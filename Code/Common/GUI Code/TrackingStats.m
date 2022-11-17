function varargout = TrackingStats(varargin)
% Last Modified by GUIDE v2.5 30-Aug-2016 20:56:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TrackingStats_OpeningFcn, ...
                   'gui_OutputFcn',  @TrackingStats_OutputFcn, ...
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


% --- Executes just before TrackingStats is made visible.
function TrackingStats_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for TrackingStats
handles.output = hObject;
set(hObject, 'Renderer','painters');
scrSz = getPanelPosPix(0,'Pixels','ScreenSize');

% sets the input arguments
hGUI = varargin{1};
if length(varargin) == 1
    isExpt = false;
else
    isExpt = varargin{2};    
end

% initialises the loadbar
if ~isExpt
    h = ProgressLoadbar('Initialising Tracking GUI...');
end

% retrieves the sub-region data struct
[iPara,iMov] = setPlotDataStruct(getappdata(hGUI,'iMov'));

% sets the input arguments
setappdata(hObject,'iMov',iMov);
setappdata(hObject,'iPara',iPara);
setappdata(hObject,'hGUI',hGUI);
setappdata(hObject,'isExpt',isExpt);
setappdata(hObject,'isTrack',strcmp(get(hGUI,'tag'),'figFlyTrack'))

% determines if the connected device is an DAQ device
dInfo = getappdata(hGUI,'objDACInfo');
if isempty(dInfo)
    setappdata(hObject,'isSer',false)
else
    setappdata(hObject,'isSer',any(strcmp(dInfo.dType,'Serial')))
end

% deletes any old objects
hObjOld = findobj(handles.panelTrackStats);
if ~isempty(hObjOld)
    delete(hObjOld(hObjOld ~= handles.panelTrackStats))
end

% initialises the GUI objects
handles = initGUIObjects(handles); pause(0.01);

% resets the GUI location
[figPosM,figPos] = deal(get(hGUI,'position'),get(hObject,'position'));

% resets the left/bottom location of the GUI
dX = 25;
Lnw = min((sum(figPosM([1 3]))+dX),scrSz(3)-figPos(3));
Bnw = max(50,figPos(2) + (figPos(4) - figPosM(4)));

% updates the GUI location
try; delete(h); end; pause(0.05); 
set(setObjVisibility(hObject,'on'),'position',[Lnw Bnw figPos(3:4)]); 

% sets the function handles into the GUI
setappdata(hObject,'uFunc',@updateStatusColour)
setappdata(hObject,'rFunc',@resetTrackingGUI)
setappdata(hObject,'menuAvgVel',@menuAvgVel_Callback)
setappdata(hObject,'menuMeanInact',@menuMeanInact_Callback)

% sets the menu item handles into the GUI
setappdata(hObject,'hMenuD',num2cell(findobj(handles.menuData,'type','uimenu')));
setappdata(hObject,'hMenuG',num2cell(findobj(handles.menuGraph,'type','uimenu')));

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes TrackingStats wait for user response (see UIRESUME)
% uiwait(handles.figTrackStats);

% --- Outputs from this function are returned to the command line.
function varargout = TrackingStats_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%
        
% ----------------------- %
% --- FILE MENU ITEMS --- %
% ----------------------- %

% -------------------------------------------------------------------------
function menuClose_Callback(hObject, eventdata, handles)

% retrieves the calling GUI handle and related object handles
hGUI = getappdata(handles.figTrackStats,'hGUI');
hGUIH = guidata(hGUI);

% switches off the GUI through the calling GUI functions
switch (get(hGUI,'tag'))
    case ('figFlyRecord') % case is the recording GUI
        toggleStartTracking = getappdata(hGUI,'toggleStartTracking');
        toggleStartTracking(hGUIH.toggleStartTracking,[],hGUIH)
    case ('figFlyTrack') % case is the tracking GUI
        menuRTTrack = getappdata(hGUI,'menuRTTrack');
        menuRTTrack(hGUIH.menuRTTrack,[],hGUIH)        
end

% ------------------------------- %
% --- TABLE METRIC MENU ITEMS --- %
% ------------------------------- %

% -------------------------------------------------------------------------
function menuTotalDisp_Callback(hObject, eventdata, handles)

% updates the menu check properties
updateMenuChecks(hObject)

% -------------------------------------------------------------------------
function menuInstantInact_Callback(hObject, eventdata, handles)

% updates the menu check properties
updateMenuChecks(hObject)

% -------------------------------------------------------------------------
function menuInactiveTime_Callback(hObject, eventdata, handles)

% updates the menu check properties
updateMenuChecks(hObject)

% -------------------------------------------------------------------------
function menuFlyPos1_Callback(hObject, eventdata, handles)

% updates the menu check properties
updateMenuChecks(hObject)

% -------------------------------------------------------------------------
function menuFlyPos2_Callback(hObject, eventdata, handles)

% updates the menu check properties
updateMenuChecks(hObject)

% -------------------------------------------------------------------------
function menuStimCount_Callback(hObject, eventdata, handles)

% updates the menu check properties
updateMenuChecks(hObject)

% ------------------------------- %
% --- GRAPH METRIC MENU ITEMS --- %
% ------------------------------- %

% -------------------------------------------------------------------------
function menuAvgVel_Callback(hObject, eventdata, handles)

