function file = dicom_get_msg(file)
%DICOM_GET_MSG  Get a pool of potential messages to load later.
%   FILE = DICOM_GET_MSG(FILE) processes FILE.Filename to obtain a pool
%   of potential DICOM messages to read.  After execution, FILE.Filename
%   will contain a cell array of messages to read.
%
%   Note: When loading a locally stored file, this function just checks
%   for the existence of the file.  When network contexts are supported,
%   the message pool will contain the results of a QUERY operation.
%
%   See also DICOM_OPEN_MSG and DICOM_CREATE_FILE_STRUCT.

%   Copyright 1993-2011 The MathWorks, Inc.

% Verify that file exists.

if (exist(file.Filename) ~= 2)
    
    % Look for file with common extensions.
    if (exist([file.Filename '.dcm']))
        
        file.Filename = [file.Filename '.dcm'];
        
    elseif (exist([file.Filename '.dic']))
        
        file.Filename = [file.Filename '.dic'];
        
    elseif (exist([file.Filename '.dicom']))
        
        file.Filename = [file.Filename '.dicom'];
        
    elseif (exist([file.Filename '.img']))
        
        file.Filename = [file.Filename '.img'];
        
    else
        
        file.Filename = '';
        return
        
    end
    
end

% Get full filename.
fid = fopen(file.Filename);

if (fid < 0)
    
    error(message('images:dicom_get_msg:fileOpen', file.Filename))
    
else
    
    file.Filename = fopen(fid);
    
end

fclose(fid);
