% --- appends the local working tree branch nodes to the explorer tree
function [hTree,isOK] = appendLocalWorkingTreeNodes(hFig,GF,hTree,mChng)

% initialisations
isOK = true;
hRoot = hTree.getRoot;
gHistAll = getappdata(hFig,'gHistAll');
cID = GF.gitCmd('commit-id');
mID = field2cell(gHistAll.master,'ID');

% retrieves the names of the local branches
lBr0 = strsplit(GF.gitCmd('all-branches'),'\n');
hasLW = cellfun(@(x)(startsWith(x(3:end),'LocalWorking')),lBr0);
lBr = cellfun(@(x)(x(3:end)),lBr0(hasLW),'un',0);

% if the current version is part of local branch, then
% retrieve the commits from this branch         
for i = 1:length(lBr)
    % retrieves the commit history for the 
    gHistL = getLocalCommitHistory(GF,lBr{i},gHistAll); 
    if isempty(gHistL)
        GF.gitCmd('delete-local',lBr{i});
    else
        lID = field2cell(gHistL,'ID');

        % updates the branch with the entire history
        cBrStr = strrep(lBr{i},'-','');
        gHistAll = setStructField(gHistAll,cBrStr,gHistL);

        % determines the master node the local-branch is under
        iSelM = find(strcmp(mID,lID{end}));
        if ~isempty(iSelM)
            % retrieves the main branch node
            hNodeM = hRoot.getChildAt(iSelM-1);
            hNodeM.setAllowsChildren(true)

            % adds the sub-nodes
            iSelL = (length(gHistL)-1) - (find(strcmp(lID,cID))-1);
            hNodeM = addTreeSubNodes(hNodeM,gHistL(end-1:-1:1),iSelL,iSelM);

            % determines if the last node added is the current commit
            if strcmp(lBr{i},GF.getCurrentBranch) && strcmp(gHistL(1).ID,cID)
                % if so, then determine if the code has changed
                codeDiff = GF.gitCmd('diff-commit',gHistL(1).ID);
                if ~isempty(codeDiff)
                    % retrieves the current last node
                    hNodePr = hNodeM.getChildAt(length(gHistL)-2);

                    % if so, then add another node to the tree
                    addUncommitedChngNode(hTree,hNodeM,hNodePr);                         
                end
            end

            % expands the node
            hTree.expand(hNodeM)
        end
    end
end

% if there is a change in the code off the master branch, then determine if
% an uncommitted branch node needs to be added
if mChng
    hNodeP = getSelectedNode(hTree.getRoot);
    if hNodeP.getChildCount == 0   
        % if the master node has no children, then create a new node
        addUncommitedChngNode(hTree,hNodeP,hNodeP);
        hTree.expand(hNodeP)
        
        % flags that an update is unneccessary
        isOK = false;
    end
end

% updates the git history struct
setappdata(hFig,'gHistAll',gHistAll);

% sets the mouse-press callback function
jTree = handle(hTree.getTree,'CallbackProperties');
set(jTree, 'MousePressedCallback', {@treeContextMenu,GF});

% repaints the explorer tree
hTree.repaint;

% -------------------------------------- %
% --- RIGHT-CLICK CALLBACK FUNCTIONS --- %
% -------------------------------------- %

% --- creates the uicontext menus for the explorer tree node
function jMenu = setupTreeContextMenus(hNode,GF,iType)

% memory allocation
hFig = findall(0,'tag','figGitVersion');

% menu labels
ignoreLbl = 'Ignore Local Changes';
rebaseLbl = 'Rebase On Master Branch';
hotfixLbl = 'Create Hot-Fix Branch';
copyLbl = 'Copy Local Working Branch';
renameLbl = 'Rename Current Commit';
% renameLbl = [];

% menu callback functions
ignoreFcn = @ignoreNodeChanges;
rebaseFcn = @rebaseMasterCommit;
hotfixFcn = @createHotfixBranch;
copyFcn = @copyLocalBranch;
renameFcn = @renameCurrentNode;
% renameFcn = [];

