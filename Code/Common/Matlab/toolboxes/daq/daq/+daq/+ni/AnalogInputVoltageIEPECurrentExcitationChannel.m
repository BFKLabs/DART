classdef (Hidden) AnalogInputVoltageIEPECurrentExcitationChannel < daq.ni.AnalogInputVoltageChannel
    %AnalogInputVoltageIEPECurrentExcitationChannel All settings &
    %operations for an NI analog input voltage channel with IEPE current
    %excitation.
    
    % Copyright 2010-2013 The MathWorks, Inc.
    %   
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties
        %ExcitationCurrent The desired excitation current for the channel in amps
        ExcitationCurrent;
        
        %ExcitationSource Source for the excitation voltage (internal/external)
        ExcitationSource;
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = AnalogInputVoltageIEPECurrentExcitationChannel(session,deviceInfo,channelID)
            %AnalogInputVoltageIEPECurrentExcitationChannel All settings &
            %operations for an analog input voltage channel added to a
            %session.
            %    AnalogInputVoltageIEPECurrentExcitationChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    analog channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)
            
            % Create the channel to get appropriate defaults
            obj@daq.ni.AnalogInputVoltageChannel(session,deviceInfo,channelID);
            
            % Determine if there's internal excitation available
            obj.ExcitationValues = [];
            
            [arraysize, ~] = daq.ni.NIDAQmx.DAQmxGetDevAICurrentIntExcitDiscreteVals(...
                deviceInfo.ID,...   % device
                0,...               % data
                uint32(0));         % arraySizeInElements
            if arraysize ~= 0
                [status, obj.ExcitationValues] = daq.ni.NIDAQmx.DAQmxGetDevAICurrentIntExcitDiscreteVals(...
                    deviceInfo.ID,...       % device
                    zeros(1,arraysize),...  % data
                    uint32(arraysize));     % arraySizeInElements
                daq.ni.utility.throwOrWarnOnStatus(status);
                % Set the default to the minimum excitation value greater
                % than 0
                defaultExcitationValue = min(obj.ExcitationValues(obj.ExcitationValues > 0));
                dafaultExcitationSource = daq.ExcitationSource.Internal;
            else
                defaultExcitationValue = 0;
                dafaultExcitationSource = daq.ExcitationSource.None;
            end
            
            obj.BlockPropertyNotificationDuringInit = true;
            obj.ExcitationCurrent = defaultExcitationValue;
            obj.ExcitationSourceInfo = dafaultExcitationSource;
            obj.BlockPropertyNotificationDuringInit = false;
        end
    end
    
    % Hidden properties
    properties(Hidden)
        %ExcitationSourceInfo Source for the excitation voltage as an enumeration
        ExcitationSourceInfo;
    end
    
    % Property access methods
    methods
        function set.ExcitationCurrent(obj,newExcitation)
            try
                if obj.PropertyChangeInProgress
                    obj.ExcitationCurrent = newExcitation;                    
                    return
                end
                
                % Check that newExcitation is a scalar numeric greater than 0
                if isempty(newExcitation) || ~isscalar(newExcitation) ||...
                        ~daq.internal.isNumericNum(newExcitation) || newExcitation <= 0
                    obj.localizedError('nidaq:ni:invalidExcitationCurrent');
                end
                try
                    obj.PropertyChangeInProgress = true;
                    obj.lastGoodExcitationCurrent = obj.ExcitationCurrent;
                    obj.channelPropertyBeingChanged('ExcitationCurrent',newExcitation)
                    obj.ExcitationCurrent = newExcitation;
                    obj.PropertyChangeInProgress = false;
                catch e
                    obj.PropertyChangeInProgress = false;
                    rethrow(e)
                end
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
        
        
        function set.ExcitationSourceInfo(obj,newExcitationSourceInfo)
            try
                if obj.PropertyChangeInProgress
                    obj.ExcitationSourceInfo = newExcitationSourceInfo;
                    obj.ExcitationSource = char(newExcitationSourceInfo);
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newExcitationSourceInfo = daq.ExcitationSource.setValue(newExcitationSourceInfo);
                    obj.channelPropertyBeingChanged('ExcitationSourceInfo',newExcitationSourceInfo)
                    % Keep the hidden and visible properties in sync
                    obj.ExcitationSourceInfo = newExcitationSourceInfo;
                    obj.ExcitationSource = char(newExcitationSourceInfo);
                    obj.PropertyChangeInProgress = false;
                catch e
                    obj.PropertyChangeInProgress = false;
                    rethrow(e)
                end
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
        
        function set.ExcitationSource(obj,newExcitationSource)
            try
                if obj.PropertyChangeInProgress
                    obj.ExcitationSource = newExcitationSource;
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    obj.lastGoodExcitationSource = obj.ExcitationSource;
                    newExcitationSourceInfo = daq.ExcitationSource.setValue(newExcitationSource);
                    % Really, we only change the underlying hidden property
                    % with the enumeration -- and we only report that change
                    obj.channelPropertyBeingChanged('ExcitationSourceInfo',newExcitationSourceInfo)
                    % Keep the hidden and visible properties in sync
                    obj.ExcitationSource = char(newExcitationSourceInfo);
                    obj.ExcitationSourceInfo = newExcitationSourceInfo;
                    obj.PropertyChangeInProgress = false;
                catch e
                    obj.PropertyChangeInProgress = false;
                    rethrow(e)
                end
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
    
    % Hidden methods, which are typically used as friend methods
    methods(Hidden)
        function createChannelAndCaptureParameters(obj,taskHandle)
            obj.createChannelAndCaptureParameters@daq.ni.AnalogInputVoltageChannel(taskHandle);
        end
        
        function configureTask(obj,taskHandle)
            obj.configureTask@daq.ni.AnalogInputVoltageChannel(taskHandle);
        end
    end
    
    % Protected template methods with optional implementation by a subclass
    methods (Access = protected)
        function channelPropertyBeingChangedHook(obj,propertyName,newValue)
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
            
            taskHandle = obj.Session.getUnreservedTaskHandle(obj.GroupName);
            
            try
                switch propertyName
                    case 'ExcitationCurrent'
                        [~] = daq.ni.NIDAQmx.DAQmxSetAIExcitVal(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            newValue);
                        % If the property is not supported we will get an
                        % error on read
                        [status,readValue] = daq.ni.NIDAQmx.DAQmxGetAIExcitVal(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            double(0));
                        if readValue ~= newValue                          
                            [setStatus] = daq.ni.NIDAQmx.DAQmxSetAIExcitVal(...
                                taskHandle,...          % taskHandle
                                obj.PhysicalChannel,... % channel
                                obj.lastGoodExcitationCurrent);
                            daq.ni.utility.throwOrWarnOnStatus(setStatus);
                            obj.ExcitationCurrent = obj.lastGoodExcitationCurrent;
                        end
                        daq.ni.utility.throwOrWarnOnStatus(status);
                    case 'ExcitationSourceInfo'
                        [~] = daq.ni.NIDAQmx.DAQmxSetAIExcitSrc(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            daq.ni.utility.DAQToNI(newValue));
                        % If the property is not supported we will get an
                        % error on read
                        [status,readValue] = daq.ni.NIDAQmx.DAQmxGetAIExcitSrc(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            int32(0));
                        if readValue ~=  daq.ni.utility.DAQToNI(newValue)
                            orginalExcitationSourceInfo...
                                = daq.ExcitationSource.setValue(obj.lastGoodExcitationSource);
                            [setStatus] = daq.ni.NIDAQmx.DAQmxSetAIExcitSrc(...
                                taskHandle,...          % taskHandle
                                obj.PhysicalChannel,... % channel
                                daq.ni.utility.DAQToNI(orginalExcitationSourceInfo));
                            daq.ni.utility.throwOrWarnOnStatus(setStatus);
                            obj.ExcitationSource = obj.lastGoodExcitationSource;
                        end
                        daq.ni.utility.throwOrWarnOnStatus(status);
                    otherwise
                        obj.standardAIPropertyConfiguration(taskHandle,propertyName,newValue)
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
                        obj.localizedError('nidaq:ni:deviceDoesNotSupport',propertyName,newValueChar)
                    otherwise
                        rethrow(e)
                end
            end
        end
    end
    
    % Protected methods
    methods (Access = protected)
    end
    
    methods (Static, Hidden)
    end
    
    properties (Hidden, Access = private)
        
        %lastGoodExcitationCurrent Last correct value is stored so that we
        %can restore if the driver errors on read
        lastGoodExcitationCurrent;
        
        %lastGoodExcitationSource Last correct value is stored so that we
        %can restore if the driver errors on read
        lastGoodExcitationSource;
        
    end
    
    properties (SetAccess = private, GetAccess = private)
        ExcitationValues
    end
end
