% --- determines the first feasible region/sub-region indices
function [i0,j0] = getFirstFeasRegion(iMov)

% determines the first feasible region
[i0,j0] = deal(find(iMov.ok,1,'first'),1);

% if not multi-tracking, then determine the first feasible sub-region
if ~detMltTrkStatus(iMov)
    j0 = find(iMov.flyok(:,i0),1,'first');
end