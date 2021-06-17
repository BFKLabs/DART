% --- calculates the periodicity of the signal, Z
function Tp = calcSignalPeriodicity(Z,iRmv)

% parameters
pTol = 0.75;

% calculates the periodogram of the signal
[Pxx,f] = periodogram(Z - mean(Z(:)),hamming(length(Z)));
if exist('iRmv','var')
    Pxx(1:iRmv) = 0;
end

% calculates the most likely frequency of the signal
[~,tPk] = findpeaks(Pxx/max(Pxx),'MinPeakHeight',pTol);
Tp = roundP(2*pi/f(tPk(1)));
