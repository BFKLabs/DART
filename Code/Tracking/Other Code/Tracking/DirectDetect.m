classdef DirectDetect < handle
    % class properties
    properties
        % main class fields
        iMov
        hProg
        Img
        prData
        iPara
        iPhase
        
        % boolean/scalar flags
        wOfs = 1;      
        hasProg = false;
        calcBG = false;   
        calcOK = true;
        
        % dimensioning veriables
        nApp
        nTube
        nImg       
        
        % important images/masks
        hG
        y0
        szObj
        
        % permanent calculated values
        IBG
        pBG        
        pMax
        pMaxG
        fPos
        fPosL
        fPosG
        iStatus               
        
        % temporary object fields
        ImdBG
        iImgBG
        ImdRL
        ImdR
        ImdL
        IL
        iGrpP
        zGrpP        
        
        % optimal gaussian parameter fields
        pOpt
        Iopt
        Bopt
        
        % fixed parameters
        rTol0 = 0.5;
        gpTol = 90;             
        pTolR = 0.35;
        zTol = [0.5,0.4];  
        dTol = 5;         
        wSz = 8;
        pTol = 0.4;
        abTol = 0.75;
        
        % variable parameters
        
        
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
            obj.nTube = getFlyCount(iMov,1);
            obj.nImg = length(obj.Img);
            
            % sets the tube-region offsets
            obj.y0 = cell(obj.nApp,1);
            for iApp = 1:obj.nApp
                obj.y0{iApp} = cellfun(@(x)(x(1)-1),obj.iMov.iRT{iApp});
            end
            
            % initialises the parameter struct
            obj.initParaStruct();
            
        end
        
        % ---------------------------- %
        % --- MAIN SOLVER FUNCTION --- %
        % ---------------------------- %         
        
        % --- runs the main detection algorithm 
        function runDetectionAlgo(obj,prData)
           
            % default input arguments
            if ~exist('prData','var'); prData = []; end
            
            % field updates and other initialisations
            obj.prData = prData;
            obj.nImg = length(obj.Img);                                
            
            % initialises the solver fields
            obj.initObjectFields();
            
            % calculates the median filtered background estimate
            obj.calcLocalImageMedian();
            
            % calculates the initial fly location estimates
            obj.calcFlyLocEstimate();
            
        end                
        
        % --- initialises the solver fields
        function initObjectFields(obj)
                        
            % flag initialisations
            obj.szObj = NaN;            
            obj.calcOK = true;            
            
            % permanent field memory allocation
            obj.pMax = cell(obj.nApp,obj.nImg);
            obj.fPos = cell(obj.nApp,obj.nImg);            
            obj.iStatus = ~obj.iMov.flyok*3;
            
            % temporary field memory allocation
            obj.IL = cell(obj.nImg,1);
            obj.iGrpP = cell(obj.nApp,obj.nImg);
            obj.zGrpP = cell(obj.nApp,obj.nImg);
            obj.ImdL = cell(obj.nApp,obj.nImg);            
            
            % sets up the gaussian filter
            [obj.iPara.N,obj.iPara.SD] = deal(5,2);
            obj.hG = fspecial('gaussian',obj.iPara.N,obj.iPara.SD);
            
            % initialises the progressbar (if one is not provided)
            if ~obj.hasProg; obj.initProgBar(); end                   
            
        end
        
        % ---------------------------- %
        % --- MAIN SOLVER FUNCTION --- %
        % ---------------------------- %        
        
        % --- runs the main calculation estimation function
        function calcFlyLocEstimate(obj)
            
            % calculates the likely points for the moving objects             
            obj.calcResidualLikelyPoints();
            
            % calculates the likely points for the static objects           
            obj.calcStaticLikelyPoints();
            
            % calculates the sub-region most likely point groupings
            obj.calcFramePointGroupings();
            
            % calculates the background image estimate            
            obj.estimateBG();
            
            % calculates the global coordinates
            obj.calcGlobalCoords();
            
            % closes the progressbar (if opened within the function)
            obj.performHouseKeepingOperations()
            
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
                    for iT = 1:obj.nTube(iApp)
                        if obj.iMov.flyok(iT,iApp)
                            pMaxT = obj.pMax{iApp,iFrm}{iT};
                            obj.pMaxG{iApp,iFrm}{iT} = pMaxT + ...
                                    repmat([xOfs,yOfs+obj.y0{iApp}(iT)],...
                                    size(pMaxT,1),1);
                        end
                    end
                end
            end
            
        end
        
        % ------------------------------------------------ %
        % --- RESIDUAL-BASED LIKELY POINT CALCULATIONS --- %
        % ------------------------------------------------ %
        
        % --- reduces down the likely points taking into consideration the
        %     movement of the objects over the image stack frames (it is
        %     assumed the image stack has a reasonably stable background)
        function calcResidualLikelyPoints(obj)
            
            % function only works if there: 
            %  - there is more than one image
            %  - if this is not the initial estimate
            %  - the user has not cancelled
            if (obj.nImg == 1) || ~obj.calcOK
                return
            end            
            
            % updates the progressbar main field
            obj.updateProgBarMain(2,'Calculating Moving Object Locations');            
            obj.updateProgBarSub('Region',0);
            
            % calculates the background image estimate for each region
            for iApp = 1:obj.nApp
                % updates the progressbar
                obj.updateProgBarSub('Region',iApp,obj.nApp)
                if ~obj.calcOK
                    % if the user cancelled, then exit
                    return
                else
                    % otherwise, calculate the likely moving objects
                    obj.calcResidualLikelyRegionPoints(iApp);
                end
            end
            
            % updates the progressbar
            obj.updateProgBarSub('Region');
        end
        
        % --- reduces the likely points for the region, iApp
        function calcResidualLikelyRegionPoints(obj,iApp)
            
            % --- calculates the ratio of the inter-frame and median
            %     filtered residual images
            function ImgR = calcImgRatio(IappR,ImdR)
                
                % sets up the ratio image
                ImgR = max(0,IappR./ImdR);
                Bc = ImgR > 1;
                ImgR(Bc) = 1./ImgR(Bc);
                
            end                              
            
            % parameters
            aTol = 0.1;
            mnTol = 0.75;
            pMaxTol = 0.50;
            
            % initialisations
            iM = obj.iMov;
            [szR,nT] = deal([1,1,(obj.nImg-1)],length(iM.iRT{iApp}));
            [iR,iC,iRT] = deal(iM.iR{iApp},iM.iC{iApp},iM.iRT{iApp});
            
            % memory allocation
            iStatusNw = zeros(nT,1);
            pMax0 = repmat({cell(nT,1)},1,obj.nImg);
            
            % local image/median filtered background images
            Imd_BG = obj.ImdBG(iR,iC);
            ImgL = cellfun(@(x)(x(iR,iC)),obj.Img,'un',0);
            
            % for each sub-region
            for iT = find(obj.iMov.flyok(:,iApp))'               
                % sets the sub-images and median background estimate
                % residual image masks (for all images in the stack)
                ImgT = cellfun(@(x)(x(iRT{iT},:)),ImgL,'un',0);
                ImdTR = cellfun(@(x)(max(0,obj.medianShiftImg(...
                                    Imd_BG(iRT{iT},:)-x))),ImgT,'un',0);
                    

                % calculates the inter-frame residuals/ratios
                [IappR,ImgR] = deal(cell(obj.nImg));
                for i = 1:obj.nImg
                    for j = (i+1):obj.nImg
                        % calculates the residuals between the 2 images
                        IappR0 = obj.medianShiftImg(ImgT{j}-ImgT{i});

                        % calculates the positive residual ratio image
                        IappR{i,j} = max(0,IappR0);
                        ImgR{i,j} = calcImgRatio(IappR{i,j},ImdTR{i});

                        % calculates the negative residual ratio image
                        IappR{j,i} = max(0,-IappR0);
                        ImgR{j,i} = calcImgRatio(IappR{j,i},ImdTR{j});
                    end
                end                 
                
                %
                for j = 1:obj.nImg
                    % calculates the minimum ratio image (over all frames)
                    isOK = ~cellfun(@isempty,ImgR(j,:));
                    IRmx = max(cell2mat(reshape(ImgR(j,isOK),szR)),[],3);
                    IRmn = max(cell2mat(reshape(IappR(j,isOK),szR)),[],3);
                    IRcomb = IRmx.*IRmn/max(ImdTR{j}(:));

                    % thresholds the image and determines the binary images
                    % linear indices (removes any group with only 1 pixel)
                    iGrp = getGroupIndex(IRcomb > obj.rTol0);
                    iGrp = iGrp(cellfun(@length,iGrp)>1);

                    % determines if there are any significant regions
                    if ~isempty(iGrp)
                        if length(iGrp) > 1
                            iNw = argMax(cellfun(@(x)...
                                    (prctile(IRcomb(x),obj.gpTol)),iGrp));
                            iGrp = iGrp{iNw};
                        end

                        % determines the likely points from the residual
                        % ratio image
                        BTol = obj.setupBinaryMap(iGrp,size(IRcomb)); 
                        IRcombF = imfilter(IRcomb,obj.hG);
                        pB = obj.groupLikelyPoints(IRcombF,BTol);                                                                                             

                        % sets the max points
                        pMax0{j}{iT} = pB;

                        % updates the status flag to indicate
                        if size(pB,1) == 1
                            iStatusNw(iT) = 1;
                        end
                    end
                end

                % determines if each frame has a candidate point
                hasObj = cellfun(@(x)(~isempty(x{iT})),pMax0);
                if any(~hasObj)
                    if mean(hasObj) >= mnTol
                        % if there are enough frame with candidate points,
                        % but some are missing, then determine if there is
                        % a legitimate object for the missing frames
                        for i = find(~hasObj(:))'
                            % calculates the location of the max point over
                            % all the frames
                            ii = (1:obj.nImg) ~= i;
                            pMaxNw = cell2mat(cellfun(@(x)(...
                                obj.calcMaxCoord(x)),IappR(i,ii),'un',0)');
                            
                            % determines if the coordinate range is within
                            % the distance tolerance
                            if max(range(pMaxNw,1)) <= obj.dTol
                                % if so, then re-add the missing coords
                                pMax0{i}{iT} = roundP(nanmean(pMaxNw,1));
                                
                            else
                                % if not, then reset the flag to zero
                                iStatusNw(iT) = 0;                                
                            end
                            
                        end
                    else                    
                        % if not, then reset the flag to zero
                        iStatusNw(iT) = 0;
                    end                    
                end

                % if the sub-region is flagged as moving, then determine
                % definitively if the objects have actually moved
                if iStatusNw(iT) == 1
                    % converts the locations to linear coordinates
                    pMaxT = cell2mat(cellfun(@(x)(x{iT}),pMax0(:),'un',0));
                    iMaxT = sub2ind(size(ImgT{1}),pMaxT(:,2),pMaxT(:,1));
                    
                    % determines the pixel intensities of coordinates, and 
                    % uses this threshold each frame
                    IMaxT = cellfun(@(x,y)(x(y)),ImdTR(:),num2cell(iMaxT));
                    
                    % thresholds the images (ensures that the binary
                    % overlapping the original point is included)
                    BMaxT = cellfun(@(x)(x>pMaxTol*min(IMaxT)),ImdTR,'un',0);
                    for i = 1:length(BMaxT)
                        [~,BMaxT{i}] = detGroupOverlap(BMaxT{i},pMaxT(i,:));
                    end
                        
                    % sums the binary masks over all frames. if there are
                    % any pixels 
                    szB = [1,1,length(BMaxT)];
                    BTot = mean(cell2mat(reshape(BMaxT,szB)),3);
                    iStatusNw(iT) = sum(BTot(:)==1)/sum(BTot(:)>0) < aTol;
                end                
            end
            
            % adds the max-point locations/status flag values
            obj.pMax(iApp,:) = pMax0;
            obj.iStatus(:,iApp) = iStatusNw;
            
        end
      
        % --- 
        function pB = groupLikelyPoints(obj,IRcombF,Bmap)
            
            % initialisations
            sz = size(IRcombF);            
            
            % determines the 
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
        
        % --- 
        function Bmap = setupBinaryMap(obj,iGrp,sz)

            % memory allocation
            Bmap = zeros(sz);
            
            % ensures the indices is stored in a cell array
            if ~iscell(iGrp); iGrp = {iGrp}; end

            % sets the indices for each of the binary groups
            for i = 1:length(iGrp)
                Bmap(iGrp{i}) = i;
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
            
            % memory allocation
            [obj.ImdR,obj.ImdRL] = deal(cell(obj.nImg,1));            
            
            % updates the progress bar main-field
            obj.updateProgBarMain(3,'Calculating Filtered Residual Images');
            obj.updateProgBarSub('Frame',0)
            
            % calculates the residual images
            for iImg = 1:obj.nImg
                % updates the progressbar sub-field                
                obj.updateProgBarSub('Frame',iImg,obj.nImg)
                if ~obj.calcOK
                    % if the user cancelled, then exit
                    return
                end
                
                % calculates the filtered residual images
                obj.calcFilteredResidualImages(iImg);

                % sets the local filtered images
                obj.ImdL(:,iImg) = cellfun(@(ir,ic)...
                           (obj.ImdR{iImg}(ir,ic)),imov.iR,imov.iC,'un',0);
            end
            
            % updates the sub-field progress-bar
            obj.updateProgBarSub('Frame')
            pause(0.01);
            
            % updates the progressbar main-field
            obj.updateProgBarMain(4,'Calculating Static Object Locations');    
            obj.updateProgBarSub('Region',0)
            
            % calculates the likely points for each sub-region
            for iApp = 1:obj.nApp
                % updates the progressbar sub-field                
                obj.updateProgBarSub('Region',iApp,obj.nApp);
                if ~obj.calcOK
                    % if the user cancelled, then exit
                    return                    
                end
                
                % calculations only necessary if there are static objects
                isStatic = (obj.iStatus(:,iApp) == 0) & fok(:,iApp);
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
                if obj.iMov.flyok(iT,iApp) && (obj.iStatus(iT,iApp) == 0)
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
            if isempty(obj.Bopt)
                % if the generic binary mask has not been created, then set
                % this up
                obj.optObjectShape(pMaxApp,iApp);
            elseif isnan(obj.szObj)
                % if not set, then calculate the approximate fly size 
                [~,objBB] = getGroupIndex(obj.Bopt,'BoundingBox');
                obj.szObj = objBB([3,4]);                
            end
            
            % calculates the distance tolerance
            dTolMax = min(obj.szObj);
            
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
                    % FINISH ME!!
                    obj.iStatus(iT,iApp) = 1;
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
        
        % ------------------------------------------- %
        % --- OPTIMAL POINT GROUPING CALCULATIONS --- %
        % ------------------------------------------- %
        
        % --- calculates the most likely point groupings
        function calcFramePointGroupings(obj)
            
            % if the user cancelled, then exit
            if ~obj.calcOK; return; end            
            
            % updates the progressbar fields
            obj.updateProgBarMain(5,'Calculating Optimal Object Groupings');       
            obj.updateProgBarSub('Region',0) 
            
            % calculates the optimal groupings for each region
            for iApp = 1:obj.nApp
                % updates the progressbar
                obj.updateProgBarSub('Region',iApp,obj.nApp)                        
                if ~obj.calcOK
                    % if the user cancelled, then exit
                    return
                else                                                
                    % otherwise, calculate the groupings                    
                    obj.calcRegionPointGroupings(iApp); 
                end 
                
                % checks the stationary points are valid over all frames
                obj.checkStationaryPoints(iApp)
            end
            
            % updates the progressbar fields       
            obj.updateProgBarSub('Region')             
        end        
        
        % --- determines the optimal groupings for each sub-region
        function calcRegionPointGroupings(obj,iApp)
            
            function Ns = calcInterFrameMetrics(Ns,Isub,ind)
                
                function Ns = calcMetrics(Isub1,Isub2)
                    
%                     % calculates the sub-image metrics
%                     Ns = zeros(1,2);   
%                     
%                     %
%                     B = ~(Isub1 == 0 & Isub2 == 0);
%                     Ns(1) = 1 - ssim(Isub1(B),Isub2(B),'radius',0.25);
%                     Ns(2) = obj.calcRMSError(Isub1,Isub2,obj.wSz);
    
                    %           
                    if ~isequal(size(Isub1),size(Isub2))
                        Ns = 1;
                    elseif (sum(Isub1(:)) == 0) || (sum(Isub2(:)) == 0)
                        Ns = 1;
                    else
%                         Ixc = normxcorr2(Isub1.*obj.Iopt,Isub2.*obj.Iopt);
                        Ixc = normxcorr2(Isub1,Isub2);
                    	Ns = 1 - max(Ixc(:));
                    end
                    
                end
                
                % initialisations
                nImgM = length(Ns);
                [j1,j2] = deal(ind(1),ind(2));
                [Isub1,Isub2] = deal(Isub{j1},Isub{j2}); 
                [N1,N2] = deal(length(Isub1),length(Isub2));
                
                % calculates metrics based on the type
                if (N1*N2) == 1
                    % both are static objects
                    NsNw = repmat(calcMetrics(Isub1{1},Isub2{1}),nImgM,1);
                    
                elseif N1 == 1
                    % the first object is a static object
                    NsNw = cell2mat(cellfun(@(x)(...
                            calcMetrics(Isub1{1},x)),Isub2(:),'un',0));
                    
                elseif N2 == 1
                    % the second object is a static object
                    NsNw = cell2mat(cellfun(@(x)(...
                            calcMetrics(x,Isub2{1})),Isub1(:),'un',0));
                    
                elseif N1 == N2
                    % the second object is a static object
                    NsNw = cell2mat(cellfun(@(x,y)(...
                            calcMetrics(x,y)),Isub1(:),Isub2(:),'un',0));                    
                            
                end                

                % sets the symmetric values for each metric
                for k2 = 1:length(Ns)
                    Ns{k2}(j2,j1) = NsNw(k2);
                    Ns{k2}(j1,j2) = NsNw(k2);
                end       
                
            end
            
            % initialistions
            p_Max = obj.pMax(iApp,:);
            dN = (size(obj.Bopt,1)-1)/2;
            nTubeR = obj.nTube(iApp);        
            fok = obj.iMov.flyok(:,iApp);
            Ngrp = cellfun(@(x)(size(x,1)),p_Max{1});                 
            
            % retrieves the sub-image stacks            
            Isub0 = obj.getAllSubImages(...
                        obj.ImdL(iApp,:),cell2cell(p_Max,0),dN,iApp,1);
            Isub = cellfun(@(x)(cell2cell(x)),num2cell(Isub0,1),'un',0);                              
            
            % sets up the global indices for each sub-region
            Ns = [0;cumsum(Ngrp(:))];
            indG = arrayfun(@(x,y)(x:y),Ns(1:end-1)+1,Ns(2:end),'un',0);   
            
            % condenses sub-images for static objects into a single frame
            Isub = num2cell(cell2cell(Isub,0),2);
%             for iT = find((obj.iStatus(:,iApp) == 0) & fok)'
%                 Isub(indG{iT}) = cellfun(@(x)({nanmean(cell2mat(...
%                    reshape(x,[1,1,length(x)])),3)}),Isub(indG{iT}),'un',0);   
%             end
            
            % ----------------------------- %
            % ---- METRIC CALCULATIONS ---- %
            % ----------------------------- %
            
            % determines the sub-regions that only have one object
            nImgL = length(Isub);
            isAmbig = cellfun(@length,indG) > 1;
            iT = arrayfun(@(j)(find(cellfun(@(x)(any(x==j)),indG))),1:nImgL);                        
            
            % calculates the histogram similarity metrics
            Ns = repmat({NaN(nImgL,nImgL)},obj.nImg,1);
            for j = 1:nImgL
                % only calculate the metrics if the tube region has
                % ambiguity
                if isAmbig(iT(j))
                    for i = 1:nImgL
                        if iT(i) ~= iT(j)
                            Ns = calcInterFrameMetrics(Ns,Isub,[i,j]);
                        end
                    end
                end
            end
            
%             % calculates the normalised complimentary values
%             for k = 1:length(Ns)
%                 for i = 1:size(Ns{k},3)
%                     Ns{k}(:,:,i) = normImg(Ns{k}(:,:,i));
%                 end
%             end
            
            % -------------------------------- %
            % ---- INITIAL IMAGE MATCHING ---- %
            % -------------------------------- %
            
            isUniq = cellfun(@length,indG) == 1;
            
            % index array initialisations            
            [x,y] = deal(NaN(nTubeR,1),cell(nTubeR,1));
            x(isUniq) = cell2mat(indG(isUniq));
            y(isUniq) = indG(isUniq);
            
            % array dimensioning
            nBest0 = zeros(nTubeR,nImgL);
            
            % memory allocation
            iBest = repmat({repmat(x(:),1,nImgL)},1,obj.nImg);
            iAll = repmat({repmat(y(:),1,nImgL)},1,obj.nImg);         
            nBest = repmat({nBest0},1,obj.nImg);
            
            % for all the non-unique regions,            
            for i = 1:nTubeR
                % retrieves the metric values for the maximal
                for j = 1:Ngrp(i)
                    % sets the global index
                    iC = indG{i}(j);
                    for i1 = 1:obj.nImg                        
                        % retrieves the metric values for the current point                        
                        NsT = squeeze(Ns{i1}(:,iC));
                        for k = find(isAmbig(:))'                            
                            if i == k
                                % case is the sub-regions intersect
                                iAll{i1}{k,iC} = indG{i}(j);
                                iBest{i1}(k,iC) = indG{i}(j);                                

                            elseif ~all(isnan(NsT(indG{k},:)))
                                % sorts the metric values in ascending order
                                NsTG = NsT(indG{k},:);

                                % determines if the objects indices are the
                                % same over all metrics
                                iMin = argMin(NsTG);
                                nBest{i1}(k,iC) = NsTG(iMin);
                                [iBest{i1}(k,iC),iAll{i1}{k,iC}] = ...
                                                deal(indG{k}(iMin));
                            end
                        end
                    end
                end
            end
            
            % ------------------------------------ %
            % ---- AMBIGUOUS SOLUTION REMOVAL ---- %
            % ------------------------------------ %                        
            
            % memory allocation
            [iGrp,nGrp,dGrp,pGrp] = deal(cell(obj.nImg,1));
            hasObj = cellfun(@(x)(~all(cellfun(@isempty,x),2)),iAll,'un',0);
            
            % sets up the histogram discretisation vector
            pLim = cellfun(@(I)(obj.calcMaxIntensity(I)),Isub,'un',0);
            pLim = cell2mat(pLim);
            
            % removes any
            for iImg = 1:obj.nImg
                % memory allocation
                [iGrp{iImg},nGrp{iImg},dGrp{iImg},pGrp{iImg}] = deal([]);
                
                %
                for i = 1:nImgL
                    % determines which tube regions have unique solutions
                    ii = cellfun(@length,iAll{iImg}(:,i)) == 1;
                    if mean(ii) > obj.pTol
                        if ~all(ii)
                            % determines the unique/ambiguous tube regions
                            i1 = cell2mat(iAll{iImg}(ii,i));
                            i2 = find(~ii & hasObj{iImg});

                            % keep determining the point with the lowest
                            % distance values from the ambiguous list (adding
                            % to the unique list) until there are no more
                            % ambiguous regions
                            while ~isempty(i2)
                                [dArr,iArr] = deal([]);
                                for j = i2(:)'
                                    dArr = [dArr;nanmean(sum(...
                                            Ns{iImg}(i1,iAll{iImg}...
                                            {j,i},:).^2,3),1)'];
                                    iArr = [iArr;[j*ones(length(...
                                            iAll{iImg}{j,i}),1),...
                                            iAll{iImg}{j,i}(:)]];
                                end

                                % if one point has the
                                imn = argMin(dArr);
                                [iT,iNw] = deal(iArr(imn,1),iArr(imn,2));
                                iAll{iImg}{iT,i} = iNw;
                                [i1(end+1),i2] = deal(iNw,i2(i2~=iT));
                            end
                        end

                        % determines if the new groupings already exist
                        iGrpNw = cell2mat(iAll{iImg}(:,i));
                        if isempty(iGrp{iImg})
                            % if there are no stored indices, then flag adding data
                            iAdd = [];
                        else
                            % otherwise, search the previous lists
                            iAdd = find(cellfun(@(x)(...
                                    isequal(x,iGrpNw)),iGrp{iImg}));
                        end

                        % calculates the distance between metrics 
                        dGrpNw = nansum(nansum(Ns{iImg}...
                                                (iGrpNw,i,:).^2,3)).^0.5;                        
                        
                        % determines if the new index array already exists
                        if isempty(iAdd)                            
                            % if not, then append the new data
                            iGrp{iImg}{end+1} = iGrpNw;
                            nGrp{iImg}(end+1) = 1;
                            dGrp{iImg}(end+1) = dGrpNw;
                            pGrp{iImg}(end+1) = mean(pLim(iGrpNw));
                        else
                            % otherwise, increment the counter
                            nGrp{iImg}(iAdd) = nGrp{iImg}(iAdd)+1;
                            dGrp{iImg}(iAdd) = (dGrp{iImg}(iAdd)*...
                             (nGrp{iImg}(iAdd)-1)+dGrpNw)/nGrp{iImg}(iAdd);
                        end
                    end
                end
            end
            
            % -------------------------------- %
            % ---- FINAL LOCATION SETTING ---- %
            % -------------------------------- %
            
            %
            A = cell2mat(obj.pMax{iApp,1});
            A(:,2) = A(:,2) + cell2mat(arrayfun(@(n,dy)...
                                (dy*ones(n,1)),Ngrp,obj.y0{iApp},'un',0));
            
            % determines thes
            for iImg = 1:obj.nImg
                if all(isUniq(hasObj{iImg}))
                    % if there is only one solution, use the first solution
                    [zGrp,iS,nPoss] = deal(1);
                else
                    % otherwise, calculate the combine objective function
                    % and sort in descending order
                    zGrp0 = (max(dGrp{iImg})/sum(nGrp{iImg}))*...
                                (nGrp{iImg}.*pGrp{iImg}./dGrp{iImg});
                    [zGrp,iS] = sort(zGrp0,'descend');

                    % determine which groupings have an objective function
                    % ratio value greater than tolerance
                    nPoss = sum(zGrp/zGrp(1) >= obj.abTol);
                end
            
                %
                iSF = iS(1:nPoss);                       
            
                % tube region offset
                fPosF = NaN(nTubeR,2);     
                yOfs = num2cell(obj.y0{iApp}(hasObj{iImg})); 
                pMaxF = cell2mat(cellfun(@(x,y0)(x+repmat([0,y0],...
                     size(x,1),1)),p_Max{iImg}(hasObj{iImg}),yOfs,'un',0));
            
                % sets the coordinates for each potential grouping
                fPosF(hasObj{iImg},:) = pMaxF(iGrp{iImg}{iS(1)},:);
            
                % sets the final values into class object
                obj.fPos{iApp,iImg} = fPosF;
                obj.iGrpP{iApp,iImg} = iGrp{iImg}(iSF);
                obj.zGrpP{iApp,iImg} = zGrp(iSF);
            end
        end        
        
        % --- calculates the maximum intensity for the image array, Img
        function Imx = calcMaxIntensity(obj,Img)
            
            if length(Img) == 1
                Imx = max(Img{1}(:))*ones(1,obj.nImg);
            else
                Imx = cellfun(@(x)(max(x(:))),Img(:)');                
            end
            
            
        end
        
        % --- optimises the shape function to the average image
        function optObjectShape(obj,pMaxApp,iApp)
            
            % --- optimises parameters for the general 2D gaussian equation
            function [Iopt,pOptF] = opt2DGaussian(Isub,pLim,pOpt0)
                
                % --- optimisation function for fitting the gabor function
                function [F,ITg] = optFunc(p,IT,X,Y)
                    
                    % calculates the new objective function
                    try
                        [Y0,A,k1,k2] = deal(p(1),p(2),p(3),p(4));
                        ITg = Y0 - A*exp(-k1*X.^2 + -k2*Y.^2);
                        
                        % calculates the objective function
                        F = ITg - IT;
                    catch
                        %
                        [F,ITg] = deal(1e10*ones(size(IT)),NaN(size(IT)));
                    end
                    
                end
                
                % optimisation solver option struct
                opt = optimset('display','none','tolX',1e-6,'TolFun',1e-6);
                
                % calculates the weighted mean image
                pW = pLim/min(pLim);
                X = cellfun(@(p,x)(p*x),num2cell(pW(:)),Isub(:),'un',0);
                I = nansum(cell2mat(reshape(X,[1,1,length(X)])),3)/sum(pW);
                
                % estimates the median/amplitude
                if isempty(pOpt0)
                    I(isnan(I)) = nanmedian(I(:));
                    Ymd = median(I(:));
                    Yamp = max(I(:)) - min(I(:));
                    pOpt0 =  [   Ymd,  Yamp,  0.1, 0.1];
                end
                
                % sets up the x/y coordinate values
                D = floor(size(I,1)/2);
                [X,Y] = meshgrid(-D:D);
                
                % parameters
                pLB = [-255.0,-255.0,  0.0, 0.0];
                pUB = [ 255.0, 255.0,  1.0, 1.0];
                
                % runs the optimiation can returns the optimal template
                pOptF = lsqnonlin(@optFunc,pOpt0,pLB,pUB,opt,I,X,Y);
                [~,Iopt] = optFunc(pOptF,I,X,Y);
            end            
           
            % parameters
            dimgSz = 5;
            pTol0 = 0.01;
            
            % retrieves the initial estimates of the
            [Iopt0,pOpt0] = deal(obj.Iopt,obj.pOpt);
            if isempty(Iopt0)
                imgSz = 5;
            else
                imgSz = (size(Iopt0,1)-1)/2;
            end            
            
            % initialisations
            ImgL = obj.ImdL(iApp,:);  
            
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
                BoptNw = IoptNw > pTol0;
                Bedge = bwmorph(true(size(BoptNw)),'remove');
                if any(BoptNw(Bedge))
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
                    ii = (iR >= 1) & (iR <= sz(1));
                    jj = (iC >= 1) & (iC <= sz(2));
                    
                    % sets the valid points for the sub-image
                    Isub{k}(ii,jj) = I(iR(ii),iC(jj));
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
                    pMaxT = pMaxL{i,j} + repmat(pOfs,size(pMaxL{i,j},1),1);
                    Isub{i,j} = getSubImages(ImgL{j},pMaxT,dN);
                end
            end       
            
            % if the images aren't to be normalised, then exit
            if ~isNorm; return; end
            
            %
            if isempty(obj.Bopt)
                BoptNw = false(size(Isub{1}));
            else
                BoptNw = bwmorph(obj.Bopt,'dilate',2);
            end
            
            % removes the non-conforming points from the images
            for i = 1:numel(Isub)
                for j = 1:length(Isub{i})
                    % removes all points that are:
                    %  - not part of the optimal binary
                    %  - NaN values
                    %  - have median image values > 0
                    Brmv = (Isub{i}{j}>=0) | isnan(Isub{i}{j});% | ~BoptNw;
                    Isub{i}{j}(Brmv) = 0;
                end
            end
            
            % calculates the metrics for each group
            pMin = min(cellfun(@(x)(min(...
                                cellfun(@(y)(min(y(:))),x))),Isub(:)));
            for i = 1:numel(Isub)
                Isub{i} = cellfun(@(x)(x/pMin),Isub{i},'un',0);
            end
            
        end
        
        % --- optimises the likely point image/locations
        function Isub = optLikelyPointImages(obj,p_Max,iImg,iApp)
            
            % --- retrieves the sub-regions surrounding the points, pMax
            function Isub = getSubImages(I,pMax,y0,dN)
                
                % initialisations
                [sz,nPts] = deal(size(I),size(pMax,1));
                
                % memory allocation
                Isub = repmat({NaN(2*dN+1)},nPts,1);
                
                % retrieves the valid sub-image pixels surrounding the max points
                for j = 1:nPts
                    % sets the row/column indices
                    iC = pMax(j,1) + (-dN:dN);
                    iR = (pMax(j,2)+y0(j)) + (-dN:dN);
                    
                    % determines which indices are valid
                    ii = (iR >= 1) & (iR <= sz(1));
                    jj = (iC >= 1) & (iC <= sz(2));
                    
                    % sets the valid points for the sub-image
                    Isub{j}(ii,jj) = I(iR(ii),iC(jj));
                end
                
            end
            
            % --- optimises parameters for the general 2D gaussian equation
            function [Iopt,pOptF] = opt2DGaussian(Isub,pLim,pOpt0)
                
                % --- optimisation function for fitting the gabor function
                function [F,ITg] = optFunc(p,IT,X,Y)
                    
                    % calculates the new objective function
                    try
                        [Y0,A,k1,k2] = deal(p(1),p(2),p(3),p(4));
                        ITg = Y0 - A*exp(-k1*X.^2 + -k2*Y.^2);
                        
                        % calculates the objective function
                        F = ITg - IT;
                    catch
                        %
                        [F,ITg] = deal(1e10*ones(size(IT)),NaN(size(IT)));
                    end
                    
                end
                
                % optimisation solver option struct
                opt = optimset('display','none','tolX',1e-6,'TolFun',1e-6);
                
                % calculates the weighted mean image
                pW = pLim/min(pLim);
                X = cellfun(@(p,x)(p*x),num2cell(pW(:)),Isub(:),'un',0);
                I = nansum(cell2mat(reshape(X,[1,1,length(X)])),3)/sum(pW);
                
                % estimates the median/amplitude
                if isempty(pOpt0)
                    I(isnan(I)) = nanmedian(I(:));
                    Ymd = median(I(:));
                    Yamp = max(I(:)) - min(I(:));
                    pOpt0 =  [   Ymd,  Yamp,  0.1, 0.1];
                end
                
                % sets up the x/y coordinate values
                D = floor(size(I,1)/2);
                [X,Y] = meshgrid(-D:D);
                
                % parameters
                pLB = [-255.0,-255.0,  0.0, 0.0];
                pUB = [ 255.0, 255.0,  1.0, 1.0];
                
                % runs the optimiation can returns the optimal template
                pOptF = lsqnonlin(@optFunc,pOpt0,pLB,pUB,opt,I,X,Y);
                [~,Iopt] = optFunc(pOptF,I,X,Y);
            end
            
            % parameters
            dimgSz = 5;
            pTol0 = 0.01;
            
            % retrieves the initial estimates of the
            [Iopt0,pOpt0] = deal(obj.Iopt,obj.pOpt);
            if isempty(Iopt0)
                imgSz = 5;
            else
                imgSz = (size(Iopt0,1)-1)/2;
            end
            
            % initialisations
            Imd_L = obj.ImdL{iApp,iImg};
            N = cellfun(@(x)(size(x,1)),p_Max);
            dy = cell2cell(arrayfun(@(x,n)...
                (x*ones(n,1)),obj.y0{iApp},N(:),'un',0));
            
            % keep looping until the optimal binary doesn't touch the
            % sub-image edge
            while 1
                % retrieves the sub-images
                Isub0 = getSubImages(Imd_L,cell2cell(p_Max),dy,imgSz);
                if iImg > 1
                    BoptNw = obj.Iopt > pTol0;
                    break
                end
                
                % optimises the 2D gaussian image from the mean image
                pLim = cellfun(@(I)(min(I(:))),Isub0);
                [Iopt0,pOptNw] = opt2DGaussian(Isub0,pLim,pOpt0);
                IoptNw = (1-normImg(Iopt0)).*(Iopt0<0);
                
                % determines if the optimal binary intersects the edge
                BoptNw = IoptNw > pTol0;
                Bedge = bwmorph(true(size(BoptNw)),'remove');
                if any(BoptNw(Bedge))
                    % if so, then increment the image size
                    imgSz = imgSz + dimgSz;
                else
                    % otherwise, exit the loop
                    break
                end
            end
            
            % sets the optimal image properties (first image only)
            if iImg == 1
                [obj.Iopt,obj.pOpt,obj.Bopt] = deal(IoptNw,pOptNw,BoptNw);
            end
            
            % sets the approximate fly size (if not set)
            if isnan(obj.szObj)
                [~,objBB] = getGroupIndex(BoptNw,'BoundingBox');
                obj.szObj = objBB([3,4]);
            end
            
            % removes the non-conforming points from the images
            Isub = Isub0;
            for i = 1:length(Isub)
                % removes all points that are:
                %  - not part of the optimal binary
                %  - NaN values
                %  - have median image values > 0
                Brmv = (Isub{i}>=0) | isnan(Isub{i}) | ~BoptNw;
                Isub{i}(Brmv) = 0;
            end
            
            % calculates the metrics for each group
            pMin = min(cellfun(@(I)(min(I(:))),Isub));
            Isub = cellfun(@(x)(x/pMin),Isub,'un',0);
            
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
                
                % final check to determine if the object has moved
                for iImg = 1:obj.nImg
                    fPosT = cell2mat(cellfun(@(x)...
                                (x(iT,:)),obj.fPos(iApp,:)','un',0));
                    if any(range(fPosT,1) > (obj.szObj-1)/2)
                        obj.iStatus(iT,iApp) = 1;
                    end
                end
            end            
        end        
        
        % --------------------------------------------- %
        % --- BACKGROUND IMAGE ESTIMATION FUNCTIONS --- %
        % --------------------------------------------- %
        
        % --- calculates the background images for each region
        function estimateBG(obj)
            
            % exit if not calculating the background
            if ~(obj.calcBG && obj.calcOK)
                return
            end
            
            % memory allocation
            [obj.IBG,obj.pBG] = deal(cell(obj.nApp,1));
            
            % updates the progressbar fields
            obj.updateProgBarMain(6,'Calculating Background Image Estimate');
            obj.updateProgBarSub('Region',0)
            
            % calculates the background image estimate for each region
            for iApp = 1:obj.nApp
                % updates the progress bar sub-field
                obj.updateProgBarSub('Region',iApp,obj.nApp)
                if ~obj.calcOK
                    % if the user cancelled, then exit
                    return
                else                
                    % calculates the background estimate for the region                
                    obj.estimateRegionBG(iApp);
                end
            end
            
            % updates the progressbar fields
            obj.updateProgBarSub('Region')            
            
        end
        
        % --- calculates the background image estimate for sub-region iApp
        function estimateRegionBG(obj,iApp)
            
            % --- sets the background image (the images with the locations
            %     of the objects being removed)
            function [IappBG,BMax,isOK] = ...
                                setBGImage(obj,Iapp,fPosT,Imd_BG)
                
                % parameters
                hQ = 0.25;
                
                % initialisations
                sz = size(Iapp);
                isOK = ~isnan(fPosT(:,1));    
                Qopt = obj.Iopt.^hQ;
                
                % memory allocation      
                Qw = zeros(sz);
                del = (size(Qopt,1)-1)/2;                
                
                % sets up the points
                Imd_BGnw = Imd_BG + (median(Iapp(:))-median(Imd_BG(:)));
                BMax = setGroup(cellfun(@(x)(...
                    sub2ind(sz,x(2),x(1))),num2cell(fPosT(isOK,:),2)),sz);
                
                % sets up the binary image for object removal
                for i = find(isOK(:))'
                    % sets the row/column indices
                    iCP = (fPosT(i,1)-del):(fPosT(i,1)+del);
                    iRP = (fPosT(i,2)-del):(fPosT(i,2)+del);
                    
                    % determines which row/column indices are valid
                    jj = (iCP > 0) & (iCP <= sz(2));
                    ii = (iRP > 0) & (iRP <= sz(1));
                    
                    % determines the binary location that overlaps the fly
                    Qw(iRP(ii),iCP(jj)) = ...
                                    max(Qopt(ii,jj),Qw(iRP(ii),iCP(jj)));
                end
                
                % removes the object locations from the image
                IappBG = Qw.*Imd_BGnw + (1-Qw).*Iapp;
                
            end
            
            % parameters
            nDil = 1;
            
            % initialisations
            [IappBG,BMaxT] = deal(cell(obj.nImg,1));
            [iR,iC] = deal(obj.iMov.iR{iApp},obj.iMov.iC{iApp});
            Imd_BG = obj.ImdBG(iR,iC);
            
            % converts all potential locations (for the current sub-region)
            % into a single array
            fPosT = obj.fPos(iApp,:);
            
            % retrieves the local images (for each sub-region)
            Iapp = cellfun(@(I)(I(iR,iC)),obj.Img,'un',0);
            
            % sets the images for the background estimate
            isOK = cell(obj.nImg,1);
            for iImg = 1:obj.nImg
                [IappBG{iImg},BMaxT{iImg},isOK{iImg}] = setBGImage(obj,...
                                Iapp{iImg},roundP(fPosT{iImg}),Imd_BG);
            end
            
            % calculates mean of the pixels across all frames
            IBGnw = nanmean(cell2mat(reshape(IappBG,[1,1,obj.nImg])),3);
            
            % for any missing regions, use the median background estimate
            Bstat = isnan(IBGnw);
            IBGnw(Bstat) = Imd_BG(Bstat);
            
            % ------------------------------------------ %
            % ---- THRESHOLD STATISTIC CALCULATIONS ---- %
            % ------------------------------------------ %
            
            % memory allocation
            szImg = size(BMaxT{iImg});
            Irng = zeros(size(fPosT{1},1),2,obj.nImg);
            
            % dilates the images around the
            IappR = cellfun(@(x)(IBGnw-x),Iapp,'un',0);
            
            %
            for iImg = 1:obj.nImg
                % retrieves the group indices for each point from the
                % binary image and sorts them in ascending order
                iGrp = getGroupIndex(bwmorph(BMaxT{iImg},'dilate',nDil));
                [yP,~] = ind2sub(szImg,cellfun(@(x)(x(1)),iGrp));
                [~,iS] = sort(yP);
                
                % returns the median/max values from the sub-regions
                Isub = cellfun(@(x)(IappR{iImg}(x)),iGrp(iS),'un',0);
                Irng(isOK{iImg},:,iImg) = cell2mat(cellfun(@(x)(...
                    [nanmedian(x),max(x)]),Isub,'un',0));
            end
            
            % perform test here to determine if region is empty...
            IrngMx = nanmax(Irng(:,2,:),[],3);
            
            % sets the final images
            obj.IBG{iApp} = IBGnw;
            obj.pBG{iApp} = nanmedian(Irng(:,1,:),3);
            
        end
        
        % ------------------------------------ %
        % --- IMAGE MANIPULATION FUNCTIONS --- %
        % ------------------------------------ %        
        
        % --- calculates the local median filter background image estimate
        function calcLocalImageMedian(obj,N)
            
            % sets the default input variables
            if nargin < 2; N = 1; end
            
            % updates the progressbar
            wStr = 'Median Filtered Background Image Setup';
            obj.updateProgBarMain(1,wStr);
            
            % determines the minimum inter-frame RMS error      
            D = zeros(obj.nImg);
            for i = 1:obj.nImg
                for j = (i+1):obj.nImg
                    Dnw = obj.calcRMSError(obj.Img{i},obj.Img{j},obj.wSz);
                    [D(i,j),D(j,i)] = deal(Dnw);
                end
            end
            
            obj.iPara.Nh = 50;
            
            % other inialisations
            obj.iImgBG = argMin(sum(D,1));
            I = obj.Img{obj.iImgBG};
            h = obj.iPara.Nh*[1,3];            
            
            % updates the median background image
            for i = 1:N
                % calculates the new median smoothed background mask
                ImdBG0 = 0.5*(medfilt2(I,[h(1),1]) + medfilt2(I,[1,h(2)]));
                
                % updates the image (by removing the median image)
                if i < N; I = I - ImdBG0; end
            end
           
            % sets the final image into the class object
            obj.ImdBG = ImdBG0;
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
            N = 2*obj.iPara.Nh + 1;
            
            % calculates the median residual image
            Imd = imfilter(obj.Img{iImg},obj.hG) - obj.ImdBG;
            
            % calculates the x, y and x/y filtered residual images
            Ir = cell(nGrp,1);
            Ir{1} = max(0,calcFilteredImage(Imd,[N,1]) - Imd);
            Ir{2} = max(0,calcFilteredImage(Imd,[1,N]) - Imd);
            Ir{3} = max(0,calcFilteredImage(Imd,N*[1,1]) - Imd);
            
            % sets the median residual
            obj.ImdR{iImg} = Imd;
            obj.ImdRL{iImg} = cell2cell(cellfun(@(x)(cellfun(@(ir,ic)...
                (x(ir,ic)),iM.iR,iM.iC,'un',0)),Ir,'un',0));
            
        end
        
        % --- sets up the combines residual images
        function [Zmn,Zpr] = setupCombResImages(obj,I)
            
            % combines the cell array into a 3D array
            I = cell2mat(reshape(I,[1,1,length(I)]));
            
            % calculates the filtered images
            Zmn = imfilter(min(I,[],3),obj.hG);
            Zpr = imfilter(prod(I,3),obj.hG);
            
        end
        
        % -------------------------- %
        % --- PLOTTING FUNCTIONS --- %
        % -------------------------- %
        
        function plotFramePos(obj,iImg,isFull)
            
            % sets the default input arguments
            if ~exist('isFull','var'); isFull = false; end
            
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
            nGrp = 5;
            pW = iGrp/(nGrp+obj.calcBG);
            
            % updates the progressbar
            if obj.updateProgBar(1,wStr,pW)
                obj.calcOK = false;
            end
            
        end
        
        % --- updates the sub-field of the progressbar
        function updateProgBarSub(obj,sTypeStr,i,N)            
            
            % sets the progressbar string            
            if nargin == 2
                pW = 1;
                wStr = sprintf('Analysing %s (Complete!)',sTypeStr);
            elseif nargin == 3
                pW = 0;
                wStr = sprintf('Analysing %s (Initialising)',sTypeStr);
            else
                pW = i/(N+1);
                wStr = sprintf('Analysing %s (%i of %i)',sTypeStr,i,N);
            end
            
            % updates the progressbar
            if obj.updateProgBar(2,wStr,pW)
                ok.calcOK = false;
            end
            
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
        
        % --- retrieves the maxima point search indices
        function [ii,jj] = getSearchIndices(obj,yy,xx)
            
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
        
        % --- determines the threshold pixel intensity
        function pTol = getBinThreshold(obj,Z,ind)
            
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
           
    end
    
    % class static methods
    methods (Static)
        % --- calculates the RMS error between images x and y
        function rmse = calcRMSError(x,y,ws)

            nresf = ws^2;
            nxn_sum_filter = ones(ws);
            num = (single(x) - single(y)).^2;
            num = filter2(nxn_sum_filter,num);
            rmse_map = sqrt(num./nresf);
            
            % calculates the overall mean difference
            ds = round(ws/2);
            rmse = mean2(rmse_map(ds:end-ds,ds:end-ds));

        end
        
        % --- 
        function pMx = calcMaxCoord(Img)            
            
            pMx = zeros(1,2);
            [pMx(2),pMx(1)] = ind2sub(size(Img),argMax(Img(:)));
            
        end
        
        % --- 
        function ImdS = medianShiftImg(I)

            ImdS = I - nanmedian(I(:));

        end                    
    end
end