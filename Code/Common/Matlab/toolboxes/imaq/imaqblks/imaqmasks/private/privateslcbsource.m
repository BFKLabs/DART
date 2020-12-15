function privateslcbsource(dialog)
%PRIVATESLCBSOURCE Validates the video source setting in the IAT SL block.
%
%    PRIVATESLCBSOURCE(DIALOG) validates the video source set in the From
%    Video Device block. 
%

%    SS 09-19-06
%    Copyright 2006 The MathWorks, Inc.

% Get the dialog source object. 
obj = dialog.getDialogSource;

% If there are no sources, just return. 
if strcmp(obj.Block.VideoSource,'(none)')
    return;
end

% Set the value on the underlying IMAQ object. 
set(obj.IMAQObject,'SelectedSourceName',obj.VideoSource);

% Set is different source to true. 
obj.IsDifferentSource = true;

% Call dialog refresh to update the settings to the new device. 
dialog.refresh();