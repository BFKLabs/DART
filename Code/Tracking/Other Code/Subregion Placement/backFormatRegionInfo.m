% back-formats the region data struct 
function snTot = backFormatRegionInfo(snTot)

% determines if the region information parameter field is set
if ~isfield(snTot.iMov,'pInfo')
    % if not, then add this field based on the existing data
    if iscell(snTot.iMov.iR{1})
        snTot = separateCombinedGroups(snTot);
    end
    
    % re-arranges the regions so that they match spatially 
    snTot = realignRegionInfo(snTot);
end

% ------------------------------ %
% --- OBSOLETE FIELD REMOVAL --- %
% ------------------------------ %

% removes the apparatus sub-region field (obsolete)
if isfield(snTot,'appPara')
    snTot.appPara = rmfield(snTot,'appPara');
end

% removes the isUse index field (obsolete)
if isfield(snTot.iMov,'isUse')
    snTot.iMov = rmfield(snTot.iMov,'isUse');
end

% removes the isUse index field (obsolete)
if isfield(snTot.iMov,'dTube')
    snTot.iMov = rmfield(snTot.iMov,'dTube');
end

% sets the sub-region data struct into the solution data struct
snTot.iMov.ok = any(snTot.iMov.flyok,1)';

% --- re-arranges the regions so that they match spatially 
function snTot = realignRegionInfo(snTot)

% initialisations
iMov = snTot.iMov;
[hasX,hasY] = deal(~isempty(snTot.Px),~isempty(snTot.Py));

% sorts regions in the correct order (from left to right, top to bottom)
xReg = cellfun(@(x)(mean(x)),iMov.iC);
yReg = cellfun(@(x)(mean(x)),iMov.iR);
zReg = 1000*log10(yReg(:)) + log10(xReg(:));
[~,iS] = sort(zReg);

% re-orders the x position/mapping arrays
if hasX
    [snTot.Px,snTot.pMapPx] = deal(snTot.Px(iS),snTot.pMapPx(iS));
end

% re-orders the y position/mapping arrays
if hasY
    [snTot.Py,snTot.pMapPy] = deal(snTot.Py(iS),snTot.pMapPy(iS));
end

% re-orders the other fields
snTot.appPara.Name = snTot.appPara.Name(iS);
[iMov.iR,iMov.iC] = deal(iMov.iR(iS),iMov.iC(iS));
[iMov.iRT,iMov.iCT] = deal(iMov.iRT(iS),iMov.iCT(iS));
[iMov.xTube,iMov.yTube] = deal(iMov.xTube(iS),iMov.yTube(iS));
iMov.flyok = iMov.flyok(:,iS);

% resets the fly counts
iMov.is2D = is2DCheck(iMov);
iMov.nTubeR = reshape(cellfun(@length,iMov.iRT),iMov.nRow,iMov.nCol)';

% retrieves the region data struct information
iMov.pInfo = getRegionDataStructs(iMov);

% updates the grouping indices (based on expt type)
iGrp0 = getRegionGroupIndices(iMov,snTot.appPara.Name);
if iMov.is2D
    % case is a 2D experiment
    iMov.pInfo.iGrp = iGrp0;
else
    % case is a 1D experiment
    for i = 1:iMov.nRow
        for j = 1:iMov.nCol
            iMov.pInfo.iGrp(i,j) = iGrp0(1,(i-1)*iMov.nCol + j);
        end
    end
end

% resets the sub-region data struct
snTot.iMov = iMov;

% --- separates the combined groups
function [snTot,iMov] = separateCombinedGroups(snTot)

% retrieves the initial struct fields
[appPara,iMov] = deal(snTot.appPara,snTot.iMov);
[pMapPx,Px] = deal(snTot.pMapPx,snTot.Px);
[pMapPy,Py] = deal(snTot.pMapPy,snTot.Py);
[iRT,flyok,yTube] = deal(iMov.iRT,iMov.flyok,iMov.yTube);

% separates the column/row index arrays
iMov.iCT = cell2cell(iMov.iCT)';
iMov.xTube = num2cell(cell2mat(iMov.xTube(:)),2)';
[iMov.iR,iMov.iC] = deal(cell2cell(iMov.iR)',cell2cell(iMov.iC)');

% recalculates the row/column indices (from the region outer positions)
xPos = cellfun(@(x)(sum(x([1,3]))),iMov.posO);
iMov.nCol = find(diff(xPos)<0,1,'first');
iMov.nRow = length(xPos)/iMov.nCol;

% sets up the grouping index array
[indG,iOfs] = deal(cell(length(iRT),1),0);
for i = 1:length(indG)
    % calculates the grouping indices
    y0 = [1e6;cellfun(@(x)(x(1)),iRT{i})];
    dy0 = (1-sign(diff(y0)))/2;
    indG{i} = cumsum(dy0) + iOfs;
    
    % increments the offset
    iOfs = iOfs + sum(dy0);    
end

% ---------------------------- %
% --- MEMORY RE-ALLOCATION --- %
% ---------------------------- %

% initialisations
nReg = length(iMov.posO);
[hasX,hasY] = deal(~isempty(Px),~isempty(Py));

% re-allocates memory for the arrays
[snTot.appPara.Name] = deal(cell(1,nReg));
[iMov.yTube,iMov.iRT] = deal(cell(1,nReg));
iMov.nTubeR = zeros(iMov.nRow,iMov.nCol);

% resets the x positional data (if it exists)
if hasX
    snTot.Px = cell(nReg,1);
    snTot.pMapPx = repmat(pMapPx(1),nReg,1);
end

% resets the x positional data (if it exists)
if hasY
    snTot.Py = cell(nReg,1);
    snTot.pMapPy = repmat(pMapPy(1),nReg,1);
end

%
[ii,jj] = deal(zeros(1,nReg),cell(1,nReg));
for i = 1:nReg
    % sets the group/sub-group indices for the current region
    ii(i) = find(cellfun(@(x)(any(x==i)),indG));
    jj{i} = indG{ii(i)} == i;
    
    % sets the fly count for the current region
    iRow = floor((i-1)/iMov.nCol)+1;
    iCol = mod(i-1,iMov.nCol)+1;
    iMov.nFly(iRow,iCol) = sum(jj{i});
    
    % resets the x position/mapping arrays
    if hasX
        snTot.Px{i} = Px{ii(i)}(:,jj{i});
        snTot.pMapPx(i).xMin = pMapPx(ii(i)).xMin(jj{i});
        snTot.pMapPx(i).xMax = pMapPx(ii(i)).xMax(jj{i});
    end
    
    % resets the y position/mapping arrays
    if hasY
        snTot.Py{i} = Py{ii(i)}(:,jj{i});
        snTot.pMapPy(i).xMin = pMapPy(ii(i)).xMin(jj{i});
        snTot.pMapPy(i).xMax = pMapPy(ii(i)).xMax(jj{i});
    end
    
    % resets the tube region vertical positioning
    iMov.yTube{i} = yTube{ii(i)}(jj{i},:);
    iMov.iRT{i} = iRT{ii(i)}(jj{i});
    iMov.nTubeR(iRow,iCol) = sum(jj{i});
    snTot.appPara.Name{i} = appPara.Name{ii(i)};
end

% resets the acceptance flags
iMov.flyok = false(iMov.nTube,length(iMov.iR));
for i = 1:length(ii)
    iMov.flyok(1:sum(jj{i}),i) = flyok(jj{i},ii(i));
end

% resets the sub-region data struct
snTot.iMov = iMov;