classdef SingleTrackInit < SingleTrack
    % class properties
    properties    
        
        % threshold parameters
        pMaxR = 0.25;            
        sdTol = 0.35;
        pbTol = 0.20;        
        
        % other fields
        Qval
        prData0 = [];
        sdSE = ones(5);
        Img0
        
        % quality metric boltzmann curve parameters
        hQ = 5;
        kQ = 4;
        Qtol = 50;
        
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
        
        % --- calculates the initial fly location/background estimates
        function calcInitEstimate(obj,iMov,hProg)
            
            % sets the input variables
            obj.iMov = iMov;
            obj.hProg = hProg;
            
            % other initialisations
            wStr0 = obj.hProg.wStr;  
            nPhase = length(obj.iMov.vPhase);          
                        
            % initialises the tracking objects
            obj.initTrackingObjects('InitEstimate');      
            
            % retrieves the frame/image stack arrays
            [iFrm,Img] = obj.getTrackingImages();            
            
            % initial detection of the moving objects over the video
            [fPos,sFlag,rFlag] = initResidualDetect(obj,Img,iFrm);
            switch rFlag
                case 0
                    % if the initial detection was feasible (and there are
                    % moving objects within the video) then update the 
                    % tracking class objects with this information     
                    
%                     % calculates the object shape (must have 1 moving obj)
%                     if any(sFlag(:)==1)
%                         szObj = optObjectShapeRes(iMov,Img,fPos,sFlag);
%                     end

                    % sets the positional values
                    for i = 1:nPhase
                        % sets the potential object coordinates
                        pMaxNw = fPos{i};
                        for j = 1:numel(pMaxNw)
                            pMaxNw{j} = num2cell(pMaxNw{j},2);
                        end

                        % sets the tracking object classfields
                        obj.fObj{i}.setClassField('fPos',fPos{i})
                        obj.fObj{i}.setClassField('pMax',pMaxNw)                    
                        obj.fObj{i}.setClassField('calcRes',false)
                        obj.fObj{i}.setClassField('szObj',NaN)
                    end
                    
                case -1
                    % case is the user cancelled so exit the function
                    obj.calcOK = false;
                    return
                    
                case -2
                    % case is there was an error or no moving objects so
                    % run the direct detection in full
                    obj.iMov.IbgT = [];                
            end
            
            % loops through each phase calculating the initial estimates
            for i = find(obj.iMov.vPhase(:)' < 3)
                % updates the overall progress 
                wStr = sprintf(...
                    'Initial Estimate Progress (Phase %i of %i)',i,nPhase);
                obj.hProg.Update(1+obj.wOfsL,wStr,i/(1+nPhase));
                
                % resets the other progressbar fields (for phases > 1)
                if i > 1                    
                    for j = obj.wOfsL + (2:3)
                        obj.hProg.Update(j,wStr0{j},0);
                    end
                end               
                
                % resets the status flag fields
                for j = 1:3
                    obj.iMov.StatusF{i}(sFlag==j) = j;
                end
                                
                % sets the class fields for the tracking object
                obj.fObj{i}.setClassField('Img',Img{i});
                obj.fObj{i}.setClassField('iMov',obj.iMov);
                obj.fObj{i}.setClassField('wOfs',1+obj.wOfsL);
                obj.fObj{i}.setClassField('iPh',i)
                obj.fObj{i}.setClassField('vPh',obj.iMov.vPhase(i)) 
                obj.fObj{i}.setClassField('iStatus',double(sFlag==1)) 
                
                % sets the initial object locations
                if i == 1
                    % case is the first frame
                    obj.fObj{i}.setClassField('prData',obj.prData0);
                    
                elseif obj.iMov.vPhase(i-1) == 3
                    % case is the previous phase is high-variance
                    obj.fObj{i}.setClassField('prData',[]); 
                    
                else
                    % case is the sub-sequent phases
                    prDataNw = obj.getPrevPhaseData(obj.fObj{i-1});
                    obj.fObj{i}.setClassField('prData',prDataNw);
                end                
                
                % runs the direct detection algorithm
                obj.fObj{i}.runDetectionAlgo(1);
                if ~obj.fObj{i}.calcOK
                    % if the user cancelled, then exit the function
                    obj.calcOK = false;
                    return
                end
            end
            
            % calculates the final total background images
            IbgT0 = cell2cell(cellfun(@(x)(x.iMov.IbgT),obj.fObj,'un',0));
            IbgTF = cellfun(@(x)(...
                        calcImageStackFcn(x)),num2cell(IbgT0,1),'un',0);                                
                
            % retrieves the object sizes (for each phase)
            szObj = cellfun(@(x)(x.szObj),obj.fObj,'un',0);
            szObj = cell2mat(szObj(~cellfun(@(x)(isnan(x(1))),szObj)));
                    
            % sets the background images into the sub-region data struct            
            obj.iMov.IbgT = IbgTF;
            obj.iMov.szObj = ceil(median(szObj,1));
            obj.iMov.Ibg = cellfun(@(x)(x.IBG),obj.fObj,'un',0);
            
            % calculates the residual detection tolerances
            obj.setupResidualTolerances();
                        
            % calculates the overall quality of the flies (prompting the
            % user to exclude any empty/anomalous regions)
            if ~obj.isBatch && ~all(obj.iMov.vPhase == 3)
                obj.calcOverallQuality()
            end
            
            % sets the status flags for each phase (full and overall)
            obj.iMov.StatusF = cellfun(@(x)(x.iStatus),obj.fObj,'un',0);
            
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
        
        % --- resets up the residual tolerances (low-variance phase only)
        function setupResidualTolerances(obj)
            
            % if there are no low-variance phases then exit the function
            if ~any(obj.iMov.vPhase == 1); return; end
            
            % retrieves the 
            pBG0 = cell2cell(cellfun(@(x)(x.pBG),obj.fObj,'un',0));
            pBG = cellfun(@(x)(cell2mat(x(:)')),num2cell(pBG0,1),'un',0);
            
            % calculates 
            obj.iMov.pBG = cell(1,obj.nApp);
            for iApp = 1:obj.nApp
                if obj.iMov.ok(iApp)
                    % calculates the normalised threshold estimates
                    pBGmn = nanmean(pBG{iApp}(:));
                    pBGsd = nanstd(pBG{iApp}(:));
                    ZBG = (pBG{iApp}-pBGmn)/pBGsd;
                    
                    % calculates the weighting array
                    P = normcdf(ZBG,pBGmn,pBGsd);
                    Qw = (1-2*abs(P-0.5)); 
                    QwT = Qw./(repmat(nansum(Qw,2),1,size(Qw,2)));
                    
                    % calculates the final threshold values
                    obj.iMov.pBG{iApp} = nansum(QwT.*pBG{iApp},2);
                    obj.iMov.pBG{iApp}(all(isnan(QwT),2)) = NaN;
                end
            end
            
        end
        
        % --- 
        function [iFrm,Img] = getTrackingImages(obj)
            
            % 
            if obj.isCalib
                % returns the previously read image stack
                Img = obj.Img0;
                iFrm = {1:length(Img{1})};
                
            else
                % sets the phase frame indices
                nPh = obj.nPhase;
                iFrm = getPhaseFrameIndices(obj.iMov,obj.nFrmR);

                % reads the initial images            
                Img = cell(nPh,1);
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
                        Img{i} = obj.getImageStack(iFrm{i});    
                    end
                end
            end
            
            % updates the progress-bar
            obj.hProg.Update(1+obj.wOfsL,'Frame Read Complete',1);
            
        end        
      
        % --- segments the first frame of each phase (bg estimate only)
        function segFirstPhaseFrame(obj,iMov,ImgPhase)
           
            % sets the input arguments/
            obj.iMov = iMov;
            
            % creates the progress bar
            wStrPB = {'Overall Progress','Sub-Region Segmentation'};
            obj.hProg = ProgBar(wStrPB,'First Phase Frame Segmentation');
            
            % other initialisations
            nPhase = length(ImgPhase);
            
            % initialises the tracking objects
            obj.initTrackingObjects('Detect'); 
            
            % calculates the object locations for each phase
            for i = 1:nPhase
                % updates the overall progress
                wStrNw = sprintf('Overall Progress (%i of %i)',i,nPhase);
                obj.hProg.Update(1,wStrNw,i/nPhase);
                
                % sets the class fields for the tracking object                
                obj.fObj{i}.setClassField('wOfs',1+obj.wOfsL);
                obj.fObj{i}.setClassField('iPh',i);
                obj.fObj{i}.setClassField('Img',ImgPhase(i));
                
                % runs the detection algorithm for the tracking object
                obj.fObj{i}.runDetectionAlgo();
                    
                if ~obj.fObj{i}.calcOK
                    % if the user cancelled, then exit the function
                    obj.calcOK = false;
                    return
                end                
            end
            
            % closes the progress bar
            obj.hProg.closeProgBar();
            
        end
       
        % -------------------------------------------- %
        % --- INITIAL RESIDUAL DETECTION FUNCTIONS --- %
        % -------------------------------------------- %       
        
        % --- performats the initial residual detection
        function [fPos,sFlag,rFlag] = initResidualDetect(obj,Img,iFrm)

            % memory allocation
            pW0 = 0.8;
            rFlag = 0;
            sFlag = ~obj.iMov.flyok*3;
            nTube = getSRCountVec(obj.iMov);
            [nPhase,nApp] = deal(length(Img),length(nTube));
            fPos = cellfun(@(x)(repmat(arrayfun(@(n)(NaN(n,2)),...
                            nTube(:),'un',0),1,length(x))),Img,'un',0);
            h0 = getMedBLSize(obj.iMov);
            
            % sets the phase/frame index array
            nImgS = cumsum(cellfun(@length,Img));
            if sum(nImgS) == 0
                rFlag = -2;
                return
            else
                indF = cellfun(@(x)((x(1):x(2))'),...
                        num2cell([[1;nImgS(1:end-1)+1],nImgS],2),'un',0);
            end
            
            % updates the overall progress 
            wStr = 'Image Baseline Subtraction';
            if obj.hProg.Update(2+obj.wOfsL,wStr,0.5)   
                rFlag = -1;
                return                    
            end            
            
            % removes the median baseline from all images
            Img = removeImageMedianBL(cell2cell(Img),true,obj.is2D,h0);
            Img = cellfun(@(x)(Img(x)),indF,'un',0);             
            
            % creates the frame/phase mapping array
            gMap = cell2mat(cellfun(@(i,x)([i*ones(length(x),1),...
                    (1:length(x))']),num2cell(1:length(Img))',Img,'un',0));            
            
            % determines if there are any hi-variance phases
            isOK = obj.iMov.vPhase(:) < 3;
            if any(~isOK)
                % if so, remove these from the analysis
                [Img,iFrm] = deal(Img(isOK),iFrm(isOK));

                % removes the mapping values from the hi-variance phases
                for i = find(~isOK'); gMap(gMap(:,1)==i,:) = NaN; end
                gMap = gMap(~isnan(gMap(:,1)),:);
            end
                
            % updates the progressbar
            wStrB = 'Baseline Subtraction Complete!';
            obj.hProg.Update(2+obj.wOfsL,wStrB,1);          
            
            % --- MOVING OBJECT TRACKING --- %
            
            % memory allocation and other initialisations
            wStrB = 'Tracking Moving Objects';
            [IbgTmp,IsubNw] = deal(cell(max(nTube),nApp));                                 
            
            % for each sub-region, determine if the object has moved
            % appreciably over the entirety of the phase image stacks            
            for i = 1:nApp
                wStr = sprintf('%s (Region %i of %i)',wStrB,i,nApp);
                for j = 1:nTube(i)
                    if obj.iMov.flyok(j,i)
                        % updates the progressbar
                        pW = pW0*((i-1)+j/nTube(i))/nApp;
                        if obj.hProg.Update(3+obj.wOfsL,wStr,pW)
                            rFlag = -1;
                            return
                        end                        
                        
                        % tracks the object over all frames (for the given
                        % sub-region (i,j))
                        [fPosNw,sFlag(j,i),IbgTmp{j,i},IsubNw{j,i}] = ...
                               obj.trackAllSubRegionFrames(Img,iFrm,[i,j]);                        
                        if isempty(fPosNw)
                            % if there is a severe error then exit 
                            rFlag = -2;
                            return                           
                            
                        elseif ~all(isnan(fPosNw(:,1)))  
                            % otherwise, set the sub-region coordinates 
                            % for all frames (if a valid movement detected
                            fPos = obj.setSubRegionCoord(...
                                                fPos,fPosNw,gMap,[i,j]);                                                                     
                        end
                    end
                end
            end      
            
            % case is there are no moving object over the video
            if ~any(sFlag(:)==1)
                rFlag = -2;
                return
            elseif ~isempty(obj.prData0)
                % if there 
                return
            end           

            % --- FINAL BACKGROUND ESTIMATE IMAGE SETUP --- %            
            
            % parameters
            [xcTol,mxTol] = deal(2.5,2.5);
            
            % memory allocation            
            nTubeMx = max(nTube);
            [Ixc,Imax] = deal(NaN(nTubeMx,nApp),NaN(nTubeMx,nApp));
            [iR,iC] = deal(obj.iMov.iR,obj.iMov.iC);                 
            hasImg = ~cellfun(@isempty,IsubNw);            
            
            % initialises/sets the background image array
            if ~isfield(obj.iMov,'IbgT')
                IbgT = cell(1,nApp);
            elseif isempty(obj.iMov.IbgT)
                IbgT = cell(1,nApp);
            else
                IbgT = obj.iMov.IbgT;
            end
             
            % determines which frames have images that have been detected
            ii = find(hasImg);
            nImg = length(ii);
            
            %
            for i = 1:nImg
                % updates the waitbar figure
                pW = pW0 + (1-pW0)*(i/(nImg+1));                
                wStrNw = sprintf(['Final Sub-Region Check (Sub-Region ',...
                                  '%i of %i)'],i,nImg);
                if obj.hProg.Update(3+obj.wOfsL,wStrNw,pW)
                    % if the user cancelled, then exit the function
                    rFlag = -1;
                    return
                end                                
                
                % calculates the cross-correlation between the sub-images
                [iT,iApp] = ind2sub(size(Ixc),ii(i));
                jj = ~setGroup(i,[length(ii),1]);
                Ixc(iT,iApp) = 1 - nanmean(cellfun(@(x)(max(max(...
                          normxcorr2(IsubNw{ii(i)},x)))),IsubNw(ii(jj))));
    
                % calculates the indices of the central region
                if ~exist('indC','var')
                    sz = size(IsubNw{ii(i)});
                    N = (sz(1)-1)/2;
                    indC = bwmorph(setGroup((N+1)*[1,1],sz),'dilate');
                end
                
                % determines the maximum value around the central point
                Imax(iT,iApp) = max(IsubNw{ii(i)}(indC));
            end   
            
            % determines if there are any regions that are markedly
            % different from the others (x-corr/residual-wise)
            IxcN = Ixc./nanmedian(Ixc(:));
            ImaxN = nanmedian(Imax(:))./Imax;
            notOK = (IxcN > xcTol) & (ImaxN > mxTol);
            
            % if there are such regions, then remove them from the moving
            % fly list
            if any(notOK(:))
                % determines the regions that need to be reset
                [iT,iApp] = find(notOK);                
                for i = 1:length(iApp)                
                    % resets the background region/status flag
                    IbgTmp{iT(i),iApp(i)} = [];
                    sFlag(iT(i),iApp(i)) = 2;  
                    
                    % resets the positional values
                    for iPhase = 1:nPhase
                        for iFrm = 1:size(fPos{iPhase},2)
                            fPos{iPhase}{iApp(i),iFrm}(iT(i),:) = NaN;
                        end
                    end
                end
            end
            
            % sets the total background estimate for each region/sub-region
            for i = 1:nApp
                % memory allocation
                iRT = obj.iMov.iRT{i};
                IbgT{i} = NaN(length(iR{i}),length(iC{i}));
                
                % sets the images for each of the sub-regions
                for j = 1:nTube(i)
                    if obj.iMov.flyok(j,i) && ~isempty(IbgTmp{j,i})
                        IbgT{i}(iRT{j},:) = IbgTmp{j,i};
                    end
                end
            end
            
            % sets the final estimates into the sub-region data struct
            obj.iMov.IbgT = IbgT;
            
        end
        
        % --- tracks all the sub-region for all frames
        function [fPosNw,sFlag,IbgT,IsubNw] = ...
                                trackAllSubRegionFrames(obj,Img,iFrm,indG)
                        
            % initialisations
            sFlag = 1;
            nanTol = 0.3;  
            [iApp,iT,IsubNw] = deal(indG(1),indG(2),[]);
            
            % memory allocation      
            iC = obj.iMov.iC{iApp};
            iRT = obj.iMov.iRT{iApp}{iT};
            iR = obj.iMov.iR{iApp}(iRT); 

            % --- INITIAL IMAGE PROCESSING --- %

            % retrieves the local images (for all frames)
            ImgL = cell2cell(cellfun(@(x)(cellfun(@(y)...
                 (medianShiftImg(y(iR,iC))),x(:),'un',0)),Img,'un',0));
            BwL = cellfun(@(x)(x>median(x(:))),ImgL,'un',0);

            % other memory allocation s           
            [szI,nFrm] = deal(size(ImgL{1}),length(ImgL));
            [dImgL0mx,dImgMx] = deal(cell(nFrm,1));
            [dImgL0,IbgT] = deal(cell(nFrm),[]);                

            % sets the edge binary (used to remove edge objects)
            Bedge = ~getExclusionBin(obj.iMov,szI,iApp,iT);

            % calculates the inter-frame residual group stacks
            for i = 1:nFrm
                % calculates the image residual stack
                dImgL0(:,i) = cellfun(@(x)(BwL{i}.*(ImgL{i}-x)),...
                                    ImgL(:),'un',0);
                dImgL0mx{i} = cell2mat(cellfun(@(x)...
                                    (max(x,[],1)),dImgL0(:,i),'un',0));

                % calculate max pixel residual intensity for all frames
                dImgMx{i} = calcImageStackFcn(dImgL0(:,i),'max');
                dImgMx{i}(Bedge) = 0;
            end           

            % clears the temporary array
            clear Itmp            
            
            % --- OBJECT DETECTION CALCULATIONS --- %              
            
%             if isempty(obj.prData0)                      
                % calculates the location of the object over all frames
                [fPosNw,IsubF,isOK] = obj.calcMovingObjCoords(dImgMx);
                
%             else    
%                 % retrieves the local images (for all frames)
%                 ImgL = cell2cell(cellfun(@(x)(cellfun(@(y)...
%                                     (y(iR,iC)),x(:),'un',0)),Img,'un',0));                 
%                 
%                 % calculates the local image residuals
%                 Ibg0 = obj.iMov.IbgT{iApp}(iRT,:);
%                 ImgLR = cellfun(@(x)(max(0,x-Ibg0)),ImgL,'un',0);
%                 
%                 % calculates the object locations using the total
%                 % background image (from the previous solutions)
%                 [fPosNw,isOK] = obj.calcPosReuseBG(ImgLR);     
%                 
%                 % retrieves the residual sub-images surrounding the object
%                 if isOK
%                     IsubF = cellfun(@(I,p)(obj.getResSubImage(I,p,1)),...
%                                         dImgMx,num2cell(fPosNw,2),'un',0);      
%                 end
%             end
            
            % if the object is stationary, then exit the function  
            nFrm = length(ImgL);
            if ~isOK
                [fPosNw,sFlag] = deal(NaN(nFrm,2),2);
                return
            end            
            
            % --- BACKGROUND IMAGE ESTIMATE CALCULATIONS --- %

            % memory allocation            
            Ibg0 = cell(nFrm,1);                        
            
            % calculates the average image for all the object locations
            if isempty(obj.prData0)
                % case is the background is not being re-used
                IsubNw = calcImageStackFcn(cell2cell(cellfun(@(I,p)(...
                                    obj.getResSubImage(I,p)),dImgMx,...
                                    num2cell(fPosNw,2),'un',0)));  
            else
                % case is the background is being re-used
                IsubNw = calcImageStackFcn(IsubF);
            end
            
            if isfield(obj.iMov,'szObj')
                nPts = ceil(pi*prod(obj.iMov.szObj/2));
            else
                B = IsubNw > 0.05*max(IsubNw(:));
                nPts = sum(B(:));             
            end            
            
            % sets the background temporary image for each frame
            for i = 1:nFrm
                Ibg0{i} = obj.setTempBGImage(ImgL{i},fPosNw(i,:),nPts);
            end
            
            % calculates the average over the image stack (while removing
            % any NaN regions within the final bg image)
            IbgT = calcImageStackFcn(Ibg0);
            nanPix = isnan(IbgT);
            
            % determines if there are any NaN pixels in the avg image
            if any(nanPix(:))  
                % if so, determine how many there are compared to the NaN
                % regions in the temporary background image stack
                nNaN = cellfun(@(x)(sum(isnan(x(:)))),Ibg0);
                if sum(nanPix(:))/median(nNaN) > nanTol
                    % if the NaN count is excessive, then flag that the fly
                    % is probably stationary
                    [sFlag,fPosNw(:)] = deal(2,NaN);
                else
                    % otherwise, interpolate the missing regions
                    IbgT = calcInterpolatedImage(IbgT);
                end
                
                % exits the function
                return
            end
            
            % --- HIDDEN OBJECT DETECTION --- %
            
            % the hidden object check is only applicable to 1D setups
            if is2DCheck(obj.iMov) || obj.isCalib
                return
            end            

            % memory allocation            
            BsubF = cell(length(IsubF),1);
            [pSubF,IsubSD] = deal(zeros(length(IsubF),1));
            
            % sets up the x-limits
            pxLim = 0.1;
            xLim = roundP([pxLim,(1-pxLim)]*szI(2));

            % sets the mid-point of the sub-images
            fPosF = (1+(size(IsubF{1},1)-1)/2)*[1,1]; 

            % calculates the local std. dev and mean binary coverage from
            % each of the frame's sub-images
            for i = 1:length(IsubF)
                % thresholds the image to intersect with the mid-point
                Bsub0 = IsubF{i} > obj.pMaxR*max(IsubF{i}(:));
                [~,BsubF{i}] = detGroupOverlap(Bsub0,fPosF);

                % sets the binary size proportion and the max std-dev
                % filtered from the sub-image
                pSubF(i) = nanmean(BsubF{i}(:));
                IsubSD(i) = max(max(stdfilt(IsubF{i},obj.sdSE)));
            end

            % determines if there are any frames if the object is
            % hiding at the edge of the frame
            IsubSDmx = max(IsubSD);
            nearEdge = (fPosNw(:,1)<xLim(1)) | (fPosNw(:,2)>xLim(2));
            isHide = nearEdge & (IsubSD/IsubSDmx<obj.sdTol);% & (pSubF<obj.pbTol);             
            
            %
            if all(isHide)
                % if there are no feasible frames, then use the solution
                % from the previous location data
                if isempty(obj.prData0)
                    % if there is no previous data, then set as stationary
                    [sFlag,fPosNw(:)] = deal(2,NaN);                    
                else
                    fP = obj.prData0.fPos{iApp}(iT,:) - [0,iRT(1)-1];
                    fPosNw = repmat(fP,size(fPosNw,1),1);
                end
                
            elseif any(isHide)
                % if there are any frames that are not feasible, then
                % determine the index groups that they belong to
                iFrmT = cell2mat(iFrm(:))';
                iGrpF = getGroupIndex(isHide);

                % determines the edge limits of the feasible frame
                % range for each infeasibility group
                [iNw,indF] = deal(cell(length(iGrpF),1));
                for i = 1:length(iGrpF)
                    if iGrpF{i}(1) > 1
                        % start of group starts after first frame
                        iNw{i} = iGrpF{i}(1)+[-1,0];
                        indF{i} = {ImgL{iNw{i}},[iFrmT(iNw{i}),0]};
                    elseif iGrpF{i}(end) < nFrm
                        % end of group ends before last frame
                        iNw{i} = iGrpF{i}(end)+[0,1];
                        indF{i} = {ImgL{iNw{i}},[iFrmT(iNw{i}),1]};                            
                    end
                end

                % calculates the last location of the object before it
                % goes hidden. use these coordinates to fill in the
                % coordinates of the hidden frames
                for i = 1:length(iGrpF)
                    fPosHidden = obj.detHiddenObjPos(...
                               fPosNw(iNw{i},:),indF{i},indG,IsubSDmx);                           
                    fPosNw(iGrpF{i},:) = ...
                               repmat(fPosHidden,length(iGrpF{i}),1);
                end
                
                % check to determine if the fly has moved appreciably    
                if isfield(obj.iMov,'szObj')
                    szRng = obj.iMov.szObj/2;
                else
                    szRng = 5;
                end
                    
                    
                if all(range(fPosNw,1) < szRng)
                    [sFlag,IbgT,IsubNw] = deal(2,[],[]);  
                end
            end      

        end
        
        % --- calculates the position of the objects reusing the total 
        %     background image from previous solutions
        function [fPosNw,ok] = calcPosReuseBG(obj,ImgLR)
            
            % parameters
            ok = true;
            pW = 0.5;
            hG = fspecial('gaussian',3,1);
            
            % memory allocation
            sz = size(ImgLR{1});
            nFrm = length(ImgLR);
            fPosNw = NaN(nFrm,2);
            
            % thresholds the residual images to determine the
            ImgLR = cellfun(@(x)(imfilter(x,hG)),ImgLR,'un',0);
            Imx = cellfun(@(x)(max(x(:))),ImgLR,'un',0);
            Bmx0 = cellfun(@(x)(imregionalmax(x)),ImgLR,'un',0);           
            Bmx = cellfun(@(x,y,p)(y.*(x>pW*p)),ImgLR,Bmx0,Imx,'un',0);
            
            % calculates the object's location for each frame
            for i = 1:nFrm
                % converts the regional maxima to coordinates
                imx = find(Bmx{i});
                [yP,xP] = ind2sub(sz,imx);
                if length(xP) > 1
                    iP = argMax(ImgLR{i}(imx));
                    [xP,yP] = deal(xP(iP),yP(iP));
                end
                
                % sets the final position values
                fPosNw(i,:) = [xP,yP];
            end
            
            % determines if the object has moved appreciably
            if ~any(range(fPosNw,1) > obj.iMov.szObj/2)
                % if not, then exit the function
                [fPosNw(:),ok] = deal(NaN,false);
                return
            end
            
        end
        
        % --- determines the last like location of the hidden object
        function fPosF = detHiddenObjPos(obj,fPosL,indF,indG,IsubSDmx)
            
            % parameters
            pW = 0.5;
            nDil = 2;
            dEdge = 5;
            nFrmGap = 10;            
                    
            % retrieves the frame/region indices
            is2D = is2DCheck(obj.iMov);
            [iFrmF,ImgF] = deal(indF{3}(1:2),indF(1:2));
            [iApp,iFly,iType] = deal(indG(1),indG(2),indF{3}(3));
            sz = size(ImgF{1});
            
            % sets the position of the valid location 
            fPosF = fPosL(iType+1,:);
            
            % row/column indices
            iC = obj.iMov.iC{iApp};
            iRT = obj.iMov.iRT{iApp}{iFly};
            iR = obj.iMov.iR{iApp}(iRT);
            h0 = getMedBLSize(obj.iMov);
            
            %
            while 1
                % calculates the new frame 
                iFrmNw = roundP(mean(iFrmF));
                I0 = obj.getImageStack(iFrmNw,1);
                I = removeImageMedianBL(I0,0,obj.is2D,h0);
                
                % calculates the residual image
                IL = I(iR,iC);
                IRL = cellfun(@(x)(max(0,IL-x)),ImgF,'un',0);
                IRLmx = calcImageStackFcn(IRL,'max');                
                
                % determines the maxima points that intersect with the
                % regions of high residual pixel intensity
                Bw = (IRLmx>pW*max(IRLmx(:)));
                Bmx = imregionalmax(IRLmx).*Bw;
                
                % if 1D, then remove any maxima that are close to the edges
                if ~is2D
                    [Bmx(:,1:dEdge),Bmx(:,(end-dEdge-1):end)] = deal(0);
                end
                
                % retrieves the 
                iGrpF = getGroupIndex(Bmx);
                
                %
                nGrp = length(iGrpF);
                fP = zeros(nGrp,2);
                Imx = zeros(nGrp,1);
                isFeas = false(nGrp,1);
                
                                
                % retrieves the sub-image around the new location
                for i = 1:length(isFeas)
                    fP(i,:) = getMaxCoord(IRLmx.*setGroup(iGrpF{i},sz));
                    IsubNw = obj.getResSubImage(IRLmx,fP(i,:),1);
                    
                    % thresholds the image
                    fPC = 1+(size(IsubNw)-1)/2;
                    [~,BsubNw] = detGroupOverlap(...
                                    IsubNw > obj.pMaxR*max(IsubNw(:)),fPC);
                    Bm = bwmorph(BsubNw,'dilate',nDil);                    

                    % determines if the new frame has a feasible location
                    IsdNw = stdfilt(IsubNw,obj.sdSE);
                    IsubSD = max(IsdNw(Bm))/IsubSDmx;
                    
                    Imx(i) = max(IsubNw(Bm));
                    isFeas(i) = (mean(BsubNw(:))<obj.pbTol) & ...
                                                    (IsubSD>obj.sdTol);
                end
                
                if any(isFeas)
                    %
                    if sum(isFeas) > 1
                        [jj,szF] = deal(find(isFeas),size(isFeas));
                        isFeas = setGroup(jj(argMax(Imx(isFeas))),szF);
                    end
                    
                    % if feasible, then update the coordinates and frame
                    [fPosF,iFrmF(1+iType)] = deal(fP(isFeas,:),iFrmNw);
                else
                    % otherwise, update the other frame index
                    iFrmF(2-iType) = iFrmNw;
                end
                
                % if the difference in frames is less than tolerance, then
                % exit the loop
                if diff(iFrmF) < nFrmGap
                    break
                end
            end
                            
        end
        
        % --- calculates the coordinates of the moving object (if the
        %     object is not moving, then return ok = false)
        function [fPos,IsubF,ok] = calcMovingObjCoords(obj,dImgQ)
            
            % parameters
            IsubF = [];
            ok = true;
            pW = 0.5;    
            xTol = 3;
            nGrpMx = 5*(1+obj.is2D);  
            pEdgeTol = 0.25;
            
            % array dimensioning
            sz = size(dImgQ{1});
            
            % calculates the pixel intensity threshold for each image
            pMax = cellfun(@(x)(pW*max(x(:))),dImgQ,'un',0);
            
            % threshold each sub-region frame for the threshold intensities
            fPos0 = cellfun(@(x,p)(...
                            obj.calcLikelyResLoc(x,p)),dImgQ,pMax,'un',0);           
                           
            % if the mean number of thresholded groups is high (meaning the
            % sub-region is probably empty or has major issues) then exit
            % the function flagging an error
            nGrp = cellfun(@(x)(size(x,1)),fPos0);  
            if (mean(nGrp)>nGrpMx) || (max(nGrp)>10*nGrpMx) || any(nGrp==0)
                [fPos,ok] = deal([],false);
                return
            end
            
            % removes any objects located at the frame edge (1D only)
            if ~obj.is2D                                    
                for i = 1:length(fPos0)                                
                    ii = (fPos0{i}(:,1)>=xTol) & ...
                         (fPos0{i}(:,1)<=(sz(2)-xTol)); 
                    if any(ii)                        
                        [nGrp(i),fPos0{i}] = deal(sum(ii),fPos0{i}(ii,:));
                    end
                end
            end                              
                
            % sets the group indices for each frame
            nGrpS = cumsum(nGrp);
            indG = num2cell([[1;nGrpS(1:end-1)+1],nGrpS],2);
            iGrp = cellfun(@(x)(x(1):x(2)),indG,'un',0);                                 

            % groups the objects by their proximity to each other and
            % determines the frame of the first index in each group
            [iGrp,Isub0,fPos0] = obj.distGroupObj(dImgQ,iGrp,fPos0);                                  

            % returns the position values based on the number of
            % feasible groupings that were determined above
            fPos = detLikelyFrameGrouping(...
                                cell2cell(Isub0),dImgQ,iGrp,fPos0);
                            
            if isempty(fPos)
                % no feasible groupings were found
                [fPos,ok] = deal([],false);
                return
            end     
            
            % sets the final sub-images
            IsubF = cellfun(@(fp,fp0,I)(I{argMin(sum(abs(fp0-repmat(fp,...
                   size(fp,1),1))))}),fPos0,num2cell(fPos,2),Isub0,'un',0);              
            
            % determines if any points are on the frame edge for a
            % significant proportion of the frames (1D only)
            if ~obj.is2D
                pEdge = mean(fPos(:,1)<=2 | fPos(:,1)>=(sz(2)-1) | ...
                             fPos(:,2)<=2 | fPos(:,2)>=(sz(1)-1));
                if mean(pEdge) > pEdgeTol
                    [fPos,ok] = deal([],false);
                end     
            end

        end                 
        
        % --- groups the objects by their proximity to each other
        function [iGrp,Isub0,fPos0] = ...
                                distGroupObj(obj,dImgQ,iGrp,fPos0)
            
            % parameters
            dTol = 5;
            
            % retrieves the sub-image surrounding each object
            Isub0 = cellfun(@(I,p)...
                        (obj.getResSubImage(I,p)),dImgQ,fPos0,'un',0);                         
                    
            %
            for i = length(fPos0):-1:1
                if size(fPos0{i},1) > 1
                    % calculates the distance between the points, if they
                    % are too close then remove the smaller of the two
                    dPos0 = pdist2(fPos0{i},fPos0{i});
                    
                    % determines if any points are close to each other
                    if any(dPos0(:)<2*dTol)
                        % if so, then remove the points for 
                        isKeep = true(size(dPos0,1),1);
                        for j = 1:size(dPos0,1)
                            isC = find(dPos0(:,j)<2*dTol);
                            if length(isC) > 1
                                % if there are 1 or more points close to
                                % each other, then retrieve the value of
                                % the residual at the candidate points
                                IPos = dImgQ{i}(sub2ind(size(dImgQ{i}),...
                                        fPos0{i}(isC,2),fPos0{i}(isC,1)));
                                        
                                % remove the non-max point from the group
                                isR = isC((1:length(isC))~=argMax(IPos));
                                isKeep(isR) = false;
                                [dPos0(isR,:),dPos0(:,isR)] = deal(NaN);
                            end
                        end
                        
                        % removes the extraneous point(s)
                        fPos0{i} = fPos0{i}(isKeep,:);
                        Isub0{i} = Isub0{i}(isKeep);
                        iGrp{i} = iGrp{i}(1:sum(isKeep));
                        
                        % decrements the index counts
                        dOfs = sum(~isKeep);
                        iGrp((i+1):end) = cellfun(@(x)...
                                        (x-dOfs),iGrp((i+1):end),'un',0);
                    end
                end
            end                        
            
            %
            [IsubF,fPosT] = deal(cell2cell(Isub0),cell2mat(fPos0));
            [nFrm,nObj] = deal(length(fPos0),size(fPosT,1));
            
            % calculates the distance between the objects
            dPos = cell2mat(cellfun(@(x)(pdist2(x,fPosT)),fPos0,'un',0)); 
            dPos(logical(eye(size(dPos)))) = NaN; 
            
            %
            for i = 1:nObj
                for j = 1:nFrm
                    if any(iGrp{j} == i)
                        % case is the group contains the candidate object
                        dPos(iGrp{j},i) = NaN;
                        
                    elseif ~any(dPos(iGrp{j},i)<=dTol)
                        % case is no objects from this group are close to 
                        % the candidate object
                        dPos(iGrp{j},i) = NaN;
                        
                    else
                        % otherwise, ignore the objects within the group
                        % that are not closest to the candidate
                        iMn = argMin(dPos(iGrp{j},i));
                        ii = (1:length(iGrp{j})) ~= iMn;
                        dPos(iGrp{j}(ii),i) = NaN;                        
                    end
                end
            end
            
%             % keep looping until all groups 
%             jGrp = [];
%             isF = false(nObj,1);
%             while any(~isF)
%                 % determines the next ungrouped object, and the frame from
%                 % which the object came
%                 iNw = find(~isF,1,'first');
%                 iFrm = find(cellfun(@(x)(any(x==iNw)),iGrp));
%                 
%                 %
%                 [jGrp{end+1},isF(iNw)] = deal(iNw,true);
%                 for j = (iFrm+1):nFrm
%                     % determines if there are any points from the next
%                     % frame that can be added to the group
%                     ii = (dPos(iGrp{j},iNw) >= 0) & ~isF(iGrp{j});
%                     if any(ii)
%                         % if so, determine
%                         k = iGrp{j}(ii);
%                         Ixc = normxcorr2(IsubF{iNw},IsubF{k});
%                         
%                         %
%                         isF(k) = true;
%                         jGrp{end}(end+1) = k;
%                         
%                     else
%                         % otherwise, exit the loop
%                         break
%                     end
%                 end
%             end            
%             
%             % retrieves the first/last frame of each frame grouping
%             iFrm0 = cellfun(@(x)(obj.getFrameMatch(iGrp,x(1))),jGrp);
%             iFrmF = cellfun(@(x)(obj.getFrameMatch(iGrp,x(end))),jGrp);
% 
%             % removes any groupings that don't link to any other groups
%             isOK = true(length(jGrp),1);
%             for i = 1:length(jGrp)
%                 if iFrm0(i) == 1
%                     % case is this frame grouping starts on the first frame
%                     isOK(i) = any(iFrm0==(iFrmF(i)+1));
%                 elseif iFrmF(i) == nFrm
%                     % case is this frame grouping ends on the last frame
%                     isOK(i) = any(iFrmF==(iFrm0(i)-1));
%                 else
%                     % other case type
%                     isOK(i) = any(iFrm0==(iFrmF(i)+1)) && ...
%                               any(iFrmF==(iFrm0(i)-1));
%                 end
% 
%                 % if not feasible, then remove the frame indices
%                 if ~isOK(i)
%                     [iFrm0(i),iFrmF(i)] = deal(NaN);
%                 end
%             end
% 
%             % removes the infeasible groupings
%             jGrp = jGrp(isOK);            
            
        end             
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %                     

        % --- determines the matching frame from the global index, iObj
        function iFrm = getFrameMatch(obj,iGrp,iObj)
           
            if length(iObj) > 1
                iFrm = arrayfun(@(x)(obj.getFrameMatch(iGrp,x)),iObj);
            else
                iFrm = find(cellfun(@(y)(any(y==iObj)),iGrp));
            end
            
        end       
        
        % --- calculates the overall quality values
        function calcOverallQuality(obj)
            
            % calculates the quality values (min over all phases)        
            obj.Qval = calcImageStackFcn(cellfun(@(x)(roundP(100./(1+...
               exp(obj.kQ*(x.Qmet-obj.hQ))))),obj.fObj,'un',0),'ptile',25);
                        
            % determines if there are any potentially empty regions
            isAnom = (obj.Qval < obj.Qtol) & obj.iMov.flyok;
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
                eObj = EmptyCheck(obj.Qval,isAnom);
                
                % resets the status flags for all flagged sub-regions
                for i = find(eObj.isEmpty(:)')
                    [iApp,iTube] = deal(eObj.iApp(i),eObj.iTube(i));
                    for j = 1:length(obj.fObj)                        
                        obj.fObj{j}.iStatus(iTube,iApp) = 3;
                        
                        obj.iMov.flyok(iTube,iApp) = false;
                        if ~any(obj.iMov.flyok(:,iApp))
                            obj.iMov.ok(iApp) = false;
                        end
                    end                    
                end
                
                % closes the progressbar
                obj.hProg.setVisibility('off');                
            end
            
        end        
    end    
    
    % class static methods
    methods (Static)
        
        % --- sets the sub-region coordinates for all frames
        function fPos = setSubRegionCoord(fPos,fPosNw,gMap,indG)

            for i = 1:size(gMap,1)
                fPos{gMap(i,1)}{indG(1),gMap(i,2)}(indG(2),:) = fPosNw(i,:);
            end

        end                       
        
        % --- calculates the temporary background image
        function ImgL = setTempBGImage(ImgL,fPos,nPts)
            
            % parameters
            szL = size(ImgL);
            [~,iS] = sort(ImgL(:),'descend');
            
            % thresholds the image surrounding the object location
            Brmv0 = setGroup(iS(1:nPts),szL);
            [~,Brmv] = detGroupOverlap(Brmv0,fPos);            
                
            % removes the region surrounding the object
            ImgL(bwmorph(Brmv,'dilate')) = NaN;
            
        end      
        
        % --- 
        function fPosC = calcBinGroupCOM(iGrp,sz)
            
            % memory allocation
            fPosC = NaN(length(iGrp),2);
            
            % calculates the binary groups COM
            for i = 1:length(iGrp)
                [pY,pX] = ind2sub(sz,iGrp{i});
                fPosC(i,:) = roundP([mean(pX),mean(pY)]);
            end
            
        end
        
        % --- 
        function Isub = getResSubImage(I,p,varargin)
            
            % initialisations
            dN = 10;
            sz = size(I);            
            Isub = repmat({zeros(2*dN+1)},size(p,1),1);
            
            % sets the sub-images for each coordinate
            for i = 1:length(Isub)
                % calculates the row/column indices of the sub-image
                iR = (p(i,2)-dN):(p(i,2)+dN);
                iC = (p(i,1)-dN):(p(i,1)+dN);
                
                % determines valid row/column pixels
                ii = (iR >= 1) & (iR <= sz(1));
                jj = (iC >= 1) & (iC <= sz(2));
                
                % sets the valid pixels of the image
                Isub{i}(ii,jj) = I(iR(ii),iC(jj));
            end
            
            % converts to a single array (if required)
            if nargin == 3; Isub = Isub{1}; end
            
        end
        
        % --- calculates the likely residual locations for the image, I
        %     for the pixel intensity, p
        function fPos = calcLikelyResLoc(I,p)
            
            % threshold the image for the pixel intensity, p
            B = I > p;
            iGrp = getGroupIndex(B);
            
            %
            [yP,xP] = find(imregionalmax(I).*B);
            if length(xP) ~= length(iGrp)
                % calculates the indices of the points
                iP = sub2ind(size(I),yP,xP);
                
                % for each binary group, determine which is the more likely
                % point (if there is more than one point per binary group)
                isOK = true(length(xP),1);                
                for i = 1:length(iGrp)
                    ii = find(arrayfun(@(x)(any(iGrp{i}==x)),iP));
                    if length(ii) > 1
                        iMx = argMax(I(iP(ii)));
                        isOK(ii((1:length(ii))~=iMx)) = false;
                    end
                end
                
                % removes the extraneous points
                [xP,yP] = deal(xP(isOK),yP(isOK));
            end
            
            % sets the final positional values
            fPos = [xP(:),yP(:)];
            
        end        
        
    end
end
