function varargout = CircPara(varargin)
% Last Modified by GUIDE v2.5 09-Dec-2015 18:35:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CircPara_OpeningFcn, ...
                   'gui_OutputFcn',  @CircPara_OutputFcn, ...
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

% --- Executes just before CircPara is made visible.
function CircPara_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for CircPara
handles.output = hObject;

% global variables
global hQ R

% sets the input variables
hGUI = varargin{1};
iMov = varargin{2};
X = varargin{3};
Y = varargin{4};
R = varargin{5};
hQ = varargin{6};

% sets the input variables/data structs into the GUI
setappdata(handles.figCircPara,'hGUI',hGUI)
setappdata(handles.figCircPara,'iMov',iMov)
setappdata(handles.figCircPara,'X',X)
setappdata(handles.figCircPara,'Y',Y)

% sets the editbox string and button enabled properties
set(handles.editCircRad,'string',num2str(R))
set(handles.editWeightIndex,'string',num2str(hQ))
set(handles.buttonRecalcCirc,'enable','off')

% plots the circle regions on the main GUI
plotCircleRegions(handles)
centreFigPosition(hObject);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes CircPara wait for user response (see UIRESUME)
uiwait(handles.figCircPara);

% --- Outputs from this function are returned to the command line.
function varargout = CircPara_OutputFcn(hObject, eventdata, handles) 

% global variables
global iMov hQ uChoice

% Get default command line output from handles structure
varargout{1} = iMov;
varargout{2} = hQ;
varargout{3} = uChoice;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ----------------------------------------- %
% --- EDITBOX OBJECT CALLBACK FUNCTIONS --- %
% ----------------------------------------- %

% --- executes on the callback of editCircRad
function editCircRad_Callback(hObject, eventdata, handles)

% global variables
global R RnwTol Rmax   

% check to see if the new value is valid
nwVal = str2double(get(hObject,'string'));
if (chkEditValue(nwVal,[RnwTol Rmax],1))
    % if it is, then update the data struct
    R = nwVal;    
    plotCircleRegions(handles)
else
    % otherwise, reset to the last valid value
    set(hObject,'string',num2str(R));      
end

% --- executes on the callback of editWeightIndex
function editWeightIndex_Callback(hObject, eventdata, handles)

% global variables
global hQ

% check to see if the new value is valid
nwVal = str2double(get(hObject,'string'));
if (chkEditValue(nwVal,[0.01 1.00],0))
    % if it is, then update the data struct
    hQ = nwVal;    
    set(handles.buttonRecalcCirc,'enable','on')
else
    % otherwise, reset to the last valid value
    set(hObject,'string',num2str(hQ));      
end

% ---------------------------------------- %
% --- BUTTON OBJECT CALLBACK FUNCTIONS --- %
% ---------------------------------------- %

% --- Executes on button press in buttonRecalcCirc.
function buttonRecalcCirc_Callback(hObject, eventdata, handles)

% global variables
global uChoice iMov

% retrieves the main GUI axes handle data struct
hGUI = getappdata(handles.figCircPara,'hGUI');
hGUIM = getappdata(hGUI.figWinSplit,'hGUI');

% retrieves the main GUI handles data struct
hOut = findall(hGUIM.imgAxes,'tag','hOut');
if (~isempty(hOut)); set(hOut,'visible','off'); end

% sets the user choice and closes the window
[uChoice,iMov] = deal('Recalc',[]); 
delete(handles.figCircPara) 

% --- Executes on button press in buttonCont.
function buttonCont_Callback(hObject, eventdata, handles)

% global variables
global uChoice iMov R 

% retrieves the sub-image data struct and circle centre X/Y coordinates
X = getappdata(handles.figCircPara,'X');
Y = getappdata(handles.figCircPara,'Y');
iMov = getappdata(handles.figCircPara,'iMov');
hGUI = getappdata(handles.figCircPara,'hGUI');

% retrieves the main GUI axes image
nTubeMax = max(getFlyCount(iMov,1));
hGUIM = getappdata(hGUI.figWinSplit,'hGUI');
I = get(findobj(get(hGUIM.imgAxes,'children'),'type','image'),'cdata');
sz = size(I); 

% parameters and memory allocation
[pDel,nApp] = deal(3,iMov.nRow*iMov.nCol);
iMov.autoP = struct('X',[],'Y',[],'B',[],'R',R,'Type','Circle');
[iMov.autoP.B,iMov.autoP.X,iMov.autoP.Y] = deal(cell(nApp,1),X,Y);
[iMov.isSet,iMov.ok] = deal(true,true(iMov.nRow*iMov.nCol,1));

% determines the lower bound of the offset distance between the arenas
[dX,dY] = deal(diff(X,[],2),diff(Y,[],1));
if (isempty(dX))
    Dmin = min(dY(:));
elseif (isempty(dY))
    Dmin = min(dX(:));
else
    Dmin = min(min(dX(:)),min(dY(:)));
end

% sets the maximum possible radius
if (isempty(Dmin))
    Rmax = R;
else
    Rmax = min(floor(Dmin/2)+1,R);
end

