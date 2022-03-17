% --- determines the region detection type
function Type = getDetectionType(iMov)

% sets the automatic detection type
if ~isfield(iMov,'autoP') || isempty(iMov.autoP)
    % no automatic detection data set (old struct type)
    Type = 'None';    
else
    % otherwise, set the automatic detection type
    Type = iMov.autoP.Type;
end