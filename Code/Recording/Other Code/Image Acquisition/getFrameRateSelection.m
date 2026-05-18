function [fRate,iSel] = getFrameRateSelection(exObj,FPS)

% default input arguments
if ~exist('FPS','var'); FPS = []; end

if exObj.isTest
    % case is a test recording
    [fRate,iSel] = deal(exObj.objIMAQ.FPS,1);

elseif exObj.isWebCam
    % case is a webcam device
    [fRate,~,iSel] = detWebcamFrameRate(exObj.objIMAQ,FPS);
    
elseif exObj.isMemLog
    % case is a Video Device
    dProps = exObj.objIMAQ.DeviceProperties;
    [fRate,iSel] = deal(str2double(dProps.FrameRate),1);
    
else
    % case is the video input device
    srcObj = getselectedsource(exObj.objIMAQ);
    [fRate,~,iSel] = detCameraFrameRate(srcObj,FPS);
end
