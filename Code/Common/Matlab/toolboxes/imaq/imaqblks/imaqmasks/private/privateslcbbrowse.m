function privateslcbbrowse(dialog, tag)
%PRIVATESLCBBROWSE Opens a file open window to select a camera file. 
%
%    PRIVATESLCBBROWSE (DIALOG, TAG) Opens a file open window to select a camera
%    file. 

%    SS 09-19-06
%    Copyright 2006 The MathWorks, Inc.

% Get the dialog source. 
obj = dialog.getDialogSource;

% Get the widget tags. 
tags = privateimaqslstring('tags');

% Open the dialog to select the camera file.
[filename, pathname] = uigetfile({'*.*', 'All Files(*.*)'},...
                        'Select the camera file', obj.CameraFile);

% Check if a selection was made. 
if ~(isequal(filename,0) || isequal(pathname,0))
    % Set the value on the block dialog. 
    dialog.setWidgetValue(tags.CameraFile, [pathname filename]);
    % Call callback for video format.
    privateslcbformat(dialog, tag);
end

