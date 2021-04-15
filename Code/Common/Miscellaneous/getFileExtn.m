% --- retrieves the file name from a full directory string
function fExtn = getFileExtn(fFull)

% splits the full string into its parts
[~,~,fExtn] = fileparts(fFull);