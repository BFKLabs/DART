% rotates the image (if required)
function Img = getRotatedImage(iMov,Img0,mlt)

% applies the fisheye distortion
if isfield(iMov,'fdPara')
    Img0 = applyFishEyePara(Img0,iMov.fdPara);
end

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

% --- applies the fish eye undistortion parameters
function Img = applyFishEyePara(Img,fdP)

% if there are no parameters, or not being used, then exit the function
if isempty(fdP) || ~fdP.useFD
    return
end

% applies the image rotation
if fdP.pPhi ~= 0
    Img = imrotate(Img,fdP.pPhi,'crop');
end

% applies the image undistortion
szImg = size(Img);
Img = imresize(undistortFisheyeImage(...
    Img,fdP.hInt,'OutputView','valid'),szImg(1:2));