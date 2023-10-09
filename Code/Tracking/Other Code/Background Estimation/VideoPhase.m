classdef VideoPhase < handle
    
    % class properties
    properties
        
        % main class properties
        iMov
        iData
        hProg
        iLvl
        calcOK
        
        % other class properties
        nApp
        rOpt
        rMet
        iFrm0
        Dimg0
        phsP
        
        % image/region arrays
        sz0
        iR0
        iC0
        Img0
        ILF
        Dimg
        Imu
        indH1S
        
        % other class fields
        hS
        pOfs
        IrefF
        
        % variable parameters
        nDS
        hasT
        hasF
        isBig
        isCheck
        closePB = false;
        autoDetect = false;
        
        % phase detection fields
        iPhase
        vPhase
        
        % homomorphic filter parameters
        aHM = 0;
        bHM = 1;
        sigHM = 15;
        hmFilt
        
        % histogram tolerances
        eDistTol = 0.035;
        mDistTol = 0.25;
        iSectTol = 0.875;
        vCosTol = 0.95;
        xi2Tol = 0.15;
        dHistTol = 20;
        pOfsMin = 0.49;
        pTile = 25;
        
        % other fixed parameters        
        isHT1
        nPhMax        
        tOfs = 1;
        sFlag = 0;
        Dtol = 100;
        nPhaseMx = 50;
        nFrm0 = 15;
        szDS = 800;
        szBig = 1400;
        dnFrmMin = 25;
        NTmx = 500;
        isFeasVid = true;
        refSearch = false;
        pTolPhase = 5;
        hasSR = false;
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = VideoPhase(iData,iMov,hProg,iLvl,autoDetect)
            
            % sets the default input arguments
            if ~exist('autoDetect','var'); autoDetect = false; end
            
            % sets the main class properties
            obj.iMov = iMov;
            obj.iData = iData;
            obj.autoDetect = autoDetect;
            
            % sets the secondary input fields
            if exist('hProg','var')
                obj.hProg = hProg;
                obj.iLvl = iLvl;
            end
            
            % initialises the class fields
            obj.initClassFields();
            
        end
        
        % --- initialises the class object fields
        function initClassFields(obj)
            
            % field retrieval
            if ~isfield(obj.iData,'iExpt')
                obj.isHT1 = false;
            elseif isfield(obj.iData.iExpt,'Device')
                Device = obj.iData.iExpt.Device;
                obj.isHT1 = any(strContains(Device.DAQ,'HTControllerV1'));
            else
                obj.isHT1 = false;
            end
            
            % sets the region count
            if isfield(obj.iMov,'posO')
                obj.nApp = length(obj.iMov.posO);
            else
                obj.nApp = length(obj.iMov.pos);
            end
            
            % other class fields
            obj.sFlag = 0;
            [obj.rOpt,obj.rMet] = imregconfig('monomodal');
            obj.rOpt.MaximumIterations = 250;
            obj.nFrm0 = min(obj.iData.nFrm,(1+obj.isHT1)*obj.nFrm0);
            
            % sets the maximum phase count
            if ~isfield(obj.iMov.bgP.pPhase,'nPhMax')
                obj.nPhMax = roundP((2/3)*obj.iMov.bgP.pPhase.nImgR);
            else
                obj.nPhMax = obj.iMov.bgP.pPhase.nPhMax;
            end
            
            % sets the variable fields
            obj.sz0 = getCurrentImageDim;
            obj.isBig = any(obj.sz0 > obj.szBig);
            obj.nDS = max(floor(obj.sz0/obj.szDS)) + 1;            
            
            % sets up the image filter
            bgP = getTrackingPara(obj.iMov.bgP,'pSingle');
            if bgP.useFilt
                obj.hS = fspecial('disk',bgP.hSz);
            end
            
            % retrieves/sets the region outline coordinates
            if obj.autoDetect
                posO = getCurrentRegionOutlines(obj.iMov);
            elseif ~obj.iMov.isSet
                obj.nApp = 1;
                posO = {[1,1,(flip(obj.iData.sz)-1)]};
            elseif isfield(obj.iMov,'posO')
                posO = obj.iMov.posO;
            else
                posO = obj.iMov.pos;
            end
            
            % memory allocation
            obj.indH1S = [];
            [obj.hasT,obj.hasF] = deal(false);
            [obj.iR0,obj.iC0] = deal(cell(obj.nApp,1));
            [obj.IrefF,obj.pOfs] = deal(cell(obj.nApp,1));
            obj.ILF = cell(obj.nFrm0,obj.nApp);
            
            % sets the region row/column indices
            for iApp = 1:obj.nApp
                pP = posO{iApp};
                obj.iR0{iApp} = ceil(pP(2))+(0:floor(pP(4)));
                obj.iC0{iApp} = ceil(pP(1))+(0:floor(pP(3)));
            end
            
