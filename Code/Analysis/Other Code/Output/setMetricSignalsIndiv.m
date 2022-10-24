% --- sets the population signal data for the output GUI
function iData = setMetricSignalsIndiv(iData,plotD,pType,snTot)

% sets the number of experiments
nExp = iData.sepExp*(length(snTot)-1) + 1;
if ~iscell(snTot(1).iMov.flyok)
    fok = arrayfun(@(x)(groupAcceptFlags(x)),snTot,'un',0);
else
    fok = arrayfun(@(x)(x.iMov.flyok),snTot,'un',0);
end

% initialisations
[yVar,xVar,Y] = deal(iData.yVar(pType),iData.xVar,iData.Y{6});
[pStr,nApp] = deal(field2cell(yVar,'Var'),length(iData.appName));

% sets the x-dependency
xDep = field2cell(yVar,'xDep');
xDepT = cellfun(@(x)(x{1}),xDep,'un',0);

% determines the number of days each experiment runs for
Y0 = field2cell(plotD,pStr{1});
nDay0 = zeros(nApp,nExp);
for i = 1:length(Y0)
    for j = 1:nExp
        nDay0(i,j) = max(cellfun(@(x)(sum(~cellfun(...
                                @isempty,x))),num2cell(Y0{i}(:,:,j),1)));
    end
end

% aligns the independent variables to the plot values
nDay = max(nDay0,[],1);
[xDepTU,~,indU] = unique(xDepT,'stable');
ii = cellfun(@(x)(any(strcmp(xDepT,x))),field2cell(xVar,'Var'));

% memory allocation
nDep = length(xDepTU);
[T,iD,hasTime] = deal(cell(nExp,2,nDep),cell(nExp,nDep),false(nDep,1));
xVar = field2cell(xVar(ii),'Type');

% sets up the dependent variable arrays
for i = 1:nDep    
    % splits the time-bin indices into separate days
    if strcmp(xVar{i},'Time')
        % initialisations
        hasTime(i) = true;
        [tDay,nDayMx] = deal(convertTime(1,'day','sec'),max(nDay));

        % retrieves the time vector array (ensures is cell arrays)
        TT = field2cell(plotD,xDepTU{i});
        if ~iscell(TT{1}); TT = cellfun(@(x)({x}),TT,'un',0); end   

        % ensures the time vector matches the experiment count
        if length(TT{1}) < nExp
            TT = cellfun(@(x)(repmat(x,1,nExp)),TT,'un',0);
        end

        % determines if the time vector is greater than a single day
        if nDayMx > 1
            % if so, then set the converted daily time vector        
            dT = roundP(median(diff(TT{1}{1}),'omitnan'));
            Tnw = ((dT/2):dT:(convertTime(1,'day','sec')-dT/2))';        
            xiD = num2cell(1:nDayMx);

            % sets the time vectors for each experiment
            for j = 1:nExp        
                % sets the ID/time vectors            
                TTot = cellfun(@(x)(Tnw+(x-1)*tDay),xiD,'un',0);
                iD{j,i} = cell2mat(cellfun(@(x)...
                            (x*ones(length(Tnw),1)),xiD(:),'un',0));
                [T{j,1,i},T{j,2,i}] = deal(cell2mat(TTot(:)),Tnw);
            end
        else    
            % for each experiment, determine if the data is for more than one day.
            % if so, then expand the time vector for that experiment
            for j = 1:nExp
                if (nDay(j) > 1)
                    % expands the time vector to cover the entire experiment
                    xiD = 1:nDay(j);
                    Tnw = arrayfun(@(x)(TT{1}{j}+(x-1)*tDay),xiD,'un',0);
                    [T{j,1,i},T{j,2,i}] = deal(cell2mat(Tnw(:)),TT{1}{j});
                else
                    % otherwise, set the time vector for both time vector types
                    [T{j,1,i},T{j,2,i}] = deal(TT{1}{j});
                end
            end
        end    
    else
        % otherwise, set the index based on the dependency
        hasTime = false;
        T0 = eval(sprintf('plotD.%s',xDepTU{i}));
        if isnumeric(T0); T0 = num2cell(T0); end

        nDayMx = max(nDay);
        if length(T0) == nExp
            [T(:,1,i),T(:,2,i)] = deal(T0,{T0});
        else
            [T(:,1,i),T(:,2,i)] = deal({repmat(T0,nDayMx,1)},{T0});
        end

        if nDayMx > 1
            iD(:,i) = {cell2cell(arrayfun(@(x)(num2cell(...
                        x*ones(length(T0),1))),(1:nDayMx)','un',0))};
        else
            iD(:,i) = {[]};
        end
    end
end   

% loops through each of the specified indices calculating the metrics
for i = 1:sum(pType)
    % initialisations
    j = indU(i);
    pVal = field2cell(plotD,pStr{i});
    YY = dataGroupSplit(iData,T(:,:,j),iD(:,j),pVal,fok,hasTime(j));
    
    % sets the metrics for each of the levels
    for iLvl = 1:size(YY,1)       
        % memory allocation
        Y{i,iLvl} = cell(nApp,1);
        
        % sets the values into the array
        for iApp = 1:nApp
            if ~isempty(YY{iLvl,iApp})
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
%         [j0,j1] = deal(NaN(nApp,1));
    end
    
    %
    for k = 1:nApp
        if j == 1
            % memory allocation
            for i = 1:nExp; Y{k}(:,~fok{i}{k},i) = {[]}; end
            
            %
            isE = cellfun(@isempty,Y{k});
            for i = 1:size(isE,3)
                if any(arr2vec(isE(:,:,i)))
                    % determines which is the first non-empty cell
                    k0 = find(~isE(:,:,i),1,'first');
                    if isempty(k0)
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
            if noID
                if hasTime
                    Ynw{k} = cellfun(@(t,x)([t,combineNumericCells(x(:)')]),...
                        T(:,1),reshape(num2cell(Ytmp,2),size(T(:,1))),'un',0);
                    YnwI = cellfun(@(x)(x(:,2:end)),Ynw{k},'un',0);                    
                else
                    Ynw{k} = cellfun(@(t,x)([t,num2cell(combineNumericCells(x(:)'))]),...
                        T(:,1),reshape(num2cell(Ytmp,2),size(T(:,1))),'un',0);                    
                    YnwI = cellfun(@(x)(cell2mat(x(:,2:end))),Ynw{k},'un',0);
                end                                                                     
            else
                if hasTime
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
                if isempty(j0{i}); j0{i} = 1; end
                if isempty(j1{i}); j1{i} = size(YnwI{i},1); end
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
                ind = cellfun(@(x,y)(x:y),j0,j1,'un',0);
                Ygrp{j,k} = cellfun(@(x,y)(x(y,:)),Ynw{k},ind,'un',0);
                
            case (2) % case is signals are separated over all days                
                if iData.sepDay
                    % resets the final combined output array
                    if hasTime
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
