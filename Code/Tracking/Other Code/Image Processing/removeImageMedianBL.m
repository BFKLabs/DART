function [ImgBL,ImgBG] = removeImageMedianBL(Img,isLoVar,is2D,h0,mlt)

% default input arguments
if ~exist('h0','var'); h0 = 50; end
if ~exist('mlt','var'); mlt = 1; end

% parameters
returnArr = false;
h = h0*[1,(1+2*(~is2D))];
hG = fspecial('gaussian',5,2);

% converts the image to a cell (if not already so)
if ~iscell(Img)
    Img = {Img};
    returnArr = true;
end

if isLoVar
    % case is a low-variance phase
    szImg = [1,1,numel(Img)];
    ImgComb = cell2mat(reshape(Img,szImg));
    ImgBG = {medianBGImageEst(mean(ImgComb,3,'omitnan'),h)};
    
else
    % case is a non low-variance phase
    ImgBG = cellfun(@(x)(medianBGImageEst(x,h)),Img,'un',0);
end

% removes the image baseline
ImgBL = removeImagePhaseBL(Img,ImgBG,hG,mlt);
if returnArr; ImgBL = ImgBL{1}; end

% removes the median baseline from the image
function ImgRmv = removeImagePhaseBL(Img,ImgBG,hG,mlt)         

if length(ImgBG) == length(Img)
    ImgRmv = cellfun(@(x,Ibg)(...
            mlt*removeImageBL(x,Ibg,hG)),Img,ImgBG,'un',0);
else
    ImgRmv = cellfun(@(x)(...
            mlt*removeImageBL(x,ImgBG{1},hG)),Img,'un',0);    
end   

% --- removes the image median smoothed baseline 
function ImdF = removeImageBL(Img,ImgBG,hG)

ImdF = medianShiftImg(ImgBG-imfilter(Img,hG));
