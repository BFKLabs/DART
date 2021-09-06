function varargout = GitVerInfo(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GitVerInfo_OpeningFcn, ...
                   'gui_OutputFcn',  @GitVerInfo_OutputFcn, ...
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

% --- Executes just before GitVerInfo is made visible.
function GitVerInfo_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for GitVerInfo
handles.output = hObject;

% initialises the gui information and centres it within the screen
initObjProps(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GitVerInfo wait for user response (see UIRESUME)
% uiwait(handles.figVerInfo);


% --- Outputs from this function are returned to the command line.
function varargout = GitVerInfo_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     FIGURE CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when user attempts to close figVerInfo.
function figVerInfo_CloseRequestFcn(hObject, eventdata, handles)

% closes the windo
menuExit_Callback(handles.menuExit, [], handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                      MENU CALLBACK FUNCTIONS                      %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

% closes the figure
delete(handles.figVerInfo);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                          OTHER FUNCTIONS                          %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- initialises the object properties
function initObjProps(handles)

% global variables
global mainProgDir

% parameters
dX = 10;

% retrieves the repo information
[rType,gDirP,gRepoDir,gName] = promptGitRepo(false);

% memory allocation
sStr = {'','s'};
nRepo = length(rType);
nowStr = {datestr(now,'yyyy-mm-dd HH:MM')};
[Data,ok] = deal(cell(nRepo,3),false(nRepo,1));

% loads the update information from the parameter file
pFile = getParaFileName('RepoUpdate.mat');
if exist(pFile,'file')
    % if the git repo information is missing, then create it
    A = load(pFile);    
    if nRepo ~= size(A.grUpdate,1)
        % adds in the missing repository fields
        isAdd = cellfun(@(x)(~any(strcmp(A.grUpdate(:,1),x))),gName);
        grUpdateNw = [gName(isAdd),repmat(nowStr,sum(isAdd),1)];
        A.grUpdate = [A.grUpdate;grUpdateNw];

        % updates the parameter file 
        save(pFile,'-struct','A');
    end
else
    % creates the parameter file information
    A = struct('grUpdate',[]);
    A.grUpdate = [gName(:),repmat(nowStr,nRepo,1)];
    
    % saves the parameter file
    save(pFile,'-struct','A');
end


% sets the repo name and update information
Data(:,[1,4]) = A.grUpdate;
h = ProgressLoadbar('');

% retrieves the git information
for i = 1:nRepo
    % updates the loadbar
    h.StatusMessage = sprintf('Checking Repository: "%s" (%i of %i)',...
                               gName{i},i,nRepo);
    
    % creates the git items
    gitEnvVarFunc('add','GIT_DIR',gRepoDir{i})
    GF = GitFunc(rType{i},gDirP{i},gName{i});
    
    % removes/sets the origin url
    GF.gitCmd('rmv-origin')
    GF.gitCmd('set-origin')
    
    % retrieves the repo's current commit ID and git history
    cID = GF.gitCmd('commit-id');
    [gHist,ok(i)] = getCommitHistory(GF,[]); 
    Data{i,2} = num2str(length(gHist));
    
    % determines the matching 
    iMatch = find(strcmp(field2cell(gHist,'ID'),cID))-1;
    if iMatch == 0
        % case is the user is using the latest version
        Data{i,3} = 'Latest Version';
    else
        % if no match, then an issue has occured (git repo has been reset?)
        % if this is the case a new branch for the current version will
        % need to be created
        if isempty(iMatch)
            iMatch = length(gHist); 
            
            % creates new local branch supporting the current version
        end
        
        % otherwise, flag how many versions behind
        vStr = sprintf('%i Version%s Behind',iMatch,sStr{1+(iMatch>1)});
        Data{i,3} = setHTMLColourString('r',vStr,1);
    end
    
    % removes the git directory environment variables
    gitEnvVarFunc('remove','GIT_DIR');
    GF.gitCmd('rmv-origin');
end

% sets the directory to the main
cd(mainProgDir)

% deletes the loadbar
try; delete(h); end

% resets the height of the table
tPos = get(handles.tableVerInfo,'Position');
tPos(4) = calcTableHeight(nRepo);

% resets the height of the panel
pPos = get(handles.panelVerInfo,'Position');
pPos(4) = tPos(4)+2*dX;

% resets the figure height
resetObjPos(handles.figVerInfo,'Height',sum(pPos([2,4]))+dX);

% sets the table and resizes the columns
set(handles.panelVerInfo,'Position',pPos)
set(handles.tableVerInfo,'Position',tPos);

% resizes the columns
autoResizeTableColumns(handles.tableVerInfo)

% centres the figure and makes it visible
centreFigPosition(handles.figVerInfo)
set(handles.figVerInfo,'Visible','on')
pause(0.05);

% sets the horizontally aligned data into the table
setHorizAlignedTable(handles.tableVerInfo,Data)
