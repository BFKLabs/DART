function varargout = FlyCombCondInfo(varargin)
% Last Modified by GUIDE v2.5 22-Nov-2016 04:43:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FlyCombCondInfo_OpeningFcn, ...
                   'gui_OutputFcn',  @FlyCombCondInfo_OutputFcn, ...
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

% --- Executes just before FlyCombCondInfo is made visible.
function FlyCombCondInfo_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for FlyCombCondInfo
handles.output = hObject;
hGUI = varargin{1};
if length(varargin) > 1
    % sets the solution array
    [snTot,h] = deal(varargin{2},varargin{3});
    
    % sets the sub-region data struct
    hGUIF = hGUI.figFlyCombine;
    setappdata(hObject,'iMov',getappdata(hGUIF,'iMov'))
    
else
    % sets an empty solution array
    snTot = [];
    
    % sets the sub-region data struct
    setappdata(hObject,'iMov',hGUI.iMov)
    set(hObject,'CloseRequestFcn',{@closeGUI,handles});
end

% retrieves the position of the parent and current objects
resetObjPos(hObject,'left',-1000);
setObjVisibility(hObject,'on')

% sets the main GUI and combined solution file data struct
setappdata(hObject,'hGUI',hGUI)
setappdata(hObject,'snTot',snTot)

% initialises the GUI objects
initGUIObjects(handles)
if (~isempty(snTot))
    % calculates the fly metrics
    initFlyInfo(handles,h)
    
    % retrieves the panel/popupmenu position
    pPos = get(handles.panelFlyInfo,'position');
    ppPos = get(handles.popupFlyInfo,'Position');
    
    % resets the object positions
    resetObjPos(hObject,'height',ppPos(4)+5,1);
    resetObjPos(handles.popupFlyInfo,'bottom',pPos(4)-5)
    resetObjPos(handles.panelFlyInfo,'height',ppPos(4)+5,1);
    
    % initialises the popup menu properties
    set(handles.popupFlyInfo,'Value',1);
    popupFlyInfo_Callback(handles.popupFlyInfo, [], handles)    
else
    % deletes the popup menu
    delete(handles.popupFlyInfo)        
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes FlyCombCondInfo wait for user response (see UIRESUME)
% uiwait(handles.figFlyInfoCond);

% --- Outputs from this function are returned to the command line.
function varargout = FlyCombCondInfo_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- function that runs when closing the GUI with close icon
function closeGUI(hObject, eventdata, handles)

% retrieves the background estimate GUI handles
obj = getappdata(handles.figFlyInfoCond,'hGUI');

% unchecks the menu item and reset the information GUI array
set(obj.hGUI.menuFlyAccRej,'checked','off');
obj.hInfo = [];

% deletes the GUI
delete(handles.figFlyInfoCond);

% --- Executes on selection change in popupFlyInfo.
function popupFlyInfo_Callback(hObject, eventdata, handles)

% retrieves the number of apparatus
iMov = getappdata(handles.figFlyInfoCond,'iMov');

%
hSP = findall(handles.figFlyInfoCond,'type','hgjavacomponent');
if (isa(hSP,'matlab.ui.container.internal.JavaWrapper'))
    hSP = hSP.JavaPeer;
end

% sets the cell selection callback function (non background estimate)
try
    jTab = getJavaTable(hSP);
catch
    setObjVisibility(handles.figFlyInfoCond,'on')
    jTab = getJavaTable(hSP);
end

% seperator string
[jSP,cFunc] = deal(findjobj(hSP),[]);
Status = combineNumericCells(iMov.Status);
Status(isnan(Status)) = 3;

% sets the table enabled flags and data
switch (get(hObject,'Value'))
    case (1) % case is setting reject/accept check boxes
        tabData = num2cell(logical(getappdata(handles.figFlyInfoCond,'ok')));
        
    case (2) % case is the max inactive time
        tInact = getappdata(handles.figFlyInfoCond,'tInact');                
        tabData = cellfun(@(x)(sprintf('%i',x)),num2cell(tInact),'un',0);
        tabData(Status == 3) = {'N/A'};        
        cFunc = {@tableFlyInfo_CellSelectionCallback,handles};                                
        
    case (3) % case is the number of NaN locations       
        % sets the table to 
        nNaN = getappdata(handles.figFlyInfoCond,'nNaN');
        tabData = cellfun(@(x)(sprintf('%.2f%s%s',x,char(37))),...
                                    num2cell(nNaN),'un',0); 
        tabData(nNaN == 0) = {'--------'};
        tabData(Status == 3) = {'N/A'};
        cFunc = {@tableFlyInfo_CellSelectionCallback,handles};   
        
