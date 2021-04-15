% --- calculates the local image orientation angle
function phi = calcLocalImageAngle(A,N)

% sets the x/y meshgrid values
[IL,fPosL] = deal(A{1},A{2});
[xx,yy] = meshgrid(1:size(IL,2),1:size(IL,1));

% determines the most likely points from the image
B0 = (IL > nanmedian(IL(:))) & (IL ~= 0);
if (sum(B0(:)) < N/2)
    % if the thresholded image is too small, then rethreshold with so that
    % the binary has a decent size
    B0 = setGroup(detTopNPoints(IL(:),N,0,0),size(IL)) & (IL ~= 0);
end
    
% thresholds the sub-image and determines the overlapping
[~,Bnw] = detGroupOverlap(B0,fPosL);
if (~any(Bnw(:)))
    % if there is no overlapping group, then determine the groups from the
    % initial binary image
    [iGrp,pCent] = getGroupIndex(B0,'Centroid');
    if (length(iGrp) > 1)
        % if there is more than one group, then determine the group that is
        % closest to the centre of the sub-image
        [~,imn] = min(sqrt(sum((pCent - repmat(fPosL,size(pCent,1),1)).^2,2)));
        iGrp = iGrp(imn);
    end
else
    % otherwise, fill any gaps within the image and continue
    iGrp = getGroupIndex(bwfill(Bnw,'holes'));
end

% ensures there are no non-zero values in the pca array setup
ILmn = min(IL(iGrp{1}));
if (ILmn < 1); IL = IL + (1 - ILmn); end

% sets up and calculate the PCA 
BB = num2cell(iGrp{1});
z = cell2mat(cellfun(@(x)(repmat([xx(x),yy(x)],ceil(IL(x)),1)),BB,'un',0)); 
[coef,~,eVal] = pca(z); 

% determines if the pca calculations returns any feasible values
if (length(eVal) < 2)
    % calculation was not feasible, so return a NaN array
    phi = NaN(1,2);
else
    % calculates the final orientation angle. align the orientation angle 
    % with the direction of the pixel weighted COM to the binary COM
    pF = mod(atan2(coef(2,1),coef(1,1))+pi/2,pi)-pi/2;

    % sets the orientation angle and aspect ratio    
    phi = [pF,eVal(1)/eVal(2)];
end