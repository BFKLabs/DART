function varargout = AnalysisPara(varargin)
% Last Modified by GUIDE v2.5 24-Jan-2022 04:19:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AnalysisPara_OpeningFcn, ...
                   'gui_OutputFcn',  @AnalysisPara_OutputFcn, ...
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

% --- Executes just before AnalysisPara is made visible.
function AnalysisPara_OpeningFcn(hObject, ~, handles, varargin)

% Choose default command line output for AnalysisPara
setObjVisibility(hObject,'off'); 
pause(0.05)
handles.output = hObject;

% sets the input arguments
hGUI = varargin{1};
setappdata(hObject,'hGUI',hGUI)

% sets the function handles
setappdata(hObject,'getPlotData',@getPlotData)
setappdata(hObject,'initAnalysisGUI',@initAnalysisGUI)

% initialises the base GUI objects
handles = initBaseGUIObjects(handles);
guidata(hObject, handles);

% initialises the analysis parameter class object
pObj = AnalysisParaClass(hObject,hGUI);
if pObj.isOK
    setappdata(hObject,'pObj',pObj)
else
    delete(hObject)
    return
end

% Update handles structure
set(hObject,'CloseRequestFcn',[]);

% UIWAIT makes AnalysisPara wait for user response (see UIRESUME)
% uiwait(handles.figAnalysisPara);

% --- Outputs from this function are returned to the command line.
function varargout = AnalysisPara_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                           BOX-PANEL FUNCTIONS                           %
%-------------------------------------------------------------------------%

% --- initialises the base GUI objects
function handles = initBaseGUIObjects(handles)

% global variables
global pHght

% object handles
hFig = handles.figAnalysisPara;
fPos = get(hFig,'Position');

% other initialisations
dX = 5;
[hdrSz,fSz] = deal(13,12);
[tWid,tWidL,tHght] = deal(140,145,16);
[fWid,pHght] = deal(fPos(3),25);
pPos = [0,0,fWid,30];
txtCol = [0,0,0];
titleCol = 0.8*[1,1,1];

% deletes any existing objects
h = findall(hFig);
h = h(h ~= hFig);
if ~isempty(h); delete(h); end

% text/panel object properties
tStr = {'Recalculation Required','textCalcReqd';...
        'Function Description','textFuncDesc';...
        'Function File Name','textFuncName'};
pStr = {'FUNCTION INFORMATION','panelFuncInfo';...
        'CALCULATION PARAMETERS','panelCalcPara';...
        'PLOTTING PARAMETERS','panelPlotPara';...
        'STIMULI RESPONSE','panelStimResPara';...
        'SUBPLOT CONFIGURATION','panelSubPara';...          
        'TIME PARAMETERS','panelTimePara'};
        
% creates the box panel object
nPanel = size(pStr,1);
hghtMin = pHght*ones(1,nPanel);

% creates the box panel object
handles = setStructField(handles,'panelVBox',uix.VBox('Parent',hFig));

% creates the panel objects
hPanel = cell(nPanel,1);
for i = 1:nPanel    
    % creates the new panel object        
    hPanel{i} = uix.BoxPanel('Title',pStr{i,1},'Parent',handles.panelVBox,...
                          'UserData',i,'tag',pStr{i,2},...
                          'Minimized',false,'TitleColor',titleCol,...
                          'ForegroundColor',txtCol,'FontWeight','Bold',...
                          'FontUnits','Pixels','FontSize',hdrSz);    
    handles = setStructField(handles,pStr{i,2},hPanel{i});    
    set(hPanel{i},'MinimizeFcn',{@boxPanelClick,hPanel{i}});
    hghtMin(i) = hghtMin(i) + pPos(4);
    
    % creates the panel object for the box panel
    uipanel(hPanel{i},'Title','','Units','Pixels','Position',pPos,...
                   'tag','hPanelS','UserData',pPos(4));    
end

% retrieves the function description panel handle
hPanelT = findall(hPanel{1},'tag','hPanelS');
set(hPanelT,'UserData',dX*(size(tStr,1)*4+2));
hghtMin(1) = pHght + dX*(size(tStr,1)*4+2);

% creates the function description objects
for i = 1:size(tStr,1)
    % creates the label marker object
    tStrL = sprintf('%sL',tStr{i,2});
    tPosL = [dX,dX*(1+4*(i-1)),tWidL,tHght];
    txtStrL = sprintf('%s: ',tStr{i,1});
    hTxtL = uicontrol(hPanelT,'Style','text','String',txtStrL,...
                            'Tag',tStrL,'FontWeight','Bold',...
                            'FontUnits','Pixels','FontSize',fSz,...
                            'Units','Pixels','Position',tPosL,...
                            'HorizontalAlignment','right');
    
    % creates text label objects
    tPos = [sum(tPosL([1,3])),tPosL(2),tWid,tHght];
    hTxt = uicontrol(hPanelT,'Style','text','String',tStr{i,1},...
                            'Tag',tStr{i,2},'FontUnits','Pixels',...
                            'FontSize',fSz,'Units','Pixels',...
                            'HorizontalAlignment','left',...
                            'Position',tPos);
                        
    % adds the objects the to handle object
    handles = setStructField(handles,tStrL,hTxtL);                          
    handles = setStructField(handles,tStr{i,2},hTxt);      
end

% sets the panel dimensions
set(handles.panelVBox,'MinimumHeights',hghtMin);
set(handles.panelVBox,'Heights',hghtMin);
set(hFig,'Position',[fPos(1:2),fWid,sum(hghtMin)]);

% --- box panel minimise/maximise callback function
function boxPanelClick(hObject, evnt, hPanel)

% global variables
global pHght

% object handles
handles = guidata(hObject);
hFig = handles.output;
iPanel = get(hPanel,'UserData');
hPanelS = findall(hPanel,'tag','hPanelS');
pPosS0 = get(hPanelS,'UserData');
pbHght = get(handles.panelVBox,'Heights');

% updates the minimisation flag
hPanel.Minimized = ~hPanel.Minimized;

% updates the panel heights
nwHght = pHght + double(~hPanel.Minimized)*pPosS0;
pbHght(iPanel) = nwHght;
resetObjPos(hPanelS,'Height',nwHght-pHght)
set(handles.panelVBox,'Heights',pbHght,'MinimumHeights',pbHght)

% updates the figure positions
fPos = get(hFig,'Position');
dHght = sum(pbHght) - fPos(4);
resetObjPos(hFig,'Bottom',-dHght,1);
resetObjPos(hFig,'Height',dHght,1);

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the Analysis Parameters GUI --- %
function varargout = initAnalysisGUI(hPara)

% re-initialises the gui
pObj = getappdata(hPara,'pObj');
pData = pObj.initAnalysisGUI();

% returns the parameter data struct
if (nargout == 1)
    varargout{1} = pData;
end

% --- retrieves the current plot data struct
function pData = getPlotData(hPara)

% retrieves the plot data struct
pObj = getappdata(hPara,'pObj');
pData = pObj.pData;
