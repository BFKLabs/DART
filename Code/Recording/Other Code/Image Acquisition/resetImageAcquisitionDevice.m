% --- resets the image acquisition device
function resetImageAcquisitionDevice(obj,resetFlds)

% default input arguments
if ~exist('resetFlds','var')
    resetFlds = true;
end

% field retrieval
if isprop(obj,'hMain')
    [hFigM,useVD] = deal(obj.hMain,obj.isMemLog);
elseif isprop(obj,'hFig')
    [hFigM,useVD] = deal(obj.hFig,obj.useVD);
end

% field retrieval
infoObj = getappdata(hFigM,'infoObj');
vInfo = infoObj.vIndIMAQ(infoObj.vSelIMAQ,:);
devInfo = infoObj.objIMAQDev{vInfo(1)}(vInfo(2));
vForm0 = obj.objIMAQ.VideoFormat;

% % resets the video format
% devInfo.DefaultFormat = obj.objIMAQ.VideoFormat;

if isVidDev(obj.objIMAQ)
    pROI0 = obj.objIMAQ.ROI;
    if ~useVD
        pROI0(1:2) = pROI0(1:2) - 1;
    end
else
    pROI0 = get(obj.objIMAQ,'ROIPosition');
    if useVD
        pROI0(1:2) = pROI0(1:2) + 1;
    end
end

if useVD
    % case is memory logging (imaq.VideoDevice)
    conStr = setupConstructorString(devInfo.VideoDeviceConstructor,vForm0);
    obj.objIMAQ = eval(conStr);
    
    % sets the device properties
%     obj.objIMAQ.Device = devInfo.DeviceName;
    obj.objIMAQ.ReturnedDataType = 'uint8';    
    obj.objIMAQ.ROI = pROI0;
    
else
    % case is disk logging (videoinput)
    conStr = setupConstructorString(devInfo.VideoInputConstructor,vForm0);
    obj.objIMAQ = eval(conStr);
    
    % sets the trigger configuration flag
    triggerconfig(obj.objIMAQ,'manual')
    
    % sets the device properties
    obj.objIMAQ.LoggingMode = 'disk';
    obj.objIMAQ.Name = devInfo.DeviceName;    
    set(obj.objIMAQ,'ROIPosition',pROI0);    
end

% sets the common device fields
obj.objIMAQ.ReturnedColorSpace = 'grayscale';

% updates the object information struct in the main GUI
infoObj.objIMAQ = obj.objIMAQ;
setappdata(hFigM,'infoObj',infoObj);

% resets any ROI parameters
if resetFlds
    resetCameraROIPara(obj.objIMAQ)
    applyDefaultDeviceProps(infoObj,devInfo.DeviceName);
end

% --- sets up the video constructor string
function conStr = setupConstructorString(conStr0,vForm0)

conStr = sprintf('%s, ''%s'')',conStr0(1:(end-1)),vForm0);