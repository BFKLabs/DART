function fName = getUniqueFileName(fName0,fExtn)

% sets the default input arguments
if ~exist('fExtn','var'); fExtn = 'mat'; end

% initialisations
i = 1;

% keep looping until a unique file name is determined
while true
    % sets the new file name
    fName = sprintf('%s%i.%s',fName0,i,fExtn);    
    if exist(fName,'file')
        % if the file exists, then increment the counter
        i = i + 1;
    else
        % otherwise, exit the loop
        return;
    end
end