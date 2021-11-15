% --- Loads the image/video data into the image data struct ---------------
function [ok,iData] = loadImgData(...
                        handles,fName,fDir,setMovie,isSolnLoad,iData,iMov)

% global variables
global isBatch bufData frmSz0

% sets the default values
if isempty(isBatch); isBatch = false; end

% object handles
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
[ok,Frm0,T0] = deal(1,1,0);
eStr0 = 'Error! Video appears to be corrupted. Suggest deleting file.';

% sets the full movie file name
fStr = fullfile(fDir,fName);

% attempts to determine if the movie file is valid
[~,~,fExtn] = fileparts(fStr);
if exist(fStr,'file')
    try
        % uses the later version of the function 
        switch fExtn
            case {'.mj2', '.mov','.mp4'}
                mObj = VideoReader(fStr);
            case '.mkv'
                mObj = ffmsReader();
                [~,~] = mObj.open(fStr,0);        
            otherwise
                [V,~] = mmread(fStr,inf,[],false,true,'');
        end
        
    catch
        % if an error occured, then output an error and exit the function
        if ~isBatch
            eStr = eStr0;
            waitfor(errordlg(eStr,'Corrupted Video File','modal'))
        end        
        ok = false; return
    end
    
else
    try
        % uses the earlier version of the function 
        aviinfo(fStr)
    catch
        % if an error occured, then output an error and exit the function
        if ~isBatch
            eStr = eStr0;
            waitfor(errordlg(eStr,'Corrupted Video File','modal'))            
        end        
        ok = false; return        
    end
end

% opens the movie file object
[wState,isVidObj] = deal(warning('off','all'),true);
switch fExtn
    case {'.mj2','.mov','.mp4'}
        hFig.mObj = mObj;
        iData.exP.FPS = mObj.FrameRate;
        iData.sz = [mObj.Height mObj.Width];   
        iData.nFrmT = mObj.NumberOfFrames;
        
        while 1            
            try 
                % reads a new frame. 
                Img = read(mObj,iData.nFrmT);
                break
            catch
                % if there was an error, reduce the frame count
                iData.nFrmT = iData.nFrmT - 1;
            end
        end
        
    case '.mkv'
        hFig.mObj = mObj;        
        iData.nFrmT = mObj.numberOfFrames;
        
        % reads in a small sub-set of images (to determine size/frame rate)
        [tTmp,nFrmTmp] = deal([],5);
        for i = 1:nFrmTmp
            [ITmp,tTmp(i)] = mObj.getFrame(i-1);
        end
        
        % sets the image dimensions/video frame rate
        iData.sz = size(ITmp);
        iData.exP.FPS = 1000/(mean(diff(tTmp)));                          
        
        while 1            
            try 
                % reads a new frame. 
                [~,~] = mObj.getFrame(iData.nFrmT - 1);
                break
            catch
                % if there was an error, reduce the frame count
                iData.nFrmT = iData.nFrmT - 1;
            end
        end        
        
    otherwise        
        iData.sz = [V.height V.width];        
        iData.exP.FPS = V.rate;
        iData.nFrmT = abs(V.nrFramesTotal);
        isVidObj = false;
        
end
warning(wState);

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
iData.movStr = fStr;
iData.isLoad = false;     
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
    
    % sets the properties of the related objects
    if ~isBatch
        setObjEnable(handles.menuStimInfo,'on')
    end        
    
    % retrieves the videos stimuli information
    if isempty(iData.stimP)
        summFile = getSummaryFilePath(iData);
        [iData.stimP,iData.sTrainEx] = getExptStimInfo(summFile,iData.Tv);
        setObjEnable(handles.menuStimInfo,detIfHasStim(iData.stimP))  
    end    
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
        iData.sz = iData.sz([2 1]); 
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

% updates the GUI properties (if not batch processing)
if ~isBatch
    % determines if there is an executable for loading the image stacks    
    if ~isempty(bufData)           
        % if the buffer timer is running, then stop it
        if strcmp(get(bufData.tObjChk,'Running'),'on')
            stop(bufData.tObjChk)
            try; stop(bufData.tObjChk); end
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