% creates the menu object
jMenu = javax.swing.JPopupMenu;
switch iType
    case 1
        % case is clicking on a master node (at least one commit)
        mStr = {'Delete Local-Working Branch'};
        cbFcn = {@deleteWorkingBranch};                                   

    case 2
        % case is clicking on the last LW node (changes)
        mStr = {'Commit Local Changes',ignoreLbl,[],hotfixLbl};
        cbFcn = {@commitLastNode,ignoreFcn,[],hotfixFcn};  

    case 3
        % case is clicking on the last LW node (no changes) 
        mStr = {'Delete Current Commit',renameLbl,[],copyLbl,rebaseLbl};
        cbFcn = {@deleteLastNode,renameFcn,[],copyFcn,rebaseFcn};  

    case 4
        % case is clicking on the non-last LW node
        mStr = {'Delete Subsequent Commits',ignoreLbl,renameLbl};
        cbFcn = {@deleteProceedingNodes,ignoreFcn,renameFcn};                 

    case 5
        % case is clicking on a master node (no commits)
        mStr = {ignoreLbl};
        cbFcn = {ignoreFcn};             

end

% updates the menu item labal
cMsg0 = retHTMLColouredStrings(char(hNode.getName));
cMsg = regexp(cMsg0,') - ','split');
cMsgNw = sprintf('<html><b>%s',cMsg{end});

% adds in the header row
jMenu.add(javax.swing.JMenuItem(cMsgNw)); 
jMenu.addSeparator;     

% adds all the context menu items
for j = 1:length(mStr)
    if isempty(mStr{j})
        jMenu.addSeparator;
    else
        mItem = javax.swing.JMenuItem(mStr{j});
        set(mItem,'ActionPerformedCallback',[cbFcn(j),{GF,hFig}]);
        jMenu.add(mItem);  
    end
end

% ------------------------------------- %
% --- MOUSE PRESS CALLBACK FUNCTION --- %
% ------------------------------------- %

% --- callback function for the right-click on the explorer tree panel
function treeContextMenu(hTree, evnt, GF)

% global variables
global hNode

% if not a right-click event then exit
if ~evnt.isMetaDown
    return 
end
    
% Get the clicked node
[clickX,clickY,jTree] = deal(evnt.getX,evnt.getY,evnt.getSource);
tPath = jTree.getPathForLocation(clickX, clickY);

% if there is no node selected, then exit the function
if ~isempty(tPath)
    % if a valid node was selected, then retrieve the context menu based on
    % the node type (and its state of the code)
    [ucStr,mOfs] = deal('Uncommited Changes',NaN);
    hNode = tPath.getLastPathComponent;
    if hNode.getLevel == 1
        % case is a master branch node (must have local working branch)
        switch hNode.getChildCount
            case 0
                % if no local working branch, then exit
                return
                
            case 1
                % if one branch, then determine determine if the node is
                % commited or not
                if strContains(hNode.getChildAt(0).getName,ucStr)
                    % it not, then use the ignore local changes item
                    iType = 5;
                    
                else
                    % otherwise, flag the removal of the local branch
                    iType = 1;
                end
                
            otherwise
                % otherwise, 
                iType = 1;
        end
        
    else
        % case is a local-working branch node
        uData = hNode.getUserObject;
        if strContains(hNode.getName,ucStr)
            % case is selecting the last LW node (with changes)
            iType = 2;
            
        elseif isempty(uData)
            % case is selecting the last LW node (without changes)
            iType = 3;            
            
        elseif hNode.getParent.getLeafCount == uData(2)
            % case is selecting the last LW node (without changes)
            iType = 3;
            
        else
            % case is selecting the non-last LW node
            iType = 4; 
            
            % removes the extraneous menu item
            if (hNode.getParent.getLeafCount-1) == uData(2)
                % case is the node is the 2nd to last node
                if strContains(hNode.getNextNode.getName,ucStr)
                    % if the next node is uncommited, then remove the
                    % delete commit menu item
                    mOfs = 2;
                else
                    % if the next node is commited, then remove the
                    % ignore changes menu item
                    mOfs = 3;
                end
            else
                % otherwise, remove the ignore changes menu item
                mOfs = 2;
            end
        end
        
    end
    
    % creates the menu item
    jMenu = setupTreeContextMenus(hNode,GF,iType);
    if ~isnan(mOfs)
        jMenu.remove(mOfs);
    end
    
    % Display the (possibly-modified) context menu
    jMenu.show(jTree, clickX, clickY);
    jMenu.repaint;
