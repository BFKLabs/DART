% --- sets the sub-region dimensions
function iMov = setSubRegionDim(iMov,hGUI)

% allocates memory for the movie struct
iMov.isSet = true;
[iMov.pos,iMov.iC,iMov.iR,iMov.iCT,iMov.iRT,iMov.xTube,...
            iMov.yTube,iMov.Status] = deal(cell(1,iMov.nRow*iMov.nCol));

% determines the current frame dimensions
frmSz = getCurrentImageDim(hGUI.figFlyTrack);
        
% retrieves the 
hSubW = findobj(hGUI.imgAxes,'tag','hInner');
if length(hSubW) == 1
    iSubW = get(hSubW,'UserData');
else
    iSubW = cell2mat(get(hSubW,'UserData'));
end

% sets the parameters for each of the sub-regions
for i = 1:length(iMov.iC)
    % sets the new index
    j = iSubW(i);
    nTube = getSRCount(iMov,j);
    
    % sets the location of the 
    hAPI = iptgetapi(hSubW(i)); 
    iMov.pos{j} = hAPI.getPosition();
    
    % sets the positional vector    
    Yrange = iMov.pos{j}(2)+[0 iMov.pos{j}(4)];
    Xrange = iMov.pos{j}(1)+[0 iMov.pos{j}(3)];
               
    % sets the row/column indices of the sub-image
    iMov.iR{j} = max(1,ceil(Yrange(1))):min(frmSz(1),floor(Yrange(2)));
    iMov.iC{j} = max(1,ceil(Xrange(1))):min(frmSz(2),floor(Xrange(2)));    
    iMov.Status{j} = zeros(nTube,1);
        
    % sets the locations of the tubes    
    yExt = Yrange(1) + (diff(Yrange)/nTube)*(0:nTube)';
    iMov.xTube{j} = Xrange - iMov.pos{j}(1);
    iMov.yTube{j} = [yExt(1:(end-1)) yExt(2:end)] - iMov.pos{j}(2);
    
    % sets the tube row/column indices
    iMov.iCT{j} = 1:length(iMov.iC{j});
    iMov.iRT{j} = cellfun(@(x)(max(1,ceil(x(1))):min(iMov.iR{j}(end),...
                floor(x(2)))),num2cell(iMov.yTube{j},2),'un',0);            
end