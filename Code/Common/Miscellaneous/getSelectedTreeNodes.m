% --- retrieves the names of the selected tree nodes
function sNode = getSelectedTreeNodes(jRoot,sStr)

% sets the default input parameters
if nargin == 1; sStr = '.'; end

% initialisations
sNode = [];
nNode = jRoot.getChildCount;

for i = 1:nNode
    % retrieves the child node object
    jChild = jRoot.getChildAt(i-1);

    % retrieves the new string
    sStrTmp = strrep(char(jChild),'<html><b>','');
    sStrNw = sprintf('%s\\%s',sStr,sStrTmp);
    
    if jChild.isLeaf
        % if the child is a leaf node, then store the file name
        if strcmp(get(jChild,'SelectionState'),'selected')
            sNode{end+1} = sStrNw;
        end
    else
        % otherwise, search through the sub-directories
        sNodeNw = getSelectedTreeNodes(jChild,sStrNw);
        sNode = [sNode(:);sNodeNw(:)];
    end
end

