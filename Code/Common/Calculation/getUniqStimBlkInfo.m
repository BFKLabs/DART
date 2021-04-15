% --- determines the unique block information/channel names for a 
%     given stimuli train, sTrain
function [blkInfo,chN] = getUniqStimBlkInfo(sTrain,Type,sType)

% sets the default input arguments
if ~exist('Type','var'); Type = 'All'; end
if ~exist('sType','var'); sType = []; end

% ensures the type variable is of the correct form
if strcmp(Type,'All')
    Type = {'Motor','Opto'}; 
elseif ~iscell(Type)
    Type = {Type};
end

% ensures the sub-type (if provided) is stored in a cell-array
if ~isempty(sType)
    if ~iscell(sType)
        sType = {sType};
    end
end

% sets the block information for the stimuli train
blkInfo0 = sTrain.blkInfo;
chN0 = field2cell(blkInfo0,'chName');
blkInfo0 = arrayfun(@(x)(rmfield(x,'chName')),blkInfo0);

% determines the information blocks with the correct device type 
devType = field2cell(blkInfo0,'devType');
isOK = cellfun(@(x)(any(strContains(x,Type))),devType);

% determines the information blocks with the correct channel type (if
% provided)
if ~isempty(sType)
    isOK = isOK & cellfun(@(x)(any(strContains(x,sType))),chN0);
end

% determines if there are any remaining feasible blocks
if any(isOK)
    % if so, the remove the infeasible blocks
    [blkInfo0,chN0] = deal(blkInfo0(isOK),chN0(isOK));
else
    % if there are no feasible matches, then exit
    [blkInfo,chN] = deal([]);
    return
end

% memory allocation
nBlk = length(blkInfo0);
isUniq = setGroup(1,[nBlk,1]);
iBlk = double(isUniq);

% loops through each block determining if they are unique
for i = 2:nBlk
    isMatch = arrayfun(@(x)(isequal(blkInfo0(i),x)),blkInfo0(isUniq));
    if any(isMatch)
        % if there is a match, then set the matching block index
        iBlk(i) = find(isMatch);
    else
        % otherwise, flag the block as unique and reset the block index
        isUniq(i) = true;
        iBlk(i) = sum(isUniq);
    end
end

% reduces the block information to only the unique blocks
blkInfo = blkInfo0(isUniq);
chN = arrayfun(@(x)(chN0(iBlk==x)),(1:length(blkInfo))','un',0);    
