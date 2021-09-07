classdef OpenSolnFileTab < dynamicprops & handle
    
    % class properties
    properties
        % other class fields
        sDir
        sDir0
        sFile
        
        % tab panel objects
        hTab
        hPanel
        hTabGrp
        jTabGrp  
        
        % explorer tree objects
        jMov
        jRoot 
        jTree
        
        % experiment info table objects
        tabCR1
        tabCR2
        jTable
        
        % temprary tree setup objects
        hMovT
        sFileT                             
        
        % scalar class properties
        iTab      
        iExp
        nTab = 3;        
        nExpMax = 4;
        tableUpdate = false;
        
        % other class properties
        fExtn = {'.soln','.ssol','.msol'};                
        
    end
    
    % private class properties    
    properties (Access = private)
    	baseObj
    end    
    
    % class methods
    methods
        % class constructor
        function obj = OpenSolnFileTab(baseObj)                                            
            
            % field initialisations
            obj.baseObj = baseObj;
            [obj.sDir,obj.sDir0] = deal(getappdata(baseObj.hFigM,'sDirO'));            
            
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
        
        % --- initialises all the object callback functions
        function initObjCallbacks(obj)
            
            % objects with normal callback functions
            cbObj = {'buttonSetDir','buttonAddSoln','buttonClearExpt',...
                     'buttonClearAll','buttonShowProtocol',...
                     'buttonHideProtocol'};
            for i = 1:length(cbObj)
                hObj = getStructField(obj.hGUI,cbObj{i});
                cbFcn = eval(sprintf('@obj.%sCB',cbObj{i}));
                set(hObj,'Callback',cbFcn)
            end            
            
            % objects with cell selection callback functions
            csObj = {'tableExptInfo'};
            for i = 1:length(csObj)
                hObj = getStructField(obj.hGUI,csObj{i});
                cbFcn = eval(sprintf('@obj.%sCS',csObj{i}));
                set(hObj,'CellSelectionCallback',cbFcn)
            end 
            
            % objects with cell edit callback functions
            ceObj = {'tableGroupNames'};
            for i = 1:length(ceObj)
                hObj = getStructField(obj.hGUI,ceObj{i});
                cbFcn = eval(sprintf('@obj.%sCE',ceObj{i}));
                set(hObj,'CellEditCallback',cbFcn)
            end  
            
        end
        
        % --- initialises the tab panel object properties
        function initObjProps(obj)
            
            % creates the load bar
            h = ProgressLoadbar('Loading Solution File Information...');
            
            % initialisations
            handles = obj.hGUI;
            hAx = handles.axesStim;
            hPanelT = handles.panelSolnExplorer;
            tStr = {'Video Solution Files (*.soln)',...
                    'Experiment Solution Files (*.ssol)',...
                    'Multi-Expt Solution Files (*.msol)'};
            
            % sets group name table to inactive (if loading analysis files)
            if obj.sType == 3
                set(handles.tableGroupNames,'Enable','Inactive')
            end
                
            % resets the current figure axes handle
            set(obj.hFig,'CurrentAxes',hAx);                                
            
            % disables the add button and added expt/expt info panels
            setObjEnable(handles.buttonAddSoln,'off')

            % sets the object positions
            tabPos = getTabPosVector(hPanelT,[5,-15,30,30]);
            pPos = [5,5,tabPos(3:4)-[15,40]];

            % creates a tab panel group
            obj.nExp = length(obj.sInfo);
            obj.hTabGrp = createTabPanelGroup(hPanelT,1);
            set(obj.hTabGrp,'position',tabPos,'tag','hTabGrp')

            % creates the tabs for each code difference type
            [obj.hTab,obj.hPanel] = deal(cell(obj.nTab,1));
            for i = 1:obj.nTab
                % creates the new tab panel
                obj.hTab{i} = createNewTabPanel(...
                               obj.hTabGrp,1,'title',tStr{i},'UserData',i);         
                set(obj.hTab{i},'ButtonDownFcn',{@obj.tabSelected})

                % creates the tree-explorer panel
                obj.hPanel{i} = uipanel('Title','','Units',...
                                        'Pixel','Position',pPos);
                set(obj.hPanel{i},'Parent',obj.hTab{i});
                resetObjPos(obj.hPanel{i},'Bottom',5)          
            end

            % pause to allow figure update
            obj.resetStorageArrays(1)
            pause(0.05);

            % retrieves the tab group java object handles
            obj.jTabGrp = getTabGroupJavaObj(obj.hTabGrp);

            % creates the experiment information table
            obj.createExptInfoTable()

            % adds to the added list 
            if ~isempty(obj.sInfo)
                % sets the added list strings    
                setObjEnable(handles.buttonClearAll,'on')
                setPanelProps(handles.panelExptInfo,'on')
                set(handles.textExptCount,'string',num2str(obj.nExp))    

                % updates the experiment information table
                obj.updateExptInfoTable()
            end

            % creates the explorer tree for each panel
            hasTree = true(obj.nTab,1);
            for i = obj.nTab:-1:1
                % creates a new explorer tree on the current tab
                obj.iTab = i;
                obj.createFileExplorerTree()

                % determines if a tree was created
                hasTree(i) = ~isempty(obj.jRoot{i});
                if ~hasTree(i)
                    % if not, then disable the tab
                    obj.jTabGrp.setEnabledAt(i-1,false)
                end
            end

            % sets the first valid tab
            obj.iTab = find(hasTree,1,'first');
            set(obj.hTabGrp,'SelectedTab',obj.hTab{obj.iTab});      
            
            % closes the loadbar
            try; close(h); end            
            
        end                         
        
        % ---------------------------------------------- %
        % --- EXPERIMENT INFORMATION TABLE FUNCTIONS --- %
        % ---------------------------------------------- %          
        
        % --- table cell update callback function
        function tableCellChange(obj, ~, evnt)

            % if the table is updating automatically, then exit
            if obj.tableUpdate
                return
            end
            
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
            nwStr = obj.jTable.getValueAt(iRow,iCol);            
            
            % determines if the new string is valid and feasible
            if (iRow+1) > size(tabData,1)
                % case is the experiment has not been loaded
                mStr = sprintf(['It isn''t possible to set the name ',...
                                'for an experiment that is not loaded.']);
                waitfor(msgbox(mStr,'Experiment Naming Error','modal'))

            elseif strcmp(nwStr,tabData{iRow+1,iCol+1})
                % case is the string name has not changed
                return

            elseif iCol == 0
                % case is the experiment name is being updated
                nwStr = obj.jTable.getValueAt(iRow,iCol);

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
                    obj.jTable.repaint();
                    pause(0.05);
                    obj.tableUpdate = false;
                    
                    % updates the experiment names on the other tabs
                    if obj.sType == 3
                        obj.baseObj.updateExptNames(iRow+1,1);
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
                    obj.jTable.setValueAt([],iRow,iCol);
                else
                    obj.jTable.setValueAt(tabData{iRow+1,iCol+1},iRow,iCol);
                end

                % waits for update
                pause(0.05)
            end
            
            % resets the table update flag
            obj.tableUpdate = false;            
            
        end
            
        % --- callback function for the apparatus inclusion checkboxs --- %
        function tableUpdateSel(obj, ~, ~)

            % text object handles strings
            handles = obj.hGUI;
            hButtonAdd = handles.buttonAddSoln;
            txtTag = {'textFileCount','textSelectedCount','textRootDir'};
            bgCol = {0.94*ones(1,3),[1,0,0]};
            
            % if there is no information then exit
            if isempty(obj.jMov{obj.iTab})
                nSel = 0;
            else
                % sets the new selected movie count
                isSel = cellfun(@(x)(strcmp(get(x,...
                        'SelectionState'),'selected')),obj.jMov{obj.iTab});    
                nSel = sum(isSel);            
            end

            % updates the batch process running menu item
            canAdd = nSel > 0;
            setObjEnable(hButtonAdd,canAdd)
            set(hButtonAdd,'BackGroundColor',bgCol{1+canAdd});
            

            % sets the new text label strings
            if isempty(obj.sDir{obj.iTab})
                % case is no file explorer has been created
                txtStr = repmat({'N/A'},1,length(txtTag));  
                txtStrTT = '';
            else
                % case is file explorer has been created 
                txtStr = {num2str(length(obj.sFile{obj.iTab})),...
                          num2str(nSel),obj.sDir{obj.iTab}};
                txtStrTT = obj.sDir{obj.iTab};
            end

            % updates the object strings/properties
            hTxt0 = findall(handles.panelSolnExplorer,'style','text');
            cellfun(@(x,y)(set(findall...
                            (hTxt0,'tag',x),'String',y)),txtTag,txtStr);
            arrayfun(@(x)(setObjEnable...
                            (x,~isempty(obj.sDir{obj.iTab}))),hTxt0)
            set(handles.textRootDir,'tooltipstring',txtStrTT)   
        
        end         
        
        % --- creates the experiment information table
        function createExptInfoTable(obj)
           
            % object handle retrieval
            handles = obj.hGUI;
            hTableI = handles.tableExptInfo;
            hPanelI = handles.panelExptInfo;

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
            tabData = cell(obj.nExpMax,length(hdrStr));
            
            % sets up the table dimension array
            dX = 6;
            dPos = [2*dX,30];            
            pPos = get(hPanelI,'Position');
            tPos = [dX*[1,1],pPos(3:4)-dPos];
            
            % creates the java table object
            jScroll = findjobj(hTableI);
            [jScroll, hContainer] = javacomponent(jScroll,[],hPanelI);
            set(hContainer,'Units','Pixels','Position',tPos)

            % creates the java table model
            obj.jTable = jScroll.getViewport.getView;
            jTableMod = javax.swing.table.DefaultTableModel(tabData,hdrStr);
            obj.jTable.setModel(jTableMod);

            % sets the table callback function
            cbFcn = {@obj.tableCellChange};
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
                cMdl = obj.jTable.getColumnModel.getColumn(cID-1);
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
            obj.jTable.getTableHeader().setBackground(gridCol);
            obj.jTable.setGridColor(gridCol);
            obj.jTable.setShowGrid(true);

            % disables the resizing
            jTableHdr = obj.jTable.getTableHeader(); 
            jTableHdr.setResizingAllowed(false); 
            jTableHdr.setReorderingAllowed(false);

            % repaints the table
            obj.jTable.repaint()
            obj.jTable.setAutoResizeMode(obj.jTable.AUTO_RESIZE_ALL_COLUMNS)
            obj.jTable.getColumnModel().getSelectionModel.setSelectionMode(2)          
            
        end        
        
        % --- updates the solution file/added experiments array
        function updateExptInfoTable(obj)

            % other initialisations            
            obj.tableUpdate = true;            
            jTableMod = obj.jTable.getModel;

            % removes the table selection
            obj.jTable.changeSelection(-1,-1,false,false);

            % adds data to the table
            for i = 1:obj.nExp
                % adds the data for the new table row and bg colour index
                tabData = obj.getExptTableRow(obj.sInfo{i});
                if i > obj.jTable.getRowCount
                    jTableMod.addRow(tabData)
                    for j = 1:obj.jTable.getColumnCount
                        % sets the background colours
                        obj.tabCR1.setCellBgColor(i-1,j-1,obj.gray);
                        obj.tabCR2.setCellBgColor(i-1,j-1,obj.gray);        

                        % sets the foreground colours
                        obj.tabCR1.setCellFgColor(i-1,j-1,obj.black);
                        obj.tabCR2.setCellFgColor(i-1,j-1,obj.black);            
                    end
                else
                    % updates the table values
                    for j = 1:obj.jTable.getColumnCount
                        nwStr = java.lang.String(tabData{j});
                        obj.jTable.setValueAt(nwStr,i-1,j-1)                         
                    end        
                end
            end

            % resets the column widths
            mStr = obj.resetExptTableBGColour(1);
            obj.resetColumnWidths()

            % repaints the table
            obj.jTable.repaint();

            % flag that the table update is complete
            pause(0.05)
            obj.tableUpdate = false;

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

            % object retrieval
            handles = obj.hGUI;
            hTable = handles.tableExptInfo;
            jTableMod = obj.jTable.getModel();

            % sets the table update flag to on
            obj.tableUpdate = true;

            % removes the table selection
            removeTableSelection(hTable)

            % removes/clears all the fields in the table
            for i = obj.jTable.getRowCount:-1:1
                if i > obj.nExpMax
                    jTableMod.removeRow(obj.jTable.getRowCount-1)
                else
                    obj.clearExptInfoTableRow(i)  
                end
            end

            % repaints the table
            obj.jTable.repaint;
            pause(0.05);

            % resets the table update flag
            obj.tableUpdate = false;

        end
        
        % --- clears the information on a table row
        function clearExptInfoTableRow(obj,iRow)

            % resets the cells in the table row
            for j = 1:obj.jTable.getColumnCount
                % removes the value in the cell
                obj.jTable.setValueAt([],iRow-1,j-1)

                % resets the cell background colour
                if j == 1
                    obj.tabCR1.setCellBgColor(iRow-1,j-1,obj.gray)
                else
                    obj.tabCR2.setCellBgColor(iRow-1,j-1,obj.gray)
                end
            end

        end
        
        % --- updates the experiment information fields
        function updateGroupTableProps(obj)

            % retrieves the solution file information struct 
            % (for the current expt)
            handles = obj.hGUI;
            sInfoNw = obj.sInfo{obj.iExp};

            % sets the experiment dependent fields
            setObjEnable(handles.buttonShowProtocol,sInfoNw.hasStim);    

            % resets the table background colours
            bgCol = obj.getTableBGColours(sInfoNw);
            set(handles.tableGroupNames,'BackgroundColor',bgCol)

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
            set(handles.tableGroupNames,'Data',Data,'ColumnName',cHdr,...
                              'ColumnEditable',cEdit,'ColumnWidth',cWid)
            setObjVisibility(handles.tableGroupNames,'on')
            autoResizeTableColumns(handles.tableGroupNames)

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
        
        % --- updates the table background row colour
        function setExptTableRowColour(obj,iRow,rwCol)

            % sets the experiment colour
            obj.tabCR1.setCellBgColor(iRow-1,0,rwCol);

            % sets the other column colours
            for iCol = 2:obj.jTable.getColumnCount
                obj.tabCR2.setCellBgColor(iRow-1,iCol-1,rwCol)
            end

        end        
        
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
        
        % --- resets the column widths
        function resetColumnWidths(obj)

            % other intialisations
            cWid = [176,50,55,60,60,60,78];
            if obj.jTable.getRowCount > obj.nExpMax
                % other intialisations
                cWid = (cWid - 20/length(cWid));
            end

            for cID = 1:obj.jTable.getColumnCount
                cMdl = obj.jTable.getColumnModel.getColumn(cID-1);
                cMdl.setMinWidth(cWid(cID))
            end

        end             
        
        % ------------------------------------ %
        % --- FILE EXPLORER TREE FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- creates the file explorer tree
        function createFileExplorerTree(obj)
           
            % imports the checkbox tree
            import com.mathworks.mwswing.checkboxtree.*

            % sets the default input arguments
            if ~exist('sDirNw','var')
                sDirNw = [];
            end

            % sets the root search directory (dependent on stored 
            % values and tab index)
            if isempty(sDirNw)
                if isempty(obj.sDir{obj.iTab})
                    switch obj.iTab
                        case 1
                            % case is video solution files
                            sDirNw = obj.iProg.DirSoln;

                        otherwise
                            % case is experiment solution files
                            sDirNw = obj.iProg.DirComb;
                    end
                else
                    % otherwise, use the stored directory path
                    sDirNw = obj.sDir{obj.iTab};
                end