end

% --------------------------------------- %
% --- CONTEXT MENU CALLBACK FUNCTIONS --- %
% --------------------------------------- %

% --- commits the last nodes for a local-working branch
function commitLastNode(hObject, evnt, GF, hFig)

% global variables
global hNode

% prompts the user 
prompt = {'Enter commit message:'};
mStr = inputdlg(prompt,'',[1,50],{'New Commit'});

% if the commit message is empty then exit
if isempty(mStr)
    return
elseif isempty(mStr{1})
    return
end

% creates a loadbar
h = ProgressLoadbar('Committing Changes To Local Branch');

% initialisations
cBr = GF.getCurrentBranch;
gHistAll = getappdata(hFig,'gHistAll');

% creates a local commit for the working branch
if strcmp(cBr,'master')
    % retrieves the new local working branch name and 
    cBr = getNewBranchName(gHistAll);
    GF.gitCmd('create-local-detached',cBr);
else    
    % otherwise, determine if the new comment is the same as any previous
    cStrL = field2cell(getStructField(gHistAll,cBr),'Comment');
    if any(strcmp(cStrL,mStr{1}))
        % if so, delete the loadbar and output an error screen and exit
        delete(h)
        eStr = sprintf(['Error! The following comment message is ',...
                        'already present on this branch:',...
                        ':\n\n %s "%s"\n\nPlease try again with ',...
                        'a unique comment message.'],...
                        char(8594),mStr{1});
        waitfor(msgbox(eStr,'Non-Unique Comment Message','modal'))
       
        % exits the function
        return
    end
end

% changes are on the local working branch
GF.gitCmd('commit-all',mStr{1});

% retrieves the updated branch history
gHistL = getLocalCommitHistory(GF,cBr,gHistAll);

% updates the parameter struct
gHistAll = setStructField(gHistAll,strrep(cBr,'-',''),gHistL);
setappdata(hFig,'gHistAll',gHistAll)

% updates the node string
nC = length(gHistL)-1;
dStr = datestr(gHistL(1).DateNum,1);
nodeStr = sprintf('(#%i: %s) - %s',nC,dStr,gHistL(1).Comment); 
hNode.setName(setHTMLColourString('r',nodeStr))

% updates the node userdata field
uData = [hNode.getParent.getUserObject;hNode.getSiblingCount];
hNode.setUserObject(uData);

% repaints the tree
hTree = getappdata(hFig,'hTree');
hTree.reloadNode(hNode);
hTree.repaint();

% deletes the loadbar
delete(h)

% --- deletes the last nodes for a local-working branch
function deleteLastNode(hObject, evnt, GF, hFig)

% global variables
global hNode

% prompt the user if they want to continue with the node deletion
if ~promptUserChange()
    % if not, then exit
    return
end

% creates a loadbar
h = ProgressLoadbar('Deleting Local Branch Head Commit');

% initialisations
hTree = getappdata(hFig,'hTree');
gHistAll = getappdata(hFig,'gHistAll');
hNodeP = hNode.getParent;
iSel = hNode.getUserObject;

% retrieves the current branch and struct field names
cBr = GF.getCurrentBranch;
cBrStr = strrep(cBr,'-','');

% updates the history struct by removing the required fields
if iSel(2) == 1
    % if the current node is a branch point, then remove the branch
    gHistL = getStructField(gHistAll,cBrStr);
    gHistAll = rmfield(gHistAll,cBrStr);
