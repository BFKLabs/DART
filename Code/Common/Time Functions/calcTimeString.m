% --- calculates the time string that is offset from the time vector, T0,
%     by the time (in seconds), Tofs
function [timeVec,timeStr] = calcTimeString(T0,Tofs)

% sets the new time vector and string
timeVec = datevec(addtodate(datenum(T0),roundP(Tofs,1),'second'));
timeStr = datestr(timeVec);