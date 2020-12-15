% --- 
function yL0 = getBoxPlotLimits(hPlot,hasOutL)

% initialisations
tStr = get(hPlot(:,1),'tag');

% determines the indices of the lower/upper whiskers and the outliers
iUW = strcmp(tStr,'Upper Adjacent Value');
iLW = strcmp(tStr,'Lower Adjacent Value');
iOL = strcmp(tStr,'Outliers');

% determines the upper/lower whisker values
yUW = getArrayVals(get(hPlot(iUW,:),'ydata'));
yLW = getArrayVals(get(hPlot(iLW,:),'ydata'));

%
if (hasOutL)
    % case is there is outliers
    yOL = cell2mat(get(hPlot(iOL,:),'ydata'));
    yL0 = [min(min(yLW(:)),min(yOL(:))),max(max(yUW(:)),max(yOL(:)))];
else
    % case is there is no outliers
    yL0 = [min(yLW(:)),max(yUW(:))];
end

% --- retrieves the array values (ensure data is stored in numerical array)
function Y = getArrayVals(Y)

if (iscell(Y)); Y = cell2mat(Y); end