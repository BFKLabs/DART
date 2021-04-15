% --- sets the population signal data for the output GUI
function iData = setMetricSignalsIndiv(snTot,iData,plotD,pType)

% sets the number of experiments
[hasTime,nExp] = deal(true,iData.sepExp*(length(snTot)-1) + 1);
fok = cellfun(@(x)(x.appPara.flyok),num2cell(snTot),'un',0);

% initialisations
[yVar,xVar,Y] = deal(iData.yVar(pType),iData.xVar,iData.Y{6});
[pStr,nApp] = deal(field2cell(yVar,'Var'),length(iData.appName));
[T,iD] = deal(cell(nExp,2),cell(nExp,1));

% sets the x-dependency
xDep = field2cell(yVar,'xDep');
xDepT = cellfun(@(x)(x{1}),xDep,'un',0);

% determines the number of days each experiment runs for
[Y0,nDay] = deal(field2cell(plotD,pStr{1}),zeros(nExp,1));
for i = 1:length(Y0)
    for j = 1:nExp
        nDay(j) = max(cellfun(@(x)(sum(~cellfun(...
                                @isempty,x))),num2cell(Y0{i}(:,:,j),1)));
    end
end

% determines if any of the variables have a time dependency
ii = find(cellfun(@(x)(any(strcmp(xDepT,x))),field2cell(iData.xVar,'Var')));
iiT = ii(strcmp(field2cell(iData.xVar(ii),'Type'),'Time'));

% splits the time-bin indices into separate days
if (~isempty(iiT))
    % initialisations
    [tDay,nDayMx] = deal(convertTime(1,'day','sec'),max(nDay));
    
    % retrieves the time vector array (ensures is cell arrays)
    TT = field2cell(plotD,xVar(iiT).Var);
    if (~iscell(TT{1})); TT = cellfun(@(x)({x}),TT,'un',0); end   
    
    %
    if (length(TT{1}) < nExp)
        TT = cellfun(@(x)(repmat(x,1,nExp)),TT,'un',0);
    end
    
    % determines if the time vector is greater than a single day
    if (nDayMx > 1)
        % if so, then set the converted daily time vector        
        dT = roundP(nanmedian(diff(TT{1}{1})));
        Tnw = ((dT/2):dT:(convertTime(1,'day','sec')-dT/2))';        
        xiD = num2cell(1:nDayMx);
        
        % sets the time vectors for each experiment
        for i = 1:nExp        
            % sets the             
            TTot = cellfun(@(x)(Tnw+(x-1)*tDay),xiD,'un',0);
            iD{i} = cell2mat(cellfun(@(x)(x*ones(length(Tnw),1)),xiD(:),'un',0));
            
            %
            [T{i,1},T{i,2}] = deal(cell2mat(TTot(:)),Tnw);
        end
    else    
        % for each experiment, determine if the data is for more than one day.
        % if so, then expand the time vector for that experiment
        for i = 1:nExp
            if (nDay(i) > 1)
                % expands the time vector to cover the entire experiment
                Tnw = cellfun(@(x)(TT{1}{i}+(x-1)*tDay),num2cell(1:nDay(i)),'un',0);
                [T{i,1},T{i,2}] = deal(cell2mat(Tnw(:)),TT{1}{i});
            else
                % otherwise, set the time vector for both time vector types
                [T{i,1},T{i,2}] = deal(TT{1}{i});
            end
        end
    end    
