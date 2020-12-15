% sets the DAC device ID tags
function iStim = setChannelID(objDACInfo,iStim)

% retrieves the number of channels per DAC device
i0 = 0;

% otherwise, set the number of DAC objects
iStim.nChannel = objDACInfo.nChannel;
iStim.nChannel(isnan(iStim.nChannel)) = 1;

% sets the ID fields for all of the stimuli types
for i = 1:iStim.nDACObj
    % sets the ID flags for the current device
    for j = 1:iStim.nChannel(i)
        iStim.ID(i0+j,:) = [i j];
    end
    
    % increments the offset counter
    i0 = i0 + iStim.nChannel(i);
end