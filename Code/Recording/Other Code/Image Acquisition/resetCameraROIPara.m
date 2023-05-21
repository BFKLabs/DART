function resetCameraROIPara(objIMAQ)

% retrieves the camera source object information
if isprop(objIMAQ,'Source')
    srcObj = get(objIMAQ,'Source');
else
    return
end

% updates the video ROI (depending on camera type)
switch get(objIMAQ,'Name')
    case 'Allied Vision 1800 U-501m NIR'
        % sets the ROI position vector
        pROI = get(objIMAQ,'ROIPosition');
        set(srcObj,'AutoModeRegionOffsetX',pROI(1))
        set(srcObj,'AutoModeRegionOffsetY',pROI(2))
        set(srcObj,'AutoModeRegionWidth',pROI(3))
        set(srcObj,'AutoModeRegionHeight',pROI(4))
end
