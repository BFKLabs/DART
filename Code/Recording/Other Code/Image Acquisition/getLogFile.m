% --- retrieves the log-file object (based on the logging mode)
function logFile = getLogFile(objIMAQ)

% global variables
global isMemLog

% retrieves the frame logging mode (if not set)
if isempty(isMemLog) && isprop(objIMAQ,'LoggingMode')   
    isMemLog = strcmp(objIMAQ.LoggingMode,'memory');
else
    isMemLog = false;
end

% retrieves the logfile based on the logging type
if isMemLog
    % case is logging frames to memory
    logFile = get(objIMAQ,'UserData');    
else
    % case is logging frames to disk
    logFile = objIMAQ.DiskLogger;
end

