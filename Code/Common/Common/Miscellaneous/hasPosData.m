% --- determines if the positional data has been calculated
function isOK = hasPosData(pData)

% determines if the update is possible
isOK = ~isempty(pData);
if (isOK)
    isOK = isOK && isfield(pData,'fPos'); 
end