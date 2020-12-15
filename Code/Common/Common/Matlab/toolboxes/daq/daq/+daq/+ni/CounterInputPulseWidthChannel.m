classdef (Hidden) CounterInputPulseWidthChannel < daq.ni.CounterInputChannel
    %CounterInputPulseWidthChannel All settings & operations for an NI
    %counter input PulseWidth channel.
    
    % Copyright 2010-2013 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties
        %ActivePulse Specifies the edge of the pulse to begin measuring
        %from
        ActivePulse;
    end
    
    % Read only properties
    properties(SetAccess = protected)
        %Terminal Specifies the physical device pulse width terminal
        Terminal;
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = CounterInputPulseWidthChannel(session,deviceInfo,channelID)
            %CounterInputPulseWidthChannel All settings & operations for an counter input PulseWidth channel added to a session.
            %    CounterInputPulseWidthChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID)
            %    Create a counter channel with SUBSYSTEMTYPE, SESSION,
            %    DEVICEINFO, and ID (see daq.Channel)
            
            % Create the channel to get appropriate defaults
            obj@daq.ni.CounterInputChannel(session,deviceInfo,channelID);
            
            % Get the channel group name.
            obj.GroupName = obj.getGroupNameHook();

            % Set channel defaults
            obj.BlockPropertyNotificationDuringInit = true;
            obj.PropertyChangeInProgress = true;

            obj.ActivePulseInfo     = daq.ActivePulse.High;
            obj.Terminal            = 'Unknown';
            
            % Hidden defaults
            obj.MinimumExpectedPW   = ...
                   obj.Device.getSubsystem(daq.internal.SubsystemType.CounterInput).DefaultMinMaxExpectedPulseWidth(1);
            obj.MaximumExpectedPW   = ...
                   obj.Device.getSubsystem(daq.internal.SubsystemType.CounterInput).DefaultMinMaxExpectedPulseWidth(2);
            obj.UnitsInfo           = daq.ni.NIDAQmx.DAQmx_Val_Seconds;
            
            obj.OnDemandOperationsSupported = ...
                deviceInfo.getSubsystem(daq.internal.SubsystemType.CounterInput).OnDemandOperationsSupportedPulseWidth;
       
            obj.PropertyChangeInProgress = false;
            obj.BlockPropertyNotificationDuringInit = false;
        end
    end
    
    % Hidden properties
    properties(Hidden)
        %ActivePulseInfo Enumeration specifies which input pulse edge
        %(rising or falling) to start measuring from.
        ActivePulseInfo;
        
        %MinimumExpectedPW Minimum expected pulse width value
        MinimumExpectedPW;
        
        %MaximumExpectedPW Maximum expected pulse width value
        MaximumExpectedPW;
        
        %UnitsInfo Pulse width units
        UnitsInfo;
    end
    
    methods
        function set.ActivePulseInfo(obj,newActivePulseInfo)
            try
                if obj.PropertyChangeInProgress
                    obj.ActivePulseInfo = newActivePulseInfo;
                    obj.ActivePulse = char(newActivePulseInfo);
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newActivePulseInfo = daq.ActivePulse.setValue(newActivePulseInfo);
                    obj.channelPropertyBeingChanged('ActivePulseInfo',newActivePulseInfo)
                    % Keep the hidden and visible properties in sync
                    obj.ActivePulseInfo = newActivePulseInfo;
                    obj.ActivePulse = char(newActivePulseInfo);
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
        
        function set.ActivePulse(obj,newActivePulse)
            try
                if obj.PropertyChangeInProgress
                    obj.ActivePulse = newActivePulse;
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newActivePulseInfo = daq.ActivePulse.setValue(newActivePulse);
                    % Really, we only change the underlying hidden property
                    % with the enumeration -- and we only report that change
                    obj.channelPropertyBeingChanged('ActivePulseInfo',newActivePulseInfo)
                    % Keep the hidden and visible properties in sync
                    obj.ActivePulse = char(newActivePulseInfo);
                    obj.ActivePulseInfo = newActivePulseInfo;
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
        function configureTask(obj,taskHandle)
            obj.createChannel(taskHandle)
            
            [status] = daq.ni.NIDAQmx.DAQmxSetCIPulseWidthStartingEdge(...
                taskHandle,...
                obj.PhysicalChannel,...
                daq.ni.utility.DAQToNI(obj.ActivePulseInfo));
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
        
        function createChannelAndCaptureParameters(obj,taskHandle)
            obj.createChannel(taskHandle);
            captureCounterInputPulseWidthParametersFromNIDAQmx(obj,taskHandle)
        end
    end
    
    % Protected template methods with optional implementation by a subclass
    methods (Access = protected)
        function [groupName] = getGroupNameHook(obj)
            % Define the channel group name for this channel.
            %
            % The default implementation is to set GroupName to
            % "ci/PhysicalChannel" which causes all counter input channels
            % from a device to be grouped separately.
            groupName = ['ci/' obj.PhysicalChannel];
        end
        
        function measurementTypeDisplayText = getMeasurementTypeDisplayHook(obj) %#ok<MANU>
            % getMeasurementTypeDisplayHook A function that returns the string to
            % display the measurement type in the display operation
            measurementTypeDisplayText = 'PulseWidth';
        end
        
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
                    case 'ActivePulseInfo'
                        [status] = daq.ni.NIDAQmx.DAQmxSetCIPulseWidthStartingEdge(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
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
                        obj.localizedError('nidaq:ni:deviceDoesNotSupport',propertyName,newValueChar)
                    otherwise
                        rethrow(e)
                end
            end
        end
        
        function UpdateCounterOffsetHook(obj, ~) %#ok<MANU>
            % This counter channel does not keep track of counter offset
            % between start/stop counter operations
        end
    end
    
    % Friends
    methods(Hidden)
        function channelDescriptionText = getChannelDescriptionHook(obj) %#ok<MANU>
            % getChannelDescriptionText A function that returns the string
            % to display the channel description in the channel display
            % operation
            channelDescriptionText = 'counter input pulse width channel';
        end
    end
    
    % Protected methods for use by a subclass
    methods (Sealed, Access = protected)
        function captureCounterInputPulseWidthParametersFromNIDAQmx(obj,taskHandle)
            % ActivePulse
            [status,Edge] = daq.ni.NIDAQmx.DAQmxGetCIPulseWidthStartingEdge(...
                taskHandle,...
                obj.PhysicalChannel,...
                int32(0));
            if status == daq.ni.NIDAQmx.DAQmxSuccess
                switch Edge
                    case daq.ni.NIDAQmx.DAQmx_Val_Rising
                        obj.ActivePulse = 'High';
                    case daq.ni.NIDAQmx.DAQmx_Val_Falling
                        obj.ActivePulse = 'Low';
                end
            end
        end
        
        function createChannel(obj,taskHandle)
            [status] = daq.ni.NIDAQmx.DAQmxCreateCIPulseWidthChan (...
                taskHandle,...                          % The task handle
                obj.PhysicalChannel,...                 % physicalChannel
                char(0),...                             % nameToAssignToChannel
                obj.MinimumExpectedPW,...               % minimum value
                obj.MaximumExpectedPW,...               % maximum value
                obj.UnitsInfo,...                       % units
                daq.ni.utility.DAQToNI(obj.ActivePulseInfo),...       % starting edge
                char(0));                               % custom scale
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            BufferSize = 64;
            TerminalName = blanks(BufferSize);
            [status, TerminalName] = daq.ni.NIDAQmx.DAQmxGetCIPulseWidthTerm(...
                taskHandle,...                          % The task handle
                obj.PhysicalChannel,...                 % physicalChannel
                TerminalName,...                        % buffer
                uint32(BufferSize));                    % buffer size
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            obj.Terminal = obj.abbreviateTerminalName(TerminalName);
            
        end
    end
end
