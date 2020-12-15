% --- determines the 
function iMov = detGenRegions(iMov,I,dI)

% creates a waitbar figure
wStr = {'Initialising General Sub-Region Detection'};
h = ProgBar(wStr,'General Sub-Region Detection');

% parameters and initialisations
[xMinG,xMaxG,yMinG,yMaxG,pR,iterMx] = deal(1e10,0,1e10,0,0.95,5);
[nApp,sz,iter] = deal(iMov.nRow*iMov.nCol,size(I),1);
[Nc,nDil] = deal(nApp*iMov.nTube,3);
[szMx,avgSz0] = deal(length(iMov.iC{1}).^2,roundP(iMov.posG(4)/(iMov.nCol*2)));

% memory allocation
iApp = zeros(iMov.nRow*iMov.nTube,iMov.nCol);
autoP = struct('X',[],'Y',[],'XG',[],'YG',[],'XC',[],'YC',[],...
               'B',[],'BT',[],'Type','General');
[autoP.X,autoP.Y,autoP.XC,autoP.YC,autoP.B] = deal(cell(iMov.nTube,nApp));           
[autoP.XG,autoP.YG,autoP.BT] = deal(cell(1,nApp));

% sets up the sub-region grouping index array
X = reshape(1:Nc,size(iApp,1),size(iApp,2))';
for i = 1:nApp
    iRow = floor((i-1)/iMov.nCol) + 1;
    iCol = mod(i-1,iMov.nCol) + 1;
    iApp((iRow-1)*iMov.nTube+(1:iMov.nTube),iCol) = i;
end

% sets the global search region
Bg = false(sz);
iRG = roundP(max(1,iMov.posG(2)):min(sz(1),sum(iMov.posG([2 4]))));
iCG = roundP(max(1,iMov.posG(1)):min(sz(2),sum(iMov.posG([1 4]))));
Bg(iRG,iCG) = true;

% equalises the image
Ieq = adapthisteq(uint8(I));

% determines the likely sub-regions
while (1)
    % determine the likely subregions for the current window size
    [kGrp,ok] = detLikelySubRegions(Ieq,dI,Bg,Nc,szMx,avgSz0,h);
    if (~ok)
        % if the user cancelled, then exit the function
        iMov = [];
        return;
    elseif (~isempty(kGrp))
        % if a feasible group was found, then search exit the loop
        break        
    else
        % otherwise, decrease the search window size
        avgSz0 = roundP(avgSz0*pR);        
        
        % increments the iteration counter. if the count exceeds the
        % maximum, then exit the function with an error message
        iter = iter + 1;
        if (iter > iterMx)
            % closes the waitbar figure
            h.closeProgBar()
            
            % outputs an error to screen
            mStr = {'Initial sub-region failed to find a feasible grouping.';...
                    'Retry the general detection with a larger search region'};
            waitfor(msgbox(mStr,'General Region Detection Failed','modal'))
            
            % exits the function
            iMov = [];
            return
        end
    end    
end

% retrieves the sub-region outlines
[Pc,PcG,Bacc,ok] = getSubRegionOutlines(iMov,Ieq,kGrp,Nc,h);
if (isempty(Pc))
    % if the user cancelled, then exit the function
    iMov = [];
    return;
elseif (~ok)
    % closes the waitbar figure
    h.closeProgBar()

    % outputs an error to screen
    mStr = {'General sub-region detection failed.';
            'This video may not be suitable for this type of sub-region detection.'};
    waitfor(msgbox(mStr,'General Region Detection Failed','modal'))

    % exits the function
    iMov = [];
    return
end

% updates the waitbar figure
h.Update(1,'Setting Final Sub-Region Properties',0.8);

