function varargout = StartPoint(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @StartPoint_OpeningFcn, ...
                   'gui_OutputFcn',  @StartPoint_OutputFcn, ...
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


% --- Executes just before StartPoint is made visible.
function StartPoint_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for StartPoint
handles.output = hObject;

% sets the input arguments
trkObj = varargin{1};

% loads the progress data file
pFile = fullfile(trkObj.tDir,'Progress.mat');
A = load(pFile); 

% sets the data structs into the GUI
setappdata(hObject,'trkObj',trkObj)
setappdata(hObject,'nFrmS',A.sProg.nFrmS)
setappdata(hObject,'iDataS',initDataStruct(handles,trkObj))

% initialises the object properties
initObjProps(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes StartPoint wait for user response (see UIRESUME)
uiwait(handles.figStartPoint);


% --- Outputs from this function are returned to the command line.
function varargout = StartPoint_OutputFcn(hObject, eventdata, handles) 

% global variables
global indStart

% Get default command line output from handles structure
varargout{1} = indStart;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when user attempts to close figStartPoint.
function figStartPoint_CloseRequestFcn(hObject, eventdata, handles)

% closes the figure via the cancel function
buttonCancel_Callback(handles.buttonCancel,[],handles)

%-------------------------------------------------------------------------%
%                        OBJECT CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when selected object is changed in panelStartPoint.
function panelStartPoint_SelectionChangedFcn(hObject, eventdata, handles)

% initialisations
eStr = {'off','on'};

% retrieves the handle of the selected radio button
if ischar(eventdata)
    hRadio = get(hObject,'SelectedObject');
else
    hRadio = eventdata.NewValue;
end   

% updates the object properties based on the selection
isFrameSel = strcmp(get(hRadio,'tag'),'radioStartFrame');
setObjEnable(handles.editFrame,isFrameSel)
setPanelProps(handles.panelStartPhase,eStr{1+(~isFrameSel)})

% --- Executes on updating parameter editboxes
function editParaUpdate(hEdit, eventdata, handles)

% retrieves the important data structs
hFig = handles.figStartPoint;
iDataS = getappdata(hFig,'iDataS');
trkObj = getappdata(hFig,'trkObj');

% retrieves the parameter limits (based on type)
pStr = get(hEdit,'UserData');
switch pStr
    case 'Phase' % case is the start frame
        nwLim = [1,trkObj.iPhase0];        
        
    case 'Stack' % case is the start stack
        nwLim = [1,trkObj.pData.nCount(iDataS.Phase)+1];
        
    case 'Frame' % case is the start frame
        nwLim = [1,getappdata(handles.figStartPoint,'iFrm0')];
        
end

% determines if the new value is 
nwVal = str2double(get(hEdit,'string'));
if chkEditValue(nwVal,nwLim,true)
    % if so, then update the parameter struct
    eval(sprintf('iDataS.%s = nwVal;',pStr));    
    
    % updates the other fields based on the parameter being altered
    switch pStr
        case 'Frame' % case is the frame index
            [iDataS.Phase,iDataS.Stack] = calcPhaseIndex(handles,nwVal);
            set(handles.editPhase,'string',num2str(iDataS.Phase))
            set(handles.editStack,'string',num2str(iDataS.Stack))
            
        otherwise % case is the phase/stack index
            iDataS.Frame = calcFrameIndex(handles,iDataS.Phase,iDataS.Stack);
            set(handles.editFrame,'string',num2str(iDataS.Frame))
            
    end
    
    % updates the data struct
    setappdata(hFig,'iDataS',iDataS)
    
else
    % otherwise, reset the parameter to the last valid value
    set(hEdit,'string',num2str(eval(sprintf('iDataS.%s',pStr))))
end

% --- Executes on button press in buttonCont.
function buttonCont_Callback(hObject, eventdata, handles)

% global variables
global indStart

% returns an empty data struct
iDataS = getappdata(handles.figStartPoint,'iDataS');
indStart = [iDataS.Phase,iDataS.Stack];

% deletes the GUI
delete(handles.figStartPoint)

% --- Executes on button press in buttonCancel.
function buttonCancel_Callback(hObject, eventdata, handles)

% global variables
global indStart

% returns an empty data struct
indStart = [];

% deletes the GUI
delete(handles.figStartPoint)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the object properties
function initObjProps(handles)

% retrieves the data structs
hFig = handles.figStartPoint;
iDataS = getappdata(hFig,'iDataS');

% initialises the 
fStr = fieldnames(iDataS);
for i = 1:length(fStr)
    % retrieves the editbox handle
    hEdit = eval(sprintf('handles.edit%s',fStr{i}));
    
    % sets the callback function and values
    cbFcn = {@editParaUpdate,handles};
    pVal = eval(sprintf('iDataS.%s;',fStr{i}));
    set(hEdit,'Callback',cbFcn,'String',num2str(pVal))
end

% runs the start point selection callback function
panelStartPoint_SelectionChangedFcn(handles.panelStartPoint, '1', handles)

% --- initialises the data struct
function iDataS = initDataStruct(handles,trkObj)

% calculates the frame index
iPhase0 = trkObj.iPhase0;
iStack0 = trkObj.pData.nCount(iPhase0)+1;
iFrm0 = calcFrameIndex(handles,iPhase0,iStack0);

% sets up the data struct
iDataS = struct('Phase',iPhase0,'Stack',iStack0,'Frame',iFrm0);
setappdata(handles.figStartPoint,'iFrm0',iFrm0)

% --- calculates the frame index (from the phase/stack indices)
function iFrm0 = calcFrameIndex(handles,iPhase0,iStack0)

% retrieves the important values from the GUI
nFrmS = getappdata(handles.figStartPoint,'nFrmS');
trkObj = getappdata(handles.figStartPoint,'trkObj');
nFrmMx = size(trkObj.pData.fPos{1}{1},1);

% calculates the start frame index
iFrm0 = min(nFrmMx,trkObj.iMov.iPhase(iPhase0,1) + (iStack0-1)*nFrmS);

% --- calculates the phase/stack indices (from the frame index)
function [iPhase0,iStack0] = calcPhaseIndex(handles,iFrm0)

% retrieves the important values from the GUI
nFrmS = getappdata(handles.figStartPoint,'nFrmS');
trkObj = getappdata(handles.figStartPoint,'trkObj');

% calculates the phase/stack indices
iPhase0 = find(iFrm0 <= trkObj.iMov.iPhase(:,2),1,'first');
iStack0 = ceil((iFrm0-trkObj.iMov.iPhase(iPhase0,1))/nFrmS);
