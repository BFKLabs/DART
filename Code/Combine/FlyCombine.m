function varargout = FlyCombine(varargin)
% Last Modified by GUIDE v2.5 02-Nov-2021 21:47:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FlyCombine_OpeningFcn, ...
                   'gui_OutputFcn',  @FlyCombine_OutputFcn, ...
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

% --- Executes just before FlyCombine is made visible.
function FlyCombine_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global mainProgDir isDocked initDock scrSz updateFlag regSz isAnalysis
isAnalysis = false;
[isDocked,initDock] = deal(true);
updateFlag = 2; pause(0.1); 

% retrieves the regular size of the GUI
regSz = get(handles.panelImg,'position');

% creates the load bar
h = ProgressLoadbar('Initialising Data Combining GUI...');

% sets the GUI figure position (top-left corner)
pos = get(hObject,'position');
set(hObject,'position',[10 (scrSz(4)-pos(4)) pos(3) pos(4)]);

% ----------------------------------------------------------- %
% --- FIELD INITIALISATIONS & DIRECTORY STRUCTURE SETTING --- %
% ----------------------------------------------------------- %

% sets the DART object handles (if provided) and the program directory
switch length(varargin) 
    case (0) % case is running full program from command line
        [hDART,ProgDefNew,mainProgDir] = deal([],[],pwd);  
        figName = 'DART Fly Experiment Data Output Program (Test Mode)';
        set(hObject,'name',figName) 
        setappdata(hObject,'hGUIOpen',[])
        
    case (1) % case is running the program from DART main
        % sets the input argument and the open GUI (makes invisible)
        hDART = varargin{1};
        set(hObject,'name','DART Fly Experiment Data Output Program')
                               
        % retrieves the program default struct
        ProgDefNew = getappdata(hDART.figDART,'ProgDefNew');
        setObjVisibility(hDART.figDART,'off')                      
        
    otherwise % case is any other number of input arguments
        % displays an error message
        tStr = 'Data Combining GUI Initialisation Error';
        eStr = ['Error! Incorrect number of input arguments. ',...
                'Exiting Data Combining GUI...'];
        waitfor(errordlg(eStr,tStr,'modal'))
        
        % deletes the GUI and exits the function
        delete(hObject)
        return
end

% sets the input arguments
setappdata(hObject,'iTab',1);
setappdata(hObject,'sInfo',[]);
setappdata(hObject,'hUndock',[]);
setappdata(hObject,'hGUIInfo',[]);
setappdata(hObject,'hDART',hDART);
setappdata(hObject,'iProg',ProgDefNew);

% sets the default input opening files
sDirO = {ProgDefNew.DirSoln,ProgDefNew.DirComb,ProgDefNew.DirComb}';
setappdata(hObject,'sDirO',sDirO);

% sets the function handles into the GUI
setappdata(hObject,'updatePlot',@updatePosPlot)
setappdata(hObject,'postSolnLoadFunc',@postSolnLoadFunc)
setappdata(hObject,'postSolnSaveFunc',@postSolnSaveFunc)
setappdata(hObject,'getInfoFcn',@getCurrentExptInfo); 
setappdata(hObject,'updateInfoFcn',@updateCurrentExptInfo)

% clears the image axis
cla(handles.axesImg); 
axis(handles.axesImg,'off')
cla(handles.axesStim); 
axis(handles.axesStim,'off')

% sets the other object properties
initObjProps(handles)

% % sets up the git menus
% if exist('GitFunc','file')
%     setupGitMenus(hObject)
% end

% initialisations the apparatus data struct
centreFigPosition(hObject);

% closes the loadbar
try; delete(h); end

% Choose default command line output for FlyCombine
handles.output = hObject;

% ensures that the appropriate check boxes/buttons have been inactivated
setObjVisibility(hObject,'on'); pause(0.1);
updateFlag = 0; pause(0.1); 

% initialises the table position
setappdata(hObject,'jObjT',findjobj(handles.tableAppInfo))
setTableDimensions(handles,4,true);

% takes a snapshot of the clear gui
setappdata(hObject,'hProp0',getHandleSnapshot(hObject))

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes FlyCombine wait for user response (see UIRESUME)
% uiwait(handles.figFlyCombine);

% --- Outputs from this function are returned to the command line.
function varargout = FlyCombine_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = [];

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% ------------------ %
% --- LOAD ITEMS --- %
% ------------------ %

% -------------------------------------------------------------------------
function menuLoadExpt_Callback(hObject, eventdata, handles)

% initialisations
hFig = handles.figFlyCombine;
hGUIInfo = getappdata(hFig,'hGUIInfo');

% makes the acceptance flag info gui invisible
if ~isempty(hGUIInfo)
    setObjVisibility(hGUIInfo.hFig,'off');
end

% opens the solution file gui
OpenSolnFile(hFig);

% --------------------------------------------------------------------
function menuSaveSingle_Callback(hObject, eventdata, handles)

% runs the save single experiment file gui
SaveExptFile(handles.figFlyCombine)

% --------------------------------------------------------------------
function menuSaveMulti_Callback(hObject, eventdata, handles)

% runs the save multi experiment file gui
SaveMultiExptFile(handles.figFlyCombine)

% ------------------- %
% --- OTHER ITEMS --- %
% ------------------- %

% -------------------------------------------------------------------------
function menuClearData_Callback(hObject, eventdata, handles)

