function varargout = FlyRecord(varargin)
% Last Modified by GUIDE v2.5 24-Nov-2021 19:53:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @FlyRecord_OpeningFcn, ...
    'gui_OutputFcn',  @FlyRecord_OutputFcn, ...
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

% --- Executes just before FlyRecord is made visible.
function FlyRecord_OpeningFcn(hObject, eventdata, handles, varargin)

% turns off all warnings
wState = warning('off','all');
handles.output = hObject;

% --------------------------------------------------- %
% --- PARAMETERS & FIGURE POSITION INITIALISATION --- %
% --------------------------------------------------- %

% deletes any existing timer objects
hT = timerfindall();
if ~isempty(hT)
    deleteTimerObjects(hT);
end

% global variables
global defVal minISI isAddPath nFrmRT runTrack
[defVal,minISI,nFrmRT] = deal(5,60,150);
[isAddPath,runTrack] = deal(false);

% input arguments
infoObj = varargin{1};
h = varargin{2};

% updates the progress message
h.StatusMessage = 'Initialising Recording GUI...';

% seeds the random number generator to the system clock
rSeed = sum(100*clock);
try
    RandStream.setGlobalStream(RandStream('mt19937ar','seed',rSeed));
catch
    RandStream.setDefaultStream(RandStream('mt19937ar','seed',rSeed));
end

% initialises the other GUI functions
setappdata(hObject,'initExptStruct',@initExptStruct)
setappdata(hObject,'toggleVideoPreview',@toggleVideoPreview_Callback);
setappdata(hObject,'resetVideoPreviewDim',@resetVideoPreviewDim);

% ----------------------------------------------------------- %
% --- FIELD INITIALISATIONS & DIRECTORY STRUCTURE SETTING --- %
% ----------------------------------------------------------- %

% sets the input arguments
hDART = infoObj.hFigM;

% otherwise, make the DART GUI invisible
setObjVisibility(hDART,'off')    

% ---------------------------------- %
% --- DATA STRUCT INITIALISATION --- %
% ---------------------------------- %

% initialises the stimulus parameter struct
iPara = initStimParaStruct();

% initialises the program preferences struct
if isempty(hDART)
    % retrieves the program defaults from the local parameter file
    iProg = initProgDef(handles); 
else
    % retrieves the program defaults from DART
    iProg = getappdata(hDART,'ProgDefNew');
end

% sets the program data struct
setappdata(hObject,'iPara',iPara);
setappdata(hObject,'iProg',iProg);

% ------------------------------------- %
% --- ADAPTOR OBJECT INITIALISATION --- %
% ------------------------------------- %   

% reduces the device information
if infoObj.hasDAQ
    [objDAQ,objDAQ0] = reduceDevInfo(infoObj.objDAQ);
else
    [objDAQ,objDAQ0] = deal([]);
end

% sets the program directory and the DART object handles
setappdata(hObject,'iMov',[]);
setappdata(hObject,'sTrain',[]);
setappdata(hObject,'hDART',hDART)
setappdata(hObject,'isRot',false);
setappdata(hObject,'objDAQ0',objDAQ0);
setappdata(hObject,'objDAQ',objDAQ);
setappdata(hObject,'infoObj',infoObj)
setappdata(hObject,'iStim',infoObj.iStim);

% runs the external packages
feval('runExternPackage','RTTrack',handles,'Init');
feval('runExternPackage','VideoCalibObj',handles);

% ------------------------------------------ %
% --- GUI OBJECT PROPERTY INITIALISATION --- %
% ------------------------------------------ %

% updates the progress message
h.StatusMessage = 'Starting Video Preview...';

% updates the DAC adaptor name strings
iExpt = initExptStruct(infoObj.exType,infoObj.objIMAQ);
setappdata(hObject,'iExpt',iExpt);

% initialises the GUI properties
handles = setRecordGUIProps(handles,'InitGUI',infoObj.exType);
resetVideoPreviewDim(handles)

% creates the video preview object
prObj = VideoPreview(hObject,true);
setappdata(hObject,'prObj',prObj);

% ------------------------------------- %
% --- FINAL HOUSE-KEEPING EXERCISES --- %
% ------------------------------------- %

% initialises using full GUI setup
setRecordGUIProps(handles,'InitOptoMenuItems');

% turns on the camera for preview
set(handles.toggleVideoPreview,'value',1)
toggleVideoPreview_Callback(handles.toggleVideoPreview,1,handles);

