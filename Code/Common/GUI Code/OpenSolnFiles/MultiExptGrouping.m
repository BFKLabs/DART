classdef MultiExptGrouping < handle & dynamicprops
    
    % class properties
    properties
        
        % input arguments
        iTabP
        hPanelG
        hPanelR
        
        % main class objects
        hTab
        hPanel        
        
        % compatible group list panel objects
        hPanelGL
        hTabGrpGL
        jTabGrpGL
        hTabGL
        hListGL
        
        % total information panels objects
        hPanelTI
        hTabGrpTI
        jTabGrpTI
        hTabTI
        
        % grouping criteria panel objects
        hPanelGC
        hChkGC
        hEditGC
        
        % final group name panel objects
        hPanelRN
        hTableRN
        jTableRN
        hButRN        
        
        % region/group name link panel objects
        hPanelRL
        hTableRL      
        
        % compatible experiment panel objects
        hPanelC
        hTableC
        jTableC
        
        % comparison table class fields
        tabCR1
        tabCR2          
        tCol        
        
        % fixed dimension class field               
        hghtPanelR = 185;
        hghtPanelC = 250;
        hghtPanelTI = 150;        
        widPanelGC = 185;
        widPanelRL = 470;
        widPanelTI = 600;
        widTxtGC = 115;
        
        % calculated dimension class field
        hghtPanelG
        hghtPanelGI
        hghtPanelRI
        widPanelI
        widPanelGL
        widPanelRN
        widTabGrpGL
        hghtTabGrpGL
        hghtTableR
        widTableRN
        widTableRL
        widChkGC
        widTableC
        hghtTableC        
        
        % other class fields        
        iExp = 1;
        nRow
        nHdr
        exptCol        
        
        % boolean class fields
        isSaving
        tableUpdate
        
        % static scalar class fields  
        nTabTI = 2;
        nChkGC = 5;
        nRowTR = 6;
        nButRN = 2;
        nExpMax = 7;
        
        % static string class fields
        regStr = '* REJECTED *';
        tHdrG = 'COMPATIBLE EXPERIMENT GROUPS';
        tHdrGC = 'GROUPING CRITERIA';
        tHdrR = 'REGION GROUP NAMING';
        tHdrRN = 'FINAL GROUP NAMES';
        tHdrRL = 'ORIGINAL/FINAL GROUP NAME LINK';
        tHdrC = 'EXPERIMENT COMPATIBILITY';
        cStrTG = 'matlab.ui.container.TabGroup'; 
        
        % cell array class fields
        tabStr = {'Experiment Comparison','Group Naming'};
        
    end
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end  
    
    % class methods
    methods
        
        % --- class constructor
        function obj = MultiExptGrouping(objB,iTabP,isSaving)
            
            % sets the input arguments
            obj.objB = objB;
            obj.iTabP = iTabP;
            obj.isSaving = isSaving;
            
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
            fldStr = {'hFigM','sInfo','cObj','hParent','tHdrTG',...
                      'gName','gName0','gNameU','expDir','expName',...
                      'dX','hghtBut','hghtChk','hghtRow','hghtHdr',...
                      'fSzL','fSz','hghtHdrTG','nExp','iProg',...
                      'white','black','gray','redFaded','sType',...
                      'blueFaded','greenFaded','isChange'};
            
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
            obj.hChkGC = cell(obj.nChkGC,1);
            obj.hButRN = cell(obj.nButRN,1);            
            
            % field initialisations
            obj.nExp = length(obj.sInfo);
            obj.cObj = ExptCompObj(obj.sInfo,obj.isSaving);
            obj.exptCol = 1;                       
            
            % reshapes the solution file information
            for i = 1:length(obj.sInfo)
                obj.sInfo{i}.snTot = reshapeSolnStruct...
                                (obj.sInfo{i}.snTot,obj.sInfo{i}.iPara);
            end                
            
            % sets the original group names            
            if ~isempty(obj.sInfo)
                [obj.gName,obj.gName0] = ...
                    deal(cellfun(@(x)(x.gName),obj.sInfo,'un',0));
            end
                    
            % use specific property field initialisation
            if obj.isSaving
                % case is for multi-expt saving
                obj.nRow = getappdata(obj.hFigM,'nRow');        
                obj.hTabTI = cell(obj.nTabTI,1);
                
            else
                % case is for analysis
                obj.nRow = 6;
            end            
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %    
            
            % panel width calculations
            obj.widPanelI = pPos(3) - 2*obj.dX;  
            
            % calculates the compatible group panel height
            obj.hghtPanelGI = obj.dX + ...
                obj.hghtRow + obj.hghtHdr*(1 + obj.nChkGC);
            obj.hghtPanelG = obj.dX/2 + obj.hghtHdr + obj.hghtPanelGI;            
            
            % use specific object dimension calculations
            if obj.isSaving
                % case is running via multi-experiment saving
                
                % calculates the compatible experiment panel dimensions
                obj.hghtTableC = calcTableHeight(obj.nRow) + obj.dX;
                obj.hghtPanelC = obj.hghtTableC + obj.dX;

                % calculates the region name table dimensions
                obj.widPanelRL = 340;
                obj.hghtTableR = calcTableHeight(obj.nRow-1);
                obj.hghtPanelRI = obj.hghtPanelC;
                
                % recalculates the panel height
                obj.hghtPanelTI = obj.hghtPanelC + obj.hghtRow + 2*obj.dX;
                obj.widPanelRN = obj.widPanelTI - ...
                    (2.5*obj.dX + obj.widPanelRL);                
                
            else
                % case is running via analysis
                
                % calculates the region name/link panel height
                obj.hghtPanelRI = obj.hghtPanelR - ...
                    (obj.dX/2 + obj.hghtHdr + 3);                
                
                % calculates the compatible experiment panel dimensions
                obj.hghtPanelC = pPos(4) - ...
                    (2.5*obj.dX + obj.hghtPanelG + obj.hghtPanelR);
                obj.hghtTableC = obj.hghtPanelC - (obj.dX + obj.hghtHdr);
                obj.widTableC = obj.widPanelI - 1.5*obj.dX;
                
                % calculates the region name table dimensions
                obj.hghtTableR = calcTableHeight(obj.nRowTR);
                obj.widPanelRN = obj.widPanelI - ...
                    (1.5*obj.dX + obj.widPanelRL);                
            end            
            
            % calculated dimension class field
            obj.widChkGC = obj.widPanelGC - 2*obj.dX;
            obj.widPanelGL = obj.widPanelI - (1.5*obj.dX + obj.widPanelGC);            

            % region name/link table width dimension calculations
            obj.widTableRN = obj.widPanelRN - (2*obj.dX + obj.hghtBut);
            obj.widTableRL = obj.widPanelRL - 1.5*obj.dX;            
            
            % calculates the tab group dimensions
            obj.widTabGrpGL = obj.widPanelGL - obj.dX;
            obj.hghtTabGrpGL = obj.hghtPanelGI - obj.hghtHdr;                        
            
        end
        
        % --- initialises the class fields
        function initClassObjects(obj)

            % ------------------------------ %
            % --- MAIN SUB-PANEL OBJECTS --- %
            % ------------------------------ %
            
            % sets up the total information panel (saving only)
            if obj.isSaving
                obj.setupTotalInfoPanel();
            end
            
            % sets up the sub-panel objects
            obj.setupExptCompatibilityPanel();
            obj.setupGroupNamePanels();            
            obj.setupCompatibleGroupPanels();
            
            if ~isempty(obj.sInfo)                
                % runs the initial criteria check
                obj.cObj.getInitCritCheck();
                indG = obj.cObj.detCompatibleExpts();
                obj.resetFinalGroupNameArrays(indG)  
                
                % updates the grouping lists
                obj.updateGroupLists(indG)
            end                        
            
        end
        
        % --- creates the experiment information table
        function createExptInfoTable(obj)
            
            % java imports
            import javax.swing.JTable
            import javax.swing.JScrollPane
            
            % sets the table header strings
            cWid = [165,45,55,60,60,100,78];            
            hdrStr = {createTableHdrString({'Experiment Name'}),...
                      createTableHdrString({'Setup','Config'}),...
                      createTableHdrString({'Region','Shape'}),...
                      createTableHdrString({'Stimuli','Devices'}),...
                      createTableHdrString({'Exact','Protocol?'}),...
                      createTableHdrString({'Duration'}),...
                      createTableHdrString({'Compatible?'})};
                  
            % case specific updates
            switch obj.sType
                case 3
                    % case is running through analysis
                    cWid(1) = cWid(1) + 150;
            end
            
            % other intialisations  
            obj.nHdr = length(hdrStr);
            if obj.nExp > obj.nExpMax
                cWid = (cWid - 20/length(cWid));
            end              
                  
            % creates the base table object
            hTableEx = createUIObj('table',obj.hPanelC,'Rowname',[],...
                'CellSelectionCallback',@obj.tableExptCompSelect);
            
            % sets up the table data array
            tabData = obj.getTableData();

            % creates the java table object
            jScroll = findjobj(hTableEx);
            [jScroll, hContainer] = ...
                        createJavaComponent(jScroll,[],obj.hPanelC);
            
            % sets the container position
            if obj.isSaving
                % case is running via multi-experiment saving
                set(hContainer,'Units','Normalized','Position',[0,0,1,1])
                
            else
                % case is running via analysis
                pPosT = [obj.dX*[1,1]/2,obj.widTableC,obj.hghtTableC];
                set(hContainer,'Units','Pixels','Position',pPosT)
            end
                
            % creates the java table model
            obj.jTableC = jScroll.getViewport.getView;
            jTableMod = javax.swing.table.DefaultTableModel(tabData,hdrStr);
            obj.jTableC.setModel(jTableMod);

            % sets the table callback function
            cbFcn = @obj.tableExptCompEdit;
            jTableMod = handle(jTableMod,'callbackproperties');
            addJavaObjCallback(jTableMod,'TableChangedCallback',cbFcn);            
            
            % creates the table cell renderer
            obj.tabCR1 = ColoredFieldCellRenderer(obj.white);
            obj.tabCR2 = ColoredFieldCellRenderer(obj.white);

            % sets the table text to black
            for i = 1:size(tabData,1)
                for j = 1:size(tabData,2)
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
                cMdl = obj.jTableC.getColumnModel.getColumn(cID-1);
                cMdl.setMinWidth(cWid(cID))

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
            obj.jTableC.getTableHeader().setBackground(gridCol);
            obj.jTableC.setGridColor(gridCol);
            obj.jTableC.setShowGrid(true);

            % disables the resizing
            jTableHdr = obj.jTableC.getTableHeader(); 
            jTableHdr.setResizingAllowed(false); 
            jTableHdr.setReorderingAllowed(false);

            % repaints the table
            obj.jTableC.repaint()
            obj.jTableC.setAutoResizeMode(obj.jTableC.AUTO_RESIZE_ALL_COLUMNS)            
            
        end
        
        % ------------------------------------ %
        % --- PANEL OBJECT SETUP FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- sets up the total information panel objects
        function setupTotalInfoPanel(obj)            
            
            % initialisations
            cbFcnT = @obj.tabSelectedInfo;
            
            % creates the panel object
            pPos = [obj.dX*[1,1],obj.widPanelTI,obj.hghtPanelTI];
            obj.hPanelTI = createPanelObject(obj.hPanel,pPos);
            
            % creates the tabgroup object
            pPosTG = [obj.dX*[1,1]/2,pPos(3:4)-obj.dX];
            obj.hTabGrpTI = createUIObj(...
                'tabgroup',obj.hPanelTI,'Position',pPosTG);
            
            % creates the information tabs
            for i = 1:obj.nTabTI
                obj.hTabTI{i} = createUIObj('tab',obj.hTabGrpTI,...
                    'Title',obj.tabStr{i},'ButtonDownFcn',cbFcnT,...
                    'UserData',i);
            end            

            % creates the tab group java object and disables the panel
            obj.jTabGrpTI = getTabGroupJavaObj(obj.hTabGrpTI);
            obj.jTabGrpTI.setEnabledAt(1,0);            
            
        end                
        
        % --- sets up the experiment compatibility panel objects        
        function setupExptCompatibilityPanel(obj)
            
            % sets the parent object handle (based on use type)
            if obj.isSaving
                % case is for running via multi-expt saving
                [hObjP,wOfs,tHdr] = deal(obj.hTabTI{1},obj.dX/2,[]);
                
            else
                % case is for running via analysis
                [hObjP,wOfs,tHdr] = deal(obj.hPanel,obj.dX,obj.tHdrC);
            end
            
            % creates the panel object
            widP = hObjP.Position(3) - 2*wOfs;
            pPos = [wOfs*[1,1],widP,obj.hghtPanelC];
            obj.hPanelC = createPanelObject(hObjP,pPos,tHdr);
            
            % creates the experiment information table
            obj.createExptInfoTable();
            
        end
        
        % --- sets up the group name panel objects
        function setupGroupNamePanels(obj)
            
            if obj.isSaving
                % case is using via multi-expt saving
                
                % sets the parent object
                hObjP = obj.hTabTI{2};

            else
                % case is using via analysis
                
                % creates the panel object
                yPos = sum(obj.hPanelC.Position([2,4])) + obj.dX/2;
                pPos = [obj.dX,yPos,obj.widPanelI,obj.hghtPanelR];
                obj.hPanelR = createPanelObject(obj.hPanel,pPos,obj.tHdrR);
                
                % sets the parent object
                hObjP = obj.hPanelR;
            end
                
            % ------------------------------- %            
            % --- FINAL GROUP NAMES PANEL --- %
            % ------------------------------- %
            
            % initialisations
            cNameRN = {'Group Name'};
            cbFcnRNE = @obj.tableGroupNameEdit;
            cbFcnRNS = @obj.tableGroupNameSelect;
            cbFcnRB = {@obj.buttonMoveUp,@obj.buttonMoveDown};
            
            % creates the panel object
            pPosN = [obj.dX*[1,1]/2,obj.widPanelRN,obj.hghtPanelRI];
            obj.hPanelRN = createPanelObject(...
                hObjP,pPosN,obj.tHdrRN,'FontSize',obj.fSzL);
                        
            % creates the table object
            pPosRN = [obj.dX*[1,1]/2,obj.widTableRN,obj.hghtTableR];
            obj.hTableRN = createUIObj('table',obj.hPanelRN,...
                    'Data',[],'Position',pPosRN,'ColumnName',cNameRN,...
                    'ColumnEditable',true,'ColumnWidth',{'auto'},...
                    'ColumnFormat',{'char'},'FontSize',obj.fSz,...
                    'CellEditCallback',cbFcnRNE,'RowName',[],...
                    'CellSelectionCallback',cbFcnRNS);
            autoResizeTableColumns(obj.hTableRN);
                
            % creates the button objects
            xPosRB = sum(pPosRN([1,3])) + obj.dX/2;            
            yPosRB0 = (obj.dX + obj.hghtTableR)/2 - ...
                      (obj.dX/4 + obj.hghtBut);
            for i = 1:obj.nButRN
                % calculates the vertical offset
                j = obj.nButRN - (i-1);
                yPosRB = yPosRB0 + (j-1)*(obj.dX/2 + obj.hghtBut);
                
                % creates the button object
                pPosRB = [xPosRB,yPosRB,obj.hghtBut*[1,1]];
                obj.hButRN{i} = createUIObj('pushbutton',obj.hPanelRN,...
                    'Position',pPosRB,'Callback',cbFcnRB{i});
            end
            
            % sets the button c-data values            
            cdFile = getParaFileName('ButtonCData.mat');
            if exist(cdFile,'file')
                [A,nDS] = deal(load(cdFile),3); 
                obj.hButRN{1}.CData = uint8(dsimage(A.cDataStr.Iup,nDS));
                obj.hButRN{2}.CData = uint8(dsimage(A.cDataStr.Idown,nDS));
            end   
            
            % disables both buttons
            cellfun(@(x)(setObjEnable(x,0)),obj.hButRN);
            
            % ------------------------------------ %            
            % --- REGION/GROUP NAME LINK PANEL --- %
            % ------------------------------------ %
            
            % initialisations
            cEditRL = [false,true];
            cNameRL = {'Original Name','Final Name'};
            cbFcnRL = @obj.tableGroupLinkEdit;     
            cFormRL = {'char','char'};            
            
            % creates the panel object
            xPosL = sum(pPosN([1,3])) + obj.dX/2;
            pPosL = [xPosL,obj.dX/2,obj.widPanelRL,obj.hghtPanelRI];
            obj.hPanelRL = createPanelObject(...
                hObjP,pPosL,obj.tHdrRL,'FontSize',obj.fSzL);
            
            % creates the table object
            pPosRL = [obj.dX*[1,1]/2,obj.widTableRL,obj.hghtTableR];
            obj.hTableRL = createUIObj('table',obj.hPanelRL,...
                'Data',[],'Position',pPosRL,'ColumnName',cNameRL,...
                'ColumnEditable',cEditRL,'ColumnFormat',cFormRL,...
                'FontSize',obj.fSz,'CellEditCallback',cbFcnRL,...
                'RowName',[]);
            autoResizeTableColumns(obj.hTableRL);            
            
        end                
        
        % --- sets up the compatible group panel objects
        function setupCompatibleGroupPanels(obj)
        
            % sets the panel vertical offset
            if obj.isSaving
                % case is running from multi-expt saving
                yPos = sum(obj.hPanelTI.Position([2,4])) + obj.dX/2;
                
            else
                % case is running via analysis
                yPos = sum(obj.hPanelR.Position([2,4])) + obj.dX/2;
            end
            
            % creates the panel object
            pPos = [obj.dX,yPos,obj.widPanelI,obj.hghtPanelG];
            obj.hPanelG = createPanelObject(obj.hPanel,pPos,obj.tHdrG);
            
            % ----------------------------------- %
            % --- COMPATIBLE GROUP LIST PANEL --- %
            % ----------------------------------- %
            
            % creates the panel object
            pPosL = [obj.dX*[1,1]/2,obj.widPanelGL,obj.hghtPanelGI];
            pPosL(4) = pPosL(4) - obj.dX/2;
            obj.hPanelGL = createPanelObject(obj.hPanelG,pPosL);
                        
            % creates the tab group
            pPosTG = [obj.dX*[1,1]/2,obj.widTabGrpGL,obj.hghtTabGrpGL];
            obj.hTabGrpGL = createUIObj('tabgroup',obj.hPanelGL,...
                'Position',pPosTG);
            
            % ------------------------------- %
            % --- GROUPING CRITERIA PANEL --- %
            % ------------------------------- %
            
            % initialisations
            tStrC = {'Exact Setup Type','Exact Region Shape',...
                     'Exact Stimuli Devices','Exact Stimuli Protocols',...
                     'Similar Expt Duration'};
            tStrE = 'Max Difference (%)';
            
            % object handles
            cbFcnC = @obj.checkGroupCriteria;
            cbFcnE = @obj.editGroupCriteria;            
            
            % creates the panel object
            xPosC = sum(pPosL([1,3])) + obj.dX/2;
            pPosC = [xPosC,obj.dX/2,obj.widPanelGC,obj.hghtPanelGI];
            pPosC(4) = pPosC(4) + (obj.dX/2 - 2);
            obj.hPanelGC = createPanelObject(...
                obj.hPanelG,pPosC,obj.tHdrGC,'FontSize',obj.fSzL);            
            
            % creates the editbox object
            obj.hEditGC = createObjectPair(obj.hPanelGC,tStrE,...
                obj.widTxtGC,'edit','cbFcnM',cbFcnE);
            obj.hEditGC.String = num2str(obj.cObj.getParaValue('pDur'));
            
            % sets up the grouping criteria checkboxes
            yPos0 = obj.dX + obj.hghtRow;
            for i = 1:obj.nChkGC
                % calculates the vertical offset
                j = obj.nChkGC - (i-1);
                yPos = yPos0 + (j-1)*obj.hghtHdr;
                
                % creates the checkbox object
                pPos = [obj.dX,yPos,obj.widChkGC,obj.hghtHdr];
                obj.hChkGC{i} = createUIObj('checkbox',obj.hPanelGC,...
                    'Position',pPos,'FontUnits','Pixels',...
                    'FontWeight','Bold','FontSize',obj.fSzL,...
                    'Callback',cbFcnC,'UserData',i,'String',tStrC{i});
            end
            
        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
           
        %
        function tabSelectedInfo(obj, hObj, evnt)
            
            
            
        end        
        
        % --- callback function for selecting the experiment group tabs
        function tabSelectedGrp(obj, hObject, ~, indG)
           
            % determines the compatible experiment info
            if ~exist('indG','var')
                indG = obj.cObj.detCompatibleExpts(); 
            end            
            
            % initialisations
            iTabG = get(hObject,'UserData');
            iSel = get(obj.hListGL,'Value');
            lStr = cellfun(@(x)(x.expFile),obj.sInfo(indG{iTabG}),'un',0);

            % updates the list strings
            set(obj.hListGL,'Parent',hObject,'String',lStr(:));            

            % resets the panel information
            obj.resetExptInfo(indG{iTabG}(1))
            if isempty(iSel); iSel = -1; end

            % if the selection index is invalid, remove the selection
            if (iSel > length(lStr))      
                % removes the listbox selection
                set(obj.hListGL,'Max',2,'Value',[]); 

                % ensures the experiment comparison tab is selected
                if obj.isSaving
                    set(obj.hListGL,'Max',2,'Value',[]); 
                    hTabI = get(obj.hTabGrpTI,'SelectedTab');
                    if get(hTabI,'UserData') > 1
                        hTabNw = findall(obj.hTabGrpGL,'UserData',1);
                        set(obj.hTabGrpTI,'SelectedTab',hTabNw)
                    end    

                    % disables the group name 
                    obj.jTabGrpTI.setEnabledAt(1,0);
                else
                    set(obj.hListGL,'Value',1); 
                    obj.listSelect(obj.hListGL, [])
                end
            else
                % otherwise, update the table group names
                obj.updateTableGroupNames()    
            end        
            
        end        
        
        % --- list selection callback function
        function listSelect(obj, hObject, ~)
            
            if obj.isSaving
                % if the group name tab is not selected, then reselect it
                hTabI = get(obj.hTabGrpTI,'SelectedTab');
                if get(hTabI,'UserData') ~= 2
                    obj.jTabGrpTI.setEnabledAt(1,1);
                    hTabNw = findall(obj.hTabGrpTI,'UserData',2);
                    obj.hTabGrpTI.SelectedTab = hTabNw;
                end
            end

            % resets the selection mode to single selection
            set(hObject,'max',2)
            
            % resets the listbox selection
            iSelS = hObject.Value;
            obj.jTableC.changeSelection(iSelS-1,0,0,0);

            % updates the table group names
            obj.updateTableGroupNames()            
            
        end        
        
        % --- group name move up button callback function
        function buttonMoveUp(obj, hBut, ~)

            % determines the currently selected name row and group index
            iTabG = obj.getCurrentTab();            
            [iRow,~] = getTableCellSelection(obj.hTableRN);

            % permutes the group name array and updates within the gui
            indP = [(1:iRow-2),iRow+[0,-1],...
                    (iRow+1):length(obj.gNameU{iTabG})];
            obj.gNameU{iTabG} = obj.gNameU{iTabG}(indP);                            
            
            % updates the table and the other object properties
            setObjEnable(hBut,iRow>2);
            setTableSelection(obj.hTableRN,iRow-2,0)            
            obj.updateGroupLists()            

            % updates the change flag
            obj.isChange = true;
            
        end
        
        % --- group name move down button callback function
        function buttonMoveDown(obj, hBut, ~)
            
            % determines the currently selected name row and group index
            iTabG = obj.getCurrentTab();            
            [iRow,~] = getTableCellSelection(obj.hTableRN);
            
            % permutes the group name array and updates within the gui
            indP = [(1:iRow-1),iRow+[1,0],...
                    (iRow+2):length(obj.gNameU{iTabG})];
            obj.gNameU{iTabG} = obj.gNameU{iTabG}(indP);             
            
            % updates the table and the other object properties
            setObjEnable(hBut,(iRow+1)<length(obj.gNameU{iTabG}));
            setTableSelection(obj.hTableRN,iRow,0)            
            obj.updateGroupLists()            
            
            % updates the change flag
            obj.isChange = true;
            
        end        
        
        % --- group name table cell edit callback function
        function tableGroupNameEdit(obj, hTable, evnt)
            
            % exits the function if updating
            if obj.tableUpdate
                return
            end
           
            % initislisations
            ok = true;
            [tabData,tabData0] = deal(hTable.Data);            

            % retrieves the new input parameters
            iRow = evnt.Indices(1);
            prStr = evnt.PreviousData;
            nwStr = strtrim(evnt.NewData);

            % determines the currently selected experiment
            indG = obj.cObj.detCompatibleExpts();
            iTabG = obj.getCurrentTab();

            % determines the index of the first empty group name cell
            if isempty(prStr)
                tabData0{iRow} = ' ';
            else
                tabData0{iRow} = prStr;
            end
            
            if strcmp(prStr,' ')
                % determines the first empty table row (if there are none 
                % then set the value to be the table row count)
                indE = find(strcmp(tabData0,' '),1,'first');
                if isempty(indE); indE = size(tabData0,1); end

                % determines if there is a gap in the group name list
                if iRow > indE
                    % if a gap exists in the name list then output an error
                    ok = false;
                    mStr = ['There cannot be empty rows within ',...
                            'the group names list.'];    
                else
                    % case is a new name is being added
                    if any(strcmp(tabData(1:iRow-1),nwStr))
                        % if the new name is not unique, then flag an error
                        ok = false;
                        mStr = sprintf(['The group name "%s" already ',...
                                        'exists in group list.'],nwStr);
                    else
                        % otherwise, append on the new name to the list
                        obj.gNameU{iTabG}{end+1} = nwStr;
                    end
                end
            else
                % sets the indices of the experiments to be updated
                iEx = indG{iTabG};

                % determines if the new name is unique
                if any(strcmp(tabData0,nwStr))
                    % if not, then prompt the user
                    tStr = 'Combine Groupings?';
                    qStr = sprintf(['The group name "%s" already ',...
                                    'exists in group list.\nAre you ',...
                                    'sure you want to combine these ',...
                                    'two groups?'],nwStr);        
                    uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                    if ~strcmp(uChoice,'Yes')
                        % if the user chose not to update then flag a reset
                        ok = false;
                    else
                        % updates the final/linking group names    
                        obj.gNameU{iTabG}{iRow} = nwStr;
                        obj.gName(iEx) = obj.resetGroupNames...
                                            (obj.gName(iEx),nwStr,prStr);

                        % reduces down the final names
                        obj.gNameU{iTabG} = ...
                                        unique(obj.gNameU{iTabG},'stable');
                    end
                else
                    % otherwise, update the final/linking group names
                    if isempty(nwStr)
                        % if the string is empty, then remove it
                        B = ~setGroup(iRow,size(obj.gNameU{iTabG}));
                        obj.gNameU{iTabG} = obj.gNameU{iTabG}(B);
                    else
                        % otherwise, update the name list
                        obj.gNameU{iTabG}{iRow} = nwStr;
                    end

                    % updates the linking group names
                    obj.gName(iEx) = obj.resetGroupNames...
                                            (obj.gName(iEx),nwStr,prStr);
                end    
            end

            % determines if a feasible name was added to the name list
            if ok
                % updates the flags/arrays    
                obj.isChange = true;

                % resets the group lists
                obj.updateGroupLists()
                
                % updates the group names on the other tabs
                if obj.sType == 3
                    obj.objB.updateGroupNames(2);
                end
                
            else
                % outputs the error message to screen (if there is error)
                if exist('mStr','var')
                    waitfor(msgbox(mStr,'Group Name Error','modal'))
                end

                % resets the table cell and exits the function
                hTable.Data{iRow} = evnt.PreviousData;
                return
            end            
            
        end
        
        % --- group name table cell edit callback function
        function tableGroupNameSelect(obj, ~, evnt)
           
            % if there are no indices provided, then exit
            if isempty(evnt.Indices); return; end            
            
            % determines the number of group names
            iRow = evnt.Indices(1);
            iTabG = obj.getCurrentTab();
            nName = length(obj.gNameU{iTabG});
            
            % updates the move up/down button enabled properties
            isOn = [iRow>1,iRow<nName] & (iRow <= nName);
            setObjEnable(obj.hButRN{1},isOn(1))
            setObjEnable(obj.hButRN{2},isOn(2))            
            
        end                
            
        % --- group name link table cell edit callback function
        function tableGroupLinkEdit(obj, hTable, evnt)
            
            % other initialisations
            iRow = evnt.Indices(1);
            tabData = get(hTable,'Data');

            % determines if the new selection is feasible
            if (iRow > length(obj.gName{obj.iExp})) || ...
                                        strcmp(tabData{iRow,1},obj.regStr)
                % if row selection is greater than group count, then reset
                hTable.Data{iRow,2} = ' ';
                
            else
                % otherwise, update the group name for the experiment
                obj.gName{obj.iExp}{iRow} = evnt.NewData;

                % updates the flags/arrays    
                obj.isChange = true;                
                
                % removes the table selection
                removeTableSelection(hTable);

                % updates the background colours of the altered cell                
                tabDataN = get(obj.hTableRN,'Data');
                cFormN = [{' '};tabDataN(~strcmp(tabDataN,' '))];
                bgColL = cellfun(@(x)...
                        (obj.tCol{strcmp(cFormN,x)}),tabData(:,2),'un',0);
                set(hTable,'BackgroundColor',cell2mat(bgColL))  
                
                % updates the group names on the other tabs
                if obj.sType == 3
                    obj.objB.updateGroupNames(2);
                end                
            end            
            
        end
        
        % --- experiment comparison table edit callback function
        function tableExptCompEdit(obj, ~, evnt)

            % if the table is updating automatically, then exit
            if obj.tableUpdate
                return
            end

            % field retrieval
            try
                % attempts to retrieves the row/column indices
                iRow = get(evnt,'FirstRow');
                iCol = get(evnt,'Column');
                if (iRow < 0) || (iCol < 0)
                    % if the row/column indices are infeasible, then exit
                    return
                end
            catch
                % if there was an error, then exit
                return
            end

            % retrieves the original table data
            tabData = obj.getTableData();
            nwStr = obj.jTableC.getValueAt(iRow,iCol);
            if strcmp(nwStr,tabData{iRow+1,iCol+1})
                % if there is no change, then exit
                return
            end

            % determines if the experiment name has been updated
            if iCol == 0
                % case is the experiment name is being updated
                nwStr = obj.jTableC.getValueAt(iRow,iCol);
                iExpNw = obj.getCurrentExpt();

                % checks to see if the new experiment name is valid
                if checkNewExptName(obj.sInfo,nwStr,iExpNw)
                    % if so, then update the 
                    obj.cObj.expData(iRow+1,1,:) = {nwStr};  

                    % updates the experiment name and change flag
                    obj.sInfo{iRow+1}.expFile = nwStr;
                    obj.isChange = true;

                    % resets the group lists
                    obj.updateGroupLists()
                    
                    % updates the experiment names on the other tabs
                    if obj.sType == 3
                        obj.objB.updateExptNames(iRow+1,2);
                    end                    

                    % exits the function        
                    return
                end
            end

            % if not, then resets the table cell back to the original value    
            obj.tableUpdate = true;
            obj.jTableC.setValueAt(tabData{iRow+1,iCol+1},iRow,iCol);
            
            % updates the table
            pause(0.05);
            obj.tableUpdate = false;            
            
        end                
        
        % --- experiment comparison table selection callback function
        function tableExptCompSelect(obj, ~, evnt)
            
            % retrieves the new experiment index
            iExpNw = evnt.Indices(1);
            
            % retrieves the indices of the experiments
            indG = obj.cObj.detCompatibleExpts();
            iTabG = find(cellfun(@(x)(any(x==iExpNw)),indG));
            
            % if the incorrect tab is showing, then reset the group tab
            hTabG = get(obj.hTabGrpGL,'SelectedTab');
            if get(hTabG,'UserData') ~= iTabG
                hTabG = findall(obj.hTabGrpGL,'UserData',iTabG);
                set(obj.hTabGrpGL,'SelectedTab',hTabG);
            end
            
            % updates the experiment list selection
            set(obj.hListGL,'Value',find(indG{iTabG} == iExpNw));                        
            obj.tabSelectedGrp(hTabG, [], indG)            
            
        end
        
        % --- group criteria checkbox callback function
        function checkGroupCriteria(obj, hCheck, ~)
            
            % object retrieval
            pStr = get(hCheck,'UserData');
            pValue = get(hCheck,'Value');
            obj.cObj.setCritCheck(pStr,pValue)

            % flag a change was made
            obj.isChange = true;            
            
            % resets the final group name arrays
            obj.resetFinalGroupNameArrays();

            % object retrieval
            obj.updateGroupLists();                 
            
        end
        
        % --- group criteria editbox callback function
        function editGroupCriteria(obj, hEdit, ~)
            
            % object retrieval
            nwVal = str2double(get(hEdit,'String'));

            % determines if the new value is valid
            if chkEditValue(nwVal,[0.001,100],0)
                % if so, update the parameter struct
                obj.cObj.setParaValue('pDur',nwVal);
                obj.cObj.calcCompatibilityFlags(5);

                % resets the final group name arrays
                obj.resetFinalGroupNameArrays()    

                % updates the group lists
                obj.updateGroupLists();
                
            else
                % otherwise, revert back to the last valid value
                prStr = num2str(obj.cObj.getParaValue('pDur'));
                set(hEdit,'String',prStr);
            end                   
            
        end
        
        % ----------------------------------------- %
        % --- EXPERIMENTAL INFO TABLE FUNCTIONS --- %
        % ----------------------------------------- %            
        
        % --- updates the experiment information table (this occurs when 
        %     the user load/removes data)
        function updateExptInfoTable(obj)
            
            % retrieves the current/new row table counts
            nRowNw = max(1,obj.nExp);
            nRow0 = obj.jTableC.getRowCount;
            
            % other initialisations    
            obj.iExp = 1;
            obj.tableUpdate = true;            
            jTableMod = obj.jTableC.getModel;            
            emptyRow = cell(1,obj.jTableC.getColumnCount);                          
            
            % determines if the expt info table needs to be modified
            if nRowNw > nRow0
                % case is new rows need to be added 
                for i = (nRow0+1):nRowNw
                    jTableMod.addRow(emptyRow);
                    for j = 1:obj.jTableC.getColumnCount
                        % sets the background colours
                        obj.tabCR1.setCellBgColor(i-1,j-1,obj.gray);
                        obj.tabCR2.setCellBgColor(i-1,j-1,obj.gray);        

                        % sets the foreground colours
                        obj.tabCR1.setCellFgColor(i-1,j-1,obj.black);
                        obj.tabCR2.setCellFgColor(i-1,j-1,obj.black);            
                    end                    
                end
                
            elseif nRowNw < nRow0
                % case is existing rows need to be removed
                for i = nRow0:-1:(nRowNw+1)
                    jTableMod.removeRow(i-1);
                end                
            end   
            
            % resets the table data (only if experiments are loaded)
            if obj.nExp > 0
                tabData = obj.getTableData();
                for i = 1:obj.jTableC.getRowCount
                    for j = 1:obj.jTableC.getColumnCount
