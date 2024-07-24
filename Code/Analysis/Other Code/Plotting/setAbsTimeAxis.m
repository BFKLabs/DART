% --- sets the absolute time on a plot axis, hAx --- %
function setAbsTimeAxis(hAx,T,snTot,tStep)

% global variables
global tDay

% allowable time steps
tMin = [6*60^2,5*60,-1];
tStr = {'hrs','min','sec'};
tDayH = convertTime(tDay,'hrs','sec');
[lMax,dumT,xL,iStep] = deal(8,clock,get(hAx,'xlim'),1);
xStep = {[1,2,4,6,12],[1,2,5,10,15,20,30,60],[1,2,5,10,15,20,30,60]};

% determines the experiment duration index
iMin = find(T(end) >= tMin,1,'first');

% sets the time step (based on the duration of the experiment)
if nargin < 4
    % determines the optimal time-step
    Tend = convertTime(T(end),'sec',tStr{iMin});
    iFin = find(ceil(Tend/lMax) <= xStep{iMin},1,'first');
    
    % sets the time step
    if isempty(iFin)
        % experiment is long, so use sub-sampling 
        tStep = xStep{iMin}(end);        
        iStep = floor(Tend/(xStep{iMin}(end)*lMax));
    else
        % otherwise, use the exact sampling rates
        [tStep,iStep] = deal(xStep{iMin}(iFin),1);
    end
end

% converts the time step to the time units
Ts = 0;
tStepS = convertTime(tStep,tStr{iMin},'secs');

% sets the start/finish times and initial time hour
if ~any(nargin == [2,4])
    % calculates the start time of the experiment (in relation to the 
    % start of the day, tDayH) which is given in seconds)
    if ~isempty(snTot) || (T(1) >= snTot.iExpt.Video.Ts(2))
        if iMin < 3
            Ts = vec2sec([0,snTot.iExpt(1).Timing.T0(4:end)])-tDayH;            
        end
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
    switch iMin
        case 1   
            if mod(tDay,1) == 0
                tLblStr{i} = datestr([dumT(1:2) ...
                                sec2vec(Ts+tTick(i)+tDayH)],'HHPM');
            else
                tLblStr{i} = datestr([dumT(1:2) ...
                                sec2vec(Ts+tTick(i)+tDayH)],'HH:MMPM');
            end
            
        case 2
            tLblStr{i} = datestr([dumT(1:2) ...
                                sec2vec(Ts+tTick(i)+tDayH)],'HH:MMPM');
        case 3
            tLblStr{i} = num2str(tTick(i));
    end        
end

% removes any labels that are in the correct step size
ii = false(size(tLblStr));
ii(1:iStep:end) = true;
tLblStr(~ii) = {''};

% updates the axis time marks/labels
set(hAx,'xtick',xTick,'xticklabel',tLblStr,'Ticklength',[0 0])