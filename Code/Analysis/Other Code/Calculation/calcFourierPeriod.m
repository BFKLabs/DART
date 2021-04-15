% --- calculates a signals period from the fourier autocorrelation
function [P,tLagH,aY] = calcFourierPeriod(Ys,tBin,aYtol,tPer)

% parameters
if (nargin < 3); aYtol = 0; end
[N,dT] = deal(4*(tPer/24),tPer/6);

% removes the mean component from the signal
dYs = Ys - mean(Ys);

% calculates the auto-correlation of the signal. converts the lag times
% from frames to hours and smooths the auto-correlation signal
[aY,tLag] = xcorr(dYs,convertTime(1,'day','min')*N,'coeff');    
tLagH = convertTime(tLag*(tBin/60),'min','hours');

% determines the location of the auto-correlation max around the
% 24-hour mark
ii = find((tLagH > (tPer-dT)) & (tLagH < (tPer+dT)));
if (isempty(ii))
    P = NaN;
else
    [aYn,imx] = deal(normImg(aY),ii(argMax(aY(ii))));    
    if (aYn(imx) > aYtol)       
        P = tLagH(imx); 
    else
        P = NaN;
    end
end