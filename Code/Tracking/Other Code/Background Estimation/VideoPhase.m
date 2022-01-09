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
        
        % image/region arrays
        sz0
        iR0
        iC0
        Img0
        ILF
        Dimg
        
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
        pTolLo = 35;
        pTolHi = 210;        
        
        % homomorphic filter parameters
        aHM = 0;
        bHM = 1;
        sigHM = 15;
        hmFilt
        
        % other fixed parameters
        Dtol = 2;
        nPhaseMx = 6;
        nImgR = 10;
        nFrm0 = 10;
        nPhMax = 5;
        szDS = 1000;
        szBig = 1400; 
        dnFrmMin = 50;              
        
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
            
            % other class fields
            obj.nApp = length(obj.iMov.posO);
            [obj.rOpt,obj.rMet] = imregconfig('monomodal');  
            obj.rOpt.MaximumIterations = 250;
            
            % sets the variable fields
            obj.sz0 = getCurrentImageDim;
            obj.isBig = any(obj.sz0 > obj.szBig);
            obj.nDS = max(floor(obj.sz0/obj.szDS)) + 1;
            
            % sets up the image filter
            bgP = obj.iMov.bgP.pSingle;
            if bgP.useFilt
                obj.hS = fspecial('disk',bgP.hSz);
            end
            
            % memory allocation
            [obj.hasT,obj.hasF] = deal(false);
            [obj.iR0,obj.iC0] = deal(cell(obj.nApp,1)); 
            [obj.IrefF,obj.pOfs] = deal(cell(obj.nApp,1));
            obj.ILF = cell(obj.nFrm0,obj.nApp);
            
            % retrieves/sets the region outline coordinates
            if obj.autoDetect
                posO = getCurrentRegionOutlines(obj.iMov);
            else
                posO = obj.iMov.posO;
            end
            
            % sets the region row/column indices            
            for iApp = 1:obj.nApp
                pP = posO{iApp};
                obj.iR0{iApp} = ceil(pP(2))+(0:floor(pP(4)));
                obj.iC0{iApp} = ceil(pP(1))+(0:floor(pP(3)));                  
            end
            
        end           
        
        % --------------------------------- %
        % --- PHASE DETECTION FUNCTIONS --- %
        % --------------------------------- %
        
        % --- runs the phase detection algorithm
        function runPhaseDetect(obj,varargin)
            
            % creates the progress bar (if not provided)
            if nargin == 2
                wStr = {'Overall Progress',...
                        'Reading Initial Frame Stack'};
                obj.hProg = ProgBar(wStr,'Phase Detection');
                obj.closePB = true;
            end
            
            % reads the initial image stack
            obj.getInitialImgStack();
            
            % determines the video properties
            obj.detVideoProps();
            
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
                obj.calcRegionInfo(iApp)
            end            
            
            % optimises the frame group limits
            iGrpF = obj.optFrameGroupLimits();
            
            % checks the final frame groupings
            obj.checkFinalFrameGroups(iGrpF);
            
            % closes the progressbar (if required)
            if obj.closePB
                obj.hProg.closeProgBar();
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
            
            % calculates the offset between the last/first frame
            obj.hasT = false(1,obj.nApp);
            
            % updates the progressbar
            obj.updateSubProgField('Determining Video Translation',0.25);            
            ImgHM = cellfun(@(x)(applyHMFilter(x)),obj.Img0([1,end]),'un',0);
            pOfs0 = obj.estImgOffset(ImgHM{2},ImgHM{1});            
            
            % if there is significant translation, then determine which 
            % regions have significant shift            
            if any(abs(roundP(pOfs0)) > 0)
                obj.hasT(:) = true;
            end
