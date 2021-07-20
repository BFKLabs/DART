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

% % sets the sub-region data struct into the solution data struct
% snTot.iMov.ok = any(snTot.iMov.flyok,1)';

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