function varargout = SplitAxisRegions(varargin)
% Last Modified by GUIDE v2.5 29-Sep-2016 13:31:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SplitAxisRegions_OpeningFcn, ...
                   'gui_OutputFcn',  @SplitAxisRegions_OutputFcn, ...
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

% --- Executes just before SplitAxisRegions is made visible.
function SplitAxisRegions_OpeningFcn(hObject, eventdata, handles, varargin)

% updates the global variable
global hasCtrl isUpdating isInit isMove updateFlag isChange
[hasCtrl,isUpdating,isInit,isMove,isChange] = deal(false);
updateFlag = 2;

% Choose default command line output for SplitAxisRegions
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% sets the input variables
hGUI = varargin{1};
sPara = getappdata(hGUI.figFlyAnalysis,'sPara');

% sets the parameter struct into the GUI
setappdata(hObject,'hGUI',hGUI)
setappdata(hObject,'sPara0',sPara)
setappdata(hObject,'sPara',sPara)

% initialises the GUI properties
initObjProps(handles)

% initialises the parameter struct, movement time and sub-regions
initMovementTimer();
createSubRegions(handles);
centreFigPosition(hObject);

% UIWAIT makes SplitAxisRegions wait for user response (see UIRESUME)
% uiwait(handles.figSplitPlot);

% --- Outputs from this function are returned to the command line.
function varargout = SplitAxisRegions_OutputFcn(hObject, eventdata, handles) 

% sets the output variables
varargout{1} = hObject;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes on key press with focus on figSplitPlot and none of its controls.
function KeyPressFcn(hObject, eventdata, handles)

% updates the global variable
global hasCtrl
hasCtrl = strcmp(eventdata.Key,'control');

% --- Executes on key release with focus on figSplitPlot and none of its controls.
function KeyReleaseFcn(hObject, eventdata, handles)

% resets the control flag
global hasCtrl
hasCtrl = false;

% ------------------------------------- %
% --- SUBPLOT RESIZING INFO OBJECTS --- %
% ------------------------------------- %

% --- the parameter editbox editting callback function --- %
function editSegPara(hObject, eventdata, handles)

% retrieves the segmentation parameters
sPara = getappdata(handles.figSplitPlot,'sPara');
uD = get(hObject,'UserData');

% retrieves the parameter string and the new value/limits
pStr = sprintf('sPara.%s',uD);
[nwVal,nwLim] = deal(str2double(get(hObject,'string')),[1 5]);

% checks to see if the new value is valid
if chkEditValue(nwVal,nwLim,1)
    % determines if the new value is unique
    if eval(pStr) ~= nwVal
        % if so, then update the parameter field and struct
        eval(sprintf('%s = nwVal;',pStr));    

        % enables the update button
        setObjEnable(handles.buttonSplitAxis,'on')
        setappdata(handles.figSplitPlot,'sPara',sPara)
    end
else
    % otherwise, revert back to the previous valid value
    set(hObject,'string',num2str(eval(pStr)))
end

% ------------------------------ %
% --- CONTROL BUTTON OBJECTS --- %
% ------------------------------ %

% --- Executes on button press in buttonClear.
function buttonClear_Callback(hObject, eventdata, handles)

% global variables
global isChange

% prompts the user if they want to continue
uChoice = questdlg({['Are you sure you want to clear the split ',...
                    'regions?'];'';'This action can not be reversed.'},...
                    'Clear Split Regions?','Yes','No','Yes');
if (~strcmp(uChoice,'Yes'))
    % if not, then exit the function
    return
else
    % otherwise, update the status flag
    isChange = true;    
end

% reset the row/column edit box strings
set(handles.editRows,'string','1')
set(handles.editCols,'string','1')

% updates the parameters
sPara = getappdata(handles.figSplitPlot,'sPara');
[sPara.nRow,sPara.nCol] = deal(1);
setappdata(handles.figSplitPlot,'sPara',sPara)

% updates the axis table and recreates the sub-regions
setupAxisTable(handles,1)
createSubRegions(handles)

% disables the button
setObjEnable(hObject,'off')
setObjEnable(handles.buttonCombine,'off')

% --- Executes on button press in buttonCombine.
function buttonCombine_Callback(hObject, eventdata, handles)

% global variables
global isChange

% retrieves the handles to the custom axis
hAx = findall(0,'tag','axesCustomPlot');

% retrieves the indices of the selected region
hNum = findall(hAx,'tag','hNum','Color','w');
iSel = sort(str2double(get(hNum,'string')),'ascend');

% retrieves the positions of the selected regions
[~,pos] = detClickSubplot(handles);
pos = pos(iSel,:);

% calculates the total max area, and the sum of the individual region areas
Atot = prod(max(pos(:,1:2)+pos(:,3:4))-min(pos(:,1:2)));
Asum = sum(pos(:,3).*pos(:,4));

% if the total max area does not equal the area sum then exit with an error
if (abs(Atot - Asum) > 1e-6)
    eStr = 'Error! Can''t combine regions as they do not form a rectangle';
    waitfor(errordlg(eStr,'Combining Selected Region Error'))
    return
else
    uChoice = questdlg({['Are you sure you want to combine the selected ',...
                        'regions?'];'';'This action can not be reversed.'},...
                        'Combine Selected Regions?','Yes','No','Yes');
    if (~strcmp(uChoice,'Yes'))
        return
    end
end

% disables the button
setObjEnable(hObject,'off')

% retrieves the parameter struct
sPara = getappdata(handles.figSplitPlot,'sPara');
indNw = true(size(sPara.pos,1),1);
[indNw(iSel(2:end)),isChange] = deal(false,true);

% sets the new position vector into the parameter struct
pos0 = sPara.pos(iSel,:);
posNw = [min(pos0(:,1:2)) (max(pos0(:,1:2)+pos0(:,3:4))-min(pos0(:,1:2)))];
sPara.pos(iSel(1),:) = posNw;

% removes the extraneous rows from the parameter struct arrays
[sPara.pos,sPara.pData] = deal(sPara.pos(indNw,:),sPara.pData(indNw));
[sPara.plotD,sPara.ind] = deal(sPara.plotD(indNw),sPara.ind(indNw,:));

% resets the parameter struct and recreates the sub-regions
setappdata(handles.figSplitPlot,'sPara',sPara);

% updates the axis table info and the sub-regions
setupAxisTable(handles)
createSubRegions(handles)

