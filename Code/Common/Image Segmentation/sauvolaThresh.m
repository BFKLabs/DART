% SAUVOLA local thresholding.
function [ImgT,pTol] = sauvolaThresh(Img, avgSz, k)
 
% Convert to double
Img = double(Img);

% Mean value
mean = averagefilter(Img, avgSz, 'replicate');
mean2 = averagefilter(Img.^2, avgSz, 'replicate');

% Standard deviation
dev = (mean2 - mean.^2).^0.5;

% Sauvola thresholding
R = max(dev(:));
pTol = mean.*(1 + k * (dev / R-1));
ImgT = (Img > pTol);

function image = averagefilter(image, window, padding)

% 
[m,n] = deal(window(1),window(2));

if ~mod(m,2); m = m-1; end       % check for even window sizes
if ~mod(n,2); n = n-1; end

% Initialization.
[rows, columns] = size(image);   % size of the image

% Pad the image.
imageP  = padarray(image, [(m+1)/2 (n+1)/2], padding, 'pre');
imagePP = padarray(imageP, [(m-1)/2 (n-1)/2], padding, 'post');

% Always use double because uint8 would be too small.
imageD = double(imagePP);

% Matrix 't' is the sum of numbers on the left and above the current cell.
t = cumsum(cumsum(imageD),2);

% Calculate the mean values from the look up table 't'.
imageI = t(1+m:rows+m, 1+n:columns+n) + t(1:rows, 1:columns)...
    - t(1+m:rows+m, 1:columns) - t(1:rows, 1+n:columns+n);

% Now each pixel contains sum of the window. But we want the average value.
imageI = imageI/(m*n);

% Return matrix in the original type class.
image = cast(imageI, class(image));
