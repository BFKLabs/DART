% rotates the image (if required)
function Img = getRotatedImage(iMov,Img,mlt)

% % global variables
% global frmSz0

if iMov.useRot && (iMov.rotPhi ~= 0)
    % sets the rotation direction multiplier
    frmSz0 = size(Img);
    if ~exist('mlt','var'); mlt = -1; end
    
    % calculates the rotated image
    Img = imrotate(Img,mlt*iMov.rotPhi,'bilinear','loose');
    
    % determines if the image dimensions need to change
    if ((abs(iMov.rotPhi) > 45) && (mlt < 0)) || ...
                                ((abs(iMov.rotPhi) < 45) && (mlt > 0))
        szImg = flip(frmSz0);        
    else
        szImg = frmSz0;        
    end        
    
    % reduces the image to the required dimensions
    dSz = roundP((size(Img) - szImg)/2);
    Img = Img(dSz(1)+(1:szImg(1)),dSz(2)+(1:szImg(2)));
end
