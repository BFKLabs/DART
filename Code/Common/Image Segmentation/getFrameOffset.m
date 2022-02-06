% --- gets the frame offset (wrapper function for calcFrameOffset)
function dpOfs = getFrameOffset(iMov,iFrmR,iApp)

% initialisations
dpOfs = [0,0];

% determines if translation is feasible
if ~isfield(iMov,'iPhase') || ~isfield(iMov,'phInfo')
    % if no information is provided, then exit
    return
    
elseif isempty(iMov.phInfo)
    % if the field has not been initialised, then exit
    return
end

% sets the default input arguments
if ~exist('iApp','var'); iApp = 1:length(iMov.phInfo.pOfs); end

% calculates and applied the image offset
dpOfs = calcFrameOffset(iMov.phInfo,iFrmR,iApp);
