% --- retrieves the video resolution based off the ROI position
function vRes = getVideoResolution(vObj)

% retrieves the video resolution based on the input object type
if isa(vObj,'VideoReader')
    % video object is the video reader
    vRes = [get(vObj,'Width'),get(vObj,'Height')];
    
else
    % video object is the image acquisition object
    rPos = get(vObj,'ROIPosition');
    vRes = rPos(3:4);
end