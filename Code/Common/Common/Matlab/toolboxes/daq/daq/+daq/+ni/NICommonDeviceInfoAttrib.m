classdef NICommonDeviceInfoAttrib < daq.internal.BaseClass
    %NICommonDeviceInfoAttrib Hold the utility functions used during device
    %discovery
    
    % Copyright 2011 The MathWorks, Inc.
    
    methods (Hidden, Static)
        function result = detectOnDemandSupport(taskHandle)
            result = true;
            [status] = daq.ni.NIDAQmx.DAQmxSetSampTimingType(...
                taskHandle,...
                daq.ni.NIDAQmx.DAQmx_Val_OnDemand );
            
            if status ~= daq.ni.NIDAQmx.DAQmxSuccess
                result = false;
            end
            
            % Some NI devices error out only when you try to read an
            % unsupported value and not when you write to them
            [status,~] = daq.ni.NIDAQmx.DAQmxGetSampTimingType(...
                taskHandle,...
                int32(0));
            
            if status == daq.ni.NIDAQmx.DAQmxErrorInvalidAttributeValue
                result = false;
            end
        end
    end
end

