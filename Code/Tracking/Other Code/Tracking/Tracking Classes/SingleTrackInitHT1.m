classdef SingleTrackInitHT1 < handle
    
    % class properties
    properties
   
        % main class properties
        trObj
        
        % struct class fields
        IL
        IR
        iMov        
        hProg
        
        % array class fields
        hC        
        IbgT
        IRef
        pStats
        isAmbig
        szObjHT1
        
        % tolerances
        pLo = 100;        
        dZTol = 2;
        dTol0 = 7.5;
        
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
        nFrmAdd = 20;
        
    end
    
    % class methods
    methods
       
        % --- class constructor
        function obj = SingleTrackInitHT1(trObj)
        
            % sets the main class fields
            obj.trObj = trObj;
            
            % sets the other fields
            obj.hProg = trObj.hProg;
            obj.wOfsL = trObj.wOfsL;
            obj.nApp = trObj.nApp;            
            obj.iMov = trObj.iMov;
            obj.nI = trObj.nI;            
            
            % resets the distance tolerance field
            obj.dTol = obj.calcDistTol();
                        
        end
        
        % --- analyses the entire video for the initial locations
        function analysePhase(obj)
            
            % updates the progress-bar
            wStrNw = 'Special Phase Detection (Phase #1)';
            pW0 = 2/(obj.trObj.pWofs+obj.trObj.nPhase);
            if obj.hProg.Update(1+obj.wOfsL,wStrNw,pW0)
                obj.trObj.calcOK = false;
                return
            else
                % resets the secondary field
                wStrNw1 = 'Initialising Region Analysis...';
                obj.hProg.Update(2+obj.wOfsL,wStrNw1,0);
            end
            
            % field retrieval
            obj.hC = cell(obj.nApp,1);
            obj.szObjHT1 = NaN(obj.nApp,2);
            nFrmPh = length(obj.trObj.Img{1});            
            [iR,iC] = deal(obj.iMov.iR,obj.iMov.iC);  
            
            % determines the 
            for iApp = find(obj.iMov.ok(:)')
                % update the waitbar figure
                wStr = sprintf('Analysing Region (%i of %i)',iApp,obj.nApp);
                if obj.hProg.Update(2+obj.wOfsL,wStr,iApp/obj.nApp)
                    % if the user cancelled, then exit
                    obj.trObj.calcOK = false;
                    return
                else
                    % resets the tertiary field
                    wStrNw2 = 'Initialising Sub-Region Analysis...';
                    obj.hProg.Update(3+obj.wOfsL,wStrNw2,0);                    
                end     
                                
                % field retrieval
                iRT = obj.iMov.iRT{iApp};
                xiF = 1:getSRCount(obj.iMov,iApp);
                fOK = obj.iMov.flyok(xiF,iApp);                
                nRT = ceil(median(cellfun(@length,iRT))); 
                QmxF = zeros(length(iRT),nFrmPh);

                % ------------------------- %
                % --- IMAGE STACK SETUP --- %
                % ------------------------- %                
                
                % calculates the background reference image
                IL0 = cellfun(@(x)...
                    (x(iR{iApp},iC{iApp})),obj.trObj.Img{obj.iPh},'un',0); 
                obj.IRef = uint8(calcImageStackFcn(IL0));
                obj.trObj.IbgR{obj.iPh,iApp} = obj.IRef;
                
                % retrieves the sub-region image stack
                obj.IL = calcHistMatchStack(IL0,obj.IRef);
                clear IL0
                
                % sets the background image estimate
                obj.IbgT = calcImageStackFcn(obj.IL,'ptile',obj.pT);
                obj.trObj.iMov.Ibg{obj.iPh}{iApp} = obj.IbgT;
                                
                % calculates the residual image stack
                obj.IR = obj.calcImageResidual(obj.IL,obj.IbgT);
                obj.pStats = obj.calcImageStackStats(obj.IR);  
                obj.nFrm = length(obj.IR);
                
                % ----------------------------- %
                % --- MOVEMENT STATUS FLAGS --- %
                % ----------------------------- %                
                
                % calculates the offset residual values
                ZR = max(calcImageStackFcn(obj.IR,'max'),[],2);
                ZRO = imopen(ZR,ones(nRT,1));
                dZR = (ZR - ZRO)./ZRO;
                
                % determines the movement status flag for each sub-region
                Zmx = obj.getSubRegionValues(dZR,iRT,fOK);
                isZTol = Zmx < obj.dZTol;
                
                % sets the status/movement flags                
                obj.trObj.sFlagT{obj.iPh,iApp} = 1 + double(isZTol);
                obj.trObj.sFlagT{obj.iPh,iApp}(~fOK) = NaN;
                obj.trObj.mFlag{obj.iPh,iApp} = 2 - double(isZTol);
                obj.trObj.pStatsF{obj.iPh,iApp} = obj.pStats;
                
                % ----------------------------------- %
                % --- BLOB DETECTION CALCULATIONS --- %
                % ----------------------------------- %
                
                % memory allocation
                IRL = cell(obj.nFrm,length(fOK));
                
                % calculates the position of the blobs over all frames
                wStr = 'Initial Sub-Region Detection...';
                obj.hProg.Update(3+obj.wOfsL,wStr,1/3);
                for iFly = find(fOK(:)')
                    IRL(:,iFly) = cellfun(@(x)(x(iRT{iFly},:)),obj.IR,'un',0);
                    QmxF(iFly,:) = obj.calcBlobPos(IRL(:,iFly),iApp,iFly);
                end

                % ------------------------------- %
                % --- AMBIGUOUS REGION SEARCH --- %
                % ------------------------------- %
                
                % determines if there are any ambiguous locations
                % (residuals which are outliers relative to the population)
                obj.QmxTol = prctile(QmxF(:),25) - 1.25*iqr(QmxF(:));
                obj.isAmbig = QmxF < obj.QmxTol;   
                obj.isAmbig(obj.trObj.sFlagT{obj.iPh,iApp} == 2,:) = false;                
                
                % determines if there are any "ambiguous" locations
                % (locations where flies have very low residuals)
                if any(obj.isAmbig(:))                    
                    % searches through each of the ambiguous frames
                    iGrpA = obj.setupSearchGroups(obj.isAmbig,fOK);
                    nGrpA = size(iGrpA,1);
                    
                    % searches each of the frame groups
                    for j = 1:nGrpA
                        % updates the progressbar
                        pW = (1/3)*(1 + 2*j/nGrpA);
                        wStr = sprintf('Checking Group (%i of %i)',j,nGrpA);                        
                        if obj.hProg.Update(3+obj.wOfsL,wStr,pW)
                            % if the user cancelled, then exit
                            obj.trObj.calcOK = false;
                            return
                        end                        
                        
                        % performs the search for the ambiguous object
                        obj.searchAmbigPos(iGrpA(j,:),iApp);
                    end
                end
                
                % sets the residual values (for quality calculations)
                obj.trObj.Is{obj.iPh,iApp} = {obj.IR,obj.IR};
                
                % 
                sz = size(obj.IR{1});
                xiF = 1:getSRCount(obj.iMov,iApp);
                
                %
                fOK0 = obj.iMov.flyok(xiF,iApp);
                fPT0 = obj.trObj.fPosL{obj.iPh}(iApp,:);
                yOfs = cellfun(@(x)(x(1)-1),obj.iMov.iRT{iApp});
                
                % sets the residual values at the final points
                for j = 1:obj.nFrm
                    fPT = fPT0{j} + [zeros(length(yOfs),1),yOfs];
                    fOK = fOK0 & ~isnan(fPT(:,1));
                    indP = sub2ind(sz,fPT(fOK,2),fPT(fOK,1));
                    obj.trObj.IPos{obj.iPh}{iApp,j}(fOK) = obj.IR{j}(indP);
                end
                
                % only set up the template if missing and there are fly
                % locations known with reasonable accuracy
                if isempty(obj.hC{iApp})
                    if any(~obj.isAmbig(:))
                        obj.setupFlyTemplate(IRL,fOK,iApp);
                    else
                        return
                    end
                end
                
                % updates the waitbar figure
                wStr = 'Sub-Region Detection Complete';
                obj.hProg.Update(3+obj.wOfsL,wStr,1);                
            end            
            
            % sets the final expanded template images
            obj.trObj.hCQ = obj.trObj.expandImageArray(obj.hC);
            
            % calculates the global coordinates
            obj.trObj.calcGlobalCoords(1);            
            
        end        
        
        % ------------------------------------------ %
        % --- FLY TEMPLATE CALCULATION FUNCTIONS --- %
        % ------------------------------------------ %
        
        % --- calculates the fly template image (for the current region) 
        function setupFlyTemplate(obj,IRL,fOK,iApp)
                
            % sets the known fly location coordinates/linear indices
            IRL = IRL(:,fOK);
            fPos0 = obj.trObj.fPosL{obj.iPh}(iApp,:);
            fPosT = cellfun(@(x)(x(fOK,:)),fPos0,'un',0)';    
            
            % sets up and runs the template optimisation object
            tObj = FlyTemplate(obj,iApp);
            tObj.setupFlyTemplate(IRL,fPosT);             
            
            % sets 
            obj.szObjHT1(iApp,:) = obj.iMov.szObj;
            
        end        
        
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
            for iFrm = 1:size(obj.trObj.fPosL{obj.iPh},2)
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
            dnFrm = min(64,diff(obj.trObj.indFrm{1}(1:2))/2);
            
            % retrieves the initial raw/residual images
            iFrmL = iFrmG(xiFL);          
            ImgL0 = cellfun(@(x)(x(iRT,:)),obj.IL(xiFL),'un',0);
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
                BNw = obj.getThresholdBinary(ImgR);
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
            
            % sets the new/current coordinates and 
            if isempty(pNw); pNw = getMaxCoord(ImgR); end
            pPr = obj.trObj.fPosL{obj.iPh}{iApp,iFrm(1)}(iRow,:);
            if pdist2(pNw,pPr) > obj.dScl            
                % if the distance between the points is large, then
                % reassign the points (find the point with the highest
                % residual/raw image ratio)
                pPr = obj.resetFramePos(ImgL0{1},ImgR0{1},pNw,iApp,iRow);
                obj.trObj.fPosL{obj.iPh}{iApp,iFrm(1)}(iRow,:) = pPr;
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
                pNw = obj.trObj.fPosL{obj.iPh}{iApp,j}(iRow,:);                
                
                % if the distance between the points is high, then
                % determine the most likely point closest to the previous
                if pdist2(pNw,pPr) > obj.dScl                    
                    [ILnw,IRnw] = deal(obj.IL{j}(iRT,:),obj.IR{j}(iRT,:));
                    pPr = obj.resetFramePos(ILnw,IRnw,pNw,iApp,iRow);
                    obj.trObj.fPosL{obj.iPh}{iApp,j}(iRow,:) = pPr;                    
                end
                
                % resets the previous 
                pPr = pNw;
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
            IbgTL = obj.IbgT(iRT,:);            
            
            % enhances/de-enhances the background image
            IbgTL(BNw) = min(255,IbgTL(BNw) + obj.QmxTol/4);
            IbgTL(BRmv) = max(0,IbgTL(BRmv) - obj.QmxTol/2);
            obj.trObj.iMov.Ibg{obj.iPh}{iApp}(iRT,:) = IbgTL;
            
        end
            
        % --- sets up the residual image
        function [ImgR,ImgL] = setupResidualImage(obj,iFrm,iApp,iRow)
            
            % sets the row indices            
            [iR,iC] = deal(obj.iMov.iR{iApp},obj.iMov.iC{iApp});
            iRT = obj.iMov.iRT{iApp}{iRow};
            
            % reads/sets the sub-region image and calculates the residual
            Img = obj.trObj.getImageStack(iFrm,1,1);
            ImgL0 = calcHistMatchStack({Img(iR,iC)},obj.IRef);
            
            % applies the smooth filter (if specified)
            if obj.trObj.useFilt
                ImgL0 = imfiltersym(ImgL0{1},obj.trObj.hS);
            else
                ImgL0 = ImgL0{1};
            end
            
            % sets the sub-region raw/residual images
            ImgL = ImgL0(iRT,:);
            ImgR0 = obj.calcImageResidual({ImgL},obj.IbgT(iRT,:)); 
            ImgR = ImgR0{1};
            
        end                        
        
        % --- calculates the threshold binary
        function B = getThresholdBinary(obj,I)
            
            B = I > obj.QmxTol;
            
        end        
        
        % --- calculates the distance tolerance value
        function dTolT = calcDistTol(obj)
            
            % calculates the distance tolerance
            if isempty(obj.iMov.szObj)
                dTolT = obj.dTol0;
            else
                % scales the value (if interpolating)
                dTolT = (3/4)*min(obj.iMov.szObj);                        
                if obj.nI > 0
                    dTolT = ceil(dTolT/obj.nI);
                end
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
        
    end
    
end
