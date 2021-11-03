function varargout = SplitSubRegionTemp(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SplitSubRegionTemp_OpeningFcn, ...
                   'gui_OutputFcn',  @SplitSubRegionTemp_OutputFcn, ...
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


% --- Executes just before SplitSubRegionTemp is made visible.
function SplitSubRegionTemp_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for SplitSubRegionTemp
handles.output = hObject;

%
hFigM = varargin{1};

% sets the fields into the gui
setappdata(hObject,'hFigM',hFigM);
setappdata(hObject,'iMov',getappdata(hFigM,'iMov'));
setappdata(hObject,'iMov0',getappdata(hFigM,'iMov'));

% initialises the object properties
initObjProps(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SplitSubRegionTemp wait for user response (see UIRESUME)
% uiwait(handles.figSplitSubRegion);


% --- Outputs from this function are returned to the command line.
function varargout = SplitSubRegionTemp_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        OBJECT CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%


% --- Executes on button press in buttonUpdate.
function buttonUpdate_Callback(hObject, eventdata, handles)


% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)



%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the object properties
function initObjProps(handles)
