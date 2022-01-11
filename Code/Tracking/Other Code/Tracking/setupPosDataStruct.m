% --- initialises the fly position data struct --- %
function pData = setupPosDataStruct(iMov,T)

% loads the global analysis parameters from the program parameter file
nFrmS = getFrameStackSize();

% sets up the phase count (based on segmentation type)
isDD = isDirectDetect(iMov);
if isDD
    % case is direct-detection
    nPhase = 1;
else
    % case is background subtraction
    nPhase = length(iMov.vPhase);
end

% array length indexing
nTube = getSRCount(iMov);
nApp = length(iMov.iR);
nFrm = diff(iMov.iPhase,[],2) + 1;
nFrmS = iMov.sRate.*floor(nFrmS./iMov.sRate);
nStack = ceil(nFrm/nFrmS);                 

% memory allocation 
xiT = num2cell(nTube)';
a = cellfun(@(x)(repmat({NaN(sum(nFrm),2)},1,x)),xiT,'un',0);
b = cellfun(@(x)(repmat({NaN(sum(nFrm),1)},1,x)),xiT,'un',0);

% sets the fly location data struct
pData = struct('T',[],'fPos',[],'fPosL',[],'IPos',[],'frmOK',[],'isSeg',[],...
               'nTube',nTube,'nApp',nApp,'nCount',[],'calcPhi',iMov.calcPhi);
pData.IPos = b;           
[pData.fPos,pData.fPosL] = deal(a);
[pData.nCount,pData.isSeg] = deal(zeros(nPhase,1),false(nPhase,1));

% if calculating the orientation angle, then allocate memory
if (pData.calcPhi)
    b = cellfun(@(x)(repmat({NaN(sum(nFrm),1)},1,x)),xiT,'un',0);
    [pData.Phi,pData.PhiF,pData.axR,pData.NszB] = deal(b);
end

% sets the time vector (if it is provided)
if (nargin == 2); pData.T = T; end

% other memory allocations
pData.frmOK = cell(nPhase,1);
for i = 1:nPhase
    pData.frmOK{i} = zeros(nStack(i),1);
end
