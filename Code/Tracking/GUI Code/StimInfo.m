function varargout = StimInfo(varargin)
% Last Modified by GUIDE v2.5 18-Jan-2021 10:50:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @StimInfo_OpeningFcn, ...
                   'gui_OutputFcn',  @StimInfo_OutputFcn, ...
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

% --- Executes just before StimInfo is made visible.
function StimInfo_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for StimInfo
handles.output = hObject;

% sets the input arguments
hGUI = varargin{1};

% initialses the custom property field string
pFldStr = {'hGUI','sPara','stimP','sData','T','dType','chName'};
initObjPropFields(hObject,pFldStr);

% retrieves the data struct from the main GUI
iMov = get(hGUI.output,'iMov');
iData = get(hGUI.output,'iData');

% if there is no stimuli information, then exit the GUI
if isempty(iData.stimP)
    mStr = 'There is no stimuli information for this video.';
    waitfor(errordlg(mStr,'Stimuli Protocol View Error','modal'))
    delete(hObject)
    return
end

% case is the experiment is run using the new stimuli format
sPara = iData.sTrainEx;

% retrieves the program data struct
set(hObject,'hGUI',hGUI);
set(hObject,'sPara',sPara);
set(hObject,'stimP',iData.stimP);
set(hObject,'T',iData.Tv(iData.Frm0:iMov.sRate:end));

% retrieves the objects within the stimuli panel
delete(handles.editOuter);

% initialises the tab objects
handles = initObjProps(handles);
initListBoxes(handles)
initEventTabGroup(handles)
autoResizeTableColumns(handles.tableStimPara)

% updates the channel list information
listDevice_Callback(handles.listDevice, '1', handles);

% centres the gui
centreFigPosition(hObject);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes StimInfo wait for user response (see UIRESUME)
% uiwait(handles.figStimInfo);

% --- Outputs from this function are returned to the command line.
function varargout = StimInfo_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = [];

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% -------------------------------------------------------------------------
function menuClose_Callback(hObject, eventdata, handles)

% closes the GUI
delete(handles.output)

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes on selection change in listDevice.
function listDevice_Callback(hObject, eventdata, handles)

% initialisations
hFig = handles.output;
sData = get(hFig,'sData');
chName = get(hFig,'chName');
[lStr,iSel] = deal(get(hObject,'String'),get(hObject,'Value'));

% updates the device type
sData.dType = lStr{iSel};
set(hFig,'sData',sData)

% updates the channel listbox
set(handles.listChannel,'String',chName{iSel}(:),'Value',1);
listChannel_Callback(handles.listChannel, '1', handles)

% --- Executes on selection change in listChannel.
function listChannel_Callback(hObject, eventdata, handles)

% initialisations
hFig = handles.output;
stimP = get(hFig,'stimP');
sData = get(hFig,'sData');
[lStr,iSel] = deal(get(hObject,'String'),get(hObject,'Value'));

% updates the device type
sData.chName = lStr{iSel};

% retrieves the stimuli information
stimPC = getStructField(stimP,sData.dType,sData.chName);
nStim = length(stimPC.Ts);

% updates the select tab
sData.sTab = min(nStim,sData.sTab);
set(hFig,'sData',sData)

% resets the tabs visibility
hTabG = get(sData.heTab{1},'Parent');
cellfun(@(x)(set(x,'Parent',hTabG)),sData.heTab(1:nStim))
cellfun(@(x)(set(x,'Parent',[])),sData.heTab((nStim+1):end))

% updates the selected tab
set(hTabG,'SelectedTab',sData.heTab{sData.sTab});
updateEventFields(handles)

% --- Executes on button press in buttonStartFrame.
function buttonStartFrame_Callback(hObject, eventdata, handles)

% retrieves the display image function
hFig = handles.output;
hGUI = get(hFig,'hGUI');
iData = get(hGUI.output,'iData');
dispImage = get(hGUI.output,'dispImage');

% updates the frame counter
set(hGUI.frmCountEdit,'string',get(handles.textStartFrame,'string'));
iData.cFrm = str2double(get(handles.textStartFrame,'string'));
set(hGUI.output,'iData',iData)

% updates the main image axis
axes(hGUI.imgAxes)
h = waitbar(0,'Updating Main Axes Image...');
dispImage(hGUI)
waitbar(1,h,'Update Complete'); delete(h);

% resets the figure to stimulus info GUI
figure(handles.output)

% --- Executes on button press in buttonFinishFrame.
function buttonFinishFrame_Callback(hObject, eventdata, handles)

% retrieves the display image function
hFig = handles.output;
hGUI = get(hFig,'hGUI');
iData = get(hGUI.output,'iData');
dispImage = get(hGUI.output,'dispImage');

% updates the frame counter
set(hGUI.frmCountEdit,'string',get(handles.textFinishFrame,'string'));
iData.cFrm = str2double(get(handles.textFinishFrame,'string'));
set(hGUI.output,'iData',iData)

