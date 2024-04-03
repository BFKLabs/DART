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
        objDAQ
        objDev  
        objDRT
        spixObj
        extnObj
                
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
        rfRate
        resInfo
        iRW
        iCW
        
        % large-video handling fields
        vComp0
        vCompStr
        isConvert

        % camera check class fields
        vB0
        ImgAvg0
        hTimerChk        
        dImgTol = 3;
        tDelayChk = 1;
        tagStrChk = 'hTimerChk';

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
        isSaving
        isTrigger
        isUserStop
        isWebCam
        isTest
        hasDAQ
        hasIMAQ
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
            [obj.isError,obj.isStopped,obj.hasDAC] = deal(false);   
            [obj.isUserStop,obj.isStart,obj.isConvert] = deal(false);
            
            % sets the image acquisition object handle
            infoObj = getappdata(obj.hMain,'infoObj');
            obj.hasDAQ = infoObj.hasDAQ;
            obj.hasIMAQ = infoObj.hasIMAQ;
            obj.objIMAQ = infoObj.objIMAQ;
            obj.isWebCam = infoObj.isWebCam;
            obj.isTest = infoObj.isTest;
            
            %
            switch obj.vidType
                case 'Expt'
                    % sets the input arguments
                    hExptF = varargin{1};                    
                    isRTBatch = varargin{2};
                    isRTExpt = varargin{3};                     
            
                    % retrieves the stimuli/experiment data structs 
                    obj.hExptF = hExptF;                                       
                    obj.sTrain = getappdata(obj.hExptF,'sTrain');
                    obj.extnObj = getappdata(obj.hExptF,'extnObj');
                    obj.resInfo = getappdata(obj.hExptF,'resInfo');
                    
                    % sets up the experiment data struct
                    iExpt0 = obj.getExptDataStruct();
                    
                    % sets the other fields
                    obj.iStim = infoObj.iStim;
                    [obj.iExpt,obj.iExpt0] = deal(iExpt0);    
                    [obj.isRT,obj.isRTB] = deal(isRTExpt,isRTBatch); 
                    
                    % updates the experiment information field (this could
                    % have changed when starting the expt)
                    iExptM = getappdata(hMain,'iExpt'); 
                    obj.iExpt.Info.Type = iExptM.Info.Type;                    
                    
                    % sets the video dependent fields (if recording)
                    if obj.hasIMAQ
                        obj.vCompStr = 'obj.iExpt.Video.vCompress';
                        obj.rfRate = roundP(obj.iExpt.Video.FPS);
                    else                        
                        % sets the streampix class object (if available)
                        obj.rfRate = 1;                        
                        obj.spixObj = getappdata(obj.hExptF,'spixObj');
                    end                                        
                    
                    % initialises the experiment object
                    obj.initExptObjFields();   
                    
                case 'Test'
                    % sets the input variables and other important fields
                    [obj.vPara,obj.vParaVV] = deal(varargin{1});
                    [obj.isRT,obj.isRTB] = deal(false);
                    obj.iExpt = getappdata(obj.hMain,'iExpt');                       
                    obj.vCompStr = 'obj.vPara.vCompress';                                      
                    obj.rfRate = roundP(obj.vPara.FPS);
                    
                    % checks the video resolution is correct
                    obj.isOK = checkVideoResolution(obj.objIMAQ,obj.vPara);
                    if obj.isOK
                        obj.initCameraProperties()
                    end
                    
            end    
            
            % sets up the ROI row/column indices (webcam only)
            if obj.isWebCam
                obj.setupROIIndices();

                % sets up the camera image check (expt only)
                if strcmp(obj.vidType,'Expt')
                    obj.setupCameraImageCheck();
                end
            end
                                            
        end        

        % -------------------------------------- %        
        % ----    OBJECT INITIALISATIONS    ---- %
        % -------------------------------------- %        
        
        % --- initialises the experiment object
        function initExptObjFields(obj)
            
            % creates a loadbar            
            h = ProgressLoadbar('Initialising Experiment Objects...');
            
            % initialises the camera properties (if recording)
            if obj.hasIMAQ
                h.StatusMessage = 'Initialising Camera Properties...';                
                obj.initCameraProperties();
            end
            
            % sets up the camera properties                       
            obj.objDAQ = getappdata(obj.hMain,'objDAQ');

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
            if ~isempty(obj.sTrain) && ~isempty(obj.objDAQ)
                % sets the DAC device flags
                obj.hasDAC = any(strcmp(obj.objDAQ.dType{1},'DAC'));
                
                % sets up the stimuli signals for the experiment
                if ~obj.isRT
                    h.StatusMessage = 'Setting Up Stimuli Signals...';
                    obj.setupExptStimSignals(); 
                end
            end     

            % creates the experiment progress summary GUI
            h.StatusMessage = 'Setting Up Experiment Progress Dialog...';
            obj.hProg = ExptProgress(obj); 
            pause(0.05)
            
            % resets the loadbar to be on top
            figure(h.Control)

            % sets the video parameter structs
            if ~isempty(obj.ExptSig)
                % updates the progress bar
                h.StatusMessage = 'Setting Up Stimuli Devices...';
                
                % initialisations and array dimensioning                
                ID = field2cell(obj.ExptSig,'ID',1);                  
                [~,~,iC] = unique(ID(:,1));
                isS = strcmp(obj.objDAQ.dType(unique(iC)),'Serial');
                nCh = size(unique(ID,'rows'),1);

                % memory allocations
                nCont = 1;
                obj.nCountD = zeros(nCh,1);
                obj.objDev = cell(nCont,1);                   

                % sets up the stimuli devices 
                if any(isS)     
                    % case is serial stimuli devices
                    obj.objDev{1} = setupSerialDevice(...
                                obj.objDAQ,'Expt',obj,find(isS));                    
                else
                    % case is external stimuli devices
                    obj.extnObj.setupExtnDeviceExpt(obj,find(~isS));
                    obj.objDev{1} = obj.extnObj.objD;
                    
