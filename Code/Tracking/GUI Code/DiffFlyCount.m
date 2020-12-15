function varargout = DiffFlyCount(varargin)
% Last Modified by GUIDE v2.5 18-Nov-2016 07:40:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DiffFlyCount_OpeningFcn, ...
                   'gui_OutputFcn',  @DiffFlyCount_OutputFcn, ...
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

% --- Executes just before DiffFlyCount is made visible.
function DiffFlyCount_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for DiffFlyCount
handles.output = hObject;

% sets the input arguments
hMain = varargin{1};

% sets the arrays into the GUI
setappdata(hObject,'hMain',hMain)

% initialises the GUI objects and updates the sub-region data struct
setappdata(hMain,'iMov',initGUIObjects(handles,getappdata(hMain,'iMov')))

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes DiffFlyCount wait for user response (see UIRESUME)
% uiwait(handles.figDiffCount);

% --- Outputs from this function are returned to the command line.
function varargout = DiffFlyCount_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when entered data in editable cell(s) in tableDiffCount.
function tableDiffCount_CellEditCallback(hObject, eventdata, handles)

% determines if the function is called properly
if (isempty(eventdata.Indices))
    % if there are no indices, then exit the function
    return;
else
    % sets the row/column indices
    [iRow,iCol] = deal(eventdata.Indices(1),eventdata.Indices(2));
end

% retrieves the important object/arrays
hMain = getappdata(handles.figDiffCount,'hMain');
iMov = getappdata(hMain,'iMov');

% prompts the user if they wish to make the change
resetMovQuest = getappdata(hMain,'resetMovQuest');
if (resetMovQuest(guidata(hMain)))
    % if so, then update the data arrays    
    [iMov.nTubeR(iRow,iCol),iMov.isSet] = deal(eventdata.NewData,false);
    setappdata(hMain,'iMov',iMov)
    
    % disables the update button
    set(findall(hMain,'tag','buttonUpdate'),'enable','off')
else
    % otherwise, resets the table data to the last valid
    set(hObject,'Data',num2cell(iMov.nTubeR))
end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the GUI objects
function iMov = initGUIObjects(h,iMov)

% initialisations
fPos = get(h.figDiffCount,'position');

% sets the table row/column header strings and widths
[nRow,nCol] = deal(iMov.nRow,iMov.nCol);
[xiC,xiR,cWid0,dX] = deal(num2cell(1:nCol),num2cell(1:nRow),85,10);
cStr = cellfun(@(x)(sprintf('Column #%i',x)),xiC,'un',0);
rStr = cellfun(@(x)(sprintf('Row #%i',x)),xiR,'un',0);
cWid = num2cell(cWid0*ones(1,iMov.nCol));
cEdit = true(1,iMov.nCol);

% sets the regional fly count array
if (isempty(iMov.nTubeR))
    % no array is set, so create a new one
    [nFly,iMov.nTubeR] = deal(iMov.nTube*ones(iMov.nRow,iMov.nCol));
else
    % otherwise, use the previous array
    nFly = iMov.nTubeR;
end

% resets the figure position
drawnow('expose'); pause(0.05);
set(h.figDiffCount,'visible','on')

% updates the table properties
set(h.tableDiffCount,'rowname',rStr,'columnname',cStr,'columnwidth',cWid,...
                     'ColumnEditable',cEdit)                    
                 
% retrieves the table dimensions
[H0T,HWT,W0T] = getTableDimensions(findjobj(h.tableDiffCount));
tPos = [dX*[1 1],W0T+nCol*cWid0,H0T+nRow*HWT];
set(h.figDiffCount,'visible','off'); pause(0.05)

% reset GUI object positions
set(h.tableDiffCount,'position',tPos,'Data',num2cell(nFly));
set(h.panelDiffCount,'position',[dX*[1 1],tPos(3:4)+2*dX])
set(h.figDiffCount,'position',[fPos(1:2),tPos(3:4)+4*dX])

