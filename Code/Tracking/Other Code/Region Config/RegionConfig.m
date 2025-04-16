classdef RegionConfig < handle
    
    % class properties
    properties
        
        % main dialog class fields
        hGUI
        hFigM
        hAxM
        hProp0
        hProp1
        
        % main object class fields
        hFig        
        hPanelO
        hPanelC
        hPanelAx        
        hTabGrp  
        jTabGrp
        
        % other object class fields
        hAx
        hTab                
        hButC
        
        % sub-class object fields
        objT                    % tab class object
        objD                    % display class object
        objRC                   % region class object
        objSR                   % split-region class object
        objCM                   % context menu class object
        objG                    % grid detection class object
        objPh                   % phase detection class objects
        
        % fixed object dimension fields
        H0T
        HWT
        dX = 10;  
        hghtTab = 25;
        hghtTxt = 16;
        hghtBut = 25;
        hghtChk = 23;
        hghtEdit = 22;
        hghtRadio = 20;
        hghtPopup = 23;
        hghtRow = 25;
        hghtPanelO = 555;
        hghtPanelC = 40;
        widPanelO = 300;
        widPanelAx = 670;                      
        
        % calculated object dimension fields                
        hghtFig  
        hghtAx
        widFig        
        widPanelI
        widPanelC        
        widButC
        widAx
        
        % other important class fields
        iMov
        iMov0
        iData
        iDataM
        dtPos
        cFigDir
        
        % temporary class fields
        p0
        axPosX
        axPosY
        
        % boolean class fields
        isHT
        isMTrk
        isCalib        
        isChange = false;
        isUpdating = false;
        isMenuOpen = false;
        isMouseDown = false;
        updateReqd = false;
        
        % static numeric class fields
        fSzH = 13;
        fSzL = 12;
        fSz = 10 + 2/3;
        nFrmEst = 10;
        tPause = 0.5;        
        
        % function handles
        tabSelFcn
        updateGroupFcn
        editParaFcn
        popupParaFcn
        checkParaFcn        
        checkSubGroupFcn
        radioRegionChangeFcn
        tableRegionEditFcn
        tableGroupEditFcn   
        tableGroupSelectFcn
                
        % static string class fields
        tagStr = 'figRegionConfig';
        figName = 'Tracking Region Configuration';
        ppStr = {'Circle','Rectangle','Polygon'};        
        fModeF = {'*.rcf', 'Region Configuration File (*.rcf)'};
        fModeD = {'*.csv', 'Region Configuration Data File (*.csv)'};        
        
    end       
    
    % class methods
    methods
        
        % --- class constructor
        function obj = RegionConfig(hGUI,hProp0)
            
            % creates a loadbar
            hLoad = ProgressLoadbar('Initialising Region Setting GUI...');
            pause(0.05);
            
            % sets the input arguments
            obj.hGUI = hGUI;
            obj.hProp0 = hProp0;            
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();
            obj.initClassProps(true);
            
            % deletes the loadbar
            delete(hLoad);
            
        end

        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % global variables
            global H0T HWT
            
            % main window object handles
            obj.hFigM = obj.hGUI.figFlyTrack;
            obj.hAxM = obj.hGUI.imgAxes;                 

            % field retrieval
            [obj.H0T,obj.HWT] = deal(H0T,HWT);
            obj.iDataM = get(obj.hFigM,'iData');            
            [obj.iMov,obj.iMov0] = deal(get(obj.hFigM,'iMov'));                               
            
            % boolean class field initialisation
            obj.isCalib = obj.hFigM.isCalib;
            obj.isHT = isHTController(obj.iDataM);
            obj.isMTrk = detMltTrkStatus(obj.iMov);
            
            % other field calculations
            obj.dtPos = [1,0,-2,0]*obj.dX/2 + obj.hghtPanelC*[0,-1,0,1];
            [obj.axPosX,obj.axPosY] = ...
                    obj.hFigM.calcAxesGlobalCoords(obj.hGUI);            
            
            % function handles
            obj.tabSelFcn = @obj.tabSelected;
            obj.updateGroupFcn = @obj.updateGroupSelection;
            obj.editParaFcn = @obj.editParaUpdate;
            obj.popupParaFcn = @obj.popupParaUpdate;
            obj.checkParaFcn = @obj.checkParaUpdate;            
            obj.checkSubGroupFcn = @obj.checkSubGrouping;
            obj.radioRegionChangeFcn = @obj.radioRegionChange;
            obj.tableRegionEditFcn = @obj.tableRegionEdit;
            obj.tableGroupEditFcn = @obj.tableGroupEdit;
            obj.tableGroupSelectFcn = @obj.tableGroupSelect;            
                        
            % sets up the configuration directory path
            obj.setupConfigDirPath();
            
            % disables the tracking gui panels
            obj.hProp1 = disableAllTrackingPanels(obj.hGUI,1);
            
            % ----------------------------------------- %
            % --- REGION DATA STRUCT INITIALISATION --- %
            % ----------------------------------------- %
           
            % sets the 2D region flag (if not set)
            if ~isfield(obj.iMov,'is2D')
                obj.iMov.is2D = is2DCheck(obj.iMov);
            end            
            
            % initialises an empty automatic detection parameter field
            if ~isfield(obj.iMov,'autoP') || isempty(obj.iMov.autoP)
                obj.iMov.autoP = pos2para(obj.iMov);
            end                        
            
            % ---------------------------------- %            
            % --- DATA STRUCT INITIALISATION --- %
            % ---------------------------------- %
            
            if obj.iMov.isSet
                % case is the region configuration has previously been set
                obj.iData = obj.convertDataStruct();
                
                % sets configuration information data struct (if missing)
                if ~isfield(obj.iMov,'pInfo')
                    obj.iMov.pInfo = obj.getDataSubStruct();
                end
                
                % back formats the sub-region data struct (2D)                
                if obj.iMov.is2D
                    % case is 2D single tracking setup
                    obj.backFormatDataStruct(true);                                        
                    
                elseif ~obj.isMTrk 
                    % case is 1D single tracking setup
                    obj.backFormatDataStruct(false);                    
                end
                
            else
                % case is the region configuration has not been set
                obj.iData = obj.initDataStruct();
            end        
            
            % -------------------------------------------- %
            % --- CALIBRATION SPECIFIC INITIALISATIONS --- %
            % -------------------------------------------- %
            
            if obj.isCalib
                % field retrieval
                infoObj = obj.hFigM.infoObj;
                
                % set the original frame size
                if isa(obj.hFigM.infoObj,'cell')
                    % case is the calibration testing mode
                    obj.hFigM.frmSz0 = size(infoObj.objIMAQ{1});
                
                else
                    % case is for proper calibration/RT-tracking
                    vRes = getVideoResolution(infoObj.objIMAQ);
                    obj.hFigM.frmSz0 = flip(vRes);
                end
            end
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %
            
            % figure dimension calculations
            obj.hghtFig = obj.hghtPanelO + 2*obj.dX;
            obj.widFig = obj.widPanelO + obj.widPanelAx + 3*obj.dX;
            
            % display axes dimension calculations
            obj.widAx = obj.widPanelAx - 2*obj.dX;
            obj.hghtAx = obj.hghtPanelO - 2*obj.dX;
            
            % other object dimension calculations
            obj.widPanelI = obj.widPanelO - 2.5*obj.dX;
            obj.widPanelC = obj.widPanelO - obj.dX;
            obj.widButC = (obj.widPanelC - 2.5*obj.dX)/2;
            
        end
        
        % --- initialises the class fields
        function initClassObjects(obj)
            
            % deletes any previous GUIs
            hPrev = findall(0,'tag',obj.tagStr);
            if ~isempty(hPrev); delete(hPrev); end
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = createUIObj('figure','Position',fPos,...
                'tag',obj.tagStr,'MenuBar','None','Toolbar','None',...
                'Name',obj.figName,'NumberTitle','off',...
                'Visible','off','AutoResizeChildren','off',...
                'Resize','off','BusyAction','Cancel',...
                'WindowButtonUpFcn',@obj.figButtonUp,...
                'WindowButtonDownFcn',@obj.figButtonDown,...
                'WindowButtonMotionFcn',@obj.figButtonMotion,...
                'CloseRequestFcn',[]);

            % creates the region config panel
            pPosO = [obj.dX*[1,1],obj.widPanelO,obj.hghtPanelO];
            obj.hPanelO = createUIObj(...
                'Panel',obj.hFig,'Position',pPosO,'Title','');
            
            % sets the class object into the figure
            setappdata(obj.hFig,'obj',obj);
            
            % ------------------------- %
            % --- MENU ITEM OBJECTS --- %
            % ------------------------- %
            
            % main menu items
            hMenuF = uimenu(obj.hFig,'Label','File','tag','hMenuFile');
            hMenuAD = uimenu(obj.hFig,...
                'Label','Automatic Detection','tag','hMenuAutoDetect');
            hMenuRS = uimenu(obj.hFig,...
                'Label','Region Splitting','tag','hMenuRegionSplit');            
                        
            % file menu items
            uimenu(hMenuF,'Label','Load Config File',...
                'tag','hMenuLoadConfig','Callback',@obj.menuLoadConfigFile)
            uimenu(hMenuF,'Label','Save Config File',...
                'tag','hMenuSaveConfig','Callback',@obj.menuSaveConfigFile)            
            uimenu(hMenuF,'Label','Reset Configuration',...
                'Callback',@obj.menuResetConfig,'Separator','on',...
                'tag','hMenuResetConfig');
            uimenu(hMenuF,'Label','Show Region Outlines',...
                'Callback',@obj.menuShowRegions,'tag','hMenuShowRegions');
            uimenu(hMenuF,'Label','Close Window','Accelerator','X',...
                'Callback',@obj.menuCloseWindow,'Separator','on',...
                'tag','hMenuCloseWindow');            
            
            % 1D automatic detection sub-menu items
            hMenu1D = uimenu(hMenuAD,...
                'Label','1D Assay','Tag','hMenuAutoDetect1D');
            uimenu(hMenu1D,'Label','Equally Spaced Grid',...
                'Callback',@obj.menuDetectGrid,'tag','hMenuDetectGrid');            
            
            % 2D automatic detection sub-menu items
            hMenu2D = uimenu(hMenuAD,...
                'Label','2D Assay','Tag','hMenuAutoDetect2D');
            uimenu(hMenu2D,'Label','Circles',...
                'Callback',@obj.menuDetectCirc,'tag','hMenuDetectCirc');
            uimenu(hMenu2D,'Label','Rectangles',...
                'Callback',@obj.menuDetectRect,'tag','hMenuDetectRect');
            uimenu(hMenu2D,'Label','General (Repeating)',...
                'Callback',@obj.menuDetectGen,'tag','hMenuDetectGen');
            uimenu(hMenu2D,'Label','General (Custom)',...
                'Callback',@obj.menuDetectGenCust,...
                'tag','hMenuDetectGenCust');
            
            % region splitting menu items
            uimenu(hMenuRS,'Label','Use Region Splitting',...
                'Callback',@obj.menuSplitRegion,'tag','hMenuUseSplit');
            uimenu(hMenuRS,'Label','Configuration Setup',...
                'Callback',@obj.menuConfigSetup,'Separator','on',...
                'tag','hMenuConfigSetup');                   
            
            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ %
            
            % initialisations
            bStrC = {'Set Regions','Update Changes'};
            cbFcnC = {@obj.buttonSetRegions,@obj.buttonUpdateChanges};
            
            % creates the control button objects
            pPosC = [obj.dX*[1,1]/2,obj.widPanelC,obj.hghtPanelC];
            obj.hPanelC = createUIObj(...
                'Panel',obj.hPanelO,'Position',pPosC,'Title','');
                        
            % other initialisations
            obj.hButC = cell(length(bStrC),1);
            for i = 1:length(bStrC)
                % sets up the button position vector
                lBut = obj.dX + (i-1)*(obj.widButC + obj.dX/2);
                bPos = [lBut,obj.dX-2,obj.widButC,obj.hghtBut];
                
                % creates the button object
                obj.hButC{i} = createUIObj('Pushbutton',obj.hPanelC,...
                    'Position',bPos,'Callback',cbFcnC{i},...
                    'FontUnits','Pixels','FontSize',obj.fSzL,...
                    'FontWeight','Bold','String',bStrC{i});
            end
            
            % ------------------------- %
            % --- TAB GROUP OBJECTS --- %
            % ------------------------- %
            
            % creates the tab panel group
            pPosTG = getTabPosVector(obj.hPanelO,obj.dtPos);
            obj.hTabGrp = createTabPanelGroup(obj.hPanelO,1);
            set(obj.hTabGrp,'position',pPosTG);
            
            % sets up the region information tabs (based on tracking type)
            if obj.isMTrk
                % multi-tracking region configuration
                obj.objT = {RegionConfig1D(obj)};
                
                % resets the data struct fields
                [obj.iData.is2D,obj.iData.isFixed] = deal(false,true);
                if ~obj.iMov.isSet || ...
                        ~isfield(obj.iMov.bgP.pMulti,'isFixed')
                    obj.iMov.bgP.pMulti.isFixed = true;
                end
                    
            else
                % single-tracking region configuration
                obj.objT = {RegionConfig1D(obj);...
                            RegionConfig2D(obj)};
                   
                % runs the sub-grouping (1D setup only)
                if ~obj.iData.is2D
                    obj.checkSubGrouping(obj.objT{1}.hChkR,[]);
                end
            end
            
            % retrieves the table group java object
            obj.jTabGrp = getTabGroupJavaObj(obj.hTabGrp); 

            % ---------------------------- %
            % --- DISPLAY AXES OBJECTS --- %
            % ---------------------------- %
            
            % creates the region config panel
            lPosAx = sum(pPosO([1,3])) + obj.dX;
            pPosAx = [lPosAx,obj.dX,obj.widPanelAx,obj.hghtPanelO];
            obj.hPanelAx = createUIObj(...
                'Panel',obj.hFig,'Position',pPosAx,'Title','');
            
            % creates the axes object
            axPos = [obj.dX*[1,1],obj.widAx,obj.hghtAx];
            obj.hAx = createUIObj('axes',obj.hPanelAx,'Position',axPos);
            set(obj.hAx,'XTickLabel',[],'YTickLabel',[],'Box','on',...
                'TickLength',[0,0],'XColor','w','YColor','w');
            
            % calculates the axes global coordinates
            obj.calcAxesGlobalCoords();
            
            % sets up the region config display class object
            obj.objD = RegionConfigDisplay(obj);
            
            % -------------------------------------- %
            % --- OTHER PROPERTY INITIALISATIONS --- %
            % -------------------------------------- %            
            
            % sets up the region class obhect
            obj.objRC = obj.hFigM.rgObj;
            obj.objRC.isMain = false;
            obj.objRC.hButU = obj.hButC{2};
            obj.objRC.hMenuSR = obj.getMenuItem('hMenuShowRegions');            
            
            % sets the region-set specific properties
            if obj.iMov.isSet
                % retrieves the split region use flag
                useSR = false;
                if isfield(obj.iMov,'srData') && ~isempty(obj.iMov.srData)
                    % case is the split-region data struct is set
                    if isfield(obj.iMov.srData,'useSR')
                        % case is the use sub-region flag is available
                        useSR = obj.iMov.srData.useSR;
                        
                    else
                        % otherwise, append the flag to the data struct
                        obj.updateReqd = true;
                        obj.iMov.srData.useSR = false;
                    end
                    
                    % enables split region configuration setup menu item
                    obj.setMenuEnable('hMenuConfigSetup',1);
                end
                
                % sets the region splitting menu item properties
                useMenuSR = obj.iMov.isSet && obj.iMov.is2D;
                obj.setMenuEnable('menuSplitRegion',useMenuSR)
                
                % sets the use region split menu item properties
                obj.setMenuCheck('hMenuUseSplit',useSR)                
                obj.setMenuEnable('hMenuUseSplit',useSR)
                
                % draw the main figure sub-region division
                obj.objRC.setupRegionConfig(obj.iMov,true);
            end                        
            
        end
        
        % --- initialises the class object properties
        function initClassProps(obj,isInit)

            % ---------------------------- %
            % --- TAB GROUP PROPERTIES --- %
            % ---------------------------- %
            
            % sets the tab group selections (based on whether the regions
            % have been set or not)
            if obj.iData.isFixed
                % sets the update tab index
                if obj.isMTrk
                    % case is multi-tracking
                    iTab = 1;                    
                else
                    % case is single-tracking
                    iTab = 1 + obj.iData.is2D;
                    obj.jTabGrp.setEnabledAt(~obj.iData.is2D,0);
                end
                
                % updates the selected tab
                obj.hTabGrp.SelectedTab = obj.objT{iTab}.hTab;
                
            else
                % case is the regions are not fixed
                xiT = 1:length(obj.objT);
                arrayfun(@(x)(obj.jTabGrp.setEnabledAt(x-1,1)),xiT);
            end

            % ------------------------------- %
            % --- AXES CONTEXT MENU SETUP --- %
            % ------------------------------- %
            
            % retrieves the region popup strings
            pStrR = obj.objT{1+obj.iData.is2D}.hPopupR.String;

            % creates the context menu items (if initialising)
            if isInit
                obj.objCM = AxesContextMenu(obj.hFig,obj.hAx,pStrR);
                obj.objCM.setMenuParent(obj.hPanelAx);
                obj.objCM.setCallbackFcn(obj.updateGroupFcn);
            end            
            
            % ----------------------------------- %
            % --- OTHER OBJECT PROPERTY SETUP --- %
            % ----------------------------------- %                        
        
            % resets the object properties
            obj.setMenuCheck('hMenuShowRegions',0);
            
            % resets the parameter values for all panel objects
            for i = 1:length(obj.objT)
                % retrieves the data struct
                pInfo = obj.getDataSubStruct(i-1);
                
                % updates the editbox parameter values
                hObjE = findall(obj.objT{i}.hPanel,'Style','Edit');
                for j = 1:length(hObjE)
                    hObjE(j).String = num2str(pInfo.(hObjE(j).UserData));
                end
                
                % updates the editbox parameter values
                hObjP = findall(obj.objT{i}.hPanel,'Style','PopupMenu');
                for j = 1:length(hObjP)
                    % updates the popupmenu value
                    if isempty(hObjP(j).UserData)
                        % case is object doesn't have a parameter value
                        hObjP(j).Value = 2;
                        
                    else
                        % case is object is linked to parameter value
                        pVal = pInfo.(hObjP(j).UserData);
                        iSelP = find(strcmp(hObjP(j).String,pVal));
                        hObjP(j).Value = iSelP;
                    end
                end
                
                % updates the editbox parameter values
                hObjC = findall(obj.objT{i}.hPanel,'Style','CheckBox');
                for j = 1:length(hObjC)
                    hObjC(j).Value = pInfo.(hObjC(j).UserData);
                end                
                
                % sets the other editbox properties
                nReg = pInfo.nRow*pInfo.nCol;                
                setObjEnable(obj.objT{i}.hEditC{3},nReg > 1);                
                
                % updates the table data/background colours
                hTableN = obj.objT{i}.hTableN;
                tCol = getAllGroupColours(length(pInfo.gName),1);
                set(hTableN,'Data',pInfo.gName,'BackgroundColor',tCol);
                
                % resets the properties for the region info panels
                if i == 2
                    % resets the selected radio button
                    hPanelR = obj.objT{i}.hPanelR;
                    hRadio = findall(hPanelR,'UserData',pInfo.gType);
                    hRadio.Value = 1;
                    
                    % runs the region change callback function
                    obj.radioRegionChange(hPanelR,'1');
                end
            end
            
            % updates the experiment setup specific properties
            if ~obj.iData.is2D
                % case is either multi-tracking or 1D setup
                
                % updates the region information table
                obj.updateRegionInfoTable(); 
                
                % runs the sub-grouping check box callback (1D setup only)
                if ~obj.isMTrk
                    obj.checkSubGrouping(obj.objT{1}.hChkR, [])
                end
            end            
            
            % updates the group name table and menu item properties
            obj.updateGroupNameTable();
            obj.updateMenuItemProps();
            obj.setMenuCheck('hMenuShowRegions',obj.iMov.isSet);
            
            % updated the context menu items (if not initialising)            
            if ~isInit
                pStrR = obj.objT{1+obj.iData.is2D}.hPopupR.String;
                obj.objCM.updateMenuLabels(pStrR)
            end            
            
            % resets the configuration axes
            obj.objD.resetConfigAxes();
            
            % control button properties
            setObjEnable(obj.hButC{2},obj.updateReqd);            
            
            % if not initialising, then exit
            if ~isInit; return; end

            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
           
            % centers the figure and makes it visible
            optFigPosition([obj.hFigM,obj.hFig],1)
            refresh(obj.hFig);
            pause(0.05);

            % makes the figure visible
            set(obj.hFig,'Visible','on');
            
        end

        %---------------------------------- %
        % --- OBJECT CREATION FUNCTIONS --- %
        %---------------------------------- %
        
        % --- creates a title panel object
        function hPanel = createPanel(obj,hP,pPos,tHdr,isBG)
            
            % sets the input arguments
            if ~exist('isBG','var'); isBG = false; end
            
            % sets the panel object type
            if isBG
                % case is a button group
                objType = 'buttongroup';
                
            else
                % case is a regular panel
                objType = 'panel';
            end
                
            % creates the panel object
            hPanel = createUIObj(objType,hP,'Position',pPos,...
                'Title',tHdr,'FontSize',obj.fSzH,'FontWeight','Bold');
            
        end
        
        % --- creates the text label combo objects
        function hEdit = createEditGroup(obj,hP,widTxt,tTxt,yPos,xOfs)
            
            % sets the default input arguments
            if ~exist('xOfs','var'); xOfs = obj.dX; end
            
            % initialisations
            tTxtL = sprintf('%s: ',tTxt);
            widEdit = hP.Position(3) - (2*obj.dX + widTxt);
            
            % sets up the text label
            pPosL = [xOfs,yPos+2,widTxt,obj.hghtTxt];
            createUIObj('text',hP,'Position',pPosL,'FontWeight','Bold',...
                'FontSize',obj.fSzL,'HorizontalAlignment','Right',...
                'String',tTxtL);
            
            % creates the text object
            pPosE = [sum(pPosL([1,3])),yPos,widEdit,obj.hghtEdit];
            hEdit = createUIObj(...
                'edit',hP,'Position',pPosE,'FontSize',obj.fSz);
            
        end
        
        % --- creates the text label combo objects
        function [hPopup,hTxt] = ...
                createPopupGroup(obj,hP,widTxt,tTxt,yPos,xOfs)
            
            % sets the default input arguments
            if ~exist('xOfs','var'); xOfs = obj.dX; end            
            
            % initialisations
            tTxtL = sprintf('%s: ',tTxt);
            widEdit = hP.Position(3) - (2*obj.dX + widTxt);
            
            % sets up the text label
            pPosL = [xOfs,yPos+2,widTxt,obj.hghtTxt];
            hTxt = createUIObj('text',hP,'Position',pPosL,...
                'FontSize',obj.fSzL,'String',tTxtL,'FontWeight','Bold',...
                'HorizontalAlignment','Right');
            
            % creates the text object
            pPosP = [sum(pPosL([1,3])),yPos,widEdit,obj.hghtEdit];
            hPopup = createUIObj(...
                'popupmenu',hP,'Position',pPosP,'FontSize',obj.fSz);
            
        end        

        % --------------------------------- %
        % --- FIGURE CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- mouse button up callback function
        function figButtonUp(obj, ~, ~)
            
            % determines if the user is currently click and dragging
            if obj.isMouseDown
                % field retrieval
                iTab = obj.iData.is2D + 1;
                pInfo = obj.getDataSubStruct();
                szG = flip(size(pInfo.iGrp));                
                iSel = obj.objT{iTab}.hPopupR.Value;
                
                % retrieves the current mouse position
                mP = get(obj.hAx,'CurrentPoint');
                mP = ceil(mP(1,1:2)-0.5);
            
                % updates the data struct with the new group index
                if obj.iData.is2D || obj.isMTrk
                    % determines the grid row/column indices
                    iC = min(obj.p0(1),mP(1)):max(obj.p0(1),mP(1));
                    iR = min(obj.p0(2),mP(2)):max(obj.p0(2),mP(2));
                    
                    % updates the grouping index
                    pInfo.iGrp(iR,iC) = iSel - 1;
                    
                else
                    % determines the region indices
                    indR0 = obj.objD.getRegionIndices1D(obj.p0);
                    indRU = obj.objD.getRegionIndices1D(mP);
                    iC = min(obj.p0(1),mP(1)):max(obj.p0(1),mP(1));
                    
                    % updates the group indices based on type
                    if pInfo.isFixed
                        % case is using sub-grouping
                        
                        % determines the sub-region indices
                        [iR,iC,iFly] = ...
                            obj.objD.getSubRegionCoord(indR0,indRU,0);
                        
                        % resets the mapping indices
                        for i = 1:length(iR)
                            for j = 1:length(iC)
                                % updates the mapping indices
                                pInfo.gID{iR(i),iC(j)}(iFly{i,j}) = iSel-1;
                                
                                % updates the region group name table
                                pInfo = obj.resetSubRegionTableGroup(...
                                        pInfo,[iR(i),iC(j)],iSel);                                
                            end
                        end                                                
                        
                    else
                        % case is using full grouping
                        
                        % determines the row indices
                        iR = min(indR0(1),indRU(1)):max(indR0(1),indRU(1));
                        
                        % resets the group index and mapping indices
                        pInfo.iGrp(iR,iC) = iSel - 1;
                        for i = 1:length(iR)
                            for j = 1:length(iC)
                                pInfo.gID{iR(i),iC(j)}(:) = iSel - 1;
                            end
                        end
                    end
                end
                    
                % updates the data sub-struct
                obj.setDataSubStruct(pInfo);                
                
                % resets the region information table group names
                if ~obj.iData.is2D && ~pInfo.isFixed
                    [ix,iy] = meshgrid(iC,iR(:));
                    iRow = sub2ind(szG,ix,iy);
                    obj.resetRegionTableGroup(iRow,iSel);
                end
                
                % deletes the selection patch and resets the config axes
                obj.objD.updateSelectionPatch('delete')
                obj.objD.resetConfigAxes(false)                
                
                % enables the update button
                setObjEnable(obj.hButC{2},1);
            end
            
            % resets the mouse-down flag
            obj.isMouseDown = false;            
                
        end
        
        % --- mouse button down callback function
        function figButtonDown(obj, ~, ~)
            
            % initialisations
            mPos = get(obj.hFig,'CurrentPoint');
            [obj.p0,obj.isMouseDown] = deal([],false);
            
            % exit if 2D setup and using fixed regions
            if obj.iData.is2D && (obj.iData.D2.gType == 1)
                return
            end
            
            % determines if the mouse is over the axis
            if isOverAxes(mPos) 
                % retrieves the selection type
                sType = get(obj.hFig,'SelectionType');
                mPosAx = ceil(get(obj.hAx,'CurrentPoint')-0.5);                
                
                % performs the update based on the mouse selection type
                if strcmp(sType,'alt')
                    % case is the user right-clicked
                    pInfo = obj.getDataSubStruct();
                    
                    % sets the selected group index
                    if obj.iData.is2D || obj.isMTrk
                        % case is for a 2D experimental setup
                        iGrpS = pInfo.iGrp(mPosAx(1,2),mPosAx(1,1));
                        
                    else
                        % case is for a 1D experimental setup
                        indR = obj.objD.getRegionIndices1D(mPosAx);
                        if pInfo.isFixed
                            iGrpS = pInfo.gID{indR(1),indR(2)}(indR(3));
                        else
                            iGrpS = pInfo.iGrp(indR(1),indR(2));
                        end
                    end                        
                    
                    % updates the menu check mark and position        
                    obj.objCM.updateMenuCheck(iGrpS+1);
                    obj.objCM.updatePosition(mPos);
                    obj.objCM.setVisibility(1)        

                    % flag that the menu is now open
                    obj.isMenuOpen = true;
                    return                    
                    
                elseif strcmp(sType,'normal')
                    % case is the user left-clicked
                    if obj.isMenuOpen
                        % the mouse click is not on menu, then close it
                        obj.isMenuOpen = false;
                        obj.objCM.setVisibility(0);                        
                    
                    else
                        % sets the initial point of the selection
                        mP = get(obj.hAx,'CurrentPoint');
                        obj.isMouseDown = true;
                        obj.p0 = ceil(mP(1,1:2)-0.5);
                        
                        % performs update based on experimental setup type 
                        if obj.iData.is2D || obj.isMTrk
                            % case is a 2D experimental setup
                            if ~obj.figButtonDown2D()
                                return
                            end

                        else
                            % case is a 1D experimental setup
                            if ~obj.figButtonDown1D()
                                return                                
                            end
                        end
                    end
                end
            end
            
            % closes the context menu item (if open)
            if obj.isMenuOpen
                obj.objCM.setVisibility(0)
            end
                
        end
        
        % --- mouse button motion callback function
        function figButtonMotion(obj, ~, ~)
            
            % determines if the user is currently click and dragging
            mP = get(obj.hAx,'CurrentPoint');
            
            if obj.isMouseDown
                % updates the selection patch    
                obj.objD.updateSelectionPatch('update',ceil(mP(1,1:2)-0.5))
                
            elseif obj.isMenuOpen
                % determines if the mouse is over the menu    
                if isOverAxes(get(obj.hFig,'CurrentPoint'))    
                    tStrM = {'tag','hMenu'};
                    hMenu = findAxesHoverObjects(obj.hFig,tStrM,obj.hFig);                    
                    if ~isempty(hMenu)
                        % if mouse is over context menu, then determine  
                        % which text label the mouse is hovering over
                        tStrT = {'style','text'};
                        hLbl = findAxesHoverObjects(obj.hFig,tStrT,hMenu);
                        if ~isempty(hLbl)
                            % if over a label, then retrieve label index
                            iSel = get(hLbl,'UserData');
                            if obj.objCM.iSel ~= iSel
                                % if selection changed, then de-highlight 
                                % currently highlighted menu item
                                if obj.objCM.iSel > 0
                                    iSelCM = obj.objCM.iSel;
                                    obj.objCM.setMenuHighlight(iSelCM,0)
                                end
                                
                                % updates the menu highlight
                                obj.objCM.setMenuHighlight(iSel,1)
                            end
                            
                            % exits the function
                            return                            
                        end
                    end
                else
                    % if no longer over the axes, close the menu
                    obj.isMenuOpen = false;
                    obj.objCM.setVisibility(0);                    
                end
                
                % if the menu highlight is still on, then remove it
                if obj.objCM.iSel > 0
                    obj.objCM.setMenuHighlight(obj.objCM.iSel,0)
                end
            end
                    
        end        

        % --- figure button down callback function (1D expt setup)
        function ok = figButtonDown1D(obj)
            
            % initialisations
            ok = true;
            pInfo = obj.getDataSubStruct;
            szG = flip(size(pInfo.iGrp));
            indR = obj.objD.getRegionIndices1D(obj.p0);

            % sets the group colour
            iSel = obj.objT{1}.hPopupR.Value;
            pCol = getAllGroupColours(length(pInfo.gName));            

            % creates the selection patch function
            obj.objD.updateSelectionPatch('add',pCol(iSel,:))            

            % updates the region information table (full region set only)
            if pInfo.isFixed
                % updates the region group name table
                obj.resetSubRegionTableGroup(pInfo,indR,iSel);                
                
            else                
                iRow = sub2ind(szG,indR(2),indR(1));
                obj.resetRegionTableGroup(iRow,iSel);            
            end
                
        end                
        
        % --- figure button down callback function (1D expt setup)
        function ok = figButtonDown2D(obj)
            
            % if using regular grid setup, then exit
            if ~obj.isMTrk
                if obj.objT{2}.hRadioR{1}.Value
                    ok = false;
                    return
                end
            end
            
            % initialisations
            ok = true;
            iTab = 2 - obj.isMTrk;
            pInfo = obj.getDataSubStruct;            
            
            % sets the group colour
            iSel = obj.objT{iTab}.hPopupR.Value;
            pCol = getAllGroupColours(length(pInfo.gName));
            
            % creates the selection patch function
            obj.objD.updateSelectionPatch('add',pCol(iSel,:))
            
            % updates the region information table
            if obj.isMTrk
                szG = flip(size(pInfo.iGrp));
                iRow = sub2ind(szG,obj.p0(1),obj.p0(2));
                obj.resetRegionTableGroup(iRow,iSel);
            end
        
        end
        
        % ----------------------------- %
        % --- FILE MENU ITEM EVENTS --- %
        % ----------------------------- %
        
        % --- load config file menu item callback function
        function menuLoadConfigFile(obj, ~, ~)
            
            % initialisations
            tStr = 'Select A File';
            
            % prompts the user for the configuration file
            [fName,fDir,fIndex] = uigetfile(obj.fModeF,tStr,obj.cFigDir);
            if ~fIndex
                % if the user cancelled, then exit 
                return
            end
            
            % loads the data struct
            A = load(fullfile(fDir,fName),'-mat');
            obj.iData.is2D = isfield(A.pInfo,'nRowG');
            obj.setDataSubStruct(A.pInfo);

            % runs the file load property update
            obj.postFileLoadPropUpdate();
            
        end       
        
        % --- save config file menu item callback function
        function menuSaveConfigFile(obj, ~, ~)
            
            % initialisations
            tStr = 'Select A File';
            
            % prompts the user for the configuration file
            [fName,fDir,fIndex] = uiputfile(obj.fModeF,tStr,obj.cFigDir);
            if ~fIndex
                % if the user cancelled, then exit
                return
            end
            
            % saves the data struct to file
            pInfo = obj.getDataSubStruct();
            save(fullfile(fDir,fName),'pInfo')            
            
        end
        
        % --- reset configuration menu item callback function
        function menuResetConfig(obj, ~, ~)
            
            % prompts the user if they wish to proceed
            tStr = 'Reset Configuration?';
            qStr = {'Are you sure you want to reset the current ';...
                    'configuration? The operation can not be reversed.'};
            uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % if the user did not confirm, then exit
                return
            end
           
            % object handles
            obj.iMov.isSet = false;
            obj.updateReqd = false;
            
            % resets the automatic detection parameter struct
            aP = pos2para(obj.iMov);
            [obj.iMov.autoP,obj.objRC.iMov.autoP] = deal(aP);
            
            % deletes the configuration regions
            obj.objRC.deleteRegionConfig();                
            
            % resets the data struct and class objects
            obj.iData = obj.initDataStruct();            
            obj.initClassProps(false);
            
        end
        
        % --- show regions menu item callback function
        function menuShowRegions(obj, hObj, ~)

            % toggles the menu item
            toggleMenuCheck(hObj)

            % plots the region outlines
            isShow = strcmp(get(hObj,'Checked'),'on');
            obj.objRC.setMarkerVisibility(isShow);
            
        end
        
        % --- window close menu item callback function
        function menuCloseWindow(obj, ~, ~)
            
            % if an update is specified, then prompt the user to update
            if strcmp(obj.hButC{2}.Enable,'on')
                % prompts the user if they wish to update the struct
                tStr = 'Update Sub-Regions?';
                qStr = 'Do you wish to update the specified sub-region?';
                uChoice = questdlg(qStr,tStr,'Yes','No','Cancel','Yes');
                
                switch uChoice
                    case ('Yes') 
                        % case is the user wants to update movie struct
                        obj.buttonUpdateChanges(obj.hButC{2}, 1);
                        
                    case ('No') 
                        % case is the user does not want to update
                        obj.isChange = false;
                        
                    otherwise
                        % case is the user cancelled
                        return
                end
            end
                
            % makes the gui invisible
            setObjVisibility(obj.hFig,0);

            % closes the grid detection GUI (if open)
            hGrid = findall(0,'tag','figGridDetect');
            if ~isempty(hGrid)
                obj.objG.isClosing = true;
                obj.objG.cancelButton(obj.objG.hButC{3})
            end

            % deletes the sub-regions from tracking gui axes
            obj.objRC.deleteRegionConfig(1)
            if ~isempty(obj.hGUI)
                % removes all the circle regions from the main GUI (if they exist)
                hOut = findall(obj.hAxM,'tag','hOuter');
                if ~isempty(hOut); delete(hOut); end

                % reset the property snapshot
                resetHandleSnapshot(obj.hProp1)

                % runs the post window split function
                postSplitFcn = obj.hFigM.postWindowSplit;
                postSplitFcn(obj.hGUI,obj.iMov,obj.hProp0,obj.isChange)
            end

            % closes the GUI
            delete(obj.hFig)
            
        end
        
        % --------------------------------------- %
        % --- AUTOMATIC DETECTION ITEM EVENTS --- %
        % --------------------------------------- %
        
        % --- grid detection menu item callback function 
        function menuDetectGrid(obj, ~, ~)
           
            % field retrieval
            isUpdate = false;
            iMovOrig = obj.iMov;
            
            % if the field does exist, then ensure it is correct
            obj.iMov.phInfo = [];
            obj.iMov.bgP = ...
                DetectPara.resetDetectParaStruct(obj.iMov.bgP,obj.isHT);
            
            % determines the sub-region dimension configuration
            [iMovNw,ok] = setSubRegionDim(obj.iMov,obj.hGUI);
            if ~ok
                % exits the function if there was an error
                setObjEnable(hObject,'off')
                return
            else
                % otherwise, update the data struct
                obj.iMov = iMovNw;
            end
            
            % opens the grid detection tracking parameter gui
            obj.objG = GridDetect(obj);
            if obj.objG.iFlag == 3
                % if the user cancelled, then exit
                obj.objRC.setupRegionConfig(iMovOrig,true);
                return
            end
            
            % keep looping until either the user quits or accepts the result
            cont = obj.objG.iFlag == 1;
            while cont
                % runs the 1D auto-detection algorithm
                dObj = DetGridRegion(obj);
                if ~dObj.calcOK
                    % if user cancelled then exit loop and close para gui
                    obj.iMov = iMovOrig;
                    obj.objRC.setupRegionConfig(iMovOrig,true);
                    obj.objG.closeGUI();
                    return
                end
                
                % allow user to reset location of regions (either up or 
                % down) or redo the region calculations
                obj.objG.checkDetectedSoln(dObj.iMov,dObj.trkObj);
                switch obj.objG.iFlag
                    case 2
                        % case is the user continued
                        [cont,isUpdate] = deal(false,true);
                        
                    case 3
                        % case is the user cancelled
                        if obj.objG.isClosing
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
                % resets the region configuration
                obj.objRC.setupRegionConfig(obj.objG.iMov,true);
                
                % resets the region dimension properties
                for iApp = find(obj.objG.iMov.ok(:)')
                    obj.objRC.resetRegionPropDim(...
                            obj.objG.iMov.pos{iApp},iApp)
                end
            end
                        
            % sets up the sub-regions for the final time (delete loadbar)
            obj.postAutoDetectUpdate(iMovOrig,obj.objG.iMov,isUpdate)
            delete(h)
        end
            
        % --- circle detection menu item callback function 
        function menuDetectCirc(obj, ~, ~)
        
            % retrieves the automatic detection algorithm objects
            [iMovOrig,~] = obj.initAutoDetect();
            if isempty(iMovOrig); return; end
            
            % retrieves the region estimate image stack
            I = obj.getRegionEstImageStack(iMovOrig);
            if isempty(I)
                % if the user cancelled, then exit the function
                setObjVisibility(obj.hFig,1);
                return
                
            else
                % runs the automatic circle detection algorithm
                objCD = AutoCircPara(obj,iMovOrig,I);
                if objCD.calcOK
                    % case is the detection was run successfully
                    iMovNw = objCD.iMov;
                    if obj.isMTrk
                        iMovNw.autoP.pPos = para2pos(iMovNw.autoP);                        
                    end
                    
                else
                    % case is the user cancelled or the detection failed
                    iMovNw = [];
                end
            end
            
            % performs the post automatic detection updates
            obj.postAutoDetectUpdate(iMovOrig,iMovNw);
            
        end            
            
        % --- rectangle detection menu item callback function 
        function menuDetectRect(obj, ~, ~)
        
            % determines if there are multiple regions
            if ~obj.multiRegionCheck()
                % if not output an error and exit
                eStr = ['Rectangle detection is only feasible ',...
                        'for multi-region setups'];
                waitfor(msgbox(eStr,'Region Detection Error','modal'))
                return
            end            
            
            % retrieves the automatic detection algorithm objects
            [iMovOrig,~] = obj.initAutoDetect();
            if isempty(iMovOrig); return; end
            
            % retrieves the region estimate image stack
            I = obj.getRegionEstImageStack(iMovOrig);
            if isempty(I)
                % if the user cancelled, then exit the function
                setObjVisibility(obj.hFig,1);
                return
                
            else
                % runs the general region detection algorithm
                if obj.isMTrk
                    obj.objG = MultiGenRegionDetect(iMovOrig,I);
                else
                    obj.objG = SingleGenRegionDetect(iMovOrig,I);
                end
                
                % runs the rectangle region detection algorithm
                if obj.objG.calcOK
                    % case is the calculations succeeded
                    iMovNw = obj.objG.iMov;
                    
                else
                    % case is the user cancelled
                    iMovNw = [];
                end
            end
            
            % performs the post automatic detection updates
            obj.postAutoDetectUpdate(iMovOrig,iMovNw);
            
        end            
            
        % --- general shape detection menu item callback function 
        function menuDetectGen(obj, ~, ~)
        
            % retrieves the automatic detection algorithm objects
            [iMovOrig,~] = obj.initAutoDetect();
            if isempty(iMovOrig); return; end        
            
            % retrieves the region estimate image stack
            I = obj.getRegionEstImageStack(iMovOrig);            
            if isempty(I)
                % if the user cancelled, then exit the function
                setObjVisibility(obj.hFig,1);
                return            
            
            else
                try
                    % runs the general region detection algorithm
                    iMovNw = detGenRegions(iMovOrig,I);
                    
                catch ME
                    % if there was an error, then output a message to screen
                    tStr = 'General Region Detection Error!';
                    eStr = sprintf(['There was an error in the ',...
                        'general region detection calculations. Try ',...
                        'resetting the search region and retrying']);
                    waitfor(errordlg(eStr,tStr,'modal'))
                    
                    % sets an empty sub-region data struct
                    iMovNw = [];
                end
            end
            
            % performs the post automatic detection updates
            obj.postAutoDetectUpdate(iMovOrig,iMovNw);            
                
        end
            
        % --- custom shape detection menu item callback function 
        function menuDetectGenCust(~, ~, ~)
        
           % FINISH ME!
            showUnderDevelopmentMsg() 
            
        end
        
        % ----------------------------------------- %
        % --- REGION SPLITTING MENU ITEM EVENTS --- %
        % ----------------------------------------- %
        
        % --- split region menu item callback functions
        function menuSplitRegion(obj, hObj, ~)

            % toggles the checkmark
            toggleMenuCheck(hObj)
            
            % updates the split-region flag
            obj.iMov.srData.useSR = strcmp(hObj.Checked,'on');
            
            % enables the update button
            setObjEnable(obj.hButC{2},1);

        end

        % --- configuration setup menu item callback functions
        function menuConfigSetup(obj, ~, ~)

            % ensures the split region data struct is setup properly
            if isfield(obj.iMov,'srData') && ~isempty(obj.iMov.srData)
                if isfield(obj.iMov.srData,'Type')
                    % resets the split region data struct if shape mismatch
                    if ~strcmp(obj.iMov.mShape,obj.iMov.srData.Type)
                        obj.iMov.srData = [];
                    end
                else
                    % case is the type field hasn't be set (force reset)
                    obj.iMov.srData = [];
                end
            else
                % case is the type field hasn't be set (force reset)
                obj.iMov.srData = [];                
            end
            
            % if there is no split region data, then disable the split menu item
            if isempty(obj.iMov.srData)
                obj.setMenuEnable('hMenuUseSplit',0)
                obj.setMenuCheck('hMenuUseSplit',0)
            end
            
            % runs the sub-region splitting sub-program
            obj.objSR = SplitSubRegion(obj);
                
        end        
        
        % -------------------------------------- %
        % --- MAIN OBJECT CALLBACK FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- protocol tab callback function
        function tabSelected(obj, hObj, evnt)

            % updates the 2D selection flag
            obj.iData.is2D = hObj.UserData == 2;

            % updates the menu item properties/config axes
            obj.updateMenuItemProps()
        
            % resets the context menu labels
            pStrR = obj.objT{hObj.UserData}.hPopupR.String;            
            obj.objCM.updateMenuLabels(pStrR)            
            
            % resets the configuration axes (if not running directly)
            if ~isempty(evnt)
                obj.objD.resetConfigAxes()
            end
            
        end
        
        % --- region setting button callback function
        function buttonSetRegions(obj, ~, ~)
            
            % deletes automatically detected regions (if any present)
            hOut = findall(obj.hAxM,'tag','hOuter');
            if ~isempty(hOut); delete(hOut); end
            
            % sets up the sub-regions
            obj.iMov.isSet = true;
            obj.iMov.is2D = obj.iData.is2D;
            [obj.iMov.iR,obj.iMov.phInfo] = deal([]);
            
            % creates the sub-regions configuration
            obj.iMov = obj.objRC.setupRegionConfig(obj.iMov);
            figure(obj.hFig);
            
            % updates the other object properties
            setObjEnable(obj.hButC{2},1);
            obj.setMenuCheck('hMenuShowRegions',1);
            obj.updateMenuItemProps();
            
        end
        
        % --- change update button callback function
        function ok = buttonUpdateChanges(obj, hBut, evnt)
            
            % initialisations
            iMovT = obj.iMov;
            
            % region data struct reset
            iMovT.Ibg = [];
            if isfield(iMovT,'xcP')
                iMovT = rmfield(iMovT,'xcP');
            end
            
            % sets the final sub-region dimensions into the data struct
            [iMovT,ok] = setSubRegionDim(iMovT,obj.hGUI);
            if ~ok
                % if there was an issue, then exit the function
                return
                
            elseif ~isa(evnt,'char')
                % otherwise, update the properties/flags
                obj.isChange = true;
                setObjEnable(hBut,'off');
            end
            
            % updates the sub-region data struct
            iMovT.pInfo = obj.getDataSubStruct();
            obj.iMov = iMovT;
            
        end         
        
        % ------------------------------------ %
        % --- PARAMETER CALLBACK FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- configuration parameter editbox callback function
        function editParaUpdate(obj, hObj, ~)
            
            % field retrieval
            [eVal,pMlt] = deal([]);
            iTab = 1 + obj.iData.is2D;
            pStr = get(hObj,'UserData');
            pInfo = obj.getDataSubStruct();
            nwVal = str2double(hObj.String);
            
            % determines if a uniform grid configuration is required (2D
            % only with grid grouping)
            if obj.iData.is2D
                % case is a 2D setup
                isGrid = (pInfo.nGrp > 1) && obj.objT{2}.hRadioR{1}.Value;
                
            else
                % otherwise, set a false flag
                isGrid = false;
            end
            
            % sets the parameter limits
            switch pStr
                case 'nRow'
                    % case is the row count
                    nwLim = [1,20];
                    if isGrid; pMlt = pInfo.nRowG; end
                    
                case 'nCol'
                    % case is the row count
                    nwLim = [1,20];
                    if isGrid; pMlt = pInfo.nRowG; end  
                    
                case 'nGrp'
                    % case is the group count
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
            if chkEditValue(nwVal,nwLim,1,'exactVal',eVal,'exactMlt',pMlt)            
                % if so, update the parameter in the data struct
                pInfo.(pStr) = nwVal;
                obj.setDataSubStruct(pInfo);
                
                % updates the group count editbox enabled properties
                hEdit = findall(obj.objT{iTab}.hPanelC,'UserData','nGrp');
                setObjEnable(hEdit,pInfo.nRow*pInfo.nCol > 1);
                
                % updates object properties based on parameters values
                if pInfo.nRow*pInfo.nCol < pInfo.nGrp
                    % case is the group count exceeds the region count
                    
                    % resets the group count and editbox string
                    pInfo.nGrp = pInfo.nRow*pInfo.nCol;
                    hEdit.String = num2str(pInfo.nGrp);
                    obj.setDataSubStruct(pInfo);
                    
                    % updates the group name table (if updating the group count)
                    obj.updateGroupNameTable()
                    
                elseif strcmp(pStr,'nGrp')
                    % case is the group count
                    
                    % updates the group name table
                    obj.updateGroupNameTable();
                    
                    % updates the panel properties (based on group count)
                    if obj.iData.is2D
                        % case is a 2D experimental setup
                        obj.radioRegionChange(obj.objT{iTab}.hPanelR,'1');
                    end
                    
                elseif strcmp(pStr,'nFlyMx')
                    % case is the max fly count
                    
                    % ensure all fly counts are less than equal to max
                    if any(pInfo.nFly(:) > pInfo.nFlyMx)
                        pInfo.nFly = min(pInfo.nFly,pInfo.nFlyMx);
                        obj.setDataSubStruct(pInfo);
                    end
                end
               
                % updates the data struct/information table
                if obj.iData.is2D
                    % updates the data sub-struct
                    pInfo = obj.updateGroupArrays();
                    obj.setDataSubStruct(pInfo,true);
                    
                    if pInfo.nGrp == 1
                        % if there is only one group, then reset the group 
                        % indices so that they are all 1
                        pInfo.iGrp(:) = 1;
                        obj.setDataSubStruct(pInfo,true);
                        
                    else
                        % otherwise, re-run the region panel buttongroup
                        % callback function
                        obj.radioRegionChange(obj.objT{iTab}.hPanelR,1);
                    end
                    
                else
                    % updates the 1D region information table
                    obj.updateRegionInfoTable();
                end
               
                % resets the group ID flags (1D tracking only)
                if ~obj.isMTrk && ~obj.iData.is2D
                    obj.resetRegionGroupID();
                end
                
                % resets the configuration axes
                obj.objD.resetConfigAxes()
                
            else
                % otherwise, revert back to the previous valid value
                hObj.String = num2str(pInfo.(pStr));
            end
        end
        
        % --- configuration parameter popupmenu callback function
        function popupParaUpdate(obj, hObj, ~)
            
            % field retrieval
            pStr = hObj.UserData;
            pInfo = obj.getDataSubStruct();
            [lStr,iSel] = deal(hObj.String,hObj.Value);
            
            % updates the parameter in the data struct
            pInfo.(pStr) = lStr{iSel};
            obj.setDataSubStruct(pInfo);
            
            % performs parameter specific property updates
            switch pStr
                case 'mShape'
                    % updates the shape field
                    obj.iMov.mShape = lStr{iSel}(1:4);                
                
                    % case is the region shape string
                    if obj.iMov.isSet
                        % creates the loadbar figure
                        lbStr = 'Resetting Region Shapes...';
                        hProg = ProgressLoadbar(lbStr);                    
                
                        % updates the parameter fields
                        obj.objRC.iMov.pInfo.Type = lStr{iSel};
                        obj.iMov.pInfo = obj.objRC.iMov.pInfo;                        
                        
                        % toggles the shape menu check items
                        obj.objRC.deleteRegionConfig();
                        obj.iMov = obj.objRC.setupRegionConfig(obj.iMov,1);
                        
                        % determines if the split-region information is set
                        if isfield(obj.iMov,'srData') && ~isempty(obj.iMov.srData)
                            % check if current/split region shape match
                            if strcmp(obj.iMov.mShape,obj.iMov.srData.Type)
                                % if so, then enable the menu item
                                obj.setMenuEnable('hMenuUseSplit',1);
                                
                            else
                                % otherwise, reset split region flag
                                obj.setMenuCheck('hMenuUseSplit',0);
                                obj.setMenuEnable('hMenuUseSplit',0);
                                obj.iMov.srData.useSR = false;                                
                            end
                        end
                        
                        % updates the auto-detection menu items
                        if obj.iData.is2D
                            obj.updateAutoMenuItemProps2D();
                        end

                        % enables the update button
                        setObjEnable(obj.hButC{1},1)
                        
                        % deletes the loadbar figure
                        delete(hProg);
                    end
            end
            
        end
        
        % --- configuration parameter popupmenu callback function
        function checkParaUpdate(obj, hObj, ~)
            
            % field retrieval
            pInfo = obj.getDataSubStruct();
            
            % updates the parameter in the data struct
            pInfo.(hObj.UserData) = hObj.Value;
            obj.setDataSubStruct(pInfo);
            
        end
        
        % --- sub-grouping checkbox callback function 
        function checkSubGrouping(obj, hObj, evnt)
            
            % field retrieval
            isOn = hObj.Value;
            
            % updates the object properties
            setObjEnable(obj.objT{1}.hTableR,~isOn);
            
            % if initialising, then exit the function
            if isempty(evnt); return; end
            
            % if using full region setup, then reset the mapping ID flags
            if ~isOn
                % retrieves the region data struct
                pInfo = obj.getDataSubStruct();
                
                % resets the grouping indices
                for i = 1:pInfo.nRow
                    for j = 1:pInfo.nCol
                        pInfo.gID{i,j}(:) = pInfo.iGrp(i,j);
                    end
                end
                
                % resets the region data struct and config axes
                obj.setDataSubStruct(pInfo);
                obj.objD.resetConfigAxes();
            end
            
            % updates the data struct field
            obj.iData.D1.(hObj.UserData) = isOn;            
            
        end
        
        % --- region table cell edit callback function
        function tableRegionEdit(obj, hObj, evnt)
            
            % exits if there are no indices
            if isempty(evnt.Indices)
                return
            end
            
            % field retrieval
            iSel = evnt.Indices;
            nwVal = evnt.NewData;
            pInfo = obj.getDataSubStruct(false);
            [tData,cForm] = deal(hObj.Data,hObj.ColumnFormat);

            % retrieves the global column/row indices
            [iRG,iCG] = deal(tData{iSel(1),1},tData{iSel(1),2});            
            
            % table column specific updates
            switch iSel(2)
                case 3
                    % case is the sub-region count
                    
                    % determines if the new valid is valid
                    if chkEditValue(nwVal,[0,pInfo.nFlyMx],1)
                        % if so, then update the parameter field
                        pInfo.nFly(iRG,iCG) = nwVal;
                        
                        % if setting count to zero, then reset group fields
                        if nwVal == 0
                            pInfo.iGrp(iRG,iCG) = 0;
                            hObj.Data{iSel(1),4} = cForm{end}{1};
                        end
                        
                        % resets group mapping indices (1D tracking only) 
                        if ~obj.isMTrk
                            pInfo = obj.resetRegionGroupID(pInfo);
                        end
                        
                    else
                        % otherwise, reset to the previous valid value
                        hObj.Data{iSel(1),iSel(2)} = evnt.PreviousData;
                        
                        % exits the function
                        return
                    end
                    
                case 4
                    % case is the region group name
                    
                    % determines if the fly count is valid
                    nFlyS = pInfo.nFly(iRG,iCG);
                    if (nFlyS == 0) || isnan(nFlyS)
                        % if not, then output an error message 
                        tStr = 'Infeasible Region Configuration';
                        eStr = ['Set a non-zero sub-region count ',...
                                'before setting the group type.'];
                        waitfor(msgbox(eStr,tStr,'modal'))
                        
                        % resets the previous valid value
                        hObj.Data{iSel(1),iSel(2)} = evnt.PreviousData;
                        
                        % exits the function
                        return
                    else
                        % otherwise, reset the group/mapping indices
                        iGrpNw = find(strcmp(cForm{end},nwVal)) - 1;
                        pInfo.iGrp(iRG,iCG) = iGrpNw;
                        pInfo.gID{iRG,iCG}(:) = iGrpNw;
                        
                        % enables the update button (if regions are set)
                        if obj.iMov.isSet
                            setObjEnable(obj.hButC{2},1);
                        end
                    end
                    
            end            
            
            % updates the update button
            setObjEnable(obj.hButC{1},obj.iMov.isSet)
            
            % updates the data struct into the gui
            obj.setDataSubStruct(pInfo,false);
            
            % resets the configuration axes
            obj.objD.resetConfigAxes()
            
        end        
        
        % --- group name table cell edit callback function        
        function tableGroupEdit(obj, hObj, evnt)
            
            % exits if there are no indices
            if isempty(evnt.Indices)
                return
            end
            
            % field retrieval
            iSel = evnt.Indices;
            nwVal = evnt.NewData;
            pInfo = obj.getDataSubStruct();
            
            % determines if the new name is unique
            if any(strcmp(pInfo.gName,nwVal))
                % if not, then output an error message to screen
                mStr = sprintf(['The group name "%s" already exists ',...
                    'in the list.\nPlease try again with a different ',...
                    'group name.'],nwVal);
                waitfor(msgbox(mStr,'Replicated Name','modal'))
                
                % resets the parameter value
                hObj.Data{iSel(1),iSel(2)} = evnt.PreviousData;
                
                % exits the function
                return
                
            else
                % otherwise, updates the group name
                pInfo.gName{iSel(1)} = nwVal;
                
                % updates the region popup strings
                iTab = obj.hTabGrp.SelectedTab.UserData;
                obj.objT{iTab}.hPopupR.String{iSel(1)+1} = nwVal;

                % updates the menu label
                obj.objCM.setMenuLabel(iSel(1),nwVal);
            end
            
            % updates the sub-struct
            setObjEnable(obj.hButC{1},1)
            obj.setDataSubStruct(pInfo);
            
            % updates the region information table (1D only)
            if hObj.UserData == 1
                obj.updateRegionInfoTable()
            end
            
        end      
        
        % --- group name table cell select callback function
        function tableGroupSelect(obj, ~, evnt)
            
            % exits if there are no indices
            if isempty(evnt.Indices)
                return
            end            
            
            % updates the popup menu
            iRow = evnt.Indices(1);
            iTab = obj.hTabGrp.SelectedTab.UserData;
            obj.objT{iTab}.hPopupR.Value = iRow + 1;            
            
        end
        
        % --- region grouping radio button selection callback function
        function radioRegionChange(obj, hObj, evnt)
            
            % initialisations
            eStr = '';
            pInfo = obj.getDataSubStruct(true);
            hRadio = hObj.SelectedObject;
            
            % updates the selected grouping type
            pInfo.gType = hRadio.UserData;
            obj.setDataSubStruct(pInfo,true);
            
            % updates the group panel properties
            obj.updateGroupPanelProps();
            
            % updates the configuration axes (if not running function directly)
            if ~ischar(evnt)
                % updates the grid patterns (if grid grouping selected)
                if hRadio.UserData == 1
                    % initialisations
                    if pInfo.nGrp == 1
                        [nRG,nCG] = deal(1);
                    else
                        % retrieves the column/row grid counts
                        hEditC = findall(hObj,'UserData','nColG');
                        hEditR = findall(hObj,'UserData','nRowG');
                        
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
                            eStr0 = ['The following grid group counts ',...
                                'are infeasible and will be reset to 1:'];
                            eStrF = sprintf('%s\n%s',eStr0,eStr);
                            
                            % outputs the message to screen
                            tStr = 'Infeasible Grid Dimensions';
                            waitfor(msgbox(eStrF,tStr,'modal'))
                        end
                        
                        % updates the editbox with the parameter values
                        [nRG,nCG] = deal(pInfo.nRowG,pInfo.nColG);
                        hEditC.String = num2str(nCG);
                        hEditR.String = num2str(nRG);                                                
                    end
                    
                    % sets the grid row/column indices
                    [dx,dy] = deal(pInfo.nCol/nCG,pInfo.nRow/nRG);
                    iR = arrayfun(@(x)((x-1)*dy+(1:dy)),1:nRG,'un',0);
                    iC = arrayfun(@(x)((x-1)*dx+(1:dx)),1:nCG,'un',0);
                    
                    % resets the group indices (based on the majority group 
                    % index within each grid region)
                    for i = 1:nRG
                        for j = 1:nCG
                            iGrpG = arr2vec(pInfo.iGrp(iR{i},iC{j}));
                            if all(iGrpG == 0)
                                pInfo.iGrp(iR{i},iC{j}) = 0;
                            else
                                iGrpM = mode(iGrpG(iGrpG > 0));
                                pInfo.iGrp(iR{i},iC{j}) = iGrpM;
                            end
                        end
                    end
                    
                    % updates the data sub-struct
                    setObjEnable(obj.hButC{1},1)
                    obj.setDataSubStruct(pInfo)
                end
                
                % updates the configuration axes
                obj.objD.resetConfigAxes()
            end
            
        end
        
        % ------------------------------------ %
        % --- MENU ITEM PROPERTY FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- sets the menu enabled properties
        function setMenuEnable(obj,tStr,eState)
            
            setObjEnable(obj.getMenuItem(tStr),eState);
            
        end
         
        % --- sets the menu checked state
        function setMenuCheck(obj,tStr,cState)
            
            setMenuCheck(obj.getMenuItem(tStr),cState);            
            
        end
        
        % --- retrieves the menu item with the tag string, tStr
        function hMenu = getMenuItem(obj,tStr)
            
            hMenu = findall(obj.hFig,'tag',tStr);
            
        end        
        
        % --- updates the menu item properties
        function updateMenuItemProps(obj)
            
            % determines if the sub-region data struct is set
            isSet = obj.iMov.isSet;
            canSet = strcmp(obj.hButC{1}.Enable,'on');
            isFeas = obj.iData.is2D || obj.isMTrk;
            hasSR = isfield(obj.iMov,'srData') && ...
                    ~isempty(obj.iMov.srData);            

            % sets the main menu item enabled properties
            obj.setMenuEnable('hMenuSaveConfig',canSet);
            obj.setMenuEnable('hMenuAutoDetect',isSet);
            obj.setMenuEnable('hMenuShowRegions',isSet);
            obj.setMenuEnable('hMenuRegionSplit',isSet && isFeas);
            obj.setMenuEnable('hMenuConfigSetup',isSet && isFeas);
            obj.setMenuEnable('hMenuUseSplit',isSet && hasSR && isFeas);
            
            % if the regions are not set, then exit
            if ~isSet; return; end            
            
            % updates the other menu item objects
            obj.setMenuEnable('hMenuAutoDetect1D',~isFeas);
            obj.setMenuEnable('hMenuAutoDetect2D',isFeas);            
            
            % updates the automatic detection menu items
            if obj.iData.is2D
                obj.updateAutoMenuItemProps2D();
            end
            
        end

        % --- updates the 2D auto-detection menu items
        function updateAutoMenuItemProps2D(obj)
            
            % initialisations
            [useCirc,useRect,useGen,useGenCust] = deal(true);
            
            switch obj.iMov.mShape
                case {'Circ','Circle'}
                    % case is circular regions
                    [useRect,useGenCust] = deal(false);

                case {'Rect','Rectangle'}
                    % case is rectangular regions
                    [useCirc,useGenCust] = deal(false);

                otherwise
                    % case is other regions
                    [useCirc,useRect] = deal(false);
            end
            
            % updates the menu item enabled properties            
            obj.setMenuEnable('hMenuDetectCirc',useCirc)
            obj.setMenuEnable('hMenuDetectRect',useRect)
            obj.setMenuEnable('hMenuDetectGen',useGen)
            obj.setMenuEnable('hMenuDetectGenCust',useGenCust)
            
        end        
        
        % --------------------------------- %        
        % --- OBJECT PROPERTY FUNCTIONS --- %
        % --------------------------------- %
        
        % --- updates the group table column format
        function updateRegionInfoTable(obj)
            
            % updates the group arrays (to account for row/column counts)
            [pInfo,isDiff] = obj.updateGroupArrays();
            [nRow,nCol] = deal(pInfo.nRow,pInfo.nCol);
            [nFly,iGrp] = deal(pInfo.nFly,pInfo.iGrp);
            [xiC,xiR] = deal(1:nCol,1:nRow);            
            
            % updates the data sub-struct (if there is a difference)
            if isDiff
                obj.setDataSubStruct(pInfo,false); 
            end
            
            % sets the table column values
            iCol = repmat(xiC(:),nRow,1);
            iRow = cell2mat(arrayfun(@(x)(x*ones(nCol,1)),xiR(:),'un',0));
            [iFly,iGrpT] = deal(arr2vec(nFly'),arr2vec(iGrp'));

            % sets the column format names
            iFly(isnan(iFly)) = 0;
            cForm = {'char','char','char',[{' '};pInfo.gName(:)]'};

            % sets the final table array
            DataT = [num2cell([iRow,iCol,iFly]),cForm{end}(1+iGrpT)'];            
            set(obj.objT{1}.hTableR,'ColumnFormat',cForm,'Data',DataT);
            
        end
        
        % --- updates the group name table
        function updateGroupNameTable(obj)
                        
            % initialisations
            pInfo = obj.getDataSubStruct();            
            hTableN = obj.objT{1+obj.iData.is2D}.hTableN;
            
            % disable the menu highlight (2D only)
            obj.objCM.setMenuHighlight(obj.objCM.iSel,0);
            
            % adds/removes from the group name array
            nGrp0 = length(pInfo.gName);
            if pInfo.nGrp > nGrp0
                % case is group names are being added to the list
                iGrpNw = (nGrp0+1):pInfo.nGrp;
                gNameNw = arrayfun(@(x)(...
                    sprintf('Group #%i',x)),iGrpNw(:),'un',0);
                pInfo.gName = [pInfo.gName;gNameNw(:)];

            else
                % otherwise, remove the names from the list
                pInfo.gName = pInfo.gName(1:pInfo.nGrp);
                pInfo.iGrp(pInfo.iGrp > pInfo.nGrp) = 0;
            end
            
            % updates the parameter information
            obj.setDataSubStruct(pInfo);
                
            % resets the popup strings/selection index
            pStr = [{'(None)'};pInfo.gName(:)];
            hPopupR = obj.objT{1+obj.iData.is2D}.hPopupR;
            iSel = min(length(pStr),hPopupR.Value);
            
            % updates the data sub-struct
            obj.setDataSubStruct(obj.updateGroupArrays());
            
            % updates the popup string/value
            set(hPopupR,'String',pStr,'Value',iSel)
            
            % creates the context menu
            obj.objCM.updateMenuLabels(pStr);
            
            % updates the region table information
            if ~obj.iData.is2D
                obj.updateRegionInfoTable()
            end
            
            % updates the table data/background colours
            tCol = getAllGroupColours(length(pInfo.gName),1);
            set(hTableN,'Data',pInfo.gName,'BackgroundColor',tCol);
            
        end
        
        % --- updates the group selection 
        function updateGroupSelection(obj,varargin)
            
            % field retrieval
            mP0 = obj.objCM.mP0;            
            pInfo = obj.getDataSubStruct();
            sz = size(pInfo.iGrp);
            
            % resets the region to the selected value
            if obj.isMTrk
                % case is multi-tracking
                
                % updates the group index
                pInfo.iGrp(mP0(2),mP0(1)) = obj.objCM.iSel - 1;
                
                % updates the group name table 
                iRow = sub2ind(flip(sz),mP0(1),mP0(2));
                obj.resetRegionTableGroup(iRow,obj.objCM.iSel);
            
            elseif ~obj.iData.is2D
                % case is 1D single-tracking
                
                % retrieves the selected region indices
                iSelM = obj.objCM.iSel;
                indR = obj.objD.getRegionIndices1D(mP0);
                
                % updates the group index/mapping indices
                if length(indR) == 2
                    % case is using full region selection
                    pInfo.iGrp(indR(1),indR(2)) = iSelM - 1;
                    pInfo.gID{indR(1),indR(2)}(:) = iSelM - 1;
                
                    % updates the region table group information
                    iRow = sub2ind(flip(sz),indR(2),indR(1));
                    obj.resetRegionTableGroup(iRow,iSelM);
                    
                else
                    % case is using sub-region selection
                    pInfo.gID{indR(1),indR(2)}(indR(3)) = iSelM - 1;
                    
                    % updates the region group name table
                    pInfo = obj.resetSubRegionTableGroup(pInfo,indR,iSelM);
                end
                    
            elseif obj.objT{2}.hRadioR{1}.Value
                % case is grid grouping (2D expt setup)
                
                % determines the x/y increments
                dx = pInfo.nCol/pInfo.nColG;
                dy = pInfo.nRow/pInfo.nRowG;
                
                % sets the row/column indices (for the selected group)
                iC = max(0,floor((mP0(1)-1)/dx)*dx) + (1:dx);
                iR = max(0,floor((mP0(2)-1)/dy)*dy) + (1:dy);
                pInfo.iGrp(iR,iC) = obj.objCM.iSel - 1;
                                
            else
                % case is custom grouping (2D expt setup)
                iSel0 = pInfo.iGrp(mP0(2),mP0(1));
                CC = bwconncomp(pInfo.iGrp==iSel0,4);                
                
                % resets the grouping indices
                idx0 = sub2ind(sz,mP0(2),mP0(1));
                isM = cellfun(@(x)(any(x==idx0)),CC.PixelIdxList);
                pInfo.iGrp(CC.PixelIdxList{isM}) = obj.objCM.iSel - 1;
            end            
            
            % removes the menu highlight/checkmarks
            obj.objCM.setMenuHighlight(obj.objCM.iSel,0);
            obj.objCM.updateMenuCheck(0)
            
            % updates the data struct and resets the configuration axes
            obj.setDataSubStruct(pInfo)
            obj.objD.resetConfigAxes(false)
            
            % resets the open menu flag
            obj.isMenuOpen = false;
            
        end
        
        % --- updates the group panel properties
        function updateGroupPanelProps(obj)
            
            % retrieves the 2D setup data sub-struct
            pInfo = obj.getDataSubStruct(true);
            multiGrp = (pInfo.nRow*pInfo.nCol) > 1;
            
            % sets the sub-panel enabled flags
            useCG = (pInfo.gType==2) && multiGrp;
            useGG = (pInfo.gType==1) && (pInfo.nGrp>1) && multiGrp;
            
            % updates the grid grouping panel object's enabled properties
            setPanelProps(obj.objT{2}.hPanelR,'on')
            setPanelProps(obj.objT{2}.hPanelRI{1},useGG);
            setPanelProps(obj.objT{2}.hPanelRI{2},useCG);
            
            % updates the row/grid objects (if grid grouping is chosen & multi-group)
            if useGG
                setObjEnable(obj.objT{2}.hEditR{1},pInfo.nRow>1)
                setObjEnable(obj.objT{2}.hEditR{2},pInfo.nCol>1)
            end
            
        end
        
        % --- sets button properties based on current selections
        function setContButtonProps(obj)
            
            % initialisations
            pInfo = obj.getDataSubStruct();
            
            % retrieves the field values
            [iGrp,nGrp] = deal(pInfo.iGrp,pInfo.nGrp);
            
            % ensures that names have been set for at least one region
            if obj.isMTrk || obj.iData.is2D || ~pInfo.isFixed           
                % case is multi-tracking, 2D setup or fixed region 1D setup
                grpNameSet = all(arrayfun(@(x)(any(iGrp(:)==x)),1:nGrp));
                grpSet = pInfo.iGrp > 0;

            else
                % case is sub-region enabled 1D expt setup
                gIDT = cell2mat(pInfo.gID(:));
                grpNameSet = all(arrayfun(@(x)(any(gIDT==x)),1:nGrp));
                grpSet = cellfun(@(x)(any(x > 0)),pInfo.gID);                
            end
                
            % updates the enabled properties of the control buttons
            regionSet = all(any(grpSet,1)) && all(any(grpSet,2));            
            canSet = grpNameSet && regionSet;
            setObjEnable(obj.hButC{1},canSet)            
            obj.setMenuEnable('hMenuSaveConfig',canSet);            
            
        end
        
        % --- post file load object property update
        function postFileLoadPropUpdate(obj)
            
            % resets the region tab object
            iTab = 1 + obj.iData.is2D;            
            set(obj.hTabGrp,'SelectedTab',obj.objT{iTab}.hTab)                       
            
            % deletes the configuration regions
            if obj.iMov.isSet
                obj.objRC.deleteRegionConfig();
                obj.iMov.isSet = false;
            end            
            
            % resets the automatic detection parameter struct
            aP = pos2para(obj.iMov);
            [obj.iMov.autoP,obj.objRC.iMov.autoP] = deal(aP);            
            
            % resets the data struct and class objects
            obj.initClassProps(false);            
            
        end                
        
        % ----------------------------- %
        % --- DATA STRUCT FUNCTIONS --- %
        % ----------------------------- %
        
        % --- initialises the data struct
        function iData = initDataStruct(obj)
            
            % parameters
            nFlyMx = 10;
            szDim = {1,1,1,'Circle'};
                        
            % initialises the common data struct
            A = struct('nRow',1,'nCol',1,'nGrp',1,'iGrp',1,...
                       'gName',[],'isFixed',false);
            A.gName = {'Group #1'};
            
            % sets the setup dependent sub-fields
            B = setStructField(A,{'nFlyMx','nFly'},{nFlyMx,nFlyMx});
            C = setStructField(A,{'nRowG','nColG','gType','mShape'},szDim);
            C.pPos = [];
            
            % sets the extra fields (depending on tracking type)
            if obj.isMTrk
                % case is for multi-tracking
                [B.mShape,B.pPos] = deal('Circle',[]);
                
            else
                % case is for 1D single tracking
                B.gID = {ones(nFlyMx,1)};
            end
            
            % data struct initialisations
            iData = struct('D1',B,'D2',C,'is2D',false,'isFixed',false);
            
        end        
        
        % --- converts sub-region data struct to full data struct format
        function iData = convertDataStruct(obj)
            
            % data struct initialisations
            [D1,D2] = getRegionDataStructs(obj.iMov);            
            
            % resets the arrays
            if obj.isMTrk
                % case is multi-tracking
                [D1,D2] = deal(D2,[]);
                
            elseif isempty(D1) || isempty(D2)
                % if a field is missing, then set with the default
                iDataTmp = obj.initDataStruct();
                if isempty(D1)
                    % case is the 1D expt data struct is missing
                    D1 = iDataTmp.D1;
                    
                else
                    % case is the 2D expt data struct is missing
                    D2 = iDataTmp.D2;
                end
            end
            
            % sets the final data struct
            is2D = obj.iMov.is2D;
            iData = struct('D1',D1,'D2',D2,'is2D',is2D,'isFixed',1);
            
        end                
        
        % --- initialises the sub-region data struct
        function iMovNw = initSubPlotStruct(obj,iMovNw)

            % sets the 2D flag and sub-region info fields
            iMovNw.pInfo = obj.getDataSubStruct();
            iMovNw.is2D = obj.iData.is2D;

            % retrieves the axis limits
            [xL,yL] = deal(get(obj.hAxM,'xlim'),get(obj.hAxM,'ylim'));
            
            % sets the subplot variables (based on the inputs)
            [pG,del] = deal(iMovNw.posG,5);
            if obj.iData.is2D || obj.isMTrk
                [nRow,nCol] = deal(1,size(iMovNw.pInfo.iGrp,2));
            else
                [nRow,nCol] = deal(iMovNw.pInfo.nRow,iMovNw.pInfo.nCol);
            end

            % sets the overall dimensions of the outer regions
            [iMovNw.nRow,iMovNw.nCol] = deal(nRow,nCol);
            [L,B,W,H] = deal(pG(1),pG(2),pG(3)/nCol,pG(4)/nRow);

            % if multi-tracking, set the sub-region count to one/region
            if detMltTrkStatus(iMovNw)
                [iMovNw.nTube,iMovNw.nTubeR] = deal(1,ones(nRow,nCol));
            end

            % sets the window label font sizes and linewidths
            fSize = 20 + 6*(~ispc);

            % for each row/column initialise the subplot structs
            [iMovNw.posO,iMovNw.pos] = deal(cell(1,nRow*nCol));
            for i = 1:nRow
                for j = 1:nCol
                    % sets the parameter struct index/position
                    k = (i-1)*nCol + j;
                    iMovNw.posO{k} = [(L+(j-1)*W) (B+(i-1)*H) W H];

                    % creates the text markers (1D setup only)
                    if ~obj.iData.is2D
                        % creates the dummy text marker
                        hText = text(0,0,num2str(k),'parent',obj.hAxM,...
                            'tag','hNum','fontsize',fSize,'color','r',...
                            'fontweight','bold');   

                        % repositions the dummy text marker
                        hEx = get(hText,'Extent');  
                        pPosTxt = [L+(j-0.5)*W-(hEx(3)/2) B+(i-0.5)*H 0];
                        set(hText,'position',pPosTxt)
                    end

                    % sets the left/right locations of the sub-window
                    PosNw(1) = min(xL(2),max(xL(1),L+((j-1)*W+del)));
                    PosNw(2) = min(yL(2),max(yL(1),B+((i-1)*H+del)));                                               
                    PosNw(3) = (W-2*del) + min(0,xL(2)-(PosNw(1)+(W-2*del)));
                    PosNw(4) = (H-2*del) + min(0,yL(2)-(PosNw(2)+(H-2*del)));      

                    % updates the sub-image position vectos
                    iMovNw.pos{k} = PosNw;        
                end
            end

            % sets up the sub-region acceptance flags
            if iMovNw.is2D || obj.isMTrk
                % case is a 2D expt setup

                % parameters
                dGrp0 = 5;
                nRow = iMovNw.pInfo.nRow;

                % sets up the acceptance flag array    
                iMovNw.flyok = iMovNw.pInfo.iGrp > 0;
                iMovNw.autoP.pPos = cell(size(iMovNw.flyok));

                % sets up the position vector for each sub-region
                for j = 1:size(iMovNw.flyok,2)
                    % retrieves the region dimensions
                    dGrp = dGrp0;
                    [L0,B0] = deal(iMovNw.pos{j}(1),iMovNw.pos{j}(2));
                    [W0,H0] = deal(iMovNw.pos{j}(3),iMovNw.pos{j}(4));

                    % sets the offset dimensions 
                    [L,B,W] = deal(L0+dGrp/2,B0+dGrp/2,W0-dGrp);
                    H = (H0 - nRow*dGrp)/nRow;        

                    % if using circle regions, ensure widths/heights match
                    if startsWith(iMovNw.autoP.Type,'Circ')
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
                        iMovNw.autoP.pPos{i,j} = [L,y0,W,H];
                    end
                end

            else
                % case is a 1D expt setup

                % determines the number of flies in each region grouping
                nFlyT = arr2vec(iMovNw.pInfo.nFly')';
                if iMovNw.pInfo.isFixed
                    % case is sub-region setting is enabled
                    
                    % determines which sub-regions has a grouping set
                    hasG = cellfun(@(x)...
                        (x>0),arr2vec(iMovNw.pInfo.gID')','un',0);

                    % set up the acceptance flag array
                    dnFly = max(nFlyT) - nFlyT;                    
                    flyok = cellfun(@(x,n)...
                        ([x;false(n,1)]),hasG,num2cell(dnFly),'un',0);
                    
                else
                    % case is fixed sub-regions only
                    
                    % determines the fly count 
                    iGrp = arr2vec(iMovNw.pInfo.iGrp')';
                    nFly = (iGrp>0).*nFlyT;
                    
                    % sets up the acceptance flag array
                    szF = [max(nFly),1];
                    flyok = arrayfun(@(x)(setGroup(1:x,szF)),nFly,'un',0);
                end                                        

                % sets up the acceptance flag array
                iMovNw.flyok = cell2mat(flyok);
            end

            % sets the region acceptance flags
            iMovNw.ok = any(iMovNw.flyok,1);
            iMovNw.pInfo.pPos = iMovNw.autoP.pPos;
            
        end
        
        % --- retrieves the data sub struct (dependent on the setup type)
        function [pInfo,is2D] = getDataSubStruct(obj,is2D)
            
            % sets the 2d flag (if not already given)
            if ~exist('is2D','var')
                is2D = obj.iData.is2D;
            end
            
            % retrieves sub-struct (depending on setup dimensionality)
            pInfo = obj.iData.(sprintf('D%i',1+is2D));
            
        end        
        
        % --- updates the data sub struct (dependent on the setup type)
        function setDataSubStruct(obj,pInfo,is2D)
            
            % updates the sub-struct (depending on setup dimensionality)
            if exist('is2D','var')
                obj.iData.(sprintf('D%i',1+is2D)) = pInfo;
            else
                obj.iData.(sprintf('D%i',1+obj.iData.is2D)) = pInfo;
            end
            
        end

        % -------------------------------- %        
        % --- AUTO DETECTION FUNCTIONS --- %
        % -------------------------------- %        
        
        % --- initialises the automatic detection algorithm values
        function [iMovAD,I] = initAutoDetect(obj)
            
            % initialisations
            iMovTmp = obj.iMov;

            % retrieves the main image axes image
            hImageM = findobj(get(obj.hAxM,'children'),'type','image');
            I = get(hImageM,'cdata');

            % determines if the sub-region data struct has been set
            if isempty(iMovTmp.iR)
                % if the sub-regions not set, then determine them 
                % from the main axes
                if ~obj.buttonUpdateChanges(obj.hButC{1},'1')
                    [iMovAD,I] = deal([]);
                    return            
                end

                % retrieves and reset the sub-region data struct
                [iMovAD,obj.iMov] = deal(obj.iMov,iMovTmp);

            else
                % otherwise set the original to be the test data struct
                iMovAD = iMovTmp;
            end

            % retrieves the region information parameter struct
            iMovAD.pInfo = obj.getDataSubStruct();
            iMovAD.autoP = pos2para(iMovAD,iMovTmp.autoP.pPos);

            % makes the GUI invisible (for the duration of the calculations)
            setObjVisibility(obj.hFig,'off'); pause(0.05)

            % removes any previous markers from the main GUI axes
            obj.objRC.deleteRegionConfig();            
            
        end        
        
        % --- retrieves the region estimate image stack
        function I = getRegionEstImageStack(obj,iMovNw)
            
            % memory allocation
            I = cell(obj.nFrmEst,1);
            
            % retrieves the initial image stack
            if obj.isCalib
                % creates a waitbar figure
                wStr = {'Capturing Test Image Frames'};
                hProg = ProgBar(wStr,'Test Image Capture');

                % case is the user is calibrating the camera
                infoObj = obj.hFigM.infoObj; 
                for i = 1:obj.nFrmEst
                    % updates the progressbar
                    wStrNw = sprintf('%s (%i of %i)',wStr{1},i,obj.nFrmEst);
                    if hProg.Update(1,wStrNw,i/(obj.nFrmEst+1))
                        % if the user cancelled, then exit
                        I = [];
                        return
                    end
                    
                    % reads in the next frame (pausing for a little bit)
                    I{i} = double(getsnapshot(infoObj.objIMAQ));
                    pause(obj.tPause);
                end
                
                % updates and closes the progressbar
                hProg.Update(1,'Test Image Capture Complete',1);                
                hProg.closeProgBar;
                
            else
                % case is the tracking from a video
                
                % reads in the image stack from file
                xi = roundP(linspace(1,obj.iDataM.nFrm,obj.nFrmEst));
                for i = 1:length(xi)
                    Inw = getDispImage(obj.iDataM,iMovNw,xi(i),0,obj.hGUI);
                    I{i} = double(Inw);
                end
            end
            
        end
        
        % --- updates the figure/axis properties after automatic detection
        function postAutoDetectUpdate(obj,iMov0,iMovNw,isUpdate)
                                    
            % sets the input arguments
            if ~exist('isUpdate','var'); isUpdate = ~isempty(iMovNw); end
            
            % determines if the user decided to update or not
            if isUpdate
                % sets the region position vectors (2D expts only)
                if iMovNw.is2D
                    iMovNw.autoP.pPos = para2pos(iMovNw.autoP);
                end
                
                % flag a change has been made and updates the data struct
                [obj.isChange,obj.iMov] = deal(true,iMovNw);                                
                
                % shows the regions on the main GUI
                obj.resetRegionShape(iMovNw);
                obj.objRC.setupRegionConfig(iMovNw,true);
                
                % sets the menu item/update button properties
                obj.setMenuEnable('hMenuShowRegions',1);
                obj.setMenuCheck('hMenuShowRegions',1);                
                setObjEnable(obj.hButC{1},1)
                
            else
                % updates the menu properties
                canSR = obj.iMov.isSet && iMov0.is2D;
                obj.setMenuEnable('hMenuRegionSplit',canSR)
                obj.setMenuEnable('hMenuShowRegions',0);
                obj.setMenuCheck('hMenuShowRegions',1);
                
                % shows the tube regions
                hMenuSR = obj.getMenuItem('hMenuShowRegions');
                set(hMenuSR,'Checked','on','Enable','off');
                obj.menuShowRegions(hMenuSR,[]);
                
                % resets the sub-regions on the main GUI axes
                obj.objRC.setupRegionConfig(iMov0,true);
            end
            
            % makes the gui window visible again
            setObjVisibility(obj.hFig,'on'); pause(0.05)
            figure(obj.hFig)
            
        end        

        % --------------------------------------------- %        
        % --- DATA STRUCT BACK-FORMATTING FUNCTIONS --- %
        % --------------------------------------------- %
        
        % --- back-formats the 2D format data struct
        function backFormatDataStruct(obj,is2D)
            
            if is2D
                % case is a 2D single-tracking setup                
                
                % checks 2D regional information field is set properly
                if ~isempty(obj.iMov.autoP.X0)
                    [obj.iMov.autoP,obj.updateReqd] = ...
                        backFormatRegionParaStruct(obj.iMov.autoP);
                    
                    % circular region check
                    if startsWith(obj.iMov.autoP.Type,'Circ')
                        % resets outer region position array (if incorrect)
                        if obj.iMov.posO{1}(1) ~= obj.iMov.posG(1)
                            % field retrieval and precalculations
                            obj.iMov.posO = obj.iMov.pos;
                            wPosG = sum(obj.iMov.posG([1,3]));                                                        
                            
                            % resets the outer position vectors
                            obj.iMov.posO{1}(1) = obj.iMov.posG(1);                            
                            obj.iMov.posO{end}(3) = ...
                                wPosG - obj.iMov.posO{end}(1);                            
                        end
                    end
                end
                
                % ensures the shape field is set
                if ~isfield(obj.iMov,'mShape')
                    % determines if the shape field is set
                    if isfield(obj.iData.D2,'mShape')
                        % if the field exists, then use the field value
                        obj.iMov.mShape = obj.iData.D2.mShape;
                        
                    else
                        % determines if the auto-detection field is set
                        if isfield(obj.iMov,'autoP') && ...
                                ~isempty(obj.iMov.autoP)
                            % if so, then use the shape field
                            obj.iMov.mShape = obj.iMov.autoP.Type;
                            
                        else
                            % otherwise, set the default field
                            obj.iMov.mShape = 'Circle';
                        end
                        
                        % ensures the region information field is set
                        obj.iData.D2.mShape = obj.iMov.mShape;
                    end
                end
                
            else
                % case is a 1D single-tracking setup
                
                % checks the 1D region info fields are set properly
                if ~isfield(obj.iData.D1,'isFixed')
                    obj.iData.D1.isFixed = false;
                    obj.updateReqd = true;
                end

                % ensures the group ID fields have been set
                if ~isfield(obj.iData.D1,'gID')
                    obj.iData.D1.gID = setup1DGroupFlags(obj.iMov);
                    obj.updateReqd = true;                        
                end            
            end            
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- sets the region table group field
        function resetRegionTableGroup(obj,iRow,iSel)

            hTableR = obj.objT{1}.hTableR;
            cForm = hTableR.ColumnFormat{end};
            hTableR.Data(iRow,end) = cForm(iSel);

        end        
        
        % --- resets the sub-region region table group field
        function pInfo = resetSubRegionTableGroup(obj,pInfo,indR,iSel)
            
            % determines the region information table row index
            szG = flip(size(pInfo.iGrp));
            iRow = sub2ind(szG,indR(2),indR(1));
            
            if all(pInfo.gID{indR(1),indR(2)} == (iSel-1))
                % case is all the region has the same value
                pInfo.iGrp(indR(1),indR(2)) = iSel-1;
                obj.resetRegionTableGroup(iRow,iSel);
                
            else
                % case is there are multiple values for the region
                pInfo.iGrp(indR(1),indR(2)) = 0;
                obj.resetRegionTableGroup(iRow,1);
            end
            
            % updates the data struct (if not outputting)
            if nargout == 0
                obj.setDataSubStruct(pInfo);
            end
            
        end
        
        % --- resets the 1D region group ID flags
        function pInfo1D = resetRegionGroupID(obj,pInfo1D)
            
            % field retrieval
            if ~exist('pInfo1D','var')
                pInfo1D = obj.getDataSubStruct(false);
            end
            
            % field retrieval
            gID = pInfo1D.gID;
            nFly = pInfo1D.nFly;
            
            % ensures mapping array dimensions matches region dimensions
            szID = size(pInfo1D.gID);            
            if ~isequal(szID,[pInfo1D.nRow,pInfo1D.nCol])
                % if not, then expand/reduce the mapping array to match                                
                
                % row dimension check
                if szID(1) < pInfo1D.nRow
                    % expand if smaller than required
                    iR = (szID(1)+1):pInfo1D.nRow;
                    Iadd = arrayfun(@(n)(zeros(n,1)),nFly(iR,:),'un',0);
                    gID = [gID;Iadd];
                    
                elseif szID(1) > pInfo1D.nRow
                    % reduce if bigger than required
                    gID = gID(1:pInfo1D.nRow,:);
                end
                   
                % row dimension check
                if szID(2) < pInfo1D.nCol
                    % expand if smaller than required
                    iC = (szID(2)+1):pInfo1D.nCol;
                    Iadd = arrayfun(@(n)(zeros(n,1)),nFly(:,iC),'un',0);
                    gID = [gID,Iadd];
                    
                elseif szID(2) > pInfo1D.nCol
                    % reduce if bigger than required
                    gID = gID(:,1:pInfo1D.nCol);
                end                
                    
            end
                            
            % ensures the fly counts and group indices are feasible
            nFlyID = cellfun('length',gID);            
            for i = 1:pInfo1D.nRow
                for j = 1:pInfo1D.nCol
                    % resets any infeasible group indices
                    ii = gID{i,j} > pInfo1D.nGrp;
                    gID{i,j}(ii) = 0;
                    
                    % ensures the fly count is correct
                    if nFly(i,j) < nFlyID(i,j)
                        % case is fly count is greater than required
                        gID{i,j} = gID{i,j}(1:nFly(i,j));
                        
                    elseif nFly(i,j) > nFlyID(i,j)
                        % case is fly count is less than required
                        
                        % sets the group index
                        if pInfo1D.isFixed
                            % case is using sub-grouping
                            pGrp = 0;
                            
                        else
                            % case is fixed grouping
                            pGrp = pInfo1D.iGrp(i,j);
                        end
                        
                        % appends the 
                        dnFly = nFly(i,j) - nFlyID(i,j);
                        gID{i,j} = [gID{i,j};pGrp*ones(dnFly,1)];
                    end
                end
            end
            
            % resets the mapping index array field
            pInfo1D.gID = gID;
            
            % updates the data struct (if not outputting)
            if nargout == 0
                obj.setDataSubStruct(pInfo1D,false);
            end
            
        end
        
        % --- calculates the coordinates of the axes with respect to the 
        %     global coordinate position system
        function calcAxesGlobalCoords(obj)
            
            % global variables
            global axPosX axPosY
            
            % retrieves the position vectors for each associated panel/axes
            pPosAx = get(obj.hPanelAx,'Position');
            axPos = get(obj.hAx,'Position');
            
            % calculates the global x/y coordinates of the
            axPosX = (pPosAx(1)+axPos(1)) + [0,axPos(3)];
            axPosY = (pPosAx(2)+axPos(2)) + [0,axPos(4)];
            
        end                
        
        % --- fixes the region shape popup item
        function resetRegionShape(obj,iMovNw)
            
            % sets the region shape strings
            switch iMovNw.autoP.Type
                case {'Circle','Rectangle'}
                    % case is a circle or rectangle
                    mShape = iMovNw.autoP.Type;
                    
                otherwise
                    % case is a general polygon
                    mShape = 'Polygon';
            end
            
            % updates the 
            iSelS = find(strcmp(obj.ppStr,mShape));
            obj.objT{1+obj.iData.is2D}.hPopupC.Value = iSelS;
            
        end
        
        % --- updates the group arrays
        function [pInfo,isDiff] = updateGroupArrays(obj)
            
            % retrieves the data sub-struct
            [pInfo,is2D] = obj.getDataSubStruct();
            
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
            
        end
        
        % --- sets up the region configuration directory path
        function setupConfigDirPath(obj)
        
            % initialisations
            fFldC = 'ConfigFile';      
            tStrD = '2 - Region Configuration';
            
            % determines if config file field exists in program defaults
            if isfield(obj.hFigM.ppDef,fFldC)
                % if so, then retrieve the field
                obj.cFigDir = obj.hFigM.ppDef.(fFldC);
                
            else
                % otherwise, add the field to the file
                
                % file/directory path retrieval
                pFile = getParaFileName('ProgDef.mat');
                fDir = getProgFileName('Data','Tracking',tStrD);
                
                % if the directory doesn't exist, then make it
                if ~exist(fDir,'dir')
                    mkdir(fDir);
                end
                
                % loads the program default file
                A = load(pFile);
                ProgDef = A.ProgDef;
                
                % appends missing fields to the default directory struct
                ProgDef.Tracking.(fFldC) = fDir;
                ProgDef.Tracking.fldData.(fFldC) = {'Tracking',tStrD};
                
                % updates the program defaults
                obj.hFigM.ppDef = ProgDef.Tracking;
                
                % updates the program default file
                save(pFile,'ProgDef');
            end
            
            
        end

        % --- determines if a 2D setup has multiple regions
        function isMultiReg = multiRegionCheck(obj)
            
            isMultiReg = obj.iMov.pInfo.nRow*obj.iMov.pInfo.nCol > 1;            
            
        end
        
    end
    
end