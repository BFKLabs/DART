classdef ExptFuncDependency < handle & dynamicprops
    
    % class properties
    properties
        
        % input arguments
        iTabP
        
        % main class objects
        hTab
        hPanel
        objF
        
        % control button objects
        hPanelC
        hChkC
        hPopupC
        hButC
        
        % function list panel objects
        hPanelF
        hTableF
        jTableF
        
        % function filter panel objects
        hPanelFF
        
        % table objects
        tabCR1
        tabCR2
        tabData        
        
        % fixed dimension class fields
        hghtPanelFF = 180;
        widColF = 200;
        widObjC = [230,115,190,240];
        
        % calculated dimension class fields
        widPanelI
        hghtPanelC
        hghtPanelF
        hghtTableF
        widTableF
        
        % other class objects        
        cWid0
        cName
                
        % fixed scalar fields
        sGap = 2;
        expWid = 40;                
        
        % array class fields
        reqWid = [55,55,80,60,60];
        
    end
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end  
    
    % class methods
    methods
        
        % --- class constructor
        function obj = ExptFuncDependency(objB,iTabP)
            
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
            fldStr = {'sInfo','pDataT','hParent','tHdrTG','nExp',...
                      'dX','hghtHdrTG','hghtRow','grayLight','gray',...
                      'white','black','redFaded','greenFaded'};
            
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

            % ------------------------- %
            % --- MAIN OBJECT SETUP --- %
            % ------------------------- %
            
            % creates the stimuli tab object
            obj.hTab = createUIObj('tab',obj.hParent,...
                'Title',obj.tHdrTG{obj.iTabP},'UserData',obj.iTabP);

            % creates the panel object                
            pPosT = getpixelposition(obj.hTab);
            szTG = pPosT(3:4)-(obj.dX+[0,obj.hghtHdrTG]); 
            pPos = [obj.dX*[1,1]/2,szTG];
            obj.hPanel = createPanelObject(obj.hTab,pPos);
            
            % ----------------------------- %
            % --- OTHER INITIALISATIONS --- %
            % ----------------------------- %
            
            % column file names
            obj.cName = {'Function Name','Analysis Scope',...
                         'Duration','Shape','Stimuli','Special'};
            
            % other field initialisations
            obj.nExp = length(obj.sInfo);
            obj.cWid0 = [obj.widColF,obj.reqWid,obj.sGap];
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %
                 
            % panel width calculations
            obj.widPanelI = pPos(3) - 2*obj.dX;            
            
            % calculates the panel dimensions
            obj.hghtPanelC = obj.dX + obj.hghtRow;
            obj.hghtPanelF = pPos(4) - (obj.hghtPanelC + 2.5*obj.dX);
            
            % function table dimension calculations
            obj.hghtTableF = obj.hghtPanelF - obj.dX;
            obj.widTableF = obj.widPanelI - obj.dX;        
            
        end
        
        % --- initialises the class fields
        function initClassObjects(obj)
            
            % ------------------------------ %
            % --- MAIN SUB-PANEL OBJECTS --- %
            % ------------------------------ %  
            
            % sets up the file loading sub-panel objects
            obj.setupControlButtonPanel();
            obj.setupFuncFilterPanel();
            obj.setupFuncDependPanel();    
            
            % resorts the sub-panels
            hPanelCh = obj.hPanel.Children;
            isFF = arrayfun(@(x)(isequal(obj.hPanelFF,x)),hPanelCh);
            obj.hPanel.Children = [hPanelCh(isFF);hPanelCh(~isFF)];
            
        end        

        % --- creates the function dependency table 
        function createFuncDependTable(obj)
                        
            % object retrieval     
            cbFcnF = @obj.reorderTableRows;
            
            % sets the table header strings
            exptCol = arrayfun(@(x)(createTableHdrString...
                        ({'Expt',sprintf('#%i',x)})),1:obj.nExp,'un',0);            
            hdrStr = [{createTableHdrString({'Analysis Function Name'}),...
                      createTableHdrString({'Analysis','Scope'}),...
                      createTableHdrString({'Duration'}),...
                      createTableHdrString({'Shape'}),...
                      createTableHdrString({'Stimuli'}),...          
                      createTableHdrString({'Special'}),' '},exptCol];                                
            
            % updates the table data array
            obj.updateTableData()                  
                  
            % creates the temporary table object
            pPosT = [obj.dX*[1,1]/2,obj.widTableF,obj.hghtTableF];
            hTable = createUIObj('table',obj.hPanelF);
            
            % creates the java table object
            jScroll = findjobj(hTable);
            [jScroll, hContainer] = ...
                createJavaComponent(jScroll, [], obj.hPanelF);
            set(hContainer,'Units','Pixels','Position',pPosT)
            
            % creates the java table model
            obj.jTableF = jScroll.getViewport.getView;
            jTableMod = ...
                  javax.swing.table.DefaultTableModel(obj.tabData,hdrStr);
            obj.jTableF.setModel(jTableMod);            
                  
            % sets the table callback function
            cbFcn = @obj.tableHdrSortChange;
            jTH = handle(obj.jTableF.getTableHeader,'callbackproperties');
            addJavaObjCallback(jTH,'MousePressedCallback',cbFcn);            
            
            % creates the table cell renderer
            obj.tabCR1 = ColoredFieldCellRenderer(obj.white);
            obj.tabCR2 = ColoredFieldCellRenderer(obj.white);            
            
            % sets the table text to black
            for i = 1:size(obj.tabData,1)
                for j = 1:size(obj.tabData,2)
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

            % sets the column models for each table column
            for cID = 1:length(hdrStr)
                obj.updateColumnModel(cID);
            end

            % updates the table header colour
            gridCol = getJavaColour(0.5*ones(1,3));
            obj.jTableF.getTableHeader().setBackground(gridCol);
            obj.jTableF.setGridColor(gridCol);
            obj.jTableF.setShowGrid(true);

            % disables the resizing
            jTableHdr = obj.jTableF.getTableHeader(); 
            jTableHdr.setResizingAllowed(false); 
            jTableHdr.setReorderingAllowed(false);
            obj.jTableF.setAutoCreateRowSorter(true);

            % repaints the table
            obj.jTableF.repaint()
            obj.jTableF.setAutoResizeMode(obj.jTableF.AUTO_RESIZE_OFF)                        
            set(obj.objF,'jTable',obj.jTableF,'treeUpdateExtn',cbFcnF);            
                                   
            % updates the function compatibility table cell colours
            obj.updateFuncCellComp();
            
        end
        
        % ------------------------------------ %
        % --- PANEL OBJECT SETUP FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- sets up the function filter panel objects
        function setupFuncFilterPanel(obj)
            
            % creates the panel object
            bPos = getObjGlobalCoord(obj.hButC);
            tPos = getObjGlobalCoord(obj.hPanel);
            xPos = bPos(1) - tPos(1) + 1;
            yPos = bPos(2) - (obj.hghtPanelFF + tPos(2));

            % creates the panel object
            pPos = [xPos,yPos,obj.widObjC(4),obj.hghtPanelFF];            
            obj.hPanelFF = createPanelObject(obj.hPanel,pPos);
            set(obj.hPanelFF,'Tag','panelFuncFilter','Visible','off')
           
            % ---------------------------------- %
            % --- FILTER FUNCTION TREE SETUP --- %
            % ---------------------------------- %
            
            % retrieves the solution file information data struct
            if isempty(obj.sInfo)
                snTot = [];
            else
                snTot = cellfun(@(x)(x.snTot),obj.sInfo,'un',0);
            end
            
            % creates the function filter tree object
            obj.objF = FuncFilterTree(obj.hTab,snTot,obj.pDataT);                                 
            
        end        
        
        % --- sets up the control panel objects
        function setupControlButtonPanel(obj)
            
            % initialisations
            pTypeC = {'checkbox','text','popupmenu','togglebutton'};
            pStrC = {'Only Display Compatible Functions',...
                     'Sort Functions By: ',[],...
                     'Open Analysis Function Filter'};
                 
            % function handles
            cbFcnP = @obj.popupFuncSort;
            cbFcnC = @obj.chkGroupExpt;
            cbFcnB = @obj.toggleFuncFilter;
            
            % creates the panel object
            yPos = 1.5*obj.dX + obj.hghtPanelF;
            pPos = [obj.dX,yPos,obj.widPanelI,obj.hghtPanelC];
            obj.hPanelC = createPanelObject(obj.hPanel,pPos);
            
            % creates the other objects
            hObjC = createObjectRow(obj.hPanelC,length(pTypeC),pTypeC,...
                obj.widObjC,'pStr',pStrC,'dxOfs',0,'yOfs',obj.dX-2);
            [obj.hChkC,obj.hPopupC,obj.hButC] = ...
                            deal(hObjC{1},hObjC{3},hObjC{4});            
            
            % sets the other object properties
            set(hObjC{2},'HorizontalAlignment','Right');            
            resetObjPos(hObjC{4},'Left',3*obj.dX/2,1);            
            set(obj.hPopupC,'Callback',cbFcnP,'String',obj.cName);
            set(obj.hChkC,'Callback',cbFcnC,'tag','checkGrpExpt');
            set(obj.hButC,'Callback',cbFcnB,'tag','toggleFuncFilter');
            
        end
        
        % --- sets up the function dependency panel objects
        function setupFuncDependPanel(obj)
            
            % creates the panel object
            pPos = [obj.dX*[1,1],obj.widPanelI,obj.hghtPanelF];
            obj.hPanelF = createPanelObject(obj.hPanel,pPos);
            
            % creates the function dependency table
            obj.createFuncDependTable();      
                        
            % ----------------------------- %            
            % --- OTHER INITIALISATIONS --- %
            % ----------------------------- %
            
            % resets the popup menu user data
            rFld = fieldnames(obj.objF.rGrp);
            nGrp = cellfun(@(x)(numel(obj.objF.rGrp.(x))),rFld);

            % removes any requirement groups without multiple group types
            indM = [1;(find(nGrp > 1) + 1)];
            set(obj.hPopupC,'String',obj.cName(indM),'UserData',indM);

            % runs the function sorting popup menu
            obj.popupFuncSort(obj.hPopupC, [])              
            
        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- % 
        
        % --- function sort popupmenu callback function
        function popupFuncSort(obj, hPopup, evnt)
            
            % java imports
            import javax.swing.SortOrder

            % object handles
            iSel = get(hPopup,'Value');
            sOrder = SortOrder.ASCENDING;

            % sets the sorting list array
            sList = java.util.ArrayList;
            sList.add(javaObject...
                        ('javax.swing.RowSorter$SortKey',iSel-1,sOrder));

            % sets the rows sort order
            jRowSorter = obj.jTableF.getRowSorter();
            jRowSorter.setSortKeys(sList)

            if isempty(evnt)
                % case is calling function directly (updates sort filter)
                xiS = 1:obj.jTableF.getColumnCount;
                arrayfun(@(x)(jRowSorter.setSortable(x-1,0)),xiS);
                
            else
                % case is calling through object update (update colours)
                obj.updateFuncCompColours()    
            end                        
            
        end
        
        % --- group experiment checkbox callback function
        function chkGroupExpt(obj, hChk, ~)
            
            % closes the filter (if open)
            if obj.hButC.Value
                obj.hButC.Value = 0;
                obj.toggleFuncFilter(obj.hButC,[])
            end  
            
            % updates the tree click function
            setObjEnable(obj.hButC,~get(hChk,'Value'));
            obj.objF.treeUpdateClick([], []);            
            
        end
        
        % --- function filter togglebutton callback function 
        function toggleFuncFilter(obj, hBut, ~)
            
            % updates the funcion filter panel visibility            
            isOpen = get(hBut,'Value');            
            setObjVisibility(obj.hPanelFF,isOpen);

            % updates the toggle button string
            if isOpen
                set(hBut,'String','Close Analysis Function Filter')
            else
                set(hBut,'String','Open Analysis Function Filter')
            end             
            
        end
        
        % --- column header selection callback function
        function tableHdrSortChange(obj, ~, ~)
            
            % ensures the table update is complete
            obj.jTableF.repaint();
            pause(0.1);
            
            % resets the compatibility colours
            obj.updateFuncCompColours()            
            
        end
        
        % --- reorders the table rows
        function reorderTableRows(obj)
            
            % java imports
            import javax.swing.RowFilter            
            
            % resets the row sorter filter
            jRowSort = obj.jTableF.getRowSorter;
            jRowSort.setRowFilter(RowFilter.andFilter(obj.objF.cFiltTot))
            
            % resets the function compatibility colours
            obj.updateFuncCompColours()              
            
        end

        % -------------------------------------- %
        % --- FIGURE/OBJECT UPDATE FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- updates the experiment table data
        function updateTableData(obj)
                  
            % initialisations
            sStr = {'No','Yes'};
            nFunc = size(obj.objF.fcnData,1);            
            
            % sets up the function requirement information array            
            fcnDataT = obj.objF.fcnData;
            fcnDataT(:,2:end) = centreTableData(fcnDataT(:,2:end));
            obj.tabData = [fcnDataT,repmat({' '},nFunc,1),...
                    arrayfun(@(x)(sStr{1+x}),obj.objF.cmpData,'un',0)];
                       
        end        
        
        % --- updates the function dependency table (this occurs when
        %     adding/remove loaded experiments)
        function updateFuncDepTable(obj)
            
            % if no experiments are loaded, then exit
            if obj.nExp == 0; return; end
            
            % field retrieval
            jTableMod = obj.jTableF.getModel();
            jTableMod.fireTableStructureChanged()
           
            % column old/new counts
            nCol0 = obj.jTableF.getColumnCount();
            nColHdr = (size(obj.objF.fcnData,2) + 1);
            nColNw = nColHdr + obj.nExp;
            
            % updates the experiment information
            snTot = cellfun(@(x)(x.snTot),obj.sInfo,'un',0);                        
            obj.objF.resetFuncFilter(snTot);

            % determines (from the current batch of expts) the 
            % compatibility of the functions with loaded experiments
            obj.updateTableData();            
            
            % resets the data for the non-added columns
            for iCol = (nColHdr+1):min(nCol0,nColNw)
                for iRow = 1:obj.jTableF.getRowCount()
                    if ~strcmp(obj.tabData{iRow,iCol},...
                               char(obj.jTableF.getValueAt(iRow-1,iCol-1)))                                
                        nwStr = java.lang.String(obj.tabData{iRow,iCol});
                        obj.jTableF.setValueAt(nwStr,iRow-1,iCol-1)  
                    end
                end
            end
            
            % determines if the expt info table needs to be modified
            if nColNw > nCol0
                % case is new rows need to be added
                for i = (nCol0+1):nColNw
                    indStr = sprintf('#%i',i-nColHdr);
                    colHdr = createTableHdrString({'Expt',indStr});
                    colData = obj.tabData(:,i);
                    jTableMod.addColumn(colHdr,colData);                                        
                end
                
            elseif nColNw < nCol0
                % case is existing rows need to be removed
