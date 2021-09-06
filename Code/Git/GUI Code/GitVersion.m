function varargout = GitVersion(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GitVersion_OpeningFcn, ...
                   'gui_OutputFcn',  @GitVersion_OutputFcn, ...
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

% --- Executes just before GitVersion is made visible.
function GitVersion_OpeningFcn(hObject, eventdata, handles, varargin)

% % global variables
% global isDeleting
% isDeleting = false;

% Choose default command line output for GitVersion
handles.output = hObject;

% sets the input arguments
hFig = varargin{1};
setObjVisibility(hFig,0)

% initialises the data struct and other important fields
setappdata(hObject,'hFig',hFig)

% % sets the function handle
% setappdata(hObject,'updateFcn',@panelVerFilt_SelectionChangedFcn)

% initialises the version class object
verObj = GitVerClass(hObject);
if verObj.ok
    % Update handles structure
    guidata(hObject, handles);

    % makes the GUI visible
    setappdata(hObject,'verObj',verObj)
else
    % makes the main GUI visible again
    set(hFig,'visible','on')
    
    % deletes the current GUI and exits
    delete(hObject)
    return
end

% UIWAIT makes GitVersion wait for user response (see UIRESUME)
% uiwait(hFig);

% --- Outputs from this function are returned to the command line.
function varargout = GitVersion_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = [];

% ----------------------------------------------------------------------- %
%                        FIGURE CALLBACK FUNCTIONS                        %
% ----------------------------------------------------------------------- %

% --- Executes when user attempts to close figGitVersion.
function figGitVersion_CloseRequestFcn(hObject, eventdata, handles)

% runs the GUI exit function
menuExit_Callback(handles.menuExit, [], handles)

% ----------------------------------------------------------------------- %
%                         MENU CALLBACK FUNCTIONS                         %
% ----------------------------------------------------------------------- %

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

% global variables
global mainProgDir

% prompts the user if they wish to close the tracking gui
uChoice = questdlg('Are you sure you want to close the Git Version GUI?',...
                   'Close Git Version GUI?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if the user cancelled, then exit
    return
end

% retrieves the main GUI handle
hFig = getappdata(handles.figGitVersion,'hFig');

% removes the environment variable
gitEnvVarFunc('remove','GIT_DIR')

% changes the directory back down to the main directory and closes the GUI
cd(mainProgDir)
delete(handles.figGitVersion)

% sets the main GUI visible again
set(hFig,'visible','on')

% ----------------------------------------------------------------------- %
%                        OBJECT CALLBACK FUNCTIONS                        %
% ----------------------------------------------------------------------- %

% ------------------------------------------------- %
%       VERSION FILTER PANEL OBJECT CALLBACKS       %
% ------------------------------------------------- %

% --- Executes on button press in buttonUpdateFilt.
function buttonUpdateFilt_Callback(hObject, eventdata, handles)

% updates the commit history details
if isa(eventdata,'ProgressDialog')
    updateCommitHistoryDetails(handles,1)
else
    updateCommitHistoryDetails(handles)
end

% ----------------------------------------------------- %
%       VERSION DIFFERENCE PANEL OBJECT CALLBACKS       %
% ----------------------------------------------------- %

% --- Executes on button press in buttonUpdateVer.
function buttonUpdateVer_Callback(hObject, eventdata, handles)

% creates the load bar
h = ProgressLoadbar('Updating Branch Version...');    

% retrieves the object handles/data structs
hFig = handles.figGitVersion;
GB = getappdata(hFig,'GitBranch');
GF = getappdata(hFig,'GitFunc');
hTree = getappdata(hFig,'hTree');
% iCurr = getappdata(hFig,'iCurr');
gHistAll = getappdata(hFig,'gHistAll');

% resets the directory to the repository directory current directory
cDir0 = pwd;
cd(GF.gDirP);

% % if the current branch is the local-working branch, then change to master
% isLW = strcmp(cBr,localBr);
% if isLW
%     cBr = GB.updateLocalWorkingBranch();    
% end

% updates the repository information
updateRepoInfo(GF.gName);

% retrieves the version selection index 
jTree = get(hTree.getTree);
hNodeNw = hTree.SelectedNodes(1);
hNodePr = getSelectedNode(hTree.getRoot);

% checks if there are any branch modifications and is not detached. if so
% prompt how the user wants to handle it
uStatus = GB.checkBranchModifications(h);
switch uStatus
    case 1
        % if the user chose to cancel, then exit the function
        cd(cDir0)
        return
        
    case 2
        % determines if current branch is a local-working branch (for
        % non-developers only)
        if GF.uType > 0
            % if the commit being ignored is an uncommited node, then
            % remove it from explorer tree
            hNodeS = getSelectedNode(hTree.getRoot);            
            if strContains(hNodeS.getName,'Uncommited Changes*')
                % retrieves the parent                 
                hNodeP = hNodeS.getParent;
                                
                % removes the node from the history explorer tree
                hNodeP.remove(hNodeS);
                hTree.reloadNode(hNodeP);
                hTree.repaint;   
                
                % flag that there is no previous node
                hNodePr = [];
            end
        end
        
        % if the user chose to ignore, then force reset the commit
        cID = GB.GitFunc.gitCmd('commit-id');
        GB.GitFunc.gitCmd('force-checkout',cID);
end

% retrieves the git history struct for the current branch
cBr = GF.getCurrentBranch;
if GF.uType == 0
    % case is for developers    
    iSel = jTree.SelectionRows;    
    gHist = eval(sprintf('gHistAll.%s',strrep(cBr,'-','')));
    gHistNw = gHist(iSel);   
    
    % checkouts the version corresponding to the selected tree node
    if iSel == 1
        % if the latest commit, then checkout the main branch
        GB.checkoutBranch('remote',cBr)

    else
        % otherwise, checkout the later version via the commit ID
        GB.checkoutBranch('version',gHistNw.ID)
    end
else
    % case is for users    
    iSel = hNodeNw.getUserObject;
    [gHistNw,bStr,iSel] = getUserGitHistory(hFig,iSel);
    
    % checks out the branch (if the current/new branches are different)
    if ~strcmp(bStr,cBr)
        GF.gitCmd('stash-save','dummy');        
        if iSel(end) == 1   
            % if checking out the first item, then reset to the branch head
            GF.gitCmd('checkout-local',bStr);
        else
            % otherwise, checkout the later version via the commit ID
            GB.checkoutBranch('version',gHistNw.ID)            
        end

        % removes the item from the list
        iList = GF.detStashListIndex('dummy');
        if ~isempty(iList)
            GF.gitCmd('stash-drop',iList-1)
        end        
        
    else
        if iSel(end) == 1   
            % if checking out the first item, then reset to the branch head
            GF.gitCmd('checkout-local',bStr);
        else
            % otherwise, checkout the later version via the commit ID
            GB.checkoutBranch('version',gHistNw.ID)            
        end       
    end        
end

% updates the current version
updateVersionDetails(handles,gHistNw,iSel(1))
updateDiffObjects(handles,splitCodeDiff(''))
set(handles.tableCodeLine,'data',[])
setObjEnable(hObject,'off')

% resets the tree-node colour scheme
updateTreeNode(hNodePr,'k')
updateTreeNode(hNodeNw,'r')
hTree.repaint

% changes the directory back to the original
cd(cDir0)