else
    gHistAll = removeHistCommits(gHistAll,cBrStr,1);
    gHistL = getStructField(gHistAll,cBrStr);
end

% determines if the current node is the highlighted node
hNodeSel = getSelectedNode(hNode.getRoot);
if isequal(hNode,hNodeSel)
    % if so, then reset to a previous commit
    if iSel(2) == 1
        % if the current point is the branch point, then move to the master
        resetCommitPoint(GF,'master',gHistL(end).ID)
        hNodeNw = hNodeP;
    else
        % otherwise, move back 
        resetCommitPoint(GF,cBr,gHistL(1).ID)
        hNodeNw = hNode.getPreviousNode;
    end
    
    % resets the highlight colour to the new node
    updateTreeNode(hNode,'k')
    updateTreeNode(hNodeNw,'r')   
else
    % if not, then reset the local branch head
    cID0 = GF.gitCmd('commit-id');    
    if ~isempty(gHistL)
        % only reset the commit point if there are commits on the branch
        resetCommitPoint(GF,cBr,gHistL(1).ID)
    end
    
    % resets the commit point back to original
    if strcmp(cBr,'master')
        resetCommitPoint(GF,'master',cID0)
    else
        GF.gitCmd('checkout-version',cID0)
    end
end

% deletes the local working branch (if removing the branch point)
if iSel(2) == 1
    GF.gitCmd('delete-local',cBr)
end

% resets the total git history struct
setappdata(hFig,'gHistAll',gHistAll);

% removes the node from the history explorer tree
hNodeP.remove(hNode);
hTree.reloadNode(hNodeP);
hTree.repaint;

% deletes the loadbar
delete(h)

% --- deletes all the nodes (from a local working branch) past the selected
function deleteProceedingNodes(hObject, evnt, GF, hFig)

% global variables
global hNode

% prompt the user if they want to continue with the node deletion
if ~promptUserChange()
    % if not, then exit
    return
end

% creates a loadbar
h = ProgressLoadbar('Deleting Local Branch Commits');

% initialisations
hTree = getappdata(hFig,'hTree');
gHistAll = getappdata(hFig,'gHistAll');
hNodeP = hNode.getParent;
iSel = hNode.getUserObject;

% retrieves the current branch and struct field names
cBr = GF.getCurrentBranch;
cBrStr = strrep(cBr,'-','');

% updates the history struct by removing the required fields
nRmv = hNode.getSiblingCount - iSel(2);
gHistAll = removeHistCommits(gHistAll,cBrStr,nRmv);
gHistL = getStructField(gHistAll,cBrStr);

% retrieves the handles of the nodes to be removed
hNodeR = cell(nRmv,1);
hNodeR{1} = hNode.getNextNode;
for i = 2:nRmv
    hNodeR(i) = hNodeR{i-1}.getNextNode;
end

% determines if any of the nodes set for removal are highlighted
hNodeSel = getSelectedNode(hNode.getRoot);
if any(cellfun(@(x)(isequal(hNodeSel,x)),hNodeR))
    % if so, then reset to a previous commit
    resetCommitPoint(GF,cBr,gHistL(1).ID)
    hNodeNw = hNodeR{1}.getPreviousNode;
    
    % resets the highlight colour to the new node
    updateTreeNode(hNode,'k')
    updateTreeNode(hNodeNw,'r')   
else
    % only reset the branch head if there are commits on the branch
    cID0 = GF.gitCmd('commit-id');    
    if ~isempty(gHistL)
        resetCommitPoint(GF,cBr,gHistL(1).ID)
    end
    
    % resets the commit point back to original
    GF.gitCmd('checkout-version',cID0)
end

% resets the total git history struct
setappdata(hFig,'gHistAll',gHistAll);

% removes the nodes from the history explorer tree
cellfun(@(x)(hNodeP.remove(x)),hNodeR)
hTree.reloadNode(hNodeP);
hTree.repaint;

