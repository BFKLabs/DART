function varargout = FlyCombine(varargin)
% Last Modified by GUIDE v2.5 04-Jun-2021 03:13:07

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
setappdata(hObject,'hDART',hDART)
setappdata(hObject,'hGUIInfo',[]);
setappdata(hObject,'hUndock',[])
setappdata(hObject,'iProg',ProgDefNew);

% sets the function handles into the GUI
setappdata(hObject,'updatePlot',@updatePosPlot)

% clears the image axis
cla(handles.axesImg); 
axis(handles.axesImg,'off')
cla(handles.axesStim); 
axis(handles.axesStim,'off')

% sets the other object properties
setObjEnable(handles.menuSaveSingleSoln,'off')

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
function menuLoadDir_Callback(hObject, eventdata, handles)

% initialisations
hFig = handles.figFlyCombine;
iProg = getappdata(hFig,'iProg');
dDir = iProg.DirSoln;

% prompts the user for the solution file directory
fFile = DirTree({'.soln'},dDir);
if isempty(fFile)
    % if the user cancelled, then exit the function 
    return
else
    % determines the directory names
    [fDir,fFileGrp] = detUniqFileNames(fFile);    
    switch length(fDir)
        case 0
            % case is the user cancelled or there are no feasible folders
            return
            
        case 1
            % case is there is one feasible solution file directory           
            [snTot,iMov,eStr] = combineSolnFiles(fFileGrp{1}); 
            
        otherwise
            % case is there are multiple contiguous directories
            [snTot,iMov] = deal([]);
            eStr = ['Video solution files for more than one ',...
                    'experiment has been selected. Please retry by ',...
                    'only selecting files from a single experiment.'];
    end
    
    % if the user cancelled, or there was an error, then exit    
    if isempty(snTot)
        % if there was an error, then output this to screen
        if ~isempty(eStr)
            waitfor(msgbox(eStr,'Video Solution File Error','modal'))
        end    
        
        return
    else
        % sets the end directory name (used as output file name)
        if length(fDir) == 1
            [fName,sName] = deal(getFinalDirString(fDir{1}));
        else
            [A,~,~] = fileparts(fDir{1}); 
            [fName,sName] = deal(getFinalDirString(A));
            snTot.iExpt(1).Info.Title = fName;
        end
    end
end

