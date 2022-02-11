% --- retrieves the parameter value (main field/parameter = pType/pStr)
function pVal = getTrackingPara(bgP,pType,pStr)

% retrieves the main parameter struct field
pVal = getStructField(bgP,pType);
if exist('pStr','var')
    % retrieves the parameter struct sub-field (if provided)
    pVal = getStructField(pVal,pStr);
end