% deletes the loadbar
delete(h)

% --- deletes a local-working branch
function deleteWorkingBranch(hObject, evnt, GF, hFig)

% global variables
global hNode

% prompt the user if they want to continue with the node deletion
if ~promptUserChange()
    % if not, then exit
    return
end

% creates a loadbar
h = ProgressLoadbar('Deleting Local Branch');

% initialisations
iSel = hNode.getUserObject;
nNode = hNode.getChildCount;
hTree = getappdata(hFig,'hTree');
hNodeR = arrayfun(@(x)(hNode.getChildAt(x-1)),1:nNode,'un',0);

% retrieves the local working history struct
gHistAll = getappdata(hFig,'gHistAll');
[~,lBr,~] = getLocalWorkingHistory(gHistAll,hNode.getChildAt(0));
setappdata(hFig,'gHistAll',rmfield(gHistAll,lBr));

% determines if any of the of the nodes selected for removal 
hNodeS = getSelectedNode(hTree.getRoot);
if any(cellfun(@(x)(isequal(hNodeS,x)),hNodeR))
    % if so, then move the commit point back to the master branch
    resetCommitPoint(GF,'master',gHistAll.master(iSel).ID)
    updateTreeNode(hNode,'r')
end    

% deletes the local branch
lBrF = ['LocalWorking',lBr(13:end)];
GF.gitCmd('delete-local',lBrF);

% removes the nodes from the history explorer tree
cellfun(@(x)(hNode.remove(x)),hNodeR)
hNode.setAllowsChildren(false);
hTree.reloadNode(hNode);
hTree.repaint;

% deletes the loadbar
delete(h)

% removes the selection
versionHistSelect([], []) 

% --- ignores the local changes made on a branch/node
function ignoreNodeChanges(hObject, evnt, GF,hFig)

% global variables
global hNode

% prompt the user if they want to continue with the node deletion
if ~promptUserChange(1)
    % if not, then exit
    return
end

% creates a loadbar
h = ProgressLoadbar('Removing Uncommited Changes');

% initialisations
hTree = getappdata(hFig,'hTree');

% determines if the leaf node was selected
if hNode.isLeafNode
    % set the parent/removal nodes
    [hNodeP,hNodeR] = deal(hNode.getParent,hNode);
    if hNodeP.getChildCount == 1
        % case is the change is on the master branch
        updateTreeNode(hNodeP,'r')
    else
        % case is the change is on the local branch
        updateTreeNode(hNode.getPreviousNode,'r')
    end
else
    % set the parent/removal nodes
    [hNodeP,hNodeR] = deal(hNode,hNode.getChildAt(0));
    
    % updates the highlighted node
    updateTreeNode(hNodeP,'r')
end

% resets the commit point for the stated branch/commit ID
GF.gitCmd('ignore-local-changes');

% removes the node from the history explorer tree
hNodeP.remove(hNodeR);
hTree.reloadNode(hNodeP);
hTree.repaint;

% deletes the loadbar
delete(h)

% --- renames the current node
function renameCurrentNode(hObject, evnt, GF, hFig)

% global variables
global hNode

% initialisations
gHistAll = getappdata(hFig,'gHistAll');

% retrieves the local working history struct
[gHistL,lBr,iSelR] = getLocalWorkingHistory(gHistAll,hNode);

% prompts the user 
prompt = {'Enter new commit message:'};
mStr = inputdlg(prompt,'',[1,50],{gHistL(iSelR).Comment});

% if the commit message is empty then exit
if isempty(mStr)
    return
elseif isempty(mStr{1})
    return
end

% FINISH ME!
waitfor(msgbox('Finish Me!','modal'))

% resets the node name
hNode.setName(mStr{1});

% repaints the tree
hTree = getappdata(hFig,'hTree');
hTree.reloadNode(hNode);
hTree.repaint();

% --- merges the selected node with another master commit point
function rebaseMasterCommit(hObject, evnt, GF, hFig)

