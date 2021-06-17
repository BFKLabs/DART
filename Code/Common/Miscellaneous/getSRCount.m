% --- retrieves the apparatus fly count
function nFly = getSRCount(iMov,varargin)

% determines if multi-tracking
if detIfMultiTrack(iMov)
    nFly = 1;
    return
end

if isfield(iMov,'pInfo')
    % retrieves the entire sub-count arrays 
    if iMov.is2D        
        % case is a 2D setup
        nFly = iMov.pInfo.nRow*ones(1,iMov.pInfo.nCol);
    else
        % case is a 1D setup
        if iMov.nRow*iMov.nCol == numel(iMov.pInfo.nFly)
            nFly = iMov.pInfo.nFly;
        else
            nFly = iMov.pInfo.nFlyMx*ones(iMov.nRow,iMov.nCol);
        end
    end
    
    % calculates the row/column indices (if required)
    switch nargin
        case 2
            % only the apparatus index was provided
            iApp = varargin{1};
            iRow = floor((iApp-1)/iMov.nCol) + 1;
            iCol = mod((iApp-1),iMov.nCol) + 1; 
            
        case 3
            % both row/column indices were provided
            [iRow,iCol] = deal(varargin{1},varargin{2});            
            
        otherwise
            % otherwise, exit the function
            return
    end
    
    % returns the value at the specified row/column index
    nFly = nFly(iRow,iCol);

elseif isfield(iMov,'dTube')
    % if the fixed fly count flag has been set, determine if there is 
    % regional variation in the fly count
    if iMov.dTube
        % retrieves the row/column indices
        switch nargin
            case 1
                if numel(iMov.nTubeR) == iMov.nRow*iMov.nCol
                    szGrp = [iMov.nRow,iMov.nCol];
                    nFly = reshapeIndexArray(iMov.nTubeR,szGrp);
                else
                    nFly = iMov.nTubeR;
                end
                
                return
                
            case 2
                % only the apparatus index was provided
                iApp = varargin{1};
                iRow = floor((iApp-1)/iMov.nCol) + 1;
                iCol = mod((iApp-1),iMov.nCol) + 1;
                
            otherwise
                % both row/column indices were provided
                [iRow,iCol] = deal(varargin{1},varargin{2});
        end
        
        % retrieves the fly count
        if any(size(iMov.nTubeR) == 1)
            if exist('iApp','var')
                nFly = iMov.nTubeR(iApp);
            else
                iApp = iRow*iMov.nCol + iCol;
                nFly = iMov.nTubeR(iApp);
            end
        else
            nFly = iMov.nTubeR(iRow,iCol);
        end
    else
        % case is the fly count is fixed    
        if nargin == 2
            nFly = iMov.nTube;
        else
            nFly = iMov.nTube*ones(iMov.nRow,iMov.nCol);
        end
    end
else
    % old program version, so use fixed fly count
    nFly = iMov.nTube;
end