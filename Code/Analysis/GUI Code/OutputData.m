function varargout = OutputData(varargin)
% Last Modified by GUIDE v2.5 24-Jul-2014 19:31:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @OutputData_OpeningFcn, ...
                   'gui_OutputFcn',  @OutputData_OutputFcn, ...
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

% --- Executes just before OutputData is made visible.
function OutputData_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global Tmlt T0 TStr
[Tmlt,TStr] = deal(1,' (sec)');

% Choose default command line output for OutputData
handles.output = hObject;
setObjVisibility(hObject,'off'); 
pause(0.05);

% sets the input arguments
hGUI = varargin{1};
hFig = hGUI.figFlyAnalysis;

% retrieves the data structs from the main GUI
iProg = getappdata(hFig,'iProg');
hPara = getappdata(hFig,'hPara');
plotD = getappdata(hFig,'plotD');
snTot = getappdata(hFig,'snTot');
sName = getappdata(hFig,'sName');

% retrieves the currently stored plot data
pData = feval(getappdata(hPara,'getPlotData'),hPara);

% retrieves the listbox selection indices from the main GUI
T0 = snTot(1).iExpt.Timing.T0;
[eInd,fInd,pInd] = getSelectedIndices(hGUI);

% sets the plot parameter/data structs
plotD = plotD{pInd}{fInd,eInd};
if (pInd ~= 3); sName = sName(eInd); end

% initialises the data struct
iData = initDataStruct(pData);

% sets the data structs into the GUI
setappdata(hObject,'hGUI',hGUI);
setappdata(hObject,'iProg',iProg)
setappdata(hObject,'hPara',hPara)
setappdata(hObject,'pData',pData)  
setappdata(hObject,'plotD',plotD)  
setappdata(hObject,'sName',sName)  
setappdata(hObject,'iData',iData)  

% initialises the GUI objects
if (~initGUIObjects(handles))
    % if no output variables have been specified, then exit the delete the
    % GUI after outputting an error to screen
    eStr = {'Error! No output variables have been specified in the analysis function. ';
            'Update the analysis function so as to be able to output data to file.'};
    waitfor(errordlg(eStr,'Data Output Error','modal'));
    
    % deletes the GUI and exits the function
    delete(hObject)
    return
end

% updates the panel selection
centreFigPosition(hObject);
panelFileType_SelectionChangeFcn(handles.panelFileType, '1', handles)

% Update handles structure and sets the main/parameter GUIs to be invisible
setObjVisibility(hPara,'off')
setObjVisibility(hFig,'off')
guidata(hObject, handles);

% UIWAIT makes OutputData wait for user response (see UIRESUME)
% uiwait(handles.figOutputData);

% --- Outputs from this function are returned to the command line.
function varargout = OutputData_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- callback function for editing the variable names --- %
function callbackEdit(hObject,eventdata,handles)

% resets the output flag
iData = getappdata(handles.figOutputData,'iData');
iData.fName{get(hObject,'UserData')} = get(hObject,'String');
setappdata(handles.figOutputData,'iData',iData)

% --- callback function for editing the variable names --- %
function callbackButton(hObject,eventdata,handles)

% retrieves the data parameter struct
iData = getappdata(handles.figOutputData,'iData');

% updates the GUI based on the group selection type
switch (get(hObject,'string'))
    case ('Previous Group') % case is selecting the previous group
        iData.cInd = iData.cInd - 1;
    case ('Next Group') % case is selecting the next group
        iData.cInd = iData.cInd + 1;
end

% updates the data struct into the GUI
setappdata(handles.figOutputData,'iData',iData);

% makes the GUI invisible
setObjVisibility(handles.figOutputData,'off'); 
pause(0.1);

% deletes all the text/editboxs from the output variable panel
delete(findall(handles.panelOutPara,'tag','textVar'))
delete(findall(handles.panelOutPara,'tag','editVar'))

% re-initialises the GUI objects
initGUIObjects(handles,1);

