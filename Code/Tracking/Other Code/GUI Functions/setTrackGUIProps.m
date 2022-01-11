% --- sets the gui properties given by the action given by typeStr
function varargout = setTrackGUIProps(handles,typeStr,varargin)

% global variables
global isCalib

% sets the input arguments
pVar = varargin;

%
if isfield(handles,'output')
    hFig = handles.output;
else
    hFig = handles.figFlyTrack;
end

% determines if the sub-image is being viewed
isSub = get(handles.checkLocalView,'value');

% retrieves the fields
iMov = get(hFig,'iMov');
iData = get(hFig,'iData');
pData = get(hFig,'pData');
cType = get(hFig,'cType');
isTest = get(hFig,'isTest');

% retrieves the gui functions
dispImage = get(hFig,'dispImage');
deleteAllMarkers = get(hFig,'deleteAllMarkers');
removeDivisionFigure = get(hFig,'removeDivisionFigure');
initMarkerPlots = get(hFig,'initMarkerPlots');
checkShowTube_Callback = get(hFig,'checkShowTube_Callback');
checkShowMark_Callback = get(hFig,'checkShowMark_Callback');
FirstButtonCallback = get(hFig,'FirstButtonCallback');

% other initialisations
eStr = {'off','on'};
    
% sets the object properties based on the type string
switch (typeStr)
    % --- OBJECT INITIALISATIONS --- %
    % ------------------------------ %
    
    case ('InitGUI') % case is initialising the GUI             
        % disables the GUI objects for all panels
        setImgEnable(handles,'off')
        setFrmEnable(handles,'off')
        setMovEnable(handles,'off')
        setSubMovEnable(handles);
        setParaEnable(handles,'off')
        setDetectEnable(handles,'off')
        setAxesEnable(handles,'off')
        setMenuEnable(handles,'off')   
        
        % deletes any extraneous menu items
        try           
            % removes the tags from the handles struct
            hMenu = findall(handles.menuRTCalib,'type','uimenu');            
            for i = 1:length(hMenu)
                handles = rmfield(handles,get(hMenu(i),'tag')); 
            end            
            
            % deletes the handles
            delete(hMenu);         
        end        
        
        % resets the handle
        varargout{1} = handles;
        
        % sets the video status objects to being invisible
        setObjVisibility(handles.textVideoStatus,'off')
        setObjVisibility(handles.editVideoStatus,'off')
        
    case ('InitGUICalib') % case is initialising the GUI     
        % sets the type string
        if cType == 1
            tStr = 'Real-Time Calibration';    
        else
            tStr = 'Trackiing Calibration';          
            set(hFig,'Resize','off')
        end
        
        % sets the frame step objects to being invisible
        setObjVisibility(handles.textFrameStep,'off')
        setObjVisibility(handles.editFrameStep,'off')        
        
        % initialises the field strings/values
        setImgEnable(handles,'on')   
        set(handles.textMovieFileS,'string',tStr)
        if isTest
            set(handles.textFrameCountS,'string','N/A')
            set(handles.textTimeStepS,'string','N/A')
            set(handles.textFrameSizeS,'string','N/A')                   
        else
            % retrieves the video resolution
            infoObj = get(hFig,'infoObj');
            vRes = getVideoResolution(infoObj.objIMAQ);
            vStr = sprintf('%i %s %i',vRes(2),char(215),vRes(2));
            
            % determines the video framerate
            objSrc = get(infoObj.objIMAQ,'Source');
            vRate = roundP(str2double(get(objSrc,'FrameRate')));
            
            % sets the field strings
            set(handles.textFrameCountS,'string','Video Feed')
            set(handles.textTimeStepL,'string','Frame Rate')
            set(handles.textTimeStepS,'string',sprintf('%i fps',vRate))
            set(handles.textFrameSizeS,'string',vStr)    
        end
        
        % disables the other GUI objects
        setFrmEnable(handles,'off')
        setMovEnable(handles,'off')                 
        setSubMovEnable(handles);
        setParaEnable(handles,'off')        
        setDetectEnable(handles,'off')
        
        % deletes any extraneous menu items
        try
            if cType == 1
                delete(handles.menuOpen)
                delete(handles.menuSaveSoln)
            else
                reshapeCalibObjects(handles)         
            end
            
            delete(handles.menuProgPara)
            delete(handles.menuStimInfo)            
            delete(handles.menuSplitVideo)   
            delete(handles.menuBatchProcess)
            delete(handles.menuViewProgress)
            delete(handles.menuManualReseg)                        
            guidata(hFig);      
        end
        
        % sets the menu item properties        
        varargout{1} = handles;
        set(handles.menuVideoFeed,'checked','off')
        set(handles.menuExit,'label','Exit Calibation');
        setObjEnable(handles.checkReject,'off')
        set(handles.checkFixRatio,'value',1)
        
        if ~iMov.isSet
            % if the sub-regions haven't been set, then only set the 
            setMenuEnable(handles,'on',[4 5])   
%             setObjEnable(handles.menuRTTrack,'off')
%             setObjEnable(handles.menuRTPara,'off') 
            
        elseif ~initDetectCompleted(iMov)
            % otherwise, if the background has not been set, then disable
            % the fly location marker checkbox
            if cType == 1
                setMenuEnable(handles,'on',4:5)   
                setDetectEnable(handles,'on',[1 4])   
                set(handles.movCountEdit,'string','1')
