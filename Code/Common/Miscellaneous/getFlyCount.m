% --- returns the tube count based on whether the regional fly index has
%     been set or not
function nTube = getFlyCount(iMov,varargin)

% determines if the regional fly count flag has been set
if (isfield(iMov,'dTube'))
    % if so, determine if regional fly counts are being used
    if (iMov.dTube)
        % region fly counts are being used
        nTube = iMov.nTubeR;    
    else
        % fixed fly counts are being used
        nTube = repmat(iMov.nTube,1,iMov.nRow*iMov.nCol);    
    end
else
    % otherwise, use the fixed fly count value
    nTube = repmat(iMov.nTube,1,iMov.nRow*iMov.nCol);    
end

% vectorises the tube count array (if required)
if (nargin == 2) && (numel(nTube) > 1)
    nTube = nTube';
    nTube = nTube(:); 
end