% --- creates the toolbar items
function hTool = createToolbarItems(hFig,cImg,tType,ttStr,cbFcnT,hasSep)

% sets the default input arguments
if ~exist('hasSep','var'); hasSep = false(size(cImg)); end

% loads the toolbar images
A = load(getParaFileName('ButtonCData.mat'));
imgTool = A.cDataStr.Itool;  

% creates the toolbar item
hTool = createUIObj('toolbar',hFig);

% creates all the toolbar objects
for i = 1:length(cImg)
    % retrieves the toolbar image
    ImgT = double(im2uint8(imgTool.(cImg{i})))/255;
    ImgT(ImgT == 0) = NaN;
    
    % creates the new toolbar objec
    hToolNw = createUIObj(tType{i},hTool,...
        'ToolTip',ttStr{i},'ClickedCallback',cbFcnT{i},...
        'CData',ImgT);
    
    if hasSep(i)
        set(hToolNw,'Separator','on');
    end
end