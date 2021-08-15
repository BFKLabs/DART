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
setappdata(hObject,'hFigM',varargin{1});
setappdata(hObject,'roiObj',VideoROIClass(hObject));

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
