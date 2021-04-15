function varargout = FlyRecord(varargin)
% Last Modified by GUIDE v2.5 15-Apr-2021 13:22:55

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

% --------------------------------------------------- %
% --- PARAMETERS & FIGURE POSITION INITIALISATION --- %
% --------------------------------------------------- %

% deletes any existing timer objects
hT = timerfindall();
if ~isempty(hT)
    deleteTimerObjects(hT);
end

% global variables
global defVal minISI isAddPath nFrmRT mainProgDir runTrack
[defVal,minISI,nFrmRT] = deal(5,60,150);
[isAddPath,runTrack] = deal(false);

% seeds the random number generator to the system clock
rSeed = sum(100*clock);
try
    RandStream.setGlobalStream(RandStream('mt19937ar','seed',rSeed));
catch
    RandStream.setDefaultStream(RandStream('mt19937ar','seed',rSeed));
end

% ----------------------------------------------------------- %
% --- FIELD INITIALISATIONS & DIRECTORY STRUCTURE SETTING --- %
% ----------------------------------------------------------- %

% sets the DART object handles, program directory and test flag
switch length(varargin)
    case (0) % case is running the full program from the command line
        [hDART,isTest,mainProgDir] = deal([],false,pwd);
        
    case (1) % case is running the test program from the command line
        [hDART,isTest,mainProgDir] = deal([],true,pwd); 
        
    case (2) % case is running the program from DART
        [hDART,isTest] = deal(varargin{1},varargin{2});           
        if ~isfield(hDART,'figDART')
            % displays an error message if DART handle not correct
            eStr = ['Error! Invalid DART program handle. ',...
                    'Exiting Recording GUI...'];
            tStr = 'Recording GUI Initialisation Error';
            waitfor(errordlg(eStr,tStr,'modal'))

            % deletes the GUI and exits the function
            delete(hObject)
            return          
        else
            % otherwise, make the DART GUI invisible
            setObjVisibility(hDART.figDART,'off')    
        end
    otherwise % case is any other number of input arguments
        % displays an error message
        eStr = ['Error! Incorrect number of input arguments. ',...
                'Exiting Recording GUI...'];
        waitfor(errordlg(eStr,'Recording GUI Initialisation Error','modal'))
        
        % deletes the GUI and exits the function
        delete(hObject)
        return        
end

% sets the program directory and the DART object handles
setappdata(hObject,'isTest',isTest)
setappdata(hObject,'hDART',hDART)
    
% initialises the other GUI functions
setappdata(hObject,'toggleVideoPreview',@toggleVideoPreview_Callback);
setappdata(hObject,'initExptStruct',@initExptStruct)

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
    iProg = getappdata(hDART.figDART,'ProgDefNew');
end

% sets the program data struct
setappdata(hObject,'iPara',iPara);
setappdata(hObject,'iProg',iProg);

% sets up the stimulus train parameter struct
iStim = initTotalStimParaStruct();

% ------------------------------------- %
% --- ADAPTOR OBJECT INITIALISATION --- %
% ------------------------------------- %

% initialises the experimental adaptors
[objIMAQ,objDACInfo0,exptType,iStim] = initExptAdaptors(handles,iStim,1);
if isempty(objIMAQ) && isempty(objDACInfo0) 
    
    % if the DART GUI exists, then make it visible again
    if ~isempty(hDART)
        setObjVisibility(hDART.figDART,'on')
    end        

    % if the user cancelled (or there was an error) then exit program
    delete(hObject)
    return
else
    % if running the test through DART, then load the test image stack 
    % (in External Files) and set that as the image acquisition object
    if isTest
        a = load('TestStack');
        objIMAQ = a.I;
    end
end    

% creates the load bar
h = ProgressLoadbar('Initialising Recording GUI...');

% sets the data structs into the GUI
setappdata(hObject,'exptType',exptType)
setappdata(hObject,'objIMAQ',objIMAQ);
setappdata(hObject,'objDACInfo0',objDACInfo0);
setappdata(hObject,'objDACInfo',reduceDevInfo(objDACInfo0,isTest));
setappdata(hObject,'iStim',iStim);
setappdata(hObject,'sTrain',[]);
setappdata(hObject,'iMov',[]);
setappdata(hObject,'isRot',false);

