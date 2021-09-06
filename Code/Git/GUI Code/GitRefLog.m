function varargout = GitRefLog(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GitRefLog_OpeningFcn, ...
                   'gui_OutputFcn',  @GitRefLog_OutputFcn, ...
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

% --- Executes just before GitRefLog is made visible.
function GitRefLog_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for GitRefLog
handles.output = hObject;

% retrieves the main GUI handle
vObj = varargin{1};
% cBr = mObj.GitFunc.getCurrentBranch();

% sets the input arguments
setappdata(hObject,'vObj',vObj);
setappdata(hObject,'isChange',false);

% initialises the GUI objects
initGUIObjects(handles,vObj)
% setappdata(hObject,'hRLP',RefLogPara(vObj,hObject));

% Update handles structure
guidata(hObject, handles);

% % UIWAIT makes GitRefLog wait for user response (see UIRESUME)
% uiwait(handles.figRefLog);

% --- Outputs from this function are returned to the command line.
function varargout = GitRefLog_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = hObject;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     FIGURE CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when user attempts to close figRefLog.
function figRefLog_CloseRequestFcn(hObject, eventdata, handles)

% Hint: delete(hObject) closes the figure
menuExit_Callback(handles.menuExit, [], handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                      MENU CALLBACK FUNCTIONS                      %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
function menuResetHist_Callback(hObject, eventdata, handles)

% prompts the user if they want to reset the history
qStr = 'Are you sure you want to reset the history to this point?';
uChoice = questdlg(qStr,'Reset Log History?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if not, then exit the function
    return
end

% creates a loadbar
h = ProgressLoadbar('Resetting History Point...');

% retrieves the important fields from the current GUI
hFig = handles.figRefLog;
vObj = getappdata(hFig,'vObj');
headID = getappdata(hFig,'headID');
tData = get(handles.tableRefLog,'Data');

% retrieves the important fields from the parameter GUI
iRow = getTableCellSelection(handles.tableRefLog);
nwID = tData{iRow,1};

% retrieves the current branch ID
cBr = vObj.rObj.brData{vObj.getCurrentHeadInfo(headID),1};

% stashes any changes (if there are any modifications)
if vObj.rObj.isMod
    vObj.gfObj.gitCmd('stash'); 
    vObj.gfObj.gitCmd('stash-drop');
end

% --------------------------- %
% --- CHILD BRANCH UPDATE --- %
% --------------------------- %

% retrieves the list of current branches
cBr0 = cellfun(@(x)(x(3:end)),strsplit...
                            (vObj.gfObj.gitCmd('branch'),'\n')','un',0);

% determines the difference between the new and current ID
diffID = getCommitDifferences(vObj,nwID,headID);
if isempty(diffID)
    % case is user is moving to a later commit
    dateHead = vObj.gfObj.gitCmd('get-commit-date',headID);
    
    % determines any branch commits post the head commit
    cmStr = sprintf('1st Commit (Branched from ''%s'')',cBr);
    nwBrStr0 = vObj.gfObj.gitCmd('reflog-grep-since',cmStr,dateHead);    
    if ~isempty(nwBrStr0)
        % if there are such branches, then determine their commit IDs
        nwBrID = cellfun(@(x)(regexp(x,'\w+','match','once')),...
                              strsplit(nwBrStr0,'\n')','un',0);
        isAdd = true(length(nwBrID),1);
        
        % determines if there have been any branch deletions post the head
        delStr = 'commit: Branch Delete';
        delBrStr0 = vObj.gfObj.gitCmd('reflog-grep-since',delStr,dateHead);
        if ~isempty(delBrStr0)
            % if so, then determine if these deleted branches match the
            % branches that were added (if so, then no need to re-add)
            delBrInfo = cellfun(@(x)(regexp(x,'\w+','match')),...
                                   strsplit(delBrStr0,'\n')','un',0);            
            delBrID = cellfun(@(x)(x{end}),delBrInfo,'un',0);
            
            %
            for i = 1:length(delBrID)
                cIDBr0 = vObj.gfObj.gitCmd('branch-commits',delBrID{i});
                cIDBr = strsplit(cIDBr0,'\n');
                
                for j = 1:length(nwBrID)
                    if any(startsWith(cIDBr,nwBrID{j}))
                        isAdd(j) = false;
                    end
                end
            end
        end
        
        % determines the commit ID groups
        brGrp = groupCommitID(vObj.gfObj,1);
        
        % adds on any branches that were never properly deleted
        for iBr = find(isAdd(:)')
            brName = sprintf('other-restored%i',iBr);
            iM = cellfun(@(x)(any(strcmp(x,nwBrID{iBr}))),brGrp);            
            vObj.gfObj.gitCmd('create-local-detached',brName,brGrp{iM}{1});
        end
    end
    
    % checks out the main local branch
    vObj.gfObj.checkoutBranch('local',cBr)
    
else
    % case is user is moving to an earlier commit        
    
    % determines if any commits being removed are the branch nodes for any
    % children nodes (if so, then remove the child branches)
    pCID = field2cell(vObj.rObj.gHist,'pCID');
    for iBr = find(cellfun(@(x)(any(strcmp(diffID,x))),pCID)')
        % determines if the branch for removal is in the current list
        cBrRmv = vObj.rObj.brData{iBr,1};
        if any(strcmp(cBr0,cBrRmv))
            % determines if there are any merges on the branch
            mCID = vObj.rObj.gHist(iBr).brInfo.mCID;
            hasMerge = any(~cellfun(@isempty,mCID));
            
            % deletes the local and remote branches
            vObj.gfObj.gitCmd('delete-local',cBrRmv,hasMerge)
            vObj.gfObj.gitCmd('delete-remote',cBrRmv)           
        end
    end
end

% --------------------------- %
% --- COMMIT RESET UPDATE --- %
% --------------------------- %

% hard-resets to the selected history point
vObj.gfObj.resetLogPoint(nwID)
pause(0.05);

% recreates the repository structure
vObj.rObj = RepoStructure();

% updates the head node and version object
setappdata(hFig,'vObj',vObj);
setappdata(hFig,'headID',nwID);
setappdata(hFig,'isChange',true);

% updates the table background colours
bgCol = ones(size(tData,1),3); 
bgCol(strcmp(tData(:,1),nwID),:) = [1,0.5,0.5]; 
set(handles.tableRefLog,'BackgroundColor',bgCol)

% deletes the loadbar
delete(h);

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

% retrieves the main GUI handle
hFig = handles.figRefLog;
hRLP = getappdata(hFig,'hRLP');
vObj = getappdata(hFig,'vObj');
isChange = getappdata(hFig,'isChange');

% deletes the RefLog GUIs and makes the main GUI visible again
delete(hRLP)
delete(handles.figRefLog)

% if there was a change then update the main gui
if isChange
    feval(vObj.postRefLogFcn)
end

% makes the main GUI visible again
setObjVisibility(vObj.hFig,1)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     OBJECT CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when selected cell(s) is changed in tableRefLog.
function tableRefLog_CellSelectionCallback(hObject, eventdata, handles)

% if no indices are selected, then exit the function
if isempty(eventdata.Indices)
    return
end 

% initialisations
col = 'rk';
iRow = eventdata.Indices(1);

% only rows with a new commit ID w
Data = get(hObject,'Data');
headID = getappdata(handles.figRefLog,'headID');
isNew = ~strcmp(Data{iRow,1},headID);

% updates the selected row text and reset history menu enabled props
set(handles.textCurrSel,'string',sprintf('Row #%i',iRow),...
                        'foregroundcolor',col(1+isNew),'enable','on');
setObjEnable(handles.textCurrSelL,1)                    
setObjEnable(handles.menuResetHist,isNew)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                          OTHER FUNCTIONS                          %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%           
%%%%    GUI OBJECT PROPERTY FUNCTIONS    %%%%           
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- initialises the GUI object properties
function initGUIObjects(handles,vObj)

% makes the main GUI invisible
setObjVisibility(vObj.hFig,0)
setObjEnable(handles.menuResetHist,0)

% sets the reference log panel title
cBr = vObj.getCurrentBranchName();
pLbl = sprintf('REFERENCE LOG HISTORY (%s)',cBr);
set(handles.panelRefLog,'Title',pLbl)

% updates the head ID flag
iBr = vObj.getCurrentHeadInfo();
headID = vObj.rObj.gHist(iBr).brInfo.CID{1};
setappdata(handles.figRefLog,'headID',headID);

% creates the reflog explorer table
createRefLogExplorerTable(handles)

% --- creates the GitVersion explorer tree
function createRefLogExplorerTable(handles)

% object retrieval
hFig = handles.figRefLog;
hTable = handles.tableRefLog;
vObj = getappdata(hFig,'vObj');

% other initialisations
bgCol = [];
cWid = {90,150,500};
gpat = '<%h> <%as> <%s> <%at>';
colStr = {'Commit ID','Action Type','Reference Message'};

% retrieves the table data
Data = get(handles.tableRefLog,'Data');
if ~isempty(Data)
    % if there is data, then reset the table
    set(hTable,'Data',[])
end

% creates the loadbar
h = ProgressLoadbar('Updating Reference Log Table...');

% determines the matching commit group for each branch, and determines the
% grouping that belongs to the current branch
brGrp = groupCommitID(vObj.gfObj);
iBr = vObj.getCurrentHeadInfo();
indM = cellfun(@(x)(any(strcmp(x,vObj.rObj.brData{iBr,2}))),brGrp);

% retireves all info from the head commits reflog
tData = vObj.gfObj.getAllCommitInfo('HEAD',gpat);

% retrieves the reference log commit IDs
if ~isempty(tData)
    % if there is data, then sort by date
    if any(indM)
        ii = cellfun(@(x)(find(strcmp(tData(:,1),x))),brGrp{indM});
        tData = tData(ii,:);
        [~,iS] = sort(cellfun(@str2double,tData(:,end)),'descend');
        tData = tData(iS,1:3);

        % sets the table background colour
        bgCol = ones(size(tData,1),3);
        headID = vObj.rObj.gHist(iBr).brInfo.CID{1};
        bgCol(strcmp(tData(:,1),headID),:) = [1,0.5,0.5];
    else
        % otherwise reduce the arrays
        tData = tData(:,1:3);
    end
end
                    
% updates the table and resizes
set(hTable,'Data',tData,'ColumnName',colStr,'ColumnWidth',cWid)
if ~isempty(bgCol)
    set(hTable,'BackgroundColor',bgCol)   
end

% automatically resizes the table columns                    
autoResizeTableColumns(hTable);        

% deletes the loadbar
delete(h)

% --- determines the commit ID differences between cID1 and cID2
function diffID = getCommitDifferences(vObj,cID1,cID2)

% compares the 2 commits
diffID0 = vObj.gfObj.gitCmd('compare-commit',cID1,cID2);
if isempty(diffID0)
    % if the first commit is older, then exit with an empty array
    diffID = [];
else
    % otherwise, retrieve the commit IDs
    diffID = cellfun(@(x)(x(3:end)),strsplit(diffID0,'\n')','un',0);
end