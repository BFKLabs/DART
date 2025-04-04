function varargout = FlySolnView(varargin)
% Last Modified by GUIDE v2.5 06-Feb-2022 18:18:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FlySolnView_OpeningFcn, ...
                   'gui_OutputFcn',  @FlySolnView_OutputFcn, ...
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

% --- Executes just before FlySolnView is made visible.
function FlySolnView_OpeningFcn(hObject, ~, handles, varargin)

% global variables
global isDetecting nFrmRS updateFlag2 regSz
updateFlag2 = 2; pause(0.1); 

% retrieves the regular size of the GUI
regSz = get(handles.panelImg,'position');

% Choose default command line output for FlySolnView
handles.output = hObject;

% sets the input arguments
hGUI = varargin{1};

% determines if the video is 2D or not
iMov = get(hGUI.output,'iMov');
iData = get(hGUI.output,'iData');

% initialises the custom object properties
addObjProps(hObject,'hGUI',hGUI,'iMov',iMov,'iData',iData,'T',[],...
                    'sFac',iData.exP.sFac,'vType',[],'nNaN',[],...
                    'Dfrm',[],'tTick0',[],'tTickLbl0',[],'phObj',[],...
                    'iPara',initParaStruct,'dyLim',0.025,'isMltTrk',[]);
                                
% sets the functions that are to be used outside the GUI
addObjProps(hObject,'updateFunc',@updatePlotObjects,...
                    'initFunc',@initPlotObjects)

% sets the number of frame read per image stack
nFrmRS = getFrameStackSize();
hObject.isMltTrk = detMltTrkStatus(hObject.iMov);

if hObject.isMltTrk
    hObject.iMov.is2D = true;
elseif ~isfield(hObject.iMov,'is2D')
    hObject.iMov.is2D = is2DCheck(hObject.iMov);
end

% if detecting, then don't allow the data tool
if isDetecting
    setObjEnable(handles.uiDataTool,'off') 
end
    
% sets the view type
if hObject.iMov.is2D   
    set(handles.menuViewXY,'checked','on');
    set(hObject,'vType',[1 1])
else
    setObjEnable(handles.menuPlotData,'off')
    set(hObject,'vType',[1 0])
end

% initialises the menu and plot objects
initMenuObjects(handles)
initPlotObjects(handles)

% centres the figure in the middle of the screen
centreFigPosition(hObject);

% resizes the 
% set(hObject,'ResizeFcn',{@figFlySolnView_ResizeFcn,guidata(hObject)});
% resetFigSize(guidata(hObject),getFinalResizePos(hObject,500,400))

% ensures that the appropriate check boxes/buttons have been inactivated
setObjVisibility(hObject,'on'); pause(0.1);
updateFlag2 = 0; pause(0.1); 

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes FlySolnView wait for user response (see UIRESUME)
% uiwait(handles.figFlySolnView);

