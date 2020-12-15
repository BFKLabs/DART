% --- sets the object font sizes within a GUI with object handles, handles
function setGUIFontSize(handles)

% determines the screen resolution 
pos = get(0,'MonitorPositions'); 
scRes = pos(1,3:4);

% sets the font sizes for all of the GUI objects
switch (scRes(1))
    case (1920)
        fSize = [13 12 11 10];        
    otherwise
        fSize = [12 11 10 9];
end

% retrieves all the field names (removes any infeasible objects)
fldName = fieldnames(handles);
hObj = getStructFields(handles);
isFeas = cellfun(@(x)(any(ishandle(x))),hObj);
[fldName,hObj] = deal(fldName(isFeas),hObj(isFeas));

% retrieves all the object types
fldType = cellfun(@(x)(get(x,'type')),hObj,'un',false);
                                
% retrieves the main figure handle                                 
hFig = fldName{find(strcmp(fldType,'figure'),1)};
                                
% loops through all of the objects setting the font sizes
for i = 1:length(fldName)
    % retrieves the new object handle
    hObj = eval(sprintf('handles.%s',fldName{i}));
    
    %
    if ~iscell(fldType{i})
        fldType{i} = {fldType{i}};
    end
    
    % sets the fonts based on the 
    for j = 1:length(fldType{i})
        switch (fldType{i}{j})            
            case {'uipanel','uibuttongroup'}
                % determines the panel type
                if (strcmp(hFig,get(get(hObj,'Parent'),'Tag')))
                    % main panel, so use the large font                                
                    set(hObj,'FontSize',fSize(1));
                else
                    % sub-panel, so use the medium font                                                
                    set(hObj,'FontSize',fSize(2));                
                end
            case ('uicontrol')
                % determines the uicontrol type
                switch (get(hObj,'style'))
                    case ('uitable')
                        % type is a table, so use the small font
                        set(hObj,'FontSize',fSize(4));      
                    case {'edit','listbox'}
                        % type is a table, so use the small font
                        set(hObj,'FontSize',fSize(3));     
                    case {'popupmenu'}
                    otherwise
                        % otherwise, use the medium font                
                        set(hObj,'FontSize',fSize(2));                                
                end
        end
    end
end
