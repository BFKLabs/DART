% --- calculates the duration of the experiment stimuli train
function [tDurEx,tDurExU,tBlkOfs,tBlkDur] = ...
                         calcExptStimDuration(hFig,sTrainS,sPara,tDur)

if nargin == 1
    % retrieves parameter information for the current protocol/signal
    pType = getappdata(hFig,'pType');
    sPara = getProtocolParaInfo(hFig,pType);                

    % retrieves the stimuli train object for the protocol type
    sTrainS = getSelectedSignalTrainInfo(hFig);    
end

% initialisations
sParaBlk = field2cell(sTrainS.blkInfo,'sPara');

% 
if isfield(sPara,'tOfs')
    sParaS = sPara;
    [~,tDurExU] = vec2time(tDur);
else
    sType = getappdata(hFig,'sType');
    iExpt = getappdata(hFig,'iExpt');
    
    sParaS = getExptParaInfo(sPara,sType);
    [~,tDurExU] = vec2time(iExpt.Timing.Texp);
end

% calculates the inter-stimuli interval (in terms of the expt time units)
tStimInt = vec2sec(sParaS.tStim)*getTimeMultiplier(tDurExU,'s');

% calculates the time multiplers for each of stimuli blocks
tDurUnits = cellfun(@(x)(x.tDurU),sParaBlk,'un',0);
tMltDur = cellfun(@(x)(getTimeMultiplier(tDurExU,x)),tDurUnits);
tBlkDur = cellfun(@(x)(x.tDur),sParaBlk).*tMltDur;

% calculates the time multiplers for each of stimuli blocks
tOfsUnits = cellfun(@(x)(x.tOfsU),sParaBlk,'un',0);
tMltOfs = cellfun(@(x)(getTimeMultiplier(tDurExU,x)),tOfsUnits);
tBlkOfs =  cellfun(@(x)(x.tOfs),sParaBlk).*tMltOfs;

% calculates maximum duration for the stimuli trains across all channels
tDurEx = max(tBlkOfs+tBlkDur);

% calculates the full stimuli train
tDurEx = (sParaS.nCount-1)*tStimInt + tDurEx;