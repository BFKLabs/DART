% --- sets the file extension, fExtn, for the video compression, vCompress
function fExtn = getMovieFileExtn(vCompress)

% sets the file extension based on the compression type
switch (vCompress)
    case {'Archival','Motion JPEG 2000'} % case is *.mj2 format
        fExtn = '.mj2';
    case {'Motion JPEG AVI','Uncompressed AVI'} % case is *.avi format
        fExtn = '.avi';
    case {'MPEG-4'} % case is *.mp4 format
        fExtn = '.mp4';
end