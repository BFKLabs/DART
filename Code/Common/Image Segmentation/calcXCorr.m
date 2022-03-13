% --- calculates the x-correlation of the image, I, with the template, IT
function Ixc = calcXCorr(IT,I,D,varargin)

if all(isnan(I(:)))
    Ixc = zeros(size(I));
    return
end

% sets the default input arguments
if ~exist('D','var')
    D = 2*ceil((size(IT) - 1)/2);
end

% calculates the x/y-direction gradient cross-correlation
Iex = padarray(I,D,'symmetric','both');
if nargin < 4
    Ixc = normxcorr2(IT,Iex);
else
    Ixc = xcorr2(Iex-mean(Iex(:)),IT-mean(IT(:)));
end

% calculates the x/y-gradients of the images 
dD = ceil((size(Ixc) - size(I)) / 2);
[iRL,iCL] = deal(dD(1)+(1:size(I,1)),dD(2)+(1:size(I,2)));
    
% reduces down the final image
Ixc = Ixc(iRL,iCL); 
