% --- initialises the total stimulus parameter struct
function iStim = initTotalStimParaStruct()

% memory allocation
sStr = struct('sRate',[]);
iStim = struct('oPara',sStr,'nDACObj',0,'nChannel',[],'ID',[]);

% sets the firing frequency of the device (used for stimuli timer)
iStim.oPara.sRate = 1000;