%                 % prompts the user for the search directory
%                 titleStr = 'Select the root search directory';
%                 sDirNw = uigetdir(defDir,titleStr);
%                 if sDirNw == 0
%                     % if the user cancelled, then exit
%                     return
%                 end
            end

            % deletes any existing tree objects
            hPanelS = obj.hPanel{obj.iTab};
            jTreeOld = findall(hPanelS,'type','hgjavacomponent');
            if ~isempty(jTreeOld); delete(jTreeOld); end

            % creates the file tree structure in the panel
            [jRootNw,sFileNw,jMovNw] = obj.setFileDirTree(sDirNw);             
            if isempty(jRootNw)
                % if there was an error, then exit
                return   
            end

            % updates the object fields with the new objects/values
            obj.sDir{obj.iTab} = sDirNw;
            obj.sFile{obj.iTab} = sFileNw;
            obj.jMov{obj.iTab} = jMovNw;
            obj.jRoot{obj.iTab} = jRootNw;

            % updates the file selection information
            obj.tableUpdateSel([],[])            
            
        end        
        
        % --- sets up the file directory tree structure
        function [jRoot,mFile,hM] = setFileDirTree(obj,sDir)

            % imports the checkbox tree
            import com.mathworks.mwswing.checkboxtree.*

            % other initialisations
            dX = 10;
            fType = obj.fExtn{obj.iTab};
            hObj = obj.hPanel{obj.iTab};            

            % searches the batch processing movie directory for movies
            obj.sFileT = obj.findFileAll(sDir,fType);
            if isempty(obj.sFileT)
                % closes the loadbar and sets empty variables for outputs
                [jRoot,mFile,hM] = deal([]);                    
                return
                
            else
                sInfoT = obj.sInfo;
                if ~isempty(sInfoT)        
                    % if there is stored info, then reduce down the 
                    % information to the fields corresponding to the 
                    % selected file type tab
                    sInfoT = sInfoT(...
                                cellfun(@(x)(x.iTab==obj.iTab),sInfoT));
                end

                if ~isempty(sInfoT)
                    % removes the search files that are already loaded
                    switch obj.iTab
                        case 1                
                            % video solution files
                            sFileL = cell2cell(cellfun(@(x)...
                                (x.snTot.sName),sInfoT,'un',0));  
                            isKeep = ~any(cell2mat(cellfun(@(x)...
                                (strcmp(obj.sFileT,x)),sFileL,'un',0)'),2);                                                                

                        otherwise
                            % experiment solution files
                            exFile = cellfun(@(x)...
                                    (x.sFile),sInfoT,'un',0);
                            isKeep = ~any(cell2mat(cellfun(@(x)(strcmp...
                                    (obj.sFileT,x)),exFile(:)','un',0)),2);
                    end

                    % removes any of the files that are loaded
                    obj.sFileT = obj.sFileT(isKeep);
                end

                % removes any infeasible solution file directories 
                % (soln file only)
                if obj.iTab == 1    
                    obj.sFileT = obj.removeInfeasSolnDir(obj.sFileT);
                end

                % otherwise, determine the directory struct from the movies
                dirStr = obj.detDirStructure(sDir,obj.sFileT);
                obj.hMovT = cell(length(obj.sFileT),1);
            end    

            % creates the root checkbox node
            sDirT = getFinalDirString(sDir);

            % sets up the root node based on whether there are valid files
            if isempty(obj.sFileT)
                % case is there are no valid files
                jRoot = DefaultCheckBoxNode('No Valid Files Detected!');
            else
                % sets up the directory trees structure
                jRoot = DefaultCheckBoxNode(sDirT);
                jRoot = obj.setSubDirTree(jRoot,dirStr,sDirT);    
            end

            % retrieves the object position
            objP = get(hObj,'position');

            % creates the final tree explorer object
            obj.jTree = com.mathworks.mwswing.MJTree(jRoot);
            jTreeCB = handle(CheckBoxTree...
                            (obj.jTree.getModel),'CallbackProperties');
            jScrollPane = com.mathworks.mwswing.MJScrollPane(jTreeCB);

            % creates the scrollpane object
            wState = warning('off','all');
            tPos = [dX*[1 1],objP(3:4)-2*dX];
            [~,~] = javacomponent(jScrollPane,tPos,hObj);
            warning(wState);

            % sets the callback function for the mouse clicking of 
            % the tree structure
            set(jTreeCB,'MouseClickedCallback',{@obj.tableUpdateSel})

            % sets the output variables
            if nargout > 1
                [mFile,hM] = deal(obj.sFileT,obj.hMovT);
            end

        end
        
        % --- sub-directory tree setup for the directories in dirStr --- %
        function jTree = setSubDirTree(obj,jTree,dirStr,dirC)

            % imports the checkbox tree
            import com.mathworks.mwswing.checkboxtree.*

            % adds all the nodes for each of the sub-directories
            for i = 1:length(dirStr.Names)    
                jTreeNw = DefaultCheckBoxNode(dirStr.Names{i});
                nodeStr = fullfile(dirC,dirStr.Names{i});
                jTreeNw = obj.setSubDirTree(jTreeNw,dirStr.Dir(i),nodeStr);
                jTree.add(jTreeNw);                
            end

            % if there are any files detected, then add them to the list
            if ~isempty(dirStr.Files)
                for i = 1:length(dirStr.Files)
                    % determines the matching movie file name
                    fStr = fullfile(dirC,dirStr.Files{i});
                    ii = cellfun(@(x)(strContains(x,fStr)),obj.sFileT);      

                    % creates the new node
                    [jTreeNw,obj.hMovT{ii}] = ...
                                deal(DefaultCheckBoxNode(dirStr.Files{i}));
                    jTree.add(jTreeNw)                    
                end        
            end

        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %        
        
        % --- callback function for clicking buttonSetDir
        function buttonSetDirCB(obj, ~, ~)

            % determines if the explorer tree exists for the current tab
            if ~isempty(obj.jRoot{obj.iTab})
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

            % creates the explorer tree
            obj.isChange = true;
            obj.createFileExplorerTree();            
            
        end
        
        % --- callback function for clicking buttonAddSoln
        function buttonAddSolnCB(obj, ~, ~)
            
            % global variables
            global hh

            % object/array retrieval
            sInfo0 = obj.sInfo;
            handles = obj.hGUI;
            hPanelEx = handles.panelExptInfo;

            % other initialisations
            tDir = obj.iProg.TempFile;

            % sets the full names of the selected files
            isSel = cellfun(@(x)(strcmp(get...
                    (x,'SelectionState'),'selected')),obj.jMov{obj.iTab});
            sFileS = obj.sFile{obj.iTab}(isSel);

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
                            'Loading Data File',...
                            'Current File Progress'};
                    if obj.iTab == 3
                        [wStr{end+1},mName] = deal('Data Output',[]);
                    else
                        mName = cellfun(@(x)(getFileName(x)),sFileS,'un',0);
                    end
            end

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

                            % removes any y-axis data (1D analysis only)
                            if ~snTotNw.iMov.is2D
                                snTotNw.Py = [];
                            end                               
                            
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
                                    
                            % separates the multi-experiment group names
                            gName = separateMultiExptGroupNames(snTotNw(j)); 
                            snTotNw(j).iMov.pInfo.gName = gName;
                        end

                        % case is a group of multiexperiment solution files
                        obj.appendSolnInfo(snTotNw,fFileS,mNameNw);
                        mName = [mName;mNameNw(:)];
                end
            end

            % closes the progress bar
            hh.closeProgBar()
            hh = [];
            
            % sets the full tab group enabled properties (if it exists)
            obj.nExp = length(obj.sInfo);
            obj.resetFullTabProps();
            
            %
            if any(~isOK)
                % if there was an error loading a directory/file, then 
                % output these directories to screen
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

            % recreates the explorer tree
            obj.createFileExplorerTree()
            if isempty(mName); return; end

            % updates the solution file/added experiments array
            obj.updateExptInfoTable()                   

            % updates the added experiment objects
            setPanelProps(hPanelEx,'on');
            setObjEnable(handles.buttonClearAll,'on');
            set(handles.textExptCount,'string',num2str(obj.nExp),...
                                      'enable','on')

            % if loading files through the analysis gui, then update the
            % experiment information for the other tabs
            obj.baseObj.updateFullGUIExpt();
                                  
            % updates the change flag
            obj.isChange = true;          
            
        end
        
        % --- callback function for clicking buttonClearExpt
        function buttonClearExptCB(obj, hObject, ~)
          
            % object handles
            handles = obj.hGUI;
            hText = handles.textExptCount;
            hTable = handles.tableExptInfo;            

            % confirms the user wants to clear the selected table fields
            tStr = 'Confirm Data Clearing?';
            qStr = ['Are you sure you want to clear the ',...
                    'selected experiment data?'];
            uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % if the user cancelled, then exit the function
                return
            end

            % retrieves the currently selected table rows
            jTableMod = obj.jTable.getModel;

            % determines the selected rows
            iSel = double(obj.jTable.getSelectedRows)+1;
            iNw = ~setGroup(iSel(:),[length(obj.sInfo),1]);

            % if there are no experiments left, then clear everything
            if ~any(iNw)
                obj.buttonClearAllCB(handles.buttonClearAll,[]);
                return
            else
                % otherwise, recalculate the experiment count
                obj.nExp = sum(iNw);
            end            
            
            % disables the added experiment information fields
            setObjEnable(hObject,'off')
            setObjEnable(handles.buttonShowProtocol,0)
            setObjVisibility(handles.tableGroupNames,0)
            setObjEnable(handles.buttonClearAll,obj.nExp>0)
            set(setObjEnable(hText,1),'string',num2str(obj.nExp))

            % reduces down the solution file information
            obj.sInfo = obj.sInfo(iNw);
            obj.isChange = true;

            % removes the rows from the table
            obj.tableUpdate = true;

            % removes the table selection
            removeTableSelection(hTable)

            % shifts the rows (if there are any rows under those being cleared)
            if iSel(end)+1 <= length(iNw)
                indRow = obj.jTable.getRowCount-1;
                jTableMod.moveRow(iSel(end),indRow,iSel(1)-1)
            end

            % removes any excess rows
            for i = max(obj.nExp,obj.nExpMax+1):obj.jTable.getRowCount
                jTableMod.removeRow(obj.jTable.getRowCount-1)
            end
            
            % removes/clears the rows
            for i = (obj.nExp+1):obj.nExpMax
                obj.clearExptInfoTableRow(i) 
            end

            % resets the column widths
            obj.resetExptTableBGColour(0);
            obj.resetColumnWidths()

            % repaints the table
            obj.jTable.repaint()

            % resets the table update flag
            pause(0.05);
            obj.tableUpdate = false;

            % if loading files through the analysis gui, then update the
            % experiment information for the other tabs
            obj.baseObj.updateFullGUIExpt();
            
            % creates the explorer tree
            iTab0 = obj.iTab;
            for i = 1:length(obj.sDir)
                obj.iTab = i;
                if ~isempty(obj.sDir{obj.iTab})
                    obj.createFileExplorerTree();
                    pause(0.05);
                end 
            end
            
            % resets the tab index
            obj.iTab = iTab0;
        end
        
        % --- callback function for clicking buttonClearAll
        function buttonClearAllCB(obj, ~, eventdata)

            % object handles
            iTab0 = obj.iTab;
            handles = obj.hGUI;            

            % prompts the user if they want to clear all the loaded data
            if ~isempty(eventdata)
                tStr = 'Confirm Data Clearing?';
                qStr = ['Are you sure you want to clear all the ',...
                        'loaded solution data?'];                
                uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                if ~strcmp(uChoice,'Yes')
                    % if the user cancelled, then exit the function
                    return
                end
            end

            % resets the storage arrays
            obj.resetStorageArrays(0)
            obj.resetFullTabProps();

            % disables all the buttons
            setObjEnable(handles.buttonClearAll,0)
            setObjEnable(handles.buttonClearExpt,0)
            setObjEnable(handles.buttonShowProtocol,0)
            setObjVisibility(handles.tableGroupNames,0)
            set(handles.textExptCount,'string',0)

            % disables the added experiment information fields
            obj.resetExptInfoTable();

            % creates the explorer trees for each file type
            for i = 1:length(obj.sDir)
                if ~isempty(obj.sDir{i})
                    obj.iTab = i;
                    obj.createFileExplorerTree();
                end
            end

            % if loading files through the analysis gui, then update the
            % experiment information for the other tabs
            obj.baseObj.updateFullGUIExpt();
            
            % updates the tab index
            obj.iTab = iTab0;
            obj.isChange = true;
            
        end
        
        % --- callback function for clicking buttonShowProtocol
        function buttonShowProtocolCB(obj, ~, ~)
            
            % sets the panel object visibility properties
            handles = obj.hGUI;
            setObjVisibility(handles.panelSolnExplorer,0)
            setObjVisibility(handles.panelExptOuter,0)
            setObjVisibility(handles.panelStimOuter,1)

            % resets the stimuli axes
            obj.resetStimAxes()
            
        end
        
        % --- callback function for clicking buttonHideProtocol
        function buttonHideProtocolCB(obj, ~, ~)
            
            % sets the panel object visibility properties
            handles = obj.hGUI;
            setObjVisibility(handles.panelSolnExplorer,1)
            setObjVisibility(handles.panelExptOuter,1)
            setObjVisibility(handles.panelStimOuter,0)            
            
        end        
        
        % ----------------------------------------- %
        % --- CELL SELECTION CALLBACK FUNCTIONS --- %
        % ----------------------------------------- %           
        
        % --- callback function for cell selection in tableExptInfo
        function tableExptInfoCS(obj, ~, eventdata)
            
            % pauses for a small amount of time...
            pause(0.05);

            % object retrieval
            handles = obj.hGUI;

            % if there is no solution data loaded, then exit the function
            if isempty(obj.sInfo) || isempty(eventdata.Indices)
                return
            end

            % retrieves the other imporant fields
            obj.iExp = eventdata.Indices(1);

            % updates the group table
            setObjEnable(handles.buttonClearExpt,1)
            obj.updateGroupTableProps();            
            
        end        
        
        % ------------------------------------ %
        % --- CELL EDIT CALLBACK FUNCTIONS --- %
        % ------------------------------------ %   
               
        % --- callback function for cell editting in tableGroupName
        function tableGroupNamesCE(obj, hObject, eventdata)
            
            % initialisations
            mStr = [];
            indNw = eventdata.Indices;

            % removes the selection highlight
            jScroll = findjobj(hObject);
            jTableT = jScroll.getComponent(0).getComponent(0);
            jTableT.changeSelection(-1,-1,false,false);

            % determines if the current group/region is rejected
            isRejected = strcmp(eventdata.PreviousData,'* REJECTED *');
            if ~isRejected
                % if not, determines if the new name is valid
                nwName = eventdata.NewData;
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
                Data = get(hObject,'Data');
                Data{indNw(1),indNw(2)} = eventdata.PreviousData;
                set(hObject,'Data',Data);

                % exits the function
                return
            end

            % resets the table background colours
            bgCol = obj.getTableBGColours(obj.sInfo{obj.iExp});
            set(hObject,'BackgroundColor',bgCol)

            % updates the change flag
            obj.isChange = true;
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %           
        
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

                case 3
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
                s = seconds(sInfoNw{i}.tDur); 
                s.Format = 'dd:hh:mm:ss';
                sInfoNw{i}.tDurS = char(s);

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
        
        % --- resets the storage arrays within the GUI
        function resetStorageArrays(obj,isInit)
            
            % default input arguments
            if ~exist('isInit','var'); isInit = false; end

            % resets the solution information struct (reset only)            
            if ~isInit
                obj.nExp = 0;
                obj.sInfo = [];                 
            end            

            % initialises the other array objects 
            [obj.jMov,obj.jRoot,obj.jTree,obj.sFile] = ...
                                                deal(cell(obj.nTab,1));
        
        end        
        
        % --- sets up the directory tree structure from the movie files 
        function dirStr = detDirStructure(obj,sDir,movFile)

            % sets the directory name separation string
            if ispc; sStr = '\'; else sStr = '/'; end
            if ~strcmp(sDir(end),sStr); sDir = [sDir,sStr]; end

            % memory allocation
            [dirStr,a] = deal(struct('Files',[],'Dir',[],'Names',[]));

            % sets up the director tree structure for the selected movies
            for i = 1:length(movFile)
                % sets the new directory sub-strings
                bStr = 'dirStr';
                A = obj.splitStringRegExpLocal...
                                (movFile{i}((length(sDir)+1):end),sStr);                
                for j = 1:length(A)
                    % appends the data to the struct
                    if j == length(A)
                        % appends the movie name to the list
                        eval(sprintf...
                            ('%s.Files = [%s.Files;A(end)];',bStr,bStr));
                    else
                        % if the sub-field does not exists then create one
                        if ~any(strcmp(eval(sprintf('%s.Names',bStr)),A{j}))            
                            if isempty(eval(sprintf('%s.Dir',bStr)))
                                eval(sprintf('%s.Dir = a;',bStr));
                                eval(sprintf('%s.Names = A(j);',bStr));                    
                            else
                                eval(sprintf...
                                      ('%s.Dir = [%s.Dir;a];',bStr,bStr));
                                eval(sprintf...
                                      ('%s.Names = [%s.Names;A(j)];',...
                                      bStr,bStr));
                            end
                        end            

                        % appends the new field to the data struct
                        ii = find(strcmp(...
                                    eval(sprintf('%s.Names',bStr)),A{j}));
                        bStr = sprintf('%s.Dir(%i)',bStr,ii);
                    end
                end
            end        
        end        
        
        % --- finds all the finds 
        function fName = findFileAll(obj,snDir,fExtn)

            % initialisations
            [fFileAll,fName] = deal(dir(snDir),[]);

            % determines the files that have the extension, fExtn
            fFile = dir(fullfile(snDir,sprintf('*%s',fExtn)));
            if ~isempty(fFile)
                fNameT = cellfun(@(x)(x.name),num2cell(fFile),'un',0);
                fName = cellfun(@(x)(fullfile(snDir,x)),fNameT,'un',0);    
            end

            %
            isDir = find(cellfun(@(x)(x.isdir),num2cell(fFileAll)));
            for j = 1:length(isDir)
                % if the sub-directory is valid then search for any files        
                i = isDir(j);
                if ~(strcmp(fFileAll(i).name,'.') || ...
                                            strcmp(fFileAll(i).name,'..'))        
                    fDirNw = fullfile(snDir,fFileAll(i).name);        
                    fNameNw = obj.findFileAll(fDirNw,fExtn);
                    if ~isempty(fNameNw)
                        % if there are any matches, then add them to 
                        % the name array
                        fName = [fName;fNameNw];
                    end
                end
            end

        end           
        
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
                ii = cellfun(@length,iGrp0) == 1;
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
        
        % --- callback function for selecting the file type tab
        function tabSelected(obj, hObject, ~)
            
            % updates the selected tab
            obj.iTab = get(hObject,'UserData');

            % updates the table information
            obj.tableUpdateSel([],[])
            
        end           
        
        % --- resets the stimuli axes properties
        function resetStimAxes(obj)

            % object retrieval
            handles = obj.hGUI;
            hAx = handles.axesStim;

            %
            fAlpha = 0.2;
            tLim = [120,6,1e6];
            [axSz,lblSz] = deal(16,20);
            tStr0 = {'m','h','d'};
            tUnits0 = {'Mins','Hours','Days'};
            sTrainEx = obj.sInfo{obj.iExp}.snTot.sTrainEx;

            % sets the 
            [devType,~,iC] = unique(sTrainEx.sTrain(1).devType,'stable');
            nCh = NaN(length(devType),1);

            % sets up the 
            for iCh = 1:length(devType)
                % calculates the number of motor channels 
                if startsWith(devType{iCh},'Motor')
                    nCh(iCh) = sum(iC == iCh);
                end

                % strips of the number from the device string
                devType{iCh} = regexprep(devType{iCh},'[0-9]','');
            end

            chCol = flip(getChannelCol(devType,nCh));

            % determines the experiment units string
            Texp = obj.sInfo{obj.iExp}.snTot.T{end}(end);
            iLim = find(cellfun(@(x)...
                        (convertTime(Texp,'s',x)),tStr0) < tLim,1,'first');
            [tStr,tUnits] = deal(tStr0{iLim},tUnits0{iLim});
            tLim = [0,Texp]*getTimeMultiplier(tStr,'s');

            % clears the axes and turns it on
            cla(hAx)
            axis(hAx,'on');       
            hold(hAx,'on');
            axis('ij');

            % calculates the scaled 
            for i = 1:length(sTrainEx.sTrain)
                % sets up the signal
                sPara = sTrainEx.sParaEx(i);
                sTrain = sTrainEx.sTrain(i);
                xyData0 = setupFullExptSignal(obj,sTrain,sPara);

                % scales the x/y coordinates for the axes time scale
                tMlt = getTimeMultiplier(tStr,sPara.tDurU);
                tOfs = getTimeMultiplier(tStr,sPara.tOfsU)*sPara.tOfs;    
                xyData = cellfun(@(x)(colAdd...
                            (colMult(x,1,tMlt),1,tOfs)),xyData0,'un',0);        

                % plots the non-empty signals
                for iCh = 1:length(xyData)
                    % plots the channel region markers
                    if iCh < length(xyData)
                        plot(hAx,tLim,iCh*[1,1],'k--','linewidth',1)
                    end

                    % creates a new patch (if there is data)
                    if ~isempty(xyData{iCh})
                        [xx,yy] = deal(xyData{iCh}(:,1),xyData{iCh}(:,2));
                        yy = (1 - (yy - floor(min(yy)))) + (iCh-1);
                        patch(hAx,xx([1:end,1]),yy([1:end,1]),chCol{iCh},...
                                'EdgeColor',chCol{iCh},'FaceAlpha',...
                                fAlpha,'LineWidth',1);
                    end
                end   

                % sets the axis limits (first stimuli block only)
                if i == 1
                    % sets the axis properties
                    yTick = (1:length(xyData)) - 0.5;
                    yTickLbl = cellfun(@(x,y)(sprintf('%s (%s)',y,x(1))),...
                                      sTrain.devType,sTrain.chName,'un',0);
                    set(hAx,'xlim',tLim,'ylim',[0,length(xyData)],...
                            'ytick',yTick,'yticklabel',yTickLbl,...
                            'FontUnits','Pixels','FontSize',axSz,...
                            'FontWeight','bold','box','on')

                    % sets the axis/labels
                    xLbl = sprintf('Time (%s)',tUnits);
                    xlabel(hAx,xLbl,'FontWeight','bold','FontUnits',...
                                    'Pixels','FontSize',lblSz)
                end
            end

            % turns the axis hold off
            hold(hAx,'off');

        end
        
        % --- resets the full tab group object properties
        function resetFullTabProps(obj)
            
            % resets the full gui tab enabled properties (if they exist)
            if ~isempty(obj.jTabGrpF)
                pause(0.05);
                obj.jTabGrpF.setEnabledAt(1,obj.nExp>0);  
                
                if obj.jTabGrpF.getTabCount == 3
                    obj.jTabGrpF.setEnabledAt(2,obj.nExp>0);
                end
            end            

        end        
        
    end
    
    % static class methods
    methods (Static)
        
        % --- retrieves the experiment table row data
        function rowData = getExptTableRow(sInfoEx)

            % initialisations
            pFileStr = 'N/A';
            exStr = {'1D','2D'};
            typeStr = {'soln','ssol','msol'};

            % sets the solution file type strings/fields
            switch sInfoEx.iTab
                case 1
                    % case is data from a video file directory
                    pFileStr = getFinalDirString(sInfoEx.sFile,1);

                case 3
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

            % sets the 
            rowData = cell(1,6);
            rowData{1} = sInfoEx.expFile;
            rowData{2} = pFileStr;
            rowData{3} = typeStr{sInfoEx.iTab};
            rowData{4} = exStr{1+sInfoEx.is2D};
            rowData{5} = stimStr;
            rowData{6} = sInfoEx.tDurS;

        end     
        
        % removes any infeasible solution file directories
        function sFile = removeInfeasSolnDir(sFile)

            % determines the unique solution directory names
            fDir0 = cellfun(@(x)(fileparts(x)),sFile,'un',0);
            [fDir,~,iC] = unique(fDir0);

            % determines the number of Summary files in each directory
            nSumm = cellfun(@(x)(length...
                            (dir(fullfile(x,'Summary.mat')))),fDir);
            sFileD = arrayfun(@(x)(sFile(iC==x)),(1:max(iC))','un',0);

            % loops through all the feasible directories (folders with 
            % only 1 Summary file) determining if the multi-files expts 
            % are named correctly
            isOK = nSumm == 1;
            for i = find(nSumm(:)' == 1)
                if length(sFileD{i}) > 1
                    % retrieves the names of the files in the directory
                    fName = cellfun(@(x)(getFileName(x)),sFileD{i},'un',0);

                    % ensures that files have consistent naming conventions
                    smData = load(fullfile(fDir{i},'Summary.mat'));
                    bStr = smData.iExpt.Info.BaseName;
                    isOK(i) = all(cellfun(@(x)(startsWith(x,bStr)),fName));
                end
            end

            % removes the infeasible directories
            sFile = cell2cell(sFileD(isOK));

        end             
        
        % --- splits up a string, Str, by its white spaces and returns the
        %     constituent components in the cell array, sStr
        function sStr = splitStringRegExpLocal(Str,sStr)

            % ensures the string is not a cell array
            if iscell(Str)
                Str = Str{1};
            end

            % determines the indices of the non-white regions in the string
            if length(sStr) == 1
                if strcmp(sStr,'\') || strcmp(sStr,'/')  
                    ind = strfind(Str,sStr)';
                else
                    ind = regexp(Str,sprintf('[%s]',sStr))';
                end
            else
                ind = regexp(Str,sprintf('[%s]',sStr))';
            end

            % calculates the indices of the non-contigious non-white 
            % space indices and determines the index bands that the 
            % strings belong to
            indGrp = num2cell([[1;(ind+1)],[(ind-1);length(Str)]],2);

            % sets the sub-strings
            sStr = cellfun(@(x)(Str(x(1):x(2))),indGrp,'un',false);

        end
            
        % --- group the selected files by their unique directories
        function [fDirS,fNameS] = groupSelectedFiles(sFile)

            % retrieves the file directory/name strings
            fDir0 = cellfun(@(x)(fileparts(x)),sFile,'un',0);
            fName0 = cellfun(@(x)(getFileName(x,1)),sFile,'un',0);

            % groups the file names/directories into their unique groups
            [fDirS,~,iC] = unique(fDir0);
            fNameS = arrayfun(@(x)(fName0(iC==x)),1:max(iC),'un',0);

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
        
        % --- initialises the parameter struct
        function iPara = initParaStruct(snTot)

            % initialises the parameter struct
            nVid = length(snTot.T);
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

        end
        
        % --- initialises the solution file information --- %
        function expInfo = initExptInfo(sInfo)

            % retrieves the solution data struct
            snTot = sInfo.snTot;
            iMov = snTot.iMov;

            % sets the experimental case string
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

                case 3
                    % case is the multi-experiment files
                    sDirTT = fileparts(sInfo.sFile);
            end

            % calculates the experiment duration (rounded to nearest min)
            dT = roundP((snTot.T{end}(end)-snTot.T{1}(1))/60,1)*60;
            [~,~,Tstr] = calcTimeDifference(dT);

            % calculates the experiment count/duration strings
            nExpt = num2str(length(snTot.T));
            TstrTot = sprintf('%s Days, %s Hours, %s Mins',...
                                                Tstr{1},Tstr{2},Tstr{3});
            T0vec = calcTimeString(snTot.iExpt.Timing.T0,0);
            Tfvec = calcTimeString(snTot.iExpt.Timing.T0,snTot.T{end}(end));
            txtStart = datestr(sInfo.iPara.Ts0,'mmm dd, YYYY HH:MM AM');
            txtFinish = datestr(sInfo.iPara.Tf0,'mmm dd, YYYY HH:MM AM');

            % sets the expt setup dependent fields
            if iMov.is2D
                % case is a 2D experiment
                if isempty(iMov.autoP)
                    setupType = 'No Shape';
                else
                    switch iMov.autoP.Type
                        case 'Circle'
                            setupType = 'Circle';
                        case 'GeneralR'
                            setupType = 'General Repeating';            
                        case 'GeneralC'
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

            % sets the experiment information fields
            expInfo = struct('ExptType',eCase,'ExptDur',TstrTot,...
                             'SolnDur',TstrTot,'SolnCount',nExpt,...
                             'RegionConfig',regConfig,'dT',dT,...
                             'StartTime',txtStart,'FinishTime',txtFinish,...
                             'SolnDir',sName,'SolnDirTT',sDirTT,...
                             'T0vec',T0vec,'Tfvec',Tfvec,...
                             'SetupType',exptStr);          

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
            [T0,T1] = deal(snTot.T{1}(1),snTot.T{end}(end));
            
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
                        ii = (Ts >= T0) & (Tf <= T1);
                        chStim.iStim = chStim.iStim(ii);
                        [chStim.Ts,chStim.Tf] = deal(Ts(ii)-T0,Tf(ii)-T0);                         
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
            obj.baseObj.(propname) = varargin{:};
        end
        
        % --- gets a class object field
        function varargout = GetDispatch(obj, propname)
            varargout{:} = obj.baseObj.(propname);
        end
        
    end    
end
