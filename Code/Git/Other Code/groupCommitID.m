% --- groups the commit ID's by their branches
function brGrp = groupCommitID(gfObj)

% splits up the commit reflog strings into their parent/commit IDs
refAll = getReflogID(gfObj,'HEAD');
Y = num2cell(refAll,2);
indR = NaN(size(refAll,1),1);

% retrieves the branch information
logStrB0 = gfObj.gitCmd('branch-head-info');
brInfo = cell2cell(cellfun(@(x)(strsplit(x(3:end))),...
                strsplit(logStrB0(1:end-1),'\n')','un',0));
            
% re-orders the branch info so the master is the first branch
isM = strcmp(brInfo(:,1),'master');
brInfo = brInfo(isM,:);
            
% 
for i = 1:size(brInfo,1)
    % retrieves the commit ID's from the branch
    refID = getReflogID(gfObj,brInfo{i,1});
    
    % matches the overall ID's against the branch ID's
    for j = 1:size(refID,1)
        iNw = cellfun(@(x)(isequal(x,refID(j,:))),Y);
        if isnan(indR(iNw))
            % sets the branch index
            indR(iNw) = i;
        else
            % if the index has already been set then exit the loop
            break
        end
    end
end

% if there are any other remaining groups, then add them in
[i0,j0] = deal(i,0);
while any(isnan(indR))
    % updates the index
    [i0,j0] = deal(i0 + 1,j0 + 1);
    
    % determines the reflog information for the next available commit
    iRow = find(isnan(indR),1,'first');
    revLog0 = gfObj.gitCmd('branch-commits',refAll{iRow,2},1);
    revLog = strsplit(revLog0,'\n')';
    
    %
    for i = 1:(length(revLog)-1)
        % determines which overall commit the current parent/child commit
        % combination matches the overall values
        X = {revLog{i+1},revLog{i}};
        iNw = cellfun(@(x)(isequal(x,X)),Y);
        
        % determines if the index value has already been set
        if isnan(indR(iNw))
            % if so, then update the branch index at the matching commit
            indR(iNw) = i0;
        else
            % otherwise, exit the loop
            break
        end
    end
end

% sets the final branch grouping values
brGrp = arrayfun(@(x)(refAll(indR==x,2)),1:max(indR),'un',0);

% --- retrieves the reflog ID strings
function cInfo = getReflogID(gfObj,pName)

cInfo = gfObj.getAllCommitInfo(pName,'<%p> <%h> <%at> <%s>');
if ~isempty(cInfo)
    [~,iS] = sort(cellfun(@str2double,cInfo(:,3)),'descend');
    cInfo = cInfo(iS,1:2);
end