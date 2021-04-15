% --- creates the direct detection filter images
function Idf = createFilterImagesDD(I,Bw,bgP)

% sets the default image 
if nargin == 3
    hF = fspecial('gaussian',bgP.gSz,bgP.gSD);    
else
    hF = fspecial('gaussian',20,5);
end

% sets up the rejection binary mask
Idf = cellfun(@(x)(Bw.*imfilter(1-normImg(x),hF,'replicate')),I,'un',0);