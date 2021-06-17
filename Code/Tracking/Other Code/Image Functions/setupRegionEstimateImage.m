% --- sets up the automatic region detection algorithm image estimate
function ImdBL0 = setupRegionEstimateImage(iMov,Istack)

% parameters
dT = 10;
sz = size(Istack{1});
Bg = false(sz);

% sets the global search region
iRG = roundP(max(1,iMov.posG(2)-dT):min(sz(1),sum(iMov.posG([2 4]))+dT));
iCG = roundP(max(1,iMov.posG(1)-dT):min(sz(2),sum(iMov.posG([1 3]))+dT));
Bg(iRG,iCG) = true;

% calculates the median baseline removed image
I = calcImageStackFcn(Istack,'min');
h0 = ceil(getMedBLSize(iMov)*2);
ImdBL0 = removeImageMedianBL(double(I),false,true,h0);
ImdBL0(~Bg) = 0;