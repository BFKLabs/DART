% --- initialises the sub-movie data struct
function iMov = initMovStruct(iData)

% determines if the tracking parameters have been set
A = load(getParaFileName('ProgPara.mat'));
if ~isfield(A,'trkP')
    % track parameters have not been set, so initialise
    trkP = initTrackPara();
else
    % track parameters have been set
    trkP = A.trkP;
end

% Sub-Movie Data Struct
iMov = struct('pos',[1 1 1 1],'posG',[],'Ibg',[],'ddD',[],...
              'nRow',[],'nCol',[],'nPath',trkP.nPath,'hasRGB',false,...
              'useRGB',false,'nTube',[],'nTubeR',[],'nFly',[],'nFlyR',[],...
              'iR',[],'iC',[],'iRT',[],'iCT',[],'xTube',[],'yTube',[],...
              'sgP',[],'Status',[],'tempName',[],'autoP',[],'bgP',[],...
              'isSet',false,'ok',true,'tempSet',false,'isOpt',false,...
              'useRot',false,'rotPhi',90,'calcPhi',false,'sepCol',false,...
              'vGrp',[],'sRate',5,'nDS',1,'mShape','Circ','phInfo',[]);

% sets the parameter sub-struct fields
iMov.bgP = DetectPara.initDetectParaStruct('All');        
iMov.sgP = iData.sgP;