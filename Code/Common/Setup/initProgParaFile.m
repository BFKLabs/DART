% --- initialises the program parameter file
function initProgParaFile(paraDir)

% initialises the individual parameter structs
gPara = initGlobalPara();
bgP = DetectPara.initDetectParaStruct('All',false);
trkP = initTrackPara();
sDev = initSerialDeviceNames();

% saves the parameter parameter structs to file
pFile = fullfile(paraDir,'ProgPara.mat');
save(pFile,'gPara','bgP','trkP','sDev');

% ------------------------------------------------- %
% --- PARAMETER STRUCT INITIALISATION FUNCTIONS --- %
% ------------------------------------------------- %

% --- initialises the global parameter struct --- %
function gPara = initGlobalPara()

% global variables
global tDay

% initialises the parameter struct
gPara = struct('Tgrp0',[],'TdayC',[],'movType',[],'pWid',[],...
               'tNonR',[],'nAvg',[],'dMove',[],'tSleep',[]);

% sets the parameter fields
gPara.Tgrp0 = 8;
gPara.TdayC = 12;
gPara.movType = 'Absolute Location';
gPara.pWid = 0.5;
gPara.tNonR = 60;
gPara.nAvg = 10;
gPara.dMove = 3;
gPara.tSleep = 5;           
           
% initialises the global variables
tDay = gPara.Tgrp0;     

% --- initialises the serial devices names
function sDev = initSerialDeviceNames()

% sets the serial device names
sDev = {'STMicroelectronics STLink COM Port';...
        'STMicroelectronics STLink Virtual COM Port';...
        'STMicroelectronics Virtual COM Port';...
        'USB Serial Device'};