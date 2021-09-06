classdef GitFunc
    % Class properties
    properties(Hidden)
        gDirP
        rType
        gName
        useKey
        uType
        gRepo   
        
        % fixed fields
        tKey = 'bea6406bc8bcc5e24e68c9889f108faf4eeff3b9';
        tKeyU = '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';
    end
    
    % Class functions
    methods
        % --- class constructor
        function obj = GitFunc(rType,gDirP,gName)
            
            % sets the object token key and user type
            obj.uType = obj.getUserType();              
            if nargin == 0
                % if there are no input arguments, then exit
                return
            end
            
            % sets/changes the git respository directory
            [obj.gDirP,obj.rType,obj.gName] = deal(gDirP,rType,gName);
            cd(obj.gDirP)
            
            % sets the git repository type dependent on the input
            switch obj.rType
                case 'Main'
                    gRepo = 'DART';
                case 'AnalysisGen'
                    gRepo = 'DARTAnalysisGen';
                case 'Git'
                    gRepo = 'DARTGit';
            end
            
            % sets repository string
            obj.gRepo = sprintf('%s%s','@github.com/BFKLabs/',gRepo);                                                            
            
            % if user is a non-developer then remove non-master branches
            if obj.uType ~= 0                
                obj.rmvNonMasterBranches();
            end            
        end                                  
        
        % --- checks out a branch (either local, remote or version) 
        %     add/removes any directories that are not part of current
        function checkoutBranch(obj,chkType,chkData,chkID)
            
            % retrieves the commit ID of the new branch
            switch chkType
                case 'local' % case is checking out the local branch head 
                    % retrieves the commit ID of the local branch
                    nwID = obj.gitCmd('commit-id',chkData);

                case 'remote' % case is checking out a remote branch
