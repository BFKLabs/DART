classdef GitMenu < handle
    % class properties
    properties(Hidden)
        GitFunc
        GitBranch
        hMenu
        hMain
    end

    % class methods
    methods
        % class constructor
        function obj = GitMenu(hMain,GitFunc)
            
            % initialisations
            obj.GitFunc = GitFunc;
            obj.GitBranch = GitBranch(hMain,GitFunc,obj);
            obj.hMain = hMain;
            
            % sets the main branch menu item
            hMenuP = hMain.menuBranch;     
            hMenuI = hMain.menuInfo;               
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
            %%%%    HOT-FIX MENU ITEM    %%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if obj.GitFunc.uType ~= 0
                % creates the hot-fix menu item (user-only)
                hfFcn = {@GitMenu.hotfixBranch,obj};
                uimenu(hMenuP,'Label','Create Hot-Fix','Callback',hfFcn)
                
                % removes the information menu item
                set(hMenuI,'visible','off')
            
                % if not a developer, then exit the constructor
                return
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
            %%%%    OTHER BRANCH MENU ITEM    %%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            

            % fetches the origin
            obj.GitFunc.gitCmd('fetch-origin')  

            % menu labels/strings
            eStr = {'off','on'};
            bStrGrp = obj.GitBranch.bStrGrp;
            mStr = {'Create','Merge','Change','Delete'};
            mType = cellfun(@lower,mStr,'un',0);               
            
            % retrieves/sets the current branch
            cBr = obj.GitFunc.getCurrentBranch();
            set(hMain.textCurrBranch,'string',cBr)            
            
            % other initialisations
            nMenu = cellfun(@length,bStrGrp);
            hMenu = cell(length(mStr),1);
            
            % creates the branch menu items
            for i = 1:length(mStr)
                % creates the menu item
                hMenu{i} = uimenu(hMenuP,...
                                 'Label',sprintf('%s Branch',mStr{i}),...
                                 'Separator',eStr{1+(i==1)},'tag',mStr{i});
                switch mStr{i}
                    case {'Create','Merge'}
                        % flag that the inner loop won't be entered
                        i0 = length(bStrGrp) + 1;
                        
                        % creates the merge sub-branches (if merge branch)
                        if strcmp(mStr{i},'Merge')
                            % case is the merge branch sub-menus
                            obj.GitBranch.createMergeBranchMenus(obj)
                        else
                            % otherwise, setup the create menu item
                            cbFcn = sprintf('@GitMenu.%sBranch',mType{i});
                            set(hMenu{i},'Callback',{eval(cbFcn),obj})                            
                        end
                    
                    case 'Delete'                        
                        nMenu = cellfun(@length,bStrGrp);
                        set(hMenu{i},'enable',eStr{1+(sum(nMenu)>1)})
                        if any(nMenu>0)
                            i0 = find(nMenu(2:end)>0,1,'first')+1;
                        else
                            i0 = length(bStrGrp)+1;
                        end
                                            
                    otherwise
                        i0 = 1;
                        set(hMenu{i},'enable',eStr{1+(sum(nMenu)>1)})
                end
                                                           
                for j = i0:length(bStrGrp)
                    % sets the initial index
                    k0 = 1 + (strcmp(mStr{i},'Delete') && (j==1));                    
                    for k = k0:length(bStrGrp{j})
                        % sets the callback function
                        cbFcn = sprintf('@GitMenu.%sBranch',mType{i});
                        
                        % creates the sub-menu item
                        hasSep = (k==1) && ...
                                (j>(find(nMenu(i0:end),1,'first')+(i0-1)));
                        hMenuS = uimenu(hMenu{i},...
                                        'Label',bStrGrp{j}{k},...
                                        'Separator',eStr{1+hasSep},...
                                        'Callback',{eval(cbFcn),obj});                        
                                    
                        if strcmp(mType{i},'change') && ...
                                            strcmp(bStrGrp{j}{k},cBr)
                            set(hMenuS,'checked','on')
                        end
                    end
                end
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
            %%%%    STASHED/RESET BRANCH MENU ITEM    %%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%             
            
            % creates the fetch remote menu item
            frFcn = {@GitMenu.fetchRemote,obj};
            uimenu(hMenuP,'Label','Fetch Remote','Callback',frFcn,...
                          'Separator','on','tag','Fetch');
            
            % creates the stashed branches menu item
            sbFcn = {@GitMenu.stashedBranches,obj};
            uimenu(hMenuP,'Label','Stashed Branches','Callback',sbFcn,...
                          'Separator','on','tag','Stashed');
                      
            % creates the reset branches menu item
            rbFcn = {@GitMenu.resetBranch,obj};
            uimenu(hMenuP,'Label','Reset Branch','Callback',rbFcn,...
                          'Separator','off','tag','Reset');            
                      
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%    REFERENCE LOG MENU ITEM    %%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                      
            % creates the reference log menu item
            rlFcn = {@GitMenu.reflogBranch,obj};
            uimenu(hMenuI,'Label','Reference Log','Callback',rlFcn,...
                          'Separator','off','tag','RefLog');
                      
            % creates the reference log menu item
            rlFcn = {@GitMenu.branchInfo,obj};
            uimenu(hMenuI,'Label','Branch Information','Callback',rlFcn,...
                          'Separator','off','tag','BranchInfo');
                      
            % sets the menu items
            obj.hMenu = hMenu;
        end                           
    end
    
    % class static methods
    methods (Static)
        
        % --- branch hot-fix callback function
        function hotfixBranch(hMenu,~,obj)
            
            % if there are no modifications, output an error and exit
            if ~obj.GitFunc.detIfBranchModified()
                % error dialog inputs
                tStr = 'No Code Alterations Detected?';
                eStr = sprintf(['There are currently no modifications ',...
                                'within the code on this branch.\nYou ',...
                                'will not be able to create such a ',...
                                'branch until you make changes.']);
                            
                % outputs the error to screen and exits
                errordlg(eStr,tStr,'modal')
                return
            end
            
            % prompts the user for the branch creation information
            iData = GitHotfix(obj);
            if ~isempty(iData)
                % if the user didn't cancel, then create a new hot-fix
                % branch from the master branch
                obj.GitBranch.createNewHotfixBranch(iData)
            end 
            
        end          
        
        % --- branch creation callback function
        function createBranch(hMenu,~,obj)
            
            % prompts the user for the branch creation information
            iData = GitCreate(obj);            
            if ~isempty(iData)
                % if the user didn't cancel, then create a new branch
                obj.GitBranch.createNewBranch(iData)
            end                 
            
        end
        
        % --- branch merge callback function
        function mergeBranch(hMenu,~,obj)
            
            % if there are uncommited changes, then output an error to
            % screen and exit the function            
            if obj.GitFunc.detIfBranchModified()
                eStr = sprintf(['Unable to merge as there are ',...
                                'uncommitted changes on this branch.\n',...
                                'Commit the changes before re-',...
                                'attempting to merge.']);
                waitfor(errordlg(eStr,'Branch Merge Failed','modal'))
                return
            end

            % initialisations
            mBr = get(hMenu,'label');
            cBr = obj.GitFunc.getCurrentBranch();
            hGV = findall(0,'tag','figGitVersion');
            
            % checks out the branch to merge with and runs the 
            obj.GitBranch.checkoutBranch('local',mBr)
                        
            % determines if there were any merged/conflicted files            
            obj.GitFunc.gitCmd('merge-no-commit',cBr);      
            
            % determines if there are any merge conflict/differences
            dcFiles = obj.GitFunc.getMergeDCFiles();         
            if ~isempty(dcFiles)
                if isempty(dcFiles.Conflict)
                    mStr0 = 'Differences';
                elseif isempty(dcFiles.Diff)
                    mStr0 = 'Merge conflicts';                    
                else
                    mStr0 = 'Merge conflicts and differences';                    
                end
                
                % outputs a message to screen indicating a merge is reqd
                mStr = sprintf(['%s exist between the branches.\n',...
                                'You will need to resolve these before ',...
                                'completing the final merge.'],mStr0);
                waitfor(msgbox(mStr,'Merge Conflict/Differences','modal'))
                
                % if so, then prompt the user to manually alter the files 
                % until either they cancel or successfully merged      
                set(hGV,'visible','off')
                isCont = GitMergeDiff(obj,dcFiles,mBr,cBr,obj.GitFunc);  
                set(hGV,'visible','on')
                
                % aborts the merge
                if isCont
                    for i = 1:length(dcFiles.Diff)
                        if isempty(dcFiles.Diff(i).Path)
                            dFile = dcFiles.Diff(i).Name;
                        else
                            dFile = sprintf('%s/%s',dcFiles.Diff(i).Path,...
                                                    dcFiles.Diff(i).Name);
                        end
                        
                        obj.GitFunc.gitCmd('add-file',dFile);
                    end
                else
                    % if the user aborted the merge, then revert back to
                    % the original branch and exit the function   
                    obj.GitFunc.gitCmd('abort-merge')
                    obj.GitBranch.checkoutBranch('local',cBr)
                    return
                end
            end
            
            % clears the git history struct for the merged branch
            obj.GitFunc.clearGitHistory(mBr)

            % if the user successfully merged all files, then finish the 
            % merge process and update the history
            h = ProgressLoadbar('Committing Completed Merge...'); 
            cMsg = sprintf('Merged from "%s"',cBr);
            obj.GitFunc.gitCmd('commit-simple',cMsg);  
            obj.GitFunc.gitCmd('force-push',1);
            delete(h)

            % retrieves the object handle
            hMenuC = resetMenuItems('Change Branch',mBr);
            feval(hMenuC.Callback{1},hMenuC,[],obj,1)
            
            % makes the main GUI visible again            
            pause(0.05)

            % prompts the user if they wish to delete the branch
            % from which the merge occured
            qStr = sprintf(['Do you want to delete the ',...
                            '"%s" branch?'],cBr);
            uChoice = questdlg(qStr,'Delete Branch?','Yes','No','Yes');
            if strcmp(uChoice,'Yes')
                % if so, then delete the branch
                hMenuD = resetMenuItems('Delete Branch',cBr);
                feval(hMenuD.Callback{1},hMenuD,[],obj,1)
            end            
            
        end
        
        % --- branch change callback function
        function changeBranch(hMenu,~,obj,varargin)
            
            % retrieves the previously selected branch item
            hMenuPr = findall(get(hMenu,'parent'),'checked','on');
            if (hMenu == hMenuPr) && isempty(varargin)
                return
            end                   
            
            % creates the loadbar
            if isempty(varargin)
                h = ProgressLoadbar('Changing Branch...'); 
            else
                h = ProgressLoadbar('Updating Branch...'); 
            end
            
            % updates the current branch string
            nwBr = get(hMenu,'label');
            isOK = obj.GitBranch.changeLocalBranch(nwBr,false,h);
            
            % determines if the branch change was successful
            if isOK 
                % if so, then update the branch label
                set(obj.hMain.textCurrBranch,'string',nwBr)
            else
                % otherwise, exit the function
                delete(h)
                return
            end
                        
            % unchecks the previous/checks the new menu item
            set(hMenuPr,'checked','off')
            set(hMenu,'checked','on')                            
            
            % updates the version history details
            obj.GitBranch.updateCommitHistoryInfo();    
            
            % deletes the loadbar
            delete(h)            
            
        end
        
        % --- branch deletion callback function
        function deleteBranch(hMenu,~,obj,varargin)
            
            % determines the current branch
            delBr = get(hMenu,'Label');
            if strcmp(obj.GitFunc.getCurrentBranch(),delBr)
                % if the current branch is the same as that being deleted,
                % then output an error to screen and exit the function
                eStr = sprintf(['Unable to delete because this is ',...
                                'the current branch.\nChange branch ',...
                                'before attempting to delete this branch.']);
                waitfor(errordlg(eStr,'Branch Deletion Error','modal'))
                return
            elseif isempty(varargin)
                % prompts the user if they want to delete the branch
                qStr = sprintf(['Are you sure you want to delete the ',...
                                'branch "%s"?'],delBr);
                uChoice = questdlg(qStr,'Confirm Branch Deletion',...
                                   'Yes','No','Yes');
                if ~strcmp(uChoice,'Yes')
                    % if the user cancelled, then exit the function
                    return
                end
            end
            
            % creates the loadbar
            if isempty(varargin)
                h = ProgressLoadbar('Deleting Branch...'); 
            else
                h = ProgressLoadbar('Deleting Merging Branch...'); 
            end
                             
            % retrieves the current branch name
            isStashed = obj.GitFunc.detIfBranchModified();
            cBr = obj.GitFunc.getCurrentBranch();  
            if isStashed; obj.GitFunc.gitCmd('stash'); end
            
            % sets the message for the deletion branch (combines the
            % deleted branch name with the last commit ID#)
            cID = strsplit(obj.GitFunc.gitCmd('branch-commits',delBr),'\n');
            cMsg = sprintf('Branch Delete ("%s" - %s)',delBr,cID{1});
            
            % adds an empty commit to the deleted branch and then returns
            % to the current branch
            obj.GitFunc.gitCmd('checkout-local',delBr);
            obj.GitFunc.gitCmd('commit-empty',cMsg);  
            
            % returns to the current branch
            obj.GitFunc.gitCmd('checkout-local',cBr);
            if isStashed; obj.GitFunc.gitCmd('stash-pop'); end
            
            % deletes the local/remote branches 
            obj.GitFunc.removeStashedFiles(delBr)                               
            obj.GitFunc.gitCmd('delete-remote',delBr)
            obj.GitFunc.gitCmd('delete-local',delBr)            
        
            % removes the branch from the history struct
            obj.GitBranch.removeStructHistory(delBr)       
            iType = obj.GitBranch.removeBranchString(delBr);                        
            
            % determines the number of items within each branch group type
            nMenu = cellfun(@length,obj.GitBranch.bStrGrp);
            
            % removes the menu items from the branch menus
            for i = 2:4
                % retrieves the object handle of the item to be deleted
                hMenuDel = findall(obj.hMenu{i},'label',delBr);
                if ~isempty(hMenuDel)
                    if strcmp(get(hMenuDel,'Separator'),'on') && ...
                                                    (nMenu(iType) > 0)
                        % if the deletion branch has a separator, and there 
                        % are still more elements within the group, then 
                        % add a separator to the next branch menu item
                        nxtBr = obj.GitBranch.bStrGrp{iType}{1};
                        hMenuNext = findall(obj.hMenu{i},'label',nxtBr);
                        set(hMenuNext,'Separator','on')
                    end

                    % deletes the menu item
                    delete(hMenuDel)
                    if sum(nMenu) == 1
                        % if there no branches (except the master branch) 
                        % then disable the parent menu item                    
                        set(obj.hMenu{i},'enable','off')                    
                    end                
                end                       
            end
            
            % closes the loadbar
            delete(h)
        end     
        
        % --- fetches the remote branches 
        function fetchRemote(hMenu,~,obj)
            
            % creates a loadbar
            h = ProgressLoadbar('Fetching Remote Repositories...');
            
            % performs the fetch operation
            obj.GitFunc.gitCmd('fetch-origin');
            
            % closes the loadbar
            delete(h)
            
        end
        
        % --- stashed branches callback function
        function stashedBranches(hMenu,~,obj)
            
            % retrieves the list of currently stashed branches
            sList = strsplit(obj.GitFunc.gitCmd('stash-list'),'\n');           
            if isempty(sList{1})
                % no branches are stashed
                stStr = {'No Stashed Branches'};
            else
                % otherwise, determines if there are any valid stashes
                isStash = cellfun(@(x)(strContains(x,'-stash')),sList);
                if ~any(isStash)
                    % no valid branches are stashed
                    stStr = {'No Stashed Branches'};                    
                else                
                    % otherwise, retrieve the stashed branch names
                    pat = ' (\w*)-stash';
                    stStr = cell2cell(cellfun(@(x)(regexp(x,pat,...
                                'tokens','once')),sList(isStash),'un',0));
                end
            end
            
            % runs the stashed branches GUI
            StashedBranches(stStr)
            
        end
        
        % --- reset branch callback function        
        function resetBranch(hMenu,~,obj)
            
            % confirms the user wants to reset to the detached point
            qStr = sprintf(['Are you certain you want to reset the ',...
                            'branch to the current point.\nNote ',...
                            'that this operation is can''t be reversed.']);
            uChoice = questdlg(qStr,'Reset Current Branch?',...
                               'Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % if the user did not confirm then exit the function
                return
            end
            
            % creates the loadbar
            h = ProgressLoadbar('Resetting Branch...');   
            
            % retrieves the struct branch string (removes any dashes
            cBr = obj.GitFunc.getCurrentBranch();
            hGV = findall(0,'tag','figGitVersion');
            hGVh = guidata(hGV);
            
            % clears the history data for the current branch
            gHistAll = getappdata(hGV,'gHistAll');
            eval(sprintf('gHistAll.%s = [];',strrep(cBr,'-','')));
            setappdata(hGV,'gHistAll',gHistAll)
            
            % retrieves the current/ID commit IDs 
            cID = obj.GitFunc.gitCmd('commit-id');
            obj.GitBranch.checkoutBranch('local',cBr)
            cID0 = obj.GitFunc.gitCmd('commit-id');            
            
            % add/removes the directories that are different between the
            % commits and then hard resets the branch
            obj.GitFunc.addRemoveDir(cID0,cID);
            obj.GitFunc.resetHistoryPoint(cID);
%             obj.GitFunc.gitCmd('hard-reset',cID);  
                                    
            % updates the version history details
            set(hGVh.radioAllVer,'value',1)
            obj.GitBranch.updateCommitHistoryInfo();            
            set(hMenu,'enable','off')
            
            % deletes the loadbar
            delete(h)                         
        end        
        
        % --- reference log callback function
        function reflogBranch(hMenu,~,obj)
            % runs the reference log GUI
            isChange = GitRefLog(obj);            
            if isChange
                % clears the git history struct (for all fields)
                obj.GitFunc.clearGitHistory()
                                
                % if there was a change, then update the version history  
                cBr = obj.GitFunc.getCurrentBranch();   
                hMenuC = resetMenuItems('Change Branch',cBr);
                feval(hMenuC.Callback{1},hMenuC,[],obj,1)                
            end
        end
        
        % --- branch information callback function
        function branchInfo(hMenu,~,obj)
            % runs the branch information GUI 
            GitBranchInfo(obj);                
        end
    end
end
