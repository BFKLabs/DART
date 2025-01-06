% --- sets the time cycle menu item properties
function setTimeCycleMenuProps(hFig,sInfo)

% field retrieval
hMenuTC = findall(hFig,'tag','menuTimeCycle');

% determines if the any experiment is a long expt
if isempty(sInfo)
    % case is no data is loaded
    isOn = false;
    
else
    % case is at least one long (1/2 day) expt is loaded
    tDur = cellfun(@(x)(x.tDur),sInfo);
    isOn = any(convertTime(tDur,'s','d') > 0.5);
end

% sets the menu item visibility
setObjEnable(hMenuTC,isOn)