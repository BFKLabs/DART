function varargout = CircPara(varargin)
% Last Modified by GUIDE v2.5 06-Feb-2021 02:28:21

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
setObjEnable(handles.buttonRecalcCirc,'off')

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
if chkEditValue(nwVal,[RnwTol Rmax],1)
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
if chkEditValue(nwVal,[0.01 1.00],0)
    % if it is, then update the data struct
    hQ = nwVal;    
    setObjEnable(handles.buttonRecalcCirc,'on')
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
hGUIM = getappdata(hGUI.output,'hGUI');

% retrieves the main GUI handles data struct
hOut = findall(hGUIM.imgAxes,'tag','hOuter');
if ~isempty(hOut); setObjVisibility(hOut,'off'); end

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
hGUIM = getappdata(hGUI.output,'hGUI');
I = get(findobj(get(hGUIM.imgAxes,'children'),'type','image'),'cdata');

% other initalisations
sz = size(I); 
phi = linspace(0,2*pi,101)';
[pDel,nApp] = deal(3,iMov.nRow*iMov.nCol);
[iMov.isSet,iMov.ok] = deal(true,true(iMov.nRow*iMov.nCol,1));

% sets up the automatic detection parameteres
iMov.autoP = struct('X0',X,'Y0',Y,'XC',R*cos(phi),'YC',R*sin(phi),...
                    'B',[],'R',R,'Type','Circle');
iMov.autoP.B = cell(nApp,1);

% determines the lower bound of the offset distance between the arenas
[dX,dY] = deal(diff(X,[],2),diff(Y,[],1));
if isempty(dX)
    Dmin = min(dY(:));
elseif (isempty(dY))
    Dmin = min(dX(:));
else
    Dmin = min(min(dX(:)),min(dY(:)));
end

% sets the maximum possible radius
if isempty(Dmin)
    Rmax = R;
else
    Rmax = min(floor(Dmin/2)+1,R);
end

% loops through each of the apparatus determining the new indices
[nRow,nCol] = size(X);
for i = 1:nCol
    % sets the x/y coordinates of the apparatus
    [xApp,yApp] = deal(X(:,i),Y(:,i));
    
    % sets the new row/column indices for the current apparatus
    iMov.iR{i} = roundP(max(1,min(yApp)-Rmax):min(sz(1),max(yApp)+Rmax));
    iMov.iC{i} = roundP(max(1,min(xApp)-Rmax):min(sz(2),max(xApp)+Rmax));    
    iMov.iCT{i} = 1:length(iMov.iC{i});
    iMov.iRT{i} = cell(size(X,1),1);
    
    % resets the location of the apparatus region
    iMov.pos{i} = [iMov.iC{i}(1),iMov.iR{i}(1),...
                   diff(iMov.iC{i}([1 end])),...
                   diff(iMov.iR{i}([1 end]))];
    iMov.xTube{i} = [0 iMov.pos{i}(3)];
       
    % sets the sub-image binary mask
    iMov.autoP.B{i} = false(length(iMov.iR{i}),length(iMov.iC{i}));
    [XB,YB] = meshgrid(1:size(iMov.autoP.B{i},2),1:size(iMov.autoP.B{i},1));    
    
    % loops through all of the tube regions setting the new values
    for j = 1:nRow
        % sets the new row indices and y-coordinates for each tube
        iMov.iRT{i}{j} = roundP((yApp(j)+(-Rmax:Rmax))-(iMov.iR{i}(1)-1));

        % ensures the row indices within the image frame
        ii = (iMov.iRT{i}{j}<=length(iMov.iR{i})) & (iMov.iRT{i}{j}>0);       
        iMov.iRT{i}{j} = iMov.iRT{i}{j}(ii);          
        
        % sets the vertical position of the tubes
        iMov.yTube{i}(j,:) = iMov.iRT{i}{j}([1 end]) - 1;
        
        % sets the new search binary mask
        iMov.autoP.B{i} = iMov.autoP.B{i} | (sqrt((XB - X(j,i) + ...
                    (iMov.iC{i}(1)-1)).^2 + (YB - Y(j,i) + ...
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
hGUIM = getappdata(hGUI.output,'hGUI');

% retrieves the main GUI handles data struct
hOut = findall(hGUIM.imgAxes,'tag','hOuter');
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
iMov = getappdata(handles.figCircPara,'iMov');
hGUI = getappdata(handles.figCircPara,'hGUI');

% retrieves the main GUI handles data struct
hGUIM = getappdata(hGUI.output,'hGUI');
hAx = hGUIM.imgAxes;

% other initialisations
nApp = length(iMov.iR);
phi = linspace(0,2*pi,101);

% sets the group colour array (based on the format)
if isfield(iMov,'pInfo')
    tCol = getAllGroupColours(length(iMov.pInfo.gName));
else
    tCol = getAllGroupColours(1);
end

% retrieves the circle 
hOut = findall(hAx,'tag','hOuter');
createMark = isempty(hOut);

% sets the hold on the main GUI image axes 
hold(hAx,'on');

% loops through all the sub-regions plotting the circles
for iCol = 1:nApp
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
        [xP,yP] = deal(X(j,iCol)+R*cos(phi),Y(j,iCol)+R*sin(phi));
        
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

% sets the GUI to the top again
uistack(handles.figCircPara,'top')
