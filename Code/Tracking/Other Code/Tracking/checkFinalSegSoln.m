% --- performs a diagnostic check on the final solution 
function [pData,iMov,ok] = checkFinalSegSoln(obj)

% global variables
global wOfs
if isempty(wOfs); wOfs = 1; end

% object field retrieval
[pData,iMov,h] = deal(obj.pData,obj.iMov,obj.hProg);

% if there are no valid phases, then exit
if all(iMov.vPhase == 3)
    return
end

% array dimensionsing and parameters
wStr = 'Final Segmentation Check';
[nApp,ok] = deal(length(obj.pData.fPos),true);

% calculates all the metric probabilities (over all regions/frames)
ZPos = calcAllMetricProb(obj);

% loops through all the frames/sub-regions determining if there is an issue
for i = find(iMov.ok(:)')
    % updates the waitbar figure
    if ~isempty(h)
        wStrNw = sprintf('%s (Region %i of %i)',wStr,i,nApp);
        if h.Update(wOfs+1,wStrNw,i/nApp)
            % if the user cancelled, then exit the function
            ok = false; 
            return
        end
    end
    
    nTube = getSRCount(iMov,i);
    for j = find(iMov.flyok(:,i)')
        if ~isempty(h)
            % updates the waitbar figure (if available)
            wStrNw = sprintf('%s (Sub-Region %i of %i)',wStr,j,nTube);
            h.Update(wOfs+2,wStrNw,j/nTube);
            h.Update(wOfs+3,'Inter-Frame Distance Check',0);
        end

        % checks the location data for NaN frames 
        ZPosSR = ZPos{i}(:,j);
        [iMov,pData] = frameNaNCheck(obj,iMov,pData,i,j);

        % calculates inter-frame distance travelled by the object
        if iMov.Status{i}(j) == 1
            [pData,ok] = frameDistCheck(obj,pData,iMov,ZPosSR,i,j);
        else
            [pData,ok] = framePosCheck(obj,pData,iMov,ZPosSR,i,j);                    
        end

        % if the user cancelled, then exit
        if ~ok; return; end
    end
end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- checks the position data for any NaN frames
function [iMov,pData] = frameNaNCheck(obj,iMov,pData,iApp,iTube)

% global variables
global Nsz

% field retrieval
[handles,iData] = deal(obj.hGUI,obj.iData);

% determines the frame count for the current video
[iTube0,iApp0] = find(iMov.flyok,1,'first');
[nFrm,NN] = deal(size(pData.fPos{iApp0}{iTube0},1),25);

% retrieves the position values of the object and
% dimensions of the subregion
fPosNw = pData.fPos{iApp}{iTube};
[iR,iRT,iC] = deal(iMov.iR{iApp},iMov.iRT{iApp}{iTube},iMov.iC{iApp});

% determines the nan frames
ii = double(any(isnan(fPosNw),2));
for i = find(iMov.vPhase >= 3)'
    % removes any high-variance or invalid phases
    ii(iMov.iPhase(i,1):iMov.iPhase(i,2)) = -1;
end

% determines all the NaN position values
if any(ii == 1)
    % determines the groupings of NaN values, and the
    % lengths of these groups
    if (all(ii == 1))
        % all positions are NaNs, so reject frame
        iMov.Status{iApp}(iTube) = 3;
    else        
        % calculates the x/y global offsets
        [jj,fPosLNw] = deal(find(ii==0,1,'first'),pData.fPosL{iApp}{iTube});
        xOfs = fPosNw(jj,1) - fPosLNw(jj,1);
        yOfs = fPosNw(jj,2) - fPosLNw(jj,2);
                
        % otherwise, determine the index groups where there are NaN values
        % and interpolate the points
        iGrp = getGroupIndex(ii == 1);
        for i = 1:length(iGrp)                                           
            % sets the new positions based on the missing location
            if (iGrp{i}(1) == 1)
                % grouping starts on the start frame, so set indices to be
                % that of the frame after the groups end
                fPosNw(iGrp{i},:) = repmat(fPosNw(iGrp{i}(end)+1,:),length(iGrp{i}),1);
            elseif (iGrp{i}(end) == nFrm)
                % grouping end on the end frame, so set indices to be
                % that of the frame preceding the groups start
                fPosNw(iGrp{i},:) = repmat(fPosNw(iGrp{i}(1)-1,:),length(iGrp{i}),1);
            else
                % otherwise, calculate the distance between the start/end
                % points of the group. if the distance is small, then
                % interpolate the locations between them
                if (length(iGrp{i}) == 1)
                    iX = iGrp{i}(1) + [-1;1];
                else
                    iX = iGrp{i}([1 end]) + [-1;1];
                end
                                    
                D = sqrt(sum(diff(fPosNw(iX,:),[],1).^2));
                if (D < 3*Nsz/2)
                    % if the distance between the start/end points is small
                    % then interpolate between the missing values
                    fPosNw(iGrp{i},1) = interp1(iX,fPosNw(iX,1),iGrp{i});
                    fPosNw(iGrp{i},2) = interp1(iX,fPosNw(iX,2),iGrp{i});
                else
                    % sets the local images for the groups
                    jGrp = [iX(1);iGrp{i};iX(2)];
                    IL = cell(length(jGrp),1);
                    
                    % retrieves the local images for each missing frame
                    for j = 1:ceil(length(IL)/NN)
                        % sets the indices for each of the missing frames
                        kk = (j-1)*NN + (1:NN);
                        kk = kk(kk <= length(IL));

                        % retrieves the local images for the current apparatus
                        Img = cellfun(@(x)(double(getDispImage(iData,...
                                iMov,x,false,handles))),num2cell(jGrp(kk)),'un',0);                
                        IL(kk) = cellfun(@(x)(x(iR(iRT),iC)),Img,'un',0);                    
                        clear Img;                                          
                    end      
                    
                    % loops through each of the missing frames calculating
                    % the location of the fly points
                    for j = 1:length(iGrp{i})
                        % calculates the residual and the maximum point
                        IR = (IL{end}-IL{j+1}).*((IL{end}-IL{j+1})>0) + ...
                             (IL{1}  -IL{j+1}).*((IL{1}  -IL{j+1})>0);
                        [~,imx] = max(IR(:));
                        
                        % sets the new position from the maximum residual
                        [ymx,xmx] = ind2sub(size(IR),imx);
                        fPosNw(iGrp{i}(j),:) = [xmx,ymx] + [xOfs,yOfs];                        
                    end
                end
            end
        end
        
        % resets the positions into the local/global position data array
        pData.fPos{iApp}{iTube} = fPosNw;              
        pData.fPosL{iApp}{iTube} = fPosNw - repmat([xOfs,yOfs],nFrm,1);
    end
end

% --- checks the position data for any large jumps in location
function [pData,ok] = frameDistCheck(obj,pData,iMov,ZPos,iApp,iTube)

% global variables
global wOfs

% parameters
dN = 3;
[zPrTol,zPrMin] = deal(0.02,0.1);

% field retrieval
[is2D,cont] = deal(is2DCheck(iMov),true);
[wStr,ok] = deal('Inter-Frame Distance Check',true);
[handles,iData,h] = deal(obj.hGUI,obj.iData,obj.hProg);
T = iData.Tv(roundP(1:iMov.sRate:length(iData.Tv)));

% sets the x/y coordinates
[X,Y] = deal(pData.fPosL{iApp}{iTube}(:,1),pData.fPosL{iApp}{iTube}(:,2));

% calculates the position offset
nFrm = length(X);

% determines if there are any low metric probability frames
isLowPr = ZPos < zPrTol;
if any(isLowPr) && ~is2D
    % if so, then determine if the tracking has been conducted properly
    
    % calculates the coordinate extent of the feasible frames    
    isOK = ZPos > zPrMin;
    dXTol = obj.iMov.szObj(1)/2;
    
    if any(isOK)
        xExt = [min(X(isOK)),max(X(isOK))];
        yExt = [min(Y(isOK)),max(Y(isOK))];    

        % for each low metric probability frame group, determine the side at
        % which the object "hides". reset the coordinates to that extent
        iGrp = getGroupIndex(isLowPr);
        for i = 1:length(iGrp)
            % determines the first feasible neighbouring index
            if iGrp{i}(1) == 1
                % case is the following point is feasible
                iPr = iGrp{i}(end)+1;
            else
                % case is the previous point is feasible
                iPr = iGrp{i}(1)-1;
            end

            % determines the side the surrounding point is closest to, and 
            dX = max(0,[X(iPr)-xExt(1),xExt(2)-X(iPr)]);
            iSide = argMin(dX);

            if dX(iSide) < dXTol
                [X(iGrp{i}),Y(iGrp{i})] = deal(xExt(iSide),mean(yExt));
            elseif (iGrp{i}(1) == 1) || (iGrp{i}(end) == nFrm)
                [X(iGrp{i}),Y(iGrp{i})] = deal(xExt(iSide),mean(yExt));
            else
                xiS = iGrp{i}([1,end]) + [-1,1];
                dXS = [(X(xiS)-xExt(1)),(xExt(2)-X(xiS))];

                if all(dXS(:) > dXTol)
                    % sets the interpolation index array
                    xi = [max(1,(iGrp{i}(1)-dN)):(iGrp{i}(1)-1),...
                         (iGrp{i}(end)+1):min(nFrm,(iGrp{i}(end)+dN))];
                    xi = xi(~isLowPr(xi) & ~isnan(X(xi)));

                    % interpolates the missing x/y coordinates
                    X(iGrp{i}) = roundP(interp1(xi,X(xi),iGrp{i},'pchip'));
                    Y(iGrp{i}) = roundP(interp1(xi,Y(xi),iGrp{i},'pchip')); 
                else
                    [X(iGrp{i}),Y(iGrp{i})] = deal(xExt(iSide),mean(yExt));
                end

                % updates the flags
                isLowPr(iGrp{i}) = false;
            end
        end
    else
        % if there is only low probability values, then is probably fixed
        % in location (see locations to be median of coordinates)
        [X(:),Y(:)] = deal(nanmedian(X),nanmedian(Y));
    end
end
 
% updates the waitbar figure
h.Update(wOfs+3,sprintf('%s (100%% Complete)',wStr),1);

% sets the local-to-global position offset
i0 = find(~isnan(X),1,'first');
pOfs = repmat(pData.fPos{iApp}{iTube}(i0,:)-[X(i0),Y(i0)],length(X),1);

% updates the positions into the overall positonal data struct
pData.fPosL{iApp}{iTube} = [X,Y];
pData.fPos{iApp}{iTube} = pData.fPosL{iApp}{iTube} + pOfs;

% --- checks the position data for static objects
function [pData,ok] = framePosCheck(obj,pData,iMov,ZPos,iApp,iTube)

% global variables
global wOfs

% field retrieval
[handles,iData,h] = deal(obj.hGUI,obj.iData,obj.hProg);

% other initialistions
mTol = 0.05;
[wStr,ok,cont] = deal('Inter-Frame Distance Check',true,true);
[iR,iRT,iC] = deal(iMov.iR{iApp},iMov.iRT{iApp}{iTube},iMov.iC{iApp});
[X,Y] = deal(pData.fPosL{iApp}{iTube}(:,1),pData.fPosL{iApp}{iTube}(:,2));
[is2D,isOK] = deal(is2DCheck(iMov),true(length(X),1));

% if all values are NaN's, then exit
if all(isnan(X))
    return
end

% determines the distance tolerances
if isfield(iMov,'szObj')
    if is2D
        dTol = sqrt(sum(iMov.szObj.^2))/2;   
    else
        dTol = iMov.szObj(1)/2;
    end        
end

% calculates the distance between the coordinates and the median point
fPosMn = [nanmedian(X),nanmedian(Y)];
if is2D
    dPos = sqrt((X-fPosMn(1)).^2 + (Y-fPosMn(2)).^2);
else
    dPos = abs(X-fPosMn(1));
end

% sets up the distance the masks
BD = bwdist(setGroup(roundP(fPosMn),[length(iRT),length(iC)])) <= dTol;

% if there are a large number of mistracked flies, then reset all of the
% coordinates to be the median location
if mean(dPos > dTol) > mTol
    [X(:),Y(:)] = deal(X(1),Y(1));
    cont = false;
end

% keep looping until all frames are within tolerance
while cont
    % determines if there are any frames outside of tolerance
    iFrm = find((dPos.*isOK) > dTol,1,'first');
    if isempty(iFrm)
        % if all frames are within tolerance, then exit the loop
        break
    end
    
    % updates the waitbar figure (if provided)
    if ~isempty(h)
        pW = iFrm/length(X);           
        wStrNw = sprintf('%s (%i%% Complete)',wStr,floor(100*pW));
        if h.Update(wOfs+3,wStrNw,pW)
            % if the user cancelled, then exit
            ok = false; 
            return
        end
    end  
        
    % retrieves the image for the frame
    Img = double(getDispImage(iData,iMov,iFrm,false,handles)); 
    if ~isempty(obj.hS); Img = imfilter(Img,obj.hS); end

    % calculates the residual image
    ImgL = Img(iR(iRT),iC);
    IxcL = calcXCorrStack(obj.iMov,ImgL,obj.hS).*(1-normImg(ImgL)).*BD;       
    
    % calculates the new coordinates
    pNw = getMaxCoord(IxcL);
    [X(iFrm),Y(iFrm)] = deal(pNw(1),pNw(2));
    isOK(iFrm) = false;
end

% updates the waitbar figure
h.Update(wOfs+3,sprintf('%s (100%% Complete)',wStr),1);

% calculates the position offset
i0 = find(~isnan(X),1,'first');
pOfs = repmat(pData.fPos{iApp}{iTube}(i0,:)-[X(i0),Y(i0)],length(X),1);

% updates the positions into the overall positonal data struct
pData.fPosL{iApp}{iTube} = [X,Y];
pData.fPos{iApp}{iTube} = pData.fPosL{iApp}{iTube} + pOfs;

% --------------------------------------- %
% --- METRIC PROBABILITY CALCULATIONS --- %
% --------------------------------------- %

% --- calculates the cross-correlation images for the image stack, Img
function Ixc = calcXCorrStack(iMov,Img,hS)

% memory allocation
tP = iMov.tPara;

% calculates the original cross-correlation image
[Gx,Gy] = imgradientxy(Img);
Ixc0 = max(0,calcXCorr(tP.GxT,Gx) + calcXCorr(tP.GyT,Gy));

% calculates the final x-correlation mask
if isempty(hS)
    Ixc = Ixc0/2;
else
    Ixc = imfilter(Ixc0,hS)/2;
end

% --- calculates the metric probabilities over all frames
function ZPos = calcAllMetricProb(obj)

% memory allocation
nFrm = size(obj.pData.fPos{1}{1},1);
IPos = cell2cell(obj.pData.IPos)';
ZPos = arrayfun(@(n)(NaN(nFrm,n)),obj.nTube(:)','un',0);

% loops through each phase calculating the metric probabilities
for i = 1:obj.nPhase
    % sets the frame indices
    setValues = true;
    indF = obj.iMov.iPhase(i,1):obj.iMov.iPhase(i,2);
    
    % groups the data values
    switch obj.iMov.vPhase(i)
        case 1
            % case is a low-variance phase
            iStat = obj.iMov.StatusF{i};
            [isStat,isMove] = deal(iStat==2,iStat==1);
            
            % calculates the metrics for the 
            ZPosNw = cell(size(IPos));
            ZPosNw(isMove) = calcGroupMetricProb(IPos(isMove),indF);            
            ZPosNw(isStat) = calcGroupMetricProb(IPos(isStat),indF);
            
        case 2
            % case is a high-variance phase
            ZPosNw = calcGroupMetricProb(IPos,indF);
            
        otherwise
            % case is an untrackable phase type
            setValues = false;
            
    end
    
    % updates the values within the final array if low/high variance phase
    if setValues
        for j = 1:size(IPos,1)
            for k = 1:size(IPos,2)
                ZPos{k}(indF,j) = ZPosNw{j,k};
            end
        end 
    end
end

% --- calculates the metric for a given group
function ZPos = calcGroupMetricProb(IPos,indF)

% calculates the mean/std deviation of the group metric values
IPosT = cell2mat(cellfun(@(x)(x(indF,1)),IPos,'un',0));
[pMu,pSD] = deal(nanmean(IPosT(:)),nanstd(IPosT(:)));

% calculates the normal cdf values
ZPos = cellfun(@(x)(normcdf(x(indF,1),pMu,pSD)),IPos,'un',0);

% ----------------------- %
% --- OTHER FUNCTIONS --- %
% ----------------------- %

% --- calculates the signal CWT
function Pcwt = calcSignalCWT(X)

% sets the row summation indices
iR = 1:15;

% calculates the cwt and sums the power spectrums for the high-freq rows
Y = cwt(X-mean(X));
Pcwt = nanmean(abs(Y(iR,:)),1);

% --- sets up the extrapolation signal
function y = setupExtrapSig(x,nPts)

% number of points for which to extrapolate
if ~exist('nPts','var'); nPts = 4; end

% memory allocation
if range(x) == 0
    y = x; 
    return    
end
    
% memory allocation
nFrm = length(x);
y = NaN(nFrm,1);
isN = isnan(x);

% fill in the known part of the time series
ii = 1:nPts;
y(ii) = x(ii);

% Run the initial timeseries through the filter to get the filter state
for i = 1:(length(x)-nPts)       
    % Now use the filter as an IIR to extrapolate
    xNw = x(ii+(i-1));
    if range(xNw) == 0
        y(i+nPts) = xNw(1);
    else       
        jj = ~isN(ii+(i-1));
        switch sum(jj)
            case 0
                
            case 1
                y(i+nPts) = xNw(end);
                
            otherwise                
                a = arburg(xNw(jj),sum(jj)-1);            
                if any(isnan(a))
                    y(i+nPts) = mean(xNw(jj));
                else
                    [~, zf] = filter(-[0 a(2:end)], 1, xNw(jj));  
                    y(i+nPts) = filter([0 0], -a, 0, zf);
                end
        end
    end
end