% initialises the axes properties
initAxesProps(handles,[],handles.axesPreview)
set(hObject,'CurrentAxes',handles.axesPreview)

% turns on all warnings again
try; close(h); end
warning(wState);

% Update handles structure
guidata(hObject, handles); 
    
% UIWAIT makes FlyRecord wait for user response (see UIRESUME)
% uiwait(handles.figFlyRecord);

% --- Outputs from this function are returned to the command line.
function varargout = FlyRecord_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = [];

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% ----------------------- %
% --- FILE MENU ITEMS --- %
% ----------------------- %

% -------------------------------------------------------------------------
function menuNewExpt_Callback(hObject, eventdata, handles)

% global variables
hFig = handles.figFlyRecord;
infoObj0 = getappdata(hFig,'infoObj');
setObjVisibility(hFig,'off'); pause(0.05);

% retrieves the camera field names and property values
if ~infoObj0.isTest
    srcObj = getselectedsource(infoObj0.objIMAQ);
    [~,fldNames] = combineDataStruct(propinfo(srcObj));
    pVal0 = get(srcObj,fldNames);
end

% if the IR lights are on, then turn them off
onIR = strcmp(get(handles.menuToggleIR,'Checked'),'on');
if onIR
    menuToggleIR_Callback(handles.menuToggleIR, '1', handles)    
end

% initialises the experimental adaptors
iStimNw = initTotalStimParaStruct();
infoObj = AdaptorInfo('hFigM',hFig,'iType',2,'iStim',iStimNw);
if isempty(infoObj)
    % if the IR was originally on, then turn the light back on
    if onIR
        menuToggleIR_Callback(handles.menuToggleIR, '1', handles)    
    end    
    
    % makes the gui visible again and exits
    setObjVisibility(hFig,'on')
    return
else
    % sets the data structs into the GUI
    propStr = 'InitOptoMenuItems';
    setappdata(hFig,'infoObj',infoObj);
        
    % updates the stimuli data struct and expt type
    setappdata(hFig,'iMov',[]);
    setappdata(hFig,'iStim',infoObj.iStim);
    setappdata(hFig,'exptType',infoObj.exType)     
    
    % resets the video preview dimensions
    resetVideoPreviewDim(handles)    
    
    % reduces the device information
    if infoObj.hasDAQ    
        [objDAQ,objDAQ0] = reduceDevInfo(infoObj.objDAQ);
        setappdata(hFig,'objDAQ0',objDAQ0);
        setappdata(hFig,'objDAQ',objDAQ);    
    else
        setappdata(hFig,'objDAQ0',[]);
        setappdata(hFig,'objDAQ',[]); 
    end
    
    % resets the real-time tracking parameters
    rtObj = getappdata(hFig,'rtObj');
    if ~isempty(rtObj)
%         rtObj.initTrackPara();
%         rtObj.initVideoTimer(handles)  
    end    
end    

% ------------------------------------------ %
% --- GUI OBJECT PROPERTY INITIALISATION --- %
% ------------------------------------------ %

% initialises the experiment struct
iExpt = initExptStruct(infoObj.iStim,infoObj.objIMAQ,infoObj.exType);
setappdata(hFig,'iExpt',iExpt);

% sets the GUI properties based on whether testing or not
setRecordGUIProps(handles,'InitGUI',infoObj.exType);
setRecordGUIProps(handles,propStr)

% if there is no change in the camera type, then reset the camera to 
% the original parameters (full program only)    
if ~infoObj.isTest && ~infoObj0.isTest 
    % retrieves the current camera properties and resets any class fields
    % that don't match
    srcObjNw = getselectedsource(infoObj.objIMAQ);
    [srcInfoNw,fldNamesNw] = combineDataStruct(propinfo(srcObjNw));
    if isequal(fldNamesNw,fldNames)
        % only updates the non read-only fields
        for i = 1:length(fldNamesNw)
            if (~strcmp(srcInfoNw(i).ReadOnly,'always'))
                switch (fldNames{i})
                    case ('FrameRate')
                        set(srcObjNw,fldNames{i},srcObjNw.FrameRate)
                    otherwise
                        try
                            set(srcObjNw,fldNames{i},pVal0{i})
                        end
                end
            end
        end
    end
end
    
% turns on the camera/video for preview
set(handles.toggleVideoPreview,'value',1)
toggleVideoPreview_Callback(handles.toggleVideoPreview, '1', handles)

% makes the main GUI visible again
setObjVisibility(hFig,'on');

