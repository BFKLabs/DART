function varargout = GitRebase(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GitRebase_OpeningFcn, ...
                   'gui_OutputFcn',  @GitRebase_OutputFcn, ...
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


% --- Executes just before GitRebase is made visible.
function GitRebase_OpeningFcn(hObject, ~, handles, varargin)

% Choose default command line output for GitRebase
handles.output = hObject;

% sets the input arguments
setappdata(hObject,'hFigM',varargin{1});

% creates the git rebase class object
setappdata(hObject,'rbObj',GitRebaseClass(hObject));

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GitRebase wait for user response (see UIRESUME)
% uiwait(handles.figGitRebase);


% --- Outputs from this function are returned to the command line.
function varargout = GitRebase_OutputFcn(~, ~, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes when user attempts to close figGitRebase.
function figGitRebase_CloseRequestFcn(~, ~, handles)

% Hint: delete(hObject) closes the figure
buttonAbortRebase_Callback(handles.buttonAbortRebase, [], handles)


% --- Executes on button press in buttonContRebase.
function buttonContRebase_Callback(~, ~, handles)

% object retrieval
hFig = handles.figGitRebase;
rbObj = getappdata(hFig,'rbObj');

% prompts the user if they want to continue
qStr = 'Are you sure you want to continue with the commit rebase?';
uChoice = questdlg(qStr,'Continue Rebase?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    return
end

% creates the loadbar 
h = ProgressLoadbar('Performing Initial Rebase...');

% performs the final rebase
rbStrF = sprintf('"%s"',rbObj.getScriptString);
rbObj.gfObj.gitCmd('set-global-config','sequence.editor',rbStrF)
pause(0.1);
rbObj.gfObj.gitCmd('rebase-interactive',rbObj.cIDP);

% determines if there are any merge conflict/differences
dcFiles = rbObj.gfObj.getMergeDCFiles(); 
if ~isempty(dcFiles.Conflict)
    % ignore any differences (shouldn't be any?)
    dcFiles.Diff = [];
    setObjVisibility(h.Control,0);
    
    % outputs a message to screen indicating a merge is reqd
    mStr0 = 'Merge conflicts'; 
    mStr = sprintf(['%s exist between the branches.\n',...
                    'You will need to resolve these before ',...
                    'completing the final merge.'],mStr0);
    waitfor(msgbox(mStr,'Merge Conflicts Detected','modal'))           

    % if so, then prompt the user to manually alter the files 
    % until either they cancel or successfully merged      
    setObjVisibility(hFig,0)
    isCont = GitMerge(rbObj.vObj,dcFiles);     
    if isCont
        % if the user resolved the conflicts, then continue the rebase
        setObjVisibility(h.Control,1);
        rbObj.gfObj.gitCmd('set-global-config','rebase.backend','apply')
        pause(0.1);
        
        rbObj.gfObj.gitCmd('rebase-continue')
        rbObj.gfObj.gitCmd('unset-global-config','rebase.backend')
    else
        % deletes the loadbar
        try; delete(h); end
        
        % if the user cancelled, then abort the rebase
        rbObj.gfObj.gitCmd('rebase-abort')
        
        % makes the gui visible again
        setObjVisibility(hFig,1)         
        return
    end
end

% clears the sequence editor flag
rbObj.gfObj.gitCmd('unset-global-config','sequence.editor')

% resets the main GUI objects
rbObj.vObj.resetGUIObjects(h)

% force-pushes the results
h.StatusMessage = 'Pushing Changes To Remote...';
rbObj.gfObj.gitCmd('force-push',1);

% deletes the loadbar/figure
delete(h);
delete(hFig);

% --- Executes on button press in buttonAbortRebase.
function buttonAbortRebase_Callback(~, ~, handles)

% object retrieval
hFig = handles.figGitRebase;
rbObj = getappdata(hFig,'rbObj');

% prompts the user if they want to abort
qStr = 'Are you sure you want to abort the commit rebase?';
uChoice = questdlg(qStr,'Abort Rebase?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    return
end

% clears the sequence editor flag
rbObj.gfObj.gitCmd('unset-global-config','sequence.editor')

% deletes the figure
delete(hFig);
