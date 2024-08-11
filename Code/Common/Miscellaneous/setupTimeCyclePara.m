% --- sets up the time cycle parameter data struct
function tcPara = setupTimeCyclePara()

% retrieves the global parameter struct
hFigA = findall(0,'tag','figFlyAnalysis');
if isempty(hFigA)
    % case is loading from the data combining GUI
    A = load(getProgFileName('Para Files','ProgPara.mat'));
    gP = A.gPara;
else
    % case is from the analysis GUI
    gP = getappdata(hFigA,'gPara');
end

% memory allocation
tcPara = struct('tOn',gP.TdayC,'tOff',gP.TdayC,...
                'tCycleR',[],'tCycle0',[],'isFixed',1);

% setting class fields
tMin = minutes(hours(gP.Tgrp0));
tcPara.tCycle0 = [floor(tMin/60),mod(tMin,60),0];
tcPara.tCycleR = {12,12};