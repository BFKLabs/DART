% --- determines the fly edge positional flags
function onEdge = detFlyEdgePos(X,Y,R,mPara,sFac)

% parameters
drTol = 1;

% sets the radial tolerances
rTol = R - mPara.rTol/sFac;
drTol = rTol - drTol/sFac;

% determines if the radial distance is above threshold (for each frame)
D = sqrt(X.^2 + Y.^2);

% for each of the index groups where the fly is below threshold,
% determine if the fly has moved significantly from the edge
onEdge = false(size(D));
for i = 1:size(D,2)
    % thresholds the radial positions for the secondary threshold
    onEdge(:,i) = D(:,i) >= rTol(i);       
    if (any(~onEdge(:,i)))
        % determines the time points where the fly is in the inner region
        wGrp = getGroupIndex(~onEdge(:,i));
        if (wGrp{1}(1) == 1); wGrp = wGrp(2:end); end

        % determines if all of the points are outside the secondary 
        % threshold if not, then flag that the fly hasn't really moved away
        % from the edge (and reset the edge flags)
        if (~isempty(wGrp))
            ii = cellfun(@(x)(min(D(x,i))),wGrp) >= drTol(i);        
            onEdge(cell2mat(wGrp(ii)),i) = true;    
        end
    end   
    
    if (any(onEdge(:,i)))
        % determines the time points where the fly is in the outer region
        wGrp = getGroupIndex(onEdge(:,i));
        
        % removes any points when the fly is in the outer region for only a
        % single frame 
        onEdge(cell2mat(wGrp(cellfun(@length,wGrp) == 1)),i) = false;
    end
end