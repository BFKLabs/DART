% --- reduces down the combined solution files such that the apparatus 
function snTot = reduceExptSolnFiles(snTot,indNw,appName)

% sets the new indices (if not provided)
if nargin < 2
    indNw = num2cell(1:length(snTot.Px))'; 
    indNw(cellfun(@isempty,snTot.Px)) = {[]};
end
if nargin < 3; appName = snTot.iMov.pInfo.gName; end

if isfield(snTot,'iMov')
    % determines if the orientation angles were calculated
    if isfield(snTot.iMov,'calcPhi')
        calcPhi = snTot.iMov.calcPhi;
    else
        calcPhi = false;
    end
    
else
    % otherwise, flag neither difference sub-region counts or orientation
    % angles were used for this experiment
    calcPhi = false;
end

% initialisations
nApp = length(indNw);
ok = false(nApp,1);

% memory allocation
[Px,Py,Name,flyok] = deal(cell(nApp,1));
if ~isempty(snTot.pMapPx); pMapX = repmat(snTot.pMapPx(1),nApp,1); end
if ~isempty(snTot.pMapPy); pMapY = repmat(snTot.pMapPy(1),nApp,1); end
if calcPhi; [Phi,AxR] = deal(cell(nApp,1)); end

% reduces down the arrays
for i = 1:nApp
    % sets apparatus name
    Name{i} = appName{i};
    
    % sets the indices for the current apparatus
    if ~isempty(indNw{i})
        % sets the current indices
        ii = indNw{i}(:)';
        
        % sets the fly x-locations
        Px{i} = cell2mat(arr2vec(snTot.Px(ii))');
        if ~isempty(snTot.Py)
            % sets the fly y-locations (if they exist)
            Py{i} = cell2mat(arr2vec(snTot.Py(ii))');
        end
        
        % sets the orientation angles/aspect ratios
        if calcPhi
            Phi{i} = cell2mat(arr2vec(snTot.Phi(ii))');
            AxR{i} = cell2mat(arr2vec(snTot.AxR(ii))');
        end

        % reduces down the x-location scale values
        if ~isempty(snTot.pMapPx)                
            pMapX(i).xMin = cell2mat(field2cell(snTot.pMapPx(ii),'xMin'));
            pMapX(i).xMax = cell2mat(field2cell(snTot.pMapPx(ii),'xMax'));
        end
            
        % reduces down the y-location scale values
        if ~isempty(snTot.pMapPy)
            if (i == 1); pMapY = repmat(snTot.pMapPy(1),nApp,1); end
            pMapY(i).xMin = cell2mat(field2cell(snTot.pMapPy(ii),'xMin'));
            pMapY(i).xMax = cell2mat(field2cell(snTot.pMapPy(ii),'xMax'));        
        end

        % reduces down the sub-region acceptance flags
        if iscell(snTot.iMov.flyok)
            a = snTot.iMov.flyok{ii};
        else
            a = snTot.iMov.flyok(:,ii);
        end
            
        % sets the fly acceptance flags        
        [flyok{i},ok(i)] = deal(a(:),true);     
        [pMapX(i).nFrame,pMapY(i).nFrame] = deal(size(Px{i},1));
    else
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
[snTot.iMov.pInfo.gName,snTot.Px,snTot.iMov.ok] = deal(Name,Px,ok);

% % sets the y-location data (if required)
% if ~keepNum
%     snTot.iMov.flyok = flyok; 
% else
%     fokTmp = combineNumericCells(flyok(:)');
%     fokTmp(isnan(fokTmp)) = 0;
%     snTot.iMov.flyok = logical(fokTmp);
% end

% groups the acceptance flags (if not already grouped)
if ~iscell(snTot.iMov.flyok)
    fok0 = groupAcceptFlags(snTot,1);    
    snTot.iMov.flyok = cellfun(@(x)...
                            (cell2mat(arr2vec(fok0(x)))),indNw,'un',0);                        
end

% regroups the ID flags
cID0 = snTot.cID;
snTot.cID = cellfun(@(x)(cell2mat(arr2vec(cID0(x)))),indNw,'un',0);

% sets the coordinates/mapping arrays (if required)
if ~isempty(snTot.Py); snTot.Py = Py; end
if ~isempty(snTot.pMapPx); snTot.pMapPx = pMapX; end
if ~isempty(snTot.pMapPy); snTot.pMapPy = pMapY; end
if calcPhi; [snTot.Phi,snTot.AxR] = deal(Phi,AxR); end