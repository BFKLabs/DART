% --- determines an estimate of the circle centres/radii from the 2D
%     cross-correlation of the candidate image with a circle template
function [iMov,R,X,Y,ok] = detImageCircles(Istack,iMov,hQ)

% creates the waitbar figure
h = ProgBar('Reading Estimation Image Stack','Automatic Region Detection'); 
pause(0.05)

% sets up the region estimate image
I = setupRegionEstimateImage(iMov,Istack);

% if the number of circles is high, then use the new detection algo
[iMov,R,X,Y,ok] = detImageCirclesNew(I,iMov,h);

% if it failed, then try the old algorithm
if ~ok
    [iMov,R,X,Y,ok] = detImageCirclesPrev(I,iMov,hQ);    
end
    
%-------------------------------------------------------------------------%
%                    NEW DETECTION ALGORITHM FUNCTIONS                    %
%-------------------------------------------------------------------------%

% --- determines an estimate of the circle centres/radii from the 2D
%     cross-correlation of the candidate image with a circle template
function [iMov,R,X,Y,ok] = detImageCirclesNew(I,iMov,h)

% global variables
global RnwTol Rmax 

% sets the global image
ok = true;
iCG = floor(iMov.posG(1)):ceil(sum(iMov.posG([1,3])));
iRG = floor(iMov.posG(2)):ceil(sum(iMov.posG([2,4])));

% removes any infeasible row/column indices
iCG = iCG((iCG > 0) & (iCG <= size(I,2)));
iRG = iRG((iRG > 0) & (iRG <= size(I,1)));

% retrieves the estimate of the initial estimate of the radius
if ~isfield(iMov,'autoP')
    R0 = ceil(cellfun(@length,iMov.iCT)/2);
    
elseif isempty(iMov.autoP)
    R0 = ceil(cellfun(@length,iMov.iCT)/2);
    
else
    Bw = getExclusionBin(iMov,[],1,1);
    [~,A,P] = getGroupIndex(Bw,'Area','Perimeter');
    R0 = ceil(2*A/P);    
end

% sets the row count (based on the sub-region data struct format)
if isfield(iMov,'pInfo')
    % case is using the new format
    nRow = size(iMov.pInfo.iGrp,1);
else
    % case is using the old format
    nRow = sum(max(iMov.nTubeR,[],2));
end

% initialisations
[pdR,dim] = deal([0.80,1.20],[iMov.nCol,nRow]);
[IG,pOfs] = deal(I(iRG,iCG),[iCG(1),iRG(1)]-1);

% calculates the region periodicity estimate
tPer0 = calcRegionPeriodicityEst(IG,dim);
if isnan(tPer0)
    % if there was an error, then set empty output variables
    [R,X,Y,ok] = deal([],[],[],false);
    
    % updates and closes the waitbar
    h.Update(1,'Automatic Dectection Failed!',1); pause(0.05);
    h.closeProgBar()    
    return
end

try           
    % determines the regions over the columns/rows    
    [X0,Y0,R0] = detInitCircleCentres(IG,roundP(max(R0).*pdR),tPer0,dim,h);
    Rmax = calcMaxRadii(X0,Y0);
    
    % sets the final x/y centre coordinates and the maximum radii
    R = min(Rmax,nanmax(R0(:))-1);
    [X,Y] = deal(X0+pOfs(1),Y0+pOfs(2));
    
    % sets the lower/upper tolerances on the radii    
    pLo = 0.10;
    RnwTol = floor(R*(1-pLo));   

    % closes the waitbar figure (and remove the resegmentation frames from 
    % the sub-image data struct)
    if ~h.Update(1,'Automatic Dectection Complete!',1)  
        h.closeProgBar()
    end
    
catch ME
    % sets a false flag
    [R,X,Y,ok] = deal([],[],[],false);
    
    % updates and closes the waitbar
    h.Update(1,'Automatic Dectection Failed!',1); pause(0.05);
    h.closeProgBar()
