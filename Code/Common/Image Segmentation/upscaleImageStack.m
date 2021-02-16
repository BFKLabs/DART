% --- upscales the image stack to the original size
function Ius = upscaleImageStack(iMov,I,iApp,iFly)

% determines if the tube regions are grouped by column
isCG = isColGroup(iMov);

%
if (nargin == 3)
    % determines the original sub-image sizes
    if (isCG)
        sz0 = cellfun(@(x)([length(iMov.iRT{iApp}),length(x)]),iMov.iCT{iApp},'un',0);
    else
        sz0 = cellfun(@(x)([length(x),length(iMov.iCT{iApp})]),iMov.iRT{iApp},'un',0);
    end

    %
    if (numel(sz0) ~= numel(I))
        szI = size(I);
        if (find(length(sz0) == szI) == 1)
            sz0 = repmat(sz0,1,szI(2));
        else
            sz0 = repmat(sz0(:)',szI(1),1);
        end
    end
    
    % upscales the image stack and reshapes to the original stack dimensions
    Ius = reshape(cellfun(@(x,y)(usimage(x,y)),I(:),sz0(:),'un',0),size(I));
else
    % determines the sub-image size
    if (isCG)
        sz0 = [length(iMov.iR{iApp}),length(iMov.iCT{iApp}{iFly})];
    else
        sz0 = [length(iMov.iRT{iApp}{iFly}),length(iMov.iC{iApp})];
    end
    
    % upscales the image stack and reshapes to the original stack dimensions
    Ius = reshape(cellfun(@(x)(usimage(x,sz0)),I,'un',0),size(I));
end