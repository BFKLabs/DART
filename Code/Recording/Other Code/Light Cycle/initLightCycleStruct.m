% --- initialises the light cycle data struct
function LCycle = initLightCycleStruct()

% fixed cycle parameters
pConst = struct('pW',50,'pIR',0);
a = struct('Dur',720*[1;1],'pW',[50;0],'pIR',[0;50],'useTrans',0,'tTrans',5);

% total data struct memory allocation
LCycle = struct('isSerial',false,'lType',1,'sType',2,'T0',[8;0],'hS',[],...
                'pFixed',a,'pVar',a,'pConst',pConst);
