function varargout = RegionConfig(varargin)
% Last Modified by GUIDE v2.5 17-Mar-2022 12:27:36

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
function RegionConfig_OpeningFcn(hObject, ~, handles, varargin)

% Choose default command line output for RegionConfig
handles.output = hObject;

% global variables
global isMouseDown isMenuOpen p0
global isChange isCalib frmSz0 isUpdating
[isMouseDown,isMenuOpen,isChange,isUpdating] = deal(false);
p0 = [];

% sets the input variables
hGUI = varargin{1};
hPropTrack0 = varargin{2};

% creates a loadbar figure
hLoad = ProgressLoadbar('Initialising Region Setting GUI...');

% sets the data structs into the GUI
hFig = hGUI.figFlyTrack;

% sets the input arguments into the gui
pFldStr = {'hDiff','iMov','iMov0','isMTrk','iData','hSelP','hProp0',...
           'infoObj','cmObj','hTabGrp','jTabGrp','hTab','srObj',...
           'phObj','gridObj','rgObj','axPosX','axPosY','isHT1'};
initObjPropFields(hObject,pFldStr);
addObjProps(hObject,'hGUI',hGUI,'hPropTrack0',hPropTrack0) 

% loads the background parameter struct from the program parameter file
hObject.isHT1 = isHT1Controller(get(hFig,'iData'));
A = load(getParaFileName('ProgPara.mat'));
bgP = DetectPara.resetDetectParaStruct(A.bgP,hObject.isHT1);

% ---------------------------------------- %
% --- FIELD & PROPERTY INITIALISATIONS --- %
% ---------------------------------------- %

% calculates the main axes global coordinates
iMov = get(hFig,'iMov');
[hObject.axPosX,hObject.axPosY] = hFig.calcAxesGlobalCoords(hGUI);
hFig.rgObj.hMenuSR = handles.menuShowRegion;

% resets the flags
hObject.rgObj = get(hFig,'rgObj');
hObject.rgObj.isMain = false;
hObject.rgObj.hButU = handles.buttonUpdate;
hObject.rgObj.hMenuSR = handles.menuShowRegion;

% sets the 2D region flag (if not set)
if ~isfield(iMov,'is2D')
    iMov.is2D = is2DCheck(iMov);
end

% sets the background parameter struct (if not set)
isSet = iMov.isSet;
if ~isfield(iMov,'bgP')
    iMov.bgP = bgP;
elseif isempty(iMov.bgP)
    iMov.bgP = bgP;
end

% sets the manual region shape flag (if not set)
if ~isfield(iMov,'mShape')
    iMov.mShape = 'Circ';
end

% initialises an empty automatic detection parameter field
if ~isfield(iMov,'autoP') || isempty(iMov.autoP)
    iMov.autoP = pos2para(iMov);
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
    
    % sets the configuration information data struct (if not present)
    if ~isfield(hObject.iMov,'pInfo')
        hObject.iMov.pInfo = getDataSubStruct(handles);
        hObject.iMov.is2D = hObject.iData.is2D;
    end   
    
    % sets the 2D flag (if not set)
    if ~isfield(hObject.iMov,'is2D')
        hObject.iMov.is2D = hObject.iData.is2D;
    end
    
    % checks that the 2D regional information field is set properly
    if hObject.iData.is2D
        if ~isempty(hObject.iMov.autoP.X0)
            [hObject.iMov.autoP,isUpdated] = ...
                            backFormatRegionParaStruct(hObject.iMov.autoP);
            setObjEnable(handles.buttonUpdate,isUpdated)
        end
    end
    
    % if the movie has already been set, then set the window properties and
    % disable the set button
    setObjEnable(handles.buttonSetRegions,'on')        
        
    % sets the other object properties
    useSR = false;
    is2D = hObject.iData.is2D;
    setMenuCheck(handles.menuShowRegion,is2D);
    
    % sets check mark for the split region use flag
    if isfield(iMov,'srData') && ~isempty(iMov.srData)
        % sets the checkmark flag
        if isfield(hObject.iMov.srData,'useSR')
            useSR = hObject.iMov.srData.useSR;
        else
            [useSR,hObject.iMov.srData.useSR] = deal(false);
            setObjEnable(handles.buttonUpdate,1);
        end
        
        % updates the menu item checkmark
        setObjEnable(handles.menuConfigSetup,1);
    end
    
    % sets the menu splitting enabled properties (sub-region information
    % must be set and expt must be 2D)
    setObjEnable(handles.menuSplitRegion,hObject.iMov.isSet && is2D)
    setMenuCheck(setObjEnable(handles.menuUseSplit,useSR),useSR);
    
    % draw the sub-region division figures (if not auto-detecting)
    hObject.rgObj.setupRegionConfig(hObject.iMov,true);        
    
    % sets the GUI to the top
    uistack(hObject,'top')      
