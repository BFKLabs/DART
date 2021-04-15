% --- sets the Zeitgeiber time on a plot axis, hAx --- %
function setZeitGTimeAxis(hAx,T,snTot,lMax)

% global variables
global tDay

% allowable time steps
if (nargin < 4); lMax = 16; end
[tDayH,xL] = deal(convertTime(tDay,'hrs','sec'),get(hAx,'xlim'));
xStep = [1 2 4 6 12 24];

% sets the time step (based on the duration of the experiment)
tStep = xStep(1+find(xStep <= ceil(convertTime(T(end),'sec','hrs')/lMax),1,'last'));

% sets the start/finish times and initial time hour
if (nargin == 2)
    Ts = 0;    
else
    if (~isempty(snTot))
        Ts = vec2sec([0,snTot.iExpt(1).Timing.T0(4:end)])-tDayH;
    else
        Ts = 0;
    end
end

% converts the time step to the time units
tStepS = convertTime(tStep,'hrs','secs');
    
% time points where the markers should be
Tf = ceil(Ts + T(end));
if (mod(Ts,tStepS) == 0)
    indT = 0:tStepS:Tf;
else
    indT = (tStepS-mod(Ts,tStepS)):tStepS:Tf;
end

% sets the time/location of the tick-markers
tTick = indT;
% xTick = xL(1) + (tTick/diff(T([1 end])))*diff(xL);
xTick = (tTick/diff(T([1 end])))*diff(xL);

% resets the start time to the nearest day/night transition time
tLblStr = cell(size(xTick));
for i = 1:length(xTick)
    tLblStr{i} = num2str(mod(convertTime(tTick(i)+Ts,'sec','hrs'),24));
end

% updates the axis time marks/labels
set(hAx,'xtick',xTick,'xticklabel',tLblStr,'Ticklength',[0 0])