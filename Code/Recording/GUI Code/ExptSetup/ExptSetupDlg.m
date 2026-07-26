classdef ExptSetupDlg < handle
    
    % class properties
    properties
        
        % main class object handles
        hFig
        hFigM
        hPanelO
        hZoom
        hProp0
        
        % tab group class fields
        hTabS
        hTabGrpS
        jTabGrpS
        
        % sub-class fields
        objM
        objT        
        objEx
        
        % external package sub-class fields
        objED
        objCS
        
        % data struct fields
        infoObj
        spixObj
        resInfo
        
        % mouse property class fields
        mType = 0;
        mpStrDef = 'arrow';
        
        % channel information fields
        nCh
        nCh0 = NaN;
        chID
        chName
        chInfo
        chCol
        
        % fixed class object dimensions
        dX = 10;
        hghtLbl = 20;
        hghtGrp = 20;
        hghtRow = 25;
        hghtBut = 25;
        hghtTxt = 16;
        hghtPopup = 22;
        hghtEdit = 22;
        hghtSlider = 10;
        hghtCheck = 20;
        hghtRadio = 20;
        hghtFig = 720;
        widFig = 1400;
        
        % calculated class object dimensions
        hghtPanelO
        widPanelO
        hghtTabGrp
        widTabGrp
        
        % class data struct fields
        iMov
        iProg
        iExpt
        
        % other important class fields
        hProg
        objDAQ
        objDAQ0
        devType
        devType0
        
        % stimuli train data struct
        sTrainP
        
        % numerical class fields
        nTab
        nDev
        axPosX
        axPosY
        iTab = 1;
        iBlkSel = 0;
        fSzL = 12;
        fSzH = 13;
        fSz = 10 + 2/3;
        
        % boolean class fields
        isInit = false;
        isHLOn = false;
        isStimOnly = false;
        isMouseDown = false;
        
        % function handle class fields
        zoomPropFcn        
        mouseMoveFcn
        isOverAxesFcn
        updateExptTabFcn
        calcExptStimDurFcn
        addCustomTabFcn
        
        % cell array fields
        dType = {'Info','S','L','Ex'};
        tabStr = {'Experiment Information',...
            'Short-Term Stimuli Protocol',...
            'Long-Term Stimuli Protocol',...
            'Experiment Stimuli Protocol'};
        
        % fixed string class fields
        tagStr = 'figExptSetupNew';
        figName = 'Experimental Recording Protocol Setup';
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = ExptSetupDlg(varargin)
            
            % initialises the class fields/objects
            obj.initClassFields(varargin);
            obj.initClassObjects();
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj,p)
            
            % function handle fields
            obj.mouseMoveFcn = @obj.normalMouseMove;
            obj.isOverAxesFcn = @obj.isOverAxes;
            obj.calcExptStimDurFcn = @obj.calcExptStimDuration;
            obj.zoomPropFcn = @obj.setAxesZoomProperties;
            obj.updateExptTabFcn = @obj.updateExptProtoTabProps;  
            obj.addCustomTabFcn = @obj.addCustomSignalTabs;
            
            % ----------------------------- %
            % --- CLASS FIELD RETRIEVAL --- %
            % ----------------------------- %
            
            % initialisations
            lStr = 'Initialising Experimental Setup Dialog';
            obj.hProg = ProgressLoadbar(lStr);
            
            % input arguments
            switch length(p)
                case 1
                    % case is running a video dependent expt
                    
                    % sets the input variables
                    obj.hFigM = p{1};
                    
                    % field retrieval
                    obj.iMov = getappdata(obj.hFigM,'iMov');
                    obj.iProg = getappdata(obj.hFigM,'iProg');
                    obj.infoObj = getappdata(obj.hFigM,'infoObj');
                    
                case 2
                    % case is running a stimuli only experiment
                    
                    % sets the input variables
                    [obj.infoObj,obj.hProg] = deal(p{1},p{2});
                    
                    % sets the data acquistion objects into the gui
                    [obj.objDAQ,obj.objDAQ0] = ...
                        reduceDevInfo(obj.infoObj.objDAQ);
                    
                    % loads required structs/data objects from main GUI
                    obj.hFigM = obj.infoObj.hFigM;
                    [obj.isStimOnly,obj.iMov] = deal(true,[]);
                    
                    % other field initialisations
                    objD = getappdata(obj.infoObj.hFigM,'mObj');
                    obj.iProg = objD.progDef.Recording;
            end
            
            % initialises the stimuli train parameter struct field
            obj.sTrainP = obj.initStimTrainPara();
            
            % tab count
            obj.nTab = 1 + 3*obj.infoObj.hasDAQ;            
            
            % makes the main gui invisible
            setObjVisibility(obj.hFigM,'off')            
            
            % ------------------------------ %
            % --- DATA CLASS FIELD SETUP --- %
            % ------------------------------ %
            
            % initialises the experiment information struct
            if isempty(obj.hFigM)
                % no parent figure has been provided
                obj.iExpt = initExptStruct(obj);
            else
                % otherwise, retreive expt info from the parent figure
                obj.iExpt = getappdata(obj.hFigM,'iExpt');
                if isempty(obj.iExpt)
                    % if no expt info, then re-initialise
                    obj.iExpt = initExptStruct(obj);
                end
            end
            
            % ------------------------------ %
            % --- DATA CLASS FIELD SETUP --- %
            % ------------------------------ %
            
            % retrieves the device channel information
            obj.getChannelInfo();
            obj.getChannelLabels();
            
            % sets up the video conversion data struct
            if ~obj.isStimOnly
                obj.setupConvInfoStruct();
            end                           
            
            % ------------------------------------------- %
            % --- CLASS OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------------- %
            
            % panel dimension calculations
            obj.hghtPanelO = obj.hghtFig - 2*obj.dX;
            obj.widPanelO = obj.widFig - 2*obj.dX;
            
            % tab group dimension calculations
            obj.hghtTabGrp = obj.hghtPanelO - obj.dX;
            obj.widTabGrp = obj.widPanelO - obj.dX;
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj,varargin)
            
            % removes any previous GUIs
            hFigPr = findall(0,'tag',obj.tagStr);
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % -------------------------- %
            % --- MAIN CLASS OBJECTS --- %
            % -------------------------- %
            
            % creates the figure object
            fPos = [100*[1,1],obj.widFig,obj.hghtFig];
            obj.hFig = figure('Position',fPos,'tag',obj.tagStr,...
                'MenuBar','None','Toolbar','None','Name',obj.figName,...
                'NumberTitle','off','Visible','off','Resize','off'); %,...
            %                 'CloseRequestFcn',[]);
            
            % sets the figure event functions
            set(obj.hFig,'WindowButtonDownFcn',@obj.figButtonDownFcn,...
                'WindowButtonUpFcn',@obj.figButtonUpFcn,...
                'WindowButtonMotionFcn',@obj.figButtonMotionFcn);
            
            % sets other experiment properties
            setappdata(obj.hFig,'obj',obj);
            setappdata(obj.hFig,'afterExptFunc',@obj.afterExptFunc);
            
            % creates the menu items
            obj.objM = ExptSetupMenu(obj);
            
            % runs the custom signal package (if available)
            if ~strcmp(obj.iExpt.Info.Type,'RecordOnly')
                obj.objCS = feval('runExternPackage','CustomSignalObj',obj);            
            end
            
            % -------------------------- %
            % --- MAIN CLASS OBJECTS --- %
            % -------------------------- %
            
            % creates the experiment combining data panel
            pPosO = [obj.dX*[1,1],obj.widPanelO,obj.hghtPanelO];
            obj.hPanelO = createUIObj('panel',...
                obj.hFig,'Title','','Units','Pixels','Position',pPosO);
            
            % ----------------------- %
            % --- TAB GROUP SETUP --- %
            % ----------------------- %
            
            % creates a tab panel group
            pPosTG = [(obj.dX/2)*[1,1],obj.widTabGrp,obj.hghtTabGrp];
            obj.hTabGrpS = createTabPanelGroup(obj.hPanelO,1);
            set(obj.hTabGrpS,'position',pPosTG,'tag','hTabGrpS');
            
            % creates the tab objects
            for i = 1:obj.nTab
                obj.createNewDialogTab(i);
            end
            
            % enables the protocol menu items (recording only)
            if obj.nTab == 1
                obj.objM.setMenuItemEnable('menuNewProto','on');
                obj.objM.setMenuItemEnable('menuOpenProto','on');
                obj.objM.setMenuItemEnable('toolNewProto','on');
                obj.objM.setMenuItemEnable('toolOpenProto','on');
                
                % sets the window fields with the protocol data
                obj.resizeClassObjects(false);
            end
            
            % ------------------------------------------ %
            % --- OTHER FIELD RETREIVAL/OBJECT SETUP --- %
            % ------------------------------------------ %
            
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % runs all external packages
            feval('runExternPackage','RunStreamPix',obj);
            
        end
        
        % --- adds new tabs to the dialog window
        function createNewDialogTab(obj,iT)
            
            obj.hTabS{end+1} = createNewTab(...
                obj.hTabGrpS,'Title',obj.tabStr{iT},'UserData',iT);
            set(obj.hTabS{iT},'ButtonDownFcn',@obj.tabSelected);
            
            % sets up the tab objects
            switch iT
                case 1
                    % case is the information tab
                    obj.objT{end+1} = ExptTabInfo(obj,obj.hTabS{iT});
                case {2,3}
                    % case is the short/long-term stimuli tab
                    obj.objT{end+1} = ExptTabStim(obj,obj.hTabS{iT},iT);
                    
                    % creates the zoom object
                    if iT == 2
                        obj.initZoomObject()
                    end
                case 4
                    % case is the experiment protocol tab
                    obj.objT{end+1} = ExptTabProto(obj,obj.hTabS{iT});
            end
            
        end        
        
        % --- adds the custom signal tabs
        function addCustomSignalTabs(obj,sObj)
            
            % adds the short/long-term stimuli custom tabs
            for i = 2:3
                % determines if there is a duplicate custom signal tab
                if isprop(obj.objT{i}.objP,sObj.sName)
                    % if so, then output an error to screen
                    tStr = 'Duplicate Signal Tabs';
                    eStr = sprintf(['The custom signal type "%s" has ',...
                                    'already been loaded.'],sObj.sName);
                    waitfor(msgbox(eStr,tStr,'modal'))
                    
                    % exits the loop
                    break
                    
                else
                    % otherwise, create the signal tab
                    obj.objT{i}.addCustomSignalTab(sObj);
                end                                
            end
            
        end
        
        % ------------------------------ %
        % --- FIGURE EVENT FUNCTIONS --- %
        % ------------------------------ %
        
        % --- mouse motion event figure callback function
        function figButtonMotionFcn(obj,varargin)
            
            % if the tab isn't initialised, then exit
            objTT = obj.objT{obj.iTab};
            if ~objTT.isInit
                return
            end
            
            % performs the action based on the currently selected tab
            if obj.iTab == 1
                % case is information tab is selected
                
                % resets the mouse cursor
                obj.mpStrDef = 'arrow';
                
            else
                % case is the other tabs are selected
                
                % resets the current axes to that of the selected tab
                obj.currentTabAxesCheck();
                
                % determines if the mouse is over the plot axes
                mPos = get(obj.hFig,'CurrentPoint');
                if obj.isOverAxes(mPos)
                    % determines the object being hovered over
                    hHover = findAxesHoverObjects(obj.hFig);
                    if any(obj.mType == [4,5])
                        % case is expt protocol stimuli objects
                        objTT.exptTabMouseMove(hHover)
                        
                    elseif ~isempty(hHover)
                        % case is an object is being hovered over
                        if any(obj.mType == [2,3])
                            % case is stimuli protocol stimuli objects
                            objTT.exptTabMouseMove(hHover)
                            
                        else
                            % case is normal mouse movement
                            obj.normalMouseMove(hHover)
                        end
                        
                    else
                        % case is there are not objects being hovered over
                        obj.mpStrDef = 'arrow';
                        if ~any(obj.mType == [3,5])
                            objTT.removeChannelHighlight(true)
                        end
                    end
                else
                    % case is the mouse is not over the plot axes
                    obj.mpStrDef = 'arrow';
                    if ~any(obj.mType == [3,5])
                        objTT.removeChannelHighlight(true)
                    end
                end
            end
            
            % updates the mouse cursor object
            obj.updateMouseCursor();
            
        end
        
        % --- mouse button down event figure callback function
        function figButtonDownFcn(obj,~,~,selType)
            
            % default input arguments
            if obj.iTab == 1
                % exit if the information tab
                return
            elseif ~exist('selType','var')
                % otherwise, retrieve the mouse selection type
                selType = get(obj.hFig,'SelectionType');
            end
            
            % field retrieval
            objTT = obj.objT{obj.iTab};
            objTSM = objTT.objSM;
            
            %
            switch selType
                case 'alt'
                    % case is mouse right-click
                    
                    % resets the mouse pointer selection type
                    iSigS = objTT.objSM.iSigS;
                    if obj.mType > 0
                        objTT.removeChannelHighlight(true);
                        objTSM.setFillVisibility('on')
                        obj.mType = 0;
                    end
                    
                    % disables any selected objects
                    if ~any(isnan(iSigS))
                        objTT.objSM.setSelectedObjProps('off');
                    end
                    
                case 'normal'
                    % case is mouse left-click
                    
                    % updates the mouse-down flag                    
                    obj.isMouseDown = true;
                    
                    % determines if the mouse is over the plot axes
                    mPos = get(obj.hFig,'CurrentPoint');
                    if ~obj.isOverAxes(mPos)
                        return
                    end
                    
                    %
                    switch obj.mType
                        case 0
                            % if a stimuli object is being hovered over,
                            % then update the selection properties
                            if objTSM.iSigH > 0
                                % removes the channel highlight
                                if obj.iTab < 4
                                    objTSM.setFillVisibility('off')
                                end
                                
                                % removes any currently selected objects
                                if ~any(isnan(objTSM.iSigS))
                                    objTSM.setSelectedObjProps('off',1)
                                end
                                
                                % sets selected signal block properties
                                objTSM.setSelectedObjProps('on');
                            end
                            
                        case 2
                            % case is stimuli train is being placed
                            
                            % resets mouse status flag
                            obj.mType = 0;
                            
                            % creates the stimuli train object
                            objTT.createTrainObject()
                            
                        case 4 
                            % case is an experiment block is being placed
                            
                            % resets the mouse hover type flag
                            obj.mType = 0;
                            
                            % creates the signal object
                            objTT.createBlockObject()
                            
                        case {3,5}
                            % case is stimuli train object is being moved
                            if ~objTSM.selectStimObject()
                                objTSM.setSelectedObjProps('off')
                                return
                            end
                    end
            end
            
            % runs the button motion function
            obj.figButtonMotionFcn();
            
        end
        
        % --- mouse button up event figure callback function
        function figButtonUpFcn(obj,varargin)
            
            % exit if not a stimuli protocol tab
            if obj.iTab == 1
                return
            end
            
            % updates the mouse down flag
            obj.isMouseDown = false;
            
            %
            objTSM = obj.objT{obj.iTab}.objSM;            
            switch obj.mType
                case 3
                    % case is a stimuli train is selected
                    
                    % hides the distance lines and reset the time limits
                    objTSM.setDistLineVisibility('off');
                    objTSM.resetStimObjTimeLimits();
                    objTSM.iSigH = -1;
                    
                case 5
                    % case is a stimuli block is selected                    

                    % hides the distance lines and reset the time limits
                    objTSM.setDistLineVisibility('off');
                    objTSM.resetBlockObjLimits();                  
            end
            
        end
        
        % --- normal mouse movement callback function
        function normalMouseMove(obj,hHover)
            
            % field retrieval
            objTT = obj.objT{obj.iTab};            
            
            %
            if obj.iTab == 4
                % determines if a channel object is being hovered over
                isChB = arrayfun(@(x)(...
                    strcmp(get(x,'tag'),'hSigBlk')),hHover);
                if any(isChB)
                    [obj.mpStrDef,obj.isHLOn] = deal('hand',true);
                
                    % sets the signal block object
                    hHoverChB = hHover(isChB);
                    if length(hHoverChB) > 1
                        % determines the signal block which matches the
                        % hover signal block index
                        objExSM = obj.objT{4}.objSM;
                        idBlk = cell2mat(get(hHoverChB,'UserData'));
                        
                        % determines the matching signal block
                        if ~isnan(objExSM.iSigS)
                            ii = objExSM.idBlkList(...
                                objExSM.iSigS) == idBlk;
                        else
                            ii = objExSM.idBlkList(...
                                objExSM.iSigH) == idBlk;
                        end

                        % keeps the relevant block object handle
                        hHoverChB = hHoverChB(ii);      
                    end
                    
                    % turns on the channel highlight
                    objTT.resetChannelHighlight(hHoverChB);
                
                    % if adding new block, then determine feasibility
                    if obj.mType == 1
                        objTT.stimObjCheck();
                    end                
                   
                    % exits the function
                    return
                end
                
            else
                % determines if a channel object is being hovered over
                isChP = arrayfun(@(x)(...
                    strcmp(get(x,'tag'),'chFill')),hHover);
                
                if any(isChP)
                    % if so, then flag that the object is being highlighted
                    [obj.mpStrDef,obj.isHLOn] = deal('hand',true);

                    % turns on the channel highlight
                    objTT.resetChannelHighlight(hHover(isChP));

                    % if adding new train, then determine feasibility
                    if obj.mType == 1
                        objTT.stimObjCheck();
                    end                    
                    
                    % reset the current stimuli block highlight (??)
                    objTT.objSM.checkStimTrainHighlight(hHover);                    
                    
                    % exits the function
                    return
                end
            end

            % otherwise, turn the channel highlight
            objTT.removeChannelHighlight(false);
            
        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- callback function for selecting the file type tab
        function tabSelected(obj, ~, ~)
            
            % removes any stimuli object selections
            if obj.iTab > 1
                obj.figButtonDownFcn([],[],'alt')
                obj.objT{obj.iTab}.objSM.resetObjectIndices();
            end
            
            % updates the selected tab
            obj.mType = 0;
            obj.iTab = obj.hTabGrpS.SelectedTab.UserData;
            set(obj.hFig,'Pointer','arrow');
            
            % sets zoom toolbar item (only enable if not info tab)
            obj.objM.setMenuItemEnable('toolZoom',obj.iTab > 1);
            
            % resets the current axes handle
            if obj.iTab == 1
                % case is the information tab (no axes)
                set(obj.hFig,'CurrentAxes',[])
            else
                % case is the stimuli/experiment protocols
                set(obj.hFig,'CurrentAxes',obj.objT{obj.iTab}.hAx)
                obj.resetZoomAxes();                
            end
            
            % custom signal menu item property update 
            if ~isempty(obj.objCS)
                if any(obj.iTab == [2,3])
                    % if short/long-term stimuli, check selected para tab
                    hTabSel = obj.objT{obj.iTab}.objP.hTabGrp.SelectedTab;
                    setObjEnable(obj.objCS.hMenuA,hTabSel.UserData);
                else
                    % otherwise, disable menu item
                    setObjEnable(obj.objCS.hMenuA,0);                    
                end            
            end
            
        end
                
        % ------------------------------------ %
        % --- CLASS FIELD GETTER FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- retrieves the device channel information
        function getChannelInfo(obj)
            
            % sets the device information (dependent on expt/devices)
            switch obj.infoObj.exType
                case 'RecordOnly'
                    % case is a recording only experiment
                    
                    % sets the device type to record only
                    [obj.devType,obj.nCh0] = deal({'RecordOnly'},NaN);
                    
                case {'RecordStim','StimOnly'}
                    % case is a stimuli dependent experiment
                    
                    % field retrieval
                    obj.nCh0 = obj.infoObj.objDAQ.nChannel;
                    obj.devType = ...
                        obj.resetDevType(obj.infoObj.objDAQ.sType);
                    
                    % resets the fields for test cases
                    if obj.infoObj.isTest
                        isOK = find(obj.nCh0 > 0);
                        [obj.nCh0,obj.devType] = ...
                            deal(obj.nCh0(isOK),obj.devType(isOK));
                    end
                    
                    % sets up the external device class object
                    obj.objED = feval('runExternPackage','ExtnDevices');
                    
                    % sets the device channel counts
                    xiCh = 1:length(obj.nCh0);
                    obj.infoObj.iStim.nChannel(xiCh) = obj.nCh0;
                    
                    % updates the opto menu gui properties
                    if ~obj.infoObj.isTest
                        setRecordGUIProps(obj,'InitOptoMenuItems')
                    end
            end
            
            % sets the original device type
            obj.nDev = length(obj.devType);
            obj.devType0 = obj.devType;
            
        end
        
        % --- retrieves the stimuli channel labels
        function getChannelLabels(obj)
            
            % memory allocation
            obj.nCh = obj.nCh0;
            obj.chName = cell(1,obj.nDev);
            
            % sets the axis labels (based on device type)
            for i = 1:obj.nDev
                switch obj.devType{i}
                    case 'HTControllerV3'
                        % case is the HTControllerV3
                        obj.chName{i} = [{'Motors'},...
                            obj.getOptoChannelNames()];
                        [obj.nCh(i),obj.nCh0(i)] = ...
                            deal(length(obj.chName{i}));
                        
                    case 'Opto'
                        % case is the optogenetic device
                        obj.chName{i} = obj.getOptoChannelNames();
                        [obj.nCh(i),obj.nCh0(i)] = ...
                            deal(length(obj.chName{i}));
                        
                    case 'Motor'
                        % case is a motor device
                        obj.chName{i} = getMotorChannelNames(obj.nCh(i),1);
                        
                    case 'RecordOnly'
                        % case is recording only
                        obj.chName{i} = [];
                        
                end
            end
            
            % initialises the stimuli channel information array
            if strcmp(obj.devType{1},'RecordOnly')
                % case is a recording only experiment
                obj.chInfo = [];
                
            else
                % case is a stimuli-dependent experiment
                [devTypeT,isFound] = deal(obj.devType,false(obj.nDev,1));
                for i = 1:obj.nDev
                    if ~isFound(i)
                        % determines if multiple devices of the same type
                        ii = strcmp(obj.devType,devTypeT{i});
                        if sum(ii) > 1
                            % if so, replace with numbered names
                            xiD = 1:sum(ii);
                            devTypeT(ii) = arrayfun(@(x)(sprintf(...
                                '%s %i',obj.devType{i},x)),xiD,'un',0);
                        end
                        
                        % flag that all device of this type are found
                        isFound(ii) = true;
                    end
                end
                
                % sets the device channel information array
                obj.chID = cellfun(@(i,x)(i*ones(length(x),1)),...
                    num2cell(1:obj.nDev),obj.chName,'un',0);
                obj.chInfo = cell2cell(cellfun(@(i,x)([num2cell(i),x(:),...
                    devTypeT(i)]),obj.chID,obj.chName,'un',0));
                
                % retrieves the channel colours
                obj.chCol = getChannelCol(...
                    obj.devType,obj.nCh(1:length(obj.devType)));
            end
            
        end
        
        % --- retrieves the current recording device resolution
        function vRes = getRecordingResolution(obj)
            
