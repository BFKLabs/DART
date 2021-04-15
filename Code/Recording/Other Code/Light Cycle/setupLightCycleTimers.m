% --- function that sets up light cycle timer objects for an experiment.
%     the light cycle serial object (hS) is controlled with the parameters
%     in the parameter struct (LCycle). the experiment is also assumed to
%     start at the time vector, T0 for a duration of Texp seconds
function tObj0 = setupLightCycleTimers(hS,iExpt,tStart,hProg)

% initialisations
[LCycle,tExp] = deal(iExpt.LCycle,vec2sec(iExpt.Timing.Texp));
[t0,setTimer] = deal([0,LCycle.T0(:)',0],true);

% ensures the serial object is open
if (strcmp(hS.Status,'closed')); fopen(hS); end

% deletes any previous light cycle timers
hLightC = timerfindall('tag','LightC');
if (~isempty(hLightC))
    wState = warning('off','all');
    delete(hLightC)
    warning(wState)
end

% creates the objects based on the lighting schedule
switch (LCycle.lType)
    case (1) % case is constant lighting
        [p,setTimer] = deal(LCycle.pConst,false);  
        tObj0 = setupStatLCTimer(hS,[p.pW(1),p.pIR(1)]/100,1,...
                                 tExp+tStart,hProg);
        
        % initialises the light cycle time-stamp array
        assignin('base','tStampL',NaN);        
    case (2) % case is the fixed 2-phase light cycle
        p = LCycle.pFixed;
    case (3) % case is a variable light cycle
        p = LCycle.pVar;        
end

% creates the light cycle timer object (not for constant lighting)
if (setTimer)    
    tObj0 = detCyclePhaseTiming(hS,p,t0,tExp,LCycle.sType==1,hProg);     
end

% starts the timer object
start(tObj0);

% --- determines the timing/index of the cycle phases with respect to the
%     start of the experiment (over the duration of the experiment)
function tObj0 = detCyclePhaseTiming(hS,p,t0,tExp,exptStart,hProg)

% global variables
global nPause

% initialisations
[a,Dur] = deal(clock,p.Dur*60);
[t0F,iPhase,TT,jj] = deal(0,1,0,circshift((1:length(Dur))',1));

% sets the current time (adjusts for the pause time)
tNow = [0,a(4:6)];
tNow(end) = tNow(end) + nPause;

% resets time if starting light cycle at beginning of experiment
if (exptStart)
    t0 = tNow; 
end

% ensures the current time >= the light cycle start time
[sNow,s0] = deal(vec2sec(tNow),vec2sec(t0));
if (sNow < s0) 
    tNow(1) = 1; 
    sNow = vec2sec(tNow);
end

% keep searching for light cycle phases that will occur before the end of
% the experiment (wrt to the start time of the experiment)
dT = sNow - s0;
while (1)
    % sets the time of the light cycle phases (wrt to the expt start)
    tNew = t0F + cumsum(Dur)-(p.useTrans*(60*p.tTrans/2));
    
    % determines which light cycle phases will occur before the end of the
    % experiment. these phases are appended to the end of the phase
    % timing/index arrays
    ii = (1:find(tNew < (tExp+dT),1,'last'))';
    [TT,iPhase] = deal([TT;tNew(ii)],[iPhase;jj(ii)]);
    
    % determines if there are any more phases that can occur before the end
    % of the experiment
    if (length(ii) < length(Dur))        
        % if not, then exit the loop
        break
    else
        % otherwise, add on the total time for all phases
        t0F = t0F + sum(Dur);
    end
end

% ensures that the experiment end is incorprated in the time array
if (TT(end) < (tExp+dT))
    % incorporates the end time in the time vector
    TT(end+1) = tExp+dT; 
    
    % sets the index of the next phase
    iPhase(end+1) = iPhase(end)+1; 
    if (iPhase(end) > length(Dur)); iPhase(end) = 1; end
end

% determines the starting cycle phase
jPhase = find(TT<=dT,1,'last');

% sets up the delayed timer objects for the other phases (if they exist)
kk = jPhase:length(TT);
if (~isempty(kk))
    % sets up the date strings for each cycle phase    
    TT = TT(kk);
    dTT = TT - dT;
    [vPhase,b] = deal(repmat(a,length(kk),1),sec2vec(TT+s0));
    if (b(1,1) == 1); b(:,1) = b(:,1) - 1; end
    
    % sets the phase time/indices
    [vPhase(:,4:end),vPhase(:,3)] = deal(b(:,2:end),vPhase(:,3)+b(:,1));
    [tPhase,iPhase] = deal(datestr(vPhase),iPhase(kk));
    
    % initialises the light cycle time-stamp array
    assignin('base','tStampL',NaN(length(iPhase),1));
    
    % sets the delayed timers for each of the light cycle phases
    for i = 1:(length(TT)-1)
        % sets the global indices
        j = i + [0 1];              
        
        % sets up the timer objects
        if ((i == 1) || (~p.useTrans))                        
            % sets up the static timer   
            pL = [p.pW(iPhase(i)),p.pIR(iPhase(i))]/100;
            dtPhase = dTT(j(2))-max(0,dTT(j(1)));
            tObj = setupStatLCTimer(hS,pL,i,dtPhase,hProg);
        else                       
            % sets up a transition timer
            iPnw = iPhase(i+[-1,0]);
            [pW,pIR] = deal(p.pW(iPnw)/100,p.pIR(iPnw)/100);
            tObj = setupTransLCTimer(hS,pW,pIR,i,diff(TT(j)),hProg,...
                                     p.tTrans*60);            
        end
                     
        % sets up the timer object to run at the specified time
        if (i == 1)
            % pre-experiment phase (ensures the lights are on)
            tObj0 = tObj;
            tObj0.StartDelay = nPause - 5;
        else
            % other phases
            startat(tObj,tPhase(i,:));
        end
    end
end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% -------------------------------- %
% --- STATIC LIGHT CYCLE TIMER --- %
% -------------------------------- %

% --- sets up the static light cycle timer
function tObjS = setupStatLCTimer(hS,pL,ind,dtPhase,hProg,tDelay)

% initialisations and parameters
switch get(hS,'UserData')
    case 2
        tRep = 1;
        nTaskF = 3;
    otherwise
        tRep = 15;
        nTaskF = max(1,floor(dtPhase/tRep)-1);
end
        
% sets up the timer function based on the type
if (nargin == 5)
    % case is a straight static light cycle timer
    [fcnT,tDelay] = deal({@timerStatLC,hS,pL,ind,nTaskF,hProg},0);     
else
    % case is from a transisent light cycle timer
    fcnT = {@timerStatLC,hS,pL,ind,nTaskF,hProg,1};    
end

% creates the timer object
tObjS = timer('tag','LightC','Period',tRep,'TasksToExecute',nTaskF,...
              'ExecutionMode','fixedRate','TimerFcn',fcnT,'StartDelay',tDelay);    

% --- the light cycle timer object start function
function timerStatLC(obj,event,hS,pL,ind,nTaskF,hProg,varargin)    

% updates the light channel values
updateLightChannelsSerial(hS,pL(1),pL(2));
updateProgressLC(hProg,pL)

% determines the number of tasks that have been executed
nTask = obj.TasksExecuted;
if ((nTask == 1) && (nargin == 6))    
    % if the first executation, then update the light cycle time-stamps
    tStampL = evalin('base','tStampL');
    tStampL(ind) = now;
    assignin('base','tStampL',tStampL);    
elseif (nTask == nTaskF)
    % if the last task, then delete the timer object
    wState = warning('off','all');
    delete(obj)
    warning(wState);    
end
         
% ----------------------------------- %
% --- TRANSIENT LIGHT CYCLE TIMER --- %
% ----------------------------------- %

% --- sets up a timer that transitions between the start/finish values
%     given in the white/infrared light intensity arrays over a time
%     of tTrans minutes
function tObj = setupTransLCTimer(hS,pW,pIR,ind,dtPhase,hProg,tTrans)

% sets the white/infrared light levels at each time point
[yW,yIR] = deal([pW(1),diff(pW)/tTrans],[pIR(1),diff(pIR)/tTrans]);

% sets up the static light cycle timer object (to be run after the
% transient timer object)
tObjS = setupStatLCTimer(hS,[pW(2),pIR(2)],ind,dtPhase,hProg,tTrans+1);
fcnT = {@timerTransLC,hS,yW,yIR,ind,tTrans,hProg,tObjS};

% initialises the timer object
tObj = timer('Period',0.01,'ExecutionMode','fixedRate','tag','LightC',...
             'TimerFcn',fcnT,'TasksToExecute',1);

% --- the timer callback function for the light cycle object
function timerTransLC(obj,event,hS,pW,pIR,ind,tTrans,hProg,tObjS)

% updates the light cycle time stamp array
tStampL = evalin('base','tStampL');
tStampL(ind) = now;
assignin('base','tStampL',tStampL);    

% determines if the time is greater than the next change event
updateLightChannelsSerial(hS,pW(1),pIR(1),pW(2),pIR(2),tTrans);
updateProgressLC(hProg,[pW(1),pIR(1)])

% starts the static timer
start(tObjS)

% deletes the transient timer object
stop(obj)    
delete(obj)

% --- updates the expt progress light cycle intensities
function updateProgressLC(hProg,pL)

% updates the intensity values on the progress gui
set(hProg.textWL,'string',sprintf('%i%s',roundP(100*pL(1)),char(37)))
set(hProg.textIR,'string',sprintf('%i%s',roundP(100*pL(2)),char(37)))
