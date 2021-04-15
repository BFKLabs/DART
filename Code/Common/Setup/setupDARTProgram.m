% --- initialises the DART program framwork and places the program files
%     into their designated locations --- %
function ok = setupDARTProgram()

% global variables
global mainProgDir

% un-zips the zip file into the temporary data directory
warning off all

% sets the default search directory
[~,B] = system('hostname');
switch (B(1:end-1))
    case ('LankyG-PC') % case is home computer
        dDir = 'E:\Work\Versions\DART Tracking\Full Versions';
    otherwise
        if (isempty(mainProgDir))
            dDir = pwd;
        else
            dDir = mainProgDir;
        end
end
        
% sets the program .zip file for the program setup
[tmpDir,ok] = deal(fullfile(pwd,'Temp Files'),false);
if (isdeployed)
    % if deployed, then use the attached .zip file
    zFile = 'DART.zip';
else
    % otherwise, prompt the user for the file 
    [zName,zDir,zIndex] = uigetfile({'*.zip;','Zip File (*.zip)'},...
                                    'Select Program Zip File',dDir);
    if (zIndex == 0)
        % if the user cancelled, then exit the function
        return
    else
        % otherwise, set the new zip file 
        zFile = fullfile(zDir,zName);
    end
end
    
% prompts the user to select the directory where they want to install the
% DART program
cDir = uigetdir(pwd,'Select To Install DART Program');
if (cDir == 0)
    % if the user cancelled, then exit the function
    return
else
    % sets the directory seperation string (dependent on OS type)
    if (ispc); sStr = '\'; else sStr = '/'; end
    cDirSub = splitStringRegExp(cDir,sStr);
    
    % check to see if the directory name is valid. if not, then the
    % compiler will not be able to create executables. a valid directory
    % title has no white space or special characters
    if (~all(cellfun(@(x)(chkDirString(x,1)),cDirSub(2:end))))
        return
    end
end

% unzips the file to the temporary directory
h = waitbar(0,'Unzipping Program Files...');
unzip(zFile, tmpDir);

% sets the un-zipped directory details and names
uzDir = dir(tmpDir);

% --------------------------------- %
% --- DIRECTORY STRUCTURE SETUP --- %
% --------------------------------- %

% updates the waitbar
waitbar(0.40,h,'Setting Up Directory Structure...');

% sets the code folder sub-directories
sName = {'Analysis','Common','Combine','Recording','Tracking'};
sDir = cell(length(sName),1);

% makes the sub-directories
mkdir(cDir,'Code')
mkdir(cDir,'Documents')
mkdir(cDir,'External Files')
mkdir(cDir,'Para Files')
mkdir(cDir,'Analysis Functions')

% for all the program code folders, create a new folder and within it
% create the program version type folders (code or executable)
for i = 1:length(sName)
    % makes the sub-directory for the code
    mkdir(fullfile(cDir,'Code'),sName{i});
    sDir{i} = fullfile(cDir,'Code',sName{i});
end

% ---------------------------- %
% --- MAIN DIRECTORY SETUP --- %
% ---------------------------- %

% updates the waitbar
waitbar(0.45,h,'Setting Up Main Directory...');

%
srcDir = {fullfile(tmpDir,'DART Main'),...
          fullfile(tmpDir,'Para Files'),...
          fullfile(tmpDir,'Test Main'),...
          fullfile(tmpDir,'Analysis Functions')};
dstDir = {cDir,fullfile(cDir,'Para Files'),...
               fullfile(cDir,'External Files'),...
               fullfile(cDir,'Analysis Functions')};

% copies the main directory files to the install folder  
for i = 1:length(srcDir)     
    if (~copyAllFilesOrig(srcDir{i},dstDir{i}))
        % removes the copy/temporary directories
        waitbar(0.70,h,'Removing Temporary/Destination Directories...');
        rmdir(cDir,'s')
        rmdir(tmpDir,'s');
        
        % exits with a false flag
        waitbar(1,h,'Directory Removal Complete. Exiting Installation.');
        delete(h)
        ok = false;
        return
    end
end

% deletes any remaining files
rmvAllFiles(fullfile(tmpDir,'Para Files'));
rmvAllFiles(fullfile(tmpDir,'External Files'));
rmvAllFiles(fullfile(tmpDir,'Analysis Functions'));

% removes the main directories
try; rmdir(fullfile(tmpDir,'DART Main')); end
try; rmdir(fullfile(tmpDir,'Para Files')); end
try; rmdir(fullfile(tmpDir,'External Files')); end
try; rmdir(fullfile(tmpDir,'Analysis Functions')); end

% ------------------------------------ %
% --- PROGRAM FILE DIRECTORY SETUP --- %
% ------------------------------------ %

