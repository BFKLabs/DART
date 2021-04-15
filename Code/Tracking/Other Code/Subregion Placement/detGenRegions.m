% --- determines the general region outline
function iMov = detGenRegions(iMov,Istack)

% creates a waitbar figure
wStr = {'Initial Sub-Region Detection'};
h = ProgBar(wStr,'General Sub-Region Detection');

% parameters and other initialisations
nIter = 2;
pTol = 0.75;
sz = size(Istack{1});
hG = fspecial('gaussian',5,2);

% sets up the fly count array (arranged in row/column format)
nFlyT = iMov.nTubeR;

% sets the total row/column counts
[nRowT,nColT] = deal(sum(max(nFlyT,[],2)),iMov.nCol);

% ------------------------------------ %
% --- INITIAL SUB-REGION DETECTION --- %
% ------------------------------------ %

% sets the global search region
dT = 10;
Bg = false(sz);
iRG = roundP(max(1,iMov.posG(2)-dT):min(sz(1),sum(iMov.posG([2 4]))+dT));
iCG = roundP(max(1,iMov.posG(1)-dT):min(sz(2),sum(iMov.posG([1 3]))+dT));
Bg(iRG,iCG) = true;

% calculates the median baseline removed image
I = calcImageStackFcn(Istack,'min');
h0 = ceil(getMedBLSize(iMov)*2);
ImdBL0 = removeImageMedianBL(double(I),false,true,h0);
ImdBL0(~Bg) = 0;

% updates the waitbar figure
if h.Update(1,wStr{1},0.1/6)
    iMov = [];
    return
end

% ------------------------------------------ %
% --- EXPERIMENTAL REGION DIMENSIONALITY --- %
% ------------------------------------------ %

% calculates the weighted row/column mean signals
[ZC,ZR] = setupWeightedMeanSignals(ImdBL0,[nRowT,nColT],h);
if isempty(ZC)
    % if there was an error then exit the function
    iMov = [];
    return
end

% determines the row/column indices of the repeating pattern groups
iR = calcRegionIndices(ZR);
iC = calcRegionIndices(ZC);

% determines if the region configuration is feasible
if ~checkIfRegionFeas([length(iR),length(iC)],[nRowT,nColT],h)
    % if not, then exit the function
    iMov = [];    
    return    
else
    % otherwise, reset the row/column indices to match the required counts
    [iR,iC] = deal(iR(1:nRowT),iC(1:nColT));
end

% calculates the x/y offset coordinates for each region
[x0,y0] = deal(cellfun(@(x)(x(1)-1),iC),cellfun(@(x)(x(1)-1),iR));
[X,Y] = meshgrid(x0,y0);
pOfs = num2cell([X(:),Y(:)],2);

% updates the waitbar figure
if h.Update(1,wStr{1},1/3)
    iMov = [];
    return
end

% recalculates the median baseline removed image (based on the region size)
h0 = getMedBLSize(iMov);
ImdBL = removeImageMedianBL(double(I),false,true,h0);

% ------------------------------------ %
% --- SUB-REGION LOCATION ESTIMATE --- %
% ------------------------------------ %

% estimates the sub-region reference image and from this determines the
% location of the sub-regions within the image (this process is run nIter
% times to refine the sub-region locations - nIter > 3 is unnecessary)
for i = 1:nIter
    % updates the waitbar figure
    pW = (1/3)*(1+i/nIter);
    if h.Update(1,'Sub-Region Location Estimation',pW)
        iMov = [];
        return
    end
    
    if i == 1
        % sets up the reference image based on the grouping estimates
        IGrp = getInitRegionSubImages(ImdBL,iR,iC);
        IRef = setupReferenceImg(IGrp); 
        szL = size(IRef);
        
        % calculates the cross-correlation of the image against the
        % reference estimate (retrieves the sub-images from this)   
        Ixc = imfilter(calcXCorrImage(ImdBL,IRef),hG);
        [IGrpXC,iOfs] = getInitRegionSubImages(Ixc,iR,iC);  
        
        % calculates the positional offset vectors
        pOfs = cellfun(@(p,dp)(p+dp),pOfs,num2cell(iOfs,2),'un',0);
        
    else
        % sets up the reference image based on the grouping estimates
        pMaxC = num2cell(pMax,2);
        IGrp = cellfun(@(x)(getPointSubImages(ImdBL,x,szL)),pMaxC,'un',0);
        IRef = setupReferenceImg(IGrp);
        
        % calculates the cross-correlation of the image against the
        % reference estimate (retrieves the sub-images from this)
        Ixc = imfilter(calcXCorrImage(ImdBL,IRef),hG);        
        IGrpXC = cellfun(@(x)(getPointSubImages(Ixc,x,szL)),pMaxC,'un',0);
        
        % calculates the positional offset
        pOfs = num2cell(pMax-repmat(szL([2,1])/2,size(pMax,1),1),2);
    end
    
    % calculates the likely locations of all sub-regions 
    pMax = cell2mat(cellfun(@(I,p)(roundP(detLikelyCorrMax(I)+p)),...
                                       IGrpXC,pOfs,'un',0));