%                     rmBr = sprintf('origin/%s',chkData);
%                     if obj.uType > 0
%                         obj.gitCmd('set-origin');
%                     end
% 
%                     % retrieves all branches and determines if the input 
%                     % branch is part of the remote branches
%                     obj.gitCmd('fetch-origin')

                    % retrieves the commit ID of the remote branch
                    nwID = chkID;              

                case 'version' % case is checking out branch version
                    % input data is the commit ID
                    nwID = chkData;

            end

            % adds/removes the directories between versions
            cID = obj.gitCmd('commit-id');
            obj.addRemoveDir(cID(1:length(nwID)),nwID)

            % checks out the branch/version based on the type
            switch chkType
                case 'local' 
                    % case is checking out the local branch head 
                    obj.gitCmd('checkout-local',chkData);

                case 'remote' 
                    % case is checking out a remote branch
                    obj.gitCmd('hard-reset',nwID,1);

                    % removes the origin url (non-developers only) 
                    if obj.uType > 0
                        obj.gitCmd('rmv-origin');
                    end                  

                case 'version' 
                    % case is checking out branch version
                    obj.gitCmd('checkout-version',chkData);

            end
        
        end        
        
        % --- deletes any local non-master branches 
        function rmvNonMasterBranches(obj)
            
            % retrieves the local branch names
            lclBr0 = strsplit(obj.gitCmd('branch-local'),'\n');
            lclBr0 = cellfun(@(x)(x(3:end)),lclBr0,'un',0);
            
            % determines all non-master/local working branches
            notOK = ~(strcmp(lclBr0,'master') | ...
                      startsWith(lclBr0,'LocalWorking') | ...
                      strContains(lclBr0,'HEAD detached at'));
            
            % sets the non-master local branch names (and deletes them)
            for i = find(notOK(:)')
                obj.gitCmd('delete-local',lclBr0{i});
            end
            
        end
        
        % --- resolves the stash list item pop for any conflicts
        function resolveStashPop(obj,iSel)
        
            % attempts to unstash the stashed changes
            stStatus = obj.gitCmd('stash-pop',iSel);
            if strContains(stStatus,'CONFLICT (content)')
                % if a conflict occurred then prompt the user the course of
                % action to take (accepts theirs, accept remote or manual)
                qStr = sprintf(['There is a merge conflict between your ',...
                                'local code version and the remote ',...
                                'version.\n\nDo you want to accept your ',...
                                'code version, accept the remote version, ',...
                                'or manually resolve the code conflicts?']);
                uChoice = questdlg(qStr,'Code Conflicts Detected',...
                                   'Accepts Yours','Accept Remote',...
                                   'Accepts Yours');

                % performs the action based on the user's choice
                umFiles = strsplit(obj.gitCmd('get-unmerged-files'),'\n');
                switch uChoice
                    case 'Accepts Yours' % case is to merge using local code
                        for i = 1:length(umFiles)
                            obj.gitCmd('checkout-ours',umFiles{i});
                            obj.gitCmd('add-file',umFiles{i});
                        end

                    case 'Accepts Remote' % case is to merge with remote code
                        for i = 1:length(umFiles)
                            obj.gitCmd('checkout-theirs',umFiles{i});
                            obj.gitCmd('add-file',umFiles{i});
                        end                    

                    case 'Manually Resolve' % case is to manually resolve
                        % FINISH ME!
                        a = 1;
                end

                % resets the branch and drops the stashed item
                obj.gitCmd('reset');
                obj.gitCmd('stash-drop',iSel);
                
            end
        end        
        
        % --- clones the program from the DART repository
        function cloneDART(obj,dartDir)
            % if the installation directory doesn't exist then create it
            cDir = pwd;
            if ~exist(dartDir,'dir'); mkdir(dartDir); end
            cd(dartDir)            
            
            % initialises the local repository and pulls from remote
            h = ProgressLoadbar('Cloning DART Repository...');
            obj.gitCmd('init');
            obj.gitCmd('pull');
            delete(h);
            
            % restores to the original directory
            cd(cDir)
        end                
        
        % --- determines the index of the stash list (if it exists)
        function iList = detStashListIndex(obj,sStr) 
            
            sList = strsplit(obj.gitCmd('stash-list'),'\n');
            iList = find(cellfun(@(x)(strContains(x,sStr)),sList));
            
        end        
        
        % --- retrieves the stash string for the current branch
        function sStr = getStashBranchString(obj,cBr)
            
            % retrieves the current branch and sets the stash string
            if ~exist('cBr','var'); cBr = obj.getCurrentBranch(); end
            sStr = sprintf('%s-stash',cBr);    
            
        end         

        % --- stashes any files for a specific branch
        function stashBranchFiles(obj,sStr)
            
            if obj.detIfBranchModified()
                % if there are any modified files, then unstash the
                % branch (if any files are stashed)
                if nargin == 1
                    sStr = obj.getStashBranchString();
                end                        

                % saves the new stash
                obj.unstashBranchFiles(sStr)                        
                obj.gitCmd('stash-save',sStr);
            end    
            
        end
        
        % --- unstashes any files for a specific branch        
        function unstashBranchFiles(obj,sStr)
            
            % retrieves the stash string for the current branch                       
            if nargin == 1
                sStr = obj.getStashBranchString();
            end
            
            % determines the index of the stash that belongs to
            % the current branch (if any)
            iList = obj.detStashListIndex(sStr);                                        
            if ~isempty(iList)
                % if a stash does exist, then pop this stash
                obj.gitCmd('stash-pop',iList-1)
            end  
            
        end        
        
        % --- removes any stashed files for a specific branch
        function removeStashedFiles(obj,sStr)

            % determines the index of the stash that belongs to
            % the current branch (if any)
            iList = obj.detStashListIndex(sStr);                                        
            if ~isempty(iList)
                % if a stash does exist, then pop this stash
                obj.gitCmd('stash-drop',iList-1)
            end  
                                              
        end        
        
        % --- determines if the branch has been modified (either deleted
        %     or modified files)
        function [isMod,fMod] = detIfBranchModified(obj)

            % determines if there are any modified/deleted files
            fMod = obj.gitCmd('branch-modifications');
            if isempty(fMod)
                % if there are no modifications, then return a false value
                isMod = false;
            else            
                % retrieves the files extenstions of the 
                fMod = strsplit(fMod,'\n');
                fExtn = cellfun(@(x)(getFileExtn(x)),fMod(:),'un',0);
                
                % determines the forced valid files
                vFiles = {'ProgPara.mat'};
                isV = cellfun(@(x)(strContains(fMod(:),x)),vFiles,'un',0);
                
                % determines if any of the altered files are valid (i.e.,
                % any non-asv or non.mat files, but can include files
                % from the valid file list)
                isOK = ~(strcmp(fExtn,'.asv') | ...
                         strcmp(fExtn,'.mat')) | ...
                         any(cell2cell(isV),2);
                [isMod,fMod] = deal(any(isOK),fMod(isOK));
            end    
        
        end       
        
        % --- retrieves the current commit ID
        function cID = getCurrentCommitID(obj)

            % retrieves the commit ID string
            logStr0 = strsplit(obj.gitCmd('n-log',1),'\n');
            commitLine = strsplit(logStr0{1});
            cID = commitLine{2};

        end
        
        % --- sorts the branch types in descending order of importance
        function bStr = sortBranches(obj,bStr0)
            
            % sets the search strings (based on user-type)
            switch obj.uType
                case 0
                    sStr = {'master','develop-','feature-',...
                            'hotfix-','other-'};
                case 1
                    sStr = {'master','LocalWorking'};
            end
            
            %
            iGrp = cell(length(sStr),1);
            for i = 1:length(sStr)
                iGrp{i} = find(cellfun(@(x)(startsWith(x,sStr{i})),bStr0'));
            end
            
            %
            bStr = bStr0(cell2mat(iGrp(:)));
            
        end
        
        % --- retrieves the current branch (if the branch is detached then
        %     determine the branch which it is detached from)
        function [cBr,isDetached] = getCurrentBranch(obj)

            % retrieves the current branch
            cBr = obj.gitCmd('current-branch');
            if isempty(cBr)
                % if the current branch is a detached branch, then
                % determine the branch from which it detached from
                isDetached = 1;
                hBr0 = strsplit(obj.gitCmd('head-branch'),'\n');  
                hBr0Sp = strsplit(hBr0{1});
                
                brID = hBr0Sp{end}(1:end-1);
                bStr0 = strsplit(obj.gitCmd('branch-contains',brID),'\n');                 
                bStr = obj.sortBranches(...
                            cellfun(@(x)(x(3:end)),bStr0(2:end),'un',0));  
                
                %
                if length(bStr) == 1
                    cBr = bStr{1};
                    
                else
                    % retrieves the current commit ID                    
                    [cID,nL] = deal(obj.gitCmd('commit-id'),25); 
                    
                    % determines which reflog strings have 
                    while 1
                        rlStr = strsplit(obj.gitCmd(...
                                    'n-reflog-branch',nL,'HEAD'),'\n');
                        hasID = cellfun(@(x)(strContains(x,cID) ...
                                    && strContains(x,'checkout')),rlStr);
                                
                        if ~any(hasID)
                            nL = 2*nL;
                        else
                            break
                        end
                    end
                    
                    %
                    rlStrF = rlStr(hasID);
                    for i = 1:length(rlStrF)
                        %
                        isMatch = cellfun(@(x)(strContains(rlStrF{i},...
                                    sprintf('moving from %s',x))),bStr);
                        if any(isMatch)
                            cBr = bStr{isMatch};
                            return
                        end
                    end         
                end                               
            else
                % flag that the branch is not detached
                isDetached = false;
            end
        end        
                        
        % --- add/removes the directories between versions from the 
        %     matlab path
        function addRemoveDir(obj,cID,nwID)
        
            % determines the difference between the 2 versions
            if startsWith(cID,nwID)
                % if the version ID's are the same then exit the function
                return
            else
                % otherwise, determine the difference between versions
                dBr0 = obj.gitCmd('diff-status',cID,nwID);
                if isempty(dBr0)
                    % if there is no difference then exit the function
                    return
                else
                    % otherwise, split the difference string by line
                    dBr = strsplit(dBr0,'\n');
                end
            end

            % determines the status flag for each file
            dBrSp = cellfun(@(x)(strsplit(x,'\t')),dBr(:),'un',0);
            fStatus = cellfun(@(x)(x{1}),dBrSp,'un',0);
            fDir = cellfun(@(x)(fileparts(x{2})),dBrSp,'un',0);

            % determines if there are any files that will be removed
            isRmv = strcmp(fStatus,'D');
            if any(isRmv)
                % determines the unique removal directories
                rmvDir = obj.getDiffFileNames(fDir(isRmv));
                [rmvDirU,~,iC] = unique(rmvDir);

                % sorts the directories by descreasing depth
                iNw = argSort(cellfun(@(x)...
                                    (length(strsplit(x,'/'))),rmvDirU),1);
                rmvDirU = rmvDirU(iNw);

                % determines if, for any directory from which files are 
                % being removed, if all files are to be removed. if so, 
                % then remove the directory from the path
                for i = 1:length(rmvDirU)
                    % if all files in the directory have been removed, and 
                    % is on the matlab path, then remove from the path
                    if (length(dir(rmvDirU{i}))-2) == sum(iC==iNw(i))
                        if strContains(path,rmvDirU{i})
                            rmpath(rmvDirU{i})
                        end
                    end
                end
            end

            % determines if there are any files that will be added
            isAdd = strcmp(fStatus,'A');
            if any(isAdd)
                % retrieves the names/directories of the files to be added
                addDir = obj.getDiffFileNames(fDir(isAdd));           

                % determines if the new directories are on the matlab path
                fullPath = path;
                for i = 1:length(addDir)
                    % if not, then create a new directory and add to path
                    if ~strContains(fullPath,addDir{i})
                        % creates/add the new directory to the path
                        mkdir(addDir{i});
                        addpath(addDir{i});

                        % appends the new directory to the full path
                        fullPath = sprintf('%s\n%s',fullPath,addDir{i});
                    end
                end
            end        
        
        end
        
        % --- retrieves the file names/directories of the difference files
        %     searches for the files given by chkStr ('gone' or 'new')
        function fDir = getDiffFileNames(obj,fDir0)
            
            % retrieves the full path of the files to be removed
            if ispc
                % if using PC, then replaces the directory separator
                fDir0 = cellfun(@(x)(strrep(x,'/','\')),fDir0,'un',0);
            end                        

            % retrieves the full names/directories of files to be removed
            fDir = cellfun(@(x)(fullfile(obj.gDirP,x)),fDir0,'un',0);
            
        end              
        
        % --- retrieves the files that are different/conflicted after 
        %     a merge has been attempted
        function dcFiles = getMergeDCFiles(obj)
            
            % retrieves the current directory
            cDir = pwd;            
            
            % retrieves the branch status
            cd(obj.gDirP)
            brStatus = strsplit(obj.gitCmd('branch-status',1),'\n');
            cd(cDir)
            
            % determines which files are conflicted/merged
            isDC = cellfun(@(x)(startsWith(strtrim(x),'AA') || ...
                                startsWith(strtrim(x),'UU') || ...
                                startsWith(strtrim(x),'M')),brStatus);
            dcFiles = struct('Conflict',[],'Diff',[]);
                            
            for i = find(isDC(:)')
                % sets the file type/status
                brType = brStatus{i}(1:2);
                brStatusNw = strrep(brStatus{i}(4:end),'"','');
                
                nwStr = struct('Path',[],'Name',[]);
                [nwStr.Path,fName,fExtn] = fileparts(brStatusNw); 
                nwStr.Name = sprintf('%s%s',fName,fExtn);
                
                % 
                if strcmp(brType,'AA') || strcmp(brType,'UU')
                    dcFiles.Conflict = [dcFiles.Conflict;nwStr];
                else
                    dcFiles.Diff = [dcFiles.Diff;nwStr];
                end
            end
        end
        
        % --- resets the local branch so that 
        function ok = matchRemoteBranch(obj,cBr)

            % sets the remote branch
            cBrR = sprintf('origin/%s',cBr);
            obj.gitCmd('fetch-origin',cBrR);

            % keep attempting to reset the local branch (creates new
            % directories manually if permission is denied)
            while 1
                rMsg = obj.gitCmd('hard-reset',cBrR);
                if strContains(rMsg,'fatal: cannot create directory')
                    % sets the full path of the missing directory
                    dStr = regexp(rMsg,'''[^()]*''','match');
                    nwDir = fullfile(obj.gDirP,dStr{1}(2:end-1));

                    % attempts to create the directory
                    cStatus = mkdir(nwDir);
                    if cStatus == 0
                        % if there was an error then exit
                        ok = false;
                        break
                    end
                else
                    % otherwise, exit the loop
                    ok = true;
                    break
                end
            end

        end        
        
        % --- clears the clear git history struct field for a given branch
        function clearGitHistory(obj,fStr)
            % retrieves the git version GUI object handle/history struct
            hGV = findall(0,'tag','figGitVersion');
            gHistAll = getappdata(hGV,'gHistAll');
            
            if nargin == 1
                % if not provided, update all struct fields
                fStr = fieldnames(gHistAll);
            elseif ~iscell(fStr)
                % otherwise, ensure the field is stored in a cell array
                fStr = {fStr};
            end
           
            % resets the git history data struct for all fields            
            for i = 1:length(fStr)
                eval(sprintf('gHistAll.%s = [];',fStr{i}));
            end
            
            % updates the git history struct
            setappdata(hGV,'gHistAll',gHistAll)
        end
        
        % --- resets the local/remote history (for the current branch to a
        %     certain commit ID (cID)
        function resetHistoryPoint(obj,cID)
            
            % resets the commit to the specified commit point
            obj.gitCmd('hard-reset',cID);     
            obj.gitCmd('force-push',1);
                        
        end
        
        % --- resets the local/remote history (for the current branch to a
        %     certain commit ID (cID)
        function resetLogPoint(obj,cID)
            
            % resets the commit to the specified commit point
            obj.gitCmd('hard-reset',cID);     
            obj.gitCmd('force-push',1);
                        
        end        
        
        % --- sets the origin user/password url
        function setOriginPW(obj)
            
            obj.gitCmd('rmv-helper');  
            obj.gitCmd('set-origin-pw');            
            
        end
        
        % --- determines if there is a local change in the code
        function isDiff = detIfCodeChange(obj)
            
            [~,isDiff] = obj.gitCmd('branch-has-diff');
            
        end
        
        % --- calculates the number commits from a local working branch
        function nCommit = getLocalBranchCommitCount(obj,lBr)
            
            %
            cStr = obj.gitCmd('all-branch-commits','master',lBr);
            if isempty(cStr)
                nCommit = 0;
            else
                nCommit = length(strsplit(cStr,'\n'));
            end
            
        end
        
        % --- prompts the user what action they want to do take given
        %     there is a change in the current branch
        function uChoice = promptUserChange(obj)
            
            % sets the title/button strings
            tStr = 'Code Changes Detected';
            bStr = {'Commit','Stash','Ignore','View','Cancel'};
            
            if obj.uType > 0
                % user is not a developer (not able to make commits/stash)
                [i0,sStr] = deal(3,'Ignore');  
                
            else
                % case is a developer, so determines if branch is detached
                [~,isDetached] = obj.getCurrentBranch; 
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
        
        % --- sets up the commit information array
        function cInfo = getAllCommitInfo(obj,pName,gpat)
            
            % initialisations
            pat = '(?<=<).+?(?=>)';

            % determines all the commit/merge commits
            AC0 = obj.gitCmd('reflog-grep',pName,'commit:',gpat);
            AM0 = obj.gitCmd('reflog-grep',pName,'commit (merge)',gpat);
            AR0 = obj.gitCmd('reflog-grep',pName,'rebase',gpat);
            
            %
            if isempty(AM0)
                cInfo = [];
                return
            else
                AM = strsplit(AM0,'\n')';
                cInfoM0 = cellfun(@(x)(regexp(x,pat,'match')),AM,'un',0);
                cInfoM = cell2cell(cInfoM0);
            end
            
            % sets the final commit information
            AC = strsplit(AC0,'\n')';            
            cInfoC = cellfun(@(x)(regexp(x,pat,'match')),AC,'un',0);
            cInfoT = [cell2cell(cInfoC);cInfoM];
            
            % removes any commits that are branch deletions
            isOK = ~startsWith(cInfoT(:,end),'Branch Delete');
            cInfo = cInfoT(isOK,:);            
                
        end
        
        % --- retrieves the branch information
        function brInfo = getBranchInfo(obj,isAll)
            
            % sets the default input arguments
            if ~exist('isAll','var'); isAll = false; end
            
            % retrieves the branch info
            if isAll
                % case is for all branches
                brInfo0 = obj.gitCmd('branch-info',1);
            else
                % case is for local branches only
                brInfo0 = obj.gitCmd('branch-info');
            end
            
            % retrieves the non-detached branches
            X = strsplit(brInfo0,'\n')';
            X = X(~strContains(X,'HEAD detached'));
            
            %
            brInfo = cell2cell(cellfun(@(x)(strsplit(x(3:end))),X,'un',0));
        end
        
        % --- retrieves the information from the created branch
        function crBr = getCreatedBranchInfo(obj)
            
            % initialisations
            cStr = 'commit: 1st Commit (Branched from';
            
            % retrieves the branch deletion objects
            crBrInfo0 = obj.gitCmd('reflog-grep','HEAD',cStr);   
            if isempty(crBrInfo0)
                crBr = [];
                return
            else
                % otherwise, split the string into components
                crBrInfo = strsplit(crBrInfo0,'\n')';                
            end
            
            % retrieves the deleted commit ID information 
            crBr = cell(length(crBrInfo),1);            
            for i = 1:length(crBrInfo)
                % splits the deletion branch information
                crBrSp = regexp(crBrInfo{i},'\w+','match');
                crBr{i,1} = crBrSp{1};
            end
            
        end
        
        % --- retrieves the information about all deleted branches
        function delBr = getDeletedBranchInfo(obj)
            
            % initialisations
            cStr = 'commit: Branch Delete';
            
            % retrieves the branch deletion objects
            delBrInfo0 = obj.gitCmd('reflog-grep','HEAD',cStr);            
            if isempty(delBrInfo0)
                delBr = [];
                return
            else
                % otherwise, split the string into components
                delBrInfo = strsplit(delBrInfo0,'\n');
            end
            
            % retrieves the deleted commit ID information 
            delBr = cell(length(delBrInfo),2);            
            for i = 1:length(delBrInfo)
                % splits the deletion branch information
                iiR = regexp(delBrInfo{i},'\w+');                
                xiCID0 = 1:(iiR(2)-2);
                xiCID = iiR(end):(length(delBrInfo{i})-1);
                
                % sets the commit/deleted commit ID and message
                delBr{i,1} = delBrInfo{i}(xiCID0);
                delBr{i,2} = delBrInfo{i}(xiCID);             
            end
        end
        
        % --- resets the commit message from txt0 to txtNw
        function resetCommitMessage(obj,txt0,txtNw,cBr,iCm)
            
            % sets the callback message strings
            cbMsgStr = sprintf(['return message.replace(b''%s'','...
                             'b''%s'')'],txt0,txtNw);
            refStr = sprintf('--refs %s~%i..%s',cBr,iCm+1,cBr);
            
            % resets the commit message
            obj.gitCmd('reset-commit-msg',cbMsgStr,refStr);
            
        end
        
        % --- runs the git command (based on the type given by cStr)
        function varargout = gitCmd(obj,cStr,varargin)
            
            % initialisation
            resetURL = false;
            
            switch cStr
                case 'general'
                    % command string is set outside of function
                    gitCmdStr = varargin{1};
                
                case {'init','branch','diff','fetch',...
                             'commit','stash','reset'} 
                    % command string is same as name as type string
                    gitCmdStr = cStr;
               
                case 'reset-commit-msg'
                    % case is resetting a commit message
                    [cbMsgStr,refStr] = deal(varargin{1},varargin{2});
                    gitCmdStr = sprintf(['filter-repo ',...
                            '--message-callback "%s" %s'],cbMsgStr,refStr);
                    
                case 'diff-no-index'
                    % case is determining the difference between two files
                    % that aren't necessarily within the repo index
                    [file1,file2] = deal(varargin{1},varargin{2});
                    gitCmdStr = sprintf(['diff --no-index -b -w ',...
                            '--ignore-blank-lines "%s" "%s"'],file1,file2);
                   
                case 'ignore-local-changes'
                    % ignores the local changes on a branch
                    gitCmdStr = 'checkout .';
                        
                case 'force-push'
                    % forces pushes a commit 
                    remotePush = ~isempty(varargin);
                    if remotePush
                        cBr = obj.getCurrentBranch();
                        gitCmdStr = sprintf('push --force origin %s',cBr);
                    else
                        gitCmdStr = 'push --force';
                    end
                    
                case 'push-set-upstream'
                    % pushes a commit while setting the upstream branch
                    bStr = varargin{1};
                    gitCmdStr = sprintf('push --set-upstream origin %s',bStr);
                    
                case 'force-push-commit'
                    % force pushes a specific commit
                    if length(varargin) == 1
                        cID = varargin{1};
                        cBr = obj.getCurrentBranch();
                        gitCmdStr = ...
                            sprintf('push --force origin %s:%s',cID,cBr);
                    else
                        bStr = varargin{1};
                        gitCmdStr = ...
                            sprintf('push --force origin %s:%s',bStr,bStr);                        
                    end
                    
                case 'upstream-push'
                    % creates an upstream push
                    nwBr = varargin{1};
                    if length(varargin) == 2
                        upBr = varargin{2};
                        gitCmdStr = sprintf('push -u %s %s',upBr,nwBr);
                    else
                        gitCmdStr = sprintf('push -u origin %s',nwBr);
                    end                   
                    
                case 'rmv-helper'
                    % removes the credential helper
                    gitCmdStr = 'config --system --unset credential.helper';                    
                    
                case 'branch-modifications'
                    % retrieves the modified files
                    rootDir = obj.gitCmd('get-root-dir');
                    gitCmdStr = sprintf('ls-files -m -d "%s"',rootDir);
                    
                case 'get-root-dir'
                    % retrieves the git root directory
                    gitCmdStr = 'rev-parse --show-toplevel';
                    
                case 'switch-branch'
                    %
                    brStr = varargin{1};
                    if length(varargin) == 1
                        gitCmdStr = sprintf('switch %s',brStr);
                    else
                        gitCmdStr = sprintf('switch -c %s',brStr);
                    end
                    
                case 'branch-log-remote'
                    % sets the origin url (non-developer only)
                    if obj.uType > 0
                        if isempty(obj.gitCmd('get-origin'))
                            resetURL = true; 
                            obj.gitCmd('set-origin')
                        end
                    end
                    
                    % retrieves the current/parent branch
                    cmpStr = sprintf('origin/%s',varargin{1});                    
                    
                    % sets up the git string
                    [sDate,fDate] = deal(varargin{2},varargin{3});
                    gitCmdStr = sprintf(['log %s --date=local ',...
                                         '--after="%s" --before="%s"'],...
                                         cmpStr,sDate,fDate);
                                     
                    % adds in the history count length (if provided)
                    if length(varargin) == 4
                        nHist = varargin{4};
                        gitCmdStr = sprintf('%s -n %i',gitCmdStr,nHist);
                    end                    
                    
                    
                case 'branch-log'
                    % retrieves the log details for the current branch 
                    
                    % retrieves the current/parent branch
                    pBr = varargin{1};
                    cBr = obj.getCurrentBranch();
                    
                    % sets the branch/parent comparison string
                    if isempty(pBr)
                        % case is the master (so no comparison)
                        cmpStr = 'master';
                    else
                        % otherwise set the branch/parent comparison string
                        cmpStr = sprintf('%s..%s',pBr,cBr);
                    end
                    
                    % sets up the git string
                    [sDate,fDate] = deal(varargin{2},varargin{3});
                    gitCmdStr = sprintf(['log %s --date=local ',...
                                         '--after="%s" --before="%s"'],...
                                         cmpStr,sDate,fDate);
                                     
                    % adds in the history count length (if provided)
                    if length(varargin) == 4
                        nHist = varargin{4};
                        gitCmdStr = sprintf('%s -n %i',gitCmdStr,nHist);
                    end
                    
                case 'branch-status'
                    if isempty(varargin)
                        gitCmdStr = 'status';
                    else
                        gitCmdStr = 'status -s';
                    end
                    
                case 'n-log'                 
                    % retrieves the log of the last nHist commits
                    nHist = varargin{1};
                    gitCmdStr = sprintf('log -n %i',nHist);
                   
                case 'n-reflog-branch'
                    % retrieves the last n-log events for a given branch
                    [nHist,brName] = deal(varargin{1},varargin{2});
                    gitCmdStr = sprintf(['reflog -n %i --pretty=oneline ',...
                                         '%s'],nHist,brName);
                    
                case 'show-reflog'
                    % shows the reference log for a particular branch
                    shBr = varargin{1};
                    gitCmdStr = sprintf('reflog show --no-abbrev %s',shBr);
                    
                case 'reflog-branch'
                    %
                    bStr = varargin{1};
                    switch length(varargin)
                        case 1
                            % case is all histories
                            gitCmdStr = sprintf('reflog %s',bStr);
                        case 2
                            % case is the n-history
                            nRL = varargin{2};
                            gitCmdStr = sprintf('reflog %s -n %i',bStr,nRL);
                        case 3
                            % case is using the date filter
                            [D0,D1] = deal(varargin{2},varargin{3});
                            gitCmdStr = sprintf('reflog %s@{%s} %s@{%s}',...
                                                bStr,D0,bStr,D1);
                    end
                    
                case 'raw-log'
                    %
                    [cID,nL] = deal(varargin{1},varargin{2});
                    gitCmdStr = sprintf(...
                            'log -t --pretty=raw -n %i %s',nL,cID);
                    
                case 'log-grep'
                    % phrase searches a specific branch
                    [gStr,cBr] = deal(varargin{1},varargin{2});
                    gitCmdStr = sprintf('log --grep="%s" %s',gStr,cBr);
                        
                case 'log-grep-all'
                    % phrase searches all branches
                    gStr = varargin{1};
                    gitCmdStr = sprintf('log -g --grep="%s" --oneline',gStr);                    
                    
                case 'head-branch'
                    % sets the git command string
                    gitCmdStr = 'branch --all --contains HEAD';
                    
                case 'branch-contains'
                    % determines the branches containing the commit ID
                    cID = varargin{1};
                    gitCmdStr = sprintf('branch --contains %s',cID);
                    
                case 'head-describe'
                    % sets the git command string
                    gitCmdStr = 'describe --contains --all HEAD';

                case 'branch-local'
                    % retrieves all the remote branch names
                    gitCmdStr = 'branch';                    
                    
                case 'branch-remote'
                    % retrieves all the remote branch names
                    gitCmdStr = 'branch -r';
                    
                case 'get-commit-msg'
                    % retrieves the message for a given commit
                    cID = varargin{1};
                    if length(varargin) == 1
                        gitCmdStr = sprintf(...
                                    'show -s --format=%sB %s','%',cID);
                    else
                        gitCmdStr = sprintf('log --format=%sB %s','%',cID);                        
                    end
                    
                case 'branch-commits'
                    % retrieves the commit IDs for a given branch
                    cBr = varargin{1};
                    gitCmdStr = sprintf('rev-list %s',cBr);
                    
                    if length(varargin) == 2
                        gitCmdStr = sprintf('%s --abbrev-commit',gitCmdStr);
                    end
                    
                case 'revlist-grep'
                    %
                    [cID,gStr] = deal(varargin{1},varargin{2});
                    gitCmdStr = sprintf(['rev-list %s ',...
                                '--grep="%s" --oneline'],cID,gStr);                    
                    
                case 'reflog-grep'
                    %
                    [cBr,gStr] = deal(varargin{1},varargin{2});
                    gitCmdStr = sprintf(['reflog %s ',...
                                '--grep-reflog="%s" --oneline'],cBr,gStr);
                            
                    if length(varargin) == 3
                        fStr = varargin{3};
                        gitCmdStr = sprintf...
                                    ('%s --format="%s"',gitCmdStr,fStr);
                    end
                    
                case 'reflog-grep-since'
                    % case is search the ref-log for a certain string
                    % (starting from a time)
                    [gStr,sDate] = deal(varargin{1},varargin{2});
                    gitCmdStr = sprintf(['reflog --since="%s" ',...
                            '--grep-reflog="%s" --oneline'],sDate,gStr);                            
                            
                case 'get-commit-parent'
                    % retrieves the commit IDs for a given branch
                    cBr = varargin{1};
                    gitCmdStr = sprintf('rev-list --parents -n 1 %s',cBr);                    
                    
                case 'get-branch-commits'
                    % retrieves the commit string for the current branch
                    cBr = varargin{1};
                    gitCmdStr = sprintf('log --walk-reflogs %s',cBr);
                    
                case 'all-branch-commits'
                    % retrieves the commit/ID from the branch head
                    cBr = varargin{1};
                    if length(varargin) == 2
                        lBr = varargin{2};
                        gitCmdStr = sprintf('cherry -v %s %s',cBr,lBr);
                    else
                        gitCmdStr = sprintf('cherry -v %s',cBr);
                    end
                    
                case 'compare-commit'
                    % sets the input arguments
                    [cID1,cID2] = deal(varargin{1},varargin{2});
                    gitCmdStr = sprintf...
                                ('cherry %s %s --abbrev=7',cID1,cID2);
                    
                case 'get-commit-date'
                    % retrieves the date stamp for a given commit
                    cID = varargin{1};
                    gitCmdStr = sprintf...
                                ('show -s --format=%s %s','%ai',cID);
                    
                case 'get-commit-comment'
                    % retrieves the date stamp for a given commit
                    cID = varargin{1};
                    gitCmdStr = sprintf('log --format=%s -n 1 %s','%B',cID);
                    
                case 'get-merge-base'
                    % retrieves the common commit between 2 branches
                    [cBr1,cBr2] = deal(varargin{1},varargin{2});
                    gitCmdStr = sprintf('merge-base %s %s',cBr1,cBr2);
                    
                case 'rebase-onto'
                    % rebases commit cID1 onto commit cID2
                    [cID1,cID2] = deal(varargin{1},varargin{2});
                    gitCmdStr = sprintf('rebase --onto %s %s',cID1,cID2);
                    
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%    STASH FUNCTIONS    %%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                                                                     
                                                           
                case 'stash-list'
                    % retrieves the list of stashed files
                    gitCmdStr = 'stash list';
                    
                case 'stash-pop'
                    % pops the stashed branch given by the index, iPop
                    if isempty(varargin)
                        gitCmdStr = 'stash pop';                         
                    else
                        iPop = varargin{1};
                        gitCmdStr = sprintf('stash pop stash@{%i}',iPop); 
                    end
                    
                case 'stash-apply'
                    % pops the stashed branch given by the index, iPop
                    if isempty(varargin)
                        gitCmdStr = 'stash apply';                         
                    else
                        iPop = varargin{1};
                        gitCmdStr = sprintf('stash apply stash@{%i}',iPop); 
                    end                    
                    
                case 'stash-drop'
                    % drops the stashed branch given by the index, iPop
                    if isempty(varargin)
                        gitCmdStr = 'stash pop';
                    else
                        iPop = varargin{1};
                        gitCmdStr = sprintf('stash drop stash@{%i}',iPop);  
                    end
                    
                case 'stash-save'
                    % case is save a stash with specific message
                    if isempty(varargin)
                        gitCmdStr = sprintf('stash save'); 
                    else
                        sMsg = varargin{1};
                        gitCmdStr = sprintf('stash save "%s"',sMsg);    
                    end
                    
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%    GIT BRANCH FUNCTIONS    %%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                         
                    
                case 'all-branches'
                    % retrieves all the repository branches
                    gitCmdStr = 'branch -a';                                                            
                    
                case 'current-branch'
                    % retrieves all the repository branches
                    gitCmdStr = 'branch --show-current';                    
                                        
                case 'show-branches'
                    % retrieves all the repository branches
                    gitCmdStr = 'show-branch';    
                    
                case 'branch-info'
                    % case is retrieving the information local branches 
                    gitCmdStr = ['branch -v --format="%(HEAD) ',...
                                 '%(refname:short) %(objectname:short)"'];
                    if length(varargin) == 1
                        % case is for all branches
                        gitCmdStr = sprintf('%s --all',gitCmdStr);
                    end

                case 'diff-commit-stats'
                    % case is the commit difference statistics
                    [cID1,cID2] = deal(varargin{1},varargin{2});
                    gitCmdStr = sprintf('diff --shortstat %s %s',cID1,cID2);
                    
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%    FILE CHECKOUT FUNCTIONS    %%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
                
                case 'checkout-ours'
                    % checks out file from "our" branch
                    fName = varargin{1};
                    gitCmdStr = sprintf('checkout --ours "%s"',fName);                 
                    
                case 'checkout-theirs'
                    % checks out file from "their" branch
                    fName = varargin{1};
                    gitCmdStr = sprintf('checkout --theirs "%s"',fName);                    
                    
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%    ORIGIN URL FUNCTIONS    %%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                     
                    
                case 'set-origin'
                    % sets the origin url
                    gitCmdStr = sprintf('remote add -f origin https://%s%s',...
                                         obj.tKey,obj.gRepo);   
                                                     
                case 'set-origin-user'
                    % sets the origin url
                    gitCmdStr = sprintf('remote add -f origin https://%s%s',...
                                         obj.tKeyU,obj.gRepo); 
                                     
                    
                case 'set-origin-pw'
                    % sets the origin url (setting password)
                    uName = 'DARTUser';
                    pWord = 'bfk_dart_user0';
                    gitCmdStr = sprintf(['remote add -f origin ',...
                        'https://%s:%s%s'],uName,pWord,obj.gRepo);                    
                                     
                case 'rmv-origin'
                    % removes the origin url                     
                    gitCmdStr = 'remote remove origin';
                    
                case 'get-origin'
                    % retrieves the origin URL
                    gitCmdStr = 'config --get remote.origin.url';                    
                    
                case 'fetch-origin'
                    % fetches all branches from the origin
                    if isempty(varargin)
                        gitCmdStr = 'fetch origin'; 
                        
                    else
                        cID = varargin{1};
                        gitCmdStr = sprintf('fetch origin %s',cID);
                    end                                                        
                    
                case 'fetch-origin-prune'
                    % fetches all branches from the origin
                    gitCmdStr = 'fetch --prune origin';                     
                    
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%    REPOSITORY COMMIT FUNCTIONS    %%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                                            
                    
                case 'commit-empty'
                    % case is a simplt commit
                    cmStr = varargin{1};
                    gitCmdStr = sprintf('commit --allow-empty -m "%s"',cmStr);                
                
                case 'commit-simple'
                    % case is a simplt commit
                    cmStr = varargin{1};
                    gitCmdStr = sprintf('commit -m "%s"',cmStr);
                    
                case 'commit-all'
                    % case is a simple commit
                    cmStr = varargin{1};
                    gitCmdStr = sprintf('commit -a -m "%s"',cmStr);                    
                    
                case 'commit-id'
                    if isempty(varargin)
                        % retrieves the commit ID for the current branch 
                        gitCmdStr = 'rev-parse HEAD';
                    else
                        % retrieves the commit ID for a specific branch
                        chkBr = varargin{1};
                        gitCmdStr = sprintf('rev-parse %s',chkBr);
                    end

                case 'diff-file'
                    % determines the file difference between 2 commits
                    cID1 = varargin{1};
                    
                    if length(varargin) == 2
                        fFile = varargin{2};
                        gitCmdStr = sprintf('diff %s -- "%s"',...
                                                        cID1,fFile);                        
                    else
                        [cID2,fFile] = deal(varargin{2},varargin{3});
                        gitCmdStr = sprintf('diff %s..%s -- "%s"',...
                                                        cID1,cID2,fFile);
                    end
                    
                case 'status-short'
                    %
                    gitCmdStr = sprintf('status --short');
                    
                case 'diff-commit'
                    % determines the difference status between 2 commits
                    cID1 = varargin{1};
                    gitCmdStr = sprintf('diff --name-status %s %s',cID1);                    
                    
                case 'diff-status'
                    % determines the difference status between commits
                    cID1 = varargin{1};
                    if length(varargin) == 1
                        % case is checking current commit status
                        gitCmdStr = sprintf('diff --name-status %s',cID1);                        
                    else
                        % case is comparing 2 commits
                        cID2 = varargin{2};
                        gitCmdStr = sprintf(...
                                    'diff --name-status %s %s',cID1,cID2);
                    end
                    
                case 'commit-diff'
                    % retrieves the difference between 2 commits
                    [cID1,cID2] = deal(varargin{1},varargin{2});
                    if length(varargin) == 2
                        % commit difference is full form
                        gitCmdStr = sprintf('diff -m %s %s',cID1,cID2);
                    else
                        % commit difference is summary form
                        gitCmdStr = sprintf('diff -m %s %s %s',...
                                            '--compact-summary',cID1,cID2);
                    end
                    
                case 'commit-diff-current'
                    % retrieves the difference between the current code
                    % state and a given commit 
                    cID = varargin{1};
                    if length(varargin) == 1
                        gitCmdStr = sprintf('diff -R %s',cID); 
                    else
                        gitCmdStr = sprintf('diff %s',cID); 
                    end
                   
                case 'add-file'
                    % adds a file to the repository
                    fName = varargin{1};
                    gitCmdStr = sprintf('add "%s"',fName);
                    
                case 'remove-file'
                    % removes a file from the repository
                    fName = varargin{1};
                    gitCmdStr = sprintf('rm "%s"',fName);
                    
                case 'reset-file'
                    % resets a file from the repository
                    fName = varargin{1};
                    gitCmdStr = sprintf('reset "%s"',fName);                    
                    
                case 'cached-diff'
                    % resets a file from the repository
                    fName = varargin{1};
                    gitCmdStr = sprintf('diff --cached "%s"',fName);                                        
                    
                case 'branch-has-diff'
                    % determines if there is a difference on the branch
                    gitCmdStr = 'diff --exit-code';
                    
                case 'apply-patch'
                    % applies the patch file, pFile
                    pFile = varargin{1};
                    if length(varargin{1}) == 1
                        gitCmdStr = sprintf('apply "%s"',pFile);
                    else
                        gitCmdStr = sprintf('apply -R "%s"',pFile);
                    end
                    
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%    REMOTE BRANCH FUNCTIONS    %%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                                                                      
                    
                case {'checkout-remote'}
                    % checks out a remote branch
                    brName = varargin{1};                    
                    if length(varargin) == 1
                        gitCmdStr = sprintf('checkout -t origin/%s',brName); 
                    else
                        gitCmdStr = sprintf('checkout origin/%s',brName); 
                    end                   
                    
                case {'delete-remote'}
                    % deletes a remote branch
                    brName = varargin{1};
                    gitCmdStr = sprintf('push origin --delete %s',brName);                                        
                    
                case {'push-remote-init'}
                    % creates a remote branch                                        
                    [pBr,nwBr] = deal(varargin{1},varargin{2});
                    gitCmdStr = sprintf('push origin %s:%s',pBr,nwBr);                                        
                    
                case 'fetch-remote'
                    % fetches the files from the remote repository
                    cBr = varargin{1};
                    gitCmdStr = sprintf('fetch origin/%s %s',cBr,cBr);
                    
                case 'checkout-remote-file'
                    % checks out a file from the remote branch
                    [cBr,fName] = deal(varargin{1},varargin{2});
                    gitCmdStr = sprintf('checkout origin/%s -- "%s"',...
                                        cBr,fName);
                    
                case 'force-checkout'
                    % case is force switching a branch (ignores changes)
                    nwBr = varargin{1};
                    gitCmdStr = sprintf('checkout -f %s',nwBr);                                    
                                    
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%    LOCAL BRANCH FUNCTIONS    %%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                    
                    
                case 'create-local'
                    % creates a local branch from a remote branch
                    nwBr = varargin{1};
                    gitCmdStr = sprintf('checkout -b %s origin/%s',nwBr,nwBr);                                                            

                case 'create-local-detached'
                    % creates a local branch from a detached head
                    [nwBr,cID0] = deal(varargin{1},varargin{2});
                    gitCmdStr = sprintf('checkout -b %s %s',nwBr,cID0);                                                                                
                    
                case 'checkout-local'
                    % checks out a local branch 
                    brName = varargin{1};
                    gitCmdStr = sprintf('checkout %s',brName);    
                    
                case 'force-checkout-local'
                    % force checks out a local branch
                    brName = varargin{1};
                    gitCmdStr = sprintf('checkout -f %s',brName);                      
                    
                case 'checkout-to-location'
                    % checks out a file from a given branch to a specific
                    % output location 
                    [brName,dFile,dFileOut] = ...
                                deal(varargin{1},varargin{2},varargin{3});
                    gitCmdStr = sprintf('show %s:"%s" > "%s"',...
                                brName,dFile,dFileOut);
                            
                case 'checkout-branch-file'
                    % checks out a file from a specific branch
                    [brName,fName] = deal(varargin{1},varargin{2});
                    gitCmdStr = sprintf('checkout %s "%s"',brName,fName);
                            
                case 'delete-local'
                    % deletes a local branch
                    brName = varargin{1};
                    if length(varargin) == 1
                        % case is a force branch delete
                        gitCmdStr = sprintf('branch -D %s',brName);
                    else
                        % case is the has merged flag is provided
                        if varargin{2}
                            % case is the branch has merged
                            gitCmdStr = sprintf('branch -d %s',brName);
                        else
                            % case is the branch has not merged
                            gitCmdStr = sprintf('branch -D %s',brName);
                        end
                    end

                case 'checkout-version'
                    % checks out a version from a local branch
                    vID = varargin{1};
                    gitCmdStr = sprintf('checkout %s',vID);
                    
                case 'set-branch-head'
                    [bStr,cID] = deal(varargin{1},varargin{2});
                    gitCmdStr = sprintf('git branch -f %s %s',bStr,cID);
                    
                case 'hard-reset'
                    % hard reset a branch to a specific commit
                    cID = varargin{1};
                    gitCmdStr = sprintf('reset --hard %s',cID);
                    
                case 'revert-branch'
                    % reverts a branch back to 
                    cID = varargin{1};
                    gitCmdStr = sprintf('revert --no-commit %s..HEAD',cID);
                    
                case 'create-fetch-branch'
                    % creates a branch from a origin fetch operation
                    brName = varargin{1};
                    gitCmdStr = sprintf('branch %s FETCH_HEAD',brName);
                
                case 'set-global-config'
                    % case is setting a global config parameter
                    [gType,gV] = deal(varargin{1},varargin{2});
                    gitCmdStr = sprintf('config --global %s %s',gType,gV);   
                    
                case 'unset-global-config'
                    % case is unsetting a global config parameter
                    gType = varargin{1};
                    gitCmdStr = sprintf('config --global --unset %s',gType);
                    
                case 'get-global-config'
                    % case is setting a global config parameter
                    gType = varargin{1};
                    gitCmdStr = sprintf('config --global %s',gType);                      
                    
                case 'reset-commit-author'
                    % resets the author for a given commit
                    gitCmdStr = 'commit --amend --reset-author';
                    
                case 'reset-commit-message'
                    % resets the commit message
                    mStr = varargin{1};
                    gitCmdStr = sprintf('commit --amend -m "%s"',mStr);
                    
                case 'set-sequence-editor'
                    % resets the sequence editor script string
                    nwStr = varargin{1};
                    
                    
                case 'reset-branch-name'
                    % resets the commit message
                    brStr = varargin{1};
                    gitCmdStr = sprintf('branch -m "%s"',brStr);                    
                    
                case 'branch-head-commits'
                    % retrieves the head commits for each branch
                    if ~isempty(varargin)
                        % case is for a specific branch
                        rStr = sprintf('refs/heads/%s',varargin{1});
                        gitCmdStr = sprintf(...
                            ['for-each-ref --format="',...
                             '%s(objectname:short)" %s'],'%',rStr);                         
                    else
                        % case is for all branches
                        gitCmdStr = sprintf(...
                            ['for-each-ref --format="%s(refname:short)',...
                             ' %s(objectname:short)" refs/heads'],'%','%');   
                    end
                           
                case 'branch-head-info'
                    gitCmdStr = ['branch -v --format="%',...
                          '(HEAD) %(refname:short) %(objectname:short)"'];
                    
                case 'local-working-commits'
                    % retrieves the commits from the local working branch
                    lBr = varargin{1};
                    if length(varargin) == 1
                        gitCmdStr = sprintf('log --no-merges %s',lBr);
                    else
                        mBr = varargin{2};
                        gitCmdStr = sprintf('cherry -v %s %s',mBr,lBr);
                    end
                    
                case 'copy-local-commit'
                    % case is copying a commit with ID, cID
                    cID = varargin{1};
                    gitCmdStr = sprintf('cherry-pick %s',cID);
                    
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%    STALE BRANCH REMOVAL    %%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                    
                    
                case 'remove-stale-dryrun'
                    % removes any stale remote branches (dry-run)
                    gitCmdStr = 'remote prune origin --dry-run';
                    
                case 'remove-stale-final'
                    % removes any stale remote branches (final)      
                    gitCmdStr = 'remote prune origin';

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%    REBASE FUNCTIONS    %%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                case 'rebase-interactive'
                    % case is running the interactive rebase
                    cID = varargin{1};
                    if length(varargin) == 1
                        gitCmdStr = sprintf('rebase -i %s',cID);
                    else
                        gitCmdStr = sprintf...
                                        ('rebase -i --autosquash %s',cID);
                    end
                    
                case 'rebase-abort'
                    % case is aborting a rebase
                    gitCmdStr = sprintf('rebase --abort');
                    
                case 'rebase-continue'
                    % case is aborting a rebase
                    gitCmdStr = sprintf('rebase --continue');                    
                    
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%    MERGE FUNCTIONS    %%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                case 'merge-no-commit'
                    % performs a no-commit merge
                    mBr = varargin{1};
                    gitCmdStr = sprintf('merge --no-commit --no-ff %s',mBr);
                
                case 'merge-commit'
                    % performs a no-commit merge
                    mBr = varargin{1};
                    if length(varargin) == 1
                        gitCmdStr = sprintf('merge --no-ff %s',mBr);   
                    else
                        gitCmdStr = sprintf('merge %s',mBr); 
                    end
                    
                case 'merge-continue'
                    % continues the merge process
                    gitCmdStr = 'merge --continue';
                    
                case 'abort-merge'
                    % aborts an attempted merge
                    gitCmdStr = 'merge --abort';
                    
                case 'quit-merge'
                    % aborts an attempted merge
                    gitCmdStr = 'merge --quit';                    
                    
                case 'unresolve-merge'
                    % case is unresolving a merge on a specific file
                    unFile = varargin{1};
                    gitCmdStr = sprintf('checkout -m "%s"',unFile);
%                     gitCmdStr = ...
%                         sprintf('update-index --unresolve "%s"',unFile);                    
                    
                case 'get-unmerged-files'
                    % case is determining the unmerged files
                    gitCmdStr = 'diff --name-only --diff-filter=U';
                    
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%    MERGE/DIFFTOOL FUNCTIONS    %%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                case 'run-mergetool'
                    % case is running the mergetool on a specific file
                    mFile = varargin{1};
                    gitCmdStr = sprintf('mergetool "%s"',mFile);
                    
                case 'run-difftool'
                    % case is running the difftool on a specific file
                    [dFile,dFileTmp] = deal(varargin{1},varargin{2});
                    gitCmdStr = sprintf(...
                        'difftool --no-index -- "%s" "%s"',dFile,dFileTmp);                                        
                    
                case 'accept-ours'
                    % case is accepting a file from the "ours" branch
                    fName = varargin{1};
                    gitCmdStr = sprintf('checkout --ours "%s"',fName);
                    
                case 'accept-theirs'
                    % case is accepting a file from the "theirs" branch                    
                    fName = varargin{1};
                    gitCmdStr = sprintf('checkout --theirs "%s"',fName);
                    
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%    CONFIG FILE FUNCTIONS    %%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                case 'show-all-untracked'
                    % ensures all untracked files are shown
                    gitCmdStr = ['config --global ',...
                                 'status.showUntrackedFiles all'];
                    
            end
            
            if ~isempty(gitCmdStr)
                % runs the command string                
%                 tic
                [status,gStr] = system(sprintf('git %s',gitCmdStr));
%                 fprintf('Time = %.2f ("%s")\n',toc,gitCmdStr);
            end
                
            % removes the origin url (if required)
            if resetURL
                obj.gitCmd('rmv-origin')
            end
            
            % sets the output from the command (if required)
            switch nargout
                case 1
                    varargout = {gStr(1:end-1)};
                case 2
                    varargout = {gStr(1:end-1),status};
            end
        end        
    end
    
    % Private class functions
    methods(Access='private')
        
        % retrieves the token key (depending on the user)
        function uType = getUserType(obj)
            
            % retrieves the hostname of the computer
            [~,hName] = system('hostname');
            
            % sets the user type/token key string based on the computer
            switch hName(1:end-1)
                case {'DESKTOP-94RD45L'} 
                    % case is a developer
                    uType = 0;
                    if isempty('get-origin')
                        obj.gitCmd('set-origin')
                    end                    
                    
                otherwise
                    % case is a basic program user
                    uType = 1;
                    if ~isempty('get-origin')
                        obj.gitCmd('rmv-origin')
                    end
                    
            end
            
        end 
        
    end
end
