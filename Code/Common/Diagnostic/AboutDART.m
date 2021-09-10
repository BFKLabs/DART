function varargout = AboutDART(varargin)
% Last Modified by GUIDE v2.5 19-Dec-2013 04:09:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AboutDART_OpeningFcn, ...
                   'gui_OutputFcn',  @AboutDART_OutputFcn, ...
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


% --- Executes just before AboutDART is made visible.
function AboutDART_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for AboutDART
handles.output = hObject;

% global variables
global mainProgDir
hAx = handles.axesLogo;

% Update handles structure
guidata(hObject, handles);
setGUIFontSize(handles)

% sets the button c-data values
cdFile = 'ButtonCData.mat';
if ~exist(cdFile,'file')
    cdFile = [];
end

% sets the DART logo
if ~isempty(cdFile)
    A = load(cdFile);    
    image(A.cDataStr.Ilogo,'parent',hAx)
    set(hAx,'xtick',[],'xticklabel',[],'ytick',[],'yticklabel',[])
    axis equal
end

% determines if the update log-file exists
if isdeployed
    a = dir(fullfile(mainProgDir,'DART.exe'));
    set(handles.textLastTime,'string',a.date)
    set(handles.textLastName,'string','Executable Version')
else
    logFile = fullfile(mainProgDir,'Para Files','Update Log.mat');
    if (exist(logFile,'file'))
        % if the file exists, load it and set the info fields
        A = load(logFile);
        set(handles.textLastTime,'string',datestr(A.Time))
        set(handles.textLastName,'string',A.File)    
    else
        % otherwise, set N/A for the string fields
        set(handles.textLastTime,'string','N/A')
        set(handles.textLastName,'string','N/A')
    end
end

% centres the figure position
centreFigPosition(hObject);
set(hObject,'CloseRequestFcn','closereq');
    
% UIWAIT makes AboutDART wait for user response (see UIRESUME)
set(hObject,'WindowStyle','modal')

% --- Outputs from this function are returned to the command line.
function varargout = AboutDART_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = [];
