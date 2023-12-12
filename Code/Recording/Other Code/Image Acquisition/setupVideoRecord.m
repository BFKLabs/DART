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
        % initialises the waitbar figure
        exObj.hProg = ProgBar('Initialising Recording...',...
                              'Recording Test Video');
        exObj.hProg.wStr = {'Recording Video - '};
        
        % retrieves the video logging mode
        if ~exObj.isWebCam
            exObj.isMemLog = strcmp(exObj.objIMAQ.LoggingMode,'memory');
            if exObj.isMemLog; exObj.tOfsT = 0; end
        end
                
        % sets up the video log file
        setupLogVideo(exObj,exObj.vPara);
        
        % sets the image acquisition callback functions    
        if exObj.isWebCam
            % deletes any previous timer objects
            hTimerPr = timerfindall('Tag','vObjW');
            if ~isempty(hTimerPr); delete(hTimerPr); end            
            
            % case is using a webcam object
            tPer = roundP(1/exObj.vPara.FPS,0.001);
            exObj.objIMAQ.hTimer = timer(...
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
        
        % gets the rotation flag
        exObj.tExpt = [];
        if exObj.isMemLog; exObj.tOfsT = 0; end          
        
        % if running a real-time tracking experiment (and outputting the
        % solution files directly) then re-initialise the data struct)
        if exObj.isRT
            initRTTrackExpt(exObj,1); 
        end        
        
        % allocates memory for the time stamp array
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
                
        % sets the video parameters
        exObj.vParaVV = VV;
        exObj.vPara = setVideoParameters(exObj.iExpt.Info,VV);
        setupLogVideo(exObj,exObj.vPara(exObj.nCountV));        
                        
        % sets the image acquisition callback functions   
        if exObj.isWebCam || exObj.isTest
%             % deletes any previous timer objects
%             hTimerPr = timerfindall('Tag','vObjW');
%             if ~isempty(hTimerPr); delete(hTimerPr); end
            
            % case is using a webcam object
            exObj.objIMAQ.hTimer = struct(...
                'TimerFcn',[],'StopFcn',[],'TriggerFcn',[],...
                'UserData',0,'Tag','vObjW','iFrm',0,'Running','off',...
                'FramesAcquired',0);            

            % sets the timer callback function
            exObj.objIMAQ.hTimer.TimerFcn = {@timerFunc,exObj};
            exObj.objIMAQ.hTimer.StopFcn = {@finishRecord,exObj};
            exObj.objIMAQ.hTimer.TriggerFcn = {@trigCamera,exObj};            
            
        else
            % case is using a videoinput object
            exObj.objIMAQ.TimerFcn = {@timerFunc,exObj};
            exObj.objIMAQ.StopFcn = {@finishRecord,exObj};
            exObj.objIMAQ.TriggerFcn = {@trigCamera,exObj};
            exObj.objIMAQ.FramesAcquiredFcn = {@frmAcquired,exObj,0};            
        end
end

% sets the videoinput specific fields
if ~(exObj.isWebCam || exObj.isTest)
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
if exObj.isWebCam
    open(exObj.objIMAQ.DiskLogger)    
    if isstruct(exObj.objIMAQ.hTimer)
        exObj.objIMAQ.hTimer.Running = 'on';
    end
end

% updates the video counter
if strcmp(exObj.vidType,'Expt')
    feval(getappdata(exObj.hProg,'tFunc'),[1 2],...
                     num2str(exObj.nCountV),exObj.hProg);
end

% --- callback function for the imaq object timer --- %
function timerFunc(hTimer,~,exObj)

% this function basically updates the summary waitbar figure
if ~exObj.isTrigger
    % if the camera has not been triggered yet, then exit
    return
    
elseif exObj.isWebCam || exObj.isTest
    % acquires the new frame
    frmAcquired([],[],exObj,exObj.objIMAQ.hTimer.UserData);
    
    % only update figure at of 1 FPS
    iFrm = get(hTimer,'TasksExecuted');
    if mod(iFrm,exObj.rfRate) ~= 1
        return
    end
end

try
    % retrieves the waitbar strings
    if isprop(exObj.hProg,'wStr')
        wStr = exObj.hProg.wStr;
    else
        wStr = getappdata(exObj.hProg,'wStr');
    end
catch
    % if user stopped the video prematurely, then stop recording
    [exObj.userStop,exObj.isUserStop] = deal(true);
    stopRecordingDevice(exObj);
end

% sets the waitbar proportion value and new waitbar string
vPara = exObj.vPara;
pWait = min(1,max(0,(exObj.tVid-vPara(exObj.nCountV).Ts)/...
                    (vPara(exObj.nCountV).Tf-vPara(exObj.nCountV).Ts)));
ppWait = floor(100*pWait);