% updates the real-time axis plot and menu items
iPara = getappdata(handles.figTrackStats,'iPara');
updateRTPlot(hObject,'Population Speed','Speed (mm/s)',iPara.vMax)

% -------------------------------------------------------------------------
function menuPropInact_Callback(hObject, eventdata, handles)

% updates the real-time axis plot and menu items
yStr = sprintf('%s Inactive',char(37));
updateRTPlot(hObject,'% Inactivity',yStr,100)

% -------------------------------------------------------------------------
function menuMeanInact_Callback(hObject, eventdata, handles)

% updates the real-time axis plot and menu items
yStr = 'Time Inactive (s)';
iPara = getappdata(handles.figTrackStats,'iPara');
updateRTPlot(hObject,'Inactive Duration',yStr,iPara.tDur)

% -------------------------------------- %
% --- DISPLAY INFORMATION MENU ITEMS --- %
% -------------------------------------- %

% -------------------------------------------------------------------------
function menuShowStats_Callback(hObject, eventdata, handles)

% updates the position of the figure objects
updateFigObjPos(hObject,handles)

% -------------------------------------------------------------------------
function menuShowPlot_Callback(hObject, eventdata, handles)

% updates the position of the figure objects
updateFigObjPos(hObject,handles)

% -------------------------------------------------------------------------
function menuDispCrit_Callback(hObject, eventdata, handles)

% parameters
vStr = {'off','on'};
isCheck = strcmp(get(hObject,'checked'),'on');

% toggles the menu check item
set(hObject,'checked',vStr{1+(~isCheck)})

% updates the properties based on the 
if (strcmp(get(hObject,'label'),'Display Criteria Markers'))
    % case is displaying the criteria markers
    hCrit = findall(handles.axesProgress,'tag','hCrit');
    setObjVisibility(hCrit,~isCheck)    
else
    % case is displaying the experiment location markers
    hGUIH = guidata(getappdata(handles.figTrackStats,'hGUI'));
    switch (get(hGUI,'tag'))
        case ('figFlyTrack') % case is the Tracking GUI
            hAx = hGUIH.imgAxes;
        case ('figFlyRecord') % case is the Recording GUI
            hAx = hGUIH.axesPreview;
    end
    
    % updates the marker visibility
    hExLoc = findall(hAx,'tag','hExLoc');
    setObjVisibility(hExLoc,~isCheck)        
end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% ------------------------------- %
% --- OBJECT UPDATE FUNCTIONS --- %
% ------------------------------- %

% --- updates the real-time axis plot and menu items
function updateRTPlot(hObject,tStr,yStr,yLim)

% retrieves the tracking stats GUI handles
handles = guidata(hObject);
hGUI = getappdata(handles.figTrackStats,'hGUI');

% determines the checked menu item
hMenuC = getCheckedMenuItem(handles.menuGraph);
hYlbl = findall(handles.figTrackStats,'Tag','yLabel');
hTitle = findall(handles.figTrackStats,'Tag','Title');

% if the checked menu-item does not match then menu item, then update flags
if (hMenuC ~= hObject)
    set(hMenuC,'checked','off')
    set(hObject,'checked','on')    
end

% updates the stimulus marker y-extent
hStim = findobj(handles.axesProgress,'tag','hStimMark');
if ~isempty(hStim)
    set(hStim,'yData',[0 yLim])
end

% if the connection type is channel to apparatus, then update the criteria
% marker on the real-time tracking plot
gType = get(hObject,'tag');
if getappdata(handles.figTrackStats,'isC2A')
    % initialisations   
    yData = getCritValue(getappdata(hGUI,'rtP'),gType);
    hCrit = findall(handles.axesProgress,'tag','hCrit');   
    isCheck = strcmp(get(handles.menuDispCrit,'checked'),'on');
    
    % sets the fill object y-values
    if isnan(yData)
        % no fill object to be shown
        yy = NaN(1,2);
    else
        % object to be shown
        yy = [0 yLim];
        yy(1+strcmp(gType,'menuAvgVel')) = yData;
    end
    
    % updates the criteria marker    
    set(setObjVisibility(hCrit,isCheck),'yData',yy([1 1 2 2]))
    setObjEnable(handles.menuDispCrit,~isnan(yData))
end

% updates the axis limits and vertical axis title
set(handles.axesProgress,'yLim',[0 yLim])
set(hYlbl,'string',yStr)
set(hTitle,'string',tStr)

% updates the tracking plot
updateRTTrackPlot(handles.figTrackStats,getappdata(hGUI,'rtD'),gType)
drawnow update;

% --- updates the menu item checks --- %
function updateMenuChecks(hObject)

% determines the checked menu item
handles = guidata(hObject);
hMenuC = getCheckedMenuItem(handles.menuData);

% if the checked menu-item does not match then menu item, then update flags
if hMenuC ~= hObject
    set(hMenuC,'checked','off')
    set(hObject,'checked','on')
end

% --- updates the position of the figure objects/dimensions
function updateFigObjPos(hMenu,handles)

% parameters
[X0,Y0] = deal(10);
[HfigT,WfigT] = deal(60,20);
scrSz = get(0,'screensize');

% toggles the check markers
if strcmp(get(hMenu,'checked'),'on')
    set(hMenu,'checked','off')
