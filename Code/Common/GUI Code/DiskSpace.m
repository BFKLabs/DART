function varargout = DiskSpace(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DiskSpace_OpeningFcn, ...
                   'gui_OutputFcn',  @DiskSpace_OutputFcn, ...
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


% --- Executes just before DiskSpace is made visible.
function DiskSpace_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for DiskSpace
handles.output = hObject;

% initialises the object properties
initObjProps(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes DiskSpace wait for user response (see UIRESUME)
% uiwait(handles.figDiskSpace);


% --- Outputs from this function are returned to the command line.
function varargout = DiskSpace_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when user attempts to close figDiskSpace.
function figDiskSpace_CloseRequestFcn(hObject, eventdata, handles)

% runs the close window function
buttonClose_Callback(handles.buttonClose, [], handles);

%-------------------------------------------------------------------------%
%                         OTHER CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% deletes the figure
delete(handles.figDiskSpace)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- 
function initObjProps(handles)

% object dimensions
dX = 10;
[txtWid,txtHght] = deal(70,16);
[axHght,axWid,axBot] = deal(125,60,95);
lblPos = get(handles.textVolName,'Position');
lblWid = lblPos(3);

% retrieves the disk volume information
volInfo = getDiskVolumeInfo();

% calculates the width of the panel objects
nVol = size(volInfo,1);
pWid = (3+nVol)*(dX/2) + lblWid + nVol*txtWid;

% resets the widths of the other gui objects
resetObjPos(handles.figDiskSpace,'Width',pWid+2*dX);
resetObjPos(handles.panelDiskInfo,'Width',pWid);
resetObjPos(handles.panelContButton,'Width',pWid);
resetObjPos(handles.buttonClose,'Width',pWid-2*dX);

% creates the objects for each of the 
for i = 1:nVol
    % creates the text objects
    xTxt = (i-1)*txtWid + lblWid + (1+i)*(dX/2);
    txtPos = [xTxt,NaN,txtWid,txtHght];    
    
    % creates the text objects for 
    txtStr = flip([volInfo(i,:),{100*volInfo{i,3}/volInfo{i,2}}]);
    txtCol = getTextColour(txtStr{1});
    for j = 1:length(txtStr)
        createTextObj(handles,txtPos,txtStr{j},txtCol,j)
    end
    
    % creates the axes objects
    axPos = [xTxt+dX/2,axBot,axWid,axHght];
    createAxesObject(handles,txtStr{1},axPos,i==1)
end

% --- retrieves the colour of the text (based on the volumes % capacity)
function txtCol = getTextColour(pFree)

% sets the colour of the text based on the capacity %age
if pFree < 10
    % case is free space is very low
    txtCol = 'r';
elseif pFree < 25
    % case is free space is low
    txtCol = [0.9,0.3,0.0];
else
    % case is free space is normal
    txtCol = 'k';
end

% --- creates the axes objects
function createAxesObject(handles,pFree,axPos,isFirst)

% initialisations
dX = 5;
fAlpha = 0.5;
yTick = 0:20:100;
hPanel = handles.panelDiskInfo;
[yFree,yUsed,xP] = deal(100-[pFree,0],[0,100-pFree],0.5*[-1,1]);
[ix,iy] = deal([1,1,2,2],[1,2,2,1]);

% creates the new axes object
hAx = axes(hPanel,'Units','Pixels','Position',axPos,'xticklabel',[],...
           'yticklabel',[],'xtick',[],'ytick',yTick,'box','on',...
           'xlim',0.5*[-1,1],'ylim',[0,100],'YGrid','on');
  
% creates the new axes objects
hold(hAx,'on');
hFree = patch(hAx,xP(ix),yFree(iy),'g','FaceAlpha',fAlpha);
hUsed = patch(hAx,xP(ix),yUsed(iy),'r','FaceAlpha',fAlpha);

% sets the legend (first volume only)
if isFirst    
    hLg = legend([hFree,hUsed],{'Free Space','Used Space'},'box','off',...
                 'FontWeight','bold','FontSize',8,'Units','Pixels');
             
    lgPos = get(hLg,'Position');
    lgBot = axPos(2)+0.5*axPos(4)-lgPos(4)/2;
    set(hLg,'Position',[dX,lgBot,axPos(1)-2*dX,lgPos(4)])
end

% --- creates the text objects
function createTextObj(handles,txtPos,txtStr,txtCol,iLbl)

% initialisations
dY = 20;
txtPos(2) = ((iLbl-1)+0.5)*dY;
hPanel = handles.panelDiskInfo;

% converts the numerical values to formatted strings
switch iLbl
    case 1
        txtStr = sprintf('%.1f%s',txtStr,'%');    
    case {2,3}
        txtStr = sprintf('%.1f',txtStr);    
end

% creates the text object
uicontrol('Parent',hPanel,'Style','Text','Position',txtPos,...
          'String',txtStr,'HorizontalAlignment','Center',...
          'FontWeight','Bold','FontUnits','Pixels','FontSize',12,...
          'ForegroundColor',txtCol);
