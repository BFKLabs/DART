% --- retrieves the global row/column indices based on the overall
%     sub-region configuration
function [iCol,iFlyR,iRow] = getRegionIndices(iMov,iApp,iFly)

% retrieves the fly count array
if ~isfield(iMov,'isUse')
    % if the isUse field is missing, then use the default values
    nFlyT = iMov.nTube*ones(iMov.nRow,1);
    
elseif isempty(iMov.isUse)    
    % if the isUse field is empty, then use the default values
    nFlyT = iMov.nTube*ones(iMov.nRow,1);
    
else
    % otherwise, use the values already set
    nFlyT = cellfun(@length,iMov.isUse(:,1));
end

% calculates the region row/column index
iCol = mod(iApp-1,iMov.nCol)+1;
iRow = floor((iApp-1)/iMov.nCol)+1;

% calculates the global sub-region index
iOfs = sum(nFlyT(1:(iRow-1)));
iFlyR = (1:nFlyT(iRow))+iOfs;

% if a specific index is required, then return than value instead
if nargin == 3
    iFlyR = iFlyR(iFly);
end