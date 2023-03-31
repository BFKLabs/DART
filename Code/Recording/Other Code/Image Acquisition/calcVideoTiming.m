% --- calculates the video recording timing --- %
function mStr = calcVideoTiming(handles,varargin)

% sets the wait period after a stimuli event
global stimWait initObj
stimWait = 15;

% retrieves the required data structs
mStr = [];
rType = 'FixedDur';
hFig = handles.figExptSetup;
iExpt = getappdata(hFig,'iExpt');
sTrain = getappdata(hFig,'sTrain');
infoObj = getappdata(hFig,'infoObj');

% if this is a stimuli only expt, then exit the function
if strcmp(infoObj.exType,'StimOnly')
    return
end

% derived parameters
[isCheck,VV] = deal(true,iExpt.Video);
szFrm = getVideoResolution(infoObj.objIMAQ);

% determines if there are any stimuli signals
if isempty(sTrain)
    hasStim = false;
else
    hasStim = ~isempty(sTrain.Ex);
end

% if the number of frames
tExp = vec2sec(iExpt.Timing.Texp);
tVid = vec2sec([0,iExpt.Video.Dmax]);
if (tExp < tVid) && strcmp(iExpt.Info.Type,'RecordOnly')
    [VV.nCount,VV.Ts,VV.Tf] = deal(1,1,nFrameTot);
    iExpt.Video = VV;
    setappdata(hFig,'iExpt',iExpt);
    return
end

% calculates video recording start/stop times given the recording type
switch rType
    case 'BtwnStim' 
        % case is recording between the stimuli
        iExpt = calcBtwnStimTimes(iExpt);
        
    case 'OnStim' 
        % case is recording on the stimuli
        iExpt = calcOnStimTimes(iExpt);
        
    case 'FixedDur' 
        % case is recording fixed duration
        if isempty(varargin)
            % case is calculating the fixed duration times
            iExpt = calcFixedDurTimes(iExpt);
        else
            % case is optimising the fixed duration times
            iExpt = optFixedDurTimes(iExpt);
        end          
        
        % check to see if the video parameters are feasible
        if ~hasStim
            if (isnan(iExpt.Video.nCount) || (iExpt.Video.nCount == 0))
                % if not feasible, then set video check-mark to false
                isCheck = false;
            end        
        end
end

% calculates the total number of video frames
VV = iExpt.Video;

% sets and updates the video frame count
set(handles.textRecordDur,'string',num2str(ceil(max(VV.Tf-VV.Ts)*VV.FPS)))     

% sets the video feasbility check box
if isfield(handles,'checkVidFeas')
    set(handles.checkVidFeas,'value',isCheck)
end
% feval(getappdata(hFig,'setSaveRunEnable'),handles)

% initialisations
txtCol = 'kr';
b2gb = 1/(1024^3);
nFrmTot = sum(ceil((VV.Tf-VV.Ts)*VV.FPS));
fSizeTot = b2gb*estTotalVideoSize(nFrmTot,szFrm,VV.vCompress);

% determines the currently selected volume (from the video file output)
volInfo = getDiskVolumeInfo();
iVol = cellfun(@(x)(startsWith(iExpt.Info.OutDir,x)),volInfo(:,1));
isWarn = fSizeTot > volInfo{iVol,3};

% sets the total video/frame count strings
set(handles.textFrmCount,'string',sprintf('%.2fGB',fSizeTot),...
                         'foregroundcolor',txtCol(1+isWarn));
set(handles.textVidCount,'string',num2str(VV.nCount));

% determines if the estimated required disk space exceeds the free space
if isWarn && ~initObj
    % if so, then output a message to screen
    mStr = sprintf(['Warning! The estimated total disk space required ',...
                    'for the experiment exceeds the free space:\n\n',...
                    ' * Estimated Required Space = %.2fGB\n',...
                    ' * Free Space on %s = %.2fGB\n\n'],fSizeTot,...
                    volInfo{iVol,1},volInfo{iVol,3});
       
    % outputs the message to screen (if not outputting to screen)
    if nargout == 0
        mStr = sprintf(['%sEither select another drive for video ',...
                       'file output, select another video compression ',...
                       'type, or reduce the experiment duration.'],mStr);        
        waitfor(msgbox(mStr,'Disk Space Warning','modal'))   
    end
end

% updates the stimulus data struct
setappdata(hFig,'iExpt',iExpt);

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% ----------------------------------------- %
% --- VIDEO RECORDING TIME CALCULATIONS --- %
% ----------------------------------------- %

% --- function for calculating the between-stimulus fixed duration times
function iExpt = calcBtwnStimTimes(iExpt)

