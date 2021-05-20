% --- determines if the video resolution is large
function isLargeRes = isLargeVideoRes(objIMAQ)

% initialisations
isLargeRes = false;
Wmax = [1600:100:2500,2590];
Hmax = [1600,1560,1520,1460,1400,1340,1285,1235,1190,1145,1100];

% if the width of the image is large, then check the height dimension
vRes = getVideoResolution(objIMAQ);
if vRes(1) > Wmax(1)
    % if the height dimension is sufficiently large, then use
    HmaxF = floor(interp1(Wmax,Hmax,vRes(1),'linear','extrap'));
    isLargeRes = vRes(2) > HmaxF;
end

% REMOVE ME!
isLargeRes = true;
