function privateslcbprop(dialog)
%PRIVATESLCBPROP Opens the property inspector for the selected video source. 
%
%    PRIVATESLCBPROP (DIALOG) Opens the inspector window for the source
%    that is currently selected in the From Video Device Block. 

%    SS 09-19-06
%    Copyright 2006-2013 The MathWorks, Inc.

% Get the source object. 
obj = dialog.getDialogSource;

% Enable the Apply button. 
% G359043 -->APPLY button is not present in FVD block mask. However when the
% dialog is opened in Model Explorer window, it consists of an APPLY
% button. The following line of code is required to enable the 'APPLY'
% button when user clicks on 'Edit Properties'. This ensures that user can
% save video source properties through model explorer as well. 
% dialog.enableApplyButton(true);

% Open property inspector for the selected source.
srcObj = getselectedsource(obj.IMAQObject);

% Call inspect.
inspect(srcObj);

% Set 'being inspected' to true.
obj.IsBeingInspected = true;