% --- calculates the fly locations over the image stack I (given previous
%     frame fly locations, p0). the fly locations are calculated between
%     the residual of the image stack I and the background image, Ibg
function fPos = calcFrameFlyLocations(I,Ibg,p0,Bw,flyok)

% global variables
global frmSz

% sets the flag to true (if not provided)
if (nargin == 4)
    flyok = true;
end

% sets the thresholding tolerance
[nErode,nFrm,szB] = deal(1,length(I),size(Ibg));
[optSize,iterMax,szTol,jDel] = deal([5 20],30,3,5);
[pDmax,pdDmax,pTolBase,zResMax] = deal(0.50,0.75,0.7,4);

% recalculates the optimal size to account for screen resolution
optSize = roundP(min(frmSz(1)/480,frmSz(2)/640)*optSize);

% memory allocation
fPos = NaN(nFrm,2);
if (~flyok)
    % if the fly has been rejected, then exit 
    return
end

% sets the sub-image array sizes
[Dmax,dDmax] = deal(pDmax*max(szB),pDmax*pdDmax*max(szB));
sz = cellfun(@size,I,'un',0);

% determines if the weight matrix is required (for tube detection only)
Chk2D = (max(szB)/min(szB)) > szTol;

% sets up the weight matrix (for tube detection only)
Dw = ones(size(I{1})); 
Dw(:,[(1:nErode) (end-(nErode-1)):end]) = 0;
if (Chk2D) 
     Dw([(1:nErode) (end-(nErode-1)):end],:) = 0;
end        

% calculates the normalised residuals for each of the rows    
IRes = cellfun(@(x)(calcResidualImage(Dw,Ibg,x,Bw)),I,'un',0);

