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
        isBatch
        
        % image array fields
        IL0
        IL
        IR
        IRs
        dIRs
        IXCs
        Bexc
        hC
        
        % statistics fields
        pStats
        
        % sub-region maxima 
        pR
        iMax
        pMax
        pMaxS
        pMaxM
        RMaxS
        sFlag
        mFlag  
        iRI
        iRM
        iCI
        
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
        pWS = 2.5;
        pTolBB = 0.1;    
        dTol0 = 7.5;
        ZTolR = 5;
        
        % other class fields
        hS
        hG
        nI
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
            obj.iMov.szObj = [];
            obj.hC = cell(length(obj.iMov.ok),1);            
            
            % sets up the disk filter masks
            obj.nI = getImageInterpRate();
            obj.hS = arrayfun(@(x)(fspecial('disk',x)),obj.xi,'un',0);
            
            % sets the distance tolerance
            obj.dTol = obj.calcDistTol();
            
        end
        
        % --- clears the class fields
        function clearClassFields(obj)
            
            % clears the image stack arrays
            obj.IR = [];
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
            [obj.IL0,obj.iPh,obj.iApp] = deal(IL,iPh,iApp);
            
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
            obj.setupSubRegionIndices();
            
            % initialisations
            obj.nFrm = length(obj.IL0);                        
            obj.okS = false(obj.nT,1);            
            obj.isAmbig = false(obj.nFrm,obj.nT);
            [obj.sFlag,obj.mFlag] = deal(NaN(obj.nT,1));
            [obj.RMaxS,obj.fPosAm] = deal(cell(obj.nT,1));
            [obj.pMax,obj.iMax] = deal(cell(obj.nFrm,obj.nT));
            [obj.pMaxS,obj.pR] = deal(cell(obj.nFrm,obj.nT));            
            obj.fPos = repmat({NaN(obj.nT,2)},obj.nFrm,1);
            obj.pStats = struct('Imu',[],'Isd',[]);         
            
            % downsamples the image stack
            obj.downsampleImageStack();                        
            
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
            obj.dIRs = cellfun(@(x)(max(0,...
                    imfiltersym(x-IRTmn,obj.hG))),obj.IRs,'un',0);
            
            % calculates the image stack statistics
            obj.calcImageStackStats(obj.dIRs);
