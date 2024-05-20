classdef FuncDiagnosticTree < handle
    
    % class properties
    properties
        
        % main class fields
        ffObj
        snTot
        pDataT
        hPanel
        hPanelF
        
        % explorer tree fields
        sNode
        hRoot
        hTreeF 
        mTreeF
        jTreeF
        jCompF
        hNodeLS
        
        % index/mapping array fields
        iCG
        indS
        indF
        Imap
        ImapU
        
        % selected function fields
        iFcn
        useF
        iRowF
        fData0
        
        % position vector/other cell array fields
        tPos
        pPos
        fcnName     
        extnSelectFcn
        
        % other scalar/string fields
        dX = 10;  
        fSz = 9;
        nType = 2;        
        isInit = true;
        useSubGrp = false;        
        sScope = {'I','S','M'};        
        rootStr = 'FILTERED FUNCTION LIST';
        sType = {'Individual','Single Experiment','Multiple Experiments'};
  
        % old version flag
        isOldVer      
        
    end
    
    % class methods
    methods
    
        % --- class constructor
        function obj = FuncDiagnosticTree(ffObj,hPanel,pDataT,snTot)
            
            % sets the input arguments
            obj.ffObj = ffObj;
            obj.hPanel = hPanel;
            obj.pDataT = pDataT;
            obj.snTot = snTot;
            
            % sets the old-version flag
            obj.isOldVer = ffObj.isOldVer;
            
            % initialises the class fields and explorer tree
            obj.initClassFields();
            
            if obj.isInit
                % initialises the explorer tree                
                obj.setupExplorerTree();
    
                % sets up the selected node indices
                [obj.fData0,obj.iFcn] = obj.getCurrentSelectedNodes();
                obj.useF = cellfun(@(x)(true(length(x),1)),obj.iFcn,'un',0);
                
                % sets the indices of the 
                N = cellfun(@length,obj.useF);
                NT = cumsum([0,N(1:(end-1))]);
                obj.iRowF = arrayfun(@(x,y)(y+(1:x)),N,NT,'un',0);
                
                obj.isInit = false;
            end
            
        end

        % --------------------------------------------- %
        % --- CLASS OBJECT INITIALISATION FUNCTIONS --- %
        % --------------------------------------------- %        
        
        % --- initialises the class fields
        function initClassFields(obj)                        
            
            % removes multi-expt fields (if single expt)
            if length(obj.snTot) == 1            
                obj.sType = obj.sType(1:end-1);                
                obj.sScope = obj.sScope(1:end-1);                
            end            
            
            % initialisations
            A = cell(length(obj.sScope),1);
            obj.pPos = get(obj.hPanel,'Position');                                    
            obj.tPos = [obj.dX*[1,1],obj.pPos(3:4)-2*obj.dX];   
            [obj.ImapU,obj.iCG,obj.indF,obj.indS,obj.fcnName] = deal(A);
            
            % sets up the mapping indices
            for pInd = 1:length(obj.sType)
                obj.setupMappingIndices(pInd);
            end            
            
        end        
        
        % --- sets up the analysis function mapping indices
        function setupMappingIndices(obj,pInd)
                        
            % retrieves the requirement fields for each feasible function
            rFld = fieldnames(obj.ffObj.rGrp);
            obj.indS{pInd} = find(any(obj.ffObj.cmpData,2));                        
            obj.fcnName{pInd} = obj.ffObj.fcnData(obj.indS{pInd},1);            
            X = obj.ffObj.fcnData(obj.indS{pInd},3:end);
            
            % retrieves the currently selected nodes
            obj.sNode = obj.ffObj.getSelectedNodes();
            sFld = fieldnames(obj.sNode);
            
            % loops through each of the feasible functions mapping them to 
            % their location within the plot data struct
            obj.Imap = NaN(size(X));
            iCol = cellfun(@(x)(find(strcmp(rFld,x))),sFld) - 1;
            for i = 1:length(sFld)
                % retrieves the node field
                sNodeS = getStructField(obj.sNode,sFld{i});
                
                % sets the mapping values
                for k = 1:length(sNodeS)
                    obj.Imap(strcmp(X(:,iCol(i)),sNodeS{k}),iCol(i)) = k;
                end
            end            
            
            % determines the unique mappings
            obj.indF{pInd} = find(~any(isnan(obj.Imap(:,iCol)),2));
            [obj.ImapU{pInd},~,iC] = ...
                unique(obj.Imap(obj.indF{pInd},iCol),'rows');            
            obj.iCG{pInd} = arrayfun(@(x)(find(iC == x)),1:max(iC),'un',0);                                
            
        end        
        
        % ------------------------------------- %
        % --- EXPLORER TREE SETUP FUNCTIONS --- %
        % ------------------------------------- %
        
        % --- sets up the function explorer tree
        function setupExplorerTree(obj,useScope)
            
            % initialisations
            wState = warning('off','all');
            if ~exist('useScope','var')
                useScope = true(1,length(obj.sScope));
            end
            
            % deletes any previous explorer trees
            hTreePr = findall(obj.hPanel,'Type','uicheckboxtree');
            if ~isempty(hTreePr); delete(hTreePr); end     
            
            % exits if there are no valid values
            pIndT = find(useScope(:)');            
            if isempty(pIndT); return; end
            
            % imports the checkbox tree
            if obj.isOldVer
                obj.hTreeF = [];
            else
                obj.hTreeF = uitree(obj.hPanel,'CheckBox','Position',...
                    obj.tPos,'FontWeight','Bold','FontSize',obj.fSz);
            end
            
            % creates the tree root node
            for pInd = pIndT
                % determines the experiment compatibility
                obj.ffObj.detExptCompatibility(obj.sScope{pInd});
                obj.setupMappingIndices(pInd);
            end
                
            % creates the root tree node
            obj.ImapU(~useScope) = {[]};
            obj.hRoot = obj.createTreeNode(obj.hTreeF,obj.rootStr);
            for pInd = find(~cellfun(@isempty,obj.ImapU)')       
                % creates the function scope root node
                obj.setupScopeBranch(pInd)
            end
                        
            % expands the explorer tree (new version only)
            if obj.isOldVer
                % checkbox tree import
                import com.mathworks.mwswing.checkboxtree.*                  
                
                % creates the final tree explorer object
                obj.hTreeF = com.mathworks.mwswing.MJTree(obj.hRoot);
                jTreeCB = handle(CheckBoxTree(obj.hTreeF.getModel),...
                                              'CallbackProperties');
                jSP = com.mathworks.mwswing.MJScrollPane(jTreeCB);

                % creates the scrollpane object
                objP = get(obj.hPanel,'position');
                tPosSP = [obj.dX-[1 0],objP(3:4)-2*obj.dX];
                [~,~] = createJavaComponent(jSP,tPosSP,obj.hPanel);  
                
                % sets the tree structure mouse click callback function 
                set(jTreeCB,'MouseClickedCallback',@obj.treeSelectChng);
                
            else           
                if obj.isInit
                    obj.hTreeF.CheckedNodes = obj.hRoot;
                else
                    hNodeS = [];
                    for i = 1:length(pIndT)
                        % retrieves the parent node of the group type
                        j = pIndT(i);
                        tStrP = sprintf('Function Scope = %s',obj.sType{j});
                        hNodeSP = findall(obj.hTreeF,'Text',tStrP);

                        % determines if there are nodes for the indices
                        iFcnNw = obj.iFcn{j}(obj.useF{j});
                        hNode0 = arrayfun(@(x)(findall(hNodeSP,...
                                        'UserData',x)),iFcnNw,'un',0);
                        
                        % if there are valid nodes, then add them to the 
                        % selected node list            
                        isNode = cellfun(@(x)(isa(x,...
                            'matlab.ui.container.TreeNode')),hNode0);
                        if any(isNode)
                            hNodeNw = arrayfun(@(x)(findall(...
                                hNodeSP,'UserData',x)),iFcnNw(isNode));                        
                            hNodeS = [hNodeS;hNodeNw(:)];
                        end
                    end
                    
                    % sets the nodes
                    obj.hTreeF.CheckedNodes = hNodeS(:);
                end
                    
                expand(obj.hTreeF,'All');
                uistack(obj.hPanelF,'top')                
                set(obj.hTreeF,'CheckedNodesChangedFcn',@obj.treeSelectChng)
            end
            
            % ensures the function filter is always on top            
            warning(wState);            
            
        end       
        
        % --- sets up the analysis function scope branch
        function setupScopeBranch(obj,pInd)
            
            % creates the function scope root node
            pStr = sprintf('Function Scope = %s',obj.sType{pInd});
            hRootF = obj.createTreeNode(obj.hRoot,pStr);

            % sets the scope root node as the parent (if not grouping)
            if ~obj.useSubGrp; hNodeP = hRootF; end

            % case is grouping function by sub-type
            for i = 1:size(obj.ImapU{pInd},1)
                % creates the tree parent node
                if obj.useSubGrp
                    hNodeP = obj.createTreeParent(hRootF,obj.ImapU{pInd}(i,:));
                end

                % adds the leaf nodes for each of the functions
                indC = obj.indF{pInd}(obj.iCG{pInd}{i});
                for j = 1:length(indC)
                    % retrieves the function name/index
                    fcnNameNw = obj.fcnName{pInd}{indC(j)};
                    iFcnM = obj.ffObj.Imap(obj.indS{pInd}(indC(j)),pInd);

                    % creates the new tree node
                    hNodeNw = obj.createTreeNode(hNodeP,fcnNameNw);
                    if ~obj.isOldVer
                        hNodeNw.UserData = iFcnM;
                    end
                end
            end           
            
        end
        
        % --- creates the tree parent node
        function hNodeP = createTreeParent(obj,hNodeP,ImapU)
            
            % initialisations
            fStr = fieldnames(obj.sNode);
            
            %
            for i = 1:length(ImapU)
                % retrieves the struct field
                isAdd = true;
                fVal = getStructField(obj.sNode,fStr{i});
                
                % determines if the parent node has any 
                if obj.isOldVer
                    hasChild = hNodeP.getChildCount > 0;
                else
                    hasChild = ~isempty(hNodeP.Children);
                end
                
                % determines if a new
                if hasChild
                    % retrieves the names of the children nodes
                    if obj.isOldVer
                        xiC = (1:hNodeP.getChildCount)' - 1;
                        hNodeC = cell2mat(arrayfun(@(x)...
                            (hNodeP.getChildAt(x)),xiC,'un',0));
                        nodeName = arrayfun(@char,hNodeC,'un',0);
                    else
                        hNodeC = hNodeP.Children;
                        nodeName = arrayfun(@(x)(x.Text),hNodeC,'un',0);
                    end
                    
                    % determines the overlapping parent nodes
                    nStrPr = obj.getNodeString(fStr{i},fVal{ImapU(i)});
                    hasC = strContains(nodeName,nStrPr);
                    
                    % determines if there is a match
                    if any(hasC)
                        % if so, then update the parent node
                        [hNodeP,isAdd] = deal(hNodeC(hasC),false);
                    end
                end
                
                % creates the new tree node (if required)
                if isAdd
                    % sets up the node string
                    nodeStr = obj.getNodeString(fStr{i},fVal{ImapU(i)});
                    
                    % creates the new node
                    hNodeNw = obj.createTreeNode(hNodeP,nodeStr);
                    if ~obj.isOldVer
                        hNodeNw.UserData = fVal{ImapU(i)};
                    end
                    
                    % resets the parent node
                    hNodeP = hNodeNw;
                end
            end
        
        end                                              
        
        % -------------------------------- %
        % --- EVENT CALLBACK FUNCTIONS --- %
        % -------------------------------- %                     
        
        % --- tree update callback function
        function treeSelectChng(obj, ~, evnt)
            
            if obj.isOldVer
                obj.hNodeLS = getSelectedTreeNodes(obj.hRoot);
            else
                obj.hNodeLS = evnt.LeafCheckedNodes;                 
            end

            % determines the currently selected nodes
            [~,iSelN] = obj.getCurrentSelectedNodes();
            
            % resets the selection flags
            obj.useF = cell(1,length(iSelN));
            for i = 1:length(obj.useF)
                [~,iA] = intersect(obj.iFcn{i},iSelN{i});
                obj.useF{i} = setGroup(iA,[length(obj.iFcn{i}),1]);
            end
            
            if ~isempty(obj.extnSelectFcn)
                feval(obj.extnSelectFcn)
            end
            
        end          
        
        % ------------------------------------- %
        % --- SELECTED NODE INDEX FUNCTIONS --- %
        % ------------------------------------- %        
        
        % --- retrieves the indices of the currently selected nodes
        function [fStrS,iSel] = getCurrentSelectedNodes(obj)
            
            % memory allocation
            iSel = cell(size(obj.sScope));
            
            % retrieves the selected node information
            pFld = fieldnames(obj.pDataT);
            
            %
            if obj.isOldVer
                fStrS = obj.getBranchSelectedNodes(obj.hRoot,1);
            else                
                % retrieves all the selected leaf nodes
                hNodeC = obj.hTreeF.CheckedNodes;
                isLeaf = arrayfun(@(x)(isempty(x.Children)),hNodeC);
                
                if any(isLeaf)
                    % retrieves all the selected leaf nodes
                    hNodeCL = hNodeC(isLeaf);                    
                    
                    % sets the function info (if leaf nodes)
                    fStr = arrayfun(@(x)(x.Text),hNodeCL,'un',0);
                    sStr = arrayfun(@(x)(obj.getScopeType...
                        (obj.getSubRootNode(x))),hNodeCL,'un',0);
                    fStrS = [fStr(:),sStr(:)];
                else
                    % case is there are no matches
                    fStrS = [];
                end
            end
            
            % if there are no selections, then exit
            if isempty(fStrS)
                return
            end
            
            % determines indices the functions wrt the plot data struct
            for i = 1:length(iSel)
                % determines the matching functions for the current scope
                ii = strcmp(fStrS(:,2),obj.sScope{i});
                if any(ii)
                    % retrieves the function info for the analysis scope
                    pData = getStructField(obj.pDataT,pFld{i});
                    fNameP = field2cell(pData,'Name');
    
                    % determines the indices of the selected functions
                    % within the plotting data struct
                    iSel{i} = cellfun(@(x)...
                        (find(strcmp(fNameP,x))),fStrS(ii,1));                  
                end
            end
                            
        end        
        
        % --- retrieves the indices of the selected nodes on the branch
        function fStrS = getBranchSelectedNodes(obj,hNodeP,iLvl)
            
            % retrieves the children node objects
            fStrS = [];
            xiC = (1:hNodeP.getChildCount)'; 
            hNodeC = arrayfun(@(x)(hNodeP.getChildAt(x-1)),xiC,'un',0);
            
            % retrieves the selection state of the nodes
            sState = cellfun(@(x)(char...
                                (x.getSelectionState())),hNodeC,'un',0);
                            
            % retrieves the selected nodes/directory indices
            isSel = ~strcmp(sState,'not selected');
            if ~any(isSel)
                % if nothing is selected then exit the function
                return
            else
                hNodeC = hNodeC(isSel);
            end
            
            % retrieves the indices of the selected files
            isDir = ~cellfun(@(x)(x.isLeaf()),hNodeC);            
            if any(~isDir)
                % sets the function info (if leaf nodes)
                fStr = cellfun(@(x)(char(x)),hNodeC(~isDir),'un',0);
                sStr = cellfun(@(x)(obj.getScopeType...
                    (getArrayVal(x.getPath,2))),hNodeC(~isDir),'un',0);                
                fStrS = [fStr(:),sStr(:)];
            end
            
            % determines if any directory nodes have been selected
            iSelD = find(isDir);
            if ~isempty(iSelD)            
                % if so, then retrieve the indices of the selected nodes
                % from each of the selected nodes
                fStrNw = cell(size(isDir));                        
                for i = iSelD(:)'
                    uD = [iLvl,i];
                    fStrNw{i} = obj.getBranchSelectedNodes(hNodeC{i},uD);
                end
                
                % appends the selected indices
                fStrS = [fStrS;cell2cell(fStrNw)];
            end
            
        end        
        
        % --- retrieves the function scope type string
        function sType = getScopeType(obj,sStr)
            
            % initialisations            
            iType = cellfun(@(x)(strContains(sStr,x)),obj.sType);
            
            % returns the scope type string
            sType = obj.sScope{iType};

        end        
  
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %         
        
        % --- retrieves the explorer tree node for the iExp
        function expandExplorerTreeNodes(obj)
                        
            % expands the explorer tree based on the tree type     
            if obj.nType == 1
                % retrieves the root node
                hRootT = obj.hTreeF.getRoot;
                for i = 1:hRootT.getRoot.getLeafCount
                    % sets the next node to search for
                    if i == 1
                        % case is from the root node
                        hNodeP = hRootT.getFirstLeaf;
                    else
                        % case is for the other nodes
                        hNodeP = hNodeP.getNextLeaf;
                    end

                    % retrieves the selected node
                    obj.hTreeF.expand(hNodeP.getParent);
                end  
            else
                %
                expand(obj.hTreeF,'all');
            end
            
        end                
        
        % --- creates the tree node (dependent on type)
        function hNode = createTreeNode(obj,hP,pStr)

            % imports the checkbox tree  
            if obj.isOldVer
                % checkbox tree import
                import com.mathworks.mwswing.checkboxtree.*                                
                hNode = DefaultCheckBoxNode(pStr);                                
                hNode.setSelectionState(SelectionState.SELECTED);
                
                if ~isempty(hP)
                    hP.add(hNode);
                end
            else
                % case is the newer matlab version object
                hNode = uitreenode(hP,'Text',pStr);
            end
            
        end                
        
    end
    
    % static class methods
    methods (Static)
        
        % --- sets up the tree node string
        function nodeStr = getNodeString(fStr,fVal)
            
            switch fStr
                case 'Dur'
                    % case is the duration requirement
                    switch fVal
                        case 'Short'
                            % case is short expts only
                            nodeStr = 'Short Experiment Functions';
                            
                        case 'Long'
                            % case is long expts only
                            nodeStr = 'Long Experiment Functions';
                            
                        case 'None'
                            % case is duration independent
                            nodeStr = 'Duration Independent Functions';
                    end
                    
                case 'Shape'
                    % case is the experiment shape requirement
                    switch fVal
                        case '1D'
                            % case is 1D expts
                            nodeStr = 'General 1D Functions';
                            
                        case '2D'
                            % case is 2D expts
                            nodeStr = 'General 2D Functions';
                            
                        case '2D (Circle)'
                            % case is 2D Circle expts
                            nodeStr = '2D (Circle) Functions';
                            
                        case '2D (General)'
                            % case is 2D General shape expts
                            nodeStr = '2D (General) Functions';
                            
                        case 'None'
                            % case is shape independent
                            nodeStr = 'Shape Independent Functions';
                    end
                    
                case 'Stim'
                    % case is the duration requirement
                    switch fVal
                        case 'Motor'
                            % case is motor stimuli expts
                            nodeStr = 'Motor Stimuli Functions';
                            
                        case 'Opto'
                            % case is opto stimuli expts
                            nodeStr = 'Opto Stimuli Functions';
                            
                        case 'None'
                            % case is stimuli independent expts
                            nodeStr = 'Stimuli Independent Functions';
                    end
                    
                case 'Spec'
                    % case is special experiments
                    switch fVal
                        case 'MT'
                            % case is multi-tracking
                            nodeStr = 'Multi-Tracking';
                            
                        case 'None'
                            % case is duration independent
                            nodeStr = 'Non-Speciality Functions';
                    end
                    
            end
            
        end                   
        
        % --- retrieves the name of the sub-root node
        function rNodeStr = getSubRootNode(hNode)
            
            while isa(hNode.Parent,'matlab.ui.container.TreeNode')
                rNodeStr = hNode.Text;
                hNode = hNode.Parent;
            end
            
        end        
        
    end    
    
end