% -------------------------------------------------------------------------
function menuSyncSummary_Callback(hObject, eventdata, handles)

% runs the summary sychronisation file GUI
SyncSummary(handles.figFlyRecord)

% -------------------------------------------------------------------------
function menuProgDef_Callback(hObject, eventdata, handles)

% runs the program default GUI
ProgDefaultDef(handles.figFlyRecord,'Recording');

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

% prompts the user if they wish to close the recording gui
selection = questdlg('Are you sure you want to close the Recording GUI?',...
                     'Close Recording GUI?','Yes','No','Yes');
if strcmp(selection,'Yes')
    % retrieves the DART handle
    hDART = findall(0,'tag','figDART','type','figure');         

    % deletes any existing timer objects
    hT = timerfindall();
    if ~isempty(hT)
        deleteTimerObjects(hT)
    end
    
    % if the IR lights are on, then turn them off
    if strcmp(get(handles.menuToggleIR,'Checked'),'on')
        menuToggleIR_Callback(handles.menuToggleIR, '1', handles)    
    end    

    % deletes any previous DAC objects in memory
    try
        daqObj = daqfind;
        if ~isempty(daqObj)
            delete(daqObj)
        end
    end

    % deletes any previous imaq objects in memory
    try
        imaqObj = imaqfind;
        if ~isempty(imaqObj)
            delete(imaqObj)
        end
    end

    % closes and deletes any open serial objects
    hh = instrfind();
    if ~isempty(hh)
        try
            fclose(hh)
            delete(hh)
        end
    end
    
    % retrieves the video ROI sub-GUI figure handle
    hVideoROI = findobj(0,'tag','figVideoROI');
    if ~isempty(hVideoROI)
        % if the sub-GUI is open, then delete it
        delete(hVideoROI)        
    end

    % retrieves the video parameter sub-GUI figure handle
    hVidPara = findall(0,'tag','figVideoPara');
    if ~isempty(hVidPara)
        % if the sub-GUI is open, then delete it
        delete(hVidPara)
    end

    % deletes the imageseg and makes the main DART GUI visible again
    delete(handles.figFlyRecord)                
    setObjVisibility(hDART,'on');    
end

% -------------------------- %
% --- ADAPTOR MENU ITEMS --- %
% -------------------------- %

% -------------------------------------------------------------------------
function menuVideoProps_Callback(hObject, eventdata, handles)

% runs the video parameter sub-GUI
VideoPara(handles)

% -------------------------------------------------------------------------
function menuTestRecord_Callback(hObject, eventdata, handles)

% retrieves the parameter data struct
hFig = handles.figFlyRecord;
hToggle = handles.toggleVideoPreview;
iProg = getappdata(hFig,'iProg');
infoObj = getappdata(hFig,'infoObj');

% disables the preview (if currently on)
if get(handles.toggleVideoPreview,'Value')
    set(handles.toggleVideoPreview,'Value',0)
    toggleVideoPreview_Callback(handles.toggleVideoPreview, [], handles)
end

% prompts the user for the movie parameters
vPara = TestMovie(infoObj,iProg); 
if ~isempty(vPara)    
    % turns off the video preview (if on)    
    if get(hToggle,'Value')
        set(hToggle,'Value',0);
        toggleVideoPreview_Callback(hToggle, '1', handles)
    end
        
    % retrieves the video recording object
    setObjEnable(hToggle,'off')
    pause(0.05);        
    
    % sets up and runs the test video recording
    exObj = RunExptObj(hFig,'Test',vPara); 
    if ~exObj.isOK
        % if there was an issue in setting up the recording object, then
        % exit the function
        return
    end
    
    % initialises the time start
    [tStart,Tp] = deal(tic,3); 
    wStr = 'Waiting For Test Video Recording To Start';   

    % pauses the program until the wait-period has passed
    while 1
        tNew = toc(tStart);
        if tNew > Tp
            break
        else
            % updates the waitbar figure
            tRem = Tp - tNew;
            if exObj.hProg.Update(1,sprintf('%s (%i Seconds Remains)',...
                                            wStr,ceil(tRem)),1-tRem/Tp)
                % if the user cancelled, then exit
                setObjEnable(handles.toggleVideoPreview,'on')
                return
            else
                % pause to ensure camera has initialised properly
                pause(0.1);           
            end
        end               
    end
    
    % starts the test object
    exObj.isStart = true;
    trigger(exObj.objIMAQ)     
end

% -------------------------------------------------------------------------
function menuVidROI_Callback(hObject, eventdata, handles)

