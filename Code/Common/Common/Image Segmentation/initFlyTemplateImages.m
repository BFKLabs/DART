% --- initialises the fly template images
function xcP = initFlyTemplateImages()

% global variable
global frmSz mainProgDir is2D

% sets the image size
D = roundP(10*max(frmSz./[480 640]));

% loads the gabor template parameters from the program parameter file
A = load(fullfile(mainProgDir,'Para Files','ProgPara.mat'));
if (is2D)
    % case is the 2D apparatus regions
    [pX,pY] = deal(A.p2D.X,A.p2D.Y);
else
    % case is the 1D apparatus regions
    [pX,pY] = deal(A.p1D.X,A.p1D.Y);
end

% creates the fly templates
[pX,pY] = rescaleGaborPara(pX,pY);
xcP = struct('ITx',gaborFcn(D,pX),'ITy',gaborFcn(D,pY),'isSet',false);