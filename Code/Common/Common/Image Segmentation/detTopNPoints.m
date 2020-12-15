% --- 
function [iMx,yMx] = detTopNPoints(Y,N,D,isMax)

% sets the default rejection radius (if not set)
if (nargin < 3); D = 3; end
if (nargin < 4); isMax = true; end

% if minimising, then take negative of image values
if (~isMax); Y = -Y; end

% array dimensioning and other initialisations
[i,yMn,sz] = deal(1,min(Y),length(Y));
[iMx,yMx] = deal(zeros(N,1));

%
while (i <= N)
    % determines the location of the next maximum
    [yMx(i),iMx(i)] = max(Y);

    % removes the point from the signal and increments the counter
    [Y(max(1,iMx(i)-D):min(sz,iMx(i)+D)),i] = deal(yMn,i+1);
end

% sorts the indices in ascending order
[iMx,ii] = sort(iMx);
yMx = yMx(ii);

% changes the sign of the maxima (if minimising)
if (~isMax); yMx = -yMx; end