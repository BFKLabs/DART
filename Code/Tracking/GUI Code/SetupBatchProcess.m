function varargout = SetupBatchProcess(varargin)
% Last Modified by GUIDE v2.5 12-Feb-2016 01:47:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @SetupBatchProcess_OpeningFcn, ...
    'gui_OutputFcn',  @SetupBatchProcess_OutputFcn, ...
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

% --- Executes just before SetupBatchProcess is made visible.
function SetupBatchProcess_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for SetupBatchProcess
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% resets the object font sizes
setGUIFontSize(handles)

% sets the program preference struct. if it is empty, then
iData = varargin{1};

% determines if a summary file exists in the current movie directory
smFile0 = fullfile(iData.fData.dir,'Summary.mat');
if (~exist(smFile0,'file'))
    % if the summary file is missing, then output an error
    eStr = [{'Error! Summary file is missing from current movie directory.'};...
            {'Ensure summary file is present before performing batch processing.'}];
    waitfor(errordlg(eStr,'Missing Summary File','modal'));
    
    % exits the batch processing GUI
    setappdata(hObject,'bpData',[]);    
    menuExit_Callback([], [], handles)
    return
else
    % otherwise, load the summary file data
    sData0 = orderfields(load(smFile0));
    if (~isfield(sData0,'sData'))
        sData0.sData = [];
        sData0 = orderfields(sData0);
    end    
end

% sets the sub-data structs
setappdata(hObject,'ProgDef',iData.ProgDef);

% retrieces the batch processing data for the current movie directory
bpData0 = retBatchData(handles,iData.fData.dir);

% updates the data fields
setappdata(hObject,'ind0',1);
setappdata(hObject,'bpData',bpData0);
setappdata(hObject,'sData',sData0);

% initialises the GUI objects
initDefButton(handles,iData.ProgDef)
initListBoxes(handles)
initSummaryObj(handles)
centreFigPosition(hObject);

% UIWAIT makes SetupBatchProcess wait for user response (see UIRESUME)
uiwait(hObject);

% --- Outputs from this function are returned to the command line.
function varargout = SetupBatchProcess_OutputFcn(hObject, eventdata, handles)

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
function menuLoadBatch_Callback(hObject, eventdata, handles)

% retrieves the default program 
ProgDef = getappdata(handles.figBatchProcess,'ProgDef');
ind00 = getappdata(handles.figBatchProcess,'ind0');
iSel = get(handles.listExptAdded,'value');

% prompts the user for the scanning directory
scDir = uigetdir2(ProgDef.DirMov,'Set Batch Processing Directories');
if (isempty(scDir))
    % if the user cancelled, then exit the function
    return
end

% retrieves the feasible batch processing data files
[bpData,sData,ind0,isChange] = detFeasBPDir(handles,scDir);
if (isChange)
    % updates the data structs
    setappdata(handles.figBatchProcess,'bpData',bpData);
    setappdata(handles.figBatchProcess,'sData',sData);    
    setappdata(handles.figBatchProcess,'ind0',ind0);    
        
    % enables the other panels
    set(handles.listExptAdded,'string',...
                field2cell(bpData,'MovDir'),'value',iSel+(ind0-ind00))    
end

% -------------------------------------------------------------------------
function menuStartBatch_Callback(hObject, eventdata, handles)

% global variables
global bpData

% retrieves the batch processing data struct
bpData0 = getappdata(handles.figBatchProcess,'bpData');
solnDir = fullfile(bpData0.SolnDir,bpData0.SolnDirName);

% determines if the output directory exists
if (exist(solnDir,'dir'))
    % if it does, then prompt the user that directory will be over-written
    % if they continue
    qStr = sprintf(['The solution file directory already exists. If you ',...
                    'continue then this directory will be overwritten\n\n',...
                    'Do you still wish to continue?']);
    uChoice = questdlg(qStr,'Solution File Directory Already Exists',...
                       'Yes','No','Yes');
    if (strcmp(uChoice,'Yes'))
        % sets the output batch processing data struct
        bpData = bpData0;
        
        % deletes the existing solution file directory
        rmdir(solnDir, 's')
    else
        % otherwise, exit the function        
        return        
    end
else
    % sets the batch processing data struct
    bpData = bpData0;
end
    
% closes the figure
delete(handles.figBatchProcess)

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

% global variables
global bpData

% closes the GUI
bpData = [];
delete(handles.figBatchProcess)

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ---------------------------------------- %
% --- BATCH PROCESSING SETUP FUNCTIONS --- %
% ---------------------------------------- %

% --- Executes on selection change in listExptAdded.
function listExptAdded_Callback(hObject, eventdata, handles)

% retrieves the selected indices and the base experiment index
iSel = get(hObject,'value');
ind0 = getappdata(handles.figBatchProcess,'ind0');

% only enable the solution directory button for the base experiment
setObjEnable(handles.buttonSolnDir,iSel == ind0)

% updates the batch processing experiment data fields
updateBatchDataFields(handles)

% ------------------------------------ %
% --- OUTPUT DATA OBJECT FUNCTIONS --- %
% ------------------------------------ %

% --- Executes on updating editSolnDirName.
function editSolnDirName_Callback(hObject, eventdata, handles)

% retrieves the selected indices and batch processing data
iSel = get(handles.listExptAdded,'value');
bpData = getappdata(handles.figBatchProcess,'bpData');

% retrieves the new string
nwStr = get(hObject,'string');

% only check strings that are not empty
if (~isempty(nwStr))
    % retrieves the new string
    iNS = regexp(nwStr,'\S');
    nwStr = nwStr(iNS(1):end);

    % checks to see if the user entered a correct solution file name
    if (chkDirString(nwStr))   
        % updates the data struct
        bpData(iSel).SolnDirName = nwStr;
        setappdata(handles.figBatchProcess,'bpData',bpData);
        set(hObject,'string',['  ',nwStr])
        return
    end
