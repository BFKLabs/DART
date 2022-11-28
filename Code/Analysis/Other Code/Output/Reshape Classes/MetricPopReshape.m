classdef MetricPopReshape < handle
    
    % class properties
    properties

        % main class fields
        plotD
        pType        
        snTot
        
        % scalar class fields
        iType
        ind
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = MetricPopReshape(pObj,iType,ind)
            
            % sets the default input arguments
            if ~exist('ind','var'); ind = 1:sum(pObj.Type(:,iType)); end
            
            % sets the input arguments
            [obj.iType,obj.ind] = deal(iType,ind);
            
            % initialises the class fields and reshapes the metric data
            obj.initClassFields(pObj);            
            obj.reshapeMetricData(pObj);
            
        end
        
        % --- initialises the object class fields
        function initClassFields(obj,pObj)
           
            % field retrieval
            obj.pType = pObj.Type(:,obj.iType);
            obj.plotD = getappdata(pObj.hFig,'plotD');
            obj.snTot = getappdata(pObj.hFig,'snTot');
            
        end
            
        % --- sets up the data output array
        function reshapeMetricData(obj,iData)
            
            % sets the index array for the data output
            YT = iData.getData(1+obj.iType);
            yVar = iData.yVar(obj.pType);
            pStr = field2cell(yVar(obj.ind),'Var');
            nApp = length(iData.appName);
            
            % retrieves the data array
            mInd = iData.tData.iPara{iData.cTab}{2}{2};
            mInd = mInd & cellfun('isempty',YT(:,:,1));

            % loops through each specified index reshaping the metrics
            for j = 1:length(obj.ind)
                % initialisations
                i = obj.ind(j);
                Ytmp = field2cell(obj.plotD,pStr{j});
                YY = obj.dataGroupSplit(iData,Ytmp,obj.snTot);

                % retrieves the calculated values
                for iMet = find(mInd(i,:))
                    % determines the metric variable string
                    vName = ind2varStat(iMet);

                    % sets the metrics for each of the levels
                    for iLvl = 1:size(YT,3)  
                        % calculates the metrics for each of the 
                        Ymet = cell(nApp,1);
                        for iApp = 1:nApp
                            if ~isempty(YY{iLvl,iApp})
                                Ymet{iApp} = ...
                                    calcMetrics(YY{iLvl,iApp},vName);
                            end                            
                        end

                        % sets the final data array into the overall array
                        YT{i,iMet,iLvl} = Ymet;                
                    end
                end           
            end

            % sets the metric array into the overall data array
            iData.setData(YT,1+obj.iType);            
            
        end                
        
    end
    
    % static class methods
    methods (Static)
        
        % --- splits the data (for each apparatus) to denote the separation
        %     of the data (i.e., by either day or experiment)
        function Ygrp = dataGroupSplit(iData,Y,snTot)

            % Ygrp Convention
            %
            % 1st Level - metrics calculated over all days/expts
            % 2nd Level - metrics calculated over all days/individual expts
            % 3rd Level - metrics calculated over individual days/all expts
            % 4th Level - metrics calculated over individual days/expts

            % memory allocation
            nExp = length(snTot);
            [nApp,nLvl] = deal(length(Y),4);
            Ygrp = cell(nLvl,nApp);

            % loops through each apparatus, level and bin group
            for j = 1:nLvl
                for k = 1:nApp
                    switch j
                        case (1) 
                            % metrics for all days/experiments                
                            Ytmp = cellfun(@(x)(cell2mat(cell2cell(x))),...
                                      num2cell(num2cell(Y{k},1),3),'un',0);
                            Ygrp{j,k} = {cell2mat(Ytmp(:))};

                        case (2) 
                            % metrics calculated for all experiments

                            % only set if multiple experiments   
                            if iData.sepExp
                                Ygrp{j,k} = cell(1,nExp);
                                for i = 1:nExp  
                                    Ytmp = cellfun(@(x)(cell2mat(x)),...
                                        num2cell(Y{k}(:,:,i),1),'un',0);
                                    Ytmp(cellfun('isempty',Ytmp)) = {NaN};

                                    Ygrp{j,k}{i} = cell2mat(Ytmp(:));
                                end
                            end
                            
                        case (3) 
                            % metrics calculated for all days 

                            % only set if multiple days
                            if iData.sepDay
                                Ygrp{j,k} = cell(size(Y{k},1),1);
                                for i = 1:size(Y{k},1)
                                    Ytmp = cellfun(@(x)(cell2mat(x)),...
                                        num2cell(reshape(Y{k}(i,:,:),...
                                        [nExp,size(Y{k},2)]),1),'un',0);                        
                                    Ygrp{j,k}{i} = cell2mat(Ytmp(:));
                                end
                            end
                            
                        case (4) 
                            % individual metrics for all days/expts

                            % only set if multiple days/experiments
                            if iData.sepExp && iData.sepDay
                                Ygrp{j,k} = cell(size(Y{k},1),nExp);
                                for i1 = 1:size(Y{k},1)
                                    for i2 = 1:nExp
                                        Ygrp{j,k}{i1,i2} = ...
                                                cell2mat(Y{k}(i1,:,i2)');
                                    end
                                end
                            end
                    end            
                end
            end
        end    
        
    end
    
end