%             if obj.infoObj.isTest
%                 % case is testing
%                 vRes = flip(obj.infoObj.objIMAQ.szImg);
                
            if obj.infoObj.isWebCam
                % case is using webcam device
                vRes = obj.infoObj.objIMAQ.pROI(3:4);
                
            elseif isVidDev(obj.infoObj.objIMAQ)
                % case is using a video device
                vRes = obj.infoObj.objIMAQ.ROI(3:4);
                
            else
                % case is using a videoinput device
                vRes = obj.infoObj.objIMAQ.VideoResolution;
            end
            
        end
        
        % --- retrieves the tab class object
        function objTT = getTabClassObject(obj,iTabTT)
            
            objTT = obj.objT{iTabTT};
            
        end
        
        % --- calculate the total stimuli train count
        function nTrainTot = getTotalTrainCount(obj)
            
            %
            nTrainTot = sum(cellfun(@(x)(length(x.sTrain)),obj.objT(2:3)));
            
        end
        
        % ------------------------------------ %
        % --- CLASS FIELD SETTER FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- sets the axes zoom properties
        function setAxesZoomProperties(obj,zState,varargin)
            
            % field retrieval
            isOff = strcmp(zState,'off');
            hAxTT = obj.objT{obj.iTab}.objAx.hAx;
            
            % sets the enabled properties of the protocol tabs
            xiT = 1:obj.nTab;
            arrayfun(@(x)(obj.jTabGrpS.setEnabledAt(x-1,isOff)),xiT);
            
            if strcmp(zState,'off')
                % updates the state of the zoom object
                obj.setZoomState(zState);
                disableDefaultInteractivity(hAxTT)
                
                % resets the panel properties
                resetHandleSnapshot(obj.hProp0);
                
                % resets the mouse motion callback function
                obj.hFig.WindowButtonMotionFcn = @obj.figButtonMotionFcn;
                obj.hFig.WindowButtonDownFcn = @obj.figButtonDownFcn;
                obj.hFig.WindowButtonUpFcn = @obj.figButtonUpFcn;
                
            else
                %
                obj.figButtonDownFcn([],[],'alt');
                obj.mType = 0;
                
                % retrieves the current tab object property snapshot
                hPanelTT = obj.objT{obj.iTab}.hPanel;
                obj.hProp0 = getHandleSnapshot(hPanelTT,1);
                
                % disables all valid objects
                hObj = field2cell(obj.hProp0,'hObj',1);
                hasE = arrayfun(@(x)(isprop(x,'Enable')),hObj);
                arrayfun(@(x)(set(x,'Enable','off')),hObj(hasE))
                
                % removes the motion callback function
                obj.hFig.WindowButtonMotionFcn = [];
                obj.hFig.WindowButtonDownFcn = [];
                obj.hFig.WindowButtonUpFcn = [];
                
                % updates the state of the zoom object
                obj.setZoomState(zState);
                enableDefaultInteractivity(hAxTT);
            end
            
        end
        
        % --- updates the experiment info panel feasibility flags
        function setFeasFlag(obj,fType,fFlag)
            
            % default input arguments
            if ~exist('chkFeas','var')
                chkFeas = true;
            end
            
            % runs the function
            obj.objT{1}.setFeasFlag(fType,fFlag,chkFeas);
            
        end
        
        % ----------------------------- %
        % --- ZOOM OBJECT FUNCTIONS --- %
        % ----------------------------- %
        
        % --- initialises the zoom object
        function initZoomObject(obj)
            
            % creates the zoom object
            obj.hZoom = zoom(obj.hFig);
            set(obj.hZoom,'Enable','off',...
                'ActionPostCallback',@obj.postZoomFunc);
            
        end
        
        % --- sets the zoom state flag
        function setZoomState(obj,zState)
            
            % sets zoom object enabled state
            obj.hZoom.Enable = char(zState);
            
            % zoom out if disabling
            if strcmp(zState,'off')
                zoom(obj.hFig,'out');
            end
            
        end
        
        % deletes the zoom object
        function resetZoomObject(obj,zState)
            
            % deletes the existing zoom object
            delete(obj.hZoom);
            
            % creates a new zoom object
            obj.initZoomObject();
            obj.setZoomState(zState);
            
        end
        
        % --- resets the zoom to the current tab plot axes
        function resetZoomAxes(obj)
            
            % wait until the axes object has been created
            while isempty(obj.objT{obj.iTab}.objAx)
                pause(0.05);
            end
            
            % field retrieval
            hAxTT = obj.objT{obj.iTab}.objAx.hAx;
            
            % sets the axis zoom constraint to the x-direction only
            setAxesZoomConstraint(obj.hZoom,hAxTT,'x');
            %             setAllowAxesZoom(obj.hZoom,hAxTT,true);
            
        end
        
        % --- post zoom update function
        function postZoomFunc(obj,varargin)
            
            a = 1;
            
        end
        
        % ------------------------------------ %
        % --- OBJECT/FIELD RESET FUNCTIONS --- %
        % ------------------------------------ %        
        
        % --- loads the experimental protocol, pInfo
        function resetClassObjects(obj,sTrainT)
            
            % initialisations
            hasStim = ~strcmp(obj.iExpt.Info.Type,'RecordOnly');
            obj.nTab = 1 + 3*hasStim;
            
            % resets the stimuli train parameter struct
            if isempty(sTrainT)
                sTrainT = obj.initStimTrainPara();
            end
            
            % resizes the class objects
            obj.resizeClassObjects(hasStim)            
            
            % ensures the information tab is showing
            obj.hTabGrpS.SelectedTab = obj.hTabS{1};
            obj.tabSelected();
            pause(0.05);      
            
            % experiment type specific updates
            if hasStim
                if length(obj.hTabS) == 1
                    % creates the tab objects are missing
                    
                    % creates the tab objects
                    for i = 2:obj.nTab
                        obj.createNewDialogTab(i);
                    end
                else
                    % re-adds the stimuli tabs to the tabgroup
                    xiT = 2:obj.nTab;
                    cellfun(@(x,t)(...
                        set(x,'Title',t)),obj.hTabS(xiT),obj.tabStr(xiT));
                end
                
                % sets the device information and popup-values
                obj.resetDurPopupValues();
                
                % resets the global channel colours
                obj.chCol = getChannelCol(...
                    obj.devType,obj.nCh(1:length(obj.devType)));                
                
            else
                % case is there are no external devices
                [obj.chInfo,obj.chID,obj.chName] = deal([]);
                
                % removes the stimuli tabs from the tabgroup
                if length(obj.hTabGrpS.Children) == 4
                    xiT = 2:length(obj.hTabS);
                    arrayfun(@(x)(obj.jTabGrpS.setEnabledAt(x-1,0)),xiT);
                    cellfun(@(x)(set(x,'Title','')),obj.hTabS(xiT));
                end
            end
            
            % other object property updates
            obj.objM.setMenuItemEnable('toolZoom',hasStim);
            
            % resets the custom signal tabs (if required & has stimuli)
            if ~isempty(obj.objCS) && hasStim && ~isempty(sTrainT.Ex)
                % determines the stimuli signal types (for the expt)
                blkInfo = cellfun(@(x)(...
                    x.sTrain.blkInfo),sTrainT.Ex,'un',0);
                sTypeEx = unique(cell2cell(cellfun(@(x)(unique(...
                    arrayfun(@(y)(y.sType),x,'un',0))),blkInfo,'un',0)));
                
                % 
                for i = 2:3
                    obj.objT{i}.objP.resetCustomTabs(sTypeEx,sTrainT.Ex);
                end
            end            
            
            % resets the tab object properties
            for i = 1:(1+3*hasStim)
                if i == 1
                    % case is the information tab
                    obj.objT{i}.initObjectProps();
                else
                    % case is the stimuli/experimental protool tabs
                    obj.objT{i}.resetObjectPropsTimer(sTrainT);
                end
            end            
            
            % pause to update
            pause(0.05);
            
            % updates the opto menu gui properties
            if ~obj.infoObj.isTest
                setRecordGUIProps(obj,'InitOptoMenuItems')
            end
            
        end
        
        % --- resets the device information fields
        function resetDeviceInfo(obj,fData)
            
            % determines the device channel index groupings
            [~,~,iC] = unique(cell2mat(obj.chInfo(:,1)));
            indC = arrayfun(@(x)(find(iC==x)),1:max(iC),'un',0);
            
            % field reset
            obj.nDev = length(indC);
            obj.chName = cellfun(@(x)(fData.chInfo(x,2)),indC,'un',0);
            obj.chID = cellfun(@(i,x)(i*ones(length(x),1)),...
                num2cell(1:obj.nDev),obj.chName,'un',0);
            
        end
        
        % --- re-initialises all the tabs
        function resetAllTabs(obj)
            
            % updates the experimental protocol tabs
            if obj.nTab == 4
                obj.updateExptProtoTabProps();
            end
            
        end        
        
        % --- resets the duration popup fields
        function resetDurPopupValues(obj)
            
            
            
        end

        % -------------------------------- %
        % --- EXPERIMENT RUN FUNCTIONS --- %
        % -------------------------------- %
        
        % --- experiment run start function
        function startExptRun(obj)
                        
            % stops the experiment start timer
            stop(obj.objT{1}.hTimerS)

            % ----------------------------------------- %
            % --- PRE-EXPERIMENT FEASIBILITY CHECKS --- %
            % ----------------------------------------- %
            
            % runs the pre-experiment IMAQ check
            if ~obj.preExptCheckIMAQ()
                % if it failed, then restart the timer and exit
                start(obj.objT{1}.hTimerS)
                return
            end
            
            % runs the pre-experiment DAQ check
            if ~obj.preExptCheckDAQ()
                % if it failed, then restart the timer and exit
                start(obj.objT{1}.hTimerS)
                return
            end
            
            % -------------------------------------- %
            % --- EXPERIMENT RUN INITIALISATIONS --- %
            % -------------------------------------- %
            
            % sets the recording GUI properties
            obj.setPreExptObjectProps();       
            
            % initialises and runs the experiment object
            obj.objEx = RunExptObj(obj.hFigM,'Expt',obj,false,false);
            obj.objEx.startExptObj();
            
        end
        
        % --- after experiment run function
        function afterExptRun(obj)
            
            % turns off the camera (if still running)
            if obj.infoObj.hasIMAQ
                if isDeviceRunning(obj.objEx)
                    stopRecordingDevice(obj.objEx)
                end
                
                % converts the videos (if required)
                obj.objEx.convertExptVideos();   
                
                % stops the video device
                if isVidDev(obj.infoObj.objIMAQ)
                    release(obj.infoObj.objIMAQ);
                end
            end
            
            % sets the recording GUI properties
            obj.setPostExptObjectProps();            
            
            % clears the experiment object field
            obj.objEx = [];
            
            % restarts the timer object
            start(obj.objT{1}.hTimerS);            
            
        end
        
        % --- sets the pre-experiment run object properties
        function setPreExptObjectProps(obj)
            
            % sets the Recording GUI object properties (if recording)
            if obj.infoObj.hasIMAQ
                % object handle retrieval
                hMainH = guidata(obj.hFigM);
                
                % stop the video preview (if currently running)
                if get(hMainH.toggleVideoPreview,'Value')
                    toggleFcn = getappdata(obj.hFigM,'toggleVideoPreview');
                    set(hMainH.toggleVideoPreview,'Value',0)
                    toggleFcn(hMainH.toggleVideoPreview,'1',hMainH)
                end
                
                % disables the other Recording GUI objects
                setObjEnable(hMainH.toggleVideoPreview,'off')
                setObjEnable(hMainH.menuAdaptors,'off')
                setObjEnable(hMainH.menuCalibrate,'off')
            end   
            
            % makes the experimental info GUI invisible
            setObjVisibility(obj.hFig,'off')
            if obj.infoObj.hasIMAQ
                % displays the Recording GUI
                centerfig(obj.hFigM);
                setObjVisibility(obj.hFigM,1);
            end
            
        end
        
        % --- sets the post-experiment run object properties
        function setPostExptObjectProps(obj)
        
            % makes the main GUI invisible
            setObjVisibility(obj.objEx.hMain,'off');
            pause(0.01);
            
            % turns off the camera (if still running)
            if obj.infoObj.hasIMAQ                
                hMainH = guidata(obj.hFigM);
                setObjEnable(hMainH.toggleVideoPreview,'on')
                setObjEnable(hMainH.menuAdaptors,'on')
                setObjEnable(hMainH.menuCalibrate,'on')                
            end
            
            % updates the experiment title string
            obj.objT{1}.editExptTitle()
            setObjVisibility(obj.hFig,'on');            
                        
        end
        
        % --- runs the pre-experiment IMAQ feasibility check
        function ok = preExptCheckIMAQ(obj)
            
            % initialisations
            ok = true;
            
            % exit if there is no attached IMAQ device
            if ~obj.infoObj.hasIMAQ
                return
            end
            
            % determines if the video resolution is feasible
            if ~checkVideoResolution(obj.infoObj.objIMAQ,obj.iExpt.Video)
                ok = false;
                return
            end
            
            % determines if there is sufficient storage space
            mStr = obj.objT{1}.calcVidTiming();
            if ~isempty(mStr)
                % if not, then prompt the user if they wish to continue
                tStr = 'Low Space Warning!';
                mStr = sprintf(['%sDo you still wish to continue ',...
                                'with the experiment?'],mStr);
                uChoice = questdlg(mStr,tStr,'Yes','No','Yes');
                if ~strcmp(uChoice,'Yes')
                    % if not, then exit the experiment
                    ok = false;
                end
            end
        end                
        
        % --- runs the pre-experiment DAQ feasibility check
        function ok = preExptCheckDAQ(obj)
        
            % initialisations
            ok = true;
            
            % exit if there is no attached DAQ device
            if ~obj.infoObj.hasDAQ
                return
            end           
            
            % determines if the stimuli protocol has been set up
            if isempty(obj.sTrainP.Ex)
                % if not, then prompt the user if they want to continue
                tStr = 'Stimuli Protocol Missing?';
                qStr = sprintf(['A stimuli protocol has not been set ',...
                    'for this experiment, despite external devices ',...
                    'being detected.\n\nAre you sure you want to ',...
                    'continue?']);
                uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                if strcmp(uChoice,'Yes')
                    % if so, reset the experiment type flag to record only
                    obj.iExpt.Info.Type = 'RecordOnly';   
                    
                else
                    % otherwise, exit the function
                    ok = false;
                    return
                end
            else
                % otherwise, set experiment type to recording + stimuli
                obj.iExpt.Info.Type = 'RecordStim';
            end

            % updates the alter parameter menu item (if package available)
            if ~isempty(obj.spixObj)
                obj.spixObj.setVideoTime(vec2sec(obj.iExpt.Timing.Texp))
            end                
                
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- resizes the class objects
        function resizeClassObjects(obj,hasStim)
            
            if ~exist('hasStim','var')
                hasStim = ~strcmp(obj.iExpt.Info.Type,'RecordOnly');
            end
            
            if hasStim
                % main class object resizing
                obj.hTabGrpS.Position(3) = obj.widTabGrp;
                obj.hPanelO.Position(3) = obj.widPanelO;
                obj.hFig.Position(3) = obj.widFig;
                
                % resets the information panel position
                obj.objT{1}.hPanelO.Position(3) = obj.objT{1}.widPanelO;
                
            else
                % case is recording only experiment
                
                % information tab object resizing
                pPos = obj.objT{1}.hPanelE.Position;
                obj.objT{1}.hPanelO.Position(3) = pPos(3) + obj.dX;
                
                % main class object resizing
                obj.hTabGrpS.Position(3) = pPos(3) + 2*obj.dX;
                obj.hPanelO.Position(3) = pPos(3) + 3*obj.dX;
                obj.hFig.Position(3) = pPos(3) + 5*obj.dX;
            end
            
            % re-centres the figure
            centerfig(obj.hFig);
            
        end
        
        % --- updates the experimental protocol tab properties
        function updateExptProtoTabProps(obj,sTrain)
            
            % default input arguments
            if ~exist('sTrainT','var')
                sTrain = obj.sTrainP;
            end
            
            % retrieves the tab group java handle
            if isempty(obj.jTabGrpS)
                obj.jTabGrpS = getTabGroupJavaObj(obj.hTabGrpS);
            end
            
            % wait until all tabs have been readded
            while obj.jTabGrpS.getTabCount < 4
                pause(0.01);
            end
            
            % only enable if at least one short/long-term protocol is set
            hasExS = ~(isempty(sTrain.S) && isempty(sTrain.L));
            obj.jTabGrpS.setEnabledAt(3,hasExS);
            
        end
        
        % --- calculates the duration of the experiment stimuli train
        function [tDurEx,tDurExU,tBlkOfs,tBlkDur] = ...
                calcExptStimDuration(obj,sTrainS,sPara)
            
            % initialisations
            tDur = obj.iExpt.Timing.Texp;
            sParaBlk = field2cell(sTrainS.blkInfo,'sPara');
            
            % retrieves the experiment duration units
            if isfield(sPara,'tOfs')
                sParaS = sPara;
                [~,tDurExU] = vec2time(tDur);
                
            else
                sType = getappdata(hObj,'sType');
                sParaS = getExptParaInfo(sPara,sType);
                [~,tDurExU] = vec2time(obj.iExpt.Timing.Texp);
            end
            
            % calculates the inter-stimuli interval (in terms of the expt
            % time units)
            tMltStim = getTimeMultiplier(tDurExU,'s');
            tStimInt = vec2sec(sParaS.tStim)*tMltStim;
            
            % calculates the time multiplers for each of stimuli blocks
            tDurU = cellfun(@(x)(x.tDurU),sParaBlk,'un',0);
            tMltDur = cellfun(@(x)(getTimeMultiplier(tDurExU,x)),tDurU);
            tBlkDur = cellfun(@(x)(x.tDur),sParaBlk).*tMltDur;
            
            % calculates the time multiplers for each of stimuli blocks
            tOfsU = cellfun(@(x)(x.tOfsU),sParaBlk,'un',0);
            tMltOfs = cellfun(@(x)(getTimeMultiplier(tDurExU,x)),tOfsU);
            tBlkOfs =  cellfun(@(x)(x.tOfs),sParaBlk).*tMltOfs;
            
            % calculates maximum duration for the stimuli trains across
            % all channels
            tDurEx = max(tBlkOfs+tBlkDur);
            
            % calculates the full stimuli train
            tDurEx = (sParaS.nCount-1)*tStimInt + tDurEx;
            
        end
        
        % --- determines if the mouse is over the plot axes
        function isOver = isOverAxes(obj,mPos)
            
            isOver = prod(sign(obj.axPosX - mPos(1))) == -1 && ...
                prod(sign(obj.axPosY - mPos(2))) == -1;
            
        end
        
        % --- updates the mouse cursor based on type
        function updateMouseCursor(obj)
            
            % sets the mouse pointer dependent on type
            if isnumeric(obj.mpStrDef)
                % case is a custom pointer
                set(obj.hFig,...
                    'PointerShapeCData',obj.mpStrDef,'Pointer','custom')
            else
                % case is a pointer string
                set(obj.hFig,'Pointer',obj.mpStrDef);
            end
            
        end
        
        % --- ensures the current axes matches the tab's axes object
        function currentTabAxesCheck(obj)
            
            if ~isequal(obj.hFig.CurrentAxes,obj.objT{obj.iTab}.hAx)
                set(obj.hFig,'CurrentAxes',obj.objT{obj.iTab}.hAx);
            end
            
        end        
        
        % --- sets up the video converstion information data struct
        function setupConvInfoStruct(obj)
            
            vR = obj.getRecordingResolution();
            obj.resInfo = struct('rType',1,'W',vR(1),'H',vR(2),'bSz',1);
            
        end        
        
    end
    
    % static class methods
    methods (Static)
        
        % --- initialises the stimuli train parameter struct
        function sTrain = initStimTrainPara()
            
            % memory allocation
            sTrain = struct('S',[],'L',[],'Ex',[]);
            
        end
        
        % --- retrieves the protocol suffix for a given protocol type
        function dType = getProtoTypeStr(pType)
            
            switch pType
                case 'Experiment Information'
                    dType = 'Info';
                    
                case 'Short-Term Stimuli Protocol'
                    dType = 'S';
                    
                case 'Long-Term Stimuli Protocol'
                    dType = 'L';
                    
                case 'Experiment Stimuli Protocol'
                    dType = 'Ex';
            end
            
        end
        
        % --- resets the device type names
        function devType = resetDevType(devType)
            
            % converts 'HT ControllerV1' to 'Motor'
            devType(strcmp(devType,'HTControllerV1')) = {'Motor'};
            devType(strcmp(devType,'HTControllerV2')) = {'Motor'};
            %             devType(strcmp(devType,'HTControllerV3')) = {'Motor'};
            
        end
        
        % --- retrieves the general motor channel names (for nCh channels)
        function chName = getOptoChannelNames(varargin)
            
            % sets the channel name array
            chName = {'Red','Green','Blue','White'};
            
            % reverses the order (if specified)
            if nargin == 1
                chName = chName(end:-1:1);
            end
            
        end
        
    end
    
end