%                 setObjEnable(handles.menuRTTrack,'off')
                
            elseif ~iMov.isSet
                setPanelProps(handles.panelImgData,'off',1)
                setPanelProps(handles.panelAppInfo,'off',1)
            end
            
        else
            % otherwise, enable all required objects 
            setMenuEnable(handles,'on',4:5)  
            setDetectEnable(handles,'on',[1 4])                      
            set(handles.movCountEdit,'string','1')
%             setObjEnable(handles.menuRTTrack,'on')
        end
        
        % updates the movie count
        iData.nMov = iMov.nRow*iMov.nCol*iMov.isSet;
        set(hFig,'iData',iData);
        
        % enables/disables the appropriate GUI objects
        setAxesEnable(handles,'on',[1 2])                
        setObjEnable(handles.textScaleFactor,'on')
        setObjEnable(handles.editScaleFactor,'on')
        
        % if testing, then set the frame count edit box to inactive        
        if get(hFig,'isTest')
            setObjEnable(handles.frmCountEdit,'inactive')
        end        
        
        if isTest
            set(setObjEnable(handles.menuVideoFeed,'off'),'checked','off')
            setObjVisibility(handles.menuVideoProps,'off')
            setPanelProps(handles.panelAxProp,'off',1)
            
        else
            set(handles.menuVideoFeed,'checked','on')
        end                
        
    % --- PRE/POST FILE I/O --- %
    % ------------------------- %        
        
    case ('PreMovieLoad') % case is before opening a movie file        
        % disables buttons and option boxes, and clears all text labels
        cla
        setImgEnable(handles,'off');
        pause(0.01);                
        
    case ('PostImageLoadBatch') % case is the successful movie load
        % sets the image data panel text strings   
        setImgData(handles,iData,iMov,1);        
        
    case ('PostImageLoad') % case is the successful movie load
        % sets the image data panel text strings   
        setImgData(handles,iData,iMov,1); 
        
        % resets the image zoom
        [m,n] = deal(iData.sz(1),iData.sz(2));
        set(handles.imgAxes,'xlim',[1 n],'ylim',[1 m],'visible','on')   
        
        % sets the GUI object enabled properties
        setParaEnable(handles,'on')
        setAxesEnable(handles,'on',1:2)
        setDetectEnable(handles,'off')
        setTrackGUIProps(handles,'UpdateFrameSelection')
        setMenuEnable(handles,'on',8)
        setMenuEnable(handles,'off',[2,7])     
                
        % resets the status flag 
        iData.Status = 0;        
        set(handles.output,'iData',iData,'pData',[]);
        
        % clears the sub-regions
        setMovEnable(handles,'off')
        setSubMovEnable(handles);                       
        
        % sets the other object properties
        set(handles.checkFixRatio,'value',1)                
    	set(setObjEnable(handles.frmCountEdit,'on'),...
                            'string',num2str(iData.cFrm)); 
    	set(setObjEnable(handles.editFrameRate,'inactive'),...
                            'string',num2str(roundP(iData.exP.FPS,0.01)))
    	set(handles.frmCountEdit,'string','1');                         
    	set(setObjEnable(handles.editFrameStep,'on'),...
                            'string',num2str(iData.cStp))
        set(setObjEnable(handles.menuCorrectTrans,'off'),'checked','off')
    	setObjEnable(handles.textFrameStep,'on')
        setObjEnable(handles.menuWinsplit,'on')
        
        % updates the display image
        dispImage(handles);      
        
        % disables the detect tube button
        if iMov.isSet
            % resets the plot markers
            setDetectEnable(handles,'on',[1 4])            
            initMarkerPlots(handles)
            set(handles.checkShowTube,'value',1)
        else
            % deletes the temporary image stacks        
            deleteAllMarkers(handles)
        end          
        
    case ('PostSolnLoad') % case is before opening a solution file    
        
        % determines if the positional data has been determined
        if varargin{1}        
            % turns all the menu items
            setMenuEnable(handles,'on')                                
            if ~isempty(pData)
                % can view everything
                iData.Status = 2;
                if any(iMov.vPhase < 3)
                    setDetectEnable(handles,'on')                                
                    if ~iMov.calcPhi
                        setDetectEnable(handles,'off',3); 
                    end 
                else
                    setDetectEnable(handles,'off')
                end
                
            elseif initDetectCompleted(iMov)
                % case is the background has been calculated only
                iData.Status = 1;
                setDetectEnable(handles,'on',[1 4 5])      
                setDetectEnable(handles,'off',2:3) 
                
            else
                % case is the sub-windows only have been set
                iData.Status = 0;
                setDetectEnable(handles,'on',[1 4])      
                setDetectEnable(handles,'off',[2:3 5])            
                
                % turns off the batch processing/view progress menu items
                setMenuEnable(handles,'off',[3 6])
            end        
            
        else
            % otherwise, initialise the plot markers
            initMarkerPlots(handles,1)            
        end
        
        % updates the translation correction menu item
        updateCTMenu(handles,iMov);     
        
        % sets the frame/movie count
        if ishandle(handles.frmCountEdit)
            set(handles.frmCountEdit,'string',num2str(iData.cFrm))
            set(handles.movCountEdit,'string',num2str(iData.cMov))
            set(handles.editScaleFactor,'string',num2str(iData.exP.sFac))
        end
        
        % updates the program data struct 
        set(hFig,'iData',iData)
        
    case ('PostSolnLoadBP') % case is before opening a solution file                               
        % determines if the positional data has been determined
        if ~isempty(pData)
            % case is the fly locations have been calculated
            setDetectEnable(handles,'on')    
            if ~pData.calcPhi
                setDetectEnable(handles,'off',3)    
            end
        elseif initDetectCompleted(iMov)
            % case is the background has been calculated only
            setDetectEnable(handles,'on',[1 4 5])      
            setDetectEnable(handles,'off',2:3)         
        else
            % case is the sub-windows only have been set
            setDetectEnable(handles,'on',[1 4])      
            setDetectEnable(handles,'off',[2 3 5])            
        end
        
        % sets the frame/movie count
        [iData.cFrm,iData.cMov] = deal(1);
        set(handles.frmCountEdit,'string',num2str(iData.cFrm))
        set(handles.movCountEdit,'string',num2str(iData.cMov))
        set(hFig,'iData',iData)        
    
    % ----------------------------------- % 
    % --- PRE/POST IMAGE SEGMENTATION --- %
    % ----------------------------------- %    
    
    case ('PreTubeDetect') 
        % case is before detecting the tube regions
        
        % ensures the 
        set(handles.checkLocalView,'value',0)
        set(setObjEnable(handles.checkShowTube,'off'),'value',0)
        set(setObjEnable(handles.checkShowMark,'off'),'value',0)
        set(setObjEnable(handles.checkShowAngle,'off'),'value',0)
        set(setObjEnable(handles.menuCorrectTrans,'off'),'checked','off')
        setDetectEnable(handles,'off')         
            
    case ('PostInitDetect') 
        % case is after detecting the tube regions
        
        % resets the show tube checkbox and enables save soln menu item
        if isCalib
            setDetectEnable(handles,'on',[1 4])      
        else
            % sets the GUI objects based on the whether or not the
            % background estimate has been calculated
            if ~pVar{1}
                if ~initDetectCompleted(iMov)
                    setDetectEnable(handles,'on',[1 4])  
                else
                    setDetectEnable(handles,'on',[1 4:5])      
                end
            else
                isFeas = any(iMov.vPhase < 3);
                setDetectEnable(handles,'on',[1 4])
                setDetectEnable(handles,eStr{1+isFeas},5)
            end
            
            % sets the frame to the initial frame & and enable the batch
            % processing menu item
            setObjEnable(handles.menuBatchProcess,'on')            
            set(handles.frmCountEdit,'string',num2str(iData.cFrm))   
            
            % sets the image correction menu flag
            updateCTMenu(handles,iMov);
        end                           
        
    case ('PreFlyDetect') % case is after detecting the fly locations 
        % turns off the tube regions
        if get(handles.checkShowMark,'Value')
            set(handles.checkShowMark,'value',0)
            checkShowMark_Callback(handles.checkShowMark, 1, handles)
            pause(0.01)        
        end
        
        % enables the tube region outline markers                            
        if strcmp(get(handles.menuViewProgress,'checked'),'off')                 
            ImgNw = getDispImage(iData,iMov,iData.cFrm,isSub);
            dispImage(handles,ImgNw,1)       
        end               
        
        % disables the corresponding menu items
        setObjEnable(handles.menuFile,'off')
        setObjEnable(handles.toggleVideo,'off');
        setMenuEnable(handles,'on',3)
        setMenuEnable(handles,'off',[4 6 7 8])
        
    case ('PostFlyDetect') % case is after detecting the fly locations 
        
        % enables the tube region outline markers
        setTrackGUIProps(handles,'UpdateFrameSelection')
        setObjEnable(handles.menuFile,'on')
        setObjEnable(handles.toggleVideo,'on');
        setMenuEnable(handles,'on')              
        
        % resets the status flag 
        iData.Status = 2;
        set(hFig,'iData',iData);                
        
        % updates the image 
        dispImage(handles)
        
    case ('PrePreBatchProcess') % case is before the batch processing
        % enables the tube region outline markers
        setDetectEnable(handles,'off',1:3)           
        
    case ('PreBatchProcess') % case is before the batch processing
        % enables the tube region outline markers
        setObjEnable(handles.toggleVideo,'off');
        
        % disables all the menu items (except the view progress item)
        hMenu = findobj(hFig,'type','uimenu');
        setObjEnable(hMenu,'off');        
        setObjEnable(handles.menuAnalysis,'on')        
        setObjEnable(handles.menuViewProgress,'on')        
        
        % updates the image
        FirstButtonCallback(handles.frmFirstButton,[],handles)

    case ('PostBatchProcess') % case is after the batch processing        
        hMenu = findobj(hFig,'type','uimenu');
        setPanelProps(handles.panelFrmSelect,'on')
        setObjEnable(hMenu,'on');
        
    % --- PRE/POST WINDOW SPLITTING --- %
    % --------------------------------- %           

    case ('PreWindowSplit') % case is before splitting the window  
