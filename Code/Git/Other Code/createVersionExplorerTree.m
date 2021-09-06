% --- creates the GitVersion explorer tree
function [hTree,iCurr] = createVersionExplorerTree(handles,GF,gHist,cID)

% retrieves the current commit ID (if not provided)
if isnan(cID); cID = GF.gitCmd('commit-id'); end

% initialisations
rStr = 'PROGRAM VERSIONS';
[hPanel,hFig] = deal(handles.panelVerHist,handles.figGitVersion);

% retrieves the ID of the current commit, and determines if there are any
% matches within the current filter 
isMatch = strcmp(field2cell(gHist,'ID'),cID);
if any(isMatch)
    iCurr = find(isMatch);
else
    iCurr = -1;    
end

% sets the tree position vector
fPos = get(handles.figGitVersion,'position');
pPos = get(hPanel,'position');
tPos = [pPos(1)+20,fPos(4)-(pPos(4)-13),pPos(3)-20,pPos(4)-50];

% removes any existing trees
hTreeOld = getappdata(handles.figGitVersion,'hTree');
if ~isempty(hTreeOld); delete(hTreeOld); end
setappdata(handles.figGitVersion,'hTree',[])

% Root node
wState = warning('off');
hRoot = uitreenode('v0', rStr, rStr, [], false);
set(0,'CurrentFigure',hFig);
warning(wState);

% adds the tree sub-nodes
hRoot = addTreeSubNodes(hRoot,gHist,iCurr);

% creates the tree object
hTree = uitree('v0','parent',hPanel,'Root',hRoot,'position',tPos,...
               'SelectionChangeFcn',@versionHistSelect);
hTree.expand(hRoot)