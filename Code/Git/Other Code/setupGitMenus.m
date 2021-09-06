% --- sets up the git menu items
function setupGitMenus(hFig)

% global variables
global mainProgDir

if ~exist(fullfile(mainProgDir,'.git'),'file')
    % if the git directory does not exist in the main directory, then exit
    return
elseif ~isempty(findall(hFig,'tag','hGitP'))
    % if the Git menu already exists, then exit
    return
end

% sets up the GitFunc class object
GF = GitFunc();

% sets the global configuration fields
GF.gitCmd('set-global-config','core.autocrlf','false');

% creates the parent menu item
hGitP = uimenu(hFig,'Label','Git','tag','hGitP');

% creates the menu items
uimenu(hGitP,'Label','Version Control','Callback',...
             {@GV_Callback,hFig},'tag','menuGV');
if GF.uType == 0        
    uimenu(hGitP,'Label','Commit Changes','Callback',...
                 {@GC_Callback,hFig},'tag','menuGC');
end
uimenu(hGitP,'Label','Submit Issue','Separator','On','Callback',...
             {@SI_Callback,hFig},'tag','menuSI');
uimenu(hGitP,'Label','Version Information','Callback',...
             {@VI_Callback,hFig},'tag','menuVI');         

% --- version control menu item callback function
function GV_Callback(hObject, eventdata, hFig)

% runs the Git Version GUI
GitVersion(hFig)

% --- commit changes menu item callback function
function GC_Callback(hObject, eventdata, hFig)

% runs the Git Commit GUI
GitCommit(hFig)

% --- commit changes menu item callback function
function SI_Callback(hObject, eventdata, hFig)

% runs the Submit Issue GUI
SubmitIssue(hFig)

% --- commit changes menu item callback function
function VI_Callback(hObject, eventdata, hFig)

% runs the Git Version Information
GitVerInfo()
