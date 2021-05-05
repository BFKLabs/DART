function varargout = WindowSplit(varargin)
% Last Modified by GUIDE v2.5 17-Feb-2021 08:46:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @WindowSplit_OpeningFcn, ...
                   'gui_OutputFcn',  @WindowSplit_OutputFcn, ...
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

% --- Executes just before WindowSplit is made visible.
function WindowSplit_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for WindowSplit
handles.output = hObject;

% global variables
global isChange useAuto mainProgDir isCalib frmSz0 isUpdating
[isChange,isUpdating,useAuto] = deal(false);

% sets the input variables
hGUI = varargin{1};
hPropTrack0 = varargin{2};

% creates a loadbar figure
hLoad = ProgressLoadbar('Initialising Region Setting GUI...');

% loads the background parameter struct from the program parameter file
A = load(fullfile(mainProgDir,'Para Files','ProgPara.mat'));
bgP = A.bgP;

% sets the data structs into the GUI
hFig = hGUI.figFlyTrack;
iMov = getappdata(hFig,'iMov');
iData = getappdata(hFig,'iData');

% sets the frame size (if calibrating for the RT-Tracking)
if isCalib
    objIMAQ = getappdata(hFig,'objIMAQ');
    if isa(objIMAQ,'cell')
        frmSz0 = size(objIMAQ{1});
    else
        vRes = getVideoResolution(getappdata(hFig,'objIMAQ'));
        frmSz0 = vRes([2 1]);
    end
    
    % sets the image acquisition object into the GUI
    setappdata(hObject,'objIMAQ',objIMAQ);
end

% sets the important arrays/functions handles into the GUI 
setappdata(hObject,'hGUI',hGUI)
setappdata(hObject,'iMov0',iMov)
setappdata(hObject,'hPropTrack0',hPropTrack0)
setappdata(hObject,'resetMovQuest',@resetMovQuest)

% updates the GUI font-sizes
setGUIFontSize(handles)
hProp0 = disableAllTrackingPanels(hGUI,1);

% sets the background parameter struct (if not set)
if ~isfield(iMov,'bgP')
    iMov.bgP = bgP;
elseif isempty(iMov.bgP)
    iMov.bgP = bgP;
end

% determines if the user is using multi-fly tracking
isMultiTrack = detIfMultiTrack(iMov);

% sets the sub-region data struct
setappdata(hObject,'iMov',iMov)
setappdata(hObject,'isMultiTrack',isMultiTrack)

% initialises the sub-movie dimensions
if iMov.isSet
    % if the binary mask field (for the 2D circle automatic placement) has 
    % not been set in iMov, then set the field and mark a change
    if ~isfield(iMov,'autoP'); iMov.autoP = []; end    
    
    % if the movie has already been set, then set the window properties and
    % disable the set button
    setOutlineProp(handles,'inactive',iMov.posG)
    setObjEnable(handles.buttonSet,'on')        
    
    % sets the fields based on the 
    [setRegions,is2Dset] = deal(true,is2DCheck(iMov));
    if is2Dset
        % sets the 1/2-D automatic detection menu item enabled properties
        setObjEnable(handles.menuAutoPlace,'on');         
        if ~isempty(iMov.autoP)
            % plots the circle regions on the main GUI axes
            setRegions = false;
            plotRegionOutlines(handles,iMov,1)
            setPatternMenuCheck(handles)
        end    
    else
        % sets the 1/2-D automatic detection menu item enabled properties
        setObjEnable(handles.menuAutoPlace,'off');         
    end
    
    % sets the enabled properties of the auto detect menu items
    setObjEnable(handles.menuShowRegion,~setRegions);
    setObjEnable(handles.menuUseAuto,~setRegions);  
    setObjEnable(handles.checkShowInner,~setRegions);
    setObjEnable(handles.checkDiffFly,iMov.nRow*iMov.nCol>1)
    
    % auto-detect regions not set, so disable menu items
    if setRegions      
        % draw the sub-region division figures
        setupSubRegions(handles,iMov,true); 
        
    else
        % auto-detect regions have been set, so enable/check menu items
        set(handles.menuShowRegion,'checked','on');
        set(handles.menuUseAuto,'checked','on');        
    end
    
    % sets the GUI to the top
    uistack(handles.figWinSplit,'top')  
    
    % enables/sets the show inner region checkbox
    if (iMov.nRow*iMov.nCol) > 1
        set(handles.checkShowInner,'value',1)
    else
        setObjEnable(handles.checkShowInner,'off')
    end    
    
    % updates the regional fly count checkbox value
    set(handles.checkDiffFly,'value',iMov.dTube)
    setObjEnable(handles.menuFlyCount,iMov.dTube)
    checkDiffFly_Callback(handles.checkDiffFly, '1', handles)
    
else
    % otherwise, disable all the buttons and the menu item
    setOutlineProp(handles,'off')    
    setObjEnable(handles.checkShowInner,'off')
    setObjEnable(handles.menuAutoPlace,'off')
    setObjEnable(handles.checkDiffFly,'off')
    setObjEnable(handles.menuFlyCount,'off')
end

% if multi-tracking, reset some of the object text strings
if detIfMultiTrack(iMov)
    set(handles.textTubes,'string','Fixed Region Fly Count: ')
    set(handles.checkDiffFly,'string','Variable Region Fly Counts')
    set(handles.menuFlyCount,'label','Fly Counts')
end

% sets the button properties and sub-movie data struct
setObjEnable(handles.buttonUpdate,'off')

% updates the other important fields within the GUI
setappdata(hObject,'iData',iData)
setappdata(hObject,'hProp0',hProp0)
setappdata(hObject,'hDiff',[])

% sets the GUI function handles
setappdata(hObject,'resetMovQuest',@resetMovQuest)
setappdata(hObject,'resetSubRegionDataStruct',@resetSubRegionDataStruct)

% initialises the sub-movie properties
setSubMovieProp(handles,iMov)
initOutlineProp(handles);
centreFigPosition(hObject);

% closes the loadbar
try; close(hLoad); end

% Update handles structure
guidata(hObject, handles);

% % UIWAIT makes WindowSplit wait for user response (see UIRESUME)
% uiwait(handles.figWinSplit);

% --- Outputs from this function are returned to the command line.
function varargout = WindowSplit_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = hObject;

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% ---------------------------------- %
% --- AUTOMATIC REGION DETECTION --- %
% ---------------------------------- %

% -------------------------------------------------------------------------
function menuDetCircle_Callback(hObject, eventdata, handles)

% initialisations
eState = strcmp(get(handles.checkShowInner,'Enable'),'on');

% retrieves the automatic detection algorithm objects
[iMov,hGUI,I] = initAutoDetect(handles);
if isempty(iMov); return; end

% keep looping until either the user is satified or cancels
[cont,isUpdate,hQ] = deal(true,false,0.25);
while cont
    % run the automatic region detection algorithm 
    [iMovNw,R,X,Y,ok] = detImageCircles(double(I),iMov,hQ);
    if ok   
        % if successful, run the circle parameter GUI        
        [iMovNw,hQ,uChoice] = CircPara(handles,iMovNw,X,Y,R,hQ); 
        switch uChoice
            case ('Cont') % user is continuing, so exit loop with update
                [cont,isUpdate] = deal(false,true);
                
            case ('Cancel') % user cancelled, so exit loop with no update
                cont = false;
        end
        
    else
        % the user cancelled, so exit the loop
        cont = false;
    end
end

% resets/updates the pattern menu checkmark
if isempty(iMovNw)
    % not successful, so use check the existing pattern type
    setPatternMenuCheck(handles)
    
else
    % successful, so update the check to the new pattern type
    resetPatternMenuCheck(hObject)
end

% performs the post automatic detection updates
setObjEnable(handles.checkShowInner,eState && isempty(iMovNw))
postAutoDetectUpdate(handles,hGUI,iMov,iMovNw,isUpdate);

