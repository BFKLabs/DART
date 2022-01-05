% --- creates the homomorphic image filter
function hFilt = setupHMFilter(iR,iC)

% parameters
[aHM,bHM,sigHM] = deal(0,1,15);

% filter dimensions
M = 2*(length(iR)+2*sigHM) + 1;
N = 2*(length(iC)+2*sigHM) + 1;

% creates the fft filter
[X, Y] = meshgrid(1:N,1:M);
gNum = (X - ceil(N/2)).^2 + (Y - ceil(M/2)).^2;                        
H0 = 1 - exp(-gNum./(2*sigHM.^2));
hFilt = fftshift(aHM + bHM*H0);