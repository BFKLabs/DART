% --- retrieves the background estimate sub-image stacks --- %
function [iMov,sImgS,Img] = getEstimateImageStack(iData,iMov,h,iOfs)

% sets the default input arguments
if ~exist('iOfs','var'); iOfs = 0; end

% parameters
outImgStack = nargout > 1;
nStep = 2 + outImgStack;

% initialisations
delProg = false;

% creates a waitbar figure (if one is not created)
if ~exist('h','var')
    delProg = true;
    h = ProgBar('Current Progress','Image Estimation Stack');
end

% creates the video phase class object
phObj = VideoPhase(iData,iMov,h,1+iOfs);

% runs the phase detection solver
phObj.runPhaseDetect();

% updates the sub-image data struct with the phase information
phObj.iMov.ImnF = phObj.ImnF;
[phObj.iMov.iPhase,phObj.iMov.vPhase] = deal(phObj.iPhase,phObj.vPhase);
iMov = phObj.iMov;

% reads the frames from the images
if outImgStack
    h.Update(1+iOfs,'Reading Phase Frames...',2/nStep);
    [Img,sImgS] = phObj.readPhaseFrames();
end

% deletes the progressbar (if required)
h.Update(1+iOfs,'Phase Detection Complete!',1);
if delProg; h.closeProgBar(); end