else
    set(hMenu,'checked','on')
end

% determines which display information menu items are checked
isChk = [strcmp(get(handles.menuShowStats,'checked'),'on');...
         strcmp(get(handles.menuShowPlot,'checked'),'on')];
      
% retrieves the positions of the objects     
dPos = get(handles.panelTrackStats,'position');
pPos = get(handles.panelAxisPlot,'position');
fPos = get(handles.figTrackStats,'position');

% determines the height width/of the new objects
Hfig = max(isChk(1)*dPos(4)+2*Y0,isChk(2)*pPos(4)+2*Y0);
Wfig = max(260,X0*(1+sum(isChk))+isChk(1)*dPos(3)+isChk(2)*pPos(3));
fPos(1) = fPos(1) + min(0,scrSz(3)-(fPos(1)+Wfig+WfigT));
fPos(2) = fPos(2) + min(0,scrSz(4)-(fPos(2)+Hfig+HfigT));

% sets the new position of the data table/plot axis
dPosNw = [X0,Y0+max(0,isChk(2)*pPos(4)-dPos(4)),dPos(3:4)];
pPosNw = [(X0+(X0+dPos(3))*isChk(1)),...
           Y0+max(0,isChk(1)*dPos(4)-pPos(4)),pPos(3:4)];

% updates the position of the 
set(setObjVisibility(handles.panelTrackStats,isChk(1)),'position',dPosNw)
set(setObjVisibility(handles.panelAxisPlot,isChk(2)),'position',pPosNw)
set(handles.figTrackStats,'position',[fPos(1:2),Wfig,Hfig])

% ------------------------------ %
% --- GUI PROPERTY FUNCTIONS --- %
% ------------------------------ %

% --- initialises the GUI objects --- %
function handles = initGUIObjects(handles)

% global variables
global TlimRT sFin sStart
[TlimRT,sFin,sStart] = deal(60,[],[]);

% retrieves the caller program GUI handles and sub-region data struct
[hFig,hPanel] = deal(handles.figTrackStats,handles.panelTrackStats);
hGUI = getappdata(hFig,'hGUI');
iMov = getappdata(hFig,'iMov');
rtP = getappdata(hGUI,'rtP');
isT = getappdata(handles.figTrackStats,'isTrack');

% sets the velocity tolerance
Vtol = 10*(1+iMov.is2D);

% retrieves the sub-region data struct
nFlyR = getSRCountVec(iMov);
[aok,Stim,eStr] = deal(find(iMov.ok),rtP.Stim,{'off','inactive'});
[nApp,nFly] = deal(length(aok),max(nFlyR));

iGrp = rtP.combG.iGrp;
if (isempty(iGrp)); iGrp = (1:nApp)'; end
nGrp = size(iGrp,1);

% text/edit box dimensions
[Ys,Y0,X0,Rdel] = deal(5,10,10,2);
[WappS,HappS] = deal(118,16);
[WflyS,HflyS] = deal(118,16);
[WdatS,HdatS] = deal(98,16);
[Wstat,Hstat] = deal(14,14);
[WsepV,HsepH] = deal(2);
dy0 = isT*(HappS+2*Ys);

% sets the total field strings
pTotStr = {'% Inactive','Mean Inactivity','Mean Velocity'};
sTotStr = {'Last Shock Event','Shock Count',...
           'Time Remaining','Current Status'};       
[nTotP,nTotS] = deal(length(pTotStr),length(sTotStr));

% set the show stimulus shock field flag to true only if the calling
% program GUI is FlyRecord, and the experiment type is Sleep Deprivation
if ~isempty(Stim)
    % determines if the experiment was a sleep-deprivation expt (which is
    % not a test and ALL the USB channels have been set)
    if strcmp(Stim.cType,'Ch2App')
        [isC2A,isC2T] = deal(any(~isnan(Stim.C2A)),false);
    else
        [isC2A,isC2T] = deal(false,any(all(~isnan(Stim.C2T),2)));
    end   
    
    % if running single stimuli, then set the stimuli finish flag array
    if strcmp(Stim.sType,'Single')
        sFin = zeros(size(Stim.C2A,1),2);
        sStart = zeros(size(Stim.C2A,1),1);
    end
else
    % set show flag to false
    [isC2A,isC2T] = deal(false);
end

% updates the show stimulus flag
setappdata(handles.figTrackStats,'isC2A',isC2A)
setappdata(handles.figTrackStats,'isC2T',isC2T)
setappdata(handles.figTrackStats,'showStim',isC2A)

% if runningg an experiment, prevent the user from closing the GUI
if getappdata(hFig,'isExpt')
    if isfield(handles,'menuFile')
        delete(handles.menuFile)
        handles = rmfield(handles,'menuFile');        
    end    
end

% determines if the display criteria menu item is to be kept
isExLoc = isC2T && rtP.indSC.isExLoc;
if ~(isC2A || isExLoc)
    % no condition are met, so remove the display criteria menu item
    if isfield(handles,'menuDispCrit')
        delete(handles.menuDispCrit)
        handles = rmfield(handles,'menuDispCrit');        
    end
    
elseif isC2A
    % sets the enabled properties (if using speed tolerance or not)
    setObjEnable(handles.menuDispCrit,rtP.popSC.isVtol)
    
