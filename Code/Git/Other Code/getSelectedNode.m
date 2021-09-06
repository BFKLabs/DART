function hNode = getSelectedNode(hRoot,varargin)

% initialisations
hNode = [];

% if the tree root node has been selected, then exit
if nargin == 1
    if nodeIsHighlighted(hRoot)
        return
    end
end

% loops through all the children nodes determinining if any are highlighted
for i = 1:hRoot.getChildCount
    % retrieves the next node off the main branch
    hNodeNw = hRoot.getChildAt(i-1);
    if nodeIsHighlighted(hNodeNw)
        % if highlighted, then exit the function
        hNode = hNodeNw;
        return
    else
        % otherwise, determine if any of the sub-nodes are highlighted
        hNodeL = getSelectedNode(hNodeNw,1);
        if ~isempty(hNodeL)
            hNode = hNodeL;
            return
        end
    end
end

% --- determines if current node is highlighted
function isSel = nodeIsHighlighted(hNode)

isSel = strContains(hNode.getName,'<font color="red">');