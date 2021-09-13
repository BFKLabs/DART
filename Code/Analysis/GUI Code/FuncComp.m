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

% initialisations
hFig = handles.figFuncComp;
jRoot = getappdata(hFig,'jRoot');


% updates the tree click function
treeUpdateClick([], [], hFig, jRoot);

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

% --- callback for updating selection of the function filter tree
function treeUpdateClick(hObject, eventdata, hFig, jRoot)

% java imports
import javax.swing.RowFilter

% global variables
global isUpdating

% if updating elsewhere, then exit
if isUpdating; return; end

% initialisation
rGrp = getappdata(hFig,'reqGrp');
jTable = getappdata(hFig,'jTable');
hCheck = findall(hFig,'tag','checkGrpExpt');
rFld = fieldnames(rGrp);

% memory allocation
cFiltTot = java.util.ArrayList;

% determines if only the compatible functions are to be displayed
if get(hCheck,'Value')
    % if so, then create a regexp filter list for the "yes" cells
    cFiltArr = java.util.ArrayList;
    fcnData = getappdata(hFig,'fcnData');        
    for i = 1:jTable.getColumnCount
        j = size(fcnData,2)+(i+1); 
        cFiltArr.add(RowFilter.regexFilter('Yes',j));
    end
    
    % adds the compatibility filter to the total filter
    cFiltTot.add(RowFilter.orFilter(cFiltArr));    
end

