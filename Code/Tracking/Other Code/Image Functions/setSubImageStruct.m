% --- sets the sub-image data struct from the image stack, Img --- %
function sImg = setSubImageStruct(iMov,Img)

% ensures the image data is contained in a cell array
if ~iscell(Img); Img = {Img}; end

% allocates memory for the sub-image struct
sImg = struct('I',[],'Iavg',[],'Status',0);
[iR,iC] = deal(iMov.iR,iMov.iC);

% memory allocation
sImg.I = cell(length(Img),length(iR));
sImg.Iavg = zeros(length(Img),length(iR));

% sets the sub-images and calculates the average pixel values
for i = 1:length(Img)
    sImg.I(i,:) = cellfun(@(x,y)(double(Img{i}(x,y))),iR,iC,'un',0);
    sImg.Iavg(i,:) = cellfun(@(x)(mean(double(x(:)))),sImg.I(i,:));    
end