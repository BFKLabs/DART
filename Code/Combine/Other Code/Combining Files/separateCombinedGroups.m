% --- separates the combined groups
function [snTot,iMov] = separateCombinedGroups(snTot)

% retrieves the initial struct fields
[appPara,iMov] = deal(snTot.appPara,snTot.iMov);
[pMapPx,Px] = deal(snTot.pMapPx,snTot.Px);
[pMapPy,Py] = deal(snTot.pMapPy,snTot.Py);
[iRT,flyok,yTube] = deal(iMov.iRT,iMov.flyok,iMov.yTube);

if ~iscell(iMov.iR{1})
    return
end

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
iMov.ok = false(length(iMov.iR),1);
for i = 1:length(ii)
    iMov.flyok(1:sum(jj{i}),i) = flyok(jj{i},ii(i));
    iMov.ok(i) = appPara.ok(ii(i));
end

% resets the sub-region data struct
snTot.iMov = iMov;