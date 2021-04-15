% --- sets up the DAC device for the RT experiments
function objDRT = setupDACDeviceRT(objDAC,objDRT,hGUI,T,Y,chInd)

% chInd convention
%
% chInd(1) - device index (device being stimulated)
% chInd(2) - local channel index (channel being stimulated)
% chInd(3) - global channel indices (indices within global array)

% global variables
global yAmpRT

% initialisations
[iDAC,iCh,iChG] = deal(chInd(1),chInd(2),chInd(3:end));
[dT,Yt] = deal(diff(T([1 2])),zeros(length(T),length(iChG)));

% memory allocation of the amplitude array (if not already set)
if (isempty(yAmpRT))
    nCh = cellfun(@(x)(length(get(x,'Channels'))),objDAC,'un',0);
    yAmpRT = cellfun(@(x)(zeros(1,x)),nCh,'un',0);
else
    yAmpRT{iDAC}(:) = 0;
end

% determines if the timer exists
if (isempty(objDRT))
    tExist = false;
else
    tExist = isvalid(objDRT);
end

% determines if the RT timer object is currently running
if (tExist)
    % stops the timer object (if running)
    if (strcmp(get(objDRT,'Running'),'on'))
        stop(objDRT);
    end
    
    % is so, determine the timer's current position    
    [Yt0,iT] = deal(get(objDRT,'UserData'),get(objDRT,'TasksExecuted'));
    Yt(1:(end-iT),:) = Yt0((iT+1):end,:);
    
    % deletes the existing time object
    delete(objDRT);
end

% sets the signal for the current channel
Yt(:,iCh) = Y; 

% determines the details of when there is an event change
[iChng,yChng,tChng] = detEventChange(Yt,dT);

% sets the timer callback functions
fcnS = {@dacStart,objDAC{iDAC},iChng,yChng,iDAC,iChG};
fcnT = {@dacTimer,objDAC{iDAC},iChng,yChng,tChng,iDAC,iChG,hGUI};        

% initialises the timer object
objDRT = timer('tag','Stim','UserData',Yt,'Period',dT,...
               'StartFcn',fcnS,'TimerFcn',fcnT,'ExecutionMode','fixedRate'); 
                            
%-------------------------------------------------------------------------%
%                         TIMER CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- start callback function
function dacStart(obj,event,hD,iChng,yChng,iDAC,iChG)

% global variables
global stimTS iEventS yAmpRT

% initialises the start time of the stimuli event
[stimTS{iDAC},iEventS(iDAC)] = deal(tic,2);
yAmpRT{iDAC}(iChng{1}) = yChng{1};

% sets the initial stimuli channel amplitudes
outputSingleScan(hD,yAmpRT{iDAC})

% --- timer callback function 
function dacTimer(obj,event,hD,iChng,yChng,tChng,iDAC,iChG,hGUI)
    
% global variables
global stimTS iEventS sFin yAmpRT

% initialises the start time of the stimuli event
cEvent = iEventS(iDAC);

% determines if the time is greater than the next change event
if (toc(stimTS{iDAC}) > tChng(cEvent))
    % if so, update the stimuli channels  
    yAmpRT{iDAC}(iChng{cEvent}) = yChng{cEvent};
    outputSingleScan(hD,yAmpRT{iDAC})
    
    % determines if a channel has been turned off
    ii = yChng{cEvent} == 0;
    if (any(ii))
        % if so, update the finish time for the channel
        if (~isempty(hGUI))
            rtD = getappdata(hGUI,'rtD');
            if (rtD.ind > 0)
                sFin(iChG(iChng{cEvent}(ii)),:) = repmat([1,rtD.T(rtD.ind)],sum(ii),1);    
            end
        end
    end
    
    % increments the event counter
    iEventS(iDAC) = iEventS(iDAC) + 1;
    if (iEventS(iDAC) > length(tChng))
        % if the there are no more events, then stop and delete the timer
        stop(obj)
        delete(obj)
    end
end
    
%-------------------------------------------------------------------------%
%                              OTHER FUNCTIONS                            %
%-------------------------------------------------------------------------%

% --- determines the details of the event changes in a signal
function [iChng,yChng,tChng] = detEventChange(Yt,dT)

% removes any signals which are all zeros
Yt(:,all(Yt==0,1)) = -1;

% determines the indices where there is a change in channel amplitudes
dYY = abs(diff([-ones(1,size(Yt,2));Yt])) > 0;
iDiff = find(any(dYY,2));
ii = num2cell(dYY(iDiff,:),2);

% sets the indices/amplitudes of the channels where there is a change
iChng = cellfun(@(x)(find(x)),ii,'un',0);
yChng = cellfun(@(x,y)(Yt(x,y)),num2cell(iDiff),iChng,'un',0);
tChng = dT*(iDiff-1);         