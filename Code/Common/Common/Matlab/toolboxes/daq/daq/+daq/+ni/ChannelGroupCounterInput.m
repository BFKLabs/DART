classdef (Hidden) ChannelGroupCounterInput < daq.ni.ChannelGroup
    %ChannelGroupCounterInput Represents a group of counter input channels
    %sharing a NIDAQmx task
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    %% private properties
    properties(Access = private)
        AsyncIOChannel;
        IsSingleScanTiming;
    end
    
    %% constructor/destructor
    methods
        function obj = ChannelGroupCounterInput(session,name)
            % Get the device name from the group name
            idx = strfind(name,'/');
            deviceID = name(idx(1)+1:idx(2)-1);
            obj@daq.ni.ChannelGroup(session,name,deviceID);

            obj.IsSingleScanTiming = false;
            obj.AsyncIOChannel = daq.ni.AsyncIOInputChannel(session, obj, 'mwnidaqmxci');
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
    
    %% Friend methods
    methods(Hidden)
        function doConfigureForSingleScan(obj)
            try
                if obj.IsSingleScanTiming == false
                    obj.clearTask();
                    obj.doCreateTask();
                    obj.commitTask();
                    obj.updateChannelMap();
                    [status] = daq.ni.NIDAQmx.DAQmxStartTask(obj.TaskHandle);
                    daq.ni.utility.throwOrWarnOnStatus(status);
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
            
            function calculateBlockSize()
                [obj.BufferingBlockSize, obj.NumScansConfigured] = obj.Session.getInputBufferBlockSize();
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
                    % Timers cannot be internally clocked
                    isUsingChassis = any(arrayfun(@(x)isa(x,'daq.ni.CompactDAQModule'),[obj.Session.Channels.Device]));
                    if isUsingChassis
                        obj.localizedError('daq:channel:sharedSourceClockChassis',...
                            obj.Session.Channels(obj.ChannelIndexMap(1)).getChannelDescriptionHook(),...
                            obj.Session.getChannelIDs(obj.ChannelIndexMap(1)),...
                            obj.Session.Channels(obj.ChannelIndexMap(1)).Device.Model,...
                            obj.Session.Channels(obj.ChannelIndexMap(1)).Device.ChassisName);
                    else
                        obj.localizedError('daq:channel:sharedSourceClock',...
                            obj.Session.Channels(obj.ChannelIndexMap(1)).getChannelDescriptionHook(),...
                            obj.Session.getChannelIDs(obj.ChannelIndexMap(1)),...
                            obj.Session.Channels(obj.ChannelIndexMap(1)).Device.Model,...
                            obj.Session.Channels(obj.ChannelIndexMap(1)).Device.ID);
                    end
                end

                [status] = daq.ni.NIDAQmx.DAQmxCfgSampClkTiming(...
                    obj.TaskHandle,...                   % taskHandle,
                    clockSource,...                      % source
                    obj.Session.Rate,...                 % rate
                    daq.ni.NIDAQmx.DAQmx_Val_Rising,... % activeEdge
                    sampleMode,...                       % sampleMode
                    obj.NumScansConfigured);
                daq.ni.utility.throwOrWarnOnStatus(status);
            end
        end
    end
    
    %% Superclass methods this class implements
    methods (Hidden)
        function updateChannelMap(obj)
            updateChannelMapBase(obj,daq.internal.SubsystemType.CounterInput);
        end
    end
end
