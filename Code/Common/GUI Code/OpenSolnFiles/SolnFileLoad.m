classdef SolnFileLoad < handle & dynamicprops
    
    % class properties
    properties
        
        % input arguments
        iTabP
        
        % main class objects
        hTab
        hPanel
        hPanelLo
        
        % explorer tree class objects
        hPanelT
        hPanelTF
        hTabGrpT
        jTabGrpT
        hTabT
        hTxtT
        hButT
        
        % experiment details class objects
        hPanelD
        jPanelD        
        hTableD
        jTableD
        tabCR1
        tabCR2        
        
        % control button class objects
        hPanelC
        hTxtC
        hButC
        
        % group name class objects
        hPanelG
        hTableG
        jTableG
        
        % stimuli protocol panel objects
        hPanelS
        
        % stimuli protocol axes objects
        hPanelAxS
        hAxS
        
        % stimuli protocol control button class objects
        hPanelCS
        hButCS
        
        % fixed dimension class fields
        hghtPanelLo = 210;     
        widPanelL = 590;
        widPanelCS = 160;        
        widAxS = 670;
        hghtAxS = 450;
        widLblC = 130;
        widTxtC = 25;
        dimButT = 30;   
        widButC = [120,110,95*[1,1]];
        widLblT = [45,35,60,35,95,530];
        
        % calculated dimension class fields
        hghtPanelT
        hghtPanelL
        hghtPanelD
        hghtPanelC
        hghtPanelG
        hghtPanelS
        hghtPanelCS
        hghtPanelAxS
        widPanelI
        widPanelI2
        widPanelG
        widTabGrpT
        hghtTabGrpT        
        hghtTableD
        widTableD
        hghtTableG
        widTableG        
        widButCS        
        
        % file explorer tree class fields
        objFT
        sFile
        
        % other class fields
        iTab       
        iExp
        
        % boolean class fields
        tableUpdate = false;
        pathUpdate = true;
        
        % static scalar class fields
        nRowD = 4;
        nRowG = 8;
        nButC = 4;   
        nButT = 2;
        nTabT = 3;     
        nExpMax = 4;
        
        % static string class fields
        tHdrT = 'SOLUTION FILE EXPLORER TREE';
        tHdrD = 'EXPERIMENT DETAILS';
        tHdrG = 'REGION GROUP NAMES';
        tHdrS = 'STIMULI PROTOCOL';
        cStrTG = 'matlab.ui.container.TabGroup';  
        
        % static cell array class properties
        bgCol = {0.94*ones(1,3),[1,0,0]};
        fExtn = {'.soln','.ssol','.msol'};         
        txtTag = {'textFileCount','textSelectedCount','textRootDir'};
        
    end
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = SolnFileLoad(objB,iTabP)
            
            % sets the input arguments
            obj.objB = objB;
            obj.iTabP = iTabP;
            
            % initialises the class fields/objects
            obj.linkParentProps();
            obj.initClassFields();
            obj.initClassObjects();
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class object fields with that parent object
        function linkParentProps(obj)
            
            % parent fields strings
            fldStr = {'sInfo','hFig','hParent','jTabGrp','iProg',...
                      'dX','hghtHdrTG','hghtRow','hghtHdr','hghtBut',...
                      'fSzL','fSz','white','gray','black',...
                      'sDir','tHdrTG','isChange','nExp','sType'};
            
            % connects the base/child objects
            for propname = fldStr
                metaprop = addprop(obj, propname{1});
                metaprop.SetMethod = @(obj, varargin) ...
                    SetDispatch(obj, propname{1}, varargin{:});
                metaprop.GetMethod = @(obj)GetDispatch(obj, propname{1});
            end
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % sets up the outer panel object (based on type)
            if isa(obj.hParent,obj.cStrTG)
                % case is using multiple panels
                
                % creates the stimuli tab object
                obj.hTab = createUIObj('tab',obj.hParent,...
                    'Title',obj.tHdrTG{obj.iTabP},'UserData',obj.iTabP);
                
                % creates the panel object                
                pPosT = getpixelposition(obj.hTab);
                szTG = pPosT(3:4)-(obj.dX+[0,obj.hghtHdrTG]); 
                pPos = [obj.dX*[1,1]/2,szTG];
                obj.hPanel = createPanelObject(obj.hTab,pPos);
                
            else
                % case is using a single panel
                obj.hPanel = obj.hParent;
            end

            % ----------------------------- %
            % --- OTHER INITIALISATIONS --- %
            % ----------------------------- %

            % field retrieval
            pPos = obj.hPanel.Position;
            
            % memory allocation
            obj.hButT = cell(obj.nButT,1);
            [obj.hTabT,obj.hPanelTF] = deal(cell(obj.nTabT,1));
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %
            
            % panel width calculations
            obj.widPanelI = pPos(3) - 2*obj.dX;
            obj.widPanelI2 = obj.widPanelI - 2*obj.dX;
            obj.widPanelG = obj.widPanelI - (3*obj.dX + obj.widPanelL);            
        
            % table dimension calculations
            obj.hghtTableD = calcTableHeight(obj.nRowD) + obj.hghtHdr + 3;
            obj.widTableD = obj.widPanelL - 1.5*obj.dX;
            obj.hghtTableG = calcTableHeight(obj.nRowG);
            obj.widTableG = obj.widPanelG - 1.5*obj.dX;            
            
            % stimuli protocol panel objects
            obj.hghtPanelS = pPos(4) - 1.5*obj.dX;
            obj.hghtPanelCS = obj.dX + obj.hghtRow;                         
            obj.hghtPanelAxS = obj.hghtPanelS - ...
                (2*obj.dX + obj.hghtPanelCS + obj.hghtHdrTG);
            obj.widButCS = obj.widPanelCS - 2*obj.dX;
            
            % calculates the other panel dimensions
            obj.hghtPanelT = pPos(4) - (2.5*obj.dX + obj.hghtPanelLo);
            obj.hghtPanelD = obj.hghtTableD + 1.5*obj.dX + obj.hghtHdr - 1;
            obj.hghtPanelC = 1.5*obj.dX + obj.hghtRow;
            obj.hghtPanelG = obj.hghtTableG + obj.dX + obj.hghtHdr;                        
            
            % sets the file tab group dimensions
            obj.widTabGrpT = obj.widPanelI - (2.5*obj.dX + obj.dimButT);
            obj.hghtTabGrpT = obj.hghtPanelT - (obj.dX/2 + 2*obj.hghtHdr);
            
        end
        
        % --- initialises the class fields
        function initClassObjects(obj)
            
            % creates the lower panel object
            pPosLo = [obj.dX*[1,1],obj.widPanelI,obj.hghtPanelLo];
            obj.hPanelLo = createPanelObject(obj.hPanel,pPosLo);
            
            % ------------------------------ %
            % --- MAIN SUB-PANEL OBJECTS --- %
            % ------------------------------ %
            
            % sets up the file loading sub-panel objects
            obj.setupControlButtonPanel();
            obj.setupExptDetailPanel();
            obj.setupGroupNamePanel();
            obj.setupFileExplorerPanel();
            
            % sets up the stimuli protocol panel
            obj.setupStimProtocolPanel();               

            % updates the tab
            obj.treeMouseClick([],[]);
            
        end
        
        % --- creates the experiment information table 
        function createExptInfoTable(obj)
            
            % function handles
            cbFcnT = @obj.tableInfoSelect;

            % sets the table header strings
            hdrStr = {createTableHdrString({'Experiment Name'}),...
                      createTableHdrString({'Parent','Folder/File'}),...
                      createTableHdrString({'File','Type'}),...
                      createTableHdrString({'Setup','Type'}),...
                      createTableHdrString({'Stimuli','Protocol'}),...          
                      createTableHdrString({'Duration'})};

            % sets up the table data array
            cWidMin = {230,110,40,40,75,70};
            cWidMax = {250,130,40,40,75,70};
            tabData = cell(obj.nRowD,length(hdrStr));            
            tPos = [obj.dX*[1,1]/2+[0,3],obj.widTableD,obj.hghtTableD];
            hTable = createUIObj('table',obj.hPanelD,...
                'RowName',[],'CellSelectionCallback',cbFcnT,...
                'ColumnEdit',false(1,length(hdrStr)));
            
            % creates the java table object
            jScroll = findjobj(hTable);
            [jScrollP, hContainer] = ...
                createJavaComponent(jScroll,[],obj.hPanelD);
            set(hContainer,'Units','Pixels','Position',tPos)

            % creates the java table model
            obj.jTableD = jScrollP.getViewport.getView;
            jTableMod = javax.swing.table.DefaultTableModel(tabData,hdrStr);
            obj.jTableD.setModel(jTableMod);

            % sets the table callback function
            cbFcn = @obj.tableInfoEdit;
            jTableMod = handle(jTableMod,'callbackproperties');
            addJavaObjCallback(jTableMod,'TableChangedCallback',cbFcn);
            
            % creates the table cell renderer
            obj.tabCR1 = ColoredFieldCellRenderer(obj.white);
            obj.tabCR2 = ColoredFieldCellRenderer(obj.white);
            
            % sets the table text to black
            for i = 1:size(tabData,1)
                for j = 1:size(tabData,2)
                    % sets the background colours
                    obj.tabCR1.setCellBgColor(i-1,j-1,obj.gray);
                    obj.tabCR2.setCellBgColor(i-1,j-1,obj.gray);        

                    % sets the foreground colours
                    obj.tabCR1.setCellFgColor(i-1,j-1,obj.black);
                    obj.tabCR2.setCellFgColor(i-1,j-1,obj.black);                
                end
            end

            % disables the smart alignment
            obj.tabCR1.setSmartAlign(false);
            obj.tabCR2.setSmartAlign(false);

            % sets the cell renderer horizontal alignment flags
            obj.tabCR1.setHorizontalAlignment(2)
            obj.tabCR2.setHorizontalAlignment(0)

            % Finally assign the renderer object to all the table columns
            for cID = 1:length(hdrStr)
                cMdl = obj.jTableD.getColumnModel.getColumn(cID-1);
                cMdl.setMinWidth(cWidMin{cID})
                cMdl.setMaxWidth(cWidMax{cID})

                % sets the cell renderer
                if cID == 1
                    % case is the name column
                    cMdl.setCellRenderer(obj.tabCR1);        
                else
                    % case is the other columns
                    cMdl.setCellRenderer(obj.tabCR2);
                end
            end

            % updates the table header colour
            gridCol = getJavaColour(0.5*ones(1,3));
            obj.jTableD.getTableHeader().setBackground(gridCol);
            obj.jTableD.setGridColor(gridCol);
            obj.jTableD.setShowGrid(true);
            
            % retrieves the expt info panel java object
            obj.jPanelD = findjobj(obj.hPanelD);

            % disables the resizing
            jTableHdr = obj.jTableD.getTableHeader(); 
            jTableHdr.setResizingAllowed(false); 
            jTableHdr.setReorderingAllowed(false);
            
            % repaints the table            
            obj.jTableD.repaint()
            obj.jTableD.setAutoResizeMode(obj.jTableD.AUTO_RESIZE_ALL_COLUMNS)
            obj.jTableD.getColumnModel().getSelectionModel.setSelectionMode(2)
            
        end
        
        % --- creates the file explorer tree
        function createFileExplorerTree(obj,iTabNw)
            
            % default input arguments
            if ~exist('iTabNw','var'); iTabNw = obj.iTab; end           
            
            % sets the root search directory (dependent on stored
            % values and tab index)
            if exist('iTabNw','var')
                % case is the tab index is provided
                sDirNw = obj.sDir{iTabNw};
                
            else
                % case is the tab index is not provided
                iTabNw = obj.iTab;
                
                % retrieves the solution file directory
                switch obj.iTab
                    case 1
                        % case is video solution files
                        sDirNw = obj.iProg.DirSoln;
                        
                    otherwise
                        % case is experiment solution files
                        sDirNw = obj.iProg.DirComb;
                end
            end
            
            % creates the file tree explorer for the file type
            obj.objFT{iTabNw} = FileTreeExplorer(obj,sDirNw,iTabNw);
            
            % updates the folder path information
            obj.sDir{iTabNw} = sDirNw;
            obj.sFile{iTabNw} = obj.objFT{iTabNw}.sFileT;            
            
            % if there were matches, then update the information fields
            mTreeNw = obj.objFT{iTabNw}.mTree;
            if obj.objFT{iTabNw}.ok                
                % updates the table information
                set(mTreeNw,'MouseClickedCallback',@obj.treeMouseClick);
            else
                % disables the tree
                mTreeNw.Enabled = false;
            end                        
            
            % disables the add button
            obj.updateAddButtonProps(0);
            
        end           
        
        % ------------------------------------ %
        % --- PANEL OBJECT SETUP FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- sets up the control panel objects
        function setupControlButtonPanel(obj)
            
            % initialisations
            pType = [repmat({'text'},1,2),...
                     repmat({'pushbutton'},1,obj.nButC)];
            wObjC = [obj.widLblC,obj.widTxtC,obj.widButC];
            pStr = {'Loaded Experiments: ','0','Remove Selected',...
                    'Stimuli Protocol','Clear All','Continue'};
            cbFcnB = {@obj.buttonRemoveSelected;@obj.buttonStimuliProto;...
                      @obj.buttonClearAll;@obj.buttonContinue};
                 
            % creates the panel object
            pPos = [obj.dX*[1,1],obj.widPanelL,obj.hghtPanelC];
            obj.hPanelC = createPanelObject(obj.hPanelLo,pPos);
            
            % creates the panel objects
            hObjC = createObjectRow(obj.hPanelC,length(pType),...
                pType,wObjC,'yOfs',obj.dX,'xOfs',obj.dX/2,...
                'dxOfs',0,'pStr',pStr);
            [obj.hTxtC,obj.hButC] = deal(hObjC{2},hObjC(3:end));
                        
            % sets the button callback functions
            set(hObjC{1},'HorizontalAlignment','Right');
            set(hObjC{2},'HorizontalAlignment','Left');
            cellfun(@(x,y)(set(x,'Callback',y)),obj.hButC,cbFcnB);
            cellfun(@(x)(setObjEnable(x,0)),obj.hButC);          
            
        end
        
        % --- sets up the experiment details panel objects
        function setupExptDetailPanel(obj)
            
            % creates the panel object
            yPos = sum(obj.hPanelC.Position([2,4])) + obj.dX/2;
            pPos = [obj.dX,yPos,obj.widPanelL,obj.hghtPanelD];
            obj.hPanelD = createPanelObject(obj.hPanelLo,pPos,obj.tHdrD);

            % creates the experiment information table
            obj.createExptInfoTable();
            
            % adds to the added list 
            if ~isempty(obj.sInfo)
                % sets the added list strings    
                setObjEnable(obj.hButC{3},'on')
                obj.setContinueProps('on')
                setPanelProps(obj.hPanelD,'on')
                set(obj.hTxtC,'string',num2str(obj.nExp))    

                % updates the experiment information table
                obj.updateExptInfoTable()
            end                     
            
        end
        
        % --- sets up the group name panel objects
        function setupGroupNamePanel(obj)
            
            % creates the panel object
            xPos = sum(obj.hPanelC.Position([1,3])) + obj.dX;
            pPos = [xPos,obj.dX,obj.widPanelG,obj.hghtPanelG];
            obj.hPanelG = createPanelObject(obj.hPanelLo,pPos,obj.tHdrG);            
            
            % creates the table object
            pPosT = [obj.dX*[1,1]/2,obj.widTableG,obj.hghtTableG];
            obj.hTableG = createUIObj('table',obj.hPanelG,...
                'Data',[],'Position',pPosT,'FontSize',obj.fSz,...
                'CellEditCallback',@obj.tableGroupEdit,...
                'Visible','off','RowName',[]);            
            
        end        
        
        % --- sets up the file explorer panel objects
        function setupFileExplorerPanel(obj)
            
            % initialisations
            fSzB = [14,25];
            pStrB = {'...','+'};
            pStrL = {'Found: ','N/A','Selected: ','N/A',...
                     'Root Directory: ','N/A'};
            cbFcnB = {@obj.buttonSetDir,@obj.buttonAddSoln};            
                 
            % creates the panel object
            yPos = sum(obj.hPanelLo.Position([2,4])) + obj.dX;
            pPos = [obj.dX,yPos,obj.widPanelI,obj.hghtPanelT];
            obj.hPanelT = createPanelObject(obj.hPanel,pPos,obj.tHdrT);

            % --------------------------- %
            % --- MINOR PANEL OBJECTS --- %
            % --------------------------- %
            
            % creates the label objects
            hObjL = createObjectRow(obj.hPanelT,length(obj.widLblT),...
                'text',obj.widLblT,'yOfs',obj.dX/2+1,'dxOfs',0,...
                'pStr',pStrL);
            
            % updates the object properties
            cellfun(@(x)(set(...
                x,'HorizontalAlignment','Right')),hObjL([1,3,5]))
            cellfun(@(x)(set(...
                x,'HorizontalAlignment','Left')),hObjL([2,4,6]))            
            obj.hTxtT = hObjL([2,4,6]);
            
            % creates the panel button objects
            xPosB = 1.5*obj.dX + obj.widTabGrpT;
            yPosTG = obj.dX/2 + obj.hghtHdr;
            yPosB0 = yPosTG + obj.hghtTabGrpT/2 - (obj.dimButT + obj.dX/2);
            for i = 1:obj.nButT
                % determines the vertical offset
                j = obj.nButT - (i-1);
                yPosB = yPosB0 + (j-1)*(obj.dX + obj.dimButT);
                
                % creates the button object
                pPosB = [xPosB,yPosB,obj.dimButT*[1,1]];
                obj.hButT{i} = createUIObj('pushbutton',obj.hPanelT,...
                    'Position',pPosB,'Callback',cbFcnB{i},...
                    'FontUnits','Pixels','FontWeight','Bold',...
                    'FontSize',fSzB(i),'String',pStrB{i});
            end                        
            
            % ------------------------------- %
            % --- SOLUTION FILE TAB GROUP --- %
            % ------------------------------- % 
            
            % initialisations            
            tStrT = {'Video Solution Files (*.soln)',...
                     'Experiment Solution Files (*.ssol)',...
                     'Multi-Expt Solution Files (*.msol)'};            
            
            % function handles
            cbFcnT = @obj.tabSolnFileSelect;
            cbFcnTG = @obj.tabSolnGroupSelect;
            
            % creates the tab group object
            pPosTG = [obj.dX,yPosTG,obj.widTabGrpT,obj.hghtTabGrpT];
            obj.hTabGrpT = createUIObj('tabgroup',obj.hPanelT,...
                'Position',pPosTG,'SelectionChangedFcn',cbFcnTG);            
            
            % creates the explorer tree tab objects
            szT = pPosTG(3:4)-(obj.dX+[0,obj.hghtHdrTG]);
            pPosT = [obj.dX*[1,1]/2,szT];
            for i = 1:obj.nTabT
                % creates the tab panel
                obj.hTabT{i} = createUIObj('tab',obj.hTabGrpT,...
                    'Title',tStrT{i},'UserData',i,'ButtonDownFcn',cbFcnT);
                obj.hPanelTF{i} = createPanelObject(obj.hTabT{i},pPosT);
                
                % creates the explorer tree for the current tab
                obj.createFileExplorerTree(i);
            end
            
            % sets the first valid tab
            hasTree = cellfun(@(x)(x.ok),obj.objFT);
            obj.iTab = find(hasTree,1,'first');
            set(obj.hTabGrpT,'SelectedTab',obj.hTabT{obj.iTab}); 
            
        end                
        
        % --- sets up the stimuli protocol panel
        function setupStimProtocolPanel(obj)
            
            % sets up the panel object
            pPos = [obj.dX*[1,1],obj.widPanelI,obj.hghtPanelS];
            obj.hPanelS = createPanelObject(obj.hPanel,pPos,obj.tHdrS);
            setObjVisibility(obj.hPanelS,0);
            
            % ---------------------------- %            
            % --- CONTROL BUTTON PANEL --- %
            % ---------------------------- %
            
            % initialisations
            cbFcnB = @obj.buttonHideProtocol;
            bStrCB = 'Hide Stimuli Protocol';
            
            % creates the panel object
            xPosC = obj.widPanelI - (obj.dX + obj.widPanelCS);
            pPosC = [xPosC,obj.dX,obj.widPanelCS,obj.hghtPanelCS];
            obj.hPanelCS = createPanelObject(obj.hPanelS,pPosC);

            % creates the button object
            pPosCB = [obj.dX*[2,1]/2,obj.widButCS,obj.hghtBut];
            obj.widButCS = createUIObj('pushbutton',obj.hPanelCS,...
                'Position',pPosCB,'FontUnits','Pixels',...
                'FontWeight','Bold','FontSize',obj.fSzL,...
                'String',bStrCB,'Callback',cbFcnB);            
            
            % ----------------------------------- %            
            % --- STIMULI PROTOCOL AXES PANEL --- %
            % ----------------------------------- %
            
            % creates the panel object
            yPosS = sum(pPosC([2,4])) + obj.dX;
            pPosS = [obj.dX,yPosS,obj.widPanelI2,obj.hghtPanelAxS];
            obj.hPanelAxS = createPanelObject(obj.hPanelS,pPosS);
            
            % creates the axes object
            xPosAx = obj.widPanelI2 - (obj.dX + obj.widAxS);
            yPosAx = obj.hghtPanelAxS - (obj.dX + obj.hghtAxS);
            pPosAx = [xPosAx,yPosAx,obj.widAxS,obj.hghtAxS];
            obj.hAxS = createUIObj('axes',obj.hPanelAxS,'Units',...
                'Pixels','FontUnits','Pixels','Position',pPosAx,...
                'Box','On','TickLength',[0,0]);
            
        end             
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- explorer tree clicked callback function
        function treeMouseClick(obj, ~, ~)

            % updates the add button properties
            nSel = obj.getSelectedNodeCount();
            obj.updateAddButtonProps(nSel>0);            
            
            % updates the solution 
            if obj.pathUpdate
                obj.updateSolnFileInfo(nSel);                
            end            
            
        end

        % --- solution file tabgroup selection callback function
        function tabSolnGroupSelect(obj, hTabGrp, evnt)
            
            % ??
            
        end
        
        % --- solution file tab selection callback function
        function tabSolnFileSelect(obj, hTab, ~)
            
            % updates the selected tab
            obj.iTab = hTab.UserData;

            % updates the table information
            obj.treeMouseClick([],[])            
            
        end
        
        % --- set base directory button callback function
        function buttonSetDir(obj, ~, ~)
            
            % determines if the explorer tree exists for the current tab
            if obj.objFT{obj.iTab}.ok
                % if the tree explorer exists for this tab, then prompt the 
                % user ifthey actually want to overwrite the locations
                tStr = 'Reset Search Root?';
                qStr = ['Are you sure you want to reset the ',...
                        'search root directory?'];
                uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                if ~strcmp(uChoice,'Yes')
                    % if the user cancelled, then exit the function
                    return
                end
            end

            % prompts the user for the search directory
            defDir = obj.sDir{obj.iTab};
            titleStr = 'Select the root search directory';
            sDirNw = uigetdir(defDir,titleStr);
            if sDirNw == 0
                % if the user cancelled, then exit
                return
            else
                % otherwise, update the tab default directory
                obj.sDir{obj.iTab} = sDirNw;
            end            

            % creates the explorer tree
            obj.isChange = true;
            obj.createFileExplorerTree(obj.iTab);            
            obj.updateSolnFileInfo()
            
        end
        
        % --- add solution file button callback function
        function buttonAddSoln(obj, ~, ~)
            
            % global variables
            global hh
            
            % object/array retrieval
            sInfo0 = obj.sInfo;
            tDir = obj.iProg.TempFile;

            % --------------------------- %            
            % --- SELECTED FILE SETUP --- %
            % --------------------------- %
            
            % sets the full names of the selected files
            iSel = obj.objFT{obj.iTab}.getCurrentSelectedNodes();
            sFileS = obj.sFile{obj.iTab}(iSel);  
            
            % allocates memory for the 
            switch obj.iTab
                case 1
                    % case is the video solution files
                    [fDirS,fNameS] = obj.groupSelectedFiles(sFileS);

                    % other initialisations
                    nFile = length(fDirS);
                    wStr = {'Overall Progress','Directory Progress'};
                    mName = cellfun(@(x)...
                                    (getFinalDirString(x)),fDirS,'un',0);

                otherwise
                    % case is the experiment solution files
                    fDirS = cellfun(@(x)(fileparts(x)),sFileS,'un',0);
                    fNameS = cellfun(@(x)(getFileName(x,1)),sFileS,'un',0);        

                    % other initialisations
                    nFile = length(sFileS);
                    wStr = {'Overall Progress',...
                            'Loading Data File',};
                    if obj.iTab == 3
                        [wStr{end+1},mName] = deal('Data Output',[]);
                    else
                        mName = cellfun(@(x)(getFileName(x)),sFileS,'un',0);
                    end
            end      

            % ----------------------------- %            
            % --- SOLUTION FILE LOADING --- %
            % ----------------------------- %
            
            % creates the progress bar
            hh = ProgBar(wStr,'Solution File Loading');
            isOK = true(nFile,1);                              
            
            % reads the information from each of the data file/directories
            for i = 1:nFile
                % resets the minor progressbar fields 
                if i > 1
                    for j = 2:length(wStr)
                        hh.Update(j,wStr{j},0);
                    end
                end

                switch obj.iTab
                    case 1
                        % case is a video solution file directory

                        % updates the progressbar
                        wStrNw = sprintf(...
                                '%s (Directory %i of %i)',wStr{1},i,nFile);
                        hh.Update(1,wStrNw,i/(nFile+1));

                        % reads in the video solution file data
                        fFileS = cellfun(@(x)...
                                (fullfile(fDirS{i},x)),fNameS{i},'un',0);
                        [snTotNw,iMov,eStr] = combineSolnFiles(fFileS);
                                               
                        % if the user cancelled, or was an error, then exit    
                        if isempty(snTotNw)
                            if isempty(eStr)
                                % case is the user cancelled
                                obj.sInfo = sInfo0;
                                hh = [];                    
                                return  
                            else
                                % otherwise, flag that there was an error 
                                % with loading the data from the directory
                                isOK(i) = false;
                            end           
                        else
                            % resets the time vectors     
                            snTotNw = obj.resetVideoAndStimTiming(snTotNw);                                                    
                            
                            % sets up the fly location ID array
                            snTotNw.iMov = reduceRegionInfo(iMov);
                            snTotNw.cID = setupFlyLocID(snTotNw.iMov);
                            
                            % reduces the region information             
                            obj.appendSolnInfo(snTotNw,fDirS{i});
                        end            

                    case 2
                        % updates the progressbar
                        wStrNw = sprintf('%s (File %i of %i)',...
                                        wStr{1},i,nFile);
                        hh.Update(1,wStrNw,i/(nFile+1));            

                        % case is a group of experiment solution files
                        fFileS = fullfile(fDirS{i},fNameS{i});
                        [snTotNw,ok] = loadExptSolnFiles(tDir,fFileS,1,hh);  
                        if ~ok
                            % if the user cancelled, then exit the function
                            obj.sInfo = sInfo0;
                            return
                        end
                        
                        % reduces the region information 
                        snTotNw.sName = [];
                        snTotNw.iMov = reduceRegionInfo(snTotNw.iMov);
                        obj.appendSolnInfo(snTotNw,fFileS);

                    case 3
                        % updates the progressbar
                        wStrNw = sprintf('%s (File %i of %i)',...
                                         wStr{1},i,nFile);
                        hh.Update(1,wStrNw,i/(nFile+1));                 

                        % loads the multi-experiment solution file
                        fFileS = fullfile(fDirS{i},fNameS{i});
                        [snTotNw,mNameNw,ok] = ...
                            loadMultiExptSolnFiles(tDir,fFileS,[],hh);
                        if ~ok
                            % if the user cancelled, then exit the function
                            return
                        end

                        % reduce the region information for each experiment
                        for j = 1:length(snTotNw)
                            snTotNw(j).sName = [];
                            snTotNw(j).iMov = ...
                                        reduceRegionInfo(snTotNw(j).iMov);
                                    
