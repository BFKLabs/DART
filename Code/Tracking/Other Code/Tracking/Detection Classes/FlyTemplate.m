classdef FlyTemplate < handle
    
    % class properties
    properties
        
        % main input fields
        pObj
        iApp
        
        % fixed scalar fields
        pTolBB = 0.1;            
        
    end
    
    % class methods
    methods
    
        % -- class constructor
        function obj = FlyTemplate(pObj,iApp)
            
            % sets the input fields
            obj.pObj = pObj;            
            obj.iApp = iApp;
            
        end
       
        % --- calculates the fly template image (for the current region) 
        function setupFlyTemplate(obj,dIRL,fPosT)
                
            % sets the sub-region size
            N = ceil(obj.pObj.dTol);
            if obj.pObj.nI > 0
                N = (1+obj.pObj.nI)*N + 1;         
            end
            
            % keep looping until the filtered binary mask no-longer touches
            % the edge of the sub-region frame
            while 1
                % retrieves the fly sub-image stack (for all known points)
                Isub = cell(obj.pObj.nFrm,size(fPosT{1},1));
                for i = 1:obj.pObj.nFrm
                    fTmp = obj.downsampleCoords(fPosT{i});
                    Isub(i,:) = cellfun(@(x,y)(obj.getPointSubImage...
                         (y,x,N)),num2cell(fTmp,2)',dIRL(i,:),'un',0);
                end
                
                % calculates the 
                pOfs = (size(Isub{1})+1)/2;
                Bsub = cellfun(@(x)(detLargestBinary(-x,pOfs)),Isub,'un',0);

                % calculates the sub-image stack mean image
                Q = cellfun(@(x,y)(x.*y),Isub,Bsub,'un',0);
                IsubMn = calcImageStackFcn(Q(:),'mean');
                
                % sets up the binary mask
                nH = (size(IsubMn,1)-1)/2;
                B0 = setGroup((nH+1)*[1,1],(2*nH+1)*[1,1]);
                
                % sets up template image
                hC0 = max(0,IsubMn - mean(IsubMn(:),'omitnan'));
                [~,B] = detGroupOverlap(hC0>0,B0);
                
                % sets up template arrays within the parent class object
                hCF = hC0.*B;
                ii = obj.getTemplateInterpIndices(hCF);                
                [obj.pObj.hC{obj.iApp},B] = deal(hCF(ii,ii),B(ii,ii));

                % thresholds the filtered sub-image
                Brmv = B & (normImg(obj.pObj.hC{obj.iApp}) > obj.pTolBB);   
                if all(Brmv(bwmorph(true(size(Brmv)),'remove')))
                    N = N + (1+obj.pObj.nI);
                    obj.pObj.dTol = obj.pObj.dTol + 1;                    
                else
                    break
                end
            end
            
            % determines the approx blob size (if not already set)
            if ~isfield(obj.pObj.iMov,'szObj') || ...
                    isempty(obj.pObj.iMov.szObj)
                BrmvD = sum(Brmv(logical(eye(size(Brmv)))));                                
                obj.pObj.iMov.szObj = BrmvD*[1,1];
                obj.pObj.dTol = obj.pObj.calcDistTol();                
            end
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- downsamples the image coordinates
        function fP = downsampleCoords(obj,fP)
            
            if obj.pObj.nI > 0
                fP = roundP(((fP-1)/obj.pObj.nI - 1)/2 + 1);
            end
                
        end                  
        
        % --- calculates the distance tolerance value
        function dTolT = calcDistTol(obj)
            
            % calculates the distance tolerance
            if isempty(obj.pObj.iMov.szObj)
                dTolT = obj.pObj.dTol0;
            else
                % scales the value (if interpolating)
                dTolT = (3/4)*min(obj.pObj.iMov.szObj);                        
                if obj.pObj.nI > 0
                    dTolT = ceil(dTolT/obj.pObj.nI);
                end
            end
            
        end        
        
    end
    
    % static class methods
    methods (Static)
        
        % --- sets the template interpolation indices
        function indI = getTemplateInterpIndices(B)
            
            %
            xiF = 1:2:size(B,2);
            ii = any(B(:,xiF),1) | any(B(xiF,:),2)';
            
            %
            N = min(find(ii,1,'first'),(length(ii)+1)-find(ii,1,'last'));
            indI = xiF(N):xiF(end-(N-1));
            
        end                
        
        % --- retrieves the point sub-image
        function IsubS = getPointSubImage(I,fP,N,ok)

            % sets the default input argument
            if ~exist('ok','var'); ok = true; end                

            % memory allocation
            IsubS = NaN(2*N+1);
            if any(isnan(fP)) || ~ok; return; end

            % determines the row/column coordinates
            iCS = (fP(1)-N):(fP(1)+N);
            iRS = (fP(2)-N):(fP(2)+N);

            % determines the feasible points
            jj = (iCS > 0) & (iCS <= size(I,2));
            ii = (iRS > 0) & (iRS <= size(I,1));

            % sets the feasible sub-image pixels
            IsubS(ii,jj) = I(iRS(ii),iCS(jj));

        end                       
        
    end
    
end