% --- initialises the tracking parameter struct
function trkP = initTrackPara()

% initialises the tracking parameter struct
trkP = struct('nFrmS',25,'nPath',1,'PC',[],'Mac',[]);

% sets the PC classification parameters
trkP.PC.pNC = struct('pCol',[1.0 1.0 0],'pMark','.','mSz',20);
trkP.PC.pMov = struct('pCol',[0.0 1.0 0.0],'pMark','.','mSz',20);
trkP.PC.pStat = struct('pCol',[1.0 0.4 0.0],'pMark','.','mSz',20);
trkP.PC.pRej = struct('pCol',[1.0 0.0 0.0],'pMark','.','mSz',20);

% sets the Mac classification parameters
trkP.Mac.pNC = struct('pCol',[1.0 1.0 0],'pMark','*','mSz',8);
trkP.Mac.pMov = struct('pCol',[0.0 1.0 0.0],'pMark','*','mSz',8);
trkP.Mac.pStat = struct('pCol',[1.0 0.4 0.0],'pMark','*','mSz',8);
trkP.Mac.pRej = struct('pCol',[1.0 0.0 0.0],'pMark','*','mSz',8);