function varargout = RestartBatchProcess(varargin)
% Last Modified by GUIDE v2.5 18-Sep-2017 16:55:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RestartBatchProcess_OpeningFcn, ...
                   'gui_OutputFcn',  @RestartBatchProcess_OutputFcn, ...
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

% --- Executes just before RestartBatchProcess is made visible.
function RestartBatchProcess_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for RestartBatchProcess
handles.output = hObject;

% sets the input variables
hGUI = varargin{1};

% loads the required structs/data objects
iData = getappdata(hGUI.figFlyTrack,'iData');

% sets the data structs into the GUI
setappdata(hObject,'hGUI',hGUI);
setappdata(hObject,'iProg',iData.ProgDef);

% initialises the fields
initMoveButtons(handles)
initSummaryInfo(handles)
[iExptAll,iExptAdd] = initDataStruct(handles);
centreFigPosition(hObject);

% sets the other data structs into the GUI
setappdata(hObject,'iExptAll',iExptAll);
setappdata(hObject,'iExptAdd',iExptAdd);
setappdata(hObject,'iProg',iData.ProgDef);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes RestartBatchProcess wait for user response (see UIRESUME)
uiwait(handles.figMultiBatch);

% --- Outputs from this function are returned to the command line.
function varargout = RestartBatchProcess_OutputFcn(hObject, eventdata, handles) 

% global variables
global bpData

% Get default command line output from handles structure
varargout{1} = bpData;

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% ----------------------- %
% --- FILE MENU ITEMS --- %
% ----------------------- %

% -------------------------------------------------------------------------
function menuScanBatch_Callback(hObject, eventdata, handles)

% retrieves the default program 
iProg = getappdata(handles.figMultiBatch,'iProg');
redoAll = get(handles.checkRedoPP,'value');

% prompts the user for the scanning directory
scDir = uigetdir(iProg.DirSoln,'Set The Master Solution File Directory');
if (scDir == 0)
    % if the user cancelled, then exit the function
    return
end

% retrieves the feasible batch processing data files
[bpDataNw,isSegNw] = getFeasBatchProcessDir(scDir,redoAll);
if (isempty(bpDataNw))
    % if there were none, then exit the function
    return
else
    % sets the new directory strings
    [snDir,snDirN] = field2cell(bpDataNw,{'SolnDir','SolnDirName'});
    nwDir = cellfun(@(x,y)(fullfile(getDirSuffix(x),y)),snDir,snDirN,'un',0);        
    
    % determines the new list strings
    iExptAll = getappdata(handles.figMultiBatch,'iExptAll');
    iAdd = find(cellfun(@(x)(~any(strcmp(iExptAll.fName,x))),nwDir));
    if (isempty(iAdd))
        % if there are no unique entries, then exit the function
        return
    else
        % otherwise, load the loaded solution data struct
        fName = field2cell(bpDataNw,'SolnDirName');
    end
end

% otherwise, add on the unique entries
nAdd = length(iAdd);
iExptAll.bpData = [iExptAll.bpData;bpDataNw(iAdd)];
iExptAll.isSeg = [iExptAll.isSeg;isSegNw(iAdd)];
iExptAll.isAdded = [iExptAll.isAdded;false(nAdd,1)];
iExptAll.fName = [iExptAll.fName;fName(iAdd)];
setappdata(handles.figMultiBatch,'iExptAll',iExptAll);

% resets the GUI object properties (if initialising)
if (nAdd == length(iExptAll.bpData))
    resetSolnProps(handles,iExptAll)    
else
    % updates the information fields
    set(handles.listExptAll,'string',iExptAll.fName);
end

% -------------------------------------------------------------------------
function menuRestartBatch_Callback(hObject, eventdata, handles)

% global variables
global bpData

% retrieves the important data structs
iExptAdd = getappdata(handles.figMultiBatch,'iExptAdd');

% reorders the batch processing data structs
bpData = iExptAdd.bpData;

% closes the figure
delete(handles.figMultiBatch)

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

% global variables
global bpData

% closes the GUI
bpData = [];
delete(handles.figMultiBatch)

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ----------------------------------------------- %
% --- BATCH PROCESSING FILE LISTBOX CALLBACKS --- %
% ----------------------------------------------- %

% --- Executes on selection change in listExptAll.
function listExptAll_Callback(hObject, eventdata, handles)

% retrieves the maximum value of the other listbox
yMax = get(hObject,'max');
if yMax == 2
    % updates the listbox properties
    set(handles.listExptAdded,'max',2,'value',[])
    
    % retrieves the indices of the selected item
    setObjEnable(handles.buttonExptAdd,'on')
    setObjEnable(handles.buttonExptRemove,'off')           