end

% -------------------------------------------------- %
% --- SUB-REGION OUTLINE COORDINATE CALCULATIONS --- %
% -------------------------------------------------- %

% updates the waitbar figure
if h.Update(1,'Sub-Region Outline Coordinate Calculations',5/6)
    iMov = [];
    return
end

% initialisations
pOfs = szL([2,1])/2;
nDil = floor(min(szL)/50);
szImg = [1,1,length(iR)*length(iC)];

% calculates the final reference image (from the original image) 
IGrpF = cellfun(@(x)(getPointSubImages(I,x,szL)),num2cell(pMax,2),'un',0);
IRefF = nanmedian(cell2mat(reshape(IGrpF,szImg)),3);
BRefF = sauvolaThresh(IRefF, szL, 0);

% determines the sub-region shape based on its relative pixel intensity to
% the outside of the reference image
Bout = bwmorph(true(szL),'remove');
isRev = nanmean(BRefF(Bout)) > 0.5;
if isRev
    % the sub-region is darker than the outside
    B0 = imfill(bwmorph(rmvGroups(~BRefF),'majority'),'holes');
else
    % the sub-region is brighter than the outside
    B0 = imfill(bwmorph(rmvGroups(BRefF),'majority'),'holes');
end

% determines if the sub-region contains a generic shape type
[~,P,BB,A] = getGroupIndex(B0,'Perimeter','BoundingBox','Area');

% calculates the dimension ratios of several objects
pCirc = P^2/(4*A*pi);               % Circle - Perimeter/Area ratio
pSquare = (P/4)^2/A;                % Square - Perimeter/Area ratio
pRect = A/prod(BB(3:4)-1);          % Rectangle - Area/BB ratio
pObj = reciprocalFcn([pCirc,pSquare,pRect]);

% determines if the sub-region binary mask represents a generic shape
if any(pObj > pTol)
    % if so, then reset the binary mask to fit the shape
    switch argMax(pObj)
        case 1
            % case is the region is likely a circle
            [xCF,yCF] = optCircleOutline(B0);
            
            % 
            dX = max(0,max([-min(xCF),max(xCF)-size(B0,2)]));
            dY = max(0,max([-min(yCF),max(yCF)-size(B0,1)]));
            dDim = max([dX,dY]);
            
            % sets the outline coordinates into the binary mask
            if dDim > 0
                szL = szL+2*dDim;
                [xCF,yCF] = deal(xCF+dDim,yCF+dDim);
                B0 = false(szL);
            end
                
            %
            B0(:) = false;                
            B0(sub2ind(szL,yCF,xCF)) = true;
            B0 = imfill(B0,'holes');
            
        case {2,3}
            % case is the region is likely a rectangle or square
            
            % converts the bounding box region to a square/rectangle
            BB = [ceil(BB(1:2)),BB(3:4)-1];            
            B0(:) = false;
            B0(BB(2):sum(BB([2,4])),BB(1):sum(BB([1,3]))) = true;            
            
    end    
end

% sets the binary image for calculating the region outline coordinates
while 1
    % dilates the original image
    BC = bwmorph(B0,'dilate',nDil);
    
    % determines if any points lie on the image edge
    if any(BC(bwmorph(true(size(B0)),'remove')))
        % if so, then expand the image
        [B0,pOfs] = deal(padarray(B0,[1,1]),pOfs+1);
    else
        % otherwise, exit the loop
        break
    end
end

% aligns the sub-region centroids
[xC0,yC0] = getBinaryCoords(BC);
dLim = min(0.1*[range(xC0),range(yC0)]);      
[xP,yP,ok] = realignSubRegions(iMov,Ixc,pMax,nFlyT,dLim);

