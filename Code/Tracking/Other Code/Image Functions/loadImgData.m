% --- Loads the image/video data into the image data struct ---------------
function [ok,iData] = loadImgData(...
                        handles,fName,fDir,setMovie,isSolnLoad,iData,iMov)

% global variables
global isBatch bufData frmSz frmSz0

% retrieves the program/sub-image stack data struct
if nargin < 6
    iData = getappdata(handles.figFlyTrack,'iData');
    iMov = getappdata(handles.figFlyTrack,'iMov');
end
    
% sets the GUI properties after loading the image (if not batch processing)
if ~isBatch
    set(handles.checkLocalView,'value',0)        
    setTrackGUIProps(handles,'PreImageLoad')
end

% initialisations
[ok,Frm0,T0] = deal(1,1,0);
cType = getappdata(handles.figFlyTrack,'cType');
eStr0 = 'Error! Video appears to be corrupted. Suggest deleting file.';

% sets the full movie/summary file strings and determines the file data
fStr = fullfile(fDir,fName);

% attempts to determine if the movie file is valid
[~,~,fExtn] = fileparts(fStr);
if exist(fStr,'file') > 0
    try
        % uses the later version of the function 
        switch fExtn
            case {'.mj2', '.mov'}
                mObj = VideoReader(fStr);
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
warning off all
switch fExtn
    case {'.mj2', '.mov'}
        setappdata(handles.figFlyTrack,'mObj',mObj)
        iData.exP.FPS = mObj.FrameRate;
        iData.sz = [mObj.Height mObj.Width];        
        iData.nFrmT = mObj.NumberOfFrames;
        isVidObj = true;
    otherwise        
        iData.sz = [V.height V.width];        
        iData.exP.FPS = V.rate;
        iData.nFrmT = abs(V.nrFramesTotal);
        isVidObj = false;
end
warning on all

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
iVid = str2double(fName(end+(-7:-4)));
if isnan(iVid); iVid = 1; end

% sets the video index
if ~isempty(sStr)
    % loads the summary data file and sets the video time stamps/stimulus
    % parameters
    A = load(sStr);
    Tv = A.tStampV{iVid};
    iszTv = (Tv == 0); iszTv(1) = false;
    nanTv = isnan(A.tStampV{iVid}) | iszTv;
    
    % determines if there are NaN values in the time vector
    if all(nanTv)
        % if all time values are NaN values, then set up a dummy array
        iData.Tv = (0:(length(Tv)-1))'/iData.exP.FPS;
        
    else                
        % sets the final time vector
        if any(nanTv)
            FPS = 1/calcWeightedMean(diff(Tv));
            i0 = find(~nanTv,1,'first');
            Tv = removeTimeNaNs(Tv,FPS,Tv(i0)-(i0-1)/FPS,nanTv);
        end
        
        % sets the final time vector
        iData.Tv = Tv(:) - Tv(1);    
    end
    
    % sets the properties of the related objects
    setObjEnable(handles.textStatus,'on')
    if ~isBatch
        setObjEnable(handles.menuStimInfo,'on')
    end        
    
    % determines if the experiment had any stimuli data
    if isempty(A.tStampS)
        % if no stimuli, then set as false
        hasStim = false;
    else
        % FINISH ME! (Fix up the Stimuli Information GUI)
        hasStim = false;
        
%         % otherwise, retrieve the stimuli data for the experiment
%         if isfield(A,'sTrain')
% 
%         else
% 
%         end
    end
    
    % if there are stimuli events, which are not random, then set the
    % stimuli index array
    if hasStim
        iData.stimP = setStimPara(A.iExpt,iData.Tv);
    else
        iData.stimP = [];
    end
else
    % otherwise, set empty 
    [iData.Tv,iData.stimP] = deal([]);   
    setObjEnable(handles.textStatus,'off')  
    setObjEnable(handles.menuStimInfo,'off')
end

% opens the movie file and gets the movie details
iData.movStr = fStr;
iData.isLoad = false;      

% sets the global frame size 
[frmSz,frmSz0] = deal(iData.sz); 

