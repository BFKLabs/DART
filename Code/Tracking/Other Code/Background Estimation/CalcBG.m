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
        
        % array dimensioning
        nApp
        nTube              
        
        % global flags 
        is2D
        isDD  
        isCalib
        isVisible
        isChange
        isMultiTrack
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
        jTable
        Imap
        pMn
        
        % manual tracking fields
        pCol0
        iCloseR
        iCloseSR
        iCloseF
        
        % other important fields
        ImgFrm
        Ibg
        pBG
        fPos
        sImgS        
        BgrpT        
        axPosX 
        axPosY
        
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
            
            % initialises the GUI objects
            obj.initObjectCallbacks()  
            obj.calcAxesGlobalCoords()                        
                     
        end         
        
        % ---------------------------------- %
        % ---- GUI OPEN/CLOSE FUNCTIONS ---- %
        % ---------------------------------- %        
        
        % --- opens the background analysis gui
        function openBGAnalysis(obj)
            
            % makes the main gui invisible
            setObjVisibility(obj.hFig,'off'); pause(0.05);
            
            % stops the camera (if running)
            if obj.isCalib
                infoObj = getappdata(obj.hFig,'infoObj');  
                if strcmp(get(infoObj.objIMAQ,'Running'),'off')
                    start(infoObj.objIMAQ); pause(0.05); 
                end                
            end
            
            % toggles the normal/background estimate panel visibilities
            obj.resetGUIDimensions(true)              
            
            % initialises the class fields
            obj.initClassFields()
            obj.initLikelyPlotMarkers()
            obj.initObjProps()        
            obj.setManualObjProps('off')
            pause(0.05);
            
            % makes the main gui visible again
            setObjVisibility(obj.hFig,'on');   
            obj.updateManualTrackTable()
            
        end        
        
        % --- close the background analysis gui
        function closeBGAnalysis(obj)
            
            % global variables
            global isMovChange
            
            % initialisations
            hgui = obj.hGUI;
            
            % removes the menu check
            hh = guidata(obj.hFig);
            if strcmp(get(hh.menuFlyAccRej,'Checked'),'on')            
                obj.menuFlyAccRej(hh.menuFlyAccRej, [])
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
                setappdata(obj.hFig,'pData',[])
                setappdata(obj.hFig,'iMov',obj.iMov) 
                
