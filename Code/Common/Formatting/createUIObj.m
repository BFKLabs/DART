% --- creates the ui object based on the matlab version type
function hObj = createUIObj(fType,varargin)

% parameters
hObj = [];
p = varargin(2:end);

if strcmpi(fType,'figure')
    % case is creating a figure
    isOldVer = true;
%     isOldVer = verLessThan('matlab','9.10');

elseif isa(varargin{1},'matlab.ui.Figure')
    % case is the parent object is a figure
    try
        isOldVer = ~matlab.ui.internal.isUIFigure(varargin{1});
    catch
        isOldVer = true;
    end

else
    % case is the other objects
    hObj = varargin{1};
    while 1
        hObj = get(hObj,'Parent');
        if isa(hObj,'matlab.ui.Figure')
            try
                isOldVer = ~matlab.ui.internal.isUIFigure(hObj);
            catch
                isOldVer = true;
            end
                
            break
        end
    end
end

% creates the object based on matlab version type
if isOldVer
    % case is using an older version of matlab
    switch lower(fType)
        case 'figure'
            % case is the figure object
            [hObj,p] = deal(figure(),varargin);

        case 'table'
            % case is the table object
            hObj = uitable(varargin{1},'FontUnits','Pixels');            
            
        case 'panel'
            % case is the panel object
            hObj = uipanel(varargin{1},'FontUnits','Pixels');
            
        case 'axes'
            % case is an axes object
            hObj = axes(varargin{1},'FontUnits','Pixels');
                        
        case 'tabgroup'
            % case is a tab group object
            hObj = createTabGroup();
            set(hObj,'Parent',varargin{1},'Units','pixels');
            
        case 'tab'
            % case is a tab object
            hObj = createNewTab(varargin{1});            
            
        otherwise
            % case is the other object types
            hObj = uicontrol...
                (varargin{1},'Style',fType,'FontUnits','Pixels');
            
    end        
    
    % sets the object units
    set(hObj,'Units','Pixels');
    
else
    % case is using a newer version of matlab    
    switch lower(fType)
        case 'figure'
            % case is the figure object
            [hObj,p] = deal(uifigure(),varargin);

        case 'table'
            % case is the table objects
            hObj = uitable(varargin{1});            
            
        case 'panel'
            % case is the panel objects
            hObj = uipanel(varargin{1},'AutoResizeChildren','off');
            
        case 'text'
            % case is a text label
            hObj = uilabel(varargin{1});
            
        case 'edit'
            % case is an editbox
            hObj = uieditfield(varargin{1});
            
        case 'checkbox'
            % case is a checkbox
            hObj = uicheckbox(varargin{1});

        case 'pushbutton'
            % case is a pushbutton
            hObj = uibutton(varargin{1});            
            
        case 'togglebutton'
            % case is a togglebutton
            hObj = uibutton(varargin{1},'State');
            
        case 'popupmenu'
            % case is a popupmenu
            hObj = uidropdown(varargin{1});
            
        case 'axes'
            % case is an axes
            hObj = uiaxes(varargin{1});
            
        case 'listbox'
            % case is a listbox
            hObj = uilistbox(varargin{1});

        case 'tabgroup'
            % case is a tab group object
            hObj = uitabgroup(varargin{1},'Units','pixels');
            drawnow
            pause(0.05);
            
        case 'tab'
            % case is a tab object            
            hObj = uitab(varargin{1},'Units','pixels');
            
        case 'uitextarea'
            % case is an axes object
            hObj = uitextarea(varargin{1});            
            
        case 'uihtml'
            % case is an axes object
            hObj = uihtml(varargin{1});            
            
        otherwise
            % REMOVE ME
            a = 1;
            
    end            
end

% if no object was created, then exit
if isempty(hObj); return; end

% sets the object's other properties
nProp = length(p)/2;
for i = 1:nProp    
    % sets the property field/value
    [pFld,pVal] = deal(p{2*i-1},p{2*i});
    
    % sets the properties (based on type/version)
    switch lower(pFld)
        case 'string'
            % case is the string field
            if ~isOldVer
                % case is using an older version of matlab
                switch lower(fType)
                    case 'edit'
                        pFld = 'Value';
                   
                    otherwise
                        pFld = 'Text';
                end                                                
            end
            
        case 'text'
            % case is the string field
            if isOldVer
                pFld = 'String';
            end
            
        case 'cdata'
            % case is button cData field
            if ~isOldVer
                pFld = 'Icon';
            end                        
            
        case 'items'
            % case are listbox/popupmenu items
            if isOldVer
                pFld = 'String';
            end            
            
        case {'valuechangedfcn','buttonpushedfcn'}
            % case are certain object callback functions
            if isOldVer
                pFld = 'Callback';
            end                  
    end

    % case is the other property types
    set(hObj,pFld,pVal);        
end