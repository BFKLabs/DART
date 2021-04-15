% --- calculates the difference in orientation angles
function dPhi = calcOrientAngleDiff(p1,p2,varargin)

%
dPhi = atan2(sin(2*(p2-p1)),cos(2*(p2-p1)))/2;
if (nargin == 3); dPhi = dPhi*180/pi; end