% updates the waitbar
for i = 1:length(sName)
    % updates the waitbar
    pW = 0.50*(1 + (i-1)/length(sName));
    waitbar(pW,h,sprintf('Setting Up Directory "%s"...',sName{i}));
   
    % copies the main directory files to the current folder
    copyAllFilesOrig(fullfile(tmpDir,sName{i}),sDir{i});
    try; rmdir(fullfile(tmpDir,sName{i})); end
end

% ------------------------------- %
% --- HOUSE-KEEPING EXERCISES --- %
% ------------------------------- %

% deletes any remaining files
rmFiles = dir(tmpDir);
for i = 1:length(rmFiles)
    if (~(strcmp(rmFiles(i).name,'..') || strcmp(rmFiles(i).name,'.')))    
        if (rmFiles(i).isdir)
            try; rmdir(fullfile(tmpDir,rmFiles(i).name)); end
        else
            delete(fullfile(tmpDir,rmFiles(i).name))
        end
    end
end

% deletes the temporary file directory
try; rmdir(tmpDir); end

% updates the waitbar figure
waitbar(1,h,'Program Setup Complete!'); pause(0.5)

% closes the waitbar
close(h)
warning on all

% flag that the program setup was successful
ok = true;

% --- copies all the files in copyDir to the destination, destDir
function ok = copyAllFilesOrig(copyDir,destDir)

% retrieves the file details from that within the copy directory
[copyData,ok] = deal(dir(copyDir),true);

% loops through all the files in the directory copying them from the
% copying directory to the destination directory
for i = 1:length(copyData)
    % only copy over valid files
    if ~(strcmp(copyData(i).name,'.') || strcmp(copyData(i).name,'..'))
        if (copyData(i).isdir)
            % creates a new sub-directory for copying/destination
            copyDirNw = fullfile(copyDir,copyData(i).name);
            destDirNw = fullfile(destDir,copyData(i).name);
            
            % creates the new directories
            mkdir(copyDir,copyData(i).name);
            mkdir(destDir,copyData(i).name);
            
            % copies over the sub-directories
            copyAllFilesOrig(copyDirNw,destDirNw);
            rmdir(copyDirNw)
        else
            % copies over the file
            try
                nwFile = fullfile(copyDir,copyData(i).name);
                copyfile(nwFile,destDir,'f');
            catch ME
                if (ismac)
                    cpStr = sprintf('cp -p "%s" "%s"',nwFile,destDir);
                    [~,~] = system(cpStr);
                else
                    rethrow(ME)
                end
            end
            
            % deletes the file
            delete(nwFile);
        end
    end
end

% --- removes all the files/directories from rmvDir
function rmvAllFiles(rmvDir)

% sets the files to remove and removes them
rmFiles = dir(rmvDir);
for i = 1:length(rmFiles)
    if (~(strcmp(rmFiles(i).name,'..') || strcmp(rmFiles(i).name,'.')))
        if (rmFiles(i).isdir)
            rmdir(fullfile(rmvDir,rmFiles(i).name))
        else
            delete(fullfile(rmvDir,rmFiles(i).name))
        end
    end
end

% --- splits up a string, Str, by its white spaces and returns the
%     constituent components in the cell array, sStr
function sStr = splitStringRegExp(Str,sStr)

% ensures the string is not a cell array
if (iscell(Str))
    Str = Str{1};
end

% determines the indices of the non-white regions in the string
if (length(sStr) == 1)
    if (strcmp(sStr,'\') || strcmp(sStr,'/'))    
        ind = strfind(Str,sStr)';
    else
        ind = regexp(Str,sprintf('[%s]',sStr))';
    end
else
    ind = regexp(Str,sprintf('[%s]',sStr))';
end

% calculates the indices of the non-contigious non-white space indices and
% determines the index bands that the strings belong to
indGrp = num2cell([[1;(ind+1)],[(ind-1);length(Str)]],2);

% sets the sub-strings
sStr = cellfun(@(x)(Str(x(1):x(2))),indGrp,'UniformOutput',false);

% --- determines if directory string, nwStr, is a feasible directory string
function ok = chkDirString(nwStr,varargin)

% if the string is empty, then exit with a false flag
if (isempty(nwStr))
    ok = false;
    return
end

% sets the possible error strings and initialises the ok flag. if the 2nd
% input argument is set, then check for white-space
[eStr,ok] = deal('/\:?"<>|',true);
if (nargin == 2); eStr = [eStr,' ']; end

% determines if any of the offending strings are in the new string
for i = 1:length(eStr)
    % determines if the new directory string contains a non-valid character
    notOK = strContains(nwStr,eStr(i));
    
    % if so, then exit the function with a false flag
    if (notOK)
        % resets the flag and set the output error
        ok = false;
        if (strcmp(eStr(i),' '))
            A = 'Error! Directory name can''t contain white-space.';
        else
            A = sprintf('Error! Directory name can''t contain the string "%s".',eStr(i));
        end
        
        % outputs the error dialog 
        waitfor(errordlg(A,'DART Setup Error','modal'));
        return
    end
end