end

% --- calculates the estimated region periodicity
function tPer0 = calcRegionPeriodicityEst(IG,nDim)

% memory allocation
Z = cell(2,1);

% retrieves the sub-region stack estimate
[IRG,ICG] = getSubRegionStackEst(IG);

%
if nDim(1) > 1
    % sets up the negative/positive mean signals
    ZR0 = sum(cell2mat(IRG(:)));
    Z{1} = smooth(max(0,-ZR0));
    Z{2} = smooth(max(0,ZR0));    
else
    % sets up the negative/positive mean signals
    ZC0 = sum(cell2mat(ICG(:)));
    Z{1} = smooth(max(0,-ZC0));
    Z{2} = smooth(max(0,ZC0));        
end

% calculates the coefficient of variances (removes an infeasible)
zCOV = cellfun(@calcCOV,Z);
if all(isnan(zCOV))
    tPer0 = NaN;
else
    tPer0 = calcSignalPeriodicity(Z{argMin(zCOV)});
end

% --- calculates the parameters for the missing circles
function [ok,indG,R,pC] = ...
                detMissingCirclePara(iMov,IG,iGrpE,indG,pC,R,tPer0,TypeMx)

% initialisations
rTol = [min(R),max(R)];
[ok,Rmax,sz] = deal(true,rTol(2)+1,size(IG));

% determines the regions which are missing
[iFly,iApp] = find(iGrpE);

%
for i = 1:length(iFly)
    if (iMov.nCol == 1)
        % if there is only one column, then search down the rows
        [ii,xiI] = deal(indG(:,iApp(i)),true,iFly(i));
    else
        % otherwise, search across the columns for the missing region
        if (i == 1); indRow = repmat(1:iMov.nCol,iMov.nRow,1); end
        
        iRow = floor((iApp(i)-1)/iMov.nCol) + 1;
        ii = indG(iFly(i),indRow(iRow,:));
        xiI = mod(iApp(i)-1,iMov.nCol) + 1;
    end
    
    % calculates the estimated location of the missing circle center
    xi = find(~cellfun(@isempty,ii(:)));
    pCxi = pC(cell2mat(ii(xi)),:);
    pCtmp = calcMissingCircleCenter(pCxi,xi,xiI);
    
    % retrieves the sub-image surrounding the estimated location point
    iR = max(1,pCtmp(2)-Rmax):min(sz(1),pCtmp(2)+Rmax);
    iC = max(1,pCtmp(1)-Rmax):min(sz(2),pCtmp(1)+Rmax);
    IGL = imadjust(uint8(IG(iR,iC)),stretchlim(uint8(IG(iR,iC))),[]);
    
    % fits the circle parameters and updates the arrays
    [pCL,R(end+1)] = optCircleDetectPara(IGL,rTol,tPer0,TypeMx);
    pC(end+1,:) = [pCL(1)+(iC(1)-1),pCL(2)+(iR(1)+1)];    
    indG{iFly(i),iApp(i)} = length(R);
end

% --- calculates the location of the missing circle center
function pCtmp = calcMissingCircleCenter(pC,xi,xiI)

% calculates the x/y locations of the missing circle center
F0x = fit(xi,pC(:,1),'poly1');
F0y = fit(xi,pC(:,2),'poly1');

% calculates the estimated location point
pCtmp = roundP([F0x.p1*xiI + F0x.p2,F0y.p1*xiI + F0y.p2]);

%-------------------------------------------------------------------------%
%                    OLD DETECTION ALGORITHM FUNCTIONS                    %
%-------------------------------------------------------------------------%

% --- determines an estimate of the circle centres/radii from the 2D
%     cross-correlation of the candidate image with a circle template
function [iMov,R,X,Y,ok] = detImageCirclesPrev(I,iMov,hQ)

% global variables
global RnwTol Rmax 

