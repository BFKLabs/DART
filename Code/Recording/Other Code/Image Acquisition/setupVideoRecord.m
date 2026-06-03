% --- initialises the video recording objects --- %
function setupVideoRecord(exObj)

% field value initialisation
[exObj.userStop,exObj.isError] = deal(false);
[exObj.isTrigger,exObj.isSaving] = deal(false);
[exObj.tVid,exObj.tNew,exObj.tExpt] = deal(0,0,[]);

% stops the videoinput (if it is currently running)
if isDeviceRunning(exObj)
    stopRecordingDevice(exObj)
end

% sets the timer/stop functions
switch exObj.vidType
    case ('Test')
        % case is test video recording
        
        % initialises the progressbar
        exObj.objP = ProgBar('Initialising Recording...',...
                              'Recording Test Video');
        exObj.objP.wStr = {'Recording Video - '};
        
        % sets video logging mode flag (non-webcam only)
        if ~exObj.isWebCam
            exObj.isMemLog = strcmp(exObj.objIMAQ.LoggingMode,'memory');
            if exObj.isMemLog; exObj.tOfsT = 0; end
        end
                
        % video log file setup
        setupLogVideo(exObj,exObj.vPara);
        
        % image acquisition callback functions    
        if exObj.isWebCam 
            % deletes any previous timer objects
            hTimerPr = timerfindall('Tag','vObjW');
            if ~isempty(hTimerPr); delete(hTimerPr); end            
            
            % case is using a webcam object
            tPer = roundP(1/exObj.vPara.FPS,0.001);
            exObj.hTimer = timer(...
                'TimerFcn',{@timerFunc,exObj},...
                'ErrorFcn',{@errorFunc,exObj},...
                'StopFcn',{@finishRecord,exObj},...
                'StartFcn',{@trigCamera,exObj},...
                'ExecutionMode','FixedRate','Period',tPer,...
                'TasksToExecute',inf,'UserData',0,'Tag','vObjW');            
            
        else
            % case is using a videoinput object
            exObj.objIMAQ.TimerFcn = {@timerFunc,exObj};
            exObj.objIMAQ.ErrorFcn = {@errorFunc,exObj};
            exObj.objIMAQ.StopFcn = {@finishRecord,exObj};            
            exObj.objIMAQ.TriggerFcn = {@trigCamera,exObj};
            exObj.objIMAQ.FramesAcquiredFcn = {@frmAcquired,exObj,0};
        end
        
        % allocates memory for the time stamp array
        [exObj.nCountV,exObj.nMaxV] = deal(1);
        exObj.tStampV = {NaN(ceil(exObj.vPara.Tf*exObj.vPara.FPS),1)};
        
    case ('Expt')
        % case is full experiment recording
        
        % gets the rotation flag
        exObj.tExpt = [];
        if exObj.isMemLog; exObj.tOfsT = 0; end          
        
        % real-time tracking experiment data struct instruction
        if exObj.isRT
            initRTTrackExpt(exObj,1); 
        end        
        
        % time stamp array memory allocation
        VV = exObj.iExpt.Video;
        [exObj.nMaxV,FPS] = deal(VV.nCount,VV.FPS);
        if ~exObj.isError
            exObj.nCountV = 1;
            exObj.tStampV = cellfun(@(x,y)(NaN(roundP(1.1*(x-y)*FPS),1)),...
                  num2cell(roundP(VV.Tf)),num2cell(roundP(VV.Ts)),'un',0);                                                                 
        else
            exptDir = fullfile(exObj.iExpt.Info.OutDir,...
                               exObj.iExpt.Info.Title);                        
            exObj.nCountV = length(detectMovieFiles(exptDir))+1;
        end        
                
        % video log file setup
        exObj.vParaVV = VV;
        exObj.vPara = setVideoParameters(exObj.iExpt.Info,VV);
        setupLogVideo(exObj,exObj.vPara(exObj.nCountV));        
                        
        % sets the image acquisition callback functions   
        if exObj.isWebCam || exObj.isTest || exObj.isMemLog
