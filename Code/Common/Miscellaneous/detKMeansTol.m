% --- calculates the minimum, maximum and middle pixel ranges from an
%     image I using the points from the binary mask B. the vector, p0 is
%     used as a starting point for the clustering search
function [pMin,pMax,pMid] = detKMeansTol(I,B,nDil,p0)

% parameters
pDel = 10;

% retrieves the pixel values from the points surrounding the extremum
if (nargin == 1)
    IB = I;
else
    IB = I(bwmorph(B,'dilate',nDil));
end

% sets the initial search values (if not provided)
if (nargin < 4); p0 = [min(IB) max(IB) 0.5*(max(IB)+min(IB))]'; end

% calculates the k-means clustering for the 3 groups. if the starting
% values are not provided, then determine them 
a = kmeans(IB,3,'start',p0);

% sets the min/max pixel tolerance values from each cluster
[pMin,pMax] = deal(max(IB(a == 1)),min(IB(a == 2)));
if (nargout == 3)
    % sets the middle range values (if required)
    pMid = [min(IB(a == 3)),max(IB(a == 3))]; 
else
    % ensures the min/max values are not too close to the mean values, or
    % above the extremum values
    pMin = max(min(mean(I(:))-pDel,pMin),min(I(:)));
    pMax = min(max(mean(I(:))+pDel,pMax),max(I(:)));
end