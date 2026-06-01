% --- determines if the recording device is currently running
function isDevRun = isDeviceRunning(obj)

if obj.isTest
    % case is running a test
    isDevRun = false;

elseif obj.isWebCam
    % case is a webcam object
    if isempty(obj.hTimer)
        isDevRun = false;
    elseif isstruct(obj.hTimer) || isvalid(obj.hTimer)
        isDevRun = strcmp(obj.hTimer.Running,'on');
    else
        isDevRun = false;
    end
    
elseif isVidDev(obj.objIMAQ)
    % case is a imaq.VideoDevice
    if isempty(obj.hTimer)
        isDevRun = false;
    elseif isstruct(obj.hTimer) || isvalid(obj.hTimer)
        isDevRun = strcmp(obj.hTimer.Running,'on');
    end
    
else
    % case is a videoinput object
    isDevRun = isrunning(obj.objIMAQ);
end