%             % deletes any previous timer objects
%             hTimerPr = timerfindall('Tag','vObjW');
%             if ~isempty(hTimerPr); delete(hTimerPr); end            

            % case is using a timer based recording object
            exObj.hTimer = struct(...
                'TimerFcn',[],'StopFcn',[],'TriggerFcn',[],...
                'UserData',0,'Tag','vObjW','iFrm',0,'Running','off',...
                'FramesAcquired',0);
            
            % sets the timer callback function
            exObj.hTimer.TimerFcn = {@timerFunc,exObj};
            exObj.hTimer.StopFcn = {@finishRecord,exObj};
            exObj.hTimer.TriggerFcn = {@trigCamera,exObj};
            exObj.isLogging = false;
            
        else
            % case is using a videoinput object
            exObj.objIMAQ.TimerFcn = {@timerFunc,exObj};
            exObj.objIMAQ.StopFcn = {@finishRecord,exObj};
            exObj.objIMAQ.TriggerFcn = {@trigCamera,exObj};
            exObj.objIMAQ.FramesAcquiredFcn = {@frmAcquired,exObj,0};            
        end
end

% sets the videoinput specific fields
if ~(exObj.isWebCam || exObj.isTest || exObj.isMemLog)
    % sets up the camera properties
    exObj.objIMAQ.FramesAcquiredFcnCount = 1;
    exObj.objIMAQ.TriggerRepeat = 0;    
    setupCameraProps(exObj.objIMAQ,exObj.vPara(1));
    
    % starts video object (needs to be triggered to start recording)
    start(exObj.objIMAQ); 
end

%-------------------------------------------------------------------------%
%                         IMAQ CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% --- TEST RECORDING CALLBACK FUNCTIONS --- %
% ----------------------------------------- %

% --- callback function for triggering the camera
function trigCamera(~,~,exObj)

% flag that the camera has been triggered
exObj.isTrigger = true;

% opens the disklogger object (if running from webcam)
if exObj.isWebCam || exObj.isMemLog
    % flag that the video is now logging
    open(exObj.logFile)   
    exObj.isLogging = true;

    if isstruct(exObj.hTimer)
        exObj.hTimer.Running = 'on';
    end
end

% updates the video counter
if strcmp(exObj.vidType,'Expt')
    exObj.objP.updateTextInfo([1,2],num2str(exObj.nCountV));
end

% --- callback function for the imaq object timer --- %
function timerFunc(hTimer,~,exObj)

% this function basically updates the summary waitbar figure
if ~exObj.isTrigger
    % if the camera has not been triggered yet, then exit
    return
    
elseif exObj.isWebCam || exObj.isTest || exObj.isMemLog
    % acquires the new frame
    frmAcquired([],[],exObj,exObj.hTimer.UserData);
    
    % only update figure at of 1 FPS
    iFrm = get(hTimer,'TasksExecuted');
    if mod(iFrm,exObj.rfRate) ~= 1
        return
    end
end

% sets the waitbar figure + properties (depending on recording type)
updateVideoProgress(exObj);

% --- updates the video progressbar
function updateVideoProgress(exObj)

try
    % retrieves the waitbar strings
    wStr = exObj.objP.wStr;
    
catch
    % if user stopped the video prematurely, then stop recording
    [exObj.userStop,exObj.isUserStop] = deal(true);
    stopRecordingDevice(exObj);
    return
end

% sets the waitbar proportion value and new waitbar string
vPara = exObj.vPara;
pWait = min(1,max(0,(exObj.tVid-vPara(exObj.nCountV).Ts)/...
                    (vPara(exObj.nCountV).Tf-vPara(exObj.nCountV).Ts)));
ppWait = floor(100*pWait);

