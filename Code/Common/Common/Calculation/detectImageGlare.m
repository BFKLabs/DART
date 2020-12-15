% --- determines from a stack of images if reflection glare is present in
%     any of the sub-regions
function iMov = detectImageGlare(iMov,sImg,varargin)

% global variables
global mainProgDir isBatch is2D

% loads the reflection detection parameters from the program parameter file
A = load(fullfile(mainProgDir,'Para Files','ProgPara.mat'));
if (is2D)
    % case is a 2D apparatus
    if (~isfield(A,'rf2D'))
        return
    else
        svm = A.rf2D;
    end
else
    % case is a 1D apparatus
    if (~isfield(A,'rf1D'))
        return
    else    
        svm = A.rf1D;
    end
end

% creates a loadbar
if (nargin == 2)
    h = ProgressLoadbar('Detecting Image Reflection Glare...');
end

% parameters and array indexing
[nApp,nPhase,nTube] = deal(length(iMov.iR),length(sImg),getFlyCount(iMov,1));
[sGlare,pGlare] = deal(false(nApp,1));
pRegion = false(max(nTube),nApp);

% sets the frame count for each phase
[nFrm,sz] = deal(zeros(nPhase,1),[max(nTube),nApp]); 
for i = 1:length(nFrm); nFrm(i) = length(sImg(i).iFrm); end

% determines the low-variance phases
ii = find(iMov.vPhase == 1)';

% calculates the number of rows/sub-region image that exceeds threhold
if (is2D)    
    % memory allocation
    [dILmx,dILmn] = deal(zeros([sz,length(ii)]));
    
    % calculates the metrics for each phase
    for i = 1:length(ii)
        [dILmx(:,:,i),dILmn(:,:,i)] = calcPhaseStats2D(iMov,sImg(ii(i)).I);    
    end
    
    % classifies the reflection statistics    
    pRegion = (classReflectStats(svm,dILmx,dILmn) == 2);
    pRegion(~iMov.flyok) = false;
else
    % memory allocation      
    b = zeros(iMov.nRow,iMov.nCol,length(ii)); 
    [s,mu,dI] = deal(zeros(length(ii),nApp));
    
    % calculates the metrics for each phase
    for i = 1:length(ii)
        % calculates the metrics for each phase
        [s(i,:),mu(i,:),dI(i,:)] = calcPhaseStats1D(iMov,sImg(ii(i)).I);    
    end
    
    % classifies the reflection statistics
    a = classReflectStats(svm,s,mu,dI);            
    for i = 1:size(b,3)
        c = mode(reshape(a(i,:),iMov.nCol,iMov.nRow)',1);
        b(:,:,i) = repmat(c,iMov.nRow,1);
    end
    
    % determines the overall maximum over each phase
    bT = reshape(max(b,[],3)',[nApp,1]);
    bT(~iMov.ok) = NaN;
    [sGlare,pGlare] = deal((bT == 3),(bT == 2));
end

% closes the loadbar
if (nargin == 2)
    delete(h); 
    pause(0.05); 
end

% if there are any glare/anomalous regions, then reset the flags
if ((any(sGlare) || any(pGlare) || (any(pRegion(:)))) && (~isBatch))
    iMov = RegionAnomaly(iMov,sGlare,pGlare,pRegion);
    
    % prompts the user if they wish to continue
    mStr = sprintf(['Note that if you wish to change your selection, the ',...
                    'acceptance/rejection flags can be reset from the ',...
                    '"Fly Accept/Reject" menu item.']);
    waitfor(msgbox(mStr,'Resetting Acceptance/Rejection Flags','modal'))    
end
