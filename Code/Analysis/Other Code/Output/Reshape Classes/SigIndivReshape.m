classdef SigIndivReshape < handle
    
    % class properties
    properties

        % main class fields
        plotD
        pType        
        snTot
        
        % scalar class fields
        iType
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = SigIndivReshape(iData,iType)
            
            % sets the input arguments
            obj.iType = iType;
            
            % initialises the class fields and reshapes the metric data
            obj.initClassFields(iData);            
            obj.reshapeMetricData(iData);
            
        end
        
        % --- initialises the object class fields
        function initClassFields(obj,iData)
           
            % field retrieval
            obj.pType = iData.Type(:,obj.iType);
            obj.plotD = getappdata(iData.hFig,'plotD');
            obj.snTot = getappdata(iData.hFig,'snTot');            
            
        end
            
        % --- sets up the data output array
        function reshapeMetricData(obj,iData)
            
            % sets the number of experiments
            nExp = iData.sepExp*(length(obj.snTot)-1) + 1;
            if ~iscell(obj.snTot(1).iMov.flyok)
                fok = arrayfun(@(x)(groupAcceptFlags(x)),obj.snTot,'un',0);
            else
                fok = arrayfun(@(x)(x.iMov.flyok),obj.snTot,'un',0);
            end

            % initialisations
            Y = iData.getData(1+obj.iType);
            xVar = iData.xVar;
            yVar = iData.yVar(obj.pType);
            pStr = field2cell(yVar,'Var');
            nApp = length(iData.appName);
            
            % sets the x-dependency
            xDep = field2cell(yVar,'xDep');
            xDepT = cellfun(@(x)(x{1}),xDep,'un',0);
            
            % determines the number of days each experiment runs for
            Y0 = field2cell(obj.plotD,pStr{1});
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
            hasTime = false(nDep,1);            
            [T,iD] = deal(cell(nExp,2,nDep),cell(nExp,nDep));
            xVar = field2cell(xVar(ii),'Type');

            % sets up the dependent variable arrays
            for i = 1:nDep    
                % splits the time-bin indices into separate days
                if strcmp(xVar{i},'Time')
                    % initialisations
                    hasTime(i) = true;
                    nDayMx = max(nDay);                    
                    tDay = convertTime(1,'day','sec');

                    % retrieves the time vector array 
                    TT = field2cell(obj.plotD,xDepTU{i});
                    if ~iscell(TT{1})
                        % ensures the time vector is stored as a cell array
                        TT = cellfun(@(x)({x}),TT,'un',0); 
                    end   

                    % ensures the time vector matches the experiment count
                    if length(TT{1}) < nExp
                        TT = cellfun(@(x)(repmat(x,1,nExp)),TT,'un',0);
                    end

                    % determines if the time is greater than a single day
                    if nDayMx > 1
                        % if so, then set the converted daily time vector        
                        dT = roundP(median(diff(TT{1}{1}),'omitnan'));
                        Tnw = ((dT/2):dT:(convertTime(1,'day','sec')-dT/2))';        
                        xiD = 1:nDayMx;

                        % sets the time vectors for each experiment
                        for j = 1:nExp        
                            % sets the ID/time vectors            
                            TTot = arrayfun(@(x)...
                                  (Tnw+(x-1)*tDay),xiD,'un',0);
                            iD{j,i} = cell2mat(arrayfun(@(x)...
                                  (x*ones(length(Tnw),1)),xiD(:),'un',0));
                            
                            % stores the new time vectors
                            T{j,1,i} = cell2mat(TTot(:));
                            T{j,2,i} = Tnw;
                        end
                    else    
                        % for each experiment, determine if data is for 
                        % more than one day. if so, then expand the time 
                        % vector for that experiment
                        for j = 1:nExp
                            if (nDay(j) > 1)
                                % expands the time vector for all days
                                xiD = 1:nDay(j);
                                Tnw = arrayfun(@(x)...
                                        (TT{1}{j}+(x-1)*tDay),xiD,'un',0);

                                % stores the new time vectors
                                T{j,1,i} = cell2mat(Tnw(:));
                                T{j,2,i} = TT{1}{j};
                            else
                                % otherwise, set the time vector for 
                                % both time vector types
                                [T{j,1,i},T{j,2,i}] = deal(TT{1}{j});
                            end
                        end
                    end    
                else
                    % otherwise, set the index based on the dependency
                    hasTime = false;
                    T0 = getStructField(obj.plotD,xDepTU{i});
                    if isnumeric(T0); T0 = num2cell(T0); end

                    nDayMx = max(nDay);
                    if length(T0) == nExp
                        [T(:,1,i),T(:,2,i)] = deal(T0,{T0});
                    else
                        T(:,1,i) = {repmat(T0,nDayMx,1)};
                        T(:,2,i) = {T0};
                    end

                    if nDayMx > 1
                        xiD = (1:nDayMx)';
                        iD(:,i) = {cell2cell(arrayfun(@(x)(num2cell(...
                                    x*ones(length(T0),1))),xiD,'un',0))};
                    else
                        iD(:,i) = {[]};
                    end
                end
            end               
            
            % loops through each index reshaping the metrics
            for i = 1:sum(obj.pType)
                % initialisations
                j = indU(i);                
                pVal = field2cell(obj.plotD,pStr{i});
                YY = obj.dataGroupSplit...
                            (iData,T(:,:,j),iD(:,j),pVal,fok,hasTime(j));

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
            iData.setData(Y,1+obj.iType);
            
        end                
        
    end
    
    % static class methods
    methods (Static)
        
        % --- splits the data (for each apparatus) to denote the separation 
        %     of the data (i.e., by either day or experiment)
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
                if (j == 1); Ynw = Ytmp; end
                
                
                for k = 1:nApp
                    if j == 1
                        % memory allocation
                        szMax = max(cell2mat...
                                    (cellfun(@size,Y{k}(:),'un',0)),[],1);
                        for i = 1:nExp; Y{k}(:,~fok{i}{k},i) = {[]}; end

                        % determines all empty cells for the metric
                        isE = cellfun(@isempty,Y{k});
                        for i = 1:size(isE,3)
                            if any(arr2vec(isE(:,:,i)))
                                % fills in the empty cells
                                YkT = Y{k}(:,:,i);
                                YkT(isE(:,:,i)) = {NaN(szMax)};
                                Y{k}(:,:,i) = YkT;
                            end
                        end 

                        % fills in any empty cells with NaN values
                        Ytmp = cellfun(@(x)...
                                    (cell2mat(x)),num2cell(Y{k},1),'un',0);     
                                
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

                        % determines the indices of first/last non-NaN rows
                        j0 = cellfun(@(x)(find...
                                (~all(isnan(x),2),1,'first')),YnwI,'un',0);
                        j1 = cellfun(@(x)(find...
                                (~all(isnan(x),2),1,'last')),YnwI,'un',0);  

                        % sets the first NaN row if no matches
                        ii0 = cellfun(@isempty,j0);
                        if any(ii0)
                           j0(ii0) = {1};                            
                        end
                        
                        % sets the last NaN row if no matches                        
                        ii1 = cellfun(@isempty,j1); 
                        if any(ii1)
                            j1(ii1) = cellfun(@(x)...
                                        (size(x,1)),YnwI(ii1),'un',0);
                        end
                    else
                        % sets the number of days
                        Ytmp{k} = cellfun(@(x)...
                                (cell2mat(x(:)')),num2cell(Y{k},1),'un',0);            
                    end
                end

                for k = 1:nApp 
                    switch j
                        case 1 
                            % case is signals are combined over all days

                            % resets the final combined output array
                            ind = cellfun(@(x,y)(x:y),j0,j1,'un',0);
                            Ygrp{j,k} = cellfun...
                                    (@(x,y)(x(y,:)),Ynw{k},ind,'un',0);

                        case 2
                            % case is signals are separated over all days                
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

        end
        
    end
    
end