% --- The between-stimulus video files assumes that:
%      A) the videos will on the first frame
%      B) if the duration of the movies is too short, then it will be
%         combined with neighbouring movies
%      C) if the duration is too long, then the duration will be split into
%         three seperate movies of equal length
%      D) in general, video length will be variable

% sets the wait period after a stimuli event
global stimWait

% retrieves the timing/video sub-structs
[TT,VV,SS] = deal(iExpt.Timing,iExpt.Video,iExpt.Stim);

% retrieves the important parameter values from the sub-struct
[Tp,Texp,Tmax] = deal(TT.Tp,TT.Texp,vec2sec([0,VV.Dmax])+TT.Tp);

% calculates the total possible number of frames and the pause frame count
[tPause,tTot] = deal(Tp,vec2sec(Texp));
A = false(tTot,1); A([1 end]) = true;

% retrieves the stimulus start/finish times
[Ts,Tf] = retStimTimes(SS,stimWait);

% ensures all stimuli less than the total duration are counted
jj = Ts < tTot;
[Tf,Ts] = deal(Tf(jj),Ts(jj));

% sets the indices of the stimuli regions in a logical array
for i = 1:length(Ts)
    A(max(1,Ts(i)-tPause):min(Tf(i)+stimWait,tTot)) = true;
end

% calculates the distance of the non-stimuli frames to the stimuli frames.
% from this, determine the peak values (i.e., the max distance between
% stimuli 
Ts2 = cell2mat(calcSignalExtremumPeaks(bwdist(A),false,1));
if (Ts2(end) == tTot)
    Ts2 = Ts2(1:(end-1));
end
Ts2 = [1;Ts2];

% determines the movies that have a duration (in frames) longer than the
% maximum movie duration
cont = true;
while (cont)
    % calculates the difference between the video start times (with the
    % pause time removed) and determines if any videos are greater than
    % Lmax in duration 
    dFrm = diff([Ts2;tTot]);
    kk = find(dFrm > Tmax);
    
    % check to see if there are any movies > Lmax
    if (isempty(kk))
        % if not, then exit the loop
        cont = false;
    else
        % otherwise, split up the offending movies into 2
        for j = length(kk):-1:1
            % sets the frame index and the new frame count between videos
            i = kk(j);
            dFrmNw = floor((dFrm(i)-2*tPause)/3);

            % sets the new video start time array with the new split times
            Tnw = Ts2(i) + [0;(dFrmNw+tPause);2*(dFrmNw+tPause)];
            Ts2 = [Ts2(1:(i-1));Tnw;Ts2((i+1):end)];
        end
    end
end

% optimises the bin-sizes (to remove any small-bins)
Ts2 = detOptBin(Ts2,tTot,Tmax)-1;

% sets the final video parameters
VV.nCount = length(Ts2);
[VV.Ts,VV.Tf] = deal(Ts2,[(Ts2(2:end) - tPause);tTot]);

% updates the video parameter sub-struct into the experimental data struct
iExpt.Video = VV;

% --- function for calculating the on-stimulus fixed duration times
function iExpt = calcOnStimTimes(iExpt)

% --- The on-stimulus video files assumes that:
%      A) the videos will start on the stimulus event
%      B) if there are overlapping events, or the duration between events
%         is too small, then don't start new video on event
%      C) if the duration is too long, then the duration will be split into
%         two seperate movies of equal length
%      D) in general, video length will be variable 

% global variables
global stimWait

% retrieves the timing/video sub-structs
[TT,VV,SS] = deal(iExpt.Timing,iExpt.Video,iExpt.Stim);

% retrieves the important parameter values from the sub-struct
[Tp,Texp] = deal(TT.Tp,TT.Texp);
[FPS,Lmax] = deal(VV.FPS,(vec2sec([0,VV.Dmax])+TT.Tp)*VV.FPS);

% calculates the total possible number of frames and the pause frame count
[nFrmPause,nFrmTot] = deal(Tp*FPS,vec2sec(Texp)*FPS);

% retrieves the stimulus start/finish times
[Ts,Tf] = retStimTimes(SS,stimWait);

% determines the stimuli where the start time is greater than the finish
% time of the previous stimuli (remove start times of the non-complient)
jj = [true;Tf(1:(end-1)) < Ts(2:end)] & ((Ts-nFrmPause) < nFrmTot);
Ts2 = Ts(jj);