% sets the values for each of the groups
for i = 1:nApp
    % determines the sub-region that belong to the current group
    ii = find(iApp == i);
    
    % sets the sub-region outline coordinates
    autoP.X(:,i) = cellfun(@(x)(max(1,min(sz(2),x(:,1)))),PcG(ii),'un',0);
    autoP.Y(:,i) = cellfun(@(x)(max(1,min(sz(1),x(:,2)))),PcG(ii),'un',0);
    autoP.XC(:,i) = cellfun(@(x)(max(1,min(sz(2),x(:,1)))),Pc(ii),'un',0);
    autoP.YC(:,i) = cellfun(@(x)(max(1,min(sz(1),x(:,2)))),Pc(ii),'un',0);
    
    % determines the extreme x/y coordinates of the group
    xMin = min(cellfun(@min,autoP.X(:,i)));
    xMax = max(cellfun(@max,autoP.X(:,i)));
    yMin = min(cellfun(@min,autoP.Y(:,i)));
    yMax = max(cellfun(@max,autoP.Y(:,i)));  
    
    % updates the global extreme values
    [xMinG,xMaxG] = deal(min(xMinG,xMin),max(xMaxG,xMax));
    [yMinG,yMaxG] = deal(min(yMinG,yMin),max(yMaxG,yMax));
    
    % resets the global row/column indices
    iMov.iC{i} = max(1,floor(xMin)):min(sz(2),ceil(xMax));
    iMov.iR{i} = max(1,floor(yMin)):min(sz(1),ceil(yMax));     
    autoP.BT{i} = false(length(iMov.iR{i}),length(iMov.iC{i}));
    BG = false(size(autoP.BT{i})+(2*nDil));

    % sets the local row/column indices
    yOfs = iMov.iR{i}(1) - 1;
    iMov.iRT{i} = cellfun(@(x)((max(1,floor(min(x)-yOfs))):...
                min(length(iMov.iR{i}),ceil(max(x)-yOfs))),autoP.Y(:,i),'un',0);
    iMov.iCT{i} = 1:length(iMov.iC{i});        
    iMov.xTube{i} = [0 diff(iMov.iC{i}([1 end]))];
    
    % sets the acceptance binary mask for the group and individual regions 
    % and determines the overall outline coordinates of the group
    BaccL = Bacc(iMov.iR{i},iMov.iC{i});   
    [xOfsG,yOfsG,szG] = deal(xMin-(1+nDil),yMin-(1+nDil),size(BG));
    for j = 1:iMov.nTube
        % sets the group/individual acceptance binary masks
        BaccNw = BaccL == X(ii(j));
        autoP.BT{i} = autoP.BT{i} | BaccNw;
        autoP.B{j,i} = BaccNw(iMov.iRT{i}{j},:);
        
        % appends the sub-region binary to the group outline binary
        k = ii(j);
        BG = BG | poly2bin([PcG{k}(:,1)-xOfsG,PcG{ii(j)}(:,2)-yOfsG],szG);
        
        % sets the vertical position of the tubes
        iMov.yTube{i}(j,:) = iMov.iRT{i}{j}([1 end]) - 1;        
    end    
    
    % sets the final group outline coordinates
    BG = bwmorph(bwmorph(BG,'dilate',nDil),'erode',nDil);
    pGrp = bwboundaries(BG);
    [autoP.XG{i},autoP.YG{i}] = deal(pGrp{1}(:,2)+xOfsG,pGrp{1}(:,1)+yOfsG);
end

% calculatese the global positional outline 
[xMinG,xMaxG] = deal(max(1,xMinG),min(xMaxG,sz(2)));
[yMinG,yMaxG] = deal(max(1,yMinG),min(yMaxG,sz(1))); 
iMov.posG = [xMinG,yMinG,(xMaxG-xMinG),(yMaxG-yMinG)];

% updates the automatic detection parameters
iMov.autoP = autoP;

% updates and closes the waitbar figure (if still open)
if ~h.Update(1,'General Sub-Region Detection Complete!',1)
    h.closeProgBar()
end

% --- determines the 
function [kGrp,ok] = detLikelySubRegions(Ieq,dI,Bg,Nc,szMx,avgSz,h)

% initialisations
[kGrp,ok] = deal([],true);

% updates the waitbar figure
if h.Update(1,'Determining Initial Feasible Binary Groups',0.2)
    ok = false;
    return;
end

% parameters
[pLo,pHi,N] = deal(2/3,3/2,100);

% retrieves the outline of the most likely residual groups
dIs = sort(dI(:),'descend');
X = bwmorph(bwmorph(dI>dIs(N),'dilate',2),'remove');

% thresholds the image with the new parameters
Bst0 = sauvolaThresh(Ieq,avgSz*[1 1],0);
if (sum(X(Bst0)) > sum(X(~Bst0)))
    Bst0 = bwmorph(Bst0,'erode');
else
    Bst0 = bwmorph(~Bst0,'erode');
end

% removes any large groups and only includes the 
[iGrp0,Area] = getGroupIndex(Bst0,'Area');
[~,Bst] = detGroupOverlap(bwfill(setGroup(iGrp0(Area<szMx),size(Bst0)),'holes'),Bg);
Bst = bwmorph(bwmorph(Bst,'dilate'),'majority');

