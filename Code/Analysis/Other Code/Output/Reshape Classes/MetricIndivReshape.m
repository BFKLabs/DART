classdef MetricIndivReshape < handle
    
    % class properties
    properties

        % main class fields
        plotD
        pType
        
        % scalar class fields
        iType
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = MetricIndivReshape(iData,iType)
            
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
            
        end
            
        % --- sets up the data output array
        function reshapeMetricData(obj,iData)
            
            % sets the index array for the data output
            ind = 1:sum(obj.pType);   
            Y = iData.getData(1+obj.iType);
            nApp = length(iData.appName);
            pStr = field2cell(iData.yVar(obj.pType),'Var');

            % retrieves the data array
            nGrp = detDataGroupSize(iData,obj.plotD,find(obj.pType),1);

            % ensures the group size is the same as the 
            if length(nGrp) ~= length(ind)
                nGrp = nGrp*ones(length(ind),1); 
            end

            % loops through each specified index reshaping the metrics
            for j = 1:length(ind)
                % initialisations
                i = ind(j);
                Ytmp = field2cell(obj.plotD,pStr{i});
                YY = obj.dataGroupSplit(iData,Ytmp,nGrp(j),obj.plotD);

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
                                Y{i,iLvl}{iApp} = cellfun(@(x,y)...
                                    (obj.stripDataRows(x,y)),...
                                    Y{i,iLvl}{iApp},YY{iLvl,iApp,iGrp},...
                                    'un',0);
                            end
                        end
                    end
                end
            end

            % sets the metric array into the overall data array
            iData.setData(Y,1+obj.iType);
            
        end                        

        % --- splits the data (for each apparatus) to denote the separation
        %     of the data (i.e., by either day or experiment)
        function Ygrp = dataGroupSplit(obj,iData,Y,nGrp,p)

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

            % sets the metric combination type
            if isfield(p(1),'indCombMet')
                cType = p(1).indCombMet;
            else
                cType = 'mn';
            end
            
            % loops through each apparatus, level and bin group
            for k = 1:nApp
                % retrieves the values for each 
                for iGrp = 1:1+iData.sepGrp
                    Y{k}(cellfun('isempty',Y{k})) = ...
                                        {NaN(1+iData.sepGrp,nGrp)};            
                    if iData.sepGrp
                        Ynw = cellfun(@(y)(cellfun...
                                (@(x)(x(iGrp,y)),Y{k})),xiG,'un',0);            
                    else            
                        Ynw = cellfun(@(y)(cellfun...
                                (@(x)(x(y)),Y{k})),xiG,'un',0);
                    end
                    
                    [~,~,nExp] = size(Ynw{1});
                    for j = 1:nLvl
                        for i = 1:nExp
                            Ygrp{j,k,iGrp}(:,:,i) = ...
                                    obj.setLevelMetrics(Ynw,j,i,cType);                                       
                        end                     
                    end
                end
            end        
        end           
        
    end
    
    % static class methods
    methods (Static)
       
        % --- sets the metrics for a given level
        function YnwL = setLevelMetrics(Ynw,iLvl,iExpt,cType)
            
            function YY = setMetStrings(YY0)
               
                isN = isnan(YY0);
                YY = string(YY0);
                YY(isN) = '';
                
            end
            
            switch iLvl
                case 1 
                    % case is metrics for all days                                
                    Ymet = cellfun(@(x)(x(:,:,iExpt)),Ynw,'un',0);
                    YnwL = cellfun(@(x)...
                                (x'),calcMetrics(Ymet,cType),'un',0);
                    
                case 2 
                    % case is metrics for each day
                    YnwL = cellfun(@(x)...
                                (setMetStrings(x(:,:,iExpt))'),Ynw,'un',0);
            end             
            
        end        
        
        % --- strips the rows of the two arrays, X & Y
        function XY = stripDataRows(X,Y)
            
            % memory allocation
            [nX,nC] = size(X);
            XY = strings(2*nX,nC);
            
            % sets the 
            iXY = 1:2:2*nX;
            [XY(iXY,:),XY(iXY+1,:)] = deal(X,Y);
            
        end        
        
    end
    
end