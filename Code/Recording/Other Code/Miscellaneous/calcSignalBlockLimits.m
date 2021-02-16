% --- calculates the lower/upper limits of the stimuli blocks 
function tLimBlk = calcSignalBlockLimits(sBlk)

% retrieves the position vectors for each stimuli block
sPos0 = cellfun(@(x)(x.getPosition()),sBlk,'un',0);
sPos = cell2mat(sPos0(:));

% if more than one stimuli block, then sort by the start time
if size(sPos,1) > 1
    [~,iSort] = sort(sPos(:,1));
    sPos = sPos(iSort,:);
end

% calculates the lower/upper time limits
tLimBlk = [sPos(1,1),sum(sPos(end,[1,3]))];