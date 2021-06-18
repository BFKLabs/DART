function varargout = GenPara(varargin)
% Last Modified by GUIDE v2.5 06-Feb-2021 03:24:35

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

% input arguments
iMov = varargin{1};
B0 = varargin{2};
nDil = varargin{3};
x0 = varargin{4};
y0 = varargin{5};
hProg = varargin{6};

% sets the progressbar to be invisible
hProg.setVisibility(false);

% retrieves the fly tracking handle
hGUI = findall(0,'tag','figFlyTrack');
hAx = findall(hGUI,'type','axes');

% sets the input arguments
setappdata(hObject,'iMov',iMov);
setappdata(hObject,'B0',B0);
setappdata(hObject,'nDil',nDil);
setappdata(hObject,'x0',x0);
setappdata(hObject,'y0',y0);
setappdata(hObject,'hProg',hProg);

% sets the other important fields
setappdata(hObject,'hGUI',hGUI);
setappdata(hObject,'hAx',hAx);

% initialises the object properties
set(handles.editBinaryDil,'string',num2str(nDil))

% updates the main tracking GUI axes
updateMainAxes(handles)
uistack(hGUI,'top');
centreFigPosition(hObject);

% removes the close request function
set(hObject,'CloseRequestFcn',[])

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GenPara wait for user response (see UIRESUME)
uiwait(handles.figGenPara);

% --- Outputs from this function are returned to the command line.
function varargout = GenPara_OutputFcn(hObject, eventdata, handles) 

% global variables
global BC

% Get default command line output from handles structure
varargout{1} = BC;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ----------------------------------------- %
% --- EDITBOX OBJECT CALLBACK FUNCTIONS --- %
% ----------------------------------------- %

% --- executes on the callback of editBinaryDil
function editBinaryDil_Callback(hObject, eventdata, handles)

% check to see if the new value is valid
nDil = getappdata(handles.figGenPara,'nDil');
nwVal = str2double(get(hObject,'string'));

% determines if the new value is valid
if chkEditValue(nwVal,[0 20],1)
    % if it is, then update the dilation parameter and the main axes
    setappdata(handles.figGenPara,'nDil',nwVal);   
    updateMainAxes(handles)
    
else
    % otherwise, reset to the last valid value
    set(hObject,'string',num2str(nDil));      
end

% ----------------------------------------- %
% --- CONTROL BUTTON CALLBACK FUNCTIONS --- %
% ----------------------------------------- %

% --- Executes on button press in buttonCont.
function buttonCont_Callback(hObject, eventdata, handles)

% global variables
global BC

% retrieves the main GUI axes handle data struct
hFig = handles.figGenPara;
hProg = getappdata(hFig,'hProg');

% retrieves the current binary
BC = expandBinaryMask(handles);

% updates the main axes and deletes the gui
deleteTempMarkers(hFig);
delete(hFig)

% makes the progressbar visible again
hProg.setVisibility(true);

% --- Executes on button press in buttonCancel.
function buttonCancel_Callback(hObject, eventdata, handles)

% global variables
global BC

% retrieves the main GUI axes handle data struct
BC = [];

% retrieves the main GUI axes handle data struct
hFig = handles.figGenPara;
hProg = getappdata(hFig,'hProg');

% closes the progressbar
hProg.closeProgBar();

% updates the main axes and deletes the gui
deleteTempMarkers(hFig);
delete(hFig)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% updates the main tracking GUI axes
function updateMainAxes(handles)

% initialisations
hFig = handles.figGenPara;
x0 = getappdata(hFig,'x0');
y0 = getappdata(hFig,'y0');
hAx = getappdata(hFig,'hAx');
iMov = getappdata(hFig,'iMov');

% retrieves the main GUI axes handle data struct
BC = expandBinaryMask(handles);
[xC,yC] = getBinaryCoords(BC);

% retrieves the object handles of the outlines
hOut = findall(hAx,'tag','hOuter');
createMark = isempty(hOut);

% sets the group colour array (based on the format)
if isfield(iMov,'pInfo')
    tCol = getAllGroupColours(length(iMov.pInfo.gName));
else
    tCol = getAllGroupColours(1);
end

% sets the hold on the main GUI image axes 
hold(hAx,'on');

% loops through all the sub-regions plotting the circles   
for iCol = 1:iMov.nCol
    % sets the row indices
    if isfield(iMov,'pInfo')
        iGrp = iMov.pInfo.iGrp(:,iCol);
        iRow = find(iGrp' > 0);
    else
        iRow = 1:iMov.nTubeR(iCol);
        iGrp = ones(length(iRow),1);
    end    
    
    % retrieves the global row/column index
    for j = iRow
        % calculates the new coordinates and plots the circle
        [xP,yP] = deal(x0(j,iCol)+xC,y0(j,iCol)+yC);
        
        % creates/updates the marker coordinates
        if createMark
            % outline marker needs to be created
            pCol = tCol(iGrp(j)+1,:);
            fill(xP,yP,pCol,'tag','hOuter','UserData',[iCol,j],...
                   'facealpha',0.25,'LineWidth',1.5,'Parent',hAx) 
               
        else
            % otherwise, coordinates of outline
            hP = findobj(hOut,'UserData',[iCol,j]);
            set(hP,'xData',xP,'yData',yP)
        end               
    end
end

% sets the hold off again
hold(hAx,'off');

% --- calculates the outline coordinate fo the binary mask, BC
function [xC,yC,pOfs] = getBinaryCoords(BC)

% initialisations
szL = size(BC);
pOfs = szL([2,1])/2;

% calculates the final object outline coordinates 
c = contourc(double(BC),0.5*[1,1]);
xC = roundP(c(1,2:end)'-pOfs(1));
yC = roundP(c(2,2:end)'-pOfs(2));

% --- returns the expanded binary mask
function BC = expandBinaryMask(handles)

% retrieves the important fields
hFig = handles.figGenPara;
B0 = getappdata(hFig,'B0');
nDil = getappdata(hFig,'nDil');

% sets the binary image for calculating the region outline coordinates
while 1
    % dilates the original image
    BC = bwmorph(B0,'dilate',nDil);
    
    % determines if any points lie on the image edge
    if any(BC(bwmorph(true(size(B0)),'remove')))
        % if so, then expand the image
        B0 = padarray(B0,[1,1]);
        
    else
        % otherwise, exit the loop
        break
    end
end

% --- deletes the temporary markers from the main gui axes
function deleteTempMarkers(hFig)

hOut = findall(getappdata(hFig,'hAx'),'tag','hOuter');
if ~isempty(hOut); delete(hOut); end