% updates the main image axis
axes(hGUI.imgAxes)
h = waitbar(0,'Updating Main Axes Image...');
dispImage(hGUI)
waitbar(1,h,'Update Complete'); delete(h);

% resets the figure to stimulus info GUI
figure(hFig)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --------------------------------------- %
% --- OBJECT INITIALISATION FUNCTIONS --- %
% --------------------------------------- %

% --- initialises the gui object properties
function handles = initObjProps(handles)

% Create tableStimPara
tPos = [5 7 440 166];
cWid = {60, 55, 'auto', 'auto', 55, 'auto'};
cEdit = [false false false false false false];
cName = {'Type';'Count';'Period (s)';...
         'Amplitude (%)';'Offset (s)';'Duration (s)'};

% creates the table object    
handles.tableStimPara = uitable(handles.panelStimPara,...
    'Units','Pixels','ColumnName',cName,'ColumnWidth',cWid,...
    'ColumnEditable',cEdit,'Tag','tableStimPara',...
    'FontUnits','Pixels','FontSize',11,'Position',tPos,...
    'ColumnFormat',{[] [] [] [] [] []});

% --- initialises the channel listbox object --- %
function initListBoxes(handles)

% retrieves the stimulus parameter struct
hFig = handles.output;
stimP = get(hFig,'stimP');
dType = fieldnames(stimP);

% memory allocation
nStimMax = 0;
nDev = length(dType);
hasStimD = false(nDev,1);
chName = cell(nDev,1);

% determines the stimuli information for each device
for iDev = 1:nDev
    % retrieves the channels names for the current device
    stimPD = getStructField(stimP,dType{iDev});
    chName0 = fieldnames(stimPD);
    
    % removes any channels with no stimuli events
    stimPC = cellfun(@(x)(getStructField(stimPD,x)),chName0,'un',0);
    nStimC = cellfun(@(x)(length(x.Ts)),stimPC);
    [hasStimC,nStimMax] = deal(nStimC > 0,max(max(nStimC),nStimMax));
    
    % reduces down the 
    chName{iDev} = chName0(hasStimC);
    hasStimD(iDev) = any(hasStimC);
end

% reduces down the 
[chName,dType] = deal(chName(hasStimD),dType(hasStimD));
set(hFig,'dType',dType);
set(hFig,'chName',chName);

% sets the listbox strings
set(handles.listDevice,'String',dType(:),'FontUnits','pixels',...
                       'FontSize',11,'Value',1);
set(handles.listChannel,'String',chName{1}(:),'FontUnits','pixels',...
                        'FontSize',11,'Value',1);

% sets the data struct
sData = struct('dType',dType{1},'chName',chName{1}{1},...
               'sTab',1,'nStimMax',nStimMax,'heTab',[]);
set(hFig,'sData',sData);     
                    
% --- initialises the event tab group --- %
function initEventTabGroup(handles)

% retrieves the stimulus parameter struct
hFig = handles.output;
sData = get(hFig,'sData');
hObj = findall(handles.panelStimInfo,'parent',handles.panelStimInfo);

% creates the master tab group and sets the properties
hTabGrp = createTabGroup();
set(hTabGrp,'tag','tabStimPara','Units','Pixels',...
            'Position',[3 5 233 171],'Parent',handles.panelStimInfo)   
        
% sets the colour strings        
sData.heTab = cell(sData.nStimMax,1);

% sets up the tab objects (over all stimuli objects)
wState = warning('off','all');
for i = 1:sData.nStimMax
    % sets up the tabs within the tab group
    tStr = sprintf('#%i',i);
    sData.heTab{i} = createNewTab(hTabGrp,'Title',tStr,'UserData',i);
    
    % sets up all the objects within the tab 
    pause(0.1)
end    
warning(wState);

% sets the tab selection change callback function
setObjCallbackFcn(hTabGrp,'TabGroup',@stimEventTabChange);
uistack(hObj,'top');

% updates the events fields
set(hFig,'sData',sData)
updateEventFields(handles)

% ------------------------------------ %
% --- TAB GROUP CALLBACK FUNCTIONS --- %
% ------------------------------------ %

% --- callback function for altering the stimulus parameter tabs
function stimEventTabChange(hObject, eventdata)

% sets the data struct
handles = guidata(hObject);
hFig = handles.output;
sData = get(hFig,'sData');

% updates the channel tab index
sData.sTab = get(eventdata.NewValue,'UserData');
set(hFig,'sData',sData)

% updates the stimulus events fields 
updateEventFields(handles);

% ------------------------------------ %
% --- TEXT OBJECT UPDATE FUNCTIONS --- %
% ------------------------------------ %

% --- updates the stimulus events fields 
function updateEventFields(handles)

% gets the data struct
hFig = handles.output;
T = get(hFig,'T');
stimP = get(hFig,'stimP');
sData = get(hFig,'sData');
sPara = get(hFig,'sPara');