%         % retrieves the video group indices
%         vGrp = getVidGroupIndices(iMov);
%         if isempty(vGrp)
%             % no group indices have been set, so use the first frame
%             cFrm = iData.Frm0;
%         else
%             cFrm = vGrp(1,1);
%         end
%         
%         % if the current frame doesn't match, update the data struct
%         if iData.cFrm ~= cFrm
%             set(handles.frmCountEdit,'string',num2str(cFrm))
%             set(hFig,'iData',iData)
%         end
%         
%         % updates the image
%         set(handles.movCountEdit,'string','1')
%         ImgNw = getDispImage(iData,iMov,cFrm,isSub,handles); 
%         dispImage(handles,ImgNw,1)    
        
    case ('PostWindowSplit') % case is after splitting the window        
        % enables the movie selection buttons
        setSubMovEnable(handles);    
        setMovEnable(handles,'on');
        setMenuEnable(handles,'on',1:2)                 
        setDetectEnable(handles,'on',[1 4])
        set(handles.checkShowTube,'value',1)         
        
        % disables all the metric marker check boxes and the metric
        % calculations button (i.e., the solution has been reinitialised)
        if (nargin == 2)
            % resets the status flag 
            iData.Status = 0;
            setDetectEnable(handles,'off',[2 3 5])
            set(hFig,'iData',iData,'pData',[]);        
        end                
        
    case ('PostWindowSplitCalib') % case is after splitting the window          
        % enables the movie selection buttons
        setSubMovEnable(handles);          
        setMovEnable(handles,'on');
        set(handles.movCountEdit,'string','1')                    
        
    % --- AXIS COORDINATES/GRIDLINE UPDATES --- %
    % ----------------------------------------- %                
        
    case ('AxesCoordCheck') % case is altering the axes coordinate checkbox
        % gets the state of the toggle button
        setAxesProps(handles,'label');
        
        % enables/disables the gridline check buttons (depending on the
        % values of the axes checkbox value)
        if (get(handles.axesCoordCheck,'value'))
            % enables the major/minor gridline check boxes
            setAxesEnable(handles,'on',3:4)
            set(gca,'xcolor','k','ycolor','k')
        else
            % disables the major/minor gridline check boxes
            setAxesEnable(handles,'off',3:4)
            set(gca,'xcolor','w','ycolor','w')
        end
        
        % updates the grid properties
        setAxesProps(handles,'majorgrid');
        setAxesProps(handles,'minorgrid');
        
    case ('MajorGridCheck') % case is altering the major grid checkbox
        setAxesProps(handles,'majorgrid');
        
    case ('MinorGridCheck') % case is altering the minor grid checkbox
        setAxesProps(handles,'minorgrid');        

    case ('SetAllAxesProps') % case is setting all the axes properties
        setAxesProps(handles,'label');
        setAxesProps(handles,'majorgrid');
        setAxesProps(handles,'minorgrid');                
        
    % --- FRAME/MOVIE CHANGES --- %
    % --------------------------- %
        
    case ('PlayMovie') % case is playing the movie
        % sets the visibility statuses of the play/stop buttons
        set(handles.toggleVideo,'String','Stop');

        % disables the frame index/mesh data buttons
        setFrmEnable(handles,'off',1:5)
        
    case ('StopMovie') % case is stopping the movie
        % sets the visibility statuses of the play/stop buttons
        set(handles.toggleVideo,'String','Play');
        
        % disables the frame index/mesh data buttons
        setFrmEnable(handles,'on',5:6)
        setTrackGUIProps(handles,'UpdateFrameSelection')

    case ('UpdateFrameSelection') % case is updating the frame selection buttons
        
        % retrieves the current frame from the frame counter edit box
        if isempty(varargin)
            cFrm = iData.cFrm;
        else
            cFrm = varargin{1};
        end

        % updates the manual segmentation menu item
        if isfield(handles,'menuManualReseg')
            if isempty(pData)
                % turns off the manual segmentation menu item
                setMenuEnable(handles,'off',7)
                
            elseif ~isfield(pData,'fPos')
                % turns off the manual segmentation menu item
                setMenuEnable(handles,'off',7)  
                
            else
                % otherwise, determine if there is a valid fly locations 
                % for the current frame
                [i0,j0] = find(iMov.flyok,1,'first');
                hasPos = ~isnan(pData.fPos{j0}{i0}(iData.cFrm,1));                
                setObjEnable(handles.checkShowMark,hasPos)                                                                 
                
                %
                if hasPos
                    % turns off the manual segmentation menu item
                    setMenuEnable(handles,'off',7)     
                    
                else
                    % turns off the manual segmentation menu item
                    setMenuEnable(handles,'on',7)  
                    set(handles.checkShowMark,'value',0)
                end
                
                % sets the orientation angle flag
                if iMov.calcPhi
                    hasAngle = ~isnan(pData.Phi{j0}{i0}(iData.cFrm));
                    setObjEnable(handles.checkShowAngle,hasAngle) 
                    
                    if ~hasAngle
                        set(handles.checkShowAngle,'value',0)
                    end
                end                  
            end
            
        else
            % initialisations
            markerFcn = get(hFig,'checkShowMark_Callback');
            setObjEnable(handles.buttonUseCurrent,'off')
            
            % determines if the current frame is the analysed frame
            if iData.iFrm == cFrm
                % enables all radio button and marker checkbox
                setObjEnable(handlesM.checkShowMark,'on')
                setPanelProps(handles.panelImageType,'on')
                                
            else
                % disables the associated radio/checkbox objects
                setObjEnable(handles.radioHorizRes,'off')
                setObjEnable(handles.radioVertRes,'off')                
                setObjEnable(handles.radioMetrics,'off')
                setObjEnable(handles.radioRawMetric,'off')
                setObjEnable(handlesM.checkShowMark,'off')

                % if the markers are showing, then disable
                if get(handlesM.checkShowMark,'value')
                    set(handlesM.checkShowMark,'value',0)
                    markerFcn(handlesM.checkShowMark,[],handlesM)
                end
            end
        end
        
        % check to see if any buttons need to be enabled/disabled
        if cFrm == iData.nFrm
            % if the new frame index is the last frame, disable the
            % next/last buttons and enable the first/previous buttons
            setFrmEnable(handles,'on',1:2);
            setFrmEnable(handles,'off',3:4);

            % turns off the movie play button
            if isfield(handles,'toggleVideo')
                setObjEnable(handles.toggleVideo,'off');
            end
            
        else
            % turns on the movie play button
            if isfield(handles,'toggleVideo')
                setObjEnable(handles.toggleVideo,'on');
            end

            if (cFrm == 1)
                % if the new frame index is the first frame, enable the
                % next/last buttons and disable the 1st/last buttons
                setFrmEnable(handles,'off',1:2);
                setFrmEnable(handles,'on',3:4);
            else
                % otherwise, enable all the buttons
                setFrmEnable(handles,'on',1:4);
            end
        end
        
    case ('UpdateMovieSelection') % case is updating the frame selection buttons
        % retrieves the current frame from the frame counter edit box
        cMov = iData.cMov;

        % check to see if any buttons need to be enabled/disabled
        if (cMov == iData.nMov)
            % if the new frame index is the last frame, disable the
            % next/last buttons and enable the first/previous buttons
            setMovEnable(handles,'on',1:2);
            setMovEnable(handles,'off',3:4);
            
        else
            if (cMov == 1)
                % if the new frame index is the first frame, enable the
                % next/last buttons and disable the 1st/last buttons
                setMovEnable(handles,'off',1:2);
                setMovEnable(handles,'on',3:4);
                
            else
                % otherwise, enable all the buttons
                setMovEnable(handles,'on',1:4);
            end
        end                                        
        
    % --- MISCELLANEOUS FUNCTIONS --- %
    % ------------------------------- %        

    case ('CheckReject') % case is clicking the reject apparatus checkbox
        if (get(handles.checkShowTube,'value') || ...
            get(handles.checkShowMark,'value') || ...
            get(handles.checkShowAngle,'value'))
            % updates and reshows the markers
            initMarkerPlots(handles)
        else
            % updates the markers, but makes them invisible
            initMarkerPlots(handles,1)
        end
    
        % updates the tube regions and 
        checkShowTube_Callback(handles.checkShowTube,1,handles)
        dispImage(handles)
        
    case ('PreViewProj') % case is before the projection view GUI is opened
        % sets up the division figure (if not already set)
        if (get(handles.checkSubRegions,'value'))
            removeDivisionFigure(handles.imgAxes)
        else
            set(handles.checkSubRegions,'value',1)
        end                
        
        % unchecks the image markers/region highlight check boxes
        set(handles.checkSubRegions,'value',1)
        set(handles.checkLocalView,'value',0)
        set(handles.checkShowTube,'value',0)
        set(handles.checkShowMark,'value',0)   
        set(handles.checkShowAngle,'value',0) 
        
    case('RemoveSubDivision')
        % if the sub-movies regions have been set, and the show regions
        % checkbox has been set, then disable the checkbox and remove the 
        % sub-region figure        
        if (iMov.isSet) && (get(handles.checkSubRegions,'value'))
            set(handles.checkSubRegions,'value',0);
            removeDivisionFigure(handles.imgAxes)
        end     
        
        % disables the sub-region button
        setObjEnable(handles.checkSubRegions,'off');
        
    case('EnableSubMovieObjects')        
        % enables the sub-region check box again
        if (isempty(findobj(0,'tag','figManualReseg')))
            setObjEnable(handles.checkSubRegions,'on');
        end
        
    case ('DisableAppSelect')
        % case is disabling the apparatus select panel
        setPanelProps(handles.panelAppSelect,'off')
        setObjEnable(handles.checkReject,'off')
        
    case ('EnableAppSelect')
        % case is enabling the apparatus select panel
        setPanelProps(handles.panelAppSelect,'on')
                
        % sets the object properties
        if (isempty(findobj(0,'tag','figManualReseg')) ...
                                            && ~initDetectCompleted(iMov))
            setObjEnable(handles.checkReject,'on')
        end
        
    % --- UNUSED FUNCTIONS --- %
    % ------------------------ %                
        
    case ('LoadMovieSuccess') % case is the successful solution file load
        
    case ('PreMovieSeg') % case is before segmenting the movie
        
    case ('PostMovieSeg') % case is after segmenting the movie                
        