% makes the GUI visible again
setObjVisibility(handles.figOutputData,'on'); 
pause(0.1);

% --- callback function for editing the apparatus inclusion checks --- %
function callbackRegion(hObject,eventdata,handles)

% checks to see that the indices are valid
if (isempty(eventdata.Indices))
    % they are not, so exit
    return
else
    % otherwise, set the row that was altered
    iSel = eventdata.Indices(1);
end

% resets the output flag
iData = getappdata(handles.figOutputData,'iData');
iData.appOut(iSel) = eventdata.NewData;
setappdata(handles.figOutputData,'iData',iData)

% if there are any apparatus to output, then enable the output button
setObjEnable(handles.buttonOutput,any(iData.appOut))

% --- Executes on selection change in popupTimeFormat.
function popupTimeFormat_Callback(hObject, eventdata, handles)

% global variables
global Tmlt TStr

% sets the time multiplier based on the string type
lStr = get(hObject,'string');
switch lStr{get(hObject,'value')}
    case ('Seconds') % case is the time multiplier is seconds
        Tmlt = 1;
        TStr = ' (sec)';
    case ('Minutes') % case is the time multiplier is minutes
        Tmlt = convertTime(1,'sec','min');
        TStr = ' (min)';
    case ('Hours') % case is the time multiplier is hours
        Tmlt = convertTime(1,'sec','hour');
        TStr = ' (hrs)';
    case ('Days') % case is the time multiplier is days
        Tmlt = convertTime(1,'sec','day');
        TStr = ' (days)';
end

% --- PROGRAM CONTROL BUTTONS --- %
% ------------------------------- %

% --- Executes on button press in buttonOutput.
function buttonOutput_Callback(hObject, eventdata, handles)

% retrieves the data/parameter structs
iProg = getappdata(handles.figOutputData,'iProg');
pData = getappdata(handles.figOutputData,'pData');

% retrieves the file type/extension for output
A = get(get(handles.panelFileType,'SelectedObject'),'string');
fType = A(1:strfind(A,'(')-2);
fExtn = A((strfind(A,'(')+1):(strfind(A,')')-1));

% set output file name
defFile = fullfile(iProg.OutData,[pData.Name,fExtn(2:end)]);
[fName,fDir,fIndex] = uiputfile({fExtn,fType},'Output Analysis Data',defFile);
if (fIndex == 0)
    % if the user cancelled, then exit the function
    return
else
    % sets the file name
    dataName = fullfile(fDir,fName);
end

% determines if there are any radio buttons on the apparatus select panel 
hRadio = findobj(handles.panelAppSelect,'style','radio','value',1);
if (isempty(hRadio))
    % if not, then group the data by apparatus
    isMetGrp = true;
else
    % determines if the appartus grouping button was selected
    isMetGrp = strcmp(get(hRadio,'String'),'Group Data By Metric');
end

% sets the output data arrays values
[Pmat,Pcsv,h,ok] = setupOutputDataStruct(handles,fExtn,isMetGrp);
if (~ok); return; end

% outputs the data to file
switch (fExtn)
    case ('*.mat') % outputs the data to a matlab data file                
        % outputs the data file
        outputMATDataFile(dataName,Pmat)
    case ('*.csv') % outputs the data to a CSV data file         
        % outputs the data file
        if (~writeCSVFile(dataName,Pcsv,h))
            eStr = 'Error! The specified .csv file is either open or corrupt.';
            waitfor(errordlg(eStr,'CSV File Output Error','modal'))
        end
end

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% retrieves the parameter GUI handle
hGUI = getappdata(handles.figOutputData,'hGUI');
hPara = getappdata(handles.figOutputData,'hPara');

% deletes the sub-GUI and makes the parameter GUI visible again
delete(handles.figOutputData)
setObjVisibility(hGUI.figFlyAnalysis,'on')
setObjVisibility(hPara,'on')

% sets the parameter GUI to the top
uistack(hPara,'top');

