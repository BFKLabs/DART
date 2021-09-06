% --- updates the commit history details for the current branch
function updateCommitHistoryDetails(handles,varargin)

% retrieves the index of the selected radio button
hRadio = findall(handles.panelVerFilt,'style','radiobutton','value',1);
vType = get(hRadio,'UserData');

if nargin == 1
    % creates the load bar (if updating by the version update button)
    if (vType == 1)
        h = ProgressLoadbar('Retrieving All Version History...');
    else
        h = ProgressLoadbar('Retrieving Filtered Version History...');    
    end
else
    % otherwise, don't create a progressbar
    h = [];
end
    
% initialisations
cID0 = NaN;
hFig = handles.figGitVersion;
iData = getappdata(hFig,'iData');
GF = getappdata(hFig,'GitFunc');
GB = getappdata(hFig,'GitBranch');
localBr = getappdata(hFig,'localBr');
gHistAll = getappdata(hFig,'gHistAll');

% retrieves the current branch
[cBr,isLW] = deal(GF.getCurrentBranch(),false);
if GF.uType > 0    
    % if current branch is the local-working branch then change to master
    [isLW,pBr] = deal(strContains(cBr,localBr),[]);
    if isLW
        cBr0 = cBr;
        [cBr,cID0] = GB.updateLocalWorkingBranch(); 
    end
    
else
    % retrieves the parent branch
    pBr = GB.getParentBranch();    
end    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    VERSION HISTORY FILTERING    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clears the history objects
versionHistSelect([], [])
set(handles.textFilePath,'string','')

% retrieves the struct branch string (removes any dashes
cBrStr = strrep(cBr,'-','');

% determines the version history based on the users selection
switch vType
    case (1)
        % retrieves the full history from the GUI
        [gHist,ok] = deal(eval(sprintf('gHistAll.%s',cBrStr)),1);
        if isempty(gHist)
            % if not already set, then retrieve the full history
            [gHist,ok] = getCommitHistory(GF,pBr);
            
            % updates the branch with the entire history
            eval(sprintf('gHistAll.%s = gHist;',cBrStr));
            setappdata(hFig,'gHistAll',gHistAll)
        end
        
    case (2)
        % case is the commit history count has been set
        [gHist,ok] = getCommitHistory(GF,pBr,'nHist',iData.nHist);
        
    case (3)
        % case is the start/finish date has been specified
        [gHist,ok] = getCommitHistory(GF,pBr,'d0',iData.dNum0,...
                                             'd1',iData.dNum1);
end

% updates the version count
vStr = sprintf('%i Matches From Version History Filter',length(gHist));
set(handles.textVerCount,'string',vStr)

% if there was an error, then exit the function
if ok
    setappdata(hFig,'gHist',gHist)
else
    return 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    EXPLORER TREE CREATIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% creates the explorer tree
[hTree,iCurr] = createVersionExplorerTree(handles,GF,gHist,cID0);

% sets up/creates the local branches (non-developers only)
isUpdate = true;
if GF.uType == 1
    % initialisations
    mChng = false;
    
    % retrieves the master branch commits + the head commit
    mID = field2cell(gHistAll.master,'ID');
    mIDH = GF.gitCmd('branch-head-commits','master');
    
    % determines the commit index of the master branch head
    indM = find(strContains(mID,mIDH));
    if indM > 1
        % reset the head if not in the proper location
        GF.gitCmd('hard-reset',mID{1});
        GF.gitCmd('checkout-version',mID{indM});
    end
        
    if isLW
        % resets the branch to the local working branch
        GB.updateLocalWorkingBranch(cBr0,cID0);                               

    elseif iCurr < 0
        % if the current version is not part of any local branch,
        % then reset the repository branch
        iCurr = 1;
        resetRepoBranches(handles,gHist(iCurr).ID);
        
    else
        % otherwise, determine if the current commit on the master branch
        % has a difference (and there are not local branches attached to
        % the master branch commit point)
        mChng = GF.detIfCodeChange();
    end
    
    % appends the local 
    [hTree,isUpdate] = appendLocalWorkingTreeNodes(hFig,GF,hTree,mChng); 
end

% updates the tree object handle within the GUI
set(handles.buttonUpdateFilt,'enable','off')
setappdata(hFig,'hTree',hTree)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    INFORMATION LABEL UPDATE    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% updates the 
if vType == 1 && (iCurr > 0) && isUpdate
    updateVersionDetails(handles,gHist(iCurr),iCurr)    
end

% deletes the loadbar (if one was created)
if ~isempty(h); delete(h); end