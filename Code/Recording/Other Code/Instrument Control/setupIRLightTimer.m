function setupIRLightTimer(hDev,hMenu)

% parameters
tPer = 10;
tagTimer = 'hTimerIR';

% timer setup
hTimer = timer('Period',tPer,'StartDelay',tPer,'Tag',tagTimer,...
    'TasksToExecute',inf,'ExecutionMode','FixedRate',...
    'TimerFcn',{@lightTimerFcn,hDev,hMenu});

% starts the timer
start(hTimer)
            
% --- timer function
function lightTimerFcn(~, ~, hDev,hMenu)

if strcmp(get(hMenu,'Checked'),'on')
    writeSerialString(hDev,sprintf('4,%f\n',100));
end
