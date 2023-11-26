classdef DummyDevice < matlab.mixin.SetGet
    
    % class properties
    properties
        
        % device info fields
        Port
        UserData                
        status = 'closed';
        
    end
    
    % class methods
    methods
   
        % --- class constructor
        function obj = DummyDevice(comStr)
            
            % sets the input arguments
            obj.Port = comStr;
            
            % initialises the class object fields
            obj.initClassFields();            
            
        end
        
        % --- initialises the class object fields
        function initClassFields(obj)
            
            
            
        end
        
    end
    
end