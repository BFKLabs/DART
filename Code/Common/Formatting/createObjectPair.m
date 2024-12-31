function [hObjM,hObjL] = createObjectPair(hP,tTxtL,wObjL,pTypeM,varargin)

% sets the default input argument
if ~exist('pTypeM','var'); pTypeM = 'text'; end

% sets up the input parser
ip = inputParser;
addParameter(ip,'pTypeL','text');
addParameter(ip,'xOfs',10);
addParameter(ip,'yOfs',10);
addParameter(ip,'wObjM',[]);
addParameter(ip,'wObjTot',[]);
addParameter(ip,'hghtTxt',16);
addParameter(ip,'hghtEdit',22);
addParameter(ip,'hghtBut',25);
addParameter(ip,'hghtPopup',22);
addParameter(ip,'fSzL',12);
addParameter(ip,'fSzM',10+2/3);
addParameter(ip,'useColon',true);
addParameter(ip,'cbFcnM',[]);

% parses the input arguments
parse(ip,varargin{:})
p = ip.Results;

% initialisations
if isempty(p.wObjM)
    if isempty(p.wObjTot)
        pPosP = getpixelposition(hP);
        wObjM = pPosP(3) - (20 + wObjL);    
    else
        wObjM = p.wObjTot - (20 + wObjL);
    end
else
    wObjM = p.wObjM;    
end

% sets up the string
if p.useColon
    tTxtL = sprintf('%s: ',tTxtL);
end

% retrieves the object heights
hghtObjM = getObjectHeight(p,pTypeM);
hghtObjL = getObjectHeight(p,p.pTypeL);
[dyObjM,dyObjL] = getObjectOffset(pTypeM,p.pTypeL);

% creates the label object
pPosL = [p.xOfs,p.yOfs-dyObjL,wObjL,hghtObjL];
hObjL = createUIObj(p.pTypeL,hP,'Position',pPosL,'String',tTxtL,...
    'FontWeight','Bold','HorizontalAlignment','Right',...
    'FontSize',p.fSzL);

% sets the label object specific properites
switch p.pTypeL
    case {'pushbutton','togglebutton'}
        set(hObjL,'HorizontalAlignment','Center');                
end

% creates the main object
xOfsM = sum(pPosL([1,3]));
pPosM = [xOfsM,p.yOfs-dyObjM,wObjM,hghtObjM];
hObjM = createUIObj(pTypeM,hP,'Callback',p.cbFcnM,...
    'Position',pPosM,'FontUnits','Pixels','FontSize',p.fSzM);

% sets the main object specific properites
switch pTypeM
    case 'text'
        % case is a text object
        set(hObjM,'FontWeight','Bold','HorizontalAlignment','Left');
        
    case {'pushbutton','togglebutton'}        
        % case is a button object
        set(hObjM,'FontWeight','Bold');
        
    case 'popupmenu'
        % case is a popupmenu item
        set(hObjM,'String',{' '},'Value',1);
end

% --- retrieves the object offset (based on object type)
function [dyObjM,dyObjL] = getObjectOffset(pTypeM,pTypeL)

% initialisations
[dyObjM,dyObjL] = deal(0);

switch pTypeL
    case 'text'
        % case is the label is a text object
        switch pTypeM
            case {'pushbutton','togglebutton'}
                % main object is a button object
                dyObjM = 4;                
                
            case 'popupmenu'
                % main object is a popupmenu
                dyObjM = 2;
                
            case 'edit'
                % main object is an editbox
                dyObjM = 3;                
        end
        
    case {'pushbutton','togglebutton'}
        % case is the label is a button object
        switch pTypeM
            case 'edit'
                % main object is an editbox
                dyObjL = 2;
        end
end

% --- retrieves the object specific properties
function hObj = getObjectHeight(p,pType)

switch pType
    case 'text'
        % case is text label
        hObj = p.hghtTxt;
        
    case {'pushbutton','togglebutton'}
        % case is pushbutton/togglebutton
        hObj = p.hghtBut;
        
    case 'edit'
        % case is the editbox
        hObj = p.hghtEdit;
        
    case 'popupmenu'        
        % case is a popup menu
        hObj = p.hghtPopup;
end