%                 % initialises the plot markers
%                 markerFcn = getappdata(obj.hFig,'initMarkerPlots');
%                 markerFcn(hgui,1); pause(0.01); 
            else
                % otherwise, reset to the original sub-region data struct
                setappdata(obj.hFig,'iMov',obj.iMov0)                        
            end                
            
            % update axes with the original image (non-calibrating only)
            if obj.isCalib
                % stops the camera (if running)
                infoObj = getappdata(obj.hFig,'infoObj'); 
                if strcmp(get(infoObj.objIMAQ,'Running'),'on')
                    stop(infoObj.objIMAQ); pause(0.05); 
                end
                
            else
                dispFcn = getappdata(obj.hFig,'dispImage');
                dispFcn(hgui,obj.ImgFrm0,1)
            end                           

            % -------------------------------- %
            % ---- FIGURE/OBJECT DELETION ---- %
            % -------------------------------- %
            
            % retrieves the currently opened figures
            hFigAll = findall(0,'type','figure');  

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
                try; delete(obj.hInfo); end
                obj.hInfo = [];
            end        
            
            % retrieves the manual marker objects
            obj.deleteManualMarkers();  
            
            % deletes any manual markers
            if ~isempty(obj.hManual)
                delete(obj.hManual)
                obj.hManual = [];
            end
            
            % loops through all the apparatus 
            for i = 1:length(obj.iMov.iR)
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
            obj.ImgFrm = [];
            obj.sImgS = [];
            obj.BgrpT = [];
            
            % -------------------------------- %
            % ---- OTHER PROPERTY UPDATES ---- %
            % -------------------------------- %      

            % removes the tube regions (if showing)
            set(obj.hGUI.checkTubeRegions,'value',0);
            obj.checkTubeRegions(obj.hGUI.checkTubeRegions, [])

            % turns on the local viewing panel
            chkFunc = getappdata(obj.hFig,'checkLocalView_Callback');
            chkFunc(obj.hGUI.checkLocalView, 1, obj.hGUI)

            % updates the axis colour limit
            set(obj.hGUI.imgAxes,'CLimMode','Auto')
            
            % sets the pre-background detection properties
            setTrackGUIProps(obj.hGUI,'PostTubeDetect',obj.isChange);                                   
            
            % -------------------------------------- %            
            % ---- FINAL FIGURE RE-DIMENSIONING ---- %
            % -------------------------------------- %
            
            % toggles the normal/background estimate panel visibilities
            obj.resetGUIDimensions(false)
            setappdata(obj.hGUI.figFlyTrack,'bgObj',obj)
                                   
            % sets the menu item visibiity properties
            setObjVisibility(hgui.panelBGDetect,'off') 
            setObjVisibility(hgui.panelOuter,'on')            
            obj.setMenuVisibility(false);                   
            
            % makes the main tracking gui visible again
            setObjVisibility(obj.hFig,'on'); 
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
                        
                        % enables the manual correction control buttons
                        setObjEnable(obj.hGUI.buttonAddManual,1)
                        setObjEnable(obj.hGUI.buttonRemoveManual,0)
                        setObjEnable(obj.hGUI.buttonUpdateManual,1)
                        
                        % disables everything else
                        obj.manualButtonClick(hObject, 'alt') 
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
                     'buttonUpdateStack',...
                     'frmFirstPhase','frmPrevPhase','frmNextPhase',...
                     'frmLastPhase','editPhaseCount',...      
                     'frmFirstFrame','frmPrevFrame','frmNextFrame',...
                     'frmLastFrame','editFrameCount',...
                     'checkTubeRegions','checkFlyMarkers',...
                     'buttonUpdateEst','buttonAddManual',...
                     'buttonRemoveManual','buttonUpdateManual'};                   
            for i = 1:length(cbObj)
                hObj = eval(sprintf('obj.hGUI.%s;',cbObj{i}));
                cbFcn = eval(sprintf('@obj.%s',cbObj{i}));
                set(hObj,'Callback',cbFcn)
            end
            
            % objects with selection changed callback functions
            scObj = {'panelImageType'};
            for i = 1:length(scObj)
                hObj = eval(sprintf('obj.hGUI.%s;',scObj{i}));
                cbFcn = eval(sprintf('@obj.%s',scObj{i}));
                set(hObj,'SelectionChangedFcn',cbFcn)
            end
                 
            % objects with cell selection callback functions
            csObj = {'tableFlyUpdate'};
            for i = 1:length(csObj)
                hObj = eval(sprintf('obj.hGUI.%s;',csObj{i}));
                cbFcn = eval(sprintf('@obj.%s',csObj{i}));
                set(hObj,'CellSelectionCallback',cbFcn)
            end                 
            
        end           
        
        % --- initialises the class fields when starting bg detection mode
        function initClassFields(obj)
            
            % initialisations
            hgui = obj.hGUI;
            
            % retrieves the sub-region/program data structs
            [obj.iMov,obj.iMov0] = deal(getappdata(obj.hFig,'iMov'));
            obj.iData = getappdata(obj.hFig,'iData');   
            obj.iPara = obj.initParaStruct(10); 
            obj.is2D = is2DCheck(obj.iMov);
            obj.isMultiTrack = detIfMultiTrack(obj.iMov);
            
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
                obj.trkObj = MultiTrackInit(obj.iData);
            end
            
            % sets the calibration field
            obj.trkObj.setClassField('isCalib',obj.isCalib);
            
            % initial main gui properties
            obj.ok0 = obj.iMov.flyok;
            obj.hProp0 = getHandleSnapshot(hgui);
            if ~obj.isCalib
                % retrieves the image data from the current axis
                hImage = findobj(hgui.imgAxes,'type','image');
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
            
            % initialises the global parameter fields 
            obj.hManual = [];
            [obj.iSel,obj.BgrpT] = deal([1,1],BgrpT0);
            [obj.isChange,obj.frameSet] = deal(false);
            [obj.hasUpdated,obj.isBGCalc] = deal(false);
            [obj.uList,obj.fUpdate] = deal([]);
            [obj.isAllUpdate,obj.nManualMx] = deal(true,15);             
            
        end        
        
        % --- initialises the bg estimation object properties
        function initObjProps(obj)

            % retrieves the parameter data struct
            hgui = obj.hGUI;
            imov = obj.iMov;
            idata = obj.iData;
            
            % other initialisations
            cHdr = {'Phase','Frame','Region','Sub-Region'};

            % sets the pre-background detection properties
            setTrackGUIProps(hgui,'PreTubeDetect');

            % toggles the normal/background estimate panel visiblities
            setObjVisibility(hgui.panelOuter,'off')
            setObjVisibility(hgui.panelBGDetect,'on')            
            obj.setMenuVisibility(true);                       
            
            % updates the frame/edit count count
            setPanelProps(hgui.panelPhaseSelect,'off')
            setPanelProps(hgui.panelFrameSelect,'off')
            setPanelProps(hgui.panelManualSelect,'off')
            setObjEnable(hgui.buttonUpdateEst,'off')

            % updates the table position
            tPos = get(hgui.tableFlyUpdate,'position');
            tPos(4) = calcTableHeight(obj.nManualMx);
            set(setObjEnable(hgui.tableFlyUpdate,'off'),...
                       'Data',[],'Position',tPos,'ColumnName',cHdr)
            autoResizeTableColumns(hgui.tableFlyUpdate);

            % determines if the background has been calculated
            if ~initDetectCompleted(imov)
                % if not, disable the frame selection panels
                setPanelProps(hgui.panelImageType,'off')
                setObjEnable(hgui.checkFlyMarkers,'off')

                % clears the frame count string
                set(hgui.editFrameCount,'string','')               
                set(hgui.editPhaseCount,'string','')     
                
                % sets the phase count and variance type
                set(hgui.textPhaseCount,'string','N/A');
                set(hgui.textPhaseFrames,'string','N/A');    
                set(hgui.textPhaseStatus,'string','N/A'); 
                
                % updates the text fields
                set(hgui.textStartFrame,'string','N/A')
                set(hgui.textEndFrame,'string','N/A')                
                set(hgui.textCurrentFrame,'string','N/A')                  

            else 
                % updates the sub-image data struct with the frame  
                nPhase = length(imov.vPhase);
                [sImgS0,Img0] = deal(cell(nPhase,1));                
                
                % retrieves the first frame for each phase
                for i = 1:nPhase
                    if obj.isCalib
                        Img0{i} = double(get(findobj...
                                (obj.hGUI.imgAxes,'type','image'),'CData'));
                    else
                        Img0{i} = double(getDispImage(...
                                idata,imov,imov.iPhase(i,1),0));  
                    end
                                
                    sImgS0{i} = setSubImageStruct(imov,Img0{i});
                end  

                % sets the sub-image frame value
                obj.sImgS = cell2mat(sImgS0);
                if length(obj.sImgS) == 1
                    obj.sImgS.iFrm = 1;
                else
                    for i = 1:length(obj.sImgS)
                        obj.sImgS(i).iFrm = obj.iMov.iPhase(i,1);
                    end
                end

                % sets the frame count stringx1
                iFrm = num2str(obj.sImgS(1).iFrm);
                set(hgui.editFrameCount,'string','1')          
                set(hgui.textCurrentFrame,'string',iFrm)        
                set(setObjEnable(hgui.checkFlyMarkers,'on'),'value',1)  

                % likely/potential object locations
                obj.ImgFrm = Img0;
                
                % determines if the class object has location values
                if ~isempty(obj.fPos)
                    % if the class object has previous solution values,
                    % then use them as the initial points
                    ii = ~cellfun(@isempty,obj.fPos);
                    obj.fPos(ii) = cellfun...
                                    (@(x)(x(:,1)),obj.fPos(ii),'un',0);
                    
                else
                    % retrieves the positional data from the main gui
                    pData = getappdata(obj.hGUI.figFlyTrack,'pData');
                    if ~isempty(pData)                    
                        % if there is positional data, then store the
                        % position values for the 1st frame of each phase                                                
                        iFrmL = obj.iMov.iPhase(:,1);
                        obj.fPos = cell(nPhase,1);
                        
                        % calculates the region vertical offsets
                        yOfs = cellfun(@(ir,n)(repmat(...
                                [0,ir(1)]-1,n,1)),imov.iR,...
                                num2cell(obj.nTube)','un',0)';
                        
                        % memory allocation                        
                        for i = 1:nPhase
                            % retrieves the position data 
                            obj.fPos{i} = cellfun(@(y,dy)(dy+cell2mat(...
                                    cellfun(@(x)(x(iFrmL(i),:)),y(:),...
                                    'un',0))),pData.fPos(:),yOfs,'un',0);
                        end    
                    end
                end

                if ~isempty(obj.fPos)
                    % initialises the potential plot markers
                    obj.initPotentialPlotMarkers()                      

                    % updates the 
                    obj.updateObjMarkers()
                    obj.checkFlyMarkers(hgui.checkFlyMarkers, [])
                    obj.updateMainImage()      
                end

                % enables the phase panel properties (if more than one phase       
                setPanelProps(hgui.panelPhaseSelect,'on')
                obj.setButtonProps('Phase')
            end            
            
        end
        
        % --- initialises the likely object markers
        function initLikelyPlotMarkers(obj)
            
            % retrieves the sub-movie data struct
            hgui = obj.hGUI;
            imov = obj.iMov;
            
            % memory allocation
            obj.hMark = cell(1,obj.nApp);

            % sets focus to the main GUI axes
            set(hgui.figFlyTrack,'CurrentAxes',hgui.imgAxes)

            % loops through all the sub-regions creating markers 
            hold on
            for i = 1:length(imov.iR)
                % memory allocation
                tStr = sprintf('hFlyTmp%i',i);
                obj.hMark{i} = cell(obj.nTube(i),1);

                % deletes any previous markers
                hMarkPr = findobj(obj.hAx,'tag',tStr);
                if ~isempty(hMarkPr); delete(hMarkPr); end    

                % creates the markers for all the tubes
                for j = 1:obj.nTube(i)
                    obj.hMark{i}{j} = plot(NaN,NaN,'tag',tStr,...
                                        'linestyle','none','visible',...
                                        'off','UserData',[i,j]);
                end
            end
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
            obj.hMarkAll = scatter(NaN,NaN,'k','tag','hFlyAll');
            hold(obj.hAx,'on')
            
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
            simgs = obj.sImgS;
            imov = obj.iMov;

            % initialisations
            frmSz = getCurrentImageDim(hgui);
            [h,iPhase,cLim] = deal([],ipara.cPhase,[]);
            [iok,vPhase] = deal(imov.ok,imov.vPhase(iPhase));
            
            % retrieves the data structs/function handles from the main GUI     
            dispImage = getappdata(hgui.figFlyTrack,'dispImage');            

            % sets the table java object (if GUI is visible and handle not set)
            if obj.isVisible
                % sets the table java object into the table handle
                if isempty(obj.jTable)
                    hh = findjobj(hgui.tableFlyUpdate);
                    obj.jTable = hh.getComponent(0).getComponent(0);
                end
            end

            % sets the current image stack
            IL = simgs(iPhase).I(ipara.cFrm,:);

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

            % sets the image
            switch get(get(hgui.panelImageType,'SelectedObject'),'tag')
                case ('radioNormal') % case is the normal image frame                

                    % sets the composite images from the local images
                    if any(vPhase == [3 4])
                        Inw = getDispImage(idata,imov,...
                                    simgs(iPhase).iFrm(ipara.cFrm),false);  
                                
                    else
                        % equalises the image (if low-variance phase)
                        if vPhase == 1
                            IL = obj.equaliseImg(IL,iPhase);
                        end
                        
                        % creates the composition image
                        Inw = createCompositeImage(...
                                        obj.ImgFrm{iPhase},imov,IL);    
                    end        

                case ('radioBackEst') % case is the background estimate        

                    % sets the background image based on the detection type
                    if strcmp(getDetectionType(imov),'GeneralR')
                        % retrieves the background image array      
                        if isempty(obj.Ibg{iPhase})                                            
                            % creates the background image (if not present)
                            obj.createGenBGImage(iPhase);
                        end

                        % sets the final viewing image
                        Inw = obj.Ibg{iPhase};
                        
                    elseif vPhase == 1
                        % creates composite image from the phase bg images                       
                        Inw = createCompositeImage(...
                                obj.ImgFrm{iPhase},imov,imov.Ibg{iPhase}); 
                            
                    else
                        % creates composite image from the total bg images
                        Ib = zeros(size(obj.ImgFrm{1}));
                        Inw = createCompositeImage(Ib,imov,imov.IbgT);
                    end                         

                case ('radioRes') % case is the fly residual

                    % sets the image stack
                    if vPhase == 1
                        % case is the low-variance phase
                        ILs = obj.equaliseImg(IL,iPhase);
                        
                    else
                        % case is the other phase types
                        N = 50;
                        ILex = cellfun(@(x)(expandImg(x,N)),IL,'un',0);
                        
                        % case is a non low-variance phase
                        ILexs = removeImageMedianBL(ILex,0,obj.is2D);
                        ILs = cellfun(@(x)(x((N+1):(end-N),...
                                            (N+1):(end-N))),ILexs,'un',0);
                        
                    end

                    % sets the background image based on the detection type
                    if strcmp(getDetectionType(imov),'GeneralR')
                        % retrieves the background image array
                        if isempty(obj.Ibg{iPhase})                                         
                            % creates the background image if it does not exist
                            obj.createGenBGImage(iPhase);
                        end

                        % sets the final viewing image            
                        Itot = createCompositeImage(zeros(frmSz),imov,ILs);
                        Inw = (obj.Ibg{iPhase} - Itot).*(Itot > 0); 
                        
                    elseif vPhase == 1
                        % reshapes the local image array
                        ILs = reshape(ILs,size(imov.Ibg{iPhase}));
                        
                        % creates the composite from the phase bg image
                        IRL = cell(size(ILs));
                        IRL(iok) = cellfun(@(x,y)...
                              (x-y),imov.Ibg{iPhase}(iok),ILs(iok),'un',0);
                        Inw = createCompositeImage(zeros(frmSz),imov,IRL);   
                                                
                    else
                        % creates the composite from the total bg image 
                        IRL = cellfun(@(x,y)...
                                        (x-y),ILs,obj.iMov.IbgT,'un',0);
                        Inw = createCompositeImage(zeros(frmSz),imov,IRL); 
                    end           
                       
            end

            % updates the axis colour limit
            if isempty(cLim)
                set(obj.hAx,'CLimMode','Auto')
            else
                set(obj.hAx,'clim',cLim)
            end

            % updates the markers (if they exist)
            if ~isempty(obj.fPos)
                obj.updateObjMarkers()
            end

            % updates the main GUI image axis
            dispImage(hgui,Inw,1); pause(0.05);

            % updates and closes the waitbar
            if ~isempty(h)
                waitbar(1,h,'Image Update Complete');
                close(h);
            end
            
        end
        
        % --- initialises the temporary fly markers
        function updateObjMarkers(obj)

            % retrieves the sub-movie data struct
            ipara = obj.iPara;
            imov = obj.iMov; 
            
            % other initialisations
            [iPhase,iFrm,pCol] = deal(ipara.cPhase,ipara.cFrm,'g');
            isHiVar = imov.vPhase(iPhase) >= 3;

            % sets the marker properties            
            if ispc
                [pMark,mSz] = deal('.',20);
            else                
                [pMark,mSz] = deal('*',8);
            end                
            
            % marker coordinate arrays
            fpos = obj.fPos{iPhase};            

            % updates the fly markers for all apparatus
            for iApp = 1:length(imov.iR)
                % retrieves the position values
                if obj.isMultiTrack
                    % updates the marker locations
                    fPosNw = fpos{iApp,iFrm};
                    [iCol,~,iRow] = getRegionIndices(obj.iMov,iApp);
                    set(obj.hMark{iApp}{1},'xdata',fPosNw(:,1),...
                                           'ydata',fPosNw(:,2))                                                                                 

                    % updates the other properties                        
                    if imov.flyok(iRow,iCol)
                        set(obj.hMark{iApp}{1},'marker',pMark,...
                                    'color',pCol,'markersize',mSz);                                
                    end
                    
                else   
                    % retrieves the position coord (non-hi var phase only)
                    if ~isHiVar; fPosNw = fpos{iApp,iFrm}; end
                    
                    for iT = find(imov.flyok(:,iApp))'
                        % updates the marker locations
                        if isHiVar
                            % case is a hi-variance phase
                            set(obj.hMark{iApp}{iT},'xdata',NaN,...
                                                    'ydata',NaN)                            
                        else                                                       
                            % case is a non hi-variance phase 
                            set(obj.hMark{iApp}{iT},'xdata',fPosNw(iT,1),...
                                                    'ydata',fPosNw(iT,2))
                        end

                        % updates the other properties                        
                        if imov.flyok(iT,iApp)
                            set(obj.hMark{iApp}{iT},'marker',pMark,...
                                        'color',pCol,'markersize',mSz);                                
                        end
                    end
                end
            end

        end

        % retrieves the parameter and sub-image data structs
        function setButtonProps(obj,Type)

            % retrieves the parameter and sub-image data structs
            hgui = obj.hGUI;
            imov = obj.iMov;
            ipara = obj.iPara;
            simgs = obj.sImgS;
            
            % parameters
            pCol = {'k','b','m','r',[153 51 0]/255,'k'};
            pType = {'Low Var','Hi Var','Untrackable',...
                     'Invalid','Small','Direct'};                        

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
                     sprintf(['* Invalid video phase.\n',...
                              '--> Severe issues with the lighting in video phase.\n',...
                              '--> No tracking will be undertaken.']);...
                     sprintf(['* Small experimental regions.\n',...
                              '--> Fly locations determined by SVM statistical classification.\n',...
                              '--> Tracking efficacy should be high.']); 
                     sprintf(['* Direct analysis phase.\n',...
                              '--> Fly location determined by direct analysis.\n',...
                              '--> Tracking efficacy should be high if arena is small.'])}; 

            % sets local and global frame indices
            iFrmNw = num2str(simgs(ipara.cPhase).iFrm(ipara.cFrm));
            set(hgui.editFrameCount,'string',num2str(ipara.cFrm));
            set(hgui.textCurrentFrame,'string',iFrmNw);

            % sets the manual detection button enabled properties
            obj.setManualDetectEnable();
            
            % updates the phase properties (if updating the phase objects)
            if strcmp(Type,'Phase')
                % sets the phase variance type/index and phase count
                vP = imov.vPhase(ipara.cPhase);
                [cX,nX] = deal(ipara.cPhase,length(simgs));
                iPhaseNw = obj.iMov.iPhase(ipara.cPhase,:);
                nFrm = diff(iPhaseNw) + 1;                
                
                % sets the phase count and variance type
                set(setObjEnable(hgui.editPhaseCount,nX>1),...
                                         'string',num2str(cX));
                set(hgui.textPhaseStatus,'string',pType{vP},...
                                         'foregroundcolor',pCol{vP},...
                                         'tooltipstring',ttStr{vP});    
                set(hgui.textPhaseStatusL,'tooltipstring',ttStr{vP}); 
                
                % updates the text fields
                set(hgui.textPhaseFrames,'string',num2str(nFrm))
                set(hgui.textStartFrame,'string',num2str(iPhaseNw(1)))
                set(hgui.textEndFrame,'string',num2str(iPhaseNw(2)))                
                
                % sets the radio button enabled properties (if valid or not)
                if ~isempty(obj.fPos)
                    % boolean flags
                    isLoVar = vP == 1;
                    isHiVar = vP == 3;
                    hasBG = isLoVar || ~isempty(obj.iMov.IbgT);    

                    % sets the enabled properties of the radio buttons                                        
                    setObjEnable(hgui.radioRes,hasBG)  
                    setObjEnable(hgui.radioBackEst,isLoVar)
                    setObjEnable(hgui.checkFlyMarkers,~isHiVar)

                    % resets the radio buttons if the phase
                    if ~isLoVar && get(hgui.radioBackEst,'value')
                        % can't have a low-variance phase showing bg
                        set(hgui.radioNormal,'value',1);
                        obj.updateMainImage()      

                    elseif ((any(vP == [3,4])) && ...
                                      ~get(hgui.radioNormal,'value'))
                        % can't have invalid phase show bg or residuals
                        set(hgui.radioNormal,'value',1);
                        obj.updateMainImage()
                    end
                end

                % updates the frame properties
                obj.setButtonProps('Frame')
            else
                [cX,nX] = deal(ipara.cFrm,length(simgs(ipara.cPhase).iFrm));
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
            setObjVisibility(obj.hGUI.menuView,~openBG)
            
            if isfield(obj.hGUI,'menuRTCalib')
                setObjVisibility(obj.hGUI.menuRTCalib,~openBG && obj.isCalib)
            end

            % turns off the normal mode menu items
            setObjVisibility(obj.hGUI.menuEstBG,openBG)

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
                try; delete(obj.hInfo.hFig); end
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

            % runs the reflection glare parameter GUI
            bgPnw = BackgroundPara(obj.iMov);
            if ~isempty(bgPnw)
                % updates the parameter data struct
                obj.iMov.bgP = bgPnw;
            end        
            
        end   
        
        % -----------------------------------------------------------------
        function menuCloseEstBG(obj, ~, ~)

            % updates the change flag wrt the ok flags
            obj.iMov.ddD = [];
            obj.isChange = obj.isChange || (sum(abs(double(obj.ok0(:))-...
                                        double(obj.iMov.flyok(:))))>0);

            % if there is a change/update then prompt the user if they wish
            % to proceed with updating the changes
            if obj.hasUpdated || obj.isChange
                tStr = 'Update Background Estimate Image?';
                uChoice = questdlg(['Do you want to update the ',...
                                    'background estimate changes?'],...
                                    tStr,'Yes','No','Yes');
                if ~strcmp(uChoice,'Yes')
                    obj.isChange = false;
                end
            end        
            
            % coverts the tracking gui to normal tracking mode
            obj.closeBGAnalysis()
            
        end
        
        % ---------------------------------------- %
        % --- IMAGE STACK SIZE/SETUP CALLBACKS --- %
        % ---------------------------------------- %       

        % --- Executes on button press in buttonUpdateStack.
        function buttonUpdateStack(obj, ~, ~)

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
                infoObj = getappdata(obj.hFig,'infoObj');    
                
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
                simgs = setSubImageStruct(imov,Img);  
                simgs.iFrm = (1:ipara.nFrm0)';

                % sets the image stack 
                imov.vPhase = 1;
                imov.iPhase = [1,ipara.nFrm0];
                obj.ImgFrm = Img(1);
                obj.ImgC = {Img};
                
            else
                % retrieves the current frame from file                                
                [imov,simgs,Img] = getEstimateImageStack(idata,imov);

                % sets an empty sub-image struct   
                if isempty(simgs)
                    % if the user cancelled, then exit the function
                    return    
                end
            end

            % updates the parameter struct   
            obj.iMov = imov;
            obj.frameSet = true;
            [obj.isAllUpdate,obj.hasUpdated] = deal(true,false);
            [obj.iPara.cFrm,obj.iPara.cPhase] = deal(1,1);
            obj.iPara.nFrm = length(simgs(1).iFrm);

            % enables the image display properties
            setPanelProps(hgui.panelFrameSelect,'on')
            setPanelProps(hgui.panelImageType,'on')
            setObjEnable(hgui.radioBackEst,'off')
            setObjEnable(hgui.radioRes,'off')

            % disables the manual resegmentation list
            setPanelProps(hgui.panelManualSelect,'off')
            set(hgui.textPhaseCount,'string',num2str(length(simgs)))

            % determines if that are any valid phases
            if ~all(obj.iMov.vPhase == 4)
                % if so, then enable the update estimate button
                setObjEnable(hgui.buttonUpdateEst,'on')    
            end

            % sets the enables properties of the phase selection objects
            setPanelProps(hgui.panelPhaseSelect,'on');   
            if ~obj.isCalib
                if length(simgs) > 1
                    % sets 1st frame for each phase as the background image
                    imgfrm = cellfun(@(x)...
                            (calcImageStackFcn(x,'median')),Img,'un',0);
                    obj.ImgFrm = imgfrm; 
                else
                    obj.ImgFrm = Img{1}(1);
                end
            end
            
            % disables the manual tracking panel
            obj.setManualObjProps('off')
            
            % turns off the fly markers
            set(setObjEnable(hgui.checkFlyMarkers,'off'),'value',0);
            obj.checkFlyMarkers(hgui.checkFlyMarkers, [])

            % updates the image frame and the program data struct
            obj.sImgS = simgs;
            obj.iData = idata;
            obj.fPos = [];                        

            % updates the main image axes
            set(hgui.radioNormal,'value',1)
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
            obj.iPara.cFrm = min(obj.iPara.cFrm,...
                        length(obj.sImgS(obj.iPara.cPhase).iFrm));

            % updates the button properties and the main image
            obj.setButtonProps('Phase')
            obj.updateMainImage()
            
        end

        % --- Executes on button press in frmPrevPhase.
        function frmPrevPhase(obj, ~, ~)

            % retrieves the parameter and sub-image data structs
            if obj.iPara.cPhase == 1; return; end

            % updates the parameter struct
            obj.iPara.cPhase = obj.iPara.cPhase - 1;
            obj.iPara.cFrm = min(obj.iPara.cFrm,...
                        length(obj.sImgS(obj.iPara.cPhase).iFrm));

            % updates the button properties and the main image
            obj.setButtonProps('Phase')
            obj.updateMainImage()
        
        end

        % --- Executes on button press in frmNextPhase.
        function frmNextPhase(obj, ~, ~)

            % retrieves the parameter and sub-image data structs
            if (obj.iPara.cPhase == length(obj.sImgS)); return; end

            % updates the parameter struct
            obj.iPara.cPhase = obj.iPara.cPhase + 1;
            obj.iPara.cFrm = min(obj.iPara.cFrm,...
                            length(obj.sImgS(obj.iPara.cPhase).iFrm));

            % updates the button properties and the main image
            obj.setButtonProps('Phase')
            obj.updateMainImage()
        
        end

        % --- Executes on button press in frmLastPhase.
        function frmLastPhase(obj, ~, ~)

            % updates the parameter struct
            obj.iPara.cPhase = length(obj.sImgS);
            obj.iPara.cFrm = min(obj.iPara.cFrm,...
                            length(obj.sImgS(obj.iPara.cPhase).iFrm));

            % updates the button properties and the main image
            obj.setButtonProps('Phase')
            obj.updateMainImage()
        
        end

        % --- Executes on updating in editPhaseCount.
        function editPhaseCount(obj, hObject, ~)

            % checks if the new value is valid
            nwVal = str2double(get(hObject,'string'));
            if (chkEditValue(nwVal,[1 length(obj.sImgS)],1))
                % if so, then update the frame index
                obj.iPara.cPhase = nwVal;
                obj.iPara.cFrm = min(obj.iPara.cFrm,...
                                         length(obj.sImgS(nwVal).iFrm));   

                % updates the button properties and the main image
                obj.setButtonProps('Phase')
                obj.updateMainImage()
            else
                % otherwise, revert back to the previous valid value
                set(hObject,'string',num2str(obj.iPara.cPhase))
            end
        
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
            if obj.iPara.cFrm == 1; return; end

            % updates the parameter struct
            obj.iPara.cFrm = obj.iPara.cFrm - 1;

            % updates the button properties and the main image
            obj.setButtonProps('Frame')
            obj.updateMainImage()
        
        end

        % --- Executes on button press in frmNextFrame.
        function frmNextFrame(obj, ~, ~)

            % retrieves the parameter and sub-image data structs
            if obj.iPara.cFrm == length(obj.sImgS(obj.iPara.cPhase).iFrm)
                return
            end

            % updates the parameter struct
            obj.iPara.cFrm = obj.iPara.cFrm + 1;

            % updates the button properties and the main image
            obj.setButtonProps('Frame')
            obj.updateMainImage()
        
        end

        % --- Executes on button press in frmLastFrame.
        function frmLastFrame(obj, ~, ~)

            % updates the parameter struct
            obj.iPara.cFrm = length(obj.sImgS(obj.iPara.cPhase).iFrm);

            % updates the button properties and the main image
            obj.setButtonProps('Frame')
            obj.updateMainImage()
        
        end

        % --- Executes on updating in editFrameCount.
        function editFrameCount(obj, hObject, ~)

            % checks if the new value is valid
            nwVal = str2double(get(hObject,'string'));
            nFrm = length(obj.sImgS(obj.iPara.cPhase).iFrm);
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
        
        % ---------------------------- %
        % --- IMAGE TYPE CALLBACKS --- %
        % ---------------------------- %

        % --- Executes when selected object is changed in panelImageType.
        function panelImageType(obj, ~, ~)

            % updates the main image axes
            obj.updateMainImage()
        
        end

        % ------------------------------------ %
        % --- VIDEO IMAGE MARKER CALLBACKS --- %
        % ------------------------------------ %        
        
        % --- Executes on button press in checkTubeRegions.
        function checkTubeRegions(obj, hObject, ~)

            % retrieves the tube show check callback function
            hgui = obj.hGUI;
            cFunc = getappdata(hgui.figFlyTrack,'checkShowTube_Callback');

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

            % sets the panel properties
            obj.setManualDetectEnable()
            
            % sets the marker visibility for all apparatus
            for i = 1:length(obj.hMark)
                indFly = 1:getSRCount(obj.iMov,i);
                cellfun(@(x,isOn)(setObjVisibility(x,isOn)),...
                        obj.hMark{i},num2cell(isOK & fok(indFly,i)))
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

            % progressbar strings
            wStr = {'Reading Initial Image Stack',...
                    'Image Baseline Subtraction',...
                    'Tracking Moving Objects'};    
            if obj.isMultiTrack
                wStr{end} = 'Background Image Estimation';
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
                obj.trkObj.setClassField('Img0',obj.ImgC)
            end

            % creates the waitbar figure
            if obj.isMultiTrack
                % case is tracking multiple objects
                
                % creates the progressbar figure            
                h = ProgBar(wStr,'Multiple Object Background Estimation'); 
                
                % calculates the initial location estimates
                obj.trkObj.calcInitEstimate(obj.iMov,h); 
                
            else
                % case is tracking a single object                
                
                % creates the progressbar figure            
                h = ProgBar(wStr,'Single Object Background Estimation'); 
                
                % calculates the initial location estimates
                obj.trkObj.calcInitEstimate(obj.iMov,h);                                 
            end

            % calculates the background image estimate
            [ok,imov] = deal(obj.trkObj.calcOK,obj.trkObj.iMov);
            if ok     
                % updates and closes the waitbar figure
                if ~h.Update(2,'Segmentation Complete',1)
                    h.closeProgBar();
                end        
                
                % if segmentation was successful, then update the 
                % sub-image data struct   
                obj.ok0 = imov.flyok;
                obj.iMov = imov;
                obj.Ibg = cell(length(imov.vPhase),1);   
                
                % updates the sub-region data struct in the main gui
                setappdata(obj.hGUI.figFlyTrack,'iMov',imov)
                
                % likely/potential object locations
                obj.fPos = cellfun(@(x)(x.fPosG),obj.trkObj.fObj,'un',0);

                % updates the list box properties but clears the list
                setPanelProps(obj.hGUI.panelManualSelect,'on')   
                set(obj.hGUI.tableFlyUpdate,'Data',[])
                setObjEnable(obj.hGUI.buttonRemoveManual,'off')
                setObjEnable(obj.hGUI.buttonUpdateManual,'off')                
                
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
                obj.updateObjMarkers()
                obj.checkFlyMarkers(obj.hGUI.checkFlyMarkers, [])
                obj.updateMainImage()
                
                % updates the frame/phase object properties
                obj.setButtonProps('Frame')
                obj.setButtonProps('Phase')

                % updates the other flags indicating success
                [obj.isChange,obj.hasUpdated] = deal(true);
                [obj.isAllUpdate,obj.uList] = deal(false,[]);
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
        function buttonAddManual(obj, hObject, ~)
            
            % if the tubes are on, then remove them
            if get(obj.hGUI.checkTubeRegions,'value')
                set(obj.hGUI.checkTubeRegions,'value',false)
                obj.checkTubeRegions(obj.hGUI.checkTubeRegions, [])
            end  
            
            % if the tubes are on, then remove them
            if get(obj.hGUI.checkFlyMarkers,'value')
                set(obj.hGUI.checkFlyMarkers,'value',false)
                obj.checkFlyMarkers(obj.hGUI.checkFlyMarkers, [])
            end               
            
            % sets the mouse motion callback function            
            setObjEnable(hObject,'off')
            setObjEnable(obj.hGUI.buttonUpdateManual,'off')
            [obj.iCloseR,obj.iCloseSR,obj.iCloseF] = deal(-1);
            
            % sets up the manual marker map
            [obj.Imap,obj.pMn] = setupManualMarkMap(obj);   
            
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
            
            % --------------------------------- %
            % --- BACKGROUND RE-CALCULATION --- %
            % --------------------------------- %        
            
            % creates the loadbar
            h = ProgressLoadbar('Updating Manual Resegmentation...');
            
            % calculates the background and position for each of the 
            % manually reset points
            for i = 1:length(iRowM)                
                obj.setupManualBGImages(iRowM{i});
            end       
            
            % loops through each phase/region interpolating any gaps
            for iPh = 1:obj.trkObj.nPhase
                for iApp = 1:obj.trkObj.nApp
                    % determines if there are any gaps in the images
                    if obj.trkObj.fObj{iPh}.iPh == 1                    
                        % case is for the low-variance phases
                        IBG = obj.trkObj.fObj{iPh}.IBG{iApp};
                        if any(isnan(IBG(:)))
                            % if there are gaps, then interpolate them
                            obj.trkObj.fObj{iPh}.IBG{iApp} = ...
                                                    interpImageGaps(IBG);
                        end
                    else
                        % case is for the high-variance phases
                        IBG = obj.iMov.IbgT{iApp};
                        if any(isnan(IBG(:)))
                            % if there are gaps, then interpolate them
                            obj.iMov.IbgT{iApp} = interpImageGaps(IBG);
                        end
                    end
                end
            end
            
            % sets the feasible phases (low and high variance only)
            fObj = obj.trkObj.fObj;
            okP = obj.iMov.vPhase < 3;       
            obj.iMov.Ibg = cell(length(fObj),1);
            obj.iMov.Ibg(okP) = cellfun(@(x)(x.IBG),fObj(okP),'un',0);            
            
            % ------------------------------- %
            % --- POSITION RE-CALCULATION --- %
            % ------------------------------- %              
            
            % recalculates the manually selected points over all frames
            for i = 1:length(iRowM)
                obj.recalcManualPos(iRowM{i});
            end
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % enables the manual tracking panel
            obj.setManualObjProps('off')
            
            % clears the table and disables the manual reselection panel
            set(obj.hGUI.tableFlyUpdate,'Data',[]);
            setPanelProps(obj.hGUI.panelManualSelect,0);
            
            % updates the main image
            obj.updateMainImage()
            
            % deselects the fly markers
            set(obj.hGUI.checkFlyMarkers,'value',1);
            obj.checkFlyMarkers(obj.hGUI.checkFlyMarkers,[])            
            
            % closes the loadbar
            delete(h);
            
        end

        % -------------------------------------- %
        % --- MANUAL RECALCULATION FUNCTIONS --- %
        % -------------------------------------- %   
        
        % --- recalculates the background/position from the manually 
        %     selected points
        function setupManualBGImages(obj,iRowM)
            
            % initialisations
            uListG = obj.uList(iRowM,:);            
            iFrm = sort(uListG(:,2));
            [iPh,iApp,iTube] = deal(uListG(1,1),uListG(1,3),uListG(1,4));
            
            % retrieves the local images
            iRT = obj.iMov.iRT{iApp}{iTube};
            iRL = obj.iMov.iR{iApp}(iRT);
            [iCL,fObj] = deal(obj.iMov.iC{iApp},obj.trkObj.fObj{iPh}); 
            
            % sets the local images
            if fObj.iPh == 1
                % case is for a low-variance phase
                IL = cellfun(@(x)(x(iRL,iCL)),fObj.Img(iFrm),'un',0);
            else
                % case is for a high-variance phase
                IL = cellfun(@(x)(x(iRL,iCL)),fObj.ImgMd(iFrm),'un',0);
            end
            
            % sets the marker x/y coordinates            
            hM = obj.hManual(iRowM);
            [xOfs,yOfs,szL] = deal(iCL(1)-1,iRL(1)-1,size(IL{1}));            
            xD = cell2mat(arrayfun(@(h)(get(h,'xData')-xOfs),hM,'un',0));
            yD = cell2mat(arrayfun(@(h)(get(h,'yData')-yOfs),hM,'un',0));
            
            % sets the 
            Bopt = deal(fObj.Bopt);
            [pOfs,szB] = deal((size(Bopt)-1)/2,size(Bopt));
            
            % removes the background image
            for i = 1:length(IL)
                % sets the row/column indices
                iRB = (yD(i)-pOfs(1)) + ((1:szB(1))'-1);
                iCB = (xD(i)-pOfs(2)) + ((1:szB(2))'-1);
                
                % determines the feasible row/column indices
                iiR = (iRB > 0) & (iRB <= szL(1));
                iiC = (iCB > 0) & (iCB <= szL(2));
                
                % removes the region containing the fly location      
                IL{i}(iRB(iiR),iCB(iiC)) = ...
                            ~Bopt(iiR,iiC).*IL{i}(iRB(iiR),iCB(iiC));  
                IL{i}(IL{i}==0) = NaN;
            end      
            
            % resets the background image using the new images
            if fObj.iPh == 1
                % case is for a low variance phase
                fObj.IBG{iApp}(iRT,:) = calcImageStackFcn(IL);
                obj.trkObj.fObj{iPh} = fObj;       
            else
                % case is for a high variance phase
                obj.iMov.IbgT{iApp}(iRT,:) = calcImageStackFcn(IL);
            end
            
        end        
        
        % --- recalculates the positions from the manually selected point
        function recalcManualPos(obj,iRowM)
           
            % initialisations
            pW = 0.75;
            uListG = obj.uList(iRowM,:);            
            iFrm = sort(uListG(:,2));
            [iPh,iApp,iTube] = deal(uListG(1,1),uListG(1,3),uListG(1,4));            
            
            % retrieves the local images
            iRT = obj.iMov.iRT{iApp}{iTube};
            iRL = obj.iMov.iR{iApp}(iRT);
            [iCL,fObj] = deal(obj.iMov.iC{iApp},obj.trkObj.fObj{iPh});                    
            
            % sets up the residual image stack based on the 
            if obj.iMov.vPhase(iPh) == 1
                IBG = fObj.IBG{iApp}(iRT,:);
                IL = cellfun(@(x)(x(iRL,iCL)),fObj.Img,'un',0);
            else
                IBG = obj.iMov.IbgT{iApp}(iRT,:);
                IL = cellfun(@(x)(x(iRL,iCL)),fObj.ImgMd,'un',0);
            end
            
            % sets the marker x/y coordinates     
            hM = obj.hManual(iRowM);
            [xOfs,yOfs,szL] = deal(iCL(1)-1,iRL(1)-1,size(IL{1}));
            xD = cell2mat(arrayfun(@(h)(get(h,'xData')-xOfs),hM,'un',0));
            yD = cell2mat(arrayfun(@(h)(get(h,'yData')-yOfs),hM,'un',0));            
            idxD = num2cell(sub2ind(szL,roundP(yD),roundP(xD)));
            
            % calculates the residual image stack and local maxima
            IRL = cellfun(@(x)(imfilter(IBG-x,fObj.hG)),IL,'un',0);                        
            Bmax = cellfun(@(x)(imregionalmax(x)),IRL,'un',0);
            
            % 
            pTolRL = pW*mean(cellfun(@(x,y)(x(y)),IRL(iFrm),idxD));
            BRLmax = cellfun(@(x,y)(x.*(y>pTolRL)),Bmax,IRL,'un',0);
            iGrpMx = cellfun(@(x)(find(x(:))),BRLmax,'un',0);
            
            % sets the final position vector
            for i = 1:length(IRL)
                % recalculates the positions for each 
                switch length(iGrpMx{i})
                    case 0
                        % case is there is no solution
                        iGrpF = argMax(IRL{i}(:));
                        
                    case 1
                        % case is there is a unique solution
                        iGrpF = iGrpMx{i};
                        
                    otherwise
                        % case is there are unique solutions
                        iGrpF = iGrpMx{i}(argMax(IRL{i}(iGrpMx{i})));
                end
                
                % updates the positions
                [yP,xP] = ind2sub(szL,iGrpF);
                obj.fPos{iPh}{iApp,i}(iTube,:) = [(xP+xOfs),(yP+yOfs)];
            end
            
        end
        
        % ------------------------------- %
        % --- MANUAL MARKER CALLBACKS --- %
        % ------------------------------- %
        
        % --- creates the manual markers for each sub-region
        function createManualMarkers(obj)
            
            % sets the hold on
            hold(obj.hAx,'on')
            
            % creates manual markers for each potential location over all
            % regions/sub-regions
            for i = 1:obj.nApp
                for j = 1:obj.nTube(i)
                    for k = 1:size(obj.pMn{j,i},1)
                        [uInd,pNw] = deal([i,j,k],obj.pMn{j,i}(k,:));
                        plot(obj.hAx,pNw(1),pNw(2),'y.','markersize',15,...
                                    'tag','hManual','UserData',uInd,...
                                    'Visible','off');
                    end
                end
            end
            
            % sets the hold off
            hold(obj.hAx,'off')            
            
        end
        
        % --- creates the manual markers for each sub-region
        function deleteManualMarkers(obj)
            
            % find any of the manual markers
            hManualPr = findall(obj.hAx,'tag','hManual');
            if ~isempty(hManualPr)
                % if any exists, then delete them
                delete(hManualPr)
            end
            
        end
        
        % --- updates the fly marker highlights
        function updateFlyHighlight(obj,iMap)
            
            % sets up the index array of the previously highlighted region
            iPr = [obj.iCloseR,obj.iCloseSR,obj.iCloseF];    
            
            % determines
            if iMap == 0
                % if there was a previously highlighted region, then
                % de-highlight this region
                if iPr(1) > 0             
                    hPr = findall(obj.hAx,'tag','hManual','visible','on');
                    setObjVisibility(hPr,0)
                end
                
                %
                obj.iCloseF = -1;
                
            else
                % retrieves the indices of the tube region
                iNw = [iPr(1:2),iMap];                
                if ~isequal(iNw,iPr)
                    % de-highlights the old region
                    hPr = findall(obj.hAx,'tag','hManual','visible','on');
                    setObjVisibility(hPr,0)
                    
                    % highlights the new region
                    hNw = findall(obj.hAx,'UserData',iNw,'tag','hManual');
                    setObjVisibility(hNw,1)
                    
                    % updates the highlighted index array
                    obj.iCloseF = iNw(3);                                          
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
            iPr = [obj.iCloseR,obj.iCloseSR,obj.iCloseF];            
            hMarkPr = findall(obj.hAx,'UserData',iPr,'tag','hManual');
            [xP,yP] = deal(get(hMarkPr,'xdata'),get(hMarkPr,'ydata')); 
            
            % creates the new marker
            hold(obj.hAx,'on')
            hPlt = scatter(obj.hAx,xP,yP,'k','tag','hManualAdd',...
                                'MarkerFaceColor','y','UserData',uListNw);            
            obj.hManual = [obj.hManual;hPlt];
            
            % turns off the axes hold            
            uistack(hPlt,'bottom');
            hold(obj.hAx,'off')
            
        end        
        
        % --- updates the marker properties
        function updateMarkerProps(obj)
            
            % parameters
            pStr = 'arrow';
           
            % retrieves the current axes handle            
            mP = roundP(get(obj.hAx,'CurrentPoint'));

            % determines if the mouse is over any sub-regions
            hTube = cell2cell(getappdata(obj.hFig,'hTube'));
            P = cellfun(@(x)([get(x,'xdata'),...
                              get(x,'ydata')]),hTube(:),'un',0);            
            
            % determines if the mouse is over a sub-region
            ii = cellfun(@(x)(inpolygon(mP(1,1),mP(1,2),x(:,1),x(:,2))),P);
            if any(ii)
                % if so, retrieve/update the sub-region information
                obj.updateTubeHighlight(hTube{ii});                          
                
                % determines if the mouse is over any potential markers
                iMap = obj.Imap(sub2ind(size(obj.Imap),mP(1,2),mP(1,1)));
                obj.updateFlyHighlight(iMap); 
                
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

        % --- equalises the image to the background image
        function IL = equaliseImg(obj,IL,iPhase)
            
            % initialisations
            pTolEq = 5;
            [iR,iC] = deal(obj.iMov.iR,obj.iMov.iC);
            
            % determines which images are outside of tolerance
            ILmn = cellfun(@(x)(nanmean(x(:))),IL(:));
            if isfield(obj.iMov,'ImnF')
                ImnF = obj.iMov.ImnF{iPhase};
            elseif isfield(obj.iMov,'Ibg')
                ImnF = cellfun(@(x)(nanmean(x(:))),obj.iMov.Ibg{iPhase}');
            else
                return
            end                        
            
            % equalises the histograms (if required)
            isOK = abs(ImnF - ILmn) < pTolEq;
            if any(~isOK)
                for i = find(~isOK(:)')
                    Iref = uint8(obj.ImgFrm{iPhase}(iR{i},iC{i}));
                    IL{i} = double(imhistmatch(uint8(IL{i}),Iref));
                end
            end
            
        end                

        % --- creates the general background image
        function createGenBGImage(obj,iSel)

            % memory allocation
            IbgNw = NaN(size(obj.ImgFrm{iSel}));

            % combines the background image over all regions
            for i = 1:length(obj.iMov.iR)
                IbgNw(obj.iMov.iR{i},obj.iMov.iC{i}) = ...
                    nanmax(IbgNw(obj.iMov.iR{i},obj.iMov.iC{i}),...
                           obj.iMov.Ibg{iSel}{i});
            end

            % sets the other remaining pixel values
            isN = isnan(IbgNw);
            IbgNw(isN) = obj.ImgFrm{iSel}(isN);
            
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
    
    end
    
    methods (Static)
    
        % --- function that initialises the parameter struct
        function iPara = initParaStruct(nFrm)

            % initialises the parameter struct
            iPara = struct('nFrm',nFrm,'nFrm0',nFrm,'cFrm',1,'cPhase',1);

        end        
    
    end
end
