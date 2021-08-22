function varargout = ExeUpdate(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ExeUpdate_OpeningFcn, ...
                   'gui_OutputFcn',  @ExeUpdate_OutputFcn, ...
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

% --- Executes just before ExeUpdate is made visible.
function ExeUpdate_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for ExeUpdate
handles.output = hObject;

% sets the input argument
setappdata(hObject,'hFigM',varargin{1})

% creates the executable update class object
exeObj = ExeUpdateClass(hObject);
if ~exeObj.ok
    % if there an update is unnecessary, then exit
    delete(hObject);
    return
else
    % updates the executable class object into the gui
    setappdata(hObject,'exeObj',exeObj)
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ExeUpdate wait for user response (see UIRESUME)
% uiwait(handles.figExeUpdate);

% --- Outputs from this function are returned to the command line.
function varargout = ExeUpdate_OutputFcn(~, ~, ~) 

% Get default command line output from handles structure
varargout{1} = [];

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when user attempts to close figExeUpdate.
function figExeUpdate_CloseRequestFcn(~, ~, handles)

% closes the window
exeObj = getappdata(handles.figExeUpdate,'exeObj');
exeObj.buttonCloseUpdateCB();