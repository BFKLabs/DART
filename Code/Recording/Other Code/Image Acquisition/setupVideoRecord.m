% --- initialises the video recording objects --- %
function setupVideoRecord(exObj)

% field value initialisation
[exObj.userStop,exObj.isError] = deal(false);
[exObj.isTrigger,exObj.isSaving] = deal(false);
[exObj.tVid,exObj.tNew,exObj.tExpt] = deal(0,0,[]);

% stops the camera (if it is currently running)
if isrunning(exObj.objIMAQ); stop(exObj.objIMAQ); end

% sets the timer/stop functions
switch exObj.vidType
    case ('Test')
        % initialises the waitbar figure
        exObj.hProg = ProgBar('Initialising Recording...',...
                              'Recording Test Video');
        exObj.hProg.wStr = {'Recording Video - '};
        
        % retrieves the video logging mode
        exObj.isMemLog = strcmp(exObj.objIMAQ.LoggingMode,'memory');
        if exObj.isMemLog; exObj.tOfsT = 0; end                       
                
        % sets up the video log file
        setupLogVideo(exObj,exObj.vPara);
        
        % sets the image acquisition callback functions        
        exObj.objIMAQ.TimerFcn = {@timerFunc,exObj};
        exObj.objIMAQ.ErrorFcn = {@errorFunc,exObj};
        exObj.objIMAQ.StopFcn = {@finishRecord,exObj};
        exObj.objIMAQ.FramesAcquiredFcn = {@frmAcquired,exObj,0};
        exObj.objIMAQ.TriggerFcn = {@trigCamera,exObj};  
        
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
        exObj.objIMAQ.TimerFcn = {@timerFunc,exObj};
        exObj.objIMAQ.FramesAcquiredFcn = {@frmAcquired,exObj,0};
        exObj.objIMAQ.StopFcn = {@finishRecord,exObj};        
        exObj.objIMAQ.TriggerFcn = {@trigCamera,exObj};                
end

% sets the combined properties
exObj.objIMAQ.FramesAcquiredFcnCount = 1;
exObj.objIMAQ.TriggerRepeat = 0;
exObj.objIMAQ = setupCameraProps(exObj.objIMAQ,exObj.vPara(1));

% starts video object (needs to be triggered to start recording)
start(exObj.objIMAQ); 

%-------------------------------------------------------------------------%
%                         IMAQ CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% --- TEST RECORDING CALLBACK FUNCTIONS --- %
% ----------------------------------------- %

% --- callback function for triggering the camera
function trigCamera(objIMAQ,event,exObj)

% flag that the camera has been triggered
exObj.isTrigger = true;

% updates the video counter
if strcmp(exObj.vidType,'Expt')
    feval(getappdata(exObj.hProg,'tFunc'),[1 2],...
                     num2str(exObj.nCountV),exObj.hProg);
end

% --- callback function for the imaq object timer --- %
function timerFunc(objIMAQ,event,exObj)

% this function basically updates the summary waitbar figure

% if the camera has not been triggered yet, then exit
if ~exObj.isTrigger
    return
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
    stop(exObj.objIMAQ);   
end

% sets the waitbar proportion value and new waitbar string
vPara = exObj.vPara;
pWait = min(1,max(0,(exObj.tVid-vPara(exObj.nCountV).Ts)/...
                    (vPara(exObj.nCountV).Tf-vPara(exObj.nCountV).Ts)));
ppWait = floor(100*pWait);

% sets the waitbar figure + properties (depending on recording type)
try
    switch exObj.vidType
        case ('Test') % case is for a test recording   
            [ind,wStrT] = deal(1,wStr{1});
            wStrNw = sprintf('%s (%i%s Complete)',wStrT,ppWait,'%');
            isCancel = exObj.hProg.Update(ind,wStrNw,pWait);
            
        case ('Expt') % case is for an experiment recording
            wFunc = getappdata(exObj.hProg,'pFunc');
            [ind,wStrT] = deal(2,wStr{2});
            wStrNw = sprintf('%s (%i%s Complete)',wStrT,ppWait,'%');            
            isCancel = wFunc(ind,wStrNw,pWait,exObj.hProg);
    end

    % updates the waitbar progress fields
    if isCancel
        % if user stopped the video prematurely, then stop recording
        exObj.userStop = true;
        stop(exObj.objIMAQ);    
    end
