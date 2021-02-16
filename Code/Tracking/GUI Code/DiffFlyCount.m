function varargout = DiffFlyCount(varargin)
% Last Modified by GUIDE v2.5 03-Feb-2021 08:30:12

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
setappdata(hObject,'hSel',[]);

% initialises the GUI objects and updates the sub-region data struct
iMov = initGUIObjects(handles,hMain);
setappdata(hMain,'iMov',iMov)
centreFigPosition(hObject)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes DiffFlyCount wait for user response (see UIRESUME)
% uiwait(handles.figFlyCount);

% --- Outputs from this function are returned to the command line.
function varargout = DiffFlyCount_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                           MENU ITEM FUNCTIONS                           %
%-------------------------------------------------------------------------%

% -------------------------------------------------------------------------
function menuReset_Callback(hObject, eventdata, handles)

% prompts the user to confirm the reset
if ~ischar(eventdata)
    qStr = sprintf(['Are you sure you wish to reset the sub-region ',...
                    'parameters back to their original values? This ',...
                    'action cannot be reversed.']);
    uChoice = questdlg(qStr,'Confirm Reset','Yes','No','Yes');
    if ~strcmp(uChoice,'Yes')
        % if the user cancelled, then exit the function
        return
    end
end

% important object handles
hFig = handles.figFlyCount;
hMain = getappdata(hFig,'hMain');

% resets the sub-region parameter struct
iMov = getappdata(hMain,'iMov');
iMov.nTubeR = getappdata(hFig,'nTubeR0');
iMov.isUse = getappdata(hFig,'isUse0');
setappdata(hMain,'iMov',iMov)

% re-initialises the region axes objects
if ~ischar(eventdata)
    initRegionAxes(handles,iMov)
    set(handles.tableFlyCount,'Data',getTableData(iMov))
end

% -------------------------------------------------------------------------
function menuClose_Callback(hObject, eventdata, handles)

% retrieves the current/main gui handles
hFig = handles.figFlyCount;
hMain = getappdata(hFig,'hMain');
isUse0 = getappdata(hFig,'isUse0');
nTubeR0 = getappdata(hFig,'nTubeR0');
iMov = getappdata(hMain,'iMov');

% determines if there is a change in the configuration
isChange = ~isequal(isUse0,iMov.isUse) || ~isequal(nTubeR0,iMov.nTubeR);

% if the user made a change and the sub-regions have been set, then prompt
% them if they want to update their changes
if isChange && iMov.isSet
    % retrieves the function handles from the main GUI
    qFcn = getappdata(hMain,'resetMovQuest');
    rFcn = getappdata(hMain,'resetSubRegionDataStruct');
    hMainH = guidata(hMain);
    
    % prompts the user if they wish to 
    qStr = sprintf(['You have made a change to the sub-region ',...
                    'configuration. This will overwrite your current ',...
                    'configuration and is not reversible.\n\nDo you ',...
                    'wish to apply the changes?']);
    [~,uChoice] = qFcn(hMainH,qStr,sprintf(',''%s''','Cancel'));
    
    % performs the action based on the user's choice
    switch uChoice
        case 'Yes'
            % case is the user wants to update
            setappdata(hMain,'iMov',rFcn(iMov,0))
        
        case 'No'
            % case is the user doesn't want to update
            menuReset_Callback(hObject, '1', handles)
                        
        case 'Cancel'
            % if the user cancelled, then exit the function
            return
    end
end

% deletes the current gui and makes the main gui visible again
delete(hFig)
setObjVisibility(hMain,'on')

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when user attempts to close figFlyCount.
function figFlyCount_CloseRequestFcn(hFig, eventdata, handles)

% closes the figure
menuClose_Callback(handles.menuClose, [], handles)

% --- Executes on mouse motion over figure - except title and menu.
function figFlyCount_WindowButtonMotionFcn(hFig, eventdata, handles)

% initialisations and parameters
fAlpha = 0.2;
mPos = get(hFig,'CurrentPoint');
hSel = getappdata(hFig,'hSel');

