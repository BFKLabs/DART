% --- retrieves the final directory string from fDir --- %
function dirStr = getFinalDirString(fDir,NN) 

% sets the end directory to be set
if (nargin == 1); NN = 0; end

% otherwise, retrieves the partial file name
if (ispc)
    fDir(strfind(fDir,'\')) = '!';
else
    fDir(strfind(fDir,'/')) = '!';    
end

% splits the directory string by the whitespaces
A = splitStringRegExp(fDir,'!');
NN = min(length(A),NN);

% determines the last feasible string
N = length(A);
while (isempty(A{N}))
    N = N - 1;
end

% returns the directory string
dirStr = A{N-NN};