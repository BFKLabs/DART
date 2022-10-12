classdef FileTreeExplorer < handle

    % class properties
    properties
    
        % main class fields
        hP
        sDir
        fExtn
        
        % other class fields
        sFileT
        sFileD
                
        % tree object handles
        jRoot
        jTree
        mTree
        jSB
        
        % object dimensions
        dX = 10;
        
        % miscellaneous fields
        ok = true;
        isUpdate = false;
    
    end

    % class properties
    methods
        
        % --- class constructor
        function obj = FileTreeExplorer(hP,sDir,fExtn)
    
            % sets the input arguments
            obj.hP = hP;
            obj.sDir = sDir;
            obj.fExtn = fExtn;
            
            % finds all the files within the parent directory with the 
            % specified file extension
            obj.sFileT = obj.findFileAll(obj.sDir);            
            if isempty(obj.sFileT)
                % if there are no files found, then exit 
                obj.ok = false;
                return
            end                        

            % initialises the class fields and create the tree object            
            obj.createFileStructure();   
            obj.setupExplorerTree();            
            
        end               
        
        % -------------------------------------- %
        % --- TREE STRUCTURE SETUP FUNCTIONS --- %
        % -------------------------------------- %        
        
        % --- creates the file directory tree structure
        function createFileStructure(obj)
            
            % splits the paths into their constituent folders
            nS = length(obj.sDir) + 2;
            sFileSp = cell2cell(cellfun(@(x)...
                       (strsplit(x(nS:end),filesep)),obj.sFileT,'un',0),1);
            
            % determines the file path directory structure
            obj.sFileD = obj.createDirStructure(sFileSp,'');
            obj.sFileD.isSet = true;    
            
        end
        
        % --- splits the sub-directory paths 
        function sFile = createDirStructure(obj,sFileSp,fDirP0,indC0,iLvl)
    
            % sets the default input arguments
            if ~exist('indC0','var'); indC0 = 1:size(sFileSp,1); end
            if ~exist('iLvl','var'); iLvl = 1; end
            
            % memory allocation
            sFile = struct('fDirP',fDirP0,'fName',[],'fFile',[],...
                           'sFileD',[],'indC',[],'hObj',[],...
                           'iLvl',iLvl,'isSet',false);
            
            % determines the directory fields in the array
            nDir = sum(~cellfun(@isempty,sFileSp),2) - 1;            
            isDir = nDir > 0;              
            
            % determines the indices of the
            iDir = find(isDir);
            [sDirU,~,iC] = unique(sFileSp(isDir,1),'stable');
            indC = arrayfun(@(x)(iDir(iC==x)),1:max(iC),'un',0);
            nDirU = length(sDirU);
            
            % memory allocation
            sFile.indC = indC0(~isDir); 
            sFile.fName = sFileSp(~isDir,1);
            sFile.fFile = obj.sFileT(sFile.indC);
            sFile.sFileD = cell(nDirU,1);
            sFile.hObj = cell(nDirU+length(sFile.fFile),1);
            
            % searches each of the sub-directories            
            if nDirU > 0
                % if there is more than one sub-directory, then create the
                % file directory structures 
                for i = 1:nDirU
                    indCnw = indC0(indC{i});
                    fDirPnw = fullfile(fDirP0,sFileSp{indC{i}(1),1});
                    sFile.sFileD{i} = obj.createDirStructure(sFileSp...
                                (indC{i},2:end),fDirPnw,indCnw,[iLvl,i]);
                end
            
                % combines the cell array into a struct
                sFile.sFileD = cell2mat(sFile.sFileD);
            end
            
        end        
        
        % ------------------------------- %
        % --- EXPLORER TREE FUNCTIONS --- %
        % ------------------------------- %         
        
        % --- initialises the class fields
        function setupExplorerTree(obj)
            
            % imports the checkbox tree
            import com.mathworks.mwswing.checkboxtree.*            
            
            % deletes any existing tree objects within the panel object
            jTreePr = findall(obj.hP,'type','hgjavacomponent');
            if ~isempty(jTreePr); delete(jTreePr); end            
            
            % sets up the directory trees structure
            sDirF = getFileName(obj.sDir);
            obj.jRoot = DefaultCheckBoxNode(sDirF);
            
            % creates the root branch
            obj.addTreeBranch(obj.jRoot,obj.sFileD);
            
            % creates the final tree explorer object
            obj.jTree = com.mathworks.mwswing.MJTree(obj.jRoot);
            obj.mTree = handle(CheckBoxTree...
                            (obj.jTree.getModel),'CallbackProperties');            
            jScrollPane = com.mathworks.mwswing.MJScrollPane(obj.mTree);
            
            % sets the tree explorer callback function
            set(obj.mTree,'TreeWillExpandCallback',@obj.treeExpand);
            
            % creates the scrollpane object
            pPos = get(obj.hP,'Position');
            tPos = [obj.dX*[1 1],pPos(3:4)-2*obj.dX];
            [~,~] = createJavaComponent(jScrollPane,tPos,obj.hP);
            
            % retrieves the vertical scrollbar object handles
            obj.jSB = jScrollPane.getVerticalScrollBar();
            
        end               
                
        % --- adds the branch nodes to the parent node, hNodeP
        function isChng = addTreeBranch(obj,jNodeP,sFileL)
            
            % imports the checkbox tree
            import com.mathworks.mwswing.checkboxtree.*   
            
            % initialisations
            isChng = false;
            nNodeP = jNodeP.getChildCount;
            [nD,nF] = deal(length(sFileL.sFileD),length(sFileL.fName));                        
            sStateP = jNodeP.getSelectionState();
            
            % if there are already existing nodes, then check that the node
            % count matches the required count            
            if nNodeP > 0
                % determines if the node count equals the required count
                if (nD + nF) == nNodeP
                    % determines if there is only one node
                    if nNodeP == 1
                        % if the node is a dummy node, then update
                        jNodeNw = jNodeP.getChildAt(0);
                        if isempty(jNodeNw.getUserObject)
                            if nD == 1
                                nStr = getFileName(sFileL.sFileD(1).fDirP);
                                obj.addDummyNode(jNodeNw);
                            else
                                nStr = sFileL.fName{1};
                            end
                            
                            % resets the node string
                            jNodeNw.setUserObject(nStr);
                            jNodeNw.setSelectionState(sStateP);
                            isChng = true;
                        end
                    end
                    
                    % exits the function
                    return
                end
            end            
            
            % determines if there is a dummy node
            isChng = true;
            hasDummy = (nNodeP == 1);
            
            % creates the directory nodes
            for i = 1:nD
                % retrieves the directory name string
                dirName = getFileName(sFileL.sFileD(i).fDirP);                
                if hasDummy
                    % if there is a dummy node
                    hasDummy = false;
                    jNodeNw = jNodeP.getChildAt(0);
                    jNodeNw.setUserObject(dirName);
                else
                    % sets up the directory node object
                    jNodeNw = DefaultCheckBoxNode(dirName);
                    jNodeP.add(jNodeNw);
                end                    
                    
                % adds a dummy node to the new node
                jNodeNw.setSelectionState(sStateP);
                obj.addDummyNode(jNodeNw);
            end
            
            % creates the directory nodes
            for i = 1:length(sFileL.fName)                
                % sets up the directory node object
                fileName = sFileL.fName{i};                                 
                if hasDummy
                    hasDummy = false;
                    jNodeNw = jNodeP.getChildAt(0);
                    jNodeNw.setUserObject(fileName);
                else
                    % adds the node to the parent 
                    jNodeNw = DefaultCheckBoxNode(fileName);
                    jNodeP.add(jNodeNw);               
                end
                
                % sets the node selection state
                jNodeNw.setSelectionState(sStateP);
            end
            
        end                        
                
        % ------------------------------------- %
        % --- SELECTED NODE INDEX FUNCTIONS --- %
        % ------------------------------------- %        
        
        % --- retrieves the indices of the currently selected nodes
        function iSel = getCurrentSelectedNodes(obj)
            
            iSel = obj.getBranchSelectedNodes(obj.jRoot,1);
                            
        end
        
        % --- retrieves the indices of the selected nodes on the branch
        function iSel = getBranchSelectedNodes(obj,hNodeP,iLvl)
            
            % retrieves the children node objects
            xiC = (1:hNodeP.getChildCount)'; 
            sFileL = obj.getBranchInfo(iLvl);
            hNodeC = arrayfun(@(x)(hNodeP.getChildAt(x-1)),xiC,'un',0);
            
            % retrieves the selection state of the nodes
            sState = cellfun(@(x)(char...
                                (x.getSelectionState())),hNodeC,'un',0);
                            
            % retrieves the selected nodes/directory indices
            isSel = ~strcmp(sState,'not selected');
            if ~any(isSel)
                % if nothing is selected then exit the function
                iSel = [];
                return
            end
            
            % retrieves the indices of the selected files
            isDir = ~cellfun(@(x)(x.isLeaf()),hNodeC);
            iSel = sFileL.indC(isSel(~isDir));
            
            % determines if any directory nodes have been selected
            iSelD = find(isSel & isDir);
            if ~isempty(iSelD)            
                % if so, then retrieve the indices of the selected nodes
                % from each of the selected nodes
                iSelNw = cell(size(isSel));                        
                for i = iSelD(:)'
                    if strcmp(sState{i},'mixed')
                        % case is a mixed node (search nodes in sub-dir)
                        iSelNw{i} = ...
                            obj.getBranchSelectedNodes(hNodeC{i},[iLvl,i]);
                    else
                        % case is a selected node (retrieve the indices of
                        % all sub-directory nodes)
                        iSelNw{i} = ...
                            obj.getBranchNodeIndices(sFileL.sFileD(i));
                    end
                end
                
                % appends the selected indices
                iSel = [iSel(:);cell2mat(iSelNw)];
            end
            
        end
        
        % --- retrieves the branch-to-file mapping indices
        function iSel = getBranchNodeIndices(obj,sFileL)
            
            % retrieves the file indices
            iSel = sFileL.indC(:);
            
            % retrieves the indices for the files in the sub-folders
            if ~isempty(sFileL.sFileD)
                % if so, retrieve the node indices for the sub-directories
                iSelD = cell(size(sFileL.sFileD));
                for i = 1:length(iSelD)
                    iSelD{i} = obj.getBranchNodeIndices(sFileL.sFileD(i));
                end
                
                % appends the indices for the sub-directories
                iSel = [iSel;cell2mat(iSelD)];
            end            
            
        end        
        
        % -------------------------------- %
        % --- CLASS CALLBACK FUNCTIONS --- %
        % -------------------------------- %
        
        % --- tree node expansion callback function
        function treeExpand(obj,~,evnt)
                        
            % initialisations
            sFileL = obj.sFileD;
            hPath = evnt.getPath;
            iLvl = double(setGroup(1,[hPath.getPathCount(),1]));             
                                    
            % traverses the tree path to get the selected node info
            for i = 2:hPath.getPathCount()
                % retrieves the next component 
                jNodeP = hPath.getPathComponent(i-1);
                
                % determines the index of the node (within the branch)
                fDirP0 = field2cell(sFileL.sFileD,'fDirP');
                fDirP = cellfun(@(x)(getFileName(x)),fDirP0,'un',0);
                iNode = find(strcmp(fDirP,jNodeP.getUserObject()));
                
                % updates the level index and the directory information
                iLvl(i) = iNode;
                sFileL = sFileL.sFileD(iNode);
            end            
            
            % if the branch has not been setup, then create it
            if obj.addTreeBranch(jNodeP,sFileL)
                % retrieves the current scrollbar value
                val0 = obj.jSB.getValue();
                                
                % retrieves the current viewport position
                hView = obj.mTree.getParent;
                p0 = hView.getViewPosition();                
                
                % refreshes the tree
                pause(0.01); 
                obj.mTree.updateUI    
                hView.setViewPosition(p0);
                
                % resets the scrollbar back to the original value (using
                % updateUI will cause the scrollbar to be reset to 1)
                obj.jSB.setValue(val0)
            end
                            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- finds all files with the required file extension
        function fName = findFileAll(obj,snDir)

            % initialisations
            [fFileAll,fName] = deal(dir(snDir),[]);

            % determines the files that have the extension, fExtn
            fFile = dir(fullfile(snDir,sprintf('*%s',obj.fExtn)));
            if ~isempty(fFile)
                fNameT = cellfun(@(x)(x.name),num2cell(fFile),'un',0);
                fName = cellfun(@(x)(fullfile(snDir,x)),fNameT,'un',0);    
            end

            % determines if there are any sub-directories in the folder
            isDir = find(cellfun(@(x)(x.isdir),num2cell(fFileAll)));
            for j = 1:length(isDir)
                % if the sub-directory is valid then search for any files        
                i = isDir(j);
                if ~(strcmp(fFileAll(i).name,'.') || ...
                                            strcmp(fFileAll(i).name,'..'))        
                    fDirNw = fullfile(snDir,fFileAll(i).name);        
                    fNameNw = obj.findFileAll(fDirNw);
                    if ~isempty(fNameNw)
                        % if there are any matches, then add them to 
                        % the name array
                        fName = [fName;fNameNw];
                    end
                end
            end

        end                    
        
        % --- retrieves the branch information for level, iLvl
        function sFileL = getBranchInfo(obj,iLvl)
            
            sFileL = obj.sFileD;            
            for i = 2:length(iLvl)
                sFileL = sFileL.sFileD(iLvl(i));
            end
            
        end
        
    end
    
    % static class methods
    methods (Static)
    
        % --- adds a single dummy node to the parent node, hNodeP
        function hNodeP = addDummyNode(hNodeP)
            
            % imports the checkbox tree
            import com.mathworks.mwswing.checkboxtree.*                          
            hNodeP.add(DefaultCheckBoxNode(''));
            
        end        
    
    end    

end