catch ME
    % if user stopped the video prematurely, then stop recording
    assignin('base','ME',ME)
    exObj.userStop = true;
    stop(exObj.objIMAQ);        
end
    
% --- function that runs for each frame that is acquired
function frmAcquired(objIMAQ,event,exObj,tOfs)

% -------------------------- %
% --- TIME STAMP SETTING --- %
% -------------------------- %

% retrieves the time-stamp array
VV = exObj.vParaVV;
[iFrm,isStop] = deal(exObj.objIMAQ.FramesAcquired,false);
if iFrm == 0; iFrm = 1; end

% if the first frame of the first video, then start the clock    
if isempty(exObj.tExpt)
    exObj.tExpt = tic; 
end

% reads in the new frame (if logging to memory)
if exObj.isMemLog  
    % wait for the new frame to be available
    while exObj.objIMAQ.FramesAvailable == 0
        java.lang.Thread.sleep(1);
    end

    try        
        % retrieves the read frames from the camera
        nFrm = exObj.objIMAQ.FramesAvailable;
        [Img, tFrm] = getdata(exObj.objIMAQ,nFrm,'uint8','cell');   
        logFile = get(exObj.objIMAQ,'UserData');
        iFrm = zeros(length(Img),1);      
        
        % updates the video/time stamps
        for i = 1:length(Img)    
            % appends the new frame to the video    
            if exObj.isRot
                writeVideo(logFile, Img{i}');
            else
                writeVideo(logFile, Img{i});
            end
            
            % updates the frame count
            iFrm(i) = logFile.FrameCount;
            if (iFrm(i) == 1) && (exObj.nCountV > 0)
                % for the first frame on any video except the first, then
                % calculates the total time offset
                exObj.tOfsT = toc - tFrm(i);
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
    ImgNw = Img{end};
    clear Img;
else    
    % registers the time stamp for the frame (off-setting by the time tOfs)
    exObj.tVid = toc(exObj.tExpt);
    [exObj.tStampV{exObj.nCountV}(iFrm),exObj.tNew] = deal(exObj.tVid+tOfs);
end

% if the video exceeds duration, then stop the recording
if exObj.tStampV{exObj.nCountV}(iFrm) >= VV.Tf(exObj.nCountV)
    exObj.tStampV{exObj.nCountV} = exObj.tStampV{exObj.nCountV}(1:iFrm);
    isStop = true;
end

% flushes the image acqusition object frame buffer
flushdata(exObj.objIMAQ)

% if the video has reached the required duration then stop the recording
if isStop; stop(exObj.objIMAQ); end
       
% ----------------------------- %
% --- CAMERA PREVIEW UPDATE --- %
% ----------------------------- %

% sets the camera FPS
if strcmp(exObj.vidType,'Expt')
    % sets the variable input arguments    
    [FPS,isExpt] = deal(roundP(VV.FPS),true);
else
    % retrieves the frame rate from the camera directly
    [srcObj,isExpt] = deal(getselectedsource(exObj.objIMAQ),false);    
    
    % sets the current camera frame rate
    [fRate,~,iSel] = detCameraFrameRate(srcObj,exObj.iExpt.Video.FPS);
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
    if ~exObj.isMemLog; ImgNw = getsnapshot(exObj.objIMAQ); end
    
    % retrieves the current camera image    
    if exObj.isRot; ImgNw = ImgNw'; end    
    
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
            % if there is no image, then create a new image object
            image(ImgNw,'Parent',exObj.hAx);
            set(exObj.hAx,'xtick',[],'xticklabel',[],...
                          'ytick',[],'yticklabel',[])   
            axis(exObj.hAx,'image');
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
function finishRecord(objIMAQ,event,exObj)

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
    
    % checks to see if the user stopped the recording
    switch exObj.vidType
        case ('Test') % case is the test output
            try
                exObj.userStop = exObj.hProg.Update...
                                    (1,'Outputing Video To File...',1);
            catch               
                exObj.userStop = true;
            end
            
        case ('Expt') % case is the experiment output
            try
                wFunc = getappdata(exObj.hProg,'pFunc');
                wFunc(2,'Outputing Video To File...',1,exObj.hProg);
                
                % checks to see if the user aborted. if so, then flag a stop
                if get(getappdata(exObj.hProg,'hBut'),'value')
                    exObj.userStop = true;
                end                
            catch
                exObj.userStop = true;
            end
    end
end

% retrieves the log file 
logFile = getLogFile(exObj.objIMAQ);
    
% closes the video object
fName = get(logFile,'Filename');
fFile = fullfile(get(logFile,'Path'),fName);

% attempts to close the video file
wState = warning('off','all');
try         
    % flushes the frame data already from the IMAQ object
    close(logFile); pause(0.05);    
    flushdata(exObj.objIMAQ)        
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
        if isrunning(exObj.objIMAQ)
            stopCamera(exObj.objIMAQ);   
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
        if islogging(exObj.objIMAQ)
            stopCamera(exObj.objIMAQ);   
        end
                             
        % resets the imaq log file and video camera properties
        vParaNw = vPara(exObj.nCountV);
        setupLogVideo(exObj,vPara(exObj.nCountV));
        exObj.objIMAQ = setupCameraProps(exObj.objIMAQ,vParaNw);
        
        % flushes the frame data already from the IMAQ object
        flushdata(exObj.objIMAQ)
        
        % if running a real-time tracking experiment (and outputting the
        % solution files directly) then re-initialise the data struct)
        if exObj.isRT
            initRTTrackExpt(exObj.hMain,exObj.hProg,false); 
        end        
        
        % updates the waitbar figure
        wFunc(2,'Starting Camera Object...',0,exObj.hProg);
        
        % restarts the camera        
        start(exObj.objIMAQ); pause(0.05)
        
        % updates the waitbar figure
        wFunc(2,'Waiting For Camera Trigger...',0,exObj.hProg);             
        
        % resets the save flag to false
        exObj.isSaving = false;        
    end
