% --- runs all the DAC devices specified by indDAC --- %
function runDACDeviceOld(objDAC,indDAC,varargin)

% global variables
global nCountD tStart tExpt

% turns off all the warnings
wState = warning('off','all');

% sets the DAC indices
if (nargin == 1)
    indDAC = 1:length(objDAC);
end

tWait = 10;
if (iscell(objDAC))
    cellfun(@(x)(wait(x,tWait)),objDAC)
else
    wait(objDAC,tWait)
end

% adds the DAC object handles (for all the devices in the list)
for i = 1:length(indDAC)
    start(objDAC{i}); 
end

% updates the time-stamp array (for an experiment only)
if (nargin == 3)
    % if so, then increment the stimulus completion counter
    nCountD(indDAC) = nCountD(indDAC) + 1;    
    
    % retrieves the time-stamp array
    tStampS = evalin('base','tStampS');
    tStampS{indDAC}(nCountD(indDAC)) = toc(tExpt);
    tStart = tStampS{indDAC}(nCountD(indDAC));    
    
    % assigns the stimulus time stamp array back into the base workspace
    assignin('base','tStampS',tStampS)   
end
    
% reverts the warnings back to their original state
warning(wState);