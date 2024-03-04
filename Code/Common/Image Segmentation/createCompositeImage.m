% --- creates a componsite image from the sub-images given in Isub --- %
function Icomp = createCompositeImage(ImgBase,iMov,Isub,varargin)

% memory allocation
Icomp = ImgBase;
isMltTrk = detMltTrkStatus(iMov);

% sets the sub-images for all apparatus
for i = find(iMov.ok(:)')
    if (nargin == 3)
        if isMltTrk
            iR = iMov.iR{i};
            for j = 1:iMov.pInfo.nRow
                k = (j-1)*iMov.pInfo.nCol + i;                
                Icomp(iR(iMov.iRT{i}{j}),iMov.iC{i}) = Isub{k};
            end
        else
            Icomp(iMov.iR{i},iMov.iC{i}) = Isub{i};
        end
    else
        sz = [length(iMov.iR{i}),length(iMov.iC{i})];
        IsubUS = usimage(Isub{i},sz);        
        Icomp(iMov.iR{i},iMov.iC{i}) = IsubUS;
    end    
end

% removes any NaN values from the image
isN = isnan(Icomp);
Icomp(isN) = ImgBase(isN);
