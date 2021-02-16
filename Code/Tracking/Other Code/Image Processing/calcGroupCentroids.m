% --- calculates the centroid of the group with indices iGrp
function grpCent = calcGroupCentroids(iGrp,sz)
    
% checks to see if there are any groups present
if (isempty(iGrp))
    % if not, return a NaN value
    grpCent = NaN(1,2);
else
    % otherwise, return the coordinates of the centroid
    [yGrp,xGrp] = ind2sub(sz,iGrp);
    grpCent = [mean(xGrp) mean(yGrp)];
end