function privateslcbcolorspace(dialog, tag)
%PRIVATESLCBCOLORSPACE Validates the color space entry in the IAT SL block.
%
%    PRIVATESLCBCOLORSPACE(DIALOG, TAG) validates the color space entry
%    in the IAT SL block.

%    SS 05-19-11
%    Copyright 2011 The MathWorks, Inc.

% Get the dialog source object. 
obj = dialog.getDialogSource;

%G465436: Situation where model explorer and block mask from Simulink are
%used simultaneously and block mask is closed. At this point, the object
%created underneath is deleted. If ROI is changed at this point in the
%model explorer, it actually errors out mentioning no object is present.
%Performing a dialog refresh creates the object if required. 
if isempty(obj.IMAQObject) || ~isvalid(obj.IMAQObject)
    dialog.refresh();
end

% Get all the tags associated with the block. 
tags = imaqslgate('privateimaqslstring', 'tags');

% Assign the updated value to source object. 
switch tag
    case tags.ColorSpace
        % Set the value to the device.
        set(obj.IMAQObject,'ReturnedColorspace', obj.(tag));
        obj.ReturnedColorspace = obj.(tag);
    case tags.BayerSensorAlignment
        % Set the value to the device.
        set(obj.IMAQObject,'BayerSensorAlignment', obj.(tag));
    otherwise
        assert(false);
end
dialog.refresh();
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%