% parameters and memory allocation
nTubeMx = getSRCountMax(iMov);
[RnwTol,rDelMin,rDelMax,ok] = deal(10,1,5,true);
[nApp,R,dR] = deal(iMov.nRow*iMov.nCol,NaN,5);
[X,Y] = deal(zeros(nTubeMx*iMov.nRow,iMov.nCol));

% sets the optimisation option struct
opt = optimset('display','none','tolX',1e-4);

% initialisations
[xOfsG0,yOfsG0] = deal(0);

% creates the waitbar figure
wStr = {'Determining Initial Circle Radius Estimate'};
wStr2 = 'Fine Circle Parameter Optimisation';
h = ProgBar(wStr,'Automatic Region Detection'); pause(0.05)

% --------------------------------- %
% --- INITIAL RADIUS ESTIMATION --- %
% --------------------------------- %

% sets the histogram equalised image
Ieq = adapthisteq(uint8(I));

% calculates the x/y gradient of the image and combines into a single image
[Gx,Gy] = imgradientxy(Ieq,'prewitt'); 
IR = (abs(Gy) + abs(Gx)); 

% estimates the upper bound on the circle radius (which is the maximum of
% the rows/columns for each of the individual arenas)
nC = cellfun(@length,iMov.iCT);
nR = combineNumericCells(cellfun(@(x)(cellfun(@length,x)),iMov.iRT,'un',0));
Rnw = ceil(min(max(nC(:)),max(nR(:)))/2);                    

% calculates the cross-correlation of the image with the template
[Rmax,cCount,cCountMx,fCount] = deal(0,0,10,0);
while true        
    % retrieves the new circle template and calculates the 2D normalised
    % cross-correlation with the image    
    IT = getCircleTemplate(Rnw);
    IXnw = normxcorr2(IT,IR);         
    RmaxNw = max(IXnw(:));

    % determines the maximum of the cross-correlation    
    if (RmaxNw > Rmax)
        % if the new value is better, then update and decrease the radius
        [IX,R0,Rmax,cCount,fCount] = deal(IXnw,Rnw,RmaxNw,0,fCount+1);
    else
        % if not, then maximum is found so exit the loop
        cCount = cCount+1;
        if (cCount == cCountMx)
            break
        end
    end
    
    % decrements the radius
    Rnw = Rnw-1;
    if (Rnw < RnwTol)
        fCount = NaN; break
    end
end
    
% reduces the image to the original size and sets the search template
[IX,IT] = deal(IX((1:size(I,1))+R0,(1:size(I,2))+R0),getCircleTemplate(R0));

% ---------------------------------------- %
% --- ARENA CENTRE LOCATION ESTIMATION --- %
% ---------------------------------------- %

% loops through all of the apparati determining the centers/radii
for i = 1:nApp
    % updates the waitbar figure
    wStrNw = sprintf('%s (Region %i of %i)',wStr2,i,nApp);
    if h.Update(1,wStrNw,0.5*(1+i/nApp))
        % if the user cancelled, then exit the loop
        ok = false; return
    end
    
    % index calculations
    [iRow,iCol] = deal(floor((i-1)/iMov.nCol)+1,mod(i-1,iMov.nCol)+1);
        
    % sets the sub-images
    [iR,iC] = deal(iMov.iR{i}-yOfsG0,iMov.iC{i}-xOfsG0);
    [IXsub,xOfsG,yOfsG] = deal(IX(iR,iC),iC(1)-1,iR(1)-1);
    
    % loops through each of the arenas calculating the parameters
    for j = 1:getSRCount(iMov,i)
        % retrieves the sub-image for the current arena
        [iR0,iTube] = deal(iMov.iRT{i}{j},(iRow-1)*nTubeMx+j);
        [IXsNw,yOfsL] = deal(IXsub(iR0,:),iR0(1)-1);
        
        % calculates the distance weighting mask
        [Xs,Ys] = meshgrid(1:size(IXsNw,1),1:size(IXsNw,2));
        Q = 1./(sqrt((Xs-size(IXsNw,2)/2).^2 + (Ys-size(IXsNw,1)/2).^2)+1);
        
        % calculates the location of the max point from the x-corr image
        [~,imx] = max(IXsNw(:).*(normImg(Q(:)).^hQ)); 
        [ymx0,xmx0] = ind2sub(size(IXsNw),imx);
        
        [Xg,Yg] = deal(xmx0+xOfsG,ymx0+(yOfsG+yOfsL));
        iRs = max(1,Yg-(R0+2*rDelMin)):min(size(I,1),Yg+(R0+2*rDelMin));
        iCs = max(1,Xg-(R0+2*rDelMin)):min(size(I,2),Xg+(R0+2*rDelMin));
                
        % runs the optimisation function        
        dZ = fminsearch(@optFunc,[0 0],opt,IT,IR(iRs,iCs));
        [X(iTube,iCol),Y(iTube,iCol)] = deal(Xg-dZ(1)+xOfsG0,Yg-dZ(2)+yOfsG0);                        
    end
