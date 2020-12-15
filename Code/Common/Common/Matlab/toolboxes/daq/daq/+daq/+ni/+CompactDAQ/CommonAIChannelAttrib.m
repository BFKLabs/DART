classdef (Hidden) CommonAIChannelAttrib < handle
    %CommonAIChannelAttrib Common properties and methods for
    %CompactDAQ channels
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>

    %% -- Constructor --
    methods
        function obj = CommonAIChannelAttrib()
            obj.CompactDAQPropertyChangeInProgress = false;
        end
    end
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties
        % ADC timing mode, controlling the trade off between speed and effective resolution
        ADCTimingMode
    end
    
    %% -- Protected and private members of the class --
    
    methods(Access = protected)
        function delete(obj)
            try
                % Remove the listener on the mediator for ADCTimingModeInfo
                delete(obj.ADCTimingModeMediatorListener)
            catch %#ok<CTCH>
                % Ignore failures
            end

            try
                % Release the mediator for ADCTimingModeInfo
                obj.Session.releaseChannelMediator(obj.ADCTimingModeMediatorTag);
            catch %#ok<CTCH>
                % Ignore failures
            end
        end
    end
    
    % Hidden properties
    properties(Hidden)
        %ADCTimingModeInfo ADC timing mode, controlling the trade off between speed and effective resolution as an enumeration
        ADCTimingModeInfo;
    end
    
    % Property access methods
    methods
        function set.ADCTimingModeInfo(obj,newADCTimingModeInfo)
            try
                if obj.CompactDAQPropertyChangeInProgress
                    obj.ADCTimingModeInfo = newADCTimingModeInfo;
                    return
                end
                % ADC timing mode must be updated on all channels, not just
                % this one.
                obj.updateADCTimingModeOnAllChannels(daq.ni.ADCTimingMode.setValue(newADCTimingModeInfo))
            catch e
                % Rethrow any errors as caller, removing the long stack of
                % errors -- capture the full exception in the cause field
                % if FullDebug option is set.
                if daq.internal.getOptions().FullDebug
                    rethrow(e)
                end
                e.throwAsCaller()
            end
        end
        
        function set.ADCTimingMode(obj,newADCTimingMode)
            try
                if obj.CompactDAQPropertyChangeInProgress
                    obj.ADCTimingMode = newADCTimingMode;
                    return
                end
                % ADC timing mode must be updated on all channels, not just
                % this one.
                obj.updateADCTimingModeOnAllChannels(daq.ni.ADCTimingMode.setValue(newADCTimingMode))
            catch e
                % Rethrow any errors as caller, removing the long stack of
                % errors -- capture the full exception in the cause field
                % if FullDebug option is set.
                if daq.internal.getOptions().FullDebug
                    rethrow(e)
                end
                e.throwAsCaller()
            end
        end
    end
    
    % Protected methods for use by a subclass
    methods (Sealed,Access=protected)
        function captureADCTimingModeFromNIDAQmx(obj,taskHandle,session)
            % Capture the ADC timing mode
            [status,ADCTiming] = daq.ni.NIDAQmx.DAQmxGetAIADCTimingMode(...
                            taskHandle,...
                            obj.PhysicalChannel,... % channel
                            int32(0));              % data         
            if status == daq.ni.NIDAQmx.DAQmxSuccess ||...
                    status == daq.ni.NIDAQmx.DAQmxErrorAttributeInconsistentAcrossChannelsOnDevice
                defaultADCTimingModeInfo = daq.ni.ADCTimingMode.HighResolution;
                if status == daq.ni.NIDAQmx.DAQmxSuccess
                    defaultADCTimingModeInfo = daq.ni.utility.NIToDAQ(ADCTiming);
                end

                % Set the default digitizer timing by retrieving the channel
                % mediator that ensures they all stay the same.  Pass the
                % default in case this is the first channel.
                obj.ADCTimingModeMediatorTag = [obj.Device.ID '/ADCTimingMode'];
                obj.ADCTimingModeMediator = session.getChannelMediator(...
                    obj.ADCTimingModeMediatorTag,...
                    'daq.ni.ADCTimingModeMediator',...
                    defaultADCTimingModeInfo);
                obj.updateADCTimingModeOnThisChannel(obj.ADCTimingModeMediator.ADCTimingModeInfo)
                obj.ADCTimingModeMediatorListener = addlistener(...
                    obj.ADCTimingModeMediator,...
                    'ADCTimingModeInfo',...
                    'PostSet',...
                    @obj.handleADCTimingModeInfoChange);
                
                % G771104: Always set the channel to the current value
                % selected by the devices.
                [~] = daq.ni.NIDAQmx.DAQmxSetAIADCTimingMode(...
                    taskHandle,...
                    obj.PhysicalChannel,...                                 % channel
                    daq.ni.utility.DAQToNI(obj.ADCTimingModeMediator.ADCTimingModeInfo));  % data    
                
                % Check the max rate for the session to see if it has been
                % reduced due to "HighResolution" mode. If so, throw a
                % warning.
                [status, maxRateForTask] = daq.ni.NIDAQmx.DAQmxGetSampClkMaxRate(...
                                taskHandle,...
                                double(0));
                if status == daq.ni.NIDAQmx.DAQmxSuccess
                    if session.Rate > maxRateForTask &&...
                            obj.ADCTimingModeInfo == daq.ni.ADCTimingMode.HighResolution
                        session.Rate = maxRateForTask;
                        % Cannot derive from daq.internal.BaseClass, so
                        % call message catalog directly.
                        sWarningBacktrace = warning('off','backtrace');
                        warning(message('nidaq:ni:rateReducedToMaximumDueToHiRes',num2str(session.Rate)));
                        warning(sWarningBacktrace)
                    end
                end
            end
        end
        function configureADCTimingModeInTask(obj,taskHandle)
            % Set the channel ADCTimingMode to the current value selected by the
            % devices, if it isn't already set to that
            if ~isempty(obj.ADCTimingModeMediator)
                [~] = daq.ni.NIDAQmx.DAQmxSetAIADCTimingMode(...
                                taskHandle,...
                                obj.PhysicalChannel,...                                 % channel
                                daq.ni.utility.DAQToNI(obj.ADCTimingModeMediator.ADCTimingModeInfo));  % data    
            end
        end
    end
    
    % Private properties
    properties (GetAccess = private,SetAccess = private)
        CompactDAQPropertyChangeInProgress
    
        % Reference to the mediator that ensures that ADCTimingModeInfo on
        % all channels of this device are the same
        ADCTimingModeMediator
        
        % Listener handle for the property on the mediator that represents
        % the "master setter" for the ADCTimingModeInfo property
        ADCTimingModeMediatorListener
        
        % Tag used to access the mediator that represents
        % the "master setter" for the ADCTimingModeInfo property
        ADCTimingModeMediatorTag
    end
    
    % Superclass methods this class implements
    methods (Access = protected)
        function compactDAQPropertyBeingChanged(obj,propertyName,newValue,session)
            % channelPropertyBeingChangedHook React to change in channel property.
            %
            % Provides the vendor the opportunity to react to changes in
            % channel properties.  Note that releaseHook() will be called
            % before this if needed.
            %
            % channelPropertyBeingChangedHook(PROPERTYNAME,NEWVALUE)
            % is called before property changes occur.  The vendor
            % implementation may throw an error to prevent the change, or
            % update their corresponding hardware session, if appropriate.
            % PROPERTYNAME is the name of the property to change and
            % NEWVALUE is the new value the property will have if this
            % function returns normally.
            
            try
                switch propertyName
                    case 'ADCTimingModeInfo'
                        taskHandle = session.getUnreservedTaskHandle(obj.GroupName);
                        [status] = daq.ni.NIDAQmx.DAQmxSetAIADCTimingMode(...
                            taskHandle,...
                            obj.PhysicalChannel,...
                            daq.ni.utility.DAQToNI(newValue));
                            daq.ni.utility.throwOrWarnOnStatus(status);
                end
            catch e
                if isnumeric(newValue)
                    newValueChar = num2str(newValue);
                else
                    newValueChar = char(newValue);
                end
                
                % G642643 -- if the property has the 'Info' suffix, remove
                % it so that the message contains the customer facing
                % property name.  See also G656053
                propertyName(strfind(propertyName,'Info'):end) = [];

                switch e.identifier
                    case {'nidaq:ni:err200077','nidaq:ni:err200452'}
                        % Cannot derive from daq.internal.BaseClass, so
                        % call message catalog directly.
                        error(message('nidaq:ni:deviceDoesNotSupport',propertyName,newValueChar))
                    otherwise
                        rethrow(e)
                end
            end
            
        end
    end

    % Protected methods requiring implementation by a subclass
    methods (Abstract,Access = protected)
        compactDAQChannelPropertyBeingChangedImpl(obj,propertyName,newValue)
        [session] = getSession(obj)
    end
    
    % Private methods
    methods (Access = private)
        function handleADCTimingModeInfoChange(obj,~,propEvent)
            obj.updateADCTimingModeOnThisChannel(...
                propEvent.AffectedObject.ADCTimingModeInfo);
        end
        
        function updateADCTimingModeOnAllChannels(obj,newADCTimingModeInfo)
            % The ADCTimingMode has to be kept consistent on all channels
            % of a device. This function updates the property on all
            % channels.
            obj.ADCTimingModeMediator.ADCTimingModeInfo = newADCTimingModeInfo;
            
            % Fire warning about property change effecting all channels on
            % this device. Cannot derive from daq.internal.BaseClass, so
            % call message catalog directly.
            sWarningBacktrace = warning('off','backtrace');
            warning(message('nidaq:ni:propUpdatedOnAllChannels'))
            warning(sWarningBacktrace)
            
            % Changing this will effect the rate limit of the
            % session
            obj.getSession().updateRateLimit();
        end
        
        function updateADCTimingModeOnThisChannel(obj,newADCTimingModeInfo)
            % The ADCTimingMode has to be kept consistent on all channels
            % of a device. This function updates the property on this
            % channel ONLY.
            try
                obj.CompactDAQPropertyChangeInProgress = true;
                obj.compactDAQChannelPropertyBeingChangedImpl('ADCTimingModeInfo',newADCTimingModeInfo)
                % Keep the hidden and visible properties in sync
                obj.ADCTimingModeInfo = newADCTimingModeInfo;
                obj.ADCTimingMode = char(newADCTimingModeInfo);
                obj.CompactDAQPropertyChangeInProgress = false;
            catch e
                obj.CompactDAQPropertyChangeInProgress = false;
                rethrow(e)
            end
                
        end
    end
end
