function varargout = GitUserInfo(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GitUserInfo_OpeningFcn, ...
                   'gui_OutputFcn',  @GitUserInfo_OutputFcn, ...
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


% --- Executes just before GitUserInfo is made visible.
function GitUserInfo_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for GitUserInfo
handles.output = hObject;

% initialises the gui object properties
initObjProps(handles,varargin{1});

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GitUserInfo wait for user response (see UIRESUME)
uiwait(handles.figUserInfo);


% --- Outputs from this function are returned to the command line.
function varargout = GitUserInfo_OutputFcn(hObject, eventdata, handles) 

% global variables
global uInfo

% Get default command line output from handles structure
varargout{1} = uInfo;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     FIGURE CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when user attempts to close figUserInfo.
function figUserInfo_CloseRequestFcn(hObject, eventdata, handles)

% updates and closes the GUI
if strcmp(get(handles.buttonUpdate,'enable'),'on')
    buttonUpdate_Callback(handles.buttonUpdate, [], handles)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     OBJECT CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- executes on updating editUserName.
function editUserName_Callback(hObject, eventdata, handles)

% retrieves the user information data struct
uInfo = getappdata(handles.figUserInfo,'uInfo');
uInfo.Name = strtrim(get(hObject,'string'));
setappdata(handles.figUserInfo,'uInfo',uInfo)

% resets the update button enabled properties
setUpdateButtonProps(handles)

% --- executes on updating editUserName.
function editUserEmail_Callback(hObject, eventdata, handles)

% retrieves the user information data struct
uInfo = getappdata(handles.figUserInfo,'uInfo');

% determines if the new email is valid
nwEmail = strtrim(get(hObject,'string'));
if strContains(nwEmail,'@')
    % if so, then update the email field
    uInfo.Email = nwEmail;
    setappdata(handles.figUserInfo,'uInfo',uInfo)

    % resets the update button enabled properties
    setUpdateButtonProps(handles)    
else
    % if not, output an error message to screen
    eStr = 'Error! The entered email is invalid. Please retry.';
    waitfor(errordlg(eStr,'Invalid Email','modal'))

    % resets the editbox field to the last valid string
    set(hObject,'string',uInfo.Email)
end

% --- Executes on button press in buttonUpdate.
function buttonUpdate_Callback(hObject, eventdata, handles)

% global variables
global uInfo

% retrieves the user information data struct
uInfo = getappdata(handles.figUserInfo,'uInfo');

% deletes the GUI
delete(handles.figUserInfo)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                          OTHER FUNCTIONS                          %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- initialises the object properties
function initObjProps(handles,cStatus)

% retrieves the commiter information line
cLine = cStatus{strContains(cStatus,'Committer:')};
if isempty(cLine)
    % if the user information is not included, then use blank values
    [Name,Email] = deal([]);
else
    % otherwise, split the information from the status field
    
    % sets the user name
    Name = strtrim(cLine(12:strfind(cLine,'<')-2));
    
    % retrieves the user email
    Email0 = regexp(cLine,'<[^()]*>','match');
    Email = Email0{1}(2:end-1);
end

% initialises the user information data struct
setappdata(handles.figUserInfo,'uInfo',initUserInfoStruct(Name,Email));

% sets the gui object fields
set(handles.editUserName,'string',Name);
set(handles.editUserEmail,'string',Email);
setUpdateButtonProps(handles);

% --- initialises the 
function uInfo = initUserInfoStruct(Name,Email)

uInfo = struct('Name',Name,'Email',Email);

% --- sets the update button properties (based on the current info)
function setUpdateButtonProps(handles)

% retrieves the user information data struct
uInfo = getappdata(handles.figUserInfo,'uInfo');

% sets the button enabled properties (must has an email and name)
canUpdate = ~isempty(uInfo.Name) && ~isempty(uInfo.Email);
setObjEnable(handles.buttonUpdate,canUpdate);