% determines if the mouse is over the axis
if isOverAxes(mPos)
    hHover = findAxesHoverObjects(hFig);
    if ~isempty(hHover)
        % if hovering over an object, then determine if the currently
        % highlighted cell matches that which the mouse is hovering over
        if ~isequal(hSel,hHover)
            % resets the face alpha of the currently highlighted object
            if ~isempty(hSel)
                set(hSel,'FaceAlpha',fAlpha)
            end
            
            % updates the highlighted object
            set(hHover,'FaceAlpha',3*fAlpha)
            setappdata(hFig,'hSel',hHover)
        end
    end
    
    % resets the mouse pointer to a hand
    mpStr = 'hand';    
else
    % otherwise, reset the mouse pointer to an arrow
    mpStr = 'arrow';
    
    % reset the highlighted patch's face alpha value
    if ~isempty(hSel)
        set(hSel,'FaceAlpha',fAlpha)   
    end
end

% case is a pointer string
set(hFig,'Pointer',mpStr);

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figFlyCount_WindowButtonDownFcn(hFig, eventdata, handles)

% retrieves the important objects/data structs
hSel = getappdata(hFig,'hSel');
hMain = getappdata(hFig,'hMain');
uData = get(hSel,'UserData');

% retrieves the indices of the fly
col = 'rg';
[iRow,iCol,iFly] = deal(uData(1),uData(2),uData(3));

% updates the sub-region data struct
iMov = getappdata(hMain,'iMov');
iMov.isUse{iRow,iCol}(iFly) = ~iMov.isUse{iRow,iCol}(iFly);
iMov.nTubeR(iRow,iCol) = sum(iMov.isUse{iRow,iCol});
setappdata(hMain,'iMov',iMov)

% updates the colour of the object
setObjEnable(handles.menuReset,'on')
set(hSel,'FaceColor',col(1+iMov.isUse{iRow,iCol}(iFly)))

% updates the table data
Data = get(handles.tableFlyCount,'Data');
Data{iCol,iRow} = iMov.nTubeR(iRow,iCol);
set(handles.tableFlyCount,'Data',Data);

%-------------------------------------------------------------------------%
%                         OTHER CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when entered data in editable cell(s) in tableFlyCount.
function tableFlyCount_CellEditCallback(hObject, eventdata, handles)

% determines if the function is called properly
if isempty(eventdata.Indices)
    % if there are no indices, then exit the function
    return;
else
    % sets the row/column indices
    [iCol,iRow] = deal(eventdata.Indices(1),eventdata.Indices(2));
end

% retrieves the important object/arrays
hMain = getappdata(handles.figFlyCount,'hMain');
iMov = getappdata(hMain,'iMov');

% retrieves the table data
nwVal = eventdata.NewData;
tData = get(handles.tableFlyCount,'Data');

% updates the figure based on the table row that was altered
if iCol > iMov.nCol
    % case is the max row count field
    
    % prompts the user if they wish to continue
    isReset = true;
    if chkEditValue(nwVal,[1,100],1)    
        qStr = sprintf(['Are you sure you want to change the max row ',...
                       'count? This will reset the configuration format ',...
                       'and cannot be reversed.']);
        uChoice = questdlg(qStr,'Reset Max Row Count?','Yes','No','Yes');
        if strcmp(uChoice,'Yes')
            % if the user chose to update, then reset the tube counts/use
            % flags for all sub-regions in the current row            
            iMov.nTubeR(iRow,:) = nwVal;
            iMov.isUse(iRow,:) = {true(nwVal,1)};
            setappdata(hMain,'iMov',iMov)
            
            % flag that the reset is not required
            isReset = false;
            
            % updates the table data
            tData(:,iRow) = {nwVal};
            set(handles.tableFlyCount,'Data',tData)
            
            % resets the plot axes
            initRegionAxes(handles,iMov)
            setObjEnable(handles.menuReset,'on')
        end
    end
    
    % resets the table back to the last valid value (if required)
    if isReset        
        tData{end,iRow} = length(iMov.isUse{iRow,iCol});
        set(handles.tableFlyCount,'Data',tData)   
    end