%             [obj.pStats.Imu,obj.pStats.Isd]
            
        end                        
        
        % --- processes each of the sub-regions to determine the maxima
        function processSubRegions(obj)
                        
            % ---------------------------------- %
            % --- INITIAL LOCATION DETECTION --- %
            % ---------------------------------- %
            
            % parameters
            nFrmMin = 5;
            fok = obj.iMov.flyok(:,obj.iApp);
            isShortPhase = diff(obj.iMov.iPhase(obj.iPh,:)) < nFrmMin;
            
            % updates the progressbar
            wStr = 'Analysing Sub-Regions...';
            if obj.hProg.Update(obj.wOfsL+3,wStr,obj.pW0+obj.pW1)
                % exit if the user cancelled
                obj.calcOK = false;
                return
            end        
            
            % sets up the sub-region image stacks
            IRL = cellfun(@(y)(cellfun(@(x)(imfiltersym...
                    (x(y,:),obj.hG)),obj.IRs,'un',0)),obj.iRM,'un',0);
            
            % sets up the exclusion binary masks    
            szL = cellfun(@(x)(size(x{1})),IRL,'un',0);
            BexcT = cellfun(@(x)(~bwmorph(true(x),'remove')),szL,'un',0);            

            % determines the 
            if ~isShortPhase
                % sets up the sub-region residual difference image stacks
                % and calculates the maxima for each sub-image
                dIRL = cellfun(@(y)(cellfun(@(x)(x(y,:)),...
                        obj.dIRs,'un',0)),obj.iRM,'un',0);
                dIRLmx = cell2mat(cellfun(@(x)(cellfun...
                        (@(y)(max(y(:))),x)),dIRL,'un',0)');                 
                
                % sets the residual difference point values
                ZIRL = obj.calcPeakZScores(obj.pStats,dIRLmx);
            end
                
            % processes each sub-region within the current region
            for iT = find(fok(:)')
                % determines the sub-region flag
                if isShortPhase
                    % phase is very short in duration so check directly
                    [obj.mFlag(iT),sFlagT] = deal(2,0);
                    
                else
%                     if iT == 12
%                         a = 1;
%                     end
                    
                    % otherwise, use the residual based methods to
                    % determine the blob's locations
                    [sFlagT,uData] = obj.detSubRegionStatus...
                                (IRL{iT},dIRL{iT},ZIRL(:,iT),BexcT{iT});
                end                                
                
                switch sFlagT
                    case {1,2}
                        % case object location is fairly certain
                        
                        % sets the status/ambiguity flags
                        obj.okS(iT) = true;
                        obj.sFlag(iT) = 1;
                        obj.mFlag(iT) = 3 - sFlagT;
                        
                        % updates the positional values
                        obj.setPositionValues(uData,iT);                                                
                            
                    otherwise
                        % case is either 1 frame or ambiguous                                                                       

                        % segments the static locations
                        [obj.sFlag(iT),obj.mFlag(iT)] = deal(2,1);
                        obj.segStatFlyLocations(IRL{iT},BexcT{iT},iT);
                        
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
                obj.recalcFlyPos(iT);
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
        function [sFlagT,uData] = detSubRegionStatus(obj,IRL,dIRL,ZIRL,Bexc)
            
            % parameters
            pUniqMin = 2/3;                        
            
            % other initialisations
            [sFlagT,uData] = deal(0,[]);

            % ---------------------------------- %
            % --- INITIAL MOVEMENT DETECTION --- %
            % ---------------------------------- %
            
            % if all maxima z-scores are very low, then object is probably
            % stationary (analyse use the stationary blob tracking method)
            if all(ZIRL < obj.ZTolR)
                return
            end
            
            % calculates the number of significant residual peaks have been
            % determined for each sub-image
            jMx = cellfun(@(x)(obj.getSigPeaks(x,Bexc,1)),dIRL,'un',0);  
            njMx = cellfun(@length,jMx);
            
            % determines frames where there is a unique significant peak
            isU = njMx == 1;
            if all(isU)
                % if each frame is unambiguous, then flag the object has
                % moved over the video phase (and exits the function)
                fPMx = cellfun(@(x,y)...
                            (obj.calcCoords(x,y)),dIRL,jMx,'un',0);
                [sFlagT,uData] = deal(1,fPMx);
                return       
                          
            elseif (mean(isU) >= pUniqMin) && (mean(ZIRL(isU)) > obj.ZTolR)
                % if there are signifiant number of unique frames, and the
                % mean of the unique frames is high, then probably moving
                
                % calculates the combine residual images
                Q = cellfun(@(x,y)...
                        (max(0,x).*max(0,y)),dIRL(~isU),IRL(~isU),'un',0);
                jMx(~isU) = cellfun(@(x)...
                        (obj.detAmbigFlyPos(x,Bexc)),Q,'un',0);

                % calculates the peak coordintes and returns a moving flag
                fPMx = cellfun(@(x,y)(obj.calcCoords(x,y)),IRL,jMx,'un',0);
                [sFlagT,uData] = deal(1,fPMx);
                return                            
                
            elseif any(njMx == 0)
                % if there are any frames with no peaks, then exit
                return
            end
                          
            % --------------------------------- %
            % --- STATIONARY BLOB DETECTION --- %
            % --------------------------------- %              
            
            % calculates the peaks that are closest to the residual
            % difference maxima (from the residual image)
            kMx = cellfun(@(x,y)...
                        (obj.calcClosestMax(x,Bexc,y)),IRL,jMx,'un',0);
            dfPMx = cellfun(@(x,y)(obj.calcCoords(x,y)),IRL,kMx,'un',0);                        
            
            % determine if there are any static groupings amoungst the
            % residual images
            indDG = obj.findStaticPeakGroups(dfPMx,IRL,kMx);
            if ~isempty(indDG)
                % if there is more than one static grouping, then use the
                % group with the higher residual
                if length(indDG) > 1
                    QG = cellfun(@(x)(mean(cellfun(@(y,z,i)...
                                (y(z(i))),IRL,kMx,num2cell(x)))),indDG);
                    indDG = indDG(argMax(QG));
                end                
                
                % sets the final output data values
                idfPMx = num2cell(indDG{1});
                pMx = cellfun(@(x,y)(x(y,:)),dfPMx,idfPMx,'un',0);
                [sFlagT,uData] = deal(2,pMx);
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
            if any(nP == 0)
                % case is the sub-region is potentially empty?
                pMaxT = repmat({NaN(1,2)},obj.nFrm,1);
                obj.setPositionValues(pMaxT,iT);
                
                % exits the function
                return
                
            elseif all(nP == 1)
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
        %     convolution in the function @recalcFlyPos)
        function [fP,ok] = detLikelyFlyPos(obj,pMaxM0,RMaxM,iT)
            
            % memory allocation
            ok = true;
            pMaxS0 = cell(size(pMaxM0));            
            fP = repmat({NaN(1,2)},obj.nFrm,1);
            isS = cellfun(@(x)(false(size(x,1),1)),pMaxM0,'un',0);                        
            
            % ---------------------------------- %
            % --- STATIONARY POINT DETECTION --- %
            % ---------------------------------- %            
            
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
            rTolS = 2.50;            
            
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
        function recalcFlyPos(obj,iT)
            
            % parameters
            pQZtol = 0.5;
            
            % field retrieval
            mStr = 'omitnan';
            iRT = obj.iRM{iT};
            
            %
            hCT = obj.downsampleImage(obj.hC{obj.iApp});
            IRL = cellfun(@(x)(imfiltersym(x(iRT,:),obj.hG)),obj.IRs,'un',0);
            IXC = cellfun(@(x)(calcXCorr(hCT,x)),IRL,'un',0);

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
                            (obj.upsampleCoords(x(~isC,:))),fPosAm0,'un',0);
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

            % sets the sub-region size
            N = ceil(obj.dTol);
            if obj.nI > 0
                N = (1+obj.nI)*N + 1;         
            end
                
            % sets the known fly location coordinates/linear indices
            yOfsT = cell2mat(obj.yOfs(obj.okS));
            pOfsT = [zeros(sum(obj.okS),1),yOfsT(:)];            
            fPosT = cellfun(@(x)(x(obj.okS,:)+pOfsT),obj.fPos,'un',0);
                       
            % calculates the residual image stacks
            IR0 = cellfun(@(y)(cellfun(@(h)(...
                    (imfiltersym(y,h)-y)),obj.hS,'un',0)),obj.IL0,'un',0);
            IR0s = cellfun(@(x)(calcImageStackFcn(x,'mean')),IR0,'un',0);
                        
            % keep looping until the filtered binary mask no-longer touches
            % the edge of the sub-region frame
            while 1
                % retrieves the fly sub-image stack (for all known points)
                Isub = cell(obj.nFrm,sum(obj.okS));
                for i = 1:obj.nFrm
                    Isub(i,:) = cellfun(@(x)(obj.getPointSubImage...
                           (IR0s{i},x,N)),num2cell(fPosT{i},2),'un',0)';
