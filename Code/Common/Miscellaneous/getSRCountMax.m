% --- determines the maximum sub-region count
function nSubMx = getSRCountMax(iMov)

% calculates the max sub-region count over all regions
nSubMx = max(getSRCountVec(iMov));