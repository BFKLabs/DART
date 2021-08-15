function resetCameraROI(hMain,objIMAQ)

% retrieves the camera source object information
isUpdate = false;
srcObj = get(objIMAQ,'Source');

% updates the video ROI (depending on camera type)
switch get(objIMAQ,'Name')
    case 'Allied Vision 1800 U-501m NIR'
        % sets the ROI position vector
        pROI = double([srcObj.AutoModeRegionOffsetX,...
                       srcObj.AutoModeRegionOffsetY,...
                       srcObj.AutoModeRegionWidth,...
                       srcObj.AutoModeRegionHeight]);
            
        if ~isequal(pROI,get(objIMAQ,'ROIPosition'))
            isUpdate = true;
            set(objIMAQ,'ROIPosition',pROI);
        end
end

% updates the ROI position
if isUpdate
    resetFcn = getappdata(hMain.figFlyRecord,'resetVideoPreviewDim');
    resetFcn(hMain,pROI)
end