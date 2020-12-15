classdef (Hidden) AnalogInputMicrophoneChannel < daq.ni.AnalogInputVoltageIEPECurrentExcitationChannel
    %AnalogInputMicrophoneChannel All settings & operations for an NI analog input microphone channel.
    
    % Copyright 2011-2013 The MathWorks, Inc.
    %
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties
        %Sensitivity The sensitivity of the sensor in volts per pascals
        Sensitivity;
        
        %MaxSoundPressureLevel The maximum instantaneous sound pressure
        % level to be measured. This value is in decibels, referenced to 20
        % micro pascals
        MaxSoundPressureLevel;
        
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = AnalogInputMicrophoneChannel(session,deviceInfo,channelID)
            %AnalogInputMicrophoneChannel All settings & operations for
            %an analog input microphone channel added to a session.
            %    AnalogInputMicrophoneChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    analog channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)
            
            % Create the channel to get appropriate defaults
            obj@daq.ni.AnalogInputVoltageIEPECurrentExcitationChannel(session,deviceInfo,channelID);
            
            % NI-DAQmx refers to channels by "<device>/<channelID>"
            obj.PhysicalChannel = [deviceInfo.ID '/' channelID];
            
            % Get the channel group name.
            obj.GroupName = obj.getGroupNameHook();
            
            % Set channel defaults
            obj.BlockPropertyNotificationDuringInit = true;
            obj.PropertyChangeInProgress = true;
            
            obj.Sensitivity = 'Unknown';
            obj.lastGoodSensitivity = 'Unknown';
            obj.MaxSoundPressureLevel = 'Unknown'; 
            obj.lastGoodMaxSoundPressureLevel = 'Unknown';
            
            obj.VoltageRange = obj.Range;
            obj.MaxSPLSetByUser = false;
            
            obj.OnDemandOperationsSupported = ...
                deviceInfo.getSubsystem(daq.internal.SubsystemType.AnalogInput).OnDemandOperationsSupported;
            
            obj.PropertyChangeInProgress = false;
            obj.BlockPropertyNotificationDuringInit = false;
        end
    end
    
    methods
        function set.Sensitivity(obj,newSensitivity)
            try
                if obj.PropertyChangeInProgress
                    obj.Sensitivity = newSensitivity;
                    return
                end
                
                % Check that newSensitivity is a scalar numeric greater than 0
                if isempty(newSensitivity) || ~isscalar(newSensitivity) ||...
                        ~daq.internal.isNumericNum(newSensitivity) || newSensitivity <= 0
                    obj.localizedError('nidaq:ni:invalidMicSensitivity');
                end
                
                try
                    obj.PropertyChangeInProgress = true;
                    obj.Sensitivity = newSensitivity;
                    % Set the MaxSoundPressureLevel based on the sensitivity
                    % value
                    obj.setDeviceSPL();
                    obj.channelPropertyBeingChanged('Sensitivity',newSensitivity)
                    obj.lastGoodSensitivity = obj.Sensitivity;
                    obj.setDeviceRange();                  
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
        
        function set.MaxSoundPressureLevel(obj,newMaxSoundPressureLevel)
            try
                if obj.PropertyChangeInProgress
                    obj.MaxSoundPressureLevel = newMaxSoundPressureLevel;
                    return
                end
                
                % User tried changing the MaxSoundPressureLevel. 
                obj.MaxSPLSetByUser = true;
                
                % Error out if Sensitivity is not yet known.
                if strcmp(obj.Sensitivity,'Unknown')
                   obj.localizedError('nidaq:ni:setMicSensitivity');                    
                end
                
                % Check that MaxSoundPressureLevel is a scalar numeric
                if isempty(newMaxSoundPressureLevel) || ~isscalar(newMaxSoundPressureLevel) ||...
                        ~daq.internal.isNumericNum(newMaxSoundPressureLevel)
                    obj.localizedError('nidaq:ni:invalidMicSPL');
                end
                
                % Check the MaxSoundPressureLevel does not exceed the
                % maximum   
                maxSPLforCurrentSensitivity = obj.calculateMaxSPL();
                if newMaxSoundPressureLevel > maxSPLforCurrentSensitivity
                    obj.localizedError('nidaq:ni:SPLExceedsMaximum',...
                        num2str(maxSPLforCurrentSensitivity));
                end
                
                try
                    obj.PropertyChangeInProgress = true;
                    obj.MaxSoundPressureLevel = newMaxSoundPressureLevel;
                    obj.channelPropertyBeingChanged('MaxSoundPressureLevel',newMaxSoundPressureLevel)
                    obj.lastGoodMaxSoundPressureLevel = obj.MaxSoundPressureLevel;
                    obj.setDeviceRange();
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
            obj.createChannel(taskHandle,daq.ni.utility.DAQToNI(obj.TerminalConfigInfo))
            
            [status] = daq.ni.NIDAQmx.DAQmxSetAICoupling(taskHandle,obj.PhysicalChannel,daq.ni.utility.DAQToNI(obj.CouplingInfo));
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
        
        function createChannelAndCaptureParameters(obj,taskHandle)
            obj.createChannelFirstTime(taskHandle)
            obj.captureAnalogInputMicrophoneParametersFromNIDAQmx(taskHandle)
        end
    end
    
    % Protected template methods with optional implementation by a subclass
    methods (Access = protected)
        function newRange = setRangeHook(obj,value)
            % Override standard set behavior for Range.  For microphone
            % channels, this property is read only, and driven by the
            % Sensitivity of the microphone sensor
            if ~obj.PropertyChangeInProgress
                obj.localizedError('nidaq:ni:microphoneRangeIsReadOnly');
            end
            
            %obj.channelPropertyBeingChanged('Range',value)
            newRange = value;
        end
        
        function [groupName] = getGroupNameHook(obj)
            % Define the channel group name for this channel.
            %
            % The default implementation is to set GroupName to
            % "ai/<DeviceID>" which causes all analog input channels from a
            % device to be grouped together.
            groupName = ['ai/' obj.Device.ID];
        end
        
        function measurementTypeDisplayText = getMeasurementTypeDisplayHook(obj) %#ok<MANU>
            % getMeasurementTypeDisplayHook A function that returns the string to
            % display the measurement type in the display operation
            measurementTypeDisplayText = 'Microphone';
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
                    case 'Sensitivity'
                        obj.Session.recreateTaskHandle(obj.GroupName);
                        dependentPropertyName = 'MaxSoundPressureLevel';
                        [status,~] = daq.ni.NIDAQmx.DAQmxGetAIMicrophoneSensitivity(...
                            taskHandle,...
                            obj.PhysicalChannel,...
                            double(0));
                        % Some devices require that the sample rate be set
                        % before other operations. This will be indicated by the
                        % status of the attempt to get the MicrophoneSensitivity above.
                        if status == daq.ni.NIDAQmx.DAQmxErrorSampClkRateMustBeSpecd
                            [status] = daq.ni.NIDAQmx.DAQmxSetSampClkRate(...
                                taskHandle,...
                                obj.Session.Rate);
                            daq.ni.utility.throwOrWarnOnStatus(status);
                            [status,~] = daq.ni.NIDAQmx.DAQmxGetAIMicrophoneSensitivity(...
                                taskHandle,...
                                obj.PhysicalChannel,...
                                double(0));
                            % Check status outside if block
                        end
                        if status ~= daq.ni.NIDAQmx.DAQmxSuccess
                            obj.Sensitivity = obj.lastGoodSensitivity;
                            obj.Session.recreateTaskHandle(obj.GroupName);
                        end
                        daq.ni.utility.throwOrWarnOnStatus(status);
                    case 'MaxSoundPressureLevel'
                        obj.Session.recreateTaskHandle(obj.GroupName);
                        dependentPropertyName = 'Sensitivity';
                        [status,~] = daq.ni.NIDAQmx.DAQmxGetAISoundPressureMaxSoundPressureLvl(...
                            taskHandle,...
                            obj.PhysicalChannel,...
                            double(0));
                        % Some devices require that the sample rate be set
                        % before other operations. This will be indicated by the
                        % status of the attempt to get the SoundPressureMaxSoundPressure above.
                        if status == daq.ni.NIDAQmx.DAQmxErrorSampClkRateMustBeSpecd
                            [status] = daq.ni.NIDAQmx.DAQmxSetSampClkRate(...
                                taskHandle,...
                                obj.Session.Rate);
                            daq.ni.utility.throwOrWarnOnStatus(status);
                            
                            [status,~] = daq.ni.NIDAQmx.DAQmxGetAISoundPressureMaxSoundPressureLvl(...
                                taskHandle,...
                                obj.PhysicalChannel,...
                                double(0));
                            % Check status outside if block
                        end
                        if status ~= daq.ni.NIDAQmx.DAQmxSuccess
                            obj.MaxSoundPressureLevel = obj.lastGoodMaxSoundPressureLevel;
                            obj.Session.recreateTaskHandle(obj.GroupName);
                        end
                        daq.ni.utility.throwOrWarnOnStatus(status);
                    otherwise
                        channelPropertyBeingChangedHook@daq.ni.AnalogInputVoltageIEPECurrentExcitationChannel(obj,propertyName,newValue);
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
                    case {'nidaq:ni:err201172'}
                        obj.localizedError('nidaq:ni:NIDAQmxError201172');
                    case {'nidaq:ni:err200860'}
                        obj.localizedError('nidaq:ni:NIDAQmxError200860',propertyName,...
                            dependentPropertyName);
                    otherwise
                        rethrow(e)
                end
            end
        end
        
        function errorIfNotReadyToStartHook(obj)
            % errorIfNotReadyToStartHook Error if channel property is
            % invalid
            %
            % Provides the channel the opportunity to validate that all
            % settings are appropriate for an operation.
            %
            % errorIfNotReadyToStartHook() is called as part of prepare().
            % The vendor implementation may throw an error to prevent the
            % operation from going forward.
            %
            
            % User is required to set microphone sensitivity before starting
            if strcmp(obj.Sensitivity, 'Unknown')
                obj.localizedError('nidaq:ni:mustSetMicSensitivity',obj.ID)
            end
        end
        
        function createChannelFirstTime(obj,taskHandle)
            obj.createChannel(taskHandle,daq.ni.NIDAQmx.DAQmx_Val_Cfg_Default);
        end
    end
    
    % Friends
    methods(Hidden)
        function channelDescriptionText = getChannelDescriptionHook(obj) %#ok<MANU>
            % getChannelDescriptionText A function that returns the string
            % to display the channel description in the channel display
            % operation
            channelDescriptionText = 'analog input microphone channel';
        end
    end
    
    % Protected methods for use by a subclass
    methods (Sealed, Access = protected)
        function captureAnalogInputMicrophoneParametersFromNIDAQmx(obj,taskHandle)
            % Capture the input type, get it from NI-DAQmx
            [status,AITermCfg] = daq.ni.NIDAQmx.DAQmxGetAITermCfg(taskHandle,...
                obj.PhysicalChannel, int32(0));
            % Check the status after insuring failure not caused by
            % need to set the sample rate first.
            
            % G496133 Some devices require that the sample rate be set
            % before other operations. This will be indicated by the
            % status of the attempt to get the AITermCfg above.
            if status == daq.ni.NIDAQmx.DAQmxErrorSampClkRateMustBeSpecd
                [status] = daq.ni.NIDAQmx.DAQmxSetSampClkRate(...
                    taskHandle,...
                    obj.Device.Subsystems.RateLimit(1));
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                [status,AITermCfg] = daq.ni.NIDAQmx.DAQmxGetAITermCfg(taskHandle,...
                    obj.PhysicalChannel, int32(0));
                % Check status outside if block
            end
            daq.ni.utility.throwOrWarnOnStatus(status);
            obj.TerminalConfig = daq.ni.utility.NIToDAQ(AITermCfg);
            
            % We don't know the Coupling: get it from NI-DAQmx
            [status,AICoupling] = daq.ni.NIDAQmx.DAQmxGetAICoupling(...
                taskHandle,...
                obj.PhysicalChannel,...
                int32(0));
            if status == daq.ni.NIDAQmx.DAQmxSuccess
                obj.Coupling = daq.ni.utility.NIToDAQ(AICoupling);
            end            

        end
    end
    
    methods (Static, Hidden)
        function [isSupported] = detectIfSupported(device)
            isSupported = false;
            try
                [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
                daq.ni.utility.throwOrWarnOnStatus(status);
                [status] = daq.ni.NIDAQmx.DAQmxCreateAIMicrophoneChan(...
                    taskHandle,...                          % taskHandle
                    sprintf('%s/ai0',device),...            % physicalChannel
                    blanks(0),...                           % nameToAssignToChannel
                    daq.ni.NIDAQmx.DAQmx_Val_Cfg_Default,...% terminalConfig
                    daq.ni.NIDAQmx.DAQmx_Val_Pascals,...    % units to use to return sound pressure measurements
                    30,...                                  % micSensitivity  (in millivolts per pascal)
                    100,...                                 % maxSndPressLevel (in decibels, referenced to 20 micro pascals)
                    daq.ni.NIDAQmx.DAQmx_Val_Internal,...   % excitation source
                    0.002,...                               % excitation current
                    char(0));                               % customScaleName
                daq.ni.utility.throwOrWarnOnStatus(status);
                isSupported = true;
            catch  %#ok<CTCH>
                % Any error is failure
            end
            [~] = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
        end
    end
    
    % Private methods
    methods (Access = protected)
        function createChannel(obj,taskHandle,niTerminalConfig)
            if strcmp(obj.Sensitivity, 'Unknown')
                % Defaults for first time channel creation
                microphoneSensitivity = .02;
            else
                microphoneSensitivity = obj.Sensitivity;
            end
            
            if strcmp(obj.MaxSoundPressureLevel, 'Unknown')
                % Defaults for first time channel creation
                maxSoundPressureLevel = 100;
            else
                maxSoundPressureLevel = obj.MaxSoundPressureLevel;
            end
            
            [status] = daq.ni.NIDAQmx.DAQmxCreateAIMicrophoneChan(...
                taskHandle,...                          % taskHandle
                obj.PhysicalChannel,...                 % physicalChannel
                blanks(0),...                           % nameToAssignToChannel
                niTerminalConfig,...                    % terminalConfig
                daq.ni.NIDAQmx.DAQmx_Val_Pascals,...    % units to use to return sound pressure measurements
                microphoneSensitivity * 1000,...        % micSensitivity  (in millivolts per pascal)
                maxSoundPressureLevel,...               % maxSndPressLevel (in decibels, referenced to 20 micro pascals)
                daq.ni.utility.DAQToNI(obj.ExcitationSourceInfo),...   % excitation source
                obj.ExcitationCurrent,...               % excitation current
                char(0));                               % customScaleName
            daq.ni.utility.throwOrWarnOnStatus(status);
            
        end
    end
    
    methods (Access = private)
        % Range for a microphone channel is read-only and is dependent on
        % the Sensitivity and MaxSoundPressureLevel specified. This
        % function is called when changing the Sensitivity or
        % MaxSoundPressureLevel
        function setDeviceRange(obj)
            taskHandle = obj.Session.getUnreservedTaskHandle(obj.GroupName);
            
            [status,minRange] = daq.ni.NIDAQmx.DAQmxGetAIMin(taskHandle,obj.PhysicalChannel, double(0));
            
            % Some devices require that the sample rate be set
            % before other operations. This will be indicated by the
            % status of the attempt to get the MinRange above.
            if status == daq.ni.NIDAQmx.DAQmxErrorSampClkRateMustBeSpecd
                [status] = daq.ni.NIDAQmx.DAQmxSetSampClkRate(...
                    taskHandle,...
                    obj.Device.Subsystems.RateLimit(1));
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                [status,minRange] = daq.ni.NIDAQmx.DAQmxGetAIMin(taskHandle,obj.PhysicalChannel, double(0));
            end
            daq.ni.utility.throwOrWarnOnStatus(status);
            % Check status outside if block
            
            [status,maxRange] = daq.ni.NIDAQmx.DAQmxGetAIMax(taskHandle,obj.PhysicalChannel, double(0));
            daq.ni.utility.throwOrWarnOnStatus(status);
            obj.Range = daq.Range(minRange,...
                maxRange,...
                'Pascals');
        end
        
        % The MaxSoundPressureLevel is dependent on the voltage range
        % supported by the device and sensitivity of the microphone.
        % 
        % Formula used:
        %
        %   MaxSoundPressureLevel = 20log(Pmax/Po);
        % 
        %           where Pmax = the maximum Pascals that the device can receive
        %                 Po   = Reference in Pascals ( 20uP )
        %   
        %   Pmax = Vmax/SensorSensitivity
        %           
        %          where Vmax is the maximum voltage input for the device.
        function maxDB = calculateMaxSPL(obj)
             Pmax = obj.VoltageRange.Max/obj.Sensitivity;
             maxDB = floor(20*log10(Pmax/2e-5));
        end
        
        
        function setDeviceSPL(obj)            
          maxDB = obj.calculateMaxSPL();
          
          if strcmp(obj.MaxSoundPressureLevel,'Unknown') || ~(obj.MaxSPLSetByUser)
            obj.MaxSoundPressureLevel = maxDB;
          end
          
          if obj.MaxSoundPressureLevel > maxDB
              obj.MaxSoundPressureLevel = maxDB;
              obj.localizedWarning('nidaq:ni:MaxSPLChanged',...
                  num2str(maxDB));
          end

        end
    end
    
    
    
    properties (Hidden, Access = private)
        
        %lastGoodMaxSoundPressureLevel Last correct value is stored so that we
        %can restore if the driver errors on read
        lastGoodMaxSoundPressureLevel;
        
        %lastGoodSensitivity Last correct value is stored so that we
        %can restore if the driver errors on read
        lastGoodSensitivity
        
        %MaxSPLByUser Boolean to keep track if the user tried to set the
        %MaxSoundPressureLevel property.
        MaxSPLSetByUser
        
        %VoltageRange The voltage range supported by the Channel
        VoltageRange
    end
end

