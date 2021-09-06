function createGitIgnoreFile(GF)

% global variables
global mainProgDir

% sets the base git repository directory
gDir = fullfile(mainProgDir,'Code','Git','Repo');

% sets the git repository type dependent on the input
switch GF.rType
    case 'Main'
        gRepo = 'DART';
        
    case 'AnalysisGen'
        gRepo = 'DARTAnalysisGen';
        
    case 'Git'
        gRepo = 'DARTGit';
end

% determines if the git ignore for the repository exists
igDir = fullfile(gDir,gRepo);
igFile = fullfile(igDir,'.gitignore');
if exist(igFile,'file')
    % if the file exists, then exit the function
    GF.gitCmd('unset-global-config','core.excludesfile')    
    GF.gitCmd('set-global-config','core.excludesFile',['"',igFile,'"']);
    return
end

% initialisations
[ignoreFileR,allowFileR] = deal([]);
allowFileC = {'*.fig'};

% sets the repository specific files to ignore
switch GF.rType
    case 'Main' % case is the main DART repository
        allowFileR = {'*.m','*.zip','/Code'};
        ignoreFileR = {'/Code/Common/Git',...
                       '/Code/Executable Only',...
                       '/Code/External Apps'};        
        
    case 'Git' % case is the Git functions
        allowFileR = {'*.p','*.m'};
        ignoreFileR = {'Repo'};
        
    case 'AnalysisGen' % case is the general analysis functions
        allowFileR = {'*.m'};
        ignoreFileR = {'*/*'};
        
end

% otherwise, create the file object
fid = fopen(igFile,'w');

% prints the top line
fprintf(fid,'# flag to ignore all files\n*.*\n/*\n');

% outputs the allowed files/directories
fprintf(fid,'\n# allowed files/directories\n');
allowFile = [allowFileC,allowFileR];
for i = 1:length(allowFile)
    fprintf(fid,'!%s\n',allowFile{i});
end

% outputs the ignored files/directories
fprintf(fid,'\n# ignored files/directories\n');
for i = 1:length(ignoreFileR)
    fprintf(fid,'%s\n',ignoreFileR{i});
end
    
% closes the file
fclose(fid);

% sets the exclusion file location
GF.gitCmd('unset-global-config','core.excludesfile')
GF.gitCmd('set-global-config','core.excludesFile',sprintf('"%s"',igFile));
