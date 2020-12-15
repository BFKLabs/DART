% --- initialises the program parameter file
function initProgParaFile(paraDir)

% initialises the individual parameter structs
gPara = initGlobalPara();
bgP = DetectPara.initDetectParaStruct()
[p1D,p2D] = initGaborTemplatePara();
trkP = initTrackPara();
sDev = initSerialDeviceNames();
fOpto = initOptoIntensityCurves(paraDir);
% lightR = initLightResponseCurve();

% saves the parameter parameter structs to file
pFile = fullfile(paraDir,'ProgPara.mat');
save(pFile,'gPara','bgP','p1D','p2D','trkP','sDev','fOpto');
% save(pFile,'gPara','bgP','p1D','p2D','trkP','sDev','lightR');

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

% --- initialises the background parameter struct
function bgP = initBGParaStruct()

% initialises the reflection glare parameter struct
bgP = struct('P',0.25,'Pmx',0.8,'PmxTol',0.2,'AvgTol',8.0,...
             'IqrTol',4,'pDel',25,'pTolLo',0.275,'pTolHi',0.85,...
             'algoType','bgs-single','gSz',20,'gSD',5,'pTolDD',0.95,...
             'svmFcn','rbf','pOrder',3,'sFac',1,'optDS',false);
         
% sets the gabor function template parameters
function [p1D,p2D] = initGaborTemplatePara()

% memory allocation
[p1D,p2D] = deal(struct('X',[],'Y',[]));

% case is the 1D apparatus
p1D.X = struct('A',19,'s',2.0,'l',140,'g',0.65,'t',pi);
p1D.Y = struct('A',18,'s',1.6,'l',104,'g',1.26,'t',-pi/2);

% case is the 1D apparatus
p2D.X = struct('A',15,'s',1.6,'l',90,'g',1.00,'t',pi);
p2D.Y = struct('A',16,'s',1.5,'l',90,'g',1.10,'t',-pi/2);    

% --- initialises the tracking parameter struct
function trkP = initTrackPara()

% initialises the tracking parameter struct
trkP = struct('nFrmS',50,'calcPhi',false,'rot90',false,'PC',[],'Mac',[]);

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

% --- initialises the serial devices names
function sDev = initSerialDeviceNames()

% sets the serial device names
sDev = {'STMicroelectronics STLink Virtual COM Port'};