elseif isExLoc
    % resets the display criteria menu item string (if using expt location)
    set(handles.menuDispCrit,'label','Display Location Markers')
    
    % creates the separation markers on the main GUI axis    
    [ii,jj,col] = deal([1 2 2 1],[1 1 2 2],'rg');  
    [iC2T,ExLoc] = deal(rtP.Stim.C2T,rtP.indSC.ExLoc);    
    [isMM,pX] = deal(strcmp(ExLoc.pType,'mm'),ExLoc.pX);        
    
    % case is displaying the experiment location markers
    hGUIH = guidata(hGUI);
    switch get(hGUI,'tag')
        case ('figFlyTrack') % case is the Tracking GUI
            hAx = hGUIH.imgAxes;
        case ('figFlyRecord') % case is the Recording GUI
            hAx = hGUIH.axesPreview;
    end    
    
    % creates the markers based on the arena dimensionality
    hold(hAx,'on')
    if iMov.is2D
        % case is 2D experimental regions
        phi = linspace(0,2*pi,65);
        [cP,sP,isLE] = deal(cos(phi),sin(phi),strcmp(ExLoc.pRef,'Edge'));
        [X1,X2,Y1,Y2] = deal(cell(nFly,length(iMov.iR)));
        
        % sets the radius increment value
        R = iMov.autoP.R;
        if isMM; dR = pX(1); else, dR = pX(2)*R; end
        
        % sets the fill objects coordinates        
        ii = ~all(isnan(iC2T),2);
        [X0,Y0] = getCircCentreCoords(iMov);
        for i = reshape(find(ii),1,sum(ii))
            % sets the apparatus/fly indices
            [iApp,iFly] = deal(iC2T(i,1),iC2T(i,2));
            
            % sets the limits of the fill object
            [pX0,pY0] = deal(X0(iFly,iApp),Y0(iFly,iApp));
            if (isLE)
                % the edge is the region for stimulation
                [X2{i},Y2{i}] = deal(pX0+(R+Rdel)*cP,pY0+(R+Rdel)*sP);
                [X1{i},Y1{i}] = deal(pX0+dR*cP,pY0+dR*sP);                
            else
                % the centre is the region for stimulation
                [X2{i},Y2{i}] = deal(pX0+dR*cP,pY0+dR*sP);
                [X1{i},Y1{i}] = deal(pX0+(R+Rdel)*cP,pY0+(R+Rdel)*sP);                
            end            
        end
    else
        % case is 1D experimental regions
        iCh = unique(iC2T(~isnan(iC2T(:,1)),1));
        [X1,X2,Y1,Y2] = deal(cell(1,length(iCh)));
        isLE = strcmp(ExLoc.pRef,'Left Edge');        
        
        % sets the fill objects coordinates
        for j = 1:length(iCh)
            % sets the extent of the region
            i = iCh(j);
            [xL,yL] = deal(iMov.iC{i}([1 end]),iMov.iR{i}([1 end]));
            if (isMM); dX = pX(1); else, dX = pX(2)*(diff(xL)+1); end
            
            % sets the limits of the fill object            
            if (isLE)
                % left side is the side for stimulation
                [xx1,xx2] = deal(xL(1)+[0,dX],[(xL(1)+dX),xL(2)]);                
            else
                % right side is the side for stimulation
                [xx1,xx2] = deal([xL(1),(xL(2)-dX)],xL(2)-[dX,0]);
            end     
            
            % sets the x/y coordinates of the fill object
            [X1{j},X2{j}] = deal(xx1(ii),xx2(ii));
            [Y1{j},Y2{j}] = deal(yL(jj));
        end
    end
    
    % creates the fill objects     
    cellfun(@(x,y)(fill(x,y,col(1+(~isLE)),'LineStyle','-',...
                    'FaceAlpha',0.1,'Parent',hAx,'Tag','hExLoc')),X1,Y1);
    cellfun(@(x,y)(fill(x,y,col(1+isLE),'LineStyle','-',...
                    'FaceAlpha',0.1,'Parent',hAx,'Tag','hExLoc')),X2,Y2);                     
    
    % turns off the hold on the axis
    hold(hAx,'off')
end

% removes stimulation count menu item (if not connecting channel to tube)
if ~isC2T
    if (isfield(handles,'menuStimCount'))
        delete(handles.menuStimCount)
        handles = rmfield(handles,'menuStimCount');
    end
end

% updates the strings for the menu items (if using 2D regions)
if iMov.is2D
    set(handles.menuFlyPos1,'label','Fly Position (Centre)')
    set(handles.menuFlyPos2,'label','Fly Position (Edge)')
end

% --------------------------- %
% --- FIGURE DIMENSIONING --- %
% --------------------------- %

% retrieves the figure position
figPos = get(handles.figTrackStats,'position');

% sets the panel height
isG = size(iGrp,2) > 1;
Wpanel = ((WappS+2)*nApp+(WflyS+2));
Hpanel = calcStatPanelHeight(nFly,nTotP,nTotS,HappS,Ys,isC2A,isT,isG);
Haxis = calcStatPanelHeight(15,nTotP,nTotS,HappS,Ys,true,isT,isG);

