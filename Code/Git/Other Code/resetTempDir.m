function resetTempDir(tmpDir)

% global variables
global tmpDir0

% retrieves the original temporary directory (if not set)
if isempty(tmpDir0); tmpDir0 = getenv('TMP'); end

% updates the temporary directory (if
if nargin == 0
    % deletes the temporary directory (if not the original directory)
    tmpDirC = getenv('TMP');
    if ~strcmp(tmpDir0,tmpDirC)
        rmdir(tmpDirC)
        setenv('TMP',tmpDir0)
    end
else
    % creates the temporary directory (if it doesn't exist)
    if ~exist(tmpDir,'dir'); mkdir(tmpDir); end
    
    % updates the environment variable 
    setenv('TMP',tmpDir)
end