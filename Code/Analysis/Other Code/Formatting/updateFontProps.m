% --- updates the object, hObj, with the font data struct, Font --- %
function updateFontProps(hObj,Font,ind,Type)

% global variables
global regSz newSz

% ensures the objects are stored in a cell array
if ~iscell(hObj); hObj = num2cell(hObj); end

% determines the font ratio
if isempty(newSz) || isempty(regSz)
    fR = 1;
else
    fR = min(newSz(3:4)./regSz(3:4))*get(0,'ScreenPixelsPerInch')/72;
end

% sets the subplot index to one (if not provided)
if nargin < 3
    ind = 1;
elseif (nargin == 4) && strcmp(Type,'Axis')
    ind = getCurrentAxesProp('UserData');
end 

% retrieves the font struct field-names
fStr = fieldnames(Font);

% updates the font struct field
for j = 1:length(hObj)
    % sets the object tag (if not an axis item)
    if nargin == 4
        if ~(strcmp(Type,'Axis') || strcmp(Type,'Legend'))
            set(hObj{j},'Tag',Type)
        end
    end
    
    % retrieves the title/label properties 
    if strcmp(get(hObj{j},'Type'),'axes')
        hObjT = {get(hObj{j},'Title'),...
                 get(hObj{j},'XLabel'),...
                 get(hObj{j},'YLabel')};
        hProp0 = getHandleSnapshot(hObjT);
    end    
        
    % updates all the legend font properties    
    for i = 1:length(fStr)
        % evaluates the new property value
        fNw = eval(sprintf('Font.%s',fStr{i}));
        
        % sets the property values based on the type
        switch fStr{i}
            case ('Color') % case is the font colour
                if (strcmp(get(hObj{j},'Type'),'axes'))
                    set(hObj{j},'xColor',fNw,'UserData',ind)
                    set(hObj{j},'yColor',fNw,'UserData',ind)
                else
                    set(hObj{j},fStr{i},fNw,'UserData',ind)
                end
            case ('FontSize') % case is the font size                  
                % updates the object font-size
                set(hObj{j},'FontUnits','pixels','UserData',ind)
                set(hObj{j},'FontSize',setMinFontSize(fNw*fR,Type))                
            case ('Axis')
                % other cases
                set(hObj{j},fStr{i},fNw)                
            otherwise % other cases
                set(hObj{j},fStr{i},fNw,'UserData',ind)
        end
    end
    
    % resets the title/label properties (for HG2)
    if strcmp(get(hObj{j},'Type'),'axes')
        resetHandleSnapshot(hProp0)        
    end    
end