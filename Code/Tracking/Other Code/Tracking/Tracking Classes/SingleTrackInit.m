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
        
        % other important fields
        pQ0
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
        prData0 = [];
        
        % parameters
        usePTol = 0.5;
        pTolShape = 0.1; 
        pTolStat = 0.35;
        pTile = 90;
        
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
            
            % array dimensioning
            nPh = length(obj.Img);
            nT = getSRCountVec(obj.iMov);
            
            % phase dependent object memory allocation
            A = cell(nPh,1);           
            [obj.Ibg,obj.Ibg0] = deal(A);
            [obj.IbgT,obj.IbgT0] = deal(A);
            [obj.sFlag,obj.tPara,obj.pQ0] = deal(A);            
            
            % other memory allocation
            obj.fPosL = cellfun(@(x)(repmat(arrayfun(@(n)(NaN(n,2)),...
                              nT(:),'un',0),1,length(x))),obj.Img,'un',0);
                              
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

                % reads the initial images            
                obj.Img = cell(nPh,1);
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
                        obj.Img{i} = obj.getImageStack(obj.indFrm{i});                         
                        if obj.useFilt
                            obj.Img{i} = cellfun(@(x)...
                                (imfilter(x,obj.hS)),obj.Img{i},'un',0);
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
                        
            % initialises the tracking objects
            obj.initTrackingObjects('InitEstimate');                    
            
            % retrieves the frame/image stack arrays
            obj.getTrackingImages(); 
            obj.initDetectFields();
            
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
            obj.iMov.tPara = obj.setupTemplateImage();
            obj.iMov.szObj = obj.calcObjShape();
            
            % calculates the residual detection tolerances
            obj.setupResidualTolerances();
                        
            % calculates the overall quality of the flies (prompting the
            % user to exclude any empty/anomalous regions)
            okPh = obj.iMov.vPhase < 3;
            if ~obj.isBatch && any(okPh)
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
        
        % --- resets up the residual tolerances (low-variance phase only)
        function setupResidualTolerances(obj)
            
            
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
                        obj.analyseLowVarPhase(obj.Img{i},i);
                        
                    case 2
                        % case is a low-variance phase
                        obj.analyseHighVarPhase(obj.Img{i},i); 
                        
                end
                
                % calculates the global coordinates
                obj.calcGlobalCoords(i);
            end
            
            % updates the progressbar
            wStrF = 'Initial Detection Complete!';
            obj.hProg.Update(1+obj.wOfsL,wStrF,1);
            
        end
        
        % ----------------------------------- %
        % --- LOW VARIANCE PHASE ANALYSIS --- %
        % ----------------------------------- %
        
        % --- analyses a low variance video phase
        function analyseLowVarPhase(obj,Img,iPh)
                       
            % calculates the mean of the phase image stack
            Imean = calcImageStackFcn(Img);                        
            
            % calculates the removes the mean image baseline from the stack
            ImeanT = nanmean(Imean(:));
            ImgEq = cellfun(@(x)(x-(nanmean(x(:))-ImeanT)),Img,'un',0);      

            % calculates the background estimate and residuals
            [obj.IbgT{iPh},obj.IbgT0{iPh}] = ...
                                deal(calcImageStackFcn(ImgEq,'max'));
            IR = cellfun(@(x)(obj.IbgT0{iPh}-x),ImgEq,'un',0);

            % detects the moving blobs 
            obj.detectMovingBlobs(ImgEq,IR,iPh); 
            
            % sets up the blob templates
            obj.setupBlobTemplate(ImgEq,iPh);
            
            % tracks the stationary blobs 
            obj.detectStationaryBlobs(ImgEq,iPh);  
            
            % performs the phase house-keeping exercises
            obj.phaseHouseKeeping(iPh);
            
        end      
        
        % --- tracks the moving blobs from the residual image stack, IR
        function detectMovingBlobs(obj,I,IR,iPh)
            
            % --- tracks the movng blobs from the residual image
            function [fPos,pIR] = trackMovingBlobs(IRL,dTol)

                % initialisations
                pW = 0.90;
                [nFrm,szL] = deal(length(IRL),size(IRL{1}));
                [fPos,pIR] = deal(NaN(nFrm,2),NaN(nFrm,1));

                % retrieves the maxima for each frame
                iGrp = cellfun(@(x)(find(imregionalmax(x))),IRL,'un',0);

                % determines the moving blob properties for each region
                for i = 1:length(IRL)
                    if ~isempty(iGrp{i})
                        % calculates the most
                        [pMx,iS] = sort(IRL{i}(iGrp{i}),'descend');
                        pTolNw = pW*pMx(1);
                        
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
            nApp = length(obj.iMov.iR);
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
            fP = obj.fPosL{iPh};
            Isub = cell(size(fP));
            [nApp,nFrm] = size(fP);

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
            [obj.pQ0{iPh},pQ] = deal(cell2mat(cellfun(@(x)...
                                        (max(x/Zmx,[],2)),pP,'un',0)'));
            obj.useP = pQ > obj.usePTol;    
            
            % if the number of residual points is low, and there is
            % previous template data, then use that instead
            if mean(obj.useP(:)) < 0.1
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
                usePL = num2cell(obj.useP(:,iApp));

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

            if any(~obj.useP(:))
                % retrieves the template x/y gradient masks
                [GxT,GyT] = deal(obj.tPara{iPh}.GxT,obj.tPara{iPh}.GyT); 
                obj.iMov.szObj = obj.calcObjShape(obj.tPara{iPh}.Itemp);
                
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
                    obj.pStats.I{k,iPh}(j,:) = cellfun(@(x,i)(x...
                                (sub2ind(size(x),i(2),i(1)))),IL,fPnw);

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
            
            % memory allocation            
            [~,nFrm] = size(obj.fPosL{iPh});
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
                    obj.isOK = false;
                    return
                end
                
                % determines if there are any missing data values
                fP = obj.fPos{iPh};
                nFrm = size(fP,2);
                tDArr = cell2mat(tData{2}(:,iPh));                
                iFrm = obj.indFrm{iPh};
                
                % determines the frames that need recalculation
                for i = find(any(isnan(tDArr),1))
                    % updates the progressbar
                    wStr = sprintf('%s (%i of %i)',wStr0{2},i,nFrm);
                    if obj.hProg.Update(2,wStr,i/nFrm)
                        % if the user cancelled, then exit
                        obj.isOK = false;
                        return
                    end                    
                    
                    % calculates the full image 
                    I = double(getDispImage(obj.iData,obj.iMov,iFrm(i),0));
                    if ~isempty(obj.hS); I = imfilter(I,obj.hS); end
                    
                    % calculates the image cross-correlation
                    Ixc0 = obj.calcXCorrImgStack(I,tP.GxT,tP.GyT,obj.hS);   
                    
                    % sets the point cross-correlation values
                    for j = 1:size(fP,1)
                        fPL = roundP(obj.fPosG{iPh}{j,i});
                        iPos = sub2ind(size(Ixc0{1}),fPL(:,2),fPL(:,1));
                        tData{2}{j,iPh}(:,i) = Ixc0{1}(iPos);
                    end
                end
                
                % calculates the metric z-score probabilities
                for i = 1:nMet
                    % calculates the phase metrics mean/std values
                    Ytot = cell2mat(tData{i}(:,iPh));
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
        
    end    
    
    % class static methods
    methods (Static)
        
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
                % calculates the raw cross-correlation image
                [Gx,Gy] = imgradientxy(IL{i},'sobel');
                Ixc0 = max(0,calcXCorr(GxT,Gx) + calcXCorr(GyT,Gy));
                
                % sets the final image
                if isempty(hS)
                    % case is the image is not filtered
                    Ixc{i} = Ixc0/2;
                else
                    % case is the image is filtered
                    Ixc{i} = imfilter(Ixc0,hS)/2;
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
        
    end
end
