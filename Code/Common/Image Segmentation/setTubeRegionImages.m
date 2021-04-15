% --- sets the tube region sub-image arrays
function IL = setTubeRegionImages(iMov,I,ind,varargin)

if (isColGroup(iMov))    
    if (nargin == 4); ind = iMov.iCT{ind}(:)'; end
    IL = cellfun(@(x)(I(:,x)),ind,'un',0);
else
    if (nargin == 4); ind = iMov.iRT{ind}(:)'; end
    IL = cellfun(@(x)(I(x,:)),ind,'un',0);
end