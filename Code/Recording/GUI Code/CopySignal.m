function varargout = CopySignal(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CopySignal_OpeningFcn, ...
                   'gui_OutputFcn',  @CopySignal_OutputFcn, ...
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


% --- Executes just before CopySignal is made visible.
function CopySignal_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for CopySignal
handles.output = hObject;

% sets the input arguments
[iCh,chName] = deal(varargin{1},varargin{2});
[sBlk,tDur] = deal(varargin{3},varargin{4});

% sets the important values into the gui
setappdata(hObject,'tLimBlk',calcSignalBlockLimits(sBlk))
setappdata(hObject,'tDur',tDur)

% initialises the object properties
initObjProps(handles,iCh,chName)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes CopySignal wait for user response (see UIRESUME)
uiwait(handles.figCopySignal);

% --- Outputs from this function are returned to the command line.
function varargout = CopySignal_OutputFcn(hObject, eventdata, handles) 

% global variables
global iChCopy sPara isWC

% Get default command line output from handles structure
varargout{1} = isWC;
varargout{2} = sPara;
varargout{3} = iChCopy;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when user attempts to close figCopySignal.
function figCopySignal_CloseRequestFcn(hObject, eventdata, handles)

% runs the cancel function
buttonCancel_Callback(handles.buttonCancel, [], handles)

%-------------------------------------------------------------------------%
%                        OBJECT CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when selected object is changed in panelCopyType.
function panelCopyType_SelectionChangedFcn(hObject, eventdata, handles)

% initialisations
eStr = {'off','on'};
isWC = get(handles.radioWithinChannel,'Value');

% updates the within/between panel object properties
setPanelProps(handles.panelWithinChannel,eStr{1+isWC})
setPanelProps(handles.panelBtwnChannel,eStr{1+(~isWC)})

% --- Executes on editbox update for the within channel parameters
function editUpdate(hObject, eventdata, handles)

% retrieves the important values
hFig = handles.figCopySignal;
pStr = get(hObject,'UserData');
[sPara,sPara0] = deal(getappdata(hFig,'sPara'));

% sets the parameter limits/integer flags
switch pStr
    case 'nCount'
        [nwLim,isInt] = deal([1,inf],1);
    case 'tOfs'
        [nwLim,isInt] = deal([0,inf],0);
end

% determines if the new value is valid
nwVal = str2double(get(hObject,'String'));
if chkEditValue(nwVal,nwLim,isInt)
    % if valid, then set the new value
    eval(sprintf('sPara.%s = nwVal;',pStr));
    if detIfParaFeas(hFig,sPara)
        % if the parameter is feasible, then update the struct
        setappdata(hFig,'sPara',sPara)
        return
    end
end

% if there was an error, 
set(hObject,'string',num2str(eval(sprintf('sPara0.%s',pStr))))

% --- Executes on checkbox press for the between channel parameters
function checkUpdate(hObject, eventdata, handles)

% initialisations
eStr = {'off','on'};

% disables the continue button if there are no checkboxes selected
hChkSel = findobj(handles.panelBtwnChannel,'Value',1);
setObjEnable(handles.buttonCont,eStr{1+~isempty(hChkSel)})

% --- Executes on button press in buttonCont.
function buttonCont_Callback(hObject, eventdata, handles)

% global variables
global iChCopy sPara isWC

% retrieves the 
hChkSel = findobj(handles.panelBtwnChannel,'Value',1);
isWC = get(handles.radioWithinChannel,'Value');

% retrieves the selected checkbox channel indices
uData = get(hChkSel,'UserData');
if iscell(uData); uData = cell2mat(uData); end

% sets the channel index/signal parameter arrays
iChCopy = sort(uData);
sPara = getappdata(handles.figCopySignal,'sPara');

% closes the GUI
delete(handles.figCopySignal)

% --- Executes on button press in buttonCancel.
function buttonCancel_Callback(hObject, eventdata, handles)

% global variables
global iChCopy sPara isWC
[iChCopy,sPara,isWC] = deal([]);

% closes the GUI
delete(handles.figCopySignal)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the object properties
function initObjProps(handles,iCh,chName)

% initialisations
nCh = length(chName);
hFig = handles.figCopySignal;

% retrieves the important object handles
hPanelWC = handles.panelWithinChannel;
hPanelBC = handles.panelBtwnChannel;
hPanelCT = handles.panelCopyType;
hPanelCB = handles.panelContButton;
hRadio = findall(hPanelCT,'style','radiobutton');

% object dimensioning
pPos = get(hPanelBC,'position');
bpPos = get(handles.panelBtwnChannel,'position');
[x0,y0,chWid,chHght,dY] = deal(5,5,pPos(3)-10,23,25);

% calculates the change in height for the between channel panel
nwHght = 2*y0 + nCh*dY;
dHght = nwHght - bpPos(4);

% resets the position of the panels within the gui
resetObjPos(hFig,'Height',dHght,1)
resetObjPos(hPanelCT,'Height',dHght,1)
resetObjPos(hPanelBC,'Height',dHght,1)

resetObjPos(hFig,'Bottom',500)
resetObjPos(hPanelWC,'Bottom',dHght,1)
arrayfun(@(x)(resetObjPos(x,'Bottom',dHght,1)),hRadio)
resetObjPos(hPanelBC,'Bottom',y0)
resetObjPos(hPanelCB,'Bottom',2*y0)

% sets up the checkboxes for each of the channels
for i = 1:nCh
    % sets the position of the checkbox
    chkPos = [x0,y0+(i-1)*dY,chWid,chHght];
    
    % creates the checkbox object
    cbFcn = {@checkUpdate,handles};
    chkStr = sprintf('Channel #%i (%s)',(nCh+2)-iCh(i),chName{i});
    uicontrol('Parent',hPanelBC,'String',chkStr,'Value',1,...
              'Style','Checkbox','Position',chkPos,'Callback',cbFcn,...
              'FontWeight','Bold','FontUnits','pixel','FontSize',12,...
              'UserData',iCh(i));
                      
end

% initialises the stimuli parameter struct
tDur = getappdata(hFig,'tDur');
tLimBlk = getappdata(hFig,'tLimBlk');
sPara = initStimPara(tLimBlk,tDur);

% determines if parameter struct is feasbiel
if isempty(sPara)    
    % if not, then disable the between channel panel objects
    set(handles.radioBtwnChannel,'Value',1)
    setObjEnable(handles.radioWithinChannel,'off')
    setPanelProps(handles.panelWithinChannel,'off')    
else
    % resets the callback function for the within channel parameters
    hEdit = findall(hPanelWC,'style','edit');
    for i = 1:length(hEdit)
        % updates the callback function/string value
        pStr = get(hEdit(i),'UserData');
        nwVal = eval(sprintf('sPara.%s',pStr));
        set(hEdit(i),'Callback',{@editUpdate,handles},...
                     'String',num2str(abs(nwVal)));                 
    end
    
    % disables the between channel panel objects
    setPanelProps(handles.panelBtwnChannel,'off')
end

% 
setappdata(hFig,'sPara',sPara)

% --- initialises the within channel copy parameters
function sPara = initStimPara(tLimBlk,tDur)

% memory allocation
sPara = struct('tOfs',1,'nCount',1);

% determines if the current signal block configuration allows for at least
% one more copy to be placed afterwards
tDurR = (tDur-tLimBlk(2))/diff(tLimBlk);
if tDurR < 1
    % if not, flag that the within channel copying is infeasible
    sPara = [];
elseif tDurR < 2
    % otherwise, determine the valid time offset value
    sPara.tOfs = min(sPara.tOfs,diff(tLimBlk)*(tDurR-1));
end

% --- 
function isFeas = detIfParaFeas(hFig,sPara)

%
tDur = getappdata(hFig,'tDur');
tLimBlk = getappdata(hFig,'tLimBlk');

%
tDurNw = tLimBlk(2) + sPara.nCount*(sPara.tOfs + diff(tLimBlk));
isFeas = tDurNw < tDur;

% if the parameter configuration is infeasible, then output an error msg
if ~isFeas
    eStr = sprintf(['The new parameter configuration is ',...
                'infeasible:\n\n * Stimuli Duration = %.2f\n',...
                ' * New Configuration End-Point = %.2f'],tDur,tDurNw);
    waitfor(errordlg(eStr,'Infeasible Parameters','modal'))                        
end