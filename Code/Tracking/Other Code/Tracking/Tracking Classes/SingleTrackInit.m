classdef SingleTrackInit < SingleTrack
    % class properties
    properties
        
        % image array fields
        Img
        Img0
        Ibg
        Ibg0
        IbgT
        IbgT0
        Iopt
        
        % auto-detection fields
        nI
        iCG
        iRG
        fPos0
        pTolR
        ImaxR
        tPerR
        pTolS
        ImaxS
        tPerS
        yTube
        xTube
        posO
        nTubeBest
        
        % other important fields
        i0        
        pQ0
        iOK
        fPos
        fPosL
        fPosG
        tPara
        sFlag
        pStats
        pData       
        useP
        indFrm
        useFilt
        dpOfs
        dpInfo
        errStr
        errMsg
        prData0 = [];
        isAutoDetect = false;
        
        % parameters
        pW = 0.5;
        nFilt = 50;
        usePTol = 0.25;
        pTolShape = 0.1; 
        pTolStat = 0.35;
        pTile = 90;
        QTotMin = 0.10;
        dpTol = 0.5;
        hF = fspecial('gaussian',10,3);
        
    end
    
    % class methods
    methods
        % class constructor
        function obj = SingleTrackInit(iData)
            
            % creates the super-class object
            obj@SingleTrack(iData);
   
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
            nFrm = cellfun(@length,obj.Img);
            wStr0 = {'Checking Phase Image Translation';...
                     'Calculating Image Translation'};
            obj.nTubeBest = obj.nTube;
            
            % phase dependent object memory allocation
            A = cell(nPh,1);           
            [obj.Ibg,obj.Ibg0] = deal(A);
            [obj.IbgT,obj.IbgT0] = deal(A);
            [obj.sFlag,obj.tPara,obj.pQ0] = deal(A);
            [obj.dpOfs,obj.dpInfo] = deal(A);
            [obj.errStr,obj.errMsg] = deal([]);            
            
            % other memory allocation
            pOfs0 = zeros(nPh,2);
            fP0 = cellfun(@(x)(repmat(arrayfun(@(n)(NaN(n,2)),...
                              nT(:),'un',0),1,length(x))),obj.Img,'un',0);
                          
            % retrieves the positional array (based on estimation type)
            if obj.isAutoDetect
                % case is the 1D grid automatic detection
                [obj.fPos0,obj.fPos] = deal(fP0);                
            else
                % case is the initial detection
                obj.fPosL = fP0;
            end
            
            % calculates the image offset over the phase
            obj.i0 = find(obj.iMov.ok,1,'first');            
            for i = find(obj.iMov.vPhase(:)'==1)
                % updates the progressbar
                wStr = sprintf('%s (Phase %i of %i)',wStr0{1},i,nPh);
                if obj.hProg.Update(2+obj.wOfsL,wStr,i/nPh)
                    % if the user cancelled, then exit the function
                    obj.calcOK = false;
                    return
                end                  
                
                % determines if there is a signficant shift in the images
                pOfs0(i,:) = fastreg(obj.Img{i}{1},obj.Img{i}{end});
            end
            
            % calculates the overall displacement over the video
            pOfsT = nansum(pOfs0,1);            
            if any(abs(pOfsT) > 1)
                for i = find(obj.iMov.vPhase(:)'==1)
                    % updates the progressbar
                    wStr = sprintf('%s (Phase %i of %i)',wStr0{1},i,nPh);
                    if obj.hProg.Update(2+obj.wOfsL,wStr,i/nPh)
                        % if the user cancelled, then exit the function
                        obj.dpOfs(:) = {[]};
                        obj.calcOK = false;
                        return
                    end      
                    
                    % if so then calculate the offset over all phase frames
                    obj.dpOfs{i} = NaN(nFrm(i),2);  
                    obj.dpOfs{i}(1,:) = 0;

                    % calculates the image offset for the remaining frames
                    for j = 1+find(obj.iOK{i}(2:nFrm(i)))'
                        wStr = sprintf('%s (Frame %i of %i)',...
                                        wStr0{2},j,nFrm(i));
                        if obj.hProg.Update(3+obj.wOfsL,wStr,j/nFrm(i))
                            % if the user cancelled, then exit the function
                            obj.dpOfs(:) = {[]};
                            obj.calcOK = false;
                            return
                        end   

                        % calculates the image shift between the images
                        obj.dpOfs{i}(j,:) = ...
                               -flip(fastreg(obj.Img{i}{1},obj.Img{i}{j}));
                    end
                    
                    % special case - interpolates any missing offset frames
                    obj.interpMissingOffsets(i);
                end
            end
                              
            % calculates the point statistics data struct
            obj.pStats = struct('I',[],'IR',[],'Ixc',[]);            
            B = cell2cell(cellfun(@(x)(arrayfun(@(n)...
                    (NaN(n,length(x))),nT(:),'un',0)),obj.Img,'un',0),0);
            [obj.pStats.I,obj.pStats.IR,obj.pStats.Ixc] = deal(B);
            
        end
        
        % --- sets up the tracking image stack/index array
        function getTrackingImages(obj)
            
            % retrieves the frame index/image arrays
            if obj.isCalib
                % returns the previously read image stack
                obj.Img = obj.Img0;
                obj.indFrm = {1:length(obj.Img{1})};
                
            else
                % sets the phase frame indices
                nPh = obj.nPhase;
                obj.indFrm = getPhaseFrameIndices(obj.iMov,obj.nFrmR);
                
                % retrieves the use filter flag
                if isfield(obj.iMov.bgP.pSingle,'useFilt')
                    obj.useFilt = obj.iMov.bgP.pSingle.useFilt;
                else
                    obj.useFilt = false;
                end
                
                % memory allocation
                [obj.Img,obj.iOK] = deal(cell(nPh,1));

                % reads the initial images                            
                for i = 1:nPh
                    if obj.iMov.vPhase(i) < 3
                        % updates the progressbar 
                        wStr = sprintf(...
                            'Reading Phase Images (Phase %i of %i)',i,nPh);
                        if obj.hProg.Update(1+obj.wOfsL,wStr,i/(1+nPh))
                            % if the user cancelled, then exit the function
                            obj.calcOK = false;
                            return
                        end

                        % reads the image stack for phase frame indices
                        [obj.Img{i},obj.iOK{i}] = ...
                                        obj.getImageStack(obj.indFrm{i});
                        
                        % applies the smooth filter (if specified)
                        if obj.useFilt
                            obj.Img{i} = cellfun(@(x)(obj.filterImg...
                                        (x,obj.hS)),obj.Img{i},'un',0);
                        end
                    end
                end
            end
            
            % updates the progress-bar
            obj.hProg.Update(1+obj.wOfsL,'Frame Read Complete',1);
            
        end               
        
        % --- calculates the initial fly location/background estimates
        function calcInitEstimate(obj,iMov,hProg)
            
            % sets the input variables
            obj.iMov = iMov;
            obj.hProg = hProg; 
            obj.nI = floor(max(getCurrentImageDim())/1000);
                        
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
            
            % runs the initial detection estimate
            obj.runInitialDetection(); 
            if ~obj.calcOK || obj.isAutoDetect
                % if the user cancelled, then exit
                return
            end
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % sets the background images into the sub-region data struct 
            obj.iMov.Ibg = obj.Ibg;            
            obj.iMov.tPara = obj.setupTemplateImage();
            obj.iMov.szObj = obj.calcObjShape();            
                        
            % calculates the overall quality of the flies (prompting the
            % user to exclude any empty/anomalous regions)
            okPh = obj.iMov.vPhase < 3;
            if ~(obj.isBatch || obj.isAutoDetect) && any(okPh)
                obj.calcOverallQuality()
            end
            
            % sets the status flags for each phase (full and overall)
            obj.iMov.StatusF = obj.sFlag;
            
            % determines which regions are potentially empty 
            ii = ~cellfun(@isempty,obj.iMov.StatusF);
            if any(ii)
                szDim = [1,1,sum(ii)];
                Status0 = cell2mat(reshape(obj.iMov.StatusF(ii),szDim));
                Status1 = min(Status0,[],3);
                noFly = any(Status0==3,3);

                % updates the status flag  
                Status1(Status1 == 0) = 2;
                if obj.isBatch                
                    Status1(noFly & obj.iMov.flyok) = 2;
                    Status1(noFly & ~obj.iMov.flyok) = 3;
                else
                    Status1(noFly) = 3;  
                end

                % resets the status flags for the video
                obj.iMov.Status = num2cell(Status1,1);   
            else
                obj.iMov.Status = arrayfun(@(x)...
                            (zeros(x,1)),getSRCountVec(obj.iMov)','un',0);                
            end
            
            % updates the progress bar
            obj.hProg.Update(1+obj.wOfsL,'Initial Estimate Complete!',1);                                                
            
        end  
        
        % --- calculates the template images
        function tPara = setupTemplateImage(obj)
            
            % sets up the weight image and the x/y gradients
            Itemp = obj.setupWeightedTemplateImage();
            [GxT,GyT] = imgradientxy(Itemp,'sobel');
            
            % sets the template image struct
            tPara = struct('Itemp',Itemp,'GxT',GxT,'GyT',GyT);
            
        end
        
        % --- calculates the template object shape parameters
        function szObj = calcObjShape(obj,Itemp)
            
            % sets the default input argument
            if ~exist('Itemp','var')
                Itemp = obj.iMov.tPara.Itemp;
            end
            
            % fits the gaussian image to the template image
            I = 1 - normImg(Itemp);
            obj.Iopt = opt2DGaussian({I},[],[]);
            
            % determines the shape properties from the fitted shape
            Bopt0 = obj.Iopt/max(obj.Iopt(:));
            Bopt = bwmorph(Bopt0 > obj.pTolShape,'majority');
            [~,objBB] = getGroupIndex(Bopt,'BoundingBox');            
            szObj = objBB([3,4]);
            
        end         
       
        % -------------------------------------------- %
        % --- INITIAL RESIDUAL DETECTION FUNCTIONS --- %
        % -------------------------------------------- %   
        
        % --- runs the initial detection on the image stack, Img
        function runInitialDetection(obj)
        
            % sorts the phases by type (low var phases first)
            nPh = length(obj.iMov.vPhase);
            indPh = [obj.iMov.vPhase,diff(obj.iMov.iPhase,[],2)];
            [~,iSort] = sortrows(indPh,[1,2],{'ascend' 'descend'});
            
            % -------------------------------- %
            % --- INITIAL OBJECT DETECTION --- %
            % -------------------------------- %            
            
            % segments the phases (from low to high variance phases)
            for j = 1:nPh
                % updates the progress-bar
                i = iSort(j);
                wStrNw = sprintf('Analysing Phase #%i (%i of %i)',i,j,nPh);
                
                % updates the progress bar
                if obj.hProg.Update(1+obj.wOfsL,wStrNw,j/(1+nPh))
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
                
                % analyses the phase (depending on type)
                switch obj.iMov.vPhase(i)  
                    case 1
                        % case is a low-variance phase
                        if obj.isAutoDetect
                            obj.autoDetectEstimate(obj.Img{i},i);
                        else
                            obj.analyseLowVarPhase(obj.Img{i},i);
                        end
                        
                    case 2
                        % case is a high-variance phase
                        obj.analyseHighVarPhase(obj.Img{i},i); 
                        
                end
                
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
                    
                elseif ~obj.isAutoDetect && obj.calcOK
                    % otherwise, calculate the global coordinates
                    obj.calcGlobalCoords(i);
                end
            end
            
            % ----------------------------------- %
            % --- IMAGE TRANSLATION DETECTION --- %
            % ----------------------------------- %
            
            % determines the image translation information (tracking only)
            if ~obj.isAutoDetect
                try
                    % determines the image translation information
                    obj.detImgTranslateInfo();

                catch ME
                    % if there was an error then store the details
                    obj.errStr = 'image translation information';
                    [obj.errMsg,obj.calcOK] = deal(ME.message,false);
                    obj.hProg.closeProgBar;
                    return                
                end                
            end
            
            % updates the progressbar
            wStrF = 'Initial Detection Complete!';
            obj.hProg.Update(1+obj.wOfsL,wStrF,1);
            
        end
        
        % ---------------------------------- %
        % --- 1D AUTO-DETECTION ESTIMATE --- %
        % ---------------------------------- %
        
        function autoDetectEstimate(obj,Img,iPh)
            
            % memory allocation
            nApp = length(obj.iMov.posO);
            szFrm = getCurrentImageDim();            
            [obj.iRG,obj.iCG] = deal(cell(nApp,1));
            
            % sets up the total region row/column indices
            obj.posO = getCurrentRegionOutlines(obj.iMov);
            for i = 1:nApp 
                % retrieves the current outside dimensions
                pP = obj.posO{i};
                
                % sets the column indices
                iC0 = (floor(pP(1))-1) + (1:ceil(pP(3)));
                obj.iCG{i} = iC0((iC0>0)&(iC0<=szFrm(2)));
                
                % sets the row indices
                iR0 = (floor(pP(2))-1) + (1:ceil(pP(4)));
                obj.iRG{i} = iR0((iR0>0)&(iR0<=szFrm(1)));                                   
            end       
            
            % offsets the images (if required)
            if ~isempty(obj.dpOfs{iPh})
                dP = num2cell(obj.dpOfs{iPh},2);
                Img = cellfun(@(x,p)(calcImgTranslate(x,p)),Img,dP,'un',0);
            end
            
            % calculates the background estimate and residuals
            [obj.IbgT{iPh},obj.IbgT0{iPh}] = ...
                                deal(calcImageStackFcn(Img,'max'));
            IR = cellfun(@(x)(obj.IbgT0{iPh}-x),Img,'un',0);  
            
            % ----------------------------------------- %
            % --- DETECTION ESTIMATION CALCULATIONS --- %
            % ----------------------------------------- %
            
            try
                % resets the moving blobs
                obj.detectMovingBlobAuto(IR);
            catch ME
                % if there was an error then store the details
                obj.errStr = 'moving object tracking';
                [obj.errMsg,obj.calcOK] = deal(ME.message,false);
                return                
            end            
            
            try
                % sets up the automatic blob template
                obj.setupBlobTemplateAuto(Img)
            catch ME
                % if there was an error then store the details
                obj.errStr = 'object template calculation';
                [obj.errMsg,obj.calcOK] = deal(ME.message,false);
                return                
            end
              
            try
                % optimises the grid placements
                IRL = obj.optGridVertPlacement(IR);
                obj.optGridHorizPlacement(IRL);           
            catch ME
                % if there was an error then store the details
                obj.errStr = 'stationary object tracking';
                [obj.errMsg,obj.calcOK] = deal(ME.message,false);
                return                
            end            
            
        end
        
        % --- detects the moving blobs from the residual image stack, IR
        function detectMovingBlobAuto(obj,IR)
            
            % if the user cancelled, then exit
            if ~obj.calcOK; return; end
            obj.hProg.Update(2+obj.wOfsL,'Moving Object Tracking',0.25);
            obj.hProg.Update(3+obj.wOfsL,'Analysing Region',0);     
            
            % initialisations
            nApp = length(obj.iMov.pos);
            [obj.ImaxR,obj.pTolR] = deal(cell(nApp,1),zeros(nApp,1));
            
            % sets up the residual image stacks for each region             
            IRL = cellfun(@(x,y)(cellfun...
                        (@(z)(z(x,y)),IR,'un',0)),obj.iRG,obj.iCG,'un',0);            
            
            % attempts to calculate the coordinates of the moving objects            
            for iApp = 1:nApp
                % updates the progress bar
                wStrNw = sprintf('Analysing Region (%i of %i)',iApp,nApp);
                if obj.hProg.Update(3+obj.wOfsL,wStrNw,iApp/(1+nApp))
                    obj.calcOK = false;
                    return
                end                
                
                % calculates the normalised row residual signal. from this,
                % determine the number of signficant peaks from the signal
                IRLmax = calcImageStackFcn(IRL{iApp},'max');
                ImaxR0 = max(IRLmax,[],2);
                obj.ImaxR{iApp} = ImaxR0 - medfilt1(ImaxR0,obj.nFilt);
                
                % sets up the signal values
                Imx = nanmax(obj.ImaxR{iApp});
                Imn = nanmin(obj.ImaxR{iApp});
                obj.pTolR(iApp) = obj.pW*(Imx+Imn);
                                
                % thresholds the signal for the signficant peaks                 
                iGrp = getGroupIndex(obj.ImaxR{iApp} > obj.pTolR(iApp));                                       
                
                % from the positions from the most likely peaks               
                if ~isempty(iGrp)
                    obj.fPos0{1}(iApp,:) = cellfun(@(x)...
                                (obj.trackAutoMovingBlobs(x,iGrp)),...
                                IRL{iApp},'un',0);
                    obj.pStats.IR{iApp} = ...
                            combineNumericCells(cellfun(@(x,y)...
                                (obj.getPixelValue(x,y)),IRL{iApp},...
                                obj.fPos0{1}(iApp,:)','un',0)');
                end
            end                    

            % updates the progressbar
            obj.hProg.Update(3+obj.wOfsL,'Region Analysis Complete',1);            
            
        end                  
        
        % --- determines the automatic detection blob template
        function setupBlobTemplateAuto(obj,I)
            
            % initialisations
            dN = 15;            
            szObj0 = NaN(1,2);
            [i,iMax] = deal(0,10);
            nApp = size(obj.fPos0{1},1);
            [Isub,obj.useP,obj.ImaxS] = deal(cell(nApp,1));                       
            
            % keep looping until a stable solution is found
            while 1
                % retrieves the sub-images around each significant point
                for i = 1:nApp
                    % retrieves the local images
                    IL = cellfun(@(x)(x(obj.iRG{i},obj.iCG{i})),I,'un',0);

                    % retrieves the point sub-image stack
                    Isub{i} = cell2cell(cellfun(@(x,y)(cellfun(@(z)...
                            (obj.getPointSubImage(x,z,dN)),num2cell(y,2),...
                            'un',0)),IL',obj.fPos0{1}(i,:),'un',0),0);

                    % removes any low-residual images
                    obj.useP{i} = obj.pStats.IR{i} > obj.pTolR(i);
                    Isub{i}(~obj.useP{i}) = {[]};
                end            

                % calculates the template image from the estimated image
                Itemp = calcImageStackFcn(cell2cell(Isub),'mean');          
                szObjNw = obj.calcObjShape(Itemp); 
                
                % determines if the new value has changed
                if isequal(szObj0,szObjNw)
                    % if not, then exit the loop                    
                    break
                else
                    % otherwise, update the fields
                    [szObj0,dN] = deal(szObjNw,max(szObjNw));
                    
                    % increments the counter
                    i = i + 1;
                    if i > iMax
                        % exit if the count is too high
                        break
                    end
                end
            end
            
            % sets the object template field
            [GxT,GyT] = imgradientxy(Itemp,'sobel'); 
            obj.tPara{1} = struct('Itemp',Itemp,'GxT',GxT,'GyT',GyT);              
            
            % sets the class object fields
            obj.iMov.szObj = szObjNw;
            
        end            
        
        % -------------------------------------- %
        % --- 1D GRID OPTIMISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- optimises the grid vertical placement
        function IRL = optGridVertPlacement(obj,IR)
            
            % parameters
            dtMin = 4;            
            
            % calculates the             
            IRL = cellfun(@(ir,ic)(cellfun(@(x)(x(ir,ic)),...
                                IR,'un',0)),obj.iRG,obj.iCG,'un',0);
            
            % initialisations and memory allocation
            nImg = length(IRL{1});
            [nApp,nTube] = deal(length(IRL),obj.nTube);
            nRow = cellfun(@(x)(size(x{1},1)),IRL);

            % memory allocation
            C = NaN(nApp,nImg);
            Ymx = cell(1,nApp);
            [tPk,yPk] = deal(cell(nApp,nImg));             
                            
            % calculates the signal 
            for i = 1:nApp    
                % calculates the normalised maxima 
                Ymx{i} = cellfun(@(x)(normImg(max(x,[],2))),IRL{i},'un',0);   

                % determines the major peaks from the image stack
                for j = 1:nImg        
                    [yPk0,tPk0] = findpeaks...
                                    (Ymx{i}{j},'MinPeakDistance',dtMin);
                    [idx,C0] = kmeans(yPk0,2);

                    iMx = argMax(C0);
                    [ii,C(i,j)] = deal(idx == iMx,C0(iMx));
                    [tPk{i,j},yPk{i,j}] = deal(tPk0(ii),yPk0(ii));                        
                end    
            end

            % determines which regions have a low overall residual value 
            % (these will be excluded here but analysed later)
            %   => FINISH ME!
            isOK = true(1,nApp);

            % aligns the signal peaks over all regions
            tPkT = cell(1,nApp);
            for i = find(isOK)
                % combines the peak times into a single array
                tPkT{i} = combineNumericCells(tPk(i,:));

                % determines which frame has all sub-regions accounted for
                hasAll = all(~isnan(tPkT{i}),1);
                if any(hasAll)
                    % if such a frame exists, use this as the reference 
                    iMx = find(hasAll,1,'first');
                else
                    % finish me!
                    a = 1;
                end

                % temporally aligns the peaks over all frames 
                % (relative to ref frame)
                indG = zeros(size(tPkT{i})); 
                for j = 1:size(tPkT{i},2)
                    D = pdist2(tPkT{i}(:,iMx),tPkT{i}(:,j)); 
                    indG(:,j) = munkres(D); 
                end

                % determines if any sub-regions are missing peak values
                isMiss = indG == 0;
                if any(isMiss(:))
                    % re-orders the time peak array
                    for j = find(any(isMiss,1))
                        tPkT{i}(~isMiss(:,j),j) = ...
                                        tPkT{i}(~isnan(tPkT{i}(:,j)),j);
                        tPkT{i}(isMiss(:,j),j) = NaN;
                    end

                    % calculates an estimate of the grid spacing size
                    dtPer0 = floor(nanmedian...
                                    (nanmedian(diff(tPkT{i},[],1),1))/2);

                    % if so, then determine which peak roughly corresponds 
                    % to the other peak times for these sub-regions
                    for j = find(any(isMiss,2))'
                        % calculates the average peak location 
                        tPkMn = median(tPkT{i}(j,~isnan(tPkT{i}(j,:))));

                        % determines the missing peaks from the signal
                        for k = find(isMiss(j,:))
                            % determines the region of interest peaks
                            [yMx,tMx] = findpeaks(Ymx{i}{k});
                            ii = find((tMx > (tPkMn-dtPer0)) & ...
                                      (tMx < (tPkMn+dtPer0)));

                            % sets the peak time to the highest peak value
                            tPkT{i}(j,k) = tMx(ii(argMax(yMx(ii))));
                        end
                    end
                end

                % determines the locations not occupied by the flies
                X = num2cell([min(tPkT{i},[],2),max(tPkT{i},[],2)],2);
                indX = cellfun(@(x)(x(1):x(2)),X(:)','un',0);        
                BX = ~setGroup(cell2mat(indX),[nRow(i),1]);  

                % optimises the region grid locations
                YgT = calcImageStackFcn(Ymx{i},'max');
                obj.yTube{i} = obj.optRegionGrid(YgT,BX,tPkT{i},nTube(i));    
            end      
            
        end      
        
        % --- optimises the grid vertical placement
        function optGridHorizPlacement(obj,IRL)
            
            % parameters
            pTol = 0.5;
            xDel = ceil(obj.iMov.szObj(1)/2);
            
            %
            for i = find(~cellfun(@isempty,obj.yTube(:)'))
                % calculates the maximum over the image stack
                IRLT = calcImageStackFcn(IRL{i},'max');
                
                % removes any rows not within the vertical regions
                sz = size(IRL{i}{1},1);                
                ii = max(1,obj.yTube{i}(1)):min(sz(1),obj.yTube{i}(end));
                IRLT(~setGroup(ii,[sz(1),1])) = 0;
                
                % sets the grid horizontal dimensions
                iGrp = getGroupIndex(max(normImg(IRLT),[],1) > pTol);
                obj.xTube{i} = [max(iGrp{1}(1)-xDel,1),...
                                min(iGrp{end}(end)+xDel,size(IRLT,2))];
            end
            
        end
        
        % --- optimises the region grid location
        function yTube = optRegionGrid(obj,YgT,B,tPk,nTube)

            % parameters
            N = 5;
            tPerMin = 5;

            % other initialisations
            yTube = [];
            nRow = length(B);
            tPer0 = median(arr2vec(diff(tPk,[],1)));
            xiT = max(tPerMin,tPer0-N):min(ceil(nRow/nTube),tPer0+N);

            %
            nTubeG = NaN(1,length(xiT));
            isFeas = false(1,length(xiT));
            [fGrp,xi0] = deal(cell(1,length(xiT)));

            %
            for i = 1:length(xiT)
                %
                tPkT = mean(tPk,2);
                dxi = roundP(xiT(i)/2);    
                xi0{i} = (0:xiT(i):(nTube*xiT(i)))';
                xiOfs = (-dxi:((nRow+dxi)-xi0{i}(end)))';

                % determines if there are any feasible configurations
                isFeas0 = arrayfun(@(x)(all...
                                (B(min(nRow,max(1,x+xi0{i}))))),xiOfs);
                if any(isFeas0)
                    % flag that potentially this grid size is feasible
                    isFeas(i) = true;

                    % calculates the 
                    xiOfs = xiOfs(isFeas0);
                    nTubeT = arrayfun(@(x)(sum...
                                ((tPkT>x)&(tPkT<(x+xi0{i}(end))))),xiOfs);

                    % 
                    nTubeG(i) = max(nTubeT);
                    isMax = nTubeT == nTubeG(i);
                    fGrp{i} = [xiOfs(isMax),nTubeT(isMax)];
                end
            end

            % determines the feasible groupings 
            if any(isFeas)
                % reduces the grid information
                isFeasT = isFeas & (nTubeG == nanmax(nTubeG));
                [fGrp,xi0] = deal(fGrp(isFeasT),xi0(isFeasT));

                % memory allocation
                Qf = zeros(length(fGrp),1);   
                yTube0 = cell(length(fGrp),1);

                %
                for i = 1:length(fGrp)
                    % determines the refined grid placement
                    yTubeOpt = cellfun(@(x)(obj.refineGridPlacement...
                            (YgT,x,xi0{i})),num2cell(fGrp{i}(:,1)),'un',0);

                    % calculates the average signal grid points 
                    Qf0 = cellfun(@(x)(mean(YgT(x))),yTubeOpt);

                    % determines the optimal grid point placement
                    iMn = argMin(Qf0);
                    [yTube0{i},Qf(i)] = deal(yTubeOpt{iMn},Qf0(iMn));
                end

                % returns the optimal setup
                yTube = yTube0{argMin(Qf)};
            end

        end

        % --- refines the region grid location placement
        function yTube = refineGridPlacement(obj,YgT,xiOfs,xi0)

            % initialisations
            dTmax = 2;
            yTube = xiOfs + xi0;
            dxi = diff(xi0(1:2));

            %
            for i = 2:(length(yTube)-1)
                xiTnw = max(1,yTube(i)-dTmax):min(length(YgT),yTube(i)+dTmax);
                iMin = argMin(YgT(xiTnw));
                yTube(i) = xiTnw(iMin);
            end

            %
            yTube(1) = max(1,yTube(2)-dxi);
            yTube(end) = min(length(YgT),yTube(end-1)+dxi);

        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % --- optimises the sub-region placement positions
        function yTube = optSubRegionPos(obj,iApp)
           
            % initialisations            
            [tPer,nT] = deal(obj.tPerS(iApp),obj.nTube(iApp));  
            ImaxR0 = normImg(max(0,obj.ImaxR{iApp}));
            QT = smooth(sqrt(ImaxR0.^2 + obj.ImaxS{iApp}.^2));
            
            % determines the signal peaks (remove peaks at the extremes)
            [yPk,tPk] = findpeaks(QT,'MinPeakDistance',floor(0.75*tPer));
            ii = (tPk > tPer/4) & (tPk < (length(QT)-tPer/4));
            [tPk,yPk] = deal(tPk(ii),yPk(ii));
            
            % determines the peaks of the objective function signal            
            if length(tPk) > nT
                % if there are more peaks than sub-regions, then determine
                % which grouping is most likely
                [dyOfs,xiP] = deal(0:(length(tPk)-nT),(1:nT)');
                QTs = arrayfun(@(dy)(sum(yPk(xiP+dy))),dyOfs(:));                
                
                % reduces the peak count to make the sub-region count
                dyOpt = dyOfs(argMax(QTs));
                tPk = tPk(xiP+dyOpt);
                
            elseif length(tPk) < nT
                % if there are more sub-regions than peaks, then reset the
                % peak count but flag that the region could be incorrect
                [obj.nTubeBest(iApp),nT] = deal(length(tPk));
            end
            
            % determines the vertical limits of the current points
            yLim = tPk([1,end]) + roundP(tPer/2)*[-1;1];
            tPkMean = roundP(mean([tPk(1:end-1),tPk(2:end)],2));
            yTube = [yLim(1);tPkMean;yLim(2)];
            yTube = min(length(QT),max(1,yTube));
            
        end
        
        % --- reduces the object coordinates to the most likely set
        function fP = reduceObjCoords(obj,fP,iApp)
            
            % parameters
            pTol = 0.3;
            
            % calculates the relative distances between the points
            D = tril(pdist2(fP(:,2),fP(:,2)))/obj.tPerS(iApp);
            B = (D > (1-pTol)) & (D < (1+pTol));
            B(1,2) = B(2,1);
            
            % FINISH ME!
            nB = sum(B,2);
            if any(nB > 1)
                waitfor(msgbox('Finish Me!'))
            end
            
            % removes any points which isn't within 
            fP = fP(any(B,2),:);
            
        end
        
        % --- retrieves the sub-region indices
        function [iRT,iCT] = getSubRegionIndices(obj,iApp)
            
            % sets the row/column indices
            [iRT,iCT] = deal(obj.iRG{iApp},obj.iCG{iApp});
            
            % interpolates the images (if large)
            if obj.nI > 0
                iCT = iCT((obj.nI+1):(2*obj.nI):end);
                iRT = iRT((obj.nI+1):(2*obj.nI):end);
            end
            
        end          
        
        % --- performs the refined image search
        function [fP,IP] = refinedImgSeg(obj,ImgL,ImgBG,fP0,pOfs)
            
            % memory allocation            
            [W,szL] = deal(2*obj.nI,size(ImgBG));
            [fP,IP] = deal(NaN(obj.nImg,2),NaN(obj.nImg,1));
            fPT = 1 + obj.nI*(1 + 2*(fP0-1)) + repmat(pOfs,length(ImgL),1);
            
            % determines the coordinates from the refined image
            for i = 1:obj.nImg
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
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        
        % ----------------------------------- %
        % --- LOW VARIANCE PHASE ANALYSIS --- %
        % ----------------------------------- %        
        
        % --- analyses a low variance video phase
        function analyseLowVarPhase(obj,Img,iPh)

            % offsets the images (if required)
            if ~isempty(obj.dpOfs{iPh})
                dP = num2cell(obj.dpOfs{iPh},2);
                Img = cellfun(@(x,p)(calcImgTranslate(x,p)),Img,dP,'un',0);
            end

            % calculates the background estimate and residuals
            [obj.IbgT{iPh},obj.IbgT0{iPh}] = ...
                                deal(calcImageStackFcn(Img,'max'));
            IR = obj.calcResidualStack(Img,iPh);            
            
            % ----------------------------------------- %
            % --- DETECTION ESTIMATION CALCULATIONS --- %            
            % ----------------------------------------- %            
            
            try
                % detects the moving blobs 
                obj.detectMovingBlobs(Img,IR,iPh); 
            catch ME
                % if there was an error then store the details
                obj.errStr = 'moving object tracking';
                [obj.errMsg,obj.calcOK] = deal(ME.message,false);
                return
            end
            
            try
                % sets up the blob templates
                obj.setupBlobTemplate(Img,iPh);
            catch ME
                % if there was an error then store the details
                obj.errStr = 'object template calculation';
                [obj.errMsg,obj.calcOK] = deal(ME.message,false);
                return                
            end
            
            try
                % tracks the stationary blobs 
                obj.detectStationaryBlobs(Img,iPh); 
            catch ME
                % if there was an error then store the details
                obj.errStr = 'stationary object tracking';
                [obj.errMsg,obj.calcOK] = deal(ME.message,false);
                return                
            end                        
            
            % performs the phase house-keeping exercises
            obj.phaseHouseKeeping(iPh);
            
        end     
        
        % --- determines the image translation information
        function detImgTranslateInfo(obj)
            
            % determines if any phases have translation
            hasT = ~cellfun(@isempty,obj.dpOfs);
            if ~any(hasT)
                % if there is no translation info, then exit
                obj.dpInfo = [];
                return
            end
            
            % determines the global frame offset
            dpOfs0 = obj.dpOfs(hasT);
            iFrmPh = obj.iMov.iPhase(hasT,2);
            dpOfsF = cell2mat(cellfun(@(x)(x(end,:)),dpOfs0,'un',0));
            dpOfsT = [zeros(1,2);cumsum(dpOfsF(1:end-1,:),1)];
            
            % calculates the full frame translation
            dpOfsG = cell2mat(cellfun(@(x,y)([x(:,1)+y(1),x(:,2)+y(2)]),...
                                    dpOfs0,num2cell(dpOfsT,2),'un',0));
            
            % initialisations            
            iFrm = cell2mat(obj.indFrm(hasT));          
            
            % sets the details into the final struct
            obj.dpInfo = struct('iFrm',iFrm,'xFrm',dpOfsG(:,1),...
                                'yFrm',dpOfsG(:,2),'dpOfsT',dpOfsT,...
                                'iFrmPh',iFrmPh);            
            
            % updates the closes the progressbar
            obj.hProg.Update(2+obj.wOfsL,'Translation Check Complete!',1);                                        
                                      
        end
        
        % --- determines the frame group limits
        function pLim = detFrameGroupLimits(obj,IL0,pLim,pOfs,dPL,iType)

            % initialisations
            iter = 1;
            iterMx = 10;
            fTol = 0.005;
            idPL = roundP(dPL);
            
            % resets the progressbar
            wStr = 'Frame Range Check (0% Complete)';
            obj.hProg.Update(3+obj.wOfsL,wStr,0);

            % keep looping until the solution has converged
            while 1
                % updates the progressbar
                pComp = 1 - min(abs(dPL-mean(idPL)))/abs(mean(idPL));
                wStr = sprintf('Frame Range Check (%i%s Complete)',...
                                roundP(100*pComp),'%');
                if obj.hProg.Update(3+obj.wOfsL,wStr,pComp)
                    % if the user cancelled, then exit
                    obj.calcOK
                    return
                end

                % determines if the translation values are within tolerance
                if any(abs(dPL-mean(idPL)) < fTol) || (diff(pLim) == 1)
                    % if the limit border has been found then return
                    break
                else
                    % determines the new frame index
                    diFrm = ((mean(idPL)-dPL(2))*diff(pLim))/diff(dPL);
                    iFrmNw = roundP(pLim(2) + diFrm);

                    % otherwise, read in the new image and determines
                    while 1
                        % reads the new frame
                        ImgNw = obj.getImageStack(iFrmNw,1);  
                        if all(isnan(ImgNw(:)))
                            % if the frame is invalid, then get a new frame
                            iFrmNw = iFrmNw - (1-2*(iFrmNw==1));                            
                        else            
                            % otherwise, filters the image (if required)
                            if obj.useFilt
                                ImgNw = obj.filterImg(ImgNw,obj.hS);
                            end  
                            
                            % exits the loop
                            break
                        end
                    end

                    % calculates the image shift
                    dPnw = pOfs-flip(fastreg(IL0,ImgNw));        
                    iMx = roundP(dPnw(iType)) == roundP(dPL);
                    [pLim(iMx),dPL(iMx)] = deal(iFrmNw,dPnw(iType));

                    % increments the iteration counter
                    iter = iter + 1;
                    if iter > iterMx
                        pLimMn = mean(pLim);
                        pLim = floor(pLimMn)+[0,1];
                        return
                    end
                end
            end

            % returns the final limits
            iMx = argMax(abs(dPL-mean(idPL)));
            pLim(iMx) = pLim((1:2)~=iMx) + (1-2*(iMx==1));

        end
        
        % --- calculates the image residual stack values
        function IR = calcResidualStack(obj,Img,iPh)
            
            % calculates the image stack residual
            IR = cellfun(@(x)(obj.IbgT0{iPh}-x),Img,'un',0);
            
            % removes any NaN values from the image
            if ~isempty(obj.dpOfs{iPh})
                % removes any NaN pixels or pixels at the frame edge          
                for i = 1:length(IR)
                    B = bwmorph(isnan(IR{i}),'dilate',1+obj.nI);
                    IR{i}(B) = 0;
                end
            end
            
            % removes the image median
            IR = cellfun(@(x,y)(max(0,x)),IR,'un',0);
            
        end        
        
        % --- tracks the moving blobs from the residual image stack, IR
        function detectMovingBlobs(obj,I,IR,iPh)
            
            % --- tracks the movng blobs from the residual image
            function [fPos,pIR] = trackMovingBlobs(IRL,dTol)

                % initialisations
                pWT = 0.9;
                [nFrm,szL] = deal(length(IRL),size(IRL{1}));
                [fPos,pIR] = deal(NaN(nFrm,2),NaN(nFrm,1));

                % retrieves the maxima for each frame
                iGrp = cellfun(@(x)(find(imregionalmax(x))),IRL,'un',0);

                % determines the moving blob properties for each region
                for i = 1:length(IRL)
                    if ~isempty(iGrp{i})
                        % calculates the most
                        [pMx,iS] = sort(IRL{i}(iGrp{i}),'descend');
                        pTolNw = pWT*pMx(1);
                        
                        % determines how many prominent maxima there are
                        ii = pMx >= pTolNw;
                        if sum(ii) == 1
                            % case is there is one prominent maxima
                            iGrp{i} = iGrp{i}(iS(1));
                        else
                            % case is there are multiple prominent maxima
                            BL = IRL{i} >= pTolNw;
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
                
                % scales the maxima by the median pixel intensity
                Imn = cellfun(@(x)(nanmedian(x(:))),IRL);
                pIR = (pIR-Imn)./max(1,Imn);

            end
           
            % if the user cancelled, then exit
            if ~obj.calcOK; return; end
            obj.hProg.Update(2+obj.wOfsL,'Moving Object Tracking',0.25);
            obj.hProg.Update(3+obj.wOfsL,'Analysing Region',0);
            
            % attempts to calculate the coordinates of the moving objects
            nApp = length(obj.iMov.pos);
            for iApp = 1:nApp
                % updates the progress bar
                wStrNw = sprintf('Analysing Region (%i of %i)',iApp,nApp);
                if obj.hProg.Update(3+obj.wOfsL,wStrNw,iApp/(1+nApp))
                    obj.calcOK = false;
                    return
                end                

                % sets the region row/column coordinates
                [iR,iC] = deal(obj.iMov.iR{iApp},obj.iMov.iC{iApp});
                iRT = cellfun(@(x)(iR(x)),obj.iMov.iRT{iApp},'un',0);

                % tracks the blobs for each sub-region
                for iTube = find(obj.iMov.flyok(:,iApp))'
                    % calculates the most like moving blob locations
                    IL = cellfun(@(x)(x(iRT{iTube},iC)),I,'un',0);
                    IRL = cellfun(@(x)(x(iRT{iTube},iC)),IR,'un',0);
                    [fPnw,pIRNw] = trackMovingBlobs(IRL,obj.Dtol);
                    
                    % sets the tracked coordinates
                    if ~isempty(fPnw)                        
                        % retrieves the point image/residual values 
                        obj.pStats.IR{iApp,iPh}(iTube,:) = pIRNw;
                        obj.pStats.I{iApp,iPh}(iTube,:) = cellfun(@(x,i)...
                                  (x(sub2ind(size(x),i(2),i(1)))),...
                                  IL,num2cell(fPnw,2)); 
                              
                        % updates the sub-region coordinates
                        obj.setSubRegionCoord(fPnw,[iPh,iApp,iTube]);                              
                    end
                end
            end           
            
            % updates the progressbar
            obj.hProg.Update(3+obj.wOfsL,'Region Analysis Complete',1);            
            
        end
        
        % --- sets up the blob template images
        function setupBlobTemplate(obj,I,iPh)
            
            % if the user cancelled, then exit
            if ~obj.calcOK; return; end              
            
            % parameters and memory allocation
            dN = 20;
            usePTolMn = 0.1;
            fP = obj.fPosL{iPh};
            Isub = cell(size(fP));
            [nApp,nFrm] = size(fP);
            [iOfs,obj.useP] = deal(0,zeros(max(obj.nTube),nApp));
            
            % updates the progressbar
            wStrNw = 'Object Template Calculations';
            obj.hProg.Update(2+obj.wOfsL,wStrNw,0.50);
            obj.hProg.Update(3+obj.wOfsL,'Analysing Region',0);
            
            % -------------------------------- %
            % --- FLY TEMPLATE CALCULATION --- %
            % -------------------------------- %

            % calculates the sub-image weights 
            %  => favours blobs with higher residual values
            pP = obj.pStats.IR(:,iPh);
            pITot = cell2mat(pP);
            Zmx = prctile(pITot(:),obj.pTile);
            
            % calculates the cdf probabilities for the point residuals
            obj.pQ0{iPh} = combineNumericCells...
                    (cellfun(@(x)(nanmedian(x/Zmx,2)),pP(:)','un',0)');
            obj.useP = obj.pQ0{iPh} > obj.usePTol;  
            
            % if the number of residual points is low, and there is
            % previous template data, then use that instead
            if mean(obj.useP(:)) < usePTolMn
                resetPara = true;
                if isfield(obj.iMov,'tPara') && ~isempty(obj.iMov.tPara)
                    [obj.tPara{iPh},resetPara] = deal(obj.iMov.tPara,0);                    
                end
                
                % if the parameter reset is required, then use the template
                % from the other images
                if resetPara
                    Itemp = setupWeightedTemplateImage(obj);
                    [GxT,GyT] = imgradientxy(Itemp,'sobel');
                    obj.tPara{iPh} = ...
                            struct('Itemp',Itemp,'GxT',GxT,'GyT',GyT);
                end
                
                % updates the progressbar and exits
                obj.hProg.Update(3+obj.wOfsL,'Region Analysis Complete',1);
                return
            end
                                    
            % determines which sub-images to use for the template   
            for iApp = 1:nApp
                % updates the progress bar
                wStrNw = sprintf('Analysing Region (%i of %i)',iApp,nApp);
                if obj.hProg.Update(3+obj.wOfsL,wStrNw,iApp/(1+nApp))
                    obj.calcOK = false;
                    return
                end                             
                
                % calculates the sub-region offsets
                [iR,iC] = deal(obj.iMov.iR{iApp},obj.iMov.iC{iApp});
                yOfs = cellfun(@(x)(iR(x(1))),obj.iMov.iRT{iApp});
                pOfs = [iC(1)*ones(length(yOfs),1),yOfs];
                
                %
                xiP = 1:obj.nTube(iApp);
                usePL = num2cell(obj.useP(xiP,iApp));

                % calculates the weighted maxima point sub-images
                for iFrm = 1:nFrm
                    Isub{iApp,iFrm} = cellfun(@(x,ok)...
                            (obj.getPointSubImage(I{iFrm},x,dN,ok)),...
                            num2cell(fP{iApp,iFrm}+pOfs,2),usePL,'un',0);
                end
            end

            % calculates the template image from the estimated image
            Itemp = calcImageStackFcn(cell2cell(Isub(:)),'mean');
            [GxT,GyT] = imgradientxy(Itemp,'sobel'); 

            % sets the template stucts
            obj.tPara{iPh} = struct('Itemp',Itemp,'GxT',GxT,'GyT',GyT);
            
            % updates the progressbar
            obj.hProg.Update(3+obj.wOfsL,'Region Analysis Complete',1);            
            
        end               
        
        % --- tracks the stationary blobs objects
        function detectStationaryBlobs(obj,I,iPh)
            
            % if the user cancelled, then exit
            if ~obj.calcOK; return; end       
            
            % updates the progressbar
            wStrNw = 'Stationary Object Tracking';
            obj.hProg.Update(2+obj.wOfsL,wStrNw,0.75); 
            obj.hProg.Update(3+obj.wOfsL,'Analysing Sub-Region',0);

            % sets the status flag array
            %  1) moving
            %  2) stationary
            %  3) rejected
            obj.sFlag{iPh} = double(~obj.useP) + 1;
            obj.sFlag{iPh}(~obj.iMov.flyok) = 3;            

            % estimates the object shape
            obj.iMov.szObj = obj.calcObjShape(obj.tPara{iPh}.Itemp);            
            
            % calculates the location of any stationary/low res sub-regions
            if any(~obj.useP(:) & obj.iMov.flyok(:))
                % retrieves the template x/y gradient masks
                [GxT,GyT] = deal(obj.tPara{iPh}.GxT,obj.tPara{iPh}.GyT);                 
                
                % loops through each of the probable stationary regions 
                % determining the most likely blob objects 
                [iTube,iApp] = find(~obj.useP);
                
                nTube = length(iTube);
                for i = 1:nTube
                    % updates the progress bar
                    wStrNw = sprintf('Analysing Sub-Region (%i of %i)',...
                                      i,nTube);
                    if obj.hProg.Update(3+obj.wOfsL,wStrNw,i/(1+nTube))
                        obj.calcOK = false;
                        return
                    end                                 
                    
                    % retrieves the image stack for the sub-region 
                    [j,k] = deal(iTube(i),iApp(i));
                    iC = obj.iMov.iC{k};
                    iRT = obj.iMov.iR{k}(obj.iMov.iRT{k}{j});
                    IL = cellfun(@(x)(x(iRT,iC)),I,'un',0);

                    % calculates the gradient cross-correlation image 
                    % stack (multiplies by the complimentary of the 
                    % filtered image)
                    fP0 = cell2mat(cellfun(@(x)(x(j,:)),...
                                        obj.fPosL{iPh}(k,:),'un',0)');
                    IxcL = obj.calcXCorrImgStack(IL,GxT,GyT,obj.hS);
                    
                    if obj.pQ0{iPh}(j,k) < obj.pTolStat || ...
                            all(range(fP0) < obj.iMov.szObj/2)
                        % case is the object is most likely stationary
                        ILmn = calcImageStackFcn(IL);
                        IxcLmn = calcImageStackFcn(IxcL);
                        
                        % calculates the overall 
                        fPnw0 = obj.calcLikelyXcorrBlobs(ILmn,IxcLmn);
                        fPnw = repmat({fPnw0},[length(IL),1]);
                    else
                        % case is the object probably stationary
                        fPnw = cellfun(@(x,y)...
                           (obj.calcLikelyXcorrBlobs(x,y)),IL,IxcL,'un',0);
                    end
                     
                    % estimates the sub-region background image
                    IbgL = obj.estSubRegionBG(IL,cell2mat(fPnw));
                    obj.IbgT{iPh}(iRT,iC) = IbgL;
                    
                    % retrieves the image/x-corr values for the points
                    obj.pStats.I{k,iPh}(j,:) = cellfun(@(x,i)...
                                    (obj.getPixelValue(x,i,0)),IL,fPnw);
                            
                    % sets the most likely static blob locations
                    for iFrm = 1:length(fPnw)
                        obj.fPosL{iPh}{k,iFrm}(j,:) = fPnw{iFrm};
                    end

                    % resets the status flag
                    obj.sFlag{iPh}(j,k) = 1 + ...
                                   all(range(cell2mat(fPnw)) <= obj.Dtol);
                end
            end            
            
            % updates the progressbar
            obj.hProg.Update(3+obj.wOfsL,'Sub-Region Analysis Complete',1);
            
        end
        
        % --- estimates the missing region in the background image
        function IbgLmn = estSubRegionBG(obj,I,fP)
                        
            % memory allocation
            sz = size(I{1});
            szObj = obj.iMov.szObj;
            IbgL = cell(size(I));
            IoptN = normImg(obj.Iopt).^0.5;
            xiN = (1:size(obj.Iopt,1)) - ((size(obj.Iopt,1)-1)/2+1);            

            % sets up the x/y coordinate arrays        
            [X,Y] = meshgrid(1:sz(2),1:sz(1));

            % fill in the regions surrounding the points
            for i = 1:length(I)    
                % sets up the image weighting array
                Qw = zeros(sz);
                [iR,iC] = deal(fP(i,2)+xiN,fP(i,1)+xiN);
                [ii,jj] = deal((iR > 0) & (iR < sz(1)),(iC > 0) & (iC < sz(2)));    
                Qw(iR(ii),iC(jj)) = IoptN(ii,jj);

                % sets up the fill image
                [dX,dY] = deal(X-fP(i,1),Y-fP(i,2));
                B = ((dX/szObj(1)).^2 + (dY/szObj(2)).^2) <= 1;    
                Ifill = regionfill(I{i},B);

                % sets the background image
                IbgL{i} = Qw.*Ifill + (1-Qw).*I{i};
            end
            
            % calculates the mean of the image stack
            IbgLmn = calcImageStackFcn(IbgL); 
            
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
        
        % ------------------------------------ %
        % --- HIGH VARIANCE PHASE ANALYSIS --- %
        % ------------------------------------ %        
        
        % --- analyses a high variance video phase
        function analyseHighVarPhase(obj,Img,iPh)
                       
            % initialisations            
            nApp = size(obj.fPosL{iPh},1);
            fPosS = cell(nApp,2);
            isLoV = obj.iMov.vPhase == 1;               
            
            % calculates the overall template image
            Itemp = obj.setupWeightedTemplateImage();
            [GxT,GyT] = imgradientxy(Itemp);
            
            % sets the previous phase coordinates            
            if iPh > 1
                if isLoV(iPh-1)
                    fPosS(:,1) = obj.fPosL{iPh-1}(:,end);
                end
            end
            
            % sets the processing phase coordinates
            if iPh < length(obj.indFrm)
                if isLoV(iPh+1)
                    fPosS(:,2) = obj.fPosL{iPh+1}(:,1);
                end
            end
            
            % determines the most likely blobs for each region/frame
            for i = 1:nApp
                % updates the progress bar
                wStrNw = sprintf('Analysing Region (%i of %i)',i,nApp);
                if obj.hProg.Update(2+obj.wOfsL,wStrNw,i/(1+nApp))
                    obj.calcOK = false;
                    return
                end  
                
                % sets up the sub-image stacks
                [iR,iC] = deal(obj.iMov.iR{i},obj.iMov.iC{i});
                IL = cellfun(@(x)(x(iR,iC)),Img,'un',0);
                IxcL = obj.calcXCorrImgStack(IL,GxT,GyT,obj.hS);
                
                % calculates the 
                iRT = obj.iMov.iRT{i};
                nTube = length(iRT);
                for j = 1:nTube
                    % updates the progress bar
                    wStrNw = sprintf('Analysing Sub-Region (%i of %i)',...
                                     j,nTube);
                    if obj.hProg.Update(3+obj.wOfsL,wStrNw,j/(1+nTube))
                        obj.calcOK = false;
                        return
                    end                      
                    
                    % retrieves the sub-region image/x-corr masks
                    ISR = cellfun(@(x)(x(iRT{j},:)),IL,'un',0);
                    IxcSR = cellfun(@(x)(x(iRT{j},:)),IxcL,'un',0);
                    
                    % sets up the point distance mask
                    QD = obj.setupPointDistMask(ISR,fPosS(i,:),j);
                    
                    % calculates the likely blob locations
                    fPnw = cellfun(@(x,y,z)(obj.calcLikelyXcorrBlobs...
                                        (x,y,z)),ISR,IxcSR,QD,'un',0);
                                    
                    % retrieves the image/x-corr values for the points
                    obj.pStats.I{i,iPh}(j,:) = cellfun(@(x,i)(x...
                                (sub2ind(size(x),i(2),i(1)))),ISR,fPnw);                    
                    obj.pStats.Ixc{i,iPh}(j,:) = cellfun(@(x,i)(x...
                                (sub2ind(size(x),i(2),i(1)))),IxcSR,fPnw);
                                    
                    % set the sub-region coordinates
                    obj.setSubRegionCoord(cell2mat(fPnw),[iPh,i,j]);
                end                
            end
            
            % updates the progressbar
            obj.hProg.Update(2+obj.wOfsL,'Region Analysis Complete',1);
            obj.hProg.Update(3+obj.wOfsL,'Sub-Region Analysis Complete',1);
            
        end          
        
        % ------------------------- %
        % --- TESTING FUNCTIONS --- %
        % ------------------------- %

        % --- plots the image frame coordinates
        function plotImageFrame(obj,Img,iPh,iFrm)

            % retrieves the frame coordinates
            fP = obj.fPosL{iPh}(:,iFrm);

            % creates the image figure
            plotGraph('image',Img{iFrm})
            hold on

            % plots the locations for all objects in the region
            for i = 1:length(fP)
                % sets the row/column indices
                [iR,iC] = deal(obj.iMov.iR{i},obj.iMov.iC{i});
                iRT = obj.iMov.iRT{i};

                % plots the location of all the points
                pOfs = [iC(1),iR(1)]-1;
                for j = 1:size(fP{i},1)
                    yOfs = iRT{j}(1)-1;
                    plot(fP{i}(j,1)+pOfs(1),fP{i}(j,2)+(pOfs(2)+yOfs),...
                                        'go','markersize',12)
                end
            end

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
            tP = obj.iMov.tPara;
            bgP = obj.iMov.bgP.pSingle;            
            nMet = length(fieldnames(obj.pStats));
            [tData,obj.pData] = deal(cell(nMet,1));
            wStr0 = {'Tracking Quality Calculations','Analysing Frame'};
            
            % resets the waitbar figure
            for i = 1:length(wStr0)
                obj.hProg.Update(1,wStr0{i},0);
            end
            
            % collapses the progress bar by one level
            obj.hProg.collapseProgBar(1)
            pause(0.05);
            
            % sets up the image filter object
            if bgP.useFilt
                obj.hS = fspecial('disk',bgP.hSz); 
            else
                obj.hS = [];
            end
            
            % sets the residual/intensity values
            tData{1} = obj.pStats.IR;
            tData{2} = obj.pStats.Ixc;
            tData{3} = obj.pStats.I;   
            
            % sets the data values for each of the phases
            for iPh = 1:obj.nPhase
                % updates the progressbar
                wStr = sprintf('%s (%i of %i)',wStr0{1},iPh,obj.nPhase);
                if obj.hProg.Update(1,wStr,iPh/obj.nPhase)
                    % if the user cancelled, then exit
                    obj.calcOK = false;
                    return
                end
                
                % determines if there are any missing data values
                fP = obj.fPos{iPh};
                nFrm = size(fP,2);                               
                iFrm = obj.indFrm{iPh};
                nPhase = length(obj.iMov.vPhase);
                tDArr = cell2mat(tData{2}(:,iPh));                 
                fok = repmat(num2cell(obj.iMov.flyok,1)',1,nPhase);
                
                % determines the frames that need recalculation
                for i = find(any(isnan(tDArr),1))
                    % updates the progressbar
                    wStr = sprintf('%s (%i of %i)',wStr0{2},i,nFrm);
                    if obj.hProg.Update(2,wStr,i/nFrm)
                        % if the user cancelled, then exit
                        obj.calcOK = false;
                        return
                    end                    
                    
                    % calculates the full image 
                    I = double(getDispImage(obj.iData,obj.iMov,iFrm(i),0));
                    if ~isempty(obj.hS); I = obj.filterImg(I,obj.hS); end
                    
                    % calculates the image cross-correlation
                    Ixc0 = obj.calcXCorrImgStack(I,tP.GxT,tP.GyT,obj.hS);   
                    
                    % sets the point cross-correlation values
                    for j = 1:size(fP,1)
                        fPL = roundP(obj.fPosG{iPh}{j,i});
                        tData{2}{j,iPh}(:,i) = ...
                                        obj.getPixelValue(Ixc0{1},fPL);
                    end
                end
                
                % calculates the metric z-score probabilities
                for i = 1:nMet
                    % calculates the phase metrics mean/std values
                    Ytot = cell2mat(cellfun(@(x,i)(x(i,:)),...
                                            tData{i},fok,'un',0));
                    [Ymn,Ysd] = deal(nanmean(Ytot(:)),nanstd(Ytot(:)));
                    
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
            obj.pStats.Ixc = tData{2}; 
            
            % pixel tolerances
            [pTolQ,pTolQ2] = deal(10,20);
            isAnom = false(size(obj.iMov.flyok)); 
            Qval = zeros(size(obj.iMov.flyok)); 
            
            % determines which sub-region appear to be empty
            for i = 1:length(obj.pData{1})
                % groups the metrics and calculates the max/median
                A = cellfun(@(y)(cell2mat(y(i,:))),obj.pData,'un',0)';
                Amd = cell2mat(cellfun(@(x)(median(x,2)),A,'un',0));
                
                % determines which objects have low overall scores
                nT = size(Amd,1);
                isAnom(1:nT,i) = (Amd(:,1) < pTolQ) & ...
                            ((Amd(:,2) < pTolQ) | ...
                            ((Amd(:,3) < pTolQ) & (Amd(:,2) < pTolQ2)));
                Qval(1:nT,i) = mean([Amd(:,1),min(Amd(:,2:3),[],2)],2);
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
                eObj = EmptyCheck(roundP(Qval,0.1),isAnom);                
                
                % resets the status flags for all flagged sub-regions
                for i = find(eObj.isEmpty(:)')
                    % sets the region/sub-region indices
                    [iApp,iTube] = deal(eObj.iApp(i),eObj.iTube(i));
                    
                    % updates the status flags
                    obj.iMov.flyok(iTube,iApp) = false;
%                     for j = 1:length(obj.iMov.StatusF)
%                         obj.iMov.StatusF{j}(iTube,iApp) = 3;
%                     end
                    
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
        
        % --- interpolates any missing offset frames
        %       => extremely rare case - occurs frames are "missing"
        function interpMissingOffsets(obj,iPh)

            % of there are no missing
            if all(obj.iOK{iPh}); return; end

            % initialisations
            [ii,xi] = deal(obj.iOK{iPh},1:length(obj.iOK{iPh}));                        
            for j = 1:2
                obj.dpOfs{iPh}(~ii,j) = interp1...
                            (xi(ii),obj.dpOfs{iPh}(ii),xi(~ii),'pchip');
            end
        end   
        
        % --- get the pixel values the coordinates, fP
        function IP = getPixelValue(obj,I,fP,isMax)
            
            % sets the default input arguments
            if ~exist('isMax','var'); isMax = true; end
            
            % sets the neighbourhood size
            if ~isfield(obj.iMov,'szObj') || any(isnan(obj.iMov.szObj))
                N = 5;
            else
                N = min(floor(obj.iMov.szObj/2));
            end
            
            % memory allocation
            isOK = ~isnan(fP(:,1));            
            IsubS = cellfun(@(x)(obj.getPointSubImage(I,x,N)),...
                                            num2cell(fP(isOK,:),2),'un',0);
            
            % determines the min/max values surrounding the point
            IP = NaN(size(fP,1),1);
            if isMax
                IP(isOK) = cellfun(@(x)(nanmax(x(:))),IsubS);
            else
                IP(isOK) = cellfun(@(x)(nanmin(x(:))),IsubS);
            end
        end          
        
    end    
    
    % class static methods
    methods (Static)
        
        function ImgF = filterImg(Img,hS)
           
            ImgF = imfilter(Img,hS,'symmetric');
            
        end                
        
        % --- groups the row indices
        function iGrp = groupRowIndices(iGrp)
            
            % parameters
            dyTol = 0.2;
            
            % determines the distance between the groupings
            yGrpMn = cellfun(@mean,iGrp);
            dyGrpMd = median(diff(yGrpMn));
            D = tril(pdist2(yGrpMn,yGrpMn))/dyGrpMd;
            
            % reduces down any groups that 
            B = (D > (1-dyTol)) & (D < (1+dyTol));
            B(1,2) = B(2,1);
            iGrp = iGrp(any(B,2));
            
        end         
       
        % --- tracks the static blobs for the automatic detection
        function fP = trackAutoStaticBlobs(I,iRT)
            
            % initialisations
            yOfs = cellfun(@(x)(x(1)-1),iRT);
            IL = cellfun(@(x)(I(x,:)),iRT,'un',0);
            
            % calculates the most likely object in the region
            fP = cell2mat(cellfun(@(x)(getMaxCoord(x)),IL,'un',0));
            fP(:,2) = fP(:,2) + yOfs;
            
        end                        
        
        % --- calculates the most likely objects from the row groups
        function fPos = trackAutoMovingBlobs(IR,iGrp)

            % sets the group sub-images
            IRT = cellfun(@(x)(IR(x,:)),iGrp,'un',0);

            % retrieves the coordinates
            fPos = cell2mat(cellfun(@(x)(getMaxCoord(x)),IRT,'un',0));
            fPos(:,2) = fPos(:,2) + cellfun(@(x)(x(1)-1),iGrp);

        end           
        
        % --- calculates the coordinates of the likely static blobs
        function fPosS = calcLikelyXcorrBlobs(IL,IxcL,Qw)

            % sets up the objective functon mask
            QL = (1-normImg(IL)).*IxcL;
            if exist('Qw','var'); QL = QL.*Qw; end
            
            % calculates the coordinate of the max-coord
            fPosS = getMaxCoord(QL);
            
        end

        % --- calculates the gradient mask cross-correlation
        function Ixc = calcXCorrImgStack(IL,GxT,GyT,hS)

            % ensures the image array is a cell array
            if ~iscell(IL); IL = {IL}; end
            
            % memory allocation
            Ixc = cell(length(IL),1);

            % calculates the gradient correlation masks
            for i = 1:length(IL)
                % calculates the x/y image gradients
                [Gx,Gy] = imgradientxy(IL{i},'sobel');
                B = isnan(Gx) & isnan(Gy);
                [Gx(B),Gy(B)] = deal(0);
                
                % calculates the combined gradient cross-correlation
                Ixc0 = max(0,calcXCorr(GxT,Gx) + calcXCorr(GyT,Gy));
                
                % sets the final image
                if isempty(hS)
                    % case is the image is not filtered
                    Ixc{i} = Ixc0/2;
                else
                    % case is the image is filtered
                    Ixc{i} = imfilter(Ixc0,hS,'symmetric')/2;
                end
            end

        end
        
        % --- calculates the x/y gradient masks for the image stack, IL
        function [Gx,Gy] = calcImgStackGrad(IL)
            
            % memory allocation
            [Gx,Gy] = deal(cell(length(IL),1));
            
            % calculates the x/y image gradients
            for i = 1:length(IL)
                [Gx{i},Gy{i}] = imgradientxy(IL{i},'sobel');
            end
            
        end
        
        % --- sets up the point distance mask
        function QD = setupPointDistMask(IL,fPosS,iTube)
            
            % memory allocation
            hD = 1;
            szL = size(IL{1});
            dScale = max(szL);
            [fP,DB] = deal(cell(1,2));
            QD = repmat({ones(szL)},length(IL),1);
            
            % sets up the distance mask for the 1st frame
            if ~isempty(fPosS{1})                
                fP{1} = fPosS{1}(iTube,:);
                DB{1} = bwdist(setGroup(fP{1},szL))/dScale;
                QD{1} = (1./(1+DB{1})).^hD;
            end
            
            % sets up the distance mask for the last frame
            if ~isempty(fPosS{2})                
                fP{2} = fPosS{2}(iTube,:);
                DB{2} = bwdist(setGroup(fP{2},szL))/dScale;
                QD{end} = max(QD{end},(1./(1+DB{2})).^hD);
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
        
        % --- calculates the initial frame groups
        function [dpOfs,iFrm] = setupFrameGroups(iFrm0,dpOfs0,dpTol)

            % calculates the 
            dpMax = roundP(dpOfs0(end),dpTol);
            dpOfs = (0:sign(dpMax)*dpTol:dpMax)';            

            % calculates the approximate location of the limits
            dpOfsH = nanmean([dpOfs(1:end-1),dpOfs(2:end)],2);
            iFrm = roundP(interp1(dpOfs0,iFrm0,dpOfsH,'pchip'));
        end
        
        % --- determines the feasible grid placements for a signal with a
        %     peaks given at tPk at a spacing of tPer
        function fGrp = optIndivGridPlacement(tPk,nT,nR,tPer)

            % sets the groupings
            fGrp = [];

            % sets the grid offset/indices
            xiT = (0:tPer:(nT*tPer))';
            xi0 = (1:(nR-xiT(end)))';

            % if there is so feasible points then exit
            if isempty(xi0); return; end

            % calculates the number of peaks within each grid sub-region
            Z = cell2mat(arrayfun(@(y)...
                    (arrayfun(@(x)(sum(tPk<x)),xiT+y)),xi0,'un',0)');
            dZ = diff(Z,[],1);

            % determines the feasible groupings (only have one fly/region)
            isOK = ~any(dZ > 1,1) & (Z(1,:) < nT);
            if any(isOK)
                % calculates the minimum distance from a signal peak to 
                % region edge
                B = setGroup(tPk,[nR,1]);
                D = double(bwdist(B));
                DZ = arrayfun(@(x)(min(D(x+xiT))),xi0(isOK));

                % store the grouping information only if a region edge is 
                % not intersecting a signal peak
                if any(DZ > 0)        
                    nEmpty = sum(dZ(:,isOK)==0,1)';
                    fGrp = [xi0(isOK),diff(Z([1,end],isOK),[],1)',DZ,nEmpty];
                    fGrp = fGrp(fGrp(:,2)==max(fGrp(:,2)),:);
                end
            end 
            
        end        
        
    end
end
