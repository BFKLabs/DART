% --- retrieves the apparatus fly count
function nFly = getAppFlyCount(iMov,varargin)

% determines if the if the fixed fly count flag has been set
if isfield(iMov,'dTube')
    % if so, determine if there is regional variation in the fly count
    if (iMov.dTube)
        % retrieves the row/column indices
        if (nargin == 2)
            % only the apparatus index was provided
            iApp = varargin{1};
            iRow = floor((iApp-1)/iMov.nCol) + 1;
            iCol = mod((iApp-1),iMov.nCol) + 1;
        else
            % both row/column indices were provided
            [iRow,iCol] = deal(varargin{1},varargin{2});
        end
        
        % retrieves the fly count
        if (any(size(iMov.nTubeR) == 1))
            if (exist('iApp','var'))
                nFly = iMov.nTubeR(iApp);
            else
                iApp = iRow*iMov.nCol + iCol;
                nFly = iMov.nTubeR(iApp);
            end
        else
            nFly = iMov.nTubeR(iRow,iCol);
        end
    else
        % fly count is fixed
        nFly = iMov.nTube;
    end
else
    % old program version, so use fixed fly count
    nFly = iMov.nTube;
end

