% --- retrieves the names of the DAC devices --- %
function tabName = getDACNames(iStim,objDACInfo)

% retrieves the number of DAC devices/DAC channel counts
[nDACObj,i0] = deal(iStim.nDACObj,0);    
nChannel = iStim.nChannel;        
tabName = cell(sum(nChannel),1);

% sets the stimulus tab panel names
for i = 1:nDACObj
    % sets the names for the current DAC device
    for j = 1:nChannel(i)
        tabName{i0+j} = sprintf('%s - (Channel %i)',objDACInfo.vStrDAC{i},j);
    end

    % increments the offset index
    i0 = i0 + nChannel(i);
end