% determines the movies that have a duration (in frames) longer than the
% maximum movie duration
cont = true;
while (cont)
    % calculates the difference between the video start times (with the
    % pause time removed) and determines if any videos are greater than
    % Lmax in duration 
    dFrm = diff([Ts2;nFrmTot]);
    kk = find(dFrm > Lmax);
    
    % check to see if there are any movies > Lmax
    if (isempty(kk))
        % if not, then exit the loop
        cont = false;
    else
        % otherwise, split up the offending movies into 2
        for j = length(kk):-1:1
            % sets the frame index and the new frame count between videos
            i = kk(j);
            dFrmNw = floor((dFrm(i)-nFrmPause)/2);

            % sets the new video start time array with the new split times
            Tnw = Ts2(i) + [0;(dFrmNw+nFrmPause)];
            Ts2 = [Ts2(1:(i-1));Tnw;Ts2((i+1):end)];
        end
    end
end

% optimises the bin-sizes (to remove any small-bins)
Ts2 = detOptBin(Ts2,nFrmTot,Lmax);

% sets the final video parameters
VV.nCount = length(Ts2);
[VV.Ts,VV.Tf] = deal(Ts2,[(Ts2(2:end)-(nFrmPause+1));nFrmTot]);

% updates the video parameter sub-struct into the experimental data struct
iExpt.Video = VV;

% --- function for calculating the fixed duration video files
function iExpt = calcFixedDurTimes(iExpt)

% --- The fixed duration video files assumes that:
%      A) the videos start on the first frame
%      B) the final video will be of variable length

% retrieves the timing/video sub-structs
[TT,VV] = deal(iExpt.Timing,iExpt.Video);

% updates the video parameter sub-struct into the experimental data struct
tFix = vec2sec([0,VV.Dmax]); 
iExpt.Video = calcFixedDurIndices(VV,tFix,vec2sec(TT.Texp),TT.Tp);

% --- function for optimising the fixed duration video files
function iExpt = optFixedDurTimes(iExpt)

% --- The fixed duration video files optimisation assumes that:
%      A) the videos start on the first frame
%      B) the final video will be of variable length

% --- This optimisation seeks to determine the fixed movie duration that
%     produces the largest absolute distance sum from the stimuli events.
%     note that a feasible solution MUST have all video start/stop times
%     not within tBefore the start of the event, and within tAfter
%     proceeding the event. 

% global variables
global stimWait

% retrieves the timing/video sub-structs
[TT,VV,SS] = deal(iExpt.Timing,iExpt.Video,iExpt.Stim);

% retrieves the important parameter values from the sub-struct
[Lmax,Texp] = deal(vec2sec([0,VV.Dmax])+TT.Tp,TT.Texp);
[tTot,tPause] = deal(vec2sec(Texp),TT.Tp);

% calculates the total possible number of frames and the pause frame count
[Ts,Tf] = retStimTimes(SS,stimWait);

% sets up the stimulus frame event boolean array (true if no stimuli event,
% or false otherwise)
A = ones(tTot,1); 
for i = 1:length(Ts)
    ii0 = max(1,Ts(i)):min(tTot,Tf(i));
    ii2 = [max(1,Ts(i)) min(tTot,Tf(i))];
    [A(ii0),A(ii2)] = deal(0,2);
end

% calculates the duration of each of the stimuli events
ii = find(A == 2);
if (length(ii) > 2) && (mod(length(ii),2) == 1)
    ii = ii(1:end-1);
end

nFrame = diff([ii(1:2:end) ii(2:2:end)],[],2)+1;

% determines the largest region occupied by the stimuli
Lmin = max(nFrame);
if (Lmax < (Lmin+1))
    % if the max frame count is less than the min video frame requirement,
    % then exit the function with an error 
    eStr = ['Unable to optimise fixed frame positioning because the ',...
            'maximum video frame count is too low.'];
    waitfor(warndlg(eStr,'Frame Optimisation Warning','modal'))
    return
end

% determines the indices of the regions occupied by the non-stimuli frames
ii = find(A); 
jj = find(diff(ii) > 1);
if (isempty(jj))
    % if there are no gaps in the stimuli, then set the frame count to be
    % the total frame count
    tFix = tTot;
else
    % 
    kk = [ii(jj+1) [ii(jj(2:end));tTot]];
    
    % sets up the distance array
    D = Lmax*ones(tTot,1); D(~A) = NaN;
    for i = 1:size(kk,1)
        D(kk(i,1):kk(i,2)) = (kk(i,1):kk(i,2)) - (kk(i,1)-1);
    end

    % determines the distance of the frame indices
    xFrm = (Lmin:Lmax)';
    Dmin = cell2mat(cellfun(@(x)(calcFixedFrameDist(...
            D,x,tTot,tPause)),num2cell(xFrm),'un',false));
        
    % determines the feasible frame counts
    iFeas = find(~isnan(Dmin(:,1)));
    if (isempty(iFeas))
        % if there are no feasible frame counts, then exit with a warning
        eStr = [{'Unable to determine feasible fixed frame count.'};...
                {'Try altering stimuli timing or increasing maximum frame count.'}];
        waitfor(warndlg(eStr,'Fixed Frame Count Warning','modal'))            
        return
    else
        % otherwise, determine the new fixed frame value
        [~,imx] = max(Dmin(iFeas,2)./Dmin(iFeas,1));
        tFix = xFrm(iFeas(imx));
    end
