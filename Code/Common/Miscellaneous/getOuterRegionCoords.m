% --- calculates the coordinates of the outer region
function posG = getOuterRegionCoords(L,T,W,H)

% global variables
global frmSz 

% memory allocation
posG = zeros(1,4);

% retrieves the current coordinates
posG(1:2) = [max(0.5,L),max(0.5,T)];
posG(3) = W - max(0,(W + posG(1)) - (frmSz(2)-0.5));
posG(4) = H - max(0,(H + posG(2)) - (frmSz(1)-0.5));