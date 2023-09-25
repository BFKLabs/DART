% --- Loads the image/video data into the image data struct ---------------
function [ok,iData] = loadImgData(...
                        handles,fName,fDir,setMovie,isSolnLoad,iData,iMov)

% global variables
global isBatch bufData frmSz0

% sets the default values
if isempty(isBatch); isBatch = false; end

% object handles
nFrmMin = 10;
hFig = handles.output;

% retrieves the program/sub-image stack data struct
if nargin < 6
    [iData,iMov] = deal(hFig.iData,hFig.iMov);
end
    
% sets the GUI properties after loading the image (if not batch processing)
if ~isBatch
    set(handles.checkLocalView,'value',0)        
    setTrackGUIProps(handles,'PreImageLoad')
end

% initialisations
[Frm0,T0] = deal(1,0);
fStr = fullfile(fDir,fName);

% sets up the video reader object (if corrupted then exit)
[~,~,fExtn] = fileparts(fStr);
[mObj,vObj,ok] = setupVideoObject(fStr);
if ~ok; return; end

% if the video frame count is too low, then exit
iData.nFrmT = getVideoFrameCount(mObj,vObj,fExtn);
if iData.nFrmT < nFrmMin
    ok = false;
    return
end

% opens the movie file object
[wState,isVidObj] = deal(warning('off','all'),true);
switch fExtn
    case {'.mj2','.mov','.mp4'}
        % case is an .mj2, .mov or .mp4 files
        hFig.mObj = mObj;
        iData.sz = [mObj.Height mObj.Width];        
        iData.exP.FPS = calcFrameRateEst(iData,mObj.FrameRate);           
        
    case '.mkv'
        % case is .mkv files
        hFig.mObj = mObj;        
        
        % reads in a small sub-set of images (to determine size/frame rate)
        [tTmp,nFrmTmp] = deal([],5);
        for i = 1:nFrmTmp
            [ITmp,tTmp(i)] = mObj.getFrame(i-1);
        end
        
        % sets the image dimensions/video frame rate
        iData.sz = size(ITmp);
        iData.exP.FPS = 1000/(mean(diff(tTmp)));                                  
        
    otherwise        
        % case is .avi files
        isVidObj = false;        
        iData.sz = [vObj.height,vObj.width]; 
        iData.exP.FPS = calcFrameRateEst(iData,vObj.rate);        
        
        % sets the time-span for the frame and reads it from file
        iFrm0 = roundP(iData.nFrmT/2);
        tFrm = iFrm0/iData.exP.FPS + (1/(2*iData.exP.FPS))*[-1 1];
        [~,~] = mmread(fStr,[],tFrm,false,true,'');
        
end
warning(wState);

% determines if the video is multi-channel (video open only)
if isprop(mObj,'VideoFormat')
    iMov.hasRGB = strcmp(mObj.VideoFormat,'RGB24');
else
    iMov.hasRGB = false;
end

% sets the movie/solution file directory summary file names
sStrM = fullfile(fDir,getSummFileName(fDir));
if ~isempty(iData.sfData)
    sStrS = fullfile(iData.sfData.dir,getSummFileName(iData.sfData.dir));
    
else
    sStrS = [];
end

% determines if the movie/solution file directory summary file is present
sStr = [];
if exist(sStrM,'file') > 0
    % case is the movie directory summary file is present
    sStr = sStrM;
    
elseif exist(sStrS,'file') > 0
    % case is the solution directory summary file is present
    sStr = sStrS;
end

% sets the video index. if one not set, then use the first index
try
    iVid = str2double(fName(end+(-7:-4)));
    if isnan(iVid); iVid = 1; end
catch
    iVid = 1;
end

% opens the movie file and gets the movie details
[iData.movStr,iData.isLoad] = deal(fStr,false);     
% sets the video index
if ~isempty(sStr)
    % loads the summary data file 
    A = checkSummFileTimeStamps(iData,sStr);
    if (iVid > length(A.tStampV)) && (length(A.tStampV) == 1)
        iVid = 1;
    end    
    
    % sets the final time vector
    Tv = A.tStampV{iVid};
    iData.Tv0 = Tv(1);
    iData.Tv = Tv(:) - iData.Tv0;      
    
    % sets the experimental data struct
    iData.iExpt = A.iExpt;
    
%     %     
%     iszTv = (Tv == 0); iszTv(1) = false;
%     nanTv = isnan(A.tStampV{iVid}) | iszTv;
%     
%     % determines if there are NaN values in the time vector
%     if all(nanTv)
%         % if all time values are NaN values, then set up a dummy array
%         iData.Tv = (0:(length(Tv)-1))'/iData.exP.FPS;
%         
%     else                
%         % sets the final time vector
%         if any(nanTv)
%             FPS = 1/calcWeightedMean(diff(Tv));
%             i0 = find(~nanTv,1,'first');
%             Tv = removeTimeNaNs(Tv,FPS,Tv(i0)-(i0-1)/FPS,nanTv);
%         end           
%     end       
   
    
    % retrieves the videos stimuli information
    if isempty(iData.stimP)
        summFile = getSummaryFilePath(iData);
        [iData.stimP,iData.sTrainEx] = getExptStimInfo(summFile,Tv);
    end    
    
    % sets the stimuli info menu item enabled properties
    setObjEnable(handles.menuStimInfo,detIfHasStim(iData.stimP))    
else
    % otherwise, set empty 
    [iData.Tv,iData.stimP,iData.sTrainEx] = deal([]);   
    setObjEnable(handles.menuStimInfo,'off')
end 

% sets the global frame size 
frmSz0 = iData.sz; 

