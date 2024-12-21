function fStrC = getCommonBaseString(fStr)

if ischar(fStr)
    % exit with the original string if a character field
    fStrC = fStr;
    return
    
elseif length(fStr) == 1
    % exit with first element if cell array only one element in length
    fStrC = fStr{1};
    return
end
    
% determines the min overlapping length of all strings
iA = cellfun(@(x)(ismember(x,fStr{1})),fStr,'un',0);
nLen = cellfun(@(x)(length(getArrayVal(getGroupIndex(x),1))),iA);

% returns the longest common base string
fStrC = fStr{1}(1:min(nLen));