classdef SingleGenRegionDetect < GenRegionDetect
    
    % class properties
    properties
        
        szL
        
        nX
        nY
        tPerX
        tPerY
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = SingleGenRegionDetect(iMov,I)
            
            % creates the super-class object
            obj@GenRegionDetect(iMov,I,false);                            
            
            %
            obj.calcOptGridConfig();            
            
            % closes the progressbar
            obj.hProg.closeProgBar();            
            
        end
        
        % -------------------------------- %
        % --- GRID DETECTION FUNCTIONS --- %
        % -------------------------------- %        
        
        % --- calculates the optimal grid configuration
        function calcOptGridConfig(obj)
            
            % calculates the optimal grid configuration
            IRmxT = obj.setupMaxResidualMask();            
            
            % calculates the initial grid configuration
            obj.estInitGridConfig(IRmxT);            
            Isub = obj.setupRegionImageStack(); 
            
            % calculates the optimal grid configuration
            pPos = obj.calcOptRegionPositions(Isub);    
            
            % sets up the final region coordinates
            obj.setupFinalRegionFields(pPos);            
            
        end
        
        % --- calculates the optimal grid configuration
        function IRmxT = setupMaxResidualMask(obj)
            
            % updates the progressbar
            if obj.hProg.Update(1,'Creating Max Residual Mask',1/5)
                % if the user cancelled, then exit
                obj.calcOK = false;
                return
            end
                        
            % sets up the sub-image stack
            IL = obj.setupSubImageStack();
            obj.szL = size(IL{1});
            
            % calculates the approximate residual 
            IR = cellfun(@(x)(obj.IbgE - x),IL,'un',0);
            IRmxT = calcImageStackFcn(IR,'max');            
            
        end        
        
        % --- estimates the initial grid configuration
        function estInitGridConfig(obj,IRmxT)

            % updates the progressbar
            if obj.hProg.Update(1,'Estimate Initial Configuration',2/5)
                % if the user cancelled, then exit
                obj.calcOK = false;
                return
            end
            
            % estimates the locations of the region centers
            [obj.tPerX,iLocX,obj.nX] = obj.estRegionLocation(IRmxT,1,obj.nCol);
            [obj.tPerY,iLocY,obj.nY] = obj.estRegionLocation(IRmxT,2,obj.nRow);
            [obj.X0,obj.Y0] = meshgrid(iLocX,iLocY);

            % memory allocation
            [obj.xOfs,obj.yOfs] = deal(NaN(size(obj.X0)));
            [obj.xOfsF,obj.yOfsF] = deal(NaN(size(obj.X0)));

        end        
        
        % --- sets up the regioh image stack
        function Isub = setupRegionImageStack(obj)
            
            % updates the progressbar
            if obj.hProg.Update(1,'Region Image Stack Setup',3/5)
                % if the user cancelled, then exit
                obj.calcOK = false;
                return
            end            
            
            % memory allocation
            [xiY,xiX] = deal(-obj.nY:obj.nY,-obj.nX:obj.nX);
            szS = [length(xiY),length(xiX)];
            Isub = repmat({NaN(szS)},size(obj.X0));
            
            % sets up the region sub-images
            for i = 1:size(Isub,1)
                % sets the row indices
                iY = obj.Y0(i,1) + xiY;
                ii = (iY > 0) & (iY <= obj.szL(1));
                obj.yOfs(i,:) = iY(1) - 1;
                
                for j = 1:size(Isub,2)
                    % sets the column indices
                    iX = obj.X0(1,j) + xiX;
                    jj = (iX > 0) & (iX <= obj.szL(2));
                    obj.xOfs(i,j) = iX(1) - 1;
                    
                    % sets the sub-image for the region
                    Isub{i,j}(ii,jj) = obj.IbgE(iY(ii),iX(jj));
                    
                    % interpolates any missing points
                    if ~all(ii) || ~all(jj)
                        isN = isnan(Isub{i,j});
                        Isub{i,j}(isN) = median(Isub{i,j}(~isN));
                    end
                end
            end
            
        end        
        
        % --- calculates the optimal region positions
        function pPos = calcOptRegionPositions(obj,Isub)
            
            % updates the progressbar
            if obj.hProg.Update(1,'Optimises Region Configuration',4/5)
                % if the user cancelled, then exit
                obj.calcOK = false;
                return
            end            
            
            % parameters
            xiStep = 2;
            nRegS = min(5,obj.nReg);
            tPer = [obj.tPerX,obj.tPerY];
            
            % index arrays
            szS = size(Isub{1});
            xiP = randperm(obj.nReg);
            xiS0 = floor(min(tPer)/2):xiStep:min(tPer);
                        
            % memory allocation
            pOfs = [obj.iC(1),obj.iR(1)] - 1;
            [IsubF,pPos] = deal(cell(size(Isub)));
            [szReg,Zmx,iPk] = deal(zeros(size(Isub)));
            
            % determines the initial optimal size/peak location
            for i = 1:nRegS
                j = xiP(i);
                [szReg(j),iPk(j),Zmx(j)] = ...
                            obj.estOptRegionSize(Isub{j},xiS0);
            end
            
            % from the initial search, reduce the search region
            szOpt = mode(szReg(xiP(1:nRegS)));
            szP = szOpt*[1,1];
            
            % continue with the optimal region search
            for i = 1:obj.nReg
                % calculates the initial peak location if not calculated
                j = xiP(i);                
                if iPk(j) == 0
                    [~,iPk(j)] = obj.estOptRegionSize(Isub{j},szOpt);
                end
                
                % retrieves peak location neighbourhood sub-image
                [yPk,xPk] = ind2sub(szS,iPk(j));
                pPosG = [(xPk+obj.xOfs(j)),(yPk+obj.yOfs(j))];
                IsubF{j} = obj.centreRegionImage(pPosG,szOpt,j);
        
                % determines the refined search location
                [~,iPk(j)] = obj.estOptRegionSize(IsubF{j},szOpt);
                
                % sets the position vector
                [yPk,xPk] = ind2sub(size(IsubF{j}),iPk(j));
                xOfsP = xPk + pOfs(1) - szOpt/2;
                yOfsP = yPk + pOfs(2) - szOpt/2;
                pPos{j} = [xOfsP+obj.xOfsF(j),yOfsP+obj.yOfsF(j),szP];
            end

        end
        
        % --- sets up the final region fields
        function setupFinalRegionFields(obj,pPos)
            
            % updates the progressbar
            if obj.hProg.Update(1,'Final Region Setup',1)
                % if the user cancelled, then exit
                obj.calcOK = false;
                return
            end            
            
            % ---------------------------------- %
            % --- REGION COLUMN CALCULATIONS --- %
            % ---------------------------------- %            
            
            % calculates the left/right locations of the regions
            xLo = cellfun(@(x)(x(1)),pPos);
            xHi = cellfun(@(x)(sum(x([1,3]))),pPos);                      
            
            if obj.nCol == 1
                % case is there is only one column
                xLim = [min(xLo),max(xHi)] + 2*[-1,1]*obj.szDel;
                
            else
                % calculates the inner region grid locations
                [xLoMx,xHiMn] = deal(max(xLo,[],1),min(xHi,[],1));
                xInner = round(0.5*(xLoMx(2:end) + xHiMn(1:end-1)));

                % determines the region column x-limits
                if obj.nCol == 2
                    % case is there are only 2 columns
                    xGap = round(median(xLoMx(end) - xInner));
                    xLim = [min(xLo(:,1))-xGap,xInner,max(xHi(:,end))+xGap];
                    
                else
                    % case is there are >2 columns                    
                    xGap = median(diff(xInner));
                    xLim = [xInner(1)-xGap,xInner,xInner(end)+xGap];
                end                
            end
            
            % ensures the regions are feasible
            xLim = min(max(1,xLim),size(obj.I{1},2));
            for i = 1:obj.nCol
                obj.iMov.iC{i} = xLim(i):xLim(i+1);
            end

            % ------------------------------- %
            % --- REGION ROW CALCULATIONS --- %
            % ------------------------------- %
            
            % calculates the left/right locations of the regions
            yLo = cellfun(@(x)(x(2)),pPos);
            yHi = cellfun(@(x)(sum(x([2,4]))),pPos);  
            
            if obj.nRow == 1
                % case is there is only one row
                yLim = [min(yLo),max(yHi)] + 2*[-1,1]*obj.szDel;
                
            else
                % case is there are multiple rows
                [yLoMx,yHiMn] = deal(max(yLo,[],2),min(yHi,[],2));                
                yGap = round(median(yLoMx(2:end) - yHiMn(1:end-1))/2);
                yLim = [min(yLo(1,:))-yGap, max(yHi(end,:))+yGap];
            end
            
            % ensures the vertical limits are feasible
            yLim = min(max(1,yLim),size(obj.I{1},1));
            obj.iMov.iR(:) = {yLim(1):yLim(2)};
            
            % sets up the inner region row/column indices
            for j = 1:obj.nCol
                % determines the row limits
                yInnerC = round((yLo(2:end,1) + yHi(1:end-1,1))/2);
                yLimC = [yLim(1);yInnerC;yLim(2)];
                
                % sets the inner column indices
                obj.iMov.iCT{j} = 1:length(obj.iMov.iC{j});
                
                % sets the indices for each row
                for i = 1:obj.nRow
                    obj.iMov.iRT{j}{i} = yLimC(i):yLimC(i+1);
                end
                
                % sets the inner region coordinates
                obj.iMov.pos{j} = ...
                    obj.setupPosVec(obj.iMov.iC{j},obj.iMov.iR{j});
                
                % sets the outer region (is this correct?)
                obj.iMov.posO{j} = obj.iMov.pos{j};
            end
            
            % sets up the automatic detection parameters
            obj.iMov.autoP = pos2para(obj.iMov,pPos);
            
        end                         
        
        % -------------------------- %
        % --- PLOTTING FUNCTIONS --- %
        % -------------------------- %
        
        % --- plots the single tracking regions
        function plotRegions(obj,pPos)
            
            % initialisations
            plotGraph('moviesel',obj.I);
            hold on            
            
            for i = 1:numel(pPos)
                % sets up the region limits
                xL = [-1,1]*pPos{i}(3)/2;
                yL = [-1,1]*pPos{i}(4)/2;
                
                % sets the region offset
                xOfsP = pPos{i}(1) + xL(2);
                yOfsP = pPos{i}(2) + yL(2);     
                
                % plots the region
                plot(xL(obj.ix)+xOfsP,yL(obj.iy)+yOfsP,'r-');
            end
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %   
        
        % --- centres the image around its global position, pPosG
        function IsubF = centreRegionImage(obj,pPosG,szOpt,indR)
            
            % initialisations
            szI = size(obj.IbgE);
            delI = floor(szOpt/2) + 2*obj.szDel;
            
            % calculates the column indices
            iCF = pPosG(1) + (-delI:delI);
            jj = (iCF > 0) & (iCF < szI(2));
            
            % calculates the row indices
            iRF = pPosG(2) + (-delI:delI);
            ii = (iRF > 0) & (iRF < szI(1));            
            
            % sets the centred sub-image
            IsubF = NaN(2*delI+1);
            IsubF(ii,jj) = obj.IbgE(iRF(ii),iCF(jj));            
            
            % sets the global x/y-coordinate offsets
            obj.xOfsF(indR) = iCF(1);
            obj.yOfsF(indR) = iRF(1);
            
        end
        
        % --- estimates the optimal region size 
        function [szOpt,iPk,Zmx] = estOptRegionSize(obj,Isub,xiS)
            
            % memory allocation
            [Imx,iPkS] = deal(zeros(length(xiS),1));
           
            for i = 1:length(xiS)
                % calculates image cross correlation
                It = obj.setupXCorrTemplate(xiS(i));
                Ixc = calcXCorr(It,Isub); 
                iMx0 = find(imregionalmax(Ixc)); 
                
                % determines the x-corr peak and max ratio values
                [Imx(i),iMxXC] = max(Ixc(iMx0)); 
                iPkS(i) = iMx0(iMxXC);
            end
            
            % returns the optimal size/position linear index
            [Zmx,iZmx] = max(Imx);
            [szOpt,iPk] = deal(xiS(iZmx),iPkS(iZmx));
            
        end                        
        
        % --- calculates the optimal region locations
        function [tPer,iLoc,nZ] = estRegionLocation(obj,IRmxT,iDim,N)
            
            % determines the column spacing (multi-column only)
            if N == 1
                tPer = size(IRmxT,3-iDim);
                iLoc = tPer/2;
            else
                [Ymx,tPer] = obj.setupResidualSignal(max(IRmxT,[],iDim));
                iLoc = obj.findSignalPeaks(Ymx,tPer,N);
            end            
        
            % sets the 
            nZ = obj.calcSubImageOffset(tPer);            
            
        end                
        
    end    
    
    % static class methods
    methods (Static)
        
        % --- sets up the residual signal
        function [YmxS,Tp] = setupResidualSignal(Y0)
            
            Tp = floor(calcSignalPeriodicity(Y0));
            Ymx = Y0(:) - imopen(Y0(:),ones(Tp,1));
            YmxS = smooth(Ymx,Tp/2);
            
        end     
        
        % --- determines the signal peaks (seperated by Tp)
        function iMx = findSignalPeaks(Y,Tp,N)
            
            % determines the signal peaks
            [yMx,iMx] = findpeaks(Y,'MinPeakDistance',floor(2*Tp/3));
            if length(yMx) > N
                % 
                xiN = 1:N;
                iOfs = 0:(length(yMx)-N);
                
                % resets the index array
                idx = argMax(arrayfun(@(x)(mean(yMx(xiN+x))),iOfs));
                iMx = iMx(xiN + (idx-1));
            end
            
        end        
        
        % --- calculates the sub-image offset
        function Np = calcSubImageOffset(Tp)
           
            if mod(Tp,2) == 0
                Np = Tp/2;
            else
                Np = (Tp-1)/2;
            end
            
        end
        
        % --- sets up the xcorr template image
        function It = setupXCorrTemplate(sz)
            
            It = padarray(ones(sz),[1,1],'both');            
            
        end
       
        % --- sets up the region position vector
        function pos = setupPosVec(iC,iR)
            
            pos = [iC(1),iR(1),diff(iC([1,end])),diff(iR([1,end]))];
            
        end
        
    end    
    
end