function varargout = StashedBranches(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @StashedBranches_OpeningFcn, ...
                   'gui_OutputFcn',  @StashedBranches_OutputFcn, ...
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


% --- Executes just before StashedBranches is made visible.
function StashedBranches_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for StashedBranches
handles.output = hObject;

% sets the stashed strings in the listbox
set(handles.listStashed,'string',varargin{1})

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes StashedBranches wait for user response (see UIRESUME)
% uiwait(handles.figStashedBranches);

% --- Outputs from this function are returned to the command line.
function varargout = StashedBranches_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = [];

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% deletes the GUI
delete(handles.figStashedBranches)

% --- Executes when user attempts to close figStashedBranches.
function figStashedBranches_CloseRequestFcn(hObject, eventdata, handles)

% deletes the GUI
delete(hObject);
