classdef FilterResObj < handle
    
    % class properties
    properties
       
        % main gui handles
        iMov
        hProg
        fPos
        
        % ambiguous object class fields
        fPosAm
        isAmbig
        
        % image array fields
        IL
        IR
        IRs
        dIRs
        Bexc
        hC
        
        % sub-region maxima 
        pR
        iMax
        pMax
        pMaxS
        pMaxM
        RMaxS
        sFlag
        mFlag        
        
        % plotting fields
        hAxP
        hFigP
        hMarkA
        hMarkF
        hMarkAm
        iFrmP
        hTitleP        
        
        % parameters
        pW0 = 0.1;
        pW1 = 0.4;   
        pWS = 1.5;
        pTolBB = 0.1;        
        
        % other class fields
        hS
        hG
        okS
        iApp
        iPh
        nFrm
        nT
        dTol
        yOfs 
        wOfsL
        calcOK = true;
        xi = 10:5:30;        
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = FilterResObj(iMov,hProg,wOfsL)
            
            % sets the other input arguments            
            if exist('hProg','var')
                obj.hProg = hProg;
            end            
            
            % sets the input arguments
            obj.iMov = iMov;
            obj.wOfsL = wOfsL;            
            
            % initialises the class fields
            obj.initClassFields();
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % memory allocation
            obj.hC = cell(length(obj.iMov.ok),1);
            
            % sets the distance tolerance
            if isfield(obj.iMov,'szObj')
                obj.dTol = (3/4)*min(obj.iMov.szObj);
            else
                obj.dTol = 7.5;
            end
            
            % sets up the disk filter masks
            obj.hS = arrayfun(@(x)(fspecial('disk',x)),obj.xi,'un',0);
            
        end
        
        % --- clears the class fields
        function clearClassFields(obj)
            
            % clears the image stack arrays
            obj.IR = [];
            obj.IRs = [];
            obj.Bexc = [];
            
            % clears the other fields
            obj.pR = [];
            obj.iMax = [];
            
        end
        
        % ---------------------------------------- %
        % --- IMAGE STACK PROCESSING FUNCTIONS --- %
        % ---------------------------------------- %
        
        % --- processes the image stack
        function processImgStack(obj,IL,iPh,iApp)
            
            % sets the input arguments
            [obj.IL,obj.iPh,obj.iApp] = deal(IL,iPh,iApp);
            
            % initialises the stack processing
            obj.initStackProcess();            
            obj.processSubRegions();
            
            % clears the class fields
            obj.clearClassFields();            
            
        end
        
        % --- initialises the stack processing fields
        function initStackProcess(obj)
            
            % initialisations  
            obj.hG = fspecial('disk',2);
            
            % updates the progressbar
            wStr = 'Setting Up Filtered Images';
            obj.hProg.Update(obj.wOfsL+3,wStr,obj.pW0);
            
            % field initialisations
            obj.nT = getSRCount(obj.iMov,obj.iApp);            
            obj.yOfs = cellfun(@(x)(x(1)-1),obj.iMov.iRT{obj.iApp},'un',0)';            
            
            % initialisations
            obj.nFrm = length(obj.IL);                        
            obj.okS = false(obj.nT,1);            
            obj.isAmbig = false(obj.nFrm,obj.nT);
            [obj.sFlag,obj.mFlag] = deal(NaN(obj.nT,1));
            [obj.RMaxS,obj.fPosAm] = deal(cell(obj.nT,1));
            [obj.pMax,obj.iMax] = deal(cell(obj.nFrm,obj.nT));
            [obj.pMaxS,obj.pR] = deal(cell(obj.nFrm,obj.nT));            
            obj.fPos = repmat({NaN(obj.nT,2)},obj.nFrm,1);
            
            % calculates the residual image stacks
            obj.IR = cellfun(@(y)(cellfun(@(h)(...
                    (imfiltersym(y,h)-y)),obj.hS,'un',0)),obj.IL,'un',0);                                    
            obj.IRs = cellfun(@(x)(...
                    calcImageStackFcn(x,'mean')),obj.IR,'un',0);                
                
            % sets up the exclusion binary mask
            obj.setupExcBinaryMask();                            
            
            % removes the excluded regions
            obj.IRs = cellfun(@(x)(obj.Bexc.*x),obj.IRs,'un',0);
            
            % calculates the residual difference image stack
            IRTmn = calcImageStackFcn(obj.IRs,'min');
            obj.dIRs = cellfun(@(x)(max(0,x-IRTmn)),obj.IRs,'un',0);
            
        end
        
        % --- processes each of the sub-regions to determine the maxima
        function processSubRegions(obj)
            
            % field retrieval
            iRT = obj.iMov.iRT{obj.iApp};
            
            % ---------------------------------- %
            % --- INITIAL LOCATION DETECTION --- %
            % ---------------------------------- %
            
            % parameters
            nFrmMin = 5;
            isShortPhase = diff(obj.iMov.iPhase(obj.iPh,:)) < nFrmMin;
            
            % updates the progressbar
            wStr = 'Analysing Sub-Regions...';
            if obj.hProg.Update(obj.wOfsL+3,wStr,obj.pW0+obj.pW1)
                % exit if the user cancelled
                obj.calcOK = false;
                return
            end            
            
            % processes each sub-region within the current region
            for iT = 1:obj.nT
                % retrieves the sub-image stack                
                IRL = cellfun(@(x)(imfiltersym...
                            (x(iRT{iT},:),obj.hG)),obj.IRs,'un',0);
                BexcT = ~bwmorph(true(size(IRL{1})),'remove');                        
                        
                % 
                if isShortPhase
                    % phase is very short in duration so check directly
                    [obj.mFlag(iT),sFlagT] = deal(2,0);
                    
                else
                    % otherwise, use the residual based methods to
                    % determine the blob's locations
                    dIRL = cellfun(@(x)(imfiltersym...
                            (x(iRT{iT},:),obj.hG)),obj.dIRs,'un',0);                
                    [sFlagT,uData] = obj.detSubRegionStatus(IRL,dIRL,BexcT);
                end                
                
                switch sFlagT
                    case {1,2}
                        % case is 
                        
                        % sets the status/ambiguity flags
                        obj.okS(iT) = true;
                        obj.sFlag(iT) = 1;
                        obj.mFlag(iT) = 3 - sFlagT;
                        
                        % updates the positional values
                        obj.setPositionValues(uData,iT);                        
                        
                    case 3
                        % case is 
                        
                        % sets the status/ambiguity flags
                        obj.okS(iT) = true;
                        [obj.sFlag(iT),obj.mFlag(iT)] = deal(2,1);
                        
                        % updates the positional values
                        obj.setPositionValues(uData{1},iT);
                        obj.setStatPosData(IRL,uData{2},uData{3},iT);
                        
                    case 4
                        % case is there are multiple candidates for 
                        % stationary blobs
                        
                        % sets the status/ambiguity flags
                        obj.okS(iT) = false;
                        [obj.sFlag(iT),obj.mFlag(iT)] = deal(2,1);
                        
                        % sets the positional data values
                        obj.setStatPosData(IRL,uData{1},uData{2},iT);
                            
                    otherwise
                        % case is either 1 frame or ambiguous                                                                       

                        % segments the static locations
                        [obj.sFlag(iT),obj.mFlag(iT)] = deal(2,1);
                        obj.segStatFlyLocations(IRL,BexcT,iT);                                                
                        
                end                      
                   
            end
            
            % --------------------------------- %
            % --- FLY OBJECT TEMPLATE SETUP --- %
            % --------------------------------- %            

            % updates the progressbar
            wStr = 'Calculating Fly Object Template';
            if obj.hProg.Update(obj.wOfsL+3,wStr,0.75)
                % exit if the user cancelled
                obj.calcOK = false;
                return
            end
            
            % only set up the template if missing and there are fly
            % locations known with reasonable accuracy
            if isempty(obj.hC{obj.iApp}) && any(obj.okS)
                obj.setupFlyTemplate()
            end            
            
            % --------------------------------- %
            % --- FLY OBJECT TEMPLATE SETUP --- %
            % --------------------------------- %            
            
            % updates the progressbar
            wStr = 'Resegmenting Ambiguous Sub-Regions';
            if obj.hProg.Update(obj.wOfsL+3,wStr,0.9)
                % exit if the user cancelled
                obj.calcOK = false;
                return
            end            
            
            % re-segments the ambiguous regions
            for iT = find(~obj.okS(:)')
                obj.redoFlyPosDetect(iT);
            end
                            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %                        
            
            % updates the progressbar
            wStr = 'Filtered Image Analysis Complete';
            obj.hProg.Update(obj.wOfsL+3,wStr,1);
            
        end
        
        % --- sets the static blob positional data
        function setStatPosData(obj,IRL,pMaxS0,iMaxS0,iT)

            % sets the stationary location/position values
            pMaxC = num2cell(cell2cell(pMaxS0,0),2);
            [obj.pMaxS(:,iT),obj.pMax(:,iT)] = ...
                    deal(cellfun(@(x)(cell2mat(x(:))),pMaxC,'un',0));

            % sets the filtered image residual peak values
            RmaxS0 = cellfun(@(x)(cellfun(@(y,z)...
                        (y(z)),IRL,num2cell(x))),iMaxS0,'un',0);
            obj.RMaxS{iT} = cell2mat(RmaxS0')';

        end        
        
        % --- determine sub-region status flags/positional data
        function [sFlagT,uData] = detSubRegionStatus(obj,IRL,dIRL,Bexc)
            
            % parameters
            pW = 2;
            ZMxTol = 6;
            ZMxTolM = 8;
            njMxMax = 10;
            
            % initialisations
            isJitter = false;
            [sFlagT,uData] = deal(0,[]);
            
            % calculates the number of significant residual peaks have been
            % determined for each sub-image
            jMx = cellfun(@(x)(obj.getSigPeaks(x,Bexc,1)),dIRL,'un',0);            
            
            %
            njMx = cellfun(@length,jMx);
            isU = njMx == 1;
            if all(isU)
                % if each frame is unambiguous, then flag the object has
                % moved over the video phase (and exits the function)
                fPMx = cellfun(@(x,y)(obj.calcCoords(x,y)),IRL,jMx,'un',0);
                [sFlagT,uData] = deal(1,fPMx);
                return
                            
            elseif all(isU(njMx>0)) && all(njMx(~isU) == 0)  
                % case where all 
                
                % calculates the z-scores for the peaks (on frames where
                % there is a unique peak)
                ZMxU = cellfun(@(x,y)...
                        (obj.calcZScore(x,y)),dIRL(isU),jMx(isU));
                if all(ZMxU > ZMxTolM)                
                    % fills in the missing frames with the peak values
                    jj = njMx == 0;
                    jMx(jj) = cellfun(@(x)(argMax(x(:))),IRL(jj),'un',0);

                    % calculates the peak coordintes and returns a moving flag
                    fPMx = cellfun(@(x,y)(obj.calcCoords(x,y)),IRL,jMx,'un',0);
                    [sFlagT,uData] = deal(1,fPMx);
                    return
                else
                    % if there are no maxima then 
                    [sFlagT,uData] = deal(0,[]);
                    return                     
                end
                
            elseif any(njMx == 0)
                % if there are no maxima then 
                [sFlagT,uData] = deal(0,[]);
                return                
            end
                                
            % calculates the coordinates of the residual peaks
            dfPMx = cellfun(@(x,y)(obj.calcCoords(x,y)),dIRL,jMx,'un',0);                            
            ZMx = cellfun(@(x,y)(obj.calcZScore(x,y)),dIRL,jMx,'un',0);
            if all(cellfun(@(x)(max(x(:))),ZMx) < ZMxTol)
                % if the maxima are all below tolerance, then the 
                % blob is probably stationary 
                [sFlagT,uData] = deal(0,[]); 
                return
            end
            
            % determine if there are any static peak groupings
            indDG = obj.findStaticPeakGroups(dfPMx);
            if ~isempty(indDG)
                % if so, determine their peak values are significant. 
                % if so, then the static point is probably jittering
                ZMxG = cellfun(@(z)(min(cellfun...
                            (@(x,y)(x(y)),ZMx,num2cell(z)))),indDG);
                if length(ZMxG) > 1
                    iZMx = argMax(ZMxG);
                    [ZMxG,indDG] = deal(ZMxG(iZMx),indDG(iZMx));
                end

                % determines if the z-scores meet jitter tolerance
                isJitter = all(ZMxG > ZMxTol);
            end
                
            if (mean(isU) >= 0.5) && ~isJitter
                %
                iZMx = cellfun(@(x)(argMax(x)),ZMx,'un',0);
                ZMxT = cellfun(@(x,y)(x(y)),ZMx,iZMx);
                
                %
                if all(ZMxT > ZMxTolM)
                    % if there are no maxima then 
                    pMx = cellfun(@(x,y)(x(y,:)),dfPMx,iZMx,'un',0);
                    [sFlagT,uData] = deal(1,pMx);
                    return                                    
                end                
            end

            % if not jittering, and there are unique points, then determine
            % if there is significant movement for these unique points
            if ~isJitter && (sum(isU) > 1)
                % calculates the range of 
                pRng = calcImageStackFcn(dfPMx(isU),'range');
                DRng = sqrt(sum(pRng.^2));

                % if the range of movement of the pixels is significant
                % and the z-scores are high, then the blob has moved
                ZMxU = cell2mat(ZMx(isU));
                if (DRng > pW*obj.dTol) && (median(ZMxU) > ZMxTol)
                    % for ambiguous frames, use the highest value point
                    jMx(~isU) = cellfun(@(x,y)(x(argMax(y(x)))),...
                                            jMx(~isU),dIRL(~isU),'un',0);

                    % calculates and returns the final values
                    fPMx = cellfun(@(x,y)...
                                (obj.calcCoords(x,y)),IRL,jMx,'un',0);
                    [sFlagT,uData] = deal(1,fPMx); 
                    return
                end
            end
            
            % calculates significant residual image peaks
            iMx = cellfun(@(x)(obj.getSigPeaks(x,Bexc,0)),IRL,'un',0);
            niMx = cellfun(@length,iMx);
            if all(niMx == 1)
                % if each frame is unambiguous, then flag the object has
                % moved over the video phase (and exits the function)
                fPMx = cellfun(@(x,y)(obj.calcCoords(x,y)),IRL,iMx,'un',0);
                [sFlagT,uData] = deal(2,fPMx);
                return
            end            
            
            % calculates the peak coordinates
            fPMx = cellfun(@(x,y)(obj.calcCoords(x,y)),IRL,iMx,'un',0);              
            [fPS,iPS] = obj.findStaticPeakGroups(fPMx,IRL,iMx);
            
            % case is there are no stationary blob groupings
            if isempty(fPS)
                % FINISH ME!?
                a = 1;
                return
                
            elseif isJitter
                % calculates the mean distance between the stationary and
                % residual peaks
                fPosR = cellfun(@(x,y)...
                        (x(y,:)),dfPMx,num2cell(indDG{1}),'un',0);
                DPR = cellfun(@(y)...
                        (mean(cellfun(@(x,y)(pdist2(x,y)),fPosR,y))),fPS);
                
                % if the mean distance is within tolerance, then the static
                % object is probably associated with the jittering
                [Dmn,iDmn] = min(DPR);
                if Dmn < obj.pWS*obj.dTol
                    [sFlagT,uData] = deal(2,fPS{iDmn});
                    return
                end
                    
            elseif (mean(njMx) > njMxMax) && (sum(isU) <= 1)
                % if there are too many residual peaks, then flag that the
                % groupings need to be further analysed
                [sFlagT,uData] = deal(4,{fPS,iPS});
                return
                
            end
            
            % checks each of the static groups to determine if there
            % are any candidates that are in close proximity to
            % significant residual peaks (indicates jittering movement)                
            
            % memory allocation
            nS = length(fPS);
            iDT = cell(nS,1);
            isPr = false(nS,1);
            DR = NaN(obj.nFrm,nS);            
            
            % calculates the residual peak coordinates
            if ~exist('dfPMx','var')
                dfPMx = cellfun(@(x,y)(obj.calcCoords(x,y)),dIRL,jMx,'un',0);
            end
            
            % determines if any of the stationary points are in close
            % proximity to residual peaks (on each frame)
            for i = 1:nS
                DT = cellfun(@(x,y)(pdist2(x,y)),dfPMx,fPS{i},'un',0);
                iDT{i} = cellfun(@(x)(argMin(x)),DT);

                DR(:,i) = cellfun(@(x,y)(x(y)),DT,num2cell(iDT{i}));
                isPr(i) = all(DR(:,i) < pW*obj.dTol);
            end
            
            % determines if there are any potential jittering candidates 
            switch sum(isPr)
                case 0
                    % case is there are no potential matches
                    
                    if (sum(isU) > 1) && (mean(cell2mat(ZMx(isU))) > ZMxTol)                        
                        % if there are frame with unambiguous residual 
                        % peaks, then the blob is probably moving
                        jMx(~isU) = cellfun(@(x,y)(x(argMax(y(x)))),...
                                    jMx(~isU),dIRL(~isU),'un',0);
                    
                        % calculates and returns the final values
                        fPMx = cellfun(@(x,y)...
                                    (obj.calcCoords(x,y)),IRL,jMx,'un',0);
                        [sFlagT,uData] = deal(2,fPMx); 
                    else
                        % otherwise flag the point is ambiguous (needs the
                        % x-correlation transform to determine further)                        
                        [sFlagT,uData] = deal(4,{fPS,iPS});
                    end
                    
                case 1
                    % case is there is a unique potential match
                    
                    % flag that the point is jittering. return also the
                    % coordinates of the stationary points
                    [sFlagT,uData] = deal(3,{fPS{isPr},fPS,iPS});                    
                
                otherwise
                    % case is there are multiple potential matches
                                                    
                    if sum(isU) > 1
                        % if there are multiple frames with unambiguous
                        % points, then determine the stationary point that
                        % is closest to these unambiguous points
                        iPr = find(isPr);
                        iMn = argMin(median(DR(isU,isPr),1));
                        
                        % flag that the point is jittering. return also the
                        % coordinates of the stationary points
                        [sFlagT,idxF] = deal(3,num2cell(iDT{iPr(iMn)}));
                        pMx = cellfun(@(x,y)(x(y,:)),dfPMx,idxF,'un',0);
                        uData = {pMx,fPS,iPS};
                        
                    else
                        % otherwise flag the point is ambiguous (needs the
                        % x-correlation transform to determine further)                        
                        [sFlagT,uData] = deal(4,{fPS,iPS});
                    end
            end
            
        end        
        
        % --- determines the likely fly positions over all frames for a
        %     stationary fly in sub-region index, iT
        function segStatFlyLocations(obj,IRL,BexcT,iT)
        
            % otherwise, the fly is probably stationary
            [pRT,pMaxT,iMaxT] = deal(cell(obj.nFrm,1));
            for iFrm = 1:obj.nFrm
                [pRT{iFrm},pMaxT{iFrm},iMaxT{iFrm}] = ...
                                obj.calcMaximaProps(IRL{iFrm},BexcT);
            end
            
            % determines the number of maxima on each frame
            nP = cellfun(@length,pRT);
            if all(nP == 1)
                % if there only unique maxima, then update their locations
                % with the storage array and exits the function
                obj.okS(iT) = true;
                obj.setPositionValues(pMaxT,iT);
                
                % sets the static position data fields
                iMaxTF = {cell2mat(iMaxT(:))};
                obj.setStatPosData(IRL,{pMaxT},iMaxTF,iT)
                return
            end
            
            % other initialisations                      
            RMaxT = cellfun(@(x,y)(x(y)),IRL,iMaxT,'un',0);                        
            
            % determines the stationary grouping index flags
            [fPosNw,obj.okS(iT)] = obj.detLikelyFlyPos(pMaxT,RMaxT,iT);
            if obj.okS(iT)
                % if successful, then update the positional values
                obj.setPositionValues(fPosNw,iT);
            end
            
        end
        
        % --- determines the likely fly positional coordinates. if the fly
        %     location is reasonably inambiguous, then the return an ok
        %     flag value of true (otherwise, position is resegmented using
        %     convolution in the function @redoFlyPosDetect)
        function [fP,ok] = detLikelyFlyPos(obj,pMaxM0,RMaxM,iT)
            
            % memory allocation
            ok = true;
            pMaxS0 = cell(size(pMaxM0));            
            fP = repmat({NaN(1,2)},obj.nFrm,1);
            isS = cellfun(@(x)(false(size(x,1),1)),pMaxM0,'un',0);                        
            
            % ---------------------------------- %
            % --- STATIONARY POINT DETECTION --- %
            % ---------------------------------- %
            
%             % determines if any points are static over all frames
%             [sFlagU,~,iC] = unique(sFlagGrp);
%             ii = find(sFlagU > 0);
%             nC = arrayfun(@(x)(sum(iC==x)),ii);  
%             
%             if iT == 7
%                 a = 1;
%             end
%             
%             % determines indices of the stationary points for each group
%             for i = find(nC(:)' == obj.nFrm)
%                 for j = 1:obj.nFrm
%                     k = find(sFlagGrp(:,j) == i);
%                     iMaxS{j} = [iMaxS{j};k];
%                     isS{j}(k) = true;
%                 end                                
%             end
            
            % determines the static group index flags
            indG = obj.findStaticPeakGroups(pMaxM0,RMaxM);

            % storage for the stationary points residuals (if any)
            nGrpS = length(indG);
            if nGrpS == 0
                % if no stationary groups were found, then exit 
                ok = false;
                return
                
            else
                % otherwise, allocation memory for the metric arrays
                RMaxTS = zeros(nGrpS,obj.nFrm);
                
                % sets the stationary object flags
                for i = 1:nGrpS
                    for j = 1:length(indG{i})
                        isS{j}(indG{i}(j)) = true;
                    end
                end
            end
            
            % ------------------------------------- %
            % --- STATIONARY/MOVING POINT SPLIT --- %
            % ------------------------------------- %                        

            if iT == 7
                a = 1;
            end            
            
            %
            indGT = cell2mat(indG(:)')';
            
            % splits the maxima into stationary/non-stationary groups            
            for iFrm = 1:obj.nFrm
                % sets the stationary points for the frame (if any)
                pMaxS0{iFrm} = pMaxM0{iFrm}(indGT(:,iFrm),:);
                RMaxTS(:,iFrm) = RMaxM{iFrm}(indGT(:,iFrm));
                
%                 % resets the non-stationary points
%                 pMaxM0{iFrm} = pMaxM0{iFrm}(~isS{iFrm},:);
%                 RMaxM{iFrm} = RMaxM{iFrm}(~isS{iFrm});                  
            end  
            
            % sorts the stationary groups by residual values (if any)
            [RS,iS] = sort(median(RMaxTS,2,'omitnan'),'descend');
            pMaxS0 = cellfun(@(x)(x(iS,:)),pMaxS0,'un',0);
            RMaxTS = RMaxTS(iS,:);
            
            % adds the data to the class storage arrays
            obj.RMaxS{iT} = RMaxTS;
            obj.pMaxS(:,iT) = pMaxS0;                        
            
            % --------------------------------------- %
            % --- FINAL LIKELY POSITION DETECTION --- %
            % --------------------------------------- %
            
            % parameters            
            rTolS = 1.50;            
            
            % if there are only stationary groups, then return the
            % top-ranked stationary location
            if (nGrpS == 1) || (RS(1)/RS(2) > rTolS)
                % if there is only one group, use the first
                fP = cellfun(@(x)(x(1,:)),pMaxS0,'un',0);                
            else 
                % otherwise, flag as unambiguous
                ok = false;
            end
            
        end        

        % --- recalculate the fly position (using x-correlation) for the
        %     sub-regions
        function redoFlyPosDetect(obj,iT)
            
            % parameters
            pQZtol = 0.5;
            
            % field retrieval
            mStr = 'omitnan';
            iRT = obj.iMov.iRT{obj.iApp}{iT};
            IRL = cellfun(@(x)(imfiltersym(x(iRT,:),obj.hG)),obj.IRs,'un',0);
            IXC = cellfun(@(x)(calcXCorr(obj.hC{obj.iApp},x)),IRL,'un',0);

            % retrieves the x-correlation values at the maxima
            szL = size(IRL{1});  
            iPosS = cellfun(@(x)(obj.calcLinearInd...
                                (szL,x)),obj.pMaxS(:,iT),'un',0);
            irPosS = cell2mat(cellfun(@(x,y)(x(y)),IRL,iPosS,'un',0)');
            xcPosS = cell2mat(cellfun(@(x,y)(x(y)),IXC,iPosS,'un',0)');            
            
            % determines the most likely static grouping
            obj.RMaxS{iT} = irPosS.*(xcPosS.^2);
            [QZ,iS] = sort(mean(obj.RMaxS{iT},2,mStr),'descend');            
            
            % sets the values 
            if isempty(iS)
                fPosNw = repmat({NaN(1,2)},obj.nFrm,1);
            else
                iMx = iS(1);
                fPosNw = cellfun(@(x)(x(iMx,:)),obj.pMaxS(:,iT),'un',0);
            end
            
            % updates the coordinate values
            obj.setPositionValues(fPosNw,iT);
            
            % determines if there are any ambiguous points (that aren't in
            % close proximity to the candidate point)
            if length(QZ) > 1
                % if so, then calculate ratio of the objective function
                % values and determine if there are any other points with
                % relatively high values
                isAm = QZ(2:end)/QZ(1) > pQZtol;                
                if any(isAm)
                    % if there are, then retrieve the position values for
                    % each of these points
                    ix = iS(find(isAm) + 1);
                    fPosAm0 = cellfun(@(x)(x(ix,:)),obj.pMaxS(:,iT),'un',0);
                    
                    % determines if the ambiguous point(s) are not too
                    % close to the candidate point. if so, then add these
                    % points to the ambiguous 
                    isC = obj.detClosePoints(fPosNw,fPosAm0);             
                    if any(~isC)
                        obj.fPosAm{iT} = cellfun(@(x)...
                                        (x(~isC,:)),fPosAm0,'un',0);
                        obj.isAmbig(:,iT) = true;
                    end
                end
            end
            
        end           
        
        % ------------------------------------------ %
        % --- FLY TEMPLATE CALCULATION FUNCTIONS --- %
        % ------------------------------------------ %
        
        % --- calculates the fly template image (for the current region) 
        function setupFlyTemplate(obj)
                        
            % sets the known fly location coordinates/linear indices
            pOfsT = [zeros(sum(obj.okS),1),cell2mat(obj.yOfs(obj.okS))'];            
            fPosT = cellfun(@(x)(x(obj.okS,:)+pOfsT),obj.fPos,'un',0);
                        
            % keep looping until the filtered binary mask no-longer touches
            % the edge of the sub-region frame
            while 1
                % sets the sub-region size
                N = ceil(obj.dTol);
                B0 = setGroup((N+1)*[1,1],(2*N+1)*[1,1]);

                % retrieves the fly sub-image stack (for all known points)
                Isub = cell(obj.nFrm,sum(obj.okS));            
                for i = 1:obj.nFrm
                    Isub(i,:) = cellfun(@(x)(obj.getPointSubImage...
                            (obj.IRs{i},x,N)),num2cell(fPosT{i},2),'un',0)';
                end

                % calculates the sub-image stack mean image
                IsubMn = calcImageStackFcn(Isub(:),'mean');
                hC0 = max(0,IsubMn - mean(IsubMn(:)));
                [~,B] = detGroupOverlap(hC0,B0);
                obj.hC{obj.iApp} = hC0.*B;            

                % thresholds the filtered sub-image
                Brmv = normImg(obj.hC{obj.iApp}) > obj.pTolBB;   
                if all(Brmv(bwmorph(true(size(Brmv)),'remove')))
                    obj.dTol = obj.dTol + 1;
                else
                    break
                end
            end
            
            if ~isfield(obj.iMov,'szObj')
                % calculates the binary mask of the gaussian
                BrmvD = sum(Brmv(logical(eye(size(Brmv)))));
                obj.iMov.szObj = BrmvD*[1,1];
                obj.dTol = (3/4)*min(obj.iMov.szObj);
            end
            
        end

        % -------------------------- %
        % --- PLOTTING FUNCTIONS --- %
        % -------------------------- %                   
        
        % --- plots the maxima (all and known) over all frames
        function plotFrameMaxima(obj,varargin)
            
            % deletes any previous figures
            hFigPr = findall(0,'tag','hPlotMax');
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % creates the plot figure
            obj.hFigP = plotGraph('image',obj.IL{1});
            set(obj.hFigP,'tag','hPlotMax',...
                          'WindowKeyPressFcn',@obj.figKeyPress);
            obj.hTitleP = title(sprintf('Frame %i of %i',1,obj.nFrm));
                      
            % sets the axis properties
            [obj.hAxP,obj.iFrmP] = deal(gca,1); 
            [obj.hMarkA,obj.hMarkAm,obj.hMarkF] = deal([]);
            hold(obj.hAxP,'on');            
            
            % updates the frame markers
            obj.updateFrameMarkers();
            
        end
        
        % --- figure key press callback function
        function figKeyPress(obj,~,evnt)
            
            % updates the figure based on the key press
            switch evnt.Key
                case 'leftarrow'
                    % case is the right arrow key
                    if obj.iFrmP == 1
                        return
                    else
                        obj.iFrmP = obj.iFrmP - 1;
                    end
                    
                case 'rightarrow'
                    % case is the right arrow key
                    if obj.iFrmP == obj.nFrm
                        return
                    else
                        obj.iFrmP = obj.iFrmP + 1;
                    end                    
                    
                otherwise
                    % case is another key
                    return
                
            end
            
            % updates the figure
            set(findall(obj.hAxP,'Type','Image'),'CData',obj.IL{obj.iFrmP})
            
            % updates the title
            nwTitle = sprintf('Frame %i of %i',obj.iFrmP,obj.nFrm);
            set(obj.hTitleP,'string',nwTitle);

            % updates the frame markers
            obj.updateFrameMarkers();
            
        end
        
        % --- updates the frame markers
        function updateFrameMarkers(obj)
            
            % creates the all maxima plot markers
            pMax0 = arr2vec(obj.pMaxS(obj.iFrmP,:));
            yOfsT = obj.yOfs(:);            
            pPosT = cell2mat(cellfun(@(x,y)...
                        (obj.offsetYCoords(x,y)),pMax0,yOfsT,'un',0));
            
            if ~isempty(pPosT)
                if isempty(obj.hMarkA)
                    obj.hMarkA = plot(obj.hAxP,pPosT(:,1),pPosT(:,2),'r.');
                else
                    set(obj.hMarkA,'xdata',pPosT(:,1),'ydata',pPosT(:,2));
                end
            end
                        
            % plots the final position markers
            fPosP = obj.fPos{obj.iFrmP};
            if ~isempty(fPosP)   
                yPosP = fPosP(:,2) + cell2mat(obj.yOfs(:));
                if isempty(obj.hMarkF)
                    obj.hMarkF = plot(obj.hAxP,fPosP(:,1),yPosP,'gx',...
                                        'LineWidth',2);
                else
                    set(obj.hMarkF,'xdata',fPosP(:,1),'ydata',yPosP);
                end
            end
            
            % determines if there are any ambiguous points
            ii = ~cellfun(@isempty,obj.fPosAm);
            if any(ii)
                % if so then set up the plot values
                fPosAmP = cellfun(@(x)(x{obj.iFrmP}),obj.fPosAm(ii),'un',0);                
                yPosAmP = cell2cell(cellfun(@(x,y)(x+[0,y]),...
                            fPosAmP,arr2vec(obj.yOfs(ii)),'un',0));
                if isempty(obj.hMarkAm)
                    obj.hMarkAm = plot(obj.hAxP,yPosAmP(:,1),...
                                    yPosAmP(:,2),'yo','LineWidth',2);
                else
                    set(obj.hMarkAm,'xdata',yPosAmP(:,1),...
                                    'ydata',yPosAmP(:,2));
                end                        
            end
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        

        % --- sets the position values into the final position array
        function setPositionValues(obj,pMaxT,iT)
            
            % stores the positional values
            for iFrm = 1:obj.nFrm
                obj.fPos{iFrm}(iT,:) = pMaxT{iFrm};
            end
            
        end        
        
        % --- determines the static object grouping properties (if any)
        function varargout = findStaticPeakGroups(obj,fP,varargin)
            
            % parameters            
            pRRTol = 1.75;
            
            %
            switch length(varargin)
                case 1
                    % case is the max point values are input
                    RMx = varargin{1};
                    
                case 2
                    % case is the image array/max point stack is input
                    [IRL,iMx] = deal(varargin{1},varargin{2});
            end
            
            % memory allocation
            nP0 = size(fP{1},1);
            hasS = false(nP0,1);
            [iPS,fPS,indG] = deal(cell(nP0,1));
            
            % loops through each of the points (from the first frame)
            % determining if there is a stationary blob grouping
            for i = 1:nP0
                % calculates the distance/rectified ratio of the points on
                % the first frame to all the other frames
                DP = combineNumericCells(cellfun...
                            (@(x)(pdist2(fP{1}(i,:),x)),fP,'un',0));                        
                if exist('IRL','var')
                    % case is a distance/pixel value check
                    pRR = combineNumericCells(cellfun(@(x,y)...
                            (calcRectifiedRatio(IRL{1}(iMx{1}(i)),...
                            x(y))),IRL,iMx,'un',0));
                    Qm = DP./max(1,pRR);
                    Bm = (DP < obj.dTol) & (pRR < pRRTol);  
                elseif exist('RMx','var')
                    % case is 
                    pRR = combineNumericCells(cellfun(@(x)...
                            (calcRectifiedRatio(RMx{1}(i),x)),RMx,'un',0));

                    Qm = DP./max(1,pRR);
                    Bm = (DP < obj.pWS*obj.dTol) & (pRR < pRRTol);                      
                else
                    % case is a distance only check
                    [Bm,Qm] = deal(DP < obj.pWS*obj.dTol,DP);
                end
                        
                % determines points that meet the distance/RR tolerances
                hasS(i) = all(any(Bm,1));                    
                
                % continue the search only if there are points (which meet
                % the tolerances) are present on all frames
                if hasS(i)
                    % determines the frames with multiple candidate points
                    % and sets the more likely candidate
                    hasM = sum(Bm,1) > 1;
                    for j = find(hasM)
                        jj = find(Bm(:,j));
                        iQMn = jj(argMin(Qm(jj,j)));
                        Bm(:,j) = setGroup(iQMn,[size(Qm,1),1]);
                    end
                                        
                    % sets the group indices for each frame
                    if size(Bm,1) == 1
                        indG{i} = ones(size(Bm,2),1);
                    else
                        [iy,ix] = find(Bm);
                        [~,iS] = sort(ix);
                        indG{i} = iy(iS);
                    end
                    
                    % sets the linear indices/coordinates for each frame
                    if nargout == 2
                        iPS{i} = cellfun(@(x,y)(x(y)),iMx,num2cell(indG{i}));
                        fPS{i} = cellfun(@(x,y)(obj.calcCoords(x,y)),...
                                            IRL,num2cell(iPS{i}),'un',0);
                    end
                end
            end
            
            % returns the final static groupings
            if nargout == 1
                varargout = {indG(hasS)};            
            else
                varargout = {fPS(hasS),iPS(hasS)};            
            end
            
        end
        
        % --- retrieves the group status flags
        function [sFlag,nP] = getGroupFlags(obj,pMaxT,RMaxT)
                    
            % memory allocation
            pRRTolT = 1.66;
            nFrmG = length(pMaxT);
            dTolT = obj.dTol*obj.pWS;
            nP = cellfun(@(x)(size(x,1)),pMaxT);
            
            if nFrmG == 1
                sFlag = (1:max(nP))';
            else
                sFlag = zeros(max(nP),nFrmG);
            end
            
            % determines the group status flags for each maxima/frame
            for i = 1:(nFrmG-1)
                % calculates the inter-frame distances
                DP = pdist2(pMaxT{i},pMaxT{i+1});                
                if any(~isnan(DP(:)))
                    % determines the most likely path between points
                    [~,i2O] = min(DP,[],2,'omitnan');
                    [i2,~,iC] = unique(i2O);
                    indG = arrayfun(@(x)(find(iC==x)),1:max(iC),'un',0);                
                    for j = find(cellfun(@length,indG) > 1)
                        indG{j} = indG{j}(argMin(DP(indG{j},i2(j))));                    
                    end
                
                    % calculates the rectified ratios and distances
                    i1 = cell2mat(indG);
                    Dmn = DP(sub2ind(size(DP),i1(:),i2(:)));
                    
                    if exist('RMaxT','var')
                        pRR = calcRectifiedRatio...
                                        (RMaxT{i}(i1),RMaxT{i+1}(i2));
                    else
                        pRR = ones(size(Dmn));
                    end

                    % calculates the inter-frame maxima distances
                    isStat = (Dmn(:)' < dTolT) & (pRR(:)' < pRRTolT);
                    for j = find(isStat)
                        % retrieves the group index on the current frame
                        k = i1(j);
                        if sFlag(k,i) == 0
                            % case is the group flag is undefined
                            [sFnw,sFlag(k,i)] = deal(max(sFlag(:))+1);
                        else
                            % otherwise, use the group flag value
                            sFnw = sFlag(k,i);
                        end

                        % updates the group index on the next frame 
                        sFlag(i2(j),i+1) = sFnw;
                    end
                end
            end
            
        end
         
        % --- determines if the points in fPosAm0 are close to fPosNw
        function isC = detClosePoints(obj,fPosNw,fPosAm0)
        
            D0 = cellfun(@(x,y)(pdist2(x,y)),fPosAm0,fPosNw,'un',0);
            isC = mean(cell2mat(D0(:)'),2) < obj.dTol;
            
        end        
        
        % --- sets up the region exclusion binary mask
        function setupExcBinaryMask(obj)            
            
            szL = size(obj.IRs{1});
            obj.Bexc = getExclusionBin(obj.iMov,szL,obj.iApp);
            
        end             
        
        % --- calculates the maxima properties from the image IRL
        function [pR,pMax,iMax] = calcMaximaProps(obj,IRL,BexcT)
            
            % parameters
            pTol = 1/3;
            
            % parameters
            prTol = 4/3;
            
            % initialisations
            szL = size(IRL);
            iMx = find(imregionalmax(IRL) & BexcT);
            [yMx,xMx] = ind2sub(szL,iMx);
            
            % sorts the maxima in descending order
            [IMx,iS] = sort(IRL(iMx),'descend');
            
            % keeps the maxima values above threshold
            ii = IMx >= pTol*IMx(1);
            [pR,pMax] = deal(IMx(ii),[xMx(iS(ii)),yMx(iS(ii))]);
            iMax = iMx(iS(ii));    
            
            % 
            DP = pdist2(pMax,pMax); 
            DP(logical(eye(size(DP)))) = NaN;
            isC = DP < obj.dTol;
            
            % keep looping until all close points have been checked
            isOK = true(size(DP,1),1);
            while any(isC(:))
                % determines which the closest of the remaining points
                [iy,ix] = find(DP == min(DP(:)),1,'first');
                
                %
                pRR = calcRectifiedRatio(IRL(iMax(ix)),IRL(iMax(iy)));                
                if pRR < prTol
                    ixy = [ix,iy];
                    iMx = IRL(iMax(ixy));                    
                    isOK(ixy(argMin(iMx))) = false;
                end
                
                % removes the values from the search
                [isC(iy,ix),isC(ix,iy)] = deal(false);
                [DP(iy,ix),DP(ix,iy)] = deal(NaN);
            end
            
            % removes the infeasible points
            [pR,pMax,iMax] = deal(pR(isOK),pMax(isOK,:),iMax(isOK));
            
        end        
        
    end
    
    % static class methods
    methods (Static)
        
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
        
        % --- offsets the y-coordinates in fPos by yOfs
        function fPos = offsetYCoords(fPos,yOfs)
            
            if ~isempty(fPos)
                fPos = fPos + [0,yOfs];
            end
            
        end
        
        % --- calculates the linear indices of the coordinates, fPos
        function indP = calcLinearInd(szL,fPos)
            
            if isempty(fPos)
                indP = [];
            else
                indP = sub2ind(szL,fPos(:,2),fPos(:,1));
            end
            
        end
        
        % --- calculates the z-score for the point, iMx
        function Z = calcZScore(I,iMx)
            
            Z = (I(iMx) - mean(I(:)))/std(I(:));
            
        end
        
        % --- calculates the coordinates of the linear indices, ind
        function fP = calcCoords(I,ind)
            
            [yP,xP] = ind2sub(size(I),ind);
            fP = [xP,yP];
            
        end
        
        % --- retrieves the signal peaks from the image, I
        function iMx = getSigPeaks(I,Bexc,isDR)
            
            % parameters
            pTolN = 0.5 + 0.1*isDR; 

            % determines the peaks from the normalised image
            IN = normImg(I);            
            BN = (IN > pTolN) & Bexc;
            iMx = find(imregionalmax(I) & BN);
            
            % if there are none, then set the max value
            if isempty(iMx)
                return
            end
            
            % if the residual difference calculations, then remove all
            % peaks that are part of the same thresholded blob
            if isDR
%                 % calculates the z-scores
%                 ZMx = obj.calcZScore(I,iMx);                
%                 if max(ZMx) > ZMxTol
%                     iMx = iMx(ZMx >= ZMxTol);
%                 end
                
                % calculates the thresholded blob properties
                iGrpN = getGroupIndex(BN);
                [nMx,nGrpN] = deal(length(iMx),length(iGrpN));
                
                % if the peak/blob counts don't match, then reset the peak
                % indices so that the highest value (for each blob) is set
                if nMx ~= nGrpN
                    % sets the blob/peak index groupings
                    if nGrpN == 1
                        jMx = {iMx};
                    else
                        jMx = cellfun(@(x)(intersect(iMx,x)),iGrpN,'un',0);
                        jMx = jMx(~cellfun(@isempty,jMx));
                    end
                    
                    % sets the point for each blob with the highest value                    
                    iMx = cellfun(@(x)(x(argMax(IN(x)))),jMx);
                end
            end
            
        end                        
        
    end    
    
end