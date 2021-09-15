function varargout = FuncComp(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FuncComp_OpeningFcn, ...
                   'gui_OutputFcn',  @FuncComp_OutputFcn, ...
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

% --- Executes just before FuncComp is made visible.
function FuncComp_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global isUpdating

% global variable initialisations
isUpdating = false;

% Choose default command line output for FuncComp
handles.output = hObject;

% sets the input arguments
hFigM = varargin{1};
setappdata(hObject,'hFigM',hFigM)
setappdata(hObject,'pData',getappdata(hFigM,'pData'))
setappdata(hObject,'snTot',getappdata(hFigM,'snTot'))

% initialises the object properties
initObjProps(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes FuncComp wait for user response (see UIRESUME)
% uiwait(handles.figFuncComp);

% --- Outputs from this function are returned to the command line.
function varargout = FuncComp_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when user attempts to close figFuncComp.
function figFuncComp_CloseRequestFcn(hObject, eventdata, handles)

% Hint: delete(hObject) closes the figure
delete(hObject);

%-------------------------------------------------------------------------%
%                        OBJECT CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes on button press in toggleFuncFilter.
function toggleFuncFilter_Callback(hObject, eventdata, handles)

% object handles
hPanel = handles.panelFuncFilter;

% updates the funcion filter panel visibility
isOpen = get(hObject,'Value');
setObjVisibility(hPanel,isOpen);

% updates the toggle button string
if isOpen
    set(hObject,'String','Close Function Requirement Filter')
else
    set(hObject,'String','Open Function Requirement Filter')
end

% --- Executes on button press in checkGrpExpt.
function checkGrpExpt_Callback(hObject, eventdata, handles)

% updates the tree click function
fcnObj = getappdata(handles.figFuncComp,'fcnObj'); 
fcnObj.treeUpdateClick();

% --- Executes on selection change in popupFuncSort.
function popupFuncSort_Callback(hObject, eventdata, handles)

% java imports
import javax.swing.SortOrder

% object handles
hFig = handles.figFuncComp;
iSel = get(hObject,'Value');
sOrder = SortOrder.ASCENDING;
jTable = getappdata(hFig,'jTable');

% sets the sorting list array
sList = java.util.ArrayList;
sList.add(javaObject('javax.swing.RowSorter$SortKey',iSel-1,sOrder));

% sets the rows sort order
jRowSorter = jTable.getRowSorter();
jRowSorter.setSortKeys(sList)

if isempty(eventdata)
    arrayfun(@(x)(jRowSorter.setSortable(x-1,0)),1:jTable.getColumnCount);
else
    resetFuncCompColours(hFig)    
end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --------------------------------------- %
% --- OBJECT INITIALISATION FUNCTIONS --- %
% --------------------------------------- %

% --- initialises the GUI object properties
function initObjProps(handles)

% field retrieval
hFig = handles.figFuncComp;
hPopup = handles.popupFuncSort;

% initialises the function filter free
fcnObj = FuncFilterTree(hFig,handles.checkGrpExpt);
fcnObj.setClassField('treeUpdateExtn',{@resetFuncCompColours,hFig});
setappdata(hFig,'fcnObj',fcnObj);

% retrieves the function data
initFuncDepTable(handles);
initFuncCellComp(handles);

% resets the popup menu user data
lStr = get(hPopup,'String');
rGrp = getappdata(hFig,'reqGrp');
nGrp = cellfun(@(x)(length(getStructField(rGrp,x))),fieldnames(rGrp));

% removes any requirement groups without multiple group types
indM = [1;(find(nGrp > 1) + 1)];
set(hPopup,'String',lStr(indM),'UserData',indM);

% runs the function sorting popup menu
popupFuncSort_Callback(handles.popupFuncSort, [], handles)

% --- initialises the function cell compatibility table colours
function initFuncCellComp(handles)

% field retrieval
hFig = handles.figFuncComp;
jTable = getappdata(hFig,'jTable');
tabCR1 = getappdata(hFig,'tabCR1');
tabCR2 = getappdata(hFig,'tabCR2');
cmpData = getappdata(hFig,'cmpData');
tabData = getappdata(hFig,'tabData0');
fcnObj = getappdata(hFig,'fcnObj');

% other initialisations
[nFunc,nHdr] = size(fcnObj.fcnData);
grayCol = getJavaCol(0.81,0.81,0.81);
graylightCol = getJavaCol(0.9,0.9,0.9);
cCol = {getJavaCol(1.0,0.5,0.5),getJavaCol(0.5,1.0,0.5)};

% sets the background colours based on the column indices
for i = 1:nFunc
    for j = 1:size(tabData,2)
        if j == 1
            % case is the function name column
            tabCR1.setCellBgColor(i-1,j-1,grayCol);
            
        elseif j <= nHdr
            % case is the other requirement columns
            tabCR2.setCellBgColor(i-1,j-1,graylightCol);

        elseif j == (nHdr + 1) 
            % case is the gap column
            tabCR2.setCellBgColor(i-1,j-1,grayCol);
            
        else
            % case is the experiment compatibility columns
            k = j - (nHdr+1);
            isComp = double(cmpData(i,k));
            tabCR2.setCellBgColor(i-1,j-1,cCol{1+isComp});
        end
    end
end

% repaints the table
jTable.repaint();

% --- initialises the filter tree
function initFuncDepTable(handles)

% object handle retrieval
hFig = handles.figFuncComp;
hTable = handles.tableFuncComp;
hPanel = handles.panelFuncComp;
fcnObj = getappdata(hFig,'snTot');

% other initialisations
dX = 5;
sGap = 2;
expWid = 40;
dPos = [2*dX,2*(dX+1)];
nExp = length(fcnObj.snTot);  
sStr = {'No','Yes'};
pPos = get(hPanel,'Position');
reqWid = [55,55,70,60,60];
cWidMin = num2cell([200,reqWid,sGap,expWid*ones(1,nExp)]);
cWidMax = num2cell([200,reqWid,sGap,expWid*ones(1,nExp)]);
exptCol = arrayfun(@(x)(createTableHdrString...
                ({'Expt',sprintf('#%i',x)})),1:nExp,'un',0);

% sets the table header strings
hdrStr = [{createTableHdrString({'Analysis Function Name'}),...
          createTableHdrString({'Analysis','Scope'}),...
          createTableHdrString({'Duration'}),...
          createTableHdrString({'Shape'}),...
          createTableHdrString({'Stimuli'}),...          
          createTableHdrString({'Special'}),' '},exptCol];      

% retrieves the compatibility data
fcnData = fcnObj.fcnData;
cmpData = detExptCompatibility(handles);

% sets up the function requirement information array
nFunc = size(fcnData,1);
fcnData(:,2:end) = centreTableData(fcnData(:,2:end));
tabData = [fcnData,repmat({' '},nFunc,1),...
           arrayfun(@(x)(sStr{1+x}),cmpData,'un',0)];
                
% tabData = [fcnData,repmat({' '},nFunc,1)];

% creates the java table object
jScroll = findjobj(hTable);
[jScroll, hContainer] = javacomponent(jScroll, [], hPanel);
set(hContainer,'Units','Pixels','Position',[dX*[1,1],pPos(3:4)-dPos])

% creates the java table model
jTable = jScroll.getViewport.getView;
jTableMod = javax.swing.table.DefaultTableModel(tabData,hdrStr);
jTable.setModel(jTableMod);

% % sets the table callback function
% cbFcn = {@tableCellChange,handles};
% jTH = handle(jTable.getTableHeader,'callbackproperties');
% % jTH = handle(jTable,'callbackproperties');
% addJavaObjCallback(jTH,'MousePressedCallback',cbFcn);

% creates the table cell renderer
tabCR1 = ColoredFieldCellRenderer(java.awt.Color.white);
tabCR2 = ColoredFieldCellRenderer(java.awt.Color.white);

% sets the table text to black
for i = 1:size(tabData,1)
    for j = 1:size(tabData,2)
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
    % sets the model min/max widths
    cMdl = jTable.getColumnModel.getColumn(cID-1);
    cMdl.setMinWidth(cWidMin{cID})
    cMdl.setMaxWidth(cWidMax{cID})
    
    % sets the cell renderer
    if cID == 1
        % case is the name column
        cMdl.setCellRenderer(tabCR1);        
    else
        % case is the other columns
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
jTable.setAutoCreateRowSorter(true);

% repaints the table
jTable.repaint()
jTable.setAutoResizeMode(jTable.AUTO_RESIZE_OFF)

% sets the table cell renderer
setappdata(hFig,'tabCR1',tabCR1)
setappdata(hFig,'tabCR2',tabCR2)
setappdata(hFig,'jTable',jTable)
setappdata(hFig,'tabData0',tabData)

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- resets the function compatibility colours
function resetFuncCompColours(hFig)

% initialisations
jTable = getappdata(hFig,'jTable');
tabCR2 = getappdata(hFig,'tabCR2');
cCol = {getJavaCol(1.0,0.5,0.5),getJavaCol(0.5,1.0,0.5)};    

% updates the background colours of the cells
for i = 1:jTable.getRowCount
    for j = 8:jTable.getColumnCount
        switch jTable.getValueAt(i-1,j-1)
            case 'Yes'
                tabCR2.setCellBgColor(i-1,j-1,cCol{2});
            case 'No'
                tabCR2.setCellBgColor(i-1,j-1,cCol{1});
        end
    end
end    

% repaints the table
jTable.repaint

% --- determines the experiment compatibilities for each function
function cmpData = detExptCompatibility(handles)

% field retrieval
hFig = handles.figFuncComp;
fcnData = getappdata(hFig,'fcnData');
fcnInfo = getappdata(hFig,'fcnInfo');

% memory allocation
nFunc = size(fcnData,1);
[nExp,nReq] = size(fcnInfo);
cmpData = true(nFunc,nExp);

% calculates the compatibility flags for each experiment
for iFunc = 1:nFunc
    % retrieves the requirement data for the current function
    fcnDataF = fcnData(iFunc,3:end);
    
    % determines if each of the requirements matches for each expt
    isMatch = true(nReq,nExp);
    for iReq = 1:nReq
        if ~strcmp(fcnDataF{iReq},'None')
            isMatch(iReq,:) = cellfun(@(x)...
                strContains(x,fcnDataF{iReq}),fcnInfo(:,iReq));
        end
    end
    
    % calculates the overall compatibility (all 
    cmpData(iFunc,:) = all(isMatch,1);
end

% sets the experiment comparison data into the gui
setappdata(hFig,'cmpData',cmpData)

% --- retrieves the java colour for the R/G/B tuple
function jCol = getJavaCol(R,G,B)

jCol = java.awt.Color(R,G,B);
