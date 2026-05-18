% --- retrieves the log-file object (based on the logging mode)
function logFile = getLogFile(exObj)

% retrieves the logfile based on the logging type
if exObj.isWebCam || exObj.isMemLog
    % case is logging frames to memory
    logFile = exObj.logFile;    
else
    % case is logging frames to disk
    logFile = exObj.objIMAQ.DiskLogger;
end

