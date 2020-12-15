function varargout = StimInfo(varargin)
% Last Modified by GUIDE v2.5 19-Dec-2015 23:38:14

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
setappdata(hObject,'hGUI',hGUI);

% retrieves the data struct from the main GUI
iData = getappdata(hGUI.figFlyTrack,'iData');
iMov = getappdata(hGUI.figFlyTrack,'iMov');

if (isempty(iData.stimP))
    mStr = 'It is not possible to view the stimuli protocol in information GUI.';
    waitfor(errordlg(mStr,'Stimuli Protocol View Error','modal'))
    delete(hObject)
    return
end

% retrieves the program data struct
setappdata(hObject,'T',iData.Tv);
setappdata(hObject,'stimP',iData.stimP);
setappdata(hObject,'sRate',iMov.sRate);
setappdata(hObject,'stimFrm',iData.stimFrm);

% retrieves the objects within the stimuli panel
if (~verLessThan('matlab','8.4')); delete(handles.editOuter); end
hObj = findall(handles.panelStimInfo,'parent',handles.panelStimInfo);

% sets the data struct
sData = struct('cTab',1,'eTab',1,'pTab',1,...
               'nChannel',0,'nEventMax',0,'nParaMax',0);
setappdata(hObject,'sData',sData);

% initialises the tab objects
initChannelListBox(handles)
initEventTabGroup(handles,hObj)
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
delete(handles.figStimInfo)

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes on selection change in listChannel.
function listChannel_Callback(hObject, eventdata, handles)

% updates the 
sData = getappdata(handles.figStimInfo,'sData');
sData.cTab = get(hObject,'Value');
setappdata(handles.figStimInfo,'sData',sData)

% updates the events fields
updateEventFields(handles)
updateParaFields(handles)

% --- Executes on button press in buttonStartFrame.
function buttonStartFrame_Callback(hObject, eventdata, handles)

% retrieves the display image function
hGUI = getappdata(handles.figStimInfo,'hGUI');
iData = getappdata(hGUI.figFlyTrack,'iData');
dispImage = getappdata(hGUI.figFlyTrack,'dispImage');

% updates the frame counter
set(hGUI.frmCountEdit,'string',get(handles.textStartFrame,'string'));
iData.cFrm = str2double(get(handles.textStartFrame,'string'));
setappdata(hGUI.figFlyTrack,'iData',iData)

% updates the main image axis
axes(hGUI.imgAxes)
h = waitbar(0,'Updating Main Axes Image...');
dispImage(hGUI)
waitbar(1,h,'Update Complete'); delete(h);

% resets the figure to stimulus info GUI
figure(handles.figStimInfo)

% --- Executes on button press in buttonFinishFrame.
function buttonFinishFrame_Callback(hObject, eventdata, handles)

% retrieves the display image function
hGUI = getappdata(handles.figStimInfo,'hGUI');
iData = getappdata(hGUI.figFlyTrack,'iData');
dispImage = getappdata(hGUI.figFlyTrack,'dispImage');

% updates the frame counter
set(hGUI.frmCountEdit,'string',get(handles.textFinishFrame,'string'));
iData.cFrm = str2double(get(handles.textFinishFrame,'string'));
setappdata(hGUI.figFlyTrack,'iData',iData)

% updates the main image axis
axes(hGUI.imgAxes)
h = waitbar(0,'Updating Main Axes Image...');
dispImage(hGUI)
waitbar(1,h,'Update Complete'); delete(h);

% resets the figure to stimulus info GUI
figure(handles.figStimInfo)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --------------------------------------- %
% --- OBJECT INITIALISATION FUNCTIONS --- %
% --------------------------------------- %

% --- initialises the channel listbox object --- %
function initChannelListBox(handles)

% retrieves the stimulus parameter struct
stimP = getappdata(handles.figStimInfo,'stimP');
iStim = num2cell(1:length(stimP))';

% initialisations
lPos = get(handles.listChannel,'position');
[lPos(4),dL0] = calcListHeight(12,lPos(4));
lPos(2) = lPos(2) + dL0/2;

% sets the listbox strings
lStr = cellfun(@(x)(sprintf('Channel #%i',x)),iStim,'un',0);
set(handles.listChannel,'String',lStr,'FontUnits','pixels','FontSize',11,...
            'FontWeight','bold','Position',lPos);

% --- initialises the event tab group --- %
function initEventTabGroup(handles,hObj)

% retrieves the stimulus parameter struct
stimP = getappdata(handles.figStimInfo,'stimP');
sData = getappdata(handles.figStimInfo,'sData');

% creates the master tab group and sets the properties
hTabGrp = createTabGroup();
set(hTabGrp,'tag','tabStimPara','Units','Pixels',...
            'Position',[3 5 233 171],'Parent',handles.panelStimInfo)   
        