% runs the video ROI setting GUI
wState = warning('off','all');
VideoROI(handles.figFlyRecord)
warning(wState);

% ----------------------------- %
% --- EXPERIMENT MENU ITEMS --- %
% ----------------------------- %

% -------------------------------------------------------------------------
function menuSetupExpt_Callback(hObject, eventdata, handles)

% retrieves the test flag
hFig = handles.figFlyRecord;

% disables the file menu items
setObjEnable(handles.menuFile,'off')
setObjEnable(handles.menuExpt,'off')
setObjEnable(handles.menuOpto,'off')
% setObjEnable(handles.menuRTTrack,'off')

% otherwise, run the full stimuli experimental protocol GUI
ExptSetup(handles.figFlyRecord);   

% ------------------------------ %
% --- CALIBRATION MENU ITEMS --- %
% ------------------------------ %

% -------------------------------------------------------------------------
function menuCalibrateTrack_Callback(hObject, eventdata, handles)

% retrieves the full DART program default struct directory
ProgDefFull = getappdata(findall(0,'tag','figDART'),'ProgDef');
setappdata(handles.figFlyRecord,'ProgDefNew',ProgDefFull.Tracking)

% runs the Fly Tracking GUI to calibrate the video
FlyTrack(handles,1);

% ------------------------------- %
% --- OPTOGENETICS MENU ITEMS --- %
% ------------------------------- %

% -------------------------------------------------------------------------
function menuToggleIR_Callback(hObject, eventdata, handles)

% toggles the IR lights
toggleOptoLights(handles,hObject,true)

% -------------------------------------------------------------------------
function menuToggleWhite_Callback(hObject, eventdata, handles)

% toggles the white lights
toggleOptoLights(handles,hObject,false)

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ----------------------------------- %
% --- VIDEO PREVIEW PANEL OBJECTS --- %
% ----------------------------------- %

% --- Executes on button press in toggleVideoPreview.
function toggleVideoPreview_Callback(hObject, eventdata, handles)

% sets the eventdata flag (if not specifically set)
prObj = getappdata(handles.figFlyRecord,'prObj');
isSel = get(hObject,'value');
setObjEnable(handles.menuCalibrate,~isSel)

% starts/stops
if isSel
    prObj.startVideoPreview()
else
    prObj.stopVideoPreview()
end

% --- Executes on button press in checkShowGrid.
function checkShowGrid_Callback(hObject, eventdata, handles)

% retrieves the preview axis handle
hGrid = findobj(handles.axesPreview,'tag','hGrid');

% toggles the check mark and the minor gridlines
if ~get(hObject,'Value') || isa(eventdata,'char')
    % removes the check mark and makes the gridline invisible  
    setObjVisibility(hGrid,'off')
    
else
    % makes the gridlines visible again
    if isempty(hGrid)
        % if the gridlines don't exist, then plot them
        initGridLines(handles);
    else
        % otherwise make them visible
        setObjVisibility(hGrid,'on')
    end
end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- resets the gui dimensions based on the video ROI
function resetVideoPreviewDim(handles,rPos)

% retrieves the video object
hFig = handles.figFlyRecord;
hAx = handles.axesPreview;
isReset = exist('rPos','var');
vcObj = getappdata(hFig,'vcObj');
infoObj = getappdata(hFig,'infoObj');

% turns off all warnings
wState = warning('off','all');

% determines if the new roi position has been provided
if isReset
    % calculates the bottom location of the preview
    vRes = getVideoResolution(infoObj.objIMAQ);    
    rPos(2) = vRes(2) - sum(rPos([2,4]));     
    
    % resets the dimensions of the preview axes
    if ~infoObj.isTest            
        % inverts the bottom location of the ROI
        set(infoObj.objIMAQ,'ROIPosition',rPos); 
        set(hAx,'xlim',[0,rPos(3)],'ylim',[0,rPos(4)])
    end
    
    % if the camera preview is off, then reset the axes image
    prObj = getappdata(hFig,'prObj');
    if ~prObj.isOn
        % retrieves the image resolution
        hImage = findall(hAx,'type','Image');
        set(hImage,'CData',uint8(zeros(rPos([4,3]))));
    end
else
    % otherwise, retrieve the current roi position 
    rPos = getVideoROIPosition(infoObj);
end

% calculates the change in the GUI height
pAR = rPos(4)/rPos(3);
pPos = get(handles.panelImg,'Position');
dH = roundP(pAR*pPos(3) - pPos(4));

