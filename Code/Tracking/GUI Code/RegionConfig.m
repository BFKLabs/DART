function varargout = RegionConfig(varargin)
% Last Modified by GUIDE v2.5 27-Oct-2021 22:34:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RegionConfig_OpeningFcn, ...
                   'gui_OutputFcn',  @RegionConfig_OutputFcn, ...
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


% --- Executes just before RegionConfig is made visible.
function RegionConfig_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for RegionConfig
handles.output = hObject;

% global variables
global isMouseDown isMenuOpen p0
global isChange useAuto mainProgDir isCalib frmSz0 isUpdating
[isMouseDown,isMenuOpen,isChange,isUpdating,useAuto] = deal(false);
p0 = [];

% sets the input variables
hGUI = varargin{1};
hPropTrack0 = varargin{2};

% creates a loadbar figure
hLoad = ProgressLoadbar('Initialising Region Setting GUI...');

% loads the background parameter struct from the program parameter file
A = load(fullfile(mainProgDir,'Para Files','ProgPara.mat'));
bgP = DetectPara.resetDetectParaStruct(A.bgP);

% sets the input arguments into the gui
pFldStr = {'hDiff','iMov','iMov0','isMTrk','iData','hSelP','hProp0',...
           'infoObj','cmObj','hTabGrp','jTabGrp','hTab','srObj',...
           'phObj','gridObj'};
initObjPropFields(hObject,pFldStr);
addObjProps(hObject,'hGUI',hGUI,'hPropTrack0',hPropTrack0)

% ---------------------------------------- %
% --- FIELD & PROPERTY INITIALISATIONS --- %
% ---------------------------------------- %

% sets the data structs into the GUI
hFig = hGUI.figFlyTrack;
iMov = get(hFig,'iMov');

% sets the background parameter struct (if not set)
isSet = iMov.isSet;
if ~isfield(iMov,'bgP')
    iMov.bgP = bgP;
elseif isempty(iMov.bgP)
    iMov.bgP = bgP;
end

% sets the manual region shape flag (if not set)
if ~isfield(iMov,'mShape')
    iMov.mShape = 'Rect';
end

% determines if the user is using multi-fly tracking
isMTrk = detMltTrkStatus(iMov);

% sets the frame size (if calibrating for the RT-Tracking/Calibration)
if isCalib
    infoObj = get(hFig,'infoObj');
    if isa(infoObj.objIMAQ,'cell')
        % case is the testing form of the gui
        frmSz0 = size(infoObj.objIMAQ{1});
    else
        % case is for proper calibration/RT-tracking
        vRes = getVideoResolution(infoObj.objIMAQ);
        frmSz0 = vRes([2 1]);
    end

    % sets the image acquisition object into the GUI
    set(hObject,'infoObj',infoObj);
end

% updates the GUI font-sizes and disables all tracking panels
% setGUIFontSize(handles)
hProp0 = disableAllTrackingPanels(hGUI,1);
set(hObject,'hProp0',hProp0,'iMov',iMov,'iMov0',iMov,'isMTrk',isMTrk)

% ---------------------------------------- %
% --- FIELD & PROPERTY INITIALISATIONS --- %
% ---------------------------------------- %

% converts/initialises the gui data struct from the sub-region data struct
if isSet
    % case is the sub-region data struct has already been set up
    hObject.iData = convertDataStruct(iMov);
    
    % if the binary mask field (for the 2D circle automatic placement) has 
    % not been set in iMov, then set the field and mark a change
    if ~isfield(hObject.iMov,'autoP'); hObject.iMov.autoP = []; end    
    
    % if the movie has already been set, then set the window properties and
    % disable the set button
    setObjEnable(handles.buttonSetRegions,'on')        
    
    % sets the fields based on the 
    [setRegions,is2Dset] = deal(true,is2DCheck(hObject.iMov));
    if is2Dset                
        if ~isempty(hObject.iMov.autoP)
            % initialises the isAuto flag (if not set already)
            if ~isfield(hObject.iMov.autoP,'isAuto')
                hObject.iMov.autoP.isAuto = true;
            end
                        
            if hObject.iMov.autoP.isAuto
                % plots the circle regions on the main GUI axes
                setRegions = false;
                plotRegionOutlines(handles,hObject.iMov,1)
                setPatternMenuCheck(handles)      

                % sets the use automatic detection flag
                useAuto = true;
            else
                % sets the default region type
                mType = hObject.iMov.autoP.Type(1:4);                
                hMenu0 = findall(handles.menuRegionShape,'type','uimenu');
                
                % turns off/on the correct markers
                arrayfun(@(x)(set(x,'Checked','off')),hMenu0);
                set(findall(hMenu0,'tag',mType),'Checked','on');
            end
        end          
    end    
    
    % sets the other object properties
    setMenuCheck(handles.menuUseAuto,useAuto);
    setMenuCheck(handles.menuShowInner,~hObject.iData.is2D);
    setMenuCheck(handles.menuShowRegion,hObject.iData.is2D);
    setObjEnable(handles.menuView,hObject.iMov.isSet)
    setObjEnable(handles.menuSplitRegion,hObject.iMov.isSet)
    
    % draw the sub-region division figures (if not auto-detecting)
    if setRegions           
        setupSubRegions(handles,hObject.iMov,true);
    end
    
    % sets the GUI to the top
    uistack(hObject,'top')      
else
    % otherwise, initialise the data struct
    hObject.iData = initDataStruct(iMov);
end

% sets the function handles into the gui
addObjProps(hObject,'resetMovQuest',@resetMovQuest,...
                    'resetSubRegionDataStruct',@resetSubRegionDataStruct,...
                    'setupSubRegions',@setupSubRegions,...
                    'roiCallback',@roiCallback,...
                    'deleteSubRegions',@deleteSubRegions)

% ---------------------------------- %
% --- OBJECT & DATA STRUCT SETUP --- %
% ---------------------------------- %

% if multi-tracking, reset some of the object text strings
if hObject.isMTrk
    % only use the 1D setup for multi-tracking
    [hObject.iData.is2D,hObject.iData.isFixed] = deal(false,true);
    if ~isSet
        hObject.iMov.bgP.pMulti.isFixed = true;
    end
        
    % updates the text label
    hEdit = findall(handles.panel1D,'UserData','nFlyMx');
    set(hEdit,'string','Fixed Region Fly Count: ')
end

% initialises the object properties
initObjProps(handles,true);

% ------------------------------- %
% --- HOUSE-KEEPING EXERCISES --- %
% ------------------------------- %

% closes the loadbar
try; close(hLoad); end

% centres the gui to the middle of the string
centreFigPosition(hObject);

% turns off all warnings and makes the gui visible (prevents warning message)
wState = warning('off','all');
setObjVisibility(hObject,'on');
pause(0.05);
warning(wState)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes RegionConfig wait for user response (see UIRESUME)
% uiwait(handles.figRegionSetup);


% --- Outputs from this function are returned to the command line.
function varargout = RegionConfig_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when user attempts to close figRegionSetup.
function figRegionSetup_CloseRequestFcn(hObject, eventdata, handles)

% do nothing...?

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figRegionSetup_WindowButtonUpFcn(hFig, eventdata, handles)

% global variables
global p0 isMouseDown

% initialisations
hAx = handles.axesConfig;

% determines if the user is currently click and dragging
if isMouseDown   
    % sets the group colour
    iSel = get(handles.popupCurrentGroup,'Value');
    
    % retrieves the current mouse position
    mP = get(hAx,'CurrentPoint');
    mP = ceil(mP(1,1:2));
    iC = min(p0(1),mP(1)):max(p0(1),mP(1));
    iR = min(p0(2),mP(2)):max(p0(2),mP(2));
    
    % updates the 
    pInfo = getDataSubStruct(handles);
    pInfo.iGrp(iR,iC) = iSel - 1;
    setDataSubStruct(handles,pInfo);
    
    % deletes the selection patch
    selectionPatchFunc(hFig,hAx,'delete')
    
    % resets the configuration axes
    resetConfigAxes(handles)   
end

% resets the mouse-down flag
isMouseDown = false;

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figRegionSetup_WindowButtonDownFcn(hFig, eventdata, handles)

% global variables
global p0 isMouseDown isMenuOpen
[p0,isMouseDown] = deal([],false);

% initialisations
hAx = handles.axesConfig;
mPos = get(hFig,'CurrentPoint');
iData = get(hFig,'iData');
cmObj = get(hFig,'cmObj');

% determines if the mouse is over the axis
if isOverAxes(mPos) && iData.is2D
    % retrieves the current selection type
    sType = get(hFig,'SelectionType');
    isCustomGrp = get(handles.radioCustomGroup,'value');    
    if strcmp(sType,'alt')
        % sets up the 
        pInfo = getDataSubStruct(handles,1);
        mPosAx = ceil(get(hAx,'CurrentPoint'));        
        cmObj.updateMenuCheck(pInfo.iGrp(mPosAx(1,2),mPosAx(1,1))+1);
        
        % updates the menu position        
        cmObj.updatePosition(mPos);
        cmObj.setVisibility(1)        
        
        % flag that the menu is now open
        isMenuOpen = true;
        return
        
    elseif strcmp(sType,'normal') 
        if isMenuOpen          
            
            % if the mouse click is not on the menu, then close it
            isMenuOpen = false;
            cmObj.setVisibility(0);
            
        elseif isCustomGrp
            % otherwise, if customising and the left click was selected, 
            % then determine if the mouse is over a patch object
            hHover = findAxesHoverObjects(hFig,{'tag','hRegion'});
            if isempty(hHover)
                % if there are no objects, then exit
                return
            end

            % sets the initial point of the selection
            mP = get(hAx,'CurrentPoint');    
            [p0,isMouseDown] = deal(ceil(mP(1,1:2)),true);

            % sets the group colour
            iSel = get(handles.popupCurrentGroup,'Value');
            pCol = getAllGroupColours(length(iData.D2.gName));    

            % creates the selection patch function
            selectionPatchFunc(hFig,hAx,'add',pCol(iSel,:))
        end
    end    
end

%
if isMenuOpen
    cmObj.setVisibility(0)
end

% --- Executes on mouse motion over figure - except title and menu.
function figRegionSetup_WindowButtonMotionFcn(hFig, eventdata, handles)

% global variables
global isMouseDown isMenuOpen

% initialisations
hAx = handles.axesConfig;

% determines if the user is currently click and dragging
mP = get(hAx,'CurrentPoint');
if isMouseDown
    % updates the selection patch    
    selectionPatchFunc(hFig,hAx,'update',ceil(mP(1,1:2)))
    
elseif isMenuOpen
    % initialisations
    cmObj = get(hFig,'cmObj');
    
    % determines if the mouse is over the menu    
    if isOverAxes(get(hFig,'CurrentPoint'))
        hMenu = findAxesHoverObjects(hFig,{'tag','hMenu'},hFig);
        if ~isempty(hMenu)
            % if the mouse is over the context menu, then determine which 
            % text label the mouse is hovering over
            hLbl = findAxesHoverObjects(hFig,{'style','text'},hMenu);
            if ~isempty(hLbl)         
                % if the mouse is over a label, then retrieve the label index
                iSel = get(hLbl,'UserData');
                if cmObj.iSel ~= iSel
                    % if the selection has changed, then de-highlight the
                    % currently highlighted menu item
                    if cmObj.iSel > 0
                        cmObj.setMenuHighlight(cmObj.iSel,0)
                    end

                    % updates the menu highlight
                    cmObj.setMenuHighlight(iSel,1)                
                end

                % exits the function
                return
            end
        end
    else
        % if no longer over the axes, close the menu
        isMenuOpen = false;
        cmObj.setVisibility(0);
    end
    
    % if the menu highlight is still on, then remove it
    if cmObj.iSel > 0
        cmObj.setMenuHighlight(cmObj.iSel,0)
    end
