% --- retrieves the fly count for the sub-region, iApp
function nFlyR = getRegionFlyCount(iMov,iApp)

% retrieves the fly count for the region, iApp
if detMltTrkStatus(iMov)
    % case is multi-tracking
    nFlyR = iMov.pInfo.nFly(iApp);
else
    % case is single-tracking
    [iCol,~,iRow] = getRegionIndices(iMov,iApp);
    nFlyR = iMov.nFlyR(iRow,iCol); 
end