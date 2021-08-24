function varargout = AnalysisPara(varargin)
% Last Modified by GUIDE v2.5 30-Jan-2014 02:10:09

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
function AnalysisPara_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global pOfs hOfs hOfs2 B0 nTabMax
[pOfs,hOfs,hOfs2,B0,nTabMax] = deal(10,25,20,50,10);

% Choose default command line output for AnalysisPara
setObjVisibility(hObject,'off'); 
pause(0.05)
handles.output = hObject;

% sets the input arguments
hGUI = varargin{1};
setappdata(hObject,'hGUI',hGUI)
setappdata(hObject,'initAnalysisGUI',@initAnalysisGUI)

% disables the update figure button
setObjEnable(hGUI.buttonUpdateFigure,'off');

% Update handles structure
set(hObject,'CloseRequestFcn',[]);
guidata(hObject, handles);

% initialises the Analysis Parameter GUI
initAnalysisGUI(hObject,hGUI)

% re-enables the update figure button
setObjEnable(hGUI.buttonUpdateFigure,'on');
pause(0.05);

% UIWAIT makes AnalysisPara wait for user response (see UIRESUME)
% uiwait(handles.figAnalysisPara);

% --- Outputs from this function are returned to the command line.
function varargout = AnalysisPara_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        OBJECT CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%
    
% --- callback function for the time limit parameters --- %
function callbackTimeLimit(hObject,eventdata,handles)
        
% retrieves the parameter struct and the user data
pData = getappdata(handles.figAnalysisPara,'pData');
uData = get(hObject,'UserData');

% if the push-button, then reset the limits and exit the function
if (strcmp(get(hObject,'style'),'pushbutton'))
    % retrieves the limit/values structs
    [Lim,Value] = deal(pData.sP(uData).Lim,pData.sP(uData).Value);
    
    % resets the lower limit values
    Value.Lower = sec2vec(Lim(1)); Value.Lower(end) = 0;                        
    Value.Lower(end) = (Value.Lower(2) >= 12);
    Value.Lower(2) = mod(Value.Lower(2),12);
    resetTimeObj(handles,'Lower',Value.Lower+1)

    % resets the upper limit values
    Value.Upper = sec2vec(Lim(2)); Value.Upper(end) = 0;
    Value.Upper(end) = (Value.Upper(2) >= 12);
    Value.Upper(2) = mod(Value.Upper(2),12);
    resetTimeObj(handles,'Upper',Value.Upper+1)
    
    % updates the parameter struct
    pData.sP(uData).Value = Value;    

    % updates the plot figure
    pData = updatePlotFigure(handles.figAnalysisPara,pData);
    setappdata(handles.figAnalysisPara,'pData',pData);
    return
else
    Lim = pData.sP(uData{2}).Lim;
    Value = pData.sP(uData{2}).Value;
end

% retrieves the new value
Tadd = convertTime(12,'hrs','sec');
nwVal = get(hObject,'Value');
tVec = eval(sprintf('Value.%s',uData{3}));
tVec(uData{1}) = nwVal - 1;

% determines the new time
tNew = vec2sec([tVec(1:3) 0]) + tVec(4)*Tadd;
switch (uData{3})
    case ('Lower')
        % calculates the upper limit
        pp = Value.Upper;
        tHi = vec2sec([pp(1:3) 0]) + pp(4)*convertTime(12,'hrs','sec');
        
        % checks to see if the new value is valid
        if (tNew > tHi) || (tNew < Lim(1)) 
            % outputs an error to screen
            eStr = 'Error! Lower limit is not feasible.';
            waitfor(errordlg(eStr,'Lower Limit Error','modal'))
            
            % resets the previous valid value
            set(hObject,'value',Value.Lower(uData{1})+1)
            return
        else
            % updates the lower limit
            Value.Lower = tVec;
        end
    case ('Upper')
        % calculates the upper limit
        pp = Value.Lower;
        tLo = vec2sec([pp(1:3) 0]) + pp(4)*convertTime(12,'hrs','sec');
        
        % checks to see if the new value is valid
        if (tNew < tLo) || (tNew > Lim(2)) 
            % outputs an error to screen
            eStr = 'Error! Upper limit is not feasible.';
            waitfor(errordlg(eStr,'Upper Limit Error','modal'))
            
            % resets the previous valid value
            set(hObject,'value',Value.Upper(uData{1})+1)
            return
        else
            % updates the lower limit
            Value.Upper = tVec;            
        end        
end

% updates the parameter struct
pData.sP(uData{2}).Value = Value;

% updates the main figure
postParaChange(handles,pData)

% --- callback function for the subplot parameters --- %
function callbackSubPlot(hObject,eventdata,handles)       

% retrieve the new parameter value and the overall parameter struct
hP = handles.panelSubPara;
pData = getappdata(handles.figAnalysisPara,'pData');
uData = get(hObject,'UserData');

% updates the parameter based on the object type
if strcmp(get(hObject,'type'),'uitable')
    % case is updating the plotting output boolean flags
    [ind,Value] = deal(eventdata.Indices(1),pData.sP(uData).Value);

    % updates the data struct
    Value.isPlot(ind) = eventdata.NewData;        
    [Value.nRow,Value.nCol] = detSubplotDim(sum(Value.isPlot));
    pData.sP(uData).Value = Value;      
elseif (strcmp(get(hObject,'style'),'edit'))
    % case is editing the row/column counts
    nwVal = str2double(get(hObject,'string'));
    Value = pData.sP(uData{1}).Value;
    Lim = [1 sum(Value.isPlot)];

    % checks to see if the new value is valid
    if chkEditValue(nwVal,Lim,1)
        % if so, then update the corresponding parameter
        if uData{2} == 2
            Value.nRow = nwVal;
            Value.nCol = ceil(Lim(2)/Value.nRow);
        else
            Value.nCol = nwVal;
            Value.nRow = ceil(Lim(2)/Value.nCol);
        end

        % updates the sub-struct values
        pData.sP(uData{1}).Value = Value;
    else
        % resets the object string to the previous valid value
        if uData{2} == 2
            % case was the row count
            set(hObject,'string',num2str(Value.nRow))
        else
            % case was the column count
            set(hObject,'string',num2str(Value.nCol))
        end
        return
    end
else
    % resets the trace combination flag value
    Value = pData.sP(uData).Value;
    Value.isComb = get(hObject,'value'); 
    pData.sP(uData).Value = Value;

    % resets the hold figure on the main fly analysis GUI
    hGUI = getappdata(handles.figAnalysisPara,'hGUI');      
end

% updates the table based on the new selections
hTable = findobj(get(hObject,'Parent'),'tag','hTable');
set(hTable,'Data',getSubplotTableData(Value))

% resets the object string
[hRow,hCol] = deal(findobj(hP,'tag','nRow'),findobj(hP,'tag','nCol'));
if Value.isComb
    set(setObjEnable(hRow,'off'),'string','1')
    set(setObjEnable(hCol,'off'),'string','1')    
else
    set(setObjEnable(hRow,'on'),'string',num2str(Value.nRow))
    set(setObjEnable(hCol,'on'),'string',num2str(Value.nCol))
end
    
% updates the main figure
postParaChange(handles,pData)

% --- callback function for the stimuli response parameters --- %
function callbackStimResponse(hObject,eventdata,handles)

% retrieve the new parameter value and the overall parameter struct
pData = getappdata(handles.figAnalysisPara,'pData');
hGUI = getappdata(handles.figAnalysisPara,'hGUI');
uData = get(hObject,'UserData');

% resets the userdata based on the storage type
if (iscell(uData)); uData = uData{1}; end

% determines if the table or dropdown menu is being accessed
if (isa(eventdata,'matlab.ui.eventdata.CellEditData'))
    isTable = true;
else
    isTable = isfield(eventdata,'NewData');
end

% updates the parameter data based on the object being updated
if (isTable)
    % case is the data table
    [iRow,iCol] = deal(eventdata.Indices(1),eventdata.Indices(2));

    % updates the plot values
    switch (iCol)
        case (2) % case is setting the fit plotting flag
            pData.sP(uData).Lim.plotTrace(iRow) = eventdata.NewData;
        case (3) % case is setting the fit plotting flag
            pData.sP(uData).Lim.plotFit(iRow) = eventdata.NewData;
    end
else
    % otherwise, case is the dropdown menu
    if (isfield(pData.sP(uData).Lim,'appInd'))
        pData.sP(uData).Lim.appInd = get(hObject,'value');
    else
        pData.sP(uData).Lim = get(hObject,'value');
    end
end
    
