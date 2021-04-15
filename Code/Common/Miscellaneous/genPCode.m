% --- generates the .p files for the program --- %
function genPCode()

% prompts the user for the main program directory
progDir = uigetdir('Set The Program Main Directory',pwd);
if (isempty(progDir))
    % if the user cancelled, then exit the function
    return;
end

% sets the main directories
mDir = [{[]},{'Other Code'},{'GUI Code'}];
fDir = fullfile(progDir,'P-Code');

% memory allocation
[dName,fCopy] = deal(cell(length(mDir),1));
munlock 

% loops through all the directories
for i = 1:length(mDir)
    % directories to search
    if (i > 1)
        % recursively search the current directories for any
        % sub-directories that need to be searched
        dName{i} = detSubFolders(cDir,mDir(i));      
    else
        % case is the main directory
        dName{i} = mDir(i);
    end
    
    % for all the directories, determines the files to copy and the .m
    % files that are required to be converted to .p files
    fCopy{i} = cell(length(dName{i}),1);
    for j = 1:length(dName{i})
        % sets the new directory name
        nwDir = fullfile(cDir,dName{i}{j});
                
        % if there are figures to copy, then make a note of their location
        fFig = dir(fullfile(nwDir,'*.fig'));
        if (~isempty(fFig))
            fFigName = field2cell(fFig,'name');
            fCopy{i}{j} = cellfun(@(x)(fullfile(nwDir,x)),fFigName,'un',0);                        
        end
    end    
end

% copies the figures and creates/moves the m-files to their corresponding
% locations within the final p-file directory
for i = 1:length(dName)
    for j = 1:length(dName{i})
        % changes
        nwDir = fullfile(cDir,dName{i}{j});
        nwDirFin = fullfile(fDir,dName{i}{j});
        cd(nwDir)
                        
        % if the final directory does not exist, then create it
        if (~exist(nwDirFin,'dir'))
            mkdir(nwDirFin)
        end
        
        % determines if there are any m-files in the current directory
        mName = dir(fullfile(nwDir,'*.m'));
        if (~isempty(mName))
            % unlocks all the m-files in the directory
            mFile = cellfun(@(x)(fullfile(nwDir,x)),field2cell(mName,'name'),'un',0);
            isPFile = true(length(mFile),1);
            
            for k = 1:length(mFile)                
                munlock(mFile{k});
                isPFile(k) = ~strContains(mFile{k},'genPCode');
            end

            % creates the p-files for the directory, and moves them to the
            % final location within             
            cellfun(@(x)(pcode(x)),mFile(isPFile))
            pName = field2cell(dir(fullfile(nwDir,'*.p')),'name');
            
            % moves the p-files to their final location
            pFile = cellfun(@(x)(fullfile(nwDir,x)),pName,'un',0);
            cellfun(@(x)(movefile(x,nwDirFin)),pFile);
        end
            
        % copies the figure files to their final location (if they exist)
        if (~isempty(fCopy{i}{j}))
            cellfun(@(x)(copyfile(x,nwDirFin)),fCopy{i}{j})
        end
    end
end

% changes the folder back to the original
cd(cDir);

% --- determines the sub-folders within the directory, topDir
function dName = detSubFolders(topDir,dName)

% determines the files within the new directory
nwFile = dir(fullfile(topDir,dName{1}));
[isDir,fName] = field2cell(nwFile,[{'isdir'},{'name'}]);

% determines any sub-directories
nwDir = (~strcmp(fName,'.') & ~strcmp(fName,'..')) & cell2mat(isDir);

% if there are, then retrieve the names of the sub-directories
if (any(nwDir))    
    % determines the indices of the new directories
    ii = find(nwDir);
    for i = 1:length(ii)
        % adds the new directories to the new directory
        dName = [dName;fullfile(dName,fName{ii(i)})];
        
        % adds any sub-directories within the current directory
        dNameNw = detSubFolders(fullfile(topDir,dName{1}),fName(ii(i)));        
        dName = [dName;dNameNw(2:end)];
    end
end
