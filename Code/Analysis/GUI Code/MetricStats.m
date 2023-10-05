function varargout = MetricStats(varargin)
% Last Modified by GUIDE v2.5 11-Oct-2016 09:04:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MetricStats_OpeningFcn, ...
                   'gui_OutputFcn',  @MetricStats_OutputFcn, ...
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

% --- Executes just before MetricStats is made visible.
function MetricStats_OpeningFcn(hObject, ~, handles, varargin)

% global variables
global isChange
isChange = false;

% Choose default command line output for MetricStats
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% sets the input variables
iData = varargin{1};
iRow = varargin{2};
pInd = varargin{3};

% sets the metric indices
metInd = iData.tData.iPara{iData.cTab}{pInd}{2}(iRow,:);
setappdata(hObject,'metInd',metInd)

% initialises the GUI objects
initObjProps(handles)

% UIWAIT makes MetricStats wait for user response (see UIRESUME)
uiwait(handles.figStatMet);

% --- Outputs from this function are returned to the command line.
function varargout = MetricStats_OutputFcn(~, ~, ~) 

% global variables
global metInd isChange

% Get default command line output from handles structure
varargout{1} = metInd;
varargout{2} = isChange;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ------------------------------ %
% --- CONTROL BUTTON OBJECTS --- %
% ------------------------------ %

% --- Executes on button press in buttonUpdate.
function buttonUpdate_Callback(~, ~, handles)

% global variables
global metInd isChange
isChange = true;

% retrieves the important data structs and GUI handles
metInd = getappdata(handles.figStatMet,'metInd');

% deletes the GUI and makes the main GUI visible
delete(handles.figStatMet)

% --- Executes on button press in buttonClose.
function buttonClose_Callback(~, ~, handles)

% global variables
global metInd isChange 

% retrieves the important data structs and GUI handles
metInd = getappdata(handles.figStatMet,'metInd');

% determines if a change took place
if strcmp(get(handles.buttonUpdate,'enable'),'on')
    % prompts the user if they wish to update the changes
    uChoice = questdlg('Do you want to update the changes before closing?',...
                       'Update Changes?','Yes','No','Cancel','Yes');
    switch (uChoice)
        case ('Yes') % case is updating                    
            buttonUpdate_Callback(handles.buttonUpdate, 1, handles)
            return
        case ('No')
            isChange = false;
        otherwise % case is cancelling
            % exit the function
            return            
    end
end

% deletes the GUI and makes the main GUI visible
delete(handles.figStatMet)

% ----------------------------------- %
% --- CHECKBOX CALLBACK FUNCTIONS --- %
% ----------------------------------- %

% --- callback function for the statistical metric checkboxes
function statMetricCallback(hObject, ~)

% global variables
global isChange
isChange = true;

% sets the object handles
handles = guidata(hObject);
iSel = var2indStat(get(hObject,'UserData'));

% updates the metric index array
metInd = getappdata(handles.figStatMet,'metInd');
metInd(iSel) = get(hObject,'value');

% determines if any of the metric indices have been set
if ~any(metInd)
    % if not, then output an error to screen
    eStr = 'Error! At least one metric statistical type has to be set';
    waitfor(errordlg(eStr,'Incorrect Metric Selection','modal'))
    
    % resets the object value to being true
    set(hObject,'value',1)
else
    % otherwise, update the index array and enable the update button
    setappdata(handles.figStatMet,'metInd',metInd);
    setObjEnable(handles.buttonUpdate,'on')
end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --------------------------------- %
% --- OBJECT PROPERTY FUNCTIONS --- %
% --------------------------------- %

% initialises the GUI object properties
function initObjProps(handles,varargin)

% retrieves the important data structs and GUI handles
metInd = getappdata(handles.figStatMet,'metInd');
metVar = cellfun(@(x)(ind2varStat(x)),num2cell(find(metInd)),'UniformOutput',0);

% initialises the statistical metric checkboxes
hChk = findall(handles.panelStatMetrics,'style','checkbox');

% sets the checkbox callback functions (if initialising)
for i = 1:length(hChk)
    % sets the callback function
    set(hChk(i),'Callback',{@statMetricCallback})
    set(hChk(i),'value',any(strcmp(metVar,get(hChk(i),'UserData'))))
end

% disables the update button
setObjEnable(handles.buttonUpdate,'off')

% --- returns the index of a statistic metric variable
function ind = var2indStat(vName)

% returns the index based on the variable name string
switch (vName)
    case ('mn') % case is the mean
        ind = 1;
    case ('md') % case is the median
        ind = 2;        
    case ('lq') % case is the lower quartile
        ind = 3;        
    case ('uq') % case is the upper quartile
        ind = 4;        
    case ('rng') % case is the range
        ind = 5;        
    case ('ci') % case is the confidence interval
        ind = 6;        
    case ('sd') % case is the standard deviation
        ind = 7;        
    case ('sem') % case is the standard error mean
        ind = 8;        
    case ('min') % case is the minimum
        ind = 9;        
    case ('max') % case is the maximum
        ind = 10;        
end