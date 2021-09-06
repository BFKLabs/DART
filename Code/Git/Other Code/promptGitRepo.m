% --- determines all the git repo directories within the project
function [rType,gDir,gRepoDir,gName] = promptGitRepo(promptUser)

% global variables
global mainProgDir

% initialisations
[rType,gDir] = deal([]);
if ~exist('promptUser','var'); promptUser = true; end

% searches all the sub-folders starting from the main program path
gDir0 = searchSubFolders(mainProgDir);
if isempty(gDir0)
    % if there are none then output an error to screen
    eStr = 'Error! No Git respositories found within current DART version.';
    waitfor(errordlg(eStr,'No Git Repositories!','modal'))
    
    % exit without setting the fields
    return
end

% retrieves the paths of the git repositories
gRepoDir0 = cellfun(@(x)(fread(fopen(fullfile(x,'.git'),'r'),...
                                 inf,'uint8=>char')'),gDir0(:),'un',0);
gRepoDir = cellfun(@(x)(x(9:end-1)),gRepoDir0,'un',0);
fclose('all');

% ensures the 
for i = find(strContains(gRepoDir,'Code/Common/Git'))'
    % deletes the previous file
    gRepoFile = fullfile(gDir0{i},'.git');
    delete(gRepoFile);
    pause(0.05);    
    
    % prepares the string for output
    gRepoDir{i} = strrep(gRepoDir{i},'Common/Git','Git');    
    
    % writes the string to file
    fid = fopen(gRepoFile,'w');
    fprintf(fid,'gitdir: %s\n',gRepoDir{i});
    fclose(fid);
end

% retrieves the descriptions of the Git repositories
gDesc = cellfun(@(x)(fread(fopen(fullfile(x,'description'),'r'),...
                                 inf,'uint8=>char')'),gRepoDir(:),'un',0);

% splits up the description/abbreviation for each repository
i0 = cellfun(@(x)(strfind(x,'(')),gDesc,'un',0);
i1 = cellfun(@(x)(strfind(x,')')),gDesc,'un',0);
gName = cellfun(@(x,i)(x(1:i-2)),gDesc,i0,'un',0);
rType = cellfun(@(x,i0,i1)(x(i0+1:i1-1)),gDesc,i0,i1,'un',0);

if promptUser
    % prompts the user which respository they want to view
    [iSel,isOK] = listdlg('PromptString','Select Git Repository',...
                          'SelectionMode','single','ListString',gName,...
                          'ListSize',[250,10+17*length(gName)]);
    if ~isOK        
        % if the user cancelled, then exit without setting the fields
        [rType,gDir,gRepoDir,gName] = deal([]);
        return
    end

    % sets the final repo type/directory
    [rType,gDir,gRepoDir,gName] = ...
                deal(rType{iSel},gDir0{iSel},gRepoDir{iSel},gName{iSel});
else
    gDir = gDir0;
end

% --- 
function gDir = searchSubFolders(sDir)

% memory allocation
gDir = {};

% retrieves the file/directory flags
[dName,isDir] = field2cell(dir(sDir),{'name','isdir'});
if isempty(dName)
    return
else
    isOK = ~(strcmp(dName,'.') | strcmp(dName,'..') | ...
             strContains(dName,'_mcr'));
    [dName,isDir] = deal(dName(isOK),cell2mat(isDir(isOK)));
end

% determines if there are any .git repository files in the directory
hasGit = strcmp(dName(~isDir),'.git');
if any(hasGit)
    % if so, then store the folder name
    gDir = {sDir};
end

% determines if any of the directories are git repo directories
for i = find(isDir(:)')
    gDirNw = searchSubFolders(fullfile(sDir,dName{i}));
    if ~isempty(gDirNw)
        % if there are any matches, then
        gDir = [gDir,gDirNw];
    end
end