%         % retrieves all the current figure handles
%         currFig = findall(0,'type','figure');
%         
%         % only update frame buttons enable properties if ONLY the main GUI
%         % is shown (these properties have been set elsewhere)
%         if (~any(strcmp(get(currFig,'tag'),'figNewMesh')) && (iData.nFrm > 1))
%             % check to see if any buttons need to be enabled/disabled
%             setObjEnable(handles.frmCountEdit,'on')
%             if (pVar{1} == iData.nFrm)
%                 % if the new frame index is the last frame, disable the
%                 % next/last buttons and enable the first/previous buttons
%                 setFrmEnable(handles,'on',1:2);
%                 setFrmEnable(handles,'off',3:4);
%                 
%                 % turns off the movie play button
%                 setObjEnable(handles.frmPlayButton,'off');
%             else
%                 % turns on the movie play button
%                 setObjEnable(handles.frmPlayButton,'on');
%                 if (pVar{1} == 1)
%                     % if the new frame index is the first frame, enable the
%                     % next/last buttons and disable the 1st/last buttons
%                     setFrmEnable(handles,'off',1:2);
%                     setFrmEnable(handles,'on',3:4);
%                 else
%                     % otherwise, enable all the buttons
%                     setFrmEnable(handles,'on',1:4);
%                 end
%             end
%         end     
        
    case ('UpdateData') % case is updating the data fields