% -------------------------------------------------------------------------
function menuDetGeneral_Callback(hObject, eventdata, handles)

% global variables
global isCalib

% initialisations
nFrm = 11;
I = cell(nFrm,1);
eState = strcmp(get(handles.checkShowInner,'Enable'),'on');

% retrieves the tracking data struct
iData = getappdata(handles.figWinSplit,'iData');

% retrieves the automatic detection algorithm objects
[iMov,hGUI,~] = initAutoDetect(handles);
if isempty(iMov); return; end

% retrieves the initial image stack
if isCalib
    % case is the user is calibrating the camera
    objIMAQ = getappdata(handles.figWinSplit,'objIMAQ');
    for i = 1:nFrm
        I{i} = getsnapshot(objIMAQ);
        pause(1);
    end
    
else
    % case is the tracking from a video
    xi = roundP(linspace(1,iData.nFrm,nFrm));
    for i = 1:length(xi)
        I{i} = getDispImage(iData,iMov,xi(i),false,hGUI);
    end
end

try
    % runs the general region detection algorithm
    iMovNw = detGenRegions(iMov,I);
    
catch 
    % if there was an error, then output a message to screen
    eStr = sprintf(['There was an error in the general region ',...
                    'detection calculations. Try resetting the search',...
                    'region and retrying']);
    waitfor(errordlg(eStr,'General Region Detection Error!','modal'))
    
    % sets an empty sub-region data struct 
    iMovNw = [];  
end

% resets/updates the pattern menu checkmark
if isempty(iMovNw)
    % not successful, so use check the existing pattern type
    setPatternMenuCheck(handles)
    
else
    % successful, so update the check to the new pattern type
    resetPatternMenuCheck(hObject)
end

% performs the post automatic detection updates
setObjEnable(handles.checkShowInner,eState && isempty(iMovNw))
postAutoDetectUpdate(handles,hGUI,iMov,iMovNw,~isempty(iMovNw));

% -------------------------------------------------------------------------
function menuDetGeneralCust_Callback(hObject, eventdata, handles)

% FINISH ME!
showUnderDevelopmentMsg()

% -------------------------------------------------------------------------
function menuUseAuto_Callback(hObject, eventdata, handles)

% global variables
global useAuto isChange
isChange = true;

% retrieves the main GUI handle data struct
hGUI = getappdata(handles.figWinSplit,'hGUI');
iMov = getappdata(handles.figWinSplit,'iMov');

% performs the action based on the menu item checked status 
if (strcmp(get(hObject,'checked'),'off'))
    % sets the check status to on. enables the show region menu item
    useAuto = false;
    set(hObject,'checked','on')
    setObjEnable(handles.menuShowRegion,'on')
    setObjEnable(handles.buttonUpdate,'on')
    
    % removes the sub-regions
    deleteSubRegions(handles)
else
    % sets the check status to off
    useAuto = true;
    set(hObject,'checked','off')    
    setObjEnable(handles.buttonUpdate,'off')
    
    % disables the show region menu item and removes the regions
    set(setObjEnable(handles.menuShowRegion,'off'),'checked','on')
    menuShowRegion_Callback(handles.menuShowRegion, [], handles)
    
    % resets the sub-regions on the main GUI axes    
    setupSubRegions(handles,iMov,true);    
end    

% makes the Window Splitting GUI visible again
uistack(handles.figWinSplit,'top')  

% -------------------------------------------------------------------------
function menuShowRegion_Callback(hObject, eventdata, handles)

% performs the action based on the menu item checked status 
if (strcmp(get(hObject,'checked'),'off'))
    % toggles the menu item to being checked and adds circle regions
    set(hObject,'checked','on')    
else
    % toggles the menu item to being unchecked and removes circle regions
    set(hObject,'checked','off')    
end

% plots the region outlines
plotRegionOutlines(handles)

% ------------------------- %
% --- SUB-REGION COUNTS --- %
% ------------------------- %

% -------------------------------------------------------------------------
function menuFlyCount_Callback(hObject, eventdata, handles)

% runs the differing sub-region fly count setup gui
DiffFlyCount(handles.figWinSplit)

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --------------------------------------------- %
% --- SUB-MOVIE DIMENSIONS OBJECT FUNCTIONS --- %
% --------------------------------------------- %

% --- executes on the callback of editRows
function editRows_Callback(hObject, eventdata, handles)

% retrieves the sub-movie struct and the main gui handles
ok = false(1,2);
iMov = getappdata(handles.figWinSplit,'iMov');

% sets the parameter value based on the tracking algorithm type
if detIfMultiTrack(iMov)
    pStr = 'iMov.nFly';
else
    pStr = 'iMov.nTube';
end

% check to see if the new value is valid
nwVal = str2double(get(hObject,'string'));
if chkEditValue(nwVal,[1 20],1)
    % if it is, then update the data struct
    if ~isequal(iMov.nRow,nwVal)
        if resetMovQuest(handles)            
            % updates the data struct
            iMov.nRow = nwVal;
            iMov = resetSubRegionDataStruct(iMov);            
            setappdata(handles.figWinSplit,'iMov',iMov)    
            
            % if the other parameters are set, then enable the set button
            setObjEnable(handles.buttonUpdate,'off')
            if isempty(iMov.nCol) || isempty(eval(pStr))
                ok(:) = false;
            else 
                ok = [true,iMov.nRow*iMov.nCol>1];
            end
        else
            % otherwise, reset to the last valid value
            set(hObject,'string',num2str(iMov.nRow));              
        end
    end
    
elseif ~isempty(iMov.nRow)
    % otherwise, reset to the last valid value if there is one
    set(hObject,'string',num2str(iMov.nRow));   
    
else
    % otherwise, reset to an empty edtibox
    set(hObject,'string','');
    
end

% sets the set button properties
setObjEnable(handles.buttonSet,ok(1))
setObjEnable(handles.checkDiffFly,ok(2))
    
% --- executes on the callback of editCols
function editCols_Callback(hObject, eventdata, handles)

% retrieves the sub-movie struct and the main gui handles
ok = false(1,2);
iMov = getappdata(handles.figWinSplit,'iMov');

% sets the parameter value based on the tracking algorithm type
if detIfMultiTrack(iMov)
    pStr = 'iMov.nFly';
else
    pStr = 'iMov.nTube';
end

% check to see if the new value is valid
nwVal = str2double(get(hObject,'string'));
if chkEditValue(nwVal,[1 20],1)
    % if it is, then update the data struct
    if ~isequal(iMov.nCol,nwVal)
        if resetMovQuest(handles)
            % updates and resets the sub-region data struct
            iMov.nCol = nwVal;
            iMov = resetSubRegionDataStruct(iMov);            
            setappdata(handles.figWinSplit,'iMov',iMov)                               
            
            % if the other parameters are set, then enable the set button
            setObjEnable(handles.buttonUpdate,'off')
            if isempty(iMov.nRow) || isempty(eval(pStr))
                ok(:) = false;
            else 
                ok = [true,iMov.nRow*iMov.nCol > 1];
            end
        else
            % otherwise, reset to the last valid value
            set(hObject,'string',num2str(iMov.nCol));              
        end        
    end
    
elseif ~isempty(iMov.nRow)
    % otherwise, reset to the last valid value if there is one
    set(hObject,'string',num2str(iMov.nRow));   
    
else
    % otherwise, reset to an empty edtibox
    set(hObject,'string','');     
end

% sets the set button properties
setObjEnable(handles.buttonSet,ok(1))
setObjEnable(handles.checkDiffFly,ok(2))

% --- executes on the callback of editTubes
function editTubes_Callback(hObject, eventdata, handles)

% retrieves the sub-movie struct and the main gui handles
ok = false(1,2);
iMov = getappdata(handles.figWinSplit,'iMov');

% sets the parameter value based on the tracking algorithm type
isMultiTrack = detIfMultiTrack(iMov);
if isMultiTrack
    pStr = 'iMov.nFly';