% --- Executes when selected object is changed in panelFileType.
function panelFileType_SelectionChangeFcn(hObject, eventdata, handles)

% retrieves the apparatus/trace radio button handles
hApp = handles.panelAppSelect;
[hType,hMet] = deal(findall(hApp,'tag','hType'),findall(hApp,'tag','hMet'));

% resets the radio button properties
if isa(eventdata,'char')
    % ensures the output is by apparatus only    
    set(setObjEnable(hMet,'off'),'value',1)
    setObjEnable(hType,'off')   
    
elseif (eventdata.NewValue ~= handles.radioCSV)
    % ensures the output is by apparatus only    
    set(setObjEnable(hMet,'off'),'value',1)
    setObjEnable(hType,'off')  
    
else
    % otherwise, enable the group by trace radio
    setObjEnable(hMet,'on')
    setObjEnable(hType,'on')        
end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% ----------------------------- %
% --- DATA OUTPUT FUNCTIONS --- %
% ----------------------------- %

% --- outputs the data to a Matlab (*.mat) file --- %
function [Pmat,Pcsv,h,ok] = setupOutputDataStruct(handles,fExtn,isMetGrp)

% global variables
global x hasNA Tmlt TStr
[x,hasNA,h,ok] = deal(1e10,false,[],true);

% retrieves the data/parameter structs
iData = getappdata(handles.figOutputData,'iData');
plotD = getappdata(handles.figOutputData,'plotD');
pData = getappdata(handles.figOutputData,'pData');

% resets the output data struct
[pData.oP(:,1),pData.appName] = deal(iData.fName,iData.appName(iData.appOut));
pData.sName = getappdata(handles.figOutputData,'sName');

% determines if there is a time variable in the variable list
isTime = strcmp(pData.oP(:,2),'T');
if (sum(isTime) == 1)
    % if so, then add the duration string to the variable name
    pData.oP{isTime,1} = sprintf('%s%s',pData.oP{isTime,1},TStr);
    
    % incorporates the time multiplier into the time vector
    tStr = pData.oP{isTime,2};
    for i = 1:length(plotD)
        for j = 1:length(plotD{i})
            eval(sprintf('plotD{i}(j).%s = Tmlt*plotD{i}(j).%s;',tStr,tStr))
        end
    end
end

% determines the number of traces that are currently held
if (~iscell(plotD)); plotD = {plotD}; end
nTrace = length(plotD);
[Pmat,PcsvT] = deal(cell(nTrace,1));

% resets the plotting data array
if (length(plotD{1}) == length(iData.appOut))
    plotD = cellfun(@(y)(y(iData.appOut)),plotD,'un',0);
else
    % ensures all the data is orientated in the correct direction
    [fName,nApp] = deal(fieldnames(plotD{1}),length(iData.appOut));
    for i = 1:length(fName)
        % retrieves the values for the current field
        pStr = sprintf('plotD{1}.%s',fName{i});
        Y = eval(pStr);
        
        % determines which dimension matches the apparatus count
        ii = find(size(Y) == nApp);
        if (ii == 1)
            % row dimensions matches apparatus count
            eval(sprintf('%s = Y(iData.appOut,:);',pStr))
        elseif (ii == 2)
            % column dimensions matches apparatus count
            eval(sprintf('%s = Y(:,iData.appOut);',pStr))
        end
    end
end

% special operations based on the function type
switch (pData.Name)
    case {'Population Sleep Metrics','Population Waking Metrics'}
        % case is sleep/waking metrics. prompt user if they wish to daily
        % group the data values
        if (plotD{1}(1).nDayMx > 1)
            uChoice = questdlg('Do you wish to average raw data over all days?',...
                               'Average Raw Data','Yes','No','Cancel','Yes');
        else
            uChoice = 'Yes';
        end
                           
        if (strcmp(uChoice,'Cancel'))
            % if the user cancels, then exit the function
            [Pmat,Pcsv,ok] = deal([],[],false);
            return
        else
            % otherwise, set the flag based on the user choice
            pData.isAvg = strcmp(uChoice,'Yes');            
        end
    otherwise
        % otherwise, set the averaging flag to false
        pData.isAvg = true;
