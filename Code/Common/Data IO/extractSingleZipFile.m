% --- extracts a single file from a zip file
function outFile = extractSingleZipFile(zName, outName, outDir)

% default input arguments
if ~exist('outDir','var'); outDir = pwd; end

% Obtain the entry's output names
outFile = fullfile(outDir, outName);

% Create a stream copier to copy files.
sCopy = ...
    com.mathworks.mlwidgets.io.InterruptibleStreamCopier.getInterruptibleStreamCopier;

try
    % Create a Java file of the Zip filename.
    jzFile = java.io.File(zName);

    % Create a java ZipFile and validate it.
    zFile = org.apache.tools.zip.ZipFile(jzFile);

    % Get entry
    entry = zFile.getEntry(outName);

catch exception
    % if there was an error then close the zip file
    if ~isempty(zFile)
        zFile.close;
    end
    
    % deletes the temporary file and outputs the error
    delete(cleanUpUrl);
    error(message('MATLAB:unzip:unvalidZipFile', zName));
end

% Create the Java File output object using the entry's name.
file = java.io.File(outFile);

% If the parent directory of the entry name does not exist, then create it.
pDir = char(file.getParent.toString);
if ~exist(pDir, 'dir')
    mkdir(pDir)
end

try
    % Create an output stream
    fStreamOut = java.io.FileOutputStream(file);
catch 
    % if unable to, determine the issue
    overwriteExistingFile = file.isFile && ~file.canWrite;
    if overwriteExistingFile
        % case is being unable to overwrite an existing file
        warning(message('MATLAB:extractArchive:UnableToOverwrite',...
                         outputName));
    else
        % case is being unable to create the file
        warning(message('MATLAB:extractArchive:UnableToCreate',...
                         outputName));
    end
    
    % exits the function
    return
end

% create an input stream from the API
fStreamIn = zFile.getInputStream(entry);

% extract the entry via the output stream.
sCopy.copyStream(fStreamIn, fStreamOut);

% close the output stream.
fStreamOut.close;
zFile.close;