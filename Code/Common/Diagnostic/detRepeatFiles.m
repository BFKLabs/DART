% --- determines the repeat files within the program
function repFiles = detRepeatFiles()

% determines all files (removes any unwanted directories)
allFilesFull = findFileAll(pwd,'*.*');
isOK = ~(cellfun(@(x)(strContains(x,'Matlab\toolboxes')),allFilesFull) | ...
         cellfun(@(x)(strContains(x,'Common\Utilities')),allFilesFull) | ...
         cellfun(@(x)(strContains(x,'Git\Repo')),allFilesFull) | ...
         cellfun(@(x)(strContains(x,'File Exchange\export_fig')),allFilesFull) | ...
         cellfun(@(x)(isempty(getFileExtn(x))),allFilesFull));
allFilesFull = allFilesFull(isOK);

% sets the files for ignoring
ignFile = {'.','','..','.git'};

% removes any of the files to be ignored
allFiles = cellfun(@(x)(x(find(x==filesep,1,'last')+1:end)),allFilesFull,'un',0);
isOK2 = cellfun(@(x)(~any(strcmp(ignFile,x))),allFiles);
[allFilesFull,allFiles] = deal(allFilesFull(isOK2),allFiles(isOK2));

% determines the unique files
[fileUniq,~,iB] = unique(allFiles);

% groups the repeated values 
indF = arrayfun(@(x)(find(iB==x)),(1:length(fileUniq)),'un',0);
indM = find(cellfun(@length,indF) > 1);

% returns the final groups of repeated files
repFiles = arrayfun(@(x)(allFilesFull(indF{x})),indM,'un',0);