function isUVC = isCamUVC(devName)

% sets the flag based on the camera type
switch devName
    case {'UV155xLE-C_3500006372','Integrated Webcam'}
%     case {'UV155xLE-C_3500006372'}    
        % case is a UVC camera type
        isUVC = true;

    otherwise
        % case is another camera type
        isUVC = false;
end