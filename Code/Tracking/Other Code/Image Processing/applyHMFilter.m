function [Ihmf,H] = applyHMFilter(IL0,H)

% initialisations
sz0 = size(IL0);
IL0 = fillArrayNaNs(IL0);

% sets the image expansion size offset
if exist('H','var')
    dX = (size(H) - (2*size(IL0)+1))/4;
else
    dX = 10*[1,1];
end
    
% expands the image and calculates the image dimensions
IL = padarray(IL0,dX,'symmetric','both');
I = log(1 + IL/255);
M = 2*size(I,1) + 1;
N = 2*size(I,2) + 1;

% sets up the hm filter (if not provided)
if ~exist('H','var')
    [A,B,sigHM] = deal(0,1,15);
    [X, Y] = meshgrid(1:N,1:M);
    gNum = (X - ceil(N/2)).^2 + (Y - ceil(M/2)).^2;    
    H0 = 1 - exp(-gNum./(2*sigHM.^2));
    H = fftshift(A + B*H0);
end

% applies the FFT filter
If = fft2(I, M, N);
Iout = real(ifft2(H.*If));
Iout = Iout(1:size(I,1),1:size(I,2));
Iout = Iout((1:sz0(1))+dX(1),(1:sz0(2))+dX(2));

% converts back to the normal number space
Ihmf = exp(Iout) - 1;