else
    % determines if the new value is valid    
    if chkEditValue(nwVal,[0,tData{end,iRow}],1)
        % determines the indices of the regions that are to be updated
        dN = nwVal - iMov.nTubeR(iRow,iCol);
        if dN < 0
            % case is there is a reduction in count
            ii = find(iMov.isUse{iRow,iCol},-dN,'last');                        
        else
            % case is there is an increase in count
            ii = find(~iMov.isUse{iRow,iCol},dN,'first');
        end
        
        % if so, update the sub-region data struct
        iMov.isUse{iRow,iCol}(ii) = dN > 0;
        iMov.nTubeR(iRow,iCol) = nwVal;
        setappdata(hMain,'iMov',iMov)
        
        % enables the reset menu item
        setObjEnable(handles.menuReset,'on')
        
        % updates the region axes patches
        c = 'rg';
        hP = getappdata(handles.figFlyCount,'hP');
        arrayfun(@(x,i)(set(x,'FaceColor',c(1+i))),...
                                    hP{iRow,iCol},iMov.isUse{iRow,iCol})
        
    else
        % otherwise, reset the table data back to the last valid value
        tData{iCol,iRow} = iMov.nTubeR(iRow,iCol);
        set(handles.tableFlyCount,'Data',tData);
    end
end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the GUI objects
function iMov = initGUIObjects(h,hMain)

% initialisations
hFig = h.figFlyCount;
fPos = get(hFig,'position');
iMov = getappdata(hMain,'iMov');

% other parameters and array dimensioning
[nRow,nCol] = deal(iMov.nRow,iMov.nCol);
[xiC,xiR,cWid0,dX] = deal(num2cell(1:nCol),num2cell(1:nRow),85,10);

% sets the regional fly count array
if isempty(iMov.nTubeR)
    % no array is set, so create a new one
    [nFly,iMov.nTubeR] = deal(iMov.nTube*ones(iMov.nRow,iMov.nCol));
    [isUse,iMov.isUse] = deal(arrayfun(@(n)(true(n,1)),nFly,'un',0));
else
    % otherwise, use the previous array
    nFly = iMov.nTubeR;
    isUse = iMov.isUse;
end

% sets the fly count/use flag arrays into the gui
setappdata(hFig,'nTubeR0',nFly)
setappdata(hFig,'isUse0',isUse)

% makes the main GUI invisible
setObjVisibility(hMain,'off')
setObjEnable(h.menuReset,'off')

% ---------------------------------- %
% --- REGION AXES INITIALISATION --- %
% ---------------------------------- %

% sets the table information fields
cStrT = {'Max Count'};
cStr = [cellfun(@(x)(sprintf('Column #%i',x)),xiC,'un',0),cStrT];
rStr = cellfun(@(x)(sprintf('Row #%i',x)),xiR,'un',0);
cWid = num2cell(cWid0*ones(1,iMov.nRow));
cEdit = true(1,iMov.nRow);

% resets the figure position and makes it visible
drawnow('expose'); pause(0.05);
resetObjPos(hFig,'Bottom',-1000)
setObjVisibility(hFig,'on')

% updates the table properties
set(h.tableFlyCount,'rowname',cStr,'columnname',rStr,...
                    'columnwidth',cWid,'columnEditable',cEdit)                    
                 
% retrieves the table dimensions
[H0T,HWT,W0T] = getTableDimensions(findjobj(h.tableFlyCount));
tPos = [dX*[1 1],W0T+nRow*cWid0,H0T+(nCol+1)*HWT];
tPos(2) = fPos(4)-(3*dX+tPos(4));

% reset GUI object positions
tData = getTableData(iMov);

% tData(end,:) = cellfun(@(x)...
%                     (setHTMLColourString('kb',x,1)),tData(end,:),'un',0);
% setHorizAlignedTable(h.tableFlyCount,tData)

