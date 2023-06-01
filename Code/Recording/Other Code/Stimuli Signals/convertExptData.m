% --- converts the experiment data from the old-format .exp files 
function [iExpt,sTrainEx] = convertExptData(handles,sTrainS,iExpt0)

% initialisations
tNow = datevec(now);
nTrain = length(sTrainS);

% struct initialisations
sTrainEx = struct('sName',[],'sType',[],'sParaEx',[],'sTrain',[]);

% memory allocation
[sTrainEx.sName,sTrainEx.sType] = deal(cell(nTrain,1));
[sTrainEx.sTrain,sTrainEx.sParaEx] = deal(cell(nTrain,1));

% initialises the experiment data struct
if ~isempty(handles)
    hFig = handles.figExptSetup;
    iExpt = initExptStruct(hFig);
else
    hFig = [];    
    iExpt = initExptStruct('RecordStim',[],[]);
end

% updates the timing sub-struct fields
iExpt.Timing.Texp = iExpt0.Timing.Texp;
iExpt.Timing.Tp = iExpt0.Timing.Tp;
iExpt.Timing.fixedT0 = sign(iExpt0.Timing.T0(1)) > 0;
[~,iExpt.Timing.TexpU] = vec2time(iExpt.Timing.Texp);

% sets the experiment start time (ensures the time is feasible)
iExpt.Timing.T0 = [tNow(1:3),iExpt.Timing.T0(4:5),0];
if datenum(iExpt.Timing.T0) < now
    iExpt.Timing.T0(3) = iExpt.Timing.T0(3) + 1;
end

% if there is no stimuli info then exit
if isempty(sTrainS)
    sTrainEx = [];
    return
end

for i = 1:nTrain
    % sets the stimuli type
    sType = split(sTrainS.sName);
    ii = str2double(regexp(sTrainS.chName{1},'\d','match','once'));
    
    % sets the description/parameters
    sTrainEx.sName{i} = sTrainS.sName;
    sTrainEx.sType{i} = sprintf('%s Stimuli',sType{1});    
    sTrainEx.sTrain{i} = sTrainS(i);  
    
    % retrieves the parameters 
    sParaEx = struct('tOfs',NaN,'tOfsU','h','tDur',NaN,...
                     'tDurU',iExpt.Timing.TexpU,'nCount',NaN,'tStim',NaN,...
                     'sName',sprintf('Stimuli Train #%i',i));
    
    % sets the initial offset/stimuli counts             
    sParaEx.tOfs = iExpt0.Stim(ii).Ts(1)*getTimeMultiplier('h','s');
    sParaEx.nCount = iExpt0.Stim(ii).nCount;
    
    % sets the inter-stimuli duration
    if length(iExpt0.Stim(ii).Ts) > 1
        dtStim = diff(iExpt0.Stim(ii).Ts([1,2]))/iExpt0.Video.FPS;
        sParaEx.tStim = sec2vec(dtStim);
    else
        sParaEx.tStim = [0,1,0,0];
    end
        
    % sets the duration (in hours)
    [tDurEx0,tDurExU] = calcExptStimDuration(hFig,...
                                    sTrainS(i),sParaEx,iExpt.Timing.Texp);   
    
    % updates the field within the struct
    sParaEx.tDur = tDurEx0*getTimeMultiplier(iExpt.Timing.TexpU,tDurExU);
    sTrainEx.sParaEx{i} = sParaEx;
end

% converts the train/experiment cell arrays to struct arrays
sTrainEx.sTrain = cell2mat(sTrainEx.sTrain);
sTrainEx.sParaEx = cell2mat(sTrainEx.sParaEx);
