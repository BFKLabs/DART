function varargout = UndockPlot(varargin)
% Last Modified by GUIDE v2.5 19-Sep-2016 18:10:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @UndockPlot_OpeningFcn, ...
                   'gui_OutputFcn',  @UndockPlot_OutputFcn, ...
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

% --- Executes just before UndockPlot is made visible.
function UndockPlot_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global fPos0 L0 W0 isDocked updateFlag
[isDocked,updateFlag] = deal(false,2);
pause(0.1); 

% Choose default command line output for UndockPlot
handles.output = hObject;
setObjVisibility(hObject,'off'); 
pause(0.05)

% sets the input arguments
hGUI = varargin{1};
hPara = getappdata(hGUI.figFlyAnalysis,'hPara');
sPara = getappdata(hGUI.figFlyAnalysis,'sPara');

% sets the data structs into the GUI
setappdata(hObject,'hGUI',hGUI)
setappdata(hObject,'hPara',hPara)
setappdata(hObject,'sPara',sPara)
setappdata(hObject,'snTot',getappdata(hGUI.figFlyAnalysis,'snTot'))
setappdata(hObject,'iProg',getappdata(hGUI.figFlyAnalysis,'iProg'))

% retrieves the original plot panel/figure position vectors
set(hGUI.panelPlot,'Units','pixels')
fPos0 = get(hGUI.figFlyAnalysis,'Position');
pPos0 = get(hGUI.panelOuter,'Position');
L0 = sum(pPos0([1 3])) + 10;
W0 = fPos0(3) - (L0+10);

% copies any axes on the main GUI to the undocked gUI
hAx = findall(hGUI.panelPlot,'type','axes');

% deletes the current axes objects and shrinks the main GUI width to
% account for the remove of the plot panel
delete(hAx);
resetObjPos(hGUI.panelPlot,'width',1)

% makes the figure invisible
% setObjEnable(hGUI.menuUndock,'off');
setObjVisibility(hGUI.figFlyAnalysis,'off'); 
pause(0.05); 

% resets the left/bottom locations of the GUI
resetObjPos(hObject,'left',fPos0(1)+L0+25)
resetObjPos(hObject,'bottom',fPos0(2))

% makes the figure visible again
setappdata(hGUI.figFlyAnalysis,'hUndock',hObject)
centreFigPosition(hObject);

% if not docked (and showing GUIs) then create the plot panel objects
if (size(sPara.pos,1) > 1)
    % creates a loadbar
    h = ProgressLoadbar('Initialising Analysis Plot...');
        
    % initialises the subplot panels and makes the parameter GUI visible
    setObjVisibility(hPara,'off')
    setupSubplotPanels(handles.panelPlot,sPara,@axisClickCallback)                
    
    % updates the subplot selection
    sInd = getappdata(hGUI.figFlyAnalysis,'sInd');
    subPlotSelect(handles,sInd,1)    
    
    % deletes the loadbar 
    delete(h); pause(0.05);      
elseif (~isempty(hPara))
    % updates the plot figure
    updatePlotFigure(hObject,getappdata(hPara,'pData'));
end
    
% Update handles structure
guidata(hObject, handles);

% makes the GUI visible
setObjVisibility(hObject,'on');

% resets the flag
pause(0.1);
updateFlag = 0;

% UIWAIT makes UndockPlot wait for user response (see UIRESUME)
% uiwait(handles.figUndockPlot);

% --- Outputs from this function are returned to the command line.
function varargout = UndockPlot_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                       TOOLBAR CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% -------------------------------------------------------------------------
function menuSave_ClickedCallback(hObject, eventdata, handles)

% updates the plot figure
hGUI = getappdata(handles.figUndockPlot,'hGUI');
hPara = getappdata(hGUI.figFlyAnalysis,'hPara');
if (isempty(hPara))
    return
end

% runs the save figure GUI
SaveFigure(handles)

% -------------------------------------------------------------------------
function menuEditPlot_ClickedCallback(hObject, eventdata, handles)