% --- Outputs from this function are returned to the command line.
function varargout = FlySolnView_OutputFcn(~, ~, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                       TOOLBAR CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% -------------------------------------------------------------------------
function uiZoomAxes_ClickedCallback(hObject, ~, handles)

% global variables
global isDetecting

% toggles the zoom
switch get(hObject,'state')
    case ('on') % case is the zoom is turned on        
        % turns the zoom on
        zoom xon                  
        
        % disables the relevant objects
        set(setObjEnable(handles.uiDataTool,'off'),'state','off')
        uiDataTool_ClickedCallback(handles.uiDataTool, '1', handles)        
    case ('off') % case is the zoom is turned off        
        % turns the zoom off        
        zoom off
        
        % if detecting, then don't allow the data tool
        if ~isDetecting
            setObjEnable(handles.uiDataTool,'on')    
        end
end

% -------------------------------------------------------------------------
function uiDataTool_ClickedCallback(hObject, eventdata, handles)

% toggles the zoom
switch get(hObject,'state')
    case ('on') % case is the data tool is turned on        
        % sets the mouse-motion function
        wmFunc = {@resetMarkerLine,handles}; 
        set(handles.output,'WindowButtonMotionFcn',wmFunc)                                        
        
        % sets the button-down function
        bdFunc = {@updateMainFrame,handles}; 
        set(handles.output,'WindowButtonDownFcn',bdFunc)                                                
        
    case ('off') % case is the data tool is turned off
        % disables the relevant objects
        set(handles.output,'WindowButtonMotionFcn',[])                                
        setObjVisibility(findobj(handles.output,'tag','hMark'),0)
        setObjVisibility(findobj(handles.output,'tag','hText'),0)
        
        % sets the window button function (not for zooming function
        if ~isa(eventdata,'char')
            set(handles.output,'WindowButtonDownFcn',[])
        end
end

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% ----------------------- %
% --- FILE MENU ITEMS --- %
% ----------------------- %

% -------------------------------------------------------------------------
function menuDiagCheck_Callback(~, ~, handles)

% calculates the NaN count/inter-frame displacement 
[handles.output.nNaN,handles.output.Dfrm] = calcDiagnosticValue(handles);

% runs the solution diagnostic check
SolnDiagCheck(handles.figFlySolnView);

% -------------------------------------------------------------------------
function menuClose_Callback(~, ~, handles)

% retrieves the tracking GUI handles and the related GUI object handles
hGUI = get(handles.output,'hGUI');
hFigM = hGUI.output;

% deletes the options GUI (if open)
hOptions = findall(0,'tag','figMetricPara');
if ~isempty(hOptions); delete(hOptions); end

% closes the GUI through the calling GUI
hFigM.menuViewProgress_Callback(hGUI.menuViewProgress,[],hGUI)

% sets the tracking GUI on top
uistack(hFigM,'top')

% ------------------------------ %
% --- PLOT METRIC MENU ITEMS --- %
% ------------------------------ %

% --- update function for the position data menu item selection
function menuSelectUpdate(hObject, eventdata, handles)

% initialisations
isUpdate = true;
hMenuMet = [get(handles.menuFlyPos,'children');handles.menuAvgSpeed;...
            handles.menuAvgInt;handles.menuImgTrans];
hMenu = findobj(hMenuMet,'type','uimenu','checked','on');

% retrieves the menu item that is currently checked
if isempty(hMenu)
    % if there is no menu item selected, then set the current menu
    isUpdate = true;
    set(hObject,'checked','on')
    
elseif hMenu ~= hObject
    % turns off the check for the previous menu, and set the current menu
    set(hMenu,'checked','off')
    set(hObject,'checked','on')
    
else
    % set the update flag to false
    isUpdate = isa(eventdata,'char');
end

% updates the plot (if one is required)
if isUpdate
    updatePlotObjects(handles)
    
    % resets the zoom (if on)
    if strcmp(get(handles.uiZoomAxes,'state'),'on')
        zoom reset
    end    
end

% --------------------------------------------------------------------
function menuMetricOptions_Callback(hObject, ~, handles)

% if the metric parameter GUI is already open then exit
if strcmp(get(hObject,'Checked'),'on')
    return
end

% runs the solution metric parameter GUI
set(hObject,'Checked','on');
SolnMetricPara(handles.figFlySolnView);

% --------------------------------------------------------------------
function menuShowPhase_Callback(hObject, ~, handles)

% retrieves the phase object
eStr = {'off','on'};
isCheck = strcmp(get(hObject,'Checked'),'on');
hPhase = findall(handles.axesImg,'tag','hPhase');

% updates the menu check mark
setObjVisibility(hPhase,~isCheck);
set(hObject,'Checked',eStr{~isCheck+1})

% -------------------------------- %
% --- POSITION DATA MENU ITEMS --- %
% -------------------------------- %

% -------------------------------------------------------------------------
function menuTime_Callback(hObject, ~, handles)

% resets the check labels
if strcmp(get(hObject,'checked'),'on')
    % item already checked, so exit function
    return
else
    % toggles the checks between menu items
    set(handles.menuTime,'checked','on')
    set(handles.menuFrmIndex,'checked','off')
end

% retrieves the axes handle and time vector
hAx = findall(handles.output,'type','axes');
set(findall(hAx,'tag','hXLbl'),'string','Time (min)')

% updates the ticklabel
set(hAx,'xtick',get(handles.output,'tTick0'))
set(hAx,'xTickLabel',get(handles.output,'tTickLbl0'))

% -------------------------------------------------------------------------
function menuFrmIndex_Callback(hObject, ~, handles)

% resets the check labels
if strcmp(get(hObject,'checked'),'on')
    % item already checked, so exit function
    return
else
    % toggles the checks between menu items
    set(handles.menuTime,'checked','off')
    set(handles.menuFrmIndex,'checked','on')
end

% retrieves the axes handle and time vector
hAx = handles.axesImg;
set(findall(hAx,'tag','hXLbl'),'string','Frame Index')

% retrieves the original x-axis tick labels
T = get(handles.output,'T');
tTick0 = get(handles.output,'tTick0');

% reset the tick label values
dTLbl = [50 100 200 500 1000 1500 2000 2500 5000];
idTLbl = find(length(T)./dTLbl >= length(tTick0),1,'last');
tTickNw = (0:dTLbl(idTLbl):length(T));

% updates the axis label
tLblNw = cellfun(@(x)(num2str(x)),num2cell(tTickNw),'un',0);
set(hAx,'xtick',T(tTickNw+1)/60,'xticklabel',tLblNw);

% -------------------------------------------------------------------------
function menuViewXY_Callback(hObject, ~, handles)

% updates the view menu properties and the viewing axes
updateViewMenu(handles,hObject,[1 1])

% -------------------------------------------------------------------------
function menuViewX_Callback(hObject, ~, handles)

% updates the view menu properties and the viewing axes
updateViewMenu(handles,hObject,[1 0])

% -------------------------------------------------------------------------
function menuViewY_Callback(hObject, ~, handles)

% updates the view menu properties and the viewing axes
updateViewMenu(handles,hObject,[0 1])

% -------------------------- %
% --- STIMULI MENU ITEMS --- %
% -------------------------- %

% -------------------------------------------------------------------------
function menuShowStim_Callback(hObject, ~, handles)

% initialistions
dY = 10;
eStr = {'off','on'};
isChecked = strcmp(get(hObject,'Checked'),'on');

% object handles
hFig = handles.output;
hPanelI = handles.panelImg;
hPanelS = handles.panelStim;

% updates the object properties
set(hObject,'Checked',eStr{2-isChecked})
setObjVisibility(hPanelS,~isChecked)

% determines the height change in the figure
hUnitsS = get(hPanelS,'Units');
set(hPanelS,'Units','Pixels');
pPos = get(hPanelS,'Position');
set(hPanelS,'Units',hUnitsS);

% sets the height change
dHght = (1-2*isChecked)*(sum(pPos([2,4]))+dY);

% updates the figure properties
hUnitsF = get(hFig,'Units');
set(hFig,'Units','Pixels')
resetObjPos(hFig,'Height',dHght,1)
fPos = get(hFig,'Position');
set(hFig,'Units',hUnitsF)

% updates the image panel properties
hUnitsI = get(hPanelI,'Units');
set(hPanelI,'Units','Pixels')

%
if isChecked
    [y0nw,Hnw] = deal(dY,fPos(4)-2*dY);
else
    y0nw = dHght+2*dY;
    Hnw = fPos(4)-(dY+y0nw);
end

% resets the panel units
resetObjPos(hPanelI,'bottom',y0nw);
resetObjPos(hPanelI,'height',Hnw);
set(hPanelI,'Units',hUnitsI)

% -------------------------------------------------------------------------
function menuPhaseStats_Callback(hObject, ~, handles)

% object handles
hFig = handles.output;

switch get(hObject,'Checked')
    case 'on'
        % case is closing an open statistics GUI
        hFig.phObj.closeGUI([],hFig.phObj);
        set(hObj,'Checked','off');

        % clears the statistics object
        hFig.phObj = [];                    

    case 'off'
        % case is opening the statistics GUI
        hFig.phObj = InitPhaseStats(hFig);
        set(hObject,'Checked','on');                    

end

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ----------------------------- %
% --- MAIN FIGURE CALLBACKS --- %
% ----------------------------- %

% --- Executes when figFlySolnView is resized.
function figFlySolnView_ResizeFcn(~, ~, ~)

% % global variables
% global updateFlag2 uTime2
% 
% % resets the timer
% uTime2 = tic;
% 
% % dont allow any update (if flag is set to 2)
% if updateFlag2 ~= 0
%     return
% else
%     updateFlag2 = 2;
%     while (toc(uTime2) < 0.5)
%         java.lang.Thread.sleep(10);
%     end
% end
% 
% % parameters
% [Wmin,Hmin] = deal(500,400);
% 
% % retrieves the final position of the resized GUI
% fPos = getFinalResizePos(hObject,Wmin,Hmin);
% 
% % otherwise, update the figure position
% resetFigSize(handles,fPos)
% 
% % makes the figure visible again
% updateFlag2 = 2;
% setObjVisibility(hObject,'on');
% 
% % ensures the figure doesn't resize again (when maximised)
% pause(0.5);
% updateFlag2 = 0;

% --- resizes the combining GUI objects
function resetFigSize(h,fPos)

% sets the overall width/height of the figure
[W0,H0,dY,dX] = deal(fPos(3),fPos(4),10,10);
dPos = {[80,2*dX],[85,70]};

% updates the image panel dimensions
pPos = [dX,dY,(W0-2*dX),(H0-2*dY)];
set(h.panelImg,'units','pixels','position',pPos)

% updates the plot axes dimensions
hAx = findall(h.panelImg,'type','axes');
axPos = [dPos{1}(1),dPos{2}(1),pPos(3)-sum(dPos{1}),pPos(4)-sum(dPos{2})];
set(hAx,'Units','Pixels','Position',axPos);

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% ---------------------------------------------- %
% --- OBJECT INITIALISATION/UPDATE FUNCTIONS --- %
% ---------------------------------------------- %

% --- initialises the solution file information --- %
function initMenuObjects(handles)

% retrieves the fly positional data struct
hGUI = get(handles.output,'hGUI');
iMov = hGUI.output.iMov;
pData = hGUI.output.pData;
hMenuP = handles.menuFlyPos;
isMltTrk = detMltTrkStatus(iMov);
bFunc = {@menuSelectUpdate,handles};

% sets the menu enable string
if isempty(pData)
    mStr = 'off';     
else
    mStr = 'on'; 
end

% sets the fly indices for each region (multi-tracking only)
if isMltTrk
    % initialisations
    nFlyMx = 20;    
    nReg = iMov.pInfo.nRow*iMov.pInfo.nCol;
    pInd = cell(nReg,1);
    
    % sets the fly indices for each 
    indM = 1:nReg;
    for i = indM
        % retrieves the fly count
        iC = mod(i-1,iMov.pInfo.nCol) + 1;        
        iR = floor((i-1)/iMov.pInfo.nCol) + 1;
        nFly = iMov.pInfo.nFly(iR,iC);
        
        % calculates the number of new menus and the fly count
        nMenu = ceil(nFly/nFlyMx);
        nFlyP = ceil(nFly/nMenu);
        
        % sets the indices of the fly count for each region
        pInd{i} = arrayfun(@(x)(...
                ((x-1)*nFlyP+1):min(nFly,(x*nFlyP))),1:nMenu,'un',0)';
    end        
else
    indM = find(hGUI.output.iMov.ok(:)');
end

% sets the diagnostic check menu item
setObjEnable(handles.menuDiagCheck,mStr)

% creates the new apparatus markers
for i = indM
    % creates the new menu item
    if isMltTrk
        % creates the menus for each sub-grouping
        for j = 1:length(pInd{i})
            uData = [i,pInd{i}{j}([1,end])];
            lStr = sprintf('Region %i (Fly %i-%i)',i,uData(2),uData(3));
            hMenuNw = uimenu(hMenuP,'Label',lStr);                 
            set(hMenuNw,'Callback',bFunc,'UserData',uData,'Enable',mStr)
        end
    else
        % sets the menu item callback function
        hMenuNw = uimenu(hMenuP,'Label',sprintf('Region %i',i));     
        set(hMenuNw,'Callback',bFunc,'UserData',i,'Enable',mStr)
    end
end

% creates the new menu item
bFunc = {@menuSelectUpdate,handles};
set(handles.menuAvgSpeed,'Callback',bFunc,'UserData',0,'checked','on')
set(handles.menuAvgInt,'Callback',bFunc,'UserData',-1)
set(handles.menuImgTrans,'Callback',bFunc,'UserData',-2)

% --- initialises the solution file information --- %
function initPlotObjects(handles,varargin)

% object handle retrieval
hFig = handles.output;
hAxI = handles.axesImg;

% ------------------------------------------- %
% --- INITIALISATIONS & MEMORY ALLOCATION --- %
% ------------------------------------------- %

% clears the image axis
cla(hAxI)
axis(hAxI,'on')

% retrieves the fly positonal data struct
hGUI = get(hFig,'hGUI');
iMov = get(hGUI.output,'iMov');
iData = get(hGUI.output,'iData');

% sets the fly count (based on tracking type)
if hFig.isMltTrk
    nFly = max(iMov.pInfo.nFly(:));
else
    nFly = getSRCountMax(iMov);
end

% other initialisations
eStr = {'off','on'};
axCol = 0.9*ones(1,3);
[Tmlt,T] = deal(1/60,setupTimeVector(handles));
nApp = length(iMov.iR);
NN = max(nFly,nApp);

% sets up the time labels
set(hFig,'T',T)

% retrieves the font-sizes
[axSz,lblSz,tSz] = detSolnViewFontSizes(handles);

% determines if the gui is being initialised
hYLbl = findall(hAxI,'tag','hYLbl');
isInit = isempty(hYLbl);

% retrieves the phase information
if isfield(iMov,'phInfo')
    phInfo = iMov.phInfo;    
else
    phInfo = [];
end

% ---------------------------------------- %
% --- AXIS LABEL & MENU INITIALISATION --- %
% ---------------------------------------- %

% retrieves the currently selected menu item
iApp = getSelectedMenuItem(handles);

% sets the ylabels
switch iApp    
    case 0 
        % case is the average velocity             
        yLimT = [1 nApp] + 0.5*[-1 1];
        yLblStr = 'Group Index';      
        
    otherwise
        % case is the positional traces
        yLimT = [1 nFly] + 0.5*[-1 1];
        yLblStr = 'Sub-Region Index';
end

% sets the time axis limits
pDel = diff(T([1 end])*Tmlt)*0.001;
xLimT = T([1 end])*Tmlt-[pDel,0]';

% creates/resets the y-axis label
if isInit
    ylabel(hAxI,yLblStr,'fontweight','bold',...
                'fontsize',lblSz,'tag','hYLbl')
else
    set(hYLbl,'string',yLblStr)
end

% sets the limits based on the 
if nFly > nApp
    yTick = 1:nFly;
    yStr = cellfun(@(x)(sprintf('%i',x)),num2cell(1:nFly)','un',0);    
    
else
    yTick = 1:nApp;   
    yStr = cellfun(@(x)(sprintf('%i',x)),num2cell(1:nApp)','un',0);
end

% creates/resets the x-axis label/titles
if isInit
    % case is the labels are missing
    title(hAxI,'Average Velocity','fontweight','bold',...
                'fontsize',tSz,'tag','hTitle');
    xlabel(hAxI,'Time (min)','fontweight','bold',...
                'fontsize',lblSz,'tag','hXLbl')
else
    % case is the labels are present
    set(findall(hAxI,'tag','hTitle'),'string','Average Velocity');        
    set(findall(hAxI,'tag','hXLbl'),'string','Time (min)');
end

% ------------------------- %
% --- PHASE PATCH SETUP --- %
% ------------------------- %

% initialises the phase patch markers
initPhaseMarkers(handles,yLimT);

% ---------------------------------- %
% --- PLOT MARKER INITIALISATION --- %
% ---------------------------------- %

% adds a hold to the axis
hold(hAxI,'on')

% plots the population markers
plot(hAxI,NaN,NaN,'r','tag','hLinePop','Linewidth',1,'hittest','off');    
                        
% plots the x-coordinate marker
plot(hAxI,NaN,NaN,'b','tag','hLineInd','Linewidth',1);
if hFig.iMov.is2D 
    % creates the y-coordinate marker (2D only)
    plot(hAxI,NaN,NaN,'r','tag','hLineInd2','Linewidth',1,'hittest','off');
end

% plots the separation markers
TM = arr2vec(repmat([T([1 end])*Tmlt-[pDel;0];NaN],1,NN));
YM = arr2vec([repmat((1:NN)+0.5,2,1);NaN(1,NN)]);
plot(hAxI,TM(1:end-1),YM(1:end-1),'k','linewidth',1,'hittest','off');

% updates the axis properties
set(hAxI,'xlim',xLimT,'ylim',yLimT'-[0.001;0],...
         'yticklabel',yStr,'ytick',yTick);
if isInit
    % sets any initialisation only properties
    set(hAxI,'fontweight','bold','fontsize',axSz,'UserData',1,...
             'Color',axCol,'box','on','LineWidth',1.5,...
             'TickLength',[0,0],'xgrid','on');
end

% sets the original tick mark/labels
set(hFig,'tTick0',get(hAxI,'xTick'),'tTickLbl0',get(hAxI,'xTickLabel'))    
    
% ---------------------------------- %
% --- PLOT MARKER INITIALISATION --- %
% ---------------------------------- %

if ~isempty(phInfo)
    % sets the frame indices and mean image pixel intensity
    [ii,Imu] = deal(phInfo.iFrmF,mean(phInfo.DimgF,2));

    % sets up the plot values  
    yLim = [floor(min(Imu)),ceil(max(Imu))];                
    yPlt = hFig.dyLim + (1-2*hFig.dyLim)*(Imu-yLim(1))/diff(yLim);

    % plots image average intensity line
    hAvgTag = 'hLineAvg';
    [yLo,yHi] = deal(hFig.dyLim*[1,1],(1-hFig.dyLim)*[1,1]);
    plot(hAxI,T(ii)*Tmlt,yPlt,'kx-','tag',hAvgTag,'LineWidth',1,...
                        'UserData',1,'Visible','off');
    plot(hAxI,xLimT,yLo,'r:','tag',hAvgTag,'LineWidth',1,...
                        'UserData',2,'Visible','off');
    plot(hAxI,xLimT,yHi,'r:','tag',hAvgTag,'LineWidth',1,...
                        'UserData',2,'Visible','off');

    % sets up the axis limits based on whether there is translation
    if any(phInfo.hasT)
        % sets the y-axis limits
        pOfsT = calcImageStackFcn(phInfo.pOfs);
        yLim = [min(-1,min(pOfsT(:))),max(1,max(pOfsT(:)))];

        % sets the plot values
        pWL = (1-2*hFig.dyLim)/diff(yLim);
        tPlt = T(phInfo.iFrm0)*Tmlt;
        yPltX = hFig.dyLim + pWL*(pOfsT(:,1)-yLim(1));
        yPltY = hFig.dyLim + pWL*(pOfsT(:,2)-yLim(1));
        yPlt0 = hFig.dyLim + pWL*([0,0]-yLim(1));

    else
        % case is there is no major translation
        tPlt = T([1,end])*Tmlt;
        [yPltX,yPltY,yPlt0] = deal(0.5*[1,1]);
    end

    % plot image translation line
    hLTag = 'hLineTrans';
    plot(hAxI,xLimT,yPlt0,'k','tag',hLTag,'LineWidth',2,'Visible','off');
    hPlt = [plot(hAxI,tPlt,yPltX,'b','tag',hLTag,'LineWidth',2);...
            plot(hAxI,tPlt,yPltY,'r','tag',hLTag,'LineWidth',2)];
    plot(hAxI,xLimT,yLo,'k:','tag',hLTag,'LineWidth',1,'Visible','off');
    plot(hAxI,xLimT,yHi,'k:','tag',hLTag,'LineWidth',1,'Visible','off');
    setObjVisibility(hPlt,'off')

    % creates the legend object
    hLg = legend(hPlt,{'X-Offset';'Y-Offset'});
    set(hLg,'location','best','tag','hLegend','location','northwest',...
            'Box','off','FontWeight','Bold','Visible','off');
end

% -------------------------------------- %
% --- STIMULI MARKER INITIALISATIONS --- %
% -------------------------------------- %

% resets the object property units
resetObjProps(hFig,'Units','Pixels')
resetObjProps(hAxI,'FontUnits','Pixels')

% parameters
isShow = addStimAxesPanels(handles,iData.stimP,iData.sTrainEx,T,isInit);
setObjEnable(set(handles.menuShowStim,'Checked',eStr{1+isShow}),isShow)

% updates the visibility of the stimuli related objects
if ~isInit
    setObjVisibility(handles.menuShowStim,isShow);
    setObjVisibility(handles.panelStim,isShow)
end

% ------------------------------------------- %
% --- DATA INFORMATION BOX INITIALISATION --- %
% ------------------------------------------- %

if isInit
    % sets the text label
    hText = imtext(0,0,{''},'right');
    set(hText,'tag','hText','parent',hAxI,'visible','off','FontSize',8,...
                'FontWeight','bold','EdgeColor','k','LineWidth',1,...
                'BackgroundColor','y')
    % sets up the marker line
    hMark = plot(hAxI,NaN,NaN,'k','linewidth',1,'tag','hMark');

    % Create menu items for the uicontextmenu
    c = uicontextmenu;
    set(hMark,'UIContextMenu',c)
    uimenu(c,'Label','Goto Video Frame',...
             'Callback',{@updateMainFrame,handles});
end

% ------------------------------ %
% --- HOUSE-KEEPING ROUTINES --- %
% ------------------------------ %

% ensures the average speed menu item is selected
toggleLineMarker(hFig.iMov,hAxI,1)

% removes hold from the axis
hold(hAxI,'off')
axis(hAxI,'ij')
zoom(hAxI,'reset')

% sets the initial plot to be the average velocity
if nargin == 1
    hMenu = findobj(handles.menuPlotMetrics,'type','uimenu','UserData',0);
    menuSelectUpdate(hMenu, '1', handles)
end

% resets the object property units
resetObjProps(hFig,'Units','Normalized')
resetObjProps(hAxI,'FontUnits','Normalized')
set(hFig,'Units','Pixels')
    
% --- update function for the position data menu items
function updateViewMenu(handles,hMenu,vType)

% if the menu item is already checked, then exit the function
if strcmp(get(hMenu,'checked'),'on'); return; end

% otherwise, remove any existing checks and turns the current one
hMenuPr = findobj(handles.menuYData,'checked','on');
set(hMenuPr,'checked','off')
set(hMenu,'checked','on')

% sets the view type to the specified
set(handles.output,'vType',vType)

% updates the plot object
updatePlotObjects(handles)

% --- initialises the solution file information --- %
function updatePlotObjects(handles)

% retrieves the positional data
hFig = handles.output;
hGUI = get(hFig,'hGUI');
pData = hGUI.output.pData;
isMltTrk = hFig.isMltTrk;

% retrieves the font-sizes
[~,lblSz,~] = detSolnViewFontSizes(handles);

% retrieves the objects from the GUI
iMov = get(handles.output,'iMov');
vType = get(handles.output,'vType');
iPara = get(handles.output,'iPara');

% if there is no data, then exit the function
hMenu = findobj(handles.menuPlotMetrics,'type','uimenu');
ii = cellfun(@(x)(~isempty(x) && (x(1) > 0)),get(hMenu,'UserData'));
hMenu = hMenu(ii);

% determines if the update is possible
if ~hasPosData(pData)
    setObjEnable(hMenu,'off')
    return
else
    % sets the menu enable string
    setObjEnable(hMenu,'on')
end

% parameters
yDel = 0.05;

% sets the plot metric handles
hMenuMet = [get(handles.menuFlyPos,'children');handles.menuAvgSpeed;...
            handles.menuAvgInt;handles.menuImgTrans];
hMenu = findobj(hMenuMet,'type','uimenu','checked','on');

% retrieves the menu 
hAx = handles.axesImg;
hTitle = get(hAx,'Title');
uData = get(hMenu,'UserData');
setObjEnable(handles.menuYData,uData(1)>0)

% retrieves the fly positonal data struct
[T,Tmlt] = deal(get(handles.output,'T'),1/60);
[pDel,nApp] = deal(diff(get(hAx,'xlim'))*0.001,pData.nApp);

% retrieves the menu item handles
switch uData(1)
    case 0         
        % case is the average velocity
        
        % makes all the population plot lines visible and the individual
        % plot line invisible
        toggleLineMarker(iMov,hAx,1)             
        
        % sets the y-axis limits and strings
        yTick = 1:nApp;
        yStr = arrayfun(@(x)(sprintf('%i',x)),yTick(:),'un',0);
        
        % sets/updates the y-axis label
        hYLbl = findall(hAx,'tag','hYLbl');
        if isempty(hYLbl)
            ylabel(hAx,'Group Index','fontweight','bold',...
                       'fontsize',lblSz,'tag','hYLbl')
        else
            set(hYLbl,'string','Group Index')
        end
        
        % retrieves the data values based on the region struct format
        if isfield(iMov,'pInfo')
            % case is the new format solution file
            nApp = iMov.pInfo.nGrp;
            fPos = groupPosValues(hFig.iMov,pData.fPos);
        else
            % case is the old format solution file
            fPos = pData.fPos;
        end        
        
        % calculates the fly velocities (over all apparatus)        
        Vplt = cellfun(@(x)(calcPopVel(T,x,iPara.vP)),fPos,'un',0);     
        Vmax = ceil(max(cellfun(@max,Vplt)));
        VpltN = cellfun(@(x)(x/Vmax),Vplt,'un',0);                
        
        % updates the title
        tStr = sprintf('Average Velocity (V_{scale} = %i)',Vmax);
        set(hTitle,'string',tStr)        
        
        % updates the plot lines for all the apparatus
        hLine = findobj(hAx,'tag','hLinePop');

        % sets the plot indices and updates the plot data        
        [TT,VT] = deal(cell(nApp,1));
        for i = 1:nApp
            ii = 1:min(length(T),length(VpltN{i}));
            TT{i} = [T(ii)*Tmlt;NaN];
            VT{i} = [(yDel+(1-2*yDel)*(1-VpltN{i}(ii))+(i-0.5));NaN];
        end
        
        % updates the axis limits
        set(hLine,'xData',cell2mat(TT),'yData',cell2mat(VT))
        set(hAx,'yLim',[1 nApp]+0.5*[-1.002 1])         
        
    case -1
        % case is the average image intensity        
        
        % parameters
        yLblStr = 'Avg. Pixel Intensity';
        
        % toggles the line markers
        toggleLineMarker(iMov,hAx,2);        
        
        % sets up the plot values
        pInfo = iMov.phInfo;
        Imu = mean(pInfo.DimgF,2);  
        yLim = [floor(min(Imu)),ceil(max(Imu))];
        
        % updates the other object properties
        set(hAx,'yLim',[0 1])
        set(findall(hAx,'tag','hYLbl'),'String',yLblStr); 
        set(hTitle,'string','Average Image Pixel Intensity')
        
        % sets the axis limits and strings
        yTick = [hFig.dyLim,(1-hFig.dyLim)];
        yStr = arrayfun(@num2str,yLim,'un',0);
        
    case -2
        % case is the image translation        
        
        % parameters
        yLblStr = 'Image Offset (Pixels)';        
        
        % toggles the line markers
        toggleLineMarker(iMov,hAx,3)  
        
        % updates the title
                
        % sets the y-axis limits
        pOfsT = calcImageStackFcn(iMov.phInfo.pOfs);
        yLim = [floor(min(-1,min(pOfsT(:)))),ceil(max(1,max(pOfsT(:))))];        
        
        % updates the other object properties
        set(hAx,'yLim',[0 1])
        set(findall(hAx,'tag','hYLbl'),'String',yLblStr);         
        set(hTitle,'string','Image Translation')
        
        % sets the axis limits and strings
        yTick = [hFig.dyLim,(1-hFig.dyLim)];
        yStr = arrayfun(@num2str,yLim,'un',0);
        
    otherwise
        % case is the fly position plot
        
        % makes all the population plot lines invisible and the individual
        % plot line visible    
        iApp = uData(1);  
        tStr = sprintf('Region %i Location',iApp);
        
        % sets the column indices (based on tracking type)
        if isMltTrk
            % case is the multi-tracking
            iCol = mod(iApp-1,iMov.pInfo.nCol) + 1;
            iRow = floor((iApp-1)/iMov.pInfo.nCol) + 1;
        else
            % case is the single tracking
            iCol = iApp;
        end                
        
        if length(uData) == 1
            nFly = pData.nTube(iApp);
            [yLblStr,iFly] = deal('Sub-Region Index',1:nFly);
        else
            iFly = uData(2):uData(3); 
            [yLblStr,nFly] = deal('Fly Index',length(iFly));
            tStr = sprintf('%s (Fly %i-%i)',tStr,uData(2),uData(3));
        end
        
        % toggles the line markers
        toggleLineMarker(iMov,hAx,4)               
        set(hTitle,'string',tStr)
                
        % sets the visibility of the 2nd line (if 2D or multi-tracking)
        if hFig.iMov.is2D
            setObjVisibility(findobj(hAx,'tag','hLineInd2'),vType(2)); 
        end                                
        
        % sets the y-axis limits and strings
        yTick = 1:nFly;
        yStr = arrayfun(@(x)(sprintf('%i',x)),yTick','un',0);                      
        
        % sets the positional array
        if isMltTrk
            fPosNw = pData.fPos{iRow,iCol}(iFly);
        else
            fPosNw = pData.fPos{iApp}(iFly);
        end
        
        % sets/updates the y-axis label
        hYLbl = findall(hAx,'tag','hYLbl');
        if isempty(hYLbl)
            ylabel(hAx,yLblStr,'fontweight','bold',...
                    'fontsize',lblSz,'tag','hYLbl'); 
        else
            set(hYLbl,'string',yLblStr)
        end                
        
        % calculates the x-coordinates
        if vType(1)            
            % sets the lower/upper x-limits
            if isempty(iMov.iC{iCol})
                [xMin,xMax] = deal(0,1);
            else
                xMin = iMov.iC{iCol}(1) - 1;
                xMax = iMov.iC{iCol}(end) - 1; 
            end
            
%             if length(uData) > 1
%                 % determines the min/max position values over all flies
%                 % within the current region
%                 xPosL = cell2mat(cellfun(@(x)...
%                         ([min(x(:,1)),max(x(:,1))]),fPosNw(:),'un',0)); 
%                 xMin = min(xMin,min(xPosL(:,1)));
%                 xMax = max(xMax,max(xPosL(:,2)));
%             end
            
            % normalises the x-location traces
            XpltN = cellfun(@(x)...
                            ((x(:,1)-xMin)./(xMax-xMin)),fPosNw,'un',0);
        end
        
        % calculates the y-coordinates
        if hFig.iMov.is2D && vType(2)
            if length(uData) == 1
                yMin = num2cell(iMov.yTube{iCol}(:,1))';
                yMax = num2cell(iMov.yTube{iCol}(:,2))';
                YpltN = cellfun(@(x,y,z)((x(:,2)-y)./(z-y)),...
                    fPosNw,yMin,yMax,'un',0);       
            else
                % determines the min/max position values over all flies
                % within the current region
                yPosL = cell2mat(cellfun(@(x)...
                        ([min(x(:,2)),max(x(:,2))]),fPosNw(:),'un',0)); 
                yMin = min(iMov.iR{iCol}(1)-1,min(yPosL(:,1)));
                yMax = max(iMov.iR{iCol}(end)-1,max(yPosL(:,2)));                
                YpltN = cellfun(@(x,y,z)((x(:,2)-yMin)./(yMax-yMin)),...
                                        fPosNw,'un',0);                 
            end                           
        end
        
        % retrieves the x/y-coordinate marker lines
        hLineX = findobj(hAx,'tag','hLineInd');
        hLineY = findobj(hAx,'tag','hLineInd2');

        %
        setObjVisibility(hLineX,vType(1));        
        
        % updates the plot lines for all tubes
        [TT,XT,YT] = deal(cell(nFly,1));
        for i = 1:nFly
            % sets the plot indices and updates the plot data
            if vType(1)
                ii = 1:min(length(T),length(XpltN{i}));
                TT{i} = [T(ii)*Tmlt;NaN];
                XT{i} = [(yDel+(1-2*yDel)*(1-XpltN{i}(ii))+(i-0.5));NaN];
            end
                            
            if hFig.iMov.is2D && vType(2)
                % sets the plot indices
                ii = 1:min(length(T),length(YpltN{i}));                
                
                % sets the time points (if not set already)
                if isempty(TT{i})
                    TT{i} = [T(ii)*Tmlt;NaN];                    
                end

                % sets the y-coordinates
                YT{i} = [(yDel+(1-2*yDel)*(1-YpltN{i}(ii))+(i-0.5));NaN];
            end
        end        
                
        % sets the x-coordinate line marker
        TT = cell2mat(TT);
        if vType(1)
            set(hLineX,'xdata',TT,'yData',cell2mat(XT))
        end
        
        % sets the y-coordinate line marker        
        if hFig.iMov.is2D && vType(2)        
            set(hLineY,'xdata',TT,'yData',cell2mat(YT))
        end
        
        % updates the axis limits
        set(hAx,'yLim',[1 nFly]+0.5*[-1.002 1])
end

% retrieves the phase patch object handle
hPhase = findall(hAx,'tag','hPhase');
[yLimF,iy] = deal(get(hAx,'ylim'),[1,2,2,1,1]);
arrayfun(@(x)(set(x,'yData',yLimF(iy))),hPhase)

% updates the axis properties
xLim = [-pDel max(get(hAx,'xlim'))];
set(hAx,'yticklabel',yStr,'ytick',yTick,'xlim',xLim);

% updates the axis orientation
if any(uData(1) == [-1,-2])
    axis(hAx,'xy')
else
    axis(hAx,'ij') 
end

% --- groups the position values (2D expt only)
function fPos = groupPosValues(iMov,fPos0)

% initialisations
iGrp = iMov.pInfo.iGrp;
fPos = cell(1,iMov.pInfo.nGrp);

% groups the position values based on the experiment type
for i = 1:iMov.pInfo.nGrp
    % determines the region row/column indices
    [iRowG,iColG] = find(iGrp==i);
    
    % case is a 2D expt setup
    if iMov.is2D        
        % case is a 2D expt setup
        fPos{i} = arrayfun(@(ir,ic)(fPos0{ic}{ir}),iRowG,iColG,'un',0)';
        
    else
        % case is non 2D expt setup
        if detIfCustomGrid(iMov)
            % case is 1D expt with custom regions
            gID = iMov.pInfo.gID;            
            fPos{i} = cell2cell(cellfun(@(x,y)...
                    (x(y==i)),fPos0(:),gID(:),'un',0));
            
        else
            % case is the other experiment setup types
            indG = sub2ind(size(iMov.pInfo.nFly),iRowG,iColG);
            iRegG = (iRowG-1)*iMov.pInfo.nCol + iColG;
            nFly = iMov.pInfo.nFly(indG);

            fPos{i} = cell2cell(arrayfun(@(i,n)...
                                    (fPos0{i}(1:n)),iRegG,nFly,'un',0),0);
        end
    end
end

% --------------------------------------- %
% --- CONTEXT MENU CALLBACK FUNCTIONS --- %
% --------------------------------------- %

% --- context menu callback function for the plotting axis
function updateMainFrame(~, ~, handles)

% sets the current x/y location of the mouse
hAx = handles.axesImg;
cPos = get(hAx,'CurrentPoint'); mP = cPos(1,1:2);

% only update if the mouse-click was within the image axes
if isInAxes(handles,mP)
    % determines the frame that is currently selected
    T = get(handles.output,'T');
    [~,iFrm] = min(abs(T/60-mP(1)));    

    % updates the main image frame
    hGUI = get(handles.output,'hGUI');    
    set(hGUI.frmCountEdit,'string',num2str(iFrm))
    feval(hGUI.output.dispImage,hGUI)
end

% ----------------------------------------------- %
% --- POSITION/VELOCITY CALCULATION FUNCTIONS --- %
% ----------------------------------------------- %

% --- calculates the diagnostic metric values
function [nNaN,Dfrm] = calcDiagnosticValue(handles)

% global variables
global nFrmRS

% retrieves the position data struct
hFig = handles.output;
iMov = get(hFig,'iMov');
iData = get(hFig,'iData');
sFac = get(hFig,'sFac');

% retrieves the positional data array
pData = hFig.hGUI.output.pData;

% determines the first non-rejected sub-region
[j0,i0] = find(iMov.flyok,1,'first');
nFrm = size(pData.fPos{i0}{j0},1);

% ignore the last frame for .avi videos
[~,~,fExtn] = fileparts(iData.movStr);
if (strcmp(fExtn,'.avi')); nFrm = nFrm - 1; end

% ensures the frame counter index array is a cell array
frmOK = pData.frmOK;
if ~iscell(frmOK)
    frmOK = {frmOK}; 
end

% sets the indices of the frames that have already been read
if isnan(nFrmRS)
    ii = [];
elseif all(cellfun(@all,frmOK))
    ii = 1:nFrm;
else
    jj = find(~isnan(pData.fPos{i0}{j0}(:,1)),1,'last');
    ii = 1:jj;
end

% memory allocation
nNaN = cell(pData.nTube(i0),pData.nApp);
Dfrm = repmat({NaN(nFrm,1)},pData.nTube(i0),pData.nApp);

% loops through each of the apparatus determining the number of NaN values
% and the inter-frame displacement
for j = 1:pData.nApp
    % calculates the time point displacements between time points
    if iMov.ok(j)
        D = cellfun(@(x)(sFac*[0;sqrt(sum(diff(x(ii,:),1).^2,2))]),...
                                            pData.fPos{j},'un',0);                                    
        N = cellfun(@(x)(getGroupIndex(isnan(x(ii,1)))),...
                                            pData.fPos{j},'un',0);        
                                        
        % NaN-frame count calculation and inter-frame displacement setting                                    
        for i = 1:size(nNaN,1)
            if iMov.flyok(i,j)
                % sets the NaN values (if any exist)
                if ~isempty(N{i})
                    nNaN{i,j} = N{i}; 
                end
                
                % sets the distance values
                Dfrm{i,j} = D{i};
            end
        end
    end
end

% --- calculates the population velocity (for a given apparatus)
function Vplt = calcPopVel(T,fPos,vP)

% parameters   
nFrm = length(T);
Vplt = NaN(nFrm,1); 

% calculates the time point displacements between time points
D = cellfun(@(x)([0;sqrt(sum(diff(x,[],1).^2,2))]),fPos,'un',0);
Dmean = mean(cell2mat(D(:)'),2,'omitnan');

% determines the valid time frames. if there are none then exit
ii = ~isnan(Dmean);
if ~any(ii); return; end

% sets up the pre/post time markers
switch vP.Type
    case 'Central'
        % case is the central derivative
        [t1,t2] = deal(vP.nPts);
        
    case 'Forward'
        % case is the forward derivative
        [t1,t2] = deal(0,vP.nPts);
        
    case 'Backward'
        % case is the backward derivative
        [t1,t2] = deal(vP.nPts,0);
        
end

% calculates the distance travelled and the time steps
iVel = (1+t1):(find(ii,1,'last')-t2);
dD = cellfun(@(x)(sum(Dmean((x-t1):(x+t2)))),num2cell(iVel));
dT = cellfun(@(x)(diff(T([(x-t1) (x+t2)]))),num2cell(iVel));
    
% sets the new velocity values
Vplt(iVel) = dD./dT;

% --- sets up the time vector --- %
function T = setupTimeVector(handles)

% retrieves the sub-region and fly position data structs
hGUI = get(handles.output,'hGUI');
[iData,iMov] = deal(hGUI.output.iData,hGUI.output.iMov);

% sets the time vector
T = iData.Tv(1:iMov.sRate:length(iData.Tv));
T = T(:) - T(1);

% resets the time vector to match position data (if given)
if hasPosData(hGUI.output.pData)
    nFrmT = size(hGUI.output.pData.fPos{1}{1},1);
    if nFrmT < length(T)
        T = T(1:nFrmT);
    else
        dT = mean(diff(T));
        T = [T;(T(end)+cumsum(dT*ones(nFrmT-length(T),1)))];
    end
end

% --- initialises the solution viewing gui parameter struct
function iPara = initParaStruct()

% memory allocation
iPara = struct('vP',[]);

% sets the velocity calculation parameters
iPara.vP = struct('Type','Central','nPts',5);

% --- initialises the phase patch markers
function initPhaseMarkers(handles,yLimT)

% object handles
hAxI = handles.axesImg;
T = get(handles.output,'T');
hGUI = get(handles.output,'hGUI');
iMov = get(hGUI.output,'iMov');

% deletes any previous patch objects
hPatchPr = findall(hAxI,'tag','hPhase');
if isempty(hPatchPr); delete(hPatchPr); end

% if there are no phases detected, then exit
nPhase = length(iMov.vPhase);
if nPhase == 0; return; end

% retrieves the axis limits (if not provided)
if ~exist('yLimT','var'); yLimT = get(hAxI,'yLim'); end

% other initialisations
Tmlt = 1/60;
fAlpha = 0.1;
dT = median(diff(T),'omitnan');
phCol = distinguishable_colors(nPhase);
[ix,iy] = deal([1,1,2,2,1],[1,2,2,1,1]);

% creates the phase patch objects
for i = 1:nPhase
    iPh = iMov.iPhase(i,:);
    if (diff(iPh) < 0)
        iPh = [iPh(1),length(T)];
    end
    
    xP = (T(iPh)+(dT/4)*[-1,1])*Tmlt;
    patch(hAxI,xP(ix),yLimT(iy),phCol(i,:),'FaceAlpha',fAlpha,...
               'tag','hPhase','UserData',i,'LineStyle','none');
end

% --- retrieves the currently selected menu item
function iApp = getSelectedMenuItem(handles)

% retrieves the selected menu item object handle
hMenuMet = [get(handles.menuFlyPos,'children');handles.menuAvgSpeed;...
            handles.menuAvgInt;handles.menuImgTrans];
hMenu = findobj(hMenuMet,'checked','on');

% ses the menu selection properties
if isempty(hMenu)
    % case is nothing is selected, so use avg. speed
    hMenu = findobj(handles.menuPlotMetrics,'type','uimenu','UserData',0);
    set(hMenu,'Checked','on')
    iApp = 0;
    
else
    % retrieves the sub-region indices
    uData = get(hMenu,'UserData'); 
    iApp = uData(1);
end

% --- toggles the line marker visibility properties
function toggleLineMarker(iMov,hAx,iStr)

% line tag strings
tStr = {'hLinePop','hLineAvg','hLineTrans','hLineInd'};

% resets the line marker visibility flags
for i = 1:length(tStr)
    hLine = findobj(hAx,'tag',tStr{i});
    setObjVisibility(hLine,iStr==i);
end

% makes the 2nd line invisible (2D or multi-tracking only)
if iMov.is2D
    hLine = findobj(hAx,'tag','hLineInd2');
    setObjVisibility(hLine,strcmp(tStr{iStr},'hLineInd')); 
end

% updates the legend visibility
hLg = findobj(get(hAx,'Parent'),'tag','hLegend');
setObjVisibility(hLg,strcmp(tStr{iStr},'hLineTrans'))
set(hLg,'String',{'X-Offset','Y-Offset'})

% --- retrieves the current numerical derivative coefficients
function [pC,iType] = getNumericalDerivCoeff(handles)

% field retrieval
vP = handles.output.iPara.vP;

% sets up the coefficients based on type
switch vP.Type
    case 'Central'
        % case is the central derivative
        iType = 1;
        pC = calcNumericalDerivCoeff(vP.Type,vP.nPtsH);
        
    otherwise
        % case is the forward/backward derivative
        iType = 2 + strcmp(vP.Type,'Backward');
        pC = calcNumericalDerivCoeff(vP.Type,vP.nPts);
        
end

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% callback on mouse motion over figure - except title and menu.
function resetMarkerLine(~, ~, handles)

% retrieves the current mouse point
hFig = handles.output;
T = get(hFig,'T');
iMov = get(hFig,'iMov');

% sets the current x/y location of the mouse
hAx = handles.axesImg;
cPos = get(hAx,'CurrentPoint'); mP = cPos(1,1:2);
[xLim,yLim] = deal(get(hAx,'xlim'),get(hAx,'ylim'));
[hMark,hText] = deal(findobj(hAx,'tag','hMark'),findobj(hAx,'tag','hText'));

% updates the marker line visibility
if isInAxes(handles,mP)
    % cursor is inside axes, so turn on marker line
    set(hMark,'xData',mP(1)*[1 1],'yData',get(hAx,'ylim'),'visible','on')
    
    % sets the normalised coordinates
    mPN = [(mP(1)-xLim(1))/diff(xLim),(mP(2)-yLim(1))/diff(yLim)];
    yDel =  0.14 + 0.86*(mPN(2) > 0.5); 
    xDel = -0.005 + 0.15*(mPN(1) < 0.5); 
    
    % updates the text-box position
    posNw = [(mPN(1)+xDel) (1-yDel) 0];
    set(hText,'position',posNw,'visible','on','string',...
          setDataTipTxt(iMov,T,mP(1)),'HorizontalAlignment','right')
else
    % cursor is outside axes, so turn off marker line
    setObjVisibility(hMark,'off')
    setObjVisibility(hText,'off')
end

% --- determines if the mouse-point is within the axes limits
function isIn = isInAxes(handles,mP)

% retrieves the position data struct
hFig = handles.output;
T = get(hFig,'T');
pData = hFig.hGUI.output.pData;

% determines the maximum extent
iApp = getSelectedMenuItem(handles);
if (iApp == 0)
    isIn = all([mP,T(end)/60,(length(pData.fPos)+0.5)] - [0 0.5 mP] > 0);
else
    isIn = all([mP,T(end)/60,(length(pData.fPos{iApp})+0.5)] - [0 0.5 mP] > 0);
end

% --- sets the string for the data-cursor box
function nwStr = setDataTipTxt(iMov,T,xMark)

% global variables
global nFrmRS

% determines the global frame index
[~,iFrmG] = min(abs(T/60-xMark(1)));

% determines the phase index
iPhase = find(iFrmG >= iMov.iPhase(:,1),1,'last');
iFrm = iFrmG - (iMov.iPhase(iPhase,1)-1);

% determines the selected frame and set the datatip string
nwStr = {sprintf('Phase Index = %i',iPhase);...
         sprintf('Image Stack = %i',floor((iFrm-1)/nFrmRS)+1);...
         sprintf('Global Frame Index = %i',iFrmG);...
         sprintf('Phase Frame Index = %i',iFrm);...
         sprintf('Time (Min) = %.2f',xMark(1))};
