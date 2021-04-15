% --- retrieves the unique files names from a list of files names, fFile
function [fDir,fFileGrp] = detUniqFileNames(fFile)

% retrieves the directory strings
fDirFiles = cellfun(@(x)(getFinalDirString(x,1)),fFile,'un',0);
[~,iUniq,iC] = unique(fDirFiles);

% sets the final file directory names
fDir = cellfun(@(x)(fileparts(x)),fFile(iUniq),'un',0);
fFileGrp = arrayfun(@(x)(fFile(iC==x)),(1:iC(end))','un',0);
