% --- sets up the dac device (old matlab version)
function objDAC = setupDACDeviceOld(objDAC,dacType,varargin)

% global variables
global nCountD nMaxD hSumm isError

% sets the dac device properties based on the setup type
switch (dacType)
    case ('Test') % case is testing the DAC devices
        % sets the input arguments
        Ysig = varargin{1};                           
        
        % puts the data onto the DAC devices        
        for i = 1:length(objDAC)        
            % adds the output data to the device
            putdata(objDAC{i},Ysig{i});

            % sets the callback functions for the devices
            objDAC{i}.StartFcn = {@startDevice};          
            objDAC{i}.TimerFcn = {@timerDevice};                                      
            
            % resets the total samples output function count
            sAvail = get(objDAC{i},'SamplesAvailable');
            set(objDAC{i},'SamplesOutputFcnCount',sAvail,'TimerPeriod',0.01)                        
        end
        
    case ('RTShock') % case is sleep deprivation experiment
        % sets the input arguments
        hGUI = varargin{1};        
        Ysig = varargin{2};   
        iUSB = varargin{3};   
        
        % puts the data onto the DAC devices
        if (iscell(objDAC))
            % sets the callback functions for the devices
            putdata(objDAC{1},Ysig{1});
            objDAC{1}.StartFcn = {@startDeviceSD,hGUI,iUSB};
            objDAC{1}.StopFcn = {@stopDeviceSD,hGUI,iUSB};  
            objDAC{1}.TimerFcn = {@timerDeviceTest}; 
        else            
            % sets the callback functions for the devices
            putdata(objDAC(1),Ysig{1});
            objDAC(1).StartFcn = {@startDeviceSD,hGUI,iUSB};
            objDAC(1).StopFcn = {@stopDeviceSD,hGUI,iUSB};            
            objDAC(1).TimerFcn = {@timerDevice}; 
        end
        
    case ('Expt') % case is a normal experiment 
        % sets the input arguments
        [ExptSig,hSumm] = deal(varargin{1},varargin{2});
%         iUSB = varargin{3};
        
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
            % resets the stimulus counter variables 
            
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
                                         
            % sets the callback functions for the devices            
            objDAC{i}.StartFcn = {@startDevice};
            objDAC{i}.StopFcn = {@stopDevice,objDAC,hSumm,ExptSig(i),iDAC};
            objDAC{i}.TimerFcn = {@timerDevice}; 
            
            % sets the signals for the initial stimuli
            if (nCountD(iDAC) < nMaxD(iDAC))
                Ynw = ExptSig(i).Y{nCountD(iDAC)+1};
                Ynw = [Ynw;zeros(size(Ynw,2))];                
                nChannel = length(get(objDAC{i},'Channel'));
                
                % if the number of signals does not match the number of
                % channels, then expand the signal array
                if (size(Ynw,2) ~= nChannel)
                    Ynw = [Ynw,repmat(Ynw(:,end),1,nChannel-size(Ynw,2))];
                end
                
                % places the data on the DAC device
                putdata(objDAC{i},Ynw);
            end
        end                
        
        % places the stimulus time stamp array in the base workspace
        if (~isError)
            assignin('base','tStampS',tStampS)
        end
end

%-------------------------------------------------------------------------%
%                          DAC CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% ---------------------------------------------- %
% --- SLEEP DEPRIVATION EXPERIMENT CALLBACKS --- %
% ---------------------------------------------- %

% --- function for triggering the stimuli device (sleep deprivation only)
function startDeviceSD(obj, event, hGUI, iUSB)

% global variables
global tStart
tStart = toc;

% flag that the device is running
pStr = getappdata(hGUI,'pStr');
pStr.uStatus(iUSB) = true;
setappdata(hGUI,'pStr',pStr);

% --- function for when device is finished (sleep deprivation only)
function stopDeviceSD(obj, event, hGUI, iUSB)

% flag that the device is free again
pStr = getappdata(hGUI,'pStr');
pStr.uStatus(iUSB) = false;
setappdata(hGUI,'pStr',pStr);

% ------------------------------------------- %
% --- NORMAL STIMULI EXPERIMENT CALLBACKS --- %
% ------------------------------------------- %

% --- callback function that runs when starting the device
function startDevice(obj, event)

% global variables
global tTest
tTest = tic;

% --- timer callback function when running the device
function timerDevice(obj, event)

% global variables
global tTest
tNew = toc(tTest);

% determines if the device finished running
if ((tNew > (get(obj,'SamplesOutputFcnCount')/get(obj,'SampleRate'))))
    % stop the object and rezeros the device
    stop(obj)
    putdata(obj,zeros(1,length(get(obj,'Channel'))))  

    % restarts the object
    [obj.TimerFcn,obj.StartFcn] = deal([]);    
    start(obj)
end

% --- function for when device is finished (stimuli experiment only)
function stopDevice(obj, event, objDAC, hSumm, eSig, ind)

% global variables
global nCountD nMaxD

% determines if there are anymore triggers to come
if (nCountD(ind) <= nMaxD(ind))        
    % updates the triggered device count within the expertiment progress GUI
    tFunc = getappdata(hSumm,'tFunc');
    tFunc([(eSig.ID+1) 2],num2str(nCountD(ind)),hSumm);
        
    % places the next signal data onto the DAC device
    if ((nCountD(ind)+1) <= length(eSig.Y))
        putdata(objDAC{eSig.ID},eSig.Y{nCountD(ind)+1}); 
    else
        putdata(objDAC{eSig.ID},zeros(1,size(eSig.Y{end},2)))
    end
end