% retrieves the main GUI handles
hGUI = getappdata(handles.figUndockPlot,'hGUI');
hPara = getappdata(hGUI.figFlyAnalysis,'hPara');

% toggles the plot editting
if (strcmp(get(hObject,'state'),'on'))
    if (isempty(hPara))
        % if there is no parameter GUI, then exit the function
        set(hObject,'state','off')
        return
    else
        % otherwise, enabled the plot editting
        plotedit(handles.figUndockPlot,'on')
        eStr = 'off';
    end    
else
    % otherwise, disable the plot editing
    plotedit(handles.figUndockPlot,'off')
    eStr = 'on';
end

% sets the visible properties of the other objects
setObjVisibility(hPara',eStr)
setObjEnable(handles.menuPlot,eStr)

% -------------------------------------------------------------------------
function menuZoom_ClickedCallback(hObject, eventdata, handles)

% toggles the zoom based on the button state
if strcmp(get(hObject,'state'),'on')
    zoom on
else
    zoom off
end

% -------------------------------------------------------------------------
function menuDataCursor_ClickedCallback(hObject, eventdata, handles)

% toggles the data cursor based on the button state
if strcmp(get(hObject,'state'),'on')
    set(setObjEnable(datacursormode(gcf),'on'),'DisplayStyle','window')    
else
    setObjEnable(datacursormode(gcf),'off')    
end

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% -------------------------------------------------------------------------
function menuRedock_Callback(hObject, eventdata, handles)

% global variables
global W0 isDocked
isDocked = true;

% retrieves the main GUI handles
hGUI = getappdata(handles.figUndockPlot,'hGUI');
hPara = getappdata(hGUI.figFlyAnalysis,'hPara');
sPara = getappdata(hGUI.figFlyAnalysis,'sPara');

% copies any axes on the main GUI to the undocked gUI
hAx = findall(hGUI.panelPlot,'type','axes');

% resets the main GUI width
delete(hAx);
resetObjPos(hGUI.panelPlot,'width',W0)

% deletes the docking GUI
setObjEnable(hGUI.menuUndock,'on');
delete(handles.figUndockPlot)
setappdata(hGUI.figFlyAnalysis,'hUndock',[])

% if not docked (and showing GUIs) then create the plot panel objects
if size(sPara.pos,1) > 1
    % creates a loadbar
    h = ProgressLoadbar('Initialising Analysis Plot...');
    
    % initialises the subplot panels and makes the parameter GUI visible    
    fcnAxC = getappdata(hGUI.figFlyAnalysis,'axisClickCallback');
    setupSubplotPanels(hGUI.panelPlot,sPara,fcnAxC,1)    
            
    % deletes/clears the analysis parameter GUI
    if strcmp(get(hPara,'visible'),'off')
        if ~isempty(hPara); delete(hPara); end
        setappdata(hGUI.figFlyAnalysis,'hPara',[]);    
    end
    
    % updates the sub-index popup function    
    popFcn = getappdata(hGUI.figFlyAnalysis,'popupSubInd');
    set(hGUI.popupSubInd,'value',getappdata(hGUI.figFlyAnalysis,'sInd'))
    popFcn(hGUI.popupSubInd,1,hGUI)       
    
    % deletes the loadbar 
    delete(h); pause(0.05); 
    
elseif ~isempty(hPara)
    % updates the plot figure
    updatePlotFigure(hGUI,getappdata(hPara,'pData'));
end

% gives focus to the main Analysis GUI
setObjVisibility(hGUI.figFlyAnalysis,'on'); pause(0.05);
figure(hGUI.figFlyAnalysis)

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when figUndockPlot is resized.
function figUndockPlot_ResizeFcn(hObject, eventdata, handles)

% global variables
global updateFlag 

% resets the timer
tic;

% dont allow any update (if flag is set to 2)
if (updateFlag ~= 0)
    return; 
else
    updateFlag = 2;
    while (toc < 0.5)
        java.lang.Thread.sleep(10);
    end
end

% retrieves the required data structs
hGUI = getappdata(handles.figUndockPlot,'hGUI');
sPara = getappdata(hGUI.figFlyAnalysis,'sPara');
sInd0 = getappdata(hGUI.figFlyAnalysis,'sInd0');
snTot = getappdata(hGUI.figFlyAnalysis,'snTot');
pData = getappdata(hGUI.figFlyAnalysis,'pData');
plotD = getappdata(hGUI.figFlyAnalysis,'plotD');
initAxesObject = getappdata(hGUI.figFlyAnalysis,'initAxesObject');

% retrieves the final position of the resized GUI
fPos = getFinalResizePos(hObject);
[eInd,fInd,pInd] = getSelectedIndices(hGUI);

% checks if the plot figure needs to be updated
[iReg,nReg] = deal(true,size(sPara.pos,1));
if (nReg > 1)
    % if multiple subplots, check each subplot to see if a valid dataset
    % has been set
    iReg = ~cellfun(@isempty,sPara.pData)';
end

% makes the figure invisible
setObjVisibility(hObject,'off'); 
pause(0.1);

% creates a loadbar
h = ProgressLoadbar('Updating Analysis Plot...');

% initialises axes and runs the plotting function
for i = find(iReg)
    if (nReg == 1)
        % retrieves the axis handle
        set(handles.panelPlot,'Units','Pixels');
        [hP,X0,Y0] = deal(handles.panelPlot,10,10); 
        set(hP,'Position',[X0,Y0,fPos(3:4)-[X0,Y0]]);
        
        % retrieves the plot data struct
        pDataNw = pData{pInd}{fInd,eInd};
        plotDNw = plotD{pInd}{fInd,eInd};
    else           
        % updates the subplot index
        setappdata(hGUI.figFlyAnalysis,'sInd',i);

        % retrieves the axis handle
        hP = findall(handles.panelPlot,'tag','subPanel','UserData',i);
           
        % retrieves the plot data struct
        [eInd,pInd] = deal(sPara.ind(i,1),sPara.ind(i,3));
        [pDataNw,plotDNw] = deal(sPara.pData{i},sPara.plotD{i});
    end

    % determines if there are any annotations
    hGG = findall(get(handles.panelPlot,'parent'),'type','annotation');    
    
    % determines if there are any annotations        
    if ~isempty(hGG)
        isReplot = true;
    else
        rpFcn = {'Stimuli Response','Pre & Post'};
        isRPFcn = cellfun(@(x)(strContains(pDataNw.Name,x)),rpFcn);        
        hPP = findall(handles.panelPlot,'tag','hPolar');
        isReplot = ((pDataNw.hasRS) && (isempty(hPP))) || any(isRPFcn);
    end    
    
    % determines if the axis is reset or not
    if isReplot        
        % clears the plot axis
        initAxesObject(hGUI); 

        % recreates the new plot
        if (pInd == 3)
            feval(pDataNw.pFcn,snTot,pDataNw,plotDNw);           
        else
            feval(pDataNw.pFcn,reduceSolnAppPara(snTot(eInd)),...
                                        pDataNw,plotDNw);           
        end    
        
        % ensures the figure is still invisible
        setObjVisibility(hObject,'off');     
    else
        % resets the plot axis based on the number of subplots
        [hAx,hLg,m,n] = resetPlotFontResize(hP,pDataNw);

        % resets the plot axis based on the number of subplots 
        resetAxesPos(hAx,m,n);  

        % determines if the plots axes need to be resized for legend
        % objects that are outside the plot regions            
        if (~isempty(hLg))
            % determines if any legend objects are outside the axes
            isInAx = ~strcmp(get(hLg,'location'),'none');
            if (any(~isInAx))
                % if any legends outside of the axis, then reposition
                resetLegendPos(hLg(~isInAx),hAx)               
            end
        end           
    end
end

% deletes the loadbar and makes the GUI visible again
delete(h)            
setObjVisibility(hObject,'on'); 

% ensures the figure doesn't resize again (when maximised)
% set(hObject,'units',uStr0)
updateFlag = 2;
pause(0.5);
updateFlag = 0;

% resets the original sub-plot index
setappdata(hGUI.figFlyAnalysis,'sInd0',sInd0);

% --- callback function when a sub-plot axes is clicked
function axisClickCallback(hObject, eventdata)

% retrieves the GUI object handles
handles = guidata(hObject);

% determines the object being selected
if (strcmp(get(hObject,'type'),'axes'))
    % case selecting an axes object
    sInd = get(get(hObject,'Parent'),'UserData');
else
    % case selecting a panel object
    sInd = get(hObject,'UserData');
end

% updates the subplot selection
subPlotSelect(handles,sInd)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% ------------------------------ %
% --- GUI PROPERTY FUNCTIONS --- %
% ------------------------------ %

% --- updates the figure/parameter properties on selecting a sub-region
function subPlotSelect(handles,sInd,varargin)

% retrieves the required data structs
hGUI = getappdata(handles.figUndockPlot,'hGUI');
sPara = getappdata(handles.figUndockPlot,'sPara');
hPara = getappdata(handles.figUndockPlot,'hPara');

% updates the subplot index
sInd0 = getappdata(hGUI.figFlyAnalysis,'sInd');
setappdata(hGUI.figFlyAnalysis,'sInd',sInd)

% resets the highlight panel colours
hPanel = findall(handles.panelPlot,'tag','subPanel');
set(hPanel,'HighLightColor','w');
set(findobj(hPanel,'tag','subPanel','UserData',sInd),'HighlightColor','r');

% updates the plot parameters (if a valid plot has been selected)
if ((~isempty(sPara.pData{sInd0})) && (nargin == 2))
    % retrieves the experiment, function and plot indices
    ind = sPara.ind(sInd0,:);
    [eInd,fInd,pInd] = deal(ind(1),ind(2),ind(3));

    % if so, then update the plotting data struct
    sPara.pData{sInd0} = getappdata(hPara,'pData');
    setappdata(handles.figUndockPlot,'sPara',sPara);

    % updates the plot data struct
    pData = getappdata(hGUI.figFlyAnalysis,'pData');
    pData{pInd}{fInd,eInd} = getappdata(hPara,'pData');
    setappdata(hGUI.figFlyAnalysis,'pData',pData);
end

% updates the plot parameters (if a valid plot has been selected)
if (~isempty(sPara.pData{sInd}))
    % sets the new selected indices
    [lStr,fName] = deal(get(hGUI.listPlotFunc,'string'),sPara.pData{sInd}.Name);
    fIndNw = find(cellfun(@(x)(any(strfind(x,fName))),lStr));  

    % if there is more than one match, then narrow them down    
    if (length(fIndNw) > 1)        
        ii = cellfun(@(x)(strfind(x,'>')),lStr(fIndNw),'un',0);
        jj = cellfun(@(x,y)(strcmp(x(y(end)+1:end),fName)),lStr(fIndNw),ii);
        fIndNw = fIndNw(jj);
    end    
    
    % update the popup menu/list values
    set(hGUI.popupExptIndex,'value',sPara.ind(sInd,1))
    set(hGUI.popupPlotType,'value',sPara.ind(sInd,3)) 
    set(hGUI.listPlotFunc,'value',fIndNw)    
    
    % updates the parameter GUI
    if (isempty(hPara))
        hPara = AnalysisPara(hGUI);
        setappdata(hGUI.figFlyAnalysis,'hPara',hPara);
        setappdata(handles.figUndockPlot,'hPara',hPara)
    else
        feval(getappdata(hPara,'initAnalysisGUI'),hPara,hGUI)  
    end
else
    % otherwise, remove the plot list
    setObjVisibility(hPara,'off');     
end