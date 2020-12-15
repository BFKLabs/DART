classdef (Hidden) CounterOutputInfo < daq.CounterOutputInfo
    %CounterOutputInfo Counter output subsystem info for National
    %Instruments devices.
    %
    %    This class represents a counter output subsystem on devices by
    %    National Instruments.
    %
    %    This undocumented class may be removed in a future release.
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods(Hidden)
        function obj = CounterOutputInfo(device,COPhysicalChans)
            
            % Get measurementTypesAvailable and rangesAvailable
            measurementTypesAvailable = cell(0,0);
            defaultMeasurementType = [];
            onDemandOperationsSupported = true;
            channelToTest = [device '/' COPhysicalChans{1}];
            
            % Detect PulseGeneration capability
            [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
            daq.ni.utility.throwOrWarnOnStatus(status);
            [status] = daq.ni.NIDAQmx.DAQmxCreateCOPulseChanFreq (...
                taskHandle,...                          % The task handle
                channelToTest,...                       % physicalChannel
                char(0),...                             % nameToAssignToChannel
                daq.ni.NIDAQmx.DAQmx_Val_Hz,...         % units
                daq.ni.NIDAQmx.DAQmx_Val_Low,...        % idle state
                0,...                                   % initial delay
                1,...                                   % frequency
                0.5);                                   % duty cycle
            if status == 0
                measurementTypesAvailable{end + 1} = 'PulseGeneration';
                defaultMeasurementType = 'PulseGeneration';
                
               onDemandOperationsSupported = ....
                    daq.ni.NICommonDeviceInfoAttrib.detectOnDemandSupport(taskHandle);
            end
            status = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
            daq.ni.utility.throwOrWarnOnStatus(status);

            % Get nativeDataType,...
            nativeDataType = 'double';
                        
            % Get the rate limit information
            COMinRate = daq.ClockedSubsystemInfo.MinimumSampleRate;

            [status,COMaxChanRate] = daq.ni.NIDAQmx.DAQmxGetDevCOMaxTimebase(device,double(0));
            daq.ni.utility.throwOrWarnOnStatus(status);
            rateLimitInfo = daq.internal.ParameterLimit(COMinRate,COMaxChanRate);

            % Get the resolution
            [status, resolution] = daq.ni.NIDAQmx.DAQmxGetDevCOMaxSize(device, uint32(0));
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            % Call the superclass constructor
            obj@daq.CounterOutputInfo(...
                measurementTypesAvailable,...   % measurement types specified by the cell array of strings
                defaultMeasurementType,...      % default measurement type
                nativeDataType,...              % a native data type (MATLAB type string)                
                COPhysicalChans,...             % channel names supported
                rateLimitInfo,...               % supports rates defined by a daq.internal.ParameterLimit object
                resolution,...                  % number of bits of resolution
                onDemandOperationsSupported);
        end
    end 
end

