% --- retrieves the phase object information
function phInfo = getPhaseObjInfo(phObj)

% retrieves the phase detection information
phInfo = struct('iFrmF',[],'DimgF',[],'Iref',[],'pOfs',[],'hmFilt',[],...
                'hasT',phObj.hasT,'hasF',phObj.hasF,'iFrm0',phObj.iFrm0,...
                'Dimg0',phObj.Dimg0,'iR0',[],'iC0',[],'Iref0',[]);
            
% sets the other information fields
phInfo.pOfs = phObj.pOfs;
phInfo.hmFilt = phObj.hmFilt;
phInfo.iFrmF = find(phObj.Dimg(:,1));
phInfo.DimgF = full(phObj.Dimg(phInfo.iFrmF,:));
[phInfo.Iref,phInfo.Iref0] = deal(phObj.IrefF);

% sets the initial reference images and row/column indices
phInfo.iR0 = phObj.iR0;
phInfo.iC0 = phObj.iC0;