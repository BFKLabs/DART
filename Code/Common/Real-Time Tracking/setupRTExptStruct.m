% --- initialises the real-time experiment data struct
function rtPos = setupRTExptStruct(iMov)

% initialisations
[nFlyR,N] = deal(getSRCountVec(iMov),1000);

% struct memory allocation
rtPos = struct('T',[],'fPos',[],'ind',0,'indMx',N);

% sub-field memory allocation
rtPos.T = NaN(N,1);
rtPos.fPos = cellfun(@(x)(repmat({NaN(N,2)},1,x)),num2cell(nFlyR),'un',0);

