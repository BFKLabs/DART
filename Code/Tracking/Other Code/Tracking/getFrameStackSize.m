% --- retrieves the segmentation stack frame size
function nFrmS = getFrameStackSize()

% global parameters
hFig = findall(0,'tag','figFlyTrack');

% opens the program parameter struct
A = load(getParaFileName('ProgPara.mat'));

% sets the comparison/maximum size limits
szMax = [1400,1800];
szComp = [min(hFig.frmSz0),max(hFig.frmSz0)];

% sets the image stack size
if any(szComp > szMax)
    % if the video is large, reduce the image stack size
    nFrmS = min(10,A.trkP.nFrmS);
else
    % loads the parameters from the program parameter file                
    nFrmS = A.trkP.nFrmS;
end