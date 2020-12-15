% --- determines the initial tolerance that is used to threshold all of the
%     residual images in an image stack. the function loops through
%     thresholding the image until A) the size is within tolerance
%     (optSize) or B) the iteration counter exceeds the counter limit
function [iGrpNw,pTol0] = optThreshTolerance(IRes,optSize,iterMax,pTol0)

% sets the initial tolerance to be the overall base value
if (nargin == 3)
    [pTol0,dpTol] = deal(0.5,0.050);
else
    dpTol = 0.025;
end

% initialisations
iter = 0;

% keep looping until the criteria has been met
while (1)
    % thresholds the new group
    iGrpNw = getGroupIndex(bwmorph(IRes > pTol0,'majority',2));

    % determines if the max group size is within tolerance
    if (~isempty(iGrpNw))
        % determines the size of the thresholded groups and determines
        % which groups are within the optimal size
        nGrpNw = cellfun(@length,iGrpNw);   
        ii = (nGrpNw >= optSize(1)) & (nGrpNw <= optSize(2));        
        if (any(ii))
            % if there are optimal groups, then set them as the output
            iGrpNw = iGrpNw(ii);
            break
        else
            % if there are not, then determine the largest * brightest
            % groups and sort by value in descending order
            IGrpNw = cellfun(@(x)(mean(IRes(x))),iGrpNw);
            [~,imx] = sort(nGrpNw.*IGrpNw,'descend');
            if (nGrpNw(imx(1)) < optSize(1))
                % if the new group is too small, then set the
                % tolerance increment to be positive
                dpTol = -abs(dpTol);
            elseif (nGrpNw(imx(1)) > optSize(2))
                % if the new group is too large, then set the
                % tolerance increment to be negative
                dpTol = abs(dpTol);
            end              
        end        
    else
        % tolerance is too high, so lower the value
        dpTol = -abs(dpTol);
    end
    
    % increments the pixel tolerance and iteration counter
    [pTol0,iter] = deal(pTol0+dpTol,iter+1);
    if (iter > iterMax)
        % if there have been too many iterations, then exit the loop
        break;
    end
end