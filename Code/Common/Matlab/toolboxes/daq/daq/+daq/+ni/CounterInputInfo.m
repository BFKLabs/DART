classdef (Hidden) CounterInputInfo < daq.CounterInputInfo
    %CounterInputInfo Counter input subsystem info for National Instruments
    %devices.
    %
    %    This class represents a counter input subsystem on devices by
    %    National Instruments.
    %
    %    This undocumented class may be removed in a future release.
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods(Hidden)
        function obj = CounterInputInfo(device,CIPhysicalChans)
            
            % Get measurementTypesAvailable and rangesAvailable
            measurementTypesAvailable = cell(0,0);
            defaultMeasurementType = [];
            
            activeEdgesAvailable = cell(0,0);
            defaultActiveEdge = [];
            
            % On-demand support could be different depending on the
            % measurement type ( E-series counters). So maintaining different
            % properties for all the measurement types.
            onDemandOperationsSupportedEdgeCount    = true;
            onDemandOperationsSupportedFrequency    = true;
            onDemandOperationsSupportedPosition     = true;
            onDemandOperationsSupportedPulseWidth   = true;
            
            channelToTest = [device '/' CIPhysicalChans{1}];
            
            % Detect Rising EdgeCount capability
            [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
            daq.ni.utility.throwOrWarnOnStatus(status);
            [status] = daq.ni.NIDAQmx.DAQmxCreateCICountEdgesChan (...
                taskHandle,...                          % The task handle
                channelToTest,...                       % physicalChannel
                char(0),...                             % nameToAssignToChannel
                daq.ni.NIDAQmx.DAQmx_Val_Rising,...     % edge
                uint32(0),...                           % initial count
                daq.ni.NIDAQmx.DAQmx_Val_CountUp);      % countDirection
            if status == 0
                measurementTypesAvailable{end + 1} = 'EdgeCount';
                defaultMeasurementType = 'EdgeCount';
                activeEdgesAvailable{end+1} = 'Rising';
                defaultActiveEdge = 'Rising';
                onDemandOperationsSupportedEdgeCount = ...
                    daq.ni.NICommonDeviceInfoAttrib.detectOnDemandSupport(taskHandle);
            end
            
            status = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            % Detect Falling EdgeCount capability
            [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
            daq.ni.utility.throwOrWarnOnStatus(status);
            [status] = daq.ni.NIDAQmx.DAQmxCreateCICountEdgesChan (...
                taskHandle,...                          % The task handle
                channelToTest,...                       % physicalChannel
                char(0),...                             % nameToAssignToChannel
                daq.ni.NIDAQmx.DAQmx_Val_Falling,...     % edge
                uint32(0),...                           % initial count
                daq.ni.NIDAQmx.DAQmx_Val_CountUp);      % countDirection
            if status == 0
                if ~(any(strcmp('EdgeCount', measurementTypesAvailable)))
                    measurementTypesAvailable{end + 1} = 'EdgeCount';
                end
                defaultMeasurementType = 'EdgeCount';
                activeEdgesAvailable{end+1} = 'Falling';
                if isempty(defaultActiveEdge)
                    defaultActiveEdge = 'Falling';
                end
                onDemandOperationsSupportedEdgeCount = ...
                    daq.ni.NICommonDeviceInfoAttrib.detectOnDemandSupport(taskHandle);
            end
            
            status = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            % Detect PulseWidth capability
            minmaxValues = {...
                [1e-7, 1],...     % Default
                [1e-7, 0.8],...   % PCI-6110
                [1e-6, 0.5],...
                [1e-6, 0.1]...    % Fall back
                };
            
            for i = 1:numel(minmaxValues)
                defaultMinMaxExpectedPulseWidth = minmaxValues{i};
                
                [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
                daq.ni.utility.throwOrWarnOnStatus(status);
                [status] = daq.ni.NIDAQmx.DAQmxCreateCIPulseWidthChan (...
                    taskHandle,...                              % The task handle
                    channelToTest,...                           % physicalChannel
                    char(0),...                                 % nameToAssignToChannel
                    defaultMinMaxExpectedPulseWidth(1),...      % minimum value
                    defaultMinMaxExpectedPulseWidth(2),...      % maximum value
                    daq.ni.NIDAQmx.DAQmx_Val_Seconds,...          % units
                    daq.ni.NIDAQmx.DAQmx_Val_Rising,...         % starting edge
                    char(0));                                   % custom scale name
                if status == daq.ni.NIDAQmx.DAQmxSuccess
                    BufferSize = 64;
                    terminalName = blanks(BufferSize);
                    [status, terminalName] = daq.ni.NIDAQmx.DAQmxGetCIPulseWidthTerm(...
                        taskHandle,...                          % The task handle
                        channelToTest,...                       % physicalChannel
                        terminalName,...                        % buffer
                        uint32(BufferSize));                    %#ok<NASGU> % buffer size
                    if status == daq.ni.NIDAQmx.DAQmxSuccess
                        measurementTypesAvailable{end + 1} = 'PulseWidth';  %#ok<AGROW>
                        if isempty(defaultMeasurementType)
                            defaultMeasurementType = 'PulseWidth';
                        end
                        onDemandOperationsSupportedPulseWidth = ...
                            daq.ni.NICommonDeviceInfoAttrib.detectOnDemandSupport(taskHandle);
                        status = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
                        daq.ni.utility.throwOrWarnOnStatus(status);
                        break;
                    end
                end
                
                status = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
                daq.ni.utility.throwOrWarnOnStatus(status);
            end
            
            % Detect Frequency capability
            minmaxValues = {...
                [1, 10e6],...   % Default
                [2, 10e6],...   % PCI-6110
                [2, 1e6],...
                [2, 100]...     % Fall back
                };
            
            for i = 1:numel(minmaxValues)
                defaultMinMaxExpectedFrequency = minmaxValues{i};
                [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
                daq.ni.utility.throwOrWarnOnStatus(status);
                [status] = daq.ni.NIDAQmx.DAQmxCreateCIFreqChan (...
                    taskHandle,...                          % The task handle
                    channelToTest,...                       % physicalChannel
                    char(0),...                             % nameToAssignToChannel
                    defaultMinMaxExpectedFrequency(1),...   % minimum value
                    defaultMinMaxExpectedFrequency(2),...   % maximum value
                    daq.ni.NIDAQmx.DAQmx_Val_Hz,...         % units
                    daq.ni.NIDAQmx.DAQmx_Val_Rising,...     % starting edge
                    daq.ni.NIDAQmx.DAQmx_Val_LowFreq1Ctr,...% measurement method
                    double(0),...                           % measurement time
                    uint32(0),...                           % divisor
                    char(0));                               % custom scale name
                if status == daq.ni.NIDAQmx.DAQmxSuccess
                    BufferSize = 64;
                    terminalName = blanks(BufferSize);
                    [status, terminalName] = daq.ni.NIDAQmx.DAQmxGetCIFreqTerm(...
                        taskHandle,...                          % The task handle
                        channelToTest,...                       % physicalChannel
                        terminalName,...                        % buffer
                        uint32(BufferSize));                    %#ok<NASGU> % buffer size
                    if status == daq.ni.NIDAQmx.DAQmxSuccess;
                        measurementTypesAvailable{end + 1} = 'Frequency'; %#ok<AGROW>
                        if isempty(defaultMeasurementType)
                            defaultMeasurementType = 'Frequency';
                        end
                        onDemandOperationsSupportedFrequency = ...
                            daq.ni.NICommonDeviceInfoAttrib.detectOnDemandSupport(taskHandle);
                        status = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
                        daq.ni.utility.throwOrWarnOnStatus(status);
                        break;
                    end
                end
                
                status = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
                daq.ni.utility.throwOrWarnOnStatus(status);
            end
            
            % Detect Position capability
            
            [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
            daq.ni.utility.throwOrWarnOnStatus(status);
            [status] = daq.ni.NIDAQmx.DAQmxCreateCILinEncoderChan (...
                taskHandle,...                          % The task handle
                channelToTest,...                       % physicalChannel
                char(0),...                             % nameToAssignToChannel
                daq.ni.NIDAQmx.DAQmx_Val_X1,...         % decoding type
                uint32(false),...                       % enable z-indexing
                double(0),...                           % initial z-index value
                daq.ni.NIDAQmx.DAQmx_Val_AHighBHigh,... % z-index phase
                daq.ni.NIDAQmx.DAQmx_Val_Ticks,...      % units
                double(1),...                           % distance per pulse
                double(0),...                           % initial position
                char(0));                               % custom scale name
            if status == 0
                measurementTypesAvailable{end + 1} = 'Position';
                if isempty(defaultMeasurementType)
                    defaultMeasurementType = 'Position';
                end
                onDemandOperationsSupportedPosition = ...
                    daq.ni.NICommonDeviceInfoAttrib.detectOnDemandSupport(taskHandle);
            end
            
            status = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            % Get nativeDataType,...
            nativeDataType = 'double';
            
  
            
            % Get the rate limit information
            CIMinRate = daq.ClockedSubsystemInfo.MinimumSampleRate;
            
            [status,CIMaxChanRate] = daq.ni.NIDAQmx.DAQmxGetDevCIMaxTimebase(device,double(0));
            
            %Check if it is a on-demand channel only
            if(status == daq.ni.NIDAQmx.DAQmxErrorAttrNotSupported)
                CIMinRate = 0;
                CIMaxChanRate = 0;
            else
                daq.ni.utility.throwOrWarnOnStatus(status);
            end
            
            CIMinRate = min(CIMaxChanRate, max(CIMinRate,daq.ClockedSubsystemInfo.MinimumSampleRate));
            
            rateLimitInfo = daq.internal.ParameterLimit(CIMinRate,CIMaxChanRate);
            
            % Get the resolution
            [status, resolution] = daq.ni.NIDAQmx.DAQmxGetDevCIMaxSize(device, uint32(0));
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            % Call the superclass constructor
            obj@daq.CounterInputInfo(...
                measurementTypesAvailable,...           % measurement types specified by the cell array of strings
                defaultMeasurementType,...              % default measurement type
                nativeDataType,...                      % a native data type (MATLAB type string)
                CIPhysicalChans,...                     % channel Names supported
                rateLimitInfo,...                       % supports rates defined by a daq.internal.ParameterLimit object
                resolution,...                          % number of bits of resolution
                activeEdgesAvailable,...                % active edges specified by the cell array of strings
                defaultActiveEdge,...                   % default active edge to used in EdgeCount mode
                defaultMinMaxExpectedFrequency,...      % default minmax expected frequency values
                defaultMinMaxExpectedPulseWidth,...     % default minmax expected pulse width values
                onDemandOperationsSupportedEdgeCount,...% on-demand support flag for edge count counter input channels
                onDemandOperationsSupportedFrequency,...% on-demand support flag for frequency counter input channels
                onDemandOperationsSupportedPosition,... % on-demand support flag for position counter input channels
                onDemandOperationsSupportedPulseWidth); % on-demand support flag for pulse width counter input channels
        end
    end  
end

