% --- sets the population signal data for the output GUI
function iData = setMetricSignalsPop(iData,plotD,pType)

% sets the index array for the data output
yVar = iData.yVar(pType);
[pStr,Y] = deal(field2cell(yVar,'Var'),iData.Y{5});
nApp = length(iData.appName);
                                 
% loops through each of the specified indices calculating the metrics
for i = 1:sum(pType)
    % sets the independent/dependent variable arrays
    X = arrayfun(@(x)(getStructField(x,yVar(i).xDep{1})),plotD,'un',0); 
    YY = dataGroupSplit(X,field2cell(plotD,pStr{i}));
    
    % sets the signals for each of the 
    Y{i} = cell(nApp,1);
    for j = 1:nApp; Y{i}{j} = YY{j}; end
end

% sets the metric array into the overall data array
iData.Y{5} = Y;

% -------------------------------- %
% --- DATA COMBINING FUNCTIONS --- %
% -------------------------------- %

% --- splits the data (for each apparatus) into separate arrays to denote
%     the separation of the data (i.e., by either day or experiment)
function Ygrp = dataGroupSplit(X,Y)                     

% memory allocation
nApp = length(Y);
Ygrp = cell(1,nApp);

% loops through each apparatus, level and bin group
for k = 1:nApp
    if iscell(Y{k})
        Ytmp = cell2cell(cellfun(@(x)(num2cell(x,1)),Y{k},'un',0));        
        Ygrp{k} = [X{k},cell2cell(cellfun(@(x)...
                    (cell2mat(x(:)')),num2cell(Ytmp,1),'un',0),0)];
    else
        % ensures the arrays are cell arrays
        if ~iscell(X{k}); X{k} = num2cell(X{k}); end
        if ~iscell(Y{k}); Y{k} = num2cell(Y{k}); end
        
        % appends the array together
        if (size(Y{k},1) == length(X{k}))
            Ygrp{k} = [X{k}(:),Y{k}];
        else
            Ygrp{k} = [X{k}(:),Y{k}(:)];
        end
    end        
end