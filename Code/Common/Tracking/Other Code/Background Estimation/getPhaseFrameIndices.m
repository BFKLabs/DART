% --- 
function iFrm = getPhaseFrameIndices(iPhase,nFrmR)

% parameters
dFrmMin = 50;                
nFrmP = diff(iPhase)+1;

% determines the array based on the duration of the phase
if nFrmP == 1
    % phase is one 1 frame in duration
    iFrm = iPhase(1);
else
    % phase has more than one frame (ensure first/last frame of phase is
    % included in this frame index array)
    nFrm = min(1+ceil(nFrmP/dFrmMin),nFrmR);
    iFrm = roundP(linspace(iPhase(1),iPhase(2),nFrm));
end