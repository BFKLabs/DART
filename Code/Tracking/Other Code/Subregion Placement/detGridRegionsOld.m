function [iMov,trkObj] = detGridRegionsOld(hFig)

% global variables
global isCalib

% progressbar setup
wStr = {'Phase Detection','Region Segmentation','Sub-Region Segmentation'};
hProg = ProgBar(wStr,'1D Automatic Detection');

% ----------------------- %
% --- PHASE DETECTION --- %
% ----------------------- %

% field retrieval
updateObj = false;
phObj = get(hFig,'phObj');
[iMov,iData] = deal(get(hFig,'iMov'),get(hFig.hGUI.output,'iData'));

% runs the phase detection solver    
if isCalib
    % updates the sub-image data struct with the phase information
    phObj = struct('iPhase',[1,1],'vPhase',1);
else
    % creates the video phase object
    hProg.Update(1,'Determining Video Phases...',0.25);
    if isempty(phObj)
        updateObj = true;
        phObj = VideoPhase(iData,iMov,hProg,1,true);
        phObj.runPhaseDetect();  
    end

    % updates the progressbar
    if hProg.Update(2,'Phase Detection Complete!',1)
        % if the user cancelled, then exit
        [iMov,trkObj] = deal([]);
        return
    end

    % updates the sub-image data struct with the phase information
    iMov.phInfo = getPhaseObjInfo(phObj);
end

% sets the phase indices/classification flags
iMov.iPhase = phObj.iPhase;
iMov.vPhase = phObj.vPhase;

% ---------------------------------- %
% --- INITIAL DETECTION ESTIMATE --- %
% ---------------------------------- %

% runs the phase detection solver            
hProg.Update(1,'Estimating Grid Setup...',0.50);

% determines the longest low-variance phase
indPh = [phObj.vPhase,diff(phObj.iPhase,[],2)];
[~,iSort] = sortrows(indPh,[1,2],{'ascend' 'descend'});
iMx = iSort(1);

% updates the sub-image data struct with the phase information
iMovT = iMov;
iMovT.iPhase = iMovT.iPhase(iMx,:);
iMovT.vPhase = iMovT.vPhase(iMx);

% creates the tracking object
trkObj = SingleTrackInitAuto(iData);

% runs the initial estimate
trkObj.calcInitEstimateAuto(iMovT,hProg)
if ~trkObj.calcOK
    % if the user cancelled, then exit
    [iMov,trkObj] = deal([]);
    return
end

% ------------------------------ %
% --- SUB-REGION FIELD SETUP --- %
% ------------------------------ %

% retrieves the current image dimensions
frmSz = getCurrentImageDim();
[xT,yT] = deal(trkObj.xTube,trkObj.yTube);

% sets the parameters for each of the sub-regions
for i = 1:length(iMov.pos)
    % sets the region position coordinates
    if ~isempty(yT{i})
        %
        pOfsG = [trkObj.iCG{i}(1),trkObj.iRG{i}(1)]-1;
        [xT{i},yT{i},dpOfs] = calcTubeRegionOffset(xT{i},yT{i},pOfsG,frmSz);
        
        % calculates the dimensions/offsets for the tube regions
        [W,H] = deal(diff(xT{i})+1,diff(yT{i}([1,end]))+1);
        [dyT,dxT] = deal(yT{i}-yT{i}(1),xT{i}-xT{i}(1));

        % sets the region outlne coordinate vector        
        pos0 = [pOfsG+dpOfs,W,H];
        iMov.pos{i} = fitRegionFrame(pos0,frmSz);

        % tube-region x/y coordinate arrays
        iMov.xTube{i} = dxT;
        iMov.yTube{i} = [dyT(1:end-1),dyT(2:end)];

        % sets the region row/column indices   
        [x0,y0] = deal(iMov.pos{i}(1),iMov.pos{i}(2));
        iRnw = ceil(y0+dyT(1)):floor(y0+dyT(end));
        iCnw = ceil(x0+dxT(1)):floor(x0+dxT(end)); 
        
        % sets the feasible row/column indices
        isFR = (iRnw>0)&(iRnw<=frmSz(1));
        isFC = (iCnw>0)&(iCnw<=frmSz(2));
        
        % resets the feasible row/column indices
        iMov.iR{i} = iRnw(isFR);
        iMov.iC{i} = iCnw(isFC);

        % sets the sub-region row/column indices
        iMov.iCT{i} = 1:length(iMov.iC{i});        
        iMov.iRT{i} = cellfun(@(x)(ceil(x(1)):floor(x(2))),...
                                num2cell(iMov.yTube{i},2),'un',0);     
                
        diRT = [max(0,-y0),max(0,(yT{i}(end)+y0)-frmSz(1))];
        iMov.iRT{i}{1} = iMov.iRT{i}{1}((1+diRT(1)):end);
        iMov.iRT{i}{end} = iMov.iRT{i}{end}(1:(end-diRT(2)));
        
        % reduces downs the filter/reference images (if they exist)
        if ~isempty(iMov.phInfo.Iref{i})
            iMov = reducePhaseInfoImages(iMov,i);
        end
    end
end

% sets the outer region dimension vectors
pPos = iMov.pos;
pPos(~iMov.ok) = iMov.posO(~iMov.ok);

% resets the outer region coordinates
for i = 2:iMov.pInfo.nRow    
    for j = 1:iMov.pInfo.nCol
        % sets the lower/upper region indices
        iLo = (i-2)*iMov.pInfo.nCol + j;
        iHi = (i-1)*iMov.pInfo.nCol + j;
        
        % calculates the vertical location separating the regions
        yHL = 0.5*(sum(pPos{iLo}([2 4])) + sum(pPos{iHi}(2)));
        yB = sum(iMov.posO{iHi}([2,4]));
               
        % resets the outer region coordinates        
        iMov.posO{iHi}(2) = yHL;
        iMov.posO{iHi}(4) = yB - yHL;
        iMov.posO{iLo}(4) = yHL - iMov.posO{iLo}(2);        
    end
end
    
% re-initialises the status flags
nTube = getSRCountVec(iMov)';
iMov.Status = arrayfun(@(x)(NaN(x,1)),arr2vec(nTube),'un',0);

% ------------------------------- %
% --- HOUSE-KEEPING EXERCISES --- %
% ------------------------------- %

% updates the phase detection object if required
if updateObj
    % clears the phase object fields
    [phObj.Img0,phObj.ILF] = deal([]);
    
    % updates the phase object field
    set(hFig,'phObj',phObj)
end

% closes the progressbar
hProg.closeProgBar();

% --- 
function [xTL,yTL,pOfsL] = calcTubeRegionOffset(xTL,yTL,pOfsG,frmSz)

% calculates the regions with respect to the global image frame
[xTG0,yTG0] = deal(xTL+pOfsG(1),yTL+pOfsG(2));

% ensures the horizontal locations are within frame
xTG = max(min(xTG0,frmSz(2)),0);
yTG = max(min(yTG0,frmSz(1)),0);

%
dyTG = yTG0 - yTG;
if any(abs(dyTG) > 0)
    a = 1;
end

%
dxTG = xTG0 - xTG;
if any(abs(dxTG) > 0)
    a = 1;
end

% calculates the tube-region offsets
pOfsL = [xTL(1),yTL(1)];
[xTL,yTL] = deal(xTL-pOfsL(1),yTL-pOfsL(2));