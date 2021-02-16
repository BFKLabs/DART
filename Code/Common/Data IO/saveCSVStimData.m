% --- saves the stimuli data to a csv file
function saveCSVStimData(fFile,Stim,Ts,Tf,exptName)

% creates a loadbar
h = ProgressLoadbar('Setting Up Data Array...');

% sets up the stimuli data array
Data = setupStimDataArray(Stim,Ts,Tf,exptName);

% writes the data to file
if (writeCSVFile(fFile,Data,h))
    try; delete(h); end
end

% --- sets up the stimuli data array
function Data = setupStimDataArray(Stim,Ts,Tf,exptName)

% initialisations
[nExpt,Data] = deal(length(Stim),{NaN});

% sets up the stimuli data for each of the experiments
for i = 1:nExpt
    DataNw = setupStimDataSingle(Stim{i},exptName{i},Ts{i},Tf{i},i,nExpt);
    Data = combineCellArrays(combineCellArrays(Data,DataNw),{NaN});
end

% --- sets up the stimuli data for a single experiment
function Data = setupStimDataSingle(Stim,exptName,Ts,Tf,indExpt,nExpt)

% sets the number of stimuli events
nCh = length(Stim);
Tsig = field2cell(Stim,'Tsig');
pStr = {'pDur','pAmp','iDelay','pDelay','sDelay'};

% determines the longest time signal in the experiment
imx = cellfun(@(x)(argMax(cellfun(@length,x))),Tsig);
[~,jmx] = max(cellfun(@(x,y)(length(x{y})),Tsig,num2cell(imx)));
DataYT = num2cell(Tsig{jmx}{imx(jmx)});

% sets the main header data information
DataHM = cell(7,2);
DataHM(2,:) = {'Experiment Index',sprintf('%i of %i',indExpt,nExpt)};
DataHM(3,:) = {'Experiment Name',exptName};
DataHM(4,:) = {'Channel Count',nCh};
DataHM(5,:) = {'Stimuli Count',length(Stim(1).sigPara)};
DataHM(6,1) = {'Train Count'};

% sets the stimuli train count
if (range(cellfun(@length,Stim(1).sigPara)) == 0)
    % stimuli train count is fixed
    [DataHM{6,2},nTrain] = deal(length(Stim(1).sigPara{1}));
else
    % stimuli train count is random
    [DataHM{6,2},nTrain] = deal('Random',1);
end

% sets the data header titles and signal data
[DataHT,hInd] = deal(cell(14,1),[4:8,10:12,14]);
DataHT(hInd) = {'Pulse Duration (s)';'Amplitude';'Inter-Pulse Delay (s)';...
                'Inter-Stimuli Delay (s)';'Initial Delay (s)';'Stimuli #';...
                'Start Time (s)';'Finish Time (s)';'Time (s)'};
     
% sets the parameters/signals for each of the channels/stimuli events
for i = 1:nCh
    % memory allocation
    [nStim,sgP] = deal(length(Ts),Stim(i).sigPara);    
    [xiS,xiT] = deal(1:nStim,1:nTrain);
    
    % memory allocation 
    DataT = cell(size(DataHT,1),max(nStim,nTrain));
    DataT{1,1} = sprintf('Channel #%i',i);      
    DataT(3,xiT) = cellfun(@(x)(sprintf('Train #%i',x)),num2cell(xiT),'un',0);
    
    % sets the stimuli parameters for each of the trains
    for j = 1:length(pStr)
        eval(sprintf('Y = field2cell(sgP{1},''%s'');',pStr{j})); 
        if (length(Y) == nTrain)
            ii = (cellfun(@range,Y) == 0); 
            DataT(3+j,ii) = cellfun(@(x)(x(1)),Y,'un',0); 
            DataT(3+j,~ii) = repmat({'Random'},1,sum(~ii)); 
        else
            if (range(Y{1}) == 0) 
                DataT{3+j,1} = num2cell(Y{1}(1)); 
            else
                DataT{3+j,1} = 'Random'; 
            end
        end
    end
    
    % sets the stimuli start/finish times
    DataT(10,xiS) = cellfun(@(x)(sprintf('#%i',x)),num2cell(xiS),'un',0);
    DataT(11,xiS) = num2cell(Ts(:)');
    DataT(12,xiS) = num2cell(Tf(:)');
    
    % sets the stimuli signal traces
    DataHT = combineCellArrays(combineCellArrays(DataHT,DataT),{NaN});
    
    % appends the new signal values to the overall array
    nanGap = num2cell(NaN(1,1+(i<nCh)*max(0,nTrain-nStim)));
    DataYnw = num2cell(cell2mat(Stim(1).Ysig(xiS)'));
    DataYT = combineCellArrays(combineCellArrays(DataYT,DataYnw),nanGap);
end

% combines the data into a single array
Data = combineCellArrays(combineCellArrays(DataHM,DataHT,0),DataYT,0);
Data(cellfun(@isempty,Data)) = {NaN};