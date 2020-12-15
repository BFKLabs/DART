function rmvButtonImgDir(paraDir)

% sets the image file names
fName = {'Analysis','Combine','Exit','Recording','Tracking'};

% sets the images directory
imgDir = fullfile(paraDir,'Images');

% loads the existing button data file
A = load(fullfile(imgDir,'ButtonCData.mat'));
cDataStr = A.cDataStr;

% loads the image files, stores the data and then deletes them
for i = 1:length(fName)
    eval(sprintf('cDataStr.%s = imread(''%s.bmp'');',fName{i},fName{i}))
    delete(fullfile(imgDir,sprintf('%s.bmp',fName{i})))
end

% saves the button data to file in the new location
save(fullfile(paraDir,'ButtonCData.mat'),'cDataStr')

% removes the image directory path and deletes it
rmpath(imgDir); pause(0.1);
rmdir(imgDir,'s')