% --- determines if the stimuli protocols are the same for all experiments.
%     if, so, then return the stimuli count
function [hasEqSP,nStim] = hasEqualStimProtocol(snTot)

% initialisations
[hasEqSP,nStim] = deal(false,0);

% determines if all the stimuli have equal lengths
sTrainEx = field2cell(snTot,'sTrainEx');
if ~isempty(sTrainEx{1})            
    hasEqSP = all(cellfun(@(x)(isequal(x,sTrainEx{1})),sTrainEx));
    
    % sets the stimuli count for each device (if required)
    if nargout == 2
        nCount = field2cell(sTrainEx{1}.sParaEx,'nCount');    
        nStim = nCount*hasEqSP;
    end
end