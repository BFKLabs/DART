% --- adds the tree subnodes to the root node, hRoot
function hRoot = addTreeSubNodes(hRoot,gHist,iCurr,iSelM)

% creates the tree nodes for each of the commits
for i = 1:length(gHist)
    % sets the new node string
    dStr = datestr(gHist(i).DateNum,1);    
    
    % sets the merge flag
    if isfield(gHist(i),'isMerge')
        isMerge = gHist(i).isMerge;
    else
        isMerge = false;
    end
    
    % sets the node string
    if isMerge
        nStr = sprintf('(#%i: %s) - %s',i,dStr,gHist(i).Comment);
        nodeStr = setHTMLColourString('b',nStr);
    else
        nodeStr = sprintf('(#%i: %s) - %s',i,dStr,gHist(i).Comment);    

        % highlights red if the current version
        if i == iCurr
            nodeStr = setHTMLColourString('r',nodeStr);
        end
    end
        
    % sets the node user data
    if exist('iSelM','var')
        uData = [iSelM,i];
    else
        uData = i;
    end
    
    % creates the new node and adds it to the tree
    hNode = uitreenode('v0', nodeStr, nodeStr, [], true);
    hNode.setUserObject(uData);
    hRoot.add(hNode);
end