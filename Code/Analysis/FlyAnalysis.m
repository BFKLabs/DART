function varargout = FlyAnalysis(varargin)
% Last Modified by GUIDE v2.5 24-Mar-2021 21:10:08

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
function FlyAnalysis_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global mainProgDir isDocked initDock regSz updateFlag canSelect
[isDocked,initDock,canSelect] = deal(true);
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
switch (length(varargin))   
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
    
% initialises the structs
setappdata(hObject,'hDART',hDART)
setappdata(hObject,'hPara',[])
setappdata(hObject,'hUndock',[])
setappdata(hObject,'sInd',1)
setappdata(hObject,'iData',iData)
setappdata(hObject,'gPara',gPara)
setappdata(hObject,'iProg',iData.ProgDef)

% sets all the functions
setappdata(hObject,'plotMetricGraph',@plotMetricGraph);
setappdata(hObject,'initAxesObject',@initAxesObject)
setappdata(hObject,'clearAxesObject',@clearAxesObject)
setappdata(hObject,'popupSubInd',@popupSubInd_Callback);
setappdata(hObject,'axisClickCallback',@axisClickCallback);

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
function varargout = FlyAnalysis_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% ------------------------------- %
% --- DATA FILE OPENING ITEMS --- %
% ------------------------------- %

% -------------------------------------------------------------------------
function menuOpenIndiv_Callback(hObject, eventdata, handles)

% global variables
global hh
hh = [];

% loads the data structs from the GUI
iData = getappdata(handles.figFlyAnalysis,'iData');
dDir = iData.ProgDef.DirSoln; n = length(dDir);

% prompts the user for the solution file directory
[fName,fDir,fIndex] = uigetfile({'*.soln','Solution Files (*.soln)'},...
                        'Select The Video Solution Files',dDir,...
                        'MultiSelect','on');
if fIndex == 0
    % if the user cancelled, then exit
    return
else
    % ensures the filenames are in a cell array
    if ~iscell(fName); fName = {fName}; end
    
    % determines the file indices
    indFile = cellfun(@(x)(str2double(x(end-7:end-4))),fName);
    if ~all(diff(indFile) == 1)
        eStr = 'Error! Selected files are not all contiguous.';
        waitfor(errordlg(eStr,'Video Solution File Error','modal'))
        return
        
    else
        % loads the summary file
        A = importdata(fullfile(fDir,fName{1}),'-mat');
        smFile = getSummaryFilePath(A.fData);
        if ~exist(smFile,'file')
            % attempts to get the summary file from the soln directory
            smFile = getSummaryFilePath(struct('dir',fDir));
            if ~exist(smFile,'file')
                % if the summary file doesn't exist, then exit
                eStr = ['Error! Associated video solution ',...
                        'summary file is missing.'];
                waitfor(errordlg(eStr,'Missing Summary File','modal'))
                return
            end
        end
            
        % converts any character arrays to cell arrays        
        if ~iscell(fName)
            fName = {fName};
        end        
    end  
end

% if the user cancelled, then exit the function
tempSolnDataIO(handles,'store') 

% sets the files and combines the solution files
sName = cellfun(@(x)(fullfile(fDir,x)),fName,'un',0);
[snTot,iMov] = combineSolnFiles(sName);
if isempty(snTot)
    % if the user cancelled, then exit the function
    tempSolnDataIO(handles,'reload') 
    return
    
else
    % deletes the temporary solution data
    tempSolnDataIO(handles,'remove')     
    
    % initialises the apparatus parameter struct
    snTot.appPara = initAppStruct(snTot,iMov);
    sName = getFinalDirString(fDir);
    if (~iscell(sName)); sName = {sName}; end
    
    % sets the solution file struct into the GUI
    snTot = reduceCombSolnFiles(snTot);
    setappdata(handles.figFlyAnalysis,'snTot',snTot)
    setappdata(handles.figFlyAnalysis,'sName',sName)
end

% removes the default directory component from the solution file path
A = strfind(fDir,dDir);
if ~isempty(A)
    fDir = ['~',fDir((A+n):end)];
end

% sets the data fields
setappdata(handles.figFlyAnalysis,'sNameFull',{fDir})
setSolnInfo(handles,'Experiment')
resetGUIObjects(handles,snTot)
       
% -------------------------------------------------------------------------
function menuOpenSingle_Callback(hObject, eventdata, handles)

% loads the data structs from the GUI
iData = getappdata(handles.figFlyAnalysis,'iData');
[dDir,TempDir] = deal(iData.ProgDef.DirComb,iData.ProgDef.TempFile);
n = length(dDir);

% prompts the user for the solution file directory
fModeStr = {'*.ssol;','Single Experimental Solution Files (*.ssol)'};
[fName,fDir,fIndex] = uigetfile(fModeStr,...
                        'Select Experimental Solution Files',dDir,...
                        'MultiSelect','on');
if fIndex == 0
    % if the user cancelled, then exit
    return
else
    % saves a copy of the currently loaded solution file data
    tempSolnDataIO(handles,'store')
    
    % sets the solution file name
    if iscell(fName)
        % loads the combined solution file
        sNameF = cellfun(@(x)(fullfile(fDir,x)),fName,'un',0);
        [snTot,sName,ok] = loadMultiCombSolnFiles(TempDir,sNameF);
        if ~ok
            % if the user cancelled, then exit the function
            tempSolnDataIO(handles,'reload')
            return
        else
            % sets the solution file names (without extensions)
            fName = [getFinalDirString(fDir),' (Multi)'];
            sNameNw = cellfun(@(x)(getFileName(x)),sName,'un',0);            
                        
            % deletes the temporary solution data
            tempSolnDataIO(handles,'remove')
            
            % updates the solution file names into the Analysis GUI
            setappdata(handles.figFlyAnalysis,'sName',sNameNw)
            setappdata(handles.figFlyAnalysis,'sNameFull',sNameF)
            setappdata(handles.figFlyAnalysis,'fName',fName)                                    
        end
    else
        % otherwise, only one file is to be loaded
        sNameF = fullfile(fDir,fName);
        [snTot,ok] = loadCombSolnFiles(iData.ProgDef.TempFile,sNameF);
        if ~ok
            % if the user cancelled, then exit the function
            tempSolnDataIO(handles,'reload')            
            return
        else
            % deletes the temporary solution data
            tempSolnDataIO(handles,'remove')            
            
            % sets the solution file name (without extensions)
            sNameNw = {[getFileName(sNameF),'.ssol']};
            sNameF = {sNameF};
            setappdata(handles.figFlyAnalysis,'sName',sNameNw)
        end        
    end
end

% resets the solution file names (to remove the default directory)
A = cellfun(@(x)(strfind(x,dDir)),sNameF,'un',0);
for i = 1:length(sNameF)
    if ~isempty(A{i})
        sNameF{i} = ['~',sNameF{i}((A{i}+n):end)];
    end
end

% reduces down the combined experiment solution files
for i = 1:length(snTot)
    snTot(i) = reduceCombSolnFiles(snTot(i));
end

% ensures the solution file names are stored as a cell array
if ~iscell(sNameF); sNameF = {sNameF}; end

% sets the solution file struct into the GUI
setappdata(handles.figFlyAnalysis,'snTot',snTot)    
setappdata(handles.figFlyAnalysis,'sNameFull',sNameF)
setappdata(handles.figFlyAnalysis,'fNameFull',getToolTipStrings(handles))

% sets the data fields
% setSolnInfo(handles,sType)
resetGUIObjects(handles,snTot)

% -------------------------------------------------------------------------
function menuOpenMulti_Callback(hObject, eventdata, handles)

% loads the data structs from the GUI
iData = getappdata(handles.figFlyAnalysis,'iData');
dDir = iData.ProgDef.DirComb; n = length(dDir);

% prompts the user for the solution file directory
fMode = {'*.msol;','Multi-Experimental Solution File (*.msol)'};
[fName,fDir,fIndex] = uigetfile(fMode,'Set The Multi-Solution File',dDir);
if fIndex == 0
    % if the user cancelled, then exit
    return
else
    % sets the solution file name
    mName = fullfile(fDir,fName);    
end

% saves a copy of the currently loaded solution file data
tempSolnDataIO(handles,'store')

