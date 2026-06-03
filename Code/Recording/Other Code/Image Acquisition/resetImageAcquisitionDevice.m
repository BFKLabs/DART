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

if useVD
    % case is memory logging (imaq.VideoDevice)
    obj.objIMAQ = eval(devInfo.VideoDeviceConstructor);
    
    % sets the device properties
    obj.objIMAQ.Device = devInfo.DeviceName;
    obj.objIMAQ.ReturnedDataType = 'uint8';
else
    % case is disk logging (videoinput)
    obj.objIMAQ = eval(devInfo.VideoInputConstructor);
    
    % sets the trigger configuration flag
    triggerconfig(obj.objIMAQ,'manual')
    
    % sets the device properties
    obj.objIMAQ.LoggingMode = 'disk';
    obj.objIMAQ.Name = devInfo.DeviceName;
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