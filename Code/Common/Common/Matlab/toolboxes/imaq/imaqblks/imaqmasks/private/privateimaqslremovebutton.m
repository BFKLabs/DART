function privateimaqslremovebutton(dialog)
%PRIVATEIMAQSLREMOVEBUTTON Removes the selected metadata(s) from the listbox. 
%
%    PRIVATEIMAQSLREMOVEBUTTON (DIALOG) Removes the selected metadata(s) 
%    from the listbox. 

%    AD 03-22-13
%    Copyright 2013 The MathWorks, Inc.

% Get the dialog source. 
obj = dialog.getDialogSource;

% Get the widget tags. 
tags = privateimaqslstring('tags');

% Get the fields that are selected.
values = dialog.getWidgetValue(tags.SelectedMetadata);

% Return if none selected.
if isempty(values)
    %TODO: Should we warn?
    % uiwait(warndlg('Please select a measurement from the Selected Measurements Listbox before using the delete button.', 'Warning', 'modal'));
    return;
end

% Make 1-based.
values = values + 1;

listOfSelectedMetadata = privateimaqslgetentries(obj.SelectedMetadata);

allList = 1:length(listOfSelectedMetadata);

finalList = listOfSelectedMetadata(~ismember(allList, values));
finalListStr = sprintf('%s;', finalList{:});
obj.SelectedMetadata = finalListStr(1:end-1);

% Refresh dialog
dialog.refresh;

% Select the ones deleted in the all measurements list.
deletedList = listOfSelectedMetadata(ismember(allList, values));
allMeasList = privateimaqslgetentries(obj.AllMetadata);
indices = find(ismember(allMeasList, deletedList));
dialog.setWidgetValue(tags.AllMetadata, []);
dialog.setWidgetValue(tags.AllMetadata, indices-1);

% Enable the apply button.
dialog.enableApplyButton(true);
