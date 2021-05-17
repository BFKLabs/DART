function varargout = VideoROI(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @VideoROI_OpeningFcn, ...
                   'gui_OutputFcn',  @VideoROI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before VideoROI is made visible.
function VideoROI_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global manualUpdate
manualUpdate = false;

% Choose default command line output for VideoROI
handles.output = hObject;

% initialises the object properties
initObjProps(handles,varargin{1})

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes VideoROI wait for user response (see UIRESUME)
% uiwait(handles.figVideoROI);

% --- Outputs from this function are returned to the command line.
function varargout = VideoROI_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when user attempts to close figVideoROI.
function figVideoROI_CloseRequestFcn(hObject, eventdata, handles)

% runs the exit menu item
menuExit_Callback(handles.menuExit, '1', handles)

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

% deletes the gui
delete(handles.figVideoROI);

%-------------------------------------------------------------------------%
%                         OTHER CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- callback function on updating the ROI dimension editboxes
function editROIDim(hObject, eventdata, handles)

%
szMin = 64;
uData = get(hObject,'UserData');
vRes = getappdata(handles.figVideoROI,'vRes');

% retrieves the current ROI dimensions
rPos0 = roundP(getCurrentROIDim(handles));

% determines the parameter limits (based on type
switch uData
    case 1 % case is the ROI left location
        nwLim = [0,max(0,floor(vRes(1)-rPos0(3)))];
        
    case 2 % case is the ROI bottom location
        nwLim = [0,max(0,floor(vRes(2)-rPos0(4)))];
        
    case 3 % case is the ROI width
        nwLim = [szMin,floor(vRes(1)-rPos0(1))];
        
    case 4 % case is the ROI height
        nwLim = [szMin,floor(vRes(2)-rPos0(2))];
        
end

% determines if the new value is valid
nwVal = str2double(get(hObject,'string'));
if chkEditValue(nwVal,nwLim,1)
    % if so, then update the parameter value and the 
    rPos0(uData) = nwVal;
    updateAllROIMarkers(handles,rPos0);
else
    % resets the back to the last visible
    set(hObject,'String',num2str(rPos0(uData)))
end

% --- updates all the ROI markers given the ROI vector, rPos
function updateAllROIMarkers(handles,rPos)

% global variables
global manualUpdate
manualUpdate = true;

% initialisations
hAx = handles.axesImg;
vRes = getappdata(handles.figVideoROI,'vRes');

% resets the ROI marker on the left side
hRectX1 = findall(hAx,'tag','hROILim','UserData',[1,1]);
updateROIMarker(hRectX1,'Width',rPos(1));

% resets the ROI marker on the right side
hRectX2 = findall(hAx,'tag','hROILim','UserData',[1,2]);
updateROIMarker(hRectX2,'Left',sum(rPos([1,3])));
updateROIMarker(hRectX2,'Width',vRes(1)-sum(rPos([1,3])));

% resets the ROI marker on the bottom side
hRectY1 = findall(hAx,'tag','hROILim','UserData',[0,2]);
updateROIMarker(hRectY1,'Bottom',vRes(2)-rPos(2));
updateROIMarker(hRectY1,'Height',rPos(2));

% resets the ROI marker on the top side
hRectY2 = findall(hAx,'tag','hROILim','UserData',[0,1]);
updateROIMarker(hRectY2,'Height',vRes(2)-sum(rPos([2,4])));

% resets the manual update flag
manualUpdate = false;

% --- updates the location of the ROI marker rectangle
function updateROIMarker(hRect,dimStr,nwVal)

% retrieves the current marker position
hAPI = iptgetapi(hRect);
rPos = hAPI.getPosition();

% updates the dimension corresponding to the dimension type string
iDim = strcmp({'Left','Bottom','Width','Height'},dimStr);
rPos(iDim) = nwVal;

% updates the position of the marker
hAPI.setPosition(rPos);

% --- Executes on button press in buttonResetDim.
function buttonResetDim_Callback(hObject, eventdata, handles)

% initialisations
vRes = getappdata(handles.figVideoROI,'vRes');
hFigM = getappdata(handles.figVideoROI,'hFigM');
resetFcn = getappdata(hFigM,'resetVideoPreviewDim');


% updates all ROI markers
rPos0 = [0,0,vRes];
updateAllROIMarkers(handles,rPos0)

% resets the dimension edit box values
for i = 1:length(rPos0)
    hEdit = findall(handles.panelROIDim,'UserData',i);
    set(hEdit,'String',num2str(rPos0(i)))
end

% resets the main GUI dimensions
resetFcn(guidata(hFigM),rPos0)

% --- Executes on button press in buttonUpdateROI.
function buttonUpdateROI_Callback(hObject, eventdata, handles)

% retrieves the main gui object handles
hFigM = getappdata(handles.figVideoROI,'hFigM');
resetFcn = getappdata(hFigM,'resetVideoPreviewDim');

% resets the main GUI dimensions
resetFcn(guidata(hFigM),roundP(getCurrentROIDim(handles)))

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- retrieves the current ROI dimensiong
function rPos = getCurrentROIDim(handles)

% memory allocation
hRect = cell(4,1);
hAx = handles.axesImg;
vRes = getappdata(handles.figVideoROI,'vRes');

% retrieves the marker object handles
for i = 1:2
    for j = 1:2
        k = 2*(i-1)+j;
        hRect{k} = findall(hAx,'tag','hROILim','UserData',[(i-1),j]);
    end
end

% retrieves the position of the marker objects
hAPI = cellfun(@(x)(iptgetapi(x)),hRect,'un',0);
fPos = cell2mat(cellfun(@(x)(x.getPosition()),hAPI,'un',0));

% returns the 
[W,H] = deal(fPos(4,1)-fPos(3,3),fPos(2,2)-fPos(1,4));
rPos = [fPos(3,3),fPos(2,4),W,H];

% --- initialises the GUI object properties
function initObjProps(handles,hFigM)

% parameters
dX = 10;

% initialisations
hFig = handles.figVideoROI;
hAx = handles.axesImg;
hAxM = findall(hFigM,'type','axes');
objIMAQ = getappdata(hFigM,'objIMAQ');

% retrieves the current/full video resolution
rPos = get(objIMAQ,'ROIPosition');
vRes = get(objIMAQ,'VideoResolution');

% -------------------------------------- %
% --- OBJECT PROPERTY INITIALISATION --- %
% -------------------------------------- %

% sets the original resolution height/width
set(handles.textOrigWidth,'string',num2str(vRes(1)))
set(handles.textOrigHeight,'string',num2str(vRes(2)))

% sets the edit property
for i = 1:length(rPos)
    % retrieves the edit object handle
    hEdit = findall(handles.panelROIDim,'style','edit','UserData',i);
    
    % sets the object properties
    cbFcn = {@editROIDim,handles};
    set(hEdit,'string',num2str(rPos(i)),'Callback',cbFcn)
end

% ------------------------ %
% --- IMAGE AXES SETUP --- %
% ------------------------ %

%
set(objIMAQ,'ROIPosition',[0,0,vRes])
Img = getsnapshot(objIMAQ);
set(objIMAQ,'ROIPosition',rPos)

% if there is no image object, then create a new one
image(uint8(Img),'parent',hAx);    
set(hAx,'xtick',[],'ytick',[],'xticklabel',[],'yticklabel',[]);
set(hAx,'ycolor','w','xcolor','w','box','off')   
colormap(hAx,gray)

% creates the image markers
for i = 1:2
    % sets the horizontal/vertical marker locations
    if i == 1
        [xV,yH] = deal(rPos(1),rPos(2));
    else
        [xV,yH] = deal(sum(rPos([1,3])),sum(rPos([2,4])));
    end
    
    % creates the horizontal/vertical markers
    createROIMarker(hAx,yH,i,0)
    createROIMarker(hAx,xV,i,1)
end

% --------------------------- %
% --- GUI RE-DIMENSIONING --- %
% --------------------------- %

% resets the major gui dimensions
pAR = vRes(1)/vRes(2);
pPos = get(handles.panelImageAxes,'Position');

% resets the axes, image panel and figure dimensions
pPos(3) = roundP(pAR*pPos(4));
set(handles.panelImageAxes,'Position',pPos)
set(hAx,'Position',[dX*[1,1],pPos(3:4)-2*dX])
resetObjPos(hFig,'Width',sum(pPos([1,3]))+dX)

% resets the axis limits
del = 3;
set(hAx,'xlim',get(hAx,'xlim')+del*[-1,1],...
        'ylim',get(hAx,'ylim')+del*pAR*[-1,1])

% ------------------------------- %
% --- HOUSE-KEEPING EXERCISES --- %
% ------------------------------- %

% sets the important fields into the GUI
setappdata(hFig,'vRes',vRes)
setappdata(hFig,'rPos',rPos)
setappdata(hFig,'hAxM',hAxM)
setappdata(hFig,'hFigM',hFigM)

% --- creates the ROI markers on the axes, hAx
function createROIMarker(hAx,pL,ind,isVert)

% global variables
[uData,lWidL] = deal([isVert,ind],4);
xLim = get(hAx,'xlim');
yLim = get(hAx,'ylim');

% sets the marker coordinates
if isVert
    % case is a vertical marker
    yROI = yLim;
    if ind == 1
        xROI = [xLim(1),pL];
        lStr = 'maxx top line';
    else
        xROI = [pL,xLim(2)];
        lStr = 'minx top line';
    end
else
    % case is a horizontal marker
    xROI = xLim;
    if ind == 1        
        yROI = [yLim(1),pL];
        lStr = 'maxy top line';
    else
        yROI = [pL,yLim(2)];
        lStr = 'miny top line';
    end
end

%
xROI = max(min(xROI,xLim(2)-0.5),xLim(1)+0.5);
yROI = max(min(yROI,yLim(2)-0.5),yLim(1)+0.5);

% creates a patch object object
pROI = [xROI(1),yROI(1),diff(xROI),diff(yROI)];
hRectS = imrect(hAx,pROI);
set(hRectS,'UserData',uData,'tag','hROILim')

% % if moveable, then set the position callback function
% api = iptgetapi(hRectS);
% api.setColor('k');

%
hRectL = findall(hRectS,'type','Line');
set(hRectL,'Visible','off','HitTest','off');

hRectLV = findall(hRectL,'tag',lStr);
set(hRectLV,'Visible','on','LineWidth',lWidL,'HitTest','on',...
            'Color','r','LineStyle',':')
uistack(hRectLV,'top');

%
hRectP = findall(hRectS,'type','Patch');
set(hRectP,'FaceColor',0.75*[1,1,1],'FaceAlpha',0.25,'HitTest','off');

% %
% if isVert
%     [xL,yL] = deal(xLim,yLim);
% else
%     [xL,yL] = deal(xLim,yLim);
% end

% sets the constraint/position callback functions
handles = guidata(hAx);
hRectS.addNewPositionCallback(@(p)moveROIMarker(p,handles,uData));

api = iptgetapi(hRectS);
fcn = makeConstrainToRectFcn('imrect',xLim,yLim);
api.setPositionConstraintFcn(fcn);  

% --- 
function moveROIMarker(p,handles,uData)

% global variables
global manualUpdate
if manualUpdate; return; end

% retrieves the ROI positional coordinates
hAx = handles.axesImg;
rPos = getappdata(handles.figVideoROI,'rPos');
vRes = getappdata(handles.figVideoROI,'vRes');

% retrieves the location of the opposite marker object
uDataF = [uData(1),1+(uData(2)==1)];
hAPI = iptgetapi(findall(hAx,'tag','hROILim','UserData',uDataF)); 
pF = hAPI.getPosition();

%
if uData(1)       
    % sets the length dimension parameter object  
    if uData(2) == 1
        rPos(1) = roundP(p(3)-0.5); 
        rPos(3) = roundP(pF(1)-rPos(1));
    else
        rPos(3) = min(vRes(1),roundP(p(1)-pF(3)));
    end
    
    % sets the bottom coordinate
    set(handles.editLeft,'string',num2str(rPos(1)));
    set(handles.editWidth,'string',num2str(rPos(3)));
    
else
    % sets the length dimension parameter object 
    if uData(2) == 2
        rPos(2) = max(0,roundP(p(4)-0.5));
        rPos(4) = roundP(p(2)-pF(4));
    else
        rPos(4) = min(vRes(2),roundP(pF(2)-p(4)));
    end
    
    % sets the bottom coordinate    
    set(handles.editBottom,'string',num2str(rPos(2)));
    set(handles.editHeight,'string',num2str(rPos(4)));
end
