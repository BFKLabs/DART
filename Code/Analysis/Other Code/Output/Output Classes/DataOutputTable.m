classdef DataOutputTable < dynamicprops & handle
    
    % class properties
    properties
        
        % main class fields
        hFigH
        
        % main GUI object handle fields
        hPanelD
        hPanelM
        hPanelO
        hTabGrpD
        hTabGrpM
        
        % tab/table handle fields
        hTab
        hTable                
        
        % fixed tab header strings
        hStrD = {'Sheet 1','+'};
        tStrD = 'sheetTabGrp';
        
        % array fields
        Name
        Data
        iPara
        altChk
        alignV
        vPpr
        
        % other scalar fields
        mInd
        stInd
        iSel = 1;
        mSel = 1;
        tCount = 0;
        cCol = 125/255;
        isUpdating = false;
        allowSelect = false;
        
        % function handle
        pSelFcn
        bUpdateFcn
        mChngFcn
        
    end
    
    % private class properties
    properties (Access = private)
        
        baseObj
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = DataOutputTable(baseObj)
            
            % base object
            obj.baseObj = baseObj;
            
            % initialises the class fields
            obj.linkParentProps();
            obj.initClassFields();
            obj.initObjProps();
            
        end
        
        % --- initialises the class object fields with that parent object
        function linkParentProps(obj)
            
            % parent fields strings
            fldStr = {'hFig','Type','nChk','nMet','nMetG','nApp',...
                'nPara','nTab','nExp','cTab','appOut','expOut'};
            
            % connects the base/child objects
            for propname = fldStr
                metaprop = addprop(obj, propname{1});
                metaprop.SetMethod = @(obj, varargin) ...
                    SetDispatch(obj, propname{1}, varargin{:});
                metaprop.GetMethod = @(obj)GetDispatch(obj, propname{1});
            end
            
        end
        
        % --- initialises the class object fields
        function initClassFields(obj)
            
            % other memory allocation
            a = cell(1,obj.nMetG);
            
            % object handle retrieval
            obj.hFigH = guidata(obj.hFig);
            obj.hPanelD = obj.hFigH.panelDataOuter;
            obj.hPanelM = obj.hFigH.panelMetricInfo;
            obj.hPanelO = obj.hFigH.panelInfoOuter;            
            
            % memory allocation and other field initialisations
            obj.Name = {'Sheet 1'};
            obj.iPara = {obj.addOrderArray(obj.Type)};
            [obj.Data,obj.mInd] = deal({a});
            obj.stInd = {NaN(obj.nPara,2)};
            obj.alignV = true(1,obj.nMetG);
            obj.altChk = {repmat({false(1,obj.nChk)},1,obj.nMetG)};
            
            % panel selection update function
            obj.pSelFcn = getappdata(obj.hFig,'panelInfoOuterFcn');
            obj.bUpdateFcn = getappdata(obj.hFig,'updateButtonProps');
            obj.mChngFcn = getappdata(obj.hFig,'changeMetricTab');                                               
            
        end
        
        % --- initialises the class object properties
        function obj = initObjProps(obj)
            
            % initialisations
            nStrD = length(obj.hStrD);
            tPosD = getTabPosVector(obj.hPanelD);
            
            % creates the tab panel group
            obj.hTabGrpD = createTabPanelGroup(obj.hPanelD,1);
            set(obj.hTabGrpD,'tag',obj.tStrD,...
                'Units','Pixels','position',tPosD,...
                'Units','Normalized');
            
            % sets up the tab objects (for each tab string)
            [obj.hTab,obj.hTable] = deal(cell(nStrD,1));
            for i = 1:length(obj.hStrD)
                % creates the tab panel objects
                obj.hTab{i} = createNewTabPanel...
                    (obj.hTabGrpD,1,'title',obj.hStrD{i},'UserData',i,...
                    'Units','Normalized');
                
                % creates the tab table (first tab only)
                if i == 1
                    obj.createDataTable(1);
                end
            end
            
            % sets the tab selection change callback function
            setTabGroupCallbackFunc(obj.hTabGrpD,{@obj.changeDataTab});
            
        end        
        
        % -------------------------- %
        % --- DATA TAB FUNCTIONS --- %
        % -------------------------- %
        
        % --- adds a data tab to the table
        function addDataTab(obj)
            
            % updates the parameter struct
            metType = getappdata(obj.hFig,'metType');
            a = cell(1,obj.nMetG);            
            
            % determines the selected radio button
            hRS = findall(obj.hPanelO,'style','radiobutton',...
                'value',1,'Parent',obj.hPanelO);
            
            % enables the delete/move tab menu items
            if obj.nTab == 1
                setObjEnable(obj.hFigH.menuDeleteTab,'on')
                setObjEnable(obj.hFigH.menuMoveTab,'on')
            end
            
            % resets the data struct fields
            obj.Name{end+1} = obj.getUniqueTabName(obj.Name);
            obj.Data = [obj.Data;{a}];
            obj.iPara{end+1} = obj.addOrderArray(metType);
            obj.iSel(end+1) = get(hRS,'UserData');
            obj.mSel(end+1) = obj.mSel(obj.cTab);
            obj.mInd{end+1} = cell(1,obj.nMetG);
            obj.stInd{end+1} = NaN(size(obj.stInd{1}));
            obj.altChk{end+1} = repmat({false(1,obj.nChk)},1,obj.nMetG);
            obj.alignV = [obj.alignV;true(1,obj.nMetG)];
            obj.appOut{end+1} = true(obj.nApp,obj.nMetG);
            obj.expOut{end+1} = true(obj.nExp,obj.nMetG);
            [obj.nTab,obj.cTab] = deal(obj.nTab + 1);
            
            %             % expands the stats arrays
            % iData.stData = [iData.stData,cell(size(iData.stData,1),1)];
            
            % creates the new tab
            obj.hTab{end+1} = createNewTabPanel(obj.hTabGrpD,1,'Title','+');
            
            % resets the user data/title fields
            set(obj.hTab{end},'UserData',obj.nTab+1);
            set(obj.hTab{end-1},'Title',obj.Name{end});
            
            % updates the tab fields
            obj.createDataTable(obj.nTab);
            
            % sets the worksheet information
            obj.changeDataTab([], struct('NewValue',obj.hTab{obj.nTab}))
            obj.updateSheetInfo()
            
        end
        
        % --- deletes the data tab
        function deleteDataTab(obj)
            
            % if there is only one tab, then output an error then exit
            if obj.nTab == 1
                eStr = 'Error! Data output must include at least one worksheet';
                waitfor(errordlg(eStr,'Tab Deletion Error','modal'))
                return
            end
            
            % prompts the user if they want to delete the selected tab
            qStr = 'Are you sure you want to delete the selected tab?';
            uChoice = questdlg(qStr,'Delete Sheet Tab','Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % if the user cancelled, then exit the function
                return
            end
            
            % deletes the currently selected tab
            delete(obj.hTab{obj.cTab})
            
            % decrements the tab counters
            for i = (obj.cTab+1):(obj.nTab+1)
                iTab0 = get(obj.hTab{i},'UserData');
                set(obj.hTab{i},'UserData',iTab0-1);
                obj.hTable{i}.iTab = iTab0-1;
            end
            
            % removes the data associated with the selected tab
            ii = (1:obj.nTab) ~= obj.cTab;
            obj.Name = obj.Name(ii);
            obj.Data = obj.Data(ii);
            obj.iPara = obj.iPara(ii);
            obj.iSel = obj.iSel(ii);
            obj.mSel = obj.mSel(ii);
            obj.mInd = obj.mInd(ii);
            obj.stInd = obj.stInd(ii);
            obj.altChk = obj.altChk(ii);
            obj.alignV = obj.alignV(ii,:);
            
            % resets the tab objects
            kk = [ii,true];
            obj.hTab = obj.hTab(kk);
            obj.hTable = obj.hTable(ii);
            
            % resets the parent object fields
            obj.appOut = obj.appOut(ii);
            obj.expOut = obj.expOut(ii);
                        
            % decrements the tab count
            obj.nTab = obj.nTab - 1;
            if obj.cTab > obj.nTab
                % if the selected tab is greater than tab count, then reset
                obj.cTab = obj.nTab;
                obj.updateTabSelection(obj.hTabGrpD,obj.cTab)
            end
            
            % disables the delete/move tab menu items (if only one tab)
            if obj.nTab == 1
                setObjEnable(obj.hFigH.menuDeleteTab,'off')
                setObjEnable(obj.hFigH.menuMoveTab,'off')
            end
            
            % updates the metric
            obj.updateTabSelection(obj.hTabGrpM,obj.cTab)
            
            % sets the worksheet information and data
            obj.updateSheetInfo()
            
        end
        
        % --- renames the data tab
        function renameDataTab(obj)
            
            % retrieves the data struct
            eStr = [];
            xiN = 1:obj.nTab;
            qStr = 'Enter new tab name:';
            prStr = obj.Name(obj.cTab);
            
            % prompts the user for the new name
            nwStr = inputdlg(qStr,'Selected Tab Rename',[1 40],prStr);
            if ~isempty(nwStr)
                % checks to see if the input string is valid
                if strcmp(nwStr{1},'+')
                    % can't have a "+" as a tab name (used for adding)
                    eStr = 'This is not a valid tab name. Please try again.';
                elseif any(strcmp(nwStr{1},obj.Name(xiN ~= obj.cTab)))
                    % tab name already exists
                    eStr = 'Tab name already exists. Please try again.';
                end
                
                % determines if the new tab name is valid
                if ~isempty(eStr)
                    % if not, output an error to screen and re-run function
                    waitfor(errordlg(eStr,'Invalid Tab Name','modal'))
                    obj.renameDataTab()
                    return
                else
                    % otherwise, update the tab name and tab title
                    obj.Name{obj.cTab} = nwStr{1};
                    set(obj.hTab{obj.cTab},'Title',obj.Name{obj.cTab})
                end
            end
            
        end
        
        % --- moves the data tab
        function moveDataTab(obj,iTab0,iTab)
            
            % sets the permutation array
            ii = find((1:obj.nTab) ~= iTab0);
            jj = [ii(1:(iTab-1)),iTab0,ii(iTab:end)];

            % resets the tab index
            obj.cTab = find(jj == iTab0);            
            
            % reorders the arrays
            obj.Name = obj.Name(jj);
            obj.Data = obj.Data(jj);
            obj.iPara = obj.iPara(jj);
            obj.iSel = obj.iSel(jj);
            obj.mSel = obj.mSel(jj);
            obj.mInd = obj.mInd(jj);
            obj.stInd = obj.stInd(jj);
            obj.altChk = obj.altChk(jj);
            obj.alignV = obj.alignV(jj,:);
            
            % reorders the other arrays
            [obj.appOut,obj.expOut] = deal(obj.appOut(jj),obj.expOut(jj));
            
            % updates the tab properties
            kk = [jj,length(jj)+1];
            hChild = get(obj.hTabGrpD,'Children');
            set(obj.hTabGrpD,'Children',hChild(kk))
            [obj.hTable,obj.hTab] = deal(obj.hTable(jj),obj.hTab(kk));
                        
            % updates the visiblity flags
            obj.updateTabSelection(obj.hTabGrpD,obj.cTab);
%             setObjVisibility(obj.hTable{obj.cTab},'on')
                                    
        end
        
        % --- clears the data tab
        function clearDataTab(obj)
            
            % removes all flags for each of the alternative option values
            iSelC = obj.iSel(obj.cTab);
            
            % resets the data struct fields
            obj.altChk{obj.cTab}{iSelC}(:) = false;
            obj.Data{obj.cTab}{iSelC} = [];
            obj.iPara{obj.cTab}{iSelC}(1) = {[]};
            obj.mInd{obj.cTab}{iSelC} = [];                        
            
            % clears the stats selection (if selected)
            if (iSelC == 1); obj.stInd{obj.cTab}(:) = NaN; end
            
            % sets the worksheet information
            obj.updateSheetInfo()
            
        end
        
        % ---------------------------- %
        % --- DATA TABLE FUNCTIONS --- %
        % ---------------------------- %
        
        % --- creates the worksheet table object for the tab index, iTab
        function createDataTable(obj,iTab)
                        
            % creates the data table object
            obj.hTable{iTab} = ...
                DataTableObject(obj.hPanelD,obj.hTab{iTab},iTab);            
            
        end
        
        % --- updates the data table
        function updateDataTable(obj,isRecalc,varargin)
            
            % turns all warnings
            wState = warning('off','all');
            obj.allowSelect = true;
            
            % other initialisations
            DataT = [];
            iSelT = obj.iSel(obj.cTab);
            iParaT = obj.iPara{obj.cTab}{iSelT};
            obj.hTable{obj.cTab}.resetObjectUnits();
            
            % sets the tab worksheet data cell array
            if ~isRecalc
                % if not recalculating, then retrieve the stored values
                DataT = obj.Data{obj.cTab}{iSelT};
                
            elseif ~isempty(iParaT{1})
                % creates the progress loadbar
                h = ProgressLoadbar('Reshaping Table Data...');
                obj.Data{obj.cTab}{iSelT} = [];
                
                % sets up the signal data array object
                sObj = DataOutputSetup(obj.hFig,h);
                if sObj.ok
                    % if successful, then updates the sheet data array
                    DataT = sObj.Data;
                    obj.mInd{obj.cTab}{iSelT} = sObj.mInd;
                    delete(sObj);
                else
                    % otherwise, rethrow the error message (use this for debugging...)
                    rethrow(sObj.msgObj)
                end
            else
                % sets an empty array for the sheet data array
                obj.mInd{obj.cTab}{iSelT} = [];
            end            
            
            % disables the save menu item
            setObjEnable(obj.hFigH.menuSave,any(~cellfun('isempty',obj.Data)))
            enableDisableFig(obj.hFig,'off');            
            
            % determine if there is sufficient memory to display the data
            try jheapcl; catch; end

            % updates the table data
            obj.hTable{obj.cTab}.updateTableData(DataT);
            obj.Data{obj.cTab}{iSelT} = DataT;
            
            % clears the warning buffer
            pause(0.05); drawnow();
            fprintf(' \b');
            
            % updates the data field            
            clear DataT;            
                        
            % deletes the loadbar
            enableDisableFig(obj.hFig,'on');
            warning(wState);
            
        end
        
        % --- updates the data tab information
        function updateSheetInfo(obj,varargin)
            
            % updates the radio button value
            uD = 1 + (obj.iSel(obj.cTab) > 1);
            hRadio = findall(obj.hPanelO,'style','radiobutton');
            set(hRadio,'UserData',uD,'Value',1)
            
            % updates the selection index
            [~,obj.iSel(obj.cTab)] = obj.getSelectedIndexType();
            
            % updates the panel selection
            if (nargin == 1)
                obj.pSelFcn(obj.hPanelO, 1, obj.hFigH)
            else
                obj.pSelFcn(obj.hPanelO, '1', obj.hFigH)
            end
            
        end        
                
        % -------------------------- %
        % --- CALLBACK FUNCTIONS --- %
        % -------------------------- %
        
        % --- callback function for altering the sheet tabs
        function changeDataTab(obj,~,evnt)
            
            % determines if a new tab has to be added
            addTab = strcmp(get(evnt.NewValue,'Title'),'+');
            
            % determines which tab was selected
            if addTab
                % selected tab was the addition tab
                obj.addDataTab();
            else
                % retrieves the new and set tab user data values
                uDataS = cellfun(@(x)...
                    (get(x,'UserData')),obj.hTab(1:end-1),'un',0);
                uDataN = get(evnt.NewValue,'UserData');
            
                % determines the new the tab index
                cTab0 = obj.cTab;
                obj.cTab = find(cell2mat(uDataS) == uDataN);
                hTab0 = obj.hTable{cTab0};
                
                % stops the cell editor (if editting)
                if hTab0.jTable.isEditing
                    hTab0.jTable.getCellEditor().stopCellEditing();
                    pause(0.05);
                end
                
                % retrieves the metrics index of tab
                hTabM = get(obj.hTabGrpM,'Children');
                uDataM = get(hTabM,'UserData');
                if iscell(uDataM); uDataM = cell2mat(uDataM); end
                
                % updates the selected tab
                i1 = find(uDataM == obj.mSel(obj.cTab));
                obj.updateTabSelection(obj.hTabGrpM,i1);
                
                % sets the worksheet information
                if obj.iSel(obj.cTab) == 1
                    obj.mChngFcn(obj.hTabGrpM)
                else
                    evnt = struct('NewValue',hTabM(i1));
                    obj.mChngFcn(obj.hTabGrpM, evnt, 1)
                end
            end
                
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %         
        
        % --- resizes all the table objects
        function resizeTableObjects(obj)
            
            % sets the index array for the table update
            indT = [obj.cTab,find(setGroup(obj.cTab,[1,obj.nTab]))];
            
            % resizes the individual tables
            for i = indT
                obj.hTable{i}.resizeTableData();
            end
            
        end
        
        % --- gets the tab table position vector
        function tPosD = getTabTablePos(obj,hTabGrpNw)
            
            % sets the tab group handle (if not provided)
            if ~exist('hTabGrpNw','var')
                hTabGrpNw = obj.hTabGrpD;
            end
            
            % sets the table position vector
            tgPos = get(hTabGrpNw,'position');
            tPosD = [1 1 tgPos(3:4)-[6 30]];            
            
        end		
		
        % --- creates a new index order array
        function iPara = addOrderArray(obj,metType)
            
            % iPara Convention
            %
            % Element 1 - Statistical Test
            % Element 2 - Population Metrics
            % Element 3 - Fixed Metrics
            % Element 4 - Individual Metrics
            % Element 5 - Population Signals
            % Element 6 - Individual Signals
            % Element 7 - 2D Array
            % Element 8 - Parameters
            
            % memory allocation
            [isMP,a] = deal(metType(:,1),[]);
            
            % set the individual cell components (population metrics)
            if any(isMP)
                a = false(sum(isMP),obj.nMet);
                [a(:,1),a(1,end)] = deal(true);
            end
            
            % sets the final array
            iPara = repmat({{[]}},1,obj.nMetG);
            iPara{2} = {[],a};
            
        end
        
        % --- gets the selected radio button index and overall index
        function [iSel,iSelT] = getSelectedIndexType(obj)
            
            % determines the
            hRS = findall(obj.hPanelO,'style',...
                'radiobutton','value',1,'Parent',obj.hPanelO);
            
            % retrieves the selected radio button index
            iSel = get(hRS,'UserData');
            iSelT = obj.mSel(obj.cTab)*(iSel > 1) + 1;
            
        end
        
        % --- sets the metric statistics string from the index array, metInd
        function mStr = setMetricStatString(obj,metInd)
            
            % determines the selected indices (remove the N-values)
            iMet = find(metInd);
            iMet = iMet(iMet ~= obj.nMet);
            
            % sets the metric string based on the selection type
            if (length(iMet) > 1)
                % case is multiple metrics have been selected
                mStr = 'Multiple Metrics';
            else
                % case is only one has been selected
                [~,mStr] = ind2varStat(iMet);
            end
            
        end
        
        % --- sets the statistical test string
        function stStr = setStatTestString(obj,pType,iRow)
            
            % initisalisations
            switch pType{1}
                case {'Sim','SimDN','GOF'}
                    % case is the similarity matrics
                    outStr = [];
                    
                case {'SimNorm','SimNormDN'}
                    % case is the normalised similarity matrices
                    outStr = {'Raw','Normalised'};
                    
                otherwise
                    % case is the significance tests
                    outStr = {'P-Values','Significance','Both'};
            end
            
            % determines if a valid test type has been set/calculated
            stIndS = obj.stInd{obj.cTab}(iRow,:);
            if isnan(stIndS(1))
                % if no test is set, then set an empty string
                stStr = '';
            else
                % otherwise, set the test string based on the type
                stData = obj.getData(1,iRow,stIndS(1));
                if isempty(outStr)
                    stStr = stData.Test;
                else
                    if iscell(stData.Test)
                        stStr = cellfun(@(x)(sprintf('%s (%s)',x,...
                            outStr{stIndS(2)})),stData.Test,'un',0);
                    else
                        stStr = sprintf('%s (%s)',stData.Test,outStr{stIndS(2)});
                    end
                end
            end
            
        end
        
        % --- sets the row/column indice array
        function ind = setDataTableIndices(obj,x0,rSz,vSz,mxSz,del)
            
            [dimLo,dimHi] = obj.calcIndLim(x0,rSz,vSz);
            ind = max(0,dimLo-del):min(mxSz-1,dimHi+del);
            
        end        

        % --- retrieves the data table position
        function tPosD = getDataTablePos(obj)
            
            tabPosD = get(obj.hTabGrpD,'Position');
            tPosD = [1,1,tabPosD(3:4)-[1,30]]; 

        end        
        
    end
    
    % static class methods
    methods (Static)
        
        % --- function that updates the tab selection
        function updateTabSelection(hTabGrp,iNw)
            
            % updates the selected tab based on the graphics type
            if nargin == 2
                % new index is the order within tab group
                hTabGrp.SelectedTab = hTabGrp.Children(iNw);
            else
                % new index is based on the user data flag
                hTabGrp.SelectedTab = findall(hTabGrp,'UserData',iNw);
            end
            
        end
        
        % --- determines the unique data tab name
        function tNameNw = getUniqueTabName(tName0)
            
            % determines the current number of tabs
            nTab = length(tName0) + 1;
            
            % keep incrementing the tab counter until feasible
            while (1)
                tNameNw = sprintf('Sheet %i',nTab);
                if ~any(strcmp(tName0,tNameNw))
                    % unique name has been found so exit
                    break
                else
                    % name is not unique, so increment the counter
                    nTab = nTab + 1;
                end
            end
            
        end  
        
        % --- sets the lower/higher limit indices
        function [dimLo,dimHi] = calcIndLim(x0,rSz,vSz)
            
            dimLo = floor(x0/rSz);
            dimHi = ceil((x0+vSz)/rSz);
            
        end
        
        % --- stops editing and removes selection (for an editted cell)
        function resetSelectedCell(jTab,iRow,iCol)
            
            % if editting, then stop editting
            if jTab.isEditing()
                jTab.getCellEditor().stopCellEditing();
            end
            
            % toggles the cell selection
            jTab.changeSelection(iRow, iCol, false, false);
            
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