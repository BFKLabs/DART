% --- scales the duration parameters so they have the same time units
function [tOfs,t1,t2] = scaleTimePara(sPara,isSW)

% sets the time offset
tOfs = sPara.tOfs*getTimeMultiplier(sPara.tDurU,sPara.tOfsU);
if nargout == 1; return; end

% scales and returns the parameters based on waveform type
if isSW
    % retrieves the on-cycle duration
    tDurOn = getDurationValue(sPara.tDurOn);
    tDurOff = getDurationValue(sPara.tDurOff);
    
    % case is the square waveform (uses on/off-cycle duration)
    t1 = tDurOn*getTimeMultiplier(sPara.tDurU,sPara.tDurOnU);
    t2 = tDurOff*getTimeMultiplier(sPara.tDurU,sPara.tDurOffU);
    
else
    % case is the non-square waveform (uses cycle duration)
    t1 = sPara.tCycle*getTimeMultiplier(sPara.tCycleU,sPara.tDurU);    
end

%
function tD = getDurationValue(tD0)

if length(tD0) == 1
    tD = tD0;
elseif tD0(3) < 0
    tD = tD0(1:2);
else
    tD = tD0(3);
end