% sets the overall panel size
pPos = [X0 Y0+max(0,Haxis-Hpanel) Wpanel Hpanel];
axPos = [(2*X0+Wpanel) Y0+max(0,Hpanel-Haxis) Haxis*[4/3 1]];
figPos = [figPos(1:2) (pPos(3)+axPos(3)+3*X0) (2*Y0+max(pPos(4),axPos(4)))];

% sets the panel/figure dimensions
set(handles.panelTrackStats,'position',pPos)
set(handles.panelAxisPlot,'position',axPos)
set(handles.figTrackStats,'position',figPos)

% -------------------------------- %
% --- AXON PLOT INITIALISATION --- %
% -------------------------------- %

% parameters
[lSz,tSz] = deal(20,30);    
    
% % sets the axis location
% haxPos = [7*X0 5.5*Y0 0 0];
% haxPos(3) = axPos(3) - (haxPos(1)+2.5*X0);
% haxPos(4) = axPos(4) - (haxPos(2)+4.5*Y0);
% set(handles.axesProgress,'position',haxPos)

% initialises the 
pF = setFormatFields(1);
pF.Title = setFormatFields(setupFontStruct('FontSize',tSz),'Average Speed',1);
pF.xLabel = setFormatFields(setupFontStruct('FontSize',lSz),'Time (s)',1);
pF.yLabel = setFormatFields(setupFontStruct('FontSize',lSz),'Avg Speed (mm/s)',1);
pF.Axis = setFormatFields(setupFontStruct('FontSize',lSz-4),[]);
[pF.xLabel.ind,pF.yLabel.ind] = deal(1);

% initialisaes the axis object
hAx = createSubPlotAxes(handles.panelAxisPlot,[1,1],1);
set(hFig,'CurrentAxes',hAx)
set(hAx,'SortMethod','childorder','Color',0.8*[1 1 1]);
handles.axesProgress = hAx;

% adds the plot labels
hPlot = zeros(nGrp,1);
for i = 1:nGrp
    hPlot(i) = plot(hAx,NaN,NaN,'UserData',i,'Color',colSetTabColour(i),...
                                'LineWidth',2);
end

% sets the label properties
set(hAx,'ylim',[0 Vtol],'xlim',[0 TlimRT]);
formatPlotAxis(hAx,pF,1);

% if the connection type is channel to apparatus, then update the criteria
% marker on the real-time tracking plot
if (getappdata(handles.figTrackStats,'isC2A'))
    % initialisations   
    gType = get(findall(handles.menuGraph,'checked','on'),'tag');
    yData = getCritValue(getappdata(hGUI,'rtP'),gType);
        
    % plots the criteria fill region
    [xx,yy] = deal([0,TlimRT],[0 yData]);
    fill(xx([1 2 2 1]),yy([1 1 2 2]),'r','LineStyle','--',...
                           'FaceAlpha',0.2,'Parent',hAx,'Tag','hCrit')
end
    
% resets the axis position so everything looks nice
resetAxesPos(hAx,1,1);

% creates the legend
if (nGrp > 1)
    iPlot = num2cell(1:nGrp);
    pF.Legend.String = cellfun(@(x)(sprintf('#%i',x)),iPlot,'un',0);    
    hLg = createLegendObj(hPlot,pF.Legend,1,0);    
    set(hLg,'Location','BestOutside','box','off')
end

set(hAx,'Units','Pixels','Box','on')
grid(hAx,'minor');
grid(hAx,'on');
set(handles.panelAxisPlot,'Units','Pixels')

% --------------------------------------- %
% --- OBJECT DIMENSIONING & LOCATIONS --- %
% --------------------------------------- %

% memory allocation
[pSepV,pColS] = deal(cell(nApp,1));
[pRowS,pTotS,sTotS] = deal(cell(nFly,1),cell(nTotP,1),cell(nTotS,1));

% horizontal seperator dimensions
if (isC2A)
    % adds in the extra marker space
    pSepH = repmat({[0 0 (pPos(3)-2) HsepH]},3+(isT+isG),1);
    pSepH{1+isT}(2) = (2*Ys+nTotS*HappS-1+dy0);
    pSepH{2+isT}(2) = (pSepH{1+isT}(2)+1)+(2*Ys+nTotP*HappS-1);
    pSepH{3+isT}(2) = (pSepH{2+isT}(2)+1)+(2*Ys+nFly*HappS-1);           
    if (isG); pSepH{4+isT}(2) = pSepH{3+isT}(2) + (HappS+Ys); end
else
    % removes the extra marker space
    pSepH = repmat({[0 0 (pPos(3)-2) HsepH]},2+(isT+isG),1);
    pSepH{1+isT}(2) = (2*Ys+nTotP*HappS-1+dy0);
    pSepH{2+isT}(2) = (pSepH{1+isT}(2)+1)+(2*Ys+nFly*HappS-1); 
    if (isG); pSepH{3+isT}(2) = pSepH{2+isT}(2) + (HappS+Ys); end
end

% sets the time field (if required)
if (isT); pSepH{1}(2) = dy0; end
    
