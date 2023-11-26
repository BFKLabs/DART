% --- scales the duration parameters so they have the same time units
function [tOfs,t1,t2] = scaleTimePara(sPara,isSW)

% sets the time offset
tOfs = sPara.tOfs*getTimeMultiplier(sPara.tDurU,sPara.tOfsU);
if nargout == 1; return; end

% scales and returns the parameters based on waveform type
if isSW
    % case is the square waveform (uses on/off-cycle duration)
    t1 = sPara.tDurOn(1)*getTimeMultiplier(sPara.tDurU,sPara.tDurOnU);
    t2 = sPara.tDurOff(1)*getTimeMultiplier(sPara.tDurU,sPara.tDurOffU);
else
    % case is the non-square waveform (uses cycle duration)
    t1 = sPara.tCycle*getTimeMultiplier(sPara.tCycleU,sPara.tDurU);    
end