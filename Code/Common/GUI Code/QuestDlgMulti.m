function varargout = QuestDlgMulti(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @QuestDlgMulti_OpeningFcn, ...
                   'gui_OutputFcn',  @QuestDlgMulti_OutputFcn, ...
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

% --- Executes just before QuestDlgMulti is made visible.
function QuestDlgMulti_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for QuestDlgMulti
handles.output = hObject;

% sets the input arguments
bStr = varargin{1};
mStr = varargin{2};
tStr = varargin{3};

% sets the other input arguments (if they exist)
if length(varargin) >= 4
    fWid = varargin{4}; 
else
    fWid = NaN;
end

% initialises the 
initObjProps(handles,mStr,bStr,tStr,fWid)
centreFigPosition(hObject,2);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes QuestDlgMulti wait for user response (see UIRESUME)
uiwait(handles.figQuestDlg);

% --- Outputs from this function are returned to the command line.
function varargout = QuestDlgMulti_OutputFcn(hObject, eventdata, handles) 

% global variables
global uChoice

% Get default command line output from handles structure
varargout{1} = uChoice;

% --- Executes when user attempts to close figQuestDlg.
function figQuestDlg_CloseRequestFcn(hObject, eventdata, handles)

% global variables
global uChoice

% 
uChoice = [];
delete(hObject)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                          OTHER FUNCTIONS                          %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- initialises the object properties
function initObjProps(handles,mStr,bStr,tStr,fWid)

% parameters
dX = 10;
Bhght = 23;

% sets the button dimensions
nBut = length(bStr);

% object handles
hFig = handles.figQuestDlg;
hAx = handles.axesQuestImage;

% sets the figure title
set(handles.figQuestDlg,'Name',tStr)

% creates the message text object
hText = uicontrol(hFig,'Style','Text','String',mStr);

% resets the text positions
fCol = get(hFig,'Color');
fPos = get(hFig,'Position');
tPos = get(hText,'Extent');
axPos = get(hAx,'Position');

% sets the figure width (if not set
if isnan(fWid)
    fWid = sum(axPos([1,3]))+sum(tPos([1,3]))+3*dX;
end

% resets the axes/text bottom based on the related object heights
objBot = 2*dX+Bhght;
[axHght,tHght] = deal(axPos(4),tPos(4));
if axHght > tHght
    % the axes object is bigger, so use this to set the figure height
    fHght = (dX+objBot)+axHght;
    tPos(2) = objBot + (axHght-tHght)/2;
    axPos(2) = objBot;
else
    % the text object is bigger, so use this to set the figure height
    fHght = (dX+objBot)+tHght;
    tPos(2) = objBot;
    axPos(2) = objBot + (tHght-axHght)/2;
end

% resets the figure position
fPosNw = [fPos(1:2),fWid,fHght];
set(hFig,'Position',fPosNw)

% resets the text object position
tPos(1) = sum(axPos([1,3]))+dX;
set(hText,'Position',tPos,'HorizontalAlignment','left')

% resets the image axes location
set(hAx,'Position',axPos)

% retrieves the question image filename
A = load('ButtonCData.mat');
if isfield(A.cDataStr,'IinfoBig')
    % retrieves the image (if it exists)
    Img = A.cDataStr.IinfoBig;
    sz = size(Img);

    % removes any dark spots within the image and replaces with white
    iGrp = cell2mat(getGroupIndex(all(Img < 220,3)));
    for i = 1:3; Img(iGrp+(i-1)*prod(sz(1:2))) = 255*fCol(i); end
    
    % shows the image within the axes object
    image(hAx,Img);
end

% sets the question dialog axes
set(hAx,'xticklabel',[],'yticklabel',[],'xcolor',fCol,'ycolor',fCol)

% creates all buttons and sets the callback function
Bwid = (fPosNw(3)-(nBut+1)*dX)/nBut;
for i = 1:length(bStr)
    hBut = uicontrol(hFig,'Style','pushbutton','String',bStr{i},...
                     'Units','Pixels',...
                     'Position',[i*dX+(i-1)*Bwid,dX,Bwid,Bhght]);
    set(hBut,'Callback',{@userSelect,handles});
end

% --- callback function for the button selection
function userSelect(hObj,~,handles)

% global variables 
global uChoice

% retrieves the button string and deletes the GUI
uChoice = get(hObj,'String');
delete(handles.figQuestDlg);
