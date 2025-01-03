function isUVC = isCamUVC(devName)

% HARD CODE FIX - recording as webcam doesn't allow for higher frame rates
if startsWith(devName,'UV155xLE')
    isUVC = false;
    return;
end

% determines if the device is in the webcam list
if exist('webcamlist','file')
    % uses the webcamlist to determine device type
    try
        isUVC = any(strcmp(webcamlist,devName));
    catch
        isUVC = false;
    end
    
else
    % manually sets the flag based on the camera type
    switch devName
        case {'UV155xLE-C_3500006372','Integrated Webcam'}
            % case is a UVC camera type
            isUVC = true;

        otherwise
            % case is another camera type
            isUVC = false;
    end
end
