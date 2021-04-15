% --- sets the region exclusion binary mask
function Bw = setRegionBinaryMask(iMov,Img)

% memory allocation
[sz,is2D] = deal(size(Img),is2DCheck(iMov));
Bw = false(sz);

% sets the exclusion binary based on the experiment type
for iApp = 1:length(iMov.iR)
    if is2D
        % case is a 2D image
        BwNw = getExclusionBin(iMov,sz,iApp);
        Bw(iMov.iR{iApp},iMov.iC{iApp}) = Bw(iMov.iR{iApp},iMov.iC{iApp}) | BwNw;
    else
        % case is a 1D image
        Bw(iMov.iR{iApp},iMov.iC{iApp}) = true;
    end
end