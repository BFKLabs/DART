classdef DirectDetect < handle
    % class properties
    properties
        % main class fields
        iMov
        hProg
        Img
        iPara
        iPhase
        prData = [];
        
        % boolean/scalar flags
        is2D
        wOfs = 1;
        hasProg = false;
        calcOK = true;
        calcRes = true;
        calcInit
        
        % dimensioning veriables
        nApp
        nTube
        nImg
        hProgN
        
        % important images/masks
        hG
        y0
        szObj
        vPh
        iPh
        
        % permanent calculated values
        IBG
        pBG
        pMax
        pMaxG
        fPos
        fPosL
        fPosG
        Phi
        axR
        NszB
        iStatus
        Qmet
        
        % temporary object fields
        Bw
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
        zTol = [0.5,0.4];
        dTol = 5;
        wSz = 8;
        pTol = 0.4;
        abTol = 0.75;
        xcTol = 0.525;
        
    end
    
    % class methods
    methods
        % class constructor
        function obj = DirectDetect(iMov,hProg)
            
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
            obj.is2D = is2DCheck(obj.iMov);
            
            % sets the tube-region offsets
            obj.y0 = cell(obj.nApp,1);
            for iApp = 1:obj.nApp
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
        function runDetectionAlgo(obj,calcInit)
            
            % default input arguments
            if ~exist('calcInit','var'); calcInit = false; end
            
            % field updates and other initialisations
            obj.calcInit = calcInit;
            obj.nImg = length(obj.Img);
            
            % initialises the solver fields
            obj.initObjectFields();
            
            % calculates the initial fly location estimates
            if obj.calcInit || isempty(obj.iMov.IbgT)
                % calculates the object positions directly if:
                %  - these are initial (bg) object calculations, or
                %  - no total background image has been set
                obj.calcInitObjPos();
                
            else
                % otherwise, calculate the
                obj.calcFullObjPos();
            end
            
            % calculates the global coordinates & performs housekeeping
            obj.calcGlobalCoords();
            obj.performHouseKeepingOperations();
            
        end
        
        % --- initialises the solver fields
        function initObjectFields(obj)
            
            % flag initialisations
            obj.calcOK = true;
            
            % permanent field memory allocation
            if obj.calcRes
                obj.pMax = cell(obj.nApp,obj.nImg);
                obj.fPos = cell(obj.nApp,obj.nImg);
                obj.iStatus = ~obj.iMov.flyok*3;
            end
            
            % orientation angle memory allocation
            if ~obj.calcInit
                if obj.iMov.calcPhi
                    obj.Phi = cell(obj.nApp,obj.nImg);
                    obj.axR = cell(obj.nApp,obj.nImg);
                    obj.NszB = cell(obj.nApp,obj.nImg);
                end
            end
            
            % sets the empty field to a NaN
            if isempty(obj.szObj)
                obj.szObj = NaN;
            end
            
            % temporary field memory allocation
            obj.IL = cell(obj.nImg,1);
            obj.iGrpP = cell(obj.nApp,obj.nImg);
            obj.zGrpP = cell(obj.nApp,obj.nImg);
            obj.ImdL = cell(obj.nApp,obj.nImg);
            [obj.BrmvBG,obj.indC] = deal(cell(1,obj.nApp));
            
            % sets up the gaussian filter
            [obj.iPara.N,obj.iPara.SD] = deal(5,2);
            obj.hG = fspecial('gaussian',obj.iPara.N,obj.iPara.SD);
            
            % initialises the progressbar (if one is not provided)
            if ~obj.hasProg; obj.initProgBar(); end
            
        end
        
        % ----------------------------- %
        % --- MAIN SOLVER FUNCTIONS --- %
        % ----------------------------- %
        
        % --- runs the initial position estimation function
        function calcInitObjPos(obj)
            
            % calculates the likely points for the static objects
            obj.calcStaticLikelyPoints();
            
            % calculates the sub-region most likely point groupings
            obj.calcFramePointGroupings();
            
            % calculates the background image estimate
            obj.estimateBGAll();
            
            % final empty region check
            obj.checkEmptyRegions();
            
        end
        
        % --- runs the initial position estimation function
        function calcFullObjPos(obj)
            
            % parameters
            pTolMax = 0.20;
            dTolT = max(obj.iMov.szObj);
            h0 = getMedBLSize(obj.iMov);
            
            % calculates the median filtered images
            obj.updateProgBar(1,'Subtracting Image Baseline...',0);
            [obj.ImgMd,obj.ImdBG] = ...
                removeImageMedianBL(obj.Img,false,obj.is2D,h0);
            obj.updateProgBar(1,'Image Baseline Subtraction Complete',1);
            
            % sets the flags for the rejected/empty regions
            obj.iStatus(obj.iStatus==0) = 2;
            obj.iStatus(~obj.iMov.flyok) = 3;
            
            % allocates memory for the positional coordinates
            obj.fPos = repmat(arrayfun(@(x)...
                (NaN(x,2)),obj.nTube(:),'un',0),1,obj.nImg);
            
            % calculates the object locations over all regions/frames
            for i = 1:obj.nApp
                % updates the progressbar
                wStr = sprintf(...
                    'Object Detection (Region %i of %i)',i,obj.nApp);
                if obj.updateProgBar(2,wStr,0.5*(1+i/(1+obj.nApp)))
                    % if the user cancelled, then exit
                    obj.calcOK = false;
                    return
                end
                
                % calculates the region residual images
                [iR,iC] = deal(obj.iMov.iR{i},obj.iMov.iC{i});
                ILnw = cellfun(@(x)(x(iR,iC)),obj.ImgMd,'un',0);
                IRLnw = cellfun(@(x)...
                            (obj.calcSubRegionRes(x,i)),ILnw,'un',0);
                
                % sets the sub-region residual images for all frames
                IRLnwT = cell2cell(cellfun(@(x)(cellfun(@(ir)(x(ir,:)),...
                    obj.iMov.iRT{i},'un',0)),IRLnw,'un',0),0);                

                % sets the previous stack location data
                if isempty(obj.prData)
                    % no previous data, so use empty values
                    fPr = cell(obj.nTube(i),1);
                else
                    % otherwise, use the previous values
                    fPr = obj.prData.fPosPr{i}(:);
                end                
                
                % calculates the coordinates for each sub-region/frame
                for j = 1:obj.nTube(i)
                    if obj.iMov.flyok(j,i)
                        [fPosNw,IRLmx] = segSingleSubRegion...
                                            (IRLnwT(j,:),fPr{j},dTolT);                        
                        if all(IRLmx < pTolMax) && ~isempty(obj.prData)
                            % if the residual is extremely low, then use
                            % the coordinates from the previous phase
                            pOfs = [0,obj.y0{i}(j)];
                            fPosNw = repmat(obj.prData.fPos{i}(j,:) - ...
                                pOfs,obj.nImg,1);
                        end
                        
                        % sets the final positions for each frame
                        for k = 1:obj.nImg
                            obj.fPos{i,k}(j,:) = fPosNw(k,:);
                        end
                    end
                end
                
                % calculates the binary mask template of the object
                if isnan(obj.szObj)
                    % retrieves the local positions and converts the
                    % residual images to their compliment
                    fPosOpt = cell2cell(cellfun(@(x)...
                        (num2cell(x,2)),obj.fPos(i,:),'un',0),0);
                    IRLnwC = cellfun(@(x)(-x),IRLnw,'un',0);
                    
                    % optimises the object shape
                    obj.optObjectShape(fPosOpt,i,IRLnwC);
                end
                
                % converts the coordinates from sub-region to region
                pOfs = [zeros(length(obj.y0{i}),1),obj.y0{i}];
                for j = 1:obj.nImg
                    obj.fPos{i,j} = obj.fPos{i,j} + pOfs;
                end
                
                % performs the orientation angle calculations (if required)
                if obj.iMov.calcPhi
                    % creates the orientation angle object
                    phiObj = OrientationCalc(imov,...
                        num2cell(IResL,2),fPos0,iApp);
                    
                    % sets the orientation angles/eigan-value ratio
                    obj.Phi(iApp,:) = num2cell(phiObj.Phi,1);
                    obj.axR(iApp,:) = num2cell(phiObj.axR,1);
                    obj.NszB(iApp,:) = num2cell(phiObj.NszB,1);
                end
            end
            
