function privateslcbpreview(dialog)
%PRIVATESLCBPREVIEW Opens the preview window for the device selected. 
%
%    PRIVATESLCBPREVIEW (DIALOG) Opens the preview window for the device
%    currently being selected in the from video device.

%    SS 09-19-06
%    Copyright 2006-2008 The MathWorks, Inc.

% Get the source object. 
ddgObj = dialog.getDialogSource;

try
    % Open the preview window for the device. 
    preview(ddgObj.IMAQObject);
catch exception
    errorStrings = privateimaqslstring('errorstrings');
    msg1 = sprintf(errorStrings.ProblemWithPreviewing, ddgObj.Device);
    errMsg = sprintf('%s\n\n%s', msg1, exception.message);
    % Call T&M function to display error dialog.
    tamslgate('privatesldialogbox', dialog, ...
                                errMsg, ...
                                errorStrings.ErrorDialogTitle);    
    return;
end
% Adjust the ROI Position value. 
privateimaqsladjustroi(ddgObj);