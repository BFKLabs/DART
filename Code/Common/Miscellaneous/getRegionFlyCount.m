% --- retrieves the fly count for the sub-region, iApp
function nFlyR = getRegionFlyCount(iMov,iApp)

% retrieves the fly count for the region, iApp
[iCol,~,iRow] = getRegionIndices(iMov,iApp);
nFlyR = iMov.nFlyR(iRow,iCol); 