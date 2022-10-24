classdef SigPopReshape < handle
    
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
        function obj = SigPopReshape(iData,iType)
            
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
            Y = iData.getData(1+obj.iType);            
            yVar = iData.yVar(obj.pType);
            nApp = length(iData.appName);
            pStr = field2cell(yVar,'Var');
            
            % loops through each of the specified indices reshaping metrics
            for i = 1:sum(obj.pType)
                % sets the independent/dependent variable arrays
                X = arrayfun(@(x)(getStructField...
                                (x,yVar(i).xDep{1})),obj.plotD,'un',0); 
                YY = obj.dataGroupSplit(X,field2cell(obj.plotD,pStr{i}));

                % sets the signals for each of the 
                Y{i} = cell(nApp,1);
                for j = 1:nApp; Y{i}{j} = YY{j}; end
            end

            % sets the metric array into the overall data array
            iData.setData(Y,1+obj.iType);
            
        end                
        
    end
    
    % static class methods
    methods (Static)
        
        % --- splits the data (for each group) to denote the separation 
        %     of the data (i.e., by either day or experiment)
        function Ygrp = dataGroupSplit(X,Y)                     

            % memory allocation
            nApp = length(Y);
            Ygrp = cell(1,nApp);

            % loops through each apparatus, level and bin group
            for k = 1:nApp
                if iscell(Y{k})
                    Ytmp = cell2cell(cellfun...
                            (@(x)(num2cell(x,1)),Y{k},'un',0));        
                    Ygrp{k} = [X{k},cell2cell(cellfun(@(x)...
                            (cell2mat(x(:)')),num2cell(Ytmp,1),'un',0),0)];
                else
                    % appends the array together
                    if size(Y{k},1) == length(X{k})
                        Ygrp{k} = [X{k}(:),Y{k}];
                    else
                        Ygrp{k} = [X{k}(:),Y{k}(:)];
                    end
                end        
            end

        end
        
        
    end
end