% global variables
global hNode

% initialisations
hRoot = hNode.getRoot;
hNodeP = hNode.getParent;
nModeM = hRoot.getChildCount;
nNodeP = hNodeP.getChildCount;
hTree = getappdata(hFig,'hTree');

% retrieves the master history struct
gHistAll = getappdata(hFig,'gHistAll');
gHistM = gHistAll.master;
mID0 = gHistM(hNodeP.getUserObject).ID;
[gHistL0,lBr,~] = getLocalWorkingHistory(gHistAll,hNode);

% determines the master commits that a) is not a parent of the current
% node, and B) does not have any local working branches
isOK = ~strcmp(field2cell(gHistM,'ID'),gHistL0(end).ID);
for i = 1:nModeM
    isOK(i) = isOK(i) && hRoot.getChildAt(i-1).getChildCount == 0;
end

% if there are no feasible master commits, then output an error message 
% to screen and exit the function
if ~any(isOK)
    % outputs the message to screen
    mStr = sprintf(['There are no feasible master branch commits to ',...
                'rebase onto.\nRetry after deleting the ',...
                'local working branch from at least one master commit.']);
    waitfor(msgbox(mStr,'No Feasible Rebase Points','modal'))
            
    % exits the function
    return
end

% prompts the user for the master commit they wish to branch from
iOK = find(isOK);
[gHistF,iSelM] = MasterMerge(gHistM(iOK),'Rebase');
if isempty(gHistF)
    % if the user cancelled, then exit the function
    return
else
    iSelM = iOK(iSelM);    
end

% creates a loadbar
h = ProgressLoadbar('Rebasing Code On Master Branch');

% rebases the code from the old node to the new
GF.gitCmd('rebase-onto',gHistF.ID,mID0);
GF.gitCmd('checkout-local',lBr);

% removes the nodes from the current master branch point
hNodeR = arrayfun(@(x)(hNodeP.getChildAt(x-1)),1:nNodeP,'un',0);
cellfun(@(x)(hNodeP.remove(x)),hNodeR)
hNodeP.setAllowsChildren(false)

% retrieves the master branch node at the rebase point
hNodeM = hTree.getRoot.getChildAt(iSelM-1);
hNodeM.setAllowsChildren(true)

% removes the highlight selection on the current node
updateTreeNode(getSelectedNode(hTree.getRoot),'k'); 
pause(0.05);

% adds the sub-nodes for the new branch
gHistL = getLocalCommitHistory(GF,lBr,gHistAll);
hNodeM = addTreeSubNodes(hNodeM,gHistL(end-1:-1:1),length(gHistL)-1,iSelM);
setappdata(hFig,'gHistAll',setStructField(gHistAll,lBr,gHistL))

% % resets the commit point to newly created branch
% resetCommitPoint(GF,cBr,gHistL(1).ID)

% reloads/expands the node and repaints the tree
hTree.reloadNode(hNodeP);
hTree.reloadNode(hNodeM);
hTree.expand(hNodeM)
hTree.repaint

% updates the version history selection
hNodeS = hTree.getSelectedNodes();
if isempty(hNodeS)
    versionHistSelect([],[])
else
    versionHistSelect(hTree,hNodeS(1),1)
end

% closes the loadbar
delete(h)

% --- creates a remote hot-fix branch 
function copyLocalBranch(hObject, evnt, GF, hFig)

% global variables
global hNode

% initialisations
hRoot = hNode.getRoot;
nModeM = hRoot.getChildCount;
gHistAll = getappdata(hFig,'gHistAll');

% retrieves the master history struct
gHistM = gHistAll.master;

% retrieves the local working history struct
gHistL0 = getLocalWorkingHistory(gHistAll,hNode);

% determines the master commits that a) is not a parent of the current
% node, and B) does not have any local working branches
isOK = ~strcmp(field2cell(gHistM,'ID'),gHistL0(end).ID);
for i = 1:nModeM
    isOK(i) = isOK(i) && hRoot.getChildAt(i-1).getChildCount == 0;
