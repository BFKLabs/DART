classdef OpenSolnFuncTab < dynamicprops & handle
    % class properties
    properties        
        % function/experiment data fields
        fcnData
        fcnInfo
        reqGrp
        cmpData
        
        % table objects
        tabCR1
        tabCR2
        jTable        
        tabData
        
        % function filter objects
        jSP
        jTree
        jRoot
        
        % other class objects
        cWid0
        expWid = 40;
        isUpdating = false;        
        
    end
    
    % private class properties    
    properties (Access = private)
    	baseObj
    end        
    
    % class methods
    methods
        % class constructor
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
            
            % initialises the function information and requirement groups 
            obj.setupFuncReqInfo();
            obj.initFuncReqGroups();
            
            % determines (from the current batch of expts) the 
            % compatibility of the functions with loaded experiments
            obj.setupExptInfo();
            obj.detExptCompatibility();       
            
            % initialises the other gui objects
            obj.initFuncDepTable();
            obj.initFuncCellComp();
            obj.initFilterTree();
            
            % resets the popup menu user data
            lStr = get(hPopup,'String');
            rFld = fieldnames(obj.reqGrp);
            nGrp = cellfun(@(x)(numel(getStructField(obj.reqGrp,x))),rFld);

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
            obj.treeUpdateClick([], []);            
            
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
        
        % --- sets up the function compatibility information 
        function setupExptInfo(obj)
            
            % field retrieval
            if isempty(obj.sInfo); return; end            
            
            % parameters
            nReq = 4;
            tLong = 12;

            % memory allocation
            nExp = length(obj.sInfo);
            obj.fcnInfo = cell(nExp,nReq);
            snTot = cellfun(@(x)(x.snTot),obj.sInfo,'un',0);

            % other initialisations
            expStr = {'1D','2D'};
            durStr = {'Short','Long'};
            iMov = cellfun(@(x)(x.iMov),snTot,'un',0);
            stimP = cellfun(@(x)(x.stimP),snTot,'un',0);

            % calculates the experiment duration in terms of hours
            Ts = cellfun(@(x)(x.T{1}(1)),snTot);
            Tf = cellfun(@(x)(x.T{end}(length(x.T{end}))),snTot);
            Texp = convertTime(Tf-Ts,'s','h');

            % sets the duration string
            obj.fcnInfo(:,1) = ...
                        arrayfun(@(x)(durStr{1+(x>tLong)}),Texp,'un',0);

            % for each of the experiments, strip out the important 
            % information fields from the solution file data
            for iExp = 1:nExp
                % experiment shape string
                obj.fcnInfo{iExp,2} = expStr{1+iMov{iExp}.is2D};
                if ~isempty(iMov{iExp}.autoP)
                    obj.fcnInfo{iExp,2} = sprintf('%s (%s)',...
                                obj.fcnInfo{iExp,2},iMov{iExp}.autoP.Type);
                end

                % stimuli type string
                if isempty(stimP{iExp})
                    obj.fcnInfo{iExp,3} = 'None';
                else
                    stimStr = fieldnames(stimP{iExp});
                    obj.fcnInfo{iExp,3} = strjoin(stimStr,'/');
                end

                % special type string (FINISH ME!)
                obj.fcnInfo{iExp,4} = 'None';    
            end        
            
        end
        
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
            [jScroll, hContainer] = javacomponent(jScroll, [], hPanel);
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
            
            % field retrieval
            jTableMod = obj.jTable.getModel();
            jTableMod.fireTableStructureChanged()
           
            % column old/new counts
            nCol0 = obj.jTable.getColumnCount();
            nColHdr = (size(obj.fcnData,2) + 1);
            nColNw = nColHdr + obj.nExp;

            % determines (from the current batch of expts) the 
            % compatibility of the functions with loaded experiments
            obj.setupExptInfo();
            obj.detExptCompatibility(); 
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
            [nFunc,nHdr] = size(obj.fcnData);
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
                        isComp = double(obj.cmpData(i,k));
                        obj.tabCR2.setCellBgColor(i-1,j-1,cCol{1+isComp});
                    end
                end
            end

            % repaints the table
            obj.jTable.repaint();            
            
        end
        
        % --- initialises the function filter explorer tree
        function initFilterTree(obj)
            
            % imports the checkbox tree
            import com.mathworks.mwswing.checkboxtree.*

            % parameters
            dX = 5;
            fldStr = {'Analysis Scope','Duration Requirements',...
                      'Region Shape Requirements',...
                      'Stimuli Requirements','Special Requirements'};

            % field retrieval
            handles = obj.hGUI;
            hPanel = handles.panelFuncFilter;
            rFld = fieldnames(obj.reqGrp);

            % creates the root node
            nodeStr = 'Function Requirement Categories';
            obj.jRoot = DefaultCheckBoxNode(nodeStr);
            obj.jRoot.setSelectionState(SelectionState.SELECTED);

            % creates all the requirement categories and their sub-nodes
            for i = 1:length(rFld)
                % retrieves the sub 
                rVal = getStructField(obj.reqGrp,rFld{i});
                if length(rVal) > 1
                    % sets the requirement type node
                    jTreeR = DefaultCheckBoxNode(fldStr{i});
                    obj.jRoot.add(jTreeR);
                    jTreeR.setSelectionState(SelectionState.SELECTED);    

                    % adds on each sub-category for the requirements node
                    for j = 1:length(rVal)
                        jTreeSC = DefaultCheckBoxNode(rVal{j});
                        jTreeR.add(jTreeSC);
                        jTreeSC.setSelectionState(SelectionState.SELECTED);
                    end
                end
            end

            % retrieves the object position
            objP = get(hPanel,'position');

            % creates the final tree explorer object
            obj.jTree = com.mathworks.mwswing.MJTree(obj.jRoot);
            jTreeCB = handle(CheckBoxTree(obj.jTree.getModel),...
                                                'CallbackProperties');
            obj.jSP = com.mathworks.mwswing.MJScrollPane(jTreeCB);

            % creates the scrollpane object
            wState = warning('off','all');
            tPos = [dX-[1 0],objP(3:4)-2*dX];
            [~,~] = javacomponent(obj.jSP,tPos,hPanel);
            warning(wState);

            % resets the cell renderer
            obj.jTree.setEnabled(false)
            obj.jTree.repaint;

            % sets the tree explorer callback functions
            set(jTreeCB,'MouseClickedCallback',{@obj.treeUpdateClick},...
                        'TreeCollapsedCallback',{@obj.treeCollapseClick},...
                        'TreeExpandedCallback',{@obj.treeExpandClick})        

            % resets the tree panel position
            nwHeight = jTreeCB.getMaximumSize.getHeight;
            obj.resetTreePanelPos(nwHeight)                           
            
        end      
        
        % --- callback for updating selection of the function filter tree
        function treeUpdateClick(obj, ~, ~)
            
            % java imports
            import javax.swing.RowFilter

            % if updating elsewhere, then exit
            if obj.isUpdating
                return
            end

            % initialisation
            rFld = fieldnames(obj.reqGrp);
            hCheck = findall(obj.hFig,'tag','checkGrpExpt');            

            % memory allocation
            cFiltTot = java.util.ArrayList;

            % determines if only compatible functions are to be displayed
            if get(hCheck,'Value')
                % if so, then create a regexp filter list for "yes" cells
                cFiltArr = java.util.ArrayList;     
                for i = 1:obj.jTable.getColumnCount
                    j = size(obj.fcnData,2)+(i+1); 
                    cFiltArr.add(RowFilter.regexFilter('Yes',j));
                end

                % adds the compatibility filter to the total filter
                cFiltTot.add(RowFilter.orFilter(cFiltArr));    
            end

            % creates the function filter objects
            for i = 1:obj.jRoot.getChildCount
                % retrieves the child node
                jNodeC = obj.jRoot.getChildAt(i-1);
                nStr = char(jNodeC.getUserObject);
                i0 = find(cellfun(@(x)(strContains(nStr,x)),rFld));

                % sets the filter field cell arrays
                switch char(jNodeC.getSelectionState)
                    case 'mixed'
                        % retrieves the leaf node objects
                        xiC = 1:jNodeC.getChildCount;
                        jNodeL = arrayfun(@(x)...
                                    (jNodeC.getChildAt(x-1)),xiC','un',0);

                        % determines which of the leaf nodes have been selected
                        isSel = cellfun(@(x)(strcmp(char...
                                (x.getSelectionState),'selected')),jNodeL);
                        fFld = cellfun(@(x)...
                                (x.getUserObject),jNodeL(isSel),'un',0);

                    otherwise
                        % case is either all or none are selected
                        fFld = getStructField(obj.reqGrp,rFld{i0});
                end  

                % creates the category filter array
                cFiltArr = java.util.ArrayList;
                for j = 1:length(fFld)
                    % loops through each requirement type setting the 
                    % regex filters
                    if i0 == 1
                        % case is the analysis scope requirement
                        cFiltArr.add(RowFilter.regexFilter(fFld{j}(1),i0));
                    else
                        % case is the other filter types, so split the 
                        % filter string into separate words
                        fFldSp = strsplit(fFld{j});
                        if length(fFldSp) == 1
                            % if the filter string is only one word, then 
                            % create the filter using this string
                            cFiltArr.add(RowFilter.regexFilter(fFld{j},i0));
                        else
                            % otherwise, create an and filter from each 
                            % of the separate words in the filter string
                            cFiltSp = java.util.ArrayList;
                            for k = 1:length(fFldSp)
                                cFiltSp.add(...
                                     RowFilter.regexFilter(fFldSp{k},i0));
                            end
                            cFiltArr.add(RowFilter.andFilter(cFiltSp));
                        end
                    end
                end

                % adds the category filter to the total filter
                cFiltTot.add(RowFilter.orFilter(cFiltArr));
            end

            % resets the row sorter filter
            jRowSort = obj.jTable.getRowSorter;
            jRowSort.setRowFilter(RowFilter.andFilter(cFiltTot))

            % resets the function compatibility colours
            obj.resetFuncCompColours()            
            
        end
        
        % --- callback for expanding a tree node
        function treeExpandClick(obj, hObject, ~)

            % flags that the tree is updating
            obj.isUpdating = true;

            % resets the tree panel dimensions
            nwHeight = hObject.getMaximumSize.getHeight;
            obj.resetTreePanelPos(nwHeight)
            pause(0.05);

            % flags that the tree is updating
            obj.isUpdating = false;            
            
        end
        
        % --- callback for expanding a tree node
        function treeCollapseClick(obj, hObject, ~)

            % flags that the tree is updating
            obj.isUpdating = true;

            % resets the tree panel dimensions
            nwHeight = hObject.getMaximumSize.getHeight;
            obj.resetTreePanelPos(nwHeight)
            pause(0.05);

            % flags that the tree is updating
            obj.isUpdating = false;                  
            
        end
        
        % --- resets the category tree dimensions
        function resetTreePanelPos(obj,hghtTree0)

            % tree height offset (manual hack...)
%             hghtTree0 = obj.jTree.getMaximumSize.getHeight;
            hghtTree = hghtTree0 + 2;

            % object retrieval
            handles = obj.hGUI;
            hPanel = handles.panelFuncFilter;
            hButton = handles.toggleFuncFilter;
            hTree = findall(hPanel,'type','hgjavacomponent');

            % other initialisations
            dX = 5;
            hghtPanel = hghtTree + 2*dX;
            bPos = getObjGlobalCoord(hButton);

            % ressets the tree/panel dimensions
            resetObjPos(hPanel,'Height',hghtPanel);
            resetObjPos(hPanel,'Bottom',bPos(2)-(hghtPanel+2*(1+dX)))
            resetObjPos(hTree,'Height',hghtTree)
            resetObjPos(hTree,'Bottom',dX)

        end
        
        % --- initialises the requirement grouping information
        function initFuncReqGroups(obj)

            % initialisations
            obj.reqGrp = struct();
            rType = {'Scope','Dur','Shape','Stim','Spec'};

            % retrieves the requirement information for each type
            for i = 1:length(rType)
                switch rType{i}
                    case 'Scope'
                        % case is the analysis scope
                        rGrpNw = {'Individual';'Single Expt';'Multi Expt'};

                    otherwise
                        % case is the other requirements
                        reqDataU = unique(obj.fcnData(:,i+1));
                        ii = strcmp(reqDataU,'None');    
                        rGrpNw = [reqDataU(ii);reqDataU(~ii)];
                end

                % appends the field to the data struct
                obj.reqGrp = setStructField(obj.reqGrp,rType{i},rGrpNw);
            end

        end
        
        % --- sets up the function requirement information
        function setupFuncReqInfo(obj)
           
            % initialisations
            nCol = 6;
            
            % retrieves the plotting function data struct
            pFldT = fieldnames(obj.pDataT);
            pData = cell2cell(cellfun(@(x)(num2cell...
                        (getStructField(obj.pDataT,x))),pFldT,'un',0));

            % other initialisations
            pFld = fieldnames(pData{1}.rI); 
            fcnData0 = cell(length(pData),nCol);             

            % sets the function information (for each listed function)
            for i = 1:length(pData)
                % sets the experiment name
                fcnData0{i,1} = pData{i}.Name; 

                % sets the other requirement fields
                for j = 1:(length(pFld)-1)
                    fcnData0{i,j+1} = getStructField(pData{i}.rI,pFld{j}); 
                end 
            end

            % determines the unique analysis functions
            [~,iB,~] = unique(fcnData0(:,1));
            obj.fcnData = fcnData0(iB,:);            
            
        end
        
        % --- determines the experiment compatibilities for each function
        function detExptCompatibility(obj)

            % if there is no loaded data, then exit
            if isempty(obj.sInfo); return; end
            
            % memory allocation
            nFunc = size(obj.fcnData,1);
            [nExp,nReq] = size(obj.fcnInfo);
            obj.cmpData = true(nFunc,nExp);

            % calculates the compatibility flags for each experiment
            for iFunc = 1:nFunc
                % retrieves the requirement data for the current function
                fcnDataF = obj.fcnData(iFunc,3:end);

                % determines if each of the requirements matches for each expt
                isMatch = true(nReq,nExp);
                for iReq = 1:nReq
                    if ~strcmp(fcnDataF{iReq},'None')
                        isMatch(iReq,:) = cellfun(@(x)strContains(...
                                    x,fcnDataF{iReq}),obj.fcnInfo(:,iReq));
                    end
                end

                % calculates the overall compatibility (all 
                obj.cmpData(iFunc,:) = all(isMatch,1);
            end

        end
        
        % --- resets the function compatibility colours
        function resetFuncCompColours(obj)

            % initialisations
            iCol0 = size(obj.fcnData,2) + 2;
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
            nFunc = size(obj.fcnData,1);            
            
            % sets up the function requirement information array            
            fcnDataT = obj.fcnData;
            fcnDataT(:,2:end) = centreTableData(fcnDataT(:,2:end));
            obj.tabData = [fcnDataT,repmat({' '},nFunc,1),...
                           arrayfun(@(x)(sStr{1+x}),obj.cmpData,'un',0)];
                       
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