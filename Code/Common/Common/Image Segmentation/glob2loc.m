% --- converts indices from a global reference to a frame local reference
function indL = glob2loc(indG,pOfs,sz,szL)

% converts the global indices to coordinates
[yG,xG] = ind2sub(sz,indG);

% calculates the local indices from the local coordinates
indL = sub2ind(szL,yG-pOfs(2),xG-pOfs(1));