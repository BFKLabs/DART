classdef GitCommitClass < handle
    
    % class properties
    properties
        % main class objects
        hFig
        hGUI
        hFigM
        gfObj 
        
        % creates object classes
        pDiff
        sDiff
        cBlk
        cID
        cBr
        
        % created object handles
        jRoot
        jTab
        hTabDiff
        hList
        
        % scalar class object variables
        nTab
        isRunGV
        dX = 10;
        ok = true;    
        isCommit = false;
        tStr = {'Altered','Added','Removed'};
        
    end
    
    % class methods
    methods
        % class constructor
        function obj = GitCommitClass(hFig,hFigM,gfObj)
            
            % sets the input arguments
            obj.hFig = hFig;
            obj.hFigM = hFigM;
            obj.hGUI = guidata(hFig);
            obj.gfObj = gfObj;
            
            % initialises the object callbacks
            obj.initObjCallbacks();            
            
            % initialises the GUI objects
            obj.initGUIObjects()
            
        end    
        
        % --------------------------------------------- %
        % --- CLASS OBJECT INITIALISATION FUNCTIONS --- %
        % --------------------------------------------- %          
        
        % --- initialises all the object callback functions
        function initObjCallbacks(obj)
           
            % objects with normal callback functions
            cbObj = {'buttonPushCommit'};
            for i = 1:length(cbObj)
                hObj = getStructField(obj.hGUI,cbObj{i});
                cbFcn = eval(sprintf('@obj.%sCB',cbObj{i}));
                set(hObj,'Callback',cbFcn)
            end
            
        end
        
        % --- initialises the GUI objects
        function initGUIObjects(obj)
            
            % imports the checkbox tree
            import com.mathworks.mwswing.checkboxtree.*

            % initialisations
            cDir = pwd;
            handles = obj.hGUI;
            
            % retrieves the current branch                       
            obj.cID = obj.gfObj.gitCmd('commit-id');
            obj.cBr = obj.gfObj.gitCmd('current-branch');
            
            % sets up the difference struct
            obj.sDiff = struct();
            for i = 1:length(obj.tStr)
                obj.sDiff = setStructField(obj.sDiff,obj.tStr{i},[]);
            end
            
            % creates/sets the gitignore file 
            createGitIgnoreFile(obj.gfObj);

            % retrieves the status string and splits into by line
            cd(obj.gfObj.gDirP)
            obj.gfObj.gitCmd('show-all-untracked');
            sStr = obj.gfObj.gitCmd('status-short');     
