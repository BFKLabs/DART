function tLag = calcSignalLag(Y1,Y2,nP,dxi)

% sets the default input values
if (nargin < 4); dxi = 0.1; end

% removes the mean component from the signal
% [dY1,dY2] = deal(Y1-mean(Y1),Y2-mean(Y2));
[dY1,dY2] = deal(Y1,Y2);

% calculates the signal auto-correlation
[aY,cLags] = xcorr(dY1,dY2,nP,'coeff'); 

% interpolates the signal and determines the turning points
xi = (1:dxi:length(aY))';
aYI = interp1((1:length(aY))',aY,xi,'spline');
cLagsI = interp1(1:length(cLags),cLags,xi);

%
[~,imx] = max(aYI);
tLag = cLagsI(imx);