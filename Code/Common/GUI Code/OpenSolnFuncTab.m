classdef OpenSolnFuncTab < dynamicprops & handle
    
    % class properties
    properties 
        
        % function/experiment data fields
        objFcn  
        
        % table objects
        tabCR1
        tabCR2
        jTable        
        tabData
        
        % other class objects
        cWid0
        expWid = 40;                
        
    end
    
    % private class properties    
    properties (Access = private)
    	baseObj
    end        
    
    % class methods
    methods
        
        % --- class constructor
        function obj = OpenSolnFuncTab(baseObj)
            
            % field initialisations
            obj.baseObj = baseObj;
            
            % initialises the object callback functions
            obj.linkParentProps();
            obj.initObjCallbacks();  
            obj.initObjProps();
            
        end
        
        % --- initialises the class object fields with that parent object
        function linkParentProps(obj)
           
            % connects the base/child objects 
            for propname = properties(obj.baseObj)'
                metaprop = addprop(obj, propname{1});
                metaprop.SetMethod = @(obj, varargin) ...
                                SetDispatch(obj, propname{1}, varargin{:});
                metaprop.GetMethod = @(obj) ...
                                GetDispatch(obj, propname{1});
            end            
            
        end        
        
        % initialises all the object callback functions
        function initObjCallbacks(obj)
           
            % objects with normal callback functions
            cbObj = {'popupFuncSort','checkGrpExpt','toggleFuncFilter'};
            for i = 1:length(cbObj)
                hObj = getStructField(obj.hGUI,cbObj{i});
                cbFcn = eval(sprintf('@obj.%sCB',cbObj{i}));
                set(hObj,'Callback',cbFcn)
            end                  
            
        end
        
        % --- initialises the tab panel object properties
        function initObjProps(obj)
            
            % object retrieval
            handles = obj.hGUI;
            hPopup = handles.popupFuncSort;     
            cbFcn = @obj.reorderTableRows;
            
            % retrieves the solution file information data struct
            if isempty(obj.sInfo)
                snTot = [];
            else
                snTot = cellfun(@(x)(x.snTot),obj.sInfo,'un',0);
            end
            
            % creates the function filter tree object            
            obj.objFcn = FuncFilterTree(obj.hFig,snTot,obj.pDataT);           
                 
            % initialises the other gui objects
            obj.initFuncDepTable();
            obj.initFuncCellComp();
            
            % updates the function object fields
            set(obj.objFcn,'jTable',obj.jTable,'treeUpdateExtn',cbFcn);
            
            % resets the popup menu user data
            lStr = get(hPopup,'String');
            rFld = fieldnames(obj.objFcn.rGrp);
            nGrp = cellfun(@(x)...
                        (numel(getStructField(obj.objFcn.rGrp,x))),rFld);

            % removes any requirement groups without multiple group types
            indM = [1;(find(nGrp > 1) + 1)];
            set(hPopup,'String',lStr(indM),'UserData',indM);

            % runs the function sorting popup menu
            obj.popupFuncSortCB(hPopup, [])            
            
        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- % 
        
        % --- callback function for selecting popupFuncSort
        function popupFuncSortCB(obj, hObject, eventdata)
           
            % java imports
            import javax.swing.SortOrder

            % object handles
            iSel = get(hObject,'Value');
            sOrder = SortOrder.ASCENDING;

            % sets the sorting list array
            sList = java.util.ArrayList;
            sList.add(javaObject...
                        ('javax.swing.RowSorter$SortKey',iSel-1,sOrder));

            % sets the rows sort order
            jRowSorter = obj.jTable.getRowSorter();
            jRowSorter.setSortKeys(sList)

            if isempty(eventdata)
                % case is calling function directly (updates sort filter)
                xiS = 1:obj.jTable.getColumnCount;
                arrayfun(@(x)(jRowSorter.setSortable(x-1,0)),xiS);
            else
                % case is calling through object update (update colours)
                obj.resetFuncCompColours()    
            end            
            
        end            
        
        % --- callback function for clicking checkGrpExpt
        function checkGrpExptCB(obj, hObject, ~)
            
            % closes the filter (if open)
            if get(obj.hGUI.toggleFuncFilter,'Value')
                set(obj.hGUI.toggleFuncFilter,'Value',0)
                obj.toggleFuncFilterCB(obj.hGUI.toggleFuncFilter)
            end
           
            % updates the tree click function
            setObjEnable(obj.hGUI.toggleFuncFilter,~get(hObject,'Value'));
            obj.objFcn.treeUpdateClick([], []);            
            
        end    
        
        % --- callback function for toggling toggleFuncFilter
        function toggleFuncFilterCB(obj, hObject, ~)
           
            % object handles
            handles = obj.hGUI;
            isOpen = get(hObject,'Value');

            % updates the funcion filter panel visibility            
            setObjVisibility(handles.panelFuncFilter,isOpen);

            % updates the toggle button string
            if isOpen
                set(hObject,'String','Close Analysis Function Filter')
            else
                set(hObject,'String','Open Analysis Function Filter')
            end            
            
        end         
        
        % --- callback function for clicking the column header sort
        function tableHdrSortChange(obj, ~, ~)
           
            % ensures the table update is complete
            obj.jTable.repaint();
            pause(0.1);
            
            % resets the compatibility colours
            obj.resetFuncCompColours()
            
        end
        
        % ----------------------- %
        % --- OTHER FUNCTIONS --- %
        % ----------------------- %          
        
        % --- initialises the function dependency table
        function initFuncDepTable(obj)
            
            % object handle retrieval
            handles = obj.hGUI;
            hTable = handles.tableFuncComp;
            hPanel = handles.panelFuncComp;
            pPos = get(hPanel,'Position');

            % other initialisations
            dX = 5;
            sGap = 2;              
            dPos = [2*dX,2*(dX+1)];
            nExp = length(obj.sInfo);                        
            reqWid = [55,55,70,60,60];
            obj.cWid0 = [200,reqWid,sGap];
            
            % creates the experiment column headers
            exptCol = arrayfun(@(x)(createTableHdrString...
                            ({'Expt',sprintf('#%i',x)})),1:nExp,'un',0);

            % sets the table header strings
            hdrStr = [{createTableHdrString({'Analysis Function Name'}),...
                      createTableHdrString({'Analysis','Scope'}),...
                      createTableHdrString({'Duration'}),...
                      createTableHdrString({'Shape'}),...
                      createTableHdrString({'Stimuli'}),...          
                      createTableHdrString({'Special'}),' '},exptCol];

            % updates the table data array
            obj.updateTableData()            

            % creates the java table object
            jScroll = findjobj(hTable);
            tPos = [dX*[1,1],pPos(3:4)-dPos];
            [jScroll, hContainer] = createJavaComponent(jScroll, [], hPanel);
            set(hContainer,'Units','Pixels','Position',tPos)

            % creates the java table model
            obj.jTable = jScroll.getViewport.getView;
            jTableMod = ...
                  javax.swing.table.DefaultTableModel(obj.tabData,hdrStr);
            obj.jTable.setModel(jTableMod);
            
            % sets the table callback function
            cbFcn = {@obj.tableHdrSortChange};
            jTH = handle(obj.jTable.getTableHeader,'callbackproperties');
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
            obj.jTable.getTableHeader().setBackground(gridCol);
            obj.jTable.setGridColor(gridCol);
            obj.jTable.setShowGrid(true);

            % disables the resizing
            jTableHdr = obj.jTable.getTableHeader(); 
            jTableHdr.setResizingAllowed(false); 
            jTableHdr.setReorderingAllowed(false);
            obj.jTable.setAutoCreateRowSorter(true);

            % repaints the table
            obj.jTable.repaint()
            obj.jTable.setAutoResizeMode(obj.jTable.AUTO_RESIZE_OFF)            
            
        end        
        
        % --- updates the function dependency table (this occurs when
        %     adding/remove loaded experiments)
        function updateFuncDepTable(obj)
            
            % if no experiments are loaded, then exit
            if obj.nExp == 0; return; end
            
            % field retrieval
            jTableMod = obj.jTable.getModel();
            jTableMod.fireTableStructureChanged()
           
            % column old/new counts
            nCol0 = obj.jTable.getColumnCount();
            nColHdr = (size(obj.objFcn.fcnData,2) + 1);
            nColNw = nColHdr + obj.nExp;
            
            % updates the experiment information
            snTot = cellfun(@(x)(x.snTot),obj.sInfo,'un',0);                        
            obj.objFcn.resetFuncFilter(snTot);

            % determines (from the current batch of expts) the 
            % compatibility of the functions with loaded experiments
            obj.updateTableData();            
            
            % resets the data for the non-added columns
            for iCol = (nColHdr+1):min(nCol0,nColNw)
                for iRow = 1:obj.jTable.getRowCount()
                    if ~strcmp(obj.tabData{iRow,iCol},...
                               char(obj.jTable.getValueAt(iRow-1,iCol-1)))                                
                        nwStr = java.lang.String(obj.tabData{iRow,iCol});
                        obj.jTable.setValueAt(nwStr,iRow-1,iCol-1)  
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
                    cMdl = obj.jTable.getColumnModel().getColumn(iCol-1);
                    obj.jTable.removeColumn(cMdl);
                    