% sets the image rotation flag
if isfield(iMov,'useRot')
    if detIfRotImage(iMov)
        iData.sz = flip(iData.sz); 
    end
end

% calculates an estimate of the sampling rate from the time stamps
FPSest = 1/median(diff(iData.Tv),'omitnan');
if rectifyRatio(iData.exP.FPS/FPSest) > 1.1
    % if there is a major discrepancy, then determine if the calculated
    % sampling rate is better than the stated value
    iDataT = iData;
    if isnan(iDataT.Frm0)
        % sets the initial frame (if not set)
        iDataT.Frm0 = Frm0;
    end
    
    % retrieves an image from the video (given the stated sampling rate)
    I0 = getDispImage(iDataT,iMov,10,false);
    if isempty(I0) || all(isnan(I0(:)))
        % if there was an error then reset the rate to the calculated value
        iData.exP.FPS = FPSest;
    end
end

% sets the time vector/total frame count
if isempty(iData.Tv)
    % case is the time vectory is empty
    FPS = 1/iData.exP.FPS;
    iData.Tv = 0:FPS:(FPS*(iData.nFrmT-1));
    
elseif iData.nFrmT < length(iData.Tv)
    % case is the time vector 
    iData.Tv = iData.Tv(1:iData.nFrmT);
    
elseif iData.nFrmT > length(iData.Tv)
    iData.nFrmT = length(iData.Tv);
end

% sets the movie sample rate (if opening movie only)
if hFig.cType > 0
    [iMov.sRate,Frm0] = deal(roundP(iData.exP.FPS),1);
    set(hFig,'iMov',iMov)   
    
elseif (setMovie && ~isSolnLoad) && ~isBatch  
    [iMov.sRate,Frm0] = SampleRate(iData);
    set(hFig,'iMov',iMov)   
end

% sets the initial frame (if not set)
if isnan(iData.Frm0)
    iData.Frm0 = Frm0;
end

% determines the first feasible frame
if isVidObj
    % sets the final frame
    iData.nFrm = length(iData.Frm0:iMov.sRate:iData.nFrmT);
else
    % determines the first feasible frame
    while 1
        [V,~] = mmread(fStr,[],T0+0.01*[-1 1],false,true,'');
        if ~isempty(V.frames)
            % if a valid frame was read, then exit the loop
            break
        else
            % otherwise, increment the time by the frame rate
            [T0,iData.Frm0] = deal(T0 + 1/iData.exP.FPS,iData.Frm0+1);
        end
    end
    
    % determines the last feasible frame    
    iData.nFrm = length(iData.Frm0:iMov.sRate:iData.nFrmT);
    while 1
        try
            I = getDispImage(iData,iMov,iData.nFrm,0,handles);
        catch
            I = [];
        end
            
        if ~isempty(I)
            % if a valid frame was read, then exit the loop
            break
        else
            % otherwise, decrement the frame count
            iData.nFrm = iData.nFrm - 1;
        end
    end        
end

% sets the final total frame count
iData.Tv = iData.Tv(:);

% enables the play movie button (if there is more than one frame)
iData.isOpen = true;
[iData.cFrm,iData.cStp] = deal(1);
iData.fData = dir(fStr);
iData.fData.dir = fDir;
set(hFig,'iData',iData);

% resizes the gui
resizeFlyTrackGUI(hFig)

% creates the tracking marker class object
if detMltTrkStatus(iMov)
    hFig.mkObj = MultiTrackMarkerClass(hFig,handles.imgAxes);
else
    hFig.mkObj = TrackMarkerClass(hFig,handles.imgAxes);
end

% updates the GUI properties (if not batch processing)
if ~isBatch
    % determines if there is an executable for loading the image stacks    
    if ~isempty(bufData)           
        % if the buffer timer is running, then stop it
        if strcmp(get(bufData.tObjChk,'Running'),'on')
            stop(bufData.tObjChk)
            try stop(bufData.tObjChk); catch; end
        end
        
        % deletes the temporary file (if it exists)
        if exist(bufData.tmpFile,'file')
            delete(bufData.tmpFile);
        end
        
        % if so, then reset the image stack indices and flag that all the 
        % image sectors are to be updated 
        mGrp = 3;
        bufData.indStack = (-mGrp:(mGrp-1))*bufData.fDel;
        [bufData.I(:),bufData.isUpdate(:)] = deal({[]},[0 1 1 1 1 0]); 
        [bufData.i0,bufData.iL,bufData.canUpdate] = deal(1,0,true);                
        
        % restarts the buffer timer 
        start(bufData.tObjChk)
        
        % disables the play button
        setObjEnable(handles.toggleVideo,'off')           
    end               

    % updates the GUI
    setTrackGUIProps(handles,'PostImageLoad')

    % updates the use grayscale menu item properties
    eStr = {'off','on'};
    set(handles.menuUseGray,'Checked',eStr{1+(~iMov.useRGB)})
    setObjVisibility(handles.menuUseGray,iMov.hasRGB);
    setObjEnable(handles.menuUseGray,iMov.hasRGB)
    
    % sets the GUI properties after loading the image
    hFig.checkFixRatio_Callback(handles.checkFixRatio, [], handles)
    
else
    % sets the GUI properties after loading the image
    setTrackGUIProps(handles,'PostImageLoadBatch')
end

% retrieves the program/sub-image stack data struct
if nargin < 6
    [hFig.iData,hFig.iMov] = deal(iData,iMov);
end

function FPS = calcFrameRateEst(iData,FPS0)

if ~isfield(iData,'Tv') || isempty(iData.Tv)
    FPS = FPS0;
else
    FPS = round(1./mean(diff(iData.Tv),'omitnan'),2);
end