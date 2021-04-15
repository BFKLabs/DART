% --- determines if the user is using multi-fly tracking
function isMultiTrack = detIfMultiTrack(iMov)

if isfield(iMov.bgP,'algoType')
    isMultiTrack = strContains(iMov.bgP.algoType,'multi');
else
    isMultiTrack = false;
end