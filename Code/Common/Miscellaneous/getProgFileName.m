% --- retrieves the full name of a program directory or file
function pFile = getProgFileName(varargin)

% global variables
global mainProgDir

% sets the base program folder path
pFile = mainProgDir;

% sets the full program file name path
for i = 1:length(varargin)
    pFile = fullfile(pFile,varargin{i});
end