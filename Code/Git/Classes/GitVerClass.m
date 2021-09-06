classdef GitVerClass < handle
    
    % class properties
    properties
        % class object handles
        hFig
        hGUI
        hProg
        
        % other gui object handles   
        jTab
        hList
        hTabDiff
        
        % git repository information
        rType
        gDirP
        gRepoDir
        gName
        
        % sub-classes objects
        gfObj           % git function object
        gObj            % graph objects
        rObj            % repository log information
        cmObj           % context menu object
        iData
        pDiff
        cBlk
        postRefLogFcn
        
        % other scalar flags
        ok = true;
        nTab
        indD
        nHist0
        isMenuOpen = false;
        
        % cell arrays
        bStrGrp
        tStr = {'Altered','Added','Removed','Moved'};
        bGrpType = {'main','develop','feature','hotfix','other'};        
        
    end
    
    % hidden class properties
    properties (Hidden)
        
        pWordHF = 'BfkLabHF';
        
    end
    
    % class methods
    methods
        % --- class constructor
        function obj = GitVerClass(hFig)
            
            % sets the input variables
            obj.hFig = hFig;
            obj.hGUI = guidata(hFig);
            
            % initialises the class object fields
            obj.initDataStruct();
            
            % sets up the git function class object
            obj.ok = obj.setupGitFuncClass();
            if ~obj.ok
                % if the user cancelled, then exit
                return
            end
            
            % initialises the object callbacks
            obj.initObjCallbacks();
            
            % sets up the repository struct object
            obj.setupRepoStructure();
            obj.setupRepoGraph();            
            obj.setupGUIObjects();
            
            % sets the original master history count
            obj.nHist0 = size(obj.rObj.gHist(1).brInfo,1);
            
            % closes the progress bar
            try; delete(obj.hProg); end
            
        end
        
        % --------------------------------------------- %
        % --- CLASS OBJECT INITIALISATION FUNCTIONS --- %
        % --------------------------------------------- %        
        
        % --- initialises all the object callback functions
        function initObjCallbacks(obj)
           
            % objects with normal callback functions
            cbObj = {'editVerCount','buttonUpdateFilt','menuRefresh',...
                     'buttonUpdateVer','menuRefLog','menuBranchInfo',...
                     'menuResetHistory'};
            for i = 1:length(cbObj)
                hObj = getStructField(obj.hGUI,cbObj{i});
                cbFcn = eval(sprintf('@obj.%sCB',cbObj{i}));
                set(hObj,'Callback',cbFcn)
            end
            
            % objects with cell selection callback functions
            scObj = {'panelVerFilt'};
            for i = 1:length(scObj)
                hObj = getStructField(obj.hGUI,scObj{i});
                cbFcn = eval(sprintf('@obj.%sSC',scObj{i}));
                set(hObj,'SelectionChangedFcn',cbFcn)
            end            
            
            % sets the figure window motion callback function
            set(obj.hFig,'WindowButtonMotionFcn',@obj.mouseMove,...
                         'WindowButtonDownFcn',@obj.mouseDown)            
            
        end
        
        % --- initialises the GUI data struct
        function initDataStruct(obj)

            % retrieves the current date indices
            dStr = strsplit(datestr(now,'dd/mm/yyyy'),'/');
            dVal = cellfun(@str2double,dStr);

            % retrieves the date string numbers for the start/end times
            d0 = struct('Day',1,'Month',1,'Year',2019);

            % sets up the data struct
            obj.iData = struct('gHist',[],'nHist',20,'y0',2018,'d0',d0); 
                           
            % sets the post reflog update function handle
            obj.postRefLogFcn = @obj.postRefLogCB;

        end
        
        % --- sets up and initialises the gui object
        function setupGUIObjects(obj)
            
            % updates the loadbar
            lStr = 'Initialising GUI Object Properties...';
            obj.hProg.StatusMessage = lStr;
            
            % initialisations            
            hRadioVer = obj.hGUI.radioAllVer;
            hPanelVer = obj.hGUI.panelVerFilt;
            hPanelDate = obj.hGUI.panelFiltDate;
            hTableCode = obj.hGUI.tableCodeLine;
            
            % other initialisations  
            [~,iCm] = obj.getCurrentHeadInfo();
            dYear = str2double(datestr(datenum(datestr(now)),'yyyy'));
            
            % creates the tab objects
            obj.setupVersionDiffObjects();

            % sets the tab selection change callback function
            setTabGroupCallbackFunc(obj.hTabDiff,{@obj.changeDiffTab});

            % disables the update version button
            setObjEnable(obj.hGUI.buttonUpdateVer,0)  
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%    HISTORY VERSION PANEL OBJECTS    %%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            

            % initialises the version filter panel
            set(hRadioVer,'value',1)
            obj.panelVerFiltSC(hPanelVer, '1')            

            % sets the callback function for all data popup objects
            hPopup = findall(hPanelDate,'style','popupmenu');
            for i = 1:length(hPopup)
                % sets the callback function
                set(hPopup(i),'Callback',@obj.updateDateFilter)

                % determines if the popup menu object is before
                [isBF,dType] = obj.getSelectedPopupType(hPopup(i));      

                % sets up the popup menu strings based on the object type
                dN = getStructField(obj.iData,sprintf('d%i',isBF));
                switch dType
                    case 1
                        % case is the day popupmenu            

                        % determines the number of days given the month
                        dMax = obj.getDayCount(dN.Month);          

                        % sets the popup menu list strings
                        iSel = dN.Day;
                        pStr = arrayfun(@num2str,1:dMax,'un',0)';

                    case 2
                        % case is the month popupmenu            

                        % sets the popup menu list strings            
                        iSel = dN.Month;
                        pStr = {'Jan','Feb','Mar','Apr','May','Jun',...
                                'Jul','Aug','Sep','Oct','Nov','Dec'}';

                    case 3
                        % case is the year popupmenu      

                        % sets the popup menu list strings            
                        iSel = dN.Year - obj.iData.y0;
                        pStr = arrayfun(@num2str,2019:dYear,'un',0)';

                end

                % sets the popup strings
                set(hPopup(i),'string',pStr,'value',iSel)
            end

            % initialises the codeline table properties
            [cWid0,tPos] = deal(50,get(hTableCode,'position'));
            cWid = {cWid0,cWid0,tPos(3)-2*cWid0};
            set(hTableCode,'data',[],'columnwidth',cWid)
            autoResizeTableColumns(hTableCode)   
            
            % updates the version/commit difference info
            obj.updateCommitDiffInfo();
            obj.updateVersionInfo();    
            
            % -------------------------------------- %
            % --- OTHER PROPERTY INITIALISATIONS --- %
            % -------------------------------------- %
            
            % sets the menu enabled properties
            setObjVisibility(obj.hGUI.menuResetHistory,obj.gfObj.uType==0)
            setObjEnable(obj.hGUI.menuResetHistory,iCm>1)
            
        end
        
        % --- sets up the repository graph object
        function setupRepoGraph(obj)
           
            % updates the loadbar
            lStr = 'Determining Repository Branch Structure...';
            obj.hProg.StatusMessage = lStr;    

            % creates the git graph class object            
            obj.gObj = GitGraph(obj.hFig,obj.rObj);
            
            % creates the axes context menu
            pStr = {'Dummy'};
            obj.cmObj = AxesContextMenuGit(obj.hFig,obj.gObj.hAx,pStr,0);
            obj.cmObj.setMenuParent(obj.hGUI.panelVerHist);
            obj.cmObj.setCallbackFcn(@obj.menuSelect);             
            
        end
        
        % --- sets up the repository structure object 
        function setupRepoStructure(obj)
            
            % updates the loadbar
            lStr = 'Determining Repository Branch Structure...';
            obj.hProg.StatusMessage = lStr;            
            
            % sets up the repository struct object            
            obj.rObj = RepoStructure(); 
            obj.rObj.isMod = obj.detIfHeadModified();            
            
            % groups the branch names
            obj.groupBranchStrings();
            
            % updates the history 
            nHistM = size(obj.rObj.gHist(1).brInfo,1);
            obj.iData.nHist = min([nHistM,obj.iData.nHist]);
            set(obj.hGUI.editVerCount,'string',num2str(obj.iData.nHist))
            
            % initialises the difference data struct            
            obj.pDiff = cell(obj.rObj.nCommit);
            
        end
        
        % --- sets up the git function class object
        function ok = setupGitFuncClass(obj)

            % initialisations
            ok = true;            
            
            % prompts the user for the git repo to be viewed
            [obj.rType,obj.gDirP,...
                            obj.gRepoDir,obj.gName] = promptGitRepo(); 
            if isempty(obj.rType)
                ok = false;
                return
            end            
            
            % updates the loadbar
            lStr = 'Initialising Git Class Objects...';
            obj.hProg = ProgressLoadbar(lStr);            

            % creates the menu items
            gitEnvVarFunc('add','GIT_DIR',obj.gRepoDir)
            obj.gfObj = GitFunc(obj.rType,obj.gDirP,obj.gName);
            brInfo = obj.gfObj.getBranchInfo(true);
            
            % creates/sets the gitignore file 
            createGitIgnoreFile(obj.gfObj);                        
            
            % if a developer, then ensure the local and remote repositories
            % match (NB - this is important for picking up hotfix branches)
            if obj.gfObj.uType == 0     
                % initialisations
                isMod = false;
                
                % ensures that the origin url has been set
                if isempty(obj.gfObj.gitCmd('get-origin'))
                    obj.gfObj.gitCmd('set-origin')
                end

                % fetches the remote repository (prunes any removed)
                obj.gfObj.gitCmd('fetch-origin-prune');                 
                
                % separates the branches into remote and local  
                [brL,brR,isR] = obj.splitBranchInfo(brInfo);                
                
                % retrieves the current branch
                cID0 = obj.gfObj.gitCmd('commit-id');
                cBrL = obj.gfObj.gitCmd('current-branch');
                if isempty(cBrL); cBrL = 'master'; end     
                
                % ensures all the local branches
                if ~isequal(brL,brR)
                    % determines if there are any modifications to the head
                    isMod = obj.detIfHeadModified;
                    if isMod
                        % if so, then stash the modifications
                        sStr = obj.gfObj.getStashBranchString(cBrL);
                        obj.gfObj.stashBranchFiles(sStr);
                    end                                  
                    
                    % adds on any local branches missing from remote
                    for i = 1:length(brR)
                        if ~any(strcmp(brL,brR{i}))
                            obj.gfObj.gitCmd('switch-branch',brR{i});
                        end
                    end
                    
                    % removes any local branches not in remote
                    for i = 1:length(brL)
                        if ~any(strcmp(brR,brL{i}))
                            obj.gfObj.gitCmd('delete-local',brL{i});
                        end
                    end
                    
                    % resets the head to the original point                    
                    if startsWith(cID0,brInfo{strcmp(brInfo(:,1),cBrL),2})
                        % case is the head of the branch
                        obj.gfObj.checkoutBranch('local',cBrL)
                    else
                        % case is a detached head
                        obj.gfObj.checkoutBranch('version',cID0)
                    end 
                    
                    % resets the branch information 
                    brInfo = obj.gfObj.getBranchInfo(true);
                    [~,~,isR] = obj.splitBranchInfo(brInfo);   
                end
                
                % determines if local branch heads match the remote. if not
                % then reset the branch heads
                [cIDL,cIDR] = deal(brInfo(~isR,2),brInfo(isR,2));
                if ~isequal(cIDL,cIDR)
                    % determines if there are any modifications to the head
                    isMod = obj.detIfHeadModified;
                    if isMod
                        % if so, then stash the modifications
                        sStr = obj.gfObj.getStashBranchString(cBrL);
                        obj.gfObj.stashBranchFiles(sStr);
                    end                          
                    
                    % resets the local branches (for those whose head
                    % doesn't match)
                    for i = 1:length(cIDL)
                        if ~strcmp(cIDL{i},cIDR{i})
                            obj.gfObj.matchRemoteBranch(brInfo{i,1});                            
                        end
                    end               
                    
                    % checks out the original branch
                    obj.gfObj.checkoutBranch('version',cID0)
                end
                
                % restores any stashed modifications
                if isMod
                    obj.gfObj.unstashBranchFiles(sStr); 
                end                
                
            else
                % if a user, then determine if the remote branch head is
                % the same as the current
                obj.gfObj.gitCmd('set-origin');
                obj.gfObj.gitCmd('fetch-origin-prune');  

                % retrieves the local/remote master commit IDs                
                cIDL = brInfo{strcmp(brInfo(:,1),'master'),2};
                cIDR = brInfo{strcmp(brInfo(:,1),'origin/master'),2};
                
                % determines if the local/remote branches are the same 
                if strcmp(cIDL,cIDR) 
                    % if so, then remove the origin url and exits
                    obj.gfObj.gitCmd('rmv-origin');
                    return
                end
                
                % determines if there are any local modifications
                isMod = obj.detIfHeadModified;
                if isMod
                    % if so, then stash the changes
                    sStr = obj.gfObj.getStashBranchString('master');
                    obj.gfObj.stashBranchFiles(sStr);
                end
                
                % resets the local branch to match the remote
                obj.gfObj.matchRemoteBranch('master');
                
                % resets the local head to the remote head and then
                % rechecks out the original local commit                
                obj.gfObj.checkoutBranch('version',cIDL)
                
                % if there were modifications, then unstash them
                if isMod
                    obj.gfObj.unstashBranchFiles(sStr);
                end
                
                % removes the origin url 
                obj.gfObj.gitCmd('rmv-origin');
            end            
            
        end
        
        % --- sets up the version difference objects
        function setupVersionDiffObjects(obj)

            % initialisations                        
            obj.nTab = length(obj.tStr);
            obj.hList = cell(obj.nTab,1);
            
            % sets the object positions
            hPanelF = obj.hGUI.panelFileSelect;
            tabPos = getTabPosVector(hPanelF,[5,5,-10,10]);
            lPos = [5,20,tabPos(3)-10,tabPos(4)-54];
            txtPos = [5,0,tabPos(3)-10,15];

            % creates a tab panel group
            obj.hTabDiff = createTabPanelGroup(hPanelF,1);
            set(obj.hTabDiff,'position',tabPos,'tag','hTabDiff')           

            % creates the tabs for each code difference type
            for i = 1:obj.nTab
                % creates a new tab panel
                hTabU = createNewTabPanel(obj.hTabDiff,1,...
                                      'title',obj.tStr{i},'UserData',i);

                % creates the new text labels
                txtStr = sprintf('0 Files %s Between Versions',obj.tStr{i});
                uicontrol('style','text','parent',hTabU,...
                          'HorizontalAlignment','left',...
                          'position',txtPos,'string',txtStr,...
                          'FontWeight','bold',...
                          'tag',[obj.tStr{i},'T'],...
                          'BackgroundColor',0.94*ones(1,3));    

                % creates a new listbox
                obj.hList{i} = uicontrol('style','listbox','parent',hTabU,...
                                  'position',lPos,'tag',obj.tStr{i});                  
                set(obj.hList{i},'Callback',@obj.selDiffItem)                         
            end     

            % retrieves the table group java object
            obj.jTab = findjobj(obj.hTabDiff);
            obj.jTab = obj.jTab(arrayfun(@(x)...
                        (strContains(class(x),'MJTabbedPane')),obj.jTab));

            % disables all the tabs for each group type
            arrayfun(@(x)(obj.jTab.setEnabledAt(x-1,0)),1:obj.nTab)
        
        end
        
        % --- groups the branch strings
        function groupBranchStrings(obj)

            % memory allocation
            nGrp = length(obj.bGrpType);
            obj.bStrGrp = cell(nGrp,1);
            
            % retrieves all local/remote branch strings
            bStrSp = obj.rObj.brData(:,1);
            iType = zeros(length(bStrSp),1);
            
            % determines which are the main branches (master or develop) 
            isMain = strcmp(bStrSp,'master');
            
            % determines the feature/hotfix branch types
            iType(isMain) = nGrp-1;
            for iGrp = 2:(nGrp-1)
                isOK = cellfun(@(x)(...
                            strContains(x,obj.bGrpType{iGrp})),bStrSp); 
                iType(isOK) = nGrp-iGrp;
            end
            
            % sets the branching string groups (based on type)
            for i = 1:nGrp
                obj.bStrGrp{i} = bStrSp((nGrp-iType) == i);
            end           
            
        end
        
        % --------------------------------- %
        % --- FIGURE CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- mouse movement callback function
        function mouseMove(obj,hObject,~)
            
            try
                % determines if the mouse is over the plot axes
                mPos = get(hObject,'CurrentPoint');                
                overAx = isOverAxesGit...
                                (mPos,obj.gObj.axPosX,obj.gObj.axPosY,5);
            catch
                % function failed, so try old version
                overAx = isOverAxes(mPos);
            end
            
            % updates the selection if over the axes
            if overAx
                % retrieves the current row location
                mPosAx = get(obj.gObj.hAx,'CurrentPoint');
                iRowHNw = ceil(mPosAx(1,2)/obj.gObj.txtHY);
                
                if obj.isMenuOpen               
                    % determines if there are any open context menu items
                    hMenu = findAxesHoverObjectsGit...
                                   (obj.hFig,{'tag','hMenu'},obj.hFig,7.5);                    
                    if ~isempty(hMenu)
                        % if the mouse is over the context menu, then 
                        % determine which text label being hovered over
                        hLbl = findAxesHoverObjectsGit...
                                        (obj.hFig,{'style','text'},hMenu);
                        if ~isempty(hLbl)         
                            % if the mouse is over a label, then retrieve 
                            % the label index
                            iSel = get(hLbl,'UserData');
                            if obj.cmObj.iSel ~= iSel
                                % if the selection has changed, then 
                                % de-select the highlighted menu item
                                if obj.cmObj.iSel > 0
                                    obj.cmObj.setMenuHighlight...
                                                        (obj.cmObj.iSel,0)
                                end

                                % updates the menu highlight
                                obj.cmObj.setMenuHighlight(iSel,1)                
                            end

                            % exits the function
                            return
                        end
                    else
                        % if no longer over the axes, close the menu
                        obj.isMenuOpen = false;
                        obj.cmObj.setVisibility(0);
                    end
                    
                else
                    % retrieves the currently selected/highlighted rows
                    iRowH0 = get(obj.gObj.hFillH,'UserData');
                    iRowS0 = get(obj.gObj.hFillS,'UserData');                

%                     % determines if the 
%                     if ~any([iRowH0,iRowS0] == iRowHNw)
                    % updates the fill object userdata                    
                    yData = (iRowHNw-1)*obj.gObj.txtHY+obj.gObj.yFill;
                    set(obj.gObj.hFillH,'UserData',iRowHNw,'YData',yData);
%                     end

                    % turns the object visibility on
                    setObjVisibility(obj.gObj.hFillH,iRowHNw ~= iRowS0)
                end
                
            else
                % turns the head fill object visibility on
                setObjVisibility(obj.gObj.hFillH,0)
                set(obj.gObj.hFillH,'UserData',NaN);
                
                % if no longer over the axes, close the menu                
                obj.isMenuOpen = false;
                obj.cmObj.setVisibility(0);
            end
            
            % if the menu highlight is still on, then remove it
            if obj.cmObj.iSel > 0
                obj.cmObj.setMenuHighlight(obj.cmObj.iSel,0)
            end            
            
        end        
        
        % --- mouse down callback function
        function mouseDown(obj,hObject,~)
            
            % if the mouse click isn't over the axes, then exit
            mPos = get(hObject,'CurrentPoint');
            if ~isOverAxes(mPos)
                return
            end
                
            % retrieves the mouse selection type
            closeMenu = true;
            sType = get(hObject,'SelectionType'); 
            iRowH0 = get(obj.gObj.hFillH,'UserData');                      
            
            % determines if the highlight patch is currently visible            
            if strcmp(get(obj.gObj.hFillH,'Visible'),'on')
                % calculates the new y-location of the selected patch
                yData = (iRowH0-1)*obj.gObj.txtHY+obj.gObj.yFill;
                
                % turns the selected object on
                set(obj.gObj.hFillS,'UserData',iRowH0,...
                                    'YData',yData,'Visible','on');
                           
                % updates the version difference information
                obj.updateCommitDiffInfo();
            end        
            
            % if right-clicking over the axes, then retrieves the 
            if strcmp(sType,'alt')
%                 % turns off any row selection 
%                 set(obj.gObj.hFillS,'UserData',NaN,'Visible','off'); 
                
                % updates the context menu strings
                if obj.updateContextMenu(iRowH0)  
                    % flag that the menu is now open
                    closeMenu = false;
                    obj.isMenuOpen = true;                    
                    
                    % updates the menu position        
                    obj.cmObj.updatePosition(mPos);
                    obj.cmObj.setVisibility(1)   
                    pause(0.01);
                end
                
            end
            
            % if the menu is open, then close it
            if closeMenu
                obj.cmObj.setVisibility(0)
                obj.isMenuOpen = false;
            end              
            
        end
        
        % ------------------------------- %
        % --- MENU CALLBACK FUNCTIONS --- %
        % ------------------------------- %          
        
        % --- callback function for clicking menuRefresh
        function menuRefreshCB(obj,~,~)
            
            % determines if there is a modification in the branch
            isMod0 = obj.rObj.isMod;
            obj.rObj.isMod = obj.detIfHeadModified();            
            if xor(isMod0,obj.rObj.isMod)
                % retrieves the head commit description
                [iBr,iCm] = obj.getCurrentHeadInfo(obj.rObj.headID);
                txtH = obj.rObj.gHist(iBr).brInfo.Desc{iCm};
                
                % if the branch is modified then add in the commit string
                if obj.rObj.isMod
                    txtH = sprintf('%s**',txtH);
                end
                
                % updates the head string
                hTxtH = findall(obj.gObj.hAx,'tag','hTxtDesc',...
                            'UserData',get(obj.gObj.hFillHd,'UserData'));
                set(hTxtH,'string',txtH);
            end
            
        end        
        
        % --- callback function for clicking menuResetHistory
        function menuResetHistoryCB(obj,hObject,~)
            
            % prompts the user if they wish to reset the history point
            qtStr = 'Confirm History Reset';
            qStr = ['Are you sure you want to reset the branch history ',... 
                    'tip to this point?'];
            uChoice = questdlg(qStr,qtStr,'Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % if the user cancelled, then exit the function
                return
            end
            
            % creates a loadbar
            h = ProgressLoadbar('Resetting History Point...');
            
            % retrieves the selected node commit ID
            [iBr,iCm] = obj.getCurrentHeadInfo();
            cIDNw = obj.rObj.gHist(iBr).brInfo.CID{iCm};
            
            % checks out the branch to the head
            cBr = obj.rObj.brData{iBr,1};
            obj.gfObj.checkoutBranch('local',cBr)
            
            % add/removes the directories that are different between the
            % commits and then hard resets the branch
            obj.gfObj.resetHistoryPoint(cIDNw);            
            
            % resets the GUI objects
            setObjEnable(hObject,0)
            obj.resetGUIObjects(h)            
            
            % closes the loadbar
            delete(h)
            
        end        
        
        % --- callback function for clicking menuRefLog
        function menuRefLogCB(obj,~,~)
            
            % runs the reference log GUI
            GitRefLog(obj);          
            
        end        
        
        % --- function called when there was a succesful update
        function postRefLogCB(obj)
            
            % creates a loadbar
            h = ProgressLoadbar('Updating Branch Graph...');

            % resets the GUI objects
            obj.resetGUIObjects(h)

            % deletes the loadbar
            delete(h)                 
            
        end
        
        % --- callback function for clicking menuBranchInfo
        function menuBranchInfoCB(obj,~,~)
            
            % runs the branch information GUI 
            GitBranchInfo(obj);            
            
        end  
                
        % --------------------------------------- %
        % --- CONTEXT MENU CALLBACK FUNCTIONS --- %
        % --------------------------------------- %          
        
        % --- context menu selection callback
        function menuSelect(obj,cmObj)
            
            % if a gap label string, then exit
            if strContains(cmObj.mStr{cmObj.iSel},'=')
                return
            end
            
            % closes the menu
            obj.isMenuOpen = false;
            obj.cmObj.setVisibility(0);
            
            % runs the callback function 
            switch cmObj.mStr{cmObj.iSel}
                case 'Create New Branch'
                    % case is creating a new branch (can occur at any node)
                    obj.createNewBranch();
                    
                case 'Rebase Branch Commits'
                    % case is rebasing the current commit
                    obj.rebaseBranchCommits();
                    
                case 'Commit Changes'
                    % case is committng changes (only for when the branch
                    % tip is currently selected)
                    obj.commitChanges();
                    
                case 'Merge Branches'
                    % case is branch merging (only for non-master branch
                    % nodes when selected at the branch tip)
                    obj.mergeBranches();
                    
                case 'Rebase Branch'
                    % case is branch rebasing (only when non-master branch
                    % tip nodes are selected)
                    obj.rebaseBranch();
                    
                case 'Rename Branch'
                    % case is branch renaming (only for when branch tip
                    % node is currently selected)
                    obj.renameBranch();
                    
                case 'Delete Branch'
                    % case is branch deletion (only for when branch tip
                    % node is currently selected)
                    obj.deleteBranch();                    
                    
                case 'Rename Commit' 
                    % case is branch renaming (can occur at any node)
                    obj.renameCommit();                    
                    
                case 'Create Hot-Fix'
                    % case is creating a hot fix branch (only for users
                    % when there are non-commited changes)
                    obj.createNewHotFixBranch();
                    
                case 'Ignore Local Changes'
                    % case is ignoring local changes (only for nodes where
                    % there has been modifications
                    obj.ignoreLocalChanges()

                case 'Stash Local Changes'
                    % case is ignoring local changes (only for nodes where
                    % there has been modifications                    
                    obj.stashLocalChanges()
                    
                case 'Delete Head Commit'
                    % case is removing the head commit
                    obj.removeHeadCommit()
            end            
        end
        
        % --- creates a new hot fix branch
        function createNewHotFixBranch(obj)
            
            % prompts the user for the branch creation information
            iDataHF = GitHotfix(obj);
            if isempty(iDataHF)
                % user cancelled or there was an error
                return
            end 
            
            % ----------------------- %
            % --- BRANCH CREATION --- %
            % ----------------------- %            
                        
            % creates the load bar
            h = ProgressLoadbar('Creating New Remote Branch...'); 
            
            % determines the current and merging branches
            [iBr,iCm] = obj.getCurrentHeadInfo();
            [~,cID] = obj.getSelectedCommitInfo();
            
            % retrieves the current/new branch names
            cBr = obj.rObj.brData{iBr,1};
            nwBr = obj.getBranchNameString(iDataHF);
            
            % if the there are changes on the current branch then 
            % stash the changes
            sStr = obj.gfObj.getStashBranchString(cBr);
            obj.gfObj.stashBranchFiles(sStr);            
            
            % sets the commit message/user name string
            mS = sprintf('%s (User: "%s")',iDataHF.cMsg,iDataHF.uName);                         
            
            % creates the local/remote branches
            obj.gfObj.gitCmd('create-local-detached',nwBr,cID)
            obj.createNewRemoteBranch(cBr,nwBr)    
            obj.gfObj.gitCmd('stash-apply')
            
            % commits the latest changes to the branch
            cStatus = strsplit(obj.gfObj.gitCmd('commit-all',mS),'\n');
            if any(strContains(cStatus,'git commit --amend --reset-author'))
                % if there is ambiguity about the user information, then
                % prompt the user for their info and reset
                uInfo = GitUserInfo(cStatus);
                
                % updates the user information and reset the commit author
                fType = 'set-global-config';
                obj.gfObj.gitCmd(fType,'user.name',['"',uInfo.Name,'"'])
                obj.gfObj.gitCmd(fType,'user.email',uInfo.Email)
            end            
            
            % pushes the changes to the remote branch
            h.StatusMessage = 'Force pushing changes to remote...';
            obj.gfObj.gitCmd('force-push-commit',nwBr);            
            
            % checks out the branch (depending on the branch index)
            if iCm == 1
                % if the latest commit, then checkout the branch                    
                obj.gfObj.checkoutBranch('local',cBr)

            else
                % otherwise, checkout the version from the commit ID
                obj.gfObj.checkoutBranch('version',cID)
            end            
            
            % removes the origin url (non-developers only)
            h.StatusMessage = 'Cleaning up local repository...';
            obj.gfObj.gitCmd('delete-local',nwBr)
            obj.gfObj.gitCmd('rmv-origin')           
            
            % unstashes the files (if required)
            if obj.rObj.isMod
                obj.gfObj.unstashBranchFiles(sStr);
            end            
            
            % closes the loadbar
            delete(h)
            
            
%             % sets the new branch/commit strings    
%             cBr = obj.GitFunc.getCurrentBranch();
%             nwBr = obj.getBranchNameString(iData);      
%             obj.appendStructHistory(nwBr);  
%             
%             % sets the commit message/user name string
%             mS = sprintf('%s (User: "%s")',iData.cMsg,iData.uName); 
%             
%             % stashes the current changes
%             isStashed = obj.GitFunc.detIfBranchModified();
%             if isStashed; obj.GitFunc.gitCmd('stash'); end
%             
%             % creates the local/remote branches
%             obj.GitFunc.gitCmd('create-local-detached',nwBr)
%             obj.createNewRemoteBranch(nwBr,nwBr)
%             
%             % checks out the remote branch and commits the stashed changes
%             h.StatusMessage = 'Pushing Changes To Remote Branch';
%             obj.GitFunc.gitCmd('stash-apply')
%             
%             % commits the latest changes to the branch
%             cStatus = strsplit(obj.GitFunc.gitCmd('commit-all',mS),'\n');
%             if any(strContains(cStatus,'git commit --amend --reset-author'))
%                 % if there is ambiguity about the user information, then
%                 % prompt the user for their info and reset
%                 uInfo = GitUserInfo(cStatus);
%                 
%                 % updates the user information and reset the commit author
%                 fType = 'set-global-config';
%                 obj.GitFunc.gitCmd(fType,'user.name',['"',uInfo.Name,'"'])
%                 obj.GitFunc.gitCmd(fType,'user.email',uInfo.Email)
%             end            
%             
%             % pushes the changes to the remote branch
%             obj.GitFunc.gitCmd('force-push-commit',nwBr);
%             
%             % checks out the original branch and pops the stashed changes
%             obj.checkoutBranch('local',cBr)
%             if isStashed; obj.GitFunc.gitCmd('stash-pop'); end
%             
%             % removes the origin url (non-developers only)
%             if obj.GitFunc.uType > 0
%                 obj.GitFunc.gitCmd('delete-local',nwBr)
%                 obj.GitFunc.gitCmd('rmv-origin')
%             end            
            
        end
        
        % --- function which creates a new repo branch
        function createNewBranch(obj,iDataB)
            
            % retrieves the branch creation data struct (if not provided)
            if ~exist('iDataB','var')
                iDataB = GitCreate(obj);            
                if isempty(iDataB)
                    % user cancelled or there was an error
                    return
                end
            end
            
            % ----------------------- %
            % --- BRANCH CREATION --- %
            % ----------------------- %            
                        
            % creates the load bar
            h = ProgressLoadbar('Creating New Branch...');             
            
            % if the there are changes on the current branch then 
            % stash the changes           
            if obj.rObj.isMod
                cBr = obj.gfObj.gitCmd('current-branch');
                sStr = obj.gfObj.getStashBranchString(cBr);
                obj.gfObj.stashBranchFiles(sStr);
            end                                    
            
            % sets the new branch/commit strings                 
            nwBr = obj.getBranchNameString(iDataB);
            isDetached = obj.isHeadDetached(0);
            
            % sets the commit message string
            mS = sprintf('1st Commit (Branched from ''%s'')',iDataB.pBr);
            
            % creates the new local/remote branches            
            obj.createNewRemoteBranch(iDataB.pBr,nwBr)            
            if isDetached
                %
                [~,cIDS] = obj.getSelectedCommitInfo();
                
                % creates the new branch, adds the altered files and
                % creates the first commit
                obj.gfObj.gitCmd('create-local-detached',nwBr,cIDS);
                obj.gfObj.gitCmd('general','add -u');
                obj.gfObj.gitCmd('commit-empty',mS);
                
            else
                % stashes any modified files
                obj.gfObj.stashBranchFiles() 
                
                % otherwise, create a new branch with an empty commit
                obj.gfObj.gitCmd('create-local',nwBr)
                obj.gfObj.gitCmd('commit-empty',mS);
            end
            
            % creates a new commit and forces pushes to the branch
            obj.gfObj.gitCmd('push-set-upstream',nwBr)
            obj.gfObj.gitCmd('force-push');
            
            % deletes the progressbar and exits (non-developer only)            
            if obj.gfObj.uType > 0
                % checks out the master branch again
                obj.gfObj.gitCmd('checkout-local','master');
                obj.gfObj.gitCmd('delete-local',nwBr);
                obj.gfObj.gitCmd('rmv-origin');                             
            end    
            
            % unstashes the files (if required)
            if obj.rObj.isMod
                obj.gfObj.unstashBranchFiles(sStr);
            end
            
            % resets the GUI objects
            obj.resetGUIObjects(h)            
            
            % deletes the progressbar and exits the function
            delete(h)            
            
        end
       
        % --- functon that rebases the commits for a given branch
        function rebaseBranchCommits(obj)
            
            % runs the commit rebase GUI
            GitRebase(obj.hFig);
            
        end
        
        % --- function which commits the current branch modifications
        function commitChanges(obj)
            
            % runs the Git Commit gui
            hFigComm = GitCommit(obj.hFig,obj.gfObj);
            setappdata(hFigComm,'postCommitFcn',@obj.postCommitFcn)
            
        end        

        % --- function which creates a new repo branch
        function mergeBranches(obj)
            
            % if there are uncommited changes, then output an error to
            % screen and exit the function            
            if obj.gfObj.detIfBranchModified()
                eStr = sprintf(['Unable to merge as there are ',...
                                'uncommitted changes on this branch.\n',...
                                'Commit the changes before re-',...
                                'attempting to merge.']);
                waitfor(errordlg(eStr,'Branch Merge Failed','modal'))
                return
            end
            
            % determines the current and merging branches
            iBr = obj.getCurrentHeadInfo();
            cBr = obj.rObj.brData{iBr,1};
            mBr = obj.rObj.gHist(iBr).pName;
            [~,cIDS] = obj.getSelectedCommitInfo();
            
            % prompts user if they want to delete branch after merge
            qtStr = 'Delete Branch After Merge?';
            qStr = sprintf(['Do you want to delete the branch "%s" ',...
                            'after merging?'],cBr);
            uChoice = questdlg(qStr,qtStr,'Yes','No','Yes');
            deleteBranch = strcmp(uChoice,'Yes');
            
            % determines if there were any merged/conflicted files  
            obj.gfObj.checkoutBranch('local',mBr)
            obj.gfObj.gitCmd('merge-no-commit',cBr);    
            
            % determines if there are any merge conflict/differences
            dcFiles = obj.gfObj.getMergeDCFiles(); 
            hasDiff = ~isempty(dcFiles.Diff);
            hasConf = ~isempty(dcFiles.Conflict);
            
            % determines if there are any merge conflicts/differences
            % between the merged/original branches
            if hasConf || hasDiff
                % if so, then prompt the user to resolve these
                if ~hasConf
                    % only differences between versions
                    mStr0 = 'Differences';
                elseif ~hasDiff
                    % only merge conflicts between versions
                    mStr0 = 'Merge conflicts';                    
                else
                    % both merge conflicts and differences
                    mStr0 = 'Merge conflicts and differences';                    
                end
                
                % outputs a message to screen indicating a merge is reqd
                mStr = sprintf(['%s exist between the branches.\n',...
                                'You will need to resolve these before ',...
                                'completing the final merge.'],mStr0);
                waitfor(msgbox(mStr,'Merge Conflict/Differences','modal'))       
                
                % if so, then prompt the user to manually alter the files 
                % until either they cancel or successfully merged      
                setObjVisibility(obj.hFig,0)
                isCont = GitMerge(obj,dcFiles,mBr,cBr);  
                setObjVisibility(obj.hFig,1)                
                                
                if isCont
                    % case is the user updates the merge files
                    for i = 1:length(dcFiles.Diff)
                        % sets the full file name
                        if isempty(dcFiles.Diff(i).Path)
                            dFile = dcFiles.Diff(i).Name;
                        else
                            dFile = sprintf('%s/%s',dcFiles.Diff(i).Path,...
                                                    dcFiles.Diff(i).Name);
                        end
                        
                        % re-adds the file 
                        obj.gfObj.gitCmd('add-file',dFile);
                    end
                else
                    % if the user aborted the merge, then revert back to
                    % the original branch and exit the function   
                    obj.gfObj.gitCmd('abort-merge')
                    obj.gfObj.checkoutBranch('local',cBr)
                    return
                end
            end
                
            % creates a loadbar
            h = ProgressLoadbar('Completing Branch Merge...'); 

            % if the user successfully merged all files, then finish  
            % the merge process 
            cMsg = sprintf('Merging from "%s" (%s)',cBr,cIDS);
            obj.gfObj.gitCmd('commit-simple',cMsg);  
            obj.gfObj.gitCmd('force-push',1);

            % deletes the original branch (if required)
            if deleteBranch
                h.StatusMessage = 'Deleting Branch From Respository...';
                obj.deleteBranch(cIDS,h);
            end

            % resets the GUI objects
            obj.resetGUIObjects(h)
            
            % deletes the loadbar
            delete(h)                            
            
        end
        
        % --- function which creates a new repo branch
        function rebaseBranch(obj)
            
            waitfor(msgbox('Finish Me! (Rebase Branch)','modal'))
            
        end
        
        % --- function which creates a new repo branch
        function renameCommit(obj)
            
            % retrieves the text object corresponding to the selected row
            [iSel,cIDS,iSelS] = obj.getSelectedCommitInfo();
            [iBr,iCm] = obj.getCurrentHeadInfo(cIDS);
            hTxtD = findall(obj.gObj.hAx,'UserData',iSel,'tag','hTxtDesc');
            txtD0 = get(hTxtD,'String');
            
            % removes any modification markers
            if endsWith(txtD0,'**')
                txtD0 = txtD0(1:end-2);
            end
            
            % prompts the user for the new commit name
            pStr = {'Enter the new commit description:'};
            titleStr = 'New Commit Description';
            txtDNw = inputdlg(pStr,titleStr,[1,100],{txtD0});
            
            % if the user cancelled, then exit
            if isempty(txtDNw) || isequal(txtD0,txtDNw{1})
                % if the user cancelled, or there is no change, then exit
                return
            end
            
            % creates the loadbar
            h = ProgressLoadbar('Resetting Commit Message...'); 
            
            % update commit message in the repo
            cBr = obj.rObj.brData{iBr,1};
            obj.gfObj.resetCommitMessage(txtD0,txtDNw{1},cBr,iCm);
            
            % force pushes to the remote repository
            pushMsg = obj.gfObj.gitCmd('force-push',1);
            if strContains(pushMsg,'Could not read from remote repository')
                obj.gfObj.gitCmd('set-origin')
                obj.gfObj.gitCmd('force-push',1)
            end
            
            
            % resets the GUI objects
            obj.resetGUIObjects(h)
            
            % closes the loadbar
            delete(h)
            
        end        
                
        % --- function which re-names the current 
        function renameBranch(obj)
            
            % retrieves the text object corresponding to the selected row
            [iSel,cIDS] = obj.getSelectedCommitInfo();
            iBr = obj.getCurrentHeadInfo(cIDS);
            
            % retrieves the branch text object
            hTxtBr = findall(obj.gObj.hAx,'UserData',iBr,'tag','hTxtBr');
            txtBr0 = strip(get(hTxtBr,'String'));
            
            % prompts the user for the new commit name
            pStr = {'Enter the new branch name:'};
            titleStr = 'New Branch Name';
            txtBrNw = inputdlg(pStr,titleStr,[1,50],{txtBr0});
            
            % determine if the new branch name is unique and valid
            if isempty(txtBrNw) || isequal(txtBr0,txtBrNw{1})
                % if the user cancelled, then exit
                return
                
            elseif ~obj.checkBranchName(txtBrNw{1})
                % if the branch name is invalid, then exit
                return                
            end
            
            % creates the loadbar
            h = ProgressLoadbar('Resetting Branch Name...');             
            
            % retrieves the description text object
            hTxtD = findall(obj.gObj.hAx,'UserData',iSel,'tag','hTxtDesc');            
            
            % update description in repo
            obj.gfObj.gitCmd('reset-branch-name',txtBrNw{1});
            obj.gfObj.gitCmd('force-push',txtBrNw{1}); 
            
            % update description in repository structure data struct
            obj.rObj.brData{iBr,1} = txtBrNw{1};
            obj.rObj.gHist(iBr).brName = txtBrNw{1};
            
            % updates the history data structs
            pName0 = field2cell(obj.rObj.gHist,'pName');
            for i = find(strcmp(pName0,txtBr0)')
                obj.rObj.gHist(i).pName = txtBrNw{1};
            end
            
            % update text object and the corresponding 
            set(hTxtBr,'String',sprintf(' %s ',txtBrNw{1}));            
            pPosBr = get(hTxtBr,'Extent');
            xDesc = sum(pPosBr([1,3]))+obj.gObj.dxTxt;            
            
            % determines if this is a repo head
            if strcmp(obj.rObj.headID,cIDS)
                % if this is the repo head, then move this object
                xDesc = sum(pPosBr([1,3]))+obj.gObj.dxTxt;
                hTxtH = findall(obj.gObj.hAx,'tag','hTxtHead');
                resetObjPos(hTxtH,'Left',xDesc);
                
                % recalculates the x-location of the description
                pPosH = get(hTxtH,'Extent');
                xDesc = sum(pPosH([1,3]))+obj.gObj.dxTxt;
            end
            
            % resets the description text object position
            resetObjPos(hTxtD,'Left',xDesc);
                       
            % resets the graph axes dimensions
            obj.gObj.resetAxesDimensions();
            
            % closes the loadbar
            delete(h)            
            
        end                
        
        % --- function which deletes a branch
        function deleteBranch(obj,cIDS,h)
                
            % retrieves the commit ID (if not provided)
            if ~exist('cIDS','var')
                % case is calling the function directly
                directCall = true;
                [~,cIDS] = obj.getSelectedCommitInfo();
            else
                % case is calling the function indirectly
                directCall = false;
            end
            
            % retrieves the branch deletion name
            iBrD = obj.getCurrentHeadInfo(cIDS);
            delBr = obj.rObj.brData{iBrD,1};            
            
            % retrieves the text object corresponding to the selected row
            if directCall
                % prompts the user if they want to delete the branch
                qtStr = 'Confirm Branch Deletion';
                qStr = sprintf(['Are you sure you want to delete the ',...
                                '"%s" branch?'],delBr);
                uChoice = questdlg(qStr,qtStr,'Yes','No','Yes');
                if ~strcmp(uChoice,'Yes')
                    % if the user cancelled, then exit the function
                    return
                end
                
                % creates the loadbar
                h = ProgressLoadbar('Deleting Branch From Respository...');                 
            end
                
            % ----------------------- %
            % --- BRANCH DELETION --- %
            % ----------------------- %                        
            
            % retrieves the current branch string
            if directCall
                iBrH = obj.getCurrentHeadInfo();
                cBrH = obj.rObj.brData{iBrH,1};    
            else
                cBrH = obj.gfObj.gitCmd('current-branch');
            end
            
            % stashes any changes
            if obj.rObj.isMod; obj.gfObj.gitCmd('stash'); end
            
            % sets the message for the deletion branch (combines the
            % deleted branch name with the last commit ID# - this is used
            % to determine deleted branches from reflog)
            pID = obj.rObj.gHist(iBrD).brInfo.CID{1};
            cMsg = sprintf('Branch Delete ("%s" - %s)',delBr,pID);            
            
            % determines if there are any merges on this branch
            mCID = obj.rObj.gHist(iBrD).brInfo.mCID;
            hasMerge = any(~cellfun(@isempty,mCID));
            
            % adds an empty commit to the deleted branch and then returns
            % to the current branch
            obj.gfObj.gitCmd('checkout-local',delBr);
            obj.gfObj.gitCmd('commit-empty',cMsg);  
            
            % returns to the current branch
            obj.gfObj.gitCmd('checkout-local',cBrH);
            if obj.rObj.isMod; obj.gfObj.gitCmd('stash-pop'); end
            
            % deletes the local/remote branches 
            obj.gfObj.removeStashedFiles(delBr)                
            obj.gfObj.gitCmd('delete-local',delBr,hasMerge)
            obj.gfObj.gitCmd('delete-remote',delBr)                                              

            % resets the GUI objects
            obj.resetGUIObjects(h)
            
            % deletes the loadbar (if called directly)
            if directCall; delete(h); end              
            
        end
        
        % --- function which creates a new repo branch
        function ignoreLocalChanges(obj)
            
            % prompts the user if they want to delete the branch
            qtStr = 'Confirm Ignoring Modifications';
            qStr = sprintf(['Are you sure you want to ignore the ',...
                            'local modifications?']);
            uChoice = questdlg(qStr,qtStr,'Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % if the user cancelled, then exit the function
                return
            end
            
            % creates the loadbar
            h = ProgressLoadbar('Deleting Branch From Respository...'); 
            
            % resets the head to the original state
            obj.rObj.isMod = false;
            [iSel,cIDS] = obj.getSelectedCommitInfo();
            obj.gfObj.gitCmd('force-checkout',cIDS);
            
            % removes the modification marker from the commit string
            hTxtD = findall(obj.gObj.hAx,'UserData',iSel,'tag','hTxtDesc');
            txtD = get(hTxtD,'String'); 
            set(hTxtD,'String',txtD(1:end-2));
            
            % closes the loadbar
            try; close(h); end
            
        end
        
        % --- function which stashes local changes
        function stashLocalChanges(obj)
            
            waitfor(msgbox('Finish Me! (Stash Local Changes)','modal'))
            
        end    
        
        % --- removes the head commit
        function removeHeadCommit(obj)
            
            % confirms the user wants to reset to the detached point
            qtStr = 'Reset Current Branch?';
            qStr = sprintf(['Are you certain you want to delete the ',...
                            'current head branch point?']);
            uChoice = questdlg(qStr,qtStr,'Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % if the user did not confirm then exit the function
                return
            end        
            
            % creates the loadbar
            h = ProgressLoadbar('Deleting Branch Head Commit...');            
            
            % retrieves the selected node commit ID
            iBr = obj.getCurrentHeadInfo();
            cIDNw = obj.rObj.gHist(iBr).brInfo.CID{2};
            
            % add/removes the directories that are different between the
            % commits and then hard resets the branch
            obj.gfObj.resetHistoryPoint(cIDNw);
                                    
            % resets the GUI objects
            obj.resetGUIObjects(h)
            set(obj.hGUI.radioAllVer,'value',1)  
            
            % deletes the loadbar
            delete(h)                    
            
        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %  
        
        % --- callback function for editting editVerCount
        function editVerCountCB(obj,hObject,~)
            
            % determines if the new value is valid
            nwVal = str2double(get(hObject,'string')); 
            if chkEditValue(nwVal,[1,obj.nHist0],1)
                % if the new value is valid, then update the data struct
                obj.iData.nHist = nwVal;

                % enables the update filter button
                setObjEnable(obj.hGUI.buttonUpdateFilt,1)
            else
                % otherwise, revert back to the last valid value
                set(hObject,'string',num2str(obj.iData.nHist))
            end            
            
        end
        
        % --- callback function for clicking buttonUpdateFilt
        function buttonUpdateFiltCB(obj,hObject,~)
        
            % resets the progressbar
            h = ProgressLoadbar('Updating Version History...');
            
            % resets the gui objects
            obj.resetGUIObjects(h);
            setObjEnable(hObject,0)
            
            % deletes the loadbar
            delete(h);

        end
        
        % --- callback function for clicking buttonUpdateVer
        function buttonUpdateVerCB(obj,hObject,~)
            
            % creates the load bar
            h = ProgressLoadbar('Updating Branch Version...');              
            
            % initialisations
            iBr0 = obj.getCurrentHeadInfo(); 
            [~,cIDS,~] = obj.getSelectedCommitInfo();
            
            % sets the current directory to the repository directory 
            cDir0 = pwd;
            cd(obj.gDirP);                                    
            
            % determines if the user wants to keep any branch modifications
            % (if any modifications exist)
            uStatus = obj.checkCommitModifications(h);
            switch uStatus
                case 1
                    % if the user chose to cancel, then exit the function
                    cd(cDir0)
                    return
                    
                case 2
                    % case is the user chose to ignore changes
                    obj.gfObj.gitCmd('force-checkout',cIDS);
                    
            end
            
            % determines the currently selected commit            
            [iBr,iCm] = obj.getCurrentHeadInfo(cIDS);
            brNameNw = obj.rObj.brData{iBr,1};
            
            if obj.gfObj.uType == 0
                % checks out the branch (depending on the branch index)
                if iCm == 1
                    % if the latest commit, then checkout the branch                    
                    obj.gfObj.checkoutBranch('local',brNameNw)

                else
                    % otherwise, checkout the version from the commit ID
                    obj.gfObj.checkoutBranch('version',cIDS)
                end
            else
                % determines if the current/new branch will differ                               
                if iBr ~= iBr0
                    % if so, then stash any changes
                    obj.gfObj.gitCmd('stash-save','dummy');   
                end
                
                % checks out the branch (depending on the branch index)
                if iCm == 1   
                    % if the latest commit, then checkout the branch  
                    obj.gfObj.gitCmd('checkout-local',brNameNw);
                else
                    % otherwise, checkout the version from the commit ID
                    obj.gfObj.checkoutBranch('version',cIDS)            
                end
                
                % removes the item from the list
                if iBr ~= iBr0
                    iList = obj.gfObj.detStashListIndex('dummy');
                    if ~isempty(iList)
                        obj.gfObj.gitCmd('stash-drop',iList-1)
                    end
                end
            end
                     
            % updates the new head ID information
            obj.rObj.headID = cIDS;
            obj.gObj.resetHeadMarker(iBr,iCm);
            setObjEnable(obj.hGUI.menuResetHistory,iCm>1)
            
            % updates the repository information
            updateRepoInfo(obj.gName);
            
            % updates the version/commit difference info            
            obj.updateVersionInfo();
            obj.clearCodeInfo();
            setObjEnable(hObject,0); 
            
            %
            set(obj.gObj.hFillS,'UserData',NaN,'Visible','off');
            obj.updateCommitDiffInfo()
            
            % changes the directory back to the original
            cd(cDir0)

            % closes the loadbar
            try; delete(h); end
            
        end        
        
        % --- callback function for selecting the code difference list
        function selDiffItem(obj,hObject,~)

            % retrieves the 
            handles = obj.hGUI;
            iSelC = get(hObject,'value');     
            hStr = {'Line #','Line #','Code'};
            pCol = {[1.0,1.0,1.0],[0.9,0.7,0.7],[0.7,0.9,0.7]}; 
            
            % if there is no selection, then clear the code info and exits
            if isempty(iSelC)
                obj.clearCodeInfo()
                return
            end
            
            % retrieves the difference struct
            tStr0 = get(hObject,'tag');
            iTab = get(get(obj.hTabDiff,'SelectedTab'),'UserData');
            pDiff0 = obj.pDiff{obj.indD(1),obj.indD(2)};
            pDiffS = getStructField(pDiff0,tStr0);
            pDiffC = pDiffS(iSelC);
            
            % determines the head/selected commit ID's
            cIDH = obj.rObj.headID;
            [~,cIDS] = obj.getSelectedCommitInfo();
            
            % case is a text file is selected
            set(handles.tableCodeLine,'enable','on','columnname',hStr)      
          
            % retrieves/determines the code block difference information
            if isempty(obj.cBlk{iTab}{iSelC})
                % creates a loadbar
                h = ProgressLoadbar('Determining Code Difference...');

                % retrieves the code difference block 
                fFile = fullfile(pDiffC.Path,pDiffC.Name);
                dStr = obj.gfObj.gitCmd('diff-file',cIDS,cIDH,fFile);
                cBlkNw = obj.splitCodeDiff(dStr);
                obj.cBlk{iTab}{iSelC} = cBlkNw;

                % deletes the loadbar
                try; delete(h); end
            else
                % retrieve the code block (if it exists)
                cBlkNw = obj.cBlk{iTab}{iSelC};
            end
                                  
            % sets the file path string
            if isempty(pDiffC.Path)
                pStr = fullfile('.',pDiffC.Name);    
            else
                pStr = fullfile('.',pDiffC.Path,pDiffC.Name);
            end
            
            % updates the file path
            set(handles.textFilePath,'string',pStr)
            setPanelProps(handles.panelCodeDiff,1)

            % updates the code data
            if isempty(cBlkNw)
                % case is a binary file is selected
                DataNw = {'','','Binary File Selected...'};
                set(handles.tableCodeLine,'data',DataNw,'enable','off')                       
            else    
                % initialisations
                [tData,bCol] = deal([]);
                for i = 1:length(cBlkNw)
                    % sets the code block header and block data
                    cHdr = sprintf('CODE BLOCK #%i',i);
                    hStr = {setHTMLColourString('b','####',1),...
                            setHTMLColourString('b','####',1),...
                            setHTMLColourString('b',cHdr,1)};                      

                    % retrieves the code block
                    tDataNw = [hStr;[cBlkNw(i).iLine,cBlkNw(i).Code]];
                    bColNw = num2cell([0;cBlkNw(i).Type]);

                    % inserts a gap for multiple code blocks
                    if i > 1 
                        tDataNw = [{'','',''};tDataNw]; 
                        bColNw = [{0};bColNw];
                    end        

                    % updates the total data
                    [tData,bCol] = deal([tData;tDataNw],[bCol;bColNw]);
                end

                % case is a text file is selected
                bColFin = cell2mat(cellfun(@(x)(pCol{x+1}),bCol,'un',0));
                set(handles.tableCodeLine,'data',tData,'visible','on');       
                autoResizeTableColumns(handles.tableCodeLine)
                set(handles.tableCodeLine,'backgroundcolor',bColFin)
            end

        end    
        
        % --- callback function for altering the code difference tabs
        function changeDiffTab(obj,hObject,~)

            % updates the selection
            iTab = get(get(hObject,'SelectedTab'),'UserData');
            obj.selDiffItem(obj.hList{iTab},[])

        end
        
        % --- updates the data filter
        function updateDateFilter(obj,hObject,~)

            % initialisations
            iData0 = obj.iData;
            iSel = get(hObject,'value');            
            [dStr,abStr] = deal({'Day','Month','Year'},{'After','Before'});

            % determines the type
            [isBF,dType] = obj.getSelectedPopupType(hObject);
            
            % updates the date struct field
            iSelF = iSel+(dType==3)*obj.iData.y0;
            obj.setDateValue(dStr{dType},iSelF,isBF)            

            % determines if the new date is feasible
            if ~obj.feasDateFilter(obj.iData)
                % if not, then output an error to screen
                eStr = ['Error! The filter date must be ',...
                        'later than current date.'];
                waitfor(errordlg(eStr,'Date Filter Error','modal'))

                % resets the popup menu value to the last feasible value
                pStr = sprintf('d%i.%s',isBF,dStr{dType});                
                iSelPr = getStructField(iData0,pStr);
                set(hObject,'value',iSelPr-(dType==3)*obj.iData.y0)

                % exits the function
                return
            end

            % enables the update filter button
            setObjEnable(obj.hGUI.buttonUpdateFilt,1)

            % determines if the current date object is a month popup box
            if dType == 2
                % if so, then retrieve the maximum data count
                dN = getStructField(obj.iData,sprintf('d%i',isBF));
                dMax = obj.getDayCount(dN.Month);

                % retrieves the corresponding day popupmenu object handle
                hStr = sprintf('popup%sDay',abStr{1+isBF});
                hListDay = getStructField(obj.hGUI,hStr);

                % determines if the selected day index exceeds the count
                iSelD = get(hListDay,'value');
                if iSelD > dMax
                    % if so, then 
                    iSelD = dMax;
                    
                    % updates the struct fields
                    obj.setDateValue('Day',iSelD,isBF);
                end

                % determines if the max day count matches the current count
                if length(get(hListDay,'String')) ~= dMax
                    % updates the 
                    pStr = arrayfun(@num2str,1:dMax,'un',0)';
                    set(hListDay,'string',pStr,'value',iSelD)
                end
            end

        end             
        
        % -------------------------------------------------- %
        % --- OBJECT SELECTION CHANGE CALLBACK FUNCTIONS --- %
        % -------------------------------------------------- %          
        
        % --- callback function for selection change in panelVerFilt
        function panelVerFiltSC(obj,hObject,eventdata)
            
            % initialisations
            [pStr,eStr] = deal('off');

            % sets the handle of the currently selected radio button
            if ischar(eventdata)
                hRadioSel = hObject.SelectedObject;
            else
                hRadioSel = eventdata.NewValue;
            end

            % updates the parameters based on the selection type
            switch get(hRadioSel,'tag')
                case ('radioLastVer')
                    eStr = 'on';
                case ('radioDateFilt')
                    pStr = 'on';
            end

            % updates the other properties
            setObjEnable(obj.hGUI.editVerCount,eStr)
            setPanelProps(obj.hGUI.panelFiltDate,pStr)

            % enables the update filter button
            setObjEnable(obj.hGUI.buttonUpdateFilt,~ischar(eventdata))            

        end        
        
        % ------------------------------------------ %        
        % --- INFORMATION FIELD UPDATE FUNCTIONS --- %
        % ------------------------------------------ %
        
        % --- updates the current version information
        function updateVersionInfo(obj)
            
            % initialisations
            sStr = {'','s'};
            handles = obj.hGUI;
            
            % retrieves the history field for the current branch
            indM = arrayfun(@(x)(find(strcmp(x.brInfo.CID,....
                                obj.rObj.headID))),obj.rObj.gHist,'un',0);
            indBr = ~cellfun(@isempty,indM);
            gHist = obj.rObj.gHist(indBr);
            
            % sets the version string
            iVer = indM{indBr};
            if iVer == 1
                % flags that the commit is at the branch head
                [verStr,txtCol] = deal('Version At Branch Head','k');
            else
                % sets the number of versions behind the current
                txtCol = 'r';
                verStr = sprintf('%i Commit%s Behind Branch Head',...
                                                iVer-1,sStr{1+(iVer>2)});
            end
            
            % sets the information fields
            set(handles.textCurrBranch,'string',gHist.brName)
            set(handles.textVerStatus,'string',verStr,...
                                      'ForegroundColor',txtCol)
            set(handles.textVerDate,'string',gHist.brInfo.Date{iVer})
            set(handles.textVerComment,'string',gHist.brInfo.Desc{iVer})
            
        end
        
        % --- updates the commit difference information
        function updateCommitDiffInfo(obj)
            
            % sets the input arguments
            [iSelS,cIDS] = obj.getSelectedCommitInfo();
            
            % if there is no selected item, then resets the gui and exit            
            if isnan(iSelS)
                obj.clearVersionInfo();
                return
            end            
                            
            % retrieves the commit ID of the selected line
            obj.indD = [obj.gObj.headInd,iSelS];
            if range(obj.indD) == 0
                getDiffData = false;
            else
                getDiffData = isempty(obj.pDiff{obj.indD(1),obj.indD(2)});
            end
            
            % retrieves/sets up the commit difference struct
            if getDiffData
                % creates a loadbar
                lStr = 'Determining Version Code Differences...';
                h = ProgressLoadbar(lStr);

                % determines the difference between selected/head commits
                cIDH = obj.rObj.headID;
                dStr = obj.gfObj.gitCmd('diff-status',cIDS,cIDH);
                pDiffNw = splitDiffStatus(dStr,obj.tStr,0);  
                obj.pDiff{obj.gObj.headInd,iSelS} = pDiffNw;
                
                % deletes the progress loadbar
                try; delete(h); end                    
            else
                % if the struct exists, then extract it from the array
                pDiffNw = obj.pDiff{obj.gObj.headInd,iSelS};
            end                    
            
            % enables the properties
            setPanelProps(obj.hGUI.panelFileSelect,'on')
            setObjEnable(obj.hGUI.buttonUpdateVer,'on')
            obj.clearCodeInfo();
            
            % resets the code block information 
            if ~isempty(pDiffNw)
                nBlk = cellfun(@(x)(length...
                        (getStructField(pDiffNw,x))),fieldnames(pDiffNw));
                obj.cBlk = arrayfun(@(x)(cell(x,1)),nBlk,'un',0);
                    
                % updates the difference objects           
                updateDiffObjects(obj.hGUI,obj.jTab,pDiffNw)
            else
                % clears the version information
                obj.clearVersionInfo();                
            end
            
        end
        
        % --- clears the version information fields
        function clearVersionInfo(obj)
            
            % disables all the tabs for each group type
            arrayfun(@(x)(obj.jTab.setEnabledAt(x-1,0)),1:obj.nTab)
            setPanelProps(obj.hGUI.panelFileSelect,0);

            % clears each of the listboxes 
            cellfun(@(x)(set(x,'String','','Max',2,'Value',[])),obj.hList)
            
            % clears the code line table
            obj.clearCodeInfo()
            setObjEnable(obj.hGUI.buttonUpdateVer,'off')

            % clears the version difference text strings
            bgCol = 0.94*ones(1,3);
            hTxt = findall(obj.hTabDiff,'style','text');
            arrayfun(@(x)(set(x,'enable','off',...
                                'BackgroundColor',bgCol)),hTxt)           
            
        end
        
        % --- clears the code difference information table
        function clearCodeInfo(obj)

            set(obj.hGUI.textFilePath,'string','');
            set(obj.hGUI.tableCodeLine,'Data',[]);
            setPanelProps(obj.hGUI.panelCodeDiff,0);

        end            
        
        % --- resets the GUI objects
        function resetGUIObjects(obj,h)

            % recreates the repo structure object and graph
            if exist('h','var')
                lStr = 'Updating Information Fields...';
                h.StatusMessage = lStr;            
            end
            
            % clears the code/version information
            obj.clearCodeInfo()
            obj.clearVersionInfo();
            
            % updates the loadbar
            if exist('h','var')
                lStr = 'Recalculating Repository Branch Structure...';
                h.StatusMessage = lStr;
            end
            
            % determines which version filter button is selected, and
            % determine the repository structure from this
            hRadio = findall(obj.hGUI.panelVerFilt,'Value',1,...
                                                   'Style','radiobutton');
            switch get(hRadio,'tag')
                case 'radioAllVer'
                    % case is using all commits
                    obj.rObj = RepoStructure();
                    
                case 'radioLastVer'
                    % case is using all commits
                    obj.rObj = RepoStructure('nHist',obj.iData.nHist);                    
                    
                case 'radioDateFilt'
                    % case is filtering by date
                    obj.rObj = RepoStructure('d0',obj.iData.d0);
            end
            
            % recreates the repo structure object and graph
            obj.gObj.rObj = obj.rObj;
            obj.rObj.isMod = obj.detIfHeadModified();
            obj.gObj.setupRepoAxis(false);   
            
            % resets the branch group strings
            obj.groupBranchStrings();
            obj.updateVersionInfo()
            
        end        
        
        % ------------------------------------- %
        % --- COMMIT MODIFICATION FUNCTIONS --- %
        % ------------------------------------- %        
        
        % --- checks the commit modification status (0 if no modification,
        %     1 if user cancels, 2 if user ignores or 3 for new branch)
        function uStatus = checkCommitModifications(obj,h)
            
            % if there are no modifications, then exit the function
            uStatus = 0;  
            if ~obj.detIfHeadModified()                
                return
            end
            
            % if the loadbar exists, then makes it invisible
            if exist('h','var'); setObjVisibility(h.Control,0); end 
            
            % prompt user if they want to stash, commit or ignore changes
            uChoice = obj.promptUserChange();            
            switch uChoice
                case 'Create Branch'
                    % case is creating a new branch (which is the case
                    % when changing from a modified detached branch)
                    iDataB = GitCreate(obj);            
                    if isempty(iDataB)
                        % user cancelled or there was an error
                        uStatus = 1;
                        return
                    else
                        % if the user didn't cancel, then create 
                        % a new branch
                        obj.createNewBranch(iDataB)
                        uStatus = 3;
                    end                         
                    
                case 'Commit'
                    % case is commit changes
                    GitCommit(obj.hFig,obj.gfObj);
                    
                case 'Stash'
                    % case is stashing changes
                    obj.stashFiles()
                    
                case 'Ignore'
                    % case is ignoring the changes
                    uStatus = 2;

                case 'Cancel'
                    % case is cancelling (exit function) 
                    uStatus = 1;
                    return    
                    
            end
            
            % retrieves the head text object
            if obj.rObj.isMod
                hAx = obj.gObj.hAx;
                [iBr,iCm] = obj.getCurrentHeadInfo();
                iID = str2double(obj.rObj.gHist(iBr).brInfo.ID{iCm});
                hTxtD = findall(hAx,'tag','hTxtDesc','UserData',iID);

                % if the string has been tagged for modification, then remove
                txtStr = get(hTxtD,'String');
                if endsWith(txtStr,'**')
                    set(hTxtD,'String',txtStr(1:end-2));
                    obj.rObj.isMod = false;
                end
            end
                    
            % if the loadbar exists, then makes it visible again
            if exist('h','var')
                set(h.Control,'visible','on'); 
                pause(0.01)
            end                                          
            
        end
        
        % --- determines if there has been any modifications to the commit
        function isMod = detIfHeadModified(obj)
            
            % determines if there has been any file modfications            
%             fMod = obj.gfObj.gitCmd('diff-status',obj.rObj.headID);
            fMod =  obj.gfObj.gitCmd('branch-status',1);
            isMod = ~isempty(fMod);
            
        end                

        % --- determines if the head commit is detached from the branch
        function isDetached = isHeadDetached(obj,useHead)
            
            % sets the default input arguments
            if useHead
                cIDS = obj.rObj.headID;                
            else
                [~,cIDS] = obj.getSelectedCommitInfo();
            end
            
            % determines if the commit index (on the current branch) is
            % greater than one (if so, then the branch head is detached)            
            [~,iCm] = obj.getCurrentHeadInfo(cIDS);
            isDetached = iCm > 1;
            
        end
        
        % --- retrieves the current head branch/commit index
        function [iBr,iCm] = getCurrentHeadInfo(obj,cID)
            
            % sets the search commit ID
            if ~exist('cID','var')
                cID = obj.rObj.headID;
            end
            
            % determines the head ID matching indices            
            indM = arrayfun(@(x)(find(strcmp...
                        (x.brInfo.CID,cID))),obj.rObj.gHist,'un',0);
                    
            % sets the branch/commit indices
            iBr = find(~cellfun(@isempty,indM));
            iCm = indM{iBr};
            
        end        
        
        % --- create a remote branch, nwBr, from the parent branch, pBr
        function createNewRemoteBranch(obj,pBr,nwBr)
            
            % removes the url
            obj.gfObj.gitCmd('rmv-origin');  
            
            % sets the origin URL
            if obj.gfObj.uType > 0                              
                % case is a normal user
                obj.gfObj.gitCmd('set-origin-user')
            else
                % case is a developer
                obj.gfObj.gitCmd('set-origin')
            end

            % creates the remote branch (from the original branch)
            obj.gfObj.gitCmd('push-remote-init',pBr,nwBr);
            
        end        
        
        % --------------------------- %        
        % --- GIT STASH FUNCTIONS --- %
        % --------------------------- %             

        % --- stashes any files for a specific branch
        function stashFiles(obj,sStr)
            
            if obj.detIfHeadModified()
                % if there are any modified files, then unstash the
                % branch (if any files are stashed)
                if nargin == 1
                    sStr = obj.getStashBranchString();
                end                        

                % saves the new stash
                obj.unstashFiles(sStr)                        
                obj.gfObj.gitCmd('stash-save',sStr);
            end    
            
        end
        
        % --- unstashes any files for a specific branch        
        function unstashFiles(obj,sStr)
            
            % retrieves the stash string for the current branch                       
            if nargin == 1
                sStr = obj.getStashBranchString();
            end
            
            % determines the index of the stash that belongs to
            % the current branch (if any)
            iList = obj.detStashListIndex(sStr);                                        
            if ~isempty(iList)
                % if a stash does exist, then pop this stash
                obj.gfObj.gitCmd('stash-pop',iList-1)
            end  
            
        end        
        
        % --- removes any stashed files for a specific branch
        function removeStashedFiles(obj,sStr)

            % determines the index of the stash that belongs to
            % the current branch (if any)
            iList = obj.detStashListIndex(sStr);                                        
            if ~isempty(iList)
                % if a stash does exist, then pop this stash
                obj.gfObj.gitCmd('stash-drop',iList-1)
            end  
                                              
        end             

        % --- determines the index of the stash list (if it exists)
        function iList = detStashListIndex(obj,sStr)
            
            sList = strsplit(obj.gfObj.gitCmd('stash-list'),'\n');
            iList = find(cellfun(@(x)(strContains(x,sStr)),sList));
            
        end        
        
        % --- retrieves the stash string for the current branch
        function sStr = getStashBranchString(obj)
            
            % retrieves the current branch and sets the stash string
            iBr = obj.getCurrentHeadInfo();
            sStr = sprintf('%s-stash',obj.rObj.brData{iBr,1});    
            
        end                  
        
        % ----------------------------------- %
        % --- OTHER GIT RELATED FUNCTIONS --- %
        % ----------------------------------- %           
        
        % --- determines if the hot-fix/created branch data is valid
        function [mStr,tStr] = checkBranchData(obj,iData)
            
            % sets the new branch name
            nwBr = obj.getBranchNameString(iData);
            isDup = strcmp(obj.rObj.brData(:,1),nwBr);
            
            % checks the new branch name/password
            if any(isDup)
                % sets the suffix string (based on branch creation type)
                if isfield(iData,'pWordHF')
                    % case is hotfix branch creation
                    sStr = '';
                else
                    % case is general branch creation
                    sStr = '/type';
                end
                
                % sets the duplicate branch error message
                mStr = sprintf(['Branch name already exists. ', ...
                                'Re-enter a new branch name%s.'],sStr);
                tStr = 'Duplicate Branch';     
                
            elseif isfield(iData,'pWordHF')
                % checks the password is correct (if active field)
                if ~strcmp(obj.pWordHF,iData.pWordHF)
                    % case is the password is incorrect
                    mStr = ['Entered password is incorrect. ', ...
                            'Try with correct password.'];
                    tStr = 'Incorrect Password';
                else
                    % case is there is no issue
                    [mStr,tStr] = deal([]);
                end
                
            else
                % case is there is no issue
                [mStr,tStr] = deal([]);                
            end
        end                              
        
        % --- retrieves the currently selected commit information fields
        function [iSelS,cIDS,iSelSG] = getSelectedCommitInfo(obj)
            
            % retrieves the graph row index that is currently selected
            hFillS = obj.gObj.hFillS;
            iSelS = get(hFillS,'UserData');
            
            % retrieves the commit ID (dependent on selection0
            if isnan(iSelS)
                % case is there is no selected row
                cIDS = [];
            else
                % otherwise, return the selected row commit ID
                iSelSG = obj.gObj.indL2G(iSelS);
                cIDS = obj.rObj.bInfo{iSelSG,1};  
            end
            
        end              
        
        % --- retrieves the current branch name
        function cBr = getCurrentBranchName(obj)
            
            % retrieves the current branch name
            iBr = obj.getCurrentHeadInfo();
            cBr = obj.rObj.brData{iBr,1};
            
        end
        
        % --- restores the deleted branch, delBr
        function restoreDeletedBranch(obj,delBr,cID)
            
            % creates the load bar
            h = ProgressLoadbar('Restoring Deleted Branch...');                                            
            
            % determines if there are any modifications to the head
            isMod = obj.detIfHeadModified;
            if isMod
                % if so, then stash the modifications
                sStr = obj.gfObj.getStashBranchString(cBr);
                obj.gfObj.stashBranchFiles(sStr);                        
            end            
            
            % recreates the deleted local/remote branches
            obj.gfObj.gitCmd('create-local-detached',delBr,cID);
            obj.gfObj.gitCmd('force-push-commit',delBr,1);            
            
            % resets the GUI objects
            obj.resetGUIObjects();
            
            % deletes the progressbar
            delete(h)            
            
        end            
        
        % ----------------------- %
        % --- OTHER FUNCTIONS --- %
        % ----------------------- %            
        
        % --- post commit change function
        function postCommitFcn(obj,comObj)
            
            % if there was no commit change, then exit
            if ~comObj.isCommit
                return
            end
            
            % creates the load bar
            h = ProgressLoadbar('Updating Information Fields...');                
            
            % resets the GUI objects
            obj.rObj.isMod = false;
            obj.resetGUIObjects(h)            
            
            % deletes the progressbar and exits the function
            delete(h)        
            
        end        
        
        % --- updates the date struct field
        function setDateValue(obj,dStr,iSel,isBefore)
            
            pStr = sprintf('d%i.%s',isBefore,dStr);
            obj.iData = setStructField(obj.iData,pStr,iSel);
            
        end   
        
        % --- prompts the user for the action they would like to take 
        %     regarding any modifications within the code
        function uChoice = promptUserChange(obj)
            
            % initialisations
            qtStr = 'Code Changes Detected';
            bStr = {'Commit','Stash','Ignore','View','Cancel'};
            
            if obj.gfObj.uType > 0
                % user is not a developer (not able to make commits/stash)
                [i0,sStr] = deal(3,'Ignore');              
            
            else
                % case is a developer, so determines if branch is detached
                if obj.isHeadDetached(1)
                    % if detached, then can only create a new branch
                    bStr{2} = 'Create Branch';
                    [i0,sStr] = deal(2,'Create a new ranch');
                else
                    % not detached so able to make commits
                    [i0,sStr] = deal(1,'Commit, Stash');   
                end
            end                
                
            % sets the button/message string
            qStr = sprintf(['Changes have been detected on the ',...
                            'current branch.\nDo you want to %s ',...
                            'or Ignore these changes?'],sStr);
                        
            % prompts the user for what action they wish to take
            while 1
                uChoice = QuestDlgMulti(bStr(i0:end),qStr,qtStr);
                if strcmp(uChoice,'View')
                    % views the current changes on the branch
                    waitfor(GitViewChanges(obj.gfObj))
                    
                else
                    % otherwise, exit the loop
                    break
                end
            end                        
            
        end         
        
        % --- updates the context menu items
        function ok = updateContextMenu(obj,iRowH0)
                        
            try
                % determines the branch/commit indices of highlighted row
                indM = arrayfun(@(x)(find(str2double...
                            (x.brInfo.ID)==iRowH0)),obj.rObj.gHist,'un',0);
                iBr = ~cellfun(@isempty,indM);
                iCm = indM{iBr};   
                cIDS = obj.rObj.gHist(iBr).brInfo.CID{iCm};
            catch
                % if there was an error, then exit
                ok = false;
                return
            end
            
            % determines the branch index of the current head
            iBrH = obj.getCurrentHeadInfo(obj.rObj.headID);
            
            % initialisations
            ok = true;
            gapStr = '==================';
            atHead = strcmp(cIDS,obj.rObj.headID);
            hasMod = obj.detIfHeadModified() && atHead;
            notMaster = ~strcmp(obj.rObj.brData{iBr,1},'master');
            isParent = any(strcmp(field2cell(obj.rObj.gHist,'pCID'),cIDS));
            nCommBr = size(obj.rObj.gHist(iBr).brInfo,1);
            
            % sets the menu label strings (based on the user type)
            switch obj.gfObj.uType
                case 0
                    % developer only labels
                    lblStr = {'Create New Branch',...               % complete                              
                              'Rename Commit',...                   % complete
                              'Rebase Branch Commits',...
                              gapStr,...
                              'Merge Branches',...                  % 5
                              'Rebase Branch',...                   % 6                     
                              'Rename Branch',...                   % complete
                              'Delete Branch',...                   % complete
                              gapStr,...                              
                              'Delete Head Commit',...              % complete
                              'Commit Changes',...                  % complete
                              'Ignore Local Changes'};              % complete              
                          
                    % sets the acceptance flags
                    isOK = true(size(lblStr));
                    isOK(1) = true;                                     % (can occur at any node)
                    isOK(2) = true;                                     % (can occur at any node)                    
                    isOK(3) = ~atHead;                                  % (only for non-head commits)
                    isOK(5) = (iCm == 1) && notMaster  && atHead;       % (only for non-master branch nodes when selected at the branch tip)
                    isOK(6) = (iCm == 1) && notMaster;                  % (only when non-master branch tip nodes are selected)
                    isOK(7) = (iCm == 1) && notMaster;                  % (only for when branch tip node is currently selected)                    
                    isOK(8) = (iCm == 1) && notMaster && ~iBr(iBrH);    % (only for when branch tip node is currently selected)                                        
                    isOK(10) = (iCm == 1) && ~isParent && (nCommBr>1);   % (only for branch tips that are not parents)
                    isOK(11) = (iCm == 1) && hasMod;                    % (only for when the branch tip is currently selected)
                    isOK(12) = hasMod;                                  % (only for modified nodes)
                    
                    % sets the gap strings
                    isOK(4) = any(isOK(5:8));
                    isOK(9) = any(isOK(10:end));
                    
                case 1
                    % user only labels
                    lblStr = {'Create Hot-Fix',...
                              'Ignore Local Changes'};
                          
                    % sets the acceptance flags
                    isOK = true(size(lblStr));
                    isOK(:) = hasMod;
                    
            end
            
            % determines if there are any valid label strings
            if ~any(isOK)
                % if not, then exit with a false flag
                ok = false;
                
            else
                % otherwise, update the context menu labels
                obj.cmObj.updateMenuLabels(lblStr(isOK)); 
            end
            
        end
        
    end
        
    % class static methods
    methods (Static)
    
        % --- determines if the current before/after dates are feasible
        function isFeas = feasDateFilter(iData)

            % calculates the date-time objects and determines if feasible
            d0 = iData.d0;
            isFeas = now > datenum(d0.Year,d0.Month,d0.Day);

        end
        
        % --- determines what type of popupmenu was selected
        function [isBefore,dType] = getSelectedPopupType(hObj)

            % initialisations
            dStr = {'Day','Month','Year'};
            hObjStr = get(hObj,'tag');

            % determines if the object is a before popup object
            isBefore = strContains(hObjStr,'Before');

            % determines the date type of the popup menu object
            dType = find(cellfun(@(x)(strContains(hObjStr,x)),dStr));

        end
        
        % --- retrieves the day count based on month index
        function dCount = getDayCount(iMonth)

            switch iMonth
                case (2) % case is February
                    dCount = 28;
                case {4,6,9,11} % case is the 30 day months
                    dCount = 30;                
                otherwise % case is the 31 day months
                    dCount = 31;                                
            end

        end        
        
        % --- splits the code difference into it compoentns
        function CBlk = splitCodeDiff(dStr)
            
            % determines the lines where the code blocks start
            dBlk = strsplit(dStr,'\n')';
            iDiffC = find(cellfun(@(x)(startsWith(x,'@@')),dBlk));
            if isempty(iDiffC)
                % if there are none, then exit with an empty array
                CBlk = [];
                return;
            end

            % splits the codes into the separate blocks
            endStr = '\ No newline at end of file';
            p = struct('Code',[],'iLine',[],'Type',[]);
            iBlkC = num2cell([iDiffC,[iDiffC(2:end)-1;length(dBlk)]],2);
            CBlk = repmat(p,length(iBlkC),1);

            %
            for j = 1:length(iBlkC)
                % retrieves the new code block
                cBlkNw = dBlk(iBlkC{j}(1):iBlkC{j}(2));
                while 1            
                    if isempty(cBlkNw{end}) || strcmp(cBlkNw{end},endStr)
                        cBlkNw = cBlkNw(1:end-1); 
                    else
                        break
                    end
                end

                % sets the new code block into the data struct
                CBlk(j).Code = cellfun(@(x)(x(2:end)),cBlkNw(2:end),'un',0);            
                CBlk(j).iLine = cell(length(CBlk(j).Code),2);  
                CBlk(j).Type = zeros(length(CBlk(j).Code),1);  

                % determines the insertion/deletion parameters
                cInfo = strsplit(cBlkNw{1});
                iLine = cell2mat(cellfun(@(y)(cellfun(@(x)(abs(...
                                    str2double(x))),strsplit(y,','))),...
                                    cInfo(2:3)','un',0));
                ind = iLine(:,1)';    

                for k = 1:length(CBlk(j).Code)                             
                    if strcmp(cBlkNw{k+1}(1),'+')
                        [CBlk(j).Type(k),cNw] = deal(2,num2str(ind(1)));
                        CBlk(j).iLine(k,:) = ...
                                        {cNw,repmat('*',1,length(cNw))};
                        ind(1) = ind(1) + 1;
                    elseif strcmp(cBlkNw{k+1}(1),'-')
                        [CBlk(j).Type(k),cNw] = deal(1,num2str(ind(end)));
                        CBlk(j).iLine(k,:) = ...
                                        {repmat('*',1,length(cNw)),cNw};
                        ind(end) = ind(end) + 1;
                    else
                        CBlk(j).iLine(k,:) = ...
                                    arrayfun(@(x)(num2str(x)),ind,'un',0);
                        ind = ind + 1;
                    end
                end
            end            
            
        end
        
        % --- retrieves the new branch name (based on the branch data)
        function brName = getBranchNameString(iData)
            
            % determines what branch type the new branch is
            if strcmp(iData.bType,'main')
                % case is a main branch type
                brName = iData.bName;
            else
                % case is a sub-main branch type
                brName = sprintf('%s-%s',iData.bType,iData.bName);
            end            
        end           
        
        % --- determines if the new branch name is feasible
        function ok = checkBranchName(txtBr)
            
            % determines if the string is valid
            [ok,mStr] = chkDirString(txtBr,1);
            if ok && (strcmp(txtBr(1),'.') || strcmp(txtBr(1),'-'))
                % if valid, but starts with ".", then set an error message
                ok = 0;
                mStr = 'Error! Branch string can''t start with "." or "-".';
            end  
            
            % if there was an error, then output the message to screen
            if ~ok                
                waitfor(errordlg(mStr,'Branch Name Error','modal'))                
            end
            
        end               
        
        % --- splits the branch info local and remote branches
        function [brL,brR,isR] = splitBranchInfo(brInfo)

            isR = strContains(brInfo(:,1),'origin');
            brL = brInfo(~isR,1);
            brR = cellfun(@(x)(getFileName(x)),brInfo(isR,1),'un',0);

        end                
        
    end

end
