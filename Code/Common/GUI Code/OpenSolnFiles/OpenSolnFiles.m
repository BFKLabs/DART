classdef OpenSolnFiles < handle & OpenSolnFilesObj
    
    % class properties
    properties
        
        
    end
    
    % class methods
    methods
        
        % --- class constuctor
        function obj = OpenSolnFiles(hFigM,sType)
            
            % sets the input arguments
            obj@OpenSolnFilesObj(hFigM,sType);            
            
            % clears the output object (if not required)
            if (nargout == 0) && ~isdeployed
                clear obj
            end            
            
        end       
                
    end 
    
end