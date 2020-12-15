% --- retrieves a snapshot of the object handles properties --- %  
function hProp = getHandleSnapshot(handles)

% retrieves the object handles
if isstruct(handles)
    % retrieves the field names of all the objects within handles
    strFld = getStructFields(handles);
    
    % retrieves the valid object handles
    hObj = cell2cell(strFld,0)';
    isH = logical(cell2cell(cellfun(@(x)(ishandle(x)),strFld,'un',0),0)');    
    hObj = hObj(isH);           
else
    % case is the object handles have already been provided
    hObj = handles;
end

% memory allocation
nObj = length(hObj);      
hProp = repmat(struct('hObj',[],'data',[]),nObj,1);
isValid = true(nObj,1);

% loops through all the objects retrieving the relevant data fields
for i = 1:nObj
    % retrieves the current object handle
    if iscell(hObj)
        hProp(i).hObj = hObj{i};
    else
        hProp(i).hObj = hObj(i);
    end
            
    % sets the data array based on the object type
    switch (get(hProp(i).hObj,'Type'))                
        case ('uicontrol') % case is a control ite
            switch (get(hProp(i).hObj,'Style'))
                case ('checkbox') % object is a checkbox
                    data = cell(2,2);
                    data{1,1} = 'Value';
                    data{2,1} = 'Enable';                                          
                    data{3,1} = 'Visible';
                    data{4,1} = 'Position';                                        
                case ('edit') % object is an editbox
                    data = cell(2,2);       
                    data{1,1} = 'String';                       
                    data{2,1} = 'Enable';  
                    data{3,1} = 'Visible';
                    data{4,1} = 'Position';                    
                case {'pushbutton','togglebutton'} % object is a button
                    data = cell(3,2);   
                    data{1,1} = 'String';                       
                    data{2,1} = 'Enable';    
                    data{3,1} = 'Visible'; 
                    data{4,1} = 'Position';                    
                case ('radiobutton') % object is a radiobutton
                    data = cell(2,2);  
                    data{1,1} = 'Value';                       
                    data{2,1} = 'Enable';                       
                    data{3,1} = 'Visible';
                    data{4,1} = 'Position';                    
                case ('text') % object is a textbox
                    data = cell(4,2);
                    data{1,1} = 'String';
                    data{2,1} = 'Enable';                                                                            
                    data{3,1} = 'Visible';
                    data{4,1} = 'Position';
            end
        case ('uimenu') % case is a menu item
            data = cell(2,2);
            data{1,1} = 'Checked';
            data{2,1} = 'Enable'; 
        case ('uipanel') % case is a panel item
            data = cell(3,2);
            data{1,1} = 'ForegroundColor';
            data{2,1} = 'Visible';
            data{3,1} = 'Position';
        case ('axes')
            data = cell(2,2);
            data{1,1} = 'Visible';            
            data{2,1} = 'Position';
        case ('image')
            data = cell(1,2);
            data{1,1} = 'Visible';     
        case ('figure')
            data = cell(1,2);
            data{1,1} = 'Position';      
        case ('text')
            data = cell(2,2);
            data{1,1} = 'FontSize';      
            data{2,1} = 'Color';
        otherwise % we are not concerned with the other objects
            isValid(i) = false;
    end
    
    % retrieves the specified data fields (if a valid object type)
    if (isValid(i))        
        % sets the properties into the data struct
        data(:,2) = get(hProp(i).hObj,data(:,1))';
        hProp(i).data = data;        
    end
end

% removes the invalid objects from the property array
hProp = hProp(isValid);