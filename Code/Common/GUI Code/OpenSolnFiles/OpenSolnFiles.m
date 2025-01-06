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
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();            
            
            % clears the output object (if not required)
            if (nargout == 0) && ~isdeployed
                clear obj
            end            
            
        end        
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            
            
        end
        
        % --- initialises the class fields
        function initClassObjects(obj)
            

            
        end
                
    end
    
    % class methods
    methods (Static)
        

        
    end    
    
end