end

% creates a loadbar figure
h = ProgressLoadbar('Preparing Data For Output...');

% calculates the other output data
for i = 1:nTrace        
    [Pmat{i},PcsvT{i}] = feval(pData.oFcn,pData,plotD{i},fExtn,isMetGrp);   
end

% sets final data array
if (strcmp(fExtn,'*.mat'))
    % case is the .mat file
    [Pmat,Pcsv] = deal(cell2mat(Pmat),[]);
else
    % sets the final matlab/csv file data arrays
    Pcsv = PcsvT{1};
    for j = 2:nTrace
        Pcsv = combineCellArrays(combineCellArrays(Pcsv,{NaN}),Pcsv{j});
    end    
        
    % removes all the empty elements and sets all NaN values back to N/A
    Pcsv(cellfun(@isempty,Pcsv)) = {NaN};
    if (hasNA)
        % if any not applicable values, then reset the cell values
        ii = find(cellfun(@isnumeric,Pcsv));
        jj = ii(cellfun(@(y)(y > x),Pcsv(ii)));    
        Pcsv(jj) = {'N/A'};    
    end
end

% --- outputs the data to a Matlab (*.mat) file --- %
function outputMATDataFile(dataName,Pmat)

% sets output file names
[fldNames,pStr] = deal(fieldnames(Pmat),'save(dataName');

% sets the output data string
for i = 1:length(fldNames)
    eval(sprintf('%s = Pmat.%s;',fldNames{i},fldNames{i}));
    pStr = sprintf('%s,''%s''',pStr,fldNames{i});   
end

% saves the data to file
h = ProgBar('Outputting Data To File...','Saving Analysis Data'); 
pause(0.5);
pStr = [pStr,');']; eval(pStr);

% updates and closes the data file
h.Update(1,'Data Output Complete!',1); 
pause(0.5);
h.closeProgBar()

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- initialises the data struct
function iData = initDataStruct(pData)

% retrieves the output data struct
[oP,nApp] = deal(pData.oP,length(pData.appName));

% initialises the output data struct
iData = struct('fName',[],'pStr',[],'appOut',[],'appName',[],...
               'nOut',[],'cInd',1);

% sets the field names and strings
[iData.fName,iData.pStr] = deal(oP(:,1),oP(:,2));
[iData.appOut,iData.appName] = deal(true(nApp,1),pData.appName);

% --- updates the variable group selection buttons
function updateButtonSelection(hBut,iData)

% initialisations
eStr = {'off','on'};
    
% updates the button enabled properties
setObjEnable(hBut{1},iData.cInd>1)
setObjEnable(hBut{2},iData.cInd<length(iData.nOut))

% --- initialises the GUI objects --- %
function ok = initGUIObjects(handles,varargin)

% sets the GUI object handles
hFig = handles.figOutputData;
hPanel = handles.panelOutPara;
hApp = handles.panelAppSelect;

% retrieves the parameter data struct
pData = getappdata(handles.figOutputData,'pData');
iData = getappdata(handles.figOutputData,'iData');

% initialisations
[ok,incSep,nOutMax,iOfs] = deal(true,nargin>1,20,0);

% sets the parameter counter/offset based on the num
if (nargin == 1)
    nOut = length(iData.fName);
    if (nOut > nOutMax)       
        % separates the parameters into equal sized groups
        N = ceil(nOut/nOutMax); NN = ceil(nOut/N);
        
        % sets the output indices
        iData.nOut = NN*ones(1,N);
        [iData.nOut(end),iData.cInd] = deal(nOut-sum(iData.nOut(1:end-1)),1);
        setappdata(handles.figOutputData,'iData',iData);
        
        % sets the new parameter count and output indices       
        [incSep,nOut] = deal(true,iData.nOut(1));
    end