%             % calculates the background image estimate
%             obj.estimateBGAll();
            
            % updates the progressbar
            obj.updateProgBar(2,'Object Detection Complete',1);
            
        end
        
        % --- calculates the sub-region image residual
        function IR = calcSubRegionRes(obj,I,iApp)
            
            IR = imfilter(I-obj.iMov.IbgT{iApp},obj.hG);
            IR(isnan(IR)) = 0;
            
        end
        
        % --- 
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
            obj.pMaxG = repmat(arrayfun(@(x)(cell(x,1)),...
                obj.nTube,'un',0),1,nFrm);
            
            % converts the coordinates from the sub-region to global coords
            for iApp = 1:obj.nApp
                % calculates the x/y offset of the sub-region
                xOfs = obj.iMov.iC{iApp}(1)-1;
                yOfs = obj.iMov.iR{iApp}(1)-1;
                pOfsL = [zeros(obj.nTube(iApp),1),obj.y0{iApp}(:)];
                
                % calculates the global offset and appends it to each frame
                pOfs = repmat([xOfs,yOfs],obj.nTube(iApp),1);
                for iFrm = 1:nFrm
                    % calculates the sub-region/global coordinates
                    obj.fPosL{iApp,iFrm} = obj.fPos{iApp,iFrm} - pOfsL;
                    obj.fPosG{iApp,iFrm} = obj.fPos{iApp,iFrm} + pOfs;
                    
                    % sets the other potential marker locations
                    if obj.calcInit
                        for iT = 1:obj.nTube(iApp)
                            if obj.iMov.flyok(iT,iApp) && ...
                                    ~isempty(obj.pMax{iApp,iFrm}{iT})
                                pMaxT = obj.pMax{iApp,iFrm}{iT};
                                obj.pMaxG{iApp,iFrm}{iT} = pMaxT + ...
                                    repmat([xOfs,yOfs+obj.y0{iApp}(iT)],...
                                    size(pMaxT,1),1);
                            end
                        end
                    end
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
            for iApp = 1:obj.nApp
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
            
            % sets up the combined images
            [Zmn,Zpr] = obj.setupCombResImages(I);
            sz = size(Zmn);
            
            % determines the values of the overall minimum mask points
            [yPmn,xPmn] = find(imregionalmax(Zmn));
            Ymn = Zmn(sub2ind(sz,yPmn,xPmn));
            [~,iSmn] = sort(Ymn,'descend');
            [xPmn,yPmn] = deal(xPmn(iSmn),yPmn(iSmn));
            
            % determines the values of the overall product mask points
            [yPpr,xPpr] = find(imregionalmax(Zpr));
            Ypr = Zpr(sub2ind(sz,yPpr,xPpr));
            [~,iSpr] = sort(Ypr,'descend');
            [xPpr,yPpr] = deal(xPpr(iSpr),yPpr(iSpr));
            
            % calculates the distance between the mask maxima points
            D = pdist2([xPmn(:),yPmn(:)],[xPpr(:),yPpr(:)]);
            if length(xPmn) > length(xPpr)
                [D,Yc] = deal(D',Ymn(iSmn));
            else
                Yc = Ypr(iSpr);
            end
            
            % memory allocation
            N = min(length(xPmn),length(xPpr));
            iMatch = NaN(N,1);
            
            % determines closest matching point between the maxima types
            for i = 1:N
                % determines if there are any close points to the max
                iNw = find(argMin(D) == i);
                if ~isempty(iNw)
                    if length(iNw) > 1
                        imx = argMax(Yc(iNw)./D(i,iNw)');
                        iNw = iNw(imx);
                    end
                    
                    % updates the match index and distance array
                    iMatch(i) = iNw;
                    D(:,iNw) = deal(NaN);
                end
            end
            
            % sets the matching peak minimum/product maxima
            ii = ~isnan(iMatch);
            if length(xPmn) > length(xPpr)
                Pmn = [xPmn(iMatch(ii)),yPmn(iMatch(ii))];
                Ppr = [xPpr(ii),yPpr(ii)];
            else
                Pmn = [xPmn(ii),yPmn(ii)];
                Ppr = [xPpr(iMatch(ii)),yPpr(iMatch(ii))];
            end
            
            % sets the max values at the peak maxima locations
            Ymn = Zmn(sub2ind(sz,Pmn(:,2),Pmn(:,1)));
            Ypr = Zpr(sub2ind(sz,Ppr(:,2),Ppr(:,1)));
            
            % removes any non-significant points
            ii = (Ymn/max(Ymn) > obj.pTolR) | (Ypr/max(Ypr) > obj.pTolR);
            [Pmn,Ppr,Ymn,Ypr] = deal(Pmn(ii,:),Ppr(ii,:),Ymn(ii),Ypr(ii));
            if size(Pmn,1) == 1
                % sets the position vectors
                pMaxF = [roundP(mean([Pmn(:,1),Ppr(:,1)],2),1),...
                    roundP(mean([Pmn(:,2),Ppr(:,2)],2),1)];
                return
            end
            
            % determines if any maxima are close to each other
            dTolSz = min(sz/2);
            [Dmn,Dpr] = deal(pdist2(Pmn,Pmn),pdist2(Ppr,Ppr));
            Dmn(logical(eye(size(Dmn)))) = dTolSz+1;
            Dpr(logical(eye(size(Dpr)))) = dTolSz+1;
            [yy,xx] = find((Dmn<=dTolSz)|(Dpr<=dTolSz));
            
            % determines if the
            if ~isempty(xx)
                % determines the indices of points that are close
                imn = sub2ind(sz,Pmn(:,2),Pmn(:,1));
                ipr = sub2ind(sz,Ppr(:,2),Ppr(:,1));
                
                % determines the search indices
                [ii,jj] = obj.getSearchIndices(yy,xx);
                for i = 1:length(ii)
                    kk = [ii(i),jj(i)];
                    if ~any(isnan(Pmn(kk,1)))
                        % calculates max non-connecting tolerance values
                        mnTol = obj.getBinThreshold(Zmn,imn(kk));
                        prTol = obj.getBinThreshold(Zpr,ipr(kk));
                        
                        % if the ratio of the non-connecting tolerances to
                        % the max value is high, then the groups are
                        % probably connected
                        if all([mnTol/max(Ymn(kk)),...
                                prTol/max(Ypr(kk))] > obj.zTol)
                            % if oonnected then average the point locations
                            Pmn(kk(1),:) = mean(Pmn(kk,:),1);
                            Ppr(kk(1),:) = mean(Ppr(kk,:),1);
                            [Pmn(kk(2),:),Ppr(kk(2),:)] = deal(NaN);
                        end
                    end
                end
            end
            
            % removes any combined points
            ii = ~isnan(Pmn(:,1));
            [Pmn,Ppr] = deal(Pmn(ii,:),Ppr(ii,:));
            
            % sets the position vectors
            pMaxF = [roundP(mean([Pmn(:,1),Ppr(:,1)],2),1),...
                roundP(mean([Pmn(:,2),Ppr(:,2)],2),1)];
            
        end
        
        % --- aligns all the stationary points over all frames
        function alignStaticObjects(obj,iApp)
            
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
                obj.optObjectShape(pMaxApp,iApp);
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
            for iApp = 1:obj.nApp
                % retrieves the images for the current region
                yOfs = num2cell(obj.y0{iApp});
                Iapp = obj.getRegionImageStack(obj.ImdR,iApp);
                
                % converts the likely coordinates to region coordinate
                pMax0 = obj.pMax(iApp,:);
                fPos0 = cellfun(@(z)(cellfun(@(x,y)...
                    (x+repmat([0,y],size(x,1),1)),z,...
                    yOfs,'un',0)),pMax0,'un',0);
                
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
                    IappF = obj.getRegionImageStack(obj.Img,iApp);
                else
                    % case is another type of phase
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
            
            % initialisations
            sz = size(Iapp{1});
            nFly = length(fPos0{1});
            del = getSubImageDim(obj);
            Ngrp = cellfun(@(x)(size(x,1)),fPos0{1}(:));
            fok = obj.iMov.flyok(:,iApp);
            
            % sets up the blob binary masks for each frame
            Brmv = cellfun(@(x)(setGroup(x,sz)),iGrp,'un',0);
            
            % calculates the mean image/blob binary mask over all frames
            IappT = calcImageStackFcn(Iapp);
            BrmvT = calcImageStackFcn(Brmv) == 1;
            IBG0 = obj.setupBGImage(IappT,BrmvT);
            IappR = IBG0 - IappT;
            
            % sets up the global indices for each sub-region
            Ns = [0;cumsum(Ngrp)];
            indG0 = cell2mat(arrayfun(@(x,y,z)...
                ([z*ones(y-x+1,1),(x:y)']),...
                Ns(1:end-1)+1,Ns(2:end),(1:nFly)','un',0));
            
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
                
                % retrieves the sub-regions
                fPosR = [fPosX(isOK),fPosY(isOK)];
                IsubR = obj.getSubImage(IappR,fPosR,del,0);
                IsubMx = cellfun(@(x)(x(del+1,del+1)),IsubR);
                
                % sets up the sub-region to global index array
                indG = [indG0(isOK,1),(1:size(fPosR,1))'];
                indSR = arrayfun(@(x)...
                    (indG(indG(:,1)==x,2)),(1:nFly)','un',0);
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
                iPos = sub2ind(sz,fP(:,2),fP(:,1));
                
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
                
                % retrieves the valid sub-image pixels surrounding the max points
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
            
            % removes the infeasible points
            isOK = ~isnan(fP(:,1));
            fP = fP(isOK,:);
            
            % memory allocation
            nBlob = size(fP,1);
            szL = (2*del+1)*[1,1];
            Isub = repmat({NaN(szL)},nBlob,1);
            [Pc,cLvl,iGrp] = deal(cell(nBlob,1));
            
            % sets up the binary image for object removal
            for i = 1:nBlob
                % sets the row/column indices
                [Isub(i),indL,indG] = obj.getSubImage(I,fP(i,:),del,1);
                Imin = Isub{i}(del+1,del+1);
                
                % determines if there are any other points in the frame
                fPO = obj.detPointsInFrame(fP,indG{1},i);
                
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
                for iApp = 1:obj.nApp
                    % updates the progressbar
                    obj.updateProgBarSub('Region',iApp)
                    if ~obj.calcOK
                        % if the user cancelled then exit the function
                        return
                    end
                    
                    % removes binary image of the image blobs
                    [IappF,IappF0] = deal(...
                        obj.getRegionImageStack(obj.Img,iApp));
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
            end
            
            % clears up any missing
            if obj.vPh == 2
                % calculates the average image stack across all frames
                for iApp = 1:obj.nApp
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
                         (obj.getNthSortedValue(I(B),nFlyS)),IappRL,BrmvL);
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
            for iApp = 1:obj.nApp
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
            for iApp = 1:obj.nApp
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
                IoptNw = (1-normImg(Iopt0)).*(Iopt0<0);
                
                % determines if the optimal binary intersects the edge
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
            nGrp = 3;
            iM = obj.iMov;
            Nr = mean(cellfun(@(x)(mean(cellfun(@length,x))),iM.iRT));
            N = 2*min(floor(Nr),obj.iPara.Nh) + 1;
            
            % calculates the median residual image
            Imd = -obj.ImgMd{iImg};
            Bmd = Imd < 0;
            
            % calculates the x, y and x/y filtered residual images
            Ir = cell(nGrp,1);
            Ir{1} = max(0,calcFilteredImage(Imd,[N,1]) - Imd).*Bmd;
            Ir{2} = max(0,calcFilteredImage(Imd,[1,N]) - Imd).*Bmd;
            Ir{3} = max(0,calcFilteredImage(Imd,N*[1,1]) - Imd).*Bmd;
            
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
                
                for iApp = 1:obj.nApp
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
            for iApp = 1:obj.nApp
                % retrieves the marker points
                if isFull
                    j = 1;
                    fPosP = obj.fPosG{iApp,iImg};
                else
                    j = iApp;
                    fPosP = obj.fPos{iApp,iImg};
                end
                
                % plots the markers
                isMove = iStatusF(:,iApp) == 1;
                plot(h(j),fPosP(isMove,1),fPosP(isMove,2),'go');
                plot(h(j),fPosP(~isMove,1),fPosP(~isMove,2),'ro');
            end
            hold off
        end
        
        function plotFrameLikelyPos(obj,iImg)
            
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
            for iApp = 1:obj.nApp
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
        
        % ---
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
        
        % --------------------------------- %
        % --- CLASS FIELD I/O FUNCTIONS --- %
        % --------------------------------- %
        
        % --- sets class field for the field string(s) given in pStr
        function setClassField(obj,pStr,pVal)
            
            % ensures the field strings are in a cell array
            if ~iscell(pStr); pStr = {pStr}; end
            
            % combines the field string
            fStr = 'obj';
            for i = 1:length(pStr)
                fStr = sprintf('%s.%s',fStr,pStr{i});
            end
            
            % updates the field value
            eval(sprintf('%s = pVal;',fStr));
            
        end
        
        % --- sets class field for the field string(s) given in pStr
        function pVal = getClassField(obj,pStr)
            
            % ensures the field strings are in a cell array
            if ~iscell(pStr); pStr = {pStr}; end
            
            % combines the field string
            fStr = 'obj';
            for i = 1:length(pStr)
                fStr = sprintf('%s.%s',fStr,pStr{i});
            end
            
            % retrieves the field value
            pVal = eval(fStr);
            
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
                            jmx = argMin(min(Zt(imx,:),[],2));
                            
                            % sets the confounding index and updates
                            % the optimal index
                            indC(iFly) = indSR{iFly}(imx(imx~=jmx));
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
        function fPO = detPointsInFrame(fP,indG,iBlob)
            
            % determines the indices of the other blobs
            iOther = (fP(:,1) >= indG{2}(1)) & ...
                (fP(:,1) <= indG{2}(end)) & ...
                (fP(:,2) >= indG{1}(1)) & ...
                (fP(:,2) <= indG{1}(end));
            iOther(iBlob) = false;
            
            % determines if there are any points within the sub-image
            if any(iOther)
                % if so, then convert the points to local coordinates
                pOfs = [indG{2}(1),indG{1}(1)] - 1;
                fPO = [(fP(iOther,1)+pOfs(1)),(fP(iOther,2)+pOfs(2))];
            else
                % otherwise, return an empty array
                fPO = [];
            end
            
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
        
        function p = getNthSortedValue(I,N)
            
            if isempty(I)
                p = 0;
            else                        
                Is = sort(I,'descend');
                p = Is(min(length(I),N));
            end
            
        end
        
        % --- converts the index value to a coordinate array
        function fP = ind2subC(sz,ind)
            
            [yP,xP] = ind2sub(sz,ind);
            fP = [xP(:),yP(:)];
            
        end        
        
    end
end