% prompts the user for the final binary dilation
BC = GenPara(iMov,B0,nDil,xP,yP,h);
if isempty(B0)
    % if the user cancelled, then exit the function
    iMov = [];
    return
else
    % otherwise, calculate the final binary coordinates
    [xC,yC,pOfs] = getBinaryCoords(BC);
end

% ------------------------------- %
% --- HOUSE-KEEPING EXERCISES --- %
% ------------------------------- %

% updates the waitbar figure
if h.Update(1,'House-Keeping Exercises',11/12)
    iMov = [];
    return
end

% initialisations
nApp = iMov.nRow*iMov.nCol;
[xCmn,xCmx,yCmn,yCmx] = deal(min(xC),max(xC),min(yC),max(yC));

% sets the automatic detection parameters
autoP = struct('X0',xP,'Y0',yP,'XC',xC,'YC',yC,'BC',BC,'BT',[],...
               'pOfs',pOfs,'Type','GeneralR');
autoP.BT = cell(nApp,1);
           
%
for i = 1:nApp
    % retrieves the global row/column index
    [iCol,iFlyR0,iRow] = getRegionIndices(iMov,i);
    iFlyR = iFlyR0(iMov.isUse{iRow,iCol});
    
    % determines the min/max locations of the objects in the sub-region
    xMin = max(1,floor(xP(iFlyR,iCol)+xCmn));
    xMax = min(sz(2),ceil(xP(iFlyR,iCol)+xCmx));
    yMin = max(1,floor(yP(iFlyR,iCol)+yCmn));
    yMax = min(sz(1),ceil(yP(iFlyR,iCol)+yCmx));
    
    % resets the global row/column indices
    iMov.iC{i} = min(xMin):max(xMax);
    iMov.iR{i} = min(yMin):max(yMax); 
    
    % sets the row/column indices for the sub-regions
    [xOfs,yOfs] = deal(iMov.iC{i}(1)-1,iMov.iR{i}(1)-1);
    iMov.iRT{i} = arrayfun(@(x,y)(max(1,floor(x)):min(...
                length(iMov.iR{i}),ceil(y))),yMin-yOfs,yMax-yOfs,'un',0);
    iMov.iCT{i} = 1:length(iMov.iC{i});        
    iMov.xTube{i} = [0 diff(iMov.iC{i}([1 end]))];            
    
    % allocates memory for the sub-region binary masks
    szBT = [length(iMov.iR{i}),length(iMov.iC{i})];
    autoP.BT{i} = false(szBT);
    for j = 1:length(iFlyR)
        % sets the coordinates of the outline
        k = iFlyR(j);
        xNw = min(szBT(2),max(1,xP(k,iCol)+(xC-xOfs)));
        yNw = min(szBT(1),max(1,yP(k,iCol)+(yC-yOfs)));        
        autoP.BT{i}(sub2ind(size(autoP.BT{i}),yNw,xNw)) = true;
        
        % sets the vertical position of the tubes
        iMov.yTube{i}(j,:) = iMov.iRT{i}{j}([1 end]) - 1;           
    end
    
    % fills in the holes in the bw image
    autoP.BT{i} = imfill(autoP.BT{i},'holes');
end

% determines the x/y range of the sub-regions
xRng = cell2mat(cellfun(@(x)(x([1,end])),iMov.iC(:),'un',0));
yRng = cell2mat(cellfun(@(x)(x([1,end])),iMov.iR(:),'un',0));

% calculates the global positional outline 
[xMinG,xMaxG] = deal(min(xRng(:,1)),max(xRng(:,2)));
[yMinG,yMaxG] = deal(min(yRng(:,1)),max(yRng(:,2))); 
iMov.posG = [xMinG,yMinG,(xMaxG-xMinG),(yMaxG-yMinG)];

% updates the automatic detection parameters
iMov.autoP = autoP;

% updates and closes the waitbar figure (if still open)
if ~h.Update(1,'General Sub-Region Detection Complete!',1)
    h.closeProgBar()
end

% --- determines if the required configuration meets that which was set
%     by the user
function isFeas = checkIfRegionFeas(nDim,nDimT,h)

% initialisations
dStr = {'Row','Column'};
dDim = nDim - nDimT;