else
    nOut = iData.nOut(iData.cInd);
    if (iData.cInd > 1)
        iOfs = sum(iData.nOut(1:(iData.cInd-1)));
    end
end

% sets the parameter indices to be included
pInd = (1:nOut) + iOfs;

% if there are no parameters set, then exit the function
if (nOut == 0)
    ok = false; return
end

% ------------------------------------------------- %
% --- PARAMETER CHECKBOX/EDITBOX INITIALISATION --- %
% ------------------------------------------------- %

% object base dimensions
[Hedit,Hchk,Htxt,Hbut] = deal(23,17,17,25);
[dX,dY,pOfs] = deal(10,[10,25,5],10);
[yOfs0,yOfs1,yOfsT] = deal(20,10,incSep*Hbut);

% determines if the time vector is a component of the output data
if (~any(cellfun(@(x)(strcmp(x,'T')),pData.oP(:,2))) && (nargin == 1))
    % if not then remove it
    pPos = get(handles.panelTimeFormat,'position');
    resetObjPos(hFig,'height',-(pPos(4)+dY(1)),1);
    delete(handles.panelTimeFormat);    
    
    % resets the positions of the other objects
    hPP = [findobj(hFig,'type','uipanel');...
           findobj(hFig,'type','uibuttongroup')];
    for i = 1:length(hPP)
        resetObjPos(hPP(i),'bottom',-(pPos(4)+dY(1)),1);
    end
end

% resets the panel dimensions to account for the new variables
pPos = get(hPanel,'position');
Hpanel = nOut*dY(2)+(dY(1)+dY(3))+(yOfs0+yOfsT);
resetObjPos(hPanel,'height',Hpanel);
resetObjPos(hFig,'height',Hpanel-pPos(4),1);

% --- TEXTBOX INITIALISATION --- %
% ------------------------------ %    

% memory allocation
hTxt = cell(nOut,1);

% creates the textbox objects for all the output parameter fields
for j = nOut:-1:1    
    % sets the vertical offset
    i = (nOut-j)+1;
    [k,yOfs] = deal(pInd(i),dY(1) + (j-1)*dY(2) + yOfsT);
    
    % creates the checkbox object
    txtPos = [dX(1) (yOfs+2) 10*Htxt Htxt];
    hTxt{i} = uicontrol('Style','Text','String',sprintf('%s:',iData.pStr{k}),...
                     'Position',txtPos ,'Parent',hPanel,...
                     'HorizontalAlignment','right','FontUnits','pixels',...
                     'FontWeight','bold','FontSize',12,'tag','textVar');   
end
                 
% resets the text object locations
pExt = cell2mat(cellfun(@(x)(get(x,'Extent')),hTxt,'un',0));
resetObjPos(hTxt,'width',max(pExt(:,3)));

% recalculates the editbox widths
dX(2) = dX(1) + (max(pExt(:,3)) + yOfs/2);
Wedit = pPos(3) - (pOfs*3/2 + dX(2));

% for each of the output variables, initialise the checkbox/editbox
% object combinations
for j = nOut:-1:1
    % sets the vertical offset
    i = (nOut-j)+1;
    [k,yOfs] = deal(pInd(i),dY(1) + (j-1)*dY(2) + yOfsT);
    
    % --- EDITBOX INITIALISATION --- %
    % ------------------------------ %
    
    % creates the checkbox object
    editPos = [dX(2) yOfs Wedit Hedit];
    hEdit = uicontrol('Style','Edit','String',iData.fName{k},...
                      'Position',editPos,'Parent',hPanel,'tag','editVar'); 
    
    % sets the callback function handle
    editFcn = @(hObj,e)OutputData('callbackEdit',hObj,e,handles);                  
    set(hEdit,'callback',editFcn,'UserData',k)                  
end

