function [fFileS,fNameS] = sortVideoFiles(fFile)

% determines the length of the common base string
fName = cellfun(@(x)(getFileName(x)),fFile,'un',0);
fNameB = getCommonBaseString(fName);
nB = length(fNameB);

% sorts the video paths/names in ascending order
indF = cellfun(@(x)(str2double(x((nB+1):end))),fName);
iS = argSort(indF);
[fFileS,fNameS] = deal(fFile(iS),fName(iS));