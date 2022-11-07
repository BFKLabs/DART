classdef DataTableObject < handle

    % class properties
    properties
        
        % main class fields
        hFig
        hTab
        iTab
        hPanelD
        
        % table objects
        jTable
        jTableMod
        jView
        jScP       
        jSBH
        jSBV
        hScP
        hSBH
        hSBV                
        rwTable
        
        % array fields
        Data
        szD
        nRowD
        nColD
        vPpr
        
        % other property fields                        
        cellSz
        tLim0
        
        % other scalar fields
        iR0 = 0;
        iC0 = 0;
        tSleep = 1;
        tPause = 0.05;
        isInit = true;
        keyDown = false;
        isUpdating = false;
        
        % fixed variable fields
        a = {''};
        b = '';
        sbDim = 17;
        gCol = 0.7;
        cnCol = 0.9;
        hght0 = 22;
        hghtR = 18;
        dHghtT = 30;
        cWidC = 72;
        cWidR = 50;
        nRow = 60;
        nCol = 50;        
        
        % java colours
        GRID
        CORNER
        WHITE = java.awt.Color(1,1,1);
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = DataTableObject(hPanelD,hTab,iTab)
            
            % sets the input arguments
            obj.hTab = hTab;
            obj.iTab = iTab;
            obj.hPanelD = hPanelD;
            
            % initialises the class fields and objects
            obj.initClassFields();
            obj.initClassObjects();
            
            % resets the initalisation flag
            pause(0.01);
            obj.isInit = false;
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % memory allocation   
            obj.vPpr = zeros(1,2);
            obj.hFig = findall(0,'tag','figDataOutput');
            
            % sets the property java colours 
            obj.GRID = java.awt.Color(obj.gCol,obj.gCol,obj.gCol);
            obj.CORNER = java.awt.Color(obj.cnCol,obj.cnCol,obj.cnCol);            
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
            % java class import
            import javax.swing.*
            import javax.swing.table.*                                                                    
            
            % creates the table model object  
            obj.setupTableModel();            
            
            % creates the view object in the table
            obj.jTable = JTable(obj.jTableMod);
            
            % sets up the components of the table
            obj.setupTableHeader(); 
            obj.setupViewportObject(); 
            obj.setupRowHeaderView();            
            obj.setJavaTableProps();    
            obj.addDataTablePopupMenu();
            
            % sets up the vertical scrollbars              
            [obj.jSBH,obj.hSBH] = obj.setupScrollBar(0);
            [obj.jSBV,obj.hSBV] = obj.setupScrollBar(1);            

            % resets the scrollbar policy
            obj.jScP.setVerticalScrollBarPolicy(21);
            obj.jScP.setHorizontalScrollBarPolicy(31);
            obj.jScP.repaint();                             
            
            % resizes the table columns
