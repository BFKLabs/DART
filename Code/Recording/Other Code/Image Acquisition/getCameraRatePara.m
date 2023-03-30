% --- determines the properties field the control frame rate (dependent
%     on the camera type being used)
function fpsFld = getCameraRatePara(srcObj)

switch get(srcObj,'DeviceVendorName')
    case {'Allied Vision','Basler'}
        fpsFld = 'AcquisitionFrameRate';
end
