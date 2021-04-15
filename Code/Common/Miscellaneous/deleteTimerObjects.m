function deleteTimerObjects(hTimer)

% stops the timer objects
stop(hTimer)
pause(0.05);

% deletes the timer objects
delete(hTimer);