%             autoResizeTableColumns(obj.jTable);
            obj.cellSz = obj.jTable.getCellRect(0,0,1);              
            obj.tLim0 = obj.getVisibleTableDim();

        end
        
        % --- resets the object units
        function resetObjectUnits(obj)
            
            set(obj.hScP,'Units','Normalized');
            set(obj.hSBH,'Units','Normalized');
            set(obj.hSBV,'Units','Normalized');

        end        
            
        % ------------------------------------ %
        % --- TABLE OBJECT SETUP FUNCTIONS --- %
        % ------------------------------------ %

        % --- sets up the table header object
        function setupTableHeader(obj)
            
            % java class import
            import javax.swing.*            
            
            % retrieves the table header dimensiongs
            jTH = obj.jTable.getTableHeader();
            sz0 = jTH.getPreferredSize();
            
            % updates the table header
            jTH.setBackground(java.awt.Color(0.5,0.5,0.5))
            jTH.setPreferredSize(java.awt.Dimension(sz0.width,obj.hght0));
            jTH.getDefaultRenderer.setHorizontalAlignment(JLabel.CENTER);
            jTH.setReorderingAllowed(false);
            jTH.repaint();
            
        end        
        
        % --- sets up the java table model
        function setupTableModel(obj)
            
            % java class import
            import javax.swing.table.*             
            
            % initialisations
            cbFcnT = @obj.tableDataEdit;
            cTypeT = 'TableChangedCallback';
            
            % creates the table model object            
            cHdr0 = arrayfun(@(x)(obj.getColString(x)),1:obj.nCol,'un',0);
            obj.jTableMod = DefaultTableModel(obj.Data,cHdr0);
            
            % sets the java object properties/callback functions
            addJavaObjCallback(obj.jTableMod,cTypeT,cbFcnT)
            obj.jTableMod.setRowCount(obj.nRow)
            obj.jTableMod.setColumnCount(obj.nCol)
            
        end
        
        % --- sets up the viewport object
        function setupViewportObject(obj)
            
            % java class import
            import javax.swing.*            
            
            % sets up the table position vector
            tPosD = obj.getDataTablePos();
            tPosD(2:4) = [obj.sbDim,tPosD(3:4)-obj.sbDim];
            
            % creates the java object
            [obj.jScP, obj.hScP] = ...
                createJavaComponent(JScrollPane(obj.jTable), [], obj.hTab);
            set(obj.hScP,'Position',tPosD,'tag','hSP',...
                'UserData',obj.iTab,'Interruptible','off')
            
            % sets the scrollpane objects
            obj.jScP.setViewportView(obj.jTable);            
            obj.jScP.setVerticalScrollBarPolicy(22);
            obj.jScP.setHorizontalScrollBarPolicy(32);
            obj.jScP.repaint();                                   
            
        end        
        
        % --- sets up the row header view objects
        function setupRowHeaderView(obj)
            
            % java class import
            import javax.swing.*            
            
            % creates the table row headers 
            obj.rwTable = RowNumberTable(obj.jTable,2);
            
            % sets the dimensions size
            szR0 = obj.rwTable.getPreferredSize();
            szR = java.awt.Dimension(obj.cWidR,szR0.getHeight());
            obj.rwTable.setPreferredSize(szR);
            
            % sets the other row table header properties            
            obj.rwTable.getTableHeader().setBackground(obj.WHITE);
            obj.jScP.setRowHeaderView(obj.rwTable)            
            
            % sets the top left corner object
            jLabel = JLabel("");
            jLabel.setBorder(UIManager.getBorder("TableHeader.cellBorder"))
            jLabel.setBackground(obj.CORNER);
            obj.jScP.setCorner("UPPER_LEFT_CORNER",jLabel)            
            
        end    
        
        % --- sets the java table properties
        function setJavaTableProps(obj)
            
            % initialisations
            cTypeKP = 'KeyPressedCallback';
            cTypeKR = 'KeyReleasedCallback';
            cbFcnKP = @obj.tableDataKeyPress;
            cbFcnKR = @obj.tableDataKeyRelease;
            
            % table properties update
            LSM = obj.jTable.getSelectionModel();
            obj.jTable.setSelectionMode(LSM.MULTIPLE_INTERVAL_SELECTION)
            obj.jTable.setColumnSelectionAllowed(true);
            obj.jTable.setRowSelectionAllowed(true);            
            obj.jTable.setGridColor(obj.GRID);   
            obj.jTable.setRowHeight(obj.hghtR);
            obj.jTable.repaint();  
            
            % resets the column widths                
            obj.resetTableColumnWidth();  
            obj.jTable.setAutoResizeMode(obj.jTable.AUTO_RESIZE_OFF)
            
            % adds the table callback functions
            addJavaObjCallback(obj.jTable,cTypeKP,cbFcnKP)
            addJavaObjCallback(obj.jTable,cTypeKR,cbFcnKR)
            obj.jView = obj.jTable.getParent();            
            
            % table update (REMOVE ME)
            pause(0.01);
            
        end
        
        % --- sets up the scroll bar objects
        function [jSB,hSB] = setupScrollBar(obj,isVert)
            
            % java class import
            import javax.swing.*
            import javax.swing.table.*            
            
            % initialisations
            cbFcnV = {@obj.viewAdjustFunc,double(1+isVert)};
            cTypeV = 'AdjustmentValueChangedCallback';
            
            % sets up the viewport size dimension vector
            szDV = obj.getViewportDim();           
            
            % scrollbar position vector
            sbPos = zeros(1,4);
            sbPos(4 - isVert) = obj.sbDim;
            
            % sets the position vector components (based on orientation)
            if isVert
                % case is a vertical scrollbar
                sbPos([1,2,4]) = [szDV(1)+1,obj.sbDim,szDV(2)];
            else
                % case is a horizontal scrollbar
                sbPos(1:3) = [1,1,szDV(1)];
            end
            
            % creates the object            
            [jSB,hSB] = createJavaComponent(JScrollBar(),sbPos,obj.hTab);            
            
            % sets the table objects                        
            addJavaObjCallback(jSB,cTypeV,cbFcnV)                        
            jSB.setOrientation(isVert); 
            jSB.setBorder(UIManager.getBorder("TableHeader.cellBorder"))            
            jSB.setBlockIncrement(1);
            jSB.setMaximum(1);
            jSB.setEnabled(0);                        
            
        end        
        
        % --- sets the datasheet table pop-up menus
        function addDataTablePopupMenu(obj)
            
            % initialisations
            addSep = [0,1,0,0];
            jMenu = javax.swing.JPopupMenu;
            cType = 'ActionPerformedCallback';
            lblStr = {'Copy Selection','Select All',...
                'Insert Sheet Row(s)/Column(s)',...
                'Delete Sheet Row(s)/Column(s)'};
            cbFcn = {@obj.menuCopyFcn,@obj.menuSelectFcn,...
                     @obj.menuInsertFcn,@obj.menuDeleteFcn};
            
            % creates/adds the menu items
            for i = 1:length(cbFcn)
                % creates the menu item
                hMenu = javax.swing.JMenuItem(lblStr{i});
                addJavaObjCallback(hMenu,cType,cbFcn{i})
                
                % adds the menu item to the popup menu
                jMenu.add(hMenu);
                if addSep(i)
                    jMenu.addSeparator;
                end
            end
            
            % sets the tree mouse-click callback
            cbFcnT = {@obj.mousePressed,jMenu};
            addJavaObjCallback(obj.jTable,'MousePressedCallback',cbFcnT)            
            
        end
        
        % ---------------------------- %
        % --- POPUP MENU FUNCTIONS --- %
        % ---------------------------- % 
        
        % --- copy menu item
        function menuCopyFcn(obj, ~, ~)
            
            % initialisations
            DataC = obj.Data;
            [m,n] = size(DataC);
            iRow0 = obj.jTable.getSelectedRows();
            iCol0 = obj.jTable.getSelectedColumns();
            
            % determines if the user can select the data            
            if isempty(iRow0) || isempty(iCol0)                
                % outputs a message to screen
                mStr = 'All sheet data has been copied to the clipboard.';
            else                
                % sets the reduces data array
                iRow = (iRow0(1)+1):min(m,iRow0(end)+1);
                iCol = (iCol0(1)+1):min(n,iCol0(end)+1);
                DataC = DataC(iRow,iCol);
                mStr = 'Selected sheet data has been copied to the clipboard.';
            end
            
            % copies the data to the clipboard
            waitfor(msgbox(mStr,'Data Copying','modal'))
            mat2clip(cellfun(@char,num2cell(DataC),'un',0))
            
        end        
        
        % --- select all menu item
        function menuSelectFcn(obj, ~, ~)
            
            % selects the entire table
            obj.jTable.selectAll
            
        end
        
        % --- insert row/column menu item
        function menuInsertFcn(obj, ~, ~)
            
            % runs the data alteration sub-gui
            altObj = AlterTableData(obj,1);
            if altObj.ok
                % inserts the data based on the selection type
                obj.addTableData(altObj)
                                
                % updates the table data
                obj.setTableData();
                altObj.resetTableSelection();
            end
            
        end
        
        % --- insert row/column menu item
        function menuDeleteFcn(obj, ~, ~)
            
            % runs the data alteration sub-gui
            altObj = AlterTableData(obj,2);
            if altObj.ok
                % inserts the data based on the selection type
                obj.removeTableData(altObj)
                
                % updates the table data
                obj.setTableData();
                altObj.resetTableSelection();
            end            
            
        end             

        % --------------------------------------- %
        % --- DATA TABLE ALTERATION FUNCTIONS --- %
        % --------------------------------------- %        
        
        % --- adds a row to the data table
        function addTableData(obj,altObj)
            
            % determines the alignment/type of insertion
            isRow = mod(altObj.iSel-1,2);
            isFull = floor((altObj.iSel-1)/2);            
            
            % adds empty table data (based on the alteration type)
            if isRow
                % case is adding rows to the table
                if isFull
                    % case is adding entire rows
                    obj.addTableRows(altObj.iR0)
                    
                else
                    % case is shifting cells down
                    obj.addTableRows(altObj.iR0,altObj.iC0+1)
                end
            else
                % case is adding columns to the table
                if isFull
                    % case is adding entire columns
                    obj.addTableColumns(altObj.iC0)
                    
                else
                    % case is shifting cells right
                    obj.addTableColumns(altObj.iC0,altObj.iR0+1)
                end                
            end
            
        end        
        
        % --- adds the table columns
        function addTableColumns(obj,iC,iR)
            
            % sets the default input arguments
            if ~exist('iR','var'); iR = 1:obj.szD(1); end                        
            
            % sets up the temporary data array
            DataApp = string(repmat(obj.a,1,length(iC)));
            DataT = combineCellArrays(obj.Data,DataApp,1,obj.b);
            
            % appends the empty array into the temporary data array
            [xi0,xi1] = deal(1:iC(1),(iC(1)+1):size(obj.Data,2));
            DataAdd = string(repmat(obj.a,length(iR),length(iC)));
            DataT(iR,:) = [obj.Data(iR,xi0),DataAdd,obj.Data(iR,xi1)];
            
            % resets the temporary data array
            obj.Data = DataT;
            
        end
        
        % --- adds the table columns
        function addTableRows(obj,iR,iC)
            
            % sets the default input arguments
            if ~exist('iC','var'); iC = 1:obj.szD(2); end
            
            % sets up the temporary data array
            DataApp = string(repmat(obj.a,length(iR),1));
            DataT = combineCellArrays(obj.Data,DataApp,0,obj.b);
            
            % appends the empty array into the temporary data array
            [xi0,xi1] = deal(1:iR(1),(iR(1)+1):size(obj.Data,1));
            DataAdd = string(repmat(obj.a,length(iR),length(iC)));
            DataT(:,iC) = [obj.Data(xi0,iC);DataAdd;obj.Data(xi1,iC)];
            
            % resets the temporary data array
            obj.Data = DataT;            
            
        end                
        
        % --- removes a row to the data table
        function removeTableData(obj,altObj)
            
            % determines the alignment/type of insertion
            isRow = mod(altObj.iSel-1,2);
            isFull = floor((altObj.iSel-1)/2);                        
            
            % adds empty table data (based on the alteration type)
            if isRow
                % case is removing rows from the table
                if isFull
                    % case is removing entire rows
                    obj.removeTableRows(altObj.iR0);
                    
                else
                    % case is shifting cells up
                    obj.removeTableRows(altObj.iR0,altObj.iC0+1);
                end                
            else
                % case is removing columns from the table
                if isFull
                    % case is removing entire columns
                    obj.removeTableColumns(altObj.iC0);                    
                    
                else
                    % case is shifting cells left
                    obj.removeTableColumns(altObj.iC0,altObj.iR0+1);
                end                                
            end
            
        end
        
        % --- removes the table columns
        function removeTableColumns(obj,iC,iR)
            
            % sets the default input arguments
            if ~exist('iR','var'); iR = 1:obj.szD(1); end
            
            % creates a temporary copy of the data array
            DataT = obj.Data;
            
            % appends the empty array into the temporary data array
            indCT = ~setGroup(iC+1,[1,size(obj.Data,2)]);
            indCF = 1:sum(indCT);
            DataT(iR,indCF) = DataT(iR,indCT);
            
            % resets the temporary data array
            obj.Data = DataT; 
            
        end
        
        % --- removes the table rows
        function removeTableRows(obj,iR,iC)
            
            % sets the default input arguments
            if ~exist('iC','var'); iC = 1:obj.szD(2); end            
            
            % creates a temporary copy of the data array
            DataT = obj.Data;            
            
            % appends the empty array into the temporary data array
            indRT = ~setGroup(iR+1,[size(obj.Data,1),1]);
            indRF = 1:sum(indRT);
            DataT(indRF,iC) = DataT(indRT,iC);
            
            % resets the temporary data array
            obj.Data = DataT;

        end        
        
        % -------------------------- %
        % --- CALLBACK FUNCTIONS --- %
        % -------------------------- %

        % --- data table keypress callback function
        function tableDataKeyRelease(obj,~,~)
            
            % resets the key down flag 
            obj.keyDown = false;
            
        end
        
        % --- data table keypress callback function
        function tableDataKeyPress(obj,~,evnt)
            
            % resets the flag
            if obj.isUpdating || obj.keyDown
                return
            end
            
            % determines the alternative key press
            [iRowS,iColS] = deal([]);
            hasCtrl = get(evnt,'ControlDown');                                  
            
            % retrieves the currently selected cell row/column index
            iRow = obj.jTable.getSelectedRow;
            iCol = obj.jTable.getSelectedColumn;            
            
            % if the row/column index isn't unitary then exit            
            if (length(iRow) ~= 1) || (length(iCol) ~= 1)
                return
            end
            
            % updates the key down flag
            isCont = true;
            obj.keyDown = true;            
            
            % performs the action based on the key press
            switch get(evnt,'ExtendedKeyCode')                   
                case 33
                    % case is page-up
                    if (iRow > 0) || (obj.iR0 == 0)
                        % if not the first row, then exit
                        isCont = false;
                        
                    else
                        % otherwise, reset the row index
                        obj.iR0 = max(0,obj.iR0 - obj.tLim0(1));
                        [iRowS,iColS] = deal(0,iCol);
                    end
                    
                case 34
                    % case is page-down                    
                    if ((iRow + 1) < obj.tLim0(1)) || ...
                            ((obj.iR0 + 1) == obj.nRowD)
                        % if not the last row, then exit
                        isCont = false;
                        
                    else
                        % otherwise, reset the row index
                        rMax = max(0,obj.nRowD - obj.tLim0(1));
                        obj.iR0 = min(rMax,obj.iR0 + obj.tLim0(1));
                        [iRowS,iColS] = deal(obj.tLim0(1)-1,iCol);
                    end
                    
                case 37
                    % case is the left key
                    if hasCtrl
                        % user is pressing Ctrl
                        obj.iC0 = 0;
                        [iRowS,iColS] = deal(iRow,0);
                        
                    elseif (iCol > 0) || (obj.iC0 == 0) 
                        % case is not the first column (so exit function)
                        isCont = false;
                        
                    else
                        % case is no other key type is pressed 
                        obj.iC0 = obj.iC0 - 1;
                        [iRowS,iColS] = deal(iRow,0);
                    end
                    
                case 38
                    % case is the up key
                    if hasCtrl
                        % user is pressing Ctrl
                        obj.iR0 = 0;
                        [iRowS,iColS] = deal(0,iCol);
                        
                    elseif (iRow > 0) || (obj.iR0 == 0) 
                        % case is not the first row (so exit function)
                        isCont = false;
                        
                    else
                        % case is no other key type is pressed 
                        obj.iR0 = obj.iR0 - 1;
                    end                    
                    
                case 39
                    % case is the right key
                    if hasCtrl
                        % user is pressing Ctrl
                        obj.iC0 = max(0,obj.nColD - obj.tLim0(2));
                        [iRowS,iColS] = deal(iRow,obj.tLim0(2)-1);
                        
                    elseif ((iCol + 1) < obj.tLim0(2)) || ...
                            ((obj.iC0 + obj.tLim0(2)) == obj.nColD)
                        % if not the last column (or edge) then exit
                        isCont = false;
                        
                    else
                        % case is no other key type is pressed 
                        obj.iC0 = obj.iC0 + 1;
                        [iRowS,iColS] = deal(iRow,obj.tLim0(2)-1);
                    end                    
                    
                case 40
                    % case is the down key                    
                    if hasCtrl
                        % user is pressing Ctrl
                        obj.iR0 = max(0,obj.nRowD - obj.tLim0(1));
                        [iRowS,iColS] = deal(obj.tLim0(1)-1,iCol);
                        
                    elseif ((iRow + 1) < obj.tLim0(1)) || ...
                            ((obj.iR0 + obj.tLim0(1)) == obj.nRowD)                        
                        % if not the last row (or edge) then exit
                        isCont = false;
                        
                    else
                        % case is no other key type is pressed 
                        obj.iR0 = obj.iR0 + 1;
                        [iRowS,iColS] = deal(obj.tLim0(1)-1,iCol);
                    end                    
                    
                otherwise
                    % case is the other keys
                    isCont = false;
            end     
            
            % flag that the key is being pressed
            if isCont
                obj.isUpdating = true;
            else
                obj.keyDown = false;
                return
            end
            
