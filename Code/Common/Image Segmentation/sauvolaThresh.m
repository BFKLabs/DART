% SAUVOLA local thresholding.
function [ImgT,pTol] = sauvolaThresh(Img, varargin)
 
% ensures the image is stored as a double
if ~isa(Img,'double'); Img = double(Img); end

% sets the thresholding parameters
if isstruct(varargin{1})
    pP = varargin{1};
    [szMu, kT] = deal(pP.szMu, pP.kT);
else
    [szMu, kT] = deal(varargin{1},varargin{2});
end

% Mean value
Imu = avgFilt(Img, szMu*[1,1]);
Ivar = avgFilt(Img.^2, szMu*[1,1]);
Isd = (Ivar - Imu.^2).^0.5;
R = max(Isd(:));

% Sauvola thresholding
pTol = Imu.*(1 + kT * (Isd / R-1));
ImgT = Img < pTol;

% --- calculates the average filtered image
function Img = avgFilt(Img, wSize)

% initialisations
pType = 'replicate';
[nRow, nCol] = size(Img);
[m,n] = deal(wSize(1),wSize(2));

% ensures the window size is event
if ~mod(m,2); m = m-1; end       
if ~mod(n,2); n = n-1; end

% Pad the image.
ImgPre  = padarray(Img, [(m+1)/2 (n+1)/2], pType, 'pre');
ImgPost = padarray(ImgPre, [(m-1)/2 (n-1)/2], pType, 'post');

% Always use double because uint8 would be too small.
imageD = double(ImgPost);

% Matrix 't' is the sum of numbers on the left and above the current cell.
t = cumsum(cumsum(imageD),2);

% Calculate the mean values from the look up table 't'.
ImgI = t(1+m:nRow+m, 1+n:nCol+n) + t(1:nRow, 1:nCol)...
     - t(1+m:nRow+m, 1:nCol) - t(1:nRow, 1+n:nCol+n);

% Now each pixel contains sum of the window. But we want the average value.
Img = ImgI/(m*n);