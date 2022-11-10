% rotates the image (if required)
function Img = getRotatedImage(iMov,Img0,mlt)

if iMov.useRot && (iMov.rotPhi ~= 0)
    % sets the rotation direction multiplier
    frmSz0 = size(Img0);
    if ~exist('mlt','var'); mlt = -1; end
    
    % calculates the rotated image
    Img = imrotate(Img0,mlt*iMov.rotPhi,'bilinear','loose');
    
    % determines if the image dimensions need to change
    if ((abs(iMov.rotPhi) > 45) && (mlt < 0)) || ...
                                ((abs(iMov.rotPhi) < 45) && (mlt > 0))
        szImg = flip(frmSz0(1:2));        
    else
        szImg = frmSz0(1:2);        
    end        
    
    % reduces the image to the required dimensions
    szImgNw = size(Img);
    dSz = roundP((szImgNw(1:2) - szImg)/2);
    Img = Img(dSz(1)+(1:szImg(1)),dSz(2)+(1:szImg(2)),:);
else
    % case is there is no rotation
    Img = Img0;
end
