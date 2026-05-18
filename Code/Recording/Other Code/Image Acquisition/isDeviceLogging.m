% --- determines if the recording device is currently logging
function isDevLog = isDeviceLogging(obj)

if obj.isWebCam
    isDevLog = isDeviceRunning(obj);
elseif obj.isMemLog
    isDevLog = obj.isLogging;
else
    isDevLog = islogging(obj.objIMAQ);
end
