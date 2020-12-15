% --- converts indices from a global reference to a frame local reference
function indG = loc2glob(indL,pOfs,sz,szL)

% converts the global indices to coordinates
[yL,xL] = ind2sub(szL,indL);

% calculates the local indices from the local coordinates
indG = sub2ind(sz,yL+pOfs(2),xL+pOfs(1));