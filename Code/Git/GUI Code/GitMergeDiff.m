function varargout = GitMergeDiff(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GitMergeDiff_OpeningFcn, ...
                   'gui_OutputFcn',  @GitMergeDiff_OutputFcn, ...
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

% --- Executes just before GitMergeDiff is made visible.
function GitMergeDiff_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global isUpdating isCont
[isUpdating,isCont] = deal(false);

% Choose default command line output for GitMergeDiff
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% sets the input variables
vObj = varargin{1};
dcFiles = varargin{2};
mBr = varargin{3};
cBr = varargin{4};

% sets the input arguments into the GUI
setappdata(hObject,'vObj',vObj)
setappdata(hObject,'dcFiles',dcFiles)
setappdata(hObject,'mBr',mBr)
setappdata(hObject,'cBr',cBr)
setappdata(hObject,'iRow',NaN(1,2))
setappdata(hObject,'cDir0',pwd)

% initialises the GUI objects
cd(vObj.gfObj.gDirP)
initGUIObjects(handles)

% UIWAIT makes GitMergeDiff wait for user response (see UIRESUME)
uiwait(handles.figGitMergeDiff);

% --- Outputs from this function are returned to the command line.
function varargout = GitMergeDiff_OutputFcn(hObject, eventdata, handles) 

% global variables
global isCont

% Get default command line output from handles structure
varargout{1} = isCont;

% --- Executes when user attempts to close figGitMergeDiff.
function figGitMergeDiff_CloseRequestFcn(hObject, eventdata, handles)

% runs the cancel function
buttonCancel_Callback(handles.buttonCancel, [], handles)

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    TABLE CALLBACK FUNCTIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when selected cell(s) is changed in tableConflict.
function tableConflict_CellSelectionCallback(hObject, eventdata, handles)

% global variables
global isUpdating

% sets the update flag depending on the value
if isUpdating
    % if in the process of updating, then exit
    return
else
    % otherwise, flag that an updating is occuring
    isUpdating = true;
end

% updates the row selection properties
if ~isempty(eventdata.Indices)    
    iRow = eventdata.Indices(1);
    updateSelectionProperties(hObject,iRow,1)
end
    
% flag that updating is complete
isUpdating = false;

% --- Executes when selected cell(s) is changed in tableDiff.
function tableDiff_CellSelectionCallback(hObject, eventdata, handles)

% global variables
global isUpdating

% sets the update flag depending on the value
if isUpdating
    % if in the process of updating, then exit
    return
else
    % otherwise, flag that an updating is occuring
    isUpdating = true;
end

% updates the row selection properties
if ~isempty(eventdata.Indices)    
    iRow = eventdata.Indices(1);
    updateSelectionProperties(hObject,iRow,2)
end
    
% flag that updating is complete
isUpdating = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    REVERT/REOLVE BUTTON FUNCTIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in buttonResolveConflict.
function buttonResolveConflict_Callback(hObject, eventdata, handles)

% retrieves the important objects from the GUI
hFig = handles.figGitMergeDiff;
vObj = getappdata(hFig,'vObj');
iRow = getappdata(hFig,'iRow');
dcFiles = getappdata(hFig,'dcFiles');

% creates the loadbar
h = ProgressLoadbar('Initiating Mergetool...');

% determines the merge conflict file to be resolved
cFile = dcFiles.Conflict(iRow(1));
mcFile = getFullFileName(cFile);

% runs the mergetool on the file
setObjVisibility(hFig,0)
vObj.gfObj.gitCmd('run-mergetool',mcFile);
setObjVisibility(hFig,1)

% deletes the loadbar
delete(h)

% determines if the merge conflict resolution was successful
fFile = fullfile(vObj.gfObj.gDirP,mcFile);
if strContains(fileread(fFile),'<<<< HEAD')
    % if the merge conflict was not resolved correctly, then output an
    % error message to screen
    eStr = ['Merge conflict was not resolved correctly. You will need ',...
            'to resolve all conflicts within this file before continuing.'];
    waitfor(errordlg(eStr,'Conflict Not Resolved!','modal'))
    
    % un-resolves the merge and exits the function
    vObj.gfObj.gitCmd('unresolve-merge',mcFile)
    return
end

% updates the table indicating the difference has been resolved
updateTableFlag(handles.tableConflict,iRow(1),true)

% disables/enables the resolve/revert buttons
resetButtonProps(hObject,handles.buttonRevertConflict)
setContButtonProps(handles)

% --- Executes on button press in buttonRevertConflict.
function buttonRevertConflict_Callback(hObject, eventdata, handles)

if ~ischar(eventdata)
    % prompt the user if they want to revert to original
    qStr = 'Are you sure you want to revert the file back to original?';
    uChoice = questdlg(qStr,'Undo Merge Conflict?','Yes','No','Yes');
    if ~strcmp(uChoice,'Yes')
        % if the user cancelled, then exit the function
        return
    end
end
    
% retrieves the important objects from the GUI
hFig = handles.figGitMergeDiff;
vObj = getappdata(hFig,'vObj');
iRow = getappdata(hFig,'iRow');
dcFiles = getappdata(hFig,'dcFiles');

% determines the merge conflict file to be reverted
cFile = dcFiles.Conflict(iRow(1));
mcFile = getFullFileName(cFile);

% un-resolves the merge and exits the function
vObj.gfObj.gitCmd('unresolve-merge',mcFile)

% updates the table indicating the difference has been resolved
updateTableFlag(handles.tableConflict,iRow(1),false)

% disables/enables the resolve/revert buttons
resetButtonProps(hObject,handles.buttonResolveConflict)
setObjEnable(handles.buttonCont,0)

% --- Executes on button press in buttonResolveDiff.
function buttonResolveDiff_Callback(hObject, eventdata, handles)

% retrieves the important objects from the GUI
hFig = handles.figGitMergeDiff;
vObj = getappdata(hFig,'vObj');
iRow = getappdata(hFig,'iRow');
dcFiles = getappdata(hFig,'dcFiles');

% creates the loadbar
h = ProgressLoadbar('Initiating Difftool...');

% determines the merge conflict file to be resolved
dFile = dcFiles.Diff(iRow(2));
mdFile = getFullFileName(dFile);
mdFileTmp = getTempDiffFileName(dFile);

% runs the difftool on the file
setObjVisibility(hFig,0)
vObj.gfObj.gitCmd('run-difftool',mdFile,mdFileTmp);
setObjVisibility(hFig,1)

% deletes the loadbar
delete(h)

% updates the table indicating if the difference has been resolved
dStr = vObj.gfObj.gitCmd('diff-no-index',mdFile,mdFileTmp);
if ~isempty(dStr)
    % determines if the 
    dStr = strsplit(dStr,'\n');
    if (length(dStr) == 2) && startsWith(dStr{1},'warning:') 
        dStr = [];
    end
end

% disables/enables the resolve/revert buttons
updateTableFlag(handles.tableDiff,iRow(2),isempty(dStr))
if isempty(dStr)
    resetButtonProps(hObject,handles.buttonRevertDiff)
    setContButtonProps(handles)
end

% --- Executes on button press in buttonRevertDiff.
function buttonRevertDiff_Callback(hObject, eventdata, handles)

if ~ischar(eventdata)
    % prompt the user if they want to revert to original
    qStr = 'Are you sure you want to revert the file back to original?';
    uChoice = questdlg(qStr,'Undo Merge Difference?','Yes','No','Yes');
    if ~strcmp(uChoice,'Yes')
        % if the user cancelled, then exit the function
        return
    end
end

% retrieves the important objects from the GUI
hFig = handles.figGitMergeDiff;
mBr = getappdata(hFig,'mBr');
vObj = getappdata(hFig,'vObj');
iRow = getappdata(hFig,'iRow');
dcFiles = getappdata(hFig,'dcFiles');

% determines the merge conflict file to be resolved
dFile = dcFiles.Diff(iRow(2));
mdFile = getFullFileName(dFile);

% reverts the merge difference file back to original
vObj.gfObj.gitCmd('checkout-branch-file',mBr,mdFile);

% updates the table indicating the difference has been resolved
updateTableFlag(handles.tableDiff,iRow(2),false)

% disables/enables the resolve/revert buttons
resetButtonProps(hObject,handles.buttonResolveDiff)
setObjEnable(handles.buttonCont,0)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    OTHER CONTROL BUTTON FUNCTIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in buttonCont.
function buttonCont_Callback(hObject, eventdata, handles)

% global variables
global isCont

% indicating the merge/difference was successful
isCont = true;

% removes the temporary file directory and closes the GUI
tmpDirFunc('remove')
delete(handles.figGitMergeDiff)

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
iRow = getappdata(hFig,'iRow');
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
            % updates the row index
            iRow(i) = j;
            setappdata(hFig,'iRow',iRow);
            
            % runs the revert function (depending on the type)
            if i == 1
                % case is reverting the conflict merge 
                buttonRevertConflict_Callback(hButRevC,'1',handles)
            else
                % case is reverting the file difference
                buttonRevertDiff_Callback(hButRevD,'1',handles)                
            end
        end
    end
end

% changes the directory back to the original
cDir0 = getappdata(hFig,'cDir0');
cd(cDir0);

% removes the temporary directory and closes the GUI
tmpDirFunc('remove')
delete(hFig)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    OBJECT PROPERTY FUNCTIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- initialises the GUI objects
function initGUIObjects(handles)

% field retrieval
hFig = handles.figGitMergeDiff;
cBr = getappdata(hFig,'cBr');
mBr = getappdata(hFig,'mBr');
vObj = getappdata(hFig,'vObj');
dcFiles = getappdata(hFig,'dcFiles');

% other initialisations
fStr = fieldnames(dcFiles);
[dX,hasEmpty] = deal(10,false);

% sets the table column format strings
rType = {'Custom Resolve',sprintf('Use "%s"',mBr),sprintf('Use "%s"',cBr)};
cForm = {'char',rType,'logical'};

% if there are difference files, then copy them to a temporary directory
if ~isempty(dcFiles.Diff)
    % creates the temporary directory
    tmpDirFunc('add')
    
    % checkouts the difference file from the merging branch
    for i = 1:length(dcFiles.Diff)
        % sets the difference and temporary output file names
        dFile = getFullFileName(dcFiles.Diff(i));
        dFileOut = getTempDiffFileName(dcFiles.Diff(i));
        
        % outputs the file from the merging branch to the temp directory
        vObj.gfObj.gitCmd('checkout-to-location',cBr,dFile,dFileOut);
    end
end

% memory allocation
hTable = cell(length(fStr),1);

% initialises the table data for the merge conflict/difference files
for i = 1:length(fStr)
    % retrieves the corresponding data struct field
    dcStr = getStructField(dcFiles,fStr{i});
    
    % retrieves the corresponding panel/table object handles
    hPanel = eval(sprintf('handles.panel%s',fStr{i}));
    hTable{i} = eval(sprintf('handles.table%s',fStr{i}));   
    
    % sets the table (if any exists)
    nFld = length(dcStr);
    if nFld > 0
        % if there are valid fields, then update the table
        fName = field2cell(dcStr,'Name');
        iInd = ones(nFld,1);
        isOK = num2cell(false(nFld,1));        
        set(hTable{i},'Data',[fName,cForm{2}(iInd),isOK],...
                      'ColumnFormat',cForm)
        autoResizeTableColumns(hTable{i})
        
        % if the other panel is empty, 
        if hasEmpty
            resetObjPos(hPanel,'left',dX)
        end
    else
        % otherwise, make the panel invisible and sets an empty table         
        setObjVisibility(hPanel,0)  
        set(hTable{i},'Data',{'',true});             
        
        % resets the position of the control buttons panel and figure width
        [pPos,hasEmpty] = deal(get(hPanel,'position'),true);
        resetObjPos(handles.panelContButtons,'left',dX)     
        resetObjPos(hFig,'width',-(pPos(3)+dX),1);  
    end
end

% disables all push-buttons (except the cancel button)
hBut = findall(hFig,'style','pushbutton');
setObjEnable(hBut,0)
setObjEnable(handles.buttonCancel,1)

% --- updates the properties when selecting a table row
function updateSelectionProperties(hTable,iRowSel,iTable)

% parameters
bStr = {'Conflict','Diff'};

% determines if the conflict or difference table was selected
isDiff = strContains(get(hTable,'tag'),'Diff');
hButRes = findall(gcf,'tag',sprintf('buttonResolve%s',bStr{1+isDiff}));
hButRev = findall(gcf,'tag',sprintf('buttonRevert%s',bStr{1+isDiff}));

% selects the row of a table
selectTableRow(hTable,iRowSel)

% sets the enabled properties of the control buttons depending on whether
% the conflict/difference has been resolved or not
Data = get(hTable,'Data');
setObjEnable(hButRev,Data{iRowSel,3})
setObjEnable(hButRes,~Data{iRowSel,3})

% updates the selected row in the selection array
iRow = getappdata(gcf,'iRow');
iRow(iTable) = iRowSel;
setappdata(gcf,'iRow',iRow)

% --- determines if the user can continue (only when all
%     conflicts/differences have been resolved)
function setContButtonProps(handles)

% retrieves the data from both tables
tDataM = get(handles.tableConflict,'Data');
tDataD = get(handles.tableDiff,'Data');

% if all differences have been resolved then continue
if isempty(tDataM)
    % case is there are only merge conflict files
    canCont = all(cell2mat(tDataM(:,2)));
elseif isempty(tDataD)
    % case is there are only merge difference files
    canCont = all(cell2mat(tDataD(:,2)));
else
    % case is there are both merge difference/conflict files
    canCont = all(cell2mat(tDataM(:,2))) && all(cell2mat(tDataD(:,2)));
end

% updates the enabled properties of the continue button
setObjEnable(handles.buttonCont,canCont)

% --- disables/enables the corresponding control buttons
function resetButtonProps(hOff,hOn)

% disables/enables the corresponding buttons
setObjEnable(hOn,1)
setObjEnable(hOff,0)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    TABLE UPDATE FUNCTIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- selects a specific row of a table
function selectTableRow(hTable,iRowSel)

% retrieves the table java object handle
jTable = getappdata(hTable,'jTable');
if isempty(jTable)
    % if it doesn't exist, then retrieve and set it
    jScrollPane = findjobj(hTable);
    jTable = jScrollPane.getViewport.getView;
    setappdata(hTable,'jTable',jTable)
end

% --- updates the resolved flag within a given table (on a specific row)
function updateTableFlag(hTable,iRow,tVal)

% updates the table value
tData = get(hTable,'Data');
tData{iRow,3} = tVal;
set(hTable,'Data',tData)

% reselects the row of the table
selectTableRow(hTable,iRow)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    TEMPORARY FILE FUNCTIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- retrieves the temporary difference file name
function dFileOut = getTempDiffFileName(dStr)

[~,fName,fExtn] = fileparts(dStr.Name);
dFileOut = sprintf('%s/%s_REMOTE%s',getTempDiffFileDir,fName,fExtn);

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    MISCELLANEOUS FUNCTIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
% --- retrieves the full file name from the file data struct
function ffName = getFullFileName(fFile)

if isempty(fFile.Path)
    ffName = fFile.Name;
else
    ffName = sprintf('%s/%s',fFile.Path,fFile.Name);
end