% retrieves the channel information (for the currently selected device)
sTab = sData.sTab;
stimPC = getStructField(stimP,sData.dType,sData.chName);
[Ts,Tf] = deal(max(0,stimPC.Ts(sTab)),min(stimPC.Tf(sTab),T(end)));
[iFrm0,iFrmF] = deal(argMin(abs(T-Ts)),argMin(abs(T-Tf)));

% determines the stimuli time stamp/duration time strings
[~,~,C1] = calcTimeDifference(T(iFrm0));
[~,~,C2] = calcTimeDifference(Tf-Ts);

%
indS = stimPC.iStim(sData.sTab);
sTrain = sPara.sTrain(indS);
[dT,chN] = deal(sData.dType,sData.chName);

% sets the device type (removes any spaces/#'s)
dType0 = field2cell(sPara.sTrain(indS).blkInfo,'devType');
dType = cellfun(@(x)(regexprep(x,'[ #]','')),dType0,'un',0); 

% retrieves the block information pertaining to the current channel
if strcmp(chN,'Ch')
    % if all channels are the same, then use the first one that matches the
    % current device type
    isM = find(strcmp(dType,dT),1,'first');
    blkInfo = sTrain.blkInfo(isM);
else   
    % otherwise, determine all blocks that correspond to the current
    % device/channel name
    chName0 = field2cell(sPara.sTrain(indS).blkInfo,'chName');
    chName = cellfun(@(x)(strrep(x,' #','')),chName0,'un',0);
    isM = strcmp(dType,dT) & strcmp(chName,chN);
    blkInfo = sTrain.blkInfo(isM);
end

% updates the fields strings
set(handles.textStartFrame,'string',num2str(iFrm0));
set(handles.textFinishFrame,'string',num2str(iFrmF));
set(handles.textTimeStamp,'string',sprintf('%s:%s:%s',C1{2},C1{3},C1{4}));
set(handles.textStimDur,'string',sprintf('%s:%s:%s',C2{2},C2{3},C2{4}));
set(handles.textStimCount,'string',num2str(length(blkInfo)));

% updates the stimuli parameter table information
updateStimParaTable(handles,blkInfo);

% --- updates the stimuli parameter information table 
function updateStimParaTable(handles,blkInfo)

% data retrieval
sType = field2cell(blkInfo,'sType');
sPara = field2cell(blkInfo,'sPara',1);
sTypeF = cellfun(@(x)(convertSignalTypes(x)),sType,'un',0);

% sets the table head strings
tHdr = {'Type','Count','Period (s)',...
        'Amplitude (%)','Offset (s)','Duration (s)'};

% sets the signal parameter table data
sData = cell(length(sPara),length(tHdr)-1);
for i = 1:length(sPara)
    % calculates the time multipliers    
    tMltD = getTimeMultiplier('s',sPara(i).tDurU);
    tMltO = getTimeMultiplier('s',sPara(i).tOfsU);
    
    % sets the signal independent fields
    sData{i,1} = num2str(sPara(i).nCount);
    sData{i,4} = sprintf('%s',setCellEntry(sPara(i).tOfs*tMltO));
    sData{i,5} = sprintf('%s',setCellEntry(sPara(i).tDur*tMltD));
    
    % sets the signal dependent fields
    if strcmp(sType{i},'Square')
        % calculates the off/on duty cycle durations time multipliers
        tMltOff = getTimeMultiplier('s',sPara(i).tDurOffU);
        tMltOn = getTimeMultiplier('s',sPara(i).tDurOnU);
        
        % sets the values for the amplitude/cycle duration
        tStrOn = setCellEntry(sPara(i).tDurOn*tMltOn);
        if sPara(i).nCount == 1
            sData{i,2} = sprintf('%s',tStrOn);
        else
            tStrOff = setCellEntry(sPara(i).tDurOff*tMltOff);
            sData{i,2} = sprintf('%s/%s',tStrOff,tStrOn);
        end
            
        sData{i,3} = setCellEntry(sPara(i).sAmp);
    else
        % calculates the duty cycle duration time multiplier
        tMltC = getTimeMultiplier('s',sPara(i).tCycleU);
        
        % sets the cycle duration
        sData{i,2} = setCellEntry(sPara(i).tCycle*tMltC);
        
        % sets the signal amplitude
        sStrOn = setCellEntry(sPara(i).sAmp1);
        if sPara(i).sAmp0 == 0
            % case is there is a zero base amplitude
            sData{i,3} = sprintf('%s',sStrOn);
            
        else
            % case is there is a non-zero base amplitude
            sStrOff = setCellEntry(sPara(i).sAmp0);
            sData{i,3} = sprintf('%s/%s',sStrOff,sStrOn);
        end
    end
end

% sets up the table data
setHorizAlignedTable(handles.tableStimPara,[sTypeF(:),sData]);

% --- converts the signal types
function sType = convertSignalTypes(sType)

switch sType
    case 'SineWave'
        sType = 'Sine';            
end

% --- sets the text for a numerical value, tVal
function tStr = setCellEntry(tVal)

% rounds the value to 0.001 and converts to a string
tStr = num2str(roundP(tVal,0.001));

