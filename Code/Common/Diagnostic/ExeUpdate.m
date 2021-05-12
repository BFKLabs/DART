function varargout = ExeUpdate(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ExeUpdate_OpeningFcn, ...
                   'gui_OutputFcn',  @ExeUpdate_OutputFcn, ...
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


% --- Executes just before ExeUpdate is made visible.
function ExeUpdate_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for ExeUpdate
handles.output = hObject;

% sets the input argument
hMain = varargin{1};
setappdata(hObject,'hMain',hMain)

% checks if the executable requires updating
iStatus = checkCurrentUpdateStatus(handles,hMain);
if iStatus > 0
    % if no update is required then 
    createResponseFile(handles,0);
    pause(0.05);    
    
    % if no update is required/feasible then close the gui
    setObjVisibility(hMain,1)
    deleteTempDir(handles);
    delete(hObject)
    return
end

% initialises the object properties
initObjProps(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ExeUpdate wait for user response (see UIRESUME)
% uiwait(handles.figExeUpdate);

% --- Outputs from this function are returned to the command line.
function varargout = ExeUpdate_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = [];

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when user attempts to close figExeUpdate.
function figExeUpdate_CloseRequestFcn(hObject, eventdata, handles)

% do nothing...?
a = 1;

%-------------------------------------------------------------------------%
%                        OBJECT CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes on button press in buttonApplyUpdate.
function buttonApplyUpdate_Callback(hObject, eventdata, handles)

% parameters
tPause = 0.1;

% if running DART via executable, then warn the user that will close
if isdeployed
    mStr = 'DART will close after applying the executable update.';
    waitfor(msgbox(mStr,'DART Closedown','modal'))
end

% memory allocation
hTxt = handles.textProg;
hImg = findall(handles.axesProg,'type','image');
fSzT = getappdata(handles.figExeUpdate,'fSzT');
tempDir = getappdata(handles.figExeUpdate,'tempDir');
hMain = getappdata(handles.figExeUpdate,'hMain');

% sets the temporary file name
tempFile = fullfile(tempDir,'ExeUpdate.zip');

% creates a response file (flagging file download continuation)
createResponseFile(handles,1);

% keep looping until the file has been downloaded
while 1
    if exist(tempFile,'file')
        fInfo = dir(tempFile);
        fSzC = byte2mbyte(fInfo.bytes);
        
        % updates the download progress
        updateDownloadProgress(hImg,hTxt,fSzC,fSzT);
        if fSzC == fSzT
            % if the download is complete, then exit the loop
            break
        end
    end
    
    % pauses for a little bit
    pause(tPause)
end

% if DART is being run via executable, then close DART
if isdeployed
    delete(hMain);
else
    setObjVisibility(hMain,1)
end

% closes the gui if successful
delete(handles.figExeUpdate)

% --- Executes on button press in buttonCloseUpdate.
function buttonCloseUpdate_Callback(hObject, eventdata, handles)

% kills the ExeUpdate.exe process (if it is running)
killExternExe(handles)

% creates a response file (flagging no continuation)
createResponseFile(handles,0);

% makes the gui visible again
hMain = getappdata(handles.figExeUpdate,'hMain');
setObjVisibility(hMain,1);

% deletes the temporary data folder and the GUI
deleteTempDir(handles)
delete(handles.figExeUpdate)

% --- kills the external update executable process (if it is running)
function killExternExe(handles)

% parameters
iCol = 2;

% determines if the ExeUpdate.exe process is running
[~,tList0] = system('tasklist /fo csv | findstr /c:"ExeUpdate.exe"');
if isempty(tList0)
    % if the task is not in the list, then exit
    return
end

% splits the task list information into a single cell array
tListSp = cell2cell(cellfun(@(x)(regexp(x,'"(.*?)"', 'match')),...
                    strsplit(tList0(1:end-1),'\n')','un',0),1);
idList = cellfun(@(x)(sprintf('/pid %s',...
                    x(2:end-1))),tListSp(:,iCol),'un',0)';
                
% kills the task
killStr = sprintf('taskkill /f %s',strjoin(idList(:)'));
[~,~] = system(killStr);

% pauses before continuing
pause(1);
for i = size(tListSp,1)
    
end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- creates the response file with the flag, isCont
function createResponseFile(handles,cont)

% sets the response file name
tempDir = getappdata(handles.figExeUpdate,'tempDir');

if exist(tempDir,'dir')
    % sets the response file output directory
    responseFile = fullfile(tempDir,'Response.mat');

    % saves the continuation flag to file and pauses for a little bit...
    save(responseFile,'cont')
    pause(0.05);
end

% --- initialises the object properties
function initObjProps(handles)

% initialises the progress
hImg = image(handles.axesProg,uint8(256*ones(1,1000,3)));
set(handles.axesProg,'xtick',[],'xticklabel',[],'ytick',[],'yticklabel',[])

% updates the download progress
fSzT = getappdata(handles.figExeUpdate,'fSzT');
updateDownloadProgress(hImg,handles.textProg,0,fSzT);

% --- checks the status of the current update file
function iStatus = checkCurrentUpdateStatus(handles,hMain)

% global variables
global mainProgDir

% creates a loadbar
h = ProgressLoadbar('Checking Current Executable Versions...');

% initialisations
iStatus = 0;
exeFile = which('ExeUpdate.exe');
dartFile = fullfile(mainProgDir,'DART.ctf');
tempDir = fullfile(fileparts(exeFile),'TempFiles');
statusFile = fullfile(tempDir,'Status.mat');

% sets the important fields into the gui
setObjVisibility(hMain,0)
setappdata(handles.figExeUpdate,'tempDir',tempDir);

% deletes the status file (if one already exists)
if exist(tempDir,'dir')
    rmdir(tempDir,'s')
end

% changes directory to the temporary directory
cDir0 = pwd;
cd(fileparts(tempDir))

% runs the executable file
Process = System.Diagnostics.Process();
Process.StartInfo.UseShellExecute = false;
Process.StartInfo.CreateNoWindow = true;
Process.Start(exeFile);

% keep waiting until the status file appears
while ~exist(statusFile,'file')
    pause(0.1);
end

% loads the status file information and then deletes it
sInfo = load(statusFile);
delete(statusFile);
cd(cDir0)

% deletes the loadbar
delete(h)

% determines if the file could be successfully detected
if sInfo.ok
    % determines if the 
    fInfo = dir(dartFile);
    if fInfo.datenum > datenum(sInfo.mod_time)
        % if the current DART version date time exceeds that stored on the
        % remove server, output a message to screen
        iStatus = 1;
        mStr = ['Current DART version is the ',...
                'latest so no update is required.'];
        waitfor(msgbox(mStr,'No Update Required','modal'))        
    else
        % otherwise, set the file size information
        setappdata(handles.figExeUpdate,'fSzT',byte2mbyte(sInfo.size));        
    end    
else
    % otherwise, output an error to screen
    eStr = sprintf(['Executable update failed with the following ',...
                    'error:\n\n => "%s"'],sInfo.e_str);
    waitfor(msgbox(eStr,'Executable Update Failure','modal'))
    
    % exits the function
    iStatus = 2;
end

% --- updates the download progress bar
function updateDownloadProgress(hImg,hTxt,fSzC,fSzT)

% initialisations
I = get(hImg,'CData');

% calculates the number 
pC = fSzC/fSzT;
nC = roundP(pC*size(I,2));

% updates the progress bar axes
[I(:,1:nC,2),I(:,1:nC,3)] = deal(0);
set(hImg,'CData',I);

% updates the text string
tStr = sprintf('%.1f of %.1fMB (%.1f%s Complete)',fSzC,fSzT,100*pC,'%');
set(hTxt,'string',tStr)

% --- deletes the temporary directory
function deleteTempDir(handles)

% determines if the temporary directory exists
tempDir = getappdata(handles.figExeUpdate,'tempDir');
if exist(tempDir,'dir')
    % if so, then delete it
    rmdir(tempDir,'s')
end

% --- converts the size in bytes to megabytes
function fSzMB = byte2mbyte(fSzB)

fSzMB = double(fSzB)/(1024^2);
