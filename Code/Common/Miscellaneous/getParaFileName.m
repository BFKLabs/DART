% --- retrieves the full name of a parameter file
function pFile = getParaFileName(pName)

% global variables
global mainProgDir

% sets the full parameter file name
pFile = fullfile(mainProgDir,'Para Files',pName);