% --- Executes on button press in buttonSplitAxis.
function buttonSplitAxis_Callback(hObject, eventdata, handles)

% global variables
global isChange

% determines if the user has made a change that hasn't been updated
if strcmp(get(handles.buttonSplitAxis,'enable'),'on')
    % if so, then prompt the user if they still want to close the window
    uChoice = questdlg({'Are you sure you want to update the axis split?';...
                '';'This action will clear all current axis properties.'},...
                'Update Axis Split?','Yes','No','Yes');
    if (~strcmp(uChoice,'Yes'))                
        % if not, then exit the function
        return
    else
        % otherwise, update the status flag
        isChange = true;
    end
end

% updates the axis table and recreates the sub-regions
setupAxisTable(handles,1)
createSubRegions(handles)

% disables the button
setObjEnable(hObject,'off')
setObjEnable(handles.buttonClear,'on')

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% global variables
global updateFlag isChange 
updateFlag = 2;

% retrieves the main GUI handles
hGUI = getappdata(handles.figSplitPlot,'hGUI');
sPara = getappdata(handles.figSplitPlot,'sPara');

% determines if the user has made a change 
if (isChange)
    % if so, prompt the user if they want to update the changes
    uChoice = questdlg('Are you sure you want update the changes?',...
                       'Update Axis Changes?','Yes','No','Cancel','Yes');
    switch (uChoice)
        case ('Yes') % case is wanting to update
            setappdata(hGUI.figFlyAnalysis,'sPara',sPara)                
            delete(getappdata(hGUI.figFlyAnalysis,'hPara'))
            setappdata(hGUI.figFlyAnalysis,'hPara',[])          
        case ('No') % case is not wanting to update
            sPara = getappdata(handles.figSplitPlot,'sPara0')
            setappdata(hGUI.figFlyAnalysis,'sPara',sPara)                            
        otherwise % case is cancelling
            return
    end
end

% clears all the axis objects
hAx = findall(hGUI.panelPlot,'tag','axesCustomPlot');
if (~isempty(hAx)); delete(hAx); end                

% clears all the plot panel objects
hPanel = findall(hGUI.panelPlot,'tag','subPanel');
if (~isempty(hPanel)); delete(hPanel); end                

% sets the sub-index 
nReg = size(sPara.pos,1);
setObjVisibility(hGUI.textSubInd,nReg>1)
setObjVisibility(hGUI.popupSubInd,nReg>1)

% sets the main GUI properties
setMainGUIProps(handles,'on')

