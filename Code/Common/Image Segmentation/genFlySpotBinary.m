% --- generates a binary region surround a fly at mPos --- %
function [Bspot,iGrp] = genFlySpotBinary(sz,flyPos,del)

% sets the dot radius (if not provided)
if (nargin == 2)
    del = sqrt(10);
end

% memory allocation
nFly = size(flyPos,1);
[Bspot,fP,iGrp] = deal(false(sz),roundP(flyPos,1),cell(nFly,1));

% sets the binary dot groups for each of the flies
for i = 1:nFly
    if (~isnan(fP(i,1)))
        Bnw = (bwdist(setGroup(sub2ind(sz,fP(i,2),fP(i,1)),sz)) <= del);
        [Bspot,iGrp(i)] = deal(Bspot|Bnw,getGroupIndex(Bnw));
    end
end