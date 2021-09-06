function varargout = GitCommit(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GitCommit_OpeningFcn, ...
                   'gui_OutputFcn',  @GitCommit_OutputFcn, ...
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

% --- Executes just before GitCommit is made visible.
function GitCommit_OpeningFcn(hObject, ~, handles, varargin)

% Choose default command line output for GitCommit
handles.output = hObject;

% sets the input arguments
hFig = varargin{1};
setObjVisibility(hFig,0)

% sets the GUI run type
switch length(varargin)
    case (1) % case is the 
        [rType,gDirP,~,gName] = promptGitRepo();
        if isempty(rType)
            % if the user cancelled, then delete the GUI and exit
            delete(hObject)
            setObjVisibility(hFig,1)
            return
        else
            % otherwise, create the GitFunc class object
            GF = GitFunc(rType,gDirP,gName);
        end
        
    case (2)
        % if there are input arguments, then set their local values
        GF = varargin{2};        
end

% creates the loadbar
h = ProgressLoadbar('Determining Current Local Changes...');

% initialises the important class objects
comObj = GitCommitClass(hObject,hFig,GF);
setappdata(hObject,'comObj',comObj)

% deletes the loadbar
delete(h)

% Update handles structure
guidata(hObject, handles);

% % UIWAIT makes GitCommit wait for user response (see UIRESUME)
% uiwait(handles.figGitCommit);

% --- Outputs from this function are returned to the command line.
function varargout = GitCommit_OutputFcn(hObject, ~, ~)

% Get default command line output from handles structure
varargout{1} = hObject;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     FIGURE CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when user attempts to close figGitCommit.
function figGitCommit_CloseRequestFcn(~, ~, handles)

% runs the GUI exit function
try; menuExit_Callback(handles.menuExit, [], handles); end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                      MENU CALLBACK FUNCTIONS                      %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
function menuExit_Callback(~, ~, handles)

% global variables
global mainProgDir

% prompts the user if they wish to close the tracking gui
qStr = 'Are you sure you want to close the Git Commit GUI?';
uChoice = questdlg(qStr,'Close Git Commit GUI?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if the user cancelled, then exit
    return
end

% retrieves the GitFunc object
hFig = handles.figGitCommit;
comObj = getappdata(hFig,'comObj');
postCommitFcn = getappdata(hFig,'postCommitFcn');

% determines if GitCommit was run from the GitVersion GUI
if ~isempty(findall(0,'tag','figGitVersion'))
    % if so, then determine if there any uncommitted modifications 
    if comObj.gfObj.detIfBranchModified()
        % if so, then prompt the user if they want to stash these files
        qStr = sprintf(['There are still uncommitted changes on the ',...
                        'current branch.\nDo you want to stash these ',...
                        'uncommitted changes?']);
        uChoiceM = questdlg(qStr,'Stash Uncommited Changes?',...
                            'Yes','No','Cancel','Yes');
        switch uChoiceM
            case 'Yes'
                % case is the user chose to stash the files
                comObj.gfObj.stashBranchFiles()                
            case 'Cancel'
                % case is the user cancelled so exit
                return
        end
    end    
end

% changes the directory back down to the main directory and closes the GUI
cd(mainProgDir)
delete(hFig)

% runs the post commit function (if any)
if ~isempty(postCommitFcn)    
    postCommitFcn(comObj);
end

% sets the main GUI visible again
setObjVisibility(comObj.hFigM,1)
    
