% --- determines the approximate size of the objects in pixels
function N = detApproxSize(xcP)

% parameters
BszTol = 1e-3; 

% determines the mid-section pixel tolerance via k-means and uses this to
% threshold the image
Bx = bwmorph(abs(xcP.ITx)+abs(xcP.ITy) > BszTol,'close',3);

% determines the maximum extent and 
[~,gMaj] = getGroupIndex(Bx,'MajorAxisLength');
N = floor(gMaj/2);