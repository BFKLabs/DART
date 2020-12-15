classdef (Hidden) ChannelGroupDigitalInput < daq.ni.ChannelGroup
    %ChannelGroupDigitalInput Represents a group of digital input channels
    %sharing a NIDAQmx task
    
    % Copyright 2013 The MathWorks, Inc.
    
    %% private properties
    properties(Access = private)
        AsyncIOChannel;
        IsSingleScanTiming;
    end
    
    %% constructor/destructor
    methods
        function obj = ChannelGroupDigitalInput(session,name)
            % Get the device name from the group name
            deviceID = sscanf(name,'di/%s');
            obj@daq.ni.ChannelGroup(session,name,deviceID);

            obj.IsSingleScanTiming = false;
            obj.AsyncIOChannel = daq.ni.AsyncIOInputChannel(session, obj, 'mwnidaqmxdi');
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
        
        %Retrieve the start trigger terminal that was actually selected
        function startTrigger = getStartTriggerConfiguration(obj)
           
            [status,type] = daq.ni.NIDAQmx.DAQmxGetStartTrigType(obj.TaskHandle,int32(0));
             if status ~= daq.ni.NIDAQmx.DAQmxSuccess
                    startTrigger = [ '/',obj.getDeviceIDForSync(),'/di/StartTrigger'];
                    return;
             end
            if type == daq.ni.NIDAQmx.DAQmx_Val_None
                [status,startTrigger] = daq.ni.NIDAQmx.DAQmxGetStartTrigTerm(obj.TaskHandle,blanks(1000),uint32(1000));
                if status == daq.ni.NIDAQmx.DAQmxErrorCannotGetPropertyWhenTaskNotReservedCommittedOrRunnin ||...
                        status == daq.ni.NIDAQmx.DAQmxErrorAttributeNotSupportedInTaskContext
                    %Related to G635856.  The workaround prevents the commit of
                    %simulated devices.  This means that the exact terminal is not
                    %selected on CompactDAQ devices.  Use a reasonable
                    %default
                    startTrigger = [ '/',obj.getDeviceIDForSync(),'/di/StartTrigger'];
                    status = daq.ni.NIDAQmx.DAQmxSuccess;
                end
                daq.ni.utility.throwOrWarnOnStatus(status);
                return
            end
            
            [status,startTrigger] = daq.ni.NIDAQmx.DAQmxGetDigEdgeStartTrigSrc(obj.TaskHandle,blanks(1000),uint32(1000));
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
   
       
        function scanClock = getScanClockConfiguration(obj)
            [status,terminal] = daq.ni.NIDAQmx.DAQmxGetSampClkTerm(obj.TaskHandle,blanks(1000),uint32(1000));
            if status==daq.ni.NIDAQmx.DAQmxErrorCannotGetPropertyWhenTaskNotReservedCommittedOrRunnin ||...
                    status == daq.ni.NIDAQmx.DAQmxErrorAttributeNotSupportedInTaskContext
                %Related to G635856.  The workaround prevents the commit of
                %simulated devices.  This means that the exact terminal is
                %not selected on CompactDAQ devices, and
                %DAQmxGetSampClkTerm.  Use DAQmxGetSampClkSrc instead and
                %change <Device>/?/SampleClockTimebase to
                %<Device>/ai/SampleClock
                [status,terminal] = daq.ni.NIDAQmx.DAQmxGetSampClkSrc(obj.TaskHandle,blanks(1000),uint32(1000));
                posQuestion = strfind(terminal,'/?/SampleClockTimebase');
                if ~isempty(posQuestion)
                    terminal = [terminal(1:posQuestion-1) '/di/SampleClock'];
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
    end
    
    %% Friend methods
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
                % G673218: Session cannot startForeground if the task is
                % already running.
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
            calculateBlockSize();
            obj.doConfigureReferenceClock();
            configureScanClock();
            configureBlockSize();
            
            function calculateBlockSize()
                [obj.BufferingBlockSize, obj.NumScansConfigured] = obj.Session.getInputBufferBlockSize();
            end
            
            function configureBlockSize()
                [status] = daq.ni.NIDAQmx.DAQmxCfgInputBuffer(...
                    obj.TaskHandle,... % taskHandle,
                    uint32(obj.NumScansConfigured));
                daq.ni.utility.throwOrWarnOnStatus(status);
            end
            
            function configureScanClock()
                % Configure the clocking
                if obj.Session.IsContinuous
                    sampleMode = daq.ni.NIDAQmx.DAQmx_Val_ContSamps;
                else
                    sampleMode = daq.ni.NIDAQmx.DAQmx_Val_FiniteSamps;
                end

                clockSource = daq.SyncManager.Default;

                if ~strcmp(obj.SyncInfo.ScanClock,daq.SyncManager.Default)
                      clockSource = obj.SyncInfo.ScanClock;
                end

                if strcmp(clockSource,daq.SyncManager.Default)
                    obj.localizedError('daq:channel:DIOExternalClock',...
                        obj.Session.Channels(obj.ChannelIndexMap(1)).getChannelDescriptionHook(),...
                        obj.Session.getChannelIDs(obj.ChannelIndexMap(1)))
                end

                [status] = daq.ni.NIDAQmx.DAQmxCfgSampClkTiming(...
                    obj.TaskHandle,...                   % taskHandle,
                    clockSource,...                      % source
                    obj.Session.Rate,...                 % rate
                    daq.ni.NIDAQmx.DAQmx_Val_Rising,...  % activeEdge
                    sampleMode,...                       % sampleMode
                    obj.NumScansConfigured);
                daq.ni.utility.throwOrWarnOnStatus(status);
            end
        end
    end
    
    %% Superclass methods this class implements
    methods (Hidden)
        function updateChannelMap(obj)
            updateChannelMapBase(obj,daq.internal.SubsystemType.DigitalIO);
        end
    end
end
