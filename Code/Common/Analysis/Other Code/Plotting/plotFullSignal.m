% --- plots the full signal data
function hPlot = plotFullSignal(hAx,T,Y)

% initalisations
[dT,dtTol] = deal(diff(T),2);

% determines/removes points in the signal where there are any large gaps
idT = find([0;dT] > dtTol*mean(dT));
for i = length(idT):-1:1
    T = [T(1:(idT(i)-1));NaN;T(idT(i):end)];
    Y = [Y(1:(idT(i)-1),:);NaN(1:size(Y,2));Y(idT(i):end,:)];
end

% creates the final plot
hPlot = plot(hAx,T,Y);