function varargout = SampleRate(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SampleRate_OpeningFcn, ...
                   'gui_OutputFcn',  @SampleRate_OutputFcn, ...
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

% --- Executes just before SampleRate is made visible.
function SampleRate_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for SampleRate
handles.output = hObject;

% sets the input variables
iData = varargin{1}; 
sRate = 5;
frm0 = 1;

% sets the data arrays into the GUI
setappdata(hObject,'iData',iData)
setappdata(hObject,'sRate',sRate)
setappdata(hObject,'frm0',frm0)

% sets the field strings
setFieldStrings(handles)
centreFigPosition(hObject);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SampleRate wait for user response (see UIRESUME)
set(hObject,'WindowStyle','modal');
uiwait(handles.figSampleRate);

% --- Outputs from this function are returned to the command line.
function varargout = SampleRate_OutputFcn(hObject, eventdata, handles) 

% global variables
global sRate frm0

% Get default command line output from handles structure
varargout{1} = sRate;
varargout{2} = frm0*sRate;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes on updating in editSampleRate.
function editSampleRate_Callback(hObject, eventdata, handles)

% retrieves the data struct and previous sample rate value
sRate = getappdata(handles.figSampleRate,'sRate');

% sets the new value and parameter limits
[nwVal,nwLim] = deal(str2double(get(hObject,'String')),[1 25]);

% checks to see if the new value is valid
if (chkEditValue(nwVal,nwLim,1))
    % if so, then updates the parameter value and field strings
    setappdata(handles.figSampleRate,'sRate',nwVal);    
    setNewFieldString(handles)        
else
    % otherwise, revert back to the previous valid value
    set(hObject,'string',num2str(sRate));
end

% --- Executes on updating in editStartFrame.
function editStartFrame_Callback(hObject, eventdata, handles)

% retrieves the data struct and previous sample rate value
iData = getappdata(handles.figSampleRate,'iData');
sRate = getappdata(handles.figSampleRate,'sRate');
frm0 = getappdata(handles.figSampleRate,'frm0');

% sets the new value and parameter limits
nFrmT = floor(iData.nFrmT/sRate) - 1;
[nwVal,nwLim] = deal(str2double(get(hObject,'String')),[1 nFrmT]);

% checks to see if the new value is valid
if (chkEditValue(nwVal,nwLim,1))
    % if so, then updates the parameter value and field strings
    setappdata(handles.figSampleRate,'frm0',nwVal);
    setNewFieldString(handles)        
else
    % otherwise, revert back to the previous valid value
    set(hObject,'string',num2str(frm0));
end

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% global variables
global sRate frm0

% closes the GUI
sRate = getappdata(handles.figSampleRate,'sRate');
frm0 = getappdata(handles.figSampleRate,'frm0');
delete(handles.figSampleRate);

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- sets all the field strings --- %
function setFieldStrings(handles,iData,sRate)

% retrieves the data values
iData = getappdata(handles.figSampleRate,'iData');
sRate = getappdata(handles.figSampleRate,'sRate'); 
frm0 = getappdata(handles.figSampleRate,'frm0');

% sets the p;d frame count and frame time step fields
set(handles.textOldFrames,'string',num2str(iData.nFrmT));
set(handles.textOldTime,'string',sprintf('%.2f sec',1/iData.exP.FPS));
set(handles.editSampleRate,'string',num2str(sRate));
set(handles.editStartFrame,'string',num2str(frm0));

% sets the new frame count and frame time step fields
setNewFieldString(handles)

% --- sets the new field strings --- %
function setNewFieldString(handles)

% retrieves the data values
iData = getappdata(handles.figSampleRate,'iData');
sRate = getappdata(handles.figSampleRate,'sRate'); 
frm0 = getappdata(handles.figSampleRate,'frm0');

% retrieves the total frame count
nFrmT = floor(iData.nFrmT/sRate) - (frm0-1);

% sets the new frame count and frame time step fields
set(handles.textNewFrames,'string',num2str(nFrmT));
set(handles.textNewTime,'string',sprintf('%.2f sec',(sRate/iData.exP.FPS)));
