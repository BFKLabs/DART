classdef OpenSolnFilesObj < handle
    
    % class properties
    properties
        
        % input arguments
        hFigM
        sType
        
        % main class objects
        hFig
        hTabGrp
        jTabGrp
        hPanelO
        hParent
        
        % sub-class objects
        objT
        cObj
        
        % fixed dimension fields
        dX = 10;
        hghtBut = 25;
        hghtRow = 25;
        hghtHdr = 20;
        hghtHdrTG = 25;        
        hghtPanelO = 630;
        widPanelO = 830;
        
        % calculated dimension fields
        widFig
        hghtFig
        widTabGrp
        hghtTabGrp
        
        % menu item class fields
        hMenuF
        
        % group/experiment names
        expDir
        expName
        gName
        gName0
        gNameU         
        
        % other important class fields
        nExp
        sDir
        sDir0
        iProg
        sInfo
        pDataT  
        postLoadFcn
                        
        % boolean class fields
        hasInfo
        isChange = false;
        
        % static class fields
        nTab
        fSzH = 13;
        fSzL = 12;
        fSz = 10 + 2/3;
        
        % java colours
        white = java.awt.Color.white;
        black = java.awt.Color.black;
        gray = getJavaColour(0.81*ones(1,3));
        grayLight = getJavaColour(0.90*ones(1,3));
        redFaded = getJavaColour([1.0,0.5,0.5]);
        blueFaded = getJavaColour([0.5,0.5,1.0]);
        greenFaded = getJavaColour([0.5,1.0,0.5]);        
        
        % static string fields
        tagStr = 'figOpenSolnFile';
        figName = 'Solution File Explorer';
        lStr = 'Loading Solution File Information...';
        tHdrTG = {'Load Solution Files',...
                  'Experiment Compatibility & Groups',...
                  'Function Compatibility'};
        
    end
    
    % class methods
    methods
        
        % --- class constuctor
        function obj = OpenSolnFilesObj(hFigM,sType)
            
            % sets the input arguments
            obj.hFigM = hFigM;
            obj.sType = sType;
            
            % initialises the class fields/objects
            obj.initSolnClassFields();
            obj.initSolnClassObjects();
            
            % clears the output object (if not required)
            if (nargout == 0) && ~isdeployed
                clear obj
            end
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initSolnClassFields(obj)            
            
            % main dialog window field retrieval
            obj.iProg = getappdata(obj.hFigM,'iProg');            
            obj.pDataT = getappdata(obj.hFigM,'pDataT');
            obj.sInfo = getappdata(obj.hFigM,'sInfo');
            [obj.sDir,obj.sDir0] = deal(getappdata(obj.hFigM,'sDirO'));                       
            obj.postLoadFcn = getappdata(obj.hFigM,'postSolnLoadFunc');
            
            % field initialisation
            obj.nExp = length(obj.sInfo);            
            obj.nTab = 1 + 2*(obj.sType == 3);
            
            % memory allocation
            obj.objT = cell(obj.nTab,1);
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %
                        
            if obj.sType == 3
                % case is using all tabs
                obj.widTabGrp = obj.widPanelO + obj.dX;
                obj.hghtTabGrp = obj.hghtPanelO + obj.dX + obj.hghtHdrTG;
                obj.widFig = obj.widTabGrp + 2*obj.dX;
                obj.hghtFig = obj.hghtTabGrp + 2*obj.dX;
                
            else
                % calculates the panel objects
                obj.widFig = obj.widPanelO + 2*obj.dX;
                obj.hghtFig = obj.hghtPanelO + 2*obj.dX;
            end
            
        end
        
        % --- initialises the class fields
        function initSolnClassObjects(obj)
            
            % deletes any previous GUIs
            hPrev = findall(0,'tag',obj.tagStr);
            if ~isempty(hPrev); delete(hPrev); end
            
            % hides the main window
            setObjVisibility(obj.hFigM,'off')            
            
            % function handles
            cbFcn = @obj.tabSelected;                        
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            if obj.sType ~= 2
                obj.hFig = createUIObj('figure','Position',fPos,...
                    'tag',obj.tagStr,'MenuBar','None','Toolbar','None',...
                    'Name',obj.figName,'Resize','on','NumberTitle','off',...
                    'Visible','off','AutoResizeChildren','off',...
                    'BusyAction','Cancel','GraphicsSmoothing','off',...
                    'DoubleBuffer','off','Renderer','painters',...
                    'CloseReq',[]);
            end
            
            if obj.sType == 3
                % case is opening within analysis

                % creates the tab group object
                pPosTG = [obj.dX*[1,1],obj.widTabGrp,obj.hghtTabGrp];
                obj.hTabGrp = createUIObj('tabgroup',obj.hFig,...
                    'Position',pPosTG,'SelectionChangedFcn',cbFcn);                    

                % sets the parent object
                obj.hParent = obj.hTabGrp;                    
            
            elseif obj.sType == 2
                % case is multi-experiment saving
                
                % retrieves the parent panel object
                hFigMS = findall(0,'tag','figMultiSave');
                obj.hParent = findall(hFigMS,'tag','panelExptGroup');
                
            else
                % creates the panel object
                pPosO = [obj.dX*[1,1],obj.widPanelO,obj.hghtPanelO];
                obj.hPanelO = createPanelObject(obj.hFig,pPosO);
                
                % sets the parent object
                obj.hParent = obj.hPanelO;                
            end            
                        
            % ----------------------- %
            % --- TAB PANEL SETUP --- %
            % ----------------------- %                            

            switch obj.sType
                case 1
                    % case is opening from data combining file load
                    obj.objT = SolnFileLoad(obj,1);                    
                    
                case 2
                    % case is opening from multi-experiment saving
                    obj.objT = MultiExptGrouping(obj,2,true);        
                    
                case 3
                    % creates the load bar
                    hLoad = ProgressLoadbar(obj.lStr);                    
                    
                    % case is opening from analysis file load 
                    obj.objT{1} = SolnFileLoad(obj,1);
                    obj.objT{2} = MultiExptGrouping(obj,2,false);
                    obj.objT{3} = ExptFuncDependency(obj,3);                                        

                    % runs the analysis function external package
                    hGUI = guidata(obj.hFigM);
                    feval('runExternPackage',...
                        'AnalysisFunc',hGUI,'OpenSolnFile',obj);
                    
                    % disables these tabs (enabled when files are loaded)
                    obj.jTabGrp = getTabGroupJavaObj(obj.hTabGrp);
                    arrayfun(@(x)(obj.jTabGrp.setEnabledAt(x-1,0)),2:3);
                    
                    % deletes the loadbar
                    delete(hLoad);
            end
                        
