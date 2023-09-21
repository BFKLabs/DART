function varargout = SolnMetricPara(varargin)% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SolnMetricPara_OpeningFcn, ...
                   'gui_OutputFcn',  @SolnMetricPara_OutputFcn, ...
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


% --- Executes just before SolnMetricPara is made visible.
function SolnMetricPara_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for SolnMetricPara
handles.output = hObject;

% retrieves the input arguments
hFigM = varargin{1};

% sets the main fields into the gui
setappdata(hObject,'hFigM',hFigM);
setappdata(hObject,'iPara',get(hFigM,'iPara'));

% initialises the object properties
initObjProps(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SolnMetricPara wait for user response (see UIRESUME)
% uiwait(handles.figMetricPara);


% --- Outputs from this function are returned to the command line.
function varargout = SolnMetricPara_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        OBJECT CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ------------------------------------ %
% --- SPEED CALCULATION PARAMETERS --- %
% ------------------------------------ %

% --- Executes when selected object is changed in panelDerivType.
function panelDerivType_SelectionChangedFcn(hObject, eventdata, handles)

% field retrieval
iPara = getappdata(handles.output,'iPara');

% updates the parameter struct
hRadio = findall(handles.panelDerivType,'Value',1);
iPara.vP.Type = get(hRadio,'UserData');
setappdata(handles.output,'iPara',iPara)

% enables the update button (if not initialising)
setObjEnable(handles.buttonUpdate,'on')

% --- Executes on updating editWindowSize
function editWindowSize_Callback(hObject, eventdata, handles)

% initialisations
nwVal = str2double(get(hObject,'String'));
iPara = getappdata(handles.output,'iPara');

% determines if the new value is valid
if chkEditValue(nwVal,[1,20],1)
    % if so, then update the parameter struct
    iPara.vP = setStructField(iPara.vP,'nPts',nwVal);
    setappdata(handles.output,'iPara',iPara);
    
    % enables the update button
    setObjEnable(handles.buttonUpdate,'on')    
else
    % otherwise, reset to the last valid value
    set(hObject,'string',num2str(iPara.vP.nPts))
end

% ----------------------- %
% --- CONTROL BUTTONS --- %
% ----------------------- %

% --- Executes on button press in buttonUpdate.
function buttonUpdate_Callback(hObject, eventdata, handles)

% updates the parameter struct in the solution viewing gui
hFigM = getappdata(handles.output,'hFigM');
set(hFigM,'iPara',getappdata(handles.output,'iPara'));

% updates the trace plot
hFigM.updateFunc(guidata(hFigM))

% disables the update button
setObjEnable(hObject,'off')

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% if there was a change, prompt the user if they wish to close
if strcmp(get(handles.buttonUpdate,'Enable'),'on')
    qStr = 'Do you want to update your changes before closing?';
    uChoice = questdlg(qStr,'Update Changes?','Yes','No','Cancel','Yes');
    switch uChoice
        case 'Yes'
            % user chose to update
            buttonUpdate_Callback(handles.buttonUpdate, [], handles)
            
        case 'No'
            % user chose to not update (do nothing...)
            
        otherwise
            % otherwise, the user cancelled
            return
    end
end

% removes the menu item checkmark
hFigM = getappdata(handles.output,'hFigM');
hMenu = findall(hFigM,'tag','menuMetricOptions');
set(hMenu,'Checked','off');

% closes the gui
delete(handles.output)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the gui object properties
function initObjProps(handles)

% field retrieval
iPara = getappdata(handles.output,'iPara');

% sets the derivative method type radio button
hRadio = findall(handles.panelDerivType,'UserData',iPara.vP.Type);
set(hRadio,'Value',1);

% sets derivative sizes
set(handles.editWindowSize,'String',num2str(iPara.vP.nPts))

% turns off the update button 
setObjEnable(handles.buttonUpdate,0);
