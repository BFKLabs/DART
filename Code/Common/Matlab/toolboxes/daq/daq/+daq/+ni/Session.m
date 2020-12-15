classdef (Hidden) Session < daq.Session
    %daq.ni.Session Session object for National Instruments DAQ
    %    National Instruments DAQ devices are accessed using this session.
    %    It contains all the vendor specific code to access the hardware
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties (SetObservable )
        % This property indicates if an attempt will be made to auto
        % synchronize DSA PCI and PXI devices
        AutoSyncDSA
    end
    
    % Read only properties
    properties (SetAccess = private)
    end
    
    % Read only properties that can be altered by a subclass
    properties (SetAccess = protected)
    end
    
    % Constants
    properties(Constant, GetAccess = private)
    end
    
    % Methods
    methods
    end
    
    % Sealed methods
    methods(Sealed)
    end
    
    % Events
    events
    end
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods(Hidden)
        function obj = Session(vendor)
            % Assume an initial rate of 1000 scans/second
            obj@daq.Session(vendor,1000);
            
            obj.InitializationInProgress = true;
            
            obj.ChannelGroup = containers.Map('KeyType','char','ValueType','any');
            obj.TriggerReceived = false;
            obj.TriggerTime = [];
            obj.AutoSyncDSA = false;
            
            obj.InitializationInProgress = false;
        end
    end
    
    % Destructor
    methods(Hidden)
        function delete(obj)
            % G771952: Destroy channel groups associated with the Session
            obj.getAllChannelGroups().stop();
            delete(obj.getAllChannelGroups());
        end
    end
    
    % Property accessor methods
    methods
        function set.AutoSyncDSA(obj,newValue)
            try
                if obj.InitializationInProgress %#ok<MCSUP>
                    % Initialization -- just do it
                    obj.AutoSyncDSA = newValue;
                    return
                end
                
                obj.errorIfParameterChangeNotOK()
                
                if isempty(newValue) || ~isscalar(newValue) ||...
                        ~(daq.internal.isNumericNum(newValue) || islogical(newValue)) || ...
                        ((newValue ~= 0) && (newValue ~=1))
                    obj.localizedError('nidaq:ni:AutoSyncDSAMustBeLogical');
                end
                
                if logical(newValue) == obj.AutoSyncDSA
                    % if the value isn't being changed, then abort
                    return
                end
                
                obj.AutoSyncDSA = newValue;
                obj.sessionPropertyBeingChangedHook('AutoSyncDSA',newValue);
                obj.resetCountersImpl();
            catch e
                obj.AutoSyncDSA = ~newValue;
                if ~strcmp(e.identifier,'daq:Session:noChangeWhileRunning')
                    obj.recreateAllChannelGroups();
                end
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
    
    % Hidden properties
    properties(Hidden)
    end
    
    % Hidden read only properties
    properties(Hidden,SetAccess = private)
        % Input data available merge buffer
        DataAvailableBuffer;
        
        % TriggerTime of first trigger in a multi trigger acquisition
        InitialTriggerTime;
        
        % Total number of scans acquired - used to compute time stamps
        % information
        TotalScansAcquired;
    end
    
    % Hidden methods, which are typically used as friend methods
    methods(Hidden)
        function [taskHandle] = getUnreservedTaskHandle(obj,channelGroupName)
            % getUnreservedTaskHandle return a uncommitted TaskHandle
            % [TASKHANDLE] = getUnreservedTaskHandle(CHANNELGROUPNAME) returns the
            % TASKHANDLE of the channel group CHANNELGROUPNAME.
            %
            % If the channel group does not exist, it will be created.
            %
            % Channel groups describe related channels that belong together
            % in a task.  They are self-organizing, with names generally of
            % the form <subsystem>/<deviceid>, but related devices may
            % choose another mechanism.  For instance, CompactDAQ uses
            % <subsystem>/<chassisID>.
            
            taskHandle = obj.getChannelGroup(channelGroupName).getUnreservedTaskHandle();
        end
        
        function [taskHandle] = getCommittedTaskHandle(obj,channelGroupName)
            % getCommittedTaskHandle return a committed TaskHandle
            % [TASKHANDLE] = getCommittedTaskHandle(CHANNELGROUPNAME) returns the
            % TASKHANDLE of the channel group CHANNELGROUPNAME.
            %
            % Channel groups describe related channels that belong together
            % in a task.  They are self-organizing, with names generally of
            % the form <subsystem>/<deviceid>, but related devices may
            % choose another mechanism.  For instance, CompactDAQ uses
            % <subsystem>/<chassisID>.
            
            taskHandle = obj.getChannelGroup(channelGroupName).getCommittedTaskHandle();
        end
        
        function configureForSingleScan(obj, channelGroupName)
            obj.getChannelGroup(channelGroupName).configureForSingleScan();
        end
        
        function handleDataAvailable(obj,data,channels,numberOfScansConfigured)
            
            % TriggerTime is set when the first time we enter this.
            if isempty(obj.TriggerTime)
                obj.TriggerTime = now;
            end
            
            % TriggerReceived is set the first time there is data available.
            if ~obj.TriggerReceived
                obj.TriggerReceived = true;
                obj.processHardwareTrigger();
            end
            
            for iChannel = 1:numel(channels)
                obj.DataAvailableBuffer{channels(iChannel)} = ...
                    [obj.DataAvailableBuffer{channels(iChannel)}; data(:,iChannel)];
            end
            
            numInputChannels = obj.Channels.countInputChannels();
            
            % For multichannel acquisitions, minSize represents the
            % minimum amount of data available across all channels
            minSize = numel(obj.DataAvailableBuffer{1});
            for iChannel = 2:numInputChannels
                minSize = min(minSize, numel(obj.DataAvailableBuffer{iChannel}));
            end
            
            blockSize = double(obj.NotifyWhenDataAvailableExceeds);
            
            % G667622/G676518: Check if number of scans is reached with
            % a remaining partial block of data. For the last block we
            % may need to notify a partial block size
            if minSize + obj.ScansAcquired >= obj.NumberOfScans
                notifySize = minSize; % last notification (may be a partial block)
            else
                notifySize = blockSize;
            end
            
            while minSize >= notifySize
                dataBlock = zeros(notifySize, numInputChannels);
                for iChannel = 1:numInputChannels
                    dataBlock(:, iChannel) = ...
                        obj.DataAvailableBuffer{iChannel}(1:notifySize);
                    obj.DataAvailableBuffer{iChannel} = ...
                        obj.DataAvailableBuffer{iChannel}(notifySize + 1:end);
                end
                
                period = 1/obj.Rate;
                if isempty(obj.InitialTriggerTime)
                    obj.InitialTriggerTime = obj.TriggerTime;
                end
                
                % triggerTimeDelta is the time elapsed from initial trigger
                triggerTimeDelta = etime(datevec(obj.TriggerTime), datevec(obj.InitialTriggerTime));
                
                % triggerNumber is zero based, representing additional
                % triggers beyond first trigger
                triggerNumber = floor(obj.TotalScansAcquired/numberOfScansConfigured);
                
                % If the acquisition is continuous, force triggerNumber to
                % zero.
                if obj.IsContinuous
                    triggerNumber = 0;
                end
                
                scansFromPreviousTriggers = triggerNumber * numberOfScansConfigured;
                startTime = (obj.TotalScansAcquired - scansFromPreviousTriggers)* period + triggerTimeDelta;
                endTime = startTime + (notifySize - 1) * period;
                timestamps = (startTime:period:endTime)';
                
                obj.processAcquiredData(obj.TriggerTime,timestamps,dataBlock);
                obj.TotalScansAcquired = obj.TotalScansAcquired + notifySize;
                minSize = minSize - notifySize;
            end
        end
        
        function handleOutputEvent(obj,scansOutput)
            % TriggerReceived is set the first time there is data is
            % generated.
            if (scansOutput > 0) && (~obj.TriggerReceived)
                obj.TriggerReceived = true;
                obj.processHardwareTrigger();
            end
            
            if scansOutput > obj.ScansOutputByHardware
                obj.processOutputEvent(scansOutput);
            end
        end
        
        function error = processNIDAQmxDriverError(obj, channels, messageID, driverMessage)
            % Allow reporting errors across multiple channels in a channel
            % group
            
            % Property updates that result in driver calls happening during
            % the creation of the session object result in calls to this
            % method with an empty channel.
            
            if isempty(channels) || any(isnan(channels))
                error = MException(messageID, driverMessage);
                return;
            end
            
            channelIDs = obj.getChannelIDs(channels);
            
            % Translate NIDAQmx driver errors to DAQ errors
            switch(messageID)
                case {'nidaq:ni:NIDAQmxError201087', 'nidaq:ni:err201087'}
                    error = MException('nidaq:ni:NIDAQmxError201087', ...
                        obj.getLocalizedText('nidaq:ni:NIDAQmxError201087', ...
                        obj.Channels(channels(1)).getChannelDescriptionHook(),...
                        channelIDs,...
                        obj.Channels(channels(1)).Device.Model,...
                        obj.Channels(channels(1)).Device.ID));
                case {'nidaq:ni:NIDAQmxError200300', 'nidaq:ni:err200300','nidaq:ni:NIDAQmxError200251','nidaq:ni:err200251'}
                    error = MException('nidaq:ni:NIDAQmxError200300', ...
                        obj.getLocalizedText('nidaq:ni:NIDAQmxError200300', ...
                        obj.Channels(channels(1)).getChannelDescriptionHook(),...
                        channelIDs,...
                        obj.Channels(channels(1)).Device.Model,...
                        obj.Channels(channels(1)).Device.ID));
                case {'nidaq:ni:NIDAQmxError201314', 'nidaq:ni:err201314'}
                    % Customize error message by measurement type
                    if strcmp(obj.Channels(channels(1)).MeasurementType, 'PulseWidth')
                        error = MException('nidaq:ni:NIDAQmxError201314_PW', ...
                            obj.getLocalizedText('nidaq:ni:NIDAQmxError201314_PW', ...
                            obj.Channels(channels(1)).getChannelDescriptionHook(),...
                            channelIDs,...
                            obj.Channels(channels(1)).Device.Model,...
                            obj.Channels(channels(1)).Device.ID));
                    else
                        error = MException('nidaq:ni:NIDAQmxError201314_Freq', ...
                            obj.getLocalizedText('nidaq:ni:NIDAQmxError201314_Freq', ...
                            obj.Channels(channels(1)).getChannelDescriptionHook(),...
                            channelIDs,...
                            obj.Channels(channels(1)).Device.Model,...
                            obj.Channels(channels(1)).Device.ID));
                    end
                case {'nidaq:ni:NIDAQmxError200141','nidaq:ni:err200141'}
                    error = MException('nidaq:ni:NIDAQmxError200141', ...
                        obj.getLocalizedText('nidaq:ni:NIDAQmxError200141', ...
                        obj.Channels(channels(1)).getChannelDescriptionHook(),...
                        channelIDs,...
                        obj.Channels(channels(1)).Device.Model,...
                        obj.Channels(channels(1)).Device.ID));
                case {'nidaq:ni:NIDAQmxError200018','nidaq:ni:err200018'}
                    error = MException('nidaq:ni:NIDAQmxError200018', ...
                        obj.getLocalizedText('nidaq:ni:NIDAQmxError200018', ...
                        obj.Channels(channels(1)).Device.Model,...
                        obj.Channels(channels(1)).Device.ID));
                otherwise
                    if isa(messageID,'char')
                        error = MException(messageID, driverMessage);
                    else
                        error = MException('nidaq:ni:NIDAQmxStatusCode',...
                            obj.getLocalizedText('nidaq:ni:NIDAQmxStatusCode', messageID, driverMessage));
                    end
            end
        end
        
        function handleStop(obj,error)
            % g878084: If all channel groups are already stopped, do
            % nothing.
            if obj.NumberOfChannelGroupsRunning == 0
                return;
            end
            
            if ~isempty(error)
                % If there's an error, then immediately stop
                obj.NumberOfChannelGroupsRunning = 0;
            else
                % Otherwise continue running until all channel groups have
                % stopped
                obj.NumberOfChannelGroupsRunning = obj.NumberOfChannelGroupsRunning - 1;
            end
            if obj.NumberOfChannelGroupsRunning == 0
                % Stop all channel sessions
                obj.getAllChannelGroups().stop();
                
                try
                    if ~obj.checkNoCommitDevices()
                        obj.getAllChannelGroups().configureForNextStart();
                    end
                catch e
                    % Mask out 'nidaq:ni:badCommandInThisState' in the case
                    % of a premature stop
                    if isempty(error) ||...
                            ~strcmp(e.identifier, 'nidaq:ni:badCommandInThisState')
                        rethrow(e);
                    end
                end
                
                obj.processHardwareStop(error);
                % All input channels are now done, call processAcquiredData
                % to get out of state 'AcquiredDataWaiting'
                numAIChannels = obj.Channels.countInputChannels();
                if numAIChannels > 0
                    obj.processAcquiredData(now,[],zeros(0,numAIChannels));
                end
                
                % release after session has stopped completely
                if obj.checkNoCommitDevices() && (obj.TriggersRemaining == 0)
                    obj.release();
                end
               
                % Reset triggerTime for the next run.
                obj.TriggerTime = [];
                
                obj.TriggerReceived = false;
            end
        end
        
        % G685776: Workaround for BSOD with X-Series devices, pending
        % NIDAQmx driver update (CAR# 287556)
        function [doNotCommit] = checkNoCommitDevices(obj)
            doNotCommit = false;
            
            deviceIDs = {};
            for i = 1:numel(obj.Channels)
                deviceIDs{i} = obj.Channels(i).Device.ID; %#ok<AGROW>
                % g770020 Do not commit PXI modules
                if isa(obj.Channels(i).Device,'daq.ni.PXIModule');
                    doNotCommit = true;
                    return;
                end
            end
            deviceIDs = unique(deviceIDs);
            
            for i = 1:numel(deviceIDs)
                [status,productCategory] = ...
                    daq.ni.NIDAQmx.DAQmxGetDevProductCategory(deviceIDs{i},int32(0));
                if status ~= 0 || ...
                        productCategory == daq.ni.NIDAQmx.DAQmx_Val_XSeriesDAQ || ...
                        productCategory == daq.ni.NIDAQmx.DAQmx_Val_NetworkDAQ || ...
                        productCategory == daq.ni.NIDAQmx.DAQmx_Val_NIELVIS
                    doNotCommit = true;
                    break;
                end
            end
        end
        
        function updateRateLimit(obj)
            % updateRateLimit Adjust the RateLimit to reflect changes in
            % configuration.  Needs to be available to channels in case
            % property updates will effect the rate limit.
            
            % If there are no channels, set obj.RateLimitInfo to empty
            if isempty(obj.Channels)
                obj.RateLimitInfo = daq.internal.ParameterLimit.empty;
                return
            end
            
            % Assume that the maximum rate is the maximum possible for real
            % values.
            
            newMaxRate = realmax;
            maxRateForTask = realmax;
            
            % Check if the channels have a device specialization which gives
            % the supported rates. If yes, then limit the max rate to the
            % maximum for the channel. See geck 741810 for details.
            for indexChannel = 1:numel(obj.Channels)
                rateLimitFromDS = obj.Channels(indexChannel).Device.getRateLimitFromDataSheet(obj.Channels(indexChannel).MeasurementType);
                if ~isempty(rateLimitFromDS)
                    maxFromDS = max(rateLimitFromDS);
                    newMaxRate = min(maxFromDS,newMaxRate);
                end
            end

            % Then loop through all the channel groups reducing to the 
            % lowest maximum rate for all groups.
            
            channelGroups = obj.getAllChannelGroups();  
            
            for iChannelGroups = 1:numel(channelGroups)
                status = 0;
                taskHandle = channelGroups(iChannelGroups).getUnreservedTaskHandle();
                
                channelGroupClass = class(channelGroups(iChannelGroups));
                
                switch (channelGroupClass)
                    case 'daq.ni.ChannelGroupCounterInput'
                        
                        channelIndexMap = channelGroups(iChannelGroups).ChannelIndexMap;
                        for iChannel = 1:numel(channelIndexMap)
                            
                            channel = channelIndexMap(iChannel);
                            deviceID = obj.Channels(channel).Device.ID;
                            channelID = obj.Channels(channel).ID;
                            
                            sampClkSupported = uint32(0);
                            [~, sampClkSupported] = daq.ni.NIDAQmx.DAQmxGetDevCISampClkSupported(...
                                [deviceID '/' channelID], sampClkSupported);
                            if ~sampClkSupported
                                newMaxRate = 0;
                                break;
                            end
                            
                            % g719530, g857306: Check if the device is
                            % E-Series. E-series has one DMA controller and 
                            % does not allow us to perform clocked
                            % counter operations. Throw the error before we ask user
                            % to add an analog channel to provide clock.
                            [status, productCategory] = daq.ni.NIDAQmx.DAQmxGetDevProductCategory(...
                                deviceID, int32(0));
                            daq.ni.utility.throwOrWarnOnStatus(status);
                            
                            if( productCategory == daq.ni.NIDAQmx.DAQmx_Val_ESeriesDAQ )
                                newMaxRate = 0;
                                break;
                            end
                            
                            [status, maxRateForTask] = daq.ni.NIDAQmx.DAQmxGetDevCIMaxTimebase(...
                                deviceID, double(0));
                            
                            % Check if it only supports on-demand operations
                            if status == daq.ni.NIDAQmx.DAQmxErrorAttrNotSupported
                                newMaxRate = 0;
                                status = 0;
                            end
                            
                            newMaxRate = min(newMaxRate, maxRateForTask);
                        end
                        
                    case 'daq.ni.ChannelGroupCounterOutput'
                        
                        channelIndexMap = channelGroups(iChannelGroups).ChannelIndexMap;
                        
                        for iChannel = 1:numel(channelIndexMap)
                            
                            channel = channelIndexMap(iChannel);
                            deviceID = obj.Channels(channel).Device.ID;
   
                            [status, maxRateForTask] = daq.ni.NIDAQmx.DAQmxGetDevCOMaxTimebase(...
                                deviceID, double(0));
                            daq.ni.utility.throwOrWarnOnStatus(status);
                            newMaxRate = min(newMaxRate, maxRateForTask);
                        end
                        
                    case 'daq.ni.ChannelGroupDigitalInput'
                        
                        channelIndexMap = channelGroups(iChannelGroups).ChannelIndexMap;
                        
                        for iChannel = 1:numel(channelIndexMap)
                            
                            channel = channelIndexMap(iChannel);
                            deviceID = obj.Channels(channel).Device.ID;
                            channelID = obj.Channels(channel).ID;                            
                            
                            if obj.Channels(channel).IsGroup
                                newMaxRate = 0;
                                break;
                            end
                            
                            sampClkSupported = uint32(0);
                            [~, sampClkSupported] = daq.ni.NIDAQmx.DAQmxGetPhysicalChanDISampClkSupported(...
                                [deviceID '/' channelID], sampClkSupported);
                            if ~sampClkSupported
                                newMaxRate = 0;
                                break;
                            end
                        end
                        
                        channel = channelIndexMap(1);
                        [status, maxRateForTask] = daq.ni.NIDAQmx.DAQmxGetDevDIMaxRate(...
                            deviceID, double(0));
                        
                        if status == 0
                            newMaxRate = min(newMaxRate, maxRateForTask);
                        else
                            newMaxRate = 0;
                            status = 0;
                        end
                        
                    case 'daq.ni.ChannelGroupDigitalOutput'
                        
                        channelIndexMap = channelGroups(iChannelGroups).ChannelIndexMap;
                        
                        for iChannel = 1:numel(channelIndexMap)
                                                        
                            channel = channelIndexMap(iChannel);
                            deviceID = obj.Channels(channel).Device.ID;
                            channelID = obj.Channels(channel).ID;
                            
                            if obj.Channels(channel).GroupChannelCount > 1
                                newMaxRate = 0;
                                break;
                            end
                            
                            sampClkSupported = uint32(0);
                            [~,sampClkSupported] = daq.ni.NIDAQmx.DAQmxGetPhysicalChanDOSampClkSupported(...
                                [deviceID '/' channelID], sampClkSupported);
                            if ~sampClkSupported
                                newMaxRate = 0;
                                break;
                            end
                        end
                        
                        channel = channelIndexMap(1);
                        [status, maxRateForTask] = daq.ni.NIDAQmx.DAQmxGetDevDOMaxRate(...
                            deviceID, double(0));
                        
                        if status == 0
                            newMaxRate = min(newMaxRate, maxRateForTask);
                        else
                            status = 0;
                            newMaxRate = 0;
                        end

                    case 'daq.ni.ChannelGroupAnalogInput'
                        
                        % For every device, we have one ChannelGroup and
                        % for every ChannelGroup, we have one device (1:1)
                        channelIndexMap = channelGroups(iChannelGroups).ChannelIndexMap;
                        numberOfChannels = numel(channelIndexMap);
                        
                        currentChannelIndex = channelIndexMap(numberOfChannels);
                        
                        device = obj.Channels(currentChannelIndex).Device;
                        deviceID = device.ID;
                        
                        aiSubsystemIndex = strmatch('AnalogInput',...
                            {device.Subsystems.SubsystemType});
                        
                        isSimultaneous = strmatch('Simultaneous',...
                            device.Subsystems(aiSubsystemIndex).SampleType);
                        
                        if isSimultaneous
                            channelCount = 1;
                        else
                            channelCount = numberOfChannels;
                        end
                        
                        [status, maxSingleRate] = ...
                            daq.ni.NIDAQmx.DAQmxGetDevAIMaxSingleChanRate(...
                                deviceID, double(0));

                        [status, maxMultiRate] = ...
                            daq.ni.NIDAQmx.DAQmxGetDevAIMaxMultiChanRate(...
                                deviceID, double(0));
                            
                            
                        maxMultiRate = maxMultiRate/channelCount;
                        maxRateForTask = min(maxSingleRate, maxMultiRate);
                            
%                         if channelCount == 1
%                             maxRateForTask = maxSingleRate;
%                         else
%                             [status, maxMultiRate] = ...
%                                 daq.ni.NIDAQmx.DAQmxGetDevAIMaxMultiChanRate(...
%                                 deviceID, double(0));
%                             
%                             maxMultiRate = maxMultiRate/channelCount;
%                             
%                             maxRateForTask = min(maxSingleRate, maxMultiRate);
%                         end
                     
                    case 'daq.ni.ChannelGroupAnalogOutput' 

                        [status, maxRateForTask] = daq.ni.NIDAQmx.DAQmxGetSampClkMaxRate(...
                            taskHandle, double(0));
                        
                        switch (status)
                            % G687868: Check whether the task only supports on-demand
                            % operations
                            case daq.ni.NIDAQmx.DAQmxErrorAttributeNotSupportedInTaskContext
                                
                                status = 0;
                                maxRateForTask = 0;
                                
                            % 642569 Some devices require that the sample rate be set
                            % before other operations. This will be indicated by the
                            % status of the attempt to get the Max Rate above.
                            case daq.ni.NIDAQmx.DAQmxErrorSampClkRateMustBeSpecd

                                minRate = obj.Channels(1).Device.Subsystems.RateLimit(1);
                                [status] = daq.ni.NIDAQmx.DAQmxSetSampClkRate(...
                                    taskHandle, minRate); 
                                daq.ni.utility.throwOrWarnOnStatus(status);
                                
                                
                                [status, maxRateForTask] = daq.ni.NIDAQmx.DAQmxGetSampClkMaxRate(...
                                    taskHandle, double(0));
                                % Check status outside if block

                            % G698695: In some scenarios, this property is unreadable
                            % (e.g. Adding an NI-9201 AI voltage channel followed by an
                            % NI-9234 accelerometer channel.                                
                            case daq.ni.NIDAQmx.DAQmxErrorInvalidAttributeValue
                                
                                status = daq.ni.NIDAQmx.DAQmxSetSampTimingType(...
                                    taskHandle, daq.ni.NIDAQmx.DAQmx_Val_SampClk);
                                daq.ni.utility.throwOrWarnOnStatus(status);
                                
                                [status, maxRateForTask] = daq.ni.NIDAQmx.DAQmxGetSampClkMaxRate(...
                                    taskHandle, double(0));
                        end
                end
                
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                newMaxRate = min(newMaxRate, maxRateForTask);
                
                % If we've achieved the minimum possible rate, don't
                % continue to check
                if newMaxRate == 0
                    break;
                end
            end
            
            subsystems = obj.Channels.getSubsystem();
            ratelimits = [subsystems.RateLimitInfo];
            % Find the largest minimum
            newMin = max([ratelimits.Min]);
            newMin = min(newMin, newMaxRate);
            
            % Find the smallest maximum
            oldMax = min([ratelimits.Max]);
            newMaxRate = min(oldMax, newMaxRate);
            
            obj.RateLimitInfo = daq.internal.ParameterLimit(newMin,newMaxRate);
        end
        
        function channelIDs = getChannelIDs(obj, channels)
            channelIDs = obj.Channels(channels(1)).ID;
            for iChannel = 2 : numel(channels)
                strcat(channelIDs, ', ', obj.Channels(channels(iChannel)).ID);
            end
        end
        
        function checkIsValidChannelID(obj, deviceInfo, id, subsystem)
   
            % G722712: Check for invalid channel names
            % G1029606: Allow channel if it is a "hidden" ID that starts 
            % with underscore, such as used by the CJC on thermocouples, or 
            % the vernier device.             
            if ~ismember(id, deviceInfo.getSubsystem(subsystem).ChannelNames) && ~isequal(id(1),'_')
                obj.throwUnknownChannelIDError(...
                    deviceInfo,...
                    num2str(id),...
                    deviceInfo.getSubsystem(subsystem).ChannelNames)
            end
        end
        
        function [outputBufferSize, blockSize, numberOfScans] = getBufferBlockSize(obj)
            persistent prevSetup;
            
            if isempty(prevSetup)
                prevSetup.BlockSize = 0;
                prevSetup.NumberOfScans = 0;
                prevSetup.OutputBufferSize = 0;
                
                prevSetup.SessionRate = 0;
                prevSetup.SessionNumberOfScans = 0;
                prevSetup.SessionIsContinuous = 0;
                prevSetup.SessionNotifyWhenDataAvailableExceeds = 0;
                prevSetup.SessionIsNotifyWhenDataAvailableExceedsAuto = 0;
                prevSetup.SessionNotifyWhenScansQueuedBelow = 0;
                prevSetup.SessionIsNotifyWhenScansQueuedBelowAuto = 0;
            end
            
            if obj.Rate == prevSetup.SessionRate &&...
                    obj.NumberOfScans == prevSetup.SessionNumberOfScans &&...
                    obj.IsContinuous == prevSetup.SessionIsContinuous &&...
                    obj.NotifyWhenDataAvailableExceeds == prevSetup.SessionNotifyWhenDataAvailableExceeds &&...
                    obj.IsNotifyWhenDataAvailableExceedsAuto == prevSetup.SessionIsNotifyWhenDataAvailableExceedsAuto &&...
                    obj.NotifyWhenScansQueuedBelow == prevSetup.SessionNotifyWhenScansQueuedBelow &&...
                    obj.IsNotifyWhenScansQueuedBelowAuto == prevSetup.SessionIsNotifyWhenScansQueuedBelowAuto
                
                % Used cached values
                blockSize = prevSetup.BlockSize;
                numberOfScans = prevSetup.NumberOfScans;
                outputBufferSize = prevSetup.OutputBufferSize;
            else
                % Recalculate buffer block sizes
                %
                
                % Unaligned output buffer size and number of scans
                outputBufferSize = calculateNIDAQContinuousBufferSize(obj.Rate);
                if obj.IsContinuous
                    numberOfScans = outputBufferSize;
                else
                    numberOfScans = obj.NumberOfScans;
                end
                
                % Determine limits
                min_bs = max(floor(obj.Rate / obj.WarnIfEventsPerSecondExceeds), 2);
                max_bs = ceil(obj.Rate / (obj.WarnIfEventsPerSecondExceeds / 10));
                
                % Make end points even
                min_bs = min_bs + mod(min_bs, 2);
                max_bs = max_bs + mod(max_bs, 2);
                
                % We cannot have separate block sizes because we
                % synchronize both devices to the same clock and require
                % the least common multiple of both buffer sizes to match a
                % changing target number of scans. The buffer size must be
                % independent of number of scans, since the number of scans
                % can change between runs if the user queues different
                % amounts of data to the session object.
                blockSize = min_bs;
                if obj.IsNotifyWhenDataAvailableExceedsAuto && ~obj.IsNotifyWhenScansQueuedBelowAuto
                    threshold = obj.NotifyWhenScansQueuedBelow;
                    threshold = threshold + mod(threshold, 2);
                    for bs = [min_bs:2:min(max_bs, threshold/2), min(max_bs, threshold)]
                        if mod(threshold, bs)==0
                            blockSize = bs;
                            break;
                        end
                    end
                elseif ~obj.IsNotifyWhenDataAvailableExceedsAuto && obj.IsNotifyWhenScansQueuedBelowAuto
                    threshold = obj.NotifyWhenDataAvailableExceeds;
                    threshold = threshold + mod(threshold, 2);
                    for bs = [min_bs:2:min(max_bs, threshold/2), min(max_bs, threshold)]
                        if mod(threshold, bs)==0
                            blockSize = bs;
                            break;
                        end
                    end
                elseif ~obj.IsNotifyWhenDataAvailableExceedsAuto && ~obj.IsNotifyWhenScansQueuedBelowAuto
                    threshold1 = obj.NotifyWhenScansQueuedBelow;
                    threshold2 = obj.NotifyWhenDataAvailableExceeds;
                    for bs = [min_bs:2:min(max_bs, min(threshold1/2, threshold2/2)), min(max_bs, min(threshold1, threshold2))]
                        if mod(threshold1, bs)==0 && mod(threshold2, bs)==0
                            blockSize = bs;
                            break;
                        end
                    end
                end
                
                numberOfScans = ceil(double(numberOfScans)/double(blockSize))*double(blockSize);
                outputBufferSize = ceil(calculateNIDAQContinuousBufferSize(obj.Rate)/double(blockSize))*double(blockSize);
                
                blockSize = uint64(blockSize);
                numberOfScans = uint64(numberOfScans);
                outputBufferSize = uint64(outputBufferSize);
                
                prevSetup.BlockSize = blockSize;
                prevSetup.NumberOfScans = numberOfScans;
                prevSetup.OutputBufferSize = outputBufferSize;
                
                prevSetup.SessionRate = obj.Rate;
                prevSetup.SessionNumberOfScans = obj.NumberOfScans;
                prevSetup.SessionIsContinuous = obj.IsContinuous;
                prevSetup.SessionNotifyWhenDataAvailableExceeds = obj.NotifyWhenDataAvailableExceeds;
                prevSetup.SessionIsNotifyWhenDataAvailableExceedsAuto = obj.IsNotifyWhenDataAvailableExceedsAuto;
                prevSetup.SessionNotifyWhenScansQueuedBelow = obj.NotifyWhenScansQueuedBelow;
                prevSetup.SessionIsNotifyWhenScansQueuedBelowAuto = obj.IsNotifyWhenScansQueuedBelowAuto;
            end
            
            function result = calculateNIDAQContinuousBufferSize(rate)
                % calculateNIDAQContinuousBufferSize Calculate buffer size
                % calculateNIDAQContinuousBufferSize() returns the correct
                % buffer size to use based on the NI-DAQmx documentation
                % "How Is Buffer Size Determined?"
                if rate < 100
                    result = double(1000);
                elseif rate < 10000
                    result = double(10000);
                elseif rate < 1000000
                    result = double(100000);
                else
                    result = double(1000000);
                end
            end
        end
        
        function [inputBlockSize, numberOfScans] = getInputBufferBlockSize(obj)
            [~, inputBlockSize, numberOfScans] = obj.getBufferBlockSize();
        end
        
        function [outputBufferSize, outputBlockSize, numberOfScans] = getOutputBufferBlockSize(obj)
            [outputBufferSize, outputBlockSize, numberOfScans] = obj.getBufferBlockSize();
        end
        
        function taskHandle = recreateTaskHandle(obj,channelGroupName)
            removeChannelGroup(obj,channelGroupName);
            taskHandle = getUnreservedTaskHandle(obj,channelGroupName);
        end
        
        function recreateAllChannelGroups(obj)
            % Clear all channel groups
            allChannelGroups = obj.getAllChannelGroups();
            for i = 1:numel(allChannelGroups)
                groupName = allChannelGroups(i).Name;
                obj.removeChannelGroup(groupName);
            end
            
            % Walk the session channels and create any channels that are
            % part of this channel group
            for iChannel = 1:numel(obj.Channels)
                groupName = obj.Channels(iChannel).GroupName;
                if ~obj.ChannelGroup.isKey(groupName)
                    obj.recreateTaskHandle(groupName);
                end
            end
            
            % Give the channels groups a chance to react to task
            % recreation.
            allChannelGroups = obj.getAllChannelGroups();
            for i = 1:numel(allChannelGroups)
                allChannelGroups(i).onTaskRecreation();
            end
            
        end
        
        function handleAutoSyncDSAErrors(obj,e)
 
            % Use a hotlink if available
            link  = obj.getLinkIfAvailable('nidaq:ni:DSASyncDocumentationLink');
            
            switch e.identifier
                case 'nidaq:ni:err201114'
                    % DAQmxErrorDSAExpansionMixedBoardsWrongOrderInPXIChassis
                    obj.localizedError('nidaq:ni:heteroDSAsync',link);
                case 'nidaq:ni:err200852'
                    %DAQmxErrorSyncNoDevSampClkTimebaseOrSyncPulseInPXISlot2
                    obj.localizedError('nidaq:ni:homoDSAsync',link);
                case 'nidaq:ni:err201206'
                    obj.localizedError('nidaq:ni:autoSyncSimulated',link)
                case 'nidaq:ni:err201425'
                    obj.localizedError('nidaq:ni:cannotAutoSync',link)
                case 'nidaq:ni:err089120'
                    obj.localizedError('nidaq:ni:NIDAQmxError089120WhenEnablingAutoSyncDSA',link)
                otherwise
                    throwAsCaller(e);
            end
        end
    end
    
    % Hidden public sealed methods, which are typically used as friend methods
    methods (Sealed, Hidden)
    end
    
    % Hidden static methods, which are typically used as friend methods
    methods(Hidden,Static)
    end
    
    % Protected read only properties for use by a subclass
    properties(GetAccess=protected,SetAccess=private)
    end
    
    % Protected constants for use by a subclass
    properties(GetAccess=protected,Constant)
    end
    
    % Protected methods requiring implementation by a subclass
    methods (Abstract,Access = protected)
    end
    
    % Protected template methods with optional implementation by a subclass
    methods (Access = protected)
    end
    
    % Protected methods for use by a subclass
    methods (Sealed, Access = protected)
    end
    
    % Protected static methods for use by a subclass
    methods (Sealed,Static,Access=protected)
    end
    
    % Private properties
    properties (GetAccess = private,SetAccess = private)
        % Channel groups describe related channels that belong together
        % in a task.  They are self-organizing, with names generally of
        % the form <subsystem>/<deviceid>, but related devices may
        % choose another mechanism.  For instance, CompactDAQ uses
        % <subsystem>/<chassisID>.
        
        % A Map of all the channel groups that have been created
        ChannelGroup
        
        % The number of channel groups still running
        NumberOfChannelGroupsRunning
        
        % A bool indicating if trigger has been received.
        TriggerReceived
        
        % The initial trigger time captured from first call to
        % handleProcessAcquiredData
        TriggerTime;
    end
    
    % Internal constants
    properties(Constant, GetAccess = private)
        % Default timeout when reading or writing a single scan to NI-DAQmx
        DefaultNIDAQmxTimeout = double(1);
        
        % The maximum acceptable rate variation among tasks in the session
        MaximumRateVariationPercentage = 1;
    end
    
    % Superclass methods this class implements
    methods (Sealed, Access = protected)
        % createChannelImpl is implemented by the vendor to validate that
        % the requested channel can be created, and to create and return an object of
        % type daq.Channel conforming to the parameters passed. All
        % parameters will be pre-validated and will always be passed in
        % (other than the varargins)
        function newChannel = createChannelImpl(obj,...
                subsystem,...       % A daq.internal.SubsystemType defining the type of the subsystem to create a channel for on the device
                isGroup,...         % A flag indicating if multiple channels should be grouped together
                deviceInfo,...      % A daq.DeviceInfo object of the device that the channel exists on
                channelID,...       % A cell array of strings or numeric vector containing the IDs of the channels to create
                measurementType,... % A string containing the specialized measurement to be used, such as 'Voltage'.
                varargin)           % Any additional parameters passed by the user, to be interpreted by the vendor implementation
            
            newChannel = daq.Channel.empty();
            
            if (nargin > 6)
                obj.localizedError('MATLAB:maxrhs');
            end
            
            % Find any registered RTSI cables and add them to the device
            % info for individual devices.
            daq.ni.PCIDSADevice.findAndAddRegsiteredRTSIcables();
            
            if isa(deviceInfo,'daq.ni.PCIDSADevice') && obj.AutoSyncDSA
                deviceInfo.verifyIfDeviceCanBeAddedInAutoSyncDSA(obj);
            end
            
            % For some devices, NI errors out when startForeground
            % is called between channel additions. So recreating
            % the taskHandle before adding new channels.
            allChannelGroups = obj.getAllChannelGroups();
            
            for i = 1:numel(allChannelGroups)
                if allChannelGroups(i).NumberOfChannels ~= 0
                    obj.recreateTaskHandle(allChannelGroups(i).Name);
                end
            end
            
            % Validate channels
            for iChannel = 1:numel(channelID)
                id = channelID{iChannel};
                for chanIdx = 1:numel(obj.Channels)
                    % Session channel might be a digital group
                    if isa(obj.Channels(chanIdx), 'daq.DigitalChannel')
                        % Iterate through all channels in the
                        % digital group
                        if iscell(obj.Channels(chanIdx).GroupChannelIDs)
                            groupChannelIDs = obj.Channels(chanIdx).GroupChannelIDs;
                        else
                            groupChannelIDs = {obj.Channels(chanIdx).GroupChannelIDs};
                        end
                        for groupIdx = 1:numel(groupChannelIDs)
                            if strcmp(groupChannelIDs(groupIdx), id) &&...
                                    strcmp(obj.Channels(chanIdx).Device.ID, deviceInfo.ID)
                                obj.localizedError('nidaq:ni:sameChannelTwice',num2str(id))
                            end
                        end
                    else
                        if strcmp(obj.Channels(chanIdx).ID, id) &&...
                                strcmp(obj.Channels(chanIdx).Device.ID, deviceInfo.ID)
                            obj.localizedError('nidaq:ni:sameChannelTwice',num2str(id))
                        end
                    end
                end
            end
            
            try
                if ~isGroup
                    for iChannel = 1:numel(channelID)
                        % !!! Bug: If you add a channel that cannot go at the
                        % current rate, you'll get an error
                        id = channelID{iChannel};
                        
                        % Delegate to the device channel factory method
                        newChannel(end + 1) = deviceInfo.createChannel(obj,...
                            subsystem,...               % A daq.internal.SubsystemType defining the type of the subsystem to create a channel for on the device
                            id,...                      % A string or integer containing the ID of the channel to create
                            measurementType,...         % A string containing the specialized measurement to be used, such as 'Voltage'.
                            varargin);                  %#ok<AGROW> % Any additional parameters passed by the user, to be interpreted by the vendor implementation
                    end
                    
                    if obj.AutoSyncDSA && ...
                            ~isa(deviceInfo,'daq.ni.PCIDSADevice') && ...
                            ~isa(deviceInfo,'daq.ni.PXIDSAModule')
                        obj.localizedWarning('nidaq:ni:AutoSyncDSAOnlyApplicableToDSADevices')
                    end
                else
                    % Set a channel id for the exception handler
                    id = channelID{1};
                    
                    % Delegate to the device channel factory method
                    newChannel(end + 1) = deviceInfo.createChannel(obj,...
                        subsystem,...               % A daq.internal.SubsystemType defining the type of the subsystem to create a channel for on the device
                        channelID,...               % A string or integer containing the ID of the channel to create
                        measurementType,...         % A string containing the specialized measurement to be used, such as 'Voltage'.
                        varargin);                  % Any additional parameters passed by the user, to be interpreted by the vendor implementation
                end
            catch e
                % Clear the tasks associated with successful
                % channels that were added before the error, since
                % those tasks now contain channels that will not be
                % added.
                for iChannel2 = 1:numel(newChannel)
                    obj.getChannelGroup(newChannel(iChannel2).GroupName).clearTask();
                end
                
                % g672463: Failure to create a channel may result in an empty
                % channel group. Delete any empty channel groups.
                allChannelGroups = obj.getAllChannelGroups();
                for iChannelGroup = 1:numel(allChannelGroups)
                    channelGroup = allChannelGroups(iChannelGroup);
                    if channelGroup.NumberOfChannels == 0
                        obj.removeChannelGroup(channelGroup.Name);
                    end
                end
                
                % g932100: We cannot call handleAutoSyncDSAErrors because 
                % this function masks the presence of other errors: unfold 
                % its functionality manually. Solution occurs in 3 steps.
                % 1) Check for hotlinks
                % 2) Check for DSA specific errors
                % 3) Check for originally specified errors
                
                % g932100: step 1-of-3: 
                % Use a hotlink if available (blank if not)
                link  = obj.getLinkIfAvailable('nidaq:ni:DSASyncDocumentationLink');
                
                % g932100: step 2-of-3: 
                % Check for DSA-Specific errors (from handleAutoSyncDSAErrors)
                switch e.identifier
                    case 'nidaq:ni:err201114'
                        % DAQmxErrorDSAExpansionMixedBoardsWrongOrderInPXIChassis
                        obj.localizedError('nidaq:ni:heteroDSAsync',link);
                    case 'nidaq:ni:err200852'
                        %DAQmxErrorSyncNoDevSampClkTimebaseOrSyncPulseInPXISlot2
                        obj.localizedError('nidaq:ni:homoDSAsync',link);
                    case 'nidaq:ni:err201206'
                        obj.localizedError('nidaq:ni:autoSyncSimulated',link)
                    case 'nidaq:ni:err201425'
                        obj.localizedError('nidaq:ni:cannotAutoSync',link)
                    case 'nidaq:ni:err089120'
                        obj.localizedError('nidaq:ni:NIDAQmxError089120WhenEnablingAutoSyncDSA',link)
                    otherwise
                        % Do nothing: pass on to the _next_
                        % switch-statement
                end
                
                % g932100: step 3-of-3: 
                % Check for original errors
                switch e.identifier
                    case 'nidaq:ni:err200489'
                        % Can't have same channel twice
                        obj.localizedError('nidaq:ni:sameChannelTwice',num2str(id))
                    case {'nidaq:ni:err200170','nidaq:ni:err200430'}
                        % Invalid channel ID
                        obj.throwUnknownChannelIDError(...
                            deviceInfo,...
                            num2str(id),...
                            deviceInfo.getSubsystem(subsystem).ChannelNames)
                    case 'nidaq:ni:err201003'
                        % Device can not be accessed
                        obj.localizedError('nidaq:ni:deviceCannotBeAccessed',deviceInfo.ID)
                    case 'nidaq:ni:err200432'
                        % G748316: For some devices the DeviceInfo is unable to find
                        % the correct supported measurement types. The following
                        % NIDAQmx call will fail if the channel was not created
                        % properly.
                        obj.localizedError('nidaq:ni:wrongMeasurementType',...
                            num2str(id), measurementType);
                    case 'nidaq:ni:err201250'
                        % G769959: Disconnected network device timeout
                        obj.localizedError('nidaq:ni:networkTimeoutError',...
                            deviceInfo.ID);
                    otherwise
                        rethrow(e)
                end
            end
            
            % If autoSync is high, recreate channel groups
            if obj.AutoSyncDSA
                obj.recreateAllChannelGroups();
            end
            
            % Let the task groups know they'll have to update their channel
            % counts
            for iChannel = 1:numel(newChannel)
                obj.getChannelGroup(newChannel(iChannel).GroupName).resetChannelCount();
            end
        end
        
        function newTriggerConn = createTriggerConnImpl(obj,...
                source,...
                destination,...
                type ...
                )
            %Create the StartTriggerConnection object. Since we currently
            %support only start trigger, we do not need a switch to
            %differentiate between the various types of triggers.
            newTriggerConn = daq.ni.StartTriggerConnection(obj,...
                source,...
                destination,...
                type);
        end
        
        function newClockConn = createClockConnImpl(obj,...
                source,...
                destination,...
                type ...
                )
            %Create the ScanClockConnection object. Since we currently
            %support only scan clock, we do not need a switch to
            %differentiate between the various types of clock.
            newClockConn = daq.ni.ScanClockConnection(obj,...
                source,...
                destination,...
                type);
        end
        
        % startHardwareImpl is implemented by the vendor to start the
        % hardware.
        function startHardwareImpl(obj)
            obj.TotalScansAcquired = 0;
            obj.InitialTriggerTime = [];
            obj.DataAvailableBuffer = {};
            obj.TriggerReceived = false;

            obj.startHardwareBetweenTriggersImpl();
        end
        
        % startHardwareBetweenTriggersImpl is implemented by the vendor to
        % start the hardware between multiple triggers.
        function startHardwareBetweenTriggersImpl(obj)
            
            % g680657: Check for the scenario where we're committed for
            % single scans, and force a configureForMultipleScans
            channelGroups = obj.getAllChannelGroups();
            obj.NumberOfChannelGroupsRunning = numel(channelGroups);
            
            if channelGroups.anyCommittedForSingleScan()
                channelGroups.configureForMultipleScans();
            end
            
            for iChannel = 1:obj.Channels.countInputChannels()
                obj.DataAvailableBuffer{iChannel} = [];
            end
            
            cg = obj.getAllChannelGroups('ao');
            if ~isempty(cg)
                cg.doWriteDataLastBlock();
            end
            
            cg = obj.getAllChannelGroups('do');
            if ~isempty(cg)
                cg.doWriteDataLastBlock();
            end
            
            channelGroups.setup();
            
            % The correct start order is:
            % start all Counter outputs (they run independently)
            cg = obj.getAllChannelGroups('co');
            cg.start();
            
            % start all destination Counter inputs (they are synced to the primary or local analog input or analog output subsystem)
            startDestinationDeviceSubsystem('ci');
            
            % start all secondary digital outputs (they are synced to the primary or local analog input subsystem)
            startDestinationDeviceSubsystem('do');
            
            % start all secondary digital inputs (they are synced to the primary analog input subsystem, if there is one)
            startDestinationDeviceSubsystem('di');
            
            % start all secondary analog outputs (they are synced to the primary or local analog input subsystem)
            startDestinationDeviceSubsystem('ao');
            
            % start all secondary analog inputs (they are synced to the primary analog input subsystem, if there is one)
            startDestinationDeviceSubsystem('ai');
            
            
            sourceDevice = obj.SyncManager.getSourceDevice;
            
            if ~strcmp(sourceDevice,'none')
                % start all primary counter inputs (they are synced to local analog input or analog output subsystem)
                cg = getChannelGroupsForDeviceAndSubsystem(sourceDevice,'ci');
                if ~cg.isRunning()
                    cg.start();
                end
                
                % start all primary digital outputs (they are synced to local analog input or analog output subsystem)
                cg = getChannelGroupsForDeviceAndSubsystem(sourceDevice,'do');
                if ~cg.isRunning()
                    cg.start();
                end
                
                % start all primary digital inputs (they are synced to local analog input or analog output subsystem)
                cg = getChannelGroupsForDeviceAndSubsystem(sourceDevice,'di');
                if ~cg.isRunning()
                    cg.start();
                end
                
                % start all primary analog outputs (they are synced to local analog input subsystem)
                cg = getChannelGroupsForDeviceAndSubsystem(sourceDevice,'ao');
                if ~cg.isRunning()
                    cg.start();
                end
                
                % start the primary analog input (they may be synced to an external sync)
                cg = getChannelGroupsForDeviceAndSubsystem(sourceDevice,'ai');
                if ~cg.isRunning()
                    cg.start();
                end
            end
            
            function startDestinationDeviceSubsystem(subsystem)
                destinationDevices = obj.SyncManager.getDestinationDevices;
                otherDevices = obj.SyncManager.getDevicesWithoutConnections;
                devices = [ destinationDevices otherDevices];
                for iDestinationDevices = 1:length(devices);
                    cg = getChannelGroupsForDeviceAndSubsystem(devices{iDestinationDevices},subsystem);
                    if ~cg.isRunning()
                        cg.start();
                    end
                end
            end
            
            function cg = getChannelGroupsForDeviceAndSubsystem(deviceID,subsystem)
                cg = daq.ni.ChannelGroup.empty();
                channelGroupsForThisDevice = obj.getChannelGroupsForDevice(deviceID);
                if ~isempty(channelGroupsForThisDevice)
                    cg = channelGroupsForThisDevice.locate(subsystem);
                end
            end
        end
        
        % stopImpl is implemented by the vendor to request a
        % hardware stop.  It is expected that the vendor will call
        % processHardwareStop() when the stop actually occurs.
        %
        % It is OK to call processHardwareStop() from within stopImpl, or
        % at a later time if the stop requires an asynchronous action off
        % the MATLAB thread (which it usually does)
        function stopImpl(obj)
            obj.getAllChannelGroups().stop();
            
            % Allow re-using the channels for another run after stop
            channelGroups = obj.getAllChannelGroups('ai');
            channelGroups.changeState('CommittedForMultipleScans');
            
            channelGroups = obj.getAllChannelGroups('ao');
            channelGroups.changeState('CommittedForMultipleScans');
            
            channelGroups = obj.getAllChannelGroups('di');
            channelGroups.changeState('CommittedForMultipleScans');
            
            channelGroups = obj.getAllChannelGroups('do');
            channelGroups.changeState('CommittedForMultipleScans');
            
            channelGroups = obj.getAllChannelGroups('ci');
            channelGroups.changeState('CommittedForMultipleScans');
            
            channelGroups = obj.getAllChannelGroups('co');
            channelGroups.changeState('CommittedForMultipleScans');
        end
        
        % queueOutputDataImpl is implemented by the vendor to handle data
        % to be queued to the hardware. All parameters will be pre-validated
        % and will always be passed in.
        function queueOutputDataImpl(obj,...
                dataToOutput)   % An mxn array of doubles where m is the number of scans, and n is the number of output channels
            
            channelGroups = [obj.getAllChannelGroups('ao') obj.getAllChannelGroups('do')]; % co is non-clocked
            for iChannelGroups = 1:numel(channelGroups)
                % Use the channel index map to select the output values for
                % this channel group
                thisGroupsData = dataToOutput(:,channelGroups(iChannelGroups).ChannelIOIndexMap);
                channelGroups(iChannelGroups).writeData(thisGroupsData);
            end
        end
        
        % configSampleClockTimingImpl is implemented by the vendor to
        % handle multiple calls to queue output data between starting
        % operation
        function configSampleClockTimingImpl(obj)
            channelGroups = [obj.getAllChannelGroups('ai'),...
                obj.getAllChannelGroups('di'),...
                obj.getAllChannelGroups('ci'),...
                obj.getAllChannelGroups('do'),...
                obj.getAllChannelGroups('ao'),...
                obj.getAllChannelGroups('co')]; % co is non-clocked
            channelGroups.configureForMultipleScans();
            channelGroups.updateNumberOfScans();
        end
        
        % flushOutputDataImpl is implemented by the vendor to delete any
        % data previously queued for output by the hardware.
        function flushOutputDataImpl(obj)
            channelGroups = obj.getAllChannelGroups('ao');
            if ~isempty(channelGroups)
                channelGroups.flush();
            end
            
            channelGroups = obj.getAllChannelGroups('do');
            if ~isempty(channelGroups)
                channelGroups.flush();
            end
            
            % co is non-clocked
        end
        
        % resetCountersImpl is implemented by the vendor to reset counter
        % input channels
        function resetCountersImpl(obj)
            [CIChannelGroups] = obj.getAllChannelGroups('ci');
            for iCIChannelGroups = 1:numel(CIChannelGroups)
                channelIndexMap = CIChannelGroups(iCIChannelGroups).ChannelIndexMap;
                obj.Channels(channelIndexMap).resetCounter();
            end
        end
        
        % inputSingleScanImpl is implemented by the vendor to acquire a
        % single scan of the input channels and return them.
        %
        % data: An 1xn array of doubles where n is the number of input channels
        function [data,triggerTime] = inputSingleScanImpl(obj)
            
            % Preallocate the data array
            data = zeros(1,obj.Channels.countInputChannels());
            
            [AIChannelGroups] = obj.getAllChannelGroups('ai');
            [DIChannelGroups] = obj.getAllChannelGroups('di');
            [CIChannelGroups] = obj.getAllChannelGroups('ci');
            
            for iAIChannelGroups = 1:numel(AIChannelGroups)
                AIChannelGroups(iAIChannelGroups).configureForSingleScan();
                inputIndices = AIChannelGroups(iAIChannelGroups).ChannelIOIndexMap;
                taskHandle = AIChannelGroups(iAIChannelGroups).getCommittedTaskHandle();
                [status,thisGroupsData,~,~] =...
                    daq.ni.NIDAQmx.DAQmxReadAnalogF64(...
                    taskHandle,...                                                  % taskHandle
                    int32(1),...                                                    % numSampsPerChan
                    obj.DefaultNIDAQmxTimeout,...                                   % timeout
                    uint32(daq.ni.NIDAQmx.DAQmx_Val_GroupByScanNumber),...          % fillMode
                    zeros(1,AIChannelGroups(iAIChannelGroups).NumberOfChannels),... % readArray
                    uint32(AIChannelGroups(iAIChannelGroups).NumberOfChannels),...  % arraySizeInSamps
                    int32(0),...                                                    % sampsPerChanRead
                    uint32(0));                                                     % reserved
                
                % G639008 Some devices like the NI-9227 require the sample
                % timing type to be set to sample clocked mode before
                % on-demand operations. G689777 Some devices like the
                % NI-9227 require that the sample rate be set before other
                % operations. This will be indicated by the status of the
                % attempt to get the DAQmxReadAnalogF64 above.
                if status == daq.ni.NIDAQmx.DAQmxErrorSampClkRateMustBeSpecd ||...
                        status == daq.ni.NIDAQmx.DAQmxErrorInvalidAttributeValue
                    
                    [status] = daq.ni.NIDAQmx.DAQmxSetSampTimingType(...
                        taskHandle,...
                        daq.ni.NIDAQmx.DAQmx_Val_SampClk);
                    daq.ni.utility.throwOrWarnOnStatus(status);
                    
                    [status] = daq.ni.NIDAQmx.DAQmxSetSampClkRate(...
                        taskHandle,...
                        obj.Rate);
                    daq.ni.utility.throwOrWarnOnStatus(status);
                    
                    [status,thisGroupsData,~,~] =...
                        daq.ni.NIDAQmx.DAQmxReadAnalogF64(...
                        taskHandle,...                                                  % taskHandle
                        int32(1),...                                                    % numSampsPerChan
                        obj.DefaultNIDAQmxTimeout,...                                   % timeout
                        uint32(daq.ni.NIDAQmx.DAQmx_Val_GroupByScanNumber),...          % fillMode
                        zeros(1,AIChannelGroups(iAIChannelGroups).NumberOfChannels),... % readArray
                        uint32(AIChannelGroups(iAIChannelGroups).NumberOfChannels),...  % arraySizeInSamps
                        int32(0),...                                                    % sampsPerChanRead
                        uint32(0));
                end
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                % G689804: Intermittent failures using InputSingleScan.
                % Some devices like the NI-9227 seem to start the task in a
                % continuous acquisition, despite being setup for on
                % demand. If on demand samples are not requested fast
                % enough, the device buffer overflows and we get an NI
                % error: Attempted to read samples that are no longer
                % available. We are performing on-demand acquisition,
                % explicitly make sure the task is not running.
                [status] = daq.ni.NIDAQmx.DAQmxStopTask(taskHandle);
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                triggerTime = now;
                % Use the channel map to copy thisGroupsData into the data array
                data(:,inputIndices) = thisGroupsData;
            end
            
            for iDIChannelGroups = 1:numel(DIChannelGroups)
                DIChannelGroups(iDIChannelGroups).configureForSingleScan();
                inputIndices = DIChannelGroups(iDIChannelGroups).ChannelIOIndexMap;
                channelIndices = DIChannelGroups(iDIChannelGroups).ChannelIndexMap;
                taskHandle = DIChannelGroups(iDIChannelGroups).getCommittedTaskHandle();
                
                % DAQmxReadDigitalLines returns data in a buffer composed
                % of a block of data for each channel group. The size of
                % each block is equal to the size of the largest group in
                % the task. The buffer size is the largest block size
                % multiplied by the total number of groups and/or lines in
                % the task.
                %
                blockSize = max([obj.Channels(channelIndices).GroupChannelCount]);
                rawDataBufferSize = blockSize * numel(channelIndices);
                [status,rawDigitalData,~,~,~] =...
                    daq.ni.NIDAQmx.DAQmxReadDigitalLines(...
                    taskHandle,...                                                  % taskHandle
                    int32(1),...                                                    % number of samples per channel
                    obj.DefaultNIDAQmxTimeout,...                                   % timeout
                    uint32(daq.ni.NIDAQmx.DAQmx_Val_GroupByScanNumber),...          % fillMode
                    uint8(zeros(1,rawDataBufferSize)),...                           % readArray
                    uint32(rawDataBufferSize),...                                   % arraySizeInSamps
                    int32(0),...                                                    % sampsPerChanRead
                    int32(0),...                                                    % numBytesPerChannel
                    uint32(0));                                                     % reserved
                
                daq.ni.utility.throwOrWarnOnStatus(status);
                triggerTime = now;
                
                % Format data
                bitIndex = 1;
                thisChanData = zeros(numel(channelIndices), 1);
                for idx = 1:numel(channelIndices)
                    channelIndex = channelIndices(idx);
                    numLines = obj.Channels(channelIndex).GroupChannelCount;
                    rawChannelData = rawDigitalData(bitIndex+numLines-1:-1:bitIndex);
                    thisChanData(idx) = binvec2dec(double(rawChannelData));
                    bitIndex = bitIndex + blockSize;
                end
                
                % Use the channel map to copy thisGroupsData into the data array
                data(:,inputIndices) = thisChanData;
            end
            
            for iCIChannelGroups = 1:numel(CIChannelGroups)
                CIChannelGroups(iCIChannelGroups).configureForSingleScan();
                inputIndices = CIChannelGroups(iCIChannelGroups).ChannelIOIndexMap;
                taskHandle = CIChannelGroups(iCIChannelGroups).getCommittedTaskHandle();
                [status,thisChanData,~] =...
                    daq.ni.NIDAQmx.DAQmxReadCounterScalarF64(...
                    taskHandle,...                                                  % taskHandle
                    obj.DefaultNIDAQmxTimeout,...                                   % timeout
                    double(0),...                                                   % readArray
                    uint32(0));                                                     % reserved
                if status == daq.ni.NIDAQmx.DAQmxErrorOperationTimedOut || ...
                        status == daq.ni.NIDAQmx.DAQmxErrorPulseActiveAtStart % See g828553 for more info
                    % Channel timed out (typically happens with unconnected
                    % PulseWidth or frequency channels)
                    status = 0;
                    thisChanData = NaN;
                end
                daq.ni.utility.throwOrWarnOnStatus(status);
                triggerTime = now;
                % Use the channel map to copy thisGroupsData into the data array
                data(:,inputIndices) = thisChanData;
            end
        end
        
        % outputSingleScanImpl is implemented by the vendor to generate a
        % single scan of the output channels. All parameters will be pre-validated
        % and will always be passed in.
        function outputSingleScanImpl(obj,...
                dataToOutput)   % A 1xn cell array of data where n is the number of output channels
            
            AOChannelGroups = obj.getAllChannelGroups('ao');
            DOChannelGroups = obj.getAllChannelGroups('do');
            
            for iAOChannelGroups = 1:numel(AOChannelGroups)
                % Configure for single scan
                AOChannelGroups(iAOChannelGroups).configureForSingleScan();
                outputIndices = AOChannelGroups(iAOChannelGroups).ChannelIOIndexMap;
                taskHandle = AOChannelGroups(iAOChannelGroups).getCommittedTaskHandle();
                
                % Use the channel index map to select the output values for
                % this channel group
                thisGroupsData = double(cell2mat(dataToOutput(:,outputIndices)));
                
                % Output the data
                [status,~,~] =...
                    daq.ni.NIDAQmx.DAQmxWriteAnalogF64(...
                    taskHandle,...                                          % taskHandle
                    int32(1),...                                            % numSampsPerChan
                    uint32(true),...                                        % autoStart
                    obj.DefaultNIDAQmxTimeout,...                           % timeout
                    uint32(daq.ni.NIDAQmx.DAQmx_Val_GroupByScanNumber),...  % dataLayout
                    thisGroupsData,...                                      % writeArray
                    int32(0),...                                            % sampsPerChanWritten
                    uint32(0));                                             % reserved
                
                daq.ni.utility.throwOrWarnOnStatus(status);
            end
            
            for iDOChannelGroups = 1:numel(DOChannelGroups)
                % Configure for single scan
                DOChannelGroups(iDOChannelGroups).configureForSingleScan();
                outputIndices = DOChannelGroups(iDOChannelGroups).ChannelIOIndexMap;
                channelIndices = DOChannelGroups(iDOChannelGroups).ChannelIndexMap;
                taskHandle = DOChannelGroups(iDOChannelGroups).getCommittedTaskHandle();
                
                % Use the channel index map to select the output values for
                % this channel group
                thisGroupsData = double(cell2mat(dataToOutput(:,outputIndices)));
                
                blockSize = max([obj.Channels(channelIndices).GroupChannelCount]);
                rawDataBufferSize = blockSize * numel(channelIndices);
                rawDigitalData = zeros(rawDataBufferSize, 1);
                
                % Format data
                bitIndex = 1;
                for idx = 1:numel(channelIndices)
                    channelIndex = channelIndices(idx);
                    numLines = obj.Channels(channelIndex).GroupChannelCount;
                    rawDigitalData(bitIndex+numLines-1:-1:bitIndex) =...
                        dec2binvec(thisGroupsData(idx), numLines);
                    bitIndex = bitIndex + blockSize;
                end
                
                % Output the data
                [status,~,~] =...
                    daq.ni.NIDAQmx.DAQmxWriteDigitalLines(...
                    taskHandle,...                                          % taskHandle
                    int32(1),...                                            % numSampsPerChan
                    uint32(true),...                                        % autoStart
                    obj.DefaultNIDAQmxTimeout,...                           % timeout
                    uint32(daq.ni.NIDAQmx.DAQmx_Val_GroupByScanNumber),...  % dataLayout
                    uint8(rawDigitalData),...                               % writeArray
                    int32(0),...                                            % sampsPerChanWritten
                    uint32(0));                                             % reserved
                
                daq.ni.utility.throwOrWarnOnStatus(status);
            end
        end
        
        function actualRate = adjustNewRateHook(obj)
            % adjustNewRateHook Adjust the rate requested by user
            % Provides the vendor the opportunity to adjust the rate of a
            % session to reflect hardware limitations, such as rate clock
            % dividers.
            %
            % NEWRATE = adjustNewRateHook(REQUESTEDRATE) is called with the
            % double REQUESTEDRATE from the user. The function returns the
            % double NEWRATE, which may be adjusted to reflect hardware
            % limitations.
            %
            % adjustNewRateHook is called after RateLimit checks have been
            % done.  NEWRATE will be adjusted to fall within RateLimit.
            % Note that sessionPropertyBeingChangedHook will still be
            % called regarding the change to Rate after this.
            
            % If there are no channels, then leave the rate alone.
            if isempty(obj.Channels)
                actualRate = obj.Rate;
                return
            end
            
            channelGroups = obj.getAllChannelGroups();
            actualRate = zeros(numel(channelGroups),1);
            
            findCommonRateSupportedByAllChannels();
            
            for iChannelGroups = 1:numel(channelGroups)
                taskHandle = channelGroups(iChannelGroups).getUnreservedTaskHandle();
                
                %Set the sample time. Ask channel group to perform this
                %operation.
                %DAQmxSetSampClkRate does not set the
                %sample clock rate according to supported values for some
                %devices like USB-6259. See g657921.
                %Using DAQmxCfgSampClkTiming function as it sets sample
                %rate according to device.
                channelGroups(iChannelGroups).doConfigureScanClock();
                
                [status, actualRate(iChannelGroups)] = daq.ni.NIDAQmx.DAQmxGetSampClkRate(...
                    taskHandle,...
                    double(0));
                
                % Digital output devices do not typically support an
                % Onboard clock, giving NIDAQmx error:
                % DAQmxErrorInvalidRoutingSourceTerminalName_Routing
                %
                % To keep functionality consistent with counter subsystems,
                % leave the rate unadjusted until the user adds a subsystem
                % with a source clock that can be shared with the digital
                % subsystem.
                if status ~= 0
                    actualRate(iChannelGroups) = obj.Rate; % No rate adjustment
                end
            end
            if any(abs(actualRate - mean(actualRate)) * 100/mean(actualRate) > obj.MaximumRateVariationPercentage)
                % The various tasks could arrive at slightly different
                % rates -- if any vary more than 1 percent
                tmpBuf = sprintf('%f, ', sort(actualRate(:)));
                tmpBuf(end-1:end) = [];
                obj.localizedWarning('nidaq:ni:variationInRates',tmpBuf)
            end
            actualRate = max(actualRate);
            
            function  findCommonRateSupportedByAllChannels()
                
                channelGroups = obj.getAllChannelGroups();
                
                % Case - Only one device
                if numel(channelGroups) == 1
                    return;
                end
                
                % Exclude DSA devices from the list of devices to check
                productCategory =  zeros(numel(channelGroups),1);
                for index = 1:numel(channelGroups)
                    % Exclude DSA from the algorithm to find same rate. DSAs
                    % can set their rate to any number specified by the user.
                    deviceIDs{index} = channelGroups(index).DeviceID; %#ok<AGROW>
                    [status,productCategory(index)] = ...
                        daq.ni.NIDAQmx.DAQmxGetDevProductCategory(deviceIDs{index},int32(0));
                end
                
                channelGroupsToTest = channelGroups(...
                    productCategory ~= daq.ni.NIDAQmx.DAQmx_Val_DynamicSignalAcquisition);
                
                numberOfAttempts = 16;
                success = false;
                testRates = repmat(obj.Rate,numberOfAttempts,1);
                originalDesiredRate = obj.Rate;
                
                while numberOfAttempts > 0 && ~isempty(channelGroupsToTest)
                    for iChannelGroupsToTest = 1:numel(channelGroupsToTest)
                        success = true;
                        closestRate = getClosestSupportedRate(channelGroupsToTest(iChannelGroupsToTest));
                        % check if the actual rate set by the device matches the
                        % desired rate.
                        if abs(obj.Rate - closestRate) > eps(obj.Rate)
                            if closestRate < obj.RateLimit(2)
                                obj.Rate = closestRate;
                            else
                                obj.Rate = originalDesiredRate;
                                return;
                            end
                            success = false;
                            break
                        end
                    end
                    if success == true
                        if abs(obj.Rate - originalDesiredRate) * 100/obj.Rate > obj.MaximumRateVariationPercentage
                            obj.Rate = originalDesiredRate;
                        end
                        return;
                    end
                    if any(abs(testRates - obj.Rate) < eps(obj.Rate))
                        obj.Rate = max(testRates) * 1.01;
                        if obj.Rate > obj.RateLimit(2) ||...
                                abs(obj.Rate - originalDesiredRate) * 100/obj.Rate > obj.MaximumRateVariationPercentage
                            obj.Rate = originalDesiredRate;
                            return;
                        end
                    end
                    testRates(numberOfAttempts) = obj.Rate;
                    numberOfAttempts = numberOfAttempts - 1;
                end
                
                obj.Rate = originalDesiredRate;
                
            end
            
            function  actualRate = getClosestSupportedRate(channelGroup)
                
                taskHandle = channelGroup.getUnreservedTaskHandle();
                
                %Set the sample time.
                channelGroup.doConfigureScanClock();
                
                [status, actualRate] = daq.ni.NIDAQmx.DAQmxGetSampClkRate(...
                    taskHandle,...
                    double(0));
                
                if status ~= 0
                    actualRate = obj.Rate; % No rate adjustment
                end
            end
        end
        
        function updateRateLimitInfoHook(obj)
            % updateRateLimitInfoHook Adjust the RateLimit
            % Provides the vendor the opportunity to adjust the
            % RateLimitInfo of a session to reflect channel adds and
            % deletes.
            %
            % updateRateLimitInfoHook() is called after channels are added
            % or removed from a session.  The vendor implementation must
            % directly set the RateLimitInfo property if it wishes to
            % change the current setting
            %
            % Note that sessionPropertyBeingChangedHook will still be
            % called regarding the change to RateLimitInfo after this.
            
            obj.updateRateLimit();
        end
        
        function removeConnectionHook(obj,~)
            % removeChannelHook React to the removal of a channel.
            %
            % Provides the vendor the opportunity to change their
            % configuration when a channel is removed.  Note that
            % releaseHook() will be called before this if needed.
            %
            % removeChannelHook(INDEX) is called before channels are
            % removed from a session.  The vendor implementation may
            % throw an error to prevent removal of a channel.  INDEX is the
            % index of the channel to be removed in the Channels property.
            %
            %Default implementation is to do nothing.
            
            % Get the channel group
            allChannelGroups = obj.getAllChannelGroups();
            
            
            for i = 1:numel(allChannelGroups)
                if allChannelGroups(i).NumberOfChannels ~= 0
                    obj.recreateTaskHandle(allChannelGroups(i).Name);
                end
            end
        end
        
        function removeChannelHook(obj,index)
            % removeConnectionHook React to the removal of a channel.
            %
            % Provides the vendor the opportunity to change their
            % configuration when a connection is removed.  Note that
            % releaseHook() will be called before this if needed.
            %
            % removeConnectionHook(INDEX) is called before connections are
            % removed from a session.  The vendor implementation may
            % throw an error to prevent removal of a connection.  INDEX is the
            % index of the connections to be removed in the Connections property.
            %
            %Default implementation is to do nothing.
            
            % Get the channel group
            ChannelGroupOfChannelToDelete = obj.getChannelGroup(obj.Channels(index).GroupName);
            
            if ChannelGroupOfChannelToDelete.NumberOfChannels == 1
                % Delete the channel group, since this is the last channel
                obj.removeChannelGroup(ChannelGroupOfChannelToDelete.Name)
            else
                % Clear the task associated with this channel group (since that
                % channel is about to be deleted
                ChannelGroupOfChannelToDelete.clearTask();
            end
            
            % Reset AutoSyncDSA to 0 after all the DSA channels have been
            % removed from the session.
            if obj.AutoSyncDSA
                
                PCIDSAChannelsInSession = daq.ni.PCIDSADevice.findPCIChannelsInSession(obj);
                PXIDSAChannelsInSession = daq.ni.PXIDSAModule.findPXIChannelsInSession(obj);
                
                % Check is only one PCI or PXI DSA devices is left in the
                % session and verify that the last PCI or PXI DSA device's
                % channel is being removed by matching ID.
                if (numel(PCIDSAChannelsInSession) == 1) && strcmp(PCIDSAChannelsInSession.ID,obj.Channels(index).Device.ID) || ...
                        (numel(PXIDSAChannelsInSession) == 1) && strcmp(PXIDSAChannelsInSession.ID,obj.Channels(index).Device.ID)
                    obj.localizedWarning('nidaq:ni:autoSyncBeingReset');
                    
                    % Reset AutoSyncDSA
                    obj.InitializationInProgress = true;
                    obj.AutoSyncDSA = 0;
                    obj.InitializationInProgress = false;
                end
            end
        end
        
        % Override for special DIO channel parsing
        function [result] = parseChannelsHook(~, subsystem, channelID)
            switch(subsystem)
                case daq.internal.SubsystemType.DigitalIO
                    result = daq.ni.DigitalChannel.parseChannelsHook(channelID);
                otherwise
                    % Use default channel hook
                    result = daq.Channel.parseChannelsHook(channelID);
            end
        end
        
        function channelsChangedHook(obj)
            % channelsRemovedHook Notify the vendor if a channel was added
            % or removed from the session.Channels property.
            allChannelGroups = obj.getAllChannelGroups();
            for iChannelGroup = 1:numel(allChannelGroups)
                channelGroup = allChannelGroups(iChannelGroup);
                channelGroup.updateChannelMap();
                
                % G771104: Removal of channels affecting ADCTimingMode
                % results in tasks that report wrong rate limits.
                obj.recreateTaskHandle(channelGroup.Name);
            end
        end
        
        function prepareHook(obj)
            % prepareHook Set up to reduce latency of impending startHardwareImpl
            %
            % Provides the vendor the opportunity to preallocate hardware
            % in advance of a call to startHardwareImpl, in order to reduce latency
            % associated with start.
            
            % Check if the system is under-defined
            obj.SyncManager.checkForUnderdefinedSystem();
            
            sourceDevice = obj.SyncManager.getSourceDevice();
            destinationDevices = obj.SyncManager.getDestinationDevices();
            
            % Configure the source device first
            if ~strcmp(sourceDevice,daq.SyncManager.NoDeviceSet)
                configureDevice(sourceDevice);
            end
            
            % Configure the destination devices
            for iDestinationDevice = 1: numel(destinationDevices)
                configureDevice(destinationDevices{iDestinationDevice});
            end
            
            % Lastly, configure devices without any connections. These are
            % devices which have no connections. Devices with a single type
            % of connection will be configured before.
            devicesWithoutConnections = obj.SyncManager.getDevicesWithoutConnections;
            for iDevices = 1:numel(devicesWithoutConnections)
                configureDevice(devicesWithoutConnections{iDevices});
            end
            
            % Loop through all the subsystems of a device. This function
            % provides the hierarchy of subsystems in terms of clocks and
            % triggers. Any new subsystem added to the NI adaptor will
            % need to added here also.
            function configureDevice(deviceID)
                
                exportedSignalsAlready = false;
                
               %Start with defaults
                parentSubsystemSyncInfo = daq.ni.SyncInfo();
                syncInfo = daq.ni.SyncInfo();
                channelGroupsForThisDevice = obj.getChannelGroupsForDevice(deviceID);
                
                if ~isempty(channelGroupsForThisDevice)
                    cg = channelGroupsForThisDevice.locate('ai');
                    if ~isempty(cg)
                        for iChannelGroup = 1:length(cg)
                            % get sync info from sync manager
                            syncInfo = getSyncInfoFromSyncManager(cg(iChannelGroup),parentSubsystemSyncInfo);
                            
                            exportedSignalsAlready = true;
                            
                            % Store syncInfo in channel group
                            cg(iChannelGroup).configureSyncInfo(syncInfo);
                            
                            % Configure AI
                            parentSubsystemSyncInfo = configureSubsystem(cg(iChannelGroup));
                        end
                    end
                    
                    cg = channelGroupsForThisDevice.locate('ao');
                    if ~isempty(cg)
                        % g770020: Choose scan clock configuration for ao.
                        % If 'Onboard' was used in ai, select 'Onboard' for
                        % 'ao' also. 
                        
                        % g874293: Only do this for DSA devices.
                        
                        % g899646: E-Series does not work in master/slave
                        % clocking configuration. 
                        
                        %% g873066,873097,885613: Fixed LXE incompatibility warnings
                        %HardwareInfo = daq.HardwareInfo.getInstance(); 
                        %devices = HardwareInfo.Devices;
                        %device = devices.locate('ni',deviceID);
                        %[~,productCategory] = ...
                        %    daq.ni.NIDAQmx.DAQmxGetDevProductCategory(device.ID,int32(0));
                        %
                        %if (isa(device,'daq.ni.PCIDSADevice') || isa(device,'daq.ni.PXIDSAModule') ...
                        %        || (productCategory == daq.ni.NIDAQmx.DAQmx_Val_ESeriesDAQ)) && ...
                        %        strcmp(syncInfo.ScanClock,daq.SyncManager.Default)
                        %    parentSubsystemSyncInfo.ScanClock = daq.SyncManager.Default;
                        %end
                        
                        % g899646: Reverting all device families to use the
                        % onboard clock. If using external triggers with
                        % multiple subsystems, there is a narrow time frame
                        % during setup, when the subsystems are being
                        % started back to back, where the trigger can slip
                        % between the task starts. The master/slave
                        % configuration is not a valid solution to this
                        % problem because it introduces a clock cycle delay
                        % that breaks the common use case. 
                        if strcmp(syncInfo.ScanClock,daq.SyncManager.Default)
                            parentSubsystemSyncInfo.ScanClock = daq.SyncManager.Default;
                        end
                        
                        for iChannelGroup = 1:length(cg)
                            % get sync info from sync manager
                            syncInfo = getSyncInfoFromSyncManager(cg(iChannelGroup),parentSubsystemSyncInfo);
                            
                            
                            if exportedSignalsAlready
                                syncInfo.ExportedStartTrigger = 'Default';
                                syncInfo.ExportedScanClock = 'Default';
                            end
                            
                            exportedSignalsAlready = true;
                            
                            % Store syncInfo in channel group
                            cg(iChannelGroup).configureSyncInfo(syncInfo);
                            
                            % Configure AO trigger & Clock
                            parentSubsystemSyncInfo = configureSubsystem(cg(iChannelGroup));
                        end
                    end
                    
                    cg = channelGroupsForThisDevice.locate('ci');
                    if ~isempty(cg)
                        % A given device may have several channel groups for a
                        % subsystem, notably Counter/Timer
                        for iChannelGroup = 1:length(cg)
                            % get sync info from sync manager
                            syncInfo = getSyncInfoFromSyncManager(cg(iChannelGroup),parentSubsystemSyncInfo);
                            
                            if exportedSignalsAlready
                                syncInfo.ExportedStartTrigger = 'Default';
                                syncInfo.ExportedScanClock = 'Default';
                            end
                            
                            exportedSignalsAlready = true;
                            
                            % Store syncInfo in channel group
                            cg(iChannelGroup).configureSyncInfo(syncInfo);
                            
                            % Configure CI trigger & Clock
                            parentSubsystemSyncInfo = configureSubsystem(cg(iChannelGroup));
                        end
                    end
                    cg = channelGroupsForThisDevice.locate('di');
                    
                    if ~isempty(cg)
                        for iChannelGroup = 1:length(cg)
                            % get sync info from sync manager
                            syncInfo = getSyncInfoFromSyncManager(cg(iChannelGroup),parentSubsystemSyncInfo);
                            
                            if exportedSignalsAlready
                                syncInfo.ExportedStartTrigger = 'Default';
                                syncInfo.ExportedScanClock = 'Default';
                            end
                            
                            exportedSignalsAlready = true;
                            % Store syncInfo in channel group
                            cg(iChannelGroup).configureSyncInfo(syncInfo);
                            
                            % Configure DI
                            parentSubsystemSyncInfo = configureSubsystem(cg(iChannelGroup));
                        end
                    end
                    
                    cg = channelGroupsForThisDevice.locate('do');
                    if ~isempty(cg)
                        for iChannelGroup = 1:length(cg)
                            % get sync info from sync manager
                            syncInfo = getSyncInfoFromSyncManager(cg(iChannelGroup),parentSubsystemSyncInfo);
                            
                            if exportedSignalsAlready
                                syncInfo.ExportedStartTrigger = 'Default';
                                syncInfo.ExportedScanClock = 'Default';
                            end
                            exportedSignalsAlready = true;
                            % Store syncInfo in channel group
                            cg(iChannelGroup).configureSyncInfo(syncInfo);
                            
                            % Configure DO trigger & Clock
                            parentSubsystemSyncInfo = configureSubsystem(cg(iChannelGroup));
                        end
                    end
                    
                    
                    
                    cg = channelGroupsForThisDevice.locate('co');
                    if ~isempty(cg)
                        % A given device may have several channel groups for a
                        % subsystem, notably Counter/Timer
                        for iChannelGroup = 1:length(cg)
                            % get sync info from sync manager
                            syncInfo = getSyncInfoFromSyncManager(cg(iChannelGroup),parentSubsystemSyncInfo);
                            
                            if exportedSignalsAlready
                                syncInfo.ExportedStartTrigger = 'Default';
                                syncInfo.ExportedScanClock = 'Default';
                            end
                            
                            exportedSignalsAlready = true;
                            % Store syncInfo in channel group
                            cg(iChannelGroup).configureSyncInfo(syncInfo);
                            
                            % Configure Counter output trigger & Clock
                            [~] = configureSubsystem(cg(iChannelGroup));
                        end
                    end
                end
            end
            
            % Configure the subsystem by first getting the sync information
            % from the Sync Manager.
            function syncInfo = configureSubsystem(cg)
                
                % Configure for multiple scans
                cg.configureForMultipleScans();
                
                % syncInfo is subsystem-dependent and will be same for all channel
                % groups for a particular subsystem and device.
                syncInfo = cg.SyncInfo;
                
                % Other downstream subsystems can use the same
                % trigger configuration
                syncInfo.StartTrigger = cg.getStartTriggerConfiguration;
                % Other downstream subsystems can use the same
                % clocking configuration
                syncInfo.ScanClock = cg.getScanClockConfiguration;
                
            end
            
            function syncInfo = getSyncInfoFromSyncManager(cg,parentSubsystemSyncInfo)
                % Sync manager contains all the clock and triggering
                % information needed for configuring a subsystems
                % syncInfo is subsystem-dependent and will be same for all channel groups
                % for a particular subsystem and device.
                syncInfo = obj.SyncManager.configureChannelGroup(cg,parentSubsystemSyncInfo);
            end
        end
        
        function releaseHook(obj)
            % releaseHook Release resources allocated during prepareHook
            %
            % Provides the vendor the opportunity to release hardware
            % allocated by prepareHook, in order to reduce latency
            % associated with start.
            
            obj.getAllChannelGroups().unreserve();
        end
        
        function sessionPropertyBeingChangedHook(obj,propertyName,newValue)
            % sessionPropertyBeingChangedHook React to change in session property.
            %
            % Provides the vendor the opportunity to react to changes in
            % session properties.  Note that releaseHook() will be called
            % before this if needed.
            %
            % sessionPropertyBeingChangedHook(PROPERTYNAME,NEWVALUE)
            % is called before property changes occur.  The vendor
            % implementation may throw an error to prevent the change, or
            % update their corresponding hardware session, if appropriate.
            % PROPERTYNAME is the name of the property to change, and
            % NEWVALUE is the new value the property will have if this
            % function returns normally.
            %
            switch propertyName
                case 'AutoSyncDSA'
                    try
                        if newValue
                            PCIDSADevicesInSession = daq.ni.PCIDSADevice.findPCIdevicesInSession(obj);
                            PXIDSADevicesInSession = daq.ni.PXIDSAModule.findPXImodulesInSession(obj);
                            
                            % Error out  if we have no channels or no DSA
                            % channels present in session.
                            if isempty(obj.Channels) || ...
                                    ( isempty(PCIDSADevicesInSession) && ...
                                    isempty(PXIDSADevicesInSession) )
                                obj.localizedError('nidaq:ni:addChannelsBeforeSettingAutoSyncDSA')
                            end
                            
                            devicesInSession = [obj.Channels.Device];
                            nonDSADevices = devicesInSession( ...
                                arrayfun(@(x) ~isa(x,'daq.ni.PCIDSADevice') && ~isa(x,'daq.ni.PXIDSAModule'), devicesInSession)) ;
                            
                            % Warn if non-DSA channels are found in the
                            % session.
                            if ~isempty(nonDSADevices)
                                obj.localizedWarning('nidaq:ni:AutoSyncDSAOnlyApplicableToDSADevices')
                            end
                            
                            % If AutoSyncDSA is being turned on, verify the
                            % correctness of PCI DSA devices in the
                            % session.
                            % We do not need a similar verifySetup
                            % function for PXI DSA devices. This is because
                            % the NI driver error at the time of channel
                            % creation in PXI while it only errors out at
                            % the time of task start in PCI case.
                            if ~isempty(PCIDSADevicesInSession)
                                PCIDSADevicesInSession(1).verifyValidAutoSyncDSASetup(obj);
                            end
                            
                            % Give the sync manager to verify the
                            % correctness of the connections after
                            % auto synchronization will be turned on.
                            if ~isempty(PCIDSADevicesInSession) || ~isempty(PXIDSADevicesInSession)
                                obj.SyncManager.validateAllDSAConnections();
                            end
                        end
                        
                        % AutoSyncDSA changes the way different channels are
                        % grouped. Recreate all the channel groups based on
                        % the AutoSyncDSA's new property. If PXI setup is
                        % not proper, the driver will error out at this
                        % time.
                        obj.recreateAllChannelGroups();
                        
                    catch  e
                        obj.handleAutoSyncDSAErrors(e);
                        rethrow(e);
                    end
            end
        end
        
        function [syncObjectClassName] = getSyncManagerObjectClassNameHook(obj) %#ok<MANU>
            % getSyncObjectClassNameHook Specify the name of the class that implements the vendor specific daq.Sync specialization.
            %
            % Provides the vendor the opportunity to provide the name of
            % the class to use when the Sync object is instantiated.
            %
            % [syncObjectClassName] = getSyncObjectClassNameHook() is
            % called when the session is created.
            syncObjectClassName = 'daq.ni.SyncManager';
        end
        
        function throwErrorOccurredHook(obj, errorCapture)
            % throwErrorOccurredHook React to errors that occurred during
            % callbacks in a foreground operation
            %
            % Provides the vendor with the opportunity to react to
            % ErrorOccurred events that were generated by a foreground
            % operation.
            id = errorCapture.identifier;
            errorID = '';
            switch(id)
                case 'nidaq:ni:NIDAQmxError89136'
                    errorID = 'nidaq:ni:NIDAQmxError89136';
                case 'nidaq:ni:NIDAQmxError200019'
                    errorID = 'nidaq:ni:NIDAQmxError200019';
                case 'nidaq:ni:NIDAQmxError89125'
                    errorID = 'nidaq:ni:NIDAQmxError89125';
                case 'nidaq:ni:NIDAQmxError50103'
                    errorID = 'nidaq:ni:DAQmxResourceReserved';
                otherwise
                    % do nothing
            end
            
            if ~isempty(errorID)
                obj.localizedError(errorID);
            else
                throw(errorCapture);
            end
        end
        
    end
    
    % Private methods
    methods (Access = private)
        
        function [channelGroup] = getChannelGroup(obj,channelGroupName)
            % getChannelGroup return the appropriate daq.ni.ChannelGroup
            % [CHANNELGROUP] = getChannelGroup(CHANNELGROUPNAME) returns
            % the daq.ni.ChannelGroup object CHANNELGROUP with the name
            % CHANNELGROUPNAME.  If the channel group does not exist, it
            % will be created
            %
            % Channel groups describe related channels that belong together
            % in a task.  They are self-organizing, with names generally of
            % the form <subsystem>/<deviceid>, but related devices may
            % choose another mechanism.  For instance, CompactDAQ uses
            % <subsystem>/<chassisID>.
            
            % Does this channel group exist?
            if ~obj.ChannelGroup.isKey(channelGroupName)
                % no: create it
                if strfind(channelGroupName,'ai/')
                    obj.ChannelGroup(channelGroupName) = daq.ni.ChannelGroupAnalogInput(obj,channelGroupName);
                elseif strfind(channelGroupName,'ao/')
                    obj.ChannelGroup(channelGroupName) = daq.ni.ChannelGroupAnalogOutput(obj,channelGroupName);
                elseif strfind(channelGroupName,'ci/')
                    obj.ChannelGroup(channelGroupName) = daq.ni.ChannelGroupCounterInput(obj,channelGroupName);
                elseif strfind(channelGroupName,'co/')
                    obj.ChannelGroup(channelGroupName) = daq.ni.ChannelGroupCounterOutput(obj,channelGroupName);
                elseif strfind(channelGroupName,'di/')
                    obj.ChannelGroup(channelGroupName) = daq.ni.ChannelGroupDigitalInput(obj,channelGroupName);
                elseif strfind(channelGroupName,'do/')
                    obj.ChannelGroup(channelGroupName) = daq.ni.ChannelGroupDigitalOutput(obj,channelGroupName);
                else
                    obj.localizedError('nidaq:ni:unknownSubsystemType',channelGroupName)
                end
            end
            
            % Get the appropriate daq.ni.ChannelGroup object
            channelGroup = obj.ChannelGroup(channelGroupName);
            
            % Check that it is valid, and hasn't been deleted
            if ~isvalid(channelGroup)
                obj.localizedError('nidaq:ni:channelGroupDeleted');
            end
        end
        
        function removeChannelGroup(obj,channelGroupName)
            % removeChannelGroup removes the appropriate daq.ni.ChannelGroup
            % [CHANNELGROUP] = removeChannelGroup(CHANNELGROUPNAME) removes
            % the daq.ni.ChannelGroup object with the name
            % CHANNELGROUPNAME.
            %
            % Channel groups describe related channels that belong together
            % in a task.  They are self-organizing, with names generally of
            % the form <subsystem>/<deviceid>, but related devices may
            % choose another mechanism.  For instance, CompactDAQ uses
            % <subsystem>/<chassisID>.
            
            % Does this channel group exist?
            if ~obj.ChannelGroup.isKey(channelGroupName)
                return
            end
            
            % Get the channel group to remove
            channelGroupToRemove = obj.getChannelGroup(channelGroupName);
            
            % clear the task
            channelGroupToRemove.clearTask();
            
            % Remove from map
            obj.ChannelGroup.remove(channelGroupName);
            
            % G685613: delete the channel group
            delete(channelGroupToRemove)
        end
        
        function [channelGroups] = getAllChannelGroups(obj,type)
            % Return an array of all channel groups
            %
            % [CHANNELGROUPS] = getAllChannelGroups() return all daq.ni.ChannelGroup objects
            %
            % [CHANNELGROUPS] = getAllChannelGroups(TYPE) return only the objects containing
            % the string TYPE.
            
            if isempty(obj.ChannelGroup)
                channelGroups = daq.ni.ChannelGroup.empty();
                return
            end
            
            % Get all channel groups: map can only return a cell array
            cellArrayOfChannelGroups = obj.ChannelGroup.values;
            
            % Transform cell array into true array of objects
            channelGroups = [cellArrayOfChannelGroups{:}];
            
            if isempty(channelGroups)
                channelGroups = daq.ni.ChannelGroup.empty();
                return
            end
            
            % Filter out any deleted objects
            channelGroups = channelGroups(isvalid(channelGroups));
            
            if isempty(channelGroups)
                channelGroups = daq.ni.ChannelGroup.empty();
                return
            end
            
            if nargin >= 2
                channelGroups = channelGroups.locate(type);
            end
        end
        
        function channelGroupsForThisDevice = getChannelGroupsForDevice(obj,deviceID)
            channelGroups = obj.getAllChannelGroups();
            
            channelGroupsForThisDevice = channelGroups(~cellfun(@isempty,strfind({channelGroups.DeviceID},deviceID)));
            
            if isempty(channelGroupsForThisDevice)
                
                % g873066,873097,885613: Fixed LXE incompatibility warnings
                HardwareInfo = daq.HardwareInfo.getInstance(); 
                devices = HardwareInfo.Devices;
                device = devices.locate('ni',deviceID);
                if isa(device,'daq.ni.PCIDSADevice')
                    channelGroupsForThisDevice = channelGroups(~cellfun(@isempty,....
                        strfind({channelGroups.DeviceID},['RTSI' num2str(device.RTSICable)])));
                end
                if isa(device,'daq.ni.PXIDSAModule')
                    channelGroupsForThisDevice = channelGroups(~cellfun(@isempty,....
                        strfind({channelGroups.DeviceID},['PXI' num2str(device.ChassisNumber)])));
                    
                end
            end
        end
        
        function link = getLinkIfAvailable(obj, errorMsg)
            % In some contexts, such as publishing, you cannot use
            % hyperlinks.  If hotlinks is true, then you can.
            hotlinks = feature('hotlinks');
            if hotlinks
                link = obj.getLocalizedText(errorMsg);
            else
                link = '';
            end
        end
        
    end
    
    properties (GetAccess = private,SetAccess = private)
        
        % Internal property that suppresses set.* functions during
        % initialization
        InitializationInProgress
    end
    % Private static methods
    methods(Static,Access = private)
    end
end