% updates the properties/axes based on the function type
if (strcmp(pData.Name,'Multi-Dimensional Scaling'))
    % flag that a recalculation is required
    setappdata(handles.figAnalysisPara,'pData',pData);
    resetRecalcObjProps(hGUI,'Yes')
else
    % updates the main figure
    postParaChange(handles,pData)
end
    
% --- updates the main figure after a parameter change --- %
function postParaChange(handles,pData)

% global parameters
global isDocked

% retrieve the main GUI handles and resets the plot data struct
hGUI = getappdata(handles.figAnalysisPara,'hGUI');
sPara = getappdata(hGUI.figFlyAnalysis,'sPara');
setappdata(handles.figAnalysisPara,'pData',pData);

% disables the listboxes
setObjEnable(hGUI.listPlotFunc,'inactive'); 
setObjEnable(hGUI.popupPlotType,'inactive'); 
setObjEnable(hGUI.popupExptIndex,'inactive'); 

% updates the figure
pData = updatePlotFigure(handles.figAnalysisPara,pData);
if ~isempty(pData)
    setappdata(handles.figAnalysisPara,'pData',pData);
    if ~isDocked
        pData0 = getappdata(hGUI.figFlyAnalysis,'pData');
        [eInd,fInd,pInd] = getSelectedIndices(hGUI);
        pData0{pInd}{fInd,eInd} = pData;
        setappdata(hGUI.figFlyAnalysis,'pData',pData0)
    end
end

% disables the listboxes
setObjEnable(hGUI.listPlotFunc,'on'); 
setObjEnable(hGUI.popupPlotType,'on'); 
setObjEnable(hGUI.popupExptIndex,'on'); 

% determines if there are multiple subplots 
if (size(sPara.pos,1) > 1)   
    % if so, then update the parameter data struct
    sPara.pData{getappdata(hGUI.figFlyAnalysis,'sInd')} = pData;
    setappdata(hGUI.figFlyAnalysis,'sPara',sPara);
end
    
% ------------------------------------------- %
% --- GUI OBJECT INITIALISATION FUNCTIONS --- %
% ------------------------------------------- %        
        
% --- callback function for the numeric parameters --- %
function callbackNumPara(hObject,eventdata,handles)

% retrieve the new parameter value and the overall parameter struct
nwVal = str2double(get(hObject,'String'));
pData = getappdata(handles.figAnalysisPara,'pData');
hGUI = getappdata(handles.figAnalysisPara,'hGUI');

% retrieves the corresponding indices and parameter values
uData = get(hObject,'UserData');
switch (uData{2})
    case ('Calc')
        [Lim,pStr,isPlot] = deal(pData.cP(uData{1}).Lim,'cP',false);
        ValueOld = pData.cP(uData{1}).Value;
    case ('Plot')
        [Lim,pStr,isPlot] = deal(pData.pP(uData{1}).Lim,'pP',true);
        ValueOld = pData.pP(uData{1}).Value;
end
        
% checks to see if the new value is valid
if (chkEditValue(nwVal,Lim(1:2),Lim(3)))
    % if so, then update the parameter struct
    eval(sprintf('pData.%s(uData{1}).Value = nwVal;',pStr))        
    setappdata(handles.figAnalysisPara,'pData',pData);
    
%     % makes the GUI invisible
%     setObjVisibility(handles.figAnalysisPara,'off'); pause(0.05);    
        
    % updates the parameter enabled properties
    p = resetParaEnable(handles.figAnalysisPara,eval(['pData.',pStr]),uData{1});
    
    % updates the parameter struct
    pData = getappdata(handles.figAnalysisPara,'pData');
    eval(sprintf('pData.%s = p;',pStr));
    setappdata(handles.figAnalysisPara,'pData',pData);
    
    % updates the main figure (if altering a plotting parameter)
    if (isPlot)
        % updates the main figure
        postParaChange(handles,pData)
    else        
        resetRecalcObjProps(hGUI,'Yes')
    end    
    
    % updates the data struct
    setappdata(handles.figAnalysisPara,'pData',pData);    
else
    % otherwise, reset the field to the last valid value
    set(hObject,'string',num2str(ValueOld))
end

% --- callback function for the list parameters --- %
function callbackListPara(hObject,eventdata,handles)

% retrieve the new parameter value and the overall parameter struct
nwVal = get(hObject,'Value');
pData = getappdata(handles.figAnalysisPara,'pData');
hGUI = getappdata(handles.figAnalysisPara,'hGUI');

% retrieves the corresponding indices and parameter values
uData = get(hObject,'UserData');
switch (uData{2})
    case ('Calc')
        pData.cP(uData{1}).Value{1} = nwVal;         
        p = pData.cP;
    case ('Plot')
        pData.pP(uData{1}).Value{1} = nwVal;             
        p = pData.pP;
end

% updates the parameter struct
setappdata(handles.figAnalysisPara,'pData',pData);

% updates the parameter enabled properties
p = resetParaEnable(handles.figAnalysisPara,p,uData{1});

% updates the parameter struct
pData = getappdata(handles.figAnalysisPara,'pData');
eval(sprintf('pData.%sP = p;',lower(uData{2}(1))));
setappdata(handles.figAnalysisPara,'pData',pData);

% performs the updates
switch (uData{2})
    case ('Calc')
        resetRecalcObjProps(hGUI,'Yes')
    case ('Plot')
        postParaChange(handles,pData)   
end

% makes sure the analysis parameter GUI is visible again
if strcmp(get(handles.figAnalysisPara,'visible'),'off')
    setObjVisibility(handles.figAnalysisPara,'on'); 
    pause(0.05);
end

% --- callback function for the boolean parameters --- %
function callbackBoolPara(hObject,eventdata,handles)

% retrieve the new parameter value and the overall parameter struct
nwVal = get(hObject,'Value');
pData = getappdata(handles.figAnalysisPara,'pData');
hGUI = getappdata(handles.figAnalysisPara,'hGUI');

% retrieves the corresponding indices and parameter values
uData = get(hObject,'UserData');
switch (uData{2})
    case ('Calc')
        pData.cP(uData{1}).Value = nwVal;
        p = pData.cP;
    case ('Plot')
        pData.pP(uData{1}).Value = nwVal; 
        p = pData.pP;
end

% % makes the GUI invisible
% setObjVisibility(handles.figAnalysisPara,'off'); pause(0.05);

% updates the parameter struct
setappdata(handles.figAnalysisPara,'pData',pData);

% updates the parameter enabled properties
p = resetParaEnable(handles.figAnalysisPara,p,uData{1});

% resets the parameters into the data struct
pData = getappdata(handles.figAnalysisPara,'pData');
eval(sprintf('pData.%sP = p;',lower(uData{2}(1))));
setappdata(handles.figAnalysisPara,'pData',pData);

% performs the updates
switch (uData{2})
    case ('Calc')
        resetRecalcObjProps(hGUI,'Yes')
    case ('Plot')
        postParaChange(handles,pData)   
end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% ------------------------------------------- %
% --- GUI OBJECT INITIALISATION FUNCTIONS --- %
% ------------------------------------------- %

% --- sets up the GUI objects based on the parameter data struct --- %
function pData = setupGUIObjects(handles,varargin)

% global variables
global pOfs hOfs hOfs2 B0 scrSz
hFig = handles.figAnalysisPara;

% retrieves the Analysis GUI handles and the current plot
hGUI = getappdata(hFig,'hGUI');
plotD = getappdata(hGUI.figFlyAnalysis,'plotD');
[eInd,fInd,pInd] = getSelectedIndices(hGUI);

% memory allocation
pData = getappdata(hFig,'pData');
[hObj,hObjF,hTabG] = deal(cell(3,1));
[wMax,nPmx] = deal(zeros(1,3));

% ----------------------------------- %
% --- FUNCTION FIELD OBJECT SETUP --- %
% ----------------------------------- %

% sets the function file fields
set(handles.textFuncName,'string',pData.Func);
resetObjExtent(handles.textFuncName)

% sets the function description fields
set(handles.textFuncDesc,'string',pData.Name);
resetObjExtent(handles.textFuncDesc)

% sets the calculation required string properties
tStr = 'Yes';
if (all([eInd,fInd,pInd] > 0))
    % if there is previous data, then flag the a recalculation is not
    % required
    if (~isempty(plotD{pInd}{fInd,eInd}))
        tStr = 'No';        
    end
end

% initialises the calculation required string
set(handles.textCalcReqd,'string','MOOOOOOOO');
resetObjExtent(handles.textCalcReqd)
resetRecalcObjProps(hGUI,tStr,handles)

