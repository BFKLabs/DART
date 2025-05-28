% --- retrieves the time scale multipler, based on the final time value - %
function [tMlt,tUnits] = getTimeScale(Tf)

% sets the minimum hour time count
mMin = 5;
hMin = 3;

% sets the time multiplier (from seconds to minutes/hours)
if convertTime(Tf,'sec','min') < mMin
    % if the time is less than hMin hours, then use minutes
    [tMlt,tUnits] = deal(1,'Sec');
    
elseif convertTime(Tf,'sec','hrs') < hMin
    % if the time is less than hMin hours, then use minutes
    [tMlt,tUnits] = deal(convertTime(1,'sec','min'),'Min');
else
    % otherwise, use hours
    [tMlt,tUnits] = deal(convertTime(1,'sec','hrs'),'Hours');
end