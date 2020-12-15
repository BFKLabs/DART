classdef (Hidden) DigitalIOInfo < daq.DigitalIOInfo
    %DigitalIOInfo Digital IO subsystem info for National Instruments
    %devices.
    %
    %    This class represents a Digital IO subsystem on devices by
    %    National Instruments.
    %
    %    This undocumented class may be removed in a future release.
    
    % Copyright 2012 The MathWorks, Inc.
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods(Hidden)
        function obj = DigitalIOInfo(device,DIPhysicalChans,DOPhysicalChans)
            
            % Get measurementTypesAvailable and rangesAvailable
            measurementTypesAvailable = cell(0,0);
            defaultMeasurementType = [];
            onDemandOperationsSupported = true;
            
            % Detect Digital Input capability
            if ~isempty(DIPhysicalChans)
                channelToTest = [device '/' DIPhysicalChans{1}];
                [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
                daq.ni.utility.throwOrWarnOnStatus(status);
                [status] = daq.ni.NIDAQmx.DAQmxCreateDIChan (...
                    taskHandle,...                          % The task handle
                    channelToTest,...                       % physicalChannel
                    char(0),...                             % nameToAssignToChannel
                    daq.ni.NIDAQmx.DAQmx_Val_ChanPerLine);  % lineGrouping
                if status == 0
                    measurementTypesAvailable{end + 1} = 'InputOnly';
                    defaultMeasurementType = 'InputOnly';
                    onDemandOperationsSupported = ...
                        daq.ni.NICommonDeviceInfoAttrib.detectOnDemandSupport(taskHandle);
                end
                
                status = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
                daq.ni.utility.throwOrWarnOnStatus(status);
            end
            
            % Detect Digital output capability
            if ~isempty(DOPhysicalChans)
                channelToTest = [device '/' DOPhysicalChans{1}];
                [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
                daq.ni.utility.throwOrWarnOnStatus(status);
                [status] = daq.ni.NIDAQmx.DAQmxCreateDOChan (...
                    taskHandle,...                          % The task handle
                    channelToTest,...                       % physicalChannel
                    char(0),...                             % nameToAssignToChannel
                    daq.ni.NIDAQmx.DAQmx_Val_ChanPerLine);  % lineGrouping
                if status == daq.ni.NIDAQmx.DAQmxSuccess
                    measurementTypesAvailable{end + 1} = 'OutputOnly';
                    if isempty(defaultMeasurementType)
                        defaultMeasurementType = 'OutputOnly';
                        onDemandOperationsSupported = ...
                            daq.ni.NICommonDeviceInfoAttrib.detectOnDemandSupport(taskHandle);
                    end
                end
                
                status = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
                daq.ni.utility.throwOrWarnOnStatus(status);
            end
            
            if numel(measurementTypesAvailable) == 2 &&...
                    ~isempty(intersect(DIPhysicalChans, DOPhysicalChans))
                measurementTypesAvailable{end + 1} = 'Bidirectional';
            end
            
            % Get nativeDataType,...
            nativeDataType = 'double';
            
            % Get the rate limit information
            DIOMinRate = daq.ClockedSubsystemInfo.MinimumSampleRate;
            
            % Make sure to check return status since not all digital
            % subsystems will support both input and output directions
            [statusDI,DIMaxChanRate] = daq.ni.NIDAQmx.DAQmxGetDevDIMaxRate(device,double(0));
            [statusDO,DOMaxChanRate] = daq.ni.NIDAQmx.DAQmxGetDevDOMaxRate(device,double(0));
            if statusDI == daq.ni.NIDAQmx.DAQmxSuccess &&...
                    statusDO == daq.ni.NIDAQmx.DAQmxSuccess
                DIOMaxChanRate = min(DIMaxChanRate,DOMaxChanRate);
            elseif statusDI == daq.ni.NIDAQmx.DAQmxSuccess
                DIOMaxChanRate = DIMaxChanRate;
            elseif statusDO == daq.ni.NIDAQmx.DAQmxSuccess
                DIOMaxChanRate = DOMaxChanRate;
            end
            
            % Some devices families (like M-Series) do not support an
            % internal sample clock
            %
            try
                [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                if ~isempty(DIPhysicalChans)
                    channelToTest = [device '/' DIPhysicalChans{1}];
                    [status] = daq.ni.NIDAQmx.DAQmxCreateDIChan (...
                        taskHandle,...                          % The task handle
                        channelToTest,...                       % physicalChannel
                        char(0),...                             % nameToAssignToChannel
                        daq.ni.NIDAQmx.DAQmx_Val_ChanPerLine);  % lineGrouping
                    daq.ni.utility.throwOrWarnOnStatus(status);
                else
                    channelToTest = [device '/' DOPhysicalChans{1}];
                    [status] = daq.ni.NIDAQmx.DAQmxCreateDOChan (...
                        taskHandle,...                          % The task handle
                        channelToTest,...                       % physicalChannel
                        char(0),...                             % nameToAssignToChannel
                        daq.ni.NIDAQmx.DAQmx_Val_ChanPerLine);  % lineGrouping
                    daq.ni.utility.throwOrWarnOnStatus(status);
                end
                
                [status] = daq.ni.NIDAQmx.DAQmxCfgSampClkTiming(...
                    taskHandle,...                       % taskHandle,
                    'OnboardClock',...                   % source
                    DIOMaxChanRate,...                   % rate
                    daq.ni.NIDAQmx.DAQmx_Val_Rising,...  % activeEdge
                    daq.ni.NIDAQmx.DAQmx_Val_FiniteSamps,...  % sampleMode
                    uint64(1));
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                [status, ~] = daq.ni.NIDAQmx.DAQmxGetSampClkRate(...
                    taskHandle,double(0));
                daq.ni.utility.throwOrWarnOnStatus(status);
            catch  %#ok<CTCH>
                if status == daq.ni.NIDAQmx.DAQmxErrorBufferedOpsNotSupportedInSpecdSlotForCDAQ
                    sWarningBacktrace = warning('off','backtrace');
                    warning(message('nidaq:ni:NIDAQmxError201107',device));
                    warning(sWarningBacktrace);
                end
            end
            
            status = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            %Check if it is a on-demand channel only
            if statusDI ~= daq.ni.NIDAQmx.DAQmxSuccess &&...
                    statusDO ~= daq.ni.NIDAQmx.DAQmxSuccess
                DIOMinRate = 0;
                DIOMaxChanRate = 0;
            else
                daq.ni.utility.throwOrWarnOnStatus(status);
            end
            
            DIOMinRate = min(DIOMaxChanRate, max(DIOMinRate,daq.ClockedSubsystemInfo.MinimumSampleRate));
            rateLimitInfo = daq.internal.ParameterLimit(DIOMinRate,DIOMaxChanRate);
            
            % Call the superclass constructor
            obj@daq.DigitalIOInfo(...
                measurementTypesAvailable,...           % measurement types specified by the cell array of strings
                defaultMeasurementType,...              % default measurement type
                nativeDataType,...                      % a native data type (MATLAB type string)
                DIPhysicalChans,...                     % channel Names supported
                DOPhysicalChans,...                     % channel Names supported
                rateLimitInfo,...                       % supports rates defined by a daq.internal.ParameterLimit object
                onDemandOperationsSupported);           % on demand operations supported
        end
    end
end

