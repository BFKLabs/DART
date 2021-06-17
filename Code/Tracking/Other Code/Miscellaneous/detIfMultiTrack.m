% --- determines if the user is using multi-fly tracking
function isMultiTrack = detIfMultiTrack(iMov)

if ~isfield(iMov,'bgP')
    isMultiTrack = false;
elseif ~isfield(iMov.bgP,'algoType')
    isMultiTrack = false;
else
    isMultiTrack = strContains(iMov.bgP.algoType,'multi');    
end