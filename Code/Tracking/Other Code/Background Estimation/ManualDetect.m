classdef ManualDetect < handle
    % class properties
    properties
        % main class fields
        iMov
        hProg
        
    end
    
    % methods
    methods
        % class constructor
        function obj = ManualDetect(iMov,hProg)
            
            % sets the input arguments
            obj.iMov = iMov;
            obj.hProg = hProg;
            
        end        
    end
    
    % static methods
    methods (Static)
        
    end
end