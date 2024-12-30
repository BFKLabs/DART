function varargout = SerialConfig(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SerialConfig_OpeningFcn, ...
                   'gui_OutputFcn',  @SerialConfig_OutputFcn, ...
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


% --- Executes just before SerialConfig is made visible.
function SerialConfig_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for SerialConfig
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% creates a loadbar
h = ProgressLoadbar('Detecting Serial Port Information...');

% sets the input variables
hGUI = varargin{1};
setappdata(hObject,'hGUI',hGUI);
setObjVisibility(hGUI,'off');

% initialises the GUI object properties
initObjProps(handles)

% closes the loadbar
try; delete(h); end

% UIWAIT makes SerialConfig wait for user response (see UIRESUME)
% uiwait(handles.figSerialConfig);

% --- Outputs from this function are returned to the command line.
function varargout = SerialConfig_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ----------------------------- %
% --- DEVICE INFO CALLBACKS --- %
% ----------------------------- %

% --- Executes when selected cell(s) is changed in tableDeviceInfo.
function tableDeviceInfo_CellSelectionCallback(hObject, eventdata, handles)

% if the indices are empty, then exit
if isempty(eventdata.Indices); return; end

% sets the selected row/column indices and serial build directory
Data = get(hObject,'Data');
[iRow,iCol] = deal(eventdata.Indices(1),eventdata.Indices(2));
utilDir = getProgFileName('Code','Common','Utilities','Serial Builds');

% only enable updating if the type column has been selected (and the
% serial device is a V1 serial controller)
if (iCol == 4) && ~strcmp(Data{iRow,3},'N/A')
    % prompt the user for the serial binary file
    [fName,fDir,fIndex] = uigetfile(...
        {'*.bin','Serial Device Binary Files (*.bin)'},...
         'Select A Serial Device Binary File',utilDir);    
    if fIndex
        % creates a loadbar
        h = ProgressLoadbar('Updating Serial Device Binary File...');
                
        % copies over the binary file. waits until the update is complete
        diskStr = getappdata(handles.figSerialConfig,'diskStr');
        copyfile(fullfile(fDir,fName),diskStr{iRow});
        pause(5.0);
        
        % updates the table
        Data{iRow,iCol} = getSerialDeviceType(Data{iRow,2});
        set(hObject,'Data',Data);
        
        % closes the loadbar
        try; delete(h); end
    end
end

% -------------------------------- %
% --- CONTROL BUTTON CALLBACKS --- %
% -------------------------------- %

% --- Executes on button press in buttonConfigPorts.
function buttonConfigPorts_Callback(hObject, eventdata, handles)

% opens the device manager
system('devmgmt.msc');

% creates a message box to guide the user in reconfiguring the device
mStr = sprintf(['To alter the COM Port Number of a Serial Device, you ',...
                'will need to perform the following steps within the ',...
                'Device Manager:\n\n 1) Expand the ',...
                '"Ports (COMS & LPT)" tree tab\n 2) Select the serial ',...
                'device you wish to reconfigure\n 3) Right-Click and select ',...
                'the "Properties" menu item\n 4) Select the "Port Settings" ',...
                'tab from the popup-window\n 5) Click the "Advanced" click ',...
                'button\n 6) Select the new "COM Port Number" from the ',...
                'drop-down list\n 7) Select "OK" and exit the Properties ',...
                'menu item\n\nOnce the alteration process is complete, ',...
                'you will need to reboot the computer so that the changes ',...
                'can take hold. Until you do this, the newly selected COM ',...
                'Port will not be available for use.']);
msgbox(mStr,'Serial COM Port Number Alteration Process')

% --- Executes on button press in butSetNames.
function butSetNames_Callback(hObject, eventdata, handles)

% opens the serial device names GUI
SerialNames(handles.figSerialConfig)

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% retrieves the main GUI handle
hGUI = getappdata(handles.figSerialConfig,'hGUI');

% closes the window
delete(handles.figSerialConfig)
setObjVisibility(hGUI,'on');

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the GUI object properties
function initObjProps(handles)

% retrieves the serial device strings from the parameter file
A = load(getParaFileName('ProgPara.mat'));

% initialisations
[Y0,X0,diskStr] = deal(10,10,[]);

% determines the serial port and connected device information
[comA,comD] = getSerialPortInfo();
pStr = findSerialPort(A.sDev,1);
nDev = size(pStr,1);

% sets the detected/available strings
set(handles.textDetectPort,'string',setFullString(comD,'Detected'));
set(handles.textAvailPort,'string',setFullString(comA,'Available'));

% retrieves the figure, button and port panel info object dimensions
tPos = get(handles.textNoDevice,'position');
fPos = get(handles.figSerialConfig,'position');
bPos = get(handles.panelContButtons,'position');
pPosP = get(handles.panelPortInfo,'position');

% recalculates the gui object dimensions
if (nDev > 0)
    % sets the new table dimensions
    [HT,Data] = deal(calcTableHeight(nDev),pStr(:,[2 1 4 5]));
    pPosD = [X0 (Y0+sum(bPos([2 4]))) pPosP(3) (3.5*Y0+HT+2)];
    [tPosD,diskStr] = deal([X0 Y0 (pPosD(3)-2*X0) HT],pStr(:,4));
    
    % updates the device info table
    set(handles.tableDeviceInfo,'position',tPosD,'Data',Data,'Visible','on')
    autoResizeTableColumns(handles.tableDeviceInfo);    
else
    % updates the panel dimensions
    pPosD = [X0 (Y0+sum(bPos([2 4]))) pPosP(3) (3.5*Y0 + tPos(4))];
    
    % makes the table invisible
    setObjVisibility(handles.tableDeviceInfo,'off')            
end

% recalculates the port panel dimensions
pPosP = [X0 (Y0+sum(pPosD([2 4]))) pPosP(3:4)];

% updates the object dimensions
set(handles.panelPortInfo,'position',pPosP)
set(handles.panelDeviceInfo,'position',pPosD)
set(handles.figSerialConfig,'position',[fPos(1:3) (Y0+sum(pPosP([2 4])))])
setappdata(handles.figSerialConfig,'diskStr',diskStr);

% --- sets the full information strings
function fStr = setFullString(sStr,Type)

% determines if the the input string is empty
if isempty(sStr)
    % if so, then output a generic string
    fStr = sprintf('No COM Ports %s',Type);
else
    % appends the strings to each other with a comma separation
    fStr = sStr{1};
    for i = 2:length(sStr)
        fStr = sprintf('%s, %s',fStr,sStr{i});
    end
end