% determines the properties of the thresholded binary groups
[iGrp,BB,A,CA] = getGroupIndex(Bst,'BoundingBox','Area','ConvexArea');
aR = BB(:,3)./BB(:,4);    

% determines the groups that close in size/aspect ratio
gMatch = false(length(iGrp));
for i = 1:length(iGrp)
    [dA,daR,dCA] = deal(A/A(i),aR/aR(i),CA/CA(i));    
    gMatch(:,i) = (dA > pLo) & (dA < pHi) & ...
                  (daR > pLo) & (daR < pHi);
%                   (dCA > pLo) & (dCA < pHi) & ...
                  
end

% groups the binary regions of similar size/shape
[jGrp,gMatchS] = deal([],any(gMatch,1));
while (1)
    % determines the next group in the 
    i0 = find(gMatchS,1,'first');
    if (isempty(i0))
        % if there are no more groups, then exit the loop
        break
    else
        % determines the binary regions that match the candidate group
        jGrpNw = find(gMatch(:,i0));        
        if (all(gMatchS(jGrpNw)))
            % if all of the groups have not been included in any other
            % search, then append the group indices to the overall array
            jGrp = [jGrp;{jGrpNw}];
        end
        
        % removes the new groups from the search
        gMatchS(jGrpNw) = false;
    end
end

% removes any groups that have too few elements
jGrp = jGrp(cellfun(@length,jGrp) > Nc/3);

% sets the grouped binary regions with the largest size
if (~isempty(jGrp))
    kGrp = iGrp(jGrp{argMax(cellfun(@(x)(mean(A(x))),jGrp))});
end

% --- determines the outlines coordinates of each sub-region
function [Pc,PcG,Bacc,ok] = getSubRegionOutlines(iMov,Ieq,iGrp,Nc,h)

% parameters and initialisations
[cEqTol,dcEqTol,ok] = deal(0.5,0.1,true);
dTol = max(cellfun(@length,iMov.iC))/8;
[cTol,PcTol,dpOfs,kGrp,sz] = deal(0.5,0.2,{[0 0]},{1},size(Ieq));

% -------------------------------- %
% --- INITIAL REGION DETECTION --- %
% -------------------------------- %

% updates the waitbar figure
if h.Update(1,'Initial Sub-Region Detection',0.4)
    % if the user cancelled, then exit the function
    [Pc,PcG,Bacc] = deal([]);
    return
end

% sets up the binary sub-image stack
[Bsub,pOfs] = setupBinarySubImages(iGrp,sz);
szL = size(Bsub{1});

% determines the groupings
for i = 2:length(Bsub)
    % determines if the new sub-image matches any existing groups
    [cMx,xMx,yMx] = deal(zeros(length(kGrp),1));
    for j = 1:length(kGrp)
        % calculates the cross-correlation
        c = normxcorr2(Bsub{kGrp{j}(1)},Bsub{i});
        
        % determines the value/position of the max x-corr value
        [cMx(j),iMx] = max(c(:));
        [yMx(j),xMx(j)] = ind2sub(size(c),iMx);
    end
    
    %
    [cMxT,iMxT] = max(cMx);
    if (cMxT > cTol)
        % if so, then add the index to the group class array and update
        % the found flag to true
        dpOfs{iMxT}(end+1,:) = mean([xMx(iMxT),yMx(iMxT)],1) - szL([2 1]);
        kGrp{iMxT}(end+1) = i; 
    else
        % if the current sub-region doesn't fit into any existing groups, 
        % then create a new group for the sub-region
        [kGrp{end+1},dpOfs{end+1}] = deal(i,[0 0]); 
    end    
end

% removes any groups with too few members
ii = cellfun(@length,kGrp) > Nc/6;
[kGrp,dpOfs] = deal(kGrp(ii),dpOfs(ii));
[iR,iC] = deal(floor(szL(1)/2)+(1:sz(1)),floor(szL(2)/2)+(1:sz(2)));

% sets the local equalised image
pDim = cellfun(@(x,y)(roundP(pOfs(x,:)+y)),kGrp(:),dpOfs(:),'un',0);
IeqL = cellfun(@(y)(cellfun(@(x)(Ieq(x(2)+(1:szL(1)),x(1)+(1:szL(2)))),...
                        num2cell(y,2),'un',0)),pDim,'un',0);
                    
