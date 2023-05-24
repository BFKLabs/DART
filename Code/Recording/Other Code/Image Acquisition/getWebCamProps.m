% --- retrieves the webcam property fields
function [fldNames,infoSrc] = getWebCamProps(objIMAQ)

% retrieves the device and property info fieldnames
pStrDev = fieldnames(objIMAQ);
[infoSrc,pStrInfo] = combineDataStruct(objIMAQ.pInfo);

% retrieves the fieldnames that are common to the webcam
fldNames = intersect(pStrInfo,pStrDev,'Stable');
