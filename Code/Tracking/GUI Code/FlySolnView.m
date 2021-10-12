function varargout = FlySolnView(varargin)
% Last Modified by GUIDE v2.5 21-Jan-2021 19:18:12

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
function FlySolnView_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global is2D isDetecting nFrmRS updateFlag2 regSz
updateFlag2 = 2; pause(0.1); 

% retrieves the regular size of the GUI
regSz = get(handles.panelImg,'position');

% Choose default command line output for FlySolnView
handles.output = hObject;

% sets the input arguments
hGUI = varargin{1};

% determines if the video is 2D or not
iMov = getappdata(hGUI.figFlyTrack,'iMov');
is2D = is2DCheck(iMov) || detMltTrkStatus(iMov);
iData = getappdata(hGUI.figFlyTrack,'iData');

% sets the objects into the GUI
setappdata(hObject,'hGUI',hGUI)
setappdata(hObject,'iMov',iMov)
setappdata(hObject,'iData',iData)
setappdata(hObject,'nNan',[])
setappdata(hObject,'Dfrm',[])
setappdata(hObject,'sFac',iData.exP.sFac)
setappdata(hObject,'pData',getappdata(hGUI.figFlyTrack,'pData'));

% sets the number of frame read per image stack
nFrmRS = detStackFrmCount(getappdata(hGUI.figFlyTrack,'pData'));

% if detecting, then don't allow the data tool
if isDetecting
    setObjEnable(handles.uiDataTool,'off') 
end
    
% sets the view type
if is2D   
    set(handles.menuViewXY,'checked','on');
    setappdata(hObject,'vType',[1 1])
else
    setObjEnable(handles.menuPlotData,'off')
    setappdata(hObject,'vType',[1 0])
end

% sets the functions that are to be used outside the GUI
setappdata(hObject,'updateFunc',@updatePlotObjects)
setappdata(hObject,'initFunc',@initPlotObjects)

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
function varargout = FlySolnView_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                       TOOLBAR CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% -------------------------------------------------------------------------
function uiZoomAxes_ClickedCallback(hObject, eventdata, handles)

% global variables
global isDetecting

