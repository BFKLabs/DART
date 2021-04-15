% --- scales the position values back to pixel values for a given apparatus
function [dPx,dPy,Rad,pC,indR,indC] = get2DCoordsBG(snTot,iApp,indFrm)

% sets the solution file type
if ~isfield(snTot,'Type')
    Type = 0;
else
    if isfield(snTot.iMov.autoP,'XC')
        Type = 2;
    else
        Type = snTot.Type;
    end
end

% resets the background image
snTot.iMov = resetBGImages(snTot.iMov);

% retrieves the x/y coordinates and other important quantities
[sFac,hasApp] = deal(snTot.sgP.sFac,~isempty(iApp));
if (hasApp)    
    [Px,Py,iMov] = deal(snTot.Px(iApp),snTot.Py(iApp),snTot.iMov);        
else
    [Px,Py,iMov,iApp] = deal(snTot.Px,snTot.Py,snTot.iMov,1);
end

% memory allocation and parameters
nApp = length(iApp);
[dPx,dPy,Rad,pC,indR,indC] = deal(cell(nApp,1));

% determines the non-rejected fly tubes
if size(Px{1},2) == size(iMov.flyok,1)
    if hasApp
        fok = num2cell(iMov.flyok(:,iApp),1);
    else
        fok = num2cell(iMov.flyok,1);
    end
else
    fok = cellfun(@(x,y)(any(~isnan(x),1) & any(~isnan(y),1)),Px,Py,'un',0);
end

% set the x/y coordinates in pixel reference frame
fok = reshape(fok,size(Px));
PxNw = cellfun(@(x,y)(x(:,y)/sFac),Px,fok,'un',0);
PyNw = cellfun(@(x,y)(x(:,y)/sFac),Py,fok,'un',0);         
                                
% sets the extreme x/y-locations of the data points
nFrm = size(PxNw{1},1);
[xMean,yMean] = deal(cell(1,nApp));
for i = 1:length(PxNw)
    xMean{i} = num2cell(nanmean(PxNw{i},1)');
    yMean{i} = num2cell(nanmean(PyNw{i},1)');
end

% sets the locations of the ends of the regions
xEnd = cellfun(@(x)(x(1)+[0,x(3)]),iMov.pos(:),'un',0);

% sets the x/y coordinates of the circle centres
[X0,Y0] = getCirclePara(iMov.autoP,{'X0','Y0'});
switch Type
    case 0
        % sets the row index arrays
        if (iscell(iMov.iR{1}))
            iR = cell2cell(iMov.iR);       
        else
            iR = iMov.iR;    
        end    

        % for the old solution file version, offset the y-position
        Y0 = Y0 - min(cellfun(@(x)(x(1)-1),iR)); 
        
    case 2
        % case is version 2 algorithm tracking type
        indReg = setRegionIndexMap(iMov,X0);        
end

% determines the indices of the circles wrt the regions
ind = cell(length(PxNw),1);
for i = 1:length(ind)
    ind{i} = cellfun(@(x,y)(argMin...
                    (sqrt((X0-x).^2+(Y0-y).^2),1)),xMean{i},yMean{i});
end

% memory allocation
for i = 1:nApp
    % determines the sub-region column indices for each fly in the group
    indC{i} = cellfun(@(x)(find...
                   (cellfun(@(y)((x>=y(1)) && (x<=y(2))),xEnd))),xMean{i});
        
    % optimises the circle centre/radii
    [pCF,pC{i},RadNw] = optCirclePara(iMov,indC{i},Type);
    PxEx = num2cell([floor(min(PxNw{i},[],1))',ceil(max(PxNw{i},[],1))'],2);
    PyEx = num2cell([floor(min(PyNw{i},[],1))',ceil(max(PyNw{i},[],1))'],2);
    
    % calculates the mean location of the path extremities
    PxMn = cellfun(@mean,PxEx);
    PyMn = cellfun(@mean,PyEx);
    
    % determines the sub-region row indices for each fly in the group
    indR{i} = arrayfun(@(x,y)(detLikelyRegionIndex(x,y,pCF)),PxMn,PyMn);
                
    % calculates the x/y-location difference to the circle centre      
    [xC,yC] = deal(pC{i}(indR{i},1),pC{i}(indR{i},2));
    dPx{i} = PxNw{i} - repmat(xC(:)',nFrm,1);
    dPy{i} = PyNw{i} - repmat(yC(:)',nFrm,1);  
    Rad{i} = RadNw(indR{i});
end

%
if nargin == 3
    dPx = cellfun(@(x)(x(indFrm,:)),dPx,'un',0);
    dPy = cellfun(@(x)(x(indFrm,:)),dPy,'un',0);
end

% sets the cell arrays as numerical arrays (if only one sub-region)
if nApp == 1
    [dPx,dPy,Rad] = deal(dPx{1},dPy{1},Rad{1});
    [pC,indR,indC] = deal(pC{1},indR{1},indC{1});
end

% --- determines the likely sub-region indices based on the outline coords
function indR = detLikelyRegionIndex(xMn,yMn,pCF)

% determines which sub-region the mean extremities lie within
indR = find(cellfun(@(z)(any(inpolygon(xMn,yMn,z(:,1),z(:,2)))),pCF));
if isempty(indR)
    % if there is no match, then determine the sub-region which is closest
    pCFmn = cell2mat(cellfun(@(x)(mean(x,1)),pCF,'un',0));
    indR = argMin(pdist2(pCFmn,[xMn,yMn]));
end

% --- sets up the region index map array 
function indR = setRegionIndexMap(iMov,X0)

% retrieves the circle parameters
indR = NaN(size(X0));

% sets the use flags
nTubeR = getSRCount(iMov);
if isfield('iMov','isUse')
    isUse = iMov.isUse;
else
    isUse = arrayfun(@(n)(true(n,1)),nTubeR,'un',0);
end

% determines the max sub-region count over all the rows
nSRMx = max(nTubeR,[],2);

% sets the region indices
[nR,nC] = size(isUse);
for iR = 1:nR
    for iC = 1:nC
        % sets the over all global index and the row offset
        iG = (iR-1)*nC + iC;
        if iR == 1
            iOfsR = 0;
        else
            iOfsR = sum(nSRMx(1:(iR-1)));
        end
        
        % updates the row indices
        iRnw = iOfsR + (1:length(isUse{iR,iC}));
        indR(iRnw,iC) = iG*isUse{iR,iC};
    end
end