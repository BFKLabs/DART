% --- runs the waitbar figure functions --- %
function varargout = waitbarFig(varargin)

% sets the input arguments
p = varargin;

% runs the waitbar function based on the number of input arguments
switch nargin
    case 4 % case is updating the waitbar figure progress
        [ind,wStr,wProp,h] = deal(p{1},p{2},p{3},p{4});
        varargout{1} = updateBar(ind,wStr,wProp,h);
        
    otherwise % case is initialising the waitbar figure
        [fldNames,hName] = deal(p{1},p{2});
        if ~iscell(fldNames)
            fldNames = {fldNames};
        end
                
        if nargin == 3
            [hasCancel,isVisible] = deal(mod(p{3},2)==0,p{3}==2);
        else
            [hasCancel,isVisible] = deal(1,1);
        end
        
        varargout{1} = waitbarFigInit(fldNames,hName,hasCancel,isVisible);  
        pause(0.1);
end

% ----------------------------------------------------------------------- %
% ---                     WAITBAR FIGURE FUNCTIONS                   --c- %
% ----------------------------------------------------------------------- %

% --- creates the waitbar progress bar figure --- %
function h = waitbarFigInit(fldNames,hName,hasCancel,isVisible)

% sets the maximum proportion value (set to default value of 1)
mxProp = 1;

% global variables
global wImg 
wImg = ones(1,1000,3);

% figure object dimensions
bOfs = 10;      % panel border offset
xyOfs = 20;     % x/y offset
bWid = 400;     % box width
btWid = 80;     % button width
bHgt = 20;      % box/edit height
sDist = bHgt/2; % seperation distance

% memory allocation
nStr = length(fldNames);
hObj = repmat(struct('wStr',[],'wAxes',[],'wImg',[],'wProp',[]),nStr,1);

% sets the figure and cancel button position vectors
if (hasCancel)
    fPos = [400 400 (2*(bOfs+xyOfs)+bWid) ...
                (2*(bOfs+nStr*bHgt)+(nStr-1)*bOfs+(3*bOfs+bHgt))];      
    pPos = [bOfs (2*bOfs+bHgt) (fPos(3)-2*bOfs) (fPos(4)-(3*bOfs+bHgt))];
else
    fPos = [400 400 (2*(bOfs+xyOfs)+bWid) ...
                (2*(bOfs+nStr*bHgt)+(nStr-1)*bOfs+(2*bOfs))];      
    pPos = [bOfs bOfs (fPos(3)-2*bOfs) (fPos(4)-(2*bOfs))];            
end
    
% creates the dialog box
if isVisible
    h = dialog('position',fPos,'tag','waitbar','name',hName);
else
    h = dialog('position',fPos,'tag','waitbar','name',hName,'visible','off');
end
    
% creates the inner panel
hp = uipanel(h,'units','pixels','position',pPos);

% creates a cancel button (if required)
if hasCancel
    btPos = [(fPos(3)-(btWid+bOfs)) bOfs btWid bHgt];       
    hBut = uicontrol(h,'style','togglebutton','string','Cancel','tag',...
                    'buttonCancel','position',btPos);
else
    % button not required, so set an empty array for the button handle
    hBut = [];
end
set(h,'windowstyle','normal')
            
% sets up the waitbar statuses for each of the figure items
for i = 1:nStr
    % sets the positions of the current waitbar objects        
    posAx = [xyOfs,(i*bOfs) + (i-1)*(2*bHgt),bWid,bHgt];
    posStr = posAx + [0 bHgt 0 0];
    
    % creates the waitbar objects
    j = nStr - (i-1);    
    hObj(j).wAxes = axes('parent',hp,'units','pixels','position',posAx);    
    hObj(j).wStr = uicontrol(hp,'style','text','position',...
                posStr,'FontSize',10,'string',fldNames{j});                                   
    hObj(j).wImg = image(wImg,'parent',hObj(j).wAxes);
    hObj(j).wProp = 0;
    set(hObj(j).wAxes,'xtick',[],'ytick',[],'xticklabel',[],...
                      'yticklabel',[],'xcolor','k','ycolor','k','box','on')    
                  
    % fixes a small bug in the new release where the box line on the upper
    % limit is missing for the last waitbar axes
    if ((~verLessThan('matlab','8.4')) && (i == 1))
        [xL,yL] = deal(get(hObj(j).wAxes,'xlim'),get(hObj(j).wAxes,'ylim'));
        hold(hObj(j).wAxes,'on')
        plot(hObj(j).wAxes,xL,yL(1)*[1 1],'k','linewidth',2)
    end
                  
    guidata(h,hObj(j))
end

% sets the object data into the gui
set(h,'windowstyle','normal')
setappdata(h,'updateBar',@updateBar);
setappdata(h,'wStr',fldNames)
setappdata(h,'hObj',hObj)
setappdata(h,'hBut',hBut)
setappdata(h,'isCancel',0)
setappdata(h,'mxProp',mxProp)
setappdata(h,'cProp',0)

% --- updates the waitbar status string and proportion complete --- %
function isCancel = updateBar(ind,wStr,wProp,h)

% global variables
global wImg 

% retrieves the maximum change/current waitbar probabilities, and
% calculates the new probability
isCancel = 0;
% retrieves the waitbar handle (if not set)
if (nargin == 3)
    h = findobj('tag','waitbar');
end

% attempts to retrieves the object handles
try
    [hObj,hBut] = deal(getappdata(h,'hObj'),getappdata(h,'hBut'));    
catch
    isCancel = 1;
    return
end
    
% retrieves the current status of the waitbar cancel status (if there is no
% button then return a false value)
if (~isempty(hBut))
    if (get(hBut,'value'))            
        % if flagged to cancel, then delete the waitbar object
        pause(0.01)        
        if (nargout == 1)
            isCancel = 1;
            delete(h)    
            return
        end
    end
end

% sets the new image
wLen = roundP(wProp*1000,1);
wImg(:,1:wLen,2:3) = 0;
wImg(:,(wLen+1):end,2:3) = 1;

% updates the proportional value
hObj(ind).wProp = wProp;
setappdata(h,'hObj',hObj)

% updates the status bar and the string
set(hObj(ind).wImg,'cdata',wImg);
set(hObj(ind).wStr,'string',wStr)
drawnow;     