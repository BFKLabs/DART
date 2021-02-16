% --- disables all the tracking panels. returns the properties before
%     disabling the panel properties (all checkboxes removed)
function hProp0 = disableAllTrackingPanels(hGUI,varargin)

% global variables
global isCalib

% main GUI handle
hGUIF = hGUI.figFlyTrack;

% remove the local view (if set)
if get(hGUI.checkLocalView,'value')
    set(hGUI.checkLocalView,'value',0)
    feval(getappdata(hGUIF,'checkLocalView_Callback'),...
                                        hGUI.checkLocalView,[],hGUI)
end

% remove the sub-regions (if set)
if get(hGUI.checkSubRegions,'value')
    set(hGUI.checkSubRegions,'value',0)
    feval(getappdata(hGUIF,'checkSubRegions_Callback'),...
                                        hGUI.checkSubRegions,[],hGUI)    
end

% remove the tube-regions (if set)
if get(hGUI.checkShowTube,'value')
    set(hGUI.checkShowTube,'value',0)
    feval(getappdata(hGUIF,'checkShowTube_Callback'),...
                                        hGUI.checkShowTube,1,hGUI)    
end

% removes the checkbox values (if they are set)
set(hGUI.checkReject,'value',0)
set(hGUI.checkShowMark,'value',0)
if ishandle(hGUI.checkShowAngle); set(hGUI.checkShowAngle,'value',0); end
if ~isCalib; feval(getappdata(hGUI.figFlyTrack,'dispImage'),hGUI); end

% updates the GUI properties
hProp0 = getHandleSnapshot(hGUI);
setPanelProps(hGUI.panelImgData,'off')
setPanelProps(hGUI.panelAppInfo,'off')
setPanelProps(hGUI.panelFlyDetect,'off')
setPanelProps(hGUI.panelAxProp,'off')

if ishandle(hGUI.panelFrmSelect)
    setPanelProps(hGUI.panelFrmSelect,'off'); 
end

if nargin == 2
    if ishandle(hGUI.panelExptPara)
        setPanelProps(hGUI.panelExptPara,'off'); 
    end
end

% disables the menu items
setObjEnable(hGUI.menuFile,'off')
setObjEnable(hGUI.menuAnalysis,'off')
