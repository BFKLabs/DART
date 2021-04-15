% --- determines the batch processing file directories from a directory
%     tree, starting at the main directory, mainDir
function bpDir = detBatchProcessDir(mainDir)

% global variables
global mainProgDir

% sets the working directory to be the search directory
if (nargin == 0)
    mainDir = mainProgDir;
end

% memory allocation and initialisations
[bpDir,a] = deal([],dir(mainDir));
[fName,isDir] = field2cell(a,{'name','isdir'});

% if there is a batch processing file in this directory, then store the
% name of the current directory
if any(strcmp(fName,'BP.mat'))
    bpDir = {mainDir};
end

% searchs the sub-directories for any batch processing files
for i = 1:length(isDir)
    if ~(strcmp(a(i).name,'.') || strcmp(a(i).name,'..')) && isDir{i}
        % if a new sub-directory, then search the new directory for files
        bpDirNw = detBatchProcessDir(fullfile(mainDir,a(i).name));
        if ~isempty(bpDirNw)
            if iscell(bpDirNw)
                bpDir = [bpDir;bpDirNw];
            else
                bpDir = [bpDir;{bpDirNw}];
            end
        end
    end
end