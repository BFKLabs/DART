classdef DetectCircle < handle
    
    % class properties
    properties
        
        % main class fields
        I
        iMov
        
        % calculated property class fields
        R
        X
        Y
        Rmin
        Rmax
        
        % temporary class fields
        Imd
        hProg
        
        % boolean class fields
        calcOK = true;        
        
        % detection algorithm parameters
        pR = 1.95;        
        pLo = 0.10;
        mTol = 0.25;
        pdR = [0.75,1];
        dsTol = 0.0025;
        pTolZ = 0.05;
        iterMx = 10;        
        
        % older detection algorithm parameters
        dR = 5;
        hQ = 0.25;
        rDelMin = 1;
        rDelMax = 5;
        
        % static string class fields
        Type = {'dark','bright'};
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = DetectCircle(I0,iMov)
        
            % sets the input arguments
            obj.iMov = iMov;
            
            % initialises the class fields
            obj.initClassFields(I0);
            
            % runs the circle detection algorithm
            obj.detCircleRegions();
            if ~obj.calcOK
                % if this failed, then try the older algorithm
                obj.detCircleRegionsOld();
            end
            
        end

        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj,I0)
            
            % parameters
            szMu = 10:2:20;
            kT = linspace(0.01,0.1,length(szMu));
            
            % sets up the region estimate image
            Iest = double(calcImageStackFcn(I0,'min'));
            obj.Imd = double(calcImageStackFcn(I0,'median'));
