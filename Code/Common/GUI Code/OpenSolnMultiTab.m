classdef OpenSolnMultiTab < dynamicprops & handle

    % class properties
    properties
        
        % object handles
        hList
        hTabGrpL
        hTabGrpI
        jTabGrpI
        
        % comparison table class fields
        tabCR1
        tabCR2
        jTable    
        tCol        
        
        % scalar class properties      
        iExp = 1;  
        nRow
        exptCol
        nHdr
        nExpMax = 7;
        nExpMin = 7;
        tableUpdate = false;
        isSaving
        
    end
    
    % private class properties    
    properties (Access = private)
        
    	baseObj
        
    end        
    
    % class methods
    methods
        
        % class constructor
        function obj = OpenSolnMultiTab(baseObj,isSaving)
            
            % field initialisations
            obj.baseObj = baseObj;
            obj.isSaving = isSaving;
                        
            % initialises the object callback functions
            obj.linkParentProps();
            obj.initClassFields();
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
        
        % --- initialises the class object fields
        function initClassFields(obj)
            
            % field initialisations
            obj.nExp = length(obj.sInfo);
            obj.cObj = ExptCompObj(obj.sInfo);
            obj.exptCol = 1;           
            
            % reshapes the solution file information
            for i = 1:length(obj.sInfo)
                obj.sInfo{i}.snTot = reshapeSolnStruct...
                                (obj.sInfo{i}.snTot,obj.sInfo{i}.iPara);
            end                
            
            % retrieves the row count
            if obj.sType == 3
                obj.nRow = 6;
            else
                obj.nRow = getappdata(obj.hFig,'nRow');        
            end
            
        end
        
        % initialises all the object callback functions
        function initObjCallbacks(obj)
            
            % objects with normal callback functions
            cbObj = {'buttonMoveUp','buttonMoveDown','editMaxDiff'};
            for i = 1:length(cbObj)
                hObj = getStructField(obj.hGUI,cbObj{i});
                cbFcn = eval(sprintf('@obj.%sCB',cbObj{i}));
                set(hObj,'Callback',cbFcn)
            end                        
            
            % objects with cell selection callback functions
            csObj = {'tableFinalNames','tableExptComp'};
            for i = 1:length(csObj)
                hObj = getStructField(obj.hGUI,csObj{i});
                cbFcn = eval(sprintf('@obj.%sCS',csObj{i}));
                set(hObj,'CellSelectionCallback',cbFcn)
            end 
            
            % objects with cell edit callback functions
            ceObj = {'tableFinalNames','tableLinkName','tableExptComp'};
            for i = 1:length(ceObj)
                hObj = getStructField(obj.hGUI,ceObj{i});
                cbFcn = eval(sprintf('@obj.%sCE',ceObj{i}));
                set(hObj,'CellEditCallback',cbFcn)
            end                      
            
        end
        
        % --- initialises the tab panel object properties
        function initObjProps(obj)
            
            % object retrieval
            handles = obj.hGUI;            
            hPanelInfoN = handles.panelGroupNames;
            hPanelInfoEx = handles.panelExptComp;
            
            % ------------------------------ %
            % --- GROUP NAME TABLE SETUP --- %
            % ------------------------------ %            
            
            % special setup for saving only
            if obj.isSaving
                % object retrieval
                hPanelInfo = handles.panelInfoTotal;

                % sets the object positions
                tabPosI = getTabPosVector(hPanelInfo,[5,5,-10,-5]);
                obj.hTabGrpI = createTabPanelGroup(hPanelInfo,1);
                set(obj.hTabGrpI,'position',tabPosI,'tag','hTabGrpL');

                % tab group information fields
                hP = {hPanelInfoEx,hPanelInfoN};
                tabStr = {'Experiment Comparison','Group Naming'};

                % creates all the information tabs 
                for i = 1:length(hP)
                    hTabNw = createNewTabPanel...
                           (obj.hTabGrpI,1,'title',tabStr{i},'UserData',i);
                    set(hTabNw,'ButtonDownFcn',{@obj.tabSelectedInfo})    
                    set(hP{i},'Parent',hTabNw)    
                end

                % creates the tab group java object and disables the panel
                obj.jTabGrpI = getTabGroupJavaObj(obj.hTabGrpI);
                obj.jTabGrpI.setEnabledAt(1,0);    
            end
            
            % ------------------------------ %
            % --- GROUP NAME TABLE SETUP --- %
            % ------------------------------ %

            % object retrieval
            hTableF = handles.tableFinalNames;
            hTableL = handles.tableLinkName;
            
            % sets the empty table data fields
            cHdr1 = {'Group Name'};
            cHdr2 = {'Original Name','Final Name'};
            set(hTableF,'Data',cell(obj.nRow,1),'ColumnName',cHdr1);
            set(hTableL,'Data',cell(obj.nRow,2),'ColumnName',cHdr2);

            % auto-resizes the table columns
            autoResizeTableColumns(hTableF)
            autoResizeTableColumns(hTableL)

            % sets the original group names
            if ~isempty(obj.sInfo)
                [obj.gName,obj.gName0] = ...
                            deal(cellfun(@(x)(x.gName),obj.sInfo,'un',0)); 
            end
                        
            % --------------------------------------------- %
            % --- EXPERIMENT GROUPING INFORMATION SETUP --- %
            % --------------------------------------------- %
            
            % object retrieval
            hPanelGrpL = handles.panelGroupLists;
            hPanelGrpC = handles.panelGroupingCrit;

            % creates the experiment information table
            obj.createExptInfoTable()
            
            % determines the compatible experiment info
            if ~isempty(obj.sInfo)
                indG = obj.cObj.detCompatibleExpts();
                obj.resetFinalGroupNameArrays(indG)
            end

            % sets the object positions            
            tabPosL = getTabPosVector(hPanelGrpL,[5,5,-10,-5]);
            obj.hTabGrpL = createTabPanelGroup(hPanelGrpL,1);
            set(obj.hTabGrpL,'position',tabPosL,'tag','hTabGrpL');
                
            % updates the grouping lists
            if ~isempty(obj.sInfo)
                obj.updateGroupLists(indG)
            end

            % sets the criteria checkbox callback functions
            hChkL = findall(hPanelGrpC,'style','checkbox');
            arrayfun(@(x)(set(hChkL,'Callback',{@obj.checkUpdate})),hChkL)

            % sets the other parameters
            durStr = num2str(obj.cObj.getParaValue('pDur'));
            set(handles.editMaxDiff,'string',durStr);  
            
            % ------------------------------------- %            
            % --- CONTROL BUTTON INITIALISATION --- %
            % ------------------------------------- %
            
            % initialisations
            cdFile = 'ButtonCData.mat';
            
            % object retrieval
            handles = obj.hGUI;
            hButtonUp = handles.buttonMoveUp;
            hButtonDown = handles.buttonMoveDown;              

            % sets the button c-data values            
            if exist(cdFile,'file')
                [A,nDS] = deal(load(cdFile),3); 
                [Iup,Idown] = deal(A.cDataStr.Iup,A.cDataStr.Idown);
                set(hButtonUp,'Cdata',uint8(dsimage(Iup,nDS)));    
                set(hButtonDown,'Cdata',uint8(dsimage(Idown,nDS)));
            end

            % creates the experiment table
            setObjEnable(hButtonUp,'off');
            setObjEnable(hButtonDown,'off');            
            
        end         
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- callback function for clicking buttonMoveUp
        function buttonMoveUpCB(obj, hObject, ~)
           
            % object retrieval
            handles = obj.hGUI;
            hTable = handles.tableFinalNames;

            % determines the currently selected name row and group index
            [iRow,~] = getTableCellSelection(hTable);
            iTabG = obj.getTabGroupIndex(obj.hTabGrpL);

            % permutes the group name array and updates within the gui
            indP = [(1:iRow-2),iRow+[0,-1],...
                                (iRow+1):length(obj.gNameU{iTabG})];
            obj.gNameU{iTabG} = obj.gNameU{iTabG}(indP);

            % updates the table and the 
            DataNw = obj.expandCellArray(obj.gNameU{iTabG},obj.nRow);
            set(hTable,'Data',DataNw);
            setObjEnable(hObject,iRow>2);
            setTableSelection(hTable,iRow-2,0)
            pause(0.05);

            % updates the change flag
            obj.isChange = true;             
            
            % resets the group lists
            obj.updateGroupLists()            
            
        end
            
        % --- callback function for clicking buttonMoveDown
        function buttonMoveDownCB(obj, hObject, ~)
            
            % object retrieval
            handles = obj.hGUI;
            hTable = handles.tableFinalNames;

            % determines the currently selected name row and group index
            [iRow,~] = getTableCellSelection(hTable);
            iTabG = obj.getTabGroupIndex(obj.hTabGrpL);

            % permutes the group name array and updates within the gui
            indP = [(1:iRow-1),iRow+[1,0],...
                                    (iRow+2):length(obj.gNameU{iTabG})];
            obj.gNameU{iTabG} = obj.gNameU{iTabG}(indP);
            DataNw = obj.expandCellArray(obj.gNameU{iTabG},obj.nRow);
            
            % updates the table and the 
            set(hTable,'Data',DataNw);
            setObjEnable(hObject,(iRow+1)<length(obj.gNameU{iTabG}));
            setTableSelection(hTable,iRow,0)
            pause(0.05);

            % updates the change flag
            obj.isChange = true;            
            
            % resets the group lists
            obj.updateGroupLists()            
            
        end
            
        % --- callback function for editting editMaxDiff
        function editMaxDiffCB(obj, hObject, ~)
            
            % object retrieval
            nwVal = str2double(get(hObject,'String'));

            % determines if the new value is valid
            if chkEditValue(nwVal,[1,100],0)
                % if so, update the parameter struct
                obj.cObj.setParaValue('pDur',nwVal);
                obj.cObj.calcCompatibilityFlags(5);

                % resets the final group name arrays
                obj.resetFinalGroupNameArrays()    

                % updates the group lists
                obj.updateGroupLists()
            else
                % otherwise, revert back to the last valid value
                prStr = num2str(obj.cObj.getParaValue('pDur'));
                set(hObject,'String',prStr);
            end            
            
        end

        % ----------------------------------------- %
        % --- CELL SELECTION CALLBACK FUNCTIONS --- %
        % ----------------------------------------- %

        % --- callback function for cell selection in tableFinalNames
        function tableFinalNamesCS(obj, ~, eventdata)
            
            % if there are no indices provided, then exit
            if isempty(eventdata.Indices); return; end

            % object retrieval
            handles = obj.hGUI;

            % determines the number of group names
            iRow = eventdata.Indices(1);
            iTabG = obj.getTabGroupIndex(obj.hTabGrpL);
            nName = length(obj.gNameU{iTabG});

            % updates the move up/down button enabled properties
            isOn = [iRow>1,iRow<nName] & (iRow <= nName);
            setObjEnable(handles.buttonMoveUp,isOn(1))
            setObjEnable(handles.buttonMoveDown,isOn(2))            
            
        end
        
        % --- callback function for cell selection in tableExptComp
        function tableExptCompCS(obj, hObject, eventdata)
        
            % retrieves the new experiment index
            iExpNw = eventdata.Indices(1);
            
            % retrieves the indices of the experiments
            indG = obj.cObj.detCompatibleExpts();
            iTabG = find(cellfun(@(x)(any(x==iExpNw)),indG));
            
            % if the incorrect tab is showing, then reset the group tab
            hTabG = get(obj.hTabGrpL,'SelectedTab');
            if get(hTabG,'UserData') ~= iTabG
                hTabG = findall(obj.hTabGrpL,'UserData',iTabG);
                set(obj.hTabGrpL,'SelectedTab',hTabG);
            end
            
            % updates the experiment list selection
            set(obj.hList,'Value',find(indG{iTabG} == iExpNw));
            
            
            obj.tabSelectedGrp(hTabG, [], indG)
            
        end
        
        % ------------------------------------ %
        % --- CELL EDIT CALLBACK FUNCTIONS --- %
        % ------------------------------------ %   
        
        % --- callback function for cell editting in tableFinalNames
        function tableFinalNamesCE(obj, hObject, eventdata)
           
            % initislisations
            ok = true;
            [tabData,tabData0] = deal(get(hObject,'Data'));            

            % retrieves the new input parameters
            iRow = eventdata.Indices(1);
            prStr = eventdata.PreviousData;
            nwStr = strtrim(eventdata.NewData);

            % determines the currently selected experiment
            indG = obj.cObj.detCompatibleExpts();
            iTabG = obj.getTabGroupIndex(obj.hTabGrpL);

            % determines the index of the first empty group name cell
            if isempty(prStr)
                tabData0{iRow} = ' ';
            else
                tabData0{iRow} = prStr;
            end

            %
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
                    obj.baseObj.updateGroupNames(2);
                end
                
            else
                % outputs the error message to screen (if there is error)
                if exist('mStr','var')
                    waitfor(msgbox(mStr,'Group Name Error','modal'))
                end

                % resets the table cell and exits the function
                tabData{iRow} = ' ';
                set(hObject,'Data',tabData);
                return
            end            
            
        end
        
        % --- callback function for cell editting in tableLinkName
        function tableLinkNameCE(obj, hObject, eventdata)
            
            % other initialisations
            handles = obj.hGUI;
            regStr = '* REJECTED *';            
            iRow = eventdata.Indices(1);
            tabData = get(hObject,'Data');

            % determines if the new selection is feasible
            if iRow > length(obj.gName{obj.iExp}) || ...
                                        strcmp(tabData{iRow,1},regStr)
                % if row selection is greater than group count, then reset
                tabData{iRow,2} = ' ';
                set(hObject,'Data',tabData); 
                
            else
                % otherwise, update the group name for the experiment
                obj.gName{obj.iExp}{iRow} = eventdata.NewData;

                % updates the flags/arrays    
                obj.isChange = true;                
                
                % removes the table selection
                removeTableSelection(hObject);

                % updates the background colours of the altered cell                
                tabDataN = get(handles.tableFinalNames,'Data');
                cFormN = [{' '};tabDataN(~strcmp(tabDataN,' '))];
                bgColL = cellfun(@(x)...
                        (obj.tCol{strcmp(cFormN,x)}),tabData(:,2),'un',0);
                set(hObject,'BackgroundColor',cell2mat(bgColL))  
                
                % updates the group names on the other tabs
                if obj.sType == 3
                    obj.baseObj.updateGroupNames(2);
                end                
            end            
            
        end        
        
        % --- callback function for cell editting in tableLinkName
        function tableExptCompCE(obj, hObject, eventdata)
            
            a = 1;
            
        end
        
        % ----------------------------------------- %
        % --- EXPERIMENTAL INFO TABLE FUNCTIONS --- %
        % ----------------------------------------- %
        
        % --- callback function for updating a table cell entry
        function tableCellChange(obj, ~, evnt)

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
            nwStr = obj.jTable.getValueAt(iRow,iCol);
            if strcmp(nwStr,tabData{iRow+1,iCol+1})
                return
            end

            % determines if the experiment name has been updated
            if iCol == 0
                % case is the experiment name is being updated
                nwStr = obj.jTable.getValueAt(iRow,iCol);
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
                        obj.baseObj.updateExptNames(iRow+1,2);
                    end                    

                    % exits the function        
                    return
                end
            end

            % if not, then resets the table cell back to the original value    
            obj.tableUpdate = true;
            obj.jTable.setValueAt(tabData{iRow+1,iCol+1},iRow,iCol);
            
            % updates the table
            pause(0.05);
            obj.tableUpdate = false;            
            
        end
        
        % --- resets the chooser file
        function resetChooserFile(obj,iTabG)
            
            resetFcn = getappdata(obj.hFig,'resetFcn');
            resetFcn(obj.hFig,iTabG);
            
        end
        
        % --- updates the group list tabs
        function updateGroupLists(obj,indG)
            
            % if there is no loaded data, then exit the function
            if isempty(obj.sInfo); return; end

            % object retrieval
            hTab0 = get(obj.hTabGrpL,'Children');

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
                                (obj.hTabGrpL,1,'title',tStr,'UserData',i);
                set(hTabNw,'ButtonDownFcn',{@obj.tabSelectedGrp})
            end

            % retrieves the group list
            if isempty(obj.hList)
                % sets up the listbox positional vector
                tabPos = get(obj.hTabGrpL,'Position');    
                lPos = [5,5,tabPos(3)-15,tabPos(4)-35];

                % creates the listbox object
                hTabNw = findall(obj.hTabGrpL,'UserData',1);
                obj.hList = uicontrol('Style','Listbox','Position',lPos,...
                                  'tag','hGrpList','Max',2,'Value',[],...
                                  'Callback',{@obj.listSelect});
                set(obj.hList,'Parent',hTabNw)
            end

            % removes any extra tab panels
            for i = (nGrp+1):nTab
                % determines the tab to be removed
                hTabRmv = findall(hTab0,'UserData',i);
                if isequal(hTabRmv,get(obj.hTabGrpL,'SelectedTab'))
                    % if the current tab is also selected, then change the 
                    % tab to the very first tab
                    hTabNw = findall(hTab0,'UserData',1);
                    set(obj.hTabGrpL,'SelectedTab',hTabNw)
                    set(obj.hList,'Parent',hTabNw);
                end

                % deletes the tab
                delete(hTabRmv);
            end

            % updates the tab information
            hTabS = get(obj.hTabGrpL,'SelectedTab');
            obj.tabSelectedGrp(hTabS,[],indG);

        end
        
        % --- callback function for selecting the experiment group tabs
        function tabSelectedGrp(obj, hObject, ~, indG)
           
            % determines the compatible experiment info
            if ~exist('indG','var')
                indG = obj.cObj.detCompatibleExpts(); 
            end            
            
            % initialisations
            iTabG = get(hObject,'UserData');
            iSel = get(obj.hList,'Value');
            lStr = cellfun(@(x)(x.expFile),obj.sInfo(indG{iTabG}),'un',0);

            % updates the list strings
            set(obj.hList,'Parent',hObject,'String',lStr(:));            
            
            % resets the chooser file
            if obj.isSaving
                obj.resetChooserFile(iTabG);
            end

            % resets the panel information
            obj.resetExptInfo(indG{iTabG}(1))
            if isempty(iSel); iSel = -1; end

            % if the selection index is invalid, remove the selection
            if (iSel > length(lStr))      
                % removes the listbox selection
                set(obj.hList,'Max',2,'Value',[]); 

                % ensures the experiment comparison tab is selected
                if obj.isSaving
                    set(obj.hList,'Max',2,'Value',[]); 
                    hTabI = get(obj.hTabGrpI,'SelectedTab');
                    if get(hTabI,'UserData') > 1
                        hTabNw = findall(obj.hTabGrpI,'UserData',1);
                        set(obj.hTabGrpI,'SelectedTab',hTabNw)
                    end    

                    % disables the group name 
                    obj.jTabGrpI.setEnabledAt(1,0);
                else
                    set(obj.hList,'Value',1); 
                    obj.listSelect(obj.hList, [])
                end
            else
                % otherwise, update the table group names
                obj.updateTableGroupNames()    
            end        
            
        end
        
        % --- resets the panel information for the experiment index, iExpt
        function resetExptInfo(obj,iExp)

            % global variables
            global tableUpdate

            % other initialisations
            isS = obj.cObj.iSel;
            eStr = {'No','Yes'};
            nExpI = obj.cObj.getParaValue('nExp');
            [~,isComp] = obj.cObj.detCompatibleExpts();

            % sets the table cell colours
            cCol = {obj.redFaded,obj.blueFaded,obj.greenFaded};

            % updates the text object colours
            tableUpdate = true;
            for i = 1:nExpI
                % updates the stimuli protocol comparison strings
                isC = isComp{iExp}(i);
                nwStr = java.lang.String(obj.cObj.expData{i,6,iExp});
                obj.jTable.setValueAt(nwStr,i-1,5)
                obj.jTable.setValueAt(eStr{1+isC},i-1,6)

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
            obj.jTable.repaint();

            % resets the table update flag
            pause(0.05)
            obj.tableUpdate = false;

        end
        
        % --- list selection callback function
        function listSelect(obj, hObject, ~)

            % if the group name tab is not selected, then reselect it
            hTabI = get(obj.hTabGrpI,'SelectedTab');
            if get(hTabI,'UserData') ~= 2
                obj.jTabGrpI.setEnabledAt(1,1);
                hTabNw = findall(obj.hTabGrpI,'UserData',2);
                set(obj.hTabGrpI,'SelectedTab',hTabNw)
            end

            % resets the selection mode to single selection
            set(hObject,'max',1)

            % updates the table group names
            obj.updateTableGroupNames()            
            
        end
        
        % --- updates the final/linking table group names
        function updateTableGroupNames(obj,iExp)

            % parameters
            rejStr = '* REJECTED *';

            % other objects
            handles = obj.hGUI;
            hTableN = handles.tableFinalNames;
            hTableL = handles.tableLinkName;               

            % determines the currently selected experiment
            iTabG = obj.getTabGroupIndex(obj.hTabGrpL);
            iSelG = get(obj.hList,'Value');
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
            iSel0 = getTableCellSelection(hTableN);
            set(hTableN,'Data',DataN,'BackgroundColor',cell2mat(bgColN));

            % resets the selection (if there was one)
            if ~isempty(iSel0)
                setTableSelection(hTableN,iSel0-1,0); 
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
            set(hTableL,'Data',DataL,'ColumnFormat',{'char',cFormN},...
                        'BackgroundColor',cell2mat(bgColL(:)));

        end
        
        % --- retrieves the current experiment index
        function iExp = getCurrentExpt(obj)
            
            % retrieves the current experiment index
            indG = obj.cObj.detCompatibleExpts();
            hTab = get(obj.hTabGrpL,'SelectedTab');
            iExp = indG{get(hTab,'UserData')}(1);
            
        end
        
        % --- creates the experiment information table
        function createExptInfoTable(obj)

            % java imports
            import javax.swing.JTable
            import javax.swing.JScrollPane

            % object handle retrieval
            handles = obj.hGUI;
            hTableEx = handles.tableExptComp;
            hPanelEx = handles.panelExptComp;  
            
            % sets the table header strings
            cWid = [176,50,55,60,60,60,78];            
            hdrStr = {createTableHdrString({'Experiment Name'}),...
                      createTableHdrString({'Setup','Config'}),...
                      createTableHdrString({'Region','Shape'}),...
                      createTableHdrString({'Stimuli','Devices'}),...
                      createTableHdrString({'Exact','Protocol?'}),...
                      createTableHdrString({'Duration'}),...
                      createTableHdrString({'Compatible?'})};

            switch obj.sType
                case 3
                    cWid(1) = cWid(1) + 200;
            end   
            
            % other intialisations  
            obj.nHdr = length(hdrStr);
            if obj.nExp > obj.nExpMax
                cWid = (cWid - 20/length(cWid));
            end              
                  
            % sets up the table data array
            tabData = obj.getTableData();

            % creates the java table object
            jScroll = findjobj(hTableEx);
            [jScroll, hContainer] = ...
                            createJavaComponent(jScroll,[],hPanelEx);
            
            if obj.isSaving
                set(hContainer,'Units','Normalized','Position',[0,0,1,1])
            else
                dX = 7;
                pPos = get(hPanelEx,'Position');
                tPos = [7,7,pPos(3)-(2*dX+1),pPos(4)-30];
                set(hContainer,'Units','Pixels','Position',tPos)
            end
                
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
%                     % sets the background colours
%                     obj.tabCR1.setCellBgColor(i-1,j-1,obj.gray);
%                     obj.tabCR2.setCellBgColor(i-1,j-1,obj.gray);        

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

        end
        
        % --- updates the experiment information table (this occurs when 
        %     the user load/removes data)
        function updateExptInfoTable(obj)
            
            % retrieves the current/new row table counts
            nRowNw = max(1,obj.nExp);
            nRow0 = obj.jTable.getRowCount;
            
            % other initialisations    
            obj.iExp = 1;
            obj.tableUpdate = true;            
            jTableMod = obj.jTable.getModel;            
            emptyRow = cell(1,obj.jTable.getColumnCount);                          
            
            % determines if the expt info table needs to be modified
            if nRowNw > nRow0
                % case is new rows need to be added 
                for i = (nRow0+1):nRowNw
                    jTableMod.addRow(emptyRow);
                    for j = 1:obj.jTable.getColumnCount
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
                for i = 1:obj.jTable.getRowCount
                    for j = 1:obj.jTable.getColumnCount
