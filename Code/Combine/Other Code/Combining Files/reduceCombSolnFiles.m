% --- reduces down the combined solution files such that the apparatus 
function snTot = reduceCombSolnFiles(snTot,indNw,appName,keepNum)

% sets the new indices (if not provided)
if nargin < 2; indNw = num2cell(1:length(snTot.Px))'; end
if nargin < 3; appName = snTot.appPara.Name; end
if nargin < 4; keepNum = false; end

if isfield(snTot,'iMov')
    % determines if differing sub-region counts were used
    if isfield(snTot.iMov,'dTube')
        dTube = snTot.iMov.dTube;
        if dTube
            b = snTot.iMov.nTubeR';
            nTubeR0 = b(:); 
        end              
    else
        dTube = false;
    end
    
    % determines if the orientation angles were calculated
    if isfield(snTot.iMov,'calcPhi')
        calcPhi = snTot.iMov.calcPhi;
    else
        calcPhi = false;
    end
    
else
    % otherwise, flag neither difference sub-region counts or orientation
    % angles were used for this experiment
    [dTube,calcPhi] = deal(false);
end

% initialisations
[nApp,indL] = deal(length(indNw),cell2mat(indNw));
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
        ii = reshape(indNw{i},length(indNw{i}),1);
        
        % sets the fly x-locations
        Px{i} = cell2mat(snTot.Px(ii)');
        if ~isempty(snTot.Py)
            % sets the fly y-locations (if they exist)
            Py{i} = cell2mat(snTot.Py(ii)');
        end
        
        % sets the orientation angles/aspect ratios
        if calcPhi
            Phi{i} = cell2mat(snTot.Phi(ii)');
            AxR{i} = cell2mat(snTot.AxR(ii)');
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
        if dTube
            % case is there a differing sub-region counts
            snTot.iMov.nTubeR(i) = sum(nTubeR0(ii));
            a = cell2mat(cellfun(@(x,y)(x(1:y)),num2cell(...
                snTot.appPara.flyok(:,ii),1)',num2cell(nTubeR0(ii)),'un',0));
        else
            % case is sub-region counts are equal
            if iscell(snTot.appPara.flyok)
                a = snTot.appPara.flyok{ii};
            else
                a = snTot.appPara.flyok(:,ii);
            end
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
        if (~isempty(snTot.pMapPy))
            [pMapY(i).xMin,pMapY(i).xMax] = deal([]);
        end
    end
end

% resets the sub-region data struct
if isfield(snTot,'iMov')
    % reduces the sub-region data struct
    snTot = reduceSubRegionStruct(snTot);        
    if dTube
        snTot.iMov.nTubeR = snTot.iMov.nTubeR(indL); 
    else
        [snTot.iMov.dTube,snTot.iMov.nTubeR] = deal(false,[]);
    end
end
    
% sets the solution struct fields
[snTot.appPara.Name,snTot.Px,snTot.appPara.ok] = deal(Name,Px,ok);
if (isfield(snTot.appPara,'aInd'))
    if length(snTot.appPara.aInd) < nApp
        snTot.appPara.aInd = (indL)';
    else
        snTot.appPara.aInd = snTot.appPara.aInd(indL);
    end
end

% sets the y-location data (if required)
if ~keepNum
    snTot.appPara.flyok = flyok; 
else
    fokTmp = combineNumericCells(flyok(:)');
    fokTmp(isnan(fokTmp)) = 0;
    snTot.appPara.flyok = logical(fokTmp);
end

% sets the coordinates/mapping arrays (if required)
if ~isempty(snTot.Py); snTot.Py = Py; end
if ~isempty(snTot.pMapPx); snTot.pMapPx = pMapX; end
if ~isempty(snTot.pMapPy); snTot.pMapPy = pMapY; end
if calcPhi; [snTot.Phi,snTot.AxR] = deal(Phi,AxR); end

% --- reduces the sub-region data struct (based on the position values)
function snTot = reduceSubRegionStruct(snTot)

% initialisations
[iMov,Px,Py] = deal(snTot.iMov,snTot.Px,snTot.Py);

% sets the scale factor
sFac = field2cell(snTot.sgP,'sFac',1);
if length(sFac) > 1
    ii = sFac == 1;
    if all(ii)
        sFac = 1;
    else
        sFac = median(sFac(~ii));        
    end
end

% check to see if the position data array matches the sub-region indices
if (length(Px) ~= length(iMov.iR)) && is2DCheck(snTot.iMov)
    % if not, then reduce the regions so they match

    % calculates the mean x coordinates and column extrema
    PmnX = cellfun(@(x)(nanmean(x,1)/sFac),Px,'un',0);  
    PmnX = cellfun(@(x)(x(~isnan(x))),PmnX,'un',0);    
    indC = cell2mat(cellfun(@(x)(x([1 end])),iMov.iC(:),'un',0));           
        
    % calculates the mean y coordinates and row extrema
    PmnY = cellfun(@(x)(nanmean(x,1)/sFac),Py,'un',0);
    PmnY = cellfun(@(x)(x(~isnan(x))),PmnY,'un',0); 
    indR = cell2mat(cellfun(@(x)(x([1 end])),iMov.iR(:),'un',0));

    % determines the matching regions (based on the position values)
    ii = cell2cell(cellfun(@(x,y)(unique(cellfun(@(xx,yy)...
       (find((xx>=indC(:,1))&(xx<=indC(:,2))&(yy>=indR(:,1))&...
       (yy<=indR(:,2)))),num2cell(x),num2cell(y)))),PmnX,PmnY,'un',0));        
   
    % checks to see if the unique rows/columns matches that in the
    % sub-region data struct
    if length(ii) ~= length(iMov.iR)      
        % reduces the sub-fields   
        [iMov.iR,iMov.iC] = deal(iMov.iR(ii),iMov.iC(ii));
        [iMov.iRT,iMov.iCT] = deal(iMov.iRT(ii),iMov.iCT(ii));
        [iMov.pos,iMov.posO] = deal(iMov.pos(ii),iMov.posO(ii));
        [iMov.xTube,iMov.yTube] = deal(iMov.xTube(ii),iMov.yTube(ii));
        [iMov.Status,iMov.pStats] = deal(iMov.Status(ii),iMov.pStats(ii));
        [iMov.ok,iMov.flyok] = deal(iMov.ok(ii),iMov.flyok(:,ii));

        % reduces the background image arrays
        for i = 1:length(iMov.Ibg)
            iMov.Ibg{i} = iMov.Ibg{i}(ii);
        end

        % resets the sub-region data struct
        snTot.iMov = iMov;
    end
end