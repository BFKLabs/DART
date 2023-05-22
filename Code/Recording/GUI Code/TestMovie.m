function varargout = TestMovie(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TestMovie_OpeningFcn, ...
                   'gui_OutputFcn',  @TestMovie_OutputFcn, ...
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

% --- Executes just before TestMovie is made visible.
function TestMovie_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global frmLim tMax

% frame limit
tMax = 20000;
frmLim = [5 50];

% Choose default command line output for TestMovie
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% sets the input arguments
setappdata(hObject,'infoObj',varargin{1});
setappdata(hObject,'iProg',varargin{2});

% memory allocation
vPara = struct('Dir',[],'Name',[],'Tf',10,'Ts',0,'FPS',[]);
setappdata(hObject,'vPara',vPara);

% initialises the video parameter properties
initVideoParaProps(handles)
centreFigPosition(hObject);
vPara = getappdata(hObject,'vPara');

% updates the edit boxes/text label strings
set(handles.editFrmCount,'string',num2str(vPara.Tf));

% UIWAIT makes TestMovie wait for user response (see UIRESUME)
uiwait(handles.figTestMovie);

% --- Outputs from this function are returned to the command line.
function varargout = TestMovie_OutputFcn(hObject, eventdata, handles) 

% global variables
global vPara

% Get default command line output from handles structure
varargout{1} = vPara;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ---------------------------------- %
% --- MOVIE RECORDING PARAMETERS --- %
% ---------------------------------- %

% --- Executes on updating editFrmCount.
function editFrmCount_Callback(hObject, eventdata, handles)

% global variables
global tMax

% retrieves the new value and the parameter struct
nwVal = str2double(get(hObject,'string'));
vPara = getappdata(handles.figTestMovie,'vPara');

% checks to see if the new value is valid
if (chkEditValue(nwVal,[5 tMax],1))
    % if so, then update the parameter struct
    vPara.Tf = nwVal;
    setappdata(handles.figTestMovie,'vPara',vPara)
    
    % updates the movie duration
    set(handles.textMovDur,'string',detDurString(vPara));
else
    % otherwise, reset to the last valid value
    set(hObject,'string',num2str(vPara.Tf));
end

% --- Executes on updating popupFrmRate.
function popupFrmRate_Callback(hObject, eventdata, handles)

% loads the data struct and frame list strings
vPara = getappdata(handles.figTestMovie,'vPara');
fList = get(hObject,'String');

% updates the experimental data struct 
FPSnw = str2double(fList(get(hObject,'Value')));
if ~isnan(FPSnw)
    vPara.FPS = FPSnw;
end

% updates the movie duration
setappdata(handles.figTestMovie,'vPara',vPara);
set(handles.textMovDur,'string',detDurString(vPara));

% --- Executes on slider movement.
function sliderFrmRate_Callback(hObject, eventdata, handles)

% object retrieval
hFig = handles.figTestMovie;
vPara = getappdata(hFig,'vPara');
infoObj = getappdata(hFig,'infoObj');

% updates the frame rate
vPara.FPS = round(get(hObject,'Value'),1);
set(handles.textFrmRate,'String',num2str(vPara.FPS))

% sets the camera frame rate
srcObj = get(infoObj.objIMAQ,'Source');
fpsFld = getCameraRatePara(srcObj);
fpsInfo = propinfo(srcObj,fpsFld);
fpsLim = fpsInfo.ConstraintValue;
set(srcObj,fpsFld,max(min(vPara.FPS,fpsLim(2)),fpsLim(1)));

% updates the movie duration
setappdata(handles.figTestMovie,'vPara',vPara);
set(handles.textMovDur,'string',detDurString(vPara));

% --- Executes on selection change in popupVideoCompression.
function popupVideoCompression_Callback(hObject, eventdata, handles)

% retrieves the video parameter struct
vPara = getappdata(handles.figTestMovie,'vPara');    

% ------------------------------- %
% --- PROGRAM CONTROL BUTTONS --- %
% ------------------------------- %

% --- Executes on button press in buttonSave.
function buttonSave_Callback(hObject, eventdata, handles)

% global variables
global vPara

% sets an empty parameter struct and deletes the struct
vPara = getappdata(handles.figTestMovie,'vPara');
iProg = getappdata(handles.figTestMovie,'iProg');
vidProf = get(handles.popupVideoCompression,'UserData');

% sets the selected compression parameters
iSel = get(handles.popupVideoCompression,'value');
vExtn = vidProf{iSel}.FileExtensions{1};
vCompressM = vidProf{iSel}.VideoCompressionMethod;

% prompts the user for the solution file directory
tStr = 'Select The Video Solution Files';
fMode = {['*',vExtn],sprintf('%s (*%s)',vCompressM,vExtn)};
[fName,fDir,fIndex] = uiputfile(fMode,tStr,iProg.DirMov);
if (fIndex == 0)
    % if the user cancelled, then exit
    return
else
    % sets the file name
    [~,vPara.Name,~] = fileparts(fName);
    
    % otherwise, update the compression parameters    
    vPara.Dir = fDir;
    vPara.vCompress = vidProf{iSel}.Name;
    vPara.vExtn = vExtn;
end

% deletes the GUI
delete(handles.figTestMovie)

% --- Executes on button press in buttonCancel.
function buttonCancel_Callback(hObject, eventdata, handles)

% global variables
global vPara

% sets an empty parameter struct and deletes the struct
vPara = [];
delete(handles.figTestMovie)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- sets up the duration string           
function durStr = detDurString(vPara)

% calculates the time in (DD/HH/MM/SS) format and set the final string
durStr = num2str(roundP(vPara.Tf*vPara.FPS));

% --- initialises the experimental information fields
function initVideoParaProps(handles)

% retrieves the experimental duration data struct
hFig = handles.figTestMovie;
hPopup = handles.popupFrmRate;
hSlider = handles.sliderFrmRate;
vPara = getappdata(hFig,'vPara');
infoObj = getappdata(hFig,'infoObj');

% retrieves the camera frame rate
if infoObj.isWebCam
    % sets the frame rate values/selections    
    isVarFPS = false;
    [fRateN,fRateS,iSel] = detWebcameFrameRate(infoObj.objIMAQ,vPara.FPS);        
else
    % sets the frame rate values/selections
    isVarFPS = detIfFrameRateVariable(infoObj.objIMAQ);
    srcObj = getselectedsource(infoObj.objIMAQ);
    [fRateN,fRateS,iSel] = detCameraFrameRate(srcObj,vPara.FPS);
end

% sets the object visibility flags
setObjVisibility(hPopup,~isVarFPS)
setObjVisibility(handles.textFrmRate,isVarFPS)
setObjVisibility(hSlider,isVarFPS)

% sets up the camera frame rate objects
if isVarFPS
    % case is a variable frame rate camera
    initFrameRateSlider(hSlider,srcObj,fRateN);    
    sliderFrmRate_Callback(hSlider, [], handles) 
else
    % updates the video frame rate
    vPara.FPS = fRateN(iSel);
    setappdata(hFig,'vPara',vPara)    

    % initialises the frame rate listbox
    set(hPopup,'string',fRateS,'value',iSel)
    if length(fRateN) == 1; setObjEnable(hPopup,0); end
    popupFrmRate_Callback(hPopup, [], handles)
end

% sets up the video compression popup box
setupVideoCompressionPopup(infoObj.objIMAQ,handles.popupVideoCompression,1)
