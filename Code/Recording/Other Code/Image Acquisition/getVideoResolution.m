% --- retrieves the video resolution based off the ROI position
function vRes = getVideoResolution(vObj,vType)

% retrieves the video resolution based on the input object type
if isa(vObj,'VideoReader')
    % video object is the video reader
    vRes = [get(vObj,'Width'),get(vObj,'Height')];
    
elseif isa(vObj,'DummyVideo')
    % video object is the video reader
    vRes = flip(vObj.szImg);    
    
else
    % sets the default input arguments
    if ~exist('vType','var'); vType = 0; end
    
    % retrieves the video resolution (dependent on type)
    try
        vRes = vObj.pROI(3:4);
    catch
        if vType
            % video object is the image acquisition object
            try
                rPos = get(vObj,'ROIPosition');
                vRes = rPos(3:4);
            catch
                vRes = get(vObj,'VideoResolution');
            end        
        else
            % case is retrieving the video resolution
            vRes = get(vObj,'VideoResolution');
        end
    end

end
