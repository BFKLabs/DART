classdef (Enumeration) TriggerType < daq.internal.StringEnum
    %TriggerType Represents possible trigger types for trigger connection.
    
    % Copyright 2011 The MathWorks, Inc.

    enumeration
        Digital        
    end
    
    methods(Static)
        function obj = setValue(value)
            obj = daq.internal.StringEnum.enumFactory(...
                'daq.TriggerType',...
                value);
        end
    end
    
    methods(Access=protected)
        function resetImpl(obj)
            %resetImpl Handle daq.reset (which is usually delete)
            if isvalid(obj)
                delete(obj)
            end
        end
    end
    
end

