function isEqSz = compImageDim(iMov,iData,szImg)

% determines the image size based on image rotation type
if iMov.useRot
    % case is image is rotated
    Itmp = getRotatedImage(iMov,zeros(szImg));
    isEqSz = isequal(iData.sz,size(Itmp)); 
else
    % case is there is not image rotation
    isEqSz = isequal(iData.sz,szImg);
end