%                     % case is external devices
%                     objDACT = createDACObjects(obj.objDAQ,50);        
%                     if ~isempty(objDACT)
%                         obj.objDev(isD) = setupDACDevice(...
%                                     objDACT,'Expt',obj.ExptSig,obj.hProg);        
%                     end
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
            
            % deletes the progressbar
            try delete(h); catch; end

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
            if obj.hasDAC
                obj.objDAQ.Control = ...
                            createDACObjects(obj.objDAQ,[]);            
                setappdata(obj.hMain,'objDAQ',obj.objDAQ)    
            end

            % it stimulating (for single pulse signals) then allocate 
            % memory for the stimuli event time/index arrays    
            if strcmp(rtP.Stim.sType,'Single')
                % determines the number of channel used for stimulation
                if any(strcmp(obj.objDAQ.dType,'DAC'))
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
            if isempty(obj.hMain.mkObj.hTube)
                obj.hMain.mkObj.initTrackMarkers();
            end

            % creates the tracking GUI and enables the show marker checkbox
            obj.hTrack = TrackingStats(obj.hMain,true);
            setappdata(obj.hMain,'hTrack',obj.hTrack)
            set(findobj(obj.hMain,'tag','checkShowMarkers'),...
                       'value',1,'enable','on')                        
        end        
        
        % --- initialises the camera properties
        function initCameraProperties(obj)
            
            % removes the timer object
            if obj.isTest
                obj.objIMAQ.hTimer = [];            
            elseif obj.isWebCam && ~isempty(obj.objIMAQ.hTimer)
                obj.objIMAQ.hTimer = [];
            end
            
            % if the camera is running, then stop it
            if isDeviceRunning(obj)
                stopRecordingDevice(obj)
            end            
            
            % checks the video compression
            obj.checkVideoCompression();              
            
            % sets the rotation flag and recording logging mode 
            if obj.isWebCam || obj.isTest
                % case is using a webcam
                obj.isMemLog = 0;
            else
                % case is using a videoinput object
                if ~isempty(obj.resInfo) && obj.resInfo.useCust
                    obj.isMemLog = 1;
                    obj.objIMAQ.LoggingMode = 'memory';
                else
                    obj.isMemLog = 0;
                    obj.objIMAQ.LoggingMode = 'disk';
                    imaqmex('feature','-limitPhysicalMemoryUsage',false)
                end                
            end

            % sets the camera frame rate
            if obj.isTest
                [fRate,iSel] = deal(obj.objIMAQ.FPS,1);
            elseif obj.isWebCam
                [fRate,~,iSel] = detWebcamFrameRate(obj.objIMAQ,[]);
            else            
                srcObj = getselectedsource(obj.objIMAQ);
                [fRate,~,iSel] = detCameraFrameRate(srcObj,[]);
            end

            % initialises the real-time batch processing (if required)
            obj.FPS = fRate(iSel);            
            if obj.isRTB
                initRTBatchProcess()             
            end         

            % retrieves the resolution of the recording image
            if ~obj.isWebCam
                vRes = getVideoResolution(obj.objIMAQ,1);
                Img0 = zeros(flip(vRes));
                set(findobj(obj.hAx,'Type','Image'),'cData',Img0);
            end
            
            % sets the current access to be the main gui axes handle
            hPanelImg = findall(obj.hMain,'tag','panelImg');
            obj.hAx = findobj(hPanelImg,'type','axes');
            set(obj.hMain,'CurrentAxes',obj.hAx);        

            % sets the empty images into the recording axes            
            setupVideoRecord(obj); 
            setappdata(obj.hAx,'hImage',[]);                    
        
        end
        
        % --- converts the recorded videos from uncompressed format to the
        %     original video compression format
        function convertExptVideos(obj)

            % converts the experiment video files from the uncompressed
            % format to the original video compression format
            if obj.isConvert
                % sets the output video directory
                switch obj.vidType
                    case 'Test'
                        vidDir = obj.vPara.Dir;
                        
                    case 'Expt'
                        Info = obj.iExpt.Info;
                        vidDir = fullfile(Info.OutDir,Info.Title);
                end

                % determines if the output video directory exists
                if exist(vidDir,'dir')
                    % if so, determine if there are any .avi files present
                    vidData = dir(fullfile(vidDir,'*.avi'));
                    if ~isempty(vidData)        
                        % retrieves the full path of the videos to convert
                        vidFile = cellfun(@(x)(fullfile(vidDir,x)),...
                                       field2cell(vidData,'name'),'un',0);

                        % converts the video files
                        convertVideoFormat(vidFile,obj.vComp0);
                    end
                end    
            end

        end        
        
        % --- checks the video compression against the video resolution. if 
        %     the video resolution is too high then use uncompressed format
        function checkVideoCompression(obj)

            % retrieves the initial 
            obj.vComp0 = eval(obj.vCompStr);
            
            % determines if the video type has compression
            isCompressed = ~strcmp(obj.vComp0,'Grayscale AVI') || ...
                           ~strcmp(obj.vComp0,'Uncompressed AVI');

            % if the video resolutio is high, and the video compression is 
            % not grayscale avi, then reset the video compression
            if isLargeVideoRes(obj.objIMAQ) && isCompressed
                % uses the uncompressed video type based on camera type
                if get(obj.objIMAQ,'NumberOfBands') == 1
                    % case is monochrome camera
                    vCompNw = 'Grayscale AVI'; 
                else
                    % case is truecolor camera
                    vCompNw = 'Uncompressed AVI'; 
                end
                
                % updates the video compression field
                eval(sprintf('%s = ''%s'';',obj.vCompStr,vCompNw));
                
                % prompt the user if they wish to compress the videos after
                % the recordings have finished
                qStr = sprintf(['Due to the camera resolution, the ',...
                                'videos will be recorded with an ',...
                                'uncompressed format.',...
                                '\n\nWould you like to convert the ',...
                                'videos to "%s" format after the ',...
                                'recordings have finished?'],obj.vComp0);            
                uChoice = questdlg(qStr,'Convert Uncompressed Videos?',...
                                   'Yes','No','Yes');     
                obj.isConvert = strcmp(uChoice,'Yes');
            end     
            
        end        
        
        % --- retrieves the experiment data struct
        function iExpt = getExptDataStruct(obj)

            % retrieve experiment data struct
            iExpt = getappdata(obj.hExptF,'iExpt');              

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
                try
                    stop(obj.hTimerExpt);
                    pause(0.05);
                catch
                end
                warning(wState);
            end

            % deletes the timer objects
            try
                wState = warning('off','all');
                delete(obj.hTimerCDown);     
                warning(wState);
            catch
            end

            % resets the preview axes image to black
            if obj.hasIMAQ
                % retrieves the original axis limits
                [xL,yL] = deal(get(obj.hAx,'xLim'),get(obj.hAx,'yLim'));
                
                % retrieves the camera resolution
                if obj.isWebCam
                    vResS = get(obj.objIMAQ,'Resolution');
                    vRes = cellfun(@str2double,strsplit(vResS,'x'));
                else
                    vRes = getVideoResolution(obj.objIMAQ,1);
                end
                
                % resets the axes image/limits
                Img0 = zeros(flip(vRes));
                set(findobj(obj.hAx,'Type','Image'),'cData',Img0); 
                set(obj.hAx,'xLim',xL,'yLim',yL)

            else
                % force stops the streampix object (if available)
                if ~isempty(obj.spixObj) && obj.isUserStop
                    obj.spixObj.forceStop()
                end                
            end

            % determines if the real-time tracking expt is being run
            if obj.isRT
                % if so, ensure the markers are invisible
                hCheck = findobj(obj.hMain,'tag','checkShowMarkers');
                set(setObjEnable(hCheck,'off'),'value',0)   
                hMark = obj.hMain.mkObj.hMark;
                for i = 1:length(hMark)
                    cellfun(@(x)(setObjVisibility(x,'off')),hMark{i})
                end 

                % deletes the tracking GUI
                if ~isempty(obj.hTrack); delete(obj.hTrack); end       
            end      

            % if the experiment didn't start then delete the sub-GUI & exit
            if ~obj.isStart
                % attempts to close any logfile (if one exists)
                wState = warning('off','all');
                try close(getLogFile(obj.objIMAQ)); catch; end
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

                % makes the info GUI visible again and sets focus
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
                if obj.hasIMAQ
                    % if so, then close and delete the movie
                    logFile = getLogFile(obj.objIMAQ);
                    fName = get(logFile,'FileName');
                    
                    if exist(fName,'file')
                        % closes the log file and deletes it
                        wState = warning('off','all');
                        close(logFile);                             
                        
                        % pauses to left the file close...
                        pause(1);
                        delete(fName)  
                        warning(wState)
                    end
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
                tStr = 'Store Experimental Data';
                uChoice = questdlg(['Do you want to keep data from ',...
                         'the partial experimental?'],tStr,...
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
                % waits until the camera stops logging (videoinput only)
                if obj.hasIMAQ && ~obj.isWebCam
                    while isDeviceLogging(obj)
                        pause(0.1)
                    end
                end
                
                % deletes the folder
                vDir = fullfile(obj.iExpt.Info.OutDir,obj.iExpt.Info.Title);
                deleteAllFiles(vDir,'*.*',1)
                pause(0.05);
            end

            % closes the experiment progress GUI
            try delete(obj.hProg); catch; end                 

            % if there are any stimuli devices then ensure they are stopped
            if ~isempty(obj.sTrain)
                if ~isempty(obj.sTrain.Ex)
                    if obj.hasDAC
                        daqreset 
                    else
                        % stops any of the serial devices
                        isS = cellfun(@(x)(isa(x,'StimObj')),obj.objDev);
                        for i = find(isS(:)')
                            obj.objDev{i}.stopAllDevices();
                        end                         
                    end                                                                      
                end      
            end

            % either closes the experiment run function, or continue onto 
            % the next individual experiment (if there are still 
            % experiments to run)
            if obj.isUserStop
                % if the user stopped the experiment then perform the 
                % house-keeping exercises

                % makes the info GUI visible again and sets focus
                setObjVisibility(obj.hExptF,'on')
                figure(obj.hExptF)

                % clears the camera callback functions (videoinput only)
                if ~obj.isWebCam
                    [obj.objIMAQ.StopFcn,obj.objIMAQ.StartFcn] = deal([]);
                    [obj.objIMAQ.TriggerFcn,obj.objIMAQ.TimerFcn] = deal([]);
                end
                
                % resets the original experiment data struct
                setappdata(obj.hMain,'iExpt',obj.iExpt0)    

                % if running a RT-tracking experiment (and outputting the 
                % solution file directly) then combine the final files
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
            Tnow = datevec(now);
            obj.tCDown = calcTimeDifference(datevec(obj.tStart),Tnow);

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
                wStrNw = sprintf(['Time Until Experiment Starts = ',...
                                  '%s:%s:%s:%s'],C{1},C{2},C{3},C{4});

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
                
                % initialises the experiment tic object
                obj.tExpt = tic;
                
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
            
            % deletes any previous timer objects
            tagStr = 'hTimerEx';
            hTimerExptPr = timerfind('tag',tagStr);
            if ~isempty(hTimerExptPr)
                deleteTimerObjects(hTimerExptPr)
            end

            % creates the timer object
            obj.timerOfs = 0;
            obj.hTimerExpt = timer;

            % sets the total number of frames
            if obj.hasIMAQ
                if isempty(obj.iExpt.Video.FPS)
                    % sets the camera frame rate
                    if obj.isWebCam
                        [fRate,~,iSel] = detWebcamFrameRate(obj.objIMAQ,[]);
                    else
                        srcObj = getselectedsource(obj.objIMAQ);
                        [fRate,~,iSel] = detCameraFrameRate(srcObj,[]);
                    end
                    
                    obj.iExpt.Video.FPS = fRate(iSel);               
                end

                % sets up the object time array
                obj.FPS = roundP(1/obj.iExpt.Video.FPS,0.001); 
                obj.setVideoEventArray();
            else
                % case is a stimuli only experiment
                obj.FPS = 1;
            end

            % sets the timer object properties
            set(obj.hTimerExpt,'Period',obj.FPS,...
                'ExecutionMode','FixedRate',...
                'StartFcn',{@(h,e)obj.startExptFcn},...
                'TimerFcn',{@(h,e)obj.timerExptFcn},...
                'StopFcn',{@(h,e)obj.stopExptFcn},...
                'TasksToExecute',inf,'tag',tagStr);
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
            
            % starts the streampix object (if available)
            if ~isempty(obj.spixObj)
                obj.spixObj.startRecord()
            end
        end
               
        % --- the experiment timer callback function       
        function timerExptFcn(obj)
            
            % gets the current frames
            try
                hTimer = obj.hTimerExpt;
                iFrm = get(hTimer,'TasksExecuted') + obj.indOfs;        
            catch
                return
            end                   

            % sets the sub-structs            
            tTot = vec2sec(obj.iExpt.Timing.Texp);
            VV = obj.iExpt.Video;            

            % checks to see if the user aborted the experiment. if so, then 
            % stop the timer object and exit the function
            if get(getappdata(obj.hProg,'hBut'),'value')
                % flag that the user has aborted the experiment
                [obj.isUserStop,obj.userStop] = deal(true);

                % stops the timer object and the camera
                if ~obj.isWebCam && (get(obj.objIMAQ,'TriggersExecuted')>=1)
                    % camera has been triggered, so remove stop function
                    stopRecordingDevice(obj);
%                     obj.hTimerExpt.StopFcn = [];
                else
                    % attempts to close the video file
                    if obj.hasIMAQ
                        wState = warning('off','all');
                        close(getLogFile(obj.objIMAQ));
                        warning(wState)
                    end
                end

                % force stops the streampix object (if available)
                if ~isempty(obj.spixObj)
                    obj.spixObj.forceStop()
                end
                
                % stops/deletes the experiment timer
                try
                    stop(obj.hTimerExpt)
                    delete(obj.hTimerExpt)
                catch
                end
                
                % exits the function
                return
            end

            % -------------------------------- %        
            % --- STIMULI EVENT TRIGGERING --- %
            % -------------------------------- %

            % determines if the current frame is an event frame
            if obj.iEvent <= size(obj.tEvent,1)
                % if not logging, then retrieve the current time
                if obj.hasIMAQ
                    if ~isDeviceLogging(obj)                     
                        if isempty(obj.tExpt)
                            obj.tNew = 0;
                        else
                            try
                                obj.tNew = toc(obj.tExpt);
                            catch
                                obj.tNew = 0;
                            end
                        end
                    end
                    
                    % determines if there is a new event
                    hasEvent = obj.tNew >= obj.tEvent{obj.iEvent,1};
                end

                % determine if a new event has taken place
                if hasEvent
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
                            obj.triggerVideoInput();                            
                        end
                    end

                    % increments the event counter
                    obj.iEvent = obj.iEvent + 1;
                end
            else
                % stimuli only, so flag no event
                obj.tNew = toc(obj.tExpt);             
            end

            % otherwise, update the summary figure (every second)
            if mod(iFrm,obj.rfRate) == 0
                % ---------------------------------- %
                % --- EXPERIMENT PROGRESS UPDATE --- %
                % ---------------------------------- %

                if isempty(obj.hProg) || ~ishandle(obj.hProg)
                    % if the figure handle is invalid, then exit function
                    return
                    
                else
                    % otherwise, set a copy of the current time
                    tCurr = obj.tNew;        

                    % updates the overall progress
                    pFunc = getappdata(obj.hProg,'pFunc');
                    pFunc(1,sprintf('Overall Progress (%i%s Complete)',...
                            floor(100*(tCurr/tTot)),'%'),...
                            tCurr/tTot,obj.hProg); 
                        
                    % stops the timer if the current experiment time
                    % exceeds experiment duration (stimuli expt only)
                    if (tCurr >= tTot) && ~obj.hasIMAQ
                        try stop(obj.hTimerExpt); catch; end
                        obj.finishExptObj()
                        return
                    end
                end

                % if first video has not started, then update the countdown
                if obj.hasIMAQ
                    if tCurr < obj.iExpt.Video.Ts(1)
                        nSec = roundP(obj.iExpt.Video.Ts(1) - tCurr);
                        wStr = sprintf(['Waiting For Recording To ',...
                                        'Start (%i Seconds Remain)'],nSec);
                        pFunc(2,wStr,0,obj.hProg);
                    end    
                end

                % ------------------------------ %
                % --- STIMULUS TIMING UPDATE --- %
                % ------------------------------ %            

                % initialisations
                isRunning = false;
                hText = getappdata(obj.hProg,'hText');
                nInfo = getappdata(obj.hProg,'nInfo');

                % expands the running flags and stimuli start/finish time 
                % (if the experiment has stimuli)
                if nInfo > 1 || ~obj.hasIMAQ
                    % sets the device running flags for the devices
                    isRunning = [isRunning;cell2mat(cellfun(@(x,ok)...
                                (x.isRunning(ok)'),obj.objDev,...
                                obj.hasStim,'un',0))];
                            
                    % removes the video camera running flag (if stim only)
                    if ~obj.hasIMAQ
                        isRunning = isRunning(2:end);
                    end
                            
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
                        i0 = double(obj.hasIMAQ);
                        tDiffR = floor(tSigSF(2,i-i0) - tCurr);
                        if tDiffR < 0
                            % if less than zero
                            nwStr = 'N/A';
                        else
                            nwStr = sprintf('%is Remain',tDiffR);
                        end  

                    elseif (jStim == nStim)
                        % if no more events then set the time to N/A
                        [nwStr,tCol] = deal('N/A','r');

                    else 
                        % otherwise, sets the time until the next event is
                        % supposed to occur
                        if (i == 1) && obj.hasIMAQ
                            % case is the video recordings
                            tDiffS = roundP(VV.Ts(jStim+1) - tCurr); 
                        else
                            % case is the stimuli events
                            i0 = double(obj.hasIMAQ);
                            tDiffS = max(0,roundP(tSigSF(1,i-i0) - tCurr));
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

            % updates the timer function
            if obj.isWebCam && isDeviceRunning(obj)
                tFcn = obj.objIMAQ.hTimer.TimerFcn{1};
                tFcn(hTimer,[],obj);
            end
            
            % sets the new frame index (the total number of task executed)
            try
                obj.indFrmNw = get(hTimer,'TasksExecuted');
            catch
            end
            
        end
        
        % --- the experiment timer stop callback function       
        function stopExptFcn(obj)
            
            % if the user aborted, then exit the experiment
            if ~obj.isError
                if obj.isUserStop
                    pause(0.05);
                    obj.finishExptObj()
                end
            end        
        
        end        

        % ------------------------------------- %
        % --- STIMULI EVENT SETUP FUNCTIONS --- %
        % ------------------------------------- %           
        
        % --- sets up the experimental stimuli signal data array
        function setupExptStimSignals(obj)

            % --- repeats the stimuli blocks and adds on time offset
            function xySigS = repeatStimBlocks(xySigS,sParaEx)

                % calculates the time offset of the block (in seconds)
                tStimNw = vec2sec(sParaEx.tStim);
                tOfs = sParaEx.tOfs*getTimeMultiplier('s',sParaEx.tOfsU);

                % repeats/appends the signals depending on repetition count 
                xySigS{1} = arrayfun(@(x)(xySigS{1}+...
                        (x-1)*tStimNw + tOfs),(1:sParaEx.nCount)','un',0);
                xySigS{2} = repmat(xySigS(2),sParaEx.nCount,1);   
                                       
            end
            
            % --- repeats the random stimuli blocks and adds on time offset
            function xySigSR = repeatRandBlocks(sTrainS,chInfo,sParaEx,dT,iCh)
                
                % field retrieval
                nCount = sParaEx.nCount;
                chInfoB = chInfo(iCh,:);
                blkInfoS = sTrainS.blkInfo;
                
                % determines the block channel index
                iChB = (strcmp(sTrainS.chName,blkInfoS(iCh).chName) & ...
                        strcmp(sTrainS.devType,blkInfoS(iCh).devType));
                
                % reduces down the stimuli info for the channel
                sTrainSB = sTrainS; 
                sTrainSB.chName = chInfoB{2};
                sTrainSB.blkInfo = sTrainSB.blkInfo(iChB);
                sTrainSB.devType = sTrainSB.devType(iChB);
                
                % calculates the time offset of the block (in seconds)
                tStimNw = vec2sec(sParaEx.tStim);
                tOfs = sParaEx.tOfs*getTimeMultiplier('s',sParaEx.tOfsU);
                
                % sets up the random stimuli blocks for each count
                xySigSR = arrayfun(@(x)(cell(nCount,1)),1:2,'un',0);
                for iB = 1:nCount
                    % sets up a new random signal
                    xySigB = setupDACSignal(sTrainSB,chInfoB,dT);
                    
                    % offsets and sets the new signal values
                    xySigSR{1}{iB} = xySigB{1}{1} + (iB-1)*tStimNw + tOfs; 
                    xySigSR{2}{iB} = xySigB{1}{2};
                end
                
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
            dT = 1/sRate(1);

%             % calculates the signals for the current train
%             xySigS = arrayfun(@(x)(setupDACSignal...
%                                 (x,chInfo,1/sRate)),sTrainS,'un',0);

            % calculates the serial device signals (for each device)
            for i = 1:nTrain
                % sets up the signals for the current train
                xySigS = setupDACSignal(sTrainS(i),chInfo,dT);
                
                % memory allocation for the full x/y data values
                if i == 1
                    xySigF = cellfun(@(x)...
                                (cell(length(x),2)),xySigS,'un',0);
                end

                % repeats the signals for each channel within the train
                for j = 1:length(xySigS)
                    for k = 1:size(xySigS{j},1)
                        if ~isempty(xySigS{j}{k,1})
                            % repeats the stimuli blocks
                            if strcmp(sTrainS(i).blkInfo(k).sType,'Random')
                                % case is a random stimuli block
                                xySigSR = repeatRandBlocks(...
                                        sTrainS(i),chInfo,sParaEx(i),dT,k);
                            else
                                % case is another stimuli type
                                xySigSR = repeatStimBlocks(...
                                        xySigS{j}(k,:),sParaEx(i));
                            end                            

                            % appends the new data values onto the full 
                            % signal arrays
                            if isempty(xySigF{j}{k,1})
                                xySigF{j}{k,1} = xySigSR{1}(:);
                                xySigF{j}{k,2} = xySigSR{2}(:);
                            else
                                xySigF{j}{k,1} = ...
                                            [xySigF{j}{k,1};xySigSR{1}(:)];
                                xySigF{j}{k,2} = ...
                                            [xySigF{j}{k,2};xySigSR{2}(:)];
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
                if ~isempty(xySigF{i})
                    % sets the signal data
                    obj.ExptSig(i).XY = xySigF{i};

                    % retrieves channel ID flags for each device stimuli 
                    ii = find(~cellfun('isempty',xySigF{i}(:,1)));
                    iChID = cell2mat(arrayfun(@(x)...
                            (x*ones(length(xySigF{i}{x,1}),1)),ii,'un',0));

                    % retrieves the start/end values of each sub-signal and  
                    % sorts them in chronological order
                    tStim = cell2mat(cellfun(@(y)...
                                    (cell2mat(cellfun(@(x)(x([1,end])'),...
                                     y,'un',0))),xySigF{i}(ii,1),'un',0));
                    [~,iS] = sort(tStim(:,1));    

                    % sets the final start/finish times and the ID flags
                    obj.ExptSig(i).Ts = tStim(iS,1);
                    obj.ExptSig(i).Tf = tStim(iS,2);
                    obj.ExptSig(i).ID = [i*ones(length(iChID),1),iChID(iS)];
                end
            end
        
        end
        
        % ------------------------------------ %
        % --- CAMERA IMAGE CHECK FUNCTIONS --- %
        % ------------------------------------ %

        % --- sets up the camera image check functions/objects
        function setupCameraImageCheck(obj)

            % deletes any previous timer objects
            hTimerChkPr = timerfind('tag',obj.tagStrChk);
            if ~isempty(hTimerChkPr)
                deleteTimerObjects(hTimerChkPr)
            end            

            % creates the timer object
            obj.hTimerChk = timer('StartDelay',obj.tDelayChk,...
                'ExecutionMode','FixedRate','TasksToExecute',1,...
                'TimerFcn',{@(h,e)obj.timerChkFcn},'tag',obj.tagStrChk);

            % calculates the baseline camera average image
            obj.vB0 = get(obj.objIMAQ,'Brightness');
            obj.ImgAvg0 = obj.calcCameraImageAvg();

        end

        % --- the camera brightness check timer function
        function timerChkFcn(obj)

            % parameters
            dvB = 1;

            % determines if the new image is significantly difference from 
            % the original image average pixel intensity
            ImgAvgNw0 = obj.calcCameraImageAvg();
            if (ImgAvgNw0 - obj.ImgAvg0) > obj.dImgTol
                % if a major increase brightness, then decrease brightness 
                % until the image intensity is within tolerance
                vB = get(obj.objIMAQ,'Brightness') - dvB;
                while true
                    % updates the camera brightness
                    set(obj.objIMAQ,'Brightness',vB)
                    pause(0.05)

                    % recalculates the average image intensity
                    ImgAvgNw = obj.calcCameraImageAvg(ImgAvgNw0);
                    dImgAvg = ImgAvgNw - obj.ImgAvg0;

                    % determines if the avg pixel intensity is within tol
                    if dImgAvg < obj.dImgTol
                        % if within tolerance, then exit the loop
                        break
                    else
                        % otherwise, recalculate the brightness value
                        dIdvB = (ImgAvgNw0 - ImgAvgNw)/dvB;
                        dvB = max(1,roundP(dImgAvg/dIdvB));

                        % updates the brightness/average image values
                        [vB,ImgAvgNw0] = deal(vB - dvB,ImgAvgNw);

                        % SPECIAL CASE - setting the brigtness to -1
                        % doesn't seem to do anything?! reset to 0
                        if vB == -1
                            vB = 0;
                        end
                    end
                end
            end

            % stops the timer object
            stop(obj.hTimerChk)

        end

        % --- calculates the avg pixel intensity from a camera snapshot 
        function ImgAvgNw = calcCameraImageAvg(obj,ImgAvgPr)

            if exist('ImgAvgPr','var')
                % paramters
                dImgPr = 1;

                % keep looping until there is a signficant change
                while true
                    % calculates the new avg pixel intensity
                    ImgNw = double(rgb2gray(snapshot(obj.objIMAQ)));
                    ImgAvgNw = mean(ImgNw(:));

                    % determines if there is a major change
                    if abs(ImgAvgPr - ImgAvgNw) > dImgPr
                        % if so, then exit the loop
                        break
                    else
                        % otherwise, pause for a little bit...
                        pause(0.05)
                    end
                end
            else
                % otherwise, calculates the new avg pixel intensity
                ImgNw = double(rgb2gray(snapshot(obj.objIMAQ)));
                ImgAvgNw = mean(ImgNw(:));
            end

        end        

        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %          
        
        % --- force stops any serial devices
        function forceStopDevices(obj)
                   
            % initialisations and array dimensioning                
            ID = field2cell(obj.ExptSig,'ID',1);                
            isS = strcmp(obj.objDAQ.dType(unique(ID(:,1))),'Serial');        

            % function only applies to serial devices
            if any(isS)
                % for each serial device, write zero signals to the devices
                obj.objDev{1}.forceStopDevices()   
            else
                % finish me!
                
            end
        
        end
        
        % --- saves the summary file to disk --- %
        function saveSummaryFile(obj)

            % retrieves the video time-stamp arrays
            a = struct('tStampV',[]);
            [a.tStampV,a.sTrain] = deal(obj.tStampV,obj.sTrain);
            [a.iExpt,a.iStim] = deal(obj.iExpt,obj.iStim);

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

            % removes any nan-time video stamps by interpolating the other 
            % time values (only do this if there are any videos that have 
            % been recorded)
            if obj.hasIMAQ
                iVideo = find(cellfun(@(x)...
                                    (~all(isnan(x))),a.tStampV),1,'last');
                if ~isempty(iVideo)
                    ii = isnan(a.tStampV{iVideo}); 
                    if any(ii)
                        jj = find(~ii); ii = find(ii);
                        if length(jj) > 1
                            a.tStampV{iVideo}(ii) = interp1(jj,...
                               a.tStampV{iVideo}(jj),ii,'linear','extrap');
                        end
                    end
                end
            end

            % creates the video file output directory
            summDir = fullfile(obj.iExpt.Info.OutDir,obj.iExpt.Info.Title);
            if ~exist(summDir,'dir'); mkdir(summDir); end
            summFile = fullfile(summDir,'Summary.mat');

            % creates the solution file output directory (if required)
            if isfield(obj.iExpt.Info,'OutSoln')
                if ~isempty(obj.iExpt.Info.OutSoln)
                    solnDir = fullfile(obj.iExpt.Info.OutSoln,...
                                       obj.iExpt.Info.Title);
                    if ~exist(solnDir,'dir')
                        % if the output solution file directory does not 
                        % exist, then create it
                        mkdir(solnDir); 
                    end
                end
            end

            % sets output data based on whether RT tracking is running
            if obj.isRT
                % retrieves the required data structs
                rtD = getappdata(obj.hMain,'rtD');
                a.iMov = getappdata(obj.hMain,'iMov');
                a.sData = rtD.sData;
                a.iExpt.rtP = getappdata(obj.hMain,'rtP');
            else
                % otherwise, set an empty SD shock data struct
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

            % determines the events where the time is greater than one  
            % (i.e., events of different frames) and groups the indices 
            % which are the same
            jj = find(diff(cell2mat(vEvent(:,1))) > 1);

            % resets the array so as to group equally timed events
            if (isempty(jj))
                B = {vEvent};
            else    
                ind = [[1;(jj(1:end)+1)] [jj;length(vEvent)]];
                B = cellfun(@(x)(vEvent(x(1):x(2),:)),...
                                                num2cell(ind,2),'un',0);
            end

            % collapses the array into a single cell array
            tEvent0 = cell(length(B),2);
            for i = 1:length(B)
                [tEvent0{i,1},tEvent0{i,2}] = deal(B{i}{1,1},B{i}(:,2)');
            end        

            % sets the time event field
            obj.tEvent = tEvent0;
        
        end                                  
        
        % --- re-triggers the camera until it starts again
        function triggerVideoInput(obj)
            
            % initialisations
            nTrig = 0;            
            
            % runs the camera properties check (webcam only)
            if obj.isWebCam
                set(obj.objIMAQ,'Brightness',obj.vB0)
                start(obj.hTimerChk)
            end

            % 
            while ~isDeviceLogging(obj)
                % if there was an error, then pause for a
                % little bit
                if (nTrig > 0)
                    pause(0.25);
                    fprintf(['Re-Triggering Attempt ',...
                        '#%i\n'],nTrig)
                end
                
                % if the camera is off, then restart it
                if ~isDeviceRunning(obj)
                    startRecordingDevice(obj)
                end
                
                % attempts to re-trigger the camera
                if ~obj.isWebCam; trigger(obj.objIMAQ); end
                nTrig = nTrig + 1;
            end
            
        end        
        
        % --- sets up the webcam ROI indices
        function setupROIIndices(obj)
            
            % initialisations
            pROI = obj.objIMAQ.pROI;            
            vResS = get(obj.objIMAQ,'Resolution');
            vRes = cellfun(@str2double,strsplit(vResS,'x'));
            yOfs = vRes(2) - sum(pROI([2,4]));
            
            % sets the row/column indices
            obj.iCW = (pROI(1)+1):min(vRes(1),sum(pROI([1,3])));
            obj.iRW = (yOfs+1):min(vRes(2),yOfs+pROI(4));
            
        end
        
    end
    
end
