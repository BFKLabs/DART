% --- retrieves the segmentation stack frame size
function nFrmS = getFrameStackSize()

% global parameters
global frmSz0

% opens the program parameter struct
A = load(getParaFileName('ProgPara.mat'));

% sets the comparison/maximum size limits
szMax = [1400,1800];
szComp = [min(frmSz0),max(frmSz0)];

% sets the image stack size
if any(szComp > szMax)
    % if the video is large, reduce the image stack size
    nFrmS = min(10,A.trkP.nFrmS);
else
    % loads the parameters from the program parameter file                
    nFrmS = A.trkP.nFrmS;
end