% determines if the current dimensions exceeds the required dimensions
isFeas = all(dDim >= 0);
if ~isFeas
    % if the dimensions don't meet requirements, then output an error 
    % message to screen    
    eStr = sprintf(['The search region does not meet the ',...
                    'required specifications.\n']);
                
    % closes the progressbar
    h.closeProgBar()                
    
    % appends the offending dimensions to the error message
    for i = find(dDim(:) < 0)'
        eStrNw = sprintf([' * %s Count:\n  - Required = %i\n',...
                   '  - Estimated = %i\n'],dStr{i},nDimT(i),nDim(i));
        eStr = sprintf('%s\n%s',eStr,eStrNw);
    end   
    
    % outputs the final error to screen    
    eStr = sprintf(['%s\nEither expand the search region ',...
                    'or reduce the row/column counts.'],eStr);
    waitfor(msgbox(eStr,'General Region Detection Error','modal'))
    
elseif sum(dDim) > 0
    % if the user selected an area that is larger than required, then
    % output a warning message to screen
    eStr = sprintf(['The search region exceeds than the required ',...
                    'specifications.\n']);    
    
    % makes the progressbar invisible
    h.setVisibility('off')                
    
    % appends the offending dimensions to the error message
    for i = find(dDim(:) > 0)'
        eStrNw = sprintf([' * %s Count:\n  - Required = %i\n',...
                   '  - Estimated = %i\n'],dStr{i},nDimT(i),nDim(i));
        eStr = sprintf('%s\n%s',eStr,eStrNw);
    end                  
                
    % outputs the final error to screen 
    eStr = sprintf(['%s\nThis is not an error however the detection ',...
                    'algorithm may not accurately represent the desired ',...
                    'regions. To remedy this issue either reduce the ',...
                    'search region to match or increase the ',...
                    'row/column counts.'],eStr);
    waitfor(msgbox(eStr,'General Region Detection Warning','modal'))    
    
    % makes the progressbar invisible
    h.setVisibility('on')     
end

% --- sets up the x-correlation reference Image
function IRef = setupReferenceImg(IGrp)

% memory allocation
sz = size(IGrp{1});
isOK = true(length(IGrp),1);

% calculates an estimate of the average from the image stack
IRef0 = calcImageStackFcn(IGrp,'median'); 

% re-aligns the images to the reference image estimage
for i = 1:length(IGrp)
    % calculates the image offset from the reference estimate
    IGrp{i}(isnan(IGrp{i})) = 0;    
    Ixc = normxcorr2(IGrp{i},IRef0);
    dZ = sz([2,1]) - getMaxCoord(Ixc);
    
    % if there is an offset, then shift the sub-image
    if sum(abs(dZ)) > 0
        IGrp{i} = getShiftedImage(IGrp{i},dZ(1),dZ(2));
    end
end

%
IRef = calcImageStackFcn(IGrp(isOK),'median');

% --- ensures that all values from the ratio array, Y, are < 1
function Y = reciprocalFcn(Y)

% ensures that all values greater than 1 are inverted
ii = Y > 1;
Y(ii) = 1./Y(ii);

% --- retrieves the sub-image surrounding the point, pP
function IPts = getPointSubImages(I,pP,szI)

% memory allocation
IPts = NaN(szI);

% calculates the row/column indices surrounding the current point
iR = (pP(2)-floor(szI(1)/2))+(1:szI(1));
iC = (pP(1)-floor(szI(2)/2))+(1:szI(2));

% determines the feasible row/column indices
ii = (iR >= 1) & (iR <= size(I,1));
jj = (iC >= 1) & (iC <= size(I,2));

% sets the final sub-image
IPts(ii,jj) = I(iR(ii),iC(jj));

% --- calculates the image cross-correlation with the reference image, IRef
function Ixc = calcXCorrImage(I,IRef)

% array dimensions
[sz,szL] = deal(size(I),size(IRef));
dN = floor(szL/2);
N = min(dN);
II = expandImg(I,N);

% calculates the cross-correlation (reduces to the original image size)
Ixc0 = normxcorr2(IRef,II);
Ixc = Ixc0((N+dN(1))+(1:sz(1)),(N+dN(2))+(1:sz(2)));

% --- determines the location of the likely x-corr maxima from I
function pMax = detLikelyCorrMax(I,normD)

% sets the default input arguments
if ~exist('normD','var'); normD = true; end

% determines the 
d0 = 0.1;
sz = size(I);
I(isnan(I)) = 0;

% determines the coordinates of the local xcorr maxima
iP = imregionalmax(I);
[yP,xP] = find(iP);

