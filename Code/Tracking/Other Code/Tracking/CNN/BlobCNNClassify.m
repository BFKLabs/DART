classdef BlobCNNClassify < handle
    
    % properties
    properties
    
        % main class objects
        iMov
        pNet
        pTrain
        pSF                
         
        % fixed scalar fields
        Nh
        nCh
        nApp
        sz0
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = BlobCNNClassify(iMov,pCNN)
        
            % sets the input arguments
            obj.iMov = iMov;
            obj.pNet = pCNN.pNet;
            obj.pTrain = pCNN.pTrain;
            obj.pSF = pCNN.pSF;
            
            % initialises the class fields
            obj.initClassFields();
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % array dimensions
            obj.nApp = length(obj.iMov.iR);
            obj.nCh = length(obj.pTrain.iCh);
            
            % retrieves the layer size (if required)
            if ~isempty(obj.pNet)
                obj.Nh = (obj.pNet.Layers(1).InputSize(1)-1)/2;
            end
            
        end

        % -------------------------------- %        
        % --- CLASSIFICATION FUNCTIONS --- %
        % -------------------------------- %
       
        % --- sets the up the classified images
        function BC = classifyImageFast(obj,I)            
                        
            % sets up the initial search grid points
            ICh = obj.setupClassifyImageStack(I);
            fP = obj.setupInitSearchGrid();                        
            
            % runs the neighbourhood classification search
            BC = obj.runNeighbourhoodSearch(ICh,fP);
            
        end
        
        % --- sets the up the classified images
        function [IC,IS] = classifyImage(obj,I)
            
            % memory allocation
            [IC,IS] = deal(zeros(size(I)));
            ICh = obj.setupClassifyImageStack(I); 
            wStr0 = 'Classifying Region';
            
            % creates the progressbar          
            hProg = ProgBar({'Initialising...'},'Image Classification');
            
            % classifies the images for each region
            for i = 1:obj.nApp
                % updates the progressbar
                wStrNw = sprintf('%s (%i of %i)',wStr0,i,obj.nApp);
                if hProg.Update(1,wStrNw,i/obj.nApp)
                    % if the user cancelled, then exit
                    [IC,IS] = deal([]);
                    return
                end
                
                % retrieves the classification indices for current region
                szR = [length(obj.iR{i}),length(obj.iC{i})];                
                fPR = obj.getClassifyRegionIndices(i);   
                tDataC = obj.setupClassificationDataStore(ICh,fPR);
                
                % classifies the pixels for point within the region
                [ICL,ISL] = obj.setupClassifiedSubImage(tDataC,szR);
                IC(obj.iR{i},obj.iC{i}) = ICL;
                IS(obj.iR{i},obj.iC{i}) = ISL;
                
            end
            
            % closes the progressbar
            if exist('hProg','var')
                hProg.closeProgBar();
            end
            
        end             
        
        % --- classifies the sub-region (iApp/iAppS) on frame, iFrm
        function [IC,IS] = classifyRegion(obj,I,iApp)

            % field retrieval
            [iRS,iCS] = obj.getRegionIndices(iApp);
            ICh = obj.setupClassifyImageStack(I);            
                        
            % sets up the classification image stack data-store
            fPR = obj.getClassifyRegionIndices(iApp);
            tDataC = obj.setupClassificationDataStore(ICh,fPR);

            % classifies the pixels for point within the region
            szS = [length(iRS),length(iCS)];            
            [IC,IS] = obj.setupClassifiedSubImage(tDataC,szS);
            
        end             
        
        % --- classifies and resizes the sub-image data
        function [ICL,ISL] = setupClassifiedSubImage(obj,tDataC,szR)
            
            % classifies the image stack data store
            [Z,P] = classify(obj.pNet,tDataC);            
            ICL = reshape(double(Z),szR) - 1;
            ISL = reshape(double(P(:,2)),szR);            
            
        end        
        
        % --- classifies the sub-region (iApp/iAppS) on frame, iFrm
        function [IC,IS] = classifySubRegion(obj,I,iApp,iAppS)
            
            % field retrieval
            [iRS,iCS] = obj.getRegionIndices(iApp,iAppS);
            
            % sets up the classification image stack data-store
            ICh = obj.setupClassifyImageStack(I);
            fPR = obj.getClassifyRegionIndices(iApp,iAppS);
            tDataC = obj.setupClassificationDataStore(ICh,fPR);
            
            % classifies the pixels for point within the region
            szS = [length(iRS),length(iCS)];
            [IC,IS] = obj.setupClassifiedSubImage(tDataC,szS);
            
        end        
        
        % --------------------------- %
        % --- DATASTORE FUNCTIONS --- %
        % --------------------------- %
        
        % --- sets up the classification data store object
        function tDataC = setupClassificationDataStore(obj,ICh,fPR,NhI)

            % sets the input arguments
            if exist('NhI','var')
                obj.Nh = NhI;
            else
                NhI = obj.Nh; 
            end            
            
            % sets the local image size
            szL = (2*NhI + 1)*[1,1]; 
            
            % sets up the classification images
            for k = 1:obj.nCh
                % sets up the sub-image array
                ICT = zeros([szL,1,size(fPR,1)]);
                for j = 1:size(fPR,1)
                    ICT(:,:,1,j) = ...
                        obj.getPointSubImage(ICh{k},fPR(j,:),k,NhI);
                end
                
                % sets up the classification data store object
                if k == 1
                    tDataC = obj.createDataStore(ICT);
                else
                    tDataC = combine(tDataC,obj.createDataStore(ICT));
                end
            end
            
        end             
        
        % --------------------------------- %
        % --- FIELD RETRIEVAL FUNCTIONS --- %
        % --------------------------------- %
        
        % --- sets up the initial search grid points
        function fPR0 = setupInitSearchGrid(obj)
            
            % memory allocation
            NhG = 3;
            fPR0 = cell(obj.nApp,1);
            
            % sets up the search grid points
            for i = 1:obj.nApp
                % retrieves the sub-region coordinates
                [iRnw,iCnw] = obj.getRegionIndices(i);
                szT = [length(iRnw),length(iCnw)];

                % sets up the sub-region grid-points
                [X,Y] = obj.setupSearchGrid(szT,NhG,iCnw,iRnw);
                fPR0{i} = [X(:),Y(:)];
            end            
            