% sets the image rotation flag
if isfield(iMov,'rot90')
    if iMov.rot90
        [iData.sz,frmSz] = deal(iData.sz([2 1]),frmSz([2 1])); 
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
if cType > 0
    [iMov.sRate,Frm0] = deal(roundP(iData.exP.FPS),1);
    setappdata(handles.figFlyTrack,'iMov',iMov)   
    
elseif (setMovie && ~isSolnLoad) && ~isBatch  
    [iMov.sRate,Frm0] = SampleRate(iData);
    setappdata(handles.figFlyTrack,'iMov',iMov)
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
        I = getDispImage(iData,iMov,iData.nFrm,0,handles);
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

% updates the program data struct
setappdata(handles.figFlyTrack,'iData',iData);

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
        
    % checks to see if there is any stimuli information for the file
    if ~isempty(iData.stimP)
        % sets the time vector for the video        
        iData.stimFrm = setStimFrameStats(iData);                     
        
        % sets the stimulus event frame stats (if set)
        if any(iData.stimFrm > 0)
            % disables the stimulus info menu item
            setObjEnable(handles.menuStimInfo,'on')
        else
            % disables the stimulus info menu item
            setObjEnable(handles.menuStimInfo,'off')
        end        
        
        % updates the program data struct
        setappdata(handles.figFlyTrack,'iData',iData); 
    else
        % disables the stimulus info menu item
        setObjEnable(handles.menuStimInfo,'off')
    end            

    % updates the GUI
    setTrackGUIProps(handles,'PostImageLoad')
    
    % sets the GUI properties after loading the image
    checkFcn = getappdata(handles.figFlyTrack,'checkFixRatio_Callback');
    checkFcn(handles.checkFixRatio, [], handles)
else
    % sets the GUI properties after loading the image
    setTrackGUIProps(handles,'PostImageLoadBatch')
    
    % if there are any stimuli events, then setup the stimuli index vector
    if ~isempty(iData.stimP) 
        % sets the time vector for the video        
        iData.stimFrm = setStimFrameStats(iData);      
        setappdata(handles.figFlyTrack,'iData',iData); 
    end
end

% --- retrieves the stimulus parameters from the summary file --- %
function stimP = setStimPara(iExpt,Tv)

% index for the movie
[Stim,T0] = deal(iExpt.Stim,Tv(1));
nChannel = length(Stim);

% sets the time bounds for the current movie 
[indTs,indTf] = field2cell(Stim,{'Ts','Tf'});

% stimulus parameter struct memory allocation
a = struct('Tsig',[],'Ysig',[],'Ts0',[],'TsF',[],'sP',[]);
stimP = repmat(a,nChannel,1);

% loops through all the channels on all devices determining the stimulus
% events that occured within the movie, and retrieving their parameters
for i = 1:nChannel
    % determines the indices of any stimuli events that occured within the
    % current movie. 
    [Ts,Tf] = deal((indTs{i}-1),(indTf{i}-1));            
    indStim = find((Tv(1) <= Tf) & (Tv(end) >= Ts));
    
    % updates the stimulus parameter struct
    if ~isempty(indStim)
        % memory allocation
        nStimNw = length(indStim);
        [stimP(i).Tsig,stimP(i).Ysig,stimP(i).sP] = deal(cell(nStimNw,1));
        [stimP(i).Ts0,stimP(i).TsF] = deal(zeros(nStimNw,1));
    
        % loops through all the stimuli events that occured within the
        % movie, and retrieves the important parameters
        for j = 1:length(indStim)
            % sets the new stimulus index
            iNw = indStim(j);
            
            % sets the stimulus parameter struct
            stimP(i).sP{j} = Stim(i).sigPara{iNw};
            stimP(i).Tsig{j} = Stim(i).Tsig{iNw};
            stimP(i).Ysig{j} = Stim(i).Ysig{iNw};            
            [stimP(i).Ts0(j),stimP(i).TsF(j)] = deal(Ts(iNw)-T0,Tf(iNw)-T0);            
        end
    end
end
