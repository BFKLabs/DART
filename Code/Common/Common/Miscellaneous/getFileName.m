% --- retrieves the file name from a full directory string
function fName = getFileName(fFull,varargin)

% splits the full string into its parts
[~,fName,fExtn] = fileparts(fFull);
if nargin == 2; fName = [fName,fExtn]; end