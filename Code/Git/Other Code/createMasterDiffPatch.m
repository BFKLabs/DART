% --- creates/applies the difference patch to the master branch point
%     from the current status (ignoring any local commits)
function tFile = createMasterDiffPatch(GF,mID,lID,lID2)

% global variables
global mainProgDir

% retrieves the difference string
if exist('lID2','var')
    % case is 2 local commits are provided
    dStr = detMasterDiffString(GF,mID,lID,lID2);
else
    % case is only one local commit is provided
    dStr = detMasterDiffString(GF,mID,lID);
end

% creates the patch file
tFile = fullfile(mainProgDir,'External Files','TempPatch.diff');
fObj = fopen(tFile,'w+');
fwrite(fObj,strjoin(dStr,'\n'));
fclose(fObj);

% --- determines the overall difference between the current state and the
%     master branch point (removing any local branch changes)
function diffStr = detMasterDiffString(GF,mID,lID,lID2)

% determines the previous commit to master branch-point difference
if mID == lID
    % difference is determined from master branch commit (as no
    % local-working branch is involved, we can exit the function
    diffStr = arr2vec(strsplit(...
                        GF.gitCmd('commit-diff-current',mID,1),'\n'));
    return
else
    dStrL2M = strsplit(GF.gitCmd('commit-diff',mID,lID),'\n');
end

% determines the current point to master branch-point difference
if ~exist('lID2','var')
    % if only one local ID was provided, then determine the difference from
    % the current state to the master branch point
    dStrC2M = strsplit(GF.gitCmd('commit-diff-current',mID,1),'\n');
else
    % otherwise, determine the difference from the 2nd local branch commit
    % to the master branch point
    dStrC2M = strsplit(GF.gitCmd('commit-diff',mID,lID2),'\n');
end

% 
dBlkC2M = getCodeBlocks(dStrC2M);
dBlkC2MTot = cellfun(@(x)(strjoin(x([2,5:end]),'\n')),dBlkC2M,'un',0);

% determines the combined differences between 
dBlkL2M = getCodeBlocks(dStrL2M);
dBlkL2MTot = cellfun(@(x)(strjoin(x([2,5:end]),'\n')),dBlkL2M,'un',0);

% joins the final string
[~,iL2C] = setdiff(dBlkL2MTot,dBlkC2MTot,'stable');
[~,iC2L] = setdiff(dBlkC2MTot,dBlkL2MTot,'stable');

diffStr = [cellfun(@(x)(strjoin(x,'\n')),dBlkC2M(iC2L),'un',0);...
           cellfun(@(x)(strjoin(x,'\n')),dBlkL2M(iL2C),'un',0)];
diffStr{end} = sprintf('%s\n',diffStr{end});

% --- splits up the code into its constituent blocks
function dBlk = getCodeBlocks(dStr)

% determines the start indices of the difference blocks
iDiff = find(cellfun(@(x)(startsWith(x,'diff --git')),dStr(:)));
iBlk = num2cell([iDiff,[iDiff(2:end)-1;length(dStr)]],2);

% memory allocation
nBlk = length(iBlk);
[isOK,dBlk] = deal(true(nBlk,1),cell(nBlk,1));

% splits up the code into its blocks (ignore binary files)
for i = 1:nBlk
    dBlk0 = dStr(iBlk{i}(1):iBlk{i}(2));
    if any(cellfun(@(x)(startsWith(x,'Binary files')),dBlk0))
        isOK(i) = false;
    else
        dBlk{i} = dBlk0;
    end
end

% removes the non-binary files
dBlk = dBlk(isOK);