%             % SPECIAL CASE - for HT1 controllers, the phases where
%             % stimuli events occur must be treated separately than
%             % other phase types
%             if obj.isHT1 && ~isempty(obj.iData.stimP)
%                 obj.setupHT1StimIndices();
%             end
            
        end
        
        % --------------------------------- %
        % --- PHASE DETECTION FUNCTIONS --- %
        % --------------------------------- %
        
        % --- runs the phase detection algorithm
        function runPhaseDetect(obj,varargin)
            
            % runs the pre-initial detection. if theres an issue then exit
            if ~obj.preDetectSetup(nargin==2)
                return
            end
            
            % updates the progressbar
            obj.updateProgField('Region Property Calculations',0.5);
            
            % calculates the initial information for each region
            for iApp = 1:obj.nApp
                % updates the progressbar
                wStrNw = sprintf(['Calculating Region Properties ',...
                    '(Region %i of %i)'],iApp,obj.nApp);
                if obj.updateSubProgField(wStrNw,iApp/obj.nApp)
                    % if the user cancelled, then exit
                    obj.calcOK = false;
                    return
                end
                
                % calculates the region information
                [IL,obj.ILF(:,iApp)] = obj.setupRegionInfoStack(iApp);
                obj.Dimg(obj.iFrm0,iApp) = obj.calcAvgImgIntensity(IL,iApp);                
            end
            
            % optimises the frame group limits
            iGrpF = obj.optFrameGroupLimits();
            obj.checkFinalFrameGroups(iGrpF);
            
            % closes the progressbar (if required)
            if obj.closePB
                obj.hProg.closeProgBar();
            end
            
        end
        
        % --- pre-detection setup function
        function ok = preDetectSetup(obj,initPB)
            
            % initialisations
            ok = true;
            
            % retrieves the phase tracking parameters
            obj.phsP = getTrackingPara(obj.iMov.bgP,'pPhase');
            obj.hasT = false(1,obj.nApp);
            
            % creates the progress bar (if not provided)
            if initPB
                wStr = {'Overall Progress',...
                    'Reading Initial Frame Stack'};
                obj.hProg = ProgBar(wStr,'Phase Detection');
                obj.closePB = true;
            end
            
            % reads the initial image stack
            obj.getInitialImgStack();
            if ~obj.isFeasVid
                % updates the progressbar
                obj.updateProgField('Infeasible Video Detected',1);
                
                % flag that the video is untrackable
                [obj.vPhase,obj.iPhase] = deal(3,[1,obj.iData.nFrm]);
                
                % closes the progressbar (if required)
                if obj.closePB
                    obj.hProg.closeProgBar();
                end
                
                % exits the function
                ok = false;
                return
            end
            
            % determines the video properties
            if ~obj.isHT1
                obj.detVideoProps();
            end
            
        end
        
        % --- calculates the region information
        function getInitialImgStack(obj)
            
            % updates the progress bar
            obj.updateProgField('Reading Initial Image Stack',1/6);
            obj.updateSubProgField('Initialising Image Read...',0);
            
            % resets the
            obj.calcOK = true;
            obj.isCheck = false(obj.iData.nFrm,1);
            obj.Dimg = sparse(obj.iData.nFrm,obj.nApp);
            
            % retrieves the initial image stack
            obj.iFrm0 = roundP(linspace(1,obj.iData.nFrm,obj.nFrm0));
            obj.Img0 = obj.getImageStack();
            
            % if the user cancelled, then exit
            if ~obj.calcOK; return; end
            
            % determines if there is any significant translation over
            % the video
            obj.isBig = any(size(obj.Img0{1}) > obj.szBig);
            
            % calculates the mean image intensity over all image regions
            if obj.iMov.isSet
                [iR,iC] = deal(obj.iMov.iR,obj.iMov.iC);
            else
                [iR,iC] = deal(obj.iR0,obj.iC0);
            end
            
            % set up the mean values
            obj.Imu = cell2mat(cellfun(@(x)(cellfun(@(ir,ic)(mean...
                (arr2vec(x(ir,ic)),'omitnan')),iR,iC)),...
                obj.Img0(:),'un',0));
            
            % determines if the video is trackable
            obj.isFeasVid = any((obj.Imu(:) > obj.phsP.pTolLo) & ...
                (obj.Imu(:) < obj.phsP.pTolHi));
            
            % updates the progressbar
            obj.updateSubProgField('Image Estimate Read Complete',1);
            
        end
        
        % --- determines the video properties based on the image
        %     translation and average pixel intensity fluctations
        function detVideoProps(obj)
            
            % if the user already cancelled, then exit the function
            if ~obj.calcOK; return; end
            
            % updates the progress bar
            obj.updateProgField('Initialising Property Detection',2/6);
            obj.updateSubProgField('Determining Video Properties',0);            
            
            % determines the frames which are feasible
            isOK = any((obj.Imu > obj.phsP.pTolLo) & ...
                (obj.Imu < obj.phsP.pTolHi),2);
            [i0,i1] = deal(find(isOK,1,'first'),find(isOK,1,'last'));
            
            % updates the progressbar
            obj.updateSubProgField('Determining Video Translation',0.25);
            ImgHM = cellfun(@(x)(applyHMFilter(x)),obj.Img0([i0,i1]),'un',0);
            pOfs0 = obj.estImgOffset(ImgHM{2},ImgHM{1});
            
            % if there is significant translation, then determine which
            % regions have significant shift
            if any(abs(pOfs0) > obj.pOfsMin)
                obj.hasT(:) = true;
            end
            
            %                 [p0,pW] = deal(0.25,0.5);
            %                 for i = 1:obj.nApp
            %                     % updates the progress bar
            %                     pNw = p0 + i*pW/(1+obj.nApp);
            %                     wStrR = sprintf(['Calculating Region Translation ',...
            %                                      '(Region %i of %i)'],i,obj.nApp);
            %                     if obj.updateSubProgField(wStrR,pNw)
            %                         % if the user cancelled, then exit
            %                         obj.calcOK = false;
            %                         return
            %                     end
            %
            %                     % retrieves the local image stack
            %                     [iR,iC] = deal(obj.iR0{i},obj.iC0{i});
            %                     IL = cellfun(@(x)(x(iR,iC)),obj.Img0([1,end]),'un',0);
            %                     IL = cellfun(@(x)(applyHMFilter(x)),IL,'un',0);
            %
            %                     % calculates offset between the first/last frames, and
            %                     % from this determine if there is signficant movement
            %                     pOfs0 = obj.estImgOffset(IL{1},IL{1});
            %                     pOfs1 = obj.estImgOffset(IL{2},IL{1});
            %                     obj.hasT(i) = any(abs(pOfs0-pOfs1) > 0.4);
            %                 end
            %             end
            
            % updates the progressbar
            wStr2 = 'Determining Lighting Fluctuations';
            if obj.updateSubProgField(wStr2,0.75)
                % if the user has cancelled, then exit
                obj.calcOK = false;
                return
            end
            
            % determines if there are any:
            %  A) phases in avg. pixel intensity, or
            %  B) severe fluctuation in avg. pixel intensity
            ImgI = cellfun(@(x)(dsimage(x,obj.nDS)),obj.Img0,'un',0);
            obj.Dimg0 = cellfun(@(x)(mean(x(:),'omitnan')),ImgI);
            Dmu = pdist2(obj.Dimg0(:),obj.Dimg0(:));
            iFrmG0 = obj.estPhaseFrameGroups(Dmu,obj.iFrm0);
            
            % determines if there are a large number of phases
            % (unstable image fluctuation)
            obj.hasF = size(iFrmG0,1) > obj.nPhMax;
            if obj.hasF
                % if so, then set up the hm filter images
                obj.sFlag = -2;
                obj.hmFilt = arrayfun(@(x)...
                    (obj.setupHMFilterW(x)),1:obj.nApp,'un',0)';
            end
            
            % updates the progressbar
            wStrF = 'Video Property Detection Complete';
            obj.calcOK = ~obj.updateSubProgField(wStrF,1);
            obj.Dtol = 5+obj.hasF;
            
        end
        
        % --- sets up the region information image stack
        function [IL,ILT] = setupRegionInfoStack(obj,iApp,ImgL)
            
            % retrieves the base image stack
            if ~exist('ImgL','var'); ImgL = obj.Img0; end
            
            % retrieves the raw region image stack
            [iR,iC] = deal(obj.iR0{iApp},obj.iC0{iApp});
            IL = cellfun(@(x)(x(iR,iC)),ImgL,'un',0);
            
            % if there is severe light fluctuation or translation, then
            % calculate the hm-filtered images
            if obj.hasF
                IL = cellfun(@(x)(obj.applyHMFilter...
                    (x,obj.hmFilt{iApp})),IL,'un',0);
                obj.IrefF{iApp} = uint8(calcImageStackFcn(IL,'max'));
                IL = cellfun(@(x)(double((imhistmatch...
                    (uint8(x),obj.IrefF{iApp},256)))),IL,'un',0);
            end
            
            % if there is significant image translations then estimate the
            % image offset over the duration of the video
            if obj.hasT(iApp)
                % memory allocation
                ILT = cell(obj.nFrm0,1);
                pOfs0 = NaN(obj.nFrm0,2);
                
                % calculates the image offset over the video
                for k = 1:obj.nFrm0
                    pOfs0(k,:) = obj.estImgOffset(IL{k},IL{1});
                    ILT{k} = obj.applyImgTrans(IL{k},pOfs0(k,:));
                end
                
                % sets the position offset coordinates
                obj.pOfs{iApp} = pOfs0 - pOfs0(1,:);
            else
                % if there is no translation, then update the image array
                ILT = IL;
            end
            
            %
            if obj.isHT1
                % performs the histogram matching
                IRef = uint8(calcImageStackFcn(IL));
                IL = calcHistMatchStack(IL,IRef);
                
                % sets the translated images (if required)
                if obj.hasT(iApp)
                    ILT = calcHistMatchStack(ILT,IRef);
                else
                    ILT = IL;
                end
            end
            
        end
        
        % --- optimises the frame grouping limits
        function iGrpF = optFrameGroupLimits(obj)
            
            % if the user already cancelled, then exit the function
            if ~obj.calcOK
                iGrpF = [];
                return
            end
            
            % parameters and initialisations
            iFrmC = find(obj.Dimg(:,1));
            nFrmC = length(iFrmC);
            [isF,iGrpF] = deal(false(nFrmC,1),cell(nFrmC,1));
            
            % updates the progressbar
            obj.updateProgField('Frame Grouping Limit Optimisation',4/6);
            obj.updateSubProgField('Frame Limit Detection',0);
            
            % determines if the video has high fluctuation
            if obj.hasF
                % if so, then video only has one phase
                iGrpF = arr2vec(iFrmC([1,end]))';
                
                % updates the progressbar
                obj.updateSubProgField('Frame Group Limit Detection',1);
                return
            end
            
            % ----------------------------------------- %
            % --- INITIAL FRAME GROUPING ESTIMATION --- %
            % ----------------------------------------- %
            
            % determines which frames are reasonably within tolerance
            DimgF = obj.getDimg(iFrmC);
            D0 = cellfun(@(x)(pdist2(x(:),x(:))),num2cell(DimgF,1),'un',0);
            D = calcImageStackFcn(D0,'max');
            BD = D <= obj.Dtol;
            
            % determines the frame groupings (which have similarity scores
            % that are within tolerances)
            for j = 1:size(BD,2)
                % determines the feasible adjacent frames
                ii = j:nFrmC;
                jGrpF = getGroupIndex(BD(ii,j));
                
                % determines if the new grouping adds on any unique frames
                % to the searched boolean array
                iGrpB = ii(jGrpF{1});
                if any(~isF(iGrpB))
                    % determines if all interframe values are within
                    % tolerance
                    BDF = BD(iGrpB,iGrpB);
                    if ~all(BDF(:))
                        % if not, then remove the non-viable frames
                        X = tril(BDF) | triu(true(size(BDF)));
                        iGrpB = iGrpB(1:(find(any(~X,2),1,'first')-1));
                    end
                    
                    % updates the found indices and frame groups
                    if any(~isF(iGrpB))
                        [iGrpF{j},isF(iGrpB)] = deal(iGrpB,true);
                        
                        % if all frames are searched, then exit the loop
                        if all(isF); break; end
                    end
                end
            end
            
            % ---------------------------------------- %
            % --- INITIAL FRAME GROUPING REDUCTION --- %
            % ---------------------------------------- %
            
            % reduces the empty frame grouping index cells
            iCol = find(~cellfun('isempty',iGrpF));
            iGrpF = iGrpF(iCol);
            
            % sets up the feasible frame index array
            Dtot = NaN(nFrmC,length(iCol));
            for i = 1:length(iGrpF)
                Dtot(iGrpF{i},i) = i;
            end
            
            % resets the found array
            isF(:) = false;
            
            % keep looping which there is ambiguity in the optimal frame
            % group (for any of the frames)
            while 1
                % determines the next row that has more than one potential
                % frame group AND hasn't already been searched
                iNw = find(~isF & (sum(~isnan(Dtot),2)>1),1,'first');
                if isempty(iNw)
                    % if there are no such rows, then exit the loop
                    break
                else
                    % otherwise, flag that the current frame has been
                    % searched (and won't be searched again)
                    isF(iNw) = true;
                end
                
                % determines the columns
                jNw = find(~isnan(Dtot(iNw,:)));
                indF = iGrpF{jNw(2)};
                if indF > 1
                    % retrieves the distance sub-array
                    DGrp = D(indF(2:end),iCol(jNw));
                    
                    % determines the first
                    [~,imn] = min(DGrp,[],2);
                    jmn = find(imn==2,1,'first');
                    
                    % resets the index array for the optimal frame groups
                    if isempty(jmn)
                        % first frame group has a lower similarity metric
                        Dtot(indF(1:end-1),jNw(2)) = NaN;
                    else
                        % otherwise, combination of first/second groups
                        Dtot(indF((jmn):end),jNw(1)) = NaN;
                        Dtot(indF(1:(jmn-1)),jNw(2)) = NaN;
                    end
                end
            end
            
            % ------------------------------------------ %
            % --- COARSE FRAME GROUPING OPTIMISATION --- %
            % ------------------------------------------ %
            
            % parameters
            dVtol = 1.0;
            pTolMin = 0.15;
            nGrpSearch = 10;
            nFrmGrpMax = 25;
            
            % determines the coarse frame groupings
            Dtot = Dtot(:,any(~isnan(Dtot),1));
            iFrmG = cell2mat(cellfun(@(x)([find(~isnan(x),1,'first'),...
                find(~isnan(x),1,'last')]),num2cell(Dtot,1)','un',0));
            
            % other initialisations
            nGrp = size(iFrmG,1);
            iGrpC = cell(nGrp-1,1);
            
            % sets the frames that are checked
            indChk0 = [iFrmC(1):iFrmC(iFrmG(1,2)),...
                iFrmC(iFrmG(end,1)):iFrmC(end)];
            obj.isCheck(indChk0) = true;
            if obj.updatePhaseDetectionProgress()
                % if the user cancelled, then exit the function
                obj.calcOK = false;
                return
            end
            
            % search the phases based on decreasing size
            nG = iFrmG(2:end,1)-iFrmG(1:end-1,1);
            [~,iS] = sort(nG,'descend');
            for i = iS(:)'
                % determines the phase limits within the coarse limits
                ii = [iFrmG(i,2),iFrmG(i+1,1)];
                frm0 = iFrmC(ii);
                
                % calculates the coarse phase limits
                if diff(frm0) == 0
                    iGrpC{i} = {frm0};
                else
                    % otherwise, determine the existence of any sub-phases
                    % within the coarse phase group
                    iGrpC{i} = obj.detCoarsePhaseLimits(frm0);
                    
                    % combines the detected phases into a single array
                    iGrpT = cell2cell(iGrpC{i});
                    if (size(iGrpT,1) >= nGrpSearch) || obj.refSearch
                        % if there is a significant number of sub-phases
                        % detected, then perform a very fine search of
                        % the coarse phase (fills any large frame gaps)
                        obj.refSearch = true;
                        iGrpC{i} = obj.refineCoarseSearch(iGrpT,frm0);
                    end
                end
                
                % updates the progressbar
                if obj.updatePhaseDetectionProgress()
                    % if the user cancelled, then exit the function
                    obj.calcOK = false;
                    return
                end
            end
            
            % determines the
            X = cell2mat(cellfun(@(x)(cell2cell(x)),iGrpC,'un',0));
            if isempty(X)
                indG = arr2vec(iFrmC([1,end]))';
            else
                indG = [[iFrmC(1);X(:,2)],[X(:,1);iFrmC(end)]];
            end
            
            % sets the frame indices
            if iscell(obj.Dimg)
                iFrmF = find(obj.Dimg{1}(:,1));
            else
                iFrmF = find(obj.Dimg(:,1));
            end
            
            % for each for the frame groupings, determine the valid frames
            % indices
            indG0 = indG;
            iFrmGrp = cellfun(@(x)(iFrmF...
                ((iFrmF>=x(1))&(iFrmF<=x(2)))),num2cell(indG,2),'un',0);
            nFrmGrp = diff(indG,[],2) + 1;
            
            % calculates the mean intensities/gradients for each groupings
            pGrp = obj.calcFrmGroupGradient(iFrmGrp);
            
            % determines if any adjacent frame groupings can be combined
            % either by A) having a small distance difference, or B) having
            % a similar distance gradient over the frame grouping
            isOK = true(size(indG,1),1);
            for i = 2:length(isOK)
                % calculates estimated pixel intensity average and
                % compares it with the actual value
                iNw = [indG(i-1,2),indG(i,1)];
                D0 = obj.calcDist(iNw(1),1);
                Dact = obj.calcDist(iNw(2),1);
                [dT,Vest] = deal(diff(iNw),pGrp(i-1));
                
                % determines if the the frame groups can be combined
                if isnan(Vest) || any(nFrmGrp(i+[-1,0]) > nFrmGrpMax)
                    inTol = false;
                elseif abs(Vest) < pTolMin
                    % if the gradient of the previous frame group is
                    % low, then compare the estimated/actual distances
                    Dpr = obj.calcDist(iFrmGrp{i-1},1);
                    Dnw = obj.calcDist(iFrmGrp{i},1);
                    dD = pdist2(Dpr,Dnw);
                    
                    inTol = max(dD(:)) < obj.Dtol;
                else
                    % otherwise, compare the gradients of the
                    % actual/estimate values (between frame groups)
                    Vact = (Dact-D0)/dT;
                    dV = abs(Vact-Vest);
                    inTol = (dV < dVtol) && (sign(Vact)==sign(Vest));
                end
                
                % if the difference is within tolerance, then
                % remove the limit marker for the current grouping
                if inTol
                    obj.isCheck(indG0(i-1,1)+1:indG0(i,2)-1) = true;
                    [indG(i-1,2),indG(i,1)] = deal(NaN);
                    
                    % updates the progressbar
                    if obj.updatePhaseDetectionProgress()
                        % if the user cancelled, then exit the function
                        obj.calcOK = false;
                        return
                    end
                end
            end
            
            % sets the final frame grouping indices
            indF = cellfun(@(x)(x(~isnan(x))),num2cell(indG,1),'un',0);
            iGrpF = cell2mat(indF);
            
            % updates the progressbar
            obj.updateSubProgField('Frame Group Limit Detection',1);
            
        end
        
        % --- performs a refined search of the coarsely determined
        %     phase frame limits (reduces the search gaps in the image
        %     until the largest search gap is dFrmMax in size)
        function iGrpC = refineCoarseSearch(obj,iGrpT,frm0)
            
            % initialisations
            dFrmMax = 25;
            xi = frm0(1):frm0(2);
            
            % keep searching the groupings until the frame gap < dFrmMax
            while 1
                % determines the frames that have been analysed
                if iscell(obj.Dimg)
                    iFrmD = find(obj.Dimg{1}(xi,1)) + (xi(1)-1);
                else
                    iFrmD = find(obj.Dimg(xi,1)) + (xi(1)-1);
                end
                
                % determines if there are any large frame gaps remaining
                dFrmD = diff(iFrmD);
                ii = find(dFrmD(:)' > dFrmMax);
                if isempty(ii)
                    % if there are no large gaps, then exit the loop
                    break
                else
                    % otherwise, set the large frame group index array
                    iNw = [iFrmD(ii),iFrmD(ii+1)];
                end
                
                % resets the phase detection progressbar
                for i = 1:size(iNw,1)
                    obj.isCheck((iNw(i,1)+1):iNw(i,2)-1) = false;
                    if obj.updatePhaseDetectionProgress()
                        % finish me...
                    end
                end
                
                % performs the refined search of the large gaps
                iGrpTmp = cell(length(ii),1);
                for i = 1:length(iGrpTmp)
                    % calculates the phase limits of the gap
                    jGrpT = cell2cell(obj.detCoarsePhaseLimits(iNw(i,:)));
                    if size(jGrpT,1) > 1
                        % if multiple sub-phases were found then store them
                        isAdd = true;
                    else
                        % otherwise, determine if the phase limit is valid
                        % (i.e., there is a change in pixel tolerance)
                        if iscell(obj.Dimg)
                            dD = abs(diff...
                                (mean(full(obj.Dimg{1}(jGrpT,:)),2)));
                        else
                            dD = abs(diff...
                                (mean(full(obj.Dimg(jGrpT,:)),2)));
                        end
                        
                        isAdd = dD > obj.Dtol;
                    end
                    
                    % adds on the data to the storage array (if required)
                    if isAdd
                        if jGrpT(end,2) < iGrpT(1,1)
                            % case is frame indices are placed before
                            iGrpT = [jGrpT;iGrpT];
                        elseif jGrpT(1,1) > iGrpT(end,2)
                            % case is frame indices are placed after
                            i0 = find(jGrpT(1,1) > iGrpT(:,2),1,'last');
                            iGrpT = [iGrpT(1:i0,:);jGrpT;iGrpT(i0+1:end,:)];
                        end
                    end
                end
                
            end
            
            % resets the index values
            iGrpC = {iGrpT};
            
        end
        
        % --- calculates the frame group gradients
        function [pGrp,DGrpMn] = calcFrmGroupGradient(obj,iFrmGrp)
            
            % calculates the
            DGrp = cellfun(@(x)(obj.getDimg(x)),iFrmGrp,'un',0);
            DGrpMn = cellfun(@(x)(mean(x,2,'omitnan')),DGrp,'un',0);
            
            % calculates the linear fits for each frame grouping
            pGrp = NaN(length(iFrmGrp),1);
            for i = 1:length(iFrmGrp)
                if length(iFrmGrp{i}) > 1
                    lFit = polyfit(iFrmGrp{i},DGrpMn{i},1);
                    pGrp(i) = lFit(1);
                end
            end
            
        end
        
        % --- checks the final frame groupings
        function checkFinalFrameGroups(obj,iGrpF)
            
            % if the user already cancelled, then exit the function
            if ~obj.calcOK; return; end
            
            % updates the progress bar
            obj.updateProgField('Checking Frame Groupings',5/6);
            obj.updateSubProgField('Setting Phase Classification...',0);
            
            % parameters
            pTolRng = 0.25*256;         % pixel range tolerance
            
            % memory allocation
            nGrpF = size(iGrpF,1);
            DimgF = cell(nGrpF,1);
            vPhaseF = zeros(nGrpF,1);
            
            if nGrpF > obj.nPhaseMx
                % if there are a large number of phases, then flag the
                % video as having high pixel fluctuation
                [obj.hasF,obj.sFlag] = deal(true,-1);
                [iPhaseF,vPhaseF] = deal([1,obj.iFrm0(end)],1);
                
                % sets up the hm filter masks
                [iR,iC] = deal(obj.iMov.iR,obj.iMov.iC);
                obj.hmFilt = cellfun(@(ir,ic)(...
                    obj.setupHMFilterW(ir,ic)),iR,iC,'un',0);
                
                % set the final class field values
                [obj.iPhase,obj.vPhase] = deal(iPhaseF,vPhaseF);
                
                % updates the progress bar and exits the function
                obj.updateSubProgField('Final Grouping Check Complete',1);
                return
            end
            
            % determines if the phases can be combined/reduced
            for i = 1:nGrpF
                % retrieves the non-sparse frames for the current group
                iGrpNw = iGrpF(i,1):iGrpF(i,2);
                if iscell(obj.Dimg)
                    iFrmG = find(obj.Dimg{1}(iGrpNw,1)) + (iGrpF(i,1)-1);
                else
                    iFrmG = find(obj.Dimg(iGrpNw,1)) + (iGrpF(i,1)-1);
                end
                
                % determines if the frame range is too low for tracking
                DimgF{i} = obj.getDimg(iFrmG);
                if obj.isHT1
                    % SPECIAL CASE - HT1 Controller
                    vPhaseF(i) = 4;
                    
                elseif all(DimgF{i}(:) < pTolRng)
                    % pixel range is too low, so set as untrackable
                    vPhaseF(i) = 3;
                else
                    % otherwise, determine if the mean pixel intensity is
                    % either too high or too low for tracking
                    if any(DimgF{i}(:)<obj.phsP.pTolLo) || ...
                            any(DimgF{i}(:)>obj.phsP.pTolHi)
                        % the mean pixel intensity is either too high/low.
                        % therefore, flag that the phase is untrackable
                        vPhaseF(i) = 3;
                        
                    elseif obj.hasF
                        % case is there is severe fluctuation
                        vPhaseF(i) = 1;
                        
                    else
                        % otherwise, set the phase type (either low
                        % variance or short/high pixel variation)
                        isShort = diff(iGrpF(i,:)) <= obj.dnFrmMin;
                        isHiDiff = any(range(DimgF{i},1) > 2*obj.Dtol);
                        vPhaseF(i) = 1 + (isShort || isHiDiff);
                    end
                end
            end
            
            % calculates the mean frame grouping avg pixel intensities
            DimgFmu = cellfun(@(x)(mean(x,2)),DimgF,'un',0);
            
            % ------------------------------------ %
            % --- PHASE REDUCTION CALCULATIONS --- %
            % ------------------------------------ %
            
            % updates the progressbar
            obj.updateSubProgField('Phase Reduction Calculations...',0.25);
            
            % determines which adjacent phases are either
            % medium/untrackable phases AND have a small number of frames
            isOK = true(size(vPhaseF));
            for i = 2:length(vPhaseF)
                ii = i + [-1,0];
                joinPhases = false;
                if all(vPhaseF(ii) == 2)
                    % if both phases are high-variance, then
                    iFrmL = [iGrpF(ii(1),2),iGrpF(ii(2),1)];
                    [~,Imet1] = obj.getRegionImageStack(iFrmL(1));
                    [~,Imet2] = obj.getRegionImageStack(iFrmL(2));
                    Qnw = mean(cell2mat(cellfun(@(x,y)...
                        (calcHistSimMetrics(x,y)),Imet1,...
                        Imet2,'un',0)),1,'omitnan');
                    
                    % determines if the
                    [joinPhases,~] = obj.checkHistMetrics(Qnw);
                    
                elseif all(vPhaseF(ii) == 3)
                    % combine all adjacent untrackable phases
                    joinPhases = true;
                    
                end
                
                if joinPhases
                    % if so, then combine the phases
                    isOK(i-1) = false;
                    iGrpF(i,1) = iGrpF(i-1,1);
                end
            end
            
            % reduces the phase limits
            [vPhaseF,DimgFmu] = deal(vPhaseF(isOK),DimgFmu(isOK));
            [iGrpF,iPhaseF] = deal(iGrpF(isOK,:),zeros(sum(isOK),2));
            for i = 1:size(iPhaseF,1)
                iPhaseF(i,:) = [iGrpF(i,1),iGrpF(i,2)];
            end
            
            % ----------------------------- %
            % --- REFERENCE IMAGE SETUP --- %
            % ----------------------------- %
            
            % updates the progressbar
            obj.updateSubProgField('Reference Image Setup...',0.5);
            
            % if there is no major image fluctuation, then check to see if
            % there are any high-variance phases (these phases are to be
            % analysed using the hm filter/imhistmatch process)
            if ~obj.hasF
                % memory allocation
                for i = 1:length(vPhaseF)
                    if range(DimgFmu{i}) > 2*obj.Dtol && (vPhaseF(i) == 1)
                        vPhaseF(i) = 2;
                    end
                end
                
                % sets up the imhistmatch reference images (if required)
                if any(vPhaseF(:)==2)
                    % sets up the hm filter masks
                    obj.hmFilt = arrayfun(@(x)(...
                        obj.setupHMFilterW(x)),1:obj.nApp,'un',0);
                end
            end
            
            % if there are a large number of phases, then flag the video as
            % having high pixel fluctuation (non-HT1 controllers only)
            if (length(vPhaseF) > obj.nPhaseMx) && ~obj.isHT1
                [obj.hasF,obj.sFlag] = deal(true,-1);
                [iPhaseF,vPhaseF] = deal([1,obj.iFrm0(end)],1);
                
                % sets up the hm filter masks
                [iR,iC] = deal(obj.iMov.iR,obj.iMov.iC);
                obj.hmFilt = cellfun(@(ir,ic)(...
                    obj.setupHMFilterW(ir,ic)),iR,iC,'un',0);
            end
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % set the final class field values
            [obj.iPhase,obj.vPhase] = deal(iPhaseF,vPhaseF);
            
            % updates the progress bar
            obj.updateSubProgField('Final Grouping Check Complete',1);
            
        end
        
        % --------------------------------------- %
        % --- PHASE LIMIT DETECTION FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- determines if the histogram metrics between phases are
        %     within tolerance (and hence can be combined)
        function [joinPhases,meetsTol] = checkHistMetrics(obj,Q)
            
            % determines if the inter-phase histogram metrics are all
            % within tolerance
            meetsTol = [Q(1) < obj.eDistTol,...     % euclidean distance tolerance
                Q(2) < obj.mDistTol,...     % manhattan distance tolerance
                Q(3) > obj.iSectTol,...     % intersection distance tolerance
                Q(4) > obj.vCosTol,...      % vector cosine distance tolerance
                Q(5) < obj.xi2Tol,...       % chi2 distance tolerance
                abs(Q(6)) < obj.dHistTol];  % histogram shift distance tolerance
            
            % determines if all the metrics meets tolerance
            joinPhases = all(meetsTol);
            
        end
        
        % --- determines the coarse phase limits
        function iFrmG = detCoarsePhaseLimits(obj,iFrm0)
            
            % calculates the number of sub-frame checks
            N0 = min(5,diff(iFrm0)+1);
            
            % calculates the metrics for the new frames
            iFrmG0 = roundP(linspace(iFrm0(1),iFrm0(2),N0));
            arrayfun(@(x)(obj.calcRegionAvgInt(x)),iFrmG0);
            
            % calculates the difference in the distance values
            Davg = obj.calcDist(iFrmG0);
            if obj.hasSR
                dDavg = max(abs(diff(Davg,[],1)),[],2);
                Davg = mean(Davg,2);
            else
                dDavg = abs(diff(Davg));
            end
            
            % determines if there is a major difference in pixel intensity
            iDiff = find(dDavg > obj.Dtol);
            if isempty(iDiff)
                % if there is no major difference, then
                [~,jmn] = min(abs(repmat(Davg,1,2) - Davg([1,end])'),[],2);
                kGrp = getGroupIndex(jmn == 1);
                iFrmD = iFrmG0(kGrp{1}(end) + [0,1]);
                
                % updates the progressbar
                i0 = iFrm0(1):(iFrmD(1)-1);
                i1 = (iFrmD(2)+1):iFrm0(end);
                obj.isCheck([i0,i1]) = true;
                if obj.updatePhaseDetectionProgress()
                    % if the user cancelled, then exit the function
                    [obj.calcOK,iFrmG] = deal(false,[]);
                    
                elseif diff(iFrmD) == 1
                    % case is the region can't be split further
                    iFrmG = {iFrmD};
                    
                else
                    %
                    iFrmGNw = detCoarsePhaseLimits(obj,iFrmD);
                    if isempty(iFrmGNw)
                        [obj.calcOK,iFrmG] = deal(false,[]);
                    else
                        iFrmG = {cell2cell(iFrmGNw)};
                    end
                end
                
                % exits the function
                return
            end
            
            % updates the progressbar
            obj.isCheck(iFrm0(1):iFrmG0(iDiff(1))-1) = true;
            obj.isCheck(iFrmG0(iDiff(end)+1)+1:iFrm0(2)) = true;
            if obj.updatePhaseDetectionProgress()
                % if the user cancelled, then exit
                [iFrmG,obj.calcOK] = deal([],false);
                return
            end
            
            % loops through each of the major pixel intensity differences
            % determining if any sub-phases exist
            iFrmG = cell(length(iDiff),1);
            for i = 1:length(iDiff)
                iFrmD = iFrmG0(iDiff(i)+(0:1));
                if diff(iFrmD) > 1
                    % if the frame groupings have a size greater than
                    % tolerance, then search the sub-groupings
                    iFrmGNw = detCoarsePhaseLimits(obj,iFrmD);
                    if isempty(iFrmGNw)
                        % if the user cancelled, then exit
                        [iFrmG,obj.calcOK] = deal([],false);
                        return
                    else
                        % otherwise, update the frame grouping array
                        iFrmG{i} = cell2cell(iFrmGNw);
                        
                        %                         % updates the checked frames
                        %                         obj.isCheck(iFrm0(1):iFrmG{i}(1,1)-1) = true;
                        %                         obj.isCheck(iFrmG{i}(end,2)+1:iFrm0(2)) = true;
                        %                         if obj.updatePhaseDetectionProgress()
                        %                             % if the user cancelled, then exit
                        %                             [iFrmG,obj.calcOK] = deal([],false);
                        %                             return
                        %                         end
                        
                        % updates the progressbar
                        obj.updatePhaseDetectionProgress();
                    end
                else
                    % otherwise, update the frame grouping array
                    iFrmG{i} = iFrmD;
                end
            end
            
        end
        
        % --- determines the refined frame grouping limits
        function iGrpF = detFinePhaseLimits(obj,iFrm,D0)
            
            % keep looping until either the exact frame limit has been
            % determined, or a new sub-phase is detected
            while 1
                % reads in the new frame (the mid-point between the limits)
                iFrmNw0 = roundP(mean(iFrm));
                obj.calcRegionAvgInt(iFrmNw0);
                
                % the differences in the mean image metrics versus the
                % candidate frames
                Dnw = obj.calcDist(iFrmNw0,1);
                dD = D0-Dnw;
                dDmx = max(abs(dD),[],1);
                imn = argMin(dDmx);
                
                % determines the closes matching frame group
                if dDmx(imn) < 1.5*obj.Dtol
                    % case is the new frame is within tolerance of one of
                    % the phase limit frames
                    if imn == 1
                        % case is the lower limit is within tolerance
                        obj.isCheck(iFrm(1):iFrmNw0) = true;
                    else
                        % case is the upper limit is within tolerance
                        obj.isCheck(iFrmNw0:iFrm(2)) = true;
                    end
                    
                    % updates the progressbar
                    if obj.updatePhaseDetectionProgress()
                        % if the user cancelled, then exit
                        obj.calcOK = false;
                        return
                    end
                    
                    % updates the limit frame index and metrics
                    [iFrm(imn),D0(imn)] = deal(iFrmNw0,Dnw);
                    
                    % if the exact limit is found, then exit the loop
                    if diff(iFrm) == 1
                        iGrpF = iFrm(:)';
                        break
                    end
                else
                    % otherwise, case is a new sub-phase has been detected
                    if diff(iFrm) == 2
                        % if the frame range is small, then no need to
                        % search the sub-phase limits
                        iGrpF = [[iFrm(1),iFrmNw0];[iFrmNw0,iFrm(2)]];
                    else
                        % determines the lower frame grouping
                        iFrmLo = [iFrm(1),iFrmNw0];
                        iGrpLoF = obj.detFinePhaseLimits(iFrmLo,[D0(1),Dnw]);
                        
                        % determines the upper frame grouping
                        iFrmHi = [iFrmNw0,iFrm(2)];
                        iGrpHiF = obj.detFinePhaseLimits(iFrmHi,[Dnw,D0(2)]);
                        
                        % sets the final frame index group array
                        iGrpF = [iGrpLoF;iGrpHiF];
                    end
                    
                    % exits the loop
                    break
                end
            end
            
        end
        
        % ----------------------------- %
        % --- IMAGE STACK FUNCTIONS --- %
        % ----------------------------- %
        
        % --- retrieves the region image stack
        function [IL,Imet] = getRegionImageStack(obj,iFrm)
            
            % retrieves the new image frame
            I0 = obj.getImageFrame(iFrm);
            [iR,iC] = deal(obj.iR0,obj.iC0);
            
            % retrieves the region image stack
            if isempty(I0)
                % if the image is empty, then return NaN arrays
                [IL,Imet] = deal(cellfun(@(ir,ic)...
                    (NaN(length(ir),length(ic))),iR,iC,'un',0));
                return
            else
                IL = cellfun(@(ir,ic)(I0(ir,ic)),iR,iC,'un',0);
            end
            
            % corrects image fluctuation (if required)
            if obj.hasF
                % if there is fluctuation, then apply the hm filter and the
                % histogram matching to the reference image
                Imet = cellfun(@(x,h)(obj.applyHMFilter(x,h)),...
                    IL,obj.hmFilt,'un',0);
                IL = cellfun(@(x,y)(double((imhistmatch...
                    (uint8(x),y,256)))),Imet,obj.IrefF(:),'un',0);
            else
                Imet = IL;
            end
            
            % corrects image fluctuation
            if any(obj.hasT)
                pOfsT = cellfun(@(p)(interp1...
                    (obj.iFrm0,p,iFrm,'linear','extrap')),...
                    obj.pOfs(obj.hasT),'un',0);
                IL(obj.hasT) = cellfun(@(x,p)(obj.applyImgTrans(x,p)),...
                    IL(obj.hasT),pOfsT,'un',0);
            end
            
        end
        
        % --- retrieves the image stack (for the frames, iFrm)
        function Img = getImageStack(obj)
            
            % reads the image frames
            xiF = 1:obj.nFrm0;
            Img = arrayfun(@(x)...
                (obj.getImageFrame(obj.iFrm0(x),x)),xiF,'un',0);
            
            % if the user cancelled, then exit the function
            if ~obj.calcOK; return; end
            
            % determines which frames are a) not empty, and b) not all NaNs
            isOK = ~cellfun('isempty',Img(:));
            isOK(isOK) = ~cellfun(@(x)(all(isnan(x(:)))),Img(isOK));
            
            % adds in any missing image frames
            for i = find(~isOK')
                iDir = 2*(i == 1) - 1;
                while true
                    % reads in the new frame
                    obj.iFrm0(i) = obj.iFrm0(i) + iDir;
                    ImgNw = obj.getImageFrame(obj.iFrm0(i));
                    
                    if ~isempty(ImgNw) && ~all(isnan(ImgNw(:)))
                        Img{i} = ImgNw;
                        break
                    end
                end
            end
            
        end
        
        % --- retrieves the image frame
        function Img = getImageFrame(obj,iFrm,indF)
            
            % if the user cancelled, then exit the function
            if ~obj.calcOK
                Img = [];
                return
            end
            
            % updates the progressbar
            if exist('indF','var')
                wStr = sprintf('Reading Estimate Frame (%i of %i)',...
                    indF,obj.nFrm0);
                if obj.updateSubProgField(wStr,indF/obj.nFrm0)
                    [Img,obj.calcOK] = deal([],false);
                    return
                end
            end
            
            % retrieves the image
            Img = double(getDispImage(obj.iData,obj.iMov,iFrm,0));
            
            % applies the image filter (if applicable)
            if ~isempty(obj.hS)
                Img = imfiltersym(Img,obj.hS);
            end
            
        end
        
        % ---  reads the image frames for all phases
        function [Img,sImg] = readPhaseFrames(obj)
            
            % initialisations and memory allocation
            nPhase = length(obj.vPhase);
            [Img,sImg] = deal(cell(nPhase,1));
            
            % sets the frame indices
            nImgR = obj.phsP.nImgR*(1+obj.isHT1);
            [obj.iMov.vPhase,obj.iMov.iPhase] = deal(obj.vPhase,obj.iPhase);
            iFrmR = getPhaseFrameIndices(obj.iMov,nImgR,obj.iPhase);
            
            % reads the frames for each
            for i = 1:nPhase
                % reads the video frames
                Img{i} = obj.readPhaseImgStack(iFrmR{i});
                
                % reads the sub-image stack
                sImg{i} = setSubImageStruct(obj.iMov,Img{i});
                sImg{i}.iFrm = iFrmR{i};
            end
            
            % converts the cell array to a struct array
            sImg = cell2mat(sImg);
        end
        
        % --- reads the image stack for the frames, iFrm
        function Img = readPhaseImgStack(obj,iFrm,isFull)
            
            % sets the default input arguments
            if ~exist('iFrm','var'); iFrm = obj.iFrm0; end
            if ~exist('isFull','var'); isFull = true; end
            
            % memory allocation
            Img = cell(length(iFrm),1);
            
            % retrieves the frames for each frame in the stack
            for j = 1:length(iFrm)
                Img{j} = double(...
                    getDispImage(obj.iData,obj.iMov,iFrm(j),0));
                if ~isFull
                    % case is sub-images are to be used
                    useRegions = true;
                    if isfield(obj.iMov,'srData')
                        if ~isempty(obj.iMov.srData)
                            % flag the images don't need to be broken down
                            % by region (split regions are to be used)
                            if j == 1
                                useRegions = false;
                                iGrp = cell2cell(obj.iMov.srData.iGrp(:));
                                Img{j} = cellfun...
                                    (@(x)(Img{j}(x)),iGrp,'un',0);
                            end
                        end
                    end
                    
                    %
                    if useRegions
                        if isempty(obj.iMov.iR)
                            % if the regions are not set, then use an
                            % estimate from the region outlines
                            szL = size(Img{j});
                            iR = cellfun(@(p)(max(1,floor(p(2))):...
                                min(szL(1),ceil(sum(p([2,4]))))),...
                                obj.pPosO,'un',0)';
                            iC = cellfun(@(p)(max(1,floor(p(1))):...
                                min(szL(2),ceil(sum(p([1,3]))))),...
                                obj.pPosO,'un',0)';
                        else
                            % otherwise, use the row/column indices
                            [iR,iC] = deal(obj.iMov.iR,obj.iMov.iC);
                        end
                        
                        % retrieves the region images
                        Img{j} = cellfun(@(ir,ic)...
                            (Img{j}(ir,ic)),iR,iC,'un',0)';
                    end
                end
            end
            
            % converts the cell of cell arrays to a cell array
            if ~isFull
                Img = cell2cell(Img,0);
            end
        end
        
        % ------------------------------------------ %
        % --- OTHER IMAGE MANIPULATION FUNCTIONS --- %
        % ------------------------------------------ %
        
        % --- estimates the image offset (relative to the reference image)
        function [pOfs,IT] = estImgOffset(obj,I,Iref)
            
            % optimisation parameters
            if obj.isBig
                % case is a big frame is being analysed
                pOfs = -flip(fastreg(I,Iref));
                IT = imtranslate(I,-pOfs);
            else
                % case is a smaller frame is being analysed
                IT = imregister(I,Iref,'translation',obj.rOpt,obj.rMet);
                pOfs = -flip(fastreg(IT,I));
            end
            
            % calculates the average difference between the reference image
            % and the original/translated images
            dImg = cellfun(@(x)(mean(abs(x(:)-Iref(:)),'omitnan')),{I,IT});
            if argMin(dImg) == 1
                % if the original image has a lower difference, then flag
                % that the image is static
                pOfs = [0,0];
            end
            
            % removes the regions where translation has occured
            if nargout == 2
                IT = obj.removeTransRowCols(IT,-pOfs);
            end
            
        end
        
        % --- applies the image translation
        function IT = applyImgTrans(obj,I,pOfs)
            
            IT = imtranslate(I,-pOfs);
            IT = obj.removeTransRowCols(IT,-pOfs);
            
        end
        
        % --- calculates the mean distance for a given frame, iFrm
        function Dmn = calcDist(obj,iFrm,varargin)
            
            DimgFrm = obj.getDimg(iFrm);
            
            if obj.hasSR && (nargin == 2)
                Dmn = DimgFrm;
            else
                xi = ones(1,size(DimgFrm,2));
                pW = repmat(xi/sum(xi),size(DimgFrm,1),1);
                Dmn = sum(pW.*DimgFrm,2);
            end
            
        end
        
        % --- calculates the region image avg. pixel intensities
        function calcRegionAvgInt(obj,iFrm)
            
            % retrieves the image intensities for the current frame
            DimgFrm = obj.getDimg(iFrm);
            
            % calculates the average image intensities (if missing)
            if all(DimgFrm == 0)
                % retrieves the image stack
                [~,Imet] = obj.getRegionImageStack(iFrm);
                
                % recalculates the image intensities based on type
                if iscell(obj.Dimg)
                    % case is the data is stored in cell array
                    for i = 1:obj.nApp
                        Dnew = obj.calcAvgImgIntensity(Imet,i);
                        if size(obj.Dimg{i},2) == length(Dnew)
                            obj.Dimg{i}(iFrm,:) = Dnew;
                        else
                            obj.Dimg{i}(iFrm,i) = Dnew;
                        end
                    end
                else
                    % case is the data is stored in a sparse array
                    obj.Dimg(iFrm,:) = obj.calcAvgImgIntensity(Imet);
                end
            end
            
        end
        
        % --- calculates the average image intensity (based on type)
        function D = calcAvgImgIntensity(obj,I,iApp)
            
            % calculates the average image intensity (based on type)
            if obj.hasSR
                % case is there is sub-region data set
                D = cell2mat(cellfun(@(y)(cellfun(@(x)(prctile(x(y),...
                    obj.pTile)),I)),obj.iGrpSR{iApp}(:),'un',0))';
            else
                % case is there is no sub-region setup (single region)
                D = cellfun(@(x)(prctile(x(x>0),obj.pTile)),I)';
            end
            
        end
        
        % --- retrieves the image pixel intensities (for the frames, iFrmD)
        function Dimg = getDimg(obj,iFrmD)
            
            % retrieves the values depending on how they are stored
            if iscell(obj.Dimg)
                % values are stored in a cell of sparse arrays
                DimgC = cellfun(@(x)(full(x(iFrmD,:))),obj.Dimg,'un',0);
                Dimg = cell2mat(DimgC(:)');
            else
                % case is a normal sparse array
                Dimg = full(obj.Dimg(iFrmD,:));
            end
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- determines the limits of any
        function setupHT1StimIndices(obj)
            
            % field retrieval
            Tv = obj.iData.Tv(1:obj.iMov.sRate:end);
            Ch1 = obj.iData.stimP.Motor.Ch1;
            [Ts,Tf] = deal(Ch1.Ts,min(Ch1.Tf+obj.tOfs,Tv(end)));
            
            % determines the stim event start/finish frames indices
            iTs = max(1,arrayfun(@(x)(find(Tv<=x,1,'last')),Ts)-1);
            iTf = arrayfun(@(x)(find(Tv>=x,1,'first')),Tf);
            obj.indH1S = cell2mat...
                (arrayfun(@(x1,x2)((x1:x2)'),iTs,iTf,'un',0));
            
        end
        
        % --- wrapper function for the homomorphic image filter setup
        function hFilt = setupHMFilterW(obj,varargin)
            
            % retrieves the row/column indices (if not provided)
            switch length(varargin)
                case 1
                    % case is using the whole region
                    iApp = varargin{1};
                    [iR,iC] = deal(obj.iR0{iApp},obj.iC0{iApp});
                    
                case 2
                    % case is the specified row/column indices
                    [iR,iC] = deal(varargin{1},varargin{2});
            end
            
            % sets up the homomorphic image filter
            hFilt = setupHMFilter(iR,iC);
            
        end
        
        % --- updates the subprogress field
        function isCancel = updateProgField(obj,wStr,pW)
            
            isCancel = obj.hProg.Update(obj.iLvl,wStr,pW);
            
        end
        
        % --- updates the subprogress field
        function isCancel = updateSubProgField(obj,wStr,pW)
            
            isCancel = obj.hProg.Update(1+obj.iLvl,wStr,pW);
            
        end
        
        % --- updates the phase detection progress
        function isCancel = updatePhaseDetectionProgress(obj)
            
            % progress bar parameters
            pChk = mean(obj.isCheck);
            wStr = sprintf('Detecting Video Phases (%.2f%s Complete)',...
                100*pChk,'%');
            
            % updates the progress bar
            isCancel = obj.hProg.Update(1+obj.iLvl,wStr,pChk);
            
        end
        
    end
    
    % static class methods
    methods (Static)
        
        % --- estimates the initial phase frame groupings
        function iFrmG = estPhaseFrameGroups(D,iFrm,dTol)
            
            % initialisations
            pMlt = 1;
            nFrm = length(iFrm);
            
            % sets the default parameters
            if ~exist('dTol','var'); [dTol,pMlt] = deal(2,2); end
            
            % calculates the distance between average pixel intensities
            if all(D <= dTol)
                % case is all distances are within tolerances
                iFrmG = [1,nFrm];
                
            else
                % case is there are one or more video phases
                
                % calculates/sorts the distances between adjacent frames
                iG = 1;
                iFrmG0 = [1,NaN(1,nFrm-1)];
                
                %
                for i = 2:nFrm
                    % determines if the new
                    if D(i,iG) < pMlt*dTol
                        ii = iFrmG0 == iG;
                        if all(arr2vec(D(ii,ii)) < pMlt*dTol)
                            %
                            iFrmG0(i) = iG;
                        else
                            %
                            [iG,iFrmG0(i)] = deal(i);
                        end
                    else
                        %
                        [iG,iFrmG0(i)] = deal(i);
                    end
                end
                
                % determines the unique frame groupings
                [~,~,iC] = unique(iFrmG0);
                iFrmG = cell2mat(arrayfun(@(x)([find(iC==x,1,'first'),...
                    find(iC==x,1,'last')]),1:max(iC),'un',0)');
            end
            
        end
        
        % --- removes the row/columns affected by translation
        function IT = removeTransRowCols(IT,pOfs)
            
            if pOfs(1) < 0
                IT(:,(end+floor(pOfs(1))):end) = NaN;
            elseif pOfs(1) > 0
                IT(:,1:ceil(pOfs(1))) = NaN;
            end
            
            if pOfs(2) < 0
                IT((end+floor(pOfs(2))):end,:) = NaN;
            elseif pOfs(2) > 0
                IT(1:ceil(pOfs(2)),:) = NaN;
            end
        end
        
        % --- applies the homomorphic filter to the image, I
        function Ihm = applyHMFilter(I,hF)
            
            Ihm = applyHMFilter(I,hF);
            Ihm = 255*normImg(Ihm - min(Ihm(:)));
            
        end    
        
    end
    
end
