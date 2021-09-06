function varargout = MasterMerge(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MasterMerge_OpeningFcn, ...
                   'gui_OutputFcn',  @MasterMerge_OutputFcn, ...
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

% --- Executes just before MasterMerge is made visible.
function MasterMerge_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for MasterMerge
handles.output = hObject;

% sets the input arguments
setappdata(hObject,'gHistM',varargin{1});
setappdata(hObject,'sType',varargin{2});

% initialises the object properties
initObjProps(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes MasterMerge wait for user response (see UIRESUME)
uiwait(handles.figMasterMerge);

% --- Outputs from this function are returned to the command line
function varargout = MasterMerge_OutputFcn(hObject, eventdata, handles) 

% global variables
global gHistFin iSelM

% Get default command line output from handles structure
varargout{1} = gHistFin;
varargout{2} = iSelM;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when user attempts to close figMasterMerge.
function figMasterMerge_CloseRequestFcn(hObject, eventdata, handles)

% closes the GUI without continuing
buttonCancel_Callback(handles.buttonCancel, '1', handles)

%-------------------------------------------------------------------------%
%                        OTHER CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% --- Executes on button press in buttonCont.
function buttonCont_Callback(hObject, eventdata, handles)

% global variables
global gHistFin iSelM

% retrieves the master history/table data
Data = get(handles.tableMasterCommits,'Data');
gHistM = getappdata(handles.figMasterMerge,'gHistM');

% returns the selected master commit information and closes the GUI
iSelM = find(cell2mat(Data(:,end)));
gHistFin = gHistM(iSelM);
delete(handles.figMasterMerge)

% --- Executes on button press in buttonCancel.
function buttonCancel_Callback(hObject, eventdata, handles)

% global variables
global gHistFin iSelM

% returns no master commit information and closes the GUI
[gHistFin,iSelM] = deal([]);
delete(handles.figMasterMerge)

% --- Executes when selected cell(s) is changed in tableMasterCommits.
function tableMasterCommits_CellSelectionCallback(hObject, eventdata, handles)

% if there are no indices, then exit the function
if isempty(eventdata.Indices); return; end

% sets the row/column indices of the change
Data = get(hObject,'Data');
[iRow,iCol] = deal(eventdata.Indices(1),eventdata.Indices(2));

% removes any existing checks (if the check is unique)
if ~Data{iRow,iCol}
    Data(:,iCol) = {false};    
end

% resets the table data
Data{iRow,iCol} = true;
set(hObject,'Data',Data)
    
%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the object properties within the GUI
function initObjProps(handles)

% global variables
global H0T HWT

% retrieves the important data struct/objects
hFig = handles.figMasterMerge;
gHistM = getappdata(hFig,'gHistM');
nC = length(gHistM);
isUse = num2cell(setGroup(1,[nC,1]));

% sets the table data
cID = cellfun(@(x)(x(1:7)),field2cell(gHistM,'ID'),'un',0);
Data = [cID,field2cell(gHistM,'Comment'),isUse];
set(handles.tableMasterCommits,'Data',Data)

% calculates the offset
tPos = get(handles.tableMasterCommits,'Position');
dY = (H0T + nC*HWT) - tPos(4);

% resets the object dimensions
resetObjPos(hFig,'Height',dY,1)
resetObjPos(handles.panelMasterCommits,'Height',dY,1)
resetObjPos(handles.tableMasterCommits,'Height',dY,1)

% resizes the table columns
autoResizeTableColumns(handles.tableMasterCommits)

% updates the other object names
sType = getappdata(hFig,'sType');
set(hFig,'name',sprintf('Set The Master %s Point',sType));
set(handles.buttonCont,'string',sprintf('Continue With %s',sType));