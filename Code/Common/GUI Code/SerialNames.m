function varargout = SerialNames(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SerialNames_OpeningFcn, ...
                   'gui_OutputFcn',  @SerialNames_OutputFcn, ...
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


% --- Executes just before SerialNames is made visible.
function SerialNames_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for SerialNames
handles.output = hObject;

% sets the input variables
hGUI = varargin{1};
setappdata(hObject,'hGUI',hGUI)
setObjVisibility(hGUI,'off')

% Update handles structure
guidata(hObject, handles);

% initialises the GUI object properties
initObjProps(handles)

% disables the add/remove buttons
setObjEnable(handles.buttonAddDevice,'off')
setObjEnable(handles.buttonRemoveDevice,'off')

% UIWAIT makes SerialNames wait for user response (see UIRESUME)
% uiwait(handles.figDeviceNames);

% --- Outputs from this function are returned to the command line.
function varargout = SerialNames_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes on updating editDeviceName.
function editDeviceName_Callback(hObject, eventdata, handles)

% retrieves the new edit string
[nwStr,eStr] = deal(getDeviceString(handles),{'off','on'});

% sets the enabled property of the add button
setObjEnable(handles.buttonAddDevice,~isempty(nwStr))

% --- Executes when selected cell(s) is changed in tableDeviceName.
function tableDeviceName_CellSelectionCallback(hObject, eventdata, handles)

% retrieves the table java object
eStr = {'off','on'};
jTable = getappdata(handles.figDeviceNames,'jTable');

% determines if the object has been set
if (isempty(jTable))
    % retrieves the table java object
    hh = findjobj(hObject);
    jTable = hh.getComponent(0).getComponent(0);
    
    % updates the table java object handle
    setappdata(handles.figDeviceNames,'jTable',jTable)
end

% determines if a table row has been selected
iSel = jTable.getSelectedRows;
setObjEnable(handles.buttonRemoveDevice,~isempty(iSel))

% ----------------------- %
% --- CONTROL BUTTONS --- %
% ----------------------- %

% --- Executes on button press in buttonAddDevice.
function buttonAddDevice_Callback(hObject, eventdata, handles)

% global variables
global mainProgDir

% prompts the user if they actually want to add the device name
uChoice = questdlg(['Are you sure you want to add the device name to the ',...
                    'search list?'],'Add Device Name?','Yes','No','Yes');
if (~strcmp(uChoice,'Yes'))
    % if the user cancelled, then exit
    return
end

% makes the GUI invisible
setObjVisibility(handles.figDeviceNames,'off'); pause(0.05)

% updates the parameter file
sDev = [get(handles.tableDeviceName,'Data');{getDeviceString(handles)}];
save(fullfile(mainProgDir,'Para Files','ProgPara.mat'),'sDev','-append');

% disables the add/remove buttons and clears the device name editbox
setObjEnable(hObject,'off')
setObjEnable(handles.buttonRemoveDevice,'off')
set(handles.editDeviceName,'string','')

% makes the GUI visible again
initObjProps(handles,sDev)
setObjVisibility(handles.figDeviceNames,'on'); 

% --- Executes on button press in buttonRemoveDevice.
function buttonRemoveDevice_Callback(hObject, eventdata, handles)

% global variables
global mainProgDir

% determines the row that has been selected
jTable = getappdata(handles.figDeviceNames,'jTable');
iSel = jTable.getSelectedRows + 1;

% prompts the user if they actually want to remove the device name
Data = get(handles.tableDeviceName,'Data');
if (strcmp(Data{iSel},'STMicroelectronics STLink Virtual COM Port'))
    % outputs and error to screen and exits
    eStr = 'This is a default serial device type and can''t be removed.';
    waitfor(errordlg(eStr,'Device Removal Error','modal'))
    return
else
    % prompts the user if they actually want to add the device name
    uChoice = questdlg(['Are you sure you want to remove the device name from the ',...
                        'search list?'],'Remove Device Name?','Yes','No','Yes');
    if (~strcmp(uChoice,'Yes'))
        % if the user cancelled, then exit
        return
    end    
end

% makes the GUI invisible
setObjVisibility(handles.figDeviceNames,'off'); pause(0.05)

% updates the parameter file
sDev = Data((1:length(Data)) ~= iSel);
save(fullfile(mainProgDir,'Para Files','ProgPara.mat'),'sDev','-append');

% disables the add/remove buttons and clears the device name editbox
setObjEnable(hObject,'off')
setObjEnable(handles.buttonAddDevice,'off')
set(handles.editDeviceName,'string','')

% makes the GUI visible again
initObjProps(handles,sDev)
setObjVisibility(handles.figDeviceNames,'on'); 

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% retrieves the main GUI handle
hGUI = getappdata(handles.figDeviceNames,'hGUI');

% closes the window
delete(handles.figDeviceNames)
setObjVisibility(hGUI,'on');

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the GUI object properties
function initObjProps(handles,sStr)

% global variables
global mainProgDir

% retrieves the serial device strings from the parameter file
if (nargin == 1)
    A = load(fullfile(mainProgDir,'Para Files','ProgPara.mat'));
    sStr = A.sDev;
end

% initialisations
[Y0,nDev] = deal(10,length(sStr));

% retrieves the figure, button and port panel info object dimensions
tPos = get(handles.tableDeviceName,'position');
fPos = get(handles.figDeviceNames,'position');
pPos = get(handles.panelDeviceNames,'position');

% recalculates the gui object dimensions
if (nDev > 0)
    [tPos(4),Data] = deal(calcTableHeight(nDev),sStr);
else
    [tPos(4),Data] = deal(calcTableHeight(1),cell(1));
end

% resets the height of the panel/figure
pPos(4) = sum(tPos([2 4])) + 2.5*Y0;
fPos(4) = sum(pPos([2 4])) + Y0;

% recalculates the port panel dimensions
set(handles.tableDeviceName,'position',tPos,'Data',Data)
set(handles.panelDeviceNames,'position',pPos)
set(handles.figDeviceNames,'position',fPos);
autoResizeTableColumns(handles.tableDeviceName);

% --- 
function nwStr = getDeviceString(handles)

% retrieves the device name string
nwStr = get(handles.editDeviceName,'string');

% removes the start/end white-spaces
ii = regexp(nwStr,'\S');
nwStr = nwStr(ii(1):ii(end));
