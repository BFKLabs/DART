classdef GenPopData < DataOutputArray
    
    % class properties
    properties
        
        % string/index array fields        
        mIndG
        mStrH
        mStrB
        appName        
        
        % data array fields
        YR        
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = GenPopData(hFig,hProg)                        
            
            % creates the super-class object
            obj@DataOutputArray(hFig,hProg);            
            
            % sets up the data array
            obj.initClassFields();
            obj.setupDataArray();
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % reduces down the output data array
            obj.YR = cellfun(@(x)(x(obj.appOut)),obj.Y(obj.iOrder),'un',0); 
            
            % sets the main headers
            mStrH0 = {'Genotype';'Metric';''};
            obj.mStrH = [mStrH0,repmat({''},length(mStrH0),1)];
            
            % sets the global metric indices
            Type = field2cell(obj.iData.yVar,'Type',1); 
            mIndG0 = find(Type(:,6));
            obj.mIndG = mIndG0(obj.iOrder);
            
            % sets the other imporant fields
            obj.mStrB = obj.iData.fName(obj.mIndG);
            obj.appName = obj.iData.appName(obj.appOut);
            
        end        
        
        % --- sets up the data output array
        function setupDataArray(obj)
            
            % sets up the header/data values for the output array
            obj.setupMetricData();                        
            
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
                [a,b] = deal({''},'');
                DataT{i} = cell(1,obj.nApp);
                obj.mStrH{1,2} = obj.mStrB{i};

                % sets the individual data arrays
                for j = 1:obj.nApp
                    % updates the header string for the group name
                    obj.mStrH{2,2} = obj.appName{j};

                    % combines the metric data values
                    YRnw = obj.YR{i}{j};                    
                    DataT0 = combineCellArrays(obj.mStrH,YRnw,0,b);
                    DataT0 = combineCellArrays(DataT0,a,1,b);
                    DataT{i}{j} = combineCellArrays(DataT0,a,0,b);                    
                end

                % combines the data array over each group
                DataT{i} = cell2cell(DataT{i},0);
            end
            
            % combines the individual arrays into a single array
            obj.combineFinalArray(DataT);
            
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
end