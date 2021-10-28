classdef HVPhaseTrack < matlab.mixin.SetGet
    
    % class properties
    properties
        % main class fields
        iMov
        hProg
        Img
        pInt
        iFrmR
        iPara
        iPhase
        prData = [];
        
        % boolean/scalar flags
        is2D
        iFrm
        wOfs = 1;
        hasProg = false;
        calcOK = true;
        
        % dimensioning veriables
        nApp
        nTube
        nImg
        hProgN
        
        % important fields
        hS
        y0
        szObj
        vPh
        iPh
        fPos0
        
        % permanent calculated values
        IBG
        pBG
        pMax
        pMaxG
        IPos
        fPos
        fPosL
        fPosG
        Phi
        axR
        NszB
        iStatus
        Qmet
        
        % temporary object fields
        ImgMd
        ImdBG
        iImgBG
        ImdRL
        ImdR
        ImdL
        IL
        iGrpP
        zGrpP
        BrmvBG
        indC
        
        % optimal gaussian parameter fields
        pOpt
        Iopt
        Bopt
        
        % other parameters
        rTol0 = 0.5;
        gpTol = 90;
        pTolR = 0.35;
        mxTol = 0.5;
        dTol = 5;
        wSz = 8;
        pTol = 0.4;
        abTol = 0.75;
        xcTol = 0.525;
        
    end
    
    % class methods
    methods
        % class constructor
        function obj = HVPhaseTrack(iMov,hProg)
            
            % sets the class fields
            obj.iMov = iMov;
            
            % sets the other class fields (if provided)
            if exist('hProg','var')
                obj.hProg = hProg;
                obj.hasProg = true;
            end
            
            % object dimensions
            obj.nApp = length(iMov.iR);
            obj.nTube = getSRCountVec(iMov);
            obj.nImg = length(obj.Img);
            obj.is2D = obj.iMov.is2D;
            
            % sets the tube-region offsets
            obj.y0 = cell(obj.nApp,1);
            for iApp = find(obj.iMov.ok(:)')
                obj.y0{iApp} = cellfun(@(x)(x(1)-1),obj.iMov.iRT{iApp});
            end
            
            % initialises the parameter struct
            obj.initParaStruct();
            
            % sets the object size
            if isfield(obj.iMov,'szObj')
                obj.szObj = obj.iMov.szObj;
            end
            
        end
        
        % ---------------------------- %
        % --- MAIN SOLVER FUNCTION --- %
        % ---------------------------- %
        
        % --- runs the main detection algorithm
        function runDetectionAlgo(obj)            
            
            % field updates and other initialisations
            obj.nImg = length(obj.Img);
            
            % initialises the solver fields
            obj.initObjectFields();            
            obj.calcFullObjPos();
            
            % calculates the global coordinates & performs housekeeping
            obj.calcGlobalCoords();
            obj.performHouseKeepingOperations();
            
        end
        
        % --- initialises the solver fields
        function initObjectFields(obj)
            
            % flag initialisations
            obj.calcOK = true;
            
            % permanent field memory allocation
            obj.IPos = cell(obj.nApp,obj.nImg);
            obj.fPos = cell(obj.nApp,obj.nImg);
            obj.iStatus = ~obj.iMov.flyok*3;
            
            % orientation angle memory allocation
            if obj.iMov.calcPhi
                obj.Phi = cell(obj.nApp,obj.nImg);
                obj.axR = cell(obj.nApp,obj.nImg);
                obj.NszB = cell(obj.nApp,obj.nImg);
            end
            
            % sets the empty field to a NaN
            if isempty(obj.szObj)
                obj.szObj = NaN;
            end            
            
            % sets up the image filter (if required)
            [bgP,obj.hS] = deal(obj.iMov.bgP.pSingle,[]);
            if isfield(bgP,'useFilt')
                if bgP.useFilt
                    obj.hS = fspecial('disk',bgP.hSz);
                end
            end
            
            % initialises the progressbar (if one is not provided)
            if ~obj.hasProg; obj.initProgBar(); end
            
        end
        
        % ----------------------------- %
        % --- MAIN SOLVER FUNCTIONS --- %
        % ----------------------------- %        
        
        % --- runs the initial position estimation function
        function calcFullObjPos(obj)
            
            % updates the progressbar
            obj.updateProgBar(1,'Stack Segmentation Intialisation...',0);
            
            % sets the flags for the rejected/empty regions
            obj.iStatus(obj.iStatus==0) = 2;
            obj.iStatus(~obj.iMov.flyok) = 3;
            
            % allocates memory for the positional coordinates
            obj.fPos = repmat(arrayfun(@(x)...
                            (NaN(x,2)),obj.nTube(:),'un',0),1,obj.nImg);
            obj.IPos = repmat(arrayfun(@(x)...
                            (NaN(x,2)),obj.nTube(:),'un',0),1,obj.nImg);                        
            
            % calculates the object locations over all regions/frames
            for iApp = find(obj.iMov.ok(:)')
                % updates the progressbar
                wStr = sprintf(...
                    'Object Detection (Region %i of %i)',iApp,obj.nApp);
                if obj.updateProgBar(2,wStr,iApp/(1+obj.nApp))
                    % if the user cancelled, then exit
                    obj.calcOK = false;
                    return
                end
                
                % segments the region
                obj.segmentRegions(iApp);                
                
            end
            
            % updates the progressbar
            obj.updateProgBar(1,'Stack Segmentation Complete',1);
            obj.updateProgBar(2,'All Region Segmented',1);
            
        end
        
        % --- segments the all the objects for a given region
        function segmentRegions(obj,iApp)
            
            % initialisations
            imov = obj.iMov;
            iRT = imov.iRT{iApp};           
            y0L = [zeros(obj.nTube(iApp),1),obj.y0{iApp}(:)];
            
            % retrieves the global row/column indices
            nTubeR = getSRCount(obj.iMov,iApp);
            fok = obj.iMov.flyok(1:nTubeR,iApp);
            obj.dTol = max(obj.iMov.szObj);            
            
            % memory allocation
            xiF = obj.pInt.iFrm;
            fP0 = repmat({NaN(nTubeR,2)},1,obj.nImg);
            IP0 = repmat({NaN(nTubeR,1)},1,obj.nImg);            
            
            % sets up the region image stack
            ImgL = obj.setupRegionImageStack(iApp);

            % segments the location for each feasible sub-region
            for iTube = find(fok(:)')
                % sets the sub-region image stack
                ImgSR = cellfun(@(x)(x(iRT{iTube},:)),ImgL,'un',0);

                % calculates the x-correlation image stack
                ImgSeg = obj.setupXCorrStack(ImgSR);
                
                % calculates the estimate
                xI0 = obj.pInt.fPos{iApp}{iTube}(:,1);
                yI0 = obj.pInt.fPos{iApp}{iTube}(:,2) - y0L(iTube);                
                pEst = [interp1(xiF,xI0,obj.iFrmR,'pchip')',...
                        interp1(xiF,yI0,obj.iFrmR,'pchip')'];
                
                % segments the image stack
                [fP0nw,IP0nw] = obj.segSubRegion(ImgSeg,pEst);
                
                % sets the metric/position values
                for j = 1:obj.nImg
                    IP0{j}(iTube) = IP0nw(j);
                    fP0{j}(iTube,:) = fP0nw(j,:);
                end  
                
                % performs the orientation angle calculations (if required)
                if obj.iMov.calcPhi
                    % FINISH ME!
                    waitfor(msgbox('Finish Me!','Finish Me!','modal'))                    
                    
                    % creates the orientation angle object
                    phiObj = OrientationCalc(imov,...
                                            num2cell(IResL,2),fPos0,iApp);

                    % sets the orientation angles/eigan-value ratio
                    obj.Phi(iApp,:) = num2cell(phiObj.Phi,1);
                    obj.axR(iApp,:) = num2cell(phiObj.axR,1);
                    obj.NszB(iApp,:) = num2cell(phiObj.NszB,1);
                end                   
            end

            % converts the coordinates from sub-region to region
            obj.IPos(iApp,:) = IP0;
            obj.fPos(iApp,:) = cellfun(@(x)(x+y0L),fP0,'un',0);                        
            
        end
        
        % --- sets up the image stack for the region index, iApp
        function ImgL = setupRegionImageStack(obj,iApp)
            
            % sets the region row/column indices
            [iR,iC] = deal(obj.iMov.iR{iApp},obj.iMov.iC{iApp});             
            
            % calculates the background/local images from the stack                       
            ImgL = cellfun(@(I)(I(iR,iC)),obj.Img,'un',0);                          
            
            % removes the rejected regions from the sub-images
            Bw = getExclusionBin(obj.iMov,[length(iR),length(iC)],iApp);
            ImgL = cellfun(@(I)(I.*Bw),ImgL,'un',0);
            
        end              
        
        % --- segments a sub-region with a moving object
        function [fP,IP] = segSubRegion(obj,Img,pEst)            
            
            % memory allocation
            pW = 0.75;
            szL = size(Img{1});
            nFrm = length(Img);
            [fP,IP] = deal(NaN(nFrm,2),NaN(nFrm,1));
            Dscale = sqrt(prod(obj.iMov.szObj));
            
            % determines the regional maxima from the image stack
            iPmx = cellfun(@(x)(find(imregionalmax(x))),Img,'un',0);
            
            % determines the most likely object position over all frames
            for i = 1:nFrm                
                % sorts the maxima in descending order
                [Pmx,iS] = sort(Img{i}(iPmx{i}),'descend');
                pTolB = pW*Pmx(1);
                
                % calculates the locations of the local maxima
                [yP,xP] = ind2sub(szL,iPmx{i}(iS));
                Dest = pdist2(pEst(i,:),[xP(:),yP(:)])'/Dscale;                
                
                % determines how many prominent objects are in the frame
                ii = Pmx >= pTolB;
                if sum(ii) == 1
                    % case is there is only 1 prominent object
                    iMx = 1;
                else
                    % case is there are more than one prominent object
                    Z = Pmx(ii)./(1+Dest(ii));  
                    iMx = argMax(Z);
                end
                
                % sets the final positional/intensity values
                [fP(i,:),IP(i)] = deal([xP(iMx),yP(iMx)],Pmx(iMx));                
            end
            
        end        
        
        % --- sets up the x-correlation image stack from the stack, Img
        function ImgXC = setupXCorrStack(obj,Img)
            
            % ensures the images are stored in a cell array
            if ~iscell(Img); Img = {Img}; end
            
            % memory allocation
            tP = obj.iMov.tPara;
            ImgXC = cell(length(Img),1);
            
            % sets up the x-correlation image stack
            for i = 1:length(Img)
                % calculates the original cross-correlation image
                [Gx,Gy] = imgradientxy(Img{i});
                Ixc0 = max(0,calcXCorr(tP.GxT,Gx) + calcXCorr(tP.GyT,Gy));
                
                % calculates the final x-correlation mask
                if isempty(obj.hS)
                    ImgXC{i} = Ixc0/2;
                else
                    ImgXC{i} = imfilter(Ixc0,obj.hS)/2;
                end
            end
            
        end           
        
        % ----------------------- %
        % --- OLDER FUNCTIONS --- %
        % ----------------------- %             
        
        % --- calculates the sub-region image residual
        function IR = calcSubRegionRes(obj,I,iApp)
            
            IR = imfilter(I-obj.iMov.IbgT{iApp},obj.hG);
            IR(isnan(IR)) = 0;
            
        end
        
        % --- matches the residual blobs
        function [iGrpF,IRmx] = matchResBlobs(obj,IRT)
            
            % parameters
            pW = 0.25;
            
            % thresholds the image for each frame
            BwG = cellfun(@(x)(imregionalmax(x)),IRT,'un',0);
            iGrp = cellfun(@(B,x)(getGroupIndex...
                                (B.*(x>pW*max(x(:))))),BwG,IRT,'un',0);
            nGrp = cellfun(@length,iGrp);
            
            % if there are any ambiguous regions
            if any(nGrp > 1)
                % memory allocation
                sz = size(IRT{1});
                iGrpT = cell(length(iGrp),min(nGrp));
                IRmx0 = zeros(1,size(iGrpT,2));
                
                % retrieves coordinates of the blobs for each frame
                fGrpT = cellfun(@(I,x)(obj.ind2subC(sz,cellfun(@(y)...
                                (y(argMax(I(y)))),x))),IRT,iGrp,'un',0);
                            
                % reduces the residual blobs 
                for i = 1:size(iGrpT,2)
                    [iGrpT(:,i),iGrp,fGrpT] = ...
                                           obj.reduceResBlobs(iGrp,fGrpT);
                    IRmx0(i) = mean(cellfun(@(I,x)(max(I(x))),...
                                           IRT(:),cell2cell(iGrpT(:,i))));
                end
                
                % returns the groupings with the highest residuals
                iGrp = iGrpT(:,argMax(IRmx0));             
            end
            
            % returns the maximum residual values for each blob
            iGrpF = cell2cell(iGrp);
            IRmx = cellfun(@(I,x)(max(I(x))),IRT(:),iGrpF);             
            
        end
        
        % --- reduces the residual blobs
        function [iGrpF,iGrp,fGrp] = reduceResBlobs(obj,iGrp,fGrp)
            
            % determines the unique frame groups
            nGrp = cellfun(@length,iGrp);
            indG = double(nGrp == 1);
            
            % if there are no unique frames, then use the first group
            if sum(indG) == 0; indG(1) = 1; end
            
            % loop through each of the ambiguous regions
            jGrp = getGroupIndex(indG==0);
            for i = 1:length(jGrp)
                % 
                if jGrp{i}(1) == 1
                    kGrp = [jGrp{i}(end)+1;flip(jGrp{i})];
                else
                    kGrp = [jGrp{i}(1)-1;jGrp{i}];
                end
                
                % determines the blobs which have the shortest distance
                % between frames 
                fP0 = fGrp{kGrp(1)}(indG(kGrp(1)),:);
                for j = 2:length(kGrp)    
                    % calculates the distance between the previous and
                    % current frame blobs
                    fPnw = fGrp{kGrp(j)};
                    D = pdist2(fP0,fPnw);
                    
                    % determines the blob with the shortest distance
                    indG(kGrp(j)) = argMin(D);
                    fP0 = fPnw(indG(kGrp(j)),:);
                end
            end
            
            % removes the optimal path grouping from the groups
            iKeep = arrayfun(@(n,x)(setGroup(x,[1,n])),nGrp,indG,'un',0);
            iGrpF = cellfun(@(x,i)(x(i,:)),iGrp,iKeep,'un',0);
            
            %
            iGrp = cellfun(@(x,i)(x(~i)),iGrp,iKeep,'un',0);
            fGrp = cellfun(@(x,i)(x(~i,:)),fGrp,iKeep,'un',0);
            
        end        
        
        % --- calculates the global coords from the sub-region reference
        function calcGlobalCoords(obj)
            
            % exit if not calculating the background
            if ~obj.calcOK; return; end
            
            % memory allocation
            [~,nFrm] = size(obj.fPos);
            [obj.fPosG,obj.fPosL] = deal(repmat(...
                arrayfun(@(x)(NaN(x,2)),obj.nTube,'un',0),1,nFrm));
            
            % converts the coordinates from the sub-region to global coords
            for iApp = find(obj.iMov.ok(:)')
                % calculates the x/y offset of the sub-region
                xOfs = obj.iMov.iC{iApp}(1)-1;
                yOfs = obj.iMov.iR{iApp}(1)-1;
                pOfsL = [zeros(obj.nTube(iApp),1),obj.y0{iApp}(:)];
                
                % calculates the global offset and appends it to each frame
                pOfs = repmat([xOfs,yOfs],obj.nTube(iApp),1);
                for i = 1:nFrm
                    % calculates the sub-region/global coordinates
                    obj.fPosL{iApp,i} = obj.fPos{iApp,i} - pOfsL;
                    obj.fPosG{iApp,i} = obj.fPos{iApp,i} + pOfs;                    
                end
            end
            
        end
        
        % ---------------------------------------- %
        % --- STATIC LIKELY POINT CALCULATIONS --- %
        % ---------------------------------------- %
        
        % --- calculates the location of the likely points for frame, iImg
        function calcStaticLikelyPoints(obj)
            
            % if the user has cancelled, then exit
            if ~obj.calcOK; return; end
            
            % initialisations
            imov = obj.iMov;
            fok = imov.flyok;
            h0 = getMedBLSize(imov);
            
            % memory allocation
            [obj.ImdR,obj.ImdRL] = deal(cell(obj.nImg,1));
            
            % updates the progress bar main-field
            obj.updateProgBarMain(3,'Calculating Filtered Residual Images');
            obj.updateProgBarSub('Frame',0)
            obj.setProgBarSubN(obj.nImg);
            
            %
            [iR,iC] = deal(imov.iR,imov.iC);
            nAppB = num2cell(1:length(iR));
            obj.Bw = cellfun(@(ir,ic,i)(getExclusionBin(imov,...
                [length(ir),length(ic)],i)),iR,iC,nAppB,'un',0);
            
            % calculates the
            [obj.ImgMd,obj.ImdBG] = ...
                removeImageMedianBL(obj.Img,obj.vPh==1,obj.is2D,h0);
            
            % calculates the residual images
            for iImg = 1:obj.nImg
                % updates the progressbar sub-field
                obj.updateProgBarSub('Frame',iImg)
                if ~obj.calcOK
                    % if the user cancelled, then exit
                    return
                end
                
                % calculates the filtered residual images
                obj.calcFilteredResidualImages(iImg);
                
                % sets the local filtered images
                obj.ImdL(:,iImg) = cellfun(@(ir,ic,B)...
                    (obj.ImdR{iImg}(ir,ic).*B),iR,iC,obj.Bw,'un',0);
            end
            
            % updates the sub-field progress-bar
            obj.updateProgBarSub('Frame')
            pause(0.01);
            
            % updates the progressbar main-field
            obj.updateProgBarMain(4,'Calculating Static Object Locations');
            obj.updateProgBarSub('Region',0)
            obj.setProgBarSubN(obj.nApp);
            
            % calculates the likely points for each sub-region
            for iApp = find(obj.iMov.ok(:)')
                % updates the progressbar sub-field
                obj.updateProgBarSub('Region',iApp);
                if ~obj.calcOK
                    % if the user cancelled, then exit
                    return
                end
                
                % calculations only necessary if there are static objects
                isStatic = (obj.iStatus(:,iApp) ~= 1) & fok(:,iApp);
                if any(isStatic)
                    for iImg = 1:obj.nImg
                        obj.pMax{iApp,iImg} = ...
                            obj.calcStaticRegionLikelyPoints(iImg,iApp);
                    end
                    
                    % aligns all the stationary points over all frames
                    obj.alignStaticObjects(iApp)
                end
            end
            
            % updates the progressbar
            obj.updateProgBarSub('Region')
            
        end
        
        % --- calculates the the likely points for sub-region, iApp
        function pMaxNw = calcStaticRegionLikelyPoints(obj,iImg,iApp)
            
            % initialisations
            iRT = obj.iMov.iRT{iApp};
            Imd_L = obj.ImdL{iApp,iImg};
            Imd_RL = obj.ImdRL{iImg}(:,iApp);
            
            % retrieves the tube-region images
            Imd_RT = cell2cell(cellfun(@(ir)(cellfun(@(x)...
                (x(ir,:)),Imd_RL','un',0)),iRT,'un',0));
            
            % calculates the normalised image for each tube-region
            IT = cellfun(@(ir)(Imd_L(ir,:)),iRT,'un',0);
            ITN = cellfun(@(x)(max(0,x/min(x(:)))),IT,'un',0);
            
            % normalises the images for each sub-region
            In = cellfun(@(y)(cellfun(@(x)(normImg(...
                imfilter(x,obj.hG))),y,'un',0)),...
                num2cell([Imd_RT,ITN],2),'un',0);
            
            % determines the likely object for all tube regions
            pMaxNw = obj.pMax{iApp,iImg};
            for iT = 1:obj.nTube(iApp)
                if obj.iMov.flyok(iT,iApp) && (obj.iStatus(iT,iApp) ~= 1)
                    pMaxNw{iT} = obj.calcSubRegionLikelyPoints(In{iT});
                end
            end
        end
        
        % --- retrieves the tube regions binaries
        function pMaxF = calcSubRegionLikelyPoints(obj,I)
            
            % distance tolerance
            sz = size(I{1});
            if ~isfield(obj.iMov,'szObj')
                Dtol = 5;
            else
                Dtol = min(obj.iMov.szObj/2);
            end            
            
            % calculates the distances between the regional maxima from
            % each of the metric images
            for i = 1:length(I)
                % calculates the regional maxima for the current frame
                iP = find(imregionalmax(I{i}));
                [yP,xP] = ind2sub(sz,iP); 
                pMxNw = [xP,yP];
                
                % calculates the distances between points relative to first
                if i == 1
                    % memory allocation
                    [iMxT,IMxT] = deal(NaN(length(xP),length(I)));                    
                    pMxT = NaN([length(xP),2,length(I)]);
                    
                    % sets the maxima image values/coordinates
                    iMxT(:,i) = 1:length(xP);
                    IMxT(:,i) = I{i}(iP);
                    pMxT(:,:,i) = pMxNw;
                else
                    % determines the distance from the current/first image
                    % maxima and determines which are within tolerance
                    D = pdist2(pMxT(:,:,1),pMxNw); 
                    [Dmn,imn] = min(D,[],2);
                    ii = Dmn <= Dtol;
                    
                    % sets the feasible index/image values
                    iMxT(ii,i) = imn(ii);
                    IMxT(ii,i) = I{i}(iP(iMxT(ii,i)));
                    pMxT(ii,:,i) = pMxNw(iMxT(ii,i),:);
                end
            end
            
            % calculates the mean coordinate/peak values
            pMx = roundP(nanmean(pMxT,3));
            [IMx,iS] = sort(nanmean(IMxT,2),'descend');
            pMx = pMx(iS,:);
            
            % removes any non-significant points
            ii = IMx/max(IMx) > obj.pTolR;
            [pMx,IMx] = deal(pMx(ii,:),IMx(ii));
            if size(pMx,1) == 1
                % if there is a unique solution then exit
                pMaxF = pMx;
                return
            end
            
            % determines if any maxima are close to each other
            dTolSz = 2*Dtol;
            DMx = pdist2(pMx,pMx);
            DMx(logical(eye(size(DMx)))) = dTolSz+1;
            [yy,xx] = find(DMx<=dTolSz);
            
            % determines if the close points are actually connected groups
            if ~isempty(xx)
                % determines the indices of points that are close
                iMx = sub2ind(sz,pMx(:,2),pMx(:,1));
                Imean = calcImageStackFcn(I,'mean');
                
                % determines the search indices
                [ii,jj] = obj.getSearchIndices(yy,xx);
                for i = 1:length(ii)
                    kk = [ii(i),jj(i)];
                    if ~any(isnan(pMx(kk,1)))
                        % calculates max non-connecting tolerance values
                        mxThresh = obj.getBinThreshold(Imean,iMx(kk));
                        
                        % if the ratio of the non-connecting tolerances to
                        % the max value is high, then the groups are
                        % probably connected
                        if mxThresh/max(IMx(kk)) > obj.mxTol
                            % if oonnected then use the point with the
                            % higher pixel value
                            jMx = argMax(IMx(kk));
                            pMx(kk(1),:) = pMx(kk(jMx),:);
                            pMx(kk(2),:) = NaN;
                        end
                    end
                end
            end
            
            % removes any combined points
            pMaxF = pMx(~isnan(pMx(:,1)),:);
            
        end
        
        % --- aligns all the stationary points over all frames
        function alignStaticObjects(obj,iApp)
            
            % if there is only one image then exit
            if obj.nImg == 1
                return
            end
            
            % retrieves the potential
            if size(obj.pMax,2) == 1
                pMaxApp = obj.pMax{iApp,1}(:);
                
            else
                pMaxTmp = cellfun(@(x)(x(:)),obj.pMax(iApp,:),'un',0);
                pMaxApp = cell2cell(pMaxTmp,0);
            end
            
            % determines the tube regions that need to be updated
            fok = obj.iMov.flyok(:,iApp);
            iTubeS = find((obj.iStatus(:,iApp)==0) & fok);
            
            % determines the object's size for distance purposes
            if isnan(obj.szObj)
                try
                    obj.optObjectShape(pMaxApp,iApp);
                catch
                    % FIGURE OUT THIS ERROR?!
                    obj.szObj = 10*[1,1];
                end
            end
            
            % calculates the distance tolerance
            dTolMax = max(obj.szObj);
            
            %
            for iT = iTubeS(:)'
                % loop initialisations
                pMaxT = pMaxApp(iT,:);
                indD = NaN(size(pMaxT{1},1),length(pMaxT)-1);
                
                % calculates the distance between points (between frames)
                D = cellfun(@(x)(pdist2(pMaxT{1},x)),pMaxT(2:end),'un',0);
                
                % determines the which points are coincident between frames
                for j = 1:length(D)
                    for i = 1:size(D{j},2)
                        % determines the distance between points
                        [Dmn,imn] = min(D{j}(:,i));
                        if Dmn <= dTolMax
                            indD(imn,j) = i;
                        end
                        
                        % removes the matching points from the search
                        D{j}(imn,:) = dTolMax + 1;
                    end
                end
                
                % resets all the points so they align between frames
                ii = all(~isnan(indD),2);
                if ~any(ii)
                    % if there is no feasible alignment, then the region is
                    % probably empty?
                    obj.iStatus(iT,iApp) = 3;
                    pMaxApp(iT,:) = {[]};
                else
                    %
                    pMaxT{1} = pMaxT{1}(ii,:);
                    for j = 1:size(indD,2)
                        pMaxT{j+1} = pMaxT{j+1}(indD(ii,j),:);
                    end
                    
                    % resets the values into the array
                    pMaxApp(iT,:) = obj.matchPrevPos(pMaxT,[iApp,iT]);
                end
            end
            
            % resets the values into the class field
            for iImg = 1:size(pMaxApp,2)
                obj.pMax{iApp,iImg} = pMaxApp(:,iImg);
            end
            
        end
        
        % --- matches the static objects from the previous phase
        function pMaxNw = matchPrevPos(obj,pMaxNw,ind)
            
            % if there is no previous solution then exit
            if isempty(obj.prData)
                return
            else
                [iApp,iT] = deal(ind(1),ind(2));
                if obj.iStatus(iT,iApp) == 1
                    % if the object has been determined to have moved, then
                    % exit the function
                    return
                end
            end
            
            % parameters
            if isnan(obj.szObj)
                Dtol = 5;
            else
                Dtol = max(obj.szObj/2);
            end
            
            % memory allocation & initialisations
            nImgP = length(pMaxNw);
            [Dmn,imn] = deal(zeros(nImgP,1));
            fPos0 = obj.prData.fPos{iApp}(iT,:) - [0,obj.y0{iApp}(iT)];
            
            % determines if there are any close points to the previous
            for i = 1:nImgP
                [Dmn(i),imn(i)] = min(pdist2(fPos0,pMaxNw{i}));
            end
            
            if all(Dmn <= Dtol)
                % if so, then use that solution
                for i = 1:nImgP
                    pMaxNw{i} = pMaxNw{i}(imn(i),:);
                end
            end
            
        end
        
        % ------------------------------------------------- %
        % --- LIKELY STATIC BLOB DETECTION CALCULATIONS --- %
        % ------------------------------------------------- %
        
        function fPos0 = convertLikelyPosCoord(obj,iApp)
            
            % initialisations
            fPos0 = obj.pMax(iApp,:);
            yOfs = num2cell(obj.y0{iApp});              
            
            % converts the coordinates for all sub-regions to region coords
            for i = 1:length(fPos0)
                % determines the sub-regions with valid objects detected
                isOK = ~cellfun(@isempty,fPos0{i});
                
                % converts the valid regions from sub-region to region
                % coordinates (sets NaN values for the invalid regions)
                fPos0{i}(isOK) = cellfun(@(x,y)(roundP(x+repmat([0,y],...
                          size(x,1),1))),fPos0{i}(isOK),yOfs(isOK),'un',0);
                fPos0{i}(~isOK) = {NaN(1,2)};
            end
            
        end
        
        % --- calculates the most likely point groupings
        function calcFramePointGroupings(obj)
            
            % if the user cancelled, then exit
            if ~obj.calcOK; return; end
            
            % updates the progressbar fields
            obj.updateProgBarMain(5,'Calculating Likely Objects');
            obj.updateProgBarSub('Region',0)
            obj.setProgBarSubN(obj.nApp);
            
            % determines the object's size for distance purposes
            if isnan(obj.szObj)
                pMaxTmp = cellfun(@(x)(x(:)),obj.pMax(1,:),'un',0);
                pMaxApp = cell2cell(pMaxTmp,0);
                obj.optObjectShape(pMaxApp,1);
            end
            
            % loops through each region calculating the likely blobs
            for iApp = find(obj.iMov.ok(:)')
                % retrieves the median filtered image
                Iapp = obj.getRegionImageStack(obj.ImdR,iApp);                                
                
                % converts the likely coordinates to region coordinate                
                fPos0 = obj.convertLikelyPosCoord(iApp);
                
                % retrieves the indices of all potential blobs over all the
                % frames in the image stack
                iGrp = obj.detAllObjectBlobs(Iapp,fPos0,iApp);
                if isempty(iGrp)
                    % if the user cancelled, then exit
                    return
                end     
                
                % sets the region image stack based on the phase type
                if obj.vPh == 1
                    % case is a low-variance phase
                    IappF0 = obj.getRegionImageStack(obj.Img,iApp);
                    IappF = obj.equaliseImageStack(IappF0,iApp);
                else
                    IappF = Iapp;
                end                
                
                % determines the likely static blobs for each subregion
                obj.detLikelyStaticBlobs(IappF,iGrp,fPos0,iApp);
            end
            
            % updates the progressbar fields
            obj.updateProgBarSub('Region')
        end
        
        % --- determines the likely static sub-region blobs for the region
        function detLikelyStaticBlobs(obj,Iapp,iGrp,fPos0,iApp)
            
            function Imap = createLabelMap(iGrp,sz)
                
                % memory allocation              
                Imap = zeros(sz);
                iGrp = iGrp(~cellfun(@isempty,iGrp));                
                
                % sets the map values for each non-empty blob
                for j = 1:length(iGrp)
                    Imap(iGrp{j}) = j;
                end
                
            end
            
            % initialisations
            sz = size(Iapp{1});
            nFly = length(fPos0{1});
            del = getSubImageDim(obj);
            Ngrp = cellfun(@(x)(sum(~isnan(x(:,1)))),fPos0{1}(:));
            fok = obj.iMov.flyok(:,iApp);
            xiF = (1:nFly)';
            
            % sets up the blob binary masks for each frame
            Bmap = cellfun(@(x)(createLabelMap(x,sz)),iGrp,'un',0);
            Brmv = cellfun(@(x)(x>0),Bmap,'un',0);
            
            % calculates the mean image/blob binary mask over all frames
            IappT = calcImageStackFcn(Iapp);
            BrmvT = bwmorph(calcImageStackFcn(Brmv) == 1,'dilate');
            IBG0 = obj.setupBGImage(IappT,BrmvT);
            IappR = IBG0 - IappT;
            
            % sets up the global indices for each sub-region
            Ns = [0;cumsum(Ngrp)];
            indG0 = cell2mat(arrayfun(@(x,y,z)...
                ([z*ones(y-x+1,1),(x:y)']),...
                Ns(1:end-1)+1,Ns(2:end),xiF,'un',0));
            
            % ----------------------------------- %
            % --- SUB-REGION IMAGE RETRIEVAL  --- %
            % ----------------------------------- %
            
            % determines the indices of each point
            fP = cellfun(@cell2mat,fPos0,'un',0);
            fPosX0 = cell2mat(cellfun(@(x)(roundP(x(:,1))),fP,'un',0));
            fPosY0 = cell2mat(cellfun(@(x)(roundP(x(:,2))),fP,'un',0));
            
            % calculates the mean position of each
            fPosX = roundP(mean(fPosX0,2));
            fPosY = roundP(mean(fPosY0,2));
            iPosT = sub2ind(sz,fPosY,fPosX);
            
            % determines the feasible points (only points which are within
            % the total binary mask on all frames)
            [isOK,ii] = deal(~isnan(iPosT));
            isOK(ii) = BrmvT(iPosT(ii));
            
            % ---------------------------------------- %
            % --- OPTIMAL STATIC BLOB CALCULATIONS --- %
            % ---------------------------------------- %
            
            if any(isOK)
                % initialisations
                isInit = true;
                iOK = find(isOK);
                fPosR = [fPosX(isOK),fPosY(isOK)];
                xi = num2cell(Bmap{1}(sub2ind(sz,fPosR(:,2),fPosR(:,1))));
                
                % ensures the global index array 
                indGT = NaN(length(isOK),2);
                indGT(ii,:) = indG0;                
                
                % retrieves the sub-regions                                
                IsubR = obj.getSubImage(IappR,fPosR,del,0);
                ImapR = obj.getSubImage(Bmap{1},fPosR,del,0);
                
                % only retrieve the sub-image corresponding to the maxima
                % point (removes other points)
                IsubR = cellfun(@(x,y,z)(x.*(y==z)),IsubR,ImapR,xi,'un',0);
                IsubMx = cellfun(@(x)(x(del+1,del+1)),IsubR); 
                
                % sets up the sub-region to global index array
                indG = [indGT(isOK,1),(1:size(fPosR,1))'];
                indSR = arrayfun(@(x)...
                    (indG(indG(:,1)==x,2)),xiF,'un',0);
                iBestPr = indG(:,2);
                
                % keep loopings until the best index array doesn't change
                while 1
                    % calculates the new optimal grouping
                    [iBest,indC0] = obj.detLikelyStaticBlobsSR...
                                            (IsubR,IsubMx,indSR,iBestPr);                    
                    if isInit
                        % flag that the loop is no longer initialising
                        isInit = false;
                    else
                        % otherwise, compare if the new best solution
                        % matches the previous. if so, then exit the loop
                        if nansum(abs((iBest-iBestPr))) == 0
                            obj.indC{iApp} = indC0;
                            break
                        end
                    end
                    
                    % resets the best index array
                    iBestPr = iBest;
                end
                
                % determines the global indices of the best blob for each
                % sub-region/row
                ii = ~isnan(iBest);
                jj = num2cell(ones(nFly,1)); 
                jj(ii) = cellfun(@(x,y)(find(x==y)),...
                            indSR(ii),num2cell(indG(iBest(ii),2)),'un',0);
                                    
                % sets the final (optimal) sub-region index array
                indSRF = arrayfun(@(x)(indG0(indG0(:,1)==x,2)),xiF,'un',0);                
                
                % resets the binary removal masks
                kk = ~cellfun(@isempty,indSRF);
                indF = cellfun(@(x,y)(x(y)),indSRF(kk),jj(kk));                
                Brmv = cellfun(@(x)(setGroup(x(indF),sz)),iGrp,'un',0);
                
            else
                % there are no valid static flies in this region
                iBest = NaN(nFly,1);
            end
            
            % sets the position values for each feasible sub-region
            for iFly = find(fok(:)')
                % sets the position values for each image in the stack
                for iImg = 1:obj.nImg
                    if isnan(iBest(iFly))
                        % case is the fly is non-static
                        pPosNw = obj.fPos{iApp,iImg}(iFly,:);
                        pPosNw(2) = pPosNw(2) + obj.y0{iApp}(iFly);
                    else
                        % case is the fly is static
                        indF = iOK(iBest(iFly));
                        pPosNw = [fPosX0(indF,iImg),fPosY0(indF,iImg)];
                    end
                    
                    % sets the positional values for the current frame
                    obj.fPos{iApp,iImg}(iFly,:) = pPosNw;
                end
            end
            
            % sets the binary masks of the final locations over all frames
            obj.BrmvBG{iApp} = cell(obj.nImg,1);
            for iImg = 1:obj.nImg
                % determines the linear indices of the blobs on this frame
                fP = obj.fPos{iApp,iImg}(fok,:);
                isOK = ~isnan(fP(:,1));
                iPos = sub2ind(sz,fP(isOK,2),fP(isOK,1));
                
                % determines blobs that overlap with the likely solution
                [~,Btmp] = detGroupOverlap(Brmv{iImg},setGroup(iPos,sz));
                obj.BrmvBG{iApp}{iImg} = Btmp;
            end
            
        end
        
        % --- retrieves all sub-images
        function Isub = getAllSubImages(obj,ImgL,pMaxL,dN,iApp,isNorm)
            
            % --- retrieves the sub-regions surrounding the points, pMax
            function Isub = getSubImages(I,pMax,dN)
                
                % initialisations
                [sz,nPts] = deal(size(I),size(pMax,1));
                
                % memory allocation
                Isub = repmat({NaN(2*dN+1)},nPts,1);
                
                % retrieves the valid sub-image pixels surrounding 
                % the max points
                for k = 1:nPts
                    % sets the row/column indices
                    iC = pMax(k,1) + (-dN:dN);
                    iR = pMax(k,2) + (-dN:dN);
                    
                    % determines which indices are valid
                    i1 = (iR >= 1) & (iR <= sz(1));
                    i2 = (iC >= 1) & (iC <= sz(2));
                    
                    % sets the valid points for the sub-image
                    Isub{k}(i1,i2) = I(iR(i1),iC(i2));
                end
                
            end
            
            % memory allocation
            Isub = cell(obj.nTube(iApp),obj.nImg);
            
            % retrieves the sub-images for each sub-region
            for i = 1:obj.nTube(iApp)
                % sets the sub-region y-offset
                pOfs = [0,obj.y0{iApp}(i)];
                
                % retrieves the sub-images for all points (across all
                % frames)
                for j = 1:obj.nImg
                    if ~isempty(pMaxL{i,j}) && ~isnan(pMaxL{i,j}(1))
                        pMaxT = roundP(pMaxL{i,j} + ...
                            repmat(pOfs,size(pMaxL{i,j},1),1));
                        Isub{i,j} = getSubImages(ImgL{j},pMaxT,dN);
                    end
                end
            end
            
            % if the images aren't to be normalised, then exit
            if ~isNorm; return; end
            
            % removes the non-conforming points from the images
            for i = 1:numel(Isub)
                for j = 1:length(Isub{i})
                    % removes all points that are:
                    %  - not part of the optimal binary
                    %  - NaN values
                    %  - have median image values > 0
                    Brmv = (Isub{i}{j}>=0) | isnan(Isub{i}{j});
                    Isub{i}{j}(Brmv) = 0;
                end
            end
            
            % calculates the metrics for each group
            ii = ~cellfun(@isempty,Isub);
            pMin = min(cellfun(@(x)(min(...
                cellfun(@(y)(min(y(:))),x))),Isub(ii)));
            
            for i = 1:numel(Isub)
                if ~isempty(Isub{i})
                    Isub{i} = cellfun(@(x)(x/pMin),Isub{i},'un',0);
                end
            end
            
        end
        
        % --- checks the stationary points are consistent
        function checkStationaryPoints(obj,iApp)
            
            % retrieves the locations of the
            fPosApp = obj.fPos(iApp,:);
            nFrmF = size(fPosApp,3);
            
            % determines the tube regions that need to be analysed
            fok = obj.iMov.flyok(:,iApp);
            iTubeS = find((obj.iStatus(:,iApp)==0) & fok);
            
            % for each sub-region where there was no moving object,
            % determine if the most likely points was indeed stationary
            for iT = iTubeS(:)'
                % retrieves the locations of the objects over all frames
                fPosT = cell2mat(cellfun(@(x)(x(iT,:)),fPosApp','un',0));
                if all(range(fPosT,1) <= obj.szObj)
                    % if the points close to each other, then is probably
                    % stationary. update status flag as such
                    obj.iStatus(iT,iApp) = 2;
                    
                else
                    % otherwise, determine which region is most likely to
                    % be the stationary object
                    dMetTX = pdist2(fPosT(:,1),fPosT(:,1));
                    dMetTY = pdist2(fPosT(:,2),fPosT(:,2));
                    [iGrp,isF] = deal([],false(size(fPosT,1),1));
                    
                    % groups the frames by metrics
                    for i = 1:size(dMetTX,2)
                        % determines which frames are grouped together
                        ii = (dMetTX(:,i) <= obj.szObj(1)) & ...
                            (dMetTY(:,i) <= obj.szObj(2)) & ~isF;
                        [iGrp{end+1},isF(ii)] = deal(find(ii),true);
                        
                        % if all frames are account for, then exit the loop
                        if all(isF); break; end
                    end
                    
                    % determines the most common solution
                    imx = argMax(cellfun(@length,iGrp));
                    pNw = mean(fPosT(iGrp{imx},:),1);
                    
                    % updates the flags
                    obj.iStatus(iT,iApp) = 2;               % set as 3?
                    for iImg = find(~setGroup(iGrp{imx},[1,nFrmF]))
                        obj.fPos{iApp,iImg}(iT,:) = pNw;
                    end
                end
            end
            
        end
        
        % --- equalises the image stack to 
        function IappF = equaliseImageStack(obj,IappF,iApp)
            
            % parameters
            pTolEq = 5;
            
            % determines which images are within tolerance of the average
            % pixel intensity of the sub-region
            Iavg = obj.iMov.ImnF{obj.iPh}(iApp);
            isOK = abs(cellfun(@(x)(nanmean(x(:))),IappF)-Iavg) < pTolEq;
            
            % if any are not within tolerance, then equalise the images
            if any(~isOK)
                % calculates the reference image 
                Iref = uint8(calcImageStackFcn(IappF(isOK),'mean'));
                
                % matches the histograms of the images
                for i = find(~isOK(:)')
                    IappF{i} = double(imhistmatch(uint8(IappF{i}),Iref));
                end
            end
            
        end
        
        % --------------------------------------- %
        % --- STATIC BLOB DETECTION FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- determines the indices of all blob objects (over all frames)
        function iGrp = detAllObjectBlobs(obj,Iapp,fPos0,iApp,updatePBar)
            
            % sets the default input arguments
            if ~exist('updatePBar','var'); updatePBar = true; end
            
            % memory allocation
            iGrp = cell(obj.nImg,1);
            
            % calculates the blob object binaries (for each frame)
            for i = 1:obj.nImg
                % updates the progress bar
                if updatePBar
                    dpW = i/(obj.nImg*obj.nApp);
                    obj.updateProgBarSub('Region',iApp,dpW);
                    if ~obj.calcOK
                        % if the user cancelled, then exit
                        iGrp = [];
                        return
                    end
                end                            
                
                % otherwise, detect the blob objects from the frame
                iGrp{i} = obj.detObjectBlobs(Iapp{i},fPos0{i});
            end
            
        end
        
        % --- determines the binary mask of all the blob objects
        function iGrp = detObjectBlobs(obj,I,fPos0)
            
            % converts the cell array to a numerical array
            sz = size(I);
            fP = cell2mat(fPos0);
            del = obj.getSubImageDim();            
            
            % resets the likely points to the maxima
            fP = obj.resetLikelyPos(I,fP,max(obj.szObj));           
            
            % removes the infeasible points
            isOK = ~isnan(fP(:,1));
            fP = roundP(fP(isOK,:));
            
            % memory allocation
            nBlob = size(fP,1);
            szL = (2*del+1)*[1,1];
            Isub = repmat({NaN(szL)},nBlob,1);
            [Pc,cLvl,iGrp] = deal(cell(nBlob,1));
            
            % sets up the binary image for object removal
            for i = 1:nBlob
                % sets the sub-image and local/global indices
                [Isub(i),indL,indG] = obj.getSubImage(I,fP(i,:),del,1);
                Imin = Isub{i}(del+1,del+1);
                
                % determines if there are any other points in the frame
                fPO = obj.detPointsInFrame(Isub{i},del/2);
                
                % calculates the contour levels
                [Pc{i},cLvl{i}] = ...
                    obj.getLargestFeasContour(Isub{i},Imin,fPO);
                
                if ~isempty(Pc{i})
                    % calculates the binary representing the contour region
                    PcR = roundP(Pc{i}{end});
                    Bc0 = setGroup(sub2ind(szL,PcR(:,2),PcR(:,1)),szL);
                    Bc = bwmorph(bwfill(Bc0,'holes'),'dilate');
                    Bc(isnan(Isub{i})) = false;
                    
                    % converts the blob local indices to the region frame
                    BcF = Bc(indL{1}{1},indL{1}{2});
                    pOfs = [indG{1}{2}(1),indG{1}{1}(1)]-1;
                    iGrp{i} = loc2glob(find(BcF),pOfs,sz,size(BcF));
                end
            end
            
        end
        
        % --------------------------------------------- %
        % --- BACKGROUND IMAGE ESTIMATION FUNCTIONS --- %
        % --------------------------------------------- %
        
        % --- calculates the background image estimates
        function estimateBGAll(obj)
            
            % if the user cancelled, then exit
            if ~obj.calcOK; return; end
            
            % updates the progressbar fields
            obj.updateProgBarMain(6,'Estimating Background Image');
            obj.updateProgBarSub('Region',0)
            obj.setProgBarSubN(obj.nApp);
            
            % ------------------------------------------------- %
            % --- LOW-VARIANCE BACKGROUND IMAGE CALCULATION --- %
            % ------------------------------------------------- %
            
            % estimates the low variance phase background (if required)
            if obj.vPh == 1
                % memory allocation
                [obj.IBG,obj.pBG] = deal(cell(1,obj.nApp));
                
                % calculates the average image stack across all frames
                for iApp = find(obj.iMov.ok(:)')
                    % updates the progressbar
                    obj.updateProgBarSub('Region',iApp)
                    if ~obj.calcOK
                        % if the user cancelled then exit the function
                        return
                    end
                    
                    % removes binary image of the image blobs
                    IappF0 = obj.getRegionImageStack(obj.Img,iApp);
                    [IappF,IappF0] = deal...
                                (obj.equaliseImageStack(IappF0,iApp));
                    
                    for iImg = 1:obj.nImg
                        IappF{iImg}(obj.BrmvBG{iApp}{iImg}) = NaN;
                    end
                    
                    % calculates the final background estimate
                    obj.IBG{iApp} = interpImageGaps...
                                        (calcImageStackFcn(IappF));
                    obj.pBG{iApp} = obj.calcResTolerance(IappF0,iApp);
                    
                end
                
                % clears the array
                clear IappF
                
            elseif obj.vPh == 2
                % calculates the average image stack across all frames
                for iApp = find(obj.iMov.ok(:)')
                    % sets
                    IappF = obj.getRegionImageStack(obj.ImgMd,iApp);
                    for iImg = 1:obj.nImg
                        IappF{iImg}(obj.BrmvBG{iApp}{iImg}) = NaN;
                    end
                    
                    % calculates the final background estimate
                    obj.iMov.IbgT{iApp} = ...
                            interpImageGaps(calcImageStackFcn(IappF));
                end
            end
            
        end
        
        % --- calculates the residual tolerances for each sub-region
        function pBG = calcResTolerance(obj,Iapp,iApp)
            
            % initialisations
            Brmv = obj.BrmvBG{iApp};
            iRT = obj.iMov.iRT{iApp};
            IappR = cellfun(@(x)(obj.IBG{iApp}-x),Iapp,'un',0); 
            nFlyS = max(20,roundP(sum(obj.Bopt(:))/4));
            
            % memory allocation
            nFly = length(iRT);
            pBG = NaN(nFly,1);
            
            % calculates the residual thresholds for each sub-region
            for i = 1:nFly
                if obj.iMov.flyok(i,iApp)
                    % retrieves the sub-region residual/binary images
                    BrmvL = cellfun(@(x)(x(iRT{i},:)),Brmv,'un',0);
                    IappRL = cellfun(@(x)(x(iRT{i},:)),IappR,'un',0);  

                    % calculates an estimate of the threshold
                    pBGnw = cellfun(@(I,B)...
                            (getNthSortedValue(I(B),nFlyS)),IappRL,BrmvL);
                    pBG(i) = nanmedian(pBGnw);
                end
            end
            
        end
        
        % --- determines if any of the stationary regions are empty
        function checkEmptyRegions(obj)
            
            % if the user cancelled, then exit
            if ~obj.calcOK; return; end
            
            % initialisations
            iOfs = 0;
            dN = max(obj.szObj);
            sz = (2*dN+1)*[1,1];
            indC0 = bwmorph(setGroup((dN+1)*[1,1],sz),'dilate');
            
            % updates the progressbar fields
            obj.updateProgBarMain(7,'Calculating Quality Measures');
            obj.updateProgBarSub('Region',0)
            obj.setProgBarSubN(obj.nApp)
            
            % memory allocation
            Imean = cell(1,obj.nApp);
            [Zmax,Zxc] = deal(NaN(max(obj.nTube),obj.nApp));
            
            % sets the raw/background images for the residual calculations
            if obj.vPh == 1
                [I,Ibg] = deal(obj.Img,obj.IBG);
            else
                obj.Qmet = ones(size(Zmax));
                return
            end
            
            % converts the position array so that the positions are now
            % grouped by sub-region
            for iApp = find(obj.iMov.ok(:)')
                % updates the progressbar
                obj.updateProgBarSub('Region',iApp)
                if ~obj.calcOK
                    % if the user cancelled then exit the function
                    return
                end
                
                % retrieves the location of all objects for current region
                [iR,iC] = deal(obj.iMov.iR{iApp},obj.iMov.iC{iApp});
                ILnw = cellfun(@(x)(Ibg{iApp}-x(iR,iC)),I,'un',0);
                fPosT = num2cell(cell2cell(cellfun(@(x)...
                    (num2cell(x,2)),obj.fPos(iApp,:),'un',0),0),2);
                
                % retrieves the sub-images surrounding each point
                A = cellfun(@(p)(cell2cell(cellfun(@(I,pp)...
                    (obj.getPointSubImage(I,roundP(pp),dN)),...
                    ILnw,p(:),'un',0))),fPosT,'un',0);
                A = cell2cell(A',0);
                
                % calculates the mean/max images across all stacks
                Imean{iApp} = cellfun(@(x)(calcImageStackFcn...
                    (x)),num2cell(A,1),'un',0);
                Imax = cellfun(@(x)(calcImageStackFcn...
                    (x,'max')),num2cell(A,1),'un',0);
                
                % calculates the cross-correlation distance between the
                % objects in each sub-region (over all frames)
                iNw = 1:obj.nTube(iApp);
                Zmax(iNw,iApp) = cellfun(@(x)(max(x(indC0))),Imax);
            end
            
            % updates the progressbar
            obj.updateProgBar(2,'Calculating Overall Scores',3/4);
            
            % calculates the inter-subregion cross-correlations
            Imean = cell2cell(Imean,0);
            ZxcT = nanmean(cell2mat(arrayfun(@(x)(cellfun(@(y)...
                (obj.calcMetrics(y,Imean{x})),Imean(:))),...
                1:length(Imean),'un',0)),1);
            
            % sets the values into the overall array
            for iApp = find(obj.iMov.ok(:)')
                iNw = 1:obj.nTube(iApp);
                Zxc(iNw,iApp) = ZxcT(iNw+iOfs);
                iOfs = iOfs+obj.nTube(iApp);
            end
            
            % calculates the total similarity metric (the closer the values
            % are to 1, the more likely they will resemble the median fly
            % object). excessively high values (>5?) indicate that the
            % object in that region does not represent the others
            ZxcN = Zxc/nanmedian(Zxc(:));
            ZmaxN = nanmedian(Zmax(:))./Zmax;
            obj.Qmet = ZxcN.*ZmaxN;
            
            % updates the progressbar
            obj.updateProgBar(2,'Phase Segmentation Complete!',1);
            
        end
        
        % ------------------------------------ %
        % --- IMAGE MANIPULATION FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- gets the image stack for the region, iApp
        function Iapp = getRegionImageStack(obj,I,iApp)
            
            [iR,iC] = deal(obj.iMov.iR{iApp},obj.iMov.iC{iApp});
            Iapp = cellfun(@(I)(I(iR,iC)),I,'un',0);
            
        end
        
        % --- optimises the shape function to the average image
        function optObjectShape(obj,pMaxApp,iApp,ImgL)
            
            % default input arguments
            if ~exist('ImgL','var'); ImgL = obj.ImdL(iApp,:); end
            
            % parameters
            dimgSz = 5;
            pTol0 = 0.05;
            pEdgeTol = 0.05;
            
            % retrieves the initial estimates of the
            [Iopt0,pOpt0] = deal(obj.Iopt,obj.pOpt);
            if isempty(Iopt0)
                imgSz = 5;
            else
                imgSz = (size(Iopt0,1)-1)/2;
            end
            
            %
            while 1
                % sets the sub-images for the
                Isub0 = cell2cell(...
                    obj.getAllSubImages(ImgL,pMaxApp,imgSz,iApp,0));
                
                % optimises the 2D gaussian image from the mean image
                pLim = cellfun(@(I)(min(I(:))),Isub0);
                [Iopt0,pOptNw] = opt2DGaussian(Isub0,pLim,pOpt0);                
                if isempty(Iopt0)
                    % if there was an issue, then increment the image size
                    imgSz = imgSz + dimgSz;                    
                else                                
                    % determines if the optimal binary intersects the edge
                    IoptNw = (1-normImg(Iopt0)).*(Iopt0<0);
                    BoptNw = bwmorph(IoptNw > pTol0,'majority');
                    Bedge = bwmorph(true(size(BoptNw)),'remove');
                    if mean(BoptNw(Bedge)) > pEdgeTol
                        % if so, then increment the image size
                        imgSz = imgSz + dimgSz;
                    else
                        % otherwise, exit the loop
                        break
                    end
                end
            end
            
            % sets the optimal image properties (first image only)
            [obj.Iopt,obj.pOpt,obj.Bopt] = deal(IoptNw,pOptNw,BoptNw);
            
            % sets the approximate fly size (if not set)
            [~,objBB] = getGroupIndex(BoptNw,'BoundingBox');
            obj.szObj = objBB([3,4]);
            
        end
        
        % --- calculates the residual images
        function calcFilteredResidualImages(obj,iImg)
            
            % --- calculates the filtered images based on the dimensions, hD
            function Ifilt = calcFilteredImage(I,hD)
                
                Ifilt = imfilter(I,fspecial('average',hD));
                
            end
            
            % dimensioning            
            iM = obj.iMov;
            nGrp = 1 + 2*is2DCheck(iM);
            Nr = mean(cellfun(@(x)(mean(cellfun(@length,x))),iM.iRT));
            N = 2*min(floor(Nr),obj.iPara.Nh) + 1;
            
            % calculates the median residual image
            Imd = -obj.ImgMd{iImg};
            Bmd = Imd < 0;
            
            % calculates the x, y and x/y filtered residual images
            Ir = cell(nGrp,1);
            Ir{1} = max(0,calcFilteredImage(Imd,[N,1]) - Imd).*Bmd;
            if nGrp == 3
                Ir{2} = max(0,calcFilteredImage(Imd,[1,N]) - Imd).*Bmd;
                Ir{3} = max(0,calcFilteredImage(Imd,N*[1,1]) - Imd).*Bmd;
            end
            
            % sets the median residual
            obj.ImdR{iImg} = Imd;
            obj.ImdRL{iImg} = cell2cell(cellfun(@(x)(cellfun(@(ir,ic,B)...
                (x(ir,ic).*B),iM.iR,iM.iC,obj.Bw,'un',0)),Ir,'un',0));
            
        end
        
        % --- sets up the combines residual images
        function [Zmn,Zpr] = setupCombResImages(obj,I)
            
            % combines the cell array into a 3D array
            I = cell2mat(reshape(I,[1,1,length(I)]));
            
            % calculates the filtered images
            Zmn = imfilter(min(I,[],3),obj.hG);
            Zpr = imfilter(prod(I,3),obj.hG);
            
        end
        
        % --- sets the background image (the images with the locations
        %     of the objects being removed)
        function [IBGnw,BMax,isOK] = setBGImage(obj,I,fP)
            
            % initialisations
            sz = size(I);
            isOK = ~isnan(fP(:,1));
            del = ceil(max(obj.szObj)/2);
            
            % sets up the points
            IBGnw = I;
            BMax = setGroup(cellfun(@(x)(...
                sub2ind(sz,x(2),x(1))),num2cell(fP(isOK,:),2)),sz);
            
            % sets up the binary image for object removal
            for i = find(isOK(:))'
                % sets the row/column indices
                iCP = (fP(i,1)-del):(fP(i,1)+del);
                iRP = (fP(i,2)-del):(fP(i,2)+del);
                
                % determines which row/column indices are valid
                jj = (iCP > 0) & (iCP <= sz(2));
                ii = (iRP > 0) & (iRP <= sz(1));
                
                % determines the binary location that overlaps the fly
                IBGnw(iRP(ii),iCP(jj)) = NaN;
                IBGnw(iRP(ii),:) = interpImageGaps(IBGnw(iRP(ii),:));
            end
            
        end
        
        % -------------------------- %
        % --- PLOTTING FUNCTIONS --- %
        % -------------------------- %
        
        function plotFramePos(obj,iImg,isFull)
            
            % sets the default input arguments
            if ~exist('isFull','var'); isFull = false; end
            
            % ensures the image count is correct
            if obj.nImg ~= length(obj.Img)
                obj.nImg = length(obj.Img);
            end
            
            % determine if the plot frame index is valid
            if iImg > obj.nImg
                % outputs an error message to screen
                eStr = sprintf(['The plot index (%i) exceeds the total',...
                    'number of frames (%i)'],iImg,obj.nImg);
                waitfor(errordlg(eStr,'Invalid Frame Reference','modal'))
                
                % exits the function
                return
            end
            
            % initialisations
            iStatusF = obj.iStatus;
            [I,iM] = deal(obj.Img{iImg},obj.iMov);
            [nR,nC] = deal(iM.nRow,iM.nCol);
            ILp = cellfun(@(ir,ic)(I(ir,ic)),iM.iR,iM.iC,'un',0);
            
            % creates the image/location plots for each sub-region
            figure;
            if isFull
                %
                h = subplot(1,1,1);
                plotGraph('image',I,h)
                hold on
                
            else
                %
                h = zeros(obj.nApp,1);
                
                for iApp = find(obj.iMov.ok(:)')
                    %
                    if isFull
                        ILshow = obj.IBG{iApp} - ILp{iApp};
                    else
                        ILshow = ILp{iApp};
                    end
                    
                    % plots the graph
                    h(iApp) = subplot(nR,nC,iApp);
                    plotGraph('image',ILshow,h(iApp));
                    hold on
                end
            end
            
            % plots the most likely positions
            hold on;
            for iApp = find(obj.iMov.ok(:)')
                % retrieves the marker points
                if isFull
                    j = 1;
                    fPosP = obj.fPosG{iApp,iImg};
                else
                    j = iApp;
                    fPosP = obj.fPos{iApp,iImg};
                end
                
                % plots the markers
                indF = 1:getSRCount(obj.iMov,iApp);
                isMove = iStatusF(indF,iApp) == 1;
                plot(h(j),fPosP(isMove,1),fPosP(isMove,2),'go');
                plot(h(j),fPosP(~isMove,1),fPosP(~isMove,2),'ro');
            end
            hold off
        end
        
        function plotFrameLikelyPos(obj,iImg)
            
            if length(obj.Img) ~= obj.nImg
                obj.nImg = length(obj.Img);
            end
            
            % determine if the plot frame index is valid
            if iImg > obj.nImg
                % outputs an error message to screen
                eStr = sprintf(['The plot index (%i) exceeds the total',...
                    'number of frames (%i)'],iImg,obj.nImg);
                waitfor(errordlg(eStr,'Invalid Frame Reference','modal'))
                
                % exits the function
                return
            end
            
            % initialisations
            [I,iM] = deal(obj.Img{iImg},obj.iMov);
            [nR,nC] = deal(iM.nRow,iM.nCol);
            ILp = cellfun(@(ir,ic)(I(ir,ic)),iM.iR,iM.iC,'un',0);
            
            % creates the image/location plots for each sub-region
            figure;
            for iApp = find(obj.iMov.ok(:)')
                % plots the graph
                plotGraph('image',ILp{iApp},subplot(nR,nC,iApp));
                hold on;
                
                %
                pMaxP = obj.pMax{iApp,iImg};
                for iT = 1:length(pMaxP)
                    % plots the most like positions
                    if ~isempty(pMaxP{iT})
                        plot(pMaxP{iT}(:,1),...
                            pMaxP{iT}(:,2)+obj.y0{iApp}(iT),'ro');
                    end
                end
            end
        end
        
        function plotResidualImages(obj,iImg)
            
            obj.plotFramePos(iImg,true)
            
        end
        
        % -------------------------- %
        % --- PROGRESS FUNCTIONS --- %
        % -------------------------- %
        
        % --- initialises the waitbar figure
        function initProgBar(obj)
            
            % waitbar field/title strings
            wStr = {'Overall Progress','Algorithm Progress'};
            tStr = 'Direction Detection Algorithm';
            
            % creates the waitbar figure
            obj.hProg = ProgBar(wStr,tStr);
            
        end
        
        % --- updates the waitbar figure
        function isCancel = updateProgBar(obj,iLvl,wStr,pW)
            
            isCancel = obj.hProg.Update(iLvl+obj.wOfs,wStr,pW);
            
        end
        
        % --- updates the main field of the progressbar
        function updateProgBarMain(obj,iGrp,wStr)
            
            % updates the
            nGrp = 6;
            pW = iGrp/(nGrp+1);
            
            % updates the progressbar
            if obj.updateProgBar(1,wStr,pW)
                obj.calcOK = false;
            end
            
        end
        
        % --- updates the sub-field of the progressbar
        function updateProgBarSub(obj,sTypeStr,i,dpW)
            
            % sets the progressbar string
            if nargin == 2
                pW = 1;
                wStr = sprintf('Analysing %s (Complete!)',sTypeStr);
            elseif i == 0
                pW = 0;
                wStr = sprintf('Analysing %s (Initialising)',sTypeStr);
            else
                [N,pW] = deal(obj.hProgN,(i-1)/obj.hProgN);
                if exist('dpW','var'); pW = pW + dpW; end
                wStr = sprintf('Analysing %s (%i of %i)',sTypeStr,i,N);
            end
            
            % updates the progressbar
            if obj.updateProgBar(2,wStr,pW)
                obj.calcOK = false;
            end
            
        end
        
        % --- sets up the progress bar object
        function setProgBarSubN(obj,hProgN)
            
            obj.hProgN = hProgN;
            
        end
        
        % --- sets the parameter struct externally
        function setProgBarObj(obj,hProg)
            
            obj.hProg = hProg;
            
        end
        
        % --- closes the progressbar (if created within internally)
        function performHouseKeepingOperations(obj)
            
            % clears the temporary image array fields
            obj.ImdBG = [];
            obj.ImdRL = [];
            obj.ImdR = [];
            obj.ImdL = [];
            obj.IL = [];
            obj.iGrpP = [];
            obj.zGrpP = [];
            
            % deletes the progress figure (if created within class)
            if ~obj.hasProg
                obj.hProg.closeProgBar();
            end
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- initialises the parameter struct
        function initParaStruct(obj)
            
            obj.iPara = struct('Nh',30,'N',5,'SD',2);
            
        end
        
        % --- retrieves the sub-image dimensions
        function del = getSubImageDim(obj)
            
            del = max(obj.szObj);
            
        end
        
    end
    
    % class static methods
    methods (Static)
        
        % --- determines the most likely sub-region objects
        function [iBest,indC] = detLikelyStaticBlobsSR...
                (IsubR,IsubMx,indSR,iBestPr)
            
            % initialisations
            nFly = length(indSR);
            [iBest,indC] = deal(NaN(nFly,1),NaN(nFly,1));
            iBestF = iBestPr(~isnan(iBestPr));
            
            % calculates the mean max residual/avg residual sub-images
            % over the indices given in the array, iBestPr
            IsubMn = calcImageStackFcn(IsubR(iBestF));
            Ixc = cellfun(@(x)(max(max(normxcorr2(x,IsubMn)))),IsubR);
            
            % metric calculations
            Zmx = (IsubMx-mean(IsubMx))/std(IsubMx);
            Zxc = (Ixc-mean(Ixc))/std(Ixc);
            Z = [Zmx,Zxc];
            
            % sets the index of the most likely blobs for each sub-region
            for iFly = 1:nFly
                switch length(indSR{iFly})
                    case 0
                        % no valid objects in the sub-region...
                        
                    case 1
                        % case is the sub-region has a unique object
                        iBest(iFly) = indSR{iFly};
                        
                    otherwise
                        % case is multiple blobs are in the sub-region
                        Zt = Z(indSR{iFly},:);
                        [~,imx] = max(Zt,[],1);
                        if range(imx) > 0
                            % if the best solution is mixed across metrics,
                            % then determine the metric with the lower
                            % metric value as being the group to reject
                            sZt = any(sign(Zt(imx,:))>0,2);
                            if sum(sZt) == 1
                                jmx = find(sZt > 0);
                            else
                                jmx = argMax(sum(normcdf(Zt(imx,:)),2));
                            end
                            
                            % sets the confounding index and updates
                            % the optimal index
                            indC(iFly) = indSR{iFly}(imx(imx~=imx(jmx)));
                            imx = imx(jmx);
                        end
                        
                        % sets the index of the most likely fly
                        iBest(iFly) = indSR{iFly}(imx(1));
                end
            end
            
        end
        
        % --- retrieves the sub-image (of half-width size del) from the
        %     image, I at the locations given by fP
        function [Isub,indL,indG] = getSubImage(I,fP,del,isN)
            
            % memory allocation
            sz = size(I);
            nImg = size(fP,1);
            [indL,indG] = deal(cell(nImg,1));
            
            % sub-image stack memory allocation
            if isN
                % sub-images are NaNs
                Isub = repmat({NaN(2*del+1)},nImg,1);
            else
                % sub-images are zeros
                Isub = repmat({zeros(2*del+1)},nImg,1);
            end
            
            % sets the sub-image for each coordinate
            for i = 1:nImg
                % sets the local row/column indices
                iCP = (fP(i,1)-del):(fP(i,1)+del);
                iRP = (fP(i,2)-del):(fP(i,2)+del);
                
                % determines which row/column indices are valid
                jj = (iCP > 0) & (iCP <= sz(2));
                ii = (iRP > 0) & (iRP <= sz(1));
                
                % sets the sub-image (for all feasible rows/columns)
                Isub{i}(ii,jj) = I(iRP(ii),iCP(jj));
                [indL{i},indG{i}] = deal({ii,jj},{iRP(ii),iCP(jj)});
            end
            
        end
        
        % --- calculates the background image estimate
        function IBG = setupBGImage(I,B)
            
            I(B) = NaN;
            IBG = interpImageGaps(I);
            
        end
        
        % --- determines the coordinates of other blobs in the sub-image
        function fPO = detPointsInFrame(Isub,dTol)                       
            
            % distance tolerance
            Dtol = 0.01 + dTol;
            
            % determines the minima within the sub-image
            B = isnan(Isub);
            Isub(B) = 0;
            [yP,xP] = find(imregionalmin(Isub).*(~B));
            
            % removes the centre point and returns the other values
            D = pdist2([1,1]*(size(Isub,1)-1)/2,[xP,yP]);
            ii = ~setGroup(find(D(:)<=Dtol),[length(xP),1]);
            fPO = [xP(ii),yP(ii)];
            
        end
        
        % --- calculates the largest feasible contour from Isub
        function [PcF,cLvlF] = getLargestFeasContour(Isub,Imin,fPO)
            
            % parameters
            nLvl = 25;
            dcLvlTol = 0.01;
            
            % splits the contour
            Isub = min(0,Isub);
            [Pc0,cLvl0] = splitContourLevels(Isub,nLvl,fPO);
            if isempty(Pc0)
                [PcF,cLvlF] = deal([]);
                return
            end
            
            % calculates the initial level difference
            if length(cLvl0) == 1
                dcLvl = cLvl0 - min(Isub(:));
            else
                dcLvl = diff(cLvl0(end-1:end));
            end
            
            % determines the largest possible contour
            cLvl = cLvl0(end);
            while dcLvl > dcLvlTol
                % calculates the contour at the current level
                PcNw = splitContourLevels(Isub,(cLvl+dcLvl)*[1,1],fPO);
                if ~isempty(PcNw)
                    cLvl = cLvl+dcLvl;
                else
                    % otherwise, reduce the level difference
                    dcLvl = dcLvl/2;
                end
            end
            
            % sets the final split contour levels (from min to max range)
            [PcF,cLvlF] = splitContourLevels(Isub,...
                linspace(Imin,cLvl,nLvl),fPO,0);
            
        end
        
        % --- determines the threshold pixel intensity
        function pTol = getBinThreshold(Z,ind)
            
            % --- runs the tolerance optimisation solver
            function pTol = runTolOpt(Z,B0,indL,pTol0)
                
                % --- determines if the binary group
                function isConnect = isBinConnect(Z,B0,indL,pTol)
                    [~,ZB] = detGroupOverlap(Z>=pTol,B0);
                    isConnect = all(ZB(indL));
                end
                
                % parameters
                dpTol = 0.01;
                gr = (sqrt(5)+1)/2;
                pLim = [0,pTol0];
                
                % keep iterating until limit difference is < tolerance
                while diff(pLim) > dpTol
                    % determines the limit difference value
                    dp = diff(pLim)/gr;
                    
                    % determines the limits from the upper value
                    p1 = pLim(1) + dp;
                    pLim(2-isBinConnect(Z,B0,indL,p1)) = p1;
                    
                    % determines the limits from the lower value
                    p0 = pLim(2) - dp;
                    pLim(2-isBinConnect(Z,B0,indL,p0)) = p0;
                end
                
                % returns the upper limit value
                pTol = pLim(2);
            end
            
            % initialisations
            sz = size(Z);
            [yP,xP] = ind2sub(sz,ind);
            
            % determines the point with the smaller z-value
            [pTol0,imn] = min(Z(ind));
            
            %
            [iR,iC] = deal(min(yP):max(yP),min(xP):max(xP));
            [ZL,xPL,yPL] = deal(Z(iR,iC),xP-(iC(1)-1),yP-(iR(1)-1));
            
            % sets the binary of the point with the lower z-value
            szL = size(ZL);
            indL = sub2ind(szL,yPL,xPL);
            B0 = setGroup(indL(imn),szL);
            
            % calculates the optimal tolerance value
            pTol = runTolOpt(ZL,B0,indL,pTol0);
            
        end
        
        % --- calculates the coordinates of the maximum of the array, Img
        function pMx = calcMaxCoord(Img)
            
            pMx = zeros(1,2);
            [pMx(2),pMx(1)] = ind2sub(size(Img),argMax(Img(:)));
            
        end
        
        % --- removes the left/right edges from an image
        function I = zeroImgEdges(I,dX)
            
            [I(:,1:dX),I(:,(end-(dX-1)):end)] = deal(0);
            
        end
        
        % ---
        function Ip = getPointResiduals(I,fP)
            
            %
            Ip = zeros(size(fP,1),1);
            [sz,isOK] = deal(size(I),~isnan(fP(:,1)));
            
            % sets the point residual values for the feasible points
            Ip(isOK) = I(sub2ind(sz,fP(isOK,2),fP(isOK,1)));
            
        end
        
        % ---
        function Isub = getPointSubImage(I,p,dN)
            
            % default input arguments
            if ~exist('dN','var'); dN = 10; end
            
            % initialisations
            sz = size(I);
            Isub = repmat({NaN(2*dN+1)},size(p,1),1);
            
            % sets the sub-images for each coordinate
            for i = 1:length(Isub)
                if ~any(isnan(p(i,:)))
                    % calculates the row/column indices of the sub-image
                    iR = (p(i,2)-dN):(p(i,2)+dN);
                    iC = (p(i,1)-dN):(p(i,1)+dN);
                    
                    % determines valid row/column pixels
                    ii = (iR >= 1) & (iR <= sz(1));
                    jj = (iC >= 1) & (iC <= sz(2));
                    
                    % sets the valid pixels of the image
                    Isub{i}(ii,jj) = I(iR(ii),iC(jj));
                    
                    % sets the missing values to be the median value
                    isN = isnan(Isub{i});
                    if any(isN(:))
                        Isub{i}(isN) = median(Isub{i}(~isN));
                    end
                end
            end
            
        end
        
        % --- cretes the binary map mask
        function Bmap = setupBinaryMap(iGrp,sz)
            
            % memory allocation
            Bmap = zeros(sz);
            
            % ensures the indices is stored in a cell array
            if ~iscell(iGrp); iGrp = {iGrp}; end
            
            % sets the indices for each of the binary groups
            for i = 1:length(iGrp)
                Bmap(iGrp{i}) = i;
            end
            
        end
        
        % --- groups the static points by their relative likeness
        function pB = groupLikelyPoints(IRcombF,Bmap)
            
            % initialisations
            sz = size(IRcombF);
            [yB,xB] = find(imregionalmax(IRcombF.*(Bmap>0)));
            
            %
            if length(xB) > 1
                % if so, determine the map
                BmapT = Bmap(sub2ind(sz,yB,xB));
                
                %
                pGrp = cell(max(BmapT),1);
                for i = 1:length(pGrp)
                    ii = BmapT == i;
                    pGrp{i} = roundP([mean(xB(ii)),mean(yB(ii))]);
                end
                
                % sets the final values into a single array
                pB = cell2mat(pGrp(:));
                
            else
                % sets the final coordinate array
                pB = [xB(:),yB(:)];
            end
            
        end
        
        % --- retrieves the maxima point search indices
        function [ii,jj] = getSearchIndices(yy,xx)
            
            % initialisations
            N = length(xx)/2;
            X = [yy(:),xx(:)];
            [ii,jj] = deal(zeros(N,1));
            isFound = false(2*N,1);
            
            % determines the groupings for the points
            for i = 1:N
                % finds the next point that has not yet been found
                j = find(~isFound,1,'first');
                
                % determines the next candidate point
                k = find(sum(abs(X - repmat(X(j,[2,1]),2*N,1)),2) == 0);
                [ii(i),jj(i)] = deal(X(j,1),X(k,1));
                
                % updates the found flag
                isFound([j,k]) = true;
            end
            
        end
        
        function Ns = calcMetrics(Isub1,Isub2)
            
            if ~isequal(size(Isub1),size(Isub2))
                Ns = 1;
            elseif (sum(Isub1(:)) == 0) || (sum(Isub2(:)) == 0)
                Ns = 1;
            elseif any(isnan(Isub1(:)))
                Ns = 1;
            elseif any(isnan(Isub1(:)))
                Ns = 1;
            else
                try
                    Ixc = normxcorr2(Isub1,Isub2);
                    Ns = 1 - max(Ixc(:));
                catch
                    Ns = 1;
                end
            end
            
        end        
        
        % --- converts the index value to a coordinate array
        function fP = ind2subC(sz,ind)
            
            [yP,xP] = ind2sub(sz,ind);
            fP = [xP(:),yP(:)];
            
        end        
        
        % --- resets the position of the likely points so that they map to
        %     the maxima from the raw image, I
        function fP = resetLikelyPos(I,fP,dTolC)

            % determines the minima from the raw image
            Icomp = 1 - normImg(I);
            iMx = find(imregionalmax(Icomp)); 
            [yMx,xMx] = ind2sub(size(I),iMx);

            % calculates the distance between the points and the minima
            DMx = pdist2(fP,[xMx,yMx]);

            %
            for i = 1:size(fP,1)
                ii = find(DMx(i,:) < dTolC);
                if isempty(ii)
%                     % no close matches so remove the coordinate
%                     fP(i,:) = NaN;
%                 else
                    % otherwise, if there are ambiguous points then 
                    % calcula
                    if length(ii) > 1
                        DMxP = DMx(i,ii)';
                        if any(DMxP == 0)
                            ii = ii(DMxP == 0);
                        else                
                            ZMxP = Icomp(iMx(ii))./(1+(DMxP/dTolC));
                            ii = ii(argMax(ZMxP));
                        end
                    end

                    % updates the coordinates
                    if ~isempty(ii)
                        fP(i,:) = [xMx(ii),yMx(ii)];
                    end
                end
            end        
        
        end
    end
end
