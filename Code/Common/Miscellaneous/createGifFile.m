function createGifFile(fName,iData,iMov,iFrm,tDelay)

% sets the default input argument
if ~exist('tDelay','var'); tDelay = 0.5; end

% initialisations
nFrm = length(iFrm);
wStr = 'Writing Gif File';
h = waitbar(0,wStr);

% creates the gif file
for i = 1:nFrm
    % updates the waitbar
    waitbar(i/length(iFrm),h,sprintf('%s (%i of %i)',wStr,i,nFrm));
    
    % reads the new image
    Img = getDispImage(iData,iMov,iFrm(i),0);
    [A,map] = rgb2ind(repmat(Img,[1,1,3]),256);
    
    % appends the image to the gif object
    if i == 1
        imwrite(A,map,fName,'gif','LoopCount',Inf,'DelayTime',tDelay);
    else
        imwrite(A,map,fName,'gif','WriteMode','append','DelayTime',tDelay);
    end
end

% closes the waitbar 
close(h)