end

% ---------------------------------------- %
% --- CENTRE LOCATION DIAGNOSTIC CHECK --- %
% ---------------------------------------- %

% check to see if the is any overlap of the circles. if so, then the
% regions will need to be optimised further
if numel(X) > 1
    % determines if any of the circles overlap
    [dX,dY] = deal(diff(X,[],2),diff(Y,[],1));
    if (isempty(dX))
        % only need to check vertically if overlap
        dMin = min(dY(:));        
    elseif (isempty(dY))
        % only need to check horizontally if overlap
        dMin = min(dX(:));        
    else
        % otherwise, check both directions for overlap
        dMin = min(min(dX(:)),min(dY(:)));
    end
    
    % determines if there is any overlap
    cont = dMin < 2*(R0+rDelMin); 
    if (~cont); Dmx = dMin/2 - (R0+rDelMin); end
else
    % no need to check the alignment for a single region
    [cont,Dmx] = deal(false,rDelMax);
end

% checks the values to see if they are correct
while cont
    % memory allocation
    [Yc,Xc] = deal(zeros(size(Y))); 
    [pXY,pYX] = deal(cell(size(X,1),1),cell(size(X,2),1));
    
    % fits the x/y linear relationship    
    for i = 1:size(Xc,1)
        if (size(Xc,2) > 1)        
            % calculates the polynomial fits and         
            pXY{i} = polyfit(X(i,:),Y(i,:),1); 
            Yc(i,:) = polyval(pXY{i},X(i,:));
        else
            [pXY{i},Yc(i,:)] = deal([1,(Y(i,:)-X(i,:))],Y(i,:));
        end
    end
        
    % fits the y/x linear relationship
    for i = 1:size(Xc,2)
        if size(Xc,1) > 1
            % calculates the polynomial fits and         
            pYX{i} = polyfit(Y(:,i),X(:,i),1); 
            Xc(:,i) = polyval(pYX{i},Y(:,i));
        else
            [pYX{i},Xc(:,i)] = deal([1,(X(:,i)-Y(:,i))],X(:,i));
        end
    end
    
    % calculates the errors in the points from the fitted values
    D = sqrt((Yc - Y).^2 + (Xc - X).^2);
    [Dmx,imx] = max(D(:));

    % if the maximum is greater than tolerance, then re-fit the anomalous
    % value to the others
    if Dmx > sqrt(2)
        % sets up the simulataneous equations and solves them
        [ymx,xmx] = ind2sub(size(Yc),imx);
        Z = [[-pXY{ymx}(1),1];[1,-pYX{xmx}(1)]]\[pXY{ymx}(2);pYX{xmx}(2)];                
        
        % sets the new values
        [X(ymx,xmx),Y(ymx,xmx)] = deal(roundP(Z(1)),roundP(Z(2)));
    else
        % otherwise, exit the loop
        cont = false;
    end
end    

