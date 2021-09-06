function varargout = GitHotfix(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GitHotfix_OpeningFcn, ...
                   'gui_OutputFcn',  @GitHotfix_OutputFcn, ...
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

% --- Executes just before GitHotfix is made visible.
function GitHotfix_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for GitHotfix
handles.output = hObject;

% sets the input arguments into the GUI
vObj = varargin{1};

% opens the loadbar figure
h = ProgressLoadbar('Initialising Hot-Fix Branch Information...');

% sets the important structs into the GUI
setappdata(hObject,'iData',initDataStruct)
setappdata(hObject,'vObj',vObj)

% initialises the GUI object properties
initGUIObjects(handles,vObj)

% closes the loadbar figure
delete(h)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GitHotfix wait for user response (see UIRESUME)
uiwait(handles.figGitHotfix);

% --- Outputs from this function are returned to the command line.
function varargout = GitHotfix_OutputFcn(hObject, eventdata, handles) 

% global variables
global iData

% returns the information data struct
varargout{1} = iData;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     FIGURE CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when user attempts to close figGitHotfix.
function figGitHotfix_CloseRequestFcn(hObject, eventdata, handles)

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

% --- Executes on updating editBranchName.
function editBranchName_Callback(hObject, eventdata, handles)

% retrieves the data struct
hFig = handles.figGitHotfix;
hfBr = getappdata(hFig,'hfBr');
iData = getappdata(hFig,'iData');

% retrieves the new string and checks to see if it is valid
nwStr = get(hObject,'string');
if isempty(nwStr); return; end

% determines if the string is valid
[ok,mStr] = chkDirString(nwStr,1);
if ok 
    if strcmp(nwStr(1),'.') || strcmp(nwStr(1),'-')
        % if valid, but starts with ".", then set an error message
        ok = 0;
        mStr = 'Error! Branch string can''t start with "." or "-".';
        
    elseif any(strcmp(hfBr,nwStr))
        % case is there is an existing hot-fix branch with the same name
        ok = 0;
        mStr = sprintf(['Error! The hot-fix branch name ',...
                        '"%s" already exists.'],nwStr);
        
    end
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
setEnableProps(handles)

% --- Executes on updating editUserName.
function editUserName_Callback(hObject, eventdata, handles)

% retrieves the data struct
hFig = handles.figGitHotfix;
iData = getappdata(hFig,'iData');

% retrieves the new string and checks to see if it is valid
nwStr = get(hObject,'string');
if isempty(nwStr); return; end

% determines if the string is valid
[ok,mStr] = chkDirString(nwStr,1);

% updates/reverts the branch name depending on whether it is valid
if ok
    % updates the branch name string
    iData.uName = nwStr;
    setappdata(hFig,'iData',iData);
else
    % otherwise, output the error and revert back to the last valid value
    waitfor(errordlg(mStr,'Branch Name Error','modal'))
    set(hObject,'string',iData.uName)
end

% updates the enabled properties
setEnableProps(handles)

% --- Executes on key press with focus on editPassword.
function editPassword_KeyPressFcn(hObject, eventdata, handles)

% retrieves the data struct
jEdit = findjobj(hObject);
hFig = handles.figGitHotfix;
iData = getappdata(hFig,'iData');

% if not a valid character, then exit the function
switch eventdata.Key
    case 'backspace'
        % ensures the cursor is at the end of the line
        pause(0.01)
        nChar = jEdit.getDocument.getLength;
        iData.pWordHF = iData.pWordHF(1:nChar);
    otherwise
        % case is any other key
        if isempty(eventdata.Character)
            % if a valid character was not set, then exit
            return
        elseif length(double(eventdata.Key)) ~= 1
            % if a valid character was not set, then exit
            return            
        end
        
        % updates the password
        if isempty(iData.pWordHF)
            % password is empty, so set as the new key
            iData.pWordHF = eventdata.Character;
        else
            % otherwise, append the new character
            iData.pWordHF = [iData.pWordHF,eventdata.Character];
        end
end

% updates the password
pWordStr = repmat('*',1,length(iData.pWordHF));

% HACK SOLUTION - it seems taking focus off the gui causes the java
% exception error to stop appearing?!
disp(' '); clc;

% ensures the cursor is at the end of the line
jEdit.setText(pWordStr);
jEdit.setCaretPosition(length(iData.pWordHF))
jEdit.repaint()

% updates the data struct into the GUI
setappdata(hFig,'iData',iData)
setEnableProps(handles)

% --- Executes on updating editCommitMsg.
function editCommitMsg_Callback(hObject, eventdata, handles)

% initialisations
hFig = handles.figGitHotfix;

% updates the commit message string
iData = getappdata(hFig,'iData');
iData.cMsg = get(hObject,'string');
setappdata(hFig,'iData',iData);

% updates the enabled properties
setEnableProps(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    CONTROL BUTTON CALLBACKS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in pushCreate.
function pushCreate_Callback(hObject, eventdata, handles)

% global variables
global iData

% retrieves the important objects from the GUI
hFig = handles.figGitHotfix;
vObj = getappdata(hFig,'vObj');
iData = getappdata(hFig,'iData');

% checks the password/branch
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
delete(handles.figGitHotfix)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     OBJECT CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- initialises the GUI objects
function initGUIObjects(handles,vObj)

% initialisations
hfBr = [];
hFig = handles.figGitHotfix;
iData = getappdata(hFig,'iData');

% retrieves the remote branch strings
vObj.gfObj.gitCmd('set-origin');
rmBr = strsplit(vObj.gfObj.gitCmd('branch-remote'),'\n');
vObj.gfObj.gitCmd('rmv-origin');

% determines which of the remote branches are hot-fix branches
isHF = strContains(rmBr,'hotfix');
if any(isHF)
    % retrieves the existing hotfix branch names
    hfBr = cellfun(@(x)(x(17:end)),rmBr(isHF),'un',0);    
end

% updates the hot-fix branch names/commit message into the gui
set(handles.listHFBranches,'string',hfBr)
set(handles.editCommitMsg,'string',iData.cMsg)
setappdata(hFig,'hfBr',hfBr)

% disables the creation button
setObjEnable(handles.pushCreate,0)

% --- sets the enabled properties
function setEnableProps(handles)

% initialisations
iData = getappdata(handles.figGitHotfix,'iData');

% determines if all fields have been set (if so then enable create button)
isEnable = ~isempty(iData.bName) && ...
           ~isempty(iData.uName) && ...
           ~isempty(iData.pWordHF) && ...
           ~isempty(iData.cMsg);
       
% sets the enabled properties of the create button        
setObjEnable(handles.pushCreate,isEnable);

% --- initialises the data struct
function iData = initDataStruct()

% initialises the data struct
iData = struct('pBr','master','bType','hotfix',...
               'bName',[],'uName',[],'pWordHF',[],'cMsg',[]);
iData.cMsg = 'New Hot-Fix Branch';           
