function [iMov,trkObj] = detGridRegions(hFig)

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
hProg.Update(1,'Determining Video Phases...',0.25);

% creates the video phase object
if isempty(phObj)
    updateObj = true;
    phObj = VideoPhase(iData,iMov,hProg,2);
    phObj.runPhaseDetect();
end

% updates the progressbar
if hProg.Update(2,'Phase Detection Complete!',1)
    % if the user cancelled, then exit
    iMov = [];
    return
end

% updates the sub-image data struct with the phase information
iMov.iPhase = phObj.iPhase;
iMov.vPhase = phObj.vPhase;      
iMov.ImnF = phObj.ImnF;

% ---------------------------------- %
% --- INITIAL DETECTION ESTIMATE --- %
% ---------------------------------- %

% runs the phase detection solver            
hProg.Update(1,'Determining Video Phases...',0.50);

% determines the longest low-variance phase
indPh = [phObj.vPhase,diff(phObj.iPhase,[],2)];
[~,iSort] = sortrows(indPh,[1,2],{'ascend' 'descend'});
iMx = iSort(1);

% updates the sub-image data struct with the phase information
iMovT = iMov;
iMovT.iPhase = iMovT.iPhase(iMx,:);
iMovT.vPhase = iMovT.vPhase(iMx);      
iMovT.ImnF = iMovT.ImnF(iMx);

% creates the tracking object
trkObj = SingleTrackInit(iData);
trkObj.isAutoDetect = true;

% runs the initial estimate
trkObj.calcInitEstimate(iMovT,hProg)
if ~trkObj.calcOK
    % if the user cancelled, then exit
    iMov = [];
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
    [W,H] = deal(diff(xT{i})+1,diff(yT{i}([1,end]))+1);
    [dyT,dxT] = deal(yT{i}-yT{i}(1),xT{i}-xT{i}(1));
    
    % sets the region outlne coordinate vector
    pOfs = [trkObj.iCG{i}(1),trkObj.iRG{i}(1)]-1;
    iMov.pos{i} = [pOfs+[xT{i}(1),yT{i}(1)]-1,W,H];
    
    % tube-region x/y coordinate arrays
    iMov.xTube{i} = dxT;
    iMov.yTube{i} = [dyT(1:end-1),dyT(2:end)];
    
    % sets the region row/column indices    
    iMov.iR{i} = max(1,ceil(yT{i}(1))):min(frmSz(1),floor(yT{i}(end)));
    iMov.iC{i} = max(1,ceil(xT{i}(1))):min(frmSz(2),floor(xT{i}(end)));
    
    % sets the sub-region row/column indices
    iMov.iCT{i} = 1:length(iMov.iC{i});
    iMov.iRT{i} = cellfun(@(x)(max(1,ceil(x(1))):min(iMov.iR{i}(end),...
                floor(x(2)))),num2cell(iMov.yTube{i},2),'un',0);     
end
    
% ------------------------------- %
% --- HOUSE-KEEPING EXERCISES --- %
% ------------------------------- %

% updates the phase detection object if required
if updateObj
    set(hFig,'phObj',phObj)
end

% closes the progressbar
hProg.closeProgBar();