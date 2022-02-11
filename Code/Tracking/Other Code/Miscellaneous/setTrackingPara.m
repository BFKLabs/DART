% --- sets the tracking parameter within the parameter struct, bgP
function bgP = setTrackingPara(bgP,pType,pStr,pVal)

% retrieves the sub-struct field
bgPS = getStructField(bgP,pType);

% updates the tracking parameter struct with the sub-struct field
bgP = setStructField(bgP,pType,setStructField(bgPS,pStr,pVal));
