classdef SingleTrackInitHT1 < handle
    
    % class properties
    properties
   
        % main class properties
        trObj
        pCNN
        
        % struct class fields
        IL
        IR
        iMov 
        
        % array class fields
        hC  
        IbgT
        IRef
        IPosT
        pStats
        szObjHT1
        
        % boolean class fields
        useCNN
        
        % tolerances
        pLo = 100;        
        dZTol = 2.25;
        dTol0 = 7.5;
        pQmxTol = 1/4;

        % scalar class fields
        nI        
        nApp
        nFrm
        dScl
        dTol
        wOfsL
        QmxTol        
        iPh = 1;
        pT = 100;
        nFrmAdd = 50;
        
    end
    
    % class methods
    methods
       
        % --- class constructor
        function obj = SingleTrackInitHT1(trObj)
        
            % sets the main class fields
            obj.trObj = trObj;
            
            % sets the other fields
            obj.nI = trObj.nI;                        
            obj.nApp = trObj.nApp;            
            obj.iMov = trObj.iMov;
            obj.wOfsL = trObj.wOfsL;            
            obj.useCNN = isa(trObj.hProg,'BlobCNNProgBar');
            
            % resets the distance tolerance field
            obj.dTol = obj.calcDistTol();
            
        end
        
        % --- analyses the entire video for the initial locations
        function analysePhase(obj)
            
            % updates the progress-bar
            wStrNw = 'Special Phase Detection (Phase #1)';
            pW0 = 2/(obj.trObj.pWofs+obj.trObj.nPhase);
            if obj.trObj.UpdatePB([1,-1],wStrNw,pW0)
                obj.trObj.calcOK = false;
                return
            else
                % resets the secondary field
                wStrNw1 = 'Initialising Region Analysis...';
                obj.trObj.UpdatePB([2,-1],wStrNw1,0);
            end
            
            % field retrieval and memory allocation
            obj.szObjHT1 = NaN(obj.nApp,2);
            [obj.hC,obj.IbgT,obj.IL] = deal(cell(obj.nApp,1));
            [isAmbig,IRL,fOK] = deal(cell(obj.nApp,1));
            
            % field retrieval
            obj.IPosT = obj.trObj.IPos;
            nFrmPh = length(obj.trObj.Img{1});            
            [iR,iC] = deal(obj.iMov.iR,obj.iMov.iC);                          
            
            % determines the 
            for iApp = find(obj.iMov.ok(:)')
                % update the waitbar figure
                wStr = sprintf('Analysing Region (%i of %i)',iApp,obj.nApp);
                if obj.trObj.UpdatePB([2,3],wStr,iApp/obj.nApp)
                    % if the user cancelled, then exit
                    obj.trObj.calcOK = false;
                    return
                else
                    % resets the tertiary field
                    wStrNw2 = 'Initialising Sub-Region Analysis...';
                    obj.trObj.UpdatePB([3,-1],wStrNw2,0);
                end     
                                
                % field retrieval
                iRT = obj.iMov.iRT{iApp};
                xiF = 1:getSRCount(obj.iMov,iApp);
                fOK{iApp} = obj.iMov.flyok(xiF,iApp);                
                nRT = ceil(median(cellfun(@length,iRT))); 
                QmxF = zeros(length(iRT),nFrmPh);

                % ------------------------- %
                % --- IMAGE STACK SETUP --- %
                % ------------------------- %                
                
                % calculates the background reference image
                IL0 = cellfun(@(x)...
                    (x(iR{iApp},iC{iApp})),obj.trObj.Img{obj.iPh},'un',0);
                obj.IRef = obj.calcWeightedRefImage(IL0);
                obj.trObj.IbgR{obj.iPh,iApp} = obj.IRef;
                
                % retrieves the sub-region image stack
                obj.IL{iApp} = calcHistMatchStack(IL0,obj.IRef);   
                
                % sets the background image estimate
                Ibg0 = calcImageStackFcn(IL0,'max');
                obj.IbgT{iApp} = calcHistMatchStack(Ibg0,obj.IRef);
                clear IL0
                                
                % calculates the residual image stack
                obj.IR = obj.calcImageResidual(obj.IL{iApp},obj.IbgT{iApp});
                obj.pStats = obj.calcImageStackStats(obj.IR);  
                obj.nFrm = length(obj.IR);                          
                
                % ----------------------------- %
                % --- MOVEMENT STATUS FLAGS --- %
                % ----------------------------- %                
                
                % calculates the offset residual values
                ZR = max(calcImageStackFcn(obj.IR,'max'),[],2);
                ZRO = imopen(ZR,ones(2*nRT,1));
                dZR = (ZR - ZRO)./ZRO;
                
                % determines the movement status flag for each sub-region
                Zmx = obj.getSubRegionValues(dZR,iRT,fOK{iApp});
                isZTol = Zmx < obj.dZTol;
                
                % sets the status/movement flags                
                obj.trObj.sFlagT{obj.iPh,iApp} = 1 + double(isZTol);
                obj.trObj.sFlagT{obj.iPh,iApp}(~fOK{iApp}) = NaN;
                obj.trObj.mFlag{obj.iPh,iApp} = 2 - double(isZTol);
                obj.trObj.pStatsF{obj.iPh,iApp} = obj.pStats;
                obj.trObj.Is{obj.iPh,iApp} = {obj.IR,obj.IL{iApp}};
                
                % ----------------------------------- %
                % --- BLOB DETECTION CALCULATIONS --- %
                % ----------------------------------- %
                
                % memory allocation
                IRL{iApp} = cell(obj.nFrm,length(fOK{iApp}));
                
                % calculates the position of the blobs over all frames
                wStr = 'Initial Sub-Region Detection...';
                obj.trObj.UpdatePB([3,-1],wStr,1/3);
                for iFly = find(fOK{iApp}(:)')
                    IRL{iApp}(:,iFly) = ...
                        cellfun(@(x)(x(iRT{iFly},:)),obj.IR,'un',0);
                    QmxF(iFly,:) = ...
                        obj.calcBlobPos(IRL{iApp}(:,iFly),iApp,iFly);               
                end                

                % ------------------------------- %
                % --- AMBIGUOUS REGION SEARCH --- %
                % ------------------------------- %
                
                % determines if there are any ambiguous locations
                % (residuals which are outliers relative to the population)
                obj.QmxTol = min((1+obj.dZTol)*...
                        cellfun(@(x)(mean(ZRO(x))),iRT));

                % determines if there are any ambiguous locations (removes
                % any sub-regions flag as being stationary)
                isStat = obj.trObj.sFlagT{obj.iPh,iApp} == 2;
                isAmbig{iApp} = QmxF < obj.QmxTol; 
                isAmbig{iApp}(isStat,:) = 0;
                
                % determines if there are any "ambiguous" locations
                % (locations where flies have very low residuals)
                if any(isAmbig{iApp}(:))                    
                    % searches through each of the ambiguous frames
                    iGrpA = obj.setupSearchGroups(isAmbig{iApp},fOK{iApp});
                    nGrpA = size(iGrpA,1);
                    
                    % searches each of the frame groups
                    for j = 1:nGrpA
                        % updates the progressbar
                        pW = (1/3)*(1 + 2*j/nGrpA);
                        wStr = sprintf('Checking Group (%i of %i)',j,nGrpA);                        
                        if obj.trObj.UpdatePB([3,-1],wStr,pW)
                            % if the user cancelled, then exit
                            obj.trObj.calcOK = false;
                            return
                        end
                        
                        % performs the search for the ambiguous object
                        obj.searchAmbigPos(iGrpA(j,:),iApp);
                    end
                end                                
                
                % sets the region coordinates + vertical offsets                             
                fOK0 = obj.iMov.flyok(xiF,iApp);
                fPT0 = obj.trObj.fPosL{obj.iPh}(iApp,:);
                yOfs = cellfun(@(x)(x(1)-1),obj.iMov.iRT{iApp});
                
                % sets the residual values at the final points
                for j = 1:obj.nFrm
                    % sets the linear indices of the fly positions
                    fPT = fPT0{j} + [zeros(length(yOfs),1),yOfs];
                    [fOK{iApp},fOKF] = deal(fOK0 & ~isnan(fPT(:,1)));
                    indP = sub2ind(size(obj.IR{1}),fPT(fOKF,2),fPT(fOKF,1));
              
                    % sets the blob point residual values
                    obj.trObj.IPos{obj.iPh}{iApp,j}(fOKF) = obj.IR{j}(indP);
                    obj.IPosT{obj.iPh}{iApp,j}(fOKF) = obj.IL{iApp}{j}(indP);
                end
            end
           
            % ------------------------- %
            % --- BLOB CNN TRAINING --- %
            % ------------------------- %            
            
            % if there are moving blobs (and using CNN) then train network
            if obj.useCNN 
                % determines which flies are moving
                isMoving = combineNumericCells(obj.trObj.sFlagT) == 1;
                
                if obj.trObj.hProg.isTrain
                    % if training, then clear the network object
                    obj.trObj.hProg.pCNN.pNet = [];                                                   
                    
                    % if training network, then determine if there are any
                    % regions which have moving blobs
                    if ~any(isMoving(:))
                        % if not, then output a warning to screen
                        eStr = ['There are no moving objects detected ',...
                                'within the current setup. Either ',...
                                'reset the group regions or deselect',...
                                'CNN classification.'];
                        tStr = 'No Moving Objects';
                        waitfor(msgbox(eStr,tStr,'modal'));
                        
                        % resets the CNN use flag
                        obj.useCNN = false;
                    end
                end    
                
                if obj.useCNN
                    % updates the global coordinates
                    obj.trObj.calcGlobalCoords(1); 
                    
                    % runs the CNN training/classification                    
                    objB = BlobCNNTrain(obj.trObj);
                    objB.trainCNN(obj.trObj.hProg);
                    
                    if ~objB.calcOK
                        % if the user cancelled, then exit                    
                        obj.trObj.calcOK = false;
                        return
                        
                    elseif obj.trObj.hProg.isTrain
                        % if training, then retrieve the network model
                        obj.trObj.hProg.pCNN.pSF = objB.pSF;
                        obj.trObj.hProg.pCNN.pNet = objB.pNet;
                        
                        % sets the average class image
                        isT = double(objB.iIDT) == 2;
                        obj.trObj.hProg.pCNN.Iavg = cellfun(@(x)(...
                            mean(x(:,:,:,isT),4)),objB.ImgT,'un',0);                        
                    end                    
                    
                    % clears the extraneous variables
                    clear objB
                end
            end
            
            % runs the batch processing perform check (if necessary)
            if obj.trObj.isBatch
                obj.trObj.performBatchProcessCheck();
            end

            % -------------------------------------------- %
            % --- POST TRAINING/DETECTION CALCULATIONS --- %
            % -------------------------------------------- %           
            
            for iApp = find(obj.iMov.ok(:)')
                % update the waitbar figure
                wStr = sprintf('Analysing Region (%i of %i)',iApp,obj.nApp);
                if obj.trObj.UpdatePB([2,4],wStr,iApp,obj.nApp)
                    % if the user cancelled, then exit
                    obj.trObj.calcOK = false;
                    return
                end
                
                % field retrieval
                fPT0 = obj.trObj.fPosL{obj.iPh}(iApp,:);
                
                % only set up the template (if missing and there are fly
                % locations known with reasonable accuracy)
                if isempty(obj.hC{iApp})
                    if any(~isAmbig{iApp}(:))
                        obj.setupFlyTemplate(IRL{iApp},fOK{iApp},iApp);
                    else
                        return
                    end
                end                                
                
                % resets the background images for the stationary objects
                if obj.useCNN
                    % case is using the 
                    for i = find(obj.trObj.sFlagT{obj.iPh,iApp}(:)' == 2)
                        fPosL = cellfun(@(x)(x(i,:)),fPT0(:),'un',0);
                        obj.removeBackgroundBlob(fPosL,iApp,i);
                    end
                    
                elseif any(obj.trObj.sFlagT{obj.iPh,iApp} == 2)
                    % otherwise, find and remove the stationary objects
                    obj.searchStationaryRegions(iApp);
                end                                
                
                % removes any stationary blobs from the background image
                isStat = obj.calcMovementRange(iApp) <= obj.calcDistTol;
                isStatD = (obj.trObj.sFlagT{obj.iPh,iApp} == 1) & isStat;
                for i = find(isStatD(:)')
                    fPosL = cellfun(@(x)(x(i,:)),fPT0(:),'un',0);
                    obj.removeBackgroundBlob(fPosL,iApp,i);
                end
               
                % if there were any changes, then fill in the gaps
                if any(isnan(obj.IbgT{iApp}(:)))
                    obj.IbgT{iApp} = interpImageGaps(obj.IbgT{iApp});
                end                
                
                % sets the tracking object fields
                obj.trObj.iMov.Ibg{obj.iPh}{iApp} = obj.IbgT{iApp};

                % clears extraneous fields
                
                % updates the waitbar figure
                wStr = 'Sub-Region Detection Complete';
                obj.trObj.UpdatePB([3,-1],wStr,1);
            end
            
            % sets the final expanded template images
            obj.trObj.hCQ = obj.trObj.expandImageArray(obj.hC);
            
            % calculates the global coordinates
            obj.trObj.calcGlobalCoords(1);            
            
        end      
        
        % --- searches any of the stationary regions
        function searchStationaryRegions(obj,iApp)
                        
            % parameters
            nS = 1000;
            pTolZT = 1/5;
            pTolZmxT = 1/4;            
            yOfs = cellfun(@(x)(x(1)),obj.iMov.iRT{iApp}) - 1;

            % retrieves the template image
            if isempty(obj.hC{iApp})
                xiC = 1:(iApp-1);
                hCex = obj.trObj.expandImageArray(obj.hC(xiC));
                hCnw = calcImageStackFcn(hCex(obj.iMov.ok(xiC)));
            else
                hCnw = obj.hC{iApp};
            end
            
            % sets the image filter (based on template image size)
            hG = fspecial('log',size(hCnw)+2,1); 

            % calculates the sharpened image cross-correlation binary
            Q = cellfun(@(x)(min(0,...
                imsharpen(x,'Amount',nS))),obj.IL{iApp},'un',0); 
            Z = cellfun(@(x)(max(0,calcXCorr(hG,x))),Q,'un',0);            
            Ztot = calcImageStackFcn(cellfun(@(x)(x > pTolZT),Z,'un',0)); 
            
            % calculates the raw image maxima cross-correlation binary
            ILmx = calcImageStackFcn(obj.IL{iApp},'max'); 
            Zmx = max(0,calcXCorr(-hCnw,ILmx));            
            ZmxB = obj.removeEdgeTouchGroups(ILmx,Zmx>pTolZmxT,iApp);
            
            % calculates the sub-region pixel intensity threshold
            ILmd = median(ILmx,2);
            ILmdT = cellfun(@(x)(...
                0.5*(min(ILmd(x))+max(ILmd(x)))),obj.iMov.iRT{iApp});
            
            % determines the likely group blobs and their centroids
            [~,A] = detGroupOverlap(Ztot==1,ZmxB); 
            [~,pC,bSz] = getGroupIndex(A,'Centroid','Area');
            pC = roundP(pC);         
            
            % searches the sub-regions which were flagged as stationary
            for i = find(obj.trObj.sFlagT{obj.iPh,iApp}(:)' == 2)
                % determines the blobs within the sub-region
                if isempty(pC)
                    ii = [];
                else
                    ii = find((pC(:,2) >= obj.iMov.iRT{iApp}{i}(1)) & ...
                              (pC(:,2) <= obj.iMov.iRT{iApp}{i}(end)));
                end

                if ~isempty(ii)
                    % if there are such blobs, then determine which blob
                    % centroids meet the threshold criteria
                    okG = (ILmd(pC(ii,2)) > ILmdT(i)) & (bSz(ii) > 1);
                    jj = ii(okG);
                    switch length(jj)
                        case 0
                            % case is there is no blobs in the sub-region
                            iMx = NaN;
                            
                        case 1
                            % case is there is a unique blob
                            
                            % converts to local coordinates and sets
                            iMx = 1;
                                                        
                        otherwise
                            % case is non-unique blob counts
                            
                            % determines blob with highest x-corr score
                            indP = sub2ind(size(ILmx),pC(jj,2),pC(jj,1));
                            iMx = argMax(Zmx(indP));                              
                    end
                    
                    if ~isnan(iMx)
                        % converts to local coordinates and sets
                        fPosL = pC(jj(iMx),:) - [0,yOfs(i)];
                        obj.setObjPos(fPosL,iApp,i);
                        obj.trObj.mFlag{obj.iPh,iApp}(i) = 1;
                        
                        % resets the background image
                        obj.removeBackgroundBlob({fPosL},iApp,i);
                    end
                end
            end
            
        end             
        
        % --- removes any binary groups that touch the frame edge 
        function B = removeEdgeTouchGroups(obj,ILmx,B0,iApp)
            
            % parameters
            pTolI = 10;
            Imax = 50;
            
            % sets up the region map mask
            Imap = obj.setupRegionMap(obj.iMov.iRT{iApp},size(ILmx));
                        
            % determines the threshold value
            IPosAll = cell2mat(obj.IPosT{obj.iPh}(iApp,:)');
            pTolAll = min(Imax,prctile(IPosAll,pTolI));
            
            % removes any blob groups that touch the frame edge
            Bedge = bwmorph(true(size(B0)),'remove');
            [~,Bover] = detGroupOverlap(B0 | (ILmx <= pTolAll),Bedge);
            
            % removes any groups that are too large or cross sub-regions
            iGrp = getGroupIndex(B0 & ~Bover);
            nGrp = cellfun('length',iGrp);
            nGrpMap = cellfun(@(x)(length(unique(Imap(x)))),iGrp);
            ii = (nGrp < pi*(obj.iMov.szObj(1)/2)^2) & (nGrpMap == 1);
            
            % sets the final binary mask
            B = setGroup(iGrp(ii),size(B0));
            
        end
        
        % ------------------------------------------ %
        % --- FLY TEMPLATE CALCULATION FUNCTIONS --- %
        % ------------------------------------------ %
        
        % --- calculates the fly template image (for the current region) 
        function setupFlyTemplate(obj,IRL,fOK,iApp)
                
            % sets the known fly location coordinates/linear indices
            fPos0 = obj.trObj.fPosL{obj.iPh}(iApp,:);   
            isOK = fOK & (obj.trObj.sFlagT{obj.iPh,iApp} == 1);   

            % if there are no valid fly locations then exit the function
            if ~any(isOK)
                % if there is a previous filter image, then use that
                if isfield(obj.iMov,'hFilt') && ~isempty(obj.iMov.hFilt)
                    % uses the previous filter sub-image
                    obj.hC{iApp} = obj.iMov.hFilt;
                    
                    % calculates the other properties (if not set)
                    if ~isfield(obj.iMov,'szObj') || isempty(obj.iMov.szObj)
                        Brmv = obj.hC{iApp} > 0;
                        BrmvD = sum(Brmv(logical(eye(size(Brmv)))));
                        obj.iMov.szObj = BrmvD*[1,1];
                        obj.dTol = obj.calcDistTol();
                    end
                end
                
                % exits the function
                return
            end
            
            % determines the feasible frames
            IRL = IRL(:,isOK); 
            fPosT = cellfun(@(x)(x(isOK,:)),fPos0,'un',0);
            
            % sets up and runs the template optimisation object
            tObj = FlyTemplate(obj,iApp);
            tObj.setupFlyTemplate(IRL,fPosT);             
            
            % sets blob size field
            obj.szObjHT1(iApp,:) = obj.iMov.szObj;
            
        end        
        
        % ------------------------------------------ %
        % --- FLY POSITION CALCULATION FUNCTIONS --- %
        % ------------------------------------------ %
        
        % --- calculates the locations of the special phase blobs 
        function QmxF = calcBlobPos(obj,IRL,iApp,iFly)
                        
            % parameters
            pnMin = 0.25;
            pTolMx = 2/3;
            
            % sets the region image stack
            [nFrmL,szL] = deal(length(IRL),size(IRL{1}));
            [fPosNw,QmxF] = deal(NaN(nFrmL,2),NaN(1,nFrmL));
            sFlag = obj.trObj.sFlagT{obj.iPh,iApp}(iFly);
            
            % calculates the positions for each sub-region
            for i = 1:nFrmL
                % determines the regional maxima from the local image
                iMx = find(imregionalmax(IRL{i}));
                [Qmx,iS] = sort(IRL{i}(iMx),'descend');
                iMx = iMx(iS);
                
                % determines how dominance of the most likely blob
                isTol = Qmx/Qmx(1) > pTolMx;
                if sum(isTol) == 1
                    % case is frame has a dominant blob
                    iSel = 1;
                    
                else
                    switch sFlag
                        case 1
                            % case is a moving blob
                            iSel = 1;
                            
                        case 2
                            % case is a stationary blob 
                            iSel = NaN;
                            
                        otherwise
                            % 
                            iSel = NaN;
                            
                    end
                end
                
                % calculates the final coordinates
                if ~isnan(iSel)
                    [yMx,xMx] = ind2sub(szL,iMx(iSel));
                    fPosNw(i,:) = [xMx,yMx];
                    QmxF(i) = Qmx(iSel);
                end
            end
            
            % fills in any frames with NaN values (stationary object only)
            if sFlag == 2
                isN = isnan(QmxF);
                if any(isN)
                    % if there positions haven't been located, then 
                    % determine if enough data points are available to
                    % confidently say the stationary object has been found
                    if (mean(~isN) > pnMin)
                        % if so then set the position of the missing frames
                        fPosMd = roundP(median(fPosNw(~isN,:),1));
                        fPosNw(isN,:) = repmat(fPosMd,sum(isN),1);
                    else
                        % otherwise, set NaN's for all frames (positions
                        % are most likely false positives)                       
                        fPosNw(~isN,:) = NaN;
                        obj.trObj.mFlag{obj.iPh,iApp}(iFly) = 0;
                    end
                end
            end
                
            % updates the position array
            for iFrm = 1:obj.nFrm
                obj.trObj.fPosL{obj.iPh}...
                    {iApp,iFrm}(iFly,:) = fPosNw(iFrm,:);
            end
            
        end        
           
        % --- performs a fine search of the potentially ambiguous locations
        function searchAmbigPos(obj,uData,iApp)
            
            % memory allocation
            pNw = [];
            iFrmG = obj.trObj.indFrm{obj.iPh};
            [iRow,iFrm,iDir] = deal(uData{1},uData{2},-1);
            iRT = obj.iMov.iRT{iApp}{iRow};
            obj.dScl = length(iRT)/2;
            
            % search in reverse direction if first frame is ambiguous
            if length(iFrm) == length(iFrmG)
                % case is there are no non-ambigious frame so exit (while
                % flagging that the region might have a stationary fly)
                obj.trObj.sFlagT{iApp}(iRow) = 2;
                return
            elseif iFrm(1) == 1
                [iFrm,iDir] = deal(flip(iFrm),1); 
            end            

            % ---------------------------------- %
            % --- SUBSEQUENT FRAME DETECTION --- %
            % ---------------------------------- %            
            
            % initialisations
            isInit = true;            
            xiFL = iFrm(1) + [0,iDir];
            dnFrm = min(64,2^(nextpow2(diff(obj.trObj.indFrm{1}(1:2)))-1));
            
            % retrieves the initial raw/residual images
            iFrmL = iFrmG(xiFL);          
            ImgL0 = cellfun(@(x)(x(iRT,:)),obj.IL{iApp}(xiFL),'un',0);
            ImgR0 = cellfun(@(x)(x(iRT,:)),obj.IR(xiFL),'un',0);
            
            % keep looping while the limit size is greater than tolerance
            while true
                diFrm = abs(diff(iFrmL));
                if diFrm == 1
                    break
                end
                
                % determines the new video frame index
                if isInit
                    % reduces step size (if greater than limit size)
                    if diFrm <= dnFrm
                        dnFrm = 2^(nextpow2(diFrm)-1);
                    end
                    
                    % calculates the new frame index
                    iFrmNw = iFrmL(1) + iDir*dnFrm; 
                else
                    % otherwise, calculate the bisecting value
                    iFrmNw = roundP(mean(iFrmL));
                end                
                
                % sets the new frame image/residuals
                [ImgR,ImgL] = obj.setupResidualImage(iFrmNw,iApp,iRow);
                BNw = obj.getThresholdBinary(ImgR,iRow);
                iNw = 1 + any(BNw(:));
                                
                % updates the frame limits (based on whether the new 
                % residual meets tolerance)
                iFrmL(iNw) = iFrmNw;
                if iNw == 2
                    % if so, then update the raw/residual images
                    isInit = false;
                    [ImgR0{iNw},ImgL0{iNw}] = deal(ImgR,ImgL);                    

                    % if the frame difference is less than tolerance, then
                    % determine the location of the high value residual
                    if diFrm <= obj.nFrmAdd
                        if isempty(pNw)
                            pNw = getMaxCoord(ImgR);
                        else
                            pNw = obj.getLikelyPos(ImgR,BNw,pNw,obj.dScl/2);
                        end
                    end
                end
            end
            
            % sets the new/current coordinates and calculates the distance
            % between the these two points
            if isempty(pNw); pNw = getMaxCoord(ImgR); end
            pPr = obj.trObj.fPosL{obj.iPh}{iApp,iFrm(1)}(iRow,:);
            if pdist2(pNw,pPr) > obj.dScl            
                % if the distance between the points is large, then
                % reassign the points (find the point with the highest
                % residual/raw image ratio)
%                 pPr = obj.resetFramePos(ImgL0{1},ImgR0{1},pNw,iApp,iRow);
%                 obj.trObj.fPosL{obj.iPh}{iApp,iFrm(1)}(iRow,:) = pPr;
                obj.trObj.fPosL{obj.iPh}{iApp,iFrm(1)}(iRow,:) = pNw;
            end
                
            % exits the function (if only one frame is ambiguous)
            if (length(iFrm) == 1); return; end
            
            % ---------------------------------- %
            % --- SUBSEQUENT FRAME DETECTION --- %
            % ---------------------------------- %
            
            % keep performing the search until proper 
            for i = 2:length(iFrm) 
                % current frame object position
                j = iFrm(i);
                pPr = obj.trObj.fPosL{obj.iPh}{iApp,j}(iRow,:);                
                
                % if the distance between the points is high, then
                % determine the most likely point closest to the previous
                if pdist2(pNw,pPr) > obj.dScl                    
%                     [ILnw,IRnw] = deal(obj.IL{j}(iRT,:),obj.IR{j}(iRT,:));
%                     pPr = obj.resetFramePos(ILnw,IRnw,pNw,iApp,iRow);
%                     obj.trObj.fPosL{obj.iPh}{iApp,j}(iRow,:) = pPr; 
                    obj.trObj.fPosL{obj.iPh}{iApp,j}(iRow,:) = pNw; 
                end
                
%                 % resets the previous 
%                 pPr = pNw;
            end
            
        end  
        
        % --- resets the frame position which is most likely closest
        %     to the point, pNw
        function pPr = resetFramePos(obj,ImgL0,ImgR0,pNw,iApp,iRow)
        
            % determines the likely object position
            Q = ImgR0./max(obj.pLo,ImgL0);
            pPr = obj.getLikelyPos(Q,[],pNw,obj.dScl/2);
            
            % darkens the other regions not part of the point
            B0 = ImgR0 > obj.QmxTol/2;
            [~,BNw] = detGroupOverlap(B0,setGroup(pPr,size(B0)));
            BRmv = xor(BNw,B0);
            
            % retrieves the background image for the tube region 
            iRT = obj.iMov.iRT{iApp}{iRow};
            IbgTL = obj.IbgT{iApp}(iRT,:);            
            
            % enhances/de-enhances the background image
            IbgTL(BNw) = min(255,IbgTL(BNw) + obj.QmxTol/4);
            IbgTL(BRmv) = max(0,IbgTL(BRmv) - obj.QmxTol/2);
            obj.trObj.iMov.Ibg{obj.iPh}{iApp}(iRT,:) = IbgTL;
            
        end
        
        % ------------------------------------------ %
        % --- FLY TEMPLATE CALCULATION FUNCTIONS --- %
        % ------------------------------------------ %        
        
        % --- sets up the residual image
        function [ImgR,ImgL] = setupResidualImage(obj,iFrm,iApp,iRow)
            
            % sets the row indices            
            [iR,iC] = deal(obj.iMov.iR{iApp},obj.iMov.iC{iApp});
            iRT = obj.iMov.iRT{iApp}{iRow};
            
            % reads/sets the sub-region image and calculates the residual
            obj.trObj.stopUpdate = true;
            Img = obj.trObj.getImageStack(iFrm,1,1);
            ImgL0 = calcHistMatchStack({Img(iR,iC)},obj.IRef);
            obj.trObj.stopUpdate = false;
            
            % applies the smooth filter (if specified)
            if obj.trObj.useFilt
                ImgL0 = imfiltersym(ImgL0{1},obj.trObj.hS);
            else
                ImgL0 = ImgL0{1};
            end
            
            % sets the sub-region raw/residual images
            ImgL = ImgL0(iRT,:);
            ImgR0 = obj.calcImageResidual({ImgL},obj.IbgT{iApp}(iRT,:)); 
            ImgR = ImgR0{1};
            
        end                        
        
        % --- calculates the threshold binary
        function B = getThresholdBinary(obj,I,iApp)
            
            if length(obj.QmxTol) == 1
                B = I > obj.QmxTol;
            else
                B = I > obj.QmxTol(iApp);
            end
            
        end        
                        
        % --- removes the region from the
        function removeBackgroundBlob(obj,fPosL,iApp,iRow)
            
            % field retrieval
            N = ceil((size(obj.hC{iApp},1) - 1)/2);
            iRT = obj.iMov.iRT{iApp}{iRow};
            ILL = repmat({obj.IbgT{iApp}(iRT,:)},length(fPosL),1);
            
            % removes the blobs from the background estimate
            IbgTL = obj.trObj.setupBGEstStack(ILL,fPosL,N);
            obj.IbgT{iApp}(iRT,:) = calcImageStackFcn(IbgTL,'max');
            
        end
        
        % --- calculates the distance tolerance value
        function dTolT = calcDistTol(obj)
            
            % calculates the distance tolerance
            if isempty(obj.iMov.szObj)
                dTolT = obj.dTol0;
            else
                % scales the value (if interpolating)
                dTolT = (3/2)*min(obj.iMov.szObj);                        
                if obj.nI > 0
                    dTolT = ceil(dTolT/obj.nI);
                end
            end
            
        end
        
        % --- calculates the movement range of the flies
        function D = calcMovementRange(obj,iApp)
            
            % field retrieval
            xiF = 1:getSRCount(obj.iMov,iApp);
            fPosL = obj.trObj.fPosL{obj.iPh}(iApp,:)';
            
            % calculates the movement range
            D = arrayfun(@(y)(max(range(...
                cell2mat(cellfun(@(x)(x(y,:)),fPosL,'un',0)),1))),xiF');
            
        end
        
        % --- sets the position vector for the fly at iApp/iTube
        function setObjPos(obj,fPosL,iApp,iTube)
            
            for i = 1:obj.nFrm            
                obj.trObj.fPosL{obj.iPh}{iApp,i}(iTube,:) = fPosL;
            end
                
        end  
        
    end
    
    % static class methods
    methods (Static)
        
        % --- calculates the max peak value with each sub-region
        function Zmx = getSubRegionValues(Z,iRT,fOK)
            
            % memory allocation
            Zmx = zeros(length(iRT),1);
            
            % determines the peaks
            [yPk,iPk] = findpeaks(Z);
            for j = find(fOK(:)')
                [~,iB] = intersect(iPk,iRT{j});
                if ~isempty(iB)
                    Zmx(j) = max(yPk(iB));
                end
            end
            
        end                
        
        % --- sets up the ambiguous frame index groups
        function iGrpA = setupSearchGroups(isAmbig,fOK)
           
            % determines the frame groupings for each fly
            isAmbig(~fOK,:) = false;
            A = cellfun(@getGroupIndex,num2cell(isAmbig,2),'un',0);
            indG = find(~cellfun(@isempty,A));
            
            % sets up the search group indices
            iGrpA = cell2cell(cellfun(@(i,x)([num2cell(i*...
                ones(size(x))),x]),num2cell(indG),A(indG),'un',0));
            
        end
        
        % --- calculates the image residual
        function IR = calcImageResidual(I,Ibg)
            
            hG = fspecial('gaussian');
            IR = cellfun(@(x)(imfilter(max(0,Ibg-x),hG)),I,'un',0);
%             IR = cellfun(@(x)(max(0,Ibg-x)),I,'un',0);
            
        end        
        
        % --- determines most likely location of the object on the new
        %     frame (based on the previous frame location)
        function pNw = getLikelyPos(ImgR,BR,pPr,Dscl)
            
            % initialisations
            pY = 10;
            if isempty(BR); BR = true(size(ImgR)); end
            
            % calculates the new frame regional maxima and object function
            iMx = find(imregionalmax(ImgR) & BR);
            [yMx,xMx] = ind2sub(size(ImgR),iMx);
            D = sqrt((xMx - pPr(1)).^2 + pY*(yMx - pPr(2)).^2);
            
            % returns the position of the most likely object
            Q = ImgR(iMx)./max(1,D/Dscl);
            iNw = argMax(Q);
            pNw = [xMx(iNw),yMx(iNw)];
            
        end
        
        % --- calculates the image stack statistics
        function P = calcImageStackStats(I)
            
            % calculates the frame stack mean/std dev values
            B = cellfun(@(x)(x>0),I,'un',0);
            
            % calculates the mean/std values
            P = struct('Imu',[],'Isd',[]);
            P.Imu = cellfun(@(x,y)(mean(x(y))),I,B);
            P.Isd = cellfun(@(x,y)(std(x(y))),I,B);            
            
        end       

        % --- 
        function [IRef,W] = calcWeightedRefImage(IL0)

            %
            IL0mn = cellfun(@(x)(mean(x(:))),IL0);

            %
            Z = (IL0mn - mean(IL0mn))/std(IL0mn);
            W0 = normpdf(Z);
            W = W0/sum(W0);

            % calculates the weighted mean reference image
            IRef = uint8(calcImageStackFcn(IL0,'weighted-sum',W));

        end

        % --- sets up the region map mask
        function Imap = setupRegionMap(iRT,sz)
            
            % memory allocation
            Imap = zeros(sz);
            
            % sets the region mapping values
            for i = 1:length(iRT)
                Imap(iRT{i},:) = i;
            end
            
        end        
        
    end
    
end
