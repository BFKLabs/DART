function [gHistL,lBr,iSelR] = getLocalWorkingHistory(gHistAll,hNode)

% initialisations
[gHistL,lBr,iSelR] = deal([]);

% retrieves the user object
iSel = hNode.getUserObject;
if isempty(iSel)
    return
else
    mID = gHistAll.master(iSel(1)).ID;
end

% retrieves the names of the local-working branches
fStr = fieldnames(gHistAll);
fStr = fStr(strContains(fStr,'LocalWorking'));
gHistL0 = cellfun(@(x)(getStructField(gHistAll,x)),fStr,'un',0);
iM = cellfun(@(x)(find(strcmp(field2cell(x,'ID'),mID))),gHistL0,'un',0);

% determines the local branch that contains the master branch commit id
isL = ~cellfun(@isempty,iM);
if any(isL)
    % if there is match then return the require field values
    [gHistL,lBr] = deal(gHistL0{isL},fStr{isL});
    iSelR = length(gHistL) - (iSel(2)-1);
end