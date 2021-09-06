function varargout = RefLogPara(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RefLogPara_OpeningFcn, ...
                   'gui_OutputFcn',  @RefLogPara_OutputFcn, ...
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

% --- Executes just before RefLogPara is made visible.
function RefLogPara_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for RefLogPara
handles.output = hObject;

% retrieves the main GUI handle
[vObj,hFigM] = deal(varargin{1},varargin{2});
cBr = vObj.getCurrentBranchName();

% sets the input parameters
setappdata(hObject,'cBr',cBr)
setappdata(hObject,'vObj',vObj)
setappdata(hObject,'hFigM',hFigM)
setappdata(hObject,'rlData',initRefLogPara(cBr))

% sets the function handles into the GUI
setappdata(hObject,'updateRefLogTable',@updateRefLogTable)

% initialises the GUI objects
initGUIObjects(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes RefLogPara wait for user response (see UIRESUME)
% uiwait(handles.figRefLogsPara);

% --- Outputs from this function are returned to the command line.
function varargout = RefLogPara_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = hObject;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     FIGURE CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when user attempts to close figRefLogPara.
function figRefLogPara_CloseRequestFcn(hObject, eventdata, handles)

% do nothing...

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     OBJECT CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on updating editHistCount
function editHistCount_Callback(hObject, eventdata, handles)

% initialisations
rlData = getappdata(handles.figRefLogPara,'rlData');

% determines if the new value is valid
nwVal = str2double(get(hObject,'string'));
if chkEditValue(nwVal,[1,1000],1)
    % if the new value is valid, then update the data struct
    rlData.nHist = nwVal;
    setappdata(handles.figRefLogPara,'rlData',rlData)
    
    % enables the update filter button
    set(handles.buttonUpdateHist,'enable','on')
else
    % otherwise, revert back to the last valid value
    set(hObject,'string',num2str(rlData.nHist))
end

% --- updates the data filter
function updateDateFilter(hObject, eventdata, handles)

% initialisations
[iSel,hFig] = deal(get(hObject,'value'),handles.figRefLogPara);
[rlData,rlData0] = deal(getappdata(hFig,'rlData'));
[dStr,abStr] = deal({'Day','Month','Year'},{'After','Before'});

% determines the type
[isBefore,dType] = getSelectedPopupType(hObject);
rlData = updateDateValue(rlData,dStr{dType},...
                         iSel+(dType==3)*rlData.y0,isBefore);

if ~feasDateFilter(rlData)
    % if not, then output an error to screen
    eStr = 'Error! The before filter date must be later than the after filter date';
    waitfor(errordlg(eStr,'Date Filter Error','modal'))
    
    % resets the popup menu value to the last feasible value
    iSelPrev = eval(sprintf('rlData0.dNum%i.%s',isBefore,dStr{dType}));
    set(hObject,'value',iSelPrev-(dType==3)*rlData.y0)

    % exits the function
    return
end

% enables the update filter button
set(handles.buttonUpdateHist,'enable','on')

% determines if the current date object is a month popup box
if dType == 2
    % if so, then retrieve the maximum data count
    dNum = eval(sprintf('rlData.dNum%i',isBefore));
    dMax = getDayCount(dNum.Month);

    % retrieves the corresponding day popupmenu object handle
    hListDay = eval(sprintf('handles.popup%sDay',abStr{1+isBefore}));

    % determines if the current selected day index exceeds the new count
    iSelD = get(hListDay,'value');
    if iSelD > dMax
        % if so, then 
        iSelD = dMax;
        rlData = updateDateValue(rlData,'Day',iSelD,isBefore);
    end
    
    % determines if the max day count matches the current day count
    if length(get(hListDay,'String')) ~= dMax
        % updates the 
        pStr = arrayfun(@num2str,1:dMax,'un',0)';
        set(hListDay,'string',pStr,'value',iSelD)
    end
end

% updates the data struct
setappdata(hFig,'rlData',rlData)

% --- Executes when selected object is changed in panelHistVer.
function panelHistVer_SelectionChangedFcn(hObject, eventdata, handles)

% initialisations
[pStr,eStr] = deal('off');

% sets the handle of the currently selected radio button
if ischar(eventdata)
    hRadioSel = hObject.SelectedObject;
else
    hRadioSel = eventdata.NewValue;
end

% updates the parameters based on the selection type
switch get(hRadioSel,'tag')
    case ('radioLastHist')
        eStr = 'on';
    case ('radioDateFilt')
        pStr = 'on';
end

% updates the history type
rlData = getappdata(handles.figRefLogPara,'rlData');
rlData.hType = get(hRadioSel,'UserData');
setappdata(handles.figRefLogPara,'rlData',rlData)

% updates the other properties
set(handles.editHistCount,'enable',eStr)
setPanelProps(handles.panelFiltDate,pStr)

% enables the update filter button
set(handles.buttonUpdateHist,'enable','on')

% --- Executes on button press in buttonUpdateHist.
function buttonUpdateHist_Callback(hObject, eventdata, handles)


% updates the reference log explorer tree
updateRefLogTable(handles)

% disables the update button
set(hObject,'enable','off')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                          OTHER FUNCTIONS                          %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    OBJECT PROPERTY FUNCTIONS    %%%%           
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   

% --- initialises the GUI objects
function initGUIObjects(handles)

% retrieves the reference log parameter struct
hFig = handles.figRefLogPara;
rlData = getappdata(hFig,'rlData');
dYear = str2double(datestr(datenum(datestr(now)),'yyyy'));

% sets the selected radio button
hRadio = findall(handles.panelHistVer,'style','radioButton',...
                                      'userData',rlData.hType);
set(hRadio,'Value',1)
panelHistVer_SelectionChangedFcn(handles.panelHistVer, '1', handles)                   

% disables the update history parameter button
setObjEnable(handles.buttonUpdateHist,0)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    HISTORY VERSION PANEL OBJECTS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialises the version filter panel
set(handles.editHistCount,'string',num2str(rlData.nHist))

% sets the callback function for all data popup objects
hPopup = findall(handles.panelFiltDate,'style','popupmenu');
for i = 1:length(hPopup)
    % sets the callback function
    hObj = hPopup(i);
    set(hObj,'Callback',@updateDateFilter)
    
    % determines if the popup menu object is before
    [isBefore,dType] = getSelectedPopupType(hObj);      
    
    % sets up the popup menu strings based on the object type
    dNum = eval(sprintf('rlData.dNum%i',isBefore));
    switch dType
        case 1
            % case is the day popupmenu            
            
            % determines the number of days given the selected month
            dMax = getDayCount(dNum.Month);          
            
            % sets the popup menu list strings
            iSel = dNum.Day;
            pStr = arrayfun(@num2str,1:dMax,'un',0)';
            
        case 2
            % case is the month popupmenu            
            
            % sets the popup menu list strings            
            iSel = dNum.Month;
            pStr = {'Jan','Feb','Mar','Apr','May','Jun',...
                    'Jul','Aug','Sep','Oct','Nov','Dec'}';
                
        case 3
            % case is the year popupmenu      
            
            % sets the popup menu list strings            
            iSel = dNum.Year - rlData.y0;
            pStr = arrayfun(@num2str,2019:dYear,'un',0)';
            
    end
    
    % sets the popup strings
    set(hObj,'string',pStr,'value',iSel)
end

% updates the reference log tree
updateRefLogTable(handles)

% --- determines what type of popupmenu was selected
function [isBefore,dType] = getSelectedPopupType(hObj)

% initialisations
dStr = {'Day','Month','Year'};
hObjStr = get(hObj,'tag');

% determines if the object is a before popup object
isBefore = strContains(hObjStr,'Before');

% determines the date type of the popup menu object
dType = find(cellfun(@(x)(strContains(hObjStr,x)),dStr));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    REFERENCE LOG TABLE UPDATE FUNCTIONS    %%%%           
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        

% --- updates the reference log tree
function updateRefLogTable(handles)

% initialisations
hFig = handles.figRefLogPara;
vObj = getappdata(hFig,'vObj');
hFigM = getappdata(hFig,'hFigM');
rlData = getappdata(hFig,'rlData');

% creates the reference log explorer tree
hGUIM = guidata(hFigM);
createRefLogExplorerTable(hGUIM);

% sets the reference log GUI properties
setappdata(hFigM,'iRow',1)
set(hGUIM.textCurrSel,'string','N/A','enable','off')
set(hGUIM.textCurrSelL,'enable','off')
set(hGUIM.menuResetHist,'enable','off')

% --- creates the GitVersion explorer tree
function createRefLogExplorerTable(handles)

% object retrieval
hFig = handles.figRefLog;
hTable = handles.tableRefLog;
vObj = getappdata(hFig,'vObj');

% other initialisations
bgCol = [];
cWid = {90,150,500};
gpat = '<%h> <%as> <%s> <%at>';
colStr = {'Commit ID','Action Type','Reference Message'};

% retrieves the table data
Data = get(handles.tableRefLog,'Data');
if ~isempty(Data)
    % if there is data, then reset the table
    set(hTable,'Data',[])
end

% creates the loadbar
h = ProgressLoadbar('Updating Reference Log Table...');

% determines the matching commit group for each branch, and determines the
% grouping that belongs to the current branch
brGrp = groupCommitID(vObj.gfObj);
iBr = vObj.getCurrentHeadInfo();
indM = cellfun(@(x)(any(strcmp(x,vObj.rObj.brData{iBr,2}))),brGrp);

% retireves all info from the head commits reflog
tData = vObj.gfObj.getAllCommitInfo('HEAD',gpat);

% retrieves the reference log commit IDs
if ~isempty(tData)
    % if there is data, then sort by date
    if any(indM)
        ii = cellfun(@(x)(find(strcmp(tData(:,1),x))),brGrp{indM});
        tData = tData(ii,:);
        [~,iS] = sort(cellfun(@str2double,tData(:,end)),'descend');
        tData = tData(iS,1:3);

        % sets the table background colour
        bgCol = ones(size(tData,1),3);
        headID = vObj.rObj.gHist(iBr).brInfo.CID{1};
        bgCol(strcmp(tData(:,1),headID),:) = [1,0.5,0.5];
    else
        % otherwise reduce the arrays
        tData = tData(:,1:3);
    end
end
                    
% updates the table and resizes
set(hTable,'Data',tData,'ColumnName',colStr,'ColumnWidth',cWid)
if ~isempty(bgCol)
    set(hTable,'BackgroundColor',bgCol)   
end

% automatically resizes the table columns                    
autoResizeTableColumns(hTable);        

% deletes the loadbar
delete(h)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%           
%%%%    DATE FUNCTIONS    %%%%           
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%           

% --- retrieves the day count based on month index
function dCount = getDayCount(iMonth)

switch iMonth
    case (2) % case is February
        dCount = 28;
    case {4,6,9,11} % case is the 30 day months
        dCount = 30;                
    otherwise % case is the 31 day months
        dCount = 31;                                
end

% --- updates the date value
function rlData = updateDateValue(rlData,dStr,iSel,isBefore)

eval(sprintf('rlData.dNum%i.%s = iSel;',isBefore,dStr))

% --- determines if the current before/after dates are feasible
function isFeas = feasDateFilter(rlData)

% calculates the date-time objects and determines if feasible
[d0,d1] = deal(rlData.dNum0,rlData.dNum1);
isFeas = datetime(d1.Year,d1.Month,d1.Day) > ...
         datetime(d0.Year,d0.Month,d0.Day);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%           
%%%%    MISCELLANOUES FUNCTIONS    %%%%           
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%          
     
% --- initialises the reference log history parameter struct
function rlData = initRefLogPara(cBr)

% retrieves the current date indices
dVal = cellfun(@str2double,strsplit(datestr(now,'dd/mm/yyyy'),'/'));

% retrieves the date string numbers for the start/end times
dNum0 = struct('Day',1,'Month',1,'Year',2019);
dNum1 = struct('Day',dVal(1),'Month',dVal(2),'Year',dVal(3));

% sets up the data struct
rlData = struct('hType',2,'nHist',200,'dNum0',dNum0,...
                'dNum1',dNum1,'y0',2018,'bType',cBr);  

% --- retrieves the date string from the data struct, dNum
function dStr = getDateStr(dNum)

dStr = datestr([dNum.Year,dNum.Month,dNum.Day,0,0,0],29);            
