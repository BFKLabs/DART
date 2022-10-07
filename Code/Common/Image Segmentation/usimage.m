% --- upsamples an image, Img, by the upsample rate, uRate
function ImgUS = usimage(Img,sz0)

% determines if the array is logical
[nR,nC] = size(Img);
if (isequal([nR,nC],sz0))
    ImgUS = Img;
else
    [Imn,Imx] = deal(min(Img(:)),max(Img(:)));
    ImgUS = imresize(Img, [sz0(1),sz0(2)],'bilinear');
%     ImgUS = imresize(Img, [sz0(1),sz0(2)],'Nearest');
    
    [ImnUS,ImxUS] = deal(min(ImgUS(:)),max(ImgUS(:)));    
    ImgUS = (Imx-Imn)*(ImgUS-ImnUS)/(ImxUS-ImnUS);
end