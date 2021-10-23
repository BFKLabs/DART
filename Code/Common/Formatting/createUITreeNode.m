function hNode = createUITreeNode(hNode,nodeStr,imgStr,isLeaf)

% removes the warning
wState = warning('off','all');

% creates the node object
hNode = uitreenode('v0',hNode,nodeStr,imgStr,isLeaf);

% resets the warnings
warning(wState);