function deleteTimerObjects(hTimer)

if isvalid(hTimer)
    % stops the timer objects
    if strcmp(get(hTimer,'Running'),'on')
        stop(hTimer)
        pause(0.05);
    end

    % deletes the timer objects
    delete(hTimer);
end