% loads the combined solution file
[snTot,sName,ok] = loadMultiCombSolnFiles(iData.ProgDef.TempFile,mName);
if ~ok
    % if the user cancelled, then exit the function
    tempSolnDataIO(handles,'reload') 
    return
else
    % sets the solution file names (without extensions)
    sNameNw = cellfun(@(x)(getFileName(x)),sName,'un',0);
    
    % deletes the temporary solution data
    tempSolnDataIO(handles,'remove')      
    
    % sets the solution file struct into the GUI
    setappdata(handles.figFlyAnalysis,'snTot',snTot)    
    setappdata(handles.figFlyAnalysis,'sName',sNameNw)    
    setappdata(handles.figFlyAnalysis,'sNameFull',sName)    
    setappdata(handles.figFlyAnalysis,'fName',fName)   
    
    % removes the default directory component from the solution file path
    A = strfind(fDir,dDir);
    if ~isempty(A)
        mName = ['~',mName((A+n):end)];
    end
    setappdata(handles.figFlyAnalysis,'fNameFull',mName)    
end        
   
% sets the data fields
setSolnInfo(handles,'Multiple',fName)
resetGUIObjects(handles)

% -------------------------------------------------------------------------
function menuOpenSubConfig_Callback(hObject, eventdata, handles)

