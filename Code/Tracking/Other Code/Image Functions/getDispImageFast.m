% --- retrieves the image to be displayed on the main image axes ----------
function Img = getDispImageFast(hFig,iFrmL,isSub)

% field retrieval
iFrmT = iFrmL(1):iFrmL(2);

% retrieves the RGB flag
if isfield(hFig.iMov,'useRGB')
    useRGB = hFig.iMov.useRGB;
else
    useRGB = true;
end

% resets the video object current time (if not matching)
t0 = iFrmT(1)/hFig.mObj.FrameRate;
if hFig.mObj.CurrentTime ~= t0
    hFig.mObj.CurrentTime = t0;
end

% reads all the frames from the image stack
for iFrmR = (iFrmT(1)+1):iFrmT(end)
    try
        % reads the next frame
        Img0 = readFrame(hFig.mObj,'native');    
    
    catch
        % if there was an error, then return an 
        Img = [];
        return
    end        
end

% converts the image (if required)
if useRGB
    Img = getRotatedImage(hFig.iMov,Img0);
else
    Img = getRotatedImage(hFig.iMov,rgb2gray(Img0));
end

% sets the image with the sub-image coordinates (if sub-image selected)
if isSub 
    Img = setSubImage(guidata(hFig),Img);
end