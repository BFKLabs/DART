% --- retrieves the unique files names from a list of files names, fFile
function [fDir,fFileGrp] = detUniqFileNames(fFile)

% retrieves the directory strings
fDir0 = cellfun(@(x)(fileparts(x)),fFile,'un',0);
[fDir,~,iC] = unique(fDir0);

% sets the final file directory names
fFileGrp = arrayfun(@(x)(fFile(iC==x)),(1:iC(end))','un',0);