end

% updates the video parameter sub-struct into the experimental data struct
iExpt.Video = calcFixedDurIndices(VV,tFix,tTot,tPause);
tVec = sec2vec(max(iExpt.Video.Tf-iExpt.Video.Ts));
iExpt.Video.Dmax = tVec(2:end);

% ---------------------------------- %
% --- BIN OPTIMISATION FUNCTIONS --- %
% ---------------------------------- %

% --- calculates the new video start times such that there are no bins that
%     have a size bigger than 
function Ts2 = detOptBin(Ts2,tTot,Tmax)

% calculates the individual optimal bin sizes
while (1)
    % initialisations for the inner loop
    [nVid,dFrm] = deal(length(Ts2),diff([Ts2;tTot]));
    [ind,cont,isFree] = deal((1:nVid)',true,true(nVid,1));
    
    % calculates the optimal bin indices   
    iBin = cellfun(@(x)(detOptBinIndiv(dFrm,ind(x:end),Tmax)),...
                                        num2cell(ind),'un',0);             
    nVidNw = cellfun('length',iBin); 
    
    % determines if there are any groups to join
    if (all(nVidNw == 1))
        % if there are no viable groups to join, then exit the loop
        break
    else                                
        % while there are still bins to join, keep joining them                                
        while (cont)
            % determines the last 
            nVidMx = max(nVidNw);
            if (nVidMx == 1)
                cont = false;
            else           
                % determines the next optimal bin sizing
                iNw = find(nVidNw == nVidMx,1,'first');        
                if (all(isFree(iBin{iNw})))
                    %        
                    ind(iBin{iNw}(2:end)) = iBin{iNw}(1); 
                    [isFree(iBin{iNw}),nVidNw(iBin{iNw})] = deal(false,1);
                else
                    nVidNw(iBin{iNw}) = 1;
                end
            end
        end
    end
    
    % checks to see if all times have been accounted for. if not, then add
    % the missing values to the time array
    Ts2 = Ts2(ind(diff([-1;ind]) > 0));
end

% --- determines the optimal individual bin indices --- %
function iBin = detOptBinIndiv(dFrm,ind,Lmax)

% memory allocation
dFrmNw = dFrm(ind);
iBin = ind(1:find(cumsum(dFrmNw)<=Lmax,1,'last'));
                             
% ------------------------------ %
% --- MISCELLANEOUS FUNCTION --- %
% ------------------------------ %

% --- calculates
function Dmin = calcFixedFrameDist(D,tFrm,tTot,tPause)

% sets the frame indices of the video start points (must take into account
% the pause at the change-over of the movies)
ii = 1:(tFrm+tPause):tTot; 

% sets the distance values for the frame index points
Dnew = D(ii);
if (any(isnan(Dnew)))
    % if any of the values are infeasible, then return a NaN value   
    Dmin = NaN(1,2);
else
    % otherwise, return the minimum distance
    Dmin = [length(ii) min(Dnew)];
end

% --- retrieves the stimulus times which are sorted by start times --- %
function [Ts,Tf] = retStimTimes(SS,Twait)

% sorts the stimulus start times in chronological order
[Ts,ii] = sort(cell2mat(field2cell(SS,'Ts')));

% reorders the finish times to match the starts times (also takes into
% account the mandatory wait period of Twait after the stimulus)
Tf = cell2mat(field2cell(SS,'Tf')); 
Tf = Tf(ii) + Twait;

% --- calculates the indices of the fixed duration videos --- %
function VV = calcFixedDurIndices(VV,tFix,tExp,tPause)

% calculates the total number of videos, and allocated memory for the video
% start/finish times
VV.nCount = ceil(tExp/(tFix + tPause));
[VV.Ts,VV.Tf] = deal(zeros(VV.nCount,1));

% loops through all the videos setting the start/stop times
for i = 1:VV.nCount
    % sets the start time index (based on the video index)
    if (i == 1)
        % case if the first video
        VV.Ts(i) = 0;        
    else
        % case is the other videos
        VV.Ts(i) = VV.Tf(i-1) + tPause;
    end
    
    % sets the finish time index (ensures the max index is nFrmTot)
    VV.Tf(i) = min(VV.Ts(i) + tFix,tExp);    
end
