function varargout = ProgParaTrack(varargin)
% Last Modified by GUIDE v2.5 12-Jan-2014 23:39:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @ProgParaTrack_OpeningFcn, ...
    'gui_OutputFcn',  @ProgParaTrack_OutputFcn, ...
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

% --- Executes just before ProgParaTrack is made visible.
function ProgParaTrack_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for ProgParaTrack
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% resets the object font sizes
setGUIFontSize(handles)

% initialises the object fields
[hGUI,ProgDef] = deal(varargin{1},varargin{2});
addObjProps(hObject,'hGUI',hGUI,'ProgDef',ProgDef,'hDART',[]);

% sets the program preference struct
if ~strcmp(get(hGUI.output,'tag'),'figFlyRecord')     
    set(hObject,'hDART',get(hGUI.output,'hGUIOpen'))
end

% if the default struct has not be set, then re-initialise
if isempty(ProgDef)
    hObject.ProgDef = struct('DirMov',[],'DirSoln',[],'TempFile',[]);
end

% sets the cancel enable properties based on whether update is being forced
setObjEnable(handles.buttonCancel,length(varargin) ~= 3)

% disables the reset/update buttons
setObjEnable(handles.buttonUpdate,'off')
setObjEnable(handles.buttonReset,'off')

% initialises the GUI objects
initDefButton(handles,hObject.ProgDef)
centreFigPosition(hObject);

% UIWAIT makes ProgParaTrack wait for user response (see UIRESUME)
set(hObject,'WindowStyle','modal');
uiwait(hObject);

% --- Outputs from this function are returned to the command line.
function varargout = ProgParaTrack_OutputFcn(hObject, eventdata, handles)

% global variables
global isSave ProgDef

% Get default command line output from handles structure
varargout{1} = ProgDef;
varargout{2} = isSave;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes on button press in buttonReset.
function buttonReset_Callback(hObject, eventdata, handles)

% global variables
global mainProgDir

% updates the program default file
hDART = get(handles.output,'hDART');
ProgDefNw = get(handles.output,'ProgDef');

% updates the program default file (depending on whether the program is
% being from the command line or through DART)
progFile = fullfile(mainProgDir,'Para Files','ProgDef.mat');  
if isempty(hDART)
    % if running from command-line, update the local parameter file    
    ProgDef = ProgDefNw;
else
    % updates the default directory defaults file
    hDART = findall(0,'tag','figDART');
    ProgDefFull = getappdata(hDART,'ProgDef');    
    ProgDefFull.Tracking = ProgDefNw;
    setappdata(hDART,'ProgDef',ProgDefFull)    
    
    % otherwise, update the full program preference data struct/file    
    ProgDef = ProgDefFull;        
    
    % updates the button properties
    hDARTObj = guidata(hDART);
    set(hDARTObj.buttonFlyTrack,'UserData',ProgDefNw)
end

% closes the sub-GUI
save(progFile,'ProgDef')
buttonUpdate_Callback([], [], handles)

% --- Executes on button press in buttonUpdate.
function buttonUpdate_Callback(hObject, eventdata, handles)

% global variables
global isSave ProgDef
[isSave,ProgDef] = deal(1,handles.output.ProgDef);

% closes the figure
delete(handles.figProgDef)

% --- Executes on button press in buttonCancel.
function buttonCancel_Callback(hObject, eventdata, handles)

% global variables
global isSave ProgDef
[isSave,ProgDef] = deal(0,[]);

% closes the figure
delete(handles.output)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the default directory/file pushbutton properties --- %
function initDefButton(handles,ProgDef)

% sets the variable tag strings
wStr = {'DirMov';'DirSoln';'TempFile'};

% sets the call back function for all the GUI buttons
for i = 1:length(wStr)
    % sets up the object callback function
    hObj = eval(sprintf('handles.button%s;',wStr{i}));
    bFunc = @(hObj,e)ProgParaTrack('setDefDir',hObj,[],guidata(hObj));
    
    % sets the object callback function
    set(hObj,'UserData',wStr{i},'callback',bFunc);
    
    % updates the editbox string
    hEditStr = sprintf('handles.edit%s',wStr{i});
    set(eval(hEditStr),'string',['  ',eval(sprintf('ProgDef.%s',wStr{i}))])
end

% --- sets the enabled properties of the update/reset pushbuttons --- %
function setOtherButton(handles,ProgDef)

% sets the variable tag strings
wStr = fieldnames(ProgDef);
isEnable = true;

% sets the call back function for all the
for i = 1:length(wStr)
    if (isempty(eval(sprintf('ProgDef.%s',wStr{i}))))
        isEnable = false;
    end
end

% sets the enabled properties depending if all the directories have been
% set correctly
setObjEnable(handles.buttonUpdate,isEnable)    
setObjEnable(handles.buttonReset,isEnable)

% --- callback function for the default directory setting buttons --- %
function setDefDir(hObject, eventdata, handles)

% retrieves the default directory corresponding to the current object
wStr = get(hObject,'UserData');
ProgDef = get(handles.output,'ProgDef');
dDir = getStructField(ProgDef,wStr);

% prompts the user for the new default directory
dirName = uigetdir(dDir,'Set The Default Path');
if dirName ~= 0
    % otherwise, update the directory string names
    hEdit = sprintf('handles.edit%s',wStr);
    ProgDef = setStructField(ProgDef,wStr,dirName);
    set(handles.output,'ProgDef',ProgDef);
       
    % resets the enabled properties of the buttons
    set(eval(hEdit),'string',['  ',dirName])
    setOtherButton(handles,ProgDef)
end
