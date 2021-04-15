% --- determines an estimate of the circle centres/radii from the 2D
%     cross-correlation of the candidate image with a circle template
function [iMov,R,X,Y,ok] = detImageCircles(I,iMov,hQ)

% if the number of circles is high, then use the new detection algo
[iMov,R,X,Y,ok] = detImageCirclesNew(I,iMov);

% if it failed, then try the old algorithm
if (~ok)        
    [iMov,R,X,Y,ok] = detImageCirclesPrev(I,iMov,hQ);    
end
    
%-------------------------------------------------------------------------%
%                    NEW DETECTION ALGORITHM FUNCTIONS                    %
%-------------------------------------------------------------------------%

% --- determines an estimate of the circle centres/radii from the 2D
%     cross-correlation of the candidate image with a circle template
function [iMov,R,X,Y,ok] = detImageCirclesNew(I,iMov)

% global variables
global RnwTol Rmax 

% sets the global image
ok = true;
iCG = floor(iMov.posG(1)):ceil(sum(iMov.posG([1 3])));
iRG = floor(iMov.posG(2)):ceil(sum(iMov.posG([2 4])));
[iCG,iRG] = deal(iCG((iCG>0)&(iCG<=size(I,2))),iRG((iRG>0)&(iRG<=size(I,1))));

% creates the waitbar figure
h = ProgBar('Initial Circle Radius Estimate','Automatic Region Detection'); 
pause(0.05)

%
if ~isfield(iMov,'autoP')
    R0 = ceil(cellfun(@length,iMov.iCT)/2);
    
elseif isempty(iMov.autoP)
    R0 = ceil(cellfun(@length,iMov.iCT)/2);
    
else
    [~,A,P] = getGroupIndex(getExclusionBin(iMov,[],1,1),'Area','Perimeter');
    R0 = ceil(2*A/P);    
end

% initialisations
nRow = max(sum(reshape(iMov.nTubeR(:),[iMov.nCol iMov.nRow]),2));
[pdR,dim] = deal([0.80 1.20],[iMov.nCol,nRow]);

try       
    % sets the adjusted global image    
    IG = imadjust(uint8(I(iRG,iCG)),stretchlim(uint8(I(iRG,iCG))),[]);
    
    % determines the regions over the columns/rows
    h.Update(1,'Grouping Circle Centres By Row/Column',0.2);
    [pCnw,Rnw,xG,yG,idxC,idxR,TypeMx] = ...
                        detInitCircleCentres(IG,roundP(max(R0).*pdR),dim);    
    [dZ,A] = deal(zeros(size(pCnw)));

    % sets the column indices for each circle centre
    h.Update(1,'Determining Column Groupings',0.4);
    [~,iSX] = sort(xG);
    for i = 1:length(iSX)
        % sets the column indices
        ii = idxC == iSX(i);    
        A(ii,1) = i;    

        % calculates the offset distance for each circle centre
        dZ(ii,1) = pCnw(ii,1) - calcWeightedMean(pCnw(ii,1));
    end

    % sets the row indices for each circle centre
    h.Update(1,'Determining Row Groupings',0.6);
    [~,iSY] = sort(yG);
    for i = 1:length(iSY)
        % sets the column indices
        ii = idxR == iSY(i);    
        A(ii,2) = i;    

        % calculates the offset distance for each circle centre
        dZ(ii,2) = pCnw(ii,2) - calcWeightedMean(pCnw(ii,2));    
    end

    % sets the global indices for each circle centre
    h.Update(1,'Determining Final Indices',0.8);
    indG = cell(nRow,iMov.nCol);
    for i = 1:size(indG,1)
        for j = 1:size(indG,2)
            % determines the circles the belong to the current row/column
            ii = find((A(:,1) == j) & (A(:,2) == i));
            if (length(ii) > 1)
                % if there is more than one circle, then determine the circle
                % with the least distance between the others in the row/column
                [~,imn] = min(sqrt(sum(dZ(ii,:).^2,2)));
                ii = ii(imn);
            end

            % sets the final index
            indG{i,j} = ii;
        end
    end

    % determines if there are any empty groupings
    iGrpE = cellfun(@isempty,indG);
    if any(iGrpE(:)) && ((iMov.nCol*iMov.nTube) > 1)
        % if so, then loop through each empty element correcting them
        [ok,indG,Rnw,pCnw] = detMissingCirclePara(...
                                    iMov,IG,iGrpE,indG,pCnw,Rnw,TypeMx);
        if (~ok)
            % if the detection failed, then exit the function
            [R,X,Y,ok] = deal([],[],[],false);

            % updates and closes the waitbar
            h.Update(1,'Automatic Dectection Failed!',1); pause(0.05);
            h.closeProgBar()
            
            % exits the function
            return
        end                
    end
    
    % sets the final x/y centre coordinates and the maximum radii
    R = max(cellfun(@(x)(Rnw(x)),indG(:)));
    X = cellfun(@(x)(pCnw(x,1)),indG) + (iCG(1)-1);
    Y = cellfun(@(x)(pCnw(x,2)),indG) + (iRG(1)-1);
    
    % sets the lower/upper tolerances on the radii
    [pLo,pHi] = deal(0.10,0.02);
    [RnwTol,Rmax] = deal(floor(R*(1-pLo)),ceil(R*(1+pHi)));   

    % closes the waitbar figure (and remove the resegmentation frames from the
    % sub-image data struct)
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