% loads the data structs from the GUI
iData = getappdata(handles.figFlyAnalysis,'iData');
fcnAxC = getappdata(handles.figFlyAnalysis,'axisClickCallback');
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
    setObjVisibility(handles.figFlyAnalysis,'off'); 
    pause(0.05);
    
    % opens the file and retrieves the subplot parameter data struct
    A = load(fullfile(fDir,fName),'-mat');
    setappdata(handles.figFlyAnalysis,'sPara',A.sPara)
    
    % removes any existing panels/plots
    hPanel = findall(handles.panelPlot,'tag','subPanel');
    if ~isempty(hPanel); delete(hPanel); end    
    
    % deletes/clears the analysis parameter GUI
    hPara = getappdata(handles.figFlyAnalysis,'hPara');
    if ~isempty(hPara); delete(hPara); end
    setappdata(handles.figFlyAnalysis,'hPara',[]);
    
    % updates the popup subindex list
    nReg = size(A.sPara.pos,1);
    lStr = cellfun(@num2str,num2cell(1:nReg)','un',0);  
    set(handles.popupSubInd,'visible','on','string',lStr,'value',1); 
    setObjVisibility(handles.textSubInd,'on')
    
    % creates the new subplot panels    
    setupSubplotPanels(handles.panelPlot,A.sPara,fcnAxC)      
    
    % updates the panel selection    
    setappdata(handles.figFlyAnalysis,'sInd',1)
    popupSubInd_Callback(handles.popupSubInd,[],handles)
    
    % makes the figure visible again
    setObjEnable(handles.menuSaveSubConfig,'on')
    setObjVisibility(handles.figFlyAnalysis,'on');     
end

% -------------------------------------------------------------------------
function menuOpenTempData_Callback(hObject, eventdata, handles)

% loads the data structs from the GUI
iData = getappdata(handles.figFlyAnalysis,'iData');
dDir = iData.ProgDef.TempData;

% prompts the user if they wish to continue. if not, then exit
qStr = {['This action will clear any currently calculated data and ',...
         'can''t be undone.'];'';'Are you sure you wish to continue?'};
uChoice = questdlg(qStr,'Continue Temporary Data Load?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes'); return; end

% prompts the user for the solution file directory
fMode = {'*.tdat;','Temporary Data File (*.tdat)'},;
[tName,tDir,fIndex] = uigetfile(fMode,'Temporary Data File File',dDir);
if (fIndex == 0)
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
fName0 = getFinalDirString(getappdata(handles.figFlyAnalysis,'fNameFull'));
sName0 = getappdata(handles.figFlyAnalysis,'sName');

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
pData = getappdata(handles.figFlyAnalysis,'pData');
plotD = getappdata(handles.figFlyAnalysis,'plotD');
for i = 1:length(pData) 
    if (~isempty(pData{i}) && ~isempty(A.pData{i}))        
        % retrieves the function names for the current function type
        funcT = field2cell(cell2mat(A.pData{i}(:,1)),'Func');
        
        % loops through all of the functions in the currently loaded set
        % determining the matches with the loaded data
        for j = 1:size(pData{i},1)            
            % determines if there is a match between data structs
            ii = strcmp(pData{i}{j,1}.Func,funcT);
            if (any(ii))
                % if so, then update the function/plotting data structs
                pData{i}(j,:) = A.pData{i}(ii,:);
                plotD{i}(j,:) = A.plotD{i}(ii,:);
            end
        end
    end
end

% resets the fields with the loaded data
setappdata(handles.figFlyAnalysis,'sName',A.sData.sName)
setappdata(handles.figFlyAnalysis,'fName',A.sData.fName)
setappdata(handles.figFlyAnalysis,'gPara',A.gPara)
setappdata(handles.figFlyAnalysis,'sPara',A.sPara)
setappdata(handles.figFlyAnalysis,'plotD',plotD)
setappdata(handles.figFlyAnalysis,'pData',pData)

% sets the menu item enabled properties
setObjEnable(handles.menuSaveTempData,'on')

% resets the selecting indices
[eInd,fInd,pInd] = getSelectedIndices(handles);
if fInd > 0
    hPara = getappdata(handles.figFlyAnalysis,'hPara');
    setappdata(hPara,'pData',pData{pInd}{fInd,eInd}) 
end

% updates the figure with the new data
% setappdata(handles.figFlyAnalysis,'eIndex',-1);
popupExptIndex_Callback(handles.popupExptIndex, '1', handles)

% ------------------------------ %
% --- DATA FILE OUTPUT ITEMS --- %
% ------------------------------ %
                    
% -------------------------------------------------------------------------
function menuSaveData_Callback(hObject, eventdata, handles)

% deletes the data output figure (if it is open)
hOut = findall(0,'tag','figDataOutput');
if (~isempty(hOut)); delete(hOut); pause(0.05); end

% runs the output data sub-GUI
DataOutput(handles.figFlyAnalysis)

% -------------------------------------------------------------------------
function menuSaveStim_Callback(hObject, eventdata, handles)

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
function menuSaveSubConfig_Callback(hObject, eventdata, handles)

% loads the data structs from the GUI
sPara = getappdata(handles.figFlyAnalysis,'sPara');
iData = getappdata(handles.figFlyAnalysis,'iData');
dDir = iData.ProgDef.OutFig; 

% prompts the user for the solution file directory
tStr = 'Set The Subplot Configuration Output File';
fMode = {'*.spp','Subplot Configuration File (*.spp)'};
[fName,fDir,fIndex] = uiputfile(fMode,tStr,dDir);
if (fIndex == 0)
    % if the user cancelled, then exit
    return
else
    % clears the fields
    [sPara.pData(:),sPara.plotD(:),sPara.ind(:)] = deal({[]},{[]},NaN);
    
    % outputs the subplot data struct to file
    save(fullfile(fDir,fName),'sPara');
end
    
% -------------------------------------------------------------------------
function menuSaveTempData_Callback(hObject, eventdata, handles)

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
function menuProgPara_Callback(hObject, eventdata, handles)

% runs the program default GUI
hFig = handles.figFlyAnalysis;
iData = getappdata(hFig,'iData');
[iData.ProgDef,isSave] = ProgParaAnalysis(hFig,iData.ProgDef);

% updates the data struct if the user specifed changes
if isSave
    setappdata(hFig,'iData',iData);
end

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

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
function menuClearPlot_Callback(hObject, eventdata, handles)

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
listPlotFunc_Callback(handles.listPlotFunc, '0', handles)

% deletes the parameter GUI
hPara = getappdata(handles.figFlyAnalysis,'hPara');
if (~isempty(hPara))
    setappdata(hPara,'pData',pData)
    resetRecalcObjProps(handles,'Yes')    
end

% -------------------------------------------------------------------------
function menuResetData_Callback(hObject, eventdata, handles)

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
    set(handles.popupSubInd,'value',1)
    popupSubInd_Callback(handles.popupSubInd, '1', handles)
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
listPlotFunc_Callback(handles.listPlotFunc, '1', handles)

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
        setappdata(hPara,'pData',pData{pInd}{fInd,eInd})    
    else
        resetRecalcObjProps(handles,'No')
    end
end

% -------------------------------------------------------------------------
function menuUndock_Callback(hObject, eventdata, handles)

% runs the plotting GUI
UndockPlot(handles)

% -------------------------------------------------------------------------
function menuSplitPlot_Callback(hObject, eventdata, handles)

% runs the axis splitting GUI
SplitAxisRegions(handles)

% ----------------------------------- %
% --- GLOBAL PARAMETERS MENU ITEM --- %
% ----------------------------------- %

% -------------------------------------------------------------------------
function menuGlobalParameters_Callback(hObject, eventdata, handles)

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
function menuResetPara_Callback(hObject, eventdata, handles)

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
% --- TOOLBAR ITEM FUNCTIONS --- %
% ------------------------------ %

% --------------------------------------------------------------------
function menuZoom_ClickedCallback(hObject, eventdata, handles)

% toggles the zoom based on the button state
if strcmp(get(hObject,'state'),'on')
    zoom on
else
    zoom off
end

% --------------------------------------------------------------------
function menuDataCursor_ClickedCallback(hObject, eventdata, handles)

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
function figFlyAnalysis_ResizeFcn(hObject, eventdata, handles)

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
            pDataNw = getappdata(hPara,'pData');
            plotDNw = plotD{pInd}{fInd,eInd};
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
        if isHG1
            hGG = findall(get(hPanelP,'parent'),'type','hggroup');    
        else
            hGG = findall(get(hPanelP,'parent'),'type','annotation');    
        end        
        
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

% --- callback function when a sub-plot axes is clicked
function axisClickCallback(hObject, eventdata)

% global variable
global canSelect

% if can't select, then exit the function
if ~canSelect; return; end

% retrieves the GUI object handles
handles = guidata(hObject);

% determines the object being selected
if strcmp(get(hObject,'type'),'axes')
    % case selecting an axes object
    iSel = get(get(hObject,'Parent'),'UserData');
else
    % case selecting a panel object
    iSel = get(hObject,'UserData');
end

% updates the popup sub index 
set(handles.popupSubInd,'value',iSel)
popupSubInd_Callback(handles.popupSubInd, [], handles)

% ---------------------------------------- %
% --- EXPERIMENT INFORMATION FUNCTIONS --- %
% ---------------------------------------- %

% --- Executes on selection change in popupSubInd.
function popupSubInd_Callback(hObject, eventdata, handles)

% retrieves the sub-region data struct
hPara = getappdata(handles.figFlyAnalysis,'hPara');
sPara = getappdata(handles.figFlyAnalysis,'sPara');
pData = getappdata(handles.figFlyAnalysis,'pData');
sInd0 = getappdata(handles.figFlyAnalysis,'sInd');

% retrieves the selected index
[lStr,iStr] = deal(get(hObject,'string'),get(hObject,'value'));
sInd = str2double(lStr{iStr});
setappdata(handles.figFlyAnalysis,'sInd',sInd)

% resets the highlight panel colours
hPanel = findall(handles.panelPlot,'tag','subPanel');
set(hPanel,'HighLightColor','w');
set(findobj(hPanel,'tag','subPanel','UserData',sInd),'HighlightColor','r');

% determines if there are any valid indices selected
[eInd,fInd,pInd] = getSelectedIndices(handles);
if ~isempty(hPara) && ~isa(eventdata,'char')  
    if all([eInd,fInd,pInd] > 0)
        % if so, then update the plotting data struct
        sPara.pData{sInd0} = getappdata(hPara,'pData');
        setappdata(handles.figFlyAnalysis,'sPara',sPara);

        % updates the plot data struct
        pData{pInd}{fInd,eInd} = getappdata(hPara,'pData');
        setappdata(handles.figFlyAnalysis,'pData',pData);
    end        
end

% determines if the plot data has been set for the current sub-plot
if ~isempty(sPara.pData{sInd}) && ~any(isnan(sPara.ind(sInd,:)))
    % sets the new selected indices
    lStr = get(handles.listPlotFunc,'string');
    fName = sPara.pData{sInd}.Name;
    fIndNw = find(cellfun(@(x)(any(strfind(x,fName))),lStr)); 
    
    % if there is more than one match, then narrow them down    
    if length(fIndNw) > 1       
        % determines the end of the HTML-colour markers
        ii = cellfun(@(x)(strfind(x,'>')),lStr(fIndNw),'un',0);
        ii(cellfun(@isempty,ii)) = {0};

        % determines the exact match
        jj = cellfun(@(x,y)(strcmp(x(y(end)+1:end),fName)),lStr(fIndNw),ii);
        fIndNw = fIndNw(jj);
    end
    
    % if so, then update the popup menu/list value 
    setObjEnable(handles.menuUndock,'on')
    setObjEnable(handles.menuSaveData,'on')
    setObjEnable(handles.buttonUpdateFigure,'on')
    set(handles.popupExptIndex,'value',sPara.ind(sInd,1))
    set(handles.popupPlotType,'value',sPara.ind(sInd,3)) 
    set(handles.listPlotFunc,'value',fIndNw)   
    
    % updates the parameter GUI
    if isempty(hPara)
        hPara = AnalysisPara(handles);
        setappdata(handles.figFlyAnalysis,'hPara',hPara);
    else
        feval(getappdata(hPara,'initAnalysisGUI'),hPara,handles)
    end
else
    % otherwise, remove the plot list
    setObjEnable(handles.menuSaveData,'off')
    set(handles.listPlotFunc,'value',1)  
    setObjVisibility(hPara,'off'); 
    
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

% --- Executes on selection change in popupExptIndex.
function popupExptIndex_Callback(hObject, eventdata, handles)

% retrieves the solution struct and solution directory/file names
hPara = getappdata(handles.figFlyAnalysis,'hPara');
pData = getappdata(handles.figFlyAnalysis,'pData');
snTot = getappdata(handles.figFlyAnalysis,'snTot');
eIndex = getappdata(handles.figFlyAnalysis,'eIndex');

% check to see if the new experiment 
if (eIndex ~= get(hObject,'value')) || isa(eventdata,'char')
    if ~isempty(hPara)
        % updates the parameter struct in the overall array
        [~,fInd,pInd] = getSelectedIndices(handles);

        % updates the parameter struct
        if fInd > 0
            pDataOld = getappdata(hPara,'pData');
            if pInd == 3
                pData{pInd}{fInd,1} = pDataOld;
            else
                pData{pInd}{fInd,eIndex} = pDataOld;
            end
            setappdata(handles.figFlyAnalysis,'pData',pData);    
        end
    end
    
    % updates the experiment index and experiment information
    setappdata(handles.figFlyAnalysis,'eIndex',get(hObject,'value'));
    setExptInfo(handles,snTot);         
    
    % resets the plotting function listbox
    updateListColourStrings(handles,'func')
    listPlotFunc_Callback(handles.listPlotFunc, '1', handles)          
end   

% --- Executes on button press in toggleExptSel.
function toggleExptSel_Callback(hObject, eventdata, handles)

% global variables
global indExpt0

% parameters
[B0,H0,nMax] = deal(95,20,7);
if ispc; Htxt = 14; else; Htxt = 14; end

% sets the other object properties
lPos = get(handles.listExptSel,'Position');
iData = getappdata(handles.figFlyAnalysis,'iData');
sName = getappdata(handles.figFlyAnalysis,'sName');

% updates the listbox properties based on toggle button value
if get(hObject,'value')
    % resets the list strings and position
    Hnw = Htxt*min(nMax,length(sName));
    Bnw = (B0 + H0) - Hnw;
    indExpt0 = iData.indExpt;
    
    % makes the relevant objects disabled 
    setObjProps(handles,'off',1)
    
    % resets the listbox string and positions
    ind = find(iData.indExpt);
    set(handles.listExptSel,'string',sName,'value',ind(end:-1:1),...
                    'Position',[lPos(1) Bnw lPos(3) Hnw],'enable','on',...
                    'Style','listbox')                             
else        
    % makes the relevant objects enabled again
    setObjProps(handles,'on',1)
    
    % resets the listbox strings and positions
    set(handles.listExptSel,'value',1,'string','Multi Experiment',...
                    'Position',[lPos(1) B0 lPos(3) H0],'enable',...
                    'inactive','Style','popupmenu')     

    % if there is a change, then prompt the user if they want to update the
    % changes. if so, then clear the multi-experiment plot data
    if ~isa(eventdata,'char')
        if any(xor(iData.indExpt,indExpt0))
            % prompts the user if they really want to make the changes
            tStr = 'Reset Experiment List?';
            qStr = 'Are you sure you want to reset the experiment list?';            
            uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
            if strcmp(uChoice,'Yes')
                % resets the plot data struct
                menuResetData_Callback...
                                (handles.menuResetData,'Multi',handles)             
            else
                % resets the experiment indices to the original
                iData.indExpt = indExpt0;
                setappdata(handles.figFlyAnalysis,'iData',iData)                            
            end
        end
    end
end

% --- Executes on selection change in listExptSel.
function listExptSel_Callback(hObject, eventdata, handles)

% determines the listbox indices that were selected
iSel = get(hObject,'Value');
iData = getappdata(handles.figFlyAnalysis,'iData');

% determines if the indices were selected correctly
if isempty(iSel)
    % if no list indices are selected, then output an error
    eStr = 'Error! At least one experiment must be selected.';
    waitfor(errordlg(eStr,'Experiment List Selection Error','modal'))

    % resets the selected listbox indices
    set(hObject,'value',find(iData.indExpt));
else
    % updates the experimental indices
    iData.indExpt(:) = false;
    iData.indExpt(iSel) = true;    
    
    % otherwise update the data struct
    set(handles.textSolnCount,'string',num2str(sum(iData.indExpt)))
    setappdata(handles.figFlyAnalysis,'iData',iData);
    setExptInfo(handles)
end
    
% ---------------------------------------- %
% --- PLOTTING TYPE CALLBACK FUNCTIONS --- %
% ---------------------------------------- %

% --- Executes on selection change in popupPlotType.
function popupPlotType_Callback(hObject, eventdata, handles)

% retrieves the plotting data type struct
pData = getappdata(handles.figFlyAnalysis,'pData');
pDataT = getappdata(handles.figFlyAnalysis,'pDataT');
pIndex = getappdata(handles.figFlyAnalysis,'pIndex');
hPara = getappdata(handles.figFlyAnalysis,'hPara');
snTot = getappdata(handles.figFlyAnalysis,'snTot');
gPara = getappdata(handles.figFlyAnalysis,'gPara');

% other initialisations
eStr = 'on';

% check to see if the new selection is unique
if ~isa(eventdata,'char')
    if pIndex ~= get(hObject,'value')
        if ~isempty(hPara)
            % updates the parameter struct in the overall array
            [eInd,fInd,~] = getSelectedIndices(handles);

            % updates the corresponding parameter struct
            if fInd > 0
                pDataOld = getappdata(hPara,'pData');
                pData{pIndex}{fInd,eInd} = pDataOld;
                setappdata(handles.figFlyAnalysis,'pData',pData);
            end
        end
        
        % if so, updates the plotting function selected index
        setappdata(handles.figFlyAnalysis,'pIndex',get(hObject,'value'));        
    else
        % if the selected value is not unique, then exit the function
        return
    end   
end
   
% retrieves the selected string
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

% check to see if the function stack is empty
if isempty(A)
    % if so, then disable the listbox
    set(handles.listPlotFunc,'string',{' '},'value',1,'enable','inactive');
else
    % sets the new list strings        
    fInd = min(get(handles.listPlotFunc,'value'),length(A)+1);
    lStrNw = getListColourStrings(handles,getFuncListString(A),'Func');     
    set(handles.listPlotFunc,'value',fInd)  
    set(setObjEnable(handles.listPlotFunc,'on'),'string',lStrNw); 
    pause(0.1);        
    
    % sets the function stack into the GUI
    fcnStack = [{' '},field2cell(A,'fcn')];
    setappdata(handles.figFlyAnalysis,'fcnStack',fcnStack);        
end

% resets the experiment list strings
resetExptListStrings(handles)       

% updates the plotting function listbox 
setObjEnable(handles.popupExptIndex,eStr)
listPlotFunc_Callback(handles.listPlotFunc, '1', handles)

% --- Executes on selection change in listPlotFunc.
function listPlotFunc_Callback(hObject, eventdata, handles)

% global variables
global updateFlag
updateFlag = 1;

% retrieves the parameter GUI handles
sInd = getappdata(handles.figFlyAnalysis,'sInd');
sPara = getappdata(handles.figFlyAnalysis,'sPara');
plotD = getappdata(handles.figFlyAnalysis,'plotD');
pData = getappdata(handles.figFlyAnalysis,'pData');

% disables the listboxes
setObjProps(handles,'inactive')
[eInd,fIndNw,pInd,fIndNwT] = getSelectedIndices(handles);
[isShowPara,eStr,nReg] = deal(fIndNw > 0,{'off','on'},size(sPara.pos,1));

% sets the function description
if isempty(fIndNwT)
    % non-function field is not selected
    set(handles.textFuncDesc,'string','');
    if nReg == 1
        setObjEnable(handles.menuUndock,'off')
    end
else
    % sets the required object handles/data structs
    eStrNw = eStr{1+(sign(fIndNwT) > 0)};
    if isempty(pData{pInd}{abs(fIndNwT),eInd}.fDesc)
        % function has no description
        set(handles.textFuncDesc,'enable',eStrNw,...
                    'string','<No Function Description Given>');
    else
        % otherwise, set the function description
        set(handles.textFuncDesc,'enable',eStrNw,...
                    'string',pData{pInd}{abs(fIndNwT),eInd}.fDesc);
    end        
end

% sets the enabled properties of the update figure button (depending on
% whether the user selected a valid list entry)
if isShowPara
    % enables the calculate/plot function button    
    setObjEnable(handles.buttonUpdateFigure,'on')        
    
    % checks to see if the plot index has changed index
    fIndex = getappdata(handles.figFlyAnalysis,'fIndex');
    if (fIndex ~= fIndNw) || (isa(eventdata,'char')) || (nReg > 1)
        % clears the plot axis and resets the data
        if ~isa(eventdata,'char'); eventdata = '0'; end
        clearAxesObject(handles)                       
        
        % creates the new parameter GUI
        hPara = getappdata(handles.figFlyAnalysis,'hPara');
        if isempty(hPara)
            hPara = AnalysisPara(handles);
            setappdata(handles.figFlyAnalysis,'hPara',hPara);
            
            % if there is more than one subplot, update the data values
            if nReg > 1
                % retrieves the currently selected index
                sInd = getappdata(handles.figFlyAnalysis,'sInd');

                % updates the parameters
                sPara.ind(sInd,:) = [eInd,fIndNw,pInd];
                sPara.pData{sInd} = pData{pInd}{fIndNw,eInd};
                sPara.plotD{sInd} = plotD{pInd}{fIndNw,eInd};

                % updates the sub-plot data struct
                setappdata(handles.figFlyAnalysis,'sPara',sPara);            
            end              
        else
            % updates the parameter struct in the overall array
            if (fIndex > 0) && (str2double(eventdata) == 0)                 
                % updates the 
                pDataOld = getappdata(hPara,'pData');
                pData{pInd}{fIndex,eInd} = pDataOld;
                setappdata(handles.figFlyAnalysis,'pData',pData);
            end
            
            % if there is more than one subplot, update the data values
            if nReg > 1
                % retrieves the currently selected index
                sInd = getappdata(handles.figFlyAnalysis,'sInd');

                % updates the parameters
                sPara.ind(sInd,:) = [eInd,fIndNw,pInd];
                sPara.pData{sInd} = pData{pInd}{fIndNw,eInd};
                sPara.plotD{sInd} = plotD{pInd}{fIndNw,eInd};

                % updates the sub-plot data struct
                setappdata(handles.figFlyAnalysis,'sPara',sPara);            
            end             
            
            % reinitialises the function parameter struct            
            feval(getappdata(hPara,'initAnalysisGUI'),hPara,handles,1)
            pData = getappdata(handles.figFlyAnalysis,'pData');
        end
        
        % makes the parameter GUI         
        setappdata(handles.figFlyAnalysis,'fIndex',fIndNw)
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
    setappdata(handles.figFlyAnalysis,'fIndex',0)
    
    hPara = getappdata(handles.figFlyAnalysis,'hPara');
    setObjVisibility(hPara,'off');
end

% determines if there is any previous stored plotting values
[eInd,fInd,pInd] = getSelectedIndices(handles);
if all([eInd,fInd,pInd] > 0)
    % enables/disables the hold menu item (depending on whether the
    % hold flag is set to true)        
    if ~isempty(plotD{pInd}{fInd,eInd})              
        % if there is, then replot the data        
        snTot = getappdata(handles.figFlyAnalysis,'snTot'); 
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
    sInd = getappdata(handles.figFlyAnalysis,'sInd');

    % updates the parameters
    sPara.ind(sInd,:) = NaN;
    sPara.plotD{sInd} = [];
    sPara.pData{sInd} = [];

    % updates the sub-plot data struct
    setObjEnable(handles.menuUndock,any(~isnan(sPara.ind(:))))
    setappdata(handles.figFlyAnalysis,'sPara',sPara);            
end

% enables the listboxes/popup menus
setObjProps(handles,'on')

% disables the clear plot menu item
if isShowPara; setObjVisibility(hPara,'on'); end
setObjEnable(handles.menuSaveData,'off')
setObjEnable(handles.menuClearPlot,'off')

% resets the flag
updateFlag = 0;
    
% --- Executes on button press in buttonUpdateFigure.
function buttonUpdateFigure_Callback(hObject, eventdata, handles)

% global variables
global canSelect

% retrieves the experiment/function plot index
[isAdd,canSelect] = deal(false);
pause(0.05)

% disables the listboxes
[eInd,fInd,pInd] = getSelectedIndices(handles);
setObjProps(handles,'inactive')

% retrieves the function stack and solution file data
gPara = getappdata(handles.figFlyAnalysis,'gPara');
sPara = getappdata(handles.figFlyAnalysis,'sPara');
plotD = getappdata(handles.figFlyAnalysis,'plotD');
pData = getappdata(handles.figFlyAnalysis,'pData');
pDataT = getappdata(handles.figFlyAnalysis,'pDataT');
iData = getappdata(handles.figFlyAnalysis,'iData');
snTot = getappdata(handles.figFlyAnalysis,'snTot');
fcnStack = getappdata(handles.figFlyAnalysis,'fcnStack');

% retrieves the parameter GUI handle
hPara = getappdata(handles.figFlyAnalysis,'hPara');
try 
    guidata(hPara);
catch
    hPara = AnalysisPara(handles);
    setappdata(handles.figFlyAnalysis,'hPara',hPara);
end

% memory allocation
nReg = size(sPara.pos,1);

% sets the new solution data struct for the analysis
if (pInd == 3)
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
    setappdata(handles.figFlyAnalysis,'pData',pData);
elseif ~isempty(hPara)
    pData{pInd}{fInd,eInd} = getappdata(hPara,'pData');
    setappdata(handles.figFlyAnalysis,'pData',pData);
end

% retrieves the necessary data structs 
[pDataNw,plotDNw] = deal(pData{pInd}{fInd,eInd},plotD{pInd}{fInd,eInd});
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
                        initFcn = getappdata(hPara,'initAnalysisGUI');
                        pDataNw = feval(initFcn,hPara,handles,1);
                        setObjVisibility(hPara,'off')
                    end
                catch
                    return
                end
            end
            
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
    [plotDNw,isAdd] = deal({plotDCalc},true);
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
    axes(hAx)
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
    setappdata(hPara,'pData',pDataNw)
end

% updates the sub-plot parameters (if more than one subplot)
if nReg > 1
    % retrieves the currently selected index
    sInd = getappdata(handles.figFlyAnalysis,'sInd');    

    % updates the parameters
    sPara.ind(sInd,:) = [eInd,fInd,pInd];
    sPara.plotD{sInd} = {plotDCalc};
    sPara.pData{sInd} = pDataNw;
    
    % updates the sub-plot data struct
    setappdata(handles.figFlyAnalysis,'sPara',sPara);    
end

% updates the new parameter data struct into the total struct
pData{pInd}{fInd,eInd} = pDataNw;
setappdata(handles.figFlyAnalysis,'pData',pData);      

% sets the plot data into the main GUI
setObjEnable(handles.menuUndock,'on')
setObjEnable(handles.menuClearPlot,'on')
setObjEnable(handles.menuResetData,'on'); 
setObjEnable(handles.menuSaveTempData,'on'); 

if isempty(pDataNw.oP)
    setObjEnable(handles.menuSaveData,'off')    
elseif isempty(pDataNw.oP.yVar)
    setObjEnable(handles.menuSaveData,'off')    
else
    setObjEnable(handles.menuSaveData,'on'); 
end

% disables the listboxes
setObjVisibility(hPara,'on')
setObjEnable(handles.menuZoom,'on') 
setObjEnable(handles.menuDataCursor,'on') 
setObjProps(handles,'on')

% updates the plot data struct with the newly calculated values
plotD{pInd}{fInd,eInd} = plotDNw;
setappdata(handles.figFlyAnalysis,'plotD',plotD);  

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

% -------------------------------- %
% --- IMAGE PLOTTING FUNCTIONS --- %
% -------------------------------- %

% --- plots the metric graph to the image axis -------------------------- %
function plotMetricGraph(handles,iData,fmtStr)

% sets the GUI/format data structs (if not provided)
if (nargin == 1)
    iData = getappdata(handles.figFlyAnalysis,'iData');
    fmtStr = iData.fmtStr;
end

% ------------------------------ %
% --- GUI PROPERTY FUNCTIONS --- %
% ------------------------------ %

% --- initialises the plotting image axis 
function hAx = initAxesObject(handles)

% global variables
global isDocked newSz

% retrieves the sub-plot parameter struct
uStr = 'pixels';
sInd = getappdata(handles.figFlyAnalysis,'sInd');
sPara = getappdata(handles.figFlyAnalysis,'sPara');    

% sets the units string/axis handles for setting up the figure   
if (isDocked)    
    % retrieves the sub-plot parameter struct
    [h,hFig] = deal(handles,handles.figFlyAnalysis);
    sInd = getappdata(hFig,'sInd');
    sPara = getappdata(hFig,'sPara');    
else
    % if the plot axis is undocked, then use normalized coordinates
    hFig = getappdata(handles.figFlyAnalysis,'hUndock');
    h = guidata(hFig);            
end
       
% makes the GUI invisible and deletes all previous axes objects
clearAxesObject(handles)
    
% creates a new axis
hAx = axes('Units','normalized','outerposition',[0 0 1 1]);
axis(hAx,'off');    

% determines how many axis there are
if (size(sPara.pos,1) == 1)        
    % only one axis, so set with the overall plot panel
    set(hAx,'parent',h.panelPlot,'Units',uStr)        
    set(h.panelPlot,'Units','Pixels')
    newSz = get(h.panelPlot,'position');
else
    % set the plot within the new plot panel
    fcnAxC = getappdata(handles.figFlyAnalysis,'axisClickCallback');
    hPanel = findall(h.panelPlot,'tag','subPanel','UserData',sInd);                          
    set(hAx,'parent',hPanel,'Units',uStr,'UserData',sInd,'ButtonDownFcn',fcnAxC)        

    % retrieves the panel dimensions (in pixels)
    set(hPanel,'Units','Pixels')        
    newSz = get(hPanel,'position');
    set(hPanel,'Units','Normalized')        
end

% clears the axis and ensures it is off
set(0,'CurrentFigure',hFig)
set(hFig,'CurrentAxes',hAx)
cla(hAx); rotate3d(hAx,'off');     

% --- initialises the plotting image axis 
function clearAxesObject(handles,varargin)

% global variables
global isDocked

% retrieves the sub-plot parameter struct
sPara = getappdata(handles.figFlyAnalysis,'sPara');
nReg = size(sPara.pos,1);

% deletes all the axis objects
if (nReg == 1)
    if (isDocked)        
        h = handles.figFlyAnalysis;
        hAx = findall(handles.panelPlot,'type','axes');    
    else
        h = getappdata(handles.figFlyAnalysis,'hUndock');
        hAx = findall(h,'type','axes');
    end
    
    % deletes the axis objects (if they exist)
    if (~isempty(hAx)); delete(hAx); end
else
    % sets the currently selected index
    if (nargin == 1)
        sInd = getappdata(handles.figFlyAnalysis,'sInd');
    else
        sInd = 1:nReg;
    end
    
    % retrieves the axis objects for all the selected indices
    for i = sInd    
        if (isDocked)
            % case is the figure is docked
            hP = findall(handles.panelPlot,'tag','subPanel','UserData',i);
        else
            % case is the figure is undocked
            h = getappdata(handles.figFlyAnalysis,'hUndock');
            hP = findall(h,'tag','subPanel','UserData',i);
        end    
    
        % retrieves the axis object
        hAx = findall(hP,'type','axes');
        if (~isempty(hAx)); delete(hAx); end
    end        
end

% removes any annotations
if (verLessThan('matlab','8.4'))
    hGG = findall(h,'type','hggroup');
else
    hGG = findall(h,'type','annotation');
end

if (~isempty(hGG)); delete(hGG); end
    
% --- initialises the object properties within the GUI 
function initGUIObjects(handles,iData)

% disables all the panels
setPanelProps(handles.panelSolnData,'off')
setPanelProps(handles.panelExptInfo,'off')
setPanelProps(handles.panelPlotFunc,'off')
setPanelProps(handles.panelFuncDesc,'off')    

% makes the plot function listbox invisible
set(setObjVisibility(handles.listPlotFunc,'off'),'value',[])

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

% % sets up the Git menus
% if exist('GitFunc','file')
%     setupGitMenus(handles.figFlyAnalysis)
% end

% --- resizes the analysis GUI objects
function resetFigSize(h,fPos)

% sets the overall width/height of the figure
[W0,H0,dY,dX] = deal(fPos(3),fPos(4),10,10);
[HLF,YLF] = deal(H0 - 480,108);
[pPosO,HPF] = deal(get(h.panelOuter,'position'),HLF + 200);

% resets the plot panel dimensions
pPosPnw = [sum(pPosO([1 3]))+dX,dY,(W0-(3*dX+pPosO(3))),(H0-2*dY)];
set(h.panelPlot,'units','pixels','position',pPosPnw)

% updates the plot listbox/panel position
WPI = pPosO(3) - 2*dX;
set(h.panelPlotFunc,'position',[dX,dY,WPI,HPF]);
set(h.listPlotFunc,'position',[dX,YLF,WPI-2*dX,HLF]);

% updates the button position
pBut = get(h.buttonUpdateFigure,'position');
pBut(2) = YLF+HLF+dY;
set(h.buttonUpdateFigure,'position',pBut);

%
pTxt = get(h.textPlotType,'position');
pTxt(2) = HPF - 47;
set(h.textPlotType,'position',pTxt);

%
pPop = get(h.popupPlotType,'position');
pPop(2) = HPF - 50;
set(h.popupPlotType,'position',pPop);

% updates the experiment information panel position
pPosE = get(h.panelExptInfo,'position');
pPosE(2) = (3/2)*dY + HPF;
set(h.panelExptInfo,'position',pPosE);

% updates the solution file information panel position
pPosS = get(h.panelSolnData,'position');
pPosS(2) = sum(pPosE([2 4])) + dY/2;
set(h.panelSolnData,'position',pPosS);

% updates the outer panel position
pPosO(4) = fPos(4) - 2*dY;
set(h.panelOuter,'position',pPosO);

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

% determines if the program defaults have been set
if (~exist(progFileDir,'dir')); mkdir(progFileDir); end
if (exist(progFile,'file'))
    % if so, loads the program preference file and set the program
    % preferences (based on the OS type)
    A = load(progFile);
    ProgDef = checkDefaultDir(A.ProgDef);         
else
    % displays a warning
    uChoice = questdlg(['Program default file not found. Would you like ',...
        'to setup the program fefault file manually or automatically?'],...
        'Program Default Setup','Manually','Automatically','Manually');
    switch (uChoice)
        case ('Manually')
            % user chose to setup manually, so load the ProgDef sub-GUI
            ProgDef = ProgParaAnalysis(handles.figFlyAnalysis,[],1);
        case ('Automatically')
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
    switch (fldNames{i})
        case ('DirSoln')
            [dirName,type] = deal('Video Solution','file');
        case ('DirComb')
            [dirName,type] = deal('Experiment Solution','file');
        case ('OutFig')
            [dirName,type] = deal('Figure Output','directory');
        case ('OutData')
            [dirName,type] = deal('Data Output','directory');
        case ('DirFunc')
            [dirName,type] = deal('Analysis Function','directory');
        case ('TempFile')
            [dirName,type] = deal('Temporary File','directory');
    end
    
    % check to see if the directory exists
    if (isempty(nwDir))
        % flag that the directory has not been set
        isExist(i) = false;
        if (nargin == 1)
            wStr = sprintf('Warning! The "%s" %s is not set.',dirName,type);
            waitfor(warndlg(wStr,'Directory Location Error','modal'))   
        end
    elseif (exist(nwDir,fType) == 0)
        % if the directory does not exist, then clear the directory field
        % and flag a warning
        isExist(i) = false;
        eval(sprintf('%s = [];',nwVar));        
        if (nargin == 1)
            wStr = sprintf('Warning! The "%s" %s does not exist.',dirName,type);
            waitfor(warndlg(wStr,'Missing File/Directory','modal'))
        end
    end
end

% if any of the directories do not exist, then
if (any(~isExist))
    % runs the program default sub-ImageSeg
    if (nargin == 1)
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
    if (exist(nwDir,'dir') == 0)
        mkdir(nwDir)
    end
end

% saves the program default file
ProgDef = a;
save(progFile,'ProgDef');

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- sets the solution file in
function setSolnInfo(handles,sType,sName,snTot)

% retrieves the currently selected indices and plot types
eInd = getSelectedIndices(handles);

% enables the solution file info panel 
if nargin < 4
    snTot = getappdata(handles.figFlyAnalysis,'snTot');
end
setPanelProps(handles.panelSolnData,'on');

% sets the solution file direcoty (if not provided)
iData = getappdata(handles.figFlyAnalysis,'iData');
if nargin < 3
    sName = getappdata(handles.figFlyAnalysis,'sName');
    if iscell(sName); sName = sName{1}; end
end

% sets the text fields depending on the file load type
switch sType
    case ('Experiment') % case is a single experiment solution file(s)        
        if length(snTot) == 1
            ind = eInd;
            nCount = num2str(length(snTot(eInd).T));
            set(handles.textSolnType,'string','Experiment Solution File')            
            set(handles.textSolnCount,'string',nCount)
        else
            ind = 1:length(snTot);
            set(handles.textSolnType,'string','Experiment Solution Files')
            set(handles.textSolnCount,'string',num2str(sum(iData.indExpt)))
        end
    case ('Multiple') % case is a multi-experiment solution file
        ind = 1:length(snTot);
        set(handles.textSolnType,'string','Multi-Experiment Solution File')       
        set(handles.textSolnCount,'string',num2str(sum(iData.indExpt)))
end

% retrieves the tool-tip strings
sNameTT = getToolTipStrings(handles,ind);

% resets the solution file name (if flag as doing so)
set(handles.textSolnDirL,'string',' File: ')
set(handles.textSolnDir,'string',sName,'ToolTipString',sNameTT)

% --- initialises the apparatus data 
function appPara = initAppStruct(snTot,iMov)

% determines the number of apparatus
appPara = struct('ok',[],'Name',[],'flyok',[]);

% if the data has been read from the combined solution file, then
% set the dimensions on the cell dimensions
nApp = length(snTot.Px);
nFly = max(cellfun(@(x)(size(x,2)),snTot.Px));        

% sets the data struct fields
appPara.ok = true(nApp,1);
appPara.Name = cellfun(@(x)(sprintf('Region #%i',x)),...
                        num2cell(1:nApp)','un',0);

% sets the individual fly feasibility                    
if (isempty(iMov))           
    if (isempty(snTot))
        appPara.flyok = true(nFly,nApp);                                    
    elseif (isfield(snTot.appPara,'flyok'))
        appPara.flyok = snTot.appPara.flyok;
    else
        appPara.flyok = true(nFly,nApp);                    
    end
else
    appPara.flyok = iMov.flyok;
end

% --- resets the GUI objects with the new solution file struct, snTot 
function resetGUIObjects(handles,varargin)

% global variables
global updateFlag
updateFlag = 0;

% retrieves the solution struct and solution directory/file names
if (nargin == 1)
    snTot = getappdata(handles.figFlyAnalysis,'snTot');    
else
    snTot = varargin{1};
end

% updates the experiment indices
iData = getappdata(handles.figFlyAnalysis,'iData');    
iData.indExpt = true(length(snTot),1);
setappdata(handles.figFlyAnalysis,'iData',iData)    

% initialises the experiment, function type and plotting function indices
setappdata(handles.figFlyAnalysis,'eIndex',1)
setappdata(handles.figFlyAnalysis,'fIndex',0)

% resets the plot data structs
setappdata(handles.figFlyAnalysis,'pData',resetPlotDataStructs(handles,1))
setappdata(handles.figFlyAnalysis,'plotD',resetPlotDataStructs(handles))

% resets the popup menu items
sName = getappdata(handles.figFlyAnalysis,'sName');
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
setObjEnable(handles.menuSplitPlot,'on')
setObjEnable(handles.menuSaveData,'off')
setObjEnable(handles.menuSaveTempData,'off')
setObjEnable(handles.menuSaveSubConfig,'off')
setObjEnable(handles.menuOpenSubConfig,'on')
setObjEnable(handles.menuOpenTempData,'on')

% removes any existing panels/plots
hPanel = findall(handles.panelPlot,'tag','subPanel');
if ~isempty(hPanel); delete(hPanel); end    
setObjVisibility(handles.textSubInd,'off')
setObjVisibility(handles.popupSubInd,'off'); 

% updates the plot type popup
popupPlotType_Callback(handles.popupPlotType, '1', handles)

% resets the experiment listbox strings 
resetExptListStrings(handles,snTot)

% --- resets the experiment listbox strings 
function resetExptListStrings(handles,snTot)

% retrieves the solution struct (if not provided)
if (nargin == 1)
    snTot = getappdata(handles.figFlyAnalysis,'snTot');
end

% determines the currently selected plot type index value
hPopup = handles.popupExptIndex;
[eInd,~,pInd] = getSelectedIndices(handles);

% re-enables the save menu item
if pInd == 3
    % case is the multi-experiment type has been selected
    setObjVisibility(hPopup,'off')
    setSolnInfo(handles,'Multiple')
    
    % updates the properties of the other 
    set(setObjVisibility(handles.toggleExptSel,'on'),'value',0)
    setObjVisibility(handles.listExptSel,'on')
    toggleExptSel_Callback(handles.toggleExptSel,'1',handles)
    
else
    % retrieves the lists colour strings
    [sName,sName0] = deal(getappdata(handles.figFlyAnalysis,'sName'));
    sName = cellfun(@(x)(simpFileName(x,18)),sName,'un',0);
    sName = getListColourStrings(handles,sName,'Expt');
    
    % case is the single-experiment type has been selected
    setObjVisibility(hPopup,'on')        

    % sets the list/toggle button visibility properites
    setObjVisibility(handles.listExptSel,'off'); 
    setObjVisibility(handles.toggleExptSel,'off'); 
    pause(0.05);        
    
    % determines if the solution file is for a multi-experiment solution file
    isMulti = length(snTot) > 1;
    if (isMulti)
        % sets the table strings and makes the popup menu active
        set(setObjEnable(hPopup,'on'),'string',sName)
        setSolnInfo(handles,'Experiment')
    else
        % sets the table strings but makes the popup menu inactive
        set(setObjEnable(hPopup,'inactive'),'string',sName,'value',1)
        if (~iscell(sName0)); sName0 = {sName0}; end
        setSolnInfo(handles,'Experiment',sName0{eInd},snTot(eInd)) 
    end
end

% updates the experimental information
setExptInfo(handles,snTot);
    
% --- sets the experiment information
function setExptInfo(handles,snTot)

% retrieves the currently selected indices and plot types
hFig = handles.figFlyAnalysis;
[eInd,~,pInd] = getSelectedIndices(handles);

% enables the experiment information panel
if (nargin == 1); snTot = getappdata(hFig,'snTot'); end

% sets the fly/sub-region count
if isfield(snTot(eInd),'iMov')
    % case is the newer solution file format
    nFly = getSRCountMax(snTot(eInd).iMov);
    nApp = length(snTot(eInd).Px);
else
    % case is the older solution file format
    [nFly,nApp] = deal(size(snTot(eInd).Px{1},2),length(snTot(eInd).Px));
end

% turns on the enabled properties for the experimental info panel
setPanelProps(handles.panelExptInfo,'on')

% sets the experiment information fields
if pInd == 3
    % sets the save stimuli menu item
    hasStim = any(~cellfun(@isempty,field2cell(snTot,'stimP')));
    setObjEnable(handles.menuSaveStim,hasStim)
    
    % sets the experiment type
    set(handles.textExptType,'string','Combined Multi-Experiment')
    set(handles.textSolnDir,'string',getappdata(hFig,'fName'),...
                            'ToolTipString',getappdata(hFig,'fNameFull'))
    
    % calculates the sum of the experiment durations    
    iData = getappdata(hFig,'iData'); 
    ii = iData.indExpt;
    dT = sum(cellfun(@(x)(x{end}(end)-x{1}(1)),field2cell(snTot(ii),'T')));
else
    % sets the selected solution file       
    [snTotNw,sName] = deal(snTot(eInd),getappdata(hFig,'sName'));
    sNameF = getappdata(hFig,'sNameFull');
    dT = snTotNw.T{end}(end)-snTotNw.T{1}(1);   
    
    % sets the experiment type string
    if length(snTotNw.iExpt) > 1
        % sets the experiment type label string
        set(handles.textExptType,'string','Multi-Phase Experiment')        
        
        % determines the number stimuli that were used in the experiment
        Type = field2cell(cell2mat(field2cell(snTot.iExpt,'Info')),'Type');        
        if any(cellfun(@(x)(strContains(x,'Stim')),Type))
            % at least one stimuli experiment, so determine if any random
            % stimuli events were used
            setObjEnable(handles.menuSaveStim,'on')
        else
            % no stimuli events (all circadian rhythm)
            setObjEnable(handles.menuSaveStim,'off')
        end
    else        
        switch snTotNw.iExpt.Info.Type
            case ('RecordOnly') 
                set(handles.textExptType,'string','Recording Only')
                setObjEnable(handles.menuSaveStim,'off')
                
            case {'RecordStim','StimRecord'}
                set(handles.textExptType,'string','Recording and Stimuli')                    
                setObjEnable(handles.menuSaveStim,'on')
                
            case ('RTTrack')
                set(handles.textExptType,'string','Real-Time Tracking')
                setObjEnable(handles.menuSaveStim,'on')
        end
    end

    % calculates the experiment duration    
    if length(snTot) == 1
        set(handles.textSolnDir,'string',sName,...
                            'ToolTipString',getToolTipStrings(handles))
    else
        set(handles.textSolnDir,'string',[sName{eInd},'.ssol'],...
                            'ToolTipString',sNameF{eInd})       
    end
    
    % sets the stimuli/solution count strings
    set(handles.textSolnCount,'string',num2str(length(snTotNw.T)))
end

% sets the other fields
[~,~,tStr] = calcTimeDifference(dT);
nwStr = sprintf('%s Days, %s Hours, %s Mins',tStr{1},tStr{2},tStr{3});

% sets the other fields
set(findall(0,'string','Fly Tube Count: '),'string','Max Fly Count: ')
set(handles.textExptDur,'string',nwStr)
set(handles.textAppCount,'string',num2str(nApp))
set(handles.textFlyCount,'string',num2str(nFly))

% --- sets the plot function information/functions
function setPlotInfo(handles,snTot)

% enables the plot function panel
setPanelProps(handles.panelPlotFunc,'on')
setPanelProps(handles.panelFuncDesc,'on')

% sets the listbox strings
lName = {'Experiment Analysis (Individual)',...
         'Experiment Analysis (Population)'};
if (length(snTot) > 1)    
    lName = [lName,{'Multi-Experiment Analysis'}];         
end

% sets the popup strings to the highest level solution data type (either
% the multi-combined or single combined solution files)
setappdata(handles.figFlyAnalysis,'pIndex',length(lName))
set(handles.popupPlotType,'string',lName,'value',length(lName))
set(handles.listPlotFunc,'string',{' '},'value',1,'visible','on')
set(handles.textFuncDesc,'string','','visible','on')
set(handles.textFuncDescBack,'visible','on','backgroundcolor','k')

% --- scans the plotting function directory for valid functions and places
function scanPlotFuncDir(handles)

% global variables
global mainProgDir

% scans the plotting function directory for any functions
iProg = getappdata(handles.figFlyAnalysis,'iProg');
dDir = iProg.DirFunc;

% initialises the struct for the plotting function data types
a = struct('fcn',[],'Name',[],'fType',[],'fDesc',[]);
pDataT = struct('Indiv',[],'Pop',[],'Multi',[]);

% retrieves the partial/full file names
if (isdeployed)
    % loads the analysis function data file
    pFile = fullfile(mainProgDir,'Para Files','AnalysisFunc.mat');
    pData = load(pFile);
    
    % sets the partial/full file names
    [fDir,fName,eStr] = deal(pData.fDir,pData.fName,[]);
        
    % determines if this is the computer the executable was created on 
    [~, hName] = system('hostname');
    if (strcmp(hName,pData.hName))
        % if so, set the analysis files relative to the current computer
        fFile = cellfun(@(x,y)(fullfile(x,y)),fDir,fName,'un',0);
    else
        % otherwise, set the file names relative to the analysis file
        % directory on the new computer
        fFile = cellfun(@(x)(fullfile(dDir,x)),fName,'un',0);
    end

    % determines if any of the files are missing from where they should be
    ii = cellfun(@(x)(exist(x,'file')),fFile) > 0;
    if (any(~ii))
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
    if (~isempty(jj))
        % if there is a change, then flag that the executable may need 
        % to be updated to include these changes
        if (~isempty(eStr)); eStr = sprintf('%s\n',eStr); end
        eStr = sprintf(['%sThe following files in the default analysis file ',...
                        'directory are not up to date:\n\n'],eStr);

        kk = find(jj);
        for i = reshape(kk,1,length(kk)) 
            eStr = sprintf('%s => %s\n',eStr,fName{i}); 
        end  
    end
    
    % if there are any issues, then output a warning to screen
    if (~isempty(eStr))
        eStr = sprintf(['%s\nIt is strongly suggested that you recompile ',...
                        'the executable to account for the missing files ',...
                        'and/or out of date analysis functions.\n'],eStr);
        waitfor(warndlg(eStr,'Analysis Function Issues','modal'))
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
        
        % sets the field type strings
        tStr = pDataNw.Type; if (~iscell(tStr)); tStr = {tStr}; end
        
        % sets the new type field string
        for j = 1:length(tStr)
            typeStr = sprintf('pDataT.%s',tStr{j});
            if (isempty(eval(typeStr)))
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
    eval(sprintf('pDataT.%s = A(ii);',fNames{i}));
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
    if (strcmp(fName{i},'Multi'))
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
            if (nargin == 2)
                if (strcmp(fName{i},'Multi'))
                    pData{i}{j,k} = feval(p(j).fcn,snTot);
                else
                    pData{i}{j,k} = feval(p(j).fcn,reduceSolnAppPara(snTot(k)));
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
if (~any([eInd,fInd,pInd] == 0))    
    % retrieves the relevant data/parameter structs
    snTot = getappdata(handles.figFlyAnalysis,'snTot');
    pDataT = getappdata(handles.figFlyAnalysis,'pDataT');   
    pData = getappdata(handles.figFlyAnalysis,'pData');   
    fName = fieldnames(pDataT);
    
    % reduces the solution struct (if not analysing multi-experiment)
    if (pInd == 3)
        snTotL = snTot;
    else
        snTotL = reduceSolnAppPara(snTot(eInd));
    end
    
    % reinitialises the parameter struct
    p = eval(sprintf('pDataT.%s;',fName{pInd}));
    A = feval(p(fInd).fcn,snTotL);
    if (nargin == 2)
        pDataNw = varargin{1};
        pDataNw.pF = A.pF;
    else        
        pDataNw = A;    
    end
        
    % resets the data struct
    pData{pInd}{fInd,eInd} = pDataNw;            
    setappdata(handles.figFlyAnalysis,'pData',pData);            
            
    % resets the output array into the main GUI
    plotD = getappdata(handles.figFlyAnalysis,'plotD');    
    plotD{pInd}{fInd,eInd} = [];                
    setappdata(handles.figFlyAnalysis,'plotD',plotD);            
end 

% --- updates the list string, specified by type
function updateListColourStrings(handles,type)

% sets the list object to read (based on the type flag)
switch (type)
    case ('func') % case is for the analysis function list
        hObj = handles.listPlotFunc;
    case ('expt') % case is for the experiment selection list
        hObj = handles.popupExptIndex;
end

% updates the list string
StrOld = get(hObj,'string');
Str = cellfun(@(x)(retHTMLColouredStrings(x)),StrOld,'un',0);
set(hObj,'string',getListColourStrings(handles,Str,type))
    
% --- converts the list strings, lStr, to coloured strings depending on A) 
%     whether data has been calculated for the function/experiment, and B) 
%     whether the list is for the type 'expt' (experiment popup) or 'func'
%     (the analysis function listbox)
function lStrCol = getListColourStrings(handles,lStr,type)

