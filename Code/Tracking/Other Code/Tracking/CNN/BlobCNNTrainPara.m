classdef BlobCNNTrainPara < matlab.mixin.Copyable
    
    % properties
    properties
        
        % numerical fields
        nLvl
        iCh
        filtSize
        maxEpochs
        batchSize
        Momentum
        nCountStop
        
        % enumeration parameters
        algoType
        
        % other class fields
        floatP = {'Momentum'};
        
    end
    
    % class methods
    methods
    
        % --- class constructor
        function obj = BlobCNNTrainPara(initClass)
            
            % sets the class initialisation flag
            if ~exist('initClass','var'); initClass = false; end
            
            % initialises the class fields
            if initClass
                obj.initClassFields()
            end
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % network parameters
            obj.iCh = 1:2;                
            obj.nLvl = 2;
            obj.filtSize = 16;
            
            % training parameters
            obj.batchSize = 50;            
            obj.maxEpochs = 2;
            obj.nCountStop = 5;
            obj.Momentum = 0.9;            
            
            % enumeration parameters
            obj.algoType = 'sgdm';            
            
        end
        
        % --- determines if the parameter, pStr, is an integer value
        function isIntP = isInitPara(obj,pStr)
           
            % returns the parameter flag
            isIntP = ~any(strcmp(obj.floatP,pStr));
            
        end

        % --------------------------- %        
        % --- CLASS I/O FUNCTIONS --- %
        % --------------------------- %
        
        % --- sets the class field
        function setField(obj,pStr,pVal)
            
            obj.(pStr) = pVal;
            
        end
        
        % --- sets the class field
        function pVal = getField(obj,pStr)
            
            pVal = obj.(pStr);
            
        end        
        
    end
    
end