end
    
% updates the table properties
addJavaObjCallback(jTab,'MousePressedCallback',cFunc)                

% updates the table
tabData = setupDataArray(iMov,tabData);
setupTableObject(tabData,1+(get(hObject,'Value')>1),handles,jSP);
    
% --- Executes when entered data in editable cell(s) in tableFlyInfo.
function tableFlyInfo_CellEditCallback(hObject, eventdata, handles)

% global variables
global isPlotAll

% sets the cell selection callback function (non background estimate)
indNw = [eventdata.getFirstRow+1,eventdata.getColumn+1];

% retrieves the java table object handle
if (verLessThan('matlab','8.4'))
    jTab = getJavaTable(findall(handles.figFlyInfoCond,'type','hgjavacomponent'));
else
    aa = findall(handles.figFlyInfoCond,'UserData','javax.swing.JScrollPane');
    jTab = getJavaTable(aa.JavaPeer);    
end

% retrieves the ok flags and the indices of the altered cell
newValue = jTab.getValueAt(indNw(1)-1,indNw(2)-1);
hGUI = getappdata(handles.figFlyInfoCond,'hGUI');
ok = getappdata(handles.figFlyInfoCond,'ok');

% updates the acception/rejection flags
ok(indNw(1),indNw(2)) = newValue;
setappdata(handles.figFlyInfoCond,'ok',ok)

% updates the sub-region data struct
if isfield(hGUI,'figFlyCombine')
    % if the apparatus being updating is also being shown on the combined
    % solution viewing GUI, then update the figure
    if isPlotAll
        hPos = findobj(hGUI.figFlyCombine,'UserData',indNw(2),'Tag','hPos');
        setObjVisibility(hPos,eventdata.NewData);        
    else
        iApp = get(hGUI.popupAppPlot,'value');    
        if iApp == indNw(2)
            appPara = getappdata(hGUI.figFlyCombine,'appPara');
            if (appPara.ok(indNw(2)))
                hPos = findobj(hGUI.figFlyCombine,...
                                    'UserData',indNw(1),'Tag','hPos');
                setObjVisibility(hPos,newValue);
            end
        end
    end
else
    % updates the sub-region data struct
    [obj,hGUI] = deal(hGUI,hGUI.hGUI);
    obj.iMov.flyok = ok;    
    obj.iMov.ok(indNw(2)) = any(obj.iMov.flyok(:,indNw(2)));   
        
    % retrieves the tube show check callback function 
    cFunc = getappdata(hGUI.figFlyTrack,'checkShowTube_Callback');
    cFunc2 = get(hGUI.checkFlyMarkers,'Callback');

    % updates the tubes visibility
    hGUI.iMov = obj.iMov;
    cFunc(hGUI.checkShowTube,num2str(...
                            get(hGUI.checkTubeRegions,'value')),hGUI)   
    cFunc2(hGUI.checkFlyMarkers,[])    
end
    
% --- Executes when selected cell(s) is changed in tableFlyInfo.
function tableFlyInfo_CellSelectionCallback(hObject, eventdata, handles)

% retrieves the object handles and the selected row/column indices
hGUI = getappdata(handles.figFlyInfoCond,'hGUI');
[hAx,indNw] = deal(hGUI.figFlyCombine,eventdata.Indices);

% determines the previously selected item and resets it colour
hPosOld = findobj(hAx,'tag','hPos','color','k');
set(hPosOld,'color',getTraceColour(mod(get(hPosOld,'UserData')-1,4)+1));    

% updates the plot linewidths
if (~isempty(indNw) && (get(handles.popupFlyInfo,'value') ~= 1))    
    if (get(hGUI.popupAppPlot,'value') == indNw(2))        
        set(findobj(hAx,'UserData',indNw(1),'Tag','hPos'),'color','k');
    end    
end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the GUI objects to account for the number of flies/apps
function initGUIObjects(handles)

% retrieves combined solution struct and figure position
hGUI = getappdata(handles.figFlyInfoCond,'hGUI');
iMov = getappdata(handles.figFlyInfoCond,'iMov');

