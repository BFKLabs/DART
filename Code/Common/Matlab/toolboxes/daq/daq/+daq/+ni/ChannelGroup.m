classdef (Hidden) ChannelGroup < daq.internal.BaseClass
    %ChannelGroup Represents the activities associated with a group of channels
    % Channel groups describe related channels that belong together
    % in a task.  They are self-organizing, with names generally of
    % the form <subsystem>/<deviceid>, but related devices may
    % choose another mechanism.  For instance, CompactDAQ uses
    % <subsystem>/<chassisID>.
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    %% -- Constructor --
    methods
        function obj = ChannelGroup(session,name,deviceID)
            obj.createInternalStateMap();
            obj.Session = session;
            obj.Name = name;
            obj.DeviceID = deviceID;
            obj.changeState('NoTask')
            obj.NumScansConfigured = 0;
            obj.SyncInfo = daq.ni.SyncInfo();
        end
    end
    
    % Methods requiring implementation by a subclass
    methods (Access = public)
        %openStream Open and AsyncIO channel
        function openStream(obj, taskHandle, numberOfScans, bufferingBlockSize, numChannels, isContinuous) %#ok<INUSD>
            error(message('daq:general:methodNotImplemented', 'openStream'));
        end
        
        %flushStream flush and AsyncIO channel
        function flushStream(obj) %#ok<MANU>
            error(message('daq:general:methodNotImplemented', 'flushStream'));
        end
        
        %closeStream Close an AsyncIO channel
        function closeStream(obj) %#ok<MANU>
            error(message('daq:general:methodNotImplemented', 'closeStream'));
        end
        
        %startTask Send start command to device plugin
        function startTask(obj) %#ok<MANU>
            error(message('daq:general:methodNotImplemented', 'startTask'));
        end
        
        %configureTrigger Configure channel groups task handle for trigger
        function configureTriggers(obj)
            % Set the start trigger for the channel group to the terminal
            % specified by the syncInfo.
            if ~any(strcmp({daq.SyncManager.Default, daq.SyncManager.ExternalDevice}, ....
                    obj.SyncInfo.StartTrigger))
                % G921524: myDAQ devices cannot route the StartTrigger to
                % other subsystems. Therefore, Edge-Triggers aren't allowed
                % (or any other trigger). Trying to configure a Digital
                % Edge Start Trigger for these devices results in an error.                
                try           
                    [status] = daq.ni.NIDAQmx.DAQmxCfgDigEdgeStartTrig(...
                        obj.TaskHandle,...                              % taskHandle,
                        obj.SyncInfo.StartTrigger,...                   % triggerSource
                        daq.ni.utility.DAQToNI((obj.SyncInfo.StartTriggerCondition))); % triggerEdge
                    daq.ni.utility.throwOrWarnOnStatus(status);
                catch e
                    switch e.identifier
                        case {'nidaq:ni:err200077'}
                          % Ignore this error for now.
                        otherwise
                            rethrow(e);
                    end
                end
                       
                            
            end
        end
        
        %configureExportedSignals Configure channel group task handle for
        %exported signals
        function configureExportedSignals(obj)
            
            % Export scan clock being used by the channel group to the
            % terminal specified by syncInfo.
            if ~any(strcmp({daq.SyncManager.Default, daq.SyncManager.ExternalDevice}, ....
                    obj.SyncInfo.ExportedScanClock))
                [status] = daq.ni.NIDAQmx.DAQmxExportSignal(...
                    obj.TaskHandle,...                          % taskHandle,
                    daq.ni.NIDAQmx.DAQmx_Val_SampleClock  ,...  % signalID
                    obj.SyncInfo.ExportedScanClock);            % outputTerminal[]);
                daq.ni.utility.throwOrWarnOnStatus(status);
            end
            
            % Export start trigger used by the channel group to the
            % terminal specified by syncInfo.
            if ~any(strcmp({daq.SyncManager.Default, daq.SyncManager.ExternalDevice}, ....
                    obj.SyncInfo.ExportedStartTrigger))
                [status] = daq.ni.NIDAQmx.DAQmxExportSignal(...
                    obj.TaskHandle,...                           % taskHandle,
                    daq.ni.NIDAQmx.DAQmx_Val_StartTrigger ,...   % signalID
                    obj.SyncInfo.ExportedStartTrigger);          % outputTerminal[]);
                daq.ni.utility.throwOrWarnOnStatus(status);
            end
        end
        
        function doConfigureReferenceClock(obj)
            
            if daq.internal.getOptions().DisableReferenceClockSynchronization
                return;
            end
            
            if obj.isReferenceClockSyncCapable()
                
                % NI requires the fully qualified clock name
                referenceClock = ['/' obj.getDeviceIDForSync() '/PXI_CLK10'];
                
                % Set the reference clock source to the 10MHz clock
                % available on the PXI chassis backplane
                [status, ~] = daq.ni.NIDAQmx.DAQmxSetRefClkSrc(...
                    obj.TaskHandle,...
                    referenceClock);
                % Some DSA devices like PXI-447x series does not support
                % reference clock synchronization. Do not error out if
                % property not supported by task.
                if status ~= daq.ni.NIDAQmx.DAQmxErrorAttributeNotSupportedInTaskContext
                    daq.ni.utility.throwOrWarnOnStatus(status);
                end
                
                % Set the reference clock rate to 10MHz
                [status] = daq.ni.NIDAQmx.DAQmxSetRefClkRate(...
                    obj.TaskHandle,...
                    10e6);
                % Some DSA devices like PXI-447x series does not support
                % reference clock synchronization. Do not error out if
                % property not supported by task.
                if status ~= daq.ni.NIDAQmx.DAQmxErrorAttributeNotSupportedInTaskContext
                    daq.ni.utility.throwOrWarnOnStatus(status);
                end
                
            end
        end
        
        function result = isReferenceClockSyncCapable(obj)
            
            % E, S and AO series devices do not support reference clock
            % synchronization
            devices = [obj.Session.Channels.Device];
            
            % Do not set reference clock for simulated devices.
            if any([devices.IsSimulated])
                result = false;
                return;
            end
            
            [status,productCategory] = ...
                daq.ni.NIDAQmx.DAQmxGetDevProductCategory(obj.DeviceID,int32(0));
            if status ~= 0 || ...
                    productCategory == daq.ni.NIDAQmx.DAQmx_Val_ESeriesDAQ || ...
                    productCategory == daq.ni.NIDAQmx.DAQmx_Val_SSeriesDAQ || ...
                    productCategory == daq.ni.NIDAQmx.DAQmx_Val_AOSeries
                result = false;
                return;
            end
            % Reference Clock Synchronization is only supported on PXI
            % chassis.
            result = isa(devices(strcmp({devices.ID},obj.DeviceID)),'daq.ni.PXIModule');
        end
        
        %Retrieve the start trigger terminal that was actually selected
        function startTrigger = getStartTriggerConfiguration(obj)
            startTrigger = obj.SyncInfo.StartTrigger;
        end
        
        %Retrieve the scan clock terminal that was actually selected
        function scanClock = getScanClockConfiguration(obj)
            scanClock = obj.SyncInfo.ScanClock;
        end
        
        %Get the deviceID that will be used for setting reference clocks,
        %trigger and sample clock. Normally this is available through the
        %'DeviceID' property of the channel group. However, when auto
        %synchronizing using PXI or PCI DSA modules,the deviceID reflects
        %the type of chassis and chassis number in case of PXI and
        %identified RTSI bus number in case of PCI. In that case, we can
        %use the first device in the auto sync task for all synchronization
        %purpose.
        function deviceIDForSync = getDeviceIDForSync(obj)
            if obj.Session.AutoSyncDSA
                deviceIDForSync =  obj.Session.Channels(obj.ChannelIOIndexMap(1)).Device.ID;
            else
                deviceIDForSync = obj.DeviceID;
            end
        end
    end
    
    %% Read only properties
    properties (SetAccess = private)
        % Commit status
        %!!! IsCommitted = true;
        
        % Task group name
        Name
        
        % Device name
        DeviceID
        
        % Task groups are a tag that describes related channels that
        % belong together in a task.  They are self-organizing,
        % generally of the form <subsystem>/<deviceid>, but related
        % devices may choose another mechanism.  For instance,
        % CompactDAQ uses <subsystem>/<chassisID>.
        
        % Maps input channels in the channel group based to their order on
        % the session object, and output channels in a channel group based
        % on their order in a session object.
        ChannelIOIndexMap
        
        % Maps channels to their index on the session object
        ChannelIndexMap
        
        % Channel maps are logical arrays that map the channels from
        % session on to the channels for the task.  For instance, if a
        % task with 3 channels in part of a session with 5 channels, and
        % the task represents channels 2, 4, and 5, the channel map will be
        % [0 1 0 1 1]
        
        % Count of the channels in this group
        NumberOfChannels
        
        % All information needed for synchronization ( clocking and
        % triggering ) of a channel group.
        SyncInfo
        
    end
    
    %% Sealed methods
    methods(Sealed)
        function [taskHandle] = getUnreservedTaskHandle(obj)
            % getUnreservedTaskHandle() get a task handle guaranteed to be
            % unreserved
            
            % Remember, this could be an array of objects
            taskHandle = zeros(1,numel(obj),'uint64');
            for iObj = 1:numel(obj)
                taskHandle(iObj) = obj(iObj).InternalState.getUnreservedTaskHandle();
            end
        end
        
        function [taskHandle] = getCommittedTaskHandle(obj)
            % getCommittedTaskHandle() get a task handle guaranteed to be
            % committed, though it may be configured for single or multiple
            % scans.
            
            % Remember, this could be an array of objects
            taskHandle = zeros(1,numel(obj),'uint64');
            for iObj = 1:numel(obj)
                taskHandle(iObj) = obj(iObj).InternalState.getCommittedTaskHandle();
            end
        end
        
        function configureForMultipleScans(obj)
            % Remember, this could be an array of objects
            for iObj = 1:numel(obj)
                obj(iObj).InternalState.configureForMultipleScans();
            end
        end
        
        function updateNumberOfScans(obj)
            % Remember, this could be an array of objects
            for iObj = 1:numel(obj)
                obj(iObj).InternalState.updateNumberOfScans();
            end
        end
        
        function configureForSingleScan(obj)
            % Remember, this could be an array of objects
            for iObj = 1:numel(obj)
                obj(iObj).InternalState.configureForSingleScan();
            end
        end
        
        function configureForNextStart(obj)
            % Remember, this could be an array of objects
            for iObj = 1:numel(obj)
                obj(iObj).InternalState.configureForNextStart();
            end
        end
        
        function setup(obj)
            % start() Start the AsyncIO operation
            
            % Remember, this could be an array of objects
            for iObj = 1:numel(obj)
                obj(iObj).InternalState.setup();
            end
        end
        
        function start(obj)
            % start() Start the AsyncIO operation
            
            % Remember, this could be an array of objects
            for iObj = 1:numel(obj)
                obj(iObj).InternalState.start();
            end
        end
        
        function stop(obj)
            % stop() Stop the AsyncIO operation in progress
            
            % Remember, this could be an array of objects
            for iObj = 1:numel(obj)
                obj(iObj).InternalState.stop();
            end
        end
        
        function unreserve(obj)
            % unreserve() Unreserve the hardware
            
            % Remember, this could be an array of objects
            for iObj = 1:numel(obj)
                obj(iObj).InternalState.unreserve();
            end
        end
        
        function clearTask(obj)
            % clearTask() Clear the task.
            
            % Remember, this could be an array of objects
            for iObj = 1:numel(obj)
                obj(iObj).InternalState.clearTask();
            end
        end
        
        function result = anyCommittedForSingleScan(obj)
            result = false;
            for iObj = 1:numel(obj)
                if isa(obj(iObj).InternalState,'daq.ni.ChannelGroupStateCommittedForSingleScan')
                    result = true;
                    return
                end
            end
        end
        
        function resetConfigurationFlag(obj)
            for iObj = 1:numel(obj)
                obj(iObj).IsConfigured = false;
            end
        end
        
        function [result] = isRunning(obj)
            % Remember, this could be an array of objects
            result = false;
            for iObj = 1:numel(obj)
                result = obj(iObj).InternalState.getIsRunning();
                if result
                    break;
                end
            end
        end
        
    end
    
    %% Destructor
    methods
        function delete(obj)
            % Remember, this could be an array of objects
            for iObj = 1:numel(obj)
                try
                    obj(iObj).doClearTask();
                    delete(obj(iObj));
                catch %#ok<CTCH>
                    % If this fails, there's nothing we can do, so ignore it
                    % !!! When we have global access to FullDebug flag, throw.
                end
            end
        end
    end
    
    % Property accessor methods
    methods
        function [result] = get.NumberOfChannels(obj)
            result = numel(obj.ChannelIOIndexMap);
        end
        function [result] = get.ChannelIOIndexMap(obj)
            result = obj.ChannelIOIndexMap;
        end
        function [result] = get.ChannelIndexMap(obj)
            result = obj.ChannelIndexMap;
        end
    end
    
    %% Hidden methods, which are typically used as friend methods
    methods(Hidden)
        function doCreateTask(obj)
            [status,newTaskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            % Walk the session channels and create any channels that are
            % part of this channel group
            for iChannel = 1:numel(obj.Session.Channels)
                if strcmp(obj.Session.Channels(iChannel).GroupName,obj.Name)
                    subsystemType = obj.Session.Channels(iChannel).SubsystemType;
                    obj.Session.Channels(iChannel).configureTask(newTaskHandle);
                    obj.updateChannelMapBase(subsystemType);
                end
            end
            
            obj.TaskHandle = newTaskHandle;
        end
        
        function taskHandle = doGetTaskHandle(obj)
            taskHandle = obj.TaskHandle;
        end
        
        function doUnreserve(obj)
            % doUnreserve() Unreserve the hardware
            status = daq.ni.NIDAQmx.DAQmxTaskControl(...
                obj.TaskHandle,...
                daq.ni.NIDAQmx.DAQmx_Val_Task_Unreserve);
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
        
        function doClearTask(obj)
            obj.resetChannelCount();
            try
                obj.closeStream();
            catch e
                [~] = daq.ni.NIDAQmx.DAQmxClearTask(obj.TaskHandle);
                rethrow(e)
            end
            % Clear the task
            [status] = daq.ni.NIDAQmx.DAQmxClearTask(obj.TaskHandle);
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
        
        function doFlush(obj)
            obj.flushStream();
        end
        
        function doSetup(obj)
            if obj.Session.IsContinuous
                numberOfScans = uint64(0);
            else
                numberOfScans = obj.NumScansConfigured;
            end
            
            obj.openStream(obj.TaskHandle,...
                numberOfScans,...
                obj.BufferingBlockSize,...
                obj.NumberOfChannels,...
                obj.Session.IsContinuous,...
                obj.Session.ExternalTriggerTimeout)
        end
        
        function doStart(obj)
            obj.startTask();
        end
        
        function doStop(obj)
            obj.closeStream();
        end
        
        function doConfigureScanClock(obj)
            % Default way to set the sample clock for a device. Channel
            % groups can override
            [status] = daq.ni.NIDAQmx.DAQmxSetSampClkRate(...
                obj.TaskHandle,...
                obj.Session.Rate);
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
        
        function resetChannelCount(obj)
            obj.ChannelIndexMap = [];
            obj.ChannelIOIndexMap = [];
        end
        
        function handleStop(obj, error)
            obj.Session.handleStop(error);
        end
        
        % Set the private property SyncInfo for channel groups
        function configureSyncInfo(obj,syncInfo)
            obj.SyncInfo = syncInfo;
        end
        
    end
    
    % Hidden public sealed methods, which are typically used as friend methods
    methods (Sealed, Hidden)
        function changeState(obj,targetState)
            % changeState switch session to the target state
            % Intended only for use internally, or by State* classes
            try
                if daq.internal.getOptions().StateDebug
                    disp(['Channel Group (' obj.Name ') :' targetState]);
                end
                % Pull the target state out of the map
                for iChannelGroup=1:length(obj)
                    obj(iChannelGroup).InternalState = ...
                        obj(iChannelGroup).InternalStateMap(targetState);
                end
            catch e
                if strcmp(e.identifier,'MATLAB:Containers:Map:NoKey')
                    obj.localizedError('nidaq:ni:badState',targetState)
                else
                    rethrow(e)
                end
            end
        end
        
        function locatedGroup = locate(obj,type)
            % locate ChannelGroups of the type specified
            % Get logical array of items matching the criteria
            matches = ~cellfun(@isempty,strfind({obj.Name},[type '/']));
            
            % Select the matching ChannelGroup
            locatedGroup = obj(matches);
        end
        
        % Give channels a chance to react to task recreation
        function onTaskRecreation(obj)
            % Loop over all the channels in the group.
            for i = 1:numel(obj.ChannelIndexMap)
                obj.Session.Channels(obj.ChannelIndexMap(i)).onTaskRecreationHook(obj.TaskHandle);
            end
        end
    end
    
    % Protected properties for use by a subclass
    properties(SetAccess=protected)
        % The buffering block size for AsyncIO
        BufferingBlockSize
        
        % The number of scans configured for sample clock timing. This is
        % the raw number of scans to be acquired or generated by the device
        % after padding to ensure that we always acquire or generate a
        % multiple of the buffering block size
        NumScansConfigured
    end
    
    % Protected read only properties for use by a subclass
    properties(GetAccess=protected,SetAccess=private)
        % This is the real task handle, that the public TaskHandle property
        % relies on.  This allows internal operation to avoid the expense
        % of creating a task, only to do something like release().
        TaskHandle = [];
        
        % Handle to the session object, used to dispatch AsyncIO events.
        Session
        
        % Contains the current state of the ChannelGroup object
        InternalState
    end
    
    % Protected methods requiring implementation by a subclass
    % These would be abstract, but we want daq.ni.ChannelGroup.empty() to
    % work. Hidden because we want to be able to use it by friend classes.
    methods (Hidden)
        function updateChannelMap(obj) %#ok<MANU>
        end
    end
    
    % Protected methods for use by a subclass
    methods (Sealed, Access = protected)
        function configureTriggerAndIgnoreErrorIfNeeded(obj)
            % G878226: Most counter (M and X Series) and some digital (M Series)
            % subsystems do not support external triggers, but if slaved
            % off of an analog AI or AO clock (i.e. auto sync), the trigger
            % is implicit in the parent subsystem clock and hence the trigger not supported
            % error can be ignored.
           
            % Case 1: No connections, automatic synchronization -
            % means clock is shared by different subsystems,
            % trigger errors can be ignored
            if isempty(obj.Session.Connections)
                return;
            end
            
            % Case 2: Connections with external destination,
            % trigger errors can be ignored
            if all(strcmp(obj.Session.SyncManager.getDestinationDevices(),'External'))
                return;
            end
            
            deviceID = obj.Session.Channels(obj.ChannelIndexMap(1)).Device.ID;
            deviceModel = obj.Session.Channels(obj.ChannelIndexMap(1)).Device.Model;
            subsystemType = obj.Session.Channels(obj.ChannelIndexMap(1)).SubsystemType;
             
            % Case 3: If the deviceID is not one of the destination devices
            if ~any(strcmp(obj.Session.SyncManager.getDestinationDevices(),deviceID))
                return;
            end
            
            % Is it a trigger connection 
            [ ~ ,index ] = obj.Session.SyncManager.getConnectionsForDeviceAsDestination(deviceID);
            if any(isa(obj.Session.Connections(index),'daq.ni.StartTriggerConnection'))
                showError = true;
            else
                showError = false;
            end
            
            try
                obj.configureTriggers()
            catch e
                if strcmp(e.identifier, 'nidaq:ni:err200452')
                    if showError
                        obj.localizedError('nidaq:ni:triggersNotSupported',...
                            deviceModel,...
                            deviceID,...
                            char(subsystemType));
                    else
                        obj.localizedWarning('nidaq:ni:triggersNotSupported',...
                            deviceModel,...
                            deviceID,...
                            char(subsystemType));
                    end
                else
                    rethrow(e);
                end                
            end
        end
            
            function updateChannelMapBase(obj,subsystemType)
                channelIndexMap = [];
                channelIOIndexMap = [];
                inputChannelIndex = 0;
                outputChannelIndex = 0;
                
                for iChannel = 1:numel(obj.Session.Channels)
                    isAI = isa(obj.Session.Channels(iChannel),'daq.AnalogInputChannel');
                    isCI = isa(obj.Session.Channels(iChannel),'daq.CounterInputChannel');
                    isDI = isa(obj.Session.Channels(iChannel),'daq.DigitalChannel') &&...
                        (strcmp(obj.Session.Channels(iChannel).Direction, 'Input')||...
                        strcmp(obj.Session.Channels(iChannel).Direction, 'Unknown'));
                    
                    isAO = isa(obj.Session.Channels(iChannel),'daq.AnalogOutputChannel');
                    isCO = isa(obj.Session.Channels(iChannel),'daq.CounterOutputChannel');
                    isDO = isa(obj.Session.Channels(iChannel),'daq.DigitalChannel') &&...
                        strcmp(obj.Session.Channels(iChannel).Direction, 'Output');
                    
                    % Input channels
                    if isAI || isCI || isDI
                        inputChannelIndex = inputChannelIndex + 1;
                    end
                    
                    % Output channels
                    %
                    % Note: Counter output channels do not support
                    % outputSingleScan and queueOutputData
                    if isAO || isDO
                        outputChannelIndex = outputChannelIndex + 1;
                    end
                    
                    groupName = obj.Session.Channels(iChannel).GroupName;
                    
                    % Map input channels belonging to this channel group and subsystem type
                    if strcmp(obj.Name,groupName)
                        if (isAI && subsystemType == daq.internal.SubsystemType.AnalogInput) ||...
                                (isCI && subsystemType == daq.internal.SubsystemType.CounterInput) ||...
                                (isDI && subsystemType == daq.internal.SubsystemType.DigitalIO)
                            channelIndexMap(end + 1) = iChannel; %#ok<AGROW>
                            channelIOIndexMap(end + 1) = inputChannelIndex; %#ok<AGROW>
                        end
                        
                        % Map output channels belonging to this channel group and subsystem type
                        if (isAO && subsystemType == daq.internal.SubsystemType.AnalogOutput) ||...
                                (isDO && subsystemType == daq.internal.SubsystemType.DigitalIO)
                            channelIndexMap(end + 1) = iChannel; %#ok<AGROW>
                            channelIOIndexMap(end + 1) = outputChannelIndex; %#ok<AGROW>
                        end
                        
                        % Note: Counter output channels are not supported by
                        % outputSingleScan and queueOutputData. Filter those
                        % channels from channelIOIndexMap.
                        if isCO && subsystemType == daq.internal.SubsystemType.CounterOutput
                            channelIndexMap(end + 1) = iChannel; %#ok<AGROW>
                            channelIOIndexMap(end + 1) = NaN; %#ok<AGROW>
                        end
                    end
                end
                
                obj.ChannelIndexMap = channelIndexMap;
                obj.ChannelIOIndexMap = channelIOIndexMap;
            end
            
            
            function commitTask(obj)
                % commitTask() Reserve the hardware and configure it.
                
                % G635856: BSOD if task containing simulated devices is
                % explicitly committed (NI CAR#242484). If any devices are
                % simulated, then don't commit.
                devices = [obj.Session.Channels.Device];
                if any([devices.IsSimulated])
                    return
                end
                
                % G685776: Workaround for BSOD with X-Series devices, pending
                % NIDAQmx driver update (CAR# 287556)
                if obj.Session.checkNoCommitDevices()
                    return;
                end
                
                status = daq.ni.NIDAQmx.DAQmxTaskControl(...
                    obj.TaskHandle,...
                    daq.ni.NIDAQmx.DAQmx_Val_Task_Commit);
                
                % G635929 Reserved hardware is not an error. It is an
                % indication that the hardware is being used either in another
                % session in this MATLAB or in an external program.
                if status == daq.ni.NIDAQmx.DAQmxErrorPALResourceReserved || ...
                        status == daq.ni.NIDAQmx.DAQmxErrorResourceAlreadyReserved || ...
                        status == daq.ni.NIDAQmx.DAQmxErrorDigLinesReservedOrUnavailable
                    obj.localizedError('nidaq:ni:DAQmxResourceReserved');
                end
                
                % Wrap the error message about incorrect routing. It basically implies that
                % the terminal used in a particular connection is not available for routing and
                % thus can not be used.
                if status == daq.ni.NIDAQmx.DAQmxErrorRouteNotSupportedByHW_Routing
                    obj.localizedError('nidaq:ni:NIDAQmxError89136')
                end
                daq.ni.utility.throwOrWarnOnStatus(status);
            end
            
            function stopTask(obj)
                if ~isempty(obj.TaskHandle)
                    status = daq.ni.NIDAQmx.DAQmxStopTask(obj.TaskHandle);
                    daq.ni.utility.throwOrWarnOnStatus(status);
                end
            end
        
        function checkClockConfigurationStatus(obj, status)
            % G1009174: Check if clock configuration failed because we're using simulated devices
            if (status == daq.ni.NIDAQmx.DAQmxErrorCannotGetPropertyWhenTaskNotReservedCommittedOrRunnin)
                [status, isSimulated] = daq.ni.NIDAQmx.DAQmxGetDevIsSimulated(obj.DeviceID, uint32(0));
                if status==daq.ni.NIDAQmx.DAQmxSuccess && isSimulated
                    devices = blanks(1000);
                    [status, devices] = daq.ni.NIDAQmx.DAQmxGetDevChassisModuleDevNames(obj.DeviceID, devices, uint32(numel(devices)));
                    if status==daq.ni.NIDAQmx.DAQmxSuccess && numel(devices) > 0
                        obj.Session.localizedError('nidaq:ni:notSupportedUsingSimulatedChassis', devices, obj.DeviceID);
                    else
                        obj.Session.localizedError('nidaq:ni:notSupportedUsingSimulatedDevice', obj.DeviceID);
                    end
                end
            end
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
        end
        
        % Protected properties
        properties (GetAccess = protected,SetAccess = protected)
            % A map of all the possible states of the ChannelGroup
            InternalStateMap
        end
        
        % Internal constants
        properties(Constant, GetAccess = private)
        end
        
        % Superclass methods this class implements
        methods (Access = protected)
            function resetImpl(obj)
                %resetImpl Handle daq.reset (which is usually delete)
                if isvalid(obj)
                    delete(obj)
                end
            end
        end
        
        % Private methods
        methods (Access = private)
            function createInternalStateMap(obj)
                % Create the internal state map
                obj.InternalStateMap = containers.Map();
                addState('NoTask')
                addState('Unreserved')
                addState('CommittedForMultipleScans')
                addState('CommittedForSingleScan')
                addState('Running')
                addState('Complete')
                
                function addState(stateName)
                    % Dynamically generate the names of the classes to
                    % instantiate from the class name
                    obj.InternalStateMap(stateName) =...
                        feval(str2func(['daq.ni.ChannelGroupState' stateName]),obj);
                end
            end
        end
        
        % Private properties
        properties (SetAccess = protected,GetAccess = protected)
            % True if this channel group has been configured (so it's not
            % configured twice
            IsConfigured = false;
        end
    end
