classdef StatsTestData < DataOutputArray
    
    % class properties
    properties

        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = StatsTestData(hFig,hProg) 
            
            % creates the super-class object
            obj@DataOutputArray(hFig,hProg);            
            
            % sets up the data array
            obj.setupDataArray();
            
        end
        
        % --- sets up the data output array
        function setupDataArray(obj)
            
            
        end                
        
    end
end