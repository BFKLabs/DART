classdef (Hidden) ChannelGroupDigitalOutput < daq.ni.ChannelGroup
    %ChannelGroup Represents a NI-DAQmx task used for digital output
    
    % Copyright 2012 The MathWorks, Inc.
    
    %% private properties
    properties(Access = private)
        AsyncIOChannel;
        OutputBufferSize;
        IsSingleScanTiming;
    end
    
    %% constructor/destructor
    methods
        function obj = ChannelGroupDigitalOutput(session,name)
            % Get the device name from the group name
            deviceID = sscanf(name,'do/%s');
            obj@daq.ni.ChannelGroup(session,name,deviceID);
            
            obj.OutputBufferSize = 0;
            obj.IsSingleScanTiming = false;
            obj.AsyncIOChannel = daq.ni.AsyncIOOutputChannel(session, obj, 'mwnidaqmxdo');
        end
        
        function delete(obj)
            try
                delete(obj.AsyncIOChannel);
                obj.AsyncIOChannel = [];
            catch e %#ok<NASGU>
            end
        end
    end
    
    %% AsyncIOChannel methods
    methods
        function openStream(obj, taskHandle, numberOfScans, bufferingBlockSize, numChannels, isContinuous,externalTriggerTimeout)
            obj.AsyncIOChannel.openStream(taskHandle, numberOfScans, bufferingBlockSize, numChannels, isContinuous,externalTriggerTimeout)
        end
        
        function flushStream(obj)
            obj.AsyncIOChannel.flushStream();
        end
        
        function closeStream(obj)
            if ~isempty(obj.AsyncIOChannel)
                obj.AsyncIOChannel.closeStream();
            end
        end
        
        function startTask(obj)
            obj.AsyncIOChannel.startTask();
        end
    end
    
    %% Sync/Trigger methods
    methods
        % For digital subsystem, only the scan clock is needed for
        % synchronization
        function [scanClock] = getScanClockConfiguration(obj)
            % Internal -- return what was actually selected
            [status,terminal] = daq.ni.NIDAQmx.DAQmxGetSampClkTerm(obj.TaskHandle,blanks(1000),uint32(1000));
            if status==daq.ni.NIDAQmx.DAQmxErrorCannotGetPropertyWhenTaskNotReservedCommittedOrRunnin ||...
                    status == daq.ni.NIDAQmx.DAQmxErrorAttributeNotSupportedInTaskContext
                %Related to G635856.  The workaround prevents the commit of
                %simulated devices.  This means that the exact terminal is
                %not selected on CompactDAQ devices, and
                %DAQmxGetSampClkTerm.  Use DAQmxGetSampClkSrc instead and
                %change <Device>/?/SampleClockTimebase to
                %<Device>/do/SampleClock
                [status,terminal] = daq.ni.NIDAQmx.DAQmxGetSampClkSrc(obj.TaskHandle,blanks(1000),uint32(1000));
                posQuestion = strfind(terminal,'/?/SampleClockTimebase');
                if ~isempty(posQuestion)
                    terminal = [terminal(1:posQuestion-1) '/do/SampleClock'];
                end
                % SampleClockTimebase is also not correct -- fix to SampleClock
                posSampleClockTimebase = strfind(terminal,'SampleClockTimebase');
                if ~isempty(posSampleClockTimebase)
                    terminal = [terminal(1:posSampleClockTimebase-1) 'SampleClock'];
                end
            end
            
            obj.checkClockConfigurationStatus(status);
            scanClock = terminal;
        end
        
        function writeData(obj,dataToOutput)
            % An array of objects is not allowed
            if numel(obj) ~= 1
                obj.LocalizedError('nidaq:ni:cannotWriteDataToMultipleGroups')
            end
            
            obj.InternalState.writeData(dataToOutput);
        end
        
        function flush(objArray)
            % flush() flush output data from AsyncIO
            % Remember, this could be an array of objects
            for iObj = 1:numel(objArray)
                obj = objArray(iObj);
                obj.InternalState.flush();
            end
        end
    end
    
    % Friend methods
    methods(Hidden)
        function doConfigureForSingleScan(obj)
            try
                if obj.IsSingleScanTiming == false
                    obj.clearTask();
                    obj.doCreateTask();
                    obj.commitTask();
                    obj.updateChannelMap();
                    obj.IsSingleScanTiming = true;
                end
            catch e
                obj.clearTask();
                obj.doCreateTask();
                obj.updateChannelMap();
                obj.IsSingleScanTiming = false;
                error = obj.Session.processNIDAQmxDriverError(obj.ChannelIOIndexMap, ...
                    e.identifier, ...
                    e.message);
                throw(error);
            end
        end
        
        function doConfigureForMultipleScans(obj)
            try
                obj.stopTask();
                obj.doUpdateNumberOfScans();
                obj.configureExportedSignals();
                obj.configureTriggerAndIgnoreErrorIfNeeded();               
                obj.commitTask();
                obj.IsSingleScanTiming = false;
                obj.IsConfigured = true;
            catch e
                error = obj.Session.processNIDAQmxDriverError(obj.ChannelIOIndexMap, ...
                    e.identifier, ...
                    e.message);
                throw(error);
            end
        end
        
        function doUpdateNumberOfScans(obj)
            calculateAndConfigureBlockSize();
            obj.doConfigureReferenceClock();
            configureScanClock();
            
            function calculateAndConfigureBlockSize()
                % Calculate the output buffer size as a multiple of the
                % buffering block size
                [outputBufferSize, obj.BufferingBlockSize, obj.NumScansConfigured] = obj.Session.getOutputBufferBlockSize();
                
                obj.OutputBufferSize = outputBufferSize;
                
                [status] = daq.ni.NIDAQmx.DAQmxCfgOutputBuffer(...
                    obj.TaskHandle,...  % taskHandle
                    uint32(obj.OutputBufferSize));
                daq.ni.utility.throwOrWarnOnStatus(status);
            end
            
            function configureScanClock()
                
                % Configure the clocking
                if obj.Session.IsContinuous
                    sampleMode = daq.ni.NIDAQmx.DAQmx_Val_ContSamps;
                else
                    sampleMode = daq.ni.NIDAQmx.DAQmx_Val_FiniteSamps;
                end
                
                % G747293: This function is called when rate is changed.
                % Set obj.IsSingleScanTiming to false, allowing
                % doConfigureForSingleScan to set parameters properly
                obj.IsSingleScanTiming = false;
                
                clockSource = daq.SyncManager.Default;
                
                if ~strcmp(obj.SyncInfo.ScanClock,daq.SyncManager.Default)
                    clockSource = obj.SyncInfo.ScanClock;
                end
                
                if strcmp(clockSource,daq.SyncManager.Default)
                    obj.localizedError('daq:channel:DIOExternalClock',...
                        obj.Session.Channels(obj.ChannelIndexMap(1)).getChannelDescriptionHook(),...
                        obj.Session.getChannelIDs(obj.ChannelIndexMap(1)))
                end
                
                if obj.NumScansConfigured == 0
                    % default to 2, so that we can get a valid rate
                    numOfScans = uint64(2);
                else
                    numOfScans = obj.NumScansConfigured;
                end
                
                % G662854: Prevent output regeneration, necessary with
                % cDAQ-9172 chassis
                [status] = daq.ni.NIDAQmx.DAQmxSetWriteRegenMode(...
                    obj.TaskHandle,...  % taskHandle
                    daq.ni.NIDAQmx.DAQmx_Val_DoNotAllowRegen);
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                [status] = daq.ni.NIDAQmx.DAQmxCfgSampClkTiming(...
                    obj.TaskHandle,...                  % taskHandle,
                    clockSource,...                     % source
                    obj.Session.Rate,...                % rate
                    daq.ni.NIDAQmx.DAQmx_Val_Rising,... % activeEdge
                    sampleMode,...                      % sampleMode
                    numOfScans);
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                [status, ~] = daq.ni.NIDAQmx.DAQmxGetSampClkRate(...
                    obj.TaskHandle,...
                    double(0));
                
                % Some DO devices like USB-4331 have fixed update rates and
                % they error out if incorrect rate was chosen. If setting
                % default rate was unsuccessful, try to get the supported
                % discrete rates from DeviceInfo
                if status ~= daq.ni.NIDAQmx.DAQmxSuccess
                    tryDiscreteOutputRates();
                    [status] = daq.ni.NIDAQmx.DAQmxCfgSampClkTiming(...
                        obj.TaskHandle,...                  % taskHandle,
                        clockSource,...                     % source
                        obj.Session.Rate,...                % rate
                        daq.ni.NIDAQmx.DAQmx_Val_Rising,... % activeEdge
                        sampleMode,...                      % sampleMode
                        numOfScans);
                    daq.ni.utility.throwOrWarnOnStatus(status);
                end
                
                function tryDiscreteOutputRates()
                    discreteRates = zeros(1, numel(obj.ChannelIndexMap));
                    count = 0;
                    for chan = 1:numel(obj.ChannelIndexMap)
                        rates = obj.Session.Channels(obj.ChannelIndexMap(chan)).Device.getOutputUpdateRatesFromDataSheet();
                        if ~isempty(rates)
                            discreteRates(count + 1) = rates;
                            count = count + 1;
                        end
                    end
                    if count == 0
                        % If no discrete rates were found, return without
                        % error. This would give the user a chance to set the
                        % correct rate.
                        return
                    else
                        % Choose the next higher rate supported by the device.
                        diff = discreteRates - obj.Session.Rate;
                        diff(diff < 0) = NaN;
                        [~, index] = min(diff);
                        obj.Session.Rate = discreteRates(index);
                    end
                end
            end
        end
        
        function doWriteData(objArray,dataToOutput)
            for iObj = 1:numel(objArray)
                obj = objArray(iObj);
                obj.AsyncIOChannel.doWriteData(dataToOutput);
            end
        end
        
        function doWriteDataLastBlock(objArray)
            for iObj = 1:numel(objArray)
                obj = objArray(iObj);
                obj.AsyncIOChannel.doWriteDataLastBlock();
            end
        end
    end
    
    % Internal constants
    properties(Constant, GetAccess = private)
        % Configure output buffer to this many buffering blocks
        OutputBufferSizeInBlocks = 4;
    end
    
    % Superclass methods this class implements
    methods (Hidden)
        function updateChannelMap(obj)
            updateChannelMapBase(obj,daq.internal.SubsystemType.DigitalIO);
        end
    end
    
    % Superclass methods this class implements
    methods (Access = protected)
        function resetImpl(obj)
            % Reset digital outputs to zero at daq.reset g699723
            [~,~,~] =...
                daq.ni.NIDAQmx.DAQmxWriteDigitalLines(...
                obj.TaskHandle,...                                      % taskHandle
                int32(1),...                                            % numSampsPerChan
                uint32(true),...                                        % autoStart
                double(1),...                                           % timeout
                uint32(daq.ni.NIDAQmx.DAQmx_Val_GroupByScanNumber),...  % dataLayout
                uint8(0),...                                            % writeArray
                int32(0),...                                            % sampsPerChanWritten
                uint32(0));                                             % reserved
        end
    end
end
