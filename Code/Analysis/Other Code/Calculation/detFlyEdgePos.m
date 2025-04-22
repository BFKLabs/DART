% --- determines the fly edge positional flags
function onEdge = detFlyEdgePos(X,Y,R,mPara,sFac,mShape)

% parameters
drTol = 1;

% memory allocation
onEdge = NaN(size(X));

% sets the radial tolerances
switch mShape
    case 'Circle'
        % case is circular regions
        fok = ~isnan(R);
        rTol = R - mPara.rTol/sFac;
        drTol = rTol - drTol/sFac;
   
        % calculates the radial distance
        D = sqrt(X.^2 + Y.^2);        
        
    case 'Rectangle'
        % case is rectangular regions        
        fok = ~isnan(R(1,:));
        rTol = R/2 - mPara.rTol/sFac;
        drTol = rTol - drTol/sFac;        
        
        % calculates the radial distance
        [X,Y] = deal(abs(X),abs(Y));
end

% for each of the index groups where the fly is below threshold,
% determine if the fly has moved significantly from the edge
for i = find(fok(:)')
    % thresholds the radial positions for the secondary threshold
    switch mShape
        case 'Circle'
            % case is circular regions
            onEdge(:,i) = D(:,i) >= rTol(i);       
            
        case 'Rectangle'
            % case is rectangular regions            
            onEdge(:,i) = (X(:,i) > rTol(1,i)) | (Y(:,i) > rTol(2,i));
    end
    
    if any(~onEdge(:,i))
        % determines the time points where the fly is in the inner region
        wGrp = getGroupIndex(~onEdge(:,i));
        if (wGrp{1}(1) == 1); wGrp = wGrp(2:end); end

        % determines if all of the points are outside the secondary 
        % threshold if not, then flag that the fly hasn't really moved away
        % from the edge (and reset the edge flags)
        if ~isempty(wGrp)
            switch mShape
                case 'Circle'
                    % case is circular regions
                    ii = cellfun(@(x)(min(D(x,i))),wGrp) >= drTol(i);        
                    
                case 'Rectangle'
                    % case is rectangular regions
                    iiX = cellfun(@(x)(min(X(:,i))),wGrp) >= drTol(1,i);
                    iiY = cellfun(@(x)(min(Y(:,i))),wGrp) >= drTol(2,i);
                    ii = iiX | iiY;
            end
            
            % resets the on-edge flags
            onEdge(cell2mat(wGrp(ii)),i) = true;    
        end
    end   
    
    if any(onEdge(:,i))
        % determines the time points where the fly is in the outer region
        wGrp = getGroupIndex(onEdge(:,i));
        
        % removes any points when the fly is in the outer region for only a
        % single frame 
        onEdge(cell2mat(wGrp(cellfun('length',wGrp) == 1)),i) = false;
    end
end