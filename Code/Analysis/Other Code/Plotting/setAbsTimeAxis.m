% --- sets the absolute time on a plot axis, hAx --- %
function setAbsTimeAxis(hAx,T,snTot,tStep)

% global variables
global tDay

% allowable time steps
[lMax,hMin,dumT,xL,iStep] = deal(8,6,clock,get(hAx,'xlim'),1);
tDayH = convertTime(tDay,'hrs','sec');

% sets the x-axis time step
if convertTime(T(end),'sec','hour') < hMin
    % time is less than the minimum time, so time in units of minutes
    [tStr,isHours] = deal('min',false);    
    xStep = [1 2 5 10 15 20 30 60];
else    
    % otherwise, set time in units of hours
    [tStr,isHours] = deal('hrs',true);       
    xStep = [1 2 4 6 12];
end

% sets the time step (based on the duration of the experiment)
if nargin < 4
    % determines the optimal time-step
    Tend = convertTime(T(end),'sec',tStr);
    iFin = find(ceil(Tend/lMax) <= xStep,1,'first');
    
    % sets the time step
    if isempty(iFin)
        % experiment is long, so use sub-sampling 
        tStep = xStep(end);        
        iStep = floor(Tend/(xStep(end)*lMax));
    else
        % otherwise, use the exact sampling rates
        [tStep,iStep] = deal(xStep(iFin),1);
    end
end

% converts the time step to the time units
tStepS = convertTime(tStep,tStr,'secs');

% sets the start/finish times and initial time hour
switch nargin
    case {2,4}
        Ts = deal(0);
    otherwise
        % calculates the start time of the experiment (in relation to the 
        % start of the day, tDayH) which is given in seconds)
        if ~isempty(snTot) || (T(1) >= snTot.iExpt.Video.Ts(2))
            Ts = vec2sec([0,snTot.iExpt(1).Timing.T0(4:end)])-tDayH;            
        else
            Ts = 0;      
        end        
end

% time points where the markers should be
Tf = ceil(Ts + T(end));
tTick = (tStepS*ceil(Ts/tStepS):tStepS:Tf)-Ts;

% sets the time/location of the tick-markers
xTick = (tTick/diff([0,T(end)]))*diff(xL);

% resets the start time to the nearest day/night transition time
tLblStr = cell(size(xTick));
for i = 1:length(xTick)
    if isHours
        tLblStr{i} = datestr([dumT(1:2) ...
                                sec2vec(Ts+tTick(i)+tDayH)],'HHPM');
    else
        tLblStr{i} = datestr([dumT(1:2) ...
                                sec2vec(Ts+tTick(i)+tDayH)],'HH:MMPM');
    end        
end

% removes any labels that are in the correct step size
ii = false(size(tLblStr));
ii(1:iStep:end) = true;
tLblStr(~ii) = {''};

% updates the axis time marks/labels
set(hAx,'xtick',xTick,'xticklabel',tLblStr,'Ticklength',[0 0])