end

% % resets the alpha patch on the graph
setMoveButtonProp(handles)

% --- Executes on selection change in listExptAdded.
function listExptAdded_Callback(hObject, eventdata, handles)

% retrieves the maximum value of the other listbox
yMax = get(hObject,'max');
if (yMax == 2)
    % updates the listbox properties
    set(hObject,'max',1);
    set(handles.listExptAll,'value',[])
    
    % retrieves the indices of the selected item
    setObjEnable(handles.buttonExptAdd,'off')
    setObjEnable(handles.buttonExptRemove,'on')           
end

% resets the alpha patch on the graph
iSel = get(hObject,'Value');
setMoveButtonProp(handles,iSel)

% sets the newly selected batch processing file
iExptAdd = getappdata(handles.figMultiBatch,'iExptAdd');
[bpNw,isSegNw] = deal(iExptAdd.bpData(iSel),iExptAdd.isSeg{iSel});

% updates the movie directory name
[A1,B1] = fileparts(bpNw.MovDir); [~,B2] = fileparts(A1);
set(handles.textMovDir,'string',fullfile('..',B2,B1),...
                'tooltipstring',bpNw.MovDir)

% updates the solution directory name
B2 = getDirSuffix(bpNw.SolnDir);
set(handles.textSolnDir,'string',fullfile('..',B2,bpNw.SolnDirName),...
                'tooltipstring',fullfile(bpNw.SolnDir,bpNw.SolnDirName))

% updates the other fields
pComp = roundP(100*sum(isSegNw)/length(bpNw.mName),1);
set(handles.textVideoCount,'string',length(bpNw.mName))
set(handles.textSolnCount,'string',sum(isSegNw))
set(handles.textPercentComp,'string',sprintf('%i%s',pComp,char(37)))

% ------------------------------------------------------- %
% --- BATCH PROCESSING FILE LIST PUSHBUTTON CALLBACKS --- %
% ------------------------------------------------------- %

% --- Executes on button press in buttonExptAdd.
function buttonExptAdd_Callback(hObject, eventdata, handles)

% retrieves the program data struct
indNw = get(handles.listExptAll,'Value');
indNw = reshape(indNw,length(indNw),1);

% retrieves the total/added solution data array structs
iExptAll = getappdata(handles.figMultiBatch,'iExptAll');
iExptAdd = getappdata(handles.figMultiBatch,'iExptAdd');

% resets the array to only include those not already added
indNw = indNw(~iExptAll.isAdded(indNw));
if (isempty(indNw))
    % if there are no unique solutions to add, then exit the function
    return
end

% updates the added flags
iExptAll.isAdded(indNw) = true;
setappdata(handles.figMultiBatch,'iExptAll',iExptAll);

% if there were no solutions added then enable the start/finish time panels
if iExptAdd.nCount == 0
    setObjEnable(handles.buttonExptReset,'on')
    setObjEnable(handles.menuRestartBatch,'on')
    setPanelProps(handles.panelBatchInfo,'on')
end

% flags the new values to be added
iExptAdd.nCount = sum(iExptAll.isAdded);
iExptAdd.bpData = [iExptAdd.bpData;iExptAll.bpData(indNw)];
iExptAdd.isSeg = [iExptAdd.isSeg;iExptAll.isSeg(indNw)];
iExptAdd.fName = [iExptAdd.fName;iExptAll.fName(indNw)];
iExptAdd.Order = [iExptAdd.Order;indNw];
setappdata(handles.figMultiBatch,'iExptAdd',iExptAdd);

% sets the solution file names
updateAddLists(handles)
    
% --- Executes on button press in buttonExptRemove.
function buttonExptRemove_Callback(hObject, eventdata, handles)

% retrieves the program data struct
indNw = get(handles.listExptAdded,'Value');
indNw = reshape(indNw,length(indNw),1);

% retrieves the total/added solution data array structs
iExptAll = getappdata(handles.figMultiBatch,'iExptAll');
iExptAdd = getappdata(handles.figMultiBatch,'iExptAdd');

% updates the added flags
jj = true(iExptAdd.nCount,1); jj(indNw) = false;
iExptAll.isAdded(iExptAdd.Order(indNw)) = false;
setappdata(handles.figMultiBatch,'iExptAll',iExptAll);

% resets the data arrays
ii = logical(iExptAll.isAdded);
iExptAdd.nCount = sum(ii);
iExptAdd.bpData = iExptAdd.bpData(jj);
iExptAdd.isSeg = iExptAdd.isSeg(jj);
iExptAdd.fName = iExptAdd.fName(jj);
iExptAdd.Order = iExptAdd.Order(jj);
setappdata(handles.figMultiBatch,'iExptAdd',iExptAdd);

