% --- checks that the git function version is up to date (for non-developed
%     users only)
function checkGitFuncVersion()

% sets up the GitFunc class object
GF0 = GitFunc();

% if a developer, then exit the function
if GF0.uType == 0
    return
end

% initialisations
rType = 'Git';
gDirP = getProgFileName('Git');
gRepoDir = fullfile(gDirP,'Repo','DARTGit');
gName = 'Git Functions';

% creates the git function object
gitEnvVarFunc('add','GIT_DIR',gRepoDir)
GF = GitFunc(rType,gDirP,gName);

% removes/sets the origin url
GF.gitCmd('rmv-origin')
GF.gitCmd('set-origin')

% determines the current/head commit ID
cID0 = GF.gitCmd('commit-id','origin/master');
cIDH = GF.gitCmd('branch-head-commits','master');
if ~startsWith(cID0,cIDH)
    % if they don't match, then reset the repository so that it matches the
    % remote repository
    GF.matchRemoteBranch('master');
end

% removes the git directory environment variables
gitEnvVarFunc('remove','GIT_DIR');
GF.gitCmd('rmv-origin');

% sets the directory to the main
cd(getProgFileName())