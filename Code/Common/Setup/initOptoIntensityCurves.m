% --- calculates the optogenetics intensity curves
function fOpto = initOptoIntensityCurves(paraDir)

% loads the button cdata file
A = load(fullfile(paraDir,'ButtonCData.mat'));
[imgF,fOpto] = deal({'optoR','optoG','optoB'},cell(3,1));

% process the images for the piece-wise polynomial data structs
for i = 1:length(fOpto)
    fOpto{i} = processOptoImg(eval(sprintf('A.cDataStr.%s',imgF{i})));
end

% converts the cell array to a struct array
fOpto = cell2mat(fOpto);

% --- 
function fP = processOptoImg(I)

% parameters
[xSclF,ySclF,p0G] = deal(50,0.1,[380,0]);
[pHi,pLo,sz] = deal(200,100,size(I));

% determines the RGB filtered images
Ir = (I(:,:,1) > pHi) & (I(:,:,2) < pLo) & (I(:,:,3) < pLo);
Ig = (I(:,:,2) > pHi) & (I(:,:,1) < pLo) & (I(:,:,3) < pLo);
Ib = (I(:,:,3) > pHi) & (I(:,:,1) < pLo) & (I(:,:,2) < pLo);
Iy = (I(:,:,1) > pHi) & (I(:,:,2) > pHi) & (I(:,:,3) < pLo);

% determines the x/y scales
[yR,~] = ind2sub(sz(1:2),find(Ir));
[yG,~] = ind2sub(sz(1:2),find(Ig));
[~,xB] = ind2sub(sz(1:2),find(Ib));
[yY,xY] = ind2sub(sz(1:2),find(Iy));

% calculates the x/y-scale factors
[xScl,yScl,p0] = deal(xSclF/range(xB),ySclF/range(yG),[mean(xY),mean(yY)]);

% determines the mean y-values of the signals
A = NaN(sz(1:2));
A(Ir) = yR;
YR = mean(A,1,'omitnan');

% determines the x/y coordinates of the signal and scales them
ix = find(~isnan(YR));
X = xScl*(ix-p0(1))+p0G(1);
Y = p0G(2) - yScl*(YR(ix)-p0(2));
Y(Y<0.0025) = 0;

% returns the normalised piece-polynomial struct
fP = pchip(X,Y/max(Y));