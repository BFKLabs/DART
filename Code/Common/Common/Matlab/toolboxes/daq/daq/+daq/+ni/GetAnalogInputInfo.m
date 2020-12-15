classdef (Hidden) GetAnalogInputInfo < handle
    %GetAnalogInputInfo Analog Subsystem properties for National Instrument
    % devices
    %
    %    This class queries the device for properties needed by the analog
    %    subsystem on devices by National Instruments.
    %
    %    This undocumented class may be removed in a future release.
    
    % Copyright 2011-2012 The MathWorks, Inc.
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods(Hidden)
        function obj = GetAnalogInputInfo(device,AIPhysicalChans,model,minimumSampleRate)
            
            obj.measurementTypesAvailable   = cell(0,0);
            obj.defaultMeasurementType      = [];
            
            obj.superSetOfRangesAvailable   = daq.Range.empty();
            
            obj.rangesAvailableForDifferential              = daq.Range.empty();
            obj.rangesAvailableForSingleEnded               = daq.Range.empty();
            obj.rangesAvailableForSingleEndedNonReferenced  = daq.Range.empty();
            obj.rangesAvailableForPseudoDifferential        = daq.Range.empty();
            
            obj.couplingsAvailable   = daq.Coupling.empty();
            obj.terminalConfigsAvailable = daq.TerminalConfig.empty();
            
            obj.channelToTest = [device '/' AIPhysicalChans{1}];
            obj.device = device;
            obj.model = model;
            obj.minimumSampleRate = minimumSampleRate;
            
            obj.onDemandOperationsSupported = true;
            
            %Store an Legacy object. This object can be used to get device
            %properties if the new approach fails.
            obj.legacyGetAnalogInputInfo = daq.ni.GetAnalogInputInfoLegacy(...
                obj.channelToTest);
            
        end
        
        function queryDevice(obj)
            %This function queries the device for all necessary
            %information.
            
            %Detect if voltage channel is supported.If supported,add
            %available ranges to superSetOfRangesAvailable
            obj.detectVoltageChannelAndGetRanges();
            
            %Detect if voltage channel is supported.If supported,add
            %available ranges to superSetOfRangesAvailable
            obj.detectCurrentChannelAndGetRanges();
            
            %Get the maximum and minimum rate supported by the analog
            %subsystem
            obj.getRateLimitInfo();
            
            %Get sample type supported by analog subsystem
            obj.getSampleType();
            
            %Get all the available coupling types AC/DC for a device
            obj.getAvailableCouplings()
            
            %Get the inputTypes supported by the device
            obj.getAvailableTerminalConfigs();
            
            %Properties like resolution etc can only be acquired from a
            %channel
            obj.getChannelSpecificProperties();
            
            if any(strcmp('Voltage', obj.measurementTypesAvailable)) ||...
                    any(strcmp('Current', obj.measurementTypesAvailable))
                % Some devices have different ranges depending on the inputType
                % of a channel (For Example. B-series 6008). So getting supported ranges
                % for all inputTypesAvailable
                if(any(obj.terminalConfigsAvailable == daq.TerminalConfig.Differential))
                    obj.rangesAvailableForDifferential = obj.getSupportedRangesForInputType(...
                        daq.TerminalConfig.Differential);
                end
                if(any(obj.terminalConfigsAvailable == daq.TerminalConfig.SingleEnded))
                    obj.rangesAvailableForSingleEnded = obj.getSupportedRangesForInputType(...
                        daq.TerminalConfig.SingleEnded);
                end
                if(any(obj.terminalConfigsAvailable == daq.TerminalConfig.SingleEndedNonReferenced))
                    obj.rangesAvailableForSingleEndedNonReferenced = obj.getSupportedRangesForInputType(...
                        daq.TerminalConfig.SingleEndedNonReferenced);
                end
                if(any(obj.terminalConfigsAvailable == daq.TerminalConfig.PseudoDifferential))
                    obj.rangesAvailableForPseudoDifferential =  obj.getSupportedRangesForInputType( ...
                        daq.TerminalConfig.PseudoDifferential);
                end
            else
                obj.rangesAvailableForDifferential = obj.superSetOfRangesAvailable;
            end
            
            %Detect if the device supports any specialized measurement
            %channels like RTD, Thermocouple, Bridge etc
            obj.detectSpecializedMeasurementChannels();
        end
    end
    
    methods(Hidden)
        
        function detectVoltageChannelAndGetRanges(obj)
            
            try
                %If property is not accessible through the new
                %methods, this functions calls the same methods on the legacy
                %object if available.
                [arraysize,~] = daq.ni.NIDAQmx.DAQmxGetDevAIVoltageRngs(obj.device, zeros(1,1), uint32(0));
                
                if arraysize ~= 0
                    [status,AIVoltageRngs] = daq.ni.NIDAQmx.DAQmxGetDevAIVoltageRngs(obj.device, zeros(arraysize,1), uint32(arraysize));
                    daq.ni.utility.throwOrWarnOnStatus(status);
                    AIVoltageRngs = reshape(AIVoltageRngs,2,arraysize/2)';
                    for iRange = 1:size(AIVoltageRngs,1)
                        obj.superSetOfRangesAvailable(end + 1) = daq.Range(AIVoltageRngs(iRange,1),AIVoltageRngs(iRange,2),'Volts');
                    end
                    % Get voltage ranges Available
                    
                    obj.measurementTypesAvailable{end + 1} = 'Voltage';
                    if isempty(obj.defaultMeasurementType)
                        obj.defaultMeasurementType = 'Voltage';
                    end
                else
                    %If new method fails, fall back to legacy way
                    obj.legacyGetAnalogInputInfo.detectVoltageChannelAndGetRanges(obj);
                end
            catch %#ok<*CTCH>
                obj.superSetOfRangesAvailable(end + 1) = daq.Range(0,0,'Volts');
            end
            
        end
        
        function detectCurrentChannelAndGetRanges(obj)
            
            % Get current ranges Available
            [arraysize,~] = daq.ni.NIDAQmx.DAQmxGetDevAICurrentRngs(obj.device, zeros(1,1), uint32(0));
            if arraysize ~= 0
                obj.measurementTypesAvailable{end + 1} = 'Current';
                if isempty(obj.defaultMeasurementType)
                    obj.defaultMeasurementType = 'Current';
                end
                [status,AICurrentRngs] = daq.ni.NIDAQmx.DAQmxGetDevAICurrentRngs(obj.device, zeros(arraysize,1), uint32(arraysize));
                daq.ni.utility.throwOrWarnOnStatus(status);
                AICurrentRngs = reshape(AICurrentRngs,2,arraysize/2)';
                for iRange = 1:size(AICurrentRngs,1)
                    obj.superSetOfRangesAvailable(end + 1) = daq.Range(AICurrentRngs(iRange,1),AICurrentRngs(iRange,2),'A');
                end
            end
            
        end
        
        function getRateLimitInfo(obj)
            try
                % Get rateLimitInfo
                [status,obj.AIMinRate] = daq.ni.NIDAQmx.DAQmxGetDevAIMinRate(obj.device,double(0));
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                % G687868: On-demand only devices such as the NI USB-TC01 will
                % return a maximum single channel rate of 0
                [status,AIMaxSingleChanRate] = daq.ni.NIDAQmx.DAQmxGetDevAIMaxSingleChanRate(obj.device,double(0));
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                % G635448: If the device reports that it's minimum rate is zero
                % force the minimum allowed by any clocked subsystem. G687868:
                % Make sure the minimum remains below the maximum.
                obj.AIMinRate = min(AIMaxSingleChanRate, max(obj.AIMinRate,obj.minimumSampleRate));
                
                obj.rateLimitInfo = daq.internal.ParameterLimit(obj.AIMinRate,AIMaxSingleChanRate);
                
            catch %#ok<CTCH>
                %If new method fails, fall back to legacy way
                obj.legacyGetAnalogInputInfo.getRateLimitInfo(obj);
            end
        end
        
        function getSampleType(obj)
            
            try
                % Get sampleType,...
                [status,AISimultaneousSamplingSupported] = daq.ni.NIDAQmx.DAQmxGetDevAISimultaneousSamplingSupported(obj.device,uint32(0));
                daq.ni.utility.throwOrWarnOnStatus(status);
                if AISimultaneousSamplingSupported ~= 0
                    obj.sampleType = daq.SampleType.Simultaneous;
                else
                    obj.sampleType = daq.SampleType.Scanning;
                end
                
            catch %#ok<CTCH>
                %If new method fails, fall back to legacy way
                obj.legacyGetAnalogInputInfo.getSampleType(obj);
            end
            
        end
        
        function getAvailableCouplings(obj)
            %If property is not accessible through the new
            %methods, this functions calls the same methods on the legacy
            %object if available.
            [status,AICouplings] = daq.ni.NIDAQmx.DAQmxGetDevAICouplings(obj.device,int32(0));
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            if bitand(uint32(AICouplings),uint32(daq.ni.NIDAQmx.DAQmx_Val_Bit_CouplingTypes_DC))
                obj.couplingsAvailable(end + 1) = daq.Coupling.DC;
            end
            
            if bitand(uint32(AICouplings),uint32(daq.ni.NIDAQmx.DAQmx_Val_Bit_CouplingTypes_AC))
                obj.couplingsAvailable(end + 1) = daq.Coupling.AC;
            end
            
            if(isempty(obj.couplingsAvailable))
                %If new method fails, fall back to legacy way
                obj.legacyGetAnalogInputInfo.getAvailableCouplings(obj)
                
            end
        end
        
        function getAvailableTerminalConfigs(obj)
            %If property is not accessible through the new
            %methods, this functions calls the same methods on the legacy
            %object if available.
            [status,AITermCfgs] = daq.ni.NIDAQmx.DAQmxGetPhysicalChanAITermCfgs(obj.channelToTest, int32(0));
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            
            if bitand(uint32(AITermCfgs),uint32(daq.ni.NIDAQmx.DAQmx_Val_Bit_TermCfg_RSE))
                obj.terminalConfigsAvailable(end + 1) = daq.TerminalConfig.SingleEnded;
            end
            
            if bitand(uint32(AITermCfgs),uint32(daq.ni.NIDAQmx.DAQmx_Val_Bit_TermCfg_NRSE))
                obj.terminalConfigsAvailable(end + 1) = daq.TerminalConfig.SingleEndedNonReferenced;
            end
            
            if bitand(uint32(AITermCfgs),uint32(daq.ni.NIDAQmx.DAQmx_Val_Bit_TermCfg_Diff))
                obj.terminalConfigsAvailable(end + 1) = daq.TerminalConfig.Differential;
            end
            
            if bitand(uint32(AITermCfgs),uint32(daq.ni.NIDAQmx.DAQmx_Val_Bit_TermCfg_PseudoDIFF))
                obj.terminalConfigsAvailable(end + 1) = daq.TerminalConfig.PseudoDifferential;
            end
            
            if(isempty(obj.terminalConfigsAvailable))
                %If new method fails, fall back to legacy way
                obj.legacyGetAnalogInputInfo.getAvailableTerminalConfigs(obj)
            end
        end
        
        function detectSpecializedMeasurementChannels(obj)
            % Detect thermocouple capability
            if daq.ni.AnalogInputThermocoupleChannel.detectIfSupported(obj.device,obj.superSetOfRangesAvailable(1))
                obj.measurementTypesAvailable{end + 1} = 'Thermocouple';
                if isempty(obj.defaultMeasurementType)
                    obj.defaultMeasurementType = 'Thermocouple';
                end
            end
            
            % Detect accelerometer capability
            if daq.ni.AnalogInputAccelerometerChannel.detectIfSupported(obj.device,obj.superSetOfRangesAvailable(1))
                obj.measurementTypesAvailable{end + 1} = 'Accelerometer';
                if isempty(obj.defaultMeasurementType)
                    obj.defaultMeasurementType = 'Accelerometer';
                end
            end
            
            % Detect RTD capability
            if daq.ni.AnalogInputRTDChannel.detectIfSupported(obj.device)
                obj.measurementTypesAvailable{end + 1} = 'RTD';
                if isempty(obj.defaultMeasurementType)
                    obj.defaultMeasurementType = 'RTD';
                end
            end
            
            % Detect bridge capability
            if daq.ni.AnalogInputBridgeChannel.detectIfSupported(obj.device,obj.superSetOfRangesAvailable(1))
                bridgeChannelRanges = daq.ni.AnalogInputBridgeChannel.getSupportedRanges(obj.model);
                for ibridgeChannelRanges = 1:numel(bridgeChannelRanges)
                    obj.rangesAvailableForDifferential(end + 1) = ...
                        bridgeChannelRanges(ibridgeChannelRanges);
                end
                obj.measurementTypesAvailable{end + 1} = 'Bridge';
                if isempty(obj.defaultMeasurementType)
                    obj.defaultMeasurementType = 'Bridge';
                end
            end
            
            % Detect microphone capability
            if daq.ni.AnalogInputMicrophoneChannel.detectIfSupported(obj.device)
                obj.measurementTypesAvailable{end + 1} = 'Microphone';
                if isempty(obj.defaultMeasurementType)
                    obj.defaultMeasurementType = 'Microphone';
                end
            end
            
            % Detect IEPE capability
            if daq.ni.AnalogInputIEPEChannel.detectIfSupported(obj.device,obj.superSetOfRangesAvailable(1), obj.rateLimitInfo)
                obj.measurementTypesAvailable{end + 1} = 'IEPE';
                if isempty(obj.defaultMeasurementType)
                    obj.defaultMeasurementType = 'IEPE';
                end
            end
        end
        
        function getChannelSpecificProperties(obj)
            % These require a task to retrieve, since they are channel
            % based
            [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
            daq.ni.utility.throwOrWarnOnStatus(status);
            try
                % Create a channel in the task to use
                % !!! There's a number of possible failure modes here:
                %   1. Might not support voltage or current
                %   2. Range(1) might not be valid for channel
                if any(strcmp('Voltage', obj.measurementTypesAvailable))
                    [status] = daq.ni.NIDAQmx.DAQmxCreateAIVoltageChan (...
                        taskHandle,...                          % The task handle
                        obj.channelToTest,...                       % physicalChannel
                        char(0),...                             % nameToAssignToChannel
                        daq.ni.NIDAQmx.DAQmx_Val_Cfg_Default,...% terminalConfig
                        obj.superSetOfRangesAvailable(1).Min,...              % minVal
                        obj.superSetOfRangesAvailable(1).Max,...              % maxVal
                        daq.ni.NIDAQmx.DAQmx_Val_Volts,...      % units
                        char(0));                               % customScaleName
                    daq.ni.utility.throwOrWarnOnStatus(status);
                elseif any(strcmp('Current', obj.measurementTypesAvailable))
                    [status] = daq.ni.NIDAQmx.DAQmxCreateAICurrentChan (...
                        taskHandle,...                          % The task handle
                        obj.channelToTest,...                   % physicalChannel
                        char(0),...                             % nameToAssignToChannel
                        daq.ni.NIDAQmx.DAQmx_Val_Cfg_Default,...% terminalConfig
                        obj.superSetOfRangesAvailable(1).Min,...              % minVal
                        obj.superSetOfRangesAvailable(1).Max,...              % maxVal
                        daq.ni.NIDAQmx.DAQmx_Val_Amps,...       % units
                        daq.ni.NIDAQmx.DAQmx_Val_Default,...	% shuntResistorLoc  !!! should this be a property?
                        double(0),...                           % extShuntResistorVal
                        char(0));                               % customScaleName
                    daq.ni.utility.throwOrWarnOnStatus(status);
                elseif any(strcmp('Bridge', obj.measurementTypesAvailable))
                    safeExcitationValue = 2;
                    safeNominalResistancevalue = 350;
                    
                    bridgeConf = {daq.ni.NIDAQmx.DAQmx_Val_FullBridge,...
                        daq.ni.NIDAQmx.DAQmx_Val_HalfBridge,...
                        daq.ni.NIDAQmx.DAQmx_Val_QuarterBridge };
                    
                    for iBridgeConfig = 1:numel(bridgeConf)
                        try
                            [status] = daq.ni.NIDAQmx.DAQmxCreateAIBridgeChan(...
                                taskHandle,...                              % taskHandle
                                obj.channelToTest,...                       % physicalChannel
                                blanks(0),...                               % nameToAssignToChannel
                                obj.superSetOfRangesAvailable(2).Min,...    % minVal
                                obj.superSetOfRangesAvailable(2).Max,...    % maxVal
                                daq.ni.NIDAQmx.DAQmx_Val_VoltsPerVolt,...   % units
                                bridgeConf{iBridgeConfig} ,...             % bridgeConfig
                                daq.ni.NIDAQmx.DAQmx_Val_Internal ,...      % voltageExcitSource
                                safeExcitationValue,...                     % voltageExcitVal
                                safeNominalResistancevalue,...              % nominalBridgeResistance
                                char(0));                                   % customScaleName
                            daq.ni.utility.throwOrWarnOnStatus(status);
                        catch %#ok<CTCH>
                            % Try other bridge configurations
                        end
                    end
                elseif any(strcmp('RTD', obj.measurementTypesAvailable))
                    minTemperatureToMeasure = 0;
                    maxTemperatureToMeasure = 100;
                    defaultExcitationValue = 0.004;
                     
                    [status] = daq.ni.NIDAQmx.DAQmxCreateAIRTDChan(...
                        taskHandle,...                          % taskHandle
                        obj.channelToTest,...                     % physicalChannel
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
                    
                else
                    
                    % The device does not have any supported AI channel type.
                    % Do nothing here. The call to get resolution will fail
                    % below and an error will be thrown.
                    % Add additional channel types here.
                end
                
                % Get resolution
                [status,AIResolution] = daq.ni.NIDAQmx.DAQmxGetAIResolution(...
                    taskHandle,...
                    obj.channelToTest,...
                    double(0));
                % Check the status after insuring failure not caused by
                % need to set the sample rate first.
                
                % G496133 Some devices require that the sample rate be set
                % before other operations. This will be indicated by the
                % status of the attempt to get the resolution above.
                if status == daq.ni.NIDAQmx.DAQmxErrorSampClkRateMustBeSpecd
                    [status] = daq.ni.NIDAQmx.DAQmxSetSampClkRate(...
                        taskHandle,...
                        obj.AIMinRate);
                    daq.ni.utility.throwOrWarnOnStatus(status);
                    
                    [status,AIResolution] = daq.ni.NIDAQmx.DAQmxGetAIResolution(...
                        taskHandle,...
                        obj.channelToTest,...
                        double(0));
                    % Check status outside if block
                end
                daq.ni.utility.throwOrWarnOnStatus(status);
                obj.resolution = AIResolution;
                
                obj.onDemandOperationsSupported = ...
                    daq.ni.NICommonDeviceInfoAttrib.detectOnDemandSupport(taskHandle);
                
            catch
                % Make sure the task is cleaned up
                [~] = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
                obj.resolution = 'Unknown';
                
            end
            status = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
            daq.ni.utility.throwOrWarnOnStatus(status);
            
        end
        
        % Try to create voltage channels for each input type using the
        % different voltage ranges. Scan rate limits are not verified by
        % this function.
        function supportedRangesForInputType = getSupportedRangesForInputType(obj,InputType)
            % getSupportedRangesForInputType A helper function for this class.
            % This gives the supported ranges for a given InputType
            
            supportedRangesForInputType = daq.Range.empty;
            
            % g639771: DAQToNI is an expensive function and should not be called in
            % loop for performance considerations.
            cachedDAQInputType  = daq.ni.utility.DAQToNI(InputType);

            for iSupportedRanges = 1:numel(obj.superSetOfRangesAvailable);
                if any(strcmp('Voltage', obj.measurementTypesAvailable))
                    try
                        % Create a Task
                        [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
                        daq.ni.utility.throwOrWarnOnStatus(status);
                        
                        % Try creating channel with one of the supported ranges
                        [status] = daq.ni.NIDAQmx.DAQmxCreateAIVoltageChan (...
                            taskHandle,...                                  % The task handle
                            obj.channelToTest,...                           % physicalChannel
                            char(0),...                                     % nameToAssignToChannel
                            cachedDAQInputType,...                         % terminalConfig
                            obj.superSetOfRangesAvailable(iSupportedRanges).Min,...   % minVal
                            obj.superSetOfRangesAvailable(iSupportedRanges).Max,...   % maxVal
                            daq.ni.NIDAQmx.DAQmx_Val_Volts,...              % units
                            char(0));                                       % customScaleName
                        daq.ni.utility.throwOrWarnOnStatus(status);
                        
                        % DAQmxGetAITermCfg requires that we set the
                        % clock for devices such as NI 9234
                        if obj.rateLimitInfo.Max ~= 0
                            % Don't do this for on-demand only devices
                            
                            % G746758: Some devices like NI PXI-4472 do not
                            % report a correct minimum rate, or the rate
                            % requires special setup.
                            testRates = [obj.rateLimitInfo.Min 0.1:0.1:1 2:1:10 20:10:100 ...
                                200:100:1000 2000:1000:10000 20000:10000:100000 200000:100000:1000000 ...
                                2000000:1000000:10000000 obj.rateLimitInfo.Max];
                            testRates = testRates((testRates >= obj.rateLimitInfo.Min) & ...
                                (testRates <= obj.rateLimitInfo.Max));
                            for i = 1 : numel(testRates)
                                testRate = testRates(i);
                                
                                % The status of DAQmxSetSampClkRate was
                                % observed to always succeed. To determine
                                % if the rate is indeed valid, read the AI
                                % terminal configuration to see if setting
                                % the rate succeeded or not.
                                [~] = daq.ni.NIDAQmx.DAQmxSetSampClkRate(taskHandle, testRate);
                                [readStatus,~] = daq.ni.NIDAQmx.DAQmxGetAITermCfg(taskHandle,...
                                    obj.channelToTest, int32(0));
                                
                                % G746758: Since most devices report a
                                % valid minimum rate, we will exit the
                                % loop on the first iteration, resulting in
                                % no impact to performance of getDevices.
                                if readStatus == daq.ni.NIDAQmx.DAQmxSuccess
                                    obj.AIMinRate = testRate;
                                    obj.rateLimitInfo = daq.internal.ParameterLimit(obj.AIMinRate,obj.rateLimitInfo.Max);
                                    break;
                                end
                                % G767014: If a wireless device is
                                % disconnected from the network, exit
                                % sample rate search.
                                if readStatus == daq.ni.NIDAQmx.DAQmxErrorNetworkStatusTimedOut
                                    daq.ni.utility.throwOrWarnOnStatus(readStatus);
                                end
                            end
                        else
                            % If channel creation was unsuccessful, a read operation
                            % should error out
                            [readStatus,~] = daq.ni.NIDAQmx.DAQmxGetAITermCfg(taskHandle,...
                                obj.channelToTest, int32(0));
                        end
                        
                        % Clear the task
                        status = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
                        daq.ni.utility.throwOrWarnOnStatus(status);
                        
                        % Check for the read status
                        if readStatus == daq.ni.NIDAQmx.DAQmxSuccess
                            if ~obj.superSetOfRangesAvailable(iSupportedRanges).existsInList(supportedRangesForInputType)
                                supportedRangesForInputType = [ supportedRangesForInputType obj.superSetOfRangesAvailable(iSupportedRanges)]; %#ok<AGROW>
                            end
                        end
                    catch e
                        % Make sure the task is cleaned up
                        [~] = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
                        rethrow(e)
                    end
                    
                end
                if any(strcmp('Current', obj.measurementTypesAvailable))
                    try
                        % Create a Task
                        [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
                        daq.ni.utility.throwOrWarnOnStatus(status);
                        
                        % The value, in ohms, of an external shunt resistor.
                        defaultExternalShuntResistorValue = 1e-6;
                        
                        % Try creating channel with one of the supported ranges
                        [status] = daq.ni.NIDAQmx.DAQmxCreateAICurrentChan (...
                            taskHandle,...                            % The task handle
                            obj.channelToTest,...                         % physicalChannel
                            char(0),...                               % nameToAssignToChannel
                            daq.ni.utility.DAQToNI(InputType),... 					  % terminalConfig
                            obj.superSetOfRangesAvailable(iSupportedRanges).Min,...   % minVal
                            obj.superSetOfRangesAvailable(iSupportedRanges).Max,...   % maxVal
                            daq.ni.NIDAQmx.DAQmx_Val_Amps,...       % units
                            daq.ni.NIDAQmx.DAQmx_Val_Default,...	% shuntResistorLoc
                            defaultExternalShuntResistorValue,...   % extShuntResistorVal
                            char(0));                               % customScaleName
                        daq.ni.utility.throwOrWarnOnStatus(status);
                        
                        % DAQmxGetAITermCfg requires that we set the
                        % clock for devices such as NI 9234
                        if obj.rateLimitInfo.Max ~= 0
                            % Don't do this for on-demand only devices
                            [status] = daq.ni.NIDAQmx.DAQmxSetSampClkRate(taskHandle, obj.rateLimitInfo.Min);
                            daq.ni.utility.throwOrWarnOnStatus(status);
                        end
                        
                        % If channel creation was unsuccessful, a read operation
                        % should error out
                        [readStatus,~] = daq.ni.NIDAQmx.DAQmxGetAITermCfg(taskHandle,...
                            obj.channelToTest, int32(0));
                        
                        % Clear the task
                        status = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
                        daq.ni.utility.throwOrWarnOnStatus(status);
                        
                        % Check for the read status
                        if readStatus == daq.ni.NIDAQmx.DAQmxSuccess
                            if ~obj.superSetOfRangesAvailable(iSupportedRanges).existsInList(supportedRangesForInputType)
                                supportedRangesForInputType = [ supportedRangesForInputType obj.superSetOfRangesAvailable(iSupportedRanges)]; %#ok<AGROW>
                            end
                        end
                    catch e
                        % Make sure the task is cleaned up
                        [~] = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
                        rethrow(e)
                    end
                end
            end
        end
        
    end
    
    
    properties(Hidden, Access = public)
        % Analog Subsystem properties that need to be queried from the
        % device
        measurementTypesAvailable;
        defaultMeasurementType;
        
        superSetOfRangesAvailable;
        rangesAvailableForDifferential;
        rangesAvailableForSingleEnded;
        rangesAvailableForSingleEndedNonReferenced;
        rangesAvailableForPseudoDifferential;
        
        rateLimitInfo;
        
        couplingsAvailable;
        terminalConfigsAvailable;
        
        sampleType;
        resolution;
        onDemandOperationsSupported;
    end
    
    properties(Hidden, SetAccess = private)
        channelToTest;
        device;
        model;
        minimumSampleRate;
        AIMinRate;
    end
    
    properties (Hidden,Access = private )
        legacyGetAnalogInputInfo;
    end
end

