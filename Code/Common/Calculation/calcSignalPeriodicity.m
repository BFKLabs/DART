% --- calculates the periodicity of the signal, Z
function [Tp,Yp] = calcSignalPeriodicity(Z,iRmv,varargin)

% parameters
pTol = 0.75;

% calculates the periodogram of the signal
[Pxx,f] = periodogram(Z - mean(Z(:)),hamming(length(Z)));
if exist('iRmv','var')
    if ~isempty(iRmv)
        Pxx(1:iRmv) = 0;
    end
end

% calculates the most likely frequency of the signal
[yPk,tPk] = findpeaks(Pxx/max(Pxx),'MinPeakHeight',pTol);

% rounds the value (if required)
if nargout == 2
    [Tp,Yp] = deal(2*pi./f(tPk),yPk);
else
    Tp = roundP(2*pi/f(tPk(argMax(yPk))));    
end
