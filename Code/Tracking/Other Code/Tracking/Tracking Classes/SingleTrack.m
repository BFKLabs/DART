classdef SingleTrack < Track
    
    properties
        
        % common fields
        hS
        Dtol
        
        % other fixed parameter fields
        nFrmPr = 5;
        isAutoDetect = false;
        
    end
    
    % class methods
    methods
        
        % class constructor
        function obj = SingleTrack(iData)
            
            % creates the super-class object
            obj@Track(iData,false);
            
        end                          
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %                               
        
        % --- initialises the tracking objects
        function initTrackingObjects(obj,sType)
            
            % initialisations              
            obj.initClassFields();            
            
            % sets the tracking object type indices and boolean flags
            switch sType
                case 'Manual'
                    % case is manual correction
                    sInd = 3;
                    [obj.isBGCalc,obj.isManual] = deal(false,true);
                    
                case 'InitEstimate'
                    % case is the initial background estimation
                    sInd = ones(1+(obj.nPhase-1)*(~obj.isDD),1);
                    [obj.isBGCalc,obj.isManual] = deal(~obj.isDD,false);  
                    
                    % updates the sub-region data struct phase information
                    % if tracking using direct detection 
                    if obj.isDD
                        obj.iMov.vPhase = 2;
                        obj.iMov.iPhase = [1,obj.iData.nFrm];
                    end
                    
                case 'Detect'
                    % case is detecting for all frames
                    [obj.isBGCalc,obj.isManual] = deal(false);
                    
                    % sets the tracking type index based on the algorithm
                    if obj.isDD
                        % case is direct detection 
                        sInd = 2;
                    else
                        % case is background subtraction
                        sInd = obj.iMov.vPhase(:);
                    end
                                        
            end     
            
        	% other parameters                         
            obj.Dtol = 5;                
            
            % sets the image filter
            [bgP,obj.hS] = deal(obj.iMov.bgP.pSingle,[]);
            if isfield(bgP,'hSz')
                if bgP.useFilt
                    obj.hS = fspecial('disk',bgP.hSz);
                end
            end
            
            % updates the ok flags
            if isfield(obj.iMov,'pInfo')
                iGrp = arr2vec(obj.iMov.pInfo.iGrp')';
                obj.iMov.flyok(:,iGrp==0) = false;
            end
            
            % memory allocation            
            obj.fObj = cell(length(sInd),1);
            
            % sets up the tracking class objects based on
            % algorithm/segmentation types
            for i = 1:length(sInd)
                switch sInd(i)
                    case {1,2}
                        % case is low variance calculations
                        isHV = sInd(i) == 2;
                        obj.fObj{i} = PhaseTrack(obj.iMov,obj.hProg,isHV);
                        obj.fObj{i}.nI = floor(max(getCurrentImageDim())/800);                        
                                                
                    case 3
                        % case is manual correction updates
                        obj.fObj{i} = ManualDetect(obj.iMov,obj.hProg);
                        
                    otherwise
                        % FINISH ME!
                        waitfor(msgbox('Finish Me!'))
                end
            end
            
        end              
              
        % --- retrieves the important data from the previous phase
        function prData = getPrevPhaseData(obj,fObjPr,iFrm)

            % data struct memory allocation
            prData = struct('fPosPr',[],'fPos',[],'IPosPr',[],...
                            'iStatus',[],'nFrmPr',obj.nFrmPr);

            % sets the data from the previous phase   
            prData.fPos = fObjPr.fPos(:,end);  
            prData.iStatus = obj.iMov.Status;
            
            if isprop(obj,'pData')
                % sets the phase index (if not provided)
                if ~exist('iFrm','var')                
                    iStack = obj.pData.nCount(fObjPr.iPh);
                    iFrm = obj.sProg.iFrmR{iStack}(end);
                end            

                % sets the previous frame points (for the full search only)               
                indT = max(1,iFrm-(obj.nFrmPr-1)):iFrm;
                prData.fPosPr = cellfun(@(y)(cellfun(@(x)...
                        (x(indT,:)),y,'un',0)),obj.pData.fPosL,'un',0); 
                prData.IPosPr = cellfun(@(y)(cellfun(@(x)...
                        (x(iFrm)),y(:))),obj.pData.IPos,'un',0);
            end

        end         
        
        % ------------------------------------ %
        % --- REGION STACK SETUP FUNCTIONS --- %
        % ------------------------------------ %          
        
        % --- retrieves the region image stack
        function [IL,BL] = getRegionImageStack(obj,I0,iFrm,iApp,isHiV)
            
            % sets the default input arguments
            if ~exist('isHiV','var'); isHiV = false; end
            
            % retrieves the new image frame
            I0 = I0(:);
            IL = cell(size(I0));     
            phInfo = obj.iMov.phInfo;
            
            % sets the row/column indices
            if obj.isAutoDetect
                % case is using auto-detection
                [iR,iC] = deal(obj.iRG{iApp},obj.iCG{iApp}); 
            else
                % case is using general tracking
                [iR,iC] = deal(obj.iMov.iR{iApp},obj.iMov.iC{iApp});
            end
            
            % sets the sub-image stacks
            isOK = ~cellfun(@isempty,I0);          
            IL(isOK) = cellfun(@(I)(I(iR,iC)),I0,'un',0); 
            if any(~isOK)
                % if the image is empty, then return NaN arrays
                szT = [sum(~isOK),1];
                IL(~isOK) = repmat({NaN(length(iR),length(iC))},szT);
            end              
            
            % corrects image fluctuation (if applicable)
            if obj.getFlucFlag() || isHiV
                % if there is fluctuation, then apply the hm filter and the
                % histogram matching to the reference image
                h = phInfo.hmFilt{iApp};
                Imet = cellfun(@(x)(obj.applyHMFilter(x,h)),IL(:),'un',0); 
                IL = cellfun(@(x)(x-nanmedian(x(:))),Imet,'un',0); 
                
                if ~phInfo.hasT(iApp) && (nargout == 2)
                    BL = cellfun(@(x)(x<nanmean(x(:))),IL,'un',0);
                end
                
            elseif (nargout == 2)
                % case is there is no light fluctuation
                BL = cell(length(IL),1);
            end
            
            % corrects image fluctuation (if applicable)
            if obj.getTransFlag(iApp)
                % calculates the x/y coordinate translation
                phInfo = obj.iMov.phInfo;
                p = phInfo.pOfs{iApp};
                pOfsT = interp1(phInfo.iFrm0,p,iFrm,'linear','extrap');
                
                % applies the image translation
                IL = cellfun(@(x,p)(obj.applyImgTrans(x,p)),...
                                    IL,num2cell(pOfsT,2),'un',0);                                
                if phInfo.hasF && (nargout == 2)
                    BL = cellfun(@(x)(x<nanmean(x(:))),IL,'un',0);
                end                                
            end
            
        end                       
        
        % --- retrieves the fluctuation flag
        function hasF = getFlucFlag(obj)
              
            if obj.isCalib
                % case is tracking calibration
                hasF = false;
            else
                % case is video tracking
                hasF = obj.iMov.phInfo.hasF;
            end
            
        end 
        
        % --- retrieves the fluctuation flag
        function hasT = getTransFlag(obj,iApp)
              
            if obj.isCalib
                % case is tracking calibration
                hasT = false;
            else
                % case is video tracking
                hasT = obj.iMov.phInfo.hasT(iApp);
            end
            
        end           
        
    end    
    
    % static class methods
    methods (Static)          
        
        % --- applies the image translation 
        function IT = applyImgTrans(I,pOfs)
            
            % pads the array by the movement magnitude
            sz = size(I);
            dpOfs = ceil(abs(flip(pOfs)))+2;
            Iex = padarray(I,dpOfs,'both','symmetric');
            
            % translates and sets the final offset image
            IT0 = imtranslate(Iex,-pOfs);
            IT = IT0(dpOfs(1)+(1:sz(1)),dpOfs(2)+(1:sz(2)));
            
        end            
        
        % --- applies the homomorphic filter to the image, I
        function Ihm = applyHMFilter(I,hF)
                
            Ihm = applyHMFilter(I,hF);
            Ihm = 255*normImg(Ihm - min(Ihm(:)));

        end              
        
    end
    
end

% %-------------------------------------------------------------------------%
% %                    BACKGROUND CALCULATION FUNCTIONS                     %
% %-------------------------------------------------------------------------%
% 
% % ------------------------------------ %
% % --- MANUAL BACKGROUND ESTIMATION --- %
% % ------------------------------------ %
% 
% % --- recalculates the background estimate using the manual suggestions - %
% function [iMov,ok] = manualBackgroundEst(obj,iMov,sImg,h)
% 
% % global variables
% global fUpdate
% 
% % ------------------------------------------- %
% % --- INITIALISATIONS & MEMORY ALLOCATION --- %
% % ------------------------------------------- %
% 
% % initialisations
% [nDS,p,ok] = deal(getDownSampleRate(iMov),iMov.pStats,true);
% [fUpdate,nDil] = deal(false(size(iMov.flyok)),2*nDS);
% 
% % determines the indices of the lo-variance phases
% pLo = find(iMov.vPhase == 1);
% isSeg = zeros([size(iMov.flyok),length(pLo)]);
% fPosB0 = getappdata(handles.figBackEst,'fPos');
% 
% % ------------------------------------ %
% % --- MANUALLY DETECTION OVERWRITE --- %
% % ------------------------------------ %    
% 
% % here we take the original fly binary groups (for each of the candidate
% % frames) and update the them with the manually selected regions
% 
% % retrieves the manual selection info
% [iGrp,uListC] = retManualSelectInfo();
% 
% % if manually detecting, then reset the 
% for i = 1:length(iGrp)
%     % sets the apparatus/fly indices for the current grouping
%     iFrm = cell2mat(uListC(iGrp{i},1));
%     iApp = uListC{iGrp{i}(1),2};               
%     iFly = uListC{iGrp{i}(1),3};
%     iPhase = uListC{iGrp{i}(1),4};    
%     fPosNw = cell2mat(uListC(iGrp{i},6));    
%     
%     % flags that this region needs updating. if this region has been
%     % classified as empty/rejected, then flag that this phase was set
%     fUpdate(iFly,iApp) = true;        
%     if (~iMov.flyok(iFly,iApp)) || (all(isnan(fPosB0{1,iApp,iPhase}(iFly,:))))
%         isSeg(iFly,iApp,pLo==iPhase) = 1;
%     end
%     
%     % retrieves the resegmentation image stack
%     [IL,Ysvm,szL,iR] = getResegStack(iMov,sImg,iApp,iFly,iPhase,iFrm);       
%     
%     % sets the binary regions of the "accepted" svm regions
%     BB0 = cellfun(@(x)(bwmorph(x < 0,'dilate',nDil)),Ysvm,'un',0);     
%     
%     % determines the accepted binaries that overlap with the selections
%     BB = cellfun(@(x,y)(bwmorph(genFlySpotBinary(size(y),roundP(x)),...
%                     'dilate',nDil)),uListC(iGrp{i},6),BB0,'un',0);
%     for j = 1:length(iFrm)        
%         [~,BB0{j}] = detGroupOverlap(BB0{j},BB{j});
%         if (~any(BB0{j}(:))); BB0{j} = BB{j}; end
%     end
%         
%     % calculates the sum/count arrays for the BG calculation
%     [Isum,Icount] = deal(zeros(szL));
%     for j = 1:length(iFrm)
%         % upscales the image
%         BB0nw = usimage(BB0{j},szL);
%         
%         % sets the background image/count
%         Isum(~BB0nw) = Isum(~BB0nw) + IL{iFrm(j)}(~BB0nw);
%         Icount = Icount + ~BB0nw;
%     end
%     
%     % calculates the background image for the current arena     
%     [iMov,IBGL,fPos,isMove] = calcResegBG(iMov,IL,fPosNw,Isum,Icount); 
%     
%     % recalculates the regional stats
%     indNw = [iApp,iFly,iPhase];
%     p = resetRegionStats(p,iMov,sImg,fPos,IL,IBGL,indNw,isMove);
%     
%     % sets the background image and resets the acceptance flags
%     iMov.Ibg{iPhase}{iApp}(iR,:) = IBGL;     
%     [iMov.flyok(iFly,iApp),iMov.ok(iApp)] = deal(true);
%     iMov.Status{iApp}(iFly) = 1 + (isnan(p{iApp}(iFly).pMu));
% end
% 
% % determines all regions where the flies need to be resegmented for the
% % other low-variance phases
% [jFly,jApp] = find(mod(sum(isSeg,3),length(pLo))~=0);
% for i = 1:length(jFly)
%     % sets the apparatus/fly indices
%     [iApp,iFly] = deal(jApp(i),jFly(i));
%             
%     % determines all the regions that were segmented correctly
%     ii = (mod(sum(isSeg(:,iApp,:),3),length(pLo)) == 0);    
%     ii = ii(1:length(p{iApp,1}));
%     
%     % determines the phases which need to also be resegmented
%     jPhase = pLo(reshape(isSeg(iFly,iApp,:)==0,size(pLo)));
%     for j = 1:length(jPhase)
%         % sets the phase index
%         [iPhase,useSVM] = deal(jPhase(j),false);
%         
%         % retrieves the image segmentation stack
%         [IL,Ysvm,szL,iR] = getResegStack(iMov,sImg,iApp,iFly,iPhase);
%         sz = [1 1 length(IL)];
%         
%         % if there are any feasible         
%         if (any(ii))
%             % calculates the mean pixel tolerance            
%             pTol = nanmean(field2cell(p{iApp,iPhase}(ii),'pMu',1));
%             
%             % determines if the max residual is greater than this
%             % tolerance. if so, then use the residual to calculate the
%             % background image
%             IR = cellfun(@(x)(max(cell2mat(reshape(cellfun(@(xx)(xx-x),...
%                     IL,'un',0),sz)),[],3)),IL,'un',0);
%                 
%             % determines if any of the points are above tolerance
%             jj = find(cellfun(@(x)(any(x(:)>pTol)),IR));
%             if (~isempty(jj))
%                 % if so, then calculate the background estimate
%                 fPos = roundP(cell2mat(cellfun(@(x)(...
%                     calcMaxValueLocation(x)),IR(jj),'un',0)));               
%             else
%                 % flag to using the SVM classifier images
%                 useSVM = true;
%             end
%         else
%             % flag to using the SVM classifier images
%             useSVM = true;
%         end
%         
%         % if no solution was found from the residuals, then use the 
%         if (useSVM)
%             jj = 1:sz(3);
%             fPos = roundP(cell2mat(cellfun(@(x)(...
%                 calcMaxValueLocation(x,'min')),Ysvm,'un',0)));
%         end
%         
%         % calculates the background image estimate
%         [iMov,IBGL,fPos,isMove] = calcResegBG(iMov,IL(jj),fPos,nDil,szL);        
%         iMov.Status{iApp}(iFly) = double(isMove) + 1;
%         
%         % recalculates the regional stats
%         indNw = [iApp,iFly,iPhase];
%         p = resetRegionStats(p,iMov,sImg,fPos,IL(jj),IBGL,indNw,isMove);        
%         
%         % sets the background image 
%         isSeg(iFly,iApp,pLo==iPhase) = 1;
%         iMov.Ibg{iPhase}{iApp}(iR,:) = IBGL;             
%     end
% end
% 
% % resets the struct into the sub-region data struct
% iMov.pStats = p;
% 
% % --- resets the regional stats for a given tube region
% function p = resetRegionStats(p,iMov,sImg,fPos,IL,IBGL,indNw,isMove)
% 
% % sets the apparatus, fly and phase indices
% [iApp,iFly,iPhase] = deal(indNw(1),indNw(2),indNw(3));
% 
% % sets the stats based on whether the object moved or not
% if (isMove)
%     % fly has moved appreciably
%     sz0 = size(IL{1});
%     Bw = logical(usimage(getExclusionBin(iMov,size(IBGL),iApp,iFly),sz0));
%         
%     % calculates the region statistics
%     p{iApp,iPhase}(iFly) = ...
%             calcRegionStats(p{iApp}(iFly),IL,IBGL,Bw,fPos,1);
%     p{iApp,iPhase}(iFly).fxPos = NaN(1,2);        
% else
%     % fly has not moved appreciably
%     iFrm = reshape(sImg(iPhase).iFrm,length(sImg(iPhase).iFrm),1);
%     p{iApp,iPhase}(iFly).fxPos = [iFrm,fPos];
%     p{iApp,iPhase}(iFly).pMu = NaN;
%     p{iApp,iPhase}(iFly).pTol = NaN;
% end
% 
% % --- retrieves the resegmentation image stack
% function [IL,Ysvm,szL,iR] = getResegStack(iMov,sImg,iApp,iFly,iPhase,iFrm)
% 
% % if not provided, set the default frame index to be all frames
% if (nargin < 6)
%     iFrm = 1:length(sImg(iPhase).I(:,iApp));
% end
% 
% %
% isCG = isColGroup(iMov);
% if (isCG)
%     [iR,iC] = deal(iMov.iR{iApp},iMov.iCT{iApp}{iFly});    
% else
%     [iR,iC] = deal(iMov.iRT{iApp}{iFly},iMov.iC{iApp});    
% end
% 
% % retrieves the local coordinates for the selected frames    
% szL = [length(iR) length(iC)];            
% Bw = getExclusionBin(iMov,szL,iApp,iFly);      
% 
% % retrieves the binary spots and local images for the current
% % resegmentation frame group
% if (isCG)
%     IL = cellfun(@(x)(x(:,iC)),sImg(iPhase).I(:,iApp),'un',0);         
% else
%     IL = cellfun(@(x)(x(iR,:)),sImg(iPhase).I(:,iApp),'un',0);          
% end
%          
% % sets the final classifier images
% Ysvm = cellfun(@(x)(setupClassifierStack(iMov,x,iApp,1)),IL(iFrm),'un',0);    
% if (nargin < 6)
%     % sets the rejected regions to be the maximum pixel value
%     for i = 1:length(Ysvm)
%         Ysvm{i}(~Bw) = max(Ysvm{i}(Bw));
%     end
% else
%     % removes the rejected regions from the images    
%     Ysvm = cellfun(@(x)(x.*Bw),Ysvm,'un',0);
% end
% 
% % updates the image stack
% Ysvm = upscaleImageStack(iMov,Ysvm,iApp,iFly);
