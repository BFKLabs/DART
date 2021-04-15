classdef RunExptObj < handle
    % class properties
    properties
        % object handles/arrays
        hMain
        hExpt
        hExptF
        hProg
        hAx
        objIMAQ
        objDACInfo
        objDev  
        objDRT
                
        % data structs/timers
        iExpt
        iExpt0
        iStim
        sTrain
        ExptSig
        hTimerExpt
        hTimerCDown   
        hTrack
        tStampV
        vidType
        
        % real-timer tracking objects
        stimTS
        iEventS
        
        % parameter values/arrays
        FPS
        nCountD
        nCountV
        nMaxD    
        nMaxV
        nPause
        tStart
        tCDown
        tEvent
        timerOfs
        tNew
        tExpt
        tVid
        tOfsT        
        vType
        vPara
        vParaVV
        
        % boolean flags
        hasDAC
        iEvent
        indOfs 
        indFrmNw 
        isStart 
        isError 
        isStopped        
        isMemLog
        isOK
        isRT
        isRTB
        isRTBatch
        isRTExpt           
        isRot
        isSaving
        isTrigger
        isUserStop                 
        userStop   
        hasStim
    end

    % class methods
    methods
        % class constructor
        function obj = RunExptObj(hMain,vidType,varargin)
            
            % sets the main object fields
            obj.hMain = hMain;                             
            
            % sets the other minor object fields
            obj.vidType = vidType;
            [obj.iEvent,obj.isOK] = deal(1);
            [obj.indOfs,obj.indFrmNw] = deal(0);       
            [obj.isUserStop,obj.isStart] = deal(false);
            [obj.isError,obj.isStopped,obj.hasDAC] = deal(false);             
            
            %
            switch obj.vidType
                case 'Expt'
                    % sets the input arguments
                    hExptF = varargin{1};                    
                    isRTBatch = varargin{2};
                    isRTExpt = varargin{3};          
            
                    % retrieves the stimuli/experiment data structs 
                    obj.hExptF = hExptF;   
                    iExpt0 = getappdata(obj.hExptF,'iExpt');                    
                    obj.sTrain = getappdata(obj.hExptF,'sTrain'); 
                    obj.iStim = getappdata(obj.hMain,'iStim');
                    
                    % sets the other fields
                    [obj.iExpt,obj.iExpt0] = deal(iExpt0);    
                    [obj.isRT,obj.isRTB] = deal(isRTExpt,isRTBatch);
                    
                    % initialises the experiment object
                    obj.initExptObjFields();   
                    
                case 'Test'
                    % sets the input variables and other important fields
                    [obj.vPara,obj.vParaVV] = deal(varargin{1});
                    [obj.isRT,obj.isRTB] = deal(false);
                    obj.iExpt = getappdata(obj.hMain,'iExpt');
                    
                    % sets up the camera properties           
                    obj.initCameraProperties();
                    
            end                                   
                                            
        end        

        % -------------------------------------- %        
        % ----    OBJECT INITIALISATIONS    ---- %
        % -------------------------------------- %        
        
        % --- initialises the experiment object
        function initExptObjFields(obj)
            
        % sets up the camera properties           
        obj.initCameraProperties();  
        obj.objDACInfo = getappdata(obj.hMain,'objDACInfo');

        % deletes any previous experiment timers
        hTimerExptOld = timerfindall('tag','hTimerExpt');
        if ~isempty(hTimerExptOld)
            deleteTimerObjects(hTimerExptOld);
        end

        % adds the output solution directory (if not already set)
        if ~isfield(obj.iExpt.Info,'OutSoln')
            obj.iExpt.Info.OutSoln = [];
        end              
        
        % sets up the experimental stimulus signals
        if ~isempty(obj.sTrain)
            % sets the DAC device flags
            obj.hasDAC = any(strcmp(obj.objDACInfo.dType{1},'DAC'));
            if ~obj.isRT
                % sets up the stimuli signals for the experiment
                obj.setupExptStimSignals(); 
            end
        end     
        
        % creates the experiment progress summary GUI
        obj.hProg = ExptProgress(obj); 
        pause(0.05)            
        
        % sets the video parameter structs
        if ~isempty(obj.ExptSig)
            % initialisations and array dimensioning                
            ID = field2cell(obj.ExptSig,'ID',1);                
            isD = strcmp(obj.objDACInfo.dType(unique(ID(:,1))),'DAC');
            nCh = size(unique(ID,'rows'),1);

            % memory allocations
            nDAC = sum(isD);
            nCont = nDAC + any(~isD);
            obj.nCountD = zeros(nCh,1);
            obj.objDev = cell(nCont,1);                   

            % sets up the DAC devices (if any)
            if any(isD)
                % memory allocation
                objDACT = createDACObjects(obj.objDACInfo,50);        
                if (~isempty(objDACT))
                    obj.objDev(isD) = setupDACDevice(...
                                objDACT,'Expt',obj.ExptSig,obj.hProg);        
                end                
            end

            % sets up the serial devices (if any)
            if any(~isD)
                obj.objDev{nDAC+1} = setupSerialDevice(...
                            obj.objDACInfo,'Expt',obj,find(~isD));         
            end    
            
            % sets the stimuli flags for each device
            obj.hasStim = cellfun(@(x)(x.nCountD>0),obj.objDev,'un',0);            
        end     

        % if a real-time tracking experiment, then initialise the RT 
        % data struct and tracking GUI
        if obj.isRT; obj.initRTExptObj(); end    
        
        % updates the fields of the progress-bar gui
        setappdata(obj.hProg,'sFunc',@obj.saveSummaryFile);
        setappdata(obj.hProg,'iExpt',obj.iExpt)            

        % initalises the countdown/experiment timers
        obj.initExptTimer();
        obj.initCDownTimer();
        obj.saveSummaryFile();
        
        end
        
        % --- initialises the real-time experiment fields
        function initRTExptObj(obj)
            
            % initialises the RT data struct into the main GUI
            rtP = getappdata(obj.hMain,'rtP');

            % creates new device objects (if they are invalid/deleted)
            if (obj.hasDAC)
                obj.objDACInfo.Control = ...
                            createDACObjects(obj.objDACInfo,[]);            
                setappdata(obj.hMain,'objDACInfo',obj.objDACInfo)    
            end

            % it stimulating (for single pulse signals) then allocate 
            % memory for the stimuli event time/index arrays    
            if (strcmp(rtP.Stim.sType,'Single'))
                % determines the number of channel used for stimulation
                if any(strcmp(obj.objDACInfo.dType,'DAC'))
                    % case is the DAC device is being used
                    nCh = length(unique(obj.iStim.ID(:,1)));
                    obj.objDRT = cell(nCh,1);                               
                else
                    % case is the Serial Controller is being used
                    nCh = size(rtP.Stim.C2T,1);                
                end

                % memory allocation
                obj.stimTS = cell(nCh,1);
                obj.iEventS = zeros(nCh,1);
            end      

            % if there are no markers, then initialise them
            if (isempty(getappdata(obj.hMain,'hMark')))
                uFunc = getappdata(obj.hMain,'initMarkerPlots');
                uFunc(obj.hMain);
            end

            % creates the tracking GUI and enables the show marker checkbox
            obj.hTrack = TrackingStats(obj.hMain,true);
            setappdata(obj.hMain,'hTrack',obj.hTrack)
            set(findobj(obj.hMain,'tag','checkShowMarkers'),...
                       'value',1,'enable','on')                        
        end
        
        % --- initialises the camera properties
        function initCameraProperties(obj)

        % sets the image acquisition object handle
        obj.objIMAQ = getappdata(obj.hMain,'objIMAQ');

        % if the camera is running, then stop it
        if isrunning(obj.objIMAQ)
            stop(obj.objIMAQ)
        end            
        
        % sets the rotation flag and recording logging mode
        obj.isRot = getappdata(obj.hMain,'isRot');            
        if obj.isRot
            [obj.objIMAQ.LoggingMode,obj.isMemLog] = deal('memory',1);
        else
            [obj.objIMAQ.LoggingMode,obj.isMemLog] = deal('disk',0);
        end            

        % sets the camera frame rate
        srcObj = getselectedsource(obj.objIMAQ);
        [fRate,~,iSel] = detCameraFrameRate(srcObj,[]);
        obj.FPS = fRate(iSel);        

        % initialises the real-time batch processing (if required)
        if (obj.isRTB)
            initRTBatchProcess()             
        end         

        % retrieves the resolution of the recording image
        vRes = get(obj.objIMAQ,'VideoResolution');
        if (obj.isRot)
            % case is the image is rotated
            Img0 = zeros(vRes);
        else
            % case is the image is not rotated
            Img0 = zeros(vRes([2 1]));
        end

        % sets the current access to be the main gui axes handle
        obj.hAx = findobj(obj.hMain,'type','axes');
        set(obj.hMain,'CurrentAxes',obj.hAx);        
        
        % sets the empty images into the recording axes
        set(findobj(obj.hAx,'Type','Image'),'cData',Img0);
        setupVideoRecord(obj);
        setappdata(obj.hAx,'hImage',[]);                    
        
        end
        
        % ----------------------------------------------- %        
        % ----    EXPERIMENT START/STOP FUNCTIONS    ---- %
        % ----------------------------------------------- %       
        
        % --- initialises the experiment object
        function startExptObj(obj)
                        
        if ~obj.isOK
            % if there was an error during the setup phase, then make 
            % the experiment setup GUI visible again
            setObjVisibility(obj.hExptF,'on')
        else
            % otherwise, start the experiment timer
            start(obj.hTimerCDown)
        end   
            
        end  
        
        % --- performs the house-keeping rountines after the fly experiment
        function finishExptObj(obj)

        % determines if the experiment has already stopped
        if obj.isStopped
            % if so, then exit the function
            return
        else
            % otherwise, flag that the experiment is finished
            obj.isStopped = true;
        end

        % retrieves the image/data acquisition objects
        aFunc = getappdata(obj.hExptF,'afterExptFunc');
        if ishandle(obj.hProg) 
            set(obj.hProg,'WindowStyle','normal'); 
        end

        % deletes the timer objects
        if ~obj.isUserStop
            wState = warning('off','all');   
            stop(obj.hTimerExpt); 
            warning(wState);
        end

        % deletes the timer objects
        wState = warning('off','all');
        delete(obj.hTimerCDown);     
        delete(obj.hTimerExpt);
        warning(wState);

        % resets the preview axes image to black
        vRes = get(obj.objIMAQ,'VideoResolution');
        if obj.isRot
            Img0 = zeros(vRes);    
        else
            Img0 = zeros(vRes([2 1]));
        end
        set(findobj(obj.hAx,'Type','Image'),'cData',Img0);

        % determines if the real-time tracking expt is being run
        if obj.isRT
            % if so, ensure the markers are invisible
            hCheck = findobj(obj.hMain,'tag','checkShowMarkers');
            set(setObjEnable(hCheck,'off'),'value',0)   
            hMark = getappdata(obj.hMain,'hMark');
            for i = 1:length(hMark)
                cellfun(@(x)(setObjVisibility(x,'off')),hMark{i})
            end 

            % deletes the tracking GUI
            if ~isempty(obj.hTrack); delete(obj.hTrack); end       
        end      
        
        % if the experiment did not start, then delete the sub-GUI and exit
        if ~obj.isStart
            % attempts to close any logfile (if one exists)
            wState = warning('off','all');
            try; close(getLogFile(obj.objIMAQ)); end
            warning(wState);

            % deletes the video output directory
            vDir = fullfile(obj.iExpt.Info.OutDir,obj.iExpt.Info.Title);
            deleteAllFiles(vDir,'*.*',1)

            % deletes the solution output directory (if it exists)
            if ~isempty(obj.iExpt.Info.OutSoln)
                sDir = fullfile(obj.iExpt.Info.OutSoln,...
                                obj.iExpt.Info.Title);
                deleteAllFiles(sDir,'*.*',1)
            end

            % makes the experimental info GUI visible again and sets focus
            setObjVisibility(obj.hExptF,'on')
            figure(obj.hExptF)    

            % deletes the experimental GUI
            delete(obj.hProg)
            aFunc(obj.hExptF)
            return
        else
