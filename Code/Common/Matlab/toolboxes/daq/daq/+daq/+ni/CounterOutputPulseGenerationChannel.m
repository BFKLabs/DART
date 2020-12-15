classdef (Hidden) CounterOutputPulseGenerationChannel < daq.ni.CounterOutputChannel
    %CounterOutputPulseGenerationChannel All settings & operations for an NI
    %counter output PulseGeneration channel.
    
    % Copyright 2010-2013 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties
        %IdleState Specifies the output high/low when no output pulse is
        %being generated
        IdleState;
        
        %Delay Specifies a delay in seconds to wait before starting counter
        %output pulse generation
        InitialDelay;
        
        %Frequency Specifies the frequency in hertz of the output pulse
        %generated
        Frequency;
        
        %DutyCycle Specifies the duty cycle as a ratio of the width of the
        %pulse divided by the period of the output pulse to be generated
        DutyCycle;
    end
    
    % Read only properties
    properties(SetAccess = protected)
        % Physical device terminals
        Terminal;
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = CounterOutputPulseGenerationChannel(session,deviceInfo,channelID)
            %CounterOutputPulseGenerationChannel All settings & operations
            %for an counter output PulseGeneration channel added to a
            %session.
            %    CounterOutputPulseGenerationChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID)
            %    Create a counter channel with SUBSYSTEMTYPE, SESSION,
            %    DEVICEINFO, and ID (see daq.Channel)
            
            % Create the channel to get appropriate defaults
            obj@daq.ni.CounterOutputChannel(session,deviceInfo,channelID);
            
            % Get the channel group name.
            obj.GroupName = obj.getGroupNameHook();

            % Set channel defaults
            obj.BlockPropertyNotificationDuringInit = true;
            obj.PropertyChangeInProgress = true;

            %obj.ActivePulseInfo    = daq.ActivePulse.High;
            obj.Terminal            = 'Unknown';
            obj.IdleStateInfo       = daq.IdleState.Low;
            obj.InitialDelay        = 0;
            obj.Frequency           = 100;
            obj.DutyCycle           = 0.5;
                        
            % Hidden defaults
            obj.UnitsInfo           = daq.ni.NIDAQmx.DAQmx_Val_Hz;
            
            obj.OnDemandOperationsSupported = ...
                deviceInfo.getSubsystem(daq.internal.SubsystemType.CounterOutput).OnDemandOperationsSupported;
       
            obj.PropertyChangeInProgress = false;
            obj.BlockPropertyNotificationDuringInit = false;
        end
    end
    
    % Hidden properties
    properties(Hidden)
        %IdleStateInfo Specifies the output during idle state
        IdleStateInfo
        
        %UnitsInfo Specifies the output pulse frequency units
        UnitsInfo;
    end
    
    methods
        function set.IdleStateInfo(obj,newIdleStateInfo)
            try
                if obj.PropertyChangeInProgress
                    obj.IdleStateInfo = newIdleStateInfo;
                    obj.IdleState = char(newIdleStateInfo);
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newIdleStateInfo = daq.IdleState.setValue(newIdleStateInfo);
                    obj.channelPropertyBeingChanged('IdleStateInfo',newIdleStateInfo)
                    % Keep the hidden and visible properties in sync
                    obj.IdleStateInfo = newIdleStateInfo;
                    obj.IdleState = char(newIdleStateInfo);
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
        
        function set.IdleState(obj,newIdleState)
            try
                if obj.PropertyChangeInProgress
                    obj.IdleState = newIdleState;
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newIdleStateInfo = daq.IdleState.setValue(newIdleState);
                    % Really, we only change the underlying hidden property
                    % with the enumeration -- and we only report that change
                    obj.channelPropertyBeingChanged('IdleStateInfo',newIdleStateInfo)
                    % Keep the hidden and visible properties in sync
                    obj.IdleState = char(newIdleStateInfo);
                    obj.IdleStateInfo = newIdleStateInfo;
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
        
        function set.InitialDelay(obj,newInitialDelay)
            try
                if isempty(newInitialDelay) || ~isscalar(newInitialDelay) ||...
                        ~daq.internal.isNumericNum(newInitialDelay) ||...
                        newInitialDelay < 0
                    obj.localizedError('nidaq:ni:invalidCOInitialDelay');
                end
                
                obj.channelPropertyBeingChanged('InitialDelay',newInitialDelay)
                obj.InitialDelay = newInitialDelay;
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
        
        function set.Frequency(obj,newFrequency)
            try
                if isempty(newFrequency) || ~isscalar(newFrequency) ||...
                        ~daq.internal.isNumericNum(newFrequency) || ...
                        newFrequency < 0
                    obj.localizedError('nidaq:ni:invalidCOFrequency');
                end
                
                obj.channelPropertyBeingChanged('Frequency',newFrequency)
                obj.Frequency = newFrequency;
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
        
        function set.DutyCycle(obj,newDutyCycle)
            try
                if isempty(newDutyCycle) || ~isscalar(newDutyCycle) ||...
                        ~daq.internal.isNumericNum(newDutyCycle)
                    obj.localizedError('nidaq:ni:invalidCODutyCycle');
                end
                
                if newDutyCycle <= 0 || newDutyCycle >= 1
                    obj.localizedError('nidaq:ni:invalidCODutyCycleRange');
                end
                
                obj.channelPropertyBeingChanged('DutyCycle',newDutyCycle)
                obj.DutyCycle = newDutyCycle;
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
            
            [status] = daq.ni.NIDAQmx.DAQmxSetCOPulseIdleState(...
                taskHandle,...
                obj.PhysicalChannel,...
                daq.ni.utility.DAQToNI(obj.IdleStateInfo));
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            [status] = daq.ni.NIDAQmx.DAQmxSetCOPulseFreqInitialDelay(...
                taskHandle,...
                obj.PhysicalChannel,...
                obj.InitialDelay);
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            [status] = daq.ni.NIDAQmx.DAQmxSetCOPulseFreq(...
                taskHandle,...
                obj.PhysicalChannel,...
                obj.Frequency);
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            [status] = daq.ni.NIDAQmx.DAQmxSetCOPulseDutyCyc(...
                taskHandle,...
                obj.PhysicalChannel,...
                obj.DutyCycle);
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
        
        function createChannelAndCaptureParameters(obj,taskHandle)
            obj.createChannel(taskHandle);
            captureCounterOutputPulseGenerationParametersFromNIDAQmx(obj,taskHandle)
        end
    end
    
    % Protected template methods with optional implementation by a subclass
    methods (Access = protected)
        function [groupName] = getGroupNameHook(obj)
            % Define the channel group name for this channel.
            %
            % The default implementation is to set GroupName to
            % "ci/PhysicalChannel" which causes all counter output channels
            % from a device to be grouped separately.
            groupName = ['co/' obj.PhysicalChannel];
        end
        
        function measurementTypeDisplayText = getMeasurementTypeDisplayHook(obj) %#ok<MANU>
            % getMeasurementTypeDisplayHook A function that returns the string to
            % display the measurement type in the display operation
            measurementTypeDisplayText = 'PulseGeneration';
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
                    case 'IdleStateInfo'
                        [status] = daq.ni.NIDAQmx.DAQmxSetCOPulseIdleState(...
                            taskHandle,...
                            obj.PhysicalChannel,...
                            daq.ni.utility.DAQToNI(newValue));
                        daq.ni.utility.throwOrWarnOnStatus(status);
            
                    case 'InitialDelay'
                        [status] = daq.ni.NIDAQmx.DAQmxSetCOPulseFreqInitialDelay(...
                            taskHandle,...
                            obj.PhysicalChannel,...
                            newValue);
                        daq.ni.utility.throwOrWarnOnStatus(status);
            
                    case 'Frequency'
                        [status] = daq.ni.NIDAQmx.DAQmxSetCOPulseFreq(...
                            taskHandle,...
                            obj.PhysicalChannel,...
                            newValue);
                        daq.ni.utility.throwOrWarnOnStatus(status);
            
                    case 'DutyCycle'
                        [status] = daq.ni.NIDAQmx.DAQmxSetCOPulseDutyCyc(...
                            taskHandle,...
                            obj.PhysicalChannel,...
                            newValue);
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
            channelDescriptionText = 'counter output pulse generation channel';
        end
    end
    
    % Protected methods for use by a subclass
    methods (Sealed, Access = protected)
        function captureCounterOutputPulseGenerationParametersFromNIDAQmx(obj,taskHandle)
            % IdleState
            [status,Idle] = daq.ni.NIDAQmx.DAQmxGetCOPulseIdleState(...
                taskHandle,...
                obj.PhysicalChannel,...
                int32(0));
            if status == daq.ni.NIDAQmx.DAQmxSuccess
            	obj.IdleState = daq.ni.utility.NIToDAQ(Idle);
            end
            
            % InitialDelay
            [status,Delay] = daq.ni.NIDAQmx.DAQmxGetCOPulseFreqInitialDelay(...
                taskHandle,...
                obj.PhysicalChannel,...
                0);
            if status == daq.ni.NIDAQmx.DAQmxSuccess
            	obj.InitialDelay = Delay;
            end
            
            % Frequency
            [status,Freq] = daq.ni.NIDAQmx.DAQmxGetCOPulseFreq(...
                taskHandle,...
                obj.PhysicalChannel,...
                0);
            if status == daq.ni.NIDAQmx.DAQmxSuccess
            	obj.Frequency = Freq;
            end
            
            % DutyCycle
            [status,Duty] = daq.ni.NIDAQmx.DAQmxGetCOPulseDutyCyc(...
                taskHandle,...
                obj.PhysicalChannel,...
                0);
            if status == daq.ni.NIDAQmx.DAQmxSuccess
            	obj.DutyCycle = Duty;
            end
        end
        
        function createChannel(obj,taskHandle)
            [status] = daq.ni.NIDAQmx.DAQmxCreateCOPulseChanFreq (...
                taskHandle,...                          % The task handle
                obj.PhysicalChannel,...                 % physicalChannel
                char(0),...                             % nameToAssignToChannel
                obj.UnitsInfo,...                       % units
                daq.ni.utility.DAQToNI(obj.IdleStateInfo),...          % idle state
                obj.InitialDelay,...                    % initial delay
                obj.Frequency,...                       % frequency
                obj.DutyCycle);                         % duty cycle
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            BufferSize = 64;
            TerminalName = blanks(BufferSize);
            [status, TerminalName] = daq.ni.NIDAQmx.DAQmxGetCOPulseTerm(...
                taskHandle,...                          % The task handle
                obj.PhysicalChannel,...                 % physicalChannel
                TerminalName,...                        % buffer
                uint32(BufferSize));                    % buffer size
            if status == 0
                obj.Terminal = obj.abbreviateTerminalName(TerminalName);
            end
        end
    end
end