else
    pStr = 'iMov.nTube';
end

% check to see if the new value is valid
[nwVal,prVal] = deal(str2double(get(hObject,'string')),eval(pStr));
if chkEditValue(nwVal,[1 50],1)    
    % if it is, then update the data struct
    if ~isequal(prVal,nwVal)
        % determines if the user needs to be prompted for update
        if isMultiTrack
            % case is multi-tracking (won't affect configuration)
            cont = true;
        else
            % case is single tracking (will affect configuration)
            cont = resetMovQuest(handles);
        end
        
        if cont
            % updates the data struct
            eval(sprintf('%s = nwVal;',pStr));
            if ~isMultiTrack                
                iMov = resetSubRegionDataStruct(iMov);
            end
            
            % updates the sub-region data struct
            setObjEnable(handles.buttonUpdate,iMov.isSet && isMultiTrack)
            setappdata(handles.figWinSplit,'iMov',iMov)                             
                        
            % if the other parameters are set, then enable the set button            
            if isempty(iMov.nCol) || isempty(iMov.nRow)
                ok(:) = false;
            else 
                ok = [true,iMov.nRow*iMov.nCol > 1];
            end
        else
            % otherwise, reset to the last valid value
            set(hObject,'string',num2str(prVal));              
        end              
    end
    
elseif ~isempty(prVal)
    % otherwise, reset to the last valid value
    set(hObject,'string',num2str(prVal));      
    
else
    % otherwise, reset to the last valid value
    set(hObject,'string','');        
end

% sets the set button properties
setObjEnable(handles.buttonSet,ok(1))
setObjEnable(handles.checkDiffFly,ok(2))

% --- Executes on button press in checkDiffFly.
function checkDiffFly_Callback(hObject, eventdata, handles)

% initialisations
iMov = getappdata(handles.figWinSplit,'iMov');
iMov.dTube = get(hObject,'value');
isMultiTrack = detIfMultiTrack(iMov);

% only updating if not initialising
if ~isa(eventdata,'char')
    % determines if the user needs to be prompted for update
    if isMultiTrack
        % case is multi-tracking (won't affect configuration)
        cont = true;
    else
        % case is single tracking (will affect configuration)
        cont = resetMovQuest(handles);
    end

    if cont    
        % updates the regional fly count flag
        setObjEnable(handles.buttonUpdate,'off')                 
        
        % clears the total fly count/use flag arrays        
        iMov = resetSubRegionDataStruct(iMov);   
        setappdata(handles.figWinSplit,'iMov',iMov)        
    else
        % otherwise, exit the function
        set(hObject,'value',~iMov.dTube);
        return
    end
end

% sets the enabled properties of the fly count editbox
hText = findall(handles.panelMovieDim,'style','text');
hEdit = findall(handles.panelMovieDim,'style','edit');
setObjEnable(hText,~iMov.dTube)
setObjEnable(hEdit,~iMov.dTube)

% updates the fly count menu item enabled properties
setObjEnable(handles.menuFlyCount,iMov.dTube)

% --- Executes on button press in checkShowInner.
function checkShowInner_Callback(hObject, eventdata, handles)

% initialisations
hGUI = getappdata(handles.figWinSplit,'hGUI');
isShow = get(hObject,'value');

% sets the object properties
setObjEnable(handles.buttonUpdate,isShow);
setObjVisibility(findobj(hGUI.imgAxes,'tag','hNum'),isShow);
setObjVisibility(findobj(hGUI.imgAxes,'UserData','hTube'),isShow);

hInner = findobj(hGUI.imgAxes,'tag','hInner');
setObjVisibility(hInner,isShow);

if (isShow)
    setObjVisibility(findall(hInner,'tag','bottom line'),'off');
end

% --- callback function for key-strokes in the editboxes
function keyPressFunc(hObject, eventdata, handles)

% disables the set button
setObjEnable(handles.buttonSet,'off')

% -------------------------------------- %
% --- MISCELLANEOUS BUTTON FUNCTIONS --- %
% -------------------------------------- %

% --- Executes on button press in buttonSet.
function buttonSet_Callback(hObject, eventdata, handles)

% global variables
global useAuto

% retrieves the main GUI and sub-image region data structs
useAuto = false;
hGUI = getappdata(handles.figWinSplit,'hGUI');
iMov = getappdata(handles.figWinSplit,'iMov');

% sets the ok flags
nApp = iMov.nRow*iMov.nCol;
[iMov.ok,iMov.isSet,iMov.iR] = deal(true(nApp,1),true,[]);

% deletes the automatically detected circular regions (if any present)
hOut = findall(hGUI.imgAxes,'tag','hOuter');
if ~isempty(hOut); delete(hOut); end

% sets up the sub-regions
iMov = setupSubRegions(handles,iMov);

% determines if the new array is 2-dimensional
is2D = is2DCheck(iMov);

% determines the rough aspect ratio of the sub-regions. if they are roughly
% 2D, then enable the automatic placement menu item
setObjEnable(handles.menuAutoPlace,is2D)

% sets the sub-GUI as the top window
uistack(handles.figWinSplit,'top')

% sets the outer dimensions
setOuterDimensions(handles,iMov)

% enables/sets the show inner region checkbox
if (iMov.nRow*iMov.nCol) > 1
    set(setObjEnable(handles.checkShowInner,'on'),'value',1)
end

% enable the update button, but disable the use automatic region and show
% region menu items
set(setObjEnable(handles.menuUseAuto,'off'),'checked','off');
set(setObjEnable(handles.menuShowRegion,'off'),'checked','off');
setObjEnable(handles.buttonUpdate,'on');
setOutlineProp(handles,'inactive',iMov.posG)

% updates the data struct into the GUI
setappdata(handles.figWinSplit,'iMov',iMov);

% --- Executes on button press in buttonUpdate.
function buttonUpdate_Callback(hObject, eventdata, handles)

% global variables
global isChange useAuto

% retrieves the main gui handles and sub-movie data struct
hGUI = getappdata(handles.figWinSplit,'hGUI');
iMov = getappdata(handles.figWinSplit,'iMov');

% removes the x-correlation parameter struct (if it exists)
iMov.Ibg = [];
if isfield(iMov,'xcP')
    iMov = rmfield(iMov,'xcP'); 
end

% if using the automatic detection, disable the button and exit
if strcmp(get(handles.menuUseAuto,'checked'),'on') || useAuto
    setappdata(handles.figWinSplit,'iMov',iMov)
    setObjEnable(hObject,'off'); return
end

% gets the width/height values
W = str2double(get(handles.editWidth,'string'));
H = str2double(get(handles.editHeight,'string'));
L = str2double(get(handles.editLeft,'string'));
T = str2double(get(handles.editTop,'string'));
iMov.posG = getOuterRegionCoords(L,T,W,H);

% sets the final sub-region dimensions into the data struct
iMov = setSubRegionDim(iMov,hGUI);
if ~isa(eventdata,'char')
    [iMov.autoP,isChange] = deal([],true);    
    setObjEnable(hObject,'off');
end

% resets the sub-movie data struct
setappdata(handles.figWinSplit,'iMov',iMov)

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% global variables
global isChange

% if there is an update specified, then prompt the user to update
if strcmp(get(handles.buttonUpdate,'enable'),'on')
    % prompts the user if they wish to update the struct
    uChoice = questdlg('Do you wish to update the specified sub-region?',...
            'Update Sub-Regions?','Yes','No','Cancel','Yes');
    switch uChoice
        case ('Yes') % case is the user wants to update movie struct
            if (strcmp(get(handles.menuUseAuto,'checked'),'off'))
                buttonUpdate_Callback(handles.buttonUpdate, 1, handles)
            end
            
        case ('No') % case is the user does not want to update
            isChange = false;
            
        otherwise % case is the user cancelled
            return            
    end
end

% loads the movie struct
hGUI = getappdata(handles.figWinSplit,'hGUI');
iMov = getappdata(handles.figWinSplit,'iMov');
hProp0 = getappdata(handles.figWinSplit,'hProp0');
hPropTrack0 = getappdata(handles.figWinSplit,'hPropTrack0');

% removes the sub-regions and the fly region count GUI
deleteSubRegions(handles)
delete(findall(0,'type','figure','tag','figFlyCount'))

% removes all the circle regions from the main GUI (if they exist)
hOut = findall(hGUI.imgAxes,'tag','hOuter');
if ~isempty(hOut); delete(hOut); end

% closes the window
resetHandleSnapshot(hProp0)
delete(handles.figWinSplit)

% runs the post window split function
postWindowSplit = getappdata(hGUI.figFlyTrack,'postWindowSplit');
postWindowSplit(hGUI,iMov,hPropTrack0,isChange)

%-------------------------------------------------------------------------%
%                       SUB-REGION OUTLINE FUNCTIONS                      %
%-------------------------------------------------------------------------%

% --- sets up the sub-regions 
function iMov = setupSubRegions(handles,iMov,isSet)

% sets the setup flag
if (nargin < 3); isSet = false; end

% removes any previous sub-regions
deleteSubRegions(handles)

% determines if the regions have been set
if isSet
    % otherwise, setup the outer frame from the previous values
    setupMainFrameRect(handles,iMov);
    
    % calculates the outside region coordinates if they haven't been set
    if ~isfield(iMov,'posO')
        iMov.posO = resetOutsidePos(iMov);
    end
else
    % if not, then prompt the user to set them up
    iMov.posG = setupMainFrameRect(handles);
    iMov = initSubPlotStruct(handles,iMov);
    
    % resets the sub-movie data struct
    setappdata(handles.figWinSplit,'iMov',iMov)    
end

% resets the tube count/use flags (if not using differing region counts)
if detIfMultiTrack(iMov)
    % case is multi-fly tracking
    if isempty(iMov.nFlyR) || ~iMov.dTube        
        iMov.nTubeR = ones(iMov.nRow,iMov.nCol);
        iMov.nFlyR = iMov.nFly*ones(iMov.nRow,iMov.nCol);        
    end    
else
    % case is single-fly tracking
    if isempty(iMov.nTubeR) || ~iMov.dTube
        iMov.nTubeR = iMov.nTube*ones(iMov.nRow,iMov.nCol);        
    end
end

% initialises the in-use flags (if not already initialises elsewhere)
nMax = max(iMov.nTubeR(:));
if ~isfield(iMov,'isUse')
    iMov.isUse = arrayfun(@(n)(true(nMax,1)),iMov.nTubeR,'un',0);
elseif isempty(iMov.isUse)    
    iMov.isUse = arrayfun(@(n)(true(nMax,1)),iMov.nTubeR,'un',0);
end

% removes any previous markers and updates
iMov = createSubRegions(handles,iMov,isSet);

% --- creates the subplot regions and line objects
function iMov = createSubRegions(handles,iMov,isSet)

% global variables
global xGap yGap xVL pX pY pH pW

% ------------------------------------------- %
% --- INITIALISATIONS & MEMORY ALLOCATION --- %
% ------------------------------------------- %

% initialisations
[xGap,yGap] = deal(5,5);
xVL = zeros(iMov.nCol-1,2);
[pX,pY,pH,pW] = deal(zeros(iMov.nCol*iMov.nRow,1));

% retrieves the GUI objects
hGUI = getappdata(handles.figWinSplit,'hGUI');
hAx = hGUI.imgAxes;
hold(hAx,'on')

% sets the region position vectors
[rPosS,nApp] = deal(iMov.pos,length(iMov.pos));

% ------------------------------ %
% --- VERTICAL LINE CREATION --- %
% ------------------------------ %

% memory allocation
hVL = cell(1,iMov.nCol-1);
yVL = iMov.posG(2) + [0 iMov.posG(4)];

% only set up the vertical lines if there is more than one column
for i = 2:iMov.nCol
    % sets the x-location of the lines
    if ~isempty(iMov.pos)
        % sets the indices of the groups to the left of the line
        iLf = iMov.nCol*(0:(iMov.nRow-1)) + (i-1);
        
        % sets the locations of the lower top/upper bottom indices
        xR = max(cellfun(@(x)(sum(x([1 3]))),iMov.pos(iLf)));
        xL = min(cellfun(@(x)(x(1)),iMov.pos(iLf+1)));  
        
        % sets the horizontal location of the vertical separator
        xVL = 0.5*(xR+xL)*[1 1];          
    else
        xVL = iMov.posO{i}(1)*[1 1];
    end

    % creates the line object and sets the flags
    hVL{i-1} = imline(hAx,xVL,yVL);
    set(hVL{i-1},'tag','hVert');
    set(findobj(hVL{i-1},'tag','bottom line'),'visible','off','UserData',i-1);
    set(findobj(hVL{i-1},'tag','end point 1'),'hittest','off');
    set(findobj(hVL{i-1},'tag','end point 2'),'hittest','off');

    % updates the 
    api = iptgetapi(hVL{i-1});
    api.setColor('r')
    api.addNewPositionCallback(@vertCallback); 

    % sets the position constraint function
    fcn = makeConstrainToRectFcn('imline',getVertXLim(iMov,i),yVL);
    api.setPositionConstraintFcn(fcn);           
end

% -------------------------------- %
% --- HORIZONTAL LINE CREATION --- %
% -------------------------------- %    

% only set up the horizontal lines if there is more than one row
for j = 1:iMov.nCol
    % sets the x-location of the lines
    xHL = iMov.posO{j}(1) + [0 iMov.posO{j}(3)];        
    
    % creates the line objects
    for i = 2:iMov.nRow
        % sets the y-location of the line
        if (~isempty(iMov.pos))
            [iLo,iHi] = deal((i-2)*iMov.nCol+j,(i-1)*iMov.nCol+j);
            yHL = 0.5*(sum(iMov.pos{iLo}([2 4])) + sum(iMov.pos{iHi}(2)))*[1 1];
        else
            k = (i-1)*iMov.nCol + j;
            yHL = iMov.posO{k}(2)*[1 1];
        end
        
        % creates the line object and sets the properties
        hHL = imline(hAx,xHL,yHL);
        set(hHL,'tag','hHorz','UserData',[i,j]);
        setObjVisibility(findobj(hHL,'tag','bottom line'),'off'); 
        set(findobj(hHL,'tag','end point 1'),'hittest','off');
        set(findobj(hHL,'tag','end point 2'),'hittest','off');        
        
        % updates the 
        api = iptgetapi(hHL);
        api.setColor('r')
        api.addNewPositionCallback(@horzCallback); 
        
        % sets the position constraint function
        fcn = makeConstrainToRectFcn('imline',xHL,getHorzYLim(iMov,i,j));
        api.setPositionConstraintFcn(fcn);             
        
        % sets the left-coordinate into the corresponding vertical line
        if (j > 1)
            uD = [get(hVL{j-1},'UserData');{api,1,i,j}];
            set(hVL{j-1},'UserData',uD);
        end
        
        % sets the right-coordinate into the corresponding vertical line
        if (j < iMov.nCol)
            uD = [get(hVL{j},'UserData');{api,2,i,j}];
            set(hVL{j},'UserData',uD);            
        end
    end
end

% ----------------------------------- %
% --- TUBE REGION OBJECT CREATION --- %
% ----------------------------------- %

% case is for movable inner objects (different colours)
if (mod(iMov.nCol,2) == 1)
    col = 'gmyc';    
else
    col = 'gmy';    
end

% sets the inner rectangle objects for all apparatus
for i = 1:nApp
    %
    iCol = mod(i-1,iMov.nCol) + 1;
    iRow = floor((i-1)/iMov.nCol) + 1;
    
    % sets the sub-region limits
    xLimS = getRegionXLim(iMov,hAx,iCol);
    yLimS = getRegionYLim(iMov,hAx,iRow,iCol);

    % adds the ROI fill objects (if already set)
    if isSet
        [ix,iy] = deal([1 1 2 2],[1 2 2 1]);
        hFill = fill(xLimS(ix),yLimS(iy),'r','facealpha',0,'tag',...
                     'hFillROI','linestyle','none','parent',hAx);
                 
        % if the region is rejected, then set the facecolour to red
        if ~iMov.ok(i)
            set(hFill,'facealpha',0.2)
        end
    end       
    
    % retrieves the new fly count index
    nTubeNw = getSRCount(iMov,i);
    
    % sets the proportional height/width values
    pX(i) = (iMov.pos{i}(1)-iMov.posO{i}(1))/iMov.posO{i}(3);
    pY(i) = (iMov.pos{i}(2)-iMov.posO{i}(2))/iMov.posO{i}(4);
    pW(i) = iMov.pos{i}(3)/iMov.posO{i}(3);
    pH(i) = iMov.pos{i}(4)/iMov.posO{i}(4);
    
    % creates the new rectangle object
    hROI = imrect(hAx,iMov.pos{i});
    indCol = mod(i-1,length(col))+1;    
    
    % disables the bottom line of the imrect object
    set(hROI,'tag','hInner','UserData',i);
    setObjVisibility(findobj(hROI,'tag','bottom line'),'off');

    % if moveable, then set the position callback function
    api = iptgetapi(hROI);
    api.setColor(col(indCol));
    api.addNewPositionCallback(@roiCallback);   
    
    % sets the constraint region for the inner regions
    fcn = makeConstrainToRectFcn('imrect',xLimS,yLimS);
    api.setPositionConstraintFcn(fcn); 
    
    % creates the individual tube markers
    xTubeS = repmat(rPosS{i}(1)+[0 rPosS{i}(3)],nTubeNw-1,1)';
    yTubeS = rPosS{i}(2) + (rPosS{i}(4)/nTubeNw)*(1:(nTubeNw-1));
    plot(hAx,xTubeS,repmat(yTubeS,2,1),[col(indCol),'--'],'tag',...
                    sprintf('hTubeEdge%i',i),'UserData','hTube');     
end

% turns the axis hold off
hold(hAx,'off')

% --- removes the sub-regions
function deleteSubRegions(handles)

% retrieves the GUI objects
hGUI = getappdata(handles.figWinSplit,'hGUI');
hAx = hGUI.imgAxes;

% removes all the division marker objects
delete(findobj(hAx,'tag','hOuter'));
delete(findobj(hAx,'tag','hVert'));
delete(findobj(hAx,'tag','hHorz'));
delete(findobj(hAx,'tag','hNum'));
delete(findobj(hAx,'tag','hInner'));
delete(findobj(hAx,'tag','hFillROI'));

% deletes all the tube-markers
delete(findobj(hAx,'UserData','hTube'));

% --- sets up the main sub-window frame --- %
function [rPos,hROI] = setupMainFrameRect(handles,iMov)

% retrieves the GUI objects
hGUI = getappdata(handles.figWinSplit,'hGUI');
hAx = hGUI.imgAxes;

% ------------------------------------ %
% --- OUTER RECTANGLE OBJECT SETUP --- %
% ------------------------------------ %

% updates the position of the outside rectangle 
if (nargin == 1)
    hROI = imrect(hAx);    
else
    hROI = imrect(hAx,iMov.posG);
end

% disables the bottom line of the imrect object
set(hROI,'tag','hOuter')
setObjVisibility(findobj(hROI,'tag','bottom line'),'off');

% if moveable, then set the position callback function
api = iptgetapi(hROI);
api.setColor('r');
rPos = api.getPosition();

% force the imrect object to be fixed
setResizable(hROI,false);
set(findobj(hROI),'hittest','off')

% sets the constraint function for the rectangle object
fcn = makeConstrainToRectFcn('imrect',rPos(1)+[0 rPos(3)],...
                                      rPos(2)+[0 rPos(4)]);
api.setPositionConstraintFcn(fcn); 

% --- calculates the coordinates of the outer region
function posG = getOuterRegionCoords(L,T,W,H)

% memory allocation
posG = zeros(1,4);
frmSz = getCurrentImageDim();

% retrieves the current coordinates
posG(1:2) = [max(0.5,L),max(0.5,T)];
posG(3) = W - max(0,(W + posG(1)) - (frmSz(2)-0.5));
posG(4) = H - max(0,(H + posG(2)) - (frmSz(1)-0.5));

% --------------------------------- %
% --- OBJECT CALLBACK FUNCTIONS --- %
% --------------------------------- %

% --- the callback function for moving the vertical seperator
function vertCallback(lPos)

% global variables
global isUpdating
isUpdating = true;

% retrieves the sub-region data struct
iMov = getappdata(findall(0,'tag','figWinSplit'),'iMov');
hWS = guidata(findall(0,'tag','figWinSplit'));
hGUIH = guidata(findall(0,'tag','figFlyTrack'));

% retrieves the object handle and the index of the line
hVL = get(gco,'parent');
iVL = get(findall(hVL,'tag','bottom line'),'UserData');

% updates the attached horizontal line properties
uD = get(hVL,'UserData');
for i = 1:size(uD)
    % updates the position of the attached line
    lPos0 = uD{i,1}.getPosition;
    lPos0(uD{i,2},1) = lPos(1,1);
    uD{i,1}.setPosition(lPos0);
    
    % sets the position constraint function    
    yLimNw = getHorzYLimNw(iMov,hGUIH.imgAxes,uD{i,3},uD{i,4});
    fcn = makeConstrainToRectFcn('imline',lPos0(:,1),yLimNw);
    uD{i,1}.setPositionConstraintFcn(fcn);      
end

% updates the position of the inner regions
updateInnerRegions(iMov,hGUIH.imgAxes,iVL,true)
setObjEnable(hWS.buttonUpdate,'on')

% resets the flag
isUpdating = false;

% --- the callback function for moving the horizontal seperator
function horzCallback(lPos)

% global variables
global isUpdating
if (isUpdating)
    % if already updating, then exit the function
    return
else
    % otherwise, flag that updating is occuring
    isUpdating = true;
end

% retr
iVL = get(get(gco,'parent'),'UserData');

% retrieves the sub-region data struct
iMov = getappdata(findall(0,'tag','figWinSplit'),'iMov');
hGUIH = guidata(findall(0,'tag','figFlyTrack'));
hWS = guidata(findall(0,'tag','figWinSplit'));

% updates the position of the inner regions
updateInnerRegions(iMov,hGUIH.imgAxes,iVL,false)
setObjEnable(hWS.buttonUpdate,'on')

% resets the flag to false
isUpdating = false;

% --- the callback function for moving the inner tube regions
function roiCallback(rPos)

% global variables
global iAppInner isUpdating pX pY pW pH

% global variables
hWS = guidata(findall(0,'tag','figWinSplit'));

% sets the apparatus index
iApp = get(get(gco,'Parent'),'UserData');
if (iscell(iApp)) || (length(iApp) ~= 1)
    iApp = iAppInner; 
end

% retrieves the sub-region data struct
iMov = getappdata(hWS.figWinSplit,'iMov');
nTube = getSRCount(iMov,iApp);

% resets the locations of the flies
hTube = findobj(gca,'tag',sprintf('hTubeEdge%i',iApp));
dY = diff(rPos(2)+[0 rPos(4)])/nTube;

% sets the x/y locations of the tube sub-regions
xTubeS = repmat(rPos(1)+[0 rPos(3)],nTube-1,1)';
yTubeS = repmat(rPos(2)+(1:(nTube-1))*dY,2,1);

% sets the x/y locations of the inner regions
for i = 1:length(hTube)
    set(hTube(i),'xData',xTubeS(:,i),'yData',yTubeS(:,i));
end

% if not updating, then reset the proportional dimensions
if ~isUpdating
    % retrieves the sub-region data struct
    iMov = getappdata(findall(0,'tag','figWinSplit'),'iMov');
    hGUIH = guidata(findall(0,'tag','figFlyTrack'));
    
    % sets the row/column indices
    iRow = floor((iApp-1)/iMov.nCol) + 1;
    iCol = mod((iApp-1),iMov.nCol) + 1;
    
    % retrieves the x/y limits of the region
    xLim = getRegionXLim(iMov,hGUIH.imgAxes,iCol);
    yLim = getRegionYLim(iMov,hGUIH.imgAxes,iRow,iCol);
    
    % recalculates the proportional dimensions
    [W,H] = deal(diff(xLim),diff(yLim));
    [pX(iApp),pY(iApp)] = deal((rPos(1)-xLim(1))/W,(rPos(2)-yLim(1))/H);
    [pW(iApp),pH(iApp)] = deal(rPos(3)/W,rPos(4)/H);    
    
    % enables the update button
    setObjEnable(hWS.buttonUpdate,'on')
end

% --- updates the position of the inner regions (if the vertical/horizontal
%     line objects are being moved)
function updateInnerRegions(iMov,hAx,iL,isVert)

% global variables
global pH pW pX pY iAppInner

% updates the inner region based on the line being moved
if (isVert)
    % case is moving a vertical line    
    for j = 1:2
        % sets the indices of the inner regions being affected        
        xLim = getRegionXLim(iMov,hAx,iL+(j-1));
        iApp = (1:iMov.nCol:length(iMov.pos)) + (iL + (j-2));
        
        % updates the position of the regions and their constraint regions
        for i = 1:iMov.nRow
            % retrieves the handle of the inner object
            iAppInner = iApp(i);
            hInner = findall(hAx,'tag','hInner','UserData',iApp(i));
            
            % retrieves the height limits of the 
            yLim = getRegionYLim(iMov,hAx,i,iL+(j-1));
            
            % retrieves the in
            api = iptgetapi(hInner);
            inPos = api.getPosition();
            
            % sets the new inner region position            
            inPos(1) = xLim(1) + pX(iApp(i))*diff(xLim);              
            inPos(3) = pW(iApp(i))*diff(xLim);
                                    
            % sets the constraint region for the inner regions
            api.setPosition(inPos);
            fcn = makeConstrainToRectFcn('imrect',xLim,yLim);
            api.setPositionConstraintFcn(fcn);             
        end
    end
else
    % case is moving a horizontal line   
    for j = 1:2
        % retrieves the height limits of the 
        iApp = (iL(1)+(j-3))*iMov.nCol + iL(2);
        yLim = getRegionYLim(iMov,hAx,iL(1)+(j-2),iL(2));
        xLim = getRegionXLim(iMov,hAx,iL(2));
        
        % retrieves the handle of the inner object
        iAppInner = iApp;
        hInner = findall(hAx,'tag','hInner','UserData',iApp);   
        
        % retrieves the in
        api = iptgetapi(hInner);
        inPos = api.getPosition();

        % sets the new inner region position            
        inPos(2) = yLim(1) + pY(iApp)*diff(yLim);              
        inPos(4) = pH(iApp)*diff(yLim);

        % sets the constraint region for the inner regions
        api.setPosition(inPos);
        fcn = makeConstrainToRectFcn('imrect',xLim,yLim);
        api.setPositionConstraintFcn(fcn);         
    end
end

% ------------------------------------- %
% --- REGION/OBJECT LIMIT FUNCTIONS --- %
% ------------------------------------- %

% --- retrieves the horizontal seperator line limits (original)
function yLim = getHorzYLim(iMov,iRow,iCol,varargin)

% global variables
global yGap

% memory allocation
yLim = zeros(1,2);
yGapNw = 3*(nargin == 3)*yGap;

% sets the lower limit
if (iRow == 2)
    yLim(1) = iMov.posG(2) + yGapNw;
else
    iL = (iRow-2)*iMov.nCol + iCol;    
    yLim(1) = iMov.pos{iL}(2) + yGapNw;
end

% sets the upper limit
if (iRow == iMov.nRow)
    yLim(2) = sum(iMov.posG([2 4])) - yGapNw;
else
    iU = iRow*iMov.nCol + iCol;
    yLim(2) = iMov.pos{iU}(2) - yGapNw;
end

% --- retrieves the horizontal seperator line limits (callback function)
function yLim = getHorzYLimNw(iMov,hAx,iRow,iCol)

% global variables
global yGap

% memory allocation
[yLim,yGapNw] = deal(zeros(1,2),3*yGap);

% sets the lower limit
if (iRow == 2)
    yLim(1) = iMov.posG(2) + yGapNw;
else
    apiLo = iptgetapi(findall(hAx,'tag','hHorz','UserData',[iRow-1,iCol]));
    lPos = apiLo.getPosition();
    yLim(1) = lPos(1,2) + yGapNw;    
end

% sets the upper limit
if (iRow == iMov.nRow)
    yLim(2) = sum(iMov.posG([2 4])) - yGapNw;
else
    apiHi = iptgetapi(findall(hAx,'tag','hHorz','UserData',[iRow+1,iCol]));
    lPos = apiHi.getPosition();
    yLim(2) = lPos(1,2) - yGapNw;
end

% --- retrieves the vertical seperator line limits (original)
function xLim = getVertXLim(iMov,iCol,varargin)

% global variables
global xGap

% memory allocation and other initialisations
xLim = zeros(1,2);
xGapNw = 3*(nargin == 2)*xGap;

% sets the lower limit
if (iCol == 2)
    xLim(1) = iMov.posG(1) + xGapNw;
else
    xLim(1) = iMov.posO{iCol-1}(1) + xGapNw;
end

% sets the upper limit
if (iCol == iMov.nCol)
    xLim(2) = sum(iMov.posG([1 3])) - xGapNw;
else
    xLim(2) = iMov.posO{iCol+1}(1) - xGapNw;
end

% --- returns the x-limits of the sub-region
function xLim = getRegionXLim(iMov,hAx,iCol)

% memory allocation
xLim = zeros(1,2);

% gets the lower limit based on the row count
if (iCol == 1)
    % sets the lower limit to be the bottom
    xLim(1) = iMov.posG(1);
else
    % retrieves the position of the lower line region
    api = iptgetapi(get(findall(hAx,'tag','bottom line','UserData',iCol-1),'parent'));
    lPosL = api.getPosition();
    
    % sets the lower limit
    xLim(1) = lPosL(1,1);
end

% gets the upper limit based on the row count
if (iCol == iMov.nCol)
    % sets the upper limit to be the top
    xLim(2) = sum(iMov.posG([1 3]));
else
    % retrieves the position of the upper line region
    api = iptgetapi(get(findall(hAx,'tag','bottom line','UserData',iCol),'parent'));
    lPosR = api.getPosition();
    
    % sets the upper limit
    xLim(2) = lPosR(1,1);    
end

% --- returns the y-limits of the sub-region
function yLim = getRegionYLim(iMov,hAx,iRow,iCol)

% memory allocation
yLim = zeros(1,2);

% gets the lower limit based on the row count
if (iRow == 1)
    % sets the lower limit to be the bottom
    yLim(1) = iMov.posG(2);
else
    % retrieves the position of the lower line region
    api = iptgetapi(findall(hAx,'tag','hHorz','UserData',[iRow,iCol]));
    lPosLo = api.getPosition();
    
    % sets the lower limit
    yLim(1) = lPosLo(1,2);
end

% gets the upper limit based on the row count
if (iRow == iMov.nRow)
    % sets the upper limit to be the top
    yLim(2) = sum(iMov.posG([2 4]));
else
    % retrieves the position of the upper line region
    api = iptgetapi(findall(hAx,'tag','hHorz','UserData',[iRow+1,iCol]));
    lPosHi = api.getPosition();
    
    % sets the upper limit
    yLim(2) = lPosHi(1,2);    
end

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- initialisation of the subplot data struct
function iMov = initSubPlotStruct(handles,iMov)

% retrieves the main GUI handle struct
hGUI = getappdata(handles.figWinSplit,'hGUI');

% retrieves the axis limits
hAx = hGUI.imgAxes;
[xLim,yLim] = deal(get(hAx,'xlim'),get(hAx,'ylim'));

% sets the subplot variables (based on the inputs)
[nRow,nCol,pG,del] = deal(iMov.nRow,iMov.nCol,iMov.posG,5);
[L,B,W,H] = deal(pG(1),pG(2),pG(3)/nCol,pG(4)/nRow);

% if multi-tracking, set the sub-region count to one/region
if detIfMultiTrack(iMov)
    [iMov.nTube,iMov.nTubeR] = deal(1,ones(nRow,nCol));
end

% sets the window label font sizes and linewidths
fSize = 20 + 6*(~ispc);

% for each row/column initialise the subplot structs
[iMov.posO,iMov.pos] = deal(cell(1,nRow*nCol));
for i = 1:nRow
    for j = 1:nCol
        % sets the parameter struct index/position
        k = (i-1)*nCol + j;
        iMov.posO{k} = [(L+(j-1)*W) (B+(i-1)*H) W H];
        
        % creates the text marker object
        hText = text(0,0,num2str(k),'fontweight','bold','fontsize',fSize,...
                         'tag','hNum','color','r','parent',hAx);   
                     
        hEx = get(hText,'Extent');                     
        set(hText,'position',[L+(j-0.5)*W-(hEx(3)/2) B+(i-0.5)*H 0])
        
        % sets the left/right locations of the sub-window
        PosNw(1) = min(xLim(2),max(xLim(1),L+((j-1)*W+del)));
        PosNw(2) = min(yLim(2),max(yLim(1),B+((i-1)*H+del)));                                               
        PosNw(3) = (W-2*del) + min(0,xLim(2)-(PosNw(1)+(W-2*del)));
        PosNw(4) = (H-2*del) + min(0,yLim(2)-(PosNw(2)+(H-2*del)));      

        % updates the sub-image position vectos
        iMov.pos{k} = PosNw;        
    end
end

% --- resets the outside dimensions of the sub-regions
function posO = resetOutsidePos(iMov)

% array indexing
[pR,pG] = deal(iMov.pos,iMov.posG);
[nRow,nCol,nApp] = deal(iMov.nRow,iMov.nCol,length(iMov.iR));

% memory allocation
[pX,pY,posO] = deal(zeros(nCol+1,1),zeros(nRow+1,1),cell(1,nApp));

% sets the start/end x/y locations
[pX(1),pX(end)] = deal(pG(1),sum(pG([1 3])));
[pY(1),pY(end)] = deal(pG(2),sum(pG([2 4])));

% sets the locations
for i = 2:nCol
    % sets the indices of the left/right sub-regions 
    iL = ((1:iMov.nCol:nApp)-1) + (i-1);
    xR = max(cellfun(@(x)(sum(x([1 3]))),pR(iL)));
    xL = min(cellfun(@(x)(x(1)),pR(iL+1)));
    
    % calculates the mid point of the extremum
    pX(i) = 0.5*(xR + xL);    
end

% sets the locations
for i = 2:nRow
    % sets the indices of the left/right sub-regions 
    iU = (i-2)*nCol + (1:nCol);
    yU = max(cellfun(@(x)(sum(x([2 4]))),pR(iU)));
    yB = min(cellfun(@(x)(x(2)),pR(iU+nCol)));
    
    % calculates the mid point of the extremum
    pY(i) = 0.5*(yU + yB);    
end

% sets the final outside coordinates
for i = 1:nRow
    for j = 1:nCol
        k = (i-1)*nCol + j;
        posO{k} = [pX(j),pY(i),diff(pX(j+(0:1))),diff(pY(i+(0:1)))];
    end
end  

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% ---------------------------------------- %
% --- OBJECT PROPERTY UPDATE FUNCTIONS --- %
% ---------------------------------------- %

% --- initialises the properties of the sub-window position editboxes --- %
function initOutlineProp(handles)

% sets the object strings
wStr = {'Left','Top','Width','Height'};
wStrP = {'Rows','Cols','Tubes'};

% sets the callback functions for all of the outline position editboxes
for i = 1:length(wStr)
    hObj = eval(sprintf('handles.edit%s',wStr{i}));    
    bFunc = @(hObj,e)WindowSplit('editOutDimCallback',hObj,[],guidata(hObj));  
    set(hObj,'Callback',bFunc)
end

% sets the callback functions for all row, column and tube count editboxes
for i = 1:length(wStrP)
    hObj = eval(sprintf('handles.edit%s',wStrP{i}));    
    bFunc = @(hObj,e)WindowSplit('keyPressFunc',hObj,[],guidata(hObj));  
    set(hObj,'KeyPressFcn',bFunc)
end

% --- sets the properties of the sub-window position editboxes --- %
function setOutlineProp(handles,state,pPos)

% sets the panel object handle
hPanel = handles.panelOutlineDim;

% sets the object properties for all the types
for i = 1:4
    % retrieves the edit/text box based on the userdata number
    hEdit = findobj(hPanel,'UserData',i,'style','edit');
    hText = findobj(hPanel,'UserData',i,'style','text');
    
    % sets the enabled states of the objects
    setObjEnable(hEdit,state);
    setObjEnable(hText,state);    
    
    % updates the edit box value (if provided)
    if (strcmp(state,'on') || strcmp(state,'inactive'))
        set(hEdit,'string',num2str(roundP(pPos(i),0.1)))
    end
end

% --- sets the sub-movie property editbox fields --- %
function setSubMovieProp(handles,iMov)

% sets the row, column and tube count editbox fields
set(handles.editRows,'string',num2str(iMov.nRow))
set(handles.editCols,'string',num2str(iMov.nCol))

% sets the fly/sub-region counts
if detIfMultiTrack(iMov)
    set(handles.editTubes,'string',num2str(abs(iMov.nFly)))
else
    set(handles.editTubes,'string',num2str(abs(iMov.nTube)))
end

% --- sets the dimensions of the outer region
function setOuterDimensions(handles,iMov)

% sets the details of the outer dimensions in the editboxes
set(handles.editLeft,'string',num2str(roundP(iMov.posG(1),0.1)));
set(handles.editTop,'string',num2str(roundP(iMov.posG(2),0.1)));
set(handles.editWidth,'string',num2str(roundP(iMov.posG(3),0.1)));
set(handles.editHeight,'string',num2str(roundP(iMov.posG(4),0.1))); 

% --------------------------------- %
% --- REGION PLOTTING FUNCTIONS --- %
% --------------------------------- %

% --- plots the circle regions on the main GUI to enable visualisation
function plotRegionOutlines(handles,iMov,forceUpdate)

% retrieves the sub-region and main GUI handles data struct
hGUI = getappdata(handles.figWinSplit,'hGUI');
if ~exist('forceUpdate','var'); forceUpdate = false; end
if ~exist('iMov','var'); iMov = getappdata(handles.figWinSplit,'iMov'); end

% sets the circle visibility based on the checked status
hOut = findall(hGUI.imgAxes,'tag','hOuter');
if strcmp(get(handles.menuShowRegion,'checked'),'on') || forceUpdate
    % menu item is checked, so makes the regions visible
    if isempty(hOut)        
        % creates the outlines based on the type
        switch iMov.autoP.Type
            case 'Circle'           
                createCircleOutlines(hGUI.imgAxes,iMov);
                
            case 'GeneralR'
                createGeneralOutlines(hGUI.imgAxes,iMov);
        end              
    else
        % otherwise, make the circles visible
        setObjVisibility(hOut,'on')
    end
else
    % otherwise, make the circular regions invisible
    setObjVisibility(hOut,'off')
end

% --- creates the circle outlines
function createCircleOutlines(hAx,iMov)

% adds a hold to the axis
hold(hAx,'on');

% sets the X/Y coordinates of the circle centres
[X,Y,XC,YC] = deal(iMov.autoP.X0,iMov.autoP.Y0,iMov.autoP.XC,iMov.autoP.YC);

% loops through all the sub-regions plotting the general objects   
for iApp = 1:length(iMov.iR)
    % retrieves the global row/column indices
    [iCol,iFlyR0,iRow] = getRegionIndices(iMov,iApp);
    iFlyR = iFlyR0(iMov.isUse{iRow,iCol});

    % creates the new fill objects for each valid region    
    for k = iFlyR(:)'
        % calculates the new coordinates and plots the circle
        [xP,yP] = deal(X(k,iCol)+XC,Y(k,iCol)+YC);
        fill(xP,yP,'r','tag','hOuter','UserData',[iCol k],...
                   'facealpha',0.25,'LineWidth',1,'Parent',hAx)
    end
end  

% removes the hold
hold(hAx,'off');

% --- creates the general object outlines
function createGeneralOutlines(hAx,iMov)

% adds a hold to the axis
hold(hAx,'on');

% sets the object location/outline coordinates
aP = iMov.autoP;
[X0,Y0,XC,YC] = deal(aP.X0,aP.Y0,aP.XC,aP.YC);

% loops through all the sub-regions plotting the general objects   
for iApp = 1:length(iMov.iR)
    % retrieves the global row/column indices
    [iCol,iFlyR0,iRow] = getRegionIndices(iMov,iApp);
    iFlyR = iFlyR0(iMov.isUse{iRow,iCol});

    % creates the new fill objects for each valid region    
    for j = 1:length(iFlyR)
        k = iFlyR(j);
        fill(X0(k,iCol)+XC,Y0(k,iCol)+YC,'r','tag','hOuter',...
                   'UserData',[iCol k],'facealpha',0.25,'LineWidth',1,...
                   'Parent',hAx)
    end
end 

% removes the hold
hold(hAx,'off');

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- if the sub-regions are set, and the user alters the dimension
%     editboxes, then prompt them if they wish to continue. if so, then
%     reset all of the properties pertaining to the current sub-region set
function [isReset,uChoice] = resetMovQuest(handles,qStr,bStr)

% sets the default question string (if required)
if ~exist('qStr','var')
    % if the user hasn't provided a question string, then set a default
    qStr = {'This action will overwrite the current sub-region selection.';...
            'Do you wish to continue?'};  
end

% sets the default button string
if ~exist('bStr','var'); bStr = ''; end

% initialisations
iMov = getappdata(handles.figWinSplit,'iMov');
[hGUI,isReset] = deal(getappdata(handles.figWinSplit,'hGUI'),true);

% if the sub-regions are not set, then exit with a true value
if ~iMov.isSet
    return; 
end

% sets the function string
fStr = sprintf(['questdlg(qStr,''Reset Sub-Regions?'',''Yes'',',...
                '''No''%s,''Yes'')'],bStr);

% prompts the user if they wish to continue
uChoice = eval(fStr);
if ~strcmp(uChoice,'Yes')
    % if the user selected no, then exit the function
    isReset = false; 
    return
end

% disables the relevant objects
setObjEnable(handles.buttonUpdate,'off')
setObjEnable(handles.menuAutoPlace,'off')

% removes the check-mark from the pattern menu (if it exists)
hMenuC = findall(handles.menuRegionType,'Checked','on');
if ~isempty(hMenuC)
    set(hMenuC,'Checked','off')
end

% removes any circle objects (if present)
hOut = findall(hGUI.imgAxes,'tag','hOuter');
if ~isempty(hOut); delete(hOut); end

% deletes the manual placement sub-regions (if present)
deleteSubRegions(handles) 

% slight pause to update the GUI
pause(0.05)

% --- initialises the automatic detection algorithm values
function [iMov,hGUI,I] = initAutoDetect(handles)

% prompts the user that the smart region placement only works for circular
% regions (this may change in the future...)
qStr = {'Note that the automatically detected regions are fixed.';...
        'Do you still wish to continue?'};
uChoice = questdlg(qStr,'Automatic Circle Detection','Yes','No','Yes');
if (~strcmp(uChoice,'Yes'))
    [iMov,hGUI,I] = deal([]);
    return    
end        

% retrieves the original sub-region data struct
iMov0 = getappdata(handles.figWinSplit,'iMov');

% retrieves the main image axes image
hGUI = getappdata(handles.figWinSplit,'hGUI');
I = get(findobj(get(hGUI.imgAxes,'children'),'type','image'),'cdata');

% determines if the sub-region data struct has been set
if isempty(iMov0.iR)
    % if the sub-regions not set, then determine them from the main axes
    buttonUpdate_Callback(handles.buttonUpdate, '1', handles)

    % retrieves the sub-region data struct and 
    iMov = getappdata(handles.figWinSplit,'iMov');
    if isfield(iMov,'autoP'); iMov = rmfield(iMov,'autoP'); end
    setappdata(handles.figWinSplit,'iMov',iMov0);
else
    % otherwise set the original to be the test data struct
    iMov = iMov0; clear iMov0
end
    
% makes the GUI invisible (for the duration of the calculations)
setObjVisibility(handles.figWinSplit,'off'); pause(0.05)

% removes any previous markers and updates from the main GUI axes
deleteSubRegions(handles)

% --- updates the figure/axis properties after automatic detection
function postAutoDetectUpdate(handles,hGUI,iMov0,iMovNw,isUpdate)

% global variables
global isChange

% determines if the user decided to update or not
if isUpdate
    % if the user updated the solution, then update the data struct
    isChange = true;
    setappdata(handles.figWinSplit,'iMov',iMovNw);
    
    % updates the global position coordinates
    setOutlineProp(handles,'inactive',iMovNw.posG)

    % updates the menu properties
    set(setObjEnable(handles.menuUseAuto,'on'),'checked','on')
    set(setObjEnable(handles.menuShowRegion,'on'),'checked','off')
    
    % shows the regions on the main GUI
    menuShowRegion_Callback(handles.menuShowRegion, [], handles)
    
    % global variables
    setObjEnable(handles.buttonUpdate,'on')
else
    % updates the menu properties
    set(setObjEnable(handles.menuUseAuto,'off'),'checked','off')
    set(setObjEnable(handles.menuShowRegion,'off'),'checked','on')    
    
    % shows the tube regions
    menuShowRegion_Callback(handles.menuShowRegion, [], handles)
    
    % resets the sub-regions on the main GUI axes
    setupSubRegions(handles,iMov0,true);    
end

% makes the Window Splitting GUI visible again
setObjVisibility(handles.figWinSplit,'on'); pause(0.05)
figure(handles.figWinSplit)  

% --- sets the pattern menu item check mark
function setPatternMenuCheck(handles,Type)

% sets the default input arguments
if ~exist('Type','var')
    Type = getDetectionType(getappdata(handles.figWinSplit,'iMov'));
end

% sets the check mark for the corresponding menu item
hMenu = findall(handles.menuRegionType,'UserData',Type);
if ~isempty(hMenu)
    set(hMenu,'Checked','on')
end

% if successful, then set the ratio check
function resetPatternMenuCheck(hMenu)

% determines the currented checked menu item
hMenuC = findall(get(hMenu,'Parent'),'Checked','on');

% if the current checked item isn't the new one, then reset the checkmarks
if ~isequal(hMenu,hMenuC)
    set(hMenuC,'Checked','off');
    set(hMenu,'Checked','on');
end

% --- resets the sub-region data struct fields
function iMov = resetSubRegionDataStruct(iMov,resetCount)

% sets the default input arguments
if ~exist('resetCount','var'); resetCount = true; end

% resets the set flag
iMov.isSet = false;

% resets the important sub-region fields
iMov.autoP = [];

% resets the count/region use flags (if required)
if resetCount
    [iMov.isUse,iMov.nFlyR,iMov.nTubeR] = deal([]);
end
