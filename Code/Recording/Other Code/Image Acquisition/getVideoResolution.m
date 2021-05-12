% --- retrieves the video resolution based off the ROI position
function vRes = getVideoResolution(objIMAQ)

% retrieves the camera ROI position
rPos = get(objIMAQ,'ROIPosition');

% retrieves the width/height component
vRes = rPos(3:4);