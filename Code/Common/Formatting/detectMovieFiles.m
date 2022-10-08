% --- determines the movie files that exist in the directory, movDir. the
%     movie files that are to be detected are given in VV
function movFiles = detectMovieFiles(movDir,VV)

% searches for the movie files based on the number of inputs
if nargin == 1
    % sets the file extensions to search for
    [fExtn,movFiles] = deal({'*.mj2','*.avi','*.mp4'},[]);
    
    % loop through the extensions until at least one is found
    for i = 1:length(fExtn)
        movFilesNw = dir(fullfile(movDir,fExtn{i}));        
        if ~isempty(movFilesNw)
            movFiles = [movFiles;movFilesNw];
        end
    end    
else
    % sets the file extension based on the compression type
    switch VV.vCompress
        case {'Archival','Motion JPEG 2000'} 
            % case is mj2 files
            movFiles = dir(fullfile(movDir,'*.mj2'));
            
        case {'Motion JPEG AVI','Uncompressed'} 
            % case is avi files
            movFiles = dir(fullfile(movDir,'*.avi'));
            if (isempty(movFiles))
                movFiles = dir(fullfile(movDir,'*.AVI'));
            end
            
        case {'MPEG-4'} 
            % case is mp4 files
            movFiles = dir(fullfile(movDir,'*.mp4'));
    end    
end