%         setImgData(handles)
        
    case ('UpdateFrameProps') % case is updating the frame obj properties
%         setFrameObjProp(handles,iData,iSoln,pVar{1});
                  
    case ('PostSolnSave') % case is after saving the solution file
%         setImgData(handles,iData);           
        
end

% --- PANEL OBJECT ENABLED PROPERTY FUNCTIONS --- %
% ----------------------------------------------- %

% --- Sets the image data text string enable properties -------------------
function setImgEnable(handles,state)

% retrieves the text object label/string object handles
hTextL = findobj(handles.panelImgData,'style','text','UserData',0);
hTextS = findobj(handles.panelImgData,'style','text','UserData',1);

% sets the text string label enabled properties
for i = 1:length(hTextL)
    % sets the label/text string enabled states
    setObjEnable(hTextL(i),state);
    setObjEnable(hTextS(i),state);
    
    % resets the text strings (if state = 'off')
    if strcmp(state,'off')
        set(hTextS(i),'string','');
    end
end

% --- Sets the frame selection button enabled properties ------------------
function setFrmEnable(handles,state,ind)

% sets the object tag strings
objStr = {'frmFirstButton','frmPrevButton','frmNextButton',...
          'frmLastButton','frmCountEdit','toggleVideo'};

% sets all the indices (if none are provided)
if (nargin == 2)
    ind = 1:length(objStr);