%             obj.I = setupRegionEstimateImage(obj.iMov,I0);           
            
            % sets the image estimate
            obj.I = zeros(size(Iest));            
            for i = szMu
                for j = kT
                    obj.I = obj.I + sauvolaThresh(Iest,i,j);
                end
            end                                      
            
            % creates the waitbar figure
            wStr = 'Reading Estimation Image Stack';
            tStr = 'Automatic Region Detection';
            obj.hProg = ProgBar(wStr,tStr);
            
        end
        
        % ---------------------------------- %
        % --- CIRCLE DETECTION FUNCTIONS --- %
        % ---------------------------------- %
        
        % --- runs the circle region detection algorithm
        function detCircleRegions(obj)
            
            % field retrieval
            szI = size(obj.I);
            
            % sets the global column indices
            iCG = floor(obj.iMov.posG(1)):ceil(sum(obj.iMov.posG([1,3])));
            iCG = iCG((iCG > 0) & (iCG <= szI(2)));            
            
            % sets the global row indices
            iRG = floor(obj.iMov.posG(2)):ceil(sum(obj.iMov.posG([2,4])));
            iRG = iRG((iRG > 0) & (iRG <= szI(1)));
            
            % sets the row count (based on sub-region data struct format)
            if isfield(obj.iMov,'pInfo')
                % case is using the new format
                nRow = size(obj.iMov.pInfo.iGrp,1);
            else
                % case is using the old format
                nRow = sum(max(obj.iMov.nTubeR,[],2));
            end

            % ------------------------------- %            
            % --- CIRCLE REGION DETECTION --- %
            % ------------------------------- %
            
            % other initialisations
            pOfs = [iCG(1),iRG(1)] - 1;
            [IG,ImdG] = deal(obj.I(iRG,iCG),obj.Imd(iRG,iCG));
            [szR,szG] = deal([nRow,obj.iMov.nCol],size(IG));            
            
            % calculates an estimate of the radii range 
            Rest = ceil(min([szG(1)/obj.iMov.pInfo.nRow,...
                             szG(2)/obj.iMov.pInfo.nCol])/2);
            
            try
                % determines the regions over the columns/rows
                R0s = roundP(Rest.*obj.pdR);
                [X0,Y0,R0] = obj.detInitCircleCentres(IG,ImdG,R0s,szR);
                obj.Rmax = obj.calcMaxRadii(X0,Y0); 
                
                % sets the final x/y centre coordinates and the maximum radii
                obj.R = min(obj.Rmax,max(R0(:),[],'omitnan')-1);
                [obj.X,obj.Y] = deal(X0+pOfs(1),Y0+pOfs(2));
                
                % sets the lower/upper tolerances on the radii
                obj.Rmin = floor(obj.R*(1 - obj.pLo));
                
                % updates and closes the waitbar figure
                if ~obj.hProg.Update(1,'Automatic Dectection Complete!',1)
                    obj.hProg.closeProgBar()
                end
                
            catch
                % if there was an error, then update the error flag
                obj.calcOK = false;
                
                % updates the progressbar
                obj.hProg.Update(1,'Automatic Dectection Failed!',1); 
                pause(0.05);                
            end
                         
        end
        
        % --- determines the initial estimate of the circle centres
        function [xC,yC,RC] = detInitCircleCentres(obj,IG,ImdG,R0s,szR)
        
            % updates the progressbar
            wStr = 'Determining Initial Circle Centre Estimate';
            obj.hProg.Update(1,wStr,0.25);      
            
            % memory allocation
            sz = size(ImdG);
            NC = prod(szR);
            nCircTol = 2*prod(szR);
            [pC0,R0,M0] = deal(cell(length(obj.Type),1));
            
            % -------------------------------- %
            % --- INITIAL CIRCLE DETECTION --- %
            % -------------------------------- %  
            
            % parameters
            sTol = 0.9975;            
            
            %%% FIND BETTER IMAGE FOR I(TMP) 
            
            % calculates the normalised image and mean/std dev
            Itmp = 255*normImg(applyHMFilter(ImdG));
            Imn = mean(Itmp(:),'omitnan');
            Isd = std(Itmp(:),[],'omitnan');
            
            % removes any outlier regions
            ZI = normcdf(Itmp,Imn,Isd);
            BZ = (ZI >= obj.pTolZ) & (ZI <= (1 - obj.pTolZ));
            Itmp(~BZ) = median(Itmp(BZ),'omitnan');
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % calculate circle regions each object polarity type
            for i = 1:length(obj.Type)
                % initialisations
                j = 1;
                
                % keep looping until either A) number of circles detected 
                % is within tolerance, or B) iteration count is exceeded
                while 1
                    % runs the circle finding function
                    [pC0{i},R0{i},M0{i}] = imfindcircles(IG,R0s,...
                        'Method','TwoStage','Sensitivity',sTol,...
                        'ObjectPolarity',obj.Type{i});
                    
                    % determines if the circle count is within tolerance
                    if length(R0{i}) > nCircTol
                        % case is there are too many circles
                        sTol = sTol - obj.dsTol;

                    elseif length(R0{i}) < nCircTol
                        % case is there are too few circles
                        sTol = sTol + obj.dsTol;
                    else
                        % if within tolerance, then exit the loop
                        break
                    end
                    
                    % increments the iteration counter
                    j = j + 1;
                    if j > obj.iterMx
                        % if the iteration counter exceed tolerance, then
                        % exit the inner loop
                        break
                    end
                end
            end
            
            % determines type which produces the better results
            xiC = 1:NC;
            Mmn = mean(cell2mat(cellfun(@(x)(x(xiC)),M0','un',0)),1);
            Rvar = 1./var(cell2mat(cellfun(@(x)(x(xiC)),R0','un',0)),[],1);
            imx = argMax(Mmn.*Rvar);
            
            % determines the most likely circle centres
            ii = (M0{imx}/M0{imx}(1) > obj.mTol);
            ii = ii & setGroup(1:min(NC,sum(ii)),size(M0{imx}));  
            
            % strips out the best x/y circle centres and radii
            [xC0,yC0,R0] = deal(pC0{imx}(ii,1),pC0{imx}(ii,2),R0{imx}(ii));
            Rmax0 = max(R0);
            
            % ----------------------------- %
            % --- FINE CIRCLE DETECTION --- %
            % ----------------------------- %
            
            % initialisations
            II = {Itmp,IG};
            Ixc = cell(length(II),1);
            
            % sets up the xcorr template image
            for i = 1:length(II)
                % calculates the median sub-image
                Isub = obj.setupSubImageStack(...
                    II{i},roundP(xC0),roundP(yC0),Rmax0);
                IsubMn = calcImageStackFcn(Isub(:),'median');
                
                % calculate the cross-correlation image (from the template)
                Iex = padarray(II{i},Rmax0*[1,1],'replicate','both');
                IxcT = max(0,normxcorr2(IsubMn,Iex));
                Ixc{i} = IxcT(2*Rmax0+(1:sz(1)),2*Rmax0+(1:sz(2)));
            end
            
            % sets edge binary mask (remove points from within this region)
            nDil = max(3,floor(Rmax0/4));
            Bedge = bwmorph(bwmorph(true(sz),'remove'),'dilate',nDil);
            
            % determines regional maxima from lowest entropy xcorr image
            imn = argMin(cellfun(@entropy,Ixc));
            iMx0 = find(imregionalmax(Ixc{imn}) & ~Bedge);
            [yMx0,xMx0] = ind2sub(sz,iMx0);
            
            % sorts the xcorr maxima points in descending order
            [~,iS] = sort(Ixc{imn}(iMx0),'descend');
            [xMx0,yMx0,iMx0,RC] = deal(xMx0(iS),yMx0(iS),iMx0(iS),Rmax0);
            
            % ------------------------ %
            % --- FINAL GRID SETUP --- %
            % ------------------------ %
            
            % memory allocation
            [xC,yC] = deal(NaN(szR));
            
            % calculates the distance between all maxima points
            D = pdist2([xMx0,yMx0],[xMx0,yMx0]);
            
            % fills any gaps within the 
            for i = 1:size(D,2)
                if ~isnan(all(D(:,i)))
                    ii = find(D(:,i) < obj.pR*RC);
                    iMx = argMax(Ixc{imn}(iMx0(ii)));                    
                    jj = ii(~setGroup(iMx,size(ii)));
                    [D(jj,:),D(:,jj)] = deal(NaN);
                end
            end
            
            % resets the optimal x/y maxima coordinates
            k = ~isnan(D(:,1));
            [xMx,yMx] = deal(xMx0(k),yMx0(k));
            
            % sorts the maxima points by the y-location
            [yMx,iS] = sort(yMx);
            xMx = xMx(iS);
            
            % splits the y-location by the maximum radii
            ii = find(diff([yMx;(yMx(end)+2*Rmax0)]) > Rmax0);
            xiC = num2cell([[1;(ii(1:end-1)+1)],ii],2);
            indC = cellfun(@(x)(x(1):x(2)),xiC,'un',0);
            
            % if there are more rows than required, then reduce them down
            if length(indC) > szR(1)
                % determines which configuration closest matches required
                nC = cellfun('length',indC);
                xi = 0:(length(indC)-szR(1));
                nCSum = arrayfun(@(x)(sum(nC(x+(1:szR(1))))),xi);
                
                % reduces down the regions to remove extraneous points
                indC = indC(xi(argMin(abs(nCSum-prod(szR))))+(1:szR(1)));
            end
            
            % sets the final grid locations
            for i = 1:szR(1)
                % if more points than required, then reduce grouping
                if length(indC{i}) > szR(2)
                    % retrives the x/y coordinates of the maxima
                    [XX,YY] = deal(xMx(indC{i}),yMx(indC{i}));
                    
                    % removes any potentially infeasible points
                    ii = (XX > RC) & (XX < sz(2)) & ...
                         (YY > RC) & (YY < sz(1));
                    if sum(ii) == szR(2)
                        % reduce the indices if now feasible
                        indC{i} = indC{i}(ii);
                    else
                        % otherwise, determine points closest to the median
                        [~,ii] = sort(abs(YY-median(YY)));
                        indC{i} = indC{i}(ii(1:szR(2)));
                    end
                end
                
                % sets the x/y grid coordinates
                [xC(i,:),jS] = sort(xMx(indC{i}));
                yC(i,:) = yMx(indC{i}(jS));
            end
            
        end
            
        % -------------------------------------- %
        % --- OLD CIRCLE DETECTION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- runs the circle region detection algorithm
        function detCircleRegionsOld(obj)
            
            % field retrieval and initialisations
            nTubeMx = getSRCountMax(obj.iMov);
            nRowT = nTubeMx*obj.iMov.nRow;            
            [obj.Rmin,obj.calcOK] = deal(10,true);
            
            % memory allocation
            [xOfsG0,yOfsG0] = deal(0);            
            [obj.X,obj.Y] = deal(zeros(nRowT,obj.iMov.nCol));            
            [nApp,obj.R] = deal(obj.iMov.nRow*obj.iMov.nCol,NaN);
            
            % sets the optimisation option struct
            opt = optimset('display','none','tolX',1e-4);            
            
            % creates the waitbar figure
            wStr = 'Determining Initial Circle Radius Estimate';            
            wStr2 = 'Fine Circle Parameter Optimisation';
            
            % updates the progressbar
            obj.hProg.Update(1,wStr,0);            
            pause(0.05)
            
            % --------------------------------- %
            % --- INITIAL RADIUS ESTIMATION --- %
            % --------------------------------- %
            
            % sets the histogram equalised image
            Ieq = adapthisteq(uint8(obj.I));
            
            % calculates the x/y gradient of image 
            [Gx,Gy] = imgradientxy(Ieq,'prewitt');
            IR = (abs(Gy) + abs(Gx));
            
            % estimates upper bound on circle radius (which is the maximum 
            % of the rows/columns for each of the individual arenas)
            nC = cellfun('length',obj.iMov.iCT);
            nR = combineNumericCells(...
                cellfun(@(x)(cellfun('length',x)),obj.iMov.iRT,'un',0));
            Rnw = ceil(min(max(nC(:)),max(nR(:)))/2);
            
            % calculates the x-correlation of the image with the template
            [obj.Rmax,cCount,cCountMx,fCount] = deal(0,0,10,0);
            while true
                % retrieves the new circle template and calculates the 2D 
                % normalised cross-correlation with the image
                IT = getCircleTemplate(Rnw);
                IXnw = normxcorr2(IT,IR);
                RmaxNw = max(IXnw(:));
                
                % determines the maximum of the cross-correlation
                if RmaxNw > obj.Rmax
                    % if new value is better, then update & decrease radius
                    [IX,R0,obj.Rmax] = deal(IXnw,Rnw,RmaxNw);
                    [cCount,fCount] = deal(0,fCount+1);
                    
                else
                    % if not, then increment the counter
                    cCount = cCount + 1;
                    if cCount == cCountMx
                        % if iteration exceeds the max, then exit loop
                        break
                    end
                end
                
                % decrements the radius
                Rnw = Rnw-1;
                if Rnw < obj.Rmin
                    fCount = NaN; 
                    break
                end
            end
            
            % reduces image to original size and sets the search template
            szI = size(obj.I);
            IX = IX((1:szI(1))+R0,(1:szI(2))+R0);
            IT = getCircleTemplate(R0);
            
            % ---------------------------------------- %
            % --- ARENA CENTRE LOCATION ESTIMATION --- %
            % ---------------------------------------- %
            
            % loops through all regions determining the centers/radii
            for i = 1:nApp
                % updates the waitbar figure
                wStrNw = sprintf('%s (Region %i of %i)',wStr2,i,nApp);
                if obj.hProg.Update(1,wStrNw,0.5*(1+i/nApp))
                    % if the user cancelled, then exit the loop
                    obj.calcOK = false; 
                    return
                end
                
                % index calculations
                iRow = floor((i-1)/obj.iMov.nCol) + 1;
                iCol = mod(i-1,obj.iMov.nCol) + 1;
                
                % sets the sub-images
                iR = obj.iMov.iR{i} - yOfsG0;
                iC = obj.iMov.iC{i} - xOfsG0;
                [IXsub,xOfsG,yOfsG] = deal(IX(iR,iC),iC(1)-1,iR(1)-1);
                
                % loops through each of the arenas calculating the parameters
                for j = 1:getSRCount(obj.iMov,i)
                    % retrieves the sub-image for the current arena
                    iR0 = obj.iMov.iRT{i}{j};
                    iTube = (iRow-1)*nTubeMx + j;
                    [IXsNw,yOfsL] = deal(IXsub(iR0,:),iR0(1)-1);
                    
                    % calculates the distance weighting mask
                    [Xs,Ys] = meshgrid(1:size(IXsNw,1),1:size(IXsNw,2));
                    Q = 1./(sqrt((Xs-size(IXsNw,2)/2).^2 + ...
                                 (Ys-size(IXsNw,1)/2).^2) + 1);
                    
                    % calculates max point location from the x-corr image
                    [~,imx] = max(IXsNw(:).*(normImg(Q(:)).^obj.hQ));
                    [ymx0,xmx0] = ind2sub(size(IXsNw),imx);
                    
                    % sets the local row/column indices
                    dRMin = R0 + 2*obj.rDelMin; 
                    [Xg,Yg] = deal(xmx0+xOfsG,ymx0+(yOfsG+yOfsL));
                    iRs = max(1,Yg - dRMin):min(szI(1),Yg + dRMin);
                    iCs = max(1,Xg - dRMin):min(szI(2),Xg + dRMin);
                    
                    % runs the optimisation function
                    dZ = fminsearch(@obj.optFunc,[0 0],opt,IT,IR(iRs,iCs));
                    obj.X(iTube,iCol) = Xg - dZ(1) + xOfsG0;
                    obj.Y(iTube,iCol) = Yg - dZ(2) + yOfsG0;
                end
            end
            
            % ---------------------------------------- %
            % --- CENTRE LOCATION DIAGNOSTIC CHECK --- %
            % ---------------------------------------- %
            
            % check to see if the is any overlap of the circles. if so, then the
            % regions will need to be optimised further
            if numel(obj.X) > 1
                % determines if any of the circles overlap
                [dX,dY] = deal(diff(obj.X,[],2),diff(obj.Y,[],1));
                if isempty(dX)
                    % only need to check vertically if overlap
                    dMin = min(dY(:));
                    
                elseif isempty(dY)
                    % only need to check horizontally if overlap
                    dMin = min(dX(:));
                    
                else
                    % otherwise, check both directions for overlap
                    dMin = min(min(dX(:)),min(dY(:)));
                end
                
                % determines if there is any overlap
                cont = dMin < 2*(R0 + obj.rDelMin);
                if ~cont
                    Dmx = dMin/2 - (R0 + obj.rDelMin); 
                end
            else
                % no need to check the alignment for a single region
                [cont,Dmx] = deal(false,obj.rDelMax);
            end
            
            % checks the values to see if they are correct
            while cont
                % memory allocation
                [Yc,Xc] = deal(zeros(size(obj.Y)));
                pXY = cell(size(obj.X,1),1);
                pYX = cell(size(obj.X,2),1);
                
                % fits the x/y linear relationship
                for i = 1:size(Xc,1)
                    if size(Xc,2) > 1
                        % calculates the polynomial fits
                        pXY{i} = polyfit(obj.X(i,:),obj.Y(i,:),1);
                        Yc(i,:) = polyval(pXY{i},obj.X(i,:));
                    else
                        % otherwise, set the coordinate manually
                        pXY{i} = [1,(obj.Y(i,:)-obj.X(i,:))];
                        Yc(i,:) = obj.Y(i,:);
                    end
                end
                
                % fits the y/x linear relationship
                for i = 1:size(Xc,2)
                    if size(Xc,1) > 1
                        % calculates the polynomial fits and
                        pYX{i} = polyfit(obj.Y(:,i),obj.X(:,i),1);
                        Xc(:,i) = polyval(pYX{i},obj.Y(:,i));
                    else
                        pYX{i} = [1,(obj.X(:,i)-obj.Y(:,i))];
                        Xc(:,i) = obj.X(:,i);
                    end
                end
                
                % calculates errors in the points from the fitted values
                D = sqrt((Yc - obj.Y).^2 + (Xc - obj.X).^2);
                [Dmx,imx] = max(D(:));
                
                % if the maximum is greater than tolerance, then re-fit 
                % the anomalous value to the others
                if Dmx > sqrt(2)
                    % sets up the simulataneous equations and solves them
                    [ymx,xmx] = ind2sub(size(Yc),imx);
                    Z = [[-pXY{ymx}(1),1];...
                         [1,-pYX{xmx}(1)]]\[pXY{ymx}(2);pYX{xmx}(2)];
                    
                    % sets the new values
                    obj.X(ymx,xmx) = roundP(Z(1));
                    obj.Y(ymx,xmx) = roundP(Z(2));
                else
                    % otherwise, exit the loop
                    cont = false;
                end
            end
            
            % sets the final radius
            obj.Rmax = R0 + floor(min(obj.rDelMax,max(obj.rDelMin,Dmx)));
            obj.R = min(obj.Rmax,R0 + obj.dR);
            
            % closes the waitbar figure (and remove the resegmentation 
            % frames from the sub-image data struct)
            if ~obj.hProg.Update(1,'Automatic Dectection Complete!',1)
                obj.hProg.closeProgBar()
            end
            
            % if there was no better solution found from the initial radius 
            % search then output a warning to screen
            if isnan(fCount)
                eStr = sprintf(['Warning! You may have set the outer ',...
                    'region to be too small. This could reduce the ',...
                    'accuracy of the region placement algorithm.\n\n',...
                    'You may need to reset the outer region and ',...
                    're-run the circle detection.']);
                waitfor(warndlg(eStr,'Circle Detection Warning','modal'));
            end
            
        end                        
        
    end
    
    % static class methods
    methods (Static)
        
        % -------------------------------------- %
        % --- NEW CIRCLE DETECTION FUNCTIONS --- %
        % -------------------------------------- %        
        
        % --- calculates the maximum possible radii between circles
        function RadMx = calcMaxRadii(xC,yC)
            
            % calculates the maximum radii such that the
            P = [xC(:),yC(:)];
            Dc = pdist2(P,P);
            Dc(logical(eye(size(Dc)))) = NaN;
            RadMx = ceil(min(Dc(:),[],'omitnan')/2);
            
        end
        
        % --- setup cross-correlation sub-image
        function Isub = setupSubImageStack(IG,xC,yC,R)
            
            % initalisations
            sz = size(IG);
            nImg = numel(xC);
            xiS = -R:R;
            Isub = repmat({NaN(2*R+1)},size(xC));
            
            % sets the sub-images over the image stack
            for i = 1:nImg
                % sets row/column indices surrounding xC/yC
                [iR,iC] = deal(yC(i)+xiS,xC(i)+xiS);
                ii = (iR >= 1) & (iR <= sz(1));
                jj = (iC >= 1) & (iC <= sz(2));
                
                % sets the sub-image
                Isub{i}(ii,jj) = IG(iR(ii),iC(jj));
            end
            
        end
       
        % -------------------------------------- %
        % --- OLD CIRCLE DETECTION FUNCTIONS --- %
        % -------------------------------------- %        
        
        % --- objective function for optimising the centre of the circles
        function F = optFunc(z,IT,IR)
            
            % calculates the maximum residual
            if any(abs(z) > 1)
                % shift is infeasible
                F = 1e10;
            else
                % shifts local residual image and takes the x-correlation
                IT = conv2(IT,[z(2); 1-z(2)]*[z(1), 1-z(1)],'same');
                IXnw = normxcorr2(IT,IR);
                
                % calculates shifted image and calculates the mean shift
                F = -max(IXnw(:));
            end
            
        end
        
    end
    
end