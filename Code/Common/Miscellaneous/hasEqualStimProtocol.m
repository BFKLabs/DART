% --- determines if the stimuli protocols are the same for all experiments.
%     if, so, then return the stimuli count
function [hasEqSP,nStim] = hasEqualStimProtocol(snTot)

try
    iStim = field2cell(field2cell(snTot,'iExpt',1),'Stim',1);
    hasEqSP = all(cellfun(@(x)(isequal(x,iStim(1))),num2cell(iStim)));
    nStim = length(iStim(1).Ts)*hasEqSP;
catch
    [hasEqSP,nStim] = deal(false,0);
end