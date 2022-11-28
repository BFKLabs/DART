% --- reorders the parameter struct to account for time reshaping --- %
function snTot = reshapeSolnStruct(snTot,iPara,varargin)

% sets the the frame offset for each of the movies
nFrame = cellfun('length',snTot.T);
frmOfs = [0;cumsum(nFrame(1:end-1))];

% determines the frame indices that are to be output
[indS,indF] = deal(iPara.indS,iPara.indF);
frmInd = (frmOfs(indS(1))+indS(2)):(frmOfs(indF(1))+indF(2));

% resets the fly position x/y data arrays (if required)
if nargin == 2
    ii = ~cellfun('isempty',snTot.Px);
    snTot.Px(ii) = cellfun(@(x)(x(frmInd,:)),snTot.Px(ii),'un',0);
    if ~isempty(snTot.Py)
        snTot.Py(ii) = cellfun(@(x)(x(frmInd,:)),snTot.Py(ii),'un',0);
    end
end
    
% resets the solution file start time to the new start time
for i = 1:length(snTot.iExpt)    
    snTot.iExpt(i).Timing.T0 = iPara.Ts; 
end

% if the stimuli parameter field is missing (old solution file format) then
% set up the this field within the solution data struct
if ~isfield(snTot,'stimP')
    snTot.stimP = getExptStimInfo(snTot);
end

% offsets the time arrays for the new indices
[snTot.T,Tofs] = reshapeTimeArrays(snTot.T,indS,indF);
% snTot.isDay = reshapeTimeArrays(snTot.isDay,indS,indF,0);
snTot.stimP = reshapeStimuliTiming(snTot,Tofs);

% --- reshapes the time arrays such that A) the time is offset by Tofs, and
%     the time array, T, is reset to the start/finish indices (indS/indF)
function [Tnw,Tofs] = reshapeTimeArrays(T,indS,indF,varargin)

% if there is no data, then exit
if isempty(T)
    [Tnw,Tofs] = deal([],0);
    return
end

% resets the time arrays and ensures the first/last array is set correctly
if indS(1) == indF(1)
    % start/finish index is within a single time vector
    Tnw = {T{indS(1)}(indS(2):indF(2))};
else
    % start/finish indices span multiple time vectors
    Tnw = T(indS(1):indF(1));
    [Tnw{1},Tnw{end}] = deal(Tnw{1}(indS(2):end),Tnw{end}(1:indF(2)));
end
    
% sets the time-offset
if nargin == 3
    Tofs = Tnw{1}(1);
    Tnw = cellfun(@(x)(x-Tofs),Tnw,'un',0);
end

% --- reshapes the stimuli timing arrays such that A) the time is offset by
%     Tofs, and the time array, T, is reset to the start/finish indices
%     (indS/indF)
function stimP = reshapeStimuliTiming(snTot,Tofs)

% field retrieval
Tofs = roundP(Tofs,0.001);
[T,stimP] = deal(snTot.T,snTot.stimP);
if isempty(stimP); return; end

% retrieves the device type strings
devStr = fieldnames(stimP);
devOK = true(length(devStr),1);

% for each device/channel, reduce down the start/times
for i = 1:length(devStr)
    % retrieves the device stimuli information
    devP = getFieldValue(stimP,devStr{i});    
    
    % loops through each channel ensuring the 
    chStr = fieldnames(devP);
    chOK = true(length(chStr),1);
    for j = 1:length(chStr)
        % retrieves the channel information
        chP = getFieldValue(devP,chStr{j});
        isOK = true(length(chP),1);
        
        % reduces down each stimuli type for the current channel
        for k = 1:length(chP)
            % determines the stimuli events that start within the entire
            % duration of the experiment
            [chP(k).Ts,chP(k).Tf] = deal(chP(k).Ts-Tofs,chP(k).Tf-Tofs);
            ii = (chP(k).Tf >= 0) & (chP(k).Ts <= T{end}(end));
            
            % determines if there are any valid stimuli events still left
            isOK(k) = any(ii);
            if isOK(k)
                % if so, then reduce down the start/finish times
                chP(k).Ts = max(chP(k).Ts(ii),0);
                chP(k).Tf = min(chP(k).Tf(ii),T{end}(end));
                chP(k).iStim = chP(k).iStim(ii);
            end
        end
        
        % determines if there are any valid stimuli events still left
        chOK(j) = any(isOK);
        if any(isOK)        
            % if so, reset the channel stimuli information
            devP = setFieldValue(devP,chStr{j},chP(isOK));
        else
            % otherwise, remove the field from the data struct
            devP = rmfield(devP,chStr{j});
        end
    end
    
    % determines if there are any valid channels still left
    devOK(i) = any(chOK);
    if any(chOK)
        % if so, then reset the device information
        stimP = setFieldValue(stimP,devStr{i},devP);
    else
        % otherwise, remove the field from the data struct
        stimP = rmfield(stimP,devStr{i});
    end
end

% if there were no devices with stimuli events within the set limits of the
% experiment, then return an empty array
if ~any(devOK); stimP = []; end
