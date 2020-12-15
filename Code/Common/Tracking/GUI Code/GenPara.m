function varargout = GenPara(varargin)
% Last Modified by GUIDE v2.5 24-Nov-2017 16:11:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GenPara_OpeningFcn, ...
                   'gui_OutputFcn',  @GenPara_OutputFcn, ...
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

% --- Executes just before GenPara is made visible.
function GenPara_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for GenPara
handles.output = hObject;

% initialises the object properties
gP = struct('avgSz',50,'k',0.2','useInv',false);
set(handles.editAvgSize,'string',num2str(gP.avgSz))
set(handles.editExpDecay,'string',num2str(gP.k))

% sets the input arguments
setappdata(hObject,'hGUI',varargin{1});
setappdata(hObject,'I',varargin{2});
setappdata(hObject,'gP',gP);

% removes the close request function
set(hObject,'CloseRequestFcn',[])

% updates the main tracking GUI axes
updateMainAxes(handles,1)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GenPara wait for user response (see UIRESUME)
uiwait(handles.figGenPara);

% --- Outputs from this function are returned to the command line.
function varargout = GenPara_OutputFcn(hObject, eventdata, handles) 

% global variables
global Bgen

% Get default command line output from handles structure
varargout{1} = Bgen;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ----------------------------------------- %
% --- EDITBOX OBJECT CALLBACK FUNCTIONS --- %
% ----------------------------------------- %

% --- executes on the callback of editAvgSize
function editAvgSize_Callback(hObject, eventdata, handles)

% check to see if the new value is valid
gP = getappdata(handles.figGenPara,'gP');
nwVal = str2double(get(hObject,'string'));

% determines if the new value is valid
if (chkEditValue(nwVal,[5 100],1))
    % if it is, then update the data struct
    gP.avgSz = nwVal;    
    setappdata(handles.figGenPara,'gP',gP);
    
    % updates the thresholded image
    updateMainAxes(handles,1)
else
    % otherwise, reset to the last valid value
    set(hObject,'string',num2str(gP.avgSz));      
end

% --- executes on the callback of editExpDecay
function editExpDecay_Callback(hObject, eventdata, handles)

% check to see if the new value is valid
gP = getappdata(handles.figGenPara,'gP');
nwVal = str2double(get(hObject,'string'));

% determines if the new value is valid
if (chkEditValue(nwVal,[0 1],0))
    % if it is, then update the data struct
    gP.k = nwVal;    
    setappdata(handles.figGenPara,'gP',gP);
    
    % updates the thresholded image
    updateMainAxes(handles,1)
else
    % otherwise, reset to the last valid value
    set(hObject,'string',num2str(gP.k));      
end

% --- Executes on button press in checkUseInv.
function checkUseInv_Callback(hObject, eventdata, handles)

% check to see if the new value is valid
gP = getappdata(handles.figGenPara,'gP');
gP.useInv = get(hObject,'value');
setappdata(handles.figGenPara,'gP',gP);

% updates the thresholded image
updateMainAxes(handles,1)

% ----------------------------------------- %
% --- CONTROL BUTTON CALLBACK FUNCTIONS --- %
% ----------------------------------------- %

% --- Executes on button press in buttonCont.
function buttonCont_Callback(hObject, eventdata, handles)

% global variables
global Bgen

% retrieves the main GUI axes handle data struct
Bgen = getappdata(handles.figGenPara,'Bgen');

% updates the main axes with the original image
updateMainAxes(handles,0)

% deletes the GUI
delete(handles.figGenPara)

% --- Executes on button press in buttonCancel.
function buttonCancel_Callback(hObject, eventdata, handles)

% global variables
global Bgen

% retrieves the main GUI axes handle data struct
Bgen = [];

% updates the main axes with the original image
updateMainAxes(handles,0)

% deletes the GUI
delete(handles.figGenPara)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% updates the main tracking GUI axes
function updateMainAxes(handles,useGenEst)

% retrieves the main GUI axes handle data struct
hGUI = getappdata(handles.figGenPara,'hGUI');

% retrieves the original background image
I = getappdata(handles.figGenPara,'I');    

% sets the new image based on the type
if (useGenEst)
    % updates the estimate image
    gP = getappdata(handles.figGenPara,'gP');
    Inw = bwmorph(sauvolaThresh(I,gP.avgSz*[1 1],gP.k),'erode');
    if (gP.useInv); Inw = ~rmvGroups(Inw); end
    
    % updates the estimate image into the GUI
    setappdata(handles.figGenPara,'Bgen',Inw)
else
    % uses the original image to update main axes
    Inw = I;
end

% updates the main GUI axes
set(findall(hGUI.imgAxes,'type','image'),'cdata',Inw);
