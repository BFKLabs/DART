% --- sets up the parameter data array
function Data = setupParaDataArray(handles,iData)

% retrieves the global parameters
pData = getappdata(handles.figDataOutput,'pData');
hGUI = getappdata(handles.figDataOutput,'hGUI');
gP = getappdata(hGUI,'gPara'); 

% retrieves the 
iPara = iData.tData.iPara{iData.cTab};
iOrder = iPara{iData.tData.iSel(iData.cTab)}{1};

%
DataT = cell(length(iOrder),1);
for i = 1:length(iOrder)
    switch (iOrder(i))
        case (1) % case is the global parameters
            % retrieves the global parameter field names
            gPF = fieldnames(gP);
            
            % memory allocation
            DataT{i} = repmat({''},length(gPF)+3,2);
            DataT{i}{1,1} = 'Global Parameters';                                    
            
            % sets the calculation parameter values
            for j = 1:length(gPF)
                % retrieves the fields string based on the parameter string
                switch (gPF{j})
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
                        fStr = 'Stimuli Response Averaging Time-Window (frames)';
                    case ('dMove')
                        fStr = 'Sleep Inactivity Duration (min)';
                    case ('tSleep')
                        fStr = 'Activity Movement Distance (mm)';
                end
                
                % sets the global parameter field string
                DataT{i}{j+2,1} = fStr;                
                
                % retrieves the parameter value
                Ynw = eval(sprintf('gP.%s',gPF{j}));
                if (isnumeric(Ynw))
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
            
        case (2) % case is the calculation parameters
            % retrieves the calculation parameter struct                             
            cP = retParaStruct(pData.cP);
            [cPF,fName] = deal(fieldnames(cP),field2cell(pData.cP,'Name'));
            
            % memory allocation
            DataT{i} = repmat({''},length(cPF)+3,2);
            DataT{i}{1,1} = 'Calculation Parameters';
            DataT{i}(2+(1:length(fName)),1) = fName;
            
            % sets the calculation parameter values
            for j = 1:length(cPF)
                Ynw = eval(sprintf('cP.%s',cPF{j}));
                if (isnumeric(Ynw))
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
Data = combineCellArrays({'',''},cell2cell(DataT),0);