% sets the colour strings
sData.nEventMax = max(cellfun(@length,field2cell(stimP,'Tsig')));         
sData.heTab = cell(sData.nEventMax,1);

% sets up the tab objects (over all stimuli objects)
for i = 1:sData.nEventMax
    % sets up the tabs within the tab group
    tStr = sprintf('Stim Event #%i',i);
    sData.heTab{i} = createNewTab(hTabGrp,'Title',tStr,'UserData',i);
    
    % sets up all the objects within the tab 
    pause(0.1)
end    
warning on all

% sets the tab selection change callback function
tChngFcn = @(hTabGrp,e)StimInfo('stimEventTabChange',hTabGrp,e,handles);
setObjCallbackFcn(hTabGrp,'TabGroup',tChngFcn);
uistack(hObj,'top');

% updates the events fields
setappdata(handles.figStimInfo,'sData',sData)
updateEventFields(handles)
updateParaFields(handles)

% ------------------------------------ %
% --- TAB GROUP CALLBACK FUNCTIONS --- %
% ------------------------------------ %

% --- callback function for altering the stimulus parameter tabs
function stimEventTabChange(hObject, eventdata, handles)

% sets the data struct
stimP = getappdata(handles.figStimInfo,'stimP');
sData = getappdata(handles.figStimInfo,'sData');

% updates the channel tab index
sData.eTab = get(eventdata.NewValue,'UserData');
setappdata(handles.figStimInfo,'sData',sData)

% updates the parameter tab visibility
sP = stimP(sData.cTab).sP{sData.eTab};
for i = 1:sData.nParaMax
    if (i <= length(sP))
        set(sData.hpTab{i},'HitTest','on')
    else
        set(sData.hpTab{i},'HitTest','off')
    end
end

% updates the stimulus events fields 
updateEventFields(handles);
updateParaFields(handles);

% ------------------------------------ %
% --- TEXT OBJECT UPDATE FUNCTIONS --- %
% ------------------------------------ %

% --- updates the stimulus events fields 
function updateEventFields(handles)

% gets the data struct
T = getappdata(handles.figStimInfo,'T');
stimP = getappdata(handles.figStimInfo,'stimP');
sData = getappdata(handles.figStimInfo,'sData');
stimFrm = getappdata(handles.figStimInfo,'stimFrm');

% sets the sub-structs and other indices
stimPnw = stimP(sData.cTab);
[Tsig,sP] = deal(stimPnw.Tsig{sData.eTab},stimPnw.sP{sData.eTab});
iGrp = getGroupIndex(stimFrm>=2);

% updates the fields strings
set(handles.textStartFrame,'string',num2str(iGrp{sData.eTab}(1)));
set(handles.textFinishFrame,'string',num2str(iGrp{sData.eTab}(end)));
set(handles.textTimeStamp,'string',num2str(roundP(T(iGrp{sData.eTab}(1)),0.01)));
set(handles.textStimDur,'string',sprintf('%i sec',ceil(Tsig(end))));
set(handles.textStimCount,'string',sprintf('%i',length(sP)));

% --- updates the stimulus parameter fields 
function updateParaFields(handles)

% gets the data struct
stimP = getappdata(handles.figStimInfo,'stimP');
sData = getappdata(handles.figStimInfo,'sData');

% sets the sub-structs and other indices
stimPnw = stimP(sData.cTab);
sP = stimPnw.sP{sData.eTab};
gStr = repmat(' ',1,8);

% resets the table position height
tPos = get(handles.tableStimPara,'Position');
tPos(4) = calcTableHeight(8);

% updates the table values
[A,B,C,D,E] = field2cell(sP,{'nCount','pAmp','pDur','iDelay','pDelay'});
nCount = cellfun(@(x)(sprintf('%s %i',gStr,x(1))),A,'un',0);    
pAmp = cellfun(@(x)(sprintf('%s%.2f',gStr,x(1))),B,'un',0);
pDur = cellfun(@(x)(sprintf('%s%.2f',gStr,x(1))),C,'un',0);

% adds in any pre-stimuli duration elements which are missing
D(cellfun(@length,D)==0) = {[0]};
iDelay = cellfun(@(x)(sprintf('%s%.2f',gStr,x(1))),D,'un',0);

% adds in any pre-stimuli duration elements which are missing
E(cellfun(@length,E)==0) = {[0]};
pDelay = cellfun(@(x)(sprintf('%s%.2f',gStr,x(1))),E,'un',0);
    
% sets the table properties
Data = [nCount,pAmp,pDur,iDelay,pDelay];
set(handles.tableStimPara,'Data',Data,'Position',tPos)
autoResizeTableColumns(handles.tableStimPara);
