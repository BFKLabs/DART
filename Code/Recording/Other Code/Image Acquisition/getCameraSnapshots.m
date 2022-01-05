% --- retrieves the set number of frames from the camera
function Img = getCameraSnapshots(iMov,iData,objIMAQ,frmPara)

% parameters & memory allocation
[Img,ImgMn] = deal([]);

% sets up the waitbar figure
wStr0 = {'Reading Image Frames','Current Frame Wait'};
h = ProgBar(wStr0,'Reading Video Frames');

% creates the video phase class object
phObj = VideoPhase(iData,iMov,h,1);

% reads the required frames from the camera
while 1 
    % updates the waitbar figure
    iFrm = length(Img)+1;
    wStrNw = sprintf('%s (%i of %i)',h.wStr{1},iFrm,frmPara.Nframe);
    if h.Update(1,wStrNw,iFrm/frmPara.Nframe)
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
        ImgMnNw = nanmean(arr2vec(calcImageStackFcn(Img,'mean')));
        dImgMn = abs(max(ImgMnNw(:)-ImgMn{end}(:)))
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
            if length(Img) == frmPara.Nframe                
                break
            end
        end     
    end       
    
    % pause for required time period
    if ~pauseForFrame(h,frmPara)
        % if the user cancelled, then exit the function
        Img = [];
        return        
    end
end

% ensures the array is a column array
Img = Img(:);

% closes the waitbar figure
h.closeProgBar();

% --- pauses for the next frame (updates the waitbar figure)
function ok = pauseForFrame(h,frmPara)

% sets up the wait timer object
ok = true;
tUpdate = 0.05;
nUpdate = roundP(frmPara.wP/tUpdate);

% updates the progressbar for the required number of iterations
for i = 1:nUpdate
    tRemain = tUpdate*(nUpdate-i);
    wStrNw = sprintf('Waiting For New Frame (%.1fs Remains)',tRemain);
    if h.Update(2,wStrNw,i/nUpdate)
        ok = false;
        return
    else
        java.lang.Thread.sleep(tUpdate*1000)
    end
end