end

% sets the states for the frame buttons and index edit box
for i = 1:length(ind)
    % sets the new object handle
    hObj = eval(sprintf('handles.%s',objStr{ind(i)}));
    
    % case is the first frame button
    setObjEnable(hObj,state)
end

% --- Sets the frame selection button enabled properties ------------------
function setMovEnable(handles,state,ind)

% sets the object tag strings
objStr = {'movFirstButton','movPrevButton','movNextButton',...
          'movLastButton','movCountEdit'};

% sets all the indices (if none are provided)
if (nargin == 2)
    ind = 1:length(objStr);
end

% sets the states for the frame buttons and index edit box
for i = 1:length(ind)
    % sets the new object handle
    hObj = eval(sprintf('handles.%s',objStr{ind(i)}));
    
    % case is the first frame button
    setObjEnable(hObj,state)
end

% --- Sets the sub-movie panel enabled properties -------------------------
function setSubMovEnable(handles,varargin)

% loads the sub-movie
iMov = get(handles.output,'iMov');
if (iMov.isSet && (nargin == 1))
    % sets the sub-movie properties strings
    setObjEnable(handles.textRowCountL,'on')
    setObjEnable(handles.textColCountL,'on')        
    set(setObjEnable(handles.textRowCount,1),'string',num2str(iMov.nRow))
    set(setObjEnable(handles.textColCount,1),'string',num2str(iMov.nCol))
    
    % enables the check boxes/buttons in the frame
    setObjEnable(handles.checkSubRegions,'on')
    setObjEnable(handles.checkLocalView,'on')
    setObjEnable(handles.checkReject,~get(handles.checkLocalView,'value'))
    
else
    % otherwise, disable all the sub-window selection buttons/check boxes
    setMovEnable(handles,'off');
    
    % sets the sub-movie properties strings
    setObjEnable(handles.textRowCountL,'off')
    setObjEnable(handles.textColCountL,'off')        
    set(setObjEnable(handles.textRowCount,'off'),'string','')
    set(setObjEnable(handles.textColCount,'off'),'string','')
    
    % enables the check boxes/buttons in the frame
    set(setObjEnable(handles.checkSubRegions,'off'),'value',0)
%     set(setObjEnable(handles.checkLocalView,'off'),'value',0)
    set(setObjEnable(handles.checkReject,'off'),'value',0)    
end

% --- Sets the frame selection button enabled properties ------------------
function setParaEnable(handles,state,ind)

% sets the object tag strings
objStr = {'FrameRate','ScaleFactor'};
a = {'text','edit'};
      
% sets all the indices (if none are provided)
if (nargin == 2)
    ind = 1:length(objStr);
end

% sets the states for the frame buttons and index edit box
for i = 1:length(ind)
    switch (objStr{ind(i)})
        % case is the analysis buttons
        case {'buttonDetectBackground','buttonDetectFly'}
            % sets the new object handle
            hObj = eval(sprintf('handles.%s',objStr{ind(i)}));
            setObjEnable(hObj,state)
            
        % case is the parameter fields            
        otherwise
            for j = 1:length(a)
                hObj = eval(sprintf('handles.%s%s',a{j},objStr{ind(i)}));
                setObjEnable(hObj,state)
            end
    end
end

% --- Sets the axes check box enable properties ---------------------------
function setDetectEnable(handles,state,ind)

% sets the object tag strings
objStr = {'checkShowTube','checkShowMark','checkShowAngle',...
          'buttonDetectBackground','buttonDetectFly'};
      
% sets all the indices (if none are provided)      
if (nargin == 2)
    ind = 1:length(objStr);
