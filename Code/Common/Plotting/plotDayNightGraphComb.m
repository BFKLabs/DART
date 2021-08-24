% --- plots the day/night time bands --- %
function plotDayNightGraphComb(hAx,snTot,Y)

% global variables
global tDay hDay

% parameters and initialisations
[fAlpha,T0] = deal(0.4,snTot.iExpt(1).Timing.T0);
[xTickLbl,xTick] = deal(get(hAx,'xticklabel'),get(hAx,'xtick'));
if (ischar(xTickLbl)); xTickLbl = num2cell(xTickLbl,2)'; end

% determines the times of the non-empty x-tick labels
if (strcmpi(xTickLbl{1}(end),'m'))
    % determines the gap size
    a = load(getParaFileName('ProgPara.mat'));
    sGapS = repmat(' ',1,1-floor(log10(a.gPara.Tgrp0)));        
        
    % determines the matching time for the start of the day cycle
    yStr = sprintf('%s%iAM',sGapS,a.gPara.Tgrp0);
    j0 = find(strcmp(xTickLbl,yStr),1,'first');        
    
    % determines the matching time for the start of the night cycle
    yStr = sprintf('%s%iPM',sGapS,a.gPara.Tgrp0);
    j1 = find(strcmp(xTickLbl,yStr),1,'first'); 
    
    % sets the earliest start time (either the day or night cycle)
    i0 = min([j0,j1]);
else
    % case is zeitgeiber time
    i0 = find(strcmp(xTickLbl,'0'),1,'first');
end

% fills in any gaps
xL = get(hAx,'xlim');
xGrp0 = xTick(i0):12:xL(2);
if (xGrp0(1) > xL(1)); xGrp0 = [xL(1),xGrp0]; end
if (xGrp0(end) < xL(2)); xGrp0 = [xGrp0,xL(2)]; end

% sets the day/night groupings
xGrp = [xGrp0(1:end-1)',xGrp0(2:end)'];

% determines
Tofs = convertTime(vec2sec([0 T0(4:end)]),'sec','hrs');   
isDayS = (Tofs >= tDay) && (Tofs <= (tDay+hDay));
dnInd = logical(mod((1:size(xGrp,1))-(1-isDayS),2)');
        
% loops through all the subplot indices setting the day/night bands
yFill = [0 0 Y*[1 1]];
for j = 1:length(dnInd)
    % sets the subplot
    subplot(hAx); hold on           
    
    % sets the x-fill coordinates
    xFill = xGrp(j,[1 2 2 1]);

    % plot the day-time bands
    if (dnInd(j))
        fill(xFill,yFill,'y','FaceAlpha',fAlpha,'tag','hFill')
    else
        fill(xFill,yFill,'k','FaceAlpha',fAlpha,'tag','hFill')
    end
end