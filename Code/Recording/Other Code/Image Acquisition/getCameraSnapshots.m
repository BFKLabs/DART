% --- retrieves the set number of frames from the camera
function Img = getCameraSnapshots(iMov,iData,objIMAQ,fPara,h)

% parameters & memory allocation
wOfs = 1;
[Img,ImgMn] = deal([]);

% sets up the waitbar figure
if ~exist('h','var')
    wOfs = 0;
    wStr0 = {'Reading Image Frames','Current Frame Wait'};
    h = ProgBar(wStr0,'Reading Video Frames');
end

% creates the video phase class object
if isempty(iData)
    % case is running the real-time tracking
    phObj = struct('pTolPhase',5);
else
    % case is running the background image calculation
    phObj = VideoPhase(iData,iMov,h,1);
end
    
% reads the required frames from the camera
while 1 
    % updates the waitbar figure
    iFrm = length(Img)+1;
    wStrNw = sprintf('%s (%i of %i)',h.wStr{1},iFrm,fPara.Nframe);
    if h.Update(1+wOfs,wStrNw,iFrm/fPara.Nframe)
        % if the user cancelled, then exit the function
        Img = [];
        return
    end        
    
    % reads the new frame from the camera
    ImgNw = getRotatedImage(iMov,double(getsnapshot(objIMAQ)));
%     ImgMnNw = phObj.calcCombinedImgAvg(ImgNw);
    
    %
    if isempty(Img)
        % if the arrays are empty, then initialise them
        Img = {ImgNw};
        ImgMn = {ImgNw};
        
    else
        % otherwise, determine if the new frame matches roughly the last
        % frame in the image stack
        ImgMnNw = mean(arr2vec(calcImageStackFcn(Img,'mean')),'omitnan');
        dImgMn = abs(max(ImgMnNw(:)-ImgMn{end}(:)));
        if dImgMn > phObj.pTolPhase
            % if the match is poor, then reset the arrays
            Img = {ImgNw};
            ImgMn = {ImgMnNw};
            
        else
            % if there is more than one match, then retrieve the best match
            Img{end+1} = ImgNw;
            ImgMn{end+1} = ImgMnNw;
            
            % if the required number of frames has been reached, then exit
            % the frame capture loop
            if length(Img) == fPara.Nframe                
                break
            end
        end     
    end       
    
    % pause for required time period
    if ~pauseForFrame(h,fPara,wOfs)
        % if the user cancelled, then exit the function
        Img = [];
        return        
    end
end

% ensures the array is a column array
Img = Img(:);

% closes the waitbar figure
if wOfs == 0; h.closeProgBar(); end

% --- pauses for the next frame (updates the waitbar figure)
function ok = pauseForFrame(h,fPara,wOfs)

% sets up the wait timer object
ok = true;
tUpdate = 0.05;
nUpdate = roundP(fPara.wP/tUpdate);

% updates the progressbar for the required number of iterations
for i = 1:nUpdate
    tRemain = tUpdate*(nUpdate-i);
    wStrNw = sprintf('Waiting For New Frame (%.1fs Remains)',tRemain);
    if h.Update(2+wOfs,wStrNw,i/nUpdate)
        ok = false;
        return
    else
        java.lang.Thread.sleep(tUpdate*1000)
    end
end