% sets the final radius
Rmax = R0 + floor(min(rDelMax,max(rDelMin,Dmx)));
R = min(Rmax,R0 + dR);

% closes the waitbar figure (and remove the resegmentation frames from the
% sub-image data struct)
if ~h.Update(1,'Automatic Dectection Complete!',1)    
    h.closeProgBar()
end

% if there was no better solution found from the initial radius search,
% then output a warning to screen
if isnan(fCount)
    eStr = sprintf(['Warning! You may have set the outer region to be too ',...
                    'small. This could reduce the accuracy of the region ',...
                    'placement algorithm.\n\nYou may need to reset the outer ',...
                    'region and re-run the circle detection.']);
    waitfor(warndlg(eStr,'Circle Detection Warning','modal'));
end

% --- objective function for optimising the centre of the circles
function F = optFunc(z,IT,IR)

% calculates the maximum residual
if any(abs(z) > 1)
    % shift is infeasible
    F = 1e10;
else
    % shifts the local residual image and takes the cross-correlation
    IT = conv2(IT,[z(2); 1-z(2)]*[z(1), 1-z(1)],'same');
    IXnw = normxcorr2(IT,IR); 

    % calculates the shifted image and calculates the mean shift
    F = -max(IXnw(:));    
end

% --- determines the initial estimate of the circle centres
function [xC,yC,R] = detInitCircleCentres(IG,rTol,tPer0,dim,h)    
    
% intialisations and memory allocation
Z = NaN(2,1);
Type = {'dark','bright'};
[xC0,yC0,R0,M0] = deal(cell(length(Type),1));

% updates the progressbar
h.Update(1,'Determining Initial Circle Centre Estimate',0.25);

% loops through each detection type estimating the circle centres
for i = 1:length(Type)
    % optimises the circle parmeters
    [xC0{i},yC0{i},R0{i},M0{i}] = ...
                        optCircleDetectPara(IG,rTol,tPer0,Type{i});
    if isequal(size(xC0{i}),dim)
        % if the dimensions are correct, then calculate the difference
        % between the grid row/column coordinates
        dxC0 = max(0,1-abs(diff(xC0{i},[],2)-tPer0)/tPer0);
        dyC0 = max(0,1-abs(diff(yC0{i},[],1)-tPer0)/tPer0);        
        dxR0 = max(0,1-abs(xC0{i}-repmat(mean(xC0{i},1),dim(1),1))/tPer0);
        dyR0 = max(0,1-abs(yC0{i}-repmat(mean(yC0{i},2),1,dim(1)))/tPer0);
        
        % calculates the overall for the polarity type
        Z(i) = nanmean(dxC0(:))*nanmean(dyC0(:))*...
               nanmean(dxR0(:))*nanmean(dyR0(:))*nanmean(M0{i}(:));
    end
end

% returns the type that has the least variation from the region
% periodicitiy and the greatest metric values
i0 = argMax(Z);
[xC,yC,R] = deal(xC0{i0},yC0{i0},R0{i0});
Rmax0 = calcMaxRadii(xC,yC);

% ---------------------------------- %
% --- CIRCLE CENTRE OPTIMISATION --- %
% ---------------------------------- %

% updates the progressbar
h.Update(1,'Calculating Image Cross-Correlation',0.5);

% sets up the xcorr template image
Isub = setupSubImageStack(IG,roundP(xC),roundP(yC),Rmax0);
IsubMn = calcImageStackFcn(Isub(:),'median');

% calculate the cross-correlation image (from the template)
IGex = padarray(IG,Rmax0*[1,1],'replicate','both');
IxcT = normxcorr2(IsubMn,IGex);
Ixc = IxcT(2*Rmax0+(1:size(IG,1)),2*Rmax0+(1:size(IG,2)));

% updates the progressbar
h.Update(1,'Fine Resolution Detection',0.75);

% determines the regional maxima from the xcorr image
iMx = find(imregionalmax(Ixc));
[yMx,xMx] = ind2sub(size(Ixc),iMx);