try
    switch exObj.vidType
        case ('Test') 
            % case is for a test recording   
            [ind,wStrT] = deal(1,wStr{1});
            wStrNw = sprintf('%s (%i%s Complete)',wStrT,ppWait,'%');
            isCancel = exObj.objP.Update(ind,wStrNw,pWait);
            
        case ('Expt') 
            % case is for an experiment recording
            wStrNw = sprintf('%s (%i%s Complete)',wStr{2},ppWait,'%');
            isCancel = exObj.objP.updateBar(2,wStrNw,pWait);
    end

    % updates the waitbar progress fields
    if isCancel
        % if user stopped the video prematurely, then stop recording
        exObj.userStop = true;
        stopRecordingDevice(exObj); 
    end
    
catch
    % if user stopped the video prematurely, then stop recording
    exObj.userStop = true;
    stopRecordingDevice(exObj);
end
    
% --- function that runs for each frame that is acquired
function frmAcquired(hTimer,~,exObj,tOfs)

% -------------------------- %
% --- TIME STAMP SETTING --- %
% -------------------------- %

% retrieves the time-stamp array
[VV,isStop] = deal(exObj.vParaVV,false);
if exObj.isWebCam || exObj.isTest || exObj.isMemLog
    % case is a webcam object
    if isstruct(exObj.hTimer)
        % case is an experiment recording
        iFrm = exObj.hTimer.FramesAcquired + 1;
        exObj.hTimer.FramesAcquired = iFrm;
    else
        % case is a test recording
        iFrm = max(1,exObj.hTimer.TasksExecuted);
    end
else
    % case is a videoinput object
    iFrm = max(1,exObj.objIMAQ.FramesAcquired);
end

% if the first frame of the first video, then start the clock    
if isempty(exObj.tExpt)
    exObj.tExpt = tic; 
end
    
if exObj.isMemLog  
%     % wait for the new frame to be available    
%     [nRetry,nRetryMax,tPause] = deal(0,100,5);
%     while exObj.objIMAQ.FramesAvailable == 0
%         % pauses for a small amount of time
%         java.lang.Thread.sleep(tPause);
%         
%         % increments the counter
%         nRetry = nRetry + 1;
%         if nRetry > nRetryMax
%             return
%         end
%     end

    try
        % retrieves the read frames from the camera
        [exObj.iFrmVid,iFrm] = deal(exObj.iFrmVid + 1);
        ImgNw = step(exObj.objIMAQ);

        % adds the new frame to the log file
        ImgFrm = convertImageFrame(ImgNw,exObj.resInfo);
        writeVideo(exObj.logFile, ImgFrm);
                
        if (iFrm == 1)
            % starts the log-file time
            exObj.tLogFile = tic;
            
            % for the first frame on any video except the first, then
            % calculates the total time offset
            if (exObj.nCountV > 0)
                exObj.tOfsT = toc(exObj.tExpt) - toc(exObj.tLogFile);
            end
        end

        % updates the time stamp array
        exObj.tVid = toc(exObj.tExpt);        
        if strcmp(exObj.vidType,'Test')
            % case is the video is for a test
            exObj.tStampV{exObj.nCountV}(iFrm) = exObj.tVid;
        else
            % case is the video is for an experiment
            [exObj.tStampV{exObj.nCountV}(iFrm),exObj.tNew] = ...
                                deal(exObj.tVid);
        end
    catch ME
        % if there was an error, then exit the function
        return
    end
    
    % sets the new frame and clears the read image array    
%     updateVideoProgress(exObj)
    clear Img;
else    
    % registers the time stamp for the frame (off-setting by the time tOfs)
    exObj.tVid = toc(exObj.tExpt);
    [exObj.tStampV{exObj.nCountV}(iFrm),exObj.tNew] = deal(exObj.tVid+tOfs);
    
    % reads in the new frame (if logging to memory)
    if exObj.isWebCam
        ImgNw = getPreviewFrame(exObj);
        writeVideo(exObj.logFile,ImgNw(exObj.iRW,exObj.iCW,:));
    end
end

% if the video exceeds duration, then stop the recording
if exObj.tStampV{exObj.nCountV}(iFrm(end)) >= VV.Tf(exObj.nCountV)
    exObj.tStampV{exObj.nCountV} = exObj.tStampV{exObj.nCountV}(1:iFrm);
    isStop = true;
