% --- deletes all the files with extension, fExtn, in the directory, fDir
function deleteAllFiles(fDir,fExtn,varargin)

% turns off all warnings
wState = warning('off','all');

% deletes the text files (if there are any)
fFile = field2cell(dir(fullfile(fDir,fExtn)),'name');
if (~isempty(fFile))
    fFile = cellfun(@(x)(fullfile(fDir,x)),fFile,'un',0);
    try; cellfun(@delete,fFile); end
end

% removes the directory (if required)
if (nargin == 3)
    try; rmdir(fDir); end
end

% reverts warnings back to original state
warning(wState);