% vertical seperator and column header title dimensions
[nGrp,j0] = deal(sum(~isnan(iGrp),2),0);
for i = 1:size(iGrp,1)
    % sets the indices for the current group
    iGrpC = iGrp(i,1:sum(~isnan(iGrp(i,:))));
    
    % creates the vertical seperator postion vectors
    for j = 1:length(iGrpC)        
        % sets the global index
        k = j0 + j;            
        
        % case is for a column displaying the tracking duration
        pSepV{k} = [((WflyS+1)+(k-1)*(WappS+2)) 1 WsepV (pPos(4)-2)];
        if (isT) && (k < (nApp-1))            
            pSepV{k}([2 4]) = pSepV{k}([2 4]) + [(dy0-1) -dy0];                
        end

        % column header title postion vector
        pColS{k} = [(pSepV{k}(1)+2) (pSepH{end-isG}(2)+(Ys-1)) (WappS-2) (HappS-1)];        
        
        % 
        if (length(iGrpC) == 1)
            if (isG)
                if (nGrp(i-1) == 1)
                    pSepV{k}(4) = pSepV{k}(4) - (Ys+HappS);    
                end
            end
        elseif ((j > 1) && ((k > 1) && (isG)))
            % removes any vertical separators within a combined group
            pSepV{k} = [];
        end
                
        % sets the final horiztonal separator (grouped regions only)
        if (isG) && (k == 1)
            pSepH{end}([1 3]) = [0 pSepH{1}(3)] + pSepV{i}(1)*[1 -1];
        end                
    end
    
    % increments the global counter
    j0 = j0 + length(iGrpC);    
end   

% row header title position vectors
for i = 1:nFly
    j = nFly - (i-1);
    pRowS{i} = [1 (pSepH{end-(1+isG)}(2)+(Ys+1)+(j-1)*HflyS) WflyS HflyS];
end   

% static field object cell arrays
hStatT = cell(nTotS,size(iGrp,1));
[hTotE,hTotT] = deal(cell(nTotP,size(iGrp,1)));
[hDataE,hDataT] = deal(cell(nFly,nApp));

% ------------------------- %
% --- MAIN TABLE FIELDS --- %
% ------------------------- %      

% sets the initial vertical offset
if isC2A
    % case is a population stimuli connection
    Y0 = (pSepH{1+isT}(2)+1);
elseif isT
    % case is the duration counter is visible
    Y0 = pSepH{1}(2);
else
    % no vertical offset
    Y0 = 0;
end
    
% sets the mean information fields y-offset
if ~isC2T; showSD = false; end
if ~isC2A; showPD = false; end

% sets the column header titles for all subregions
j0 = 0;
for i = 1:size(iGrp,1)
    % sets the indices for the current group
    iGrpC = iGrp(i,1:nGrp(i));
    
    % creates the column headers for each sub-region
    for j = 1:length(iGrpC)
        k = j0 + j;
        uicontrol('Style','text','String',sprintf('Sub-Region #%i',iGrpC(j)),...
                  'Position',pColS{k},'Parent',hPanel,'FontUnits','pixels',...
                  'FontWeight','bold','FontSize',12);
    end
    
    % if the sub-regions are grouped, then set the column header
    if (nGrp(i) > 1)
        pColG = pColS{j0+1} + [0 (Ys+HappS-2) 0 0];
        pColG(3) = nGrp(i)*pColG(3)-2;        
        uicontrol('Style','text','String',sprintf('Combined Group #%i',i),...
                  'Position',pColG,'Parent',hPanel,'FontUnits','pixels',...
                  'FontWeight','bold','FontSize',12);        
    end
    
    % increments the global counter
    j0 = j0 + length(iGrpC);
end

% sets the row header titles for all flies
for i = 1:nFly    
    uicontrol('Style','text','String',sprintf('Fly #%i',i),...
              'Position',pRowS{i},'Parent',hPanel,'FontUnits','pixels',...
              'FontWeight','bold','FontSize',12);          
end

% data strings/status editboxes for all the flies/apparatus
for j = 1:nApp
    % sets the individual fly detail strings/status objects
    for i = nFlyR(j):-1:1    
        % determines if the current configuration has a match
        if (isC2T)            
            showSD = any(cellfun(@(x)(isequal(x,[j,i])),num2cell(Stim.C2T,2)));            
        end
        
        % creates the data strings
        pDatS = [pColS{j}(1) pRowS{i}(2) (WappS-5) HdatS];
        hDataT{i,j} = uicontrol('Style','text','String','***',...
                  'Position',pDatS,'tag','hDataT','UserData',[i j],...
                  'Parent',hPanel,'FontUnits','pixels',...
                  'FontWeight','bold','FontSize',12);
              
        % creates the status checkbox (if required)       
        if (showSD)
            pStatS = [(pColS{j}(1)+WdatS+1) (pRowS{i}(2)+1) Wstat Hstat];
            hDataE{i,j} = uicontrol('Style','edit','String','','Parent',hPanel,...
                      'Position',pStatS,'tag','hDataE','UserData',[i j],...
                      'HitTest','off','Enable','inactive',...
                      'Backgroundcolor','k');        
        end
    end
end

% -------------------------------- %
% --- STATISTICAL VALUE FIELDS --- %
% -------------------------------- %
 
% initialisations
j0 = 0;

