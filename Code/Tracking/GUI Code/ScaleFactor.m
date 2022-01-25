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
hFigM = varargin{1};
hType = varargin{2};

% resets the object font sizes
hGUI = guidata(hFigM);

% updates the scale factor value in the main GUI axes
switch hType
    case 'FlyTrack'
        hProp0 = disableAllTrackingPanels(hGUI);
    case 'FlyAnalysis'
        hProp0 = [];
end
        
% sets up the data struct
iData = struct('Lm',1,'Lp',0);
hAx = findobj(hFigM,'type','axes');
hEdit = findobj(hFigM,'tag','editScaleFactor');
setObjEnable(handles.buttonUpdate,'off')

% adds the object properties
addObjProps(hObject,'hGUI',hGUI,'hFigM',hFigM,'hAx',hAx,'hEdit',hEdit,...
                    'iData',iData,'hProp0',hProp0,'hType',hType);

% sets the other figure properties
setGUIFontSize(handles)
centreFigPosition(hObject,2);

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
hAx = get(hFig,'hAx');

% creates a new line object
axes(hAx)
hScale = imline(hAx);
setColor(hScale,'r');
set(hScale,'tag','hScale')

% sets the constraint/position callback functions
fcn = makeConstrainToRectFcn('imline',get(hAx,'XLim'),get(hAx,'YLim'));
setPositionConstraintFcn(hScale,fcn);
hScale.addNewPositionCallback(@(p)moveScaleMarker(p,handles));

% enables/disables the necessary buttons
setObjEnable(handles.buttonUpdate,'on')
setObjEnable(handles.buttonSet,'off')

% updates the scale marker
moveScaleMarker(hScale.getPosition(),handles);

% resets the figure stacks
uistack(handles.figScaleFactor,'top');
uistack(hFig.hFigM,'down',1);

% --- Executes on button press in buttonUpdate.
function buttonUpdate_Callback(hObject, eventdata, handles)

% global variables
global isCalib isRTPChange

% retrieves the main GUI handles and sub-GUI data struct
hFig = handles.figScaleFactor;
iData = get(hFig,'iData');
hFigM = get(hFig,'hFigM');

% calculates the scale factor and updates the scale factor values
sFac = calcScaleFactor(iData);

% updates the scale factor value in the main GUI axes
switch hFig.hType
    case 'FlyTrack'
        % updates the scale factor
        hFigM.iData.exP.sFac = sFac;
   
        % updates the scale factor in the real-time tracking parameters
        if isCalib
            [hFigM.rtP.trkP.sFac,isRTPChange] = deal(sFac,true);
        end        
        
    case 'FlyAnalysis'
        % updates the scale factor
        vpObj = getappdata(hFigM,'vpObj');
        vpObj.sFac(vpObj.iExpt) = sFac;
        vpObj.isChange = true;
end

% disables the update button
setObjEnable(hObject,'off')
set(hFig.hEdit,'string',num2str(sFac))

% --- Executes on button press in buttonClose.
function buttonClose_Callback(~, ~, handles)

% removes the scale marker from the main GUI axes
hFig = handles.figScaleFactor;

% deletes the scale marker
hScale = findobj(hFig.hAx,'Tag','hScale');
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
if ~isempty(hFig.hProp0)
    nwStr = get(hFig.hEdit,'string');
    resetHandleSnapshot(hFig.hProp0)
    set(hFig.hEdit,'string',nwStr)
end

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
