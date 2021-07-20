% --- removes the file extension from the file path, fFile0
function fFileF = removeFileExtn(fFile0)

if isempty(fFile0)
    % case is the file path string is empty
    fFileF = fFile0;
else
    % otherwise, split the path string and recombine within the extension
    [fDir0,fName0,~] = fileparts(fFile0);
    fFileF = fullfile(fDir0,fName0);
end