% --- calculates the parameters for the missing circles
function [ok,indG,R,pC] = ...
                    detMissingCirclePara(iMov,IG,iGrpE,indG,pC,R,TypeMx)

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
    [pCL,R(end+1)] = optCircleDetectPara(IGL,rTol,1,TypeMx);
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
while (1)        
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
if (numel(X) > 1)
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
while (cont)
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
        if (size(Xc,1) > 1)
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
    if (Dmx > sqrt(2))
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
if (isnan(fCount))
    eStr = sprintf(['Warning! You may have set the outer region to be too ',...
                    'small. This could reduce the accuracy of the region ',...
                    'placement algorithm.\n\nYou may need to reset the outer ',...
                    'region and re-run the circle detection.']);
    waitfor(warndlg(eStr,'Circle Detection Warning','modal'));
end

% --- objective function for optimising the centre of the circles
function F = optFunc(z,IT,IR)

% calculates the maximum residual
if (any(abs(z) > 1))
    % shift is infeasible
    F = 1e10;
else
    % shifts the local residual image and takes the cross-correlation
    IT = conv2(IT,[z(2); 1-z(2)]*[z(1), 1-z(1)],'same');
    IXnw = normxcorr2(IT,IR); 

    % calculates the shifted image and calculates the mean shift
    F = -max(IXnw(:));    
end

function [pCnw,Rnw,xG,yG,idxC,idxR,Tmx] = detInitCircleCentres(IG,rTol,dim)    
    
% intialisations and memory allocation
[nCirc,Type] = deal(prod(dim),{'dark','bright'});
[xG0,yG0,idxC0,idxR0,pCnw0,Rnw0] = deal(cell(length(Type),1));
[xSD,ySD] = deal(zeros(2,1));

%
for i = 1:length(Type)
    % optimises the circle parmeters
    [pCnw0{i},Rnw0{i}] = optCircleDetectPara(IG,rTol,nCirc,Type{i});

    % groups the circle centers by the required dimensions
    [idxC0{i},xG0{i}] = kmeans(pCnw0{i}(:,1),dim(1));
    [idxR0{i},yG0{i}] = kmeans(pCnw0{i}(:,2),dim(2));
    [xSD(i),ySD(i)] = deal(std(diff(sort(xG0{i}))),std(diff(sort(yG0{i}))));
end

% returns the type that has the least variance in x/y position
[~,i0] = min(xSD.*ySD);
[pCnw,Rnw,xG] = deal(pCnw0{i0},Rnw0{i0},xG0{i0});
[yG,idxC,idxR,Tmx] = deal(yG0{i0},idxC0{i0},idxR0{i0},Type{i0});

function [pCnw,Rnw] = optCircleDetectPara(IG,rTol,nCirc,Type)

% initialisations
wState = warning('off','all');
[sTol,dsTol,sDir] = deal(0.995,0.01,0);

% determines the circle centres from the adjusted image    
while (1)
    [pCnw,Rnw] = imfindcircles(IG,rTol,...
        'ObjectPolarity',Type,'Sensitivity',sTol,'Method','TwoStage');
    if (length(Rnw) < nCirc)
        sTol = sTol + dsTol;
        if (sDir == -1); dsTol = dsTol/2; end
        sDir = 1;            
    elseif (length(Rnw) > 1.1*nCirc)
        sTol = sTol - dsTol;
        if (sDir == 1); dsTol = dsTol/2; end
        sDir = -1;
    else
        break;
    end
end

% resets the warnings to their original state
warning(wState)