% resets the dimensions of the GUI
resetObjPos(hFig,'Height',dH,1);
resetObjPos(hFig,'Bottom',-dH,1);
resetObjPos(handles.panelVidPreview,'Height',dH,1);
resetObjPos(handles.panelImg,'Height',dH,1);
resetObjPos(hAx,'Height',dH,1);
pause(0.05);

% resets the dimensions of the video calibration panel
if ~isempty(vcObj)
    vcObj.resetObjProps(dH);
end

% resets the warning flags
warning(wState)

% ---------------------------------------------- %
% --- OBJECT/STRUCT INITIALISATION FUNCTIONS --- %
% ---------------------------------------------- %

% --- initialises the stimulus parameter struct
function iPara = initStimParaStruct()

% sub-struct initialisation
sStr = struct('pVal',[],'pMin',[],'pMax',[],'isRand',false);
opStr = struct('wNM',450,'pI',100,'sRate',50);

% initialises the parameter struct
iPara = struct('pCount',sStr,'pDur',sStr,'pAmp',sStr,...
               'pDelay',sStr,'sDelay',sStr,'iDelay',sStr,...
               'pOpto',opStr);

% sets the stimulus count parameters
iPara.pCount.pVal = 5;
iPara.pCount.pMin = 1;
iPara.pCount.pMax = 5;

% sets the stimulus duration parameters
iPara.pDur.pVal = 0.2;
iPara.pDur.pMin = 0.1;
iPara.pDur.pMax = 0.5;

% sets the stimulus amplitude parameters
iPara.pAmp.pVal = 1.0;
iPara.pAmp.pMin = 0.0;
iPara.pAmp.pMax = 1.0;

% sets the pulse delay parameters
iPara.pDelay.pVal = 0.5;
iPara.pDelay.pMin = 0.1;
iPara.pDelay.pMax = 1.0;

% sets the stimulus delay parameters
iPara.sDelay.pVal = 30.0;
iPara.sDelay.pMin = 10.0;
iPara.sDelay.pMax = 100.0;

% sets the pulse delay parameters
iPara.iDelay.pVal = 0.0;
iPara.iDelay.pMin = 0.0;
iPara.iDelay.pMax = 2.0;

% ------------------------------------------- %
% --- PROGRAM DEFAULT DIRECTORY FUNCTIONS --- %
% ------------------------------------------- %

% --- initialises and confirms that A) the program default file exists, and
%     B) the directories listed in the file are valid --- %
function ProgDef = initProgDef(handles)

% sets the program default file name
progFile = getParaFileName('ProgDef.mat');
progFileDir = fileparts(progFile);

% determines if the program defaults have been set
if (~exist(progFileDir,'dir')); mkdir(progFileDir); end
if (exist(progFile,'file'))
    % if so, loads the program preference file and set the program
    % preferences (based on the OS type)
    A = load(progFile);
    ProgDef = checkDefaultDir(A.ProgDef);         
else
    % displays a warning
    uChoice = questdlg(['Program defaults file not found. Would you like ',...
        'to setup the program default file manually or automatically?'],...
        'Program Default Setup','Manually','Automatically','Manually');
    switch (uChoice)
        case ('Manually')
            % user chose to setup manually, so load the ProgDef sub-GUI            
            ProgDefaultDef(handles.figFlyRecord,'Recording');
            ProgDef = getappdata(handles.figFlyRecord,'iProg');
            
        case ('Automatically')
            % user chose to setup automatically then create the directories            
            ProgDef = setupAutoDir(progFile);
            pause(0.05); % pause required otherwise program crashes?
    end
end

% --- checks if the program default directories exist ---------------------
function [ProgDef,isExist] = checkDefaultDir(ProgDef,varargin)

% retrieves the field names
fldNames = fieldnames(ProgDef);
isExist = true(length(fldNames),1);

% loops through all the field names determining if the directories exist
for i = 1:length(fldNames)
    % sets the new variable string
    nwVar = sprintf('ProgDef.%s',fldNames{i});
    nwDir = eval(nwVar);
    fType = 'dir';
    
    % if no directory has not set, then set the field names
    switch (fldNames{i})
        case ('DirMov')
            dirName = 'Default Output Movie';
        case ('StimPlot')
            dirName = 'Stimulus Trace';
        case ('DirPlay')
            dirName = 'Playlist File';
        case ('CamPara')
            dirName = 'Video Presets';            
    end
    
    % check to see if the directory exists
    if (isempty(nwDir))
        % flag that the directory has not been set
        isExist(i) = false;
        if (nargin == 1)
            wStr = sprintf('Warning! The "%s" directory is not set.',dirName);
            waitfor(warndlg(wStr,'Directory Location Error','modal'))     
        end
    elseif (exist(nwDir,fType) == 0)
        % if the directory does not exist, then clear the directory field
        % and flag a warning
        isExist(i) = false;
        eval(sprintf('%s = [];',nwVar));
        
        if (nargin == 1)
            wStr = sprintf('Warning! The "%s" directory does not exist.',dirName);
            waitfor(warndlg(wStr,'Missing Directory','modal'))    
        end
    end
