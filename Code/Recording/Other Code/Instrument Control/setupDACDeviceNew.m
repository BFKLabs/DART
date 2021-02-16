% --- sets up the DAC device (new matlab version)
function objDAC = setupDACDeviceNew(objDACT,dacType,varargin)

% global variables
global nMaxD hSumm isError isRT

% sets the dac device properties based on the setup type
switch (dacType)
    case ('Test') % case is testing the DAC devices
        % sets the input arguments
        YYtot = varargin{1};
                
        % memory allocation
        [objDAC,nDAC] = deal(cell(1,length(objDACT)),length(objDACT));                
        
        % creates the timer objects for each of the devices
        for i = 1:nDAC
            % sets the sample rate
            try
                sRate = get(objDACT{i},'SampleRate');
            catch
                sRate = 50;
            end
            
            % determines the details of when there is an event change            
            [yChng,tChng] = detEventChange(YYtot{i},1/sRate);
            
            % sets the timer callback functions
            fcnS = {@dacStart,objDACT{i},yChng};
            fcnT = {@dacTimer,objDACT{i},yChng,tChng};
            
            % initialises the timer object
            objDAC{i} = timer('tag','Stim','UserData',[],'Period',1/sRate,...
                              'StartFcn',fcnS,'TimerFcn',fcnT,...
                              'ExecutionMode','fixedRate');              
        end        
        
    case ('Expt')
        % sets the input arguments
        [ExptSig,hSumm] = deal(varargin{1},varargin{2});
        
        % memory allocation and parameters
        objDAC = cell(length(ExptSig),1);
        dT = diff(ExptSig(1).T{1}([1 2]));
                
        % sets the current/total stimuli counts
        if (~isError)
            try
                % retrieves the time stamp array from the base workspace
                tStampS = evalin('base','tStampS');
            catch
                % if the array doesn't exist, then create a new one
                tStampS = cell(length(nMaxD),1); 
            end  
        else            
            % REMOVE ME LATER
            waitfor(msgbox('REINITIALISE nCountD here!','Finish Code','modal'))
        end        

        % sets the stop/trigger functions for the experiment DAC devices
        for i = 1:length(ExptSig)
            % retrieves the DAC ID 
            iDAC = ExptSig(i).ID;            
            
            % allocates memory for the time stamp array
            if (~isError)
                tStampS{iDAC} = zeros(length(ExptSig(i).Ts),1);
            end        
            
            % sets up the timer objects for each experiment stimuli event
            objDAC{i} = cell(length(ExptSig(i).Ts),1);
            for j = 1:length(objDAC{i})
                % determines the details of when there is an event change
                [yChng,tChng] = detEventChange(ExptSig(i).Y{j},dT);  
                
                % sets the timer callback functions
                fcnS = {@dacStart,objDACT{i},yChng};
                fcnT = {@dacTimer,objDACT{i},yChng,tChng};    
                fcnF = {@dacStop,hSumm,ExptSig(i),iDAC};
                
                % initialises the timer object
                objDAC{i}{j} = timer('tag','Stim','UserData',[],'Period',dT,...
                                     'StartFcn',fcnS,'TimerFcn',fcnT,...
                                     'StopFcn',fcnF,'ExecutionMode','fixedRate');                                               
            end         
        end        
        
        % places the stimulus time stamp array in the base workspace
        if (~isError)
            assignin('base','tStampS',tStampS)
        end               
end

%-------------------------------------------------------------------------%
%                         SERIAL CALLBACK FUNCTIONS                       %
%-------------------------------------------------------------------------%

% ------------------------------------------- %
% --- NORMAL STIMULI EXPERIMENT CALLBACKS --- %
% ------------------------------------------- %

% --- start callback function
function dacStart(obj,event,hD,yChng)

% sets the userdata
set(obj,'UserData',{tic,2})

% sets the initial stimuli channel amplitudes
if (verLessThan('matlab','9.2'))
    putsample(hD,yChng{1})
else
    outputSingleScan(hD,yChng{1})
end

% --- timer callback function 
function dacTimer(obj,event,hD,yChng,tChng)

% global variables
global isRT

% initialises the start time of the stimuli event
uData = get(obj,'UserData');

% determines if the time is greater than the next change event
if (toc(uData{1}) > tChng(uData{2}))
    % if so, update the stimuli channels 
    if (verLessThan('matlab','9.2'))
        putsample(hD,yChng{uData{2}})
    else
        outputSingleScan(hD,yChng{uData{2}})
    end        
        
    % increments the event counter
    uData{2} = uData{2} + 1;
    if (uData{2} > length(tChng))
        % if the there are no more events, then stop and delete the timer
        stop(obj)
        if (~isRT)
            delete(obj)
        end
    else
        set(obj,'UserData',uData);
    end
end

% --- function for when device is finished (stimuli experiment only)
function dacStop(obj, event, hSumm, eSig, ind)

% global variables
global nCountD nMaxD

% determines if there are anymore triggers to come
if (nCountD(ind) <= nMaxD(ind))        
    % updates the triggered device count within the expertiment progress GUI
    tFunc = getappdata(hSumm,'tFunc');
    tFunc([(eSig.ID+1) 2],num2str(nCountD(ind)),hSumm);        
end
    
%-------------------------------------------------------------------------%
%                              OTHER FUNCTIONS                            %
%-------------------------------------------------------------------------%

% --- determines the details of the event changes in a signal
function [yChng,tChng] = detEventChange(YY,dT)

% determines the indices where there is a change in channel amplitudes
dYY = abs(diff([-ones(1,size(YY,2));YY])) > 0;
iDiff = find(any(dYY,2));

% sets the indices/amplitudes of the channels where there is a change
yChng = num2cell(YY(iDiff,:),2);
tChng = dT*(iDiff-1);