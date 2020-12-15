% --- initialises the total stimulus parameter struct
function iStim = initTotalStimParaStruct()

% memory allocation
sStr = struct('sRate',[]);
iStim = struct('oPara',sStr,'nDACObj',0,'nChannel',[],'ID',[]);

% sets the min/max actuator potentials
iStim.oPara.sRate = 50;