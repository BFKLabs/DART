% --- retrieves the background estimate sub-image stacks --- %
function [iMov,sImgS,Img] = getEstimateImageStack(iData,iMov,h,iOfs)

% sets the default input arguments
if ~exist('iOfs','var'); iOfs = 0; end

% parameters
outImgStack = nargout > 1;
nStep = 2 + outImgStack;

% initialisations
delProg = false;
if isfield(iMov,'useGray')
    useGray0 = iMov.useGray;
else
    useGray0 = true;
end

% creates a waitbar figure (if one is not created)
if ~exist('h','var')
    delProg = true;
    wStr = {'Current Progress','Region Progress'};
    h = ProgBar(wStr,'Image Estimation Stack');
end

% only grayscale is necessary for phase detection
iMov.useGray = true;

% creates the video phase class object
if detMltTrkStatus(iMov)
    % case is multi-tracking
    phObj = VideoPhaseMulti(iData,iMov,h,1+iOfs);
    phObj.nPhMax = 100;
    phObj.runPhaseDetect();
else
    % case is single-tracking
    phObj = VideoPhase(iData,iMov,h,1+iOfs);
    phObj.runPhaseDetect();
end

% updates the sub-image data struct with the phase information
phObj.iMov.iPhase = phObj.iPhase;
phObj.iMov.vPhase = phObj.vPhase;
phObj.iMov.phInfo = getPhaseObjInfo(phObj);

% reduces downs the filter/reference images (if they exist)
for i = 1:length(phObj.iMov.iR)
    if ~isempty(phObj.iMov.phInfo.Iref{i})
        phObj.iMov = reducePhaseInfoImages(phObj.iMov,i);
    end
end

% updates the sub-image data struct with the phase information
iMov = phObj.iMov;
iMov.useGray = useGray0;

% if using colour images, then determine the best channel indices for each
% of the phases
if ~iMov.useGray
    %    
    phObj.iMov = iMov;
    ImgF = phObj.readPhaseImgStack(iMov.iPhase(:,1));
    iMov.iColPh = detPhaseChannelIndices(iMov,ImgF);
end

% reads the frames from the images
if outImgStack
    h.Update(1+iOfs,'Reading Phase Frames...',2/nStep);
    [Img,sImgS] = phObj.readPhaseFrames();
end

% deletes the progressbar (if required)
h.Update(1+iOfs,'Phase Detection Complete!',1);
if delProg; h.closeProgBar(); end