% --- determines if the recording device is currently running
function isDevRun = isDeviceRunning(obj)

if obj.isTest
    % case is running a test
    isDevRun = false;

elseif obj.isWebCam
    % case is a webcam object
    if isempty(obj.objIMAQ.hTimer)
        isDevRun = false;
    elseif isstruct(obj.objIMAQ.hTimer)
        isDevRun = strcmp(obj.objIMAQ.hTimer.Running,'on');
    elseif isvalid(obj.objIMAQ.hTimer)
        isDevRun = strcmp(obj.objIMAQ.hTimer.Running,'on');        
    else
        isDevRun = false;
    end
else
    % case is a videoinput object
    isDevRun = isrunning(obj.objIMAQ);
end

