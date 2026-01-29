function [bgCol,iGrpNw] = setupGroupTableColour(sInfo,gName0)

% default input arguments
if ~exist('gName0','var'); gName0 = sInfo.gName; end

% parameters and memory allocation
grayCol = 0.81;
mgCol = [0.9,0.1,0.1];
mgStr = 'Multiple Groups';
bgCol = zeros(length(gName0),3);

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
bgCol(~isMG,:) = tCol(iGrpNw(~isMG),:);
bgCol(isMG,:) = repmat(mgCol,sum(isMG),1);
bgCol(~isOK,:) = grayCol; 