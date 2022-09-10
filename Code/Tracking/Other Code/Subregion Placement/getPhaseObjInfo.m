% --- retrieves the phase object information
function phInfo = getPhaseObjInfo(phObj)

% retrieves the phase detection information
phInfo = struct('iFrmF',[],'DimgF',[],'Iref',[],'pOfs',[],'hmFilt',[],...
                'hasT',phObj.hasT,'hasF',phObj.hasF,'iFrm0',phObj.iFrm0,...
                'Dimg0',phObj.Dimg0,'iR0',[],'iC0',[],'Iref0',[],'sFlag',0);
            
% sets the frame indices
if iscell(phObj.Dimg)
    phInfo.iFrmF = find(phObj.Dimg{1}(:,1));
else
    phInfo.iFrmF = find(phObj.Dimg(:,1));
end
            
% sets the other information fields
phInfo.pOfs = phObj.pOfs;
phInfo.sFlag = phObj.sFlag;
phInfo.hmFilt = phObj.hmFilt;
phInfo.DimgF = phObj.getDimg(phInfo.iFrmF);
[phInfo.Iref,phInfo.Iref0] = deal(phObj.IrefF);

% sets the initial reference images and row/column indices
phInfo.iR0 = phObj.iR0;
phInfo.iC0 = phObj.iC0;