% --- converts indices from a global reference to a frame local reference
function indL = glob2loc(indG,pOfs,sz,szL)

% converts the global indices to coordinates
[yG,xG] = ind2sub(sz,indG);
[dyG,dxG] = deal(yG-pOfs(2),xG-pOfs(1));

% calculates the local indices from the local coordinates
try
    indL = sub2ind(szL,dyG,dxG);
catch
    ii = (dxG > 0) & (dxG <= szL(2)) & (dyG > 0) & (dyG <= szL(1));
    indL = sub2ind(szL,dyG(ii),dxG(ii));
end