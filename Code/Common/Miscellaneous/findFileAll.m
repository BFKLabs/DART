% --- finds all the finds
function fName = findFileAll(snDir,fExtn)

% initialisations
[fFileAll,fName] = deal(dir(snDir),[]);

% determines the files that have the extension, fExtn
fFile = dir(fullfile(snDir,sprintf('%s',fExtn)));
if (~isempty(fFile))
    fNameT = field2cell(fFile,'name');
    fName = cellfun(@(x)(fullfile(snDir,x)),fNameT,'un',0);    
end

%
isDir = find(field2cell(fFileAll,'isdir',1));
for j = 1:length(isDir)
    % if the sub-directory is valid, then search it for any files        
    i = isDir(j);
    if ~(strcmp(fFileAll(i).name,'.') || strcmp(fFileAll(i).name,'..'))        
        fDirNw = fullfile(snDir,fFileAll(i).name);        
        fNameNw = findFileAll(fDirNw,fExtn);
        if ~isempty(fNameNw)
            % if there are any matches, then add them to the name array
            fName = [fName;fNameNw];
        end
    end
end