end      
      
% sets the states for the frame buttons and checkboxes     
for i = 1:length(ind)
    % sets the new object handle
    hObj = eval(sprintf('handles.%s',objStr{ind(i)}));
    
    % case is the first frame button
    if ishandle(hObj)
        setObjEnable(hObj,state)
        if (strcmp(get(hObj,'style'),'checkbox'))
            if (strcmp(state,'off'))
                set(hObj,'value',0)    
            end
        end
    end
end

% --- Sets the axes check box enable properties ---------------------------
function setAxesEnable(handles,state,ind)

% sets the object tag strings
objStr = {'axesCoordCheck','checkFixRatio',...
          'gridMajorCheck','gridMinorCheck'};

% sets all the indices (if none are provided)
if (nargin == 2)
    ind = 1:length(objStr);
end

% sets the states for the checkboxes 
for i = 1:length(ind)
    % sets the new object handle
    hObj = eval(sprintf('handles.%s',objStr{ind(i)}));
    
    % case is the first frame button
    setObjEnable(hObj,state)
    if (strcmp(state,'off'))
        set(hObj,'value',0)    
    end
end

% --- Sets the menu enable properties -------------------------------------
function setMenuEnable(handles,state,ind)

% sets the object tag strings
objStr = {'menuSaveMovie','menuSaveSoln','menuViewProgress',...
          'menuWinsplit','menuVideoFeed','menuBatchProcess',...
          'menuManualReseg','menuSplitVideo','menuCorrectTrans'};

% sets all the indices (if none are provided)
if (nargin == 2)
    ind = 1:length(objStr);
end

% sets the states for the frame buttons and index edit box
for i = 1:length(ind)
    % sets the object enabled properties
    if isfield(handles,objStr{ind(i)})
        try
            hObj = eval(sprintf('handles.%s',objStr{ind(i)}));
            setObjEnable(hObj,state);

            % removes the check (if disabling)
            if strcmp(state,'off')
                set(hObj,'Checked','off')
            end
        end
    end
end

% --- PANEL OBJECT FIELD UPDATE FUNCTIONS --- %
% ------------------------------------------- %

% --- Sets the image data text string enable properties -------------------
function setImgData(handles,iData,iMov,varargin)

% re-enables all the image detail panel objects
setImgEnable(handles,'on');

% sets the image file name
set(handles.textMovieFileS,'string',simpFileName(iData.fData.name),...
           'TooltipString',fullfile(iData.fData.dir,iData.fData.name));

% sets the image size string
if (nargin == 4)
    tFrm = iMov.sRate/iData.exP.FPS;
    [m,n] = deal(iData.sz(1),iData.sz(2));
        
    % sets the duration string
    s = seconds(iData.Tv(end)); 
    s.Format = 'dd:hh:mm:ss';
    
    % updates the text label strings
    set(handles.textFrameCountS,'string',num2str(iData.nFrm));
    set(handles.textTimeStepS,'string',sprintf('%.2f sec',tFrm));        
    set(handles.textVidDurS,'string',char(s))
    set(handles.textFrameSizeS,'string',sprintf('%i %s %i',m,char(215),n));    
end

% --- Sets the image axis properties --------------------------------------
function setAxesProps(handles,axProp)

% retrieves the image axes handle
hAx = handles.imgAxes;

% sets the axis properties based on the property type
switch (axProp)
    case ('label')
        % initialisations
        pPos = get(handles.panelImg,'position');
        [X0,Y0,dX,dY,del] = deal(10,10,30,15,2);        
        
        % case is the axis label properties
        if (get(handles.axesCoordCheck,'value'))
            % turns the axis on
            axPos = [(X0+dX),(Y0+dY),pPos(3:4)-[(X0+2*dX),(Y0+2*dY)]];            
            set(hAx,'XTickLabelMode','auto','YTickLabelMode','auto',...
                    'XTickMode','auto','YTickMode','auto','box','on',...
                    'Position',axPos);
        else
            % turns the axis off
            axPos = [X0-del,Y0-del,pPos(3:4)-[2*X0,2*Y0]];
            set(hAx,'xtick',[],'ytick',[],'xticklabel',[],...
                    'yticklabel',[],'Position',axPos);
        end
    case ('majorgrid')
        % case is the axis gridlines
        if (get(handles.gridMajorCheck,'value'))
            % turns the gridlines on
            set(hAx,'XGrid','on','YGrid','on');
        else
            % turns the gridlines off
            set(hAx,'XGrid','off','YGrid','off');
        end
    case ('minorgrid')
        % case is the axis gridlines
        if (get(handles.gridMinorCheck,'value'))
            % turns the gridlines on
            set(hAx,'XMinorGrid','on','YMinorGrid','on');
        else
            % turns the gridlines off
            set(hAx,'XMinorGrid','off','YMinorGrid','off');
        end
end

% --- OTHER UNSORTED FUNCTIONS --- %
% -------------------------------- %

% --- sets the object properties based on the frame properties ------------
function setFrameObjProp(handles,iData,iSoln,cFrmL)

