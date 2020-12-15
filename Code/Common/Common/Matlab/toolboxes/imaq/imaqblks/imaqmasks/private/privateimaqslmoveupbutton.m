function privateimaqslmoveupbutton(dialog)
%PRIVATEIMAQSLMOVEUPBUTTON Moves the selected metadata(s) up in the listbox. 
%
%    PRIVATEIMAQSLMOVEUPBUTTON (DIALOG) Moves the selected metadata(s) 
%    up in the listbox. 

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
    return;
end

% Get all filtered measurements
metadata = privateimaqslgetentries(obj.SelectedMetadata);

% Determine the rows to swap with. 
rows = sort(values);
tempRows = values - 1;

if isempty(find(tempRows<0, 1))
    % We can move successfully.
    metadatasToMove = cell(length(rows), 2);
    for idx = 1:length(rows)
        metadataToMove = metadata{rows(idx)+1};
        rowToMoveBefore = rows(idx)-1;
        metadataToMoveBefore = metadata{rowToMoveBefore + 1};
        metadatasToMove{idx,1} = metadataToMove;
        metadatasToMove{idx,2} = metadataToMoveBefore;
    end
    if (length(rows)==1)
        metadata = swapMetadatas(metadata, metadatasToMove{1}, metadatasToMove{2});
    else
        for idx = length(metadatasToMove):-1:1
            metadata = swapMetadatas(metadata, metadatasToMove{idx, 1}, metadatasToMove{idx, 2});
        end
    end
    finalMeasStr = sprintf('%s;', metadata{:});
    obj.SelectedMetadata = finalMeasStr(1:end-1);
    
    dialog.setWidgetValue(tags.SelectedMetadata, []);
    dialog.setWidgetValue(tags.SelectedMetadata, rows-1);
    % Refresh dialog
    dialog.refresh;
    
    % Enable the apply button.
    dialog.enableApplyButton(true);    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Swap two measurements.
function metadata = swapMetadatas(metadata, p1, p2)

id1 = find(strcmp(p1, metadata),1);
id2 = find(strcmp(p2, metadata),1);
tmpMetadata = metadata{id1};
metadata{id1} = metadata{id2};
metadata{id2} = tmpMetadata; 

