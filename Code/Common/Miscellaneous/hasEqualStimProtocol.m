% --- determines if the stimuli protocols are the same for all experiments.
%     if, so, then return the stimuli count
function [hasEqSP,nStim] = hasEqualStimProtocol(snTot)

% initialisations
[hasEqSP,nStim] = deal(false,0);

% determines if all the stimuli have equal lengths
sTrainEx = field2cell(snTot,'sTrainEx');
if ~isempty(sTrainEx{1})            
    hasEqSP = all(cellfun(@(x)(isequal(x,sTrainEx{1})),sTrainEx));
    nStim = sTrainEx{1}.sParaEx.nCount*hasEqSP;
end