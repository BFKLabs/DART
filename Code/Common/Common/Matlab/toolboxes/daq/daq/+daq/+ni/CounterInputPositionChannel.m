classdef (Hidden) CounterInputPositionChannel < daq.ni.CounterInputChannel
    %CounterInputPositionChannel All settings & operations for an NI
    %counter input Position channel.
    
    % Copyright 2010-2013 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties
        %EncoderType Specifies the position encoder type X1, X2, X4, or
        %TwoPulse
        EncoderType;
        
        %ZResetEnable Used to enable Z-indexing
        ZResetEnable;
        
        %ZResetValue Specifies the Z-indexing reset value
        ZResetValue;
        
        %ZResetCondition Specifies the Z-indexing reset conditions
        ZResetCondition;
    end
    
    % Read only properties
    properties(SetAccess = protected)
        %TerminalA Specifies the physical device position channel terminal
        %A
        TerminalA;
        
        TerminalB;
        %TerminalB Specifies the physical device position channel terminal
        %B
        
        TerminalZ;
        %TerminalZ Specifies the physical device position channel terminal
        %Z
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = CounterInputPositionChannel(session,deviceInfo,channelID)
            %CounterInputPositionChannel All settings & operations for an
            %counter input Position channel added to a session.
            %    CounterInputPositionChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    counter channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)
            
            % Create the channel to get appropriate defaults
            obj@daq.ni.CounterInputChannel(session,deviceInfo,channelID);
            
            % Get the channel group name.
            obj.GroupName = obj.getGroupNameHook();

            % Set channel defaults
            obj.BlockPropertyNotificationDuringInit = true;
            obj.PropertyChangeInProgress = true;
            obj.ChannelCreationInProgress = true;

            obj.EncoderTypeInfo     = daq.EncoderType.X1;
            obj.ZResetEnable        = uint32(false);
            obj.ZResetValue         = 0;
            obj.ZResetConditionInfo = daq.ZResetCondition.BothHigh;
            obj.TerminalA           = 'Unknown';
            obj.TerminalB           = 'Unknown';
            obj.TerminalZ           = 'Unknown';
            
            % Hidden defaults
            obj.UnitsInfo           = daq.ni.NIDAQmx.DAQmx_Val_Ticks;
            
            obj.OnDemandOperationsSupported = ...
                deviceInfo.getSubsystem(daq.internal.SubsystemType.CounterInput).OnDemandOperationsSupportedPosition;
             
            obj.ChannelCreationInProgress = false;
            obj.PropertyChangeInProgress = false;
            obj.BlockPropertyNotificationDuringInit = false;
        end
    end
    
    % Hidden properties
    properties(Hidden)
        %EncoderTypeInfo X1, X2, X4, or TwoPulse
        EncoderTypeInfo;
        
        %ZResetConditionInfo A/B line condition for reset for Z indexing
        ZResetConditionInfo
        
        %UnitsInfo Quadrature encoder units
        UnitsInfo;
    end
    
    methods
        function set.EncoderTypeInfo(obj,newEncoderTypeInfo)
            try
                if obj.PropertyChangeInProgress
                    obj.EncoderTypeInfo = newEncoderTypeInfo;
                    obj.EncoderType = char(newEncoderTypeInfo);
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newEncoderTypeInfo = daq.EncoderType.setValue(newEncoderTypeInfo);
                    obj.channelPropertyBeingChanged('EncoderTypeInfo',newEncoderTypeInfo)
                    % Keep the hidden and visible properties in sync
                    obj.EncoderTypeInfo = newEncoderTypeInfo;
                    obj.EncoderType = char(newEncoderTypeInfo);
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
        
        function set.EncoderType(obj,newEncoderType)
            try
                if obj.PropertyChangeInProgress
                    obj.EncoderType = newEncoderType;
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newEncoderTypeInfo = daq.EncoderType.setValue(newEncoderType);
                    % Really, we only change the underlying hidden property
                    % with the enumeration -- and we only report that change
                    obj.channelPropertyBeingChanged('EncoderTypeInfo',newEncoderTypeInfo)
                    % Keep the hidden and visible properties in sync
                    obj.EncoderType = char(newEncoderTypeInfo);
                    obj.EncoderTypeInfo = newEncoderTypeInfo;
                    obj.PropertyChangeInProgress = false;
                    obj.internalResetCounter();
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
        
        function set.ZResetConditionInfo(obj,newZResetConditionInfo)
            try
                if obj.PropertyChangeInProgress
                    obj.ZResetConditionInfo = newZResetConditionInfo;
                    obj.ZResetCondition = char(newZResetConditionInfo);
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newZResetConditionInfo = daq.ZResetCondition.setValue(newZResetConditionInfo);
                    obj.channelPropertyBeingChanged('ZResetConditionInfo',newZResetConditionInfo)
                    % Keep the hidden and visible properties in sync
                    obj.ZResetConditionInfo = newZResetConditionInfo;
                    obj.ZResetCondition = char(newZResetConditionInfo);
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
        
        function set.ZResetCondition(obj,newZResetCondition)
            try
                if obj.PropertyChangeInProgress
                    obj.ZResetCondition = newZResetCondition;
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newZResetConditionInfo = daq.ZResetCondition.setValue(newZResetCondition);
                    % Really, we only change the underlying hidden property
                    % with the enumeration -- and we only report that change
                    obj.channelPropertyBeingChanged('ZResetConditionInfo',newZResetConditionInfo)
                    % Keep the hidden and visible properties in sync
                    obj.ZResetCondition = char(newZResetConditionInfo);
                    obj.ZResetConditionInfo = newZResetConditionInfo;
                    obj.PropertyChangeInProgress = false;
                    obj.internalResetCounter();
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
        
        function set.ZResetValue(obj,newZResetValue)
            try
                obj.channelPropertyBeingChanged('ZResetValue',newZResetValue)
                obj.ZResetValue = newZResetValue;
                obj.internalResetCounter();
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
        
        function set.ZResetEnable(obj,newZResetEnable)
            try
                newZResetEnable = uint32(newZResetEnable);
                obj.channelPropertyBeingChanged('ZResetEnable',newZResetEnable)
                obj.ZResetEnable = newZResetEnable;
                obj.internalResetCounter();
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
            
            [status] = daq.ni.NIDAQmx.DAQmxSetCIEncoderDecodingType(...
                taskHandle,...
                obj.PhysicalChannel,...
                daq.ni.utility.DAQToNI(obj.EncoderTypeInfo));
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            [status] = daq.ni.NIDAQmx.DAQmxSetCIEncoderZIndexEnable(...
                taskHandle,...
                obj.PhysicalChannel,...
                uint32(obj.ZResetEnable));
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            [status] = daq.ni.NIDAQmx.DAQmxSetCIEncoderZIndexVal(...
                taskHandle,...
                obj.PhysicalChannel,...
                obj.ZResetValue);
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            [status] = daq.ni.NIDAQmx.DAQmxSetCIEncoderZIndexPhase(...
                taskHandle,...
                obj.PhysicalChannel,...
                daq.ni.utility.DAQToNI(obj.ZResetConditionInfo));
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
        
        function createChannelAndCaptureParameters(obj,taskHandle)
            obj.ChannelCreationInProgress = true;
            obj.createChannel(taskHandle);
            captureCounterInputPositionParametersFromNIDAQmx(obj,taskHandle)
            obj.ChannelCreationInProgress = false;
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
            measurementTypeDisplayText = 'Position';
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
                    case 'EncoderTypeInfo'
                        [status] = daq.ni.NIDAQmx.DAQmxSetCIEncoderDecodingType(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            daq.ni.utility.DAQToNI(newValue));
                        daq.ni.utility.throwOrWarnOnStatus(status);
                    case 'ZResetEnable'
                        [status] = daq.ni.NIDAQmx.DAQmxSetCIEncoderZIndexEnable(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            newValue);
                        daq.ni.utility.throwOrWarnOnStatus(status);
                    case 'ZResetValue'
                        [status] = daq.ni.NIDAQmx.DAQmxSetCIEncoderZIndexVal(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            newValue);
                        daq.ni.utility.throwOrWarnOnStatus(status);
                    case 'ZResetConditionInfo'
                        [status] = daq.ni.NIDAQmx.DAQmxSetCIEncoderZIndexPhase(...
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
    end
    
    % Friends
    methods(Hidden)
        function channelDescriptionText = getChannelDescriptionHook(obj) %#ok<MANU>
            % getChannelDescriptionText A function that returns the string
            % to display the channel description in the channel display
            % operation
            channelDescriptionText = 'counter input position channel';
        end
    end
    
    % Protected methods for use by a subclass
    methods (Sealed, Access = protected)
        function captureCounterInputPositionParametersFromNIDAQmx(obj,taskHandle)
            % EncoderType
            [status,Encoding] = daq.ni.NIDAQmx.DAQmxGetCIEncoderDecodingType(...
                taskHandle,...
                obj.PhysicalChannel,...
                int32(0));
            if status == daq.ni.NIDAQmx.DAQmxSuccess
                obj.EncoderType = daq.ni.utility.NIToDAQ(Encoding);
            end
            
            % ZResetEnable
            [status,resetEnable] = daq.ni.NIDAQmx.DAQmxGetCIEncoderZIndexEnable(...
                taskHandle,...
                obj.PhysicalChannel,...
                uint32(0));
            if status == daq.ni.NIDAQmx.DAQmxSuccess
                obj.ZResetEnable = resetEnable;
            end
            
            % ZResetValue
            [status,resetValue] = daq.ni.NIDAQmx.DAQmxGetCIEncoderZIndexVal(...
                taskHandle,...
                obj.PhysicalChannel,...
                0);
            if status == daq.ni.NIDAQmx.DAQmxSuccess
                obj.ZResetValue = resetValue;
            end
            
            % ZResetCondition
            [status,resetCondition] = daq.ni.NIDAQmx.DAQmxGetCIEncoderZIndexPhase(...
                taskHandle,...
                obj.PhysicalChannel,...
                int32(0));
            if status == daq.ni.NIDAQmx.DAQmxSuccess
                obj.ZResetCondition = daq.ni.utility.NIToDAQ(resetCondition);
            end
        end
        
        function createChannel(obj,taskHandle)
            [status] = daq.ni.NIDAQmx.DAQmxCreateCILinEncoderChan(...
                taskHandle,...                          % The task handle
                obj.PhysicalChannel,...                 % physicalChannel
                char(0),...                             % nameToAssignToChannel
                daq.ni.utility.DAQToNI(obj.EncoderTypeInfo),...        % quadrature encoding
                uint32(obj.ZResetEnable),...            % z enable
                obj.ZResetValue,...                     % z reset value
                daq.ni.utility.DAQToNI(obj.ZResetConditionInfo),...    % z reset phase
                obj.UnitsInfo,...                       % units
                1,...                                   % distance per pulse
                0,...                                   % initial position
                char(0));                               % custom scale
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            BufferSize = 64;
            
            TerminalName = blanks(BufferSize);
            [status, TerminalName] = daq.ni.NIDAQmx.DAQmxGetCIEncoderAInputTerm(...
                taskHandle,...                          % The task handle
                obj.PhysicalChannel,...                 % physicalChannel
                TerminalName,...                        % buffer
                uint32(BufferSize));                    % buffer size
            if status == 0
                obj.TerminalA = obj.abbreviateTerminalName(TerminalName);
            end
            
            TerminalName = blanks(BufferSize);
            [status, TerminalName] = daq.ni.NIDAQmx.DAQmxGetCIEncoderBInputTerm(...
                taskHandle,...                          % The task handle
                obj.PhysicalChannel,...                 % physicalChannel
                TerminalName,...                        % buffer
                uint32(BufferSize));                    % buffer size
            if status == 0
                obj.TerminalB = obj.abbreviateTerminalName(TerminalName);
            end
            
            TerminalName = blanks(BufferSize);
            [status, TerminalName] = daq.ni.NIDAQmx.DAQmxGetCIEncoderZInputTerm(...
                taskHandle,...                          % The task handle
                obj.PhysicalChannel,...                 % physicalChannel
                TerminalName,...                        % buffer
                uint32(BufferSize));                    % buffer size
            if status == 0
                obj.TerminalZ = obj.abbreviateTerminalName(TerminalName);
            end
        end
    end
end