else
    % pauses a bit for things to update...
    pause(1);
    
    % converts the recordings (if required)
    exObj.convertExptVideos();
    
    % resets the preview axes image to black
    vRes = getVideoResolution(exObj.objIMAQ);
    Img0 = zeros(vRes([2 1]));
    set(findobj(exObj.hAx,'Type','Image'),'cData',Img0);
    
    % enables the video preview toggle    
    hMainH = guidata(exObj.hMain);
    setObjEnable(hMainH.toggleVideoPreview,'on')
end

% --- function that stops the camera
function stopCamera(objIMAQ)

% removes the camera stop function
sFunc = objIMAQ.stopFcn; 
objIMAQ.stopFcn = [];

% stops the camera
stop(objIMAQ); 

% resets the camera stop function
objIMAQ.StopFcn = sFunc;  
            
%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the log video for recording --- %
function objIMAQ = setupCameraProps(objIMAQ,vPara)

% sets the frame rate of the recording by altering the camera parameters
srcObj = getselectedsource(objIMAQ);

% sets the camera frame rate
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
flushdata(exObj.objIMAQ)

% sets the log-file name
logName = fullfile(vPara.Dir,vPara.Name);

% sets the video FPS and colormap
logFile = VideoWriter(logName,vPara.vCompress); 
if isempty(vPara.FPS)
    % sets the camera frame rate
    srcObj = getselectedsource(exObj.objIMAQ);
    [fRate,~,iSel] = detCameraFrameRate(srcObj,[]);
    logFile.FrameRate = fRate(iSel);            
else
    logFile.FrameRate = vPara.FPS;
end
    
% sets the colormap (for an index avi
if strcmp(vPara.vCompress,'Indexed AVI')
    logFile.Colormap = repmat(linspace(0,1,256)',[1,3]);
end

% sets the other video parameters
if strcmp(exObj.objIMAQ.LoggingMode,'memory')
    exObj.objIMAQ.UserData = logFile;
    open(logFile); 
else
    exObj.objIMAQ.DiskLogger = logFile;
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
