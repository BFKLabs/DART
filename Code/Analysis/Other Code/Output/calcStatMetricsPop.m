% --- calculates the statistic metrics for the population data 
function iData = calcStatMetricsPop(iData,plotD,pType,snTot)

% sets the index array for the data output
yVar = iData.yVar(pType);
pStr = field2cell(yVar,'Var');
ind = 1:length(pStr); 

% retrieves the data array
[Y,nApp] = deal(iData.Y{2},length(iData.appName));
mInd = iData.tData.iPara{iData.cTab}{2}{2};
mInd = mInd & cellfun(@isempty,Y(:,:,1));

% loops through each of the specified indices calculating the metrics
for j = 1:length(ind)
    % initialisations
    i = ind(j);
    YY = dataGroupSplit(iData,field2cell(plotD,pStr{i}),snTot);
            
    % retrieves the calculated values
    for iMet = find(mInd(i,:))
        % determines the metric variable string
        vName = ind2varStat(iMet);
        
        % sets the metrics for each of the levels
        for iLvl = 1:size(Y,3)  
            % calculates the metrics for each of the 
            Ymet = cell(nApp,1);
            for iApp = 1:nApp
                if ~isempty(YY{iLvl,iApp})
                    Ymet{iApp} = calcMetrics(YY{iLvl,iApp},vName);
                end
            end
                
            % sets the final data array into the overall array
            Y{i,iMet,iLvl} = Ymet;                
        end
    end           
end

% sets the metric array into the overall data array
iData.Y{2} = Y;

% -------------------------------- %
% --- DATA COMBINING FUNCTIONS --- %
% -------------------------------- %

% --- splits the data (for each apparatus) into separate arrays to denote
%     the separation of the data (i.e., by either day or experiment)
function Ygrp = dataGroupSplit(iData,Y,snTot)

% Ygrp Convention
%
% 1st Level - metrics calculated over all days/experiments
% 2nd Level - metrics calculated over all days/individual experiments
% 3rd Level - metrics calculated over individual days/all experiments
% 4th Level - metrics calculated over individual days/experiments

% memory allocation
[nApp,nLvl] = deal(length(Y),4);
Ygrp = cell(nLvl,nApp);
 
% loops through each apparatus, level and bin group
for j = 1:nLvl
    for k = 1:nApp
        switch j
            case (1) 
                % metrics calculated over all days/experiments                
                Ytmp = cellfun(@(x)(cell2mat(cell2cell(x))),...
                            num2cell(num2cell(Y{k},1),3),'un',0);
                Ygrp{j,k} = {cell2mat(Ytmp(:))};
            
            case (2) 
                % metrics calculated over all days only
                
                % only set if multiple days   
                if iData.sepExp
                    Ygrp{j,k} = cell(1,length(snTot));
                    for i = 1:length(snTot)  
                        Ytmp = cellfun(@(x)(cell2mat(x)),...
                                num2cell(Y{k}(:,:,i),1),'un',0);
                        Ygrp{j,k}{i} = cell2mat(Ytmp(:));
                    end
                end                                        
            case (3) 
                % metrics calculated over all experiments only
                
                % only set if multiple experiments
                if iData.sepDay
                    Ygrp{j,k} = cell(size(Y{k},1),1);
                    for i = 1:size(Y{k},1)
                        Ytmp = cellfun(@(x)(cell2mat(x)),num2cell(...
                                reshape(Y{k}(i,:,:),[length(snTot),...
                                size(Y{k},2)]),1),'un',0);                        
                        Ygrp{j,k}{i} = cell2mat(Ytmp(:));
                    end
                end
            case (4) 
                % individual metrics calculated over all days/expts
                
                % only set if multiple days/experiments
                if iData.sepExp && iData.sepDay
                    Ygrp{j,k} = cell(size(Y{k},1),length(snTot));
                    for i1 = 1:size(Y{k},1)
                        for i2 = 1:length(snTot)
                            Ygrp{j,k}{i1,i2} = cell2mat(Y{k}(i1,:,i2)');
                        end
                    end
                end
        end            
    end
end

% --- combines that data for each experiment/day
function Ycomb = combineDayExptData(Y)

% memory allocation
sz = cell2mat(cellfun(@(x)(size(x)),Y,'un',0)');
Ycomb = NaN(max(sz(:,1)),max(sz(:,2)),length(Y));

% sets the data for each day/experiment
for i = 1:length(Y)
    if (~isempty(Y{i}))
        Ycomb(1:sz(i,1),1:sz(i,2),i) = Y{i};
    end
end

% --- combines that data for each day/all experiments
function Ycomb = combineExptData(Y)

% memory allocation
[nExp,sz] = deal(length(Y),cellfun(@numel,Y));
Ycomb = NaN(max(sz),nExp);

% sets the data for each experiment
for i = 1:nExp
    if (~isempty(Y{i}))
        Ycomb(1:sz(i),i) = Y{i}(:);
    end
end

% --- combines that data for each experiment/all days
function Ycomb = combineDayData(Y)

% memory allocation
sz = cell2mat(cellfun(@(x)(size(x)),Y,'un',0)');
Ycomb = NaN(sum(sz(:,1)),max(sz(:,2)));

% sets the data for each day
for i = 1:length(Y)
    if ~isempty(Y{i})
        Ycomb(sum(sz(1:(i-1),1))+(1:sz(i,1)),1:sz(i,2)) = Y{i};
    end
end

% ------------------------------------ %
% --- METRIC CALCULATION FUNCTIONS --- %
% ------------------------------------ %

% --- sets the group count for each variable
function nGrp = getGroupCount(plotD,iData,pType)

% sets the group indices
[yVar,xVar] = deal(iData.yVar(pType),iData.xVar);
xType = field2cell(xVar,'Type');

% determines if there are any grouping variables
iiG = 2*strcmp(xType,'Group') + strcmp(xType,'Genotype');
if (any(iiG > 0))
    % if so, then determine the number of bin groups
    xDep = field2cell(yVar,'xDep');

    % initialisations
    [nGrp,imx] = deal(zeros(length(xDep),1),argMax(iiG));
    nGrp0 = length(eval(sprintf('plotD(1).%s',xVar(imx).Var)));

    % sets the group count based on the dependencies   
    for i = 1:length(xDep)
        if (isempty(xDep{i}))
            % no dependencies, so set the default
            nGrp(i) = nGrp0;
        elseif (strcmp(xDep{i},'Single'))
            % case is a single value
            nGrp(i) = 1;
        else
            % sets the length based on the dependency
            nGrp(i) = length(eval(sprintf('plotD(1).%s',xDep{i}{1})));
        end
    end    
else
    % no groups, so set count to 1
    nGrp = ones(length(pType),1);
end
