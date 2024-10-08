classdef PhaseTrack < matlab.mixin.SetGet
   
    % class properties
    properties
        
        % main class fields
        iMov
        hProg
        Img
        prData
        iPara
        trkP
        iFrmR
        
        % boolean/other scalar flags
        iPr0
        iPr1
        iPh
        vPh        
        is2D
        iFrm        
        calcInit  
        wOfs = 0;      
        calcOK = true;         

        % temporary tracking fields
        fPrNw
        isStat        
        
        % dimensioning veriables
        nApp        
        nImg
        nTube
        
        % permanent object fields
        IR 
        IPos
        fPosL
        fPos
        fPosG
        pMax
        pMaxG
        pVal
        Phi
        axR
        NszB
        xLim
        yLim
        ImgS0
        ImgSL0
        
        % other object fields                     
        y0      
        hS
        nI
        dTol
        isHV
        isHT
        nPr = 5;  
        cFlag
        
    end
    
    % class methods
    methods
        
        % class constructor
        function obj = PhaseTrack(iMov,hProg)
            
            % sets the input arguments
            obj.iMov = iMov;
            obj.hProg = hProg;
            
            % array dimensioning
            obj.nApp = length(obj.iMov.iR);
            obj.nTube = getSRCountVec(obj.iMov);
            obj.cFlag = useDistCheck(obj.iMov);            
            obj.is2D = is2DCheck(obj.iMov); 
            
            % sets the tube-region offsets
            obj.y0 = cell(obj.nApp,1);
            for iApp = find(obj.iMov.ok(:)')
                % sets up the row offset coordinates
                ii = ~cellfun('isempty',obj.iMov.iRT{iApp});
                obj.y0{iApp} = NaN(length(ii),1);
                obj.y0{iApp}(ii) = ...
                    cellfun(@(x)(x(1)-1),obj.iMov.iRT{iApp}(ii));
                
                % if any region is empty, then flag as reject
                if any(~ii)
                    obj.iMov.flyok(~ii,iApp) = false;
                end
            end     
            
        end                         
        
        % ---------------------------- %
        % --- MAIN SOLVER FUNCTION --- %
        % ---------------------------- %         
        
        % --- runs the main detection algorithm 
        function runDetectionAlgo(obj)
            
            % field updates and other initialisations
            obj.Img = rmvEmptyCells(obj.Img);
            obj.nImg = length(obj.Img); 
            
            % initialises the object fields
            obj.initObjectFields()
            
            % segments the object locations for each region
            for iApp = find(obj.iMov.ok(:)')
                % updates the progress bar
                pW = 0.5*(1+iApp/(1+obj.nApp));
                wStr = sprintf(['Residual Calculations ',...
                                '(Region %i of %i)'],iApp,obj.nApp);
                if obj.hProg.Update(obj.wOfs+2,wStr,pW)
                    % if the user cancelled, then exit
                    obj.calcOK = false;
                    return
                end
                
                % segments the region
                obj.segmentRegions(iApp);                   
            end
            
            % updates the progressbar
            wStr = 'Residual Calculations (Complete!)';
            obj.hProg.Update(2+obj.wOfs,wStr,1);

            % converts the local coordinates to the global frame reference
            obj.calcGlobalCoords();      
            
        end           
        
        % --- initialises the solver fields
        function initObjectFields(obj)
            
            % flag initialisations
            obj.calcOK = true;            
            
            % permanent field memory allocation
            obj.IPos = cell(obj.nApp,obj.nImg);
            obj.fPosL = cell(obj.nApp,obj.nImg);
            obj.fPos = cell(obj.nApp,obj.nImg);
            obj.fPosG = cell(obj.nApp,obj.nImg);             
            
            % orientation angle memory allocation
            if obj.iMov.calcPhi
                obj.Phi = cell(obj.nApp,obj.nImg);
                obj.axR = cell(obj.nApp,obj.nImg);
                obj.NszB = cell(obj.nApp,obj.nImg);
            end
            
            % sets the previous stack location data
            if isempty(obj.prData) || ~isfield(obj.prData,'fPosPr')
                % no previous data, so use empty values
                nPr0 = 0;
            else
                % otherwise, use the previous values
                nPr0 = size(obj.prData.fPosPr{1}{1},1);
            end            
            
            % sets the up the previous data coordinate index arrays
            xiF = 1:obj.nImg;
            obj.iPr0 = arrayfun(@(x)(x:nPr0),xiF,'un',0);
            obj.iPr1 = arrayfun(@(x)(max(1,x-obj.nPr):(x-1)),xiF,'un',0);            
            
            % sets up the image filter (if required)
            obj.hS = [];
            bgP = getTrackingPara(obj.iMov.bgP,'pSingle');
            if isfield(bgP,'useFilt')
                if bgP.useFilt
                    obj.hS = fspecial('disk',bgP.hSz);
                end
            end
        
            % ensures the 2D flag is set
            if ~isfield(obj.iMov,'is2D')
                obj.iMov.is2D = is2DCheck(obj.iMov);
            end
            
            % retrieves the tracking parameters
            obj.trkP = getTrackingPara(obj.iMov.bgP,'pTrack');
            
            % initialises the progressbar
            wStr = 'Residual Calculations (Initialising)';
            obj.hProg.Update(2+obj.wOfs,wStr,0);            
            
        end            
        
        % ------------------------------------ %
        % --- IMAGE SEGMENTATION FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- segments the all the objects for a given region
        function segmentRegions(obj,iApp)
                        
            % initialisations
            imov = obj.iMov;                   
            y0L = [zeros(obj.nTube(iApp),1),obj.y0{iApp}(:)];
            
            % retrieves the global row/column indices
            nTubeR = getSRCount(obj.iMov,iApp);
            fok = obj.iMov.flyok(1:nTubeR,iApp);
            
            % sets the distance tolerance
            if isfield(obj.iMov,'szObj')
                obj.dTol = max(obj.iMov.szObj);
            else
                obj.dTol = 10;
            end
            
            % memory allocation
            fP0 = repmat({NaN(nTubeR,2)},1,obj.nImg);
            IP0 = repmat({NaN(nTubeR,1)},1,obj.nImg);
            
            % sets the previous stack location data
            if isempty(obj.prData)
                % no previous data, so use empty values
                fPr = cell(obj.nTube(iApp),1);  
                IPr = NaN(obj.nTube(iApp),1);
                
            elseif ~isfield(obj.prData,'fPosPr')
                % no previous data, so use empty values
                fPr = cell(obj.nTube(iApp),1);      
                IPr = NaN(obj.nTube(iApp),1);
                
            else
                % otherwise, use the previous values
                fPr = obj.prData.fPosPr{iApp}(:);
                IPr = obj.prData.IPosPr{iApp};
                if obj.nI > 0
                    fPr = cellfun(@(x)(obj.downsampleCoord(x)),fPr,'un',0);
                end
            end
            
            % sets up the region image stack
            iRT0 = obj.iMov.iRT{iApp};
            [ImgL,ImgBG] = obj.setupRegionImageStack(iApp);            
            [iRT,iCT] = obj.getSubRegionIndices(iApp,size(ImgL{1},2));
            
            % sets up the special image stack
            if obj.isHT
                IRef = obj.iMov.IbgR{iApp};
                ImgL = calcHistMatchStack(ImgL,IRef);
                ImgSegS = obj.setupSpecialImgStack(ImgL,iRT,iCT,iApp,fok);
            end
            
            % segments the location for each feasible sub-region
            for iTube = find(fok(:)')
                % sets up the image stack for segmentation
                if obj.isHT
                    % case is a special phase
                    ImgSeg = ImgSegS{iTube};
                    
                else
                    % sets the sub-region image stack
                    ImgSR = cellfun(@(x)(x(iRT{iTube},iCT)),ImgL,'un',0);
                    
                    % case is another phase type
                    ImgBGL = ImgBG(iRT{iTube},iCT);
                    ImgSeg = obj.setupResidualStack(ImgSR,ImgBGL);
                end                           
                
                % segments the image stack
                [fP0nw,IP0nw] = obj.segmentSubRegion...
                              (ImgSeg,fPr{iTube},IPr(iTube),[iApp,iTube]);
                if obj.nI > 0
                    % if the image is interpolated, then performed a
                    % refined image search
                    yOfs = y0L(iTube,:);
                    [fP0nw,IP0nw] = ...
                            obj.segmentSubImage(ImgL,ImgBG,fP0nw,yOfs);
                end                
                
                % sets the metric/position values
                for j = 1:obj.nImg
                    IP0{j}(iTube) = IP0nw(j);
                    fP0{j}(iTube,:) = fP0nw(j,:);
                end                                       
            end    
            
            % performs the orientation angle calculations (if required)
            if imov.calcPhi
                % sets up the local residual image stack
                IRes = cellfun(@(x)(ImgBG-x),ImgL(:)','un',0);
                IResL = cellfun(@(x)...
                        (cellfun(@(y)(x(y,:)),iRT0,'un',0)),IRes,'un',0);
                
                % creates the orientation angle object
                phiObj = OrientationCalc(imov,IResL,fP0,iApp);

                % sets the orientation angles/eigan-value ratio
                obj.Phi(iApp,:) = num2cell(phiObj.Phi,1);
                obj.axR(iApp,:) = num2cell(phiObj.axR,1);
                obj.NszB(iApp,:) = num2cell(phiObj.NszB,1);
            end            
            
            % sets the sub-region/region coordindates
            obj.IPos(iApp,:) = IP0;
            obj.fPosL(iApp,:) = fP0;
            obj.fPos(iApp,:) = cellfun(@(x)(...
                                    x+y0L),obj.fPosL(iApp,:),'un',0);                  
           
        end 
        
        % --- segments a sub-region with a moving object
        function [fP,IP] = segmentSubRegion(obj,Img,fPr0,IPr0,indR)
            
            % parameters
            pTolPmx = 2/3;
            
            % memory allocation   
            IPr = IPr0;
            nFrm = length(Img);   
            szL = size(Img{1});                        
            [fP,IP] = deal(NaN(nFrm,2),zeros(nFrm,1)); 
            isMove = obj.iMov.Status{indR(1)}(indR(2)) == 1;
            
            % retrieves the comparison pixel tolerance
            if isfield(obj.iMov,'pTolF')
                pTol0 = obj.iMov.pTolF(indR(1),obj.iPh);
            else
                pTol0 = NaN;
            end
            
            % retrieves the x/y-limits
            dTolL = obj.iMov.szObj(1);
            xL = obj.xLim{indR(1)}(indR(2),:);
            yL = obj.yLim{indR(1)}(indR(2),:);            

            % sets the stationary movement flag
            obj.isStat = obj.iMov.Status{indR(1)}(indR(2)) == 2;            
            
            % determines the feasible analysis frames
            isOK = ~cellfun(@(x)(all(isnan(x(:)))),Img);
            iFrmS = find(isOK(:)'); 
            
            % determines the most likely object position over all frames
            for i = iFrmS
%                 % reduces the image (if required)
%                 if (i > 1) && reduceImg
%                     [Img(i),pOfs] = obj.reduceImageStack(Img(i),fP(i-1,:));                    
%                 end

                % ----------------------------------------------- %
                % --- LIKELY POSITION COORDINATE CALCULATIONS --- %
                % ----------------------------------------------- %
                
                % sets the previous coordinate array
                if obj.iFrmR(i) < 5
                    obj.fPrNw = fP(obj.iPr1{i},:);
                else
                    obj.fPrNw = [fPr0(obj.iPr0{i},:);fP(obj.iPr1{i},:)];
                end
                
                % sorts the maxima in descending order
                iPmx = find(imregionalmax(Img{i}));
                [Pmx,iS] = sort(Img{i}(iPmx),'descend');
                iPmx = iPmx(iS);
                
                % sets the frame pixel intensity tolerance
                if isnan(pTol0)
                    pTolB = floor(pTolPmx*Pmx(1));
                else
                    pTolB = pTol0;
                end
                
                % determines the binary groups which meet threshold
                BB = Img{i} >= pTolB;
                iGrp = getGroupIndex(BB);
                nGrp = length(iGrp);                
                
                % ensures the blob and maxima count are equal
                if nGrp > 0
                    iiPmx = BB(iPmx);
                    if sum(iiPmx) == nGrp
                        % case is the peak count matches
                        [iPmx,Pmx] = deal(iPmx(iiPmx),Pmx(iiPmx));
                    else
                        % otherwise
                        iPmxT = iPmx(iiPmx);
                        jj = cellfun(@(x)(intersect(x,iPmxT)),iGrp,'un',0);
                        iPmx = cellfun(@(x)(x(argMax(Img{i}(x)))),jj);
                        Pmx = Img{i}(iPmx);
                    end                      
                end
                
                % determines how many prominent objects are in the frame
                if nGrp == 0
                    % case is there are no prominent objects
                    if isempty(obj.fPrNw)     
                        if length(Pmx) == 1
                            [fP(i,2),fP(i,1)] = ind2sub(szL,iPmx(1));
                        elseif Pmx(2)/Pmx(1) < obj.trkP.rPmxTol
                            [fP(i,2),fP(i,1)] = ind2sub(szL,iPmx(1));
                        end
                    else
                        % if there is previous data, then estimate where
                        % the blob is most likely to be
                        fPest0 = extrapBlobPosition(obj.fPrNw);
                        fPest = roundP(max(1,min(fPest0,flip(szL))));
                        Dest = bwdist(setGroup(fPest,szL));
                        
                        % calculates the objective function for all points
                        % detected from above
                        DpC = Dest(iPmx)/obj.dTol;
                        Dw = 1./max(0.25,DpC);                        
                        
                        % determines the most likely blob and sets the
                        % coordinates for the current frame
                        iMx = argMax(Dw.*Pmx);
                        [fP(i,2),fP(i,1)] = ind2sub(szL,iPmx(iMx));
                    end
                    
                elseif nGrp == 1
                    % case is there is only 1 prominent object
                    [xP,yP] = obj.calcCOM(Img{i},iGrp{1});

                    
                    % calculates the distance covered from the previous
                    % frame to the new positions                    
                    if isempty(obj.fPrNw) || isnan(obj.fPrNw(end,1))
                        % no previous data, so accept unconditionally
                        [pdPrNw,pdTolMax] = deal(0,1);
                        
                    else
                        % otherwise, set the weights for the distance check
                        % (based on the previous blob location)
                        fPrE = obj.fPrNw(end,:);
                        if any(obj.cFlag == [0,1])
                            % case is no distance check

                            % calculates the inter-frame distance
                            if obj.iMov.is2D
                                % case is a 2D setup
                                pdPrNw = pdist2([xP,yP],fPrE)/obj.dTol;

                            else
                                % case is a 1D setup (more weight is given 
                                % to the x-direction than the y-direction)
                                pdPrNw = (pdist2(xP,fPrE(1)) + ...
                                          pdist2(yP,fPrE(2))/2)/obj.dTol;                                
                            end
                            
                            % retrieves the distance tolerance value
                            pdTolMax = obj.getPDTol(indR,fPrE,1);                                  
                                
                        else
                            % case is a uni-directional side distance check
                            % (ignores distances of for a given side)
                            D = obj.calcUniDirDist(xP,fPrE(1));
                            pdPrNw = D/obj.dTol;
                            pdTolMax = obj.getPDTol(indR,fPrE,1,1); 
                        end
                    end
                        
                    % sets the final positional/intensity values
                    if pdPrNw < pdTolMax
                        % case is the blob has moved a feasible distance
                        [fP(i,:),IP(i)] = deal([xP,yP],Img{i}(iPmx(1)));
                        
                    else
                        % case is the blob has moved an infeasible distance
                        fP(i,:) = obj.fPrNw(end,:);
                        fPR = min(max(1,roundP(fP(i,:))),flip(szL));
                        IP(i) = Img{i}(sub2ind(szL,fPR(2),fPR(1)));
                    end
                    
                else
                    % case is there is not a prominient blob amoungst the
                    % candidates. performs a more through search of the
                    % candidates to determine the likely blob
                    if nGrp > 1
                        % 
                        pC = cell2mat(cellfun(@(x)(...
                            obj.calcCOM(Img{i},x)),iGrp,'un',0));
%                         iGrpMx = cellfun(@(x)(x(argMax(Img{i}(x)))),iGrp);
%                         pC = obj.calcCoords(szL,iGrpMx);
                        
                        % if there are multiple blobs, then search for the
                        % most likely blob 
                        [iMx,fPnw,IPnw] = ...
                            obj.detLikelyAmbigBlob(Img{i},iGrp,pC,indR);
                    
                        % if a valid solution was found, then update the
                        % location and pixel intensity data
                        if isnan(iMx)
                            [fP(i,:),IP(i)] = deal(fPnw,IPnw);
                        else
                            fP(i,:) = max(1,roundP(pC(iMx,:)));
                            IP(i) = max(Img{i}(iGrp{iMx}));
                        end
                    end
                    
                end
                
                % ------------------------------------ %
                % --- COORDINATE FEASIBILITY CHECK --- %
                % ------------------------------------ %
                
                % for 1D experiments, prevents the large jumps in position
                % cause by blobs hiding at the edges of the sub-region
                
                % new coordinate feasibility check
                %  - only check coordinate feasibility if:
                %    * the setup is 1D only
                %    * there is a comparison pixel tolerance (pTol)
                %    * the fly actually moves over the phase
                %    * both the new/current values are less than tolerance
                chkCoord = [~isnan(pTolB),...
                            isMove,...
                            all([IPr,IP(i)] < pTolB),...
                            ~obj.iMov.is2D];
                if all(chkCoord)
                    % if this is all true, then determine if there has been
                    % a large movement in the blob
                    fPT = [];
                    if i == 1
                        % sets the previous coordinates from the last
                        % phase/stack (if available)
                        if ~isempty(fPr0)
                            fPT = [fPr0(end,:);fP(i,:)];
                        end
                    else
                        % otherwise, set the comparison coordinate using
                        % the previous frame
                        fPT = fP(i+[-1;0],:);
                    end
                    
                    % determines if there are any comparison coordinates
                    if ~isempty(fPT)
                        % if so, determine if there has been a large
                        % displacement between frames. if so, then reset
                        % the coordinates for the current frame to the last
                        % (likely jump in location detected)
                        DPT = abs(diff(fPT,[],1));
                        if any(DPT > dTolL)
                            fP(i,:) = fPT(1,:);
                        end
                    end
                end
                
                % ------------------------------------- %
                % --- OTHER HOUSE-KEEPING EXERCISES --- %
                % ------------------------------------- %
                
                % sets the limit comparison coordinates
                if obj.nI > 0
                    % upsamples the coordinates (if required)
                    fPL = 1 + obj.nI*(1 + 2*(fP(i,:)-1));
                else
                    % otherwise, use the original coordinates
                    fPL = fP(i,:);
                end
                
                % updates the x/y coordinate limits
                [IPr,nFlag] = deal(IP(i),'omitnan');
                xL = [min(fPL(1),xL(1),nFlag),max(fPL(1),xL(2),nFlag)];
                yL = [min(fPL(2),yL(1),nFlag),max(fPL(2),yL(2),nFlag)];                
            end
            
            % resets the x/y-limits
            obj.xLim{indR(1)}(indR(2),:) = xL;
            obj.yLim{indR(1)}(indR(2),:) = yL;
            
        end                
        
        % --- calculates the unidirectional distance
        function D = calcUniDirDist(obj,xNw,xPr)
            
            if obj.cFlag == 2
                % case is searching only the left direction
                D = max(0,xPr-xNw);
            else
                % case is searching only the right direction
                D = max(0,xNw-xPr);
            end
            
        end    
        
        % --- determines the likely blob (when there is no clear
        %     prominent blob residual maxima)
        function [iMx,fPnw,IPnw] = detLikelyAmbigBlob(obj,Img,iGrp,pC,indR)                        
            
            % calculates the centroid linear indices
            [fPnw,IPnw] = deal(NaN);
            [szL,pCR] = deal(size(Img),roundP(pC));
            ipC = sub2ind(szL,pCR(:,2),pCR(:,1));
                        
            % ------------------------------------------ %
            % --- PREVIOUS LOCATION WEIGHTING FACTOR --- %
            % ------------------------------------------ %            
            
            % parameters
            Dmin = 0.5;
            dTolMax = obj.getDistTol();            
            
            % sets the previous data points (for estimating
            % the location of the blob on this frame)
            if isempty(obj.fPrNw) || isnan(obj.fPrNw(end,1))
                % case is there is no previous data
                dTolMax = 1e10;
                QD = ones(size(ipC));                
                
            else
                % if there is previous data, then calculate the weighting
                % factor of the maxima from the estimate location
                if size(obj.fPrNw,1) == 1
                    % case is there is only one previous point
                    fPest = obj.fPrNw;

                else
                    % otherwise, extrapolate the blobs location
                    fPest0 = extrapBlobPosition(obj.fPrNw);
                    fPest = max(1,min(fPest0,flip(szL)));
                end
                
                % sets up the distance estimate mask
                if any(obj.cFlag == [0,1])
                    % calculates the estimate/candidate
                    % points (scale to dTol)
                    if obj.iMov.is2D
                        % case is a 2D setup
                        Dest = pdist2(pCR,fPest);

                    else
                        % case is a 1D setup (more weight is given to the
                        % x-direction than the y-direction)
                        Dest = pdist2(pCR(:,1),fPest(:,1)) + ...
                               pdist2(pCR(:,2),fPest(:,2));
                    end
                    
                    QD = max(Dmin,Dest/obj.dTol);
                    
                else
                    % calculates the estimate/candidate
                    % points (scale to dTol)
                    D = obj.calcUniDirDist(pC(:,1),fPest(1));
                    QD = max(Dmin,D/obj.dTol);
                end
            end            
            
            % --------------------------------- %
            % --- LOCATION WEIGHTING FACTOR --- %
            % --------------------------------- %
            
            % parameters
            pRmin = 1/5;
            QRmax = 1.25;
            
            % sets the likelihood weighting factor 
            if isfield(obj.iMov,'pB') && ~isempty(obj.iMov.pB{indR(1)})
                % removes any points which have extremely low values (that
                % are not extremely close to the previous point)
                IpC = Img(ipC);
                isRmv = (IpC < pRmin*obj.iMov.pB{indR(1)}.A) & (QD > Dmin);
                QD(isRmv) = 2*dTolMax;
                
                % case is there is a residual/x-location distribution
                %  - given the location of the maxima, the residual at that
                %    location should match
                [~,xPmx] = ind2sub(szL,ipC);
                QR = min(QRmax,...
                    IpC./calcBimodalBoltz(obj.iMov.pB{indR(1)},xPmx));
                
            else
                % case is there is no weighting distribution
                QR = normImg(cellfun(@(x)(mean(Img(x))),iGrp).^2,1);
            end
            
            % ------------------------------------- %
            % --- LIKELY CANDIDATE CALCULATIONS --- %
            % ------------------------------------- %            
            
            % parameters
            QTolMin = 0.2;
            
            % if stationary, then penalise the distance weighting
            if obj.isStat
                QD = QD.^2;
            end
            
            % calculates the combined 
            QRD = QR./QD;
            
            % determines if any points are within the distance tolerance
            inDistTol = (QD < dTolMax) & (QRD > QTolMin);
            switch sum(inDistTol)
                case 0
                    % case is there are no blob maxima within a
                    % small distance of the estimate. in this
                    % case, use the previous/estimate position
                    if isempty(obj.fPrNw) || ...
                            any(range(obj.fPrNw,1) > obj.dTol)
                        % if the step size is too large, or
                        % there is no prevsious data, then use
                        % the estimated values
                        if exist('fPest','var')
                            fPnw = fPest;
                        else
                            fPnw = NaN(1,2);
                        end
                    else
                        % otherwise, use previous location
                        fPnw = obj.fPrNw(end,:);
                    end
                    
                    % seets the estimate value
                    if any(isnan(fPnw))
                        [IPnw,iMx] = deal(NaN);
                    else
                        fPR = min(max(1,roundP(fPnw)),flip(szL));
                        iPEst = sub2ind(szL,fPR(2),fPR(1));
                        [IPnw,iMx] = deal(Img(iPEst),NaN);
                    end
                    
                case 1
                    % case is there is only one feasible point
                    iMx = find(inDistTol);                    
                    
                otherwise                    
                    % sets the blob size weight factor
                    Qsz = cellfun(@length,iGrp).^0.5;
                                        
                    % determines the group with the highest
                    % location/residual weighting that is closest to the
                    % estimate location
                    iMx = argMax((Qsz.*QRD).*inDistTol);
                    
            end            
                    
        end

        % --- retrieves the proportional distance limit check value
        function pdTol = getPDTol(obj,indR,fPr,Type,cFlag0)
            
            % initialisations
            pdTol = 1e10;

            % sets the input arguments
            if ~exist('cFlag0','var'); cFlag0 = obj.cFlag; end

            % sets the tolerance flag
            switch Type
                case 1
                    % case is unique peak tolerance
                    
                    % sets the tolerance based on flag type
                    if cFlag0 > 0
                        % case is a bi-directional check
                        if obj.iMov.is2D
                            % case is a 2D setup
                            pdTol = 9;
                        else
                            % case is a 1D setup
                            if obj.withinEdge(indR,fPr)
                                % point is close to the edge
                                pdTol = 1 + ~obj.isStat*2;
                            else
                                % point is not at the region edge
                                pdTol = 2 + ~obj.isStat*5;
                            end
                        end
                    end                    
            end
                    
        end        
        
        % --- calculates the refined coordinates from original scale image
        function [fP,IP] = segmentSubImage(obj,ImgL,ImgBG,fP0,pOfs)
            
            % memory allocation            
            pOfsT = repmat(pOfs,length(ImgL),1);
            [W,szL] = deal(2+obj.nI,size(ImgBG));
            [fP,IP] = deal(NaN(obj.nImg,2),NaN(obj.nImg,1));
            fPT = roundP(1 + obj.nI*(1 + 2*(fP0-1)) + pOfsT);
            isOK = ~isnan(fP0(:,1));
            
            % determines the coordinates from the refined image
            for i = find(isOK(:)')
                % sets up the sub-image surrounding the point
                iRP = max(1,fPT(i,2)-W):min(szL(1),fPT(i,2)+W);
                iCP = max(1,fPT(i,1)-W):min(szL(2),fPT(i,1)+W);
                IRP = ImgBG(iRP,iCP)-ImgL{i}(iRP,iCP);
                
                % retrieves the coordinates of the maxima
                pMaxP = getMaxCoord(IRP);
                IP(i) = IRP(pMaxP(2),pMaxP(1));
                fP(i,:) = (pMaxP-1) + [iCP(1),iRP(1)] - pOfs;
            end
                
        end            
        
        % ---------------------------------- %
        % --- IMAGE STACK SETUP FUNCTION --- %
        % ---------------------------------- %   
        
        % --- sets up the image weights
        function Qw = setupImageWeights(obj,Img)
            
            % sets the CDF pixel weighting threshold
            if isfield(obj.iMov.bgP.pTrack,'pWQ')
                pWQ = obj.iMov.bgP.pTrack.pWQ;
            else
                pWQ = 1;
            end
            
            % sets up the weighting matrices (depending on whether there is
            % uniform or pixel intensity weighting)
            if pWQ < 1
                % calculates the image stack statistics
                ImgT = cell2mat(Img(:));                        
                B = ImgT > 0;
                Imu = mean(ImgT(B),'omitnan');
                Isd = std(ImgT(B),[],'omitnan');
                
                % calculates the image weight (preference given to lower
                % pixel intensities - removes effect of glare)
                pCDF = cellfun(@(x)(normcdf(x,Imu,Isd)),Img,'un',0);
                Qw = cellfun(@(x)(min(1,1-(x-pWQ)/(1-pWQ)).^2),pCDF,'un',0);
            else
                % otherwise, use uniform weighting arrays
                Qw = cellfun(@(x)(ones(size(x))),Img,'un',0);
            end
            
        end
        
        % --- sets up the residual image stack
        function IR = setupResidualStack(obj,Img,ImgBG)
            
            % calculates the image stack residual
            Qw = obj.setupImageWeights(Img);                
            IR = cellfun(@(x,q)(q.*(ImgBG-x)),Img,Qw,'un',0);
            isOK = ~cellfun(@(x)(all(isnan(x(:)))),IR);
            
            % removes any NaN values from the image
            if isfield(obj.iMov,'phInfo') && ~isempty(obj.iMov.phInfo)
                % removes any NaN pixels or pixels at the frame edge          
                for i = find(isOK(:)')
                    B = bwmorph(isnan(IR{i}),'dilate',1+obj.nI);
                    IR{i}(B) = 0;
                end
            end       
            
            % removes the image median
            IR(isOK) = cellfun(@(x,y)(max(0,x)),IR(isOK),'un',0);            
            
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
                    ImgXC{i} = imfiltersym(Ixc0,obj.hS)/2;
                end
                
                % adjusts the image to accentuate dark regions
                ImgXC{i} = ImgXC{i}.*(1-normImg(Img{i}));
            end
            
        end           
        
        % --- reduces the image stack to the neighbourhood surrounding 
        %     the location, fP0
        function [ImgL,pOfs] = reduceImageStack(obj,Img,fP0,W)
            
            % sets the image neighbourhood
            if exist('W','var')
                W = max(21,max(obj.iMov.szObj));
            end
            
            % initialisations            
            [szL,N] = deal(size(Img{1}),1+(W-1)/2);
            
            % sets up the feasible row/column indices
            [iR,iC] = deal(fP0(2)+(-N:N),fP0(1)+(-N:N));
            iR = iR((iR > 0) & (iR <= szL(1)));
            iC = iC((iC > 0) & (iC <= szL(2)));
            
            % sets the position offset and reduced image stack
            pOfs = [iC(1),iR(1)]-1;
            ImgL = cellfun(@(x)(x(iR,iC)),Img,'un',0);
            
        end           
        
        % --- sets up the image stack for the region index, iApp
        function [ImgL,ImgBG] = setupRegionImageStack(obj,iApp)
            
            % sets the region row/column indices
            ImgL = getRegionImgStack...
                            (obj.iMov,obj.Img,obj.iFrmR,iApp,obj.isHV);
            
            % calculates the background/local images from the stack    
            if obj.isHT
                ImgBG = obj.iMov.Ibg{obj.iPh}{iApp}; 
                
            else
                ImgBG = obj.iMov.Ibg{obj.iPh}{iApp};             
                Iref = mean(ImgBG(:),'omitnan');

                % determines if mean of any of the frame images are outside 
                % the tolerance, pTolPh (=5)
                ImgLmn = cellfun(@(x)(mean(x(:),'omitnan')),ImgL);
                isOK = abs(ImgLmn-Iref) < obj.trkP.pTolPh;  
                if any(~isOK)
                    % if so, then reset the 
                    ImgL(~isOK) = cellfun(@(x,dy)(x-(dy-Iref)),...
                                ImgL(~isOK),num2cell(ImgLmn(~isOK)),'un',0);
                end
                
                % removes the rejected regions from the sub-images
                [iR,iC] = deal(obj.iMov.iR{iApp},obj.iMov.iC{iApp});
                Bw = getExclusionBin(obj.iMov,[length(iR),length(iC)],iApp);
                ImgBG = ImgBG.*Bw;
                ImgL = cellfun(@(I)(I.*Bw),ImgL,'un',0);
            end            
            
        end           

        % ------------------------------------------------ %
        % --- SPECIAL PHASE IMAGE STACK SETUP FUNCTION --- %
        % ------------------------------------------------ %
        
        % --- sets up the special phase image stack for analysis
        function ImgSegS = setupSpecialImgStack(obj,ImgL,iRT,iCT,iApp,fok)
            
            % memory allocation
            ImgSegS = cell(size(fok));
            ImgBG = obj.iMov.Ibg{obj.iPh}{iApp};
            
            % sets up the image stack for all sub-regions
            for iT = find(fok(:)')
                % retrieves the image stack for the sub-region
                ImgSL = cellfun(@(x)(x(iRT{iT},iCT)),ImgL,'un',0);
                Bw = getExclusionBin(obj.iMov,size(ImgSL{1}),[]);                
                
                % sets up the special residual image stack
                if obj.nI > 0
                    IbgSL = ImgBG(iRT{iT},iCT);
                else
                    IbgSL = ImgBG(iRT{iT},:);
                end
                ImgSegS{iT} = cellfun(@(x)(Bw.*max(0,IbgSL-x)),ImgSL,'un',0);
            end
            
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
            iStatus = obj.iMov.StatusF{obj.iPh};
            [I,iM] = deal(obj.Img{iImg},obj.iMov);
            [nR,nC] = deal(iM.nRow,iM.nCol);
            ILp = cellfun(@(ir,ic)(I(ir,ic)),iM.iR,iM.iC,'un',0);            
            
            % creates the image/location plots for each sub-region  
            figure;
            if isFull
                % memory allocation
                h = subplot(1,1,1);
                
                % creates the full image figure
                plotGraph('image',I,h)
                hold on
                
            else           
                % memory allocation
                h = zeros(obj.nApp,1);
                
                % creates the figure displaying each region separately
                for iApp = find(obj.iMov.ok(:)')
                    h(iApp) = subplot(nR,nC,iApp);
                    plotGraph('image',ILp{iApp},h(iApp)); 
                    hold on
                end
            end

            % plots the most likely positions     
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
                isMove = iStatus(:,iApp) == 1;
                plot(h(j),fPosP(isMove,1),fPosP(isMove,2),'go');
                plot(h(j),fPosP(~isMove,1),fPosP(~isMove,2),'ro');
            end  
        end                             
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- calculates the global coords from the sub-region reference
        function calcGlobalCoords(obj)
            
            % exit if not calculating the background
            if ~obj.calcOK; return; end            
            
            % memory allocation
            [~,nFrm] = size(obj.fPos);
            obj.fPosG = repmat(arrayfun(@(x)(NaN(x,2)),...
                                                obj.nTube,'un',0),1,nFrm);
            obj.pMaxG = repmat(arrayfun(@(x)(cell(x,1)),...
                                                obj.nTube,'un',0),1,nFrm);                                            
            
            % converts the coordinates from the sub-region to global coords
            for iApp = find(obj.iMov.ok(:)')
                % calculates the x/y offset of the sub-region
                xOfs = obj.iMov.iC{iApp}(1)-1;
                yOfs = obj.iMov.iR{iApp}(1)-1;
                
                % calculates the global offset and appends it to each frame
                pOfs = repmat([xOfs,yOfs],obj.nTube(iApp),1);
                for i = 1:nFrm
                    obj.fPosG{iApp,i} = obj.fPos{iApp,i} + pOfs;
                    obj.pMaxG{iApp,i} = num2cell(obj.fPosG{iApp,i},2);
                end
            end 
            
        end           
        
        % --- closes the progressbar (if created within internally)
        function performHouseKeepingOperations(obj)
           
            % clears the temporary image array fields
            obj.IR = [];
            obj.y0 = [];            
            
        end       
        
        % --- retrieves the sub-region indices
        function [iRT,iCT] = getSubRegionIndices(obj,iApp,nCol)
            
            % sets the row/column indices
            [iRT,iCT] = deal(obj.iMov.iRT{iApp},1:nCol);
            
            % interpolates the images (if large)
            if obj.nI > 0
                iCT = (obj.nI+1):(2*obj.nI):nCol;
                iRT = cellfun(@(x)(x((obj.nI+1):2*obj.nI:end)),iRT,'un',0);
            end
            
        end
        
        % --- downsamples the coordinates
        function fP = downsampleCoord(obj,fP0)
            
            fP = roundP(((fP0-1)/obj.nI - 1)/2 + 1);
        
        end
        
        % --- determines if a blob is within the edge limits
        function isIn = withinEdge(obj,indR,fPest)
            
            if obj.iMov.is2D
                % don't consider for 2D...
                isIn = false;
                
            else
                % otherwise, determine if the blob is close to the limits
                % of the locations it has already taken
                xHi = obj.iMov.iCT{indR(1)}(end) - obj.dTol;
                xLT = min(max(obj.xLim{indR(1)}(indR(2),:),obj.dTol),xHi);
                xEst = min(max(fPest(1),obj.dTol),xHi);                
                
                dxLim = abs(xLT - xEst);
                isIn = any(dxLim < obj.dTol/2);
            end
            
        end        
        
        % --- calculates the distance tolerance
        function dTolMax = getDistTol(obj)
            
            dTolMax = 1.5*(1 + ~obj.isStat);
            
        end        
        
    end
    
    % static class methods
    methods (Static)        
        
        % --- calculates the coordinates of the linear indices, ind
        function fP = calcCoords(sz,ind)
            
            [yP,xP] = ind2sub(sz,ind);
            fP = [xP(:),yP(:)];
            
        end
        
        % --- calculates the COM of the blob given by, indB
        function varargout = calcCOM(I,indB)
            
            [yB,xB] = ind2sub(size(I),indB);
            [xCOM,yCOM] = deal(mean(xB),mean(yB));
            
            if nargout == 1
                varargout = {[xCOM,yCOM]};
            else
                varargout = {xCOM,yCOM};
            end
            
        end        
        
%         % --- calculates the special phase residual image stack
%         function ImgSR = calcSpecialResidualImages(ImgSL0,Bw,I0)
%             
%             % parameters            
%             nFrmSL = length(ImgSL0);
%             ImgSR = cell(nFrmSL,1);
%             
%             % sets up the residual images for all frames
%             xiF = 1:nFrmSL;
%             for i = xiF
%                 % sets up the surrounding frame indices
%                 xiSL = xiF ~= i;
%                 
%                 % calculates the residual image mask
%                 Inw = [ImgSL(xiSL),I0];
%                 Itmp = cellfun(@(x)(max(0,x-ImgSL{i})),Inw,'un',0);
%                 ImgSR{i} = calcImageStackFcn(Itmp,'max');
% %                 ImgSR{i} = calcImageStackFcn(Itmp,'max')./(1 + ImgSL0{i});
%             end
%             
%         end               

    end    
    
end
