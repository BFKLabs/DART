% --- retrieves the stimuli train information 
function [Ts,Tf,blkInfo,ChN] = getStimTimes(stimP,sTrainEx,Type,sType)

% sets the default input arguments
if ~exist('sType','var'); sType = []; end
if ~iscell(stimP); stimP = {stimP}; end
if ~iscell(sTrainEx); sTrainEx = {sTrainEx}; end

% memory allocation
nExpt = length(stimP);
[blkInfo,ChN] = deal(cell(nExpt,1));

% retrieves the device string
for i = 1:nExpt
    % memory allocation
    sTrain = sTrainEx{i}.sTrain;
    nTrain = length(sTrain);
    [blkInfo{i},ChN{i}] = deal(cell(1,nTrain));
    
    % retrieves the unique stimuli block information from all stimuli train
    % used within the current experiment
    for j = 1:nTrain
        pType = getArrayVal(strsplit(sTrainEx{i}.sType{j},'-'),1);
        [blkInfo{i}{j},ChN{i}{j}] = ...
                    getUniqBlkInfo(sTrain(j),stimP{i},Type,sType,pType);
    end
end

% determines the unique stimuli blocks over all experiments
[blkInfo,ChN,iStimEx] = reduceBlkInfo(blkInfo,ChN);

% memory allocation
nStim = length(blkInfo);
[Ts,Tf] = deal(cell(nStim,1));

% sets the details for the stimuli 
for i = 1:nStim
    % determines the number of unique experiment indices
    iEx0 = unique(iStimEx{i}(:,1));
    dType = blkInfo{i}.devType;
    
    % memory allocation
    nEx = length(iEx0);
    [Ts{i},Tf{i}] = deal(cell(1,nEx));
    
    % retrieves the start/stop times of the stimuli events
    for j = 1:nEx
        % determines the stimuli indices that belong to the current expt
        iEx = iEx0(j);
        ii = iStimEx{i}(:,1) == iEx;
        sP = getStructField(stimP{iEx},dType);
        
        % determines which stimuli events correspond to this stimuli type
        sPC = getStructField(sP,ChN{i}{1}{1});
        jj = arrayfun(@(x)(any(iStimEx{i}(ii,2)==x)),sPC.iStim);
        
        % sets the start/finish stimuli times
        [Ts{i}{j},Tf{i}{j}] = deal(sPC.Ts(jj),sPC.Tf(jj));
    end
    
%     % combines the start/finish time arrays into a numerical array
%     Ts{i} = combineNumericCells(Ts{i});
%     Tf{i} = combineNumericCells(Tf{i});
end

% --- reduces the stimuli block information 
function [blkInfo,chN,iStim] = reduceBlkInfo(blkInfo0,chN0)

% memory allocation
nExpt = length(blkInfo0);
% iStim = cellfun(@(x)(NaN(length(x),2)),blkInfo0,'un',0);

% array initialisation
[blkInfo,chN,iStim] = deal([]);

% loop through all experiments determining the unique block information
for i = 1:nExpt
    % loops through each stimuli block type within the current experiment
    for j = 1:length(blkInfo0{i})
        if ~isempty(blkInfo0{i}{j})
            % determines if the current block matches any existing blocks
            if isempty(blkInfo)
                isM = false;
            else
                isM = cellfun(@(x)(isequal(x,blkInfo0{i}{j})),blkInfo);
            end
                
            if ~any(isM)
                % if there is no match, then add in the unique information
                chN = [chN;chN0{i}(j)];
                blkInfo = [blkInfo;{blkInfo0{i}{j}}];
                iStim{end+1} = [i,j];
            else
                % otherwise, set the matching stimuli block index
                iStim{isM} = [iStim{isM};[i,j]];
            end
        end
    end
end

% --- determines the unique block information/channel names for a 
%     given stimuli train, sTrain
function [blkInfo,chN] = getUniqBlkInfo(sTrain,stimP,Type,sType,pType)

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

% resets the channel name strings for the motors
for i = 1:length(blkInfo)
    % sets the protocol type
    blkInfo(i).pType = pType;
    
    if startsWith(blkInfo(i).devType,'Motor')
        % sorts the channel names
        chN{i} = sort(chN{i});
        
        % determines if all the channel names have been clumped together
        sTmp = getStructField(stimP,blkInfo(i).devType);
        if isfield(sTmp,'Ch')
            % if so, then reset the channel names
            chN{i} = {'Ch'};
        end
    end
end