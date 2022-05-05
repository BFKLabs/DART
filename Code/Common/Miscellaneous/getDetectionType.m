% --- determines the region detection type
function Type = getDetectionType(iMov)

% initialisations
Type = 'None';

% sets the automatic detection type
if isfield(iMov,'autoP') && ~isempty(iMov.autoP)
    % otherwise, set the automatic detection type
    if iMov.is2D || detMltTrkStatus(iMov)
        Type = iMov.autoP.Type;
    end
end