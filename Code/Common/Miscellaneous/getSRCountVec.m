% --- determines the maximum sub-region count
function nSubV = getSRCountVec(iMov)

% calculates the max sub-region count over all regions
[nApp,nSub] = deal(length(iMov.pos),getSRCount(iMov));
if numel(nSub) ~= nApp
    nSubV = max(nSub(:),[],'omitnan')*ones(nApp,1);
else
    nSubV = arr2vec(nSub');    
end

% removes any NaN counts
nSubV(isnan(nSubV)) = 0;
