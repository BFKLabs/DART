% --- retrieves the git history for the selected node
function [gHist,bStr,iSel] = getUserGitHistory(hFig,iSel)

% retrieves the main git-history data struct
gHistAll = getappdata(hFig,'gHistAll');
[gHist,bStr] = deal(gHistAll.master(iSel(1)),'master');

% if a local branch is selected, then determine which one (returns the git
% history struct for this branch)
if length(iSel) > 1
    % retrieves the names of the local-working branches
    lBrS = 'LocalWorking';
    fStr = fieldnames(gHistAll);
    fStr = fStr(strContains(fStr,lBrS));
    
    % retrieves the git histories of these local branches
    mID = gHist.ID;
    gHistL = cellfun(@(x)(getStructField(gHistAll,x)),fStr,'un',0);
    iM = cellfun(@(x)(find(strcmp(field2cell(x,'ID'),mID))),gHistL,'un',0);
    
    % retrieves the matching local branch git history
    isL = ~cellfun(@isempty,iM);
    if any(isL)
        iSel(2) = length(gHistL{isL})-iSel(2);    
        if (iSel(2) > length(gHistL{isL})) || (iSel(2) == 0)
            [gHist,bStr,iSel] = deal([]);
        else
            gHist = gHistL{isL}(iSel(2));
            bStr = sprintf('%s%s',lBrS,fStr{isL}((length(lBrS)+1):end));
        end
    else
        % no commits for this current node
        [gHist,bStr,iSel] = deal([]);
    end
end