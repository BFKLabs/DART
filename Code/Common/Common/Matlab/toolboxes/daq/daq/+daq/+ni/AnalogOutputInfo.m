classdef (Hidden) AnalogOutputInfo < daq.AnalogOutputInfo
    %AnalogOutputInfo analog output subsystem info for National Instruments devices.
    %
    %    This class represents a analog output subsystem on devices by
    %    National Instruments.
    %
    %    This undocumented class may be removed in a future release.
   
    % Copyright 2010-2012 The MathWorks, Inc.
    
    properties
        %TerminalConfigsAvailable An array of representations of the
        %terminal configs that this subsystem supports.
        TerminalConfigsAvailable
    end
    
    methods
        function obj = AnalogOutputInfo(device,AOPhysicalChans)
            
            
            % Get measurementTypesAvailable and rangesAvailable
            measurementTypesAvailable = cell(0,0);
            defaultMeasurementType = [];
            rangesAvailable = daq.Range.empty();
            
            % Get voltage ranges Available
            [arraysize,~] = daq.ni.NIDAQmx.DAQmxGetDevAOVoltageRngs(device, zeros(1,1), uint32(0)); 
            if arraysize ~= 0
                measurementTypesAvailable{end + 1} = 'Voltage';
                if isempty(defaultMeasurementType)
                    defaultMeasurementType = 'Voltage';
                end
                [status,AOVoltageRngs] = daq.ni.NIDAQmx.DAQmxGetDevAOVoltageRngs(device, zeros(arraysize,1), uint32(arraysize));            
                daq.ni.utility.throwOrWarnOnStatus(status);
                AOVoltageRngs = reshape(AOVoltageRngs,2,arraysize/2)';
                for iRange = 1:size(AOVoltageRngs,1)
                    rangesAvailable(end + 1) = daq.Range(AOVoltageRngs(iRange,1),AOVoltageRngs(iRange,2),'Volts'); %#ok<AGROW>
                end
            end
            
            % Get current ranges Available
            [arraysize,~] = daq.ni.NIDAQmx.DAQmxGetDevAOCurrentRngs(device, zeros(1,1), uint32(0));           
            if arraysize ~= 0
                measurementTypesAvailable{end + 1} = 'Current';
                if isempty(defaultMeasurementType)
                    defaultMeasurementType = 'Current';
                end
                [status,AOCurrentRngs] = daq.ni.NIDAQmx.DAQmxGetDevAOCurrentRngs(device, zeros(arraysize,1), uint32(arraysize));            
                daq.ni.utility.throwOrWarnOnStatus(status);
                AOCurrentRngs = reshape(AOCurrentRngs,2,arraysize/2)';
                for iRange = 1:size(AOCurrentRngs,1)
                    rangesAvailable(end + 1) = daq.Range(AOCurrentRngs(iRange,1),AOCurrentRngs(iRange,2),'A'); %#ok<AGROW>
                end
            end

            % Get rateLimitInfo
            [status,AOMinRate] = daq.ni.NIDAQmx.DAQmxGetDevAOMinRate(device,double(0));
            %Check if it is a on-demand channel only
            if(status == daq.ni.NIDAQmx.DAQmxErrorAttrNotSupported)
                AOMinRate = 0;                
            else
                daq.ni.utility.throwOrWarnOnStatus(status);
            end
            
            [status,AOMaxRate] = daq.ni.NIDAQmx.DAQmxGetDevAOMaxRate(device,double(0));
            %Check if it is a on-demand channel only
            if(status == daq.ni.NIDAQmx.DAQmxErrorAttrNotSupported)
                AOMaxRate = 0;
            else
                daq.ni.utility.throwOrWarnOnStatus(status);
            end
            
            % G635448 If the device reports that it's minimum rate is zero
            % force the minimum allowed by any clocked subsystem.
            % Make sure the minimum remains below the maximum.
            AOMinRate = min(AOMaxRate, max(AOMinRate,daq.ClockedSubsystemInfo.MinimumSampleRate));
        
            rateLimitInfo = daq.internal.ParameterLimit(AOMinRate,AOMaxRate);
                
            % Get nativeDataType,...
            nativeDataType = 'double';

            channelToTest = [device '/' AOPhysicalChans{1}];
            
            % These require a task to retrieve, since they are channel
            % based
            [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
            daq.ni.utility.throwOrWarnOnStatus(status);
            try
                % Create a channel in the task to use
                % There's a number of possible failure modes here:
                %   1. Might not support voltage or current (add new types
                %      as support is added)
                %   2. Range(1) might not be valid for channel
                if any(strcmp('Voltage', measurementTypesAvailable))
                    [status] = daq.ni.NIDAQmx.DAQmxCreateAOVoltageChan (...
                        taskHandle,...                      % The task handle
                        channelToTest,...                   % physicalChannel
                        char(0),...                         % nameToAssignToChannel
                        rangesAvailable(1).Min,...          % minVal
                        rangesAvailable(1).Max,...          % maxVal
                        daq.ni.NIDAQmx.DAQmx_Val_Volts,...  % units
                        char(0));                           % customScaleName);
                    daq.ni.utility.throwOrWarnOnStatus(status);
                elseif any(strcmp('Current', measurementTypesAvailable))
                    [status] = daq.ni.NIDAQmx.DAQmxCreateAOCurrentChan (...
                        taskHandle,...                      % The task handle
                        channelToTest,...                   % physicalChannel
                        char(0),...                         % nameToAssignToChannel
                        rangesAvailable(1).Min,...          % minVal
                        rangesAvailable(1).Max,...          % maxVal
                        daq.ni.NIDAQmx.DAQmx_Val_Amps,...   % units
                        char(0));                           % customScaleName);
                    daq.ni.utility.throwOrWarnOnStatus(status);
                else
                    % The device does not have any supported AO channel type.
                    % Do nothing here. The call to get resolution will fail
                    % below and an error will be thrown.
                    % At R2010b release the only AO channel type
                    % not supported is DAQmxCreateAOFuncGenChan and this
                    % channel exists only on ELVIS II products, which are
                    % not targeted for R2010b.
                end
                
                % Get resolution
                [status,AOResolution] = daq.ni.NIDAQmx.DAQmxGetAOResolution(taskHandle,...
                                                channelToTest,...
                                                double(0));
                daq.ni.utility.throwOrWarnOnStatus(status);
                resolution = AOResolution;
                
                onDemandOperationsSupported = ....
                    daq.ni.NICommonDeviceInfoAttrib.detectOnDemandSupport(taskHandle);
            catch e
                % Make sure the task is cleaned up
                [~] = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
                rethrow(e)
            end
            status = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
            daq.ni.utility.throwOrWarnOnStatus(status);
				
            outputTypesAvailable  =  daq.TerminalConfig.empty();
            [status,AOTermCfgs] = daq.ni.NIDAQmx.DAQmxGetPhysicalChanAOTermCfgs(channelToTest, int32(0));            
            daq.ni.utility.throwOrWarnOnStatus(status);
             if bitand(uint32(AOTermCfgs),uint32(daq.ni.NIDAQmx.DAQmx_Val_Bit_TermCfg_RSE))
                outputTypesAvailable(end + 1) = daq.TerminalConfig.SingleEnded;
            end
            
            if bitand(uint32(AOTermCfgs),uint32(daq.ni.NIDAQmx.DAQmx_Val_Bit_TermCfg_NRSE))
                outputTypesAvailable(end + 1) = daq.TerminalConfig.SingleEndedNonReferenced;
            end
            
            if bitand(uint32(AOTermCfgs),uint32(daq.ni.NIDAQmx.DAQmx_Val_Bit_TermCfg_Diff))
                outputTypesAvailable(end + 1) = daq.TerminalConfig.Differential;
            end
            
            if bitand(uint32(AOTermCfgs),uint32(daq.ni.NIDAQmx.DAQmx_Val_Bit_TermCfg_PseudoDIFF))
                outputTypesAvailable(end + 1) = daq.TerminalConfig.PseudoDifferential;
            end
            
            obj@daq.AnalogOutputInfo(...
                measurementTypesAvailable,...
                defaultMeasurementType,...
                nativeDataType,...               
                AOPhysicalChans,...
                rateLimitInfo,...
                rangesAvailable,...
                daq.Range.empty, ...
                daq.Range.empty, ...
                daq.Range.empty, ...
                resolution,...
                outputTypesAvailable,...
                onDemandOperationsSupported);
        end
    end    
    
    % Property access methods
    methods
        function result = get.TerminalConfigsAvailable(obj)
            % Return information in the more MATLAB friendly format
            result = obj.TerminalConfigsAvailableInfo.toCellArray();
        end
    end
end