end

% flushes the image acqusition object frame buffer
if ~(exObj.isWebCam || exObj.isTest || exObj.isMemLog)
    flushdata(exObj.objIMAQ); 
end

% if the video has reached the required duration then stop the recording
if isStop
    stopRecordingDevice(exObj,false,exObj.nCountV == exObj.nMaxV);
end
       
% ----------------------------- %
% --- CAMERA PREVIEW UPDATE --- %
% ----------------------------- %

% sets the camera FPS
isExpt = strcmp(exObj.vidType,'Expt');

% determines if the frame required updating
if exObj.userStop || isStop || exObj.isError
    frmUpdate = false;
    
else
    % otherwise, determine if an update is required
    frmUpdate = exObj.tVid/exObj.dtFrmUpdate > exObj.iFrmUpdate;
    if frmUpdate
        exObj.iFrmUpdate = exObj.iFrmUpdate + 1;
    end
end

% updates the main image (only every second)
if frmUpdate
    % retrieves the image (if not logging to memory)
    if ~exObj.isMemLog && ~exist('ImgNw','var')
        ImgNw = getPreviewFrame(exObj); 
    end    
        
    % checks to see if a real-time tracking experiment is being run. if so,
    % then update the real-time tracking stats GUI and stats   
    if isExpt && exObj.isRT        
        try
            % updates the image axes and tracking GUI
            rtPos0 = exObj.objP.rtPos;
            exObj.objP.rtPos = ...
                updateVideoFeedImage(exObj.hMain,[],ImgNw,rtPos0);
        catch
            return
        end
    else    
        % retrieves the current preview 
        hImage = getappdata(exObj.hAx,'hImage');              
        if isempty(hImage)            
            % retrieves the original axis limits
            [xL,yL] = deal(get(exObj.hAx,'xLim'),get(exObj.hAx,'yLim'));  
            
            % if there is no image, then create a new image object
            hImage = image(ImgNw,'Parent',exObj.hAx);
            hImage.CDataMapping = 'scaled';
            
            axis(exObj.hAx,'image');
            set(exObj.hAx,'xtick',[],'xticklabel',[],'ytick',[],...
                          'yticklabel',[],'xLim',xL,'yLim',yL)               
            
            % sets the axes colourmap to grayscale (if single band)
            if size(ImgNw,3) == 1
                colormap(exObj.hAx,'gray');
            end
                      
            setappdata(exObj.hAx,'hImage',hImage)
        else
            % otherwise, update the axes preview image
            set(hImage,'cData',ImgNw);
        end    
    end    
end

% --- callback function for the imaq object timer --- %
function errorFunc(objIMAQ,event,exObj)

% sets the error flag values
[exObj.userStop,exObj.isError] = deal(false,true);

% deletes the summary GUI
if strcmp(exObj.vidType,'Expt')
    % case is an experiment recording
    exObj.objP.closeWindow();
    
else
    % case is a test recording
    delete(exObj.objP)
end

% output an error to screen
resStr = splitStringRegExp(get(exObj.objIMAQ,'VideoFormat'),'x_');
eStr = {['An error has occured while recording. Suggest decreasing ',...
         'camera resolution:'];...
        '';sprintf('    * Recording Format = %s',resStr{1});...
           sprintf('    * Current Resolution = %s x %s',resStr{2},resStr{3})};
waitfor(errordlg(eStr,'Experiment Recording Error','modal'))
    
% attempt to delete the disk-logging file
wState = warning('off','all');
try            
    % closes and deletes the log file
    exObj.isLogging = false;    
    logFile = getLogFile(exObj);
    close(logFile);
    delete(get(logFile,'FileName'))    
catch
end
    
% runs the finish recording function    
warning(wState);
finishRecord([],[],exObj)    
    
% --- callback function for finishing data logging --- %
function finishRecord(~,~,exObj)

