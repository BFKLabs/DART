function varargout = GlobalPara(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GlobalPara_OpeningFcn, ...
                   'gui_OutputFcn',  @GlobalPara_OutputFcn, ...
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

% --- Executes just before GlobalPara is made visible.
function GlobalPara_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global isChange
isChange = false;

% Choose default command line output for GlobalPara
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% sets the input arguments
hGUI = varargin{1};
gPara = getappdata(hGUI.figFlyAnalysis,'gPara');
hPara = getappdata(hGUI.figFlyAnalysis,'hPara');

% makes the main/parameter GUIs invisible
setObjVisibility(hGUI.figFlyAnalysis,'off')
if ~isempty(hPara); setObjVisibility(hPara,'off'); end

% determines if there are any y-values in the solution data. if there is,
% then disable the movement type (absolute location only)
snTot = getappdata(hGUI.figFlyAnalysis,'snTot');
if ~isempty(snTot(1).Py)
    setObjEnable(handles.popupMovType,'off')
end

% sets the data structs into the GUI
setappdata(hObject,'gPara',gPara);
setappdata(hObject,'hPara',hPara);
setappdata(hObject,'hGUI',hGUI);

% initialises the 
initEditObjects(handles)
initPopupObjects(handles)
setObjEnable(handles.buttonUpdate,'off')
setObjEnable(handles.buttonReset,'off')
centreFigPosition(hObject);

% UIWAIT makes GlobalPara wait for user response (see UIRESUME)
uiwait(handles.figGlobalPara);

% --- Outputs from this function are returned to the command line.
function varargout = GlobalPara_OutputFcn(hObject, eventdata, handles) 

% global variables
global gPara isChange

% Get default command line output from handles structure
varargout{1} = gPara;
varargout{2} = isChange;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ------------------------------------- %
% --- GUI OBJECT CALLBACK FUNCTIONS --- %
% ------------------------------------- %

% --- callback function for the edit box objects --- %
function editCallback(hObject, eventdata, handles)

% retrieves the global parameter struct
gPara = getappdata(handles.figGlobalPara,'gPara');
pStr = get(hObject,'userdata');
nwVal = str2double(get(hObject,'string'));

% sets the parameter limits/integer flags
switch (pStr)
    case ('Tgrp0') % case is the start of the day
        [nwLim,isInt] = deal([0 23.99],0);
    case ('TdayC') % case is the day cycle duration
        [nwLim,isInt] = deal([0 24],1);        
    case ('pWid') % case is the midline location
        [nwLim,isInt] = deal([0 1],0);
    case ('tNonR') % case is the post-stimuli non-reactive duration
        [nwLim,isInt] = deal([1 600],0);
    case ('nAvg') % case is the stimuli averaging time bin size
        [nwLim,isInt] = deal([1 300],1);
    case ('dMove') % case is the activity movement distance
        [nwLim,isInt] = deal([0 inf],0);
    case ('tSleep') % case is the inactivity sleep duration
        [nwLim,isInt] = deal([1 60],1);
end

% determines if the new value is valid
if (chkEditValue(nwVal,nwLim,isInt))
    % updates the parameter value
    if (isInt)
        % parameter is an integer
        eval(sprintf('gPara.%s = %i;',pStr,nwVal))
    else
        % parameter is a float
        eval(sprintf('gPara.%s = %f;',pStr,nwVal))
    end
    
    % resets the parameter struct and enables the update button
    setappdata(handles.figGlobalPara,'gPara',gPara)
    setObjEnable(handles.buttonReset,'on')
    setObjEnable(handles.buttonUpdate,'on')
    
else
    % resets the string to the previous value
    set(hObject,'string',eval(sprintf('gPara.%s',pStr)))
end

% --- callback function for the popup menu objects --- %
function popupCallback(hObject, eventdata, handles)

% retrieves the global parameter struct
gPara = getappdata(handles.figGlobalPara,'gPara');

% updates the global parameter struct
[popupStr,iSel] = deal(get(hObject,'string'),get(hObject,'value'));
gPara.movType = popupStr{iSel};

% resets the parameter struct and enables the update button
setappdata(handles.figGlobalPara,'gPara',gPara)
setObjEnable(handles.buttonUpdate,'on')

% ------------------------------- %
% --- PROGRAM CONTROL BUTTONS --- %
% ------------------------------- %

% --- Executes on button press in buttonReset.
function buttonReset_Callback(hObject, eventdata, handles)

% global variables
global isChange

% prompts the user if they wish to update the struct
uChoice = questdlg('Are sure you wish to update the default global parameters?',...        
                   'Reset Global Parameters?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    return
end

% overwrites the global parameter struct in the program parameter data file
gPara = getappdata(handles.figGlobalPara,'gPara');
save(getParaFileName('ProgPara.mat'),'gPara','-append');

% sets the change flag to true and disables the reset/update buttons
isChange = true;
setObjEnable(hObject,'off')
setObjEnable(handles.buttonUpdate,'off')

% --- Executes on button press in buttonUpdate.
function buttonUpdate_Callback(hObject, eventdata, handles)

% global variables
global isChange 

% prompts the user if they really do want to update
if (~isa(eventdata,'char'))
    % prompts the user if they wish to update the struct
    uChoice = questdlg({'Do you wish to update the global parameters?',...
            'Note - this will clear all current calculations'},...
            'Update Global Parameters?','Yes','No','Yes');
    if (~strcmp(uChoice,'Yes'))
        % user chose no or cancelled
        return
    end
end

% sets the change flag to true and disables the update button
isChange = true;
setObjEnable(hObject,'off')

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% global variables
global gPara isChange

% retrieves the global parameter struct
gPara = getappdata(handles.figGlobalPara,'gPara');
hPara = getappdata(handles.figGlobalPara,'hPara');
hGUI = getappdata(handles.figGlobalPara,'hGUI');

% if there is an update specified, then prompt the user to update
if strcmp(get(handles.buttonUpdate,'enable'),'on')
    % prompts the user if they wish to update the struct
    uChoice = questdlg({'Do you wish to update the global parameters?',...
            'Note - this will clear all current calculations'},...
            'Update Global Parameters?','Yes','No','Cancel','Yes');
    switch (uChoice)
        case ('Yes') % case is the user wants to update movie struct
            buttonUpdate_Callback(handles.buttonUpdate, '1', handles)            
        case ('No')
            [gPara,isChange] = deal([],false);
        otherwise
            return
    end
end

% closes the GUI
delete(handles.figGlobalPara);

% makes the main/parameter GUIs invisible
setObjVisibility(hGUI.figFlyAnalysis,'on')
if ~isempty(hPara); setObjVisibility(hPara,'on'); end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the GUI edit box object properties --- %
function initEditObjects(handles)

% retrieves the global parameter struct
gPara = getappdata(handles.figGlobalPara,'gPara');

% sets the panel object handle
hPanel = handles.panelPara;
hEdit = findall(hPanel,'style','edit');

% initialises all the editboxes in the GUI
for i = 1:length(hEdit)
    % sets the editbox callback function   
    hObj = hEdit(i);
    cbFcn = @(hObj,e)GlobalPara('editCallback',hObj,e,handles); 
    
    % sets the editbox properties
    pStr = num2str(eval(sprintf('gPara.%s',get(hEdit(i),'UserData'))));    
    set(hObj,'string',pStr,'callback',cbFcn)
end

% --- initialises the GUI edit box object properties --- %
function initPopupObjects(handles)

% retrieves the global parameter struct
gPara = getappdata(handles.figGlobalPara,'gPara');

% initialises the list strings
set(handles.popupMovType,'string',{'Absolute Location';'Midline Crossing'}')

% sets the panel object handle
hPanel = handles.panelPara;
hPopup = findall(hPanel,'style','popupmenu');

% initialises all the editboxes in the GUI
for i = 1:length(hPopup)
    % sets the editbox callback function   
    hObj = hPopup(i);
    cbFcn = @(hObj,e)GlobalPara('popupCallback',hObj,e,handles); 
    
    % determines the item that is to be selected
    pStr = eval(sprintf('gPara.%s',get(hPopup(i),'UserData')));    
    iSel = find(strcmp(pStr,get(hObj,'string')));
    
    % sets the popup menu properties    
    set(hObj,'callback',cbFcn,'value',iSel)
end
