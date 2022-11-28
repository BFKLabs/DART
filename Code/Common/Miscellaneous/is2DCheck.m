% --- checks to see see if the sub-regions are 2-Dimensional
function is2D = is2DCheck(iMov,varargin)

% sub-regions are not set, so return a false value
if ~iMov.isSet
    is2D = false;
    return
elseif detMltTrkStatus(iMov)
    is2D = true;
    return
elseif isfield(iMov,'is2D')
    is2D = iMov.is2D;
    return    
end

% aspect ratio tolerance
ARtol = 3; 

% calculates the aspect ratio and determines if is greater than tolerance
if isempty(iMov.xTube) || (nargin == 2)         
    AR = cellfun(@(iC,iR)(mean...
                    (cellfun('length',iR))/length(iC)),iMov.iCT,iMov.iRT);  
else
    isOK = ~cellfun('isempty',iMov.yTube);
    [xT,yT] = deal(iMov.xTube(isOK),iMov.yTube(isOK));
    AR = cellfun(@(x,y)(diff(x(1,:))/diff(y(1,:))),xT,yT);    
end

% determines if the new array is 2-dimensional
is2D = all(max(AR,1./AR) < ARtol);
