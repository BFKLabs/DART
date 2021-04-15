% --- creates a point distance mask for the location fPos
function Dp = createPointDistMask(fPos,sz)

% converts the position to a linear index and then creates the mask
ind = sub2ind(sz,roundP(fPos(2)),roundP(fPos(1)));
Dp = bwdist(setGroup(ind,sz));