% updates the solution file name/directory
setappdata(hFig,'fDir',iProg.DirComb)
setappdata(hFig,'fName',fName)
setappdata(hFig','sDir',fDir)
setappdata(hFig','sName',sName)
set(handles.textSolnDirL,'string','Data Directory: ')
set(handles.textSolnType,'string','Video Solution File Directory')

% resets the GUI objects
snTot.iMov = iMov;
resetGUIObjects(handles,snTot)

% -------------------------------------------------------------------------
function menuLoadSoln_Callback(hObject, eventdata, handles)

% loads the data structs from the GUI
hFig = handles.figFlyCombine;
iProg = getappdata(hFig,'iProg');

% prompts the user for the solution file directory
fType = {'*.ssol;','Experimental Solution Files (*.ssol)'};
[fName,fDir,fIndex] = uigetfile(fType,...
                        'Load Experimental Solution File',iProg.DirComb);
if fIndex == 0
    % if the user cancelled, then exit the function 
    return
else
    % initialises the waitbar
    snTot = loadExptSolnFiles(iProg.TempFile,fullfile(fDir,fName),1);
    
    % loads the solution file
    if isempty(snTot)
        % if the user cancelled, then exit
        return
    end
end

% determines if there is 1D or 2D analysis required
if ~isfield(snTot.iMov,'is2D')
    snTot.iMov.is2D = ~isempty(snTot.Py);
end

% sets the base solution file name
[~,fNameNw,~] = fileparts(fName);

% % sets the sub-region data struct (only really important for 2D analysis)
% if isfield(snTot,'iMov')
%     % if the appPara field exists, then strip out the important information 
%     % and removes it from the solution data struct
%     if isfield(snTot,'appPara')
% %         % strips out the individual/group acceptance flags
% %         iMov = snTot.iMov;
% %         [iMov.flyok,iMov.ok] = deal(snTot.appPara.flyok,snTot.appPara.ok);
% %         snTot.iMov = iMov;
%         
%         % removes the appPara field
%         snTot = rmfield(snTot,'appPara');        
%     end
% end

% back-formats the region data struct 
snTot = backFormatRegionInfo(snTot);

% updates the field and data structs
setappdata(hFig,'fDir',fDir)
setappdata(hFig,'fName',fNameNw)
setappdata(hFig','sDir',{fDir})
setappdata(hFig','sName',[fNameNw,'.ssol'])
set(handles.textSolnDirL,'string','Data File: ')
set(handles.textSolnType,'string','Experiment Solution File')

% resets the GUI objects
resetGUIObjects(handles,snTot)

% ------------------ %
% --- SAVE ITEMS --- %
% ------------------ %

% -------------------------------------------------------------------------
function menuSaveSingleSoln_Callback(hObject, eventdata, handles)

% runs the combined solution file save GUI
SaveCombFile(handles);

% -------------------------------------------------------------------------
function menuSaveMultiSoln_Callback(hObject, eventdata, handles)

% runs the single combined data output file generation GUI
MultFlyCombInfo(handles)

% ------------------- %
% --- OTHER ITEMS --- %
% ------------------- %

% -------------------------------------------------------------------------
function menuProgPara_Callback(hObject, eventdata, handles)

% runs the program preference sub-GUI
iProg = getappdata(handles.figFlyCombine,'iProg');
[iProgNw,isSave] = ProgParaCombine(handles.figFlyCombine,iProg);

% updates the data struct (based on the program preference)
if (isSave)
    setappdata(handles.figFlyCombine,'iProg',iProgNw);
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
[pPos,Y0] = deal(get(handles.panelOuter,'position'),10);
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

% --- resizes the combining GUI objects
function resetFigSize(h,fPos)

% sets the overall width/height of the figure
[W0,H0,dY,dX] = deal(fPos(3),fPos(4),10,10);
pPosO = get(h.panelOuter,'position');
pPosS = get(h.panelStim,'position');

% sets the left/width dimensions
Lnw = sum(pPosO([1 3]))+dX;
Wnw = (W0-(3*dX+pPosO(3)));

% updates the image panel dimensions
pPosI = [Lnw,2*dY+pPosS(4),Wnw,(H0-(3*dY+pPosS(4)))];
set(h.panelImg,'units','pixels','position',pPosI)
set(h.panelStim,'units','pixels','position',[Lnw,dY,Wnw,pPosS(4)])

% updates the outer position bottom location
resetObjPos(h.panelOuter,'bottom',H0 - (pPosO(4)+dY));

% resets the axis/label fontsizes
hAx = findall(h.panelImg,'type','axes');
[axSize,lblSize] = detCombineFontSizes(h);
set(hAx,'FontSize',axSize)
set(get(hAx,'yLabel'),'FontSize',lblSize)

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
snTot = getappdata(hFig,'snTot'); 
hGUIInfo = getappdata(hFig,'hGUIInfo');

% ensures the 2D flag is set 
if ~isfield(snTot.iMov,'is2D')
    snTot.iMov.is2D = is2DCheck(snTot.iMov);
end

% other initialisations
iMov = snTot.iMov;
Data = get(hObject,'Data');
[indNw,nwData] = deal(eventdata.Indices,eventdata.NewData);

% removes the selection highlight
jScroll = findjobj(hObject);
jTable = jScroll.getComponent(0).getComponent(0);
jTable.changeSelection(-1,-1,false,false);

% determines if the region is rejected
switch indNw(2)
    case 1
        if isprop(eventdata,'PreviousData')
            isRejected = strcmp(eventdata.PreviousData,'% REJECTED %');
        else
            isRejected = false;
        end
        
    case 2
        isRejected = strContains(Data{indNw(1),1},'% REJECTED %');
end

% determines if the region is reject. if so, then revert back to the
% previous data (while outputting a message to screen)
if isRejected
    if snTot.iMov.is2D
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
            snTot.iMov.pInfo.gName{indNw(1)} = nwData;             
            setappdata(hFig,'snTot',snTot);              
            
        else
            % apparatus name is invalid so output an error
            eStr = 'Region names strings can''t contain a comma';
            waitfor(errordlg(eStr,'Region Naming Error','modal'))
            
            % resets the table values
            Data{indNw(1),indNw(2)} = iMov.pInfo.gName{indNw(1)};
            set(hObject,'Data',Data);
            return
        end
        
    case (2) 
        % case is the inclusion flag
                
        % updates the apparatus data struct
        snTot.iMov.ok(indNw(1)) = nwData;        
        setappdata(hFig,'snTot',snTot);  
        
        % updates the position plot axes
        updatePosPlot(handles)   
        updateGroupColours(handles,indNw,nwData)
end

% resets the table background colours
bgCol = getTableBGColours(handles,snTot);
set(hObject,'BackgroundColor',bgCol)

% determines if the individual fly info gui is open            
if ~isempty(hGUIInfo)
    % if so, then update the grouping colours
    jT = hGUIInfo.jTable;
    for j = 1:size(bgCol,1)
        % sets the new background colour
        nwCol = getJavaColour(bgCol(j,:));

        % updates the colours                
        if iMov.is2D
            % case is a 2D experiment setup
            if isfield(snTot.iMov,'pInfo')
                [iRow,iCol] = find(snTot.iMov.pInfo.iGrp == j);
            else
                iRow = 1:size(snTot.iMov.flyok);
                iCol = j*ones(size(iRow));
            end

            % updates the colours
            for i = 1:length(iRow)
                jT.SetBGColourCell(iRow(i)-1,iCol(i)-1,nwCol);
            end

        else
            % case is a 1D experiment setup
            for i = 1:size(snTot.iMov.flyok,1)
                jT.SetBGColourCell(i-1,j-1,nwCol);
            end
        end
    end

    % updates the table
    jT.repaint();
end

% updates the apparatus data struct
updatePosPlot(handles)

% ----------------------------------------- %
% --- START/FINISH TIME POINT CALLBACKS --- %
% ----------------------------------------- %

% --- Executes on button press in buttonStartReset.
function buttonStartReset_Callback(hObject, eventdata, handles)

% retrieves the parameter struct
iPara = getappdata(handles.figFlyCombine,'iPara');
[iPara.Ts,iPara.indS] = deal(iPara.Ts0,[1 1]);
setappdata(handles.figFlyCombine,'iPara',iPara);
txtStart = datestr(iPara.Ts0,'mmm dd, YYYY HH:MM AM');

% resets to the start time string
resetPopupFields(handles.panelStartTime,iPara.Ts)
resetLimitMarker(handles.axesImg,[0 0],'Start')
set(handles.textStartTime,'string',txtStart)

% --- Executes on button press in buttonFinishReset.
function buttonFinishReset_Callback(hObject, eventdata, handles)

% global variables
global xLimTot

% retrieves the parameter struct
snTot = getappdata(handles.figFlyCombine,'snTot');
iPara = getappdata(handles.figFlyCombine,'iPara');
iPara.Tf = iPara.Ts0;
iPara.indF = [length(snTot.T) length(snTot.T{end})];
setappdata(handles.figFlyCombine,'iPara',iPara);

% resets to the finish time
txtFinish = datestr(iPara.Tf0,'mmm dd, YYYY HH:MM AM');
resetPopupFields(handles.panelFinishTime,iPara.Tf)
resetLimitMarker(handles.axesImg,xLimTot(2)*[1 1],'Finish')
set(handles.textFinishTime,'string',txtFinish)

% --- Executes on selection change in popupStartDay.
function popupTimeVal(hObject, eventdata, handles)

% retrieves the index of the month that was selected
iSel = get(hObject,'Value');
iType = get(hObject,'UserData');
hPanel = get(hObject,'parent');

% 
iPara = getappdata(handles.figFlyCombine,'iPara');
snTot = getappdata(handles.figFlyCombine,'snTot');
Tmlt = getTimeScale(snTot.T{end}(end));

% sets the initial start time
Tv0 = cellfun(@(x)(x(1)),snTot.T)*Tmlt;
if (strcmp(get(get(hObject,'parent'),'tag'),'panelStartTime'))
    T0 = iPara.Ts;
else
    T0 = iPara.Tf;
end

% sets the start time vector
switch (iType)
    case (2) % case is the month was selected
        % gets the day popup handle
        hDay = findobj(hPanel,'UserData',3,'Style','PopupMenu');
        
        % sets the days in the month (based on the month selected)
        switch (iSel)
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
        T0(iType) = 12*(get(hAMPM,'Value')-1) + iSel;
                
    case (5) % case is the minutes was selected
        % updates the value
        T0(iType) = iSel - 1;        
        
    otherwise % case is the AM/PM popup
        % resets the hour value based on the AM/PM popup                
        hHour = findobj(hPanel,'UserData',4,'Style','PopupMenu');
        T0(4) = get(hHour,'Value') + 12*(iSel-1);
end

% resets the panel marker
[dTS,dTS0] = deal(calcTimeDifference(T0,iPara.Ts0));
if (strcmp(get(get(hObject,'parent'),'tag'),'panelStartTime'))
    % calculates the time difference between the new time location and the
    % limit markers    
    dTF = calcTimeDifference(iPara.Tf,T0);
    
    % checks to see if the new time is valid
    if ((dTS < 0) || (dTF < 0))
        % if not, then reset to the previous valid value
        eStr = 'Error! Start time is not valid.';
        waitfor(errordlg(eStr,'Start Time Error','modal'))
        resetPopupFields(handles.panelStartTime,iPara.Ts)        
    else
        % otherwise, update the start time/index
        iPara.Ts = T0;
        iPara.indS(1) = find(Tv0 <= dTS0,1,'last');                
        iPara.indS(2) = find(snTot.T{iPara.indS(1)}*Tmlt <= dTS0,1,'last');        
        setappdata(handles.figFlyCombine,'iPara',iPara)
        
        % resets the limit markers
        resetLimitMarker(handles.axesImg,dTS*[1 1]*Tmlt,'Start')
    end
else
    % calculates the time difference between the new time location and the
    % limit markers    
    dTS = calcTimeDifference(T0,iPara.Ts);
    dTF = calcTimeDifference(iPara.Tf0,T0);
    
    % checks to see if the new time is valid
    if ((dTS < 0) || (dTF < 0))
        % if not, then reset to the previous valid value
        eStr = 'Error! Finish time is not valid.';
        waitfor(errordlg(eStr,'Finish Time Error','modal'))        
        resetPopupFields(handles.panelFinishTime,iPara.Tf)
    else
        % otherwise, update the finish time/index
        iPara.Tf = T0;
        iPara.indF(1) = find(Tv0 <= dTS0,1,'last');                
        iPara.indF(2) = find(snTot.T{iPara.indF(1)}*Tmlt <= dTS0,1,'last');         
        setappdata(handles.figFlyCombine,'iPara',iPara)        
        
        % resets the limit markers
        resetLimitMarker(handles.axesImg,dTS0*[1 1]*Tmlt,'Finish')
    end
end

% --- start/finish limit marker callback function --- %
function moveLimitMarker(pNew,handles,Type,varargin)

% global variables
global xLimTot

% initialisations
snTot = getappdata(handles.figFlyCombine,'snTot');
iPara = getappdata(handles.figFlyCombine,'iPara');
T0 = snTot.iExpt(1).Timing.T0;
[hAx,xNew] = deal(handles.axesImg,pNew(1,1));

% sets the video start times
Tmlt = getTimeScale(snTot.T{end}(end));
Tv0 = cellfun(@(x)(x(1)),snTot.T)*Tmlt;

% updates the 
switch Type
    case ('Start')
        % retrieves the finish marker x-location
        hFinish = findobj(handles.axesImg,'tag','Finish');        
        pF = get(findobj(hFinish,'tag','top line'),'xData');
        
        % if the start marker exceeds the finish, then reset
        if xNew >= pF(1)
            % sets the time vector to be below that of the finish
            TvecNw = iPara.Tf;
            TvecNw(5) = TvecNw(5) - 1;            
            
            % resets the limit marker
            xNew = calcTimeDifference(TvecNw,iPara.Ts0)*Tmlt;
            resetLimitMarker(hAx,xNew*[1 1],Type)            
        end                
        
        % determines the new marker index value  
        if xNew == 0
            iPara.indS = ones(1,2);
        else            
            iPara.indS(1) = find([Tv0;1e10] <= xNew,1,'last');                
            iPara.indS(2) = find...
                    ([snTot.T{iPara.indS(1)}*Tmlt;1e10] <= xNew,1,'last');                
        end
        
        if (iPara.indS(1)*iPara.indS(2)) == 1
            % if the first point, set the the original marker point
            iPara.Ts = iPara.Ts0;            
        else
            % otherwise, calculate the new time string
            iPara.Ts = calcTimeString...
                    (T0,snTot.T{iPara.indS(1)}(iPara.indS(2)));
        end
        setappdata(handles.figFlyCombine,'iPara',iPara)
        
        % sets the new x-limit
        TvecNw = iPara.Ts; TvecNw(5) = TvecNw(5) + 1;
        xLimNew = calcTimeDifference(TvecNw,iPara.Ts0)*Tmlt;        
        
        % resets the popup-values
        resetLimitMarkerRegion(hAx,[xLimNew xLimTot(2)],'Finish')
        resetPopupFields(handles.panelStartTime,iPara.Ts)
        
    case ('Finish')
        % retrieves the start marker x-location
        hStart = findobj(handles.axesImg,'tag','Start');
        pS = get(findobj(hStart,'tag','top line'),'xData');
               
        % if the start marker exceeds the finish, then reset
        if (xNew <= pS(1))
            % sets the time vector to be below that of the finish
            TvecNw = iPara.Ts;
            TvecNw(5) = TvecNw(5) + 1;            
            
            % resets the limit marker
            xNew = calcTimeDifference(TvecNw,iPara.Ts0)*Tmlt;
            resetLimitMarker(hAx,xNew*[1 1],Type)            
        end          

        % sets the final marker index and the final time string 
        iPara.indF(1) = find([Tv0;1e10] <= xNew,1,'last');
        iPara.indF(2) = find...
                    ([snTot.T{iPara.indF(1)}*Tmlt;1e10] <= xNew,1,'last');                
        iPara.Tf = calcTimeString(T0,snTot.T{iPara.indF(1)}(iPara.indF(2)));        
        setappdata(handles.figFlyCombine,'iPara',iPara)
        
        % sets the new x-limit
        TvecNw = iPara.Tf; TvecNw(5) = TvecNw(5) - 1;
        xLimNew = calcTimeDifference(TvecNw,iPara.Ts0)*Tmlt;
        
        % resets the popup-values
        resetLimitMarkerRegion(hAx,[0 xLimNew],'Start')
        resetPopupFields(handles.panelFinishTime,iPara.Tf)
end

% updates the experiment durations
[~,~,tStr] = calcTimeDifference(iPara.Tf,iPara.Ts);
textDur = sprintf('%s Days, %s Hours, %s Mins',tStr{1},tStr{2},tStr{3});
set(handles.textSolnDur,'string',textDur)

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

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --------------------------------------- %
% --- OBJECT INITIALISATION FUNCTIONS --- %
% --------------------------------------- %

% --- initialises the solution file information --- %
function initSolnInfo(handles)

% retrieves the solution data struct
snTot = getappdata(handles.figFlyCombine,'snTot');
sName = getappdata(handles.figFlyCombine,'sName');
sDir = getappdata(handles.figFlyCombine,'sDir');

% sets the field strings
set(handles.textSolnDir,'string',simpFileName(sName,18),...
                        'ToolTipString',sDir{1})  
                    
% sets the other object properties
set(handles.textSolnCount,'string',num2str(length(snTot.T)))
setPanelProps(handles.panelSolnData,'on')

% --- initialises the solution file information --- %
function initExptInfo(handles)

% global variables
global dT

% retrieves the solution data struct
snTot = getappdata(handles.figFlyCombine,'snTot');
iMov = snTot.iMov;
    
% sets the experimental case string
if (length(snTot.iExpt) > 1)
    eCase = 'Multi-Experiment';        
else
    switch (snTot.iExpt.Info.Type)
        case {'RecordStim','StimRecord'}
            eCase = 'Recording & Stimulus';        
        case ('RecordOnly')
            eCase = 'Recording Only';
        case ('RTTrack')
            eCase = 'Real-Time Tracking';
    end    
end
    
% calculates the experiment duration (rounded to the nearest minute)
dT = roundP((snTot.T{end}(end)-snTot.T{1}(1))/60,1)*60;
[~,~,Tstr] = calcTimeDifference(dT);

% calculates the experiment duration strings
TstrTot = sprintf('%s Days, %s Hours, %s Mins',Tstr{1},Tstr{2},Tstr{3});

%
if iMov.is2D
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

% sets the string text labels
set(handles.textExptType,'string',eCase)
set(handles.textExptDur,'string',TstrTot)
set(handles.textSetupType,'string',exptStr)
set(handles.textRegionConfig,'string',regConfig)
setPanelProps(handles.panelExptInfo,'on')

% --- initialises the solution file information --- %
function initPlotObjects(handles,snTot)

% global variables
global pStep isPlotAll

% clears the image axis
iMov = snTot.iMov;
hFig = handles.figFlyCombine;
[hAx,isPlotAll] = deal(handles.axesImg,false);

% updates the current figure/axes handles
cla(hAx); axis(hAx,'on')
set(0,'CurrentFigure',hFig);
set(hFig,'CurrentAxes',hAx)

% sets the time multiplier
calcPhi = isfield(snTot,'Phi');
Tmlt = getTimeScale(snTot.T{end}(end));
    
% calculates the time step
nFrm = sum(cellfun(@length,snTot.T));
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
isDay = cell2mat(snTot.isDay'); snTot.isDay = {isDay(ii)};

% updates the axis x-limits
xLim0 = Tmlt*[0 T(end)];
xLim = xLim0 + 0.001*diff(xLim0)*[-1 1];
set(hAx,'xlim',xLim)

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

% sets the fly time/x-coordinate arrays
for i = 1:length(Px)
    if iMov.ok(i)
        Px{i} = snTot.Px{i}(ii,:)/sFac; 
        if iMov.is2D
            % if 2D analysis, then set the y-locations as well
            Py{i} = snTot.Py{i}(ii,:)/sFac; 
            if i == 1; T = T(1:(end-1)); end        
        end

        % calculates the population speed
        V{i} = calcPopVel(T,Px{i},Py{i},iMov.flyok(:,i));

        % sets the c
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

% creates the grouping colour fill objects
hFill = findall(hAx,'tag','hGrpFill');
if ~isempty(hFill); delete(hFill); end

if isfield(iMov,'pInfo')
    if iMov.is2D
        nRowMx = max(size(iMov.pInfo.iGrp),max(iMov.pInfo.iGrp(:)));
    else
        nRowMx = max(numel(iMov.pInfo.iGrp),size(iMov.flyok,1));
    end
end

% creates the fill objects
[ix,iy,fAlpha] = deal([1,1,2,2,1],[1,2,2,1,1],0.1);
for i = 1:nRowMx
    yy = (i-0.5)+[0,1];
    patch(xLim(ix),yy(iy),'k','FaceAlpha',fAlpha,'tag','hGrpFill',...
                          'UserData',i);
    
end
    
% if the plot markers don't exist, then create them
initPosPlotMarkers(handles,T,setupPlotValues(snTot,Px,'X',1))      

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
set(hAMPM,'String',[{'AM'};{'PM'}],'Value',(Tvec(4)>12)+1,'UserData',1);
                       
% initalises all the start time popup object properties
for i = 1:5
    % retrieves the popup menu handle
    hObj = findobj(hPanel,'Style','popupmenu','UserData',i);
   
    % sets the callback function
    bFunc = @(hObj,e)FlyCombine('popupTimeVal',hObj,[],guidata(hObj));
    set(hObj,'Callback',bFunc)
end

% enables all the panel properties
setPanelProps(hPanel,'on')

% --------------------------------------- %
% --- STRUCT INITIALISATION FUNCTIONS --- %
% --------------------------------------- %

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
                    
% ------------------------------------ %
% --- PLOT MARKER UPDATE FUNCTIONS --- %
% ------------------------------------ %

% --- intialises the position plot markers
function initPosPlotMarkers(handles,T,xPlt)

% global variables
global xLimTot yLimTot pStep isPlotAll 

% ------------------------------------------- %
% --- INITIALISATIONS & MEMORY ALLOCATION --- %
% ------------------------------------------- %

% sets the axis/label font sizes
hFig = handles.figFlyCombine;
[axSize,lblSize] = detCombineFontSizes(handles);

% retrieves the ok flags
snTot = getappdata(hFig,'snTot');
hGUIInfo = getappdata(hFig,'hGUIInfo');
[ok,iMov] = deal(hGUIInfo.ok,snTot.iMov);

% retrieves the axes handles and other important data arrays
hAx = handles.axesImg;
TT = getappdata(hFig,'T');
snTot = getappdata(hFig,'snTot');

% sets the maximum number of flies
nFly = max(snTot.iMov.pInfo.nGrp,size(iMov.flyok,1));

% allocates memory
[eStr,Tmlt] = deal({'off','on'},getTimeScale(T(end)));

% ensures all plot arrays are of the correct length
kk = 1:min(size(xPlt,1),length(T)); 
T = T(kk); 
ii = 1:pStep:length(T);

% ------------------------------------ %
% --- PLOTTING AXES INITIALISATION --- %
% ------------------------------------ %

% if the plots do not exist, then create them for each apparatus
hold(hAx,'on');
for i = 1:nFly
    % initialises the plot traces
    if isPlotAll
        % plotting data for all the apparatus together
        plot(hAx,NaN,NaN,'color','b','tag','hPos','UserData',i,...
            'LineWidth',0.5,'visible','off');        
    else
        % plotting data for each apparatus individually
        plot(hAx,NaN,NaN,'color','b','tag','hPos','UserData',i,...
            'LineWidth',0.5,'visible','off');                
    end
    
    % initialises the plot trace for the 2nd plot lines (if 2D)
    if iMov.is2D               
        % plots the trace
        plot(hAx,NaN,NaN,'color','r','tag','hPos2','UserData',i,...
            'LineWidth',0.5,'visible','off');                        
    end
                
    % sets seperation line (if not the last sub-region)
    if i ~= nFly
        plot(T([1 end])*Tmlt,(i+0.5)*[1 1],'k','linewidth',1)
    end
end    
hold(hAx,'off')

% resets the axis properties
set(hAx,'fontweight','bold','fontsize',axSize,'box','on',...
        'ytick',(1:nFly)','yLim',[1 nFly] + 0.5*[-1 1],...
        'TickLength',[0 0],'linewidth',1.5)
resetXTickMarkers(hAx);
    
if isPlotAll
    lblStr = 'Region Index';
elseif iMov.is2D
    lblStr = 'Grid Row Number';
else
    lblStr = 'Sub-Region Index';
end

% updates the axis/label properties
hLbl = ylabel(hAx,lblStr,'FontUnits','pixels','tag','hYLbl');
set(hLbl,'fontweight','bold','fontsize',lblSize,'UserData',lblStr)
axis(hAx,'ij')

% sets the label points
xLimTot = [snTot.T{1}(1) snTot.T{end}(end)]*Tmlt;
yLimTot = [1 nFly]+0.5*[-1 1];

% sets the axes units to normalised
set(handles.axesImg,'Units','Normalized')

% updates the position plot
updatePosPlot(handles)

% adds in the stimuli axes panels (if stimuli are present)
addStimAxesPanels(handles,snTot.stimP,snTot.sTrainEx,T([1 end]));

% --- resets the tick markers so they match the y-axis limit
function resetXTickMarkers(hAx)

% retrieves the xtick marker labels and the y-axis limits
[hTick,yLim] = deal(findall(hAx,'tag','hXTick'),get(hAx,'ylim'));

if isempty(hTick)
    % if there are no markers, then create them
    hold on
    xTick = get(hAx,'xtick');
    yPlt = repmat(yLim',1,length(xTick));
    plot(repmat(xTick,2,1),yPlt+0.5,'k--','tag','hXTick')
    hold off
else
    % otherwise, update there y-data values
    arrayfun(@(x)(set(x,'ydata',yLim)),hTick)
end

% --- creates the line objects that will server as the limit markers -- %
function initLimitMarkers(handles)

% global variables
global xLimTot

% sets the axis limits
hAx = handles.axesImg;

% creates the new markers
yLim = get(hAx,'yLim');
createNewMarker(hAx,xLimTot(1)*[1 1],yLim,'Start')
createNewMarker(hAx,xLimTot(2)*[1 1],yLim,'Finish')

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
function updatePosPlot(handles)

% global variables
global isPlotAll

% ------------------------------------------- %
% --- INITIALISATIONS & MEMORY ALLOCATION --- %
% ------------------------------------------- %

% data struct/object handle retrieval
hAx = handles.axesImg;
hFig = handles.figFlyCombine;
T = getappdata(hFig,'T');
Px = getappdata(hFig,'Px');
Py = getappdata(hFig,'Py');
snTot = getappdata(hFig,'snTot');
hGUIInfo = getappdata(hFig,'hGUIInfo');

% other initialisations
iMov = snTot.iMov;
iApp = get(handles.popupAppPlot,'value');

% retrieves the ok flags
ok = hGUIInfo.ok;

% retrieves the fly count (dependent on expt type)
if iMov.is2D
    % case is a 2D expt
    nFly = size(iMov.flyok,1);
else
    % case is a 1D expt
    nFly = find(iMov.flyok(:,iApp),1,'last');
end

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
        [xPlt,yPlt] = deal(setupPlotValues(snTot,Px,'X',iApp),[]);
        
    case ('menuViewYData') 
        % case is the y-locations only
        [xPlt,yPlt] = deal([],setupPlotValues(snTot,Py,'Y',iApp));
        
    case ('menuViewXYData') 
        % case is both the x/y-locations 
        xPlt = setupPlotValues(snTot,Px,'X',iApp);
        yPlt = setupPlotValues(snTot,Py,'Y',iApp);
        
    case ('menuOrientAngle') 
        % case is the orientation angles
        Phi = getappdata(hFig,'Phi');
        [xPlt,yPlt] = deal(setupPlotValues(snTot,Phi,'Phi',iApp),[]);
        
    case ('menuAvgSpeedIndiv') 
        % case is the avg. speed (individual fly)
        V = getappdata(hFig,'V');
        [xPlt,yPlt] = deal(setupPlotValues(snTot,V,'V',iApp),[]);
        
    case ('menuAvgSpeedGroup') 
        % case is the avg. speed (group average) 
        avgPlot = true;
        V = getappdata(hFig,'V');
        
        nFly = length(unique(iMov.pInfo.gName));        
        [xPlt,yPlt] = deal(setupPlotValues(snTot,V,'Vavg',iApp),[]);
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
        iGrp = getRegionGroupIndices(iMov,iMov.pInfo.gName,iApp);   
        isVis = num2cell(hGUIInfo.ok(:,iApp));
        hGrpF = num2cell(hGrpF);
    end
    
    % sorts the fields in descending order
    iiG = (1:length(iGrp))';
    [~,iS] = sort(cellfun(@(x)(get(x,'UserData')),hGrpF));
    hGrpF = hGrpF(iS);    
    
    % updates the face colours of the fill objects
    tCol = getAllGroupColours(length(unique(iMov.pInfo.gName)));
    cellfun(@(h,i,isV)(set(setObjVisibility(h,isV),'FaceColor',...
              tCol(i+1,:))),hGrpF(iiG),num2cell(iGrp),arr2vec(isVis(iiG)));
end

% resets the apparatus ok flags so that they match up correctly
if isPlotAll
    aok = iMov.ok;        
else
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
end

% -------------------------------------- %
% --- PLOTTING TRACE PROPERTY UPDATE --- %
% -------------------------------------- %


% retrieves the handles from the image panel
hObjImg = findall(handles.axesImg);

% determines the data type that is being plotted
if isPlotAll
    % determines 
    if avgPlot
        canPlot = true;
    elseif iMov.is2D
        canPlot = any(iMov.flyok(:));
    else
        canPlot = any(aok);
    end        

    % if there are a small number of averall regions, then plot all the
    % data onto the plotting axis
    if canPlot
        % turns on the image axis on
        setAxisObjVisibility(hObjImg,'on')            

        % sets the trace plot properties for each apparatus
        for i = 1:nFly
            hPosNw = findobj(hPos,'UserData',i);
            set(hPosNw,'LineWidth',0.5,'color','b',...
                       'visible',eStr{1+double(aok(iApp) && ok(i))});                
        end

        % updates the axis limits
        set(hAx,'yLim',[1 nFly]+0.5*[-1.002 1])  
        resetXTickMarkers(hAx)

    else
        % turns the image axis off 
        setAxisObjVisibility(hObjImg,'off')
        setObjVisibility(hPos,'off')
    end        
else        
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
        resetXTickMarkers(hAx)

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
function Z = setupPlotValues(snTot,Pz,type,iApp)

% parameters
pW = 1.05;
iMov = snTot.iMov;

% if the region is rejected, then exit with a NaN value
if isempty(Pz{iApp})
    Z = NaN;
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
        iGrp = getRegionGroupIndices(iMov,iMov.pInfo.gName);
        Zgrp = cell(1,max(iGrp(:)));
        
        % calculates the avg. velocity based on the grouping type          
        [jGrp,okGrp] = deal(num2cell(iGrp,1),num2cell(flyok,1));
        for i = 1:length(Zgrp)
            Zgrp{i} = cell2mat(cellfun(@(x,j,ok)...
                            (x(:,(j==i) & ok)),Pz,jGrp,okGrp,'un',0));
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

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- resets the GUI objects with the new solution file struct, snTot --- %
function resetGUIObjects(handles,snTot)

% global variables
global dT

% object handle and data struct retrieval
hAx = handles.axesImg;
hFig = handles.figFlyCombine;
hGUIInfo = getappdata(hFig,'hGUIInfo');

% removes an previous information GUIs
if ~isempty(hGUIInfo)
    setappdata(hFig,'hGUIInfo',[])
    hGUIInfo.closeFigure();           
end

% creates a waitbar figure
h = ProgBar('Creating Fly Information Sub-GUI...',...
            'Initialising Experimental Solution Data GUI',1);

% makes the GUI invisible
setObjVisibility(hFig,'off'); 
pause(0.01);

% initialises the parameter struct
iPara = initParaStruct(snTot);

% sets the visibility of the orientation angle menu item
setObjVisibility(handles.menuOrientAngle,isfield(snTot,'Phi'))
    
% sets the major structs into the main GUI
setappdata(hFig,'snTot',snTot)
setappdata(hFig,'iPara',iPara);

% updates the table
updateAppNameTable(handles) 

% initialises the GUI text/parameters fields and other objects
h.Update(1,'Initialising GUI Objects and Plot Markers...',0.8);
set(0,'CurrentFigure',hFig)
set(hFig,'CurrentAxes',hAx)
initSolnInfo(handles)
initExptInfo(handles)

% creates a variable region information GUI
hGUIInfo = FlyInfoGUI(handles,snTot,h,false);   
setappdata(hFig,'hGUIInfo',hGUIInfo);

% updates the menu properties
setObjEnable(handles.menuPlotData,'on')
updateViewMenu(handles,handles.menuViewXData,1)
setObjEnable(handles.menuViewYData,snTot.iMov.is2D)
setObjEnable(handles.menuViewXYData,snTot.iMov.is2D)

% initialises the axes plot
initPlotObjects(handles,snTot)
initLimitMarkers(handles)
popupAppPlot_Callback(handles.popupAppPlot, [], handles)

% initialise
[T0,T] = deal(snTot.iExpt(1).Timing.T0,snTot.T);
T0vec = calcTimeString(T0,0);
Tfvec = calcTimeString(T0,T{end}(end));
txtStart = datestr(iPara.Ts0,'mmm dd, YYYY HH:MM AM');
txtFinish = datestr(iPara.Tf0,'mmm dd, YYYY HH:MM AM');

% updates the table information colours
evnt = struct('NewData',snTot.iMov.pInfo.gName{1},'Indices',[1,1]);
tableAppInfo_CellEditCallback(handles.tableAppInfo, evnt, handles) 

% sets the initial time location properties
initTimeLocationProps(handles,handles.panelStartTime,T0vec)
initTimeLocationProps(handles,handles.panelFinishTime,Tfvec)

% retrieves the new time value
set(handles.textStartTime,'string',txtStart)
set(handles.textFinishTime,'string',txtFinish)
setObjEnable(handles.toggleZoom,'on')
setObjEnable(handles.menuSaveSingleSoln,'on')

% updates the experiment durations
dTnw = min(dT,calcTimeDifference(iPara.Tf0,iPara.Ts0));
[~,~,tStr] = calcTimeDifference(dTnw);
textDur = sprintf('%s Days, %s Hours, %s Mins',tStr{1},tStr{2},tStr{3});
set(handles.textSolnDur,'string',textDur)

% makes the GUI visible again
hProp0 = getHandleSnapshot(handles);
setObjVisibility(hFig,'on'); 
pause(0.05);

% updates the 
resetHandleSnapshot(hProp0)
setObjVisibility(hGUIInfo.hFig,1);
uistack(hGUIInfo.hFig,'top')

% updates and closes the waitbar figure
h.Update(1,'GUI Initialisation Complete',1); pause(0.1);
h.closeProgBar();

% --- combines all the solution files in the directory list, fDir --- %
function [snTot,iMov] = combineAllSolnFiles(fDir,fFile)

% global variables
global hh

% memory allocation
nDir = length(fDir);
[snTotT,iMovNw] = deal(cell(nDir,1));

% creates the waitbar figure
wStr = {'Overall Progress','Loading Video Solution Files',...
        'Post-Processing Data'};
hh = ProgBar(wStr,'Combining Multi-Experiment Solution Files');

% for all the solution files, open and read them
for i = 1:nDir
    % updates the waitbar figure
    wStrNw = sprintf('%s (Directory %i of %i)',wStr{1},i,nDir);
    if hh.Update(1,wStrNw,i/nDir)
        % if the user cancelled, then exit the function
        [hh,snTot,iMov] = deal([]);
        return
    end

    % loads the solution file data and the sub-region data struct
    [snTotT{i},iMovNw{i}] = combineSolnFiles(fFile{i});    
    
    % otherwise, loads the combined solution files
    if i == 1
        iMov = iMovNw{i};
    end
end

% converts the cell array to a data struct
snTotT = cell2mat(snTotT);

% determines the time offset for each of the experiments
T0 = field2cell(field2cell(field2cell(snTotT,'iExpt',1),'Timing',1),'T0');
tOfs = cellfun(@(x)(calcTimeDifference(x,T0{1})),T0);

% sets the first struct to be the base data struct, and append all the
% other data struct to this one
snTot = snTotT(1);
for i = 2:nDir
    % updates the waitbar figure
    wStrNw = sprintf('%s (Directory %i of %i)',wStr{3},i,nDir);
    if h.Update(3,wStrNw,(i-1)/nDir)
        % if the user cancelled, then exit the function
        [snTot,hh] = deal([]);
        return
    end
    
    % updates the start/finish time arrays
    snTot.T = [snTot.T;cellfun(@(x)(x+tOfs(i)),snTotT(i).T,'un',0)];
    snTot.Ts = [snTot.Ts;cellfun(@(x)(x+tOfs(i)),snTotT(i).Ts,'un',0)];
    snTot.Tf = [snTot.Tf;cellfun(@(x)(x+tOfs(i)),snTotT(i).Tf,'un',0)];
    snTot.isDay = [snTot.isDay,snTotT(i).isDay];
        
    % sets the new time binned indices
    snTot.Px = cellfun(@(x,y)([x;y]),snTot.Px,snTotT(i).Px,'un',0);
    snTot.Py = cellfun(@(x,y)([x;y]),snTot.Py,snTotT(i).Py,'un',0);
    [snTot.iExpt(i),snTot.sgP(i)] = deal(snTotT(i).iExpt,snTotT(i).sgP);        
end

% closes the waitbar figure
hh.Update(3,'Post-Processing Complete!',1);
hh.closeProgBar();
hh = [];

% --- updates the apparatus name table panel --- %
function updateAppNameTable(handles)

% parameters and other initialisations
nAppMx = 9;
hFig = handles.figFlyCombine;
snTot = getappdata(hFig,'snTot');
gName0 = snTot.iMov.pInfo.gName;   

% sets the group name strings
if snTot.iMov.is2D
    [cHdr0,gStr] = deal('2D Arena Grouping Names','Column');
else
    [cHdr0,gStr] = deal('1D Region Grouping Names','Region');
end


% reduces the region information 
snTot.iMov = reduceRegionInfo(snTot.iMov);
setappdata(hFig,'snTot',snTot)

% sets the table information
iok = snTot.iMov.ok(:);
if snTot.iMov.is2D
    % case is a 2D expt setup
    Data = [gName0(iok) num2cell(iok)];        
else
    % case is 1D expt setup 
    Data = [gName0(:) num2cell(iok)];
end           

% resets the 
Data(~snTot.iMov.ok,1) = {'% REJECTED %'};

% sets the table row headers
if snTot.iMov.is2D
    lblStr = 'Group Name: ';
    rowName = cellfun(@(x)(sprintf('%s #%i',gStr,x)),...
                            num2cell(1:size(Data,1)),'un',0);  
else
    lblStr = 'Region Location: ';
    rowName = setup1DRegionNames(snTot.iMov.pInfo,2);
end

% sets the table panel dimensions (depending on OS type)
[X0,Y0] = deal(10,10);

% retrieves the height of the popup object
pApp = get(handles.popupAppPlot,'position'); 
pPos = get(handles.panelFinishTime,'position');
pPosT = get(handles.panelAppInfo,'position');

% updates the group name table information
cHdr = {cHdr0,'Include?'};
bgCol = getTableBGColours(handles,snTot);
setObjEnable(handles.tableAppInfo,~isempty(snTot))
set(handles.tableAppInfo,'RowName',rowName,'ColumnName',cHdr,...
                         'Data',Data,'BackgroundColor',bgCol)                                         
                     
% resets the panel/panel object positions  
nAppF = min(size(Data,1),nAppMx);
[tPos,Hpop] = deal(setTableDimensions(handles,nAppF,0),pApp(4));

% sets the final table/panel position vectors
pAppF = [X0 0 (tPos(3)+2*X0) (tPos(4)+4*Y0+Hpop)];
pAppF(2) = pPos(2) - (pAppF(4) + Y0);
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

% --- retrieves the table background colours
function [bgCol,iGrpNw] = getTableBGColours(handles,snTot)

% sets the default input arguments (if not provided)
if ~exist('snTot','var')
    snTot = getappdata(handles.figFlyCombine,'snTot');
end

% retrieves the unique group names from the list
grayCol = 0.81;
[gName,~,iGrpNw] = unique(snTot.iMov.pInfo.gName,'stable');

% sets the background colour based on the matches within the unique list
tCol = getAllGroupColours(length(gName),1);
bgCol = tCol(iGrpNw,:);
bgCol(~snTot.iMov.ok,:) = grayCol;

% --- updates the table dimensions
function tabPos = setTableDimensions(handles,nApp,isInit)

% parameters
hFig = handles.figFlyCombine;
pPos = get(handles.tableAppInfo,'position');
[X0,Y0,Wf,W,W0,isMove] = deal(10,10,55,pPos(3),0,false);

% retrieves the figure positional vector
fPos0 = get(hFig,'position');

% retrieves the base table dimensions
while W0 == 0
    % retrieves the table dimensions
    [~,~,W0] = getTableDimensions(getappdata(hFig,'jObjT'));
    
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
if isInit; autoResizeTableColumns(handles.tableAppInfo); end

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

%
function setAxisObjVisibility(hObjImg,state)

if strcmp(state,'on')
    hGrpFill = findall(hObjImg,'tag','hGrpFill');
    setObjVisibility(setxor(hObjImg,hGrpFill),'on');
else
    setObjVisibility(hObjImg,'off')
end

% --- updates the group colours
function updateGroupColours(handles,indNw,nwData)

% global variables
global tableUpdating

% retrieves the cell indices
hFig = handles.figFlyCombine;   
snTot = getappdata(hFig,'snTot'); 
hGUIInfo = getappdata(hFig,'hGUIInfo');

% updates the information table
if ~isempty(hGUIInfo)
    % initialisations
    jT = hGUIInfo.jTable;
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
            nFly = size(snTot.Px{indNw(1)},2);
            chkVal = num2cell(flyok(:,indNw(1)));
            chkVal((nFly+1):end) = {[]};                    
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
