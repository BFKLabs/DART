% --- scales the position values back to pixel values for a given apparatus
function [dPx,dPy,Rad] = get2DCoordsBG(snTot,iApp,indFrm)

% runs the function depending on the soluton file format
if isfield(snTot,'cID')
    % case is the new file format
    [dPx,dPy,Rad] = get2DCoordsBGNew(snTot,iApp);
else
    % case is the old file format
    [dPx,dPy,Rad] = get2DCoordsBGOld(snTot,iApp);
end

% reduces the arrays for the specified number of frames (if procided)
if exist('indFrm','var')
    ii = ~cellfun('isempty',dPx);
    dPx(ii) = cellfun(@(x)(x(indFrm,:)),dPx(ii),'un',0);
    dPy(ii) = cellfun(@(x)(x(indFrm,:)),dPy(ii),'un',0);
end

% sets the cell arrays as numerical arrays (if only one sub-region)
nApp = max(1,length(iApp));
if nApp == 1
    [dPx,dPy,Rad] = deal(dPx{iApp(1)},dPy{iApp(1)},Rad{iApp(1)});
end

% ---------------------------- %
% --- NEW FUNCTION VERSION --- %
% ---------------------------- %

% --- runs the new version of the function
function [dPx,dPy,Rad] = get2DCoordsBGNew(snTot,iApp)

% field retrieval
[cID,iMov] = deal(snTot.cID,snTot.iMov);
[sFac,hasApp,fok] = deal(snTot.sgP.sFac,~isempty(iApp),iMov.flyok);
[X0,Y0] = getCircCentreCoords(iMov);

% memory allocation
nApp = max(1,length(snTot.Px));
isMT = detMltTrkStatus(snTot.iMov);
[dPx,dPy,Rad] = deal(cell(nApp,1));

% retrieves the x/y coordinates and other important quantities
if hasApp  
    [Px,Py] = deal(snTot.Px,snTot.Py);        
else
    [Px,Py,iApp] = deal(snTot.Px,snTot.Py,1);
end

% reduces down the acceptance flag array
if isMT
    
end

% reduces down the x/y-coordinates
i0 = find(~cellfun('isempty',Px),1,'first');
[szG,nFrm] = deal(size(X0),size(Px{i0},1)); 

% calculates the relative x/y-coordinates
for j = 1:length(iApp)  
    i = iApp(j);
    if isMT
        [xOfs,yOfs] = deal(X0(j),Y0(j)-iMov.iR{j}(1)+1);
        [dPx{i},dPy{i}] = deal(Px{i}/sFac-xOfs,Py{i}/sFac-yOfs);
    else
        % retrieves the indices of the grid locations
        indG = sub2ind(szG,cID{i}(fok{i},1),cID{i}(fok{i},2));

        % calculates the x/y coordinates (wrt the circle centres)
        dPx{i} = Px{i}(:,fok{i})/sFac - repmat(arr2vec(X0(indG))',nFrm,1);
        dPy{i} = Py{i}(:,fok{i})/sFac - repmat(arr2vec(Y0(indG))',nFrm,1);
    end
        
    % sets the radii values for each sub-region in the group
    if length(iMov.autoP.R) == 1
        % case is there is a constant radii value
        Rad{i} = (iMov.autoP.R-1)*ones(sum(fok{i}),1);z
    else
        % case is radii have been set for each sub-region
        Rad{i} = iMov.autoP.R(indG)-1;
    end
end

% ---------------------------- %
% --- OLD FUNCTION VERSION --- %
% ---------------------------- %

% --- runs the old version of the function
function [dPx,dPy,Rad] = get2DCoordsBGOld(snTot,iApp)

% memory allocation and parameters
nApp = max(1,length(iApp));
[sFac,hasApp] = deal(snTot.sgP.sFac,~isempty(iApp));
[dPx,dPy,Rad,pC,indR,indC] = deal(cell(nApp,1));

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
if hasApp    
    [Px,Py,iMov] = deal(snTot.Px(iApp),snTot.Py(iApp),snTot.iMov);        
else
    [Px,Py,iMov,iApp] = deal(snTot.Px,snTot.Py,snTot.iMov,1);
end

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
    xMean{i} = num2cell(mean(PxNw{i},1,'omitnan')');
    yMean{i} = num2cell(mean(PyNw{i},1,'omitnan')');
end

% sets the locations of the ends of the regions
xEnd = cellfun(@(x)(x(1)+[0,x(3)]),iMov.pos(:),'un',0);

% sets the x/y coordinates of the circle centres
[X0,Y0] = getCirclePara(iMov.autoP,{'X0','Y0'});
switch Type
    case 0
        % sets the row index arrays
        if iscell(iMov.iR{1})
            iR = cell2cell(iMov.iR);       
        else
            iR = iMov.iR;    
        end    

        % for the old solution file version, offset the y-position
        Y0 = Y0 - min(cellfun(@(x)(x(1)-1),iR));            
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

% --- determines the likely sub-region indices based on the outline coords
function indR = detLikelyRegionIndex(xMn,yMn,pCF)

% determines which sub-region the mean extremities lie within
indR = find(cellfun(@(z)(any(inpolygon(xMn,yMn,z(:,1),z(:,2)))),pCF));
if isempty(indR)
    % if there is no match, then determine the sub-region which is closest
    pCFmn = cell2mat(cellfun(@(x)(mean(x,1)),pCF,'un',0));
    indR = argMin(pdist2(pCFmn,[xMn,yMn]));
end
