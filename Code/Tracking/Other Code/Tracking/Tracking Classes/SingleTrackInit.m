classdef SingleTrackInit < SingleTrack
    
    % class properties
    properties
        
        % main field objects
        infoObj
        frObj
        
        % image array fields
        Img
        Img0
        Ibg
        Ibg0
        IbgT
        IbgR
        IbgT0
        Iss
        dIss
        
        % object positional coordinate arrays
        fPos
        fPos0
        fPosL
        fPosG
        fPosAm
        fPosP
        yPosP
        IPos
        
        % movement status flag arrays
        mFlag
        sFlag
        sFlagT
        sFlagMax
        
        % quality metric fields
        hCQ
        pStats
        pStatsF
        Is
        
        % other important fields
        nI
        i0
        pQ0
        iOK
        tPara
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
        isSpecial
        usePTol
        pWofs = 4;
        nMet = 3;
        pTolQ = 5;
        pTolMin = 5;
        pSigMin = 0.5;
        nOpenRng = 15;
        nFrmMin = 10;
        dyRngMin = 10;
        pTolSz = 0.05;
        mdDim = 30*[1,1];
        pLim = [5,3,0.85];
        hSR = fspecial('disk',2);
        
    end
    
    % class methods
    methods
        
        % --- class constructor
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
            okPh = obj.getFeasPhase();
            
            % sets the status flags for each phase (full and overall)
            sFlag0 = cellfun(@(x)(3-x),obj.sFlag,'un',0);
            obj.iMov.StatusF = sFlag0;
            
            % calculates the distance each blob travels over the video
            fPT = num2cell(cell2cell(obj.fPosL(okPh)',0),2);
            fPmn = cellfun(@(x)(calcImageStackFcn(x,'min')),fPT,'un',0);
            fPmx = cellfun(@(x)(calcImageStackFcn(x,'max')),fPT,'un',0);
            DfPC = cellfun(@(x,y)(sum((y-x).^2,2).^0.5),fPmn,fPmx,'un',0);
            
            % sets up the distance array.
            DfP = NaN(max(cellfun('length',DfPC)),length(obj.iMov.ok));
            DfP(:,obj.iMov.ok) = combineNumericCells(DfPC(obj.iMov.ok)');
            
            % determines which regions are potentially empty
            ii = ~cellfun('isempty',obj.iMov.StatusF);
            if any(ii)
                % sets the status flag array. any blobs which have been
                % flagged as non-moving, but actually has moved appreciably
                % over the video, is reset to moving
                Status = calcImageStackFcn(obj.iMov.StatusF(ii),'min');
                Status((Status==2) & (DfP > 1.5*obj.iMov.szObj(1))) = 1;
                
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
            
            % calculates the residual/position distribution parameters
            if obj.isSpecial && ~obj.isBatch
                obj.calcResidualProfilePara();
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
            obj.nI = getImageInterpRate();
            obj.frObj = FilterResObj(obj.iMov,obj.hProg,obj.wOfsL);
            obj.frObj.isBatch = obj.isBatch;
            
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
        
        % --- calculates the residual/position distribution parameters
        function calcResidualProfilePara(obj)
            
            % memory allocation
            obj.iMov.pB = cell(obj.nApp,1);
            
%             figure;
            
            %
            for iApp = find(obj.iMov.ok(:)')
                % determines the moving objects
                isM = obj.iMov.Status{iApp} == 1;
                
                % retrieves the position/residuals of the moving objects
                [fP0,IP0] = deal(obj.fPos{1}(iApp,:),obj.IPos{1}(iApp,:));                
                fP = cell2mat(cellfun(@(x)(x(isM,:)),fP0(:),'un',0)); 
                IP = cell2mat(cellfun(@(x)(x(isM,:)),IP0(:),'un',0)); 
                
                % retrieves the unique coordinates (calculating the mean
                % residual values for each unique coordinate)
                [X,~,iC] = unique(fP(:,1));                 
                Y = arrayfun(@(x)(mean(IP(iC==x))),1:max(iC));
                
                %                
                XX = [0;X(:);length(obj.iMov.iC{iApp})];
                obj.iMov.pB{iApp} = fitBimodalBoltz(XX,[0;Y(:);0]);
                
%                 subplot(2,1,iApp); hold on;
%                 plot(X,Y,'g.');
%                 plot(XX,calcBimodalBoltz(obj.iMov.pB{iApp},XX));
            end
            
        end        
        
        % ----------------------------------------- %
        % --- INITIAL OBJECT ESTIMATE FUNCTIONS --- %
        % ----------------------------------------- %
        
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
                nFrmRF = obj.nFrmR*(1 + (obj.iMov.vPhase(1) == 4));
                obj.indFrm = getPhaseFrameIndices(obj.iMov,nFrmRF);
                
                % memory allocation
                wStr0 = 'Initial Frame Stack Read';
                obj.Img = cell(nPh,1);
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
                    [obj.Img{i},obj.indFrm{i}] = ...
                        obj.getImageStack(obj.indFrm{i});
                    obj.iMov.iPhase(i,:) = obj.indFrm{i}([1,end]);
                    
                    % applies the smooth filter (if specified)
                    if obj.useFilt && ~isempty(obj.Img{i})
                        obj.Img{i} = cellfun(@(x)(imfiltersym...
                            (x,obj.hS)),obj.Img{i},'un',0);
                    end
                end
            end
            
            % updates the progress-bar
            obj.hProg.Update(3+obj.wOfsL,'Frame Read Complete',1);
            
        end
        
        % --- initialises the class fields before detection
        function initDetectFields(obj)
            
            % if the user has cancelled, then exit
            if ~obj.calcOK; return; end
            
            % array dimensioning
            nPh = length(obj.Img);
            nT = getSRCountVec(obj.iMov);
            nApp = numel(nT);
            obj.isSpecial = obj.iMov.vPhase(1) == 4;            
            
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
            B = cell(nPh,nApp);
            [obj.fPosP,obj.mFlag,obj.sFlagT,obj.pStatsF,obj.Is] = deal(B);
            [obj.Iss,obj.dIss] = deal(cell(length(nT),nPh));
            [obj.Imu,obj.Isd,obj.pTolF] = deal(NaN(nApp,nPh));
            
            % special memory allocation (HT1 Controller only)
            if any(obj.iMov.vPhase == 4)
                obj.IbgR = B;
            end
            
            % ambiguous position memory allocation
            nR = arr2vec(getSRCount(obj.iMov)');
            obj.fPosAm = repmat(arrayfun(@(n)...
                (cell(n,1)),nR','un',0),obj.nPhase,1);
            
            % other memory allocation
            fP0 = cellfun(@(x)(repmat(arrayfun(@(n)(NaN(n,2)),...
                nT(:),'un',0),1,length(x))),obj.Img,'un',0);
            obj.IPos = cellfun(@(x)(repmat(arrayfun(@(n)(NaN(n,1)),...
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
            obj.pStats = cell(obj.nApp,obj.nPhase,obj.nMet);
            
            % retrieves the initial detection parameters
            obj.iniP = getTrackingPara(obj.iMov.bgP,'pInit');
            
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
            okPh = obj.getFeasPhase(1:2);
            
            % segments the phases (from low to high variance phases)
            for j = 1:obj.nPhase
                % updates the progress-bar
                i = iSort(j);
                wStrNw = sprintf('Moving Object Detection (Phase #%i)',i);
                
                % updates the progress bar
                pW0 = (j+1)/(obj.pWofs+obj.nPhase);
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
                        
            % determines if the phase is a special phase
            if obj.isSpecial
                % creates and runs the HT1 controller 
                objHT1 = SingleTrackInitHT1(obj);
                objHT1.analysePhase();                
                
                % sets the background/reference image fields
                obj.iMov.IbgR = obj.IbgR;
                obj.Ibg = obj.iMov.Ibg;
                
            else
                % case is there are no special phases
                obj.interPhasePosMatch();
                obj.hCQ = obj.expandImageArray(obj.frObj.hC);
            end                                                     
            
            % calculates the overall quality of the flies (prompting the
            % user to exclude any empty/anomalous regions)
            if any(obj.getFeasPhase([1,2,4]))
                obj.calcOverallQuality()
            end
            
            % ----------------------------------- %
            % --- BACKGROUND IMAGE ESTIMATION --- %
            % ----------------------------------- %            
            
            if obj.isSpecial       
                % sets the sub-region status flags
                obj.detSubRegionStatusFlags(1);
                
            else
                % updates the progressbar
                pW = (3+nPh)/(obj.pWofs+nPh);
                wStrNw = 'Background Image Estimation';
                obj.hProg.Update(1+obj.wOfsL,wStrNw,pW);
                
                % memory allocation
                iL0 = find(~cellfun('isempty',IL),1,'first');
                szL = cellfun(@size,IL{iL0}(1,:),'un',0);
                A = cellfun(@(x)(NaN(x)),szL,'un',0);
                obj.Ibg = repmat({A},obj.nPhase,1);
                
                % calculates the estimated blob size
                obj.bSzT = obj.calcBlobSize();
                nFrmPh = diff(obj.iMov.iPhase,[],2) + 1;
                obj.iMov.szObj = obj.bSzT*[1,1];
                
                % calculates background image estimates (for feasible phases)
                %             okPh = obj.getFeasPhase(1:2);
                for iPh = find(okPh(:)')
                    % updates the progressbar
                    wStrNw = sprintf('Analysing Phase (%i of %i)',iPh,nPh);
                    if obj.hProg.Update(2+obj.wOfsL,wStrNw,iPh/(1+nPh))
                        obj.calcOK = false;
                        return
                    end
                    
                    % calculates the background image estimate
                    if (nFrmPh(iPh) > 1) && any(obj.iMov.vPhase(iPh) == 1:2)
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
            end
            
            % determines the overall minimum sub-region flags
            obj.setupOverallStatusFlags();                   
            
            % ----------------------------------- %
            % --- UNTRACKABLE PHASE DETECTION --- %
            % ----------------------------------- %            
            
            % interpolates the locations for untrackable phases
            for i = find(obj.iMov.vPhase(:)' == 3)
                % analyses phase and calculates global coordinates
                obj.analyseUntrackablePhase(i);
                obj.calcGlobalCoords(i);
            end                           
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %            
            
            % performs the final region check (non-batch processing only)
            if obj.calcOK && ~obj.isBatch
                obj.performFinalDiagnosticCheck();
            end
            
            % updates the progressbar
            wStrF = 'Initial Detection Complete!';
            obj.hProg.Update(1+obj.wOfsL,wStrF,1);
            
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
                
                % retrieves and processes the image stack
                IL(:,i) = obj.getRegionImageStack(Img,iFrm,i,isHiV);
                obj.frObj.processImgStack(IL(:,i),iPh,i);
                
                % if successful, then retrieve the final information
                if obj.frObj.calcOK && ~isempty(obj.frObj.hC{i})
                    obj.setStackProcessInfo(iPh,i);
                end
            end
            
            % determines if any region didn't have a template image
            noTemp = cellfun(@isempty,obj.frObj.hC);
            if any(noTemp)                
                % retrieves and resizes the known template images
                hCT0 = obj.frObj.hC(~noTemp);                
                sz = cellfun(@size,hCT0,'un',0);
                szMx = max(cell2mat(sz),[],1);
                hCT = cellfun(@(x,s)(padarray(padarray(x,...
                    (szMx(1)-s(1))/2)',(szMx(1)-s(1))/2)'),hCT0,sz,'un',0);
                
                % reset the missing template images
                obj.frObj.hC(noTemp) = {calcImageStackFcn(hCT)};

                % sets up the raw/residual image stacks
                for i = find(noTemp(:)')
                    % update the waitbar figure
                    wStr = sprintf('Analysing Region (%i of %i)',i,obj.nApp);
                    if obj.hProg.Update(2+obj.wOfsL,wStr,i/obj.nApp)
                        % if the user cancelled, then exit
                        obj.calcOK = false;
                        return
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
            
        end
        
        % --- sets the data from the filtered image analysis object
        function setStackProcessInfo(obj,iPh,iApp)
            
            % retrieves the status flags
            obj.sFlagT{iPh,iApp} = obj.frObj.sFlag;
            obj.mFlag{iPh,iApp} = obj.frObj.mFlag;
            
            % retrieves the known and ambiguous marker locations
            obj.fPosL{iPh}(iApp,:) = obj.frObj.fPos;
            
            % stores the values into the arrays
            obj.fPosP{iPh,iApp} = cellfun(@(x)...
                (obj.upsampleCoords(x)),obj.frObj.pMaxS,'un',0);
            obj.yPosP{iPh,iApp} = obj.frObj.RMaxS;
            
            % sets the stats fields
            obj.pStatsF{iPh,iApp} = obj.frObj.pStats;
            obj.Is{iPh,iApp} = {obj.frObj.IRs,obj.frObj.dIRs};
            [obj.frObj.dIRs,obj.frObj.IXCs] = deal([]);
            
        end
        
        % --- calculates the final diagnostic check
        function performFinalDiagnosticCheck(obj)
            
            % calculates the max metric values (grouped by region/metric)
            QMet0 = cell(obj.nApp,obj.nMet);
            for i = 1:obj.nMet
                QMet0(:,i) = cellfun(@(x)(max(cell2mat(x),[],2)),...
                    num2cell(obj.pStats(:,:,i),2),'un',0);
            end
            
            % reshapes the metric arrays (grouped by region)
            QMetF = cellfun(@(x)(cell2mat(x)),num2cell(QMet0,2),'un',0);
            
            % determines which regions are potentially empty
            isE = obj.iMov.flyok;
            okNw = (combineNumericCells(cellfun(@(x)...
                (sum(x>obj.pLim,2)),QMetF(obj.iMov.ok)','un',0)) == 0);
            isE(:,obj.iMov.ok) = isE(:,obj.iMov.ok) & okNw;
            if ~any(isE(:)); return; end
            
            % closes the progressbar
            obj.hProg.setVisibility('off');
            
            % outputs a message string to the user
            eStr = sprintf(['One or more anomalous or empty regions ',...
                'have been detected.\nYou will need to ',...
                'manually accept/reject these regions.']);
            waitfor(msgbox(eStr,'Anomalous Regions Detected','modal'))
            
            % if so, prompt the user if they should exclude those
            % regions from the analysis
            eObj = EmptyCheck(obj.fPosG,isE);
            
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
            Zflag = NaN(max(cellfun('length',obj.mFlag(iPh,:))),obj.nApp);
            Zflag(:,okF) = combineNumericCells(obj.mFlag(iPh,okF)');
            
            % ----------------------------------- %
            % --- DISTANCE RANGE CALCULATIONS --- %
            % ----------------------------------- %
            
            % retrieves the residual scores
            pPR = obj.pStats(:,iPh,1);
            
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
            DrngC0(cellfun('isempty',DrngC0)) = {NaN(1,2)};
            
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
            pW = 1/2;
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
                    
                    % offsets and updates the position array
                    fP0 = cellfun(@(x,y)(obj.recalcBlobPos...
                        (x,y,pTolT(j))),IsubS,fP0,'un',0);
                    obj.setSRPos(iPh,i,j,fP0);
                end
                
                % calculates the overall threshold value
                obj.pTolF(i,iPh) = median(pTolT,'omitnan');
            end
            
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
            
            % calculates the gaussian signal parameters for each region
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
            N = obj.bSzT;
            
            % calculates the
            for i = find(obj.iMov.ok(:)')
                % updates the progressbar
                pW = 0.5*i/(1+obj.nApp);
                wStrNw = sprintf('%s (Region %i of %i)',wStr0,i,obj.nApp);
                if obj.hProg.Update(3+obj.wOfsL,wStrNw,pW)
                    obj.calcOK = false;
                    return
                end
                
                % calculates the feasible frames (the frames that are not
                % too far away from the image stack mean)
                Imn = cellfun(@(x)(mean(x(:),'omitnan')),I(:,i));
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
                        IbgE = obj.setupBGEstStack(IL,fP,N);
                        Imx0 = calcImageStackFcn(IbgE,'max');
                        
                        % interpolates any gaps within the background image
                        IbgLmn = obj.interpBGImageGaps(Imx0,IL,fP);
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
        function I = setupBGEstStack(obj,I,fP,N)
            
            % memory allocation
            sz = size(I{1});
            NN = N + 1 + obj.nI;
            
            % sets up distance binary mask
            [X,Y] = meshgrid(-NN:NN);
            D = sqrt(X.^2 + Y.^2);
            Bfilt = D <= NN;
            
            % sets up the removal binary mask
            szF = size(Bfilt);
            xiN = (1:szF) - floor((szF(1)-1)/2+1);
            Brmv = Bfilt > 0;
            
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
        
        % --- interpolates any gaps within the background image
        function I = interpBGImageGaps(obj,I,I0,fP)
            
            % determines the gaps within the image
            B0 = isnan(I);
            [iGrp,BB] = getGroupIndex(B0,'BoundingBox');
            if isempty(iGrp); return; end
            
            % initialisations
            dN = 5;
            sz = size(I);
            iP = unique(cellfun(@(x)(sub2ind(sz,x(:,2),x(:,1))),fP));
            
            % determines the reduced blob regions for each gap
            for i = 1:length(iGrp)
                % sets the row/column indices
                ind0 = floor(BB(i,1:2));
                iR = max(1,ind0(2)-dN):min(sz(1),ind0(2)+BB(i,4)+dN);
                iC = max(1,ind0(1)-dN):min(sz(2),ind0(1)+BB(i,3)+dN);
                pOfs = [iC(1),iR(1)];
                
                % sets the local image stack
                IGrp = cellfun(@(x)(x(iR,iC)),I0,'un',0);
                IGrpMx = calcImageStackFcn(IGrp,'max');
                szL = size(IGrp{1});
                
                % determines the binary mask of the maxima within the gap
                iPG = glob2loc(intersect(iP,iGrp{i}),pOfs,sz,szL);
                if isempty(iPG)
                    % if there are not such maxima, then determine the
                    % largest binary surrounding the max value
                    BGrp = detLargestBinary(IGrpMx);
                else
                    % otherwise, determine the maxima with the lowest value
                    iPG = iPG(argMin(IGrpMx(iPG)));
                    [yPG,xPG] = ind2sub(szL,iPG);
                    ILim = [IGrpMx(iPG(1)),max(IGrpMx(:))];
                    
                    % determines the reduced binary blob
                    BGrp = detLargestBinary(IGrpMx,[xPG,yPG],ILim);
                end
                
                % sets the reduced binary gap
                IGrpMx(BGrp) = NaN;
                I(iR,iC) = IGrpMx;
            end
            
            % interpolates the gaps within the image
            if obj.iMov.is2D
                % case is a 2D setup
                I = (interpImageGaps(I,1) + interpImageGaps(I,2))/2;
            else
                % case is a 1D setup
                I = interpImageGaps(I);
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
            okPh = obj.getFeasPhase(1:2);
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
                        if ~any(all(cellfun('isempty',fPosT)))
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
                okPh = obj.getFeasPhase(1:2);
                fPosPT = cellfun(@(x)(x{1,iT}),obj.fPosP(okPh,iApp),'un',0);
                
                if any(cellfun('isempty',fPosPT))
                    indG = [];
                else
                    indG = obj.frObj.findStaticPeakGroups(fPosPT);
                end
                
                % determines which groups are present over all phases
                if isempty(indG)
                    % FINISH ME?
                    return
                    
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
            okPh = find(obj.getFeasPhase());
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
            okPh = obj.getFeasPhase(1:2);
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

        % ------------------------------------------- %
        % --- OTHER PHASE TYPE TRACKING FUNCTIONS --- %
        % ------------------------------------------- %                         
        
        % --- analyses the untrackable phase, iPh
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
                for i = 1:length(obj.fPosL{iPh})
                    obj.fPosL{iPh}{i}(:) = NaN;
                end
                
                % exits the function
                return
            end
            
            % determines if the surrounding phases is feasible
            okPh = obj.getFeasPhase();
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
            fPosPT0 = obj.fPosP{obj.iPhP,obj.iAppP};
            if isempty(fPosPT0)
                fPosPT = [];
            else
                yOfs = cellfun(@(x)(x(1)),obj.iMov.iRT{obj.iAppP})-1;
                fPosPT = cell2mat(cellfun(@(x,y)(obj.frObj.offsetYCoords...
                    (x,y)),fPosPT0(obj.iFrmP,:)',...
                    num2cell(yOfs),'un',0));
            end
            
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
        
        % --- calculates the overall quality metrics
        function calcOverallQuality(obj)
            
            % exit if the user cancelled
            if ~obj.calcOK; return; end
            
            % initialisations
            nPh = obj.nPhase;
            okPh = obj.getFeasPhase([1:2,4]);
            
            % updates the progressbar
            wStrNw = 'Calculating Quality Metrics...';
            obj.hProg.Update(1+obj.wOfsL,wStrNw,(2+nPh)/(obj.pWofs+nPh));
            
            % sets up the reference image
            Iref0 = calcImageStackFcn(obj.hCQ,'mean');            
            if isempty(Iref0)
                return;
            else                
                Iref = normImg(obj.frObj.downsampleImage(Iref0));
                N = ceil((size(Iref,1) - 1)/2);
            end
            
            % loops through each of the phases/regions calculating the
            % z-scores for the positions of all frames/sub-regions
            for j = find(obj.iMov.ok(:)')
                % updates the progressbar
                wStr = sprintf('Analysing Region (%i of %i)',j,obj.nApp);
                if obj.hProg.Update(2+obj.wOfsL,wStr,j/obj.nApp)
                    % if the user cancelled, then exit
                    obj.calcOK = false;
                    return
                end
                
                % calculates the region vertical offset
                fok = obj.iMov.flyok(1:obj.nTube(j),j);
                yOfs = obj.calcVertOffset(obj.iMov.iRT{j});
                pOfs = [zeros(length(yOfs),1),yOfs];
                
                % calculates the
                for i = find(okPh(:)')
                    % updates the progressbar
                    wStr = sprintf('Analysing Phase (%i of %i)',...
                        i,obj.nPhase);
                    if obj.hProg.Update(3+obj.wOfsL,wStr,i/obj.nPhase)
                        % if the user cancelled, then exit
                        obj.calcOK = false;
                        return
                    end
                    
                    % retrieves the positional data
                    IsS = obj.Is{i,j};
                    pS = obj.pStatsF{i,j};
                    fP = cellfun(@(x)(obj.downsampleCoords(x)+...
                        pOfs),obj.fPosL{i}(j,:),'un',0);
                    
                    % calculates the x-correlation peak z-scores
                    ZIR = NaN(obj.nTube(j),length(IsS{2}));
                    for k = 1:length(IsS{2})
                        fok = ~isnan(fP{k}(:,1));
%                         [ZIR(fok,k),obj.IPos{i}{j,k}(fok)] = ...
%                             obj.calcZScores(IsS{2},pS,fP,k,fok);
                        ZIR(fok,k) = obj.calcZScores(IsS{2},pS,fP,k,fok);
                    end
                    
                    % case is the residual difference images
                    obj.pStats{j,i,1} = ZIR;
                    
                    % set the other quality metrics (non-batch only)
                    if ~obj.isBatch
                        % sets up the sub-image stack (surrounding each
                        % location point for each object/frame)
                        A = cellfun(@(x)(x.*max...
                            (0,calcXCorr(Iref,x))),IsS{1},'un',0);
                        P = obj.frObj.calcImageStackStats(A);
                        Isub = cell2cell(cellfun(@(y,z)(cellfun(@(x)...
                            (obj.getPointSubImage(z,x,N)),num2cell...
                            (y,2),'un',0)),fP,A(:)','un',0),0);
                        
                        % calculates the SSIM values for each frame
                        pSSIM = NaN(size(fP{1},1),length(fP));
                        for k = 1:length(fP)
                            pSSIM(fok,k) = cellfun(@(x)(obj.calcSSIM...
                                (normImg(x),Iref,N/2)),Isub(fok,k));
                        end
                        
                        % calculates the z-scores for each frame
                        ZXC = NaN(obj.nTube(j),length(IsS{2}));
                        for k = 1:length(IsS{2})
                            fok = ~isnan(fP{k}(:,1));
                            ZXC(fok,k) = obj.calcZScores(A,P,fP,k,fok);
                        end
                        
                        % case is the residual difference images
                        obj.pStats{j,i,2} = ZXC;
                        obj.pStats{j,i,3} = pSSIM;
                    end
                end
            end
            
            % determines if there are any infeasible phases
            if any(~okPh)
                % if so, then add in the missing data values
                nSR = getSRCount(obj.iMov,1:obj.nApp);
                A = arrayfun(@(n)(NaN(n,1)),nSR,'un',0);
                
                % fills in the missing phase data (for each metric)
                for i = 1:obj.nMet
                    for j = find(~okPh(:)')
                        obj.pStats(:,j,i) = A;
                    end
                end
            end
            
            % removes the statistics data fields
            [obj.Is,obj.pStatsF] = deal([]);
            
        end
        
        % --- calculates the sub-region vertical offset
        function yOfs = calcVertOffset(obj,iRT)
            
            % sets the row/column indices
            if obj.nI > 0
                % interpolates the images (if large)
                iRT = cellfun(@(x)(x((obj.nI+1):2*obj.nI:end)),iRT,'un',0);
            end
            
            % calculates the vertical offset
            yOfs = [0;cumsum(cellfun('length',iRT(1:end-1)))];
            
        end
                
        % --- downsamples the image coordinates
        function fP = upsampleCoords(obj,fP)
            
            if obj.nI > 0
                fP = 1 + obj.nI*(1 + 2*(fP-1));
            end
            
        end
        
        % --- downsamples the image coordinates
        function fP = downsampleCoords(obj,fP)
            
            if obj.nI > 0
                fP = roundP(((fP-1)/obj.nI - 1)/2 + 1);
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
        function [sD,ff] = optGaussSignal(II0)
            
            function F = optGauss(p,x)
                
                F = p(1)*exp(-(x/p(2)).^2);
                
            end
            
            % initialisations
            N = (length(II0)-1)/2;
            gaussEqn = 'A*exp(-(x/sd)^2)';
            xi = (-N:N)';
            
            %
            II = normImg(II0(:));
            [iN,iP] = deal(find(xi<0),find(xi>0));
            xiI = argMin(II(iN)):(argMin(II(iP)) + (N+1));
            
            % sets the fitting weights
            W0 = exp(-(xi/N).^2);
            W = W0/sum(W0);
            
            try
                % fits the gaussian equation and returns the std-dev
                [p0,WI] = deal([max(II(:)),1],W(xiI));
                ff = fit(xi(xiI),II(xiI),gaussEqn,'Start',p0,'Weights',WI);
                sD = ff.sd;
            catch
                % if curve-fitting toolbox is unusable, then use the
                % optimisation toolbox functions
                opt = optimset('display','none');
                pp = lsqcurvefit(@optGauss,p0,xi,II,[0,0],[10,10],opt);
                [ff,sD] = deal([],pp(2));
            end
            
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
                
        % --- recalculates the blob positional coordinates
        function fP = recalcBlobPos(I,fP,pTolT)
            
            % initialisations
            szL = size(I);
            N = (szL(1)-1)/2;
            
            % determines the thresholded blob
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
        
        % --- calculates the z-scores from the points
        function [Z,IsP] = calcZScores(IsS,pS,fP,iImg,ok)
            
            % calculates the linear indices for the coordinates
            iP = sub2ind(size(IsS{1}),fP{iImg}(ok,2),fP{iImg}(ok,1));
            
            % calculates the z-scores
            IsP = IsS{iImg}(iP);
            Z = (IsP - pS.Imu(iImg))/pS.Isd(iImg);
            
        end
        
        % --- calculats the SSIM score
        function pSSIM = calcSSIM(I,Iref,R,isNorm)
            
            %
            if ~exist('isNorm','var'); isNorm = false; end
            
            %
            [i1,j1] = deal(~all(isnan(I),2),~all(isnan(I),1));
            [i2,j2] = deal(~all(isnan(Iref),2),~all(isnan(Iref),1));
            [ii,jj] = deal(i1 & i2, j1 & j2);
            
            %
            if ~any(ii) || ~any(jj)
                pSSIM = 0;
            else
                % normalises the sub-image
                if isNorm; I = normImg(I); end
                pSSIM = ssim(I(ii,jj),Iref(ii,jj),'Radius',R);
            end
            
        end
        
        % --- expands the image stack, hC, so they are all the same size
        function hCT = expandImageArray(hC)
            
            % determines the sizes of the images in the stack
            sz = cell2mat(cellfun(@size,hC,'un',0));
            szMx = max(sz,[],1);
            
            %
            hCT = cell(length(hC),1);
            for i = 1:length(hC)
                % sets the image copy
                if isequal(sz(i,:),szMx)
                    hCT{i} = hC{i};
                else
                    dsz = (szMx(1) - sz(i,1))/2;
                    xi = dsz + (1:sz(i,1));
                    
                    hCT{i} = zeros(szMx);
                    hCT{i}(xi,xi) = hC{i};
                end
            end
            
        end        
        
    end
    
end
