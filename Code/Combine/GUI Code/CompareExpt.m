function varargout = CompareExpt(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CompareExpt_OpeningFcn, ...
                   'gui_OutputFcn',  @CompareExpt_OutputFcn, ...
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

% --- Executes just before CompareExpt is made visible.
function CompareExpt_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global tableUpdate
tableUpdate = false;

% Choose default command line output for CompareExpt
handles.output = hObject;

% sets the input arguments
hFigM = varargin{1};

% sets the input arguments
setappdata(hObject,'hFigM',hFigM);
setappdata(hObject,'isChange',false);
setappdata(hObject,'sInfo',getappdata(hFigM,'sInfo'));
setappdata(hObject,'iProg',getappdata(hFigM,'iProg'));

% initialises the object properties
initObjProps(handles)

% centres the gui figure
centreFigPosition(hObject,1,0)
set(hObject,'CloseRequestFcn',{@figCompExpt_CloseRequestFcn,handles});

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes CompareExpt wait for user response (see UIRESUME)
% uiwait(handles.figCompExpt);

% --- Outputs from this function are returned to the command line.
function varargout = CompareExpt_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when user attempts to close figCompExpt.
function figCompExpt_CloseRequestFcn(hObject, eventdata, handles)

% Hint: delete(hObject) closes the figure
buttonCancel_Callback(handles.buttonCancel, [], handles)

%-------------------------------------------------------------------------%
%                        OBJECT CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ------------------------------------ %
% --- TAB GROUP CALLBACK FUNCTIONS --- %
% ------------------------------------ %

% --- callback function for selecting the experiment info tabs
function tabSelectedGrp(hObj,eventdata,handles,indG)

% object retrieval
hFig = handles.figCompExpt;
hTabGrpL = get(hObj,'Parent');
sInfo = getappdata(hFig,'sInfo');
hTabGrpI = getappdata(hFig,'hTabGrpI');
iTab = get(hObj,'UserData');

% determines the compatible experiment info
if ~exist('indG','var')
    cObj = getappdata(hFig,'cmpObj');
    indG = cObj.detCompatibleExpts(); 
end

% resets the listbox parent object
hList = findall(hTabGrpL,'tag','hGrpList');
iSel = get(hList,'Value');
lStr = cellfun(@(x)(x.expFile),sInfo(indG{iTab}),'un',0);

% resets the panel information
resetExptInfo(handles,indG{iTab}(1))
if isempty(iSel); iSel = -1; end

% if the selection index is now invalid, the remove the listbox selection
if iSel > length(lStr)        
    % removes the listbox selection
    set(hList,'Max',2,'Value',[]); 
    
    % ensures the experiment comparison tab is selected
    hTabI = get(hTabGrpI,'SelectedTab');
    if get(hTabI,'UserData') > 1
        set(hTabGrpI,'SelectedTab',findall(hTabGrpI,'UserData',1))
    end    
    
    % disables the group name 
    jTabGrpI = getappdata(hFig,'jTabGrpI');
    jTabGrpI.setEnabledAt(1,0);
else
    % otherwise, update the table group names
	updateTableGroupNames(handles)    
end

% updates the list strings
set(hList,'Parent',hObj,'String',lStr(:));

% --- callback function for selecting the experiment info tabs
function tabSelectedInfo(hObj,eventdata,handles)

% FINISH ME?!
a = 1;

% ----------------------------------- %
% --- EXPT COMPARISON TAB OBJECTS --- %
% ----------------------------------- %

% --- table cell update callback function
function tableCellChange(hTable,evnt,handles)

% global variables
global tableUpdate

% if the table is updating automatically, then exit
if tableUpdate; return; end

% field retrieval
hFig = handles.figCompExpt;
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
if strcmp(nwStr,tabData{iRow+1,iCol+1})
    return
end

% determines if the experiment name has been updated
if iCol == 0
    % case is the experiment name is being updated
    nwStr = jTable.getValueAt(iRow,iCol);
    iExp = getCurrentExpt(hFig);
    
    % checks to see if the new experiment name is valid
    if checkNewExptName(sInfo,nwStr,iExp)
        % if so, then update the 
        cObj = getappdata(hFig,'cmpObj');
        cObj.expData(iRow+1,1,:) = {nwStr};   
        setappdata(hFig,'cmpObj',cObj)
        
        % updates the experiment name and change flag
        sInfo{iRow+1}.expFile = nwStr;
        setappdata(hFig,'sInfo',sInfo)
        setappdata(hFig,'isChange',true);
        
        % resets the group lists
        updateGroupLists(handles)
        
        % exits the function        
        return
    end
end

% if not, then resets the table cell back to the original value    
tableUpdate = true;
jTable.setValueAt(tabData{iRow+1,iCol+1},iRow,iCol);
tableUpdate = false;

% --- callback function for updating a criteria checkbox value
function checkUpdate(hObject, eventdata, handles)

% object retrieval
hFig = handles.figCompExpt;

% updates the criteria checkbox values
cObj = getappdata(hFig,'cmpObj');
cObj.setCritCheck(get(hObject,'UserData'),get(hObject,'Value'))

% resets the final group name arrays
resetFinalGroupNameArrays(hFig)

% object retrieval
updateGroupLists(handles);

% --- callback function for editing editMaxDiff
function editMaxDiff_Callback(hObject, eventdata, handles)

% object retrieval
hFig = handles.figCompExpt;
cObj = getappdata(hFig,'cmpObj');
nwVal = str2double(get(hObject,'String'));

% determines if the new value is valid
if chkEditValue(nwVal,[1,100],0)
    % if so, update the parameter struct
    cObj.setParaValue('pDur',nwVal);
    
    % updates compatibility flags
    cObj.calcCompatibilityFlags(5);
    
    % resets the final group name arrays
    resetFinalGroupNameArrays(hFig)    
    
    % updates the group lists
    updateGroupLists(handles)
else
    % otherwise, revert back to the last valid value
    set(hObject,'String',num2str(cObj.getParaValue('pDur')));
end

% ------------------------------ %
% --- GROUP NAME TAB OBJECTS --- %
% ------------------------------ %

% --- Executes on button press in buttonMoveUp.
function buttonMoveUp_Callback(hObject, eventdata, handles)

%
hFig = handles.figCompExpt;
hTable = handles.tableFinalNames;
nRow = getappdata(hFig,'nRow');
gNameU = getappdata(hFig,'gNameU');
hTabGrpL = getappdata(hFig,'hTabGrpL');

% determines the currently selected name row and group index
[iRow,~] = getTableCellSelection(hTable);
iTabG = get(get(hTabGrpL,'SelectedTab'),'UserData');

% permutes the group name array and updates within the gui
indP = [(1:iRow-2),iRow+[0,-1],(iRow+1):length(gNameU{iTabG})];
gNameU{iTabG} = gNameU{iTabG}(indP);
setappdata(hFig,'gNameU',gNameU);

% updates the table and the 
set(hTable,'Data',expandCellArray(gNameU{iTabG},nRow));
setObjEnable(hObject,iRow>2);
setTableSelection(hTable,iRow-2,0)

% resets the group lists
updateGroupLists(handles)

% --- Executes on button press in buttonMoveDown.
function buttonMoveDown_Callback(hObject, eventdata, handles)

%
hFig = handles.figCompExpt;
hTable = handles.tableFinalNames;
nRow = getappdata(hFig,'nRow');
gNameU = getappdata(hFig,'gNameU');
hTabGrpL = getappdata(hFig,'hTabGrpL');

% determines the currently selected name row and group index
[iRow,~] = getTableCellSelection(hTable);
iTabG = get(get(hTabGrpL,'SelectedTab'),'UserData');

% permutes the group name array and updates within the gui
indP = [(1:iRow-1),iRow+[1,0],(iRow+2):length(gNameU{iTabG})];
gNameU{iTabG} = gNameU{iTabG}(indP);
setappdata(hFig,'gNameU',gNameU);

% updates the table and the 
set(hTable,'Data',expandCellArray(gNameU{iTabG},nRow));
setObjEnable(hObject,(iRow+1)<length(gNameU{iTabG}));
setTableSelection(hTable,iRow,0)

% resets the group lists
updateGroupLists(handles)

% --- Executes when entered data in editable cell(s) in tableFinalNames.
function tableFinalNames_CellEditCallback(hObject, eventdata, handles)

% initislisations
ok = true;

% object retrieval
hFig = handles.figCompExpt;
cObj = getappdata(hFig,'cmpObj');
gName = getappdata(hFig,'gName');
gNameU = getappdata(hFig,'gNameU');
hTabGrpL = getappdata(hFig,'hTabGrpL');
[tabData,tabData0] = deal(get(hObject,'Data'));

% retrieves the new input parameters
iRow = eventdata.Indices(1);
prStr = eventdata.PreviousData;
nwStr = strtrim(eventdata.NewData);

% determines the currently selected experiment
indG = cObj.detCompatibleExpts();
iTabG = get(get(hTabGrpL,'SelectedTab'),'UserData');

% removes the table selection
removeTableSelection(hObject)

% determines the index of the first empty group name cell
if isempty(prStr)
    tabData0{iRow} = ' ';
else
    tabData0{iRow} = prStr;
end

% determines if there is a gap in the group name list
indE = find(strcmp(tabData0,' '),1,'first');
if iRow > indE
    % if there is a gap in the group name list, then output an error
    ok = false;
    mStr = 'There cannot be an empty rows within the final group names.';    
elseif iRow == indE
    % case is a new name is being added
    if any(strcmp(tabData(1:indE-1),nwStr))
        % if the new name is not unique, then flag an error
        ok = false;
        mStr = sprintf(['The group name "%s" already exists in ',...
                        'group list.'],nwStr);
    else
        % otherwise, append on the new name to the unique name list
        gNameU{iTabG}{end+1} = nwStr;
    end
else
    % sets the indices of the experiments to be updated
    iEx = indG{iTabG};
    
    % determines if the new name is unique
    if any(strcmp(tabData0,nwStr))
        % if not, then prompt the user
        qStr = sprintf(['The group name "%s" already exists in ',...
                        'group list.\nAre you sure you want ',...
                        'to combine these two groups?'],nwStr);        
        uChoice = questdlg(qStr,'Combine Groupings?','Yes','No','Yes');
        if ~strcmp(uChoice,'Yes')
            % if the user chose not to update, then flag a reset
            ok = false;
        else
            % updates the final/linking group names    
            gNameU{iTabG}{iRow} = nwStr;
            gName(iEx) = resetGroupNames(gName(iEx),nwStr,prStr);
            
            % reduces down the final names
            gNameU{iTabG} = unique(gNameU{iTabG},'stable');
        end
    else
        % otherwise, update the final/linking group names
        if isempty(nwStr)
            % if the string is empty, then remove it from the name list
            B = ~setGroup(iRow,size(gNameU{iTabG}));
            gNameU{iTabG} = gNameU{iTabG}(B);
        else
            % otherwise, update the name list
            gNameU{iTabG}{iRow} = nwStr;
        end
        
        % updates the linking group names
        gName(iEx) = resetGroupNames(gName(iEx),nwStr,prStr);
    end    
end
    
% determines if a feasible name was added to the name list
if ok
    % updates the flags/arrays    
    setappdata(hFig,'gName',gName)
    setappdata(hFig,'gNameU',gNameU)
    setappdata(hFig,'isChange',true)
    
    % resets the group lists
    updateGroupLists(handles)
else
    % outputs the error message to screen (if there is an error message)
    if exist('mStr','var')
        waitfor(msgbox(mStr,'Group Name Error','modal'))
    end
    
    % resets the table cell and exits the function
    tabData{iRow} = ' ';
    set(hObject,'Data',tabData);
    return
end

% --- Executes when selected cell(s) is changed in tableFinalNames.
function tableFinalNames_CellSelectionCallback(hObject, eventdata, handles)

% if there are no indices provided, then exit
if isempty(eventdata.Indices); return; end

% object retrieval
hFig = handles.figCompExpt;
gNameU = getappdata(hFig,'gNameU');
hTabGrpL = getappdata(hFig,'hTabGrpL');

% determines the number of group names
iRow = eventdata.Indices(1);
iTabG = get(get(hTabGrpL,'SelectedTab'),'UserData');
nName = length(gNameU{iTabG});

% updates the move up/down button enabled properties
isOn = [iRow>1,iRow<nName] & (iRow <= nName);
setObjEnable(handles.buttonMoveUp,isOn(1))
setObjEnable(handles.buttonMoveDown,isOn(2))

% --- Executes when entered data in editable cell(s) in tableLinkName.
function tableLinkName_CellEditCallback(hObject, eventdata, handles)

% object retrieval
hFig = handles.figCompExpt;
iExp = getappdata(hFig,'iExp');
gName = getappdata(hFig,'gName');

% other initialisations
regStr = '* REJECTED *';
iRow = eventdata.Indices(1);
tabData = get(hObject,'Data');

% determines if the new selection is feasible
if iRow > length(gName{iExp}) || strcmp(tabData{iRow,1},regStr)
    % if the row selection is greater than the group count, then reset
    tabData{iRow,2} = ' ';
    set(hObject,'Data',tabData);            
else
    % otherwise, update the group name for the experiment
    gName{iExp}{iRow} = eventdata.NewData;
    setappdata(hFig,'gName',gName);
    
    % removes the table selection
    removeTableSelection(hObject);
    
    % updates the background colours of the altered cell
    tCol = getappdata(hFig,'tCol');
    tabDataN = get(handles.tableFinalNames,'Data');
    cFormN = [{' '};tabDataN(~strcmp(tabDataN,' '))];
    bgColL = cellfun(@(x)(tCol{strcmp(cFormN,x)}),tabData(:,2),'un',0);
    set(hObject,'BackgroundColor',cell2mat(bgColL))      
end

% ------------------------------ %
% --- FILE CHOOSER CALLBACKS --- %
% ------------------------------ %

% --- callback function for the file chooser property change
function chooserPropChange(hObject, eventdata, handles)

% initialisations
hFig = handles.figCompExpt;
% iExp = getappdata(hFig,'iExp');
% fExtn = getappdata(hFig,'fExtn');
objChng = eventdata.getNewValue;

switch class(objChng)
    case 'sun.awt.shell.Win32ShellFolder2'
        % FINISH ME!
        a = 1;
        
%         % case is the folder change
%         fDir = char(objChng.getPath);
%         [~,fName,~] = fileparts(char(objChng.getName));
%         
%         % updates the file name        
%         setappdata(hFig,'fDir',fDir)
%         setappdata(hFig,'fName',fName)
end

% --- updates when the file name is changed
function saveFileNameChng(hObject, eventdata, handles)

% enables the create button enabled properties (disable if no file name)
fName = char(get(hObject,'Text'));
setObjEnable(handles.buttonCreate,~isempty(fName))

% -------------------------------- %
% --- CONTROL BUTTON CALLBACKS --- %
% -------------------------------- %

% --- Executes on button press in buttonCreate.
function buttonCreate_Callback(hObject, eventdata, handles)


% --- Executes on button press in buttonCancel.
function buttonCancel_Callback(hObject, eventdata, handles)

% initialisations
hFig = handles.figCompExpt;

% determines if the user made a change 
if getappdata(hFig,'isChange')
    % if there was a change, then prompt the user if they wish to update
    qStr = 'Do you want to update the changes you have made?';
    uChoice = questdlg(qStr,'Update Changes?','Yes','No','Cancel','Yes');    
    switch uChoice
        case 'Yes'
            % case is the user chose to update
            hFigM = getappdata(hFig,'hFigM');
            setappdata(hFigM,'sInfo',getappdata(hFig,'sInfo'));
            
        case 'Cancel'
            % case is the user cancelled
            return
    end
end

% deletes the GUI
delete(hFig);

% -------------------------------- %
% --- OTHER CALLBACK FUNCTIONS --- %
% -------------------------------- %

% --- list selection callback function
function listSelect(hObject, eventdata, handles)

% object retrieval
hFig = handles.figCompExpt;
hTabGrpI = getappdata(hFig,'hTabGrpI');
jTabGrpI = getappdata(hFig,'jTabGrpI');

% if the group name tab is not selected, then make sure it is selected
hTabI = get(hTabGrpI,'SelectedTab');
if get(hTabI,'UserData') ~= 2
    jTabGrpI.setEnabledAt(1,1);
    set(hTabGrpI,'SelectedTab',findall(hTabGrpI,'UserData',2))
end

% resets the selection mode to single selection
set(hObject,'max',1)

% updates the table group names
updateTableGroupNames(handles)

% --- updates the final/linking table group names
function updateTableGroupNames(handles)

% parameters
rejStr = '* REJECTED *';

% object retrieval
hFig = handles.figCompExpt;
nRow = getappdata(hFig,'nRow');
cObj = getappdata(hFig,'cmpObj');
gName = getappdata(hFig,'gName');
gName0 = getappdata(hFig,'gName0');
gNameU = getappdata(hFig,'gNameU');
hTabGrpL = getappdata(hFig,'hTabGrpL');

% other objects
hTableN = handles.tableFinalNames;
hTableL = handles.tableLinkName;
hList = findall(hFig,'tag','hGrpList');
iSelG = get(hList,'Value');

% determines the currently selected experiment
indG = cObj.detCompatibleExpts();
iTabG = get(get(hTabGrpL,'SelectedTab'),'UserData');

% sets the experiment index
if isempty(iSelG)
    % if there is no selection, then use the first experiment
    iExp = indG{iTabG}(1);
else
    iExp = indG{iTabG}(iSelG);
end

% sets update the group colour arrays
tCol = num2cell(getAllGroupColours(length(gNameU{iTabG})),2);

% sets up the final name table data/background colours
DataN = expandCellArray(gNameU{iTabG},nRow);
bgColN = expandCellArray(tCol(2:end),nRow,tCol{1});

% adds an additional row to the table (if more space is required)
if size(DataN,1) > nRow
    [DataN,bgColN] = deal([DataN;{' '}],[bgColN;tCol(1)]);
end

% updates the final name table data/properties
set(hTableN,'Data',DataN,'BackgroundColor',cell2mat(bgColN));

% expands the cell array
DataL = expandCellArray([gName0{iExp}(:),gName{iExp}(:)],nRow);

% updates the group name link table data/properties
cFormN = [{' '},gNameU{iTabG}(:)'];
isRej = strcmp(DataL(:,1),rejStr);
DataL(isRej,2) = {' '};
bgColL = cellfun(@(x)(tCol{strcmp(cFormN,x)}),DataL(:,2),'un',0);
set(hTableL,'Data',DataL,'ColumnFormat',{'char',cFormN},...
            'BackgroundColor',cell2mat(bgColL(:)));

% sets the experiment index
setappdata(hFig,'iExp',iExp)
setappdata(hFig,'tCol',tCol)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the GUI object properties
function initObjProps(handles)

% global variables
global H0T HWT mainProgDir

% parameters
dX = 5;
dYP = 25;
bHght = 25;
nExpMax = 10;

% object retrieval
hFig = handles.figCompExpt;
hPanelF = handles.panelFileInfo;
hPanelGrp = handles.panelGroupingInfo;
hPanelGrpL = handles.panelGroupLists;
hPanelGrpC = handles.panelGroupingCrit;

% memory allocation and other initialisations
sInfo = getappdata(hFig,'sInfo');
nExp = length(sInfo);

% creates the experiment comparison object
cmpObj = ExptCompObj(hFig);
setappdata(hFig,'cmpObj',cmpObj);

% ------------------------------------------- %
% --- EXPERIMENT INFORMATION OBJECT SETUP --- %
% ------------------------------------------- %

% object retrieval
hTableT = handles.tableExptInfo;
hPanelInfo = handles.panelInfoTotal;
hPanelInfoN = handles.panelGroupNames;
hPanelInfoEx = handles.panelExptComp;

% calculates the new table height
pPosEx0 = get(hPanelInfoEx,'Position');
tblHght = calcTableHeight(min(nExpMax,nExp)) + H0T - 5;
hghtNew = tblHght + 2*dX;

% other intialisations
cWid = [176,50,55,60,60,60,78];
if nExp > nExpMax
    % other intialisations
    cWid = (cWid - 20/length(cWid));
end

% updates the height of the experiment comparison panel
resetObjPos(hPanelInfoEx,'height',hghtNew);
resetObjPos(hTableT,'height',tblHght);
resetObjPos(hTableT,'bottom',dX);

% resets the height of 
dHght = hghtNew-pPosEx0(4);
resetObjPos(hFig,'height',dHght,1)
resetObjPos(hPanelF,'height',dHght,1)
resetObjPos(hPanelInfo,'height',dHght,1)
resetObjPos(hPanelInfoN,'height',dHght,1)
resetObjPos(hPanelGrp,'bottom',dHght,1) 
resetObjPos(handles.panelFinalNames,'height',dHght,1)
resetObjPos(handles.panelLinkName,'height',dHght,1)

% calculates the number of rows within the new table
pPos = getpixelposition(handles.panelFinalNames);
nRow = floor((pPos(4)-(H0T+dYP))/HWT);
hghtTabN = nRow*HWT + H0T;

% resets the group name table heights
resetObjPos(handles.tableFinalNames,'Height',hghtTabN)
resetObjPos(handles.tableLinkName,'Height',hghtTabN)

% resets the movement button object positions
tPos = get(handles.tableFinalNames,'Position');
y0 = (sum(tPos([2,4]))-dX)/2 - bHght;
resetObjPos(handles.buttonMoveDown,'Bottom',y0);
resetObjPos(handles.buttonMoveUp,'Bottom',y0+(dX+bHght));

% sets the button c-data values
cdFile = fullfile(mainProgDir,'Para Files','ButtonCData.mat');
if exist(cdFile,'file')
    [A,nDS] = deal(load(cdFile),3); 
    [Iup,Idown] = deal(A.cDataStr.Iup,A.cDataStr.Idown);        
    set(handles.buttonMoveUp,'Cdata',uint8(dsimage(Iup,nDS)));        
    set(handles.buttonMoveDown,'Cdata',uint8(dsimage(Idown,nDS)));                   
end

% creates the experiment table
setObjEnable(handles.buttonMoveUp,'off');
setObjEnable(handles.buttonMoveDown,'off');
createExptInfoTable(handles,num2cell(cWid))

% sets the row count into the gui
setappdata(hFig,'nRow',nRow);

% ----------------------------------------- %
% --- OTHER INFORMATION TAB GROUP SETUP --- %
% ----------------------------------------- %

% sets the object positions
tabPosI = getTabPosVector(hPanelInfo,[5,5,-15,-5]);
hTabGrpI = createTabPanelGroup(hPanelInfo,1);
set(hTabGrpI,'position',tabPosI,'tag','hTabGrpL'); 
setappdata(hFig,'hTabGrpI',hTabGrpI)

% tab group information fields
hP = {hPanelInfoEx,hPanelInfoN};
tabStr = {'Experiment Comparison','Group Naming'};

% creates all the information tabs and updates the panel parent objects
for i = 1:length(hP)
    hTabNw = createNewTabPanel(hTabGrpI,1,'title',tabStr{i},'UserData',i);
    set(hTabNw,'ButtonDownFcn',{@tabSelectedInfo,handles})    
    set(hP{i},'Parent',hTabNw)    
end

% creates the tab group java object and disables the group name panel
jTabGrpI = getTabGroupJavaObj(hTabGrpI);
jTabGrpI.setEnabledAt(1,0);

% sets the group handles into the GUI
setappdata(hFig,'hTabGrpI',hTabGrpI)
setappdata(hFig,'jTabGrpI',jTabGrpI)

% sets the empty table data fields
[cHdr1,cHdr2] = deal({'Group Name'},{'Original Name','Final Name'});
set(handles.tableFinalNames,'Data',cell(nRow,1),'ColumnName',cHdr1);
set(handles.tableLinkName,'Data',cell(nRow,2),'ColumnName',cHdr2);

% auto-resizes the table columns
autoResizeTableColumns(handles.tableFinalNames)
autoResizeTableColumns(handles.tableLinkName)

% sets the original group names
gName = cellfun(@(x)(x.gName),sInfo,'un',0);
setappdata(hFig,'gName',gName);
setappdata(hFig,'gName0',gName);

% --------------------------------------------- %
% --- EXPERIMENT GROUPING INFORMATION SETUP --- %
% --------------------------------------------- %

% determines the compatible experiment info
indG = cmpObj.detCompatibleExpts();
resetFinalGroupNameArrays(hFig,indG)

% sets the object positions
tabPosL = getTabPosVector(hPanelGrpL,[5,5,-10,-5]);
hTabGrpL = createTabPanelGroup(hPanelGrpL,1);
set(hTabGrpL,'position',tabPosL,'tag','hTabGrpL'); 
setappdata(hFig,'hTabGrpL',hTabGrpL)
 
% updates the grouping lists
updateGroupLists(handles,indG)

% sets the criteria checkbox callback functions
hChkL = findall(hPanelGrpC,'style','checkbox');
arrayfun(@(x)(set(hChkL,'Callback',{@checkUpdate,handles})),hChkL)

% sets the other parameters
set(handles.editMaxDiff,'string',num2str(cmpObj.getParaValue('pDur')));

% ----------------------------------------- %
% --- EXPERIMENT FILE INFORMATION SETUP --- %
% ----------------------------------------- %

% retrieves the default directories
iProg = getappdata(hFig,'iProg');

% sets the base file directory/output names
objStr = 'javahandle_withcallbacks.com.sun.java.swing.plaf.windows.WindowsFileChooserUI$7';

% file chooser parameters
fSpec = {{'DART Multi-Experiment Solution File (*.msol)',{'msol'}}};
defDir = iProg.DirComb;

% creates the file chooser object
jFileC = setupJavaFileChooser(hPanelF,'fSpec',fSpec,...
                                      'defDir',defDir,...
                                      'defFile',defDir,...
                                      'isSave',true);
jFileC.setDialogType(1)
jFileC.PropertyChangeCallback = {@chooserPropChange,handles};
setappdata(hFig,'jFileC',jFileC)

% attempts to retrieve the correct object for the keyboard callback func
jPanel = jFileC.getComponent(2).getComponent(2);
hFn = handle(jPanel.getComponent(2).getComponent(1),'CallbackProperties');
if isa(hFn,objStr)
    % if the object is feasible, set the callback function
    hFn.KeyTypedCallback = {@saveFileNameChng,handles};
end

% --- updates the group list tabs
function updateGroupLists(handles,indG)

% object retrieval
hFig = handles.figCompExpt;
hPanelGrpL = handles.panelGroupLists;
hTabGrpL = getappdata(hFig,'hTabGrpL');
hTab0 = get(hTabGrpL,'Children');

% sets the default input arguments
if ~exist('indG','var')
    cObj = getappdata(hFig,'cmpObj');
    indG = cObj.detCompatibleExpts();
end

% array dimensions
[nGrp,nTab] = deal(length(indG),length(hTab0));

% creates the new tab panel
for i = (nTab+1):nGrp
    tStr = sprintf('Group #%i',i);
    hTabNw = createNewTabPanel(hTabGrpL,1,'title',tStr,'UserData',i);
    set(hTabNw,'ButtonDownFcn',{@tabSelectedGrp,handles})
end

% retrieves the group list
hList = findall(hPanelGrpL,'tag','hGrpList');
if isempty(hList)
    % sets up the listbox positional vector
    tabPos = get(hTabGrpL,'Position');    
    lPos = [5,5,tabPos(3)-15,tabPos(4)-35];
    
    % creates the listbox object
    hTabNw = findall(hTabGrpL,'UserData',1);
    hList = uicontrol('Style','Listbox','Position',lPos,...
                              'tag','hGrpList','Max',2,'Value',[],...
                              'Callback',{@listSelect,handles});
    set(hList,'Parent',hTabNw)
end

% removes any extra tab panels
for i = (nGrp+1):nTab
    % determines the tab to be removed
    hTabRmv = findall(hTab0,'UserData',i);
    if isequal(hTabRmv,get(hTabGrpL,'SelectedTab'))
        % if the current tab is also selected, then change the tab to the
        % very first tab
        hTabNw = findall(hTab0,'UserData',1);
        set(hTabGrpL,'SelectedTab',hTabNw)
        set(hList,'Parent',hTabNw);
    end
    
    % deletes the tab
    delete(hTabRmv);
end

% updates the tab information
hTabS = get(hTabGrpL,'SelectedTab');
tabSelectedGrp(hTabS,[],handles,indG);

% --- creates the experiment information table
function createExptInfoTable(handles,cWid)

% java imports
import javax.swing.JTable

% object handle retrieval
hFig = handles.figCompExpt;
hTable = handles.tableExptInfo;
hPanel = handles.panelExptComp;

% sets the table header strings
hdrStr = {createTableHdrString({'Experiment Name'}),...
          createTableHdrString({'Setup','Config'}),...
          createTableHdrString({'Region','Shape'}),...
          createTableHdrString({'Stimuli','Devices'}),...
          createTableHdrString({'Exact','Protocol?'}),...
          createTableHdrString({'Duration'}),...
          createTableHdrString({'Compatible?'})};

% sets up the table data array
tabData = getTableData(hFig,1);

% creates the java table object
jScroll = findjobj(hTable);
[jScroll, hContainer] = javacomponent(jScroll, [], hPanel);
set(hContainer,'Units','Normalized','Position',[0,0,1,1])

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
        tabCR1.setCellFgColor(i-1,j-1,java.awt.Color(0,0,0));
        tabCR2.setCellFgColor(i-1,j-1,java.awt.Color(0,0,0));
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
    cMdl.setMinWidth(cWid{cID})
    
    if cID == 1
        cMdl.setCellRenderer(tabCR1);        
    else
        cMdl.setCellRenderer(tabCR2);
    end
end

% repaints the table
jTable.repaint()
jTable.setAutoResizeMode(jTable.AUTO_RESIZE_ALL_COLUMNS)

% sets the table cell renderer
setappdata(hFig,'tabCR1',tabCR1)
setappdata(hFig,'tabCR2',tabCR2)
setappdata(hFig,'jTable',jTable)

% --- sets up the table header string
function hdrStrF = createTableHdrString(hdrStr)

% ensures the header string is contained in a cell array
if ~iscell(hdrStr); hdrStr = {hdrStr}; end
      
% sets the final header string
if length(hdrStr) == 1
    % case is there is only one row
    hdrStrF = sprintf('<html><center>%s</center></html>',hdrStr{1});
else
    % case is there is more than one row
    hdrStrF = sprintf('<html><center>%s<br />%s</center></html>',...
                      hdrStr{1},hdrStr{2});
end

% --- resets the panel information for the experiment index, iExpt
function resetExptInfo(handles,iExp)

% global variables
global tableUpdate

% initialisations
hFig = handles.figCompExpt;
cObj = getappdata(hFig,'cmpObj');
tabCR1 = getappdata(hFig,'tabCR1');
tabCR2 = getappdata(hFig,'tabCR2');
jTable = getappdata(hFig,'jTable');

% other initialisations
isS = cObj.iSel;
eStr = {'No','Yes'};
nExp = cObj.getParaValue('nExp');
[~,isComp] = cObj.detCompatibleExpts();

% sets the table cell colours
gCol = getJavaCol(0.5,0.5,0.5);
cCol = {getJavaCol(1,0.5,0.5),getJavaCol(0.5,0.5,1),getJavaCol(0.5,1,0.5)};

% updates the text object colours
tableUpdate = true;
for i = 1:nExp
    % updates the stimuli protocol comparison strings
    isC = isComp{iExp}(i);
    jTable.setValueAt(java.lang.String(cObj.expData{i,6,iExp}),i-1,5)
    jTable.setValueAt(eStr{1+isC},i-1,6)
    
    % sets the table strings
    tabCR1.setCellBgColor(i-1,0,cCol{1+2*isC});
    tabCR2.setCellBgColor(i-1,6,cCol{1+2*isC});
    
    % updates the table cell colours
    for j = 1:size(cObj.cmpData,2)
        if isS(j)
            isM = cObj.cmpData(i,j,iExp);
            tabCR2.setCellBgColor(i-1,j,cCol{1+isM*(1+isC)});
        else
            tabCR2.setCellBgColor(i-1,j,gCol);
        end
    end                      
end

% repaints the table
jTable.repaint();

% resets the table update flag
tableUpdate = false;

% --- resets the occurances of prStr to nwStr (for the cell array, gName)
function gName = resetGroupNames(gName,nwStr,prStr)

% ensures the previous/new strings are not empty
if isempty(prStr); prStr = ' '; end
if isempty(nwStr); nwStr = ' '; end

% resets the group names for each experiment
for i = 1:length(gName)
    gName{i}(strcmp(gName{i},prStr)) = {nwStr};
end

% --- retrieves the current table data
function tabData = getTableData(hFig,iExp)

% initialisations
sStr = {'No','Yes'};
cObj = getappdata(hFig,'cmpObj');
[indG,isComp] = cObj.detCompatibleExpts();

% retrieves the experiment index (if not provided)
if ~exist('iExp','var')
    hTabGrpL = getappdata(hFig,'hTabGrpL');
    hTab = get(hTabGrpL,'SelectedTab');
    iExp = indG{get(hTab,'UserData')}(1);
end

% sets up the table data array
tabData = [cObj.expData(:,:,1),...
           arrayfun(@(x)(sStr{1+x}),isComp{iExp},'un',0)];
       
% --- retrieves the current experiment index
function iExp = getCurrentExpt(hFig)

% field retrieval
cObj = getappdata(hFig,'cmpObj');
hTabGrpL = getappdata(hFig,'hTabGrpL');

% retrieves the current experiment index
indG = cObj.detCompatibleExpts();
hTab = get(hTabGrpL,'SelectedTab');
iExp = indG{get(hTab,'UserData')}(1);

% --- retrieves the java colour for the R/G/B tuple
function jCol = getJavaCol(R,G,B)

jCol = java.awt.Color(R,G,B);

% --- removes any of the infeasible names from the name list
function gName = rmvInfeasName(gName)

% determines the flags of the group names that are infeasible
rStr = '* REJECTED *';
isRmv = strcmp(gName,rStr) | strcmp(gName,' ') | cellfun(@isempty,gName);

% removes any infeasible names
gName = gName(~isRmv);

% --- expands the cell array to have a minimum of nRow rows 
function Data = expandCellArray(Data,nRow,cVal)

% array dimensioning
szD = size(Data);

% expands the array (if necessary)
if nRow > szD(1)
    if ~exist('cVal','var'); cVal = ' '; end
    Data = [Data;repmat({cVal},nRow-szD(1),szD(2))];
end

% --- resets the final group name arrays
function resetFinalGroupNameArrays(hFig,indG)

% sets the default input arguments
if ~exist('indG','var')
    cObj = getappdata(hFig,'cmpObj');
    indG = cObj.detCompatibleExpts();
end

% determines the unique group names
gName = getappdata(hFig,'gName');
gNameU = cellfun(@(x)(rmvInfeasName(unique...
                            (cell2cell(gName(x)),'stable'))),indG,'un',0);
setappdata(hFig,'gNameU',gNameU);
