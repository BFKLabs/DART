% --- sets the sub-region dimensions
function [iMov,ok] = setSubRegionDim(iMov,hGUI)

% global variables
global useAuto

% allocates memory for the movie struct
ok = true;
[iMov.pos,iMov.iC,iMov.iR,iMov.iCT,iMov.iRT,iMov.xTube,...
            iMov.yTube,iMov.Status] = deal(cell(1,iMov.nRow*iMov.nCol));

% sets the 2D region flag
if ~isfield(iMov,'is2D')
    [is2DSetup,iMov.is2D] = deal(is2DCheck(iMov));
else
    is2DSetup = iMov.is2D;
end
        
% determines the current frame dimensions
frmSz = getCurrentImageDim(hGUI.figFlyTrack);
        
% retrieves the indices of the region objects
hSubW = findobj(hGUI.imgAxes,'tag','hInner');
iSubW = cell2mat(arrayfun(@(x)(get(x,'UserData')),hSubW,'un',0));

% if there are no sub-region data, then exit the function
if isempty(iSubW)
    % if there was an issue, then output an error to screen
    eStr = ['The region configuration will need to be reset before ',...
            'attempting automatic grid detection.'];
    waitfor(msgbox(eStr,'Reset Region Configuration','modal'))
    
    
    % exits the function with an empty struct
    ok = false;
    return
end

% creates the sub-regions based on the experiment assay type
if is2DSetup || detMltTrkStatus(iMov)
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
        Yr = iMov.pos{j}(2)+[0 iMov.pos{j}(4)];
        Xr = iMov.pos{j}(1)+[0 iMov.pos{j}(3)]; 
        yExt = cell2mat(cellfun(@(x)(x(2)+[0,x(4)]),pPos{j},'un',0));
        
        % sets the row/column indices of the sub-image
        iMov.iR{j} = max(1,ceil(Yr(1))):min(frmSz(1),floor(Yr(2)));
        iMov.iC{j} = max(1,ceil(Xr(1))):min(frmSz(2),floor(Xr(2)));    
        iMov.Status{j} = zeros(nTube,1);   
        
        % sets the locations of the tubes    
        iMov.xTube{j} = Xr - iMov.pos{j}(1);
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
    for i = 1:length(iSubW)
        % sets the new index
        j = iSubW(i);
        if iMov.ok(j)
            nTube = getSRCount(iMov,j);

            % sets the location of the 
            hAPI = iptgetapi(hSubW(i)); 
            iMov.pos{j} = hAPI.getPosition();

            % sets the positional vector    
            Yr = iMov.pos{j}(2)+[0 iMov.pos{j}(4)];
            Xr = iMov.pos{j}(1)+[0 iMov.pos{j}(3)];

            % sets the row/column indices of the sub-image
            iMov.iR{j} = max(1,ceil(Yr(1))):min(frmSz(1),floor(Yr(2)));
            iMov.iC{j} = max(1,ceil(Xr(1))):min(frmSz(2),floor(Xr(2)));    
            iMov.Status{j} = zeros(nTube,1);

            % sets the locations of the tubes    
            yExt = Yr(1) + (diff(Yr)/nTube)*(0:nTube)';
            iMov.xTube{j} = Xr - iMov.pos{j}(1);
            iMov.yTube{j} = [yExt(1:(end-1)) yExt(2:end)] - iMov.pos{j}(2);

            % sets the tube row/column indices
            iMov.iCT{j} = 1:length(iMov.iC{j});
            iMov.iRT{j} = cellfun(@(x)(max(1,ceil(x(1))):...
                        min(iMov.iR{j}(end),floor(x(2)))),...
                        num2cell(iMov.yTube{j},2),'un',0);            
        end
    
    end    
end

% reduces downs the filter/reference images (if they exist)
if isfield(iMov,'phInfo')
    if ~isempty(iMov.phInfo)
        for j = find(iMov.ok(:)')
            if ~isempty(iMov.phInfo.Iref{j})
                iMov = reducePhaseInfoImages(iMov,j);
            end
        end
    end
end

% updates the region set flag
iMov.isSet = true;