classdef GenPopReshape < handle
    
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
        function obj = GenPopReshape(iData,iType)
            
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
            nApp = length(iData.appName);            

            % sets the data arrays for each metric
            for i = 1:length(pStr)
                % initialisations
                YY = obj.dataGroupSplit(field2cell(obj.plotD,pStr{i})); 

                % sets the signals for each of the 
                Y{i} = cell(nApp,1);
                for j = 1:nApp; Y{i}{j} = YY{j}; end
            end

            % sets the 2D data array into the overall data array
            iData.setData(Y,1+obj.iType);
            
        end                
        
    end
    
    % static class methods
    methods (Static)
        
        % --- splits and recombines the metric data group 
        function Ygrp = dataGroupSplit(Y) 

            % memory allocation
            nApp = length(Y);
            Ygrp = cell(1,nApp);

            % loops through each apparatus converting the 2D array data
            for i = 1:nApp
                % sets the x/y strings
                [nGY,nGX] = size(Y{i});
                tStrY = arrayfun(@(x)(sprintf('Cell #%i',x)),1:nGX,'un',0);
                tStrX = arrayfun(@(x)(sprintf('Cell #%i',x)),1:nGY,'un',0)';

                % memory allocation
                Ygrp{i} = cell(nGY+1,nGX+1);

                % sets the final values and removes NaN entries
                Ygrp{i} = num2cell(Y{i});
                Ygrp{i}(isnan(Y{i})) = {''};

                % adds the x/y axis titles
                Ygrp{i} = combineCellArrays(tStrY,Ygrp{i},0);
                Ygrp{i} = combineCellArrays([{''};tStrX],Ygrp{i});
            end

        end
        
    end
    
end