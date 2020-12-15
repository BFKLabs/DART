function privateslcbformat(dialog, tag)
%PRIVATESLCBFORMAT Callback when a format is changed in the IAT SL block.
%
%    PRIVATESLCBFORMAT(DIALOG, TAG) Callback when a different video format
%    is selected in the From Video Device block. 
%

%    SS 09-19-06
%    Copyright 2006-2008 The MathWorks, Inc.

% Get the dialog source object. 
obj = dialog.getDialogSource;

% Get the widget tags.
tags = privateimaqslstring('tags');

% If there are no devices, just return. 
if strcmp(obj.VideoFormatMenu,'(none)') 
    return;
end

switch tag
    case tags.VideoFormatMenu % A Video format is selected.
        % If the same format were selected, just return.
        if strcmp(obj.VideoFormat, obj.VideoFormatMenu)
            return;
        end
        % Set is different format to true. 
        obj.IsDifferentFormat = true;
        obj.VideoFormat = obj.VideoFormatMenu;
        obj.Block.VideoFormatMenu = obj.VideoFormatMenu;
    case {tags.CameraFile tags.Browse} % A Camera file is selected. 
        % Validate the camera file.
        errMsg = localValidateCameraFile(obj);
        if ~isempty(errMsg)
            % Get the error strings.
            errorStrings = privateimaqslstring('errorstrings');
            errMsg = sprintf('%s\n\n%s', errorStrings.WrongCameraFile, errMsg);
            errMsg = sprintf(errMsg, obj.Block.CameraFile);
            % Call T&M function to display error dialog.
            tamslgate('privatesldialogbox', dialog, ...
                                        errMsg, ...
                                        errorStrings.ErrorDialogTitle);            
            obj.Block.CameraFile = obj.CameraFile;
            return;
        end

        % Set is different format to true. 
        obj.IsDifferentFormat = true;
        obj.CameraFile = obj.Block.CameraFile;
end

% Call dialog refresh to update the settings to the new format. 
dialog.refresh();
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function errMsg = localValidateCameraFile(obj)

% Initialize error message. 
errMsg = [];

% Form the object constructor.
objectConstructor = strrep(obj.ObjConstructor,')',[',''' obj.Block.CameraFile ''')']);
try
    % Create temporary IMAQ Object.
    tempImaqObj = eval(objectConstructor);
catch exception
    % Display error.
    errMsg = exception.message;
    return;
end

% Delete the temporary IMAQ Object.
delete(tempImaqObj);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%