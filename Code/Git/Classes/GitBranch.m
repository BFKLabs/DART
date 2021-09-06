classdef GitBranch < handle
    % class properties
    properties(Hidden)
        GitFunc
        GitMenu
        bStrGrp
        bGrpType
        hMain
        mStr
        pWordHF               
    end
    
    % class methods
    methods
        % class constructor
        function obj = GitBranch(hMain,GitFunc,GitMenu)
            
            % initialisations
            obj.hMain = hMain;
            obj.GitFunc = GitFunc;
            obj.GitMenu = GitMenu;
            obj.pWordHF = 'BfkLabHF';
            obj.mStr = {'Create','Merge','Change','Delete'};
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
            %%%%    BRANCH INITIALISATIONS    %%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
            
            % ensures the local/remote branches match up correctly
            % (developers only)
            if obj.GitFunc.uType == 0
                obj.matchLocalRemoteBranches();  
            end
            
            % retrieves the branch names/group types
            [bStrGrp,bGrpType] = obj.groupBranchStrings();                         
            
            % sets the menu items
            obj.bStrGrp = bStrGrp;
            obj.bGrpType = bGrpType;            
        end
       
        % --- ensures that the local branches match the remote
        function matchLocalRemoteBranches(obj)
            
            % makes a fetch call to the origin
            obj.GitFunc.gitCmd('fetch-origin')

            % retrieves the local/remote branch names
            rmBr0 = strsplit(obj.GitFunc.gitCmd('branch-remote'),'\n');
            locBr0 = strsplit(obj.GitFunc.gitCmd('branch-local'),'\n'); 
            
            % strips off the extraneous name components
            rmBr = cellfun(@(x)(x(10:end)),rmBr0,'un',0);
            locBr = cellfun(@(x)(x(3:end)),locBr0,'un',0);
            
            % if the local/remote branches are the same then exit
            if isequal(rmBr,locBr)
                return
            end
            
            % retrieves the current branch            
            cBr = obj.GitFunc.getCurrentBranch();  
            isStashed = obj.GitFunc.detIfBranchModified();
            if isStashed; obj.GitFunc.gitCmd('stash'); end
            
            % creates remote branches missing from the local list
            for i = find(~cellfun(@(x)(any(strContains(rmBr,x))),locBr))
                % FINISN ME!
            end
            
            % creates local branches missing from the remote list
            for i = find(~cellfun(@(x)(any(strContains(locBr,x))),rmBr))
                obj.GitFunc.gitCmd('create-local',rmBr{i})
            end            

            % checks out the original local branch
            obj.GitFunc.gitCmd('checkout-local',cBr)
            if isStashed; obj.GitFunc.gitCmd('stash-pop'); end
            
        end  
        
        % --- groups the branch strings
        function [bStrGrp,bGrpType] = groupBranchStrings(obj)
            
            % sets the branch group type strings
            bGrpType = {'main','develop','feature','hotfix','other'};

            % memory allocation
            nGrp = length(bGrpType);
            bStrGrp = cell(nGrp,1);
            
            % retrieves all local/remote branch strings
            bStrSp = obj.getBranchNames(0);
            iType = zeros(length(bStrSp),1);
            
            % determines which are the main branches (master or develop) 
            isMain = strcmp(bStrSp,'master');
            
            % determines the feature/hotfix branch types
            iType(isMain) = nGrp-1;
            for iGrp = 2:(nGrp-1)
                isOK = cellfun(@(x)(strContains(x,bGrpType{iGrp})),bStrSp); 
                iType(isOK) = nGrp-iGrp;
            end
            
            % sets the branching string groups (based on type)
            for i = 1:nGrp
                bStrGrp{i} = bStrSp((nGrp-iType) == i);
            end                        
        end             
        
        % --- retrieves all local branch names
        function bStr = getBranchNames(obj,sType)
            
            % determines the existing branches (local only or local/remote)
            switch sType
                case 0
                    % case is checking local branches only
                    bStr0 = strsplit(obj.GitFunc.gitCmd('branch'),'\n'); 
                    
                otherwise
                    % case is checking the remote branches
                    if sType == 2
                        % pulls the latest version
                        obj.GitFunc.gitCmd('fetch-origin')
                    end
               
                    % sets the branch strings
                    bStr0 = strsplit(...
                                obj.GitFunc.gitCmd('all-branches'),'\n');
            end
                
            % removes the empty portion at the start of the stringd
            bStr = cellfun(@(x)(x(3:end)),bStr0,'un',0);
            bStr = bStr(~cellfun(@(x)(strContains(x,' ')),bStr));
        end        
        
        % --- retrieves the new branch name (based on the branch data)
        function nwBr = getBranchNameString(obj,iData)
            
            % determines what branch type the new branch is
            if strcmp(iData.bType,'main')
                % case is a main branch type
                nwBr = iData.bName;
            else
                % case is a sub-main branch type
                nwBr = sprintf('%s-%s',iData.bType,iData.bName);
            end            
        end                
        
        % --- determines if the new branch is duplicate
        function isDuplicate = checkDuplicateBranch(obj,nwBr)
            
            isDuplicate = any(strcmp(obj.getBranchNames(0),nwBr));
            
        end                    
        
        % --- determines if the hot-fix/create branch data is valid
        function [mStr,tStr] = checkBranchData(obj,iData)
            
            % sets the new branch name
            nwBr = obj.getBranchNameString(iData);
            
            % checks the new branch name/password
            if obj.checkDuplicateBranch(nwBr)
                % sets the suffix string (based on branch creation type)
                if isfield(iData,'pWordHF')
                    % case is hotfix branch creation
                    sStr = '';
                else
                    % case is general branch creation
                    sStr = '/type or parent branch';
                end
                
                % sets the duplicate branch error message
                mStr = sprintf(['Branch name already exists. Please ', ...
                                're-enter a new branch name%s.'],sStr);
                tStr = 'Duplicate Branch';     
                
            elseif isfield(iData,'pWordHF')
                % checks the password is correct (if active field)
                if ~strcmp(obj.pWordHF,iData.pWordHF)
                    % case is the password is incorrect
                    mStr = ['Entered password is incorrect. ', ...
                            'Please re-enter password and retry.'];
                    tStr = 'Incorrect Password';
                else
                    % case is there is no issue
                    [mStr,tStr] = deal([]);
                end
                
            else
                % case is there is no issue
                [mStr,tStr] = deal([]);                
            end
        end
        
        % --- creates a new hotifx branch using the data from iData
        function createNewHotfixBranch(obj,iData,h)
            
            % creates the load bar (if not provided)
            sStr = 'Creating New Hot-Fix Branch...';
            if ~exist('h','var')
                h = ProgressLoadbar(sStr); 
            else
                h.StatusMessage = sStr;
            end
            
            % sets the new branch/commit strings    
            cBr = obj.GitFunc.getCurrentBranch();
            nwBr = obj.getBranchNameString(iData);      
            obj.appendStructHistory(nwBr);  
            
            % sets the commit message/user name string
            mS = sprintf('%s (User: "%s")',iData.cMsg,iData.uName); 
            
            % stashes the current changes
            isStashed = obj.GitFunc.detIfBranchModified();
            if isStashed; obj.GitFunc.gitCmd('stash'); end
            
            % creates the local/remote branches
            obj.GitFunc.gitCmd('create-local-detached',nwBr)
            obj.createNewRemoteBranch(nwBr,nwBr)
            
            % checks out the remote branch and commits the stashed changes
            h.StatusMessage = 'Pushing Changes To Remote Branch';
            obj.GitFunc.gitCmd('stash-apply')
            
            % commits the latest changes to the branch
            cStatus = strsplit(obj.GitFunc.gitCmd('commit-all',mS),'\n');
            if any(strContains(cStatus,'git commit --amend --reset-author'))
                % if there is ambiguity about the user information, then
                % prompt the user for their info and reset
                uInfo = GitUserInfo(cStatus);
                
                % updates the user information and reset the commit author
                fType = 'set-global-config';
                obj.GitFunc.gitCmd(fType,'user.name',['"',uInfo.Name,'"'])
                obj.GitFunc.gitCmd(fType,'user.email',uInfo.Email)
            end            
            
            % pushes the changes to the remote branch
            obj.GitFunc.gitCmd('force-push-commit',nwBr);
            
            % checks out the original branch and pops the stashed changes
            obj.checkoutBranch('local',cBr)
            if isStashed; obj.GitFunc.gitCmd('stash-pop'); end
            
            % removes the origin url (non-developers only)
            if obj.GitFunc.uType > 0
                obj.GitFunc.gitCmd('delete-local',nwBr)
                obj.GitFunc.gitCmd('rmv-origin')
            end
            
            % deletes the loadbar
            delete(h)                   
        end
        
        % --- creates a new branch using the data from iData
        function createNewBranch(obj,iData)
            
            % initialisations
            eStr = {'off','on'};
            isDetached = isempty(obj.GitFunc.gitCmd('current-branch'));
            
            % creates the load bar
            h = ProgressLoadbar('Creating New Branch...');             
            
            % if the there are changes on the current branch then 
            % stash the changes           
            isMod = obj.GitFunc.detIfBranchModified();
            if isMod
                obj.GitFunc.stashBranchFiles();
            end                                     
            
            % sets the new branch/commit strings                 
            nwBr = obj.getBranchNameString(iData);      
            obj.appendStructHistory(nwBr);            
            
            % sets the commit message string
            mS = sprintf('1st Commit (Branched from ''%s'')',iData.pBr);
            
            % creates the new local/remote branches            
            obj.createNewRemoteBranch(iData.pBr,nwBr)            
            if isDetached
                % creates the new branch, adds the altered files and
                % creates the first commit
                obj.GitFunc.gitCmd('create-local-detached',nwBr);    
                obj.GitFunc.gitCmd('general','add -u');
                obj.GitFunc.gitCmd('commit-simple',mS);
                
            else
                % stashes any modified files
                obj.GitFunc.stashBranchFiles() 
                
                % otherwise, create a new branch with an empty commit
                obj.GitFunc.gitCmd('create-local',nwBr)
                obj.GitFunc.gitCmd('commit-empty',mS);
            end
            
            % creates a new commit and forces pushes to the branch
            obj.GitFunc.gitCmd('force-push');
            
            % deletes the progressbar and exits (non-developer only)            
            if obj.GitFunc.uType > 0
                % checks out the master branch again
                obj.GitFunc.gitCmd('checkout-local','master');
                obj.GitFunc.gitCmd('delete-local',nwBr);
                obj.GitFunc.gitCmd('rmv-origin');
                
                % unstashes the files (if required)
                if isMod
                    obj.GitFunc.unstashBranchFiles();
                end
                
                % deletes the progressbar and exits the function
                delete(h)
                return
            end
            
            % appends the new branch name to the menu names
            iType = find(strcmp(obj.bGrpType,iData.bType));
            if isempty(obj.bStrGrp{iType})
                obj.bStrGrp{iType} = {nwBr};
            else
                obj.bStrGrp{iType}{end+1} = nwBr;
            end
            
            % retrieves the main menu items
            hMenu = cellfun(@(x)(findall(...
                    obj.hMain.menuBranch,'tag',x)),obj.mStr,'un',0);            
            
            % calculates the number of menu items per grouping
            nMenu = cellfun(@length,obj.bStrGrp);
            
            % creates the new menu item
            for i = 3:4
                % sets the callback function
                mStrM = lower(get(hMenu{i},'tag'));
                cbFcn = sprintf('@GitMenu.%sBranch',mStrM);
                
                % creates the menu item
                hMenuNw = uimenu(hMenu{i},'Label',nwBr,...
                               'Callback',{eval(cbFcn),obj.GitMenu});
                switch mStrM
                    case 'change'
                        iPos = sum(nMenu(1:iType));
                        isSep = nMenu(iType) == 1;
                    case 'delete'
                        iPos = sum(nMenu(2:iType)) + (nMenu(1)-1);
                        isSep = (nMenu(iType) == 1) && ...
                            (length(get(hMenu{i},'Children')) > 1);                        
                end
                
                % sets the other menu properties
                set(hMenuNw,'Position',iPos,'Separator',eStr{1+isSep});                
                if strcmp(mStrM,'change') && (~isDetached)                
                    % unchecks the previous/checks the new menu item
                    hMenuPr = findall(hMenu{i},'checked','on');
                    set(hMenuPr,'checked','off')
                    set(hMenuNw,'checked','on')            
                end
                
                % enables parent menu item
                set(hMenu{i},'enable','on')                
            end
            
            if ~isDetached
                % updates the current branch to the new branch
                set(obj.hMain.textCurrBranch,'string',nwBr)

                % removes all merge sub-menus and disables the merge menu
                hMenuM = get(hMenu{2},'Children');
                if ~isempty(hMenuM); delete(hMenuM); end
                set(hMenu{2},'enable','off')

                % updates the commit history details            
                obj.updateCommitHistoryInfo()                
            end
            
            % deletes the loadbar
            delete(h)            
        end                
        
        % --- restores the deleted branch, delBr
        function restoreDeletedBranch(obj,delBr,cID)
            
            % initialisations
            eStr = {'off','on'};
            
            % creates the load bar
            h = ProgressLoadbar('Restoring Deleted Branch...');                            
                
            % stashes any modified files
            obj.GitFunc.stashBranchFiles()            
            
            % recreates the deleted local/remote branches    
            obj.appendStructHistory(delBr);                    
            obj.GitFunc.gitCmd('fetch-origin',cID); 
            obj.GitFunc.gitCmd('create-fetch-branch',delBr); 
            obj.GitFunc.gitCmd('force-push-commit',delBr,1);
                        
            % appends the new branch name to the menu names
            iType = find(cellfun(@(x)(strContains(delBr,x)),obj.bGrpType));
            if isempty(obj.bStrGrp{iType})
                obj.bStrGrp{iType} = {delBr};
            else
                obj.bStrGrp{iType}{end+1} = delBr;
            end
            
            % retrieves the main menu items
            hMenu = cellfun(@(x)(findall(...
                    obj.hMain.menuBranch,'tag',x)),obj.mStr,'un',0);             
            
            % calculates the number of menu items per grouping
            nMenu = cellfun(@length,obj.bStrGrp);
            
            % creates the new menu item
            for i = 3:4
                % sets the callback function
                mStrM = lower(get(hMenu{i},'tag'));
                cbFcn = sprintf('@GitMenu.%sBranch',mStrM);
                
                % creates the menu item
                hMenuNw = uimenu(hMenu{i},'Label',delBr,...
                               'Callback',{eval(cbFcn),obj.GitMenu});
                switch mStrM
                    case 'change'
                        iPos = sum(nMenu(1:iType));
                        isSep = nMenu(iType) == 1;
                    case 'delete'
                        iPos = sum(nMenu(2:iType)) + (nMenu(1)-1);
                        isSep = (nMenu(iType) == 1) && ...
                            (length(get(hMenu{i},'Children')) > 1);                        
                end
                
                % sets the other menu properties & enables parent menu item
                set(hMenuNw,'Position',iPos,'Separator',eStr{1+isSep});                    
                setObjEnable(hMenu{i},1)                
            end       
            
            % creates the merge branch sub-menus                    
            obj.createMergeBranchMenus(obj.GitMenu)            
            
            % deletes the loadbar              
            delete(h)
            
        end        
        
        % --- removes any remote stale branches 
        function removeStaleBranches(obj)
            
            obj.GitFunc.gitCmd('remove-stale-dryrun');
            obj.GitFunc.gitCmd('remove-stale-final');   
            
        end        
        
        % --- reverts a branch back to a specific commit ID
        function revertBranch(obj,cID)
            
            obj.GitFunc.gitCmd('revert-branch',cID);
            obj.GitFunc.gitCmd('commit');
            
        end
        
        % --- retrieves the index of the branch group type
        function iType = getBranchGroupType(obj,bName)
            
            if strContains(bName,'-')
                % case is a non-main branch
                iType = find(cellfun(@(x)(...
                                startsWith(bName,x)),obj.bGrpType));
            else
                % case is the main branch
                iType = 1;
            end
            
        end        
        
        % --- removes the branch name from the group strings
        function iType = removeBranchString(obj,delBr)
            
            % determines the index of the branch group type
            iType = obj.getBranchGroupType(delBr);
            
            % removes the branch from the grouping
            isKeep = ~strcmp(obj.bStrGrp{iType},delBr);
            obj.bStrGrp{iType} = obj.bStrGrp{iType}(isKeep);
            
        end    
        
        % --- determines if there are any unresolved modifications to 
        %     the current branch
        function uStatus = checkBranchModifications(obj,h)
            
            % initialisations
            uStatus = 0;
            
            % determine if there is any modifications to the
            % code within the current branch
            if obj.GitFunc.detIfBranchModified()
                % if the loadbar exists, then makes it invisible
                if ~isempty(h); set(h.Control,'visible','off'); end 

                % if so, then prompt user if they want to stash, commit
                % or ignore the changes
                uChoice = obj.promptUserChange();
                switch uChoice
                    case 'Create Branch'
                        % case is creating a new branch (which is the case
                        % when changing from a modified detached branch)
                        iData = GitCreate(obj.GitMenu);            
                        if isempty(iData)
                            % user cancelled or there was an error
                            uStatus = 1;
                            return
                        else
                            % if the user didn't cancel, then create 
                            % a new branch
                            obj.createNewBranch(iData)
                            uStatus = 3;
                        end                        
                        
                    case 'Commit'
                        % case is commit changes                            
                        GitCommit(obj.hMain.figGitVersion,obj.GitFunc);

                    case 'Stash'
                        % case is stashing changes
                        obj.GitFunc.stashBranchFiles()

                    case 'Ignore'
                        % case is ignoring the changes
                        uStatus = 2;
                        
                    case 'Cancel'
                        % case is cancelling (exit function) 
                        uStatus = 1;
                        return
                end

                % if the loadbar exists, then makes it visible again
                if ~isempty(h)
                    set(h.Control,'visible','on'); 
                    pause(0.01)
                end                     
            end            
            
        end

        % --- changes the branches to that specified by nwBr
        function isOK = changeLocalBranch(obj,nwBr,changeOnly,h)
            
            % sets the default input arguments
            isOK = true;
            if nargin < 3; changeOnly = false; end            
            if nargin < 4; h = []; end            
            
            % determines if a straight change is required
            if changeOnly
                % if so, then stash the current branch files, change the 
                % branch and then unstash the files from the new branch
                obj.GitFunc.stashBranchFiles()
                obj.checkoutBranch('local',nwBr)
                obj.GitFunc.unstashBranchFiles()
            else
                % checks if there are any branch modifications, and, if so
                % how the user wants to handle it
                uStatus = obj.checkBranchModifications(h);
                switch uStatus
                    case 1
                        % case is the user cancelled
                        isOK = false;
                        return
                        
                    case 2
                        % case is ignoring the changes (force checkout)
                        cID = obj.GitFunc.gitCmd('commit-id');
                        obj.GitFunc.gitCmd('force-checkout',cID);
                        
                        % checkouts the new branch
                        obj.checkoutBranch('local',nwBr)                        
                        
                    otherwise
                        % otherwise, checkout the new branch
                        obj.checkoutBranch('local',nwBr)

                end               
                
                % creates the merge branch sub-menus
                obj.GitFunc.unstashBranchFiles()                      
                obj.createMergeBranchMenus(obj.GitMenu)
            end
            
        end     
        
        % --- creates the merge branch menus
        function createMergeBranchMenus(obj,mObj)
            
            % initialisations
            [parentOnly,iGrpT] = deal(0,[]);
            [mStrM,eStr] = deal('Merge',{'off','on'});            
            
            % finds the merge menu 
            hMenuP = findall(obj.hMain.menuBranch,'tag',mStrM);
            cbFcn = sprintf('@GitMenu.%sBranch',lower(mStrM));
            
            % deletes any previous menu-items
            hMenuOld = get(hMenuP,'Children');
            if ~isempty(hMenuOld); delete(hMenuOld); end
            
            % retrieves the current branch and, from this, determines which
            % branches this branch can merge into
            cBr = obj.GitFunc.getCurrentBranch();
            if startsWith(cBr,'develop')
                % case is a development branch (only merge into master)
                parentOnly = 1;
            
            elseif startsWith(cBr,'feature')
                % case is a feature branch (only merge into parent
                % development branch)
                parentOnly = 1;   
                
            elseif startsWith(cBr,'hotfix')
                % case is a hot-fix branch (only merge into master or
                % development branches)
                iGrpT = find(strcmp(obj.bGrpType,'main') | ...
                             strcmp(obj.bGrpType,'develop'));                
            
            elseif startsWith(cBr,'other')
                % case is an other branch (only merge into parent)
                parentOnly = 1;
            end            
            
            % determines if there are any branches to add
            if isempty(iGrpT) && (~parentOnly)
                % if there are no children branches then disable the parent
                set(hMenuP,'enable','off')                
            else
                % otherwise, enable the parent menu
                set(hMenuP,'enable','on')
                
                % determines only the parent branch is being
                if parentOnly
                    % case is only the parent branch is being added
                    addBr = {{obj.getParentBranch(cBr)}};
                else
                    % case is specific group
                    addBr = obj.bStrGrp(iGrpT);
                end                                
                            
                % creates the sub-menu items
                for i = 1:length(addBr)
                    for j = 1:length(addBr{i})                    
                        % creates the create menu item 
                        hMenu = uimenu(hMenuP,'Label',addBr{i}{j},...                                       
                                              'Tag',addBr{i}{j});
                                   
                        % sets the menu callback function/separator           
                        set(hMenu,'Callback',{eval(cbFcn),mObj},...
                                  'Separator',eStr{1+((i>1)&&(j==1))})                    
                    end
                end
            end
        end
        
        % --- checks out a branch (either local, remote or version) 
        %     add/removes any directories that are not part of current
        function checkoutBranch(obj,chkType,chkData)
            
            % retrieves the current commit ID
            cID = obj.GitFunc.gitCmd('commit-id');

            % retrieves the commit ID of the new branch
            switch chkType
                case 'local' % case is checking out the local branch head 
                    % retrieves the commit ID of the local branch
                    nwID = obj.GitFunc.gitCmd('commit-id',chkData);

                case 'remote' % case is checking out a remote branch
                    rmBr = sprintf('origin/%s',chkData);
                    if obj.GitFunc.uType > 0
                        obj.GitFunc.gitCmd('set-origin');
                    end

                    % retrieves all branches and determines if the input branch
                    % is part of the remote branches
                    obj.GitFunc.gitCmd('fetch-origin')

                    % retrieves the commit ID of the remote branch
                    nwID = obj.GitFunc.gitCmd('commit-id',rmBr);              

                case 'version' % case is checking out branch version
                    % input data is the commit ID
                    nwID = chkData;

            end

            % adds/removes the directories between versions
            obj.GitFunc.addRemoveDir(cID,nwID)   

            % checks out the branch/version based on the type
            switch chkType
                case 'local' % case is checking out the local branch head 
                    obj.GitFunc.gitCmd('checkout-local',chkData);

                case 'remote' % case is checking out a remote branch
                    obj.GitFunc.gitCmd('hard-reset',nwID,1);

                    % removes the origin url (non-developers only) 
                    if obj.GitFunc.uType > 0
                        obj.GitFunc.gitCmd('rmv-origin');
                    end                  

                case 'version' % case is checking out branch version
                    obj.GitFunc.gitCmd('checkout-version',chkData);

            end
        
        end

        % --- updates the local working branch
        function varargout = updateLocalWorkingBranch(obj,localBr,vID)

            % sets the default input arguments
            if ~exist('localBr','var'); localBr = 'LocalWorking1'; end

            if nargout == 2
                % stashes any local changes
                varargout = {'master',obj.GitFunc.gitCmd('commit-id')};
                obj.GitFunc.gitCmd('stash-save',localBr);

                % resets the current branch to the master   
                obj.GitFunc.gitCmd('checkout-local',varargout{1});
                
            else
                % resets the current branch to the local working branch 
                gHistL = getLocalCommitHistory(obj.GitFunc,localBr);
                if strcmp(gHistL(1).ID,vID)   
                    % checks out the branch head
                    obj.GitFunc.gitCmd('checkout-local',localBr);
                else
                    % otherwise, check out the branch version
                    obj.GitFunc.gitCmd('checkout-version',vID);
                end

                % un-stashes any local changes
                iList = obj.GitFunc.detStashListIndex(localBr);
                if ~isempty(iList)
                    obj.GitFunc.resolveStashPop(iList-1);
                end                   
            end

        end        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%    CHILDREN/PARENTS FUNCTIONS    %%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                
        
        % --- determines the parent branch from the current branch
        function pBr = getParentBranch(obj,cBr,getFirstOnly)
            
            % sets the default parameter (if not provided)
            if nargin < 3; getFirstOnly = true; end
            
            % retrieves the current branch (if not provided)           
            if nargin == 1
                [cBr,isDetached] = obj.GitFunc.getCurrentBranch();
                if isDetached
                    if strcmp(cBr,'master')
                        % case is the master branch (no parent branch)
                        pBr = [];
                    else
                        % retrieves the current commit ID 
                        cID = obj.GitFunc.gitCmd('commit-id');

                        % checks out the detached branch head, determines
                        % the parent for that branch then returns to the
                        % current version
                        obj.checkoutBranch('local',cBr)
                        pBr = obj.getParentBranch(cBr);
                        obj.checkoutBranch('version',cID)           
                    end
                        
                    % exits the function
                    return
                end
            end
            
            %
            if strcmp(cBr,'master')
                % case is the master branch (which has not parent)
                pBr = [];
                
            elseif strContains(cBr,'hotfix-') || strContains(cBr,'LocalW')
                % case is a hot-fix branch
                pBr = 'master';
                
            else
                % retrieves the parent branch from the ref-log string
                lStr = obj.GitFunc.gitCmd('log-grep','Branched from',cBr);  
                hGrp = getCommitHistGroups(lStr);
                
                % retrieves all parent branch strings from the commit
                % matches
                pat = '''(.*?)''';
                pBr = cell2cell(cellfun(@(x)(regexp(x{end},...
                                    pat,'tokens','once')),hGrp,'un',0));
                if getFirstOnly
                    % returns the first match (if getting first parent)
                    pBr = pBr{1}; 
                end
            end
            
        end     
        
        % --- determines if a branch, brStr, exists locally
        function isBr = isLocalBranch(obj,brStr)
            
            isBr = strContains(obj.GitFunc.gitCmd('branch'),brStr);
            
        end
        
        % --- determines the parent branch from a deleted branch
        function pBr = getDeletedParentBranch(obj,cID)
            
            % retrieves the commit messages that preceding the commit ID
            delBrMsg = strsplit(...
                        obj.GitFunc.gitCmd('get-commit-msg',cID,1),'\n');
                    
            % determines the first branch message (the parent branch)
            iBr = find(cellfun(@(x)(strContains(...
                        x,'Branched from')),delBrMsg(:)),1,'first');             
            brMsg0 = regexp(delBrMsg{iBr}, '[^'']*', 'match');
            
            % sets the deleted branches' parent branch string
            pBr = brMsg0{2}; 
            
        end
        
        % --- determines all the children branches
        function chBr = getChildrenBranches(obj,cBr)
            
            % retrieves the current branch (if not provided)           
            if nargin == 1
                cBr = obj.GitFunc.getCurrentBranch();
            end
            
            % otherwise, shows all of the branches (removes any version
            % numbers from the branch names)
            repPat = '~(\d)|\^';
            showBr = cellfun(@(x)(regexprep(x,repPat,'')),strsplit(...
                obj.GitFunc.gitCmd('show-branches'),'\n')','un',0);
            
            % determines all groups (with '*''s) after the separator
            iSep = find(cellfun(@(x)(strcmp(x(1),'-')),showBr))+1;
            indSep = iSep:length(showBr);
            
            %
            brName = obj.stripBranchNames(showBr(indSep));
            [~,~,iC] = unique(brName);
            iGrp = sort(arrayfun(@(x)(find(iC==x,1,'last')),1:max(iC)));            
            [showBr,brName] = deal(showBr(indSep(iGrp)),brName(iGrp));     
                        
            % determines the column containing the children/parent markers
            iCol = 1:(strfind(showBr{1},'[')-2);
            indCol = cellfun(@(x)(strfind(x(iCol),'+')),showBr,'un',0);
            
            % determines the index of the current branch
            icBr = find(cellfun(@(x)(...
                            strContains(x,sprintf('[%s]',cBr))),showBr));     
            if length(icBr) > 1
                icBr = icBr(end);
            end
                        
            % determines which branches are children to the current
            isCh = false(length(indCol),1);
            for i = 1:(icBr-1)
                if i ~= icBr
                    isCh(i) = ~isempty(intersect(indCol{icBr},indCol{i}));
                end
            end
            
            % returns the final children branches
            if any(isCh)
                chBr = brName(isCh);
            else
                chBr = [];
            end
            
        end
        
        % --- determines all related (children/parent) branches
        function allBr = getAllRelatedBranches(obj)
            
            % retrieves the current and all local branch names
            bStr = obj.getBranchNames(0);
            cBr0 = obj.GitFunc.getCurrentBranch();
            
            % retrieves the children/parent branches for each local branch
            allBr = struct();
            for i = 1:length(bStr) 
                % changes the branch 
                obj.changeLocalBranch(bStr{i},true);
                
                % retrieves the parent/children branches
                pBr = obj.getParentBranch(bStr{i});
                chBr = obj.getChildrenBranches(bStr{i});
                
                % updates the data struct
                nwStr = struct('pBr',[],'chBr',[]);
                [nwStr.pBr,nwStr.chBr] = deal(pBr,chBr);
                eval(sprintf('allBr.%s = nwStr;',strrep(bStr{i},'-','')));                
            end
            
            % changes the branch back to the original branch
            obj.changeLocalBranch(cBr0,true);
            
        end
        
        % --- resets the master branch to that from the origin
        function resetMasterBranch(obj)
            
            % sets the origin URL (non-developer only)
            if obj.GitFunc.uType > 0
                obj.GitFunc.gitCmd('set-origin');
            end
            
            % performs hard reset from the origin/master branch
            obj.GitFunc.gitCmd('fetch-origin');
            obj.GitFunc.gitCmd('hard-reset','origin/master');          
            
            % removes the origin URL (non-developer only)
            if obj.GitFunc.uType > 0
                obj.GitFunc.gitCmd('rmv-origin');
            end            
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%    STRUCT HISTORY FUNCTIONS    %%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        
        % --- appends the new branch to history struct
        function appendStructHistory(obj,nwBr)
            
            % appends an empty field to data struct and updates it
            gHistAll = getappdata(obj.hMain.figGitVersion,'gHistAll');
            eval(sprintf('gHistAll.%s = [];',strrep(nwBr,'-','')));
            setappdata(obj.hMain.figGitVersion,'gHistAll',gHistAll)
            
        end
           
        % --- appends the new branch to history struct
        function removeStructHistory(obj,delBr)
            
            % removes the field from the data struct and updates it
            gHistAll = getappdata(obj.hMain.figGitVersion,'gHistAll');            
            gHistAll = rmfield(gHistAll,strrep(delBr,'-',''));
            setappdata(obj.hMain.figGitVersion,'gHistAll',gHistAll)
            
        end                     
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%    MISCELLANEOUS FUNCTIONS    %%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
        
        % --- updates the commit history details
        function updateCommitHistoryInfo(obj)
            
            % set radio button to all version histories
            set(obj.hMain.radioAllVer,'value',1);
        
            % updates the panel from the version GUI
            updateFcn = getappdata(obj.hMain.figGitVersion,'updateFcn');
            updateFcn(obj.hMain.panelVerFilt,'1',obj.hMain)
            
            % updates the commit history details
            updateCommitHistoryDetails(obj.hMain,1)
            
        end     
        
        % --- retrieves the final branch name 
        function brName = stripBranchNames(obj,showBr)
            
            % retrieves the regexp pattern string
            strPat = '\[(\w*\-\w*)\]|\[(\w*\~\w*)\]|\[(\w*)\]';
            
            % retrieves the branch names
            brName0 = cellfun(@(x)(regexp(x,...
                        strPat,'match','once')),showBr,'un',0);            
            brName = cellfun(@(x)(x(2:end-1)),brName0,'un',0);
            
        end
        
        % --- prompts the user what action they want to do take given
        %     there is a change in the current branch
        function uChoice = promptUserChange(obj)
            
            % sets the title/button strings
            tStr = 'Code Changes Detected';
            bStr = {'Commit','Stash','Ignore','View','Cancel'};
            
            if obj.GitFunc.uType > 0
                % user is not a developer (not able to make commits/stash)
                [i0,sStr] = deal(3,'Ignore');  
                
            else
                % case is a developer, so determines if branch is detached
                [~,isDetached] = obj.GitFunc.getCurrentBranch; 
                if isDetached
                    % if detached, then can only create a new branch
                    bStr{2} = 'Create Branch';
                    [i0,sStr] = deal(2,'Create a new ranch');                       
                else
                    % not detached so able to make commits
                    [i0,sStr] = deal(1,'Commit, Stash');   
                end
            end
            
            % sets the button/message string
            qStr = sprintf(['Changes have been detected on the ',...
                            'current branch.\nDo you want to %s ',...
                            'or Ignore these changes?'],sStr);
            
            % prompts the user for what action they wish to take
            while 1
                uChoice = QuestDlgMulti(bStr(i0:end),qStr,tStr);
                if strcmp(uChoice,'View')
                    % views the current changes on the branch
                    waitfor(GitViewChanges(obj.GitFunc))
                    
                else
                    % otherwise, exit the loop
                    break
                end
            end
            
        end             
    end
end
