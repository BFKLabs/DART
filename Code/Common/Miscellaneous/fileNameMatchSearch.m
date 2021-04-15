% --- searches for the file that matches the fData object in the 
%     sub-directory, sDir --- %
function fMatch = fileNameMatchSearch(fData,sDir)

% initialisations
fMatch = [];

% prompts the user for the search directory (if not provided)
if (nargin == 1)
    sDir = uigetdir(pwd,'Set Search Directory');
    if (length(sDir) == 1)
        return
    end
end

% retrieves the files from the current directory
nwFiles = dir(sDir);

% loops through all of the file objects in directory determining a match
for i = 1:length(nwFiles)
    % only search the non-root directory objects for a match
    if (~(strcmp(nwFiles(i).name,'.') || strcmp(nwFiles(i).name,'..')))
        if (nwFiles(i).isdir)
            % new object is a directory, so search the subdirectory for the
            % matching file. if a match is made, then exit the function
            fMatch = fileNameMatchSearch(fData,fullfile(sDir,nwFiles(i).name));
            if (~isempty(fMatch))
                return;
            end
        else
            % new object is a file, so compare the date of new file to the
            % input file. if a match is made, then exit the function
            if (strcmp(nwFiles(i).name,fData))
                fMatch = nwFiles(i);
                fMatch.dir = sDir;
                return
            end
        end
    end
end