%                 
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
            obj.Dimg0 = cellfun(@(x)(nanmean(x(:))),ImgI);
            Dmu = pdist2(obj.Dimg0(:),obj.Dimg0(:));
            iFrmG0 = obj.estPhaseFrameGroups(Dmu,obj.iFrm0);

            % determines if there are a large number of phases 
            % (unstable image fluctuation)
            obj.hasF = size(iFrmG0,1) >= obj.nPhMax;  
            if obj.hasF
                % if so, then set up the hm filter images
                obj.hmFilt = arrayfun(@(x)...
                            (obj.setupHMFilterW(x)),1:obj.nApp,'un',0)';
            end
            
            % updates the progressbar           
            wStrF = 'Video Property Detection Complete';
            obj.calcOK = ~obj.updateSubProgField(wStrF,1);
            
        end            
        
        % --- calculates the information (for a specific region)
        function calcRegionInfo(obj,iApp)
            
            % retrieves the raw region image stack
            [iR,iC] = deal(obj.iR0{iApp},obj.iC0{iApp});
            IL = cellfun(@(x)(x(iR,iC)),obj.Img0,'un',0);  
            
            % if there is severe light fluctuation or translation, then
            % calculate the hm-filtered images
            if obj.hasF
                ILhmf = cellfun(@(x)(obj.applyHMFilter...
                        (x,obj.hmFilt{iApp})),IL,'un',0);  
                obj.IrefF{iApp} = uint8(calcImageStackFcn(ILhmf,'max'));
                IL = cellfun(@(x)(double((imhistmatch...
                        (uint8(x),obj.IrefF{iApp},256)))),ILhmf,'un',0);
            end         
              
            % if there is significant image translations then estimate the 
            % image offset over the duration of the video
            if obj.hasT(iApp)
                % memory allocation
                ILT = cell(obj.nFrm0,1);
                pOfs0 = NaN(obj.nFrm0,2);
                
                % calculates the hm-filtered images
                if obj.hasF
                    ILhmf = IL;
                else
                    obj.hmFilt{iApp} = obj.setupHMFilterW(iApp);
                    ILhmf = cellfun(@(x)(obj.applyHMFilter...
                                    (x,obj.hmFilt{iApp})),IL,'un',0); 
                end                
                
                % calculates the image offset over the video
                for k = 1:obj.nFrm0
                    pOfs0(k,:) = obj.estImgOffset(ILhmf{k},ILhmf{1});
                    ILT{k} = obj.applyImgTrans(IL{k},pOfs0(k,:));
                end        

                % sets the position offset coordinates
                obj.pOfs{iApp} = pOfs0 - pOfs0(1,:);
            else
                % if there is no translation, then update the image array
                ILT = IL;
            end              
            
            % ------------------------------------------- %
            % --- FINAL IMAGE DIFFERENCE CALCULATIONS --- %
            % ------------------------------------------- %        

            % calculates image metric values
            if obj.hasF
                % case is the video has intensity fluctuations
                obj.Dimg(obj.iFrm0,iApp) = obj.calcAvgImgIntensity(ILhmf);
            else  
                % case is the video doesn't have intensity fluctuations
                obj.Dimg(obj.iFrm0,iApp) = obj.calcAvgImgIntensity(IL);
            end
            
            % sets the region specific variables
            obj.ILF(:,iApp) = ILT;              
            
        end
        
        % --- optimises the frame grouping limits
        function jGrpF = optFrameGroupLimits(obj)
           
            % if the user already cancelled, then exit the function
            if ~obj.calcOK
                jGrpF = [];
                return
            end            
            
            % parameters and initialisations
            obj.Dtol = 2+obj.hasF;     
            isF = false(obj.nFrm0,1);
            iGrpF = cell(obj.nFrm0,1);                        
            
            % updates the progressbar
            obj.updateProgField('Frame Grouping Limit Optimisation',4/6); 
            obj.updateSubProgField('Frame Limit Detection',0);             
            
            % determines if the video has high fluctuation
            if obj.hasF
                % if so, then video only has one phase 
                jGrpF = [obj.iFrm0(1),obj.iFrm0(end)];
                
                % updates the progressbar
                obj.updateSubProgField('Frame Group Limit Detection',1);
                return
            end
            
            % ----------------------------------------- %
            % --- INITIAL FRAME GROUPING ESTIMATION --- %
            % ----------------------------------------- %
            
            % determines which frames are reasonably tolerances
            DimgF = full(obj.Dimg(obj.iFrm0,:));
            D0 = cellfun(@(x)(pdist2(x(:),x(:))),num2cell(DimgF,1),'un',0);            
            D = calcImageStackFcn(D0,'max');            
            BD = D <= obj.Dtol;
            
            % determines the frame groupings (which have similarity scores
            % that are within tolerances)
            for j = 1:size(BD,2)
                % determines the feasible adjacent frames
                ii = j:obj.nFrm0;
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
            iCol = find(~cellfun(@isempty,iGrpF));
            iGrpF = iGrpF(iCol);
            
            % sets up the feasible frame index array
            Dtot = NaN(obj.nFrm0,length(iCol));             
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
            
            % determines the coarse frame groupings
            Dtot = Dtot(:,any(~isnan(Dtot),1));
            iFrmG = cell2mat(cellfun(@(x)([find(~isnan(x),1,'first'),...
                   find(~isnan(x),1,'last')]),num2cell(Dtot,1)','un',0));            
            
            % other initialisations
            nGrp = size(iFrmG,1);
            iGrpC = cell(nGrp-1,1);
            nFrmGrpMax = 25;
            
            % sets the frames that are checked
            indChk0 = [obj.iFrm0(1):obj.iFrm0(iFrmG(1,2)),...
                       obj.iFrm0(iFrmG(end,1)):obj.iFrm0(end)];
            obj.isCheck(indChk0) = true;
            if obj.updatePhaseDetectionProgress()
                % if the user cancelled, then exit the function
                obj.calcOK = false;
                return
            end            
            
            for i = 1:(nGrp-1)
                % determines the phase limits within the coarse limits
                ii = [iFrmG(i,2),iFrmG(i+1,1)];                
                frm0 = obj.iFrm0(ii);       

                % calculates the coarse phase limits
                if diff(frm0) == 0
                    iGrpC{i} = {frm0};
                else
                    iGrpC{i} = obj.detCoarsePhaseLimits(frm0);
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
                indG = obj.iFrm0([1,end]);
            else
                indG = [[obj.iFrm0(1);X(:,2)],[X(:,1);obj.iFrm0(end)]];
            end
            
            % for each for the frame groupings, determine the valid frames
            % indices 
            indG0 = indG;
            iFrmF = find(obj.Dimg(:,1));                        
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
                D0 = obj.calcDist(iNw(1));
                Dact = obj.calcDist(iNw(2));
                [dT,Vest] = deal(diff(iNw),pGrp(i-1));

                % determines if the the frame groups can be combined  
                if isnan(Vest) || any(nFrmGrp(i+[-1,0]) > nFrmGrpMax)
                    inTol = false;
                elseif abs(Vest) < pTolMin
                    % if the gradient of the previous frame group is
                    % low, then compare the estimated/actual distances
                    Dpr = obj.calcDist(iFrmGrp{i-1});
                    Dnw = obj.calcDist(iFrmGrp{i});
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
            jGrpF = cell2mat(indF);                     
 
            % updates the progressbar
            obj.updateSubProgField('Frame Group Limit Detection',1);             
                      
        end              
        
        % --- calculates the frame group gradients
        function [pGrp,DGrpMn] = calcFrmGroupGradient(obj,iFrmGrp)
            
            % calculates the 
            DGrp = cellfun(@(x)(full(obj.Dimg(x,:))),iFrmGrp,'un',0);
            DGrpMn = cellfun(@(x)(nanmean(x,2)),DGrp,'un',0);
            
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
            nFrmG = diff(iGrpF,[],2) + 1;
            
            % determines if the phases can be combined/reduced
            for i = 1:nGrpF
                % retrieves the non-sparse frames for the current group
                iGrpNw = iGrpF(i,1):iGrpF(i,2);
                iFrmG = find(obj.Dimg(iGrpNw,1)) + (iGrpF(i,1)-1);
                
                % determines if the frame range is too low for tracking                
                DimgF{i} = full(obj.Dimg(iFrmG,:));                
                if all(DimgF{i}(:) < pTolRng)
                    % pixel range is too low, so set as untrackable
                    vPhaseF(i) = 3;
                else
                    % otherwise, determine if the mean pixel intensity is 
                    % either too high or too low for tracking
                    if any(DimgF{i}(:)<obj.pTolLo) || ...
                                    any(DimgF{i}(:)>obj.pTolHi)
                        % the mean pixel intensity is either too high/low.
                        % therefore, flag that the phase is untrackable
                        vPhaseF(i) = 3;
                    else
                        % otherwise, determine if the frame range is either
                        % a low or medium variance phase
                        if obj.hasF
                            vPhaseF(i) = 1;
                        else
                            isShort = diff(iGrpF(i,:)) <= obj.dnFrmMin;
                            isHiDiff = any(range(DimgF{i},1) > 2*obj.Dtol);
                            vPhaseF(i) = 1 + (isShort || isHiDiff);
                        end
                    end
                end
            end                     

            % calculates the mean frame grouping avg pixel intensities
            DimgFmu = cellfun(@(x)(mean(x,2)),DimgF,'un',0);            
            Drng = cell2mat(cellfun(@(x)([min(x),max(x)]),DimgFmu,'un',0));
            
            % ------------------------------------ %
            % --- PHASE REDUCTION CALCULATIONS --- %
            % ------------------------------------ %
            
            % parameters
            nFrmMin = 2;
            
            % updates the progressbar
            obj.updateSubProgField('Phase Reduction Calculations...',0.25);            
            
            % determines which adjacent phases are either
            % medium/untrackable phases AND have a small number of frames
            isOK = true(size(vPhaseF));
            for i = 2:length(vPhaseF)                
                ii = i + [-1,0];
                isOverlap = false;
                if all(vPhaseF(ii) == 2) 
                    if any(nFrmG(ii) <= nFrmMin)
                        % case is one of the phases is very small
                        isOverlap = true;
                    else
                        % otherwise determines if there is any overlap in
                        % the pixel range of each phase
                        s12 = arrayfun(@(x)(prod...
                                (sign(Drng(ii(1),:)-x))),DimgFmu{ii(2)});
                        s21 = arrayfun(@(x)(prod...
                                (sign(Drng(ii(2),:)-x))),DimgFmu{ii(1)});                    
                            
                        % determines if the pixel intensities overlap 
                    	% between the adjacent phases
                        isOverlap = any(s12 == -1) || any(s21 == -1);
                    end
                elseif all(vPhaseF(ii) == 3)
                    % combine all adjacent untrackable phases
                    isOverlap = true;
                end
                    
                if isOverlap         
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
            % having high pixel fluctuation
            if length(vPhaseF) > obj.nPhaseMx
                obj.hasF = true;                
                [iPhaseF,vPhaseF] = deal([1,obj.iFrm0(end)],1); 
                
                % sets up the hm filter masks
                [iR,iC] = deal(obj.iMov.iR,obj.iMov.iC);
                obj.hmFilt = cellfun(@(ir,ic)(...
                                obj.setupHMFilterW(ir,ic)),iR,iC,'un',0);
            end   

            % set the final class field values
            [obj.iPhase,obj.vPhase] = deal(iPhaseF,vPhaseF);
            
            % updates the progress bar
            obj.updateSubProgField('Final Grouping Check Complete',1);
            
        end                     
        
        % --------------------------------------- %
        % --- PHASE LIMIT DETECTION FUNCTIONS --- %
        % --------------------------------------- %             
        
        % --- determines the coarse phase limits
        function iFrmG = detCoarsePhaseLimits(obj,iFrm0)
            
            % calculates the number of sub-frame checks 
            N0 = min(5,diff(iFrm0)+1);

            % calculates the metrics for the new frames
            iFrmG0 = roundP(linspace(iFrm0(1),iFrm0(2),N0));            
            arrayfun(@(x)(obj.calcRegionAvgInt(x)),iFrmG0);

            % calculates the difference in the distance values
            Davg = obj.calcDist(iFrmG0);
            dDavg = abs(diff(Davg));
            iDiff = find(dDavg > obj.Dtol);
            
            % determines if there is a major difference in pixel intensity
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
                Dnw = obj.calcDist(iFrmNw0);
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
        function [IL,Imet] = getRegionImgStack(obj,iFrm)
            
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
                    
            % adds in any missing image frames
            for i = find(cellfun(@isempty,Img(:)'))                                
                iDir = (i == 1) - 2;
                while isempty(Img{i})
                    obj.iFrm0(i) = obj.iFrm0(i) + iDir;
                    Img{i} = obj.getImageFrame(obj.iFrm0(i));
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
            [obj.iMov.vPhase,obj.iMov.iPhase] = deal(obj.vPhase,obj.iPhase);
            iFrmR = getPhaseFrameIndices(obj.iMov,obj.nImgR,obj.iPhase);                
            
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
        function Dmn = calcDist(obj,iFrm)
            
            Dmn = mean(full(obj.Dimg(iFrm,:)),2);
            
        end        
        
        % --- calculates the region image avg. pixel intensities
        function calcRegionAvgInt(obj,iFrm)
        
            if all(full(obj.Dimg(iFrm,:)) == 0)
                [~,Imet] = obj.getRegionImgStack(iFrm);
                obj.Dimg(iFrm,:) = obj.calcAvgImgIntensity(Imet);
            end
            
        end          
        
        % --- calculates the average image intensity (based on type)
        function D = calcAvgImgIntensity(obj,I)
            
            % down-samples the images (based on image size)            
            Ii = cellfun(@(x)(dsimage(x,obj.nDS)),I,'un',0);            
            
            if obj.hasF
                D = cellfun(@(x)(nanmean(x(:))),Ii);
            else
                D = cellfun(@(x)(nanmean(x(:))),Ii);   
            end
            
        end                
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %    
        
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
