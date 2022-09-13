classdef SingleTrackInit < SingleTrack
    
    % class properties
    properties
        
        % main fields
        infoObj
        frObj
        
        % image array fields
        Img
        Img0
        Ibg
        Ibg0
        IbgT
        IbgT0
        Iss
        dIss        
        
        % 
        fPos
        fPos0
        fPosL
        fPosG
        fPosAm  
        fPosP
        yPosP
        mFlag
        sFlag
        sFlagT
        sFlagMax        
        
        % other important fields
        nI
        i0
        pQ0
        iOK
        tPara
        pStats
        pData       
        useP
        isStat
        indFrm
        useFilt
        dpOfs
        dpInfo
        errStr
        errMsg
        hFilt                
        Isd
        Imu
        iniP
        pTolF
        okFrm
        prData0 = []; 
        bSzT
        
        % plotting fields
        hAxP
        hFigP
        hMarkA
        hMarkF
        hMarkAm
        iFrmP
        iAppP
        iPhP
        nFrmP
        hTitleP
        showAm
        
        % other parameters and scalar fields
        isHiV
        usePTol 
        pTolQ = 5;
        pTolMin = 5;
        pSigMin = 0.5;
        nOpenRng = 15;
        nFrmMin = 10;
        dyRngMin = 10;
        pTolSz = 0.05;
        mdDim = 30*[1,1];         
        hSR = fspecial('disk',2);           
        
    end
    
    % class methods
    methods
        % class constructor
        function obj = SingleTrackInit(iData)
            
            % creates the super-class object
            obj@SingleTrack(iData);
   
        end
        
        % ------------------------------------- %
        % --- BLOB DETECTION MAIN FUNCTIONS --- %
        % ------------------------------------- %        
        
        % --- calculates the initial fly location/background estimates
        function calcInitEstimate(obj,iMov,hProg)
            
            % sets the input arguments
            obj.iMov = iMov;
            obj.hProg = hProg;             
            
            % runs the pre-estimate setup
            obj.preEstimateSetup();
            if ~obj.calcOK
                % if the user cancelled then exit
                return
            end                               
            
            % runs the initial detection estimate
            obj.runInitialDetection(); 
            if ~obj.calcOK
                % if the user cancelled, then exit
                return
            end
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % sets the background images into the sub-region data struct 
            obj.iMov.Ibg = obj.Ibg;                                                       
            obj.iMov.pTolF = obj.pTolF;
            okPh = obj.iMov.vPhase < 3;
            
