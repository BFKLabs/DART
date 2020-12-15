classdef (Hidden) DeviceInfo < daq.DeviceInfo
    %DeviceInfo Device info for National Instruments devices.
    %
    %    This class represents devices by National Instruments.
    %
    %    This undocumented class may be removed in a future release.
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    % Specializations of the daq.DeviceInfo class should call addSubsystem
    % repeatedly to add a SubsystemInfo record to their device. usage:
    % addSubsystem(SUBSYSTEM) adds an adaptor specific SubsystemInfo record
    % SUBSYSTEM to the device.
    
    %% -- Public methods, properties, and events --
    
    % Read only properties
    properties (SetAccess = private)
        IsSimulated
    end
    
    % Terminals property hidden as part of hiding the Sync interface
    properties (SetAccess = protected)
        Terminals
    end
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods (Hidden)
        function obj = DeviceInfo(vendor,device)
            % Get the device type/model
            [bufferSize,~] = daq.ni.NIDAQmx.DAQmxGetDevProductType(device,' ',uint32(0));
            [status,devProductType] = daq.ni.NIDAQmx.DAQmxGetDevProductType(device,blanks(bufferSize),uint32(bufferSize));
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            % Get the device serial number, which represents the unique
            % hardware ID
            [status,serialNumber] = daq.ni.NIDAQmx.DAQmxGetDevSerialNum(device, uint32(0));
            
            % G660439: USB Firmware Loader (__tp1, __tp2, ...) devices do
            % not have serial numbers
            if status == daq.ni.NIDAQmx.DAQmxErrorRequiredPropertyMissing
                daq.ni.utility.throwOrWarnOnStatus(status);
            end
            
            % Is the device simulated?
            [status,isSimulated] = daq.ni.NIDAQmx.DAQmxGetDevIsSimulated(device,uint32(0));
            daq.ni.utility.throwOrWarnOnStatus(status);
            isSimulated = (isSimulated ~= 0);
            
            
            % If the device is simulated, the serial number is no good
            % (it's always 0).  Use the default mechanism to generate a
            % unique ID, by calling the 3 argument constructor.
            if isSimulated || serialNumber == 0
                arg = {};
            else
                arg = {num2str(serialNumber)};
            end
            % Call the superclass constructor
            obj@daq.DeviceInfo(vendor, device, devProductType,arg{:});
            
            obj.IsSimulated = isSimulated;
            
            % Only recognize if it's got a subsystem we understand
            obj.RecognizedDevice = false;
            
            % Does the device support analog input?
            [bufferSize,~] = daq.ni.NIDAQmx.DAQmxGetDevAIPhysicalChans(device,' ',uint32(0));
            [status,AIPhysicalChans] = daq.ni.NIDAQmx.DAQmxGetDevAIPhysicalChans(device,blanks(bufferSize),uint32(bufferSize));
            daq.ni.utility.throwOrWarnOnStatus(status);
            if ~isempty(AIPhysicalChans)
                % Parse the comma separated list into a cell array of
                % strings.
                AIPhysicalChans = textscan(AIPhysicalChans,[device '/%s'],'Delimiter',',');
                if numel(AIPhysicalChans) > 0
                    AIPhysicalChans = AIPhysicalChans{1};
                    AIPhysicalChans = obj.filterSupportedChannelIDs(AIPhysicalChans);
                    try
                        obj.addSubsystem(daq.ni.AnalogInputInfo.createAnalogInputInfo(device,AIPhysicalChans,obj.Model))
                        obj.RecognizedDevice = true;
                    catch %#ok<CTCH>
                        % Ignore errors. The device will appear in the list
                        % as unrecognized.
                    end
                end
            end
            
            % Does the device support analog output?
            [bufferSize,~] = daq.ni.NIDAQmx.DAQmxGetDevAOPhysicalChans(device,' ',uint32(0));
            [status,AOPhysicalChans] = daq.ni.NIDAQmx.DAQmxGetDevAOPhysicalChans(device,blanks(bufferSize),uint32(bufferSize));
            daq.ni.utility.throwOrWarnOnStatus(status);
            if ~isempty(AOPhysicalChans)
                % Parse the comma separated list into a cell array of
                % strings.
                AOPhysicalChans = textscan(AOPhysicalChans,[device '/%s'],'Delimiter',',');
                if numel(AOPhysicalChans) > 0
                    AOPhysicalChans = AOPhysicalChans{1};
                    AOPhysicalChans = obj.filterSupportedChannelIDs(AOPhysicalChans);
                    try
                        obj.addSubsystem(daq.ni.AnalogOutputInfo(device,AOPhysicalChans))
                        obj.RecognizedDevice = true;
                    catch %#ok<CTCH>
                        % Ignore errors. The device will appear in the list
                        % as unrecognized.
                    end
                end
            end
            
            % Does the device support a digital subsystem?
            [bufferSize,~] = daq.ni.NIDAQmx.DAQmxGetDevDILines(device,' ',uint32(0));
            [status,DIPhysicalChans] = daq.ni.NIDAQmx.DAQmxGetDevDILines(device,blanks(bufferSize),uint32(bufferSize));
            daq.ni.utility.throwOrWarnOnStatus(status);
            if ~isempty(DIPhysicalChans)
                % Parse the comma separated list into a cell array of
                % strings.
                DIPhysicalChans = textscan(DIPhysicalChans,[device '/%s'],'Delimiter',',');
                if numel(DIPhysicalChans) > 0
                    DIPhysicalChans = DIPhysicalChans{1};
                    DIPhysicalChans = obj.filterSupportedChannelIDs(DIPhysicalChans);
                end
            end
            [bufferSize,~] = daq.ni.NIDAQmx.DAQmxGetDevDOLines(device,' ',uint32(0));
            [status,DOPhysicalChans] = daq.ni.NIDAQmx.DAQmxGetDevDOLines(device,blanks(bufferSize),uint32(bufferSize));
            daq.ni.utility.throwOrWarnOnStatus(status);
            if ~isempty(DOPhysicalChans)
                % Parse the comma separated list into a cell array of
                % strings.
                DOPhysicalChans = textscan(DOPhysicalChans,[device '/%s'],'Delimiter',',');
                if numel(DOPhysicalChans) > 0
                    DOPhysicalChans = DOPhysicalChans{1};
                    DOPhysicalChans = obj.filterSupportedChannelIDs(DOPhysicalChans);
                end
            end
            if ~isempty(DIPhysicalChans) || ~isempty(DOPhysicalChans)
                try
                    obj.addSubsystem(daq.ni.DigitalIOInfo(device,DIPhysicalChans,DOPhysicalChans))
                    obj.RecognizedDevice = true;
                catch %#ok<CTCH>
                    % Ignore errors. The device will appear in the list
                    % as unrecognized.
                end
            end
            
            % Does the device support counter input?
            [bufferSize,~] = daq.ni.NIDAQmx.DAQmxGetDevCIPhysicalChans(device,' ',uint32(0));
            [status,CIPhysicalChans] = daq.ni.NIDAQmx.DAQmxGetDevCIPhysicalChans(device,blanks(bufferSize),uint32(bufferSize));
            daq.ni.utility.throwOrWarnOnStatus(status);
            if ~isempty(CIPhysicalChans)
                % Parse the comma separated list into a cell array of
                % strings.
                CIPhysicalChans = textscan(CIPhysicalChans,[device '/%s'],'Delimiter',',');
                if numel(CIPhysicalChans) > 0
                    CIPhysicalChans = CIPhysicalChans{1};
                    CIPhysicalChans = obj.filterSupportedChannelIDs(CIPhysicalChans);
                    try
                        obj.addSubsystem(daq.ni.CounterInputInfo(device,CIPhysicalChans))
                        obj.RecognizedDevice = true;
                    catch %#ok<CTCH>
                        % Ignore errors. The device will appear in the list
                        % as unrecognized.
                    end
                end
            end
            
            % Does the device support counter output?
            [bufferSize,~] = daq.ni.NIDAQmx.DAQmxGetDevCOPhysicalChans(device,' ',uint32(0));
            [status,COPhysicalChans] = daq.ni.NIDAQmx.DAQmxGetDevCOPhysicalChans(device,blanks(bufferSize),uint32(bufferSize));
            daq.ni.utility.throwOrWarnOnStatus(status);
            if ~isempty(COPhysicalChans)
                % Parse the comma separated list into a cell array of
                % strings.
                COPhysicalChans = textscan(COPhysicalChans,[device '/%s'],'Delimiter',',');
                if numel(COPhysicalChans) > 0
                    COPhysicalChans = COPhysicalChans{1};
                    COPhysicalChans = obj.filterSupportedChannelIDs(COPhysicalChans);
                    try
                        obj.addSubsystem(daq.ni.CounterOutputInfo(device,COPhysicalChans))
                        obj.RecognizedDevice = true;
                    catch %#ok<CTCH>
                        % Ignore errors. The device will appear in the list
                        % as unrecognized.
                    end
                end
            end
            
            % Get terminals for the device
            obj.Terminals = daq.ni.DeviceInfo.getTerminalsFromDevice(device);
            
        end
        
        function filteredChannelIDs = filterSupportedChannelIDs(obj, channelIDs)  %#ok<INUSL>
            regexpPattern = '^(ai|ao|ctr|port\d+/line)?\d+$';
            irregularIndices = regexpi(channelIDs, regexpPattern);
            
            % Filter unsupported channel IDs
            filteredChannelIDs = channelIDs;
            filteredChannelIDs(cellfun(@isempty, irregularIndices)) = [];
        end
    end
    
    % Hidden methods, which are typically used as friend methods
    methods(Hidden)
        
        function result = getSpecializedFamily(obj) %#ok<MANU>
            result = [];
        end
        
        function [newChannel] = createChannel(obj,...
                session,...         % The daq.Session that this is to be added to
                subsystem,...       % A daq.internal.SubsystemType defining the type of the subsystem to create a channel for on the device
                channelID,...       % A string or numeric containing the ID of the channel to create
                measurementType,... % A string containing the specialized measurement to be used, such as 'Voltage'.
                varargin)           % Any additional parameters passed by the user, to be interpreted by the vendor implementation
            % createChannel is a factory to create channels of the correct
            % type for a standard NI-DAQmx device
            
            specialization = obj.getSpecializedFamily();
            if isempty(specialization)
                channelLocation = char(subsystem) ;
            else
                channelLocation = [specialization '.' char(subsystem)];
            end
            
            switch subsystem
                case daq.internal.SubsystemType.AnalogInput
                    % Convert numeric channel IDs to correct string
                    if isnumeric(channelID)
                        channelID = sprintf('ai%d',channelID);
                    end
                    session.checkIsValidChannelID(obj, channelID, subsystem);
                    
                    newChannel = daq.ni.([channelLocation measurementType 'Channel'])(session,obj,channelID);
                    
                case daq.internal.SubsystemType.AnalogOutput
                    % Convert numeric channel IDs to correct string
                    if isnumeric(channelID)
                        channelID = sprintf('ao%d',channelID);
                    end
                    session.checkIsValidChannelID(obj, channelID, subsystem);
                    
                    newChannel = daq.ni.([channelLocation measurementType 'Channel'])(session,obj,channelID);
                    
                    
                case daq.internal.SubsystemType.DigitalIO
                    
                    % Overwrite channel location for Digital channels.
                    if isempty(specialization)
                        channelLocation = 'Digital';
                    else
                        channelLocation = [specialization '.Digital'];
                    end
                    
                    switch measurementType
                        case 'InputOnly'
                            newChannel = daq.ni.([channelLocation 'InputChannel'])(session,obj,channelID);
                            
                        case 'OutputOnly'
                            newChannel = daq.ni.([channelLocation  'OutputChannel'])(session,obj,channelID);
                            
                        case 'Bidirectional'
                            newChannel = daq.ni.([channelLocation 'BidirectionalChannel'])(session,obj,channelID);
                            
                    end
                    
                case daq.internal.SubsystemType.CounterInput
                    if isnumeric(channelID)
                        channelID = sprintf('ctr%d',channelID);
                    end
                    session.checkIsValidChannelID(obj, channelID, subsystem);
                    
                    newChannel = daq.ni.([channelLocation measurementType 'Channel'])(session,obj,channelID);
                    
                case daq.internal.SubsystemType.CounterOutput
                    if isnumeric(channelID)
                        channelID = sprintf('ctr%d',channelID);
                    end
                    session.checkIsValidChannelID(obj, channelID, subsystem);
                    newChannel = daq.ni.([channelLocation measurementType 'Channel'])(session,obj,channelID);
            end
           
            obj.createChannelHook(session,newChannel)
        end
        
        function createChannelHook(obj,session,newChannel)
            
            % Configure the task for this new channel
            taskHandle = session.getUnreservedTaskHandle(newChannel.GroupName);
            
            % G630578 & G664811 Adding channels when at the maximum sample
            % rate will fail so lower the sample rate before adding
            % channels if needed.
            cachedRate = obj.lowerSampleRateBeforeChannelAddIfNeeded(taskHandle, session);
            
            newChannel.createChannelAndCaptureParameters(taskHandle)
            
            % Restore to the previous rate if needed.
            obj.restorePreviousRateAfterChannelAddIfNeeded(taskHandle,cachedRate);
            
        end
    end
    
    methods (Access=protected,Static)
        function cachedRate = lowerSampleRateBeforeChannelAddIfNeeded(taskHandle, session)
            % In some cases adding a channel causes the current sample rate
            % to be invalid. No error is returned on the add but an error is
            % returned on the next call made for the task.
            
            % Initialize the PreviousRate property as it is used as a flag
            % in the restore function.
            cachedRate = [];
            
            % If the RateLimit has not yet been set there is nothing to do.
            if isempty(session.RateLimit)
                return
            end
            
            if session.RateLimit(2) == 0
                return
            end
            
            % Save the current rate.
            [status, cachedRate] = daq.ni.NIDAQmx.DAQmxGetSampClkRate(...
                taskHandle,...
                double(0));
            
            % G635388 If AO channels are added before AI then RateLimit
            % will not be empty but we cannot query the sample clock rate
            % without at least one AI channel in the task. If this is the
            % case, reset the PreviousRate (which gets set to 0 in the
            % failed call) and then return.
            % Some tasks return a 0 rate. This is also grounds not to
            % lower or remember the rate.
            if cachedRate == 0 || status == daq.ni.NIDAQmx.DAQmxErrorCanNotPerformOpWhenNoChansInTask
                cachedRate = [];
                return
            end
            
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            % Set the sample rate to the lowest available.
            [status] = daq.ni.NIDAQmx.DAQmxSetSampClkRate(...
                taskHandle,...
                session.RateLimitInfo.Min);
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
        
        function restorePreviousRateAfterChannelAddIfNeeded(taskHandle, cachedRate)
            % Get the maximum rate for the task in its current
            % configuration.
            if isempty(cachedRate)
                return;
            end
            
            [status, maxRateForTask] = daq.ni.NIDAQmx.DAQmxGetSampClkMaxRate(...
                taskHandle,...
                double(0));
            % Any error on the Get causes us to simply use the previous
            % rate.
            if status < daq.ni.NIDAQmx.DAQmxSuccess
                maxRateForTask = cachedRate;
            end
            
            % Set the rate to either the previous rate or the maximum rate,
            % whichever is lower.
            try
                [status] = daq.ni.NIDAQmx.DAQmxSetSampClkRate(...
                    taskHandle,...
                    min(cachedRate, maxRateForTask));
                daq.ni.utility.throwOrWarnOnStatus(status);
            catch %#ok<CTCH>
                % For digital channels, DAQmxGetSampClkMaxRate returns an
                % invalid maximum rate of zero
                [status] = daq.ni.NIDAQmx.DAQmxSetSampClkRate(...
                    taskHandle, ...
                    cachedRate);
                daq.ni.utility.throwOrWarnOnStatus(status);
            end
        end
    end
    
    methods(Hidden)
        % These methods can be over-ridden by Device Specializations.
        function  rateLimit = getRateLimitFromDataSheet(obj,...
                ~)  %#ok<INUSD>
            rateLimit =[];
        end
        
        function supportedRates = getOutputUpdateRatesFromDataSheet(obj) %#ok<MANU>
            supportedRates = [];
        end
    end
    methods( Hidden,Static)
        function terminals = getTerminalsFromDevice(device)
            terminals{1} = '';
            [termListSize,~] = daq.ni.NIDAQmx.DAQmxGetDevTerminals(device, char(0), uint32(0));
            [status, termList] = daq.ni.NIDAQmx.DAQmxGetDevTerminals(device, blanks(termListSize), uint32(termListSize));
            
            % G735228: USB-TC01: Device is not recognizable
            % This device does not support Terminals, and returns DAQmxErrorDevAbsentOrUnavailable_Routing
            %
            if status == daq.ni.NIDAQmx.DAQmxErrorDevAbsentOrUnavailable_Routing % Error returned by USB TC-01
                return
            end
            daq.ni.utility.throwOrWarnOnStatus(status)
            if ~isempty(termList)
                terminalList = textscan(termList,'%s','Delimiter',',');
                terminals = terminalList{1};
            end
            
            % remove the '/' when displaying terminals
            terminals = regexprep(terminals,'/','','once');
            
            % remove terminals which belong to a particular subsystem
            terminals = terminals(cell2mat(cellfun(@(x) size(strfind(x,'/'),2) == 1,terminals,'UniformOutput',0)));
        end
        
    end
    
    properties ( Access = protected, Hidden )
        DeviceClass;
    end
end
