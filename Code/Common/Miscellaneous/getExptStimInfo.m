% --- retrieves the experiment stimuli information
function [stimP,sTrainEx] = getExptStimInfo(sObj,Tv)

% initialisations
[stimP,sTrainEx,sData] = deal([]);

% retrieves the stimuli data based on the input type
if ischar(sObj)
    % case is the summary file name has been provided
    [summFile,useSolnFile] = deal(sObj,false);
    if exist(summFile,'file')  
        try
            sData = load(summFile); 
        catch
            sData = importdata(summFile,'-mat');
        end
    end
    
elseif isstruct(sObj)
    % case is the stimuli information data struct has been provided
    % (conversion of old format type to new)
    [sData,useSolnFile] = deal(sObj,true);
end

% if there is no stimuli data, then exit the function
if isempty(sData) || ~isfield(sData,'iExpt')
    return
end

% determines if the experiment was recording only
if strcmp(sData.iExpt.Info.Type,'RecordOnly')
    % if so, then return an empty
    stimP = [];
    
else
    % retrieves the stimuli information based on the stimuli setup type
    if isfield(sData,'sTrain')
        % case is the new stimuli train setup is being used
        if ~isempty(sData.sTrain)
            sTrainEx = sData.sTrain.Ex;
            stimP = getStimInfo(sTrainEx);
        end
        
    else
        % case is the old stimuli train setup is being used
        sParaT = struct('sTrain',convertStimData(sData,useSolnFile));
        [~,sTrainEx] = convertExptData([],sParaT.sTrain,sData.iExpt);        
        
        % retrieves the stimuli information 
        stimP = getStimInfo(sTrainEx,sData);        
    end
end

% if a 2nd argument is provided (the solution file data) then reduce the 
% experiment stimuli data for that video only
if ~isempty(stimP)
    if exist('Tv','var')
        % if a time vector is provided, then use this to limit the times
        if isempty(Tv)
            % if the time vector is empty, then use the entire expt
            stimP = reduceExptStimInfo(stimP);
        else
            % otherwise, reduce the time vector to the expt window
            stimP = reduceExptStimInfo(stimP,Tv([1,end]));
        end
    else
        % if there is no time vector, then use the entire experiment
        stimP = reduceExptStimInfo(stimP);
    end
end

% ----------------------------------------------- %
% --- STIMULI INFORMATION RETRIEVAL FUNCTIONS --- %
% ----------------------------------------------- %

% --- retrieves the stimuli information (new experiment parameter format)
function stimP = getStimInfo(sPara,snTot)

% if there is no stimuli data, then exit
if isempty(sPara.sTrain)
    stimP = [];
    return
end

% initialisations
pStr0 = struct('Ts',[],'Tf',[],'iStim',[]);
if ~exist('snTot','var'); snTot = []; end

% determines the unique devices/channels used in the experiment
t0 = cell2table([sPara.sTrain(1).devType,sPara.sTrain(1).chName]);
tArr0 = table2cell(unique(t0,'rows'));

% sets the struct information for each device/channel listed
stimP = struct();
for i = 1:size(tArr0,1)
    % sets the device type and channel name
    dT = regexprep(tArr0{i,1},'[ #]','');
    chN = regexprep(tArr0{i,2},'[ #]','');
    
    % if the device type sub-field is missing, then initialise
    if ~isfield(stimP,dT)
        stimP = setStructField(stimP,dT,struct());
    end
    
    % appends the field
    stimPS = getStructField(stimP,dT);
    if ~isfield(stimP,chN)
        stimPS = setStructField(stimPS,chN,pStr0);
    end
    
    % resets the channel struct into the device type struct
    stimP = setStructField(stimP,dT,stimPS);
end

% for each experiment, determine the start/end time of each 
for iStim = 1:length(sPara.sTrain)
    % calculates the stimuli train offsets (wrt the expt start)
    sParaEx = sPara.sParaEx(iStim);
    nC = sParaEx.nCount;
    tOfs = sParaEx.tOfs*getTimeMultiplier('s',sParaEx.tOfsU);           
    tS0 = tOfs + vec2sec(sParaEx.tStim)*(0:(nC-1))';
    
    % calculates the time limits for each stimuli train with the protocol
    sTrain = sPara.sTrain(iStim);           
    sParaB = field2cell(sTrain.blkInfo,'sPara',1);    
    tOfsB = arrayfun(@(x)(scaleTimeValue(x,'tOfs')),sParaB);
    tDurB = arrayfun(@(x)(scaleTimeValue(x,'tDur')),sParaB);
    tLim0 = [tOfsB,(tOfsB+tDurB)];
    
    % determines the unique group of channels that are used within the
    % entire protocol
    devType = field2cell(sTrain.blkInfo,'devType');
    chName = field2cell(sTrain.blkInfo,'chName');
    [tArr,~,iC] = unique(cell2table([devType,chName]),'rows');
    
    % calculates the time limits for each unique channel that has a stimuli
    % event (for the current protocol)
    indU = arrayfun(@(x)(iC==x),1:max(iC),'un',0)';
    tLim = cell2mat(cellfun(@(x)...
                        ([min(tLim0(x,1)),max(tLim0(x,2))]),indU,'un',0));
    
    % sets the information for each channel within the stimuli train
    for iCh = 1:length(indU)
        tArrCh = table2cell(tArr(iCh,:));
        stimP = setStimInfo(stimP,tArrCh,tS0,tLim(iCh,:),iStim,snTot);        
    end