else
    % otherwise, initialise the data struct
    hObject.iData = initDataStruct(hObject.iMov);
end

% sets the function handles into the gui
addObjProps(hObject,'resetMovQuest',@resetMovQuest,...
                    'resetSubRegionDataStruct',@resetSubRegionDataStruct,...
                    'initSubPlotStruct',@initSubPlotStruct)

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

    % initialises the shape popup menu 
    hCheck = findall(handles.panel1D,'UserData','isFixed');
    
    % initialises the shape popup menu 
    hPopup = findall(handles.panel1D,'UserData','mShape');
    lStr = get(hPopup,'String');
    
    if isfield(hObject.iMov,'pInfo')
        set(hCheck,'Value',hObject.iMov.pInfo.isFixed);    
        set(hPopup,'Value',find(strcmp(lStr,hObject.iMov.pInfo.mShape)));
    else
        set(hCheck,'Value',true);
        set(hPopup,'Value',find(strcmp(lStr,hObject.iData.D1.mShape)));
    end    
    
end

% initialises the object properties
handles = initObjProps(handles,true);

% ------------------------------- %
% --- HOUSE-KEEPING EXERCISES --- %
% ------------------------------- %

% Update handles structure
guidata(hObject, handles);

% closes the loadbar
try close(hLoad); catch; end

% centres the gui to the middle of the string
optFigPosition([hFig,hObject])

% turns off all warnings and makes the gui visible (prevents warning message)
wState = warning('off','all');
setObjVisibility(hObject,'on');
pause(0.05);
warning(wState)

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
    
    % updates the data struct with the new group index
    pInfo = getDataSubStruct(handles);
    pInfo.iGrp(iR,iC) = iSel - 1;
    setDataSubStruct(handles,pInfo);
    
    % deletes the selection patch
    selectionPatchFunc(hFig,hAx,'delete')
    
    % resets the configuration axes
    resetConfigAxes(handles,false)
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

% prompts the user if they wish to proceed
qStr = {'Are you sure you want to reset the current configuration?';...
        'The operation can not be reversed.'};