% retrieves the plot data and the selected experiment/plot type indices
plotD = getappdata(handles.figFlyAnalysis,'plotD');        

% determines which of the 
[eInd,~,pInd] = getSelectedIndices(handles);
switch (lower(type))
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
setObjEnable(handles.listPlotFunc,state); 
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
if (nargin == 1); ind = 1:length(a); end

% sets the solution file tool-tip strings
sNameTT = a{ind(1)};
for i = 2:length(ind)
    sNameTT = sprintf('%s\n%s',sNameTT,a{ind(i)});
end

% --- temporary storage, reloading or removing of the solution data
function tempSolnDataIO(handles,Type)

% loads the data structs from the GUI
iData = getappdata(handles.figFlyAnalysis,'iData');
tFile = fullfile(iData.ProgDef.OutData,'TempSolnData.mat');

% performs the solution file 
switch Type
    case ('store') % case is storing the data
        % retrieves the solution data
        iMov = getappdata(handles.figFlyAnalysis,'iMov');
        snTot = getappdata(handles.figFlyAnalysis,'snTot');
        
        % if the solution data exists, then reset
        if (~isempty(snTot))
            % creates a loadbar figure
            h = ProgressLoadbar('Saving Temporary Solution File...');
            
            % saves the sub-region and solution file data struct to file
            save(tFile,'iMov','snTot');
            
            % closes the loadbar
            try delete(h); end
            
            % removes the sub-region and solution file data struct
            setappdata(handles.figFlyAnalysis,'iMov',[]);
            setappdata(handles.figFlyAnalysis,'snTot',[]);
        end
        
    case ('reload') % case is reloading the data
        if (exist(tFile,'file'))
            % creates a loadbar figure
            h = ProgressLoadbar('Loading Temporary Solution File...');
            
            % loads & deletes the temporary solution file
            a = load(tFile);
            delete(tFile);
            
            % closes the loadbar
            try delete(h); end            
            
            % removes the sub-region and solution file data struct
            setappdata(handles.figFlyAnalysis,'iMov',a.iMov);
            setappdata(handles.figFlyAnalysis,'snTot',a.snTot);        
        end
                
    case ('remove') % case is removing the data        
        if (exist(tFile,'file'))
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

% 
xi = 1:length(x);
fmtStr.Plt.xSm = smooth(xi,fmtStr.Plt.x,iData.sSpan,'sgolay');
fmtStr.Plt.ySm = smooth(xi,fmtStr.Plt.y,iData.sSpan,'sgolay'); 
