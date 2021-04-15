% --- updates the sub-directories within mainDir by the flag, type
%     (which is set to either 'add' or 'remove')
function updateSubDirectories(mainDir,type)

% searches for the files within the current directory
if (nargin == 2)
    addpath(mainDir)
end
mFile = dir(mainDir);

% sets the directory/name flags
fName = cellfun(@(x)(x.name),num2cell(mFile),'un',0);
isDir = cellfun(@(x)(x.isdir),num2cell(mFile));

% sets the candidate directories for adding/removing files
nwDir = find((~(strcmp(fName,'.') | strcmp(fName,'..'))) & isDir);

% loops through
for i = 1:length(nwDir)
    % adds/removes the path based on the type flag
    nwDirName = fullfile(mainDir,fName{nwDir(i)});
    if (strcmp(type,'add'))
        % case is adding paths
        addpath(nwDirName);
    else
        % case is removing paths        
        rmpath(nwDirName)
    end

    % searches for the directories within the current directory
    updateSubDirectories(nwDirName,type)
end