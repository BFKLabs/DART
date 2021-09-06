function [gitHist,ok] = getCommitHistory(GF,pBr,varargin)

% initialisations
ok = true;

% sets up the input parser
ip = inputParser;
addParameter(ip,'nHist',-1);
addParameter(ip,'d0',[]);
addParameter(ip,'d1',[]);

% parses the input arguments
parse(ip,varargin{:})
p = ip.Results;

% sets the initial git string
d0 = struct('Year',2020,'Month',1,'Day',1);
d1 = struct('Year',2050,'Month',12,'Day',31);

if ~isempty(p.d0)
    % if the start time is before the stored values, then reset the start
    if datetime(d0.Year,d0.Month,d0.Day) < ...
            datetime(p.d0.Year,p.d0.Month,p.d0.Day)
        d0 = p.d0;
    end

    % sets the finish time date
    d1 = p.d1;
end

% creates the start/finish dates
startDate = sprintf('%i-%i-%i',d0.Year,d0.Day,d0.Month);        
finishDate = sprintf('%i-%i-%i',d1.Year,d1.Day,d1.Month);        

% sets the git function/branch strings
if GF.uType == 0
    [gFcn,brStr] = deal('branch-log-remote',pBr);
    if isempty(brStr); brStr = 'master'; end
else
    [gFcn,brStr] = deal('branch-log-remote','master');
end

% sets the git evaluation string
if p.nHist > 0   
    histStr = GF.gitCmd(gFcn,brStr,startDate,finishDate,p.nHist);
else
    histStr = GF.gitCmd(gFcn,brStr,startDate,finishDate);    
end

% retrieves the git log string and splits them into groups
histStrGrp = getCommitHistGroups(histStr);

% sets the history data based on the number of commits found
nCommit = length(histStrGrp);
if nCommit == 0
    % if no commits, then return and empty history array
    [gitHist,ok] = deal([],false);
else
    % memory allocation
    gStr = struct('ID',[],'DateNum',[],'Comment',[],'isMerge',false);
    gitHist = repmat(gStr,nCommit,1);
    
    for i = 1:nCommit
        % retrieves strings for the current commit
        cStr = histStrGrp{i};
        gitHist(i).isMerge = startsWith(cStr{2},'Merge');

        % retrieves the commit ID string
        idStr = strsplit(cStr{1});
        gitHist(i).ID = idStr{2};        
        
        % retrieves the commit date string
        dStr = strtrim(cStr{3+gitHist(i).isMerge}(6:end));
        gitHist(i).DateNum = datenum(dStr,'ddd mmm dd HH:MM:SS yyyy');           
        
        % sets the commit comment
        gitHist(i).Comment = strtrim(cStr{4+gitHist(i).isMerge});      
    end
end
    
