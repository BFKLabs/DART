classdef SaveExptFiles < handle
    
    % class properties
    properties
        
        % input arguments
        hFigM
        hGUIInfo        
        
        % sub-class fields
        objSF                    % experimental solution file save class
        
        % main data class fields
        fDir
        fDir0
        fDirFix        
        fName
        fDirRoot
        fExtn
        sInfo   
        oPara
        iParaOut
        iProg   
        gName
        nExp    
        Tmax
        
        % main class objects
        hFig
        hPanelLo
        hPanelHi
        
        % output option panel objects
        hPanelO
        hRadioO
        hEditO
        hButO
        
        % output explorer tree panel objects
        hPanelOS
        hTreeOS
        
        % file chooser panel objects 
        hPanelF
        jChooseF
        
        % control button panel objects
        hPanelC
        hButC
        
        % experiment/group name table panel objects
        hPanelT
        hTableTN
        jTableTN
        hTableTG
        jTableTG
        
        % output parameter panel objects
        hPanelP
        hChkP
        hTxtP
        hEditP
        
        % fixed dimension fields
        dX = 10;        
        hghtBut = 25;
        hghtRow = 25;
        hghtHdr = 20;
        hghtTxt = 16;
        hghtChk = 20;
        hghtEdit = 23;
        hghtRadio = 20;
        hghtPanelLo = 410;
        widPanel = 820;
        widPanelT = 575;
        widPanelO = 370;
        widTableTN = 320;
        widLblP = 130;
        
        % calculated dimension fields
        widFig
        hghtFig
        hghtPanelHi
        hghtPanelHiI
        hghtPanelO
        hghtPanelOS
        hghtPanelF
        hghtPanelC
        widPanelP
        widPanelOS  
        widPanelLoR
        hghtTableT
        widTableTG
        widChkP
        widRadioO
        widEditO
        widButC
        
        % boolean class fields
        useExp
        isFix = false;     
        isChange = false;
        isUpdating = false;

        % function handles class fields
        postSaveFcn
       
        % other important class fields
        iExp = 1;        
        
        % static class fields
        nRowT = 7
        nButC = 3;
        nRadioO = 2;
        nChkP = 5;        
        fSzH = 13;
        fSzL = 12;
        fSz = 10 + 2/3;
        grayCol = 0.81;        
        
        % static string fields
        tagStr = 'figExptSave';
        figName = 'Save Experiment Solution Data File';
        tHdrP = 'OTHER OUTPUT PARAMETERS';

        % cell array class fields
        igChk = {'outY'};        
        uD = {'outY';'outStim';'outExpt';'useComma';'solnTime'};
        fSpec = {{'DART Experiment Solution File (*.ssol)',{'ssol'}};...
                 {'Matlab Data File (*.mat)',{'mat'}};...
                 {'Text File (*.txt)',{'txt'}};...
                 {'Comma Separated Value File (*.csv)',{'csv'}}};        
        
        % java handle fields
        objStr = 'javahandle_withcallbacks.com.sun.java.swing.plaf.windows.WindowsFileChooserUI$7';             
             
    end
    
    % class methods
    methods
        
        % --- class constuctor
        function obj = SaveExptFiles(hFigM)
            
            % sets the input arguments
            obj.hFigM = hFigM;
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();            
            
            % clears the output object (if not required)
            if (nargout == 0) && ~isdeployed
                clear obj
            end            
            
        end        
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % field retrieval
            obj.iProg = getappdata(obj.hFigM,'iProg');
            obj.hGUIInfo = getappdata(obj.hFigM,'hGUIInfo');
            
            % memory allocation
            obj.hChkP = cell(obj.nChkP,1);
            obj.hRadioO = cell(obj.nRadioO,1);

            % sets up the expt data output class object
            obj.objSF = OutputExptFile(obj);
            
            % function handles
            obj.postSaveFcn = getappdata(obj.hFigM,'postSolnSaveFunc');
            
            % makes the main gui visible again
            setObjVisibility(obj.hFigM,0);
            setObjVisibility(obj.hGUIInfo.hFig,0)            
            
            % --------------------------- %            
            % --- SOLUTION FILE SETUP --- %
            % --------------------------- %
            
            % retrieves the solution data struct
            sInfo0 = getappdata(obj.hFigM,'sInfo');
            
            % reshapes the solution file information
            for i = 1:length(sInfo0)
                sInfo0{i}.snTot = ...
                    reshapeSolnStruct(sInfo0{i}.snTot,sInfo0{i}.iPara);
            end
            
            % updates the class field
            obj.sInfo = sInfo0;
            clear sInfo0
            
            % other field initialisations
            obj.nExp = length(obj.sInfo);
            obj.fExtn = repmat({'.ssol'},obj.nExp,1);
            
            % initialises the file information data field
            obj.initFileInfoData();
            obj.initExptOutputFlags();
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %
            
            % calculated dimension fields
            obj.hghtPanelHiI = 1.5*obj.dX + ...
                obj.hghtRow + obj.hghtHdr*(1 + obj.nChkP);
            obj.hghtPanelHi = obj.hghtPanelHiI + obj.dX; 
            obj.hghtPanelO = obj.hghtPanelLo - obj.dX;
            obj.hghtPanelOS = obj.hghtPanelO - (3*obj.hghtRow + obj.dX);
            
            % panel height dimension calculations
            obj.hghtPanelC = obj.dX + obj.hghtRow;
            obj.hghtPanelF = obj.hghtPanelLo - ...
                (1.5*obj.dX + obj.hghtPanelC);
            
            % panel width dimension calculations
            obj.widPanelP = obj.widPanel - (obj.widPanelT + 1.5*obj.dX);
            obj.widPanelOS = obj.widPanelO - obj.dX;
            obj.widPanelLoR = obj.widPanel - (obj.widPanelO + 1.5*obj.dX);
                        
            % calculates the figure dimensions
            obj.widFig = obj.widPanel + 2*obj.dX;
            obj.hghtFig = obj.hghtPanelLo + obj.hghtPanelHi + 3*obj.dX;
            
            % other object dimension calculations
            obj.widChkP = obj.widPanelP - 2*obj.dX;
            obj.widRadioO = obj.widPanelOS - 2*obj.dX;
            obj.widButC = (obj.widPanelLoR - obj.dX)/obj.nButC;            
            obj.widEditO = obj.widPanelO - (2.5*obj.dX + obj.hghtBut);
            obj.widTableTG = obj.widPanelT - (obj.widTableTN + 1.5*obj.dX);
            obj.hghtTableT = calcTableHeight(obj.nRowT);
            
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
                'Name',obj.figName,'Resize','on','NumberTitle','off',...
                'Visible','off','AutoResizeChildren','off',...
                'BusyAction','Cancel','GraphicsSmoothing','off',...
                'DoubleBuffer','off','Renderer','painters','CloseReq',[]);
            
            % sets up the lower panel object
            pPosLo = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelLo];
            obj.hPanelLo = createPanelObject(obj.hFig,pPosLo);
            
            % sets up the higher panel object
            yPosHi = sum(pPosLo([2,4])) + obj.dX;
            pPosHi = [obj.dX,yPosHi,obj.widPanel,obj.hghtPanelHi];
            obj.hPanelHi = createPanelObject(obj.hFig,pPosHi);
            
            % ----------------------- %
            % --- SUB-PANEL SETUP --- %
            % ----------------------- %
            
            % sets up the panel objects
            obj.setupOutputFormatPanel();
            obj.setupExplorerTreePanel();
            obj.setupControlButtonPanel();            
            obj.setupFileChooserPanel();
            obj.setupNameTablePanel();
            obj.setupOutputParameterPanel();
            
            % updates the object properties
            obj.updateObjectProps();
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %                         
            
            % opens the class figure
            openClassFigure(obj.hFig);
            
        end
        
        % --- initialises the file information data fields
        function initFileInfoData(obj)
            
            % memory allocation
            obj.fDir = cell(length(obj.sInfo),1);            
            
            % sets the output file/group names
            for i = 1:length(obj.sInfo)
                % retrieves the solution file name
                sFile = obj.sInfo{i}.sFile;                
                
                % sets the directory string
                switch obj.sInfo{i}.iTab
                    case 1
                        % case is 
                        sDir = obj.iProg.DirSoln;
                        cDir = obj.iProg.DirComb;
                        obj.fDir{i} = strrep(sFile,sDir,cDir);
                        
                    otherwise
                        % case is 
                        obj.fDir{i} = fileparts(sFile);
                end
            end
            
            % other field retrieval
            obj.isFix = false;
            obj.fDirFix = obj.iProg.DirComb;
            obj.fDirRoot = obj.iProg.DirComb;
            obj.fName = cellfun(@(x)(x.expFile),obj.sInfo,'un',0);
            obj.gName = cellfun(@(x)(x.gName),obj.sInfo,'un',0);
            obj.fDir0 = findDirAll(obj.iProg.DirComb); 
            obj.useExp = true(length(obj.fName),1);
            
        end
        
        % --- initialises the output flag array
        function initExptOutputFlags(obj)
            
            % memory allocation
            pStr0 = struct('useComma',0,'outY',0,'outExpt',0,...
                           'outStim',0,'solnTime',0);
            obj.oPara = repmat(pStr0,obj.nExp,1);
            
            % sets the fields for each for the
            for i = 1:length(obj.sInfo)
                % ensures the data is always output for a 2D experiment
                if obj.sInfo{i}.snTot.iMov.is2D
                    obj.oPara(i).outY = true;
                end
            end
            
        end
        
        % --- initialises the file chooser object
        function initFileChooser(obj)
            
            % retrieves the current file path
            iFile = 1;
            cbFcnFC = @obj.chooserPropChange;            
            
            % updates the ui manager
            javax.swing.UIManager.put('DocumentPane.boldActiveTab',false);

            % creates the file chooser object
            [defFile,defDir] = obj.getCurrentFilePath(iFile);
            [dDir0,dFile0,~] = fileparts(defFile);            
            obj.jChooseF = setupJavaFileChooser(obj.hPanelF,...
                'fSpec',obj.fSpec,'defDir',defDir,...
                'defFile',fullfile(dDir0,dFile0),'isSave',true);            
            
            % sets the file chooser properties
            obj.jChooseF.setName(getFileName(defFile))
            obj.jChooseF.setFileSelectionMode(0)
            obj.jChooseF.PropertyChangeCallback = cbFcnFC;
            
            % attempts to retrieve the correct object for the keyboard callback func
            hFn = getFileNameObject(obj.jChooseF);
            if isa(hFn,obj.objStr)
                % if the object is feasible, set the callback function
                hFn.KeyTypedCallback = @obj.saveFileNameChng;
            end
            
            % calculates the experiment duration
            obj.Tmax = zeros(obj.nExp,1);
            for i = 1:obj.nExp
                iPara = obj.sInfo{i}.iPara;
                [~,dT,~] = calcTimeDifference(iPara.Tf,iPara.Ts);
                obj.sInfo{i}.iPara.dT = min(dT(2),12);
                obj.Tmax(i) = 24*dT(1)+dT(2);
            end
            
            % sets the tree explorer icons
            A = load('ButtonCData.mat');
            [Im,mMap] = rgb2ind(A.cDataStr.Im,256);
            [Ifolder,fMap] = rgb2ind(A.cDataStr.Ifolder,256);
            imwrite(Im,mMap,obj.getIconImagePath('File'),'gif')
            imwrite(Ifolder,fMap,obj.getIconImagePath('Folder'),'gif')
            
        end
        
        % ------------------------------------ %
        % --- PANEL OBJECT SETUP FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- sets up the output format panel objects
        function setupOutputFormatPanel(obj)
            
            % initialisations
            cbFcnB = @obj.buttonSetDir;                        
            cbFcnP = @obj.panelOutputChange;
            pTypeO = {'edit','pushbutton'};
            wObjO = [obj.widEditO,obj.hghtBut];
            pStrO = {'Output Files To Single Fixed Directory',...
                     'Customise File Output Structure'};
            
            % creates the panel object
            pPos = [obj.dX*[1,1]/2,obj.widPanelO,obj.hghtPanelO];
            obj.hPanelO = createPanelObject(...
                obj.hPanelLo,pPos,[],'pType','buttongroup');
            set(obj.hPanelO,'SelectionChangedFcn',cbFcnP);
            
            % creates the file explorer panel
            pPosOS = [obj.dX*[1,1]/2,obj.widPanelOS,obj.hghtPanelOS];
            obj.hPanelOS = createPanelObject(obj.hPanelO,pPosOS);
            
            % creates the editbox/pushbutton grouping
            yPosE = sum(pPosOS([2,4])) + obj.dX/2 + obj.hghtRow;
            hObjO = createObjectRow(obj.hPanelO,2,pTypeO,...
                wObjO,'pStr',{[],'...'},'yOfs',yPosE);
            [obj.hEditO,obj.hButO] = deal(hObjO{1},hObjO{2});
            
            % sets the object properties
            set(obj.hEditO,'Enable','Inactive');
            set(obj.hButO,'Callback',cbFcnB);
            
            % creates the radio buttons
            yPosB0 = yPosE - obj.hghtRow;
            for i = 1:obj.nRadioO
                j = obj.nRadioO - (i-1);
                yPosB = yPosB0 + 2*(j-1)*obj.hghtRow;
                pPos = [obj.dX,yPosB,obj.widRadioO,obj.hghtRadio];
                
                % creates the radio button object
                obj.hRadioO{i} = createUIObj('radiobutton',obj.hPanelO,...
                    'Position',pPos,'FontUnits','Pixels',...
                    'FontSize',obj.fSzL,'FontWeight','Bold',...
                    'String',pStrO{i},'Value',i==2);
            end
            
            % sets the fixed/custom directories
            obj.hEditO.String = obj.iProg.DirComb;
            obj.hRadioO{1}.TooltipString = obj.iProg.DirComb;
            obj.hRadioO{2}.TooltipString = obj.iProg.DirComb;
            
            % updates the panel properties
            obj.panelOutputChange([],[]);
            
        end
            
        % --- sets up the output explorer tree panel objects
        function setupExplorerTreePanel(obj)
            
            % initialisations
            cbFcnFC = @obj.treeSelectChng;
            nLen = length(obj.fDirRoot) + 2;            
                        
            % tree explorer properties
            pPos = obj.hPanelOS.Position;
            pPosO = getObjGlobalCoord(obj.hPanelOS);
            tPos = [obj.dX*[1,1]/2,pPos(3:4)-obj.dX] + [pPosO(1:2)+2,0,0];
            rStr = getFinalDirString(obj.fDirRoot);
            
            % remove any added folders
            obj.removeAddedFolders()
            
            % Root node
            hRoot = createUITreeNode(rStr, rStr, [], false);
            hRoot.setUserObject(obj.fDirRoot);
            set(0,'CurrentFigure',obj.hFig);
            
            % sets the file/folder icons
            Ifile = obj.getIconImagePath('File');
            Ifolder = obj.getIconImagePath('Folder');
            
            % adds the tree sub-nodes
            for i = 1:length(obj.fDir)
                % creates/determines the parent node of the current file name
                hNodeP = hRoot;
                fDirSp = strsplit(obj.fDir{i}(nLen:end),filesep);
                for j = 1:length(fDirSp)
                    hNodeP = obj.addFolderTreeNode(hNodeP,fDirSp{j},Ifolder);
                end
                
                % adds in the experiment name leaf node
                hNodeL = createUITreeNode(...
                    obj.fName{i},obj.fName{i},Ifile,true);
                hNodeL.setUserObject(i);
                hNodeP.add(hNodeL);
            end
            
            % creates the tree object
            wState = warning('off','all');
            obj.hTreeOS = uitree('v0','Root',hRoot,'Position',tPos,...
                'parent',obj.hPanelOS,'SelectionChangeFcn',cbFcnFC);
            obj.hTreeOS.expand(hRoot)
            warning(wState);
            
            % expands the explorer tree nodes
            obj.expandExplorerTreeNodes();                                   
            
        end
        
        % --- sets up the control button panel objects
        function setupControlButtonPanel(obj)
            
            % initialisations
            cbFcnB = {@obj.buttonRefreshExplorer;...
                      @obj.buttonSaveFiles;@obj.buttonCloseWindow};
            pStrB = {'Refresh File Explorer',...
                     'Save Data Files','Close Window'};
            
            % creates the panel object
            xPos = sum(obj.hPanelO.Position([1,3])) + obj.dX/2;
            pPos = [xPos,obj.dX/2,obj.widPanelLoR,obj.hghtPanelC];
            obj.hPanelC = createPanelObject(obj.hPanelLo,pPos);
            
            % creates the button objects
            obj.hButC = createObjectRow(obj.hPanelC,obj.nButC,...
                'pushbutton',obj.widButC,'pStr',pStrB,'xOfs',obj.dX/2,...
                'yOfs',obj.dX/2,'dxOfs',0);
            cellfun(@(x,y)(set(x,'Callback',y)),obj.hButC,cbFcnB);
            
        end        
        
        % --- sets up the file chooser panel objects
        function setupFileChooserPanel(obj)
            
            % creates the panel object
            xPos = sum(obj.hPanelO.Position([1,3])) + obj.dX/2;
            yPos = sum(obj.hPanelC.Position([2,4])) + obj.dX/2;
            pPos = [xPos,yPos,obj.widPanelLoR,obj.hghtPanelF];
            obj.hPanelF = createPanelObject(obj.hPanelLo,pPos);
            
            %
            obj.initFileChooser();
            
        end        
        
        % --- sets up the experiment/group name table panel objects
        function setupNameTablePanel(obj)
                        
            % creates the panel object
            pPos = [obj.dX*[1,1]/2,obj.widPanelT,obj.hghtPanelHiI];
            obj.hPanelT = createPanelObject(obj.hPanelHi,pPos);           

            % ----------------------------- %
            % --- EXPERIMENT NAME TABLE --- %
            % ----------------------------- %
            
            % initialisations
            cWidN = {210,40,40};
            cbFcnNE = @obj.tableExptEdit;
            cbFcnNS = @obj.tableExptSelect;
            cNameN = {'Experiment Name','Add?','Type'};
            
            % creates the table object
            pPosTN = [obj.dX*[1,1]/2,obj.widTableTN,obj.hghtTableT];
            obj.hTableTN = createUIObj('table',obj.hPanelT,...
                'Data',[],'Position',pPosTN,'FontSize',obj.fSz,...
                'CellSelectionCallback',cbFcnNS,'ColumnName',cNameN,...
                'CellEditCallback',cbFcnNE,'ColumnWidth',cWidN,...
                'ColumnEditable',[true,true,false]);
            
            % auto-resizes the table
            autoResizeTableColumns(obj.hTableTN);
            
            % sets the experiment name table
            DataN = [obj.fName(:),num2cell(obj.useExp),obj.fExtn(:)];
            DataN(:,end) = centreTableData(DataN(:,end));   
            obj.hTableTN.Data = DataN;
            
            % resets the table selection
            obj.resetExptTableBG()
            obj.jTableTN = getJavaTable(obj.hTableTN);
            setTableSelection(obj.hTableTN,0,0)            
            
            % ------------------------ %
            % --- GROUP NAME TABLE --- %
            % ------------------------ %            
            
            % initialisations
            cWidG = {166,40};            
            cbFcnGE = @obj.tableGroupEdit;            
            cNameG = {'Group Name','Add?'};                         
            
            % creates the table object
            xPosTG = sum(pPosTN([1,3])) + obj.dX/2;
            pPosTG = [xPosTG,obj.dX/2,obj.widTableTG,obj.hghtTableT];
            obj.hTableTG = createUIObj('table',obj.hPanelT,...
                'Data',[],'Position',pPosTG,'FontSize',obj.fSz,...
                'CellEditCallback',cbFcnGE,'ColumnWidth',cWidG,...
                'ColumnName',cNameG,'ColumnEditable',true(size(cWidG)));
            
            % auto-resizes the table
            obj.jTableTG = getJavaTable(obj.hTableTG);
            autoResizeTableColumns(obj.hTableTG);            
            
        end
        
        % --- sets up the output parameter panel objects
        function setupOutputParameterPanel(obj)
            
            % initialisations
            cbFcnE = @obj.editOutputPara;
            cbFcnC = @obj.checkOutputPara;
            tStrE = 'Time Interval (Hours)';  
            tStrP = {'Output Y-Position Data',...
                     'Output Stimuli Time-Stamps',...
                     'Output Experiment Info',...
                     'Use Comma Separator',...
                     'Split Experiment By Time Interval'};                        
                 
            % creates the panel object
            xPos = sum(obj.hPanelT.Position([1,3])) + obj.dX/2;
            pPos = [xPos,obj.dX/2,obj.widPanelP,obj.hghtPanelHiI];
            obj.hPanelP = createPanelObject(obj.hPanelHi,pPos,obj.tHdrP);
            
            % creates the editbox object
            [obj.hEditP,obj.hTxtP] = createObjectPair(obj.hPanelP,tStrE,...
                obj.widLblP,'edit','cbFcnM',cbFcnE);
            obj.hEditP.String = num2str(obj.sInfo{1}.iPara.dT);
                        
            % sets up the grouping criteria checkboxes
            yPos0 = obj.dX + obj.hghtRow;
            for i = 1:obj.nChkP
                % calculates the vertical offset
                j = obj.nChkP - (i-1);
                yPos = yPos0 + (j-1)*obj.hghtHdr;
                
                % creates the checkbox object
                pPos = [obj.dX,yPos,obj.widChkP,obj.hghtHdr];
                obj.hChkP{i} = createUIObj('checkbox',obj.hPanelP,...
                    'Position',pPos,'FontUnits','Pixels',...
                    'FontWeight','Bold','FontSize',obj.fSzL,...
                    'Callback',cbFcnC,'UserData',obj.uD{i},'String',tStrP{i});
            end
            
        end

        % --------------------------------------- %
        % --- FILE CHOOSER CALLBACK FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- file chooser property change callback function
        function chooserPropChange(obj, ~, evnt)
                        
            % if updating indirectly, then exit the function
            if obj.isUpdating; return; end
                        
            % field retrieval
            fExtn0 = obj.fExtn;
            objChng = evnt.getNewValue;            
            isFixed = obj.hRadioO{1}.Value;
            
            switch get(evnt,'PropertyName')
                case 'directoryChanged'
                    % case is the folder change
                    
                    % retrieves the new file path
                    nwDir = char(objChng.getPath);
                    
                    % retrieves root directory and chooser object handle
                    if isFixed
                        isOK = true;
                    else
                        isOK = startsWith(objChng.getPath,obj.fDirRoot);
                    end
                    
                    % determines if the new directory is on the root path
                    if isOK
                        % if so, then update the directory
                        if isFixed
                            % if fixed, the update
                            obj.fDirFix = nwDir;
                            
                            % updates the fixed output strings
                            obj.hEditO.String = nwDir;
                            obj.hRadioO{1}.TooltipString = nwDir;
                        else
                            % updates the file
                            obj.fDir{obj.iExp} = nwDir;
                            
                            % updates the tree node
                            obj.treeNodeUpdate('move',obj.iExp)
                        end
                        
                        % resets the figure background
                        obj.isChange = true;
                        obj.resetExptTableBG()
                        
                    else
                        % if folder is invalid then output error message
                        tStr = 'Invalid File Directory';
                        mStr = sprintf(['The selected directory is ',...
                            'not on the root directory path.\nEither ',...
                            'reset the root directory or choose ',...
                            'another directory.']);
                        waitfor(msgbox(mStr,tStr,'modal'))
                        
                        % reverts back to the original path
                        currFile = obj.getCurrentFilePath(obj.iExp);
                        obj.jChooseF.setSelectedFile(java.io.File(currFile));
                    end
                    
                case 'fileFilterChanged'
                    % case is the file extension filter change
                    obj.fExtn{obj.iExp} = ...
                        char(objChng.getSimpleFilterExtension);
                    
                    % determines if the new name is feasible
                    if obj.checkExptName(obj.fName{obj.iExp})
                        % updates the chooser file and experiment table background
                        obj.resetChooserFile(obj.iExp)
                        obj.resetExptTableBG()
                        
                        % sets the new table string
                        tExtnNw = java.lang.String(obj.fExtn{obj.iExp});
                        fNw = centreTableData({tExtnNw});
                        
                        % updates the object properties
                        obj.isChange = true;
                        obj.updateObjectProps(obj.iExp)
                        obj.setTableValue(obj.jTableTN,obj.iExp,3,fNw{1});
                    else
                        % otherwise revert file extensions back to original
                        obj.fExtn = fExtn0;
                        obj.resetChooserFileExtn(fExtn0{obj.iExp})
                    end
                    
                case 'SelectedFileChangedProperty'
                    % case is the directory has been created
                    
                    % retrieves the new/previous values
                    nwVal = removeFileExtn(char(get(evnt,'NewValue')));
                    prVal = removeFileExtn(char(get(evnt,'OldValue')));
                    
                    if ~isempty(nwVal)
                        % determines if the new/old values differ
                        if ~strcmp(char(prVal),char(nwVal))
                            % updates the new file/directory names
                            [obj.fDir{obj.iExp},...
                                fNameNw,~] = fileparts(char(nwVal));
                            
                            % updates the explorer tree name and the table
                            obj.resetChooserFile(obj.iExp,fNameNw)
                            saveFileNameChng([], fNameNw)
                            
                        else
                            % updates the file name string
                            hFn = getFileNameObject(obj.jChooseF);
                            [~,fNameNw,~] = fileparts(char(nwVal));
                            
                            obj.isUpdating = true;
                            hFn.setText(getFileName(fNameNw));
                            obj.isUpdating = false;
                        end
                    end
            end
            
        end
        
        % --- save file name change callback function
        function saveFileNameChng(obj, hObj, evnt)
            
            % if updating elsewhere, then exit the function
            if obj.isUpdating; return; end            
            
            % retrieves the
            if ischar(evnt)
                fNameNw = evnt;
            else
                fNameNw = char(get(hObj,'Text'));
            end
            
            % enables the create button enabled properties (disable if no file name)
            if obj.checkExptName(fNameNw)
                % if valid, then update the experiment name struct
                obj.fName{obj.iExp} = fNameNw;
                obj.isChange = true;
                
                % updates the other gui objects
                obj.updateTreeExplorerName(obj.iExp)
                setObjEnable(obj.hButC{2},~isempty(fNameNw))
                obj.resetExptTableBG()
                
                % resets the table value
                nwStr = java.lang.String(fNameNw);
                obj.setTableValue(obj.jTableTN,obj.iExp,1,nwStr)
                
            else
                % otherwise, reset the chooser file
                obj.resetChooserFile(obj.iExp,[],true);
            end
            
        end        
        
        % --- experiment name change function
        function [ok,mStr] = checkExptName(obj, exptName, iExpS)
                        
            % sets the default default input arguments
            if ~exist('iExpS','var'); iExpS = obj.iExp; end            
            
            if get(obj.hRadioO{1},'Value')
                % case is fixed, so repeat the fixed directory strings
                fDirS = repmat({obj.fDirFix},length(obj.fName),1);
            else
                % otherwise, retrieve the custom directory strings
                fDirS = obj.fDir;
            end
            
            % check to see if the current directory string is valid/unique
            [ok,mStr] = chkDirString(exptName);
            if ok
                % sets the current file output file/directory names
                fFile = cell(length(obj.fName),1);
                for i = 1:length(fFile)
                    % sets the experiment file name
                    if i == iExpS
                        fNameNw = exptName;
                    else
                        fNameNw = obj.fName{i};
                    end
                    
                    % sets the full experiment file/directory path
                    switch obj.fExtn{i}
                        case {'.mat','.ssol'}
                            % case is .mat/.ssol format output
                            fFile{i} = fullfile(...
                                fDirS{i},[fNameNw,obj.fExtn{i}]);
                            
                        otherwise
                            % case is .txt/.csv format output
                            fFile{i} = fullfile(fDirS{i},fNameNw);
                    end
                end
                
                % if the new experiment file already exists in the solution 
                % file list then flag an error
                B = ~setGroup(iExpS,size(fDirS));
                if any(strcmp(fFile(B),fFile{iExpS}))
                    ok = false;
                    mStr = sprintf(['The output file name "%s" ',...
                       'already exists in the solution file list. ',...
                       'Please retry using a unique file name.'],exptName);
                end
            end
            
            % if an error occured & not being output, then output to screen
            if (nargout == 1) && ~isempty(mStr)
                waitfor(msgbox(mStr,'Infeasible Experiment Name','modal'))
            end
            
        end
        
        % -------------------------------- %
        % --- TABLE CALLBACK FUNCTIONS --- %
        % -------------------------------- %        

        % --- group name table edit callback function                
        function tableGroupEdit(obj, hTable, evnt)
            
            % input data
            [iRow,iCol] = deal(evnt.Indices(1),evnt.Indices(2));
            [prStr,nwStr] = deal(evnt.PreviousData,evnt.NewData);
            tabData = get(hTable,'Data');
            
            switch iCol
                case 1
                    % determines if the group region was rejected
                    if ~strcmp(prStr,'* REJECTED *')
                        % otherwise, update the group name array
                        obj.gName{obj.iExp}{iRow} = nwStr;
                        obj.isChange = true;
                        
                        % resets the table background colour scheme
                        bgCol = obj.getGroupNameTableColour(obj.iExp);
                        set(hTable,'BackgroundColor',bgCol)
                        return
                    end
                    
                case 2
                    % determines if the group region was rejected
                    if ~strcmp(tabData{iRow,1},'* REJECTED *')
                        % updates the group acceptance flags
                        obj.sInfo{obj.iExp}.snTot.iMov.ok(iRow) = nwStr;
                        obj.isChange = true;
                        
                        % resets the table background colour scheme
                        bgCol = obj.getGroupNameTableColour(obj.iExp);
                        set(hTable,'BackgroundColor',bgCol)
                        return
                    end
            end
            
            % if so, then output an error message to screen
            mStr = ['This group region has been rejected and ',...
                    'can''t be include in the output.'];
            waitfor(msgbox(mStr,'Rejected Region Error','modal'))
            
            % resets the table data to the previous string
            tabData{iRow,iCol} = prStr;
            bgCol = obj.getGroupNameTableColour(obj.iExp);
            set(hTable,'Data',tabData,'BackgroundColor',bgCol);
            
        end
        
        % --- experiment name table edit callback function
        function tableExptEdit(obj, hTable, evnt)
                        
            % if updating elsewhere, then exit the function
            if obj.isUpdating
                return
            else
                obj.isUpdating = true;
            end
                        
            % retrieves the input values
            tabData = get(hTable,'Data');
            [iRow,iCol] = deal(evnt.Indices(1),evnt.Indices(2));
            
            % performs the update check based on the column that was altered
            switch iCol
                case 1
                    % case is the experiment name
                    nwStr = evnt.NewData;
                    if obj.checkExptName(nwStr,iRow)
                        % if the new name is valid, then update the arrays
                        obj.fName{iRow} = nwStr;
                        obj.isChange = true;
                        
                        % updates the explorer tree
                        obj.updateTreeExplorerName(iRow)
                        obj.resetChooserFile(iRow);
                        
                    else
                        % otherwise, revert back to the original name
                        hTable.Data{iRow,1} = evnt.PreviousData;
                    end
                    
                case 2
                    % updates the experiment inclusion flag
                    obj.useExp(iRow) = tabData{iRow,iCol};
                    
                    % updates the tree node based on the table selection
                    if tabData{iRow,iCol}
                        % case is adding a node
                        obj.treeNodeUpdate('add',iRow)
                    else
                        % case is removing a node
                        obj.treeNodeUpdate('remove',iRow)
                    end
                    
                    % resets the update flag
                    obj.isUpdating = false;                       
                    
                    % resets the table selection
                    if tabData{iRow,iCol}
                        setTableSelection(hTable,iRow-1,0)
                    end
                    
                    % pause to allow refresh of gui
                    pause(0.05);
            end
            
            % resets the update flag
            obj.isUpdating = false;              
            
            % resets the experiment tables background colour
            obj.resetExptTableBG()                     
            
        end
        
        % --- experiment name table selection callback function
        function tableExptSelect(obj, hTable, evnt)
            
            % slight pause (this alows cell edit function to run before 
            % cell selection function - important for checkbox changes)
            pause(0.1)
            
            % if updating elsewhere, then exit
            if obj.isUpdating
                return
            end
             
            % retrieves the selected row index
            if isempty(evnt)
                % case is the function is called manually
                obj.isUpdating = true;
                iRow = max(1,getTableCellSelection(hTable));
                obj.isUpdating = false;
                
            elseif isempty(evnt.Indices)
                % if there are no indices, then exit
                return
                
            else
                % otherwise, retrieve the selected index
                iRow = evnt.Indices(1);
            end
            
            % updates the selected experiment flag
            iExp0 = obj.iExp;
            obj.iExp = iRow;
            
            % sets the object properties
            tData = hTable.Data;            
            setObjEnable(obj.hTableTG,tData{iRow,2});
            setObjVisibility(obj.hPanelF,tData{iRow,2});
            
            % if the region is rejected, then exit the function
            if tData{iRow,2}
                % retrieves the group name table colour array
                ok = obj.sInfo{iRow}.snTot.iMov.ok;
                bgCol = obj.getGroupNameTableColour(iRow);
                
                % resets the group name table properties
                Data = [obj.gName{iRow}(:),num2cell(ok)];
                set(obj.hTableTG,'Data',Data,'BackgroundColor',bgCol);
                
                % updates the object properties
                obj.resetChooserFile(iRow)
                
            else
                % if the region is rejected
                nRow = length(obj.sInfo{iExp0}.snTot.iMov.ok);
                set(obj.hTableTG,'Data',[],'BackgroundColor',ones(nRow,3))
            end
            
            % updates the other output parameters
            obj.resetSelectedNode(iRow)
            obj.updateObjectProps(iRow);
            obj.resetChooserFileExtn(obj.fExtn{iRow})
            
        end
        
        % --------------------------------------- %
        % --- OTHER OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- data output button group selection callback function
        function panelOutputChange(obj, ~, evnt)
            
            % initialisations
            isCust = obj.hRadioO{2}.Value;
            
            % updates the object enabled properties
            setObjEnable(obj.hEditO,~isCust);
            setObjEnable(obj.hButO,~isCust);     
            set(obj.hTreeOS,'Visible',isCust)
                        
            % resets the experiment table background
            obj.resetExptTableBG()                        
            
            % updates the file chooser 
            if ~isempty(evnt)
                obj.isChange = true;
                obj.resetChooserFile(obj.iExp)
            end
            
        end
        
        % --- set directory pushbutton callback function
        function buttonSetDir(obj, ~, ~)
                        
            % prompts the user for the search directory
            tStr = 'Select the root search directory';
            sDirNw = uigetdir(obj.fDirFix,tStr);
            if sDirNw == 0
                % if the user cancelled, then exit
                return
            end
            
            % otherwise, update the directory string names
            obj.isChange = true;
            obj.hEditO.String = sDirNw;
            obj.hRadioO{1}.TooltipString = sDirNw;
            
            % updates the object properties
            obj.resetChooserFile(obj.iExp)
            obj.resetExptTableBG()
            
        end        
        
        % --- explorer tree selection change callback function
        function treeSelectChng(obj, ~, evnt)
            
            % if updating elsewhere, then exit
            if obj.isUpdating; return; end
            
            % retrieves the current node. if it is not a leaf node then exit
            hNodeS = get(evnt,'CurrentNode');
            if ~hNodeS.isLeafNode; return; end
            
            % updates the experiment name table selection
            iExpS = hNodeS.getUserObject;
            setTableSelection(obj.hTableTN,iExpS-1,0)
            
        end        
        
        % --- output parameter editbox callback function
        function editOutputPara(obj, hEdit, ~)

            % field retrieval
            nwVal = str2double(hEdit.String);
            
            % determines if the new value is valid
            if chkEditValue(nwVal,[1,obj.Tmax(obj.iExp)],1)
                % if so, then update the parameter field/change flag
                obj.sInfo{obj.iExp}.iPara.dT = nwVal;
                obj.isChange = true;
                
            else
                % otherwise, revert to the previous valid value
                hEdit.String = num2str(obj.sInfo{obj.iExp}.iPara.dT);
            end

        end

        % --- output parameter checkbox callback function
        function checkOutputPara(obj, hChk, ~)

            % field retrieval
            pFld = hChk.UserData;
            
            % updates the other parameter struct (for current experiment)
            obj.isChange = true;
            obj.oPara(obj.iExp).(pFld) = get(hChk,'Value');
            
            % runs the time split checkbox callback function
            if strcmp(hChk.UserData,'solnTime')
                obj.updateSolnTimeProps();
            end            
            
        end        
        
        % --- refresh explorer pushbutton callback function
        function buttonRefreshExplorer(obj, ~, ~)
            
            % resets the experiment table background colours
            obj.resetExptTableBG()
            obj.jChooseF.rescanCurrentDirectory()
        
        end
        
        % --- save files pushbutton callback function
        function buttonSaveFiles(obj, ~, ~)
                    
            % determines if the files already exist
            fExist = obj.detExistingExpt();
            if any(fExist(obj.useExp))
                % if there are files/directories that already exist, then 
                % output a message to screen prompt the user to overwrite
                mStr = sprintf(['The following files from the output ',...
                                'list already exist:\n\n']);
                for i = find(fExist(obj.useExp)')
                    if any(strcmp({'.mat','.ssol'},obj.fExtn{i}))
                        % case is a mat/DART solution file
                        fExtnNw = obj.fExtn{i};
                    else
                        % case is text file
                        fExtnNw = '';
                    end
                    
                    % appends the new file name
                    mStr = sprintf('%s %s %s%s\n',...
                        mStr,char(8594),obj.fName{i},fExtnNw);
                end
                
                % appends the error message suffix string
                mStr = sprintf(['%s\nAre you sure you want to ',...
                                'overwrite these files?'],mStr);
                
                % promts the user if the wish to overwrite the files
                uChoice = questdlg(mStr,'Overwrite Existing Files?','Yes','No','Yes');
                if ~strcmp(uChoice,'Yes')
                    % if the user cancelled, then exit the function
                    return
                end
            end
            
            % outputs the experiment solution file data
            obj.objSF.outputSolnFiles();
        
            % resets the experiment table background colours
            obj.buttonRefreshExplorer([],[]);            
            
        end            
        
        % --- close window pushbutton callback function
        function buttonCloseWindow(obj, ~, ~)
        
            % determines if there was a change made
            if obj.isChange
                % if there was a change, then prompt user to confirm change
                tStr = 'Update Changes?';
                qStr = 'Do you want to update the changes you have made?';
                uChoice = questdlg(qStr,tStr,'Yes','No','Cancel','Yes');
        
                switch uChoice
                    case 'Yes'
                        % case is the user chose to update

                        % resets the fields
                        for i = 1:length(obj.sInfo)
                            obj.sInfo{i}.expFile = obj.fName{i};
                            obj.sInfo{i}.gName = obj.gName{i};
                        end

                        % case is the user chose to update
                        setappdata(obj.hFigM,'sInfo',obj.sInfo);
                        obj.postSaveFcn(obj.hFigM,0);

                    case 'Cancel'
                        % case is the user cancelled
                        return
                end
            end
            
            % removes the added folders
            obj.removeAddedFolders()

            % makes the main gui visible again
            setObjVisibility(obj.hFig,0);
            setObjVisibility(obj.hGUIInfo.hFig,'on')
            setObjVisibility(obj.hFigM,'on')            
            
            % deletes the class object
            obj.deleteClass();
            
        end                        
        
        % ------------------------------------ %        
        % --- FILE EXPLORER TREE FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- sets up the full file path string
        function [fFileP,fDirP] = getCurrentFilePath(obj,iExp)
            
            % sets the input arguments
            if ~exist('iExp','var'); iExp = 1; end            
            
            % retrieves the directory name based on the output directory type
            if obj.hRadioO{1}.Value
                % case is using a fixed output directory
                fDirP = obj.fDirFix;
                
            else
                % case is using a customised structure
                fDirP = obj.fDir{iExp};
            end
            
            % sets the full file name
            fFileP = fullfile(fDirP,obj.fName{iExp});
            
        end
        
        % --- creates a tree node from the parent node hNodeP
        function hNodeP = addFolderTreeNode(obj,hNodeP,nName,Iicon)
            
            % sets the default input aruments
            if ~exist('Iicon','var'); Iicon = []; end
            
            if hNodeP.getChildCount > 0
                % if the current node has children nodes, then
                indC = 1:hNodeP.getChildCount;
                hNodeC = arrayfun(@(x)(hNodeP.getChildAt(x-1)),indC(:),'un',0);
                chNode = cellfun(@(x)(char(x.getName)),hNodeC,'un',0);
                isLeaf = cellfun(@(x)(logical(x.isLeaf)),hNodeC);
                
                %
                isEx = strcmp(chNode,nName) & ~isLeaf;
                if any(isEx)
                    % if the node exists, then retrieve it
                    hNodeP = hNodeP.getChildAt(find(isEx)-1);
                    isAdd = false;
                else
                    % otherwise, add a new node
                    isAdd = true;
                end
                
            else
                % if the node count is zero, then add the node
                isAdd = true;
            end
            
            % adds the new node (if required)
            if isAdd && ~isempty(nName)
                % adds a new node to the tree
                hNodeP.setAllowsChildren(true);
                hNodeNw = createUITreeNode(nName,nName,Iicon,false);
                hNodeP.add(hNodeNw);
                
                % retrieves the full path of the new node
                fDirNw = obj.getFullNodePath(hNodeNw);
                if ~exist(fDirNw,'dir')
                    % if the directory does not exist, then create it
                    mkdir(fDirNw)
                end
                
                % updates the parent node to the new node
                hNodeP = hNodeP.getChildAt(hNodeP.getChildCount-1);
            end
            
        end        
  
        % --- updates the selected tree node
        function resetSelectedNode(obj,iRow)
            
            % retrieves the currently selected and candidate tree nodes
            hNodeS = obj.hTreeOS.getSelectedNodes;
            if ~obj.useExp(iRow)
                hNodeNw = [];
            else
                hNodeNw = obj.getExplorerTreeNode(iRow);
            end
            
            % determines if the tree node needs updating
            if isempty(hNodeS)
                % if no selected node, then update
                updateNode = true;
            else
                % otherwise, determine if there is a difference between the 2
                updateNode = ~isequal(hNodeS(1),hNodeNw);
            end
            
            % updates the tree selected node (if required)
            if updateNode
                obj.isUpdating = true;
                obj.hTreeOS.setSelectedNode(hNodeNw);
                pause(0.05);
                obj.isUpdating = false;
            end
            
        end
        
        % --- retrieves the explorer tree node for the iExp
        function expandExplorerTreeNodes(obj)
            
            for i = 1:obj.hTreeOS.getRoot.getLeafCount
                % sets the next node to search for
                if i == 1
                    % case is from the root node
                    hNodeP = obj.hTreeOS.getRoot.getFirstLeaf;
                else
                    % case is for the other nodes
                    hNodeP = hNodeP.getNextLeaf;
                end
                
                % retrieves the selected node
                obj.hTreeOS.expand(hNodeP.getParent);
            end
            
        end        
        
        % --- retrieves the explorer tree node for the iExp
        function hNodeP = getExplorerTreeNode(obj,iExp)
            
            for i = 1:obj.hTreeOS.getRoot.getLeafCount
                % sets the next node to search for
                if i == 1
                    % case is from the root node
                    hNodeP = obj.hTreeOS.getRoot.getFirstLeaf;
                else
                    % case is for the other nodes
                    hNodeP = hNodeP.getNextLeaf;
                end
                
                % if the correct node was found, then exit the loop
                if hNodeP.getUserObject == iExp
                    break
                end
            end
            
        end
        
        % --- tree node update function
        function treeNodeUpdate(obj,Type,iExpN,varargin)
            
            % initialisations
            hRoot = obj.hTreeOS.getRoot;            
            Ifile = obj.getIconImagePath('File');
            
            switch Type
                case 'move'
                    % removes the existing node and replaces with the new
                    obj.treeNodeUpdate('remove',iExpN,1)
                    obj.treeNodeUpdate('add',iExpN,1)
                    
                case 'add'
                    % case is adding a new node
                    Ifolder = obj.getIconImagePath('Folder');
                    
                    % determines the folder to add
                    fDirAdd = obj.fDir{iExpN}((length(obj.fDirRoot)+2):end);
                    fDirSp = strsplit(fDirAdd,filesep);                    
                    
                    % retrieves/add in the parent folder node
                    hP = cell(length(fDirSp)+1,1);
                    hP{1} = hRoot;
                    for j = 1:length(fDirSp)
                        hP{j+1} = obj.addFolderTreeNode(...
                            hP{j},fDirSp{j},Ifolder);
                    end
                    
                    % adds in the leaf node
                    hNodeL = createUITreeNode(...
                        obj.fName{iExpN},obj.fName{iExpN},Ifile,true);
                    hNodeL.setUserObject(iExpN);
                    hP{end}.add(hNodeL);
                    
                    % reloads all the nodes
                    cellfun(@(x)(obj.hTreeOS.reloadNode(x)),hP)
                    
                case 'remove'
                    % case is removing an existing node
                    hNodeL = obj.getExplorerTreeNode(iExpN);
                    
                    % delete the leaf node and any empty folder nodes
                    while 1
                        % retrieves the parent node and deletes the current
                        hNodeP = hNodeL.getParent();
                        hNodeP.remove(hNodeL);
                        obj.hTreeOS.reloadNode(hNodeP);
                        
                        if isequal(hRoot,hNodeP) || ...
                                (hNodeP.getChildCount > 0)
                            % if the parent node has children, or is the 
                            % root, then exit the loop
                            break
                        else
                            % otherwise, reset the leaf node for removal
                            hNodeL = hNodeP;
                        end
                    end
            end
            
            % repaints the tree
            if nargin == 3
                obj.expandExplorerTreeNodes()
                obj.hTreeOS.repaint();
                pause(0.05);
            end
            
        end
        
        % --- resets the chooser file extension to fExtn
        function resetChooserFileExtn(obj,fExtnS)
            
            % sets the update flag
            obj.isUpdating = true;            
            
            % retrieves the list of choosable file filters
            jExtn = obj.jChooseF.getChoosableFileFilters;
            txtExtn = arrayfun(@(x)(...
                get(x,'SimpleFilterExtension')),jExtn,'un',0);
            
            % resets the file filter
            obj.jChooseF.setFileFilter(jExtn(strcmp(txtExtn,fExtnS)))
            pause(0.05);
            
            % resets the update flag
            obj.isUpdating = false;
            
        end
        
        % --- sets the value, cValue, at the (iRow,iCol) cell in the table
        function setTableValue(obj,jTable,iRow,iCol,cValue)            
            
            % flag that an updating is occuring
            obj.isUpdating = true;
            
            % retrieves the java table object
            jTable.setValueAt(cValue,iRow-1,iCol-1)
            pause(0.05);
            
            % resets the update flag
            obj.isUpdating = false;
            
        end
        
        % --- updates the explorer tree
        function updateTreeExplorerName(obj,iExpS)
            
            % retrieves the explorer tree node
            hNodeP = obj.getExplorerTreeNode(iExpS);
            
            % updates the experiment name
            obj.isUpdating = true;
            hNodeP.setName(obj.fName{iExpS});
            obj.hTreeOS.reloadNode(hNodeP);
            obj.hTreeOS.repaint()
            obj.isUpdating = false;
            
        end
        
        % ------------------------------------- %
        % --- OTHER OBJECT UPDATE FUNCTIONS --- %
        % ------------------------------------- %
        
        % --- resets the chooser file
        function resetChooserFile(obj,iExp,fFileNw,forceUpdate)
                        
            % sets the default input arguments
            if ~exist('fFileNw','var'); fFileNw = []; end            
            if ~exist('forceUpdate','var'); forceUpdate = false; end
            
            % initialisations
            fFileS = char(obj.jChooseF.getSelectedFile());
            
            % retrieves the current file name and the new file name
            if isempty(fFileNw) || forceUpdate
                fFileNw = obj.getCurrentFilePath(iExp);
            end
            
            % if the new and selected files are not the same then update
            if ~strcmp(fFileS,fFileNw) || forceUpdate
                % flag that the object is updating indirectly
                obj.isUpdating = true;
                
                % resets the selected file
                obj.jChooseF.setSelectedFile(java.io.File(fFileNw));
                obj.jChooseF.repaint();
                
                % updates the file name string
                hFn = getFileNameObject(obj.jChooseF);
                hFn.setText(getFileName(fFileNw));
                pause(0.05);
                
                % resets the update flag
                obj.isUpdating = false;
            end
            
        end
        
        % --- resets the experiment name tables background colours
        function resetExptTableBG(obj)
            
            % determines which experiments currently exist
            fileExist = obj.detExistingExpt();
            
            % updates the update flag
            obj.isUpdating = true;
            
            % updates the table background colours
            bgCol = obj.getExptNameTableColour(obj.useExp,fileExist);
            set(obj.hTableTN,'BackgroundColor',bgCol)
            pause(0.05);
            
            % resets the update flag
            obj.isUpdating = false;            
            
        end                
        
        % --- updates the object properties (for experiment, iExp)
        function updateObjectProps(obj,iExp)
            
            % sets the default argument values
            if ~exist('iExp','var'); iExp = 1; end
            
            % initialisations
            [isCSV,isOut,isTime] = deal(false,true,true);            
            
            % field retrieval
            hasStim = obj.sInfo{iExp}.hasStim;
            hasY = ~isempty(obj.sInfo{iExp}.snTot.Py);
            tDataEx = obj.hTableTN.Data;
            
            % updates the panel properties
            setPanelProps(obj.hPanelP,tDataEx{iExp,2})
            
            % updates the GUI properties based on the
            switch obj.fExtn{iExp}
                case {'.ssol','.mat'} 
                    % case is the DART Solution File
                    [isOut,isTime] = deal(false);
                    set(obj.hChkP{5},'value',0)
                    
                case ('.txt') 
                    % case is the ASCII text file
                    isCSV = true;
            end
            
            % updates the check properties (if required)
            if tDataEx{iExp,2}
                % updates the check-box properties
                setObjEnable(obj.hChkP{4},isCSV)
                setObjEnable(obj.hChkP{5},isTime)
                setObjEnable(obj.hChkP{1},hasY)
                
                % sets the output checkbox enabled properties
                setObjEnable(obj.hChkP{3},isOut)
                setObjEnable(obj.hChkP{2},isOut && hasStim)
            end
            
            % runs the split experiment checkbox callback function
            obj.updateSolnTimeProps();
            
            % updates the checkbox values
            for i = 1:length(obj.uD)
                % if checkbox is disabled, then reset flag value to false
                if strcmp(get(obj.hChkP{i},'Enable'),'off') && ...
                            ~any(strcmp(obj.igChk,obj.hChkP{i}.UserData))
                    obj.oPara(iExp).(obj.uD{i}) = false;
                end
                
                % updates the checkbox value
                obj.hChkP{i}.Value = obj.oPara(iExp).(obj.uD{i});
            end
            
            % updates the solution time values
            obj.hEditP.String = num2str(obj.sInfo{iExp}.iPara.dT);
            
        end                
                
        % --- updates the solution time object props
        function updateSolnTimeProps(obj)
            
            % sets the time interval text/editbox properties
            isSel = get(obj.hChkP{5},'value');
            setObjEnable(obj.hTxtP,isSel)
            setObjEnable(obj.hEditP,isSel)
            
        end        
        
        % --------------------------------- %
        % --- FIELD RETRIEVAL FUNCTIONS --- %
        % --------------------------------- %
        
        % --- retrieves the icon image data for type, Type
        function iconImg = getIconImagePath(obj,Type)
            
            % retrieves temporary directory path
            tDir = obj.iProg.TempFile;
            
            % sets the full icon path
            iconImg = fullfile(tDir,sprintf('%s.gif',Type));
            
        end
        
        % --- determines which output files/directories already exist
        function [fileExist,fFile] = detExistingExpt(obj,ind)            
            
            % retrieves the base directory names
            if obj.hRadioO{1}.Value
                % case is a output to a fixed directory
                fDirP = repmat({obj.fDirFix},length(obj.fName),1);
            else
                % case is output to the custom tree structure
                fDirP = obj.fDir;
            end
            
            % memory allocation
            if ~exist('ind','var'); ind = 1:length(obj.fName); end
            [fileExist,fFile] = deal(false(length(ind),1),cell(length(ind),1));
            
            % determines if the file/directory exists (depending on extension type)
            for i = 1:length(ind)
                j = ind(i);
                switch obj.fExtn{j}
                    case {'.ssol','.mat'}
                        % case is a file output
                        fFile{i} = fullfile(...
                            fDirP{j},[obj.fName{j},obj.fExtn{j}]);
                        fileExist(i) = exist(fFile{i},'file') > 0;

                    otherwise
                        % case is a directory output
                        fFile{i} = fullfile(fDirP{j},obj.fName{j});
                        fileExist(i) = exist(fFile{i},'dir') > 0;
                end
            end
            
        end
                
        % --- sets the group name table background colour array
        function bgCol = getGroupNameTableColour(obj,iExp)
            
            % field retrieval
            [sInfoS,gNameS] = deal(obj.sInfo{iExp},obj.gName{iExp});
            
            % retrieves the unique group names from the list
            [gNameU,~,iGrpNw] = unique(gNameS,'stable');
            isOK = sInfoS.snTot.iMov.ok & ~strcmp(gNameS,'* REJECTED *');
            
            % sets the background colour based on the matches within the unique list
            tCol = getAllGroupColours(length(gNameU),1);
            bgCol = tCol(iGrpNw,:);
            bgCol(~isOK,:) = obj.grayCol;
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- removes all of the added folders
        function removeAddedFolders(obj)
            
            % determines the directories that have been added
            dfDir = setdiff(findDirAll(obj.fDirRoot),obj.fDir0);
            if isempty(dfDir); return; end
            
            % splits the added directory paths and orders by descending size
            fDirSp = cellfun(@(x)(strsplit(x,filesep)),dfDir,'un',0);
            [~,iS] = sort(cellfun('length',fDirSp),'descend');
            dirRemove = dfDir(iS);
            
            % removes any of the added folders which are empty
            for i = 1:length(dirRemove)
                dirData = dir(dirRemove{i});
                if ~any(arrayfun(@(x)(x.bytes),dirData) > 0)
                    % if the directory is empty, then remove it
                    try rmdir(dirRemove{i}); catch; end
                end
            end
            
        end        
        
        % --- deletes the class object
        function deleteClass(obj)
            
            % deletes the figure
            delete(obj.hFig);
            
            % deletes the class object
            delete(obj)
            clear obj
            
        end
        
    end
    
    % class methods
    methods (Static)
        
        % --- retrieves the full directory path of the node, hNodeNw
        function fPath = getFullNodePath(hNodeNw)
            
            hNodePath = hNodeNw.getPath;
            fPathN = arrayfun(@(x)(char(x.getName())),hNodePath(2:end),'un',0);
            fPath = strjoin([{hNodePath(1).getUserObject};fPathN]',filesep);
            
        end
        
        % --- sets the experiment name table background colour array
        function bgCol = getExptNameTableColour(ok,fileExist)
            
            % sets the default input arguments
            if ~exist('fileExist','var'); fileExist = []; end
            
            % sets the background colour array
            bgCol = ones(length(ok),3);
            bgCol(~ok,:) = 0.81;
            
            % if existing file information is given then add to the array
            if ~isempty(fileExist)
                bgCol(fileExist,1) = 1;
                bgCol(fileExist,2:3) = 0.5;
                bgCol(~ok & fileExist,2:3) = 0.81;
            end
            
        end                
        
    end    
    
end