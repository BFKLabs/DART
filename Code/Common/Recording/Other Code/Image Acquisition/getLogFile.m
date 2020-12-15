% --- retrieves the log-file object (based on the logging mode)
function logFile = getLogFile(objIMAQ)

% global variables
global isMemLog

% retrieves the frame logging mode (if not set)
if (isempty(isMemLog))
    isMemLog = strcmp(objIMAQ.LoggingMode,'memory');
end

% retrieves the logfile based on the logging type
if (isMemLog)
    % case is logging frames to memory
    logFile = get(objIMAQ,'UserData');    
else
    % case is logging frames to disk
    logFile = objIMAQ.DiskLogger;
end

