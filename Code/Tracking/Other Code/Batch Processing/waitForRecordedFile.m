% --- waits for a file, fName to finish recording. the information
%     pertaining to the files output is given iExpt
function ok = waitForRecordedFile(fName,iExpt,h,ind)

% sets the extension of the file being loaded
[~,~,fExtn] = fileparts(fName);

% initialisations
[tTimeOut,tPause,ok] = deal(300,1,false);

% sets the waitbar figure properties
if nargin < 4
    ind = 1;
    h = ProgBar('Initialising','Waiting For Recorded File');
end

% if the experiment information is given (as is the case for a recorded
% video) then determine if the program needs to wait until it arrives
if ~isempty(iExpt)
    % sets the file index
    [VV,TT,ok] = deal(iExpt.Video,iExpt.Timing,false);
    fIndex = str2double(fName(end-7:end-4));
    if (fIndex > VV.nCount)
        % if the file index exceeds the video count, then exit with an error
        eStr = 'Error! File index exceeds that of total video count';
        waitfor(errordlg(eStr,'Recorded File Waiting Error','modal'))
        return
    end

%     % sets the offset times
%     if fIndex == 1     
%         [Tofs,Ttot] = deal(ceil(VV.Tf(fIndex)/VV.FPS));
%     else                
%         % loads the summary file and retrieves the time stamp information 
%         [fDir,~,~] = fileparts(fName);
%         snFile = fullfile(fDir,'Summary.mat');     
%         A = load(snFile,'tStampV'); 
%         
%         % determines the time stamp for the end of the previous video       
%         ii = find(~isnan(A.tStampV{fIndex-1}),1,'last');
%         Tend = ceil(A.tStampV{fIndex-1}(ii));
%         
%         % sets the new offset as the difference between the
%         % current/previous videos and the time stamp of the final frame of
%         % the previous video
%         Ttot = ceil(VV.Tf(fIndex)-VV.Tf(fIndex-1))/VV.FPS;                
%         Tofs = Tend + Ttot;
%     end

    % calculates the time difference     
    Ttot = VV.Tf(fIndex)-VV.Ts(fIndex);
    Tvid = datevec(addtodate(datenum(TT.T0),VV.Tf(fIndex),'second'));

    % while the wait time is greater than zero, keep updating the waitbar
    Twait = ceil(max(0,calcTimeDifference(Tvid,clock)));
    while Twait > 0
        % sets the waitbar figure paramerters
        Twait = ceil(max(0,calcTimeDifference(Tvid,clock)));
        [~,~,C] = calcTimeDifference(Twait);
        
        % sets the 
        wStrNw = sprintf(['Waiting For Next Video (Approx Time ',...
                          'Remaining = %s:%s:%s)'],C{2},C{3},C{4});
        pW = max(0,1-Twait/Ttot);

        % updates the waitbar figure
        if h.Update(ind,wStrNw,pW)
            return
        else
            % otherwise, pause for the set time
            pause(tPause)
        end
    end
end
    
% determines if the movie file has been finished recording properly. the
% function checks if the wait-time exceeds the timeout limit. if so, then
% exit with an error flag
Ttry = clock;
while (1)
    try
        % attempts to read the movie file. if the attempt is successful,
        % then the inner loop will be exited with a success flag
        switch (fExtn)
            case ('.mat') % case is a .mat file
                fStr = 'Summary File';
                A = load(fName);
            otherwise % case is a video file
                fStr = 'Recorded Video';
                mObj = VideoReader(fName);
        end
        ok = true; 
        break
    catch
        % calculates the retry time for
        TtryNw = floor(calcTimeDifference(clock,Ttry));
        if (TtryNw > tTimeOut)
            break
        else
            % sets the new waitbar figure properties
            dT = tTimeOut - TtryNw;
            wStrNw = sprintf('Searching For %s (Timeout in %i seconds)',fStr,dT);
            
            % updates the waitbar figure
            if h.Update(ind,wStrNw,1-(dT/tTimeOut))
                % if the user cancelled, then exit the function
                return
            else
                % otherwise, pause for the set time
                pause(tPause)
            end
        end
    end
end

% closes the waitbar figure (if created in this function)
if nargin == 2
    h.closeProgBar()
end