end
    
% resets the editbox string
set(hObject,'string',['  ',bpData(iSel).SolnDirName])

% --------------------------------------- %
% --- SUMMARY OUTPUT OBJECT FUNCTIONS --- %
% --------------------------------------- %

% --- Executes on button press in checkboxOutputSoln.
function checkboxOutputSoln_Callback(hObject, eventdata, handles)

% retrieves the selected indices and batch processing data
bpData = getappdata(handles.figBatchProcess,'bpData');
bpData.sfData.isOut = get(hObject,'value');
setappdata(handles.figBatchProcess,'bpData',bpData);

% sets the other object enabled properties based on the selection value
hObj = findobj(handles.panelSummaryOutput,'UserData',1);
setObjEnable(hObj,bpData.sfData.isOut)

% --- Executes on selection change in popupOutputType.
function popupOutputType_Callback(hObject, eventdata, handles)

% retrieves the selected indices and batch processing data
bpData = getappdata(handles.figBatchProcess,'bpData');
[iSel,lStr] = deal(get(hObject,'value'),get(hObject,'string'));

% sets the summary output file type
switch (lStr{iSel})
    case ('Single Summary File')
        bpData.sfData.Type = 'Append';
    otherwise
        bpData.sfData.Type = 'WriteNew';
end

% updates the data struct
setappdata(handles.figBatchProcess,'bpData',bpData);

% --- Executes on updating editbox editTimeBin.
function editTimeBin_Callback(hObject, eventdata, handles)

% retrieves the selected indices and batch processing data
bpData = getappdata(handles.figBatchProcess,'bpData');

% retrieves the new value from the editbox
nwVal = str2double(get(hObject,'string'));
if (chkEditValue(nwVal,[10 300],true))
    % sets the new value into the data struct
    bpData.sfData.tBin = nwVal;
    setappdata(handles.figBatchProcess,'bpData',bpData);
else
    % resets the object string to the last valid value
    set(hObject,'string',num2str(bpData.sfData.tBin))
end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% ----------------------------- %
% --- OTHER INITIALISATIONS --- %
% ----------------------------- %

% --- initialises the default directory/file pushbutton properties --- %
function initDefButton(handles,ProgDef)

% sets the variable tag strings
wStr = {'SolnDir'};

% sets the call back function for all the GUI buttons
for i = 1:length(wStr)
    % sets up the object callback function
    hObj = eval(sprintf('handles.button%s;',wStr{i}));
    bFunc = @(hObj,e)SetupBatchProcess('getDirInfo',hObj,wStr{i},guidata(hObj));
    
    % sets the object callback function
    set(hObj,'UserData',wStr{i},'callback',bFunc);    
end

% --- initialises the list boxes objects --- %
function initListBoxes(handles)

% retrieves the important data structs/arrays
bpData = getappdata(handles.figBatchProcess,'bpData');

% disables all the panel objects
setPanelProps(handles.panelBatchDir,'off',1)

% initialises the listbox objects 
set(handles.listExptAdded,'max',1,'value',1,'string',bpData(1).MovDir,...
            'enable','on','backgroundcolor',[1 1 1]);

% updates the batch processing data fields
updateBatchDataFields(handles);

% --- initialises the output file summary objects
function initSummaryObj(handles)

% retrieves the important data structs/arrays
bpData = getappdata(handles.figBatchProcess,'bpData');

% sets the time bin value
set(handles.checkboxOutputSoln,'value',bpData.sfData.isOut)
set(handles.editTimeBin,'string',num2str(bpData.sfData.tBin))

% resets the output object types
checkboxOutputSoln_Callback(handles.checkboxOutputSoln, [], handles)

% ------------------------------------------ %
% --- FILE/DIRECTORY SELECTION CALLBACKS --- %
% ------------------------------------------ %

% --- callback function for the default directory setting buttons --- %
function getDirInfo(hObject, eventdata, handles)

% retrieves the default directory corresponding to the current object
bpData = getappdata(handles.figBatchProcess,'bpData');

% sets the default directory
iSel = get(handles.listExptAdded,'value');
dDir = bpData(iSel).SolnDir;            
        
% prompts the user for the new default directory
dirName = uigetdir(dDir,'Set The Directory Path');
if (dirName ~= 0)
    % otherwise, update the directory string names
    for i = 1:length(bpData)
        bpData(i).SolnDir = dirName;
    end
    setappdata(handles.figBatchProcess,'bpData',bpData);
       
    % resets the enabled properties of the buttons
    set(handles.editSolnDir,'string',['  ',dirName],'ToolTipString',dirName)   
end


% ------------------------------ %
% --- MISCELLANEOUS FUNCTION --- %
% ------------------------------ %                  

% --- updates the batch processing data fields with bData --- %
function updateBatchDataFields(handles)

% sets the batch processing data struct that is to be used for field update
bpData = getappdata(handles.figBatchProcess,'bpData');
iSel = get(handles.listExptAdded,'value');
bpDataNw = bpData(iSel);

% updates the editbox strings
set(handles.editMovDir,'string',['  ',bpDataNw.MovDir],...
                'ToolTipString',bpDataNw.MovDir); 
set(handles.editSolnDir,'string',['  ',bpDataNw.SolnDir],...
                'ToolTipString',bpDataNw.SolnDir);                          
set(handles.editSolnDirName,'string',['  ',bpDataNw.SolnDirName],...
                'ToolTipString',bpDataNw.SolnDirName);                                              