% runs the external packages
runExternPackage(handles,'RTTrack');

% ------------------------------------------ %
% --- GUI OBJECT PROPERTY INITIALISATION --- %
% ------------------------------------------ %

% updates the DAC adaptor name strings
iExpt = initExptStruct(exptType,objIMAQ);
setappdata(hObject,'iExpt',iExpt);

% initialises the GUI properties
handles = setRecordGUIProps(handles,'InitGUI',exptType);
    
% ------------------------------------- %
% --- FINAL HOUSE-KEEPING EXERCISES --- %
% ------------------------------------- %

% creates the video preview object
prObj = VideoPreview(hObject,true);
setappdata(hObject,'prObj',prObj);

% sets the GUI properties based on whether testing or not
if isTest
    % initialises using test GUI setup
    setRecordGUIProps(handles,'InitGUITestOnly');    
    
    % runs the loop video
    if ~isempty(hDART)
        set(handles.toggleVideoPreview,'value',1)
        toggleVideoPreview_Callback(handles.toggleVideoPreview,'1',handles);
    end
else
    % initialises using full GUI setup
    setRecordGUIProps(handles,'InitGUIFullOnly');
    
    % turns on the camera for preview
    set(handles.toggleVideoPreview,'value',1)
    toggleVideoPreview_Callback(handles.toggleVideoPreview,1,handles);    
end

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
setObjVisibility(hFig,'off'); pause(0.05);

% retrieves the stimulus parameter struct 
onIR = false;
isTest = getappdata(hFig,'isTest');
iStimNw = initTotalStimParaStruct();

% retrieves the current camera parameters
if ~isTest
    % retrieves the camera source object
    objIMAQ = getappdata(hFig,'objIMAQ');
    srcObj = getselectedsource(objIMAQ);

    % retrieves the camera field names and property values
    [~,fldNames] = combineDataStruct(propinfo(srcObj));
    pVal0 = get(srcObj,fldNames);
    
    % if the IR lights are on, then turn them off
    onIR = strcmp(get(handles.menuToggleIR,'Checked'),'on');
    if onIR
        menuToggleIR_Callback(handles.menuToggleIR, '1', handles)    
    end
end

% initialises the experimental adaptors
[objIMAQNw,objDACInfo0,exptType,iStim] = ...
                    initExptAdaptors(handles,iStimNw,false);
if isempty(exptType)
    if onIR
        menuToggleIR_Callback(handles.menuToggleIR, '1', handles)    
    end    
    
    setObjVisibility(hFig,'on')
    return
else
    % sets the data structs into the GUI
    if isTest
        propStr = 'InitGUITestOnly';        
        objIMAQNw = getappdata(hFig,'objIMAQ');
    else
        propStr = 'InitGUIFullOnly';
        setappdata(hFig,'objIMAQ',objIMAQNw);
    end      
        
    % updates the stimuli data struct and expt type
    setappdata(hFig,'iMov',[]);
    setappdata(hFig,'iStim',iStim);
    setappdata(hFig,'exptType',exptType)
    setappdata(hFig,'objDACInfo',objDACInfo0);
    setappdata(hObject,'objDACInfo',reduceDevInfo(objDACInfo0,isTest));
    
    % resets the real-time tracking parameters
    rtObj = getappdata(hFig,'rtObj');
    if ~isempty(rtObj)
        rtObj.initTrackPara();
    end
    
    % initialises the video timer object
    initVideoTimer(handles)    
end    

% ------------------------------------------ %
% --- GUI OBJECT PROPERTY INITIALISATION --- %
% ------------------------------------------ %

% initialises the experiment struct
iExpt = initExptStruct(iStim,objIMAQNw,exptType);
setappdata(hFig,'iExpt',iExpt);

