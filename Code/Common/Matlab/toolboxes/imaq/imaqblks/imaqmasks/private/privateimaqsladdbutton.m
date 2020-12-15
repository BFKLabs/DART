function privateimaqsladdbutton(dialog)
%PRIVATEIMAQSLADDBUTTON Adds the selected measurement(s) to the listbox. 
%
%    PRIVATEIMAQSLADDBUTTON (DIALOG) Adds the selected measurement(s) 
%    to the listbox. 

%    AD 03-22-13
%    Copyright 2013 The MathWorks, Inc.

% Get the dialog source. 
obj = dialog.getDialogSource;

% Get the widget tags. 
tags = privateimaqslstring('tags');

% Get the fields that are selected.
values = dialog.getWidgetValue(tags.AllMetadata);

% Return if none selected.
if isempty(values)
    return;
end

% Make 1-based.
values = values + 1;

% Get all the metadata
metadata = privateimaqslgetentries(obj.AllMetadata);
metadataToAdd = metadata(values);

% Get current list of selected metadata
currentMetaList = privateimaqslgetentries(obj.SelectedMetadata);

% Get a final list.
actualMetaToAdd = metadataToAdd(~ismember(metadataToAdd, currentMetaList));
if isempty(actualMetaToAdd)
    indices = find(ismember(currentMetaList, metadataToAdd));
    dialog.setWidgetValue(tags.SelectedMetadata, []);
    dialog.setWidgetValue(tags.SelectedMetadata, indices-1);
    % Nothing to add.
    return;
end
metadataToAddStr = sprintf('%s;', actualMetaToAdd{:});
if ~isempty(obj.SelectedMetadata)
    obj.SelectedMetadata = sprintf('%s;%s', obj.SelectedMetadata, metadataToAddStr(1:end-1));
else
    obj.SelectedMetadata = metadataToAddStr(1:end-1);
end

% Refresh dialog
dialog.refresh;

% Enable the apply button.
dialog.enableApplyButton(true);