%                         nwStr = java.lang.String(tabData{i,j});
                        obj.jTable.setValueAt(tabData{i,j},i-1,j-1)  
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
                if isempty(get(obj.hList,'Value'))
                    set(obj.hList,'Value',1,'max',1)
                end
            end                                           
            
            % resets the update flag
            obj.tableUpdate = false;
            
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
        
        % --- callback function for updating a criteria checkbox value
        function checkUpdate(obj, hObject, ~)
            
            % object retrieval
            pStr = get(hObject,'UserData');
            pValue = get(hObject,'Value');
            obj.cObj.setCritCheck(pStr,pValue)

            % resets the final group name arrays
            obj.resetFinalGroupNameArrays();

            % object retrieval
            obj.updateGroupLists();            
            
        end
        
        % --- callback function for selecting the experiment info tabs
        function tabSelectedInfo(obj, hObject, eventdata)
            
            % FINISH ME?!
            a = 1;
            
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
        
    end
    
    % static class methods
    methods (Static)
        
        % --- retrieves the index of the currently selected tab
        function iTabG = getTabGroupIndex(hTabGrpL)

            iTabG = get(get(hTabGrpL,'SelectedTab'),'UserData');

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
        
        % --- removes any of the infeasible names from the name list
        function gName = rmvInfeasName(gName)

            % determines the flags of the group names that are infeasible
            rStr = '* REJECTED *';
            isRmv = strcmp(gName,' ') | ...
                    strcmp(gName,rStr) | ...                    
                    cellfun(@isempty,gName);

            % removes any infeasible names
            gName = gName(~isRmv);    
            
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
            obj.baseObj.(propname) = varargin{:};        
        end
        
        % --- gets a class object field
        function varargout = GetDispatch(obj, propname)       
            varargout{:} = obj.baseObj.(propname);        
        end
        
    end      
end
