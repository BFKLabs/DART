% --- determines the properties field the control frame rate (dependent
%     on the camera type being used)
function fpsFld = getCameraRatePara(srcObj)

if isprop(srcObj,'FrameRate')
    fpsFld = 'FrameRate';
    
elseif isprop(srcObj,'DeviceVendorName')
    switch get(srcObj,'DeviceVendorName')
        case {'Allied Vision','Basler'}
            fpsFld = 'AcquisitionFrameRate';
    end
end