% loops through each region adjusting the regions to the xcorr maxima
DMx = pdist2([xC(:),yC(:)],[xMx,yMx]);
for i = 1:size(DMx,1)
    % determines all the maxima that are within tolerance of the centre
    ii = find(DMx(i,:) < Rmax0/4);
    if ~isempty(ii)
        % determines the most likely candidate for resetting
        if length(ii) == 1
            jj = 1;
        else
            jj = argMax(Ixc(iMx(ii)));
        end
        
        % updates the circle centre coordinates
        [xC(i),yC(i)] = deal(xMx(ii(jj)),yMx(ii(jj)));
    end
end


% --- setup cross-correlation sub-image
function Isub = setupSubImageStack(IG,xC,yC,R)

% initalisations
sz = size(IG);
nImg = numel(xC);
xiS = -R:R;
Isub = repmat({NaN(2*R+1)},size(xC));

%
for i = 1:nImg
    % sets the row/column indices surround the current coordinate
    [iR,iC] = deal(yC(i)+xiS,xC(i)+xiS);
    [ii,jj] = deal((iR >= 1) & (iR <= sz(1)),(iC >= 1) & (iC <= sz(2)));
    
    % sets the sub-image
    Isub{i}(ii,jj) = IG(iR(ii),iC(jj));
end

%
a = 1;

% --- calculates 
function [XC,YC,Rnw,MC] = optCircleDetectPara(IG,rTol,tPer0,Type)

% initialisations
sTol = 0.995;
wState = warning('off','all');

% calculate the circle regions using the object polarity type, Type
[pC0,R0,M] = imfindcircles(IG,rTol,...
            'ObjectPolarity',Type,'Sensitivity',sTol,'Method','TwoStage');        

% calculates the verical/horiztonal distance btwn points
dX = calcRelativeDistance(pC0(:,1));
dY = calcRelativeDistance(pC0(:,2));
[dX(logical(eye(size(dX)))),dY(logical(eye(size(dY))))] = deal(2*tPer0); 

try
    % determines the most likely grid match indices
    iGrid = detGridMatchIndices(IG,pC0,M,dX,dY,tPer0);
    
    % sets the coordinates, radii and metrics for each grid point
    ii = ~isnan(iGrid);
    [Rnw,XC,YC,MC] = deal(zeros(size(iGrid)));
    [Rnw(ii),MC(ii)] = deal(R0(iGrid(ii)),M(iGrid(ii)));
    [XC(ii),YC(ii)] = deal(pC0(iGrid(ii),1),pC0(iGrid(ii),2));
    
    % if there are any missing regions, then estimate their values
    if any(~ii(:))
        % calculates the interpolant objects   
        [X,Y] = meshgrid(1:size(iGrid,2),1:size(iGrid,1));        
        Fx = scatteredInterpolant([X(ii),Y(ii)],XC(ii),'linear');
        Fy = scatteredInterpolant([X(ii),Y(ii)],YC(ii),'linear');
        
        % interpolates the missing values
        XC(~ii) = Fx(X(~ii),Y(~ii));
        YC(~ii) = Fy(X(~ii),Y(~ii));
        Rnw(~ii) = roundP(median(Rnw(ii)));
    end
    
catch
    % if there was an error, then return empty array
    [XC,YC,Rnw,MC] = deal([]);
end

% resets the warnings to their original state
warning(wState)

% --- determines the matching grid indices
function iGrid = detGridMatchIndices(I,pC,M,dX,dY,tPer)

% memory allocation
i0 = 1;
sz = size(I);

% searches the grid regions in the four directions
iX0 = searchRegionGridDir(pC,i0,dX,dY,tPer,sz,[-1,0]);
iX1 = searchRegionGridDir(pC,i0,dX,dY,tPer,sz,[1,0]);
iY0 = searchRegionGridDir(pC,i0,dX,dY,tPer,sz,[0,-1]);
iY1 = searchRegionGridDir(pC,i0,dX,dY,tPer,sz,[0,1]);

