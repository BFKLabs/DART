% --- resets the repository branches
function resetRepoBranches(handles,vID)

% retrieves the git branch object
GF = getappdata(handles.figGitVersion,'GitFunc');
GB = getappdata(handles.figGitVersion,'GitBranch');
localBr = getappdata(handles.figGitVersion,'localBr');

% determines if there is a difference between latest/current
codeDiff = GF.gitCmd('diff-commit',vID);

% determines if there is a difference with the last commit
needStash = ~isempty(codeDiff);
if needStash
    % if so, then stash the differences
    GF.gitCmd('stash-save',localBr);
end

% updates to the required commit
GB.resetMasterBranch();

% % deletes the local branch
% if GB.isLocalBranch(localBr)    
%     GF.gitCmd('delete-local',localBr);
% end

% creates a new local branch for the working directory
GF.gitCmd('create-local-detached',localBr);

% create local working branch branching from the flagged commit (if reqd)
if needStash    
    % determines the index of the stash branch from above
    iList = GF.detStashListIndex(localBr);
    if ~isempty(iList)
        GF.resolveStashPop(iList-1);        
    end
end

% creates a local commit for the working branch
GF.gitCmd('commit-all','Branch Point')