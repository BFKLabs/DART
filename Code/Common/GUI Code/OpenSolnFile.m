function varargout = OpenSolnFile(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @OpenSolnFile_OpeningFcn, ...
                   'gui_OutputFcn',  @OpenSolnFile_OutputFcn, ...
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


% --- Executes just before OpenSolnFile is made visible.
function OpenSolnFile_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global tableUpdate yGap
[tableUpdate,yGep] = deal(false,0);

% Choose default command line output for OpenSolnFile
handles.output = hObject;

% updates the selected tab
hFigM = varargin{1};
setappdata(hObject,'iTab',1);
setappdata(hObject,'nExpMax',4);
setappdata(hObject,'hFigM',hFigM);
setappdata(hObject,'isChange',false);
setappdata(hObject,'iProg',getappdata(hFigM,'iProg'));
setObjVisibility(hFigM,'off')

% initialises the GUI object properties
initObjProps(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes OpenSolnFile wait for user response (see UIRESUME)
% uiwait(handles.figOpenSoln);


% --- Outputs from this function are returned to the command line.
function varargout = OpenSolnFile_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when user attempts to close figOpenSoln.
function figOpenSoln_CloseRequestFcn(hObject, eventdata, handles)

% Hint: delete(hObject) closes the figure
menuExit_Callback(handles.menuExit, [], handles)

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

% initialisations
hFig = handles.figOpenSoln;
hFigM = getappdata(hFig,'hFigM');
sInfo = getappdata(hFig,'sInfo');
isChange = getappdata(hFig,'isChange');
postSolnLoadFunc = getappdata(hFigM,'postSolnLoadFunc');

% determines if there were any changes made
if isChange && ~isempty(sInfo)
    % if so, prompts the user if they wish to update the changes
    qStr = 'Do wish to update the changes you have made?';
    uChoice = questdlg(qStr,'Update Changes?','Yes','No','Cancel','Yes');
    switch uChoice
        case 'Yes'
            % case is the user chose to update            
            
            % determines
            sInfo = getappdata(hFig,'sInfo'); 
            if isempty(sInfo)
                expFile = {'Dummy'};
            else
                expFile = cellfun(@(x)(x.expFile),sInfo,'un',0);
            end
            
            % determines if there are repeated experiment names
            if length(expFile) > length(unique(expFile))
                % if so, then output an error message to screen
                mStr = sprintf(['There are repeated experiment names ',...
                                'within the loaded data list.\nRemove ',...
                                'all repeated file names before ',...
                                'attempting to continue.']);
                waitfor(msgbox(mStr,'Repeated File Names','modal'))
                
                % exits the function
                return
            end
            
            % updates the search directories in the main gui
            setappdata(hFigM,'sDirO',getappdata(hFig,'sDir'));            
            
            % delete the figure and run the post solution loading function
            delete(hFig)
            postSolnLoadFunc(hFigM,sInfo);                           
            
        case 'No'
            % case is the user chose not to update
            
            % delete the figure and run the post solution loading function
            delete(hFig)
            postSolnLoadFunc(hFigM);    
    end
else
    % otherwise, delete the figure and run the post solution loading func
    delete(hFig)
    postSolnLoadFunc(hFigM); 
end

%-------------------------------------------------------------------------%
%                        OBJECT CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ----------------------------------- %
% --- EXPLORER TREE PANEL OBJECTS --- %
% ----------------------------------- %

% --- Executes on button press in buttonSetDir.
function buttonSetDir_Callback(hObject, eventdata, handles)

% GUI field retrieval
hFig = handles.figOpenSoln;
iTab = getappdata(hFig,'iTab');
jRoot = getappdata(hFig,'jRoot');

% determines if the explorer tree exists for the current tab
if ~isempty(jRoot{iTab})
    % if the tree explorer exists for this tab, then prompt the user if
    % they actually want to overwrite the locations
    qStr = 'Are you sure you want to reset the search root directory?';
    uChoice = questdlg(qStr,'Reset Search Root?','Yes','No','Yes');
    if ~strcmp(uChoice,'Yes')
        % if the user cancelled, then exit the function
        return
    end
end

% creates the explorer tree
setappdata(hFig,'isChange',true)
createDepExplorerTree(hFig);

% --- Executes on button press in buttonAddSoln.
function buttonAddSoln_Callback(hObject, eventdata, handles)

% global variables
global hh

% object/array retrieval
hFig = handles.figOpenSoln;
hPanelEx = handles.panelExptInfo;
iTab = getappdata(hFig,'iTab');
sDir = getappdata(hFig,'sDir');
jMov = getappdata(hFig,'jMov');
sFile = getappdata(hFig,'sFile');
iProg = getappdata(hFig,'iProg');
sInfo0 = getappdata(hFig,'sInfo');
jTable = getappdata(hFig,'jTable');

% other initialisations
tDir = iProg.TempFile;

% sets the full names of the selected files
isSel = cellfun(@(x)...
                (strcmp(get(x,'SelectionState'),'selected')),jMov{iTab});
sFileS = sFile{iTab}(isSel);

% allocates memory for the 
switch iTab
    case 1
        % case is the video solution files
        [fDirS,fNameS] = groupSelectedFiles(sFileS);
        
        % other initialisations
        nFile = length(fDirS);
        wStr = {'Overall Progress','Directory Progress'};
        mName = cellfun(@(x)(getFinalDirString(x)),fDirS,'un',0);
        
    otherwise
        % case is the experiment solution files
        fDirS = cellfun(@(x)(fileparts(x)),sFileS,'un',0);
        fNameS = cellfun(@(x)(getFileName(x,1)),sFileS,'un',0);        
        
        % other initialisations
        nFile = length(sFileS);
        wStr = {'Overall Progress','Loading Data File',...
                'Current File Progress'};
        if iTab == 3
            [wStr{end+1},mName] = deal('Data Output',[]);
        else
            mName = cellfun(@(x)(getFileName(x)),sFileS,'un',0);
        end
end

% creates the progress bar
hh = ProgBar(wStr,'Solution File Loading');
isOK = true(nFile,1);

% reads the information from each of the data file/directories
for i = 1:nFile
    % resets the minor progressbar fields 
    if i > 1
        for j = 2:length(wStr)
            hh.Update(j,wStr{j},0);
        end
    end
    
    switch iTab
        case 1
            % case is a video solution file directory
            
            % updates the progressbar
            wStrNw = sprintf('%s (Directory %i of %i)',wStr{1},i,nFile);
            hh.Update(1,wStrNw,i/(nFile+1));
            
            % reads in the video solution file data
            fFileS = cellfun(@(x)...
                            (fullfile(fDirS{i},x)),fNameS{i},'un',0);
            [snTotNw,iMov,eStr] = combineSolnFiles(fFileS);
            
            % if the user cancelled, or there was an error, then exit    
            if isempty(snTotNw)
                % if there was an error, then output this to screen
                if isempty(eStr)
                    % exits the function
                    setappdata(hFig,'sInfo',sInfo0)
                    hh = [];                    
                    return  
                else
                    % otherwise, flag that there was an error with loading
                    % the data from the directory
                    isOK(i) = false;
                end           
            else
                % sets up the fly location ID array
                snTotNw.iMov = reduceRegionInfo(iMov);
                snTotNw.cID = setupFlyLocID(snTotNw.iMov);

                % reduces the region information             
                appendSolnInfo(hFig,snTotNw,1,fDirS{i});                
            end            
            
        case 2
            % updates the progressbar
            wStrNw = sprintf('%s (File %i of %i)',wStr{1},i,nFile);
            hh.Update(1,wStrNw,i/(nFile+1));            
            
            % case is a group of single experiment solution files
            fFileS = fullfile(fDirS{i},fNameS{i});
            [snTotNw,ok] = loadExptSolnFiles(tDir,fFileS,1,hh);  
            if ~ok
                % if the user cancelled, then exit the function
                setappdata(hFig,'sInfo',sInfo0)
                return
            end
            
            % reduces the region information 
            snTotNw.iMov = reduceRegionInfo(snTotNw.iMov);
            appendSolnInfo(hFig,snTotNw,2,fFileS);
            
        case 3
            % updates the progressbar
            wStrNw = sprintf('%s (File %i of %i)',wStr{1},i,nFile);
            hh.Update(1,wStrNw,i/(nFile+1));                 
            
            % loads the multi-experiment solution file
            fFileS = fullfile(fDirS{i},fNameS{i});
            [snTotNw,mNameNw,ok] = ...
                                loadMultiExptSolnFiles(tDir,fFileS,[],hh);            
            if ~ok
                % if the user cancelled, then exit the function
                return
            end
            
            % reduces the region information for each experiment
            for j = 1:length(snTotNw)
                snTotNw(j).iMov = reduceRegionInfo(snTotNw(j).iMov);
            end
            
            % case is a group of multi experiment solution files
            appendSolnInfo(hFig,snTotNw,3,fFileS,mNameNw);
            mName = [mName;mNameNw(:)];
    end
end

% closes the progress bar
hh.closeProgBar()
hh = [];

%
if any(~isOK)
    % if there was an error loading a directory/file, then output these
    % directories to screen
    eStr = sprintf(['There was an error loading files from the ',...
                    'following directories:\n\n']);
    for i = find(~isOK(:))
        % adds in the error directories
        if iTab == 1
            eStr = sprintf('%s * %s\n',eStr,fDirS{i});
        else
            fFileS = fullfile(fDirS{i},fNameS{i});
            eStr = sprintf('%s * %s\n',eStr,fFileS);
        end
    end
    
    % outputs the error message to screen
    eStr = sprintf(['%s\nYou will need to ensure that all the ',...
                    'videos for this experiment have been tracked ',...
                    'correctly and are not corrupted.'],eStr);
    waitfor(msgbox(eStr,'Corrupt or Infeasble Data','modal'))
    
    % removes the directories which gave an error
    mName = mName(isOK);
end

% recreates the explorer tree
createDepExplorerTree(hFig,sDir{iTab})
if isempty(mName); return; end

% updates the solution file/added experiments array
updateExptInfoTable(handles)
nExp = jTable.getRowCount;

% updates the added experiment objects
setPanelProps(hPanelEx,'on');
setObjEnable(handles.buttonClearAll,'on');
set(handles.textExptCount,'string',num2str(nExp),'enable','on')

% updates the change flag
setappdata(hFig,'isChange',true)

% --- callback function for selecting the protocol tabs
function tabSelected(hObj, ~, handles)

% updates the selected tab
setappdata(handles.figOpenSoln,'iTab',get(hObj,'UserData'));

% updates the table information
tableUpdateSel([],[],handles.figOpenSoln)

% --- callback function for editing the apparatus inclusion checks --- %
function tableUpdateSel(hObject,eventdata,hFig)

% retrieves the tree handles
iTab = getappdata(hFig,'iTab');
jMov = getappdata(hFig,'jMov');
sDir = getappdata(hFig,'sDir');
sFile = getappdata(hFig,'sFile');

% text object handles strings
handles = guidata(hFig);
txtTag = {'textFileCount','textSelectedCount','textRootDir'};

% if there is no information then exit
if isempty(jMov{iTab})
    nSel = 0;
else
    % sets the new selected movie count
    isSel = cellfun(@(x)...
                (strcmp(get(x,'SelectionState'),'selected')),jMov{iTab});    
    nSel = sum(isSel);            
end

% updates the batch process running menu item
setObjEnable(handles.buttonAddSoln,nSel > 0)

% sets the new text label strings
if isempty(sDir{iTab})
    % case is no file explorer has been created
    txtStr = repmat({'N/A'},1,length(txtTag));  
    txtStrTT = '';
else
    % case is file explorer has been created 
    txtStr = {num2str(length(sFile{iTab})),num2str(nSel),sDir{iTab}};
    txtStrTT = sDir{iTab};
end
      
% updates the object strings/properties
hTxt0 = findall(handles.panelSolnExplorer,'style','text');
cellfun(@(x,y)(set(findall(hTxt0,'tag',x),'String',y)),txtTag,txtStr);
arrayfun(@(x)(setObjEnable(x,~isempty(sDir{iTab}))),hTxt0)
set(handles.textRootDir,'tooltipstring',txtStrTT)

% -------------------------------------- %
% --- ADDED EXPERIMENT PANEL OBJECTS --- %
% -------------------------------------- %

% --- table cell update callback function
function tableCellChange(hTable,evnt,handles)

% global variables
global tableUpdate

% if the table is updating automatically, then exit
if tableUpdate; return; end

% field retrieval
hFig = handles.figOpenSoln;
try
    sInfo = getappdata(hFig,'sInfo');
    jTable = getappdata(hFig,'jTable');
    [iRow,iCol] = deal(get(evnt,'FirstRow'),get(evnt,'Column'));
catch
    return
end

% retrieves the original table data
tabData = getTableData(hFig);
nwStr = jTable.getValueAt(iRow,iCol);

% determines if the new string is valid and feasible
if (iRow+1) >= size(tabData,1)
    % case is the experiment has not been loaded
    mStr = sprintf(['It isn''t possible to set the name for an ',...
                    'experiment that is not loaded.']);
    waitfor(msgbox(mStr,'Experiment Naming Error','modal'))

elseif strcmp(nwStr,tabData{iRow+1,iCol+1})
    % case is the string name has not changed
    return
    
elseif iCol == 0
    % case is the experiment name is being updated
    nwStr = jTable.getValueAt(iRow,iCol);
    iExp = iRow + 1;

    % determines if new experiment name is valid
    if checkNewExptName(sInfo,nwStr,iExp)
        % updates the experiment name and change flag
        sInfo{iRow+1}.expFile = nwStr;
        setappdata(hFig,'sInfo',sInfo)
        setappdata(hFig,'isChange',true);
        
        % updates the table background colours
        tableUpdate = true;
        resetExptTableBGColour(hFig,0);
        jTable.repaint();
        pause(0.05);
        tableUpdate = false;
        
        % exits the function        
        return
    end    
end

% if not, then resets the table cell back to the original value    
tableUpdate = true;
if (iRow+1) >= size(tabData,1)
    jTable.setValueAt([],iRow,iCol);
else
    jTable.setValueAt(tabData{iRow+1,iCol+1},iRow,iCol);
end
pause(0.05)
tableUpdate = false;

% --- Executes on button press in buttonClearExpt.
function buttonClearExpt_Callback(hObject, eventdata, handles)

% global variables
global tableUpdate

% object handles
hFig = handles.figOpenSoln;
iTab = getappdata(hFig,'iTab');
sDir = getappdata(hFig,'sDir');
hTable = handles.tableExptInfo;
nExpMax = getappdata(hFig,'nExpMax');

% prompts the user if they really do want to clear all the loaded data
qStr = 'Are you sure you want to clear the selected experiment data?';
uChoice = questdlg(qStr,'Confirm Data Clearing?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if the user cancelled, then exit the function
    return
end

% retrieves the currently selected table rows
jTable = getappdata(hFig,'jTable');
jTableMod = jTable.getModel;

% determines the selected rows
iSel = double(jTable.getSelectedRows)+1;
iNw = ~setGroup(iSel(:),[jTable.getRowCount,1]);

% if there are no experiments left, then clear everything
if ~any(iNw)
    buttonClearAll_Callback(handles.buttonClearAll, [], handles)
    return
end

% disables the added experiment information fields
setObjEnable(hObject,'off')
setObjEnable(handles.buttonClearAll,0)
setObjEnable(handles.buttonShowProtocol,0)
setObjVisibility(handles.tableGroupNames,0)
set(setObjEnable(handles.textExptCount,1),'string',num2str(sum(iNw)))

% reduces down the solution file information
sInfo = getappdata(hFig,'sInfo');
setappdata(hFig,'sInfo',sInfo(iNw));
setappdata(hFig,'isChange',true)

% removes the rows from the table
tableUpdate = true;

% removes the table selection
removeTableSelection(hTable)

% shifts the rows (if there are any rows under those being cleared)
if iSel(end)+1 <= jTable.getRowCount
    jTableMod.moveRow(iSel(end),jTable.getRowCount-1,iSel(1)-1)
end

% removes/clears the rows
iOfs = 1;
for i = 1:length(iSel)
    if jTable.getRowCount > nExpMax
        % if there are more rows than required, then reset
        jTableMod.removeRow(jTable.getRowCount-1)
        iOfs = iOfs + 1;
    else
        % removes the table values/resets the bg colour for all cells
        k = nExpMax - (i - iOfs);
        clearExptInfoTableRow(hFig,k)        
    end
end

% resets the column widths
resetExptTableBGColour(hFig,0);
resetColumnWidths(handles)

% repaints the table
jTable.repaint()

% resets the table update flag
pause(0.05);
tableUpdate = false;

% creates the explorer tree
if ~isempty(sDir{iTab})
    createDepExplorerTree(hFig,sDir{iTab});
end

% --- Executes on button press in buttonClearAll.
function buttonClearAll_Callback(hObject, eventdata, handles)

% object handles
hFig = handles.figOpenSoln;
iTab = getappdata(hFig,'iTab');
sDir = getappdata(hFig,'sDir');

% prompts the user if they really do want to clear all the loaded data
if ~isempty(eventdata)
    qStr = 'Are you sure you want to clear all the loaded solution data?';
    uChoice = questdlg(qStr,'Confirm Data Clearing?','Yes','No','Yes');
    if ~strcmp(uChoice,'Yes')
        % if the user cancelled, then exit the function
        return
    end
end

% resets the storage arrays
resetStorageArrays(hFig)

% disables all the buttons
setObjEnable(hObject,0)
setObjEnable(handles.buttonClearExpt,0)
setObjEnable(handles.buttonShowProtocol,0)
setObjVisibility(handles.tableGroupNames,0)
set(handles.textExptCount,'string',0)

% disables the added experiment information fields
resetExptInfoTable(handles);

% disables and resets the experiment info field
setappdata(hFig,'isChange',true)

% creates the explorer tree
if ~isempty(sDir{iTab})
    createDepExplorerTree(hFig,sDir{iTab});
end

% --- Executes when selected cell(s) is changed in tableExptInfo.
function tableExptInfo_CellSelectionCallback(hObject, eventdata, handles)

%
pause(0.05);

% object retrieval
hFig = handles.figOpenSoln;
sInfo = getappdata(hFig,'sInfo');

% if there is no solution data loaded, then exit the function
if isempty(sInfo) || isempty(eventdata.Indices)
    return
end

% retrieves the other imporant fields
iExp = eventdata.Indices(1);
setappdata(hFig,'iExp',iExp);

% updates the group table
setObjEnable(handles.buttonClearExpt,1)
updateGroupTableProps(handles);

% ------------------------------------- %
% --- EXPERIMENT INFO PANEL OBJECTS --- %
% ------------------------------------- %

% --- Executes on button press in buttonShowProtocol.
function buttonShowProtocol_Callback(hObject, eventdata, handles)

% sets the panel object visibility properties
setObjVisibility(handles.panelSolnExplorer,0)
setObjVisibility(handles.panelExptOuter,0)
setObjVisibility(handles.panelStimOuter,1)

% resets the stimuli axes
resetStimAxes(handles)

% --- Executes on button press in buttonHideProtocol.
function buttonHideProtocol_Callback(hObject, eventdata, handles)

% sets the panel object visibility properties
setObjVisibility(handles.panelSolnExplorer,1)
setObjVisibility(handles.panelExptOuter,1)
setObjVisibility(handles.panelStimOuter,0)

% --- Executes when entered data in editable cell(s) in tableGroupNames.
function tableGroupNames_CellEditCallback(hObject, eventdata, handles)

% initialisations
mStr = [];
indNw = eventdata.Indices;
hFig = handles.figOpenSoln;
iExp = getappdata(hFig,'iExp');
sInfo = getappdata(hFig,'sInfo');

% removes the selection highlight
jScroll = findjobj(hObject);
jTable = jScroll.getComponent(0).getComponent(0);
jTable.changeSelection(-1,-1,false,false);

% determines if the current group/region is rejected
isRejected = strcmp(eventdata.PreviousData,'* REJECTED *');
if ~isRejected
    % if not, determines if the new name is valid
    nwName = eventdata.NewData;
    if chkDirString(nwName)
        % if the new string is valid, then update the solution info    
        sInfo{iExp}.gName{indNw(1)} = nwName;
        setappdata(hFig,'sInfo',sInfo)
    else
        % case is the string is not valid
        mStr = 'The group/region name cannot contain a special character';
    end       
else
    % case is the region/group is rejected
    mStr = 'This group/region is rejected and cannot be altered.';
end
    
% if there was an error, then output it to screen and exit
if ~isempty(mStr)
    % outputs the error message to screen
    waitfor(msgbox(mStr,'Invalid Group Name'));
    
    % resets the table back to the last valid name
    Data = get(hObject,'Data');
    Data{indNw(1),indNw(2)} = eventdata.PreviousData;
    set(hObject,'Data',Data);
    
    % exits the function
    return
end

% resets the table background colours
bgCol = getTableBGColours(handles,sInfo{iExp});
set(hObject,'BackgroundColor',bgCol)

% updates the change flag
setappdata(hFig,'isChange',true)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the GUI object properties
function initObjProps(handles)

% creates the load bar
h = ProgressLoadbar('Loading Solution File Information...');

% initialisations
hAx = handles.axesStim;
hFig = handles.figOpenSoln;
hPanelT = handles.panelSolnExplorer;
hFigM = getappdata(hFig,'hFigM');
sInfo0 = getappdata(hFigM,'sInfo');
tStr = {'Video Solution Files (*.soln)',...
        'Experiment Solution Files (*.ssol)',...
        'Multi-Expt Solution Files (*.msol)'};

% resets the current figure axes handle
set(hFig,'CurrentAxes',hAx);
    
% sets the initial/current directories
sDirO = getappdata(hFigM,'sDirO');
setappdata(hFig,'sDir',sDirO);
setappdata(hFig,'sDir0',sDirO);    
    
% disables the add button and added expt/expt info panels
setObjEnable(handles.buttonAddSoln,'off')

% sets the object positions
tabPos = getTabPosVector(hPanelT,[5,-15,30,30]);
pPos = [5,5,tabPos(3:4)-[15,40]];

% creates a tab panel group
hTabGrp = createTabPanelGroup(hPanelT,1);
set(hTabGrp,'position',tabPos,'tag','hTabGrp')

% creates the tabs for each code difference type
nTab = length(tStr);
[hTab,hPanel] = deal(cell(nTab,1));
for i = 1:nTab
    % creates the new tab panel
    hTab{i} = createNewTabPanel(...
                       hTabGrp,1,'title',tStr{i},'UserData',i);         
    set(hTab{i},'ButtonDownFcn',{@tabSelected,handles})
                   
    % creates the tree-explorer panel
    hPanel{i} = uipanel('Title','','Units','Pixel','Position',pPos);
    set(hPanel{i},'Parent',hTab{i});
    resetObjPos(hPanel{i},'Bottom',5)          
end

% pause to allow figure update
resetStorageArrays(hFig)
pause(0.05);

% retrieves the tab group java object handles
jTabGrp = getTabGroupJavaObj(hTabGrp);

% updates the objects into the GUI
setappdata(hFig,'hTab',hTab)
setappdata(hFig,'hPanel',hPanel)
setappdata(hFig,'hTabGrp',hTabGrp) 

% creates the experiment information table
createExptInfoTable(handles)

% adds to the added list 
if ~isempty(sInfo0)
    % updates the solution file information
    setappdata(hFig,'sInfo',sInfo0)
    
    % sets the added list strings    
    setObjEnable(handles.buttonClearAll,'on')
    setPanelProps(handles.panelExptInfo,'on')
    set(handles.textExptCount,'string',num2str(length(sInfo0)))    
    
    % updates the experiment information table
    updateExptInfoTable(handles)
end

% creates the explorer tree for each panel
hasTree = true(nTab,1);
for i = nTab:-1:1
    % creates a new explorer tree on the current tab
    setappdata(hFig,'iTab',i)
    createDepExplorerTree(hFig,sDirO{i})
    
    % determines if a tree was created
    jRoot = getappdata(hFig,'jRoot');
    hasTree(i) = ~isempty(jRoot{i});
    if ~hasTree(i)
        % if not, then disable the tab
        jTabGrp.setEnabledAt(i-1,false)
    end
end

% sets the first valid tab
i0 = find(hasTree,1,'first');
set(hTabGrp,'SelectedTab',hTab{i0});
setappdata(hFig,'iTab',i0)

% closes the loadbar
try; close(h); end

% --- creates the experiment information table
function createExptInfoTable(handles)

% object handle retrieval
hFig = handles.figOpenSoln;
hTable = handles.tableExptInfo;
hPanel = handles.panelExptInfo;
nExpMax = getappdata(hFig,'nExpMax');

% sets the table header strings
hdrStr = {createTableHdrString({'Experiment Name'}),...
          createTableHdrString({'Parent','File'}),...
          createTableHdrString({'File','Type'}),...
          createTableHdrString({'Setup','Type'}),...
          createTableHdrString({'Stimuli','Protocol'}),...          
          createTableHdrString({'Duration'})};

% sets up the table data array
dX = 6;
dPos = [2*dX,30];
cWidMin = {230,110,40,40,75,70};
cWidMax = {250,130,40,40,75,70};
tabData = cell(nExpMax,length(hdrStr));
grayCol = getJavaColour(0.81*ones(1,3));
pPos = get(hPanel,'Position');

% creates the java table object
jScroll = findjobj(hTable);
[jScroll, hContainer] = javacomponent(jScroll, [], hPanel);
set(hContainer,'Units','Pixels','Position',[dX*[1,1],pPos(3:4)-dPos])

% creates the java table model
jTable = jScroll.getViewport.getView;
jTableMod = javax.swing.table.DefaultTableModel(tabData,hdrStr);
jTable.setModel(jTableMod);

% sets the table callback function
cbFcn = {@tableCellChange,handles};
jTableMod = handle(jTableMod,'callbackproperties');
addJavaObjCallback(jTableMod,'TableChangedCallback',cbFcn);

% creates the table cell renderer
tabCR1 = ColoredFieldCellRenderer(java.awt.Color.white);
tabCR2 = ColoredFieldCellRenderer(java.awt.Color.white);

% sets the table text to black
for i = 1:size(tabData,1)
    for j = 1:size(tabData,2)
        % sets the background colours
        tabCR1.setCellBgColor(i-1,j-1,grayCol);
        tabCR2.setCellBgColor(i-1,j-1,grayCol);        
        
        % sets the foreground colours
        tabCR1.setCellFgColor(i-1,j-1,java.awt.Color.black);
        tabCR2.setCellFgColor(i-1,j-1,java.awt.Color.black);                
    end
end

% disables the smart alignment
tabCR1.setSmartAlign(false);
tabCR2.setSmartAlign(false);

% sets the cell renderer horizontal alignment flags
tabCR1.setHorizontalAlignment(2)
tabCR2.setHorizontalAlignment(0)

% Finally assign the renderer object to all the table columns
for cID = 1:length(hdrStr)
    cMdl = jTable.getColumnModel.getColumn(cID-1);
    cMdl.setMinWidth(cWidMin{cID})
    cMdl.setMaxWidth(cWidMax{cID})
    
    if cID == 1
        cMdl.setCellRenderer(tabCR1);        
    else
        cMdl.setCellRenderer(tabCR2);
    end
end

% updates the table header colour
gridCol = getJavaColour(0.5*ones(1,3));
jTable.getTableHeader().setBackground(gridCol);
jTable.setGridColor(gridCol);
jTable.setShowGrid(true);

% disables the resizing
jTableHdr = jTable.getTableHeader(); 
jTableHdr.setResizingAllowed(false); 
jTableHdr.setReorderingAllowed(false);

% repaints the table
jTable.repaint()
jTable.setAutoResizeMode(jTable.AUTO_RESIZE_ALL_COLUMNS)
jTable.getColumnModel().getSelectionModel.setSelectionMode(2)

% sets the table cell renderer
setappdata(hFig,'tabCR1',tabCR1)
setappdata(hFig,'tabCR2',tabCR2)
setappdata(hFig,'jTable',jTable)

% --- resets all experiment information table
function resetExptInfoTable(handles)

% global variables
global tableUpdate

% if the table is updating automatically, then exit
if tableUpdate; return; end

% object retrieval
hFig = handles.figOpenSoln;
hTable = handles.tableExptInfo;
jTable = getappdata(hFig,'jTable');
nExpMax = getappdata(hFig,'nExpMax');

% sets the table update flag to on
tableUpdate = true;

% removes the table selection
removeTableSelection(hTable)

% removes/clears all the fields in the table
for i = jTable.getRowCount:-1:1
    if i > nExpMax
        jTableMod.removeRow(jTable.getRowCount-1)
    else
        clearExptInfoTableRow(hFig,i)  
    end
end

% repaints the table
jTable.repaint;
pause(0.1);

% resets the table update flag
tableUpdate = false;

% --- resets the stimuli axes properties
function resetStimAxes(handles)

% object retrieval
hAx = handles.axesStim;
hFig = handles.figOpenSoln;
iExp = getappdata(hFig,'iExp');
sInfo = getappdata(hFig,'sInfo');

%
fAlpha = 0.2;
tLim = [120,6,1e6];
[axSz,lblSz] = deal(16,20);
tStr0 = {'m','h','d'};
tUnits0 = {'Mins','Hours','Days'};
sTrainEx = sInfo{iExp}.snTot.sTrainEx;

% sets the 
[devType,~,iC] = unique(sTrainEx.sTrain(1).devType,'stable');
nCh = NaN(length(devType),1);

% sets up the 
for iCh = 1:length(devType)
    % calculates the number of motor channels 
    if startsWith(devType{iCh},'Motor')
        nCh(iCh) = sum(iC == iCh);
    end

    % strips of the number from the device string
    devType{iCh} = regexprep(devType{iCh},'[0-9]','');
end

chCol = flip(getChannelCol(devType,nCh));

% determines the experiment units string
Texp = sInfo{iExp}.snTot.T{end}(end);
iLim = find(cellfun(@(x)(convertTime(Texp,'s',x)),tStr0) < tLim,1,'first');
[tStr,tUnits] = deal(tStr0{iLim},tUnits0{iLim});
tLim = [0,Texp]*getTimeMultiplier(tStr,'s');

% clears the axes and turns it on
cla(hAx)
axis(hAx,'on');       
hold(hAx,'on');
axis('ij');

% calculates the scaled 
for i = 1:length(sTrainEx.sTrain)
    % sets up the signal
    [sPara,sTrain] = deal(sTrainEx.sParaEx(i),sTrainEx.sTrain(i));
    xyData0 = setupFullExptSignal(hFig,sTrain,sPara);
    
    % scales the x/y coordinates for the axes time scale
    tMlt = getTimeMultiplier(tStr,sPara.tDurU);
    tOfs = getTimeMultiplier(tStr,sPara.tOfsU)*sPara.tOfs;    
    xyData = cellfun(@(x)(colAdd(colMult(x,1,tMlt),1,tOfs)),xyData0,'un',0);        
        
    % plots the non-empty signals
    for iCh = 1:length(xyData)
        % plots the channel region markers
        if iCh < length(xyData)
            plot(hAx,tLim,iCh*[1,1],'k--','linewidth',1)
        end
        
        % creates a new patch (if there is data)
        if ~isempty(xyData{iCh})
            [xx,yy] = deal(xyData{iCh}(:,1),xyData{iCh}(:,2));
            yy = (1 - (yy - floor(min(yy)))) + (iCh-1);
            patch(hAx,xx([1:end,1]),yy([1:end,1]),chCol{iCh},...
                  'EdgeColor',chCol{iCh},'FaceAlpha',fAlpha,'LineWidth',1);
        end
    end   
    
    % sets the axis limits (first stimuli block only)
    if i == 1
        % sets the axis properties
        yTick = (1:length(xyData)) - 0.5;
        yTickLbl = cellfun(@(x,y)(sprintf('%s (%s)',y,x(1))),...
                            sTrain.devType,sTrain.chName,'un',0);
        set(hAx,'xlim',tLim,'ylim',[0,length(xyData)],'ytick',yTick,...
                'yticklabel',yTickLbl,'FontUnits','Pixels',...
                'FontSize',axSz,'FontWeight','bold','box','on')
            
        % sets the axis/labels
        xLbl = sprintf('Time (%s)',tUnits);
        xlabel(hAx,xLbl,'FontWeight','bold','FontUnits','Pixels',....
                        'FontSize',lblSz)
    end
end

hold(hAx,'off');

% ------------------------------- %
% --- EXPLORER TREE FUNCTIONS --- %
% ------------------------------- %

% --- creates the commit explorer tree
function createDepExplorerTree(hFig,sDirNw)

% imports the checkbox tree
import com.mathworks.mwswing.checkboxtree.*

% parameters and initialisations
fExtn = {'.soln','.ssol','.msol'};

% retrieves the other important fields
iTab = getappdata(hFig,'iTab');
sDir = getappdata(hFig,'sDir');
hPanel = getappdata(hFig,'hPanel');

% sets the default input arguments
if ~exist('sDirNw','var')
    sDirNw = [];
end

% sets the root search directory (dependent on stored values and tab index)
if isempty(sDirNw)
    if isempty(sDir{iTab})
        switch iTab
            case 1
                % case is video solution files
                defDir = iProg.DirSoln;

            otherwise
                % case is experiment solution files
                defDir = iProg.DirComb;
        end
    else
        % otherwise, use the stored directory path
        defDir = sDir{iTab};
    end

    % prompts the user for the search directory
    sDirNw = uigetdir(defDir,'Select the root search directory');
    if sDirNw == 0
        % if the user cancelled, then exit
        return
    end
end

% deletes any existing tree objects
jTreeOld = findall(hPanel{iTab},'type','hgjavacomponent');
if ~isempty(jTreeOld); delete(jTreeOld); end

% creates the file tree structure in the panel
[jRootNw,sFileNw,jMovNw] = ...
                    setFileDirTree(hFig,hPanel{iTab},sDirNw,fExtn{iTab});    
if isempty(jRootNw)
    % if there was an error, then exit
    return   
end

% updates the object fields with the new objects/values
updateObjField(hFig,'sDir',sDirNw,iTab);
updateObjField(hFig,'jMov',jMovNw,iTab);
updateObjField(hFig,'jRoot',jRootNw,iTab);
updateObjField(hFig,'sFile',sFileNw,iTab);

% updates the file selection information
tableUpdateSel([],[],hFig)

% --- sets up the file directory tree structure
function [jRoot,mFile,hM] = setFileDirTree(hFig,hObj,sDir,fType)

% global variables
global sFile hMov 

% imports the checkbox tree
import com.mathworks.mwswing.checkboxtree.*

% other initialisations
dX = 10;
iTab = getappdata(hFig,'iTab');
    
% searches the batch processing movie directory for movies
sFile = findFileAllLocal(sDir,fType);
if isempty(sFile)        
%     % if there are no feasible files, then output an error to screen
%     eStr = 'Error! No candidate files detected from base search directory.';
%     waitfor(errordlg(eStr,'Invalid Directory Selection','modal'))
        
    % closes the loadbar and sets empty variables for the outputs
    [jRoot,mFile,hM] = deal([]);    
    return
else
    % retrieves the solution file information
    sInfo = getappdata(hFig,'sInfo');    
    if ~isempty(sInfo)        
        % if there is stored info, then reduce down the information to the
        % fields corresponding to the selected file type tab
        sInfo = sInfo(cellfun(@(x)(x.iTab==iTab),sInfo));
    end
        
    if ~isempty(sInfo)
        % removes the search files that are already loaded
        switch iTab
            case 1                
                % video solution files
                exDir = cellfun(@(x)(x.sFile),sInfo,'un',0);
                sFileD = cellfun(@(x)(fileparts(x)),sFile,'un',0);
                isKeep = ~any(cell2mat(cellfun...
                            (@(y)(strcmp(sFileD,y)),exDir(:)','un',0)),2);

            otherwise
                % experiment solution files
                exFile = cellfun(@(x)(x.sFile),sInfo,'un',0);
                isKeep = ~any(cell2mat(cellfun...
                            (@(x)(strcmp(sFile,x)),exFile(:)','un',0)),2);
        end
        
        % removes any of the files that are loaded
        sFile = sFile(isKeep);
    end
    
    % removes any infeasible solution file directories (soln file only)
    if iTab == 1    
        sFile = removeInfeasSolnDir(sFile);
    end
    
    % otherwise, determine the directory struct from the movies
    dirStr = detDirStructure(sDir,sFile);
    hMov = cell(length(sFile),1);
end    

% creates the root checkbox node
sDirT = getFinalDirString(sDir);

% sets up the root node (based on whether there are valid files)
if isempty(sFile)
    % case is there are no valid files
    jRoot = DefaultCheckBoxNode('No Valid Files Detected!');
else
    % sets up the directory trees structure
    jRoot = setSubDirTree(DefaultCheckBoxNode(sDirT),dirStr,sDirT);    
end

% retrieves the object position
objP = get(hObj,'position');

% Now present the CheckBoxTree:
jTree = com.mathworks.mwswing.MJTree(jRoot);
jTreeCB = handle(CheckBoxTree(jTree.getModel),'CallbackProperties');
jScrollPane = com.mathworks.mwswing.MJScrollPane(jTreeCB);

% creates the scrollpane object
wState = warning('off','all');
[~,~] = javacomponent(jScrollPane,[dX*[1 1],objP(3:4)-2*dX],hObj);
warning(wState);

% sets the callback function for the mouse clicking of the tree structure
set(jTreeCB,'MouseClickedCallback',{@tableUpdateSel,hFig})

% sets the output variables
if nargout > 1
    [mFile,hM] = deal(sFile,hMov);
end

% --- sets up the sub-directory tree for the directories in dirStr --- %
function jTree = setSubDirTree(jTree,dirStr,dirC)
 
% global variables
global sFile hMov

% imports the checkbox tree
import com.mathworks.mwswing.checkboxtree.*

% adds all the nodes for each of the sub-directories
for i = 1:length(dirStr.Names)    
    jTreeNw = DefaultCheckBoxNode(dirStr.Names{i});
    
    nodeStr = fullfile(dirC,dirStr.Names{i});
    jTreeNw = setSubDirTree(jTreeNw,dirStr.Dir(i),nodeStr);
    jTree.add(jTreeNw);                
end

% if there are any files detected, then add their names to the list
if ~isempty(dirStr.Files)
    for i = 1:length(dirStr.Files)                       
        % determines the matching movie file name
        fStr = fullfile(dirC,dirStr.Files{i});
        ii = find(cellfun(@(x)(strContains(x,fStr)),sFile));      
        
        % creates the new node
        [jTreeNw,hMov{ii}] = deal(DefaultCheckBoxNode(dirStr.Files{i}));
        jTree.add(jTreeNw)                    
    end        
end

% -------------------------------------- %
% --- EXPLORER TREE SEARCH FUNCTIONS --- %
% -------------------------------------- %

% --- finds all the finds
function fName = findFileAllLocal(snDir,fExtn)

% initialisations
[fFileAll,fName] = deal(dir(snDir),[]);

% determines the files that have the extension, fExtn
fFile = dir(fullfile(snDir,sprintf('*%s',fExtn)));
if ~isempty(fFile)
    fNameT = cellfun(@(x)(x.name),num2cell(fFile),'un',0);
    fName = cellfun(@(x)(fullfile(snDir,x)),fNameT,'un',0);    
end

%
isDir = find(cellfun(@(x)(x.isdir),num2cell(fFileAll)));
for j = 1:length(isDir)
    % if the sub-directory is valid, then search it for any files        
    i = isDir(j);
    if ~(strcmp(fFileAll(i).name,'.') || strcmp(fFileAll(i).name,'..'))        
        fDirNw = fullfile(snDir,fFileAll(i).name);        
        fNameNw = findFileAllLocal(fDirNw,fExtn);
        if ~isempty(fNameNw)
            % if there are any matches, then add them to the name array
            fName = [fName;fNameNw];
        end
    end
end

% --- sets up the directory tree structure from the movie files --- %
function dirStr = detDirStructure(sDir,movFile)

% sets the directory name separation string
if ispc; sStr = '\'; else sStr = '/'; end
if ~strcmp(sDir(end),sStr); sDir = [sDir,sStr]; end

% memory allocation
[dirStr,a] = deal(struct('Files',[],'Dir',[],'Names',[]));

% sets up the director tree structure for the selected movies
for i = 1:length(movFile)
    % sets the new directory sub-strings
    A = splitStringRegExpLocal(movFile{i}((length(sDir)+1):end),sStr);
    bStr = 'dirStr';
    for j = 1:length(A)                
        % appends the data to the struct
        if j == length(A)
            % appends the movie name to the list
            eval(sprintf('%s.Files = [%s.Files;A(end)];',bStr,bStr));
        else
            % if the sub-field does not exists, then create a new one
            if ~any(strcmp(eval(sprintf('%s.Names',bStr)),A{j}))            
                if isempty(eval(sprintf('%s.Dir',bStr)))
                    eval(sprintf('%s.Dir = a;',bStr));
                    eval(sprintf('%s.Names = A(j);',bStr));                    
                else
                    eval(sprintf('%s.Dir = [%s.Dir;a];',bStr,bStr));
                    eval(sprintf('%s.Names = [%s.Names;A(j)];',bStr,bStr));
                end
            end            
            
            % appends the new field to the data struct
            ii = find(strcmp(eval(sprintf('%s.Names',bStr)),A{j}));
            bStr = sprintf('%s.Dir(%i)',bStr,ii);
        end
    end
end

% --- splits up a string, Str, by its white spaces and returns the
%     constituent components in the cell array, sStr
function sStr = splitStringRegExpLocal(Str,sStr)

% ensures the string is not a cell array
if iscell(Str)
    Str = Str{1};
end

% determines the indices of the non-white regions in the string
if length(sStr) == 1
    if strcmp(sStr,'\') || strcmp(sStr,'/')  
        ind = strfind(Str,sStr)';
    else
        ind = regexp(Str,sprintf('[%s]',sStr))';
    end
else
    ind = regexp(Str,sprintf('[%s]',sStr))';
end

% calculates the indices of the non-contigious non-white space indices and
% determines the index bands that the strings belong to
indGrp = num2cell([[1;(ind+1)],[(ind-1);length(Str)]],2);

% sets the sub-strings
sStr = cellfun(@(x)(Str(x(1):x(2))),indGrp,'un',false);

% --------------------------------------- %
% --- EXPERIMENT INFO FIELD FUNCTIONS --- %
% --------------------------------------- %

% --- updates the experiment information fields
function updateGroupTableProps(handles)

% retrieves the solution file information struct (for the current expt)
hFig = handles.figOpenSoln;
iExp = getappdata(hFig,'iExp');
sInfo0 = getappdata(hFig,'sInfo');

% retrieves the 
sInfo = sInfo0{iExp};

% sets the experiment dependent fields
setObjEnable(handles.buttonShowProtocol,sInfo.hasStim);    

% resets the table background colours
bgCol = getTableBGColours(handles,sInfo);
set(handles.tableGroupNames,'BackgroundColor',bgCol)

% sets the table data/field property values
if sInfo.snTot.iMov.is2D
    % case is a 2D experiment    
    
    % sets the final data/column headers
    Data = [num2cell((1:length(sInfo.gName))'),sInfo.gName];
    cHdr = {'Group #','Group Name'};
    cWid = {70,150};
else
    % case is a 1D experiment    
    
    % sets the row/column index information
    pInfo = sInfo.snTot.iMov.pInfo;
    A = meshgrid(1:pInfo.nRow,1:pInfo.nCol);
    B = [A(:),arr2vec(A')];   
    
    % sets the final data/column headers
    Data = [num2cell(B),sInfo.gName(:)];
    cHdr = {'Row','Col','Group Name'};  
    cWid = {35,35,150};
end

% converts numerical values to strings
isN = cellfun(@isnumeric,Data);
Data(isN) = cellfun(@num2str,Data(isN),'un',0);

% sets the group name table properties
cEdit = setGroup(length(cHdr),size(cHdr));
set(handles.tableGroupNames,'Data',Data,'ColumnName',cHdr,...
                            'ColumnEditable',cEdit,'ColumnWidth',cWid)
setObjVisibility(handles.tableGroupNames,'on')
autoResizeTableColumns(handles.tableGroupNames)

% --- updates the solution file/added experiments array
function updateExptInfoTable(handles)

% global variables
global tableUpdate

% object retrieval
hFig = handles.figOpenSoln;
sInfo = getappdata(hFig,'sInfo');
jTable = getappdata(hFig,'jTable');
tabCR1 = getappdata(hFig,'tabCR1');
tabCR2 = getappdata(hFig,'tabCR2');
nExpMax = getappdata(hFig,'nExpMax');

% other initialisations
nExp = length(sInfo);
jTableMod = jTable.getModel;
grayCol = getJavaColour(0.81*ones(1,3));

% flag that the table is updating
tableUpdate = true;

% removes the table selection
jTable.changeSelection(-1,-1,false,false);

% adds data to the table
for i = 1:nExp
    % adds in the data for the new table row and the bg colour index
    tabData = getExptTableRow(sInfo{i});
    
    if i > jTable.getRowCount
        jTableMod.addRow(tabData)
        for j = 1:jTable.getColumnCount
            % sets the background colours
            tabCR1.setCellBgColor(i-1,j-1,grayCol);
            tabCR2.setCellBgColor(i-1,j-1,grayCol);        

            % sets the foreground colours
            tabCR1.setCellFgColor(i-1,j-1,java.awt.Color.black);
            tabCR2.setCellFgColor(i-1,j-1,java.awt.Color.black);            
        end
    else
        % updates the table values
        for j = 1:jTable.getColumnCount
            jTable.setValueAt(java.lang.String(tabData{j}),i-1,j-1)                         
        end        
    end
end

% resets the column widths
mStr = resetExptTableBGColour(hFig,1);
resetColumnWidths(handles)

% repaints the table
jTable.repaint();

% flag that the table update is complete
pause(0.05)
tableUpdate = false;

% outputs any message to screen (if they exist)
if ~isempty(mStr)            
    waitfor(msgbox(mStr,'Repeated File Names','modal'))
end

% --- retrieves the experiment information table data
function tabData = getTableData(hFig)

% initialisations
sInfo = getappdata(hFig,'sInfo');
tabData = cell(length(sInfo),1);

% reads the data for each table row
for i = 1:length(tabData)
    tabData{i} = getExptTableRow(sInfo{i});
end

% converts the data into a cell array
tabData = cell2cell(tabData);

% --- retrieves the experiment table row data
function rowData = getExptTableRow(sInfo)

% initialisations
pFileStr = 'N/A';
exStr = {'1D','2D'};
typeStr = {'soln','ssol','msol'};
 
% sets the solution file type strings/fields
switch sInfo.iTab
    case 3
        % case is data from a multi-expt file
        pFileStr = getFileName(sInfo.sFile);
        
end

% sets up the stimuli string
if sInfo.hasStim
    % case is the experiment has stimuli
    devStr = fieldnames(sInfo.snTot.stimP);
    stimStr = sprintf('%s',strjoin(devStr,'/'));
else
    % case is the experiment has no stimuli
    stimStr = 'No Stimuli';
end

% sets the 
rowData = cell(1,6);
rowData{1} = sInfo.expFile;
rowData{2} = pFileStr;
rowData{3} = typeStr{sInfo.iTab};
rowData{4} = exStr{1+sInfo.is2D};
rowData{5} = stimStr;
rowData{6} = sInfo.tDurS;

% --- resets the experiment information table background colour
function mStr = resetExptTableBGColour(hFig,isLoading)

% determines the unique experiment name indices
[iGrpU,mStr] = detUniqueNameIndices(hFig,isLoading);

% resets the table background colours
for i = 1:length(iGrpU)
    if i == 1
        rwCol = getJavaColour([0.75,1,0.75]);
    else
        rwCol = getJavaColour([1,0.75,0.75]);
    end
    
    % sets the colour for all matching experiments in the group
    for j = iGrpU{i}(:)'
        setExptTableRowColour(hFig,j,rwCol)
    end
end

% --- updates the table background row colour
function setExptTableRowColour(hFig,iRow,rwCol)

% object retrieval
jTable = getappdata(hFig,'jTable');
tabCR1 = getappdata(hFig,'tabCR1');
tabCR2 = getappdata(hFig,'tabCR2');

% sets the experiment colour
tabCR1.setCellBgColor(iRow-1,0,rwCol);

% sets the other column colours
for iCol = 2:jTable.getColumnCount
    tabCR2.setCellBgColor(iRow-1,iCol-1,rwCol)
end

% --- clears the information on a table row
function clearExptInfoTableRow(hFig,iRow)

% object retrieval
jTable = getappdata(hFig,'jTable');
tabCR1 = getappdata(hFig,'tabCR1');
tabCR2 = getappdata(hFig,'tabCR2');

% other initialisations
grayCol = getJavaColour(0.81*ones(1,3));

% resets the cells in the table row
for j = 1:jTable.getColumnCount
    % removes the value in the cell
    jTable.setValueAt([],iRow-1,j-1)

    % resets the cell background colour
    if j == 1
        tabCR1.setCellBgColor(iRow-1,j-1,grayCol)
    else
        tabCR2.setCellBgColor(iRow-1,j-1,grayCol)
    end
end

% --- resets the column widths
function resetColumnWidths(handles)

% parameters
hFig = handles.figOpenSoln;
jTable = getappdata(hFig,'jTable');
nExpMax = getappdata(hFig,'nExpMax');

% other intialisations
cWid = [176,50,55,60,60,60,78];
if jTable.getRowCount > nExpMax
    % other intialisations
    cWid = (cWid - 20/length(cWid));
end

for cID = 1:jTable.getColumnCount
    cMdl = jTable.getColumnModel.getColumn(cID-1);
    cMdl.setMinWidth(cWid(cID))
end

% -------------------------------------- %
% --- SOLUTION DATA UPDATE FUNCTIONS --- %
% -------------------------------------- %

% --- appends the new solution information 
function appendSolnInfo(hFig,snTot,iTab,sFile,expFile)

% memory allocation
sInfo = getappdata(hFig,'sInfo');
sInfoNw = {struct('snTot',[],'sFile',[],'iFile',1,'iTab',iTab,'iID',[],...
                  'iPara',[],'gName',[],'expFile',[],'expInfo',[],...
                  'is2D',false,'hasStim',false,'tDurS',[],'tDur',[])};
              
% determines the index of the next available ID flag
iIDnw = getNextSolnIndex(sInfo);
              
% updates the solution information (based on the file type)
switch iTab
    case {1,2}
        % case is the video/single experiment file
        sInfoNw{1}.snTot = snTot;
        sInfoNw{1}.sFile = sFile;
        sInfoNw{1}.iID = iIDnw;
        
        % sets the experiment file name
        if iTab == 1
            sInfoNw{1}.expFile = getFinalDirString(sFile);
        else
            sInfoNw{1}.expFile = getFileName(sFile);
        end
        
    case 3
        % case is the multi-experiment files
        nFile = length(snTot);
        sInfoNw = repmat(sInfoNw,nFile,1);
        
        % retrieves the information for each of the solution files
        for i = 1:nFile
            sInfoNw{i}.snTot = snTot(i);
            sInfoNw{i}.sFile = sFile;
            sInfoNw{i}.expFile = expFile{i};
            sInfoNw{i}.iID = iIDnw+(i-1);
        end
end

% calculates the signal duration
for i = 1:length(sInfoNw)
    % sets the expt field/stimuli fields
    sInfoNw{i}.is2D = sInfoNw{i}.snTot.iMov.is2D;
    sInfoNw{i}.hasStim = ~isempty(sInfoNw{i}.snTot.stimP);
    
    % sets the experiment duration in seconds
    sInfoNw{i}.tDur = ceil(sInfoNw{i}.snTot.T{end}(end));
    
    % sets the duration string
    s = seconds(sInfoNw{i}.tDur); 
    s.Format = 'dd:hh:mm:ss';
    sInfoNw{i}.tDurS = char(s);
    
    % initialises the timing parameter struct
    sInfoNw{i}.iPara = initParaStruct(sInfoNw{i}.snTot);
    sInfoNw{i}.gName = getRegionGroupNames(sInfoNw{i}.snTot);
    sInfoNw{i}.expInfo = initExptInfo(sInfoNw{i});   
    sInfoNw{i}.snTot.iMov.ok = ~strcmp(sInfoNw{i}.gName,'* REJECTED *');
end

% udpates the solution info data struct
setappdata(hFig,'sInfo',[sInfo;sInfoNw(:)])

% --- initialises the parameter struct
function iPara = initParaStruct(snTot)

% initialises the parameter struct
nVid = length(snTot.T);
iPara = struct('iApp',1,'indS',[],'indF',[],...
               'Ts',[],'Tf',[],'Ts0',[],'Tf0',[]);
               
% sets the start/finish indices (wrt the videos)                
T0 = snTot.iExpt(1).Timing.T0;
iPara.indS = [1 1];
iPara.indF = [nVid length(snTot.T{end})];

% sets the start/finish times
[iPara.Ts,iPara.Ts0] = deal(calcTimeString(T0,snTot.T{1}(1)));
[iPara.Tf,iPara.Tf0] = deal(calcTimeString(T0,snTot.T{end}(end)));

% --- initialises the solution file information --- %
function expInfo = initExptInfo(sInfo)

% retrieves the solution data struct
snTot = sInfo.snTot;
iMov = snTot.iMov;
    
% sets the experimental case string
switch snTot.iExpt.Info.Type
    case {'RecordStim','StimRecord'}
        eCase = 'Recording & Stimulus';        
    case ('RecordOnly')
        eCase = 'Recording Only';
    case ('StimOnly')
        eCase = 'Stimuli Only';        
    case ('RTTrack')
        eCase = 'Real-Time Tracking';
end
    
% updates the solution information (based on the file type)
sName = sInfo.expFile;
switch sInfo.iTab
    case {1,2}
        % case is the video/single experiment file
        if sInfo.iTab == 1
            sDirTT = sInfo.sFile;
        else
            sDirTT = fileparts(sInfo.sFile);
        end
        
    case 3
        % case is the multi-experiment files
        sDirTT = fileparts(sInfo.sFile);
end

% calculates the experiment duration (rounded to the nearest minute)
dT = roundP((snTot.T{end}(end)-snTot.T{1}(1))/60,1)*60;
[~,~,Tstr] = calcTimeDifference(dT);

% calculates the experiment count/duration strings
nExpt = num2str(length(snTot.T));
TstrTot = sprintf('%s Days, %s Hours, %s Mins',Tstr{1},Tstr{2},Tstr{3});
T0vec = calcTimeString(snTot.iExpt.Timing.T0,0);
Tfvec = calcTimeString(snTot.iExpt.Timing.T0,snTot.T{end}(end));
txtStart = datestr(sInfo.iPara.Ts0,'mmm dd, YYYY HH:MM AM');
txtFinish = datestr(sInfo.iPara.Tf0,'mmm dd, YYYY HH:MM AM');

% sets the expt setup dependent fields
if iMov.is2D
    % case is a 2D experiment
    switch iMov.autoP.Type
        case 'Circle'
            setupType = 'Circle';
        case 'GeneralR'
            setupType = 'General Repeating';            
        case 'GeneralC'
            setupType = 'General Custom';
    end
    
    % sets the full string
    exptStr = sprintf('2D Grid Assay (%s Regions)',setupType);
    regConfig = sprintf('%i x %i Grid Assay',size(iMov.flyok,1),iMov.nCol);
else
    % sets the experiment string
    exptStr = '1D Test-Tube Assay';
    regConfig = sprintf('%i x %i Assay (Max Count = %i)',...
                    iMov.pInfo.nRow,iMov.pInfo.nCol,iMov.pInfo.nFlyMx);
end

% sets the experiment information fields
expInfo = struct('ExptType',eCase,'ExptDur',TstrTot,...
                 'SolnDur',TstrTot,'SolnCount',nExpt,...
                 'SetupType',exptStr,'RegionConfig',regConfig,'dT',dT,...
                 'StartTime',txtStart,'FinishTime',txtFinish,...
                 'SolnDir',sName,'SolnDirTT',sDirTT,...
                 'T0vec',T0vec,'Tfvec',Tfvec);          
             
% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- retrieves the table background colours
function [bgCol,iGrpNw] = getTableBGColours(handles,sInfo)

% sets the default input arguments (if not provided)
if ~exist('sInfo','var')
    sInfo = getCurrentExptInfo(handles.figOpenSoln);
end

% retrieves the unique group names from the list
grayCol = 0.81;
[gName,~,iGrpNw] = unique(sInfo.gName,'stable');
isOK = sInfo.snTot.iMov.ok & ~strcmp(sInfo.gName,'* REJECTED *');

% sets the background colour based on the matches within the unique list
tCol = getAllGroupColours(length(gName),1);
bgCol = tCol(iGrpNw,:);
bgCol(~isOK,:) = grayCol;

% --- updates storage object field within the GUI
function updateObjField(hFig,pStr,Pnw,iTab)

% updates the array within the figure
P = getappdata(hFig,pStr);
P{iTab} = Pnw;
setappdata(hFig,pStr,P);

% --- group the selected files by their unique directories
function [fDirS,fNameS] = groupSelectedFiles(sFile)

% retrieves the file directory/name strings
fDir0 = cellfun(@(x)(fileparts(x)),sFile,'un',0);
fName0 = cellfun(@(x)(getFileName(x,1)),sFile,'un',0);

% groups the file names/directories into their unique groups
[fDirS,~,iC] = unique(fDir0);
fNameS = arrayfun(@(x)(fName0(iC==x)),1:max(iC),'un',0);

% --- resets the storage arrays within the GUI
function resetStorageArrays(hFig)

% parameters
nTab = 3;

% resets the solution information struct
setappdata(hFig,'sInfo',[]);

% initialises the other array objects 
setappdata(hFig,'jMov',cell(nTab,1)) 
setappdata(hFig,'jRoot',cell(nTab,1)) 
setappdata(hFig,'jTree',cell(nTab,1)) 
setappdata(hFig,'sFile',cell(nTab,1))

% --- determines the next solution file index
function iIDnw = getNextSolnIndex(sInfo)

if isempty(sInfo)
    % there is no stored data, so start index at 1
    iIDnw = 1;
else
    % case is there is stored data, so increment the max ID flag
    iIDnw = max(cellfun(@(x)(x.iID),sInfo)) + 1;
end

% removes any infeasible solution file directories
function sFile = removeInfeasSolnDir(sFile)

%
fDir0 = cellfun(@(x)(fileparts(x)),sFile,'un',0);
[fDir,~,iC] = unique(fDir0);

% determines the number of Summary files in each directory
nSumm = cellfun(@(x)(length(dir(fullfile(x,'Summary.mat')))),fDir);
sFileD = arrayfun(@(x)(sFile(iC==x)),(1:max(iC))','un',0);

% loops through all the feasible directories (folders with only 1 Summary
% file) determining if the multi-files expts are named correctly
isOK = nSumm == 1;
for i = find(nSumm(:)' == 1)
    if length(sFileD{i}) > 1
        % retrieves the file names of the files in the directory
        fName = cellfun(@(x)(getFileName(x)),sFileD{i},'un',0);
        
        % ensures that the files have a consistent naming convention
        smData = load(fullfile(fDir{i},'Summary.mat'));
        bStr = smData.iExpt.Info.BaseName;
        isOK(i) = all(cellfun(@(x)(startsWith(x,bStr)),fName));
    end
end
    
% removes the infeasible directories
sFile = cell2cell(sFileD(isOK));

% --- determines the unique name groupings from the experiment name list
function [iGrpU,mStr] = detUniqueNameIndices(hFig,isLoading)

%
mStr = [];
sInfo = getappdata(hFig,'sInfo');
expFile = cellfun(@(x)(x.expFile),sInfo,'un',0);

% determines the unique experiment file names
[expFileU,~,iC] = unique(expFile,'stable');
if length(expFileU) < length(expFile)
    % case is there are repeated experiment names   
    iGrp0 = arrayfun(@(x)(find(iC==x)),(1:max(iC))','un',0);
    
    % determines the repeat experiment file names
    ii = cellfun(@length,iGrp0) == 1;
    expFileR = expFileU(~ii);
    iGrpU = [cell2mat(iGrp0(ii));iGrp0(~ii)];    
    
    % if loading the files, output a message to screen
    if isLoading
        % sets the message string
        mStr = sprintf(['The following experiment names from the ',...
                        'loaded solution files are repeated:\n\n']); 
        for i = 1:length(expFileR)
            mStr = sprintf('%s %s "%s"\n',mStr,char(8594),expFileR{i});
        end          
        mStr = sprintf(['%s\nYou will need to alter these file names ',...
                        'before finishing loading the data.'],mStr);                            
    end    
else
    iGrpU = {1:length(sInfo)};
end
