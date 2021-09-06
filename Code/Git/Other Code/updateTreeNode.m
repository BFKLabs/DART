% --- updates the tree node branch, hNode, to the colour nCol
function updateTreeNode(hNode,nCol)

% if there is no node, then exit
if isempty(hNode); return; end

% resets the coloured string for the node
nStr0 = retHTMLColouredStrings(char(hNode.getName)); 
hNode.setName(setHTMLColourString(nCol,nStr0)); 