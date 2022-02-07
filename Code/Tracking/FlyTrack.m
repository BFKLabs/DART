function varargout = FlyTrack(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FlyTrack_OpeningFcn, ...
                   'gui_OutputFcn',  @FlyTrack_OutputFcn, ...
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

% --- Executes just before FlyTrack is made visible.
function FlyTrack_OpeningFcn(hObject, eventdata, handles, varargin)

handles.output = hObject;

% global variables
global scrSz tubeSet updateFlag regSz 
global pPos0 axPos0 figPos0
[tubeSet,updateFlag] = deal(false,2); 
pause(0.1); 

% retrieves the regular size of the GUI
wState = warning('off','all');
regSz = get(handles.panelImg,'position');

% turns off all warnings
setObjVisibility(hObject,'off'); pause(0.05);
if ~verLessThan('matlab','9.2') 
    set(hObject,'Renderer','painters')
end

% --------------------------------------------------- %
% --- PARAMETERS & FIGURE POSITION INITIALISATION --- %
% --------------------------------------------------- %

% retrieves the figure position
figPos = get(hObject,'position');
figPosNw = [50 (scrSz(4)-(figPos(4)+50)) figPos(3:4)];
set(setObjVisibility(hObject,'off'),'position',figPosNw); 
pause(0.05);

% global variables
global szDel mainProgDir bufData pAR frmSz0
global isMovChange isDetecting isBatch isCalib isRTPChange
[isMovChange,isDetecting,isBatch,isRTPChange] = deal(false);
[szDel,bufData,pAR] = deal(5,[],2);

% initialses the custom property field string
pFldStr = {'pData','hSolnT','hTube','hMark','hDir','hMainGUI','mObj',...
           'vidTimer','hGUIOpen','reopenGUI','cType','infoObj','hTrack',...
           'isText','iMov','rtP','rtD','iData','ppDef','frmBuffer',...
           'bgObj','prObj','objDACInfo','iStim','hTT','pColF','isTest',...
           'fPosNew','vcObj','mkObj'};
initObjPropFields(hObject,pFldStr);

% ensures the background detection panel is invisible
setObjVisibility(handles.menuEstBG,'off')
setObjVisibility(handles.menuFileBG,'off')
setObjVisibility(handles.panelBGDetect,'off')

% ----------------------------------------------------------- %
% --- FIELD INITIALISATIONS & DIRECTORY STRUCTURE SETTING --- %
% ----------------------------------------------------------- %

% initialisations
cType = 0;

% sets the DART object handles (if provided) and the program directory
switch length(varargin) 
    case 0 
        % case is running full program from command line
        [ProgDefNew,mainProgDir] = deal([],pwd);
        
    case 1 
        % case is running the program from DART main
        
        % sets the input argument and the open GUI (makes invisible)
        hDART = varargin{1};
        set(hObject,'hGUIOpen','figDART')                
                
        % retrieves the program default struct
        ProgDefNew = getappdata(hDART.figDART,'ProgDefNew');
        setObjVisibility(hDART.figDART,'off')             
                
    case {2,3} 
        % case is calibration
        [hGUI,cType] = deal(varargin{1},1);  
        if isempty(hGUI)
            % if handle struct is empty, flag that the directories need to
            % be added (i.e., running test calibration from command line)
            [hObject.reopenGUI,ProgDefNew] = deal(false,[]);
            
        else
            % otherwise, case is running the calibration through the
            % recording GUI
            
            % sets the input argument and the open GUI (makes invisible)
            hObject.reopenGUI = true;  
            set(hObject,'hGUIOpen','figFlyRecord') 
            set(hObject,'hMainGUI',hGUI) 

            % closes the GUI (if running calibration from Fly Record GUI
            setObjVisibility(hGUI.figFlyRecord,'off');

            % retrieves the program default struct
            try
                ProgDefNew = getappdata(hGUI.figFlyRecord,'ProgDefNew');        
            catch
                ProgDefNew = [];
            end
        end
        
    otherwise % case is any other number of input arguments
        % displays an error message
        eStr = ['Error! Incorrect number of input arguments. ',...
                'Exiting Tracking GUI...'];
        waitfor(errordlg(eStr,'Tracking GUI Initialisation Error','modal'))
        
        % deletes the GUI and exits the function
        delete(hObject)
        return
end

% updates the calibration type
set(hObject,'cType',cType)        

% adds the ImageSeg/image processing code directories
if isempty(hObject.hGUIOpen)
    wState = warning('off','all');
    updateSubDirectories(fullfile(mainProgDir,'GUI Code'),'add')
    updateSubDirectories(fullfile(mainProgDir,'Other Code'),'add')
    updateSubDirectories(fullfile(mainProgDir,'Para Files'),'add')
    updateSubDirectories(fullfile(mainProgDir,'External Files'),'add')
    updateSubDirectories(fullfile(mainProgDir,'Common'),'add')
    warning(wState)
end
    
% creates the load bar
if nargin < 2
    h = ProgressLoadbar('Initialising Tracking GUI...');
end

% initialisation of the program data struct
hObject.iData = initDataStruct(handles,ProgDefNew);
hObject.ppDef = hObject.iData.ProgDef;

% initialises the axes properties
calcAxesGlobalCoords(handles)
set(handles.imgAxes,'DrawMode','fast');

% sets all the functions
addObjProps(hObject,'dispImage',@dispImage,...
            'checkFixRatio_Callback',@checkFixRatio_Callback,...
            'setupDivisionFigure',@setupDivisionFigure,...
            'removeDivisionFigure',@removeDivisionFigure,...
            'deleteAllMarkers',@deleteAllMarkers,...
            'initMarkerPlots',@initMarkerPlots,...
            'checkShowTube_Callback',@checkShowTube_Callback,...
            'menuViewProgress_Callback',@menuViewProgress_Callback,...
            'menuOpenSoln_Callback',@menuOpenSoln_Callback,...
            'menuVideoFeed_Callback',@menuVideoFeed_Callback,...
            'menuRTTrack',@menuRTTrack_Callback,...
            'checkLocalView_Callback',@checkLocalView_Callback,...
            'checkSubRegions_Callback',@checkSubRegions_Callback,...
            'checkShowMark_Callback',@checkShowMark_Callback,...
            'checkShowAngle_Callback',@checkShowAngle_Callback,...
            'getMarkerProps',@getMarkerProps,...
            'FirstButtonCallback',@FirstButtonCallback,...
            'LastButtonCallback',@LastButtonCallback,...
            'PrevButtonCallback',@PrevButtonCallback,...
            'NextButtonCallback',@NextButtonCallback,...
            'CountEditCallback',@CountEditCallback,...
            'ImageParaCallback',@ImageParaCallback,...
            'updateAllPlotMarkers',@updateAllPlotMarkers,...
            'updateVideoFeedImage',@updateVideoFeedImage,...
            'postWindowSplit',@postWindowSplit,...
            'menuOptSize_Callback',@menuOptSize_Callback)

% runs the fixed ratio callback function
checkFixRatio_Callback(handles.checkFixRatio, 1, handles)

% sets the image stack executable (if it doesn't exist, then set empty
% array for the name)
imgExe = fullfile(mainProgDir,'Code','Common','Utilities','ImageStack.exe');
if exist(imgExe,'file')
    % initialises the frame update timer object
%     bufData = initFrameBuffer(handles,imgExe);
    bufData = [];    
else
    % otherwise, set an empty data struct
    bufData = [];
end

% initialises the frame buffer timer/cell array
% setappdata(hObject,'frmBuffer',initFrameBuffer(handles))%

% sets the video objects/test flags based on the input arg count
setObjVisibility(hObject,'off'); pause(0.01);
setGUIFontSize(handles)
switch length(varargin)
    case {0,1} 
        % case is the normal tracking (0 input for command-line, 1 thru DART)        
        [isCalib,hObject.isTest] = deal(false);
        hObject.iMov = initMovStruct(hObject.iData);
        
        % initialises the GUI properties
        handles = setTrackGUIProps(handles,'InitGUI'); pause(0.01);
        
%         % sets up the git menus
%         if exist('GitFunc','file')
%             setupGitMenus(hObject)
%         end
        
    case {2,3}
        % case is the full calibration (thru Fly Record)
        isCalib = true;
        
        % creates a loadbar
        h = ProgressLoadbar('Initialising Video Calibration GUI...');        
        figPos0 = get(handles.output,'position');
        pPos0 = get(handles.panelImg,'position');
        axPos0 = get(handles.imgAxes,'position');
        
        % makes the Fly Record GUI invisible
        hMainGUI = hGUI.figFlyRecord;           
        setObjVisibility(hMainGUI,'off'); pause(0.01);                
        
        % retrieves the video object information from the recording GUI
        hObject.infoObj = getappdata(hMainGUI,'infoObj');     
        if ~hObject.infoObj.isTest
            % stops the camera (if running)
            if isrunning(hObject.infoObj.objIMAQ)
                stop(hObject.infoObj.objIMAQ); pause(0.1);
            end
            
            % resets the camera logging mode
            set(hObject.infoObj.objIMAQ,'LoggingMode','Memory');
        end
        
%         % retrieves/sets/updates the scale factor
%         if cType == 1
%             rtP = getappdata(hMainGUI,'rtP');
%             iData.exP.sFac = rtP.trkP.sFac;
%             set(handles.editScaleFactor,'string',num2str(iData.exP.sFac))
%         
%             % retrieves the device controller object handles
%             objDACInfo = getappdata(hMainGUI,'objDACInfo');
%             if isempty(objDACInfo)
%                 setObjEnable(handles.menuRTPara,'off')
%             else
%                 if any(strcmp(objDACInfo.dType,'DAC'))
%                     % if there are DAC devices, then create serial objects 
%                     objDACInfo.Control = createDACObjects(objDACInfo,[]);
%                 end
%             end        
%             
%             setappdata(hObject,'objDACInfo',objDACInfo)        
%             setappdata(hObject,'iStim',getappdata(hMainGUI,'iStim'))
%             setappdata(hObject,'rtP',rtP)
%         end                        

        % sets the sub-movie data struct (initialise if empty)
        hObject.iMov = getappdata(hMainGUI,'iMov');
        if isempty(hObject.iMov)
            hObject.iMov = initMovStruct(hObject.iData);            
        end
        
        % sets the camera logging mode to memory
        if hObject.infoObj.isTest
            Inw = hObject.infoObj.objIMAQ.getCurrentFrame();
        else
            while 1
                try
                    % starts the camera                        
                    start(hObject.infoObj.objIMAQ); pause(0.1);

                    % updates the frame size string
                    Inw = getsnapshot(hObject.infoObj.objIMAQ);
                    stop(hObject.infoObj.objIMAQ); pause(0.1);
                    break
                catch 
                    stop(hObject.infoObj.objIMAQ); pause(0.1);
                end
            end
        end
        
        % retrieves the frame size (flips if required)
        [sz,frmSz0] = deal(size(Inw(:,:,1)));
        if detIfRotImage(hObject.iMov); sz = flip(sz); end
                       
        % sets the image size vector/string
        nwStr = sprintf('%i %s %i',sz(1),char(215),sz(2)); 
        hObject.iData.sz = sz;
        
        % runs the resize function
        if detIfRotImage(hObject.iMov)
            menuOptSize_Callback(handles.menuOptSize,[],handles)
        end
        
        % initialises the GUI properties        
        handles = setTrackGUIProps(handles,'InitGUICalib'); pause(0.01);   
        set(handles.textFrameSizeS,'string',nwStr)    
        
        % creates the preview object
        hObject.prObj = VideoPreview(hObject,0);                
end

% sets the figure resize function
set(hObject,'ResizeFcn',{@figFlyTrack_ResizeFcn,guidata(hObject)})

% centres the figure position
centreFigPosition(hObject);

% clears the main axis
cla(handles.imgAxes)
axis(handles.imgAxes,'off')

% if calibrating, then start the video timer object
if isCalib             
    % enables the window-splitting menu item
    setObjEnable(handles.menuWinsplit,'on')    
    hObject.prObj.startTrackPreview(); pause(0.01);
%     initVideoTimer(handles); pause(0.01);
    
    % initialises the plot markers (if the sub-regions have been set)
    if hObject.iMov.isSet
        setObjEnable(handles.checkShowTube,'on');
        initMarkerPlots(handles,1); pause(0.01)  
    end         
end

% Choose default command line output for FlyTrack
initSelectionProps(handles)
try; delete(h); end

% ensures that the appropriate check boxes/buttons have been inactivated
setObjVisibility(hObject,'on'); pause(0.1);
updateFlag = 0; pause(0.1); 
warning(wState)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes FlyTrack wait for user response (see UIRESUME)
% uiwait(handles.figFlyTrack);
    
% --- Outputs from this function are returned to the command line.
function varargout = FlyTrack_OutputFcn(hObject, eventdata, handles) 

varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes on mouse motion over figure - except title and menu.
function figFlyTrack_WindowButtonMotionFcn(hObject, eventdata, handles)

% object handles
if isfield(handles,'output')
    hFig = handles.output;
    iMov = hFig.iMov;
else
    return
end

% exit if not multi-tracking
if ~iMov.isSet
    return    
elseif ~detMltTrkStatus(iMov)
    return
end

% Modify mouse pointer over axes
mPos = get(hFig,'CurrentPoint');
if isOverAxes(mPos)
    % determines the plot object the mouse is currently hovering over   
    hPlot = findHoverPlotObj(handles);    
    if ~isempty(hPlot) && get(handles.checkShowMark,'Value')
        % retrieves the user data from the plot object
        uData = get(hPlot,'UserData');        
        flyStr = sprintf('Fly #%i',uData(2));
        
        % retrieves the current mouse coordinates
        hAx = handles.imgAxes;        
        mP = get(hAx,'CurrentPoint');        
        
        % determines if the tooltip string marker has been created        
        if isempty(hFig.hTT)
            % if there is no tooltip marker, then create one
            hFig.hTT = createTooltipMarker(hAx,mP(1,1:2),flyStr);
        else
            try
                % updates the tooltip string
                setObjVisibility(hFig.hTT,'on');
                set(hFig.hTT,'Position',mP(1,:),'String',flyStr);
            catch
                % if there was an error, then recreate it
                try; delete(hFig.hTT); end
                hFig.hTT = createTooltipMarker(hAx,mP(1,1:2),flyStr);
            end
        end
        
    else
        % otherwise, set the tooltip to be invisible (if it exists)
        if ~isempty(hFig.hTT)
            setObjVisibility(hFig.hTT,'off');
        end
        
    end
end

% --- creates the plot tooltip marker
function hTT = createTooltipMarker(hAx,mP,flyStr)

% sets up the angle text object
hTT = text(hAx,mP(1),mP(2),flyStr);
set(hTT,'color','k','BackgroundColor','w',...
        'tag','hTT','fontsize',9,'horizontalalignment','center',...
        'EdgeColor','k')

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% ----------------------- %
% --- OPEN MENU ITEMS --- %
% ----------------------- %

% -------------------------------------------------------------------------
function ok = menuOpenMovie_Callback(hObject, eventdata, handles)

% global variables
global isBatch isCalib axPos0 pPos0 figPos0

% initialisations
ok = 1;

% loads the data struct
hFig = handles.output;
[iData0,iData] = deal(get(hFig,'iData'));
[iMov,vidTimer] = deal(get(hFig,'iMov'),get(hFig,'vidTimer'));
hProp0 = getHandleSnapshot(handles);

% sets the solution/movie load flags
if isstruct(eventdata)
    % solution is loaded and file data provided
    [isSolnLoad,setMovie] = deal(true,false);
elseif isa(eventdata,'char')
    % case is solution file is loaded, but user chose to open manually
    [isSolnLoad,setMovie] = deal(true);
else
    % user is opening file from open movie menu item
    [isSolnLoad,setMovie] = deal(false,true);
end

% determines if the user is being prompted, or if the movie files are being
% opened automatically (from the solution file load)
if setMovie
    if ~isempty(vidTimer)
        stop(vidTimer)
        set(handles.menuVideoFeed,'checked','off')
        
%         if cType == 1
%             setObjEnable(handles.menuVideoProps,~isTest)    
%         end
    end
    
    % sets the video type/descriptors
    mType = '*.avi;*.AVI;*.mj2;*.mp4;*.mkv;*.mov';
    mStr = 'Movie Files (*.avi, *.AVI, *.mj2, *.mp4, *.mkv, *.mov';
    
%     % if using windows version 10, then add in .mov videos
%     [~, winVer] = system('ver');
%     if ~strContains(winVer,'Version 10')
%         mType = sprintf('%s;*.mov',mType);
%         mStr = sprintf('%s, *.mov',mStr);
%     end
    
    % user is manually selecting file to open
    [fName,fDir,fIndex] = uigetfile(...
        {mType,sprintf('%s)',mStr)},'Select A File',iData0.ProgDef.DirMov);
    if fIndex == 0
        % if the user cancelled, then exit the function
        ok = false;
        resetHandleSnapshot(hProp0)       
        
        % exits the function
        return
    else
        % determines if the sub-movie data has been set
        if ~isSolnLoad           
            % sets the size field (if not already set)
            if ~isfield(iData,'sz'); iData.sz = [0,0]; end
            
            % if so, then determine if the sub-region data struct has been
            % set and the new/current video dimensions are equal
            szImg = getVideoDimensions(fDir,fName);
            if iMov.isSet && isequal(iData.sz,szImg)
                % if so, ask the user if they would like to keep the same
                % sub-window data. if not, then clear it
                tStr = 'Keep Sub-Window Data';
                uChoice = questdlg(['Do you want to keep the same ',...
                                'sub-window data?'],tStr,'Yes','No','Yes');
                
                if ~strcmp(uChoice,'Yes')
                    % re-initialises the sub-window data struct and 
                    % disables the detect tube button
                    iMov.isSet = false;
                    iMov = initMovStruct(iData);  
                    
                else
                    % sets the file data for the new selected file
                    fData0 = iData0.fData;
                    [iData0.fData.dir,iData0.fData.name] = deal(fDir,fName);

                    % removes the background and resets the statuses    
                    iMov.isSet = true;
                    [iMov.Ibg,iMov.pStats,iMov.autoP] = deal([]);
                    for i = 1:length(iMov.Status)
                        iMov.Status{i}(:) = 0;
                    end
                    
                    [iMov.ok(:),iMov.flyok(:)] = deal(true);
                    set(handles.output,'iMov',iMov);                    

                    % deletes any progress file that may already exist
                    tDir = iData0.ProgDef.TempFile;
                    pFile = fullfile(tDir,'Progress.mat');
                    if exist(pFile,'file')
                        delete(pFile)                            
                    end                

                    % removes the background/classifier fields
                    if isfield(iMov,'xcP'); iMov = rmfield(iMov,'xcP'); end
                    if isfield(iMov,'bgP'); iMov = rmfield(iMov,'bgP'); end
                    
                    % resets the file data struct
                    iData0.fData = fData0;
                end   
            else
                % otherwise, reset the sub-image data struct
                iMov = initMovStruct(iData);             
            end
                        
            % updates the data struct      
            [iMov.vGrp,iData.sfData] = deal([]);
            [iData.stimP,iData.sTrainEx,iData.exP.sFac] = deal([],[],1);                                                               
            
            % resets the movie sub-movie data struct
            set(handles.output,'pData',[],'iMov',iMov,'iData',iData) 
        end
                
        % resets the scale factor value to 1 again
        if ishandle(handles.editScaleFactor)
            set(handles.editScaleFactor,'string',num2str(iData.exP.sFac))
        end
        
        % retrieves the files data struct and sets the directory name
        ldData = dir(fullfile(fDir,fName));
        ldData.dir = fDir;        
    end
else
    % movie file detail already provided, so determine if the matching
    % movie file object can be located
    fileName = fullfile(eventdata.dir,eventdata.name);    
    
    % if the file does not exist, then search for the movie file
    if ~exist(fileName,'file')
        % prompts the user for how they would like to search for the file
        wStr = [{sprintf('Video file "%s" not found.',fileName)};...
            {'How would you like to locate the missing file?'}];
        uChoice = questdlg(wStr,'File Not Found','Automatic Search',...
            'Manual Search','Cancel','Automatic Search');    
        switch uChoice
            case 'Automatic Search' % case is the automatic search
                % creates a loadbar
                h = ProgressLoadbar('Searching For Matching File...');
                
                % searches for the matching movie file
                ldData = fileMatchSearch(eventdata,iData0.ProgDef.DirMov);                                    
                try; delete(h); end
                
                % determines if there was a file match
                if isempty(ldData)
                    % if no match, then manually locate
                    tStr = 'Automatic File Search Failure';
                    wStr = ['Automatic search could not locate ',...
                            'movie file. Manual file location required'];
                    waitfor(warndlg(wStr,tStr,'modal'))
                    ok = menuOpenMovie_Callback(hObject, '1', handles);
                    return
                    
                else
                    % otherwise, a match was made so prompt the user if
                    % they wish to open the file
                    wStr = sprintf(['Matching file found:\n\n    => ',...
                        '%s"\n\nIs this the correct file?'],...
                        fullfile(ldData.dir,ldData.name));
                    uChoice = questdlg(wStr,'Matching Solution Found',...
                        'Yes','No','Yes');                                        
                    if ~strcmp(uChoice,'Yes')
                        % if they do not, then exit the function
                        ok = menuOpenMovie_Callback(hObject, '1', handles);
                        return
                    end
                end
                
            case 'Manual Search' % case is the manual search 
                ok = menuOpenMovie_Callback(hObject, '1', handles);
                return
                
            case 'Cancel' % case is the user cancelled
                ok = false;
                return
        end
    else
        % if the file does exist, then set the file data information
        ldData = dir(fileName);
        ldData.dir = eventdata.dir;
    end 
end

% clears and turns off the axis
if ~isBatch
    axis off; cla        
end

% % resets the snapshot data struct
% if cType > 0
%     set(handles.output,'fPosNew',[])
% end

% loads the image stack. if the user cancelled, then reupdate the image
% with the previous loaded movie (only if a movie has been loaded)
if loadImgData(handles, ldData.name, ldData.dir, setMovie, isSolnLoad)
    % if not loading the solution file but the sub-region struct is set, 
    % then reset the progress data struct       
    iMov = get(handles.output,'iMov');    
    set(handles.output,'bgObj',CalcBG(handles))
    set(findobj(handles.panelAppInfo,'style','checkbox'),'value',0)
    set(findall(handles.panelFlyDetect,'style','checkbox'),'value',0);
    
    % enables the menu items
    setObjEnable(handles.menuOptSize,'on')
    
    % disables the tube regions (if not batch processing)
    if ~isBatch
        % toggles the show tube region markers
        checkShowTube_Callback(handles.checkShowTube, 1, handles)
        
        % closes the solution viewing GUI (if open)
        if ~isempty(handles.output.hSolnT)
            menuViewProgress_Callback(handles.menuViewProgress,[],handles)
        end
    end
    
    if isCalib
        initVideoTimer(handles,false); pause(0.01);     
        setObjEnable(handles.menuVideoFeed,'on')
        setObjEnable(handles.menuWinsplit,'on')        
        menuVideoFeed_Callback(handles.menuVideoFeed, [], handles)  
    end
        
%         figPos0 = get(handles.output,'position');
%         pPos0 = get(handles.panelImg,'position');
%         axPos0 = get(handles.imgAxes,'position');
%     end    

    % determines if the 
    hMenuView = handles.menuViewProgress;
    
    if ~isSolnLoad          
        % closes the progress viewing GUI (if open)        
        if ishandle(hMenuView)
            if strcmp(get(hMenuView,'checked'),'on')
                menuViewProgress_Callback(hMenuView, [], handles)                           
            end
            
            % disables the 
            set(hMenuView,'Checked','off','Enable','off')            
        end

        % resets the progress struct (if the sub-regions have been set)
        if iMov.isSet
            % resets the sub-region data struct
            iMov = resetProgressStruct(handles.output.iData,iMov); 
            set(handles.output,'iMov',iMov);
        end
    end    
    
    % recalculates the axes global coordinates
    calcAxesGlobalCoords(handles)    
    
else
    % if the user cancelled loading, then set the load flag to false
    ok = false;
    
    % resets the data struct (from the original loaded above)
    if ~isSolnLoad
        % resets the solution file directory data and the object properties
        set(handles.output,'iData',iData0);          
        resetHandleSnapshot(hProp0,hFig);
    end      
end

% -------------------------------------------------------------------------
function menuOpenSoln_Callback(hObject, eventdata, handles)

% global variables
global isBatch

% if accessing this function via the menu item, then reset the bp flag
if isa(eventdata,'matlab.ui.eventdata.ActionData')
    isBatch = false;
end

% retrieves the image data/mesh structs
hFig = handles.output;
[iData0,iData] = deal(get(hFig,'iData'));
hProp0 = getHandleSnapshot(handles); 

% sets the 
if ~isstruct(eventdata)
    % if there no data was provided, then prompt the user for the solution
    % file they wish to open
    [fName,fDir,fIndex] = ...
        uigetfile({'*.soln','Solution Files (*.soln)'},...
        'Open Solution Data File',iData.ProgDef.DirSoln);
    if fIndex == 0
        % if the user cancelled, then exit the function
        return
    end
else
    % sets the solution file name/directory
    [fName,fDir] = deal(eventdata.fName,eventdata.fDir);
end
    
% otherwise, retrieve the solution file information struct and set the
% selected file directory name
iData.sfData = dir(fullfile(fDir,fName));
iData.sfData.dir = fDir;

% creates a loadbar
if ~isempty(hObject)
    h = ProgressLoadbar('Loading Solution File...');
end

% opens the solution file
wState = warning('off','all');
solnData = load(fullfile(fDir,fName),'-mat');
warning(wState)
    
% backformats the solution file for changes 
if ~isstruct(eventdata)
    solnData = backFormatSoln(solnData,iData);
end

% retrieves the sub-structs from the solution file
iMov = solnData.iMov;
set(handles.output,'iMov',iMov)

% sets the fly positional data struct depending whether it is empty or not
if isfield(solnData,'pData')
    pData = solnData.pData;
    if ~isempty(pData)    
        % determines the first feasible region/sub-region
        [i0,j0] = getFirstFeasRegion(iMov);
        if detMltTrkStatus(iMov)
            % case is multi-tracking
            nFrm = size(pData.fPos{i0}{j0},1);
        else
            % case is single-tracking
            nFrm = size(pData.fPos{i0}{j0},1);
        end

        % resets the time vector (if required)
        if length(pData.T) > nFrm; pData.T = pData.T(1:nFrm); end        
    end
else
    pData = [];
end 

% retrieve the summary file path from the solution file
sFile = getSummaryFilePath(solnData.fData);
if exist(sFile,'file')
    % loads the summary file
    sData = load(sFile);

    % retrieves the video index/time stamp
    iVid = getVideoFileIndex(solnData.fData.name);        
    tStampV = checkVideoTimeStamps(sData.tStampV,sData.iExpt.Timing.Tp);
    iData.Tv = tStampV{iVid};
    
else
    % otherwise, set an empty time array
    iData.Tv = [];
end

% sets the tube positional data struct depending whether it is empty or not
[iData.stimP,iData.sTrainEx] = getExptStimInfo(sFile,iData.Tv);
setObjEnable(handles.menuStimInfo,detIfHasStim(iData.stimP))

% updates the data struct fields
iData.fData = solnData.fData;
[iData.exP,iData.Frm0] = deal(solnData.exP,solnData.Frm0);
[iData.cMov,iData.nMov] = deal(1,iMov.nRow*iMov.nCol);
set(handles.output,'iData',iData)

% attempts to open the movie file
if menuOpenMovie_Callback(handles.menuOpenMovie,solnData.fData,handles)
    % resets the progress data struct
    iMov = get(hFig,'iMov');
    iData = get(hFig,'iData');
    
    % updates the initial frame
    iData.Frm0 = solnData.Frm0;
    if ~isempty(pData); iData.nFrm = nFrm; end
    set(hFig,'iData',iData);    
    
    % deletes all the current markers (if any)
    deleteAllMarkers(handles)
    initMarkerPlots(handles);
    
    % removes the soln progress GUI (if it is on and not batch processing)
    hView = handles.menuViewProgress;
    if ishandle(hView)
        if strcmp(get(hView,'checked'),'on') && ~isstruct(eventdata)
            menuViewProgress_Callback(handles.menuViewProgress,[],handles)                           
        end 
    end
    
    % otherwise, reset the sub-image stack progress structs
    if iMov.isSet    
        % updates the program data struct
        iMov = resetProgressStruct(iData,iMov);
        set(handles.output,'iMov',iMov);                  
    end
    
    % updates the sub-data structs into the main GUI        
    set(handles.output,'pData',pData)
        
    % sets the marker check box values to off
    set(handles.checkShowTube,'value',0)
    set(handles.checkShowMark,'value',0)
    if ishandle(handles.checkShowAngle)
        set(handles.checkShowAngle,'value',0)
    end
        
    % updates the GUI properties
    setTrackGUIProps(handles,'PostSolnLoad',~isstruct(eventdata))
    
    % updates the object properties   
    if ~isBatch
        setTrackGUIProps(handles,'PostWindowSplit',1)          
        set(handles.checkShowTube,'value',0)
        checkLocalView_Callback(handles.checkLocalView, 1, handles)                    
    end
else
    % resets the solution file directory data and the object properties
    set(handles.output,'iData',iData0);          
    resetHandleSnapshot(hProp0,hFig);    
end

% closes the loadbar (for opening solution file directly only)
if ~isempty(hObject)
    try; delete(h); end
end

% ----------------------- %
% --- SAVE MENU ITEMS --- %
% ----------------------- %

% -------------------------------------------------------------------------
function menuSaveSoln_Callback(hObject, eventdata, handles)

% retrieves the image data/mesh structs
hFig = handles.output;
[iData,a] = deal(get(hFig,'iData'),1);

% sets the output file name
if isfield(iData,'sfData')
    if ~isempty(iData.sfData)
        % sets the name from the loaded file (if already set)
        dStr = fullfile(iData.sfData.dir,iData.sfData.name);
    else
        % otherwise, set the default name
        [~,fNamePart] = fileparts(iData.fData.name);
        dStr = fullfile(iData.ProgDef.DirSoln,[fNamePart,'.soln']);        
    end
else
    % solution file data does not exist, so reset field
    [~,fNamePart] = fileparts(iData.fData.name);
    dStr = fullfile(iData.ProgDef.DirSoln,[fNamePart,'.soln']);            
end

% prompts the user for the movie filename
[fName,fDir,fIndex] = uiputfile({'*.soln','Solution Files (*.soln)'},...
                                 'Save Solution File',dStr);
if fIndex == 0
    % if the user cancelled, then exit the function
    return
else
    % otherwise, retrieve the solution file information struct and set the
    % selected file directory name
    save(fullfile(fDir,fName),'a')
    iData.sfData = dir(fullfile(fDir,fName));
    iData.sfData.dir = fDir;
    set(hFig,'iData',iData);
end

% retrieves the other data structs from the main GUI
[pData,iMov] = deal(get(hFig,'pData'),get(hFig,'iMov'));

% resets the sub-movie fields
[iMov.tempSet,iMov.tempName] = deal(false,[]);

% creates the load bar
h = ProgressLoadbar('Saving Solution File...');

% saves the solution data structs to file
saveSolutionFile(fullfile(fDir,fName),iData,iMov,pData)

% closes the loadbar
try; close(h); end

% ------------------------ %
% --- OTHER MENU ITEMS --- %
% ------------------------ %

% -------------------------------------------------------------------------
function menuConvertVideo_Callback(hObject, eventdata, handles)

% runs the video conversion GUI
ConvertVideo(handles.output.iData.ProgDef);

% -------------------------------------------------------------------------
function menuProgPara_Callback(hObject, eventdata, handles)

% runs the program default GUI
ProgDefaultDef(handles.output,'Tracking');

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

% global variables
global isCalib isMovChange mainProgDir bufData isRTPChange

% initialiations
hFig = handles.output;

% stop the video timer (if calibrating)
if isCalib
    % retrieves the required data structs
    rtP = get(hFig,'rtP');
    iMov = get(hFig,'iMov');    
%     cType = get(hFig,'cType');    
    
    % stops the video object
    if strcmp(get(handles.menuVideoFeed,'checked'),'on')
        menuVideoFeed_Callback(handles.menuVideoFeed, 1, handles)    
    end
end

% prompts the user if they wish to close the tracking gui
uChoice = questdlg('Are you sure you want to close the Tracking GUI?',...
                     'Close Tracking GUI?','Yes','No','Yes');
if strcmp(uChoice,'Yes')  
    % removes the added directories (non-DART mode only)
    hGUIOpen = get(hFig,'hGUIOpen');
    reopenGUI = get(hFig,'reopenGUI');   
    
    % prompts the user if they want to update the sub-region data struct
    % (only if it has been set). if so, then update in the base workspace
    if isCalib
        % retrieves the recording GUI handle
        hMain = get(hFig,'hMainGUI');
        
        % if there was a change, prompt the user if they wish to keep the
        % changes
        if iMov.isSet && (isMovChange || isRTPChange)
            uChoice = questdlg('Do you wish to update the changes?',...
                               'Update Changes?','Yes','No','Yes');
            if strcmp(uChoice,'Yes')
                % otherwise, update the main GUI with the data struct                
                if ~isempty(hMain)
                    setappdata(hMain.output,'iMov',iMov)
                    setappdata(hMain.output,'rtP',rtP)
                end                                       
            end
        end
                
        % if the user set a valid background image, then enable the
        % tracking toggle button and menu item (otherwise, disable)
        if isfield(hFig,'rtObj')
            if ~isempty(hFig.rtObj)
                hFig.rtObj.trackGUIClose()
            end
            
            % determines if the tracking GUI is open (delete if so)
            if ~isempty(hFig.hTrack)
                try; delete(hFig.hTrack); end
            end            
        end        
        
        % determines if the analysis option GUI is open (delete if so)
        hAnalyOpt = findall(0,'tag','figAnalyOpt');    
        if ~isempty(hAnalyOpt)
            try; delete(hAnalyOpt); end
        end        
        
        % if running the camera object, then stop it and reset the logging
        % mode flags
        if ~hFig.isTest                    
            % stops the camera and resets the disklogging properties
            stop(hFig.infoObj.objIMAQ)
            set(hFig.infoObj.objIMAQ,'LoggingMode','Disk');                        
        end 
        
        % retrieves the full DART program default struct directory
        if ~isempty(hMain)
            ProgDefFull = getappdata(findall(0,'tag','figDART'),'ProgDef');
            setappdata(hMain.output,'ProgDefNew',ProgDefFull.Recording)

            % determines if the stimuli connections have been made. if so, 
            % then enable the ability run the experiments
%             if cType == 1
%                 uFunc = getappdata(hMain,'updateExptMenuProps');
%                 uFunc(guidata(hMain))
%             end
        end
    end
    
    % deletes the solution progress tracking GUI (if it exists)
    if ~isempty(hFig.hSolnT)
        try; delete(hFig.hSolnT); end
    end
    
    % stop and deletes the data buffering timer objects
    if ~isempty(bufData)
        % stops and deletes the frame object timer
        try; stop(bufData.tObjChk); end
        try; delete(bufData.tObjChk); end
        
        % stops and deletes the file object timer
        try; stop(bufData.tObjFile); end
        try; delete(bufData.tObjFile); end        
    end
    
    % deletes the figure and exits the program
    delete(hFig)                
    if isempty(hGUIOpen)
        wState = warning('off','all');
        updateSubDirectories(fullfile(mainProgDir,'GUI Code'),'add')
        updateSubDirectories(fullfile(mainProgDir,'Other Code'),'add')
        updateSubDirectories(fullfile(mainProgDir,'Para Files'),'add')
        updateSubDirectories(fullfile(mainProgDir,'External Files'),'add')
        updateSubDirectories(fullfile(mainProgDir,'Common'),'add')
        warning(wState)
    else
        hFig = findall(0,'tag',hGUIOpen,'type','figure');
        switch hGUIOpen
            case 'figFlyRecord'                
                % check to see if opening GUI from Fly Record or the 
                % Combined Experiment GUI
                if reopenGUI
                    % case is from fly record, so reopen GUI
                    setObjVisibility(hFig,'on')    
                end
                
            case 'figDART'
                % otherwise, reopen the GUI                
                setObjVisibility(hFig,'on')
        end
    end        
end

% --------------------------- %
% --- ANALYSIS MENU ITEMS --- %
% --------------------------- %

% -------------------------------------------------------------------------
function menuStimInfo_Callback(hObject, eventdata, handles)

% runs the stimulus
StimInfo(handles)

% -------------------------------------------------------------------------
function menuViewProgress_Callback(hObject, eventdata, handles)

% global variables
global isDetecting isBatch

% creates/deletes the solution tracking GUI (depending on state)
if strcmp(get(hObject,'checked'),'off')
    % creates the load bar
    h = ProgressLoadbar('Initialising Solution Tracking GUI...');
    
    % deletes any previous versions of the solution viewing GUI
    hPrev = findall(0,'tag','figFlySolnView');
    if ~isempty(hPrev); delete(hPrev); end
    
    % creates the solution tracking GUI   
    set(handles.output,'hSolnT',FlySolnView(handles));
    iMov = get(handles.output,'iMov');
    
    % closes the loadbar    
    try; close(h); end
    
    % adds the check to the menu item
    set(hObject,'checked','on') 
    
    % if detecting, then check the show marker
    if isDetecting || isBatch
        setObjEnable(handles.checkShowMark,'on')
        setObjEnable(handles.checkShowTube,'on')
        if iMov.calcPhi; setObjEnable(handles.checkShowAngle,'on'); end
        
        % updates the display image
        dispImage(handles)        
    end
else
    % attempts to delete the solution tracking GUI
    try
        delete(handles.output.hSolnT)
    end    
    
    % removes the check and GUI handle
    set(hObject,'checked','off')
    set(handles.output,'hSolnT',[])
    
    % if detecting, then remove the show marker
    if isDetecting || isBatch
        % updates the GUI object properties
        set(setObjEnable(handles.checkShowMark,'off'),'value',0)
        set(setObjEnable(handles.checkShowTube,'off'),'value',0)
        set(setObjEnable(handles.checkShowAngle,'off'),'value',0)        
        
        % updates the axes image
        dispImage(handles)        
        checkShowTube_Callback(handles.checkShowTube, 1, handles)
    end    
end

% -------------------------------------------------------------------------
function menuWinsplit_Callback(hObject, eventdata, handles)

% global variables
global isCalib

% resets the current axes 
set(handles.output,'CurrentAxes',handles.imgAxes)
hProp0 = getHandleSnapshot(handles);

% stop the video timer (if calibrating)
if ~isCalib     
    % ensures that the first frame is being viewed 
    setTrackGUIProps(handles,'PreWindowSplit')
    pause(0.01);    
end 

% runs the split window sub-GUI
% WindowSplit(handles,hProp0);
RegionConfig(handles,hProp0);

% --- runs the post window split function
function postWindowSplit(handles,iMov,hProp0,isChange)

% global variables
global isCalib isMovChange

% sets the axes focus to the main axis and removes the division figure (if
% already been shown)
hFig = handles.output;
iData = get(hFig,'iData');

% determines if the user set the sub-windows
if isChange           
    % creates the loadbar
    hLoad = ProgressLoadbar('Updating Region Information...');
    
    % otherwise, reset the sub-image stack progress structs
    if isCalib      
        % creates the background object 
        set(handles.output,'bgObj',CalcBG(handles))
        
%         % retrieves the calibration type
%         cType = get(hFig,'cType');         
%         if cType == 1
%             % if calibrating, and is 2D arena, then update the experiment
%             % location reference field to a 2D value        
%             rtP = get(hFig,'rtP'); 
%             if is2DCheck(iMov)
%                 rtP.indSC.ExLoc.pRef = 'Centre'; 
%             end
%         
%             % determines if the activity grouping indices are correct
%             if isempty(rtP.combG.ind)
%                 % initialises the activity groupings (if not set)
%                 rtP.combG.ind = NaN(sum(iMov.ok),1); 
%                 
%             elseif length(rtP.combG.ind) ~= sum(iMov.ok)
%                 % re-initialises the activity groupings (if not matching)
%                 rtP.combG.ind = NaN(sum(iMov.ok),1);
%             end
% 
%             % updates the real-time parameter struct
%             iMov.calcPhi = false;
%             rtP.combG = getCombSubRegionIndices(iMov,rtP);
%             set(handles.output,'rtP',rtP)
% 
%             % enables the real-time parameter menu item
%             setObjEnable(handles.menuRTPara,'on')            
%         end
        
    else
        % otherwise, reset the progress struct
        iMov = resetProgressStruct(iData,iMov);
        if ~is2DCheck(iMov); iMov.calcPhi = false; end
    end         
    
    % reinitialises the background image array
    nTube = getSRCountVec(iMov);
    iMov.flyok = false(max(nTube),length(iMov.iR));
    
    % sets the individual acceptance flags for each group
    for i = 1:length(nTube)
        iMov.Status{i}(:) = 0;
        if iMov.ok(i)
            iMov.flyok(1:nTube(i),i) = true;
        end
    end
    
    % initialises the stats/backgrounds arrays
    iMov.nDS = 1;
    [iMov.pStats,iMov.Ibg] = deal([]);            
    if isfield(iMov,'Nsz'); iMov = rmfield(iMov,'Nsz'); end
    
    % updates the program data struct video
    [iData.initSoln,iData.status,iData.isSave] = deal(1,0,true);
    iData.nMov = iMov.nRow*iMov.nCol;
            
    % updates the data structs within the GUI
    set(handles.output,'iMov',iMov,'iData',iData,'pData',[]);
    
    % updates the object properties
    if isCalib
        % enables the tube checkbox and segmentation para menu item
        set(setObjEnable(handles.checkShowTube,'on'),'value',1)        
        setObjEnable(handles.buttonDetectBackground,'on')
        
        % re-initialises the data structs
        set(handles.output,'fPosNew',[])
                
        % complete clears the axis
        isMovChange = true;
        set(hFig,'CurrentAxes',handles.imgAxes)                   
        
        % re-initialises the plot markers                
        initMarkerPlots(handles); pause(0.01) 
        setTrackGUIProps(handles,'PostWindowSplitCalib')
    else
        % (re)sets the initial plot markers    
        initMarkerPlots(handles); pause(0.01)                    
        setTrackGUIProps(handles,'PostWindowSplit')        
        checkLocalView_Callback(handles.checkLocalView, 1, handles)
    end
    
    % deletes the loadbar
    try; delete(hLoad); end
else    
    % otherwise, reset the original object properties
    if isCalib
        % resets the object properties
        resetHandleSnapshot(hProp0)        
        checkShowTube_Callback(handles.checkShowTube, 1, handles)  
    end
end
    
% -------------------------------------------------------------------------
function menuManualReseg_Callback(hObject, eventdata, handles)

% turns off the tube regions (if they are on)
if get(handles.checkShowTube,'value')
    set(handles.checkShowTube,'value',false);
    checkShowTube_Callback(handles.checkShowTube, 1, handles)
end

% runs the manual resegmentation GUI
ManualResegment(handles)

% -------------------------------------------------------------------------
function menuSetupBatch_Callback(hObject, eventdata, handles)

% % global variables
% global isBatch

% prompts the user if they have set the experiment parameters correctly
wStr = {'Have you set all experiment parameters correctly?';...
        'These parameters will be used for all segmented movies'};
uChoice = questdlg(wStr,'Set Parameters Correctly?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if the user chose no, then exit
    return
end

% creates the batch processing object
bpObj = SingleTrackBP(handles,false);
if ~isempty(bpObj.bData)
    % if the user chose to continue, then start the batch processing
    bpObj.startBatchProcessing()    
end

% -------------------------------------------------------------------------
function menuMultiBatch_Callback(hObject, eventdata, handles)

% creates the batch processing object
bpObj = SingleTrackBP(handles,true);
if ~isempty(bpObj.bData)
    % if the user chose to continue, then start the batch processing
    bpObj.startBatchProcessing()    
end

% -------------------------------------------------------------------------
function menuSplitVideo_Callback(hObject, eventdata, handles)

% runs the video splitting GUI
hFig = handles.output;
[vGrp,isChange] = VideoSplit(hFig);

% if there was a change, then update the program data struct
if isChange
    hFig.iMov.vGrp = vGrp;
end

% -------------------------------------------------------------------------
function menuAnalyOpt_Callback(hObject, eventdata, handles)

% % if the tube regions are shown, then hide them
% if get(handles.checkShowTube,'value')
%     set(handles.checkShowTube,'value',0)
%     checkShowTube_Callback(handles.checkShowTube, 1, handles)    
% end
% 
% % if the tube markers are shown, then hide them
% if get(handles.checkShowMark,'value')
%     set(handles.checkShowMark,'value',0)
%     set(handles.checkShowAngle,'value',0)
%     checkShowMark_Callback(handles.checkShowMark, [], handles)
% end

% runs the tracking analysis options
AnalyOpt(handles.output)

% ----------------------- %
% --- VIEW MENU ITEMS --- %
% ----------------------- %

% -------------------------------------------------------------------------
function menuCorrectTrans_Callback(hObject, eventdata, handles)

switch get(hObject,'Checked')
    case 'off'
        % case is turning off the image correction
        set(hObject,'Checked','on')
        
    case 'on'
        % case is turning off the image correction
        set(hObject,'Checked','off')
end

% updates the image
dispImage(handles);

% -------------------------------------------------------------------------
function menuOptSize_Callback(hObject, eventdata, handles)

% global variables
global updateFlag

% initialisations
[Y0,hFig] = deal(10,handles.output);
fPos = get(hFig,'position');
pPos = get(handles.panelOuter,'position');

% recalculates the 
pAR = hFig.iData.sz(2)/hFig.iData.sz(1);
pPosAx = [Y0+sum(pPos([1,3])),Y0,ceil(pAR*pPos(4)),pPos(4)];

% recalculates the figure width/height
fPos(3) = sum(pPosAx([1,3]))+Y0;
fPos(4) = sum(pPosAx([2,4]))+Y0;

% resets the image panel/axes positions
set(handles.panelImg,'Position',pPosAx)
set(handles.imgAxes,'Position',[Y0*[1,1],pPosAx(3:4)-2*Y0]);
resetObjPos(handles.panelOuter,'Bottom',Y0)

% recalculates the axes global coordinates
calcAxesGlobalCoords(handles)

% update the figure position
updateFlag = 2;
set(hFig,'Position',fPos)
resetFigPosition(hFig)
updateFlag = 0;

% -------------------------------------------------------------------------
function menuMaxSize_Callback(hObject, eventdata, handles)

% global variables
global updateFlag
updateFlag = 2;

% initialisations
hFig = handles.output;

% retrieves the java-frame object
wState = warning('off','all');
jFrame = get(handle(hFig),'JavaFrame');
jFrame.setMaximized(true);

% update the figure position
fPos = get(hFig,'Position');
resetFigSize(handles,fPos)

% resets the warnings
warning(wState);
updateFlag = 0;

% -------------------------------------------------------------------------
function menuAllowResize_Callback(hObject, eventdata, handles)

% initialisations
vStr = {'off','on'};
isChecked = strcmp(get(hObject,'Checked'),'on');
iData = get(handles.output,'iData');

% resets the menu iterm properties
set(hObject,'Checked',vStr{~isChecked+1})
setObjEnable(handles.menuMaxSize,~isChecked)
setObjEnable(handles.menuOptSize,~isChecked && isfield(iData,'sz'))

% resets the resize flag
set(handles.output,'Resize',vStr{~isChecked+1})

% --------------------------- %
% --- ANALYSIS MENU ITEMS --- %
% --------------------------- %

% -------------------------------------------------------------------------
function menuVideoFeed_Callback(hObject, eventdata, handles)

% retrieves the video timer object
hFig = handles.output;
prObj = get(hFig,'prObj');
infoObj = get(hFig,'infoObj');
% iMov = get(hFig,'iMov');
% cType = get(hFig,'cType');
% isTest = get(hFig,'isTest');
% vidTimer = get(hFig,'vidTimer');

% toggles the video object start/stop status
if strcmp(get(hObject,'checked'),'on')
    % turns off the video preview
    prObj.stopTrackPreview()
    
    % updates the menu properties
    set(hObject,'checked','off')        
    setObjEnable(handles.menuVideoProps,~infoObj.isTest)    
    
    % if the tracking GUI is open, then delete it    
    if ~isempty(hFig.hTrack)
        try; delete(hFig.hTrack); end
    end     
    
%     % if the RT tracking is running, then stop it
%     if cType == 1
%         setObjEnable(handles.menuRTTrack,'off')
%         if strcmp(get(handles.menuRTTrack,'checked'),'on')
%             menuRTTrack_Callback(handles.menuRTTrack, eventdata, handles)
%         end
%     end
else    
    % timer object is off, so turn on video timer
    set(hObject,'checked','on')           
        
    % turns off the video preview
    prObj.startTrackPreview()

%     %
%     setObjEnable(handles.menuRTTrack,initDetectCompleted(iMov))     
    
%     % starts the videos object
%     if ~isempty(vidTimer)
%         start(vidTimer); 
%     end    
end

% -------------------------------------------------------------------------
function menuVideoProps_Callback(hObject, eventdata, handles)

% runs the video parameter sub-GUI
VideoPara(handles.output.hMainGUI)

% -------------------------------------------------------------------------
function menuRTTrack_Callback(hObject, eventdata, handles)

% global variables
global is2D tLastFeed stimTS iEventS tRTStart objDRT

% retrieves the sub-region data and re-initialises the position data struct
hFig = handles.output;
rtP = get(hFig,'rtP');
rtD = get(hFig,'rtD');
iMov = get(hFig,'iMov');
iStim = get(hFig,'iStim');
dInfo = get(hFig,'objDACInfo');
isChecked = strcmp(get(hObject,'checked'),'on');

% determines what dimensionality the experimental regions are
is2D = is2DCheck(iMov);

% updates the properties based on the menu's check mark status
if isChecked    
    % deletes the tracking stats GUI (if it tracking was being performed)
    if ~isempty(hFig.hTrack)        
        try; delete(hFig.hTrack); end
        set(hFig,'hTrack',[])
    end     
    
    % removes the check mark from the menu item
    set(hObject,'checked','off')
    setObjEnable(handles.textScaleFactor,'on')
    setObjEnable(handles.editScaleFactor,'on')
    set(setObjEnable(handles.checkShowMark,'off'),'value',0)
    
    % resets the fly position array to NaNs
    nTube = getSRCountMax(iMov);
    fPosNaN = repmat({NaN(nTube,2)},1,length(iMov.iR));
    set(handles.output,'fPosNew',fPosNaN);
        
    % check to see that the devices have all been turned off correctly
    forceStopDevice(handles.output)
        
    % deletes any experiment location markers (if any)
    hExLoc = findall(handles.imgAxes,'tag','hExLoc');
    if ~isempty(hExLoc); delete(hExLoc); end    
    
    % prompts the user if they want to output the tracking data
    outputRTTrackData(rtD); 
else    
    % initialises the video feed timer
    tic; 
    [tLastFeed,tRTStart] = deal(toc,now);    
    
    % it stimulating (for single pulse signals) then allocate memory for
    % the stimuli event time/index arrays
    if ~isempty(rtP.Stim)
        if strcmp(rtP.Stim.sType,'Single')
            % determines the number of channel used for stimulation
            if any(strcmp(dInfo.dType,'DAC'))
                % case is the DAC device is being used
                nCh = length(unique(iStim.ID(:,1)));
                objDRT = cell(nCh,1);                               
            else
                % case is the Serial Controller is being used
                nCh = size(rtP.Stim.C2T,1);                
            end
            
            % memory allocation
            [stimTS,iEventS] = deal(cell(nCh,1),zeros(nCh,1));
        end
    end
    
    % sets the show marker checkbox to true        
    set(handles.output,'rtD',initRTDataStruct(iMov,rtP))
    
    % updates the properties of the other GUI objects
    setObjEnable(handles.editScaleFactor,'off')
    setObjEnable(handles.textScaleFactor,'off')
    set(setObjEnable(handles.checkShowMark,'on'),'value',1)    
    set(handles.menuRTTrack,'checked','on')
    
    % opens the real-time tracking stats GUI
    set(handles.output,'hTrack',TrackingStats(handles.output))
    set(hFig,'CurrentAxes',handles.imgAxes);
    
end  

% -------------------------------------------------------------------------
function menuRTPara_Callback(hObject, eventdata, handles)

% turns off the video feed (if it is on)
if strcmp(get(handles.menuVideoFeed,'checked'),'on')
    menuVideoFeed_Callback(handles.menuVideoFeed, [], handles)
end

% runs the real-time tracking parameter GUI
TrackingPara(handles.output)

%-------------------------------------------------------------------------%
%                        OBJECT CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ----------------------------- %
% --- MAIN FIGURE CALLBACKS --- %
% ----------------------------- %

% --- Executes when figFlyTrack is resized.
function figFlyTrack_ResizeFcn(hObject, eventdata, handles)

% global variables
global updateFlag uTime

% resets the timer
uTime = tic;

% dont allow any update (if flag is set to 2)
if updateFlag ~= 0
    return
else
    updateFlag = 2;
    while toc(uTime) < 0.5
        java.lang.Thread.sleep(10);
    end
end

% parameters
[pPos,Y0] = deal(get(handles.panelOuter,'position'),10);
[Wmin,Hmin] = deal(800,pPos(4)+2*Y0);

% retrieves the final position of the resized GUI
fPos = getFinalResizePos(hObject,Wmin,Hmin);

% update the figure position
resetFigSize(handles,fPos)

% makes the figure visible again
updateFlag = 2;
setObjVisibility(hObject,'on');

% ensures the figure doesn't resize again (when maximised)
pause(0.5);
updateFlag = 0;

% --- resizes the combining GUI objects
function resetFigSize(h,fPos)

% sets the overall width/height of the figure
[W0,H0,dY,dX,axP] = deal(fPos(3),fPos(4),10,10,zeros(1,4));

% resets the panel based on the type being viewed
[hPanelO,hPanelBG] = deal(h.panelOuter,h.panelBGDetect);
[pPanelO,pPanelBG] = deal(get(hPanelO,'Position'),get(hPanelBG,'Position'));

if strcmp(get(h.panelOuter,'Visible'),'on')
    % case is running in tracking mode
    pPosO = pPanelO;    
else
    % case is running in initial detection mode
    pPosO = pPanelBG;
end

% updates the image panel dimensions
pPosPnw = [sum(pPosO([1 3]))+dX,dY,(W0-(3*dX+pPosO(3))),(H0-2*dY)];
set(h.panelImg,'units','pixels','position',pPosPnw)

% updates the outer position bottom location
[pPanelO(2),pPanelBG(2)] = deal(H0 - (pPosO(4)+dY));
set(h.panelOuter,'position',pPanelO);
set(h.panelBGDetect,'position',pPanelBG);

% resets the axis/label fontsizes
hAx = findall(h.panelImg,'type','axes');
if ~isempty(hAx)
    axP(1:2) = [10,10];
    axP(3:4) = [(pPosPnw(3)-(axP(1)+dX)),(pPosPnw(4)-(axP(2)+dY))];
    set(hAx,'position',axP)
end   

% recalculates the axes global coordinates
calcAxesGlobalCoords(h)

% --------------------------------- %
% --- FRAME SELECTION CALLBACKS --- %
% --------------------------------- %

% --- Executes on button press in toggleVideo.
function toggleVideo_Callback(hObject, eventdata, handles)

%
if get(hObject,'value')
    % sets the visibility statuses of the play/stop buttons
    setTrackGUIProps(handles,'PlayMovie')
    if showMovie(handles)
        stopMovie(handles)
    end
end

% --- Executes on button press in frmStopButton.
function stopMovie(handles)

% updates the frame index with the current frame
handles.iData.cFrm = str2double(get(handles.frmCountEdit,'string'));

% sets the visibility statuses of the play/stop buttons
setTrackGUIProps(handles,'StopMovie')
    
% displays the final image
dispImage(handles)

% --------------------------------------------- %
% --- EXPERIMENTAL APPARATUS INFO CALLBACKS --- %
% --------------------------------------------- %

% --- Executes on button press in checkSubRegions.
function checkSubRegions_Callback(hObject, eventdata, handles)

% sets/removes division figure based on checkbox value
if get(hObject,'value')
    % setting check box, so create division figure
    iMov = get(handles.output,'iMov');
    setupDivisionFigure(iMov,handles,true);
else
    % unsetting check box, so remove division figure
    removeDivisionFigure(handles.imgAxes,false)
end

% --- Executes on button press in checkLocalView.
function checkLocalView_Callback(hObject, eventdata, handles, varargin)

% initialisations
updateTube = ~isa(eventdata,'char');

% sets the enable properties of the sub-movie selection
if get(hObject,'value')
    % if any sub-regions are showing, then remove them
    setTrackGUIProps(handles,'RemoveSubDivision')   
    setTrackGUIProps(handles,'EnableAppSelect')    

    % updates the tube region (if required)
    if updateTube
        checkShowTube_Callback(handles.checkShowTube, 1, handles)
    end        
    
    % case is update is from the main GUI
    CountEditCallback(handles.movCountEdit, [], handles)     
    
else
    % case is the global view is being shown, so enable objects
    setTrackGUIProps(handles,'EnableSubMovieObjects')    
    setTrackGUIProps(handles,'DisableAppSelect')   
    
    % updates the tube region (if required)
    if updateTube
        checkShowTube_Callback(handles.checkShowTube, 1, handles)
    end    
    
    % if the video feed has stopped, then update the image   
    CountEditCallback(handles.frmCountEdit, [], handles)       
end

% updates the image axis
if ~updateTube
    % retrieves the tube/fly location marker handle arrays
    hMark = get(handles.output,'hMark');
    hTube = get(handles.output,'hTube');

    % makes the tube/fly location markers invisible
    for i = 1:length(hMark)
        try
            cellfun(@(x)(setObjVisibility(x,'off')),hMark{i});
            cellfun(@(x)(setObjVisibility(x,'off')),hTube{i});
        catch
            initMarkerPlots(handles,1);
            hMark = get(handles.output,'hMark');
            hTube = get(handles.output,'hTube');            
        end
    end
end

% --- Executes on button press in checkReject.
function checkReject_Callback(hObject, eventdata, handles)

% global variables
global isCalib

% retrieves the data struct
hFig = handles.output;
iData = get(hFig,'iData');
iMov = get(hFig,'iMov');

% updates the ok flags within the sub-region data struct
iMov.ok(iData.cMov) = ~get(hObject,'value');
if all(~iMov.ok)
    % if all apparatus are rejected, then output and error and reset the
    % checkbox value to true
    eStr = 'Error! Must have at least one sub-region accepted';
    waitfor(errordlg(eStr,'Sub-Region Rejection Error','modal'))
    set(hObject,'value',0)
else
    % updates the movie flag and updates the GUI properties
    set(handles.output,'iMov',iMov);
    if isCalib    
        updateVideoFeedImage(hFig,hFig.infoObj.objIMAQ) 
        checkShowTube_Callback(handles.checkShowTube, 1, handles)
    else
        setTrackGUIProps(handles,'CheckReject');        
    end
end

% --------------------------------------------------- %
% --- FRAME/SUBMOVIE SELECTION CALLBACK FUNCTIONS --- %
% --------------------------------------------------- %

% --- Executes on editing in editFrameStep
function editFrameStep_Callback(hObject, eventdata, handles)

% retrieves the image data struct
hFig = handles.output;
nwVal = str2double(get(hObject,'string'));

% checks to see if the new value is valid
if chkEditValue(nwVal,[1 hFig.iData.nFrm],1)
    hFig.iData.cStp = nwVal;
else
    set(hObject,'string',num2str(hFig.iData.cStp));
end

% --- callback function for the first frame/sub-movie button --------------
function FirstButtonCallback(hObject, eventdata, handles)

% global variables
global isCalib

% sets the GUI figure handle
hFig = handles.output;
iData = get(hFig,'iData');

% updates the frame/sub-movie index
switch get(hObject,'UserData')
    case 'Frame' % case is the movie frame
        [hObj,pStr] = deal(handles.frmCountEdit,'cFrm');
        
    case 'First' % case is the movie frame
        [hObj,pStr] = deal(findall(hFig,'tag','frmCountEdit'),'cFrm');        
        
    case 'Sub' % case is the sub-movie
        [hObj,pStr] = deal(handles.movCountEdit,'cMov');
        set(handles.checkReject,'value',~hFig.iMov.ok(1));        
end

% updates the data struct with the new value
iData = setStructField(iData,pStr,1);
set(hFig,'iData',iData);

% sets the gui properties
switch get(hObject,'UserData')        
    case 'Frame' % case is the movie frame
        setTrackGUIProps(handles,'UpdateFrameSelection')        
        updateBufferIndices(handles,iData.cFrm,'first')
        
    case 'First' % case is the movie frame (Direct Detect)
        set(handles.frmCountEdit,'string','1');
        setTrackGUIProps(handles,'UpdateFrameSelection',1)        
        
    case 'Sub' % case is the sub-movie
        setTrackGUIProps(handles,'UpdateMovieSelection')
        checkShowTube_Callback(handles.checkShowTube,1,handles)
end

% updates the edit box value and the image axis
set(hObj,'string','1');
if isCalib   
    updateVideoFeedImage(hFig,hFig.infoObj.objIMAQ) 
else
    dispImage(handles)
end

% --- callback function for the last frame/sub-movie button ---------------
function LastButtonCallback(hObject, eventdata, handles, varargin)

% global variables
global isCalib

% sets the GUI figure handle
hFig = handles.output;
iData = get(hFig,'iData');

% updates the frame/sub-movie index
switch get(hObject,'UserData')
    case 'Frame' % case is the movie frame
        hObj = handles.frmCountEdit;
        [nwVal,pStr] = deal(iData.nFrm,'cFrm');
        
    case 'Last' % case is the movie frame (Direct Detection)
        hObj = findall(hFig,'tag','frmCountEdit');
        [nwVal,pStr] = deal(iData.nFrm,'cFrm');        
        
    case 'Sub' % case is the sub-movie
        hObj = handles.movCountEdit;        
        [nwVal,pStr] = deal(iData.nMov,'cMov');
        set(handles.checkReject,'value',~hFig.iMov.ok(nwVal)); 
                
end

% updates the data struct with the new value
iData = setStructField(iData,pStr,nwVal);
set(hFig,'iData',iData);

% sets the gui properties
switch get(hObject,'UserData')      
    case 'Frame' % case is the movie frame
        setTrackGUIProps(handles,'UpdateFrameSelection')       
        updateBufferIndices(handles,iData.cFrm,'last',iData.nFrm)
    
    case 'Last' % case is the movie frame (Direct Detect)
        set(handles.frmCountEdit,'string',num2str(iData.nFrm));
        setTrackGUIProps(varargin{1},'UpdateFrameSelection',iData.nFrm)
        
    case 'Sub' % case is the sub-movie
        setTrackGUIProps(handles,'UpdateMovieSelection')
        checkShowTube_Callback(handles.checkShowTube,1,handles)

end

% updates the edit box value and the image axis
set(hObj,'string',num2str(nwVal));
if isCalib
    updateVideoFeedImage(hFig,hFig.infoObj.objIMAQ) 
else
    dispImage(handles)
end

% --- callback function for the previous frame/sub-movie button -----------
function PrevButtonCallback(hObject, eventdata, handles)

% global variables
global isCalib

% % sets the GUI figure handle
hFig = handles.output;
iData = get(hFig,'iData');

% updates the frame/sub-movie index
switch get(hObject,'UserData')
    case 'Frame' % case is the movie frame
        [hObj,pStr] = deal(handles.frmCountEdit,'cFrm');
        cStp = str2double(get(handles.editFrameStep,'string'));
    
    case 'Prev' % case is the movie frame (direct detection)        
        hObj = findall(hFig,'tag','frmCountEdit');
        [pStr,cStp] = deal('cFrm',1);
        
    case 'Sub' % case is the sub-movie
        [hObj,pStr,cStp] = deal(handles.movCountEdit,'cMov',1);               
       
end

% sets the image data struct
nwVal = str2double(get(hObj,'string'));
if nwVal > 1
    % updates the data struct with the new value
    iData = setStructField(iData,pStr,max(1,nwVal-cStp));
    set(handles.output,'iData',iData);    
    
    % sets the gui properties
    switch get(hObject,'UserData')      
        case 'Frame' % case is the movie frame
            setTrackGUIProps(handles,'UpdateFrameSelection')        
            updateBufferIndices(handles,iData.cFrm,'prev')

        case 'Prev' % case is the movie frame (direct detection)
            set(handles.frmCountEdit,'string',num2str(nwVal-cStp));
            setTrackGUIProps(handles,'UpdateFrameSelection',iData.cFrm)
            
        case 'Sub' % case is the sub-movie
            set(handles.checkReject,'value',~hFig.iMov.ok(iData.cMov));            
            setTrackGUIProps(handles,'UpdateMovieSelection')
            checkShowTube_Callback(handles.checkShowTube,1,handles)
    end   
    
    % updates the edit box value and the image axis
    set(hObj,'string',num2str(nwVal-cStp));
    if isCalib  
        updateVideoFeedImage(hFig,hFig.infoObj.objIMAQ) 
    else
        dispImage(handles)
    end
    
else
    % sets the gui properties
    setTrackGUIProps(handles,'SetMenuItemEnable')
end

% --- callback function for the next frame/sub-movie button ---------------
function NextButtonCallback(hObject, eventdata, handles, varargin)

% global variables
global isCalib 

% % sets the GUI figure handle
hFig = handles.output;
iData = get(hFig,'iData');

% updates the frame/sub-movie index
switch get(hObject,'UserData')
    case 'Frame' % case is the movie frame
        hObj = handles.frmCountEdit;        
        [mxVal,pStr] = deal(iData.nFrm,'cFrm');        
        cStp = str2double(get(handles.editFrameStep,'string'));
        
    case 'Next' % case is the movie frame
        hObj = findall(hFig,'tag','frmCountEdit');        
        [mxVal,pStr,cStp] = deal(iData.nFrm,'cFrm',1);        
        
    case 'Sub' % case is the sub-movie
        hObj = handles.movCountEdit;
        [mxVal,pStr,cStp] = deal(iData.nMov,'cMov',1);        
                
end

% retrieves the current frame number and updates the frame (if not the
% final frame)
nwVal = str2double(get(hObj,'string'));
if nwVal < mxVal
    % updates the data struct with the new value
    iData = setStructField(iData,pStr,nwVal+cStp);
    set(handles.output,'iData',iData);    
    
    % sets the gui properties
    switch get(hObject,'UserData')       
        case 'Frame' % case is the movie frame
            setTrackGUIProps(handles,'UpdateFrameSelection')      
            updateBufferIndices(handles,iData.cFrm,'next')
            
        case 'Next' % case is the movie frame (Direct Detect)   
            set(handles.frmCountEdit,'string',num2str(nwVal+cStp));
            setTrackGUIProps(varargin{1},'UpdateFrameSelection',iData.cFrm)
    
        case 'Sub' % case is the sub-movie
            set(handles.checkReject,'value',~hFig.iMov.ok(iData.cMov));          
            setTrackGUIProps(handles,'UpdateMovieSelection')
            checkShowTube_Callback(handles.checkShowTube,1,handles)
        
    end
    
    % updates the edit box value and the image axis
    set(hObj,'string',num2str(nwVal+cStp));
    if isCalib
        updateVideoFeedImage(hFig,hFig.infoObj.objIMAQ) 
    else
        dispImage(handles)
    end
    
else
    % sets the gui properties
    setTrackGUIProps(handles,'SetMenuItemEnable')    
end

% --- Executes on editting the frame/sub-movie edit box -------------------
function CountEditCallback(hObject, eventdata, handles, varargin)

% global variables
global isCalib

% retrieves the image data struct
hFig = handles.output;
iData = get(hFig,'iData');
nwVal = str2double(get(hObject,'string'));

% detetermines the parameter limits
switch get(hObject,'UserData')       
    case {'Frame','DD'} % case is the movie frame
        pStr = 'cFrm';
        if isfield(iData,'nFrm')
            nwLim = [1,iData.nFrm];
        else
            nwLim = [1,1];
        end

    case 'Sub' % case is the sub-movie
        [pStr,nwLim] = deal('cMov',[1,iData.nMov]);
        set(handles.checkReject,'value',~hFig.iMov.ok(iData.cMov));        
end

% updates the frame/sub-movie index
if isCalib
    % case is the user is calibrating
    isValid = true;
    
else    
    % determines if the new value is valid
    isValid = chkEditValue(nwVal,nwLim,1);
end

% checks to see if the new value is valid
if isValid
    % if so, then updates the counter and the image frame
    iData = setStructField(iData,pStr,nwVal);
    set(handles.output,'iData',iData);
    
    % sets the gui properties    
    switch get(hObject,'UserData')      
        case 'Frame' % case is the movie frame
            setTrackGUIProps(handles,'UpdateFrameSelection')     
            updateBufferIndices(handles,iData.cFrm,'edit')

        case 'DD' % case is the movie frame
            set(handles.frmCountEdit,'string',num2str(iData.cFrm))
            setTrackGUIProps(varargin{1},'UpdateFrameSelection',iData.cFrm)     
            
        case 'Sub' % case is the sub-movie
            setTrackGUIProps(handles,'UpdateMovieSelection')
            checkShowTube_Callback(handles.checkShowTube,1,handles)
    end
    
    % updates the image axes
    if ~isCalib
        dispImage(handles)
    end
else
    % resets the edit box string to the last valid value
    set(hObject,'string',num2str(getStructField(iData,pStr)))
    if strcmp(get(hObject,'UserData'),'tag')
        set(handles.frmCountEdit,'string',num2str(eval(pStr)))
    end
end

% ---------------------------------------------- %
% --- EXPERIMENTAL PARA & ANALYSIS CALLBACKS --- %
% ---------------------------------------------- %

% --- Executes on editing in editScaleFactor
function editScaleFactor_Callback(hObject, eventdata, handles)

% global variables
global isCalib isRTPChange

% loads the data struct
hFig = handles.output;

% check to see if the new value is valid
nwVal = str2double(get(hObject,'string'));
if chkEditValue(nwVal,[0 inf],0)
    % if all good, update the number of tube rows
    hFig.iData.exP.sFac = nwVal;
    
    % updates the scale factor in the real-time tracking parameters
    if isCalib
        [hFig.rtP.trkP.sFac,isRTPChange] = deal(nwVal,true);
    end
else
    % otherwise, revert back to the previous value
    set(hObject,'string',num2str(hFig.iData.exP.sFac))
end

% --- Executes on button press in textScaleFactor -------------------------
function textScaleFactor_Callback(hObject, eventdata, handles)

% global variables
global isCalib

% initialisations
hFig = handles.output;

% stop the video timer (if calibrating)
if isCalib
    setObjEnable(handles.menuRTTrack,'off')
    stop(hFig.vidTimer)
end

% runs the scale factor sub-GUI
ScaleFactor(hFig,'FlyTrack')

% restarts the video timer (if calibrating and video feed on)
if isCalib     
    setObjEnable(handles.menuRTTrack,hFig.iMov.isSet)
    if strcmp(get(handles.menuVideoFeed,'checked'),'on')   
        start(hFig.vidTimer)
    end
end   

% ---------------------------------------- %
% --- FLY DETECTION & MARKER FUNCTIONS --- %
% ---------------------------------------- %

% --- Executes on button press in checkShowTube.
function checkShowTube_Callback(hObject, eventdata, handles)

% global variables
global szDel

% initialisations
hFig = handles.output;

% retrieves the sub-region struct
if ~isa(eventdata,'char')
    showUpdate = ~isa(eventdata,'double');
    iMov = get(hFig,'iMov');
else
    showUpdate = false;
    if isfield(handles,'iMov')
        iMov = handles.iMov;
    else
        iMov = hFig.iMov;
    end
end

% loads the tube-data struct
if ~iMov.isSet
    % if it does not exist, then exit the function
    return
end

% retrieves the tube struct arrays
Type = getDetectionType(iMov);
iData = get(hFig,'iData');
hTube = get(hFig,'hTube');
[ii,jj,mlt] = deal([1 2 2 1],[1 1 2 2],1);
isLocalView = get(handles.checkLocalView,'value');

% resets the tube regions (if they are invalid)
if ~ishandle(hTube{1}{1})
    initMarkerPlots(handles,get(hObject,'Value'))
    hTube = get(hFig,'hTube');
end

% retrieves the indices of the sub-regions to be shown
if isLocalView
    % local view, so get the current sub-region
    ind = iData.cMov;
    isOther = ~setGroup(ind,size(hTube));
    cellfun(@(x)(setObjVisibility(x,0)),hTube(isOther))
    
else
    % global view, so show all sub-regions
    ind = find(iMov.ok(:)');
end

% sets the tube visibility strings
for i = ind
    if ~showUpdate
        switch Type
            case {'GeneralR','Circle'} % case is automatic detection
                
                % sets the positional offset
                if isLocalView
                    % case is for local view
                    xOfs = (iMov.iC{ind}(1)-1)-szDel;
                    yOfs = (iMov.iR{ind}(1)-1)-szDel;            
                else
                    % case is for global view
                    [xOfs,yOfs] = deal(0);    
                end
                
                % retrieves the global row/column indices
                [iCol,iFlyR,~] = getRegionIndices(iMov,i);             
                
            otherwise % case is manual region setting
                
                % sets the positional offset                
                if isLocalView
                    % case is for local view
                    if iMov.ok(i)
                        if size(iMov.xTube{i}([1 end]),1) == 1
                            yOfs = min(max(0,(iMov.iR{ind}(1)-1)),szDel);
                            xOfs = szDel;
                        else
                            xOfs = min(max(0,(iMov.iC{ind}(1)-1)),szDel);
                            yOfs = szDel;
                        end            
                    end
                else
                    % case is for global view
                    [xOfs,yOfs] = deal(iMov.pos{i}(1),iMov.pos{i}(2));   
                end       

                % sets the x/y-coordinates of the sub-region
                if isempty(iMov.xTube{i})
                    % case is the region has never been set
                    iFlyR = [];                    
                else
                    % otherwise, set the x/y offsets
                    if size(iMov.xTube{i},1) == 1
                        x = (iMov.xTube{i}([1 end]) + xOfs);
                    else
                        y = (iMov.yTube{i}([1 end]) + yOfs);
                    end

                    % sets the fly indices
                    iFlyR = 1:length(hTube{i});
                end
        end        

        for j = iFlyR(:)'
            % retrieves the marker properties            
            [pCol,fAlpha,edgeCol] = getMarkerProps(iMov,i,j);              

            % sets the tube region patch based on the detection type 
            switch Type
                case 'GeneralR'
                    % case is the repeating general patterns
                    xTube = iMov.autoP.X0(j,iCol) + iMov.autoP.XC - xOfs;
                    yTube = iMov.autoP.Y0(j,iCol) + iMov.autoP.YC - yOfs;     
                    
                case 'Circle'
                    % calculates the circle coordinates
                    [XC,YC] = calcCircleCoords(iMov.autoP,j,iCol);
                    
                    % case is the circle/repeating general patterns
                    xTube = iMov.autoP.X0(j,iCol) + XC - xOfs;
                    yTube = iMov.autoP.Y0(j,iCol) + YC - yOfs;                       
                
                otherwise
                    % case is for the other detection types
                    if isColGroup(iMov)
                        x = (iMov.xTube{i}(j,:) + xOfs); 
                    else            
                        y = (iMov.yTube{i}(j,:) + yOfs); 
                    end

                    % sets the final tube outline x/y coordinates
                    [xTube,yTube] = deal(x(ii),y(jj));
            end

            % creates the fly/tube markers
            try
                set(hTube{i}{j},'xdata',xTube,'ydata',yTube,'FaceAlpha',...
                          fAlpha*mlt,'EdgeColor',edgeCol,'FaceColor',pCol);
            catch
                % if there was an error, reinitalise
                initMarkerPlots(handles,1)
                hTube = get(hFig,'hTube');

                % updates the tube location
                set(hTube{i}{j},'xdata',xTube,'ydata',yTube,'FaceAlpha',...
                          fAlpha*mlt,'EdgeColor',edgeCol,'FaceColor',pCol);            
            end
        end    
    end
    
    % sets the tube visibility strings
    if ~isa(eventdata,'char')
        isShow = (get(hObject,'value') && any(i == ind));        
    else
        isShow = str2double(eventdata);
    end    
    
    % sets the visibility fields
    cellfun(@(x)(setObjVisibility(x,isShow)),hTube{i})
end

% --- Executes on button press in checkShowMark.
function checkShowMark_Callback(hObject, eventdata, handles)

% global variables
global isCalib

% object retrieval
hFig = handles.output;

% updates the image axes
if isCalib
    if isfield(handles,'menuRTTrack')
        if ~strcmp(get(handles.menuRTTrack,'checked'),'on')
            updateVideoFeedImage(hFig,hFig.infoObj.objIMAQ)  
        end
    else
        % updates the plot markers
        updateAllPlotMarkers(handles,hFig.iMov,true)
    end
else
    % initialisations
    isOn = get(hObject,'Value');
    hMark = get(handles.output,'hMark');
    
    % if using local image, only turn on markers for that region
    if get(handles.checkLocalView,'Value')
        hMarkOff = hMark(~setGroup(hFig.iData.cMov,size(hMark)));
        hMark = hMark(hFig.iData.cMov);
    end
    
    try
        % attempts to update the marker visibility
        cellfun(@(x)(cellfun(@(y)(setObjVisibility(y,isOn)),x)),hMark)
        
    catch
        % if there was an error, recreate the markers and set their
        % visibility
        initMarkerPlots(handles);
        cellfun(@(x)(cellfun(@(y)(setObjVisibility(y,isOn)),x)),hMark)        
    end
    
    % turns off any markers (local view only)
    if exist('hMarkOff','var')
        cellfun(@(x)(cellfun(@(y)(setObjVisibility(y,0)),x)),hMarkOff)
    end    
end
    
% --- Executes on button press in checkShowAngle.
function checkShowAngle_Callback(hObject, eventdata, handles)

% initialisations
isOn = get(hObject,'Value');
hDir = get(handles.output,'hDir');

try
    % attempts to update the marker visibility
    cellfun(@(x)(cellfun(@(y)(setObjVisibility(y,isOn)),x)),hDir)
catch
    % if there was an error, recreate the markers and set their
    % visibility
    initMarkerPlots(handles);
    cellfun(@(x)(cellfun(@(y)(setObjVisibility(y,isOn)),x)),hDir)
end

% --- Executes on button press in buttonDetectBackground.
function buttonDetectBackground_Callback(hObject, eventdata, handles)

% global variables
global isCalib

% field retrieval
hFig = handles.output;

% disables the local view and the tube showing checkboxes
set(handles.checkLocalView,'value',0);
set(handles.checkShowTube,'value',0);
set(handles.checkSubRegions,'value',0);

% runs the callback functions
checkLocalView_Callback(handles.checkLocalView, '1', handles)
checkShowTube_Callback(handles.checkShowTube, '0', handles)
checkSubRegions_Callback(handles.checkSubRegions, [], handles)

% turns off the orientation angle markers (if on)
if get(handles.checkShowAngle,'value')
    set(handles.checkShowAngle,'value',false)
    checkShowAngle_Callback(handles.checkShowAngle, [], handles)
end

% turns off the orientation angle markers (if on)
if get(handles.checkShowMark,'value')
    set(handles.checkShowMark,'value',false)
    checkShowMark_Callback(handles.checkShowMark, [], handles)
end

% stop the video timer (if calibrating)
if isCalib
    % turns off the video feed (if it is on)
    if strcmp(get(handles.menuVideoFeed,'checked'),'on')
        menuVideoFeed_Callback(handles.menuVideoFeed, [], handles)
    end    
    
    % creates the background object 
    if isempty(handles.output.bgObj)
        set(handles.output,'bgObj',CalcBG(handles)) 
    end
else
    % removes the soln progress GUI (if it is on)
    if strcmp(get(handles.menuViewProgress,'checked'),'on')
        menuViewProgress_Callback(handles.menuViewProgress, [], handles)                           
    end    
end

% case is the running the background subtraction GUI
hFig.bgObj.openBGAnalysis();

% --- Executes on button press in buttonDetectFly.
function buttonDetectFly_Callback(hObject, eventdata, handles)

% gets a snap-shot of the figure object properties
hProp0 = getHandleSnapshot(handles);

% loads the data struct
hFig = handles.output;
iData = get(hFig,'iData');
iMov = get(hFig,'iMov');
pData = get(hFig,'pData');

% creates the tracking object based on the tracking type
if detMltTrkStatus(iMov)
    % case is tracking multiple objects
    trkObj = feval('runExternPackage','MultiTrack',iData,'Full');
    
else
    % case is tracking single objects
    trkObj = SingleTrackFull(iData);
end

% sets the GUI properties
setTrackGUIProps(handles,'PreFlyDetect')

% sets the tracking object fields
trkObj.segEntireVideo(handles,iMov,pData);
[iMov,pData] = deal(trkObj.iMov,trkObj.pData);
    
% (re)sets the initial plot markers    
if ~isempty(pData)   
    % updates the sub-region/positional data structs
    set(handles.output,'iMov',iMov);
    set(handles.output,'pData',pData);    
    
    % (re)sets the initial plot 
    initMarkerPlots(handles,1);       
    pause(0.01)

    % retrieves the last segmented frame
    [j0,i0] = find(cell2mat(iMov.Status) ~= 3,1,'first');
    cFrm = find(~isnan(pData.fPos{i0}{j0}(:,1)),1,'last');
    if isempty(cFrm); cFrm = 1; end   
    
    % updates the current frame
    hFig.iData.cFrm = cFrm;
    set(handles.frmCountEdit,'string',num2str(cFrm))    
    
    % sets the GUI properties           
    setTrackGUIProps(handles,'PostFlyDetect') 
    
else
    % otherwise, reset the GUI to the previous state
    resetHandleSnapshot(hProp0,hFig)    
end

% shows the tube regions
checkShowTube_Callback(handles.checkShowTube, eventdata, handles)
    
% -------------------------------------- %
% --- AXES FEATURES OBJECT FUNCTIONS --- %
% -------------------------------------- %

% --- Executes on button press in axesCoordCheck --------------------------
function axesCoordCheck_Callback(hObject, eventdata, handles)

% sets the axes properties
setTrackGUIProps(handles,'AxesCoordCheck')

% --- Executes on button press in checkFixRatio ---------------------------
function checkFixRatio_Callback(hObject, eventdata, handles)

% global variables
global isCalib

% updates the image
if ~isCalib
    dispImage(handles)
end

% sets the image aspect ratio
if get(hObject,'value')
    % sets the axis to the image aspect ratio
    axis(handles.imgAxes,'image')
else
    % otherwise, set aspect ratio to normal
    axis(handles.imgAxes,'normal')
end

% --- Executes on button press in gridMajorCheck --------------------------
function gridMajorCheck_Callback(hObject, eventdata, handles)

% gets the state of the toggle button
setTrackGUIProps(handles,'MajorGridCheck')

% --- Executes on button press in gridMinorCheck --------------------------
function gridMinorCheck_Callback(hObject, eventdata, handles)

% gets the state of the toggle button
setTrackGUIProps(handles,'MinorGridCheck')

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% ------------------------------- %
% --- IMAGE DISPLAY FUNCTIONS --- %
% ------------------------------- %

% --- displays an image frame to the image axes 
function dispImage(handles,varargin)

% global variables
global isCalib isBatch 

% retrieves the image data struct
hAx = handles.imgAxes;
hFig = handles.output;
iMov = get(hFig,'iMov');
iData = get(hFig,'iData');

% updates the frame selection object properties
if ishandle(handles.frmCountEdit)
    isBGCalc = ~isempty(hFig.bgObj) && hFig.bgObj.isVisible;
    if isBGCalc
        iFrmPh = hFig.bgObj.indFrm{hFig.bgObj.iPara.cPhase};
        cFrm = iFrmPh(hFig.bgObj.iPara.cFrm);
    else
        cFrm = str2double(get(handles.frmCountEdit,'string'));  
    end
else
    [cFrm,isBGCalc] = deal(1,false);
end

% sets the image data and retrieves the current image
switch nargin
    case 3 % case is a special image is being displayed
        ImgNw = varargin{1};
        
    case 2 % case is the movie is playing
        % retrieves new image from the image stack (loaded from movie show)
        [iNw,ImgS] = deal(varargin{1}{1},varargin{1}{2});   
        if size(ImgS{iNw},3) == 3
            ImgNw = rgb2gray(ImgS{iNw});
        else
            ImgNw = ImgS{iNw};
        end

        % sets the sub-image (if required)
        if get(handles.checkLocalView,'value')
            ImgNw = setSubImage(handles,ImgNw);
        end 
        
    otherwise % case is a normal image update
        isSub = get(handles.checkLocalView,'value');
        ImgNw = double(getDispImage(iData,iMov,cFrm,isSub,handles));         
end

% applies the image correction (if required)
if strcmp(get(handles.menuCorrectTrans,'Checked'),'on')
    ImgNw = applyImgOffset(ImgNw,iMov,cFrm);
end
        
% updates the frame selection properties
if ~(isCalib || isBatch || isBGCalc)
    setTrackGUIProps(handles,'UpdateFrameSelection',cFrm)
end

% -------------------- %
% --- IMAGE UPDATE --- %
% -------------------- %

% updates the image axes with the new image
hImg = findobj(handles.imgAxes,'type','image');
if isempty(hImg)
    % if there is no image object, then create a new one
    imagesc(uint8(ImgNw),'parent',handles.imgAxes);    
    set(hAx,'xtick',[],'ytick',[],'xticklabel',[],'yticklabel',[]);
    set(hAx,'ycolor','w','xcolor','w','box','off')   
    colormap(hAx,gray)
    
    if get(handles.checkFixRatio,'value')
        % sets the axis to the image aspect ratio
        axis(handles.imgAxes,'image')
    else
        % otherwise, set aspect ratio to normal
        axis(handles.imgAxes,'normal')
    end
    
    if ishandle(handles.frmCountEdit)
        if isempty(ImgNw)
            set(handles.frmCountEdit,'ForegroundColor','r')
        else
            set(handles.frmCountEdit,'ForegroundColor','k')
        end    
    end
else
    %
    if max(get(hAx,'clim')) < 10
        set(hImg,'cData',double(ImgNw))    
    else
        set(hImg,'cData',uint8(ImgNw))    
    end
    
    % otherwise, update the image object with the new image  
    if ishandle(handles.frmCountEdit)
        if isempty(ImgNw)
            set(handles.frmCountEdit,'ForegroundColor','r')        
        else        
            axis(hAx,[1 size(ImgNw,2) 1 size(ImgNw,1)]); 
            if ishandle(handles.frmCountEdit)
                set(handles.frmCountEdit,'ForegroundColor','k')
            end
        end
    end
end

% --------------------------- %
% --- TUBE REGION MARKERS --- %
% --------------------------- %

% retrieves the marker handles
hMark = get(handles.output,'hMark');

% determines if the marker objects are valid
if isempty(hMark)
    % if there are no markers, then exit
    return
    
elseif ~ishandle(hMark{1}{1})
    % otherwise, if the markers are not valid then recreate them
    if get(handles.checkShowMark,'value')
        initMarkerPlots(handles)
    else
        initMarkerPlots(handles,1)
    end
end

% updates all the plot markers
updateAllPlotMarkers(handles,iMov,~isempty(ImgNw))

% --- plays the movie from the current frame until A) the end of the 
%     movies or, B) until the user presses stop 
function isComplete = showMovie(handles)

% global variables
global bufData playVideo

% retrieves the image data struct
hFig = handles.output;
iData = get(hFig,'iData');
iMov = get(hFig,'iMov');

% retrieves the current frame index
isComplete = true;
iFrm = str2double(get(handles.frmCountEdit,'string'));
cStp = str2double(get(handles.editFrameStep,'string'));

% displays the image to the image figure
set(handles.output,'CurrentAxes',handles.imgAxes)
jCheck = findjobj(handles.toggleVideo);

% loops through all the images frames in the movie displaying to screen
while (iFrm + cStp) <= iData.nFrm
    % if the user paused the movie, then exit the function
    cState = jCheck.isSelected;    
    if ~cState
        stopMovie(handles)
        isComplete = false;
        set(handles.toggleVideo,'Value',0)
        return
    else
        % pauses for any changes
        if ~isempty(bufData)
            while bufData.changeArray
                pause(0.01)
            end
        end
                
        % otherwise, update the frame counter
        iFrm = iFrm + cStp;
        set(handles.frmCountEdit,'string',num2str(iFrm));
        updateBufferIndices(handles,iFrm,'next')        
               
        % sets the movie frame index number    
        isSub = get(handles.checkLocalView,'value');
        ImgNw = getDispImage(iData,iMov,iFrm,isSub,handles); 
        dispImage(handles,ImgNw,1)   
        pause(0.01)                
        
        % updates the frame count
        cStp = str2double(get(handles.editFrameStep,'string'));           
    end        
end

% --- updates the object location marker coordinates
function updateAllPlotMarkers(handles,iMov,hasImg)

% global variables
global isCalib

% retrieves the important data arrays/structs
hFig = handles.output;
% cType = get(hFig,'cType');

% determines if the location/orientation markers are to be plotted
pltLocT = get(handles.checkShowMark,'value') && hasImg;
if ishandle(handles.checkShowAngle)
    pltAngT = get(handles.checkShowAngle,'value') && hasImg;
else
    pltAngT = false;
end

% array indexing & parameters
if isCalib
    if isfield(hFig,'rtObj')
        if isempty(hFig.fPosTmp); return; end     
    end
end

% retrieves the updates the region markers (if there is translation)
if ~isempty(iMov.phInfo) && any(iMov.phInfo.hasT)
    
end

% sets the markers for all flies
if ~isempty(hFig.hMark)    
    for i = find(iMov.ok(:)')
        % if the markers have been deleted then re-initialise them
        initReqd = isempty(hFig.hMark{i}{1}) || ~ishandle(hFig.hMark{i}{1});
        if (i == 1) && initReqd
            initMarkerPlots(handles,1)
        end
        
        % sets the plot location marker flag for the current apparatus
        [pltLoc,pltAng] = deal(pltLocT&&iMov.ok(i),pltAngT&&iMov.ok(i));
        if isCalib       
            if isfield(hFig,'fPosTmp')
                updateIndivMarker(handles,hFig.fPosTmp,i,pltLoc,pltAng,1) 
            end
        else
            updateIndivMarker(handles,hFig.pData,i,pltLoc,pltAng) 
        end        
    end
end

% --- initialises all the image plot markers 
function initMarkerPlots(handles,varargin)

% global variables
global yDelG 

% sets the figure handle
if isfield(handles,'output')
    hFig = handles.output;
else
    hFig = handles.figFlyTrack;
end

% retrieves the sub-movie data struct
iMov = get(hFig,'iMov');
if isempty(iMov.yTube); return; end

% sets the marker sizes and linewidths
if ispc
    lWid = 1.5;
else
    lWid = 1.5;
end

% retrieves the data structs
Type = getDetectionType(iMov);
isMltTrk = detMltTrkStatus(iMov);
[ii,jj,yDelG] = deal([1 2 2 1],[1 1 2 2],0.35);
[nApp,isCG] = deal(length(iMov.iR),isColGroup(iMov));

% array creation 
if isMltTrk
    % case is single fly tracking
    nFlyR = arr2vec(iMov.nFlyR');
    A = arrayfun(@(x)(cell(x,1)),nFlyR,'un',0);

    % case is single fly tracking
    if isCG
        B = cellfun(@(x)(cell(size(x,1),1)),iMov.xTube,'un',0);
    else
        B = cellfun(@(x)(cell(size(x,1),1)),iMov.yTube,'un',0);
    end    
    
    % memory allocation
    [hMark,hTube,hDir] = deal(A,B,A);    
    
else
    % case is single fly tracking
    if isCG
        A = cellfun(@(x)(cell(size(x,1),1)),iMov.xTube,'un',0);
    else
        A = cellfun(@(x)(cell(size(x,1),1)),iMov.yTube,'un',0);
    end
    
    % memory allocation
    [hMark,hTube,hDir] = deal(A);    
end

% sets focus to the image axis
hAx = handles.imgAxes;
set(hFig,'CurrentAxes',hAx)
deleteAllMarkers(handles)

% sets the visibilty flag
if nargin == 1
    isOn = true;
else
    isOn = varargin{1}; 
end

% retrieves the checkbox markers
isOnT = get(handles.checkShowTube,'Value') && isOn;
isOnM = get(handles.checkShowMark,'Value') && isOn;
isOnD = get(handles.checkShowAngle,'Value') && isOn;

% resets the markers
hold(hAx,'on')
for i = find(iMov.ok(:)')
    % sets the x/y offset
    [xOfs,yOfs] = deal((iMov.iC{i}(1)-1),(iMov.iR{i}(1)-1));  
    
    switch Type
        case {'GeneralR','Circle'}
            % sets the row/column indices
            [iCol,iFlyR,~] = getRegionIndices(iMov,i);  
            
        otherwise
            iFlyR = 1:length(hMark{i});
            
    end
    
    for j = iFlyR(:)'
        % sets the tag strings and the offsets                
        [hTStr,hMStr] = deal('hTube','hMark');
        hDStr = sprintf('hDir%i',i);
        
        % sets the plot colour for the tubes
        [pCol,fAlpha,edgeCol,pMark,mSz] = getMarkerProps(iMov,i,j);        
        
        % sets the x/y coordinates of the tube regions (either for single
        % tracking, or multi-tracking for the first iteration)
        if (j == 1) || ~isMltTrk
            switch Type
                case {'GeneralR','Circle'}
                    % sets the outline coordinates
                    xTube = iMov.autoP.X0(j,iCol) + iMov.autoP.XC;
                    yTube = iMov.autoP.Y0(j,iCol) + iMov.autoP.YC;

                otherwise
                    % otherwise set the region based on storage type
                    if isCG
                        x = iMov.xTube{i}(j,:) + xOfs;
                        y = iMov.yTube{i}+yDelG*[1 -1] + yOfs;             
                    else
                        x = iMov.xTube{i} + xOfs;
                        y = iMov.yTube{i}(j,:)+yDelG*[1 -1] + yOfs;                              
                    end

                    % sets the final tube outline coordinates
                    [xTube,yTube] = deal(x(ii),y(jj));
            end

            % creates the tube region patch
            hTube{i}{j} = fill(xTube,yTube,pCol,'tag',hTStr,...
                            'FaceAlpha',fAlpha,'EdgeColor',edgeCol,...
                            'EdgeAlpha',1,'Visible','off','Parent',hAx,...
                            'UserData',[i,j]); 
        end
        
        % determines if separate colours are being used
        if iMov.sepCol
            % if so, retrieve the stored colours
            pColF = get(handles.output,'pColF');
            if j > length(pColF)
                % if there is sufficient colours, then reset the array
                nMark = length(hMark{i});
                pColF = num2cell(distinguishable_colors(nMark,'w'),2);
                set(handles.output,'pColF',pColF)
            end        
            
            % retrieves the colour
            pCol = pColF{j};
        end
        
        % creates the fly positional/orientation markers
        hMark{i}{j} = plot(NaN,NaN,'Color',pCol,'Marker',pMark,...
                           'MarkerSize',mSz,'Parent',hAx,'Visible','off',...
                           'LineWidth',lWid,'UserData',[i,j],'tag',hMStr);
        hDir{i}{j} = patch(NaN,NaN,pCol,'tag',hDStr,'Parent',hAx,...
                           'UserData',[10,0.33],'Visible','off');
    end
end

% sets the object marker visibilities
cellfun(@(x)(cellfun(@(y)(setObjVisibility(y,isOnT)),x)),hTube)
cellfun(@(x)(cellfun(@(y)(setObjVisibility(y,isOnM)),x)),hMark)
cellfun(@(x)(cellfun(@(y)(setObjVisibility(y,isOnD)),x)),hDir)

% turns the hold on the axis off
hold(hAx,'off')

% resets the marker array
[hFig.hMark,hFig.hTube,hFig.hDir] = deal(hMark,hTube,hDir);

% --- deletes all the image plot markers
function deleteAllMarkers(handles)

% sets the main GUI figure handle
if isfield(handles,'output')
    hFig = handles.output;
else
    hFig = handles.figFlyTrack;
end

% retrieves the sub-movie data struct
if isempty(hFig.hMark)
    % if the sub-movies have not been set, then exit the function
    return
end
    
% deletes any previous tube markers
hTube = findobj(handles.imgAxes,'tag','hTube');
if ~isempty(hTube); delete(hTube); end

% deletes any previous fly markers
hMark = findobj(handles.imgAxes,'tag','hMark');
if ~isempty(hMark); delete(hMark); end

% loops through all the apparatus deleting the tube/fly markers
for i = 1:length(hMark)
    % deletes any previous fly markers
    hDir = findobj(handles.imgAxes,'tag',sprintf('hDir%i',i));
    if ~isempty(hDir); delete(hDir); end    
end
    
% resets the tube/marker handle arrays
[hFig.hMark,hFig.hTube,hFig.hDir] = deal([]);

% ------------------------------------------ %
% --- SUB-WINDOW/EXCLUSION ROI FUNCTIONS --- %
% ------------------------------------------ %

% --- creates the new division figure for the apparatus sub-regions -------
function rPos = setupDivisionFigure(iMov,handles,isSet)

% initialisations
Type = getDetectionType(iMov);
if ~isfield(iMov,'isOpt'); iMov.isOpt = false; end

% sets the apparatus dimensions and show number flag (if not provided)
[nRow,nCol] = deal(iMov.nRow,iMov.nCol);
if nargin == 3; showNum = true; end

% sets the image axis handle
if isfield(handles,'imgAxes')
    hAx = handles.imgAxes;
else
    hAx = gca;
end

% sets the movement flag
if isfield(handles,'figFlyTrack')
    % for the main GUI viewing, so don't allow movement of the imrect boxes
    isMove = false;
else
    % otherwise, allow movement of the imrect boxes
    isMove = true;
end

% sets the window label font sizes and linewidths
if ispc
    [fSize,lWid] = deal(20,1);
else
    [fSize,lWid] = deal(26,1.25);    
end

% turns the axis hold on
hold(hAx,'on')

%
if isempty(iMov.autoP)
    hLine = findall(hAx,'tag','hLine');
    vLine = findall(hAx,'tag','vLine');

    % sets the horizontal seperators    
    if isempty(hLine)
        for i = 1:(nRow-1)
            for j = 1:nCol 
                line(hAx,[0 0],[0 0],'color','r','linestyle',':','tag','hLine',...
                                     'Userdata',[i,j],'linewidth',lWid);
            end
        end
    else
        setObjVisibility(hLine,'on');
    end

    % sets the vertical seperators
    if isempty(vLine)
        for j = 1:(nCol-1)
            line(hAx,[0 0],[0 0],'color','r','linestyle',':',...
                                 'tag','vLine','Userdata',j,'linewidth',lWid);   
        end
    else
        setObjVisibility(vLine,'on');
    end
end

% sets the number markers
if showNum
    hNum = findall(hAx,'tag','hNum');
    if isempty(hNum)
        for i = 1:nRow
            for j = 1:nCol
                k = (i-1)*nCol+j;
                hText = text(0,0,num2str(k),'visible','off','fontweight',...
                        'bold','fontsize',fSize,'tag','hNum',...
                        'color','r','parent',hAx);                
                if ~isempty(iMov.iR)    
                    if ~iMov.ok(k)
                        set(hText,'color','k')
                    end
                end
            end
        end
    else
        setObjVisibility(hNum,'on');
    end
end

% turns the axis hold off
hold(hAx,'off')

% sets up the sub-image rectangle windows
if isSet
    setupMainFrameRect(iMov,hAx,true);
    setupIndivFrameRect(handles,iMov,isMove,true);
else
    rPos = setupMainFrameRect(iMov,hAx,false);    
    setupIndivFrameRect(handles,iMov,isMove,false,rPos);
end
        
% --- sets up the main sub-window frame --- %
function [rPos,hROI] = setupMainFrameRect(iMov,hAx,isSet)

% retrieves the detection type
Type = getDetectionType(iMov);

% ------------------------------------ %
% --- OUTER RECTANGLE OBJECT SETUP --- %
% ------------------------------------ %

% retrieves the outer region handle
hOuter = findall(hAx,'Tag','hOuter');

% updates the position of the outside rectangle
if isempty(hOuter)
    if isSet
        rPos = iMov.posG;
        hROI = imrect(hAx,rPos);
    else    
        hROI = imrect;    
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
else
    setObjVisibility(hOuter,'on')
    return
end
    
% ---------------------------------- %
% --- SUB-WINDOW SEPERATOR SETUP --- %
% ---------------------------------- %

% initialisations
[nRow,nCol] = deal(iMov.nRow,iMov.nCol);

% sets the region dimension vectors
pPos = iMov.pos;
useOuter = cellfun(@isempty,pPos);
pPos(useOuter) = iMov.posO(useOuter);

%
if isempty(iMov.autoP)
    % retrieves the handles to the horizontal/vertical line objects
    vLine = findobj(hAx,'tag','vLine');
    hLine = findobj(hAx,'tag','hLine');

    % sets the horizontal 
    rPos = roundP(rPos,0.1);
    [L,T,W,H] = deal(rPos(1),rPos(2),rPos(3),rPos(4));
    yPltV = repmat(T + [0 H],nCol-1,1);

    % sets the horizontal marker regions
    if iMov.isOpt
        % memory allocation
        [yPltH,xPltV] = deal(zeros(nRow-1,2),zeros(nCol-1,2));

        % sets the y locations of the horizontal separators   
        for i = 1:(nRow-1)
            % sets the indices of the lower/upper groups
            [iLo,iHi] = deal((i-1)*nCol+(1:nCol),i*nCol+(1:nCol));

            % sets the locations of the lower top/upper bottom indices
            yT = max(cellfun(@(x)(sum(x([2 4]))),iMov.pos(iLo)));
            yB = min(cellfun(@(x)(x(2)),iMov.pos(iHi)));

            % sets the vertical location of the horizontal separator
            yPltH(i,:) = 0.5*(yT+yB); 
        end

        % sets the x locations of the vertical separators   
        for i = 1:(nCol-1)
            % sets the indices of the left/right groups
            iLf = nCol*(0:(nRow-1))'+i;

            % sets the locations of the lower top/upper bottom indices
            xR = max(cellfun(@(x)(sum(x([1 3]))),iMov.pos(iLf)));
            xL = min(cellfun(@(x)(x(1)),iMov.pos(iLf+1)));

            % sets the horizontal location of the vertical separator
            xPltV(i,:) = 0.5*(xR+xL);                 
        end   
    else    
        % sets the x locations of the vertical separators  
        [dW,dH] = deal(W/iMov.nCol,H/iMov.nRow); 
        xPltV = repmat(L + (1:(nCol-1))'*dW,1,2);    
    end

    % sets the location of the horizontal seperators
    xPltH = [L;xPltV(:,1);(L+W)];
    for i = 1:(nRow-1)        
        for j = 1:nCol
            % determines the apparatus index
            iApp = ((i-1)*nCol + j) + [0 nCol];            
            yPltH = 0.5*(sum(pPos{iApp(1)}([2 4]))+pPos{iApp(2)}(2));

            % retrieves the line
            hLineNw = findobj(hLine,'UserData',[i,j]);  
            set(hLineNw,'xData',xPltH(j+(0:1)),...
                        'yData',yPltH*[1 1],'Visible','on');
        end
    end

    % sets the location of the vertical seperators
    for j = 1:(nCol-1)
        vLineNw = findobj(vLine,'UserData',j);    
        set(vLineNw,'xData',xPltV(j,:),'yData',yPltV(j,:),'Visible','on');
    end
end
    
% retrieves the handles to the numbers 
hNum = findobj(hAx,'tag','hNum');

% sets the window index text (if set)
for i = 1:nRow
    for j = 1:nCol
        k = (i-1)*nCol+j;
        hText = findobj(hNum,'string',num2str(k));
        if ~isempty(hText)
            % sets the base x/y location of the text object
            if isfield(iMov,'iC')
                if isempty(iMov.iC{k})
                    X = L+(j-0.5)*dW;
                    Y = T+(i-0.5)*dH;                    
                else
                    X = mean(iMov.iC{k}([1 end]));
                    Y = mean(iMov.iR{k}([1 end]));
                end
            else
                X = L+(j-0.5)*dW;
                Y = T+(i-0.5)*dH;
            end
            
            % updates the text object position
            hEx = get(hText,'Extent');        
            set(hText,'position',[X-(hEx(3)/2) Y 0],'visible','on')
        end
    end
end    

% --- creates the individual sub-image rectangle frames
function setupIndivFrameRect(handles,iMov,isMove,isSet,rPos)

% global variables
global hh
hh = handles;
if isfield(handles,'figWinSplit')
    hGUIF = getappdata(handles.figWinSplit,'hGUI');
    hAx = hGUIF.imgAxes;
else
    hAx = handles.imgAxes;
end

% sets the number of apparatus to set up
del = 5;
nApp = iMov.nRow*iMov.nCol;
PosNw = zeros(1,4);
[ix,iy] = deal([1 1 2 2],[1 2 2 1]);
Type = getDetectionType(iMov);

% sets the colours for the inner rectangles
if isMove
    % case is for movable inner objects (different colours)
    if mod(iMov.nCol,2) == 1
        col = 'gmyc';    
    else
        col = 'gmy';    
    end
else
    % case is for the fixed inner objects (same colours)
    col = 'g';
end
    
% checks to see if the outer rectangles has just been set
[xLim,yLim] = deal(get(hAx,'xlim'),get(hAx,'ylim'));
if nargin == 5
    % if so, then initialise the locations of the inner rectangles
    rPosS = cell(nApp,1);
    [L,T,W,H] = deal(rPos(1),rPos(2),rPos(3),rPos(4));
    [dW,dH] = deal((W/iMov.nCol),(H/iMov.nRow));    
    
    % if there are any negative dimensions, then exit the function
    if any([dW dH] < 0)
        return
    end
    
    % calculates the new locations for all apparatus
    for i = 1:iMov.nRow
        for j = 1:iMov.nCol
            % sets the left/right locations of the sub-window
            PosNw(1) = min(xLim(2),max(xLim(1),L+((j-1)*dW+del)));
            PosNw(2) = min(yLim(2),max(yLim(1),T+((i-1)*dH+del)));                                               
            PosNw(3) = (dW-2*del) + min(0,xLim(2)-(PosNw(1)+(dW-2*del)));
            PosNw(4) = (dH-2*del) + min(0,yLim(2)-(PosNw(2)+(dH-2*del)));      
            
            % updates the sub-image position vectos
            rPosS{(i-1)*iMov.nCol+j} = PosNw;
        end
    end
else
    % otherwise, use the previous position of the inner/outer rectangles
    [rPos,rPosS] = deal(iMov.posG,iMov.pos);
end

% sets the inner rectangle objects for all apparatus
for i = find(iMov.ok(:)')
    % determines the new image sub-limits
    [xLimS,yLimS] = setSubImageLimits(hAx,xLim,yLim,iMov,rPos,i);
    xLimS = [max(rPos(1),xLimS(1)) min(rPos(1)+rPos(3),xLimS(2))];
    yLimS = [max(rPos(2),yLimS(1)) min(rPos(2)+rPos(4),yLimS(2))];   
    
    % adds the ROI fill objects
    if isSet
        hold(hAx,'on')
        hFill = fill(xLimS(ix),yLimS(iy),'r','facealpha',0,'tag',...
                     'hFillROI','linestyle','none','parent',hAx);
        if ~iMov.ok(i); set(hFill,'facealpha',0.2); end
        hold(hAx,'off')
    end        
    
    % creates the new rectangle object (non-General detection only)
    if isempty(iMov.autoP)
        hROI = imrect(hAx,rPosS{i});
        indCol = mod(i-1,length(col))+1;

        % disables the bottom line of the imrect object
        set(hROI,'tag','hInner');
        setObjVisibility(findobj(hROI,'tag','bottom line'),'off');

        % if moveable, then set the position callback function
        api = iptgetapi(hROI);
        api.setColor(col(indCol));
        api.addNewPositionCallback(@roiCallback);         
    end
    
    if isMove                      
        % sets the position callback function 
        set(hROI,'UserData',i)                
        
        % sets the constraint region for the 
        fcn = makeConstrainToRectFcn('imrect',xLimS,yLimS);
        api.setPositionConstraintFcn(fcn);                 
        
        % sets the tube seperator lines
        if isSet
            %
            [xTube,yTube] = deal(iMov.xTube{i},iMov.yTube{i});            
            [xOfs,yOfs] = deal(iMov.pos{i}(1),iMov.pos{i}(2));
            
            % retrieves the tube count
            if iMov.isOpt
                nTube = size(yTube,1)-1;
            else
                nTube = getSRCount(iMov,i)-1;
            end
            
            % sets the x/y coordinates of the tube region
            xTubeS = repmat(xTube+xOfs,nTube,1)';            
            yTubeS = 0.5*(yTube(1:end-1,2)+yTube(2:end,1))' + yOfs;            
            yTubeS = repmat(yTubeS,2,1);
        else
            % retrieves the tube count
            nTube = getSRCount(iMov,i);            
            
            % sets the x/y coordinates of the tube region
            xTubeS = repmat(rPosS{i}(1)+[0 rPosS{i}(3)],nTube-1,1)';
            yTubeS = rPosS{i}(2) + (rPosS{i}(4)/nTube)*(1:(nTube-1));         
            yTubeS = repmat(yTubeS,2,1);
        end

        % plots the tube markers
        hold(hAx,'on')
        line(hAx,xTubeS,yTubeS,'color',col(indCol),'linestyle','--','tag',...
                    sprintf('hTubeEdge%i',i),'UserData','hTube');        
        hold(hAx,'off')          
    else                
        % sets the constraint function for the rectangle object
        switch Type
            case {'GeneralR','Circle'}
                hInner = findall(hAx,'tag','hInner','UserData',i);
                if isempty(hInner)
                    
                    XX = iMov.iC{i}([1,end]);
                    YY = iMov.iR{i}([1,end]);
                    [ii,jj] = deal([1,1,2,2,1],[1,2,2,1,1]);
                    
                    hold(hAx,'on') 
                    line(XX(ii),YY(jj),'color','g','tag','hInner',...
                                       'UserData',i);
                    hold(hAx,'off')
                else
                    setObjVisibility(hInner,'on')
                end
                
            otherwise
                % force the imrect object to be fixed
                setResizable(hROI,false);                
                
                fcn = makeConstrainToRectFcn('imrect',rPos(1)+[0 rPos(3)],...
                                                      rPos(2)+[0 rPos(4)]);
                api.setPositionConstraintFcn(fcn); 
                set(findobj(hROI),'hittest','off')
        end
    end            
end

% --- removes all the sub-movie division markers from the main axis -------
function removeDivisionFigure(hAx,forceDelete)

% sets the default input arguments
if nargin == 1; forceDelete = true; end

% retrieves the m
tStr = {'hInner','hOuter','hLine','vLine','hNum','hFillROI'};
for i = 1:length(tStr)
    eval(sprintf('%s = findobj(hAx,''tag'',''%s'');',tStr{i},tStr{i}));
end

% retrieves the sub-region object handles
hTube = findobj(hAx,'UserData','hTube');

% deletes all the tube-markers
if forceDelete
    delete(hInner)
    delete(hOuter)
    delete(hLine)
    delete(vLine)
    delete(hNum)
    delete(hFillROI)
    delete(hTube)
else
    setObjVisibility(hInner,'off')
    setObjVisibility(hOuter,'off')
    setObjVisibility(hLine,'off')
    setObjVisibility(vLine,'off')
    setObjVisibility(hNum,'off')
    setObjVisibility(hFillROI,'off')
    setObjVisibility(hTube,'off')
end

% --- inner region movement callback function --- %
function roiCallback(rPos)

% global variables
global hh useAuto

% if the window-split GUI is being used
if isfield(hh,'editLeft')
    % retrieves the sub-region data struct
    useAuto = false;
    iMov = getappdata(hh.figWinSplit,'iMov');
        
    % resets the locations of the flies
    iApp = get(get(gco,'Parent'),'UserData');
    nTube = getSRCount(iMov,iApp);
    hTube = findobj(gca,'tag',sprintf('hTubeEdge%i',iApp));
    dY = diff(rPos(2)+[0 rPos(4)])/nTube;
    
    % sets the x/y locations of the tube sub-regions
    xTubeS = repmat(rPos(1)+[0 rPos(3)],nTube-1,1)';
    yTubeS = repmat(rPos(2)+(1:(nTube-1))*dY,2,1);
    
    % sets the x/y locations of the inner regions
    for i = 1:length(hTube)
        set(hTube{i},'xData',xTubeS(:,i),'yData',yTubeS(:,i));
    end
    
    % enables the update button
    setObjEnable(hh.buttonUpdate,'on')
end

% ------------------------------------------- %
% --- PROGRAM DEFAULT DIRECTORY FUNCTIONS --- %
% ------------------------------------------- %

% --- initialises and confirms that A) the program default file exists, and
%     B) the directories listed in the file are valid --- %
function ProgDef = initProgDef(handles)

% global variables
global mainProgDir

% sets the program default file name
progFileDir = fullfile(mainProgDir,'Para Files');
progFile = fullfile(progFileDir,'ProgDef.mat');

% determines if the program defaults have been set
if ~exist(progFileDir,'dir'); mkdir(progFileDir); end
if exist(progFile,'file')
    % if so, loads the program preference file and set the program 
    % preferences (based on the OS type)
    A = load(progFile);
    ProgDef = checkDefaultDir(handles,A.ProgDef);
else
    % displays a warning
    uChoice = questdlg(['Program defaults file not found. Would you like ',... 
        'to setup the program default file manually or automatically?'],...
        'Program Default Setup','Manually','Automatically','Manually');
    switch uChoice
        case 'Manually'
            % user chose to setup manually, so load the ProgDef sub-GUI
            ProgDefaultDef(handles.output,'Tracking');
            ProgDef = handles.output.iData.ProgDef;
            
        case 'Automatically'
            % user chose to setup automatically then create the directories
            ProgDef = setupAutoDir(progDir,progFile);
    end    
end

% --- checks if the program default directories exist ---------------------
function [ProgDef,isExist] = checkDefaultDir(handles,ProgDef,varargin)

% retrieves the field names
fldNames = fieldnames(ProgDef);
isExist = true(length(fldNames),1);

% loops through all the field names determining if the directories exist
for i = 1:length(fldNames)
    % sets the new variable string
    nwVar = sprintf('ProgDef.%s',fldNames{i});
    nwDir = eval(nwVar);
    fType = 'dir';
    
    % if no directory has not set, then set the field names 
    switch fldNames{i}
        case 'DirMov'
            dirName = 'Default Movie';            
        case 'DirSoln'
            dirName = 'Video Solution';            
        case 'TempFile'
            dirName = 'Temporary File';              
    end    
    
    % check to see if the directory exists
    if isempty(nwDir)
        % flag that the directory has not been set
        isExist(i) = false;  
        if nargin == 1
            wStr = sprintf('Warning! The "%s" directory is not set.',dirName);
            waitfor(warndlg(wStr,'Directory Location Error','modal'))        
        end
    elseif exist(nwDir,fType) == 0
        % if the directory does not exist, then clear the directory field
        % and flag a warning
        isExist(i) = false;
        eval(sprintf('%s = [];',nwVar));                
        if nargin == 1
            wStr = sprintf('Warning! The "%s" directory does not exist.',dirName);
            waitfor(warndlg(wStr,'Missing Directory','modal'))        
        end
    end
end

% if any of the directories do not exist, then 
if any(~isExist)
    % runs the program default sub-ImageSeg
    if nargin == 1
        ProgDefaultDef(handles.output,'Tracking');        
        ProgDef = handles.output.iData.ProgDef;    
    end
end

% --- function that automatically sets up the default directories --- %
function ProgDef = setupAutoDir(progDir,progFile)

% otherwise, create the 
if ~exist(progDir,'dir'); mkdir(progDir); end
baseDir = fullfile(progDir,'Output Files');

% sets the default directory names
a.DirMov = fullfile(baseDir,'Recorded Movies');
a.DirSoln = fullfile(baseDir,'Solution Files (Video)');
a.TempFile = fullfile(baseDir,'Temporary Files');

% creates the new default directories (if they do not exist)
b = fieldnames(a);
for i = 1:length(b)
    % if the new directory does not exist, then create it
    if ~strcmp(b{i},'SegPara')
        % sets the new directory name
        nwDir = eval(sprintf('a.%s',b{i}));        
         
        % if the directory does not exist, then create it
        if exist(nwDir,'dir') == 0
            mkdir(nwDir)
        end
    end
end

% saves the program default file
ProgDef = a;
save(progFile,'ProgDef');

% ----------------------------------------- %
% --- FRAME BUFFERING/LOADING FUNCTIONS --- %
% ----------------------------------------- %

% --- initialises the frame buffering struct --- %
function bufData = initFrameBuffer(handles,imgExe)
    
% if the file exists, then initialise the data struct
bufData = struct('fDel',30,'indS',[],'I',[],'imgExe',imgExe,'isUpdate',[],...
                 'i0',1,'iL',0,'tObjChk',[],'tObjFile',[],'tmpFile',[],...
                 'canUpdate',false,'changeArray',false);

% sets the temporary file name             
iData = get(handles.output,'iData');             
bufData.tmpFile = fullfile(iData.ProgDef.TempFile,'Frame Stack.mat');

% memory allocation for the arrays             
[bufData.I,bufData.isUpdate] = deal(cell(1,6),false(1,6));

% initialises the update check timer object
bufData.tObjChk = timer();
set(bufData.tObjChk,'Period',1,'ExecutionMode','FixedRate',...
                    'TimerFcn',{@checkFrameUpdate,handles},...
                    'TasksToExecute',inf);

% initialises the update check timer object
bufData.tObjFile = timer();
set(bufData.tObjFile,'Period',0.1,'ExecutionMode','FixedRate',...
                     'TimerFcn',{@checkFileOutput,handles},...
                     'TasksToExecute',inf);         
         
% --- sets the frame loading function --- %
function checkFrameUpdate(obj,event,handles)

% global variables
global bufData indGrpNw
ii = [4 3 5 2 6 1];     % update priority order (from middle to outside)

try

% checks to see if there are any updates to be made
if any(bufData.isUpdate(ii)) && bufData.canUpdate    
    % if so, then set the order for the which the groups are to be udpated
    iOrder = ii(logical(bufData.isUpdate(ii)));
    [indStack,fDel] = deal(bufData.indStack,bufData.fDel);
    
    % sets the sub-movie and program data structs
    hFig = handles.output;
    iMov = get(hFig,'iMov');
    iData = get(hFig,'iData');    
    outDir = iData.ProgDef.TempFile;
    
    % sets the start     
    indGrpNw = iOrder(1);    
    bufData.isUpdate(indGrpNw) = 0;
    i1 = bufData.i0 + indStack(indGrpNw);
    i2 = bufData.i0 + (indStack(indGrpNw) + (fDel - 1));
    i3 = i1:i2; i3((i3 < 1) | (i3 > iData.nFrm)) = NaN;                        

    % if all the middle updates are correct, then enable the play button
    if all(bufData.isUpdate(3:4) == 0)
        setObjEnable(handles.frmPlayButton,'on'); pause(0.05)
    else
        setObjEnable(handles.frmPlayButton,'off'); pause(0.05)
    end
    
    % sets the string and runs the executable runs the executables        
    if ~all(isnan(i3))
        % resets the update flag and the first/last indices
        bufData.canUpdate = false;
        ind0 = i3(find(~isnan(i3),1,'first'));                        
        indF = i3(find(~isnan(i3),1,'last'));
        disp([indGrpNw ind0 indF])

        % stops the timer object
        stop(obj);        
        
        % once allowed, reset the image stack
        nwStr = sprintf('start %s "%s" %i %i %i "%s"',bufData.imgExe,...
                        iData.movStr,ind0,indF,iMov.sRate,outDir);        
        [~,~] = system(nwStr);

        % starts the buffer data
        if strcmp(get(bufData.tObjFile,'Running'),'off')
            start(bufData.tObjFile);
        end
        
        % restarts the timer object
        start(obj);            
    end        
end

catch ME
    a = 1; 
end

% --- sets the frame loading function --- %
function checkFileOutput(obj,event,handles)

% global variables
global bufData indGrpNw

% sets the data file
if exist(bufData.tmpFile,'file') && ~bufData.changeArray   
    try
        % attempts to load the temporary file        
        A = load(bufData.tmpFile);
        if isfield(A,'Istack')
            % if the file is valid, then stop the timer object
            bufData.changeArray = true;
            stop(obj)                
            
            % sets the data from the file and delete it
            bufData.I{indGrpNw} = A.Istack;
            try; delete(bufData.tmpFile); end

            % if the group being added is at the extremities, then arrays and
            % indices so that they match the new setup
            if indGrpNw == 1
                % case is the first group, so shift arrays right
                Nnew = length(bufData.I{1});
                bufData.I(2:5) = bufData.I(1:4); bufData.I{1} = [];
                bufData.i0 = bufData.i0 - Nnew;
            elseif indGrpNw == 6
                % case is the last group, so shift arrays left 
                Nnew = length(bufData.I{end});
                bufData.I(2:5) = bufData.I(3:end); bufData.I{end} = [];
                bufData.i0 = bufData.i0 + Nnew;                
            end
            
            % flag that an update is now possible    
            bufData.canUpdate = true;     
            bufData.changeArray = false;
        end
    end        
end

% --- updates the buffer indices (for frame selection/movie play)
function updateBufferIndices(handles,cFrm,type,nFrm)

% global variables
global bufData
if isempty(bufData); return; end

% sets the buffer indices based on the frame/type
switch type
    case 'prev' % case is the previous frame
        if (mod(cFrm,bufData.fDel)+1) == bufData.fDel
            % case is the frame has changed over into the previous bin. 
            % flag an update for the first bin
            bufData.isUpdate(1) = 1;            
        end  
        
    case 'next' % case is the next frame
        if (mod(cFrm,bufData.fDel)+1) == 1
            % case is the frame has changed over into the next bin. flag an
            % update for the last bin
            bufData.isUpdate(end) = 1;
        end      
        
    case 'first' % case is the first frame
        [bufData.isUpdate,bufData.I(:)] = deal([0 1 1 1 1 0],{[]});
        [bufData.i0,bufData.canUpdate] = deal(1,true);
        setObjEnable(handles.toggleVideo,'on')
        
    case 'last' % case is the last frame
        [bufData.isUpdate,bufData.I(:)] = deal([0 1 1 1 1 0],{[]});
        [bufData.i0,bufData.canUpdate] = deal(nFrm,true);
        setObjEnable(handles.toggleVideo,'off')
        
    case 'edit' % case is the edit box update
        [bufData.isUpdate,bufData.I(:)] = deal([0 1 1 1 1 0],{[]});
        [bufData.i0,bufData.canUpdate] = deal(cFrm,true);
        setObjEnable(handles.toggleVideo,'off')
end

% resets the local index
bufData.iL = cFrm - bufData.i0;
indGrp = floor(bufData.iL/bufData.fDel)+4;    
% [bufData.i0,indGrp,bufData.iL,(mod(bufData.iL,bufData.fDel)+1)]

% ---------------------------------------------------- %
% --- OTHER OBJECT/STRUCT INITIALISATION FUNCTIONS --- %
% ---------------------------------------------------- %

% --- initialises the program data struct
function iData = initDataStruct(handles,ProgDefNew)

% global variables
global mainProgDir

% creates the data struct
iData = struct('cFrm',1,'cMov',1,'cStep',1,'Status',0,...
           'nFrmMax',50,'nFrm',0,'nMov',0,'Frm0',NaN,...
           'isSave',false,'isOpen',false,'isLoad',false,'ProgDef',[],...
           'exP',[],'sgP',[],'stimP',[],'fData',[],'sfData',[]);     
       
% sets the sub-fields        
if isempty(ProgDefNew)
    pFile = fullfile(mainProgDir,'Para Files','ProgDef.mat');
    if exist(pFile,'file')
        A = load(pFile);
        iData.ProgDef = A.ProgDef.Tracking;
    else
        iData.ProgDef = initProgDef(handles);
    end
else
    iData.ProgDef = ProgDefNew;
end

% creates the experiment parameter struct
iData.exP = setExpPara(handles);

% --- initialises the sub-movie data struct
function iMov = initMovStruct(iData)

% global variables
global mainProgDir 

% determines if the tracking parameters have been set
A = load(fullfile(mainProgDir,'Para Files','ProgPara.mat'));
if ~isfield(A,'trkP')
    % track parameters have not been set, so initialise
    trkP = initTrackPara();
else
    % track parameters have been set
    trkP = A.trkP;
end

% Sub-Movie Data Struct
iMov = struct('pos',[1 1 1 1],'posG',[],'Ibg',[],'ddD',[],...
              'nRow',[],'nCol',[],'nPath',trkP.nPath,...                            
              'nTube',[],'nTubeR',[],'nFly',[],'nFlyR',[],...              
              'iR',[],'iC',[],'iRT',[],'iCT',[],'xTube',[],'yTube',[],...
              'sgP',[],'Status',[],'tempName',[],'autoP',[],'bgP',[],...
              'isSet',false,'ok',true,'tempSet',false,'isOpt',false,...
              'useRot',false,'rotPhi',90,'calcPhi',false,'sepCol',false,...
              'vGrp',[],'sRate',5,'nDS',1,'mShape','Rect','phInfo',[]);
iMov.sgP = iData.sgP;          
          
% --- sets the experimental parameters struct/field values --- %
function exP = setExpPara(handles,exP)

% initialises the struct
if nargin == 1
    exP = struct('FPS',NaN,'sFac',1);    
end

% loops through all the fields updating the 
a = fieldnames(exP);
for i = 1:length(a)
    % retrieves the edit box that belongs to the field name, and sets its
    % value
    hEdit = findobj(handles.output,'UserData',a{i});
    set(hEdit,'string',num2str(eval(sprintf('exP.%s',a{i}))))
end 

% ---------------------------------------------------- %
% --- OTHER OBJECT/STRUCT INITIALISATION FUNCTIONS --- %
% ---------------------------------------------------- %
          
% --- initialises the video timer object --- %
function initVideoTimer(handles,isStart)

% global variables
global vFrm
if nargin == 1; isStart = true; end

% determines whether whether the calibration is a test
isTest = get(handles.output,'isTest');

% retrieves all the previous video timer objects
hTimer = timerfind; 
if ~isempty(hTimer)
    % determines if there are any old timer objects
    if length(hTimer) == 1
        hTimerOld = strcmp(get(hTimer,'tag'),'vidTimer');
    else
        hTimerOld = cellfun(@(x)(strcmp(x,'vidTimer')),get(hTimer,'tag'));
    end

    % deletes any old timer objects (if any exist)
    if any(hTimerOld)
        % attempts to stop all the timer objects
        try
            stop(hTimer(hTimerOld))
        end

        % deletes all the timer objects
        delete(hTimer(hTimerOld))
    end
end

% creates the timer object
vidTimer = timer('tag','vidTimer');
vFrm = 1;

% sets the timer object properties
set(vidTimer,'Period',0.5,'ExecutionMode','FixedRate',...
           'TimerFcn',{@timerVideoFcn,handles,infoObj.objIMAQ,isTest},...
           'StartFcn',{@startVideoFcn,handles,infoObj.objIMAQ,isTest},...
           'StopFcn',{@stopVideoFcn,handles,infoObj.objIMAQ,isTest},...
           'TasksToExecute',inf);
       
% includes the timer object within the GUI
set(handles.output,'vidTimer',vidTimer)
if isStart; start(vidTimer); end

% --- the experiment timer callback function       
function startVideoFcn(obj, event, handles, objIMAQ, isTest)

% global variables
global vFrm 
vFrm = 1;

% --- the experiment timer callback function       
function stopVideoFcn(obj, event, handles, objIMAQ, isTest)

% updates the video feed
updateVideoFeedImage(handles.output,objIMAQ) 

% --- the experiment timer callback function       
function timerVideoFcn(obj, event, handles, objIMAQ, isTest)

% global variables
global vFrm

% increments the video frame index (if running test)
% set(handles.frmCountEdit,'string',num2str(vFrm))
if isTest
    vFrm = mod(vFrm-1,handles.output.iData.nFrm) + 1;    
else
    vFrm = vFrm + 1;        
end

% updates the image axes
updateVideoFeedImage(handles.output,objIMAQ) 

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- sets the callback functions for the frame/movie selection objects ---
function initSelectionProps(handles)

% sets the base object string and the object types
wStr = {'FirstButton','LastButton','NextButton',...
        'PrevButton','CountEdit'};
uStr = {'Frame','Sub'};    
pStr = {'frm','mov'};
    
% loops through all the selection property objects initialising the
% callback functions
for i = 1:length(wStr)
    for j = 1:length(pStr)
        % sets the current object handle
        hObj = eval(sprintf('handles.%s%s',pStr{j},wStr{i}));
        
        % sets the callback function and userdata strings
        if ishandle(hObj)
            cbFcnStr = sprintf('%sCallback',wStr{i});
            cbFcn = {str2func(cbFcnStr),handles};
            set(hObj,'Callback',cbFcn,'UserData',uStr{j})
        end
    end
end

% --- retrieves the tube/fly marker properties (based on the analysis type
%     and the status of the fly/tube region)
function [pCol,fAlpha,edgeCol,pMark,mSz] = getMarkerProps(iMov,i,j)

% global variables
global isCalib mainProgDir

% initialisations
edgeCol = 'y';
cStr = {'pNC','pMov','pStat','pRej'};

% determines if the tracking parameters have been set
A = load(fullfile(mainProgDir,'Para Files','ProgPara.mat'));
if ispc
    % track parameters have not been set, so initialise
    mPara = A.trkP.PC;
else
    % track parameters have been set
    mPara = A.trkP.PC;
end

% sets the plot colour for the tubes
if isCalib
    % determines if the fly has been accepted/rejected
    if iMov.flyok(j,i) && iMov.ok(i)
        % case is fly is accepted
        [fAlpha,mSz] = deal(0.1,mPara.pMov.mSz);
        [pCol,pMark] = deal(mPara.pMov.pCol,mPara.pMov.pMark);
    else
        % case is fly is rejected
        [edgeCol,fAlpha,mSz] = deal('k',0.50,mPara.pRej.mSz);
        [pCol,pMark] = deal(mPara.pRej.pCol,mPara.pRej.pMark);                            
    end
else
    % resets the status flag (if the fly is flagged for rejection)
    if detMltTrkStatus(iMov)
        % case is multi-fly tracking
        Status = 1;
        
    else
        % case is single fly tracking
        if ~(iMov.flyok(j,i) && iMov.ok(i))
            [Status,iMov.Status{i}(j)] = deal(3);
            
        elseif isnan(iMov.Status{i}(j))
            [Status,iMov.Status{i}(j)] = deal(0);
            
        else
            Status = iMov.Status{i}(j);
            
        end    
    end
    
    % sets the facecolour and marker colour, type and size
    fAlpha = 0.1*(1 + (Status~=1));   
    mParaFld = getStructField(mPara,cStr{1+Status});
    [pMark,mSz,pCol] = deal(mParaFld.pMark,mParaFld.mSz,mParaFld.pCol);
end

% --- calculates the coordinates of the axes with respect to the global
%     coordinate position system
function calcAxesGlobalCoords(handles)

% global variables
global axPosX axPosY

% retrieves the position vectors for each associated panel/axes
pPosAx = get(handles.panelImg,'Position');
axPos = get(handles.imgAxes,'Position');

% calculates the global x/y coordinates of the
axPosX = (pPosAx(1)+axPos(1)) + [0,axPos(3)];
axPosY = (pPosAx(2)+axPos(2)) + [0,axPos(4)];

% --- determines the axes objects the mouse is currently hovering over
function hPlot = findHoverPlotObj(handles)

% parmeters
Dtol = 5;

% initialisations
hPlot = [];
hAx = handles.imgAxes;
mPos = get(hAx,'CurrentPoint');

% finds the objects from the current axes
axObj = findobj(hAx,'type','line');
if isempty(axObj)    
    return
end

% calculate the minimum distances between the lines and the mouse position
[xD,yD] = deal(get(axObj,'xData'),get(axObj,'yData'));
if ~iscell(xD)
    % no valid values, so exit
    return
else
    D = cellfun(@(x,y)(calcMinPointDist(x,y,mPos(1,1:2))),xD,yD);
    if all(isnan(D))
        % no valid values, so exit
        return
    end
end

% if the line object with the minimum distance from the point is less than
% tolerance, then show the marker
iDmn = argMin(D);
if D(iDmn) <= Dtol
    hPlot = axObj(iDmn);
end

% --- calculates the minimum point distance 
function Dmin = calcMinPointDist(x,y,mP)

Dmin = min(sqrt((x-mP(1)).^2 + (y-mP(2)).^2));
