function varargout = FlyAnalysis(varargin)
% Last Modified by GUIDE v2.5 29-Jan-2022 11:06:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @FlyAnalysis_OpeningFcn, ...
    'gui_OutputFcn',  @FlyAnalysis_OutputFcn, ...
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

% --- Executes just before FlyAnalysis is made visible.
function FlyAnalysis_OpeningFcn(hObject, ~, handles, varargin)

% global variables
global mainProgDir isDocked initDock regSz  
global updateFlag canSelect isAnalysis isUpdating
[isDocked,initDock,canSelect,isAnalysis] = deal(true);
isUpdating = false;
updateFlag = 2; pause(0.1); 

% Choose default command line output for FlyAnalysis
handles.output = hObject;

% retrieves the regular size of the GUI
regSz = get(handles.panelPlot,'position');

% creates the load bar
h = ProgressLoadbar('Initialising Analysis GUI...');

% initialises the sub-region data struct
setappdata(hObject,'sPara',initSubRegionStruct)

% loads the global analysis parameters from the program parameter file
A = load(fullfile(mainProgDir,'Para Files','ProgPara.mat'));
gPara = A.gPara;
setappdata(hObject,'gPara',gPara)

% ----------------------------------------------------------- %
% --- FIELD INITIALISATIONS & DIRECTORY STRUCTURE SETTING --- %
% ----------------------------------------------------------- %

% sets the DART object handles (if provided) and the program directory
switch length(varargin)
    case (0) % case is running full program from command line
        [hDART,ProgDefNew,mainProgDir] = deal([],[],pwd);           
        
    case (1) % case is running the program from DART main
        % sets the input argument and the open GUI (makes invisible)
        hDART = varargin{1};    
                
        % retrieves the program default struct
        ProgDefNew = getappdata(hDART.figDART,'ProgDefNew');
        setObjVisibility(hDART.figDART,'off')                      
        
    otherwise % case is any other number of input arguments
        % displays an error message
        eStr = ['Error! Incorrect number of input arguments.',...
                'Exiting Tracking GUI...'];
        waitfor(errordlg(eStr,'Analysis GUI Initialisation Error','modal'))
        
        % deletes the GUI and exits the function
        delete(hObject)
        return
end

% initialisation of the program data struct
iData = initDataStruct(handles,ProgDefNew);
if ~isdeployed
    addpath(iData.ProgDef.DirFunc);
end

% intialises the loaded information data structs
setappdata(hObject,'sInfo',[])
setappdata(hObject,'snTot',[])
setappdata(hObject,'LoadSuccess',false);

% initialises the structs
setappdata(hObject,'sInd',1)
setappdata(hObject,'hPara',[])
setappdata(hObject,'hUndock',[])
setappdata(hObject,'hDART',hDART)
setappdata(hObject,'iData',iData)
setappdata(hObject,'gPara',gPara)
setappdata(hObject,'iProg',iData.ProgDef)

% sets the default input opening files
sDir = {iData.ProgDef.DirSoln;iData.ProgDef.DirComb;iData.ProgDef.DirComb};
setappdata(hObject,'sDirO',sDir);

% sets all the functions
setappdata(hObject,'plotMetricGraph',@plotMetricGraph);
setappdata(hObject,'initAxesObject',@initAxesObject)
setappdata(hObject,'clearAxesObject',@clearAxesObject)
setappdata(hObject,'postSolnLoadFunc',@postSolnLoadFunc)
setappdata(hObject,'setSelectedNode',@setSelectedNode)
setappdata(hObject,'resetPlotPanelCoords',@resetPlotPanelCoords)
setappdata(hObject,'menuSubPlot',@menuSubPlot);

% updates the figure click callback function
fbcFcn = {@figButtonClick,handles.panelPlot};
setappdata(hObject,'figButtonClick',fbcFcn)

% initialises the gui object properties
initGUIObjects(handles)
scanPlotFuncDir(handles)
centreFigPosition(hObject);

% closes the loadbar
try; delete(h); end
updateFlag = 0; pause(0.1); 

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes FlyAnalysis wait for user response (see UIRESUME)
% uiwait(handles.figFlyAnalysis);

