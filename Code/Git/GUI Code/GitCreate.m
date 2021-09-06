function varargout = GitCreate(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GitCreate_OpeningFcn, ...
                   'gui_OutputFcn',  @GitCreate_OutputFcn, ...
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

% --- Executes just before GitCreate is made visible.
function GitCreate_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for GitCreate
handles.output = hObject;

% sets the input arguments into the GUI
vObj = varargin{1};

% sets the important structs into the GUI
setappdata(hObject,'vObj',vObj)
setappdata(hObject,'iData',initDataStruct())

% initialises the GUI object properties
initGUIObjects(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GitCreate wait for user response (see UIRESUME)
uiwait(handles.figGitCreate);

% --- Outputs from this function are returned to the command line.
function varargout = GitCreate_OutputFcn(hObject, eventdata, handles) 

% global variables
global iData

% returns the information data struct
varargout{1} = iData;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     FIGURE CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when user attempts to close figGitCreate.
function figGitCreate_CloseRequestFcn(hObject, eventdata, handles)

% prompts the user if they wish to cancel the branch creation
uChoice = questdlg('Are you sure you want to cancel the branch creation?',...
                   'Cancel Branch Creation?','Yes','No','Yes');
if strcmp(uChoice,'Yes')
    % if so, then cancel branch creation
    pushCancel_Callback(handles.pushCancel, [], handles)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     OBJECT CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    PARAMETER CALLBACKS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on selection change in popupParentBranch.
function popupParentBranch_Callback(hObject, eventdata, handles)

% retrieves the list strings/selected index
[lStr,iSel] = deal(get(hObject,'string'),get(hObject,'value'));

% resets the parent branch string in the data struct
iData = getappdata(handles.figGitCreate,'iData');
iData.pBr = lStr{iSel};
setappdata(handles.figGitCreate,'iData',iData)

% --- Executes on selection change in popupBranchType.
function popupBranchType_Callback(hObject, eventdata, handles)

% retrieves the list strings/selected index
[lStr,iSel] = deal(get(hObject,'string'),get(hObject,'value'));

% resets the data struct and deletes the GUI
iData = getappdata(handles.figGitCreate,'iData');
iData.bType = lStr{iSel};
setappdata(handles.figGitCreate,'iData',iData)

% updates the parent branches popup menu
updateParentBranches(handles)

% --- Executes on updating editBranchName.
function editBranchName_Callback(hObject, eventdata, handles)

% retrieves the data struct
hFig = handles.figGitCreate;
iData = getappdata(hFig,'iData');

% retrieves the new string and checks to see if it is valid
nwStr = get(hObject,'string');
if isempty(nwStr); return; end

% determines if the string is valid
[ok,mStr] = chkDirString(nwStr,1);
if ok && (strcmp(nwStr(1),'.') || strcmp(nwStr(1),'-'))
    % if valid, but starts with ".", then set an error message
    ok = 0;
    mStr = 'Error! Branch string can''t start with "." or "-".';
end

% updates/reverts the branch name depending on whether it is valid
if ok
    % updates the branch name string
    iData.bName = nwStr;
    setappdata(hFig,'iData',iData);
else
    % otherwise, output the error and revert back to the last valid value
    waitfor(errordlg(mStr,'Branch Name Error','modal'))
    set(hObject,'string',iData.bName)
end

% updates the enabled properties
set(hObject,'string',iData.bName)
setObjEnable(handles.pushCreate,~isempty(iData.bName))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    CONTROL BUTTON CALLBACKS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in pushCreate.
function pushCreate_Callback(hObject, eventdata, handles)

% global variables
global iData

% resets the data struct and deletes the GUI
hFig = handles.figGitCreate;
vObj = getappdata(hFig,'vObj');
iData = getappdata(hFig,'iData');

% checks the password/brnac
[mStr,tStr] = vObj.checkBranchData(iData);
if isempty(mStr)
    % otherwise, delete the GUI
    delete(hFig)    
else
    % if incorrect, then output a message to screen
    waitfor(msgbox(mStr,tStr,'modal'))    
    figure(hFig)
end

% --- Executes on button press in pushCancel.
function pushCancel_Callback(hObject, eventdata, handles)

% global variables
global iData

% resets the data struct and deletes the GUI
iData = [];
delete(handles.figGitCreate)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     OBJECT CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- initialises the GUI objects
function initGUIObjects(handles)

% retrieves the data struct
hFig = handles.figGitCreate;
vObj = getappdata(hFig,'vObj');
iData = getappdata(hFig,'iData');

% retrieves the branch group types
bGrpType = vObj.bGrpType;
[iBr,iCm] = vObj.getCurrentHeadInfo();
[cBr,isDetached] = deal(vObj.rObj.brData{iBr,1},iCm>1);

% sets the branch type strings
if isDetached
    if strcmp(cBr,'master')
        % branch is detached from master (
        iGrpT = find(strcmp(bGrpType,'develop')):length(bGrpType);
        
    elseif startsWith(cBr,'develop')        
        % branch is detached from develop (
        iGrpT = [find(strcmp(bGrpType,'feature'));...
                 find(strcmp(bGrpType,'other'))];
        
    elseif startsWith(cBr,'feature') || startsWith(cBr,'hotfix')
        % branch is detached from either a feature or hotfix branch 
        % (only able to create other type branches
        iGrpT = find(strcmp(bGrpType,'other'));
               
    else
        % not able to create a branch from other type branches
        eStr = 'Not able to create a new branch from an other type branch';
        waitfor(errordlg(eStr,'Invalid Branch Creation','modal'))
        
        % exits the GUI
        pushCancel_Callback(handles.pushCancel, [], handles)
    end
    
    % sets the parent branch (and disables the string)
    iData.pBr = cBr;
    set(handles.popupParentBranch,'string',{cBr},'enable','off')
else
    % case is the current branch is not detached
    iGrpT = 2:length(bGrpType);    
end
    
% sets the parent branch list strings
lStr = bGrpType(iGrpT);
set(handles.popupBranchType,'String',lStr(:),'Value',1);

% sets the branch type
iData.bType = lStr{1};

% updates the parameter data structs/detached flag into the GUI
setappdata(hFig,'iData',iData)
setappdata(hFig,'isDetached',isDetached)

% updates the parent branch
updateParentBranches(handles)

% disables the creation button
setObjEnable(handles.pushCreate,0)

% --- updates the parent branch popup menu strings
function updateParentBranches(handles)

% if the head is detached, then the parent branch is fixed (so exit)
hFig = handles.figGitCreate;
if getappdata(hFig,'isDetached')
    return
end

% initialisations
eStr = {'off','on'};
hPopupBr = handles.popupBranchType;
vObj = getappdata(hFig,'vObj');

% retrieves the currently selected branch string
lStrG = get(hPopupBr,'String');
iSelG = get(hPopupBr,'Value');

% determines the parent branch types based on the branch type
switch lStrG{iSelG}
    case ('develop')
        % case is a develop branch (can only branch from master branch)
        lStr = vObj.bStrGrp{1};
        
    case ('feature')
        % case is a feature branch (can only branch from develop branches)
        lStr = vObj.bStrGrp{strcmp(vObj.bGrpType,'develop')};
        
    case ('hotfix')
        % case is a hot-fix branch (can only branch from master branch)
        lStr = vObj.bStrGrp{1};
        
    case ('other')
        % case is an other branch (can branch from all but hotfix branches)
        iGrpT = strcmp(vObj.bGrpType,'main') | ...
                strcmp(vObj.bGrpType,'develop') | ...
                strcmp(vObj.bGrpType,'feature');
        lStr = cell2cell(vObj.bStrGrp(iGrpT));
end

% updates the parent branch properties
set(handles.popupParentBranch,'string',lStr(:),'value',1,...
                              'enable',eStr{1+(length(lStr)>1)})

% resets the parent branch string in the data struct
iData = getappdata(hFig,'iData');                          
iData.pBr = lStr{1};
setappdata(hFig,'iData',iData)                          
                          
% --- initialises the data struct
function iData = initDataStruct()

% initialises the data struct
iData = struct('bType',[],'pBr',[],'bName',[]);
