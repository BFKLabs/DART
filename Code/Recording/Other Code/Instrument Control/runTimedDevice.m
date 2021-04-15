% --- runs the specified signal on the serial device --- %
function runTimedDevice(objS,varargin)

% global variables
global timerTest

% determines which devices are stimuli class objects
isStimObj = cellfun(@(x)(isa(x,'StimObj')),objS);

% sets up the device timer array
timerDev = cell(length(objS),1);
timerDev(~isStimObj) = objS(~isStimObj);
timerDev(isStimObj) = cellfun(@(x)(x.hTimer),objS(isStimObj),'un',0);    

% determines if there is a test timer
if isempty(timerTest)
    % if no test timer, then run the device timer
    cellfun(@start,timerDev)
else
    % otherwise, run the timers simultaneously
    if strcmp(get(timerTest,'Running'),'off')
        cellfun(@start,[timerDev(:);{timerTest}])
    else
        cellfun(@start,timerDev);
    end
end