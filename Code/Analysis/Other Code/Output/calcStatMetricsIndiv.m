% --- calculates the statistic metrics for the population data 
function iData = calcStatMetricsIndiv(snTot,iData,plotD,pType)

% sets the index array for the data output
pStr = field2cell(iData.yVar(pType),'Var');
ind = 1:sum(pType);

% retrieves the data array
[Y,nApp] = deal(iData.Y{4},length(iData.appName));
nGrp = detDataGroupSize(iData,plotD,find(pType),1);

% ensures the group size is the same as the 
if (length(nGrp) ~= length(ind))
    nGrp = nGrp*ones(length(ind),1); 
end

% loops through each of the specified indices calculating the metrics
for j = 1:length(ind)
    % initialisations
    i = ind(j);
    YY = dataGroupSplit(iData,field2cell(plotD,pStr{i}),nGrp(j),plotD);
            
    % sets the metrics for each of the levels
    for iLvl = 1:size(Y,2)       
        % memory allocation
        Y{i,iLvl} = cell(nApp,1);
        
        % sets the values into the array
        for iApp = 1:nApp
            for iGrp = 1:(1+iData.sepGrp)
                if (iGrp == 1)
                    Y{i,iLvl}{iApp} = YY{iLvl,iApp,iGrp};
                else
                    Y{i,iLvl}{iApp} = cellfun(@(x,y)([x,y]),...
                        Y{i,iLvl}{iApp},YY{iLvl,iApp,iGrp},'un',0);                
                end
            end
        end
    end
end

% sets the metric array into the overall data array
iData.Y{4} = Y;

% -------------------------------- %
% --- DATA COMBINING FUNCTIONS --- %
% -------------------------------- %

% --- splits the data (for each apparatus) into separate arrays to denote
%     the separation of the data (i.e., by either day or experiment)
function Ygrp = dataGroupSplit(iData,Y,nGrp,p)

% Ygrp Convention
%
% 1st Level - metrics calculated over all days
% 2nd Level - metrics calculated over individual days

% Dim 1 - Sub-Grouping (Time/Distance etc)
% Dim 2 - Metric Level
% Dim 3 - Fly Group

% memory allocation
[nApp,nLvl] = deal(length(Y),2);
Ygrp = cell(nLvl,nApp,1+iData.sepGrp);
xiG = num2cell(1:nGrp)';

if isfield(p(1),'indCombMet')
    indCombMet = p(1).indCombMet;
else
    indCombMet = 'mn';
end

% loops through each apparatus, level and bin group
for k = 1:nApp
    % retrieves the values for each 
    for iGrp = 1:1+iData.sepGrp
        Y{k}(cellfun(@isempty,Y{k})) = {NaN(1+iData.sepGrp,nGrp)};            
        if (iData.sepGrp)
            Ynw = cellfun(@(y)(cellfun(@(x)(x(iGrp,y)),Y{k})),xiG,'un',0);            
        else            
            Ynw = cellfun(@(y)(cellfun(@(x)(x(y)),Y{k})),xiG,'un',0);
%             Ynw = cellfun(@(x)(cell2mat(x)),num2cell(Y{k},1),'un',0);
        end                       
    
        %
        nExp = size(Ynw{1},3);
        for j = 1:nLvl        
            % memory allocation        
            Ygrp{j,k,iGrp} = cell(nGrp,nExp);        
            for i = 1:nExp
                switch (j)
                    case (1) % case is metrics for all days                                
                        Ymet = cellfun(@(x)(x(:,:,i)),Ynw,'un',0);
                        if strcmp(indCombMet,'none')
                            Ygrp{j,k,iGrp}(:,i) = cellfun(@(x)(x'),...
                                    calcMetrics(Ymet,'sum'),'un',0);                            
                        else
                            Ygrp{j,k,iGrp}(:,i) = cellfun(@(x)(x'),...
                                    calcMetrics(Ymet,indCombMet),'un',0);
                        end
                    case (2) % case is metrics for each day
                        % only set if multiple days   
                        if (iData.sepDay)                                
                            Ymet = cellfun(@(x)(num2strC(...
                                        x(:,:,i),'%.4f',1)'),Ynw,'un',0);                            
                            Ygrp{j,k,iGrp}(:,i) = Ymet;
                        end
                end            
            end
        end
    end
end