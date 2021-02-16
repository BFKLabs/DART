% --- calculates the statistic metrics for the population data 
function iData = setFixedMetricsPop(iData,plotD,pType,ind)

% sets the index array for the data output
yVar = iData.yVar(pType);
[pStr,Y] = deal(field2cell(yVar,'Var'),iData.Y{3});
if (nargin < 5); ind = 1:length(pStr); end

% loops through each of the specified indices calculating the metrics
for j = 1:length(ind)
    % initialisations
    Ynw = field2cell(plotD,pStr{ind(j)});
    if (iscell(Ynw{1}))
        Y{j} = cellfun(@(x)(cell2cell(x)),Ynw,'un',0);    
    else
        Y{j} = cellfun(@(x)(x),Ynw,'un',0);
    end
end

% sets the metric array into the overall data array
iData.Y{3} = Y;