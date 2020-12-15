% --- calculates the longest possible stimulus train from the parameter
%     struct given by, iPara --- %
function Tstim = calcMaxStimDur(iPara)

% determines the number of stimuli within the train
nStim = length(iPara);
[pCount,pDur,pDelay,sDelay] = deal(zeros(nStim,1));

% sets the temporal parameter values for all the stimuli within the train
for i = 1:nStim
    % retrives the temporal values from the parameter struct
    pCount(i) = getStructVal(iPara(i).pCount);
    pDur(i) = getStructVal(iPara(i).pDur);
    pDelay(i) = getStructVal(iPara(i).pDelay);
    
    % set the stimulus delay only for the non-final stimulus
    if (i < nStim)
        sDelay(i) = getStructVal(iPara(i).sDelay);    
    end
end

% adds up times over all the stimuli
Tstim = sum(pCount.*pDur) + sum((pCount-1).*pDelay) + sum(sDelay);

% --- 
function pVal = getStructVal(Str)

%
if (Str.isRand)
    pVal = Str.pMax;
else
    pVal = Str.pVal;
end