% if more than one region, then update the figure properties
if nReg > 1
    % updates the editbox (if visible)
    lStr = cellfun(@num2str,num2cell(1:nReg)','un',0);        
    fcnAxC = getappdata(hGUI.figFlyAnalysis,'axisClickCallback');       
    
    % updates the subplot index popup-menu
    setObjEnable(hGUI.menuSaveSubConfig,'on')
    set(hGUI.popupSubInd,'string',lStr); 
    if isChange; set(hGUI.popupSubInd,'value',1); end
    
    % creates the subplot panels
    setupSubplotPanels(hGUI.panelPlot,sPara,fcnAxC)       
    
    % updates the sub-index popup function
    popFcn = getappdata(hGUI.figFlyAnalysis,'popupSubInd');
    popFcn(hGUI.popupSubInd,1,hGUI)    
else
    % deletes any previous subplot panels
    setObjEnable(hGUI.menuSaveSubConfig,'off')
    hPanel = findall(hGUI.panelPlot,'tag','subPanel');
    if ~isempty(hPanel); delete(hPanel); end
end

% deletes the GUI
delete(handles.figSplitPlot)
setObjVisibility(hGUI.figFlyAnalysis,'on')

% ensures the main GUI doesn't update again
pause(0.1); 
updateFlag = 0;

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% ------------------------------- %
% --- LINE POSITION FUNCTIONS --- %
% ------------------------------- %

% --- create the line objects
function hLine = createLineObj(hAx,xL,yL,ind,type,hNum)

% initialisations
vStr = {'V','H'};

% creates the line object
hLine = imline(hAx,xL,yL);

% sets the limits based on the line type
Lim = {xL,yL}; Lim{type} = [0 1];

% if moveable, then set the position callback function
api = iptgetapi(hLine);
api.addNewPositionCallback(@lineCallback);

% sets the constraint region for the
fcn = makeConstrainToRectFcn('imline',Lim{1},Lim{2});
api.setPositionConstraintFcn(fcn);

% sets the line object properties
set(hLine,'tag',sprintf('hSub%s',vStr{type}),'UserData',[ind,type])
set(findobj(hLine,'tag','top line'),'UserData',hNum,'Color','k','LineWidth',3)
set(findobj(hLine,'tag','bottom line'),'UserData',[xL',yL'],'Color','k','LineWidth',3)

% makes the end-points invisible
set(findobj(hLine,'tag','end point 1'),'visible','off','UserData',Lim)
setObjVisibility(findobj(hLine,'tag','end point 2'),'off')

% --- sets the line position callback
function lineCallback(lPos,varargin)

% global variables
global isChange

% resets the clock timer
tic;

% global variables
global dX dY isUpdating hMove isMove isInit
if (isUpdating || isInit); return; end

% parameters
[tol,tol2,del,tStr,isChange] = deal(0.001,0.01,0.05,{'V','H'},true);
if (nargin == 1); hh = gco; else hh = varargin{1}; end

% retrieves the line object tag and the userdata
[hNum,hLine] = deal(get(hh,'UserData'),get(hh,'parent'));
[uData,hAx] = deal(get(hLine,'UserData'),findall(0,'tag','axesCustomPlot'));

% resets the location of the numbers
if (~isempty(hNum))
    % retrieves the locations of the numbers
    try                
        % resets their locations depending on the type
        for i = 1:length(hNum)
            numPos = get(hNum(i),'Position');        
            if (uData(2) == 1)
                % line is vertical
                numPos(1) = (lPos(1,1)+dX);
            else
                % line is horizontal
                numPos(2) = (lPos(1,2)+dY);
            end

            % updates the positions
            set(hNum(i),'position',numPos);
        end
    catch
        return
    end
end

% exits the function
if (nargin == 2); return; end

% determines if the line has moved recently
if (~isMove)
    % if not, then determine if the line is free to move
        
    % initialisations and memory allocation
    [hMove,isInit] = deal(cell(1,3),true);
    [iP,iC] = deal(find((1:2)~=uData(2)),uData(2));    
    [A,p,jj] = deal(NaN(2),[4*dX,2*dY],cell(1,2));    
    
    % retrieves the stationary line coordinates
    lPos0 = get(findobj(hLine,'tag','bottom line'),'UserData');
    setappdata(hAx,'hLine',hLine)
    
    % calculates the position offset for the line
    [pSub{1},pSub{2}] = getAllLinePos(guidata(hAx),1);
    dP = lPos0(1,iC) + del*[-1 1];
            
    % determines if there are any matching perpendicular lines to the
    % currently moving line
    for i = 1:2
        for j = 1:2
            % determines if the line is on the edge
            if ((lPos0(i,iP) == 0) || (lPos0(i,iP) == 1))
                % if so, flag with a negative index
                A(j,i) = -1;
            else
                % determines if the x/y locations of any of the other lines
                % match the moving line
                ii = cellfun(@(x)(abs(x(i,iP)-lPos0(i,iP)) <= tol) && ...
                    ((dP(j) >= x(1,iC)) && (dP(j) <= x(2,iC))),pSub{iP});
                if (any(ii))
                    % if so, then set the index of the perpendicular line
                    try
                        A(j,i) = find(ii);
                    catch
                        a = 1;
                    end
                end
            end
        end
    end                    
    
    % determines if all the perpendicular lines matched
    hSubP = findall(hAx,'tag',['hSub',tStr{iP}]);  
    if (any(isnan(A(:))))
        % if there are missing matches, then the line may have to move with
        % other co-linear lines. search for these lines on either side
        % until either (a) an edge is reached, (b) the colinear line
        % matches a perpendicular line, or (c) there is no colinear line
        % adjacent to the search line            

        % retrieves the handles of the lines    
        hSubC = findall(hAx,'tag',['hSub',tStr{iC}]);            
        for i = 1:2
            for j = 1:2                
                % only search lines that are missing
                if (isnan(A(j,i)))
                    [k,lPosC] = deal((1:2) ~= i,lPos0);                
                    while (1)                                        
                        % THIS LINE OF CODE IS INCORRECT?! FIX THIS TO
                        % ENSURE CORRECT SELECTION OF COINCIDENT LINES
                        
                        
                        % determines the index of the line that is
                        % coincident to the current line
                        ii = cellfun(@(x)((abs(x(1,iC)-lPosC(1,iC))<=tol) && ...
                                          (abs(x(k,iP)-lPosC(i,iP))<=tol)),pSub{iC});
                            
                            
                        if (any(ii))
                            % appends the coincident line to movement array
                            hMove{1} = [hMove{1};hSubC(ii)];
                            lPosC = getLinePos(hSubC(ii));  
                            
                            % if new point is on edge, then exit the loop
                            if (lPosC(i,iP) < 1e-6) || (lPosC(i,iP) > (1-1e-6))
                                break
                            end
                            
                            % determines if the x/y locations of any of the
                            % perperndicular lines match the current line
                            k1 = cellfun(@(x)(abs(x(i,iP)-lPosC(i,iP)) <= tol) && ...
                                    ((dP(1) >= x(1,iC)) && (dP(1) <= x(2,iC))),pSub{iP});    
                            k2 = cellfun(@(x)(abs(x(i,iP)-lPosC(i,iP)) <= tol) && ...
                                    ((dP(2) >= x(1,iC)) && (dP(2) <= x(2,iC))),pSub{iP});                                                                                                    
                            if (any(k1) && any(k2))
                                % if there is a match, then set the line
                                % into the movement array and exit the loop
                                break
                            end
                        else
                            % otherwise exit loop
                            break
                        end
                    end
                end
            end
        end
        
        % sets the moved line and other colinear lines into a single array
        hC = [hLine;reshape(hMove{1},length(hMove{1}),1)];               
    else
        % otherwise, set the colinear line to be the moved line
        hC = hLine;
    end
    
    % sets the limits of all the colinear lines
    lPosT = [lPos0;cell2mat(cellfun(@(x)(getLinePos(x)),num2cell(hC(2:end)),'un',0))];        
    pLimC = [min(lPosT(:,iP)) max(lPosT(:,iP))];    
    
    % calculates the position offset for the line    
    dP = mean(lPosT(1,iC)) + del*[-1 1];
    ii = cellfun(@(x)((x(1,iP) >= pLimC(1)) && (x(1,iP) <= pLimC(2))),pSub{iP});
    for i = 1:2
        kk = cellfun(@(x)((x(i,iC) >= dP(1)) && (x(i,iC) <= dP(2))),pSub{iP});
        hMove{4-i} = hSubP(kk & ii);
    end     
    
    % gets the userdata for the co-linear lines
    uD = cell2mat(cellfun(@(x)(get(x,'UserData')),num2cell(hC),'un',0));                            
    
    % determines the parallel lines are in-line with the currently moving
    % line (removes the current line from the index array). from this,
    % determine which lines lie left/right (horizontally) or below/above
    % (vertically) wrt to the current moved line
    ii = cellfun(@(x)((x(2,iP)>=(pLimC(1)+tol2)) && ...
                                    (x(1,iP)<(pLimC(2)-tol2))),pSub{iC});
    
    ii((length(ii)+1)-uD(:,1)) = false;    
    jj{1} = ii & cellfun(@(x)(x(1,iC)<lPos0(1,iC)),pSub{iC});
    jj{2} = ii & cellfun(@(x)(x(1,iC)>lPos0(1,iC)),pSub{iC});
        
    % sets the limiting range for the currently moved line
    Lim = cellfun(@(x)(x'),num2cell(lPos0,1),'un',0);
    for i = 1:length(jj)
        if (~any(jj{i}))
            % no other limit for limit, so use frame edge
            Lim{iC}(i) = (i == 2);
        else
            if (i == 1)
                % case is for the lower limit
                Lim{iC}(i) = max(cellfun(@(x)(x(1,iC)),pSub{iC}(jj{i})));
            else
                % case is for the upper limit
                Lim{iC}(i) = min(cellfun(@(x)(x(1,iC)),pSub{iC}(jj{i})));
            end
        end
    end
    
    % sets the offsets to the rectangle limits
    Lim{iC} = Lim{iC} + reshape(p(iC)*[1 -1],size(Lim{iC}));
        
    % updates the line constraining function
    updateLineConstrainFcn(hLine,Lim)        
    [isInit,isMove] = deal(false,true);
end

% updates the positions of the colinear/perpendicular lines
updateLinePos(hMove{1},lPos,uData(2),1:2)
updateLinePos(hMove{2},lPos,uData(2),2)
updateLinePos(hMove{3},lPos,uData(2),1)

% --- updates the position of the line object
function updateLinePos(hLine,lPos,type,ind,varargin)

% global variables
global isUpdating

% retrieves the line api handle and set the new position
for i = 1:length(hLine)
    if (nargin == 4)
        [lPosNw,api] = getLinePos(hLine(i));
        lPosNw(ind,type) = lPos(ind,type);
    else
        [api,lPosNw] = deal(iptgetapi(hLine(i)),lPos);
    end
    
    % resets the line position
    isUpdating = true;
    api.setPosition(lPosNw);        
    isUpdating = false;
    
    if (length(ind) == 2)
        lineCallback(lPosNw,findall(hLine(i),'tag','top line'));
    end
end

% --- retrieves the line position for the line object, hLine
function [lPos,api] = getLinePos(hLine,ind)

% retrieves the line's position
api = iptgetapi(hLine);
pos = api.getPosition();

% sets the position of the line (depending if vertical or horizontal)
if (nargin == 2)
    lPos = pos(1,ind);
else
    lPos = pos;
end

% --- retrieves the location of all the line positions
function [pSubV,pSubH] = getAllLinePos(handles,varargin)

% retrieves the important data structs
hAx = findall(0,'tag','axesCustomPlot'); 

% retrieves the vertical marker positions
hSubV = findall(hAx,'tag','hSubV');
if (nargin == 1)
    pSubV = [0;sort(cellfun(@(x)(getLinePos(x,1)),num2cell(hSubV)),'ascend');1];
else
    pSubV = cellfun(@(x)(getLinePos(x)),num2cell(hSubV),'un',0);
end

% retrieves the horizontal marker positions
hSubH = findall(hAx,'tag','hSubH');
if (nargin == 1)
    pSubH = [0;(1-sort(cellfun(@(x)(getLinePos(x,2)),num2cell(hSubH)),'descend'));1];
else
    pSubH = cellfun(@(x)(getLinePos(x)),num2cell(hSubH),'un',0);
end

% --- updates the line constrain function to the specified limits
function updateLineConstrainFcn(hLine,Lim)

% exit if no lines
if (isempty(hLine)); return; end

% sets the line movement limits (if not provided)
if (nargin == 1)                
    [uData,lPos] = deal(get(hLine,'UserData'),getLinePos(hLine));
    Lim = cellfun(@(x)(x'),num2cell(lPos,1),'un',0);
    Lim{uData(2)} = [0 1];
end

% updates the constraining region for the line
api = iptgetapi(hLine);
fcn = makeConstrainToRectFcn('imline',Lim{1},Lim{2});
set(findall(hLine,'tag','end point 1'),'UserData',Lim)
api.setPositionConstraintFcn(fcn);            

% --- updates the line hit-test state
function setLineHTState(hAx,state)

% retrieves the children objects of all the vertical lines
hSubVC = get(findall(hAx,'tag','hSubV'),'Children');
if (~iscell(hSubVC)); hSubVC = {hSubVC}; end

% retrieves the children objects of all the vertical lines
hSubHC = get(findall(hAx,'tag','hSubH'),'Children');
if (~iscell(hSubHC)); hSubHC = {hSubHC}; end

% sets the hit-test state for all vertical/horizontal lines
cellfun(@(x)(set(x,'hittest',state)),hSubVC)
cellfun(@(x)(set(x,'hittest',state)),hSubHC)

% -------------------------------- %
% --- SUBPLOT REGION FUNCTIONS --- %
% -------------------------------- %

% --- creates the subplot regions and line objects
function createSubRegions(handles)

% global variables
global dX dY tCol

% ------------------------------------------- %
% --- INITIALISATIONS & MEMORY ALLOCATION --- %
% ------------------------------------------- %

% initialisations
tCol = {'k',0.5*[1 1 1]};
[dX,dY,pTolN] = deal(0.01,0.03,0.005);

% retrieves the important data structs
hGUI = getappdata(handles.figSplitPlot,'hGUI');
sPara = getappdata(handles.figSplitPlot,'sPara');

% retrieves the parameter data struct
hAx = findall(hGUI.panelPlot,'tag','axesCustomPlot'); 
axis(hAx); cla(hAx); hold(hAx,'on'); 
axPos = get(hAx,'position');

% removes any sub-region marker objects from the axis (if they exist)
clearAxesObjects(hAx)

% memory allcations
[pXL,pYL] = deal(cell(1,2));
[nReg,sz] = deal(size(sPara.pos,1),roundP(axPos([4,3])));
hNum = cell(nReg,1);

% ----------------------------------------- %
% --- LINE OBJECT POSITION CALCULATIONS --- %
% ----------------------------------------- %

% retrieves the number of regions (only if regions are split)
if (nReg > 1)
    [pXL,pYL] = detRegionLines(sPara,sz);   
end

% ---------------------------- %
% --- LINE OBJECT CREATION --- %
% ---------------------------- %

% creates all the fill objects
for i = 1:nReg
    % creates the fill/text objects
    [vX,vY] = pos2vec(sPara.pos(i,:));
    fill(vX,vY,'w','tag','hSel','UserData',i,'EdgeColor','none',...
               'ButtonDownFcn',{@fillButtonDownFcn,handles},'parent',hAx);        
end

% creates all the sub-region marker numbers
for i = 1:nReg
    [xT,yT] = deal(sPara.pos(i,1)+dX,sPara.pos(i,2)+dY);
    hNum{i} = text(xT,yT,num2str(i),'tag','hNum','fontsize',24,...
                  'fontweight','bold','Color',tCol{1},'parent',hAx);
end

% add in the line objects
if (nReg > 1)
    % retrieves the locations of the text number objects
    pNum = cell2mat(cellfun(@(x)(get(x,'position')),hNum,'un',0));    
    
    % creates all the line objects
    for i = 1:length(pXL)
        % determines the number objects associated with each line
        if (i == 1)
            iReg = cellfun(@(x,y)(find((abs((pNum(:,1)-dX) - x(1)) < pTolN) & ...
                    (pNum(:,2) > y(1) & (pNum(:,2) < y(2))))),num2cell(pXL{i},2),...
                    num2cell(pYL{i},2),'un',0);   
        else
            iReg = cellfun(@(x,y)(find((abs((pNum(:,2)-dY) - y(1)) < pTolN) & ...
                    (pNum(:,1) > x(1) & (pNum(:,1) < x(2))))),num2cell(pXL{i},2),...
                    num2cell(pYL{i},2),'un',0);               
        end
            
        for j = 1:size(pXL{i},1)
            % creates the line object
            if (isempty(iReg{j}))
                createLineObj(hAx,pXL{i}(j,:),pYL{i}(j,:),j,i,[]);
            else
                createLineObj(hAx,pXL{i}(j,:),pYL{i}(j,:),j,i,cell2mat(hNum(iReg{j})));
            end
        end
    end
end

% plots the surrounding regions
lWid = 3;
plot(hAx,[0 1],[0 0],'k','linewidth',lWid,'tag','hEdge');
plot(hAx,[0 1],[1 1],'k','linewidth',lWid,'tag','hEdge');
plot(hAx,[0 0],[0 1],'k','linewidth',lWid,'tag','hEdge');
plot(hAx,[1 1],[0 1],'k','linewidth',lWid,'tag','hEdge');

% sets the context-menu for the axis
hold(hAx,'on'); 
set(hAx,'xlim',[0 1],'ylim',[0 1])
axis(hAx,'ij'); 

% --- Executes on mouse press over figure background.
function fillButtonDownFcn(hObject, eventdata, handles)

% global variables
global hasCtrl tCol
vStr = {'off','on'};

% retrieves the parameter struct
hGUI = getappdata(handles.figSplitPlot,'hGUI');
sPara = getappdata(handles.figSplitPlot,'sPara');

% retrieves the axis handle
hAx = findall(hGUI.panelPlot,'tag','axesCustomPlot');

% if the window is split, and control is held, then change the selection
% properties of the fill object. otherwise, reset the
if ((hasCtrl) && (size(sPara.pos,1) > 1))    
    % determines the index/location of the clicked region
    iSub = detClickSubplot(handles);   
        
    % retrieves and updates the selection objects
    hSelT = findall(hAx,'tag','hSel');    
    [~,ii] = sort(cell2mat(get(hSelT,'UserData')),'ascend');
    [hNum,hSelT] = deal(findall(hAx,'tag','hNum','string',num2str(iSub)),hSelT(ii));                    
    
    % toggles the face color of the fill objects
    hSel = hSelT(iSub);    
    if (isequal(get(hSel,'FaceColor'),[1 0 0]))
        % sets all the faces to white
        set(hSel,'FaceColor','w');
        set(hNum,'Color',tCol{1});                
    else
        % retrieves and updates the number objects
        set(hSel,'FaceColor','r');
        set(hNum,'Color','w');        
    end       
        
    % resets the hit-test state for all the lines
    ii = cellfun(@(x)(isequal(x,[1 0 0])),get(hSelT,'FaceColor'));
    if any(ii)
        % makes all lines immobile
        setLineHTState(hAx,'off')        
        setObjEnable(handles.buttonCombine,sum(ii)>1)
        
    else
        % makes all lines mobile again
        setLineHTState(hAx,'on')
        setObjEnable(handles.buttonCombine,'off')
    end  
else
%     % retrieves and updates the selection objects
%     if (~strcmp(get(handles.figSplitPlot,'SelectionType'),'alt'))
%         hSel = findall(hAx,'tag','hSel','FaceColor','r');
%         if (~isempty(hSel))
%             % sets the face colours to white (unselected            
%             hNum = findall(hAx,'tag','hNum','Color','w');
%             
%             % updates the properties of the number/selection fill objects            
%             iNum = num2cell(sPara.isEmpty(str2double(get(hNum,'string'))));
%             cellfun(@(x,y)(set(x,'Color',tCol{1+y})),num2cell(hNum),iNum)
%             set(hSel,'FaceColor','w');            
%         end
%     end
end

% --- determines the subplot region that has been clicked
function [iSub,pos] = detClickSubplot(handles,varargin)

% retrieves the important data structs
hGUI = getappdata(handles.figSplitPlot,'hGUI');
hAx = findall(hGUI.panelPlot,'tag','axesCustomPlot'); 

% retrieves the location of the click-point
a = get(hAx,'CurrentPoint');
mP = [a(1,1) a(1,2)];

% determines the 
pos = detAllRegionPos(handles);

% determines the string of the number whose location coincides with the
% clicked group region
[L,LW,B,BH] = deal(pos(:,1),sum(pos(:,[1 3]),2),pos(:,2),sum(pos(:,[2 4]),2));
iSub = find((mP(1) > L) & (mP(1) < LW) & (mP(2) > B) & (mP(2) < BH));

% --- determines the position vectors of all the subplot regions
function pos = detAllRegionPos(handles)

% retrieves the important data structs
hAx = findall(0,'tag','axesCustomPlot'); 

% retrieves the axis position vector
aP = get(hAx,'Position');

% sets the indices of the horizontal/vertical lines
[pSubV,pSubH] = getAllLinePos(handles,1);
X = roundP(cellfun(@(x)(x(1,1)),pSubV),0.01);
Y = roundP(cellfun(@(x)(x(1,2)),pSubH),0.01);

% retrieves the positions of all the lines on the axis
Im = getRegionLineMap(pSubH,pSubV,aP);
[~,bbGrp] = getGroupIndex(Im == 0,'BoundingBox');
posG = [(bbGrp(:,1:2)) (bbGrp(:,3:4))]./repmat(aP([3 4]),size(bbGrp,1),2);
posG = roundP(posG,0.01);

%
pos = zeros(size(posG,1),4);
for i = 1:size(pos,1)
    % retrieves the x/y coordinates of the position vector
    [pX,pY] = pos2vec(roundP(posG(i,:),0.01));
        
    % determines the x-points closes to the line objects
    if (isempty(X))
        % no vertical lines, so use frame limits
        [xMin,xMax] = deal(0,1);
    else        
        % otherwise, calculate the closest limits
        xMin = min(1-any(pX == 0),X(argMin(abs(min(pX)-X))));
        xMax = max(any(pX == 1),X(argMin(abs(max(pX)-X))));            
    end
       
    % determines the y-points closes to the line objects
    if (isempty(Y))
        % no horizontal lines, so use frame limits
        [yMin,yMax] = deal(0,1);
    else
        % otherwise, calculate the closest limits
        yMin = min(1-any(pY == 0),Y(argMin(abs(min(pY)-Y))));
        yMax = max(any(pY == 1),Y(argMin(abs(max(pY)-Y))));            
    end
                
    % sets the final position vector
    pos(i,:) = [xMin yMin (xMax-xMin) (yMax-yMin)];
end

% sets the position of the groups
if (nargin == 2); return; end

% retrieves the locations of the subplot number objects
[L,LW,B,BH] = deal(pos(:,1),sum(pos(:,[1 3]),2),pos(:,2),sum(pos(:,[2 4]),2));
hNum = num2cell(findall(hAx,'tag','hNum'));
pNum = cell2mat(cellfun(@(x)(get(x,'position')),hNum,'un',0));
[~,jj] = sort(cellfun(@(x)(str2double(get(x,'string'))),hNum),'ascend');
pNum = pNum(jj,:);

% re-orders the position array to match the region numbering
pos = pos(cellfun(@(x)(find((x(1) > L) & (x(1) < LW) & ...
                     (x(2) > B) & (x(2) < BH))),num2cell(pNum,2)),:);

% --- creates a binary mask from the line regions
function Im = getRegionLineMap(pSubH,pSubV,aP)

% initialisations and memory allocation
Im = zeros(aP(4)+1,aP(3)+1);

% sets the vertical lines
for i = 1:length(pSubH)
    iC = (max(0,floor(pSubH{i}(1,1)*aP(3))):min(aP(3),ceil(pSubH{i}(2,1)*aP(3)))) + 1;
    Im(roundP(pSubH{i}(1,2)*aP(4)) + 1,iC) = 1;
end

% sets the vertical lines
for i = 1:length(pSubV)
    iR = (max(0,floor(pSubV{i}(1,2)*aP(4))):min(aP(4),ceil(pSubV{i}(2,2)*aP(4)))) + 1;
    Im(iR,roundP(pSubV{i}(1,1)*aP(3)) + 1) = 1;
end

% removes the frame outer edge 
[Im(1,:),Im(end,:),Im(:,1),Im(:,end)] = deal(1);

% --- creates a binary mask of each of the subregion lines
function Bline = getRegionLineBinary(posG,sz)

% memory allocations
[Btot,nReg] = deal(false(sz),size(posG,1));

% appends the regions to each of the total binary mask
for i = 1:nReg
    % sets up the row column indices
    iR = ceil(posG(i,2)):floor(posG(i,2)+posG(i,4));
    iC = ceil(posG(i,1)):floor(posG(i,1)+posG(i,3));
    [iR,iC] = deal(iR((iR > 0) & (iR <= sz(1))),iC((iC > 0) & (iC <= sz(2))));
    
    % sets the new binary mask
    Bnw = false(sz);
    [Bnw(iR(1),iC),Bnw(iR(end),iC)] = deal(true);
    [Bnw(iR,iC(1)),Bnw(iR,iC(end))] = deal(true);
    
    % appends the new binary mask to the total binary mask
    Btot = Btot | Bnw;
end

% determines the line segments linear indices
Breg = bwmorph(Btot & ~bwmorph(true(sz),'remove'),'thin',inf);
Bline = Breg & ~bwmorph(bwmorph(Breg,'branchpoints'),'dilate');

% --- determines the lines that surround each sub-region
function [pXL,pYL] = detRegionLines(sPara,sz)

% memory allocation
nReg = size(sPara.pos,1);
[pXL,pYL] = deal(cell(1,2));

% calculates the side coordinates for each sub-region
posG = sPara.pos.*repmat(sz([2 1]),nReg,2) + repmat([1 1 0 0],nReg,1);
posXY = cellfun(@(x)(calcPosSideCoord(x)),num2cell(posG,2),'un',0);

% determines the region lines from the position array
Bline = getRegionLineBinary(posG,sz+1);
iGrp = getGroupIndex(Bline);

% sets the x/y coordinates of each line object
[pX,pY] = deal(zeros(length(iGrp),2));
for i = 1:length(iGrp)
    % sets the coordinates for the new line
    [Y,X] = ind2sub(sz+1,iGrp{i});

    % sets the edge extensions for the horizontal/vertical lines
    if (range(X) < range(Y))
        % line is vertical
        [pX(i,:),pY(i,:)] = deal(mode(X)*[1 1],([min(Y) max(Y)]) + 2*[-1 1]);
    else
        % line is horizontal
        [pY(i,:),pX(i,:)] = deal(mode(Y)*[1 1],([min(X) max(X)]) + 2*[-1 1]);
    end
end

% determines which lines are horizontal or vertical
[isH,isV,isSet] = deal(diff(pY,[],2) == 0,diff(pX,[],2) == 0,NaN(length(iGrp),1));

% searches each of the sub-regions (from largest to smallest) determining
% which lines 
[~,iPos] = sort(posG(:,3).*posG(:,4));
for i = iPos'
    % goes through each of the 
    for j = 1:4    
        if (any(j == [1 2]))
            % checking a vertical side (has to have the same x-location and
            % y-location within limits of side)
            ii = (abs(posXY{i}(j,1) - pX(:,1)) < 2) & isV & ...
                 ((pY(:,1)+1.5) >= posXY{i}(j,3)) & ((pY(:,2)-1.5) <= posXY{i}(j,4));
        else
            % checking a horizontal side (has to have the same y-location
            % and x-location within limits of side)            
            ii = (abs(posXY{i}(j,3) - pY(:,1)) < 2) & isH & ...
                 ((pX(:,1)+1.5) >= posXY{i}(j,1)) & ((pX(:,2)-1.5) <= posXY{i}(j,2));            
        end
        
        % if there are matching lines, then set them as being set
        if (any(ii))
            isSet(ii) = true;
            if (sum(ii) > 1)
                % combines the coordinates of the two lines
                k = find(ii);
                pYnw = [min(pY(k,1),[],1) max(pY(k,2),[],1)];
                pXnw = [min(pX(k,1),[],1) max(pX(k,2),[],1)];
                
                % if so, then reset the coordinates of the lines
                [pX(k(1),:),pY(k(1),:)] = deal(pXnw,pYnw);
                [pX(k(2:end),:),pY(k(2:end),:)] = deal(NaN);                 
            end
        end
    end
end

% removes the nan rows from the arrays
ii = ~isnan(pX(:,1));
[pX,pY,isH,isV,isSet] = deal(pX(ii,:),pY(ii,:),isH(ii),isV(ii),isSet(ii));   
    
% determines if there are any orphan lines
if (any(~isSet))
    % if so, then determine the best match for these line     
    for i = find(~isSet)'
        % determines the matching inline lines
        if (isH(i))
            % case is for horizontal lines
            isMatch = (pY(:,1) == pY(i,1)) & isH & ...
                    any(abs(pX(:,[2 1])-repmat(pX(i,:),size(pX,1),1))==0,2); 
        else
            % case is for vertical lines
            isMatch = (pX(:,1) == pX(i,1)) & isV & ...
                    any(abs(pY(:,[2 1])-repmat(pY(i,:),size(pY,1),1))==0,2); 
        end
        
        % ensures the current line is not a match
        isMatch(i) = false;
        
        % combines the coordinates of the two lines
        j = find(isMatch,1,'first');
        pYnw = [min(pY([i,j],1),[],1) max(pY([i,j],2),[],1)];
        pXnw = [min(pX([i,j],1),[],1) max(pX([i,j],2),[],1)];
        
        % if so, then reset the coordinates of the lines
        [pX(j,:),pY(j,:)] = deal(pXnw,pYnw);
        [pX(i,:),pY(i,:)] = deal(NaN);        
    end
    
    % removes the nan rows from the arrays
    ii = ~isnan(pX(:,1));
    [pX,pY,isH,isV] = deal(pX(ii,:),pY(ii,:),isH(ii),isV(ii));    
end

% ensures the 
[pX,pY] = deal(min(pX,sz(2)),min(pY,sz(1)));

% sets the line coordinate arrays
[pXL{1},pYL{1}] = deal(pX(isV,:)/sz(2),pY(isV,:)/sz(1));
[pXL{2},pYL{2}] = deal(pX(isH,:)/sz(2),pY(isH,:)/sz(1));

% --- calculates the coordinates of the sides of a position vector
function posXY = calcPosSideCoord(pos)

% memory allocation
posXY = zeros(4);

% sets the coordinates for the left, right, top and bottom
posXY(1,:) = [pos(1)*[1 1],pos(2)+[0 pos(4)]];
posXY(2,:) = [sum(pos([1 3]))*[1 1],pos(2)+[0 pos(4)]];
posXY(3,:) = [pos(1)+[0 pos(3)],pos(2)*[1 1]];
posXY(4,:) = [pos(1)+[0 pos(3)],sum(pos([2 4]))*[1 1]];

% --------------------------------- %
% --- OBJECT PROPERTY FUNCTIONS --- %
% --------------------------------- %

% initialises the GUI properties
function initObjProps(handles)

% retrieves the segmentation parameters
eStr = {'off','on'};
sPara = getappdata(handles.figSplitPlot,'sPara');
      
% sets the properties for all the parameter edit boxes 
hEdit = findall(handles.figSplitPlot,'style','edit');
for i = 1:length(hEdit) 
    % resets the parameter values and callback function
    uD = get(hEdit(i),'UserData');
    pVal = eval(sprintf('sPara.%s',uD));
    
    % sets the editbox parameter value/callback function
    cFunc = @(hObj,e)SplitAxisRegions('editSegPara',hObj,[],handles); 
    set(hEdit(i),'String',num2str(pVal),'Callback',cFunc);    
end

% sets the main GUI properties
setMainGUIProps(handles,'off')
setObjEnable(handles.buttonSplitAxis,'off')
setObjEnable(handles.buttonCombine,'off')
setObjEnable(handles.buttonClear,size(sPara.pos,1)>1)

% sets up the axis table
setupAxisTable(handles)

% --- updates the main GUI properties
function setMainGUIProps(handles,state)

% retrieves the main GUI handles
hGUI = getappdata(handles.figSplitPlot,'hGUI');

% updates the panel properties
setPanelProps(hGUI.panelSolnData,state)
setPanelProps(hGUI.panelExptInfo,state)
setPanelProps(hGUI.panelPlotFunc,state)
setPanelProps(hGUI.panelFuncDesc,state)

% updates the menu item properties
setObjEnable(hGUI.menuFile,state)
setObjEnable(hGUI.menuPlot,state)
setObjEnable(hGUI.menuGlobal,state)

% sets the background colour of the text object
set(hGUI.textFuncDescBack,'BackgroundColor','k')

% if initialising the GUI, then clear the main axis
if (strcmp(state,'off'))
    % clears the main axis of any existing axis
    hAx = findall(hGUI.panelPlot,'type','axes'); 
    if (~isempty(hAx)); delete(hAx); end
           
    % sets the key press/release functions
    fcnKP = @KeyPressFcn;
    fcnKR = @KeyReleaseFcn;    
    
    % sets the axis properties
    hAx = axes('position',[0 0 1 1],'units','pixels');
    set(hAx,'parent',hGUI.panelPlot,'tag','axesCustomPlot',...
            'xticklabel',[],'xtick',[],'yticklabel',[],'ytick',[]);                   
else
    % otherwise, clear the temporary axis 
    hAx = findall(hGUI.panelPlot,'tag','axesCustomPlot');
    
    % deletes the custom plot axis
    if (~isempty(hAx)); delete(hAx); end
    [fcnKP,fcnKR] = deal([]);
end

% sets the key/press functions into the main GUI
set(hGUI.figFlyAnalysis,'resize',state)
set(hGUI.figFlyAnalysis,'KeyPressFcn',fcnKP,'KeyReleaseFcn',fcnKR)

% makes the parameter GUI invisible
if (strcmp(state,'off'))
    hPara = getappdata(hGUI.figFlyAnalysis,'hPara');
    if ~isempty(hPara); setObjVisibility(hPara,state); end    
end

% --- updates the axis table
function setupAxisTable(handles,varargin)

% retrieves the main GUI handles
sPara = getappdata(handles.figSplitPlot,'sPara');

% makes the GUI invisible
if nargin == 2
    % makes the GUI invisible
    setObjVisibility(handles.figSplitPlot,'off'); 
    pause(0.05);
    
    % updates the position array
    sPara = recalcPosArray(sPara);
    setappdata(handles.figSplitPlot,'sPara',sPara)
end

% initialisations
[nReg,Y0,X0] = deal(size(sPara.pos,1),10,10);
[HT,Data] = deal(calcTableHeight(nReg),num2cell([(1:nReg)',sPara.pos]));

% recalculates the gui object dimensions
fPos = get(handles.figSplitPlot,'position');
bPos = get(handles.buttonSplitAxis,'position');
pPosS = get(handles.panelSplitCount,'position');
pPosA = [X0 (Y0+sum(bPos([2 4]))) pPosS(3) (3.5*Y0+HT+2*bPos(4))];
pPosS = [X0 (Y0+sum(pPosA([2 4]))) pPosS(3:4)];
tPos = [X0 2.5*Y0+2*bPos(4) (pPosS(3)-2*X0) HT];

% updates the object dimensions
set(handles.panelAxisDim,'position',pPosA)
set(handles.tableAxisDim,'position',tPos,'Data',Data)
set(handles.panelSplitCount,'position',pPosS)
set(handles.figSplitPlot,'position',[fPos(1:3) (Y0+sum(pPosS([2 4])))])
autoResizeTableColumns(handles.tableAxisDim);

% makes the GUI invisible
if nargin == 2
    setObjEnable(handles.buttonClear,'off')
    setObjVisibility(handles.figSplitPlot,'on'); 
    pause(0.05);
end

% -------------------------------- %
% --- MOVEMENT TIMER FUNCTIONS --- %
% -------------------------------- %

% --- initialises the movement timer object
function t = initMovementTimer()

% global variables
global isMove hMove tMove
[isMove,hMove,tMove] = deal(false,cell(1,3),0.5);

% initialises the timer object
h = timerfindall;
if (~isempty(h))
    stop(h); delete(h)
end

% sets the timer object properties
t = timer; tic; 
set(t,'Period',0.1,'ExecutionMode','FixedRate','TimerFcn',@timerCDownFcn);

% starts the timer
start(t);

% --- the countdown timer callback function       
function timerCDownFcn(obj, event)

% global variables
global isMove hMove tMove

% determines if the user has moved the line object
if (isMove)
    % determines the time since the last movement
    tF = toc;
    
    % if greater than tolerance, then reset all the movement variables
    if (tF > tMove)        
        % turns off access to the line objects
        hAx = findall(0,'tag','axesCustomPlot');
        handles = guidata(hAx);
        setLineHTState(hAx,'off')                        
        
        % retrieves the index data of the lines
        hh = cell2mat(hMove');
        if (length(hh) == 1)
            iL = get(hh,'UserData');
        else
            iL = cell2mat(get(hh,'UserData'));
        end
        
        % retrieves the sub-region line object handles
        [hSub{1},hSub{2}] = deal(findall(hAx,'tag','hSubV'),findall(hAx,'tag','hSubH'));
        [pL{1},pL{2}] = getAllLinePos(handles,1);
        
        % resets the line locations        
        for i = 1:length(hh)
            k = hSub{iL(i,2)} == hh(i);
            updateLinePos(hh(i),pL{iL(i,2)}{k},[],[],1);            
            set(findobj(hh(i),'tag','bottom line'),'UserData',pL{iL(i,2)}{k})
        end
        
        % resets the stationary location of the moved line
        hLine = getappdata(hAx,'hLine');
        set(findobj(hLine,'tag','bottom line'),'UserData',getLinePos(hLine))
        
        % updates the line contrain functions
        for i = 1:length(hMove)
            cellfun(@(x)(updateLineConstrainFcn(x)),num2cell(hMove{i}));
        end      
        
        % updates the positions of all the subplot regions
        [pos,hSelT] = deal(detAllRegionPos(guidata(hAx)),findall(hAx,'tag','hSel'));
        [~,ii] = sort(cell2mat(get(hSelT,'UserData')),'ascend');        
        A = cellfun(@(x)(pos2vec(x)),num2cell(pos,2),'un',0);
        cellfun(@(x,y)(set(x,'xdata',y{1},'ydata',y{2})),num2cell(hSelT(ii)),A)        
        
        % updates the parameter struct with the new position array
        hFigSP = guidata(findall(0,'tag','figSplitPlot'));
        sPara = getappdata(hFigSP.figSplitPlot,'sPara');
        sPara.pos = roundP(pos,0.005);
        setappdata(hFigSP.figSplitPlot,'sPara',sPara);
        
        % updates the table data
        Data = num2cell([(1:size(sPara.pos,1))',sPara.pos]);
        set(hFigSP.tableAxisDim,'Data',Data)
        
        % resets the movement array/flag and reactivates the lines
        [hMove,isMove] = deal(cell(1,3),false);
        setLineHTState(hAx,'on')
    end
end

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- recalculates the subplot postional array
function sPara = recalcPosArray(sPara)

% memory allocation
[nRow,nCol] = deal(sPara.nRow,sPara.nCol);
[sPara.pos,nReg] = deal(zeros(nRow*nCol,4),nCol*nRow);

% memory allocation
sPara.ind = NaN(nReg,3);
[sPara.pData,sPara.plotD] = deal(cell(nReg,1));

% for each row/column initialise the subplot structs
[H,W] = deal(1/nRow,1/nCol);
for i = 1:nRow
    for j = 1:nCol
        % sets the parameter struct index/position
        sPara.pos((i-1)*nCol + j,:) = [(j-1)*W (i-1)*H W H];
    end
end

% --- converts a postion array into the x/y location rectangular arrays
function [vX,vY] = pos2vec(pos)

% sets the positions of the edges, and the sets the vector
[iX,iY] = deal([1 1 2 2],[1 2 2 1]);
[pX,pY] = deal(pos(1)+[0 pos(3)],pos(2)+[0 pos(4)]);
[vX,vY] = deal(pX(iX),pY(iY));

% ensures the vertices are within the limits [0,1]
[vX,vY] = deal(min(max(0,vX),1),min(max(0,vY),1));

% outputs in one array (if only one output variable)
if (nargout == 1); vX = [{vX},{vY}]; end

% --- 
function clearAxesObjects(hAx)

% retrieves the objects
hSub = findall(hAx,'tag','hSub');
hNum = findall(hAx,'tag','hNum');
hSel = findall(hAx,'tag','hSub');
hEdge = findall(hAx,'tag','hEdge');
hSubV = findall(hAx,'tag','hSubV');
hSubH = findall(hAx,'tag','hSubH');

% deletes the objects (if they exist)
if (~isempty(hSub)); delete(hSub); end
if (~isempty(hNum)); delete(hNum); end
if (~isempty(hNum)); delete(hSel); end
if (~isempty(hEdge)); delete(hEdge); end
if (~isempty(hSubV)); delete(hSubV); end
if (~isempty(hSubH)); delete(hSubH); end