% determines the number of apparatus/flies that were used
if (isempty(iMov))
    % loads the total solution struct
    snTot = getappdata(handles.figFlyInfoCond,'snTot');
    [iMov,isChange] = deal(struct,false);
    
    % determines the number of apparatus/flies in the experiment
    nApp = length(snTot.Px);
    [nFly,iMov.nTube] = deal(size(snTot.Px{1},2));
    
    % determines if the apparatus struct is a field. if not,
    if (~isfield(snTot,'appPara'))
        isField = false;
    else
        isField = ~isempty(snTot.appPara);
    end
    
    % sets the apparatus/fly feasibility flags
    if (isField)
        % apparatus data sub-struct exists, so retrieve the parameters
        iMov.ok = snTot.appPara.ok;
        if (isfield(snTot.appPara,'flyok'))
            iMov.flyok = snTot.appPara.flyok;
        else
            % updates
            isChange = true;
            [iMov.flyok,snTot.appPara.flyok] = deal(true(nFly,nApp));            
        end
    else                
        % no apparatus parameter field, so allocate memory
        isChange = true;
        [iMov.ok,snTot.appPara.ok] = deal(true(nApp,1));
        [iMov.flyok,snTot.appPara.flyok] = deal(true(nFly,nApp));
    end 
    
    % if a change is required, then update the solution struct
    if (isChange)
        setappdata(handles.figFlyInfoCond,'snTot',snTot);
    end
    
    % sets the indices to accept
    ind = find(snTot.appPara.ok);
else
    % sets the indices to accept
    ind = 1:length(iMov.ok);
end

% sets the acceptance/rejection flags
ok = iMov.flyok(:,ind);    
if (any(strcmp(fieldnames(hGUI),'figBackEst')))
    ok(:,~iMov.ok) = false;
end
    
% sets the ok flags
setappdata(handles.figFlyInfoCond,'ok',ok);

% sets up the conditional check table
setupCondTable(handles,ok)
                                 
% --- calculates the fly inactivity/false detection counts for all apparatus        
function initFlyInfo(handles,h)
 
% retrieves the ok data and the total solution data
ok = getappdata(handles.figFlyInfoCond,'ok');
snTot = getappdata(handles.figFlyInfoCond,'snTot');
 
% retrieves the dimensions of the apparatus
[Dmin,tBin] = deal(3,10);
[nFly,nApp] = deal(size(ok,1),sum(snTot.appPara.ok));
[nNaN,tInact] = deal(zeros(nFly,nApp));
nFrm = length(cell2mat(snTot.T));

