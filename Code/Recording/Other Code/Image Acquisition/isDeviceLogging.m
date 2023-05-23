% --- determines if the recording device is currently logging
function isDevLog = isDeviceLogging(obj)

if obj.isWebCam
    isDevLog = isDeviceRunning(obj);
else
    isDevLog = islogging(obj.objIMAQ);
end