% memory allocation
[iR,iC] = deal(length(iY0)+1,length(iX0)+1);
dimG = [length([iY0,iY1]),length([iX0,iX1])] + 1;

% updates the 
iGrid = NaN(dimG);
[iGrid(iR,:),iGrid(:,iC)] = deal([iX0,i0,iX1],[iY0,i0,iY1]');
[N0,N1] = deal(iC-1,dimG(2)-iC);

% loops through each row matching the adjacent columns
for i = 1:dimG(1)
    if i ~= iR
        % calculates the matches to the left of the initial column
        iX0 = searchRegionGridDir(pC,iGrid(i,iC),dX,dY,tPer,sz,[-1,0]);
        if length(iX0) < N0
            % case is the index array is too small
            iGrid(i,(iC-length(iX0)):(iC-1)) = iX0;
            
        else
            % case is the index array is too large
            iGrid(i,1:N0) = iX0(1+(length(iX0)-N0):end);           
        end
        
        % calculates the matches to the right of the initial column
        iX1 = searchRegionGridDir(pC,iGrid(i,iC),dX,dY,tPer,sz,[1,0]);
        if length(iX1) < N1
            %
            iGrid(i,iC+(1:length(iX1))) = iX1;
        else
            %
            iGrid(i,(iC+1):end) = iX1(1:N1);
        end
    end
end

% --- searches the 
function iMatch = searchRegionGridDir(pC,ind0,dX,dY,tPer,sz,sDir)

% initialisations
dTol = tPer/6;
[iMatch,ind] = deal([],ind0);

%
while true
    % determines the new potential matches (based on the current search
    % region and the search direction)
    if sDir(1) ~= 0
        % case is searching in the horizontal direction
        if (pC(ind,1) < tPer/2) || ((sz(2)-pC(ind,1)) < tPer/2)
            % if searching further is infeasible, then exit the loop
            break
        else        
            % otherwise, determine the potential matching centres
            i0 = abs(dX(:,ind)*sDir(1) - tPer) < dTol;
            i1 = abs(dY(:,ind)) < dTol;
        end
    else     
        % case is searching in the vertical direction
        if (pC(ind,2) < tPer/2) || ((sz(1)-pC(ind,2)) < tPer/2)
            % if searching further is infeasible, then exit the loop
            break
        else
            % otherwise, determine the potential matching centres
            i0 = abs(dX(:,ind)) < dTol;
            i1 = abs(dY(:,ind)*sDir(2) - tPer) < dTol;
        end
    end
    
    % determines which point is the most likely match
    i2 = find(i0 & i1);
    switch length(i2)
        case 0
            % no match is made, so exit the loop
            break
            
        case 1
            % case is there is only one unique match
            [iMatch(end+1),ind] = deal(i2);
            
        otherwise
            % case is there are numerous potential matches
            if sDir(1) ~= 0
                D = sqrt((sDir(1)*dX(i2,ind)-tPer).^2 + dY(i2,ind).^2);
            else
                D = sqrt(dX(i2,ind).^2 + (sDir(2)*dY(i2,ind)-tPer).^2);
            end
            
            %
            imn = argMin(D);
            [iMatch(end+1),ind] = deal(i2(imn));
    end
end

% flips the array (if searching in reverse directions)
if any(sDir < 0)
    iMatch = flip(iMatch);
end


% --- calculates the maximum possible radii between circles
function Rmax = calcMaxRadii(xC,yC)

% calculates the maximum radii such that the 
P = [xC(:),yC(:)]; 
Dc = pdist2(P,P); 
Dc(logical(eye(size(Dc)))) = NaN;
Rmax = roundP(nanmin(Dc(:))/2);

% calculates the relative distance between the points
function dZ = calcRelativeDistance(Z)

Y = repmat(Z,1,length(Z));
dZ = Y - Y';