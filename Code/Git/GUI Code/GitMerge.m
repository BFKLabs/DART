function varargout = GitMerge(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GitMerge_OpeningFcn, ...
                   'gui_OutputFcn',  @GitMerge_OutputFcn, ...
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

% --- Executes just before GitMerge is made visible.
function GitMerge_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global isCont
isCont = false;

% Choose default command line output for GitMerge
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% sets the input variables
vObj = varargin{1};
dData = varargin{2};

%
if length(varargin) > 2
    % case is running the merge from the version gui
    mBr = varargin{3};
    cBr = varargin{4};    
    mrgObj = GitMergeClass(hObject,vObj,dData,mBr,cBr);
else
    % case is running the merge from the rebase gui
    mrgObj = GitMergeClass(hObject,vObj,dData);
end

% creates the merge-object class
setappdata(hObject,'mrgObj',mrgObj)

% UIWAIT makes GitMerge wait for user response (see UIRESUME)
uiwait(handles.figGitMergeDiff);

% --- Outputs from this function are returned to the command line.
function varargout = GitMerge_OutputFcn(hObject, eventdata, handles) 

% global variables
global isCont

% Get default command line output from handles structure
varargout{1} = isCont;

% --- Executes when user attempts to close figGitMergeDiff.
function figGitMergeDiff_CloseRequestFcn(hObject, eventdata, handles)

% runs the cancel function
buttonCancel_Callback(handles.buttonCancel, [], handles)

%-------------------------------------------------------------------------%
%                        OBJECT CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    OTHER CONTROL BUTTON FUNCTIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in buttonCont.
function buttonCont_Callback(hObject, eventdata, handles)

% global variables
global isCont
isCont = true;

% retrieves the 
hFig = handles.figGitMergeDiff;
mrgObj = getappdata(hFig,'mrgObj');
gfObj = mrgObj.vObj.gfObj;

% updates the merge files (if using ours/theirs files)
for i = find(mrgObj.iAct{1}(:)>1)'
    % retrieves the conflicted file name
    fName = mrgObj.dData.Conflict(i).Name;    
    switch mrgObj.iAct{1}(i)
        case 2
            % case is accepting the merging branch file
            gfObj.gitCmd('checkout-ours',fName);
            
        case 3
            % case is accepting the current branch file
            gfObj.gitCmd('checkout-theirs',fName);
    end
    
    % re-adds the file and continues
    gfObj.gitCmd('add-file',fName)
end

% removes the temporary file directory and closes the GUI
tmpDirFunc('remove')
delete(hFig)

% --- Executes on button press in buttonCancel.
function buttonCancel_Callback(hObject, eventdata, handles)

% prompts the user if they are sure they want to close the GUI
qStr = 'Are you sure you want to cancel the branch merge operation?';
uChoice = questdlg(qStr,'Cancel Merge Resolution?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if the user cancelled, then exit
    return
end

% makes the GUI invisible
hFig = handles.figGitMergeDiff;
mrgObj = getappdata(hFig,'mrgObj');
hButRevD = handles.buttonRevertDiff;
hButRevC = handles.buttonRevertConflict;

% sets the figure to be invisible
setObjVisibility(hFig,0)

% reverts any files that have been altered
hTable = {handles.tableConflict,handles.tableDiff};
for i = 1:length(hTable)
    % retrieves the table data
    Data = get(hTable{i},'Data');
    for j = 1:size(Data,1)
        if ~isempty(Data{j,1}) && Data{j,3}
            % runs the revert function (depending on the type)
            if i == 1
                % case is reverting the conflict merge 
                mrgObj.buttonRevert(hButRevC,i,'Conflict');
            else
                % case is reverting the file difference
                mrgObj.buttonRevert(hButRevD,i,'Diff');               
            end
        end
    end
end

% changes the directory back to the original
cd(mrgObj.cDir0);

% removes the temporary directory and closes the GUI
tmpDirFunc('remove')
delete(hFig)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- retrieves the temporary difference file directory
function tmpDir = getTempDiffFileDir()

tmpDir = 'Test Files/TempDiff';

% --- performs the temporary directory function type
function tmpDirFunc(type)

% global variables
global mainProgDir

% retrieves the full temporary directory name
tmpDir = getTempDiffFileDir();
tmpDirFull = strrep(fullfile(mainProgDir,tmpDir),'/',filesep);

switch (type)
    case 'add'
        % case is adding the directory
        if ~exist(tmpDirFull,'dir')
            mkdir(tmpDirFull); 
        end
        
    case 'remove'
        % case is removing the directory
        if exist(tmpDirFull,'dir')
            rmdir(tmpDirFull, 's'); 
        end
end
       