end

% reorders the stimuli events in chronological order
fStrD = fieldnames(stimP);
for iDev = 1:length(fStrD)
    % retrieves the device data sub-struct
    stimPS = getStructField(stimP,fStrD{iDev});
    
    % retrieves the stimuli information for each channel
    fStrC = fieldnames(stimPS);
    stimPC = cellfun(@(x)(getStructField(stimPS,x)),fStrC,'un',0);
    
    % if the current device is a motor, and all the channels are the same,
    % then reduce all the motor parameters into a single field
    if strContains(fStrD{iDev},'Motor') && (length(stimPC) > 1)
        if all(cellfun(@(x)(isequal(stimPC{1},x)),stimPC(2:end)))
            fStrC = {'Ch'};
            stimPC = stimPC(1);
            stimPS = struct('Ch',stimPC{1});           
        end
    end
    
    % sorts the time limits for each channel
    for iCh = 1:length(fStrC)
        stimPC{iCh} = sortTimeLimits(stimPC{iCh});
        stimPS = setStructField(stimPS,fStrC{iCh},stimPC{iCh});
    end
    
    % resets the sub-struct for the device information
    stimP = setStructField(stimP,fStrD{iDev},stimPS);
end

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- sets the stimuli information for the current channel/device type
function stimP = setStimInfo(stimP,tArr,tS0,tLim,iStim,snTot)

% sets the input arguments
dType = regexprep(tArr{1},'[ #]','');
chName = regexprep(tArr{2},'[ #]','');

% appends the time/stimuli index information
stimPS = getStructField(stimP,dType); 
stimPS = appendStimField(stimPS,chName,'iStim',iStim*ones(length(tS0),1));

% calculate/sets the stimuli start/finish times
if isfield(snTot,'Ts')
    % case is the start/finish times have already been calculated (old
    % format solution files)
    [Ts,Tf] = deal(cell2mat(snTot.Ts(:)),cell2mat(snTot.Tf(:))); 
    
elseif isfield(snTot,'tStampS')
    % otherwise, use the start/finish times from the expt
    Ts = cell2mat(snTot.tStampS(:));
    Tf = Ts + tLim(2);    
else
    % case is no information has been provided so calculated directly
    [Ts,Tf] = deal(tLim(1)+tS0,tLim(2)+tS0);
end

% reduces down the stimuli times to those that are feasible
iSF = find(diff([Ts;-1])<0,1,'first');
[Ts,Tf] = deal(Ts(1:iSF),Tf(1:iSF));

% otherwise, use the start/finish times from the expt
stimPS = appendStimField(stimPS,chName,'Ts',Ts);
stimPS = appendStimField(stimPS,chName,'Tf',Tf);

% updates the device sub-struct field
stimP = setStructField(stimP,dType,stimPS);   

% --- appends the new data to the sub-field
function stimP = appendStimField(stimP,chName,tStr,Y)

pStr = sprintf('stimP.%s.%s',chName,tStr);
eval(sprintf('%s = [%s;Y];',pStr,pStr))

% --- sorts the stimuli events in chronological order
function stimPC = sortTimeLimits(stimPC)

% if empty then exit the function
if isempty(stimPC.Ts); return; end

% determines the sorting indices for the start time of each stimuli event
[~,iS] = sort(stimPC.Ts);

% reorderst the stimuli time limits/stimuli indices
[stimPC.Ts,stimPC.Tf,stimPC.iStim] = ...
                        deal(stimPC.Ts(iS),stimPC.Tf(iS),stimPC.iStim(iS));

% --- calculates the scale time value for the sub-field, tStr
function tVal = scaleTimeValue(p,tStr)

% converts the time to seconds and returns the value
tMlt = getTimeMultiplier('s',eval(sprintf('p.%sU',tStr)));
tVal = eval(sprintf('p.%s',tStr))*tMlt;