end

% if there are no feasible master commits, then output an error message 
% to screen and exit the function
if ~any(isOK)
    % outputs the message to screen
    mStr = sprintf(['There are no feasible master commits to create ',...
                'a copy of the local branch.\nRetry after deleting the ',...
                'local working branch from at least one master commit.']);
    waitfor(msgbox(mStr,'No Feasible Copy Points','modal'))
            
    % exits the function
    return
end

% prompts the user for the master commit they wish to branch from
iOK = find(isOK);
[gHistF,iSelM] = MasterMerge(gHistM(iOK),'Copy');
if isempty(gHistF)
    % if the user cancelled, then exit the function
    return
else
    iSelM = iOK(iSelM);
end

% creates a loadbar
h = ProgressLoadbar('Copying Local Working Branch');

% resets the commit point to the master branch point
resetCommitPoint(GF,'master',gHistF.ID)

% creates a new branch
cBr = getNewBranchName(gHistAll);
GF.gitCmd('create-local-detached',cBr);

% copies the selected commit to the new branch
nTot = 1;
for i = (length(gHistL0)-1):-1:1
    % copies the local commits to the new branch
    waitfor(GF.gitCmd('copy-local-commit',gHistL0(i).ID));
    
    % keeping pausing until the commit has been fully applied
    while 1        
        pause(0.25);
        nTotNw = GF.getLocalBranchCommitCount(cBr);        
        if nTot == nTotNw
            nTot = nTot + 1;
            break
        end
    end
end

% retrieves the main branch node
hTree = getappdata(hFig,'hTree');
hNodeM = hTree.getRoot.getChildAt(iSelM-1);
hNodeM.setAllowsChildren(true)

% removes the highlight selection on the current node
updateTreeNode(getSelectedNode(hTree.getRoot),'k'); 
pause(0.05);

% adds the sub-nodes for the new branch
cBrStr = strrep(cBr,'-','');
gHistL = getLocalCommitHistory(GF,cBr,gHistAll);
hNodeM = addTreeSubNodes(hNodeM,gHistL(end-1:-1:1),length(gHistL)-1,iSelM);
setappdata(hFig,'gHistAll',setStructField(gHistAll,cBrStr,gHistL))

% resets the commit point to newly created branch
resetCommitPoint(GF,cBr,gHistL(1).ID)

% reloads/expands the node and repaints the tree
hTree.reloadNode(hNodeM);
hTree.expand(hNodeM)
hTree.repaint

% updates the version history selection
hNodeS = hTree.getSelectedNodes();
versionHistSelect(hTree, hNodeS(1), 1)

% closes the loadbar
delete(h)

% --- creates a remote hot-fix branch 
function createHotfixBranch(hObject, evnt, GF, hFig)

% global variables
global hNode

% initialisations
sStr = 'tempHF';
hNodeP = hNode.getParent;
GM = getappdata(hFig,'GitMenu');
gHistAll = getappdata(hFig,'gHistAll');

% prompts the user for the hot-fix branch data
iData = GitHotfix(GM);
if isempty(iData)
    % if the user cancelled, then exit the function
    return
end

% determines if the the current branch is a local-working branch
cBr = GF.getCurrentBranch;
isLW = ~strcmp(cBr,'master');

% if the current branch is the local working branch, then determine the
% differences between the current code state and the master branch point.
% from checkout the branch point and apply the patch
if isLW       
    % creates a loadbar
    h = ProgressLoadbar('Determining Code Differences');
    
    % case is the current branch is the local-working branch
    iSelM = hNodeP.getUserObject;
    gHistL = getLocalCommitHistory(GF,cBr,gHistAll);
    [mID,lID] = deal(gHistAll.master(iSelM).ID,gHistL(end-1).ID);       
    
    % creates the temporary patch file of the differences between the
    % current state and the master branch-point (while ignoring and local
    % working branch changes)
    tFile = createMasterDiffPatch(GF,mID,lID);
    
    % stashes the current changes
    GF.gitCmd('stash-save',sStr)
    resetCommitPoint(GF,'master',mID)    
    GF.gitCmd('apply-patch',tFile);
    
    % creates the new hot-fix branch
    GM.GitBranch.createNewHotfixBranch(iData,h);
    
    % returns to the original point in the local-working branch (ignores
    % changes on master, checkout local branch and unstash changes)
    GF.gitCmd('ignore-local-changes');
    resetCommitPoint(GF,cBr,lID)
    GF.gitCmd('stash-pop',GF.detStashListIndex(sStr)-1)
    
