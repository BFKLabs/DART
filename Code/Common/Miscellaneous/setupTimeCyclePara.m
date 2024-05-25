% --- sets up the time cycle parameter data struct
function tcPara = setupTimeCyclePara()

% retrieves the global parameter struct
A = load(getProgFileName('Para Files','ProgPara.mat'));
gP = A.gPara;

% memory allocation
tcPara = struct('tOn',gP.TdayC,'tOff',gP.TdayC,...
                'tCycleR',[],'tCycle0',[],'isFixed',1);

% setting class fields
tMin = minutes(hours(gP.Tgrp0));
tcPara.tCycle0 = [floor(tMin/60),mod(tMin,60),0];
