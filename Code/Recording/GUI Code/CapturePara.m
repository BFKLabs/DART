function varargout = CapturePara(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CapturePara_OpeningFcn, ...
                   'gui_OutputFcn',  @CapturePara_OutputFcn, ...
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


% --- Executes just before CapturePara is made visible.
function CapturePara_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for CapturePara
handles.output = hObject;

% initialises the object properties
initObjProps(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes CapturePara wait for user response (see UIRESUME)
uiwait(handles.figCapturePara);

% --- Outputs from this function are returned to the command line.
function varargout = CapturePara_OutputFcn(hObject, eventdata, handles) 

% global parameters
global frmPara

% Get default command line output from handles structure
varargout{1} = frmPara;

%-------------------------------------------------------------------------%
%                        OBJECT CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- editbox parameter callback function
function editPara(hObject, eventdata, handles)

% initialisations
handles = guidata(hObject);
pStr = get(hObject,'UserData');
nwVal = str2double(get(hObject,'String'));
frmPara = getappdata(handles.figCapturePara,'frmPara');

% sets the parameter limits
switch pStr
    case 'Nframe'
        [nwLim,isInt] = deal([5,100],true);
    case 'wP'
        [nwLim,isInt] = deal([1,20],false);
end

% determines if the new value is valid
if chkEditValue(nwVal,nwLim,isInt)
    % if the value is valid, then update the parameter struct
    frmPara = setStructField(frmPara,pStr,nwVal);
    setappdata(handles.figCapturePara,'frmPara',frmPara);
else
    % otherwise, reset to the original value
    set(hObject,'string',num2str(getStructField(frmPara,pStr)))
end

% --- Executes on button press in buttonStart.
function buttonStart_Callback(hObject, eventdata, handles)

% global parameters
global frmPara

% retrieves the frame parameters and deletes the GUI
frmPara = getappdata(handles.figCapturePara,'frmPara');
delete(handles.figCapturePara);

% --- Executes on button press in buttonCancel.
function buttonCancel_Callback(hObject, eventdata, handles)

% global parameters
global frmPara

% returns an empty array and deletes the GUI
frmPara = [];
delete(handles.figCapturePara);

%-------------------------------------------------------------------------%
%                        OBJECT CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- initialises the object properties
function initObjProps(handles)

% initialises the parameter struct
frmPara = struct('Nframe',10,'wP',1);
setappdata(handles.figCapturePara,'frmPara',frmPara);

% sets the object properties
hEdit = findall(handles.panelCapturePara,'style','edit');
for i = 1:length(hEdit)
    pVal = getStructField(frmPara,get(hEdit(i),'UserData'));
    set(hEdit(i),'Callback',@editPara,'String',num2str(pVal));
end
