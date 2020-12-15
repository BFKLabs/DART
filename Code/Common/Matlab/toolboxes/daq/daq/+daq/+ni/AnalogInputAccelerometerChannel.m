classdef (Hidden) AnalogInputAccelerometerChannel < daq.ni.AnalogInputVoltageIEPECurrentExcitationChannel
    %AnalogInputAccelerometerChannel All settings & operations for an NI analog input accelerometer channel.
    
    % Copyright 2010-2013 The MathWorks, Inc.
    %   
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties
        %Sensitivity The sensitivity of the sensor in volts per gravity.
        Sensitivity;
    end
    
    properties(Hidden)
        VoltageRange;
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = AnalogInputAccelerometerChannel(session,deviceInfo,channelID)
            %AnalogInputAccelerometerChannel All settings & operations for
            %an analog input accelerometer channel added to a session.
            %    AnalogInputAccelerometerChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
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

            obj.VoltageRange = obj.Range;
            obj.Sensitivity = 'Unknown';
            
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
                
                % Check that newExcitation is a scalar numeric greater than 0
                if isempty(newSensitivity) || ~isscalar(newSensitivity) ||...
                        ~daq.internal.isNumericNum(newSensitivity) || newSensitivity <= 0
                    obj.localizedError('nidaq:ni:invalidAccelerometerSensitivity');
                end
                    
                try
                    obj.PropertyChangeInProgress = true;
                    obj.channelPropertyBeingChanged('Sensitivity',newSensitivity)
                    % Keep the hidden and visible properties in sync
                    obj.Sensitivity = newSensitivity;
                    obj.Range = daq.Range(obj.VoltageRange.Min/obj.Sensitivity,...
                       obj.VoltageRange.Max/obj.Sensitivity,...
                       'Gravities');
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
            obj.captureAnalogInputAccelerometerParametersFromNIDAQmx(taskHandle)
        end
    end
    
    % Protected template methods with optional implementation by a subclass
    methods (Access = protected)
        function newRange = setRangeHook(obj,value)
            % Override standard set behavior for Range.  For accelerometer
            % channels, this property is read only, and driven by the
            % Sensitivity of the accelerometer sensor
            if ~obj.PropertyChangeInProgress
                obj.localizedError('nidaq:ni:accelerometerRangeIsReadOnly');
            end
            
            obj.channelPropertyBeingChanged('Range',value)
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
            measurementTypeDisplayText = 'Accelerometer';
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
                        [status] = daq.ni.NIDAQmx.DAQmxSetAIAccelSensitivity(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            newValue);
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
            
            % User is required to set accelerometer sensitivity before starting
            if strcmp(obj.Sensitivity, 'Unknown')
                obj.localizedError('nidaq:ni:mustSetAccelerometerSensitivity',obj.PhysicalChannel)
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
            channelDescriptionText = 'analog input accelerometer channel';
        end
    end
    
    % Protected methods for use by a subclass
    methods (Sealed, Access = protected)
        function captureAnalogInputAccelerometerParametersFromNIDAQmx(obj,taskHandle)
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
            
            % Sensitivity
            if ~strcmp(obj.Sensitivity, 'Unknown')
                [status,theSensitivity] = daq.ni.NIDAQmx.DAQmxGetAIAccelSensitivity(...
                    taskHandle,...
                    obj.PhysicalChannel,...
                    0);
                if status == daq.ni.NIDAQmx.DAQmxSuccess
                    obj.Sensitivity = theSensitivity;
                end
            end
        end
    end
    
    methods (Static, Hidden)
        function [isSupported] = detectIfSupported(device,knownGoodRange)
            isSupported = false;
            try
                [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
                daq.ni.utility.throwOrWarnOnStatus(status);
                [status] = daq.ni.NIDAQmx.DAQmxCreateAIAccelChan(...
                     taskHandle,...                          % taskHandle
                    sprintf('%s/ai0',device),...            % physicalChannel
                    blanks(0),...                           % nameToAssignToChannel
                    daq.ni.NIDAQmx.DAQmx_Val_Cfg_Default,...% terminalConfig
                    knownGoodRange.Min,...                  % minVal
                    knownGoodRange.Max,...                  % maxVal
                    daq.ni.NIDAQmx.DAQmx_Val_AccelUnit_g,...% units
                    0.05,...                                % sensitivity
                    daq.ni.NIDAQmx.DAQmx_Val_VoltsPerG,...  % sensitivity units
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
                AccelerometerSensitivity = 0.05;
                GravityRange = daq.Range(obj.VoltageRange.Min/AccelerometerSensitivity,...
                    obj.VoltageRange.Max/AccelerometerSensitivity,...
                    'Gravities');
            else
                AccelerometerSensitivity = obj.Sensitivity;
                GravityRange = obj.Range;
            end
            
            [status] = daq.ni.NIDAQmx.DAQmxCreateAIAccelChan (...
                taskHandle,...                          % The task handle
                obj.PhysicalChannel,...                 % physicalChannel
                char(0),...                             % nameToAssignToChannel
                niTerminalConfig,...                    % terminalConfig
                GravityRange.Min,...                       % minVal
                GravityRange.Max,... %                     % maxVal
                daq.ni.NIDAQmx.DAQmx_Val_AccelUnit_g,...% units
                AccelerometerSensitivity,...            % sensitivity
                daq.ni.NIDAQmx.DAQmx_Val_VoltsPerG,...  % sensitivity units
                daq.ni.utility.DAQToNI(obj.ExcitationSourceInfo),...   % excitation source
                obj.ExcitationCurrent,...               % excitation current
                char(0));                               % customScaleName
            daq.ni.utility.throwOrWarnOnStatus(status);            

        end
    end
end
