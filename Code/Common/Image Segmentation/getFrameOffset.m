% --- gets the frame offset (wrapper function for calcFrameOffset)
function dpOfs = getFrameOffset(iMov,iFrmR)

% initialisations
dpOfs = [0,0];

% determines if translation is feasible
if ~isfield(iMov,'iPhase') || ~isfield(iMov,'dpInfo')
    % if no information is provided, then exit
    return
    
elseif isempty(iMov.dpInfo)
    % if the field has not been initialised, then exit
    return
end

% calculates and applied the image offset
dpOfs = calcFrameOffset(iMov.dpInfo,iFrmR);