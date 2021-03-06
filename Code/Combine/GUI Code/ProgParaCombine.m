function varargout = ProgParaCombine(varargin)
% Last Modified by GUIDE v2.5 02-Feb-2014 03:46:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @ProgParaCombine_OpeningFcn, ...
    'gui_OutputFcn',  @ProgParaCombine_OutputFcn, ...
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

% --- Executes just before ProgParaCombine is made visible.
function ProgParaCombine_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for ProgParaCombine
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% resets the object font sizes
[hGUI,ProgDef] = deal(varargin{1},varargin{2});
setGUIFontSize(handles)

% if the default struct has not be set, then re-initialise
if isempty(ProgDef)
    ProgDef = struct('DirSoln',[],'DirComb',[],'TempFile',[]);
end

% sets the cancel enable properties based on whether update is being forced
setObjEnable(handles.buttonCancel,length(varargin) ~= 3)

% disables the reset/update buttons
setObjEnable(handles.buttonUpdate,'off')
setObjEnable(handles.buttonReset,'off')

% initialises the GUI objects
initDefButton(handles,ProgDef)
centreFigPosition(hObject);

% sets the program preference struct into the GUI
setappdata(hObject,'hDART',getappdata(hGUI,'hDART'))
setappdata(hObject,'ProgDef',ProgDef);

% UIWAIT makes ProgParaCombine wait for user response (see UIRESUME)
set(hObject,'WindowStyle','modal');
uiwait(hObject);

% --- Outputs from this function are returned to the command line.
function varargout = ProgParaCombine_OutputFcn(hObject, eventdata, handles)

% global variables
global isSave ProgDef

% Get default command line output from handles structure
varargout{1} = ProgDef;
varargout{2} = isSave;

% --- UPDATE/CLOSE BUTTONS --- %
% ---------------------------- %

% --- Executes on button press in buttonReset.
function buttonReset_Callback(hObject, eventdata, handles)

% global variables
global mainProgDir

% updates the program default file
ProgDefNw = getappdata(handles.figProgDef,'ProgDef');
hDART = getappdata(handles.figProgDef,'hDART');

% determines if the program defaults have been set
progFile = fullfile(mainProgDir,'Para Files','ProgDef.mat');
if (isempty(hDART))
    % if running from command-line, update the local parameter file    
    ProgDef = ProgDefNw;    
else
    % updates the default directory defaults file
    ProgDefFull = getappdata(hDART.figDART,'ProgDef');    
    ProgDefFull.Combine = ProgDefNw;
    setappdata(hDART.figDART,'ProgDef',ProgDefFull)        
    set(hDART.buttonFlyCombine,'UserData',ProgDefNw)
        
    % otherwise, update the full program preference data struct/file    
    ProgDef = ProgDefFull;    
end

% closes the sub-GUI
save(progFile,'ProgDef');
buttonUpdate_Callback([], [], handles)

% --- Executes on button press in buttonUpdate.
function buttonUpdate_Callback(hObject, eventdata, handles)

% global variables
global isSave ProgDef
[isSave,ProgDef] = deal(1,getappdata(handles.figProgDef,'ProgDef'));

% closes the figure
delete(handles.figProgDef)

% --- Executes on button press in buttonCancel.
function buttonCancel_Callback(hObject, eventdata, handles)

% global variables
global isSave ProgDef
[isSave,ProgDef] = deal(0,[]);

% closes the figure
delete(handles.figProgDef)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the default directory pushbutton properties --- %
function initDefButton(handles,ProgDef)

% sets the variable tag strings
wStr = {'DirSoln','DirComb','TempFile'};

% sets the call back function for all the
for i = 1:length(wStr)
    % updates the objects callback function
    hObj = eval(sprintf('handles.button%s;',wStr{i}));
    bFunc = @(hObj,e)ProgParaCombine('setDefDir',hObj,[],guidata(hObj));
    set(hObj,'UserData',wStr{i},'callback',bFunc);
    
    % updates the editbox string
    hEditStr = sprintf('handles.edit%s',wStr{i});
    set(eval(hEditStr),'string',['  ',eval(sprintf('ProgDef.%s',wStr{i}))])
end

% --- sets the enabled properties of the update/reset buttons --- %
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
ProgDef = getappdata(handles.figProgDef,'ProgDef');
dDir = eval(sprintf('ProgDef.%s;',wStr));

% prompts the user for the new default directory
dirName = uigetdir(dDir,'Set The Default Path');
if (dirName == 0)
    % if the user cancelled, then escape
    return
else
    % otherwise, update the directory string names
    hEdit = sprintf('handles.edit%s',wStr);
    eval(sprintf('ProgDef.%s = ''%s'';',wStr,dirName))    
    setappdata(handles.figProgDef,'ProgDef',ProgDef);
       
    % resets the enabled properties of the buttons
    set(eval(hEdit),'string',['  ',dirName])
    setOtherButton(handles,ProgDef)
end