%                     for iRow = 1:obj.jTable.getRowCount
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
            obj.jTable.repaint()
            pause(0.05);            
            
            % resets the function dependency colours
            obj.resetFuncCompColours()
            
        end
        
        % --- initialises the function cell compatibility table colours
        function initFuncCellComp(obj)

            % initialisations
            [nFunc,nHdr] = size(obj.objFcn.fcnData);
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
                        isComp = double(obj.objFcn.cmpData(i,k));
                        obj.tabCR2.setCellBgColor(i-1,j-1,cCol{1+isComp});
                    end
                end
            end

            % repaints the table
            obj.jTable.repaint();            
            
        end                        
        
        % --- resets the function compatibility colours
        function resetFuncCompColours(obj)

            % initialisations
            iCol0 = size(obj.objFcn.fcnData,2) + 2;
            cCol = {obj.redFaded,obj.greenFaded};    

            % updates the background colours of the cells
            for i = 1:obj.jTable.getRowCount
                for j = iCol0:obj.jTable.getColumnCount
                    switch obj.jTable.getValueAt(i-1,j-1)
                        case 'Yes'
                            obj.tabCR2.setCellBgColor(i-1,j-1,cCol{2});
                        case 'No'
                            obj.tabCR2.setCellBgColor(i-1,j-1,cCol{1});
                    end
                end
            end    

            % repaints the table
            obj.jTable.repaint

        end
        
        % --- updates the experiment table data
        function updateTableData(obj)
                  
            % initialisations
            sStr = {'No','Yes'};
            nFunc = size(obj.objFcn.fcnData,1);            
            
            % sets up the function requirement information array            
            fcnDataT = obj.objFcn.fcnData;
            fcnDataT(:,2:end) = centreTableData(fcnDataT(:,2:end));
            obj.tabData = [fcnDataT,repmat({' '},nFunc,1),...
                    arrayfun(@(x)(sStr{1+x}),obj.objFcn.cmpData,'un',0)];
                       
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
            cMdl = obj.jTable.getColumnModel.getColumn(iCol-1);
            
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
        
        % --- reorders the table rows
        function reorderTableRows(obj)
            
            % java imports
            import javax.swing.RowFilter            
            
            % resets the row sorter filter
            jRowSort = obj.jTable.getRowSorter;
            jRowSort.setRowFilter(RowFilter.andFilter(obj.objFcn.cFiltTot))
            
            % resets the function compatibility colours
            obj.resetFuncCompColours()               
            
        end        
        
    end
    
    % static class methods
    methods (Static)
        
    end    
    
    % private class methods
    methods (Access = private)
        
        % --- sets a class object field
    	function SetDispatch(obj, propname, varargin)                    
            obj.baseObj.(propname) = varargin{:};        
        end
        
        % --- gets a class object field
        function varargout = GetDispatch(obj, propname)       
            varargout{:} = obj.baseObj.(propname);        
        end
        
    end       
end
