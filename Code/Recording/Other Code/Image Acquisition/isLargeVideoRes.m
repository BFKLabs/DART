% --- determines if the video resolution is large
function [isLargeRes,Hmax,Wmax] = isLargeVideoRes(objVid)

% initialisations
isLargeRes = false;
[Hmax,Wmax] = getLargeVideoDim();

% retrieves the video resolution
switch class(objVid)
    case 'videoinput'
        % case is retrieving it directly from the camera
        vRes = getVideoResolution(objVid);
    
    otherwise
        % otheriwse, the resolution vector was the input
        vRes = objVid;
    
end

% if the width of the image is large, then check the height dimension
if vRes(1) > Wmax(1)
    % if the height dimension is sufficiently large, then use
    HmaxF = floor(interp1(Wmax,Hmax,vRes(1),'linear','extrap'));
    isLargeRes = vRes(2) > HmaxF;
end