% sets the GUI properties based on whether testing or not
setRecordGUIProps(handles,'InitGUI',exptType);
setRecordGUIProps(handles,propStr)

% if there is no change in the camera type, then reset the camera to the
% original parameters (full program only)
if (~isTest)
    srcObjNw = getselectedsource(objIMAQNw);
    [srcInfoNw,fldNamesNw] = combineDataStruct(propinfo(srcObjNw));
    if (isequal(fldNamesNw,fldNames))
        % only updates the non read-only fields
        for i = 1:length(fldNamesNw)
            if (~strcmp(srcInfoNw(i).ReadOnly,'always'))
                switch (fldNames{i})
                    case ('FrameRate')
                        set(srcObjNw,fldNames{i},srcObjNw.FrameRate)
                    otherwise
                        set(srcObjNw,fldNames{i},pVal0{i})
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

% runs the program preference sub-GUI
iProg = getappdata(handles.figFlyRecord,'iProg');
[iProgNw,isSave] = ProgParaRecord(handles.figFlyRecord,iProg);

% updates the data struct (based on the program preference)
if (isSave)
    setappdata(handles.figFlyRecord,'iProg',iProgNw);
end

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

% global variables
global mainProgDir

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

    % removes the adaptor object handles (full program mode only)
    if ~getappdata(handles.figFlyRecord,'isTest')
        % deletes any previous DAC objects in memory
        try
            daqObj = daqfind;
            if (~isempty(daqObj))
                delete(daqObj)
            end
        end

        % deletes any previous imaq objects in memory
        try
            imaqObj = imaqfind;
            if (~isempty(imaqObj))
                delete(imaqObj)
            end
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

    % retrieves the stimulus train sub-GUI figure handle
    hStimFig = findobj(0,'tag','figShowTrain');
    if (~isempty(hStimFig))
        % if the sub-GUI is open, then delete it
        delete(hStimFig)
    end

    % retrieves the video parameter sub-GUI figure handle
    hVidPara = findall(0,'tag','figVideoPara');
    if (~isempty(hVidPara))
        % if the sub-GUI is open, then delete it
        delete(hVidPara)
    end

    % deletes the imageseg and exits the program        
    delete(handles.figFlyRecord)                
    if (isempty(hDART))            
        % removes the loaded directories from the directory path
        wState = warning('off','all');
        updateSubDirectories(fullfile(mainProgDir,'GUI Code'),'remove') 
        updateSubDirectories(fullfile(mainProgDir,'Other Code'),'remove') 
        updateSubDirectories(fullfile(mainProgDir,'Para Files'),'remove') 
        warning(wState);
    else
        % otherwise, make the main DART GUI visible again
        setObjVisibility(hDART,'on');
    end
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
iProg = getappdata(handles.figFlyRecord,'iProg');
objIMAQ = getappdata(handles.figFlyRecord,'objIMAQ');

% prompts the user for the movie parameters
vPara = TestMovie(objIMAQ,iProg); 
if (~isempty(vPara))
    % retrieves the video recording object
    pause(0.05);    
        
    % sets up and runs the test video recording
    exObj = RunExptObj(handles.figFlyRecord,'Test',vPara);    
    
    % initialises the time start
    [tStart,Tp] = deal(tic,3); 
    wStr = 'Waiting For Test Video Recording To Start';
    wFunc = getappdata(exObj.hProg,'updateBar'); pause(0.05);

    % pauses the program until the wait-period has passed
    while (1)
        tNew = toc(tStart);
        if (tNew > Tp)
            break
        else
            % updates the waitbar figure
            tRem = Tp - tNew;
            if (wFunc(1,sprintf('%s (%i Seconds Remains)',...
                            wStr,ceil(tRem)),1-tRem/Tp,exObj.hProg))
                % if the user cancelled, then exit
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

% ----------------------------- %
% --- EXPERIMENT MENU ITEMS --- %
% ----------------------------- %

% -------------------------------------------------------------------------
function menuSetupExpt_Callback(hObject, eventdata, handles)