% updates the GUI object properties based on the number of added solutions
if (iExptAdd.nCount == 0)
    buttonExptReset_Callback(handles.buttonExptReset, '1', handles)
else
    % retrieves the selected index and reset the listbox
    indNw = min(iExptAdd.nCount,indNw);
    set(handles.listExptAdded,'Value',indNw)    
    listExptAdded_Callback(handles.listExptAdded, [], handles) 
end
    
% sets the solution file names
updateAddLists(handles)

% --- Executes on button press in buttonExptReset.
function buttonExptReset_Callback(hObject, eventdata, handles)

% sets the user choice based on the input arguments
if (~isa(eventdata,'char'))
    % case is the user choice
    uChoice = questdlg('Do you wish to clear A) all loaded files, or B) The added files?',...
                       'Reset Batch Process Files?','All Loaded','Added Files',...
                       'Cancel','All Loaded');
else
    % case is the forced removal of added files
    uChoice = 'Added Files';   
end

% updates the data structs based on the user choice string
switch (uChoice)
    case ('All Loaded') % case is clearing all the loaded files
        % resets all the data structs
        [iExptAll,iExptAdd] = initDataStruct(handles);
        set(handles.listExptAll,'string',[],'value',[])
    case ('Added Files') % case is clearing all the added file
        % resets the data structs and GUI object properties
        iExptAll = getappdata(handles.figMultiBatch,'iExptAll');
        [~,iExptAdd] = initDataStruct(handles,1);
        iExptAll.isAdded(:) = false;

        % resets the selection to the all loaded listbox
        set(setObjEnable(handles.listExptAll,'on'),'value',1)
        listExptAll_Callback(handles.listExptAll, [], handles)        
    otherwise % case is cancelling or other
        % exits the function
        return
end

% disables the up/down buttons
setObjEnable(hObject,'off')
setObjEnable(handles.menuRestartBatch,'off')

% updates the data struct into the GUI
setappdata(handles.figMultiBatch,'iExptAll',iExptAll);
setappdata(handles.figMultiBatch,'iExptAdd',iExptAdd);

% resets the summary information panel
setPanelProps(handles.panelBatchInfo,'off')
initSummaryInfo(handles,1)

% --- Executes on button press in buttonMoveUp.
function buttonMoveUp_Callback(hObject, eventdata, handles)


% resets the data structs and GUI object properties
iExptAdd = getappdata(handles.figMultiBatch,'iExptAdd');
indNw = get(handles.listExptAdded,'Value');

% sets the new index array
ii = (1:iExptAdd.nCount)';
[ii(indNw),ii(indNw-1)] = deal(indNw-1,indNw);

% updates the arrays
iExptAdd.bpData = iExptAdd.bpData(ii);
iExptAdd.isSeg = iExptAdd.isSeg(ii);
iExptAdd.fName = iExptAdd.fName(ii);
iExptAdd.Order = iExptAdd.Order(ii);
setappdata(handles.figMultiBatch,'iExptAdd',iExptAdd);

% updates the listbox selection and up/down button properties
set(handles.listExptAdded,'value',indNw-1)
setMoveButtonProp(handles,indNw-1)

% sets the solution file names
updateAddLists(handles)

% --- Executes on button press in buttonMoveDown.
function buttonMoveDown_Callback(hObject, eventdata, handles)

% resets the data structs and GUI object properties
iExptAdd = getappdata(handles.figMultiBatch,'iExptAdd');
indNw = get(handles.listExptAdded,'Value');

% sets the new index array
ii = (1:iExptAdd.nCount)';
[ii(indNw),ii(indNw+1)] = deal(indNw+1,indNw);

% updates the arrays
iExptAdd.bpData = iExptAdd.bpData(ii);
iExptAdd.isSeg = iExptAdd.isSeg(ii);
iExptAdd.fName = iExptAdd.fName(ii);
iExptAdd.Order = iExptAdd.Order(ii);
setappdata(handles.figMultiBatch,'iExptAdd',iExptAdd);

% updates the listbox selection and up/down button properties
set(handles.listExptAdded,'value',indNw+1)
setMoveButtonProp(handles,indNw+1)

% sets the solution file names
updateAddLists(handles)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% ----------------------------- %
% --- OTHER INITIALISATIONS --- %
% ----------------------------- %

% --- initialises the movement buttons --- %
function initMoveButtons(handles)

% sets the button c-data values
cdFile = 'ButtonCData.mat';
if ~exist(cdFile,'file')
    return
end