%             % parameters
%             Ns = 10;
%             prZTol = 0.5;
%                        
%             % calculates the combined x-correlated image
%             isF = double(obj.iIDT) == 2;            
%             IChT = cellfun(@(x)(mean(x(:,:,:,isF),4)),obj.ImgT(:),'un',0);
%             IChX = cellfun(@(x,y)(max(0,calcXCorr(x,y))),IChT,ICh,'un',0);
%             IChF = calcImageStackFcn(IChX,'prod');
%             
%             % determines the regional maxima and regional indices
%             iPmx0 = find(imregionalmax(IChF));
%             [indR0,indS0] = deal(obj.ImapR(iPmx0),obj.ImapS(iPmx0));            
%             
%             % sets the candidate grid points for the sub-regions
%             fPR0 = cell(obj.nApp,1);            
%             for i = 1:obj.nApp
%                 % determines the maxima within the current region
%                 indR = find(indR0 == i);
%                 
%                 % determines the candidate points within each sub-region
%                 fPRS = cell(obj.nTube(i),1);
%                 for j = 1:obj.nTube(i)
%                     % retrieves sub-region maxima indices
%                     indS = indR(indS0(indR) == j);
%                     
%                     % determines the relative magnitude, determining the
%                     % most likely points for classification
%                     iPmxS = iPmx0(indS);                    
%                     [Z,iS] = sort(IChF(iPmxS),'descend');
%                     NsS = min(find(Z/Z(1) >= prZTol,1,'last'),Ns);
%                     
%                     % sets the test points for the sub-region                    
%                     [yPR,xPR] = ind2sub(obj.szG,iPmxS(iS(1:NsS)));
%                     fPRS{j} = [xPR(:),yPR(:)];
%                 end
%                  
%                 % converts the cell array into a numerical array
%                 fPR0{i} = cell2mat(fPRS);
%                 clear fPRS
%             end
            
            % converts the array to the final form
            fPR0 = cell2mat(fPR0);
            
        end                
        
        % --- sets up the classification image stack
        function ICh = setupClassifyImageStack(obj,I,rescaleImg)
            
            % sets the default input arguments
            if ~exist('rescaleImg','var'); rescaleImg = true; end
            
            % memory allocation
            obj.sz0 = size(I);
            ICh = cell(obj.nCh,1);
        
            % rescales the image
            if rescaleImg
                I = obj.rescaleImage(I);
            end
            
            % sets up the channel image stack
            for i = 1:obj.nCh
                switch obj.pTrain.iCh(i)
                    case 1
                        % case is the raw image
                        ICh{i} = I;
                        
                    case 2
                        % case is the x-gradient image
                        [ICh{i},IGy] = imgradientxy(I);
                        
                    case 3
                        % case is the y-gradient image
                        if exist('IGy','var')
                            ICh{i} = IGy;
                        else
                            [~,ICh{i}] = imgradientxy(I);
                        end
                end
            end
            
        end        
        
        % --- retrieves the sub-image around the point, fP
        function Isub = getPointSubImage(obj,I,fP,indCh,NhI)
            
            % sets the input arguments
            if exist('NhI','var')
                obj.Nh = NhI;
            else
                NhI = obj.Nh; 
            end
            
            % retrieves the point indices
            [iRP,iCP] = obj.getPointIndices(fP,NhI);
            Isub = I(iRP,iCP);
            
            % scales the gradient images
            if obj.pTrain.iCh(indCh) > 1
                Isub = (min(1,max(-1,Isub/128)) + 1)*128;
            end
            
        end                                                      
        
        % --- retrieves row/column indices for a given region/subregion
        function [iRS,iCS] = getRegionIndices(obj,iApp,iAppS)
            
            % retrieves the column indices
            iCS = obj.rescaleIndices(obj.iMov.iC{iApp});
            
            % retrieves the region indices
            if exist('iAppS','var')
                % case is for a sub-region
                iR0 = obj.rescaleIndices(obj.iMov.iR{iApp});
                iRS = iR0(obj.rescaleIndices(obj.iMov.iRT{iApp}{iAppS}));

            else
                % case is for an entire region
                iRS = obj.rescaleIndices(obj.iMov.iR{iApp});
            end
            
        end                
        
        % ------------------------- %
        % --- SCALING FUNCTIONS --- %
        % ------------------------- %        
        
        % --- rescales the image, I, but the scale factor, pSF
        function I = rescaleImage(obj,I,pS)
            
            % sets the default input arguments
            if ~exist('pS','var'); pS = obj.pSF; end
            
            % scales the image (if required)
            if pS > 1
                I = imresize(I,1/pS);
            end
            
        end         
        
        % --- rescales the row/column index array
        function ind = rescaleIndices(obj,ind,pS)

            % sets the default input arguments
            if ~exist('pSFnw','var'); pS = obj.pSF; end            
            
            % scales the indices (if required)
            if pS > 1
                ind = unique(floor((ind-1)/pS)+1);
            end

        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- runs the neighbourhood classification search around, fP
        function BC = runNeighbourhoodSearch(obj,ICh,fP)
            
            % initialisations
            zMinTol = 0.50;
            szG = size(ICh{1});
            [BS,BC] = deal(false(szG));            
            
            % keep running until all feasible points are searched
            while true
                % sets up and runs the classifier on the test datastore
                tData = obj.setupClassificationDataStore(ICh,fP);            
                [~,zPred0] = classify(obj.pNet,tData); 
                clear tData
            
                % determines if there are any feasible points within the
                % current point dataset
                isF = zPred0(:,2) > zMinTol;
                if any(isF)
                    % if so, set the classified points and updates the
                    % searched region binary mask
                    iP = sub2ind(szG,fP(:,2),fP(:,1));                    
                    [BC(iP),BS(iP)] = deal(isF,true);
                                        
                    % determines the new search points
                    BSnw = bwmorph(setGroup(iP(isF),szG),'dilate');
                    BSnw = BSnw & ~BS;                    
                    if any(BSnw(:))
                        % if available, then calculate their coordinates
                        [yP,xP] = ind2sub(szG,find(BSnw));
                        fP = [xP,yP];
                        
                    else
                        % otherwise, exit the search loop
                        break
                    end
                    
                else
                    % if there are no new points, then exit the loop
                    break
                end
                
            end            
        
            % resizes the image (if required)
            if ~isequal(size(BC),obj.sz0)
                BC = imresize(BC,obj.sz0);
            end
            
        end          
        
    end
    
    % static class methods
    methods (Static)
        
        % --- sets up the point indices
        function [iR,iC] = getPointIndices(fP,N)
            
            xiN = (-N:N);
            [iR,iC] = deal(xiN+fP(2),xiN+fP(1));
            
        end               
        
        % --- sets up the array data store object
        function arrDS = createDataStore(Img)
            
            arrDS = arrayDatastore(Img,'IterationDimension',4);
            
        end   
        
        % --- sets up the search grid
        function [X,Y] = setupSearchGrid(szT,nSz,iCnw,iRnw)
            
            % calculates the grid count/offset
            nGrid = ceil(szT/nSz);
            pOfsG = max(1,ceil((szT - (nGrid-1)*nSz)/2));
            
            % calculates the x/y grid point locations
            iY = pOfsG(1) + ((1:nGrid(1))-1)*nSz;
            iX = pOfsG(2) + ((1:nGrid(2))-1)*nSz;
            
            % sets the final grid values
            if exist('iCnw','var')
                [X,Y] = meshgrid(iCnw(iX),iRnw(iY));
            else
                [X,Y] = meshgrid(iX,iY);
            end
            
            % converts the arrays to row vectors
            [X,Y] = deal(X(:),Y(:));
            
        end        
        
    end
    
end