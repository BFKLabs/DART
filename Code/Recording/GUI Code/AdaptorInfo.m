function varargout = AdaptorInfo(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @AdaptorInfo_OpeningFcn, ...
    'gui_OutputFcn',  @AdaptorInfo_OutputFcn, ...
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

% --- Executes just before AdaptorInfo is made visible.
function AdaptorInfo_OpeningFcn(hObject, ~, handles, varargin)

% turns off all warnings
wState = warning('off','all');

% Choose default command line output for AdaptorInfo
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% sets up the input parser
ip = inputParser;
addParameter(ip,'hFigM',[]);
addParameter(ip,'iType',[]);
addParameter(ip,'iStim',[]);
addParameter(ip,'reqdConfig',[]);

% parses the input arguments
parse(ip,varargin{:})
p = ip.Results;

% sets the main figure handles
setappdata(hObject,'hFigM',p.hFigM)
setappdata(hObject,'iStim',p.iStim)

% creates the adaptor info class object
setObjVisibility(p.hFigM,'off');
infoObj = AdaptorInfoClass(hObject,p.iType,p.reqdConfig);
setappdata(hObject,'infoObj',infoObj)

% if there was an error, then close the GUI
if ~infoObj.ok
    buttonExit_Callback(handles.buttonExit, [], handles)
    return
end

% centres the figure
centreFigPosition(hObject);

% closes the loadbar
warning(wState);
try delete(h); catch; end

% wait for user response (daq matching only)
if any(p.iType == [2,3])
    uiwait(handles.figAdaptInfo);
end

% --- Outputs from this function are returned to the command line.
function varargout = AdaptorInfo_OutputFcn(~, ~, ~)

% global variables
global outObj

% Get default command line output from handles structure
varargout{1} = outObj;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when user attempts to close figAdaptInfo.
function figAdaptInfo_CloseRequestFcn(~, ~, handles)

% exits the gui
buttonExit_Callback(handles.buttonExit, [], handles)

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ------------------------------- %
% --- PROGRAM CONTROL BUTTONS --- %
% ------------------------------- %

% --- Executes on button press in buttonConnect.
function buttonConnect_Callback(~, ~, handles)

% global variables
global outObj

% gets the DAC only flag
hFig = handles.figAdaptInfo;
hFigM = getappdata(hFig,'hFigM');
infoObj = getappdata(hFig,'infoObj');

% creates a progressbar
h = ProgressLoadbar('Establishing Image Acquisition Device Connection...');

% ----------------------------------------------- %
% --- IMAGE ACQUISITION OBJECT INITIALISATION --- %
% ----------------------------------------------- %

% creates the image acquistion objects
if infoObj.hasIMAQ && isempty(infoObj.reqdConfig)
    infoObj = connectIMAQDevice(handles,infoObj,h);
end

% --------------------------------------- %
% --- DATA ACQUISTION OBJECT CREATION --- %
% --------------------------------------- %

% creates a progressbar
h.StatusMessage = 'Establishing Data Acquisition Device Connections...';
pause(0.1)

% updates the data acquistion object parameters
if infoObj.hasDAQ
    infoObj = updateDAQDevice(infoObj);
end
    
% if initialising/setting a new experiment, update the stimuli information
if any(infoObj.iType == [1,2]) && infoObj.hasDAQ
    infoObj = updateStimParaFields(handles,infoObj);
end

% creates a progressbar
h.StatusMessage = 'Device Initialisation Complete!';

% deletes the GUI
delete(hFig)
pause(0.1);

% continues based on the way the AdaptorInfo gui was called
switch infoObj.iType
    case 0
        % case is there was an error during initialisation
        setObjVisibility(hFigM,1);
        try close(h); catch; end
        return
    
    case 1
        % case is initialising from DART
        switch infoObj.exType
            case 'StimOnly'
                ExptSetup(infoObj,h);
            otherwise
                FlyRecord(infoObj,h);
        end
        
    case 2
        % case is creating a new experiment in RecordGUI or ExptSetup
        outObj = infoObj;
        setObjVisibility(infoObj.hFigM,'on')
        
    case 3
        % case is checking the device configuration
        outObj = infoObj.objDAQ;
        setObjVisibility(infoObj.hFigM,'on')
end

% closes the progressbar
try close(h); catch; end

% --- Executes on button press in buttonExit.
function buttonExit_Callback(~, ~, handles)

% global variables
global outObj
outObj = [];

% retrieves the object handles
hFig = handles.figAdaptInfo;
infoObj = getappdata(hFig,'infoObj');

% makes the main gui visible again
setObjVisibility(infoObj.hFigM,'on');

% deletes the GUI
delete(hFig)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- updates the stimuli device parameter struct fields
function infoObj = updateStimParaFields(handles,infoObj)

% object retrieval
hFig = handles.figAdaptInfo;
iStim = getappdata(hFig,'iStim');

% sets up the parameter fields (if IMAQonly)
iStim.nDACObj = length(infoObj.objDAQ.vSelDAQ);
if iStim.nDACObj > 0
    % sets the DAC channel IDs and string names
    iStim = setChannelID(infoObj.objDAQ,iStim);

    % allocates memory for sub-structs
    iStim.oPara = repmat(iStim.oPara,iStim.nDACObj,1);        

    % limits the voltages on the custom serial objects
    isSTM = find(cellfun(@(x)(strcmp(x,...
            'STMicroelectronics STLink Virtual COM Port')),...
            infoObj.objDAQ.BoardNames));
    for i = reshape(isSTM,1,length(isSTM))
        iStim.oPara(i).vMin = 2.0;
        iStim.oPara(i).vMax = 3.5;
    end
else
    % otherwise, set an empty array for the channel names
    iStim.oPara = struct('vMin',0.5,'vMax',2.5,'sRate',50);
end  

% updates the object field
infoObj.iStim = iStim;

% sets the DAC device ID tags
function iStim = setChannelID(objDAQ,iStim)

% retrieves the number of channels per DAC device
i0 = 0;

% otherwise, set the number of DAC objects
iStim.nChannel = objDAQ.nChannel;
iStim.nChannel(isnan(iStim.nChannel)) = 1;

% sets the ID fields for all of the stimuli types
for i = 1:iStim.nDACObj
    % sets the ID flags for the current device
    for j = 1:iStim.nChannel(i)
        iStim.ID(i0+j,:) = [i j];
    end
    
    % increments the offset counter
    i0 = i0 + iStim.nChannel(i);
end

% --- connects the imaq recording device
function infoObj = connectIMAQDevice(handles,infoObj,h)

% exits if a stimuli only experiment
if strcmp(infoObj.exType,'StimOnly') || infoObj.isTest
    infoObj.objIMAQ = DummyVideo(infoObj.testFile);
    return
end

% field retrieval
sFormat = infoObj.sFormat;
vSelIMAQ = infoObj.vSelIMAQ;
vIndIMAQ = infoObj.vIndIMAQ;
objIMAQDev = infoObj.objIMAQDev;

% retrieves the selected video input object index
iSelV = get(handles.listIMAQObj,'Value');   
infoObj.isWebCam = isCamUVC(objIMAQDev{iSelV}.DeviceName);

% deletes any previous camera objects
prImaqObj = imaqfind;
if ~isempty(prImaqObj)
    delete(prImaqObj)
end

% otherwise, set the video object to the user selection
try
    vConStr = objIMAQDev{vIndIMAQ(vSelIMAQ,1)}...
                   (vIndIMAQ(vSelIMAQ,2)).VideoInputConstructor;
catch
    try
        vConStr = objIMAQDev{iSelV}...
                    (vIndIMAQ(vSelIMAQ,2)).VideoInputConstructor;
    catch
        vConStr = objIMAQDev{iSelV}...
                        (vIndIMAQ(vSelIMAQ,2)).ObjectConstructor;
    end
end

% creates the video object constructor object string
sFormatF = sFormat{vSelIMAQ}{infoObj.sInd(vSelIMAQ)};
dName = objIMAQDev{vIndIMAQ(vSelIMAQ,1)}(vIndIMAQ(vSelIMAQ,2)).DeviceName;

vStr = sprintf('%s, ''%s'')',vConStr(1:end-1),sFormatF);
try
    % attempts to create a connection with the recording device
    objIMAQ0 = eval(vStr);
    
catch ME
    % make the loadbar invisible
    setObjVisibility(h.Control,0);
    
    % case is there is an error...
    if strcmp(ME.identifier,'winvideo:internal:dxMsg')
        % case is the video is already in use...
        tStr = 'Recording Device Communication Error';
        eStr = {['Error! Selected recording device is already in ',...
             'use. Please re-select.'];'';['If using multiple ',...
             'cameras ensure they are attached to individual ports.']};
        waitfor(errordlg(eStr,tStr,'modal'))

    else
        % if there is another error type, then output another message
        eStr = ['Critical error with the selected recording ',...
                'device. Please re-select.'];
        waitfor(errordlg(eStr,'Recording Device Error','modal'))
    end

    % resets the status flag exits the function
    infoObj.iType = 0;
    return
end

if infoObj.isWebCam
    % retrieves the source information (deleting the video object)
    pInfo = propinfo(objIMAQ0.Source);
    delete(objIMAQ0)
    pause(0.05);
    
    % creates the webcam object
    devName = objIMAQDev{iSelV}.DeviceName;
    infoObj.objIMAQ = createWebCamObj(devName,pInfo,sFormatF);

else
    % case is a non-webcam device
    infoObj.objIMAQ = objIMAQ0;
        
    % ensure that the video object writes avi objects to disk
    try
        set(infoObj.objIMAQ,'ReturnedColorSpace','grayscale');
        set(infoObj.objIMAQ,'Name',dName);
    catch
    end

    % sets the trigger configuration flag
    triggerconfig(infoObj.objIMAQ,'manual')
    
    % resets any ROI parameters
    resetCameraROIPara(infoObj.objIMAQ)
    
    % sets the camera automatic fields to manual
    srcObj = getselectedsource(infoObj.objIMAQ);
    resetFld = [];
    % resetFld = {{'FocusMode','manual'},...
    %             {'ExposureMode','auto'},...
    %             {'WhiteBalanceMode','manual'}};
    
    % resets the flagged camera properties (if they exist)
    for i = 1:length(resetFld)
        if isprop(srcObj,resetFld{i}{1})
            try
                set(srcObj,resetFld{i}{1},resetFld{i}{2})
            catch
            end
        end
    end
    
    % increases the amount of memory available to the camera
    try
        a = imaqmem;
        imaqmem(min(a.AvailVirtual,2*a.FrameMemoryLimit));
    catch
    end
end

% --- updates the DAQ device information
function infoObj = updateDAQDevice(infoObj)

% exits if a recording only experiment
if strcmp(infoObj.exType,'RecordOnly')
    infoObj.objDAQ = [];
    return
end

try
    % deletes any previous DAC objects in memory
    prDaqObj = daqfind;
    if ~isempty(prDaqObj)
        delete(prDaqObj)
    end
catch
end

% sets the channel count array (removes non-selected items)
nCh = infoObj.nCh;
nCh(~setGroup(infoObj.vSelDAQ(:),size(nCh))) = 0;

% sets the DAC object information
infoObj.objDAQ.iChannel = arrayfun(@(x)...
                ((1:x)-1),infoObj.nCh(infoObj.vSelDAQ),'un',0)'; 
infoObj.objDAQ.vSelDAQ = infoObj.vSelDAQ;
infoObj.objDAQ.nChannel = nCh;    
infoObj.objDAQ.vStrDAQ = infoObj.vStrDAQ;    
infoObj.objDAQ.sRate = 50*ones(length(infoObj.vStrDAQ),1);   
