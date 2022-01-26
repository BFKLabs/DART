% --- retrieves the global row/column indices based on the overall
%     sub-region configuration
function [iCol,iFlyR,iRow] = getRegionIndices(iMov,iApp,iFly)

% calculates the region row/column index
iCol = mod(iApp-1,iMov.nCol)+1;
iRow = floor((iApp-1)/iMov.nCol)+1;

% retrieves the fly count array
if isfield(iMov,'pInfo')
    % case is the new sub-region data struct format
    if iMov.is2D        
        iFlyR = find(iMov.pInfo.iGrp(:,iApp)>0);
    elseif numel(iMov.pInfo.nFly) == 1
        iFlyR = 1:iMov.pInfo.nFly;
    else
        iFlyR = 1:iMov.pInfo.nFly(iRow,iCol);
    end
    
else    
    % sets the fly count based on the old format type
    reduceIndices = false;
    if ~isfield(iMov,'isUse')
        % if the isUse field is missing, then use the default values
        nFlyT = iMov.nTube*ones(iMov.nRow,1);

    elseif isempty(iMov.isUse)    
        % if the isUse field is empty, then use the default values
        nFlyT = iMov.nTube*ones(iMov.nRow,1);

    else
        % otherwise, use the values already set
        reduceIndices = true;
        nFlyT = cellfun(@length,iMov.isUse(:,1));
    end

    % calculates the global sub-region index
    iOfs = sum(nFlyT(1:(iRow-1)));
    iFlyR = (1:nFlyT(iRow))+iOfs;      
        
    % reduces the array by the in-use flags (if available)
    if isfield(iMov,'isUse')
        isUse = iMov.isUse{iCol};  
        if reduceIndices
            iFlyR = iFlyR(isUse(iRow));
        end
    end
end

% if a specific index is required, then return that value instead
if nargin == 3
    iFlyR = iFlyR(iFly);
end
