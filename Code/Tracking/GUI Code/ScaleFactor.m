function varargout = ScaleFactor(varargin)
% Last Modified by GUIDE v2.5 01-May-2013 01:39:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ScaleFactor_OpeningFcn, ...
                   'gui_OutputFcn',  @ScaleFactor_OutputFcn, ...
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

% --- Executes just before ScaleFactor is made visible.
function ScaleFactor_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for ScaleFactor
handles.output = hObject;

% sets the input arguments
hGUI = varargin{1};

% resets the object font sizes
setGUIFontSize(handles)
hProp0 = disableAllTrackingPanels(hGUI);
centreFigPosition(hObject);

% sets up the data struct
iData = struct('Lm',1,'Lp',0);
setObjEnable(handles.buttonUpdate,'off')

% adds the object properties
addObjProps(hObject,'hGUI',hGUI,'iData',iData,'hProp0',hProp0);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ScaleFactor wait for user response (see UIRESUME)
uiwait(handles.figScaleFactor);

% --- Outputs from this function are returned to the command line.
function varargout = ScaleFactor_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = [];

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes on editing in editScaleLength.
function editScaleLength_Callback(hObject, eventdata, handles)

% retrieves the new value
hFig = handles.figScaleFactor;

% determines if the new value is valid
nwVal = str2double(get(hObject,'string'));
if chkEditValue(nwVal,[0 inf],0)
    % updates the data struct with the new values
    hFig.iData.Lm = nwVal;
    
    % updates the data length
    calcNewLength(handles);
    setObjEnable(handles.buttonUpdate,'on');
else
    % otherwise, reset the last valid value
    set(hObject,'string',num2str(hFig.iData.Lm));
end

% --- Executes on button press in buttonSet.
function buttonSet_Callback(hObject, eventdata, handles)

% sets focus to the main image axes
hFig = handles.figScaleFactor;
hGUI = get(hFig,'hGUI');
axes(hGUI.imgAxes)

% creates a new line object
hScale = imline(gca);
setColor(hScale,'r');
set(hScale,'tag','hScale')

% sets the constraint/position callback functions
fcn = makeConstrainToRectFcn('imline',get(gca,'XLim'),get(gca,'YLim'));
setPositionConstraintFcn(hScale,fcn);
hScale.addNewPositionCallback(@(p)moveScaleMarker(p,handles));

% enables/disables the necessary buttons
setObjEnable(handles.buttonUpdate,'on')
setObjEnable(handles.buttonSet,'off')

% updates the scale marker
moveScaleMarker(hScale.getPosition(),handles);

% resets the figure stacks
uistack(handles.figScaleFactor,'top');
uistack(hGUI.figFlyTrack,'bottom')

% --- Executes on button press in buttonUpdate.
function buttonUpdate_Callback(hObject, eventdata, handles)

% global variables
global isCalib isRTPChange

% retrieves the main GUI handles and sub-GUI data struct
hFig = handles.figScaleFactor;
hGUI = get(hFig,'hGUI');
iData = get(hFig,'iData');

% calculates the scale factor and updates the scale factor values
sFac = calcScaleFactor(iData);

% updates the scale factor value in the main GUI axes
iDataMain = get(hGUI.figFlyTrack,'iData');
iDataMain.exP.sFac = sFac;
set(hGUI.figFlyTrack,'iData',iDataMain);

% updates the scale factor in the real-time tracking parameters
if isCalib
    [hGUI.figFlyTrack.rtP.trkP.sFac,isRTPChange] = deal(sFac,true);
end

% disables the update button
setObjEnable(hObject,'off')
set(hGUI.editScaleFactor,'string',num2str(sFac))

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% removes the scale marker from the main GUI axes
hFig = handles.figScaleFactor;
hGUI = get(hFig,'hGUI');
hProp0 = get(hFig,'hProp0');
hScale = findobj(hGUI.imgAxes,'Tag','hScale');
delete(hScale);

% determines if the update button has been set
if strcmp(get(handles.buttonUpdate,'enable'),'on')  
    % if so, then prompt the user if they wish to update the solution
    uChoice = questdlg('Do you wish to update the scale factor?',...
            'Update Scale Factor','Yes','No','Yes');
    switch uChoice
        case ('Yes')
            % the user chose to update
            buttonUpdate_Callback(handles.buttonUpdate, [], handles)
    end
end

% resets the tracking GUI properties
nwStr = get(hGUI.editScaleFactor,'string');
resetHandleSnapshot(hProp0)
set(hGUI.editScaleFactor,'string',nwStr)

% closes the scale factor sub-GUI
delete(hFig)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- callback for the scale length marker --- %
function moveScaleMarker(p,handles)

% updates the marker line distance
hFig = handles.figScaleFactor;
hFig.iData.Lp = sqrt(sum(diff(p,1).^2));

% updates the marker length string
calcNewLength(handles);
setObjEnable(handles.buttonUpdate,'on')

% --- calculates and sets the new scale factor length --- %
function sFac = calcNewLength(handles)

% field retrieval
hFig = handles.figScaleFactor;

% sets the scale factor depending if the scale length has been set
if hFig.iData.Lp == 0
    % if the data length has not been set, then set value as NaN
    sFac = NaN;
    set(handles.textScaleFactor,'string','N/A')
else
    % otherwise, calculate the value and update the scale factor string
    sFac = calcScaleFactor(hFig.iData);
    set(handles.textScaleFactor,'string',num2str(sFac))    
end

% --- calcualtes the scale factor dependent on the scale lengths --- %
function sFac = calcScaleFactor(iData)

% number of decimal places to round to
nDP = 4;

% calculates the scale factor
sFac = roundP((10^nDP)*iData.Lm/iData.Lp,1)/(10^nDP);