% loops through each of the apparatus determining the new indices
for i = 1:nApp
    % index calculations
    [iRow,iCol] = deal(floor((i-1)/iMov.nCol)+1,mod(i-1,iMov.nCol)+1);    
    iTube = (1:nTubeMax) + (iRow - 1)*nTubeMax;
    
    % sets the x/y coordinates of the apparatus
    [xApp,yApp] = deal(X(iTube,iCol),Y(iTube,iCol));
    
    % sets the new row/column indices for the current apparatus
    iMov.iR{i} = roundP(max(1,min(yApp)-Rmax):min(sz(1),max(yApp)+Rmax));
    iMov.iC{i} = roundP(max(1,min(xApp)-Rmax):min(sz(2),max(xApp)+Rmax));    
    iMov.iCT{i} = 1:length(iMov.iC{i});
    
    % resets the location of the apparatus region
    iMov.pos{i} = [iMov.iC{i}(1),iMov.iR{i}(1),...
                   diff(iMov.iC{i}([1 end])),diff(iMov.iR{i}([1 end]))];
    iMov.xTube{i} = [0 iMov.pos{i}(3)];
       
    % sets the sub-image binary mask
    iMov.autoP.B{i} = false(length(iMov.iR{i}),length(iMov.iC{i}));
    [XB,YB] = meshgrid(1:size(iMov.autoP.B{i},2),1:size(iMov.autoP.B{i},1));
    
    % loops through all of the tube regions setting the new values
    for j = 1:getAppFlyCount(iMov,i)
        % sets the new row indices and y-coordinates for each tube
        iMov.iRT{i}{j} = roundP((yApp(j) + (-Rmax:Rmax)) - (iMov.iR{i}(1)-1));

        % ensures the row indices within the image frame
        ii = (iMov.iRT{i}{j}<=length(iMov.iR{i})) & (iMov.iRT{i}{j}>0);       
        iMov.iRT{i}{j} = iMov.iRT{i}{j}(ii);          
        
        % sets the vertical position of the tubes
        iMov.yTube{i}(j,:) = iMov.iRT{i}{j}([1 end]) - 1;
        
        % sets the new search binary mask
        iMov.autoP.B{i} = iMov.autoP.B{i} | (sqrt((XB - X(iTube(j),iCol) + ...
                    (iMov.iC{i}(1)-1)).^2 + (YB - Y(iTube(j),iCol) + ...
                    (iMov.iR{i}(1)-1)).^2) < R);
    end        
end

% sets the global coordinates of the sub-image
xMin = min(cellfun(@min,iMov.iC));
xMax = max(cellfun(@max,iMov.iC));
yMin = min(cellfun(@min,iMov.iR));
yMax = max(cellfun(@max,iMov.iR));
iMov.posG = [[xMin yMin]-pDel,[(xMax-xMin),(yMax-yMin)]+2*pDel];

% sets the user choice and closes the window
[uChoice,iMov] = deal('Cont',iMov); 
delete(handles.figCircPara)

% --- Executes on button press in buttonCancel.
function buttonCancel_Callback(hObject, eventdata, handles)

% global variables
global uChoice iMov

% retrieves the main GUI axes handle data struct
hGUI = getappdata(handles.figCircPara,'hGUI');
hGUIM = getappdata(hGUI.figWinSplit,'hGUI');

% retrieves the main GUI handles data struct
hOut = findall(hGUIM.imgAxes,'tag','hOut');
if ~isempty(hOut); delete(hOut); end

% sets the user choice and closes the window
[uChoice,iMov] = deal('Cancel',[]); 
delete(handles.figCircPara)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- plots the circle regions on the main GUI to enable visualisation
function plotCircleRegions(handles)

% global variables
global R

% retrieves the X/Y coordinates of the circles
X = getappdata(handles.figCircPara,'X');
Y = getappdata(handles.figCircPara,'Y');
hGUI = getappdata(handles.figCircPara,'hGUI');

% retrieves the main GUI handles data struct
hGUIM = getappdata(hGUI.figWinSplit,'hGUI');
hAx = hGUIM.imgAxes;

% other initialisations
phi = linspace(0,2*pi,101);
axes(hAx)

% retrieves the circle 
hOut = findall(hAx,'tag','hOut');
if (isempty(hOut))
    % sets the hold on the main GUI image axes 
    hold(hAx,'on');
    
    % loops through all the sub-regions plotting the circles   
    for i = 1:size(X,1)
        for j = 1:size(X,2)
            % calculates the new coordinates and plots the circle
            [xP,yP] = deal(X(i,j)+R*cos(phi),Y(i,j)+R*sin(phi));
            fill(xP,yP,'r','tag','hOut','UserData',[i j],...
                       'facealpha',0.25,'LineWidth',1.5)
        end
    end
else
    % loops through all the arenas updating the circle coordinates
    for i = 1:size(X,1)
        for j = 1:size(X,2)
            % determines the handle of the new circle           
            hP = findobj(hOut,'UserData',[i j]);
            
            % updates the coordinates of the circle
            [xP,yP] = deal(X(i,j)+R*cos(phi),Y(i,j)+R*sin(phi));
            set(hP,'xData',xP,'yData',yP)
        end
    end
end

% sets the GUI to the top again
uistack(handles.figCircPara,'top')