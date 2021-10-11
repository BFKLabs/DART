% --- sets the sub-region dimensions
function iMov = setSubRegionDim(iMov,hGUI)

% global variables
global useAuto

% allocates memory for the movie struct
iMov.isSet = true;
[iMov.pos,iMov.iC,iMov.iR,iMov.iCT,iMov.iRT,iMov.xTube,...
            iMov.yTube,iMov.Status] = deal(cell(1,iMov.nRow*iMov.nCol));

% determines the current frame dimensions
is2DSetup = iMov.is2D;
frmSz = getCurrentImageDim(hGUI.figFlyTrack);
        
% retrieves the 
hSubW = findobj(hGUI.imgAxes,'tag','hInner');
iSubW = cell2mat(arrayfun(@(x)(get(x,'UserData')),hSubW,'un',0));

% 
if is2DSetup
    % --------------------------- %
    % --- 2D EXPERIMENT SETUP --- %
    % --------------------------- %
    
    % sorts the group handles 
    [iSubW,iS] = sortrows(iSubW);
    hSubW = hSubW(iS);
    
    %
    hAPI = arrayfun(@(x)(iptgetapi(x)),hSubW,'un',0);
    pPos0 = cellfun(@(x)(x.getPosition()),hAPI,'un',0);
    pPos = cell(1,length(iMov.iC));
    
    % sets the parameters for each of the sub-regions
    for j = 1:length(iMov.iC)
        % sets the new index
        ii = iSubW(:,1) == j;
        nTube = getSRCount(iMov,j);
        pPos{j} = pPos0(ii);
        
        % sets up the region position vector
        pPosT = cell2mat(pPos{j});
        [X0,Y0] = deal(min(pPosT(:,1)),min(pPosT(:,2)));
        Wmx = max((pPosT(:,1)-X0)+pPosT(:,3));
        Hmx = max((pPosT(:,2)-Y0)+pPosT(:,4));        
        iMov.pos{j} = [X0,Y0,Wmx,Hmx];
        
        % sets the positional vector    
        Yrange = iMov.pos{j}(2)+[0 iMov.pos{j}(4)];
        Xrange = iMov.pos{j}(1)+[0 iMov.pos{j}(3)]; 
        yExt = cell2mat(cellfun(@(x)(x(2)+[0,x(4)]),pPos{j},'un',0));
        
        % sets the row/column indices of the sub-image
        iMov.iR{j} = max(1,ceil(Yrange(1))):min(frmSz(1),floor(Yrange(2)));
        iMov.iC{j} = max(1,ceil(Xrange(1))):min(frmSz(2),floor(Xrange(2)));    
        iMov.Status{j} = zeros(nTube,1);   
        
        % sets the locations of the tubes    
        iMov.xTube{j} = Xrange - iMov.pos{j}(1);
        iMov.yTube{j} = yExt - iMov.pos{j}(2);        
        
        % sets the tube row/column indices
        iMov.iCT{j} = 1:length(iMov.iC{j});
        iMov.iRT{j} = cellfun(@(x)(max(1,ceil(x(1))):min(iMov.iR{j}(end),...
                    floor(x(2)))),num2cell(iMov.yTube{j},2),'un',0); 
                
    end
    
    % sets up the region parameters
    if ~useAuto        
        iMov.autoP = setupAutoDetectPara(iMov,cell2cell(pPos,0));   
    end  
    
    % updates the region maps
    if isfield(iMov,'srData')
        if ~isempty(iMov.srData)
            iMov = createRegionIndexMap(iMov);
        end
    end
    
else
    % --------------------------- %
    % --- 1D EXPERIMENT SETUP --- %
    % --------------------------- %

    % sets the parameters for each of the sub-regions
    for i = 1:length(iMov.iC)
        % sets the new index
        j = iSubW(i);
        nTube = getSRCount(iMov,j);

        % sets the location of the 
        hAPI = iptgetapi(hSubW(j)); 
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
end
    
