% --- removes all the files/directories from rmvDir
function rmvAllFiles(rmvDir,varargin)

% sets the files to remove and removes them
rmFiles = dir(rmvDir);
for i = 1:length(rmFiles)
    if (~(strcmp(rmFiles(i).name,'..') || strcmp(rmFiles(i).name,'.')))
        if (rmFiles(i).isdir)
            rmvAllFiles(fullfile(rmvDir,rmFiles(i).name),1)
            rmdir(fullfile(rmvDir,rmFiles(i).name),'s')
        else
            delete(fullfile(rmvDir,rmFiles(i).name))
        end
    end
end

% if the top directory, then remove the main directory file
if (nargin == 1)
    rmdir(rmvDir)
end