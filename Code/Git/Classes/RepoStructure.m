classdef RepoStructure < handle
    
    % properties
    properties
        % main class fields
        logStr
        gSym
        bInfo
        brData       
        
        % git repo history fields
        gHist        
        
        % additional class fields
        indBr
        indCm
        indMrg
        isBranch
        headID
        headID0
        
        % filter parameters
        nHist
        d0
        d1        
        
        % other scalar class fields
        nLog
        nBr 
        nCommit
        isMod = false;
        
    end
    
    % class methods
    methods
        
        % --- repo structure object
        function obj = RepoStructure(varargin)
            
            % sets the input arguments
            obj.setInputArgs(varargin);            
            
            % initialises the log string data
            obj.initLogData();   
            obj.splitLogData();                        
           
            % sets up the branch data field
            obj.setupBranchData();    
            
            % searches the log graph tree
            obj.searchGraphTree();
            obj.finaliseRepoStructure();
            
        end        
        
        % --- sets the input arguments
        function setInputArgs(obj,varargin)
            
            % creates the input parser
            ip = inputParser;
            addParameter(ip,'nHist',-1);
            addParameter(ip,'d0',[]);
            addParameter(ip,'d1',[]);  
            
            % parses the input arguments
            parse(ip,varargin{1}{:})
            p = ip.Results;
            
            % sets the input parameters into the class object
            pFld = fieldnames(p);
            for i = 1:length(pFld)
                setStructField(obj,pFld{i},getStructField(p,pFld{i}));
            end
            
        end        
        
        % --- initialises the repo log data
        function initLogData(obj)
            
            % -------------------------- %
            % --- BRANCH INFORMATION --- %
            % -------------------------- %
            
            % retrieves the branch information
            cmdStrB = ['git branch -v --format="%(HEAD) ',...
                       '%(refname:short) %(objectname:short)"'];
            [~,logStrB0] = system(cmdStrB); 
            
            % splits up the repo branch data into its components
            X = strsplit(logStrB0(1:end-1),'\n')';
            isDetached = strContains(X,'HEAD detached ');
            if any(isDetached)
                Xtmp = strsplit(X{isDetached});
                X{isDetached} = sprintf('* detached %s',Xtmp{end});
            end
            
            % combines the branch data information
            brData0 = cell2cell(cellfun(@(x)(strsplit(x)),X,'un',0));                            

            % ----------------------- %
            % --- LOG INFORMATION --- %
            % ----------------------- %    
            
            % determines all non-detached branches
            isDetached = strcmp(brData0(:,2),'detached');
            brAll = strjoin(brData0(~isDetached,2),' ');
            
            % sets up the git log information string           
            cmdStrL = ['git log --graph --topo-order --decorate ',...
                          '--exclude=refs/stash ',...
                          '--date=format:"%Y-%m-%d" ',...
                          '--pretty=format:"{%h} {%ad} {%s}"'];
                      
            % retrieves the log information
            [~,logStrL0] = system(sprintf('%s %s',cmdStrL,brAll));             

            % retrieves the initial master branch commit ID
            cmdStrCID = ['git rev-list --max-parents=0 master ',...
                         '--pretty=format:"%h"'];
            [~,logStrID0] = system(cmdStrCID);
            logStrID = strsplit(logStrID0(1:end-1));
            mCID0 = logStrID{end};
            
            % determines the commit that is currently the head
            obj.logStr = cellfun(@(x)(strrep(x,char(13),'')),...
                                strsplit(logStrL0,'\n')','un',0);               
            
            % reduces down log info to only include the master branch
            isMaster0 = strContains(obj.logStr,mCID0);
            obj.logStr = obj.logStr(1:find(isMaster0,1,'first'));                                                               
            
            % retrieves the head commit ID
            isHead = strcmp(brData0(:,1),'*'); 
            obj.headID0 = brData0{isHead,3};             
            
            % combines the data from the valid branches into a single array  
            isValidBr = ~strContains(brData0(:,2),'detached') & ...
                cellfun(@(x)(any(strContains(obj.logStr,x))),brData0(:,3));             
            obj.brData = brData0(isValidBr,2:end);
            
            % appends a column to the array
            obj.brData = [obj.brData,cell(sum(isValidBr),1)];

            % sets the master initial commit ID
            isMaster = strcmp(obj.brData(:,1),'master');
            obj.brData{isMaster,3} = mCID0;

            % if there is only a single branch, then exit
            if size(obj.brData,1) > 1
                % sets the initial commit ID's for the other branches                
                for i = find(~isMaster(:)')
                    obj.brData{i,3} = obj.getBranchPoints(obj.brData{i,2});
                end
            end                                
            
        end

        % --- sets the current head ID
        function setHeadID(obj)            
            
            % determines a match for the current head in the history log
            hID0 = obj.headID0;
            if any(strcmp(obj.bInfo(:,1),hID0))
                % if there is a match, then exit
                obj.headID = hID0;
                return
            end
            
            % if there is not a match, then reset the current head to the
            % best match to that in the repository
            %  => probably not the optimal search because an exhaustive
            %     search would be best (but would take too long)
            
            %
            brName = field2cell(obj.gHist,'brName');
            gHistM = obj.gHist(strcmp(brName,'master'));
            
            %
            stStr = {'file','deletion','insertion'};
            [CID,Date] = deal(gHistM.brInfo.CID,gHistM.brInfo.Date);
            DateH = obj.gitFunc('get-commit-date',hID0);
            
            %
            isLater = cellfun(@(x)(datenum(x)),Date) >= datenum(DateH);
            if all(isLater)
                i0 = length(cID);
            else
                i0 = find(isLater,1,'last') + 1;
            end
            
            % keep searching until the optimal solution is found 
            sBest = 1e6*ones(1,3);
            for i = i0:-1:1
                % determines the commit differences statistics
                dStr = obj.gitFunc('diff-commit-stats',CID{i},hID0);
                
                % splits the difference stats into an array
                sNew = cellfun(@(x)(str2double(regexp(dStr,...
                        sprintf('\\d*(?= %s)',x),'match','once'))),stStr);
                sNew(isnan(sNew)) = 0;
                
                % determines if the new score is better
                if obj.calcStatsScores(sNew) < obj.calcStatsScores(sBest)
                    % if so, update the score
                    [iBest,sBest] = deal(i,sNew);
                else
                    % otherwise, exit the loop
                    break
                end
            end
            
            % force checkout of the best solution
            obj.headID = CID{iBest};
            obj.gitFunc('force-checkout',CID{iBest});            
            
        end
        
        % --- splits the log data into its components
        function splitLogData(obj)

            % determines the 
            obj.nLog = length(obj.logStr);
            obj.bInfo = cell(obj.nLog,3);            

            % calculates the symbol column gap
            nGap = cellfun(@(x)...
                        (regexp(x,'\{','once')-1),obj.logStr,'un',0);
            hasC = ~cellfun(@isempty,nGap);
            nGap(~hasC) = cellfun(@length,obj.logStr(~hasC),'un',0);
            
            % sets the master branch name
            obj.nCommit = sum(hasC);

            % retrieves the graph link symbols
            obj.gSym = repmat({' '},[obj.nLog,2+max(cell2mat(nGap))]);
            for i = 1:obj.nLog
                % sets the graph link symbols
                xiC = 1+(1:nGap{i});
                obj.gSym(i,xiC) = num2cell(obj.logStr{i}(1:nGap{i}));

                % sets the commit data
                if hasC(i)
                    % splits the commit data into its components
                    obj.bInfo(i,:) = obj.splitCommitInfo...
                                            (obj.logStr{i}(nGap{i}+1:end));
                end
            end
            
            % sets the final graph symbol/log 
            obj.gSym = cellfun(@strip,obj.gSym,'un',0);                   

            % sets the branching flags
            obj.isBranch = any(cell2mat(cellfun(@(x)(strcmp...
                        (obj.bInfo(:,1),x)),obj.brData(:,end)','un',0)),2);
            obj.isBranch(end) = false;              
            
        end

        % --- sets up the branch data field
        function setupBranchData(obj)
            
            % other field initialisation
            obj.nBr = size(obj.brData,1);                     
            
            % allocates memory for the repo branch histories
            a = struct('iBr',[],'brName',[],'pName',[],...
                       'pCID',[],'brInfo',[],'iLvl',0);
            obj.gHist = repmat(a,obj.nBr,1);
            
            % sets the branch names
            for i = 1:obj.nBr
                obj.gHist(i).iBr = i;
                obj.gHist(i).brName = obj.brData{i,1};
            end
            
        end        
        
        % --- finalises the repo structure
        function finaliseRepoStructure(obj)
            
            % retrieves the git history data struct
            isMaster = strcmp(obj.brData(:,1),'master');
            gHistM = obj.gHist(isMaster);
            
            % determines if extra filtering is required
            if obj.nHist > 0
                % case is filtering by count
                if size(gHistM.brInfo,1) <= obj.nHist
                    % if the history length is less than specifed then exit
                    return
                end
                
                % determines the history cutoff point
                cIDN = gHistM.brInfo.CID{obj.nHist};
                iLine = find(strContains(obj.logStr,cIDN));
                [xiM,xiL] = deal(1:obj.nHist,1:iLine);                
                
            elseif ~isempty(obj.d0)
                % case is filtering commits by date
                dNumF = datenum(obj.d0.Year,obj.d0.Month,obj.d0.Day);
                dNumM = cellfun(@(x)(datenum(x)),obj.gHist(1).brInfo.Date);                
                
                % determines which commits meet the date filter
                isKeep = dNumM >= dNumF;
                if all(isKeep)
                    % if the filter has no effect, then exit
                    return
                end
                
                % determines the commit and log line that corresponds to
                % the last feasible commit from the master branch
                iCm = find(isKeep,1,'last');
                cIDN = obj.gHist(1).brInfo.CID{iCm};
                iLine = find(strContains(obj.logStr,cIDN));
                [xiM,xiL] = deal(1:iCm,1:iLine);
                
            else
                % if no filtering, then exit
                return
                
            end
            
            % resets the master branch info array
            obj.gHist(isMaster).brInfo = gHistM.brInfo(xiM,:); 
            obj.brData{isMaster,2} = obj.gHist(isMaster).brInfo.CID{1};
            obj.brData{isMaster,3} = obj.gHist(isMaster).brInfo.CID{end};
            
            % resets the log string/symbol arrays            
            obj.logStr = obj.logStr(xiL); 
            obj.gSym = obj.gSym(xiL,:);
            obj.bInfo = obj.bInfo(xiL,:);
            obj.indBr = obj.indBr(xiL,:);
            obj.indCm = obj.indCm(xiL,:);
            obj.indMrg = obj.indMrg(xiL,:);
            obj.isBranch = obj.isBranch(xiL);
            
            % determines if the 
            isOK = isMaster;
            for i = find(~isOK(:)')
                if strcmp(obj.gHist(i).pName,'master')
                    % if branching off master, then determine if the branch
                    % is still within the range of commits
                    isOK(i) = any(strcmp(obj.gHist(1).brInfo.CID,...
                                         obj.gHist(i).pCID));
                else
                    % otherwise, determine if the sub-branches parent is
                    % within the new range of commits
                    iPr = strcmp(obj.brData(:,1),obj.gHist(i).pName);
                    isOK(i) = isOK(iPr);
                end
            end
            
            % resets the history/branch fields
            obj.gHist = obj.gHist(isOK);
            obj.brData = obj.brData(isOK,:);
            
            %
            obj.nLog = length(xiL);
            obj.nBr = sum(isOK);
            obj.nCommit = sum(arrayfun(@(x)(size(x.brInfo,1)),obj.gHist));
            
        end
        
        % ----------------------------- %        
        % --- TREE SEARCH FUNCTIONS --- %
        % ----------------------------- %
        
        % --- searches the graph tree for all given paths
        function searchGraphTree(obj)
            
            % memory allocation
            szInd = size(obj.gSym)-[0,2];
            cHdr = {'ID','CID','Desc','Date','mCID','mName'}; 
            iBrS = find(strcmp(obj.brData(:,1),'master'));
            [obj.indCm,obj.indBr,obj.indMrg] = deal(NaN(szInd));
            [obj.indCm(end,1),obj.indBr(end,1)] = deal(obj.nLog,iBrS);
            
            % retrieves all the branch paths starting at the initial commit            
            obj.getBranchPath([obj.nLog,1],obj.nLog,iBrS)
            obj.finaliseBranchPaths();
            
            % retrieves the branch indices for each commit
            indI = find(~cellfun(@isempty,obj.bInfo(:,1)));
            indCG = num2cell(obj.indCm(indI,:),2);
            indM = cellfun(@(x,y)(find(x==y)),indCG,num2cell(indI),'un',0);
             
            % determines the indices of the commits for each branch
            bInfoI = obj.bInfo(indI,:);
            indBrG = num2cell(obj.indBr(indI,:),2);
            indBrF = cellfun(@(x,y)(x(y)),indBrG,indM);            
            indG = arrayfun(@(x)(find(indBrF==x)),1:obj.nBr,'un',0)';
            
            % reduces the 
            isMrg = ~isnan(obj.indMrg);
            iMrg = obj.indMrg(isMrg);
            [iMrgBr,iMrgCm] = deal(obj.indBr(isMrg),obj.indCm(isMrg));
            
            % other memory allocation
            iRow = cell(obj.nBr,1);
            
            % sets the commit information for each branch in the repo
            for i = 1:obj.nBr
                % initialises the branch info table
                A = cell(length(indG{i}),length(cHdr));
                obj.gHist(i).brInfo = array2table(A,'VariableNames',cHdr);
                
                % sets the branch information fields
                bInfoBr = bInfoI(indG{i},:);
                obj.gHist(i).brInfo.ID = arrayfun(@num2str,indG{i},'un',0);
                obj.gHist(i).brInfo.CID = bInfoBr(:,1);
                obj.gHist(i).brInfo.Date = bInfoBr(:,2);
                obj.gHist(i).brInfo.Desc = bInfoBr(:,3);                
                
                % sets the merge node information (if merge nodes exist)
                ii = find(iMrgBr == i);
                if ~isempty(ii)
                    % determines the commits with merges in the branch
                    iMrgG = iMrg(ii);
                    indGlob = indI(indG{i});
                    jj = arrayfun(@(x)(find(indGlob==x)),iMrgCm(ii));                    
                    
                    % for each of these commits, then set the ID and
                    % branch of the merging commit
                    for j = 1:length(iMrgG)
                        % sets the corresponding merge ID
                        obj.gHist(i).brInfo.mCID{j} = obj.bInfo{iMrgG(j),1};
                        
                        % sets the corresponding merge branch name
                        iMrgPr = obj.indBr(iMrg(j),...
                                    strcmp(obj.gSym(iMrg(j),2:end-1),'*'));
                        obj.gHist(i).brInfo.mName{j} = obj.brData{iMrgPr,1};
                    end
                end     
                
                % sets the channel index
                hasCL = ~cellfun(@isempty,obj.bInfo(:,1));                
                indBrRow = find(any(obj.indBr(hasCL,:) == i,2));
                if ~isempty(indBrRow)
                    iRow{i} = indBrRow(1):indBrRow(end);
                end                                
            end
            
            % sorts the branch history by level
            [~,iS] = sort(field2cell(obj.gHist,'iLvl',1));
            obj.gHist = obj.gHist(iS,:);
            obj.brData = obj.brData(iS,:);

            %
            indBr0 = obj.indBr;
            for i = 1:length(obj.gHist)
                obj.gHist(i).iBr = i;
                obj.indBr(indBr0==iS(i)) = i;
            end     
            
            % sets the head commit ID
            obj.setHeadID();              
            
        end
        
        % --- finalises the branch paths
        function finaliseBranchPaths(obj)
            
            % ensures the first/last commits of a branch are set correctly
            for i = 1:obj.nBr
                % sets the initial/final commit flags
                for j = 2:3
                    % determines the row/column of the commit
                    cID = obj.brData{i,j};
                    iRow = find(strcmp(obj.bInfo(:,1),cID));
                    iCol = strcmp(obj.gSym(iRow,2:end-1),'*');
                    
                    % ensures the branch index is correct
                    obj.indBr(iRow,iCol) = i;
                end
                
            end
            
        end
        
        % --- searches the branch path (for initial branch/log index of
        %     iBr/iLog respectively) starting at the current point, pC
        function getBranchPath(obj,pC,iLog,iBr)
           
            % loop initiaisations
            cont = true;
            
            % keep searching until either A) the end of a branch is
            % reached, or B) the branch merges into another branch
            while cont
                % gets the next group symbol from the current point
                [gSymS,dxi] = obj.getNewSymbols(pC);
                iSym = find(~cellfun(@isempty,gSymS));
                
                % determines 
                switch length(iSym)
                    case 0
                        % case is no symbol matches (end of branch) obj
                        cont = false;
                        
                    case 1
                        %
                        iColNw = pC(2)+dxi(iSym);
                        if strcmp(gSymS{iSym},'_')
                            mlt = 1-2*strcmp(obj.gSym{pC(1),pC(2)+1},'\');
                            obj.indCm(pC(1)-1,iColNw) = iLog;
                            obj.indBr(pC(1)-1,iColNw) = iBr;                            
%                             
                            %
                            cOfs = 1+2*mlt;
                            while strcmp(obj.gSym{pC(1)-1,pC(2)+cOfs},'_') 
                                pC(2) = pC(2)+2*mlt;
                                obj.indCm(pC(1)-1,pC(2)) = iLog;
                                obj.indBr(pC(1)-1,pC(2)) = iBr;                                 
                            end
                            
                            %
%                             [iColNw,pC(1)] = deal(pC(2)+2*mlt,pC(1)-1);
                            iColNw = pC(2)+2*mlt;
                            
                        end
                        
                        % case is single match
                        if strcmp(gSymS{iSym},'*')
                            % case is a commit (reset the log index)
                            [iLog0,iLog] = deal(iLog,pC(1)-1);
                            
                            % determines if a new branch has been found
                            if obj.isBranch(iLog)
                                % makes a copy of the branch/level index
                                iBrPr = iBr;
                                iLvlPr = obj.gHist(iBrPr).iLvl;
                                 
                                % if so, then increment counter
                                brID = obj.bInfo{iLog,1};
                                iBr = find(strcmp(obj.brData(:,3),brID));                                
                                
                                % set parent name/commit ID
                                obj.gHist(iBr).iLvl = iLvlPr + 1;
                                obj.gHist(iBr).pName = obj.brData{iBrPr,1};
                                obj.gHist(iBr).pCID = obj.bInfo{iLog0,1};
                            end                            
                        end
                        
                        % updates the commit/branch index arrays                        
                        if isnan(obj.indCm(pC(1)-1,iColNw))
                            % if the indices have not been set, the update
                            obj.indCm(pC(1)-1,iColNw) = iLog;
                            obj.indBr(pC(1)-1,iColNw) = iBr;

                            % updates the current position (if possible)
                            pC = [pC(1)-1,iColNw];
                            if pC(1) == 1
                                % if on the first log graph row, then exit
                                cont = false;
                            end
                        else
                            % otherwise, exit the loop (merge point)
                            cont = false;
                            obj.indMrg(pC(1),pC(2)) = ...
                                                obj.indCm(pC(1)-1,iColNw);
                        end
                        
                    otherwise
                        % case is multiple matches
                        for i = iSym(:)'
                            % updates the commit/branch index arrays
                            iColNw = pC(2)+dxi(i);
                            
                            % determines if the indices have not been set
                            if isnan(obj.indCm(pC(1)-1,iColNw)) && ...
                                                    ~strcmp(gSymS{i},'_')
                                % if so, update the commit/branch indices
                                obj.indCm(pC(1)-1,iColNw) = iLog;
                                obj.indBr(pC(1)-1,iColNw) = iBr;

                                % searches the split in the path (if this 
                                % is currently not the penultimate row)
                                if pC(1) > 1
                                    % if so, then search the path split 
                                    pCnw = [pC(1)-1,iColNw];
                                    obj.getBranchPath(pCnw,iLog,iBr);
                                end
                            end
                        end
                        
                        % flag exiting the loop
                        cont = false;                        
                        
                end
                
            end
            
        end
        
        % --- retrieves the new symbol group from the current point, pC
        function [gSymS,dC] = getNewSymbols(obj,pC)
            
            % retrieves the current symbol
            gSymC = obj.gSym{pC(1),pC(2)+1};
            switch gSymC
                case '\'
                    dCol = [-2,0];
                    
                case '/'
                    dCol = [0,2];
                    
                case {'*','|'}
                    dCol = [-1,1];
                    
            end
            
            % retrieves the new symbol sub-array
            dC = dCol(1):dCol(2);
            iColS = pC(2)+dC;
            gSymS = obj.gSym(pC(1)-1,(iColS+1));
            
            % determines if the 
            switch gSymC
                case {'*','|'}
                    isOK = [strcmp('\',gSymS{1}),...
                            any(strcmp({'|','*'},gSymS{2})),...
                            strcmp('/',gSymS{3})];
                    
                case '/'
                    isOK = [strcmp('\',gSymS{1}),...
                            any(strcmp({'|','*'},gSymS{2})),...
                            any(strcmp({'/','_'},gSymS{3}))];   
                        
                    if all(strcmp(obj.gSym(pC(1)+[-1,0],pC(2)+2),'|'))
                        isOK(2) = false;
                    end
                    
                case '\'
                    isOK = [any(strcmp({'\','_'},gSymS{1})),...
                            any(strcmp({'|','*'},gSymS{2})),...
                            strcmp('/',gSymS{3})];
                        
                    if all(strcmp(obj.gSym(pC(1)+[-1,0],pC(2)),'|'))
                        isOK(2) = false;
                    end                        
            end
            
            % removes any 
            gSymS(~isOK) = {''};
        end
       
        % --- retrieves the previous branch points from commit ID, cID
        function brStr = getBranchPoints(obj,cID)

            % sets up the git command string  
            cStrHF = '(User: ';
            cStrC = '1st Commit (Branched from';
            
            % determines if there are any branch commits
            brStr0 = obj.gitFunc('revlist-grep',cID,cStrC);
            if isempty(brStr0)
                % if not, then determine if there are any hotfix branches
                brStr0 = obj.gitFunc('revlist-grep',cID,cStrHF); 
                if isempty(brStr0)
                    % if not, then return with an empty array
                    brStr = [];
                    return
                end
            end
            
            % determines any hot-fix/branch commits           
            brStrSp = strsplit(brStr0,'\n')';
            brStr = regexp(brStrSp{1},'\w+','match','once');            
                          
        end           
        
    end
    
    % static class methods
    methods (Static)
        
        % --- calculates the difference statistics score
        function sScore = calcStatsScores(sStats)
            
            sScore = 1e6*sStats(1) + sum(sStats(2:3));
            
        end
        
        % --- splits the commit info string into commit ID and description
        function brInfo = splitCommitInfo(brInfo0)

            brInfoSp = regexp(brInfo0,'[^{}]*','match');
            brInfo = brInfoSp(1:2:end);

        end                        

        % --- retrieves the test string
        function [testStrL,testStrB] = getTestString()

            % path/file name
            fDir = 'C:\Work\DART\Program (Git)\Testing Files\GitGraph';
            fNameL = 'TestLogGraph.txt';
            fNameB = 'TestRepoBranch.txt';

            % retrieves the test graph struct
            fIDL = fopen(fullfile(fDir,fNameL));
            testStrL = fread(fIDL,'*char')';
            fclose(fIDL);  
            
            % retrieves the test graph struct
            fIDB = fopen(fullfile(fDir,fNameB));
            testStrB = fread(fIDB,'*char')';
            fclose(fIDB);  
            
        end                 
        
        % --- case is running a git function
        function varargout = gitFunc(cStr,varargin)
        
            % sets up the git command string
            switch cStr
                case 'revlist-grep'
                    %
                    [cID,gStr] = deal(varargin{1},varargin{2});
                    gitCmdStr = sprintf(['rev-list %s ',...
                                '--grep="%s" --oneline'],cID,gStr); 
                            
                case 'diff-commit-stats'
                    % case is the commit difference statistics
                    [cID1,cID2] = deal(varargin{1},varargin{2});
                    gitCmdStr = sprintf('diff --shortstat %s %s',cID1,cID2);    
                    
                case 'get-commit-date'
                    % case is retrieving the date of a commit
                    cID = varargin{1};
                    gitCmdStr = sprintf('show %s -s --format=%s',cID,'%cs');
                    
                case 'force-checkout'
                    % case is force switching a commit (ignores changes)
                    nwBr = varargin{1};
                    gitCmdStr = sprintf('checkout -f %s',nwBr);                      
                    
            end
            
            if ~isempty(gitCmdStr)
                % runs the command string                
                [status,gStr] = system(sprintf('git %s',gitCmdStr));
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
    
end