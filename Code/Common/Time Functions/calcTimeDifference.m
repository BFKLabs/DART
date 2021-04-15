% --- calculates the time difference between T0 to T1 in dd/hh/mm/ss format
function [dT,TimeVal,TimeStr] = calcTimeDifference(T0,T1)

% sets the day, hour and minute durations (in seconds)
[dDay,dHour,dMin] = deal(24*60^2,60^2,60);

% sets the time difference depending on the input arguments
if (nargin == 1)
    % only one time, so set this as time difference
    dT = T0;
else
    % otherwise, calculate the elapsed time between events T0 to T1
    if (length(T0) == 4)
        dT = vec2sec(T0) - vec2sec(T1);
    else
        dT = etime(T0,T1);
    end
end

% calculates the time difference between the start time and now
if (dT < 0)    
    % reduces the time by one (because it is negative)
    dT = dT - 1;
    
    % sets the day,hour/min/sec values
    tDay = -floor(abs(dT)/dDay);        
    tHour = floor((abs(dT) - abs(tDay)*dDay)/dHour);
    tMin = floor((abs(dT) - abs(tDay)*dDay - tHour*dHour)/dMin);
    tSec = floor(abs(dT) - abs(tDay)*dDay - tHour*dHour - tMin*dMin);
else
    % sets the day,hour/min/sec values
    tDay = floor(dT/dDay);        
    tHour = floor((dT - tDay*dDay)/dHour);
    tMin = floor((dT - tDay*dDay - tHour*dHour)/dMin);
    tSec = floor(dT - tDay*dDay - tHour*dHour - tMin*dMin);        
end

% sets the time value vector
TimeVal = [tDay,tHour,tMin,tSec];

% sets the time value strings (if required)
if (nargout == 3)
    % sets the day time string
    if (abs(tDay) < 10)
        if (tDay < 0)
            tDayS = ['-0',num2str(abs(tDay))];
        else
            tDayS = ['0',num2str(tDay)];
        end
    else
        tDayS = num2str(tDay);
    end    
    
    % sets the hour time string
    if (abs(tHour) < 10)
        tHourS = ['0',num2str(tHour)];
    else
        tHourS = num2str(tHour);
    end

    % sets the hour time string
    if (tMin < 10)
        tMinS = ['0',num2str(tMin)];
    else
        tMinS = num2str(tMin);
    end

    % sets the hour time string
    if (tSec < 10)
        tSecS = ['0',num2str(tSec)];
    else
        tSecS = num2str(tSec);
    end

    % sets the time values/strings
    TimeStr = {tDayS,tHourS,tMinS,tSecS};
end