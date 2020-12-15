classdef (Hidden) ChannelGroupAnalogInput < daq.ni.ChannelGroup
    %ChannelGroupAnalogInput Represents a group of analog input channels
    %sharing a NIDAQmx task
    
    % Copyright 2010-2013 The MathWorks, Inc.
    
    %% private properties
    properties(Access = private)
        AsyncIOChannel;
        IsSingleScanTiming;
    end
    
    %% constructor/destructor
    methods
        function obj = ChannelGroupAnalogInput(session,name)
            % Get the device name from the group name
            deviceID = sscanf(name,'ai/%s');
            obj@daq.ni.ChannelGroup(session,name,deviceID);

            obj.IsSingleScanTiming = false;
            obj.AsyncIOChannel = daq.ni.AsyncIOInputChannel(session, obj, 'mwnidaqmxai');
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
        % Retrieve the start trigger terminal that was actually selected
        function startTrigger = getStartTriggerConfiguration(obj)
            
            [status,type] = daq.ni.NIDAQmx.DAQmxGetStartTrigType(obj.TaskHandle,int32(0));
            daq.ni.utility.throwOrWarnOnStatus(status);
            if type == daq.ni.NIDAQmx.DAQmx_Val_None
                [status,startTrigger] = daq.ni.NIDAQmx.DAQmxGetStartTrigTerm(obj.TaskHandle,blanks(1000),uint32(1000));
                if status == daq.ni.NIDAQmx.DAQmxErrorCannotGetPropertyWhenTaskNotReservedCommittedOrRunnin ||...
                        status == daq.ni.NIDAQmx.DAQmxErrorAttributeNotSupportedInTaskContext
                    %Related to G635856.  The workaround prevents the commit of
                    %simulated devices.  This means that the exact terminal is not
                    %selected on CompactDAQ devices.  Use a reasonable
                    %default
                    startTrigger = [ '/',obj.getDeviceIDForSync(),'/ai/StartTrigger'];
                    status = daq.ni.NIDAQmx.DAQmxSuccess;
                end
                daq.ni.utility.throwOrWarnOnStatus(status);
                return
            end
            
            [status,startTrigger] = daq.ni.NIDAQmx.DAQmxGetDigEdgeStartTrigSrc(obj.TaskHandle,blanks(1000),uint32(1000));
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
        
        % Retrieve the scan clock terminal that was actually selected
        function [scanClock] = getScanClockConfiguration(obj)
            % Internal -- return what was actually selected
            [status, terminal] = daq.ni.NIDAQmx.DAQmxGetSampClkTerm(obj.TaskHandle,blanks(1000),uint32(1000));
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
                      terminal = [terminal(1:posQuestion-1) '/ai/SampleClock'];
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
                obj.stopTask();
                obj.doUpdateNumberOfScans();
                obj.configureTriggers();
                obj.configureExportedSignals();
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
            obj.doConfigureScanClock();
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
        end
        
        function doConfigureScanClock(obj)
            
            % Configure the clocking
            if obj.Session.IsContinuous
                sampleMode = daq.ni.NIDAQmx.DAQmx_Val_ContSamps;
            else
                sampleMode = daq.ni.NIDAQmx.DAQmx_Val_FiniteSamps;
            end
            
            clockSource = 'OnboardClock';
            if ~strcmp(obj.SyncInfo.ScanClock,daq.SyncManager.Default)
                clockSource = obj.SyncInfo.ScanClock;
            end
            
            if obj.NumScansConfigured == 0
                % When NumScansConfigured is zero, we can use any value for
                % numOfScans to get a valid rate. Choosing 1000 as it
                % matches with session defaults.
                numOfScans = uint64(1000);
            else
                numOfScans = obj.NumScansConfigured;
            end
            
            [status] = daq.ni.NIDAQmx.DAQmxCfgSampClkTiming(...
                obj.TaskHandle,...                   % taskHandle,
                clockSource,...                      % source
                obj.Session.Rate,...                 % rate
                daq.ni.NIDAQmx.DAQmx_Val_Rising,...  % activeEdge
                sampleMode,...                       % sampleMode
                numOfScans);
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
    end
    
    %% Superclass methods this class implements
    methods (Hidden)
        function updateChannelMap(obj)
            updateChannelMapBase(obj,daq.internal.SubsystemType.AnalogInput);
        end
    end
end