% determines the initial tolerance (from the first frame in the stack
% and 
if (nFrm == 1)
    % retrieves
    iGrp = optThreshTolerance(IRes{1},optSize,iterMax,pTolBase);
    switch (length(iGrp))
        case (0)
            % if there are no valid groups, then exit with NaN's
            return
        case (1)
            % otherwise, set that as the candidate group                
            iGrp = {iGrp};
        otherwise
            % if more than one group, then set the group with the
            % highest mean residual value
            [~,imx] = max(cellfun(@(x)(mean(IRes{1}(x))),iGrp));
            iGrp = {iGrp(imx)};
    end

    % resets the group count to 1
    nGrp = 1;
else
    % calculates the mean/sd of the residual mean values
    IResMn = cellfun(@(x)(mean(x(:))),IRes); 
    [mnRes,sdRes] = deal(mean(IResMn),std(IResMn)); 
    zRes = abs(IResMn-mnRes)/sdRes;
    isOK = zRes < zResMax; ii = find(isOK);        

    % determines the candidate frame for determining the tolerance
    [~,imn] = max(cellfun(@(x)(mean(x(:))),IRes(ii)));
    [~,pTol0] = optThreshTolerance(IRes{ii(imn)},optSize,iterMax,pTolBase);

    % thresholds the frames within the stack at the threshold value
    iGrp = cellfun(@(x)(getGroupIndex(...
                bwmorph(x > pTol0,'majority',2))),IRes,'un',0);
    iGrp(~isOK) = {[]};

    % if there are any certain frames, then exit the loop
    nGrp = cellfun(@length,iGrp);        
end    

% sets the initial location (if one exists and the 1st point is ambiguous)
if (all(nGrp == 0))
    % if all groups are missing, then return a NaN-array
    return    
end

% calculates the centroids of the unique groups
indC = (nGrp == 1);
if (any(indC))
    fPos(indC,:) = cell2mat(cellfun(@(x,y)(calcGroupCentroids(x{1},y)),...
                                iGrp(indC),sz(indC),'un',0));    
end

% ------------------------------------------------------------ %
% --- MULTI-GROUP DISAMBIGUATION & MISSING GROUP DETECTION --- %
% ------------------------------------------------------------ %

% determines all the frames that have ambiguous number of groups, and
% stores these as the connected groups within the frame stack
jGrp = getGroupIndex(~indC);
grpSz = cellfun(@(x)(length(x{1})),iGrp(indC));
[grpSzMu,grpSzSD] = deal(mean(grpSz),std(grpSz));

% loops through the ambiguous groups determining which is the most likely
% group
for i = 1:length(jGrp)
    % sets the coordinates of the previously determined group
    if (jGrp{i}(1) == 1)
        % if the first frame, then set to that of the last frame of the
        % previous stack
        if (isempty(p0))
            fPos0 = fPos(jGrp{i}(end)+1,:);    
        else
            fPos0 = p0;
        end
    else
        % otherwise, set to that of the previous frame to the grouping
        fPos0 = fPos(jGrp{i}(1)-1,:);
    end
    
    % determines the most likely matching point
    [fPos(jGrp{i},:),iGrp(jGrp{i})] = detMostLikelyMatch(...
                        iGrp(jGrp{i}),IRes(jGrp{i}),fPos0,grpSzMu,grpSzSD);
    
    % recalculates the average/std group size
    indC(jGrp{i}) = true;
    grpSz = cellfun(@(x)(length(x{1})),iGrp(indC));
    [grpSzMu,grpSzSD] = deal(mean(grpSz),std(grpSz));
end

% ----------------------------------------- %
% --- LARGE POSITIONAL CHANGE DETECTION --- %
% ----------------------------------------- %

% if any of the distances between the points are still above tolerance,
% then check to see if the issue is within dodgy single frames (causes a
% jump in frames) or due to poor image quality

% calculates the difference in positions
if (isempty(p0))    
    % if the previous position is not provided, then use the first position
    % twice in the calculation
    PP = [fPos(1,:);fPos];    
else
    % otherwise, use the previous position in the calculation
    PP = [p0;fPos];    
end

% determines which points are greater than tolerance
[dPos,isCalc] = deal(sqrt(sum(diff(PP,[],1).^2,2)),false(nFrm,1));
d2Pos = [0;abs(diff(dPos))];

% keep searching while there are any frames where the distance between
% frames is greater than tolerance (and has not been recalculated)
while (any(((dPos > Dmax) | (d2Pos > dDmax)) & (~isCalc)))
    % determines the new search frame
    iFrm = find((((dPos > Dmax) | (d2Pos > dDmax)) & (~isCalc)),1,'first');
    
    % sets the search region based on the frame index
    switch (iFrm)
        case (1) % case is the first frame
            if (isempty(p0))
                % if the previous frame has not been calculated, then use
                % the entire frame for the search
                [iR,iC] = deal(1:size(Ibg,1),1:size(Ibg,2));
            else
                % otherwise, use the previous frame location point
                jFrm = iFrm + 1;
                [iX,iY] = deal([p0(1),fPos(jFrm,1)],[p0,fPos(jFrm,2)]);
                iR = roundP(max(1,min(iY)-jDel):min(sz{1}(1),max(iY)+jDel));
                iC = roundP(max(1,min(iX)-jDel):min(sz{1}(2),max(iX)+jDel)); 
            end
            
        case (nFrm) % case is the last frame
            % use the entire frame for the search
            [iR,iC] = deal(1:size(Ibg,1),1:size(Ibg,2));
            
        otherwise % case is the other frames
            [iX,iY] = deal(fPos(iFrm+[-1 0],1),fPos(iFrm+[-1 0],2));
            iR = roundP(max(1,min(iY)-jDel):min(sz{1}(1),max(iY)+jDel));
            iC = roundP(max(1,min(iX)-jDel):min(sz{1}(2),max(iX)+jDel));            
    end        
        
    % determines the minimum point from the search sub-image
    Isub = IRes{iFrm}(iR,iC);
    [~,imn] = max(Isub(:));

    % calculates the new coordinates from this point
    [yNw,xNw] = ind2sub(size(Isub),imn);
    [PP(iFrm+1,:),fPos(iFrm,:)] = deal([(xNw+iC(1)-1) (yNw+iR(1)-1)]);        
    
    % flag that the frame has been recalculated, and recalculated the 
    % distances between frame points
    [isCalc(iFrm),dPos] = deal(true,sqrt(sum(diff(PP,[],1).^2,2)));   
    d2Pos = [0;abs(diff(dPos))];
end

% REMOVE ME LATER
a = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- determines the most likely group from a collection of ambigious
%     groups of objects --- %
function [fPosNw,iGrp] = detMostLikelyMatch(iGrp,IRes,fPos0,grpSzMu,grpSzSD)

% parameters 
[sz,nFrm] = deal(size(IRes{1}),length(iGrp));
[AR,AGrp,hR,hD,hGrp,nSD] = deal(5,5,2,0.5,0.5,2);
[pTol0,dpTol,DMin] = deal(0.5,0.05,max(sz)*0.05);

% memory allocation
fPosNw = NaN(nFrm,2);

% loops through each of the groups determining the 
for i = 1:nFrm
    % if there are no groups, keep looping until a new group is found
    pTol = pTol0;
    while (isempty(iGrp{i}))       
        [iGrp{i},pTol] = deal(getGroupIndex(IRes{i} > pTol),pTol-dpTol);        
    end
    
    % searches for the new group
    if (length(iGrp{i}) > 1)
        % memory allocation
        dIRes = zeros(1,length(iGrp{i}));
        grpSzNw = cellfun(@length,iGrp{i})';
        
        % calculates the centroids of the groups, and from this determines
        % the distance of the previous point to the new groups        
        fPosC = cell2mat(cellfun(@(x)(calcGroupCentroids(x,sz)),iGrp{i},'un',0));
        DC = max(sqrt(sum((fPosC-repmat(fPos0,size(fPosC,1),1)).^2,2)'),DMin);
            
        % loops through each of the groups calculating the difference
        % in the residuals wrt the other frames in the group            
        for j = 1:length(dIRes)
            % calculates the difference in the residuals over all of
            % the frames in the group. for the concurrent frame, set
            % the difference to be the straight residual
            jj = iGrp{i}{j};                
            dIResNw = cellfun(@(x)(mean(abs(IRes{i}(jj)-x(jj)))),IRes)*AR;                   
            dIResNw(i) = mean(IRes{i}(jj)).^hR;

            % sums the values over all of the frames
            dIRes(j) = sum(dIResNw);
        end
        
        % determines the most likely group 
        if (isnan(grpSzMu))
            [~,imx] = max(dIRes./(DC.^hD));
        else
            [~,imx] = max(dIRes./((DC.^hD).*max(nSD*grpSzSD,abs(grpSzMu-grpSzNw)).^hGrp));
        end
        iGrp{i} = iGrp{i}(imx);
    end
    
    % calculates the new position from the centroids
    [fPosNw(i,:),fPos0] = deal(calcGroupCentroids(iGrp{i}{1},sz));
    if (isnan(grpSzMu)); 
        [grpSzMu,grpSzSD] = deal(length(iGrp{i}{1}),AGrp); 
    end
end

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

% --- calculates the residual images. removes any zero/nan groups
function IRes = calcResidualImage(Dw,Ibg,Inw,Bw)

% calculates the residual
IRes = Dw.*normImg(Ibg - double(Inw)).*Bw;

% removes the nan/zero pixels and replaces them with the median value
A = isnan(IRes) | (IRes == 0) | (IRes < (median(IRes(:)) - 0.5));
if (any(A(:)))
    IRes(A) = median(IRes(~A));    
    IRes = normImg(IRes);
end
    