% calculates the mean shifted image
[P,cEq,PcG0] = deal(cell(1,length(kGrp)));
for i = 1:length(kGrp)
    % shifts the binary images by the corrleation shift amount
    Btmp = cellfun(@(x,dp)(getShiftedImage(double(x),dp(1),dp(2))),...
                        Bsub(kGrp{i}),num2cell(dpOfs{i},2),'un',0);    
    Bmn = mean(cell2mat(reshape(Btmp,[1 1 length(Btmp)])),3) > PcTol;
    PcG0{i} = bwboundaries(bwmorph(rmvGroups(Bmn >= PcTol),'dilate'));
    
    % calculates the mean image and thresholds the final binary 
    IeqLmn = nanmean(cell2mat(reshape(IeqL{i},[1 1 length(IeqL{i})])),3);

    % calculates the equalised cross-correlation (resets to local frame)
    cEqF = normxcorr2(IeqLmn,Ieq);
    cEq{i} = cEqF(iR,iC);
end
   
% keep searching until a feasible group of outlines have been found
while (1)
    % inner loop flag initialisation
    innerOK = true;
    
    %
    for i = 1:length(kGrp)
        % thresholds the cross-corrlation map and determines the max value from
        % each of the binary groups
        xGrp = getGroupIndex(cEq{i} > cEqTol);
        [yC,xC] = ind2sub(sz,cellfun(@(x)(x(argMax(cEq{i}(x),1))),xGrp));
        cEqMx = cellfun(@(x)(max(cEq{i}(x))),xGrp);

        % determines the x/y position clusters. from this, determine the most
        % likely clusters that form the regions
        iP = [detPositionGroup(xC,dTol),detPositionGroup(yC,dTol)]; 
        [xCF,yCF] = detPosGroupCoords(iMov,xC,yC,cEqMx,iP,szL);  

        % sets the final region outline coordinates
        if (isempty(xCF))
            innerOK = false;
            break        
        else
            P{i} = cellfun(@(x,y)([(x+PcG0{i}{1}(:,2)),(y+PcG0{i}{1}(:,1))]),...
                                    num2cell(xCF(:)),num2cell(yCF(:)),'un',0);    
        end
    end

    % removes any extra groups by only including groups of equal size that
    % sum up to the required number of regions
    if (innerOK)
        nPP = cellfun(@numel,P(:)');
        if (sum(nPP) > Nc)
            ii = cellfun(@(x)(sum(nPP(nPP==x))),num2cell(nPP)) == Nc;
            P = P(ii);
        elseif (sum(nPP) < Nc)
            innerOK = false;
        end
    end   
    
    % determines if a feasible number of groups were found
    if (innerOK)
        % if so, then exit the loop
        break
    else
        % otherwise, decrement the tolerance value
        cEqTol = cEqTol - dcEqTol;
        if (cEqTol <= 0)
            % if the tolerance is too low, then exit the function
            [Pc,PcG,Bacc,ok] = deal(false);
            return
        end
    end
end
    
% sets the group index values for each element in the groups
iGrpR0 = cellfun(@(x,y)(x*ones(length(y),1)),num2cell(1:length(P)),P,'un',0);

% --------------------------------------- %
% --- SUB-REGION OUTLINE CALCULATIONS --- %
% --------------------------------------- %
    
% updates the waitbar figure
if h.Update(1,'Sub-Region Outline Detection',0.6)
    % if the user cancelled, then exit the function
    [Pc,PcG,Bacc] = deal([]);
    return
end

% memory allocation
Pc = cell(iMov.nTube*iMov.nRow,iMov.nCol);
iGrpR = zeros(size(Pc));

% determines the column indices of each sub-region
[Pc0,iGrpR0] = deal(cell2cell(P),cell2cell(iGrpR0));
PcMn = cell2mat(cellfun(@(x)(mean(x,1)),Pc0,'un',0));
[~,xSort] = sort(PcMn(:,1));

% aligns the sub-region outline coordinates in space
for i = 1:iMov.nCol
    % determines the sub-regions that belong to the current column
    ii = (i-1)*iMov.nTube + (1:iMov.nTube);
    [PcL,PcMnL,iGrpRL] = deal(Pc0(xSort(ii)),PcMn(xSort(ii),:),iGrpR0(xSort(ii)));

    % sorts sub-regions so that they correspond to the correct row
    [~,ySort] = sort(PcMnL(:,2));
    [Pc(:,i),iGrpR(:,i)] = deal(PcL(ySort),iGrpRL(ySort));
end  

% ---------------------------------------- %
% --- SUB-REGION BOUNDARY CALCULATIONS --- %
% ---------------------------------------- %

% memory allocation
[PcG,PcMn,PcMx] = deal(cell(size(Pc)));
[D,Bacc] = deal(zeros([sz,numel(Pc)]),zeros(sz));

% calculates the distance masks for each sub-region (over all columns)
for i = 1:size(Pc,2)
    % determines the min/max x/y values for each region in the column
    PcMn(:,i) = cellfun(@(x)(min(x,[],1)),Pc(:,i),'un',0);
    PcMx(:,i) = cellfun(@(x)(max(x,[],1)),Pc(:,i),'un',0);
    
    % determines the min/max outline coordinates in the column
    PcMnL = min(cell2mat(PcMn(:,i)),[],1);
    PcMxL = max(cell2mat(PcMx(:,i)),[],1);
    
    % sets the polynomial binary masks for all regions in the column    
    iRL = roundP(max(1,PcMnL(2)):min(sz(1),PcMxL(2)));
    iCL = roundP(max(1,PcMnL(1)):min(sz(2),PcMxL(1)));
    szL = [length(iRL),length(iCL)];
    Bcol = cellfun(@(x)(poly2bin([x(:,1)-(iCL(1)-1),...
                        x(:,2)-(iRL(1)-1)],szL)),Pc(:,i),'un',0); 
    
    % sets the distance masks for each sub-group
    for j = 1:length(Bcol)
        % determines the overall index
        k = (j-1)*iMov.nCol + i;
        
        % sets the distance mask for the sub-group
        BcolT = false(sz);
        BcolT(iRL,iCL) = Bcol{j};
        D(:,:,k) = bwdist(BcolT);        
        
        % appends the sub-region binary to the overall acceptance mask
        Bacc(iRL,iCL) = Bacc(iRL,iCL) + k*Bcol{j};
    end    
end                
           
% determines the min-distance mask to each sub-region
[~,imn] = min(D,[],3);
X = iGrpR.*bwmorph(true(size(Pc)),'erode');

% sets the final sub-region coordinates for each class type
for i = 1:max(iGrpR(:))
    % determines the first interior sub-region of the current class
    [iRow,iCol] = find(X == i,1,'first');
    indG = (iRow-1)*size(Pc,2) + iCol;
    
    % determines the ridge-filtered binary group that overlaps the interior
    % region group and calculates the outline coordinates
    PcGrpZG = bwboundaries(imn == indG);
    
    % calculates the normalised coordinates and the x/y offsets
    [PcMnX,PcMnY] = deal(min(PcGrpZG{1}(:,2)),min(PcGrpZG{1}(:,1)));
    [xOfs,yOfs] = deal(PcMn{iRow,iCol}(1)-PcMnX,PcMn{iRow,iCol}(2)-PcMnY);
    PcGn = [(PcGrpZG{1}(:,2)-PcMnX),(PcGrpZG{1}(:,1)-PcMnY)];
    
    % calculates the region outline coordinates for each binary mask
    for j = find(iGrpR == i)'
        [xOfsL,yOfsL] = deal(PcMn{j}(1)-xOfs,PcMn{j}(2)-yOfs);
        PcG{j} = [(PcGn(:,1)+xOfsL),(PcGn(:,2)+yOfsL)];
    end
end

% --- sets up the local binary images for the x-correlation calculations
function [Bsub,pOfsMn] = setupBinarySubImages(kGrp,sz)

% memory allocation
[nGrp,del] = deal(length(kGrp),15);
[pOfsMn,pOfsMx] = deal(zeros(nGrp,2));

% sets the local images
[xGrp,yGrp] = deal(cell(nGrp,1));
for i = 1:nGrp
    [yGrp{i},xGrp{i}] = ind2sub(sz,kGrp{i});
    pOfsMn(i,:) = [min(xGrp{i}),min(yGrp{i})]-del;
    pOfsMx(i,:) = [max(xGrp{i}),max(yGrp{i})]+del;
end

% resets the min/max 
[H,W] = deal(pOfsMx(:,2)-pOfsMn(:,2),pOfsMx(:,1)-pOfsMn(:,1));
pOfsMn(:,1) = pOfsMn(:,1) - floor((max(W)-W)/2);
pOfsMn(:,2) = pOfsMn(:,2) - floor((max(H)-H)/2);

% determines the local image size
szL = [max(H),max(W)];

% sets the binary images for each group
Bsub = repmat({false(szL)},nGrp,1);
for i = 1:nGrp
    Bsub{i}(glob2loc(kGrp{i},pOfsMn(i,:),sz,szL)) = true;
end

% --- converts indices from a global reference to a frame local reference
function indL = glob2loc(indG,pOfs,sz,szL)

% converts the global indices to coordinates
[yG,xG] = ind2sub(sz,indG);

% calculates the local indices from the local coordinates
indL = sub2ind(szL,yG-pOfs(2),xG-pOfs(1));

% --- determines the position cluster groupings for the vector xC
function iP = detPositionGroup(xC,dTol)

% memory allocation
iP = zeros(size(xC));

% sorts the positional values and determines the cluster indices
[xC,iSort] = sort(xC);
ixC = find(diff([xC(1);xC(:)]) > dTol);

% sets the cluster group indices based on the matches
if (isempty(ixC))
    % no clusters determined
    iP(:) = 1;
else
    for i = 1:(length(ixC)+1)
        % sets the group index based on the cluster grouping
        switch (i)
            case (1) % case is the first cluster
                ii = 1:(ixC(i)-1);
            case (length(ixC)+1) % case is the last cluster
                ii = ixC(i-1):length(xC);
            otherwise % case is the other clusters
                ii = ixC(i-1):(ixC(i)-1);
        end
        
        % sets the new cluster group indices
        iP(iSort(ii)) = i;
    end
end

% --- determines the likely position group coordinates
function [xCF,yCF] = detPosGroupCoords(iMov,xC,yC,cEqMx,iP,szL)

% determines the likely x cluster groups
iPLx = detLikelyPosGroups(iP(:,1),xC,cEqMx,iMov.nCol);
if (isempty(iPLx))
    [xCF,yCF] = deal([]); 
    return; 
end

% determines the likely y cluster groups
iPLy = detLikelyPosGroups(iP(:,2),yC,cEqMx,iMov.nRow*iMov.nTube);
if (isempty(iPLx))
    [xCF,yCF] = deal([]); 
    return;
end

% sets the final coordinates
[xCF,yCF] = deal(NaN(length(iPLy),length(iPLx)));
for j = 1:length(iPLy)
    for k = 1:length(iPLx)
        ii = (iP(:,1)==iPLx(k)) & (iP(:,2)==iPLy(j));
        if (any(ii))
            [xCF(j,k),yCF(j,k)] = deal(xC(ii),yC(ii));
        end
    end
end

% determines if there are any missing positional values
isN = isnan(xCF);
if (any(isN(:)))
    % initialisations
    if (sum(~isN(:)) < 3)
        [xCF,yCF] = deal([]); 
        return;        
    else
        [iY,iX] = find(~isN);
        Fx = scatteredInterpolant(iX,iY,xCF(~isN),'natural');
        Fy = scatteredInterpolant(iX,iY,yCF(~isN),'natural');

        [iYN,iXN] = find(isN);
        [xCF(isN),yCF(isN)] = deal(Fx(iXN,iYN),Fy(iXN,iYN));
    end
end

%
[xCF,yCF] = deal(xCF-szL(2)/2,yCF-szL(1)/2);

% --- 
function iPL = detLikelyPosGroups(iP,P,cEqMx,nMxX)

% determines the number of position groups
[nX,pTol] = deal(max(iP),0.20);

% determines if the number of position groups matches the maximum count
if (rem(nMxX,nX) ~= 0)
    % if not, then determine the likely number of search groups
    if (nX > nMxX)
        % the position groups exceeds the max, so set the search groups to
        % the maximum value
        nS = nMxX;
    else
        % otherwise, determine the maximum search group count that is a
        % multiple of the max value
        nS = find(rem(nMxX,(1:nX-1))==0,1,'last');
    end    
else
    % otherwise, set the likely groups to the position group count
    nS = nX;
end

% determines the likely groups from the x-corr values
iGrp = cellfun(@(x)(find(iP==x)),num2cell(1:nX),'un',0);
Pmn = cellfun(@(x)(mean(P(x))),iGrp);    
cEqMxG = cellfun(@(x)(max(cEqMx(x))),iGrp);        

%
while (1)
    %        
    [~,iSort] = sort(cEqMxG,'descend');
    iPL = sort(iSort(1:nS));

    dP = diff(Pmn(iPL));
    dPmn = calcWeightedMean(dP(:));
    pdPmn = abs((dP-dPmn)/dPmn);

    i0 = find(pdPmn > pTol,1,'first');
    if (isempty(i0))
        break
    else
        cEqMxG(iPL(i0+1)) = 0;
        if (sum(cEqMxG > 0) < nS)
            iPL = [];
            return
        end
    end
end