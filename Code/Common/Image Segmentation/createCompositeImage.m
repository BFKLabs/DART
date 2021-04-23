% --- creates a componsite image from the sub-images given in Isub --- %
function Icomp = createCompositeImage(ImgBase,iMov,Isub,varargin)

% memory allocation
Icomp = ImgBase;

% sets the sub-images for all apparatus
for i = find(iMov.ok(:)')
    if (nargin == 3)
        Icomp(iMov.iR{i},iMov.iC{i}) = Isub{i};
    else
        sz = [length(iMov.iR{i}),length(iMov.iC{i})];
        IsubUS = usimage(Isub{i},sz);        
        Icomp(iMov.iR{i},iMov.iC{i}) = IsubUS;
    end    
end

% removes any NaN values from the image
isN = isnan(Icomp);
Icomp(isN) = ImgBase(isN);