% determines if there was an error which caused the experiment to end
if ~exObj.isError
    % if there was no error, then determine if the camera was triggered
    if ~exObj.isTrigger
        % if there is no trigger then exit
        return
    else
        % otherwise, flag that there is a video to save
        exObj.isSaving = true;
    end
    
    % updates the progressbar
    switch exObj.vidType
        case ('Test') % case is the test output
            try
                exObj.userStop = exObj.objP.Update...
                                    (1,'Outputing Video To File...',1);
            catch               
                % if there was an error then flag a stop
                exObj.userStop = true;
            end
            
        case ('Expt') 
            % case is the experiment output
            try
                % updates the progressbar
                wStr = 'Outputing Video To File...';
                exObj.objP.updateBar(2,wStr,1);
                
                % checks if the user aborted. if so then flag a stop
                if exObj.objP.hButC.Value
                    exObj.userStop = true;
                end                
            catch
                % if there was an error then flag a stop
                exObj.userStop = true;
            end
    end
end

% retrieves the log file 
logFile = getLogFile(exObj);    
if isempty(logFile); return; end

% closes the video object
fName = get(logFile,'Filename');
fFile = fullfile(get(logFile,'Path'),fName);

% attempts to close the video file
wState = warning('off','all');
try
    % flushes the frame data already from the IMAQ object
    close(logFile); pause(0.05);
    exObj.isLogging = false;
    if ~(exObj.isWebCam || exObj.isMemLog)
        flushdata(exObj.objIMAQ); 
    end
end

% turns on all warnings again
warning(wState)
    
% if the user stopped the recording, then prompt them if they want to
% save the partial file
if exObj.userStop && exObj.isStart
    % hides the progress window
    exObj.isLogging = false;
    setObjVisibility(exObj.objP.hFig,0);
  
    % prompts the user if they want to 
    uChoice = questdlg('Do you want to save the partial recording?',...
                       'Save Partial Recording?','Yes','No','Yes');
    if ~strcmp(uChoice,'Yes')
        % if not, then delete the recording   
        if exist(fFile,'file')
            pause(0.05)
            delete(fFile)        
        end
    else
        % otherwise, clear the logfile data
        clear logFile
    end
    
    % exits the function    
    return
else
    % clears the logfile
    if strcmp(exObj.vidType,'Test') && ~exObj.isError
        try
            if isa(exObj.objP,'ProgBar')
                exObj.objP.closeProgBar();
            else
                exObj.objP.closeWindow();
            end
        catch
        end
    end
    
    % clears the logfile data
    clear logFile
end

