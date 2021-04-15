% --- 
function iParaR = setupReshapeParaStruct(handles,snTot,ind)

% retrieves the parameter/time data structs/arrays
iPara = getappdata(handles.figMultCombInfo,'iPara');
T0nw = getappdata(handles.figMultCombInfo,'T0nw'); 
Tfnw = getappdata(handles.figMultCombInfo,'Tfnw');

% memory allocation and calculation of the marker start/finish times
[indS,indF] = deal(zeros(1,2));

% calculates the new start/finish times in seconds, and set up initial time
% array for each of the solution files
T0nwS = max(0, (iPara.indS-1)*60 - vec2sec(T0nw(ind,:)));
TfnwS = T0nwS + (iPara.indF - iPara.indS)*60;
TfnwS = min(vec2sec(Tfnw(ind,:)),TfnwS);
T0 = cellfun(@(x)(x(1)),snTot.T);

% determines the start solution file/frame indices
if (T0nwS == 0)
    % case is the first time point
    indS = [1 1];
else
    % otherwise, calculate the start file/frame index
    indS(1) = find([T0;(TfnwS+1)] <= T0nwS,1,'last');
    indS(2) = find([snTot.T{indS(1)};(TfnwS+1)] <= T0nwS,1,'last');    
    indS(2) = min(indS(2),length(snTot.T{indS(1)}));
end
    
% determines the finish solution file/frame indices
if (TfnwS == 0)
    % case is the last time point
    indF = [length(snTot.T) length(snTot.T{end})];
else
    % otherwise, calculate the finish file/frame index
    indF(1) = find([T0;(TfnwS+1)] <= TfnwS,1,'last');
    indF(2) = find([snTot.T{indF(1)};(TfnwS+1)] <= TfnwS,1,'last');
    indF(2) = min(indF(2),length(snTot.T{indF(1)}));
end

% sets the new experiment start time
Timing = snTot.iExpt.Timing;
dT = ceil(snTot.T{indS(1)}(indS(2))+1);
nwTime = addtodate(datenum(Timing.T0),dT,'second');

% sets up the time reshaping parameter struct
Ts = datevec(nwTime); Ts(3:end) = sec2vec(roundP(vec2sec(Ts(3:end))/60,1)*60);
iParaR = struct('indS',indS,'indF',indF,'Ts',Ts);
