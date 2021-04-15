% --- checks to see see if the sub-regions are 2-Dimensional
function is2D = is2DCheck(iMov,varargin)

% sub-regions are not set, so return a false value
if ~iMov.isSet
    is2D = false;
    return
end

% aspect ratio tolerance
ARtol = 3; 

% calculates the aspect ratio and determines if is greater than tolerance
if isempty(iMov.xTube) || (nargin == 2)  
    nTube = getSRCount(iMov);    
    AR = (iMov.posG(3)/iMov.nCol)/(iMov.posG(4)/(iMov.nRow*max(nTube(:))));    
else
    AR = cellfun(@(x,y)(diff(x(1,:))/diff(y(1,:))),iMov.xTube,iMov.yTube);    
end

% determines if the new array is 2-dimensional
is2D = all(max(AR,1./AR) < ARtol);