% if the video recording type is for the experiments, then change over the
% AVI video objects (not for the final video)
if strcmp(exObj.vidType,'Expt')
    % sets the input arguments
    vPara = exObj.vPara;
    
    % if running a real-time tracking experiment (and outputting the
    % solution files directly) then save a temporary copy to file
    if ~isempty(exObj.iExpt.Info.OutSoln) && ~exObj.userStop
        % retrieves the current RT tracking experiment struct and saves
        % the data to a temporary file
        rtPos = exObj.objP.rtPos;
        tmpDir = fullfile(exObj.iExpt.Info.OutSoln,exObj.iExpt.Info.Title);
        tmpFile = fullfile(tmpDir,sprintf('TempRT_%i.mat',exObj.nCountV));
        save(tmpFile,'rtPos');
    end
          
    % clears the log file
    if ~exObj.isMemLog
        % if the camera is running still then stop it
        if isDeviceRunning(exObj)
            stopRecordingDevice(exObj,true);   
        end             
        
        % clears the disk logging file
        [iter,iterMx] = deal(0,10);
        while iter < iterMx
            try
                exObj.objIMAQ.DiskLogger = []; 
                iter = iterMx;
            catch
                pause(0.05);
                iter = iter + 1;
            end
        end
    end    
    
    % check to see if the last video or if the user stopped the experiment
    if (exObj.nCountV == exObj.nMaxV) || exObj.userStop               
        % runs the after experiment function
        exObj.finishExptObj()
        
    else
        % if the experiment is not finished, then prepare the next video
        
        % if not, then increment the video counter and resets trigger flag
        [exObj.nCountV,exObj.isTrigger] = deal(exObj.nCountV + 1,false);
                    
        % saves the summary file to disk
        exObj.saveSummaryFile();
                    
        % if the camera is still logging, then stop the camera (disables
        % the stop function as this isn't required)
        if isDeviceLogging(exObj)
            stopRecordingDevice(exObj,false,false);   
        end
                             
        % resets the imaq log file and video camera properties
        setupLogVideo(exObj,vPara(exObj.nCountV));        
        
        % flushes the frame data already from the IMAQ object
        if exObj.isWebCam || exObj.isMemLog
            exObj.hTimer.FramesAcquired = 0;
        else
            vParaNw = vPara(exObj.nCountV);
            setupCameraProps(exObj.objIMAQ,vParaNw);
            flushdata(exObj.objIMAQ)
        end
        
        % if running a real-time tracking experiment (and outputting the
        % solution files directly) then re-initialise the data struct)
        if exObj.isRT
            initRTTrackExpt(exObj.hMain,exObj.objP,false); 
        end        
        clc
        
        % updates the waitbar figure
        exObj.objP.updateBar(2,'Starting Camera Object...',0);
        
        % restarts the camera (video input only)
        if ~(exObj.isWebCam || exObj.isMemLog)
            startRecordingDevice(exObj);
            pause(0.05)
        end
        
        % updates the waitbar figure          
        exObj.objP.updateBar(2,'Waiting For Camera Trigger...',0);
        
        % resets the save flag to false
        exObj.isSaving = false;        
    end
else
    % pauses a bit for things to update...
    pause(0.5);
    
    % retrieves the original axis limits
    [xL,yL] = deal(get(exObj.hAx,'xLim'),get(exObj.hAx,'yLim'));    
    
    % converts the recordings (if required)
    exObj.convertExptVideos();    
    
    % resets the preview axes image to black
    if exObj.isWebCam 
        vResS = get(exObj.objIMAQ,'Resolution');
        vRes = cellfun(@str2double,strsplit(vResS,'x'));
    else
        vRes = getVideoResolution(exObj.objIMAQ);
    end
    
    % resets the display image
    Img0 = zeros(flip(vRes)); 
    set(findobj(exObj.hAx,'Type','Image'),'cData',Img0);
    set(exObj.hAx,'xLim',xL,'yLim',yL)
    
    % enables the video preview toggle    
    hMainH = guidata(exObj.hMain);
    setObjEnable(hMainH.toggleVideoPreview,'on')
end
            
%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the log video for recording --- %
function setupCameraProps(objIMAQ,vPara)

% sets the camera frame rate
srcObj = getselectedsource(objIMAQ);
if isfield(propinfo(srcObj),'FrameRate')
    [~,fRateS,~,cFPS] = detCameraFrameRate(srcObj,vPara.FPS);
    if length(fRateS) > 1
        set(srcObj,'FrameRate',cFPS);
    end
end

% sets the frames per trigger
objIMAQ.FramesPerTrigger = inf;

% --- initialises the log video for recording --- %
function setupLogVideo(exObj,vPara)

% vPara Convention
%
%  Dir - Output directory string
%  Name - Movie file name string
%  FPS - Video frame rate
%  nFrm - Video frame count

% turns off all the warnings (a warning will appear because we are using
% the DIVX codec)
wState = warning('off','all');
% vCompressF = checkVideoCompression(exObj.objIMAQ,vPara.vCompress);
% exObj.isConvert = ~strcmp(vPara.vCompress,vCompressF);

% flushes any frame data already in the IMAQ object
if ~(exObj.isWebCam || exObj.isTest || exObj.isMemLog)
    flushdata(exObj.objIMAQ); 
end

