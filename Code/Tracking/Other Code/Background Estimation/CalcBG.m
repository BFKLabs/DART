classdef CalcBG < handle
    
    % class properties
    properties
        
        % input argument objects
        hGUI       
        hFig
        hAx
        iMov
        iData
        iPara       
        
        % tracking class object
        trkObj        
        
        % initial main gui properties
        iMov0
        hProp0        
        ImgFrm0
        ImgC
        ok0
        vPhase0
        
        % array dimensioning
        nApp
        nTube              
        
        % global flags 
        is2D
        isDD  
        isCalib
        isVisible
        isChange
        isMTrk
        frameSet        
        hasUpdated
        isBGCalc
        uList
        fUpdate
        isAllUpdate
        nManualMx   
        iSel                
        
        % temporary markers/objects
        hInfo
        hMark
        hMarkAll
        hManual
        hManualB
        hManualH
        hMenuBG
        jTable
        Imap
        pMn
        mInfo
        ImgM
        hProg
        hPropT
        
        % manual tracking fields
        pCol0
        iCloseR
        iCloseSR
        iCloseF
        
        % other important fields  
        mSz
        Ibg
        pBG
        fPos
        IPos
        indFrm
        BgrpT        
        axPosX 
        axPosY
        pStats
        iFrm    
        vcObj
        statsObj
        phaseObj
        dpOfs       
        cMapJet
        isUpdating
        
        % fixed variables
        ivRej = 5;
        feasInd = [1,2,4];
        
    end
    
    % class methods
    methods
        
        % --- object constructor
        function obj = CalcBG(hGUI)
            
            % global variables
            global isCalib
            
            % sets the input arguments
            obj.hGUI = hGUI;
            obj.isCalib = isCalib;  
            
            % important object handles
            obj.hFig = obj.hGUI.figFlyTrack;
            obj.hAx = obj.hGUI.imgAxes;                        
            
            % initialises the other fields
            obj.isVisible = false;
            obj.isUpdating = false;
            
            % initialises the GUI objects
            obj.initObjectCallbacks()  
            obj.calcAxesGlobalCoords()                        
                     
        end         
        
        % ---------------------------------- %
        % ---- GUI OPEN/CLOSE FUNCTIONS ---- %
        % ---------------------------------- %        
        
        % --- opens the background analysis gui
        function openBGAnalysis(obj)
            
            % global parameters
            global updateFlag
            updateFlag = 2;
            
            % makes the main gui invisible
            setObjVisibility(obj.hFig,'off'); pause(0.05);
            
            % stops the camera (if running)
            if obj.isCalib
                infoObj = get(obj.hFig,'infoObj');  
                if ~infoObj.isTest
                    if strcmp(get(infoObj.objIMAQ,'Running'),'off')
                        start(infoObj.objIMAQ); pause(0.05); 
                    end                
                end
            else
                % toggles the normal/background estimate panel visibilities
                obj.resetGUIDimensions(true)                 
            end                         
            
            % initialises the class fields
            obj.initClassFields()
            obj.initLikelyPlotMarkers()
            obj.isVisible = true;
            
            % updates the properties based on the tracking type
            if obj.isCalib                
                % determines if the video calibration object is set
                if isempty(obj.vcObj)
                    % if not, then initialise the object
                    obj.vcObj = BGCalibObj(obj.hFig);
                else
                    % otherwise, open the calibration view
                    obj.vcObj.openCalibView();
                end
                
                % sets the file menu items
                obj.setMenuVisibility(true);
                setObjVisibility(obj.hGUI.menuPhaseStats,0);
                setObjVisibility(obj.hGUI.menuShowStats,0);
                
            else
                % case is normal video tracking
                obj.initObjProps()        
                obj.setManualObjProps('off')                
                obj.updateManualTrackTable()
            end
            
            % makes the main gui visible again
            pause(0.05);
            setObjVisibility(obj.hFig,'on');               
            
            % resets the update flag
            pause(0.1);
            updateFlag = 0;            
            
        end        
        
        % --- close the background analysis gui
        function closeBGAnalysis(obj)
            
            % global variables
            global isMovChange updateFlag
                        
            % initialisations
            hgui = obj.hGUI;
            updateFlag = 2;
            
            % removes the menu check
            hh = guidata(obj.hFig);
            if strcmp(get(hh.menuFlyAccRej,'Checked'),'on')            
                obj.menuFlyAccRej(hh.menuFlyAccRej, [])
            end
            
            % makes the tracking menu item invisible again
            if isprop(obj.trkObj,'hMenuM')
                obj.trkObj.closeBG();                
            end
            
            % makes the main tracking gui invisible
            setObjVisibility(obj.hFig,'off'); pause(0.05);
            
            % ---------------------------------- %
            % ---- MAIN FIGURE IMAGE UPDATE ---- %
            % ---------------------------------- %            
            
            % if changes are made and accepted, then update the struct
            if obj.isChange
                % updates the fields in the tracking GUI
                isMovChange = true;
                set(obj.hFig,'pData',[])
                set(obj.hFig,'iMov',obj.iMov) 
                setObjEnable(obj.hGUI.checkShowMark,'off')
            else
                % otherwise, reset to the original sub-region data struct
                set(obj.hFig,'iMov',obj.iMov0)                        
            end                

            % closes the phase statistics information GUI (if open)
            if ~isempty(obj.phaseObj)
                obj.menuPhaseStats(obj.hGUI.menuPhaseStats,[]);
            end
            
            % closes the statistics information GUI (if open)
            if ~isempty(obj.statsObj)
                obj.menuShowStats(obj.hGUI.menuShowStats,[]);
            end            
            
            % update axes with the original image (non-calibrating only)
            if obj.isCalib
                % stops the camera (if running)
                infoObj = get(obj.hFig,'infoObj'); 
                if ~infoObj.isTest
                    if strcmp(get(infoObj.objIMAQ,'Running'),'on')
                        stop(infoObj.objIMAQ); pause(0.05); 
                    end
                end
                
                % runs the calibration 
                setObjVisibility(obj.vcObj.hPanelO,0);
                
            else
                dispFcn = get(obj.hFig,'dispImage');
                dispFcn(hgui,obj.ImgFrm0,1)
            end                           

            % -------------------------------- %
            % ---- FIGURE/OBJECT DELETION ---- %
            % -------------------------------- %
            
            % retrieves the currently opened figures
            hFigAll = findall(0,'type','figure');  

            % updates the colormap type
            colormap(obj.hAx,'gray');            
            
            % removes any manual selection properties
            obj.manualButtonClick([], 'alt')
            
            % deletes the background parameter GUI (if it is open) 
            iBP = strcmp(get(hFigAll,'tag'),'figBGPara'); 
            if any(iBP); delete(hFigAll(iBP)); end

            % deletes the classification statistics GUI (if it is open)
            iCS = strcmp(get(hFigAll,'tag'),'figClassStats');
            if any(iCS); delete(hFigAll(iCS)); end

            % removes the information GUI (if showing)
            if ~isempty(obj.hInfo) 
                try delete(obj.hInfo); catch; end
                obj.hInfo = [];
            end        
            
            % retrieves the manual marker objects
            obj.deleteManualMarkers();  
            
            % deletes any manual markers
            if ~isempty(obj.hManual)
                delete(obj.hManual)
                obj.hManual = [];
            end
            
            % loops through all the regions deleting the markers
            for i = 1:length(obj.hMark)
                % deletes any previous markers
                hMarkPr = findobj(obj.hAx,'tag',sprintf('hFlyTmp%i',i));
                if ~isempty(hMarkPr)
                    delete(hMarkPr)
                end                      
            end
            
            % deletes any previous markers
            hMarkAllPr = findobj(obj.hAx,'tag','hFlyAll');
            if ~isempty(hMarkAllPr)
                delete(hMarkAllPr)
            end                              

            % temporary field deletion            
            obj.BgrpT = [];
            
            % -------------------------------- %
            % ---- OTHER PROPERTY UPDATES ---- %
            % -------------------------------- %      

            % removes the tube regions (if showing)
            set(obj.hGUI.checkTubeRegions,'value',0);
            obj.checkTubeRegions(obj.hGUI.checkTubeRegions, [])

            % turns on the local viewing panel
            chkFunc = get(obj.hFig,'checkLocalView_Callback');
            chkFunc(obj.hGUI.checkLocalView, 1, obj.hGUI)

            % updates the axis colour limit
            set(obj.hGUI.imgAxes,'CLimMode','Auto')
            
            % sets the pre-background detection properties
            setTrackGUIProps(obj.hGUI,'PostInitDetect',obj.isChange);
            
            % clears the class fields
            obj.clearClassFields()
            
            % -------------------------------------- %            
            % ---- FINAL FIGURE RE-DIMENSIONING ---- %
            % -------------------------------------- %
            
            % toggles the normal/background estimate panel visibilities
            obj.resetGUIDimensions(false)
            obj.isVisible = false;
            set(obj.hGUI.figFlyTrack,'bgObj',obj)
                                   
            % sets the menu item visibiity properties
            setObjVisibility(hgui.panelBGDetect,'off') 
            setObjVisibility(hgui.panelOuter,'on') 
            obj.setMenuVisibility(false);                      
            
            % makes the main tracking gui visible again
            setObjVisibility(obj.hFig,'on'); 
            
            % resets the update flag
            pause(0.1);
            updateFlag = 0;

        end        
        
        % -------------------------------------------- %
        % ---- MANUAL TRACKING CALLBACK FUNCTIONS ---- %
        % -------------------------------------------- %      
        
        % --- callback function for mouse movement
        function manualTrackMotion(obj, ~, ~)
            
            % only update the marker colours if over the axes
            if obj.isOverImageAxes()
                obj.updateMarkerProps();
            end            
            
        end
        
        % --- callback function for mouse button click
        function manualButtonClick(obj, hObject, eventdata)
            
            % sets the selection type (based on input)
            if ischar(eventdata)
                % function is being used directly
                selType = eventdata;
            else
                % function is called from a callback
                selType = get(obj.hFig,'SelectionType');
            end

            % performs the action based on the selection type
            switch selType                    
                case 'normal'
                    % case is the user left-clicked mouse                    
                    if obj.iCloseF > 0
                        % creates the new list item
                        rInd = [obj.iCloseR,obj.iCloseSR];
                        uListNw = [obj.iPara.cPhase,obj.iPara.cFrm,rInd];
                        
                        % if the selection already exists, then exit
                        if ~isempty(obj.uList)                            
                            if any(cellfun(@(x)(isequal(x,uListNw)),...
                                                num2cell(obj.uList,2)))
                                % if a manual marker already exists for
                                % this region, then output an error msg
                                eStr = sprintf(['Manual marker already ',...
                                    'exists for this sub-region.\n',...
                                    'Delete the existing marker from ',...
                                    'the list before proceeding.']);
                                waitfor(msgbox(eStr,...
                                  'Manual Marker Already Exists!','modal'))
                                
                                % exit the function
                                setObjEnable(obj.hGUI.buttonAddManual,1)
                                return
                            end
                        end
                        
                        % appends the list item to the table
                        obj.uList = [obj.uList;uListNw];
                        obj.updateManualTrackTable();
                        obj.addManualMarker(uListNw);
                        
                        % turns off the highlight marker
                        set(obj.hManualH,'UserData',[]);
                        setObjVisibility(obj.hManualH,'off')                                              
                        
                        % disables everything else
                        obj.manualButtonClick(hObject, 'alt')
                        obj.setManualDetectEnable;
                    end
                    
                case 'alt'
                    % case is the user right-clicked mouse
                    
                    % removes the motion/button down callback functions
                    set(obj.hFig,'WindowButtonDownFcn',[])
                    set(obj.hFig,'WindowButtonMotionFcn',[])
                    set(obj.hFig,'Pointer','arrow');
                    
                    % makes the button active again
                    setObjEnable(obj.hGUI.buttonAddManual,'on')
                    setObjEnable(obj.hGUI.buttonUpdateManual,...
                                 ~isempty(obj.uList))
                    
                    % if there is a marker-highlighted, then remove it
                    obj.updateTubeHighlight([]); 
                    obj.deleteManualMarkers()
                    
                    % updates the other properties
                    obj.setGUIObjProps('on');                      
                    
            end
            
        end        
        
        % --- updates the manual tracking plot table
        function updateManualTrackTable(obj)
            
            % sets the new table data
            if isempty(obj.uList)
                Data = [];
            else
                Data = num2cell(obj.uList);
            end   
            
            % sets the new data into the table            
            setHorizAlignedTable(obj.hGUI.tableFlyUpdate,Data);
            setObjEnable(obj.hGUI.tableFlyUpdate,~isempty(Data))
            
            % sets the object enabled properties
            setObjEnable(obj.hGUI.buttonRemoveManual,'off')
            setObjEnable(obj.hGUI.buttonUpdateManual,~isempty(Data));
            
        end                         
                 
        % ----------------------------------------- %
        % ---- OBJECT INITIALISATION FUNCTIONS ---- %
        % ----------------------------------------- %
            
        % --- initialises the GUI objects
        function initObjectCallbacks(obj)
            
            % objects with normal callback functions
            cbObj = {'menuPara','menuFlyAccRej','menuCloseEstBG',...
                     'menuPhaseStats','menuShowStats',...
                     'buttonUpdateStack','frmFirstPhase','frmPrevPhase',...
                     'frmNextPhase','frmLastPhase','editPhaseCount',...      
                     'frmFirstFrame','frmPrevFrame','frmNextFrame',...
                     'frmLastFrame','editFrameCount','checkTrackPhase',...
                     'checkFilterImg','editFilterSize','popupImgType',...
                     'checkTubeRegions','checkFlyMarkers',...
                     'buttonUpdateEst','buttonAddManual',...
                     'buttonRemoveManual','buttonUpdateManual'};                   
            for i = 1:length(cbObj)
                hObj = eval(sprintf('obj.hGUI.%s;',cbObj{i}));
                if ishandle(hObj)
                    cbFcn = eval(sprintf('@obj.%s',cbObj{i}));
                    set(hObj,'Callback',cbFcn)
                end
            end            
                 
            % objects with cell selection callback functions
            csObj = {'tableFlyUpdate'};
            for i = 1:length(csObj)
                hObj = eval(sprintf('obj.hGUI.%s;',csObj{i}));
                if ishandle(hObj)
                    cbFcn = eval(sprintf('@obj.%s',csObj{i}));
                    set(hObj,'CellSelectionCallback',cbFcn)
                end
            end                 
            
        end                           
        
        % --- initialises the class fields when starting bg detection mode
        function initClassFields(obj)
            
            % retrieves the sub-region/program data structs
            [obj.iMov,obj.iMov0] = deal(get(obj.hFig,'iMov'));
            obj.iData = get(obj.hFig,'iData');   
            obj.iPara = obj.initParaStruct(10);             
            obj.isMTrk = detMltTrkStatus(obj.iMov);
            
            % sets the 2D region flag
            if isfield(obj.iMov,'is2D')
                obj.is2D = obj.iMov.is2D;
            else
                [obj.is2D,obj.iMov.is2D] = deal(is2DCheck(obj.iMov));
            end
            
            % retrieves the current image dimensions
            frmSz = getCurrentImageDim(obj.hGUI);
            
            % sets up the detection parameter struct
            if isfield(obj.iMov,'bgP')
                % if the field does exist, then ensure it is correct
                obj.iMov.bgP = ...
                        DetectPara.resetDetectParaStruct(obj.iMov.bgP);
            else
                % field doesn't exist, so create initialise
                obj.iMov.bgP = DetectPara.initDetectParaStruct('All');                
            end
            
            % creates the tracking object based on the tracking type
            if strContains(obj.iMov.bgP.algoType,'single')
                % case is tracking single objects
                obj.trkObj = SingleTrackInit(obj.iData);
            else
                % case is tracking multiple objects                
                obj.trkObj = feval('runExternPackage',...
                                   'MultiTrack',obj.iData,'Init');
            end
            
            % sets the calibration field
            set(obj.trkObj,'isCalib',obj.isCalib);
            
            % initial main gui properties
            obj.ok0 = obj.iMov.flyok;
            obj.hProp0 = getHandleSnapshot(obj.hGUI);
            if ~obj.isCalib
                % retrieves the image data from the current axis
                hImage = findobj(obj.hGUI.imgAxes,'type','image');
                obj.ImgFrm0 = get(hImage,'cdata');                 
            end            
            
            % initialises the index fields            
            obj.isDD = isDirectDetect(obj.iMov);            
            obj.nApp = length(obj.iMov.iR);
            obj.nTube = getSRCountVec(obj.iMov);            
            
            % sets the inside/outside subregion masks
            BgrpT0 = cell(length(obj.iMov.iR),1);
            for i = 1:length(obj.iMov.iR)
                Btmp = false(frmSz); 
                Btmp(obj.iMov.iR{i},obj.iMov.iC{i}) = true; 
                BgrpT0{i} = bwmorph(bwmorph(Btmp,'dilate'),'remove');
            end            
            
            % sets the bg menu item handle array
            obj.hMenuBG = [obj.hGUI.menuFileBG,...
                           obj.hGUI.menuEstBG,...
                           obj.hGUI.menuView];
            
            % initialises the other class fields 
            obj.hManual = [];
            [obj.iSel,obj.BgrpT] = deal([1,1],BgrpT0);
            [obj.isChange,obj.frameSet] = deal(false);
            [obj.hasUpdated,obj.isBGCalc] = deal(false);
            [obj.uList,obj.fUpdate] = deal([]);
            [obj.isAllUpdate,obj.nManualMx] = deal(true,10);
            
        end        
        
        % --- initialises the bg estimation object properties
        function initObjProps(obj)

            % other initialisations
            isFeas = false;
            eStr = {'off','on'};            
            cHdr = {'Phase','Frame','Region','Sub-Region'};

            % sets the pre-background detection properties
            setTrackGUIProps(obj.hGUI,'PreTubeDetect');

            % toggles the normal/background estimate panel visiblities
            setObjVisibility(obj.hGUI.panelOuter,'off')
            setObjVisibility(obj.hGUI.panelBGDetect,'on')            
            obj.setMenuVisibility(true);
            
            % updates the frame/edit count count
            setPanelProps(obj.hGUI.panelPhaseSelect,'off')
            setPanelProps(obj.hGUI.panelFrameSelect,'off')
            setPanelProps(obj.hGUI.panelManualSelect,'off')
            set(obj.hGUI.menuCorrectTrans,'Checked','off')

            % updates the table position
            tPos = get(obj.hGUI.tableFlyUpdate,'position');
            tPos(4) = calcTableHeight(obj.nManualMx);
            set(setObjEnable(obj.hGUI.tableFlyUpdate,'off'),...
                       'Data',[],'Position',tPos,'ColumnName',cHdr)
            autoResizeTableColumns(obj.hGUI.tableFlyUpdate);

            % sets the image parameter object fields
            bgP = obj.getTrackingPara();            
            set(obj.hGUI.checkFilterImg,'Value',bgP.useFilt)
            set(obj.hGUI.editFilterSize,'String',num2str(bgP.hSz),...
                                    'Enable',eStr{1+bgP.useFilt})
            obj.updateImgTypePopup(true);         
            
            % if the phase info field is not set, then create one
            if ~isfield(obj.iMov,'phInfo')
                obj.iMov.phInfo = [];
            end
            
            % determines if the phase/initial detection is complete            
            initDetected = initDetectCompleted(obj.iMov);
            phaseDetected = ~isempty(obj.iMov.phInfo); % || initDetected;
            
            % determines if any of the detected phses are trackable
            if phaseDetected
                isFeas = any(obj.detFeasPhase());
            end
                            
            % flag whether the update button is enabled
            canUpdate = (phaseDetected && isFeas) || obj.isCalib;
            
            % sets the phase stats menu item (if info is available)
            setObjEnable(obj.hGUI.menuPhaseStats,phaseDetected)
            setObjEnable(obj.hGUI.buttonUpdateStack,~obj.isCalib)
            setObjEnable(obj.hGUI.buttonUpdateEst,canUpdate)
            setPanelProps(obj.hGUI.panelImageType,phaseDetected)
            
            % sets the phase detection related object properties
            if phaseDetected
                % sets the frame index arrays
                obj.vPhase0 = obj.iMov.vPhase;
                nPhase = length(obj.iMov.vPhase);
                obj.indFrm = getPhaseFrameIndices...
                                            (obj.iMov,obj.trkObj.nFrmR);                                                                          
                                        
                % enables the phase panel properties (if more than one phase       
                setPanelProps(obj.hGUI.panelPhaseSelect,'on')
                setPanelProps(obj.hGUI.panelFrameSelect,'on');
                setPanelProps(obj.hGUI.panelVideoInfo,'on');
                obj.setButtonProps('Phase')
                obj.setButtonProps('Frame') 
                
                % sets the other field properties
                obj.setVideoInfoProps()
                iFrm0 = num2str(obj.indFrm{1}(1));
                set(obj.hGUI.editFrameCount,'string','1')          
                set(obj.hGUI.textCurrentFrame,'string',iFrm0)                
                
            else
                % clears the frame count string
                set(obj.hGUI.editFrameCount,'string','')               
                set(obj.hGUI.editPhaseCount,'string','')     
                
                % sets the quality/translation strings
                if obj.isCalib
                    lblStr = 'Calibrating';
                else
                    lblStr = 'N/A';
                end
                
                % sets the phase count and variance type
                set(obj.hGUI.textImagQual,'string',lblStr,...
                                      'ForegroundColor','k');
                set(obj.hGUI.textTransStatus,'string',lblStr,...
                                         'ForegroundColor','k');
                set(obj.hGUI.textPhaseCount,'string','N/A');
                set(obj.hGUI.textPhaseFrames,'string','N/A');    
                set(obj.hGUI.textPhaseStatus,'string','N/A'); 
                
                % updates the text fields
                set(obj.hGUI.textStartFrame,'string','N/A')
                set(obj.hGUI.textEndFrame,'string','N/A')                
                set(obj.hGUI.textCurrentFrame,'string','N/A')    
            end
            
            % determines if the background has been calculated
            if initDetected
                % sets the frame count stringx1                     
                setObjEnable(obj.hGUI.menuShowStats,'on');
                set(setObjEnable(obj.hGUI.checkFlyMarkers,'on'),'value',1)                      
                
                % determines if the class object has location values
                if ~isempty(obj.fPos)                    
                    % retrieves the positional data from the main gui
                    pData0 = get(obj.hGUI.figFlyTrack,'pData');
                    if ~isempty(pData0)                    
                        % if there is positional data, then store the
                        % position values for the 1st frame of each phase
                        obj.fPos = cell(nPhase,1);
                        
                        % calculates the region vertical offsets
                        yOfs = cellfun(@(ir,n)(repmat(...
                                [0,ir(1)]-1,n,1)),obj.iMov.iR,...
                                num2cell(obj.nTube)','un',0)';
                        
                        % memory allocation                        
                        for i = 1:nPhase
                            % retrieves the position data 
                            iFrmNw = obj.indFrm{i};
                            obj.fPos{i} = cell(obj.nApp,length(iFrmNw));
                            
                            for j = 1:length(iFrmNw)                            
                                obj.fPos{i}(:,j) = ...
                                    cellfun(@(y,dy)(dy+cell2mat(...
                                    cellfun(@(x)(x(iFrmNw(j),:)),y(:),...
                                    'un',0))),pData0.fPos(:),yOfs,'un',0);
                            end
                        end    
                    end
                    
                    % initialises the potential plot markers
                    obj.initPotentialPlotMarkers()                      

                    % updates the 
                    obj.updateObjMarkers()
                    obj.checkFlyMarkers(obj.hGUI.checkFlyMarkers, [])
                    obj.updateMainImage()      
                end
            else
                % if not, disable the frame selection panels                
                set(setObjEnable(obj.hGUI.checkFlyMarkers,0),'Value',0)
                set(setObjEnable(obj.hGUI.menuShowStats,0),'Checked','off')                                 
            end            
            
        end
        
        % --- initialises the likely object markers
        function initLikelyPlotMarkers(obj)

            % sets focus to the main GUI axes
            set(obj.hGUI.figFlyTrack,'CurrentAxes',obj.hGUI.imgAxes)
            
            % sets up the region parameters (based on tracking type)
            if obj.isMTrk
                % case is multi-tracking
                [nRw,nCl] = deal(obj.iMov.pInfo.nRow,obj.iMov.pInfo.nCol);
                [nReg,nTubeR] = deal(nRw*nCl,obj.iMov.pInfo.nFly');
                iReg = 1:nReg;
            else
                % case is single-tracking
                nReg = length(obj.iMov.ok);
                iReg = find(obj.iMov.ok(:)');
                nTubeR = obj.nTube;
            end
            
            % memory allocation
            obj.hMark = cell(1,nReg);            

            % loops through all the sub-regions creating markers 
            hold on
            for i = iReg
                % memory allocation
                tStr = sprintf('hFlyTmp%i',i);
                obj.hMark{i} = cell(nTubeR(i),1);

                % deletes any previous markers
                hMarkPr = findobj(obj.hAx,'tag',tStr);
                if ~isempty(hMarkPr); delete(hMarkPr); end    

                % creates the markers for all the tubes
                for j = 1:nTubeR(i)
                    obj.hMark{i}{j} = plot(NaN,NaN,'tag',tStr,...
                                        'linestyle','none','visible',...
                                        'off','UserData',[i,j]);
                end
            end
            
            % turns the axes hold off
            hold off                  
            
        end                                   
        
        % --- initialises the potential object markers
        function initPotentialPlotMarkers(obj)
            
            % retrieves the sub-movie data struct
            hgui = obj.hGUI;                         
            
            % sets focus to the main GUI axes
            set(hgui.figFlyTrack,'CurrentAxes',hgui.imgAxes) 
            
            % deletes any previous markers
            hMarkPr = findobj(obj.hAx,'tag','hFlyAll');
            if ~isempty(hMarkPr); delete(hMarkPr); end               
            
            % loops through all the sub-regions creating markers 
            hold(obj.hAx,'on')
            obj.hMarkAll = scatter(obj.hAx,NaN,NaN,'k','tag','hFlyAll');
            hold(obj.hAx,'on')
            
        end
        
        % --- updates the image type popupmenu properties
        function isChange = updateImgTypePopup(obj,isInit)
            
            % sets the default input argument
            isChange = false;
            if ~exist('isInit','var'); isInit = false; end
            
            % base image type (raw image only)
            cPh = obj.iPara.cPhase;            
            hPopup = obj.hGUI.popupImgType;
            popStr = {'Raw Image';'Smoothed Image'};
            
            % sets up the special analysis flag
            if isfield(obj.iMov,'vPhase')
                isSpecial = obj.iMov.vPhase(cPh) == 4;
            else
                isSpecial = false;
            end
            
            % case is the background has been calculated
            if ~isempty(obj.iMov.Ibg)
                if ~isempty(obj.iMov.Ibg{cPh})
                    if isSpecial
                        popStrNw = {'Residual (Filtered)'};
                    
                    elseif ~isfield(obj.trkObj,'IbgT0') || ...
                            isempty(obj.trkObj.IbgT0)
                        popStrNw = {'Background';...
                                    'Residual (Filtered)';...
                                    'Cross-Correlation'};
                    else
                        popStrNw = {'Background (Raw)';...
                                    'Background (Filled)';...
                                    'Residual (Filled)';...
                                    'Cross-Correlation'};
                    end
                            
                    % adds the strings to array
                    popStr = [popStr;popStrNw(:)];
                end
            end
            
            % case is the cross-correlation template has been provided
            if isfield(obj.iMov,'tPara')
                if ~isempty(obj.iMov.tPara)
                    popStrNw = {'Cross-Correlation (Normal)';...
                                'Cross-Correlation (Adjusted)'};
                    popStr = [popStr;popStrNw(:)];
                end
            end
            
            % sets the selection values
            if isInit
                % case is the gui is being initialised
                iSelNw = 1;
            else
                % otherwise, ensure the current selection is feasible
                iSel0 = get(hPopup,'Value');
                popStr0 = get(hPopup,'String');
                
                % determines the matching image type within the new strings
                iSelNw = find(strcmp(popStr,popStr0{iSel0}));
                if isempty(iSelNw)
                    % if there is no match, then reset
                    [iSelNw,isChange] = deal(1,true);
                end
            end
            
            % updates the popup parameters
            set(hPopup,'String',popStr,'Value',iSelNw)              
            
        end
        
        % --- clears the class fields
        function clearClassFields(obj)

            % clears the class fields
            [obj.iMov,obj.iMov0,obj.iData,obj.iPara] = deal([]);
            [obj.trkObj,obj.ImgFrm0,obj.BgrpT] = deal([]);
            [obj.hProp0,obj.hPropT] = deal([]);

        end        
        
        % ------------------------------- %
        % --- OBJECT UPDATE FUNCTIONS --- %
        % ------------------------------- %

        % --- updates the main image axes --- %
        function updateMainImage(obj,varargin)

            % retrieves the main GUI handles and the image display function
            hgui = obj.hGUI;
            ipara = obj.iPara;
            idata = obj.iData;

            % initialisations
            cMapType = 'gray';
            frmSz = getCurrentImageDim(hgui);
            [h,iPhase,cLim,iok] = deal([],ipara.cPhase,[],obj.iMov.ok);
            
            % retrieves the tracking parameter struct
            bgP = obj.getTrackingPara();
            hS = fspecial('disk',bgP.hSz);            
            
            % retrieves the data structs/function handles from the main GUI     
            dispImage = get(hgui.figFlyTrack,'dispImage');      
            
            % updates the empty check markers (if visible)
            hFigEmpty = findall(0,'tag','figCheckEmpty');
            if ~isempty(hFigEmpty)
                eObj = getappdata(hFigEmpty,'obj');
                eObj.updatePlotMarkers() 
            end

            % sets the table java object (if GUI is visible and handle not set)
            if obj.isVisible
                % sets the table java object into the table handle
                if isempty(obj.jTable)
                    hh = findjobj(hgui.tableFlyUpdate);
                    obj.jTable = hh.getComponent(0).getComponent(0);
                end
            end

            % determines if there are any axes markers
            if ~isempty(obj.hManual)
                % retrieves the userdata arrays from the plot markers
                uData = cell2mat(arrayfun(@(x)...
                            (get(x,'UserData')),obj.hManual(:),'un',0));

                % markers for this frame are shown (otherwise disabled)
                isShow = (uData(:,1) == ipara.cPhase) & ...
                         (uData(:,2) == ipara.cFrm);
                setObjVisibility(obj.hManual(isShow),'on')
                setObjVisibility(obj.hManual(~isShow),'off')

%                 % retrieves the index of the currently selected update point
%                 iVal = obj.jTable.getSelectedRows + 1;
%                 if isShow(iVal)
%                     % if the point is on the current image, then highlight green        
%                     set(obj.hManual(iVal),'color','y')
%                 end
            end
            
            % reads the new frame
            imgType = obj.getSelectedImageType();
            isRaw = strContains(imgType,'Raw');
            if obj.isCalib
                Img0 = obj.ImgC{1}{ipara.cFrm};
            else
                iFrmS = obj.indFrm{iPhase}(ipara.cFrm);
                Img0 = double(getDispImage(idata,obj.iMov,iFrmS,false,[],1));                                
            end
            
            % sets the image            
            switch imgType
                case 'Raw Image'
                    % case is the raw image frame 
                    Inw = Img0;

                case 'Smoothed Image'
                    % case is the filtered image frame 
                    Inw = imfiltersym(Img0,hS);    

                case {'Background',...
                      'Background (Raw)',...
                      'Background (Filled)'} 
                    % case is the background estimate                    

                    if size(Img0,3) == 3
                        Img0 = double(rgb2gray(uint8(Img0)));
                    end
                    
                    % sets the background image based on the detection type
                    if strcmp(getDetectionType(obj.iMov),'GeneralR')
                        % retrieves the background image array      
                        if isempty(obj.Ibg{iPhase})                                            
                            % creates the background image (if not present)
                            obj.createGenBGImage(iPhase);
                        end

                        % sets the final viewing image
                        Inw = obj.Ibg{iPhase};
                        
                    else
                        % retrieves the background image type
                        if obj.isMTrk
                            if strContains(imgType,'Raw')
                                IbgI = obj.iMov.IbgR(:,iPhase);
                            else
                                IbgI = obj.iMov.Ibg(:,iPhase);
                            end
                        else
                            if strContains(imgType,'Raw')
                                IbgI = obj.trkObj.Ibg0{iPhase};
                            else
                                IbgI = obj.iMov.Ibg{iPhase};
                            end
                        end
                        
                        % sets the final background image
                        if obj.iMov.phInfo.hasF || ...
                                        (obj.iMov.vPhase(iPhase) > 1)
                            Imd = median(cellfun(@(x)(...
                                        median(x(:),'omitnan')),IbgI));
                            ImgC0 = Img0 - (median(Img0(:),'omitnan')+Imd);
                            
                            Iofs = true;
                        else
                            ImgC0 = Img0;
                            Iofs = false;
                        end
                        
                        % creates composite image from the phase bg images                       
                        Inw = createCompositeImage(ImgC0,obj.iMov,IbgI); 
                        if Iofs; Inw = Inw - min(Inw(:),[],'omitnan'); end
                    end   
                    
                case {'Residual',...
                      'Residual (Filled)',...
                      'Residual (Filtered)'}
                    % case is the raw residual image
                    
                    if size(Img0,3) == 3
                        Img0 = double(rgb2gray(uint8(Img0)));
                    end
                    
                    % scales the image (if required)
                    if isfield(obj.iMov,'pImg')
                        pI = obj.iMov.pImg(iPhase,:);
                        Img0 = pI(2)*(Img0 - pI(1));
                    end

                    % reads the image
                    bgP = obj.getTrackingPara();
                    if bgP.useFilt && ~isRaw
                        Img0 = imfiltersym(Img0,hS);
                    end

                    % case is the low-variance phase
                    cMapType = 'jet';             
                    
                    % sets up the residual image
                    Inw = obj.setupResidualImage(Img0,iPhase,iFrmS,iok);
                    
                case {'Cross-Correlation'}
                  
                    % creates a progressbar
                    wStr = 'Setting Up Cross-Correlation Mask';
                    hLoad = ProgressLoadbar(wStr);
                    pause(0.05);
                    
                    if size(Img0,3) == 3
                        Img0 = double(rgb2gray(uint8(Img0)));
                    end               
                    
                    % calculates the image/template gradient masks
                    cLim = [0,1];
                    cMapType = 'jet';                    
                    Img0(isnan(Img0)) = median(Img0(:),'omitnan');
                    
                    % applies the image filter (if used)
                    if bgP.useFilt && ~obj.isMTrk
                        Img0 = imfiltersym(Img0,hS);
                    end          
                        
                    % calculates the region x-correlation image
                    InwL = obj.setupXCorrImage(Img0);                     
                    
                    % case is the low-variance phase
                    InwR = obj.setupResidualImage(Img0,iPhase,iFrmS,iok);
                    InwX = createCompositeImage(zeros(frmSz),obj.iMov,InwL);
                    Inw = normImg(InwR).*InwX;
                    
                    % closes the progressbar
                    delete(hLoad)
            end

            % updates the axis colour limit
            if isempty(cLim)
                set(obj.hAx,'CLimMode','Auto')
            else
                set(obj.hAx,'clim',cLim)
            end
            
            % updates the colormap type
            if strcmp(cMapType,'jet')
                obj.cMapJet = colormap(obj.hAx,cMapType);
            else
                colormap(obj.hAx,cMapType);
            end

            % updates the markers (if they exist)
            if ~isempty(obj.fPos)
                obj.updateObjMarkers()
            end

            % updates the main GUI image axis
            set(obj.hFig,'CurrentAxes',obj.hAx);
            dispImage(hgui,Inw,1); pause(0.05);

            % updates and closes the waitbar
            if ~isempty(h)
                waitbar(1,h,'Image Update Complete');
                close(h);
            end
            
            
        end
        
        % --- sets up the region x-correlation image stack
        function IxcL = setupXCorrImage(obj,I)
            
            % initialisations
            mdDim = 30*[1,1];
            IxcL = cell(obj.nApp,1);
            iFrm0 = obj.indFrm{obj.iPara.cPhase}(obj.iPara.cFrm);
            isHiV = obj.iMov.vPhase(obj.iPara.cPhase) == 2;
                        
            % calculates the x-correlation images for each region
            for i = find(obj.iMov.ok(:)')
                % retrieves the image stack
                IL = getRegionImgStack(obj.iMov,I,iFrm0,i,isHiV);
                Bw = getExclusionBin(obj.iMov,size(IL{1}),i);                
                
                % calculates the image cross-correlation
                if obj.isMTrk
                    BO = ~(obj.iMov.Bedge{i} | obj.iMov.Binner{i});                    
                    IL{1}(BO) = median(IL{1}(~BO),'omitnan');
                    IxcL{i} = calcXCorr(-obj.iMov.IsubT,IL{1});
                else
                    dI = setupResidualEstStack(IL,mdDim);
                    IxcL{i} = Bw.*max(0,calcXCorr(obj.iMov.hFilt,...
                                          fillArrayNaNs(dI{1}))); 
                end
            end
            
        end
        
        % --- sets up the region residual image stack
        function Inw = setupResidualImage(obj,Img0,iPhase,iFrmS,iok)

            % initialisations            
            frmSz = getCurrentImageDim(obj.hGUI);
            isHV = obj.iMov.vPhase(iPhase) == 2;
            isSpecial = obj.iMov.vPhase(iPhase) == 4;            
            
            % sets up the image stack
            ILs = cell(1,obj.nApp);
            ILs(iok) = arrayfun(@(x)(getRegionImgStack...
                  (obj.iMov,Img0,iFrmS,x,isHV)),find(iok),'un',0);
            ILs(iok) = cellfun(@(x)(x{1}),ILs(iok),'un',0);

            % calculates the histogram matched images (special phase only)
            if isSpecial
                ILs(iok) = cellfun(@(x,y)(double(imhistmatch...
                    (uint8(x),y,'method','uniform'))),ILs(iok),...
                    obj.iMov.IbgR(iok),'un',0);
            end            
            
            % sets the background image based on the detection type
            if strcmp(getDetectionType(obj.iMov),'GeneralR')
                % retrieves the background image array
                if isempty(obj.Ibg{iPhase})                                         
                    % creates the background image if it does 
                    % not exist
                    obj.createGenBGImage(iPhase);
                end

                % sets the final viewing image
                I0 = zeros(frmSz);
                Itot = createCompositeImage(I0,obj.iMov,ILs);
                Inw = (obj.Ibg{iPhase} - Itot).*(Itot > 0); 

            else                        
                % retrieves the background image type
                if obj.isMTrk
                    IbgI = obj.iMov.Ibg(:,iPhase);
                else
                    IbgI = obj.iMov.Ibg{iPhase};
                end

                % reshapes the local image array
                ILs = reshape(ILs,size(IbgI));                        

                % creates the composite from the phase bg image
                [I0,IRL] = deal(zeros(frmSz),cell(size(ILs)));
                IRL(iok) = cellfun(@(x,y)...
                                (x-y),IbgI(iok),ILs(iok),'un',0);
                Inw = createCompositeImage(I0,obj.iMov,IRL);

            end

        end        
        
        % --- initialises the temporary fly markers
        function updateObjMarkers(obj)
            
            % other initialisations
            [iPhase,iFrmNw] = deal(obj.iPara.cPhase,obj.iPara.cFrm);            
            if isequal(colormap(obj.hAx),obj.cMapJet)
                [pCol,lWid] = deal('k',3);
            else
                [pCol,lWid] = deal('g',3);
            end
            
            % sets the marker properties            
            if obj.isMTrk               
                % sets the region count
                [nRow,nCol] = deal(obj.iMov.pInfo.nRow,obj.iMov.pInfo.nCol);
                nReg = nRow*nCol;
                
                % sets the marker properties
                [pMark,obj.mSz] = deal('.',12);                
            else
                % sets the region count
                nReg = length(obj.iMov.iR);
                
                % sets the marker properties
                if ispc
                    [pMark,obj.mSz,mlWid] = deal('o',10,2);
                else                
                    [pMark,obj.mSz,mlWid] = deal('*',8,2);
                end
            end
            
            % marker coordinate arrays
            vStr = {'off','on'};
            fpos = obj.fPos{iPhase};  
            isFeas = ~isempty(fpos);
            showMark = get(obj.hGUI.checkFlyMarkers,'Value');
            
            % updates the fly markers for all apparatus
            for iReg = 1:nReg
                % retrieves the position values
                if obj.isMTrk
                    % if there is no location data, then exit
                    if ~isFeas; return; end
                    
                    % resets the markers (if they are invalid)
                    if (iReg == 1) && ~isvalid(obj.hMark{iReg}{1})
                        obj.initLikelyPlotMarkers();
                    end
                    
                    % updates the marker locations                    
                    fPosNw = fpos{iReg,iFrmNw};
                    set(obj.hMark{iReg}{1},'xdata',fPosNw(:,1),...
                                           'ydata',fPosNw(:,2),...
                                           'Visible',vStr{1+showMark})
                                       
                    % updates the other properties
                    [iRow,iCol] = ind2sub([nRow,nCol],iReg);
                    if obj.iMov.flyok(iRow,iCol)
                        set(obj.hMark{iReg}{1},'marker',pMark,...
                                    'color',pCol,'markersize',obj.mSz,...
                                    'linewidth',lWid);                                
                    end
                    
                else   
                    % retrieves the position coord (non-hi var phase only)
                    if isFeas; fPosNw = fpos{iReg,iFrmNw}; end
                    
                    xiT = 1:getSRCount(obj.iMov,iReg);
                    for iT = find(obj.iMov.flyok(xiT,iReg))'
                        % updates the marker locations
                        if ~isFeas
                            % case is a hi-variance phase
                            set(obj.hMark{iReg}{iT},'xdata',NaN,...
                                                    'ydata',NaN)                            
                        else                                                       
                            % case is a non hi-variance phase 
                            set(obj.hMark{iReg}{iT},'xdata',fPosNw(iT,1),...
                                                    'ydata',fPosNw(iT,2))
                        end

                        % updates the other properties                        
                        if obj.iMov.flyok(iT,iReg)
                            set(obj.hMark{iReg}{iT},'marker',pMark,...
                                        'color',pCol,'markersize',obj.mSz,...
                                        'linewidth',mlWid);                                
                        end
                    end
                end
            end

        end

        % --- updates the correlation values for the point estimates
        function updateXCorrStats(obj,Ixc)
            
            % initialisations
            [iPh,iFrmNw] = deal(obj.iPara.cPhase,obj.iPara.cFrm);
            
            % sets the 
            for i = 1:length(obj.iMov.iR)
                fP = obj.fPos{iPh}{i,iFrmNw};
                iPos = sub2ind(size(Ixc),fP(:,2),fP(:,1));
                obj.pStats.Ixc{i,iPh}(:,iFrmNw) = Ixc(iPos);
            end
            
        end
        
        % --- retrieves the parameter and sub-image data structs
        function setButtonProps(obj,Type)

            % retrieves the parameter and sub-image data structs
            hgui = obj.hGUI;
            imov = obj.iMov;
            ipara = obj.iPara;
            
            % parameters
            pCol = {'k','b','m',[255,165,0]/255,'r'};
            pType = {'Low Variance','High Variance',...
                     'Untrackable','Special','Rejected'};

            % variance string toolstrings
            ttStr = {sprintf(['* Low pixel intensity variance within phase.\n',...
                              '--> Fly locations determined by background subtraction.\n',...
                              '--> Tracking efficacy should be extremely high.']);...
                     sprintf(['* High pixel intensity variance within phase.\n',...
                              '--> Fly locations determined by direct detection.\n',...
                              '--> Tracking efficacy should be high.']);...
                     sprintf(['* Untrackable phase.\n',...
                              '--> Pixel range is either too low or mean pixel intensity too low/high',...
                              '--> Fly locations determined by interpolating from surrounding phases.\n',...
                              '--> Tracking efficacy will be low.']);...
                     sprintf(['* Special phase.\n',...
                              '--> Pixel range fluctuates due to motor activation (HT1 Controller)',...                     
                              '--> Fly locations determined by special interpolation method.\n']);...                              
                     sprintf(['* Reject phase.\n',...
                              '--> Phase has been manually rejected by the user.\n',...
                              '--> No tracking will be undertaken.'])};

            % sets local and global frame indices
            [cPhase,cFrm] = deal(ipara.cPhase,ipara.cFrm);
            iFrmNw = num2str(obj.indFrm{cPhase}(cFrm));
            set(hgui.editFrameCount,'string',num2str(cFrm));
            set(hgui.textCurrentFrame,'string',iFrmNw);

            % sets the manual detection button enabled properties
            obj.setManualDetectEnable();
            
            % updates the phase properties (if updating the phase objects)
            if strcmp(Type,'Phase')
                % sets the phase variance type/index and phase count
                vP = imov.vPhase(cPhase);
                [cX,nX] = deal(cPhase,length(obj.indFrm));
                iPhaseNw = obj.iMov.iPhase(cPhase,:);
                nFrmPh = length(obj.indFrm{cPhase});
                
                % sets the phase count and variance type
                set(setObjEnable(hgui.editPhaseCount,nX>1),...
                                         'string',num2str(cX));
                set(hgui.textPhaseStatus,'string',pType{vP},...
                                         'foregroundcolor',pCol{vP},...
                                         'tooltipstring',ttStr{vP});    
                set(hgui.textPhaseStatusL,'tooltipstring',ttStr{vP}); 
                
                % updates the text fields
                set(hgui.textPhaseFrames,'string',num2str(nFrmPh))
                set(hgui.textStartFrame,'string',num2str(iPhaseNw(1)))
                set(hgui.textEndFrame,'string',num2str(iPhaseNw(2)))                 
                
                % updates the tracking phase checkbox object
                canTrack = obj.vPhase0(cPhase) < obj.ivRej;
                set(hgui.checkTrackPhase,'Value',canTrack);                
                setObjEnable(hgui.checkTrackPhase,canTrack)
                setObjEnable(hgui.checkFlyMarkers,canTrack);
                
                % updates the image type and properties
                if ~isempty(obj.fPos)
                    obj.updateImgTypePopup();
                end

                % updates the frame properties
                obj.setButtonProps('Frame')
            else
                % sets the frame index/count for the current phase
                [cX,nX] = deal(ipara.cFrm,length(obj.indFrm{cPhase}));
            end

            % sets the button properties based on the current index frame
            setObjEnable(eval(sprintf('hgui.frmFirst%s',Type)),cX>1)           
            setObjEnable(eval(sprintf('hgui.frmPrev%s',Type)),cX>1)
            setObjEnable(eval(sprintf('hgui.frmNext%s',Type)),cX<nX)
            setObjEnable(eval(sprintf('hgui.frmLast%s',Type)),cX<nX)      
        
        end
        
        % --- resets the dimensions of the gui
        function resetGUIDimensions(obj,openBG)
            
            % initialisations
            dx = 10;
            hgui = obj.hGUI;
            
            % determines the gui object offsets
            if openBG
                pPos = get(hgui.panelBGDetect,'position');
            else
                pPos = get(hgui.panelOuter,'position');   
                pPosI = get(hgui.panelImgData,'position');
                
                pPos(3) = pPosI(3) + 2*dx;
                resetObjPos(hgui.panelOuter,'width',pPos(3))
            end                                        
            
            % resets the figure width
            axPos = get(hgui.panelImg,'Position');
            fWid = (axPos(3)+pPos(3))+3*dx;
            manualResizeFlyTrackGUI(hgui.figFlyTrack,'width',fWid)     
            
            % updates the left position of the image axes
            resetObjPos(hgui.panelImg,'left',sum(pPos([1,3]))+dx) 
            
        end
        
        % --- sets the visibility for the main gui menu items 
        function setMenuVisibility(obj,openBG)

            % turns off the normal mode menu items
            setObjVisibility(obj.hGUI.menuFile,~openBG)
            setObjVisibility(obj.hGUI.menuAnalysis,~openBG)
            
            if isfield(obj.hGUI,'menuRTCalib')
                setObjVisibility(obj.hGUI.menuRTCalib,~openBG && obj.isCalib)
            end

            % turns off the normal mode menu items
            setObjVisibility(obj.hGUI.menuEstBG,openBG)
            setObjVisibility(obj.hGUI.menuFileBG,openBG)            

            % determines if the git-menu item is present
            hGitP = findall(obj.hGUI.figFlyTrack,'tag','hGitP');
            if ~isempty(hGitP)
                % if so, then set its properties
                setObjVisibility(hGitP,~openBG)
            end
            
        end                                                      
        
        % --------------------------------- %
        % ---- MENU CALLBACK FUNCTIONS ---- %
        % --------------------------------- %
        
        % -----------------------------------------------------------------
        function menuFlyAccRej(obj, hObject, ~)

            % determines if the menu item is checked or not
            if strcmp(get(hObject,'checked'),'on')
                % removes the menu item check 
                set(hObject,'checked','off')

                % removes the information GUI         
                try delete(obj.hInfo.hFig); catch; end
                obj.hInfo = [];
                
            else
                % adds the menu item check  
                set(hObject,'checked','on')        

                % updates the data structs   
                obj.hInfo = FlyInfoGUI(obj);  
            end
        
        end

        % -----------------------------------------------------------------
        function menuPara(obj, ~, ~)

            % runs the tracking parameter dialog
            DetectParaDialog(obj);
            
        end   
        
        % -----------------------------------------------------------------
        function menuCloseEstBG(obj, ~, ~)

            % updates the change flag wrt the ok flags
            obj.iMov.ddD = [];
%             obj.isChange = obj.isChange || (sum(abs(double(obj.ok0(:))-...
%                                         double(obj.iMov.flyok(:))))>0);

            % if there is a change/update then prompt the user if they wish
            % to proceed with updating the changes
            if obj.hasUpdated || obj.isChange
                tStr = 'Update Background Estimate Image?';
                uChoice = questdlg(['Do you want to update the ',...
                                    'background estimate changes?'],...
                                    tStr,'Yes','No','Cancel','Yes');
                switch uChoice
                    case 'Cancel'
                       % user cancelled
                       return
                       
                    otherwise
                        % case is the other choices
                        if ~strcmp(uChoice,'Yes')
                            obj.isChange = false;
                        end
                end
            end        
            
            % coverts the tracking gui to normal tracking mode
            obj.closeBGAnalysis()
            
        end

        % -----------------------------------------------------------------
        function menuPhaseStats(obj, hMenu, ~)
            
            switch get(hMenu,'Checked')
                case 'on'
                    % case is closing an open statistics GUI
                    obj.phaseObj.closeGUI(obj.phaseObj,[]);
                    set(hMenu,'Checked','off');
                    
                    % clears the statistics object
                    obj.phaseObj = [];                    
                    
                case 'off'
                    % case is opening the statistics GUI
                    obj.phaseObj = InitPhaseStats(obj);
                    set(hMenu,'Checked','on');                    
                    
            end
            
        end
        
        % -----------------------------------------------------------------
        function menuShowStats(obj, hMenu, ~)
            
            switch get(hMenu,'Checked')
                case 'on'
                    % case is closing an open statistics GUI
                    obj.statsObj.closeGUI([],[]);
                    set(hMenu,'Checked','off');
                    
                    % clears the statistics object
                    obj.statsObj = [];
                    
                case 'off'                    
                    % case is opening the statistics GUI
                    obj.statsObj = InitTrackStats(obj);
                    set(hMenu,'Checked','on');
            end
            
        end        
        
        % ---------------------------------------- %
        % --- IMAGE STACK SIZE/SETUP CALLBACKS --- %
        % ---------------------------------------- %       

        % --- Executes on button press in buttonUpdateStack.
        function buttonUpdateStack(obj, ~, ~)

            % initialisations
            chkStr = {'off','on'};
            
            % retrieves the program data struct and the image stack size
            idata = obj.iData;
            imov = obj.iMov;
            ipara = obj.iPara;
            hgui = obj.hGUI;

            % checks if there are any items for manual resegmentation
            if ~isempty(obj.uList)
                % if there are manual resegmentation items, then prompt the 
                % user if they still want to read the sub-image stack
                tStr = 'Clear Manual Resegmentation List';
                qStr = sprintf(['You have regions selected for manual ',...
                               'resegmentation. If you continue with ',...
                               'reading the sub-image stack then this ',...
                               'will clear the list.\n\nDo you still ',...
                               'wish to continue?']);
                uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                if strcmp(uChoice,'Yes')
                    % retrieves the manual marker objects. if they 
                    % exist then remove them
                    if ~isempty(obj.hManual); delete(obj.hManual); end  
                    [obj.hManual,obj.uList] = deal([]);

                    % if they do, then clear the table and the list array
                    set(hgui.tableFlyUpdate,'Data',[])  
                    
                else
                    % if they cancelled, then exit the function
                    return
                end    
            end
            
            % if the stats gui is open, then close it
            if ~isempty(obj.phaseObj)
                obj.menuPhaseStats(hgui.menuPhaseStats,[]);
                setObjEnable(hgui.menuPhaseStats,'off');
            end                        
            
            % if the stats gui is open, then close it
            if ~isempty(obj.statsObj)
                obj.menuShowStats(hgui.menuShowStats,[]);
                setObjEnable(hgui.menuShowStats,'off');
            end            

            % deselects the tube tracking regions
            if get(hgui.checkTubeRegions,'value')
                set(hgui.checkTubeRegions,'value',0)
                obj.checkTubeRegions(hgui.checkTubeRegions, [])
            end

            % removes the tracking markers
            if get(hgui.checkFlyMarkers,'value')
                set(hgui.checkFlyMarkers,'value',0)
                obj.checkFlyMarkers(hgui.checkFlyMarkers, [])
            end

            % retrieves the normal image
            if obj.isCalib
                % retrieves the camera the required number of snapshots
                infoObj = get(obj.hFig,'infoObj');    
                
                % prompts the user for the video capture information
                frmPara = CapturePara();
                if isempty(frmPara)
                    % if the user cancelled, then exit the function
                    return
                else
                    % reads the snapshots from the camera (stopping after)
                    Img = getCameraSnapshots...
                                (imov,idata,infoObj.objIMAQ,frmPara);
                    if isempty(Img)
                        % if the user cancelled, then exit the function
                        return
                    end
                end

                % sets the sub-image struct
                ipara.nFrm0 = length(Img);
    
                % sets the image stack
                imov.vPhase = 1;
                imov.iPhase = [1,ipara.nFrm0];
                obj.ImgC = {Img};
                obj.indFrm = {1:length(Img)};
                
            else                
                % retrieves the current frame from file                                
                [imov,simgs,~] = getEstimateImageStack(idata,imov); 
                if isempty(simgs)
                    % if the user cancelled, then exit the function
                    return    
                end
            end           
            
            % updates the parameter struct   
            obj.iMov = imov;
            obj.iMov.Ibg = [];
            obj.iPara.cFrm = 1;
            obj.frameSet = true;            
            [obj.isAllUpdate,obj.hasUpdated] = deal(true,false);   
            obj.vPhase0 = obj.iMov.vPhase;
            
            % sets the phase index
            okPh = obj.detFeasPhase();
            if any(okPh)
                obj.iPara.cPhase = find(okPh,1,'first');
            else
                obj.iPara.cPhase = 1;
            end

            % enables the image display properties
            setObjEnable(hgui.menuPhaseStats,'on');
            setObjEnable(hgui.menuShowStats,'off');
            setObjEnable(hgui.buttonUpdateEst,any(okPh));
            setPanelProps(hgui.panelVideoInfo,'on');
            setPanelProps(hgui.panelFrameSelect,'on')
            setPanelProps(hgui.panelImageType,'on')
            obj.checkFilterImg(obj.hGUI.checkFilterImg,[])              

            % disables the manual resegmentation list
            setPanelProps(hgui.panelManualSelect,'off')
            obj.setVideoInfoProps()

            % sets the enables properties of the phase selection objects
            setPanelProps(hgui.panelPhaseSelect,'on');            
            if ~obj.isCalib
                % sets the frame index arrays
                obj.indFrm = field2cell(simgs,'iFrm');                
            end                              
            
            % disables the manual tracking panel
            obj.setManualObjProps('off')
            
            % turns off the fly markers
            set(setObjEnable(hgui.checkFlyMarkers,'off'),'value',0);
            obj.checkFlyMarkers(hgui.checkFlyMarkers, [])

            % updates the image frame and the program data struct
            obj.iData = idata;            
            [obj.fPos,obj.IPos] = deal([]);   
            obj.iPara.nFrm = length(obj.indFrm{obj.iPara.cPhase});

            % resets the video translation menu item   
            hMenuCT = obj.hGUI.menuCorrectTrans;
            hasT = ~isempty(imov.phInfo) && any(imov.phInfo.hasT);
            set(setObjEnable(hMenuCT,hasT),'Checked',chkStr{1+hasT})                        
            
            % runs the post video phase update
            if isprop(obj.trkObj,'hMenuM')
                obj.trkObj.postVideoPhaseUpdate();
            end                                          
            
            % updates the main image axes
            obj.setButtonProps('Phase')
            obj.setButtonProps('Frame')
            obj.updateMainImage(obj.iMov)
        
        end

        % --------------------------------- %
        % --- PHASE SELECTION CALLBACKS --- %
        % --------------------------------- %
        
        % --- Executes on button press in frmFirstPhase.
        function frmFirstPhase(obj, ~, ~)

            % updates the parameter struct
            obj.iPara.cPhase = 1;
            obj.iPara.cFrm = min(obj.iPara.cFrm,length(obj.indFrm{1}));

            % updates the button properties and the main image
            obj.setButtonProps('Phase')
            obj.updateMainImage()
            
        end

        % --- Executes on button press in frmPrevPhase.
        function frmPrevPhase(obj, ~, ~)

            % retrieves the parameter and sub-image data structs
            if (obj.iPara.cPhase == 1) || obj.isUpdating
                return
            else
                obj.isUpdating = true;
            end

            % updates the parameter struct
            obj.iPara.cPhase = obj.iPara.cPhase - 1;
            obj.iPara.cFrm = min(obj.iPara.cFrm,...
                             length(obj.indFrm{obj.iPara.cPhase}));

            % updates the button properties and the main image
            obj.setButtonProps('Phase')
            obj.updateMainImage()
            obj.isUpdating = false;
            
        end

        % --- Executes on button press in frmNextPhase.
        function frmNextPhase(obj, ~, ~)

            % retrieves the parameter and sub-image data structs
            if (obj.iPara.cPhase == length(obj.indFrm)) || obj.isUpdating
                return
            else
                obj.isUpdating = true;
            end

            % updates the parameter struct
            obj.iPara.cPhase = obj.iPara.cPhase + 1;
            obj.iPara.cFrm = min(obj.iPara.cFrm,...
                                length(obj.indFrm{obj.iPara.cPhase}));

            % updates the button properties and the main image
            obj.setButtonProps('Phase')
            obj.updateMainImage()
            obj.isUpdating = false;
        
        end

        % --- Executes on button press in frmLastPhase.
        function frmLastPhase(obj, ~, ~)

            % updates the parameter struct
            obj.iPara.cPhase = length(obj.indFrm);
            obj.iPara.cFrm = min(obj.iPara.cFrm,...
                                length(obj.indFrm{obj.iPara.cPhase}));

            % updates the button properties and the main image
            obj.setButtonProps('Phase')
            obj.updateMainImage()
        
        end

        % --- Executes on updating in editPhaseCount.
        function editPhaseCount(obj, hObject, ~)

            % checks if the new value is valid
            nwVal = str2double(get(hObject,'string'));
            if chkEditValue(nwVal,[1 length(obj.indFrm)],1)
                % if so, then update the frame index
                obj.iPara.cPhase = nwVal;
                obj.iPara.cFrm = min(obj.iPara.cFrm,...
                                         length(obj.indFrm{nwVal}));   

                % updates the button properties and the main image
                obj.setButtonProps('Phase')
                obj.updateMainImage()
            else
                % otherwise, revert back to the previous valid value
                set(hObject,'string',num2str(obj.iPara.cPhase))
            end
        
        end
            
        % --- Executes on update checkTrackPhase
        function checkTrackPhase(obj, hObject, ~)
            
            % flag that a change has been made
            obj.isChange = true;
            iPh = obj.iPara.cPhase;
            isOn = get(hObject,'Value');            
                        
            % updates the phase flag            
            if isOn
                obj.iMov.vPhase(iPh) = obj.vPhase0(iPh);
            else
                obj.iMov.vPhase(iPh) = obj.ivRej;                                
                
                % if the tubes are on, then remove them
                if get(obj.hGUI.checkFlyMarkers,'value')
                    set(obj.hGUI.checkFlyMarkers,'value',false)
                    obj.checkFlyMarkers(obj.hGUI.checkFlyMarkers, [])
                end
            end
            
            % updates the phase object colours (if info GUI is open)
            if ~isempty(obj.phaseObj)
                obj.phaseObj.updatePatchColour(iPh);
            end
            
            % updates the fly marker enabled properties
            setObjEnable(obj.hGUI.checkFlyMarkers,isOn)
            
            % updates the button properties            
            obj.setButtonProps('Phase')
            
        end
        
        % --------------------------------- %
        % --- FRAME SELECTION CALLBACKS --- %
        % --------------------------------- %

        % --- Executes on button press in frmFirstFrame.
        function frmFirstFrame(obj, ~, ~)

            % updates the parameter struct
            obj.iPara.cFrm = 1;

            % updates the button properties and the main image
            obj.setButtonProps('Frame')
            obj.updateMainImage()
        
        end

        % --- Executes on button press in frmPrevFrame.
        function frmPrevFrame(obj, ~, ~)

            % retrieves the parameter and sub-image data structs
            if (obj.isUpdating) || (obj.iPara.cFrm == 1)
                return
            else
                obj.isUpdating = true;
            end

            % updates the parameter struct
            obj.iPara.cFrm = obj.iPara.cFrm - 1;

            % updates the button properties
            obj.setButtonProps('Frame')
            
            % updates the button properties and the main image
            obj.updateMainImage()
            obj.isUpdating = false;
        
        end

        % --- Executes on button press in frmNextFrame.
        function frmNextFrame(obj, ~, ~)

            % retrieves the parameter and sub-image data structs
            if obj.iPara.cFrm == length(obj.indFrm{obj.iPara.cPhase})
                return
            elseif obj.isUpdating
                return
            else
                obj.isUpdating = true;                
            end

            % updates the parameter struct
            obj.iPara.cFrm = obj.iPara.cFrm + 1;
            
            % updates the button properties
            obj.setButtonProps('Frame')
            
            % updates the button properties and the main image
            obj.updateMainImage()
            obj.isUpdating = false;
        
        end

        % --- Executes on button press in frmLastFrame.
        function frmLastFrame(obj, ~, ~)

            % updates the parameter struct
            obj.iPara.cFrm = length(obj.indFrm{obj.iPara.cPhase});

            % updates the button properties and the main image
            obj.setButtonProps('Frame')
            obj.updateMainImage()
        
        end

        % --- Executes on updating in editFrameCount.
        function editFrameCount(obj, hObject, ~)

            % checks if the new value is valid
            nwVal = str2double(get(hObject,'string'));
            nFrm = length(obj.indFrm{obj.iPara.cPhase});
            if chkEditValue(nwVal,[1 nFrm],1)
                % if so, then update the frame index
                obj.iPara.cFrm = nwVal;

                % updates the button properties and the main image
                obj.setButtonProps('Frame')
                obj.updateMainImage()
            else
                % otherwise, revert back to the previous valid value
                set(hObject,'string',num2str(obj.iPara.cFrm))
            end

        end
        
        % ------------------------------- %
        % --- DISPLAY IMAGE CALLBACKS --- %
        % ------------------------------- %          
        
        % --- Executes when selected object is changed in popupImgType.
        function checkFilterImg(obj, hObj, ~)
            
            % determines if the user wishes to make the change
            useFilt = get(hObj,'Value');
            if ~obj.checkParaChange()
                % if the user cancelled, then revert to the previous value
                set(hObj,'Value',~useFilt);
                return
            end
            
            % updates the change flag
            obj.isChange = true;            
            
            % updates the tracking parameters            
            obj.setTrackingPara('useFilt',useFilt)
            setObjEnable(obj.hGUI.textFilterSize,useFilt); 
            setObjEnable(obj.hGUI.editFilterSize,useFilt);            
            
            % updates the popup image type list
            if obj.updateImgTypePopup()   
                % if there was a change, then update the main image
                obj.updateMainImage()
            end
            
        end
        
        % --- Executes when selected object is changed in popupImgType.
        function editFilterSize(obj, hObj, ~)
    
            % determines if the new value is valid
            nwVal = str2double(get(hObj,'String'));           
            if chkEditValue(nwVal,[1,50],true)            
                if obj.checkParaChange()
                    % if so, then update the parameter 
                    obj.setTrackingPara('hSz',nwVal)

                    % updates the change flag
                    obj.isChange = true;                

                    % updates the popup image type list
                    iSel0 = get(obj.hGUI.popupImgType,'Value');
                    if any(iSel0 == 2)  
                        % if there was a change, then update the main image
                        obj.updateMainImage()
                    end   
                    
                    % exits the function
                    return
                end
            end
            
            % if the update was not successful then revert to previous 
            set(hObj,'String',num2str(obj.getTrackingPara('hSz')))            
            
        end        

        % --- Executes when selection changed in popupImgType.
        function popupImgType(obj, ~, ~)

            % updates the main image axes
            obj.updateMainImage()
        
        end

        % --- determines if the user wants to update a parameter change
        function isOK = checkParaChange(obj)
            
            % initialisations
            isOK = true;
            
            % only check if the estimate has already been calculated
            if obj.hasUpdated
                % prompts the user if they want to update
                qtStr = 'Confirm Parameter Update';
                qStr = sprintf(['Are you sure you want to change this ',...
                                'parameter?\nThis action will clear ',...
                                'all calculated data.']);
                uChoice = questdlg(qStr,qtStr,'Yes','No','Yes');                
                if ~strcmp(uChoice,'Yes')
                    % if the user cancelled, then exit
                    isOK = false;
                    return
                end
                
                % resets the fields                                
                obj.hasUpdated = false;
                [obj.iMov.tPara,obj.iMov.Ibg] = deal([]);
                setObjEnable(obj.hGUI.buttonUpdateEst,'on');

                % if the phase stats gui is open, then close it
                if ~isempty(obj.phaseObj)
                    obj.menuPhaseStats(obj.hGUI.menuPhaseStats,[]);
                    setObjEnable(obj.menuPhaseStats,'off');
                end                     
                
                % if the stats gui is open, then close it
                if ~isempty(obj.statsObj)
                    obj.menuShowStats(obj.hGUI.menuShowStats,[]);
                    setObjEnable(obj.menuShowStats,'off');
                end                                             
                
                % resets the image popup menu
                if obj.updateImgTypePopup()
                    obj.updateMainImage();
                end
                
                % turns off the fly markers
                hCheckM = obj.hGUI.checkFlyMarkers;
                set(setObjEnable(hCheckM,'off'),'value',0);
                obj.checkFlyMarkers(hCheckM, [])                
            end
            
        end
        
        % ------------------------------------ %
        % --- VIDEO IMAGE MARKER CALLBACKS --- %
        % ------------------------------------ %        
        
        % --- Executes on button press in checkTubeRegions.
        function checkTubeRegions(obj, hObject, ~)

            % retrieves the tube show check callback function
            hgui = obj.hGUI;
            cFunc = get(hgui.figFlyTrack,'checkShowTube_Callback');

            % updates the tubes visibility
            cFunc(hgui.checkShowTube,num2str(get(hObject,'value')),hgui)

        end
        
        % --- Executes on button press in checkFlyMarkers.
        function checkFlyMarkers(obj, hObject, ~)

            % if the video phase info is not set then exit
            if ~isfield(obj.iMov,'vPhase')
                return
            end
            
            % retrieves the fly marker object handles
            isOK = get(hObject,'value');
            fok = obj.iMov.flyok;

            %
            if obj.isMTrk
                fok = fok';
                iReg = find(arr2vec(fok)');
            else
                iReg = find(obj.iMov.ok(:)');
                nFly = arrayfun(@(x)(getSRCount(obj.iMov,x)),iReg);
            end
            
            % sets the panel properties
            obj.setManualDetectEnable()
            
            % sets the marker visibility for all apparatus
            for i = iReg
                % sets                
                if obj.isMTrk
                    cellfun(@(x)(setObjVisibility(x,fok(i))),obj.hMark{i})
                else
                    indFly = 1:nFly(i);                    
                    cellfun(@(x,isOn)(setObjVisibility(x,isOn)),...
                            obj.hMark{i},num2cell(isOK & fok(indFly,i)))
                end
            end
        
        end

        % ---------------------------------- %
        % --- OTHER PUSHBUTTON CALLBACKS --- %
        % ---------------------------------- %
        
        % --- Executes on button press in buttonUpdateEst.
        function buttonUpdateEst(obj, ~, ~)

            % global variables
            global wOfs1
            wOfs1 = 0;
            
            % if there are no trackable frames then exit
            if ~any(obj.detFeasPhase())
                mStr = ['This video does not appear to have any ',...
                        'trackable frames.'];
                waitfor(msgbox(mStr,'No Trackable Frames?','modal'))
                return
            end

            % retrieves the sub-image data struct
            if initDetectCompleted(obj.iMov)
                % if the background images have been calculated, then 
                % prompt the user if they wish to overwrite the solution. 
                % if not, then exit
                tStr = 'Overwrite Background Images?';
                qStr = sprintf(['This action will overwrite the ',...
                                'current background images.\nDo you ',...
                                'want to continue?']);
                uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                if ~strcmp(uChoice,'Yes')
                    % if the user cancelled, then exit
                    return
                end
            end            
            
            % deselects the tube tracking regions
            set(obj.hGUI.checkTubeRegions,'value',0);
            obj.checkTubeRegions(obj.hGUI.checkTubeRegions,[])

            % deselects the fly markers
            set(obj.hGUI.checkFlyMarkers,'value',0);
            obj.checkFlyMarkers(obj.hGUI.checkFlyMarkers,[])
            
            % disables the manual tracking panel
            obj.setManualObjProps('off')             
            
            % sets the image array (if calibrating only)
            if obj.isCalib
                set(obj.trkObj,'Img0',obj.ImgC)
            end

            % closes the acceptance/rejection flag gui (if open)
            if strcmp(get(obj.hGUI.menuFlyAccRej,'Checked'),'on')            
                obj.menuFlyAccRej(obj.hGUI.menuFlyAccRej, [])
            end            
            
%             % creates the waitbar figure
%             if obj.isMTrk
%                 % case is tracking multiple objects
%                 h = [];
%                 
%             else
                % case is tracking a single object    
                
                % progressbar strings
                wStr = {'Reading Initial Image Stack',...
                        'Tracking Moving Objects',...
                        'Tracking Stationary Objects'};                  
                
                % creates the progressbar figure            
                h = ProgBar(wStr,'Single Object Background Estimation'); 
               
            if isprop(obj.trkObj,'hFilt')
                % calculates the initial location estimates
                obj.trkObj.hFilt = [];                                
            end
            
            % calculates the initial location estimates
            obj.trkObj.calcInitEstimate(obj.iMov,h);             

            % calculates the background image estimate
            [ok,imov] = deal(obj.trkObj.calcOK,obj.trkObj.iMov);
            if ok     
                % updates and closes the waitbar figure
                if ~isempty(h)
                    if ~h.Update(2,'Segmentation Complete',1)
                        h.closeProgBar();
                    end        
                end
                
                % if segmentation was successful, then update the 
                % sub-image data struct
                obj.iMov = imov;
                obj.ok0 = imov.flyok;                              
                obj.Ibg = cell(length(imov.vPhase),1);                     
                obj.vPhase0 = obj.iMov.vPhase;
                obj.indFrm = obj.trkObj.indFrm;                
                
                % updates the sub-region data struct in the main gui
                set(obj.hGUI.figFlyTrack,'iMov',imov)
                
                % likely/potential object locations
                obj.fPos = obj.trkObj.fPosG;
                
                % sets the single-tracking specific fields
                if ~obj.isMTrk
                    obj.IPos = obj.trkObj.IPos;
                    obj.pStats = obj.trkObj.pStats;
                    obj.iMov.hFilt = calcImageStackFcn(obj.trkObj.hCQ);
                end                
                
                % updates the list box properties but clears the list
                set(obj.hGUI.tableFlyUpdate,'Data',[])
                setPanelProps(obj.hGUI.panelManualSelect,'on')                
                setObjEnable(obj.hGUI.menuPhaseStats,'on')
                setObjEnable(obj.hGUI.buttonRemoveManual,'off')
                setObjEnable(obj.hGUI.menuShowStats,~obj.isMTrk);
                
                % deletes any all potential object markers 
                if ~isempty(obj.hMarkAll)
                    delete(obj.hMarkAll)
                    obj.hMarkAll = [];
                end    

                % sets the fly markers to be visible
                set(setObjEnable(obj.hGUI.checkFlyMarkers,'on'),'value',1) 
                
                % enables the manual tracking panel
                obj.setManualObjProps('on')                
                
                % initialises the potential plot markers
                obj.initPotentialPlotMarkers()
                
                % updates the object markers
                obj.checkFlyMarkers(obj.hGUI.checkFlyMarkers, [])
                obj.updateMainImage()
                
                % updates the frame/phase object properties
                obj.setButtonProps('Frame')
                obj.setButtonProps('Phase')

                % updates the other flags indicating success
                [obj.isChange,obj.hasUpdated] = deal(true);
                [obj.isAllUpdate,obj.uList] = deal(false,[]);
                
%                 % updates the other fields
%                 if obj.isMTrk
%                     obj.trkObj.getFinalTrackingInfo(obj);
%                     obj.updateMainImage()
%                 end
            end
        
        end

        % ----------------------------------- %
        % --- MANUAL CORRECTION CALLBACKS --- %
        % ----------------------------------- %
        
        % --- Executes when selected cell(s) is changed in tableFlyUpdate.
        function tableFlyUpdate(obj, ~, eventdata)

            % enables the remove update button
            if isempty(eventdata.Indices)
                return
            else
                iVal = eventdata.Indices(1);
                if isempty(iVal); return; end
            end

            % enabled properties of the remove button
            hgui = obj.hGUI;
            setObjEnable(hgui.buttonRemoveManual,'on')
            
            % updates the phase/frame (if these properties don't match)
            sInfo = obj.uList(iVal,:);
            if (sInfo(1) ~= obj.iPara.cPhase) || ...
               (sInfo(2) ~= obj.iPara.cFrm)               
                % updates the phase/frame count
                set(hgui.editPhaseCount,'string',num2str(sInfo(1)))
                set(hgui.editFrameCount,'string',num2str(sInfo(2)))                  
                
                % updates the phase
                [obj.iPara.cPhase,obj.iPara.cFrm] = deal(sInfo(1),sInfo(2));
                obj.editPhaseCount(hgui.editPhaseCount,[])
            end

            % resets the marker colours
            set(obj.hManual,'MarkerFaceColor','y');
            set(obj.hManual(iVal),'MarkerFaceColor','m');            
            
        end
        
        % --- Executes on button press in buttonAddManual.
        function buttonAddManual(obj, ~, ~)
            
            % if the tubes are on, then remove them
            if get(obj.hGUI.checkTubeRegions,'value')
                set(obj.hGUI.checkTubeRegions,'value',false)
                obj.checkTubeRegions(obj.hGUI.checkTubeRegions, [])
            end  
            
%             % if the tubes are on, then remove them
%             if get(obj.hGUI.checkFlyMarkers,'value')
%                 set(obj.hGUI.checkFlyMarkers,'value',false)
%                 obj.checkFlyMarkers(obj.hGUI.checkFlyMarkers, [])
%             end               
            
            % sets the mouse motion callback function            
            [obj.iCloseR,obj.iCloseSR,obj.iCloseF] = deal(-1);
            
            % sets up the manual marker map
            [obj.Imap,obj.pMn] = setupManualMarkMap(obj);   
            
            % updates the manual update props and disables the GUI objects
            obj.setGUIObjProps('off');            
            
            % creates the manual markers for each sub-region
            obj.createManualMarkers();            
            
            % sets the button down/motion callback functions            
            set(obj.hFig,'WindowButtonDownFcn',@obj.manualButtonClick)
            set(obj.hFig,'WindowButtonMotionFcn',@obj.manualTrackMotion)

        end        
        
        % --- Executes on button press in buttonRemoveManual.
        function buttonRemoveManual(obj, hObject, ~)
            
            % retrieves the java object handle (if not set)
            if isempty(obj.jTable)
                hh = findjobj(obj.hGUI.tableFlyUpdate);
                obj.jTable = hh.getComponent(0).getComponent(0);                              
            end
            
            % retrieves the currently selected row
            iVal = obj.jTable.getSelectedRows + 1;
            if isempty(iVal)
                % if none are selected, then exit the function
                setObjEnable(hObject,'off')
                return
            end

            % sets the boolean array
            ii = true(1,size(obj.uList,1)); 
            ii(iVal) = false;

            % deletes the manual marker from the list
            delete(obj.hManual(iVal))
            obj.hManual = obj.hManual(ii);
            obj.uList = obj.uList(ii,:);  
            
            % resets the listbox strings and the update list indices
            obj.updateManualTrackTable();

            % resets the table header size
            setObjEnable(hObject,'off')
        
        end
        
        % --- Executes on button press in buttonUpdateManual.
        function buttonUpdateManual(obj, ~, ~)
            
            % initialisations
            xiC = [1,3,4];
            
            % determines the unique combinations
            [~,~,iC] = unique(obj.uList(:,xiC),'rows');
            iRowM = arrayfun(@(x)(find(iC==x)),1:max(iC),'un',0)';                                    
            nBlob = length(iRowM);    
            
            % --------------------------------- %
            % --- BACKGROUND RE-CALCULATION --- %
            % --------------------------------- %        
            
            % creates the waitbar figure
            wStr = {'Background Image Setup','Blob Progress'};
            obj.hProg = ProgBar(wStr,'Manual Resegmentation');
            
            % calculates the background and position for each of the 
            % manually reset points            
            for i = 1:nBlob
                obj.setupManualBGImages(iRowM{i});
            end             
            
            % ------------------------------- %
            % --- POSITION RE-CALCULATION --- %
            % ------------------------------- %    
            
            % memory allocation
            obj.ImgM = cellfun(@(x)(cell(length(x),1)),obj.indFrm,'un',0);
            
            % recalculates the manually selected points over all frames
            for i = 1:nBlob
                % updates the progressbar
                pNw = i/(2+nBlob);
                wStrNw = sprintf(['Recalculating Positions ',...
                                  '(%i of %i)'],i,nBlob);
                if obj.hProg.Update(1,wStrNw,pNw)
                    % if the user cancelled, then exit
                    return
                end
                
                % recalculates the positions
                obj.recalcManualPos(iRowM{i});
            end
            
            % clears the temporary image array
            obj.ImgM = [];
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % resets the progressbar
            obj.hProg.Update(1,'Final Marker Update',1);
            obj.hProg.Update(2,'Updating Image Axes...',0);
            
            % clears the table and disables the manual reselection panel
            set(obj.hGUI.tableFlyUpdate,'Data',[]);
            obj.setManualObjProps('off')
            obj.setManualObjProps('on')
            
            % closes the loadbar
            obj.hProg.Update(2,'Image Axes Update Complete!',1);
            obj.hProg.closeProgBar;            
            
            % updates the main image
            set(0,'CurrentFigure',obj.hGUI.output)
            obj.updateMainImage()
            
            % deselects the fly markers
            set(obj.hGUI.checkFlyMarkers,'value',1);
            obj.checkFlyMarkers(obj.hGUI.checkFlyMarkers,[])                        
            
        end

        % -------------------------------------- %
        % --- MANUAL RECALCULATION FUNCTIONS --- %
        % -------------------------------------- %   
        
        % --- recalculates the background/position from the manually 
        %     selected points
        function setupManualBGImages(obj,iRowM)
            
            % initialisations
            uListG = obj.uList(iRowM,:);
            [iPh,iApp,iTube] = deal(uListG(1,1),uListG(1,3),uListG(1,4));            
            [iR,iC] = deal(obj.iMov.iR{iApp},obj.iMov.iC{iApp});
            iRT = obj.iMov.iRT{iApp}{iTube}; 
            
            % sets up the raw image stack
            I0 = obj.trkObj.getImageStack(obj.indFrm{iPh}(uListG(:,2)));
            if obj.trkObj.useFilt
                I0 = cellfun(@(x)(imfiltersym(x,obj.trkObj.hS)),I0,'un',0);                
            end          
            
            % retrieves the sub-region image stack (over all phase frames)
            if obj.iMov.vPhase(1) == 4
                % case is a special phase
                ILT = cellfun(@(x)(x(iR,iC)),I0,'un',0);
                ILT = calcHistMatchStack(ILT,obj.iMov.IbgR{iApp});
                IL0 = cellfun(@(x)(x(iRT,:)),ILT,'un',0);
            else
                % case is 
                IL0 = cellfun(@(x)(x(iR(iRT),iC)),I0,'un',0);
            end                
            
            % sets the marker x/y coordinates            
            hM = obj.hManual(iRowM);
            szL = [length(iRT),length(iC)];
            [xOfs,yOfs] = deal(iC(1)-1,iR(iRT(1))-1);            
            xD = cell2mat(arrayfun(@(h)(get(h,'xData')-xOfs),hM,'un',0));
            yD = cell2mat(arrayfun(@(h)(get(h,'yData')-yOfs),hM,'un',0));            
            
            % determines the shape size of the blob object
            Brmv = bwmorph(obj.iMov.hFilt > 0,'dilate',1);
            [pOfs,szB] = deal((size(Brmv)-1)/2,size(Brmv));                        
            
            % removes the background image
            for i = 1:length(yD)
                % sets the row/column indices
                iRB = (yD(i)-pOfs(1)) + ((1:szB(1))'-1);
                iCB = (xD(i)-pOfs(2)) + ((1:szB(2))'-1);
                
                % determines the feasible row/column indices
                iiR = (iRB > 0) & (iRB <= szL(1));
                iiC = (iCB > 0) & (iCB <= szL(2));
                
                % removes the region containing the fly location     
                IL0{i}(iRB(iiR),iCB(iiC)) = ...
                            ~Brmv(iiR,iiC).*IL0{i}(iRB(iiR),iCB(iiC));
                IL0{i}(IL0{i}==0) = NaN;                  
            end      
            
            % interpolates the image gaps
            IbgL = interpImageGaps(calcImageStackFcn(IL0,'max'));            

            % resets the sub-region background estimate
            obj.iMov.Ibg{iPh}{iApp}(iRT,:) = IbgL;  
            
            % updates the progressbar
            obj.hProg.Update(2,'Background Estimate Complete',1);
            
        end        
        
        % --- recalculates the positions from the manually selected point
        function recalcManualPos(obj,iRowM)
           
            % initialisations
            pW = 0.75;
            Dtol = obj.iMov.szObj(1);
            uListG = obj.uList(iRowM,:);            
            iFrmNw = sort(uListG(:,2));
            [iPh,iApp,iTube] = deal(uListG(1,1),uListG(1,3),uListG(1,4));            

            % resets the progressbar
            obj.hProg.Update(2,'Reading Image Frames',0);
            
            % determines if the blob is moving/from a hi-variance phase
            isHV = obj.iMov.vPhase(iPh) == 2;
            isMove = obj.iMov.StatusF{iPh}(iTube,iApp) == 1;
            
            % sets the frame read index
            if isMove
                % case is the blob is moving
                iFrmR = iFrmNw;
            else
                % case is the blob is stationary
                iFrmR = 1:length(obj.indFrm{iPh});
            end

            % determines if the region has been rejected
            if ~obj.iMov.flyok(iTube,iApp)
                % if so, update the flag value
                obj.iMov.flyok(iTube,iApp) = true;

                % resets the info table dialog
                if ~isempty(obj.hInfo)
                    obj.hInfo.jTable.setValueAt(true,iTube-1,iApp-1)
                end
            end
            
            % retrieves the image filter
            bgP = obj.getTrackingPara();
            if bgP.useFilt
                hS = fspecial('disk',bgP.hSz);
            else
                hS = [];
            end
            
            % retrieves the local images
            iRT = obj.iMov.iRT{iApp}{iTube};
            iRL = obj.iMov.iR{iApp}(iRT);
            iCL = obj.iMov.iC{iApp};                                
            IBG = obj.iMov.Ibg{iPh}{iApp}(iRT,:);
            
            % retrieves the local image stacks
            IL0 = cell(length(iFrmR),1);
            for i = 1:length(iFrmR)
                % updates the progressbar
                wStr = sprintf('Reading Frame (%i of %i)',i,length(iFrmR));
                if obj.hProg.Update(2,wStr,i/length(iFrmR))
                    % if the user cancelled, then exit
                    return
                end
                
                % retrieves the global image
                iFrmG = obj.indFrm{iPh}(iFrmR(i));
                if isempty(obj.ImgM{iPh}{iFrmR(i)})
                    if obj.isCalib
                        Img0 = obj.ImgC{1}{iFrmR(i)};
                    else
                        Img0 = double(getDispImage...
                                    (obj.iData,obj.iMov,iFrmG,0));
                    end
                        
                    obj.ImgM{iPh}{iFrmR(i)} = imfiltersym(Img0,hS);
                end
            
                % retrieves the final region image stack
                IL0(i) = getRegionImgStack(obj.iMov,...
                            obj.ImgM{iPh}{iFrmR(i)},iFrmG,iApp,isHV);
            end
            
            % calculates the histogram match (special phase only)
            if obj.iMov.vPhase(1) == 4
                IL0 = calcHistMatchStack(IL0,obj.iMov.IbgR{iApp});
            end
            
            % retrieves the local images
            IL = cellfun(@(x)(x(iRT,:)),IL0,'un',0);                
            
            % sets the marker x/y coordinates     
            hM = obj.hManual(iRowM);
            [xOfs,yOfs,szL] = deal(iCL(1)-1,iRL(1)-1,size(IL{1}));
            xD = cell2mat(arrayfun(@(h)(get(h,'xData')-xOfs),hM,'un',0));
            yD = cell2mat(arrayfun(@(h)(get(h,'yData')-yOfs),hM,'un',0));            
            idxD = num2cell(sub2ind(szL,roundP(yD),roundP(xD)));
            
            % calculates the residual image stack and thresholds
            IRL = cellfun(@(x)(imfiltersym(IBG-x,hS)),IL,'un',0); 
            if isMove
                pTolRL = pW*mean(cellfun(@(x,y)(x(y)),IRL,idxD));
            else
                pTolRL = pW*mean(cellfun(@(x,y)(x(idxD{1})),IRL));
            end
              
            % thresholds the image and determines the blob indices
            BRL = cellfun(@(y)(y>pTolRL),IRL,'un',0);
            iGrpMx = cellfun(@(x)(getGroupIndex(x)),BRL,'un',0);
            
            % sets the final position vector
            for i = 1:length(IRL)
                % recalculates the positions for each 
                switch length(iGrpMx{i})
                    case 0
                        % case is there is no solution
                        iGrpF = argMax(IRL{i}(:));
                        
                    case 1
                        % case is there is a unique solution
                        iMx = argMax(IRL{i}(iGrpMx{i}{1}));
                        iGrpF = iGrpMx{i}{1}(iMx);
                        
                    otherwise
                        % case is there are unique solutions
                        IGrpMx = cellfun(@(x)(max(IRL{i}(x))),iGrpMx{i});
                        AGrp = sqrt(cellfun('length',iGrpMx{i}))/Dtol;
                        iMx = argMax(IGrpMx.*AGrp);
                        
                        % retrieves the coordinates of the maxima
                        jMx = argMax(IRL{i}(iGrpMx{i}{iMx}));
                        iGrpF = iGrpMx{i}{iMx}(jMx);
                end
                
                % updates the positions
                k = iFrmR(i);
                [yP,xP] = ind2sub(szL,iGrpF);
                obj.fPos{iPh}{iApp,k}(iTube,:) = [(xP+xOfs),(yP+yOfs)];
            end
            
            % determines if the 
            fPosT = cell2mat(cellfun...
                (@(x)(x(iTube,:)),obj.fPos{iPh}(iApp,:)','un',0));
            DPosT = max(fPosT,[],1) - min(fPosT,[],1);
            sFlagT = 2 - double(any(DPosT > 1.5*obj.iMov.szObj));
            
            % resets the status flags for the current tube region
            obj.iMov.StatusF{iPh}(iTube,iApp) = sFlagT;
            obj.iMov.Status = num2cell(...
                calcImageStackFcn(obj.iMov.StatusF,'min'),1);
            
        end
        
        % ------------------------------- %
        % --- MANUAL MARKER CALLBACKS --- %
        % ------------------------------- %
        
        % --- creates the manual markers for each sub-region
        function createManualMarkers(obj)
            
            % sets the hold on
            hold(obj.hAx,'on')
            
            % creates the marker coordinate information array
            pMnP = obj.pMn;
            [X,Y] = meshgrid(1:size(pMnP,2),1:size(pMnP,1));
            nBlob = cellfun(@(x)(size(x,1)),pMnP);            
            indM = arrayfun(@(x,y,n)([(1:n)',...
                            repmat([x,y],n,1)]),X,Y,nBlob,'un',0);
            obj.mInfo = [cell2mat(indM(:)),cell2mat(pMnP(:))];
            
            % creates the manual marker objects from the plot axes
            obj.clearAxesObjects('tag','hManualB');
            obj.clearAxesObjects('tag','hManualH');
                        
            % creates the background manual markers
            obj.hManualB = plot(obj.hAx,obj.mInfo(:,end-1),...
                                obj.mInfo(:,end),'.','markersize',15,...
                                'tag','hManualB','Visible','off');
                            
            % creates the highlight manual marker
            obj.hManualH = plot(obj.hAx,NaN,NaN,'y.','markersize',15,...
                                'tag','hManualH','Visible','on');            
            
            % sets the hold off
            hold(obj.hAx,'off')            
            
        end
        
        % --- clears from the main axes objects with the field/value
        %     combination given by pFld/pVal
        function clearAxesObjects(obj,pFld,pVal)
            
            % determines any objects with the field/value combo
            hObj = findall(obj.hAx,pFld,pVal);
            
            % if any such objects exist, then delete them
            if ~isempty(hObj); delete(hObj); end
            
        end
        
        % --- creates the manual markers for each sub-region
        function deleteManualMarkers(obj)
            
            % find any of the manual markers
            hManualPr = findall(obj.hAx,'tag','hManualH');
            if ~isempty(hManualPr)
                % if any exists, then delete them
                delete(hManualPr)
            end
            
        end
        
        % --- updates the fly marker highlights
        function updateFlyHighlight(obj,iMap,indT)
            
            % determines
            if iMap == 0
                % if there was a previously highlighted region, then
                % de-highlight this region
                set(obj.hManualH,'UserData',[]);
                setObjVisibility(obj.hManualH,'off')
                
                % resets the highlighted fly marker
                obj.iCloseF = -1;
                
            else
                % determines if the previous/new indices match
                iNw = [indT,iMap];            
                iPr = get(obj.hManual,'UserData');                
                if ~isequal(iNw,iPr)
                    % if not, then update the highlight marker
                    try
                        pM = obj.pMn{indT(2),indT(1)}(iMap,:);
                        set(obj.hManualH,'xData',pM(1),'yData',pM(2),...
                                         'UserData',iNw);
                        setObjVisibility(obj.hManualH,'on')

                        % updates the highlighted index array
                        obj.iCloseF = iMap;
                    catch
                        % resets the userdata/marker visibility
                        set(obj.hManualH,'UserData',[]);
                        setObjVisibility(obj.hManualH,'off')
                    end
                end                                
            end
            
        end                
        
        % --- updates the sub-region highlights
        function updateTubeHighlight(obj,hTube)
            
            % sets up the index array of the previously highlighted region
            indPr = [obj.iCloseR,obj.iCloseSR];   
            if isempty(indPr); return; end
            
            % determines
            if isempty(hTube) 
                % if there was a previously highlighted region, then
                % de-highlight this region
                if indPr(1) > 0             
                    hPr = findall(obj.hAx,'UserData',indPr,'tag','hTube');
                    setObjVisibility(hPr,0)
                end
                
                % resets the flag indices for the highlighted regions
                [obj.iCloseR,obj.iCloseSR,obj.iCloseF] = deal(-1);
            else
                % retrieves the indices of the tube region
                indNw = get(hTube,'UserData');
                if ~isequal(indNw,indPr)
                    % de-highlights the old region
                    hPr = findall(obj.hAx,'UserData',indPr,'tag','hTube');
                    setObjVisibility(hPr,0)
                    
                    % highlights the new region
                    hNw = findall(obj.hAx,'UserData',indNw,'tag','hTube');
                    setObjVisibility(hNw,1)
                    
                    % updates the highlighted index array
                    [obj.iCloseR,obj.iCloseSR] = deal(indNw(1),indNw(2));                    
                end
                
            end
            
        end
        
        % --- adds the manual marker to the plot axes
        function addManualMarker(obj,uListNw)
            
            % sets the manual marker coordinates
            xP = get(obj.hManualH,'xData');
            yP = get(obj.hManualH,'yData');
            
            % creates the new marker
            hold(obj.hAx,'on')
            hPlt = scatter(obj.hAx,xP,yP,'ko','tag','hManualAdd',...
                                'MarkerFaceColor','y','UserData',uListNw);            
            obj.hManual = [obj.hManual;hPlt];
            
            % turns off the axes hold            
%             uistack(hPlt,'bottom');
            hold(obj.hAx,'off')
            
        end        
        
        % --- updates the marker properties
        function updateMarkerProps(obj)
            
            % parameters
            pStr = 'arrow';
           
            % retrieves the current axes handle            
            mP = roundP(get(obj.hAx,'CurrentPoint'));

            % determines if the mouse is over any sub-regions
            hTube = cell2cell(obj.hFig.mkObj.hTube(:));
            P = cellfun(@(x)([get(x,'xdata'),...
                              get(x,'ydata')]),hTube(:),'un',0);            
            
            % determines if the mouse is over a sub-region
            ii = cellfun(@(x)(inpolygon(mP(1,1),mP(1,2),x(:,1),x(:,2))),P);
            if any(ii)
                % if so, retrieve/update the sub-region information                
                obj.updateTubeHighlight(hTube{ii});                          
                
                % determines if the mouse is over any potential markers
                indT = get(hTube{ii},'UserData');
                iMap = obj.Imap(sub2ind(size(obj.Imap),mP(1,2),mP(1,1)));
                obj.updateFlyHighlight(iMap,indT); 
                
                % resets the mouse pointer
                if iMap > 0; pStr = 'hand'; end
                
            else
                % if the region index is set, then remove the highlight
                obj.updateFlyHighlight(0); 
                obj.updateTubeHighlight([]);                                
            end
            
            % resets the mouse point icon
            set(obj.hFig,'Pointer',pStr);            
            
        end           
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- calculates the coordinates of the axes with respect to the 
        %     global coordinate position system
        function calcAxesGlobalCoords(obj)

            % retrieves the position vectors for each associated panel/axes
            pPosP = get(obj.hGUI.panelImg,'Position');
            axPos = get(obj.hGUI.imgAxes,'Position');

            % calculates the global x/y coordinates of the
            obj.axPosX = (pPosP(1)+axPos(1)) + [0,axPos(3)];
            obj.axPosY = (pPosP(2)+axPos(2)) + [0,axPos(4)];  
        
        end

        % --- determines if the mouse pointer is over the image axes
        function isOver = isOverImageAxes(obj)
        
            % determines if the mouse position is over the image axes
            mPos = get(obj.hFig,'CurrentPoint');
            isOver = prod(sign(obj.axPosX - mPos(1))) == -1 && ...
                     prod(sign(obj.axPosY - mPos(2))) == -1;        
        
        end                      

        % --- creates the general background image
        function createGenBGImage(obj,iSel)

            % memory allocation
            IbgNw = NaN(size(obj.ImgFrm0));

            % combines the background image over all regions
            for i = 1:length(obj.iMov.iR)
                IbgNw(obj.iMov.iR{i},obj.iMov.iC{i}) = ...
                    max(IbgNw(obj.iMov.iR{i},obj.iMov.iC{i}),...
                           obj.iMov.Ibg{iSel}{i},'omitnan');
            end

            % sets the other remaining pixel values
%             isN = isnan(IbgNw);
%             IbgNw(isN) = obj.ImgFrm0(isN);
%             IbgNw(isN) = median(IbgNw(~isN),'omitnan');
            
            % updates the array in the background image cell array
            obj.Ibg{iSel} = IbgNw;

        end        
        
        % --- sets the manual object enabled properties
        function setManualObjProps(obj,state)
            
            switch lower(state)
                case 'on'
                    % enables the panel (ignores the remove/update buttons)
                    hIgnore = [obj.hGUI.buttonRemoveManual,...
                               obj.hGUI.buttonUpdateManual];
                    setPanelProps(obj.hGUI.panelManualSelect,'on',hIgnore)
                    
                case 'off'
                    % clears the stored list
                    obj.uList = [];
                    
                    % disables the entire panel                    
                    setPanelProps(obj.hGUI.panelManualSelect,'off')
                    
                    % clears the marker table
                    setHorizAlignedTable(obj.hGUI.tableFlyUpdate,[])
                    
                    % deletes all the manual markers
                    obj.deleteManualMarkers();
                    if ~isempty(obj.hManual)
                        delete(obj.hManual);
                        obj.hManual = [];
                    end
            end
        end
        
        % --- updates the enabled properties of the manual detect button
        function setManualDetectEnable(obj)
            
            % determines if there are any manual corrections listed
            if ~isempty(obj.uList)
                % retrieves the userdata arrays from the plot markers
                uData = cell2mat(arrayfun(@(x)...
                            (get(x,'UserData')),obj.hManual(:),'un',0));

                % markers for this frame are shown (otherwise disabled)
                isShow = (uData(:,1) == obj.iPara.cPhase) & ... 
                         (uData(:,2) == obj.iPara.cFrm);
                setObjVisibility(obj.hManual(isShow),'on')
                setObjVisibility(obj.hManual(~isShow),'off')   
            end
            
            % updates the manual detection button
%             setObjEnable(obj.hGUI.buttonAddManual,1)
            setObjEnable(obj.hGUI.buttonUpdateManual,~isempty(obj.uList))

        end   
        
        % --- retrieves the currently selected image type
        function imgType = getSelectedImageType(obj,iSel)

            % sets the currently selected index
            if ~exist('iSel','var')
                iSel = get(obj.hGUI.popupImgType,'Value');
            end

            % returns the string associated with the selected index
            lStr = get(obj.hGUI.popupImgType,'String');
            imgType = lStr{iSel};

        end  
        
        % --- retrieves the tracking parameters (depending on track type)
        function bgP = getTrackingPara(obj,pFld)
                     
            if detMltTrkStatus(obj.iMov)
                % case is multi-tracking
                bgP = getTrackingPara(obj.iMov.bgP,'pMulti');
                
            else
                % case is single-tracking
                bgP = getTrackingPara(obj.iMov.bgP,'pSingle');
            end
            
            % retrieves the struct sub-field (if provided)
            if exist('pFld','var')
                bgP = getStructField(bgP,pFld);
            end
            
        end  
        
        % --- retrieves the tracking parameters (depending on track type)
        function setTrackingPara(obj,pFld,pVal)
                     
            if detMltTrkStatus(obj.iMov)
                % case is multi-tracking
                obj.iMov.bgP = ...
                        setTrackingPara(obj.iMov.bgP,'pMulti',pFld,pVal);
            else
                % case is single-tracking
                obj.iMov.bgP = ...
                        setTrackingPara(obj.iMov.bgP,'pSingle',pFld,pVal);
            end
            
        end      
        
        % --- sets the video information properties
        function setVideoInfoProps(obj)
            
            % video property fields
            txtCol = 'kr';
            phInfo = obj.iMov.phInfo;
            nPhase = length(obj.iMov.vPhase);
            stStr = {'Stable','Unstable'};
            trStr = {'Not Detected','Detected'};
            
            % sets the image fluctuation/translation flags
            if obj.isCalib
                [hasF,hasT] = deal(false);
            else
                [hasF,hasT] = deal(phInfo.hasF,any(phInfo.hasT));
            end
            
            % updates the video information strings
            set(obj.hGUI.textImagQual,'string',stStr{1+hasF},...
                            'ForegroundColor',txtCol(1+hasF))
            set(obj.hGUI.textTransStatus,'string',trStr{1+hasT},...
                            'ForegroundColor',txtCol(1+hasT))
            set(obj.hGUI.textPhaseCount,'string',num2str(nPhase))
            
        end        
    
        % --- resets the figure width
        function resetFigWidth(obj,isOn)
            
            % retrieves the outer panel position vector
            pPos = get(obj.vcObj.hPanelO,'Position');            
            setObjVisibility(obj.hFig,0); pause(0.05);
            
            % resets the figure width
            dWid = (2*isOn - 1)*(pPos(3) + obj.vcObj.dX);
            resetObjPos(obj.hFig,'Width',dWid,1);
            resetObjPos(obj.hFig,'Left',-dWid/2,1);
            
            % resets the left position of the figure
            fPosM = get(obj.hFig,'Position');
            if fPosM(1) < obj.vcObj.dX
                resetObjPos(obj.hFig,'Left',obj.vcObj.dX);
            end
            
            % makes the figure visible again
            setObjVisibility(obj.hFig,1);
            
        end        
        
        % --- sets the object properties based on the state, eState
        function setGUIObjProps(obj,eState)
            
            % updates the gui object properties
            if strcmp(eState,'off')
                % takes a snapshot of the gui properties
                hPanelBG = obj.hGUI.panelBGDetect;
                obj.hPropT = getHandleSnapshot(hPanelBG,1);
                
                % disables all the objects from the bg estimate panel
                arrayfun(@(x)(setObjEnable(x.hObj,0)),obj.hPropT)
                
            else
                % resets the object properties
                resetHandleSnapshot(obj.hPropT)
            end
            
            % sets the menu item
            setObjEnable(obj.hMenuBG,eState)
            
        end        
        
        % --- determines which phases are feasible (from feasInd)
        function okPh = detFeasPhase(obj,indF)

            if ~exist('indF','var'); indF = obj.feasInd; end
            okPh = arrayfun(@(x)(any(indF==x)),obj.iMov.vPhase);

        end        
        
    end
    
    % static class methods
    methods (Static)
    
        % --- function that initialises the parameter struct
        function iPara = initParaStruct(nFrm)

            % initialises the parameter struct
            iPara = struct('nFrm',nFrm,'nFrm0',nFrm,'cFrm',1,'cPhase',1);

        end        
    
    end
    
end
