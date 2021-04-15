% --- determines the global stimuli device ID index 
function ID = getGlobalStimID(iStim, objDACInfo, ind)

% if the index is not provided, then user the current stimuli tab
if (nargin == 2); ind = iStim.cTab; end

% returns the global stimuli ID 
if isempty(iStim)
    ID = objDACInfo.vSelDAC(ind);
else
    ID = objDACInfo.vSelDAC(iStim.ID(ind,1));
end