% calculates the NaN counts/inactive times for each apparatus
for i = 1:nApp
    % updates the waitbar figure
    wStrNw = sprintf(['Calculating Combined Dataset Metrics ',...
                      '(Region %i of %i)'],i,nApp);
    h.Update(1,wStrNw,0.8*(i/(nApp+1)));
    
    % retrieves the position/distance travelled values    
    if i == 1
        indB = detTimeBinIndices(cell2mat(snTot.T),tBin);    
    end
    
    % calculates the binned range values
    Px = snTot.Px{i};    
    Dtot = cell2mat(cellfun(@(x)(range(Px(x,:),1)),indB,'un',0));
    
    % calculates the number of NaN locations
    nNaN(1:size(Dtot,2),i) = roundP(100*sum(isnan(Px),1)/nFrm',0.1);
    
    % calculates the inactive times
    fInact = num2cell((Dtot < Dmin) | isnan(Dtot),1);
    iGrp = cellfun(@(x)(getGroupIndex(x)),fInact,'un',false);
    
    % determines which flies were actually inactive, and calculates the
    % inactive times
    ii = ~cellfun(@isempty,iGrp);    
    tInactNw = cellfun(@(y)(max(cellfun(@length,y))),iGrp(ii))';                    
    tInact(ii,i) = roundP(tInactNw*tBin/60,1);

    % clears the arrays
    clear Px Dtot; pause(0.01);
end

% sets the metric values into the main GUI
setappdata(handles.figFlyInfoCond,'snTot',snTot)
setappdata(handles.figFlyInfoCond,'nNaN',nNaN)
setappdata(handles.figFlyInfoCond,'tInact',tInact)

% --- initialises the GUI handles
function setupCondTable(handles,ok)

% java imports
% import javax.swing.UIManager;
import java.awt.font.FontRenderContext;
import java.awt.geom.AffineTransform;

% sets the look and feel component
% newLnF = 'javax.swing.plaf.metal.MetalLookAndFeel';
% newLnF = 'com.sun.java.swing.plaf.windows.WindowsClassicLookAndFeel';
% newLnF = 'com.sun.java.swing.plaf.windows.WindowsLookAndFeel';  
% javax.swing.UIManager.setLookAndFeel(newLnF);  

% creates the font render context object
aTF = javaObjectEDT('java.awt.geom.AffineTransform');
fRC = javaObjectEDT('java.awt.font.FontRenderContext',aTF,true,true);

% ------------------------------------------- %
% --- INITIALISATIONS & MEMORY ALLOCATION --- % 
% ------------------------------------------- %

% initialisations
hFig = handles.figFlyInfoCond;
hPanel = handles.panelFlyInfo;
iMov = getappdata(handles.figFlyInfoCond,'iMov');

% parameters
[fPos,WT,dX] = deal(get(hFig,'Position'),0,10);

% Ensure all drawing is caught up before creating the table
drawnow

% sets the data array and table column names
Data = setupDataArray(iMov,num2cell(ok));

% ---------------------- %
% --- TABLE CREATION --- % 
% ---------------------- %         

% Create table
[jTab,ColumnName] = setupTableObject(Data,1,handles);
rTable = RowNumberTable(jTab);                        
jTab = handle(jTab, 'callbackproperties');

% Create the base panel
hPanelNew = uipanel('Parent',hPanel,'BorderType','none','Clipping','on',...
                    'Units','Normalized','tag','hPanelView');

% Draw table in scroll pane
jScrollPane = javaObjectEDT('javax.swing.JScrollPane',jTab);
jScrollPane.setRowHeaderView(rTable);
jScrollPane.setCorner(jScrollPane.UPPER_LEFT_CORNER,rTable.getTableHeader());

%
wStr = warning('off','all');
[~, hContainer] = javacomponent(jScrollPane, [], hPanelNew);
warning(wStr);

% determines the overall maximum table width
tFont = jTab.getTableHeader.getFont();
for i = 1:length(ColumnName)
    WT = max(WT,tFont.getStringBounds(ColumnName{i}, fRC).getWidth());
end

% sets the table height/width
hOfs = 2*(~verLessThan('matlab','8.4'));
H = jTab.getPreferredSize.getHeight() + 4 + ...
    jTab.getTableHeader().getPreferredSize().getHeight();            
W = rTable.getColumnModel.getColumn(0).getWidth() + ...
    jTab.getPreferredSize.getWidth();
pPos = round([dX dX W (H+hOfs)]);

% sets the object position and locations
set(hFig,'position',[fPos(1:2),pPos(3:4)+2*dX])
set(hPanel,'position',[dX*[1 1],pPos(3:4)]);
set(hPanelNew,'position',[0 0 1 1],'Units','Pixels')
set(hContainer,'Units','Normalized','position',[0 0 1 1])
drawnow;

% resets the finer locations of the table/figure position
resetObjPos(hPanelNew,'left',dX)
resetObjPos(hPanelNew,'bottom',dX)
resetObjPos(hPanel,'width',2*dX,1)
resetObjPos(hPanel,'height',2*dX,1)
resetObjPos(hFig,'width',2*dX,1)
resetObjPos(hFig,'height',2*dX,1)

% --- sets up the boolean array
function Data = setupDataArray(iMov,Data)

% sets the table data array
for i = 1:length(iMov.iR)
    Data((getSRCount(iMov,i)+1):end,i) = {[]};
end

% --- sets up the table jave object
function [jTab,ColumnName] = setupTableObject(Data,Type,h,jScrollPane)

% sets up the column names
ColumnName = cellfun(@(x)(sprintf('Group #%i',x)),...
                        num2cell(1:size(Data,2)),'un',0);

% Create table model
jTabMod = javaObjectEDT('javax.swing.table.DefaultTableModel',Data,ColumnName);
jTabMod = handle(jTabMod, 'callbackproperties');
jTabMod.TableChangedCallback = @obj.onTableModelChanged;

% creates the table objects
jTab = CondCheckTable(jTabMod,Type);

% sets the java object callback functions
addJavaObjCallback(jTabMod,'TableChangedCallback',{@tableFlyInfo_CellEditCallback,h})

% resets the panel viewport
if (nargin == 4)
    try
        jScrollPane.setViewportView(jTab);
        jScrollPane.repaint(jScrollPane.getBounds());
    end
end
