% --- saves the stimuli data to a csv file
function saveCSVStimData(fFile,Ts,Tf,exptName,blkInfo,ChN)

% creates a loadbar
h = ProgressLoadbar('Setting Up Data Array...');

% sets the experiment names, stimuli parameters and start/finish arrays
DataExpt = setupExptInfo(exptName);
DataStim = setupStimTrainInfo(blkInfo,ChN);
DataTimes = setupStimTimesInfo(Ts,Tf);

% combines the data into a final array for output to file
Data0 = combineCellArrays(DataExpt,DataStim,0,'');
DataF = combineCellArrays(Data0,DataTimes,0,'');

% writes the data to file
if writeCSVFile(fFile,DataF,h)
    try; delete(h); end
end

% --- sets up the experiment information array
function DataExpt = setupExptInfo(exptName)

% memory allocation
nExpt = length(exptName);
DataExpt = cell(nExpt+2,3);

% sets the experiment information
DataExpt(1,1:end-1) = {'Expt #','Expt Name'};
DataExpt(2:(end-1),1) = arrayfun(@num2str,(1:nExpt)','un',0);
DataExpt(2:(end-1),2) = exptName(:);
DataExpt(cellfun(@isempty,DataExpt)) = {''};

% sets up the stimuli train info array
function DataStim = setupStimTrainInfo(blkInfo,ChN)

% memory allocation
nCol = 9;
nStim = length(blkInfo);
DataStim = cell(nStim+1,1);

% sets the header fields
DataStim{1} = {'Train #','Device','Signal','Protocol','Channel',...
               'Amplitude','Offset (s)','Cycle Dur. (s)',...
               'Total Dur. (s)','Count'};
             
% sets the stimuli information fields
for i = 1:nStim
    % memory allocation
    k = i + 1;
    nBlk = length(blkInfo{i});
    DataStim{k} = cell(nBlk,nCol);
    
    % struct field retrieval
    sType = blkInfo{i}(1).sType;
    dType = blkInfo{1}(1).devType;
    
    % sets the main stimuli fields
    DataStim{k}{1,1} = num2str(i);
    DataStim{k}{1,2} = dType;
    DataStim{k}{1,3} = sType;
    DataStim{k}{1,4} = blkInfo{i}(1).pType;
    DataStim{k}{1,5} = setChannelString(ChN{i},dType);
    
    % sets the stimuli block parameters
    for j = 1:nBlk
        % retrieves the signal parameters
        sP = blkInfo{i}(j).sPara;
        tMltDur = getTimeMultiplier('s',sP.tDurU);
        tMltOfs = getTimeMultiplier('s',sP.tOfsU);
        
        % sets the amplitude/duration strings based on signal type
        switch sType
            case 'Square'
                % sets the amplitude string
                ampStr = num2str(sP.sAmp);
                
                % sets the cycle duration string
                tOn = getTimeMultiplier('s',sP.tDurOnU)*sP.tDurOn;
                if sP.nCount == 1
                    durStr = num2str(tOn);
                else                
                    tOff = getTimeMultiplier('s',sP.tDurOffU)*sP.tDurOff;
                    durStr = sprintf('%s/%s',num2str(tOn),num2str(tOff));
                end
                
            case 'Motor'
                % sets the amplitude string
                ampStr = sprintf('%s/%s',sP.sAmp0,sP.sAmp1);
                
                % sets the cycle duration string
                tCycle = getTimeMultiplier('s',sP.tCycleU)*sP.tCycle;
                durStr = num2str(tCycle);
        end
        
        % sets the stimuli parameters
        DataStim{k}{j,6} = ampStr;
        DataStim{k}{j,7} = num2str(tMltOfs*sP.tOfs);
        DataStim{k}{j,8} = durStr;
        DataStim{k}{j,9} = num2str(tMltDur*sP.tDur);
        DataStim{k}{j,10} = num2str(sP.nCount);
    end
end

% combines the arrays and fills in any missing entries
DataStim = cell2cell(DataStim);
DataStim(cellfun(@isempty,DataStim)) = {''};
DataStim = combineCellArrays(DataStim,{''},0,'');

% --- sets up the stimuli time information arrays
function DataTimes = setupStimTimesInfo(Ts,Tf)

% memory allocation
nStim = length(Ts);
DataTimes = cell(nStim,2);

% other initialisations
rOfs = 2;
tStr = {'Stim #'};

%
for i = 1:nStim
    % data extraction and other local memory allocations
    ii = find(~cellfun(@isempty,Ts{i}));
    TsNw = combineNumericCells(Ts{i}(ii));
    TfNw = combineNumericCells(Tf{i}(ii));
    hStr0 = arrayfun(@(x)(sprintf('Expt #%i',x)),ii(:)','un',0);
    nStimMx = size(TsNw,1);
    
    % creates the temporary arrays
    A = cell(nStimMx+(2+rOfs),length(ii)+2);
    A(1+rOfs,1:(end-1)) = [tStr,hStr0];
    A((rOfs+2):(end-1),1) = arrayfun(@num2str,(1:nStimMx)','un',0);        

    % sets the stimuli start/finish times
    [DataTimes{i,1},DataTimes{i,2}] = deal(A);
    DataTimes{i,1}((rOfs+2):(end-1),(2:end-1)) = num2cell(TsNw);
    DataTimes{i,2}((rOfs+2):(end-1),(2:end-1)) = num2cell(TfNw);
    
    % sets the title headers
    DataTimes{i,1}{1,1} = sprintf('Start Times (Train Type #%i)',i);
    DataTimes{i,2}{1,1} = sprintf('Finish Times (Train Type #%i)',i);
end

% combines the arrays and fills in any missing entries
DataTimes = cell2cell(cellfun(@(x)...
                        (cell2cell(x,0)),num2cell(DataTimes,2),'un',0));
DataTimes(cellfun(@isempty,DataTimes)) = {''};                    
                    
%
isN = cellfun(@isnumeric,DataTimes);
DataTimes(isN) = cellfun(@num2str,DataTimes(isN),'un',0);

% --- sets the channel type strings
function ChStr = setChannelString(ChN,dType)

% sets the channel string based on the type
switch dType
    case 'Opto'
        % case is using the optogenetics (only use first character of
        % channel name)
        ChStr = strjoin(cellfun(@(x)(x(1)),ChN{1}(:)','un',0),'/');
        
    case 'Motor'
        % case is using the motor
        if strcmp(ChN{1}{1},'Ch')
            % case is all motors are fired simultaneously
            ChStr = 'Ch';
        else
            % case is individual motor(s) are fired
            A = cellfun(@(x)(getArrayVal...
                                    (strsplit(x,'#'))),ChN{1}(:),'un',0);
            ChStr = strjoin(A(:)','/');
        end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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