% creates the log-file (non-test only)
if ~exObj.isTest
    % sets the log-file name
    logName = fullfile(vPara.Dir,vPara.Name);    
    logFile = VideoWriter(logName,vPara.vCompress); 
    if isempty(vPara.FPS)
        % sets the camera frame rate
        if exObj.isWebCam
            [fRate,~,iSel] = detWebcamFrameRate(exObj.objIMAQ,[]);
        else
            srcObj = getselectedsource(exObj.objIMAQ);
            [fRate,~,iSel] = detCameraFrameRate(srcObj,[]);
        end

        % sets the log-file frame rate
        logFile.FrameRate = fRate(iSel);            
    else
        % sets the log-file frame rate
        logFile.FrameRate = vPara.FPS;
    end
    
    % sets the colormap (for an index avi
    if strcmp(vPara.vCompress,'Indexed AVI')
        logFile.Colormap = repmat(linspace(0,1,256)',[1,3]);
    end

    % sets the other video parameters
    exObj.iFrmVid = 0;
    if exObj.isWebCam || exObj.isMemLog || isVidDev(exObj.objIMAQ)
        % case is logging to memory
        exObj.logFile = logFile;
        open(logFile); 
    else
        % case is either a webcam or loging to disk
        exObj.objIMAQ.DiskLogger = logFile;
    end
end

% turns on all the warnings again
warning(wState)

% --- sets the video parameter structs
function vidPara = setVideoParameters(Info,VV)

% sets the new output file directory
nwDir = fullfile(Info.OutDir,Info.Title);
if exist(nwDir,'dir') == 0
    % if the new directory does not exist, then create it
    mkdir(nwDir)
end

% allocates memory for the video parameter struct
sStr = struct('Dir',nwDir,'Name',[],'Tf',[],'Ts',[],...
              'FPS',VV.FPS,'vCompress',[]);
vidPara = repmat(sStr,VV.nCount,1);

% updates the fields for each of the videos
for i = 1:VV.nCount
    % sets the new video ID tag
    nwID = sprintf('%s%i',repmat('0',1,3-floor(log10(i))),i);
    
    % sets the video parameter fields
    vidPara(i).Name = sprintf('%s - %s',Info.BaseName,nwID);
    [vidPara(i).Tf,vidPara(i).Ts] = deal(VV.Tf(i),VV.Ts(i));
    vidPara(i).vCompress = VV.vCompress;
end

% --- initialises the data structs for the RT-tracking experiment
function initRTTrackExpt(exObj,isInit)

% loads the important data structs
iExpt = obj.objP.iExpt;
rtP = getappdata(exObj.hMain,'rtP');
iMov = getappdata(exObj.hMain,'iMov');

% check to see that the devices have all been turned off correctly
forceStopDevice(exObj.hMain)  

% initialises the real-time data struct
rtD = initRTDataStruct(iMov,rtP);
setappdata(exObj.hMain,'rtD',rtD)    

% retrieves the tracking GUI handle
hTrack = getappdata(exObj.hMain,'hTrack');
if ~isempty(hTrack)
    % retrieves the update function handle
    feval(getappdata(hTrack,'rFunc'),guidata(hTrack),2-isInit);
end

% creates a new experiment data struct (if required)
if ~isempty(iExpt.Info.OutSoln)                
    exObj.objP.rtPos = setupRTExptStruct(iMov);
end     

function ImgNw = getPreviewFrame(exObj)
        
if exObj.isWebCam
    ImgNw = snapshot(exObj.objIMAQ);
else
    ImgNw = getsnapshot(exObj.objIMAQ);
end

% --- converts the frame image
function Img = convertImageFrame(Img,resInfo)

if resInfo.rType == 3
    % resizes the image
    szR = [resInfo.H,resInfo.W];
    if ~isequal(szR,size(Img))
        Img = imresize(Img,szR);
    end
elseif (resInfo.rType == 2) && (resInfo.bSz > 1)
    % bins the image
    for i = 1:log2(resInfo.bSz)
        Img = Img(1:2:end, 1:2:end)/4 + Img(2:2:end, 1:2:end)/4 + ...
              Img(1:2:end, 2:2:end)/4 + Img(2:2:end, 2:2:end)/4;
    end
end