%                 dataV = jTableMod.getDataVector;
                for iCol = nCol0:-1:(nColNw+1)
                    cMdl = obj.jTableF.getColumnModel().getColumn(iCol-1);
                    obj.jTableF.removeColumn(cMdl);
                    
%                     for iRow = 1:obj.jTableF.getRowCount
%                         dataRow = dataV.elementAt(iRow-1);
%                         dataRow.removeElementAt(iCol-1);
%                     end
                end   
            end
            
            % sets the model min/max widths
            cWid = [obj.cWid0,obj.expWid*ones(1,obj.nExp)];           
            
            % updates the column models for the other columns
            xiC = 1:length(cWid);
            arrayfun(@(x,w)(obj.updateColumnModel(x,w)),xiC,cWid);
            
            % repaints the table
            obj.jTableF.repaint()
            pause(0.05);            
            
            % resets the function dependency colours
            obj.updateFuncCompColours()             
            
        end                
        
        % --- updates the column model
        function updateColumnModel(obj,iCol,cWid)

            % sets the default input arguments
            if ~exist('cWid','var')
                if iCol > length(obj.cWid0)
                    cWid = obj.expWid;
                else
                    cWid = obj.cWid0(iCol);
                end
            end
            
            % retrieves the column model
            cMdl = obj.jTableF.getColumnModel.getColumn(iCol-1);
            
            % updates the column widths and renderer
            cMdl.setMinWidth(cWid)
            cMdl.setMaxWidth(cWid)
            
            % updates the column renderer
            if iCol == 1
                cMdl.setCellRenderer(obj.tabCR1);
            else
                cMdl.setCellRenderer(obj.tabCR2);
            end

        end           
                
        % --- resets the function compatibility colours
        function updateFuncCompColours(obj)

            % initialisations
            iCol0 = size(obj.objF.fcnData,2) + 2;
            cCol = {obj.redFaded,obj.greenFaded};                
            
            % updates the background colours of the cells
            for i = 1:obj.jTableF.getRowCount
                for j = iCol0:obj.jTableF.getColumnCount
                    switch obj.jTableF.getValueAt(i-1,j-1)
                        case 'Yes'
                            obj.tabCR2.setCellBgColor(i-1,j-1,cCol{2});
                        case 'No'
                            obj.tabCR2.setCellBgColor(i-1,j-1,cCol{1});
                    end
                end
            end    

            % repaints the table
            obj.jTableF.repaint

        end       
        
        % --- initialises the function cell compatibility table colours
        function updateFuncCellComp(obj)

            % initialisations
            [nFunc,nHdr] = size(obj.objF.fcnData);
            cCol = {obj.redFaded,obj.greenFaded};

            % sets the background colours based on the column indices
            for i = 1:nFunc
                for j = 1:size(obj.tabData,2)
                    if j == 1
                        % case is the function name column
                        obj.tabCR1.setCellBgColor(i-1,j-1,obj.gray);

                    elseif j <= nHdr
                        % case is the other requirement columns
                        obj.tabCR2.setCellBgColor(i-1,j-1,obj.grayLight);

                    elseif j == (nHdr + 1) 
                        % case is the gap column
                        obj.tabCR2.setCellBgColor(i-1,j-1,obj.gray);

                    else
                        % case is the experiment compatibility columns
                        k = j - (nHdr+1);
                        isComp = double(obj.objF.cmpData(i,k));
                        obj.tabCR2.setCellBgColor(i-1,j-1,cCol{1+isComp});
                    end
                end
            end

            % repaints the table
            obj.jTableF.repaint();
            
        end                                
                
        % --- deletes the class object
        function deleteClass(obj)
            
            clear obj
            
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