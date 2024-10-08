function bInfo = reduceStimBlockInfo(bInfo0)

% determines any matching block information
sP = field2cell(bInfo0,'sPara',1); 

% ensures the blocks are in chronological order
[~,iS] = sort(field2cell(sP,'tOfs',1));
[sP,bInfo0] = deal(sP(iS),bInfo0(iS));

% determines which blocks are the same 
B = cell2mat(arrayfun(@(x)(arrayfun(@(y)(isequal(x,y)),sP)),sP,'un',0)');

% memory allocations
iGrpB = [];
isM = false(size(B,1),1);

% groups stimuli blocks that are exact
for i = 1:size(B,1)
    % sets the new grouping
    iGrpB{end+1} = find(B(:,i) & ~isM);
    
    % sets the flags for the matching stimuli blocks
    isM(B(:,i)) = true;
    if all(isM)
        break
    end
end

% removes any empty cells
iGrpB = iGrpB(~cellfun('isempty',iGrpB));

% reduces down the common groupings
bInfo = cell(length(iGrpB),1);
for i = 1:length(iGrpB)
    % memory allocation for the sub-grouping
    bInfo{i} = struct('chName','All Ch','devType',[],'sPara',[],'sType',[]);
    
    % sets the remaining fields
    j = iGrpB{i}(1);
    bInfo{i}.sPara = bInfo0(j).sPara;
    bInfo{i}.sType = bInfo0(j).sType;
    bInfo{i}.devType = bInfo0(j).devType;
end

% converts the cell array to a struct array
bInfo = cell2mat(bInfo);