%             % calculates the overall quality of the flies (prompting the
%             % user to exclude any empty/anomalous regions)
%             if ~obj.isBatch && any(okPh)
%                 obj.calcOverallQuality()
%             end
            
            % sets the status flags for each phase (full and overall)
            sFlag0 = cellfun(@(x)(3-x),obj.sFlag,'un',0);
            obj.iMov.StatusF = sFlag0;
            
            % calculates the distance each blob travels over the video
            fPT = num2cell(cell2cell(obj.fPosL(okPh)',0),2);
            fPmn = cellfun(@(x)(calcImageStackFcn(x,'min')),fPT,'un',0);
            fPmx = cellfun(@(x)(calcImageStackFcn(x,'max')),fPT,'un',0);
            DfPC = cellfun(@(x,y)(sum((y-x).^2,2).^0.5),fPmn,fPmx,'un',0);
            
            % sets up the distance array.
            DfP = NaN(max(cellfun(@length,DfPC)),length(obj.iMov.ok));
            DfP(:,obj.iMov.ok) = combineNumericCells(DfPC(obj.iMov.ok)');
            
            % determines which regions are potentially empty 
            ii = ~cellfun(@isempty,obj.iMov.StatusF);
            if any(ii)
                % sets the status flag array. any blobs which have been
                % flagged as non-moving, but actually has moved appreciably
                % over the video, is reset to moving
                Status = calcImageStackFcn(obj.iMov.StatusF(ii),'min');
                Status((Status==2) & (DfP > obj.iMov.szObj(1))) = 1;

                % updates the other status flag 
                noFly = Status==3;
                if obj.isBatch                
                    Status(noFly & obj.iMov.flyok) = 2;
                    Status(noFly & ~obj.iMov.flyok) = 3;
                else
                    Status(noFly) = 3;  
                end

                % resets the status flags for the video
                obj.iMov.Status = num2cell(Status,1);   
            else
                obj.iMov.Status = arrayfun(@(x)...
                            (zeros(x,1)),getSRCountVec(obj.iMov)','un',0);                
            end
            
            % updates the progress bar
            obj.hProg.Update(1+obj.wOfsL,'Initial Estimate Complete!',1);                                                
            
        end          
        
        % --- runs the pre-estimate initialisations
        function preEstimateSetup(obj)
            
            % global variables
            global isCalib
            
            % sets the input variables
            obj.isCalib = isCalib;
            obj.nI = floor(max(getCurrentImageDim())/800);
            obj.frObj = FilterResObj(obj.iMov,obj.hProg,obj.wOfsL);
            
            % retrieves the device information struct (if calibrating)
            if obj.isCalib
                hFig = findall(0,'tag','figFlyTrack');
                obj.infoObj = get(hFig,'infoObj');
            end
                        
            % initialises the tracking objects
            obj.initTrackingObjects('InitEstimate');
            obj.getTrackingImages(); 
            if ~obj.calcOK
                % if the user cancelled then exit
                return
            end                     
            
            % initialises the other detection fields
            obj.initDetectFields();
            if ~obj.calcOK
                % if the user cancelled then exit
                return
            end                    
            
        end        
        
        % ----------------------------------------- %
        % --- INITIAL OBJECT ESTIMATE FUNCTIONS --- %
        % ----------------------------------------- %
        
        % --- initialises the class fields before detection
        function initDetectFields(obj)
            
            % if the user has cancelled, then exit
            if ~obj.calcOK; return; end
            
            % array dimensioning
            nPh = length(obj.Img);
            nT = getSRCountVec(obj.iMov);
            nApp = numel(nT);
            
            % field re-initialisation
            if isfield(obj.iMov,'hFilt')
                obj.hFilt = obj.iMov.hFilt;  
            else
                obj.hFilt = [];   
            end
            
            % phase dependent object memory allocation
            A = cell(nPh,1);           
            [obj.Ibg,obj.Ibg0] = deal(A);
            [obj.IbgT,obj.IbgT0] = deal(A);
            [obj.sFlag,obj.tPara,obj.pQ0] = deal(A);
            [obj.isStat,obj.fPosG] = deal(A);
            [obj.errStr,obj.errMsg] = deal([]);            
            
            % region dependent object memory allocation
            [obj.fPosP,obj.mFlag,obj.sFlagT] = deal(cell(nPh,nApp));
            [obj.Iss,obj.dIss] = deal(cell(length(nT),nPh));
            [obj.Imu,obj.Isd,obj.pTolF] = deal(NaN(nApp,nPh));            
            
            % ambiguous position memory allocation
            nR = arr2vec(getSRCount(obj.iMov)');
            obj.fPosAm = repmat(arrayfun(@(n)...
                            (cell(n,1)),nR','un',0),obj.nPhase,1);
            
            % other memory allocation
            fP0 = cellfun(@(x)(repmat(arrayfun(@(n)(NaN(n,2)),...
                              nT(:),'un',0),1,length(x))),obj.Img,'un',0);
                          
            % retrieves the positional array (based on estimation type)
            if obj.isAutoDetect
                % case is the 1D grid automatic detection
                [obj.fPos0,obj.fPos] = deal(fP0);                 
                
            else
                % case is the initial detection
                obj.fPosL = fP0;
                
                % resets the homomorphic image filters (if required)
                obj.iMov.phInfo.hmFilt = cellfun(@(ir,ic)...
                            (setupHMFilter(ir,ic)),obj.iMov.iR,...
                            obj.iMov.iC,'un',0);
            end                               
                              
            % calculates the point statistics data struct
            obj.pStats = struct('IR',[],'IRmd',[]);            
            B = cell2cell(cellfun(@(x)(arrayfun(@(n)...
                    (NaN(n,length(x))),nT(:),'un',0)),obj.Img,'un',0),0);
            [obj.pStats.IR,obj.pStats.IRmd] = deal(B);
            
            % retrieves the initial detection parameters
            obj.iniP = getTrackingPara(obj.iMov.bgP,'pInit');
            
        end
        
        % --- sets up the tracking image stack/index array
        function getTrackingImages(obj)
                        
            % retrieves the use filter flag            
            bgP = getTrackingPara(obj.iMov.bgP,'pSingle');
            if isfield(bgP,'useFilt')
                obj.useFilt = bgP.useFilt;
            else
                obj.useFilt = false;
            end            
            
            % retrieves the frame index/image arrays
            if obj.isCalib
                % returns the previously read image stack
                if isempty(obj.Img0)
                    wStr0 = obj.hProg.wStr;
                    obj.hProg.wStr(2:3) = ...
                           {'Reading Image Frames','Current Frame Wait'};
                    
                    obj.Img = {obj.getCameraImgStack()};
                    obj.hProg.wStr = wStr0;
                else
                    obj.Img = obj.Img0;
                end
                   
                % sets the frame indices
                obj.indFrm = {1:length(obj.Img{1})};
                
                % applies the smooth filter (if specified)
                if obj.useFilt
                    obj.Img{1} = cellfun(@(x)(imfiltersym...
                                            (x,obj.hS)),obj.Img{1},'un',0);
                end                
                
            else
                % sets the phase frame indices
                nPh = obj.nPhase;
                obj.indFrm = getPhaseFrameIndices(obj.iMov,obj.nFrmR);                
                
                % memory allocation
                wStr0 = 'Initial Frame Stack Read';
                [obj.Img,obj.iOK] = deal(cell(nPh,1));
                obj.hProg.Update(1+obj.wOfsL,wStr0,1/(3+nPh));

                % reads the initial images                            
                for i = 1:nPh
                    % updates the progressbar 
                    wStr = sprintf(...
                        'Reading Phase Images (Phase %i of %i)',i,nPh);
                    if obj.hProg.Update(2+obj.wOfsL,wStr,i/(1+nPh))
                        % if the user cancelled, then exit the function
                        obj.calcOK = false;
                        return
                    end

                    % reads the image stack for phase frame indices
                    [obj.Img{i},obj.iOK{i}] = ...
                                    obj.getImageStack(obj.indFrm{i});

                    % applies the smooth filter (if specified)
                    if obj.useFilt
                        obj.Img{i} = cellfun(@(x)(imfiltersym...
                                    (x,obj.hS)),obj.Img{i},'un',0);
                    end
                end
            end
            
            % updates the progress-bar
            obj.hProg.Update(3+obj.wOfsL,'Frame Read Complete',1);
            
        end                 
        
        % --- retrieves the image stack from the camera snapshots
        function ImgS = getCameraImgStack(obj)
            
            % initialisations
            fPara = struct('Nframe',10,'wP',0.5);
            objIMAQ = obj.infoObj.objIMAQ;
            
            % reads the snapshots from the camera (stopping after)
            ImgS = getCameraSnapshots...
                            (obj.iMov,obj.iData,objIMAQ,fPara,obj.hProg);            
            
            
        end
       
        % -------------------------------------------- %
        % --- INITIAL RESIDUAL DETECTION FUNCTIONS --- %
        % -------------------------------------------- %   
        
        % --- runs the initial detection on the image stack, Img
        function runInitialDetection(obj)
        
            % sorts the phases by type (low var phases first)
            nPh = obj.nPhase;
            indPh = [obj.iMov.vPhase,diff(obj.iMov.iPhase,[],2)];
            [~,iSort] = sortrows(indPh,[1,2],{'ascend' 'descend'});
            
            % -------------------------------- %
            % --- INITIAL OBJECT DETECTION --- %
            % -------------------------------- %        
            
            % memory allocation
            IL = cell(obj.nPhase,1);
            okPh = obj.iMov.vPhase < 3;
            
            % segments the phases (from low to high variance phases)
            for j = 1:obj.nPhase
                % updates the progress-bar
                i = iSort(j);
                wStrNw = sprintf('Moving Object Detection (Phase #%i)',i);                
                
                % updates the progress bar
                pW0 = (j+1)/(3+obj.nPhase);
                if obj.hProg.Update(1+obj.wOfsL,wStrNw,pW0)
                    obj.calcOK = false;
                    return
                else
                    % resets the secondary field
                    wStrNw1 = 'Initialising Phase Analysis...';
                    obj.hProg.Update(2+obj.wOfsL,wStrNw1,0);
                    
                    % resets the tertiary field
                    wStrNw2 = 'Initialising Region Analysis...';
                    obj.hProg.Update(3+obj.wOfsL,wStrNw2,0);
                end
                
                % analyses the phase
                if okPh(i)
                    isHV = obj.iMov.vPhase(i) == 2;
                    IL{i} = obj.analysePhase(obj.Img{i},i,isHV);

                    % determines if there was an error in the calculations
                    if ~isempty(obj.errStr)
                        % if so, then set up the error string for output
                        eStr = sprintf(['There was an error with the ',...
                                        'following detection phase:\n\n']);
                        eStr = sprintf('%s %s %s',eStr,char(8594),obj.errStr);
                        eStr = sprintf(['%s\n\nTry again with a different ',...
                                      'configuration or parameter set.'],eStr);
                        waitfor(msgbox(eStr,'Detection Error','modal'))

                        % if there was an error, then exit
                        obj.hProg.closeProgBar();
                        return                    
                    end
                end
            end  
            
            % matches up the blob locations between phases
            obj.interPhasePosMatch();

            % ----------------------------------- %
            % --- BACKGROUND IMAGE ESTIMATION --- %
            % ----------------------------------- %

            % updates the progressbar
            wStrNw = 'Background Image Estimation';
            obj.hProg.Update(1+obj.wOfsL,wStrNw,(2+nPh)/(3+nPh));            

            % memory allocation
            szL = cellfun(@size,IL{1}(1,:),'un',0);
            A = cellfun(@(x)(NaN(x)),szL,'un',0);
            obj.Ibg = repmat({A},obj.nPhase,1);            
            
            % calculates the estimated blob size
            obj.bSzT = obj.calcBlobSize();
            nFrmPh = diff(obj.iMov.iPhase,[],2) + 1;
            obj.iMov.szObj = obj.bSzT*[1,1];
            
            % calculates background image estimates (for feasible phases)
            okPh = obj.iMov.vPhase < 3;
            for iPh = find(okPh(:)')
                % updates the progressbar
                wStrNw = sprintf('Analysing Phase (%i of %i)',iPh,nPh);
                if obj.hProg.Update(2+obj.wOfsL,wStrNw,iPh/(1+nPh))
                    obj.calcOK = false;
                    return                    
                end                

                % calculates the background image estimate        
                if nFrmPh(iPh) > 1 
                    obj.calcImageBGEst(IL{iPh},iPh);
                    obj.recalcFlyPos(IL{iPh},iPh);
                    
                    % if the user cancelled, then exit
                    if ~obj.calcOK; return; end
                end
                
                % sets the sub-region status flags
                obj.detSubRegionStatusFlags(iPh);
                
                % calculates the global coordinates
                obj.calcGlobalCoords(iPh);                
            end
            
            % determines the overall minimum sub-region flags
            obj.setupOverallStatusFlags();            
            
            % ----------------------------------- %
            % --- STATIONARY OBJECT DETECTION --- %
            % ----------------------------------- %

%             % updates the progressbar
%             wStrNw = 'Static Object Detection';
%             obj.hProg.Update(1+obj.wOfsL,wStrNw,(2+nPh)/(3+nPh));                
% 
%             % segments the low/high variance phases
%             for i = find(okPh(:)')
%                 % updates the progressbar
%                 wStrNw = sprintf('Analysing Phase (%i of %i)',i,nPh);
%                 if obj.hProg.Update(2+obj.wOfsL,wStrNw,i/(1+nPh))
%                     obj.calcOK = false;
%                     return                    
%                 end
%
%                 % determines if any sub-regions within this phase that 
%                 % are stationary, but are moving over the whole video
%                 obj.analyseStationaryBlobs(IL{i},i);
%
%                 % performs the phase house-keeping exercises
%                 obj.phaseHouseKeeping(i);                
%
%                 % calculates the global coordinates
%                 obj.calcGlobalCoords(i);           
% 
%             end                

            % ----------------------------------- %
            % --- UNTRACKABLE PHASE DETECTION --- %
            % ----------------------------------- %

            % interpolates the locations for untrackable phases
            for i = find(obj.iMov.vPhase(:)' == 3)
                % analyses the phase
                obj.analyseUntrackablePhase(i);

                % calculates the global coordinates
                obj.calcGlobalCoords(i);                      
            end                  

            % updates the progressbar
            wStrF = 'Initial Detection Complete!';
            obj.hProg.Update(1+obj.wOfsL,wStrF,1);            
            
            % ---------------------------------------- %
            % --- STATIONARY BLOB DIAGNOSTIC CHECK --- %
            % ---------------------------------------- %
            
%             % if there is more than one phase, then determine if the 
%             % stationary blob locations are consistent over all phases
%             if obj.nPhase > 1
%                 obj.checkStationaryBlobs();
%             end                         
            
        end        
        
        % --- analyses a low variance video phase
        function IL = analysePhase(obj,Img,iPh,isHiV)
                            
            % initialisations
            obj.isHiV = isHiV;
            hasF = obj.getFlucFlag();
            obj.usePTol = 0.2*(1+0.75*(hasF || obj.isHiV));            
            
            % memory allocation            
            iFrm = obj.indFrm{iPh};
            IL = cell(length(iFrm),obj.nApp);                        
            
            % sets up the raw/residual image stacks            
            for i = find(obj.iMov.ok(:)')
                % update the waitbar figure
                wStr = sprintf('Analysing Region (%i of %i)',i,obj.nApp);
                if obj.hProg.Update(2+obj.wOfsL,wStr,i/obj.nApp)
                    % if the user cancelled, then exit
                    obj.calcOK = false;
                    return
                end          
                
                if isequal([iPh,i],[1,2])
                    iT = 1;
                end
                
                % retrieves and processes the image stack
                IL(:,i) = obj.getRegionImageStack(Img,iFrm,i,isHiV);                
                obj.frObj.processImgStack(IL(:,i),iPh,i);
                
                % if successful, then retrieve the final information
                if obj.frObj.calcOK
                    obj.setStackProcessInfo(iPh,i);
                end
            end                
                        
        end         
        
        % --- sets the data from the filtered image analysis object 
        function setStackProcessInfo(obj,iPh,iApp)
            
            % retrieves the status flags
            obj.sFlagT{iPh,iApp} = obj.frObj.sFlag;
            obj.mFlag{iPh,iApp} = obj.frObj.mFlag;
            
            % retrieves the known and ambiguous marker locations
            obj.fPosL{iPh}(iApp,:) = obj.frObj.fPos;           
                        
            % stores the values into the arrays
            obj.fPosP{iPh,iApp} = obj.frObj.pMaxS;
            obj.yPosP{iPh,iApp} = obj.frObj.RMaxS;
            
        end        

        % -------------------------------- %
        % --- STATUS FLAG CALCULATIONS --- %
        % -------------------------------- %         
        
        % --- determines the status flags for each sub-region/phase
        function detSubRegionStatusFlags(obj,iPh)
        
            % parameters
            pS = 1.5;

            % memory allocation
            okF = obj.iMov.ok;
            
            % retrieves the movement flags (for each sub-region) and
            % determines which have some sort of movement
            Zflag = NaN(max(cellfun(@length,obj.mFlag(iPh,:))),obj.nApp);            
            Zflag(:,okF) = combineNumericCells(obj.mFlag(iPh,okF)');            

            % ----------------------------------- %
            % --- DISTANCE RANGE CALCULATIONS --- %
            % ----------------------------------- %            

            % retrieves the residual scores
            pPR = obj.pStats.IR(:,iPh);            
            
            % determines if a majority of the residual pixel intensities
            % meets the tolerance (for each sub-region) across all frames
            okR = obj.iMov.ok;
            pSig = combineNumericCells(cellfun(@(x,y)(mean(x>y,2)),...
                        pPR(okR),num2cell(obj.pTolF(okR,iPh)),'un',0)');
            pvSig = combineNumericCells(cellfun(@(x,y)(mean(x>pS*y,2)),...
                        pPR(okR),num2cell(obj.pTolF(okR,iPh)),'un',0)');
            isSig = zeros(size(pvSig,1),obj.nApp);
            isSig(:,okR) = (pSig >= obj.pSigMin) | (pvSig > 0);            
            
            % ----------------------------------- %
            % --- DISTANCE RANGE CALCULATIONS --- %
            % ----------------------------------- %
            
            % calculates the distance range (fills in any missing phases
            % with NaN values)
            DrngC0 = cellfun(@(x)(calcImageStackFcn...
                        (x,'range')),num2cell(obj.fPosL{iPh},2),'un',0); 
            DrngC0(cellfun(@isempty,DrngC0)) = {NaN(1,2)};                    
            
            % calculates the range of each fly over all phases
            if obj.is2D
                DrngC = cellfun(@(x)(sqrt(sum(x.^2,2))),DrngC0,'un',0);
            else
                DrngC = cellfun(@(x)(x(:,1)),DrngC0,'un',0);               
            end                       
                
            % if the blob filter has been calculated, then exit
            Drng = combineNumericCells(DrngC(:)');

            % determines the blobs that haven't moved far over the phase
            obj.setStatusFlag(Zflag,Drng,isSig,iPh);
            
        end
            
        % --- sets up the overall movement status flags
        function setupOverallStatusFlags(obj)
                    
            % determines the max status flags of the feasible frames (must
            % have a phase duration > nFrmMin);
            isOK = (diff(obj.iMov.iPhase,[],2) + 1) > obj.nFrmMin;  
            obj.sFlagMax = calcImageStackFcn(obj.sFlag(isOK),'max');
            
        end        
        
        % --- determines the final status flags for each blob
        function setStatusFlag(obj,sFlag0,Drng,allSig,iPh)
        
            % determines which blobs have moved appreciably
            isShort = diff(obj.iMov.iPhase(iPh,:)) <= obj.nFrmMin;
            isMove = Drng > obj.iMov.szObj(1); 
            
            % re-classify blobs that have medium z-scores, but significant
            % movement, as being completely stationary
            sFlag0((sFlag0 == 1) & isMove) = 1;
            
            % re-classify blobs that high z-scores, but insigificant
            % movement, as being partially moving
            isS2 = sFlag0 == 2;
            sFlag0(isS2 & ~isMove) = 1 - isShort; 
            
            % if a blob is flagged as significant and moving, but not all
            % frames were significant, then flag as being stationary
            sFlag0((isS2 & isMove) & (allSig==0)) = 2;
            
            % stores the status flags
            obj.sFlag{iPh} = sFlag0;
            
        end        
        
        % -------------------------------------------- %
        % --- FLY POSITION RECALCULATION FUNCTIONS --- %
        % -------------------------------------------- % 
        
        % --- calculates the blob positions for a specific phase
        function recalcFlyPos(obj,IL,iPh)
            
            % if the user has cancelled then exit
            if ~obj.calcOK; return; end
            
            % initialisations
            pW = 1/3;
            N = ceil(1.5*obj.bSzT);
            hG = fspecial('disk',2);        
            wStr0 = 'Recalculating Coordinates';
            
            % loops through all regions recalculating the blob locations
            % using the new background image estimate
            for i = find(obj.iMov.ok(:)')
                pNw = 0.45*(1+i/(1+obj.nApp));
                wStrNw = sprintf('%s (Region %i of %i)',wStr0,i,obj.nApp);
                if obj.hProg.Update(3+obj.wOfsL,wStrNw,pNw)
                    obj.calcOK = false;
                    return                    
                end                 
                
                % memory allocation
                pTolT = NaN(getSRCount(obj.iMov,i),1);                
                
                % calculates the new locations over all frames
                for j = find(obj.iMov.flyok(:,i)')
                    % retrieves the local filtered images
                    iRT = obj.iMov.iRT{i}{j};
                    IBGL = obj.Ibg{iPh}{i}(iRT,:);
                    IRL = cellfun(@(x)(IBGL-x(iRT,:)),IL(:,i),'un',0);
                    IRLF = cellfun(@(x)(imfiltersym(x,hG)),IRL,'un',0);
                    
                    % retrieves the sub-images surrounding the points
                    fP0 = obj.getSRPos(iPh,i,j);                    
                    IsubS = cellfun(@(x,y)(obj.getPointSubImage...
                                        (x,y,N)),IRLF,fP0,'un',0);
                    
                    % determines the threshold levels
                    IMaxS = cellfun(@(x)(max(x(:))),IsubS);
                    pTolT(j) = median(IMaxS*pW,'omitnan');
                    obj.pStats.IR{i,iPh}(j,:) = IMaxS;
                    
                    % offsets and updates the position array
                    fP0 = cellfun(@(x,y)(obj.recalcBlobPos...
                                        (x,y,pTolT(j))),IsubS,fP0,'un',0);
                    obj.setSRPos(iPh,i,j,fP0);
                end                
                
                % calculates the overall threshold value
                obj.pTolF(i,iPh) = median(pTolT,'omitnan');
            end
            
        end
        
        % --- recalculates the blob positional coordinates
        function fP = recalcBlobPos(obj,I,fP,pTolT)
            
            %
            szL = size(I);
            N = (szL(1)-1)/2;
            
            %
            B0 = setGroup((N+1)*[1,1],szL);
            [~,B] = detGroupOverlap(I > pTolT,B0);
            
            % calculates the blob centroids
            [iGrp,pC] = getGroupIndex(B,'Centroid');            
            switch length(iGrp)
                case 0
                    % case is no blobs
                    iMx = argMax(I(:));
                    [yMx,xMx] = ind2sub(szL,iMx);
                    pC = [xMx,yMx];
                    
                case 1
                    % case is a single blob
                    pC = roundP(pC);
                    
                otherwise
                    % case is multiple blobs
                    iMx = argMax(cellfun(@(x)(max(I(x))),iGrp));
                    pC = roundP(pC(iMx,:));
                    
                    
            end
            
            % offsets the position marker
            fP = fP + (pC - (N+1));
            
        end
        
        % --- retrieves the sub-region positions (over all frames)
        function fPSR = getSRPos(obj,iPh,iApp,iT)
            
            fPSR = cellfun(@(x)(x(iT,:)),obj.fPosL{iPh}(iApp,:),'un',0)';
            
        end
        
        % --- sets the sub-region positions (over all frames)
        function setSRPos(obj,iPh,iApp,iT,fPSR)
            
            for iFrm = 1:size(obj.fPosL{iPh}(iApp,:),2)
                obj.fPosL{iPh}{iApp,iFrm}(iT,:) = fPSR{iFrm};
            end
            
        end        
        
        % ------------------------------------------- %
        % --- BACKGROUND IMAGE ESTIMATE FUNCTIONS --- %
        % ------------------------------------------- %                 
        
        % --- calculates the optimal blob size
        function bSz = calcBlobSize(obj)
            
            % memory allocation
            mStr = 'omitnan';
            sD = NaN(obj.nApp,2);
            [ff,II] = deal(cell(obj.nApp,2));            
            
            %
            for i = find(obj.iMov.ok(:)')
                for j = 1:2
                    II{i,j} = max(obj.frObj.hC{i},[],j,mStr);
                    [sD(i,j),ff{i,j}] = obj.optGaussSignal(II{i,j});
                end
            end
            
            % calculates the blob size based on the max std-dev values
            bSz = roundP(max(arr2vec(sD*sqrt(log(1/obj.pTolSz)))));
            
        end        
        
        % --- estimates the background image estimate
        function calcImageBGEst(obj,I,iPh)
                        
            % initialisations
            ZTol = 2.5;
            wStr0 = 'Background Estimate';
            
            % calculates the 
            for i = find(obj.iMov.ok(:)')
                % updates the progressbar
                pW = 0.5*i/(1+obj.nApp);
                wStrNw = sprintf('%s (Region %i of %i)',wStr0,i,obj.nApp);
                if obj.hProg.Update(3+obj.wOfsL,wStrNw,pW)
                    obj.calcOK = false;
                    return                    
                end 
                
                %
                Imn = cellfun(@(x)(nanmean(x(:))),I(:,i));
                Z = (Imn - mean(Imn))/std(Imn);
                okF = abs(Z) < ZTol;
                
                for iT = 1:getSRCount(obj.iMov,i)
                    % retrieves sub-image/positional data
                    iRT = obj.iMov.iRT{i}{iT};
                    IL = cellfun(@(x)(x(iRT,:)),I(okF,i),'un',0);
                    
                    if obj.iMov.flyok(iT,i)
                        % retrieves the blob coordinates
                        fP = cellfun(@(x)...
                                (x(iT,:)),obj.fPosL{iPh}(i,okF),'un',0)';

                        % sets up the background image estimate
                        IbgE = obj.setupBGEstStack(IL,fP);
                        Imx0 = calcImageStackFcn(IbgE,'max');

                        % calculates background image estimate (dim based)
                        if obj.iMov.is2D
                            % case is 2D open field expt
                            IbgLmn = (interpImageGaps(Imx0,1) + ...
                                      interpImageGaps(Imx0,2))/2;
                        else
                            % case is 1D grid based expt
                            IbgLmn = interpImageGaps(Imx0);
                        end  
                        
                        IbgLmn = max(IbgLmn,Imx0);
                    else
                        % case is the sub-region is rejected
                        IbgLmn = calcImageStackFcn(IL,'max');
                    end
                    
                    % sets the sub-region background image estimate
                    obj.Ibg{iPh}{i}(iRT,:) = IbgLmn;
                end
            end
                                
        end
        
        % --- sets up the background image stack
        function I = setupBGEstStack(obj,I,fP)
            
            % memory allocation
            pW = 1.5;
            sz = size(I{1});
            N = ceil(pW*obj.bSzT);

            %
            [X,Y] = meshgrid(-N:N); 
            D = sqrt(X.^2 + Y.^2); 
            Bfilt = D <= N;
            
            %
            szF = size(Bfilt);             
            xiN = (1:szF) - floor((szF(1)-1)/2+1);  
            Brmv = bwmorph(Bfilt > 0,'dilate',1+obj.nI);

            % fill in the regions surrounding the points
            for i = 1:length(I)
                % sets up the image weighting array
                [iR,iC] = deal(fP{i}(2)+xiN,fP{i}(1)+xiN);
                ii = (iR > 0) & (iR < sz(1));
                jj = (iC > 0) & (iC < sz(2));
                
                % removes the region containing the blob
                ITmp = I{i}(iR(ii),iC(jj));
                ITmp(Brmv(ii,jj)) = NaN;
                I{i}(iR(ii),iC(jj)) = ITmp;
            end
            
        end
        
        % ----------------------------------------------- %
        % --- INTER-PHASE POSITION MATCHING FUNCTIONS --- %
        % ----------------------------------------------- %         
        
        % --- matches the object position's between phases
        function interPhasePosMatch(obj)
            
            % if there is only one video phase, then exit
            if obj.nPhase == 1            
                return
            end
            
            % calculates the blob coordinate matches over all regions
            for i = find(obj.iMov.ok(:)')
                xiS = 1:getSRCount(obj.iMov,i);                
                for j = find(arr2vec(obj.iMov.flyok(xiS,i))')
                    obj.subRegionPosMatch(i,j)
                end
            end
            
        end        
        
        % --- performs the sub-region position match (over all phases)
        function subRegionPosMatch(obj,iApp,iT)

            % parameters
            DTol = 0.5;
            okPh = obj.iMov.vPhase < 3;
            sFlagTM = zeros(obj.nPhase,1);
            
            % retrieves the status flag (for the given region/sub-region)
            sFlagTM(okPh) = cellfun(@(x)(x(iT)),obj.sFlagT(okPh,iApp));            
            
            % performs the search based on if the object moves or not
            isF = sFlagTM == 1;
            if all(isF)
                % case is the object is moving over all frames
                return
                
            elseif any(isF)
                % case is some of the phases have moving objects
                
                % loop through each of the stationary phases matching up
                % the locations with that from known regions
                for i = obj.getPhaseSearchIndices(isF,okPh)
                    if sFlagTM(i) == 2
                        % determines the comparison phase index
                        [iPrC,iDir] = obj.getCompPhaseIndex(isF,i);                        
                        
                        % retrieves the known/potential location coords
                        fPosT = obj.fPosP{i,iApp}(:,iT);
                        if iDir < 0
                            % case is the comparison phase precedes the
                            % current phase
                            fPosC = obj.fPosL{iPrC}{iApp,end}(iT,:);
                            
                        else
                            % case is the comparison phase proceeds the
                            % current phase
                            fPosC = obj.fPosL{iPrC}{iApp,1}(iT,:);
                        end
                        
                        % calculates the distances between the
                        % known/potential points (over all frames)
                        if ~any(all(cellfun(@isempty,fPosT)))
                            DC0 = cellfun(@(x)(pdist2(x,fPosC)),fPosT,'un',0);
                            DC = mean(combineNumericCells(DC0),2);
                            DCN = DC/obj.frObj.dTol;
                        
                            % if the closest point is far                            
                            [DCNmn,iDCNmn] = min(DCN);
                            if DCNmn < DTol
                                iDCmn = iDCNmn;
                            else
                                yPosT = mean(obj.yPosP{i,iApp}{iT},2);
                                iDCmn = argMax(yPosT./max(1,DCN));
                            end

                            % if the group is within distance tolerance,
                            % then reset the positonal values
                            for iFrm = 1:length(fPosT)
                                obj.fPosL{i}{iApp,iFrm}(iT,:) = ...
                                                  fPosT{iFrm}(iDCmn,:);
                            end
                        end

                        % flag the current phase has been searched
                        isF(i) = true;
                        
                    end
                end
                
            else
                % case is the object is stationary over the whole video
                
                % determines the static group indices
                okPh = obj.iMov.vPhase < 3;
                fPosPT = cellfun(@(x)(x{1,iT}),obj.fPosP(okPh,iApp),'un',0);
                indG = obj.frObj.findStaticPeakGroups(fPosPT);
                
                % determines which groups are present over all phases
                if isempty(indG)
                    % FINISH ME?
                    a = 1;                    
                    
                else                    
                    % if such groupings exist, then determine which
                    % grouping should be used for 
                    
                    % retrieves the static group position values
                    [fPosPT,rPosPT] = obj.getStatGroupPos(indG,iApp,iT);                    
                    if length(fPosPT) == 1
                        % case is there is only one static grouping
                        iMx = 1;
                    else
                        % otherwise, determine the most likely grouping
                        iMx = argMax(mean(rPosPT,1));                        
                        BMx = ~setGroup(iMx,size(fPosPT));
                        obj.appendAmbigPos(fPosPT(BMx),iApp,iT);                        
                    end                    
                    
                    % resets the stationary regions with the most likely
                    % static point grouping
                    [fPosPT,iokPh] = deal(fPosPT{iMx},find(okPh));
                    for i = 1:length(fPosPT)
                        iPh = iokPh(i);
                        for iFrm = 1:size(obj.fPosL{iPh},2)
                            obj.fPosL{iPh}{iApp,iFrm}(iT,:) = ...
                                                        fPosPT{i}{iFrm};
                        end
                    end
                end
            end
            
        end
        
        % --- appends the ambiguous object positional coordinates
        function appendAmbigPos(obj,fPosPT,iApp,iT)
            
            % reformats the positional coordinates
            okPh = find(obj.iMov.vPhase < 3);
            A = num2cell(cell2cell(fPosPT,0),2);
            fPosAmT = cellfun(@(x)(cellfun(@(y)(cell2mat(y(:))),...
                        num2cell(cell2cell(x,0),2),'un',0)),A,'un',0);
    
            % sets the ambiguous position coordinates
            for iPh = 1:length(fPosAmT)
                obj.fPosAm{okPh(iPh),iApp}{iT} = fPosAmT{iPh};
            end
                
        end
        
        % --- retrieves the sub-region coordinates
        function [fPosPT,yPosPT] = getStatGroupPos(obj,indG,iApp,iT)
            
            % memory allocation
            nG = length(indG);
            okPh = obj.iMov.vPhase < 3;
            [fPosPT,yPosPT] = deal(cell(nG,1),zeros(sum(okPh),nG));
            fP0 = cellfun(@(x)(x(:,iT)),obj.fPosP(okPh,iApp),'un',0);
            yP0 = cellfun(@(x)(x{iT}),obj.yPosP(okPh,iApp),'un',0);
            
            % sets the positional/peak values
            for i = 1:nG
                indGC = num2cell(indG{i});
                fPosPT{i} = cellfun(@(x,y)(cellfun(@(z)...
                        (z(y,:)),x,'un',0)),fP0,indGC,'un',0);
                yPosPT(:,i) = cellfun(@(x,y)(mean(x(y,:))),yP0,indGC);
            end
            
        end            
        
        % --------------------------- %
        % --- OLD CLASS FUNCTIONS --- %
        % --------------------------- %        
            
        % --- determines if stationary blobs are consistent over all phases
        function checkStationaryBlobs(obj)
            
            % if the user cancelled, then exit
            if ~obj.calcOK; return; end
%             obj.hProg.Update(2+obj.wOfsL,'Moving Object Tracking',0.25);
%             obj.hProg.Update(3+obj.wOfsL,'Analysing Region',0); 

            % distance tolerance calculation
            if obj.iMov.is2D
                % case is for a 2D setup
                Dtol = sqrt(2)*obj.iMov.szObj(1)/(1+obj.nI);                
            else
                % case is for a 1D setup
                Dtol = obj.iMov.szObj(1)/(1+obj.nI);
            end
            
            % calculates the overall sub-region status flags
            okPh = find(obj.iMov.vPhase < 3);            
            [iTube,iApp] = find((obj.sFlagMax == 1) & obj.iMov.flyok);
            
            % loops through each of stationary objects determining if the
            % location of the blob is stationary over all phases/frames
            for i = 1:length(iTube)
                % sets the global region/sub-region indices
                [j,k] = deal(iTube(i),iApp(i));
                
                % retrieves the blob locations over all frame/phases
                fP = cellfun(@(y)(cell2mat(cellfun(@(x)...
                        (x(j,:)),y(k,:)','un',0))),obj.fPosL(okPh),'un',0);                
                fPT = cell2mat(fP);                
                
                % determines if there has been significant over all frames
                if ~all(range(fPT,1) < Dtol)
                    % calculates the mean locations for each phase
                    fPmn = cell2mat(cellfun(@(x)(mean(x,1)),fP,'un',0));                    
                    
                    % determines the unique groups 
                    D = pdist2(fPmn,fPmn);
                    D(isnan(D)) = 0;
                    isF = false(size(D,1),1);
                    
                    % groups the likely locations over all phases
                    kGrp = [];
                    while any(~isF)
                        % determines the points closest to the candidate
                        j0 = find(~isF,1,'first');
                        jj = D(:,j0) < Dtol;
                       
                        % stores the indices of the phases with the 
                        kGrp{end+1} = find(jj);
                        [D(:,jj),D(jj,:)] = deal(NaN);
                        isF(jj) = true;
                    end                                                                                      
                    
                    % sets the mean coordinates of each unique grouping
                    fPGrp = roundP(cell2mat(cellfun(@(x)...
                                      (mean(fPmn(x,:),1)),kGrp','un',0)));
                    if obj.nI > 0   
                        % downsamples the coordinates (if reqd)
                        fPGrp = obj.downsampleImageCoords(fPGrp,obj.nI);                        
                    end
                    
                    % retrieves the previous location data
                    if isempty(obj.prData0)
                        % set the most likely grouping to be that with the
                        % highest phase count
                        iMx = argMax(cellfun(@length,kGrp));
                    else
                        % retrieves the previous coordinates
                        fPpr = obj.prData0.fPosPr{k}{j}(end,:);
                        if obj.nI > 0
                            % downsamples the coordinates (if reqd)
                            fPpr = obj.downsampleImageCoords(fPpr,obj.nI);
                        end
                        
                        % determines the grouping which is closest to the
                        % previously known location
                        [Dmn,iMx] = min(sum((fPGrp - fPpr).^2,2).^0.5);
                        if Dmn > Dtol
                            % if the distance is too hight, then set the 
                            % most likely grouping to be that with the
                            % highest phase count                            
                            iMx = argMax(cellfun(@length,kGrp));
                        end
                    end                                        
                    
                    % calculates the x/y offset of the sub-region
                    xOfs = obj.iMov.iC{k}(1)-1;
                    yOfs = obj.iMov.iR{k}(1)-1;
                    pOfsL = [0,obj.iMov.iRT{k}{j}(1)-1];
                    pOfs = pOfsL + [xOfs,yOfs];
                    
                    % sets the row/column indices                    
                    iRT0 = obj.iMov.iRT{k}{j};
                    [iR0,iC0] = deal(obj.iMov.iR{k},obj.iMov.iC{k});                    
                    
                    % sets the groupings which match the most likely                    
                    rsGrp = ~setGroup(kGrp{iMx},[1,obj.nPhase]);     
                    fPnw = roundP(fPGrp(iMx,:));
                    if obj.nI > 0
                        % upsamples the coordinates (if required)
                        fPnw = 1 + obj.nI*(1 + 2*(fPnw-1));
                    end
                    
                    % resets the coordinates for each phase/frame
                    for iPh = find(rsGrp)
                        for ii = 1:length(obj.indFrm{iPh})
                            % resets the local blob coordinates
                            obj.fPosL{iPh}{k,ii}(j,:) = fPnw;
                            obj.fPos{iPh}{k,ii}(j,:) = fPnw + pOfsL;
                            obj.fPosG{iPh}{k,ii}(j,:) = fPnw + pOfs;
                        end
                        
                        % re-estimates the sub-region background image
                        fPTmn = roundP(mean(fPnw,1,'omitnan'));
                        IbgTmp = obj.IbgT{iPh}(iR0(iRT0),iC0);
                        IbgNw = obj.estSubRegionBG({IbgTmp},fPTmn);                        
                        obj.Ibg{iPh}{k}(iRT0,:) = IbgNw;
                    end
                end
            end
            
        end
        
        % --- analyses the untrackable phase
        function analyseUntrackablePhase(obj,iPh)
            
            % parameters
            prTol = 0.75;
            ILim = [10,250];                      
            
            % memory allocation
            fP0 = cell(obj.nApp,2); 
            iFrmPh = obj.iMov.iPhase(iPh,:);
            Dscale = obj.iMov.szObj(1)/2;            
            [iR,iC] = deal(obj.iMov.iR,obj.iMov.iC);
            
            % determines if any of the images in the phase are completely
            % untrackable (either too dark or too bright)
            ImgMd = cellfun(@(x)(median(x(:),'omitnan')),obj.Img{iPh});
            if any(ImgMd <= ILim(1)) || any(ImgMd >= ILim(2))
                % resets the coordinates for each sub-region to NaNs
                for i = 1:length(obj.fPos{iPh})
                    obj.fPos{iPh}{i}(:) = NaN;
                    obj.fPosL{iPh}{i}(:) = NaN;
                end
                
                % exits the function
                return
            end
            
            % determines if the surrounding phases is feasible
            okPh = obj.iMov.vPhase < 3;
            isOK = [(iPh > 1) && okPh(iPh-1),...
                    (iPh < obj.nPhase) && okPh(iPh+1)];
            
            % sets the lower phase index (if feasible)
            for i = find(isOK)
                iPhS = iPh + 2*(i-1.5);
                if i == 1
                    fP0(:,i) = obj.fPosL{iPhS}(:,end);
                else
                    fP0(:,i) = obj.fPosL{iPhS}(:,1);
                end
            end
            
            % determines if the phase is surrounded by feasible phases. if
            % so, then interpolate the coordinates from these frames
            if all(isOK)
                % sets the interpolation indices
                xiP = iFrmPh([1,end]) + [-1,1];
                
                % interpolates over all regions/sub-regions
                for i = 1:obj.nApp
                    % retrieves the interpolation coordinates
                    xI = cell2mat(cellfun(@(x)(x(:,1)),fP0(i,:),'un',0));
                    yI = cell2mat(cellfun(@(x)(x(:,2)),fP0(i,:),'un',0));
                    
                    for k = 1:getSRCount(obj.iMov,i)
                        % calculates the interpolated x/y-coordinates
                        xInw = interp1(xiP,xI(k,:),iFrmPh,'linear');
                        yInw = interp1(xiP,yI(k,:),iFrmPh,'linear');
                        
                        % sets the new positional values
                        for j = 1:length(iFrmPh)
                            obj.fPosL{iPh}{i,j}(k,:) = [xInw(j),yInw(j)];
                        end
                    end
                end
                
                % exits the function
                return
            end
            
            % calculates the hm filtered image stack
            Ihm = cellfun(@(x)(applyHMFilter(x)),obj.Img{iPh},'un',0);              
            for i = find(obj.iMov.ok)
                % sets up the cross-correlation images
                IL = cellfun(@(y)(y(iR{i},iC{i})),Ihm,'un',0);

                % calculates the mean surrounding locations
                fPmn = roundP(calcImageStackFcn(fP0(i,:)));
                
                % estimates the location of the points over all frames
                for j = 1:obj.nTube(i)
                    % retrieves the local x-correlation images                    
                    iRT = obj.iMov.iRT{i}{j};
                    ILS = cellfun(@(x)(1-normImg(x(iRT,:))),IL,'un',0);
                    fPmnS = fPmn(j,:) - [1,iRT(1)]-1;
                    
                    % sets up the distance mask
                    sz0 = size(ILS{1});
                    Dw = bwdist(setGroup(min(max(1,fPmnS),flip(sz0)),sz0));
                    Qw = (1./max(0.5,Dw/Dscale)).^2;
                    
                    % calculates the likely coords and updates within the
                    % storage arrays
                    for k = 1:length(ILS)
                        % determines the most significant local blobs
                        ILSQ = ILS{k}.*Qw;
                        iP = find(imregionalmax(ILS{k}));
                        [ILSS,iS] = sort(ILSQ(iP),'descend');
                        ii = ILSS/ILSS(1) > prTol;
                        
                        % determines the blob closest to the estimate
                        if any(ii)
                            iPR = iP(iS(ii));
                            iNw = argMin(Dw(iPR));
                            [yNw,xNw] = ind2sub(size(Qw),iPR(iNw));

                            % sets the coordinates into storage
                            obj.fPosL{iPh}{i,k}(j,:) = [xNw,yNw];
                        end
                    end
                end
            end
            
        end
        
        % --- analyses the stationary blobs for the phase, iPh
        function analyseStationaryBlobs(obj,IL0,iPh)
            
            % initialisations
            usePrevData = false;
            nApp = length(obj.iMov.iR);
            Ds = obj.iMov.szObj(1)/2;
            
            % calculates the overall sub-region status flags            
            hasMove = (obj.sFlag{iPh} == 0) & (obj.sFlagMax >= 1);
            isOK = cellfun(@(x)(~all(isnan(x(:)))),IL0(:,1));
                                    
            % -------------------------------------------- %
            % --- INTER-PHASE STATIC OBJECT COMPARISON --- %
            % -------------------------------------------- %
            
            % here we determine if a blob has moved on another phase. if
            % so, then use that information to determine the location of
            % the stationary ambiguous blobs from this phase              
            
            % initialisations
            wStr0 = 'Analysing Sub-Region (%i of %i)';     
            
            % determines the static blobs from the phase
            nFrm = length(obj.Img{iPh});
            if nFrm == 1
                % phase is only one frame, so analyse all
                [statObj,Ds] = deal(obj.iMov.flyok,2*Ds);                
            else
                % otherwise, determine the static objects from the phase                
                statObj = (obj.sFlag{iPh} <= 1) & obj.iMov.flyok;
                usePrevData = ~isempty(obj.prData0);        
            end
            
            % determine the regions/sub-regions that need to
            % be re-tracked for stationary/low-residual blobs
            [iTube,iApp] = find(statObj);
            [Ztot0,ZtotF,Ixc,Bw] = deal(cell(nApp,1));
            nTubeS = length(iTube);

            % loops through each of the probable stationary regions 
            % determining the most likely blob objects
            for i = 1:nTubeS
                % updates the progress bar
                wStrNw = sprintf(wStr0,i,nTubeS);
                if obj.hProg.Update(3+obj.wOfsL,wStrNw,i/(1+nTubeS))
                    % if the user cancelled, then exit
                    obj.calcOK = false;
                    return
                end                                 

                % retrieves the image stack for the sub-region 
                [j,k] = deal(iTube(i),iApp(i));
                iRT0 = obj.iMov.iRT{k}{j};                 

                % sets up the image stack for template analysis
                if isempty(obj.Iss{k,iPh})
                    [obj.Iss{k,iPh},obj.dIss{k,iPh}] = ...
                                    obj.setupStatObjStack(IL0(:,k),iPh,k);
                end

                % sets up the total combine image stack
                if isempty(ZtotF{k})
                    Bw0 = getExclusionBin(obj.iMov,size(IL0{1,k}),k);
                    if obj.nI > 0
                        Bw{k} = bwmorph(obj.downSampleImgStack(Bw0),'erode');
                    else
                        Bw{k} = bwmorph(Bw0,'erode');
                    end
                    
                    Ixc{k} = cellfun(@(x)(max(0,calcXCorr(obj.hFilt,...
                           fillArrayNaNs(x))).*Bw{k}),obj.dIss{k,iPh},'un',0);
                    Ztot0{k} = cellfun(@(x,y)...
                           (normImg(x).*(1-normImg(y)).*Bw{k}),...
                            obj.dIss{k,iPh},obj.Iss{k,iPh},'un',0);                       
                    ZtotF{k} = cellfun(@(x,y)...
                           (x.*normImg(y).*Bw{k}),Ztot0{k},Ixc{k},'un',0);                        
                end                    

                % retrieves the total combine image stack for the
                % current sub-region
                [iRT,dP] = obj.getSRRowIndices(k,j); 
                ZtotL0 = cellfun(@(x)(x(iRT,:)),Ztot0{k},'un',0);
                
                %
                if obj.sFlag{iPh}(j,k) == 1
                    % initialisations
                    szL = size(ZtotL0{1});
                    [fP0,Btmp] = deal(NaN(1,2),false(szL));
                    pOfs = [floor(-obj.Dtol),ceil(obj.Dtol)];                    
                    
                    % retrieves the coordinates of the 
                    fPr = cell2mat(cellfun(@(x)(x(j,:)),...
                                            obj.fPosL{iPh}(k,:)','un',0));
                    if obj.nI > 0
                        fPr = obj.downsampleImageCoords(fPr,obj.nI);
                    end                    
                    
                    % sets up the exclusions binary mask surrounding the
                    % currently determine locations
                    iC = max(1,min(fPr(:,1))+pOfs(1)):...
                           min(szL(2),min(fPr(:,1))+pOfs(2));
                    iR = max(1,min(fPr(:,2))+pOfs(1)):...
                           min(szL(1),min(fPr(:,2))+pOfs(2));                       
                    Btmp(iR,iC) = true;
                    
                    % applies the exclusion binary mask
                    ZtotL0 = cellfun(@(x)(x.*Btmp),ZtotL0,'un',0);
                                        
                elseif hasMove(j,k)
                    % otherwise, set the comparison coordinates to the last
                    % phase which the blob moved
                    fP0 = obj.getLikelyPrevCoord(iPh,k,j);  
                    
                elseif usePrevData
                    % case is there are coordinates from the previous
                    % solution file to compare against
                    if iPh == 1
                        % case is the first phase, so use previous data
                        calcStat = true;
                    else
                        % otherwise, only is the previous data if there has
                        % been no movement over previous phases
                        sFlagPr = obj.sFlag(1:(iPh-1));
                        calcStat = all(cellfun(@(x)(x(j,k)),sFlagPr) == 1);
                    end
                    
                    % determines if the previous data can be used 
                    if calcStat
                        % case is the blob hasn't moved since the start of
                        % the video (over all phases)
                        fP0 = roundP(mean...
                                (obj.prData0.fPosPr{k}{j},1,'omitnan'));
                        if obj.nI > 0
                            % downsamples the coordinates (if necessary)
                            fP0 = obj.downsampleImageCoords(fP0,obj.nI);
                        end                        
                    else
                        % otherwise, set NaN's for the previous coordinates
                        fP0 = NaN(1,2);                        
                    end
                else
                    % otherwise, set NaN's for the previous coordinates
                    fP0 = NaN(1,2);
                end

                % calculates the most likely static blobs 
                fPnw0 = obj.calcLikelyStaticBlobs(ZtotL0,fP0,dP,Ds);
                if ~isnan(fP0(1))
                    % if there is a comparison value, then determine if the
                    % new coordinates is close enough  
                    fP0ds = fP0;
                    if any(pdist2(fPnw0,fP0ds) > Ds)
                        % if not, then use the lesser image stack
                        ZtotLF = cellfun(@(x)(x(iRT,:)),ZtotF{k},'un',0);
                        fPnw0 = obj.calcLikelyStaticBlobs(ZtotLF,fP0,dP,Ds);
                    end
                end
                
                % upsamples the image coordinates (if required)
                if obj.nI > 0
                    ZtotFC = cellfun(@(x)(-x(iRT0,:)),IL0(:,k),'un',0);
                    fPnwF = obj.upsampleImageCoords(ZtotFC,fPnw0);
                else
                    fPnwF = fPnw0;
                end                  

                % sets the most likely static blob locations
                obj.sFlag{iPh}(j,k) = 1;
                for iFrm = 1:size(fPnwF,1)
                    obj.fPosL{iPh}{k,iFrm}(j,:) = fPnwF(iFrm,:);
                end                            
            end       
            
            % ----------------------------------------- %
            % --- BACKGROUND ESTIMATE RECALCULATION --- %
            % ----------------------------------------- %  
            
            % determine the regions/sub-regions that need to
            % be re-tracked for stationary/low-residual blobs
            [iTubeBG,iAppBG] = find(obj.sFlag{iPh} < 2 & obj.iMov.flyok);
            nTubeBG = length(iTubeBG);            
            
            % loops through each of the probable stationary regions 
            % determining the most likely blob objects
            for i = 1:nTubeBG
                % retrieves the image stack for the sub-region 
                [j,k] = deal(iTubeBG(i),iAppBG(i));
                [iC0,iRT0] = deal(obj.iMov.iC{k},obj.iMov.iRT{k}{j});   
                fPBG = cellfun(@(x)(x(j,:)),obj.fPosL{iPh}(k,:)','un',0);
                
                % estimates the sub-region background image
                ILR0 = cellfun(@(x)(x(iRT0,:)),IL0(isOK,k),'un',0);
                IbgL = obj.estSubRegionBG(ILR0,cell2mat(fPBG(isOK)));
                obj.IbgT{iPh}(obj.iMov.iR{k}(iRT0),iC0) = IbgL;  
            end
            
        end        
        
        % --- calculates the coordinates of the likely static blobs
        function fPosS = calcLikelyStaticBlobs(obj,Ztot,fP0mn,dP,Dscale)
            
            % parameters
            zTol = 1/3;
            pTolZ = 0.05;
            
            % initialisations
            nFrm = length(Ztot);
            dTol = obj.iMov.szObj(1)/2;
            Bedge = bwmorph(true(size(Ztot{1})),'remove');            
            
            % ------------------------------------ %
            % --- Z-MASK IMAGE STACK REDUCTION --- %
            % ------------------------------------ %
            
            % removes any binary groups that overlap with the edge
            for i = 1:length(Ztot)
                % separates the regional maxima from each other
                Ld = watershed(bwdist(imregionalmax(Ztot{i})));
                Ztot{i}(Ld==0) = 0;
                
                % removes any binary groups on the frame edge
                [~,Brmv] = detGroupOverlap(Ztot{i}>pTolZ,Bedge);
                Ztot{i}(bwmorph(Brmv,'dilate')) = 0;            

                % removes the extra row
                Ztot{i} = Ztot{i}((1+dP(1)):(end-dP(2)),:);
            end
            
            % calculates the coordinate of the max-coord
            if ~isnan(fP0mn(1))
                % calculates the distance weighting mask
                fP0mn = max(1,min(fP0mn,flip(size(Ztot{1}))));
                Dw = bwdist(setGroup(fP0mn,size(Ztot{1})));
                Qw = double(1./max(0.5,Dw/Dscale)).^2;
                Ztot = cellfun(@(x)(x.*Qw),Ztot,'un',0);
            end
            
            % ----------------------------------------- %
            % --- MOST LIKELY STATIC BLOC DETECTION --- %
            % ----------------------------------------- %   
            
            % parameters
            pTile = 75;
            
            % calcualtes the mean image stack values. from this determine
            % the local maxima linear indices
            ZtotMn = calcImageStackFcn(Ztot);
            ZtotMx = calcImageStackFcn(Ztot,'max');
            ZtotMnMx = ZtotMn.*ZtotMx;
            BedgeMn = bwmorph(true(size(Ztot{1})),'remove');
            iGrpMn = find(~BedgeMn.*imregionalmax(ZtotMnMx)); 
            
            % if there are no valid candidates, then exit the function
            if isempty(iGrpMn)
                fPosS = NaN(nFrm,2);
                return
            end
            
            % sorts the peaks by mask value. remove any peaks that are
            % significantly less than the maximum value
            Qtot = ZtotMnMx(iGrpMn);
            [QtotS,iS] = sort(Qtot,'descend');
            iS = iS(QtotS/QtotS(1) > zTol);
            iGrpMn = iGrpMn(iS);
            
            % if there is ambiguity in the most likely blob location, then
            % reduce down the list of likely candidates
            if length(iGrpMn) > 1
                % thresholds the image for the lower tolerance (removes any
                % local maxima on the image edge)
                Btmp = ~BedgeMn.*(ZtotMnMx > zTol*QtotS(1));
                jGrpMn = getGroupIndex(Btmp);                
                
                % calculates the objective values for each thresholded blob
                ZGrpMn = cellfun(@(x)(prctile(ZtotMnMx(x),pTile)),jGrpMn);
                
                % determines the peak point within the most likely blob
                iMx = argMax(ZGrpMn);
                jMx = argMax(ZtotMnMx(jGrpMn{iMx}));
                iGrpMn = jGrpMn{iMx}(jMx);
            end
            
            % calculates the location of the most likely static blob
            [yPC,xPC] = ind2sub(size(ZtotMnMx),iGrpMn);
            
            % ----------------------------------- %
            % --- FRAME STATIC BLOC DETECTION --- %
            % ----------------------------------- %             
            
            % calculates the coordinate of the max-coord
            sz = size(Ztot{1});
            fPosS = NaN(nFrm,2);       
            
            % calculates the local maxima over all frames
            iGrp0 = cellfun(@(x)(find(imregionalmax(x))),Ztot,'un',0);

            % from the candidate 
            for i = 1:nFrm
                % determines the peak that is closest to the candidate 
                [yPF,xPF] = ind2sub(sz,iGrp0{i});
                D = pdist2([xPF(:),yPF(:)],[xPC,yPC]);

                % converts the linear coordinates to cartisean
                [yPnw,xPnw] = ind2sub(sz,iGrp0{i}(argMin(D)));
                fPosS(i,:) = [xPnw,yPnw];
            end                                      
            
        end        
        
        % --- retrieves the likely previous coordinates from surrounding
        %     phases
        function fPF = getLikelyPrevCoord(obj,iPh,iApp,iTube)
            
            % memory allocation
            fP0 = NaN(2);            
            fDir = {'last','first'};
            
            % determines the feasible 
            okPh = obj.iMov.vPhase < 3;
            okPh(iPh) = false;    
            
            % sets up the status flag for the blob over all feasible phases
            sFlagP = NaN(obj.nPhase,1);
            sFlagP(okPh) = cellfun(@(x)(x(iTube,iApp)),obj.sFlag(okPh));
            
            % determines the indices of the phases before/after the current
            indP = {find(okPh(1:iPh-1)),iPh+find(okPh(iPh+1:end))};            
            
            % determines if the surrounding phases have an instance of the
            % blob moving
            for i = 1:length(indP)
                iNw = find(sFlagP(indP{i})>0,1,fDir{i});
                if ~isempty(iNw)
                    % if so, then retrieve the coordinates from this phase
                    iPhS = indP{i}(iNw);
                    if i == 1
                        % case is a phase before the current
                        fP0(i,:) = obj.fPosL{iPhS}{iApp,end}(iTube,:);
                    else
                        % case is a phase after the current
                        fP0(i,:) = obj.fPosL{iPhS}{iApp,1}(iTube,:);
                    end
                end
            end
            
            % sets the mean location values
            fPF = roundP(mean(fP0,1,'omitnan'));
            if obj.nI > 0
                fPF = obj.downsampleImageCoords(fPF,obj.nI);
            end
            
        end                    
        
        % --- tracks the movng blobs from the residual image
        function [fPos,pIR] = trackMovingBlobs(obj,IRL,BRng,dTol,pTol)
            
            % initialisations            
            [nFrm,szL] = deal(length(IRL),size(IRL{1}));
            [fPos,pIR] = deal(NaN(nFrm,2),NaN(nFrm,1));            

            % removes any NaN values from the images
            IRL = cellfun(@(x)(x.*BRng),IRL,'un',0);

            % retrieves the maxima for each frame                
            iGrp = cellfun(@(x)(find(imregionalmax(x))),IRL,'un',0);            
            isSig = cellfun(@(x,y)(any(x(y)>pTol)),IRL,iGrp);            
            
            % determines the moving blob properties for each region
            for i = find(isSig(:)')
                % calculates the most
                [pMx,iS] = sort(IRL{i}(iGrp{i}),'descend');
                if pMx(1) > pTol                
                    % determines how many prominent maxima there are
                    ii = pMx >= pTol;
                    if sum(ii) == 1
                        % case is there is one prominent maxima
                        iGrp{i} = iGrp{i}(iS(1));
                    else
                        % case is there are multiple prominent maxima
                        BL = IRL{i} >= pTol;
                        [jGrp,pC] = getGroupIndex(BL,'Centroid');
                        AGrp = cellfun(@length,jGrp)/dTol;
                        IGrp = cellfun(@(x)(mean(IRL{i}(x))),jGrp);

                        % recalculates the centre
                        Z = AGrp.*IGrp;
                        pCmx = roundP(pC(argMax(Z),:));
                        iGrp{i} = sub2ind(szL,pCmx(2),pCmx(1));
                    end                       

                    % sets the pixel intensity and coordinates
                    pIR(i) = IRL{i}(iGrp{i});    
                    [fPos(i,2),fPos(i,1)] = ind2sub(szL,iGrp{i});
                end
            end
            
            % determines if there are any "missing" frames (frames where
            % the max pixel intensity is less than tolerance
            notSig = ~isSig & obj.okFrm;
            if any(notSig)
                % if so, then match the points close to the mean location
                fPosMn = [];
                if mean(isSig) >= 0.5
                    dfPos = range(fPos(isSig,:),1);
                    if all(dfPos <= dTol)
                        fPosMn = mean(fPos(isSig,:),1,'omitnan');
                    end
                end
                
                %
                for i = find(notSig(:)')
                    % calculates the local maxima objective function values
                    if isempty(fPosMn)
                        DP = 1;
                    else
                        [yP,xP] = ind2sub(szL,iGrp{i});
                        DP = max(1,pdist2([xP,yP],fPosMn)/dTol).^2;                        
                    end

                    % sets the pixel intensity and coordinates
                    iMx = argMax(IRL{i}(iGrp{i})./DP);
                    pIR(i) = IRL{i}(iGrp{i}(iMx)); 
                    [fPos(i,2),fPos(i,1)] = ind2sub(szL,iGrp{i}(iMx));                    
                end
                
                % if there are any points with low pixel intensity
                % (relative to the max) then reset their coordinates
                ii = pIR/max(pIR) < obj.iniP.pIRTol;
                if any(ii)
                    fPosFix = roundP(mean(fPos(~ii,:),1,'omitnan'));
                    fPos(ii,:) = repmat(fPosFix,sum(ii),1);
                end
            end

            % scales the maxima by the median pixel intensity
            Imn = cellfun(@(x)(median(x(:),'omitnan')),IRL);
            pIR = (pIR-Imn)./max(1,Imn);

        end                
        
        % ----------------------------------- %
        % --- LOW VARIANCE PHASE ANALYSIS --- %
        % ----------------------------------- %                
        
        % --- optimises the blob filter parameters
        function [pFiltB,ZmxF] = optBlobFilter(obj,I,iPh,iApp,iFrm)
            
            % initialisations
            [dP,dXi] = deal([2,0.25],-1:1); 
            Z = NaN(length(dXi));
            xiT = 1:getSRCount(obj.iMov,iApp);                         
            [X,Y] = meshgrid(dXi);
            
            % sets the 
            yOfs = cellfun(@(x)(x(1)),obj.iMov.iRT{iApp})-1;
            pOfs = [zeros(length(yOfs),1),yOfs(:)];
            
            % retrieves the feasible coordinates
            fP = obj.fPosL{iPh}{iApp,iFrm} + pOfs;
            fP = fP(obj.useP(xiT,iApp),:);            
            if obj.nI > 0
                % downsamples the image coordinates (if required)
                fP = obj.downsampleImageCoords(fP,obj.nI);
            end
            
            % if there are no feasible points then exit
            if isempty(fP)
                [pFiltB,ZmxF] = deal(NaN(1,2),NaN);
                return
            end
            
            % calculates the initial parameters
            if obj.iMov.is2D
                hSz0 = 25;
            else
                hSz0 = min(30,ceil(diff(obj.iMov.yTube{iApp}(1:2))/2));
            end
                        
            % sets the initial parameter estimate
            pFiltB = [hSz0,ceil(hSz0/5)];
            
            % keep looping until the optimal solution is found
            while 1
                % calculates the object functions values for any grid
                % elements that have NaNs
                iNaN = find(isnan(Z));
                for i = arr2vec(iNaN)'
                    pFiltNw = [pFiltB(1)+X(i)*dP(1),pFiltB(2)+Y(i)*dP(2)];
                    Z(i) = obj.objFunc(I,pFiltNw(1),pFiltNw(2),fP);
                end
                
                % determines if the optimal solution has been found (i.e.,
                % current grid square is greater than neighbours)
                if Z(2,2) == max(Z(:))
                    % case is the optimal solution is found
                    ZmxF = Z(2,2);
                    pFiltB = pFiltB + dP;
                    break
                else
                    % determines the direction of the best solution
                    iMx = find(Z==max(Z(:)),1,'first');
                    dPos = [X(iMx),Y(iMx)];
                    pFiltB = pFiltB+[X(iMx),Y(iMx)].*dP;
                    
                    % sets the row update index array
                    if dPos(2) == 0
                        [iR0,iR1] = deal(1:3);
                    elseif dPos(2) < 0
                        [iR1,iR0] = deal(1:2,2:3);
                    else
                        [iR0,iR1] = deal(1:2,2:3);
                    end
                    
                    % sets the column update index array
                    if dPos(1) == 0
                        [iC0,iC1] = deal(1:3);
                    elseif dPos(1) < 0
                        [iC1,iC0] = deal(1:2,2:3);
                    else
                        [iC0,iC1] = deal(1:2,2:3);
                    end                    
                    
                    % resets the objective function array
                    [ZPr,Z] = deal(Z,NaN(3));
                    Z(iR0,iC0) = ZPr(iR1,iC1);
                end
            end
                
        end                   
        
        % --- tracks the moving blobs from the residual image stack, IR
        function detectMovingBlobs(obj,I,IR,IRng,iPh)
                      
            % if the user cancelled, then exit
            if ~obj.calcOK; return; end
            obj.hProg.Update(2+obj.wOfsL,'Moving Object Tracking',0.25);
            obj.hProg.Update(3+obj.wOfsL,'Analysing Region',0);                         
            
            % memory allocation
            nR = 5;
            nApp = length(obj.iMov.pos);
            obj.mFlag = cell(nApp,1);            
            nFrmPh = diff(obj.iMov.iPhase(iPh,:))+1;      
            obj.okFrm = obj.checkFrameFeas(I(:,1));
            
            % sets up the distance tolerance flag
            if isfield(obj.iMov,'szObj')
                if obj.iMov.is2D
                    obj.Dtol = sqrt(0.5)*obj.iMov.szObj(1)/(1+obj.nI);
                else
                    obj.Dtol = 0.5*obj.iMov.szObj(1)/(1+obj.nI);
                end
            else
                obj.Dtol = 5;
            end
            
            % if the frame count is small, then assume stationary and exit
            if nFrmPh <= obj.iniP.nFrmMin
                obj.mFlag = num2cell(zeros(size(obj.iMov.flyok)),1);
                return
            end                                     
            
            % attempts to calculate the coordinates of the moving objects            
            for iApp = find(obj.iMov.ok(:)')
                % updates the progress bar
                wStrNw = sprintf('Analysing Region (%i of %i)',iApp,nApp);
                if obj.hProg.Update(3+obj.wOfsL,wStrNw,iApp/(1+nApp))
                    obj.calcOK = false;
                    return
                end                        
                
                % processes the image stack for the 
                [IL0,IR0] = deal(I(:,iApp),IR(:,iApp));
                obj.frObj.processImgStack(IL0,iPh,iApp);                
                
                % applies the exclusion mask
                Bw = getExclusionBin(obj.iMov,size(I{1,iApp}),iApp);
                [Bw(1:nR,:),Bw((end-(nR-1)):end,:)] = deal(false);                
                
                % sets the image stack for analysis                
%                 IL0 = cellfun(@(x)(Bw.*x),IL0,'un',0);
%                 IR0 = cellfun(@(x)(Bw.*x),IR0,'un',0);                
                 
%                 obj.frObj.plotFrameMaxima();

                % sets the sub-region row/column indices
                [iRT,iCT] = obj.getSubRegionIndices(iApp,size(IL0{1},2));
                
                % sets the image stack based on the type
                if obj.iMov.is2D
                    ImgS = IR0;
                else
                    ImgS = IRng(iApp);
                end
                
                % sets up the search mask for each sub-region
                [obj.mFlag{iApp},obj.Imu(iApp,iPh),...
                obj.Isd(iApp,iPh),obj.pTolF(iApp,iPh)] = ...
                            obj.calcSubRegionProps(ImgS,iRT,iCT);
                obj.mFlag{iApp}(~obj.iMov.flyok(:,iApp)) = 0;
                
                % tracks the blobs for each sub-region
                pTolT = obj.pTolF(iApp,iPh);
                for iT = find(obj.mFlag{iApp}(:)' > 0)
                    % sets up the range binary mask
                    BRng = Bw(iRT{iT},iCT);                  
                    
                    % calculates the most like moving blob locations                    
%                     IL = cellfun(@(x)(x(iRT{iT},iCT)),IL0,'un',0);
                    IRL = cellfun(@(x)(x(iRT{iT},iCT)),IR0,'un',0);                    
                    fPnw = obj.trackMovingBlobs(IRL,BRng,obj.Dtol,pTolT);
                    
                    % sets the tracked coordinates
                    if ~isempty(fPnw)  
                        % retrieves the residual/background pixel values
                        fPnwT = num2cell(fPnw,2);
                        obj.pStats.IR{iApp,iPh}(iT,:) = cellfun(@(x,i)...
                            (obj.getPixelValue(x,i)),IRL,fPnwT);                                                
                              
                        % upscales the result (if image was downsampled)
                        if obj.nI > 0
                            IRLI = cellfun(@(x)...
                                (x(obj.iMov.iRT{iApp}{iT},:)),IR0,'un',0);
                            fPnw = obj.upsampleImageCoords(IRLI,fPnw);
                        end
                              
                        % updates the sub-region coordinates
                        obj.setSubRegionCoord(fPnw,[iPh,iApp,iT]);                              
                    end
                end
            end           
            
            % updates the progressbar
            obj.hProg.Update(3+obj.wOfsL,'Region Analysis Complete',1);            
            
        end
        
        % --- calculates the sub-region properties
        function [mFlag,ImuF,IsdF,pTol] = ...
                            calcSubRegionProps(obj,Isub,iRT,iCT)
            
            % parameters and initialisations            
            iRTF = unique(cell2mat(iRT(:)'));     
            nRT = cellfun(@length,iRT);
            mFlag = zeros(size(obj.iMov.flyok,1),1); 
            
            % ensures the images are stored in a cell array
            if ~iscell(Isub); Isub = {Isub}; end
            
            % sets the local indices of the sub-region row indices
            if obj.nI > 0
                % case is the image is downsampled
                NRT = [0;cumsum(nRT(1:end-1))];
                iRTL = arrayfun(@(x,y)(y+(1:x)),nRT,NRT,'un',0);
            else
                % case is there is no downsampling
                iRTL = iRT;
            end            
            
            % applies a gaussian filter to the range image
            Isub = cellfun(@(x)(imfilter(x,obj.hSR)),Isub,'un',0);
            if obj.is2D && any(obj.iMov.phInfo.hasT)
                % if a 2D setup (and translation is detected) then remove
                % the outside of the image
                DtolT = max(1,roundP(sqrt(obj.Dtol)));
                B = ~bwmorph(true(size(Isub{1})),'erode',DtolT);                
                for i = 1:length(Isub)
                    Isub{i}(B) = median(Isub{i}(~B),'omitnan');
                end
            end                                    
            
            % calculates the max range values (across each row). this is 
            % performed on an image with the open transform removed
            szOpen = ones(obj.nOpenRng);
            IRngOp = cellfun(@(x)(x - imopen(x,szOpen)),Isub(:)','un',0);
            IRngR0 = cellfun(@(x)(max(cell2mat(cellfun(@(y)(y(x,iCT)),...
                            IRngOp,'un',0)),[],1,'omitnan')),iRT,'un',0);
            
            % sets the baseline offset windowing size
            if ~isfield(obj.iMov,'szObj') || any(isnan(obj.iMov.szObj))
                nOpen = ceil(length(IRngR0{1})/4);
            else
                nOpen = 2*obj.iMov.szObj(1);                
            end
            
            % calculates the baseline estimate            
            YRng0 = max(1,cell2cell(cellfun(@(x)(x),IRngR0,'un',0),0));              
            YBL = max(1,imopen(YRng0(:),ones(nOpen,1)));            
            dYRng0 = YRng0(:) - YBL;
            if max(dYRng0) < obj.dyRngMin
                % if the absolute range difference is too low, then all 
                % blobs are probably stationary over all frames so exit
                [ImuF,IsdF,pTol] = deal(NaN);
                return                
            else
                % otherwise, calculate the proportional range
                pYRng = dYRng0./YBL;
            end
            
            % removes points from the edges (1D only)
            nCol = length(iCT);

            % if 1D, then remove any points on the tube edge
            if ~obj.is2D
                DtolT = roundP(obj.Dtol);
                [szL,dC] = deal([nCol,1],max(1,roundP(DtolT)));
                B0 = setGroup((dC+1):(length(iCT)-dC),szL);
                pYRng(repmat(~B0,length(iRTL),1)) = 0; 
            end
                
            % calculates the proportional signal difference              
            ii = pYRng > obj.iniP.pYRngTol;
            if ~any(ii)
                % if the proportional difference is too low, then all blobs
                % are probably stationary over all frames so exit
                [ImuF,IsdF,pTol] = deal(NaN);
                return
            end                
                
            % calculates the mean/std dev range values
            IsubF0 = cellfun(@(x)(x(iRTF,iCT)),Isub,'un',0);
            IsubF = cell2mat(IsubF0(:)');
            ImuF = mean(IsubF(:),'omitnan');
            IsdF = std(IsubF(:),[],'omitnan');
            
            % calculates the residual tolerance
            IsubMx = cellfun(@(x)(max(cell2mat(cellfun(@(y)(y(x,iCT)),...
                            Isub(:)','un',0)),[],1,'omitnan')),iRT,'un',0);
            YRngF = cell2cell(cellfun(@(x)(x),IsubMx,'un',0),0);            
            YBLF = max(1,imopen(YRngF(:),ones(nOpen,1)));                        
            pTol = obj.calcResidualTol(max(1,YRngF),YBLF);
            
            % reduces the proportional difference array for each subregion         
            Q = reshape(YRngF,[length(IsubMx{1}),length(iRTL)]);
            if exist('B0','var'); Q(~B0,:) = 0; end
            
            % calculates the movement status flags:
            %  = 0: blob is completely stationary over the phase
            %  = 2: blob has moved a significant distance              
            mFlag(any(Q > pTol,1)) = 2;
            
        end
        
        % --- upsamples the image coordinates
        function fP = upsampleImageCoords(obj,I,fP0)
        
            % memory allocation 
            nImg = length(I);
            fP = NaN(nImg,2);
            [W,szL] = deal(2*obj.nI,size(I{1}));            
            fPT = 1 + obj.nI*(1 + 2*(fP0-1));
            isOK = ~isnan(fP0(:,1));    
        
            % determines the coordinates from the refined image
            for i = find(isOK(:)')
                % sets up the sub-image surrounding the point
                iRP = max(1,fPT(i,2)-W):min(szL(1),fPT(i,2)+W);
                iCP = max(1,fPT(i,1)-W):min(szL(2),fPT(i,1)+W); 
                
                % retrieves the coordinates of the maxima
                pMaxP = getMaxCoord(I{i}(iRP,iCP));
                fP(i,:) = (pMaxP-1) + [iCP(1),iRP(1)];
            end            
            
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
            
            % returns the row indices for the given sub-region
            if exist('iTube','var')
                iRT = iRT{iTube};
            end
            
        end        
        
        % --- sets up the blob template images
        function setupBlobTemplate(obj,I,iPh)
            
            % if the user cancelled, then exit
            if ~obj.calcOK; return; end                           
            
            % parameters
            pS = 1.5;            
            
            % memory allocation 
            fP = obj.fPosL{iPh};
            nApp = size(fP,1);
            obj.useP = zeros(max(obj.nTube),nApp);

            % if only one frame, then exit
            if length(I) == 1
                obj.sFlag{iPh} = ones(size(obj.useP));
                obj.sFlag{iPh}(~obj.iMov.flyok) = 0;    
                return
            end
            
            % updates the progressbar
            wStrNw = 'Object Template Calculations';
            obj.hProg.Update(2+obj.wOfsL,wStrNw,0.50);
            obj.hProg.Update(3+obj.wOfsL,'Analysing Region',0);            
            
            % calculates the residual z-scores
            pPR = obj.pStats.IR(:,iPh);
            
            % -------------------------------- %
            % --- FLY TEMPLATE CALCULATION --- %
            % -------------------------------- %            
            
            % memory allocation
            ok = obj.iMov.ok;
            pFilt = cell(nApp,1);
            Zflag = NaN(max(cellfun(@length,obj.mFlag)),nApp);
            
            % retrieves the movement flags (for each sub-region) and
            % determines which have some sort of movement
            Zflag(:,ok) = combineNumericCells(obj.mFlag(ok)');
            obj.useP = (Zflag == 2);
            
            % determines if a majority of the residual pixel intensities
            % meets the tolerance (for each sub-region) across all frames
            pSig = combineNumericCells(cellfun(@(x,y)(mean(x>y,2)),...
                                pPR,num2cell(obj.pTolF(:,iPh)),'un',0)');
            pvSig = combineNumericCells(cellfun(@(x,y)(mean(x>pS*y,2)),...
                                pPR,num2cell(obj.pTolF(:,iPh)),'un',0)');                            
            isSig = zeros(size(pvSig,1),length(obj.iMov.ok));
            isSig(:,obj.iMov.ok) = (pSig >= obj.pSigMin) | (pvSig > 0);
            
            % calculates the distance range (fills in any missing phases
            % with NaN values)
            DrngC0 = cellfun(@(x)(calcImageStackFcn...
                        (x,'range')),num2cell(obj.fPosL{iPh},2),'un',0); 
            DrngC0(cellfun(@isempty,DrngC0)) = {NaN(1,2)};                    
            
            % calculates the range of each fly over all phases
            if obj.is2D
                DrngC = cellfun(@(x)(sqrt(sum(x.^2,2))),DrngC0,'un',0);
            else
                DrngC = cellfun(@(x)(x(:,1)),DrngC0,'un',0);               
            end                       
                
            % if the blob filter has been calculated, then exit
            Drng = combineNumericCells(DrngC(:)');
            if ~isempty(obj.hFilt)
                % determines the blobs that haven't moved far over the phase
                obj.setStatusFlag(Zflag,Drng,isSig,iPh);
                return
            end
                                    
            % determines which sub-images to use for the template   
            for i = find(obj.iMov.ok(:)')
                % updates the progress bar
                wStrNw = sprintf('Analysing Region (%i of %i)',i,nApp);
                if obj.hProg.Update(3+obj.wOfsL,wStrNw,i/(1+nApp))
                    obj.calcOK = false;
                    return
                end                      
                
                % sets up the image stack for template analysis
                [obj.Iss{i,iPh},obj.dIss{i,iPh},d2I] = ...
                                    obj.setupStatObjStack(I(:,i),iPh,i);
                
                % calculates the optimal blob filter parameters
                pFilt{i} = obj.optBlobFilter(d2I{1},iPh,i,1);                                 
            end
            
            % creates the object filter
            pFiltTot = median(cell2mat(pFilt),1,'omitnan');
            pFiltTot(1) = 2*floor(pFiltTot(1)/2)+1;            
            obj.hFilt = -fspecial('log',pFiltTot(1),pFiltTot(2));
            
            % determines the shape size of the blob object
            Brmv = bwmorph(obj.hFilt > 0,'dilate',1);
            [~,pBB] = getGroupIndex(Brmv,'BoundingBox');
            obj.iMov.szObj = pBB(3:4);       
            
            % determines the blobs that haven't moved far over the phase
            obj.setStatusFlag(Zflag,Drng,isSig,iPh);           
            
            % updates the progressbar
            obj.hProg.Update(3+obj.wOfsL,'Region Analysis Complete',1);            
            
        end                             
        
        % --- estimates the missing region in the background image
        function IbgLmn = estSubRegionBG(obj,I,fP)
                   
            % memory allocation
            sz = size(I{1});
            szF = size(obj.hFilt);
            xiN = (1:szF) - floor((szF(1)-1)/2+1);  
            Brmv = bwmorph(obj.hFilt > 0,'dilate',1+obj.nI);

            % fill in the regions surrounding the points
            for i = 1:length(I)
                % sets up the image weighting array
                [iR,iC] = deal(fP(i,2)+xiN,fP(i,1)+xiN);
                ii = (iR > 0) & (iR < sz(1));
                jj = (iC > 0) & (iC < sz(2));
                
                % removes the region containing the blob
                ITmp = I{i}(iR(ii),iC(jj));
                ITmp(Brmv(ii,jj)) = NaN;
                I{i}(iR(ii),iC(jj)) = ITmp;
            end
            
            % calculates the average (interpolating missing points)
            Brmv = calcImageStackFcn(I,'isnan');
            IbgL0 = calcImageStackFcn(I,'median');
            IbgL0(Brmv) = NaN;
            
            % calculates the background image estimate (based on type)
            if obj.iMov.is2D
                % case is 2D open field expt
                IbgLmn = (interpImageGaps(IbgL0,1) + ...
                          interpImageGaps(IbgL0,2))/2;
            else
                % case is 1D grid based expt
                IbgLmn = interpImageGaps(IbgL0);
            end
            
        end        
            
        % --- performs the phase house-keeping
        function phaseHouseKeeping(obj,iPh)
            
            % updates the progressbar
            obj.hProg.Update(2+obj.wOfsL,'Phase Tracking Complete',1); 
            obj.hProg.Update(3+obj.wOfsL,'Performing House-Keeping',0); 
            
            % sets the background images
            [iR,iC] = deal(obj.iMov.iR,obj.iMov.iC);
            obj.Ibg{iPh} = cellfun(@(x,y)...
                                (obj.IbgT{iPh}(x,y)),iR,iC,'un',0);
            obj.Ibg0{iPh} = cellfun(@(x,y)...
                                (obj.IbgT0{iPh}(x,y)),iR,iC,'un',0);               
            
            % updates the progressbar
            obj.hProg.Update(3+obj.wOfsL,'House-Keeping Complete',1);
            
        end                      
        
        % ---------------------------------- %
        % --- IMAGE PROCESSING FUNCTIONS --- %
        % ---------------------------------- %           
        
        % --- retrieves the region sub-region row indices
        function [iRT,dP] = getSRRowIndices(obj,iApp,iTube)
            
            % field retrieval and memory allocation            
            if exist('iTube','var')
                iRT = obj.iMov.iRT{iApp}{iTube};     
            else
                iRT = obj.iMov.iR{iApp} - obj.iMov.iR{iApp}(1); 
            end
            
            % sets the total row index count
            dP = zeros(1,2);
            nRT = length(obj.iMov.iR{iApp});
            
            % sets the sub-region indices for the sub-region
            if obj.nI > 0
                % sets the down-sampled index array
                indR = 1:nRT;
                indR = indR((obj.nI+1):2*obj.nI:end);
                nRT = length(indR);
                
                % sets the reduce indices
                iRTM = iRT(arrayfun(@(x)(any(indR==x)),iRT));
                nR = sum(arrayfun(@(x)(any(indR==x)),iRT));
                iRT = (find(indR==iRTM(1))-1) + (1:nR); 
            end   
            
            % expands the row indices (if being tracked)
            if nargout == 2
                if iRT(1) > 1
                    [iRT,dP(1)] = deal([(iRT(1)-1),iRT],1); 
                end

                if iRT(end) < nRT 
                    [iRT,dP(2)] = deal([iRT,(iRT(end)+1)],1);
                end
            end
            
        end
        
        % --- downsamples the image stack
        function I = downSampleImgStack(obj,I)
           
            % retrieves the full image size
            if iscell(I)
                % case is an image stack is input
                sz = size(I{1});
            else
                % case is the simple image is input
                sz = size(I);
            end
            
            % sets the reduced row/column indices
            iC = (obj.nI+1):(2*obj.nI):sz(2);
            iR = (obj.nI+1):(2*obj.nI):sz(1); 

            % reduces the image stack
            if iscell(I)
                I = cellfun(@(x)(x(iR,iC)),I,'un',0);
            else
                I = I(iR,iC);
            end
            
        end
        
        % --- sets up the image stack for the template analysis
        function [I,dI,d2I] = setupStatObjStack(obj,I,iPh,iApp)
            
            % retrieves the fluctuation/translation flags
            [hasF,hasT] = deal(obj.getFlucFlag,obj.getTransFlag(iApp));
            I(~obj.okFrm) = {zeros(size(I{1}))};
            
            % if the region has significant translation, and the image
            % fluctuations hasn't been accounted for, then apply the
            % homomorphic transform to the image stack  
            needsCorrect = ~(hasF || obj.isHiV);
            if ~needsCorrect && hasT                
                if ~obj.iMov.is2D
                    [I0,I] = deal(I,cell(length(I),1));
                    [I{1},H] = applyHMFilter(I0{1});
                    I(2:end) = cellfun(@(x)...
                                (applyHMFilter(x,H)),I0(2:end),'un',0);
                            
                    % clears the original array
                    clear I0                            
                end

                % convert and scales the resulting images
                I = cellfun(@(x)(255*(x-min(x(:),[],'omitnan'))),I,'un',0);
                I = cellfun(@(x)(x-median(x(:),'omitnan')),I,'un',0);                
            end         
            
            % applies the exclusion mask
            szI = size(I{1});
            Bw = bwmorph(getExclusionBin(obj.iMov,szI,iApp),'dilate');
            if hasT                                
                % calculates the x/y coordinate translation
                phInfo = obj.iMov.phInfo;
                [p,iFrm] = deal(phInfo.pOfs{iApp},obj.indFrm{iPh});
                pOfsT = interp1(phInfo.iFrm0,p,iFrm,'linear','extrap');
                
                % applies the image translation                
                Bw = cellfun(@(p)(obj.applyImgTrans(Bw,p)),...
                                            num2cell(pOfsT,2),'un',0);
            else
                % otherwise, covert the array to a cell aray
                Bw = repmat({Bw},length(I),1);
            end
            
            % downsamples the images (if high frame resolution)
            if obj.nI > 0
                I = obj.downSampleImgStack(I);
                Bw = obj.downSampleImgStack(Bw);
            end

            % sets up the median filtered residual estimate image stack
            if nargout == 2
                dI = setupResidualEstStack(I,obj.mdDim);                                 
            else
                [dI,d2I] = setupResidualEstStack(I,obj.mdDim);  
                d2I = cellfun(@(x,b)(b.*x),d2I,Bw,'un',0);
            end
            
            % fills in any rejected regions
            for i = 1:length(Bw)
                I{i}(~Bw{i}) = median(I{i}(Bw{i}),'omitnan');
            end
            
            % applies the exclusion filter
            dI = cellfun(@(x,b)(b.*x),dI,Bw,'un',0);
            
        end                                               
        
        % ------------------------- %
        % --- TESTING FUNCTIONS --- %
        % ------------------------- %

        % --- plots the image frame coordinates
        function plotImageFrame(obj,Img,iPh,iFrm)

            % retrieves the frame coordinates
            if obj.isAutoDetect
                fP = obj.fPos0{iPh}(:,iFrm);
            else
                fP = obj.fPosL{iPh}(:,iFrm);
            end

            % creates the image figure
            plotGraph('image',Img{iFrm})
            hold on

            % plots the locations for all objects in the region
            for i = find(obj.iMov.ok(:)')
                % sets the row/column indices
                [iR,iC] = deal(obj.iMov.iR{i},obj.iMov.iC{i});
                iRT = obj.iMov.iRT{i};

                % plots the location of all the points
                pOfs = [iC(1),iR(1)]-1;
                for j = 1:size(fP{i},1)
                    yOfs = (iRT{j}(1)-1)*(~obj.isAutoDetect);
                    plot(fP{i}(j,1)+pOfs(1),fP{i}(j,2)+(pOfs(2)+yOfs),...
                                'go','markersize',12)
                end
            end

        end                
        
        % --- plots the 
        function plotSubRegionPos(obj,iApp,varargin)
            
            % deletes any previous figures
            hFigPr = findall(0,'tag','hPlotReg');
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % field initialisations
            obj.nFrmP = length(obj.indFrm{1});            
            [obj.iAppP,obj.iFrmP,obj.iPhP] = deal(iApp,1,1); 
            [obj.hMarkAm,obj.hMarkF] = deal([]);  
            obj.showAm = isempty(varargin);
            
            % creates the plot figure
            obj.hFigP = plotGraph('image',obj.getPlotImageSR());
            set(obj.hFigP,'tag','hPlotReg',...
                        'WindowKeyPressFcn',@obj.figKeyPress);
            obj.hTitleP = title(sprintf...
                        ('Frame %i of %i (Phase #1)',1,obj.nFrmP));
                      
            % sets the axis properties
            obj.hAxP = gca;
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
                    if obj.iFrmP == obj.nFrmP
                        return
                    else
                        obj.iFrmP = obj.iFrmP + 1;
                    end                    
                    
                case 'downarrow'
                    % case is the right arrow key
                    if obj.iPhP == 1
                        return
                    else
                        obj.iPhP = obj.iPhP - 1;
                        obj.nFrmP = length(obj.indFrm{obj.iPhP});
                        obj.iFrmP = min(obj.iFrmP,obj.nFrmP);                        
                    end                    
                    
                case 'uparrow'
                    % case is the right arrow key
                    if obj.iPhP == obj.nPhase
                        return
                    else
                        obj.iPhP = obj.iPhP + 1;
                        obj.nFrmP = length(obj.indFrm{obj.iPhP});
                        obj.iFrmP = min(obj.iFrmP,obj.nFrmP);
                    end                    
                    
                otherwise
                    % case is another key
                    return
                
            end            

            % updates the figure
            Inw = obj.getPlotImageSR();
            set(findall(obj.hAxP,'Type','Image'),'CData',Inw)            
            
            % updates the title
            nwTitle = sprintf('Frame %i of %i (Phase #%i)',...
                                    obj.iFrmP,obj.nFrmP,obj.iPhP);
            set(obj.hTitleP,'string',nwTitle);  
            
            % updates the frame markers
            obj.updateFrameMarkers();            
            
        end                        
        
        % --- updates the frame markers
        function updateFrameMarkers(obj)
            
            % plots the final position markers
            fPosT = obj.fPosL{obj.iPhP}{obj.iAppP,obj.iFrmP};
            if ~isempty(fPosT)   
                yOfs = cellfun(@(x)(x(1)),obj.iMov.iRT{obj.iAppP})-1;
                yPosT = fPosT(:,2) + yOfs;
                
                if isempty(obj.hMarkF)
                    obj.hMarkF = plot(obj.hAxP,fPosT(:,1),yPosT,'go',...
                                        'LineWidth',2,'MarkerSize',12);
                else
                    set(obj.hMarkF,'xdata',fPosT(:,1),'ydata',yPosT);
                end
            end   
            
            % exits the function if not showing the other peaks
            if ~obj.showAm; return; end
            
            % plots the final position markers
            fPosPT0 = obj.fPosP{obj.iPhP,obj.iAppP}(obj.iFrmP,:)';                        
            yOfs = cellfun(@(x)(x(1)),obj.iMov.iRT{obj.iAppP})-1;
            fPosPT = cell2mat(cellfun(@(x,y)(obj.frObj.offsetYCoords...
                            (x,y)),fPosPT0,num2cell(yOfs),'un',0));
            
            if ~isempty(fPosPT)   
                if isempty(obj.hMarkAm)
                    obj.hMarkAm = plot(obj.hAxP,fPosPT(:,1),fPosPT(:,2),'r.');
                else
                    set(obj.hMarkAm,'Visible','on','xdata',fPosPT(:,1),...
                                    'ydata',fPosPT(:,2));
                end                
                
            elseif ~isempty(obj.hMarkAm)
                setObjVisibility(obj.hMarkAm,0);
            end              
            
        end
        
        % --- retrieves the sub-region plot image
        function ImgP = getPlotImageSR(obj)
        
            iR = obj.iMov.iR{obj.iAppP};
            iC = obj.iMov.iC{obj.iAppP};            
            ImgP = obj.Img{obj.iPhP}{obj.iFrmP}(iR,iC);
            
        end
            
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %    
        
        % --- sets the sub-region coordinates
        function setSubRegionCoord(obj,fPosNw,indG)

            % initialisations
            [iPh,iApp,iTube] = deal(indG(1),indG(2),indG(3));

            % sets the position values into the overall array
            for iFrm = 1:size(fPosNw,1)
                obj.fPosL{iPh}{iApp,iFrm}(iTube,:) = fPosNw(iFrm,:);
            end

        end         
        
        % --- calculates the global coords from the sub-region reference
        function calcGlobalCoords(obj,iPh)
            
            % exit if not calculating the background
            if ~obj.calcOK; return; end
            
            % retrieves the frame count
            [~,nFrm] = size(obj.fPosL{iPh});
                
            % memory allocation
            nTube = getSRCountVec(obj.iMov);
            [obj.fPosG{iPh},obj.fPos{iPh}] = deal(repmat(...
                        arrayfun(@(x)(NaN(x,2)),nTube,'un',0),1,nFrm));
            
            % converts the coordinates from the sub-region to global coords
            for iApp = find(obj.iMov.ok(:)')
                % calculates the x/y offset of the sub-region
                xOfs = obj.iMov.iC{iApp}(1)-1;
                yOfs = obj.iMov.iR{iApp}(1)-1;
                y0 = cellfun(@(x)(x(1)),obj.iMov.iRT{iApp})-1;
                pOfsL = [zeros(nTube(iApp),1),y0(:)];
                
                % calculates the global offset and appends it to each frame
                pOfs = repmat([xOfs,yOfs],nTube(iApp),1);
                for iFrm = 1:nFrm
                    % calculates the sub-region/global coordinates
                    obj.fPos{iPh}{iApp,iFrm} = ...
                                obj.fPosL{iPh}{iApp,iFrm} + pOfsL;
                    obj.fPosG{iPh}{iApp,iFrm} = ...
                                obj.fPos{iPh}{iApp,iFrm} + pOfs;
                end
            end
            
        end        
        
        % --- calculates the overall quality values
        function calcOverallQuality(obj)
            
            % memory allocation
            nApp = length(obj.iMov.iR);
            nMet = length(fieldnames(obj.pStats));
            nTube = num2cell(arr2vec(getSRCount(obj.iMov)'))';
            [tData,obj.pData] = deal(cell(nMet,1));
            bgP = getTrackingPara(obj.iMov.bgP,'pSingle');
            wStr0 = {'Tracking Quality Calculations','Analysing Frame'};
            
            % resets the progressbar level count
            obj.hProg.setLevelCount(2);            
            
            % resets the waitbar figure
            for i = 1:length(wStr0)
                obj.hProg.Update(1,wStr0{i},0);
            end            
            
            % sets up the image filter object
            if bgP.useFilt
                obj.hS = fspecial('disk',bgP.hSz); 
            else
                obj.hS = [];
            end
            
            % sets the residual/intensity values
            tData{1} = obj.pStats.IR;
            tData{2} = obj.pStats.IRmd;             
            
            % sets the data values for each of the phases
            for iPh = 1:obj.nPhase
                % updates the progressbar
                wStr = sprintf('%s (%i of %i)',wStr0{1},iPh,obj.nPhase);
                if obj.hProg.Update(1,wStr,iPh/obj.nPhase)
                    % if the user cancelled, then exit
                    obj.calcOK = false;
                    return
                else
                    wStr2 = sprintf('%s (Initialising...)',wStr0{2});
                    obj.hProg.Update(2,wStr2,0);
                end
                
                % determines if there are any missing data values                                        
                iFrm = obj.indFrm{iPh};
                isHV = obj.iMov.vPhase(iPh) > 1;
                nPhase = length(obj.iMov.vPhase);
                fok = repmat(cellfun(@(x,n)(x(1:n)),num2cell...
                            (obj.iMov.flyok,1),nTube,'un',0),nPhase,1)';
                                
                % determines if there are any missing residual image stacks
                % for any region (in the current phase)
                rReqd = ~cellfun(@isempty,obj.Iss(:,iPh)) & obj.iMov.ok(:);
                if any(rReqd)
                    % retrieves the image stack
                    if obj.isCalib
                        I = obj.Img0{1};
                    else
                        I = arrayfun(@(x)(double(getDispImage...
                                (obj.iData,obj.iMov,x,0))),iFrm,'un',0); 
                    end     
                            
                    if ~isempty(obj.hS)
                        % applies the smoothing filter (if required)
                        I = cellfun(@(x)(imfiltersym(x,obj.hS)),I,'un',0); 
                    end
                    
                    % sets up the residual estimate image stacks
                    for iApp = find(rReqd(:)')
                        % retrieves the region image stack
                        IL = obj.getRegionImageStack(I,iFrm,iApp,isHV);
                        [obj.Iss{iApp,iPh},obj.dIss{iApp,iPh}] = ...
                                        obj.setupStatObjStack(IL,iPh,iApp);
                    end
                end
                                
                % determines the frames that need recalculation                
                if obj.iMov.vPhase(iPh) < 3
                    for j = find(obj.iMov.ok(:)')
                        % updates the progressbar
                        wStr = sprintf('%s (%i of %i)',wStr0{2},j,nApp);
                        if obj.hProg.Update(2,wStr,j/nApp)
                            % if the user cancelled, then exit
                            obj.calcOK = false;
                            return
                        end             

                        % calculates the cross-correlation images (for all
                        % frames for the current region)
                        IxcL = obj.dIss{j,iPh};
                           
                        % sets the point cross-correlation values at each 
                        % of the calculated coordinates
                        for i = 1:length(IxcL)                    
                            % sets the coordinate of the blobs
                            fPL = roundP(obj.fPos{iPh}{j,i});
                            if obj.nI > 0
                                % downscales the coordinates (if required)
                                fPL = obj.downsampleImageCoords(fPL,obj.nI);
                            end
                            
                            % retrieves the pixel values
                            tData{2}{j,iPh}(:,i) = ...
                                        obj.getPixelValue(IxcL{i},fPL);
                        end
                    end
                end
                
                % calculates the metric z-score probabilities
                for i = 1:nMet
                    % calculates the phase metrics mean/std values
                    Ytot = cell2mat(cellfun(@(x,i)(x(i,:)),...
                                            tData{i},fok,'un',0));
                    Ymn = mean(Ytot(:),'omitnan');
                    Ysd = std(Ytot(:),[],'omitnan');
                    
                    % sets the probability values
                    for j = 1:size(tData{i},1)
                        pDataNw = normcdf(tData{i}{j,iPh},Ymn,Ysd);
                        if i == 3
                            obj.pData{i}{j,iPh} = 100*(1-pDataNw);
                        else
                            obj.pData{i}{j,iPh} = 100*pDataNw;
                        end
                    end
                end
            end
            
            % updates the values within the base object
            obj.pStats.IRmd = tData{2};             
            
            % pixel tolerances            
            isAnom = false(size(obj.iMov.flyok)); 
            Qval = zeros(size(obj.iMov.flyok)); 
            
            % determines which sub-region appear to be empty
            for i = 1:size(obj.pData{1},1)
                % groups the metrics and calculates the max/median
                A = cellfun(@(y)(cell2mat(y(i,:))),obj.pData,'un',0)';
                Amd = cell2mat(cellfun(@(x)...
                                    (median(x,2,'omitnan')),A,'un',0));
                
                % determines which objects have low overall scores
                nT = size(Amd,1);
                [xiT,isOK] = deal(1:nT,~isnan(Amd(:,1)));
                isAnom(xiT(isOK),i) = all(Amd(isOK,:) < obj.pTolQ,2);
                isAnom(xiT(~isOK),i) = (Amd(~isOK,2) < obj.pTolQ);

                % calculates the average quality value
                Qval(xiT,i) = mean([Amd(:,1),Amd(:,2)],2,'omitnan');
            end
            
            % determines if there are any NaN quality values
            isNQ = isnan(Qval);
            if any(isNQ(:))
                % if so, then flag these sub-regions as being anomalous
                % while resetting the quality value
                isAnom(isNQ & obj.iMov.flyok) = true;
                Qval(isNQ) = 0;
            end
                
            % if there are potentially empty regions (and not batch
            % processing) then show the EmptyRegion gui
            if any(isAnom(:)) && ~obj.isBatch
                % closes the progressbar
                obj.hProg.setVisibility('off');
                
                % outputs a message string to the user
                eStr = sprintf(['One or more anomalous or empty regions ',...
                                'have been detected.\nYou will need to ',...
                                'manually accept/reject these regions.']);
                waitfor(msgbox(eStr,'Anomalous Regions Detected','modal'))
                
                % if so, prompt the user if they should exclude those
                % regions from the analysis
                eObj = EmptyCheck(obj.fPosG,roundP(Qval,0.1),isAnom);                
                
                % resets the status flags for all flagged sub-regions
                for i = find(eObj.isEmpty(:)')
                    % sets the region/sub-region indices
                    [iApp,iTube] = deal(eObj.iApp(i),eObj.iTube(i));
                    
                    % updates the status flags
                    obj.iMov.flyok(iTube,iApp) = false;
                    
                    % if all sub-regions are rejected, then reject the
                    % whole region 
                    if ~any(obj.iMov.flyok(:,iApp))
                        obj.iMov.ok(iApp) = false;
                    end                    
                end                
                
            end
            
        end      
        
        % --- sets up the weighted template image
        function Itemp = setupWeightedTemplateImage(obj)
            
            % determines the low variance phases
            isLoV = (obj.iMov.vPhase == 1) & ~cellfun(@isempty,obj.tPara);
            
            % calculates a weighted sum of the existing templates
            N = cellfun(@length,obj.indFrm(isLoV));
            Itemp0 = cellfun(@(x)(x.Itemp),obj.tPara(isLoV),'un',0);
            Itemp = calcImageStackFcn(Itemp0,'weighted-sum',N/sum(N));            
            
        end
        
        % --- get the pixel values the coordinates, fP
        function IP = getPixelValue(obj,I,fP,isMax)
            
            % sets the default input arguments
            if ~exist('isMax','var'); isMax = true; end           
            
            % sets the neighbourhood size
            if ~isfield(obj.iMov,'szObj') || any(isnan(obj.iMov.szObj))
                N = 5;
            else
                N = max(2,min(floor(obj.iMov.szObj/(2*(1+obj.nI)))));
            end
            
            % memory allocation
            isOK = ~isnan(fP(:,1));            
            IsubS = cellfun(@(x)(obj.getPointSubImage(I,x,N)),...
                                            num2cell(fP(isOK,:),2),'un',0);
            
            % determines the min/max values surrounding the point
            IP = NaN(size(fP,1),1);
            if isMax
                IP(isOK) = cellfun(@(x)(max(x(:),[],'omitnan')),IsubS);
            else
                IP(isOK) = cellfun(@(x)(min(x(:),[],'omitnan')),IsubS);
            end
        end                  
        
    end    
    
    % class static methods
    methods (Static)
                
        % --- retrieves the comparison phase index
        function [iPhC,iDir] = getCompPhaseIndex(isF,iPh)
            
            % calculates the distance to the known phases
            [~,iMax] = bwdist(isF);
            
            % sets the comparison phase and direction
            iPhC = double(iMax(iPh));
            iDir = 1 - 2*(iPhC < iPh);
                
        end        
    
        % --- determines the phase search indices
        function indS = getPhaseSearchIndices(isF,okPh)
            
            % initialisations
            DM = bwdist(isF);
            indS0 = find(~isF & okPh);
            
            % determines the closest phase (which is known)
            [~,iS] = sort(DM(indS0));
            indS = arr2vec(indS0(iS))';            
            
        end            
        
        % --- calculates the optimal gaussian para for the signal, II
        function [sD,ff] = optGaussSignal(II)
            
            % initialisations
            N = (length(II)-1)/2;
            gaussEqn = 'A*exp(-(x/sd)^2)';            
            xi = -N:N;
            
            % fits the gaussian equation and returns the std-dev
            ff = fit(xi(:),II(:),gaussEqn,'Start',[max(II(:)),1]);
            sD = ff.sd;
            
        end        
        
        % ----------------------- %
        % --- OLDER FUNCTIONS --- %
        % ----------------------- %
        
        % --- calculates the object function for the given parameters
        function F = objFunc(I,hSz,hSig,fP)

            % sets up the cross-correlation image
            h = fspecial('log',hSz,hSig);
            Ixc = max(0,calcXCorr(-h,I)); 
            
            % determines the distance of the major peaks to the previous
            % coordinate vector, fP
            [yM,xM] = find(imregionalmax(Ixc));
            D = pdist2([xM,yM],fP);

            % determines the index of the peak that is closest
            [~,imn] = min(D,[],1);
            iM = sub2ind(size(I),yM(imn),xM(imn));

            % returns the objective function value surrounding the maxima
            iM = bwmorph(setGroup(iM,size(I)),'thicken');
            F = mean(nonzeros(Ixc(iM)),'omitnan');

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
        
        % --- downsamples the image coordinates
        function fP = downsampleImageCoords(fP0,nI)
            
            fP = roundP(((fP0-1)/nI - 1)/2 + 1);
            
        end  
        
        % --- calculates the residual tolerance from the range signal
        function pTol = calcResidualTol(YRng0,YBL)

            % parameters
            pW = 1.2;
            dTol = 0.075;
            d2Tol = 0.005;
            pMuTol = 0.5;

            % determines the peaks from the signal
            dRng = YRng0(:) - YBL(:);
            dRngN = dRng/max(dRng);
            [yP,tP,~,pP] = findpeaks(dRngN);

            % clusters these groups using the DBSCAN clustering algorithm
            QP = max(0,[yP,pP]);
            
            % determines the initial search neighbourhood size
            while 1
                % calculates the 2D histogram count. from this, determine
                % the binary grouping that contains the origin point
                N = histcounts2(QP(:,1),QP(:,2),roundP(1/dTol))';
                [~,BN] = detGroupOverlap(N > 0,setGroup([1,1],size(N)));                
                if mean(diag(BN)) > pMuTol
                    % if the neighbourhood size is too large then reduce it
                    dTol = dTol - d2Tol;
                else
                    % otherwise, exit the loop
                    break
                end
            end
            
            % runs the clustering algorithm
            jdx = DBSCAN(QP,dTol,1);

            % determines the cluster most like to represent the baseline peaks
            iGrp = arrayfun(@(x)(find(jdx==x)),(1:max(jdx))','un',0);
            RGrp = cellfun(@(x)(sum(mean(QP(x,:),1,'omitnan').^2)),iGrp);
            iMin = argMin(RGrp);

            % sets the indices of the peaks that are significant. from 
            % these peaks determines the threhold tolerance
            iSig = sort(cell2mat(iGrp(~setGroup(iMin,size(iGrp)))));
            pTol0 = [max(YRng0(tP(iGrp{iMin}))),min(YRng0(tP(iSig)))];
            pTol = pW*mean(pTol0);
            
        end
        
        % --- determines the frame feasibility
        function okFrm = checkFrameFeas(IL)
            
            % ensures the images are stored in a cell array
            if ~iscell(IL); IL = {IL}; end
            
            % determines which frames are feasible (no NaN frames)
            N = 10;
            okFrm = ~cellfun(@(x)(all(isnan(arr2vec(x(1:N,1:N))))),IL);
            
        end        
        
    end
end
