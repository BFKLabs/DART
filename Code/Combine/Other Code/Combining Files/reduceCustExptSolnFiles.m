function snTot = reduceCustExptSolnFiles(snTot,appName)

% sets the default region names
if ~exist('appName','var')
    appName = snTot.iMov.pInfo.gName; 
end

% sets the solution struct fields
cID = setupFlyLocID(snTot.iMov);
nApp = size(cID,1);
ok = ~cellfun('isempty',cID);

% memory allocation
[Px,Name,flyok] = deal(cell(nApp,1));

% reduces down the arrays
for i = 1:nApp
    % sets apparatus name
    Name{i} = appName{i};    
    if ~isempty(cID{i})
        % retrieves the data array indices
        indD = getDataArrayIndices(snTot.iMov,cID{i});
        
        % sets the fly x-locations
        Px{i} = [Px{i},getDataValues(snTot.Px,indD)]; 
        
        % reduces down the sub-region acceptance flags
        szOK = size(snTot.iMov.flyok);
        ii = cellfun(@(x)(sub2ind(szOK,x(1),x(2))),indD);
        flyok{i} = [flyok{i};snTot.iMov.flyok(ii)];
    end
end

% sets the solution struct fields
snTot.cID = cID;
snTot.iMov.ok = logical(ok);
snTot.iMov.flyok = cellfun(@(x)(logical(x)),flyok,'un',0);
[snTot.iMov.pInfo.gName,snTot.Px] = deal(Name,Px);

% --- retrieves the data values from the array Y with indices, cID
function Ygrp = getDataValues(Y,cID)

% retrieves the regional data values
Y0 = cellfun(@(x)(getRegionDataValues(Y,x)),cID,'un',0);

% clears the extraneous variables
clear Y cID

try
    Ygrp = cell2mat(Y0(:)');
catch
    Ygrp = NaN(length(Y0{1}),length(Y0));
    for i = 1:length(Y0)
        Ygrp(:,i) = Y0{i};
        Y0{i} = [];
    end
end

%
function Y0 = getRegionDataValues(Y,cID)

if isempty(Y{cID(2)})
    Y0 = [];
else
    Y0 = Y{cID(2)}(:,cID(1));
end

%
function indD = getDataArrayIndices(iMov,cID)

iApp = (cID(:,1)-1)*iMov.pInfo.nCol + cID(:,2);
indD = num2cell([cID(:,end),iApp],2);