% removes any points on the image edge
ii = (xP > 1) & (xP < sz(2)) & (yP > 1) & (yP < sz(1));
[xP,yP] = deal(xP(ii),yP(ii));
iPF = sub2ind(sz,yP,xP);

% calculates the distance of the points from the centre
if normD
    % distance is normalised
    D = d0 + sqrt(sum(([2*xP/sz(2),2*yP/sz(1)]-1).^2,2));
else
    % distance is not normalised
    D = d0 + sqrt(sum([xP-sz(2)/2,yP-sz(1)/2].^2,2));
end

% calculates the point with the max object function (intensity/distance)
% setting this as the overall maxima
iMx = argMax((max(0,I(iPF)).^2)./D);
pMax = [xP(iMx),yP(iMx)];

% --- retrieves the region sub-images
function [IGrp,iOfs] = getInitRegionSubImages(I,iR,iC)

% retrieves the initial sub-region groupings
IGrp = cell2cell(cellfun(@(x)(cellfun(@(y)(I(y,x)),iR,'un',0)),iC,'un',0));

% determines the overall minimum dimensions
szL = cell2mat(cellfun(@size,IGrp,'un',0));
szMin = min(szL,[],1);

% reshapes the images so that they are all the same dimensions
iOfs = zeros(length(IGrp),2);
for i = 1:length(IGrp)
    iOfs(i,[2,1]) = floor((szL(i,:)-szMin)/2);
    IGrp{i} = IGrp{i}(iOfs(i,2)+(1:szMin(1)),iOfs(i,1)+(1:szMin(2)));
end

% ---------------------------------------------- %
% --- INITIAL SUB-REGION DETECTION FUNCTIONS --- %
% ---------------------------------------------- %

% --- calculates the row/column indices of the regular pattern
function [ind,tPer] = calcRegionIndices(Z)

% parameters
del = 5;
ptPer = [0.2,0.3];

% determines the most likely min/max peak groupings
tPer = calcSignalPeriodicity(Z);
iP = detLikelySignalPeaks(Z,tPer);

% determines the points are feasibly within the periodicity limit
diP = diff(iP);
isF = rmvGroups((diP > (1-ptPer(1))*tPer) & (diP < (1+ptPer(1))*tPer));
nP = length(diP);

% if first feasible point is just outside the first periodicity, but within
% the 2nd limit, then reset the first point
i0 = find(isF,1,'first')-1;
if i0 > 0
    if (diP(i0)>(1-ptPer(2))*tPer) && (diP(i0)<(1+ptPer(2))*tPer)
        [iP(i0),isF(i0)] = deal(max(1,roundP(iP(i0+1)-tPer)),true);
    end
end

% if last feasible point is just outside the first periodicity, but within
% the 2nd limit, then reset the last point
i1 = find(isF,1,'last')+1;
if (i1<=nP)
    if (diP(i1)>(1-ptPer(2))*tPer) && (diP(i1)<(1+ptPer(2))*tPer)
        [iP(i1),isF(i1)] = deal(min(length(Z),roundP(iP(i1-1)+tPer)),true);
    end
end

% resets the location of the peaks to include all region edge points 
ii = find(rmvGroups(isF));
iP = iP([ii;(ii(end)+1)]);

% sets the row/column band index groups
indG = [max(1,iP(1:end-1)-del),min(length(Z),iP(2:end)+del)];
ind = cellfun(@(x)(x(1):x(2)),num2cell(indG,2),'un',0);

% --- calculates the 
function [iP,Zscore] = detLikelySignalPeaks(Z,tPer)

%
[yP0,iP0,~,P] = findpeaks(Z);
[yP0(yP0<0),diP0] = deal(0,iP0);

% splits the signal into groups with periodicity, tPer
t0 = iP0(argMax((P.*yP0.*(yP0/max(yP0)>0.5))));%./abs(iP0-length(Z)/2)));
iGrp0 = [(1+mod((t0-tPer/2)-1,tPer)):tPer:(t0-tPer/2),...
         (t0+tPer/2):tPer:length(Z)]'; 

% groups the indices by their position
xLim = num2cell([[0;iGrp0],[iGrp0;diP0(end)+1]],2);
jGrp = cellfun(@(x)(find((diP0>=x(1))&(diP0<x(2)))),xLim,'un',0);
jGrp = jGrp(~cellfun(@isempty,jGrp));

% from each grouping, determine the peaks with the highest combined
% amplitude/prominence score
Zscore0 = yP0.*P;
ii = cellfun(@(x)(x(argMax(Zscore0(x)))),jGrp);

