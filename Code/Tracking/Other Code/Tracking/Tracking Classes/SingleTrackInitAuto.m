classdef SingleTrackInitAuto < SingleTrackInit
    
    % class properties
    properties
        
        % auto-detection fields
        iCG
        iRG
        fOK
        Iopt
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
        
        % other parameter fields
        pW = 0.5;
        dtPer0 = 0.1;
        pIRTol = 0.6;
        pIRTolN = 0.4;
        pTolShape = 0.1; 
        seOpen = ones(21,1);
        seSig = fspecial('disk',3);
        
    end
    
    % class methods
    methods
        
        % class constructor
        function obj = SingleTrackInitAuto(iData)
            
            % creates the super-class object
            obj@SingleTrackInit(iData,false);
            
            % sets the auto-detection flag
            obj.isAutoDetect = true;
   
        end                
        
        % -------------------------------- %
        % --- BLOB DETECTION FUNCTIONS --- %
        % -------------------------------- %        
        
        % --- calculates the initial fly location/background estimates
        function calcInitEstimateAuto(obj,iMov,hProg)
            
            % sets the input variables                        
            obj.iMov = iMov;
            obj.hProg = hProg; 
            
            % other initialisations
            obj.nTubeBest = obj.nTube;
                        
            % runs the pre-estimate initialisations
            obj.preEstimateSetup();            
        
            % runs the initial auto-detection
            obj.runInitialDetectionAuto()
            
        end
        
        % --- runs the initial detection on the image stack, Img
        function runInitialDetectionAuto(obj)
            
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
                wStrNw = sprintf('Moving Object Detection (Phase #%i)',i);
                
                % updates the progress bar
                pW0 = (j+1)/(2+nPh);
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
                
                % analyses the phase (depending on type)
                obj.autoDetectEstimate(obj.Img{i},i);
                
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
        
        % ---------------------------------- %
        % --- 1D AUTO-DETECTION ESTIMATE --- %
        % ---------------------------------- %
        
        % --- wrapper function for calculating the detection estimate
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
                iC0 = ceil(pP(1))+(0:floor(pP(3)));
                obj.iCG{i} = iC0((iC0>0)&(iC0<=szFrm(2)));
                
                % sets the row indices
                iR0 = ceil(pP(2))+(0:floor(pP(4)));
                obj.iRG{i} = iR0((iR0>0)&(iR0<=szFrm(1)));
                
                % sets up the homomorphic filter
                obj.iMov.phInfo.hmFilt{i} = ...
                                    setupHMFilter(obj.iRG{i},obj.iCG{i});
            end          
            
            % sets the image stacks
            iFrmF = obj.indFrm{iPh};
            [IL,IR] = deal(cell(length(Img),obj.nApp));
            [obj.IbgT{iPh},obj.IbgT0{iPh}] = deal(cell(1,obj.nApp));
            
            % sets up the raw/residual image stacks
            for i = 1:obj.nApp
                % retrieves the region image stack
                IL(:,i) = obj.getRegionImageStack(Img,iFrmF,i);
                
                % calculates the 
                IbgTnw = calcImageStackFcn(IL(:,i),'max');
                [obj.IbgT{iPh}{i},obj.IbgT0{iPh}{i}] = deal(IbgTnw);

                % calculates the background estimate and residuals
                IR(:,i) = cellfun(@(x)(obj.IbgT{iPh}{i}-x),IL(:,i),'un',0);            
            end
                
            % ----------------------------------------- %
            % --- DETECTION ESTIMATION CALCULATIONS --- %
            % ----------------------------------------- %
            
