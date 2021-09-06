% --- retrieves the branch commit history information 
function histStrGrp = getCommitHistGroups(histStr0,varargin)

% splits the history string into lines
histStr = strsplit(histStr0,'\n')';

% splits up the lines into commit history groups
iGrp = find(cellfun(@(x)(strcmp(x(1:min(6,length(x))),'commit')),histStr));
indGrp = [iGrp,[iGrp(2:end)-1;length(histStr)]];

% strips out the information from each of the groups
histStrGrp = cellfun(@(x)(strtrim(histStr(x(1):x(2)))),...
                                            num2cell(indGrp,2),'un',0);
histStrGrp = cellfun(@(x)(x(1:end-isempty(x{end}))),histStrGrp,'un',0);

% % removes all branch deletion entries
% isOK = cellfun(@(x)(~strContains(x{end},'Branch Delete')),histStrGrp);
% histStrGrp = histStrGrp(isOK);

% 
if nargin == 2
    histStrGrp = histStrGrp(cellfun(@length,histStrGrp)==4);
end