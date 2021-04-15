% --- downsamples an image, Img, by the downsample rate, dRate
function ImgDS = dsimage(Img,dRate)

% if no downsampling, then return the original image
if (dRate == 1)
    ImgDS = Img;
    return
end

% for each of the 
for i = 1:size(Img,3)
    % calculates the downsampled image
    ImgTmp = downsample(downsample(Img(:,:,i),dRate)',dRate)';
    
    % for the first band, allocate memory for the new image
    if (i == 1)
        ImgDS = zeros(size(ImgTmp));
    end
    
    % sets the down-sample image into the array
    ImgDS(:,:,i) = ImgTmp;
end