else
    % otherwise, set the index based on the dependency
    hasTime = false;
    T0 = eval(sprintf('plotD.%s',xDepT{1}));
    if (isnumeric(T0)); T0 = num2cell(T0); end
    
    nDayMx = max(nDay);
    [T(:,1),T(:,2)] = deal({repmat(T0,nDayMx,1)},{T0});
    
    if (nDayMx > 1)
        iD(:) = {cell2cell(cellfun(@(x)(num2cell(...
                    x*ones(length(T0),1))),num2cell(1:nDayMx)','un',0))};
    else
        iD = {[]};
    end
end
    
% replicates the array for each of the metrics
T = repmat({T},sum(pType),1);

% loops through each of the specified indices calculating the metrics
for i = 1:sum(pType)
    % initialisations
    YY = dataGroupSplit(iData,T{i},iD,field2cell(plotD,pStr{i}),fok,hasTime);
    
    % sets the metrics for each of the levels
    for iLvl = 1:size(YY,1)       
        % memory allocation
        Y{i,iLvl} = cell(nApp,1);
        
        % sets the values into the array
        for iApp = 1:nApp
            if (~isempty(YY{iLvl,iApp}))
                Y{i,iLvl}{iApp} = YY{iLvl,iApp};
            end
        end
    end
end

% sets the metric array into the overall data array
iData.Y{6} = Y;

% -------------------------------- %
% --- DATA COMBINING FUNCTIONS --- %
% -------------------------------- %

% --- splits the data (for each apparatus) into separate arrays to denote
%     the separation of the data (i.e., by either day or experiment)
function Ygrp = dataGroupSplit(iData,T,iD,Y,fok,hasTime)

% Ygrp Convention
%
% 1st Level - signal combined over all days/experiments
% 2nd Level - signal separated over individual days

% memory allocation
noID = all(cellfun(@isempty,iD));
[nApp,nLvl,nExp] = deal(length(Y),2,length(fok));
Ygrp = cell(nLvl,nApp);

% loops through each apparatus, level and bin group
for j = 1:nLvl     
    % memory allocation
    Ytmp = cell(1,nApp);
    if (j == 1)
        Ynw = Ytmp; 
        [j0,j1] = deal(NaN(nApp,1));
    end
    
    %
    for k = 1:nApp           
        if (j == 1)
            % memory allocation
            for i = 1:nExp; Y{k}(:,~fok{i}{k},i) = {[]}; end
            
            %
            isE = cellfun(@isempty,Y{k});
            for i = 1:size(isE,3)
                if (any(arr2vec(isE(:,:,i))))
                    % determines which is the first non-empty cell
                    k0 = find(~isE(:,:,i),1,'first');
                    if (isempty(k0))
                        % if there are none, then base on the time vector
                        Yemp = NaN(size(T{i,2}));                        
                    else
                        % otherwise, base the empty cells on existing
                        Yemp = NaN(size(Y{k}{1,k0,i}));
                    end
                    
                    % fills in the empty cells
                    YkT = Y{k}(:,:,i);
                    YkT(isE(:,:,i)) = {Yemp};
                    Y{k}(:,:,i) = YkT;
                end
            end 
            
            % fills in any empty cells with NaN values
            Ytmp = cellfun(@(x)(cell2mat(x)),num2cell(Y{k},1),'un',0);     
            
            % combines the data with the time vectors
            if (noID)
                if (hasTime)
                    Ynw{k} = cellfun(@(t,x)([t,combineNumericCells(x(:)')]),...
                        T(:,1),reshape(num2cell(Ytmp,2),size(T(:,1))),'un',0);
                    YnwI = cellfun(@(x)(x(:,2:end)),Ynw{k},'un',0);                    
                else
                    Ynw{k} = cellfun(@(t,x)([t,num2cell(combineNumericCells(x(:)'))]),...
                        T(:,1),reshape(num2cell(Ytmp,2),size(T(:,1))),'un',0);                    
                    YnwI = cellfun(@(x)(cell2mat(x(:,2:end))),Ynw{k},'un',0);
                end                                                                     
            else
                if (hasTime)
                    Ynw{k} = cellfun(@(id,t,x)([id,t,combineNumericCells(x(:)')]),...
                        iD,T(:,1),reshape(num2cell(Ytmp,2),size(T(:,1))),'un',0);
                    YnwI = cellfun(@(x)(x(:,3:end)),Ynw{k},'un',0);                    
                else
                    Ynw{k} = cellfun(@(id,t,x)([id,t,num2cell(combineNumericCells(x(:)'))]),...
                        iD,T(:,1),reshape(num2cell(Ytmp,2),size(T(:,1))),'un',0);                    
                    YnwI = cellfun(@(x)(cell2mat(x(:,3:end))),Ynw{k},'un',0);
                end                                                 
            end      
            
            % determines the indices of the first/last non-NaN rows
            j0 = cellfun(@(x)(find(~all(isnan(x),2),1,'first')),YnwI,'un',0);
            j1 = cellfun(@(x)(find(~all(isnan(x),2),1,'last')),YnwI,'un',0);  
            
            %
            for i = 1:length(j0)
                if (isempty(j0{i})); j0{i} = 1; end
                if (isempty(j1{i})); j1{i} = size(YnwI{i},1); end
            end
            
            [i0,i1] = deal(min(cell2mat(j0)),max(cell2mat(j1)));
        else
            % sets the number of days
            Ytmp{k} = cellfun(@(x)(cell2mat(x(:)')),num2cell(Y{k},1),'un',0);            
        end
    end
        
        
   for k = 1:nApp 
        switch (j)
            case (1) % case is signals are combined over all days                                                                                                                
                
                % resets the final combined output array
                Ygrp{j,k} = cellfun(@(x)(x(i0:i1,:)),Ynw{k},'un',0);
                
            case (2) % case is signals are separated over all days                
                if (iData.sepDay)                
                    % resets the final combined output array
                    if (hasTime)
                        Ygrp{j,k} = cellfun(@(t,x)([t,cell2mat(x(:)')]),T(:,2),...
                                reshape(num2cell(Ytmp{k},2),size(T(:,2))),'un',0);
                    else
                        Ygrp{j,k} = cellfun(@(t,x)([t,num2cell(cell2mat(x(:)'))]),T(:,2),...
                                reshape(num2cell(Ytmp{k},2),size(T(:,2))),'un',0);                        
                    end
                end
        end
    end
end