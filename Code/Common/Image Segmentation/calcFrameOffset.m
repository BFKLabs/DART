% --- calculates the frame translation offset for the frame indices, iFrm
function dpOfs = calcFrameOffset(dpInfo,iFrm)

% field retrieval
[xFrm,yFrm,dpOfsT] = deal(dpInfo.xFrm,dpInfo.yFrm,dpInfo.dpOfsT);

% determines the video phase that each frame belongs to
iPh = find(iFrm(1)<=dpInfo.iFrmPh,1,'first');

% calculates the 
ix = arrayfun(@(x)(find(x<=xFrm(:,1),1,'first')),iFrm)';
iy = arrayfun(@(y)(find(y<=yFrm(:,1),1,'first')),iFrm)';
dpOfs = roundP([xFrm(ix,2)-dpOfsT(iPh,1),yFrm(iy,2)-dpOfsT(iPh,2)]);