%
for i = 1:jRoot.getChildCount
    % retrieves the child node
    jNodeC = jRoot.getChildAt(i-1);
    nStr = char(jNodeC.getUserObject);
    i0 = find(cellfun(@(x)(strContains(nStr,x)),rFld));
    
    % sets the filter field cell arrays
    switch char(jNodeC.getSelectionState)
        case 'mixed'
            % retrieves the leaf node objects
            xiC = 1:jNodeC.getChildCount;
            jNodeL = arrayfun(@(x)(jNodeC.getChildAt(x-1)),xiC','un',0);
            
            % determines which of the leaf nodes have been selected
            isSel = cellfun(@(x)(strcmp...
                        (char(x.getSelectionState),'selected')),jNodeL);
            fFld = cellfun(@(x)(x.getUserObject),jNodeL(isSel),'un',0);
                    
        otherwise
            % case is either all or none are selected (use all in any case)
            fFld = getStructField(rGrp,rFld{i0});
    end  
    
    % creates the category filter array
    cFiltArr = java.util.ArrayList;
    for j = 1:length(fFld)
        % loops through each requirement type setting the regex filters
        if i0 == 1
            % case is the analysis scope requirement
            cFiltArr.add(RowFilter.regexFilter(fFld{j}(1),i0));
        else
            % case is the other filter types, so split the filter string
            fFldSp = strsplit(fFld{j});
            if length(fFldSp) == 1
                % if the filter string is only one word, then create the
                % filter using this string
                cFiltArr.add(RowFilter.regexFilter(fFld{j},i0));
            else
                % otherwise, create an and filter from each of the word
                cFiltSp = java.util.ArrayList;
                for k = 1:length(fFldSp)
                    cFiltSp.add(RowFilter.regexFilter(fFldSp{k},i0));
                end
                cFiltArr.add(RowFilter.andFilter(cFiltSp));
            end
        end
    end
    
    % adds the category filter to the total filter
    cFiltTot.add(RowFilter.orFilter(cFiltArr));
end

% resets the row sorter filter
jRowSort = jTable.getRowSorter;
jRowSort.setRowFilter(RowFilter.andFilter(cFiltTot))

% resets the function compatibility colours
resetFuncCompColours(hFig)

% --- callback for expanding a tree node
function treeExpandClick(hObject, eventdata, hFig)

% global variables
global isUpdating

% flags that the tree is updating
isUpdating = true;

% resets the tree panel dimensions
nwHeight = hObject.getMaximumSize.getHeight;
resetTreePanelPos(hFig,nwHeight)
pause(0.05);

% flags that the tree is updating
isUpdating = false;

% --- callback for expanding a tree node
function treeCollapseClick(hObject, eventdata, hFig)

% global variables
global isUpdating

% flags that the tree is updating
isUpdating = true;

% resets the tree panel dimensions
nwHeight = hObject.getMaximumSize.getHeight;
resetTreePanelPos(hFig,nwHeight)
pause(0.05);

% flags that the tree is updating
isUpdating = false;

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the GUI object properties
function initObjProps(handles)

% field retrieval
hFig = handles.figFuncComp;
hPopup = handles.popupFuncSort;

% retrieves the function data
setupExptInfo(handles)
initFuncDepTable(handles);
initFuncCellComp(handles);
initFilterTree(handles);

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
fcnData = getappdata(hFig,'fcnData');
tabData = getappdata(hFig,'tabData0');

% other initialisations
[nFunc,nHdr] = size(fcnData);
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
snTot = getappdata(hFig,'snTot');

% other initialisations
dX = 5;
sGap = 2;
expWid = 40;
dPos = [2*dX,2*(dX+1)];
nExp = length(snTot);  
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
      
% sets up the required information fields
fcnData = setupFuncReqInfo(handles);
initReqGroups(hFig,fcnData)

% retrieves the compatibility data
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

% --- initialises the filter tree
function initFilterTree(handles)

% imports the checkbox tree
import com.mathworks.mwswing.checkboxtree.*

% parameters
dX = 5;
fldStr = {'Analysis Scope','Duration Requirements',...
          'Region Shape Requirements','Stimuli Requirements',...
          'Special Requirements'};

% field retrieval
hFig = handles.figFuncComp;
hPanel = handles.panelFuncFilter;
rGrp = getappdata(hFig,'reqGrp');
rFld = fieldnames(rGrp);

% creates the root node
jRoot = DefaultCheckBoxNode('Function Requirement Categories');
jRoot.setSelectionState(SelectionState.SELECTED);

% creates all the requirement categories and their sub-nodes
for i = 1:length(rFld)
    % retrieves the sub 
    rVal = getStructField(rGrp,rFld{i});
    if length(rVal) > 1
        % sets the requirement type node
        jTreeR = DefaultCheckBoxNode(fldStr{i});
        jRoot.add(jTreeR);
        jTreeR.setSelectionState(SelectionState.SELECTED);    
        
        % adds on each sub-category for the requirements node
        for j = 1:length(rVal)
            jTreeSC = DefaultCheckBoxNode(rVal{j});
            jTreeR.add(jTreeSC);
            jTreeSC.setSelectionState(SelectionState.SELECTED);
        end
    end
end

% retrieves the object position
objP = get(hPanel,'position');

% creates the final tree explorer object
jTree = com.mathworks.mwswing.MJTree(jRoot);
jTreeCB = handle(CheckBoxTree(jTree.getModel),'CallbackProperties');
jScrollPane = com.mathworks.mwswing.MJScrollPane(jTreeCB);

% creates the scrollpane object
wState = warning('off','all');
[~,~] = javacomponent(jScrollPane,[dX-[1 0],objP(3:4)-2*dX],hPanel);
warning(wState);

% resets the cell renderer
jTree.setEnabled(false)
jTree.repaint;

% sets the callback function for the mouse clicking of the tree structure
set(jTreeCB,'MouseClickedCallback',{@treeUpdateClick,hFig,jRoot},...
            'TreeCollapsedCallback',{@treeCollapseClick,hFig},...
            'TreeExpandedCallback',{@treeExpandClick,hFig})        

resetTreePanelPos(hFig,jTree.getMaximumSize.getHeight)                

% sets the tree object into the gui
setappdata(hFig,'jTree',jTree)
setappdata(hFig,'jRoot',jRoot)       

% --- initialises the requirement grouping information
function initReqGroups(hFig,fcnData)

% initialisations
rGrp = struct();
rType = {'Scope','Dur','Shape','Stim','Spec'};

% retrieves the requirement information for each type
for i = 1:length(rType)
    switch rType{i}
        case 'Scope'
            rGrpNw = {'Individual','Single Expt','Multi Expt'}';
            
        otherwise
            reqDataU = unique(fcnData(:,i+1));
            ii = strcmp(reqDataU,'None');    
            rGrpNw = [reqDataU(ii);reqDataU(~ii)];
    end
       
    % appends the field to the data struct
    rGrp = setStructField(rGrp,rType{i},rGrpNw);
end

% updates the requirement group info into the struct
setappdata(hFig,'reqGrp',rGrp)
setappdata(hFig,'fcnData',fcnData)

% --- sets up the function requirement information
function reqData = setupFuncReqInfo(handles)

% initialisations
nCol = 6;
hFig = handles.figFuncComp;
pData = getappdata(hFig,'pData');

% retrieves the plotting function data (first expt only)
pDataT = cell2cell(cellfun(@(x)(x(:,1)),pData,'un',0));

% other initialisations
reqData = cell(length(pDataT),nCol); 
pFld = fieldnames(pDataT{1}.rI); 

% sets the 
for i = 1:length(pDataT)
    % sets the experiment name
    reqData{i,1} = pDataT{i}.Name; 
    
    % sets the other requirement fields
    for j = 1:(length(pFld)-1)
        reqData{i,j+1} = getStructField(pDataT{i}.rI,pFld{j}); 
    end 
end

% determines the unique analysis functions
[~,iB,~] = unique(reqData(:,1));
reqData = reqData(iB,:);

% --- sets up the function compatibility information
function setupExptInfo(handles)

% parameters
nReq = 4;
tLong = 12;

% field retrieval
hFig = handles.figFuncComp;
snTot = getappdata(hFig,'snTot');

% memory allocation
nExp = length(snTot);
fcnInfo = cell(nExp,nReq);

% other initialisations
expStr = {'1D','2D'};
durStr = {'Short','Long'};
[iMov,stimP] = field2cell(snTot,{'iMov','stimP'});

% calculates the experiment duration in terms of hours
Ts = arrayfun(@(x)(x.T{1}(1)),snTot);
Tf = arrayfun(@(x)(x.T{end}(length(x.T{end}))),snTot);
Texp = convertTime(Tf-Ts,'s','h');

% sets the duration string
fcnInfo(:,1) = arrayfun(@(x)(durStr{1+(x>tLong)}),Texp,'un',0);

% for each of the experiments, strip out the important information fields
% from the solution file data
for iExp = 1:nExp
    % experiment shape string
    fcnInfo{iExp,2} = expStr{1+iMov{iExp}.is2D};
    if ~isempty(iMov{iExp}.autoP)
        fcnInfo{iExp,2} = sprintf('%s (%s)',...
                    fcnInfo{iExp,2},iMov{iExp}.autoP.Type);
    end
    
    % stimuli type string
    if isempty(stimP{iExp})
        fcnInfo{iExp,3} = 'None';
    else
        stimStr = fieldnames(stimP{iExp});
        fcnInfo{iExp,3} = strjoin(stimStr,'/');
    end
    
    % special type string (FINISH ME!)
    fcnInfo{iExp,4} = 'None';    
end

% sets the experiment requirement information into the gui
setappdata(hFig,'fcnInfo',fcnInfo);

% --- resets the category tree dimensions
function resetTreePanelPos(hFig,hghtTree0)

% tree height offset (manual hack...)
hghtTree = hghtTree0 + 2;

% object retrieval
handles = guidata(hFig);
hPanel = handles.panelFuncFilter;
hButton = handles.toggleFuncFilter;
hTree = findall(hPanel,'type','hgjavacomponent');

% other initialisations
dX = 5;
hghtPanel = hghtTree + 2*dX;
bPos = getObjGlobalCoord(hButton);

% ressets the tree/panel dimensions
resetObjPos(hPanel,'Height',hghtPanel);
resetObjPos(hPanel,'Bottom',bPos(2)-(hghtPanel+1))
resetObjPos(hTree,'Height',hghtTree)
resetObjPos(hTree,'Bottom',dX)

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
