classdef HVPhaseTrack < matlab.mixin.SetGet
    
    % class properties
    properties
        % main class fields
        iMov
        hProg
        Img
        pInt
        iFrmR
        iPara
        iPhase
        prData = [];
        
        % boolean/scalar flags
        is2D
        iFrm
        wOfs = 1;
        hasProg = false;
        calcOK = true;
        
        % dimensioning veriables
        nApp
        nTube
        nImg
        hProgN
        
        % important fields
        hS
        y0
        szObj
        vPh
        iPh
        fPos0
        
        % permanent calculated values
        IBG
        pBG
        pMax
        pMaxG
        IPos
        fPos
        fPosL
        fPosG
        Phi
        axR
        NszB
        iStatus
        Qmet
        
        % temporary object fields
        ImgMd
        ImdBG
        iImgBG
        ImdRL
        ImdR
        ImdL
        IL
        iGrpP
        zGrpP
        BrmvBG
        indC
        
        % optimal gaussian parameter fields
        pOpt
        Iopt
        Bopt
        
        % other parameters
        rTol0 = 0.5;
        gpTol = 90;
        pTolR = 0.35;
        mxTol = 0.5;
        dTol = 5;
        wSz = 8;
        pTol = 0.4;
        abTol = 0.75;
        xcTol = 0.525;
        
    end
    
    % class methods
    methods
        % class constructor
        function obj = HVPhaseTrack(iMov,hProg)
            
            % sets the class fields
            obj.iMov = iMov;
            
            % sets the other class fields (if provided)
            if exist('hProg','var')
                obj.hProg = hProg;
                obj.hasProg = true;
            end
            
            % object dimensions
            obj.nApp = length(iMov.iR);
            obj.nTube = getSRCountVec(iMov);
            obj.nImg = length(obj.Img);
            obj.is2D = obj.iMov.is2D;
            
            % sets the tube-region offsets
            obj.y0 = cell(obj.nApp,1);
            for iApp = find(obj.iMov.ok(:)')
                obj.y0{iApp} = cellfun(@(x)(x(1)-1),obj.iMov.iRT{iApp});
            end
            
            % initialises the parameter struct
            obj.initParaStruct();
            
            % sets the object size
            if isfield(obj.iMov,'szObj')
                obj.szObj = obj.iMov.szObj;
            end
            
        end
        
        % ---------------------------- %
        % --- MAIN SOLVER FUNCTION --- %
        % ---------------------------- %
        
        % --- runs the main detection algorithm
        function runDetectionAlgo(obj)
            
            % field updates and other initialisations
            obj.nImg = length(obj.Img);
            
            % initialises the solver fields
            obj.initObjectFields();            
            obj.calcFullObjPos();
            
            % calculates the global coordinates & performs housekeeping
            obj.calcGlobalCoords();
            obj.performHouseKeepingOperations();
            
        end
        
        % --- initialises the solver fields
        function initObjectFields(obj)
            
            % flag initialisations
            obj.calcOK = true;
            
            % permanent field memory allocation
            obj.IPos = cell(obj.nApp,obj.nImg);
            obj.fPos = cell(obj.nApp,obj.nImg);
            obj.iStatus = ~obj.iMov.flyok*3;
            
            % orientation angle memory allocation
            if obj.iMov.calcPhi
                obj.Phi = cell(obj.nApp,obj.nImg);
                obj.axR = cell(obj.nApp,obj.nImg);
                obj.NszB = cell(obj.nApp,obj.nImg);
            end
            
            % sets the empty field to a NaN
            if isempty(obj.szObj)
                obj.szObj = NaN;
            end            
            
            % sets up the image filter (if required)
            [bgP,obj.hS] = deal(obj.iMov.bgP.pSingle,[]);
            if isfield(bgP,'useFilt')
                if bgP.useFilt
                    obj.hS = fspecial('disk',bgP.hSz);
                end
            end
            
            % initialises the progressbar (if one is not provided)
            if ~obj.hasProg; obj.initProgBar(); end
            
        end
        
        % ------------------------------------ %
        % --- IMAGE SEGMENTATION FUNCTIONS --- %
        % ------------------------------------ %     
        
        % --- runs the initial position estimation function
        function calcFullObjPos(obj)
            
            % updates the progressbar
            obj.updateProgBar(1,'Stack Segmentation Intialisation...',0);
            
            % sets the flags for the rejected/empty regions
            obj.iStatus(obj.iStatus==0) = 2;
            obj.iStatus(~obj.iMov.flyok) = 3;
            
            % allocates memory for the positional coordinates
            obj.fPos = repmat(arrayfun(@(x)...
                            (NaN(x,2)),obj.nTube(:),'un',0),1,obj.nImg);
            obj.IPos = repmat(arrayfun(@(x)...
                            (NaN(x,2)),obj.nTube(:),'un',0),1,obj.nImg);                        
            
            % calculates the object locations over all regions/frames
            for iApp = find(obj.iMov.ok(:)')
                % updates the progressbar
                wStr = sprintf(...
                    'Object Detection (Region %i of %i)',iApp,obj.nApp);
                if obj.updateProgBar(2,wStr,iApp/(1+obj.nApp))
                    % if the user cancelled, then exit
                    obj.calcOK = false;
                    return
                end
                
                % segments the region
                obj.segmentRegions(iApp);                
                
            end
            
            % updates the progressbar
            obj.updateProgBar(1,'Stack Segmentation Complete',1);
            obj.updateProgBar(2,'All Region Segmented',1);
            
        end
        
        % --- segments the all the objects for a given region
        function segmentRegions(obj,iApp)
            
            % initialisations
            imov = obj.iMov;
            iRT = imov.iRT{iApp};           
            y0L = [zeros(obj.nTube(iApp),1),obj.y0{iApp}(:)];
            
            % retrieves the global row/column indices
            nTubeR = getSRCount(obj.iMov,iApp);
            fok = obj.iMov.flyok(1:nTubeR,iApp);
            obj.dTol = max(obj.iMov.szObj);            
            
            % memory allocation
            xiF = obj.pInt.iFrm;
            fP0 = repmat({NaN(nTubeR,2)},1,obj.nImg);
            IP0 = repmat({NaN(nTubeR,1)},1,obj.nImg);            
            
            % sets up the region image stack
            ImgL = obj.setupRegionImageStack(iApp);

            % segments the location for each feasible sub-region
            for iTube = find(fok(:)')
                % sets the sub-region image stack
                ImgSR = cellfun(@(x)(x(iRT{iTube},:)),ImgL,'un',0);

                % calculates the x-correlation image stack
                ImgSeg = obj.setupXCorrStack(ImgSR);
                
                % calculates the estimate
                xI0 = obj.pInt.fPos{iApp}{iTube}(:,1);
                yI0 = obj.pInt.fPos{iApp}{iTube}(:,2) - y0L(iTube);                
                pEst = [interp1(xiF,xI0,obj.iFrmR,'pchip')',...
                        interp1(xiF,yI0,obj.iFrmR,'pchip')'];
                
                % segments the image stack
                [fP0nw,IP0nw] = obj.segmentSubRegion(ImgSeg,pEst);
                
                % sets the metric/position values
                for j = 1:obj.nImg
                    IP0{j}(iTube) = IP0nw(j);
                    fP0{j}(iTube,:) = fP0nw(j,:);
                end  
                
                % performs the orientation angle calculations (if required)
                if obj.iMov.calcPhi
                    % FINISH ME!
                    waitfor(msgbox('Finish Me!','Finish Me!','modal'))                    
                    
                    % creates the orientation angle object
                    phiObj = OrientationCalc(imov,...
                                            num2cell(IResL,2),fPos0,iApp);

                    % sets the orientation angles/eigan-value ratio
                    obj.Phi(iApp,:) = num2cell(phiObj.Phi,1);
                    obj.axR(iApp,:) = num2cell(phiObj.axR,1);
                    obj.NszB(iApp,:) = num2cell(phiObj.NszB,1);
                end                   
            end

            % converts the coordinates from sub-region to region
            obj.IPos(iApp,:) = IP0;
            obj.fPos(iApp,:) = cellfun(@(x)(x+y0L),fP0,'un',0);                        
            
        end                  
        
        % --- segments a sub-region with a moving object
        function [fP,IP] = segmentSubRegion(obj,Img,pEst)
            
            % memory allocation
            pW = 0.75;
            szL = size(Img{1});
            nFrm = length(Img);
            [fP,IP] = deal(NaN(nFrm,2),NaN(nFrm,1));
            Dscale = sqrt(prod(obj.iMov.szObj));
            
            % determines the regional maxima from the image stack
            iPmx = cellfun(@(x)(find(imregionalmax(x))),Img,'un',0);
            
            % determines the most likely object position over all frames
            for i = 1:nFrm                
                % sorts the maxima in descending order
                [Pmx,iS] = sort(Img{i}(iPmx{i}),'descend');
                pTolB = pW*Pmx(1);
                
                % calculates the locations of the local maxima
                [yP,xP] = ind2sub(szL,iPmx{i}(iS));
                Dest = pdist2(pEst(i,:),[xP(:),yP(:)])'/Dscale;                
                
                % determines how many prominent objects are in the frame
                ii = Pmx >= pTolB;
                if sum(ii) == 1
                    % case is there is only 1 prominent object
                    iMx = 1;
                else
                    % case is there are more than one prominent object
                    Z = Pmx(ii)./(1+Dest(ii));  
                    iMx = argMax(Z);
                end
                
                % sets the final positional/intensity values
                [fP(i,:),IP(i)] = deal([xP(iMx),yP(iMx)],Pmx(iMx));                
            end
            
        end        
        
        % ------------------------------------ %
        % --- IMAGE SEGMENTATION FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- sets up the image stack for the region index, iApp
        function ImgL = setupRegionImageStack(obj,iApp)
            
            % sets the region row/column indices
            [iR,iC] = deal(obj.iMov.iR{iApp},obj.iMov.iC{iApp});             
            
            % calculates the background/local images from the stack                       
            ImgL = cellfun(@(I)(I(iR,iC)),obj.Img,'un',0);                          
            
            % removes the rejected regions from the sub-images
            Bw = getExclusionBin(obj.iMov,[length(iR),length(iC)],iApp);
            ImgL = cellfun(@(I)(I.*Bw),ImgL,'un',0);
            
        end            
        
        % --- sets up the x-correlation image stack from the stack, Img
        function ImgXC = setupXCorrStack(obj,Img)
            
            % ensures the images are stored in a cell array
            if ~iscell(Img); Img = {Img}; end
            
            % memory allocation
            tP = obj.iMov.tPara;
            ImgXC = cell(length(Img),1);
            
            % sets up the x-correlation image stack
            for i = 1:length(Img)
                % calculates the original cross-correlation image
                [Gx,Gy] = imgradientxy(Img{i});
                B = isnan(Gx) | isnan(Gy);
                [Gx(B),Gy(B)] = deal(0);                
                
                % calculates the original cross-correlation image
                Ixc0 = max(0,calcXCorr(tP.GxT,Gx) + calcXCorr(tP.GyT,Gy));
                
                % calculates the final x-correlation mask
                if isempty(obj.hS)
                    ImgXC{i} = Ixc0/2;
                else
                    ImgXC{i} = imfilter(Ixc0,obj.hS)/2;
                end
            end
            
        end                               
        
        % --- histogram equalises the image stack, IappF
        function IappF = equaliseImageStack(obj,IappF,iApp)
            
            % parameters
            pTolEq = 5;
            
            % determines which images are within tolerance of the average
            % pixel intensity of the sub-region
            Iavg = obj.iMov.ImnF{obj.iPh}(iApp);
            isOK = abs(cellfun(@(x)(nanmean(x(:))),IappF)-Iavg) < pTolEq;
            
            % if any are not within tolerance, then equalise the images
            if any(~isOK)
                % calculates the reference image 
                Iref = uint8(calcImageStackFcn(IappF(isOK),'mean'));
                
                % matches the histograms of the images
                for i = find(~isOK(:)')
                    IappF{i} = double(imhistmatch(uint8(IappF{i}),Iref));
                end
            end
            
        end                
        
        % -------------------------- %
        % --- PLOTTING FUNCTIONS --- %
        % -------------------------- %
        
        function plotFramePos(obj,iImg,isFull)
            
            % sets the default input arguments
            if ~exist('isFull','var'); isFull = false; end
            
            % ensures the image count is correct
            if obj.nImg ~= length(obj.Img)
                obj.nImg = length(obj.Img);
            end
            
            % determine if the plot frame index is valid
            if iImg > obj.nImg
                % outputs an error message to screen
                eStr = sprintf(['The plot index (%i) exceeds the total',...
                    'number of frames (%i)'],iImg,obj.nImg);
                waitfor(errordlg(eStr,'Invalid Frame Reference','modal'))
                
                % exits the function
                return
            end
            
            % initialisations
            iStatusF = obj.iStatus;
            [I,iM] = deal(obj.Img{iImg},obj.iMov);
            [nR,nC] = deal(iM.nRow,iM.nCol);
            ILp = cellfun(@(ir,ic)(I(ir,ic)),iM.iR,iM.iC,'un',0);
            
            % creates the image/location plots for each sub-region
            figure;
            if isFull
                %
                h = subplot(1,1,1);
                plotGraph('image',I,h)
                hold on
                
            else
                %
                h = zeros(obj.nApp,1);
                
                for iApp = find(obj.iMov.ok(:)')
                    %
                    if isFull
                        ILshow = obj.IBG{iApp} - ILp{iApp};
                    else
                        ILshow = ILp{iApp};
                    end
                    
                    % plots the graph
                    h(iApp) = subplot(nR,nC,iApp);
                    plotGraph('image',ILshow,h(iApp));
                    hold on
                end
            end
            
            % plots the most likely positions
            hold on;
            for iApp = find(obj.iMov.ok(:)')
                % retrieves the marker points
                if isFull
                    j = 1;
                    fPosP = obj.fPosG{iApp,iImg};
                else
                    j = iApp;
                    fPosP = obj.fPos{iApp,iImg};
                end
                
                % plots the markers
                indF = 1:getSRCount(obj.iMov,iApp);
                isMove = iStatusF(indF,iApp) == 1;
                plot(h(j),fPosP(isMove,1),fPosP(isMove,2),'go');
                plot(h(j),fPosP(~isMove,1),fPosP(~isMove,2),'ro');
            end
            hold off
        end
        
        function plotFrameLikelyPos(obj,iImg)
            
            if length(obj.Img) ~= obj.nImg
                obj.nImg = length(obj.Img);
            end
            
            % determine if the plot frame index is valid
            if iImg > obj.nImg
                % outputs an error message to screen
                eStr = sprintf(['The plot index (%i) exceeds the total',...
                    'number of frames (%i)'],iImg,obj.nImg);
                waitfor(errordlg(eStr,'Invalid Frame Reference','modal'))
                
                % exits the function
                return
            end
            
            % initialisations
            [I,iM] = deal(obj.Img{iImg},obj.iMov);
            [nR,nC] = deal(iM.nRow,iM.nCol);
            ILp = cellfun(@(ir,ic)(I(ir,ic)),iM.iR,iM.iC,'un',0);
            
            % creates the image/location plots for each sub-region
            figure;
            for iApp = find(obj.iMov.ok(:)')
                % plots the graph
                plotGraph('image',ILp{iApp},subplot(nR,nC,iApp));
                hold on;
                
                %
                pMaxP = obj.pMax{iApp,iImg};
                for iT = 1:length(pMaxP)
                    % plots the most like positions
                    if ~isempty(pMaxP{iT})
                        plot(pMaxP{iT}(:,1),...
                            pMaxP{iT}(:,2)+obj.y0{iApp}(iT),'ro');
                    end
                end
            end
        end
        
        function plotResidualImages(obj,iImg)
            
            obj.plotFramePos(iImg,true)
            
        end
        
        % -------------------------- %
        % --- PROGRESS FUNCTIONS --- %
        % -------------------------- %
        
        % --- initialises the waitbar figure
        function initProgBar(obj)
            
            % waitbar field/title strings
            wStr = {'Overall Progress','Algorithm Progress'};
            tStr = 'Direction Detection Algorithm';
            
            % creates the waitbar figure
            obj.hProg = ProgBar(wStr,tStr);
            
        end
        
        % --- updates the waitbar figure
        function isCancel = updateProgBar(obj,iLvl,wStr,pW)
            
            isCancel = obj.hProg.Update(iLvl+obj.wOfs,wStr,pW);
            
        end  
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- initialises the parameter struct
        function initParaStruct(obj)
            
            obj.iPara = struct('Nh',30,'N',5,'SD',2);
            
        end
        
        % --- calculates the global coords from the sub-region reference
        function calcGlobalCoords(obj)
            
            % exit if not calculating the background
            if ~obj.calcOK; return; end
            
            % memory allocation
            [~,nFrm] = size(obj.fPos);
            [obj.fPosG,obj.fPosL] = deal(repmat(...
                arrayfun(@(x)(NaN(x,2)),obj.nTube,'un',0),1,nFrm));
            
            % converts the coordinates from the sub-region to global coords
            for iApp = find(obj.iMov.ok(:)')
                % calculates the x/y offset of the sub-region
                xOfs = obj.iMov.iC{iApp}(1)-1;
                yOfs = obj.iMov.iR{iApp}(1)-1;
                pOfsL = [zeros(obj.nTube(iApp),1),obj.y0{iApp}(:)];
                
                % calculates the global offset and appends it to each frame
                pOfs = repmat([xOfs,yOfs],obj.nTube(iApp),1);
                for i = 1:nFrm
                    % calculates the sub-region/global coordinates
                    obj.fPosL{iApp,i} = obj.fPos{iApp,i} - pOfsL;
                    obj.fPosG{iApp,i} = obj.fPos{iApp,i} + pOfs;                    
                end
            end
            
        end      
        
        % --- closes the progressbar (if created within internally)
        function performHouseKeepingOperations(obj)
            
            % clears the temporary image array fields
            obj.ImdBG = [];
            obj.ImdRL = [];
            obj.ImdR = [];
            obj.ImdL = [];
            obj.IL = [];
            obj.iGrpP = [];
            obj.zGrpP = [];
            
            % deletes the progress figure (if created within class)
            if ~obj.hasProg
                obj.hProg.closeProgBar();
            end
            
        end        
        
    end
    
end