% sets the waitbar figure + properties (depending on recording type)
try
    switch exObj.vidType
        case ('Test') 
            % case is for a test recording   
            [ind,wStrT] = deal(1,wStr{1});
            wStrNw = sprintf('%s (%i%s Complete)',wStrT,ppWait,'%');
            isCancel = exObj.hProg.Update(ind,wStrNw,pWait);
            
        case ('Expt') 
            % case is for an experiment recording
            wFunc = getappdata(exObj.hProg,'pFunc');
            [ind,wStrT] = deal(2,wStr{2});
            wStrNw = sprintf('%s (%i%s Complete)',wStrT,ppWait,'%');            
            isCancel = wFunc(ind,wStrNw,pWait,exObj.hProg);
    end

    % updates the waitbar progress fields
    if isCancel
        % if user stopped the video prematurely, then stop recording
        exObj.userStop = true;
        stopRecordingDevice(exObj); 
    end
    
catch ME
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
if exObj.isWebCam || obj.isTest
    % case is a webcam object
    if isstruct(exObj.objIMAQ.hTimer)
        % case is an experiment recording
        iFrm = exObj.objIMAQ.hTimer.FramesAcquired + 1;
        exObj.objIMAQ.hTimer.FramesAcquired = iFrm;
    else
        % case is a test recording
        iFrm = max(1,exObj.objIMAQ.hTimer.TasksExecuted);
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
    % wait for the new frame to be available
    while exObj.objIMAQ.FramesAvailable == 0
        java.lang.Thread.sleep(1);
    end

    try
        % retrieves the read frames from the camera
        szR = [exObj.resInfo.H,exObj.resInfo.W];
        nFrm = exObj.objIMAQ.FramesAvailable;
        [Img, tFrm] = getdata(exObj.objIMAQ,nFrm,'uint8','cell');   
        logFile = get(exObj.objIMAQ,'UserData');
        iFrm = zeros(length(Img),1);      
        
        % sets the preview image
        ImgNw = Img{end};
        
        % updates the video/time stamps
        for i = 1:length(Img)    
            % appends the new frame to the video
            Img{i} = imresize(Img{i},szR);
            writeVideo(logFile, Img{i});
            
            % updates the frame count
            iFrm(i) = logFile.FrameCount;
            if (iFrm(i) == 1) && (exObj.nCountV > 0)
                % for the first frame on any video except the first, then
                % calculates the total time offset
                exObj.tOfsT = toc(exObj.tExpt) - tFrm(i);
            end
            
            % updates the time stamp array
            if strcmp(exObj.vidType,'Test')
                % case is the video is for a test
                exObj.tVid = toc(exObj.tExpt);
                exObj.tStampV{exObj.nCountV}(iFrm(i)) = exObj.tVid;
            else
                % case is the video is for an experiment
                [exObj.tStampV{exObj.nCountV}(iFrm(i)),exObj.tNew] = ...
                                    deal(tFrm(i)+tOfs+exObj.tOfsT);        
            end
        end
    catch 
        % if there was an error, then exit the function
        return
    end
    
    % sets the new frame and clears the read image array    
    clear Img;
else    
    % registers the time stamp for the frame (off-setting by the time tOfs)
    exObj.tVid = toc(exObj.tExpt);
    [exObj.tStampV{exObj.nCountV}(iFrm),exObj.tNew] = deal(exObj.tVid+tOfs);
    
    % reads in the new frame (if logging to memory)
    if exObj.isWebCam
        ImgNw = getPreviewFrame(exObj);
        writeVideo(exObj.objIMAQ.DiskLogger,ImgNw(exObj.iRW,exObj.iCW,:));
    end
end

% if the video exceeds duration, then stop the recording
if exObj.tStampV{exObj.nCountV}(iFrm) >= VV.Tf(exObj.nCountV)
    exObj.tStampV{exObj.nCountV} = exObj.tStampV{exObj.nCountV}(1:iFrm);
    isStop = true;
end

% flushes the image acqusition object frame buffer
if ~(exObj.isWebCam || exObj.isTest)
    flushdata(exObj.objIMAQ); 
end

% if the video has reached the required duration then stop the recording
if isStop
    stopRecordingDevice(exObj);
end
       
% ----------------------------- %
% --- CAMERA PREVIEW UPDATE --- %
% ----------------------------- %

% sets the camera FPS
isExpt = strcmp(exObj.vidType,'Expt');
if isExpt || exObj.isWebCam
    % sets the variable input arguments    
    FPS = roundP(VV.FPS);
    
else
    % sets the camera frame rate
    FPS0 = exObj.iExpt.Video.FPS;
    if exObj.isWebCam
        [fRate,~,iSel] = detWebcamFrameRate(exObj.objIMAQ,FPS0);
    else
        srcObj = getselectedsource(exObj.objIMAQ);
        [fRate,~,iSel] = detCameraFrameRate(srcObj,FPS0);
    end
    
    % sets the final frame rate
    FPS = roundP(fRate(iSel));
end

% determines if the frame required updating
if exObj.userStop || isStop || exObj.isError
    frmUpdate = false;
    
