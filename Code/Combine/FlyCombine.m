function varargout = FlyCombine(varargin)
% Last Modified by GUIDE v2.5 24-Jun-2022 00:21:50

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
function FlyCombine_OpeningFcn(hObject, ~, handles, varargin)

% global variables
global isAnalysis isUpdating updateFlag regSz 
[isAnalysis,isUpdating] = deal(false);
updateFlag = 2; pause(0.01); 

% retrieves the regular size of the GUI
regSz = get(handles.panelImg,'position');

% creates the load bar
h = ProgressLoadbar('Initialising Data Combining GUI...');

% sets the GUI figure position (top-left corner)
pos = get(hObject,'position');
scrSz = getPanelPosPix(0,'Pixels','ScreenSize');
set(hObject,'position',[10 (scrSz(4)-pos(4)) pos(3) pos(4)]);

% ----------------------------------------------------------- %
% --- FIELD INITIALISATIONS & DIRECTORY STRUCTURE SETTING --- %
% ----------------------------------------------------------- %

% sets the input arguments
hFigM = varargin{1};

% sets the input argument and the open GUI (makes invisible)
set(hObject,'name','DART Fly Experiment Data Output Program')

% retrieves the program default struct
mObj = getappdata(hFigM,'mObj');
ProgDefNew = mObj.getProgDefField('Combine');
setObjVisibility(hFigM,'off')                      
        
% sets the input arguments
setappdata(hObject,'iTab',1);
setappdata(hObject,'sInfo',[]);
setappdata(hObject,'pltObj',[]);
setappdata(hObject,'hGUIInfo',[]);
setappdata(hObject,'hDART',hFigM);
setappdata(hObject,'iProg',ProgDefNew);

% sets the default input opening files
sDirO = {ProgDefNew.DirSoln,ProgDefNew.DirComb,ProgDefNew.DirComb}';
setappdata(hObject,'sDirO',sDirO);

% sets the function handles into the GUI
setappdata(hObject,'postSolnLoadFunc',@postSolnLoadFunc)
setappdata(hObject,'postSolnSaveFunc',@postSolnSaveFunc)
setappdata(hObject,'getInfoFcn',@getCurrentExptInfo); 
setappdata(hObject,'updateInfoFcn',@updateCurrentExptInfo)
setappdata(hObject,'updateViewMenu',@updateViewMenu)
setappdata(hObject,'resetPopupFields',@resetPopupFields)
setappdata(hObject,'getCurrentExptDur',@getCurrentExptDur)

% clears the image axis
cla(handles.axesImg); 
axis(handles.axesImg,'off')
cla(handles.axesStim); 
axis(handles.axesStim,'off')

% sets the other object properties
handles = initObjProps(handles);

% % sets up the git menus
% if exist('GitFunc','file')
%     setupGitMenus(hObject)
% end

% initialisations the apparatus data struct
centreFigPosition(hObject);

% closes the loadbar
try delete(h); catch; end

% Choose default command line output for FlyCombine
handles.output = hObject;

% ensures that the appropriate check boxes/buttons have been inactivated
setObjVisibility(hObject,'on'); pause(0.01);
updateFlag = 0; pause(0.01); 

% auto-resizes the table columns
autoResizeTableColumns(handles.tableAppInfo);

% initialises the table position
setappdata(hObject,'jObjT',findjobj(handles.tableAppInfo))
setTableDimensions(handles,4,true);

% takes a snapshot of the clear gui
setappdata(hObject,'hProp0',getHandleSnapshot(hObject))

% Update handles structure
guidata(hObject, handles);

% % UIWAIT makes FlyCombine wait for user response (see UIRESUME)
% uiwait(handles.figFlyCombine);

% --- Outputs from this function are returned to the command line.
function varargout = FlyCombine_OutputFcn(~, ~, ~) 

% Get default command line output from handles structure
varargout{1} = [];

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% ------------------ %
% --- LOAD ITEMS --- %
% ------------------ %

% -------------------------------------------------------------------------
function menuLoadExpt_Callback(~, ~, handles)

% initialisations
hFig = handles.figFlyCombine;
hGUIInfo = getappdata(hFig,'hGUIInfo');

% makes the acceptance flag info gui invisible
if ~isempty(hGUIInfo)
    setObjVisibility(hGUIInfo.hFig,'off');
end