%
if (iData.Status > 0) && (isstruct(iSoln))
    % sets the image/pippete position struct/array
    Img = iSoln.Img(cFrmL);
    GC = iSoln.GC(cFrmL);
    PP = iSoln.PP(cFrmL);
    
    % sets the pippete position
    if (~isempty(PP.pPos))
        try
            pPos = PP.pPos;
        catch
            pPos = {};
        end
    else
        pPos = {};
    end
    
    % check to see that the current frame is viable
    if (Img.ok)
        % if so, then set the button/menu properties based on the current
        % frame status
        
        % ensures that the show ROI mesh checkbox is enabled
        setMeshEnable(handles,'on',5)
        if (isempty(iData.I))
            setDispEnable(handles,'on',2)
        else
            setDispEnable(handles,'on',1:2)
        end
        
        % --- GC Outline Check --- %
        % ------------------------ %
        
        % check to see that the current frame outline has been calculated
        if (~isempty(Img.B))
            % if the outline has been calculated, then enable the GC
            % outline check box
            setDispEnable(handles,'on',3);
            if (get(handles.radioGlobal,'value'))
                % if the image is global, then disable the binary check
                setDispEnable(handles,'off',4,0)
            else
                % if the image is local, then enable the binary check
                setDispEnable(handles,'on',4)
            end
        else
            % otherwise, disable the GC outline/Binary mask check boxes
            setDispEnable(handles,'off',3:4,0);
        end
        
        % --- GC Centre Check --- %
        % ----------------------- %
        
        % check to see if the GC centre coordinates have been set
        if (~isempty(GC.x))
            % if the GC coordinate has been set, then enable the check box
            setDispEnable(handles,'on',5)
        else
            % otherwise, disable the check box
            setDispEnable(handles,'off',5,0)
        end
        
        % --- Axon Bearing Check --- %
        % -------------------------- %
        
        % check to see if the GC centre coordinates have been set
        if (~isempty(iSoln.Axon))
            if (~isempty(iSoln.Axon(cFrmL).xpOut))
                % if the GC coordinate has been set, then enable the check box
                setDispEnable(handles,'on',6)
            else
                % otherwise, disable the check box
                setDispEnable(handles,'off',6,0)
            end
        else
            % otherwise, disable the check box
            setDispEnable(handles,'off',6,0)
        end
        
        % --- Pipette Location Check --- %
        % ------------------------------ %
        
        % check to see if the Pippete Location coordinates have been set
        if (~isempty(pPos))
            % if the coordinates have been set, then enable the check box
            if (get(handles.radioGlobal,'value'))
                setDispEnable(handles,'on',7)
            else
                setDispEnable(handles,'off',7,0)
            end
        else
            % otherwise, disable the check box
            setDispEnable(handles,'off',7,0)
        end
    else
        setDispEnable(handles,'off',1:7,0);
        setMeshEnable(handles,'off',5)
    end
else
    % if the mesh has not been calculated, then disable all the
    % mesh/display button options
    setDispEnable(handles,'off',1:7,0);
    setMeshEnable(handles,'off',5)
end

% --- disables all the necessary object properties (for mesh --------------
%     setting and an other analysis type) ---------------------------------
function disableAllObjProps(handles)

% disables the frame selection, mesh setting, analysis and other objects
setImgEnable(handles,'off')
setFrmEnable(handles,'off')
setParaEnable(handles,'off')
setAxesEnable(handles,'off')

% --- disables all the GUI objects
function disableAllObjects(handles)

% resets the GUI object enabled properties
setAnalysisEnable(handles,'off')
setAxesEnable(handles,'off');
setDispEnable(handles,'off')
setExptEnable(handles,'off');
setFrmEnable(handles,'off')
setImgEnable(handles,'off');
setMeshEnable(handles,'off')
setMenuEnable(handles,'off')  

% --- reshapes the GUI to account for the calibration setup
function reshapeCalibObjects(handles)

% parameters and initialisations
dY1 = 60;
frmPos = get(handles.panelFrmSelect,'position');
expPos = get(handles.panelExptPara,'position');

% % deletes the menu items
% delete(handles.menuRTTrack)
% delete(handles.menuRTPara)

% deletes the required panels
delete(handles.panelFrmSelect);
delete(handles.panelExptPara);

% deletes the items within the markers panels and resizes
delete(handles.checkShowAngle)
delete(handles.buttonDetectBackground)
delete(handles.buttonDetectFly)

resetObjPos(findall(handles.panelFlyDetect,'style','checkbox'),'bottom',-dY1,1)
resetObjPos(handles.panelFlyDetect,'height',-dY1,1)

%
resetObjPos(handles.panelAppInfo,'bottom',frmPos(4),1)
resetObjPos(handles.panelFlyDetect,'bottom',frmPos(4)+expPos(4)+dY1,1)
resetObjPos(handles.panelAxProp,'bottom',frmPos(4)+expPos(4)+dY1,1)

%
hEdit = findall(handles.panelTrackPara,'style','edit');
for i = 1:length(hEdit)
    hObj = hEdit(i);
    cbFcn = @(hObj,eventdata)FlyTrack...
                        ('editAlterAnalysisPara',hObj,eventdata,handles);
    set(hObj,'Callback',cbFcn);
end

% --- updates the correct translation menu item enabled properties
function updateCTMenu(handles,iMov)

% initialisations
[chkStr,hasTrans] = deal({'off','on'},false);

% determines if the there are any translation phases
if isfield(iMov,'dpInfo') && ~isempty(iMov.dpInfo)
    hasTrans = ~isempty(iMov.dpInfo);
end

% updates the translation correction menu flag
hMenuCT = handles.menuCorrectTrans;
set(setObjEnable(hMenuCT,hasTrans),'Checked',chkStr{1+hasTrans})