% sets the function info field handles
hObjF{1} = {handles.textFuncNameL,handles.textFuncName};
hObjF{2} = {handles.textFuncDescL,handles.textFuncDesc};
hObjF{3} = {handles.textCalcReqdL,handles.textCalcReqd};

% calculates the object widths
wObjF = retObjDimPos(hObjF,3);
wObjFMx = max(cellfun(@(x)(sum(x)+2*pOfs+pOfs/2),wObjF));

% ------------------------------------------ %
% --- CALCULATION/PARAMETER OBJECT SETUP --- %
% ------------------------------------------ %

% creates the calculation/plot parameter fields
[hObj{3},~] = setupParaObjects(handles,'Spec');
[hObj{2},hTabG{2},nPmx(2)] = setupParaObjects(handles,'Plot');
[hObj{1},hTabG{1},nPmx(1)] = setupParaObjects(handles,'Calc');
hasTab = ~cellfun(@isempty,hTabG);

% retrieves the GUI object width dimensions
wObj = cellfun(@(x)(retObjDimPos(x,3)),hObj(1:2),'un',0);

% determines the maximum object widths over all objects/types
for i = 1:2
    for j = 1:length(hObj{i})
        if (length(hObj{i}{j}) == 1)
            % case is a boolean parameter
            wMax(3) = max(wMax(3),wObj{i}{j});
        else
            % case is a numeric/list parameter
            if (~isempty(wObj{i}{j}))
                wMax(1:2) = max(wMax(1:2),wObj{i}{j}+20*hasTab(i));                        
            end
        end
    end
end

% determines the overall maximum 
wObjMx = max(sum(wMax(1:2))+pOfs/2,wMax(3)) + 2*pOfs;
if (wObjFMx > wObjMx)
    % the function information fields are longer
    wObjNw = wObjFMx;
    wMax(2) = (wObjNw - ((5/2)*pOfs + wMax(1)));
else
    % the calculation/plotting parameter fields are longer
    wObjNw = wObjMx;
end

% --------------------------------- %
% --- PANEL HEIGHT CALCULATIONS --- %
% --------------------------------- %

% sets the calculation/plotting parameter sizes
HObj = zeros(2,1);
for i = 1:2
    if (isempty(hObj{i}))
         if i == 1
            % deletes the time panel
            setObjVisibility(handles.panelCalcPara,'off');
        else
            % deletes the subplot panel
            setObjVisibility(handles.panelPlotPara,'off');            
        end
    else
        HObj(i) = nPmx(i)*hOfs+4*pOfs;
    end
end

% sets the calculation/plotting parameters sizes
HObjS = zeros(length(pData.sP),1);
if isempty(hObj{3})
    % if not set up, then delete the time/subplot panels
    setObjVisibility(handles.panelTimePara,'off');
    setObjVisibility(handles.panelSubPara,'off'); 
    setObjVisibility(handles.panelStimResPara,'off'); 
else
    for i = 1:length(hObj{3})    
        if (isempty(hObj{3}{i}))                
            switch (i)
                case (1) % deletes the time panel
                    setObjVisibility(handles.panelTimePara,'off'); 
                    hPosNw = get(handles.panelTimePara,'position');
                    resetObjPos(handles.panelSubPara,'bottom',-(pOfs+hPosNw(4)),1);
                case (2) % deletes the subplot panel
                    setObjVisibility(handles.panelSubPara,'off');             
                case (3) % deletes the subplot panel
                    setObjVisibility(handles.panelStimResPara,'off');                                 
            end
        else
            % retrieves the first valid handle from the cell array
            i0 = find(cellfun(@length,hObj{3}{i})>0,1,'first');
            if (~isempty(i0))
                if (iscell(hObj{3}{i}{i0}{1}))
                    hh = hObj{3}{i}{i0}{1}{1};
                else
                    hh = hObj{3}{i}{i0}{1};
                end

                % retrieves the parent panel position and sets the new height
                hPosNw = get(get(hh,'parent'),'position');
                HObjS(i) = hPosNw(4) + pOfs;
            else
                switch (i)
                    case (1) % deletes the time panel
                        setObjVisibility(handles.panelTimePara,'off');                         
                    case (2) % deletes the subplot panel
                        setObjVisibility(handles.panelSubPara,'off');     
                    case (3) % deletes the subplot panel
                        setObjVisibility(handles.panelStimResPara,'off');                                                         
                end
            end
        end
    end
end
    
% ---------------------------- %
% --- PANEL RE-POSITIONING --- %
% ---------------------------- %

% parameters
[hTabOfs,dhTabOfs] = deal(35,10);

% table gap offset (fudge factor to make table look nice...)
if (ispc); tOfs = 2; else tOfs = 4; end

% resets the figure height/bottom coordinates
[fPos,yNew] = deal(get(hFig,'Position'),pOfs);
Hfunc = 3*hOfs2 + (3/2)*pOfs;
Hfig = (Hfunc + 2*pOfs) + (sum(HObjS)+sum(HObj)) + sum(hasTab)*hTabOfs;
                 
% recalculates the figure bottom location
if (fPos(2) < B0)        
    bNew = B0;
elseif (fPos(2) > (scrSz(4)-(Hfig+B0)))
    bNew = (scrSz(4)-(Hfig+B0));
else
    bNew = fPos(2);
end

% resets the figure position
resetObjPos(hFig,'height',Hfig) 
resetObjPos(hFig,'bottom',bNew)

% --- TIME LIMIT PANEL --- %
% ------------------------ %

% resets the time limit panel width
if (pData.hasTime)    
    % resets the panel position
    hObjNw = hObj{3}{1};
    resetObjPos(handles.panelTimePara,'width',wObjNw)
    yNew = yNew + HObjS(1);          
    
    % sets the object width and the new left location
    Wobj = roundP((wObjNw - (7/2)*pOfs)/4,1);
    L0 = (wObjNw - 4*Wobj) - (5/2)*pOfs;
    
    % resets the button position
    bPos = get(hObjNw{1}{3}{2},'position');
    resetObjPos(hObjNw{1}{3}{2},'left',(wObjNw-pOfs)-(bPos(3)+2*pOfs))        
    resetObjPos(hObjNw{1}{3}{2},'width',bPos(3)+2*pOfs)        
    
    % updates the object positions
    for i = 1:length(hObjNw{1}{1})
        for j = 1:2        
            % resets the popupmenu object position
            resetObjPos(hObjNw{j}{1}{i},'Left',L0);
            resetObjPos(hObjNw{j}{1}{i},'Width',Wobj);

            % resets the text header object position
            resetObjPos(hObjNw{j}{2}{i},'Left',L0);
            resetObjPos(hObjNw{j}{2}{i},'Width',Wobj);        
        end
        
        % resets the left location
        L0 = L0 + ((1/2)*pOfs + Wobj);        
    end
end

% --- SUBPLOT PARAMETER PANEL --- %
% ------------------------------- %

