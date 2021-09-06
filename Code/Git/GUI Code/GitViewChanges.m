function varargout = GitViewChanges(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GitViewChanges_OpeningFcn, ...
                   'gui_OutputFcn',  @GitViewChanges_OutputFcn, ...
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


% --- Executes just before GitViewChanges is made visible.
function GitViewChanges_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for GitViewChanges
handles.output = hObject;

% initialises the object properties
initObjProps(handles, varargin{1})

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GitViewChanges wait for user response (see UIRESUME)
% uiwait(handles.figGitChanges);

% --- Outputs from this function are returned to the command line.
function varargout = GitViewChanges_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     FIGURE CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when user attempts to close figGitChanges.
function figGitChanges_CloseRequestFcn(hObject, eventdata, handles)

% closes the gui
buttonClose_Callback(handles.buttonClose, [], handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     OBJECT CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% closes the gui
delete(handles.figGitChanges)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                          OTHER FUNCTIONS                          %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- initialises the GUI object properties
function initObjProps(handles,GF)

% retrieves the branch status strings
tWid = get(handles.tableBranchDiff,'Position');
modStatus = strsplit(GF.gitCmd('branch-status',1),'\n')';            
                
% retrieves the modified file/types
modFile = cellfun(@(x)(strrep(x(4:end),'"','')),modStatus,'un',0);
modType0 = cellfun(@(x)(strtrim(x(1:2))),modStatus,'un',0);
modType = cellfun(@(x)(getDiffType(x)),modType0,'un',0);

% retrieves the modified names/directories
modDir = cellfun(@(x)(fileparts(x)),modFile,'un',0);
modName = cellfun(@(x)(getFileName(x,1)),modFile,'un',0);

% sets the table column widths
cWid = zeros(1,3);
cWid(1:2) = [60,100];
cWid(3) = tWid(3) - sum(cWid);

% sets the table data/properties
[~,iS] = sort(modDir);
tData = [modType(iS),modName(iS),modDir(iS)];
set(handles.tableBranchDiff,'Data',tData,'ColumnWidth',num2cell(cWid));
autoResizeTableColumns(handles.tableBranchDiff)

% --- gets the difference type string
function dType = getDiffType(abbStr)

% retrieves the difference string based on the abbreviation type
switch abbStr
    case 'AA'
        dType = 'Added';
        
    case {'M','??'}
        dType = 'Modified';
    
end
