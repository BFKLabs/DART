% --- determines how many days each experiment lasts for
function nDay = detExptDayDuration(snTot,hGUI,varargin)

% parameters
prMinTol = 5;
prDayTol = convertTime(prMinTol,'m','d');

% retrieves the global paramerter struct
if (nargin == 1); hGUI = findall(0,'tag','figFlyAnalysis'); end
gP = getappdata(hGUI,'gPara');

% retrieves the experiment timing data struct
T = field2cell(snTot,'T');
Timing = cell2mat(cellfun(@(x)(x.iExpt.Timing),num2cell(snTot),'un',0));

% converts the time vectors
T0 = cellfun(@(x)([0,x(4:6)]),field2cell(Timing,'T0'),'un',0);
for i = 1:length(T0)    
    T0{i}(2) = mod(T0{i}(2)-gP.Tgrp0,24); 
    if (((T0{i}(2) == 23) && (T0{i}(3) > (60-prMinTol))) && (nargin == 2))
        % if the start time is very close to the end of the day, then reset
        % the time so that effectively the experiment starts at the end of
        % the day (this removes errors associated with the days effectively
        % being very short)
        T0{i}(2:4) = 0;
    end
end

% calculates the number of days each experiment runs for
Tf = cellfun(@(x)(x{end}(end)),T,'un',0);
TexpF = cellfun(@(x,y)(x+sec2vec(y)),T0,Tf,'un',0);

% calculates the final day counts for each experiment
nDay = cellfun(@(x)(convertTime(vec2sec(x),'s','d')),TexpF);
for i = 1:length(nDay)
    if (mod(nDay(i),1) < prDayTol)
        % case is only partially into next day
        nDay(i) = floor(nDay(i));
    else
        % otherwise, round up the day count to the next integer
        nDay(i) = ceil(nDay(i));
    end
end