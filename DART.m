function varargout = DART(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DART_OpeningFcn, ...
                   'gui_OutputFcn',  @DART_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    wState = warning('off','all');
    try gui_State.gui_Callback = str2func(varargin{1}); end
    warning(wState);
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    try
        gui_mainfcn(gui_State, varargin{:});
    catch ME
        if strcmp(ME.message,'Session Already Running')
            set(findall(0,'tag','figDART'),'visible','off')            
        else
            rethrow(ME)
        end
    end        
end
% End initialization code - DO NOT EDIT

% --- Executes just before menuDART is made visible.
function DART_OpeningFcn(hObject, ~, handles, varargin)

% Choose default command line output for menuDART
handles.output = hObject;
setappdata(hObject,'isTest',~isempty(varargin))

% initialises the program paths and GUI objects
tic;
set(0,'units','pixels')
setappdata(hObject,'hTrack',[])
setappdata(hObject,'isInit',true)
setappdata(hObject,'dirUpdateFcn',@updateSubDirectories)

% initialises the GUI objects
if ~initGUIObjects(handles)
    % if there was an error, then exit
    try; delete(hObject); end
    return        
end

% global variables
global tDay hDay scrSz H0T HWT W0T HWL mainProgDir

% global variables
mainProgDir = pwd;
scrSz = getPanelPosPix(0,'Pixels','ScreenSize');

% loads the global analysis parameters from the program parameter file
A = load(getParaFileName('ProgPara.mat'));
[tDay,hDay] = deal(A.gPara.Tgrp0,A.gPara.TdayC);

% Update handles structure
try
    guidata(hObject, handles);
catch ME        
    eStrComp = 'H must be the handle to a figure or figure descendent.';
    if strcmp(ME.message,eStrComp)
        % user is automatically updating program so exit
        return
    else
        % otherwise, output error to screen
        eStr = ['Critical error! Unable to open DART program ',...
                'interface. Quitting...'];
        waitfor(errordlg(eStr))
        return
    end
end

% sets the temporary table data object
Data = get(handles.tableDummy,'Data');
Data(:) = {'Temp Data'};
set(handles.tableDummy,'Data',Data)

% updates the figure
drawnow; pause(0.05);

% keep trying to determine the object dimensions until they are found
while true
    try
        % attempts to retrieve the object dimensions
        [H0T,HWT,W0T] = getTableDimensions(findjobj(handles.tableDummy));
        HWL = getListDimensions(findjobj(handles.listDummy));
        
        % exits the loop
        break
    catch
        % if it failed then pause and then retry 
        pause(1);
    end
end

% retrieves the table cell heights
centreFigPosition(hObject);

% UIWAIT makes menuDART wait for user response (see UIRESUME)
% uiwait(handles.figDART);

% --- Outputs from this function are returned to the command line.
function varargout = DART_OutputFcn(~, ~, ~) 

% Get default command line output from handles structure
varargout{1} = [];

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% ------------------------------ %
% --- PROGRAM I/O MENU ITEMS --- %
% ------------------------------ %

% -------------------------------------------------------------------------
function menuUpdateProg_Callback(~, eventdata, handles)

% global variables
global isFull isAnalyDir 
[isFull,isAnalyDir] = deal(false);

% sets the full program default struct into the menuDART GUI
ProgDef = getappdata(handles.figDART,'ProgDef');

% sets the zip file name
if ~isa(eventdata,'char')
    % prompts the user if they really want to update the program
    uChoice = questdlg('Are you sure you want to update the program?',...
                       'Update DART Program','Yes','No','Yes');
    if ~strcmp(uChoice,'Yes')
        % if not, then exit the function
        return
    end
    
    % sets the default search directory
    if isfield(ProgDef,'DART')
        if exist(ProgDef.DART.DirVer,'dir')
            dDir = ProgDef.DART.DirVer;
        else
            dDir = pwd;
        end
    else
        dDir = pwd;
    end

    % prompts the user for the program update .zip file 
    [zName,zDir,zIndex] = uigetfile({'*.zip;','Zip File (*.zip)'},...
                                    'Select Program Zip File',dDir);
    if zIndex == 0
        % if the user cancelled, then exit the function
        return
    else
        % otherwise, sets the zip file name
        zFile = fullfile(zDir,zName);
    end
else
    % otherwise, set the zip file name
    zFile = eventdata;
end
    
% otherwise, set up the temporary directory string name
tmpDir = getProgFileNameDART('Temp Files');
    
% initialises the loadbar
h = ProgressLoadbar('Unzipping Program Files...');
set(h.Control,'CloseRequestFcn',[]);

% memory allocation
progDir = getProgFileNameDART();
sName = {'Analysis','Common','Combine','Recording','Tracking'};
[fileDir,sDir] = deal(tmpDir,cell(length(sName),1));

% unzips the file to the temporary directory
unzip(zFile, tmpDir);

% if the Mac temporary directory is in the zip file, then remove it from
% the files that need to be copied over
if exist(fullfile(tmpDir,'_MSCOSX'),'file')
    rmvAllFiles(fullfile(tmpDir,'_MSCOSX'));
end

% ------------------------------------ %
% --- PROGRAM FILE DIRECTORY SETUP --- %
% ------------------------------------ %

% turns off all warnings
wState = warning('off','all');

% copies over all the files from each program directory
for i = 1:length(sName)
    % updates the loadbar
    h.StatusMessage = sprintf('Updating Directory "%s"...',sName{i});
    
    % makes the sub-directory for the code
    sDir{i} = fullfile(progDir,'Code',sName{i});    
    
    % copies the main directory files to the current folder
    copyAllFiles(fullfile(tmpDir,sName{i}),sDir{i});
end

% copies the main directory files to the current folder
copyAllFiles(fullfile(fileDir,'DART Main'),progDir);

% copies the analysis function to the designated
[funcDir,isAnalyDir] = deal(fullfile(tmpDir,'Analysis Functions'),true);
if exist(funcDir,'dir')
    copyAllFiles(funcDir,ProgDef.Analysis.DirFunc);
end

% resets the analysis directory flag
isAnalyDir = false;

% reverts warnings back to their original state
warning(wState);

% ------------------------------- %
% --- HOUSE-KEEPING EXERCISES --- %
% ------------------------------- %

% updates the loadbar figure
h.StatusMessage = 'Removing Temporary Files...'; 

% updates the log-file
updateLogFile(zFile);

% removes all the temporary files/directories
rmvAllFiles(tmpDir);

% updates the status message
[h.Indeterminate,h.FractionComplete] = deal(false,1);
h.StatusMessage = 'Finished Creating Executable'; pause(0.2); 
try; delete(h); end

% closes the GUI after prompting the user to restart the program
mStr = 'You will need to restart DART for the changes to take effect.';
waitfor(msgbox(mStr,'DART Update Successful','modal'))
buttonExitButton_Callback([], [], handles)

% -------------------------------------------------------------------------
function menuExeUpdate_Callback(~, ~, handles)

% runs the executable update GUI
ExeUpdate(handles.figDART)

% -------------------------------------------------------------------------
function menuOutputProg_Callback(~, ~, handles)

% global variables
global isFull

% sets the full program default struct into the menuDART GUI
ProgDef = getappdata(handles.figDART,'ProgDef');

% sets the default search directory
if isfield(ProgDef,'DART')
    if exist(ProgDef.DART.DirVer,'dir')
        dDir = ProgDef.DART.DirVer;
    else
        dDir = pwd;
    end
else
    dDir = pwd;
end

% sets the default file name
dName = sprintf('DART (%s).zip',datestr(clock,'yyyy_mm_dd'));
dFile = fullfile(dDir,dName);

% prompts the user for the program update .zip file 
[zName,zDir,zIndex] = uiputfile({'*.zip;','Zip File (*.zip)'},...
                                'Select Program Zip File',dFile);
if zIndex == 0
    % if the user cancelled, then exit the function
    return
end

% sets up the temporary file directory
tmpDir = getProgFileNameDART('Temp Files');
zFile = fullfile(zDir,zName);
mkdir(tmpDir)

% sets whether the full file is being output
qStr = 'Do you want to output the A) full code or B) partial code';
uChoice = questdlg(qStr,'Program Output Type','Full','Partial','Full');
isFull = strcmp(uChoice,'Full');

% creates the loadbar figure
wState = warning('off','all');
h = ProgressLoadbar('Initialising...');
set(h.Control,'CloseRequestFcn',[]);

% sets the file directory names
sName = {'DART Main','Analysis','Common','Combine','Recording','Tracking'}';
if isFull
    sName = [sName;{'External Files','Para Files','Analysis Functions'}'];
else
    sName = [sName;{'Analysis Functions'}];
end

% prepares the directories for outputting the data
nwDir = cell(length(sName),1);
for i = 1:length(sName)
    % updates the loadbar
    wStr = sprintf('Creating Temporary Code Directories (%s)',sName{i});
    h.StatusMessage = wStr;    
    
    % sets the new temporary directory to copy 
    nwDir{i} = fullfile(tmpDir,sName{i}); mkdir(nwDir{i});
    
    % copies over the directories     
    switch sName{i}
        case ('DART Main') 
            % case is the main DART directory
            copyAllFiles(getProgFileNameDART(),nwDir{i},1);            

        case {'External Files','Para Files'} 
            % case is the external/parameter files            
            copyAllFiles(getProgFileNameDART(sName{i}),nwDir{i});                        

        case ('Analysis Functions')
            % case is the analysis functions
            copyAllFiles(ProgDef.Analysis.DirFunc,nwDir{i});                                    

        otherwise
            % case is the other code directories
            copyAllFiles(getProgFileNameDART('Code',sName{i}),nwDir{i});            
    end
end

% saves the zip file
h.StatusMessage = 'Saving Zip File...';
zip(zFile,nwDir);

% updates the log-file
updateLogFile(zFile);

% removes the temporary directory
h.StatusMessage = 'Removing Temporary Directories...';
rmvAllFiles(tmpDir);

% updates the status message
[h.Indeterminate,h.FractionComplete] = deal(false,1);
h.StatusMessage = 'Update File Creation Complete!'; pause(0.2); 

% turns on all the warnings again
try; delete(h); end
warning(wState);

% -------------------------------------------------------------------------
function menuDeployExe_Callback(~, ~, handles)

% prompts the user to set the output directory
dDir = getProgFileNameDART();
outDir = uigetdir(dDir,'Set The Executable Output Directory');
if outDir ~= 0
    % runs the executable creation code
    hFig = handles.figDART;
    ProgDef = getappdata(hFig,'ProgDef');    
    createDARTExecutable(dDir,outDir,ProgDef)
end

% -------------------------------------------------------------------------
function menuSetupProg_Callback(~, ~, ~)

% prompts the user if they really want to update the program
qStr = 'Are you sure you want to setup a new version of DART?';
uChoice = questdlg(qStr,'Setup New DART Version','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if not, then exit the function
    return
else
    if ~setupDARTProgram()
        eStr = 'New DART setup was unsuccessful';
        waitfor(errordlg(eStr,'Unsuccessful DART Setup','modal'));
    end
end

% -------------------------------------------------------------------------
function menuAddPackage_Callback(~, ~, ~)

% prompts the user for the external package
[fName,fDir,fIndex] = uigetfile({'*.dpkg','DART Package (*.dpkg)'},...
                                 'Select DART Package',pwd);
if fIndex == 0
    % if the user cancelled, then exit
    return
end

% ensures the external apps folder exists (create and add if not)
fDirExApp = getProgFileNameDART('Code','External Apps');
if ~exist(fDirExApp,'dir')
    mkdir(fDirExApp);
    pause(0.05);
    addpath(fDirExApp);    
end

% sets the output directory
fDirOut = fullfile(fDirExApp,getFileName(fName));
if ~exist(fDirOut,'dir')
    mkdir(fDirOut);
    pause(0.05);
    addpath(fDirOut);
end

% runs the package installer
runPackageInstaller(fullfile(fDir,fName),fDirOut);

% ------------------------------------- %
% --- OTHER MENU CALLBACK FUNCTIONS --- %
% ------------------------------------- %

% -------------------------------------------------------------------------
function menuConfigOther_Callback(~, ~, ~)

% runs the installation information GUI
InstallInfo();

% -------------------------------------------------------------------------
function menuConfigSerial_Callback(~, ~, handles)

% runs the diagnostic tool GUI
SerialConfig(handles.figDART);

% -------------------------------------------------------------------------
function menuProgPara_Callback(~, ~, handles)

% runs the program default GUI
ProgDefaultDef(handles.figDART,'DART');

% -------------------------------------------------------------------------
function menuAboutDART_Callback(~, ~, ~)

% runs the about DART GUI
AboutDARTClass();

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes on button press in buttonFlyRecord.
function buttonFlyRecord_Callback(hObject, ~, handles)

% sets the program defaults directories for the recording program
hFig = handles.figDART;
iStim0 = initTotalStimParaStruct();
setappdata(hFig,'ProgDefNew',get(hObject,'UserData'))

% runs the Adaptor Info gui 
wState = warning('off','all');
AdaptorInfo('hFigM',hFig,'iType',1,'iStim',iStim0);
warning(wState);

% --- Executes on button press in buttonFlyTrack.
function buttonFlyTrack_Callback(hObject, ~, handles)

% sets the new file path and adds it to the matlab path
setappdata(handles.figDART,'ProgDefNew',get(hObject,'UserData'))

% runs the Fly Tracking Program and re-updates the default directory struct
wState = warning('off','all');
setappdata(handles.figDART,'hTrack',FlyTrack(handles))
warning(wState)

% --- Executes on button press in buttonFlyCombine.
function buttonFlyCombine_Callback(hObject, ~, handles)

% sets the new file path and adds it to the matlab path
setappdata(handles.figDART,'ProgDefNew',get(hObject,'UserData'))

% runs the Fly Analysis Program and re-updates the default directory struct
wState = warning('off','all');
FlyCombine(handles)
warning(wState);

% --- Executes on button press in buttonFlyAnalysis.
function buttonFlyAnalysis_Callback(hObject, ~, handles)

% sets the new file path and adds it to the matlab path
setappdata(handles.figDART,'ProgDefNew',get(hObject,'UserData'))

% turns off all rendering warnings
warning('off','MATLAB:hg:uicontrol:ParameterValuesMustBeValid')

% runs the Fly Analysis Program and re-updates the default directory struct
wState = warning('off','all');
FlyAnalysis(handles)
warning(wState);

% --- Executes on button press in buttonExitButton.
function buttonExitButton_Callback(~, ~, handles)

% turns off all warnings
wState = warning('off','all');

% adds in the program directories
if ~isdeployed            
    % creates a loadbar figure
    h = ProgressLoadbar('Closing Down DART Program...');  
    pbDir = fileparts(which('ProgressDialog'));    
    
    % removes the main code directories
    rmpath(getProgFileNameDART())
    updateSubDirectories(getProgFileNameDART('Code'),'remove')
    updateSubDirectories(getProgFileNameDART('Git'),'remove')
    updateSubDirectories(getProgFileNameDART('External Files'),'remove')
    updateSubDirectories(getProgFileNameDART('Para Files'),'remove')
    
    % removes the xlwrite java files to the path
    cDir = getProgFileNameDART('Code','Common');
    jDirXL = fullfile(cDir,'File Exchange','xlwrite','poi_library');
    if exist(jDirXL,'dir')
        try
            jFiles = dir(fullfile(jDirXL,'*.jar'));
            jFile = arrayfun(@(x)(fullfile(jDirXL,x.name)),jFiles,'un',0);
            cellfun(@(x)(javarmpath(x)),jFile);
        end
    end
    
    % removes the heap java files to the path
    jDirHC = fullfile(cDir,'File Exchange','jheapcl');
    if exist(jDirHC,'dir')
        try; javarmpath(jDirHC); end
    end      
    
%     % removes the conditional check table java files to the path
%     jDirCCT = fullfile(cDir,'Utilities','CondCheckTable.zip');
%     if exist(jDirCCT,'file')
%         try; javarmpath(jDirCCT); end
%     end          
    
    % removes the conditional check table java files to the path
    jDirCCT = fullfile(cDir,'Utilities','CondCheckTable');    
    if exist(jDirCCT,'dir')
        try; javarmpath(jDirCCT); end
    end 
    
    % removes the conditional check table java files to the path
    jDirCR = fullfile(cDir,'File Exchange','ColoredFieldCellRenderer.zip');
    if exist(jDirCR,'file')
        try; javarmpath(jDirCR); end
    end        
    
    % delete the progressbar and removes the directory from the path
    h.delete();
    rmpath(pbDir);
end    

% closes the GUI
delete(handles.figDART)

% reverts all warnings back to their original state
warning(wState);

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% -------------------------------- %
% --- DATA DIRECTORY FUNCTIONS --- %
% -------------------------------- %

% --- sets up all the default program directories --- %
function ProgDef = setupAllDefaultDir(defFile)

% if the default file hasn't been provided, then set the default name
if nargin == 0
    defFile = getParaFileName('ProgDef.mat');
end

% allocates memory for the program default struct
ProgDef = struct('Recording',[],'Tracking',[],'Combine',[],...
                 'Analysis',[],'DART',[]);

% sets up the record data struct fields
strDART = struct();
strDART.DirVer = {'Output','6 - Program Versions'};             
             
% sets up the record data struct fields
strRec = struct();
strRec.DirMov = {'Output','1 - Recorded Movies'};
strRec.CamPara = {'Recording','1 - Video Presets'};
strRec.DirPlay = {'Recording','2 - Stimuli Playlists'};
strRec.StimPlot = {'Recording','3 - Stimulus Traces'};

% sets up the tracking data struct fields
strTrk = struct();
strTrk.DirMov = {'Output','1 - Recorded Movies'};
strTrk.DirSoln = {'Output','2 - Solution Files (Video)'};
strTrk.TempFile = {'Tracking','1 - Temporary Files'};

% sets up the tracking data struct fields
strComb = struct();
strComb.DirSoln = {'Output','2 - Solution Files (Video)'};
strComb.DirComb = {'Output','3 - Solution Files (Experiment)'}; 
strComb.TempFile = {'Combine','1 - Temporary Files'};

% sets up the tracking data struct fields
strAnl = struct();
strAnl.DirSoln = {'Output','2 - Solution Files (Video)'};
strAnl.DirComb = {'Output','3 - Solution Files (Experiment)'}; 
strAnl.OutFig = {'Output','4 - Analysis Figures'};
strAnl.OutData = {'Output','5 - Analysis Data'};
strAnl.DirFunc = {'Analysis','1 - Analysis Functions'};
strAnl.TempFile = {'Analysis','2 - Temporary Files'};
strAnl.TempData = {'Analysis','3 - Temporary Data'};

% creates the new data directories from the structs listed above
dataDir = getProgFileNameDART('Data');
ProgDef.DART = createDataDir(strDART,dataDir);      
ProgDef.Recording = createDataDir(strRec,dataDir);      
ProgDef.Tracking = createDataDir(strTrk,dataDir);
ProgDef.Combine = createDataDir(strComb,dataDir);
ProgDef.Analysis = createDataDir(strAnl,dataDir);    
    
% saves the program default file
save(defFile,'ProgDef');

% --- updates the sub-directories within mainDir by the flag, type
%     (which is set to either 'add' or 'remove')
function updateSubDirectories(mainDir,type,varargin)

% global variables
global addWinVideo
if isempty(addWinVideo); addWinVideo = false; end

% if the winvideo drivers are already added, then exit
[~,subDir] = fileparts(mainDir);
if strcmp(subDir,'WinVideo') && ~addWinVideo
    return
end
    
% searches for the files within the current directory
if nargin == 2
    if strcmp(type,'add')
        % case is adding paths
        addpath(mainDir);
    else
        % case is removing paths        
        rmpath(mainDir)
    end
end
    
% sets the directory/name flags
mFile = dir(mainDir);
fName = cellfun(@(x)(x.name),num2cell(mFile),'un',0);
isDir = cellfun(@(x)(x.isdir),num2cell(mFile));

% sets the candidate directories for adding/removing files
nwDir = find(~(strcmp(fName,'.') | ...
               strcmp(fName,'..') | ...
               strcmp(fName,'Executable Only') | ...
               strcmp(fName,'Repo') | ...
               strContainsDART(fName,'_mcr')) & isDir); 

% sets the utilities directory
uDir = {'MCC','NIDAQ'};
if strcmp(type,'remove')
    uDir = [uDir,{'ProgressDialog'}];
end

% loops through
for i = 1:length(nwDir)
    % sets the new directory name (ignores the incorrect HG version and the
    % DAQ utility folders)
    nwDirName = fullfile(mainDir,fName{nwDir(i)});
    validDir = all(~strContainsDART(nwDirName,uDir));
    
    % adds/removes the path based on the type flag
    if validDir    
        if strcmp(type,'add')
            % case is adding paths
            addpath(nwDirName);
        else
            % case is removing paths        
            rmpath(nwDirName)
        end

        % searches for the directories within the current directory
        updateSubDirectories(nwDirName,type,1)
    end
end

% --- checks to if the default directories exist. if not, then prompt the
%     user to reset the default directories --- %
function ProgDef = checkAllDefaultDir(handles,ProgDef)

% retrieves the struct field names
hDART = handles.figDART;
fldNames = fieldnames(ProgDef);
defFile = getParaFileName('ProgDef.mat');

% loops through all of the program directories determining if the default
% directories exist. if they do not, then run the program default GUI
for i = 1:length(fldNames)
    % setting of the sub-program default structs
    ProgDefS = sprintf('ProgDef.%s',fldNames{i});        
    
    % sets the new sub-struct and its field names
    nwStr = eval(ProgDefS);
    fldNamesS = fieldnames(nwStr.fldData);
    
    % memory allocation
    nFlds = length(fldNamesS);
    [ok,dirDetails] = deal(true(nFlds,1),cell(nFlds,1));
    
    % loops through all of the fields determining if the directories exist
    for j = 1:nFlds
        % evaluates the new directory
        nwDir = eval(sprintf('nwStr.%s',fldNamesS{j}));
        dirDetails{j} = eval(sprintf('nwStr.fldData.%s;',fldNamesS{j}));
        
        % check to see if the directory exists
        if ~exist(nwDir,'dir')
            % if the directory does not exist, then clear the directory
            % field and flag a warning
            ok(j) = false;
            eval(sprintf('nwStr.%s = [];',fldNamesS{j})); 
        end        
        
    end
    
    % if any of the directories do not exist, then prompt the user to reset
    % the default directories
    if any(~ok)
        % outputs a warning for the user
        wStr = [{sprintf('The Following Directories Are Missing For The %s Program:',fldNames{i})};...
                {''};cellfun(@(x)(['    => ',x]),cellfun(@(x)(x{2}),dirDetails(~ok),'un',0),'un',0)];
        waitfor(warndlg(wStr,'Program Default File Missing'));
                    
        % runs the program default directory reset GUI
        obj = ProgDefaultDef(hDART,fldNames{i},nwStr);
        
        % updates the data struct with the new data struct
        ProgDef = setStructField(ProgDef,fldNames{i},obj.ProgDef);
        save(defFile,'ProgDef');
    end
end

% --- creates the data directories (if not already created)
function strComb = createDataDir(strData,dataDir)

% initialises the output data struct
strNw = struct('fldData',strData);

% creates the new default directories (if they do not exist)
b = fieldnames(strData);
for i = 1:length(b)
    % retrieves the new field information cell array
    nwCell = eval(sprintf('strData.%s',b{i}));    
    
    % sets the top directory. if it does not exist, then create it
    topDir = fullfile(dataDir,nwCell{1});
    if ~exist(topDir,'dir')
        mkdir(topDir);
    end
    
    % sets the new directory name and adds it the output data struct
    nwDir = fullfile(topDir,nwCell{2});        
    eval(sprintf('strNw.%s = nwDir;',b{i}));    
    
    % if the directory does not exist, then create it
    if ~exist(nwDir,'dir')
        mkdir(nwDir)
    end
end

% sets the combined struct
strComb = strNw;

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- initialises the program paths --- %
function [ok,h] = initGUIObjects(handles)

% global variables
global addWinVideo mainProgDir

% turns off all warnings
wState = warning('off','all');

% global variables
mainDir = pwd;
[isTest,ok,h] = deal(getappdata(handles.figDART,'isTest'),true,[]);

% resets the folder names/locations
if ~isdeployed
    % ensures the "Test Files" directory is renamed to "External Files"
    testDir = fullfile(mainDir,'Test Files');
    if exist(testDir,'dir')
        nwDir = fullfile(mainDir,'External Files');
        ok = movefile(testDir,nwDir,'f');

        % if there was an error, then exit
        if ~ok; return; end
    end
    
    % ensures the Git folder is in the "Code" sub-directory
    gitDir = fullfile(mainDir,'Code','Common','Git');
    if exist(gitDir,'dir')
        % removes the git-dir environment variables
        gitEnvVarFuncDART('GIT_DIR')
        
        % moves the directory
        nwDir = fullfile(mainDir,'Git');
        ok = movefile(gitDir,nwDir,'f');

        % to move the git folder, the user must quit and restart 
    end
end

% % uses the opengl software for rendering
% try; opengl('hardware'); end

% determines if the environment variables are set correctly
if ismac && ~verLessThan('matlab','9.2')
    ePath = getenv('PATH');
    if ~any(strcmp(regexp(ePath,'[:]','split'),'/bin/bash'))
        % if not, then update them
        setenv('PATH',[ePath,':/bin/bash'])
    end
end

% if the parameter files sub-directory is not located in the main program
% directory, then exit with an error
paraDir = fullfile(mainDir,'Para Files');
if ~exist(paraDir,'dir')
    eStr = sprintf(['The parameter files sub-directory ("Para Files") ',...
            'is not present in the location where you are attempting ',...
            'to run DART from.\n\nMove the DART executable file ',...
            '(DART.exe) or Matlab entry file (DART.m) to where this ',...
            'directory is located and then restart the program']);
    waitfor(errordlg(eStr,'Parameter Files Directory Missing?','modal'))
    
    % exits the program
    ok = false;
    return        
end

% if DART doesn't exist in the current path then exit with an error
if ~exist(fullfile(mainDir,'DART.m'),'file') && ~isdeployed
    eStr = {'DART is being run from the incorrect directory.';...
            ['Alter the Matlab path to the DART program ',...
             'directory and restart']};
    waitfor(errordlg(eStr,'Incorrect Start Directory','modal'))
    
    % exits the program
    ok = false;
    return
end

% attempts to write a temporary file to the parameter directory (checks if
% the user has valid write permissions)
try
    tmpFile = fullfile(paraDir,'TempFile.mat');
    save(tmpFile,'paraDir');
    delete(tmpFile);
catch 
    % if not, then output an error to screen and exit the program
    eStr = {'Error! Matlab does not have valid Write Permissions.';'';...
            'You will need to re-open Matlab with Administrative Permissions'};
    waitfor(errordlg(eStr,'Invalid Write Permissions','modal'))
    ok = false;
    return    
end

% ------------------------------------------ %
% --- DIRECTORY/PARAMETER INITIALISATION --- %
% ------------------------------------------ %

% adds in the progress dialog menu
if ~isdeployed
    baseDir = fullfile(mainDir,'Code','Common');
    addpath(fullfile(baseDir,'File Exchange','ProgressDialog'));
    addpath(fullfile(baseDir,'Progress Bars'));
end

% creates the load bar
h = ProgressLoadbar('Initialising DART Program...');

% adds the miscellaneous file path
if ~isdeployed
    % determines if there are any other figures open (that isn't DART or
    % any regular figures)
    hFig0 = findall(0,'type','figure');
    hFigTag = get(hFig0,'tag');         
    ii = ~(strcmp(hFigTag,'figDART') | cellfun(@isempty,hFigTag) | ...
           strcmp(hFigTag,'__progressbar__'));    
    if any(ii)
        % if so, then set the tag strings for these figures
        [hFigT, hFigTag] = deal(hFig0(ii), hFigTag(ii));
        vStr = cellfun(@(x)(get(x,'visible')),num2cell(hFigT),'un',0);
        
        % retrieves the tags of all the other 
        addpath(fullfile(mainDir,'Code','Common','Miscellaneous'))    
        fName = findFileAll(fullfile(mainDir,'Code'),'*.fig');
        
        % reads in the tag strings for each figure
        isFound = 0;
        for i = 1:length(fName) 
            hFigNw = load(fName{i},'-mat'); 
            hFigNw.hgM_070000.GraphicsObjects.Format3Data.Visible='off';
            
            hFigC = findall(0,'type','figure');
            try; delete(hFigC(1)); end
            
            if any(strcmp(hFigTag, hFigNw.hgS_070000.properties.Tag))
                isFound = 1;
                break
            end
        end          

        % determines if any of these figures are open
        if isFound
            % if so, then output an error to screen
            setObjVisibility(handles.figDART,0); pause(0.05)
            eStr = 'Error! A DART session is already running!';
            waitfor(errordlg(eStr,'DART Initialisation Error','modal'))
            
            % sets the last figure to be visible
            cellfun(@(x,y)(set(x,'visible',y)),num2cell(hFigT),vStr)
            
            % deletes the new GUI and exits the function  
            try; delete(h); end
            error('Session Already Running');              
        end
    end        
end

% adds in the program directories
if ~isdeployed    
    try
        imaqInfo = imaqhwinfo;
        addWinVideo = ~any(strcmp(imaqInfo.InstalledAdaptors,'winvideo'));
    catch
        addWinVideo = false;
    end
    
    % adds the main program paths
    addpath(mainDir)
    updateSubDirectories(fullfile(mainDir,'Code'),'add')
    updateSubDirectories(fullfile(mainDir,'Git'),'add')
    updateSubDirectories(fullfile(mainDir,'External Files'),'add')
    updateSubDirectories(fullfile(mainDir,'Para Files'),'add')
end
    
% adds the xlwrite java files to the path
cDir = fullfile(mainDir,'Code','Common');
jDirXL = fullfile(cDir,'File Exchange','xlwrite','poi_library');
if exist(jDirXL,'dir')
    jFiles = dir(fullfile(jDirXL,'*.jar'));
    jFile = arrayfun(@(x)(fullfile(jDirXL,x.name)),jFiles,'un',0);
    cellfun(@(x)(javaaddpath(x,'-END')),jFile);        
end

% adds the heap clear java files to the path
jDirHC = fullfile(cDir,'File Exchange','jheapcl');
if exist(jDirHC,'dir')
    javaaddpath(fullfile(jDirHC,'MatlabGarbageCollector.jar'),'-END');
end

% adds the conditional check table java files to the path
jDirCCT = fullfile(cDir,'Utilities','CondCheckTable');
if exist(jDirCCT,'dir')
    javaaddpath(jDirCCT);
end        

% adds the coloured field cell renderer
jDirCR = fullfile(cDir,'File Exchange','ColoredFieldCellRenderer.zip');
if exist(jDirCR,'file')
    javaaddpath(jDirCR,'-END');
end        

% global variables
mainProgDir = mainDir;
defFile = getParaFileName('ProgDef.mat');
    
% loads the default parameter files
if exist(defFile,'file')
    % if so, loads the program preference file and set the program
    % preferences (based on the OS type)
    defData = load(defFile); 
    ProgDef = checkAllDefaultDir(handles,defData.ProgDef); 
    
else
    % if the file doesn't exist, then create the new directories
    set(h.Control,'visible','off');  
    eStr = [{['The DART Program Data File Has Not ',...
              'Been Initialised Or Is Missing']};...
            {['DART Will Now Automatically Create ',...
              'The Default Program Data File.']}];
    waitfor(warndlg(eStr,'Program Default File Missing'))
    
    % sets up the directories here
    ProgDef = setupAllDefaultDir(defFile);
    set(h.Control,'visible','on');  
    uistack(h.Control,'top');
end

% determines if the analysis functions folder exists in the main program
% directory (this will occur after the initial setup)
analyDir = getProgFileNameDART('Analysis Functions');
if exist(analyDir,'dir')
     % if is does, then copy the folder to the correct location and remove
     % the directory from the main folder
     copyAllFiles(analyDir,ProgDef.Analysis.DirFunc);
     rmvAllFiles(analyDir); 
end

% sets the full program default struct into the menuDART GUI
setappdata(handles.figDART,'ProgDef',ProgDef)

% --------------------------------------------- %
% --- OTHER OBJECT PROPERTY INITIALISATIONS --- %
% --------------------------------------------- %

% other initialisations
[uType,sepStr] = deal(getUserType(),{'off','on'});
hasSep = (uType == 0) && ~isdeployed; 

% only include the add package menu item if the function exists
hasPackageFile = exist('runPackageInstaller','file') > 0;
setObjVisibility(handles.menuAddPackage,hasPackageFile);

% creates the Git menu items
if exist('GitFunc','file') && ~isdeployed
    feval('setupGitMenus',handles.figDART)
end

% loads the button image data file
A = load('ButtonCData.mat'); 
cData = A.cDataStr;

% sets the button bitmap images and sub-object names
BData = {{'Recording','FlyRecord'};...
         {'Tracking','FlyTrack'};...
         {'Combine','FlyCombine'};...
         {'Analysis','FlyAnalysis'};...
         {'Exit','ExitButton'}};         

% loops through of all the button setting their face images and other
% related properties
for i = 1:length(BData)
    % retrieves the image and the button object handle
    ImgNw = getStructField(cData,BData{i}{1});
    hButton = getStructField(handles,sprintf('button%s',BData{i}{2}));
        
    % updates the button colour data
    set(hButton,'CData',uint8(ImgNw));
    if i ~= length(BData)    
        % searches for the program main file
        fNameNw = sprintf('%s.m',BData{i}{2});
        fMatch = fileNameMatchSearch(fNameNw,getProgFileNameDART());            

        % retrieves the program defaults (depending on OS)
        ProgDefNw = getStructField(ProgDef,BData{i}{1});
        
        % if there is a match, then set the file match
        if ~isempty(fMatch) || isdeployed
            uData = ProgDefNw;
        else
            uData = [];
        end
        
        % checks to see if new match has been made
        if isempty(uData)
            % if it doesn't exist, then disable the button            
            setObjEnable(hButton,'off')
        else
            % otherwise, then enable the button and set the program path
            set(setObjEnable(hButton,'on'),'UserData',uData)
        end
    end
end

% sets the GUI properties based on whether the program is deployed or not
if isdeployed
    % if the program is deployed, then disable the program update menu item
    setObjEnable(handles.menuUpdateProg,'off')
    setObjEnable(handles.menuOutputProg,'off')
    setObjEnable(handles.menuDeployExe,'off')
    setObjEnable(handles.menuSetupProg,'off')
    setObjEnable(handles.menuConfigSerial,'on')
    
else
    % checks to see if A) the matlab version is running 32-bit matlab, and
    % B) if the OS type is PC
    if ispc
        % if so, enable deployment of the executable
        setObjEnable(handles.menuDeployExe,'on')    
        setObjEnable(handles.menuConfigSerial,'on')
        setObjEnable(handles.menuExeUpdate,exist('ExeUpdate.exe','file')>0)
        
    else
        % otherwise, if not a test, then disable the fly record button
        if ~isTest
            setObjEnable(handles.buttonFlyRecord,'off')
        end
    end
end

% sets the I/O menu item properties
setObjVisibility(handles.menuUpdateProg,hasSep)
setObjVisibility(handles.menuOutputProg,hasSep)
setObjVisibility(handles.menuDeployExe,hasSep)
setObjVisibility(handles.menuSetupProg,~isdeployed)
set(handles.menuExeUpdate,'Separator',sepStr{1+hasSep})
set(handles.menuSetupProg,'Separator',sepStr{1+(uType>0)})

% -------------------------------- %
% --- PARAMETER FILE DETECTION --- %
% -------------------------------- %

% if the program parameter file is missing, then create it
pFile = fullfile(paraDir,'ProgPara.mat');
if ~exist(pFile,'file')
    % if the file is missing, then initialise it
    initProgParaFile(paraDir);
    
else
    % loads the parameter file
    [A,isChange] = deal(load(pFile),false);      
    
    % determines if the tracking parameters have been set
    if ~isfield(A,'trkP')
        % initialises the tracking parameter struct
        isChange = true;
        A.trkP = struct('nFrmS',25,'nPath',1,'PC',[],'Mac',[]);

        % sets the PC classification parameters
        A.trkP.PC.pNC = struct('pCol',[1.0 1.0 0],'pMark','.','mSz',20);
        A.trkP.PC.pMov = struct('pCol',[0.0 1.0 0.0],'pMark','.','mSz',20);
        A.trkP.PC.pStat = struct('pCol',[1.0 0.4 0.0],'pMark','.','mSz',20);
        A.trkP.PC.pRej = struct('pCol',[1.0 0.0 0.0],'pMark','.','mSz',20);

        % sets the Mac classification parameters
        A.trkP.Mac.pNC = struct('pCol',[1.0 1.0 0],'pMark','*','mSz',8);
        A.trkP.Mac.pMov = struct('pCol',[0.0 1.0 0.0],'pMark','*','mSz',8);
        A.trkP.Mac.pStat = struct('pCol',[1.0 0.4 0.0],'pMark','*','mSz',8);
        A.trkP.Mac.pRej = struct('pCol',[1.0 0.0 0.0],'pMark','*','mSz',8);               
    else        
        % if the orientatation angle field is missing, then add it in
        if ~isfield(A.trkP,'calcPhi')
            [A.trkP.calcPhi,isChange] = deal(false,true);
        end          
    end
    
    % ensures the optimal down-sampling field is set
    if ~isfield(A.bgP,'pPhase')   
        isChange = true;
        A.bgP = DetectPara.initDetectParaStruct('pPhase');
    end
    
    % determines if the serial device names have been set
    if ~isfield(A,'sDev')
        % initialises the serial device names
        isChange = true;
        A.sDev = {'STMicroelectronics STLink COM Port',...
                  'STMicroelectronics STLink Virtual COM Port',...
                  'STMicroelectronics Virtual COM Port',...
                  'USB Serial Device'};
    end
    
    % updates the parameter file
    if isChange
        save(pFile,'-struct','A');       
    end
end

% reverts warnings back to the original state
warning(wState)

% --- updates the log-file with the new information
function updateLogFile(zFile)

% determines the zip-file name parts
[~,fName,fExtn] = fileparts(zFile);

% resaves the log-file
[Time,File] = deal(clock,[fName,fExtn]);
logFile = getParaFileName('Update Log.mat');
save(logFile,'File','Time')

% --- wrapper function for determining if a string has a pattern. this is
%     necessary because there are 2 different ways of determining this
%     depending on the version of Matlab being used
function hasPat = strContainsDART(str,pat)

if isempty(pat)
    hasPat = false;
    return
elseif iscell(str)
    hasPat = cellfun(@(x)(strContainsDART(x,pat)),str);
    return
end

try
    % attempts to use the newer version of the function
    hasPat = contains(str,pat);
catch
    % if that fails, use the older version of the function
    hasPat = ~isempty(strfind(str,pat));
end

% --- removes the git environment variable
function gitEnvVarFuncDART(vName)

% case is removing an environment variable
cmdStr = sprintf('reg delete "HKCU\\Environment" /v %s /f',vName);
setenv(vName,'');

% runs the string from the command line
[~,~] = system(cmdStr);

% --- retrieves the full name of a program directory or file
function pFile = getProgFileNameDART(varargin)

% global variables
global mainProgDir

% sets the base program folder path
pFile = mainProgDir;

% sets the full program file name path
for i = 1:length(varargin)
    pFile = fullfile(pFile,varargin{i});
end