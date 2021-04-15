% --- determines the maximum sub-region count
function nSubV = getSRCountVec(iMov)

% calculates the max sub-region count over all regions
[nApp,nSub] = deal(length(iMov.iR),getSRCount(iMov));
if numel(nSub) ~= nApp
    nSubV = nSub*ones(nApp,1);
else
    nSubV = arr2vec(nSub);    
end

