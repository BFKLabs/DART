classdef SVMModel < handle

    % class properties
    properties    
        % main class fields
        mdl
        xiI
        xiR
        Bsvm
        
        % other fixed parameters
        dxi = 0.1;
        xiMax = 100;
        
    end
    
    % class methods
    methods
        % --- class constructor
        function obj = SVMModel(Z,idx)
    
            % trains the linear svm model 
            obj.mdl = fitcsvm(Z,idx,'KernelFunction','linear');
            
            % sets up the 
            [obj.xiI,obj.xiR] = meshgrid(0:obj.dxi:obj.xiMax);
            
            % sets up the svm binary mask
            sz = length(obj.xiI)*[1,1];
            Ztmp = [obj.xiI(:),obj.xiR(:)];
            obj.Bsvm = reshape(predict(obj.mdl,Ztmp),sz);
            
        end
        
        % --- retrieves the svm image
        function Isvm = getSVMImage(obj,I,IR)
            
            % sets up the values for the model predictor
            sz = size(obj.Bsvm);
            xI = min(sz(1),max(0,floor(I(:)/obj.dxi)) + 1);
            xR = min(sz(1),max(0,floor(IR(:)/obj.dxi)) + 1);            
            indIR = sub2ind(sz,xR,xI);
            
            % returns the final SVM image
            Isvm = reshape(obj.Bsvm(indIR),size(I)) - 1;
            
        end
        
    end    
    
end