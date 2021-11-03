% --- calculates the frame translation offset for the frame indices, iFrm
function dpOfs = calcFrameOffset(dpInfo,iFrmR)

% field retrieval
iFrm = dpInfo.iFrm;
[xFrm,yFrm,dpOfsT] = deal(dpInfo.xFrm,dpInfo.yFrm,dpInfo.dpOfsT);

% determines the video phase that each frame belongs to
iPh = find(iFrm(1)<=dpInfo.iFrmPh,1,'first');

% interpolates the translation values
xFrmR = interp1(iFrm,xFrm,iFrmR,'pchip');
yFrmR = interp1(iFrm,yFrm,iFrmR,'pchip');
dpOfs = roundP([xFrmR(:)-dpOfsT(iPh,1),yFrmR(:)-dpOfsT(iPh,2)]);