%
for j = 1:size(iGrp,1)
    for k = 1:nGrp(j)
        % sets the global index
        jj = j0+k;
        
        % sets the flag for showing the population data (if required)
        if (k == nGrp(j))
            if (isC2A); showPD = any(Stim.C2A == j); end            
        
            % creates the population detail strings/status objects
            for i = 1:nTotP        
                % creates the data string        
                pDatS = [pColS{jj}(1) (Y0+(Ys+(i-1)*HdatS)) (WappS-5) HdatS];
                hTotT{i,j} = uicontrol('Style','text','String','***',...
                          'Position',pDatS,'tag','hTotT','UserData',[i j],...
                          'Parent',hPanel,'FontUnits','pixels',...
                          'FontWeight','bold','FontSize',12);   

                % creates the status checkbox
                if (showPD)
                    pStatS = [(pColS{jj}(1)+WdatS+1) (pDatS(2)+1) Wstat Hstat];
                    hTotE{i,j} = uicontrol('Style','edit','String','','Parent',hPanel,...
                              'Position',pStatS,'tag','hTotE','UserData',[i,j],...
                              'HitTest','off','Enable','inactive',...
                              'Backgroundcolor','k');                  
                end
            end        

            % creates the data string
            if (isC2A)
                for i = 1:nTotS
                    % creates the data string        
                    sDatS = [pColS{jj}(1) (Ys+(i-1)*HdatS+dy0) (WappS-5) HdatS];
                    switch (i)
                        case (1) % case is the last shock time
                            nwStr = 'N/A';
                        case (2) % case is the shock counter
                            nwStr = '0';
                        otherwise % case is the other fields
                            nwStr = '***';
                    end

                    % creates the text object for the field
                    hStatT{i,j} = uicontrol('Style','text','String',nwStr,...
                              'Position',sDatS,'tag','hStatT','UserData',[i j],...
                              'Parent',hPanel,'FontUnits','pixels','FontWeight',...
                              'bold','FontSize',12,'enable',eStr{1+showPD});    
                end    
            end
        end
    end
    
    % increments the global counter
    j0 = j0 + nGrp(j);
end

% creates the population statistic strings       
for i = 1:nTotP
    pTotS{i} = [1 (Y0+(Ys+(i-1)*HflyS)) WflyS HflyS];
    uicontrol('Style','text','String',pTotStr{i},...
              'Position',pTotS{i},'Parent',hPanel,'FontUnits','pixels',...
              'FontWeight','bold','FontSize',12);    
end          

% creates the channel to apparatus statistic strings
if (isC2A)
    for i = 1:nTotS
        sTotS{i} = [1 (Ys+(i-1)*HflyS+dy0) WflyS HflyS];
        uicontrol('Style','text','String',sTotStr{i},'Position',sTotS{i},...
                  'Parent',hPanel,'FontUnits','pixels',...
                  'FontWeight','bold','FontSize',12);    
    end
end

% sets the tracking duration labels
if (isT)
    % duration label
    sTimeS = [pColS{nApp-1}(1) Ys (WappS-5) HdatS];
    uicontrol('Style','text','String','Tracking Duration','Position',sTimeS,...
              'Parent',hPanel,'FontUnits','pixels',...
              'FontWeight','bold','FontSize',12);        
    
    % duration string
    sTimeL = [pColS{nApp}(1) Ys (WappS-5) HdatS];
    hTime = uicontrol('Style','text','String','***','Position',sTimeL,...
              'Parent',hPanel,'FontUnits','pixels','tag','hTime',...
              'FontWeight','bold','FontSize',12);            
    setappdata(hFig,'hTime',hTime)
end

% sets the object arrays into the main GUI
setappdata(hFig,'hStatT',hStatT)
setappdata(hFig,'hTotT',hTotT)
setappdata(hFig,'hTotE',hTotE)
setappdata(hFig,'hDataE',hDataE)
setappdata(hFig,'hDataT',hDataT)

% -------------------------------------- %
% --- HORIZONTAL/VERTICAL SEPERATORS --- %
% -------------------------------------- %

% vertical seperators
for i = 1:nApp
    if ~isempty(pSepV{i})
        hh = uicontrol('Style','edit','String','','Enable','inactive',...
                       'Position',pSepV{i},'Parent',hPanel); 
        uistack(hh,'top')                
    end
end   

% lower horizontal seperator
for i = 1:length(pSepH)
    hh = uicontrol('Parent',hPanel,'Style','edit','Enable',...
                   'inactive','String','','Position',pSepH{i}); 
    uistack(hh,'top')      
end

% --- resets the tracking GUI fields
function resetTrackingGUI(handles,Type)

% ------------------------------------------- %
% --- MEMORY ALLOCATION & INITIALISATIONS --- %
% ------------------------------------------- %

% retrieves the caller program GUI handles and sub-region data struct
[hFig,hAx] = deal(handles.figTrackStats,handles.axesProgress);
hGUI = getappdata(hFig,'hGUI');
iMov = getappdata(hFig,'iMov');
rtP = getappdata(hGUI,'rtP');

% retrieves the sub-region data struct
[aok,Stim] = deal(find(iMov.ok),rtP.Stim);
[nApp,nFlyR] = deal(length(aok),getSRCountVec(iMov));

% retrieves the grouping indices/counts
iGrp = rtP.combG.iGrp;
if isempty(iGrp); iGrp = (1:nApp)'; end
nGrp = sum(~isnan(iGrp),2);

% retrieves the data struct
hDataT = getappdata(hFig,'hDataT');
hDataE = getappdata(hFig,'hDataE');
hTotT = getappdata(hFig,'hTotT');
hTotE = getappdata(hFig,'hTotE');
hStatT = getappdata(hFig,'hStatT');
isC2A = getappdata(hFig,'isC2A');
isC2T = getappdata(hFig,'isC2T');