%             sStr = obj.gfObj.gitCmd('diff-status',obj.cID);      
            obj.sDiff = splitDiffStatus(sStr,obj.tStr,1);
            cd(cDir)

            % creates the commit explorer tree
            obj.jRoot = obj.createCommitExplorerTree();

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%    COMMIT MESSAGE OBJECTS    %%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            % sets the default message
            gName = obj.gfObj.gName;
            cMsg0 = sprintf('%s Update (%s)',gName,datestr(now,1));
            set(handles.editCommitMsg,'string',cMsg0);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%    CODE DIFFERENCE OBJECTS    %%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % object retrieval
            hTable = handles.tableCodeLine;

            % initialises the codeline table properties
            [cWid0,tPos] = deal(50,get(hTable,'position'));
            cWid = {cWid0,cWid0,tPos(3)-2*cWid0};
            set(hTable,'data',[],'columnwidth',cWid)
            autoResizeTableColumns(hTable)

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%    VERSION DIFFERENCE OBJECTS    %%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % updates the version difference objects
            obj.setupVersionDiffObjects()
            obj.updateCodeDifferenceListboxes()
            
        end
        
        % --- sets up the version difference objects
        function setupVersionDiffObjects(obj)

            % initialisations                        
            obj.nTab = length(obj.tStr);
            obj.hList = cell(obj.nTab,1);
            hPanelF = obj.hGUI.panelFileSelect;
            
            % sets the object positions            
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
                          'tag',[obj.tStr{i},'T']);    

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
        
        % ------------------------------- %
        % --- EXPLORER TREE FUNCTIONS --- %
        % ------------------------------- %
        
        % --- creates the commit explorer tree
        function jRoot = createCommitExplorerTree(obj)

            % imports the checkbox tree
            import com.mathworks.mwswing.checkboxtree.*

            % parameters and initialisations
            handles = obj.hGUI;
            hPanel = handles.panelFileChanges;
            rStr = {'Current version up to date!','Code Changes...'};
            
            % determines if there are any modified file (over all the
            % modified file types)
            nFile = cellfun(@length,getAllStructFields(obj.sDiff));
            hasFiles = any(nFile > 0);

            % memory allocation for the code difference blocks
            obj.cBlk = arrayfun(@(x)(cell(x,1)),nFile,'un',0);
            
            % sets up the directory trees structure
            rootStr = setHTMLColourString('kb',rStr{1+hasFiles},1);
            jRoot = DefaultCheckBoxNode(rootStr);

            % creates the rest of the tree structure
            fStr = fieldnames(obj.sDiff);
            for i = 1:length(fStr)
                % retrieves the file names for the current type
                sDiffF = getStructField(obj.sDiff,fStr{i});
                if ~isempty(sDiffF)
                    % creates the root node for the current file type
                    rootStr0 = sprintf('%s Files',fStr{i});
                    rootStr = setHTMLColourString('kb',rootStr0,1);
                    jRootF = DefaultCheckBoxNode(rootStr);

                    % sets children nodes for the current file type
                    for j = 1:length(sDiffF)
                        sFile = fullfile(sDiffF(j).Path,sDiffF(j).Name);
                        obj.setupChildNode(jRootF,strsplit(sFile,filesep));
                    end

                    % adds the file type node to the root node
                    jRoot.add(jRootF);
                end
            end

            % retrieves the object position
            pPos = get(hPanel,'position');

            % creates the final tree explorer object
            jTree = com.mathworks.mwswing.MJTree(jRoot);
            jCheckBoxTree = handle(CheckBoxTree(jTree.getModel),...
                                   'CallbackProperties');
            jScrollPane = com.mathworks.mwswing.MJScrollPane(jCheckBoxTree);
            
            % creates the tree object
            tPos = [obj.dX*[1 1],pPos(3:4)-[2*obj.dX,35]];
            [~,~] = javacomponent(jScrollPane,tPos,hPanel);

            % only enabled the commit button if there are commits available
            setObjEnable(handles.buttonPushCommit,hasFiles)

            % sets the callback function            
            set(jCheckBoxTree,'MouseClickedCallback',{@obj.selectCallback})

        end

        % --- tree checkbox selection callback function
        function selectCallback(obj,~,~)

            % updates the commit buttons enabled properties
            hBut = obj.hGUI.buttonPushCommit;
            setObjEnable(hBut,~isempty(getSelectedTreeNodes(obj.jRoot)))

        end  
        
        % --- creates the children nodes from jRoot for the array, fStrSp 
        function jChild = setupChildNode(obj,jRoot,fStrSp)

            % imports the checkbox tree
            import com.mathworks.mwswing.checkboxtree.*

            % initialisation
            jChild = [];

            % determines if the current node already exists
            for i = 1:jRoot.getChildCount
                jChildNw = jRoot.getChildAt(i-1);
                if strcmp(jChildNw,fStrSp{1})
                    % if so then set the child node to be the previous node
                    jChild = jChildNw;
                    break
                end
            end

            % if no previous node was found, then create a new one
            if isempty(jChild)
                jChild = DefaultCheckBoxNode(fStrSp{1}); 
                set(jChild,'SelectionState',SelectionState.SELECTED)
                jRoot.add(jChild)
            end

            % add any further children nodes
            if length(fStrSp) > 1
                jChild = obj.setupChildNode(jChild,fStrSp(2:end));
            end

        end
        
        % -------------------------- %
        % --- CALLBACK FUNCTIONS --- %
        % -------------------------- %      
        
        % --- Executes on button press in buttonPushCommit.
        function buttonPushCommitCB(obj,hObject,~)
            
            % parameters
            cDir = pwd;
            nLast = 10;
            handles = obj.hGUI;
            hPanel = handles.panelFileChanges;

            % retrieves the full name of the selected files (exit if none)
            hasCommFiles = true;
            sNode = getSelectedTreeNodes(obj.jRoot);
            if isempty(sNode)
                if isempty(obj.sDiff.Removed)
                    return
                else
                    hasCommFiles = false;
                end
            end

            % retrieves the commit message (only if adding files)
            if hasCommFiles
                % retrieves the current commit message
                cMsg = get(handles.editCommitMsg,'string');

                % retrieves the last nLast commit messages  
                logStr = obj.gfObj.gitCmd('n-log',nLast);
                logStrGrp = getCommitHistGroups(logStr,1);
                cMsgPrev = cellfun(@(x)(x{end}),logStrGrp,'un',0);

                % if the same commit message is being used, then prompt  
                % the user if they want to continue
                if any(strcmp(cMsgPrev,cMsg))    
                    qtStr = 'Duplicate Commit Message';
                    qStr = sprintf(['This commit message is same as a ',...
                                    'recent commit.\nAre you sure you ',...
                                    'want to continue?']);        
                    uChoice = questdlg(qStr,qtStr,'Yes','No','Yes');
                    if ~strcmp(uChoice,'Yes')
                        % if the user cancelled, then exit the function
                        return
                    end
                end
            end

            % memory allocation
            cFile = struct('Altered',[],'Added',[],'Removed',[]);
            cType = fieldnames(cFile);

            % sets the selected files into their respective categories
            for i = 1:length(sNode)
                % determines what type of file the current file is
                fileSp = strsplit(sNode{i},'\');
                iType = cellfun(@(x)(strContains(fileSp{2},x)),cType);

                % sets the file name into the corresponding struct field
                fileNw = strjoin(fileSp(3:end),'/');
                eval(sprintf('cFile.%s{end+1} = fileNw;',cType{iType}));
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%    ADDING OF SELECTED FILES TO REPOSITORY    %%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            % creates the loadbar
            h = ProgressLoadbar('Applying Commit To Git Repository...');
            
            % changes the directory to the main directory
            obj.isCommit = true;
            cd(obj.gfObj.gDirP);

            % adds the altered files to the repository
            for i = 1:length(cFile.Altered)
                obj.gfObj.gitCmd('add-file',cFile.Altered{i});
            end

            % adds the added files to the repository
            for i = 1:length(cFile.Added)
                obj.gfObj.gitCmd('add-file',cFile.Added{i});
            end

            % adds the added files to the repository
            for i = 1:length(cFile.Removed)
                obj.gfObj.gitCmd('remove-file',cFile.Removed{i});
            end

            % readds any files flagged for deletion but were kept otherwise
            if length(obj.sDiff.Removed) > length(cFile.Removed)
                % fetches the files from the remote branch
                obj.gfObj.gitCmd('remote-fetch',obj.cBr);
                for i = 1:length(obj.sDiff.Removed)
                    % re-adds the file if the current file is to be kept
                    if ~any(strcmp(cFile.Removed,obj.sDiff.Removed{i}))
                        obj.gfObj.gitCmd('checkout-remote-file',...
                                            obj.cBr,obj.sDiff.Removed{i})
                    end
                end
            end

            % returns to the original directory
            cd(cDir);

            % runs the commit (only if there were files added)
            if hasCommFiles
                % initial push to the remote branch
                obj.gfObj.gitCmd('commit-simple',cMsg);
                pushMsg = obj.gfObj.gitCmd('force-push');  
                if strcmp(pushMsg,'fatal')
                    % if there was an error, then resets the upstream
                    obj.gfObj.gitCmd('push-set-upstream',obj.cBr)
                end
                
                % pushes the changes to the remote branch
                obj.gfObj.gitCmd('force-push',1);    
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%    HOUSE-KEEPING EXERCISES    %%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            % retrieves the difference/selected file name field cell arrays
            sDiffC = getAllStructFields(obj.sDiff);
            cFileC = getAllStructFields(cFile);

            % removes the files that have been selected
            for i = 1:length(sDiffC)
                if ~isempty(sDiffC{i}) && ~isempty(cFileC{i})
                    % determines the files which were committed (and hence
                    % can be removed from the lists)
                    fName = field2cell(sDiffC{i},'Name');
                    cFileCF = cellfun(@(x)...
                                    (getFileName(x,1)),cFileC{i},'un',0);
                    isRmv = cellfun(@(x)(any(strcmp(cFileCF,x))),fName);
                    
                    % resets the 
                    if all(isRmv)
                        sDiffC{i} = [];
                    else
                        sDiffC{i} = sDiffC{i}(~isRmv);
                    end
                    
                    % resets the code block/file difference structs
                    obj.sDiff = setStructField...
                                    (obj.sDiff,cType{i},sDiffC{i});
                end
            end

            % deletes and replaces the current tree object 
            jTree = findall(hPanel,'type','hgjavacomponent');
            if ~isempty(jTree); delete(jTree); end
            obj.jRoot = obj.createCommitExplorerTree();

            % updates the code difference listboxes
            obj.updateCodeDifferenceListboxes()

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%    HOUSE-KEEPING EXERCISES    %%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            % determines if there are any files that still need commiting
            hasFiles = any(cellfun(@length,sDiffC) > 1);

            % clears/disables all code difference objects associated
            set(handles.tableCodeLine,'data',[])
            set(handles.textFilePath,'string','')

            % disables the file select panel
            setObjEnable(hObject,hasFiles)
            setPanelProps(handles.panelFileSelect,hasFiles)

            % deletes the loadbar
            delete(h)
            
        end
        
        % --- callback function for selecting the code difference list
        function selDiffItem(obj,hObject,~)
            
            % retrieves the 
            handles = obj.hGUI;
            hTable = handles.tableCodeLine;
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
            pDiff0 = getStructField(obj.sDiff,tStr0);
            pDiffC = pDiff0(iSelC);
            
%             % determines the head/selected commit ID's
%             cIDH = obj.rObj.headID;
%             [~,cIDS] = obj.getSelectedCommitInfo();
            
            % case is a text file is selected
            set(hTable,'enable','on','columnname',hStr)      
          
            % retrieves/determines the code block difference information
            if isempty(obj.cBlk{iTab}{iSelC})
                % creates a loadbar
                h = ProgressLoadbar('Determining Code Difference...');

                % retrieves the code difference block 
                fFile = fullfile(pDiffC.Path,pDiffC.Name);
                dStr = obj.gfObj.gitCmd('diff-file',obj.cID,fFile);
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
                set(hTable,'data',DataNw,'enable','off')                       
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
                set(hTable,'data',tData,'visible','on');       
                autoResizeTableColumns(hTable)
                set(hTable,'backgroundcolor',bColFin)
            end            
            
        end        
        
        % ----------------------- %
        % --- OTHER FUNCTIONS --- %
        % ----------------------- %
        
        % --- updates the code difference listboxes
        function updateCodeDifferenceListboxes(obj)

            % retrieves the object handles            
            handles = obj.hGUI;

            % sets the tab header strings
            sDiffC = getAllStructFields(obj.sDiff);
            nFile = cellfun(@length,sDiffC);

            % retrieves the fieldnames from struct
            tStrD = fieldnames(obj.sDiff);

            % sets the difference object properties
            for i = 1:length(tStrD)
                % retrieves the list strings
                if isempty(sDiffC{i})
                    lStr = [];
                else
                    lStr = field2cell(sDiffC{i},'Name');
                end

                % updates the listbox
                obj.hList = findall(get(obj.hTabDiff,'Children'),'style',...
                                             'listbox','tag',tStrD{i});
                set(obj.hList,'string',lStr,'max',2,'value',[])

                % sets the plural string
                if length(lStr) == 1
                    % case is there is only 1 file so no pluralisation
                    pStr = '';
                else
                    % otherwise, set the plural string
                    pStr = 's';
                end

                % sets the tab enabled properties
                obj.jTab.setEnabledAt(i-1,~isempty(lStr))

                % sets the text label string
                tagStr = [tStrD{i},'T'];
                hTxt = findall(get(obj.hTabDiff,'Children'),'tag',tagStr);                                
                nFileD = length(lStr);
                txtDiff = sprintf('%i File%s %s',nFileD,pStr,tStrD{i});
                set(hTxt,'string',txtDiff); 
            end

            % if no files are altered, then disable the file select/code diff panels
            if all(nFile == 0)                
                setPanelProps(handles.panelFileSelect,'off')
                setPanelProps(handles.panelCodeDiff,'off')    
            end

        end
        
        % --- clears the code difference information table
        function clearCodeInfo(obj)

            set(obj.hGUI.textFilePath,'string','');
            set(obj.hGUI.tableCodeLine,'Data',[]);
            setPanelProps(obj.hGUI.panelCodeDiff,0);

        end
        
        % --- gets the difference strings for the files that have been added
        function diffStrAdd = getAddedDiffStr(obj)

            % memory allocation
            diffStrAdd = [];
            pAdded = obj.sDiff.Added;

            % retrieves the file contents for all added files
            for i = 1:length(pAdded)
                % retrieves the information from the added file
                obj.gfObj.gitCmd('add-file',pAdded{i});
                diffStrNw = obj.gfObj.gitCmd('cached-diff',pAdded{i});        
                obj.gfObj.gitCmd('reset-file',pAdded{i});

                % appends the new string to the difference string
                diffStrAdd = [diffStrAdd,diffStrNw];
            end

        end
        
    end
    
    % static class methods
    methods (Static)
    
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
        
    end
        
end