% retrieves the test flag
hFig = handles.figFlyRecord;
isTest = getappdata(hFig,'isTest');

% disables the file menu items
setObjEnable(handles.menuFile,'off')
setObjEnable(handles.menuExpt,'off')
setObjEnable(handles.menuOpto,'off')
% setObjEnable(handles.menuRTTrack,'off')

% otherwise, run the full stimuli experimental protocol GUI
ExptSetup(handles.figFlyRecord,isTest);   

% ------------------------------ %
% --- CALIBRATION MENU ITEMS --- %
% ------------------------------ %

% -------------------------------------------------------------------------
function menuCalibrateVideo_Callback(hObject, eventdata, handles)

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

% ------------------------------ %
% --- CALIBRATION MENU ITEMS --- %
% ------------------------------ %

% -------------------------------------------------------------------------
function menuCalibTrack_Callback(hObject, eventdata, handles)

% retrieves the full DART program default struct directory
ProgDefFull = getappdata(findall(0,'tag','figDART'),'ProgDef');
setappdata(handles.figFlyRecord,'ProgDefNew',ProgDefFull.Tracking)

% runs the fly tracker in full calibration mode
FlyTrack(handles,1);

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ------------------------------------------ %
% --- CAMERA VIDEO PREVIEW PANEL OBJECTS --- %
% ------------------------------------------ %

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

% global variables
global mainProgDir

% sets the program default file name
progFileDir = fullfile(mainProgDir,'Para Files');
progFile = fullfile(progFileDir,'ProgDef.mat');

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
            ProgDef = ProgParaRecord(handles.figFlyRecord,[],1);
        case ('Automatically')
            % user chose to setup automatically then create the directories            
            ProgDef = setupAutoDir(mainProgDir,progFile);
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
if (any(~isExist))
    % runs the program default sub-ImageSeg
    if (nargin == 1)
        ProgDef = ProgParaRecord(handles.figFlyRecord,ProgDef,1);
    end
end

% --- function that automatically sets up the default directories --- %
function ProgDef = setupAutoDir(progDir,progFile)

% otherwise, create the
baseDir = fullfile(progDir,'Data Files');

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
set(handles.figFlyRecord,'CurrentAxes',hAx);
objIMAQ = getappdata(handles.figFlyRecord,'objIMAQ');

% retrieves the image size
vRes = get(objIMAQ,'VideoResolution');
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
% --- VIDEO PREVIEW FUNCTIONS --- %
% ------------------------------- %

% --- starts the video preview
function startVideoPreview(handles, eventdata)

% global variables
global isRot

% finish me!
isRecordGUI = true;

% object handles
hFig = handles.figFlyRecord;
hAx = handles.axesPreview;

% retrieves the parameter struct
iMov = getappdata(hFig,'iMov');
isRot = getappdata(hFig,'isRot');
isTest = getappdata(hFig,'isTest');
objIMAQ = getappdata(hFig,'objIMAQ');

% resets the start/stop preview button enabled properties
set(handles.toggleVideoPreview,'string','Stop Video Preview');
setObjEnable(handles.toggleStartTracking,'off')

% % enables the real-time tracking menu item (if it exists)
% if isfield(handles,'menuRTTrack')
%     if strcmp(get(handles.menuRTTrack,'visible'),'on')
%         setObjEnable(handles.menuRTTrack,'off')
%         setObjEnable(handles.toggleStartTracking,'off')    
%     end
% end

% initialises the ui context menu for the video axis (if not set)
if isRecordGUI
    if isempty(get(handles.panelVidPreview,'UIContextMenu'))
        set(0,'CurrentFigure',hFig)
        c = uicontextmenu();    
        set(handles.panelVidPreview,'UIContextMenu',c);
        uimenu(c,'Label','Display Gridlines','tag','menuShowGrid',...
                 'Callback',@showGridLines,'checked','off');
    end
end

% starts the video preview
if isTest
    % retrieves the video timer object
    vidTimer = getappdata(hFig,'vidTimer');
    
    % adds the fly markers, and starts the tracking
    tic; 
    if strcmp(get(vidTimer,'Running'),'off')
        start(vidTimer); pause(0.01)    
    end
