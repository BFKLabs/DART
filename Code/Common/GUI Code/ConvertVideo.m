function varargout = ConvertVideo(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ConvertVideo_OpeningFcn, ...
                   'gui_OutputFcn',  @ConvertVideo_OutputFcn, ...
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


% --- Executes just before ConvertVideo is made visible.
function ConvertVideo_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for ConvertVideo
handles.output = hObject;

% sets the input arguments
if isempty(varargin)
    iProg = [];
else
    iProg = varargin{1};
end

% initialises the object properties
initObjProps(handles)

% sets the other fields
setappdata(hObject,'iProg',iProg);
setappdata(hObject,'iData',initDataStruct());

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ConvertVideo wait for user response (see UIRESUME)
% uiwait(handles.figConvertVideo);


% --- Outputs from this function are returned to the command line.
function varargout = ConvertVideo_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when user attempts to close figConvertVideo.
function figConvertVideo_CloseRequestFcn(hObject, eventdata, handles)

% runs the close window button
buttonClose_Callback(handles.buttonClose, [], handles)

%-------------------------------------------------------------------------%
%                         OTHER CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes on selection change in popupCompressionType.
function popupCompressionType_Callback(hObject, eventdata, handles)

% --- Executes on selection change in listVideo.
function listVideo_Callback(hObject, eventdata, handles)

% initialisations
iSel = get(hObject,'Value');
hTxt = handles.textVideoPath;
iData = getappdata(handles.figConvertVideo,'iData');

% updates the video path field
if length(iSel) == 1
    % case is only one file was selected
    fDir = iData.fDir{iSel};
    set(hTxt,'String',simpFileName(fDir,15),'TooltipString',fDir)
else
    % case is multiple files were selected
    set(hTxt,'String','Multiple Files Selected...','TooltipString','')
end

% enables the remove button
setObjEnable(handles.buttonRemove,1)

% --------------------------------------- %
% ---- LIST CONTROL BUTTON CALLBACKS ---- %
% --------------------------------------- %

% --- Executes on button press in buttonAdd.
function buttonAdd_Callback(hObject, eventdata, handles)

% initialisations
iProg = getappdata(handles.figConvertVideo,'iProg');
iData = getappdata(handles.figConvertVideo,'iData');

% retrieves the default directory
if isempty(iProg)
    dDir = pwd;
else
    dDir = iProg.DirMov;
end

% prompts the user for the output file name/directory
fMode = {'*.avi;*.mp4;*.mj2;*.mj2',...
         'Video Files (*.avi, *.mp4, *.mj2, *.mkv)'};
[fName,fDir,fIndex] = uigetfile(fMode,'Load Video Files',dDir,...
                                'MultiSelect','on');
if fIndex == 0
    % if the user cancelled, then exit the function
    return
elseif ~iscell(fName)
    fName = {fName};    
end

% determines which files can be added to the list
if isempty(iData.fName)
    % if there are no existing files, then add all selected files
    isAdd = true(length(fName),1);
else
    % retrieves the full path of the existing files in the list
    fFilePr = cellfun(@(x,y)(fullfile(x,y)),iData.fDir,iData.fName,'un',0);
    
    % determines if the new files are not already in the existing list
    fFileNw = cellfun(@(x)(fullfile(fDir,x)),fName,'un',0);
    isAdd = cellfun(@(x)(~any(strcmp(fFilePr,x))),fFileNw);
    
    % if there are no unique files, then exit the function
    if ~any(isAdd); return; end
end

% updates the video file details
iData.fName = [iData.fName;arr2vec(fName(isAdd))];
iData.fDir = [iData.fDir;repmat({fDir},sum(isAdd),1)];
setappdata(handles.figConvertVideo,'iData',iData)

% updates the other object properties
setObjEnable(handles.buttonRemove,0);
setObjEnable(handles.buttonConvert,1);
set(handles.listVideo,'String',iData.fName,'Value',[]);

% --- Executes on button press in buttonRemove.
function buttonRemove_Callback(hObject, eventdata, handles)

% determines which videos are to remain
iSel = get(handles.listVideo,'Value');
nVid = length(get(handles.listVideo,'String'));
isOK = ~setGroup(iSel(:),[nVid,1]);

% determines which files can be added to the list
iData = getappdata(handles.figConvertVideo,'iData');
[iData.fDir,iData.fName] = deal(iData.fDir(isOK),iData.fName(isOK));
setappdata(handles.figConvertVideo,'iData',iData)

% resets the video path/listbox strings
set(handles.textVideoPath,'String','')
set(handles.listVideo,'String',iData.fName,'Value',[])

% updates the button enabled properties
setObjEnable(hObject,false);
setObjEnable(handles.buttonConvert,~isempty(iData.fName))

% ---------------------------------- %
% ---- CONTROL BUTTON CALLBACKS ---- %
% ---------------------------------- %

% --- Executes on button press in buttonConvert.
function buttonConvert_Callback(hObject, eventdata, handles)

% initialisations
hFig = handles.figConvertVideo;
hPopup = handles.popupCompressionType;
iData = getappdata(hFig,'iData');
vFile = cellfun(@(x,y)(fullfile(x,y)),iData.fDir,iData.fName,'un',0);
[iSel,lStr] = deal(get(hPopup,'Value'),get(hPopup,'UserData'));

% converts the selected video files
setObjVisibility(hFig,0)
isOK = convertVideoFormat(vFile,lStr{iSel});
setObjVisibility(hFig,1)

% removes the files that were fully converted
[iData.fDir,iData.fName] = deal(iData.fDir(~isOK),iData.fName(~isOK));
setappdata(handles.figConvertVideo,'iData',iData)

% updates the other object properties
setObjEnable(handles.buttonRemove,0)
setObjEnable(handles.buttonConvert,~isempty(iData.fName))
set(handles.listVideo,'String',iData.fName,'Value',[]);
set(handles.textVideoPath,'string','')

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% deletes the GUI
delete(handles.figConvertVideo);

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the object properties
function initObjProps(handles)

% initialisations
hPopup = handles.popupCompressionType;

% retrieves the video profiles names/file extensions
vidProf = num2cell(VideoWriter.getProfiles());
pStr = cellfun(@(x)(x.Name),vidProf,'un',0)';
uStr = cellfun(@(x)(x.FileExtensions{1}),vidProf,'un',0)';

% sets the popup strings/user data
pStrF = cellfun(@(x,y)(sprintf('%s (*%s)',x,y)),pStr,uStr,'un',0);
set(hPopup,'string',pStrF,'UserData',pStr,'Value',1)
set(handles.textVideoPath,'string','')

% sets up the add/remove button icons
[Iplus,Iminus] = setupButtonIcons();
set(handles.buttonAdd,'CData',Iplus)
set(handles.buttonRemove,'CData',Iminus)

% disables the remove/convert buttons
setObjEnable(handles.buttonRemove,0)
setObjEnable(handles.buttonConvert,0)

% --- initialises the data struct
function iData = initDataStruct()

iData = struct('fDir',[],'fName',[]);

% --- sets up the add/remove button icons
function [Iplus,Iminus] = setupButtonIcons()

% memory allocation
sz = 16*[1,1];
Iminus = zeros(sz);

% initialises the minus/plus icons
Iminus(8:9,3:14) = 1;
Iplus = min(1,Iminus + Iminus');

% finalises the minus icon
Iminus(~Iminus) = NaN;
Iminus = 1 - repmat(Iminus,[1,1,3]);

% finalises the plus icon
Iplus(~Iplus) = NaN;
Iplus = 1 - repmat(Iplus,[1,1,3]);
