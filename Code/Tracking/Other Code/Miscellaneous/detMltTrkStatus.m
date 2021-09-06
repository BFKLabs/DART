% --- determines if the user is using multi-fly tracking
function isMTrk = detMltTrkStatus(iMov)

if ~isfield(iMov,'bgP')
    isMTrk = false;
elseif ~isfield(iMov.bgP,'algoType')
    isMTrk = false;
else
    isMTrk = strContains(iMov.bgP.algoType,'multi');    
end