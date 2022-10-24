classdef GenIndivData < DataOutputArray
    
    % class properties
    properties

        % string/index array fields        
        mIndG
        mStrH
        appName        
        
        % data array fields
        YR
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = GenIndivData(hFig) 
            
            % creates the super-class object
            obj@DataOutputArray(hFig);            
            
            % sets up the data array
            obj.initClassFields();
            obj.setupDataArray();
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % reduces down the output data array
            obj.YR = cellfun(@(x)(x(obj.appOut)),obj.Y(obj.iOrder),'un',0); 
            
            % sets the main headers
            mStrH0 = {'Genotype';'Metric';'Fly #';''};
            obj.mStrH = [mStrH0,repmat({''},4,1)];
            
            % sets the global metric indices
            Type = field2cell(obj.iData.yVar,'Type',1); 
            mIndG0 = find(Type(:,7));
            obj.mIndG = mIndG0(obj.iOrder);
            
            % sets the other imporant fields
            obj.mStrB = obj.iData.fName(obj.mIndG);
            obj.appName = obj.iData.appName(obj.appOut);
            
        end
        
        % --- sets up the data output array
        function setupDataArray(obj)

            % sets up the header/data values for the output array
            obj.setupMetricData();
            
            % combines the final output data array
            obj.setupFinalDataArray();            
            
        end                
        
        % ---------------------------------- %
        % --- DATA ARRAY SETUP FUNCTIONS --- %
        % ---------------------------------- %          
        
        % --- sets up the metric data strings
        function setupMetricData(obj)
            
            % memory allocation
            DataT = cell(obj.nMet,1);
            
            % sets up the final data output array
            for i = 1:obj.nMet
                % memory allocation
                DataT{i} = cell(1,obj.nApp);
                obj.mStrH{1,2} = obj.mStrB{i};

                % sets the individual data arrays
                for j = 1:obj.nApp
                    YRnw = obj.YR{i}{j};
                    obj.mStrH{2,2} = obj.appName{j};
                    DataT{i}{j} = obj.setIndivArrays(obj.mStrH,YRnw);
                end

                % combines the data array over each group
                DataT{i} = cell2cell(DataT{i},0);
            end
            
            % combines the individual arrays into a single array
            obj.Data = cell2cell(DataT);            
            
        end        
        
        % --- combines the header & metric data arrays into the final array
        function setupFinalDataArray(obj)
            
            % removes any NaN values from the final data array
            isN = find(cellfun(@isnumeric,obj.Data));
            iiFN = isN(cellfun(@isnan,obj.Data(isN)));

            % removes any NaN values and converted the integer/float values
            kk = cellfun(@(x)(mod(x,1) == 0),obj.Data(isN));
            obj.Data(isN(kk)) = num2strC(obj.Data(isN(kk)),'%i');
            obj.Data(isN(~kk)) = num2strC(obj.Data(isN(~kk)),'%.4f');
            obj.Data(iiFN) = {''};

            % adds in a spacer row/column
            [m,n] = size(obj.Data);
            obj.Data = combineCellArrays(repmat({''},m,1),obj.Data);
            obj.Data = combineCellArrays(repmat({''},1,n),obj.Data,0);
            
        end
        
    end
    
    % static class methods
    methods (Static)
        
        % --- sets the combined header/metric arrays
        function DataT = setIndivArrays(mStrH,Y)

            % memory allocation
            DataT = cell(length(Y),1);

            % sets the data values for each metric
            for i = 1:length(Y)
                % sets the main header string index
                mStrH{3,2} = sprintf('%i',i);

                % combines the data into 
                DataT0 = combineCellArrays(mStrH,Y{i},0);
                DataT0 = combineCellArrays(DataT0,{NaN});
                DataT{i} = combineCellArrays(DataT0,{NaN},0);    
            end

            % combines the cell arrays into a single array
            DataT = cell2cell(DataT,1);
        
        end
        
    end
    
end