elseif any(mod(iFrm,2) == 0)
    % frame rate is an even number
    if exObj.isRT && isExpt
        % update twice a second (for RT-tracking expt)
        frmUpdate = any(mod(iFrm,FPS/2) == 1);
    else
        % otherwise, update every second
        frmUpdate = any(mod(iFrm,FPS) == 1);    
    end
else
    % frame rate is an odd number (update every second)
    frmUpdate = any(mod(iFrm,roundP(FPS)) == 1);    
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
        % updates the image axes and tracking GUI
        try
            rtPos = getappdata(exObj.hProg,'rtPos');
            rtPos = updateVideoFeedImage(exObj.hMain,[],ImgNw,rtPos);
            setappdata(exObj.hProg,'rtPos',rtPos)
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
            image(ImgNw,'Parent',exObj.hAx);
            axis(exObj.hAx,'image');
            set(exObj.hAx,'xtick',[],'xticklabel',[],'ytick',[],...
                          'yticklabel',[],'xLim',xL,'yLim',yL)               
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
delete(exObj.hProg)

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
    logFile = getLogFile(exObj.objIMAQ);
    close(logFile);
    delete(get(logFile,'FileName'))
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
                exObj.userStop = exObj.hProg.Update...
                                    (1,'Outputing Video To File...',1);
            catch               
                % if there was an error then flag a stop
                exObj.userStop = true;
            end
            
        case ('Expt') 
            % case is the experiment output
            try
                % updates the progressbar
                wFunc = getappdata(exObj.hProg,'pFunc');
                wFunc(2,'Outputing Video To File...',1,exObj.hProg);
                
                % checks if the user aborted. if so then flag a stop
                if get(getappdata(exObj.hProg,'hBut'),'value')
                    exObj.userStop = true;
                end                
            catch
                % if there was an error then flag a stop
                exObj.userStop = true;
            end
    end
end

% retrieves the log file 
logFile = getLogFile(exObj.objIMAQ);    
if isempty(logFile); return; end

% closes the video object
fName = get(logFile,'Filename');
fFile = fullfile(get(logFile,'Path'),fName);

% attempts to close the video file
wState = warning('off','all');
try
    % flushes the frame data already from the IMAQ object
    close(logFile); pause(0.05);
    if ~exObj.isWebCam; flushdata(exObj.objIMAQ); end
catch
end

% turns on all warnings again
warning(wState)
    
% if the user stopped the recording, then prompt them if they want to
% save the partial file
if exObj.userStop && exObj.isStart
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
            if isa(exObj.hProg,'ProgBar')
                exObj.hProg.closeProgBar();
            else
                close(exObj.hProg)
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
        rtPos = getappdata(exObj.hProg,'rtPos');
        tmpDir = fullfile(exObj.iExpt.Info.OutSoln,exObj.iExpt.Info.Title);
        tmpFile = fullfile(tmpDir,sprintf('TempRT_%i.mat',exObj.nCountV));
        save(tmpFile,'rtPos');
    end
          
    % clears the log file
    if exObj.isMemLog
        set(exObj.objIMAQ,'UserData',[]) 
    else
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
        feval(getappdata(exObj.hProg,'sFunc'))
                    
        % if the camera is still logging, then stop the camera (disables
        % the stop function as this isn't required)
        if isDeviceLogging(exObj)
            stopRecordingDevice(exObj,1);   
        end
                             
        % resets the imaq log file and video camera properties
        setupLogVideo(exObj,vPara(exObj.nCountV));        
        
        % flushes the frame data already from the IMAQ object
        if exObj.isWebCam
            exObj.objIMAQ.hTimer.FramesAcquired = 0;
        else
            vParaNw = vPara(exObj.nCountV);
            setupCameraProps(exObj.objIMAQ,vParaNw);
            flushdata(exObj.objIMAQ)
        end
        
        % if running a real-time tracking experiment (and outputting the
        % solution files directly) then re-initialise the data struct)
        if exObj.isRT
            initRTTrackExpt(exObj.hMain,exObj.hProg,false); 
        end        
        
        % updates the waitbar figure
        wFunc(2,'Starting Camera Object...',0,exObj.hProg);
        
        % restarts the camera (video input only)
        startRecordingDevice(exObj);
        pause(0.05)
        
        % updates the waitbar figure
        wFunc(2,'Waiting For Camera Trigger...',0,exObj.hProg);             
        
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
if ~(exObj.isWebCam || exObj.isTest)
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
    if ~exObj.isWebCam && strcmp(exObj.objIMAQ.LoggingMode,'memory')
        % case is logging to memory
        exObj.objIMAQ.UserData = logFile;
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
iExpt = getappdata(exObj.hProg,'iExpt');
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
    setappdata(exObj.hProg,'rtPos',setupRTExptStruct(iMov)); 
end     

function ImgNw = getPreviewFrame(exObj)
        
if exObj.isWebCam
    ImgNw = snapshot(exObj.objIMAQ);
else
    ImgNw = getsnapshot(exObj.objIMAQ);
end