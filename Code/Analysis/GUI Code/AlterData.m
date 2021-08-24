function varargout = AlterData(varargin)
% Last Modified by GUIDE v2.5 23-Oct-2016 15:08:10

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AlterData_OpeningFcn, ...
                   'gui_OutputFcn',  @AlterData_OutputFcn, ...
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

% --- Executes just before AlterData is made visible.
function AlterData_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for AlterData
handles.output = hObject;

% sets the initialises the GUI type
hGUI = varargin{1};
Type = varargin{2};

% retrieves the currently selected row/column indices
iData = getappdata(hGUI.figDataOutput,'iData');
hTab = findall(iData.tData.hTab{iData.cTab},'type','uitable');
jTab = getJavaTable(hTab);
    
% retrieves the currently selected cell(s) row/column indices
[iRow0,iCol0] = deal(jTab.getSelectedRows,jTab.getSelectedColumns);
if isempty(iRow0) || isempty(iCol0)
    % if no cell is selected, then output a message to screen
    mStr = 'No worksheet cell has been selected. Retry by selecting at least one cell.';
    waitfor(msgbox(mStr,'No Worksheet Cells Selected','modal'))
    
    % deletes the GUI and exits
    delete(hObject)
    return
end

jTab.setNonContiguousCellSelection(false);

% sets the fields into the GUI
setappdata(hObject,'hGUI',hGUI)
setappdata(hObject,'Type',Type)
setappdata(hObject,'iRow0',iRow0)
setappdata(hObject,'iCol0',iCol0)
setappdata(hObject,'jTab',jTab)
setappdata(hObject,'hTab',hTab)

% initialises the GUI objects
initGUIObjects(handles,Type)

% Update handles structure
guidata(hObject, handles);
set(hObject,'WindowStyle','modal')

% UIWAIT makes AlterData wait for user response (see UIRESUME)
% uiwait(handles.figAlterData);

% --- Outputs from this function are returned to the command line.
function varargout = AlterData_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = [];

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --------------------------------------- %
% --- RADIO BUTTON SELECTION CALLBACK --- %
% --------------------------------------- %

% --- Executes when selected object is changed in panelAlterData.
function panelAlterData_SelectionChangeFcn(hObject, eventdata, handles)

% retrieves the data/object handle arrays
jTab = getappdata(handles.figAlterData,'jTab');
Type = getappdata(handles.figAlterData,'Type');

% retrieves the table dimensions
[m,n] = deal(jTab.getRowCount,jTab.getColumnCount);

% retrieves the original row selection indices
iRow0 = getappdata(handles.figAlterData,'iRow0');
if (isempty(iRow0))
    % if they are empty, then re-read the row indices 
    iRow0 = jTab.getSelectedRows;
    setappdata(handles.figAlterData,'iRow0',iRow0)
end

% retrieves the original column selection indices
iCol0 = getappdata(handles.figAlterData,'iCol0');
if (isempty(iCol0))
    % if they are empty, then re-read the column indices
    iCol0 = jTab.getSelectedColumns;
    setappdata(handles.figAlterData,'iCol0',iCol0)
end

% retrieves the currently selected radio button
hRadio = findall(handles.panelAlterData,'style','radiobutton','value',1);
iSel = get(hRadio,'UserData');

% sets the selection intervals
if (iSel > (1+(Type==3)))
    % column is selected
    jTab.setColumnSelectionInterval(iCol0(1), iCol0(end));
    jTab.setRowSelectionInterval(0, m-1);        
else
    % row is selected
    jTab.setRowSelectionInterval(iRow0(1), iRow0(end));
    jTab.setColumnSelectionInterval(0, n-1);
end

% -------------------------------- %
% --- CONTROL BUTTON CALLBACKS --- %
% -------------------------------- %

% --- Executes on button press in buttonApply.
function buttonApply_Callback(hObject, eventdata, handles)

% retrieves the data/object handle arrays
hGUI = getappdata(handles.figAlterData,'hGUI');
jTab = getappdata(handles.figAlterData,'jTab');
hTab = getappdata(handles.figAlterData,'hTab');
iRow0 = getappdata(handles.figAlterData,'iRow0');
iCol0 = getappdata(handles.figAlterData,'iCol0');
iData = getappdata(hGUI.figDataOutput,'iData');

% retrieves the data array
Data = iData.tData.Data{iData.cTab};
[iRow,iCol] = deal(jTab.getSelectedRows+1,jTab.getSelectedColumns+1);

% retrieves the table dimensions
[mm,nn] = size(Data);

% retrieves the function handles
setFinalSheetData = getappdata(hGUI.figDataOutput,'setFinalSheetData');
getTableHeaderStrings = getappdata(hGUI.figDataOutput,'getTableHeaderStrings');

% retrieves the currently selected radio button
hRadio = findall(handles.panelAlterData,'style','radiobutton','value',1);
iSel = get(hRadio,'UserData');