uChoice = questdlg(qStr,'Reset Configuration?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if the user did not confirm, then exit
    return
end

% object handles
hFig = handles.output;
hFig.iMov.isSet = false;
[hFig.iMov.autoP,hFig.rgObj.iMov.autoP] = deal(pos2para(hFig.iMov));

% deletes the configuration regions
hFig.rgObj.deleteRegionConfig();

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
            if strcmp(get(handles.buttonUpdate,'Enable'),'on')
                buttonUpdate_Callback(handles.buttonUpdate, 1, handles);
            end
            
        case ('No') % case is the user does not want to update
            isChange = false;
            
        otherwise % case is the user cancelled
            return            
    end
end

% loads the movie struct
hFig = handles.figRegionSetup;
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
hFig.rgObj.deleteRegionConfig(1)
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
function menuShowRegion_Callback(hObject, ~, handles)

% toggles the menu item
toggleMenuCheck(hObject)

% plots the region outlines
isShow = strcmp(get(hObject,'Checked'),'on');
handles.output.rgObj.setMarkerVisibility(isShow);

% ----------------------------------------- %
% --- 1D AUTOMATIC DETECTION MENU ITEMS --- %
% ----------------------------------------- %

% -------------------------------------------------------------------------
function menuDetGrid_Callback(hObject, ~, handles)

% field retrieval
isUpdate = false;
hFig = handles.output;
iMov0 = get(hFig,'iMov');

% if the field does exist, then ensure it is correct
hFig.iMov.phInfo = [];
hFig.iMov.bgP = DetectPara.resetDetectParaStruct(hFig.iMov.bgP,hFig.isHT1);

% determines the sub-region dimension configuration
[iMovNw,ok] = setSubRegionDim(hFig.iMov,hFig.hGUI);
if ~ok
    % exits the function if there was an error
    setObjEnable(hObject,'off')
    return
else
    % otherwise, update the data struct
    hFig.iMov = iMovNw;
end

% opens the grid detection tracking parameter gui
gridObj = GridDetect(hFig);
if gridObj.iFlag == 3
    % if the user cancelled, then exit
    hFig.rgObj.setupRegionConfig(iMov0,true);
    return
end

% keep looping until either the user quits or accepts the result
cont = gridObj.iFlag == 1;
while cont
    % runs the 1D auto-detection algorithm
    dObj = DetGridRegion(hFig);    
    if ~dObj.calcOK
        % if user cancelled then exit the loop after closing para gui  
        set(hFig,'iMov',iMov0)
        hFig.rgObj.setupRegionConfig(iMov0,true);
        gridObj.closeGUI();
        return
    end

    % allow user to reset location of regions (either up or down) or 
    % redo the region calculations
    gridObj.checkDetectedSoln(dObj.iMov,dObj.trkObj);
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
    hFig.rgObj.setupRegionConfig(gridObj.iMov,true);
    for iApp = find(gridObj.iMov.ok(:)')
        hFig.rgObj.resetRegionPropDim(gridObj.iMov.pos{iApp},iApp)
    end
end

% sets up the sub-regions for the final time (delete loadbar)
postAutoDetectUpdate(handles,iMov0,gridObj.iMov,isUpdate)
delete(h)

% ----------------------------------------- %
% --- 2D AUTOMATIC DETECTION MENU ITEMS --- %
% ----------------------------------------- %

% -------------------------------------------------------------------------
function menuDetCircle_Callback(hObject, eventdata, handles)

% retrieves the automatic detection algorithm objects
[iMov,hGUI,~] = initAutoDetect(handles);
if isempty(iMov); return; end

% retrieves the region estimate image stack
I = getRegionEstImageStack(handles,hGUI,iMov); 
if isempty(I)
    setObjVisibility(handles.output,'on');
    return
else
    % run the automatic region detection algorithm 
    [iMovNw,R,X,Y,ok] = detImageCircles(I,iMov);
    if ok   
        % if successful, run the circle parameter GUI   
        iMovNw = CircPara(handles,iMovNw,X,Y,R); 
    end
end

% performs the post automatic detection updates
postAutoDetectUpdate(handles,iMov,iMovNw);

% -------------------------------------------------------------------------
function menuDetRect_Callback(hObject, eventdata, handles)

% FINISH ME!
eStr = 'This feature is still under construction...';
waitfor(msgbox(eStr,'Finish Me!','modal'))
return

% retrieves the automatic detection algorithm objects
[iMov,hGUI,~] = initAutoDetect(handles);
if isempty(iMov); return; end

% retrieves the region estimate image stack
I = getRegionEstImageStack(handles,hGUI,iMov); 

% performs the post automatic detection updates
postAutoDetectUpdate(handles,iMov,iMovNw);

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

% performs the post automatic detection updates
postAutoDetectUpdate(handles,iMov,iMovNw);

% -------------------------------------------------------------------------
function menuDetGeneralCust_Callback(hObject, eventdata, handles)

% FINISH ME!
showUnderDevelopmentMsg()

% ----------------------------------- %
% --- REGION SPLITTING MENU ITEMS --- %
% ----------------------------------- %

% -------------------------------------------------------------------------
function menuUseSplit_Callback(hObject, eventdata, handles)

% toggles the checkmark
toggleMenuCheck(hObject)

% updates the check flag
hFig = handles.output;
hFig.iMov.srData.useSR = strcmp(get(hObject,'Checked'),'on');

% enables the update button
setObjEnable(handles.buttonUpdate,1);

% -------------------------------------------------------------------------
function menuConfigSetup_Callback(hObject, eventdata, handles)

% splits the sub-region
hFig = handles.output;

% ensures that the shape f
iMov = get(hFig,'iMov');
if isfield(iMov,'srData') && ~isempty(iMov.srData)
    if isfield(iMov.srData,'Type')
        % resets the sub
        if ~strcmp(iMov.mShape,iMov.srData.Type)
            hFig.iMov.srData = [];
        end
    else
        % case is the type field hasn't be set (force reset)
        hFig.iMov.srData = [];
    end
end

% if there is no split region data, then disable the split menu item
if isfield(hFig.iMov,'srData') && isempty(hFig.iMov.srData)
    setMenuCheck(setObjEnable(handles.menuUseSplit,0),0)
end

% runs the sub-region splitting GUI
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

% initialisations
hFig = handles.output;
iMov = get(hFig,'iMov');
iData = get(hFig,'iData');

% retrieves the boolean flags
isMltTrk = detMltTrkStatus(iMov);
hasSR = isfield(iMov,'srData') && ~isempty(iMov.srData);

% sets the menu item enabled properties
setObjEnable(handles.menuReset,iMov.isSet);
setObjEnable(handles.menuAutoPlace,iMov.isSet && ~isMltTrk);

% updates the split region menu item enabled properties
isFeas = iData.is2D || isMltTrk;
setObjEnable(handles.menuSplitRegion,iMov.isSet && isFeas);
setObjEnable(handles.menuConfigSetup,iMov.isSet && isFeas);
setObjEnable(handles.menuUseSplit,iMov.isSet && hasSR && isFeas );

% if the regions are not set, then exit
if ~iMov.isSet; return; end

% updates the enabled properties of the view items
setObjEnable(handles.menuShowRegion,isFeas);

% updates the enabled properties of the detection menu items
setObjEnable(handles.menuDetectSetup1D,~isFeas);
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
        nwLim = [1,100];
        
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
            setPanelProps(hPanelI,nwVal>0)
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

% --- callback function for the parameter editbox update
function popupParaUpdate(hObj, ~, handles)

% initialisations
hFig = handles.output;
pStr = get(hObj,'UserData');
pInfo = getDataSubStruct(handles);
[lStr,iSel] = deal(get(hObj,'String'),get(hObj,'Value'));

% updates the parameter in the data struct
pInfo = setStructField(pInfo,pStr,lStr{iSel});
setDataSubStruct(handles,pInfo);

% performs further actions based on the parameter
switch pStr
    case 'mShape'
        % updates the shape field
        hFig.iMov.mShape = lStr{iSel}(1:4);
        
        % case is the region shape string
        if hFig.iMov.isSet
            % creates the loadbar figure
            hProg = ProgressLoadbar('Resetting Rectangular Regions...');

            % removes the automatic detection region outlines (if selected)
            hFig.rgObj.iMov.pInfo.Type = lStr{iSel};
            hFig.iMov.pInfo = hFig.rgObj.iMov.pInfo;

            % toggles the shape menu check items
            hFig.rgObj.deleteRegionConfig();
            hFig.iMov = hFig.rgObj.setupRegionConfig(hFig.iMov,1);

            % determines if the split-region information is set
            if isfield(hFig.iMov,'srData') && ~isempty(hFig.iMov.srData)
                % determines if current and split region shape is set
                if strcmp(hFig.iMov.mShape,hFig.iMov.srData.Type)
                    setObjEnable(handles.menuUseSplit,1)
                else
                    hFig.iMov.srData.useSR = false;
                    setMenuCheck(setObjEnable(handles.menuUseSplit,0),0)
                end
            end
            
            % enables the update button
            setObjEnable(handles.buttonUpdate,1)

            % deletes the loadbar figure
            delete(hProg);
        end
end

% --- callback function for the parameter editbox update
function checkParaUpdate(hObj, ~, handles)

% initialisations
% hFig = handles.output;
pStr = get(hObj,'UserData');
pInfo = getDataSubStruct(handles);
isChk = get(hObj,'Value');

% updates the parameter in the data struct
pInfo = setStructField(pInfo,pStr,isChk);
setDataSubStruct(handles,pInfo);

% % removes the automatic detection region outlines (if selected)
% hFig.rgObj.iMov.pInfo = getDataSubStruct(handles);
% hFig.iMov.pInfo = hFig.rgObj.iMov.pInfo;

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
iMov = get(handles.output,'iMov');
pInfo = getDataSubStruct(handles,false);

% retrieves the global column/row indices
tData = get(hObject,'Data');    
cForm = get(hObject,'ColumnFormat');
[iRG,iCG] = deal(tData{iSel(1),1},tData{iSel(1),2});

% updates the parameter based on the 
nwVal = eventdata.NewData;
switch iSel(2)
    case 3
        % case is updating the sub-region count
        if chkEditValue(nwVal,[0,pInfo.nFlyMx],1)
            % if the value is valid, then update the field
            pInfo.nFly(iRG,iCG) = nwVal;    
            
            % if setting the count to zero, then reset the popup menu
            if nwVal == 0
                % resets the group index
                pInfo.iGrp(iRG,iCG) = 0;
                
                % updates the table data
                tData{iSel(1),4} = cForm{end}{1};
                set(hObject,'Data',tData)
            end
        else
            % otherwise, reset to the previous valid value
            tData{iSel(1),iSel(2)} = eventdata.PreviousData;
            set(hObject,'Data',tData)
            
            % exits the function
            return
        end
        
    case 4
        % updates the group index values
        nFlyS = pInfo.nFly(iRG,iCG);
        if (nFlyS == 0) || isnan(nFlyS)
            % if the fly count is set to zero, then reset the group type
            eStr = ['Set a non-zero sub-region count before ',...
                    'setting the group type.'];
            waitfor(msgbox(eStr,'Infeasible Region Configuration','modal'))
                
            % otherwise, reset to the previous valid value
            tData{iSel(1),iSel(2)} = eventdata.PreviousData;
            set(hObject,'Data',tData)
            
            % exits the function
            return            
        else
            % 
            iGrpNw = find(strcmp(cForm{end},nwVal)) - 1;
            pInfo.iGrp(iRG,iCG) = iGrpNw;
        end
        
end

% updates the update button
setObjEnable(handles.buttonUpdate,iMov.isSet)

% updates the data struct into the gui
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

% retrieves the main GUI and sub-image region data structs
hFig = handles.output;
hGUI = get(hFig,'hGUI');
iMov = get(hFig,'iMov');

% deletes the automatically detected circular regions (if any present)
hOut = findall(hGUI.imgAxes,'tag','hOuter');
if ~isempty(hOut); delete(hOut); end

% sets up the sub-regions
iMov.is2D = hFig.iData.is2D;
[iMov.isSet,iMov.iR] = deal(true,[]);

% creates the sub-regions
iMov = hFig.rgObj.setupRegionConfig(iMov);

% enable the update button, but disable the use automatic region and show
% region menu items
setObjEnable(handles.buttonUpdate,'on');

% sets the sub-GUI as the top window
uistack(hFig,'top')

% updates the data struct into the GUI
set(hFig,'iMov',iMov);
set(hFig,'phObj',[]);
updateMenuItemProps(handles);

% --- Executes on button press in buttonUpdate.
function ok = buttonUpdate_Callback(hObject, eventdata, handles)

% global variables
global isChange

% retrieves the main gui handles and sub-movie data struct
hFig = handles.output;
hGUI = get(hFig,'hGUI');
iMov = get(hFig,'iMov');

% removes the x-correlation parameter struct (if it exists)
iMov.Ibg = [];
if isfield(iMov,'xcP')
    iMov = rmfield(iMov,'xcP'); 
end

% % if using the automatic detection, disable the button and exit
% if iMov.is2D
%     if strcmp(get(handles.menuUseAuto,'checked'),'on') || iMov.autoP.isAuto
%         ok = true;
%         set(hFig,'iMov',iMov)
%         setObjEnable(hObject,'off'); 
%         return
%     end
% end

% sets the final sub-region dimensions into the data struct
[iMov,ok] = setSubRegionDim(iMov,hGUI);
if ~ok
    return
elseif ~isa(eventdata,'char')
    isChange = true;    
    setObjEnable(hObject,'off');
end

% creates the background object 
if ~isempty(hGUI.output.bgObj)
    hGUI.output.bgObj.vcObj = [];
end

% resets the sub-movie data struct
iMov.pInfo = getDataSubStruct(handles);
set(hFig,'iMov',iMov)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% ------------------------------------- %
% ---- OBJECT PROPERTIES FUNCTIONS ---- %
% ------------------------------------- %

% --- initialises the object properties
function varargout = initObjProps(handles,isInit)

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
    dY = 50;
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

    % initialises the table objects
    handles = initTableObj(handles);
    
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
cbFcnEdit = {@editParaUpdate,handles};
cbFcnPopup = {@popupParaUpdate,handles};
cbFcnCheck = {@checkParaUpdate,handles};
nameFcn = {@tableGroupName,handles};

% sets up the parameter editbox 
for i = 1:length(tStr)
    % retrieves the parameter values
    pVal = getStructField(iData,sprintf('D%i',i));
    
    % retrieves the editbox objects for the panel
    hEdit = findall(hPanel{i},'style','edit');
    for j = 1:length(hEdit)
        % retrieves the parameter values for the current editbox        
        set(hEdit(j),'Callback',cbFcnEdit)
        
        % updates the editbox parameter value (if values exist)
        if ~isempty(pVal)
            pStr = get(hEdit(j),'UserData');
            pValNw = getStructField(pVal,pStr);

            % sets the object value/callback function
            set(hEdit(j),'String',num2str(pValNw));
            if strcmp(pStr,'nGrp')
                setObjEnable(hEdit(j),pVal.nRow*pVal.nCol > 1)
            end
        end
    end
    
    % initialises the popup objects for the panel
    if strContains(tStr{i},'2D') || isMltTrk
        hPopup = findall(hPanel{i},'style','popupmenu');
        for j = 1:length(hPopup)
            % updates the editbox parameter value (if values exist)
            if ~isempty(pVal)
                % retrieves the parameter string
                pStr = get(hPopup(j),'UserData');
                if ~isempty(pStr)
                    % retrieves the current parameter value
                    pValNw = getStructField(pVal,pStr);

                    % determines the selected index
                    iSel = find(strcmp(get(hPopup(j),'String'),pValNw));
                    if isempty(iSel); iSel = 1; end            

                    % updates the popup-menu properties
                    set(hPopup(j),'Value',iSel,'Callback',cbFcnPopup)
                end
            end
        end
    end
    
    % initialises the popup objects for the panel
    if isMltTrk
        hCheck = findall(hPanel{i},'style','checkbox');
        for j = 1:length(hCheck)
            % updates the editbox parameter value (if values exist)
            if ~isempty(pVal)
                % retrieves the parameter string
                pStr = get(hCheck(j),'UserData');
                if ~isempty(pStr)
                    % retrieves the current parameter value
                    isChk = getStructField(pVal,pStr);          

                    % updates the popup-menu properties
                    set(hCheck(j),'Value',isChk,'Callback',cbFcnCheck)
                end
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
if ~iData.is2D
    updateRegionInfoTable(handles); 
end

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
        
    % sets the output variables
    varargout = {handles};
end

% resets the configuration axes
resetConfigAxes(handles)

% --- initialises the table objects
function handles = initTableObj(handles)

% common parameters
fSz = 10.6666666666667;

% ---------------------------- %
% --- 1D REGION INFO TABLE --- %
% ---------------------------- %

% table properties
cWid = {45, 45, 45, 91};
tabPos = [10 10 245 112];
cEdit = [false false true true];
cName = {'Row #'; 'Col #'; 'Count'; 'Group'};
cbFcnCE = {@tableRegionInfo1D_CellEditCallback,handles};
cbFcnCS = {@tableRegionInfo1D_CellSelectionCallback,handles};

% creates the table object
handles.tableRegionInfo1D = uitable(handles.panelRegionInfo1D,...
    'Units','Pixels','FontUnits','Pixels','Position',tabPos,...
    'ColumnName',cName,'ColumnWidth',cWid,'RowName','',...
    'ColumnEditable',cEdit,'FontSize',fSz,'Tag','tableRegionInfo1D',...
    'CellEditCallback',cbFcnCE,'CellSelectionCallback',cbFcnCS);

% -------------------------------- %
% --- 1D GROUP NAME INFO TABLE --- %
% -------------------------------- %

% table properties
cWid = {197, 'auto'};
cEdit = [true false];
tabPos = [10 10 245 94];
cName = {'Group Name'; ''};

% creates the table object
handles.tableGroupNames1D = uitable(handles.panelGroupNames1D,...
    'Units','Pixels','FontUnits','Pixels','Position',tabPos,...
    'ColumnEditable',cEdit,'Tag','tableGroupNames1D',...
    'ColumnName',cName,'ColumnWidth',cWid,'FontSize',fSz);

% -------------------------------- %
% --- 2D GROUP NAME INFO TABLE --- %
% -------------------------------- %

% creates the table object
handles.tableGroupNames2D = uitable(handles.panelGroupNames2D,...
    'Units','Pixels','FontUnits','Pixels','Position',tabPos,...
    'ColumnEditable',cEdit,'Tag','tableGroupNames2D',...
    'ColumnName',cName,'ColumnWidth',cWid,'FontSize',fSz);

% ------------------------------- %
% --- HOUSE-KEEPING EXERCISES --- %
% ------------------------------- %

% Update handles structure
guidata(handles.figRegionSetup, handles);

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
iFly(isnan(iFly)) = 0;
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
resetConfigAxes(handles,false)

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

% sets the sub-panel enabled flags
useCG = (pInfo.gType==2) && multiGrp;
useGG = (pInfo.gType==1) && (pInfo.nGrp>1) && multiGrp;

% updates the grid grouping panel object's enabled properties
setPanelProps(hPanelI,'on')
setPanelProps(hPanelGG,useGG);
setPanelProps(hPanelCG,useCG);

% updates the row/grid objects (if grid grouping is chosen & multi-group)
if useGG
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

% ------------------------------- %
% ---- CONFIG AXES FUNCTIONS ---- %
% ------------------------------- %

% --- resets the configuration axes with the new information
function resetConfigAxes(handles,resetAxes)

% sets the default input arguments
if ~exist('resetAxes','var'); resetAxes = true; end

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
iGrp = pInfo.iGrp;
[ii,jj,fAlpha] = deal([1,1,2,2,1],[1,2,2,1,1],0.4);
plWid = 0.5/(1+iData.is2D);

% axis limits
xLim = [0,pInfo.nCol];
yLim = [0,pInfo.nRow];

% sets up the region axes
if resetAxes
    % clears the axis 
    cla(hAx)
    axis(hAx,'ij');
    set(hAx,'xticklabel',[],'yticklabel',[],'xlim',xLim,'ylim',yLim,...
        'box','on','xcolor','w','ycolor','w','ticklength',[0,0]);

    % turns the axis hold on
    hold(hAx,'on')  
    
    % creates the outer region markers
    addOuterRegions(hAx,pInfo,xLim,yLim,iData.is2D)

    % creates the group patches for each row/column region
    for i = 1:pInfo.nRow
        for j = 1:pInfo.nCol
            % creates the region patch
            pColNw = pCol(iGrp(i,j)+1,:);
            [xx,yy,uD] = deal((j-1)+[0,1],(i-1)+[0,1],[i,j]);
            patch(xx(ii),yy(jj),pColNw,'linewidth',plWid,'UserData',uD,...
                    'facealpha',fAlpha,'parent',hAx,'tag','hRegion');

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
else
    % determines the grouping indices
    xiG = min(iGrp(:)):max(iGrp(:));
    jGrp = arrayfun(@(x)(find(iGrp==x)),xiG,'un',0);
    
    % findall the region objects
    hP0 = findall(hAx,'tag','hRegion');    
    hold(hAx,'on')      
    
    % resets the face colours within each group
    for i = 1:length(jGrp)
        [iy,ix] = ind2sub([pInfo.nRow,pInfo.nCol],jGrp{i}); 
        hPR = arrayfun(@(x,y)(findobj(hP0,'UserData',[y,x])),ix,iy); 
        set(hPR,'FaceColor',pCol(xiG(i)+1,:)); 
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

% sets the group colours
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
    % initialisations
    [szG,uDG] = deal(size(iGrp),[]);
    
    % removes the original groupings
    hG = findall(hAx,'tag','hGroup');
    if ~isempty(hG)
        isUse = false(size(hG));
        uDG = cell2mat(arrayfun(@(x)(x.UserData),hG,'un',0));
    end
    
    %
    for i = unique(iGrp)'
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
            
            % sets the outline coordinates
            Pc = roundP(Pc0{1}/4);
            Pc = Pc(sum(abs(diff([-[1,1];Pc],[],1)),2)>0,:);
            
            % creates the patch object
            ii = [(1:size(Pc,1)),1];
            if isempty(uDG)
                jj = false;
            else
                jj = all(uDG == [i,j],2);
            end

            if isempty(jj) || ~any(jj)
                fill(Pc(ii,2),Pc(ii,1),pCol(i+1,:),'Parent',hAx,'tag',...
                    'hGroup','LineWidth',lWid,'FaceAlpha',0,...
                    'UserData',[i,j]);
            else
                if sum(jj) > 1
                    % if more than one match, then delete any replicates
                    jj = find(jj,1,'first');
                end
                
                isUse(jj) = true;
                set(hG(jj),'XData',Pc(ii,2),'YData',Pc(ii,1),...
                    'FaceColor',pCol(i+1,:));
            end
        end
    end

    % deletes any extraneous regions
    if exist('isUse','var')
        if any(~isUse)
            delete(hG(~isUse));
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
mShape = 'Circle';

% initialises the common data struct
A = struct('nRow',1,'nCol',1,'nGrp',1,'gName',[],'iGrp',1);
A.gName = {'Group #1'};

% sets the setup dependent sub-fields
B = setStructField(A,{'nFlyMx','nFly'},{nFlyMx,nFlyMx});
C = setStructField(A,{'nRowG','nColG','gType','mShape'},{1,1,1,mShape});
C.pPos = [];

% sets the extra fields for multi-tracking
if detMltTrkStatus(iMov)
    [B.mShape,B.isFixed,B.pPos] = deal('Circle',true,[]);
end

% data struct initialisations
iData = struct('D1',B,'D2',C,'is2D',false,'isFixed',false);

% --- converts the sub-region data struct to the gui data struct format
function iData = convertDataStruct(iMov)

% data struct initialisations
[D1,D2] = getRegionDataStructs(iMov);

% resets the arrays 
if detMltTrkStatus(iMov)
    [D1,D2] = deal(D2,[]);
end

% sets the final data struct
iData = struct('D1',D1,'D2',D2,'is2D',iMov.is2D,'isFixed',true);

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
if iData.is2D || hFig.isMTrk
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

% sets up the sub-region acceptance flags
if iMov.is2D || hFig.isMTrk
    % case is a 2D expt setup
    
    % parameters
    dGrp0 = 5;
    nRow = iMov.pInfo.nRow;
    
    % sets up the acceptance flag array    
    iMov.flyok = iMov.pInfo.iGrp > 0;
    iMov.autoP.pPos = cell(size(iMov.flyok));
    
    % sets up the position vector for each sub-region
    for j = 1:size(iMov.flyok,2)
        % retrieves the region dimensions
        dGrp = dGrp0;
        [L0,B0] = deal(iMov.pos{j}(1),iMov.pos{j}(2));
        [W0,H0] = deal(iMov.pos{j}(3),iMov.pos{j}(4));
        
        % sets the offset dimensions 
        [L,B,W] = deal(L0+dGrp/2,B0+dGrp/2,W0-dGrp);
        H = (H0 - nRow*dGrp)/nRow;        
        
        % if using circle regions, then ensure width and height match
        if strcmp(iMov.autoP.Type,'Circ')
            if W > H
                % case is the width is greater than height
                dW = W - H;
                [L,W] = deal(L+dW/2,W-dW);                
            else
                % case is the height is greater than width
                dH = H - W;
                [B,H] = deal(B+dH/2,H-dH);
                dGrp = dGrp + dH; 
            end
        end
        
        % sets the position vector for each row
        for i = 1:nRow
            y0 = B + (i-1)*(H+dGrp);
            iMov.autoP.pPos{i,j} = [L,y0,W,H];
        end
    end
    
else
    % case is a 1D expt setup
    
    % determines the number of flies in each region grouping
    iGrp = arr2vec(iMov.pInfo.iGrp')';
    nFly = (iGrp>0).*arr2vec(iMov.pInfo.nFly')';    
    
    % sets up the acceptance flag array
    szF = [max(nFly),1];
    flyok = arrayfun(@(x)(setGroup(1:x,szF)),nFly,'un',0);
    iMov.flyok = cell2mat(flyok);
end

% sets the region acceptance flags
iMov.ok = any(iMov.flyok,1);
iMov.pInfo.pPos = iMov.autoP.pPos;

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

% sets the input arguments
if ~exist('isUpdate','var'); isUpdate = ~isempty(iMovNw); end

% determines if the user decided to update or not
if isUpdate
    % sets the region position vectors (2D expts only)
    if iMovNw.is2D
        iMovNw.autoP.pPos = para2pos(iMovNw.autoP);
    end
    
    % if the user updated the solution, then update the data struct
    isChange = true;
    set(hFig,'iMov',iMovNw);    
    
    % updates the menu properties     
    setMenuCheck(setObjEnable(handles.menuShowRegion,'on'),'off')
    
    % shows the regions on the main GUI
    resetRegionShape(handles,iMovNw);
    hFig.rgObj.setupRegionConfig(iMovNw,true);        
    
    % global variables
    setObjEnable(handles.buttonUpdate,'on')
else
    % updates the menu properties
    setObjEnable(handles.menuSplitRegion,hFig.iMov.isSet && iMovNw.is2D)
    setMenuCheck(setObjEnable(handles.menuShowRegion,'off'),'on')    
    
    % shows the tube regions
    menuShowRegion_Callback(handles.menuShowRegion, [], handles)
    
    % resets the sub-regions on the main GUI axes
    hFig.rgObj.setupRegionConfig(iMov0,true);    
end

% makes the Window Splitting GUI visible again
setObjVisibility(hFig,'on'); pause(0.05)
figure(hFig)  

% --- initialises the automatic detection algorithm values
function [iMov,hGUI,I] = initAutoDetect(handles)

% retrieves the original sub-region data struct
hFig = handles.output;
hGUI = get(hFig,'hGUI');
iMov0 = get(hFig,'iMov');

% retrieves the main image axes image
I = get(findobj(get(hGUI.imgAxes,'children'),'type','image'),'cdata');

% determines if the sub-region data struct has been set
if isempty(iMov0.iR)
    % if the sub-regions not set, then determine them from the main axes
    if ~buttonUpdate_Callback(handles.buttonUpdate, '1', handles)
        [iMov,hGUI,I] = deal([]);
        return            
    end
        
    % retrieves the sub-region data struct and 
    iMov = get(hFig,'iMov');    
    set(hFig,'iMov',iMov0);
else
    % otherwise set the original to be the test data struct
    iMov = iMov0;
end
    
% retrieves the region information parameter struct
iMov.pInfo = getDataSubStruct(handles);
iMov.autoP = pos2para(iMov,iMov0.autoP.pPos);

% makes the GUI invisible (for the duration of the calculations)
setObjVisibility(hFig,'off'); pause(0.05)

% removes any previous markers and updates from the main GUI axes
hFig.rgObj.deleteRegionConfig();

% --- retrieves the region estimate image stack
function I = getRegionEstImageStack(handles,hGUI,iMov)

% global variables
global isCalib

% memory allocation
nFrm = 10;
tPause = 0.5;
I = cell(nFrm,1);
hFig = handles.output;

% retrieves the initial image stack
if isCalib
    % creates a waitbar figure
    wStr = {'Capturing Test Image Frames'};
    hProg = ProgBar(wStr,'Test Image Capture');
    
    % case is the user is calibrating the camera
    infoObj = get(hFig,'infoObj');
    for i = 1:nFrm
        % updates the progressbar
        wStrNw = sprintf('%s (%i of %i)',wStr{1},i,nFrm);
        if hProg.Update(1,wStrNw,i/(nFrm+1))
            % if the user cancelled, then exit
            I = []; 
            return
        end        
        
        % reads in the next frame
        I{i} = double(getsnapshot(infoObj.objIMAQ));        
        pause(tPause);
    end
    
    % updates the progressbar
    hProg.Update(1,'Test Image Capture Complete',1);    
    
    % closes the progressbar
    hProg.closeProgBar;
else
    % retrieves the tracking data struct
    iData = get(hGUI.figFlyTrack,'iData');
    
    % case is the tracking from a video
    xi = roundP(linspace(1,iData.nFrm,nFrm));
    for i = 1:length(xi)
        I{i} = double(getDispImage(iData,iMov,xi(i),false,hGUI));
    end
end

% --- fixes the region shape popup item
function resetRegionShape(handles,iMov)

% sets the region shape strings
switch iMov.autoP.Type
    case {'Circle','Rectangle'}
        % case is a circle or rectangle
        mShape = iMov.autoP.Type;

    otherwise
        % case is a general polygon
        mShape = 'Polygon';
end

% resets the popup-menu selection
lStr = get(handles.popupRegionShape,'String');
set(handles.popupRegionShape,'Value',find(strcmp(lStr,mShape)));
