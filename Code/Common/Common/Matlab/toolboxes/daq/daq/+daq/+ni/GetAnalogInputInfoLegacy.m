classdef (Hidden) GetAnalogInputInfoLegacy
    %GetAnalogInputInfoLegacy 
    %
    %    This class queries the device for properties needed by the analog
    %    subsystem on devices by National Instruments as done by the Legacy 
    %    interface.
    %
    %    This undocumented class may be removed in a future release.
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor

	methods(Hidden)
	
        function obj = GetAnalogInputInfoLegacy(channelToTest)
            obj.ChannelToTest = channelToTest;
        end
        
        function detectVoltageChannelAndGetRanges(obj,AnalogInput)
		
			taskHandle = obj.createTaskandDefaultVoltageChannel();
            
            % start at one micro volt (unlikely a card would go that low).  See
            % geck 290864 for more info on this "magic" number.
            testValue = 1e-6;
            prevMaxRate = 0;
            prevMinRate = 0;
            
            while(true)
                
                status = daq.ni.NIDAQmx.DAQmxSetAIMax(taskHandle,obj.ChannelToTest, testValue);
                if ( status == daq.ni.NIDAQmx.DAQmxErrorInvalidAttributeValue)  || (status == daq.ni.NIDAQmx.DAQmxErrorAttributeNotSupportedInTaskContext)
                    break;
                else
                    daq.ni.utility.throwOrWarnOnStatus(status);
                end
                
                [status,maxRate] = daq.ni.NIDAQmx.DAQmxGetAIMax(taskHandle,obj.ChannelToTest, double(0));
                if ( status == daq.ni.NIDAQmx.DAQmxErrorInvalidAttributeValue)  || (status == daq.ni.NIDAQmx.DAQmxErrorAttributeNotSupportedInTaskContext)
                    break;
                else
                    daq.ni.utility.throwOrWarnOnStatus(status);
                end
                
                status = daq.ni.NIDAQmx.DAQmxSetAIMin(taskHandle,obj.ChannelToTest, -1  * testValue);
                if ( status == daq.ni.NIDAQmx.DAQmxErrorInvalidAttributeValue)  || (status == daq.ni.NIDAQmx.DAQmxErrorAttributeNotSupportedInTaskContext)
                    break;
                else
                    daq.ni.utility.throwOrWarnOnStatus(status);
                end
                
                [status,minRate] = daq.ni.NIDAQmx.DAQmxGetAIMin(taskHandle,obj.ChannelToTest, double(0));
                if ( status == daq.ni.NIDAQmx.DAQmxErrorInvalidAttributeValue)  || (status == daq.ni.NIDAQmx.DAQmxErrorAttributeNotSupportedInTaskContext)
                    break;
                else
                    daq.ni.utility.throwOrWarnOnStatus(status);
                end
                
                if ( maxRate ~= prevMaxRate) && (minRate ~= prevMinRate)
                     AnalogInput.superSetOfRangesAvailable(end + 1) = daq.Range(minRate,maxRate,'Volts'); 
                end
                
                prevMaxRate = maxRate;
                prevMinRate = minRate;
                
                %Increase the test value by 1% for next iteration
                testValue = testValue * 1.1;
            end
            
            if(~isempty(AnalogInput.superSetOfRangesAvailable))
                AnalogInput.measurementTypesAvailable{end + 1} = 'Voltage';
                if isempty(AnalogInput.defaultMeasurementType)
                    AnalogInput.defaultMeasurementType = 'Voltage';
                end
            end
                      
            status = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
            daq.ni.utility.throwOrWarnOnStatus(status);
		end
		
		function getRateLimitInfo(obj,AnalogInput)
            taskHandle = obj.createTaskandDefaultVoltageChannel();
            
            AIMinRate = 0;
            [status,AIMaxSingleChanRate] = daq.ni.NIDAQmx.DAQmxGetSampClkMaxRate(taskHandle,double(0));
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            AIMinRate = min(AIMaxSingleChanRate, max(AIMinRate,AnalogInput.minimumSampleRate));
            
			AnalogInput.rateLimitInfo = daq.internal.ParameterLimit(AIMinRate,AIMaxSingleChanRate); 
            
            status = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
            daq.ni.utility.throwOrWarnOnStatus(status);
		end
		
		function getSampleType(obj,AnalogInput)
           taskHandle = obj.createTaskandDefaultVoltageChannel();
			
           % Simultaneous acquisition/ SS&H devices don't have convert clocks, so this will give an error
            [ status, ~] = daq.ni.NIDAQmx.DAQmxGetAIConvRate(taskHandle, double(0));
            if( status == daq.ni.NIDAQmx.DAQmxErrorAttributeNotSupportedInTaskContext )
               AnalogInput.sampleType = daq.SampleType.Simultaneous;
            else
                AnalogInput.sampleType = daq.SampleType.Scanning;
            end
            
           status = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
           daq.ni.utility.throwOrWarnOnStatus(status);
		end
		
		function getAvailableCouplings(obj,AnalogInput)
			
			taskHandle = obj.createTaskandDefaultVoltageChannel();
			       
            if obj.isCapableOfCouplingMode(taskHandle, daq.ni.NIDAQmx.DAQmx_Val_DC)
                AnalogInput.couplingsAvailable(end + 1) = daq.Coupling.DC;
            end
            
            if obj.isCapableOfCouplingMode(taskHandle, daq.ni.NIDAQmx.DAQmx_Val_AC)
                AnalogInput.couplingsAvailable(end + 1) = daq.Coupling.AC;
            end
		
            status = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
            daq.ni.utility.throwOrWarnOnStatus(status);
			
		end
        
        function getAvailableTerminalConfigs(obj,AnalogInput)
            taskHandle = obj.createTaskandDefaultVoltageChannel();
            
            if obj.isCapableOfInputType(taskHandle,...
                      daq.ni.utility.DAQToNI(daq.TerminalConfig.SingleEnded))
                AnalogInput.terminalConfigsAvailable(end+1) = daq.TerminalConfig.SingleEnded;
            end
            
            if obj.isCapableOfInputType(taskHandle,...
                    daq.ni.utility.DAQToNI(daq.TerminalConfig.SingleEndedNonReferenced))
                AnalogInput.terminalConfigsAvailable(end+1) = daq.TerminalConfig.SingleEndedNonReferenced;
            end
            
            if obj.isCapableOfInputType(taskHandle,...
                    daq.ni.utility.DAQToNI(daq.TerminalConfig.Differential))
                AnalogInput.terminalConfigsAvailable(end+1) = daq.TerminalConfig.Differential;
            end
            
            if obj.isCapableOfInputType(taskHandle,...
                     daq.ni.utility.DAQToNI(daq.TerminalConfig.PseudoDifferential))
                AnalogInput.terminalConfigsAvailable(end+1) = daq.TerminalConfig.PseudoDifferential;
            end
            
            status = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
            daq.ni.utility.throwOrWarnOnStatus(status);
		end
		
		 % Responsibility of clearing task is with the callee function
        function [taskHandle] = createTaskandDefaultVoltageChannel(obj)
            
            [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            try
                [status] = daq.ni.NIDAQmx.DAQmxCreateAIVoltageChan (...
                    taskHandle,...                          % The task handle
                    obj.ChannelToTest,...                       % physicalChannel
                    char(0),...                             % nameToAssignToChannel
                    daq.ni.NIDAQmx.DAQmx_Val_Cfg_Default,...% terminalConfig
                    0,...             						% minVal (set to zero since it's safe for any board)
                    0.001,...          						% maxVal (set to 0.001, hoping it is safe for any board)
                    daq.ni.NIDAQmx.DAQmx_Val_Volts,...      % units
                    char(0));                               % customScaleName
                daq.ni.utility.throwOrWarnOnStatus(status);
            catch e
                % Make sure the task is cleaned up
                [~] = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
                rethrow(e)
            end
        end
		
        function result = isCapableOfCouplingMode(obj, taskHandle, couplingModeToTest)
            
            result = 0;
            status = daq.ni.NIDAQmx.DAQmxSetAICoupling(taskHandle, obj.ChannelToTest, couplingModeToTest);
            
            if( status == daq.ni.NIDAQmx.DAQmxSuccess )
                [status,retrievedCouplingMode] = daq.ni.NIDAQmx.DAQmxGetAICoupling(taskHandle, obj.ChannelToTest, int32(0));
                if(status == daq.ni.NIDAQmx.DAQmxSuccess)
                    % Return true if the set and get modes match
                    result = (couplingModeToTest == retrievedCouplingMode);
                end
            end
        end
        
        function result = isCapableOfInputType(obj, taskHandle, inputTypeToTest)
            
            result = 0;
            status = daq.ni.NIDAQmx.DAQmxSetAITermCfg(taskHandle,obj.ChannelToTest,inputTypeToTest);
            
            if( status == daq.ni.NIDAQmx.DAQmxSuccess )
                [status,retrievedInputType] = daq.ni.NIDAQmx.DAQmxGetAITermCfg(taskHandle,obj.ChannelToTest, int32(0));
                if(status == daq.ni.NIDAQmx.DAQmxSuccess)
                    % Return true if the set and get modes match
                    result = (inputTypeToTest == retrievedInputType);
                end
            end
        end 
    end
    
    properties
        ChannelToTest;
    end
end

