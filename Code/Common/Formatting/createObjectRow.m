function hObj = createObjectRow(hP,nObj,pType,wObj,varargin)

% sets up the input parser
ip = inputParser;
addParameter(ip,'xOfs0',10);
addParameter(ip,'dxOfs',5);
addParameter(ip,'yOfs',10);
addParameter(ip,'hghtTxt',16);
addParameter(ip,'hghtEdit',22);
addParameter(ip,'hghtBut',25);
addParameter(ip,'hghtPopup',22);
addParameter(ip,'hghtChk',21);
addParameter(ip,'hghtRadio',23);
addParameter(ip,'hghtObj',[]);
addParameter(ip,'fSz',12);
addParameter(ip,'pStr',[]);

% parses the input arguments
parse(ip,varargin{:})
p = ip.Results;

% converts any string names to cell arrays
if ~iscell(pType); pType = {pType}; end

% ensures the type array is the correct length
if length(pType) ~= nObj
    pType = repmat(pType(1),nObj,1);
end

% ensures the width array is the correct length
if length(wObj) ~= nObj
    wObj = wObj(1)*ones(nObj,1);
end

% calculates the object offsets
hghtObj = cellfun(@(x)(getObjectHeight(p,x)),pType);
dyOfs = ceil((min(hghtObj) - hghtObj)/2);

% creates the objects
hObj = cell(nObj,1);
for i = 1:nObj
    % sets up the position vector
    xOfs = p.xOfs0 + (i-1)*p.dxOfs + sum(wObj(1:(i-1)));
    pPos = [xOfs,p.yOfs+dyOfs(i),wObj(i),hghtObj(i)];
    fSzObj = getFontSize(p,pType{i});
    
    % creates the object
    hObj{i} = createUIObj(pType{i},hP,...
        'Position',pPos,'FontUnits','pixels','FontSize',fSzObj);
    
    % sets the string field (if provided)
    if ~isempty(p.pStr) && ~isempty(p.pStr{i})
        set(hObj{i},'String',p.pStr{i});
    end    
    
    % sets the object specific properties
    switch lower(pType{i})
        case 'text'
            % case is a text object
            set(hObj{i},'FontWeight','Bold'); 

        case {'pushbutton','togglebutton','radiobutton','checkbox'}        
            % case is a button object
            set(hObj{i},'FontWeight','Bold');            
            
        case 'popupmenu'
            % case is a popupmenu item
            set(hObj{i},'String',{' '},'Value',1);            
    end    
end

% --- retrieves the object specific properties
function hObj = getObjectHeight(p,pType)

switch lower(pType)
    case 'text'
        % case is text label
        hObj = p.hghtTxt;
        
    case {'pushbutton','togglebutton'}
        % case is pushbutton/togglebutton
        hObj = p.hghtBut;

    case 'radiobutton'
        % case is the editbox
        hObj = p.hghtRadio;        
        
    case 'edit'
        % case is the editbox
        hObj = p.hghtEdit;
        
    case 'popupmenu'        
        % case is a popup menu
        hObj = p.hghtPopup;
        
    case 'checkbox'        
        % case is a checkbox
        hObj = p.hghtChk;        
        
    otherwise
        % case is the other object types
        hObj = p.hghtObj;
end

% --- retrieves the object fontsize
function fSzObj = getFontSize(p,pType)

switch lower(pType)
    case {'popupmenu','edit','listbox'}
        % case is either popupmenu, editbox, or listbox
        fSzObj = 10 + 2/3;
        
    otherwise
        % case is the other object types
        fSzObj = p.fSz;
end