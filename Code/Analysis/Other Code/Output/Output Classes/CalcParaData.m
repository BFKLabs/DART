classdef CalcParaData < DataOutputArray 
    
    % class properties
    properties
        
        % main class parameters
        gPara
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = CalcParaData(hFig) 
            
            % creates the super-class object
            obj@DataOutputArray(hFig);            
            
            % sets up the data array
            obj.initClassFields();
            obj.setupDataArray();
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % sets the metric order index array
            iPara = obj.iData.tData.iPara{obj.cTab};
            obj.iOrder = iPara{obj.iData.tData.iSel(obj.cTab)}{1};            
            
            % retrieves the global parameters
            hGUI = getappdata(obj.hFig,'hGUI');
            obj.gPara = getappdata(hGUI,'gPara');
            
        end        
        
        % --- sets up the data output array
        function setupDataArray(obj)
            
            % memory allocation
            DataT = cell(length(obj.iOrder),1);
            
            % sets the data for each parameter
            for i = 1:length(obj.iOrder)
                switch obj.iOrder(i)
                    case (1) 
                        % case is the global parameters
                        
                        % retrieves the global parameter field names
                        gPF = fieldnames(obj.gPara);

                        % memory allocation
                        DataT{i} = repmat({''},length(gPF)+3,2);
                        DataT{i}{1,1} = 'Global Parameters';                                    

                        % sets the calculation parameter values
                        for j = 1:length(gPF)
                            % sets the global parameter field string
                            fStr = obj.getGlobalParaString(gPF{j});                            
                            DataT{i}{j+2,1} = fStr;                

                            % retrieves the parameter value
                            Ynw = getStructField(obj.gPara,gPF{j});
                            if isnumeric(Ynw)
                                % new value is numeric
                                if mod(Ynw,1) == 0
                                    % value is an integer
                                    DataT{i}{j+2,2} = sprintf('%i',Ynw);    
                                else
                                    % value is a double
                                    DataT{i}{j+2,2} = sprintf('%.4f',Ynw);    
                                end
                            else
                                % new value is a string
                                DataT{i}{j+2,2} = Ynw;
                            end                
                        end

                    case (2) 
                        % case is the calculation parameters
                        
                        % retrieves the calculation parameter struct                             
                        cP = retParaStruct(obj.pData.cP);
                        fName = field2cell(obj.pData.cP,'Name');

                        % memory allocation
                        cPF = fieldnames(cP);                        
                        DataT{i} = repmat({''},length(cPF)+3,2);
                        DataT{i}{1,1} = 'Calculation Parameters';
                        DataT{i}(2+(1:length(fName)),1) = fName;

                        % sets the calculation parameter values
                        for j = 1:length(cPF)
                            Ynw = eval(sprintf('cP.%s',cPF{j}));
                            if isnumeric(Ynw)
                                % new value is numeric
                                if (mod(Ynw,1) == 0)
                                    % value is an integer
                                    DataT{i}{j+2,2} = sprintf('%i',Ynw);    
                                else
                                    % value is a double
                                    DataT{i}{j+2,2} = sprintf('%.4f',Ynw);    
                                end
                            else
                                % new value is a string
                                DataT{i}{j+2,2} = Ynw;
                            end
                        end            
                end
            end

            % sets the final data array
            obj.Data = combineCellArrays({'',''},cell2cell(DataT),0);            
            
        end                
        
    end
    
    % static class methods
    methods (Static)
        
        % --- retrieves the global parameter string
        function fStr = getGlobalParaString(gpStr)

            % retrieves the fields string based type
            switch gpStr
                case ('Tgrp0')
                    fStr = 'Day Cycle Start Hour';
                case ('TdayC')
                    fStr = 'Day Cycle Duration (Hours)';
                case ('movType')
                    fStr = 'Movement Calculation Type';
                case ('pWid')
                    fStr = 'Mid-Line Crossing Location';
                case ('tNonR')
                    fStr = 'Post-Stimuli Event Response Time (sec)';
                case ('nAvg')
                    fStr = 'Stimuli Response Averaging Window (frames)';
                case ('dMove')
                    fStr = 'Sleep Inactivity Duration (min)';
                case ('tSleep')
                    fStr = 'Activity Movement Distance (mm)';
            end

        end
        
    end
end