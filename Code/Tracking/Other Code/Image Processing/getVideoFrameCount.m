% --- retrieves the video frame count
function nFrmT = getVideoFrameCount(mObj,vObj,fExtn)

% opens the movie file object
switch fExtn
    case {'.mj2','.mov','.mp4'}
        
        % determines the final frame count (some frames at the
        % end of videos sometimes are dodgy...)        
        nFrmT = mObj.NumberOfFrames;        
        while 1            
            try 
                % reads a new frame. 
                I = read(mObj,nFrmT);
                break
            catch
                % if there was an error, reduce the frame count
                nFrmT = nFrmT - 1;
            end
        end
        
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