%                     Isub(i,:) = cellfun(@(x)(obj.getPointSubImage...
%                            (obj.IRs{i},x,N)),num2cell(fPosT{i},2),'un',0)';
                end
                
                % calculates the 
                Bsub = cellfun(@(x)(detLargestBinary(-x)),Isub,'un',0);

                % calculates the sub-image stack mean image
                Q = cellfun(@(x,y)(x.*y),Isub,Bsub,'un',0);
                IsubMn = calcImageStackFcn(Q(:),'mean');
                
                % sets up the binary mask
                nH = (size(IsubMn,1)-1)/2;
                B0 = setGroup((nH+1)*[1,1],(2*nH+1)*[1,1]);
                
                % sets up template image
                hC0 = max(0,IsubMn - mean(IsubMn(:)));
                [~,B] = detGroupOverlap(hC0>0,B0);
                obj.hC{obj.iApp} = hC0.*B;            

                % thresholds the filtered sub-image
                Brmv = B & (normImg(obj.hC{obj.iApp}) > obj.pTolBB);   
                if all(Brmv(bwmorph(true(size(Brmv)),'remove')))
                    N = N + (1+obj.nI);
                    obj.dTol = obj.dTol + 1;                    
                else
                    break
                end
            end
            
            if ~isfield(obj.iMov,'szObj') || isempty(obj.iMov.szObj)
                % calculates the binary mask of the gaussian
                BrmvD = sum(Brmv(logical(eye(size(Brmv)))));                                
                obj.iMov.szObj = BrmvD*[1,1];
                obj.dTol = obj.calcDistTol();                
            end
            
        end

        % ------------------------------------- %
        % --- IMAGE INTERPOLATION FUNCTIONS --- %
        % ------------------------------------- % 
        
        % --- sets the sub-region row/column indices
        function setupSubRegionIndices(obj)
        
            % sets the row/column indices
            nCol = size(obj.IL0{1},2);
            [iRT,iCT] = deal(obj.iMov.iRT{obj.iApp},1:nCol);            
            
            % interpolates the images (if large)
            if obj.nI > 0
                iCT = (obj.nI+1):(2*obj.nI):nCol;
                iRT = cellfun(@(x)(x((obj.nI+1):2*obj.nI:end)),iRT,'un',0);
            end            
            
            % converts to a single array (if required)
            [obj.iRI,obj.iCI] = deal(iRT,iCT);
            
            % sets up the region mapping indices
            N = cellfun(@length,iRT);
            iOfs = [0;cumsum(N(1:end-1))];
            obj.iRM = arrayfun(@(n,i)(i+(1:n)'),N,iOfs,'un',0);
            
        end
        
        function I = downsampleImage(obj,I)
            
            % interpolates the images (if large)
            if obj.nI > 0
                iR = (obj.nI+1):(2*obj.nI):size(I,1);
                iC = (obj.nI+1):(2*obj.nI):size(I,2);
                I = I(iR,iC);
            end              
            
        end
        
        % --- upsamples the coordinates to the full frame reference
        function fPos = upsampleCoords(obj,fPos)
            
            if obj.nI > 0
                fPos = 1 + obj.nI*(1 + 2*(fPos-1));
            end
            
        end

        % --- downsamples the image coordinates
        function fP = downsampleCoords(obj,fP)
            
            if obj.nI > 0
                fP = roundP(((fP-1)/obj.nI - 1)/2 + 1);
            end
                
        end          
        
        % --- downsamples the image stack 
        function downsampleImageStack(obj)
            
            if obj.nI == 0
                obj.IL = obj.IL0;
            else
                iRT = cell2mat(obj.iRI(:)');
                obj.IL = cellfun(@(x,y)(x(iRT,obj.iCI)),obj.IL0,'un',0);
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
            obj.hFigP = plotGraph('image',obj.IL0{1});
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
            set(findall(obj.hAxP,'Type','Image'),'CData',obj.IL0{obj.iFrmP})
            
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
            pPosT = cell2mat(cellfun(@(x,y)(obj.offsetYCoords...
                        (obj.upsampleCoords(x),y)),pMax0,yOfsT,'un',0));
            
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
        function setPositionValues(obj,fPosNw,iT)
            
            % stores the positional values
            for iFrm = 1:obj.nFrm
                obj.fPos{iFrm}(iT,:) = obj.upsampleCoords(fPosNw{iFrm});                
            end
            
        end                
        
        % --- determines the static object grouping properties (if any)
        function varargout = findStaticPeakGroups(obj,fP,varargin)
            
            % parameters
            pWM = 2;
            pRRTol = 2.25;            
            pBPRRTol = 0.8;
            
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
                    Qm = DP.*pRR;
                    [BDR,BPRR] = deal(DP < pWM*obj.dTol,pRR < pRRTol);  
                    
                elseif exist('RMx','var')
                    % case is the peak values are provided
                    pRR = combineNumericCells(cellfun(@(x)...
                            (calcRectifiedRatio(RMx{1}(i),x)),RMx,'un',0));
                    Qm = DP.*pRR;
                    [BDR,BPRR] = deal(DP < obj.pWS*obj.dTol,pRR < pRRTol);
                    
                else
                    % case is a distance only check
                    Qm = DP;
                    [BDR,BPRR] = deal(DP < obj.pWS*obj.dTol,true(size(Qm)));                    
                end
                        
                % determines points that meet the distance/RR tolerances
                Bm = BDR & BPRR;
                if all(any(BDR,1))
                    iRR = any(Bm,1);
                    pRR = mean(iRR);                    
                    hasS(i) = pRR >= pBPRRTol;  
                    
                    % resets any missing points
                    if pRR < 1
                        hasS(i) = (pRR > 0.5) && (sum(~iRR) == 1);
                        Bm(:,~iRR) = BDR(:,~iRR);
                    else
                        hasS(i) = true;
                    end
                end
                
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
            
            % reduces down the data arrays to the feasible groups
            [indG,fPS,iPS] = deal(indG(hasS),fPS(hasS),iPS(hasS));            
            if length(indG) > 1
                % sets up the index testing
                D = cell2mat(cellfun(@(x)(cellfun(@(y)...
                                (min(abs(x-y))),indG)),indG,'un',0)');
                D(logical(eye(size(D)))) = NaN;
                
                if any(D(:) == 0)
                    % calculates the mean residual maxima values
                    if exist('RMx','var')
                        % case is peak maxima values are provided                           
                        QG = cellfun(@(x)(mean(cellfun...
                                (@(y,z)(y(z)),RMx,num2cell(x)))),indG);
                            
                    elseif exist('IRL','var')
                        % case is image/peak location value are provided
                        QG = cellfun(@(x)(mean(cellfun(@(y,z,i)...
                                (y(z(i))),IRL,iMx,num2cell(x)))),indG);
                            
                    else
                        % case is only distance values are provided
                        DR = cellfun(@(x)(prod(range(cell2mat(cellfun...
                                    (@(y,i)(y(i,:)),fP,num2cell(x),...
                                    'un',0)),1))),indG);
                        QG = 1./(1+DR);
                    end
    
                    % sets the initial feasibility flags
                    isOK = QG(:) > 0;  

                    % keep looping until there is no overlap
                    while 1
                        [iy,ix] = find(D == 0,1,'first');
                        if isempty(iy)
                            % if there is no overlap, then exit the loop
                            break
                        else
                            % determines which group has the higher score
                            ixy = [ix,iy];
                            imn = argMin(QG(ixy));                        

                            % removes the group with the lower score value
                            isOK(ixy(imn)) = false;
                            [D(ix,iy),D(iy,ix)] = deal(NaN);
                            [D(ixy(imn),:),D(:,ixy(imn))] = deal(NaN);
                        end
                    end

                    % reduces down the data arrays
                    [indG,fPS,iPS] = deal(indG(isOK),fPS(isOK),iPS(isOK));                    
                end                            
            end
            
            % returns the final static groupings
            if nargout == 1
                varargout = {indG};            
            else
                varargout = {fPS,iPS};
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
            ndTol = 5;
            pTolR = 0.8;
                        
            % initialisations
            BP = IRL > 0;
            BmxT = false(size(IRL));
            
            % determines the regional maxima from the sub-image
            iMx = find(imregionalmax(IRL) & BP & BexcT);
            if isempty(iMx)
                % if there are no maxima then exit with empty values
                [pR,pMax,iMax] = deal([]);
                return
            end   
            
            % sorts the 
            [IRLmx,iS] = sort(IRL(iMx),'descend');
            Bmx = arrayfun(@(x)(IRL > pTolR*x),IRLmx,'un',0);            
            
            %
            iGrp = cell(length(iS),1);
            for i = 1:length(iS)
                % 
                [~,BmxI] = detGroupOverlap(Bmx{i},BmxT);
                [Bmx{i}(BmxI),BmxT(BmxI)] = deal(false,true);
                
                %
                if Bmx{i}(iMx(iS(i)))
                    [~,BmxR] = detGroupOverlap(Bmx{i},iMx(iS(i)));
                    [iGrp0,pBB] = getGroupIndex(BmxR,'BoundingBox');
                    
                    % if the blob isn't too large, then store the 
                    if all(pBB(:,3:4) <= ndTol*obj.dTol,2)
                        iGrp(i) = iGrp0;
                        BmxT(BmxR) = true;
                    end
                end
            end
            
            % determines the feasible groups
            hasGrp = ~cellfun(@isempty,iGrp);
            if ~any(hasGrp); hasGrp(1) = true; end
            
            % sets the final values
            iMax = iMx(iS(hasGrp));
            [pR,pMax] = deal(IRL(iMax),obj.calcCoords(IRL,iMax));            
            
        end      
        
        % --- calculates
        function kMx = calcClosestMax(obj,I,B,jMx0)

            % initialisations
            sz = size(I);
            kMx = NaN(length(jMx0),1);
            [yP0,xP0] = ind2sub(sz,jMx0);
            
            % determines the regional maxima from the image
            kMx0 = find(imregionalmax(I) & B);
            [yPF,xPF] = ind2sub(sz,kMx0);
            
            %
            for i = 1:length(jMx0)
                D = max(1,pdist2([xPF,yPF],[xP0(i),yP0(i)])/obj.dTol);
                kMx(i) = kMx0(argMax(I(kMx0)./D));
            end

        end                
        
        % --- calculates the image stack statistics
        function P = calcImageStackStats(obj,I)
            
            % calculates the frame stack mean/std dev values
            B = cellfun(@(x)(x>0),I,'un',0);
%             B = cellfun(@(x)(trie),I,'un',0);
            
            if nargout == 1
                P = struct('Imu',[],'Isd',[]);
                P.Imu = cellfun(@(x,y)(mean(x(y))),I,B);
                P.Isd = cellfun(@(x,y)(std(x(y))),I,B);
            else
                obj.pStats.Imu = cellfun(@(x,y)(mean(x(y))),I,B);
                obj.pStats.Isd = cellfun(@(x,y)(std(x(y))),I,B);
            end
                        
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
        function Z = calcZScore(I,iMx,varargin)
            
            if nargin == 2
                Z = (I(iMx) - mean(I(:)))/std(I(:));
            else
                Z = (iMx - mean(I(:)))/std(I(:));                
            end
            
        end
        
        % --- calculates the coordinates of the linear indices, ind
        function fP = calcCoords(I,ind)
            
            [yP,xP] = ind2sub(size(I),ind);
            fP = [xP(:),yP(:)];
            
        end
        
        % --- retrieves the signal peaks from the image, I
        function iMx = getSigPeaks(I,Bexc,isDR)
            
            % parameters
            pTolN = 0.5; 

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
        
        % --- determines the location of an ambiguous moving fly 
        function iMx = detAmbigFlyPos(I,B)
            
            % parameters
            pTolR = 0.75;
            pTolMx = 0.75;            
            
            % determines the regional maxima
            iMx0 = find(imregionalmax(I) & B);
            [IMx,iS] = sort(I(iMx0),'descend');            
            iMx = iMx0(iS(IMx/IMx(1) > pTolMx));
            
            % if there is more than one maxima, then use size/pixel
            % intensity values to determine the most likely location
            if length(iMx) > 1
                % calculates the size of the blobs (when thresholded as a
                % proportion of their maxima value)
                A = zeros(length(iMx),1);                
                for i = 1:length(iMx)
                    [~,B] = detGroupOverlap(I>pTolR*IMx(i),iMx(i));
                    A(i) = sum(B(:));
                end
                
                % returns the largest/brightest blob 
                iMx = iMx(argMax(IMx(1:length(A)).*A));
            end
            
        end        
        
        % --- calculates the z-scores for the maxima, Imx from the image, I
        function Zmx = calcPeakZScores(pI,Imx)

            % calculates the z-scores of the sub-image maxima
            Zmx = (Imx - pI.Imu)./pI.Isd;

        end        
        
    end    
    
end