%             obj.calcAllRegionProps(IL,IR)            
            
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
                obj.setupBlobTemplateAuto(IL)
            catch ME
                % if there was an error then store the details
                obj.errStr = 'object template calculation';
                [obj.errMsg,obj.calcOK] = deal(ME.message,false);
                return                
            end
              
            try
                % optimises the grid placements
                obj.optGridVertPlacement(IL,IR);
                obj.optGridHorizPlacement(IR);  
                
            catch ME
                % if there was an error then store the details
                obj.errStr = 'grid placement optimisation';
                [obj.errMsg,obj.calcOK] = deal(ME.message,false);
                return                
            end            
            
            % final progressbar update
            obj.hProg.Update(2+obj.wOfsL,'Grid Detection Complete',1);
            
        end
        
        % --- detects the moving blobs from the residual image stack, IR
        function detectMovingBlobAuto(obj,IR)
            
            % if the user cancelled, then exit
            if ~obj.calcOK; return; end
            obj.hProg.Update(2+obj.wOfsL,'Moving Object Tracking',0.2);
            obj.hProg.Update(3+obj.wOfsL,'Analysing Region',0);     
            
            % initialisations
            nApp = length(obj.iMov.pos);
            [obj.ImaxR,obj.pTolR] = deal(cell(nApp,1),zeros(nApp,1));
            
            % attempts to calculate the coordinates of the moving objects            
            for iApp = 1:nApp
                % updates the progress bar
                wStrNw = sprintf('Analysing Region (%i of %i)',iApp,nApp);
                if obj.hProg.Update(3+obj.wOfsL,wStrNw,iApp/(1+nApp))
                    obj.calcOK = false;
                    return
                end                
                
                % removes the edge region of the image
                IRmax = calcImageStackFcn(IR(:,iApp),'max');
                Bedge = bwmorph(bwmorph(true(size(IRmax)),'remove'),'dilate');
                IRmax(Bedge) = 0;
                
                % calculates the normalised row residual signal. from this,
                % determine the number of signficant peaks from the signal                
                ImaxR0 = max(IRmax,[],2);
                ImaxR0(isnan(ImaxR0)) = 0;
                obj.ImaxR{iApp} = ImaxR0 - imopen(ImaxR0,obj.seOpen);
                
                % sets up the signal values
                Imx = max(obj.ImaxR{iApp},[],'omitnan');
                Imn = min(obj.ImaxR{iApp},[],'omitnan');
                obj.pTolR(iApp) = obj.pW*(Imx+Imn);
                                
                % thresholds the signal for the signficant peaks                 
                iGrp = getGroupIndex(obj.ImaxR{iApp} > obj.pTolR(iApp));                                       
                
                % from the positions from the most likely peaks               
                if ~isempty(iGrp)
                    obj.fPos0{1}(iApp,:) = cellfun(@(x)...
                                (obj.trackAutoMovingBlobs(x,iGrp)),...
                                IR(:,iApp),'un',0);
                    obj.pStats{iApp,1,1} = ...
                            combineNumericCells(cellfun(@(x,y)...
                                (obj.getPixelValue(x,y)),IR(:,iApp),...
                                obj.fPos0{1}(iApp,:)','un',0)');
                end
            end                    

            % updates the progressbar
            obj.hProg.Update(3+obj.wOfsL,'Region Analysis Complete',1);            
            
        end                  
        
        % --- determines the automatic detection blob template
        function setupBlobTemplateAuto(obj,I)
            
            % if the user cancelled, then exit
            if ~obj.calcOK; return; end
            obj.hProg.Update(2+obj.wOfsL,'Blob Template Calculation',0.4);
            obj.hProg.Update(3+obj.wOfsL,'Sub-Image Stack Setup',0);                
            
            % initialisations
            dN = 15; 
            mStr = 'omitnan';
            
            % memory allocation
            sD = NaN(1,2);            
            nApp = size(obj.fPos0{1},1);            
            [Isub,obj.useP,obj.ImaxS] = deal(cell(nApp,1));            

            % retrieves the sub-images around each significant point
            for i = 1:nApp
                % retrieves the point sub-image stack
                Isub{i} = cell2cell(cellfun(@(x,y)(cellfun(@(z)...
                        (obj.getPointSubImage(x,z,dN)),num2cell(y,2),...
                        'un',0)),I(:,i)',obj.fPos0{1}(i,:),'un',0),0);

                % removes any low-residual images
                obj.useP{i} = obj.pStats{i,1,1} > obj.pTolR(i);
                Isub{i}(~obj.useP{i}) = {[]};
            end            

            % calculates the template image from the estimated image
            IsubT = cell2cell(Isub);
            IsubN = cellfun(@(x)(max(0,median(x(:))-x)),...
                                IsubT(~cellfun('isempty',IsubT)),'un',0);
            Itemp = calcImageStackFcn(IsubN,'mean');
            
            % calculates the shape gaussian std. dev
            for i = 1:2
                Imx = max(Itemp,[],i,mStr);
                sD(i) = obj.optGaussSignal(Imx);
            end                       
            
            % sets the object template field
            obj.hProg.Update(3+obj.wOfsL,'Blob Template Calculation',0.5); 
            [GxT,GyT] = imgradientxy(Itemp,'sobel'); 
            obj.tPara{1} = struct('Itemp',Itemp,'GxT',GxT,'GyT',GyT);              
            
            % sets the class object fields
            obj.iMov.szObj = roundP(2*sD*sqrt(log(1/obj.pTolSz)));
            
            % updates the progresbar
            obj.hProg.Update(3+obj.wOfsL,'Template Calculation Complete',1);
            
        end            
        
        % -------------------------------------- %
        % --- 1D GRID OPTIMISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- optimises the grid vertical placement
        function IRL = optGridVertPlacement(obj,I,IR)
            
            % if the user cancelled, then exit
            if ~obj.calcOK; return; end
            obj.hProg.Update(2+obj.wOfsL,'Vertical Grid Placement',0.6);
            obj.hProg.Update(3+obj.wOfsL,'Sub-Image Stack Setup',0);             
            
            % parameters  
            pWT = 0.75; 
            pWmx = 1.10;
            dPMin = min(obj.iMov.szObj)/2;
            dtMin = max(ceil(pWT*obj.iMov.szObj));              
            
            % initialisations and memory allocation            
            nTube = obj.nTube;
            [nImg,nApp] = size(I);
            IRL = cell(nApp,1);
            obj.fOK = find(obj.iMov.ok(:)');

            % memory allocation
            C = NaN(nApp,nImg);
            Ymx = cell(1,nApp);
            Dt = cell(nImg,nImg,nApp);
            [tPk,yPk] = deal(cell(nApp,nImg));   
            
            % calculates the 
            nFlyMx = max(sum(obj.iMov.pInfo.nFly,1));
            dtMax = ceil(pWmx*obj.iMov.posG(4)/nFlyMx);
            
            % ensures the min period is less that the max (check on this?)
            if dtMin > dtMax
                dtMin = dtMax/2;
            end
            
            % calculates the 
            pIR0 = cellfun(@(x)(max(x(:))/mean(x(x>0))),IR);
            pIRmd = median(pIR0,1);
            
            pIRN = pIRmd/max(pIRmd);
            pIR = pIRmd/median(pIRmd);
            okIR = (pIR >= obj.pIRTol) & (pIRN >= obj.pIRTolN);
            
            % determines the feasible regions
            ok = setGroup(obj.fOK(:),[1,nApp]) & okIR;            
            
            % --------------------------------------- %
            % --- INITIAL GRID SPACING ESTIMATION --- %
            % --------------------------------------- %
            
            % this part of the function attempts to estimate the overall
            % grid spacing over all regions
            %  NOTE: future iterations may require the function to be
            %        expanded so that each region is treated separately
            
            % updates the progessbar
            obj.hProg.Update(3+obj.wOfsL,'Signal Peak Detection',0.25); 
            
            %
            nD = floor(dPMin/2);
            szL = cellfun(@(x)(size(x)),IR(1,:),'un',0);            
                            
            % calculates the signal
            for i = obj.fOK                
                % calculates the normalised maxima
                [Ymx0,Ymx{i}] = obj.setupRegionSignal(IR(:,i),szL{i},nD);
                
                % determines the major peaks from the image stack
                for j = 1:nImg
                    % calculates the signal peaks (and any sub-groups)
                    [yPk0,tPk0] = obj.calcSignalPeaks(Ymx0{j},dPMin);
                    [idx,C0] = kmeans(yPk0,2);

                    % retrieves the times of the significant peaks
                    iMx = argMax(C0);
                    [ii,C(i,j)] = deal(idx == iMx,C0(iMx));
                    [tPk{i,j},yPk{i,j}] = deal(tPk0(ii),yPk0(ii));
                end    
                
                % calculates the distances between the major peaks
                for j = 1:nImg
                    for k = (j+1):nImg
                        Dnw = pdist2(tPk{i,j},tPk{i,k}); 
                        Dt{k,j,i} = arr2vec(Dnw(~isnan(Dnw))); 
                    end
                end
            end
            
            % calculates the spacing difference between sub-regions
            Dtot = cell2mat(Dt(~cellfun('isempty',Dt))); 
            N = histcounts(Dtot,1:max(Dtot)); 
            Ns = [0;smooth(N(2:end))];
            
            % calculates the histogram cross-correlation, and from this
            % determines most likely grid spacing frequency
            [aY0,cLags] = xcorr(Ns,Ns,[],'coeff');
            aY = aY0(cLags >= 0);
            [yPD,tPD] = findpeaks(aY);
            
            % removes the peaks that are infeasible. the estimate of the
            % grid spacing is taken as the time with the highest peak
            ii = (tPD >= dtMin) & (tPD <= dtMax);                
            [tPD,yPD] = deal(tPD(ii),yPD(ii));
            tPerEst = tPD(argMax(yPD));
            
            % calculates the grid spacing limits
            tPerL = [max(dtMin,tPerEst-5),min(dtMax,tPerEst+5)];

            % ----------------------------------------- %
            % --- INITIAL GRID PARAMETER ESTIMATION --- %
            % ----------------------------------------- %  
            
            % memory allocation
            [obj.xTube,obj.yTube] = deal(cell(length(obj.iMov.ok),1));
                 
            % determines which regions have a low overall residual value 
            % (these will be excluded here but analysed later)
            [tPer0,yOfs0] = deal(NaN(nApp,1));
            
            % aligns the signal peaks over all regions
            for i = find(obj.iMov.ok(:)')
                % updates the progressbar
                wStrNw = sprintf...
                        ('Optimising Grid Placement (%i of %i)',i,nApp);
                if obj.hProg.Update(3+obj.wOfsL,wStrNw,0.5*(1+i/nApp))
                    % if the user cancelled, then exit
                    obj.calcOK = false;
                    return
                end
                
                if ok(i)
                    % estimates initial grid properties (spacing & offset)
                    [tPer0(i),yOfs0(i),ok(i)] = ...
                        obj.estGridProps(Ymx{i},tPk(i,:),yPk(i,:),i,tPerL);
                
                    % sets the vertical tube locations
                    obj.yTube{i} = tPer0(i)*(0:nTube(i))' + yOfs0(i);
                end
            end    

            % ------------------------------- %            
            % --- AMBIGUOUS REGION SEARCH --- %
            % ------------------------------- %
            
            if all(ok)
                % exits all regions have been investigated successfully
                return
                
            elseif ~any(ok)
                % case is there are no feasible regions
                obj.calcOK = false;
                return
            end
            
            tPerMd = median(tPer0(ok));
            
            % determines the raw image signals for the known regions
            iok = find(ok);
            Zmx0 = arrayfun(@(x)(calcImageStackFcn(...
                obj.setupRegionSignal(I(:,x),szL{x},nD),'median')),...
                iok,'un',0);
                 
            % calculates the median peak values for each region
            ZmxU = NaN(size(ok)); 
            for i = 1:length(iok)
                j = iok(i);
                ZmxN = Zmx0{i}/max(Zmx0{i});
                iPkU = unique(cell2mat(arr2vec(tPk(j,:))));
                ZmxU(j) = median(ZmxN(iPkU));
            end
            
            % determines if the peak signals need matching
            isMin = median(ZmxU(ok)) < 0.5;
            
            % re-searches each of the ambiguous regions
            for i = find(~ok(:)')
                % updates the progressbar
                wStrNw = sprintf...
                        ('Reinvestigating Grid Placement (%i of %i)',i,nApp);
                if obj.hProg.Update(3+obj.wOfsL,wStrNw,0.5*(1+i/nApp))
                    % if the user cancelled, then exit
                    obj.calcOK = false;
                    return
                end
                
                % determines the overall raw image stack signal 
                Imd = calcImageStackFcn(I(:,i),'median');
                [~,ZmxN] = obj.setupRegionSignal({Imd},szL{i},nD);
                if isMin; ZmxN = -ZmxN; end
                
                % calculates the signal peaks
                [yPkN,tPkN] = obj.calcSignalPeaks(ZmxN,dPMin);
                                
                % determines if the peak count is correct
                nPkN = length(yPkN);
                if nPkN < nTube(i)
                    %
                    a = 1;
                    
                elseif nPkN > nTube(i)
                    % case is there are more peaks than tube counts
                    xiN = 1:nTube(i); 
                    dxiN = 0:(nPkN-nTube(i));
                    yPkS = arrayfun(@(x)(sum(yPkN(x+xiN))),dxiN);
                    
                    % determines the optimal configuration
                    ii = xiN + (argMax(yPkS)-1);                    
                    tPkN = tPkN(ii);
                end
                
                % calculates the optimal spacing frequency
                xiZ = max(1,floor(tPkN(1)-tPerMd)):...
                      min(length(ZmxN),ceil(tPkN(end)+tPerMd));
                tPer0(i) = obj.calcOptSignalFreq({ZmxN(xiZ)},tPerL,nTube(i));
                  
                % sets up the signal weighting array
                Fh = tPer0(i)/2;
                xiF0 = 1:floor(nTube(i)*tPer0(i));
                xiF = mod(xiF0(:)-1,tPer0(i)) + 1;
                QZ = 1 - abs((Fh - (xiF-0.5))/Fh);
                
                % determines the optimal offset
                QZ = obj.setupWeightingVector(tPer0(i),nTube(i));
                if length(QZ) >= length(ZmxN)
                    yOfs0(i) = 1;
                    
                else
                    xiZ = 1:(length(ZmxN)-length(QZ));
                    QZs = arrayfun(@(x)(obj.calcObjFcn(ZmxN,QZ,x-1)),xiZ); 
                    yOfs0(i) = xiZ(argMax(QZs));
                end
                
                % sets the vertical tube locations
                obj.yTube{i} = tPer0(i)*(0:nTube(i))' + yOfs0(i);                
                
                % REMOVE ME LATER
                if i == 14
                    a = 1;
                end
            end
            
        end                      
        
        % --- optimises the grid vertical placement
        function optGridHorizPlacement(obj,IRL)
            
            % if the user cancelled, then exit
            if ~obj.calcOK; return; end
            obj.hProg.Update(2+obj.wOfsL,'Horiztonal Grid Placement',0.8);                        
            
            % parameters
            pTol = 0.5;
            xDel = ceil(obj.iMov.szObj(1)/2);
            N = length(obj.iMov.posO);
            
            % determines the horizontal extent of all valid regions
            for i = find(~cellfun('isempty',obj.yTube(:)'))
                % updates the progressbar
                wStrNw = sprintf('Detecting Region Extent (%i of %i)',i,N);
                if obj.hProg.Update(3+obj.wOfsL,wStrNw,i/N)
                    obj.calcOK = false;
                    return
                end
                
                % calculates the maximum over the image stack
                IRLT = calcImageStackFcn(IRL(:,i),'max');
                
                % removes any rows not within the vertical regions
                sz = size(IRL{1,i},1);    
                yT = roundP(obj.yTube{i});
                ii = max(1,yT(1)):min(sz(1),yT(end));
                IRLT(~setGroup(ii,[sz(1),1])) = 0;
                
                % sets the grid horizontal dimensions
                iGrp = getGroupIndex(max(normImg(IRLT),[],1) > pTol);
                obj.xTube{i} = [max(iGrp{1}(1)-xDel,1),...
                                min(iGrp{end}(end)+xDel,size(IRLT,2))];
            end
            
        end           
        
        % --- removes the baseline from the signal, Y
        function Yrmv = rmvBaseline(obj,Y) 
            
            Y(isnan(Y)) = 0;
            Yrmv = Y - imopen(Y,obj.seOpen);
            
        end
        
        % --- estimates the initial grid properties (spacing & offset)
        function [tPerF,yOfsF,ok] = estGridProps(obj,Y,tPkT,yPkT,iApp,tPerL)
            
            % if any signals have no peaks, or there are no multi-peak
            % signals, then exit
            nPk = cellfun('length',tPkT);
            if any(nPk == 0) || all(nPk <= 1)
                ok = false;
                [tPerF,yOfsF] = deal(NaN);
                return
            end            
            
            % parameters
            ok = true;
            Nt = getSRCount(obj.iMov,iApp);            
            tPerF = obj.calcOptSignalFreq(Y,tPerL,Nt);            
            
            % determines the most likely grid spacing size
            yL = (0:Nt)*tPerF;
            
            % ----------------------------- %
            % --- SIGNAL PEAK REDUCTION --- %
            % ----------------------------- %            
            
            % calculates the half grid span size
            dtPerF = floor(tPerF/2);  
            
            % determines the feasible grid offset values 
            nR = length(Y{1});
            dtPerL = floor(tPerF/4);
            xiP = -dtPerL:floor(nR-yL(end)+dtPerL);             
            
            % keep looping until a feasible solution is achieved
            while ~isempty(xiP)
                % reduces down the close peaks
                tPkTF = obj.removeClosePeaks(tPkT,yPkT,dtPerF);
            
                % retrieves the 
                isFeas = arrayfun(@(x)(obj.checkGridFeas(tPkTF,x,yL)),xiP);
                if isempty(isFeas) || any(isFeas)
                    break
                else
                    % increments
                    dtPerF = dtPerF + 1;
                end
            end            
            
            % --------------------------- %
            % --- OFFSET OPTIMISATION --- %
            % --------------------------- %                                               
            
            % determines 
            xiPF = xiP(isFeas);
            tPkTF = arr2vec(tPkTF(~isnan(tPkTF)));
            nTot = arrayfun(@(x)(sum(histcounts(tPkTF,x+yL([1,end])))),xiPF); 
            
            % calculates the object functions values for each offset value
            Z = arrayfun(@(x)(min(arr2vec(pdist2(tPkTF,x+yL(:))))),xiPF);            

            % sets up the final objective function array
            nTotMin = max(nTot) - Nt/2;            
            while 1
                QZ = Z.*(nTot>nTotMin);            
                if all(QZ == 0)
                    nTotMin = nTotMin - Nt/2;
                else
                    break
                end
            end
            
            % returns the optimal grid offset
            pkMin = 0.9;
            if length(QZ) >= 3
                try
                    % calculates the location of the peaks
                    QZn = QZ/max(QZ);
                    [~,tPk] = findpeaks(QZn,'MinPeakHeight',0.9);
                catch ME
                    if strcmp(ME.identifier,'MATLAB:TooManyInputs')
                        % if running the old version of the function, then
                        % run without any input arguments
                        [yPk,tPk] = findpeaks(QZn);
                        tPk = tPk(yPk >= pkMin);
                        
                    else
                        % otherwise, rethrow the error
                        rethrow(ME)
                    end
                end
                
                if isempty(tPk)
                    yOfsF = xiPF(argMax(QZn));
                else
                    yOfsF = xiPF(tPk(1));
                end
            else
                yOfsF = xiPF(argMax(QZ));
            end
            
        end        
            
        % --- objective function for optimising the grid placement 
        function varargout = optFunc(obj,tPer,Ymx,N,varargin)
            
            % --- sets up the dummy repeating signal for cross-correlation
            function Ysig = setupDummySignal(tPer,N,szObj)

                % initialisations
                hS = min(szObj)^0.25;
                T = (1:ceil(tPer*N))';
                Ysig = zeros(size(T));

                % sets up the signal
                for i = 1:N
                    dT = ((i-1)+0.5)*tPer;
                    Ysig = Ysig + exp(-((T-dT)/hS).^2);
                end

            end

            % sets up the repeating signal
            Ysig = setupDummySignal(tPer,N,obj.iMov.szObj);            

            % calculates the maximum cross-correlation value/location
            YxcT = cellfun(@(x)(xcorr(x,Ysig(:))),Ymx,'un',0);
            YxcTmn = calcImageStackFcn(YxcT);                        
            if isempty(varargin)
                % determines the max value from the peak signal value
                varargout{1} = max(YxcTmn);      
            else
                % initialisations
                nR = length(Ymx{1});
                dtPer = floor(tPer/2);
                [yL,tPkT] = deal((0:N)*tPer,varargin{1});
                
                % determines which rows are feasible
                xiP = (1:length(YxcTmn)) - nR;
                isFeas = (xiP > -dtPer) & (xiP < floor(nR-yL(end)+dtPer));
                
                % sets up the weighting matrix
                Q = zeros(size(YxcTmn));
                Q(isFeas) = double(arrayfun(@(x)...
                            (obj.checkGridFeas(tPkT,x,yL)),xiP(isFeas)));
                
                % sets the output value
                varargout{1} = xiP(argMax(Q.*YxcTmn)); 
            end
            
        end                                    

        % ------------------------------------- %
        % --- NEW DETECTION CLASS FUNCTIONS --- %
        % ------------------------------------- %   
        
        % --- calculates the properties for all of the regions
        function calcAllRegionProps(obj,I,IR)
            
            % memory allocation
            ok = true(obj.nApp,1);
            tPerF = NaN(obj.nApp,1);
            xLimF = NaN(obj.nApp,2);
            YblkF = cell(obj.nApp,1);
            szH = cellfun(@(x)(size(x,1)),I(1,:)');
            
            %
            for i = 1:obj.nApp
                % updates the progressbar
                
                
                % calculates the region properties
                [xLimF(i,:),tPerF(i),YblkF{i},ok(i)] = ...
                                        obj.calcRegionProps(I(:,i));
                if ok(i)
                    obj.xTube{i} = xLimF(i,:);
                end
                
                % decision point...
                %  - if the height of the region is very tight, then
                %    perform search on the final image signal
                %  - otherwise, using the final image and residual signals,
                %    determine the optimal locationing of the grid regions
                nRowC = szH(i)/tPerF(i);
                if nRowC > (obj.nTube(i) + 0.5)
                    % case is loose fitting regions
                    obj.setupLooseRegion(tPerF(i),YblkF{i},i);
                    
                else
                    % case is tight fitting regions                    
                    obj.setupTightRegion(tPerF(i),YblkF{i},i);
                end
            end
            
            a = 1;
            
        end
        
        % --- sets up the tube grid placement for loose fitted regions
        function setupLooseRegion(obj,tPerF,YblkF,iApp)
            
            % field retrieval
            QZ = obj.setupWeightingVector(tPerF,obj.nTube(iApp));
            
            %
            nQZ = length(QZ);
            xiQZ = 1:(length(YblkF) - nQZ);
            Q = arrayfun(@(x)(dot(QZ,YblkF((x-1)+(1:nQZ)))),xiQZ);
                        
            % sets the vertical tube locations
            yOfsF = xiQZ(argMax(Q)) - 1;
            obj.yTube{iApp} = tPerF*(0:obj.nTube(iApp))' + yOfsF;
                        
        end
        
        % --- sets up the tube grid placement for tightly fitted regions
        function setupTightRegion(obj,tPerF,YblkF,iApp)            
            
            % determines the optimal offset
            QZ = obj.setupWeightingVector(tPerF,obj.nTube(iApp));
            yOfsF = finddelay(QZ,normImg(YblkF));            
            
            % sets the vertical tube locations
            obj.yTube{iApp} = tPerF*(0:obj.nTube(iApp))' + yOfsF;            
            
        end
        
        % --- calculates the properties for the region image stack, I 
        function [xLimF,TperF,YblkF,ok] = calcRegionProps(obj,I)
            
            % initialisations
            ok = true;
            
            % parameters
            Nh = 5;
            dTol = 1.0;
            YpTol = 0.2;
            xLimF = NaN(1,2);             
            
            % sets up and calculates the region block signals
            [Tp0,Yp0] = obj.setupRegionBlockSignals(I,5);
            Yp0N = Yp0/max(Yp0);
            
            % determines the comparative block groupings
            isTF = ~isnan(Tp0);            
            xiT = find(isTF,1,'first'):find(isTF,1,'last');
            [iID,i0] = deal(NaN(length(Tp0),1),1);
            
            % sets the ID flags for each of the groups
            for i = 1:length(xiT)
                % only check values in reverse order
                if i > 1
                    % if the block is too dissimilar, then increment the
                    % block group ID counter
                    dTp = abs(diff(Tp0(xiT((i-1)+[0,1]))));
                    if (dTp > dTol) || (Yp0N(i-1) < YpTol)
                        i0 = i0 + 1;
                    end
                end
                
                % sets the group ID flag
                iID(xiT(i)) = i0;
            end
            
            % calculates the group objective score values (attempt to
            % maximise array length AND mean signal strength)
            xiID = 1:i0;
            iGrp = arrayfun(@(x)(find(iID == x)),xiID,'un',0);
            QZ = sqrt(cellfun('length',iGrp)).*...
                      cellfun(@(x)(mean(Yp0(x))),iGrp);
            
            % determines the coarse x-limits
            iMx = argMax(QZ);            
            TpF = Tp0(iGrp{iMx}([1,end]));
            xL0 = [Nh*(iGrp{iMx}(1)-1)+1,Nh*(iGrp{iMx}(end)+1)];
            
            % performs a fine search on the x-limits
            iCL = {xL0(1):(xL0(1)+(2*Nh-1)),...
                  (xL0(2)-(2*Nh-1)):xL0(2)};            
            
            %          
            for i = 1:length(iCL)
                % calculates the periodicity of the region sub-blocks
                IL = cellfun(@(x)(x(:,iCL{i})),I,'un',0);
                Tp = obj.setupRegionBlockSignals(IL,1);
                clear IL
                
                % determines the first block that is within limits
                if i == 1
                    i0 = find(abs(Tp-TpF(i)) < dTol,1,'first');
                else
                    i0 = find(abs(Tp-TpF(i)) < dTol,1,'last');
                end
                
                % sets the fine limit value
                if isempty(i0)
                    % case is no valid block was found
                    if i == 1
                        % case is the lower limit block
                        xLimF(i) = iCL{i}(1);
                        
                    else
                        % case is the upper limit block
                        xLimF(i) = iCL{i}(end);
                    end
                    
                else
                    % case is a valid block was found
                    xLimF(i) = iCL{i}(i0);
                end
            end
            
            % calculates the final full block periodcity
            iCF = xLimF(1):xLimF(2);
            IL = cellfun(@(x)(x(:,iCF)),I,'un',0); 
            YblkF = obj.setupBlockSignal(IL,0);
            TperF = obj.calcSignalPeriodicity(YblkF);
            
        end
        
        % --- sets up and analyses blocks from the image stack, I, which
        %     consist of a image half-width, Nh
        function [Tp,Yp] = setupRegionBlockSignals(obj,I,Nh)
            
            % initialisations
            N = 2*Nh;
            iC = 1:N;
            Np = floor(size(I{1},2)/Nh)-1;
            [Tp,Yp] = deal(NaN(Np,1));            
            
            % sets up and analyses the region block signal
            for i = 1:Np
                Yblk = obj.setupBlockSignal(I,0,(i-1)*(N/2) + iC);
                [Tp(i),Yp(i)] = obj.calcSignalPeriodicity(Yblk);
            end
            
        end
        
        % --- sets up the sub-block signal
        function Zs = setupBlockSignal(obj,I,useMax,iC)
            
            % sets the default input arguments
            if ~exist('iC','var'); iC = 1:size(I{1},2); end
            
            % sets up the concatenated image stack array
            Iblk = cell2mat(cellfun(@(x)(x(:,iC)),I(:)','un',0));
            
            % sets up the signal based on type
            if useMax
                % case is using the maximum block value
                Zs = obj.rmvBaseline(max(Iblk,[],2));
                
            else
                % case is using the median block value
                Zs = obj.rmvBaseline(median(Iblk,2));
            end
            
        end        
        
        % ----------------------------- %
        % --- OTHER CLASS FUNCTIONS --- %
        % ----------------------------- %   
        
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
            if isempty(obj.Iopt)
                szObj = NaN(1,2);
            else
                Bopt0 = obj.Iopt/max(obj.Iopt(:));
                Bopt = bwmorph(Bopt0 > obj.pTolShape,'majority');
                [~,objBB] = getGroupIndex(Bopt,'BoundingBox');            
                szObj = objBB([3,4]);
            end
            
        end           
        
        % --- sets up the region signal
        function [Ymx0,YmxN] = setupRegionSignal(obj,I,sz,nD)
            
            % calculates the filtered image
            BE = ~bwmorph(bwmorph(true(sz),'remove'),'dilate',nD);
            IRF = cellfun(@(x)(imfilter(x,obj.seSig)),I,'un',0);
            
            % calculates the max signal value (after removing the baseline)
            Ymx0 = cellfun(@(x)(max(BE.*x,[],2)),IRF,'un',0);
            Ymx0 = cellfun(@(x)(obj.rmvBaseline(x)),Ymx0,'un',0);
            
            % returns the normalised image
            if nargout == 2
                YmxN = cellfun(@(x)(normImg(x)),Ymx0,'un',0);
                if length(I) == 1
                    [YmxN,Ymx0] = deal(YmxN{1},Ymx0{1});
                end
                
            elseif length(I) == 1
                Ymx0 = Ymx0{1};
            end            
            
        end
        
        % --- calculates the optimal signal frequency
        function tPerF = calcOptSignalFreq(obj,Y,tPerL,Nt)
            
            tPer0 = tPerL(1):obj.dtPer0:tPerL(2);                        
            F = arrayfun(@(x)(obj.optFunc(x,Y,Nt)),tPer0);
            tPerF = tPer0(argMax(F));            
            
        end                            
        
    end
    
    % static class methods
    methods (Static)
        
        % --- removes peaks that are within dtLim from other peaks
        function tPkTF = removeClosePeaks(tPkT,yPkT,dtLim)
            
            % removes any signal peaks that have close proximity to others
            for i = 1:length(tPkT)
                iClose = diff(tPkT{i}) < dtLim;
                while any(iClose)
                    % 
                    j = find(iClose,1,'last');
                    [iCl,iClose(j)] = deal(j+[0,1],false);
                    
                    % determines which of the close peaks has the
                    % higher signal peak value
                    iNw = iCl(argMax(yPkT{i}(iCl)));
                    jNw = [(1:iCl(1)-1),iNw,(iCl(end)+1:length(tPkT{i}))];                        
                        
                    % removes the peak with the lower magnitude
                    tPkT{i} = tPkT{i}(jNw);
                    yPkT{i} = yPkT{i}(jNw);
                end
            end
            
            % combines all the cell arrays into a numeric array
            tPkTF = combineNumericCells(tPkT); 
            
        end                                                
        
        % --- determines if the grid configuration is feasible (by not
        %     having more than one object per region)
        function isFeas = checkGridFeas(tPkT,yOfs,varargin)
            
            % sets the base grid locations (based on inputs)
            switch length(varargin)
                case 1
                    % case is the locations have already been calculated
                    yL = varargin{1};
                    
                case 2
                    % case is locations need to be calculated
                    [Nt,tPer] = deal(varargin{1},varargin{2});
                    yL = (0:Nt)*tPer;
            end
            
            % calculates the number of peaks within each grid region. only
            % feasible if there are less than 2 flies within each region
            N = histc(tPkT,yOfs+yL);
            isFeas = all(N(:)<2);
            
        end                                                 
        
        % --- calculates the most likely objects from the row groups
        function fPos = trackAutoMovingBlobs(IR,iGrp)

            % sets the group sub-images
            IRT = cellfun(@(x)(IR(x,:)),iGrp,'un',0);

            % retrieves the coordinates
            fPos = cell2mat(cellfun(@(x)(getMaxCoord(x)),IRT,'un',0));
            fPos(:,2) = fPos(:,2) + cellfun(@(x)(x(1)-1),iGrp);

        end           
        
        % --- determines the signal peaks from the signal, Ymx
        function [yPk0,tPk0] = calcSignalPeaks(Ymx,dPMin)
            
            try
                % attempts to run the findpeaks function
                [yPk0,tPk0] = ...
                    findpeaks(Ymx,'MinPeakDistance',dPMin);
            catch ME
                if strcmp(ME.identifier,'MATLAB:TooManyInputs')
                    % if the function failed, then re-run with no
                    % input arguments
                    [yPk0,tPk0] = findpeaks(Ymx);
                    Y = imclose(Ymx,ones(2*dPMin,1));
                    
                    % removes the
                    ii = Y(tPk0) == yPk0;
                    [yPk0,tPk0] = deal(yPk0(ii),tPk0(ii));
                    
                else
                    % otherwise, rethrow the error
                    rethrow(ME)
                end
            end
            
        end
        
        % --- calculates the abiguous object function value
        function QZs = calcObjFcn(Z,QZ,iOfs)
            
            QZs = dot(Z(iOfs+(1:length(QZ))),QZ);
            
        end        
        
        % --- sets up the weighting vector array
        function QZ = setupWeightingVector(tPer0,nTube)

            % precalculations
            Fh = tPer0/2;
            xiF0 = 1:floor(nTube*tPer0);
            
            % sets up the signal weighting array
            xiF = mod(xiF0(:)-1,tPer0) + 1;
            QZ = min(1,max(0,1 - abs((Fh - (xiF-0.5))/Fh)));

        end
        
        % --- calculates the periodity of the signal, Y
        function [Tp,Yp] = calcSignalPeriodicity(Y)
            
            % parameters
            pTol = 0.75;
            
            % calculates the periodogram of the signal
            [Pxx,f] = periodogram(Y - mean(Y(:)),hamming(length(Y)));
            if exist('iRmv','var')
                if ~isempty(iRmv)
                    Pxx(1:iRmv) = 0;
                end
            end
            
            % calculates the most likely frequency of the signal
            [~,tPk] = findpeaks(Pxx/max(Pxx),'MinPeakHeight',pTol);
            
            % rounds the value (if required)
            if isempty(tPk)
                [Tp,Yp] = deal(NaN);
            else
                Tp = 2*pi/f(tPk(1));
                Yp = Pxx(tPk(1));
            end
            
        end        
        
    end    
    
end
