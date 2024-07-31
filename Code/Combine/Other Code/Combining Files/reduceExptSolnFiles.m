% --- reduces down the combined solution files such that the apparatus 
function snTot = reduceExptSolnFiles(snTot,indNw,appName)

% sets the new indices (if not provided)
if ~exist('indNw','var')
    indNw = num2cell(1:length(snTot.Px))'; 
    indNw(cellfun('isempty',snTot.Px)) = {[]};
end

% sets the default region names
if ~exist('appName','var')
    appName = snTot.iMov.pInfo.gName; 
end

% initialisations
calcPhi = false;
hasPx = isfield(snTot,'Px');
nApp = length(indNw);
ok = false(nApp,1);

% sets the solution struct fields
cID0 = setupFlyLocID(snTot.iMov);

% determines if the orientation angles were calculated
if isfield(snTot,'iMov')
    if isfield(snTot.iMov,'calcPhi')
        calcPhi = snTot.iMov.calcPhi;
    end
end

% memory allocation
[Px,Py,Name,flyok,cID] = deal(cell(nApp,1));
if isfield(snTot,'pMapPx')
    if ~isempty(snTot.pMapPx); pMapX = repmat(snTot.pMapPx(1),nApp,1); end
    if ~isempty(snTot.pMapPy); pMapY = repmat(snTot.pMapPy(1),nApp,1); end
end

% memory allocation for the orientation angles
if calcPhi; [Phi,AxR] = deal(cell(nApp,1)); end

% reduces down the arrays
for i = 1:nApp
    % sets apparatus name
    Name{i} = appName{i};
    
    % sets the indices for the current apparatus
    if ~isempty(indNw{i})
        % sets the current indices
        for iNw = indNw{i}(:)'
            % updates the configuration ID array            
            cID{i} = [cID{i};cID0{iNw}];          
            indD = getDataArrayIndices(snTot.iMov,cID0{iNw});            
            
            if hasPx           
                % sets the fly x-locations
                Px{i} = [Px{i},getDataValues(snTot.Px,indD)];
                
                % sets the fly y-locations (if they exist)
                if ~isempty(snTot.Py)
                    Py{i} = [Py{i},getDataValues(snTot.Py,indD)];
                end
                
                % sets the orientation angles/aspect ratios (if they exist)
                if calcPhi
                    Phi{i} = [Phi{i},getDataValues(snTot.Phi,indD)];
                    AxR{i} = [AxR{i},getDataValues(snTot.AxR,indD)];
                end
                
                % reduces down the x-location scale values
                if isfield(snTot,'pMapPx')
                    if ~isempty(snTot.pMapPx)
                        pMapX(i).xMin = ...
                            cell2mat(field2cell(snTot.pMapPx(ii),'xMin'));
                        pMapX(i).xMax = ...
                            cell2mat(field2cell(snTot.pMapPx(ii),'xMax'));
                    end

                    % reduces down the y-location scale values
                    if ~isempty(snTot.pMapPy)
                        if (i == 1)
                            pMapY = repmat(snTot.pMapPy(1),nApp,1); 
                        end
                        
                        pMapY(i).xMin = ...
                            cell2mat(field2cell(snTot.pMapPy(iNw),'xMin'));
                        pMapY(i).xMax = ...
                            cell2mat(field2cell(snTot.pMapPy(iNw),'xMax'));        
                    end
                end
            end

            % reduces down the sub-region acceptance flags
            if iscell(snTot.iMov.flyok)
                flyokNw = ...
                    getDataValues(snTot.iMov.flyok(iNw),indD);
                flyok{i} = [flyok{i};flyokNw(:)];
            else
                szOK = size(snTot.iMov.flyok);
                ii = cellfun(@(x)(sub2ind(szOK,x(1),x(2))),indD);
                flyok{i} = [flyok{i};snTot.iMov.flyok(ii)];
            end
        end
            
        % sets the fly acceptance flags        
        ok(i) = true;        
        if hasPx
            [pMapX(i).nFrame,pMapY(i).nFrame] = deal(size(Px{i},1));
        end
        
    elseif isfield(snTot,'pMapPx')
        % if the apparatus is empty, then set the flags to empty/false
        [flyok{i},ok(i)] = deal([],false);
        [pMapX(i).xMin,pMapX(i).xMax] = deal([]);
        [pMapX(i).Wmov,pMapX(i).nRep,pMapX(i).nFly] = deal(NaN);
        [pMapX(i).pScale,pMapX(i).nFrame] = deal(NaN);
        
        % removes the y-position pMap struct (if setting Y-values)
        if ~isempty(snTot.pMapPy)
            [pMapY(i).xMin,pMapY(i).xMax] = deal([]);
        end
    end
end

% % reduces the sub-region data struct
% if isfield(snTot,'iMov')    
%     snTot = reduceRegionInfo(snTot);
% end
    
% sets the solution struct fields
snTot.cID = cID;
snTot.iMov.ok = logical(ok);
snTot.iMov.flyok = cellfun(@(x)(logical(x)),flyok,'un',0);
[snTot.iMov.pInfo.gName,snTot.Px] = deal(Name,Px);

% sets the y-coordinate values (if required)
if isfield(snTot,'Py') && ~isempty(snTot.Py)
    snTot.Py = Py; 
end

% sets the orientation/axis ratio values (if required)
if calcPhi
    [snTot.Phi,snTot.AxR] = deal(Phi,AxR); 
end

% sets the coordinates/mapping arrays (if required)
if isfield(snTot,'pMapPx')
    if ~isempty(snTot.pMapPx); snTot.pMapPx = pMapX; end
    if ~isempty(snTot.pMapPy); snTot.pMapPy = pMapY; end
end

% --- retr
function Ygrp = getDataValues(Y,cID)

% retrieves the regional data values
Y0 = cellfun(@(x)(getRegionDataValues(Y,x)),cID,'un',0);

% clears the extraneous variables
clear Y cID
pause(0.05);

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

if iMov.is2D
    indD = num2cell(cID(:,1:2),2);
else
    iApp = (cID(:,1)-1)*iMov.pInfo.nCol + cID(:,2);
    indD = num2cell([cID(:,end),iApp],2);
end
