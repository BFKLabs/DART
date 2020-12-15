% --- determines which time points which an experiment are day/night points
function isDay = detDayNightTimePoints(snTot)

% global variables
global tDay 
hDay = 12;

% sets the time vectors and experiment start times
[T,T0] = deal(cell2mat(snTot.T(:)),snTot.iExpt.Timing.T0);

% sets the initial experiment time offset
Tofs = convertTime(vec2sec([0 T0(4:end)]),'sec','hrs');
        
% determines which points are within the day time
Tm = mod(convertTime(T,'sec','hrs')+Tofs,24);
isDay = (Tm >= tDay) & (Tm < (tDay+hDay));    