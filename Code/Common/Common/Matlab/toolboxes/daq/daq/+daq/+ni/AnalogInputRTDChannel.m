classdef (Hidden) AnalogInputRTDChannel < daq.ni.AnalogInputVoltageIEPECurrentExcitationChannel & daq.ni.NICommonChannelAttrib
    %AnalogInputRTDChannel All settings & operations for an NI analog input RTD channel.
    
    % Copyright 2010-2013 The MathWorks, Inc.
    %   
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties
        %Units The units to use to return the measurement.
        Units;
        
        %RTDType The type of RTD connected to the channel.
        RTDType;
        
        %RTDConfiguration The RTD wiring resistance configuration.
        RTDConfiguration;
        
        %R0 The resistance in ohms at 0 degrees Celsius as
        %defined by the Callendar–Van-Dusen equation
        R0;
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = AnalogInputRTDChannel(session,deviceInfo,channelID)
            %AnalogInputRTDChannel All settings & operations for an analog
            %input RTD channel added to a session.
            %    AnalogInputRTDChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    analog channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)
            
            % Create the channel to get appropriate defaults
            obj@daq.ni.AnalogInputVoltageIEPECurrentExcitationChannel(session,deviceInfo,channelID);
            
            % NI-DAQmx refers to channels by "<device>/<channelID>"
            obj.PhysicalChannel = [deviceInfo.ID '/' channelID];
            
            % Get the channel group name.
            obj.GroupName = obj.getGroupNameHook();
            
            obj.BlockPropertyNotificationDuringInit = true;
            obj.PropertyChangeInProgress = true;
            
            obj.UnitsInfo            = daq.TemperatureUnits.Celsius;
            obj.RTDTypeInfo          = daq.RTDType.Unknown;
            obj.RTDConfigurationInfo = daq.RTDConfiguration.Unknown;
            obj.Range                = daq.ni.utility.RTDRange(obj.RTDTypeInfo,obj.UnitsInfo);
            obj.R0                   = 'Unknown';
            
            obj.OnDemandOperationsSupported = ...
                deviceInfo.getSubsystem(daq.internal.SubsystemType.AnalogInput).OnDemandOperationsSupported;
           
            obj.PropertyChangeInProgress = false;
            obj.BlockPropertyNotificationDuringInit = false;
        end
    end
    
    % Hidden properties
    properties(Hidden)
        %Units The units to use to return thee measurement as an
        %enumeration.
        UnitsInfo;
        
        %RTDTypeInfo The type of RTD connected to the channel as an
        %enumeration.
        RTDTypeInfo;
        
        %RTDConfigurationInfo The RTD wiring resistance configuration as an
        %enumeration.
        RTDConfigurationInfo;
    end
    
    % Property access methods
    methods
        function set.UnitsInfo(obj,newUnitsInfo)
            try
                if obj.PropertyChangeInProgress
                    obj.UnitsInfo = newUnitsInfo;
                    obj.Units = char(newUnitsInfo);
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newUnitsInfo = daq.TemperatureUnits.setValue(newUnitsInfo);
                    obj.channelPropertyBeingChanged('UnitsInfo',newUnitsInfo)
                    % Keep the hidden and visible properties in sync
                    obj.UnitsInfo = newUnitsInfo;
                    obj.Units = char(newUnitsInfo);
                    obj.Range = daq.ni.utility.RTDRange(obj.RTDTypeInfo,obj.UnitsInfo);
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
        
        function set.Units(obj,newUnits)
            try
                if obj.PropertyChangeInProgress
                    obj.Units = newUnits;
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newUnitsInfo = daq.TemperatureUnits.setValue(newUnits);
                    % Really, we only change the underlying hidden property
                    % with the enumeration -- and we only report that change
                    obj.channelPropertyBeingChanged('UnitsInfo',newUnitsInfo)
                    % Keep the hidden and visible properties in sync
                    obj.Units = char(newUnitsInfo);
                    obj.UnitsInfo = newUnitsInfo;
                    obj.Range = daq.ni.utility.RTDRange(obj.RTDTypeInfo,obj.UnitsInfo);
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
        
        function set.RTDTypeInfo(obj,newRTDTypeInfo)
            try
                if obj.PropertyChangeInProgress
                    obj.RTDTypeInfo = newRTDTypeInfo;
                    obj.RTDType = char(newRTDTypeInfo);
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newRTDTypeInfo = daq.RTDType.setValue(newRTDTypeInfo);
                    obj.channelPropertyBeingChanged('RTDTypeInfo',newRTDTypeInfo)
                    % Keep the hidden and visible properties in sync
                    obj.RTDTypeInfo = newRTDTypeInfo;
                    obj.RTDType = char(newRTDTypeInfo);
                    obj.Range = daq.ni.utility.RTDRange(obj.RTDTypeInfo,obj.UnitsInfo);
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
        
        function set.RTDType(obj,newRTDType)
            try
                if obj.PropertyChangeInProgress
                    obj.RTDType = newRTDType;
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    obj.lastGoodRTDType = obj.RTDType;
                    newRTDTypeInfo = daq.RTDType.setValue(newRTDType);
                    % Really, we only change the underlying hidden property
                    % with the enumeration -- and we only report that change
                    obj.channelPropertyBeingChanged('RTDTypeInfo',newRTDTypeInfo)
                    % Keep the hidden and visible properties in sync
                    obj.RTDType = char(newRTDTypeInfo);
                    obj.RTDTypeInfo = newRTDTypeInfo;
                    obj.Range = daq.ni.utility.RTDRange(obj.RTDTypeInfo,obj.UnitsInfo);
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
        
        function set.RTDConfigurationInfo(obj,newRTDConfigurationInfo)
            try
                if obj.PropertyChangeInProgress
                    obj.RTDConfigurationInfo = newRTDConfigurationInfo;
                    obj.RTDConfiguration = char(newRTDConfigurationInfo);
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newRTDConfigurationInfo = daq.RTDConfiguration.setValue(newRTDConfigurationInfo);
                    obj.channelPropertyBeingChanged('RTDConfigurationInfo',newRTDConfigurationInfo)
                    % Keep the hidden and visible properties in sync
                    obj.RTDConfigurationInfo = newRTDConfigurationInfo;
                    obj.RTDConfiguration = char(newRTDConfigurationInfo);
                    obj.Range = daq.ni.utility.RTDRange(obj.RTDConfigurationInfo,obj.UnitsInfo);
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
        
        function set.RTDConfiguration(obj,newRTDConfiguration)
            try
                if obj.PropertyChangeInProgress
                    obj.RTDConfiguration = newRTDConfiguration;
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    obj.lastGoodRTDConfiguration = obj.RTDConfiguration;
                    newRTDConfigurationInfo = daq.RTDConfiguration.setValue(newRTDConfiguration);
                    % Really, we only change the underlying hidden property
                    % with the enumeration -- and we only report that change
                    obj.channelPropertyBeingChanged('RTDConfigurationInfo',newRTDConfigurationInfo)
                    % Keep the hidden and visible properties in sync
                    obj.RTDConfiguration = char(newRTDConfigurationInfo);
                    obj.RTDConfigurationInfo = newRTDConfigurationInfo;
                    obj.Range = daq.ni.utility.RTDRange(obj.RTDConfigurationInfo,obj.UnitsInfo);
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
        
        function set.R0(obj,newR0)
            try
                if obj.PropertyChangeInProgress
                    obj.R0 = newR0;
                    return
                end
                
                % Check that newR0 is a scalar numeric greater than 0
                if isempty(newR0) || ~isscalar(newR0) ||...
                        ~daq.internal.isNumericNum(newR0) || newR0 <= 0
                    obj.localizedError('nidaq:ni:invalidRTDR0');
                end
                    
                try
                    obj.PropertyChangeInProgress = true;
                    obj.channelPropertyBeingChanged('R0',newR0)
                    % Keep the hidden and visible properties in sync
                    obj.R0 = newR0;
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
            [status] = daq.ni.NIDAQmx.DAQmxSetAICoupling(taskHandle,obj.PhysicalChannel,daq.ni.utility.DAQToNI(obj.CouplingInfo));
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
        
        function createChannelAndCaptureParameters(obj,taskHandle)
            obj.createChannelFirstTime(taskHandle)
            obj.captureAnalogInputRTDParametersFromNIDAQmx(taskHandle)
        end
    end
    
    % Protected template methods with optional implementation by a subclass
    methods (Access = protected)
        function newRange = setRangeHook(obj,value)
            % Override standard set behavior for Range.  For RTD
            % channels, this property is read only, and driven by the
            % RTDConfiguration and Units property
            if ~obj.PropertyChangeInProgress
                obj.localizedError('nidaq:ni:RTDRangeIsReadOnly');
            end
            
            obj.channelPropertyBeingChanged('Range',value)
            newRange = value;
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
                    case 'UnitsInfo'
                        [status] = daq.ni.NIDAQmx.DAQmxSetAITempUnits(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            daq.ni.utility.DAQToNI(newValue));
                        daq.ni.utility.throwOrWarnOnStatus(status);
                    case 'RTDTypeInfo'
                        [~] = daq.ni.NIDAQmx.DAQmxSetAIRTDType(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            daq.ni.utility.DAQToNI(newValue));
                        % If the property is not supported we will get an
                        % error on read
                        [status,readValue] = daq.ni.NIDAQmx.DAQmxGetAIRTDType(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            int32(0));
                        if readValue ~= daq.ni.utility.DAQToNI(newValue)
                            originalRTDTypeInfo...
                                = daq.RTDType.setValue(obj.lastGoodRTDType);
                            [setStatus] = daq.ni.NIDAQmx.DAQmxSetAIRTDType(...
                                taskHandle,...          % taskHandle
                                obj.PhysicalChannel,... % channel
                                daq.ni.utility.DAQToNI(originalRTDTypeInfo));
                            daq.ni.utility.throwOrWarnOnStatus(setStatus);
                            obj.RTDType = obj.lastGoodRTDType;
                        end
                        daq.ni.utility.throwOrWarnOnStatus(status);
                    case 'RTDConfigurationInfo'
                        [~] = daq.ni.NIDAQmx.DAQmxSetAIResistanceCfg(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            daq.ni.utility.DAQToNI(newValue));
                        % If the property is not supported we will get an
                        % error on read
                        [status,readValue] = daq.ni.NIDAQmx.DAQmxGetAIResistanceCfg(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            int32(0));
                        if readValue ~= daq.ni.utility.DAQToNI(newValue)                          
                            if strcmp(obj.lastGoodRTDConfiguration,'Unknown')
                                % Defaults for first time channel creation
                                originalRTDConfigurationInfo = daq.RTDConfiguration.ThreeWire;
                            else
                                originalRTDConfigurationInfo...
                                = daq.RTDType.setValue(obj.lastGoodRTDConfiguration);
                            end
                            
                            [setStatus] = daq.ni.NIDAQmx.DAQmxSetAIResistanceCfg(...
                                taskHandle,...          % taskHandle
                                obj.PhysicalChannel,... % channel
                                daq.ni.utility.DAQToNI(originalRTDConfigurationInfo));
                            daq.ni.utility.throwOrWarnOnStatus(setStatus);
                            obj.RTDConfiguration = obj.lastGoodRTDConfiguration;
                        end
                        daq.ni.utility.throwOrWarnOnStatus(status);
                    case 'R0'
                        [status] = daq.ni.NIDAQmx.DAQmxSetAIRTDR0(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            newValue);
                        daq.ni.utility.throwOrWarnOnStatus(status);
                    case 'Range'
                        [status] = daq.ni.NIDAQmx.DAQmxSetAIMin(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            newValue.Min);
                        daq.ni.utility.throwOrWarnOnStatus(status);
                        [status] = daq.ni.NIDAQmx.DAQmxSetAIMax(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            newValue.Max);
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
            
            % User is required to set RTD parameters before starting
            if strcmp(obj.RTDType, 'Unknown') && ...
               strcmp(obj.RTDConfiguration, 'Unknown') && ...
               strcmp(obj.RTDConfiguration, 'Unknown')
                obj.localizedError('nidaq:ni:mustSetRTDParams',obj.PhysicalChannel)
            end
            
            if strcmp(obj.RTDType, 'Unknown')
                obj.localizedError('nidaq:ni:mustSetRTDType',obj.PhysicalChannel)
            end
            
            if strcmp(obj.RTDConfiguration, 'Unknown')
                obj.localizedError('nidaq:ni:mustSetRTDConfiguration',obj.PhysicalChannel)
            end
            
            if strcmp(obj.R0, 'Unknown')
                obj.localizedError('nidaq:ni:mustSetRTDR0',obj.PhysicalChannel)
            end
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
            measurementTypeDisplayText = 'RTD';
        end
        
        function createChannelFirstTime(obj,taskHandle)
                obj.createChannel(taskHandle);
        end
    end
    
    % Friends
    methods(Hidden)
        function channelDescriptionText = getChannelDescriptionHook(obj) %#ok<MANU>
            % getChannelDescriptionText A function that returns the string
            % to display the channel description in the channel display
            % operation
            channelDescriptionText = 'analog input RTD channel';
        end
    end
    
    % Protected methods for use by a subclass
    methods (Sealed, Access = protected)
        function captureAnalogInputRTDParametersFromNIDAQmx(obj,taskHandle)
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
            minTemperatureToMeasure = 0;
            maxTemperatureToMeasure = 100;
            isSupported = false;
            try
                physcialChannel = sprintf('%s/ai0',device);
                [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                defaultExcitationValue = 0.004;
                [arraysize, ~] = daq.ni.NIDAQmx.DAQmxGetDevAICurrentIntExcitDiscreteVals(...
                    device,...          % device
                    0,...               % data
                    uint32(0));         % arraySizeInElements
                if arraysize ~= 0
                    [status, obj.ExcitationValues] = daq.ni.NIDAQmx.DAQmxGetDevAICurrentIntExcitDiscreteVals(...
                        device,...              % device
                        zeros(1,arraysize),...  % data
                        uint32(arraysize));     % arraySizeInElements
                    daq.ni.utility.throwOrWarnOnStatus(status);
                    % Set the default to the minimum excitation value greater
                    % than 0
                    defaultExcitationValue = min(obj.ExcitationValues(obj.ExcitationValues > 0));
                end

                [status] = daq.ni.NIDAQmx.DAQmxCreateAIRTDChan(...
                    taskHandle,...                          % taskHandle
                    physcialChannel,...                     % physicalChannel
                    blanks(0),...                           % nameToAssignToChannel
                    minTemperatureToMeasure,...                  % minVal
                    maxTemperatureToMeasure,...                  % maxVal
                    daq.ni.NIDAQmx.DAQmx_Val_DegC,...       % units
                    daq.ni.NIDAQmx.DAQmx_Val_Pt3851,...     % RTD type
                    daq.ni.NIDAQmx.DAQmx_Val_3Wire,...      % wires
                    daq.ni.NIDAQmx.DAQmx_Val_Internal,...   % excitation source
                    defaultExcitationValue,...              % excitation current
                    100);                                   % r0
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                % G707014: Some analog input devices allow creation of an
                % RTD channel despite not supporting RTD. Verify RTD
                % support by attempting to read a scan.
                [status,~,~] = daq.ni.NIDAQmx.DAQmxReadAnalogScalarF64(...
                    taskHandle,...  % taskHandle
                    double(1),...   % timeout
                    double(0),...   % readValue
                    uint32(0));     % reserved 
                
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
        function createChannel(obj,taskHandle)
            if obj.RTDTypeInfo == daq.RTDType.Unknown
                % Defaults for first time channel creation
                RTDTypeVal = daq.RTDType.Pt3851;
                RTDRangeVal = daq.ni.utility.RTDRange(obj.RTDTypeInfo,obj.UnitsInfo);
            else
                RTDTypeVal = obj.RTDTypeInfo;
                RTDRangeVal = obj.Range;
            end
            
            if obj.RTDConfigurationInfo == daq.RTDConfiguration.Unknown
                % Defaults for first time channel creation
                RTDConfigurationVal = daq.RTDConfiguration.ThreeWire;
            else
                RTDConfigurationVal = obj.RTDConfigurationInfo;
            end
            
            if strcmp(obj.R0, 'Unknown')
                % Defaults for first time channel creation
                R0Val = 100;
            else
                R0Val = obj.R0;
            end
            
            [status] = daq.ni.NIDAQmx.DAQmxCreateAIRTDChan (...
                taskHandle,...                          % The task handle
                obj.PhysicalChannel,...                 % physicalChannel
                char(0),...                             % nameToAssignToChannel
                RTDRangeVal.Min,...                     % minVal
                RTDRangeVal.Max,...                     % maxVal
                daq.ni.utility.DAQToNI(obj.UnitsInfo),...              % units
                daq.ni.utility.DAQToNI(RTDTypeVal),...                 % RTD type
                daq.ni.utility.DAQToNI(RTDConfigurationVal),...        % wiring configuration
                daq.ni.utility.DAQToNI(obj.ExcitationSourceInfo),...   % excitation source
                obj.ExcitationCurrent,...               % excitation current
                R0Val);                                 % R0
            daq.ni.utility.throwOrWarnOnStatus(status);           
        end
    end
    
     properties (Hidden, Access = private)
        
        %lastGoodRTDType Last correct value is stored so that we
        %can restore if the driver errors on read
        lastGoodRTDType;
        
        %lastGoodRTDConfiguration Last correct value is stored so that we
        %can restore if the driver errors on read
        lastGoodRTDConfiguration;
        
    end
end
