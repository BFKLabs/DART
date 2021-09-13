function varargout = AnalysisPara(varargin)
% Last Modified by GUIDE v2.5 30-Jan-2014 02:10:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AnalysisPara_OpeningFcn, ...
                   'gui_OutputFcn',  @AnalysisPara_OutputFcn, ...
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

% --- Executes just before AnalysisPara is made visible.
function AnalysisPara_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for AnalysisPara
setObjVisibility(hObject,'off'); 
pause(0.05)
handles.output = hObject;

% sets the input arguments
hGUI = varargin{1};
setappdata(hObject,'hGUI',hGUI)

% sets the function handles
setappdata(hObject,'getPlotData',@getPlotData)
setappdata(hObject,'initAnalysisGUI',@initAnalysisGUI)

% initialises the analysis parameter class object
pObj = AnalysisParaClass(hObject,hGUI);
if pObj.isOK
    setappdata(hObject,'pObj',pObj)
else
    delete(hObject)
    return
end

% Update handles structure
set(hObject,'CloseRequestFcn',[]);
guidata(hObject, handles);

% UIWAIT makes AnalysisPara wait for user response (see UIRESUME)
% uiwait(handles.figAnalysisPara);

% --- Outputs from this function are returned to the command line.
function varargout = AnalysisPara_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the Analysis Parameters GUI --- %
function varargout = initAnalysisGUI(hPara)

% re-initialises the gui
pObj = getappdata(hPara,'pObj');
pData = pObj.initAnalysisGUI();

% returns the parameter data struct
if (nargout == 1)
    varargout{1} = pData;
end

% --- retrieves the current plot data struct
function pData = getPlotData(hPara)

% retrieves the plot data struct
pObj = getappdata(hPara,'pObj');
pData = pObj.pData;