% returns the most likely groupings for each band
iP = iP0(ii);
Zscore = mean(Zscore0(ii))/(1+mean(abs(diff(iP)-tPer)));

% --- calculates the signal periodicity
function tPer = calcSignalPeriodicity(Z)

% parameters
pkTol = 0.5;

% removes the signal baseline
dZ = Z - nanmean(Z);
[aY,tLag0] = xcorr(dZ,'coeff');
[~,tPeak,~,P] = findpeaks(aY);

% reduces the times down to the positive time peaks
ii = tLag0(tPeak) >= 0;
[tPeak,P] = deal(tLag0(tPeak(ii)),P(ii));

% determines the first peak to the right of the central peak
jj = tPeak > 1;
[tPeak,P] = deal(tPeak(jj),P(jj));
tPer = tPeak(find(P/max(P)>pkTol,1,'first'));

% ---------------------------------------------- %
% --- CIRCULAR REGION OPTIMISATION FUNCTIONS --- %
% ---------------------------------------------- %

% --- optimises the circles coordinates from the binary mask, B0
function [xCF,yCF] = optCircleOutline(B0)

% initialisations
opt = optimset('display','none');
[szL,pOfs] = deal(size(B0),[0,0]);

%
Bedge = bwmorph(true(szL),'remove');
if any(B0(Bedge))
    [B0,pOfs] = deal(padarray(B0,[1,1]),[1,1]);
end