% updates the sheet data depending on the alteration type
switch (getappdata(handles.figAlterData,'Type'))
    case (1)
        % case is insert the row/columns of the data array
        switch (iSel)
            case (1) % case is inserting a row
                DataI = repmat({''},length(iRow),nn);
                Data = [Data(1:(iRow(1)-1),:);DataI;Data(iRow(1):mm,:)];
            case (2) % case is inserting a column
                DataI = repmat({''},mm,length(iCol));
                Data = [Data(:,1:(iCol(1)-1)),DataI,Data(:,iCol(1):nn)];
        end
    case (2)
        % case is deleting the row/columns of the data array
        switch (iSel)
            case (1) % case is deleting a row
                Data = [Data(1:(iRow(1)-1),:);Data((iRow(end)+1):mm,:)];
            case (2) % case is deleting a column
                Data = [Data(:,1:(iCol(1)-1)),Data(:,(iCol(end)+1):nn)];
        end                
    case (3)
        % case is shift row/columns into the data array
        switch (iSel)
            case (1) % case is shift row up
                ii = [(1:iRow(1)-2)';iRow;(iRow(1)-1);((iRow(end)+1):mm)'];
                Data = Data(ii,:);
            case (2) % case is shift row down
                ii = [(1:iRow(1)-1)';(iRow(end)+1);iRow;((iRow(end)+2):mm)'];
                Data = Data(ii,:);
            case (3) % case is shift column left
                jj = [(1:iCol(1)-2)';iCol;(iCol(1)-1);((iCol(end)+1):nn)'];
                Data = Data(:,jj);
            case (4) % case is shift column right         
                jj = [(1:iCol(1)-1)';(iCol(end)+1);iCol;((iCol(end)+2):nn)'];
                Data = Data(:,jj);
        end            
end

% updates the data array into the GUI
iData.tData.Data{iData.cTab} = Data;
setappdata(hGUI.figDataOutput,'iData',iData)

pause(0.05); drawnow;
fprintf(' \b');

% retrieves the header strings
Data = expandWorksheetTable(Data);
[rowN,colN] = getTableHeaderStrings(Data);

% updates the table and makes it visible    
cEdit = true(1,size(Data,2));
cForm = repmat({'char'},1,size(Data,2));
set(hTab,'ColumnFormat',cForm,'ColumnName',colN,...
         'ColumnEditable',cEdit,'RowName',rowN); 

% sets the table data and adds the table popup menu
setFinalSheetData(hGUI,jTab,Data,colN)  

% closes the GUI
delete(handles.figAlterData)

% updates the sheet data
resetOrigTableSelection(jTab,iRow0,iCol0); pause(0.05);

% resets the contiguous cell selection flag
jTab.setNonContiguousCellSelection(true);

% --- Executes on button press in buttonCancel.
function buttonCancel_Callback(hObject, eventdata, handles)

% initialisations
jTab = getappdata(handles.figAlterData,'jTab');
iRow0 = getappdata(handles.figAlterData,'iRow0');
iCol0 = getappdata(handles.figAlterData,'iCol0');

% closes the GUI
delete(handles.figAlterData)

% resets the contiguous cell selection flag
resetOrigTableSelection(jTab,iRow0,iCol0); pause(0.05);
jTab.setNonContiguousCellSelection(true);

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the GUI objects
function initGUIObjects(handles,Type)

% retrieves the main GUI handles
hGUI = getappdata(handles.figAlterData,'hGUI');

% resizes the GUI (if type adding rows/columns only)
if any(Type == [1 2])
    % determines the figure offset
    rPos = get(handles.radioAlter2,'position');
    dH = rPos(2) - 10;
    
    % deletes the bottom 2 radio buttons
    delete(handles.radioAlter3)
    delete(handles.radioAlter4)
    
    % alters the radio button strings
    if (Type == 1)
        set(handles.radioAlter1,'String','Insert Sheet Row(s)')
        set(handles.radioAlter2,'String','Insert Sheet Column(s)')
        set(handles.buttonApply,'String','Apply Insert');
        set(handles.figAlterData,'Name','Insert Row/Column');
    else
        set(handles.radioAlter1,'String','Delete Sheet Row(s)')
        set(handles.radioAlter2,'String','Delete Sheet Column(s)')
        set(handles.buttonApply,'String','Apply Deletion');
        set(handles.figAlterData,'Name','Delete Row/Column');        
    end
        
    % resets the panel/figure heights    
    resetObjPos(handles.radioAlter1,'bottom',-dH,1)
    resetObjPos(handles.radioAlter2,'bottom',-dH,1)    
    resetObjPos(handles.panelAlterData,'height',-dH,1)
    resetObjPos(handles.figAlterData,'height',-dH,1)
    
    % resets the postion of the control buttons    
    resetObjPos(handles.buttonApply,'bottom',10)
    resetObjPos(handles.buttonCancel,'bottom',10)    
else
    % sets the table java object (if not set)
    jTab = getappdata(handles.figAlterData,'jTab');
    
    % retrieves the data array and the selected rows/columns
    [m,n] = deal(jTab.getRowCount,jTab.getColumnCount);
    [iRow,iCol] = deal(jTab.getSelectedRows+1,jTab.getSelectedColumns+1);      
    
    % determines which radio buttons are feasible
    ind = [all(iRow>1),all(iRow<m),(all(iCol>1)),(all(iCol<n))];
    
    % sets the enabled properties of the radio buttons
    setObjEnable(handles.radioAlter1,ind(1))
    setObjEnable(handles.radioAlter2,ind(2))        
    setObjEnable(handles.radioAlter3,ind(3))
    setObjEnable(handles.radioAlter4,ind(4))
    setObjEnable(handles.buttonApply,any(ind))
end

% sets the initial radio button selection
set(handles.radioAlter1,'value',1)
panelAlterData_SelectionChangeFcn([], [], handles)

% --- resets the table selection to the original
function resetOrigTableSelection(jTab,iRow0,iCol0)

% sets the original table selection 
jTab.setRowSelectionInterval(iRow0(1), iRow0(end));
jTab.setColumnSelectionInterval(iCol0(1), iCol0(end));
