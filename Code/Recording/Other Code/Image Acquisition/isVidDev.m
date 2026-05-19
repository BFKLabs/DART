% --- video device flag
function isVDev = isVidDev(objIMAQ)

isVDev = isa(objIMAQ,'imaq.VideoDevice');