% sets up the contour coordinate arrays
c = contourc(double(B0),0.5*[1,1]);
xC0 = roundP(c(1,2:end)'-(szL(2)/2));
yC0 = roundP(c(2,2:end)'-(szL(1)/2));
[xC,yC] = deal(xC0([1:end,1]),yC0([1:end,1]));
[xCR,yCR] = deal(flip(xC),flip(yC));

% sets up the initial parameter estimates
N = length(yC);
T = linspace(0,1,N)';
[xMin,xMax,yMin,yMax] = deal(min(xC),max(xC),min(yC),max(yC));
x0 = [0.5*[(xMin+xMax),(yMin+yMax),(yMax-yMin)],T(argMax(xC))];

% optimises the contours (for the forward/reverse directions)
[xP1,R1] = lsqnonlin(@objFunc,x0,[],[],opt,xC,yC,T);
[xP2,R2] = lsqnonlin(@objFunc,x0,[],[],opt,xCR,yCR,T);

% sets the outline coordinates based on the better fit
if R1 < R2
    % forward direction has a better fit
    [~,xCF,yCF] = objFunc(xP1,xC,yC,linspace(0,1,3*N)');
else
    % reverse direction has a better fit
    [~,xCF,yCF] = objFunc(xP2,xCR,yCR,linspace(0,1,3*N)');
end

% sets the final coordinates
[xCF,yCF] = deal(roundP(xCF+szL(2)/2)-pOfs(1),roundP(yCF+szL(1)/2)-pOfs(2));

% --- optimises the circle parameters for the contour coordinates, xC/yC
function [F,xCnw,yCnw] = objFunc(x,xC,yC,T)

% sets the input parameters
[x0,y0,A,phi] = deal(x(1),x(2),x(3),x(4));

% calculates the x/y coordinates
xCnw = x0 + A*cos(2*pi*T+phi);
yCnw = y0 + A*sin(2*pi*T+phi);

% calculates/sets the residual array
if length(xC) == length(xCnw)
    F = [(xCnw-xC);(yCnw-yC)];
else
    F = [];
end

% ---------------------------------------- %
% --- SUB-REGION REALIGNMENT FUNCTIONS --- %
% ---------------------------------------- %

% --- realigns the sub-regions so that they roughly fitted to a 
%     polynomial curve (realigns "missing" regions)
function [xPF,yPF,ok] = realignSubRegions(iMov,Ixc,pMax,nFlyT,dLim)

% parameters and dimensioning
w0 = 0.01;
sz = size(Ixc);
szF = [sum(max(nFlyT,[],2)),iMov.nCol];

% memory allocation
ok = true(szF);
[xPF,yPF] = deal(zeros(szF));

% retrieves the x-correlation values for each candidate point. also
% reshapes the arrays into their final dimensioning form
IxcP = max(w0,reshape(Ixc(sub2ind(sz,pMax(:,2),pMax(:,1))),szF));
[xP0,yP0] = deal(reshape(pMax(:,1),szF),reshape(pMax(:,2),szF));

% fits the sub-region centroids in the horizontal direction
for j = 1:szF(1)
    yPF(j,:) = calcPolyFitValues(xP0(j,:),yP0(j,:),IxcP(j,:),dLim);
end

% fits the sub-region centroids in the vertical direction
for j = 1:size(xP0,2)
    xPF(:,j) = calcPolyFitValues(yP0(:,j),xP0(:,j),IxcP(:,j),dLim); 
end

% keep looping until all regions are either within distance tolerance or
% have been re-aligned
D = sqrt((xP0-xPF).^2 + (yP0-yPF).^2);
while 1
    % determines the centroid furtherest from the estimate
    iMx = argMax(D(:));
    if D(iMx) > dLim
        % if above tolerance, then determine the coordinates of the
        % offending sub-region
        [yMx,xMx] = ind2sub(size(D),iMx);
        
        % resets the initial coordinates to the estimated value
        ok(yMx,xMx) = false;
        xP0(yMx,xMx) = xPF(yMx,xMx);
        yP0(yMx,xMx) = yPF(yMx,xMx);
        
        % re-calculates the centroids of the sub-regions in the row/column
        yPF(yMx,:) = calcPolyFitValues(...
                        xP0(yMx,:),yP0(yMx,:),IxcP(yMx,:),dLim,ok(yMx,:));
        xPF(:,xMx) = calcPolyFitValues(...
                        yP0(:,xMx),xP0(:,xMx),IxcP(:,xMx),dLim,ok(:,xMx)); 
        
        % re-calculates the distances (removing the contribution from any
        % re-aligned sub-regions)
        D = sqrt((xP0-xPF).^2 + (yP0-yPF).^2);
        D(~ok) = 0;
    else
        % otherwise exit the loop
        break
    end
end

% ensures the centroid coordinates are integers
[xPF,yPF] = deal(roundP(xPF),roundP(yPF));

% --- calculates the weighted-fit polynomial values
function yF = calcPolyFitValues(x0,y0,W,dLim,ok)

%
[rsTol,nRetry,nRetryMax] = deal(0.8,0,10);
if ~exist('ok','var'); ok =(abs(y0(:)-median(y0)) <= ceil(dLim)); end

% resets the coordinates/weights to only include the feasible locations
while 1
    % if there are insufficient points to fit a parabola, then exit using
    % the original values
    if sum(ok) < 3
        yF = y0(:);
        break
    end
    
    % sets the new values for the fitting process
    [xC,yC,WC] = deal(x0(ok),y0(ok),W(ok).^2);
    WC = WC/nansum(WC);
    
    % calculates the initial fit values
    [cf,gof] = fit(xC(:),yC(:),fittype('poly2'),'Weight',WC(:));  
    yF = feval(cf,x0(:));
    
    % determines if the fit was decent
    if gof.rsquare > rsTol
        % if so, then exit the loop
        break
    else
        % otherwise, remove the point with the greatest deviation
        dI = abs(yF(:)-y0(:)).*ok(:);
        ok(argMax(dI)) = false;
        
        %
        nRetry = nRetry + 1;
        if nRetry > nRetryMax
            yF = y0(:);
            return
        end
    end
end

% --- sets up the row/column weighted mean signals from the image, I
function [ZC,ZR] = setupWeightedMeanSignals(I,nDim,h)

% parameters
del = 25;
szB = 100;
zTol = 0.35;
sz = size(I);
ok = true;

% determines the sub-image block count and row/column offset
nB = floor((sz-szB)/del);
pOfs = ceil((sz-(nB*del+szB))/2);

% retrieves the block row/column indices
iRB = arrayfun(@(x)((pOfs(1)+(x-1)*del)+(1:szB)),1:nB(1),'un',0);
iCB = arrayfun(@(x)((pOfs(2)+(x-1)*del)+(1:szB)),1:nB(2),'un',0);

% sets the row/column image blocks 
IR = cellfun(@(x)(nonZeroMean(I(x,:))),iRB,'un',0);
IC = cellfun(@(x)(nonZeroMean(I(:,x)')),iCB,'un',0);

% calculates the mean positive/negative signals
if nDim(2) > 1
    % sets up the negative/positive mean signals
    ZC1 = calcSigMu(cellfun(@(I)(-min(0,I)),IR,'un',0));
    ZC2 = calcSigMu(cellfun(@(I)(max(0,I)),IR,'un',0));
    
    % calculates the coefficient of variances (removes an infeasible)
    zCOV = [calcCOV(ZC1),calcCOV(ZC2)];
    zCOV(isnan(zCOV)) = zTol + 1;

    % determines which is the more feasible signal type
    if all(zCOV > zTol)
        % if neither is a good match, then flag an error 
        ok = false;
        
    elseif zCOV(1) < zCOV(2)
        % case is negative signals give a better representation of frequency
        ZC = ZC1;
        ZR = calcSigMu(cellfun(@(I)(-min(0,I)),IC,'un',0));
    else
        % case is positive signals give a better representation of frequency
        ZC = ZC2;
        ZR = calcSigMu(cellfun(@(I)(max(0,I)),IC,'un',0));    
    end
else
    % sets up the negative/positive mean signals
    ZR1 = calcSigMu(cellfun(@(I)(-min(0,I)),IC,'un',0));
    ZR2 = calcSigMu(cellfun(@(I)(max(0,I)),IC,'un',0));
    
    % calculates the coefficient of variances (removes an infeasible)
    zCOV = [calcCOV(ZR1),calcCOV(ZR2)];
    zCOV(isnan(zCOV)) = zTol + 1;        

    % determines which is the more feasible signal type
    if all(zCOV > zTol)
        % if neither is a good match, then flag an error 
        ok = false;
    
    elseif zCOV(1) < zCOV(2)
        % case is negative signals give a better representation of frequency
        ZR = ZR1;
        ZC = calcSigMu(cellfun(@(I)(-min(0,I)),IR,'un',0));
    else
        % case is positive signals give a better representation of frequency
        ZR = ZR2;
        ZC = calcSigMu(cellfun(@(I)(max(0,I)),IR,'un',0));   
    end    
end

%
if ~ok
    % closes the waitbar figure
    h.closeProgBar()
    
    % outputs an error message to screen
    eStr = sprintf(['There was an error in identifying a repeated ',...
                   'pattern within the search region. Either ',...
                   'reposition the search region or try setting ',...
                   'the sub-regions manually.']);
    waitfor(msgbox(eStr,'Repeated Pattern Not Found!','modal'))
               
    % returns empty arrays
    [ZR,ZC] = deal([]);
end

%
function Ymn = nonZeroMean(Y)

% memory allocation
Ymn = zeros(1,size(Y,2));

% determines if there are any non-zero values
ii = abs(Y)>0;
if any(ii(:))
    jj = any(ii,1);
    Ymn(jj) = cellfun(@(x,y)...
                    (mean(x(y))),num2cell(Y(:,jj),1),num2cell(ii(:,jj),1));
end

% --- calculates the weighted signal mean 
function Z = calcSigMu(Z0)

%
zCOV = cellfun(@(x)(calcCOV(x)),Z0);
if all(isnan(zCOV))
    Q = ones(size(Z0))/length(Z0);
else
    % calculates the signal weights (removes any NaN values)
    Q = 1./zCOV;
    Q = Q/nansum(Q);
    Q(isnan(Q)) = 0;
end

% calculates the overall signal mean
Zc = cellfun(@(x,y)(x*y),num2cell(Q),Z0,'un',0);
Z = smooth(nansum(cell2mat(Zc(:)),1));

% --- calculates the coefficient of variance in difference times for the
%     most prominent peaks, given by P
function zCOV = calcCOV(Z)

% parameters
pTol = 0.30;
pkTol = 0.50;

% removes any non-prominent peaks and calculates the distance btwn them
[~,tPk,~,P] = findpeaks(Z/nanmax(abs(Z)),'MinPeakHeight',pkTol);
tPk = tPk(P/max(P) > pTol);
if length(tPk) <= 2
    zCOV = NaN;
else
    dtPk = pdist2(tPk,tPk);

    % calculates the coefficient of variance in the differences of the 
    % spatial points
    dT = abs(diff(dtPk(:,1)));
    zCOV = std(dT)/mean(dT);
end

% --- calculates the outline coordinate fo the binary mask, BC
function [xC,yC,pOfs] = getBinaryCoords(BC)

% initialisations
szL = size(BC);
pOfs = szL([2,1])/2;

% calculates the final object outline coordinates 
c = contourc(double(BC),0.5*[1,1]);
xC = roundP(c(1,2:end)'-pOfs(1));
yC = roundP(c(2,2:end)'-pOfs(2));