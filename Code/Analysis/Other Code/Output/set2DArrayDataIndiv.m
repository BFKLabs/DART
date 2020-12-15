% --- sets the individual 2D array for the output GUI
function iData = set2DArrayDataIndiv(iData,plotD,pType)

% sets the index array for the data output
yVar = iData.yVar(pType);
pStr = field2cell(yVar,'Var');

% retrieves the data array
[Y,nApp] = deal(iData.Y{8},length(iData.appName));

% sets the data arrays for each metric
for i = 1:length(pStr)
    % initialisations
    YY = dataGroupSplit(field2cell(plotD,pStr{i})); 
    
    % sets the signals for each of the 
    Y{i} = cell(nApp,1);
    for j = 1:nApp; Y{i}{j} = YY{j}; end
end

% sets the 2D data array into the overall data array
iData.Y{8} = Y;

% -------------------------------- %
% --- DATA COMBINING FUNCTIONS --- %
% -------------------------------- %

% --- splits the data
function Ygrp = dataGroupSplit(Y) 

% memory allocation
nApp = length(Y);
Ygrp = cell(1,nApp);

% loops through each apparatus converting the 2D array data
for i = 1:nApp
    % memory allocation
    Ygrp{i} = cell(1,length(Y{i}));
    
    % sets the values for each group
    for j = 1:length(Y{i})
        % sets the x/y strings
        [nGY,nGX] = size(Y{i}{j});
        tStrY = cellfun(@(x)(sprintf('Cell #%i',x)),num2cell(1:nGX),'un',0);
        tStrX = cellfun(@(x)(sprintf('Cell #%i',x)),num2cell(1:nGY),'un',0)';

        % memory allocation
        Ygrp{i}{j} = cell(nGY+1,nGX+1);

        % sets the 
        Ygrp{i}{j} = num2cell(Y{i}{j});
        Ygrp{i}{j}(isnan(Y{i}{j})) = {''};

        % adds the x/y axis titles
        Ygrp{i}{j} = combineCellArrays(tStrY,Ygrp{i}{j},0);
        Ygrp{i}{j} = combineCellArrays([{''};tStrX],Ygrp{i}{j});
    end
end