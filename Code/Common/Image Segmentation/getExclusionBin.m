% --- retrieves the exclusion binary mask (based on the exclusion type)
function Bw = getExclusionBin(iMov,sz,iApp,iFly,varargin)

% case is a 1D region
if ~(is2DCheck(iMov) || detMltTrkStatus(iMov))
    Bw = bwmorph(true(sz),'erode');
    return
end

% sets the exclusion binary mask based on the region detection type
switch getDetectionType(iMov)
    case 'None'
        Bw = bwmorph(true(sz),'erode');
        
    case {'Circle','Rectangle'}
        % otherwise, return the local exclusion binary
        if nargin == 3
            Bw = logical(iMov.autoP.B{iApp});
        elseif isnan(iFly)
            Bw = logical(iMov.autoP.B{iApp});
        else
            if isColGroup(iMov)
                Bw = logical(iMov.autoP.B{iApp}(:,iMov.iCT{iApp}{iFly}));
            else
                Bw = logical(iMov.autoP.B{iApp}(iMov.iRT{iApp}{iFly},:));
            end
        end        
        
    case {'GeneralR','GeneralC'}
        if nargin == 3
            Bw = logical(iMov.autoP.BT{iApp});
        elseif isnan(iFly)
            Bw = logical(iMov.autoP.BT{iApp});
        elseif nargin == 4
            Bw = logical(iMov.autoP.BT{iApp}(iMov.iRT{iApp}{iFly},:));
        else
            Bw = iMov.autoP.BT{iApp}(iMov.iRT{iApp}{iFly},...
                                     iMov.iCT{iApp}{iFly});
        end
end 