% array dimensioning
[nTotS,nTotP] = deal(size(hStatT,1),size(hTotE,1));

% ------------------------------------- %
% --- GUI OBJECT RE-INITIALISATIONS --- %
% ------------------------------------- %

% updates the plot values
for iApp = 1:size(iGrp,1)
    % retrieves the plot handle and the new plot data
    hPlot = findobj(hAx,'UserData',iApp,'Type','Line');
    set(hPlot,'xdata',NaN,'ydata',NaN) 
end

% data strings/status editboxes for all the flies/apparatus
for j = 1:nApp
    % sets the individual fly detail strings/status objects
    for i = nFlyR(j):-1:1    
        % determines if the current configuration has a match
        % creates the data strings        
        set(hDataT{i,j},'String','***');
              
        % creates the status checkbox (if required) 
        if (isC2T)
            if (any(cellfun(@(x)(isequal(x,[j,i])),num2cell(Stim.C2T,2))))            
                set(hDataE{i,j},'Backgroundcolor','k');        
            end
        end
    end
end

% 
for j = 1:size(iGrp,1)
    for k = 1:nGrp(j)
        % sets the flag for showing the population data (if required)
        if (k == nGrp(j))
            if (isC2A); showPD = any(rtP.Stim.C2A == j); end            
        
            % creates the population detail strings/status objects
            for i = 1:nTotP        
                % creates the data string        
                set(hTotT{i,j},'string','***');

                % creates the status checkbox
                if (showPD)
                    set(hTotE{i,j},'Backgroundcolor','k');
                end
            end        
            
            % creates the data string
            if (isC2A)
                for i = 1:nTotS
                    % creates the data string    
                    col = 'k';
                    switch (i)
                        case (1) % case is the last shock time
                            nwStr = 'N/A';
                        case (2) % case is the shock counter
                            nwStr = '0';
                        case (4) %                             
                            nwStr0 = {'Pre-Experiment','Video Changeover'};                            
                            [col,nwStr] = deal([237,136,33]/255,nwStr0{Type});
                        otherwise % case is the other fields
                            nwStr = '***';
                    end

                    % creates the text object for the field
                    set(hStatT{i,j},'String',nwStr,'ForegroundColor',col);
                end    
            end
        end
    end
end

% --- calculates the height of the panel
function Hpanel = calcStatPanelHeight(nFly,nTotP,nTotS,HappS,Ys,isC2A,isT,isG)

% sets the default grouping flag (if not provided
if (nargin < 8); isG = 0; end

% sets the 
if (isC2A)    
    Hpanel = ((nTotP+nTotS+nFly+1+isT+isG)*HappS+(2*(4+isT)*Ys));
else
    Hpanel = ((nTotP+nFly+1+isT+isG)*HappS+(2*(3+isT)*Ys));
end

% --- updates the colours of the status regions
function updateStatusColour(h,hTag,hInd,hVal)

% initialisations
col = {'g','r',[255 102 0]/255};
hh = getappdata(h,hTag);

% sets the colour strings
if (length(hInd) == 2)
    % sets the colour values
    X = repmat(hInd{1},size(hInd{2}));
    if (length(hVal) ~= length(hInd{2}))
        colVal = repmat(hVal+1,size(X));
    else
        colVal = reshape(hVal+1,size(X));
    end
    
    % retrieves the object handles
    hhObj = reshape(hh(hInd{2},hInd{1}),size(col(colVal)));    
else
    % retrieves object handles and colour indices
    hhObj = hh(:,hInd{1});
    colVal = repmat(hVal+1,size(hhObj));
end

% updates the population statistic fields
colStr = reshape(col(colVal),size(hhObj));
cellfun(@(x,y)(set(x,'backgroundcolor',y)),hhObj,colStr);

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %
        
% --- retrieves the critical value for the real-time plot graph
function yData = getCritValue(rtP,gType)

% initialisations
yData = NaN;

% sets the criteria marker value (based on the menu value)
switch (gType)
    case ('menuAvgVel') % case is average velocity
        if (rtP.popSC.isVtol)
            yData = rtP.popSC.Vtol;
        end
    case ('menuPropInact') % case is inactive proportion
        if (rtP.popSC.isPtol)
            yData = 100*rtP.popSC.Ptol;                
        end            
    case ('menuMeanInact') % case is mean inactive duration
        if (rtP.popSC.isMtol)
            yData = rtP.popSC.Mtol;                
        end                        
end

% --- retrieves the handle of the checked menu item
function hMenuC = getCheckedMenuItem(hParent)

% updates the field properties (based on the selected metric)
hMenu = num2cell(findobj(hParent,'type','uimenu'));
hMenuC = hMenu{cellfun(@(x)(strcmp(get(x,'checked'),'on')),hMenu)};

% --- initialises the plot data struct
function [iPara,iMov] = setPlotDataStruct(iMov)

% sets the 2D flag (if not already set)
if ~isfield(iMov,'is2D')
    iMov.is2D = is2DCheck(iMov);
end

% allocates memory for the data struct
iPara = struct('tDur',300,'vMax',10*(1+iMov.is2D));