else   
    % resets the image axis      
    vRes = get(objIMAQ,'VideoResolution');    
    if isRot
        hImage = image(0.81*ones(vRes),'Parent',hAx);           
        [xL,yL] = deal([1 vRes(1)]+0.5,[1 vRes(2)]+0.5);        
    else
        hImage = image(0.81*ones(vRes([2 1])),'Parent',hAx);        
        [xL,yL] = deal([1 vRes(2)]+0.5,[1 vRes(1)]+0.5);
    end        
       
    % sets the image object    
    setappdata(hImage,'UpdatePreviewWindowFcn',@mypreview_fcn);
    set(hAx,'xtick',[],'ytick',[],'xticklabel',[],'yticklabel',[],...
            'xLim',xL,'yLim',yL) 
    pause(0.05);
    axis(hAx,'image');    
    pause(0.05);    
    
    try
        % starts the video preview        
        preview(objIMAQ,hImage)                    
    catch
        % an error occured while starting the preview, so close the loadbar 
        % and output an error function. exit the function after
        eStr = [{'Error! Unable to start the camera preview.'};...
                {'Suggest changing the camera USB-Port and restart Matlab'}];
        waitfor(errordlg(eStr,'Video Preview Initialisation Error','modal'))
        return
    end
end    

% --- stops the video preview
function stopVideoPreview(handles)

% global variables
global runTrack

% finish me!
isRecordGUI = true;

% object handles
hFig = handles.figFlyRecord;
hAx = handles.axesPreview;

% retrieves the parameter struct
isTest = getappdata(hFig,'isTest');
isRot = getappdata(hFig,'isRot');
objIMAQ = getappdata(hFig,'objIMAQ');
iMov = getappdata(hFig,'iMov');
iStim = getappdata(hFig,'iStim');
exptType = getappdata(hFig,'exptType');

% resets the start/stop preview button enabled properties
% setObjEnable(handles.menuFile,'on')
% setObjEnable(handles.menuAdaptors,'on')
set(handles.panelVidPreview,'UIContextMenu',[]);
set(handles.toggleVideoPreview,'string','Start Video Preview');

% % enables the real-time tracking menu item (if it exists)
% if isfield(handles,'menuRTTrack')
%     setObjEnable(handles.menuRTTrack,'on')
% end

% retrieves the show menu panel item
hMenu = findall(hFig,'tag','menuShowGrid');
if strcmp(get(hMenu,'checked'),'on'); showGridLines(hMenu,'1'); end
if ~isempty(hMenu); delete(hMenu); end

% stops the video preview
if isTest
    % retrieves the video timer object
    vidTimer = getappdata(hFig,'vidTimer');
    stop(vidTimer); pause(0.01)        
    
    % clears the preview axis
    cla(hAx)
    axis(hAx,'off')
else
    % stops the video preview
    stoppreview(objIMAQ)
    
    % resets the preview axes image to black
    vRes = get(objIMAQ,'VideoResolution');
    if isRot
        Img = zeros(vRes);
    else
        Img = zeros(vRes([2 1]));
    end
    
    set(findobj(hAx,'Type','Image'),'cData',Img);
end

% sets the experimental protocol menu item enabled properties
switch exptType 
    case ('RecordStim') % case is recording + stimulus                        
        % updates the experiment menu items
        if ~isempty(iMov)
            % if running the real-time tracking, then stop it
            if runTrack               
                hTrack = handles.toggleStartTracking;
                toggleStartTracking_Callback(hTrack,[],handles)
            end         
        end
end

% enables the real-time tracking (if background image is set)
if ~isempty(iMov)
    if ~isempty(iMov.Ibg)
        setObjEnable(handles.toggleStartTracking,'on')
    end
end

function mypreview_fcn(obj, event, himage)

% global variables
global isRot

