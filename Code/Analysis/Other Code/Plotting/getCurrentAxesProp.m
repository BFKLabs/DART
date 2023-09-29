% --- retrieves the current analysis axes property
function [hObj,hFig] = getCurrentAxesProp(pStr)

% determines if the figure is valid
validFig = {'figPlotFigure','figFlyAnalysis'};

% ensures the current figure is the analysis figure
for i = 1:length(validFig)
    hFig = findall(0,'tag',validFig{i});
    if ~isempty(hFig)
        set(0,'CurrentFigure',hFig);  
        break
    end
end

% retrieves axes property
if exist('pStr','var')
    hObj = get(gca,pStr);    
else
    hObj = gca;
end