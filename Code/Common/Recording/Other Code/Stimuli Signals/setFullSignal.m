% --- combines the full stimulus signal from the signal parameter struct
function [T,Y] = setFullSignal(sigPara)

% sets the time step
dT = diff(sigPara(1).Tsig(1:2));
T = (sigPara(1).Tsig(1):dT:sigPara(end).Tsig(end))';
Y = zeros(size(sigPara(1).Ysig));

% sets the signal components for each part of the stimuli train
for i = 1:length(sigPara)
    % determines the location of the stimuli signal component within the
    % total train, and sets the signal values
    [~,indNw] = min(abs(T - sigPara(i).Tsig(1)));    
    Y(indNw + ((1:length(sigPara(i).Tsig))-1)',:) = sigPara(i).Ysig;
end