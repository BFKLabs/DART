% --- finds all of the sub-directories within a parent folder, fDir0
function fDir = findDirAll(fDir0)

% initialisations
[fFileAll,fDir] = deal(dir(fDir0),[]);

% determines all of directories in the sub-folder
isDir = find(field2cell(fFileAll,'isdir',1));
for j = 1:length(isDir)
    % if the sub-directory is valid, then search it for any files        
    i = isDir(j);  
    if ~(strcmp(fFileAll(i).name,'.') || strcmp(fFileAll(i).name,'..'))  
        fDirNw = fullfile(fDir0,fFileAll(i).name);
        fDir = [fDir;{fDirNw};findDirAll(fDirNw)];
    end
end