% opens the solution file gui
wState = warning('off','all');
OpenSolnFile(hFig);
warning(wState)

% --------------------------------------------------------------------
function menuSaveSingle_Callback(~, ~, handles)

% runs the save single experiment file gui
SaveExptFile(handles.figFlyCombine)

% --------------------------------------------------------------------
function menuSaveMulti_Callback(~, ~, handles)

% runs the save multi experiment file gui
SaveMultiExptFile(handles.figFlyCombine)

% ------------------- %
% --- OTHER ITEMS --- %
% ------------------- %

% -------------------------------------------------------------------------
function menuLoadExtnData_Callback(~, ~, handles)

% runs the video parameter reset dialog
ExtnData(handles.figFlyCombine);

% -------------------------------------------------------------------------
function menuClearData_Callback(~, ~, handles)

% prompts the user if they really want to clear all the data
qStr = 'Are you sure you want to clear all the loaded data?';
uChoice = questdlg(qStr,'Clear All Data?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if the user cancelled, then exit the function
    return
end

% resets the combine gui by clearing all objects
resetCombineGUI(handles)

% -------------------------------------------------------------------------
function menuProgPara_Callback(~, ~, handles)

% runs the program default GUI
ProgDefaultDef(handles.figFlyCombine,'Combine');

% -------------------------------------------------------------------------
function menuExit_Callback(~, ~, handles)

% object handles
hFig = handles.figFlyCombine;

% prompts the user if they wish to close the main gui
qStr = 'Are you sure you want to close the Data Combining GUI?';
uChoice = questdlg(qStr,'Close GUI?','Yes','No','Yes');
if strcmp(uChoice,'Yes')
    % deletes the information sub-gui (if it exists)
    hGUIInfo = getappdata(hFig,'hGUIInfo');
    if ~isempty(hGUIInfo)
        hGUIInfo.closeFigure();
    end        
    
    % returns to the base GUI
    hDART = getappdata(hFig,'hDART');  
    
    % clears the main sub-figure field
    mObj = getappdata(hFig,'mObj');
    mObj.hFigSub = [];    
    
    % deletes the data combining GUI
    delete(hFig)    
    setObjVisibility(hDART,'on');    
end

% -------------------------------- %
% --- PLOTTING DATA MENU ITEMS --- %
% -------------------------------- %

% -------------------------------------------------------------------------
function menuViewXData_Callback(hObject, ~, handles)

% updates the view menu properties and the viewing axes
updateViewMenu(handles,hObject)

% -------------------------------------------------------------------------
function menuViewYData_Callback(hObject, ~, handles)

% updates the view menu properties and the viewing axes
updateViewMenu(handles,hObject)

% -------------------------------------------------------------------------
function menuViewXYData_Callback(hObject, ~, handles)

% updates the view menu properties and the viewing axes
updateViewMenu(handles,hObject)

% -------------------------------------------------------------------------
function menuOrientAngle_Callback(hObject, ~, handles)

% updates the view menu properties and the viewing axes
updateViewMenu(handles,hObject)

% -------------------------------------------------------------------------
function menuAvgSpeedIndiv_Callback(hObject, ~, handles)

% updates the view menu properties and the viewing axes
updateViewMenu(handles,hObject)

% -------------------------------------------------------------------------
function menuAvgSpeedGroup_Callback(hObject, ~, handles)

% updates the view menu properties and the viewing axes
updateViewMenu(handles,hObject)

%-------------------------------------------------------------------------%
%                       TOOLBAR CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% -------------------------------------------------------------------------
function toggleZoom_ClickedCallback(hObject, ~, ~)

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
function figFlyCombine_ResizeFcn(hObject, ~, handles)

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
pObj = getappdata(hFig,'pltObj');
sInfo0 = getappdata(hFig,'sInfo');
hGUIInfo = getappdata(hFig,'hGUIInfo');

% deletes any previous information GUIs
if isempty(sInfo0)
    % no data is loaded, so exit function
    return
    
elseif ~isempty(hGUIInfo)
    if ~isempty(eventdata)
        % if the tab has not changed, then exit the function
        if hGUIInfo.iTab == get(hObj,'UserData')
            return
        end

        % update the solution flags and closes the gui 
        hGUIInfo.updateSolutionFlags();
    end
    
    % closes the figure
    hGUIInfo.closeFigure(); 
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

% initialises/updates the plot objects (based on the class object state)
if isempty(pObj)
    % case is plot object has yet to be initialises
    pObj = DataCombPlotObj(handles);
    setappdata(hFig,'pltObj',pObj);
else
    % case is plot object has been initialised
    pObj.resetExptPlotObjects();
end

% creates a variable region information GUI
if detMltTrkStatus(pObj.sInfo.snTot.iMov)
    hGUIInfo = MultiTrackFlyInfoGUI(handles,pObj.sInfo.snTot,[],false); 
else
    hGUIInfo = FlyInfoGUI(handles,pObj.sInfo.snTot,[],false);   
end

% updates the information gui field in the main gui
setappdata(hFig,'hGUIInfo',hGUIInfo)

% % resets the plot objects (if calling function directly)
% if isempty(eventdata)
%     pObj.resetExptPlotObjects()
% end    

% resets the experiment information fields
updateExptInfoFields(handles,pObj.sInfo)
pObj.updatePlotObjects()
updateGroupInfo(handles,pObj.sInfo)

% resets the marker
hPanelF = handles.panelFinishTime;
hPopup = findall(hPanelF,'Style','popupmenu','UserData',1);
popupTimeVal(hPopup, [], handles)

% makes the GUI visible
updateFlag = 0;
figFlyCombine_ResizeFcn(hFig,[],handles)
centerfig(hFig);
pause(0.05);

% closes the loadbar
try delete(h); catch; end

% sets the gui visibility
uistack(hGUIInfo.hFig,'top')
setObjVisibility(hGUIInfo.hFig,'on');

% --- executes on update editSolnDir
function editSolnDir_Callback(hObject, ~, handles)

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

% --------------------------------------------- %
% --- POSITION PLOT MARKER OBJECT CALLBACKS --- %
% --------------------------------------------- %

% --- Executes on selection change in popupAppPlot.
function popupAppPlot_Callback(hObject, ~, handles)

% updates the axis plot (if there are suitable apparatus set)
if ~isempty(get(hObject,'string'))
    pObj = getappdata(handles.figFlyCombine,'pltObj');
    pObj.updatePosPlot()
end
    
% --------------------------------------------- %
% --- APPARATUS INFORMATION TABLE CALLBACKS --- %
% --------------------------------------------- %

% --- Executes when entered data in editable cell(s) in tableAppInfo.
function tableAppInfo_CellEditCallback(hObject, eventdata, handles)

% retrieves the cell indices
hFig = handles.figFlyCombine;
pObj = getappdata(hFig,'pltObj');
sInfo0 = getappdata(hFig,'sInfo');
hGUIInfo = getappdata(hFig,'hGUIInfo');
hTabGrp = getappdata(hFig,'hTabGrp');
iExp = get(get(hTabGrp,'SelectedTab'),'UserData');

% other initialisations
ok = hGUIInfo.ok;
Data = get(hObject,'Data');
[indNw,nwData] = deal(eventdata.Indices,eventdata.NewData);

% updates the solution info
sInfoNw = sInfo0{iExp};
sInfoNw.snTot.iMov.flyok = ok;

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
    if pObj.sInfo.snTot.iMov.is2D
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
            pObj.sInfo = sInfoNw;            
            pObj.sInfo.gName{indNw(1)} = nwData; 
            pObj.updateCurrentExptInfo();           
            
        else
            % apparatus name is invalid so output an error
            eStr = 'Region names strings can''t contain a comma';
            waitfor(errordlg(eStr,'Region Naming Error','modal'))
            
            % resets the table values
            Data{indNw(1),indNw(2)} = pObj.sInfo.gName{indNw(1)};
            set(hObject,'Data',Data);
            return
        end
        
    case (2) 
        % case is the inclusion flag
                
        % updates the apparatus data struct
        pObj.sInfo = sInfoNw;
        pObj.sInfo.snTot.iMov.ok(indNw(1)) = nwData;        
        pObj.updateCurrentExptInfo();
        
        % updates the position plot axes
        updateGroupColours(handles,indNw,nwData)
end

% resets the table background colours
bgCol = getTableBGColours(pObj.sInfo);
set(hObject,'BackgroundColor',bgCol)

% determines if the individual fly info gui is open            
if ~isempty(hGUIInfo) && isa(hGUIInfo,'FlyInfoGUI')
    % if so, then update the grouping colours
    jT = hGUIInfo.jTable;
    for j = 1:size(bgCol,1)
        % sets the new background colour
        nwCol = getJavaColour(bgCol(j,:));

        % updates the colours                
        if detMltTrkStatus(pObj.sInfo.snTot.iMov)
            % case is multi-tracking
            [iRow,iCol] = hGUIInfo.getMultiTrackIndices(j);
            jT.SetBGColourCell(iRow-1,iCol-1,nwCol);
        
        elseif pObj.sInfo.snTot.iMov.is2D
            % case is a 2D experiment setup
            if isfield(pObj.sInfo.snTot.iMov,'pInfo')
                [iRow,iCol] = find(pObj.sInfo.snTot.iMov.pInfo.iGrp == j);
            else
                iRow = 1:size(pObj.sInfo.snTot.iMov.flyok);
                iCol = j*ones(size(iRow));
            end

            % updates the colours
            for i = 1:length(iRow)
                jT.SetBGColourCell(iRow(i)-1,iCol(i)-1,nwCol);
            end

        else
            % case is a 1D experiment setup
            for i = find(pObj.sInfo.snTot.iMov.flyok(:,j))'
                jT.SetBGColourCell(i-1,j-1,nwCol);
            end
        end
    end

    % updates the table
    jT.repaint();
end

% updates the location/speed plots
pause(0.05);
pObj.updatePosPlot()

% ----------------------------------------- %
% --- START/FINISH TIME POINT CALLBACKS --- %
% ----------------------------------------- %

% --- Executes on button press in buttonStartReset.
function buttonStartReset_Callback(~, ~, handles)

% retrieves the currently selected solution file data
hFig = handles.figFlyCombine;
pObj = getappdata(hFig,'pltObj');

% retrieves the parameter struct
pObj.sInfo.iPara.indS = [1,1];
pObj.sInfo.iPara.Ts = pObj.sInfo.iPara.Ts0;
pObj.updateCurrentExptInfo();

% resets the start time object fields
resetPopupFields(handles.panelStartTime,pObj.sInfo.iPara.Ts)
pObj.resetLimitMarker(pObj.xLimT(1)*[1 1],'Start')
pObj.resetExptDurFields();

% updates the start time string
txtStart = datestr(pObj.sInfo.iPara.Ts0,'mmm dd, YYYY HH:MM AM');
set(handles.textStartTime,'string',txtStart)

% --- Executes on button press in buttonFinishReset.
function buttonFinishReset_Callback(~, ~, handles)

% retrieves the parameter struct
hFig = handles.figFlyCombine;
pObj = getappdata(hFig,'pltObj');
indF = [length(pObj.sInfo.snTot.T) length(pObj.sInfo.snTot.T{end})];

% updates the end flag values
pObj.sInfo.iPara.Tf = pObj.sInfo.iPara.Tf0;
pObj.sInfo.iPara.indF = indF;
pObj.updateCurrentExptInfo()

% resets the finish time object fields
resetPopupFields(handles.panelFinishTime,pObj.sInfo.iPara.Tf)
pObj.resetLimitMarker(pObj.xLimT(2)*[1 1],'Finish')
pObj.resetExptDurFields();

% updates the finish time string
txtFinish = datestr(pObj.sInfo.iPara.Tf0,'mmm dd, YYYY HH:MM AM');
set(handles.textFinishTime,'string',txtFinish)

% --- Executes on selection change in popupStartDay.
function popupTimeVal(hObject, ~, handles)

% retrieves the index of the month that was selected
hFig = handles.figFlyCombine;
iSel = get(hObject,'Value');
iType = get(hObject,'UserData');
hPanel = get(hObject,'parent');
pObj = getappdata(hFig,'pltObj');

% sets the initial start time
Tv0 = cellfun(@(x)(x(1)),pObj.sInfo.snTot.T)*pObj.Tmlt;
if strcmp(get(get(hObject,'parent'),'tag'),'panelStartTime')
    T0 = pObj.sInfo.iPara.Ts;
else
    T0 = pObj.sInfo.iPara.Tf;
end

% sets the start time vector
switch iType
    case (2) 
        % case is the month was selected
        
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
        dStr = [arrayfun(@(x)(sprintf('0%i',x)),(1:9)','un',0);...
                arrayfun(@num2str,(10:dMax)','un',0)];
        
        % ensures the day is at most the maximum value, and resets the day
        % popup menu string list/value
        [T0(3),T0(iType)] = deal(min(T0(3),dMax),iSel);    
        set(handles.popupStartDay,'string',dStr,'Value',T0(3));            
        
    case (3) 
        % case is the day was selected
        
        % updates the value
        T0(iType) = iSel;
        
    case (4) 
        % case is the hours was selected
        
        % recalculates the hour
        hAMPM = findobj(hPanel,'UserData',1,'Style','PopupMenu');
        if iSel == 12
            T0(iType) = 12*(get(hAMPM,'Value')-1);
        else
            T0(iType) = 12*(get(hAMPM,'Value')-1) + iSel;
        end
                
    case (5) 
        % case is the minutes was selected
        
        % updates the value
        T0(iType) = iSel - 1;        
        
    otherwise
        % case is the AM/PM popup
        
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
[dTS,dTS0] = deal(calcTimeDifference(T0,pObj.sInfo.iPara.Ts0));
if strcmp(get(get(hObject,'parent'),'tag'),'panelStartTime')
    % calculates the time difference between the new time location and the
    % limit markers    
    dTF = calcTimeDifference(pObj.sInfo.iPara.Tf,T0);
    
    % checks to see if the new time is valid
    if (dTS < 0) || (dTF < 0)
        % if not, then reset to the previous valid value
        eStr = 'Error! Start time is not valid.';
        waitfor(errordlg(eStr,'Start Time Error','modal'))
        pObj.resetPopupFields(handles.panelStartTime,pObj.sInfo.iPara.Ts)
        
    else
        % otherwise, update the start time/index
        pObj.sInfo.iPara.Ts = T0;
        pObj.sInfo.iPara.indS(1) = find(Tv0 <= dTS0*pObj.Tmlt,1,'last');                
        pObj.sInfo.iPara.indS(2) = find(pObj.sInfo.snTot.T...
                    {pObj.sInfo.iPara.indS(1)} <= dTS0,1,'last');        
        pObj.updateCurrentExptInfo();
        
        % resets the limit markers
        pObj.resetLimitMarker(dTS*[1 1]*pObj.Tmlt,'Start')
        pObj.resetExptDurFields();
    end
else
    % calculates time difference between new time location & limit markers
    dTS = calcTimeDifference(T0,pObj.sInfo.iPara.Ts);
    dTF = calcTimeDifference(pObj.sInfo.iPara.Tf0,T0);
    
    % checks to see if the new time is valid
    if (dTS < 0) || (dTF < 0)
        % if not, then reset to the previous valid value
        eStr = 'Error! Finish time is not valid.';
        waitfor(errordlg(eStr,'Finish Time Error','modal'))        
        pObj.resetPopupFields(handles.panelFinishTime,pObj.sInfo.iPara.Tf)

    else
        % otherwise, update the finish time/index
        pObj.sInfo.iPara.Tf = T0;
        pObj.sInfo.iPara.indF(1) = find(Tv0 <= dTS0*pObj.Tmlt,1,'last');                
        pObj.sInfo.iPara.indF(2) = find(pObj.sInfo.snTot.T{...
                    pObj.sInfo.iPara.indF(1)} <= dTS0,1,'last');
        pObj.updateCurrentExptInfo()      
        
        % resets the limit markers
        pObj.resetLimitMarker(dTS0*[1 1]*pObj.Tmlt,'Finish')
        pObj.resetExptDurFields();
    end
end

% --- Executes on editing the experiment duration editboxes
function editExptDur(hObject, ~, handles)

% retrieves the currently selected solution file data
hFig = handles.figFlyCombine;
hPanelS = handles.panelStartTime;
hPanelF = handles.panelFinishTime;
iType = get(hObject,'UserData');
pObj = getappdata(hFig,'pltObj');
iPara = pObj.sInfo.iPara;

% sets the parameter limits
switch iType
    case {3,4}
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
    [iParaNw,updateStart,ok] = updateFinalTimeVec(handles,iPara);
    if ok
        % updates the data struct with the new value and exits
        pObj.sInfo.iPara = iParaNw;
        pObj.updateCurrentExptInfo()
        
        % updates the final experiment time and plot markers        
        pObj.resetPopupFields(hPanelF,pObj.sInfo.iPara.Tf)          
        hPopup = findall(hPanelF,'Style','popupmenu','UserData',1);
        popupTimeVal(hPopup, [], handles)
        
        % updates the start experiment time and plot markers
        pObj.resetPopupFields(hPanelS,pObj.sInfo.iPara.Ts)  
        if updateStart
            hPopup = findall(hPanelS,'Style','popupmenu','UserData',1);
            popupTimeVal(hPopup, [], handles)            
        end
        
        % exits the function
        return
    else
        % otherwise, create the error string
        maxFeasDur = vec2str(getCurrentExptDur(iParaNw));
        currExptDur = vec2str(getCurrentEditDur(handles));
        eStr = sprintf(['Error! The entered experiment duration is ',...
                        'not feasible:\n\n %s Entered Duration = %s',...
                        '\n %s Feasible Duration = %s'],char(8594),...
                        currExptDur,char(8594),maxFeasDur);
    end
end

% outputs the error message to screen
waitfor(msgbox(eStr,'Invalid Experiment Duration','modal'))

% otherwise, reset to the previous value
tExpt0 = getCurrentExptDur(pObj.sInfo.iPara);
set(hObject,'string',num2str(tExpt0(iType)));

% --- resets the popup field values --- %
function resetPopupFields(hPanel,Tvec)
    
% updates the popup-field values
set(findobj(hPanel,'UserData',1),'value',1+(Tvec(4)>=12)) 
set(findobj(hPanel,'UserData',2),'value',Tvec(2))
set(findobj(hPanel,'UserData',3),'value',Tvec(3))
set(findobj(hPanel,'UserData',4),'value',mod(Tvec(4)-1,12)+1)
set(findobj(hPanel,'UserData',5),'value',Tvec(5)+1)

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
    isKeep{1}(cellfun('isempty',indEx)) = false;
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
    setObjEnable(handles.menuLoadExtnData,nTabT>0)
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
function handles = initObjProps(handles)

% initialisations
bgCol = ones(4,3);
hFig = handles.figFlyCombine;
hPanelEx = handles.panelExptOuter;
hPanelOut = handles.panelOuter;

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

% table object properties
nRow = 4;
cWid = {255,55};
tPos = [10,10,400,94];
cEdit = [true,true];
cForm = {'char','logical'};
cName = {'Sub-Region Group Name','Include'};
eFcn = {@tableAppInfo_CellEditCallback,handles};
rwName = arrayfun(@(x)(sprintf('Group #%i',x)),(1:nRow)','un',0);

% creates the table object
handles.tableAppInfo = uitable(handles.panelAppInfo,'Units','Pixels',...
    'Position',tPos,'ColumnFormat',cForm,'CellEditCallback',eFcn,...
    'ColumnName',cName,'BackgroundColor',bgCol,'ColumnWidth',cWid,...
    'RowName',rwName,'ColumnEditable',cEdit,'Enable','off');

% updates the tab group information
setappdata(hFig,'hTab',{hTab});
setappdata(hFig,'hTabGrp',hTabGrp)

% creates the tree-explorer panel
set(hPanelOut,'Parent',hTab);
resetObjPos(hPanelOut,'Bottom',5)   
resetObjPos(hPanelOut,'Left',5)  

% sets the table background colour
autoResizeTableColumns(handles.tableAppInfo);

% disables the save/clear data manu items
setObjEnable(handles.menuSaveExpt,'off')
setObjEnable(handles.menuLoadExtnData,'off')
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

% ------------------------------------- %
% --- OTHER OBJECT UPDATE FUNCTIONS --- %
% ------------------------------------- %

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
setObjEnable(handles.menuLoadExtnData,'off')
setObjEnable(handles.menuClearData,'off');
setObjEnable(handles.menuPlotData,'off');

% --- resizes the combining GUI objects
function resetFigSize(h,fPos)

% sets the overall width/height of the figure
hFig = h.figFlyCombine;
[W0,H0,dY,dX] = deal(fPos(3),fPos(4),10,10);
showStim = strcmp(get(h.panelStim,'Visible'),'on');
pPosO = get(h.panelExptOuter,'Position');
pObj = getappdata(hFig,'pltObj');

% sets the panel stimuli height (depending on whether being displayed)
if isempty(pObj)
    % exits if there is no plotting object
    return
elseif showStim
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
set(hAx,'FontSize',pObj.axSize)
set(get(hAx,'yLabel'),'FontSize',pObj.lblSize)

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
    pObj = getappdata(handles.figFlyCombine,'pltObj');
    pObj.updatePosPlot()
end

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
eStr = {'off','on'};
[X0,Y0] = deal(10,10);
snTot = sInfo.snTot;
hFig = handles.figFlyCombine;
hTabGrp = getappdata(hFig,'hTabGrp');
isMltTrk = detMltTrkStatus(snTot.iMov);

% HACK FIX FOR MISSING GROUP INFORMATION TABLE?!
if ~isfield(handles,'tableAppInfo')
    handles = guidata(hFig);
end

% sets the group name strings
if isMltTrk
    [cHdr0,gStr] = deal('Region Grouping Names','Region');
elseif snTot.iMov.is2D
    [cHdr0,gStr] = deal('2D Arena Grouping Names','Column');
else
    [cHdr0,gStr] = deal('1D Region Grouping Names','Region');
end

% sets the table information
iok = snTot.iMov.ok(:);
Data = [sInfo.gName(:) num2cell(iok)];

% sets the table row headers
if snTot.iMov.is2D || isMltTrk
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
bgCol = getTableBGColours(sInfo);
set(handles.tableAppInfo,'RowName',rowName,'ColumnName',cHdr,...
              'Data',Data,'BackgroundColor',bgCol,...
              'Enable',eStr{~isempty(snTot)+1})                                         
             
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

% ------------------------------------------- %
% --- GROUP NAME TABLE PROPERTY FUNCTIONS --- %
% ------------------------------------------- %

% --- retrieves the table background colours
function [bgCol,iGrpNw] = getTableBGColours(sInfo)

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
pObj = getappdata(hFig,'pltObj');
hGUIInfo = getappdata(hFig,'hGUIInfo');

% updates the information table
if ~isempty(hGUIInfo)
    % initialisations
    jT = hGUIInfo.jTable;
    snTot = pObj.sInfo.snTot;
    iMov = snTot.iMov;
    flyok = iMov.flyok;

    % updates the colours                
    if detMltTrkStatus(iMov)
        % case is multi-tracking
        [iRow,iCol] = hGUIInfo.getMultiTrackIndices(indNw(1));
        
        if nwData
            % case is the group is accepted
            cVal = logical(flyok(iRow,iCol));            
            jT.setValueAt(cVal,iRow-1,iCol-1)
        else
            % case is the group is rejected
            jT.setValueAt([],iRow-1,iCol-1)
        end
        
    elseif iMov.is2D
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
            chkVal = hGUIInfo.Data(:,indNw(1));
            
%             noData = all(isnan(snTot.Px{indNw(1)}),1);            
%             chkVal = num2cell(flyok(:,indNw(1)));
%             chkVal(noData) = {[]};                    
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

% ------------------------------------- %
% --- EXPERIMENT DURATION FUNCTIONS --- %
% ------------------------------------- %

% --- updates the final time vector with the current information
function [iPara,updateStart,ok] = updateFinalTimeVec(handles,iPara)

% retrieves the current expt duration (as displayed)
[updateStart,ok] = deal(false,true);
tExptNw = vec2sec(getCurrentEditDur(handles));
tExpt0 = vec2sec(getCurrentExptDur(iPara));
[dTs,dTf] = deal(etime(iPara.Ts,iPara.Ts0),etime(iPara.Tf0,iPara.Tf));

% if the new time is invalid, then exit with an empty array
if tExptNw > (tExpt0 + dTs + dTf)
    % case is the experiment duration is infeasible
    ok = false;
    
elseif tExptNw > (tExpt0 + dTf)
    % case is the experiment duration is feasible, but the start time needs
    % to be shifted to accomodate
    Ts = datenum(iPara.Ts);
    updateStart = true;
    iPara.Ts = datevec(addtodate(Ts,(tExpt0 + dTf) - tExptNw,'s'));
    iPara.Tf = datevec(addtodate(Ts,dTf+tExpt0,'s'));
    
else
    % case is the experiment duration can be extended by only considering
    % the final experiment time marker
    Ts = datenum(iPara.Ts);
    iPara.Tf = datevec(addtodate(Ts,tExptNw,'s'));
end

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

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- retrieves the current experiment duration
function tExpt = getCurrentExptDur(iPara)

tExpt = sec2vec(etime(iPara.Tf,iPara.Ts));