% toggles the zoom
switch get(hObject,'state')
    case ('on') % case is the zoom is turned on        
        % turns the zoom on
        zoom xon            
        zoom reset
        
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
switch (get(hObject,'state'))
    case ('on') % case is the data tool is turned on        
        % sets the mouse-motion function
        wmFunc = @(hObject,e)FlySolnView('resetMarkerLine',hObject,[],handles); 
        set(handles.figFlySolnView,'WindowButtonMotionFcn',wmFunc)                                        
        
        % sets the button-down function
        bdFunc = {@updateMainFrame,handles}; 
        set(handles.figFlySolnView,'WindowButtonDownFcn',bdFunc)                                                
        
    case ('off') % case is the data tool is turned off
        % disables the relevant objects
        set(handles.figFlySolnView,'WindowButtonMotionFcn',[])                                
        setObjVisibility(findobj(handles.figFlySolnView,'tag','hMark'),0)
        setObjVisibility(findobj(handles.figFlySolnView,'tag','hText'),0)
        
        % sets the window button function (not for zooming function
        if ~isa(eventdata,'char')
            set(handles.figFlySolnView,'WindowButtonDownFcn',[])
        end
end

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% ----------------------- %
% --- FILE MENU ITEMS --- %
% ----------------------- %

% -------------------------------------------------------------------------
function menuDiagCheck_Callback(hObject, eventdata, handles)

% calculates the NaN count/inter-frame displacement 
[nNaN,Dfrm] = calcDiagnosticValue(handles);    
setappdata(handles.figFlySolnView,'nNaN',nNaN)
setappdata(handles.figFlySolnView,'Dfrm',Dfrm)

% runs the solution diagnostic check
SolnDiagCheck(handles)

% -------------------------------------------------------------------------
function menuClose_Callback(hObject, eventdata, handles)

% retrieves the tracking GUI handles and the related GUI object handles
hGUIH = getappdata(handles.figFlySolnView,'hGUI');
hGUI = hGUIH.figFlyTrack;

% closes the GUI through the calling GUI
menuViewProgress_Callback = getappdata(hGUI,'menuViewProgress_Callback');
menuViewProgress_Callback(hGUIH.menuViewProgress,[],hGUIH)

% sets the tracking GUI on top
uistack(hGUI,'top')

% -------------------------------- %
% --- POSITION DATA MENU ITEMS --- %
% -------------------------------- %

% -------------------------------------------------------------------------
function menuTime_Callback(hObject, eventdata, handles)

% resets the check labels
if (strcmp(get(hObject,'checked'),'on'))
    % item already checked, so exit function
    return
else
    % toggles the checks between menu items
    set(handles.menuTime,'checked','on')
    set(handles.menuFrmIndex,'checked','off')
end

% retrieves the axes handle and time vector
hAx = findall(handles.figFlySolnView,'type','axes');
set(findall(hAx,'tag','hXLbl'),'string','Time (min)')

% updates the ticklabel
set(hAx,'xtick',getappdata(handles.figFlySolnView,'tTick0'))
set(hAx,'xTickLabel',getappdata(handles.figFlySolnView,'tTickLbl0'))

% -------------------------------------------------------------------------
function menuFrmIndex_Callback(hObject, eventdata, handles)

% resets the check labels
if (strcmp(get(hObject,'checked'),'on'))
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
T = getappdata(handles.figFlySolnView,'T');
tTick0 = getappdata(handles.figFlySolnView,'tTick0');

% reset the tick label values
dTLbl = [50 100 200 500 1000 1500 2000 2500 5000];
idTLbl = find(length(T)./dTLbl >= length(tTick0),1,'last');
tTickNw = (0:dTLbl(idTLbl):length(T));

% updates the axis label
tLblNw = cellfun(@(x)(num2str(x)),num2cell(tTickNw),'un',0);
set(hAx,'xtick',T(tTickNw+1)/60,'xticklabel',tLblNw);

% -------------------------------------------------------------------------
function menuViewXY_Callback(hObject, eventdata, handles)

% updates the view menu properties and the viewing axes
updateViewMenu(handles,hObject,[1 1])

% -------------------------------------------------------------------------
function menuViewX_Callback(hObject, eventdata, handles)

% updates the view menu properties and the viewing axes
updateViewMenu(handles,hObject,[1 0])

% -------------------------------------------------------------------------
function menuViewY_Callback(hObject, eventdata, handles)

% updates the view menu properties and the viewing axes
updateViewMenu(handles,hObject,[0 1])

% -------------------------- %
% --- STIMULI MENU ITEMS --- %
% -------------------------- %

% -------------------------------------------------------------------------
function menuShowStim_Callback(hObject, eventdata, handles)

% initialistions
dY = 10;
eStr = {'off','on'};
isChecked = strcmp(get(hObject,'Checked'),'on');

% object handles
hPanelI = handles.panelImg;
hPanelS = handles.panelStim;
hFig = handles.figFlySolnView;

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


%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ----------------------------- %
% --- MAIN FIGURE CALLBACKS --- %
% ----------------------------- %

% --- Executes when figFlySolnView is resized.
function figFlySolnView_ResizeFcn(hObject, eventdata, handles)

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
hGUI = getappdata(handles.figFlySolnView,'hGUI');
iMov = getappdata(hGUI.figFlyTrack,'iMov');
hMenu = handles.menuPlotMetrics;
pData = getappdata(handles.figFlySolnView,'pData');

% sets the menu enable string
if isempty(pData)
    mStr = 'off';     
else
    mStr = 'on'; 
end

% sets the diagnostic check menu item
setObjEnable(handles.menuDiagCheck,mStr)

% creates the new apparatus markers
for i = 1:length(iMov.iR)
    % creates the new menu item
    hMenuNw = uimenu(hMenu,'Label',sprintf('Region %i Location',i)); 
    
    % sets the menu item callback function
    bFunc = @(hMenuNw,e)FlySolnView('menuSelectUpdate',hMenuNw,[],handles);                       
    set(setObjEnable(hMenuNw,mStr),'Callback',bFunc,'UserData',i)    
end

% creates the new menu item
hMenuNw = uimenu(hMenu,'Label','Average Velocity'); 
bFunc = @(hMenuNw,e)FlySolnView('menuSelectUpdate',hMenuNw,[],handles);                       
set(hMenuNw,'Callback',bFunc,'UserData',0,'Separator','on','checked','on')    

% --- initialises the solution file information --- %
function initPlotObjects(handles,varargin)

% global variables
global is2D

% ------------------------------------------- %
% --- INITIALISATIONS & MEMORY ALLOCATION --- %
% ------------------------------------------- %

% object handle retrieval
hFig = handles.figFlySolnView;
hAxI = handles.axesImg;

% clears the image axis
cla(hAxI)
axis(hAxI,'on')

% retrieves the fly positonal data struct
hGUI = getappdata(hFig,'hGUI');
iMov = getappdata(hGUI.figFlyTrack,'iMov');
iData = getappdata(hGUI.figFlyTrack,'iData');

% sets the fly count (based on tracking type)
isMTrk = detMltTrkStatus(iMov);
if isMTrk
    nFly = max(iMov.nFlyR(:));
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
setappdata(hFig,'T',T)

% retrieves the font-sizes
[axSz,lblSz,tSz] = detSolnViewFontSizes(handles);

% determines if the gui is being initialised
hYLbl = findall(hAxI,'tag','hYLbl');
isInit = isempty(hYLbl);

% ---------------------------------------- %
% --- AXIS LABEL & MENU INITIALISATION --- %
% ---------------------------------------- %

% ses the menu selection properties
hMenu = findobj(handles.menuPlotMetrics,'type','uimenu','checked','on');
if isempty(hMenu)
    hMenu = findobj(handles.menuPlotMetrics,'type','uimenu','UserData',0);
    set(hMenu,'Checked','on')
    iApp = 0;
    
else
    % retrieves the sub-region indices
    iApp = get(hMenu,'UserData'); 
end

% sets the ylabels
switch iApp
    case 0 % case is the average velocity             
        yLimT = [1 nApp] + 0.5*[-1 1];
        yLblStr = 'Region Index';      
        
    otherwise % case is the positional traces
        yLimT = [1 nFly] + 0.5*[-1 1];
        yLblStr = 'Sub-Region Index';
end

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

% ---------------------------------- %
% --- PLOT MARKER INITIALISATION --- %
% ---------------------------------- %

% adds a hold to the axis
hold(hAxI,'on')

% sets the trace colours
col = 'rb';
    
% adds the population markers
for i = 1:nApp
    % sets the population line markers
    pCol = col(mod(i-1,2)+1);
    plot(hAxI,NaN,NaN,'color',pCol,'tag','hLinePop','UserData',i,...
                            'Linewidth',1,'hittest','off');    
end
   
% adds the individual markers
pDel = diff(T([1 end])*Tmlt)*0.001;
for i = 1:NN
    % creates the x-position marker
    plot(hAxI,NaN,NaN,'b','tag','hLineInd','UserData',i,'Linewidth',1);
    if is2D 
        % creates the y-position marker (2D only)
        plot(hAxI,NaN,NaN,'r','tag','hLineInd2',...
                              'UserData',i,'Linewidth',1,'hittest','off');
    end
    
    % adds in the seperator lines
    if i ~= NN
        plot(hAxI,T([1 end])*Tmlt-[pDel,0]',(i+0.5)*[1 1],...
                  'k','linewidth',1,'hittest','off')
    end    
end

% updates the axis properties
set(hAxI,'xlim',T([1 end])*Tmlt-[pDel,0]','ylim',yLimT'-[0.001;0],...
         'yticklabel',yStr,'ytick',yTick);
if isInit
    % sets any initialisation only properties
    set(hAxI,'fontweight','bold','fontsize',axSz,'UserData',1,...
             'Color',axCol,'box','on','LineWidth',1.5,...
             'TickLength',[0,0],'xgrid','on');
end

% sets the original tick mark/labels
setappdata(handles.figFlySolnView,'tTick0',get(hAxI,'xTick'))
setappdata(handles.figFlySolnView,'tTickLbl0',get(hAxI,'xTickLabel'))    
    
% -------------------------------------- %
% --- STIMULI MARKER INITIALISATIONS --- %
% -------------------------------------- %

% resets the object property units
resetObjProps(hFig,'Units','Pixels')
resetObjProps(hAxI,'FontUnits','Pixels')

% parameters
isShow = addStimAxesPanels(handles,iData.stimP,iData.sTrainEx,T,isInit);
setObjEnable(set(handles.menuShowStim,'Checked',eStr{1+isShow}),isShow)

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

% removes hold from the axis
hold(hAxI,'off')
axis(hAxI,'ij')

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
hMenuPr = findobj(get(handles.menuPlotData,'children'),'checked','on');
set(hMenuPr,'checked','off')
set(hMenu,'checked','on')

% sets the view type to the specified
setappdata(handles.figFlySolnView,'vType',vType)

% updates the plot object
updatePlotObjects(handles)

% --- initialises the solution file information --- %
function updatePlotObjects(handles,pData)

% global variables
global is2D

% retrieves the fly position data (if not provided)
if nargin == 1
    pData = getappdata(handles.figFlySolnView,'pData');
end

% retrieves the font-sizes
[~,lblSz,~] = detSolnViewFontSizes(handles);

% retrieves the objects from the GUI
iMov = getappdata(handles.figFlySolnView,'iMov');
vType = getappdata(handles.figFlySolnView,'vType');

% if there is no data, then exit the function
hMenu = findobj(handles.menuPlotMetrics,'type','uimenu');
ii = cellfun(@(x)(~isempty(x) && (x > 0)),get(hMenu,'UserData'));
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

% retrieves the menu 
hMenu = findobj(handles.menuPlotMetrics,'type','uimenu','checked','on');
[hAx,iApp] = deal(handles.axesImg,get(hMenu,'UserData'));
setObjEnable(handles.menuYData,iApp~=0)

% retrieves the fly positonal data struct
[T,Tmlt] = deal(getappdata(handles.figFlySolnView,'T'),1/60);
[pDel,nApp] = deal(diff(get(hAx,'xlim'))*0.001,pData.nApp);

% retrieves the menu item handles
switch iApp
    case (0) % case is the average velocity
        % makes all the population plot lines visible and the individual
        % plot line invisible
        hLine = findobj(hAx,'tag','hLinePop');
        setObjVisibility(findobj(hAx,'tag','hLineInd'),'off')
        set(get(hAx,'Title'),'string','Average Velocity')
        setObjVisibility(hLine,'on')        
          
        % makes the 2nd line invisible (2D or multi-tracking only)
        if is2D
            setObjVisibility(findobj(hAx,'tag','hLineInd2'),'off'); 
        end        
        
        % sets the y-axis limits and strings
        yTick = 1:nApp;
        yStr = cellfun(@(x)(sprintf('%i',x)),num2cell(yTick)','un',0);
        
        % sets/updates the y-axis label
        hYLbl = findall(hAx,'tag','hYLbl');
        if isempty(hYLbl)
            ylabel(hAx,'Region Index','fontweight','bold',...
                       'fontsize',lblSz,'tag','hYLbl')
        else
            set(hYLbl,'string','Region Index')
        end
        
        % retrieves the data values based on the region struct format
        if isfield(iMov,'pInfo')
            % case is the new format solution file
            nApp = iMov.pInfo.nGrp;
            fPos = groupPosValues(iMov,pData.fPos);
        else
            % case is the old format solution file
            fPos = pData.fPos;
        end
        
        % calculates the fly velocities (over all apparatus)
        Vplt = cellfun(@(x)(calcPopVel(T,x)),fPos,'un',0);     
        Vmax = ceil(max(cellfun(@max,Vplt)));
        VpltN = cellfun(@(x)(x/Vmax),Vplt,'un',0);                
        
        % updates the plot lines for all the apparatus
        for i = 1:nApp
            % sets the plot indices and updates the plot data
            ii = 1:min(length(T),length(VpltN{i}));
            hLine = findobj(hAx,'tag','hLinePop','UserData',i);
            set(hLine,'xdata',T(ii)*Tmlt,'yData',...
                            yDel+(1-2*yDel)*(1-VpltN{i}(ii))+(i-0.5))
        end
        
        % updates the axis limits
        set(hAx,'yLim',[1 nApp]+0.5*[-1.002 1])    
        
    otherwise % case is the fly position plot
        % makes all the population plot lines invisible and the individual
        % plot line visible        
        isMTrk = detMltTrkStatus(iMov);   
        if isMTrk
            nFly = getRegionFlyCount(iMov,iApp); 
            yLblStr = 'Fly Index';
        else
            nFly = pData.nTube(iApp);
            yLblStr = 'Sub-Region Index';
        end
        
        % sets the object visibility
        hLine = findobj(hAx,'tag','hLineInd'); 
        setObjVisibility(findobj(hAx,'tag','hLinePop'),'off')                                        
        set(get(hAx,'Title'),'string',sprintf('Region %i Location',iApp))
        setObjVisibility(hLine,vType(1))
        
        % sets the visibility of the 2nd line (if 2D or multi-tracking)
        if is2D
            setObjVisibility(findobj(hAx,'tag','hLineInd2'),vType(2)); 
        end                
        
        % sets the y-axis limits and strings
        yTick = 1:nFly;
        yStr = cellfun(@(x)(sprintf('%i',x)),num2cell(yTick)','un',0);                      
        fPosNw = pData.fPos{iApp};
        
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
            xMin = iMov.iC{iApp}(1) - 1;
            xMax = iMov.iC{iApp}(end) - 1; 
            
            if isMTrk
                % determines the min/max position values over all flies
                % within the current region
                xPosL = cell2mat(cellfun(@(x)...
                        ([min(x(:,1)),max(x(:,1))]),fPosNw(:),'un',0)); 
                xMin = min(xMin,min(xPosL(:,1)));
                xMax = max(xMax,max(xPosL(:,2)));
            end
            
            XpltN = cellfun(@(x)((x(:,1)-xMin)./(xMax-xMin)),...
                                        fPosNw,'un',0);
        end
        
        % calculates the y-coordinates
        if is2D && vType(2)
            if isMTrk
                % determines the min/max position values over all flies
                % within the current region
                yPosL = cell2mat(cellfun(@(x)...
                        ([min(x(:,2)),max(x(:,2))]),fPosNw(:),'un',0)); 
                yMin = min(iMov.iR{iApp}(1)-1,min(yPosL(:,1)));
                yMax = max(iMov.iR{iApp}(end)-1,max(yPosL(:,2)));                
                
                YpltN = cellfun(@(x,y,z)((x(:,2)-yMin)./(yMax-yMin)),...
                                        fPosNw,'un',0); 
            else
                yMin = num2cell(iMov.yTube{iApp}(:,1))';
                yMax = num2cell(iMov.yTube{iApp}(:,2))';
                
                YpltN = cellfun(@(x,y,z)((x(:,2)-y)./(z-y)),...
                                        fPosNw,yMin,yMax,'un',0);                 
            end                           
        end
        
        % updates the plot lines for all tubes
        for i = 1:nFly
            % sets the plot indices and updates the plot data                                   
            if vType(1)
                ii = 1:min(length(T),length(XpltN{i})); 
                hLineX = findobj(hAx,'tag','hLineInd','UserData',i);            
                set(hLineX,'xdata',T(ii)*Tmlt,'yData',...
                                yDel+(1-2*yDel)*(1-XpltN{i}(ii))+(i-0.5))
            end
                            
            if is2D && vType(2)
                ii = 1:min(length(T),length(YpltN{i})); 
                hLineY = findobj(hAx,'tag','hLineInd2','UserData',i);
                set(hLineY,'xdata',T(ii)*Tmlt,'yData',...
                                yDel+(1-2*yDel)*(1-YpltN{i}(ii))+(i-0.5))                            
            end
        end        
        
        % updates the axis limits
        set(hAx,'yLim',[1 nFly]+0.5*[-1.002 1])
end

% updates the axis properties
xLim = [-pDel max(get(hAx,'xlim'))];
set(hAx,'yticklabel',yStr,'ytick',yTick,'xlim',xLim);

% updates the positional data struct (if provided)
if nargin == 2
    setappdata(handles.figFlySolnView,'pData',pData);
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
        fPos{i} = arrayfun(@(ir,ic)(fPos0{ic}{ir}),iRowG,iColG,'un',0)';        
    else
        indG = sub2ind(size(iMov.pInfo.nFly),iRowG,iColG);
        iRegG = (iRowG-1)*iMov.pInfo.nCol + iColG;
        nFly = iMov.pInfo.nFly(indG);
        
        fPos{i} = cell2cell(arrayfun(@(i,n)...
                                    (fPos0{i}(1:n)),iRegG,nFly,'un',0),0);
    end
end

% --- update function for the position data menu item selection
function menuSelectUpdate(hObject, eventdata, handles)

% initialisations
isUpdate = true;
hMenu = findobj(handles.menuPlotMetrics,'type','uimenu','checked','on');

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

% --------------------------------------- %
% --- CONTEXT MENU CALLBACK FUNCTIONS --- %
% --------------------------------------- %

% --- context menu callback function for the plotting axis
function updateMainFrame(source,eventdata,handles)

% sets the current x/y location of the mouse
hAx = handles.axesImg;
cPos = get(hAx,'CurrentPoint'); mP = cPos(1,1:2);

% only update if the mouse-click was within the image axes
if (isInAxes(handles,mP))
    % determines the frame that is currently selected
    T = getappdata(handles.figFlySolnView,'T');
    [~,iFrm] = min(abs(T/60-mP(1)));    

    % updates the main image frame
    hGUI = getappdata(handles.figFlySolnView,'hGUI');    
    set(hGUI.frmCountEdit,'string',num2str(iFrm))
    feval(getappdata(hGUI.figFlyTrack,'dispImage'),hGUI)
end

% ----------------------------------------------- %
% --- POSITION/VELOCITY CALCULATION FUNCTIONS --- %
% ----------------------------------------------- %

% --- calculates the diagnostic metric values
function [nNaN,Dfrm] = calcDiagnosticValue(handles)

% global variables
global nFrmRS

% retrieves the position data struct
iMov = getappdata(handles.figFlySolnView,'iMov');
iData = getappdata(handles.figFlySolnView,'iData');
pData = getappdata(handles.figFlySolnView,'pData');
sFac = getappdata(handles.figFlySolnView,'sFac');

% determines the first non-rejected sub-region
[j0,i0] = find(iMov.flyok,1,'first');
nFrm = size(pData.fPos{i0}{j0},1);

% ignore the last frame for .avi videos
[~,~,fExtn] = fileparts(iData.movStr);
if (strcmp(fExtn,'.avi')); nFrm = nFrm - 1; end

% ensures the frame counter index array is a cell array
frmOK = pData.frmOK;
if (~iscell(frmOK)); frmOK = {frmOK}; end

% sets the indices of the frames that have already been read
if (isnan(nFrmRS))
    ii = [];
elseif (all(cellfun(@all,frmOK)))
    ii = 1:nFrm;
else
    jj = find(cellfun(@any,frmOK),1,'last');
    iGrp = getGroupIndex(frmOK{jj});
    ii = 1:(iGrp{1}(end)*nFrmRS);
end

% memory allocation
nNaN = cell(pData.nTube(i0),pData.nApp);
Dfrm = repmat({NaN(nFrm,1)},pData.nTube(i0),pData.nApp);

% loops through each of the apparatus determining the number of NaN values
% and the inter-frame displacement
for j = 1:pData.nApp        
    % calculates the time point displacements between time points
    if (iMov.ok(j))
        D = cellfun(@(x)(sFac*[0;sqrt(sum(diff(x(ii,:),1).^2,2))]),...
                                            pData.fPos{j},'un',0);                                    
        N = cellfun(@(x)(getGroupIndex(isnan(x(ii,1)))),...
                                            pData.fPos{j},'un',0);                                                                    

        % NaN-frame count calculation and inter-frame displacement setting                                    
        for i = 1:size(nNaN,1)        
            if (iMov.flyok(i,j))
                if (~isempty(N{i})); nNaN{i,j} = N{i}; end
                Dfrm{i,j} = D{i};
            end
        end
    end
end

% --- calculates the population velocity (for a given apparatus)
function Vplt = calcPopVel(T,fPos)

% parameters
tBin = 5;    
Vplt = NaN(length(T),1); 

% calculates the time point displacements between time points
D = cellfun(@(x)([0;sqrt(sum(diff(x,1).^2,2))]),fPos,'un',0);
Dmean = nanmean(cell2mat(D),2);

% sets the feasible points
ii = ~isnan(Dmean);
if (any(ii))
    % calculates the distance travelled and the time steps
    iVel = (1+tBin):(find(ii,1,'last')-tBin);
    dD = cellfun(@(x)(sum(Dmean((x-tBin):(x+tBin)))),num2cell(iVel));
    dT = cellfun(@(x)(diff(T([(x-tBin) (x+tBin)]))),num2cell(iVel));
    
    % sets the new velocity values
    Vplt(iVel) = dD./dT;
end

% --- sets up the time vector --- %
function T = setupTimeVector(handles)

% retrieves the sub-region and fly position data structs
hGUI = getappdata(handles.figFlySolnView,'hGUI');
iMov = getappdata(hGUI.figFlyTrack,'iMov');
iData = getappdata(hGUI.figFlyTrack,'iData');
pData = getappdata(hGUI.figFlyTrack,'pData');

% sets the time vector
T = iData.Tv(1:iMov.sRate:length(iData.Tv));
T = T(:) - T(1);

% resets the time vector to match position data (if given)
if (hasPosData(pData))
    nFrmT = size(pData.fPos{1}{1},1);
    if (nFrmT < length(T))
        T = T(1:nFrmT);
    else
        dT = mean(diff(T));
        T = [T;(T(end)+cumsum(dT*ones(nFrmT-length(T),1)))];
    end
end

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% callback on mouse motion over figure - except title and menu.
function resetMarkerLine(hObject, eventdata, handles)

% retrieves the current mouse point
T = getappdata(handles.figFlySolnView,'T');
pData = getappdata(handles.figFlySolnView,'pData');
iMov = getappdata(handles.figFlySolnView,'iMov');

% sets the current x/y location of the mouse
hAx = handles.axesImg;
cPos = get(hAx,'CurrentPoint'); mP = cPos(1,1:2);
[xLim,yLim] = deal(get(hAx,'xlim'),get(hAx,'ylim'));
[hMark,hText] = deal(findobj(hAx,'tag','hMark'),findobj(hAx,'tag','hText'));

% updates the marker line visibility
if (isInAxes(handles,mP))
    % cursor is inside axes, so turn on marker line
    set(hMark,'xData',mP(1)*[1 1],'yData',get(hAx,'ylim'),'visible','on')
    
    % sets the normalised coordinates
    mPN = [(mP(1)-xLim(1))/diff(xLim),(mP(2)-yLim(1))/diff(yLim)];
    yDel =  0.07 + 0.86*(mPN(2) > 0.5); 
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
pData = getappdata(handles.figFlySolnView,'pData');
T = getappdata(handles.figFlySolnView,'T');

% determines the maximum extent
iApp = get(findobj(handles.menuPlotMetrics,'checked','on'),'UserData');
if (iApp == 0)
    isIn = all([mP,T(end)/60,(length(pData.fPos)+0.5)] - [0 0.5 mP] > 0);
else
    isIn = all([mP,T(end)/60,(length(pData.fPos{1})+0.5)] - [0 0.5 mP] > 0);
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
