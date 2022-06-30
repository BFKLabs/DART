function frmSz = getCurrentImageDim(hGUI)

% retrieves the fly tracking GUI handle
if ~exist('hGUI','var')
    hGUI = findall(0,'tag','figFlyTrack'); 

elseif isstruct(hGUI)
    hGUI = hGUI.figFlyTrack;
end

% retrieves the gui image object handle
hPanelI = findall(hGUI,'tag','panelImg');
hImg = findall(hPanelI,'type','image');
if isempty(hImg)
    % if there is no image, return a NaN array
    frmSz = NaN(1,2);
else
    % otherwise, determine the size of the image
    frmSz = size(get(hImg,'CData'));
end

% ignores the 3rd image dimension
frmSz = frmSz(1:2);