if isRot
    set(himage, 'cdata', event.Data');
else
    set(himage, 'cdata', event.Data);
end

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
        vRes = get(objIMAQ,'VideoResolution');
        imagesc(ones(vRes([2 1]))); 
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

% --- sets the parameter limits/flags based on the parameter type
function [nwLim,isInt] = getParaLim(pStr,subPara,pStrSub)

% sets the integer flag/parameter limits based on the parameter type
switch (pStr)    
    case ('pCount') % case is the pulse count
        [isInt,nwLim] = deal(1,[1 500000]);        
    case ('pDur') % case is the pulse duration
        [isInt,nwLim] = deal(0,[0.001 10000.00]);        
    case ('pAmp') % case is the pulse amplitude
        [isInt,nwLim] = deal(0,[0 1]);
    case ('iDelay') % case is the initial delay
        [isInt,nwLim] = deal(0,[0.0 10000.00]);                
    case ('pDelay') % case is the pulse delay
        [isInt,nwLim] = deal(0,[0.00 10000.00]);        
    case ('sDelay') % case is the stimulus delay
        [isInt,nwLim] = deal(0,[0.00 10000.00]);        
end

% sets the lower/upper limits for the range parameters
if (nargin > 1)
    switch (pStrSub)            
        case ('pMin') % case is the min range value
            nwLim(2) = subPara.pMax;
        case ('pMax') % case is the max range value
            nwLim(1) = subPara.pMin;
    end
end    
    
% --- compares the current DAC objects (in objDACInfo) to that
%     given in the stimulus struct, iStim
function [iStim, isUpdate] = compareDACProps(handles,iStim)

% loads the DAC object handles and initialises the updae flag
objDACInfo = getappdata(handles.figFlyRecord,'objDACInfo');
[isUpdate,eStr] = deal(true,[]);

% check to see if the loaded and playlist items match
if iStim.nDACObj == 0
    setappdata(handles.figFlyRecord,'objDACInfo',[]);
    return
elseif isempty(objDACInfo)
    % deletes any existing serial objects
    hh = instrfind;
    if ~isempty(hh); delete(hh); end
    
    % devices are required, but no DAC devices have been set
    isUpdate = true;
    [~,objDACInfo] = AdaptorInfo(handles.figFlyRecord,iStim);
    if isempty(objDACInfo)
        % if the user canceled, then set the flag to false
        isUpdate = false;
    else
        % sets the DAC channel IDs and string names
        iStim = setChannelID(objDACInfo,iStim);
        iStim.strDAC = getDACNames(iStim,objDACInfo);
        
        % otherwise, updates the DAC data struct
        setappdata(handles.figFlyRecord,'objDACInfo',objDACInfo);
    end    
    
    return
else
    % initialises the error string
    dacChannel = objDACInfo.nChannel;
    if length(dacChannel) ~= iStim.nDACObj
        % if the loaded objects do not match then set the error string
        eStr1 = 'Number of Loaded DAC Objects Does Not Match PlayList File.';   
        eStr2 = sprintf('Number Of Playlist DAC Objects = %i',iStim.nDACObj);
        eStr3 = sprintf('Number Of Loaded DAC Objects = %i',length(dacChannel));    

        % sets the total error string
        eStr = sprintf('%s\n\n%s\n%s\n',eStr1,eStr2,eStr3);
    elseif any(dacChannel(1:iStim.nDACObj) < iStim.nChannel)
        % if the number of channels do not match then set the error string    
        eStr1 = 'Number of DAC Channels Does Not Match PlayList File.';
        eStr2 = '';
    
        % sets the channel disparities for each of the objects
        for i = 1:iStim.nDACObj
            if (iStim.nChannel(i) ~= dacChannel(i)) 
                eStr2 = sprintf(['%s\nPlaylist DAC #%i Channel Count ',...
                                        '= %i\n'],eStr2,i,iStim.nChannel(i));
                eStr2 = sprintf(['%sLoaded DAC #%i Channel Count ',...
                                        '= %i\n'],eStr2,i,dacChannel(i));                                
            end
        end

        % sets the total error string
        eStr = sprintf('%s\n%s',eStr1,eStr2);
    end
end
    
% if there was a discrepancy between the loaded and current DAC
% objects, then reset the DAC devices
if ~isempty(eStr)
    % sets the error strings for the number of loaded DAC objects
    eStrB = 'Do you wish to reset the DAC device properties?';
    uChoice = questdlg(sprintf('%s\n%s',eStr,eStrB),'Reset DAC Devices?',...
                    'Yes','No','Yes');
    
    % prompts the user if they want to reset the DAC objects
    if (strcmp(uChoice,'Yes'))       
        if (iStim.nDACObj == 0)
            % otherwise, disable the panel
            setappdata(handles.figFlyRecord,'objDACInfo',[]);
        else        
            % prompts the user for the new DAC objects
            [~,objDACInfo] = AdaptorInfo(handles.figFlyRecord,iStim);
            if (isempty(objDACInfo))
                % if the user canceled, then set the flag to false
                isUpdate = false;
                return
            else
                % sets the DAC channel IDs and string names
                iStim = setChannelID(objDACInfo,iStim);
                iStim.strDAC = getDACNames(iStim,objDACInfo); 
                
                % otherwise, updates the DAC data struct
                setappdata(handles.figFlyRecord,'objDACInfo',objDACInfo);
            end
        end           
    else
        % if the user canceled, then set the flag to false
        isUpdate = false;        
    end
end

% --- checks the fixed timing elements of the fixed protocol 
function iExpt = checkExptTiming(iExpt)

% retrieves the temporary data struct
Temp = iExpt.Temp;
if (isempty(Temp))
    % if the temporary struct is empty, then exit
    return
else
    % otherwise, read the current time
    cTime = clock;
end

% determines the fixed time elements
isFixTime = find(~cellfun(@isempty,field2cell(Temp,'Tfix')));

% if there are fixed time elements within the experimental protocol, then
% prompt the user if they want to shift the time to the next feasible
if (~isempty(isFixTime))
    % provides a warning to the user
    wStr = [{'The experimental protocol file contains fixed timed stimuli.'};...
            {'The fixed time events have been moved to the next feasible day.'}];
    waitfor(warndlg(wStr,'Fixed Timed Stimuli Warning','modal'))
    
    % loops through all the fixed timed elements setting the next feasible
    % day
    for i = reshape(isFixTime,1,length(isFixTime))
        % sets the fixed time elements and determines the time at which the
        % first 
        TfixNw = Temp(i).Tfix;
        Tstim0 = datevec(combineString(TfixNw(1,:)),'mmmm-dd-HH-MM-AM');
        
        %
        while (1)
            % calculates the time difference between the initial stimulus
            % time and the current time
            [~,dT,~] = calcTimeDifference(Tstim0,cTime);            
            if (dT < 0)
                % if the time difference is negative, then add a day to the
                % time
                Tstim0 = datevec(addtodate(datenum(Tstim0),1,'day'));                
            else
                % otherwise, exit the loop
                break
            end            
        end
        
        % sets the new day/month strings
        nwStr = splitString(datestr(Tstim0,'mmmm dd'));
        [TfixNw(:,1),TfixNw(:,2)] = deal(nwStr(1),nwStr(2));
        
        % updates the fixed time element array
        Temp(i).Tfix = TfixNw;
    end
end

% resets the temporary data struct into the data struct
iExpt.Temp = Temp;

% --- back formats the experimental data struct
function iExpt = backFormatExptStruct(iExpt)

% determines if the experimental data struct has the old frame format
if (isfield(iExpt.Video,'Lmax'))
    % if so, then convert the frame count to the duration
    tVec = sec2vec(floor(iExpt.Video.Lmax/iExpt.Video.FPS));
    if (sum(tVec) == 0)
        iExpt.Video.Dmax = [1 0 0];    
    else
        iExpt.Video.Dmax = tVec(2:end);    
    end
    
    % removes the frame count fields
    iExpt.Video = rmfield(iExpt.Video,{'Lmax','nFix'});
end