%             % REMOVE ME LATER
%             obj.hTabGrp.SelectedTab = obj.objT{2}.hTab;
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            if ~isempty(obj.hFig)
                % sets up the menu item objects
                obj.setupMenuItems();
                
                % opens the class figure
                openClassFigure(obj.hFig);                
            end                
            
        end
        
        % --- sets up the menu item objects
        function setupMenuItems(obj)
            
            % parent menu item field initialisations
            pStr = {'hMenuF'};
            mStr = {'File'};
            tStr = {'menuFile'};
            
            % creates the main menu items
            for i = 1:length(tStr)
                obj.(pStr{i}) = uimenu(...
                    obj.hFig,'Label',mStr{i},'tag',tStr{i});
            end
            
            % ----------------------- %
            % --- FILE MENU ITEMS --- %
            % ----------------------- %
            
            % creates the sub-menu items
            uimenu(obj.hMenuF,'Label','Reset Scale Factor',...
                'Callback',@obj.menuScaleFactor,'Accelerator','R',...
                'Tag','menuScaleFactor');
            uimenu(obj.hMenuF,'Label','Concatenate Experiments',...
                'Callback',@obj.menuCombExpt,'Accelerator','E',...
                'Tag','menuCombExpt');
            uimenu(obj.hMenuF,'Label','Set Time Cycle',...
                'Callback',@obj.menuTimeCycle,'Accelerator','C',...
                'Tag','menuTimeCycle');
            uimenu(obj.hMenuF,'Label','Load External Data',...
                'Callback',@obj.menuLoadExtnData,'Accelerator','L',...
                'Tag','menuLoadExtnData','Separator','on');
            uimenu(obj.hMenuF,'Label','Close Window',...
                'Callback',@obj.menuCloseWindow,'Accelerator','X',...
                'Tag','menuCloseWindow','Separator','on');
            
            % disables the required menu items
            obj.setMenuEnable('menuScaleFactor',0);
            obj.setMenuEnable('menuCombExpt',0);
            obj.setMenuEnable('menuTimeCycle',0);
            
        end
        
        % ------------------------------------ %
        % --- MENU ITEM CALLBACK FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- scale factor menu item callback function
        function menuScaleFactor(obj, ~, ~)
            
            % runs the video parameter reset dialog
            ResetVideoPara(obj);            
            
        end
        
        % --- experiment concatenation menu item callback function
        function menuCombExpt(obj, ~, ~)
            
            % runs the experiment concatenation dialog
            ConcatExptClass(obj);            
            
        end
        
        % --- time cycle menu item callback function
        function menuTimeCycle(obj, ~, ~)
            
            TimeCycle(obj.hFig);            
            
        end
        
        % --- load external data menu item callback function
        function menuLoadExtnData(obj, ~, ~)
            
            % runs the video parameter reset dialog
            if ~isempty(obj.sInfo)
                ExtnData(obj);
            end            
            
        end
                
        % --- close window menu item callback function
        function menuCloseWindow(obj, ~, ~)
            
            % determines if there is a change (but no data is loaded)
            if obj.isChange && isempty(obj.sInfo)
                % if no data is loaded, then update only if data is stored
                obj.isChange = ~isempty(getappdata(obj.hFigM,'sInfo'));
            end
            
            % determines if there were any changes made
            if obj.isChange
                % if so, prompts user if they wish to update the changes
                tStr = 'Update Changes?';
                qStr = 'Do wish to update the changes you have made?';
                uChoice = questdlg(qStr,tStr,'Yes','No','Cancel','Yes');
                switch uChoice
                    case 'Yes'
                        % case is the user chose to update
                        
                        % retrieves solution file struct from loaded object
                        if obj.sType == 3
                            % determines how many compatible experiment 
                            % groups exist
                            indG = obj.cObj.detCompatibleExpts();
                            if length(indG) > 1
                                % updates the selected tab to the expt grouping tab
                                obj.hTabGrp.SelectedTab = obj.objT{2}.hTab;
                                
                                % if more than one group, then prompt the 
                                % user if they wish to continue
                                hTabS = obj.objT{2}.hTabGrpGL.SelectedTab;
                                mStr = obj.getErrorStr(get(hTabS,'Title'));
                                tStr = 'Continue Loading Data>';
                                uChoice = questdlg(...
                                    mStr,tStr,'Yes','No','Yes');
                                if ~strcmp(uChoice,'Yes')
                                    % if the user cancelled, then exit
                                    return
                                end
                            end
                            
                            % case is for loading data from analysis gui
                            sInfoF = obj.resetLoadedExptData();
                            
                        else
                            % case is for loading files from combining gui
                            sInfoF = obj.sInfo;
                        end
                        
                        % retrieves the names of the loaded experiments
                        if isempty(sInfoF)
                            expFileF = {'Dummy'};
                        else
                            expFileF = cellfun(...
                                @(x)(x.expFile),sInfoF,'un',0);
                        end
                        
                        % determines if there are repeated experiment names
                        if length(expFileF) > length(unique(expFileF))
                            % if so, then output an error message to screen
                            mStr = sprintf(['There are repeated experiment names ',...
                                'within the loaded data list.\nRemove ',...
                                'all repeated file names before ',...
                                'attempting to continue.']);
                            waitfor(msgbox(mStr,'Repeated File Names','modal'))
                            
                            % exits the function
                            return
                        end
                        
                        % updates the search directories in the main gui
                        setappdata(obj.hFigM,'sDirO',obj.sDir);
                        
                        % delete the figure and run the post solution loading function                        
                        setObjVisibility(obj.hFig,0);
                        obj.postLoadFcn(obj.hFigM,sInfoF);
                        obj.deleteClass();                        
                        
                    case 'No'
                        % case is the user chose not to update
                        
                        % run post solution loading function & delete class
                        setObjVisibility(obj.hFig,0);                        
                        obj.postLoadFcn(obj.hFigM);
                        obj.deleteClass();
                end
            else
                % run post solution loading function & delete class
                setObjVisibility(obj.hFig,0);
                obj.postLoadFcn(obj.hFigM);
                obj.deleteClass();                
            end
            
        end
        
        % --------------------------------------- %
        % --- OTHER OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- tab group selection callback function
        function tabSelected(obj, hObj, ~)
            
            a = 1;
            
        end        

        % -------------------------------------- %
        % --- FIGURE/OBJECT UPDATE FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- updates the experiment information in the full gui
        function updateFullGUIExpt(obj)
            
            % gui update only applicable for analysis gui file loading
            if obj.sType ~= 3
                return
            end
            
            % pauses for any updates
            pause(0.05);
            
            % updates the experiment comparison class object
            obj.cObj.updateExptCompData(obj.sInfo);
            
            % resets the checkbox values
            hChk = obj.objT{2}.hChkGC;
            uD = cellfun(@(x)(get(x,'UserData')),hChk,'un',0);
            cellfun(@(h,i)(set(h,'Value',obj.cObj.iSel(i))),hChk,uD)
            
            % updates the function compatibility tab
            obj.objT{3}.updateFuncDepTable();
            
            % updates the experiment comparison tab
            obj.objT{2}.updateExptInfoTable();
            
        end        
        
        % --- updates the group names
        function updateGroupNames(obj,iType)
            
            % updates the experiment names
            switch iType
                case 1
                    % case is updating from the file open panel 

                    % updates the group names
                    for i = 1:length(obj.gName)
                        obj.gName{i} = obj.sInfo{i}.gName;
                    end                    
                     
                    % resets the final grouping name arrays
                    obj.objT{2}.resetFinalGroupNameArrays()                                      
                    
                    % resets the group lists
                    obj.objT{2}.updateGroupLists()        
                    obj.objT{2}.updateTableGroupNames() 
                    
                case 2
                    % case is updating from the expt comparison panel
                    
                    % updates the group names
                    for i = 1:length(obj.gName)
                        obj.sInfo{i}.gName = obj.gName{i};
                    end
                    
                    % updates the group table properties
                    obj.objT{1}.updateGroupTableProps();
                    
            end
            
        end        
        
        % --- updates the experiment names on the other tabs (when altering
        %     an experiment name in 
        function updateExptNames(obj,iExp,iType)
            
            % retrieves the new experiment name
            expFileNw = obj.sInfo{iExp}.expFile;
            expFileCell = java.lang.String(expFileNw);
        
            % updates the experiment names
            switch iType
                case 1
                    % case is updating from the file open panel 
                    
                    % updates the experiment name within the table
                    obj.objT{2}.tableUpdate = true;
                    obj.objT{2}.jTableC.setValueAt(expFileCell,iExp-1,0);
                    obj.objT{2}.jTableC.repaint()
                    
                    % resets the group lists
                    obj.objT{2}.updateGroupLists()                       
                    
                    % resets the flag (after pausing for update)
                    pause(0.05)
                    obj.objT{2}.tableUpdate = false;                                     
                    
                case 2
                    % case is updating from the expt comparison panel

                    % updates the experiment name within the table
                    obj.objT{1}.tableUpdate = true;
                    obj.objT{1}.jTableD.setValueAt(expFileCell,iExp-1,0);
                    obj.objT{1}.jTableD.repaint()
                    
                    % resets the experiment table background colour
                    obj.objT{1}.resetExptTableBGColour(0);   
                    
                    % resets the flag (after pausing for update)
                    pause(0.05)
                    obj.objT{1}.tableUpdate = false;                    
            end
        
        end        
        
        % --- sets the menu item enabled state
        function setMenuEnable(obj,pStr,eState)
            
            setObjEnable(obj.getMenuItem(pStr),eState);
            
        end                
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- retrieves the menu item with tag field, pStr
        function hMenu = getMenuItem(obj,pStr)
            
            hMenu = findall(obj.hFig,'tag',pStr);
            
        end        
        
        % --- resets the loaded experiment data
        function sInfoF = resetLoadedExptData(obj)
            
            % if there is no loaded data, then exit with an empty array
            if isempty(obj.sInfo)
                sInfoF = [];
                return
            end
            
            % determines the currently selected experiment
            indG = obj.cObj.detCompatibleExpts();
            iTabG = obj.objT{2}.getCurrentTab();
            
            % reduces stimuli inforation/group names for current grouping
            iS = indG{iTabG};
            grpName = obj.gNameU{iTabG};
            [sInfoF,gNameF] = deal(obj.sInfo(iS),obj.gName(iS));            
            
            % removes any group names that are not linked to any experiment
            hasG = cellfun(@(x)(any(...
                cellfun(@(y)(any(strcmp(y,x))),gNameF))),grpName);
            grpName = grpName(hasG);
            
            % loops through each of the loaded
            for i = 1:length(sInfoF)
                % sets the group to overall group linking indices
                indL = cellfun(@(y)(...
                    find(strcmp(gNameF{i},y))),grpName,'un',0);
                
                % removes any extraneous fields
                snTotF = sInfoF{i}.snTot;
                if detMltTrkStatus(snTotF.iMov)
                    sInfoF{i}.snTot = ...
                        reduceMultiTrackExptSolnFiles(snTotF,indL,grpName);
                else
                    sInfoF{i}.snTot = ...
                        reduceExptSolnFiles(snTotF,indL,grpName);
                end
            end
        
        end                
        
        % --- deletes the class object
        function deleteClass(obj)
        
            % deletes the explorer tree class objects
            if obj.sType == 3
                % case is accessing via analysis
                ii = ~cellfun('isempty',obj.objT);
                cellfun(@(x)(x.deleteClass()),obj.objT(ii));
                
            else
                % case is accessing via other means
                obj.objT.deleteClass();
            end
            
            % deletes the main figure and objec
            delete(obj.hFig)            
            delete(obj)
            clear obj
            
        end        
        
    end
    
    % class methods
    methods (Static)
        
        % --- retrieves the error string
        function eStr = getErrorStr(tHdr)
            
            eStr = sprintf(['More than one compatible experiment ',...
                'grouping has been determined.\nThe currently ',...
                'selected experiment group is "%s". Are you sure you ',...
                'want to continue loading this experiment group?'],tHdr);
            
        end
            
    end
    
end