%                         nwStr = java.lang.String(tabData{i,j});
                        obj.jTableC.setValueAt(tabData{i,j},i-1,j-1)  
                    end
                end
                
                % resets the group name arrays
                [obj.gName,obj.gName0] = ...
                            deal(cellfun(@(x)(x.gName),obj.sInfo,'un',0));                 
                
                % updates the group name arrays and lists
                indG = obj.cObj.detCompatibleExpts();
                obj.resetFinalGroupNameArrays(indG)            
                obj.updateGroupLists(indG)  
                
                % sets the list selection (if not already set)
                if isempty(get(obj.hListGL,'Value'))
                    set(obj.hListGL,'Value',1,'max',1)
                end
            end                                           
            
            % resets the update flag
            obj.tableUpdate = false;
            
        end 
        
        % --- updates the group list tabs
        function updateGroupLists(obj,indG)
            
            % if there is no loaded data, then exit the function
            if isempty(obj.sInfo); return; end

            % object retrieval
            hTab0 = get(obj.hTabGrpGL,'Children');

            % sets the default input arguments
            if ~exist('indG','var')
                indG = obj.cObj.detCompatibleExpts();
            end

            % array dimensions
            [nGrp,nTab] = deal(length(indG),length(hTab0));

            % if the group/tab count is not equal, then reset the names
            if nGrp ~= nTab
                % sets the experiment directories/file names
                expNameNw = arrayfun(@(x)...
                            (sprintf('Multi-Expt #%i',x)),1:nGrp,'un',0);
                expDirNw = repmat({obj.iProg.DirComb},length(expNameNw),1);

                % updates the arrays within the gui
                obj.expDir = expDirNw;
                obj.expName = expNameNw;                
            end

            % creates the new tab panel
            for i = (nTab+1):nGrp
                tStr = sprintf('Group #%i',i);
                hTabNw = createNewTabPanel...
                            (obj.hTabGrpGL,1,'title',tStr,'UserData',i);
                set(hTabNw,'ButtonDownFcn',{@obj.tabSelectedGrp})
            end

            % retrieves the group list
            if isempty(obj.hListGL)
                % sets up the listbox positional vector
                tabPos = get(obj.hTabGrpGL,'Position');    
                lPos = [5,5,tabPos(3)-15,tabPos(4)-35];

                % creates the listbox object
                hTabNw = findall(obj.hTabGrpGL,'UserData',1);
                obj.hListGL = uicontrol('Style','Listbox',...
                    'Position',lPos,'tag','hGrpList','Max',2,...
                    'Value',[],'Callback',{@obj.listSelect});
                set(obj.hListGL,'Parent',hTabNw)
            end

            % removes any extra tab panels
            for i = (nGrp+1):nTab
                % determines the tab to be removed
                hTabRmv = findall(hTab0,'UserData',i);
                if isequal(hTabRmv,get(obj.hTabGrpGL,'SelectedTab'))
                    % if the current tab is also selected, then change the 
                    % tab to the very first tab
                    hTabNw = findall(hTab0,'UserData',1);
                    set(obj.hTabGrpGL,'SelectedTab',hTabNw)
                    set(obj.hListGL,'Parent',hTabNw);
                end

                % deletes the tab
                delete(hTabRmv);
            end

            % updates the tab information
            hTabS = get(obj.hTabGrpGL,'SelectedTab');
            obj.tabSelectedGrp(hTabS,[],indG);

        end 
        
        % --- resets the panel information for the experiment index, iExpt
        function resetExptInfo(obj,iExp)

            % other initialisations
            isS = obj.cObj.iSel;
            eStr = {'No','Yes'};
            nExpI = obj.cObj.getParaValue('nExp');
            [~,isComp] = obj.cObj.detCompatibleExpts();

            % sets the table cell colours
            cCol = {obj.redFaded,obj.blueFaded,obj.greenFaded};

            % updates the text object colours
            obj.tableUpdate = true;
            for i = 1:nExpI
                % updates the stimuli protocol comparison strings
                isC = isComp{iExp}(i);
                nwStr = java.lang.String(obj.cObj.expData{i,6,iExp});
                obj.jTableC.setValueAt(nwStr,i-1,5)
                obj.jTableC.setValueAt(eStr{1+isC},i-1,6)

                % sets the table strings
                obj.tabCR1.setCellBgColor(i-1,0,cCol{1+2*isC});
                obj.tabCR2.setCellBgColor(i-1,6,cCol{1+2*isC});

                % updates the table cell colours
                for j = 1:size(obj.cObj.cmpData,2)
                    if isS(j)
                        isM = obj.cObj.cmpData(i,j,iExp);
                        nwCol = cCol{1+isM*(1+isC)};
                        obj.tabCR2.setCellBgColor(i-1,j,nwCol);
                    else
                        obj.tabCR2.setCellBgColor(i-1,j,obj.gray);
                    end
                end                      
            end

            % repaints the table
            obj.jTableC.repaint();

            % resets the table update flag
            pause(0.05)
            obj.tableUpdate = false;

        end        
        
        % --- resets the final group name arrays
        function resetFinalGroupNameArrays(obj,indG)

            % sets the default input arguments
            if ~exist('indG','var')
                indG = obj.cObj.detCompatibleExpts();
            end

            % determines the unique group names
            obj.gNameU = cellfun(@(x)(obj.rmvInfeasName(unique...
                (cell2cell(obj.gName(x)),'stable'))),indG,'un',0);
        
        end             
        
        % --- updates the final/linking table group names
        function updateTableGroupNames(obj)

            % parameters
            rejStr = '* REJECTED *';

            % determines the currently selected experiment
            iTabG = obj.getCurrentTab();
            iSelG = get(obj.hListGL,'Value');
            indG = obj.cObj.detCompatibleExpts();          

            % sets the experiment index
            if isempty(iSelG)
                % if there is no selection, then use first experiment
                obj.iExp = indG{iTabG}(1);
            else
                obj.iExp = indG{iTabG}(iSelG);
            end

            % sets update the group colour arrays
            nColG = length(obj.gNameU{iTabG});
            obj.tCol = num2cell(getAllGroupColours(nColG),2);

            % sets up the final name table data/background colours
            DataN = obj.expandCellArray(obj.gNameU{iTabG}(:),obj.nRow);
            bgColN = obj.expandCellArray...
                                (obj.tCol(2:end),obj.nRow,obj.tCol{1});

            % adds an additional row to the table (if more space is reqd)
            if find(~strcmp(DataN,' '),1,'last') >= obj.nRow
                [DataN,bgColN] = deal([DataN;{' '}],[bgColN;obj.tCol(1)]);
            end            

            % updates the final name table data/properties
            iSel0 = getTableCellSelection(obj.hTableRN);
            set(obj.hTableRN,'BackgroundColor',cell2mat(bgColN));
            obj.hTableRN.Data = DataN;
                            
            % resets the selection (if there was one)
            if ~isempty(iSel0)
                setTableSelection(obj.hTableRN,iSel0-1,0); 
                pause(0.05);
            end

            % expands the cell array
            DataL = obj.expandCellArray([obj.gName0{obj.iExp}(:),...
                                         obj.gName{obj.iExp}(:)],obj.nRow);

            % updates the group name link table data/properties
            cFormN = [{' '},obj.gNameU{iTabG}(:)'];
            isRej = strcmp(DataL(:,1),rejStr);
            DataL(isRej,2) = {' '};
            bgColL = cellfun(@(x)(obj.tCol...
                        {strcmp(cFormN,x)}),DataL(:,2),'un',0);
            set(obj.hTableRL,'Data',DataL,'ColumnFormat',...
                {'char',cFormN},'BackgroundColor',cell2mat(bgColL(:)));

        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- retrieves the current experiment index
        function iExp = getCurrentExpt(obj)
            
            % retrieves the current experiment index
            indG = obj.cObj.detCompatibleExpts();
            iExp = indG(obj.getCurrentTab());
            
        end        
        
        % --- retrieves the selected tab index
        function iTab = getCurrentTab(obj)
            
            iTab = obj.hTabGrpGL.SelectedTab.UserData;
            
        end        
        
        % --- retrieves the current table data
        function tabData = getTableData(obj)

            % determines if there is any loaded data
            if isempty(obj.sInfo)
                % case is there is no loaded data
                tabData = cell(1,obj.nHdr);
                
            else
                % initialisations
                sStr = {'No','Yes'};
                [~,isComp] = obj.cObj.detCompatibleExpts();

                % sets up the table data array
                tabData = [obj.cObj.expData(:,:,1),...
                       arrayfun(@(x)(sStr{1+x}),isComp{obj.iExp},'un',0)];
%                 if obj.sType == 3
%                     % adds in the column index column
%                     colStr = arrayfun(@num2str,1:size(tabData,1),'un',0);
%                     tabData = [colStr(:),tabData];
%                 end
            end

        end
            
        % --- deletes the class object
        function deleteClass(obj)
            
            delete(obj)
            clear obj
            
        end
        
    end
    
    % static class methods
    methods (Static)
        
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
        
        % --- removes any of the infeasible names from the name list
        function gName = rmvInfeasName(gName)

            % determines the flags of the group names that are infeasible
            rStr = '* REJECTED *';
            isRmv = strcmp(gName,' ') | ...
                    strcmp(gName,rStr) | ...                    
                    cellfun('isempty',gName);

            % removes any infeasible names
            gName = gName(~isRmv);    
            
        end        
        
        % --- expands the cell array to have a minimum of nRow rows 
        function Data = expandCellArray(Data,nRow,cVal)

            % array dimensioning
            szD = size(Data);

            % expands the array (if necessary)
            if nRow > szD(1)
                if ~exist('cVal','var'); cVal = ' '; end
                Data = [Data;repmat({cVal},nRow-szD(1),szD(2))];
            end

        end        
        
        % --- resets the occurances of prStr to nwStr 
        %     (within the cell array, gName)
        function gName = resetGroupNames(gName,nwStr,prStr)

            % ensures the previous/new strings are not empty
            if isempty(prStr); prStr = ' '; end
            if isempty(nwStr); nwStr = ' '; end

            % resets the group names for each experiment
            for i = 1:length(gName)
                gName{i}(strcmp(gName{i},prStr)) = {nwStr};
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