% include the group separation buttons (if required)
if (incSep)
    Wbut = (pPos(3)-3*dX(1))/2;
    Bpos = {[dX(1) dY(3) Wbut Hbut],[(2*dX(1)+Wbut) dY(3) Wbut Hbut]};
    Btxt = {'Previous Group','Next Group'};
    butFcn = @(hObj,e)OutputData('callbackButton',hObj,e,handles); 
    hBut = cell(2,1);    
    
    for i = 1:2        
        if (nargin == 1)
            % includes the grouping radio buttons (if there is more than one trace)        
            hBut{i} = uicontrol('Style','PushButton','String',Btxt{i},...
                      'Position',Bpos{i},'Parent',hPanel,'tag','hMet',...
                      'FontUnits','pixels','FontWeight','bold','FontSize',12,...
                      'Callback',butFcn,'tag','grpButton');            
        else
            hBut{i} = findall(hPanel,'String',Btxt{i});
            set(hBut{i},'tag','grpButton','position',Bpos{i});
        end        
    end
    
    % updates the button selection properties
    updateButtonSelection(hBut,iData)
end

% only set up the selection table if initialising the GUI
if (nargin > 1); return; end

% ------------------------------------------------ %
% --- APPARATUS SELECTION TABLE INITIALISATION --- %
% ------------------------------------------------ %

% retrieves the apparatus names from the title strings
appPos = get(hApp,'position');

% resets the apparatus panel for the new table
if (isempty(iData.appName))
    % sets up the table
    delete(hApp)
    Bnew = 0;
else
    % if there are no apparatus, then delete the table and resize the GUI
    nApp = length(iData.appName);

    % retrieves the panel position    
    [W,H] = deal(appPos(3)-2*pOfs,calcTableHeight(nApp));
    Bnew = H + 2*yOfs1;

    % includes the grouping radio buttons (if there is more than one trace)        
    uicontrol('Style','RadioButton','String','Group Data By Metric',...
              'Position',[18 Bnew 145 Hchk],'Parent',hApp,'tag','hMet',...
              'FontUnits','pixels','FontWeight','bold','FontSize',12);    
    uicontrol('Style','RadioButton','String','Group Data By Type',...
              'Position',[170 Bnew 145 Hchk],'Parent',hApp,'tag','hType',...
              'FontUnits','pixels','FontWeight','bold','FontSize',12);    
    Bnew = Bnew + (yOfs1 + Hchk);

    % sets the table properties
    tabPos = [pOfs pOfs W H];
    colNames = {'Type Name','Include?'};
    colForm = {'Char','Logical'};
    colEdit = [false true];
    Data = [iData.appName,num2cell(logical(iData.appOut))];

    % creates the table object
    tabFcn = @(hObj,e)OutputData('callbackRegion',hObj,e,handles); 
    uitable(hApp,'Position',tabPos,'ColumnName',colNames,...
                 'ColumnFormat',colForm,'ColumnEditable',colEdit,...
                 'Data',Data,'CellEditCallback',tabFcn,...
                 'RowName',[]);
    resetObjPos(hApp,'height',Bnew) 
    setTableColWid(handles)
end

% sets the radio buttons to disabled for the infeasible function types
pStr = {'Stimuli Response Curve Fitting'}; 
if any(cellfun(@(x)(any(strcmp(x,pData.Name))),pStr))
    setObjEnable(findobj(hApp,'style','radiobutton'),'off')
end

% resets the locations of the other objects
dY = Bnew - appPos(4);
resetObjPos(hPanel,'bottom',dY,1);
setObjVisibility(handles.figOutputData,'on')
resetObjPos(hFig,'height',dY,1);    

% --- sets the table column widths
function setTableColWid(handles)

% table gap offset 
[W0,Wf] = deal(2,70);

% retrieves the base table dimensions
hTable = findall(handles.panelAppSelect,'type','uitable');

% sets the column width
tPos = get(hTable,'position');
set(hTable,'ColumnWidth',num2cell([(tPos(3)-(Wf+W0)),Wf]));





