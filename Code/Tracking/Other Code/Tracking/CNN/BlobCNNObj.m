classdef BlobCNNObj < matlab.mixin.Copyable
    
    % class properties
    properties
        
        pNet                % model network
        pTrain              % training parameters
        pSF                 % image scale factor        
        Iavg                % average image stack        
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = BlobCNNObj()
    
            % initialises the training parameters
            obj.pTrain = BlobCNNTrainPara(true);
            
        end
        
    end
    
end