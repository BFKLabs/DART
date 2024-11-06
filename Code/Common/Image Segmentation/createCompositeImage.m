% --- creates a componsite image from the sub-images given in Isub --- %
function Icomp = createCompositeImage(ImgBase,iMov,Isub,varargin)

% memory allocation
Icomp = ImgBase;
isMltTrk = detMltTrkStatus(iMov);
isDbl = isa(ImgBase,'double');

%
if isMltTrk
    % case is a multi-tracking experiment
    
    if iscell(Isub{1})
        Isub = Isub{1};
    end
    
    %
    for i = 1:iMov.pInfo.nCol
        iR = iMov.iR{i};
        for j = 1:iMov.pInfo.nRow
            k = (j-1)*iMov.pInfo.nCol + i;

            if isDbl
                Icomp(iR(iMov.iRT{i}{j}),iMov.iC{i}) = Isub{k};
            else
                Icomp(iR(iMov.iRT{i}{j}),iMov.iC{i}) = uint8(Isub{k});
            end
        end
    end
    
else
    % case is a single tracking experiment
    for i = find(iMov.ok(:)')
        if (nargin == 3)        
            if isDbl
                Icomp(iMov.iR{i},iMov.iC{i}) = Isub{i};
            else
                Icomp(iMov.iR{i},iMov.iC{i}) = uint8(Isub{i});
            end    
        else
            sz = [length(iMov.iR{i}),length(iMov.iC{i})];
            IsubUS = usimage(Isub{i},sz);

            if isDbl
                Icomp(iMov.iR{i},iMov.iC{i}) = IsubUS;
            else
                Icomp(iMov.iR{i},iMov.iC{i}) = uint8(IsubUS);
            end
        end        
    end
end

% removes any NaN values from the image
isN = isnan(Icomp);
Icomp(isN) = ImgBase(isN);