%             % check to see that the devices have all been turned 
%             % off correctly
%             obj.forceStopDevices()   
            
            % determines if the disk logger object still exists
            if obj.objIMAQ.TriggersExecuted == 1
                % if so, then close and delete the movie   
                logFile = getLogFile(obj.objIMAQ);
                fName = get(logFile,'FileName');

                % closes the log file and deletes it
                wState = warning('off','all');
                close(logFile);        
                delete(fName)  
                warning(wState)
            end
        end

        % determines if the experiment was stopped by the user
        if obj.isUserStop
            % determines if there were any experiment timers
            hTimerExptOld = timerfindall('tag','hTimerExpt');
            if ~isempty(hTimerExptOld)
                deleteTimerObjects(hTimerExptOld); 
            end                    
            
            % if so, then prompt to store the experimental data
            uChoice = questdlg(['Do you want to keep data from the ',...
                     'partial experimental?'],'Store Experimental Data',...
                     'Yes','No','Yes');    
            isStore = strcmp(uChoice,'Yes');
        else
            % otherwise, store the experimental data automatically
            isStore = true;
        end

        % closes the experimental information
        if isStore
            wStr = sprintf('Saving Experiment Summary (100%s)','%');
            pFunc = getappdata(obj.hProg,'pFunc');
            pFunc(1,wStr,1,obj.hProg);
            pause(0.05);

            % saves the summary file to disk
            obj.saveSummaryFile()
        else
            % deletes the video output directory
            pause(1)
            vDir = fullfile(obj.iExpt.Info.OutDir,obj.iExpt.Info.Title);
            deleteAllFiles(vDir,'*.*',1)
        end

        % closes the experiment progress GUI
        try; delete(obj.hProg); end                 
        
        % if there are any stimuli devices, then ensure they are stopped
        if ~isempty(obj.sTrain.Ex)
            if obj.hasDAC
                obj.resetDACDevice()    
            end                                                   

            % stops any of the serial devices
            isS = cellfun(@(x)(isa(x,'StimObj')),obj.objDev);
            for i = find(isS(:)')
                obj.objDev{i}.stopAllDevices();
            end                    
        end             
        
        % either closes the experiment run function, or continue onto the 
        % next individual experiment (if there are still experiments to run)
        if obj.isUserStop
            % if the user stopped the experiment then perform the 
            % house-keeping exercises

            % makes the experimental info GUI visible again and sets focus
            setObjVisibility(obj.hExptF,'on')
            figure(obj.hExptF)

            % clears the camera callback functions
            [obj.objIMAQ.StopFcn,obj.objIMAQ.StartFcn] = deal([]);
            [obj.objIMAQ.TriggerFcn,obj.objIMAQ.TimerFcn] = deal([]);
            setappdata(obj.hMain,'objIMAQ',obj.objIMAQ)    
            setappdata(obj.hMain,'iExpt',obj.iExpt0)    

            % if running a RT-tracking experiment (and outputting the solution file
            % directly) then combine the final solution files
            if obj.isRT && ~isempty(obj.iExpt.Info.OutSoln)
                if obj.isUserStop
                    sDir = fullfile(obj.iExpt.Info.OutSoln,...
                                    obj.iExpt.Info.Title);
                    deleteAllFiles(sDir,'*.*',1)
                else
                    combineRTSolnFiles(obj.iExpt)
                end
            end
        end          
        
        % runs the after experiment function
        aFunc(obj.hExptF)           
            
        end                 
            
        % --------------------------------- %
        % --- COUNTDOWN TIMER FUNCTIONS --- %
        % --------------------------------- %        
        
        % --- initalises the countdown timer
        function obj = initCDownTimer(obj)
        
        % creates the timer object
        obj.hExpt = guidata(obj.hExptF);
        obj.hTimerCDown = timer;
        obj.nPause = 5*(1 + ~obj.isError);
        
        % sets the start time based on the experiment type
        if obj.iExpt.Timing.fixedT0
            % case is the experiment starts at a fixed time
            obj.tStart = datenum(obj.iExpt.Timing.T0); 
        else                
            % case is the experiment starts immediately
            obj.tStart = addtodate(now,obj.nPause,'second');
            obj.iExpt.Timing.T0 = datevec(obj.tStart);    
        end    

        % sets the timer object properties
        set(obj.hTimerCDown,'Period',0.2,...
                   'ExecutionMode','FixedRate',...
                   'StartFcn',{@(h,e)obj.startCDownFcn},...
                   'TimerFcn',{@(h,e)obj.timerCDownFcn},...           
                   'StopFcn',{@(h,e)obj.stopCDownFcn});   
        setappdata(obj.hProg,'cdownTimer',obj.hTimerCDown)                

        end
               
        % --- the countdown timer callback function       
        function startCDownFcn(obj)

        % sets the start countdown time
        tic;
        obj.tCDown = calcTimeDifference(datevec(obj.tStart),datevec(now));

        % pauses the program so as to update
        pause(0.01)
        
        end

        % --- the countdown timer callback function       
        function timerCDownFcn(obj)

        % determines the time until the experiment is due to start
        dT = obj.tCDown - toc;

        % updates the details based on whether the experiment has 
        % started or not
        if (dT < 0)
            % if the time is past the start time, then stop the timer
            stop(obj.hTimerCDown)
        else
            % otherwise, update the summary figure
            pFunc = getappdata(obj.hProg,'pFunc');
            [~,~,C] = calcTimeDifference(dT);
            wStrNw = sprintf('Time Until Experiment Starts = %s:%s:%s:%s',...
                                                    C{1},C{2},C{3},C{4});

            % updates the countdown timer
            if (pFunc(1,wStrNw,1-dT/obj.tCDown,obj.hProg))
                % if the user has aborted, then exit the function
                obj.isUserStop = true;
                stop(obj.hTimerCDown)
            end
        end
        
        end

        % --- the countdown timer stop callback function       
        function stopCDownFcn(obj)

        % checks to see the state of the experiment progress bar
        if obj.isUserStop
            % if the user aborted, then exit the experiment
            obj.finishExptObj()       
        else
            % if still open, then update the summary figure
            pFunc = getappdata(obj.hProg,'pFunc');
            pFunc(1,'Starting Experiment',1,obj.hProg);     

            % otherwise, start the experiment timer
            obj.isStart = true;
            start(obj.hTimerExpt)
        end        
        
        end
        
        % ---------------------------------- %
        % --- EXPERIMENT TIMER FUNCTIONS --- %
        % ---------------------------------- %        
        
        % --- initalises the experiment timer
        function initExptTimer(obj)

        % creates the timer object
        obj.timerOfs = 0;
        obj.hTimerExpt = timer;

        % sets the total number of frames
        if isempty(obj.iExpt.Video.FPS)
            % sets the camera frame rate
            srcObj = getselectedsource(obj.objIMAQ);
            [fRate,~,iSel] = detCameraFrameRate(srcObj,[]);
            obj.iExpt.Video.FPS = fRate(iSel);               
        end
        
        % sets up the object time array
        obj.FPS = roundP(1/obj.iExpt.Video.FPS,0.001); 
        obj.setVideoEventArray();

        % sets the timer object properties
        set(obj.hTimerExpt,'Period',obj.FPS,...
                           'ExecutionMode','FixedRate',...
                           'StartFcn',{@(h,e)obj.startExptFcn},...
                           'TimerFcn',{@(h,e)obj.timerExptFcn},...
                           'StopFcn',{@(h,e)obj.stopExptFcn},...
                           'TasksToExecute',inf);
        setappdata(obj.hProg,'exptTimer',obj.hTimerExpt)                

        end
        
        % --- the experiment timer callback function       
        function startExptFcn(obj)
            
        % starts the serial devices (if any exist)
        if ~isempty(obj.objDev)
            % if so, determine if any serial devices exist (if so, then
            % start the stimuli object timers)
            isS = cellfun(@(x)(isa(x,'StimObj')),obj.objDev);
            if any(isS)
                hTimerStim = cellfun(@(x)(x.hTimer),obj.objDev,'un',0);
                cellfun(@start,hTimerStim)
            end
        end
            
        end
               
        % --- the experiment timer callback function       
        function timerExptFcn(obj)

        % gets the current frames
        hTimer = obj.hTimerExpt;
        iFrm = get(hTimer,'TasksExecuted') + obj.indOfs;        

        % sets the sub-structs
        VV = obj.iExpt.Video;
        tTot = vec2sec(obj.iExpt.Timing.Texp);

        % checks to see if the user aborted the experiment. if so, then 
        % stop the timer object and exit the function
        if get(getappdata(obj.hProg,'hBut'),'value')
            % flag that the user has aborted the experiment
            [obj.isUserStop,obj.userStop] = deal(true);

            % stops the timer object and the camera
            if (get(obj.objIMAQ,'TriggersExecuted') >= 1)
                % camera has been triggered, so remove stop function
                stop(obj.objIMAQ)    
        %         obj.hTimerExpt.StopFcn = [];
            else
                % attempts to close the video file
                wState = warning('off','all');
                close(getLogFile(obj.objIMAQ));
                warning(wState)
            end

            % stops/deletes the experiment timer
            try
                stop(obj.hTimerExpt)
                delete(obj.hTimerExpt)
            end
            return
        end

        % -------------------------------- %        
        % --- STIMULI EVENT TRIGGERING --- %
        % -------------------------------- %

        % determines if the current frame is an event frame
        if obj.iEvent <= size(obj.tEvent,1)
            % if not logging, then retrieve the current time
            if ~islogging(obj.objIMAQ)
                if isempty(obj.tExpt)
                    obj.tNew = 0;
                else
                    obj.tNew = toc(obj.tExpt);
                end
            end

            % determine if a new event has taken place
            if obj.tNew >= obj.tEvent{obj.iEvent,1}
                % if so, loop through all the event types triggering 
                % the devices
                for i = 1:length(obj.tEvent{obj.iEvent,2})
                    if strcmp(obj.tEvent{obj.iEvent,2}{i},'V')
                        % while the program is still outputting an 
                        % experimental video, keep pausing the program
                        while obj.isSaving
                            pause(1/obj.FPS)
                        end                                    

                        % attempt to trigger the camera.
                        nTrig = 0;
                        while ~islogging(obj.objIMAQ)
                            % if there was an error, then pause for a
                            % little bit
                            if (nTrig > 0)
                                pause(0.25); 
                                fprintf(['Re-Triggering Attempt ',...
                                         '#%i\n'],nTrig)
                            end                        

                            % if the camera is off, then restart it
                            if strcmp(get(obj.objIMAQ,'running'),'off')
                                start(obj.objIMAQ);
                            end

                            % attempts to re-trigger the camera
                            trigger(obj.objIMAQ);                
                            nTrig = nTrig + 1;
                        end
                    end
                end

                % increments the event counter
                obj.iEvent = obj.iEvent + 1;
            end
        end

        % otherwise, update the summary figure (every second)
        if (mod(iFrm,roundP(obj.iExpt.Video.FPS)) == 1)
            % ---------------------------------- %
            % --- EXPERIMENT PROGRESS UPDATE --- %
            % ---------------------------------- %

            if isempty(obj.hProg) || ~ishandle(obj.hProg)
                % if the figure handle is invalid, then exit the function
                return
            else
                % otherwise, set a copy of the current time
                tCurr = obj.tNew;        

                % updates the overall progress
                pFunc = getappdata(obj.hProg,'pFunc');
                pFunc(1,sprintf('Overall Progress (%i%s Complete)',...
                        floor(100*(tCurr/tTot)),'%'),tCurr/tTot,obj.hProg); 
            end

            % if the first video has not started, then update the countdown
            if tCurr < obj.iExpt.Video.Ts(1)
                nSec = roundP(obj.iExpt.Video.Ts(1) - tCurr);
                wStr = sprintf(['Waiting For Recording To Start (%i ',...
                                'Seconds Remain)'],nSec);
                pFunc(2,wStr,0,obj.hProg);
            end    

            % ------------------------------ %
            % --- STIMULUS TIMING UPDATE --- %
            % ------------------------------ %            
            
            % initialisations
            isRunning = false;
            hText = getappdata(obj.hProg,'hText');
            nInfo = getappdata(obj.hProg,'nInfo');
            
            % expands the running flags and stimuli start/finish time (if
            % the experiment has stimuli)
            if nInfo > 1                
                isRunning = [isRunning;cell2mat(cellfun(@(x,ok)...
                        (x.isRunning(ok)'),obj.objDev,obj.hasStim,'un',0))];
                tSigSF = cell2mat(cellfun(@(x,ok)...
                        (x.tSigSF(:,ok)),obj.objDev(:)',...
                        obj.hasStim(:)','un',0));
            end                        

            % loops through all the information fields getting the 
            for i = 1:nInfo 
                % retrieves the current/total event counts
                k = nInfo - (i-1);
                jStim = str2double(get(hText{k,2},'string'));
                nStim = str2double(get(hText{k,3},'string'));                  
                               
                % determines if the stimuli is current running
                if isRunning(i)
                    % if so then reset the time remaining for the event
                    tCol = 'r';

                    % determines the time remaining for the event
                    tDiffR = floor(tSigSF(2,i-1) - tCurr);
                    if tDiffR < 0
                        % if less than zero
                        nwStr = 'N/A';
                    else
                        nwStr = sprintf('%is Remain',tDiffR);
                    end  

                elseif (jStim == nStim)
                    % if there are no more events then set the time to N/A
                    [nwStr,tCol] = deal('N/A','r');
                    
                else 
                    
                    % otherwise, sets the time until the next event is
                    % supposed to occur
                    if i == 1
                        % case is the video recordings
                        tDiffS = roundP(VV.Ts(jStim+1) - tCurr); 
                    else
                        % case is the stimuli events
                        tDiffS = max(0,roundP(tSigSF(1,i-1) - tCurr));
                    end

                    % set the time to the next event
                    [dT,~,tStr] = calcTimeDifference(max(tDiffS,0));
                    nwStr = sprintf('%s:%s:%s:%s',...
                                    tStr{1},tStr{2},tStr{3},tStr{4});        

                    % sets the text colour (red if time is < 15sec)
                    if (dT < 15)
                        tCol = [255,165,0]/255;
                    else
                        tCol = 'k';                    
                    end
                end

                % if there are no more events, then set the time to N/A
                set(hText{k,4},'string',nwStr,'ForegroundColor',tCol)        
            end   
        end       

        % sets the new frame index (the total number of task executed)
        obj.indFrmNw = get(hTimer,'TasksExecuted');

        end
        
        % --- the experiment timer stop callback function       
        function stopExptFcn(obj)
            
        % if the user aborted, then exit the experiment
        if ~obj.isError
            if obj.isUserStop
                obj.finishExptObj()
            end
        end        
        
        end        

        % ------------------------------------- %
        % --- STIMULI EVENT SETUP FUNCTIONS --- %
        % ------------------------------------- %           
        
        % --- sets up the experimental stimuli signal data array
        function setupExptStimSignals(obj)

            % --- repeats the stimuli blocks and adds on the time offset
            function xySigS = repeatStimBlocks(xySigS,sParaEx)

            % calculates the time offset of the block (in seconds)
            tStimNw = vec2sec(sParaEx.tStim);
            tOfs = sParaEx.tOfs*getTimeMultiplier('s',sParaEx.tOfsU);

            % repeats/appends the signals depending on the repetition count 
            xySigS{1} = arrayfun(@(x)(xySigS{1}+(x-1)*tStimNw + tOfs),...
                                           (1:sParaEx.nCount)','un',0);
            xySigS{2} = repmat({xySigS{2}},sParaEx.nCount,1);   
                                       
            end

        % if there are no experiment stimuli trains, then exit
        if isempty(obj.sTrain.Ex)
            return
        end

        % field retrival
        chInfo = getappdata(obj.hExptF,'chInfo');
        sRate = field2cell(obj.iStim.oPara,'sRate',1);
        sTrainS = obj.sTrain.Ex.sTrain;
        sParaEx = obj.sTrain.Ex.sParaEx;

        % memory allocation
        nTrain = length(sTrainS);
        sRate = sRate(1);

        % calculates the signals for the current train
        xySigS = arrayfun(@(x)(setupDACSignal...
                                    (x,chInfo,1/sRate)),sTrainS,'un',0);
        
        % calculates the serial device signals (for each device)
        for i = 1:nTrain
            if i == 1
                % memory allocation for the full x/y data values
                xySigF = cellfun(@(x)(cell(length(x),2)),xySigS{i},'un',0);
            end

            % repeats the signals for each channel within the train
            for j = 1:length(xySigS{i})
                for k = 1:size(xySigS{i}{j},1)
                    if ~isempty(xySigS{i}{j}{k,1})
                        % repeats the stimuli blocks
                        xySigSR = repeatStimBlocks(xySigS{i}{j}(k,:),...
                                                   sParaEx(i));

                        % appends the new data values onto the full 
                        % signal arrays
                        if isempty(xySigF{j}{k,1})
                            xySigF{j}{k,1} = xySigSR{1}(:);
                            xySigF{j}{k,2} = xySigSR{2}(:);
                        else
                            xySigF{j}{k,1} = [xySigF{j}{k,1};xySigSR{1}(:)];
                            xySigF{j}{k,2} = [xySigF{j}{k,2};xySigSR{2}(:)];
                        end
                    end
                end
            end
        end

        % memory allocation
        nDev = length(xySigF);
        sStr = struct('XY',[],'Ts',[],'Tf',[],'ID',[]);
        obj.ExptSig = repmat(sStr,nDev,1);

        % stores the information for each device
        for i = 1:nDev
            % sets the signal data
            obj.ExptSig(i).XY = xySigF{i};

            % retrieves channel ID flags for each stimuli for the device
            ii = find(~cellfun(@isempty,xySigF{i}(:,1)));
            iChID = cell2mat(arrayfun(@(x)...
                            (x*ones(length(xySigF{i}{x,1}),1)),ii,'un',0));

            % retrieves the start/end values of each sub-signal and sorts 
            % them in chronological order
            tStim = cell2mat(cellfun(@(y)(cell2mat(cellfun(@(x)(x([1,end])'),...
                             y,'un',0))),xySigF{i}(ii,1),'un',0));
            [~,iS] = sort(tStim(:,1));    

            % sets the final start/finish times and the ID flags
            obj.ExptSig(i).Ts = tStim(iS,1);
            obj.ExptSig(i).Tf = tStim(iS,2);
            obj.ExptSig(i).ID = [i*ones(length(iChID),1),iChID(iS)];
        end
        
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %       

        % --- resets the DAC device
        function resetDACDevice(obj)

        if (verLessThan('matlab','9.2'))
            % determines the DAC types         
            for i = 1:length(obj.objDev)
                % zeros the DAC device and deletes it
                if (isa(obj.objDev{i},'analogoutput'))
                    while (1)
                        try
                            % attempts to reset the DAC with zeros
                            putdata(obj.objDev{i},...
                                zeros(1,obj.iStim.nChannel(i)));                                                
                            start(obj.objDev{i});                            

                            % exits the loop
                            break
                        catch ME
                            % if there was an error, then pause for 
                            % a short time...
                            pause(0.05)
                        end
                    end

                    % deletes the DAC object
                    delete(obj.objDev{i})
                end
            end                
        else
            % resets the dac devices
            daq.reset;
        end        
        
        end        
        
        % --- force stops any serial devices
        function forceStopDevices(obj)
                   
        % initialisations and array dimensioning                
        ID = field2cell(obj.ExptSig,'ID',1);                
        isD = strcmp(obj.objDACInfo.dType(unique(ID(:,1))),'DAC');        
           
        % function only applies to serial devices
        if any(~isD)
            % for each serial device, write zero signals to the devices
            obj.objDev{end}.forceStopDevices()            
        end
        
        end
        
        % --- saves the summary file to disk --- %
        function saveSummaryFile(obj)

        % retrieves the video time-stamp arrays
        a = struct('tStampV',[]);
        a.tStampV = obj.tStampV;
        [a.iExpt,a.iStim,a.sTrain] = deal(obj.iExpt,obj.iStim,obj.sTrain);

        % retrieves the experiment stimuli time-stamp arrays (based on
        % whether it was a stimuli experiment or not)
        if isempty(obj.objDev)
            [a.tStampS,a.iStampS] = deal([]);
        else
            a.iStampS = cell2cell(cellfun(@(x)(x.iChMap),...
                                    obj.objDev(:),'un',0));
            a.tStampS = cell2cell(cellfun(@(x,ok)(x.tStampS(ok)),...
                                    obj.objDev,obj.hasStim,'un',0));   
        end

        % removes any nan-time video stamps by interpolating the other time 
        % values (only do this if there are any videos that have been 
        % recorded)
        iVideo = find(cellfun(@(x)(~all(isnan(x))),a.tStampV),1,'last');
        if (~isempty(iVideo))
            ii = isnan(a.tStampV{iVideo}); 
            if (any(ii))
                jj = find(~ii); ii = find(ii);
                if length(jj) > 1
                    a.tStampV{iVideo}(ii) = interp1(jj,...
                             a.tStampV{iVideo}(jj),ii,'linear','extrap');
                end
            end
        end

        % creates the video file output directory
        summDir = fullfile(obj.iExpt.Info.OutDir,obj.iExpt.Info.Title);
        if (~exist(summDir,'dir')); mkdir(summDir); end
        summFile = fullfile(summDir,'Summary.mat');

        % creates the solution file output directory (if required)
        if (isfield(obj.iExpt.Info,'OutSoln'))
            if (~isempty(obj.iExpt.Info.OutSoln))
                solnDir = fullfile(obj.iExpt.Info.OutSoln,...
                                   obj.iExpt.Info.Title);
                if ~exist(solnDir,'dir')
                    % if the output solution file directory does not exist,
                    % then create it
                    mkdir(solnDir); 
                end
            end
        end

        % sets the output data based on whether a RT tracking expt is running
        if obj.isRT
            % retrieves the required data structs
            rtD = getappdata(obj.hMain,'rtD');
            a.iMov = getappdata(obj.hMain,'iMov');
            a.sData = rtD.sData;
            a.iExpt.rtP = getappdata(obj.hMain,'rtP');
        else
            % otherwise, then set an empty SD shock time/sub-region data struct
            [a.sData,a.iMov] = deal(0,struct);
        end

        % outputs the summary file and updates the shock data array
        save(summFile,'-struct','a') 
        
        end
        
        % --- sets up the timer events array
        function setVideoEventArray(obj)

        % field retrieval
        VV = obj.iExpt.Video;
        vEvent = [num2cell(VV.Ts) repmat({'V'},length(VV.Ts),1)];        

        % resorts the total events array by the start times
        [~,ii] = sort(cell2mat(vEvent(:,1)));
        vEvent = vEvent(ii,:);

        % determines the events where the time is greater than one (i.e., 
        % events of different frames) and groups the indices which are 
        % the same
        jj = find(diff(cell2mat(vEvent(:,1))) > 1);

        % resets the array so as to group equally timed events
        if (isempty(jj))
            B = {vEvent};
        else    
            ind = [[1;(jj(1:end)+1)] [jj;length(vEvent)]];
            B = cellfun(@(x)(vEvent(x(1):x(2),:)),num2cell(ind,2),'un',0);
        end

        % collapses the array into a single cell array
        tEvent0 = cell(length(B),2);
        for i = 1:length(B)
            [tEvent0{i,1},tEvent0{i,2}] = deal(B{i}{1,1},B{i}(:,2)');
        end        
        
        % sets the time event field
        obj.tEvent = tEvent0;
        
        end
            
    end
end
