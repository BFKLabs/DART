classdef SingleTrackInitAuto < SingleTrackInit
    
    % class properties
    properties
        
        % auto-detection fields
        iCG
        iRG
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
        
    end
    
    % class methods
    methods        
        % class constructor
        function obj = SingleTrackInitAuto(iData)
            
            % creates the super-class object
            obj@SingleTrackInit(iData);
            
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
                IL(:,i) = obj.getRegionImgStack(Img,iFrmF,i);
                
                % calculates the 
                IbgTnw = calcImageStackFcn(IL(:,i),'max');
                [obj.IbgT{iPh}{i},obj.IbgT0{iPh}{i}] = deal(IbgTnw);

                % calculates the background estimate and residuals
                IR(:,i) = cellfun(@(x)(obj.IbgT{iPh}{i}-x),IL(:,i),'un',0);            
            end
                
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
                
                % calculates the normalised row residual signal. from this,
                % determine the number of signficant peaks from the signal
                IRmax = calcImageStackFcn(IR(:,iApp),'max');
                ImaxR0 = max(IRmax,[],2);
                ImaxR0(isnan(ImaxR0)) = 0;
                obj.ImaxR{iApp} = ImaxR0 - imopen(ImaxR0,obj.seOpen);
                
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
                                IR(:,iApp),'un',0);
                    obj.pStats.IR{iApp} = ...
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
            iMax = 10;
            szObjPr = NaN(1,2);
            nApp = size(obj.fPos0{1},1);            
            [Isub,obj.useP,obj.ImaxS] = deal(cell(nApp,1));            
            
            % keep looping until a stable solution is found
            while 1
                % retrieves the sub-images around each significant point
                for i = 1:nApp
                    % retrieves the point sub-image stack
                    Isub{i} = cell2cell(cellfun(@(x,y)(cellfun(@(z)...
                            (obj.getPointSubImage(x,z,dN)),num2cell(y,2),...
                            'un',0)),I(:,i)',obj.fPos0{1}(i,:),'un',0),0);

                    % removes any low-residual images
                    obj.useP{i} = obj.pStats.IR{i} > obj.pTolR(i);
                    Isub{i}(~obj.useP{i}) = {[]};
                end            

                % calculates the template image from the estimated image
                Itemp = calcImageStackFcn(cell2cell(Isub),'mean');          
                szObjNw = obj.calcObjShape(Itemp); 
                
                % determines if the new value has changed
                if any(cellfun(@(x)(isequal(x,szObjNw)),num2cell(szObjPr,2)))
                    % if not, then exit the loop                    
                    break
                    
                else
                    % otherwise, update the fields
                    dN = ceil(max(szObjNw));
                    szObjPr = [szObjPr;szObjNw];                    
                    
                    % increments the counter
                    i = i + 1;
                    if i > iMax
                        % exit if the count is too high
                        break
                    end
                end
            end
            
            % sets the object template field
            obj.hProg.Update(3+obj.wOfsL,'Blob Template Calculation',0.5); 
            [GxT,GyT] = imgradientxy(Itemp,'sobel'); 
            obj.tPara{1} = struct('Itemp',Itemp,'GxT',GxT,'GyT',GyT);              
            
            % sets the class object fields
            obj.iMov.szObj = szObjNw;
            
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
            pW = 0.75;
            dtOfs = 2;              
            dPMin = min(obj.iMov.szObj)/2;
            dtMin = max(ceil(pW*obj.iMov.szObj));              
            
            % initialisations and memory allocation            
            nTube = obj.nTube;
            [nImg,nApp] = size(I);
            IRL = cell(nApp,1);
            fOK = find(obj.iMov.ok(:)');

            % memory allocation
            C = NaN(nApp,nImg);
            Ymx = cell(1,nApp);
            Dt = cell(nImg,nImg,nApp);
            [tPk,yPk] = deal(cell(nApp,nImg));   
            
            % calculates the 
            dTMaxR = cellfun(@(x,y)(ceil(dtOfs+length(x)/...
                    getSRCount(obj.iMov,y))),obj.iMov.iR,num2cell(1:nApp));
            dtMax = min(dTMaxR);
            
            % --------------------------------------- %
            % --- INITIAL GRID SPACING ESTIMATION --- %
            % --------------------------------------- %
            
            % this part of the function attempts to estimate the overall
            % grid spacing over all regions
            %  NOTE: future iterations may require the function to be
            %        expanded so that each region is treated separately
            
            % updates the progessbar
            obj.hProg.Update(3+obj.wOfsL,'Signal Peak Detection',0.25); 
                            
            % calculates the signal 
            for i = fOK    
                % calculates the normalised maxima
                Ymx0 = cellfun(@(x)(max(x,[],2)),IR(:,i),'un',0);
                Ymx0 = cellfun(@(x)(obj.rmvBaseline(x)),Ymx0,'un',0);
                Ymx{i} = cellfun(@(x)(normImg(x)),Ymx0,'un',0);     

                % determines the major peaks from the image stack
                for j = 1:nImg
                    % calculates the 
                    [yPk0,tPk0] = findpeaks(Ymx0{j},'MinPeakDistance',dPMin);
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
                        Dt{k,j,i} = Dnw(~isnan(Dnw)); 
                    end
                end
            end
            
            % calculates the spacing difference between sub-regions
            Dtot = cell2mat(Dt(:)); 
            N = hist(Dtot,1:max(Dtot)); 
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
                
                % estimates the initial grid properties (spacing & offset)
                [tPer0(i),yOfs0(i)] = ...
                        obj.estGridProps(Ymx{i},tPk(i,:),yPk(i,:),i,tPerL);
                
                % sets the vertical tube locations
                obj.yTube{i} = tPer0(i)*(0:nTube(i))' + yOfs0(i);
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
            for i = find(~cellfun(@isempty,obj.yTube(:)'))
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
        function [tPerF,yOfsF] = estGridProps(obj,Y,tPkT,yPkT,iApp,tPerL)
            
            % parameters
            dtPer0 = 0.1;            
            Nt = getSRCount(obj.iMov,iApp);
            tPer0 = tPerL(1):dtPer0:tPerL(2);
            
            % determines the most likely grid spacing size
            F = arrayfun(@(x)(obj.optFunc(x,Y,Nt)),tPer0);
            tPerF = tPer0(argMax(F));
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
            while 1
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
            tPkTF = tPkTF(~isnan(tPkTF));
            nTot = arrayfun(@(x)(sum(histc(tPkTF,x+yL([1,end])))),xiPF); 
            
            % calculates the object functions values for each offset value
            Z = arrayfun(@(x)(min(arr2vec(pdist2(tPkTF,x+yL(:))))),xiPF);            
            QZ = Z.*(nTot>(max(nTot)-Nt/2));            
            
            % returns the optimal grid offset
            if length(QZ) >= 3
                QZn = QZ/max(QZ);
                [~,tPk] = findpeaks(QZn,'MinPeakHeight',0.9);
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
            Bopt0 = obj.Iopt/max(obj.Iopt(:));
            Bopt = bwmorph(Bopt0 > obj.pTolShape,'majority');
            [~,objBB] = getGroupIndex(Bopt,'BoundingBox');            
            szObj = objBB([3,4]);
            
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
        
    end    
    
end