% sets the button colour data and updates the up/down buttons
[A,nDS] = deal(load(cdFile),3); 
[Iup,Idown] = deal(A.cDataStr.Iup,A.cDataStr.Idown);        
set(handles.buttonMoveUp,'Cdata',uint8(dsimage(Iup,nDS)));        
set(handles.buttonMoveDown,'Cdata',uint8(dsimage(Idown,nDS)));

% --- initialises the summary information panel --- %
function initSummaryInfo(handles,varargin)

% sets NaN values for all the info fields
set(handles.textMovDir,'string','N/A')
set(handles.textSolnDir,'string','N/A')
set(handles.textVideoCount,'string','N/A')
set(handles.textSolnCount,'string','N/A')
set(handles.textPercentComp,'string','N/A')

% disables all the objects
if (nargin == 1)
    setPanelProps(handles.panelBatchInfo,'off')
end

% ---------------------------------------- %
% --- OBJECT PROPERTY UPDATE FUNCTIONS --- %
% ---------------------------------------- %

% --- sets the up/down movement button properties --- %
function setMoveButtonProp(handles,indNw)

% retrieves the added solution data struct
iExptAdd = getappdata(handles.figMultiBatch,'iExptAdd');

% only set the button enable properties if there is at least two items in
% the table and a valid selection has been made
if nargin == 1
    setObjEnable(handles.buttonMoveUp,'off');
    setObjEnable(handles.buttonMoveDown,'off');
    
elseif (iExptAdd.nCount > 1) && ~isempty(indNw)
    if indNw(1) == 1
        % case is the first entry
        setObjEnable(handles.buttonMoveUp,'off');
        setObjEnable(handles.buttonMoveDown,'on');   
        
    elseif indNw(1) == iExptAdd.nCount
        % case is the last entry
        setObjEnable(handles.buttonMoveUp,'on');
        setObjEnable(handles.buttonMoveDown,'off'); 
        
    else
        % case is the other table entries
        setObjEnable(handles.buttonMoveUp,'on');
        setObjEnable(handles.buttonMoveDown,'on');        
    end
    
else
    setObjEnable(handles.buttonMoveUp,'off');
    setObjEnable(handles.buttonMoveDown,'off');                    
end

% --- updates the added experimental file listbox and table --- %
function updateAddLists(handles,varargin)

% determines the number of files that have been set
iExptAdd = getappdata(handles.figMultiBatch,'iExptAdd');
nExp = iExptAdd.nCount;

% updates the added experiment listbox
if (nExp == 0)
    % sets the listbox title/object properties
    set(handles.listExptAdded,'String','','max',2,'Value',[],'enable','off')    
else
    % sets the listbox title/object properties    
    set(setObjEnable(handles.listExptAdded,'on'),'String',iExptAdd.fName)
end

% sets the up/down movement button properties
setMoveButtonProp(handles,get(handles.listExptAdded,'value'))

% --- resets the solution panel object properties --- %
function resetSolnProps(handles,iExptAll)

% updates the panel properties and listbox values
setObjVisibility(handles.figMultiBatch,'off')

% initialises the solution file panel objects
setPanelProps(handles.panelBatchDir,'on')
setObjEnable(handles.buttonExptRemove,'off')
setObjEnable(handles.buttonExptReset,'off')
setObjEnable(handles.buttonMoveUp,'off')
setObjEnable(handles.buttonMoveDown,'off')
setObjVisibility(handles.figMultiBatch,'on')

% updates the information fields
set(setObjEnable(handles.listExptAdded,'on'),'backgroundcolor',[1 1 1])
set(handles.listExptAll,'string',iExptAll.fName,'value',1,...
                        'enable','on','backgroundcolor',[1 1 1]);

% --------------------------------------- %
% --- STRUCT INITIALISATION FUNCTIONS --- %
% --------------------------------------- %     

% --- initialises the program data struct
function [iExptAll,iExptAdd] = initDataStruct(handles,varargin)

% initialises the GUI objects (if only one input argument)
if (nargin == 1)
    % removes the selections from the listboxes
    setPanelProps(handles.panelBatchDir,'off')
    setObjEnable(handles.checkRedoPP,'on')
    set(handles.listExptAll,'max',2,'value',[],'string',[]);    
end

% sets the panel object properties
setObjEnable(handles.menuRestartBatch,'off')
set(handles.listExptAdded,'max',2,'value',[],'string',[]);

% initialises the data structs
[iExptAll,iExptAdd] = deal(struct('nCount',0,'bpData',[],...
                                  'isSeg',[],'fName',[]));
[iExptAll.isAdded,iExptAdd.Order] = deal([]);                              