else
    % if the master branch, then create a hot-fix branch from current
    GM.GitBranch.createNewHotfixBranch(iData);    
end

% ----------------------- %
% --- OTHER FUNCTIONS --- %
% ----------------------- %

% --- resets to a specific commit point
function resetCommitPoint(GF,brStr,cID)

% resets the commit point based on the branch/commit ID
if strcmp(brStr,'master')
    % case is resetting the master branch
    cIDhead = GF.gitCmd('branch-head-commits',brStr);
    if startsWith(cID,cIDhead)
        % case is resetting to the master head commit
        GF.gitCmd('checkout-local',brStr);
    else
        % case is resetting to a non-master head commit
        GF.gitCmd('checkout-version',cID)
    end
else
    % case is resetting on the local branch
    GF.gitCmd('checkout-local',brStr);
    GF.gitCmd('hard-reset',cID);
end

% --- removes the first iRmv entries from a given branches history
function gHistAll = removeHistCommits(gHistAll,cBr,iRmv)

% updates the local working branch history struct
gHist = getStructField(gHistAll,cBr);
gHist = gHist((iRmv+1):end);

% updates the total history struct
gHistAll = setStructField(gHistAll,cBr,gHist);

% --- adds an uncommited change node at hNodePr
function addUncommitedChngNode(hTree,hNodeM,hNodePr)

% ensures the master node allows children
hNodeM.setAllowsChildren(true)

% creates the new node off the master node
nodeStr = 'Uncommited Changes*';
hNodeNw = uitreenode('v0', nodeStr, nodeStr, [], true);
hNodeNw.setUserObject([]);
hNodeM.add(hNodeNw);

% resets the tree-node colour scheme
updateTreeNode(hNodeNw,'r');
updateTreeNode(hNodePr,'k'); 
hTree.repaint  

% --- prompts the user if they with to continue with the deletion
function isChng = promptUserChange(varargin)

% sets the question dialog prompt/title strings
if nargin == 0
    % case is node deletion
    tStr = 'Continue Deletion?';
    qStr = 'Are you sure you want to continue with deletion?';
else
    % case is ignoring local changes
    tStr = 'Ignore Change?';
    qStr = 'Are you sure you want to ignore the local changes?';
end

% prompts the user if they wish to continue with node deletion
uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
isChng = strcmp(uChoice,'Yes');

% --- retrieves the new local working branch name
function cBrNw = getNewBranchName(gHistAll)

% initialisations
lBrStr = 'LocalWorking';

% determines how many local working branches exist
fStr = fieldnames(gHistAll);
isLW = strContains(fStr,lBrStr);

% sets the new branch name (depending on the number of existing branches)
if ~any(isLW)
    % case is there are currently no local working branches
    iBr = 1;
    
else
    % case is there is at least one existing working branch (determine the
    % index of the next available local working branch)
    iBrS = cellfun(@(x)(x((length(lBrStr)+1):end)),fStr(isLW),'un',0);
    iBr0 = [0;sort(cellfun(@str2double,iBrS))];
    
    % determines the next non-contiguous index
    iBr = iBr0(find(diff(iBr0(:)) > 1,1,'first'))+1;
    if isempty(iBr)
        iBr = sum(isLW)+1;
    end
end

% sets the final branch string
cBrNw = sprintf('%s%i',lBrStr,iBr);
