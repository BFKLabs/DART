classdef SingleTrackInit < SingleTrack
    % class properties
    properties
        % parameters
        wOfsL = 0;
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
            nPhase = length(obj.iMov.vPhase);
            
            % initialises the tracking objects
            obj.initTrackingObjects('InitEstimate'); 
            wStr0 = obj.hProg.wStr;    
            
            % reads the initial images
            [Img,iFrm] = deal(cell(nPhase,1));
            for i = 1:nPhase
                % updates the progressbar 
                wStr = sprintf(...
                    'Reading Phase Images (Phase %i of %i)',i,nPhase);
                if obj.hProg.Update(1+obj.wOfsL,wStr,i/(1+nPhase))
                    % if the user cancelled, then exit the function
                    obj.calcOK = false;
                    return
                end
                
                % reads the image stack for phase frame indices
                iFrm{i} = getPhaseFrameIndices(...
                                    obj.iMov.iPhase(i,:),obj.nFrmR);
                Img{i} = obj.getImageStack(iFrm{i});                  
            end
            
            % updates the progress-bar
            obj.hProg.Update(1+obj.wOfsL,'Frame Read Complete',1);
            
            % initial detection of the moving objects over the video
            [fPos,sFlag,rFlag] = initResidualDetect(obj,Img);
            switch rFlag
                case 0
                    % if the initial detection was feasible (and there are
                    % moving objects within the video) then update the 
                    % tracking class objects with this information              

                    % sets the positional values
                    for i = 1:nPhase
                        %
                        pMaxNw = fPos{i};
                        for j = 1:numel(pMaxNw)
                            pMaxNw{j} = num2cell(pMaxNw{j},2);
                        end

                        % sets the tracking object classfields
                        obj.fObj{i}.setClassField('fPos',fPos{i})
                        obj.fObj{i}.setClassField('pMax',pMaxNw)                    
                        obj.fObj{i}.setClassField('calcRes',false) 
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
            for i = 1:nPhase
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
                
                % sets the class fields for the tracking object
                obj.fObj{i}.setClassField('Img',Img{i});
                obj.fObj{i}.setClassField('iMov',obj.iMov);
                obj.fObj{i}.setClassField('wOfs',1+obj.wOfsL);
                obj.fObj{i}.setClassField('vPh',obj.iMov.vPhase(i)) 
                obj.fObj{i}.setClassField('iStatus',double(sFlag==1))
                
                % sets the initial object locations
                if i == 1
                    % case is the first phase (no previous points)
                    prData = [];
                else
                    % case is the sub-sequent phases
                    prData = obj.getPrevPhaseData(obj.fObj{i-1});
                end                
                
                % runs the direct detection algorithm   
                obj.fObj{i}.runDetectionAlgo(prData,true);
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
                
            % sets the background images into the sub-region data struct
            obj.iMov.IbgT = IbgTF;
            obj.iMov.Ibg = cellfun(@(x)(x.IBG),obj.fObj,'un',0);
            obj.iMov.pBG = cellfun(@(x)(x.pBG),obj.fObj,'un',0);
            
            % sets the status flags for each phase (full and overall)
            obj.iMov.StatusF = cellfun(@(x)(x.iStatus),obj.fObj,'un',0);
                        
            % sets the overall status flags over all the frames (any frames
            % where any potentially empty sub-regions are removed)
            Status0 = cell2mat(reshape(obj.iMov.StatusF,[1,1,nPhase]));
            Status1 = min(Status0,[],3); 
            Status1(any(Status0==3,3)) = 3;
            obj.iMov.Status = num2cell(Status1,1);
                
            % calculates the median object size
            szObjT = cell2mat(cellfun(@(x)(x.szObj),obj.fObj,'un',0));
            obj.iMov.szObj = nanmedian(szObjT,1);
                    
            % outputs the empty region message to screen
            obj.outputEmptyRegionMsg()
                    
            % updates the progress bar
            obj.hProg.Update(1+obj.wOfsL,'Initial Estimate Complete!',1);                                                
            
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
                obj.fObj{i}.setClassField('iPhase',i);
                obj.fObj{i}.setClassField('Img',{ImgPhase{i}});
                
                % runs the detection algorithm for the tracking object
                obj.fObj{i}.runDetectionAlgo([]);
                    
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
        function [fPos,sFlag,rFlag] = initResidualDetect(obj,Img)

            % memory allocation
            rFlag = 0;
            sFlag = ~obj.iMov.flyok*3;
            nTube = getFlyCount(obj.iMov,1);
            [nPhase,nApp] = deal(length(Img),length(nTube));
            fPos = cellfun(@(x)(repmat(arrayfun(@(n)(NaN(n,2)),...
                            nTube(:),'un',0),1,length(x))),Img,'un',0);

            % calculates the median background images
            for i = 1:nPhase
                % updates the overall progress 
                wStr = sprintf(...
                    'Image Baseline Subtraction (Phase %i of %i)',i,nPhase);
                if obj.hProg.Update(2+obj.wOfsL,wStr,i/(1+nPhase))   
                    rFlag = -1;
                    return                    
                end
                
                % removes the image median baseline
                Img{i} = removeImageMedianBL(Img{i},obj.iMov.vPhase(i)==1);
            end
            
            % creates the frame/phase mapping array
            gMap = cell2mat(cellfun(@(i,x)([i*ones(length(x),1),...
                    (1:length(x))']),num2cell(1:length(Img))',Img,'un',0));            
            
            % updates the progressbar
            wStrB = 'Baseline Subtraction Complete!';
            obj.hProg.Update(2+obj.wOfsL,wStrB,1);          
            
            % --- MOVING OBJECT TRACKING --- %
            
            % 
            wStrB = 'Tracking Moving Objects';                
            
            % memory allocation 
            IbgTmp = cell(max(nTube),nApp);                                 
            
            % for each sub-region, determine if the object has moved
            % appreciably over the entirety of the phase image stacks            
            for i = 1:nApp
                wStr = sprintf('%s (Region %i of %i)',wStrB,i,nApp);
                for j = 1:nTube(i)
                    if obj.iMov.flyok(j,i)
                        % updates the progressbar
                        pW = ((i-1)+j/nTube(i))/nApp;
                        if obj.hProg.Update(3+obj.wOfsL,wStr,pW)
                            rFlag = -1;
                            return
                        end
                        
                        % tracks the object over all frames (for the given
                        % sub-region (i,j))
                        [fPosNw,sFlag(j,i),IbgTmp{j,i}] = ...
                                    obj.trackAllSubRegionFrames(Img,[i,j]);                        
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
            end

            % --- FINAL BACKGROUND ESTIMATE IMAGE SETUP --- %            
            
            % memory allocation
            IbgT = cell(1,nApp);
            [iR,iC] = deal(obj.iMov.iR,obj.iMov.iC);                        
            
            % sets the total background estimate for each region/sub-region
            for i = 1:nApp
                % memory allocation
                iRT = obj.iMov.iRT{i};
                IbgT{i} = NaN(length(iR{i}),length(iC{i}));
                
                % sets the images for each of the sub-regions
                for j = 1:nTube(i)
                    if obj.iMov.flyok(j,i)
                        IbgT{i}(iRT{j},:) = IbgTmp{j,i};
                    end
                end
            end
            
            % sets the final estimates into the sub-region data struct
            obj.iMov.IbgT = IbgT;
            
        end
        
        % --- tracks all the sub-region for all frames
        function [fPosNw,sFlag,IbgT] = ...
                                    trackAllSubRegionFrames(obj,Img,indG)
                        
            % initialisations
            sFlag = 1;
            dTol = 5;
            
            % memory allocation
            [iApp,iT] = deal(indG(1),indG(2));
            iC = obj.iMov.iC{iApp};
            iR = obj.iMov.iR{iApp}(obj.iMov.iRT{iApp}{iT});

            % retrieves the local images (for all frames)
            ImgL = cell2cell(cellfun(@(x)(cellfun(@(y)...
                   (medianShiftImg(y(iR,iC))),x,'un',0)),Img,'un',0));                    

            % other memory allocation s           
            [szI,nFrm] = deal(size(ImgL{1}),length(ImgL));
            [dImgL0mx,dImgMx] = deal(cell(nFrm,1));
            [dImgL0,IbgT] = deal(cell(nFrm),NaN(szI));
            
            % --- INITIAL IMAGE PROCESSING --- %
            
            % calculates the inter-frame residual group stacks
            for i = 1:nFrm
                % calculates the image residual stack
                dImgL0(:,i) = cellfun(@(x)(max(0,ImgL{i}-x)),ImgL(:),'un',0);
                dImgL0mx{i} = cell2mat(cellfun(@(x)...
                                       (max(x,[],1)),dImgL0(:,i),'un',0));
                                   
                dImgMx{i} = calcImageStackFcn(dImgL0(:,i),'max');
            end           
            
            % --- OBJECT DETECTION CALCULATIONS --- %                        
            
            % calculates the location of the object over all frames
            [fPosNw,isOK] = obj.calcMovingObjCoords(dImgMx,ImgL); 
            if ~isOK
                % if the object is stationary, then exit the function
                [fPosNw,sFlag] = deal(NaN(nFrm,2),2);
                return
                
            elseif max(range(fPosNw,1)) <= dTol
                % if the object has barely moved, then flag as being 
                % stationary and exit the function
                [fPosNw,sFlag] = deal(NaN(nFrm,2),2);
                return                
                
            end
            
            % --- BACKGROUND IMAGE ESTIMATE CALCULATIONS --- %

            % memory allocation
            Ibg0 = cell(nFrm,1);
            
            % sets the background temporary image for each frame
            for i = 1:nFrm
                Ibg0{i} = obj.setTempBGImage(ImgL{i},fPosNw(i,:));
            end
            
            % calculates the average over the image stack (while removing
            % any NaN regions within the final bg image)
            IbgT = calcInterpolatedImage(calcImageStackFcn(Ibg0));

        end
        
        % --- calculates the coordinates of the moving object (if the
        %     object is not moving, then return ok = false)
        function [fPos,ok] = calcMovingObjCoords(obj,dImgQ,ImgL)
            
            % parameters
            ok = true;
            pW = 0.6;          
            xTol = 3;
            xcTol = 0.70;
            nGrpMx = 5;  
            
            % array dimensioning
            sz = size(dImgQ{1});
            nFrm = length(dImgQ);
            
            % calculates the pixel intensity threshold for each image
            pMax = cellfun(@(x)(pW*max(x(:))),dImgQ,'un',0);
            
            % threshold each sub-region frame for the threshold intensities
            BGrp = cellfun(@(x,I,p)((x>p)&(I>0)),dImgQ,ImgL(:),pMax,'un',0);
            iGrp = cellfun(@(x)(getGroupIndex(x)),BGrp,'un',0);
            nGrp = cellfun(@length,iGrp);     
            
            % if the mean number of thresholded groups is high (meaning the
            % sub-region is probably empty or has major issues) then exit
            % the function flagging an error
            if (mean(nGrp)>nGrpMx) || (max(nGrp)>5*nGrpMx) || any(nGrp==0)
                [fPos,ok] = deal([],false);
                return
            end
            
            % calculates the binary object coordinates over all frames
            fPos0 = cellfun(@(x,y)(obj.calcBinGroupCOM(...
                                            x,size(y))),iGrp,BGrp,'un',0);
            for i = 1:length(fPos0)
                % removes any objects located at the frame edge
                ii = (fPos0{i}(:,1)>=xTol) & (fPos0{i}(:,1)<=(sz(2)-xTol));
                [iGrp{i},nGrp(i),fPos0{i}] = ...
                                deal(iGrp{i}(ii),sum(ii),fPos0{i}(ii,:));
                if nGrp(i) == 0
                    % if there are no valid groups within the sub-region,
                    % then exit the function
                    [fPos,ok] = deal([],false);
                    return                    
                end
            end
            
            % sets the final object coordinates
            isUniq = nGrp == 1;
            if all(isUniq)
                % if all the frames have unique objects, then combine all 
                % the positions into a single array  
                fPos = cell2mat(fPos0);
            else
                % otherwise, match the 
                
                % converts the positional cell arrays to a numeric array
                fPosT = cell2mat(fPos0);                
                
                % sets the group indices for each frame
                nGrpS = cumsum(nGrp);
                indG = num2cell([[1;nGrpS(1:end-1)+1],nGrpS],2);
                iGrp = cellfun(@(x)(x(1):x(2)),indG,'un',0);
                iGrp0 = cellfun(@(x)(x(1)),iGrp);      
                
                % retrieves the sub-image surrounding each object
                Isub0 = cell2cell(cellfun(@(I,p)...
                            (obj.getResSubImage(I,p)),dImgQ,fPos0,'un',0));                
                
                % groups the objects by their proximity to each other and
                % determines the frame of the first index in each group
                jGrp = obj.distGroupObj(Isub0,iGrp,fPos0,fPosT);    
                iFrm0 = cellfun(@(x)(obj.getFrameMatch(iGrp,x(1))),jGrp);
                
                % retrieves the sub-images for all potential coordinates
                Isub = cellfun(@(x)...
                            (calcImageStackFcn(Isub0(x))),jGrp,'un',0);                       

                % determines the groupings which have an object present on
                % the first frame
                isF = iFrm0==1;
                [kGrp,isFeas] = deal(jGrp(isF),false(sum(isF),1));
                
                % for each group that includes the first frame, search all
                % of the groups 
                for i = 1:length(kGrp)
                    while 1
                        % determines the frame of the last group index
                        iFrmF = obj.getFrameMatch(iGrp,kGrp{i}(end));
                        
                        % determines if there are any subsequent groups
                        % that will link to the end of the current group
                        isMatch = (iFrm0 == (iFrmF+1)) & ~isF;
                        if ~any(isMatch)
                            % if there are no groups that match up with the
                            % end of the current then exit the loop
                            break
                        else
                            % if there is more than one potential match,
                            % then use similarity metrics to determine
                            % which group matchs up with the current
                            iNw = find(isMatch);
                            if length(iNw) > 1 
                                %
                                IsubMn = calcImageStackFcn(Isub0(kGrp{i}));
                                Ixc = cellfun(@(x)(max(max...
                                   (normxcorr2(IsubMn,x)))),Isub(iNw));
                               
                                % determines the group with the maximum
                                % cross-correlation
                                iMx = argMax(Ixc);
                                if Ixc(iMx) < xcTol
                                    break
                                else
                                    iNw = iNw(iMx);
                                end
                            end
                            
                            % sets new match and appends the new group 
                            % indices to the current group match                            
                            isF(iNw) = true;
                            kGrp{i} = [kGrp{i},jGrp{iNw}];
                            
                            % if the new group contains the final frame,
                            % then exit the loop
                            if obj.getFrameMatch(iGrp,kGrp{i}(end)) == nFrm
                                isFeas(i) = true;
                                break
                            end
                        end
                    end
                end
                
                % returns the position values based on the number of
                % feasible groupings that were determined above
                if sum(isFeas) == 0
                    % no feasible groupings were found
                    [fPos,ok] = deal([],false);
                    
                else
                    % if there is more than one feasible group, then
                    % determine which is the more likely grouping
                    if sum(isFeas) > 1
                        % FINISH ME!
                        a = 1;
                    end
                        
                    % calculates the max cross-correlation between the
                    % sub-images in the current grouping
                    I = Isub0(kGrp{isFeas});
                    Ixc = cellfun(@(x)(max(max(...
                                        normxcorr2(x,I{1})))),I(2:end));                    
                    if median(Ixc) > xcTol                                                
                        % if the median x-correlation value is above
                        % tolerance, then return the grouping coordinates
                        fPos = fPosT(kGrp{isFeas},:);
                        
                    else
                        % otherwise, flag that the sub-region doesn't have
                        % a moving object
                        [fPos,ok] = deal([],false);                        
                    end
                        
                end                        
                
            end
        end                   
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %         
        
        % --- outputs to screen 
        function outputEmptyRegionMsg(obj)
            
            % determines if any of the regions are empty
            iStat = cell2mat(obj.iMov.Status);
            [iT,iApp] = find(iStat==3);
            
            % if there are empty regions, then exit the function
            if isempty(iT)
                return
            else                
                [iAppU,iB,iC] = unique(iApp);   
                obj.iMov.flyok(iStat==3) = false;
            end            
            
            % sets up the main message string
            mStr0 = 'The following sub-regions appear to be empty';
            mStr = sprintf('%s:\n\n',mStr0);
            
            % groups the empty sub-regions information by region         
            for i = 1:length(iAppU)
                % appends the region title
                mStr = sprintf('%s => Region #%i:\n',mStr,iAppU(i));
                
                % sets the empty subregion information into a single string
                iTU = iT(iC==iB(i));
                mStrT = sprintf('  -> Sub-Regions: %i',iTU(1));                
                for j = 2:length(iTU)
                    mStrT = sprintf('%s, %i',mStrT,iTU(j));
                end
                
                % appends the sub-region information
                mStr = sprintf('%s%s\n',mStr,mStrT);
            end                        
            
            % sets the final prompt string portion
            mStr = sprintf(['%s\nIf not, then you will need to ',...
                            'manually resegment these regions.'],mStr);                
            
            % outputs the message to screen
            obj.hProg.setVisibility(0);
            waitfor(msgbox(mStr,'Potentially Empty Regions','modal'))
            obj.hProg.setVisibility(1);
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
        
        % --- groups the objects by their proximity to each other
        function jGrp = distGroupObj(Isub0,iGrp,fPos0,fPosT)
            
            % parameters
            dTol = 5;
            xcTol = 0.85;
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
                        
                    elseif ~any(dPos(iGrp{j},i)<dTol)
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
            
            % keep looping until all groups 
            jGrp = [];
            isF = false(nObj,1);
            while any(~isF)
                % determines the next ungrouped object, and the frame from
                % which the object came
                iNw = find(~isF,1,'first');
                iFrm = find(cellfun(@(x)(any(x==iNw)),iGrp));
                
                %
                [jGrp{end+1},isF(iNw)] = deal(iNw,true);
                for j = (iFrm+1):nFrm
                    % determines if there are any points from the next
                    % frame that can be added to the group
                    ii = (dPos(iGrp{j},iNw) >= 0) & ~isF(iGrp{j});
                    if any(ii)
                        % if so, determine
                        k = iGrp{j}(ii);
                        Ixc = normxcorr2(Isub0{iNw},Isub0{k});
                        
                        %
                        if max(Ixc(:)) > xcTol
                            isF(k) = true;
                            jGrp{end}(end+1) = k;
                        else
                            break
                        end
                        
                    else
                        % otherwise, exit the loop
                        break
                    end
                end
            end            
            
        end                 
        
        % --- calculates the temporary background image
        function ImgL = setTempBGImage(ImgL,fPos)
            
            % parameters
            nSD = 2.5;
            nDil = 2;
            
            %
            Brmv0 = ImgL > nSD*std(ImgL(:));
            [~,Brmv] = detGroupOverlap(Brmv0,fPos);
            
            % removes the region surrounding the object
            ImgL(bwmorph(Brmv,'dilate',nDil)) = NaN;
            
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
        function Isub = getResSubImage(I,p)
            
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
            
        end
        
        %
        function iFrm = getFrameMatch(iGrp,iObj)
           
            if iscell(iGrp)
                iFrm = find(cellfun(@(y)(any(y==iObj)),iGrp));
            else
                iFrm = find(arrayfun(@(y)(any(y==iObj)),iGrp));
            end
            
        end
    end
end