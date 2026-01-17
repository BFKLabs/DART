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
[Px,Py,Name,flyok] = deal(cell(nApp,1));
snTot.Py = [];

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

% sets the y-coordinate values (if required)
if isfield(snTot,'Py') && ~isempty(snTot.Py)
    snTot.Py = Py; 
end

% --- retrieves the data values from the array Y with indices, cID
function Ygrp = getDataValues(Y,cID)

for i = 1:length(cID)
    if i == 1
        % retrieves the data values
        Y0 = getRegionDataValues(Y,cID{i});
        
        % memory allocation
        Ygrp = NaN(length(Y0),length(cID));
        Ygrp(:,i) = Y0;
        clear Y0
    else
        % case is the other regions
        Ygrp(:,i) = getRegionDataValues(Y,cID{i});        
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