%                             % separates the multi-experiment group names
%                             gName = separateMultiExptGroupNames(snTotNw(j)); 
%                             snTotNw(j).iMov.pInfo.gName = gName;
                        end

                        % case is a group of multiexperiment solution files
                        obj.appendSolnInfo(snTotNw,fFileS,mNameNw);
                        mName = [mName;mNameNw(:)];
                end
            end            
            
            % closes the progress bar
            try hh.closeProgBar(); catch; end
            hh = [];            

            % ------------------------------- %            
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % if there was an error loading a directory/file, then 
            % output these directories to screen
            if any(~isOK)
                eStr = sprintf(['There was an error loading files ',...
                                'from the following directories:\n\n']);
                for i = find(~isOK(:))
                    % adds in the error directories
                    if obj.iTab == 1
                        eStr = sprintf('%s * %s\n',eStr,fDirS{i});
                    else
                        fFileS = fullfile(fDirS{i},fNameS{i});
                        eStr = sprintf('%s * %s\n',eStr,fFileS);
                    end
                end

                % outputs the error message to screen
                eStr = sprintf(['%s\nYou will need to ensure that all ',...
                                'the videos for this experiment have ',...
                                'been tracked correctly and are not ',...
                                'corrupted.'],eStr);
                waitfor(msgbox(eStr,'Corrupt or Infeasble Data','modal'))

                % removes the directories which gave an error
                mName = mName(isOK);
            end
            
            % updates the solution file GUI
            setObjEnable(obj.hButC{1},0);
            obj.updateSolnFileGUI(~isempty(mName));            
            
        end
        
        % --- experiment information table cell change callback funcion
        function tableInfoEdit(obj, ~, evnt)
            
            % if the table is updating automatically, then exit
            if obj.tableUpdate
                return
            end
            
            try
                % attempts to retrieves the row/column indices
                iRow = get(evnt,'FirstRow');
                iCol = get(evnt,'Column');
                
                % if the row/column indices are infeasible, then exit
                if (iRow < 0) || (iCol < 0)
                    return
                end
                
            catch
                % if there was an error, then exit
                return
            end
            
            % retrieves the original table data
            tabData = obj.getTableData();
            nwStr = obj.jTableD.getValueAt(iRow,iCol);
            
            % determines if the new string is valid and feasible
            if (iRow+1) > size(tabData,1)
                % if the row index is infeasible then exit
                return
                
            elseif strcmp(nwStr,tabData{iRow+1,iCol+1})
                % case is the string name has not changed
                return
                
            elseif iCol == 0
                % case is the experiment name is being updated
                nwStr = obj.jTableD.getValueAt(iRow,iCol);
                
                % determines if new experiment name is valid
                if checkNewExptName(obj.sInfo,nwStr,iRow+1)
                    % if so, then update the
                    obj.cObj.expData(iRow+1,1,:) = {nwStr};
                    
                    % updates the experiment name and change flag
                    obj.isChange = true;
                    obj.sInfo{iRow+1}.expFile = nwStr;
                    
                    % updates the table background colours
                    obj.tableUpdate = true;
                    obj.resetExptTableBGColour(0);
                    
                    % repaints the table and wait for the update
                    obj.jTableD.repaint();
                    pause(0.05);
                    obj.tableUpdate = false;
                    
                    % updates the experiment names on the other tabs
                    if obj.sType == 3
                        obj.objB.updateExptNames(iRow+1,1);
                    end
                    
                    % exits the function
                    return
                end
            end
            
            % flag that the table is being updated
            obj.tableUpdate = true;
            
            try
                % attempts to reset the table cell value back to original
                if (iRow+1) >= size(tabData,1)
                    obj.jTableD.setValueAt([],iRow,iCol);
                else
                    obj.jTableD.setValueAt(tabData{iRow+1,iCol+1},iRow,iCol);
                end
                
                % waits for update
                pause(0.05)
            catch
            end
            
            % resets the table update flag
            obj.tableUpdate = false;            
            
        end        
        
        % --- experiment information table cell change callback funcion
        function tableInfoSelect(obj, ~, evnt)
            
            % pauses for a small amount of time...
            pause(0.05);
            
            if isempty(obj.sInfo)
                % if there is no solution data loaded, then exit 
                return
                
            elseif isempty(evnt.Indices)
                % otherwise, if data is loaded, but 
                obj.objB.setMenuEnable('menuScaleFactor',0);
                
                % exits the function
                return
            end         
            
            % retrieves the other imporant fields
            obj.iExp = evnt.Indices(1);
            obj.objB.setMenuEnable('menuScaleFactor',1);
            
            % updates the group table
            if obj.iExp <= length(obj.sInfo)
                setObjEnable(obj.hButC,1)
                obj.updateGroupTableProps();     
                
            else
                % otherwise, clear the table
                set(obj.hTableG,'Data',[],'Visible','off');
            end            
            
        end                                
        
        % --- remove selected button callback function
        function buttonRemoveSelected(obj, hBut, ~)
    
            % confirms the user wants to clear the selected table fields
            tStr = 'Confirm Data Clearing?';
            qStr = ['Are you sure you want to clear the ',...
                    'selected experiment data?'];
            uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % if the user cancelled, then exit the function
                return
            end
            
            % creates a loadbar
            wStr = 'Updating Stored Experiment Information...';
            hProg = ProgressLoadbar(wStr);

            % retrieves the currently selected table rows
            jTableMod = obj.jTableD.getModel;

            % determines the selected rows
            iSel = double(obj.jTableD.getSelectedRows)+1;
            iNw = ~setGroup(iSel(:),[length(obj.sInfo),1]);

            % if there are no experiments left, then clear everything
            if ~any(iNw)
                obj.buttonClearAll(handles.buttonClearAll,[]);
                return
            else
                % otherwise, recalculate the experiment count
                obj.nExp = sum(iNw);
            end            
            
            % resets the control button enabled properties
            setObjEnable(hBut,'off')
            setObjEnable(obj.hButC{2},0)
            setObjEnable(obj.hButC{3},obj.nExp>0)            
            set(obj.hTxtC,'Enable','on','string',num2str(obj.nExp))
            
            % resets the menu item enabled properties
            obj.objB.setMenuEnable('menuScaleFactor',0);
            obj.objB.setMenuEnable('menuTimeCycle',0);
            obj.objB.setMenuEnable('menuCombExpt',obj.nExp>1);            
            
            % resets the other object properties
            obj.setContinueProps(obj.nExp>0)            
            setObjVisibility(obj.hTableG,0)            

            % reduces down the solution file information
            obj.sInfo = obj.sInfo(iNw);
            setTimeCycleMenuProps(obj.hFig,obj.sInfo);

            % sets the other boolean flags
            obj.tableUpdate = true;
            obj.isChange = true;

            % removes the table selection
            obj.jTableD.changeSelection(-1,-1,false,false);
            pause(0.05);

            % shifts the rows (if there are any rows under those being cleared)
            if iSel(end)+1 <= length(iNw)
                indRow = obj.jTableD.getRowCount-1;
                jTableMod.moveRow(iSel(end),indRow,iSel(1)-1)
            end

            % removes any excess rows
            pause(0.05);
            nRow0 = obj.jTableD.getRowCount;
            for i = max(obj.nExp+1,obj.nExpMax+1):nRow0
                jTableMod.removeRow(obj.jTableD.getRowCount-1)
                obj.jTableD.repaint()
            end
            
            % removes/clears the rows
            pause(0.05);
            for i = (obj.nExp+1):obj.nExpMax
                obj.clearExptInfoTableRow(i) 
            end

            % resets the column widths
            obj.resetExptTableBGColour(0);
            obj.resetColumnWidths()

            % repaints the table
            obj.jPanelD.repaint()
            obj.jTableD.repaint()            

            % resets the table update flag
            pause(0.05);
            obj.tableUpdate = false;
            
            % if loading files through the analysis gui, then update the
            % experiment information for the other tabs
            hProg.StatusMessage = 'Resetting Loaded Data...';
            obj.objB.updateFullGUIExpt();
            
            % creates the explorer tree
            obj.pathUpdate = false;
            for i = obj.getResetIndexArray()
                obj.createFileExplorerTree(i);
                pause(0.05);
            end
            
            % deletes the loadbar
            obj.pathUpdate = true;
            delete(hProg)            
            
        end
        
        % --- stimuli protocol button callback function
        function buttonStimuliProto(obj, ~, ~)
            
            % sets the panel object visibility properties
            setObjVisibility(obj.hPanelLo,0)
            setObjVisibility(obj.hPanelD,0)
            setObjVisibility(obj.hPanelS,1)

            % resets the stimuli axes
            obj.resetStimAxes()            
            
        end               
        
        % --- clear all button callback function
        function buttonClearAll(obj, ~, evnt)
            
            % object handles
            iTab0 = obj.iTab;         

            % prompts the user if they want to clear all the loaded data
            if ~isempty(evnt)
                tStr = 'Confirm Data Clearing?';
                qStr = ['Are you sure you want to clear all the ',...
                        'loaded solution data?'];                
                uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                if ~strcmp(uChoice,'Yes')
                    % if the user cancelled, then exit the function
                    return
                end
            end            
            
            % creates a loadbar
            wStr = 'Clearing All Stored Data...';
            hProg = ProgressLoadbar(wStr);
            
            % resets the storage arrays
            obj.resetStorageArrays()
            obj.updateFullTabProps();     
            
            % disables all the buttons
            set(obj.hTxtC,'string',0)
            cellfun(@(x)(setObjEnable(x,0)),obj.hButC(1:3));
            setObjVisibility(obj.hTableG,0)            
            obj.setContinueProps(0)            
            
            % menu item property update
            obj.objB.setMenuEnable('menuScaleFactor',0);
            obj.objB.setMenuEnable('menuCombExpt',0);
            obj.objB.setMenuEnable('menuLoadExtnData',0);

            % disables the added experiment information fields
            obj.resetExptInfoTable();
            setTimeCycleMenuProps(obj.hFig,obj.sInfo);
            
            % creates the explorer trees for each file type
            obj.pathUpdate = false;
            for i = obj.getResetIndexArray()
                obj.createFileExplorerTree(i);
                pause(0.05);
            end

            % resets the solution file information
            obj.updateSolnFileInfo();            
            
            % if loading files through the analysis gui, then update the
            % experiment information for the other tabs
            obj.pathUpdate = true;
            hProg.StatusMessage = 'Resetting GUI Objects...';
            obj.objB.updateFullGUIExpt();
            
            % updates the tab index
            obj.iTab = iTab0;
            obj.isChange = true;
            
            % deletes the loadbar
            delete(hProg)            
            
        end
        
        % --- continue button callback function
        function buttonContinue(obj, ~, ~)
            
            obj.objB.menuCloseWindow([],[])
            
        end
        
        % --- hide stimuli protocol button callback function
        function buttonHideProtocol(obj, ~, ~)
            
            % sets the panel object visibility properties
            setObjVisibility(obj.hPanelLo,1)
            setObjVisibility(obj.hPanelD,1)
            setObjVisibility(obj.hPanelS,0)            
            
        end

        % --- group name table edit callback function
        function tableGroupEdit(obj, ~, evnt)
            
            % initialisations
            mStr = [];
            indNw = evnt.Indices;

            % retrieves the java object handle
            if isempty(obj.jTableG)
                obj.jTableG = getJavaTable(obj.hTableG);
            end
            
            % removes the selection highlight
            obj.jTableG.changeSelection(-1,-1,false,false);

            % determines if the current group/region is rejected
            isRejected = strcmp(evnt.PreviousData,'* REJECTED *');
            if ~isRejected
                % if not, determines if the new name is valid
                nwName = evnt.NewData;
                if chkDirString(nwName)
                    % if the new string is valid, then update the solution    
                    obj.sInfo{obj.iExp}.gName{indNw(1)} = nwName;
                    
                else
                    % case is the string is not valid
                    mStr = ['The group/region name cannot contain ',...
                            'a special character'];
                end       
            else
                % case is the region/group is rejected
                mStr = ['This group/region is rejected and ',...
                        'cannot be altered.'];
            end

            % if there was an error, then output it to screen and exit
            if ~isempty(mStr)
                % outputs the error message to screen
                waitfor(msgbox(mStr,'Invalid Group Name'));

                % resets the table back to the last valid name
                obj.hTableG.Data{indNw(1),indNw(2)} = evnt.PreviousData;

                % exits the function
                return
            end

            % resets the table background colours
            bgColT = obj.getTableBGColours(obj.sInfo{obj.iExp});
            obj.hTableG.BackgroundColor = bgColT;
            
            % updates the group names on the other tabs
            if obj.sType == 3
                obj.objB.updateGroupNames(1);
            end            

            % updates the change flag
            obj.isChange = true;            
            
        end
        
        % ---------------------------------------------- %        
        % --- EXPERIMENT INFORMATION TABLE FUNCTIONS --- %
        % ---------------------------------------------- %
        
        % --- retrieves the experiment information table data
        function tabData = getTableData(obj)

            % initialisations
            tabData = cell(length(obj.sInfo),1);

            % reads the data for each table row
            for i = 1:length(tabData)
                tabData{i} = obj.getExptTableRow(obj.sInfo{i});
            end

            % converts the data into a cell array
            tabData = cell2cell(tabData);

        end                        
        
        % --- updates the solution file/added experiments array
        function updateExptInfoTable(obj,hLoad)
            
            % other initialisations
            obj.tableUpdate = true;
            jTableMod = obj.jTableD.getModel;
            
            % removes the table selection
            obj.jTableD.changeSelection(-1,-1,false,false);
            
            % resets the enabled properties of the menu items
            obj.objB.setMenuEnable('menuScaleFactor',0);
            obj.objB.setMenuEnable('menuCombExpt',obj.nExp>1);
            
            % adds data to the table
            for i = 1:obj.nExp
                % adds the data for the new table row and bg colour index
                tabData = obj.getExptTableRow(obj.sInfo{i});
                if i > obj.jTableD.getRowCount
                    jTableMod.addRow(tabData)
                    for j = 1:obj.jTableD.getColumnCount
                        % sets the background colours
                        obj.tabCR1.setCellBgColor(i-1,j-1,obj.gray);
                        obj.tabCR2.setCellBgColor(i-1,j-1,obj.gray);
                        
                        % sets the foreground colours
                        obj.tabCR1.setCellFgColor(i-1,j-1,obj.black);
                        obj.tabCR2.setCellFgColor(i-1,j-1,obj.black);
                    end
                else
                    % updates the table values
                    for j = 1:obj.jTableD.getColumnCount
                        nwStr = java.lang.String(tabData{j});
                        obj.jTableD.setValueAt(nwStr,i-1,j-1)
                    end
                end
            end
            
            % resets the column widths
            mStr = obj.resetExptTableBGColour(1);
            obj.resetColumnWidths()
            
            % repaints the table
            obj.jPanelD.repaint();
            obj.jTableD.repaint();
            
            % flag that the table update is complete
            pause(0.05)
            obj.tableUpdate = false;
            
            % deletes the loadbar
            if exist('hLoad','var'); delete(hLoad); end
            
            % outputs any message to screen (if they exist)
            if ~isempty(mStr)
                waitfor(msgbox(mStr,'Repeated File Names','modal'))
            end
            
        end         
        
        % --- resets all experiment information table
        function resetExptInfoTable(obj)

            % if the table is updating automatically, then exit
            if obj.tableUpdate
                return
            end

            % sets the table update flag to on
            obj.tableUpdate = true;            
            
            % object retrieval
            jTableMod = obj.jTableD.getModel();

            % removes the table selection
            obj.jTableD.changeSelection(-1,-1,false,false)

            % removes/clears all the fields in the table
            for i = obj.jTableD.getRowCount:-1:1
                if i > obj.nExpMax
                    jTableMod.removeRow(obj.jTableD.getRowCount-1)
                else
                    obj.clearExptInfoTableRow(i)  
                end
            end
            
            % repaints the table
            obj.jPanelD.repaint;
            obj.jTableD.repaint;
            pause(0.05);

            % resets the table update flag
            obj.tableUpdate = false;

        end
        
        % --- clears the information on a table row
        function clearExptInfoTableRow(obj,iRow)

            % resets the cells in the table row
            for j = 1:obj.jTableD.getColumnCount
                % removes the value in the cell
                obj.jTableD.setValueAt([],iRow-1,j-1)

                % resets the cell background colour
                if j == 1
                    obj.tabCR1.setCellBgColor(iRow-1,j-1,obj.gray)
                else
                    obj.tabCR2.setCellBgColor(iRow-1,j-1,obj.gray)
                end
            end

        end        
        
        % --- updates the table background row colour
        function setExptTableRowColour(obj,iRow,rwCol)

            % sets the experiment colour
            obj.tabCR1.setCellBgColor(iRow-1,0,rwCol);

            % sets the other column colours
            for iCol = 2:obj.jTableD.getColumnCount
                obj.tabCR2.setCellBgColor(iRow-1,iCol-1,rwCol)
            end

        end                

        % --- resets the experiment information table background colour
        function mStr = resetExptTableBGColour(obj,isLoading)
            
            % determines the unique experiment name indices
            [iGrpU,mStr] = obj.detUniqueNameIndices(isLoading);
            
            % resets the table background colours
            for i = 1:length(iGrpU)
                if i == 1
                    rwCol = getJavaColour([0.75,1,0.75]);
                else
                    rwCol = getJavaColour([1,0.75,0.75]);
                end
                
                % sets the colour for all matching experiments in the group
                for j = iGrpU{i}(:)'
                    obj.setExptTableRowColour(j,rwCol)
                end
            end
            
        end        
        
        % --- resets the column widths
        function resetColumnWidths(obj)

            % other intialisations
            cWid = [176,50,55,60,60,60,78];
            if obj.jTableD.getRowCount > obj.nExpMax
                % other intialisations
                cWid = (cWid - 20/length(cWid));
            end

            for cID = 1:obj.jTableD.getColumnCount
                cMdl = obj.jTableD.getColumnModel.getColumn(cID-1);
                cMdl.setMinWidth(cWid(cID))
            end

        end               
        
        % ----------------------------------------------- %
        % --- FIGURE/OBJECT PROPERTY UPDATE FUNCTIONS --- %
        % ----------------------------------------------- %
        
        % --- updates the solution file GUI
        function updateSolnFileGUI(obj,hasFile)
            
            % sets the default input argument
            if ~exist('hasFile','var'); hasFile = true; end
            
            % creates a loadbar
            hLoad = ProgressLoadbar('Updating Loaded Data Information...');
            
            % sets the full tab group enabled properties (if it exists)
            obj.nExp = length(obj.sInfo);
            obj.updateFullTabProps();

            % recreates the explorer tree
            obj.createFileExplorerTree(obj.iTab)
            if ~hasFile; return; end

            % if loading files through the analysis gui, then update the
            % experiment information for the other tabs
            obj.objB.updateFullGUIExpt();
                                  
            % updates the solution file/added experiments array
            obj.updateExptInfoTable(hLoad)
            obj.updateSolnFileInfo();

            % updates the added experiment objects
            setPanelProps(obj.hPanelD,'on');
            set(obj.hTxtC,'string',num2str(obj.nExp),'enable','on')
            setObjEnable(obj.hButC{3},'on');
            obj.setContinueProps('on')            
            
            % updates the change flag
            obj.isChange = true;    
            setTimeCycleMenuProps(obj.hFig,obj.sInfo)            
            
        end                
        
        % --- sets the continue button properties (based on the state)
        function setContinueProps(obj, State)
            
            % converts 
            if ischar(State)
                State = strcmp(State,'on');
            end            

            % sets the button properties based on the state
            if State
                % case is enabling the button
                bCol = [1,0,0];
                
            else
                % case is disabling the button
                bCol = 0.94*[1,1,1];
            end
            
            % updates the button enabled props
            setObjEnable(obj.hButC{4},State);
            set(obj.hButC{4},'BackgroundColor',bCol)
            
        end        
        
        % --- updates the add solution file button properties
        function updateAddButtonProps(obj,canAdd)
            
            % add file button properties
            setObjEnable(obj.hButT{2},canAdd)
            set(obj.hButT{2},'BackGroundColor',obj.bgCol{1+canAdd});
            
        end        

        % --- resets the full tab group object properties
        function updateFullTabProps(obj)
            
            if obj.sType == 3
                % resets the full gui tab enabled properties (if they exist)
                obj.jTabGrp.setEnabledAt(1,obj.nExp>0);  
                drawnow

                if obj.jTabGrp.getTabCount == 3
                    obj.jTabGrp.setEnabledAt(2,obj.nExp>0);
                end            
            end

        end                        

        % --- updates the solution file information
        function updateSolnFileInfo(obj,nSel)
            
            % sets the default input arguments
            if ~exist('nSel','var')
                nSel = obj.getSelectedNodeCount();
            end
            
            % sets the new text label strings
            if isempty(obj.sDir{obj.iTab})
                % case is no file explorer has been created
                txtStr = repmat({'N/A'},1,length(obj.txtTag));
                txtStrTT = '';
            else
                % case is file explorer has been created
                txtStr = {num2str(length(obj.sFile{obj.iTab})),...
                    num2str(nSel),obj.sDir{obj.iTab}};
                txtStrTT = obj.sDir{obj.iTab};
            end
            
            % updates the object strings/properties
            isOn = ~isempty(obj.sDir{obj.iTab});
            cellfun(@(x)(setObjEnable(x,isOn)),obj.hTxtT);
            cellfun(@(x,y)(set(x,'String',y)),obj.hTxtT,txtStr(:));
            set(obj.hTxtT{3},'tooltipstring',txtStrTT)
            
        end
        
        % --- updates the experiment information fields
        function updateGroupTableProps(obj)
            
            % if there is no selection, then exit
            if isempty(obj.iExp); return; end
            
            % retrieves the solution file information struct
            % (for the current expt)
            sInfoNw = obj.sInfo{obj.iExp};
            
            % sets the experiment dependent fields
            setObjEnable(obj.hButC{2},sInfoNw.hasStim);
            
            % resets the table background colours
            bgColG = obj.getTableBGColours(sInfoNw);
            obj.hTableG.BackgroundColor = bgColG;
            
            % sets the table data/field property values
            if sInfoNw.snTot.iMov.is2D
                % case is a 2D experiment
                
                % sets the final data/column headers
                Data = [num2cell((1:length(sInfoNw.gName))'),sInfoNw.gName];
                cHdr = {'Group #','Group Name'};
                cWid = {70,150};
            else
                % case is a 1D experiment
                
                % sets the row/column index information
                pInfo = sInfoNw.snTot.iMov.pInfo;
                Ar = meshgrid(1:pInfo.nRow,1:pInfo.nCol);
                Ac = meshgrid(1:pInfo.nCol,1:pInfo.nRow);
                B = [Ar(:),arr2vec(Ac')];
                
                % sets the final data/column headers
                Data = [num2cell(B),sInfoNw.gName(:)];
                cHdr = {'Row','Col','Group Name'};
                cWid = {35,35,150};
            end
            
            % converts numerical values to strings
            isN = cellfun(@isnumeric,Data);
            Data(isN) = cellfun(@num2str,Data(isN),'un',0);
            
            % sets the group name table properties
            cEdit = setGroup(length(cHdr),size(cHdr));
            set(obj.hTableG,'Data',Data,'ColumnName',cHdr,...
                'ColumnEditable',cEdit,'ColumnWidth',cWid,...
                'Enable','on','Visible','on')
            autoResizeTableColumns(obj.hTableG)
            
        end                
        
        % --- resets the stimuli axes properties
        function resetStimAxes(obj)

            % parameters
            fAlpha = 0.2;
            tLim = [120,6,1e6];
            [axSz,lblSz] = deal(16,20);
            tStr0 = {'m','h','d'};
            tUnits0 = {'Mins','Hours','Days'};
            sTrainEx = obj.sInfo{obj.iExp}.snTot.sTrainEx;

            % sets the 
            [devType,~,iC] = unique(sTrainEx.sTrain(1).devType,'stable');
            nCh = NaN(length(devType),1);
            
            % sets up the device type string
            for iCh = 1:length(devType)
                % calculates the number of motor channels 
                if startsWith(devType{iCh},'Motor')
                    nCh(iCh) = sum(iC == iCh);
                end

                % strips of the number from the device string
                devType{iCh} = regexprep(devType{iCh},'[0-9]','');
            end

            % sets up the channel colours
            chCol = flip(getChannelCol(devType,nCh));            
            
            % determines the experiment finish time
            TexpF = obj.sInfo{obj.iExp}.snTot.T{end}(end);            
            
            % determines the experiment units string
            iLim = find(cellfun(@(x)...
                    (convertTime(TexpF,'s',x)),tStr0) < tLim,1,'first');
            [tStr,tUnits] = deal(tStr0{iLim},tUnits0{iLim});
            tLim = [0,TexpF]*getTimeMultiplier(tStr,'s');
            tUnitsExp = obj.sInfo{obj.iExp}.snTot.iExpt.Timing.TexpU(1);

            % clears the axes and turns it on
            cla(obj.hAxS)
            axis(obj.hAxS,'on');       
            hold(obj.hAxS,'on');
            axis('ij');

            % calculates the scaled 
            for i = 1:length(sTrainEx.sTrain)
                % sets up the signal
                sPara = sTrainEx.sParaEx(i);
                sTrain = sTrainEx.sTrain(i);
                xyData0 = setupFullExptSignal(obj,sTrain,sPara);

                % scales the x/y coordinates for the axes time scale
                tMlt = getTimeMultiplier(tStr,lower(tUnitsExp));
                tOfs = getTimeMultiplier(tStr,sPara.tOfsU)*sPara.tOfs;    
                xyData = cellfun(@(x)(colAdd...
                            (colMult(x,1,tMlt),1,tOfs)),xyData0,'un',0);        

                % plots the non-empty signals
                for iCh = 1:length(xyData)
                    % plots the channel region markers
                    if iCh < length(xyData)
                        plot(obj.hAxS,tLim,iCh*[1,1],'k--','linewidth',1)
                    end

                    % creates a new patch (if there is data)
                    if ~isempty(xyData{iCh})
                        [xx,yy] = deal(xyData{iCh}(:,1),xyData{iCh}(:,2));
                        yy = (1 - (yy - floor(min(yy)))) + (iCh-1);
                        patch(obj.hAxS,xx([1:end,1]),yy([1:end,1]),...
                            chCol{iCh},'EdgeColor',chCol{iCh},...
                            'FaceAlpha',fAlpha,'LineWidth',1);
                    end
                end   

                % sets the axis limits (first stimuli block only)
                if i == 1
                    % sets the axis properties
                    yTick = (1:length(xyData)) - 0.5;
                    yTickLbl = cellfun(@(x,y)(sprintf('%s (%s)',y,x(1))),...
                                      sTrain.devType,sTrain.chName,'un',0);
                    set(obj.hAxS,'xlim',tLim,'ylim',[0,length(xyData)],...
                            'ytick',yTick,'yticklabel',yTickLbl,...
                            'FontUnits','Pixels','FontSize',axSz,...
                            'FontWeight','bold','box','on')

                    % sets the axis/labels
                    xLbl = sprintf('Time (%s)',tUnits);
                    xlabel(obj.hAxS,xLbl,'FontWeight','bold',...
                            'FontUnits','Pixels','FontSize',lblSz)
                end
            end

            % turns the axis hold off
            hold(obj.hAxS,'off');

        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- determines the unique name groupings from the experiment name list
        function [iGrpU,mStr] = detUniqueNameIndices(obj,isLoading)

            % initialisations
            mStr = [];
            expFile = cellfun(@(x)(x.expFile),obj.sInfo,'un',0);

            % determines the unique experiment file names
            [expFileU,~,iC] = unique(expFile,'stable');
            if length(expFileU) < length(expFile)
                % case is there are repeated experiment names   
                iGrp0 = arrayfun(@(x)(find(iC==x)),(1:max(iC))','un',0);

                % determines the repeat experiment file names
                ii = cellfun('length',iGrp0) == 1;
                expFileR = expFileU(~ii);

                % sets the 
                if any(ii)
                    iGrpU = [cell2mat(iGrp0(ii));iGrp0(~ii)]; 
                else
                    iGrpU = [{[]};iGrp0(~ii)];
                end

                % if loading the files, output a message to screen
                if isLoading
                    % sets the message string
                    mStr = sprintf(['The following experiment names ',...
                                    'from the loaded solution files ',...
                                    'are repeated:\n\n']); 
                    for i = 1:length(expFileR)
                        mStr = sprintf('%s %s "%s"\n',...
                                            mStr,char(8594),expFileR{i});
                    end          
                    mStr = sprintf(['%s\nYou will need to alter these ',...
                                    'file names before finishing ',...
                                    'loading the data.'],mStr);                            
                end    
            else
                % otherwise, all group names are unique
                iGrpU = {1:length(obj.sInfo)};
            end

        end                
        
        % --- appends the new solution information 
        function appendSolnInfo(obj,snTot,sFile,expFile)

            % memory allocation
            sInfoNw = {struct('snTot',[],'sFile',[],'iFile',1,...
                              'iTab',obj.iTab,'iID',[],'iPara',[],...
                              'gName',[],'expFile',[],'expInfo',[],...
                              'is2D',false,'hasStim',false,'tDurS',[],...
                              'tDur',[])};

            % determines the index of the next available ID flag
            iIDnw = obj.getNextSolnIndex(obj.sInfo);

            % updates the solution information (based on the file type)
            switch obj.iTab
                case {1,2}
                    % case is the video/single experiment file
                    sInfoNw{1}.snTot = snTot;
                    sInfoNw{1}.sFile = sFile;
                    sInfoNw{1}.iID = iIDnw;

                    % sets the experiment file name
                    if obj.iTab == 1
                        sInfoNw{1}.expFile = getFinalDirString(sFile);
                    else
                        sInfoNw{1}.expFile = getFileName(sFile);
                    end

                case {3,4}
                    % case is the multi-experiment files
                    nFile = length(snTot);
                    sInfoNw = repmat(sInfoNw,nFile,1);

                    % retrieves the info for each of the solution files
                    for i = 1:nFile
                        sInfoNw{i}.snTot = snTot(i);
                        sInfoNw{i}.sFile = sFile;
                        sInfoNw{i}.expFile = expFile{i};
                        sInfoNw{i}.iID = iIDnw+(i-1);
                    end
            end

            % calculates the signal duration
            for i = 1:length(sInfoNw)
                % sets the expt field/stimuli fields
                sInfoNw{i}.is2D = sInfoNw{i}.snTot.iMov.is2D;
                sInfoNw{i}.hasStim = ~isempty(sInfoNw{i}.snTot.stimP);
                    
                % sets the experiment duration in seconds
                t0 = sInfoNw{i}.snTot.T{1}(1);
                t1 = sInfoNw{i}.snTot.T{end}(end);                
                sInfoNw{i}.tDur = ceil(t1-t0);

                % sets the duration string
                sInfoNw{i}.tDurS = getExptDurString(sInfoNw{i}.tDur);

                % initialises the timing parameter struct
                sInfoNw{i}.iPara = obj.initParaStruct(sInfoNw{i}.snTot);
                sInfoNw{i}.gName = getRegionGroupNames(sInfoNw{i}.snTot);
                sInfoNw{i}.expInfo = obj.initExptInfo(sInfoNw{i});   
                sInfoNw{i}.snTot.iMov.ok = ...
                                ~strcmp(sInfoNw{i}.gName,'* REJECTED *');
            end

            % udpates the solution info data struct
            obj.sInfo = [obj.sInfo;sInfoNw(:)];
            obj.nExp = length(obj.sInfo);

        end                        
        
        % --- retrieves the selected node count
        function nSel = getSelectedNodeCount(obj)
            
            % sets the new selected movie count
            if obj.objFT{obj.iTab}.ok
                iSel = obj.objFT{obj.iTab}.getCurrentSelectedNodes();
                nSel = length(iSel);
                
            else
                % case is there is no file information
                nSel = 0;
            end
            
        end        
        
        % --- sets the explorer tree reset index array
        function indReset = getResetIndexArray(obj)

            % determines the valid solution file tab types
            isOK = ~cellfun('isempty',obj.sDir);
            isOK(obj.iTab) = false;

            % sets the final reset index array
            indReset = [find(isOK);obj.iTab]';

        end                
        
        % --- resets the storage arrays within the GUI
        function resetStorageArrays(obj)
            
            % resets the solution information struct (reset only)            
            obj.nExp = 0;
            obj.sInfo = [];                 
            obj.sFile = cell(obj.nTabT,1);
        
        end                
        
        % --- deletes the class object
        function deleteClass(obj)
            
            % deletes the explorer tree class objects
            ii = ~cellfun('isempty',obj.objFT);
            cellfun(@(x)(x.deleteClass()),obj.objFT(ii));
            
            % deletes the class object
            clear obj
            
        end
        
    end
    
    % static class methods
    methods (Static)

        % ------------------------- %
        % --- DATA STRUCT SETUP --- %
        % ------------------------- %
        
        % --- initialises the parameter struct
        function iPara = initParaStruct(snTot)

            % initialises the parameter struct
            nVid = length(snTot.T);
            wState = warning('off','all');
            iPara = struct('iApp',1,'indS',[],'indF',[],...
                           'Ts',[],'Tf',[],'Ts0',[],'Tf0',[]);

            % sets the start/finish indices (wrt the videos)
            T0 = snTot.iExpt(1).Timing.T0;
            iPara.indS = [1 1];
            iPara.indF = [nVid length(snTot.T{end})];

            % sets the start/finish times
            [iPara.Ts,iPara.Ts0] = deal(calcTimeString(T0,snTot.T{1}(1)));
            [iPara.Tf,iPara.Tf0] = ...
                               deal(calcTimeString(T0,snTot.T{end}(end)));

            % resets the warning mode
            warning(wState);
                           
        end
        
        % --- initialises the solution file information --- %
        function expInfo = initExptInfo(sInfo)

            % retrieves the solution data struct
            snTot = sInfo.snTot;
            iMov = snTot.iMov;

            % sets the experimental case string
            if detMltTrkStatus(iMov)
                % case is multi-fly tracking
                eCase = 'Multi-Fly Tracking';
            else
                % case is single-fly tracking
                switch snTot.iExpt.Info.Type
                    case {'RecordStim','StimRecord'}
                        eCase = 'Recording & Stimulus';        
                    case ('RecordOnly')
                        eCase = 'Recording Only';
                    case ('StimOnly')
                        eCase = 'Stimuli Only';        
                    case ('RTTrack')
                        eCase = 'Real-Time Tracking';
                end
            end

            % updates the solution information (based on the file type)
            sName = sInfo.expFile;
            switch sInfo.iTab
                case {1,2}
                    % case is the video/single experiment file
                    if sInfo.iTab == 1
                        sDirTT = sInfo.sFile;
                    else
                        sDirTT = fileparts(sInfo.sFile);
                    end

                case {3,4}
                    % case is the multi-experiment files
                    sDirTT = fileparts(sInfo.sFile);
            end

            % calculates the experiment duration (rounded to nearest min)
            Tfin = floor(snTot.T{end}(end));
            dT = roundP(Tfin-snTot.T{1}(1));
            [~,~,Tstr] = calcTimeDifference(dT);

            % calculates the experiment count/duration strings
            nExpt = num2str(length(snTot.T));
            TstrTot = sprintf('%s:%s:%s:%s',Tstr{1},Tstr{2},Tstr{3},Tstr{4});
            T0vec = calcTimeString(snTot.iExpt.Timing.T0,0);
            Tfvec = calcTimeString(snTot.iExpt.Timing.T0,Tfin);
            txtStart = datestr(sInfo.iPara.Ts0,'mmm dd, YYYY HH:MM AM');
            txtFinish = datestr(sInfo.iPara.Tf0,'mmm dd, YYYY HH:MM AM');

            % sets the expt setup dependent fields
            if iMov.is2D
                % case is a 2D experiment
                if isempty(iMov.autoP)
                    setupType = 'No Shape';
                else
                    switch iMov.autoP.Type
                        case {'Circle','Rectangle'}
                            setupType = iMov.autoP.Type;
                        case 'GeneralR'
                            setupType = 'General Repeating';            
                        case {'GeneralC','General'}
                            setupType = 'General Custom';
                    end
                end

                % sets the full string
                exptStr = sprintf('2D Grid Assay (%s Regions)',setupType);
                regConfig = sprintf('%i x %i Grid Assay',...
                                    size(iMov.flyok,1),iMov.nCol);
            else
                % sets the experiment string
                exptStr = '1D Test-Tube Assay';
                regConfig = sprintf('%i x %i Assay (Max Count = %i)',...
                        iMov.pInfo.nRow,iMov.pInfo.nCol,iMov.pInfo.nFlyMx);
            end
            
            % removes any sub-second values
            T0vec(end) = roundP(T0vec(end));
            Tfvec(end) = floor(Tfvec(end));

            % sets the experiment information fields
            expInfo = struct('ExptType',eCase,'ExptDur',TstrTot,...
                             'SolnDur',TstrTot,'SolnCount',nExpt,...
                             'RegionConfig',regConfig,'dT',dT,...
                             'StartTime',txtStart,'FinishTime',txtFinish,...
                             'SolnDir',sName,'SolnDirTT',sDirTT,...
                             'T0vec',T0vec,'Tfvec',Tfvec,...
                             'SetupType',exptStr);          

        end        
        
        % --------------------------- %
        % --- FILE/PATH FUNCTIONS --- %
        % --------------------------- %        
        
        % --- group the selected files by their unique directories
        function [fDirS,fNameS] = groupSelectedFiles(sFile)
            
            % --- strips out the numeric components of the name string
            function fStrNN = getNonNumericString(fStr)
                
                % splits the string into alphanumeric characters
                fStr = strrep(fStr,'_',' ');
                fStrSp = rmvEmptyCells(regexp(fStr,'\W','split'));
                isNN = isnan(cellfun(@str2double,fStrSp));
                
                % rejoins the final string
                fStrNN = strjoin(fStrSp(isNN),' ');
                
            end
            
            % retrieves the file directory/name strings
            fDir0 = cellfun(@(x)(fileparts(x)),sFile,'un',0);
            fName0 = cellfun(@(x)(getFileName(x,1)),sFile,'un',0);
            
            % groups the file names/directories into their unique groups
            [fDirS,~,iC] = unique(fDir0);
            fNameS = arrayfun(@(x)(fName0(iC==x)),1:max(iC),'un',0);
            
            % checks each directory to ensure that the experiments naming
            % conventions (within experiments) are consistent
            for i = 1:length(fDirS)
                % splits the the file names into their non-numeric parts
                fNameSB = cellfun(@(x)...
                    (getNonNumericString(x)),fNameS{i},'un',0);
                [fNameSBU,~,iC] = unique(fNameSB,'stable');
                
                % determines if there is more than one experiment grouping
                % in the current directory
                nFName = length(fNameSBU);
                if nFName == 1
                    % if not, then use the origin
                    [fDirS{i},fNameS{i}] = deal(fDirS(i),fNameS(i));
                else
                    xiF = (1:nFName)';
                    fDirS{i} = repmat(fDirS(i),nFName,1);
                    fNameS{i} = arrayfun(@(x)(fNameS{i}(iC==x)),xiF,'un',0);
                end
            end
            
            % sets the final directory/file name arrays
            fDirS = cell2cell(fDirS(:));
            fNameS = cell2cell(fNameS(:));
            
        end        
        
        % --------------------------------------- %
        % --- STRING/PROPERTY SETUP FUNCTIONS --- %
        % --------------------------------------- %        
        
        % --- retrieves the experiment table row data
        function rowData = getExptTableRow(sInfoEx)

            % initialisations
            pFileStr = 'N/A';
            exStr = {'1D','2D','MT'};
            typeStr = {'soln','ssol','msol','other'};

            % sets the solution file type strings/fields
            switch sInfoEx.iTab
                case 1
                    % case is data from a video file directory
                    pFileStr = getFinalDirString(sInfoEx.sFile,1);

                case {3,4}
                    % case is data from a multi-expt file
                    pFileStr = getFileName(sInfoEx.sFile);

            end

            % sets up the stimuli string
            if sInfoEx.hasStim
                % case is the experiment has stimuli
                devStr = fieldnames(sInfoEx.snTot.stimP);
                stimStr = sprintf('%s',strjoin(devStr,'/'));
            else
                % case is the experiment has no stimuli
                stimStr = 'No Stimuli';
            end

            % sets the experiment type flag
            if detMltTrkStatus(sInfoEx.snTot.iMov)
                % case is multi-tracking
                iEx = 3;
            else
                % case is single tracking
                iEx = 1 + sInfoEx.is2D;
            end            
            
            % sets the 
            rowData = cell(1,6);
            rowData{1} = sInfoEx.expFile;
            rowData{2} = pFileStr;
            rowData{3} = typeStr{sInfoEx.iTab};
            rowData{4} = exStr{iEx};
            rowData{5} = stimStr;
            rowData{6} = sInfoEx.tDurS;

        end        

        % --- determines the next solution file index
        function iIDnw = getNextSolnIndex(sInfo)

            if isempty(sInfo)
                % there is no stored data, so start index at 1
                iIDnw = 1;
            else
                % case is there is stored data, so increment the max ID flag
                iIDnw = max(cellfun(@(x)(x.iID),sInfo)) + 1;
            end        
        
        end        
        
        % --- retrieves the table background colours
        function [bgCol,iGrpNw] = getTableBGColours(sInfo)
            
            % parameters
            grayCol = 0.81;
            
            % retrieves the unique group names from the list
            [gName,~,iGrpNw] = unique(sInfo.gName,'stable');
            isOK = sInfo.snTot.iMov.ok & ...
                ~strcmp(sInfo.gName,'* REJECTED *');
            
            % sets the background colour based on the unique matche list
            tCol = getAllGroupColours(length(gName),1);
            bgCol = tCol(iGrpNw,:);
            bgCol(~isOK,:) = grayCol;
            
        end                
        
        % --- resets the video/stimuli times
        function snTot = resetVideoAndStimTiming(snTot)
        
            % sets the start/finish times
            [T0,T1] = deal(roundP(max(0,snTot.T{1}(1))),snTot.T{end}(end));
            
            % resets the start time of the experiment
            dN = datenum(snTot.iExpt.Timing.T0);            
            snTot.iExpt.Timing.T0 = datevec(addtodate(dN,T0,'s'));   
            
            % offsets the video time stamps
            snTot.T = cellfun(@(x)(x-T0),snTot.T,'un',0);

            % resets stimuli times (only if stimuli is provided)
            if ~isempty(snTot.stimP)
                dType = fieldnames(snTot.stimP);
                for i = 1:length(dType)
                    % retrieves the device stimuli parameter sub-struct
                    dStim = getStructField(snTot.stimP,dType{i});
                    
                    % updates each of the stimuli times
                    chType = fieldnames(dStim);
                    for j = 1:length(chType)
                        % updates the start/stop stimuli times
                        chStim = getStructField(dStim,chType{j});
                        [Ts,Tf] = deal(chStim.Ts,chStim.Tf);
                        
                        % updates the start/finish times
                        ii = (Tf >= T0) & (Ts <= T1);
                        chStim.iStim = chStim.iStim(ii);
                        chStim.Ts = max(0,Ts(ii)-T0);
                        chStim.Tf = min(T1,Tf(ii)-T0);                       
                        dStim = setStructField(dStim,chType{j},chStim);
                    end
                    
                    % updates the device stimuli parameter sub-struct
                    snTot.stimP = ...
                            setStructField(snTot.stimP,dType{i},dStim);
                end
            end
            
        end                
        
    end
    
    % private class methods
    methods (Access = private)
        
        % --- sets a class object field
        function SetDispatch(obj, propname, varargin)
            
            obj.objB.(propname) = varargin{:};
            
        end
        
        % --- gets a class object field
        function varargout = GetDispatch(obj, propname)
            
            varargout{:} = obj.objB.(propname);
            
        end
        
    end         
    
end