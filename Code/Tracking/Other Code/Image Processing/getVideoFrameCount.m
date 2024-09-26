% --- retrieves the video frame count
function nFrmT = getVideoFrameCount(mObj,vObj,fExtn)

% opens the movie file object
switch fExtn
    case {'.mj2','.mov','.mp4','.avi'}
        
        % determines the final frame count (some frames at the
        % end of videos sometimes are dodgy...)
        iOfs = 1;        
        while 1  
            % resets the video object current time
            mObj.CurrentTime = mObj.Duration - iOfs/mObj.FrameRate;
            
            try 
                % reads a new frame from the current time 
                readFrame(mObj);
                break
            catch
                % if there was an error, the increment the frame count
                iOfs = iOfs + 1;
            end
        end
        
        % sets the final frame
        nFrmT = round(mObj.CurrentTime*mObj.FrameRate);
        
    case '.mkv'
        
        % determines the final frame count (some frames at the
        % end of videos sometimes are dodgy...)  
        nFrmT = mObj.numberOfFrames;        
        while 1
            try 
                % reads a new frame. 
                [~,~] = mObj.getFrame(nFrmT - 1);
                break
            catch
                % if there was an error, reduce the frame count
                nFrmT = nFrmT - 1;
            end
        end        
        
    otherwise        
        % case is .avi files
        nFrmT = abs(vObj.nrFramesTotal);
        
end