end

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% ----------------------- %
% --- FILE MENU ITEMS --- %
% ----------------------- %

% --------------------------------------------------------------------
function menuReset_Callback(hObject, eventdata, handles)

% global variables
global useAuto

% prompts the user if they wish to proceed
qStr = {'Are you sure you want to reset the current configuration?';...
        'The operation can not be reversed.'};
uChoice = questdlg(qStr,'Reset Configuration?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if the user did not confirm, then exit
    return
end

% object handles
useAuto = false;
hFig = handles.output;
hFig.iMov.isSet = false;

% removes the sub-regions
deleteSubRegions(handles)

% resets the data struct and the object properties
set(hFig,'iData',initDataStruct(hFig.iMov))
initObjProps(handles,false)

% -------------------------------------------------------------------------
function menuClose_Callback(hObject, eventdata, handles)

% global variables
global isChange

% if there is an update specified, then prompt the user to update
if strcmp(get(handles.buttonUpdate,'enable'),'on')
    % prompts the user if they wish to update the struct
    uChoice = questdlg('Do you wish to update the specified sub-region?',...
            'Update Sub-Regions?','Yes','No','Cancel','Yes');
    switch uChoice
        case ('Yes') % case is the user wants to update movie struct
            if strcmp(get(handles.menuUseAuto,'checked'),'off')
                buttonUpdate_Callback(handles.buttonUpdate, 1, handles)
            end
            
        case ('No') % case is the user does not want to update
            isChange = false;
            
        otherwise % case is the user cancelled
            return            
    end
end

% loads the movie struct
hFig = handles.output;
hGUI = get(hFig,'hGUI');
iMov = get(hFig,'iMov');
hProp0 = get(hFig,'hProp0');
hPropTrack0 = get(hFig,'hPropTrack0');

% makes the gui invisible
setObjVisibility(hFig,'off');

% closes the grid detection GUI (if open)
hGrid = findall(0,'tag','figGridDetect');
if ~isempty(hGrid)
    gridObj = get(hFig,'gridObj');
    gridObj.isClosing = true;
    gridObj.cancelButton(gridObj.hButC{3})
end

% deletes the sub-regions from tracking gui axes
deleteSubRegions(handles)
if ~isempty(hGUI)
    % removes all the circle regions from the main GUI (if they exist)
    hOut = findall(hGUI.imgAxes,'tag','hOuter');
    if ~isempty(hOut); delete(hOut); end

    % closes the window
    resetHandleSnapshot(hProp0)

    % runs the post window split function
    postWindowSplit = get(hGUI.figFlyTrack,'postWindowSplit');
    postWindowSplit(hGUI,iMov,hPropTrack0,isChange)
end

% closes the GUI
delete(hFig)

% ----------------------- %
% --- VIEW MENU ITEMS --- %
% ----------------------- %

% -------------------------------------------------------------------------
function menuShowInner_Callback(hObject, eventdata, handles)

% initialisations
hFig = handles.output;
hGUI = get(hFig,'hGUI');

% toggles the menu item
toggleMenuCheck(hObject)
isShow = strcmp(get(hObject,'checked'),'on');

% sets the object properties
setObjEnable(handles.buttonUpdate,isShow);
setObjVisibility(findobj(hGUI.imgAxes,'tag','hNum'),isShow);
setObjVisibility(findobj(hGUI.imgAxes,'UserData','hTube'),isShow);

% sets the visibility of the inner regions
hInner = findobj(hGUI.imgAxes,'tag','hInner');
setObjVisibility(hInner,isShow);

% ensures the region bottom line objects are made invisible
if isShow
    setObjVisibility(findall(hInner,'tag','bottom line'),'off');
end

% -------------------------------------------------------------------------
function menuShowRegion_Callback(hObject, eventdata, handles)

% toggles the menu item
toggleMenuCheck(hObject)

% plots the region outlines
plotRegionOutlines(handles)

% -------------------------------------- %
% --- AUTOMATIC DETECTION MENU ITEMS --- %
% -------------------------------------- %

% -------------------------------------------------------------------------
function menuUseAuto_Callback(hObject, eventdata, handles)

% global variables
global useAuto isChange
isChange = true;

% retrieves the main GUI handle data struct
hFig = handles.output;
iMov = get(hFig,'iMov');
iData = get(hFig,'iData');

% performs the action based on the menu item checked status 
useAuto = strcmp(get(hObject,'checked'),'off');
if useAuto
    % removes the sub-regions
    deleteSubRegions(handles)
else
    % disables the show region menu item and removes the regions
    if iData.is2D        
        setMenuCheck(setObjEnable(handles.menuShowRegion,'off'),'on')
        menuShowRegion_Callback(handles.menuShowRegion, [], handles)
    else
        setMenuCheck(setObjEnable(handles.menuShowInner,'off'),'off')
        menuShowInner_Callback(handles.menuShowInner, [], handles)
    end
    
    % resets the sub-regions on the main GUI axes    
    setupSubRegions(handles,iMov,true);    
end    

% updates the menu item properties
toggleMenuCheck(hObject);
updateMenuItemProps(handles)

% makes the Window Splitting GUI visible again
uistack(hFig,'top')  

% ----------------------------------------- %
% --- 1D AUTOMATIC DETECTION MENU ITEMS --- %
% ----------------------------------------- %

% --------------------------------------------------------------------
function menuDetGrid_Callback(hObject, eventdata, handles)

% field retrieval
isUpdate = false;
hFig = handles.output;
iMov0 = get(hFig,'iMov');

% if the field does exist, then ensure it is correct
hFig.iMov.bgP = DetectPara.resetDetectParaStruct(hFig.iMov.bgP);
hFig.iMov = setSubRegionDim(hFig.iMov,hFig.hGUI);

% opens the grid detection tracking parameter gui
gridObj = GridDetect(hFig);
if gridObj.iFlag == 3
    % if the user cancelled, then exit
    setupSubRegions(handles,iMov0,true);
    return
end

% keep looping until either the user quits or accepts the result
cont = gridObj.iFlag == 1;
while cont
    % runs the 1D auto-detection algorithm
    [iMovNw,trkObj] = detGridRegions(hFig);
    if isempty(iMovNw)
        % if user cancelled then exit the loop after closing para gui  
        set(hFig,'iMov',iMov0)
        setupSubRegions(handles,iMov0,true);
        gridObj.closeGUI();
        return
    end

    % allow user to reset location of regions (either up or down) or 
    % redo the region calculations
    gridObj.checkDetectedSoln(iMovNw,trkObj);
    switch gridObj.iFlag
        case 2
            % case is the user continued
            [cont,isUpdate] = deal(false,true);
            
        case 3
            % case is the user cancelled
            if gridObj.isClosing
                % if closing region config GUI, then exit
                return
            else
                % otherwise, exit the loop
                break
            end
    end
end

% creates a progress loadbar
h = ProgressLoadbar('Setting Final Region Configuration'); 
pause(0.05);

% updates the sub-regions (if updating)
if isUpdate
    setupSubRegions(handles,gridObj.iMov,true);
end

% sets up the sub-regions for the final time (delete loadbar)
postAutoDetectUpdate(handles,iMov0,gridObj.iMov,isUpdate)
delete(h)

% ----------------------------------------- %
% --- 2D AUTOMATIC DETECTION MENU ITEMS --- %
% ----------------------------------------- %

% -------------------------------------------------------------------------
function menuDetCircle_Callback(hObject, eventdata, handles)

% initialisations
[cont,isUpdate,hQ] = deal(true,false,0.25);

% retrieves the automatic detection algorithm objects
[iMov,hGUI,~] = initAutoDetect(handles);
if isempty(iMov); return; end

% retrieves the region estimate image stack
I = getRegionEstImageStack(handles,hGUI,iMov); 

% keep looping until either the user is satified or cancels
while cont
    % run the automatic region detection algorithm 
    [iMovNw,R,X,Y,ok] = detImageCircles(I,iMov,hQ);
    if ok   
        % if successful, run the circle parameter GUI        
        [iMovNw,hQ,uChoice] = CircPara(handles,iMovNw,X,Y,R,hQ); 
        switch uChoice
            case ('Cont') 
                % user is continuing, so exit loop with update
                [cont,isUpdate] = deal(false,true);
                
            case ('Cancel') 
                % user cancelled, so exit loop with no update
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
postAutoDetectUpdate(handles,iMov,iMovNw,isUpdate);

% -------------------------------------------------------------------------
function menuDetGeneral_Callback(hObject, eventdata, handles)

% retrieves the automatic detection algorithm objects
[iMov,hGUI,~] = initAutoDetect(handles);
if isempty(iMov); return; end

% retrieves the region estimate image stack
I = getRegionEstImageStack(handles,hGUI,iMov); 

try
    % runs the general region detection algorithm
    iMovNw = detGenRegions(iMov,I);
    
catch 
    % if there was an error, then output a message to screen
    eStr = sprintf(['There was an error in the general region ',...
                    'detection calculations. Try resetting the search ',...
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
postAutoDetectUpdate(handles,iMov,iMovNw,~isempty(iMovNw));

% -------------------------------------------------------------------------
function menuDetGeneralCust_Callback(hObject, eventdata, handles)

% FINISH ME!
showUnderDevelopmentMsg()

% ------------------------------- %
% --- REGION SHAPE MENU ITEMS --- %
% ------------------------------- %

% --- toggles the shape menu check items
function toggleShapeMenuCheck(hMenu)

% determines the currently selected menu item
hMenu0 = findall(get(hMenu,'Parent'),'Checked','on');

% toggles the menu check item
set(hMenu0,'Checked','off');
set(hMenu,'Checked','on');

% --------------------------------------------------------------------
function menuShapeRect_Callback(hObject, eventdata, handles)

% toggles the shape menu check items
toggleShapeMenuCheck(hObject)

% updates the shape flag
handles.output.iMov.mShape = 'Rect';

% --------------------------------------------------------------------
function menuShapeCirc_Callback(hObject, eventdata, handles)

% toggles the shape menu check items
toggleShapeMenuCheck(hObject)

% updates the shape flag
handles.output.iMov.mShape = 'Circ';

% --------------------------------------------------------------------
function menuShapePoly_Callback(hObject, eventdata, handles)

% toggles the shape menu check items
toggleShapeMenuCheck(hObject)

% updates the shape flag
handles.output.iMov.mShape = 'Poly';

% --------------------------------------------------------------------
function menuSplitRegion_Callback(hObject, eventdata, handles)

% splits the sub-region
hFig = handles.output;
set(hFig,'srObj',SplitSubRegion(hFig));

%-------------------------------------------------------------------------%
%                         OTHER CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- callback function for selecting the protocol tabs
function tabSelected(hObj, ~, handles)

% updates the 2D selection flag
hTabSel = get(get(hObj,'Parent'),'SelectedTab');
handles.output.iData.is2D = strcmp(get(hTabSel,'Title'),'2D Setup');

% updates the menu item properties
updateMenuItemProps(handles)

% resets the configuration axes
resetConfigAxes(handles)

% --- updates the menu item properties (based on current selections)
function updateMenuItemProps(handles)

% global variables
global useAuto

% initialisations
hFig = handles.output;
iMov = get(hFig,'iMov');
iData = get(hFig,'iData');
showInner = ~useAuto && ~iData.is2D;
isMltTrk = detMltTrkStatus(iMov);

% sets the menu item enabled properties
setObjEnable(handles.menuReset,iMov.isSet);
setObjEnable(handles.menuView,iMov.isSet);
setObjEnable(handles.menuAutoPlace,iMov.isSet);
setObjEnable(handles.menuSplitRegion,iMov.isSet);
setObjEnable(handles.menuRegionShape,iData.is2D || isMltTrk);

% if the regions are not set, then exit
if ~iMov.isSet; return; end

% updates the enabled properties of the view items
setObjEnable(handles.menuShowInner,showInner);
setObjEnable(handles.menuShowRegion,useAuto && iData.is2D);

% turns off the show inner check mark (if not showing inned regions)
if ~showInner
    setMenuCheck(handles.menuShowInner,'off')
end

% updates the enabled properties of the detection menu items
setObjEnable(handles.menuUseAuto,1)
setObjEnable(handles.menuDetectSetup1D,~iData.is2D);
setObjEnable(handles.menuDetectSetup2D,iData.is2D);

% --- callback function for the parameter editbox update
function editParaUpdate(hObj, ~, handles)

% initialisations
[eVal,pMlt] = deal([]);
hFig = handles.output;
iData = get(hFig,'iData');
pInfo = getDataSubStruct(handles);
nwVal = str2double(get(hObj,'String'));

% iMov = get(hFig,'iMov');
% isMTrk = detMltTrkStatus(iMov);

% determines if the grid row/column multiplier needs to be taken into
% account (only if 2D, more than 1 group, and grid grouping selected)
isGrid = iData.is2D && (pInfo.nGrp > 1) && ...
                                    get(handles.radioGridGroup,'value');

% retrieves the sub-struct 
pStr = get(hObj,'UserData');
switch pStr
    case 'nRow'
        % case is the row count
        nwLim = [1,20];
        if isGrid; pMlt = pInfo.nRowG; end
        
    case 'nCol'
        % case is the column count
        nwLim = [1,20];  
        if isGrid; pMlt = pInfo.nColG; end
        
    case 'nGrp'
        % case is the overall 
        nwLim = [1,pInfo.nRow*pInfo.nCol];
        
    case 'nFlyMx'
        % case is the maximum fly count
        nwLim = [1,50];
        
    case 'nRowG'
        % case is the grid row count
        nwLim = [1,pInfo.nRow];
        eVal = getAllDivisors(pInfo.nRow);
        
    case 'nColG'
        % case is the grid row count
        nwLim = [1,pInfo.nCol];
        eVal = getAllDivisors(pInfo.nCol);
        
end

% checks if the new value is valid
if chkEditValue(nwVal,nwLim,true,'exactVal',eVal,'exactMlt',pMlt)
    % if so, update the parameter in the data struct
    pInfo = setStructField(pInfo,pStr,nwVal);
    setDataSubStruct(handles,pInfo);
    
    % updates the group 
    hEdit = findall(get(hObj,'Parent'),'UserData','nGrp');
    setObjEnable(hEdit,pInfo.nRow*pInfo.nCol > 1)    
    
    % updates the parameters based on the values/parameters being updated
    if pInfo.nRow*pInfo.nCol < pInfo.nGrp
        % case is the overall group count exceeds the existing dimensions
        
        % updates the group count
        pInfo.nGrp = pInfo.nRow*pInfo.nCol;
        set(hEdit,'String',num2str(pInfo.nGrp))
        setDataSubStruct(handles,pInfo);
        
        % updates the group name table (if updating the group count)
        updateGroupNameTable(handles)         
    
    elseif strcmp(pStr,'nGrp')
        % updates the group name table (if updating the group count)
        updateGroupNameTable(handles)
        if iData.is2D
            % updates the panel properties
            hPanelI = handles.panelRegionInfo2D;
            setPanelProps(hPanelI,nwVal>1)
            setPanelProps(handles.panelGridGrouping,'off')
            setPanelProps(handles.panelCustomGrouping,'off')                          
        end
        
    elseif strcmp(pStr,'nFlyMx')
        % case is the maximum fly count (ensures no existing counts exceeds
        % this new value)
        pInfo.nFly = min(pInfo.nFly,pInfo.nFlyMx);
        setDataSubStruct(handles,pInfo);
    end    
    
    % updates the data struct/information table
    if iData.is2D
        % updates the data sub-struct
        pInfo = updateGroupArrays(handles);
        setDataSubStruct(handles,pInfo,true);          
        
        if pInfo.nGrp == 1
            % if there is only one group, then reset the group indices so
            % that they are all 1
            pInfo.iGrp(:) = 1;   
            setDataSubStruct(handles,pInfo,true);
            
        else
            % otherwise, update
            hPanelI = handles.panelRegionInfo2D;
            hRadio = findall(hPanelI,'style','radiobutton','value',1);
            panelRegionInfo2D_SelectionChangedFcn(hRadio,1,handles)
        end
    else
        % updates the 1D region information table
        updateRegionInfoTable(handles); 
    end
        
    % resets the configuration axes
    resetConfigAxes(handles)    
else
    % otherwise, revert back to the previous valid value
    set(hObj,'String',num2str(getStructField(pInfo,pStr)))
end

% --- callback function for the group name table update
function tableGroupName(hTable, eventdata, handles)

% if there are no indices provided, then exit the function
if isempty(eventdata.Indices)
    return
end

% initialisations
iSel = eventdata.Indices;
nwVal = eventdata.NewData;
hFig = handles.output;
pInfo = getDataSubStruct(handles);

% determines if the new name is unique
isOther = ~setGroup(iSel(1),[length(pInfo.gName),1]);
if any(strcmp(pInfo.gName(isOther),nwVal))
    % if not, then output an error to screen 
    mStr = sprintf(['The group name "%s" already exists in the list.\n',...
                    'Please try again with a different group name.'],nwVal);
    waitfor(msgbox(mStr,'Replicated Group Name','modal'))
    
    % reverts the value back to the previous value
    tData = get(hTable,'Data');
    tData{iSel(1),iSel(2)} = eventdata.PreviousData;
    set(hTable,'Data',tData);
    
    % exits the function
    return
else
    % otherwise, updates the group name
    pInfo.gName{iSel(1)} = nwVal;
    
    % updates the menu label
    if hFig.iData.is2D
        hFig.cmObj.setMenuLabel(iSel(1),nwVal);
    end
end

% updates the sub-struct
setObjEnable(handles.buttonUpdate,1)
setDataSubStruct(handles,pInfo);

% updates the table column format (1D only)
if get(hTable,'UserData') == 1
    updateRegionInfoTable(handles)
end

% --- Executes on button press in checkVarFlyCount.
function checkVarFlyCount_Callback(hObject, eventdata, handles)

% determines if variable fly count is being used
isVar = get(hObject,'Value');
hFig = handles.output;

% updates the multi-tracking 
hFig.iMov.bgP.pMulti.isFixed = ~isVar;

% sets the object enabled properties
setObjEnable(handles.editSRCount,~isVar);
setObjEnable(handles.buttonUpdate,hFig.iMov.isSet)

% ------------------------------------------ %
% --- 1D SETUP SPECIFIC OBJECT CALLBACKS --- %
% ------------------------------------------ %

% --- Executes when entered data in editable cell(s) in tableRegionInfo1D.
function tableRegionInfo1D_CellEditCallback(hObject, eventdata, handles)

% if there are no indices provided, then exit the function
if isempty(eventdata.Indices)
    return
end

% initialisations
iSel = eventdata.Indices;
pInfo = getDataSubStruct(handles,false);

% retrieves the global column/row indices
tData = get(hObject,'Data');
[iRG,iCG] = deal(tData{iSel(1),1},tData{iSel(1),2});

% updates the parameter based on the 
nwVal = eventdata.NewData;
switch iSel(2)
    case 3
        % case is updating the sub-region count
        if chkEditValue(nwVal,[1,pInfo.nFlyMx],1)
            % if the value is valid, then update the field
            pInfo.nFly(iRG,iCG) = nwVal;            
        else
            % otherwise, reset to the previous valid value
            tData{iSel(1),iSel(2)} = eventdata.PreviousData;
            set(hObject,'Data',tData)
            
            % exits the function
            return
        end
        
    case 4
        % case is updating the group name        
        cForm = get(hObject,'ColumnFormat');
        
        % updates the group index values
        iGrpNw = find(strcmp(cForm{end},nwVal)) - 1;
        pInfo.iGrp(iRG,iCG) = iGrpNw;
        
end

% updates the data struct into the gui
setObjEnable(handles.buttonUpdate,1)
setDataSubStruct(handles,pInfo,false);

% resets the configuration axes
resetConfigAxes(handles)

% --- Executes when selected cell(s) is changed in tableRegionInfo1D.
function tableRegionInfo1D_CellSelectionCallback(hObject, eventdata, handles)

a = 1;

% ------------------------------------------ %
% --- 2D SETUP SPECIFIC OBJECT CALLBACKS --- %
% ------------------------------------------ %

% --- Executes when selected object is changed in panelGridGrouping.
function panelRegionInfo2D_SelectionChangedFcn(hRadio, eventdata, handles)

% initialisations
eStr = '';
pInfo = getDataSubStruct(handles,true);

% updates the selected grouping type
pInfo.gType = get(hRadio,'UserData');
setDataSubStruct(handles,pInfo,true);

% updates the group panel properties
updateGroupPanelProps(handles)

% updates the configuration axes (if not running function directly)
if ~ischar(eventdata)
    % updates the grid patterns (if grid grouping selected)
    if strcmp(get(hRadio,'tag'),'radioGridGroup')
        % initialisations
        if pInfo.nGrp == 1
            [nRowG,nColG] = deal(1);              
        else
            % retrieves the column/row grid counts
            hPanelGG = handles.panelGridGrouping;
            hEditC = findall(hPanelGG,'UserData','nColG','Style','Edit');
            hEditR = findall(hPanelGG,'UserData','nRowG','Style','Edit');
            
            % reset the group column grid count (if infeasible)
            if mod(pInfo.nCol,pInfo.nColG) ~= 0
                pInfo.nColG = 1;
                eStr = sprintf('\n * Column grid count.');   
            end
            
            % reset the group row grid count (if infeasible)
            if mod(pInfo.nRow,pInfo.nRowG) ~= 0
                pInfo.nRowG = 1;
                eStr = sprintf('%s\n * Row grid count.',eStr);
            end
            
            % if there was a row/column grid count that was infeasible,
            % then output a warning message to screen 
            if ~isempty(eStr)
                % sets the full warning string
                eStr0 = ['The following grid group counts are ',...
                         'infeasible and will be reset to 1:'];             
                eStrF = sprintf('%s\n%s',eStr0,eStr);
                
                % outputs the message to screen
                waitfor(msgbox(eStrF,'Infeasible Grid Dimensions','modal'))
            end
                        
            % retrieves the parameter values and updates the editboxes
            [nColG,nRowG] = deal(pInfo.nColG,pInfo.nRowG);
            set(hEditC,'string',num2str(nColG))
            set(hEditR,'string',num2str(nRowG))
        end                 
        
        % sets the grid row/column indices
        [dX,dY] = deal(pInfo.nCol/nColG,pInfo.nRow/nRowG); 
        iR = arrayfun(@(x)((x-1)*dY+(1:dY)),1:nRowG,'un',0);
        iC = arrayfun(@(x)((x-1)*dX+(1:dX)),1:nColG,'un',0);
        
        % resets the group indices (based on the majority group index
        % within each grid region)
        for i = 1:nRowG
            for j = 1:nColG
                iGrpG = arr2vec(pInfo.iGrp(iR{i},iC{j}));
                if all(iGrpG == 0)
                    pInfo.iGrp(iR{i},iC{j}) = 0;
                else                
                    pInfo.iGrp(iR{i},iC{j}) = mode(iGrpG(iGrpG > 0));
                end
            end            
        end
        
        % updates the data sub-struct
        setObjEnable(handles.buttonUpdate,1)
        setDataSubStruct(handles,pInfo)
    end
    
    % updates the configuration axes
    resetConfigAxes(handles)
end

% -------------------------------- %
% --- CONTROL BUTTON CALLBACKS --- %
% -------------------------------- %

% --- Executes on button press in buttonSetRegions.
function buttonSetRegions_Callback(hObject, eventdata, handles)

% global variables
global useAuto

% retrieves the main GUI and sub-image region data structs
useAuto = false;
hFig = handles.output;
hGUI = get(hFig,'hGUI');
iMov = get(hFig,'iMov');

% deletes the automatically detected circular regions (if any present)
hOut = findall(hGUI.imgAxes,'tag','hOuter');
if ~isempty(hOut); delete(hOut); end

% sets up the sub-regions
[iMov.isSet,iMov.iR] = deal(true,[]);
iMov = setupSubRegions(handles,iMov);

% sets up the sub-region acceptance flags
if iMov.is2D
    % case is a 2D expt setup
    iMov.flyok = iMov.pInfo.iGrp > 0;
    
else
    % case is a 1D expt setup
    iGrp = arr2vec(iMov.pInfo.iGrp')';
    nFly = (iGrp>0).*arr2vec(iMov.pInfo.nFly')';    
    
    szF = [max(nFly),1];
    flyok = arrayfun(@(x)(setGroup(1:x,szF)),nFly,'un',0);
    iMov.flyok = cell2mat(flyok);
end

% sets the region acceptance flags
iMov.ok = any(iMov.flyok,1);

% enable the update button, but disable the use automatic region and show
% region menu items
setMenuCheck(setObjEnable(handles.menuUseAuto,'off'),'off');
setMenuCheck(setObjEnable(handles.menuShowInner,'on'),'on');
setObjEnable(handles.buttonUpdate,'on');

% sets the sub-GUI as the top window
uistack(hFig,'top')

% updates the data struct into the GUI
set(hFig,'iMov',iMov);
updateMenuItemProps(handles);

% --- Executes on button press in buttonUpdate.
function buttonUpdate_Callback(hObject, eventdata, handles)

% global variables
global isChange useAuto

% retrieves the main gui handles and sub-movie data struct
hFig = handles.output;
hGUI = get(hFig,'hGUI');
iMov = get(hFig,'iMov');

% removes the x-correlation parameter struct (if it exists)
iMov.Ibg = [];
if isfield(iMov,'xcP')
    iMov = rmfield(iMov,'xcP'); 
end

% if using the automatic detection, disable the button and exit
if iMov.is2D
    if strcmp(get(handles.menuUseAuto,'checked'),'on') || useAuto
        set(hFig,'iMov',iMov)
        setObjEnable(hObject,'off'); 
        return
    end
end

% sets the final sub-region dimensions into the data struct
iMov = setSubRegionDim(iMov,hGUI);
if ~isa(eventdata,'char')
    isChange = true;    
    setObjEnable(hObject,'off');
end

% resets the sub-movie data struct
iMov.pInfo = getDataSubStruct(handles);
set(hFig,'iMov',iMov)

%-------------------------------------------------------------------------%
%                       SUB-REGION OUTLINE FUNCTIONS                      %
%-------------------------------------------------------------------------%

% --- sets up the sub-regions 
function iMov = setupSubRegions(handles,iMov,isSet,isAutoDetect)

% sets the setup flag
if ~exist('isSet','var'); isSet = false; end
if ~exist('isAutoDetect','var'); isAutoDetect = false; end

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
    set(handles.output,'iMov',iMov)    
end

% resets the tube count/use flags (multi-fly tracking only)
if detMltTrkStatus(iMov)
    % case is 
    if isempty(iMov.nFlyR)
        pInfo = getRegionDataStructs(iMov);
        iMov.nTubeR = ones(iMov.nRow,iMov.nCol);
        iMov.nFlyR = pInfo.nFly;        
    end    
end

% removes any previous markers and updates
iMov = createSubRegions(handles,iMov,isSet,isAutoDetect);

% --- creates the subplot regions and line objects
function iMov = createSubRegions(handles,iMov,isSet,isAutoDetect)

% global variables
global xGap yGap pX pY pH pW

% sets the setup flag
if ~exist('isAutoDetect','var'); isAutoDetect = false; end

% ------------------------------------------- %
% --- INITIALISATIONS & MEMORY ALLOCATION --- %
% ------------------------------------------- %

% initialisations
[xGap,yGap] = deal(5,5);
[pX,pY,pH,pW] = deal(zeros(iMov.nCol*iMov.nRow,1));

% retrieves the GUI objects
hFig = handles.output;
hGUI = get(hFig,'hGUI');
hAx = hGUI.imgAxes;
hold(hAx,'on')

% sets the region position vectors
is2DSetup = iMov.is2D;
[rPosS,nApp] = deal(iMov.pos,numel(iMov.pos));

% ------------------------------ %
% --- VERTICAL LINE CREATION --- %
% ------------------------------ %

% memory allocation
xVL = cell(iMov.nCol-1,1);
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
        xVL{i-1} = 0.5*(xR+xL)*[1 1];          
    else
        xVL{i-1} = iMov.posO{i}(1)*[1 1];
    end

    % creates the line object and sets the flags
    hVL{i-1} = imline(hAx,xVL{i-1},yVL);
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
if iMov.nCol > 1
    for j = 1:iMov.nCol
        % sets the x-location of the lines
        switch j
            case 1
                xHL = [iMov.posO{j}(1),xVL{j}(1)];

            case iMov.nCol
                xHL = [xVL{j-1}(1),sum(iMov.posO{j}([1,3]))];

            otherwise
                xHL = [xVL{j-1}(1),xVL{j}(1)];

        end        

        % creates the line objects
        for i = 2:iMov.nRow
            % sets the y-location of the line
            if ~isempty(iMov.pos)
                [iLo,iHi] = deal((i-2)*iMov.nCol+j,(i-1)*iMov.nCol+j);
                yHL = 0.5*(sum(iMov.pos{iLo}([2 4])) + ...
                           sum(iMov.pos{iHi}(2)))*[1 1];
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

% memory allocation
pPos = cell(nApp,1);

% sets the inner rectangle objects for all apparatus
for i = 1:nApp
    % sets the row/column indices
    iCol = mod(i-1,iMov.nCol) + 1;
    iRow = floor((i-1)/iMov.nCol) + 1;
    
    % sets the sub-region limits
    xLimS = getRegionXLim(iMov,hAx,iCol);
    yLimS = getRegionYLim(iMov,hAx,iRow,iCol);

    % adds the ROI fill objects (if already set)
    if isSet
        [ix,iy] = deal([1 1 2 2],[1 2 2 1]);
        hFill = fill(xLimS(ix),yLimS(iy),'r','facealpha',0,'tag',...
                 'hFillROI','linestyle','none','parent',hAx,'UserData',i);
                 
        % if the region is rejected, then set the facecolour to red
        if ~iMov.ok(i)
            set(hFill,'facealpha',0.2)
        end
    end       
    
    % retrieves the new fly count index
    nTubeNw = getSRCount(iMov,i);
    indCol = mod(i-1,length(col))+1;  
    xTubeS0 = rPosS{i}(1)+[0 rPosS{i}(3)];
    xTubeS = repmat(xTubeS0,nTubeNw-1,1)';
    
    % sets the proportional height/width values
    pX(i) = (iMov.pos{i}(1)-iMov.posO{i}(1))/iMov.posO{i}(3);
    pY(i) = (iMov.pos{i}(2)-iMov.posO{i}(2))/iMov.posO{i}(4);
    pW(i) = iMov.pos{i}(3)/iMov.posO{i}(3);
    pH(i) = iMov.pos{i}(4)/iMov.posO{i}(4);   
    
    % creates the new rectangle object
    if is2DSetup
        % calculates the vertical tube region coordinates
        xiN = num2cell(1:nTubeNw)';
        yTube0 = linspace(rPosS{i}(2),sum(rPosS{i}([2,4])),nTubeNw+1)';
        yTubeS = num2cell([yTube0(1:end-1),yTube0(2:end)],2);
        
        % calculates the sub-region outline coordinates
        pPos{i} = cellfun(@(x)([xTubeS0(1)+xGap,x(1)+yGap,...
                     diff(xTubeS0)-2*xGap,diff(x)-2*yGap]),yTubeS,'un',0);
        
        % case is 2D setup expt
        switch iMov.mShape
            case 'Rect'
                % case is using rectangular shapes
                cFcnType = 'imrect';
                hROI = cellfun(@(x)(imrect(hAx,x)),pPos{i},'un',0);
                
            case 'Circ'
                % case is using circular shapes
                cFcnType = 'imellipse';
                
                % creates the circle objects
                hROI = cell(length(pPos{i}),1);
                for j = 1:length(pPos{i})
                    % resets the position of the circle object
                    [szObj,p0] = deal(pPos{i}{j}(3:4),pPos{i}{j}(1:2));                    
                    pPos{i}{j}(3:4) = min(szObj); 
                    pPos{i}{j}(1) = p0(1)+(szObj(1)-pPos{i}{j}(3))/2;
                    pPos{i}{j}(2) = p0(2)+(szObj(2)-pPos{i}{j}(4))/2;
                    
                    % creates the circle object
                    hROI{j} = imellipse(hAx,pPos{i}{j});
                    setFixedAspectRatioMode(hROI{j},true);
                end
        end        
        
        % updates the ROI object properties
        cellfun(@(h,x)(set(h,'tag','hInner','UserData',[i,x])),hROI,xiN);
        
        % if moveable, then set the position callback function
        for j = 1:length(hROI)
            api = iptgetapi(hROI{j});
            api.setColor(col(indCol));
            api.addNewPositionCallback(@roiCallback2D);            
            
            % sets the constraint region for the inner regions
            fcn = makeConstrainToRectFcn(cFcnType,xLimS,yTubeS{j});
            api.setPositionConstraintFcn(fcn);             
        end
        
        % resets the axes properties
        set(hAx,'Layer','Bottom','SortMethod','childorder')
        
    else
        % case is 1D setup expt
        hROI = imrect(hAx,iMov.pos{i});          

        % disables the bottom line of the imrect object
        set(hROI,'tag','hInner','UserData',i);
        setObjVisibility(findobj(hROI,'tag','bottom line'),'off');

        % if moveable, then set the position callback function
        api = iptgetapi(hROI);
        api.setColor(col(indCol));
        
        if isAutoDetect        
            % retrieves the marker object handles
            hObj = findall(hROI);            
            isM = strContains(get(hObj,'Tag'),'marker');
            
            % turns off the object visibility/hit-test
            set(hObj,'hittest','off')
            setObjVisibility(hObj(isM),0)
        else
            % sets the constraint region for the inner regions
            api.addNewPositionCallback(@roiCallback);   
            fcn = makeConstrainToRectFcn('imrect',xLimS,yLimS);
            api.setPositionConstraintFcn(fcn); 
        end

        % creates the individual tube markers        
        yTubeS = rPosS{i}(2) + (rPosS{i}(4)/nTubeNw)*(1:(nTubeNw-1));            
        plot(hAx,xTubeS,repmat(yTubeS,2,1),[col(indCol),'--'],'tag',...
                        sprintf('hTubeEdge%i',i),'UserData','hTube');     
    end
end

% turns the axis hold off
hold(hAx,'off')

% --- removes the sub-regions
function deleteSubRegions(handles)

% retrieves the GUI objects
hGUI = get(handles.output,'hGUI');
if isempty(hGUI); return; end

% removes all the division marker objects
hAx = hGUI.imgAxes;
delete(findobj(hAx,'tag','hOuter'));
delete(findobj(hAx,'tag','hVert'));
delete(findobj(hAx,'tag','hHorz'));
delete(findobj(hAx,'tag','hNum'));
delete(findobj(hAx,'tag','hInner'));
delete(findobj(hAx,'tag','hFillROI'));

% deletes all the tube-markers
delete(findobj(hAx,'UserData','hTube'));

% --- sets up the main sub-window frame --- %
function rPos = setupMainFrameRect(handles,iMov)

% retrieves the GUI objects
isInit = nargin == 1;
hGUI = get(handles.output,'hGUI');
hAx = hGUI.imgAxes;
szFrm = getCurrentImageDim;

% ------------------------------------ %
% --- OUTER RECTANGLE OBJECT SETUP --- %
% ------------------------------------ %

% updates the position of the outside rectangle 
if isInit
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
rPos0 = deal(api.getPosition());

% determines if the outer region is feasible
xL = min(max(1,[rPos0(1),sum(rPos0([1,3]))]),(szFrm(2)-1));
yL = min(max(1,[rPos0(2),sum(rPos0([2,4]))]),(szFrm(1)-1));
rPos = [xL(1),yL(1),[(xL(2)-xL(1)),(yL(2)-yL(1))]+1];

% resets the region if there is a change in size
if ~isequal(rPos,rPos0)
    api.setPosition(rPos);
end

% force the imrect object to be fixed
setResizable(hROI,false);
set(findobj(hROI),'hittest','off')

% sets the constraint function for the rectangle object
fcn = makeConstrainToRectFcn('imrect',rPos(1)+[0 rPos(3)],...
                                      rPos(2)+[0 rPos(4)]);
api.setPositionConstraintFcn(fcn); 

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% ------------------------------------- %
% ---- OBJECT PROPERTIES FUNCTIONS ---- %
% ------------------------------------- %

% --- initialises the object properties
function initObjProps(handles,isInit)

% object handle retrieval
hAx = handles.axesConfig;
hFig = handles.output;
hPanelConfig = handles.panelRegionConfig;

% initialisations
iMov = get(hFig,'iMov');
iData = get(hFig,'iData');
isMltTrk = detMltTrkStatus(iMov);

% sets the tab titles
if isMltTrk
    % case is for multi-tracking
    tStr = {'Region Setup'};
    set(handles.textSRCount,'String','Max Fly Count Per Region: ');
    
    % resets the GUI objects
    dY = 20;
    hPanel = findall(handles.panel1D,'type','uipanel');
    arrayfun(@(x)(resetObjPos(x,'Bottom',-dY,1)),hPanel)
    
    % resets the parameter object dimensions
    hObj = findall(handles.panelConfigInfo1D);
    hObj = hObj(~strcmp(get(hObj,'Type'),'uipanel'));
    resetObjPos(handles.panelConfigInfo1D,'Height',dY,1)
    arrayfun(@(x)(resetObjPos(x,'Bottom',dY,1)),hObj)    
    
    % sets the fixed fly count flag
    if isfield(iMov.bgP.pMulti,'isFixed')
        isFixed = iMov.bgP.pMulti.isFixed;
    else
        [isFixed,iMov.bgP.pMulti.isFixed] = deal(true);
    end
    
    % sets the variable fly count flag
    set(handles.checkVarFlyCount,'Value',~isFixed)
    setObjEnable(handles.editSRCount,isFixed)
    
else
    % case is for normal tracking
    tStr = {'1D Setup','2D Setup'};
end

% -------------------------------- %    
% --- TAB GROUP INITIALISATION --- %
% -------------------------------- %

% retrieves the tab panel object handles
hPanel = arrayfun(@(x)(findall(hPanelConfig,'UserData',x,...
                            'type','uipanel')),1:length(tStr),'un',0);

if isInit
    % sets the object positions
    tabPos = getTabPosVector(handles.panelRegionConfig,[5,-40,-10,40]);

    % creates a tab panel group
    hTabGrp = createTabPanelGroup(handles.panelRegionConfig,1);
    set(hTabGrp,'position',tabPos,'tag','hTabGrp')

    % creates the tab panels
    hTab = cell(length(tStr),1);
    for i = 1:length(tStr)
        % creates the new tab panel
        hTab{i} = createNewTabPanel(...
                           hTabGrp,1,'title',tStr{i},'UserData',i);
        set(hTab{i},'ButtonDownFcn',{@tabSelected,handles})         

        % sets the information panel        
        set(hPanel{i},'Parent',hTab{i});
        resetObjPos(hPanel{i},'Bottom',5)
    end

    % retrieves the table group java object
    jTabGrp = getTabGroupJavaObj(hTabGrp); 
    
    % updates the object arrays into the gui
    set(hFig,'hTab',hTab);
    set(hFig,'hTabGrp',hTabGrp);
    set(hFig,'jTabGrp',jTabGrp);
    
else
    % otherwise, retrieve the table group java object handle
    hTab = get(hFig,'hTab');
    hTabGrp = get(hFig,'hTabGrp');
    jTabGrp = get(hFig,'jTabGrp');
end

% if the regions have already been set, then disable the tab for the setup
% type that is not being used
if iData.isFixed
    % sets the update tab index
    if isMltTrk
        % case is multi-tracking
        iTab = 1;        
    else
        % case is normal tracking
        iTab = 1+iData.is2D;
        jTabGrp.setEnabledAt(~iData.is2D,0)
    end    
    
    % sets the selected tab
    set(hTabGrp,'SelectedTab',hTab{iTab})
else
    arrayfun(@(x)(jTabGrp.setEnabledAt(x-1,1)),1:length(tStr))
end

% updates the selected tab to 2D (if required)
set(hTabGrp,'SelectedTab',hTab{1+iData.is2D});

% ------------------------- %
% --- CONFIG INFO SETUP --- %
% ------------------------- %

% callback function
cbFcn = {@editParaUpdate,handles};
nameFcn = {@tableGroupName,handles};

% sets up the parameter editbox 
for i = 1:length(tStr)
    % retrieves the parameter values
    pVal = getStructField(iData,sprintf('D%i',i));
    
    % retrieves the editbox objects for the panel
    hEdit = findall(hPanel{i},'style','edit');
    for j = 1:length(hEdit)
        % retrieves the parameter values for the current editbox        
        set(hEdit(j),'Callback',cbFcn)
        
        % updates the editbox parameter value (if values exist)
        if ~isempty(pVal)
            pStr = get(hEdit(j),'UserData');
            pValNw = getStructField(pVal,pStr);

            % sets the object value/callback function
            set(hEdit(j),'String',num2str(pValNw));
            if strcmp(pStr,'nGrp')
                setObjEnable(hEdit(j),pVal.nRow*pVal.nCol > 1)
            end
            
            % sets the editbox callback function (initialising only)
            if isInit
                set(hEdit(j),'Callback',cbFcn)
            end
        end
    end
    
    % retrieves the group name table handle
    hPanelGN = findall(hPanel{i},'tag',sprintf('panelGroupNames%iD',i));
    hTableGN = findall(hPanelGN,'type','uitable');      
    
    % initialises the group name table (initialising only)
    if isInit  
        set(hTableGN,'CellEditCallback',nameFcn,'UserData',i,...
                     'ColumnName',{'Group Name'});  
    end
    
    % sets the group name table data/colours (if para are available)
    if ~isempty(pVal)
        tCol = getAllGroupColours(length(pVal.gName),1);
        set(hTableGN,'Data',pVal.gName(:),'BackgroundColor',tCol);
    end
        
    % auto-resizes the table columns    
    if isInit; autoResizeTableColumns(hTableGN); end
end

% initialises the 2D setup specific objects (if para as available)
if ~isempty(iData.D2)
    % sets the radio button value for the corresponding grouping type
    hPanelInfo = handles.panelRegionInfo2D;
    hRadioG = findall(hPanelInfo,'UserData',iData.D2.gType);
    set(hRadioG,'Value',1)

    % updates the 2D info 
    panelRegionInfo2D_SelectionChangedFcn(hRadioG, '1', handles)

    % resets the popup strings/selection index
    pStr = [{'(None)'};iData.D2.gName(:)];
    set(handles.popupCurrentGroup,'String',pStr,'Value',2) 
    
    % creates the context menu
    cmObj = get(hFig,'cmObj');
    if isempty(cmObj)
        cmObj = AxesContextMenu(hFig,hAx,pStr);
        cmObj.setMenuParent(handles.panelAxesConfig);
        cmObj.setCallbackFcn(@updateGroupSelection);
        set(hFig,'cmObj',cmObj); 
    else        
        cmObj.updateMenuLabels(pStr);        
    end
end

% updates the menu item properties
updateMenuItemProps(handles);

% --------------------------------- %    
% --- TABLE DATA INITIALISATION --- %
% --------------------------------- %

% updates the table data
if ~iData.is2D; updateRegionInfoTable(handles); end

% auto-resizes the table columns
if isInit; autoResizeTableColumns(handles.tableRegionInfo1D); end

% ---------------------------------- %    
% --- CONFIG AXES INITIALISATION --- %
% ---------------------------------- %

if isInit
    % calculates the global axes coordinates
    calcAxesGlobalCoords(handles)

    % initialises the plot axis
    set(hAx,'xtick',[],'xticklabel',[],'ytick',[],'yticklabel',[],...
            'box','on');
end

% resets the configuration axes
resetConfigAxes(handles)
    
% --- updates the group table column format
function updateRegionInfoTable(handles)

% updates the group arrays (to account for the row/column counts)
[pInfo,isDiff] = updateGroupArrays(handles);
[nRow,nCol,nFly,iGrp] = deal(pInfo.nRow,pInfo.nCol,pInfo.nFly,pInfo.iGrp);

% updates the data sub-struct (if there was a change)
if isDiff; setDataSubStruct(handles,pInfo,false); end

% sets the table column values
iCol = repmat((1:nCol)',nRow,1);
iRow = cell2mat(arrayfun(@(x)(x*ones(nCol,1)),(1:nRow)','un',0));
[iFly,iGrpT] = deal(arr2vec(nFly'),arr2vec(iGrp'));

% sets the column format names
cForm = {'char','char','char',[]};
cForm{end} = [{' '};pInfo.gName(:)]';

% sets the final table array
DataT = [num2cell([iRow,iCol,iFly]),cForm{end}(1+iGrpT)'];
set(handles.tableRegionInfo1D,'ColumnFormat',cForm,'Data',DataT);

% --- updates the group name table
function updateGroupNameTable(handles)

% initialisations
updateInfo = false;
hFig = handles.output;
iData = get(hFig,'iData');
pInfo = getDataSubStruct(handles);
hTable = findall(hFig,'tag',sprintf('tableGroupNames%iD',1+iData.is2D));

% disable the menu highlight (2D only)
if iData.is2D
    hFig.cmObj.setMenuHighlight(hFig.cmObj.iSel,0);
end

% adds/removes from the group name array
nGrp0 = length(pInfo.gName);
if pInfo.nGrp > nGrp0
    % case is group names are being added to the list 
    iGrpNw = (nGrp0+1):pInfo.nGrp;
    gNameNw = arrayfun(@(x)(sprintf('Group #%i',x)),iGrpNw(:),'un',0);
    pInfo.gName = [pInfo.gName;gNameNw(:)];
    
    % flag that the information update is reqd (2D only)
    if iData.is2D; updateInfo = true; end
else
    % otherwise, remove the names from the list
    pInfo.gName = pInfo.gName(1:pInfo.nGrp);
    pInfo.iGrp(pInfo.iGrp > pInfo.nGrp) = 0;
    updateInfo = true;    
end

% updates the parameter information
setDataSubStruct(handles,pInfo);
if updateInfo
    % updates the current group popup menu
    if iData.is2D
        % resets the popup strings/selection index
        pStr = [{'(None)'};pInfo.gName(:)];
        iSel = min(length(pStr),get(handles.popupCurrentGroup,'Value'));

        % updates the data sub-struct
        setDataSubStruct(handles,updateGroupArrays(handles),true);
        
        % updates the popup string/value
        set(handles.popupCurrentGroup,'String',pStr,'Value',iSel)
        
        % creates the context menu
        hFig.cmObj.updateMenuLabels(pStr);         
    else
        % otherwise, update the region table information
        updateRegionInfoTable(handles)
    end        
end

% updates the table data/background colours
tCol = getAllGroupColours(length(pInfo.gName),1);
set(hTable,'Data',pInfo.gName,'BackgroundColor',tCol);

% --- updates the group selection 
function updateGroupSelection(cmObj)

% global variables
global isMenuOpen

% object handles
hFig = cmObj.hFig;
handles = guidata(hFig);
pInfo = getDataSubStruct(handles,1);
sz = size(pInfo.iGrp);

% retrieves the axes handle
hGUI = get(hFig,'hGUI');
hAx = hGUI.imgAxes;

% retrieves the patch colours
nGrpT = max(max(pInfo.iGrp(:)),pInfo.nGrp);
tCol = getAllGroupColours(nGrpT);

% resets the region to the selected value
if get(handles.radioGridGroup,'Value')
    % case is grid grouping
    dX = pInfo.nCol/pInfo.nColG;
    dY = pInfo.nRow/pInfo.nRowG;
    
    % sets the row/column indices (for the selected group)
    iC = max(0,floor((cmObj.mP0(1)-1)/dX)*dX) + (1:dX);
    iR = max(0,floor((cmObj.mP0(2)-1)/dY)*dY) + (1:dY);
    pInfo.iGrp(iR,iC) = cmObj.iSel - 1;
    
    % sets the indices of the regions that need to be updated
    idx0 = cell2mat(arrayfun(@(ic)...
                (arrayfun(@(ir)(sub2ind(sz,ir,ic)),iR)),iC,'un',0));
    
else
    % case is custom grouping
    iSel0 = pInfo.iGrp(cmObj.mP0(2),cmObj.mP0(1));
    CC = bwconncomp(pInfo.iGrp==iSel0,4);
    
    %
    idx0 = sub2ind(size(pInfo.iGrp),cmObj.mP0(2),cmObj.mP0(1));
    isM = cellfun(@(x)(any(x==idx0)),CC.PixelIdxList);
    pInfo.iGrp(CC.PixelIdxList{isM}) = cmObj.iSel - 1;
end

%
for i = 1:length(idx0)
    % retrieves the handle of the region 
    [pY,pX] = ind2sub(sz,idx0(i));
    hOuter = findall(hAx,'tag','hOuter','UserData',[pX,pY]);
    
    % sets the region visibility (off if no grouping, on otherwise)
    hasGrp = pInfo.iGrp(idx0(i)) > 0;
    setObjVisibility(hOuter,hasGrp)
    
    %
    if hasGrp
        set(hOuter,'FaceColor',tCol(pInfo.iGrp(idx0(i))+1,:));
    end
end

% removes the menu highlight/checkmarks
cmObj.setMenuHighlight(cmObj.iSel,0);
cmObj.updateMenuCheck(0)

% updates the data struct and resets the configuration axes
setDataSubStruct(handles,pInfo,1)
resetConfigAxes(handles)

% resets the open menu flag
isMenuOpen = false;

% --- updates the group panel properties
function updateGroupPanelProps(handles,varargin)

% retrieves the 2D setup data sub-struct
pInfo = getDataSubStruct(handles,true);
multiGrp = (pInfo.nRow*pInfo.nCol) > 1;

% retrieves the sub-panel handles
hPanelI = handles.panelRegionInfo2D;
hPanelGG = handles.panelGridGrouping;
hPanelCG = handles.panelCustomGrouping;

% updates the 2D info panel properties (if required)
if pInfo.nGrp == 1
    setPanelProps(hPanelI,'off')
    setPanelProps(hPanelGG,'off')
    setPanelProps(hPanelCG,'off')
    return
end

% updates the grid grouping panel object's enabled properties
setPanelProps(hPanelI,'on')
setPanelProps(hPanelGG,pInfo.gType==1 && multiGrp);
setPanelProps(hPanelCG,pInfo.gType==2 && multiGrp);

% updates the row/grid objects (if grid grouping is chosen & multi-group)
if pInfo.gType==1 && multiGrp
    setObjEnable(findall(hPanelGG,'UserData','nRowG'),pInfo.nRow>1)
    setObjEnable(findall(hPanelGG,'UserData','nColG'),pInfo.nCol>1)
end

% --- sets the button enabled properties based on the current selections
function setContButtonProps(handles)

% initialisations
pInfo = getDataSubStruct(handles);

% retrieves the field values
[iGrp,nGrp] = deal(pInfo.iGrp,pInfo.nGrp);

% ensures that the group names have been set for at least one region
grpNameSet = all(arrayfun(@(x)(any(iGrp(:)==x)),1:nGrp));

% ensures that at least one region has been set for each row/column
grpSet = pInfo.iGrp > 0;
regionSet = all(any(grpSet,1)) && all(any(grpSet,2));

% updates the enabled properties of the control buttons
canSet = grpNameSet && regionSet;
setObjEnable(handles.buttonSetRegions,canSet)

% --- sets the pattern menu item check mark
function setPatternMenuCheck(handles,Type)

% initialisations
hFig = handles.output;
iData = get(hFig,'iData');

% sets the default input arguments
if ~exist('Type','var')
    Type = getDetectionType(hFig.iMov);
end

% sets the parent menu item
if iData.is2D
    hMenuP = handles.menuDetectSetup2D;
else
    hMenuP = handles.menuDetectSetup1D;
end

% sets the check mark for the corresponding menu item
hMenu = findall(hMenuP,'UserData',Type);
if ~isempty(hMenu)
    setMenuCheck(hMenu,'on')
end

% if successful, then set the ratio check
function resetPatternMenuCheck(hMenu)

% determines the currented checked menu item
hMenuC = findall(get(hMenu,'Parent'),'Checked','on');

% if the current checked item isn't the new one, then reset the checkmarks
if ~isequal(hMenu,hMenuC)
    setMenuCheck(hMenuC,'off');
    setMenuCheck(hMenu,'on');
end

% ------------------------------- %
% ---- CONFIG AXES FUNCTIONS ---- %
% ------------------------------- %

% --- resets the configuration axes with the new information
function resetConfigAxes(handles)

% initialisations
hAx = handles.axesConfig;
hFig = handles.output;
iMov = get(hFig,'iMov');
hGUI = get(hFig,'hGUI');
iData = get(hFig,'iData');
pInfo = getDataSubStruct(handles);
pCol = getAllGroupColours(length(pInfo.gName));
isMTrk = detMltTrkStatus(iMov);
hAxM = hGUI.imgAxes;

% memory allocation and parameters
[hP,iGrp] = deal(zeros(pInfo.nRow,pInfo.nCol),pInfo.iGrp);
[ii,jj,fAlpha] = deal([1,1,2,2,1],[1,2,2,1,1],0.4);
plWid = 0.5/(1+iData.is2D);

% axis limits
xLim = [0,pInfo.nCol];
yLim = [0,pInfo.nRow];

% sets up the region axes
cla(hAx)
axis(hAx,'ij');
set(hAx,'xticklabel',[],'yticklabel',[],'xlim',xLim,...
        'ylim',yLim,'box','on','xcolor','w',...
        'ycolor','w','ticklength',[0,0]);

% turns the axis hold on
hold(hAx,'on')  

% creates the outer region markers
addOuterRegions(hAx,pInfo,xLim,yLim,iData.is2D)        

% creates the group patches for each row/column region
for i = 1:pInfo.nRow
    for j = 1:pInfo.nCol
        % creates the region patch
        [xx,yy] = deal((j-1)+[0,1],(i-1)+[0,1]);
        pColNw = pCol(iGrp(i,j)+1,:);
        hP(i,j) = patch(xx(ii),yy(jj),pColNw,'linewidth',plWid,...
                    'UserData',[i,j],'facealpha',fAlpha,'parent',hAx,...
                    'tag','hRegion');

        % creates the sub-region markers (1D only)
        if ~(iData.is2D || isMTrk)
            dY = 1/pInfo.nFly(i,j);
            for k = 1:(pInfo.nFly(i,j)-1)
                % sets the patch properties/coordinates
                plot(hAx,xx,((i-1)+dY*k)*[1,1],'k','linewidth',0.5);
            end
        end
        
        % updates the patch objects on the main axes (if it exists)
        hOuter = findall(hAxM,'tag','hOuter','UserData',[j,i]);
        if ~isempty(hOuter)
            set(hOuter,'FaceColor',pColNw)
        end
    end
end

% creates the group patches (2D only)
if iData.is2D
    createGroupPatches(handles)
end

% turns the axis hold off
hold(hAx,'off') 

% updates the control button properties
setContButtonProps(handles)

% --- creates the 2D group patches
function createGroupPatches(handles)

% parameters
lWid = 3;

% initialisations
hAx = handles.axesConfig;
pInfo = getDataSubStruct(handles);
isGrid = get(handles.radioGridGroup,'Value');

%
iGrp = pInfo.iGrp;
pCol = getAllGroupColours(length(pInfo.gName));

%
if isGrid
    % sets the number of grid group rows/columns
    if pInfo.nGrp == 1
        % only one group, so use only 1 row/column grouping
        [nColG,nRowG] = deal(1);
    else
        % more than one group, so use the set values
        [nColG,nRowG] = deal(pInfo.nColG,pInfo.nRowG);
    end
    
    % calculates the x/y grid range
    dX = diff(get(hAx,'xlim'))/nColG;
    dY = diff(get(hAx,'ylim'))/nRowG;
    [ii,jj] = deal([1,1,2,2,1],[1,2,2,1,1]);
    
    % case is the sub-regions are in grid formation
    for i = 1:nRowG
        for j = 1:nColG
            % creates the patch object
            [xx,yy] = deal(dX*(j+[-1,0]),dY*(i+[-1,0]));
            pColNw = pCol(pInfo.iGrp(yy(2),xx(2))+1,:);
            fill(xx(ii),yy(jj),pColNw,'Parent',hAx,'tag','hGroup',...
                                       'LineWidth',lWid,'FaceAlpha',0);
        end
    end
else
    %
    szG = size(iGrp);
    
    %
    for i = unique(iGrp(iGrp>0))'
        % determines the groups for the current 
        CC = bwconncomp(iGrp == i,4);
        jGrp = CC.PixelIdxList;
        
        for j = 1:length(jGrp)
            % retrieves the outline of the current group
            B0 = bwfill(setGroup(jGrp{j},szG),'holes');
            B = interp2(double(B0),2,'nearest');
            
            % retrieves the outline coordinates
            P = imfill(boundarymask(padarray(B,[1,1])),'holes');
            Pc0 = bwboundaries(P);
            
            %
            Pc = roundP(Pc0{1}/4);
            Pc = Pc(sum(abs(diff([-[1,1];Pc],[],1)),2)>0,:);
            
            % creates the patch object
            ii = [(1:size(Pc,1)),1];
            fill(Pc(ii,2),Pc(ii,1),pCol(i,:),'Parent',hAx,'tag',...
                                'hGroup','LineWidth',lWid,'FaceAlpha',0);
        end
    end
end

% --- creates the region outlines
function addOuterRegions(hAx,pInfo,xLim,yLim,is2D)

% memory allocation and parameters
lWid = 1 + 2*(~is2D);
[ii,jj] = deal([1,1,2,2,1],[1,2,2,1,1]);

% creates the outline markers
for i = 1:pInfo.nRow
    % plots the row boundary marker (if not the last row)
    if i < pInfo.nRow    
        plot(hAx,xLim,i*[1,1],'k','linewidth',lWid)
    end        

    % creates the sub-region patch objects
    for j = 1:pInfo.nCol
        % plots the column boundary marker (first row only and not 
        % the last column)
        if (j < pInfo.nCol) && (i == 1)
            plot(hAx,j*[1,1],yLim,'k','linewidth',lWid)
        end
    end
end

% plots the outline border
plot(hAx,xLim(ii),yLim(jj),'k','linewidth',3)

% --- runs the selection patch function
function selectionPatchFunc(hFig,hAx,fType,varargin)

% global variables
global p0 isMouseDown

% initialisations
[ii,jj,lWid,fAlpha] = deal([1,1,2,2,1],[1,2,2,1,1],2,0.6);

%
switch fType
    case 'add'
        % patch object properties
        pCol = varargin{1};
        [xx,yy] = deal(p0(1)+[-1,0],p0(2)+[-1,0]);
        
        % creates the patch object
        hSelP = patch(xx(ii),yy(jj),pCol,'Parent',hAx,'tag','hSelP',...
                                 'LineWidth',lWid,'FaceAlpha',fAlpha);
        set(hFig,'hSelP',hSelP);
        
    case 'update'
        % calculates the new coordinates
        pNw = varargin{1};
        xx = [min(pNw(1),p0(1))-1,max(pNw(1),p0(1))];
        yy = [min(pNw(2),p0(2))-1,max(pNw(2),p0(2))];
        
        % updates the patch coordinates
        hSelP = get(hFig,'hSelP');
        try
            set(hSelP,'xData',xx(ii),'yData',yy(jj))
        catch
            isMouseDown = false;
        end
        
    case 'delete'
        % deletes the selection patch object
        hSelP = findall(hAx,'tag','hSelP');
        if ~isempty(hSelP)
            delete(hSelP);
        end
end

% ------------------------------- %
% ---- DATA STRUCT FUNCTIONS ---- %
% ------------------------------- %

% --- initialises the data struct
function iData = initDataStruct(iMov)

% parameters
nFlyMx = 10;

% initialises the common data struct
A = struct('nRow',1,'nCol',1,'nGrp',1,'gName',[],'iGrp',1);
A.gName = {'Group #1'};

% sets the setup dependent sub-fields
B = setStructField(A,{'nFlyMx','nFly'},{nFlyMx,nFlyMx});
C = setStructField(A,{'nRowG','nColG','gType'},{1,1,1});

% data struct initialisations
iData = struct('D1',B,'D2',C,'is2D',false,'isFixed',false);

% --- converts the sub-region data struct to the gui data struct format
function iData = convertDataStruct(iMov)

% data struct initialisations
is2D = is2DCheck(iMov);
[D1,D2] = getRegionDataStructs(iMov);

% resets the arrays 
if detMltTrkStatus(iMov)
    [D1,D2] = deal(D2,[]);
end

% sets the final data struct
iData = struct('D1',D1,'D2',D2,'is2D',is2D,'isFixed',true);

% --- retrieves the data sub struct (dependent on the setup type)
function [pInfo,is2D] = getDataSubStruct(handles,is2D)

% retrieves the data struct
hFig = handles.output;

% sets the 2d flag (if not already given)
if ~exist('is2D','var')    
    is2D = hFig.iData.is2D;
end

% retrieves the sub-struct (depending if the setup dimensionality is given)
pInfo = getStructField(hFig.iData,sprintf('D%i',1+is2D));

% --- updates the data sub struct (dependent on the setup type)
function setDataSubStruct(handles,pInfo,is2D)

% retrieves the data struct
iData = get(handles.output,'iData');

% updates the sub-struct (depending if the setup dimensionality is given)
if exist('is2D','var')
    iData = setStructField(iData,sprintf('D%i',1+is2D),pInfo);
else
    iData = setStructField(iData,sprintf('D%i',1+iData.is2D),pInfo);
end
    
% resets the entire data struct into the gui
set(handles.output,'iData',iData)

% --------------------------------- %
% --- OBJECT CALLBACK FUNCTIONS --- %
% --------------------------------- %

% --- the callback function for moving the vertical seperator
function vertCallback(lPos)

% global variables
global isUpdating
isUpdating = true;

% retrieves the sub-region data struct
hFig = findall(0,'tag','figRegionSetup');
iMov = get(hFig,'iMov');
hGUIH = get(hFig,'hGUI');
handles = guidata(hFig);

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
setObjEnable(handles.buttonUpdate,'on')

% resets the flag
isUpdating = false;

% --- the callback function for moving the horizontal seperator
function horzCallback(lPos)

% global variables
global isUpdating

% determines if an object updating is taking place already
if isUpdating
    % if already updating, then exit the function
    return
else
    % otherwise, flag that updating is occuring
    isUpdating = true;
end

% retr
iVL = get(get(gco,'parent'),'UserData');

% retrieves the sub-region data struct
hFig = findall(0,'tag','figRegionSetup');
iMov = get(hFig,'iMov');
hGUIH = get(hFig,'hGUI');
handles = guidata(hFig);

% updates the position of the inner regions
updateInnerRegions(iMov,hGUIH.imgAxes,iVL,false)
setObjEnable(handles.buttonUpdate,'on')

% resets the flag to false
isUpdating = false;

% --- the callback function for moving the 2D inner tube regions
function roiCallback2D(rPos)

% retrieves the sub-region data object
hFig = findall(0,'tag','figRegionSetup');
srObj = get(hFig,'srObj');

% retrieves the object handle
hROI = get(gco,'Parent');
uData = get(hROI,'UserData');

% enables the update button
hh = guidata(findall(0,'tag','figRegionSetup'));
setObjEnable(hh.buttonUpdate,1)

% add in code here to update region coordinates
%  - fill out autoP field

% determines if running the callback function is valid
if isempty(srObj)
    % sub-region struct has not been set, so exit
    return
elseif ~srObj.isOpen
    % sub-region GUI is closed, so exit
    return
end

% retrieves the marker line objects 
hMarkR = srObj.hMarkR{uData(2),uData(1)};

% initialisation
srObj.isUpdating = true;

% updates the marker object positions
switch srObj.mShape
    case 'Rect'
        % case is rectangular regions

        % rectangle parameters
        [p0nw,W,H] = deal(rPos(1:2),rPos(3),rPos(4));  
        
        % sets up the constraint function
        [xLim,yLim] = deal(p0nw(1)+[0,W],p0nw(2)+[0,H]);
        fcn = makeConstrainToRectFcn('imline',xLim,yLim);

        % resets the vertical marker lines
        pWid = W*cumsum(srObj.pWid{uData(2),uData(1)});         
        for i = find(~cellfun(@isempty,hMarkR(:,1)))'
            % recalculates the new position of the markers
            pNw = [(p0nw(1)+pWid(i)*[1;1]),(p0nw(2)+H*[0;1])];
            
            % resets the object properties
            hAPI = iptgetapi(hMarkR{i,1});              
            hAPI.setPosition(pNw);  
            hAPI.setPositionConstraintFcn(fcn);   
        end
        
        % resets the horizontal marker lines
        pHght = H*cumsum(srObj.pHght{uData(2),uData(1)}); 
        for i = find(~cellfun(@isempty,hMarkR(:,2)))'
            % recalculates the new position of the markers
            pNw = [(p0nw(1)+W*[0;1]),(p0nw(2)+pHght(i)*[1;1])];
            
            % resets the object properties
            hAPI = iptgetapi(hMarkR{i,2});
            hAPI.setPosition(pNw);            
            hAPI.setPositionConstraintFcn(fcn);            
        end
            
    case 'Circ'
        % case is circular regions
        
        % circle parameters
        Rnw = rPos(3)/2;
        p0nw = rPos(1:2)+Rnw;
        
        % resets the marker line objects
        phiP = srObj.pPhi{uData(2),uData(1)};
        for i = 1:length(hMarkR)
            hAPIR = iptgetapi(hMarkR{i});  
            pNw = [p0nw;(p0nw+Rnw*[cos(phiP(i)),sin(phiP(i))])];
            hAPIR.setPosition(pNw);            
        end
end

% resets the update flag
srObj.isUpdating = false;

% --- the callback function for moving the inner tube regions
function roiCallback(rPos,iApp)

% global variables
global iAppInner isUpdating pX pY pW pH

% initialisations
hFig = findall(0,'tag','figRegionSetup');
iMov = get(hFig,'iMov');
handles = guidata(hFig);

% sets the apparatus index
if ~exist('iApp','var')
    iApp = get(get(gco,'Parent'),'UserData');
    if (iscell(iApp)) || (length(iApp) ~= 1)
        iApp = iAppInner; 
    end
end

% retrieves the sub-region data struct
nTube = getSRCount(iMov,iApp);

% resets the locations of the flies
hAx = findall(findobj(0,'tag','figFlyTrack'),'type','axes');
hTube = findobj(hAx,'tag',sprintf('hTubeEdge%i',iApp));
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
    iMov = get(hFig,'iMov');
    hGUIH = get(hFig,'hGUI');
    
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
    setObjEnable(handles.buttonUpdate,'on')
end

% --- updates the position of the inner regions (if the vertical/horizontal
%     line objects are being moved)
function updateInnerRegions(iMov,hAx,iL,isVert)

% global variables
global pH pW pX pY iAppInner

% updates the inner region based on the line being moved
if isVert
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
if iRow == 2
    yLim(1) = iMov.posG(2) + yGapNw;
else
    iL = (iRow-2)*iMov.nCol + iCol;    
    yLim(1) = iMov.pos{iL}(2) + yGapNw;
end

% sets the upper limit
if iRow == iMov.nRow
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
if iCol == 2
    xLim(1) = iMov.posG(1) + xGapNw;
else
    xLim(1) = iMov.posO{iCol-1}(1) + xGapNw;
end

% sets the upper limit
if iCol == iMov.nCol
    xLim(2) = sum(iMov.posG([1 3])) - xGapNw;
else
    xLim(2) = iMov.posO{iCol+1}(1) - xGapNw;
end

% --- returns the x-limits of the sub-region
function xLim = getRegionXLim(iMov,hAx,iCol)

% memory allocation
xLim = zeros(1,2);

% gets the lower limit based on the row count
if iCol == 1
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
if iCol == iMov.nCol
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
if iRow == 1
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
if iRow == iMov.nRow
    % sets the upper limit to be the top
    yLim(2) = sum(iMov.posG([2 4]));
else
    % retrieves the position of the upper line region
    api = iptgetapi(findall(hAx,'tag','hHorz','UserData',[iRow+1,iCol]));
    lPosHi = api.getPosition();
    
    % sets the upper limit
    yLim(2) = lPosHi(1,2);    
end

% --------------------------------- %
% --- REGION PLOTTING FUNCTIONS --- %
% --------------------------------- %

% --- plots the circle regions on the main GUI to enable visualisation
function plotRegionOutlines(handles,iMov,forceUpdate)

% initialisations
hFig = handles.output;
hGUI = get(hFig,'hGUI');
hAx = hGUI.imgAxes;

% retrieves the sub-region and main GUI handles data struct
if ~exist('forceUpdate','var'); forceUpdate = false; end
if ~exist('iMov','var'); iMov = get(hFig,'iMov'); end

% sets the circle visibility based on the checked status
hOut = findall(hAx,'tag','hOuter');
if strcmp(get(handles.menuShowRegion,'checked'),'on') || forceUpdate
    % menu item is checked, so makes the regions visible
    if isempty(hOut)        
        % creates the outlines based on the type
        switch iMov.autoP.Type
            case 'Circle'           
                createCircleOutlines(hAx,iMov);
                
            case 'GeneralR'
                createGeneralOutlines(hAx,iMov);
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
eStr = {'off','on'};
[X,Y] = deal(iMov.autoP.X0,iMov.autoP.Y0);
[XC,YC] = deal(iMov.autoP.XC,iMov.autoP.YC);

% retrieves the group indices
if isfield(iMov,'pInfo')    
    iGrp = iMov.pInfo.iGrp;
else
    iGrp = ones(size(X));
end

% retrieves the patch colours
tCol = getAllGroupColours(max(iGrp(:)));

% loops through all the sub-regions plotting the general objects  
[nRow,nCol] = size(X);
for iCol = 1:nCol
    % creates the new fill objects for each valid region    
    for k = 1:nRow
        % calculates the new coordinates and plots the circle
        pCol = tCol(iGrp(k,iCol)+1,:);
        [xP,yP] = deal(X(k,iCol)+XC,Y(k,iCol)+YC);
        fill(xP,yP,pCol,'tag','hOuter','UserData',[iCol,k],...
                   'facealpha',0.25,'LineWidth',1,'Parent',hAx,...
                   'visible',eStr{1+(iGrp(k,iCol)>0)})
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
eStr = {'off','on'};
[X0,Y0,XC,YC] = deal(aP.X0,aP.Y0,aP.XC,aP.YC);

% retrieves the group indices
if isfield(iMov,'pInfo')    
    iGrp = iMov.pInfo.iGrp;
else
    iGrp = ones(size(X0));
end

% retrieves the patch colours
tCol = getAllGroupColours(max(iGrp(:)));

% loops through all the sub-regions plotting the general objects  
[nRow,nCol] = size(X0);
for iCol = 1:nCol    
    for k = 1:nRow
        pCol = tCol(iGrp(k,iCol)+1,:);
        fill(X0(k,iCol)+XC,Y0(k,iCol)+YC,pCol,'tag','hOuter',...
                   'UserData',[iCol,k],'facealpha',0.25,'LineWidth',1,...
                   'Parent',hAx,'Visible',eStr{1+(iGrp(k,iCol)>0)})
    end
end 

% removes the hold
hold(hAx,'off');

% --------------------------------- %
% ---- MISCELLANEOUS FUNCTIONS ---- %
% --------------------------------- %

% --- initialisation of the subplot data struct
function iMov = initSubPlotStruct(handles,iMov)

% retrieves the main GUI handle struct
hFig = handles.output;
hGUI = get(hFig,'hGUI');
iData = get(hFig,'iData');
pInfo = getDataSubStruct(handles);

% retrieves the axis limits
hAx = hGUI.imgAxes;
[xLim,yLim] = deal(get(hAx,'xlim'),get(hAx,'ylim'));

% sets the 2D flag and sub-region info fields
[iMov.pInfo,iMov.is2D] = deal(pInfo,iData.is2D);

% sets the subplot variables (based on the inputs)
[pG,del] = deal(iMov.posG,5);
if iData.is2D
    [nRow,nCol] = deal(1,size(pInfo.iGrp,2));
else
    [nRow,nCol] = deal(pInfo.nRow,pInfo.nCol);
end

% sets the overall dimensions of the outer regions
[iMov.nRow,iMov.nCol] = deal(nRow,nCol);
[L,B,W,H] = deal(pG(1),pG(2),pG(3)/nCol,pG(4)/nRow);

% if multi-tracking, set the sub-region count to one/region
if detMltTrkStatus(iMov)
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
        
        % creates the text markers (1D setup only)
        if ~iData.is2D
            hText = text(0,0,num2str(k),'parent',hAx,'tag','hNum',...
                        'fontsize',fSize,'color','r','fontweight','bold');   

            hEx = get(hText,'Extent');                     
            set(hText,'position',[L+(j-0.5)*W-(hEx(3)/2) B+(i-0.5)*H 0])
        end
        
        % sets the left/right locations of the sub-window
        PosNw(1) = min(xLim(2),max(xLim(1),L+((j-1)*W+del)));
        PosNw(2) = min(yLim(2),max(yLim(1),B+((i-1)*H+del)));                                               
        PosNw(3) = (W-2*del) + min(0,xLim(2)-(PosNw(1)+(W-2*del)));
        PosNw(4) = (H-2*del) + min(0,yLim(2)-(PosNw(2)+(H-2*del)));      

        % updates the sub-image position vectos
        iMov.pos{k} = PosNw;        
    end
end

% --- updates the group arrays
function [pInfo,isDiff] = updateGroupArrays(handles)

% retrieves the data sub-struct
[pInfo,is2D] = getDataSubStruct(handles);

% retrieves the 1D region information
[nRow,nCol,iGrp] = deal(pInfo.nRow,pInfo.nCol,pInfo.iGrp);
if ~is2D
    [nFly,nFlyMx] = deal(pInfo.nFly,pInfo.nFlyMx);
end

% determines if the fly count array needs to be updated
[nApp,nGrpT] = deal(nRow*nCol,numel(iGrp));
isDiff = nApp ~= nGrpT;
if nApp > nGrpT
    % sets the new mapping index
%     iGrpNw = 0;
    iGrpNw = double((pInfo.nGrp == 1) && is2D);
    
    % elements need to be added to the array
    dszF = [nRow,nCol]-size(iGrp);    
    iGrp = padarray(iGrp,dszF,iGrpNw,'post');       
    if ~is2D; nFly = padarray(nFly,dszF,nFlyMx,'post'); end
    
elseif nApp < nGrpT
    % elements need to be removed from the array    
    iGrp = iGrp(1:nRow,1:nCol); 
    if ~is2D; nFly = nFly(1:nRow,1:nCol); end
end

% updates the data struct (if the arrays changed size)
pInfo.iGrp = iGrp;
if ~is2D; pInfo.nFly = nFly; end

% --- calculates the coordinates of the axes with respect to the global
%     coordinate position system
function calcAxesGlobalCoords(handles)

% global variables
global axPosX axPosY

% retrieves the position vectors for each associated panel/axes
pPosAx = get(handles.panelAxesConfig,'Position');
axPos = get(handles.axesConfig,'Position');

% calculates the global x/y coordinates of the
axPosX = (pPosAx(1)+axPos(1)) + [0,axPos(3)];
axPosY = (pPosAx(2)+axPos(2)) + [0,axPos(4)];

% --- updates the figure/axis properties after automatic detection
function postAutoDetectUpdate(handles,iMov0,iMovNw,isUpdate)

% global variables
global isChange

% initialisation
hFig = handles.output;

% determines if the user decided to update or not
if isUpdate
    % if the user updated the solution, then update the data struct
    isChange = true;
    set(hFig,'iMov',iMovNw);

    % updates the menu properties
    setMenuCheck(setObjEnable(handles.menuUseAuto,'on'),'on')
    setMenuCheck(setObjEnable(handles.menuShowRegion,'on'),'off')
    
    % shows the regions on the main GUI
    menuShowRegion_Callback(handles.menuShowRegion, [], handles)
    
    % global variables
    setObjEnable(handles.buttonUpdate,'on')
else
    % updates the menu properties
    setMenuCheck(setObjEnable(handles.menuUseAuto,'off'),'off')
    setMenuCheck(setObjEnable(handles.menuShowRegion,'off'),'on')    
    
    % shows the tube regions
    menuShowRegion_Callback(handles.menuShowRegion, [], handles)
    
    % resets the sub-regions on the main GUI axes
    setupSubRegions(handles,iMov0,true);    
end

% makes the Window Splitting GUI visible again
setObjVisibility(hFig,'on'); pause(0.05)
figure(hFig)  

% --- initialises the automatic detection algorithm values
function [iMov,hGUI,I] = initAutoDetect(handles)

% prompts the user that the smart region placement only works for circular
% regions (this may change in the future...)
qStr = {'Note that the automatically detected regions are fixed.';...
        'Do you still wish to continue?'};
uChoice = questdlg(qStr,'Automatic Circle Detection','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    [iMov,hGUI,I] = deal([]);
    return    
end        

% retrieves the original sub-region data struct
hFig = handles.output;
hGUI = get(hFig,'hGUI');
iMov0 = get(hFig,'iMov');

% retrieves the main image axes image
I = get(findobj(get(hGUI.imgAxes,'children'),'type','image'),'cdata');

% determines if the sub-region data struct has been set
if isempty(iMov0.iR)
    % if the sub-regions not set, then determine them from the main axes
    buttonUpdate_Callback(handles.buttonUpdate, '1', handles)

    % retrieves the sub-region data struct and 
    iMov = get(hFig,'iMov');
    if isfield(iMov,'autoP'); iMov = rmfield(iMov,'autoP'); end
    set(hFig,'iMov',iMov0);
else
    % otherwise set the original to be the test data struct
    iMov = iMov0; clear iMov0
end
    
% retrieves the region information parameter struct
iMov.pInfo = getDataSubStruct(handles);

% makes the GUI invisible (for the duration of the calculations)
setObjVisibility(hFig,'off'); pause(0.05)

% removes any previous markers and updates from the main GUI axes
deleteSubRegions(handles)

% --- retrieves the region estimate image stack
function I = getRegionEstImageStack(handles,hGUI,iMov)

% global variables
global isCalib

% memory allocation
nFrm = 11;
I = cell(nFrm,1);
hFig = handles.output;

% retrieves the initial image stack
if isCalib
    % case is the user is calibrating the camera
    infoObj = get(hFig,'infoObj');
    for i = 1:nFrm
        I{i} = getsnapshot(infoObj.objIMAQ);
        pause(1);
    end
    
else
    % retrieves the tracking data struct
    iData = get(hGUI.figFlyTrack,'iData');
    
    % case is the tracking from a video
    xi = roundP(linspace(1,iData.nFrm,nFrm));
    for i = 1:length(xi)
        I{i} = getDispImage(iData,iMov,xi(i),false,hGUI);
    end
end
