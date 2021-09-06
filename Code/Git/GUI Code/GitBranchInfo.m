function varargout = GitBranchInfo(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GitBranchInfo_OpeningFcn, ...
                   'gui_OutputFcn',  @GitBranchInfo_OutputFcn, ...
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

% --- Executes just before GitBranchInfo is made visible.
function GitBranchInfo_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for GitBranchInfo
handles.output = hObject;

% makes the version GUI invisible
vObj = varargin{1};

% sets the input arguments
setappdata(hObject,'vObj',vObj)
setObjVisibility(vObj.hFig,0);

% creates a progress loadbar
h = ProgressLoadbar('Finding All Repository Branches...');

% initialises the GUI objects
initGUIObjects(handles,vObj)

% deletes the loadbar
delete(h);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GitBranchInfo wait for user response (see UIRESUME)
% uiwait(handles.figBranchInfo);

% --- Outputs from this function are returned to the command line.
function varargout = GitBranchInfo_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     FIGURE CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when user attempts to close figBranchInfo.
function figBranchInfo_CloseRequestFcn(hObject, eventdata, handles)

% runs the exit file menu item
menuExit_Callback(handles.menuExit, [], handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                      MENU CALLBACK FUNCTIONS                      %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

% retrieves the main GUI object handle
hFig = handles.figBranchInfo;
vObj = getappdata(hFig,'vObj');

% deletes the GUI
delete(hFig)

% makes the main GUI invisible
setObjVisibility(vObj.hFig,1)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     OBJECT CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when selected cell(s) is changed in tableBranchDel.
function tableBranchDel_CellSelectionCallback(hObject, eventdata, handles)

% enables the restore branch button
setObjEnable(handles.buttonRestoreBranch,1)

% --- Executes on button press in buttonRestoreBranch.
function buttonRestoreBranch_Callback(hObject, eventdata, handles)

% retrieves the deleted listbox strings/values
hTable = handles.tableBranchDel;
dData = get(hTable,'Data');
iSel = getTableCellSelection(hTable);

% prompt the user if they want to restore the deleted branch
qStr = sprintf('Are you sure you want to restore "%s"?',dData{iSel,1});
uChoice = questdlg(qStr,'Restore Deleted Branch?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if the user cancelled, then exit the function
    return
end

% retrieves the main GUI object handle and commit ID#s;
hFig = handles.figBranchInfo;
vObj = getappdata(hFig,'vObj'); 

% restores the deleted branch
vObj.restoreDeletedBranch(dData{iSel,1},dData{iSel,2})

% updates the current branch list
cStr = get(handles.listBranchCurr,'string');
set(handles.listBranchCurr,'string',[cStr;dData{iSel,1}])

% removes the restored branch from the table
ii = 1:size(dData,1) ~= iSel;
set(hTable,'Data',dData(ii,:))
setObjEnable(hObject,sum(ii)>0)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                          OTHER FUNCTIONS                          %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- initialises the GUI objects
function initGUIObjects(handles,vObj)

% initialisations
tData = [];
cStr = 'commit: Branch Delete';

% sets the current branch listbox values
cBrStr = cell2cell(vObj.bStrGrp);
set(handles.listBranchCurr,'string',cBrStr,...
                           'max',2,'value',[],'enable','inactive')

% determines if there are any deleted branches
delBrInfo0 = vObj.gfObj.gitCmd('reflog-grep','HEAD',cStr);
if isempty(delBrInfo0)
    % if no deleted branches, then disable the branch restore button
    setObjEnable(handles.buttonRestoreBranch,0)
    
else
    % retrieves the deleted branch information messages
    delBrInfo = strsplit(delBrInfo0,'\n')';
    brDelStr = 'commit: Branch Delete';
    isMsg = cellfun(@(x)(strContains(x,brDelStr)),delBrInfo) & ...
                        ~strContains(delBrInfo,'fatal:');    
    delBrInfo = delBrInfo(isMsg);
    
    % memory allocation
    nBr = length(delBrInfo);
    [cID,delBr] = deal(cell(nBr,1));
    
    % retrieves the names/last commit ID#s of the deleted branches
    isOK = false(nBr,1);
    for i = 1:nBr
        msgInfo0 = regexp(delBrInfo{i}, '[^()]*', 'match');
        msgInfo = strsplit(msgInfo0{2});
        [delBr{i},cID{i}] = deal(msgInfo{1},msgInfo{end}(1:7));
        
        % determines if the commit 
        pCID = strsplit(vObj.gfObj.gitCmd('get-commit-parent',cID{i}));
        if length(pCID) == 2 && ~strcmp(pCID{1},'error:')
            isOK(i) = any(strcmp(vObj.rObj.bInfo(:,1),pCID{2}(1:7)));
        end
    end
    
    % determines if the deleted branches is not included within the current
    % branch name list
    isOK = isOK & cellfun(@(x)(~any(strcmp(cBrStr,x))),delBr);
    if any(isOK)    
        % sets the listbox strings and commit ID strings
        tData = [delBr(isOK),cID(isOK)];            
    else
        % if no deleted branches, then disable the branch restore button
        setPanelProps(handles.panelBranchDel,0)
        setObjEnable(handles.buttonRestoreBranch,0)
    end
end

% auto-resizes the table
set(handles.tableBranchDel,'Data',tData)    
autoResizeTableColumns(handles.tableBranchDel);
