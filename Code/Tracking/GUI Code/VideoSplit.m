function varargout = VideoSplit(varargin)
% Last Modified by GUIDE v2.5 14-Oct-2018 02:19:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',      mfilename,...
                   'gui_Singleton', gui_Singleton,...
                   'gui_OpeningFcn',@VideoSplit_OpeningFcn,...
                   'gui_OutputFcn', @VideoSplit_OutputFcn,...
                   'gui_LayoutFcn', [] ,...
                   'gui_Callback',  []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State,varargin{:});
else
    gui_mainfcn(gui_State,varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before VideoSplit is made visible.
function VideoSplit_OpeningFcn(hObject,eventdata,handles,varargin)

% Choose default command line output for VideoSplit
handles.output = hObject;

% global variables
global fAlphaOn fAlphaOff ignoreMove tMove 
global updateFrm updateGrp pressCtrl isChange
[fAlphaOn, fAlphaOff, ignoreMove, isChange] = deal(0.6, 0.1, false, false);
[tMove, updateFrm, updateGrp, pressCtrl] = deal(tic, false, false, false);

% sets the input arguments
hMain = varargin{1};

% retrieves the 
setObjVisibility(hMain,'off')
iMov = getappdata(hMain,'iMov');
iDataM = getappdata(hMain,'iData');

% initialisation of the program data struct
iData = initDataStruct(iDataM,iMov);

% sets the data structs into the GUI
setappdata(hObject,'hMain',hMain)
setappdata(hObject,'iData',iData)
setappdata(hObject,'iDataM',iDataM)
setappdata(hObject,'hMainG',guidata(hMain))
setappdata(hObject,'iMov',getappdata(hMain,'iMov'))

% initialises the GUI object properties
initObjProps(handles,iData)

% updates the GUI object properties
setGUIFontSize(handles)
centreFigPosition(hObject);

% Update handles structure
guidata(hObject,handles);

% UIWAIT makes VideoSplit wait for user response (see UIRESUME)
uiwait(handles.figVidSplit);

% --- Outputs from this function are returned to the command line.
function varargout = VideoSplit_OutputFcn(hObject,eventdata,handles) 

% global variables
global vGrp isChange

% Get default command line output from handles structure
varargout{1} = vGrp;
varargout{2} = isChange;

%-------------------------------------------------------------------------%
%                      MENU ITEM CALLBACK FUNCTIONS                       %
%-------------------------------------------------------------------------%

% -------------------------------------------------------------------------
function menuExit_Callback(hObject,eventdata,handles)

% global variables
global vGrp isChange

% determines if there were any changes made to the video split parameters
if isChange
    % if so, prompt the user if they wish to update the changes
    uChoice = questdlg('Do you wish to update the video split properties?',...
                       'Update Video Split Properties','Yes','No','Yes');
    if isempty(uChoice)
        % user cancelled so exit the function
        return
    elseif strcmp(uChoice,'Yes')
        % user decided to keep the changes
        iData = getappdata(handles.figVidSplit,'iData');
        vGrp = iData.vGrp;
    else
        % user decided not to keep changes
        [vGrp,isChange] = deal([],false);
    end
else
    % if no change, then return an empty array
    vGrp = [];
end

% makes the main GUI visible again
hMain = getappdata(handles.figVidSplit,'hMain');
setObjVisibility(hMain,'on')

% stop and deletes the timer object
hTimer = timerfind('Tag', 'hTimerF');
if ~isempty(hTimer)
    stop(hTimer)
    delete(hTimer)
end

% deletes the current GUI
delete(handles.figVidSplit)

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figVidSplit_WindowButtonDownFcn(hObject, eventdata, handles)

% global variables
global pressCtrl fAlphaOn fAlphaOff

% if the mouse pointer is not correct, then exit
if ~strcmp(get(hObject,'Pointer'),'arrow')
    return
end

% initialisations
hAxG = handles.axesGroup;
mPos = get(handles.axesGroup,'currentpoint');
iData = getappdata(handles.figVidSplit,'iData');

% retrieves the current point and group limits
axP = [roundP(mPos(1,1)), mPos(1,2)];
xL = [iData.vGrp(1,1),iData.vGrp(end,2)];

% if the selected point is not within the limits of groups then exit
isIn = (axP(2)>=0) && (axP(2)<=1) && (axP(1)>xL(1)) && (axP(1)<=xL(2));
if (~isIn); return; end

% if a new group is selected then switch the selected groups
cGrp = find((axP(1) >= iData.vGrp(:,1)) & (axP(1) <= iData.vGrp(:,2)));
if ~isempty(cGrp)
    if pressCtrl
        % 
        dfAlpha = 1;
        hP = findall(hAxG,'tag','hGrp');
        hPG = findall(hP,'UserData',cGrp);
        
        %
        fOtherOn = cellfun(@(x)(get(findall(x,'tag','patch'),...
                       'FaceAlpha')),num2cell(hP(hP~=hPG))) == fAlphaOn;
        
        %
        if get(findall(hPG,'tag','patch'),'FaceAlpha') == fAlphaOn 
            if any(fOtherOn)
                dfAlpha = 0;
                updatePatchFaceAlpha(hAxG, cGrp, fAlphaOff);
            end
        else
            updatePatchFaceAlpha(hAxG, cGrp, fAlphaOn);
        end
        
        % updates the object properties
        canMerge = (sum(fOtherOn)+dfAlpha)>1;
        setObjEnable(handles.buttonMerge,canMerge)
        setObjEnable(handles.buttonSplit,~canMerge)
        set(handles.textGroupSelCount,...
                                'string',num2str(sum(fOtherOn)+dfAlpha))
    else
        %
        setObjEnable(handles.buttonSplit,'on')
        setObjEnable(handles.buttonMerge,'off')
        set(handles.textGroupSelCount,'string','1')
        
        % removes the selection for the other groups
        indOff = num2cell(find((1:size(iData.vGrp,1)) ~= cGrp));
        cellfun(@(x)(updatePatchFaceAlpha(hAxG, x, fAlphaOff)),indOff,'un',0);
        
        cGrpC = str2double(get(handles.grpCountEdit,'string'));
        if (cGrpC ~= cGrp)
            switchSelectedGroup(handles,iData,cGrp,cGrpC)
        end
    end
end

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figVidSplit_WindowButtonUpFcn(hObject, eventdata, handles)

global updateGrp tMove

if updateGrp
    tMove = tic;
end

% --- Executes on key press with focus on figVidSplit or any of its controls.
function figVidSplit_WindowKeyPressFcn(hObject, eventdata, handles)

% global variables
global pressCtrl

% flag whether control is currently being pressed
pressCtrl = strcmp(eventdata.Key,'control');

% --- Executes on key release with focus on figVidSplit or any of its controls.
function figVidSplit_WindowKeyReleaseFcn(hObject, eventdata, handles)

% global variables
global pressCtrl

% flag that control has been released
pressCtrl = false;

% --------------------------------- %
% --- GROUP SELECTION FUNCTIONS --- %
% --------------------------------- %

% --- callback function for the first frame/sub-movie button --------------
function FirstButtonCallback(hObject, eventdata, handles)

% retrieves the image data struct
iData = getappdata(handles.figVidSplit,'iData');
isGrp = strcmp(get(hObject,'UserData'),'Group');

% updates the selection enabled properties
hObj = {handles.frmCountEdit,handles.grpCountEdit};
valLim = [iData.nFrm,size(iData.vGrp,1)];

% updates the selection properties
set(hObj{1+isGrp},'string','1')
updateSelectionEnable(handles, 1+isGrp, 1, valLim(1+isGrp))

% updates the appropriate axes (based on the type)
if isGrp
    % updates the video group selection axes
    switchSelectedGroup(handles,iData,1,iData.cGrp)
    iData.cGrp = 1;
else
    % updates the image axes
    iData.cFrm = 1;
    updateFrameMarkerPos(handles)
    updateImageAxes(handles);
end

% updates the data struct
setappdata(handles.figVidSplit,'iData',iData)

% --- callback function for the last frame/sub-movie button ---------------
function LastButtonCallback(hObject, eventdata, handles)

% retrieves the image data struct
iData = getappdata(handles.figVidSplit,'iData');
isGrp = strcmp(get(hObject,'UserData'),'Group');

% updates the selection enabled properties
hObj = {handles.frmCountEdit,handles.grpCountEdit};
valLim = [iData.nFrm,size(iData.vGrp,1)];

% updates the selection properties
set(hObj{1+isGrp},'string',num2str(valLim(1+isGrp)))
updateSelectionEnable(handles, 1+isGrp, valLim(1+isGrp), valLim(1+isGrp))

% updates the appropriate axes (based on the type)
if isGrp
    % updates the video group selection axes
    switchSelectedGroup(handles,iData,size(iData.vGrp,1),iData.cGrp)
    iData.cGrp = size(iData.vGrp,1);    
else
    % updates the image axes
    iData.cFrm = iData.nFrm;
    updateFrameMarkerPos(handles)
    updateImageAxes(handles);
end

% updates the data struct
setappdata(handles.figVidSplit,'iData',iData)

% --- callback function for the previous frame/sub-movie button -----------
function PrevButtonCallback(hObject, eventdata, handles)

% retrieves the image data struct
iData = getappdata(handles.figVidSplit,'iData');
isGrp = strcmp(get(hObject,'UserData'),'Group');

% updates the selection enabled properties
hObj = {handles.frmCountEdit,handles.grpCountEdit};
valLim = [iData.nFrm,size(iData.vGrp,1)];

% updates the corresponding editbox value
currVal = str2double(get(hObj{1+isGrp},'string'));
set(hObj{1+isGrp},'string',num2str(currVal-1))
updateSelectionEnable(handles, 1+isGrp, currVal-1, valLim(1+isGrp))

% updates the appropriate axes (based on the type)
if isGrp
    % updates the video group selection axes
    switchSelectedGroup(handles,iData,iData.cGrp-1,iData.cGrp)
    iData.cGrp = iData.cGrp - 1;
else
    % updates the image axes
    iData.cFrm = iData.cFrm - 1;
    updateFrameMarkerPos(handles)
    updateImageAxes(handles);
end

% updates the data struct
setappdata(handles.figVidSplit,'iData',iData)

% --- callback function for the previous frame/sub-movie button -----------
function NextButtonCallback(hObject, eventdata, handles)

% retrieves the image data struct
iData = getappdata(handles.figVidSplit,'iData');
isGrp = strcmp(get(hObject,'UserData'),'Group');

% updates the selection enabled properties
hObj = {handles.frmCountEdit,handles.grpCountEdit};
valLim = [iData.nFrm,size(iData.vGrp,1)];

% updates the corresponding editbox value
currVal = str2double(get(hObj{1+isGrp},'string'));
set(hObj{1+isGrp},'string',num2str(currVal+1))
updateSelectionEnable(handles, 1+isGrp, currVal+1, valLim(1+isGrp))

% updates the appropriate axes (based on the type)
if isGrp
    % updates the video group selection axes
    switchSelectedGroup(handles,iData,iData.cGrp+1,iData.cGrp)
    iData.cGrp = iData.cGrp + 1;
else
    % updates the image axes
    iData.cFrm = iData.cFrm + 1;
    updateFrameMarkerPos(handles)
    updateImageAxes(handles);
end

% updates the data struct
setappdata(handles.figVidSplit,'iData',iData)

% --- Executes on editting the frame/sub-movie edit box -------------------
function CountEditCallback(hObject, eventdata, handles)

% retrieves the image data struct
iData = getappdata(handles.figVidSplit,'iData');
nwVal = str2double(get(hObject,'string'));

% updates the frame/sub-movie index
if strcmp(get(hObject,'UserData'),'Group')
    cGrp0 = iData.cGrp;
    [pStr,nwLim,isGrp] = deal('iData.cGrp',[1 size(iData.vGrp,1)],true);    
else
    [pStr,nwLim,isGrp] = deal('iData.cFrm',[1 iData.nFrm],false);
end

% checks to see if the new value is valid
if (chkEditValue(nwVal,nwLim,1))
    % if so, then updates the counter and the image frame
    eval(sprintf('%s = nwVal;',pStr));
    setappdata(handles.figVidSplit,'iData',iData);
    
    % updates the selection enabled properties
    updateSelectionEnable(handles, 1+isGrp, nwVal, nwLim(2))
    if isGrp
        % updates the video group selection axes
        switchSelectedGroup(handles,iData,nwVal,cGrp0)
    else
        % updates the image axes
        updateFrameMarkerPos(handles)
        updateImageAxes(handles);
    end
else
    % resets the edit box string to the last valid value
    set(hObject,'string',num2str(eval(pStr)))
end

% --- updates the position of the frame marker
function updateFrameMarkerPos(handles)

% global variables
global ignoreMove

% initialisations
cFrm = str2double(get(handles.frmCountEdit,'string'));

% resets the 
ignoreMove = true;
hLine = findall(handles.axesGroup,'tag','hLine');
hAPI = iptgetapi(hLine);
hAPI.setPosition([cFrm 0;cFrm 1]);
ignoreMove = false;

% ------------------------------------ %
% --- GROUP FRAME OBJECT CALLBACKS --- %
% ------------------------------------ %

% --- Executes on button press in buttonSetLower.
function buttonSetLower_Callback(hObject, eventdata, handles)

% global variables
global isChange

% initialisations
eStr = [];
cGrp = str2double(get(handles.grpCountEdit,'string'));
cFrm = str2double(get(handles.frmCountEdit,'string'));

% determines if the upper limit is valid
iData = getappdata(handles.figVidSplit,'iData');
if cFrm >= iData.vGrp(cGrp,2)
    % if not, then exit after displaying an error
    eStr = 'Error! Lower limit can''t be more than or equal to lower limit.';
else
    nwLim = getGroupDomain(iData,cGrp);
    if cFrm < nwLim(1)
        eStr = 'Error! Lower limit can''t overlap another group.';
    end
end

% if there was an error, output the message and exit the function
if ~isempty(eStr)
    waitfor(errordlg(eStr,'Invalid Lower Limit','modal'))
    return 
end

% updates the data struct
[iData.vGrp(cGrp,1),isChange] = deal(cFrm,true);
setappdata(handles.figVidSplit,'iData',iData)
set(handles.editGrpStart,'string',num2str(cFrm))

% updates the group position
hRect = findall(handles.axesGroup,'tag','hGrp','UserData',cGrp);
resetGroupPosition(handles,hRect,iData.vGrp(cGrp,:))

% --- Executes on button press in buttonSetUpper.
function buttonSetUpper_Callback(hObject, eventdata, handles)

% global variables
global isChange

% initialisations
eStr = [];
cGrp = str2double(get(handles.grpCountEdit,'string'));
cFrm = str2double(get(handles.frmCountEdit,'string'));

% determines if the upper limit is valid
iData = getappdata(handles.figVidSplit,'iData');
if cFrm <= iData.vGrp(cGrp,1)
    eStr = 'Error! Upper limit can''t be less than or equal to lower limit.';
else
    nwLim = getGroupDomain(iData,cGrp);
    if cFrm > nwLim(2)
        eStr = 'Error! Upper limit can''t overlap another group.';
    end
end

% if there was an error, output the message and exit the function
if ~isempty(eStr)
    waitfor(errordlg(eStr,'Invalid Upper Limit','modal'))
    return 
end

% updates the data struct
[iData.vGrp(cGrp,2),isChange] = deal(cFrm,true);
setappdata(handles.figVidSplit,'iData',iData)
set(handles.editGrpFinish,'string',num2str(cFrm))

% updates the group position
hRect = findall(handles.axesGroup,'tag','hGrp','UserData',cGrp);
resetGroupPosition(handles,hRect,iData.vGrp(cGrp,:))

% --- Executes on updating editGrpStart.
function editGrpStart_Callback(hObject,eventdata,handles)

% global variables
global isChange 

% initialisations
nwVal = str2double(get(hObject,'string'));
cGrp = str2double(get(handles.grpCountEdit,'string'));
iData = getappdata(handles.figVidSplit,'iData');

% sets the limits on the start index
nwLim = getGroupLimits(iData,cGrp,true);
    
% checks to see if the new value is valid
if (chkEditValue(nwVal,nwLim,1))
    % if so, then update the data struct
    [iData.vGrp(cGrp,1),isChange] = deal(nwVal,true);
    setappdata(handles.figVidSplit,'iData',iData)
    
    % resets the position of the group
    hRect = findall(handles.axesGroup,'tag','hGrp','UserData',cGrp);
    resetGroupPosition(handles,hRect,iData.vGrp(cGrp,:))
else
    % if not, then revert the last value
    set(hObject,'string',num2str(iData.vGrp(cGrp,1)))
end
    
% --- Executes on updating editGrpFinish.
function editGrpFinish_Callback(hObject,eventdata,handles)

% global variables
global isChange 

% initialisations
nwVal = str2double(get(hObject,'string'));
cGrp = str2double(get(handles.grpCountEdit,'string'));
iData = getappdata(handles.figVidSplit,'iData');

% sets the limits on the start index
nwLim = getGroupLimits(iData,cGrp,false);
    
% checks to see if the new value is valid
if (chkEditValue(nwVal,nwLim,1))
    % if so, then update the data struct
    [iData.vGrp(cGrp,2),isChange] = deal(nwVal,true);
    setappdata(handles.figVidSplit,'iData',iData)
    
    % resets the position of the group
    hRect = findall(handles.axesGroup,'tag','hGrp','UserData',cGrp);
    resetGroupPosition(handles,hRect,iData.vGrp(cGrp,:))
else
    % if not, then revert the last value
    set(hObject,'string',num2str(iData.vGrp(cGrp,2)))
end

% ------------------------------------- %
% --- GROUP ACTION OBJECT CALLBACKS --- %
% ------------------------------------- %

% --- Executes on button press in buttonMerge.
function buttonMerge_Callback(hObject,eventdata,handles)

% global variables
global fAlphaOn

% determines which groups are currently selected
hP = findall(handles.axesGroup,'tag','hGrp');
isOn = cellfun(@(x)(get(findall(x,'tag','patch'),...
               'FaceAlpha') == fAlphaOn),num2cell(hP));
indOn = cell2mat(get(hP(isOn),'UserData'));           

% determines if the group selection is feasible for merging
if any(diff(sort(indOn)) > 1)
    % if the selected blocks are not contiguous then output an error
    eStr = 'Error! Only contiguously selected groups blocks can be merged.';
    waitfor(errordlg(eStr,'Group Block Merge Error','modal'))
else
    % otherwise, prompt the user if they want to merge the groups
    uChoice = questdlg('Are you sure you want to merge the selected groups?',...
                   'Merge Selected Video Groups?','Yes','No','Yes');    
    if strcmp(uChoice,'Yes')
        % is so, then merges the selected groups
        mergeGroupMarkers(handles, hP(isOn))
        setObjEnable(hObject,'off')
    end
end

% --- Executes on button press in buttonSplit.
function buttonSplit_Callback(hObject,eventdata,handles)

% prompts the user if they want to split the current group
uChoice = questdlg('Are you sure you want to split the current group?',...
                   'Split Current Video Group?','Yes','No','Yes');
if strcmp(uChoice,'Yes')
    % is so, then split the group into 2
    splitGroupMarkers(handles)
end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the GUI object properties
function initObjProps(handles,iData)

% initialisations
[hAx,hAxG] = deal(handles.axesImg,handles.axesGroup);

% initialises the axes properties
set(hAx,'xtick',[],'ytick',[],'xticklabel',[],'yticklabel',[])

% initialises the edit box values
set(handles.grpCountEdit,'string','1');
set(handles.textFrameCount,'string',num2str(iData.nFrm));
set(handles.frmCountEdit,'string',num2str(iData.vGrp(1,1)));
set(handles.editGrpStart,'string',num2str(iData.vGrp(1,1)));
set(handles.editGrpFinish,'string',num2str(iData.vGrp(1,2)));

% updates the 
initSelectionProps(handles)
updateSelectionEnable(handles, 1, iData.vGrp(1,1), iData.nFrm)
updateSelectionEnable(handles, 2, 1, size(iData.vGrp,1))

% updates the image axes
ImgNw = updateImageAxes(handles);
pPos = get(handles.panelViewVid,'position');
Wnw = roundP(pPos(4)*size(ImgNw,2)/size(ImgNw,1));
dW = Wnw-pPos(3);

resetObjPos(handles.axesImg,'width',dW,1);
resetObjPos(handles.panelViewVid,'width',dW,1);
resetObjPos(handles.axesGroup,'width',dW,1);
resetObjPos(handles.panelViewGroup,'width',dW,1);
resetObjPos(handles.panelOuterPanel,'width',dW,1);
resetObjPos(handles.figVidSplit,'width',dW,1);

% initialises the group frame axes
cla(hAxG)
set(hAxG,'xtick',[],'ytick',[],'xticklabel',[],'yticklabel',[],...
         'xlim',[1 iData.nFrm] + 0.5*[-1 1],'yLim',[0 1],'box','on')
initFrameMarker(handles,iData)
initGroupMarkers(handles,iData)

% starts the frame timer function
start(timer('StartDelay',0.5, 'TimerFcn',{@frameTimerFcn,handles},...
            'Period', 0.01, 'tag', 'hTimerF', 'ExecutionMode', 'fixedrate'));
        
% --- initialisation of the program data struct
function iData = initDataStruct(iDataM,iMov)

% sets the video group indices
if isfield(iMov,'vGrp')
    % if the video group indices exist,then retrieve them
    if isempty(iMov.vGrp)
        vGrp = [1,iDataM.nFrm];        
    else
        vGrp = iMov.vGrp;
    end
else
    % if no such group exists,then initialise the video group array
    vGrp = [1,iDataM.nFrm];
end

% creates the gui data struct
iData = struct('cFrm',1,'nFrm',iDataM.nFrm,'cGrp',1,'vGrp',vGrp);

% --- updates the main display image
function ImgNw = updateImageAxes(handles)

% initialisations
hAx = handles.axesImg;
cFrm = str2double(get(handles.frmCountEdit,'string'));

% retrieves the data structs from the GUI
iMov = getappdata(handles.figVidSplit,'iMov');
iDataM = getappdata(handles.figVidSplit,'iDataM');
hMainG = getappdata(handles.figVidSplit,'hMainG');

% retrieves the new image
ImgNw = getDispImage(iDataM,iMov,cFrm,false,hMainG);

% updates the image axes with the new image
hImg = findobj(hAx,'type','image');
if (isempty(hImg))
    % if there is no image object, then create a new one
    imagesc(uint8(ImgNw),'parent',hAx);    
    set(hAx,'xtick',[],'ytick',[],'xticklabel',[],'yticklabel',[]);
    set(hAx,'ycolor','w','xcolor','w','box','off')           
    colormap(hAx,gray)
    axis(hAx,'image')
    
    if (isempty(ImgNw))
        set(handles.frmCountEdit,'ForegroundColor','r')
    else
        set(handles.frmCountEdit,'ForegroundColor','k')
    end    
else
    % updates the axes image
    if (max(get(hAx,'clim')) < 10)
        set(hImg,'cData',double(ImgNw))    
    else
        set(hImg,'cData',uint8(ImgNw))    
    end
    
    % otherwise, update the image object with the new image    
    if (isempty(ImgNw))
        set(handles.frmCountEdit,'ForegroundColor','r')        
    else        
        axis(hAx,[1 size(ImgNw,2) 1 size(ImgNw,1)]); 
        set(handles.frmCountEdit,'ForegroundColor','k')
    end
end

% --- 
function updateSelectionEnable(handles, Type, iIndex, nIndex)

%
isEnable = [repmat(iIndex>1,1,2),repmat(iIndex<nIndex,1,2)];
    
% next/last buttons and enable the first/previous buttons
setSelectButtonEnable(handles,'on',Type,find(isEnable));
setSelectButtonEnable(handles,'off',Type,find(~isEnable));
    
% sets the selection button enabled properties
function setSelectButtonEnable(handles,State,Type,Index)

if isempty(Index)
    return
else
    hObj = {{'frmFirstButton','frmPrevButton','frmNextButton','frmLastButton'},...
            {'grpFirstButton','grpPrevButton','grpNextButton','grpLastButton'}};
end

hObjNw = hObj{Type}(Index);
for i = 1:length(hObjNw)
    setObjEnable(eval(sprintf('handles.%s',hObjNw{i})),State)
end

% --- sets the callback functions for the frame/movie selection objects ---
function initSelectionProps(handles)

% sets the base object string and the object types
wStr = {'FirstButton','LastButton','NextButton',...
        'PrevButton','CountEdit'};
uStr = {'Frame','Group'};    
pStr = {'frm','grp'};
    
% loops through all the selection property objects initialising the
% callback functions
for i = 1:length(wStr)
    for j = 1:length(pStr)
        % sets the current object handle
        hObj = eval(sprintf('handles.%s%s',pStr{j},wStr{i}));
        
        % sets the callback function and userdata strings
        cFunc = sprintf('%sCallback',wStr{i});
        bFunc = @(hObj,e)VideoSplit(cFunc,hObj,[],guidata(hObj));
        set(hObj,'Callback',bFunc,'UserData',uStr{j})
    end
end

% ----------------------------------- %
% ---   FRAME MARKER FUNCTIONS    --- %
% ----------------------------------- %

% --- initialises the frame marker
function initFrameMarker(handles,iData)

% axis initialisations
hAxG = handles.axesGroup;
hold(hAxG,'on')

% creates the line object
xL = [1 iData.nFrm];
mStr = {'end point 1','end point 2'};

% creates the line object
hLine = imline(hAxG, iData.vGrp(1,1)*[1 1], [0 1]);
set(hLine,'tag','hLine','UserData',0)
cellfun(@(x)(set(findall(hLine,'tag',x),'Marker','.','hittest','off',...
                               'MarkerSize',20,'color','k')),mStr)
set(findall(hLine,'tag','top line'),'LineWidth',2,'color','k')
                           
% sets the position constraint and position callback functions
hAPI = iptgetapi(hLine);
hAPI.addNewPositionCallback(@(p)frmMove(p,handles,hLine)); 
hAPI.setPositionConstraintFcn(makeConstrainToRectFcn('imline',xL,[0 1]));        

% --- 
function frmMove(pPos,handles,hLine)

% global variables
global tMove updateFrm ignoreMove
[tMove,updateFrm] = deal(tic,true);

% exits the function if ignoring
if ignoreMove; return; end

% updates the time object
iFrm = get(hLine,'UserData') + 1;
set(hLine,'UserData', iFrm)
cFrm = roundP(pPos(1,1));

% updates the frame index
set(handles.frmCountEdit,'string',num2str(cFrm));

% --- 
function frameTimerFcn(obj, event, handles)

% global variables
global tMove updateFrm updateGrp

% if updating (and sufficient time has passed) then update the image axes
% and check the group selection feasibility
if updateFrm
    if (toc(tMove) > 0.1)
        updateImageAxes(handles);
        updateFrm = false;
    end
elseif updateGrp
    if ~isnan(tMove)
        if (toc(tMove) > 0.1)
            checkGroupFeas(handles)
            updateGrp = false;
        end    
    end
end

% --- determines if the group limits are feasible (and fixes them if not)
function checkGroupFeas(handles)

% initialisations
hAxG = handles.axesGroup;
cGrp = str2double(get(handles.grpCountEdit,'string'));

% retrieves the data structs from the GUI
iData = getappdata(handles.figVidSplit,'iData');
nwLim = getGroupDomain(iData,cGrp);

% determines the current location of the limits
hRect = findall(hAxG,'tag','hGrp','UserData',cGrp);
hAPI = iptgetapi(hRect);
fPos = hAPI.getPosition();
fLim = roundP(fPos(1) + [0 fPos(3)])-[0 1];

% updates the group position (if outside of limits
if fLim(1) < nwLim(1) 
    fLim(1) = nwLim(1); 
    resetGroupPosition(handles,hRect,fLim)    
elseif fLim(2) > nwLim(2)
    fLim(2) = nwLim(2); 
    resetGroupPosition(handles,hRect,fLim)
end

% --- retrieves the domain limits for the group, cGrp
function nwLim = getGroupDomain(iData,cGrp)

[nwLim,N] = deal([1 iData.nFrm],size(iData.vGrp,1));

if (cGrp > 1); nwLim(1) = iData.vGrp(cGrp-1,2)+1; end
if (cGrp < N); nwLim(2) = iData.vGrp(cGrp+1,1)-1; end

% ----------------------------------- %
% ---   GROUP MARKER FUNCTIONS    --- %
% ----------------------------------- %

% --- initialises the markers for each video index group
function initGroupMarkers(handles,iData)

% global variables
global fAlphaOn

% creates the group markers for each region
nGrp = size(iData.vGrp,1);
for i = 1:nGrp
    hRect = createGroupMarker(handles,i,iData.vGrp(i,:),true);
    if i == 1
        set(findall(hRect,'tag','patch'),'FaceAlpha',fAlphaOn)
    end
end

% resets the groups markers into the correct order
hAxG = handles.axesGroup;
set(hAxG, 'Children',flipud(get(hAxG, 'Children')))
set(handles.textGroupCount,'string',num2str(nGrp))

% --- splits the currently selected into two separate groups
function splitGroupMarkers(handles)

% global variables
global isChange 

% initialisations
hAxG = handles.axesGroup;
iData = getappdata(handles.figVidSplit,'iData');
cGrp = str2double(get(handles.grpCountEdit,'string'));

%
isChange = true;
hGrp = findall(hAxG,'tag','hGrp');
hGrpS = findall(hGrp,'UserData',cGrp);
resetOtherGroupProps(iData,hGrp,cGrp,1);

% recalculates the new limits
hAPI = iptgetapi(hGrpS);
fPos = hAPI.getPosition();
fLim = roundP(fPos(1)+[0 fPos(3)]);
vGrpNw = fLim(1) + [0 floor(fPos(3)/2)];
vGrpNw = [vGrpNw;[(vGrpNw(1,2)+1) fLim(2)]];

% updates the video group index array
iData.vGrp = [iData.vGrp(1:(cGrp-1),:);vGrpNw;iData.vGrp((cGrp+1):end,:)];
setappdata(handles.figVidSplit,'iData',iData)

% resets the upper limit values
set(handles.editGrpFinish,'string',num2str(vGrpNw(1,2)))

% resets the position of the first group, and creates another
resetGroupPosition(handles,hGrpS,vGrpNw(1,:));
createGroupMarker(handles,cGrp+1,vGrpNw(2,:),false);
updateSelectionEnable(handles, 2, cGrp(1), size(iData.vGrp,1))

%
set(handles.textGroupSelCount,'string','1')
set(handles.textGroupCount,'string',num2str(size(iData.vGrp,1)))

% --- merges 2 or more group marker objects
function mergeGroupMarkers(handles, hMerge)

% global variables
global fAlphaOn isChange

% initialisations
isChange = true;
hAxG = handles.axesGroup;
iData = getappdata(handles.figVidSplit,'iData');

% determines the groups which are currently selected
cGrp = cell2mat(get(hMerge,'UserData'));
[cGrp,iSort] = sort(cGrp);
hMerge = hMerge(iSort);

% removes the merged groups
isOK = true(size(iData.vGrp,1),1);
isOK(cGrp(2:end)) = false;
iData.cGrp = cGrp(1);
iData.vGrp(cGrp(1),2) = iData.vGrp(cGrp(end),2);
iData.vGrp = iData.vGrp(isOK,:);
setappdata(handles.figVidSplit,'iData',iData)

% resets the position of the merged group and deletes the others
resetGroupPosition(handles,hMerge(1),iData.vGrp(cGrp(1),:));
updatePatchFaceAlpha(hAxG, cGrp(1), fAlphaOn);
for i = 2:length(hMerge); delete(hMerge(i)); end

% resets the other GUI object properties
set(handles.editGrpStart,'string',num2str(iData.vGrp(cGrp(1),1)))
set(handles.editGrpFinish,'string',num2str(iData.vGrp(cGrp(1),2)))
setObjEnable(handles.buttonSplit,diff(iData.vGrp(cGrp(1),:))>50)
set(handles.grpCountEdit,'string',num2str(cGrp(1)))
set(handles.textGroupCount,'string',num2str(size(iData.vGrp,1)))
set(handles.textGroupSelCount,'string','1')

% updates the properties of the other groups and the selection buttons
hGrp = findall(hAxG,'tag','hGrp');
resetOtherGroupProps(iData,hGrp,cGrp(end),-diff(cGrp([1 end])))
updateSelectionEnable(handles, 2, cGrp(1), size(iData.vGrp,1))

% --- resets the properties of the other groups
function resetOtherGroupProps(iData,hGrp,cGrp,iOfs)

% re-orders the userdata flags of the other groups
grpCol = distinguishable_colors(size(iData.vGrp,1)+1);
for i = 1:length(hGrp)
    cGrpNw = get(hGrp(i),'UserData');
    if cGrpNw > cGrp
        set(hGrp(i),'UserData',cGrpNw+iOfs)
        set(findall(hGrp(i),'tag','patch'),'facecolor',grpCol(cGrpNw+iOfs,:))
    end
end

% --- resets the position of the 
function resetGroupPosition(handles,hRect,fLim)

% global variables
global ignoreMove

% resets the position of the group rectangle 
ignoreMove = true;
hAPI = iptgetapi(hRect);
hAPI.setPosition([fLim(1) 0 diff(fLim) 1])
ignoreMove = false;

% resets the group start/finish frame indices
set(handles.editGrpStart,'string',num2str(fLim(1)))
set(handles.editGrpFinish,'string',num2str(fLim(2)))

% --- creates the group marker for the group index, cGrp
function hRect = createGroupMarker(handles,cGrp,fLim,isInit)

% global variables
global fAlphaOff

% initialisations
iData = getappdata(handles.figVidSplit,'iData');
grpCol = distinguishable_colors(size(iData.vGrp,1));
sStr = {'minx','maxx','miny','maxy'};
mStr = {'side marker','corner marker'};


% axis initialisations
hAxG = handles.axesGroup;
hold(hAxG,'on')

% creates the imrect object
hRect = imrect(hAxG, [fLim(1) 0 fLim(2)-fLim(1) 1]);
set(hRect,'tag','hGrp','UserData',cGrp)
set(findall(hRect,'tag','patch'),'facealpha',fAlphaOff,...
                                 'facecolor',grpCol(cGrp,:))

% removes the side markers                             
rmvStrS = cellfun(@(x)(sprintf('%s %s',x,mStr{1})),sStr,'un',0);
cellfun(@(x)(setObjVisibility(findall(hRect,'tag',x),'off')),rmvStrS)                            

% removes the corner markers
for i = 1:2
	rmvStrC = cellfun(@(x)(sprintf('%s %s %s',sStr{i},x,mStr{2})),sStr(3:4),'un',0);
    cellfun(@(x)(setObjVisibility(findall(hRect,'tag',x),'off')),rmvStrC)                            
end

% removes the hittest capabilities of the side/patch objects
htStr = {'miny top line','maxy top line','patch'};
cellfun(@(x)(set(findall(hRect,'tag',x),'hittest','off')),htStr)
set(findall(hRect,'tag','wing line'),'linestyle','none')

% sets the position constraint and position callback functions
hAPI = iptgetapi(hRect);
hAPI.addNewPositionCallback(@(p)grpMove(p,handles,hRect)); 

% removes the hold on the axes
hold(hAxG,'on')

% resets the order of the objects (frame marker on top then groups)
if ~isInit
    hGrp = findall(hAxG, 'tag', 'hGrp');
    hLine = findall(hAxG, 'tag', 'hLine');
    set(hAxG, 'Children', [hLine;flipud(hGrp)])
end

% --- callback function for moving the groups
function grpMove(pPos,handles,hRect)

% global variables
global updateGrp tMove ignoreMove isChange
[updateGrp,tMove,isChange] = deal(true,NaN,true);

% exits the function if ignoring
if ignoreMove; return; end

%
cGrp = get(hRect,'UserData');
iData = getappdata(handles.figVidSplit,'iData');

% ensures the correct group has been selected
cGrpC = str2double(get(handles.grpCountEdit,'string'));
if cGrpC ~= cGrp
    switchSelectedGroup(handles,iData,cGrp,cGrpC)
end

% updates the limits on the screen
[fLim,eStr] = deal(roundP(pPos(1)+[0 pPos(3)])-[0 1],{'off','on'});

% updates the limits
iData.vGrp(cGrp,:) = fLim;
if size(iData.vGrp,1) > 1
    %
    nwLim = [1 iData.nFrm];
    
    % resets the upper limit of the 
    if cGrp > 1
        % sets the new lower/upper limits of the adjacent groups
        nwLim(1) = iData.vGrp(cGrp-1,2)+1;
    end
    
    %
    if cGrp < size(iData.vGrp,1)
        % sets the new lower/upper limits of the adjacent groups
        nwLim(2) = iData.vGrp(cGrp+1,1)-1;
    end
    
    %
%     updateGroupLimits(hRect,nwLim);    
    if (fLim(1) < nwLim(1)) || (fLim(2) > nwLim(2))
        fLim = [max(fLim(1),nwLim(1)),min(fLim(2),nwLim(2))];
        iData.vGrp(cGrp,:) = [max(iData.vGrp(cGrp,1),nwLim(1)),...
                              min(iData.vGrp(cGrp,2),nwLim(2))];
        resetGroupPosition(handles,hRect,fLim)
    end
end

% resets the groups positions
setappdata(handles.figVidSplit,'iData',iData)
set(handles.editGrpStart,'string',num2str(fLim(1)))
set(handles.editGrpFinish,'string',num2str(fLim(2)))
setObjEnable(handles.buttonSplit,diff(fLim)>50)

% --- switches the selected groups from cGrpC to cGrp
function switchSelectedGroup(handles,iData,cGrp,cGrpC)    

% global variables
global fAlphaOff fAlphaOn

% updates and initialisations
iData.cGrp = cGrp;
hAxG = handles.axesGroup;

% if not, then update the group selection index
setappdata(handles.figVidSplit,'iData',iData)
set(handles.grpCountEdit,'string',num2str(cGrp))
updateSelectionEnable(handles, 2, cGrp, size(iData.vGrp,1))

% updates the patch colours
updatePatchFaceAlpha(hAxG, cGrpC, fAlphaOff);
hPOn = updatePatchFaceAlpha(hAxG, cGrp, fAlphaOn);

% updates the start/finish frames for the new group
set(handles.editGrpStart,'string',num2str(iData.vGrp(cGrp,1)))
set(handles.editGrpFinish,'string',num2str(iData.vGrp(cGrp,2)))

hP = findall(hAxG, 'tag', 'hGrp');
hPOther = hP(hP ~= hPOn);
hLine = findall(hAxG, 'tag', 'hLine');
set(hAxG, 'Children', [hLine;hPOn;flipud(hPOther)])

% --- resets the groups lower/upper frame limits
function nwLim = getGroupLimits(iData,cGrp,isLower)

% initialises the frame limits
nwLim = [1+(~isLower) (iData.nFrm-isLower)];

% sets the upper/lower limits (based on the limit type)
if isLower
    % case is the lower limit
	if (cGrp > 1); nwLim(1) = iData.vGrp(cGrp-1,2)+1; end
	if (cGrp < size(iData.vGrp,1)); nwLim(2) = iData.vGrp(cGrp,2)-1; end
else
    % case is the upper limit
	if (cGrp > 1); nwLim(1) = iData.vGrp(cGrp,1)+1; end
	if (cGrp < size(iData.vGrp,1)); nwLim(2) = iData.vGrp(cGrp+1,1)-1; end
end

% --- updates the face alpha for a given group patch object
function hP = updatePatchFaceAlpha(hAxG, cGrp, fAlpha)

hP = findall(hAxG,'tag','hGrp','UserData',cGrp);
set(findall(hP,'tag','patch'),'facealpha',fAlpha);   
