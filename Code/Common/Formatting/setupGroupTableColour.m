function [bgCol,iGrpNw] = setupGroupTableColour(sInfo,gName0)

% default input arguments
if ~exist('gName0','var'); gName0 = sInfo.gName; end

% parameters
grayCol = 0.81;
mgCol = [0.9,0.1,0.1];
mgStr = 'Multiple Groups';

% retrieves the unique group names from the list
[gNameU,~,iGrpNw] = unique(gName0,'stable');
isOK = sInfo.snTot.iMov.ok & ~strcmp(gName0,'* REJECTED *');            

% removes any multi-groups
isMG = strcmp(gName0,mgStr);
if any(isMG)
    % resets the grouping indices
    ii = find(strcmp(gNameU,mgStr));
    jj = iGrpNw > ii;
    iGrpNw(jj) = iGrpNw(jj) - 1;

    % resets grouping names
    gNameU = gNameU(~strcmp(gNameU,mgStr));
end

% sets the background colour based on the unique matche list
tCol = getAllGroupColours(length(gNameU),1);
bgCol = tCol(iGrpNw,:);
bgCol(isMG,:) = repmat(mgCol,sum(isMG),1);
bgCol(~isOK,:) = grayCol; 