% --- Outputs from this function are returned to the command line.
function varargout = FlyAnalysis_OutputFcn(~, ~, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% ------------------------------- %
% --- DATA FILE OPENING ITEMS --- %
% ------------------------------- %

% -------------------------------------------------------------------------
function loadExptSoln_Callback(~, ~, handles)

% field retrieval
hFig = handles.figFlyAnalysis;

% if the parameter gui is present, then make it visible
hPara = findall(0,'tag','figAnalysisPara');
if ~isempty(hPara)
    setObjVisibility(hPara,0);
end

% closes the function filter (if open)
hToggle = handles.toggleFuncFilter;
if get(hToggle,'Value')
    set(hToggle,'Value',false)
    toggleFuncFilter_Callback(hToggle, [], handles)
end

% if there is currently loaded data, then combine the sInfo and snTot data
% structs for the 
if ~isempty(getappdata(hFig,'sInfo'))  
    % saves a copy of the currently loaded solution file data
    tempSolnDataIO(handles,'store')
    
    % combines the solution information/data structs
    combineInfoDataStructs(hFig);
end

% opens the solution file gui
wState = warning('off','all');
OpenSolnFile(hFig);
warning(wState);

% -------------------------------------------------------------------------
function menuOpenSubConfig_Callback(~, ~, handles)

% loads the data structs from the GUI
hFig = handles.figFlyAnalysis;
iData = getappdata(hFig,'iData');
dDir = iData.ProgDef.OutFig; 

% prompts the user for the solution file directory
tStr = 'Select The Subplot Configuration File';
fMode = {'*.spp','Subplot Configuration File (*.spp)'};
[fName,fDir,fIndex] = uigetfile(fMode,tStr,dDir);
if fIndex == 0
    % if the user cancelled, then exit
    return
else
    % makes the figure invisible
    setObjVisibility(hFig,'off'); 
    pause(0.05);
    
    % opens the file and retrieves the subplot parameter data struct
    A = load(fullfile(fDir,fName),'-mat');
    setappdata(hFig,'sPara',A.sPara)
    
    % removes any existing panels/plots
    hPanel = findall(handles.panelPlot,'tag','subPanel');
    if ~isempty(hPanel); delete(hPanel); end    
    
    % deletes/clears the analysis parameter GUI
    hPara = getappdata(hFig,'hPara');
    if ~isempty(hPara); delete(hPara); end
    setappdata(hFig,'hPara',[]);
    
    % creates the new subplot panels and menu items
    nReg = size(A.sPara.pos,1);
    setupSubplotPanels(handles.panelPlot,A.sPara)      
    resetSubplotMenuItems(hFig,obj.menuSubPlot,nReg);
    
    % updates the panel selection    
    setappdata(hFig,'sInd',1)    
    menuSubPlot(hFig,[])
    
    % makes the figure visible again
    setObjEnable(handles.menuSaveSubConfig,'on')
    setObjVisibility(handles.figFlyAnalysis,'on');     
end

% -------------------------------------------------------------------------
function menuOpenTempData_Callback(~, ~, handles)

% loads the data structs from the GUI
hFig = handles.figFlyAnalysis;
iData = getappdata(hFig,'iData');
dDir = iData.ProgDef.TempData;

% prompts the user if they wish to continue. if not, then exit
qStr = {['This action will clear any currently calculated data and ',...
         'can''t be undone.'];'';'Are you sure you wish to continue?'};
uChoice = questdlg(qStr,'Continue Temporary Data Load?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes'); return; end

% prompts the user for the solution file directory
fMode = {'*.tdat;','Temporary Data File (*.tdat)'};
[tName,tDir,fIndex] = uigetfile(fMode,'Temporary Data File File',dDir);
if fIndex == 0
    % if the user cancelled, then exit
    return
else    
    % sets the solution file name
    tName = fullfile(tDir,tName);    
end

% creates the load bar
h = ProgressLoadbar('Loading Temporary Data From File...');

% loads the data file and closes the load bar
wState = warning('off','all');
[A,eStr] = deal(importdata(tName,'-mat'),[]);
try; close(h); end
warning(wState);

% retrieves the original data structs
fName0 = getFinalDirString(getappdata(hFig,'fNameFull'));
sName0 = getappdata(hFig,'sName');

% check that the loaded data matches the solution file
if ~strcmp(fName0,A.sData.fName)
    % experimental solution file name does not match
    eStr = 'The loaded solution file and temporary dataset do not match';
    eStr = sprintf('%s\n\n => Loaded Solution File = "%s"\n',eStr,fName0);
    eStr = sprintf('%s => Temporary Data File = "%s"\n',eStr,A.sData.fName);
    eStr = sprintf('%s\nYou will need to load the matching solution file.',eStr);
elseif ~isequal(sName0,A.sData.sName)
    % individual solution file names do not match
    eStr = ['The solution files comprising the multi-experiment ',...
            'solution file do not match. You will need to load the',...
            'matching multi-experiment solution file'];
end

% if there was an error, then output a message to screen and exit
if ~isempty(eStr)
    waitfor(errordlg(eStr,'Solution File Mis-Match','modal'))
    return
end

% matches up the analysis function/data values between the original and
% currently loaded fields
pData = getappdata(hFig,'pData');
plotD = getappdata(hFig,'plotD');
hPara = getappdata(hFig,'hPara');
for i = 1:length(pData) 
    if ~isempty(pData{i}) && ~isempty(A.pData{i})      
        % retrieves the function names for the current function type
        funcT = field2cell(cell2mat(A.pData{i}(:,1)),'Func');
        
        % loops through all of the functions in the currently loaded set
        % determining the matches with the loaded data
        for j = 1:size(pData{i},1)
            % determines if there is a match between data structs
            ii = strcmp(pData{i}{j,1}.Func,funcT);
            if any(ii)
                % if so, then update the function/plotting data structs
                pData{i}(j,:) = A.pData{i}(ii,:);
                plotD{i}(j,:) = A.plotD{i}(ii,:);
            end
        end
    end
end

% resets the fields with the loaded data
setappdata(hFig,'sName',A.sData.sName)
setappdata(hFig,'fName',A.sData.fName)
setappdata(hFig,'gPara',A.gPara)
setappdata(hFig,'sPara',A.sPara)
setappdata(hFig,'plotD',plotD)
setappdata(hFig,'pData',pData)

% sets the menu item enabled properties
setObjEnable(handles.menuSaveTempData,'on')

% resets the selecting indices
[eInd,fInd,pInd] = getSelectedIndices(handles);
if fInd > 0    
    % updates the parameter struct into the parameter gui
    pObj = getappdata(hPara,'pObj');
    pObj.updatePlotData(pData{pInd}{fInd,eInd})
end

% updates the figure with the new data
% setappdata(handles.figFlyAnalysis,'eIndex',-1);
popupExptIndex_Callback(handles.popupExptIndex, '1', handles)

% ------------------------------ %
% --- DATA FILE OUTPUT ITEMS --- %
% ------------------------------ %
                    
% -------------------------------------------------------------------------
function menuSaveData_Callback(~, ~, handles)

% deletes the data output figure (if it is open)
hOut = findall(0,'tag','figDataOutput');
if ~isempty(hOut); delete(hOut); pause(0.05); end

% runs the output data sub-GUI
DataOutput(handles.figFlyAnalysis)

% -------------------------------------------------------------------------
function menuSaveStim_Callback(~, ~, handles)

% loads the data structs from the GUI
iData = getappdata(handles.figFlyAnalysis,'iData');
dFile = fullfile(iData.ProgDef.OutData,'StimData');

% prompts the user for the output file name
tStr = 'Set The Stimuli Data Output File';
fMode = {'*.csv','CSV-file (*.csv)';'*.mat','MAT-file (*.mat)'};
[fName,fDir,fIndex] = uiputfile(fMode,tStr,dFile);
if fIndex == 0
    % if the user cancelled, then exit the function
    return
else
    % retrieves the solution file data and experiment names
    snTot = getappdata(handles.figFlyAnalysis,'snTot');
    exptName = getappdata(handles.figFlyAnalysis,'sName');
    exptName = exptName(:);
    
    % sets the output file name
    fFile = fullfile(fDir,fName);
    [~,~,fExtn] = fileparts(fFile);
end

% retrieves the stimuli timing/parameter data structs
[stimP,sTrain] = field2cell(snTot,{'stimP','sTrainEx'});

% removes the empty stimuli data arrays
ii = ~cellfun(@isempty,stimP);
if any(~ii)
    % if there are any experiments with missing stimuli data, then output a
    % message to screen
    exptEmpty = exptName(~ii);
    
    % sets up the warning message
    mStr = sprintf(['The following experiments have ',...
                    'missing stimuli data:\n\n']);    
    for i = 1:length(exptEmpty)
        mStr = sprintf('%s => %s\n',mStr,exptEmpty{i});
    end    
    mStr = sprintf(['%s\nRe-check the relevant solution files to ',...
                    'ensure have been created correctly.'],mStr);
                
    % outputs the message to screen
    waitfor(warndlg(mStr,'Missing Stimuli Data','modal'))
    
    % exit if there are no valid files to output data for
    if ~any(ii); return; end
end

% removes the empty stimuli data arrays
[stimP,exptName] = deal(stimP(ii),exptName(ii));
[Ts,Tf,blkInfo,ChN] = getStimTimes(stimP,sTrain,'All');

% saves the stimuli data based on the file extension
switch fExtn
    case ('.mat')
        % saves the stimuli data to file        
        save(fFile,'exptName','stimP','Ts','Tf','blkInfo','ChN');
        
    case ('.csv')
        % saves the csv stimuli data to file
        saveCSVStimData(fFile,Ts,Tf,exptName,blkInfo,ChN);
end

% -------------------------------------------------------------------------
function menuSaveSubConfig_Callback(~, ~, handles)

% loads the data structs from the GUI
sPara = getappdata(handles.figFlyAnalysis,'sPara');
iData = getappdata(handles.figFlyAnalysis,'iData');
dDir = iData.ProgDef.OutFig; 

% prompts the user for the solution file directory
tStr = 'Set The Subplot Configuration Output File';
fMode = {'*.spp','Subplot Configuration File (*.spp)'};
[fName,fDir,fIndex] = uiputfile(fMode,tStr,dDir);
if fIndex == 0
    % if the user cancelled, then exit
    return
else
    % clears the fields
    [sPara.pData(:),sPara.plotD(:),sPara.ind(:)] = deal({[]},{[]},NaN);
    
    % outputs the subplot data struct to file
    save(fullfile(fDir,fName),'sPara');
end
    
% -------------------------------------------------------------------------
function menuSaveTempData_Callback(~, ~, handles)

% loads the data structs from the GUI
iData = getappdata(handles.figFlyAnalysis,'iData');
dDir = iData.ProgDef.TempData;

% prompts the user for the solution file directory
fMode = {'*.tdat;','Temporary Data File (*.tdat)'};
[tName,tDir,fIndex] = uiputfile(fMode,'Temporary Data File File',dDir);
if fIndex == 0
    % if the user cancelled, then exit
    return
else
    % sets the solution file name
    tName = fullfile(tDir,tName);    
end

% loads the plot/analysis function data structs 
hFig = handles.figFlyAnalysis;
plotD = getappdata(hFig,'plotD');
pData = getappdata(hFig,'pData');
gPara = getappdata(hFig,'gPara');
sPara = getappdata(hFig,'sPara');

% retrieves the solution file data string
sData = struct('fName',[],'sName',[]);
sData.fName = getFinalDirString(getappdata(hFig,'fNameFull'));
sData.sName = getappdata(hFig,'sName');

% creates the load bar
h = ProgressLoadbar('Outputting Temporarily Calculated Data To File...');

% saves the data to file
A = struct('plotD',plotD,'pData',pData,'gPara',gPara,...
           'sPara',sPara,'sData',sData);
save(tName,'-struct','A');

% closes the loadbar
try; close(h); end

% ------------------- %
% --- OTHER ITEMS --- %
% ------------------- %

% -------------------------------------------------------------------------
function menuClearData_Callback(hObject, eventdata, handles)

% handle objects
hFig = handles.figFlyAnalysis;

% prompts the user to confirm data clearing
if ~isempty(eventdata)
    qStr = 'Are you sure you want to clear all the loaded experiment data?';
    uChoice = questdlg(qStr,'Clear All Data?','Yes','No','Yes');
    if ~strcmp(uChoice,'Yes')
        % if the user cancelled, then exit the function
        return
    end
end

% disables 
hPanel = findall(hFig,'type','uipanel');
for i = 1:length(hPanel)
    switch get(hPanel(i),'tag')
        case 'panelPlot'
            % case is the plot axes
            initAxesObject(handles);
        case 'panelOuter'
            % case is the output panel (do nothing...?)
        otherwise
            % case is the other panel types
            hObjC = findall(hPanel(i),'UserData',1);
            arrayfun(@(x)(set(x,'String','')),hObjC)
            
            % removes the selection from the popupmenus
            hPopup = findall(hObjC,'Style','popupmenu');
            arrayfun(@(x)(set(x,'String',{' '},'Value',1)),hPopup);
    end
    
    % disables all the plot panels
    setPanelProps(hPanel(i),'off')
end

% deletes the analysis parameter gui (if it exists)
hPara = findall(0,'tag','figAnalysisPara');
if ~isempty(hPara)
    delete(hPara);    
end

% resets the data/object fields within the gui
setappdata(hFig,'hPara',[])
setappdata(hFig,'plotD',[])
setappdata(hFig,'pData',[])
setappdata(hFig,'sInfo',[])
setappdata(hFig,'snTot',[])
setappdata(hFig,'sName',[])
setappdata(hFig,'sNameFull',[])

% disables the relevant menu items
setObjEnable(hObject,'off')
setObjEnable(handles.menuSave,'off')
setObjEnable(handles.menuPlot,'off') 
setObjEnable(handles.menuGlobal,'off') 

% -------------------------------------------------------------------------
function menuProgPara_Callback(~, ~, handles)

% runs the program default GUI
ProgDefaultDef(handles.figFlyAnalysis,'Analysis');

% -------------------------------------------------------------------------
function menuExit_Callback(~, ~, handles)

% prompts the user if they wish to close the tracking gui
uChoice = questdlg('Are you sure want to close the Analysis GUI?',...
                     'Close Analysis GUI?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    return
end

% deletes the parameter GUI
try
    hPara = getappdata(handles.figFlyAnalysis,'hPara');
    if ~isempty(hPara)
        try; delete(hPara); end
    end
end
    
% deletes the parameter GUI
try
    hUndock = getappdata(handles.figFlyAnalysis,'hUndock');
    if ~isempty(hUndock)
        try; delete(hUndock); end
    end
end
    
% makes the main ZFTrack visible again
hDART = findall(0,'tag','figDART','type','figure');
if ~isempty(hDART)
    setObjVisibility(hDART,'on')
end

% removes the temporary analysis function directory from the path
if ~isdeployed
    iData = getappdata(handles.figFlyAnalysis,'iData');
    rmpath(iData.ProgDef.DirFunc);
end
    
% removes the temporary solution file (if it exists)
tempSolnDataIO(handles,'remove')

% closes the figure
delete(handles.figFlyAnalysis)

% -------------------------------- %
% --- PLOT MENU ITEM FUNCTIONS --- %
% -------------------------------- %

% -------------------------------------------------------------------------
function menuClearPlot_Callback(hObject, ~, handles)

% prompts the user if they want to clear the figure
uChoice = questdlg('Are you sure you want to clear the Analysis figure?',...
                   'Clear Analysis Figure?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    return
end

% clears the axis object
clearAxesObject(handles);
pData = resetPlottingData(handles);
setObjEnable(hObject,'off')

% updates the listbox/popup menu colour strings
resetExptListStrings(handles)
updateListColourStrings(handles,'func')

% resets the plot type
popupPlotType_Callback(handles.popupPlotType, '1', handles)

% deletes the parameter GUI
hPara = getappdata(handles.figFlyAnalysis,'hPara');
if ~isempty(hPara)
    pObj = getappdata(hPara,'pObj');
    pObj.updatePlotData(pData);    
    resetRecalcObjProps(handles,'Yes')    
end

% -------------------------------------------------------------------------
function menuResetData_Callback(~, eventdata, handles)

% prompts the user if they want to clear the figure
if ~isa(eventdata,'char')
    qStr = ['Are you sure you want to clear all the locally ',...
            'stored analysis data?'];
    uChoice = questdlg(qStr,'Clear Analysis Data?','Yes','No','Yes');
    if strcmp(uChoice,'Yes')
        resetAll = true;        
    else
        return        
    end
else
    resetAll = strcmp(eventdata,'All');
end

% creates a loadbar
h = ProgressLoadbar('Resetting Loaded Experimental Data...');

% retrieves the solution/subplot parameter structs
hFig = handles.figFlyAnalysis;
snTot = getappdata(hFig,'snTot');
sPara = getappdata(hFig,'sPara');

% ensures the plot/experiment type are set to proper values
[eInd,~,pInd] = getSelectedIndices(handles);
if isnan(eInd); set(handles.popupExptIndex,'value',1); end
if isnan(pInd)
    set(handles.popupPlotType,'value',2+(length(snTot)>1)); 
end
    
% rescans the analysis function directory
if isempty(getappdata(hFig,'hPara'))
    delete(h);
    return; 
else
    scanPlotFuncDir(handles)
    clearAxesObject(handles,1);
end

% determines if there are any subplots set
if size(sPara.pos,1) > 1
    % if so, then clear all the indices and other data arrays
    sPara.ind(:) = NaN;
    [sPara.plotD{:},sPara.pData{:}] = deal([]);            
    setappdata(hFig,'sPara',sPara);
    
    % updates the subplot index popup menu
    setappdata(hFig,'sInd',1);
    menuSubPlot(hFig,'1')
end

% clears the axis object and resets the plotting data structs
if resetAll
    setappdata(hFig,'pData',resetPlotDataStructs(handles,1))
    setappdata(hFig,'plotD',resetPlotDataStructs(handles))
else    
    % clears the plot data for the multi-experiments
    plotD = getappdata(hFig,'plotD'); plotD{3}(:) = {[]};
    setappdata(hFig,'plotD',plotD);   
end
    
% updates the listbox/popup menu colour strings
resetExptListStrings(handles)
updateListColourStrings(handles,'func')

% resets the plot type
popupPlotType_Callback(handles.popupPlotType, '1', handles)

% disables the listboxes
setObjProps(handles,'on')
setObjEnable(handles.menuSaveTempData,'off'); 

% deletes the parameter GUI
[hPara,pData] = deal(getappdata(hFig,'hPara'),getappdata(hFig,'pData'));
if ~isempty(hPara)        
    % updates the parameter GUI data struct
    [eInd,fInd,pInd] = getSelectedIndices(handles);
    if fInd > 0        
        resetRecalcObjProps(handles,'Yes')
        
        pObj = getappdata(hPara,'pObj');
        pObj.updatePlotData(pData{pInd}{fInd,eInd});
    else
        resetRecalcObjProps(handles,'No')
    end
end

% deletes the loadbar
delete(h);

% -------------------------------------------------------------------------
function menuUndock_Callback(~, ~, handles)

% runs the plotting GUI
UndockPlot(handles)

% -------------------------------------------------------------------------
function menuSplitPlot_Callback(~, ~, handles)

% runs the axis splitting GUI
SplitAxisClass(handles.figFlyAnalysis);

% ----------------------------------- %
% --- GLOBAL PARAMETERS MENU ITEM --- %
% ----------------------------------- %

% -------------------------------------------------------------------------
function menuGlobalParameters_Callback(~, ~, handles)

% global variables
global tDay

% runs the stimulus
[gPara,isChange] = GlobalPara(handles);

% updates the global parameter struct (if changes are made)
if isChange
    % updates the global parameter struct
    tDay = gPara.Tgrp0;
    setappdata(handles.figFlyAnalysis,'gPara',gPara);
    
    % resets all the calculated/plotted data
    menuResetData_Callback(handles.menuResetData, 'All', handles)
end

% --------------------------------------------------------------------
function menuResetPara_Callback(~, ~, handles)

% global variables
global tDay mainProgDir

% prompts the user if they wish to reset the parameter struct. 
qStr = 'Are you sure you want to reset the Global Parameters?';
uChoice = questdlg(qStr,'Reset Global Parameters?','Yes','No','Yes');
if strcmp(uChoice,'Yes')
    % if so, then re-initialise the global parameter struct
    A = load(fullfile(mainProgDir,'Para Files','ProgPara.mat'));
    gPara = A.gPara;    
    tDay = gPara.Tgrp0;
        
    % resets all the calculated/plotted data
    setappdata(handles.figFlyAnalysis,'gPara',gPara);
    menuResetData_Callback(handles.menuResetData, 'All', handles)    
end

% ------------------------------ %
% --- SUBPLOT ITEM FUNCTIONS --- %
% ------------------------------ %

% --------------------------------------------------------------------
function menuSubPlot(hObject, eventdata)

% initialisations
handles = guidata(hObject);
hFig = handles.figFlyAnalysis;
hMenuSP = handles.menuSubPlot;

hPara = getappdata(hFig,'hPara');
sPara = getappdata(hFig,'sPara');
pData = getappdata(hFig,'pData');
sInd0 = getappdata(hFig,'sInd');
fObj = getappdata(hFig,'fObj');

% retrieves the new subplot index
switch class(hObject)
    case 'matlab.ui.container.Menu'
        % case is the menu item object
        sInd = get(hObject,'UserData');
        setappdata(handles.figFlyAnalysis,'sInd',sInd);
        
    case 'matlab.ui.Figure'
        % case is the figure object
        sInd = getappdata(hObject,'sInd');
        
end
   
% resets the menu check items
set(findall(hMenuSP,'Checked','On'),'Checked','off')
set(findall(hMenuSP,'UserData',sInd),'Checked','on');

% resets the highlight panel colours
hPanel = findall(handles.panelPlot,'tag','subPanel');
set(hPanel,'HighLightColor','w');
set(findobj(hPanel,'tag','subPanel','UserData',sInd),'HighlightColor','r');

% determines if there are any valid indices selected
[eInd,fInd,pInd] = getSelectedIndices(handles);
if ~isempty(hPara) && ~isa(eventdata,'char')  
    if all([eInd,fInd,pInd] > 0)
        % if so, then update the plotting data struct
        pObj = getappdata(hPara,'pObj');
        sPara.pData{sInd0} = pObj.pData;
        setappdata(hFig,'sPara',sPara);

        % updates the plot data struct        
        pData{pInd}{fInd,eInd} = pObj.pData;
        setappdata(hFig,'pData',pData);
    end        
end

% determines if the plot data has been set for the current sub-plot
if ~isempty(sPara.pData{sInd}) && ~any(isnan(sPara.ind(sInd,:)))
    % sets the new selected indices
    fIndNw = fObj.getFuncIndex(sPara.pData{sInd}.Name,pInd);  
    
    % if so, then update the popup menu/list value 
    setObjEnable(handles.menuUndock,'on')
    setObjEnable(handles.menuSaveData,'on')
    setObjEnable(handles.buttonUpdateFigure,'on')
    set(handles.popupExptIndex,'value',sPara.ind(sInd,1))
    set(handles.popupPlotType,'value',sPara.ind(sInd,3)) 
    setSelectedNode(handles,fIndNw)
    
    % updates the parameter GUI
    if isempty(hPara)
        hPara = AnalysisPara(handles);
        setappdata(hFig,'hPara',hPara);
    else
        pObj = getappdata(hPara,'pObj');
        pObj.initAnalysisGUI()
    end
else
    % otherwise, remove the plot list
    setSelectedNode(handles)    
    setObjVisibility(hPara,'off'); 
    setObjEnable(handles.menuSaveData,'off')
    
    % enables the undocking menu item
    if size(sPara.pos,1) == 1
        setObjEnable(handles.menuUndock,'off')
    else
        setObjEnable(handles.menuUndock,any(~isnan(sPara.ind(:))))        
    end      
    
    % disables the update button
    [gCol,hButton] = deal((240/255)*[1 1 1],handles.buttonUpdateFigure);
    set(setObjEnable(hButton,'off'),'BackgroundColor',gCol)
end

% ------------------------------ %
% --- TOOLBAR ITEM FUNCTIONS --- %
% ------------------------------ %

% --------------------------------------------------------------------
function menuZoom_ClickedCallback(hObject, ~, ~)

% toggles the zoom based on the button state
if strcmp(get(hObject,'state'),'on')
    zoom on
else
    zoom off
end

% --------------------------------------------------------------------
function menuDataCursor_ClickedCallback(hObject, ~, ~)

% toggles the data cursor based on the button state
if strcmp(get(hObject,'state'),'on')
    set(setObjEnable(datacursormode(gcf),'on'),'DisplayStyle','window')    
else
    setObjEnable(datacursormode(gcf),'off')    
end

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ------------------------------------- %
% --- GUI FIGURE SPECIFIC FUNCTIONS --- %
% ------------------------------------- %

% --- Executes when figFlyAnalysis is resized.
function figFlyAnalysis_ResizeFcn(hObject, ~, handles)

% global variables
global updateFlag uTime

% resets the timer
uTime = tic;
[tWait,tPause] = deal(0.5,10);

% dont allow any update (if flag is set to 2)
if updateFlag ~= 0
    return
else
    updateFlag = 2;
    while toc(uTime) < tWait
        java.lang.Thread.sleep(tPause);
    end
end

% retrieves the plotting data/subplot data structs
sInd0 = getappdata(hObject,'sInd');
snTot = getappdata(hObject,'snTot');
pData = getappdata(hObject,'pData');
sPara = getappdata(hObject,'sPara');
hPara = getappdata(hObject,'hPara');
plotD = getappdata(hObject,'plotD');

% parameters
[Wmin,Hmin] = deal(1000,554);

% retrieves the final position of the resized GUI
fPos = getFinalResizePos(hObject,Wmin,Hmin);

% updates the figure position
try
    resetFigSize(handles,fPos)
catch
    return
end
    
% updating from the list box then exit (no need to re-update plot)
if updateFlag == 1; return; end

% checks if the plot figure needs to be updated
[isSet,nReg] = deal(false,size(sPara.pos,1));
if nReg == 1
    % if only one subplot, check to see if a valid dataset has been set
    [eInd,fInd,pInd] = getSelectedIndices(handles);    
    if all([eInd,fInd,pInd] > 0)
        [isSet,iReg] = deal(~isempty(plotD{pInd}{fInd,eInd}),true);
    end
else    
    % if multiple subplots, check each subplot to see if a valid dataset
    % has been set
    iReg = ~cellfun(@isempty,sPara.pData)';
    isSet = any(iReg);
end

% updates the plot object
if isSet
    % creates a loadbar
    h = ProgressLoadbar('Updating Analysis Plot...');

    % initialises axes and runs the plotting function
    for i = find(iReg)
        if nReg == 1
            % retrieves the axis handle
            hP = handles.panelPlot;            
            
            % retrieves the plot data struct
            if ~isempty(hPara)
                pObj = getappdata(hPara,'pObj');
                pDataNw = pObj.pData;
                plotDNw = plotD{pInd}{fInd,eInd};
            end
        else           
            % updates the subplot index
            setappdata(hObject,'sInd',i);
            
            % retrieves the axis handle
            hP = findall(handles.panelPlot,'tag','subPanel','UserData',i);
            
            % retrieves the plot data struct
            [eInd,pInd] = deal(sPara.ind(i,1),sPara.ind(i,3));
            [pDataNw,plotDNw] = deal(sPara.pData{i},sPara.plotD{i});
        end
        
        % determines if there are any annotations
        hPanelP = handles.panelPlot;
        hGG = findall(get(hPanelP,'parent'),'type','annotation');     
        
        % determines if there are any annotations        
        if ~isempty(hGG)
            isReplot = true;
        else
            rpFcn = {'Stimuli Response','Pre & Post'};
            isRPFcn = cellfun(@(x)(strContains(pDataNw.Name,x)),rpFcn);             
            hPP = findall(handles.panelPlot,'tag','hPolar');
            isReplot = (pDataNw.hasRS && isempty(hPP)) || any(isRPFcn);
        end
        
        % determines if the axis is reset or not
        if isReplot                                           
            % clears the plot axis
            initAxesObject(handles); 
            
            % recreates the new plot
            if pInd == 3
                feval(pDataNw.pFcn,snTot,pDataNw,plotDNw);           
            else
                feval(pDataNw.pFcn,reduceSolnAppPara(snTot(eInd)),...
                                            pDataNw,plotDNw);           
            end
            
            % ensures the figure is still invisible
            setObjVisibility(hObject,'off'); 
        else
            % resets the plot axis based on the number of subplots
            [hAx,hLg,m,n] = resetPlotFontResize(hP,pDataNw);
                                                
            % resets the plot axis based on the number of subplots 
            resetAxesPos(hAx,m,n);  
            
            % determines if the plots axes need to be resized for legend
            % objects that are outside the plot regions            
            if ~isempty(hLg)
                % determines if any legend objects are outside the axes
                isInAx = ~strcmp(get(hLg,'location'),'none');
                if any(~isInAx)
                    % if any legends outside of the axis, then reposition
                    set(hLg(~isInAx),'Units','Normalized')
                    resetLegendPos(hLg(~isInAx),hAx)     
                    set(hLg(~isInAx),'Units','Pixels')
                end
            end               
        end
    end

    % deletes the loadbar and makes the GUI visible again
    delete(h)            
end

% makes the figure visible again
updateFlag = 2;
setObjVisibility(hObject,'on'); 

% ensures the figure doesn't resize again (when maximised)
pause(tWait);
updateFlag = 0;

% resets the original sub-plot index
setappdata(hObject,'sInd',sInd0);

% --- figure button down callback function
function figButtonClick(hFig, ~, hP)

% determines if the mouse point is currently over the plot axes
mPos = get(hFig,'CurrentPoint');
if isOverAxes(mPos)
    % if so, then determine which object was clicked
    hHover = findAxesHoverObjects(hFig,{'tag','subPanel'},hP);
    if ~isempty(hHover)
        % updates the popup sub index 
        setappdata(hFig,'sInd',get(hHover(1),'UserData'))
        menuSubPlot(hFig,[])
    end
end

% ---------------------------------------- %
% --- EXPERIMENT INFORMATION FUNCTIONS --- %
% ---------------------------------------- %

% --- Executes on selection change in popupExptIndex.
function popupExptIndex_Callback(hObject, eventdata, handles)

% retrieves the solution struct and solution directory/file names
hFig = handles.figFlyAnalysis;
hPara = getappdata(hFig,'hPara');
pData = getappdata(hFig,'pData');
snTot = getappdata(hFig,'snTot');
eIndex = getappdata(hFig,'eIndex');

% check to see if the new experiment 
if (eIndex ~= get(hObject,'value')) || isa(eventdata,'char')
    if ~isempty(hPara)
        % updates the parameter struct in the overall array
        [~,fInd,pInd] = getSelectedIndices(handles);

        % updates the parameter struct
        if fInd > 0
            pObj = getappdata(hPara,'pObj');
            pDataOld = pObj.pData;
            if pInd == 3
                pData{pInd}{fInd,1} = pDataOld;
            else
                pData{pInd}{fInd,eIndex} = pDataOld;
            end
            
            % updates the parameter struct
            setappdata(hFig,'pData',pData);    
        end
    end
    
    % updates the experiment index and experiment information
    setappdata(hFig,'eIndex',get(hObject,'value'));
    setExptInfo(handles,snTot);         
    
    % resets the plotting function listbox
    popupPlotType_Callback(handles.popupPlotType, '1', handles)
    treeSelectChng([], '1', handles)
end   
    
% ---------------------------------------- %
% --- PLOTTING TYPE CALLBACK FUNCTIONS --- %
% ---------------------------------------- %

% --- Executes on selection change in popupPlotType.
function popupPlotType_Callback(hObject, eventdata, handles)

% retrieves the plotting data type struct
hFig = handles.figFlyAnalysis;
pData = getappdata(hFig,'pData');
pDataT = getappdata(hFig,'pDataT');
pIndex = getappdata(hFig,'pIndex');
hPara = getappdata(hFig,'hPara');
snTot = getappdata(hFig,'snTot');

% check to see if the new selection is unique
if ~isa(eventdata,'char')
    if pIndex ~= get(hObject,'value')
        if ~isempty(hPara)
            % updates the parameter struct in the overall array
            [eInd,fInd,~] = getSelectedIndices(handles);

            % updates the corresponding parameter struct
            if fInd > 0
                pObj = getappdata(hPara,'pObj');
                pDataOld = pObj.pData;
                pData{pIndex}{fInd,eInd} = pDataOld;
                setappdata(hFig,'pData',pData);
            end
        end
        
        % if so, updates the plotting function selected index
        setappdata(hFig,'pIndex',get(hObject,'value'));        
    else
        % if the selected value is not unique, then exit the function
        return
    end   
end
   
% retrieves the selected string
eStr = 'on';
lStr = cellstr(get(hObject,'string'));
indNw = get(hObject,'value');

% depending on the selection, retrieve the function names and add them to
% the list box
switch lStr{indNw}
    case ('Multi-Experiment Analysis') 
        % case is multi-solution
        A = pDataT.Multi;
        eStr = 'inactive';
        
    case ('Experiment Analysis (Population)') 
        % case is single-solution population analysis
        A = pDataT.Pop;
        
    case ('Experiment Analysis (Individual)') 
        % case is single-solution individual analysis
        A = pDataT.Indiv;      
end

% otherwise, update the function filter
if ~isa(eventdata,'char')
    fObj = getappdata(hFig,'fObj');
    fScope = getAnalysisScopeFlag(hFig);
    fObj.resetFuncFilter(snTot,pDataT,fScope);
end

% creates the explorer tree (if there are functions available)
if ~isempty(A)    
    createFuncExplorerTree(handles);   
end

% resets the experiment list strings
resetExptListStrings(handles,snTot)       
setObjEnable(handles.popupExptIndex,eStr)

if ~isa(eventdata,'char')
    treeSelectChng([], '1', handles)
end

% --- Executes on button press in toggleFuncFilter.
function toggleFuncFilter_Callback(hObject, ~, handles)

% object handles
isOpen = get(hObject,'Value');

% updates the funcion filter panel visibility            
setObjVisibility(handles.panelFuncFilter,isOpen);

% updates the toggle button string
if isOpen
    set(hObject,'String','Close Analysis Function Filter')
else
    set(hObject,'String','Open Analysis Function Filter')
end  
    
% --- Executes on button press in buttonUpdateFigure.
function buttonUpdateFigure_Callback(~, ~, handles)

% global variables
global canSelect

% retrieves the experiment/function plot index
[isAdd,canSelect] = deal(false);
pause(0.05)

% disables the listboxes
[eInd,fInd,pInd] = getSelectedIndices(handles);
setObjProps(handles,'inactive')

% retrieves the function stack and solution file data
hFig = handles.figFlyAnalysis;
gPara = getappdata(hFig,'gPara');
sPara = getappdata(hFig,'sPara');
plotD = getappdata(hFig,'plotD');
pData = getappdata(hFig,'pData');
pDataT = getappdata(hFig,'pDataT');
iData = getappdata(hFig,'iData');
snTot = getappdata(hFig,'snTot');
fcnStack = getappdata(hFig,'fcnStack');

% retrieves the parameter GUI handle
hPara = getappdata(hFig,'hPara');
try 
    guidata(hPara);
catch
    hPara = AnalysisPara(handles);
    setappdata(hFig,'hPara',hPara);
end

% memory allocation
nReg = size(sPara.pos,1);

% sets the new solution data struct for the analysis
if pInd == 3
    % case is for the multi-experiment file analysis    
    snTot = snTot(iData.indExpt);
else
    % case is for a single experiment file analysis
    snTot = reduceSolnStruct(snTot(eInd));
end

% attemps to re-intiialise the plot axis
hAx = initAxesObject(handles);

% creates the plot data struct
if isempty(pData{pInd}{fInd,eInd})
    pData{pInd}{fInd,eInd} = feval(fcnStack{fInd},snTot(1)); 
    setappdata(hFig,'pData',pData);
elseif ~isempty(hPara)
    pDataNw = feval(getappdata(hPara,'getPlotData'),hPara);
    pData{pInd}{fInd,eInd} = pDataNw;
    setappdata(hFig,'pData',pData);
end

% retrieves the necessary data structs 
pDataNw = pData{pInd}{fInd,eInd};
setObjVisibility(hPara,'off')

% runs the analysis function
try
    switch pDataNw.Name
        case ('Multi-Dimensional Scaling')
            plotDCalc = feval(pDataNw.cFcn,snTot,pDataNw,gPara,[],pDataT);             
        otherwise
            % if running the stimuli response metric calculations, then
            % update the table with the new values
            if pDataNw.hasSR
                try
                    if ~isempty(pDataNw.sP(3).Para)
                        pObj = getappdata(hPara,'pObj');
                        pObj.initAnalysisGUI();
                        setObjVisibility(hPara,'off')
                    end
                catch
                    return
                end
            end
                        
            % performs the function calculations
            plotDCalc = feval(pDataNw.cFcn,snTot,pDataNw,gPara); 
    end    
catch err
    % if there was an error with the calculations then exit with an error
    eStr = {'Error! There was an issue with the calculation function. '...
            'Read the error message associated with this issue.'};
    waitfor(errordlg(eStr,'Analysis Function Calculation Error','modal'))    
    
    % enables the listboxes again
    setObjVisibility(hPara,'on')
    setObjProps(handles,'on')
    rethrow(err)
end   

if isempty(plotDCalc)
    % if the user cancelled, then exit the function
    setObjVisibility(hPara,'on')    
    setObjProps(handles,'on')
    return    
else
    % otherwise, overwrite the struct to the new one 
    pDataNw = resetPlottingData(handles,pDataNw);    
    plotDNw = {plotDCalc};
end

% appends the new string to the legend string array
iNw = length(plotDNw);    
pDataNw.pF.Legend(1).String{iNw} = sprintf('Trace #%i',iNw);    
    
% if the parameter GUI is open, then update the struct there as well
if ~isempty(hPara)
    resetRecalcObjProps(handles,'No')
end

% sets focus to the main axis
try
    set(0,'CurrentFigure',hFig)
    set(hFig,'CurrentAxes',hAx);
catch
    % if there was an error then output an error and exit the function
    eStr = 'Error in initialising axes objects. Try recalculating.';
    waitfor(errordlg(eStr,'Plotting Axes Initialisation Error','modal'))
    return
end

% updates the main axes figure
try    
    pDataNw = feval(pDataNw.pFcn,snTot,pDataNw,plotDNw);
catch err
    % if there was an error with the calculations then exit with an error
    eStr = {'Error! There was an issue with the plotting function. '...
            'Read the error message associated with this issue'};
    waitfor(errordlg(eStr,'Analysis Function Plotting Error','modal'))   
    
    % enables the listboxes again
    setObjVisibility(hPara,'on')
    setObjProps(handles,'on')
    rethrow(err)
end   

% if the parameter GUI is open, then update the struct there as well
if ~isempty(hPara)
    pObj = getappdata(hPara,'pObj');
    pObj.updatePlotData(pDataNw);
end

% updates the sub-plot parameters (if more than one subplot)
if nReg > 1
    % retrieves the currently selected index
    sInd = getappdata(hFig,'sInd');    

    % updates the parameters
    sPara.ind(sInd,:) = [eInd,fInd,pInd];
    sPara.plotD{sInd} = {plotDCalc};
    sPara.pData{sInd} = pDataNw;
    
    % updates the sub-plot data struct
    setappdata(hFig,'sPara',sPara);    
end

% updates the new parameter data struct into the total struct
pData{pInd}{fInd,eInd} = pDataNw;
setappdata(hFig,'pData',pData);      

% sets the plot data into the main GUI
setObjEnable(handles.menuUndock,'on')
setObjEnable(handles.menuClearPlot,'on')
setObjEnable(handles.menuResetData,'on'); 
setObjEnable(handles.menuSaveTempData,'on'); 

% sets the save data menu item
isOn = ~(isempty(pDataNw.oP) || isempty(pDataNw.oP.yVar));
setObjEnable(handles.menuSaveData,isOn); 

% disables the listboxes
setObjVisibility(hPara,'on')
setObjEnable(handles.menuZoom,'on') 
setObjEnable(handles.menuDataCursor,'on') 
setObjProps(handles,'on')

% updates the plot data struct with the newly calculated values
plotD{pInd}{fInd,eInd} = plotDNw;
setappdata(hFig,'plotD',plotD);  

% updates the listbox/popup menu colour strings
resetExptListStrings(handles)
updateListColourStrings(handles,'func')

% reset the selection flag
canSelect = true;

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% ----------------------------------- %
% --- DATA STRUCT INITIALISATIONS --- %
% ----------------------------------- %

% --- initialises the program data struct
function iData = initDataStruct(handles,ProgDefNew)

% global variables
global mainProgDir

% initialises the format structs and calculates the fixed metrics
iData = struct('fmtStr',[],'ProgDef',[],'indExpt',[]);
       
% sets the sub-fields        
if isempty(ProgDefNew)
    iData.ProgDef = initProgDef(handles);
else
    % if the temporary calculated data field is not set, then create it
    if ~isfield(ProgDefNew,'TempData')
        % sets the data directory name
        tDir = fileparts(ProgDefNew.TempFile);
        nwDir = fullfile(tDir,'3 - Temporary Data');    
        if ~exist(nwDir,'dir')
            % if the directory does not exist, then create it
            mkdir(nwDir)
        end    

        % sets the new fields into the data struct
        ProgDefNew.TempData = nwDir;
        ProgDefNew.fldData.TempData = {'Analysis','3 - Temporary Data'};
        
        % updates the default directory defaults file
        hDART = guidata(findall(0,'tag','figDART'));
        ProgDef = getappdata(hDART.figDART,'ProgDef');    
        ProgDef.Analysis = ProgDefNew;
        setappdata(hDART.figDART,'ProgDef',ProgDef)        
        set(hDART.buttonFlyAnalysis,'UserData',ProgDefNew)
        
        % updates the program default file
        progFile = fullfile(mainProgDir,'Para Files','ProgDef.mat');    
        save(progFile,'ProgDef');
    end    
    
    % sets the program default data struct
    iData.ProgDef = ProgDefNew;
end

% ------------------------------ %
% --- GUI PROPERTY FUNCTIONS --- %
% ------------------------------ %

% --- initialises the plotting image axis 
function hAx = initAxesObject(handles)

% global variables
global isDocked newSz

% retrieves the sub-plot parameter struct
cbFcn = [];
uStr = 'pixels';
hFig0 = handles.figFlyAnalysis;
sInd = getappdata(hFig0,'sInd');
sPara = getappdata(hFig0,'sPara');    

% sets the units string/axis handles for setting up the figure   
if isDocked
    % retrieves the sub-plot parameter struct
    [h,hFig] = deal(handles,hFig0);
    sInd = getappdata(hFig,'sInd');
    sPara = getappdata(hFig,'sPara');    
else
    % if the plot axis is undocked, then use normalized coordinates
    hFig = getappdata(hFig0,'hUndock');
    h = guidata(hFig);            
end
       
% makes the GUI invisible and deletes all previous axes objects
clearAxesObject(handles)
    
% creates a new axis
hAx = axes('Units','normalized','outerposition',[0 0 1 1]);
axis(hAx,'off');    

% determines how many axis there are
if size(sPara.pos,1) == 1       
    % only one axis, so set with the overall plot panel
    set(hAx,'parent',h.panelPlot,'Units',uStr)        
    set(h.panelPlot,'Units','Pixels')
    newSz = get(h.panelPlot,'position');
    
else
    % sets the button down callback function
    cbFcn = {@figButtonClick,handles.panelPlot};
    
    % set the plot within the new plot panel    
    hPanel = findall(h.panelPlot,'tag','subPanel','UserData',sInd);                          
    set(hAx,'parent',hPanel,'Units',uStr,'UserData',sInd)        

    % retrieves the panel dimensions (in pixels)
    set(hPanel,'Units','Pixels')        
    newSz = get(hPanel,'position');
    set(hPanel,'Units','Normalized')        
end

% clears the axis and ensures it is off
set(0,'CurrentFigure',hFig)
set(hFig,'CurrentAxes',hAx,'WindowButtonDownFcn',cbFcn)
cla(hAx); rotate3d(hAx,'off');     

% --- initialises the plotting image axis 
function clearAxesObject(handles,varargin)

% global variables
global isDocked

% retrieves the sub-plot parameter struct
sPara = getappdata(handles.figFlyAnalysis,'sPara');
nReg = size(sPara.pos,1);

% deletes all the axis objects
if nReg == 1
    if isDocked       
        h = handles.figFlyAnalysis;
        hAx = findall(handles.panelPlot,'type','axes');    
    else
        h = getappdata(handles.figFlyAnalysis,'hUndock');
        hAx = findall(h,'type','axes');
    end
    
    % deletes the axis objects (if they exist)
    if ~isempty(hAx); delete(hAx); end
else
    % sets the currently selected index
    if nargin == 1
        sInd = getappdata(handles.figFlyAnalysis,'sInd');
    else
        sInd = 1:nReg;
    end
    
    % retrieves the axis objects for all the selected indices
    for i = sInd
        if isDocked
            % case is the figure is docked
            h = handles.figFlyAnalysis;
            hP = findall(handles.panelPlot,'tag','subPanel','UserData',i);
        else
            % case is the figure is undocked
            h = getappdata(handles.figFlyAnalysis,'hUndock');
            hP = findall(h,'tag','subPanel','UserData',i);
        end    
    
        % retrieves the axis object
        hAx = findall(hP,'type','axes');
        if ~isempty(hAx); delete(hAx); end
    end        
end

% removes any annotations
hGG = findall(h,'type','annotation');
if ~isempty(hGG); delete(hGG); end
    
% --- initialises the object properties within the GUI 
function initGUIObjects(handles)

% disables all the panels
setPanelProps(handles.panelSolnData,'off')
setPanelProps(handles.panelExptInfo,'off')
setPanelProps(handles.panelPlotFunc,'off')
setPanelProps(handles.panelFuncDesc,'off')    

% makes the panel description object invisible
setObjVisibility(handles.textFuncDesc,'off')
setObjVisibility(handles.textFuncDescBack,'off')

% disables the save menu item
setObjEnable(handles.menuOpenTempData,'off')
setObjEnable(handles.menuSaveData,'off')
setObjEnable(handles.menuSaveStim,'off')
setObjEnable(handles.menuSaveTempData,'off')
setObjEnable(handles.menuSaveSubConfig,'off')
setObjEnable(handles.menuClearPlot,'off')
setObjEnable(handles.menuUndock,'off')
setObjEnable(handles.menuResetData,'off')
setObjEnable(handles.menuSplitPlot,'off')

% calculates the global axes coordinates
resetPlotPanelCoords(handles)

% --- resizes the analysis GUI objects
function resetFigSize(h,fPos)

% sets the overall width/height of the figure
[W0,H0,dY,dX,yOfs] = deal(fPos(3),fPos(4),10,10,30);
[HLF,YLF] = deal(H0-475,105);

pPosF = get(h.panelFuncFilter,'Position');
[pPosO,HPF] = deal(get(h.panelOuter,'position'),HLF+220);

% resets the plot panel dimensions
pPosPnw = [sum(pPosO([1 3]))+dX,dY,(W0-(3*dX+pPosO(3))),(H0-2*dY)];
set(h.panelPlot,'units','pixels','position',pPosPnw)

% updates the plot listbox/panel position
WPI = pPosO(3) - 2*dX;
set(h.panelPlotFunc,'position',[dX,dY,WPI,HPF]);

% resizes the function list panel + objects
pPosF = [dX,YLF,WPI-2*dX,HLF];
hTree = findall(h.panelFuncList,'type','hgjavacomponent');
set(h.panelFuncList,'position',pPosF);
set(hTree,'Position',[(dX/2)*[1,1],pPosF(3:4)-2*dX])

% resets the analysis scope object positions
yBot0 = YLF+HLF+dY/2;
[yBot1,yBot2] = deal(yBot0+yOfs,yBot0+2*yOfs);

resetObjPos(h.buttonUpdateFigure,'bottom',yBot0);
resetObjPos(h.textFuncFilter,'bottom',yBot1+3);
resetObjPos(h.toggleFuncFilter,'bottom',yBot1);
resetObjPos(h.panelFuncFilter,'bottom',yBot1-(pPosF(4)-1));
resetObjPos(h.textPlotType,'bottom',yBot2+3);
resetObjPos(h.popupPlotType,'bottom',yBot2);

% updates the experiment information panel position
resetObjPos(h.panelExptInfo,'bottom',(3/2)*dY + HPF);

% sets the other panel positions
pPosE = get(h.panelExptInfo,'position');
resetObjPos(h.panelSolnData,'bottom',sum(pPosE([2 4])) + dY/2);
resetObjPos(h.panelOuter,'Height',fPos(4) - 2*dY)

% ------------------------------------------- %
% --- PROGRAM DEFAULT DIRECTORY FUNCTIONS --- %
% ------------------------------------------- %

% --- initialises and confirms that A) the program default file exists, and
%     B) the directories listed in the file are valid 
function ProgDef = initProgDef(handles)

% global variables
global mainProgDir

% sets the program default file name
progFileDir = fullfile(mainProgDir,'Para Files');
progFile = fullfile(progFileDir,'ProgDef.mat');

% creates the directory (if it doesn't exist)
if ~exist(progFileDir,'dir'); mkdir(progFileDir); end

% determines if the program defaults have been set
if exist(progFile,'file')
    % if so, loads the program preference file and set the program
    % preferences (based on the OS type)
    A = load(progFile);
    ProgDef = checkDefaultDir(A.ProgDef);         
else
    % displays a warning
    uChoice = questdlg(['Program default file not found. Would you like ',...
        'to setup the program fefault file manually or automatically?'],...
        'Program Default Setup','Manually','Automatically','Manually');
    switch uChoice
        case 'Manually'
            % user chose to setup manually, so load the ProgDef sub-GUI
            ProgDef = ProgParaAnalysis(handles.figFlyAnalysis,[],1);
        case 'Automatically'
            % user chose to setup automatically then create the directories            
            ProgDef = setupAutoDir(mainProgDir,progFile);
            pause(0.05); % pause required otherwise program crashes?
    end
end

% --- checks if the program default directories exist ---------------------
function [ProgDef,isExist] = checkDefaultDir(ProgDef,varargin)

% retrieves the field names
fldNames = fieldnames(ProgDef);
isExist = true(length(fldNames),1);

% loops through all the field names determining if the directories exist
for i = 1:length(fldNames)
    % sets the new variable string
    nwVar = sprintf('ProgDef.%s',fldNames{i});
    nwDir = eval(nwVar);
    fType = 'dir';
    
    % if no directory has not set, then set the field names
    switch fldNames{i}
        case 'DirSoln'
            [dirName,type] = deal('Video Solution','file');
        case 'DirComb'
            [dirName,type] = deal('Experiment Solution','file');
        case 'OutFig'
            [dirName,type] = deal('Figure Output','directory');
        case 'OutData'
            [dirName,type] = deal('Data Output','directory');
        case 'DirFunc'
            [dirName,type] = deal('Analysis Function','directory');
        case 'TempFile'
            [dirName,type] = deal('Temporary File','directory');
    end
    
    % check to see if the directory exists
    if isempty(nwDir)
        % flag that the directory has not been set
        isExist(i) = false;
        if nargin == 1
            wStr = sprintf('Warning! The "%s" %s is not set.',dirName,type);
            waitfor(warndlg(wStr,'Directory Location Error','modal'))   
        end
        
    elseif ~exist(nwDir,fType)
        % if the directory does not exist, then clear the directory field
        % and flag a warning
        isExist(i) = false;
        eval(sprintf('%s = [];',nwVar));        
        if nargin == 1
            wStr = sprintf('Warning! The "%s" %s does not exist.',...
                            dirName,type);
            waitfor(warndlg(wStr,'Missing File/Directory','modal'))
        end
    end
end

% if any of the directories do not exist, then
if any(~isExist)
    % runs the program default sub-ImageSeg
    if nargin == 1
        ProgDef = ProgParaAnalysis(handles.figFlyAnalysis,ProgDef,1);
    end
end

% --- function that automatically sets up the default directories 
function ProgDef = setupAutoDir(progDir,progFile)

% otherwise, create the
baseDir = fullfile(progDir,'Data Files');

% sets the default directory names
a.DirSoln = fullfile(baseDir,'Solution Files (Video)');
a.DirComb = fullfile(baseDir,'Solution Files (Experiment)');
a.OutFig = fullfile(baseDir,'Analysis Figures');
a.OutData = fullfile(baseDir,'Analysis Data');
a.DirFunc = fullfile(baseDir,'Analysis Functions');
a.TempFile = fullfile(baseDir,'Temporary Files');

% creates the new default directories (if they do not exist)
b = fieldnames(a);
for i = 1:length(b)
    % sets the new directory name
    nwDir = eval(sprintf('a.%s',b{i}));

    % if the directory does not exist, then create it
    if exist(nwDir,'dir') == 0
        mkdir(nwDir)
    end
end

% saves the program default file
ProgDef = a;
save(progFile,'ProgDef');

% ------------------------------ %
% --- FUNCTION EXPLORER TREE --- %
% ------------------------------ %

% --- creates the function explorer tree
function createFuncExplorerTree(handles)

% initialisations
hFig = handles.figFlyAnalysis;
hPanel = handles.panelFuncList; 
[eInd,~,pInd] = getSelectedIndices(handles);

% field retrieval
fObj = getappdata(hFig,'fObj');
plotD = getappdata(hFig,'plotD');

% resets the experiment compatibility flags
fScope = getAnalysisScopeFlag(hFig);
fObj.detExptCompatibility(fScope);

% retrieves the requirement fields for each feasible function
rFld = fieldnames(fObj.rGrp);
indS = find(any(fObj.cmpData,2));
X = fObj.fcnData(indS,3:end); 

% retrieves the currently selected nodes
sNode = fObj.getSelectedNodes();
sFld = fieldnames(sNode);

% loops through each of the feasible functions mapping them to their
% location within the plot data struct
[Imap,iCol] = deal(NaN(size(X)),zeros(length(sFld),1));
for i = 1:length(sFld)
    % retrieves the node field
    iCol(i) = find(strcmp(rFld,sFld{i}))-1;
    sNodeS = getStructField(sNode,sFld{i});
    
    % sets the mapping values
    for k = 1:length(sNodeS)
        Imap(strcmp(X(:,iCol(i)),sNodeS{k}),iCol(i)) = k;
    end
end

% determines the unique mappings
indF = find(~any(isnan(Imap(:,iCol)),2));
[ImapU,~,iC] = unique(Imap(indF,iCol),'rows');

% ------------------------------ %
% --- EXPLORER TREE CREATION --- %
% ------------------------------ %

% initialisations
dX = 10;
pPos = get(hPanel,'Position');
tPos = [dX*[1,1],pPos(3:4)-2*dX];
fcnName = fObj.fcnData(indS,1);
rootStr = setHTMLColourString('kb','Function List',1);

% disables the update button
[gCol,hButton] = deal((240/255)*[1 1 1],handles.buttonUpdateFigure);
set(setObjEnable(hButton,'off'),'BackgroundColor',gCol)
set(handles.textFuncDesc,'String','')

% deletes any previous explorer trees
hTree0 = findall(hPanel,'type','hgjavacomponent');
if ~isempty(hTree0); delete(hTree0); end

% Root node
hRoot = createUITreeNode(rootStr, rootStr, [], false);
set(0,'CurrentFigure',hFig);

% creates all the sub-parent/children nodes
for i = 1:size(ImapU,1)
    % creates the tree parent node
    hNodeP = createTreeParent(hRoot,sNode,ImapU(i,:));
    
    % adds the leaf nodes for each of the functions
    indC = indF(iC == i);
    for j = 1:length(indC)
        % retrieves the function name/index
        fcnNameNw = fcnName{indC(j)};
        iFcn = fObj.Imap(indS(indC(j)),pInd);
        
        % if there is plot data, then set the string to red
        if all([pInd,iFcn,eInd] > 0)
            if ~isempty(plotD{pInd}{iFcn,eInd})
                fcnNameNw = setHTMLColourString('r',fcnNameNw,1);
            end
        end
        
        % creates the new tree node  
        hNodeNw = createUITreeNode(fcnNameNw,fcnNameNw,[],true);             
        hNodeNw.setUserObject(iFcn);
        hNodeP.add(hNodeNw);
    end
end

% creates the tree object
wState = warning('off','all');
[hTreeF,hC] = uitree('v0','Root',hRoot,'position',tPos,...
                     'SelectionChangeFcn',{@treeSelectChng,handles});
set(hC,'Visible','off')
set(hC,'Parent',hPanel,'visible','on')
warning(wState);

% hTreeF.expand(hRoot)
expandExplorerTreeNodes(hTreeF)
setappdata(hFig,'hTreeF',hTreeF)

% ensures the function filter is always on top
uistack(handles.panelFuncFilter,'top')

% --- updates the parameter based on the selection
function treeSelectChng(~, eventdata, handles)

% global variables
global updateFlag isUpdating

% determines if the 
if isUpdating
    return
else
    updateFlag = 1;
end

% field retrieval
hFig = handles.figFlyAnalysis;
sPara = getappdata(hFig,'sPara');
plotD = getappdata(hFig,'plotD');
pData = getappdata(hFig,'pData');

% disables the listboxes
setObjProps(handles,'inactive')
[eInd,fIndNw,pInd] = getSelectedIndices(handles);
[isShowPara,nReg] = deal(fIndNw > 0,size(sPara.pos,1));
hTree = findall(handles.panelFuncList,'type','hgjavacomponent');

% disables the tree object
setObjEnable(hTree,'off');

% sets the function description
if all([pInd,fIndNw,eInd] > 0)
    % sets the required object handles/data structs
    set(handles.textFuncDesc,'enable','on',...
                    'string',pData{pInd}{fIndNw,eInd}.fDesc);        
else
    % non-function field is not selected
    set(handles.textFuncDesc,'string','');
    if nReg == 1
        setObjEnable(handles.menuUndock,'off')
    end
end

% retrieves the current node
if isShowPara
    % enables the calculate/plot function button    
    setObjEnable(handles.buttonUpdateFigure,'on')        
    
    % checks to see if the plot index has changed index
    fIndex = getappdata(hFig,'fIndex');
    if (fIndex ~= fIndNw) || isa(eventdata,'char') || (nReg > 1)
        % clears the plot axis and resets the data
        if ~isa(eventdata,'char'); eventdata = '0'; end
        clearAxesObject(handles)                       
        
        % creates the new parameter GUI
        hPara = getappdata(hFig,'hPara');
        if isempty(hPara)
            hPara = AnalysisPara(handles);
            setappdata(hFig,'hPara',hPara);
            
            % if there is more than one subplot, update the data values
            if nReg > 1
                % retrieves the currently selected index
                sInd = getappdata(hFig,'sInd');

                % updates the parameters
                sPara.ind(sInd,:) = [eInd,fIndNw,pInd];
                sPara.pData{sInd} = pData{pInd}{fIndNw,eInd};
                sPara.plotD{sInd} = plotD{pInd}{fIndNw,eInd};

                % updates the sub-plot data struct
                setappdata(hFig,'sPara',sPara);            
            end              
        else
            % updates the parameter struct in the overall array
            if (fIndex > 0) && (str2double(eventdata) == 0)                 
                % updates the 
                pObj = getappdata(hPara,'pObj');
                pDataOld = pObj.pData;
                pData{pInd}{fIndex,eInd} = pDataOld;
                setappdata(hFig,'pData',pData);
            end
            
            % if there is more than one subplot, update the data values
            if nReg > 1
                % retrieves the currently selected index
                sInd = getappdata(hFig,'sInd');

                % updates the parameters
                sPara.ind(sInd,:) = [eInd,fIndNw,pInd];
                sPara.pData{sInd} = pData{pInd}{fIndNw,eInd};
                sPara.plotD{sInd} = plotD{pInd}{fIndNw,eInd};

                % updates the sub-plot data struct
                setappdata(hFig,'sPara',sPara);            
            end             
            
            % reinitialises the function parameter struct 
            if ishandle(hPara)
                % if the gui is valid, then re-initialise it
                pObj = getappdata(hPara,'pObj');
                pObj.initAnalysisGUI();
            else
                % if the gui is not valid, then recreate the gui
                hPara = AnalysisPara(handles);
                setappdata(hPara,'hPara',hPara);
            end
            
            % retrieves the plotting data struct
            pData = getappdata(hFig,'pData');
        end
        
        % makes the parameter GUI         
        setappdata(hFig,'fIndex',fIndNw)
    else
        % if the selection was not unique, then exit the function
        setObjProps(handles,'on')
        return
    end
    
else
    % clears the axes and resets the experiment listbox strings    
    clearAxesObject(handles) 
    
    % disables the calculate/plot function button
    resetRecalcObjProps(handles,'No')
    setObjEnable(handles.buttonUpdateFigure,'off')        
    setappdata(hFig,'fIndex',0)
    
    % makes the parameter figure invisible 
    hPara = getappdata(hFig,'hPara');
    setObjVisibility(hPara,'off');
end

% determines if there is any previous stored plotting values
[eInd,fInd,pInd] = getSelectedIndices(handles);
if all([eInd,fInd,pInd] > 0)
    % enables/disables the hold menu item (depending on whether the
    % hold flag is set to true)        
    if ~isempty(plotD{pInd}{fInd,eInd})              
        % if there is, then replot the data        
        snTot = getappdata(hFig,'snTot'); 
        pDataNw = pData{pInd}{fInd,eInd};        
                
        % initialises axes and runs the plotting function
        initAxesObject(handles);            
        if pInd == 3
            feval(pDataNw.pFcn,snTot,pDataNw,plotD{pInd}{fInd,eInd});           
        else
            feval(pDataNw.pFcn,reduceSolnAppPara(snTot(eInd)),...
                                        pDataNw,plotD{pInd}{fInd,eInd});           
        end                           
        
        % enables the listboxes/popup menus
        setObjProps(handles,'on')
        
        % enables the clear plot menu item
        setObjEnable(handles.menuUndock,'on')
        setObjEnable(handles.menuClearPlot,'on')
        setObjEnable(handles.menuZoom,'on')                
        setObjEnable(handles.menuDataCursor,'on')                        
        if isShowPara; setObjVisibility(hPara,'on'); end
        
        % if there are output data parameters, then enable the save menu
        if isempty(pData{pInd}{fInd,eInd}.oP)
            setObjEnable(handles.menuSaveData,'off'); 
        elseif isempty(pData{pInd}{fInd,eInd}.oP.yVar)
            setObjEnable(handles.menuSaveData,'off'); 
        else
            setObjEnable(handles.menuSaveData,'on');
        end   
        
        % resets the flag
        updateFlag = 0;               
        
        % exits the function
        return
    else
        % otherwise, disable the menu items
        setObjEnable(handles.menuZoom,'off')                
        setObjEnable(handles.menuDataCursor,'off')   
        
        % enables the undocking menu item
        if nReg == 1
            setObjEnable(handles.menuUndock,'off')
        end
    end    
else
    % enables the undocking menu item
    if nReg == 1
        setObjEnable(handles.menuUndock,'off')
    end    
end

% if there is more than one subplot, update the data values
if nReg > 1
    % retrieves the currently selected index
    sInd = getappdata(hFig,'sInd');

    % updates the parameters
    sPara.ind(sInd,:) = NaN;
    sPara.plotD{sInd} = [];
    sPara.pData{sInd} = [];

    % updates the sub-plot data struct
    setObjEnable(handles.menuUndock,any(~isnan(sPara.ind(:))))
    setappdata(hFig,'sPara',sPara);            
end

% enables the listboxes/popup menus
setObjProps(handles,'on')
setObjEnable(hTree,'on');

% disables the clear plot menu item
if isShowPara; setObjVisibility(hPara,'on'); end
setObjEnable(handles.menuSaveData,'off')
setObjEnable(handles.menuClearPlot,'off')

% resets the flag
updateFlag = 0;

% --- creates the tree parent node
function hNodeP = createTreeParent(hNodeP,sNode,Imap)

% initialisations
fStr = fieldnames(sNode);

% 
for i = 1:length(Imap)   
    % retrieves the struct field
    isAdd = true;
    fVal = getStructField(sNode,fStr{i});
    
    % determines if a new 
    if hNodeP.getChildCount > 0
        % retrieves the names of the children nodes
        xiC = (1:hNodeP.getChildCount)' - 1;
        hNodeC = arrayfun(@(x)(hNodeP.getChildAt(x)),xiC,'un',0);
        nodeName = cellfun(@(x)(char(x.getUserObject)),hNodeC,'un',0);
        
        % determines if there is a match
        hasC = strcmp(nodeName,fVal{Imap(i)});
        if any(hasC)
            % if so, then update the parent node
            [hNodeP,isAdd] = deal(hNodeC{hasC},false);
        end
    end
    
    % creates the new tree node (if required)
    if isAdd
        % sets up the node string
        nodeStr0 = getNodeString(fStr{i},fVal{Imap(i)});
        nodeStr = setHTMLColourString('kb',nodeStr0,1);
        
        % creates the new node      
        hNodeNw = createUITreeNode(nodeStr,nodeStr,[],false);
        hNodeNw.setUserObject(fVal{Imap(i)});
        hNodeP.add(hNodeNw);
        
        % resets the parent node
        hNodeP = hNodeNw;
    end
end

% --- sets up the tree node string
function nodeStr = getNodeString(fStr,fVal)

switch fStr
    case 'Dur'
        % case is the duration requirement
        switch fVal
            case 'Short'
                % case is short expts only
                nodeStr = 'Short Experiment Functions';
                
            case 'Long'
                % case is long expts only
                nodeStr = 'Long Experiment Functions';
                
            case 'None'
                % case is duration independent
                nodeStr = 'Duration Independent Functions';
        end
        
    case 'Shape'
        % case is the experiment shape requirement
        switch fVal
            case '1D'
                % case is 1D expts 
                nodeStr = 'General 1D Functions';
                
            case '2D'
                % case is 2D expts 
                nodeStr = 'General 2D Functions';
                
            case '2D (Circle)'
                % case is 2D Circle expts
                nodeStr = '2D (Circle) Functions';
                
            case '2D (General)'
                % case is 2D General shape expts 
                nodeStr = '2D (General) Functions';
                
            case 'None'
                % case is shape independent
                nodeStr = 'Shape Independent Functions';
        end        
        
    case 'Stim'
        % case is the duration requirement
        switch fVal
            case 'Motor'
                % case is motor stimuli expts
                nodeStr = 'Motor Stimuli Functions';
                
            case 'Opto'
                % case is opto stimuli expts
                nodeStr = 'Opto Stimuli Functions';
                
            case 'None'
                % case is stimuli independent expts
                nodeStr = 'Stimuli Independent Functions';
        end        
        
    case 'Spec'
        % case is special experiments
        switch fVal
            case 'None'
                % case is duration independent
                nodeStr = 'Non-Speciality Functions';
        end        
        
end

% --- retrieves the explorer tree node for the iExp
function expandExplorerTreeNodes(hTree)

for i = 1:hTree.getRoot.getLeafCount
    % sets the next node to search for
    if i == 1
        % case is from the root node
        hNodeP = hTree.getRoot.getFirstLeaf;
    else
        % case is for the other nodes
        hNodeP = hNodeP.getNextLeaf;
    end
    
    % retrieves the selected node
    hTree.expand(hNodeP.getParent);
end

% --- sets the selected node to function with user data, iFcn 
function setSelectedNode(handles,iFcn)

% global variables
global isUpdating
isUpdating = true;

% object retrieval
hFig = handles.figFlyAnalysis;
hTreeF = getappdata(hFig,'hTreeF');

% retrieves the function id flags for each node
hNodeL = getAllLeafNodes(hTreeF.getRoot);

% updates the selected node
if exist('iFcn','var')
    iFcnN = cellfun(@(x)(x.getUserObject),hNodeL);
    hTreeF.setSelectedNode(hNodeL{iFcn==iFcnN});
else
    hTreeF.setSelectedNode(hNodeL{1});
end   

% resets the update flag
pause(0.05);
isUpdating = false;

% --- retrieves all leaf nodes from the explorer tree
function hNodeL = getAllLeafNodes(hNodeP)

% memory allocation
hNodeL = [];

% search for all leaf nodes for the current parent node
for i = 1:hNodeP.getChildCount
    % retrieves the next child node
    hNodeC = hNodeP.getChildAt(i-1);
    if hNodeC.isLeafNode
        % if a leaf node, then store the node handle
        hNodeL = [hNodeL;{hNodeC}];
    else
        % otherwise, search the children of the non-leaf node
        hNodeLNw = getAllLeafNodes(hNodeC);
        if ~isempty(hNodeLNw)
            % if leaf nodes were found, then add them to the stored list
            hNodeL = [hNodeL;hNodeLNw(:)];
        end
    end
end

% ---------------------------------- %
% --- INFO DATA STRUCT FUNCTIONS --- %
% ---------------------------------- %

% --- separates the solution file information data struct into
%     its components (snTot is used for analysis)
function [snTot,sInfo] = separateInfoDataStruct(hFig,sInfo)

% memory allocation
nExp = length(sInfo);
snTot = cell(nExp,1);

% removes any apparatus information fields
for i = 1:nExp
    if isfield(sInfo{i}.snTot,'appPara')
        sInfo{i}.snTot = rmfield(sInfo{i}.snTot,'appPara');
    end
end

% % retrieves the fieldname from each solution file
% fName = cellfun(@(x)(fieldnames(x.snTot)),sInfo,'un',0)';

% separates the data struct (removes snTot from sInfo)
for i = 1:nExp
    if i == 1
        snTot{i} = sInfo{i}.snTot;
    else
        snTot{i} = orderfields(sInfo{i}.snTot,snTot{1});
    end
        
    sInfo{i}.snTot = [];
end

% converts the solution file data cell array into a struct array
snTot = cell2mat(snTot);

% updates the data struct into the gui
setappdata(hFig,'sInfo',sInfo)
setappdata(hFig,'snTot',snTot)

% --- combines the solution data and information structs into a single
%     data struct (to be used for opening file data)
function combineInfoDataStructs(hFig)

% retrieves the data structs
sInfo = getappdata(hFig,'sInfo');
snTot = num2cell(getappdata(hFig,'snTot'));

% sets the solution data field for each experiment
for i = 1:length(sInfo)
    % separates the multi-experiment group names
    gName = separateMultiExptGroupNames(snTot{i});    
    
    % updates the group names
    snTot{i}.iMov.pInfo.gName = gName;
    
    % converts the data value arrays for the new format files
    snTot{i} = splitAcceptanceFlags(snTot{i});
    sInfo{i}.snTot = convertDataArrays(snTot{i});
    sInfo{i}.snTot.iMov = reduceRegionInfo(sInfo{i}.snTot.iMov);  
    sInfo{i}.gName = gName;
    
    % converts the data arrays
    snTot{i} = [];
end

% updates the solution file info into the gui
setappdata(hFig,'snTot',[])
setappdata(hFig,'sInfo',sInfo)

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- sets the solution file in
function setSolnInfo(handles)

% object retrieval
hFig = handles.figFlyAnalysis;

% field retrieval
if ~exist('snTot','var'); snTot = getappdata(hFig,'snTot'); end

% retrieves the currently selected indices and plot types
iMov = snTot(1).iMov;
[nExp,nGrp] = deal(length(snTot),length(iMov.pInfo.gName));

% avg expt duration
Ts = arrayfun(@(x)(x.T{1}(1)),snTot);
Tf = arrayfun(@(x)(x.T{end}(end)),snTot);
[~,~,tStr] = calcTimeDifference(60*roundP(mean(Tf-Ts)/60));
durStr = sprintf('%s Days, %s Hours, %s Mins',tStr{1},tStr{2},tStr{3});

% expt setup type
if snTot(1).iMov.is2D
    if isempty(iMov.autoP)
        % case is no region shape was used
        setupStr = 'General 2D Region Setup';
    else        
        % sets the region string 
        switch iMov.autoP.Type
            case 'Circle'
                setupStrS = 'Circle';
            case 'GeneralR'
                setupStrS = 'General Repeating';            
            case 'GeneralC'
                setupStrS = 'General Custom';
        end   
        
        % sets the final string
        setupStr = sprintf('2D Grid (%s Regions)',setupStrS);
    end
else
    % case is a 1D experimental setup
    setupStr = '1D Test-Tube Assay';
end

% sets up the stimuli type string
if isempty(snTot(1).stimP)
    % no external stimuli
    stimStr = 'No External Stimuli';
else
    % external stimuli, so strip out the stimuli types
    stimType = strjoin(fieldnames(snTot(1).stimP)','/');
    stimStr = sprintf('%s External Stimuli',stimType);
end

% updates the information fields
set(handles.textExptCount,'string',num2str(nExp))
set(handles.textGrpCount,'string',num2str(nGrp))
set(handles.textAvgDur,'string',durStr)
set(handles.textSetupType,'string',setupStr)
set(handles.textStimType,'string',stimStr)

% enables the solution data panel
setPanelProps(handles.panelSolnData,'on');

% --- resets the GUI objects with the new solution file struct, snTot 
function resetGUIObjects(handles,varargin)

% global variables
global updateFlag
updateFlag = 0;

% retrieves the solution struct and solution directory/file names
hFig = handles.figFlyAnalysis;
if nargin == 1
    snTot = getappdata(hFig,'snTot');    
else
    snTot = varargin{1};
end

% updates the experiment indices
iData = getappdata(hFig,'iData');    
iData.indExpt = true(length(snTot),1);
setappdata(hFig,'iData',iData)    

% initialises the experiment, function type and plotting function indices
setappdata(hFig,'eIndex',1)
setappdata(hFig,'fIndex',0)

% resets the plot data structs
setappdata(hFig,'pData',resetPlotDataStructs(handles,1))
setappdata(hFig,'plotD',resetPlotDataStructs(handles))

% resets the popup menu items
sName = getappdata(hFig,'sName');
sName = cellfun(@(x)(simpFileName(x,18)),sName,'un',0);
set(handles.popupExptIndex,'string',sName,'value',1)

% sets the experiment information 
clearAxesObject(handles)
setPlotInfo(handles,snTot);

% enables the menu/toolbar items
setObjEnable(handles.menuResetData,'on')
setObjEnable(handles.menuZoom,'off') 
setObjEnable(handles.menuDataCursor,'off') 
setObjEnable(handles.menuGlobal,'on') 
setObjEnable(handles.menuPlot,'on')
setObjEnable(handles.menuSplitPlot,'on')
setObjEnable(handles.menuSaveData,'off')
setObjEnable(handles.menuSaveTempData,'off')
setObjEnable(handles.menuSaveSubConfig,'off')
setObjEnable(handles.menuOpenSubConfig,'on')
setObjEnable(handles.menuOpenTempData,'on')
setObjEnable(handles.menuClearData,'on')

% removes any existing panels/plots
hPanel = findall(handles.panelPlot,'tag','subPanel');
if ~isempty(hPanel); delete(hPanel); end    

% updates the plot type popup
popupPlotType_Callback(handles.popupPlotType, '1', handles)

% % resets the experiment listbox strings 
% resetExptListStrings(handles,snTot)

% --- resets the experiment listbox strings 
function resetExptListStrings(handles,snTot)

% retrieves the solution struct (if not provided)
hFig = handles.figFlyAnalysis;
if nargin == 1
    snTot = getappdata(hFig,'snTot');
end

% determines the currently selected plot type index value
hPopup = handles.popupExptIndex;
[~,~,pInd] = getSelectedIndices(handles);

% re-enables the save menu item
if pInd == 3
    % case is the multi-experiment type has been selected
    setObjEnable(hPopup,'off')   
    set(hPopup,'Value',1,'String',{'Multi-Experiment Calculations'})
    
    % updates the experimental information
    setExptInfo(handles,[]);    
else
    % retrieves the lists colour strings
    sName = getappdata(hFig,'sName');
    sName = cellfun(@(x)(simpFileName(x,18)),sName,'un',0);
    sName = getListColourStrings(handles,sName,'Expt');         
    
    % determines if the solution file is for a multi-expt solution file
    if length(snTot) > 1
        % sets the table strings and makes the popup menu active
        set(setObjEnable(hPopup,'on'),'string',sName)
    else
        % sets the table strings but makes the popup menu inactive
        set(setObjEnable(hPopup,'inactive'),'string',sName,'value',1)
    end
    
    % updates the experimental information
    setExptInfo(handles,snTot);
end
    
% --- sets the experiment information
function setExptInfo(handles,snTot)

% retrieves the currently selected indices and plot types
hFig = handles.figFlyAnalysis;
setPanelProps(handles.panelExptInfo,~isempty(snTot))

% if multi-expt analysis is being performed, then reset the config string
if isempty(snTot)
    set(handles.textSetupConfig,'String','N/A');
    return
end

% enables the experiment information panel
if nargin == 1; snTot = getappdata(hFig,'snTot'); end

% sets the fly/sub-region count
[eInd,~,~] = getSelectedIndices(handles);
iMov = snTot(eInd).iMov;

% sets up the setup configuration string
if iMov.is2D
    % sets the full string
    configStr = sprintf('%i x %i Grid Assay',...
                        size(iMov.flyok,1),iMov.nCol);
else
    % sets the experiment string
    configStr = sprintf('%i x %i Assay (Max Count = %i)',...
            iMov.pInfo.nRow,iMov.pInfo.nCol,iMov.pInfo.nFlyMx);
end

% sets the setup configuration string
set(handles.textSetupConfig,'String',configStr);

% --- sets the plot function information/functions
function setPlotInfo(handles,snTot)

% enables the plot function panel
setPanelProps(handles.panelPlotFunc,'on')
setPanelProps(handles.panelFuncDesc,'on')

% sets the listbox strings
lName = {'Experiment Analysis (Individual)',...
         'Experiment Analysis (Population)'};
if length(snTot) > 1    
    lName = [lName,{'Multi-Experiment Analysis'}];         
end

% sets the popup strings to the highest level solution data type (either
% the multi-combined or single combined solution files)
setappdata(handles.figFlyAnalysis,'pIndex',length(lName))
set(handles.popupPlotType,'string',lName,'value',length(lName))
set(handles.textFuncDesc,'string','','visible','on')
set(handles.textFuncDescBack,'visible','on','backgroundcolor','k')

% --- scans the plotting function directory for valid functions and places
function scanPlotFuncDir(handles)

% scans the plotting function directory for any functions
iProg = getappdata(handles.figFlyAnalysis,'iProg');
dDir = iProg.DirFunc;

% initialises the struct for the plotting function data types
a = struct('fcn',[],'Name',[],'fType',[],'fDesc',[],'rI',[]);
pDataT = struct('Indiv',[],'Pop',[],'Multi',[]);

% retrieves the partial/full file names
if isdeployed
    % loads the analysis function data file
    pData = load('AnalysisFunc.mat');
    
    % sets the partial/full file names
    [fDir,fName,eStr] = deal(pData.fDir,pData.fName,[]);
        
    % determines if this is the computer the executable was created on 
    [~, hName] = system('hostname');
    if strcmp(hName,pData.hName)
        % if so, set the analysis files relative to the current computer
        fFile = cellfun(@(x,y)(fullfile(x,y)),fDir,fName,'un',0);
    else
        % otherwise, set the file names relative to the analysis file
        % directory on the new computer
        fFile = cellfun(@(x)(fullfile(dDir,x)),fName,'un',0);
    end

    % determines if any of the files are missing from where they should be
    ii = cellfun(@(x)(exist(x,'file')),fFile) > 0;
    if any(~ii)
        % if there are missing files, then 
        eStr = sprintf(['The following files appear to be missing from ',...
                        'the analysis function path:\n\n']);
        jj = find(~ii);
        for i = reshape(jj,1,length(jj))
            eStr = sprintf('%s => %s\n',eStr,fName{i}); 
        end
    end        
        
    % for the files that are remaining, determine the difference in the 
    % file sizes from their original 
    fData = cell2mat(cellfun(@(x)(dir(x)),fFile(ii),'un',0));
    jj = ii(find((field2cell(fData,'bytes',1) - pData.fSize(ii)) > 0)');
    if ~isempty(jj)
        % if there is a change, then flag that the executable may need 
        % to be updated to include these changes
        if ~isempty(eStr); eStr = sprintf('%s\n',eStr); end
        eStr = sprintf(['%sThe following files in the default analysis file ',...
                        'directory are not up to date:\n\n'],eStr);

        kk = find(jj);
        for i = reshape(kk,1,length(kk)) 
            eStr = sprintf('%s => %s\n',eStr,fName{i}); 
        end  
    end
else
    % sets the partial/full file names
    fName = field2cell(dir(fullfile(dDir,'*.m')),'name');
    fFile = cellfun(@(x)(fullfile(dDir,x)),fName,'un',0);
end

% determines all the valid m-files in the plotting function directory 
for i = 1:length(fName)
    % retrieves the function file name
    fcnName = getFileName(fName{i});    
    try
        % attempts to run the function and set the function handle to the
        % corresponding function type
        a.fcn = eval(sprintf('@%s',fcnName));
        pDataNw = feval(a.fcn);
        [a.Name,a.fType] = deal(pDataNw.Name,pDataNw.fType);
        a.fDesc = getFuncCommentStr(fFile{i});
        
        % adds the requirement information field (if it exists)
        if isfield(pDataNw,'rI'); a.rI = pDataNw.rI; end
        
        % sets the field type strings
        tStr = pDataNw.Type; 
        if ~iscell(tStr); tStr = {tStr}; end
        
        % sets the new type field string
        for j = 1:length(tStr)
            typeStr = sprintf('pDataT.%s',tStr{j});
            if isempty(eval(typeStr))
                % if the field is empty, then initialise with the struct
                eval(sprintf('%s = a;',typeStr))
            else
                % otherwise, append to the end of the sub-struct
                eval(sprintf('%s(end+1) = a;',typeStr))
            end
        end
    end
end

% resorts the function names by type
fNames = fieldnames(pDataT);
for i = 1:length(fNames)
    A = eval(sprintf('pDataT.%s',fNames{i}));    
    [~,ii] = sortrows(setFuncTypeList(A));
    pDataT = setStructField(pDataT,fNames{i},A(ii));
end

% updates the plotting function 
setappdata(handles.figFlyAnalysis,'pDataT',pDataT)

% --- re-initialises the plotting values struct
function pData = resetPlotDataStructs(handles,varargin)

% retrieves the solution struct and solution directory/file names
pDataT = getappdata(handles.figFlyAnalysis,'pDataT');
snTot = getappdata(handles.figFlyAnalysis,'snTot');

% retrieves the function field names
[fName,nSoln] = deal(fieldnames(pDataT),length(snTot));
fName = fName(1:(end-(nSoln==1)));

% resets the plot data structs for each of the function type. created is an
% arry with each row corresponding to an analysis function and the columns
% to each of the solution files
pData = cell(length(fName),1);
for i = 1:length(fName)
    % sets the array size (depending on the plotting type)
    if strcmp(fName{i},'Multi')
        N = 1;
    else
        N = nSoln;
    end    
    
    % retrieves the sub-struct and allocates memory for the data struct
    p = eval(sprintf('pDataT.%s;',fName{i}));
    pData{i} = cell(length(p),N);
    
    % sets the parameter data structs for all the function handles
    for j = 1:length(p)
        for k = 1:N
            if nargin == 2
                if strcmp(fName{i},'Multi')
                    pData{i}{j,k} = feval(p(j).fcn,snTot);
                else
                    pData{i}{j,k} = ...
                            feval(p(j).fcn,reduceSolnAppPara(snTot(k)));
                end
                
                pData{i}{j,k}.fDesc = p(j).fDesc;
            end
        end
    end    
end

% --- resets the plotting data structs
function pDataNw = resetPlottingData(handles,varargin)

% resets the legend strings
[eInd,fInd,pInd] = getSelectedIndices(handles);
if ~any([eInd,fInd,pInd] == 0)   
    % retrieves the relevant data/parameter structs
    snTot = getappdata(handles.figFlyAnalysis,'snTot');
    pDataT = getappdata(handles.figFlyAnalysis,'pDataT');   
    pData = getappdata(handles.figFlyAnalysis,'pData');   
    fName = fieldnames(pDataT);
    
    % reduces the solution struct (if not analysing multi-experiment)
    if pInd == 3
        snTotL = snTot;
    else
        snTotL = reduceSolnAppPara(snTot(eInd));
    end
    
    % reinitialises the parameter struct
    p = getStructField(pDataT,fName{pInd});
    A = feval(p(fInd).fcn,snTotL);
    if nargin == 2
        pDataNw = varargin{1};
        pDataNw.pF = A.pF;
    else        
        pDataNw = A;    
    end
        
    % resets the data struct
    pDataNw.fDesc = p(fInd).fDesc;
    pData{pInd}{fInd,eInd} = pDataNw;            
    setappdata(handles.figFlyAnalysis,'pData',pData);            
            
    % resets the output array into the main GUI
    plotD = getappdata(handles.figFlyAnalysis,'plotD');    
    plotD{pInd}{fInd,eInd} = [];                
    setappdata(handles.figFlyAnalysis,'plotD',plotD);            
end 

% --- updates the list string, specified by type
function updateListColourStrings(handles,type)
 
% global variables
global isUpdating

% sets the list object to read (based on the type flag)
switch type
    case 'func' 
        % case is for the analysis function list
        
        % field initialisation
        hFig = handles.figFlyAnalysis;
        hTreeF = getappdata(hFig,'hTreeF');
        hNodeS = hTreeF.getSelectedNodes;
        
        % if no nodes are selected, then exit the function
        if isempty(hNodeS); return; end
        
        % resets the node name
        nodeStr = hNodeS(1).getName;
        nodeStrNw = setHTMLColourString('r',nodeStr,1);
        hNodeS(1).setName(nodeStrNw);
        
        % updates the experiment name
        isUpdating = true;
        hTreeF.repaint()
        pause(0.05);
        isUpdating = false;
        
        
    case 'expt' 
        % case is for the experiment selection list                
        
        % object handle retrieval
        hObj = handles.popupExptIndex;

        % updates the list string
        StrOld = get(hObj,'string');
        Str = cellfun(@(x)(retHTMLColouredStrings(x)),StrOld,'un',0);
        set(hObj,'string',getListColourStrings(handles,Str,type))        
end
    
% --- converts the list strings, lStr, to coloured strings depending on A) 
%     whether data has been calculated for the function/experiment, and B) 
%     whether the list is for the type 'expt' (experiment popup) or 'func'
%     (the analysis function listbox)
function lStrCol = getListColourStrings(handles,lStr,type)

% retrieves the plot data and the selected experiment/plot type indices
plotD = getappdata(handles.figFlyAnalysis,'plotD');        

% determines which of the 
[eInd,~,pInd] = getSelectedIndices(handles);
switch lower(type)
    case ('expt') % case is the experiment selection
        ii = any(~cellfun(@isempty,plotD{pInd}),1);
        lCol = repmat({'k'},length(ii),1); lCol(ii) = {'r'};        
    case ('func') % case is the analysis function listbox
        % retrieves the data structs
        snTot = getappdata(handles.figFlyAnalysis,'snTot');        
        pData = getappdata(handles.figFlyAnalysis,'pData');        
        
        % determines the feasible experiments in the function list
        fType = setFuncTypeList(cell2mat(pData{pInd}(:,1)));
%         fType = cell2mat(field2cell(cell2mat(pData{pInd}(:,1)),'fType'));
        isFeas = detExptType(snTot,fType);
        
        % determines which of the functions has values calculated and which
        % of the lines are non-header lines
        kk = ~cellfun(@isempty,plotD{pInd}(:,eInd));
        jj = cellfun(@(x)(~strcmp(x(1),' ')),lStr); 
        
        % sets the index array of the functions that have calculated values
        jj2 = ~jj; jj = find(jj);
        ii = false(length(lStr),1); ii(jj(kk)) = true;
        
        % sets the final string colours
        lCol = repmat({'k'},length(ii),1); 
        [lCol(ii),lCol(jj2)] = deal({'r'},{'kb'});
        lCol(jj(~isFeas)) = {'gr'};
end

% sets the valid colour strings to read and sets the coloured strings
lStrCol = setHTMLColourString(lCol,lStr);

% --- updates the object property enabled states 
function setObjProps(handles,state,varargin)

% enables the listboxes/popup menus
setObjEnable(handles.popupPlotType,state); 

% checking against the plot type
if nargin == 2
    if strcmp(state,'on')
        % if plot type is 
        [~,~,pInd] = getSelectedIndices(handles);    
        if pInd ~= 3       
            setObjEnable(handles.popupExptIndex,'on'); 
        end
    else
        setObjEnable(handles.popupExptIndex,state); 
    end
end

% --- retrieves the solution file tooltip strings 
function sNameTT = getToolTipStrings(handles,ind)

% retrieves the full solution file name strings
a = getappdata(handles.figFlyAnalysis,'sNameFull');
if nargin == 1; ind = 1:length(a); end

% sets the solution file tool-tip strings
sNameTT = a{ind(1)};
for i = 2:length(ind)
    sNameTT = sprintf('%s\n%s',sNameTT,a{ind(i)});
end

% --- temporary storage, reloading or removing of the solution data
function tempSolnDataIO(handles,Type)

% loads the data structs from the GUI
hFig = handles.figFlyAnalysis;
iData = getappdata(hFig,'iData');
tFile = fullfile(iData.ProgDef.OutData,'TempSolnData.mat');

% performs the solution file 
switch Type
    case ('store') % case is storing the data
        % retrieves the solution data
        sInfo = getappdata(hFig,'sInfo');
        snTot = getappdata(hFig,'snTot');
        
        % if the solution data exists, then reset
        if ~isempty(sInfo)
            % creates a loadbar figure
            h = ProgressLoadbar('Saving Temporary Solution File...');
            
            % saves the sub-region and solution file data struct to file
            save(tFile,'sInfo','snTot');
            
            % closes the loadbar
            try; delete(h); end
        end
        
    case ('reload') % case is reloading the data
        if exist(tFile,'file')
            % creates a loadbar figure
            h = ProgressLoadbar('Loading Temporary Solution File...');
            
            % loads & deletes the temporary solution file
            a = load(tFile);
            delete(tFile);
            
            % closes the loadbar
            try delete(h); end            
            
            % removes the sub-region and solution file data struct
            setappdata(hFig,'sInfo',a.sInfo);
            setappdata(hFig,'snTot',a.snTot);
        end
                
    case ('remove') % case is removing the data        
        if exist(tFile,'file')
            % deletes the temporary solution file (if it exists)
            delete(tFile)
        end
end

% --- initialises the sub-region data struct
function sPara = initSubRegionStruct()

% intialises the sub-region data-struct
sPara = struct('pos',[0 0 1 1],'nRow',1,'nCol',1,...
               'pData',[],'plotD',[],'ind',[]);

% memory allocation
sPara.ind = NaN(1,3);
[sPara.pData,sPara.plotD] = deal(cell(1));

% --- initialises the graph format struct ------------------------------- %
function fmtStr = initFormatStruct(iData,tStr,xStr,yStr,x,y,fID)

% default font sizes
if ismac
    [titleSize,labelSize,axisSize] = deal(40,32,22);
else
    [titleSize,labelSize,axisSize] = deal(34,28,20);
end

% sets up the sub-structs and the main format struct
a = struct('Str',tStr,'fSize',titleSize,'isBold',true);
b = struct('xStr',xStr,'yStr',yStr,'fSize',labelSize,'isBold',true);
c = struct('fSize',axisSize,'isBold',true);
d = struct('x',x,'y',y,'xSm',[],'ySm',[],'yLim',[],'xLim',[]);
fmtStr = struct('Title',a,'Label',b,'Axis',c,'Plt',d,'fID',fID);

% sets up the smoothing filter vectors
xi = 1:length(x);
fmtStr.Plt.xSm = smooth(xi,fmtStr.Plt.x,iData.sSpan,'sgolay');
fmtStr.Plt.ySm = smooth(xi,fmtStr.Plt.y,iData.sSpan,'sgolay'); 

% --- retrieves the currently selected analysis scope flag
function fScope = getAnalysisScopeFlag(hFig)

% initialisations
fScope0 = {'I','S','M'};
[~,~,pInd] = getSelectedIndices(guidata(hFig));

% returns the final string
fScope = fScope0{pInd};

% --- function for the after running the solution file loading gui
function postSolnLoadFunc(hFig,sInfoNw)

% retrieves the gui object handle
handles = guidata(hFig);

% performs the actions based on the user input
if ~exist('sInfoNw','var')      
    % if the user cancelled or there was no change, then exit the function
    tempSolnDataIO(handles,'reload')
    
    % if the parameter gui is present, then make it visible   
    hPara = findall(0,'tag','figAnalysisPara');
    if ~isempty(hPara)
        setObjVisibility(hPara,1);
    end
    
    % closes the loadbar
    try; close(h); end
    
    % makes the gui visible again and exits the function
    setObjVisibility(hFig,'on');
    return
    
elseif isempty(sInfoNw)    
    % if all data was cleared, then reset the gui
    menuClearData_Callback(handles.menuClearData, [], handles)
    
    % makes the gui visible again
    tempSolnDataIO(handles,'remove')
    setObjVisibility(hFig,'on');        
    return
end

% creates a loadbar
h = ProgressLoadbar('Updating Analysis Information...');

% separates the solution file information from the loaded data
[~,sInfoNw] = separateInfoDataStruct(hFig,sInfoNw);

% makes the gui visible again
tempSolnDataIO(handles,'remove')

% sets the experiment name strings
sName = cellfun(@(x)(x.expFile),sInfoNw,'un',0);
sNameFull = cellfun(@(x)(x.sFile),sInfoNw,'un',0);
setappdata(hFig,'sName',sName)
setappdata(hFig,'sNameFull',sNameFull)
setappdata(hFig,'LoadSuccess',true);

% retrieves the stored data
pDataT = getappdata(hFig,'pDataT');
snTot = num2cell(getappdata(hFig,'snTot'));
   
% creates the function filter
fObj = FuncFilterTree(hFig,snTot,pDataT);
set(fObj,'treeUpdateExtn',@updateFuncFilter);
setappdata(hFig,'fObj',fObj);

% sets up the loaded information and resets the gui objects
setSolnInfo(handles)
resetGUIObjects(guidata(hFig))

% sets the save stimuli data enabled properties
hasStim = any(cellfun(@(x)(~isempty(x.stimP)),snTot));
setObjEnable(handles.menuSaveStim,hasStim)

% makes the main gui visible again
setObjVisibility(hFig,'on');

% attempts to close the loadbar
try; close(h); end

% --- function filter class update callback
function updateFuncFilter()

% retrieves the function filter class object
hFig = findall(0,'tag','figFlyAnalysis');
hPopup = findall(0,'tag','popupPlotType');
fObj = getappdata(hFig,'fObj');

% resets the experiment compatibility flags
fScope = getAnalysisScopeFlag(hFig);
fObj.detExptCompatibility(fScope);

% resets the function list
popupPlotType_Callback(hPopup, '1', guidata(hFig))

% --- resets the plot panel coordinate vectors
function resetPlotPanelCoords(handles)

% global variables
global axPosX axPosY

% calculates the global coordinates
pPos = getObjGlobalCoord(handles.panelPlot);
[axPosX,axPosY] = deal(pPos(1)+[0,pPos(3)],pPos(2)+[0,pPos(4)]);
