% --- updates the repository update information
function updateRepoInfo(gName)

% initialisations
nowStr = datestr(now,'yyyy-mm-dd HH:MM');
pFile = getParaFileName('RepoUpdate.mat');

% update information the version information parameter file
if exist(pFile,'file')
    % determines the matching repo
    A = load(pFile);
    iMatch = strcmp(A.grUpdate(:,1),gName);    
    if ~any(iMatch)
        % if there is no match then add in the repo
        A.grUpdate = [A.grUpdate;{gName,nowStr}]; 
        
    else
        % otherwise, update the time of the matching field
        A.grUpdate{iMatch,2} = nowStr;
    end
    
else
    % retrieves the repo information
    [~,~,~,gNameAll] = promptGitRepo(false); 
    
    % creates the repo update information data struct
    A = struct('grUpdate',[]);
    A.grUpdate = [gNameAll(:),repmat({nowStr},length(gNameAll),1)];
end

% resaves the parameter file
save(pFile,'-struct','A');