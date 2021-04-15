% --- calculates the signal power spectrum using the cwt --- %
function [PP,P] = calcSigPowerSpectrum(Y,pP)

% sets the default parameter struct
if (nargin == 1)
    pP = struct('wType','db4','nLevel',8,'rDisk',4);
end

% calculates continuous wavelet transform and the power spectrum for each
% of the levels
c = cwt(Y,1:pP.nLevel,pP.wType); 
P = abs(c.*c); 

% smooths the image with a disk-filter 
PP = imfilter(P,fspecial('disk',pP.rDisk));