% resets the table/panel dimensions
set(h.tableFlyCount,'position',tPos,'Data',tData);
set(h.panelFlyCount,'position',[dX*[1 1],tPos(3)+2*dX,fPos(4)-2*dX])

% resets the image panel/figure dimensions
resetObjPos(h.panelRegion,'left',tPos(3)+4*dX);
pPos = get(h.panelRegion,'Position');
resetObjPos(hFig,'Width',sum(pPos([1,3]))+dX)

% ---------------------------------- %
% --- REGION AXES INITIALISATION --- %
% ---------------------------------- %

% initialises the plot axes
initRegionAxes(h,iMov)

% --- initialises the region axes objects
function initRegionAxes(h,iMov)

% initialisations
hAx = h.axesRegion;
nFly = iMov.nTubeR;
isUse = iMov.isUse;

% memory allocation and parameters
hP = cell(size(nFly));
[lWid,fAlpha] = deal(3,0.2);
[ii,jj,col] = deal([1,1,2,2,1],[1,2,2,1,1],'rg');

% axis limits
xLim = [0,iMov.nCol];
yLim = [0,sum(max(nFly,[],2))];

% sets up the region axes
cla(hAx)
axis(hAx,'ij');
set(hAx,'xticklabel',[],'yticklabel',[],'xlim',xLim,...
        'ylim',yLim,'box','on','xcolor','w',...
        'ycolor','w','ticklength',[0,0]);

% turns the axis hold on
hold(hAx,'on') 
    
% creates region markers/objects
for i = 1:iMov.nRow
    % calculates the row offset    
    if i < iMov.nRow    
        % plots the row boundary marker (if not the last row)
        iOfsR = sum(max(nFly(1:i,:),[],2));
        plot(hAx,xLim,iOfsR*[1,1],'k','linewidth',lWid)
    end
    
    % sets up the flag counts/row offset
    nMax = max(nFly(i,:));
    iOfs = sum(max(nFly(1:(i-1),:),[],2));    
    
    % creates the sub-region patch objects
    for j = 1:iMov.nCol
        % plots the column boundary marker (first row only and not the last
        % column)
        if (j < iMov.nCol) && (i == 1)
            plot(hAx,j*[1,1],yLim,'k','linewidth',lWid)
        end

        % creates the patch objects
        hP{i,j} = zeros(nMax,1);
        for k = 1:nMax
            [xx,yy] = deal(j+[-1,0],(iOfs+k)+[-1,0]);
            hP{i,j}(k) = patch(xx(ii),yy(jj),col(1+isUse{i,j}(k)),...
                              'linewidth',0.5,'UserData',[i,j,k],...
                              'facealpha',fAlpha,'parent',hAx);
        end
    end   
end

% plots the outline border
plot(hAx,xLim(ii),yLim(jj),'k','linewidth',lWid)

% turns the axis hold off
hold(hAx,'off') 

% ensures the markers are on top
uistack(findall(hAx,'Type','Line'),'top')
calcAxesGlobalCoords(h)

% resets the important fields
setappdata(h.figFlyCount,'hP',hP);
setappdata(h.figFlyCount,'hSel',[]);

% --- calculates the coordinates of the axes with respect to the global
%     coordinate position system
function calcAxesGlobalCoords(handles)

% global variables
global axPosX axPosY

% retrieves the position vectors for each associated panel/axes
pPosAx = get(handles.panelRegion,'Position');
axPos = get(handles.axesRegion,'Position');

% calculates the global x/y coordinates of the
axPosX = (pPosAx(1)+axPos(1)) + [0,axPos(3)];
axPosY = (pPosAx(2)+axPos(2)) + [0,axPos(4)];

% --- sets up the data array for the table
function tData = getTableData(iMov)

nFlyMax = max(cellfun(@length,iMov.isUse),[],2)';
tData = num2cell([iMov.nTubeR';nFlyMax]);