% resets the subplot parameter panel width
if (pData.hasSP)    
    % calculates the text/popup box widths
    hObjNw = hObj{3}{2};
    WTab = (wObjNw - 2*pOfs);            
    wTab = roundP(WTab/6,1);
    
    if (pData.hasRC)
        colWid = num2cell([(WTab-3.5*wTab-tOfs) wTab wTab 1.5*wTab]);
    else
        colWid = num2cell([(WTab-2*wTab-tOfs) 2*wTab]);
    end
        
    % updates the table properties
    resetObjPos(hObjNw{1}{1},'width',WTab)
    set(hObjNw{1}{1},'ColumnWidth',colWid);    
    resetObjPos(handles.panelSubPara,'width',wObjNw)
    resetObjPos(handles.panelSubPara,'bottom',yNew)
    yNew = yNew + HObjS(2); 
    
    % calculates the row/column horizontal offset
    if (pData.hasRC)
        lObj = cell2mat(retObjDimPos(hObjNw(2:3),1)');       
        wObj = cell2mat(retObjDimPos(hObjNw(2:3),3)');    
        wObjOfs = roundP((wObjNw - sum(wObj))/2,1) - 2*lObj(1);                           

        % resets the panel/object positions    )    
        for i = 2:3
            for j = 1:length(hObjNw{i})
                resetObjPos(hObjNw{i}{j},'Left',lObj((i-2)*2+j)+wObjOfs)
            end
        end                 
    end
end

% --- STIMULI RESPONSE PARAMETER PANEL --- %
% ---------------------------------------- %

% resets the subplot parameter panel width
if (pData.hasSR && ~isempty(hObj{3}{3}))    
    % sets the column width offset
    hObjNw = hObj{3}{3};
    if (~isempty(hObjNw{1}))
        nRow = size(get(hObjNw{1}{1},'Data'),1);
        wOfs = (17+20*ismac)*(nRow>10) + 2;

        % sets the stimuli response type
        if (isstruct(pData.sP(3).Lim))
            pType = pData.sP(3).Lim.type;
        else
            pType = pData.sP(3).Lim;
        end    

        % calculates the text/popup box widths    
        [WTab,wTabL,updateStruct] = deal(wObjNw - 2*pOfs,70,false);            
        switch (pType)
            case {0,2} % case is the double column table
                % sets the table column widths
                colWid = num2cell([(WTab-1.5*wTabL-(tOfs-2))-wOfs 1.5*wTabL]);    

                % sets the new data struct
                if (pType == 0)
                    updateStruct = true;
                    [a,b] = deal(true(nRow,1));
                else
                    if (isstruct(pData.sP(3).Lim))
                        % resets the metric boolean flags from last time
                        a = pData.sP(3).Lim.plotTrace;
                        b = pData.sP(3).Lim.plotFit;
                    else
                        % otherwise, initialise new values
                        updateStruct = true;
                        [a,b] = deal(true(nRow,1));
                    end
                end
            case (1) % case is the triple column table
                % sets the table column widths
                colWid = num2cell([(WTab-2*wTabL-(tOfs-2))-wOfs wTabL wTabL]);    
                if (isstruct(pData.sP(3).Lim))
                    nRowPr = length(pData.sP(3).Lim.plotTrace);
                else
                    nRowPr = -1;
                end

                % sets the new data struct
                if (nRow == nRowPr)
                    % resets the metric boolean flags from last time
                    a = pData.sP(3).Lim.plotTrace;
                    b = pData.sP(3).Lim.plotFit;
                else          
                    updateStruct = true;
                    [a,b] = deal([true;false(nRow-1,1)],false(nRow,1));                        
                end
        end

        % resets the plot trace/fit data
        if (updateStruct)
            pData.sP(3).Lim = struct('plotTrace',a,'plotFit',b,...
                                     'appInd',1,'type',pType);            
        end
                 
        % updates the plotting data struct
        setappdata(hFig,'pData',pData)  
        
        % updates the table properties
        resetObjPos(hObjNw{1}{1},'width',WTab)
        set(hObjNw{1}{1},'ColumnWidth',colWid); 
        autoResizeTableColumns(hObjNw{1}{1})
    end
    
    % updates the popup menu (if it exists)
    if (length(hObjNw) > 1)
        txtPos = get(hObjNw{2}{1},'position');
        resetObjPos(hObjNw{2}{2},'left',sum(txtPos([1 3]))+pOfs)
    end
    
    % resets the panel dimensions
    resetObjPos(handles.panelStimResPara,'width',wObjNw)
    resetObjPos(handles.panelStimResPara,'bottom',yNew)        
    yNew = yNew + HObjS(3);     
end

% --- PLOTTING PARAMETER PANEL --- %
% -------------------------------- %

% resets the plot parameters panel  
if (HObj(2) > 0)
    % sets the new locations
    HNew = nPmx(2)*hOfs+3*pOfs+hTabOfs*(~isempty(hTabG{2}));    
    
    % resets the panel position
    resetObjPos(handles.panelPlotPara,'bottom',yNew)
    resetObjPos(handles.panelPlotPara,'width',wObjNw)
    resetObjPos(handles.panelPlotPara,'height',HNew)    
    
    % resets the tab group position
    if (hasTab(2))
        resetObjPos(hTabG{2},'height',HNew-(hTabOfs-dhTabOfs))  
    end
        
    % increment the vertical offset
    yNew = yNew + (HNew+pOfs);    
end

% --- CALCULATION PARAMETER PANEL --- %
% ----------------------------------- %

% resets the plot parameters panel  
if (HObj(1) > 0)
    % sets the new locations
    HNew = nPmx(1)*hOfs+3*pOfs+hTabOfs*(~isempty(hTabG{1}));   
    
    % resets the panel position
    resetObjPos(handles.panelCalcPara,'bottom',yNew)
    resetObjPos(handles.panelCalcPara,'width',wObjNw)
    resetObjPos(handles.panelCalcPara,'height',HNew)
    
    % resets the tab group position
    if (hasTab(1))
        resetObjPos(hTabG{1},'height',HNew-(hTabOfs-dhTabOfs))  
    end
    
    % increment the vertical offset
    yNew = yNew + (HNew+pOfs);    
end

% --- FUNCTION INFORMATION PANEL --- %
% ---------------------------------- %

% resets the function parameters panel
resetObjPos(handles.panelFuncInfo,'bottom',yNew)
resetObjPos(handles.panelFuncInfo,'width',wObjNw)

% --------------------------------- %
% --- GUI OBJECT RE-POSITIONING --- %
% --------------------------------- %

% sets the new left/right
[W1,W2] = deal(wMax(1),wMax(2));
[L1,L2] = deal(pOfs,(3/2)*pOfs+W1);

% updates the locations of the non-boolean parameters
for i = 1:2
    for j = 1:length(hObj{i})
        if (length(hObj{i}{j}) == 2)
            % resets the 1st objects location
            resetObjPos(hObj{i}{j}{1},'left',L1)
            resetObjPos(hObj{i}{j}{1},'width',W1)

            % resets the 2nd objects location
            resetObjPos(hObj{i}{j}{2},'left',L2)
            resetObjPos(hObj{i}{j}{2},'width',W2-20*hasTab(i))        
        end
    end
    
    if hasTab(i)
        resetObjPos(hTabG{i},'width',wObjNw-10);
    end
end

% resets the figure width
if nargin == 1
    setObjVisibility(handles.figAnalysisPara,'on')
end

% resets the figure dimensions
resetObjPos(hFig,'height',Hfig) 
resetObjPos(hFig,'width',2*pOfs + wObjNw)
resetObjPos(hFig,'bottom',bNew)

% updates enabled properties for all the objects (if they need altering)
for j = 1:2
    % sets the sub-struct based on the type
    switch (j)
        case (1) % case is the calculation parameters
            p = pData.cP;
        case (2) % case is the plotting parameters
            p = pData.pP;
    end
    
    % sets the enabled properties for all the objects
    for i = 1:length(p)
        if ~isempty(p(i).Enable)                        
            if iscell(p(i).Enable{1})
                % retrieves the current parameter value
                if strcmp(p(i).Type,'List')
                    % case is a list parameter
                    Value = p(i).Value{1};
                else
                    % case is the other parameters
                    Value = p(i).Value;
                end
                
                % updates the special parameter panel objects
                [pStr,offInd,isOn] = deal(p(i).Enable{1},p(i).Enable{2},[]);
                cellfun(@(x,y)(setSpecialPanelProps(...
                                        hFig,x,y,Value)),pStr,offInd);
                                
            elseif all(p(i).Enable{1} == 0)
                [pVal,onInd] = deal(p(i).Enable{1},p(i).Enable{2}); 
                isOn = any(pVal == onInd);
                
            else
                % sets the parameter indices and enabled strings
                [pInd,onInd,isOn] = deal(p(i).Enable{1},p(i).Enable{2},true);    
                [Type,Value] = field2cell(p(pInd),{'Type','Value'});
                hObjP = cellfun(@(x)(findall(hFig,'tag',x)),...
                                    field2cell(p(pInd),'Para'),'un',0);

                % sets the enabled indices (if provided)
                if (length(p(i).Enable) == 2)
                    enInd = true(size(pInd));
                else
                    enInd = p(i).Enable{3};
                end                
                
                % if the parameter index matches that being changed, then
                % update the enabled properties of the objects 
                for k = 1:length(Type)
                    switch (Type{k})
                        case ('List') % case is a list parameter 
                            if (iscell(Value{k}))
                                pVal = Value{k}{1};
                            else
                                pVal = Value{k};
                            end
                        case ('Boolean') % case is a boolean parameter
                            pVal = Value{k} + 1;
                    end
                    
                    % sets the indices to check
                    if iscell(onInd)
                        % index array is a cell array
                        onIndNw = onInd{k};
                    else
                        % index array is a numerical array
                        onIndNw = onInd;
                    end
                    
                    % sets the new enabled flag
                    if strcmp(get(hObjP{k},'enable'),'on')                
                        isOn = isOn && any(pVal == onIndNw);
                        
                    elseif enInd(k)
                        isOn = false;
                        
                    end   

                    % if not on, then exit the loop
                    if ~isOn; break; end                    
                end
            end

            % sets the enabled properties 
            if ~isempty(isOn)
                hObj = findall(hFig,'Tag',p(i).Para);
                hText = findall(hFig,'String',[p(i).Name,': ']);
                setObjEnable([hObj;hText],isOn);                          
            end
        end
    end
    
    % updates the tab enabled properties
    if (~isempty(hTabG{j}))
        updateTabEnabledProps(hTabG{j});              
    end
end

% --- sets up the parameter GUI objects --- %
function [hObj,hTabG,nPmx] = setupParaObjects(handles,type)

% global variables
global pOfs hOfs hOfs2 tDay nTabMax
hFig = handles.figAnalysisPara;

% retrieves the total solution data struct
hGUI = getappdata(handles.figAnalysisPara,'hGUI');
snTotT = getappdata(hGUI.figFlyAnalysis,'snTot');
[eInd,~,pInd] = getSelectedIndices(hGUI);

% retrieves the parameter struct
pData = getappdata(hFig,'pData');
[dX,dY,dY0,nPmx,hTabG] = deal(5,3,15,0,[]);

% sets the panel handles and parameter struct
switch type
    case ('Calc') % case is 
        [hPanel0,p] = deal(handles.panelCalcPara,pData.cP);        
    case ('Plot') % case is plotting parameters
        [hPanel0,p] = deal(handles.panelPlotPara,pData.pP);        
    case ('Spec') % case is plotting parameters
        [p,yOfs] = deal(pData.sP,pOfs);        
end

% memory allocation
nPara = length(p); hObj = cell(nPara,1);
if (nPara == 0)
    return
else    
    if (strcmp(type,'Spec'))
        ind = (1:nPara)';
    else
        tStr = field2cell(p,'Tab');        
        [tStrU,~,C] = unique(tStr);
        if (isempty(tStrU{1})); tStrU{1} = '1 - General'; end
        
        tInd = cellfun(@(x)(find(C == x)),num2cell(1:length(tStrU)),'un',0);
        ind = combineNumericCells(cellfun(@(x)(x(end:-1:1)),tInd,'un',0));                
    end
end
    
% sets the maximum number of parameters
[nPmx,nTab] = size(ind);

%
iType = strcmp(type,'Calc') + 2*strcmp(type,'Plot');
if (iType > 0)
    % sets the initial tab position vector
    pPos = get(hPanel0,'Position');
    tPos = [dX,dY,pPos(3)-2*dX,pPos(4)-(2*dY+dY0)];   
    
    % creates the master tab group and sets the properties
    hTabG = findall(hPanel0,'type','uitabgroup');
    if isempty(hTabG)
        % if the tab group does not exist, create a new one
        if (isempty(hTabG))
            hTabG = createTabPanelGroup(hPanel0,1);
            set(hTabG,'tag',sprintf('tab%s',type),'Position',tPos)           
        end
        
        % 
        hTab = getappdata(hFig,'hTab');
        if isempty(hTab); hTab = cell(1,2); end
        
        % memory allocation
        [hTabP,N,i0] = deal(cell(nTabMax,1),nTabMax,1);
        
        % creates the new tab panels                                    
        for j = i0:N
            hTabP{j} = createNewTabPanel(hTabG,1,'UserData',j);  
        end        
             
        % updates the tab object array
        hTab{iType} = hTabP;
        setappdata(hFig,'hTab',hTab)    
    else
        set(hTabG,'Position',tPos) 
        hTab = getappdata(hFig,'hTab');        
        hTabP = hTab{iType};                
    end     
    
    % sets the tab panel visibility properties
    cellfun(@(x)(set(x,'Parent',hTabG)),hTabP(1:nTab))
    cellfun(@(x)(set(x,'Parent',[])),hTabP((nTab+1):nTabMax))        
end

% creates the required parameter fields over all tabs
for j = 1:nTab
    % determines the last parameter in the list
    indF = find(~isnan(ind(:,j)),1,'last');
    if (~isempty(hTabG))
        set(hTabP{j},'Title',tStrU{j}(5:end))
    end
    
    % creates the parameters for the current list
    for k = 1:indF        
        % retrieves the parameter struct fields
        i = ind(k,j);
        [Name,Value] = deal(p(i).Name,p(i).Value);
        figPos = get(hFig,'position');

        % ----------------------------- %
        % --- SPECIALITY PARAMETERS --- %
        % ----------------------------- %        

        % creates the objects for all of the parameters in the group
        if (strcmp(p(i).Type,'Time'))   
            % --- START/FINISH TIME MARKER PARAMETERS --- %

            % sets the callback function handle
            cbFcn = @(hObj,e)AnalysisPara('callbackTimeLimit',hObj,e,handles);              

            % case is the lower/upper time limit parameters        
            if (isempty(hObj{1}))            
                % sets the lower time limit objects
                [hPanel,hObj{1}] = deal(handles.panelTimePara,cell(2,1));
                hObj{1}{1} = createTimeLimitObj(hPanel,Value,'Lower',cbFcn,i);            
                hObj{1}{2} = createTimeLimitObj(hPanel,Value,'Upper',cbFcn,i);                        

                pPos = get(hPanel,'position');
                HNew = 2*(2*hOfs2 + hOfs + pOfs) + pOfs/2;   
                yOfs = yOfs + HNew;

                % resets the panel location
                resetObjPos(hFig,'height',figPos(4)+(HNew-pPos(4)))
                resetObjPos(hPanel,'height',HNew);
                resetObjPos(hPanel,'bottom',pOfs);            
            end                        

        elseif (strcmp(p(i).Type,'Subplot'))   
            % --- SUBPLOT SELECTION TABLE PARAMETERS --- %

            % sets the callback function handle
            cbFcn = @(hObj,e)AnalysisPara('callbackSubPlot',hObj,e,handles);         

            % case is the subplot parameters          
            if (isempty(hObj{2}))
                % memory allocation
                [hPanel,hObj{2}] = deal(handles.panelSubPara,cell(3,1));
                nApp = length(Value.isPlot); 

                % determines if the can combine trace flag is set
                if (Value.canComb)                
                    % if so, create the check box and set the offset value
                    [hObj{2},cOfs] = deal(cell(4,1),hOfs);
                    hObj{2}{4}{1} = createNewObj(hPanel,pOfs,'CheckBox',...
                                    'Combine All Traces Into Single Figure',...
                                    Value.isComb);
                    set(hObj{2}{4}{1},'callback',cbFcn,'UserData',i);
                else
                    % otherwise, set the offset value to zero
                    [hObj{2},cOfs] = deal(cell(3,1),0);
                end                                    

                % calculates the new subplot panel height dimension
                pPos = get(hPanel,'position');
                Htab = calcTableHeight(nApp,0,Value.hasRC);% - (~Value.hasRC)*nApp; 
                Hnew = Htab + 2*pOfs + cOfs;                               
                if (Value.hasRC)                    
                    % sets up the row parameters
                    hObj{2}{2}{1} = createNewObj(hPanel,Hnew,'Text','# Rows');
                    hObj{2}{2}{2} = createNewObj(hPanel,Hnew,'Edit',num2str(Value.nRow));

                    % sets up the column parameters
                    hObj{2}{3}{1} = createNewObj(hPanel,Hnew,'Text','# Column');
                    hObj{2}{3}{2} = createNewObj(hPanel,Hnew,'Edit',num2str(Value.nCol));            

                    % accounts for the new 
                    Hnew = Hnew + pOfs + hOfs;
                end                                    

                if (Value.hasRC)
                    colNames = {'Name','Row','Col','Include?'};
                    colForm = {'char','char','char','logical'};
                    colEdit = [false(1,3) true];                                   
                else
                    colNames = {'Name','Include?'};
                    colForm = {'char','logical'};
                    colEdit = [false true];
                    Htab = Htab + nApp;
                end

                % creates the table            
                tStr = {'nRow','nCol'};
                tabPos = [pOfs (pOfs + cOfs) 200 Htab];
                fSize = 11;            

                % creates the table object
                hObj{2}{1}{1} = uitable(hPanel,'Position',tabPos,...
                            'ColumnName',colNames,'ColumnFormat',colForm,...
                            'ColumnEditable',colEdit,'RowName',[],...
                            'CellEditCallback',cbFcn,'UserData',i,...
                            'Data',getSubplotTableData(Value),'tag','hTable',...
                            'FontUnits','pixels','FontSize',fSize);                                
                autoResizeTableColumns(hObj{2}{1}{1})

                % resets the object widths of the row/column counts
                if (Value.hasRC) 
                    L0 = pOfs; 
                    for l = 2:3
                        % resets the editbox width
                        set(hObj{2}{l}{2},'Callback',cbFcn,'UserData',{i,l},'tag',tStr{l-1})
                        resetObjPos(hObj{2}{l}{2},'Width',50);

                        % resets the left 
                        for kk = 1:2                    
                            % resets the object's left location
                            resetObjPos(hObj{2}{l}{kk},'Left',L0);

                            % calculates the new left location for the next object
                            objPos = get(hObj{2}{l}{kk},'position');
                            L0 = L0 + (objPos(3) + pOfs/2);
                        end
                    end
                end

                % resets the panel location
                resetObjPos(hFig,'height',figPos(4)+(Hnew-pPos(4)))
                resetObjPos(hPanel,'height',Hnew);
                resetObjPos(hPanel,'bottom',yOfs);     
                yOfs = yOfs + (pOfs + Hnew);
            end      

        elseif (strcmp(p(i).Type,'Stim'))          
            % --- STIMULI RESPONSE CURVE SELECTION PARAMETERS --- %
        	            
            % sets the callback function handle
            cbFcn = @(hObj,e)AnalysisPara('callbackStimResponse',hObj,e,handles);         
                        
            % case is the subplot parameters          
            if (isempty(hObj{3}))        
                % sets the stimuli response type            
                hPanel = handles.panelStimResPara;                                          

                % determines if the can combine trace flag is set            
                if (((~pData.hasSP) || (pData.hasSR)) && ...
                     ((pData.nApp > 1) && (~strcmp(p(i).Para,'appName'))))
                    % retrieves the solution data struct
                    hGUI = getappdata(hFig,'hGUI'); 
                    snTot = getappdata(hGUI.figFlyAnalysis,'snTot');
                    if (pInd == 3)
                        snTotL = snTot(eInd);                                       
                    else
                        snTotL = reduceSolnAppPara(snTot(eInd));
                    end

                    %
                    if (isstruct(pData.sP(3).Lim))
                        if (isfield(pData.sP(3).Lim,'appInd'))
                            pVal = pData.sP(3).Lim.appInd;
                        else
                            pVal = pData.sP(3).Lim;
                        end
                    else
                        pVal = 1;
                    end

                    % if so, create the check box and set the offset value                
                    [hObj{3},cOfs] = deal(cell(2,1),hOfs);                    
                    lStr = snTotL.iMov.pInfo.gName;
                    if pData.useAll
                        lStr = [lStr;{'All Genotypes'}];
                    end

                    % creates the new objects
                    hObj{3}{2}{1} = createNewObj(hPanel,pOfs,'Text',...
                                    'Currently Viewing');                   
                    hObj{3}{2}{2} = createNewObj(hPanel,pOfs,...
                                    'PopupMenu',lStr,1);
                    
                    set(hObj{3}{2}{1},'tag','hTextS');
                    set(hObj{3}{2}{2},'callback',cbFcn,'UserData',i,...
                                      'Value',pVal,'tag','hPopupS');
                else
                    % otherwise, set the offset value to zero
                    [hObj{3},cOfs] = deal(cell(1,1),0);
                end                                 

                if (isstruct(p(i).Lim))
                    if (isfield(p(i).Lim,'type'))
                        pType = p(i).Lim.type;
                    else
                        pType = 1;
                    end
                else
                    pType = p(i).Lim;
                end               

                % retrieves the matching parameter value      
                if ~isempty(pData.sP(3).Para)
                    pPara = field2cell(pData.cP,'Para');
                    ii = cellfun(@(x)(strcmp(x,p(i).Para)),pPara);
                    if (any(ii))                
                        cP = pData.cP(ii);                
                        if (strcmp(cP.Type,'List'))
                            nNew = str2double(cP.Value{2}{cP.Value{1}});
                        else
                            nNew = cP.Value; 
                        end
                    end

                    % sets the column 
                    switch (p(i).Para)
                        case ('nBin') 
                            % case is the sleep intensity metrics
                            nRow = 60/nNew;          
                            lStr = setTimeBinStrings(nNew,nRow,1);                       
                        case ('nGrp') 
                            % case is the time-grouped stimuli response
                            nRow = nNew;
                            lStr = setTimeGroupStrings(nNew,tDay);                                                    
                        case {'appName','appNameS'}
                            lStr = snTotT(1).iMov.pInfo.gName;
                            if (pInd ~= 3)                            
                                lStr = lStr(snTotT(eInd).iMov.ok);
                            end
                            nRow = length(lStr);
                    end        

                    % calculates the table height
                    nRowNw = min(nRow,10);                
                else                               
                    switch (pType)
                        case {1,3}
                            Hnew = cOfs + 2*pOfs; 
                            nRowNw = 0;
                        case (2)
                            % sets the label strings    
                            lStr = {'Sleep Bouts','Sleep Duration',...
                                    'Avg Bout Duration','Wake Activity',...
                                    'Response Amplitude',...
                                    'Inactivation Time Constant',...
                                    'Pre-Stim Avg Speed',...
                                    'Post-Stim Avg Speed',...
                                    'Pre-/Post-Stim Avg Ratio'}';

                            % retrieves the global parameters
                            hh = getappdata(hFig,'hGUI'); 
                            gPara = getappdata(hh.figFlyAnalysis,'gPara');                            

                            % determines if there are any stimuli events. if
                            % not, then remove the stimuli reponse fields
                            stimP = field2cell(snTotT,'stimP');
                            hasStim = any(~cellfun(@isempty,stimP));
                            if strcmp(gPara.movType,'Midline Crossing') ...
                                                    || ~hasStim 
                                    
                                lStr = lStr(1:4);
                            end

                            % sets the number of table rows
                            [nRowNw,nRow] = deal(length(lStr));
                    end
                end

                % sets the table up depending on the type       
                pPos = get(hPanel,'position');                
                if (nRowNw > 0)
                    Htab = calcTableHeight(nRowNw,0,true); 
                    switch (pType)
                        case (0)
                            colNames = {'Group Name','Show Markers'};
                            colForm = {'char','logical'};
                            colEdit = [false true];         
                            DataNw = num2cell(true(nRow,1)); 
                        case (1)                
                            colNames = {'Group Name','Plot Trace','Plot Fit'};
                            colForm = {'char','logical','logical'};
                            colEdit = [false true(1,2)];                                

                            if (~isstruct(pData.sP(3).Lim))
                                DataNw = num2cell(false(nRow,2));
                                DataNw{1,1} = true;                            
                            else
                                DataNw = num2cell([pData.sP(3).Lim.plotTrace,...
                                                   pData.sP(3).Lim.plotFit]);      

                                if (size(DataNw,1) ~= length(lStr))                                           
                                    DataNw = num2cell(false(nRow,2));
                                    DataNw{1,1} = true;                                                                       
                                end
                            end
                        case (2)
                            colNames = {'Metric Name','Include?'};
                            colForm = {'char','logical'};
                            colEdit = [false true];         
                            DataNw = num2cell(true(nRow,1)); 
                    end

                    % sets the new table height and adds this to the total
                    % figure height
                    if ((cOfs + Htab) == 0)
                        hObj{3} = []; 
                        return
                    else
                        Hnew = Htab + 2*pOfs + cOfs;                 
                    end

                    % sets the table properties
                    if (~isempty(DataNw))
                        tabPos = [pOfs (pOfs + cOfs) 300 Htab];

                        % sets the data array
                        Data = [lStr,DataNw];

                        % creates the table object
                        hObj{3}{1}{1} = uitable(hPanel,'Position',tabPos,...
                                'ColumnName',colNames,'ColumnFormat',colForm,...
                                'ColumnEditable',colEdit,'RowName',[],...
                                'CellEditCallback',cbFcn,...
                                'UserData',i,'Data',Data,'tag','hTable');                      
                            
                        % if the stimuli separated stimuli response panel,
                        % then reset the userdata field
                        if (strcmp(p(i).Para,'appNameS'))
                            [~,nStim] = hasEqualStimProtocol(snTotT);
                            iPlot = false(nStim,2); iPlot(1) = true;
                            sStr = cellfun(@(x)(sprintf('Stimuli #%i',x)),...
                                        num2cell(1:nStim)','un',0);
                            
                            uData = [{i},cell(1,2)];
                            uData{2} = Data;
                            uData{3} = [sStr,num2cell(iPlot)];
                            set(hObj{3}{1}{1},'UserData',uData)
                        end
                    end
                end

                % resets the panel location                
                resetObjPos(hFig,'height',figPos(4)+(Hnew-pPos(4)))
                resetObjPos(hPanel,'height',Hnew);
                resetObjPos(hPanel,'bottom',yOfs);                    
            end
        else

        % --------------------------- %
        % --- ORDINARY PARAMETERS --- %
        % --------------------------- %

            % sets the new height and increments the index
            [yNew,isValid,TTstr] = deal(pOfs+((k-1)+(nPmx-indF))*hOfs-2,true,p(i).TTstr);
            if (~((~isempty(hTabG)) || (strcmp(p(i).Type,'None'))))
                hTab = hPanel0; 
            elseif (exist('hTabP','var'))
                hTab = hTabP{j};
            end
            
            % creates the objects for all of the parameters in the group
            switch (p(i).Type)                                
                case ('Number') % case is a numeric parameter
                    % creates the title and editbox object
                    hObj{i}{1} = createNewObj(hTab,yNew,'Text',Name);
                    hObj{i}{2} = createNewObj(hTab,yNew,'Edit',num2str(Value),[],p(i).Para);            

                    % sets the callback function handle
                    cbFcn = @(hObj,e)AnalysisPara('callbackNumPara',hObj,e,handles);

                case ('List') % case is a list parameter
                    % creates the title and popup-box object
                    hObj{i}{1} = createNewObj(hTab,yNew,'Text',Name);
                    hObj{i}{2} = createNewObj(hTab,yNew,'PopupMenu',Value{2},Value{1},p(i).Para);

                    % sets the callback function handle
                    cbFcn = @(hObj,e)AnalysisPara('callbackListPara',hObj,e,handles);           

                case ('Boolean') % case is a boolean parameter
                    % creates the checkbox object
                    hObj{i}{1} = createNewObj(hTab,yNew,'CheckBox',Name,Value,p(i).Para);

                    % sets the callback function handle
                    cbFcn = @(hObj,e)AnalysisPara('callbackBoolPara',hObj,e,handles);          

                otherwise 
                    isValid = false;
            end

            % if there is a tool-tip string, then add it to the text object
            if (~isempty(TTstr))
                set(hObj{i}{1},'ToolTipString',TTstr)
            end

            % sets the callback function and userdata for the current object
            if (isValid)
                set(hObj{i}{end},'Callback',cbFcn,'UserData',{i,type})        
            end
        end    
    end
end

% --- creates the new ui control object and sets the string/position fields
function hObj = createNewObj(hPanel,yNew,Style,Name,Value,Para)

% global variables
global pOfs
fSize = 12;
[Wmin,fWght] = deal([],'Normal');

% sets the actual object height
switch (Style)
    case {'Text','TextHeader'}
        [H,Wofs,yOfs,fWght] = deal(17,0,0,'bold');
    case ('Edit')
        [H,Wofs,yOfs,Wmin,fSize] = deal(23,2,2,120,11);
    case ('CheckBox')
        [H,Wofs,yOfs,fWght] = deal(23,22,2,'bold');
    case ('PopupMenu')
        [H,Wofs,yOfs,fSize] = deal(23,20+(25*ismac),2,11);        
    case ('PushButton')
        [H,Wofs,yOfs,fWght] = deal(23,3,0,'bold');                
end

% sets the temporary 
yNew = yNew - yOfs;
if (strcmp(Style,'PopupMenu'))
    hTemp = cellfun(@(x)(uicontrol('Style','Text','String',x,'Position',...
                    [pOfs yNew length(x)*10 H])),Name,'un',0);
else
    PosNw = [pOfs yNew length(Name)*10 H];
    
    if (strcmp(Style,'TextHeader'))
        hTemp = {uicontrol('Style','Text','String',Name,'Position',...
                    PosNw,'Parent',hPanel,'HorizontalAlignment','Center')};            
    else
        hTemp = {uicontrol('Style','Text','String',[Name,': '],'Position',...
                    PosNw,'Parent',hPanel,'HorizontalAlignment','Right')}; 
    end
end

% determines the maximum extent width over all the objects
cellfun(@(x)(set(x,'FontUnits','Pixels','FontWeight',fWght,'FontSize',12)),hTemp)
pExt = cellfun(@(x)(get(x,'Extent')),hTemp,'un',0);    
Wnw = max(cellfun(@(x)(x(3)+Wofs),pExt));

% ensures the minimum width is at least Wmin (if the value is set)
if (~isempty(Wmin))
    Wnw = max(Wmin,Wnw);
end

% creates the ui control object
if (strcmp(Style,'Text') || strcmp(Style,'TextHeader'))
    % object is already a text 
    hObj = hTemp{1};
    set(hObj,'Position',[pOfs yNew Wnw H]);
else
    % otherwise, delete the old temporary objects and create the new one
    cellfun(@delete,hTemp)
    hObj = uicontrol('Parent',hPanel,'Style',Style,...
                     'String',Name,'Position',[pOfs yNew Wnw H]);
                        
    % if the value field was provided, then set that as well
    if (nargin >= 5)
        if (~isempty(Value))
            set(hObj,'Value',Value)
        end
    end
end

% sets the other fields
set(hObj,'FontUnits','Pixels','FontWeight',fWght,'FontSize',fSize)
if (nargin == 6); set(hObj,'Tag',Para); end
  
% --- creates time-limit objects --- %
function hObj = createTimeLimitObj(hPanel,Value,Type,cbFcn,ind)

% global variables
global pOfs hOfs hOfs2

% sets the y-offset and parameter fields
hObj = cell(3,1); hObj(1:2) = {cell(1,4)};
switch (Type)
    case ('Lower')
        hObj{3} = cell(1,2);  
        [y0,pNw] = deal((3/2)*pOfs+(2*hOfs2+hOfs),Value.Lower);
        
        hObj{3}{2} = createNewObj(hPanel,(y0+hOfs+hOfs2),...
                                        'PushButton','Reset Limits');
        set(hObj{3}{2},'Callback',cbFcn,'UserData',ind)
    case ('Upper')
        [y0,pNw] = deal(pOfs,Value.Upper);
end

[a,b] = deal(num2cell(0:9)',num2cell(10:59)');
dStr = [cellfun(@(x)(sprintf('0%i',x)),a,'un',false);...
        cellfun(@num2str,b,'un',false)];  

% memory allocation
nDay = Value.Upper(1);
sStr = {'Day','Hours','Mins','AM/PM'};
pStr = {cellfun(@(x)(num2str(x)),num2cell(0:nDay)','un',0);...
        cellfun(@(x)(num2str(x)),num2cell(0:11)','un',0);...
        dStr;{'AM';'PM'}};

% creates the header text object
yNew = y0 + (hOfs + hOfs2);
hObj{3}{1} = createNewObj(hPanel,yNew,'Text',...
                            sprintf('%s TIME LIMIT',upper(Type)));        
    
% creates the popup-menu/header text objects
for i = 1:length(sStr)
    % creates the objects
    hObj{1}{i} = createNewObj(hPanel,y0,'PopupMenu',pStr{i},pNw(i)+1);
    hObj{2}{i} = createNewObj(hPanel,y0+hOfs,'TextHeader',sStr{i});
    
    % sets the popup menu callback function
    set(hObj{1}{i},'Callback',cbFcn,'UserData',{i,ind,Type},'tag',Type)
end   

% --- resets the time limit popup objects values --- %
function resetTimeObj(handles,Type,iVal)

% retrieves the popup object handles and resets their values
hPop = findobj(handles.panelTimePara,'tag',Type);
for i = 1:length(hPop)
    uData = get(hPop(i),'UserData');
    set(hPop(i),'Value',iVal(uData{1}))
end

% --- retrieves the subplot table data (based on the selections) --- %
function Data = getSubplotTableData(Sub)

% if not combining traces, then update the table with the data
if (Sub.hasRC)
    A = repmat({'N/A'},length(Sub.isPlot),2);
    if (~Sub.isComb)
        % determines the new row/column indices
        xi = (1:sum(Sub.isPlot))';
        iRow = (floor((xi-1)/Sub.nCol)+1);
        iCol = (mod((xi-1),Sub.nCol)+1);

        % sets the row/column indices
        A(Sub.isPlot,:) = cellfun(@num2str,num2cell([iRow,iCol]),'un',0);
    end    
else
    % sets the final data struct
    A = [];
end
    
% sets the final data struct
Data = [Sub.Name,A,num2cell(logical(Sub.isPlot))];

% --- initialises the Analysis Parameters GUI --- %
function varargout = initAnalysisGUI(hPara,hGUI,varargin)

% makes the GUI invisible
if nargin == 3
    setObjVisibility(hPara,'off'); pause(0.01);
end

% sets the panels for object removal
hParaH = guidata(hPara);
pStr = {'Calc','Plot','Sub','Time','StimRes'};
kStr = {'uipanel','uitabgroup','uitab'};

% removes all the objects off the specified panels
for i = 1:length(pStr)
    % determines the objects on the panel and removes them
    hPanel = eval(sprintf('hParaH.panel%sPara',pStr{i})); 
    switch (pStr{i})
        case {'Calc','Plot'} % case is the plotting/calculation para            
            hTab = getappdata(hPara,'hTab');
            if (~isempty(hTab))
                % if there are tabs set then remove the items from each tab
                iType = strcmp(pStr{i},'Calc') + 2*strcmp(pStr{i},'Plot');
                hTabP = hTab{iType};
                for j = 1:length(hTabP)
                    hObjNw = findobj(hTabP{j});  
                    if (~isempty(hObjNw))
                        delete(hObjNw(~strcmp(get(hObjNw,'type'),'uitab')))               
                    end
                end
            end
        otherwise % case is the other parameter types
            hObjNw = findobj(hPanel);            
            if (~isempty(hObjNw))    
                % removes any non-panel objects from within the panel
                delete(hObjNw(~strcmp(get(hObjNw,'type'),'uipanel')))               
            end
    end    
    
    % resets the visibility to on
    setObjVisibility(hPanel,'on')
end

% retrieves the experiment/function plot index
pData = getappdata(hGUI.figFlyAnalysis,'pData');
sPara = getappdata(hGUI.figFlyAnalysis,'sPara');

%
[eInd,fInd,pInd] = getSelectedIndices(hGUI);
if (size(sPara.pos,1) == 1)    
    setappdata(hPara,'pData',pData{pInd}{fInd,eInd})
else
    sInd = getappdata(hGUI.figFlyAnalysis,'sInd');
    if (isempty(sPara.pData{sInd}))
        setappdata(hPara,'pData',pData{pInd}{fInd,eInd})
    else
        setappdata(hPara,'pData',sPara.pData{sInd})
    end
end

% initialises the GUI objects
try
    resetGUIObjects(hParaH)
    if (nargin == 3)    
        pData{pInd}{fInd,eInd} = setupGUIObjects(hParaH,1);
    else
        pData{pInd}{fInd,eInd} = setupGUIObjects(hParaH);
    end
    setappdata(hGUI.figFlyAnalysis,'pData',pData)    
catch ME
    % if there was an error, then try running the GUI again
    eStr = 'There was an error initialising the Analysis parameter GUI.';
    waitfor(errordlg(eStr,'GUI Initialisation Error','modal'))
end
    
% returns the parameter data struct
if (nargout == 1)
    varargout{1} = pData{pInd}{fInd,eInd};
end

% --- resets the GUI panel positions --- %
function resetGUIObjects(handles)

% panel left/width dimensions
[L,W,H,H2] = deal(10,315,55,10);

% resets the panel positions
set(handles.panelFuncInfo,'position',[L 200 W 75])
set(handles.panelCalcPara,'position',[L 135 W H])
set(handles.panelPlotPara,'position',[L 70 W H])
set(handles.panelSubPara,'position',[L 50 W H2])
set(handles.panelTimePara,'position',[L 30 W H2])
set(handles.panelStimResPara,'position',[L 10 W H2])

% --- resets the enabled properties of the GUI objects wrt a change in the
%     value of another parameter (i.e., listbox changes)
function p = resetParaEnable(hFig,p,iSel)

% initialsations
hObj = [];

% sets the enables properties
for i = 1:length(p)        
    if ~isempty(p(i).Enable)                      
        % sets the parameter indices and enabled strings
        [pInd,onInd] = deal(p(i).Enable{1},p(i).Enable{2});     
        if (length(p(i).Enable) == 2)
            enInd = true(size(pInd));
        else
            enInd = p(i).Enable{3};
        end           
        
        % if the parameter index matches that being changed, then update
        % the enabled properties of the objects
        if (iscell(pInd))
            % retrieves the current parameter value
            if (strcmp(p(i).Type,'List'))
                % case is a list parameter
                Value = p(i).Value{1};
            else
                % case is the other parameters
                Value = p(i).Value;
            end

            % updates the special parameter panel objects            
            cellfun(@(x,y)(setSpecialPanelProps(hFig,x,y,Value)),pInd,onInd);                                
        elseif (any(pInd == iSel))
            % sets the parameter indices and enabled strings
            isOn = true; 
            [Type,Value] = field2cell(p(pInd),{'Type','Value'});
            hObjP = cellfun(@(x)(findall(hFig,'tag',x)),field2cell(p(pInd),'Para'),'un',0);                  
            
            for k = 1:length(Type)
                % retrieves the current value of the parameter
                switch (Type{k})
                    case ('List') % 
                        if (iscell(Value{k}))
                            pVal = Value{k}{1};
                        else
                            pVal = Value{k};
                        end
                    case ('Boolean') %
                        pVal = Value{k} + 1;
                end
            
                % sets the indices to check
                if (iscell(onInd))
                    % index array is a cell array
                    onIndNw = onInd{k};
                else
                    % index array is a numerical array
                    onIndNw = onInd;
                end

                % sets the new enabled flag
                if strcmp(get(hObjP{k},'enable'),'on')                
                    isOn = isOn && any(pVal == onIndNw);
                    
                elseif enInd(k)
                    isOn = false;
                    
                end   
                
                % if not on, then exit the loop
                if ~isOn; break; end
            end

            % sets the enabled properties 
            hObj = findall(hFig,'Tag',p(i).Para);
            hText = findall(hFig,'String',[p(i).Name,': ']);
            setObjEnable([hObj;hText],isOn);
            
            % if a boolean parameter is being disabled, then also set the
            % checkbox value to false
            if ((~isOn) && (strcmp(p(i).Type,'Boolean')))
                set(hObj,'Value',false)
                p(i).Value = false;
            end                                   
        end
    end
end

% updates the tab enabled properties
if (~isempty(hObj))
    updateTabEnabledProps(hObj); 
end

% --- updates the special panel properties base on type/selection
function setSpecialPanelProps(hFig,pStr,offInd,Value)

% updates the special panel properties for each element in the list
for i = 1:length(pStr)
    % loop initialisation flag    
    [isUpdate,isOff] = deal(true,any(Value == offInd));
    
    % retrieves the objects/performs actions based on type
    switch (pStr{i})
        case ('SR') % case is the stimuli response parameters
            hP = findall(hFig,'tag','panelStimResPara');
        case ('SP') % case is the subplot parameters
            hP = findall(hFig,'tag','panelSubPara');
        case ('SRS') % case is the short stimuli reponse parameters
            [isUpdate,updatePara] = deal(false,true);
            hP = findall(hFig,'tag','panelStimResPara');
            
            % retrieves the table object properties
            hTab = findall(hP,'tag','hTable');
            [Data,uData] = deal(get(hTab,'Data'),get(hTab,'UserData'));
            
            % updates the table fields/userdata based on the selection
            if (isOff)
                uData{2} = Data;                
                set(hTab,'Data',uData{3});
            else
                if (strcmp(Data{1,1},'Stimuli #1'))
                    uData{3} = Data;                
                    set(hTab,'Data',uData{2});
                else
                    updatePara = false;
                end                                
            end
            
            % resets the table user data fields
            set(hTab,'UserData',uData);
            
            % updates the plotting parameter struct
            if (updatePara)
                pData = getappdata(hFig,'pData');
                pData.sP(uData{1}).Lim.plotTrace = cell2mat(uData{2+isOff}(:,2));
                pData.sP(uData{1}).Lim.plotFit = cell2mat(uData{2+isOff}(:,3));
                setappdata(hFig,'pData',pData);
                
                hGUI = getappdata(hFig,'hGUI');
                pData0 = getappdata(hGUI.figFlyAnalysis,'pData');                
                [eInd,fInd,pInd] = getSelectedIndices(hGUI);
                pData0{pInd}{fInd,eInd} = pData;
                setappdata(hGUI.figFlyAnalysis,'pData',pData0)                                
            end
            
            % updates the enabled properties of the other objects
            hObj = [findall(hP,'tag','hPopupS');findall(hP,'tag','hTextS')];
            setObjEnable(hObj,isOff)            
    end

    % updates the panel properties (if not reset above)
    if isUpdate
        setPanelProps(hP,isOff)
    end            
end
