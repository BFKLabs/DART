classdef MetricFixedReshape < handle
    
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
        function obj = MetricFixedReshape(iData,iType)
            
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
            pStr = field2cell(yVar,'Var');
            ind = 1:length(pStr); 

            % loops through each of the specified indices calculating the metrics
            for j = 1:length(ind)
                % initialisations
                Ynw = field2cell(obj.plotD,pStr{ind(j)});
                if iscell(Ynw{1})
                    Y{j} = cellfun(@(x)(cell2cell(x)),Ynw,'un',0);    
                else
                    Y{j} = cellfun(@(x)(x),Ynw,'un',0);
                end
            end

            % sets the metric array into the overall data array
            iData.setData(Y,1+obj.iType);            
            
        end                
        
    end
end