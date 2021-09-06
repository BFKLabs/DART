% --- retireves the local commit history for the branch, lBr
function [gHist,ok] = getLocalCommitHistory(GF,lBr,gHistAll)

% retrieves the total git history struct (if not provided)
if ~exist('gHistAll','var')
    hFig = findall(0,'tag','figGitVersion');
    gHistAll = getappdata(hFig,'gHistAll');
end

% initialisations
ok = true;
mID = field2cell(gHistAll.master,'ID');

%
histStr = GF.gitCmd('local-working-commits',lBr,'master');
if isempty(histStr)
    % if no commits, then return and empty history array
    [gHist,ok] = deal([],false);
    return
elseif strContains(histStr,'fatal: unknown commit')
    % if branch does not exist, then return and empty history array
    [gHist,ok] = deal([],false);
    return 
else
    hGrp = cellfun(@(x)(strsplit(x(3:end))),strsplit(histStr,'\n'),'un',0);
end

% sets the history data based on the number of commits found
nCommit = length(hGrp);
if nCommit == 0
    % if no commits, then return and empty history array
    [gHist,ok] = deal([],false);
else
    % memory allocation
    gStr = struct('ID',[],'DateNum',[],'Comment',[]);
    gHist = repmat(gStr,nCommit+1,1);
    
    for i = 1:nCommit+1
        % retrieves strings for the current commit
        if i <= nCommit
            cStr = hGrp{i};
            gHist(i).ID = cStr{1};   
            gHist(i).Comment = strjoin(cStr(2:end));
        else
            gHist(i).ID = GF.gitCmd('get-merge-base','master',lBr);
            gHist(i).Comment = GF.gitCmd('get-commit-comment',gHist(i).ID);
        end
        
        % retrieves the commit date string
        dStr = GF.gitCmd('get-commit-date',gHist(i).ID);
        gHist(i).DateNum = datenum(dStr(1:end-6),'yyyy-mm-dd HH:MM:SS'); 
    end    
    
    % sorts the history struct by chronological order
    [~,iS] = sort(double(field2cell(gHist,'DateNum',1)),'descend');
    gHist = gHist(iS);
    
    % re-orders such that the master branch point is last
    lID = field2cell(gHist,'ID');
    iBP = cell2mat(cellfun(@(x)(find(strcmp(lID,x))),mID,'un',0));
    gHist = gHist([find(~setGroup(iBP,[length(gHist),1]));iBP]);
    
end
