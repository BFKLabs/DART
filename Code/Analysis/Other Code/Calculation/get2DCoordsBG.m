% --- scales the position values back to pixel values for a given apparatus
function [dPx,dPy,Rad] = get2DCoordsBG(snTot,iApp,indFrm)

switch snTot.iMov.pInfo.mShape
    case 'Rectangle'
        % case is the rectangle
        [dPx,dPy,Rad] = get2DCoordsRect(snTot,iApp);
        
    case 'Circle'
        % case is circular regions
        [dPx,dPy,Rad] = get2DCoordsCirc(snTot,iApp);
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

% ------------------------------------ %
% --- RECTANGULAR REGION FUNCTIONS --- %
% ------------------------------------ %

% --- retrieves the 2D coordinates for rectangular regions
function [dPx,dPy,Rad] = get2DCoordsRect(snTot,iApp)

% field retrieval
iMov = snTot.iMov;
pInfo = iMov.pInfo;
isMT = detMltTrkStatus(iMov);

% memory allocation
nApp = max(1,length(snTot.Px));
[dPx,dPy,Rad] = deal(cell(nApp,1));

% calculates the relative x/y-coordinates
for j = 1:length(iApp)  
    i = iApp(j);
    
    if isMT
        % case is multi-tracking
        
        % separates the flies into their separate regions
        cID = snTot.cID{i};
        [~,~,iC] = unique(cID(:,1),'stable');
        indC = arrayfun(@(x)(find(iC==x)),1:max(iC),'un',0);
        
        % retrieves the regions 
        [dPx0,dPy0,Rad0] = deal(cell(1,length(indC)));
        for k = 1:length(indC)
            % determines the row/column indices of the region
            iReg = cID(indC{k}(1),1);
            iCol = mod(iReg-1,pInfo.nCol) + 1;
            iRow = floor((iReg-1)/pInfo.nCol) + 1;
            nFly = pInfo.nFly(iRow,iCol);
            szD = [length(iMov.iC{iCol});length(iMov.iRT{iCol}{iRow})];            
            
            % retrieves the x/y-offset
            xOfs = iMov.iC{iCol}(1) - 1;
            yOfs = iMov.iR{iCol}(iMov.iRT{iCol}{iRow}(1)) - 1;            
            
            % calculates the x/y offsets
            dPx0{k} = snTot.Px{i}(:,indC{k}) - (xOfs + szD(1)/2);
            dPy0{k} = snTot.Py{i}(:,indC{k}) - (yOfs + szD(2)/2);
            
            % sets the region dimensions
            Rad0{k} = repmat(szD,1,nFly);
        end
        
        % combines the data from the regions into a cell single element
        dPx{i} = cell2mat(dPx0);
        dPy{i} = cell2mat(dPy0);
        Rad{i} = cell2mat(Rad0);
    end
end

% --------------------------------- %
% --- CIRCULAR REGION FUNCTIONS --- %
% --------------------------------- %

% --- retrieves the 2D coordinates for circular regions
function [dPx,dPy,Rad] = get2DCoordsCirc(snTot,iApp)

% runs the function depending on the soluton file format
if isfield(snTot,'cID')
    % case is the new file format
    [dPx,dPy,Rad] = get2DCoordsBGNew(snTot,iApp);
else
    % case is the old file format
    [dPx,dPy,Rad] = get2DCoordsBGOld(snTot,iApp);
end

% --- runs the new version of the function
function [dPx,dPy,Rad] = get2DCoordsBGNew(snTot,iApp)

% parameters
nBin = 360;
pDTol = 0.9;
pCover = 0.75;

% field retrieval
isMT = detMltTrkStatus(snTot.iMov);
[cID,iMov] = deal(snTot.cID,snTot.iMov);
[sFac,hasApp,fok] = deal(snTot.sgP.sFac,~isempty(iApp),iMov.flyok);
[X0,Y0] = getCircCentreCoords(iMov);

% memory allocation
szG = size(X0);
nApp = max(1,length(snTot.Px));
[dPx,dPy,Rad] = deal(cell(nApp,1));

% retrieves the x/y coordinates and other important quantities
if hasApp  
    [Px,Py] = deal(snTot.Px,snTot.Py);        
else
    [Px,Py,iApp] = deal(snTot.Px,snTot.Py,1);
end

% calculates the relative x/y-coordinates
for j = 1:length(iApp)  
    i = iApp(j);
    if isMT
        % calculates the relative coordinates
        [xOfs,yOfs] = deal(X0(j),Y0(j)-iMov.iR{j}(1)+1);
        [dPx{i},dPy{i}] = deal(Px{i}/sFac-xOfs,Py{i}/sFac-yOfs);
        
        % sets the radii values for each sub-region in the group
        if length(iMov.autoP.R) == 1
            % case is there is a constant radii value
            Rad{i} = (iMov.autoP.R-1)*ones(sum(fok{i}),1);z
        else
            % case is radii have been set for each sub-region
            Rad{i} = iMov.autoP.R(indG)-1;
        end        
    else
        % retrieves the indices of the grid locations
        indG = sub2ind(szG,cID{i}(fok{i},1),cID{i}(fok{i},2));
        Rad{i} = iMov.autoP.R(indG)-1;
        
        % calculates the initial relative x/y coordinates
        [Px{i},Py{i}] = deal(Px{i}(:,fok{i}),Py{i}(:,fok{i}));
        dPx{i} = Px{i}/sFac - arr2vec(X0(indG))';
        dPy{i} = Py{i}/sFac - arr2vec(Y0(indG))';   
        
        %
        for k = 1:size(Px{i},2)
            % determines the points in the outer region
            D = sqrt(dPx{i}(:,k).^2 + dPy{i}(:,k).^2);
            isOut = D > pDTol;
            
            % if there are no points in the outer region then continue
            if ~any(isOut)
                continue
            end
            
            % determines outer region coverage proportion
            phiP = calcPhaseAngle(dPx{i}(:,k),dPy{i}(:,k));
            idxP = max(1,round(nBin*phiP/(2*pi)));
            if length(unique(idxP)) > pCover*nBin
                % determines the minimum enclosed circle
                try
                kk = convhull(dPx{1}(:,k),dPy{1}(:,k));
                objM = MinEncloseCircle([dPx{i}(kk,k),dPy{i}(kk,k)]);
                catch
                    a = 1;
                end
                
                %
                Rad{i}(k) = objM.cP.R;                
                dPx{i}(:,k) = Px{i}(:,k)/sFac-(X0(indG(k))+objM.cP.pC(1));
                dPy{i}(:,k) = Py{i}(:,k)/sFac-(Y0(indG(k))+objM.cP.pC(2));                
            end
        end        
    end        
end

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

% --- calculates the phase angle
function phiP = calcPhaseAngle(X,Y)

phiP = wrapTo2Pi(atan2(Y,X));