% prompts the user if they really want to clear all the data
qStr = 'Are you sure you want to clear all the loaded data?';
uChoice = questdlg(qStr,'Clear All Data?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if the user cancelled, then exit the function
    return
end

% resets the combine gui by clearing all objects
resetCombineGUI(handles)

% --- resets the combine GUI objects
function resetCombineGUI(handles)

% global variables
global isUpdating

% field retrieval
hFig = handles.figFlyCombine;
hTabGrp = getappdata(hFig,'hTabGrp');

% other parameters
nRow = 4;
nExp = length(get(hTabGrp,'Children'));

% ------------------------------- %
% --- FIELD RE-INITIALISATION --- %
% ------------------------------- %

% if the information GUI is open, then close it
hGUIInfo = getappdata(hFig,'hGUIInfo');
if ~isempty(hGUIInfo)
    hGUIInfo.closeFigure();
    setappdata(hFig,'hGUIInfo',[]);
end

% resets the other fields
setappdata(hFig,'sInfo',[]);
setappdata(hFig,'iTab',1);

% --------------------------------- %
% --- OBJECT RE-INITIALISATIONS --- %
% --------------------------------- %

% object handles
hPanelO = handles.panelOuter;
hTable = handles.tableAppInfo;
hAx = {handles.axesImg,handles.axesStim};
hPanelP = findall(hPanelO,'type','uipanel');

% ensures the first experiment tab is selected
if get(get(hTabGrp,'SelectedTab'),'UserData') > 1
    isUpdating = true;
    hTab = findall(hTabGrp,'type','uitab','UserData',1);
    set(hTabGrp,'SelectedTab',hTab);
    set(hPanelO,'Parent',hTab);
    pause(0.05)
    isUpdating = false;
end

% removes any subsequent tabs from the tab group
for i = 2:nExp
    % deletes the tab    
    hTabR = findall(hTabGrp,'type','uitab','UserData',i);
    delete(hTabR)
end

% resets the group name table
colHdr = {'Sub-Region Group Name','Include?'};
rowHdr = arrayfun(@(x)(sprintf('Group #%i',x)),(1:nRow)','un',0);
set(hTable,'Data',cell(nRow,2),'RowName',rowHdr,'ColumnName',colHdr,...
           'BackgroundColor',ones(nRow,3))
autoResizeTableColumns(hTable)

% retrieves the valid popup menu, label and editbox object handles
hObjL = [findall(hPanelO,'style','text');...
        findall(hPanelO,'style','edit')];
hObjL = hObjL(arrayfun(@(x)(get(x,'UserData')),hObjL) > 0);
hObjP = findall(hPanelO,'style','popupmenu');

% resets the 
arrayfun(@(x)(set(x,'String','')),hObjL)
arrayfun(@(x)(set(x,'String',' ','Value',1)),hObjP)
arrayfun(@(x)(setPanelProps(x,'off')),hPanelP)

% clears the axes
cellfun(@(x)(cla(x)),hAx);
cellfun(@(x)(axis(x,'off')),hAx);
cellfun(@(x)(delete(findall(x,'tag','hYLbl'))),hAx);

% disables the save/clear data menu items
setObjEnable(handles.menuSaveExpt,'off');
setObjEnable(handles.menuClearData,'off');
setObjEnable(handles.menuPlotData,'off');

% -------------------------------------------------------------------------
function menuProgPara_Callback(hObject, eventdata, handles)

% runs the program preference sub-GUI
hFig = handles.figFlyCombine;
iProg = getappdata(hFig,'iProg');
[iProgNw,isSave] = ProgParaCombine(hFig,iProg);

% updates the data struct (based on the program preference)
if isSave
    setappdata(hFig,'iProg',iProgNw);
end

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

% object handles
hFig = handles.figFlyCombine;

% prompts the user if they wish to close the main gui
qStr = 'Are you sure you want to close the Data Combining GUI?';
uChoice = questdlg(qStr,'Close GUI?','Yes','No','Yes');
if strcmp(uChoice,'Yes')
    % sets the Fly Track GUI to be invisible
    hDART = findall(0,'tag','figDART','type','figure');
    
    % deletes the figure and removes all added paths
    hGUIInfo = getappdata(hFig,'hGUIInfo');
    if ~isempty(hGUIInfo)
        hGUIInfo.closeFigure();
    end
        
    % sets the Fly Track GUI to be invisible
    delete(hFig)
    setObjVisibility(hDART,'on');    
end

% -------------------------------- %
% --- PLOTTING DATA MENU ITEMS --- %
% -------------------------------- %

% -------------------------------------------------------------------------
function menuViewXData_Callback(hObject, eventdata, handles)

% updates the view menu properties and the viewing axes
updateViewMenu(handles,hObject)

% -------------------------------------------------------------------------
function menuViewYData_Callback(hObject, eventdata, handles)

% updates the view menu properties and the viewing axes
updateViewMenu(handles,hObject)

% -------------------------------------------------------------------------
function menuViewXYData_Callback(hObject, eventdata, handles)

% updates the view menu properties and the viewing axes
updateViewMenu(handles,hObject)

% -------------------------------------------------------------------------
function menuOrientAngle_Callback(hObject, eventdata, handles)

% updates the view menu properties and the viewing axes
updateViewMenu(handles,hObject)

% -------------------------------------------------------------------------
function menuAvgSpeedIndiv_Callback(hObject, eventdata, handles)

% updates the view menu properties and the viewing axes
updateViewMenu(handles,hObject)

% -------------------------------------------------------------------------
function menuAvgSpeedGroup_Callback(hObject, eventdata, handles)

% updates the view menu properties and the viewing axes
updateViewMenu(handles,hObject)

%-------------------------------------------------------------------------%
%                       TOOLBAR CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% -------------------------------------------------------------------------
function toggleZoom_ClickedCallback(hObject, eventdata, handles)

%
if (strcmp(get(hObject,'State'),'on'))
    zoom on
else
    zoom off
end

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ----------------------------- %
% --- MAIN FIGURE CALLBACKS --- %
% ----------------------------- %

% --- Executes when figFlyCombine is resized.
function figFlyCombine_ResizeFcn(hObject, eventdata, handles)

% global variables
global updateFlag uTime

% resets the timer
uTime = tic;

% dont allow any update (if flag is set to 2)
if updateFlag ~= 0
    return
else
    updateFlag = 2;
    while toc(uTime) < 0.5
        java.lang.Thread.sleep(10);
    end
end

% parameters
[pPos,Y0] = deal(get(handles.panelExptOuter,'position'),10);
[Wmin,Hmin] = deal(1000,pPos(4)+2*Y0);

% retrieves the final position of the resized GUI
fPos = getFinalResizePos(hObject,Wmin,Hmin);

% otherwise, update the figure position
resetFigSize(handles,fPos)

% makes the figure visible again
updateFlag = 2;
setObjVisibility(hObject,'on');

% ensures the figure doesn't resize again (when maximised)
pause(0.5);
updateFlag = 0;

% ------------------------------------ %
% --- EXPT TAB SELECTION CALLBACKS --- %
% ------------------------------------ %

% --- callback function for selecting the protocol tabs
function tabSelected(hObj, eventdata, handles)

% global variables
global updateFlag isUpdating

% if updating elsewhere, then exit the function
if isUpdating; return; end

% object retrieval
hFig = handles.figFlyCombine;
sInfo = getappdata(hFig,'sInfo');
hGUIInfo0 = getappdata(hFig,'hGUIInfo');

% deletes any previous information GUIs
if isempty(sInfo)
    % no data is loaded, so exit function
    return
    
elseif ~isempty(hGUIInfo0)
    if ~isempty(eventdata)
        % if the tab has not changed, then exit the function
        if hGUIInfo0.iTab == get(hObj,'UserData')
            return
        end

        % update the solution flags and closes the gui 
        hGUIInfo0.updateSolutionFlags();
    end
    
    % closes the figure
    hGUIInfo0.closeFigure(); 
end

% makes the GUI visible
setObjVisibility(hFig,'off'); pause(0.05);

% creates the progress loadbar
h = ProgressLoadbar('Updating Experiment Information...');

% retrieves the selected tab object (if not provided)
if isempty(hObj)
    hTabGrp = getappdata(hFig,'hTabGrp');
    hObj = get(hTabGrp,'SelectedTab');
end

% resets the outer panel parent
set(handles.panelOuter,'Parent',hObj)

% creates a variable region information GUI
sInfo = getCurrentExptInfo(hFig);
hGUIInfo = FlyInfoGUI(handles,sInfo.snTot,[],false);   
setappdata(hFig,'hGUIInfo',hGUIInfo);

% resets the experiment information fields
updateExptInfoFields(handles,sInfo)
updatePlotObjects(handles,sInfo)
updateGroupInfo(handles,sInfo)

% resets the marker
hPanelF = handles.panelFinishTime;
hPopup = findall(hPanelF,'Style','popupmenu','UserData',1);
popupTimeVal(hPopup, [], handles)

% makes the GUI visible
updateFlag = 0;
setObjVisibility(hGUIInfo.hFig,'on');
figFlyCombine_ResizeFcn(hFig,[],handles)
pause(0.05);

% closes the loadbar
try; delete(h); end

% --- executes on update editSolnDir
function editSolnDir_Callback(hObject, eventdata, handles)

% object retrieval
hFig = handles.figFlyCombine;
sInfo = getappdata(hFig,'sInfo');

% retrieves the current string/experiment index
nwStr = get(hObject,'String');
iExp = get(get(getappdata(hFig,'hTabGrp'),'SelectedTab'),'UserData');

% determines if the new experiment name is valid
if checkNewExptName(sInfo,nwStr,iExp)
    % if so, then update the data struct
    sInfo{iExp}.expFile = nwStr;
    setappdata(hFig,'sInfo',sInfo)
else
    % resets the experiment name to the last valid name
    set(hObject,'String',sInfo{iExp}.expFile)
end

% --- resets the plot objects
function updatePlotObjects(handles,sInfo)

% global variables
global xLimTot yLimTot pStep

% field retrieval
snTot = sInfo.snTot;
hFig = handles.figFlyCombine;
[hAx,iMov] = deal(handles.axesImg,snTot.iMov);
[~,lblSize] = detCombineFontSizes(handles);

% pauses to update the GUI
pause(0.05);

% sets the time multiplier
calcPhi = isfield(snTot,'Phi');
Tmlt = getTimeScale(snTot.T{end}(end));
nFrm = sum(cellfun(@length,snTot.T));

% recalculates the global variables
nFly = getMaxPlotObjCount(iMov);
xLimTot = [snTot.T{1}(1) snTot.T{end}(end)]*Tmlt;
yLimTot = [1 nFly]+0.5*[-1 1];
pStep = 10^max(floor(log10(nFrm))-3,0);

% sets up the popup menu strings
if iMov.is2D
    % case is the 2D experimental setup
    xiC = 1:iMov.pInfo.nCol;
    popStr = arrayfun(@(x)(sprintf('Column #%i',x)),xiC(:),'un',0);
else
    % case is the 1D experimental setup
    popStr = setup1DRegionNames(iMov.pInfo,1);
end

% initialises the popup menu
set(handles.popupAppPlot,'string',popStr,'value',1)

% sets the bin indices
ii = 1:pStep:nFrm;
T = cell2mat(snTot.T); T = T(ii);
isDay = cell2mat(snTot.isDay'); 
snTot.isDay = {isDay(ii)};

% updates the axis x-limits
xLim0 = Tmlt*[0 T(end)];
xLim = xLim0 + 0.001*diff(xLim0)*[-1 1];
set(hAx,'xlim',xLim)

% resets the horizontal limits of the plot objects
tStr = {'hPos','hPos2','hGrpFill','hSep'};
for i = 1:length(tStr)
    hObjAx = findall(hAx,'tag',tStr{i});
    if ~isempty(hObjAx)
        switch tStr{i}
            case 'hGrpFill'
                ix = [1,1,2,2,1];
                arrayfun(@(x)(set(x,'xdata',xLim(ix))),hObjAx);
            otherwise
                arrayfun(@(x)(set(x,'xdata',xLim)),hObjAx);
        end
    end
end

% sets the scale factor (newer versions will have this value)
if isfield(snTot.sgP,'sFac')
    % scale factor is present, so use it
    sFac = snTot.sgP.sFac;
else
    % otherwise, use a value of unity
    sFac = 1;
end

% memory allocation
[Px,Py,V] = deal(cell(1,length(snTot.Px)));
if calcPhi; Phi = Px; end

% sets the acceptance flags (dependent on expt setup type)
if iMov.is2D
    % case is a 2D setup
    isOK = any(iMov.flyok,1);
else
    % case is a 1D setup
    isOK = ~strcmp(sInfo.gName,'* REJECTED *');
end

% sets the fly time/x-coordinate arrays
for i = 1:length(Px)
    if isOK(i)
        Px{i} = snTot.Px{i}(ii,:)/sFac; 
        if iMov.is2D
            % if 2D analysis, then set the y-locations as well
            Py{i} = snTot.Py{i}(ii,:)/sFac; 
            if i == 1; T = T(1:(end-1)); end        
        end

        % calculates the population speed
        V{i} = calcPopVel(T,Px{i},Py{i},iMov.flyok(:,i));

        % sets the orientation angles (if calculated)
        if calcPhi; Phi{i} = snTot.Phi{i}(ii,:); end
    end
end

% if the total number of flies is low, then remove 
setObjEnable(handles.popupAppPlot,'on')

% sets the plot time/locations into the main GUI
setappdata(hFig,'T',T)
setappdata(hFig,'Px',Px)
setappdata(hFig,'Py',Py)
setappdata(hFig,'V',V)

% sets the orientation angles (if they were calculated)
if calcPhi; setappdata(hFig,'Phi',Phi); end

% sets the absolute time values on the time scale
setAbsTimeAxis(hAx,T,snTot)

% resets the axis properties
set(hAx,'ytick',(1:nFly)','yLim',[1 nFly] + 0.5*[-1 1],'linewidth',1.5)
resetXTickMarkers(hAx);

if iMov.is2D
    lblStr = 'Grid Row Number';
else
    lblStr = 'Sub-Region Index';
end

% updates the axis/label properties
hLbl = ylabel(hAx,lblStr,'FontUnits','pixels','tag','hYLbl');
set(hLbl,'fontweight','bold','fontsize',lblSize,'UserData',lblStr)
axis(hAx,'ij')

% sets the axes units to normalised
set(hAx,'Units','Normalized')
axis(hAx,'on')

% updates the menu properties
setObjEnable(handles.menuPlotData,'on')
updateViewMenu(handles,handles.menuViewXData,1)
setObjEnable(handles.menuViewYData,snTot.iMov.is2D)
setObjEnable(handles.menuViewXYData,snTot.iMov.is2D)

% updates the position plot
updatePosPlot(handles,1)

% initialises/resets the limit markers
updateLimitMarkers(handles)

% adds in the stimuli axes panels (if stimuli are present)
addStimAxesPanels(handles,snTot.stimP,snTot.sTrainEx,T([1 end]));

% --- resets the experiment information fields
function updateExptInfoFields(handles,sInfo)

% updates the experiment/solution file information
exFld = fieldnames(sInfo.expInfo);
for i = 1:length(exFld)
    hTxt = findall(handles.panelOuter,'tag',sprintf('text%s',exFld{i}));
    if ~isempty(hTxt)
        set(hTxt,'String',getStructField(sInfo.expInfo,exFld{i}));
    end
end

% sets the solution directory tooltip string
set(handles.editSolnDir,'String',sInfo.expFile)

% updates 
if sInfo.iTab == 1
    % case is data was loaded from video solution files
    set(handles.editSolnDirL,'string','Data Directory: ')
    set(handles.textSolnType,'string','Video Solution File Directory')    
else
    % case is data was loaded from a single/multi-experiment solution file
    set(handles.editSolnDirL,'string','Data File: ')
    set(handles.textSolnType,'string','Experiment Solution File')    
end

% sets the visibility of the orientation angle menu item
setObjVisibility(handles.menuOrientAngle,isfield(sInfo.snTot,'Phi'))

% enables all the expt information panels
setPanelProps(handles.panelSolnData,'on');
setPanelProps(handles.panelExptInfo,'on');
setPanelProps(handles.panelExptDur,'on');

% --- updates the apparatus name table panel --- %
function updateGroupInfo(handles,sInfo)

% parameters and other initialisations
nAppMx = 9;
[X0,Y0] = deal(10,10);
snTot = sInfo.snTot;
hFig = handles.figFlyCombine;
hTabGrp = getappdata(hFig,'hTabGrp');

% sets the group name strings
if snTot.iMov.is2D
    [cHdr0,gStr] = deal('2D Arena Grouping Names','Column');
else
    [cHdr0,gStr] = deal('1D Region Grouping Names','Region');
end

% sets the table information
iok = snTot.iMov.ok(:);
Data = [sInfo.gName(:) num2cell(iok)];

% sets the table row headers
if snTot.iMov.is2D
    lblStr = 'Group Name: ';
    rowName = cellfun(@(x)(sprintf('%s #%i',gStr,x)),...
                            num2cell(1:size(Data,1)),'un',0);  
else
    lblStr = 'Region Location: ';
    rowName = setup1DRegionNames(snTot.iMov.pInfo,2);
end

% sets the initial time location properties
initTimeLocationProps(handles,handles.panelStartTime,sInfo.iPara.Ts)
initTimeLocationProps(handles,handles.panelFinishTime,sInfo.iPara.Tf)
initExptDurProps(handles,handles.panelExptDur,sInfo);

% retrieves the height of the popup object
pApp = get(handles.popupAppPlot,'position'); 
pPosD = get(handles.panelExptDur,'position');
pPosT = get(handles.panelAppInfo,'position');

% updates the group name table information
cHdr = {cHdr0,'Include?'};
bgCol = getTableBGColours(handles,sInfo);
setObjEnable(handles.tableAppInfo,~isempty(snTot))
set(handles.tableAppInfo,'RowName',rowName,'ColumnName',cHdr,...
                         'Data',Data,'BackgroundColor',bgCol)                                         
             
% updates the table information
evnt = struct('Indices',[1,1],'NewData',Data{1,1});
tableAppInfo_CellEditCallback(handles.tableAppInfo, evnt, handles)                    

% resets the panel/panel object positions  
nAppF = min(size(Data,1),nAppMx);
[tPos,Hpop] = deal(setTableDimensions(handles,nAppF,0),pApp(4));

% sets the final table/panel position vectors
pAppF = [X0 0 (tPos(3)+2*X0) (tPos(4)+4*Y0+Hpop)];
pAppF(2) = pPosD(2) - (pAppF(4) + Y0);
set(handles.panelAppInfo,'Position',pAppF)

% moves the apparatus text/popup objects
set(handles.textAppPlot,'String',lblStr)
resetObjPos(handles.textAppPlot,'bottom',2*Y0+tPos(4))
resetObjPos(handles.popupAppPlot,'bottom',2*Y0+tPos(4)-3)

% resets all the panel bottom locations
dH = (pPosT(4)-pAppF(4));
hPanel = [findobj(handles.panelOuter,'type','uipanel');...
          findobj(handles.panelOuter,'type','uibuttongroup')];
resetObjPos(handles.panelOuter,'height',-dH,1)
for i = 1:length(hPanel)
    if strcmp(get(hPanel(i),'tag'),'panelOuter')
        resetObjPos(hPanel(i),'bottom',dH,1)        
    else
        resetObjPos(hPanel(i),'bottom',-dH,1)
    end
end

% resets the dimensions of the objects
resetObjPos(hTabGrp,'Height',-dH,1)
resetObjPos(handles.panelOuter,'Bottom',-dH,1);
resetObjPos(handles.panelExptOuter,'Height',-dH,1);
resetObjPos(handles.panelExptOuter,'Bottom',dH,1);
resetObjPos(hFig,'Height',-dH,1);

% --------------------------------------------- %
% --- POSITION PLOT MARKER OBJECT CALLBACKS --- %
% --------------------------------------------- %

% --- Executes on selection change in popupAppPlot.
function popupAppPlot_Callback(hObject, eventdata, handles)

% updates the axis plot (if there are suitable apparatus set)
if ~isempty(get(hObject,'string'))
    updatePosPlot(handles)
end
    
% --------------------------------------------- %
% --- APPARATUS INFORMATION TABLE CALLBACKS --- %
% --------------------------------------------- %

% --- Executes when entered data in editable cell(s) in tableAppInfo.
function tableAppInfo_CellEditCallback(hObject, eventdata, handles)

% retrieves the cell indices
hFig = handles.figFlyCombine;
sInfo = getCurrentExptInfo(hFig);
hGUIInfo = getappdata(hFig,'hGUIInfo');

% other initialisations
Data = get(hObject,'Data');
[indNw,nwData] = deal(eventdata.Indices,eventdata.NewData);

% removes the selection highlight
wState = warning('off','all');
jScroll = findjobj(hObject);
jTable = jScroll.getComponent(0).getComponent(0);
jTable.changeSelection(-1,-1,false,false);
warning(wState);

% determines if the region is rejected
switch indNw(2)
    case 1
        if isprop(eventdata,'PreviousData')
            isRejected = strcmp(eventdata.PreviousData,'* REJECTED *');
        else
            isRejected = false;
        end
        
    case 2
        isRejected = strContains(Data{indNw(1),1},'* REJECTED *');
end

% determines if the region is reject. if so, then revert back to the
% previous data (while outputting a message to screen)
if isRejected
    if sInfo.snTot.iMov.is2D
        gStr = 'group';
    else
        gStr = 'region';
    end
    
    % output the message to screen
    mStr = sprintf('This %s is rejected and cannot be altered.',gStr);
    waitfor(msgbox(mStr,'Update Issue'));
    
    % resets the table data and exits the function
    Data{indNw(1),indNw(2)} = eventdata.PreviousData;
    set(hObject,'Data',Data)
    return
end
    
% sets the new values into the data struct
switch indNw(2)
    case (1) 
        % case is the group name string
        if ~strContains(nwData,',')
            % updates the group name and background colours
            sInfo.gName{indNw(1)} = nwData; 
            updateCurrentExptInfo(hFig,sInfo);           
            
        else
            % apparatus name is invalid so output an error
            eStr = 'Region names strings can''t contain a comma';
            waitfor(errordlg(eStr,'Region Naming Error','modal'))
            
            % resets the table values
            Data{indNw(1),indNw(2)} = sInfo.gName{indNw(1)};
            set(hObject,'Data',Data);
            return
        end
        
    case (2) 
        % case is the inclusion flag
                
        % updates the apparatus data struct
        sInfo.snTot.iMov.ok(indNw(1)) = nwData;        
        updateCurrentExptInfo(hFig,sInfo);
        
        % updates the position plot axes
%         updatePosPlot(handles)   
        updateGroupColours(handles,indNw,nwData)
end

% resets the table background colours
bgCol = getTableBGColours(handles,sInfo);
set(hObject,'BackgroundColor',bgCol)

% determines if the individual fly info gui is open            
if ~isempty(hGUIInfo)
    % if so, then update the grouping colours
    jT = hGUIInfo.jTable;
    for j = 1:size(bgCol,1)
        % sets the new background colour
        nwCol = getJavaColour(bgCol(j,:));

        % updates the colours                
        if sInfo.snTot.iMov.is2D
            % case is a 2D experiment setup
            if isfield(sInfo.snTot.iMov,'pInfo')
                [iRow,iCol] = find(sInfo.snTot.iMov.pInfo.iGrp == j);
            else
                iRow = 1:size(sInfo.snTot.iMov.flyok);
                iCol = j*ones(size(iRow));
            end

            % updates the colours
            for i = 1:length(iRow)
                jT.SetBGColourCell(iRow(i)-1,iCol(i)-1,nwCol);
            end

        else
            % case is a 1D experiment setup
            for i = 1:size(sInfo.snTot.iMov.flyok,1)
                jT.SetBGColourCell(i-1,j-1,nwCol);
            end
        end
    end

    % updates the table
    jT.repaint();
end

% updates the location/speed plots
updatePosPlot(handles)

% ----------------------------------------- %
% --- START/FINISH TIME POINT CALLBACKS --- %
% ----------------------------------------- %

% --- Executes on button press in buttonStartReset.
function buttonStartReset_Callback(hObject, eventdata, handles)

% global variables
global xLimTot

% retrieves the currently selected solution file data
hFig = handles.figFlyCombine;
sInfo = getCurrentExptInfo(hFig);

% retrieves the parameter struct
[sInfo.iPara.Ts,sInfo.iPara.indS] = deal(sInfo.iPara.Ts0,[1 1]);
txtStart = datestr(sInfo.iPara.Ts0,'mmm dd, YYYY HH:MM AM');
updateCurrentExptInfo(hFig,sInfo);

% resets to the start time string
resetPopupFields(handles.panelStartTime,sInfo.iPara.Ts)
resetLimitMarker(handles.axesImg,xLimTot(1)*[1 1],'Start')
set(handles.textStartTime,'string',txtStart)

% --- Executes on button press in buttonFinishReset.
function buttonFinishReset_Callback(hObject, eventdata, handles)

% global variables
global xLimTot

% retrieves the parameter struct
hFig = handles.figFlyCombine;
sInfo = getCurrentExptInfo(hFig);

% updates the end flag values
sInfo.iPara.Tf = sInfo.iPara.Ts0;
sInfo.iPara.indF = [length(sInfo.snTot.T) length(sInfo.snTot.T{end})];
updateCurrentExptInfo(hFig,sInfo)

% resets to the finish time
txtFinish = datestr(sInfo.iPara.Tf0,'mmm dd, YYYY HH:MM AM');
resetPopupFields(handles.panelFinishTime,sInfo.iPara.Tf)
resetLimitMarker(handles.axesImg,xLimTot(2)*[1 1],'Finish')
set(handles.textFinishTime,'string',txtFinish)

% --- Executes on selection change in popupStartDay.
function popupTimeVal(hObject, eventdata, handles)

% retrieves the index of the month that was selected
hFig = handles.figFlyCombine;
iSel = get(hObject,'Value');
iType = get(hObject,'UserData');
hPanel = get(hObject,'parent');
sInfo = getCurrentExptInfo(hFig);

% calculates the time scale multiplier
Tmlt = getTimeScale(sInfo.snTot.T{end}(end));

% sets the initial start time
Tv0 = cellfun(@(x)(x(1)),sInfo.snTot.T)*Tmlt;
if strcmp(get(get(hObject,'parent'),'tag'),'panelStartTime')
    T0 = sInfo.iPara.Ts;
else
    T0 = sInfo.iPara.Tf;
end

% sets the start time vector
switch iType
    case (2) % case is the month was selected
        % gets the day popup handle
        hDay = findobj(hPanel,'UserData',3,'Style','PopupMenu');
        
        % sets the days in the month (based on the month selected)
        switch iSel
            case (2) % case is February
                dMax = 28;
            case {4,6,9,11} % case is the 30 day months
                dMax = 30;                                
                set(hDay,'string',num2str((1:30)'));
            otherwise % case is the 31 day months
                dMax = 31;                
                
        end
        
        % sets the day strings
        a = num2cell((1:9)');
        dStr = [cellfun(@(x)(sprintf('0%i',x)),a,'un',false);...
                cellfun(@num2str,num2cell(10:dMax)','un',false)];
        
        % ensures the day is at most the maximum value, and resets the day
        % popup menu string list/value
        [T0(3),T0(iType)] = deal(min(T0(3),dMax),iSel);    
        set(handles.popupStartDay,'string',dStr,'Value',T0(3));            
        
    case (3) % case is the day was selected
        % updates the value
        T0(iType) = iSel;
        
    case (4) % case is the hours was selected
        % recalculates the hour
        hAMPM = findobj(hPanel,'UserData',1,'Style','PopupMenu');
        if iSel == 12
            T0(iType) = 12*(get(hAMPM,'Value')-1);
        else
            T0(iType) = 12*(get(hAMPM,'Value')-1) + iSel;
        end
                
    case (5) % case is the minutes was selected
        % updates the value
        T0(iType) = iSel - 1;        
        
    otherwise % case is the AM/PM popup
        % resets the hour value based on the AM/PM popup                
        hHour = findobj(hPanel,'UserData',4,'Style','PopupMenu');
        hVal = get(hHour,'Value');
        
        % updates the hour value
        if hVal == 12
            T0(4) = 12*(iSel-1);
        else
            T0(4) = hVal + 12*(iSel-1);
        end
end

% resets the panel marker
[dTS,dTS0] = deal(calcTimeDifference(T0,sInfo.iPara.Ts0));
if strcmp(get(get(hObject,'parent'),'tag'),'panelStartTime')
    % calculates the time difference between the new time location and the
    % limit markers    
    dTF = calcTimeDifference(sInfo.iPara.Tf,T0);
    
    % checks to see if the new time is valid
    if (dTS < 0) || (dTF < 0)
        % if not, then reset to the previous valid value
        eStr = 'Error! Start time is not valid.';
        waitfor(errordlg(eStr,'Start Time Error','modal'))
        resetPopupFields(handles.panelStartTime,sInfo.iPara.Ts)        
    else
        % otherwise, update the start time/index
        sInfo.iPara.Ts = T0;
        sInfo.iPara.indS(1) = find(Tv0 <= dTS0,1,'last');                
        sInfo.iPara.indS(2) = find(sInfo.snTot.T...
                            {sInfo.iPara.indS(1)}*Tmlt <= dTS0,1,'last');        
        updateCurrentExptInfo(hFig,sInfo);
        
        % resets the limit markers
        resetLimitMarker(handles.axesImg,dTS*[1 1]*Tmlt,'Start')
    end
else
    % calculates the time difference between the new time location and the
    % limit markers    
    dTS = calcTimeDifference(T0,sInfo.iPara.Ts);
    dTF = calcTimeDifference(sInfo.iPara.Tf0,T0);
    
    % checks to see if the new time is valid
    if (dTS < 0) || (dTF < 0)
        % if not, then reset to the previous valid value
        eStr = 'Error! Finish time is not valid.';
        waitfor(errordlg(eStr,'Finish Time Error','modal'))        
        resetPopupFields(handles.panelFinishTime,sInfo.iPara.Tf)
    else
        % otherwise, update the finish time/index
        sInfo.iPara.Tf = T0;
        sInfo.iPara.indF(1) = find(Tv0 <= dTS0,1,'last');                
        sInfo.iPara.indF(2) = find(sInfo.snTot.T{...
                            sInfo.iPara.indF(1)}*Tmlt <= dTS0,1,'last');         
        updateCurrentExptInfo(hFig,sInfo)      
        
        % resets the limit markers
        resetLimitMarker(handles.axesImg,dTS0*[1 1]*Tmlt,'Finish')
    end
end

% --- Executes on editing the experiment duration editboxes
function editExptDur(hObject, eventdata, handles)

% retrieves the currently selected solution file data
hFig = handles.figFlyCombine;
hPanelF = handles.panelFinishTime;
iType = get(hObject,'UserData');
sInfo = getCurrentExptInfo(hFig);
iPara = sInfo.iPara;

% sets the parameter limits
switch iType
    case {1,2}
        % case is the minutes/seconds
        nwLim = [0,60];
   
    otherwise
        % case is the days/hours
        nwLim = [0,inf];
end

% determines if the new value is valid
nwVal = str2double(get(hObject,'String'));
[ok,eStr] = chkEditValue(nwVal,nwLim,1);

% determines if new value is valid
if ok
    % determines if the new experiment duration is valid
    iParaNw = updateFinalTimeVec(handles,iPara);
    if chkExptDur(iParaNw)
        % updates the data struct with the new value and exits
        sInfo.iPara = iParaNw;
        updateCurrentExptInfo(hFig,sInfo)
        
        % updates the final experiment time and plot markers
        resetPopupFields(hPanelF,sInfo.iPara.Tf)        
        hPopup = findall(hPanelF,'Style','popupmenu','UserData',1);
        popupTimeVal(hPopup, [], handles)
        
        % exits the function
        return
    else
        % otherwise, create the error string
        maxFeasDur = vec2str(getMaxExptDur(sInfo));
        currExptDur = vec2str(getCurrentExptDur(iParaNw));
        eStr = sprintf(['Error! The entered experiment duration is ',...
                        'not feasible:\n\n %s Entered Duration = %s',...
                        '\n %s Feasible Duration = %s'],char(8594),...
                        currExptDur,char(8594),maxFeasDur);
    end
end

% outputs the error message to screen
waitfor(msgbox(eStr,'Invalid Experiment Duration','modal'))

% otherwise, reset to the previous value
tExpt0 = getCurrentExptDur(sInfo.iPara);
set(hObject,'string',num2str(tExpt0(iType)));

% --- determines if the current experiment configuration is feasible
function isFeas = chkExptDur(iPara)

isFeas = etime(iPara.Tf0,iPara.Tf) >= 0;

% --- updates the final time vector with the current information
function iPara = updateFinalTimeVec(handles,iPara)

% retrieves the current expt duration (as displayed)
tExpt = getCurrentEditDur(handles);

% updates the experiment finish time vector
Ts = datenum(iPara.Ts);
iPara.Tf = datevec(addtodate(Ts,vec2sec(tExpt),'s'));

% --- retrieves the current experiment duration (as displayed)
function tExpt = getCurrentEditDur(handles)

% retrieves the object handles
tExpt = zeros(1,4);
hPanelD = handles.panelExptDur;

% retrieves the values from the time editboxes
for i = 1:length(tExpt)
    hEdit = findall(hPanelD,'Style','Edit','UserData',i);
    tExpt(i) = str2double(get(hEdit,'String'));
end

% --- retrieves the current maximum experiment duration (in vector form)
function tExptMax = getMaxExptDur(sInfo)

tExptMax = sec2vec(sInfo.tDur-etime(sInfo.iPara.Ts,sInfo.iPara.Ts0));

% --- start/finish limit marker callback function --- %
function moveLimitMarker(pNew,handles,Type,varargin)

% global variables
global xLimTot

% initialisations
pDel = 1e-4;
hFig = handles.figFlyCombine;
sInfo = getCurrentExptInfo(hFig);
T0 = sInfo.snTot.iExpt(1).Timing.T0;
[hAx,xNew] = deal(handles.axesImg,pNew(1,1));

% sets the video start times
Tmlt = getTimeScale(sInfo.snTot.T{end}(end));
Tv0 = cellfun(@(x)(x(1)),sInfo.snTot.T)*Tmlt;

% updates the 
switch Type
    case ('Start')
        % retrieves the finish marker x-location
        hFinish = findobj(hAx,'tag','Finish');        
        pF = get(findobj(hFinish,'tag','top line'),'xData');
        
        % if the start marker exceeds the finish, then reset
        if xNew >= (pF(1) - pDel)
%             % sets the time vector to be below that of the finish
%             TvecNw = sInfo.iPara.Tf;
%             TvecNw(5) = TvecNw(5) - 1;            
%             
            % resets the limit marker
%             xNew = calcTimeDifference(TvecNw,sInfo.iPara.Ts0)*Tmlt;
            xNew = pF(1) - pDel;
        end                
        
        % determines the new marker index value  
        if xNew <= Tv0(1)
            sInfo.iPara.indS = ones(1,2);
        else
            sInfo.iPara.indS(1) = find([Tv0;1e10] <= xNew,1,'last');                
            sInfo.iPara.indS(2) = find([sInfo.snTot.T{...
                        sInfo.iPara.indS(1)}*Tmlt;1e10] <= xNew,1,'last'); 
        end
        
        if (sInfo.iPara.indS(1)*sInfo.iPara.indS(2)) == 1
            % if the first point, set the the original marker point
            sInfo.iPara.Ts = sInfo.iPara.Ts0;            
        else
            % otherwise, calculate the new time string
            TT = sInfo.snTot.T{sInfo.iPara.indS(1)}(sInfo.iPara.indS(2));
            sInfo.iPara.Ts = calcTimeString(T0,TT);
        end
        
        % updates the solution file info
        updateCurrentExptInfo(hFig,sInfo);
        
        % re-calculates the finish marker lower limit
        TvecNw = sInfo.iPara.Ts; 
        TvecNw(5) = TvecNw(5) + 1;
        Ts0 = sInfo.snTot.iExpt.Timing.T0;
        xLimNew = (calcTimeDifference(TvecNw,sInfo.iPara.Ts0) + ...
                   calcTimeDifference(sInfo.iPara.Ts0,Ts0))*Tmlt;        
        
        % resets the popup-values
        resetLimitMarkerRegion(hAx,[xLimNew xLimTot(2)],'Finish')
        resetPopupFields(handles.panelStartTime,sInfo.iPara.Ts)
        
    case ('Finish')
        % retrieves the start marker x-location
        hStart = findobj(hAx,'tag','Start');
        pS = get(findobj(hStart,'tag','top line'),'xData');
               
        % if the start marker exceeds the finish, then reset
        if xNew <= (pS(1) + pDel)
            xNew = pS(1) + pDel;
%             % sets the time vector to be below that of the finish
%             TvecNw = sInfo.iPara.Ts;
%             TvecNw(5) = TvecNw(5) + 1;            
%             
%             % resets the limit marker
%             xNew = calcTimeDifference(TvecNw,sInfo.iPara.Ts0)*Tmlt;
%             resetLimitMarker(hAx,xNew*[1 1],Type)            
        end          

        % sets the final marker index and the final time string 
        sInfo.iPara.indF(1) = find([Tv0;1e10] <= xNew,1,'last');
        sInfo.iPara.indF(2) = find([sInfo.snTot.T{...
                    sInfo.iPara.indF(1)}*Tmlt;1e10] <= xNew,1,'last');                
        sInfo.iPara.Tf = calcTimeString(T0,sInfo.snTot.T{...
                    sInfo.iPara.indF(1)}(sInfo.iPara.indF(2)));        
        updateCurrentExptInfo(hFig,sInfo)
        
        
        % re-calculates the finish marker lower limit
        TvecNw = sInfo.iPara.Tf; 
        TvecNw(5) = TvecNw(5) - 1;
        Ts0 = sInfo.snTot.iExpt.Timing.T0;        
        xLim0 = calcTimeDifference(sInfo.iPara.Ts0,Ts0)*Tmlt;
        xLimNew = calcTimeDifference(TvecNw,sInfo.iPara.Ts0)*Tmlt + xLim0;           
        
        % resets the popup-values
        resetLimitMarkerRegion(hAx,[xLim0 xLimNew],'Start')
        resetPopupFields(handles.panelFinishTime,sInfo.iPara.Tf)
end

% updates the experiment duration
resetExptDurFields(handles.panelExptDur,sInfo);

% --- resets the experiment duration fields
function resetExptDurFields(hPanelD,sInfo)

% calculates the experiment duration
tExpt = getCurrentExptDur(sInfo.iPara);

% sets the properties for each of the editboxes
for i = 1:length(tExpt)       
    % sets the callback function
    hEdit = findall(hPanelD,'UserData',i,'Style','Edit');
    set(hEdit,'String',num2str(tExpt(i))) 
end

% --- resets the popup field values --- %
function resetPopupFields(hPanel,Tvec)
    
% updates the popup-field values
set(findobj(hPanel,'UserData',1),'value',1+(Tvec(4)>=12)) 
set(findobj(hPanel,'UserData',2),'value',Tvec(2))
set(findobj(hPanel,'UserData',3),'value',Tvec(3))
set(findobj(hPanel,'UserData',4),'value',mod(Tvec(4)-1,12)+1)
set(findobj(hPanel,'UserData',5),'value',Tvec(5)+1)

% --- resets the limit marers
function resetLimitMarker(hAx,xNew,Type)

% global variables
global yLimTot

api = iptgetapi(findobj(hAx,'tag',Type));
api.setPosition([xNew',yLimTot']);

% --- resets the limit marker regions
function resetLimitMarkerRegion(hAx,xLimNew,Type)

% global variables
global yLimTot

% sets the constraint/position callback functions
fcn = makeConstrainToRectFcn('imline',xLimNew,yLimTot);
api = iptgetapi(findobj(hAx,'tag',Type));
api.setPositionConstraintFcn(fcn);

% --- re-initialises the plot objects
function resetPlotObjects(handles)

% initialisations
hAx = handles.axesImg;
hFig = handles.figFlyCombine;
[ix,iy,fAlpha] = deal([1,1,2,2,1],[1,2,2,1,1],0.1);
axSize = detCombineFontSizes(handles);

% retrieves the experiment information
sInfo = getappdata(hFig,'sInfo');
nExpt = length(sInfo);

% calculates the max row count over all loaded experiments
nRowMx = zeros(nExpt,1);
for i = 1:nExpt
    nRowMx(i) = getMaxPlotObjCount(sInfo{i}.snTot.iMov);    
end

% determines the overall max row count
nRowMxT = max(nRowMx);

% ------------------------------------ %
% --- PLOTTING AXES INITIALISATION --- %
% ------------------------------------ %

% creates the grouping colour fill objects
xLim = [0,1];
hPos = findall(hAx,'tag','hPos');
has2D = any(cellfun(@(x)(x.is2D),sInfo));

% removes/adds any excess/missing group objects
if length(hPos) > nRowMxT
    % case is there are excess plot markers
    for i = (nRowMxT+1):length(hPos)
        % deletes the 1st position marker
        delete(hPos(i));        
        
        % deletes the 2nd position marker (if it exists)
        hPos2 = findall(hAx,'tag','hPos2','UserData',i);
        if ~isempty(hPos2); delete(hPos2); end        
        
        % deletes the fill object (if it exists)
        hGrpFill = findall(hAx,'tag','hGrpFill','UserData',i);
        if ~isempty(hGrpFill); delete(hGrpFill); end        
        
        %
        if i < length(hPos)
            hSep = findall(hAx,'tag','hSep','UserData',i);
            delete(hSep);
        end
    end

elseif length(hPos) < nRowMxT
    % case is plot objects need to be created
    
    % turns the axes hold on
    hold(hAx,'on');
    
    % adds in the missing plot objects
    for i = (length(hPos)+1):nRowMxT
        % initialises the plot traces
        plot(hAx,NaN,NaN,'color','b','tag','hPos','UserData',i,...
                'LineWidth',0.5,'visible','off');

        % initialises the plot trace for the 2nd plot lines (if 2D)
        if has2D               
            % plots the trace
            plot(hAx,NaN,NaN,'color','r','tag','hPos2','UserData',i,...
                'LineWidth',0.5,'visible','off');                        
        end

        % creates the fill objects
        yy = (i-0.5)+[0,1];
        patch(xLim(ix),yy(iy),'k','FaceAlpha',fAlpha,'tag','hGrpFill',...
                              'UserData',i,'Parent',hAx,'Visible','off');    

        % sets seperation line (if not the last sub-region)
        if i ~= nRowMxT
            plot(hAx,[0,0],(i+0.5)*[1 1],'k','linewidth',1,...
                 'tag','hSep','UserData',i)
        end
    end    

    % releases the hold on the axes
    hold(hAx,'off')
end

% resets the axis properties
dLim = 0.5*[-1 1];
set(hAx,'fontweight','bold','fontsize',axSize,'box','on',...
        'TickLength',[0 0],'linewidth',1.5,'ylim',[1 nRowMxT]+dLim)

% ---------------------------------------------- %
% --- POST SOLUTION FILE LOAD/SAVE FUNCTIONS --- %
% ---------------------------------------------- %
    
% --- function for the after running the solution file loading gui
function postSolnLoadFunc(hFig,sInfoNw)

% performs the actions based on the user input
if ~exist('sInfoNw','var')
    % deletes the figure and removes all added paths
    hGUIInfo = getappdata(hFig,'hGUIInfo');
    if ~isempty(hGUIInfo)
        setObjVisibility(hGUIInfo.hFig,'on');
    end    
    
    % case is the user cancelled
    setObjVisibility(hFig,'on');
    return
end

% retrieves the gui field objects
handles = guidata(hFig);
sInfo0 = getappdata(hFig,'sInfo');
hTabGrp = getappdata(hFig,'hTabGrp');

% other initialisations
isKeep = {true(length(sInfo0),1),true(length(sInfoNw),1)};
if isempty(sInfoNw)
    % case is there the user cleared all the stored data, so flag that all
    % existing data will be removed
    isKeep{1}(:) = false;
elseif ~isempty(sInfo0)
    % determines the indices of the loaded experiments overlapping with the
    % newly loaded solution data
    indEx = cellfun(@(y)(find(cellfun(@(x)...
                            (isequaln(x,y)),sInfoNw))),sInfo0,'un',0);
    isKeep{1}(cellfun(@isempty,indEx)) = false;
    isKeep{2}(setGroup(cell2mat(indEx),size(sInfo0))) = false;
end

% creates the new tab panel
hTab0 = get(hTabGrp,'Children');
nTabT = sum(cellfun(@sum,isKeep));

% updates the gui based on whether there is any loaded data
if nTabT == 0
    % if there are no valid solutions, then clear the combining gui
    resetCombineGUI(handles)
    setObjVisibility(hFig,'on');
    return
else
    % otherwise, update the menu enabled properties
    hTabSel = get(hTabGrp,'SelectedTab');
    setObjEnable(handles.menuSaveExpt,nTabT>0);
    setObjEnable(handles.menuSaveMulti,nTabT>0);
    setObjEnable(handles.menuClearData,nTabT>0);
    setObjEnable(handles.menuPlotData,nTabT>0);
end

if length(hTab0) > nTabT
    % if there are more tabs than required, then remove the excess
    for i = (nTabT+1):length(hTab0)
        hTabR = findall(hTabGrp,'type','uitab','UserData',i);
        if isequal(hTabSel,hTabR)            
            hTabSel = findall(hTabGrp,'type','uitab','UserData',1);  
            set(hTabGrp,'SelectedTab',hTabSel)
            set(handles.panelOuter,'Parent',hTabSel)
            pause(0.05)
        end
        
        % deletes the tab
        delete(hTabR)
    end
else
    % case is tabs need to be added in
    for i = (length(hTab0)+1):nTabT
        tStr = sprintf('Expt #%i',i);
        hTab = createNewTabPanel(hTabGrp,1,'title',tStr,'UserData',i);
        set(hTab,'ButtonDownFcn',{@tabSelected,handles})
    end
end

% updates the solution file data struct
sInfo = [sInfo0(isKeep{1});sInfoNw(isKeep{2})];
if isempty(sInfo)
    setappdata(hFig,'sInfo',[])
else
    [~,iS] = sort(cellfun(@(x)(x.iID),sInfo));
    setappdata(hFig,'sInfo',sInfo(iS))
end

% re-initialises the plot objects
resetPlotObjects(handles)
tabSelected(hTabSel,[],handles);

% makes the gui visible again
setObjVisibility(hFig,'on');

% --- function for the after running the solution file saving guis
function postSolnSaveFunc(hFig,isMulti)

% retrieves the gui field objects
handles = guidata(hFig);
sInfo = getappdata(hFig,'sInfo');
hTabGrp = getappdata(hFig,'hTabGrp');
iExp = get(get(hTabGrp,'SelectedTab'),'UserData');

% resets the experiment file name
set(handles.editSolnDir,'string',sInfo{iExp}.expFile);

% sets the table information
iok = sInfo{iExp}.snTot.iMov.ok(:);
Data = [sInfo{iExp}.gName(:) num2cell(iok)];
set(handles.tableAppInfo,'Data',Data);

% updates the other figure properties
evnt = struct('Indices',[1,1],'NewData',Data{1,1});
tableAppInfo_CellEditCallback(handles.tableAppInfo, evnt, handles)  

% pause to update figure
pause(0.05);
    
%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --------------------------------------- %
% --- OBJECT INITIALISATION FUNCTIONS --- %
% --------------------------------------- %

% --- initialises the GUI object properties
function initObjProps(handles)

% initialisations
hFig = handles.figFlyCombine;
hPanelEx = handles.panelExptOuter;
hPanelOut = handles.panelOuter;
hTable = handles.tableAppInfo;

% sets the object positions
tabPos = getTabPosVector(hPanelEx,[5,5,-10,-8]);

% creates a tab panel group
hTabGrp = createTabPanelGroup(hPanelEx,1);
set(hTabGrp,'position',tabPos,'tag','hTabGrp')

% creates the new tab panel
hTab = createNewTabPanel(hTabGrp,1,'title','Expt #1','UserData',1);
set(hTab,'ButtonDownFcn',{@tabSelected,handles})

% pause to allow figure update
pause(0.05);

% updates the tab group information
setappdata(hFig,'hTab',{hTab});
setappdata(hFig,'hTabGrp',hTabGrp)

% creates the tree-explorer panel
set(hPanelOut,'Parent',hTab);
resetObjPos(hPanelOut,'Bottom',5)   
resetObjPos(hPanelOut,'Left',5)  

% sets the table background colour
set(hTable,'BackgroundColor',ones(4,3));
autoResizeTableColumns(handles.tableAppInfo);

% disables the save/clear data manu items
setObjEnable(handles.menuSaveExpt,'off')
setObjEnable(handles.menuClearData,'off')

% --- initialises the experimental start object properties --- %
function initExptDurProps(handles,hPanel,sInfo)

% retrieves the current experiment information (if not provided)
if ~exist('sInfo','var')
    sInfo = getCurrentExptInfo(handles.figFlyCombine);
end

% sets the enabled flags for each time field
tExptFull = sec2vec(sInfo.tDur);
isOn = true(size(tExptFull));
for i = 1:length(tExptFull)
    if tExptFull(i) == 0
        isOn(i) = false;
    else
        break
    end
end

% sets the properties for each of the editboxes
tExpt = getCurrentExptDur(sInfo.iPara);
for i = 1:length(tExpt)
    % sets the callback function
    hEdit = findall(hPanel,'UserData',i,'Style','Edit');
    set(hEdit,'Callback',{@editExptDur,handles},'String',num2str(tExpt(i))) 
    setObjEnable(hEdit,isOn(i))
end

% --- initialises the experimental start object properties --- %
function initTimeLocationProps(handles,hPanel,Tvec)

% initialises the start month
mthStr = getMonthStrings();
hMonth = findobj(hPanel,'UserData',2,'Style','Popup');
set(hMonth,'String',mthStr,'Value',Tvec(2));

% initalises the day string
[a,b] = deal(num2cell(1:9)',num2cell(10:31)');
dayStr = [cellfun(@(x)(sprintf('0%i',x)),a,'un',false);
           cellfun(@num2str,b,'un',false)];
hDay = findobj(hPanel,'UserData',3,'Style','popup');   
set(hDay,'Value',Tvec(3),'String',dayStr);

% initalises the hour string
[a,b] = deal(num2cell(1:9)',num2cell(10:12)');
hourStr = [cellfun(@(x)(sprintf('0%i',x)),a,'un',false);
           cellfun(@num2str,b,'un',false)];
hHour = findobj(hPanel,'UserData',4,'Style','popup');          
set(hHour,'String',hourStr,'Value',mod(Tvec(4)-1,12)+1);

% initalises the minute string
[a,b] = deal(num2cell(0:9)',num2cell(10:59)');
minStr = [cellfun(@(x)(sprintf('0%i',x)),a,'un',false);
          cellfun(@num2str,b,'un',false)];
hMin = findobj(hPanel,'UserData',5,'Style','popup');                
set(hMin,'String',minStr,'Value',Tvec(5)+1);

% initalises the AM/PM string
hAMPM = findobj(hPanel,'UserData',1,'Style','popup');                
set(hAMPM,'String',[{'AM'};{'PM'}],'Value',(Tvec(4)>=12)+1,'UserData',1);
                       
% initalises all the start time popup object properties
for i = 1:5
    % retrieves the popup menu handle
    hObj = findobj(hPanel,'Style','popupmenu','UserData',i);
   
    % sets the callback function
    set(hObj,'Callback',{@popupTimeVal,handles})
end

% enables all the panel properties
setPanelProps(hPanel,'on')   

% ------------------------------------ %
% --- PLOT MARKER UPDATE FUNCTIONS --- %
% ------------------------------------ %

% --- resets the tick markers so they match the y-axis limit
function resetXTickMarkers(hAx)

% retrieves the xtick marker labels and the y-axis limits
[hTick0,yLim] = deal(findall(hAx,'tag','hXTick'),get(hAx,'ylim'));

% removes any previous tick markers
if ~isempty(hTick0); delete(hTick0); end

% sets the marker coordinates
xTick = get(hAx,'xtick');
xPlt = repmat(xTick,2,1);
yPlt = repmat(yLim',1,length(xTick));

% creates the marker lines
hold(hAx,'on')        
plot(hAx,xPlt,yPlt,'k--','tag','hXTick')
hold(hAx,'on')

% --- creates the line objects that will server as the limit markers -- %
function updateLimitMarkers(handles)

% global variables
global xLimTot

% sets the axis limits
hAx = handles.axesImg;
yLim = get(hAx,'yLim');

% turns the axis hold on
hold(hAx,'on');

% creates/resets the start marker
hStart = findall(hAx,'tag','Start');
if ~isempty(hStart); delete(hStart); end
createNewMarker(hAx,xLimTot(1)*[1 1],yLim,'Start')

% creates/resets the finish marker
hFinish = findall(hAx,'tag','Finish');
if ~isempty(hFinish); delete(hFinish); end
createNewMarker(hAx,xLimTot(2)*[1 1],yLim,'Finish')

% turns the axis hold on
hold(hAx,'off');

% --- creates the new experiment start/finish limit markers --- %
function createNewMarker(hAx,xPos,yPos,Type)

% global variables
global xLimTot yLimTot
[lWidM,mSizeM,lWidL] = deal(4,5,2);

% creates a new line object
hLineS = imline(hAx,xPos,yPos);
setColor(hLineS,'r');
set(hLineS,'tag',Type)
set(findobj(hLineS,'tag','top line'),'linewidth',lWidL)
set(findobj(hLineS,'tag','end point 1'),'hittest','off',...
                   'linewidth',lWidM,'Markersize',mSizeM)
set(findobj(hLineS,'tag','end point 2'),'hittest','off',...
                   'linewidth',lWidM,'Markersize',mSizeM)
setObjVisibility(findobj(hLineS,'tag','bottom line'),'off')

% sets the constraint/position callback functions
fcn = makeConstrainToRectFcn('imline',xLimTot,yLimTot);
setPositionConstraintFcn(hLineS,fcn);
hLineS.addNewPositionCallback(@(p)moveLimitMarker(p,guidata(hAx),Type));

% --- updates the position plot --- %
function updatePosPlot(handles,varargin)

% data struct/object handle retrieval
hAx = handles.axesImg;
hFig = handles.figFlyCombine;
T = getappdata(hFig,'T');
Px = getappdata(hFig,'Px');
Py = getappdata(hFig,'Py');
hGUIInfo = getappdata(hFig,'hGUIInfo');
sInfo = getCurrentExptInfo(hFig);

% other initialisations
snTot = sInfo.snTot;
iMov = snTot.iMov;
iApp = get(handles.popupAppPlot,'value');

% updates the region popup indices
if isempty(Px{iApp}) && (nargin == 2)
    iApp = find(~cellfun(@isempty,Px),1,'first');
    set(handles.popupAppPlot,'Value',iApp)    
end

% retrieves the ok flags
ok = hGUIInfo.ok;
nFly = getMaxPlotObjCount(iMov);

% other initialisations/parameters
avgPlot = false;
nMeanRatioMax = 10;
[eStr,ii] = deal({'off','on'},1:length(T));
[hPos,hPos2] = deal(findobj(hAx,'tag','hPos'),findobj(hAx,'tag','hPos2'));    

% ---------------------------------- %
% --- PLOTTING DATA CALCULATIONS --- %
% ---------------------------------- %

% sets the plot data based on the selected menu type
hMenu = findobj(handles.menuPlotData,'checked','on');
switch get(hMenu,'tag')
    case ('menuViewXData') 
        % case is the x-locations only
        [xPlt,yPlt] = deal(setupPlotValues(sInfo,Px,'X',iApp),[]);
        
    case ('menuViewYData') 
        % case is the y-locations only
        [xPlt,yPlt] = deal([],setupPlotValues(sInfo,Py,'Y',iApp));
        
    case ('menuViewXYData') 
        % case is both the x/y-locations 
        xPlt = setupPlotValues(sInfo,Px,'X',iApp);
        yPlt = setupPlotValues(sInfo,Py,'Y',iApp);
        
    case ('menuOrientAngle') 
        % case is the orientation angles
        Phi = getappdata(hFig,'Phi');
        [xPlt,yPlt] = deal(setupPlotValues(sInfo,Phi,'Phi',iApp),[]);
        
    case ('menuAvgSpeedIndiv') 
        % case is the avg. speed (individual fly)
        V = getappdata(hFig,'V');
        [xPlt,yPlt] = deal(setupPlotValues(sInfo,V,'V',iApp),[]);
        
    case ('menuAvgSpeedGroup') 
        % case is the avg. speed (group average) 
        avgPlot = true;
        V = getappdata(hFig,'V');
        
        nFly = length(unique(sInfo.gName));        
        [xPlt,yPlt] = deal(setupPlotValues(sInfo,V,'Vavg',iApp),[]);
        ok = any(~isnan(xPlt),1);
        
end
        
% includes a gap in the graph if there is a major gap in the data
[T,Tmlt] = deal(T(ii),getTimeScale(T(end)));
dT = diff(T); jj = find(dT > nMeanRatioMax*mean(diff(T)));
if ~isempty(jj)
    for i = length(jj):-1:1
        % removes the gaps from the time signal
        T = [T(1:jj(i));T(jj(i)+(0:1)');T((jj(i)+1):end)];
        
        % removes the gaps from the x-plot values
        if ~isempty(xPlt)
            xGap = NaN(2,size(xPlt,2));
            xPlt = [xPlt(1:jj(i),:);xGap;xPlt((jj(i)+1):end,:)];
        end
        % removes the gaps from the y-plot values
        if ~isempty(yPlt)
            yGap = NaN(2,size(yPlt,2));
            yPlt = [yPlt(1:jj(i),:);yGap;yPlt((jj(i)+1):end,:)];
        end        
    end
end

% ensures all plot arrays are of the correct length
kk = 1:min(max(size(xPlt,1),size(yPlt,1)),length(T)); T = T(kk);
if ~isempty(xPlt); xPlt = xPlt(kk,:); end
if ~isempty(yPlt); yPlt = yPlt(kk,:); end

% ------------------------------- %
% --- PATCH BACKGROUND UPDATE --- %
% ------------------------------- %

% retrieves the group background fill objects
hGrpF = findall(hAx,'tag','hGrpFill');
if ~isempty(hGrpF)
    % if they exist, then update their colours
    if avgPlot
        [iGrp,isVis] = deal((1:nFly)',num2cell(iMov.ok));
        hGrpF = arrayfun(@(x)(findall(hGrpF,'UserData',x)),iGrp,'un',0);
    else
        iGrp = getRegionGroupIndices(iMov,sInfo.gName,iApp);   
        isVis = num2cell(hGUIInfo.ok(:,iApp));
        hGrpF = num2cell(hGrpF);
    end
    
    % sorts the fields in descending order
    iiG = (1:length(iGrp))';
    [~,iS] = sort(cellfun(@(x)(get(x,'UserData')),hGrpF));
    hGrpF = hGrpF(iS);    
    
    % updates the face colours of the fill objects
    tCol = getAllGroupColours(length(unique(sInfo.gName)));
    cellfun(@(h,i,isV)(set(setObjVisibility(h,isV),'FaceColor',...
              tCol(i+1,:))),hGrpF(iiG),num2cell(iGrp),arr2vec(isVis(iiG)));
end

% resets the apparatus ok flags so that they match up correctly
if avgPlot
    %
    aok = ok;
elseif iscell(Px)
    if length(Px) ~= length(iMov.ok)
        aok = iMov.ok(iMov.ok);
    else
        aok = iMov.ok;    
    end
else
    aok = iMov.ok;        
end

% -------------------------------------- %
% --- PLOTTING TRACE PROPERTY UPDATE --- %
% -------------------------------------- %


% retrieves the handles from the image panel
hObjImg = findall(handles.axesImg);
   
% determines 
if avgPlot
    canPlot = true;
elseif iMov.is2D
    canPlot = any(hGUIInfo.ok(:,iApp));
else
    canPlot = aok(iApp);
end

% otherwise, plot the data by apparatus
if canPlot
    % if apparatus is accepted, then turn on the image axis
    setAxisObjVisibility(hObjImg,'on')

    % sets the trace plots for each fly within the apparatus
    nFlyF = min([nFly,max([size(xPlt,2),size(yPlt,2)])]);
    for i = 1:nFlyF
        % sets the acceptance flags
        if avgPlot
            okNw = ok(i);

            % updates the fill object visibility field
            hGrpF = findall(hAx,'UserData',i,'tag','hGrpFill');
            setObjVisibility(hGrpF,okNw);  
        else
            okNw = ok(i,iApp);
        end

        % updates the plot properties for the first trace type
        hPosNw = findobj(hPos,'UserData',i);                
        if ~isempty(xPlt)                    
            % updates the plot data
            yNw = (i + 0.5) - xPlt(:,i);
            set(hPosNw,'LineWidth',0.5,'color','b','xdata',...
                        T*Tmlt,'yData',yNw,'visible',eStr{1+okNw});
        else
            % otherwise, make the line invisible
            setObjVisibility(hPosNw,'off');                    
        end

        % updates the plot properties for the second trace type
        hPos2Nw = findobj(hPos2,'UserData',i);                
        if ~isempty(yPlt)                   
            % updates the plot data
            yNw = (i + 0.5) - yPlt(:,i);
            set(hPos2Nw,'LineWidth',0.5,'color','r','xdata',...
                        T*Tmlt,'yData',yNw,'visible',eStr{1+okNw});
        else
            % otherwise, make the line invisible
            setObjVisibility(hPos2Nw,'off');                    
        end                
    end          

    % updates the axis limits
    yLim = [1 nFlyF]+0.5*[-1.002 1];
    set(hAx,'yLim',yLim);

    % updates the line height
    x = findall(handles.axesImg,'tag','top line');
    set(x,'ydata',yLim);

    % updates the end marker y-location
    y = findall(handles.axesImg,'tag','end point 2');
    set(y,'ydata',yLim(2));

else
    % if apparatus is rejected, turn off the image axis
    setAxisObjVisibility(hObjImg,'off')
    setObjVisibility(hPos,'off')
    setObjVisibility(hPos2,'off')
end

% ------------------------------------- %
% --- OTHER OBJECT UPDATE FUNCTIONS --- %
% ------------------------------------- %

% --- resizes the combining GUI objects
function resetFigSize(h,fPos)

% sets the overall width/height of the figure
[W0,H0,dY,dX] = deal(fPos(3),fPos(4),10,10);
showStim = strcmp(get(h.panelStim,'Visible'),'on');
pPosO = get(h.panelExptOuter,'position');

% sets the panel stimuli height (depending on whether being displayed)
if showStim
    % stimuli panel is being displayed
    pPosS = get(h.panelStim,'position');
    axHghtS = pPosS(4);
else
    % stimuli panel is not being displayed
    axHghtS = 0;
end

% sets the left/width dimensions
Lnw = sum(pPosO([1 3]))+dX;
Wnw = (W0-(3*dX+pPosO(3)));

% updates the image panel dimensions
mlt = 1 + showStim;
pPosI = [Lnw,mlt*dY+axHghtS,Wnw,(H0-((1+mlt)*dY+axHghtS))];
set(h.panelImg,'units','pixels','position',pPosI)

% updates the stimuli axis (if visible)
if showStim
    set(h.panelStim,'units','pixels','position',[Lnw,dY,Wnw,axHghtS])
end

% updates the outer position bottom location
resetObjPos(h.panelExptOuter,'bottom',H0 - (pPosO(4)+dY));

% resets the axis/label fontsizes
hAx = findall(h.panelImg,'type','axes');
[axSize,lblSize] = detCombineFontSizes(h);
set(hAx,'FontSize',axSize)
set(get(hAx,'yLabel'),'FontSize',lblSize)

% --- sets the axis visibility flags
function setAxisObjVisibility(hObjImg,state)

if strcmp(state,'on')
    hGrpFill = findall(hObjImg,'tag','hGrpFill');
    setObjVisibility(setxor(hObjImg,hGrpFill),'on');
else
    setObjVisibility(hObjImg,'off')
end

% update function for the position data menu items
function updateViewMenu(handles,hMenu,varargin)

% if the menu item is already checked, then exit the function
if nargin == 2
    if strcmp(get(hMenu,'checked'),'on'); return; end
end

% otherwise, remove any existing checks and turns the current one
hMenuC = get(handles.menuPlotData,'children');
setMenuCheck(findobj(hMenuC,'checked','on'),0)
setMenuCheck(hMenu,1)

% updates the enabled properties of the region selection
isGrpAvg = strcmp(get(handles.menuAvgSpeedGroup,'Checked'),'on');
setObjEnable(handles.textAppPlot,~isGrpAvg)
setObjEnable(handles.popupAppPlot,~isGrpAvg)

%
hYLbl = findall(handles.axesImg,'tag','hYLbl');
if ~isempty(hYLbl)
    if isGrpAvg 
        set(hYLbl,'string','Grouping Index Number');
    else
        set(hYLbl,'string',get(hYLbl,'UserData'));
    end
end

% updates the position plot
if nargin == 2
    updatePosPlot(handles)
end

% ------------------------------------- %
% --- EXPERIMENT DATA I/O FUNCTIONS --- %
% ------------------------------------- %

% --- gets the current experiment information
function sInfo = getCurrentExptInfo(hFig)

% overall field retrieval
sInfo0 = getappdata(hFig,'sInfo');
hTabGrp = getappdata(hFig,'hTabGrp');

% retrieves the information field for the current tab
iTab = get(get(hTabGrp,'SelectedTab'),'UserData');
sInfo = sInfo0{iTab};

% --- updates the current experiment information
function updateCurrentExptInfo(hFig,sInfo)

% overall field retrieval
sInfo0 = getappdata(hFig,'sInfo');
hTabGrp = getappdata(hFig,'hTabGrp');

% updates the information for the selected tab
iTab = get(get(hTabGrp,'SelectedTab'),'UserData');
sInfo0{iTab} = sInfo;
setappdata(hFig,'sInfo',sInfo0)

% ----------------------------- %
% --- PLOT DATA VALUE SETUP --- %
% ----------------------------- %

% --- calculates the population velocity (for a given apparatus)
function Vplt = calcPopVel(T,Px,Py,fok)

% parameters
[tBin,nFrm] = deal(5,length(T));    
Vplt = NaN(nFrm,size(Px,2)); 
iVel = (1+tBin):(nFrm-tBin);

% sets the time-stepvectors
dT = cellfun(@(x)(diff(T([(x-tBin) (x+tBin)]))),num2cell(iVel));

% calculates the inter-frame displacement
a = zeros(1,size(Px,2));
if (isempty(Py))
    % if only 1D, then calculate the inter-frame displacement from x-values
    D = [a;abs(diff(Px,[],1))];
else    
    % if only 2D, then calculate the inter-frame euclidean displacement
    D = [a;sqrt(diff(Px,[],1).^2 + diff(Py,[],1).^2)];    
end

% calculates the distance travelled and the time steps
for i = 1:size(Vplt,2)
    if (fok(i))
        dD = cellfun(@(x)(sum(D((x-tBin):(x+tBin),i))),num2cell(iVel));
        Vplt(iVel,i) = dD./dT;
    end
end

% --- calculates the x/y location data for the plots
function Z = setupPlotValues(sInfo,Pz,type,iApp)

% parameters
pW = 1.05;
snTot = sInfo.snTot;
iMov = snTot.iMov;

% if the region is rejected, then exit with a NaN value
if isempty(Pz{iApp})
    Z = [];
    return
end

% sets the extremum values (used for normalising the signals
switch type
    case ('X') 
        % case is the x-location data 
        if iscell(iMov.iC{iApp})
            % determines the min/max range of the tube regions
            zMin = cellfun(@(x)(x(1)-1),iMov.iC{iApp});
            zMax = cellfun(@(x)(x(end)-1),iMov.iC{iApp});
            zH = 0.5*(zMin + zMax);
            
            % determines the min/max range of the actual points, and
            % determines which group these values belong to
            [Zmn,Zmx] = deal(min(Pz{iApp},[],1),max(Pz{iApp},[],1));
            iX = cellfun(@(x)(argMin(abs(x-zH))),num2cell(0.5*(Zmn+Zmx)));
            
            % calculates the normalized position values
            Z = zeros(size(Pz{iApp}));
            for i = 1:length(zMin)
                ii = iX == i;
                Z(:,ii) = (Pz{iApp}(:,ii)-zMin(i))/(zMax(i)-zMin(i));
            end
        else
            if iMov.is2D
                % case is 2D analysis
                [zMin,zMax] = deal(iMov.iC{iApp}(1)-1,iMov.iC{iApp}(end)-1);                      
            else
                % case is 1D analysis (old files are missing scale factor)
                [zMin,zMax] = deal(min(Pz{iApp}(:)),max(Pz{iApp}(:)));
            end        
            Z = (Pz{iApp} - zMin)/(zMax - zMin);        
        end
        
    case ('Y') 
        % case is the y-location data
        if iscell(iMov.iC{iApp})                       
            % determines the min/max range of the tube regions
            zMin = cellfun(@(x)(x(1)-1),iMov.iR{iApp});
            zMax = cellfun(@(x)(x(end)-1),iMov.iR{iApp});
            zH = 0.5*(zMin + zMax);
            
            % determines the min/max range of the actual points, and
            % determines which group these values belong to
            [Zmn,Zmx] = deal(min(Pz{iApp},[],1),max(Pz{iApp},[],1));
            iX = cellfun(@(x)(argMin(abs(x-zH))),num2cell(0.5*(Zmn+Zmx)));
            
            % calculates the normalized position values
            Z = zeros(size(Pz{iApp}));
            for i = 1:length(zMin)
                ii = iX == i;
                Z(:,ii) = (Pz{iApp}(:,ii)-zMin(i))/(zMax(i)-zMin(i));
            end                        
        else
            yOfs = iMov.iR{iApp}(1)-1;
            zMin = repmat(iMov.yTube{iApp}(:,1)',size(Pz{iApp},1),1);
            zMax = repmat(iMov.yTube{iApp}(:,2)',size(Pz{iApp},1),1);        
            Z = (Pz{iApp} - (zMin+yOfs))./(zMax - zMin);
        end
        
    case ('V') 
        % case is average speed
        Z = Pz{iApp}/(pW*nanmax(Pz{iApp}(:))); 
        
    case ('Phi') 
        % case is orientation angle
        Z = (Pz{iApp} + 180)/360;            
        
    case ('Vavg')
        % case is the grouped average speed
        hFig = findall(0,'tag','figFlyCombine');
        hGUIInfo = getappdata(hFig,'hGUIInfo');
        
        % retrieves the region acceptance flag and grouping indices 
        flyok = hGUIInfo.ok;
        iGrp = getRegionGroupIndices(iMov,sInfo.gName);
        
        % determnes the unique groupings comprising the expt
        iGrpU = unique(iGrp(iGrp>0),'stable');        
        
        % calculates the avg. velocity based on the grouping type  
        Zgrp = cell(1,length(iGrpU));
        [jGrp,okGrp] = deal(num2cell(iGrp,1),num2cell(flyok,1));
        for i = 1:length(Zgrp)
            Zgrp{i} = cell2mat(cellfun(@(x,j,ok)...
                        (x(:,(j==iGrpU(i)) & ok)),Pz,jGrp,okGrp,'un',0));
            if isempty(Zgrp{i})
                Zgrp{i} = NaN(size(Pz{1},1),1);
            else
                Zgrp{i} = nanmean(Zgrp{i},2);
            end
        end                        

        % normalises the signals to the maximum
        Z = cell2mat(Zgrp);            
        Z = Z/(pW*nanmax(Z(:)));            
end

% ------------------------------------------- %
% --- GROUP NAME TABLE PROPERTY FUNCTIONS --- %
% ------------------------------------------- %

% --- retrieves the table background colours
function [bgCol,iGrpNw] = getTableBGColours(handles,sInfo)

% sets the default input arguments (if not provided)
if ~exist('sInfo','var')
    sInfo = getCurrentExptInfo(handles.figFlyCombine);
end

% retrieves the unique group names from the list
grayCol = 0.81;
[gName,~,iGrpNw] = unique(sInfo.gName,'stable');
isOK = sInfo.snTot.iMov.ok & ~strcmp(sInfo.gName,'* REJECTED *');

% sets the background colour based on the matches within the unique list
tCol = getAllGroupColours(length(gName),1);
bgCol = tCol(iGrpNw,:);
bgCol(~isOK,:) = grayCol;

% --- updates the table dimensions
function tabPos = setTableDimensions(handles,nApp,isInit)

% parameters
hFig = handles.figFlyCombine;
pPos = get(handles.tableAppInfo,'position');
[X0,Y0,Wf,W,W0,isMove] = deal(10,10,55,pPos(3),0,false);

% retrieves the figure positional vector
fPos0 = get(hFig,'position');

if isInit
    jObjT = findjobj(handles.tableAppInfo);
    setappdata(hFig,'jObjT',jObjT)
else
    jObjT = getappdata(hFig,'jObjT');
end

% retrieves the base table dimensions
while W0 == 0
    % retrieves the table dimensions
    [~,~,W0] = getTableDimensions(jObjT);
    
    % if the width is still zero, then make the GUI visible and try again
    if W0 == 0               
        isMove = true;
        resetObjPos(hFig,'Left',-(fPos0(3)+10));
        setObjVisibility(hFig,'on'); 
        pause(0.05);         
    end
end

% resets the object position
if isMove
    setObjVisibility(hFig,'off'); pause(0.05);         
    resetObjPos(hFig,'Left',fPos0(1));
end

% sets the table dimensions/column width 
tabPos = [X0 Y0 W calcTableHeight(nApp)];
cWid = [(W-(W0+Wf)) Wf];

% sets the table position and column width
set(handles.tableAppInfo,'Position',tabPos,'ColumnWidth',num2cell(cWid))
autoResizeTableColumns(handles.tableAppInfo);

% --- updates the group colours
function updateGroupColours(handles,indNw,nwData)

% global variables
global tableUpdating

% retrieves the cell indices
hFig = handles.figFlyCombine;  
sInfo = getCurrentExptInfo(hFig); 
hGUIInfo = getappdata(hFig,'hGUIInfo');

% updates the information table
if ~isempty(hGUIInfo)
    % initialisations
    jT = hGUIInfo.jTable;
    snTot = sInfo.snTot;
    iMov = snTot.iMov;
    flyok = iMov.flyok;

    % updates the colours                
    if iMov.is2D
        % case is a 2D experiment setup
        if isfield(iMov,'pInfo')
            [iRow,iCol] = find(iMov.pInfo.iGrp == indNw(1));
        else
            iRow = 1:size(iMov.flyok);
            iCol = indNw(1)*ones(size(iRow));
        end

        % updates the table checkbox values
        if nwData
            % case is the group is accepted    
            ii = sub2ind(size(iMov.flyok),iRow,iCol);
            cVal = logical(flyok(ii));

            % updates the checkbox values
            arrayfun(@(cv,ir,ic)...
                    (jT.setValueAt(cv,ir-1,ic-1)),cVal,iRow,iCol);                    
        else
            % case is the group is rejected
            arrayfun(@(ir,ic)...
                    (jT.setValueAt([],ir-1,ic-1)),iRow,iCol);
        end
    else 
        % case is a 1D experiment setup

        % sets the check values for each fly
        if nwData
            % case is the region is accepted
            noData = all(isnan(snTot.Px{indNw(1)}),1);            
            chkVal = num2cell(flyok(:,indNw(1)));
            chkVal(noData) = {[]};                    
        else
            % case is the region is rejected
            chkVal = cell(size(flyok,1),1);
        end

        % case is a 1D experiment setup
        cellfun(@(cv,ir)(jT.setValueAt(cv,ir-1,indNw(1)-1)),...
                            chkVal,num2cell(1:length(chkVal))')
    end                            

    % updates the fly ok flags
    while tableUpdating
        pause(0.05);
    end

    % resets the ok flags
    hGUIInfo.ok = flyok;
    setappdata(hFig,'hGUIInfo',hGUIInfo);
end

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- retrieves the combine GUI font sizes
function [axSize,lblSize] = detCombineFontSizes(handles)

% global variables
global regSz

% determines the font ratio
newSz = get(handles.panelImg,'position');
fR = min(newSz(3:4)./regSz(3:4))*get(0,'ScreenPixelsPerInch')/72;

% sets the font size based on the OS type
if (ismac)
    % case is using a Mac
    [axSize,lblSize] = deal(20*fR,26*fR);
else
    % case is using a PC
    [axSize,lblSize] = deal(12*fR,18*fR);    
end   

% --- calculates the maximum plot object count (for a given expt)
function nRowMx = getMaxPlotObjCount(iMov)

if iMov.is2D
    % case is a 2D experiment
    szGrp = size(iMov.pInfo.iGrp);
    nRowMx = max(max(szGrp),max(iMov.pInfo.iGrp(:)));
else
    % case is a 1D experiment
    nRowMx = max(numel(iMov.pInfo.iGrp),size(iMov.flyok,1));
end

% --- retrieves the current experiment duration
function tExpt = getCurrentExptDur(iPara)

tExpt = sec2vec(etime(iPara.Tf,iPara.Ts));
