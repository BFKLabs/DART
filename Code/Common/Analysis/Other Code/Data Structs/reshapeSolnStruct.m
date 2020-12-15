% --- reorders the parameter struct to account for time reshaping --- %
function snTot = reshapeSolnStruct(snTot,iPara,varargin)

% sets the the frame offset for each of the movies
nFrame = cellfun(@length,snTot.T);
frmOfs = [0;cumsum(nFrame(1:end-1))];

% determines the frame indices that are to be output
[indS,indF] = deal(iPara.indS,iPara.indF);
frmInd = (frmOfs(indS(1))+indS(2)):(frmOfs(indF(1))+indF(2));

% resets the fly position x/y data arrays (if required)
if (nargin == 2)
    snTot.Px = cellfun(@(x)(x(frmInd,:)),snTot.Px,'un',0);
    if (~isempty(snTot.Py))
        snTot.Py = cellfun(@(x)(x(frmInd,:)),snTot.Py,'un',0);
    end
end
    
% resets the solution file start time to the new start time
for i = 1:length(snTot.iExpt)    
    [snTot.iExpt(i).Timing.T0,snTot.sgP(i).T0] = deal(iPara.Ts); 
end

% offsets the time arrays for the new indices
[snTot.T,Tofs] = reshapeTimeArrays(snTot.T,indS,indF);
snTot.isDay = reshapeTimeArrays(snTot.isDay,indS,indF,0);
snTot.Ts = reshapeStimuliArrays(snTot.Ts,Tofs,indS,indF,snTot.T{end}(end));
snTot.Tf = reshapeStimuliArrays(snTot.Tf,Tofs,indS,indF,snTot.T{end}(end));

% --- reshapes the time arrays such that A) the time is offset by Tofs, and
%     the time array, T, is reset to the start/finish indices (indS/indF)
function [Tnw,Tofs] = reshapeTimeArrays(T,indS,indF,varargin)

% resets the time arrays and ensures the first/last array is set correctly
if (indS(1) == indF(1))
    % start/finish index is within a single time vector
    Tnw = {T{indS(1)}(indS(2):indF(2))};
else
    % start/finish indices span multiple time vectors
    Tnw = T(indS(1):indF(1));
    [Tnw{1},Tnw{end}] = deal(Tnw{1}(indS(2):end),Tnw{end}(1:indF(2)));
end
    
% sets the time-offset
if (nargin == 3)
    Tofs = Tnw{1}(1);
    Tnw = cellfun(@(x)(x-Tofs),Tnw,'un',0);
end

% --- reshapes the stimuli timing arrays such that A) the time is offset by
%     Tofs, and the time array, T, is reset to the start/finish indices
%     (indS/indF)
function Tsnw = reshapeStimuliArrays(Ts,Tofs,indS,indF,Tfin)

% resets the time arrays and ensures the first/last array is set correctly
Tsnw = Ts(indS(1):indF(1));

% removes the time offset from the time arrays
Tsnw = cellfun(@(x)(x-Tofs),Tsnw,'un',0);

% ensures that the stimuli times are within that of the experiment
Tsnw{1} = Tsnw{1}(Tsnw{1} >= 0);
Tsnw{end} = Tsnw{end}(Tsnw{end} <= Tfin);