end

% if any of the directories do not exist, then
if any(~isExist)
    % runs the program default sub-ImageSeg
    if nargin == 1
        ProgDefaultDef(handles.figFlyRecord,'Recording');
        ProgDef = getappdata(handles.figFlyRecord,'iProg');
    end
end

% --- function that automatically sets up the default directories --- %
function ProgDef = setupAutoDir(progFile)

% sets the base data file directory path
baseDir = getProgFileName('Data Files');

% sets the default directory names
a.DirMov = fullfile(baseDir,'Recorded Movies');
a.StimPlot = fullfile(baseDir,'Stimulus Traces');
a.DirPlay = fullfile(baseDir,'Stimuli Playlists');
a.CamPara = fullfile(baseDir,'Video Presets');

% creates the new default directories (if they do not exist)
b = fieldnames(a);
for i = 1:length(b)
    % sets the new directory name
    nwDir = eval(sprintf('a.%s',b{i}));

    % if the directory does not exist, then create it
    if (exist(nwDir,'dir') == 0)
        mkdir(nwDir)
    end
end

% saves the program default file
ProgDef = a;
save(progFile,'ProgDef');

% --------------------------------------- %
% --- PREVIEW AXIS GRIDLINE FUNCTIONS --- %
% --------------------------------------- %

% --- initialises the grid lines on the preview figure
function initGridLines(handles)

% retrieves the parameter struct
hAx = handles.axesPreview;
hFig = handles.figFlyRecord;
set(hFig,'CurrentAxes',hAx);
infoObj = getappdata(hFig,'infoObj');

% retrieves the image size
vRes = get(infoObj.objIMAQ,'VideoResolution');
sz = vRes([2 1]);

% retrieves the greatest common denominator
D = gcd(sz(1),sz(2));
N = ceil(min(20*D./sz))*(sz/D);

% calculates the marker locations
[Y,X] = deal(linspace(0,sz(1),N(1)),linspace(0,sz(2),N(2)));

% plots the y-grid lines
hold(hAx,'on');
for i = 2:(N(1)-1)
    plot(hAx,[0 sz(2)],Y(i)*[1 1],'r:','linewidth',1,'tag','hGrid');
end

% plots the x-grid lines
for i = 2:(N(2)-1)
    plot(hAx,X(i)*[1 1],[0 sz(1)],'r:','linewidth',1,'tag','hGrid');
end
hold(hAx,'off');

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- initialises the axes properties for the axes handle, hAx --- %
function initAxesProps(handles,objIMAQ,hAx)

% sets focus to the axis handle
set(handles.figFlyRecord,'CurrentAxes',hAx); 
set(hAx,'color',0.9*[1 1 1],'fontweight','bold')

% sets the axis/label fontsizes
if ispc
    axSize = 8;
else
    axSize = 10;    
end

% plot current stimulus
set(hAx,'color',0.9*[1 1 1],'fontweight','bold','fontsize',axSize)       

% determines if video object has been initialised
if ~isempty(objIMAQ)
    % if so, initialises the axis image object
    if isstruct(objIMAQ)
        vRes = getVideoResolution(objIMAQ);
        image(zeros(vRes([2 1])),hAx); 
    end

    % enables the start preview button
    set(handles.toggleVideoPreview,'value',0,'string','Start Video Preview')
else
    % if no valid video object, then disable the start preview button
    set(handles.toggleVideoPreview,'value',1,'string','Stop Video Preview')
end

% clears the axis
axis off
colormap(hAx,gray)
caxis([0 255])

% --- retrieves the video ROI position
function rPos = getVideoROIPosition(infoObj)

if infoObj.isTest
    % video object is the test file
    rPos = [1,1,flip(infoObj.objIMAQ.szImg)];
else
    % video object is the image acquisition object
    rPos = get(infoObj.objIMAQ,'ROIPosition');
end


