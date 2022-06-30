function [B,idx] = removeSmallBlobs(B,szMin)

% retrieves the blob linear indices
idx = getGroupIndex(B);

%
isSmall = cellfun(@length,idx) < szMin;
if any(isSmall)
    B(cell2cell(idx(isSmall))) = false;    
    idx = idx(~isSmall);
end