%             %
%             obj.jTable.changeSelection(-1,-1,-1,-1);
%             obj.jTable.repaint
%             pause(0.01);
            
            % updates the table 
%             pause(0.01);
            obj.setTableData();
            
            % re-selects the cell (if required)
            if ~isempty(iRowS)
                obj.jTable.changeSelection(iRowS,iColS,0,0);
            end
            
            % clears the warning and screen buffer
            pause(0.05); drawnow();
            fprintf(' \b');
            obj.isUpdating = false;
            
            % runs the key-press cooldown timer
            tP = tic;
            while obj.keyDown
                % if the time exceeds the pause time, then reset the key
                % down flag
                if toc(tP) > obj.tPause
                    obj.keyDown = false;
                end
                    
                % pauses for a little bit...
                java.lang.Thread.sleep(obj.tSleep);
            end
            
        end        
        
        % --- data table cell edit callback function
        function tableDataEdit(obj,hObject,evnt)
            
%             % retrieves the data struct fields
%             iSelT = obj.iSel(obj.cTab);
%             mIndT = obj.mInd{obj.cTab}{iSelT};
%             
%             % retrieves the row/column indices
%             jTab = obj.jTable{obj.cTab};
%             [iRow,iCol] = deal(evnt.getFirstRow,evnt.getColumn);
%             [nwVal,mIndNw] = deal(jTab.getValueAt(iRow,iCol),[iRow,iCol]);
%             
%             % determines if the manual editting indices need to be updated
%             if isempty(nwVal)
%                 % cell is being cleared, so determines if a matching index needs to
%                 % be removed from the index array
%                 if ~isempty(mIndT)
%                     ii = cellfun(@(x)(~isempty(jTab.getValueAt(x(1),x(2)))),num2cell(mIndT,2));
%                     mIndT = mIndT(ii,:);
%                 end
%             else
%                 % cell is being added, so determined if a new index needs 
%                 % to be added to the index array
%                 if isempty(mIndT)
%                     % manual index array is empty, so add the new value
%                     mIndT = mIndNw;
%                 elseif ~any(cellfun(@(x)...
%                         (isequal(mIndNw,x)),num2cell(mIndT,2)))
%                     % otherwise, if the new indices is not included in the 
%                     % index array then append the new values to the array
%                     mIndT = [mIndT;mIndNw];
%                 end
%                 
%                 % updates the string within the sheet data array
%                 obj.Data{obj.cTab}{iSelT}{mIndNw(1)+1,mIndNw(2)+1} = nwVal;
%             end
%             
%             % updates the data struct
%             obj.mInd{obj.cTab}{iSelT} = mIndT;
            
        end        
        
        % --- scrollbar adjustment callback function
        function viewAdjustFunc(obj,hObject,~,Type)
            
            % checks the update flag (exit if updating, continue otherwise)
            if obj.isUpdating || obj.isInit
                return
            end                        
                        
            % determines if the viewport has changed
            valSB = get(hObject,'Value');
            if (valSB == obj.vPpr(Type))
                % if not, then exit
                obj.isUpdating = false;
                return
            else
                % otherwise, flag that an update is occuring
                [obj.isUpdating,valSB0] = deal(true,valSB);
                java.lang.Thread.sleep(10);
            end
            
            % keep looping until there is no change in location
            while true
                % determines if there is a change in the row/column indices
                valSB = get(hObject,'Value');
                if (valSB == valSB0)
                    % if not, then exit
                    break
                else
                    % otherwise, update the indices
                    valSB0 = valSB;
                    java.lang.Thread.sleep(20);
                end
            end            
            
            % sets the rows/columns of the table that are currently visible
            obj.vPpr(Type) = valSB;            
            
            % updates the row/column indices
            if Type == 2
                obj.iR0 = get(hObject,'Value');
            else
                obj.iC0 = get(hObject,'Value');
            end
            
            % updates the table data and resets the update flag
            obj.setTableData();
            obj.isUpdating = false;
            
        end        

        % ----------------------------------- %
        % --- TABLE DATA UPDATE FUNCTIONS --- %
        % ----------------------------------- %
        
        % --- updates the table data with the array, DataNw
        function updateTableData(obj,DataNw)
            
            % sets the size of the current data array
            obj.szD = size(DataNw);
            [obj.nRowD,obj.nColD] = deal(obj.szD(1),obj.szD(2));
            
            % updates the scrollbar slider properties
            obj.updateSliderProps(obj.jSBV,obj.nRowD,obj.tLim0(1))
            obj.updateSliderProps(obj.jSBH,obj.nColD,obj.tLim0(2))        
            
            % sets the input data and resets the row/column offset
            obj.Data = string(obj.expandWorksheetTable(DataNw));
            [obj.iR0,obj.iC0] = deal(0);            
            obj.isUpdating = false;            
            
            % updates the table data
            obj.setTableData();                        
            
        end
        
        % --- updates the table data
        function setTableData(obj)
                        
            % retrieves the 
            iR = obj.iR0 + (1:obj.tLim0(1))';
            iC = obj.iC0 + (1:obj.tLim0(2))';            
            pause(0.01);            
            
            % updates the data table
            DataF = obj.Data(iR,iC);
            cHdr = arrayfun(@(x)(obj.getColString(x)),iC,'un',0);           
            obj.jTableMod.setDataVector(DataF,cHdr)                   
            
            % resets the row offsetcount
            obj.rwTable.setRowOffsetCount(obj.iR0);
            obj.rwTable.repaint();                     
            
            % resets the slider markers
            set(obj.jSBV,'Value',obj.iR0)
            set(obj.jSBH,'Value',obj.iC0)            
            
        end
        
        % --- resizes the data table (based on current figure dimensions)
        function resizeTableData(obj)
            
            % resets the visible table dimensions
            obj.tLim0 = obj.getVisibleTableDim();
            obj.setTableData();
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- retrieves the data table position vector
        function tPosD = getDataTablePos(obj)
            
            tPosD0 = getTabPosVector(obj.hPanelD);
            tPosD = [1,1,tPosD0(3:4)-[5,32]];
            
        end        
        
        % --- retrieves the viewport dimension vector
        function szD = getViewportDim(obj)
            
            tPosD = obj.getDataTablePos();
            szD = tPosD(3:4) - obj.sbDim;
            
        end        
        
        % --- retrieves the visible table row/column dimensions
        function tLim = getVisibleTableDim(obj)
            
            % determiens the number of visible row/column counts
            szD = obj.getViewportDim();            
            nColL = (szD(1) - (3 + obj.cWidR))/obj.cellSz.getWidth();
            nRowL = (szD(2) - (obj.hght0 + 2))/obj.cellSz.getHeight();
            
            % sets the row/column limit size
            tLim = ceil([nRowL,nColL]);
            
        end        
        
        % --- expands the worksheet data array to meet min requirements
        function Data = expandWorksheetTable(obj,Data)
        
            % ensures the table has a minimum size
            [rSz,cSz] = size(Data);
            
            % row expansion (if required)
            if (rSz < obj.nRow) 
                Data = [Data;repmat({''},obj.nRow-rSz,cSz)];
                rSz = obj.nRow;
            end
            
            % column expansion (if required)
            if (cSz < obj.nCol)
                Data = [Data,repmat({''},rSz,obj.nCol-cSz)]; 
            end
            
        end
            
        % --- resets the table column widths
        function resetTableColumnWidth(obj,nCol)
            
            if ~exist('nCol','var')
                nCol = obj.jTable.getColumnCount();
            end
            
            % sets the columns minimum width
            for i = 1:nCol
                cWid0 = obj.jTable.getColumnModel().getColumn(i-1).getPreferredWidth();
                obj.jTable.getColumnModel().getColumn(i-1).setMinWidth(cWid0);
                obj.jTable.getColumnModel().getColumn(i-1).setPreferredWidth(cWid0);            
            end            
            
        end        
        
    end

    % static class methods
    methods (Static)
        
        % --- retrieves the column string
        function cStr = getColString(iStr)
            
            % array setup
            nLen = max(1,ceil(log(iStr)/log(26)));
            iStrF = zeros(1,nLen);
            
            % sets the index values for each 
            for i = 1:nLen
                iStrM = mod(iStr-1,26^i) + 1;
                iStrF(end-(i-1)) = iStrM/(26^(i-1));
                iStr = iStr - iStrM;
            end
            
            % sets the string based on the type
            cStr = char(iStrF+64);
            
        end
        
        % --- updates the scrollbar slider properties
        function updateSliderProps(jSB,nD,tD)
            
            % determines if the data row count exceeds
            isExc = nD > tD;
            
            % sets the slider properties
            jSB.setMaximum(1+isExc*(nD-1));
            jSB.setVisibleAmount(1+isExc*(tD-1));            
            jSB.setEnabled(isExc);            
            
        end        
        
        % Set the mouse-press callback
        function mousePressed(~, event, jMenu)
            
            % right-click is like a Meta-button
            if event.isMetaDown
                % retrieves the table object
                jTab = event.getSource;
                if jTab.isEditing
                    % if the user is editing the cell, then force stop editing
                    jTab.getCellEditor().stopCellEditing();
                    pause(0.05);
                end
                
                % Display the (possibly-modified) context menu
                jMenu.show(jTab, event.getX, event.getY);
                jMenu.repaint;
            end
            
        end        
        
    end    
    
end