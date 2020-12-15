function privateimaqslmovedownbutton(dialog)
%PRIVATEIMAQSLMOVEDOWNBUTTON Moves the selected measurement(s) down in the listbox. 
%
%    PRIVATEIMAQSLMOVEDOWNBUTTON (DIALOG) Moves the selected measurement(s) 
%    down in the listbox. 

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
tempRows = rows(end:-1:1);
tempRows = tempRows + 1;
if isempty(find(tempRows>(length(metadata)-1) , 1))
    % We can move successfully.
    metadatasToMove = cell(length(rows), 2);
    for idx = length(rows):-1:1
        metadataToMove = metadata{rows(idx)+1};
        rowToMoveAfter = rows(idx)+1;
        metadataToMoveAfter = metadata{rowToMoveAfter + 1};
        metadatasToMove{idx,1} = metadataToMove;
        metadatasToMove{idx,2} = metadataToMoveAfter;
    end
    if (length(rows)==1)
        metadata = swapMetadatas(metadata, metadatasToMove{1}, metadatasToMove{2});
    else
        num = length(metadatasToMove);
        for idx = 1:num
            metadata = swapMetadatas(metadata, metadatasToMove{idx, 1}, metadatasToMove{idx, 2});
        end
    end
    finalMeasStr = sprintf('%s;', metadata{:});
    obj.SelectedMetadata = finalMeasStr(1:end-1);
    
    dialog.setWidgetValue(tags.SelectedMetadata, []);
    dialog.setWidgetValue(tags.SelectedMetadata, rows+1);
    
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
tmpMeasurement = metadata{id1};
metadata{id1} = metadata{id2};
metadata{id2} = tmpMeasurement; 
