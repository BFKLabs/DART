function varargout = InstallInfo(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @InstallInfo_OpeningFcn, ...
                   'gui_OutputFcn',  @InstallInfo_OutputFcn, ...
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


% --- Executes just before InstallInfo is made visible.
function InstallInfo_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for InstallInfo
handles.output = hObject;

% initialises the gui object properties
initObjProps(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes InstallInfo wait for user response (see UIRESUME)
% uiwait(handles.figInstallInfo);

% --- Outputs from this function are returned to the command line.
function varargout = InstallInfo_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when user attempts to close figInstallInfo.
function figInstallInfo_CloseRequestFcn(hObject, eventdata, handles)

% runs the close window menu item callback
menuClose_Callback(handles.menuClose,'1',handles)

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% -------------------------------------------------------------------------
function menuClose_Callback(hObject, eventdata, handles)

% deletes the gui
delete(handles.figInstallInfo)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the gui object properties
function initObjProps(handles)

% global variables
global H0T HWT

% initialisations
hFig = handles.figInstallInfo;

% toolbox strings
tStr = ' Toolbox';
pStr = ' Support Package for ';
toolStr = {'Curve Fitting';...
           'Data Acquisition';...
           'Image Acquisition';...
           'Image Processing';... 
           'Instrument Control';...           
           'Optimization';...
           'Signal Processing';...
           'Statistics and Machine Learning'};
affStr = {{'Tracking','Analysis'};...
          {'Recording'};...
          {'Recording','Tracking'};...
          {'Tracking','Analysis'};...
          {'Recording'};...
          {'Tracking','Analysis'};...
          {'Tracking','Analysis'};...
          {'Tracking','Analysis'}};
       
% other initialisations
dX = 10;
nColV = 4;

% retrieves the version and support package info
vInfo = ver;
pInfo = matlabshared.supportpkg.getInstalled;

% ------------------------------------ %
% --- REQUIRED TOOLBOX INFORMATION --- %
% ------------------------------------ %

% determines the required toolboxes that are currently available
[vName,vVer0] = field2cell(vInfo(:),{'Name','Version'});
iInst = cellfun(@(x)(find(startsWith(vName,x))),toolStr,'un',0);
isInst = ~cellfun(@isempty,iInst);

% sets up the required toolbox table data
vData = cell(length(toolStr),nColV);
vData(:,1) = toolStr;
vData(:,2) = cellfun(@(x)(strjoin(x,', ')),affStr,'un',0);
vData(:,3) = num2cell(isInst);
vData(isInst,4) = vVer0(cell2mat(iInst(isInst)));

% sets the required toolboxes properties
set(handles.tableReqdToolboxes,'Data',vData);
autoResizeTableColumns(handles.tableReqdToolboxes);

% ----------------------------------- %
% --- SUPPORT PACKAGE INFORMATION --- %
% ----------------------------------- %

%
toolStrS = [toolStr;{'MATLAB'}];

% sets the data for the tables
[pName0,pVer,pTool0] = ...
            field2cell(pInfo(:),{'Name','InstalledVersion','BaseProduct'});      
isPack = cellfun(@(x)(any(strContains(x,toolStrS))),pTool0);

% sets the support package information (dependent on count)
if any(isPack)
    % sets the toolbox/package names
    pTool = cellfun(@(x)(getArrayVal...
                            (regexp(x,tStr,'split'),1)),pTool0,'un',0);
    pName = cellfun(@(x)(getArrayVal...
                            (regexp(x,pStr,'split'))),pName0,'un',0);
        
    % sets up the installed package table data fields
    pData = [pName(isPack),pTool(isPack),pVer(isPack)];
    [~,iSort] = sort(pData(:,2));
    pData = pData(iSort,:);

    % sets the data into the tables
    set(handles.tablePackInstall,'Data',pData);
    autoResizeTableColumns(handles.tablePackInstall);
    
    % determines the change in figure/object dimensions
    tPos = get(handles.tablePackInstall,'Position');
    tHght = H0T+sum(isPack)*HWT;
    dHght = tPos(4)-tHght;
    
    % resets the table dimensions
    resetObjPos(handles.tablePackInstall,'Height',tHght)
    resetObjPos(handles.tablePackInstall,'Bottom',dX)
    
else
    % no packages are installed, so reset the table dimensions
    setObjVisibility(handles.tablePackInstall,0)
    setObjVisibility(handles.textNoPackage,1)
    uistack(handles.textNoPackage,'top');
    
    % determines the height change
    txtPos = get(handles.textNoPackage,'Position');
    dHght = txtPos(2)-dX;
    resetObjPos(handles.textNoPackage,'Bottom',dX)
    
end

% 
resetObjPos(hFig,'Height',-dHght,1)
resetObjPos(handles.panelReqdToolboxes,'Bottom',-dHght,1)
resetObjPos(handles.panelPackInstall,'Bottom',dX)
resetObjPos(handles.panelPackInstall,'Height',-dHght,1)
