% --- determines the next mat-file name for output (error files)
function fName = nextMatFileName(fDir,bName)

% initialisations
ind = 1;

% keep looping until a unique file name is determined
while (1)
    % sets the new name with the current index
    fName = fullfile(fDir,sprintf('%s%i.mat',bName,ind));
    if (exist(fName,'file'))
        % if not unique, then increment index
        ind = ind + 1;
    else
        % otherwise, exit loop
        break
    end
end