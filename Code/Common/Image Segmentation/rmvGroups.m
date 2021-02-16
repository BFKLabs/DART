% --- 
function [Im,iArea,ii] = rmvGroups(I,varargin)

% retrieves the image binary mask groups and areas
[iGrp,iArea] = getGroupIndex(I,'Area');

% calculat
if (nargin == 1)
    % only one input, so return the largest group 
    ii = find(iArea == max(iArea));
    if (length(ii) > 1)
        ii = ii(1);
    end
else
    % sets the input argument (the area tolerance)
    aTol = varargin{1};
    
    % determines the selected group indices based on the area tolerance
    % sign
    if (aTol > 0)
        % area tolerance is positive, so find groups that have sizes 
        % greater than the area tolerance
        ii = iArea/max(iArea) > aTol;
    else
        % area tolerance is negative, so find groups that have sizes less
        % than the area tolerance
        ii = iArea/max(iArea) < abs(aTol);
    end
end

% sets the new image base mask
Im = setGroup(iGrp(ii),size(I));