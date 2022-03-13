% --- converts indices from a global reference to a frame local reference
function indG = loc2glob(indL,pOfs,sz,szL)

% converts the global indices to coordinates
[yL,xL] = ind2sub(szL,indL);
xLT = min(sz(2),max(1,xL+pOfs(1)));
yLT = min(sz(1),max(1,yL+pOfs(2)));

% calculates the local indices from the local coordinates
indG = sub2ind(sz,yLT,xLT);