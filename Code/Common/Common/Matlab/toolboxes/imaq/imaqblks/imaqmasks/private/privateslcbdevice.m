function privateslcbdevice(dialog)
%PRIVATESLCBDEVICE Callback when a device is changed in the IAT SL block.
%
%    PRIVATESLCBDEVICE(DIALOG) Callback executed when a different device is
%    selected in the From Video Device block. 
%

%    SS 09-19-06
%    Copyright 2006-2007 The MathWorks, Inc.

% Get the dialog source object. 
obj = dialog.getDialogSource;

% If there are no devices or same device was selected, just return. 
if strcmp(obj.DeviceMenu,'(none)') || ...
    strcmp(obj.Device, obj.DeviceMenu)
    return;
end

% Set ShowErrorPopUp to true, workaround for dcam. 
obj.ShowErrorPopUp = true;

% Reflect the new device settings.
obj.Device = obj.DeviceMenu;

% Set is different device to true. 
obj.IsDifferentDevice = true;

% Since device is different do not load user data from block structure.
obj.IsUserDataInvalid = true;

% Call dialog refresh to update the settings to the new device. 
dialog.refresh();