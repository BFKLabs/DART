% --- determines if the stimuli protocols are the same for all experiments.
%     if, so, then return the stimuli count
function [hasEqSP,nStim] = hasEqualStimProtocol(snTot)

% initialisations
[hasEqSP,nStim] = deal(false,0);

% determines if all the stimuli have equal lengths
iExpt = field2cell(snTot,'iExpt',1);
if isfield(iExpt,'Stim')            
    iStim = field2cell(iExpt,'Stim',1);
    hasEqSP = all(cellfun(@(x)(isequal(x,iStim(1))),num2cell(iStim)));
    nStim = length(iStim(1).Ts)*hasEqSP;
end