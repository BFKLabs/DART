classdef (Enumeration) SignalPolarity < daq.internal.StringEnum
    %SignalCondition Represents possible signal polarities for triggering
    %and clocking
    
    % Copyright 2010 The MathWorks, Inc.
    % $Revision: 1.1.6.1 $  $Date: 2011/01/28 18:48:26 $
    
    enumeration
        Normal
        Inverted
    end
    
    methods(Static)
        function obj = setValue(value)
            obj = daq.internal.StringEnum.enumFactory(...
                'daq.SignalPolarity',...
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

