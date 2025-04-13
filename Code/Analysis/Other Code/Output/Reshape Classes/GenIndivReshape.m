classdef GenIndivReshape < handle
    
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
        function obj = GenIndivReshape(iData,iType)
            
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
                Y0 = field2cell(obj.plotD,pStr{i});
                YY = obj.dataGroupSplit(Y0,pStr{i}); 

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
        
        % --- splits the data
        function Ygrp = dataGroupSplit(Y,pStr) 

            % memory allocation
            nApp = length(Y);
            Ygrp = cell(1,nApp);
            
            switch pStr
                case 'tImmobF'
                    [lblX,lblY] = deal('Fly','Stimuli');
                    
                otherwise
                    [lblX,lblY] = deal('Cell');
            end

            % loops through each apparatus converting the 2D array data
            for i = 1:nApp
                % memory allocation
                Ygrp{i} = cell(1,length(Y{i}));

                % sets the values for each group
                for j = 1:length(Y{i})
                    % sets the x/y strings
                    [nGY,nGX] = size(Y{i}{j});
                    tStrY = arrayfun(@(x)...
                            (sprintf('%s #%i',lblX,x)),1:nGX,'un',0);
                    tStrX = arrayfun(@(x)...
                            (sprintf('%s #%i',lblY,x)),1:nGY,'un',0)';

                    % memory allocation
                    Ygrp{i}{j} = cell(nGY+1,nGX+1);
                    Ygrp{i}{j} = num2cell(Y{i}{j});
                    Ygrp{i}{j}(isnan(Y{i}{j})) = {''};

                    % adds the x/y axis titles
                    Ygrp{i}{j} = combineCellArrays(tStrY,Ygrp{i}{j},0);
                    Ygrp{i}{j} = combineCellArrays([{''};tStrX],Ygrp{i}{j});
                end
            end                    
        end
        
    end
    
end