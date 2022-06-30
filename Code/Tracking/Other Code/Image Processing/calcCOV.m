% --- calculates the coefficient of variance in difference times for the
%     most prominent peaks, given by P
function zCOV = calcCOV(Z)

% parameters
Tmn = 5;
pTol = 0.20;
pkTol = 0.10;

% calculates power spectrum of the signal (remove the first Tmn points)
Tp = calcSignalPeriodicity(Z,Tmn);

% removes any non-prominent peaks and calculates the distance btwn them
[~,tPk,~,P] = findpeaks(Z/max(abs(Z),[],'omitnan'),'MinPeakHeight',pkTol);
tPk = tPk(P/max(P) > pTol);
if length(tPk) <= 2
    zCOV = NaN;
else
    % calculates the distance between the peaks
    dtPk = pdist2(tPk,tPk);
    dT = abs(diff(dtPk(:,1)));
    
    % calculates the variance in the peak difference wrt the period
    zCOV = mean(abs((dT-Tp)/Tp));
end
