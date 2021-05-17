% --- performs a diagnostic check on the final solution 
function [pData,iMov,ok] = checkFinalSegSoln(obj)

% global variables
global wOfs
if isempty(wOfs); wOfs = 1; end

% object field retrieval
[handles,iData] = deal(obj.hGUI,obj.iData);
[pData,iMov,h] = deal(obj.pData,obj.iMov,obj.hProg);

% array dimensionsing and parameters
wStr = 'Final Segmentation Check';
[nApp,ok] = deal(length(pData.fPos),true);

% if there are no valid phases, then exit
if all(iMov.vPhase == 3)
    return
end

% loops through all the frames/sub-regions determining if there is an issue
for i = 1:nApp
    % updates the waitbar figure
    if ~isempty(h)
        wStrNw = sprintf('%s (Region %i of %i)',wStr,i,nApp);
        if h.Update(wOfs+1,wStrNw,i/nApp)
            % if the user cancelled, then exit the function
            ok = false; 
            return
        end
    end
    
    % only check if the apparatus is not rejected
    if iMov.ok(i)
        nTube = getSRCount(iMov,i);
        for j = 1:nTube
            % updates the waitbar figure
            if ~isempty(h)
                wStrNw = sprintf('%s (Sub-Region %i of %i)',wStr,j,nTube);
                h.Update(wOfs+2,wStrNw,j/nTube);
                h.Update(wOfs+3,'Inter-Frame Distance Check',0);
            end
            
            % only check if the sub-region is not rejected
            if iMov.flyok(j,i)
                % checks the location data for NaN frames 
                [iMov,pData] = frameNaNCheck(handles,iData,pData,iMov,i,j);
                                               
                % calculates inter-frame distance travelled by the object
                if iMov.Status{i}(j) == 1
                    [pData,ok] = ...
                        frameDistCheck(handles,iData,pData,iMov,i,j,h);
                else
                    [pData,ok] = ...
                        framePosCheck(obj,handles,iData,pData,iMov,i,j,h);                    
                end
                        
                % if the user cancelled, then exit
                if ~ok; return; end
            end
        end
    end
end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- checks the position data for any NaN frames
function [iMov,pData] = frameNaNCheck(handles,iData,pData,iMov,iApp,iTube)

% global variables
global Nsz

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
if (any(ii == 1))
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

%
function [pData,ok] = ...
                   framePosCheck(obj,handles,iData,pData,iMov,iApp,iTube,h)

% global variables
global wOfs

% parameters
mTol = 0.05;
hG = fspecial('gaussian',3,1);

% other initialistions
[wStr,ok,cont] = deal('Inter-Frame Distance Check',true,true);
[iR,iRT,iC] = deal(iMov.iR{iApp},iMov.iRT{iApp}{iTube},iMov.iC{iApp});
[X,Y] = deal(pData.fPosL{iApp}{iTube}(:,1),pData.fPosL{iApp}{iTube}(:,2));
[is2D,isOK] = deal(is2DCheck(iMov),true(length(X),1));
h0 = getMedBLSize(iMov);

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

% ensures the time vector is the same length as the position vector
fPosMn = [nanmedian(X),nanmedian(Y)];
if is2D
    dPos = sqrt((X-fPosMn(1)).^2 + (Y-fPosMn(2)).^2);
else
    dPos = abs(X-fPosMn(1));
end

%
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
        
    % calculates the 
    Img = double(getDispImage(iData,iMov,iFrm,false,handles));  
    ImgMd = removeImageMedianBL(Img,1,is2D,h0);

    ImgR = imfilter(ImgMd(iR(iRT),iC)-iMov.IbgT{iApp}(iRT,:),hG);    
    
    % calculates the like hidden object position
    [X(iFrm),Y(iFrm)] = calcHiddenObjPos(ImgR,fPosMn,dTol);
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

% --- checks the position data for any large jumps in location
function [pData,ok] = frameDistCheck(handles,iData,pData,iMov,iApp,iTube,h)

% global variables
global wOfs

% parameters and memory allocation
[wStr,ok] = deal('Inter-Frame Distance Check',true);
[is2D,cont] = deal(is2DCheck(iMov),true);
[X,Y] = deal(pData.fPosL{iApp}{iTube}(:,1),pData.fPosL{iApp}{iTube}(:,2));

% sets the tube row indices and the position offset
T = iData.Tv(roundP(1:iMov.sRate:length(iData.Tv)));
[iR,iC,iRT] = deal(iMov.iR{iApp},iMov.iC{iApp},iMov.iRT{iApp}{iTube});
iRL = iR(iRT);
FPS = nanmedian(1./diff(T));

% calculates the distance tolerance dependent on the tracking algorithm
if isfield(iMov,'xcP')
    % case is the svm tracking algorithm 
    dTol = 4*sqrt(1+is2D)*detApproxSize(iMov.xcP)/FPS;

elseif isfield(iMov,'szObj')
    if is2D
        dTol = 4*sqrt(2)*sqrt(prod(iMov.szObj))/FPS;        
    else
        dTol = 4*iMov.szObj(1)/FPS;
    end

else
    % case is the direct detection tracking algorithm
    if isColGroup(iMov)
        % case is column grouping
        dX = diff(iMov.iCT{iApp}{iTube}([1 end]));
        dY = diff(iMov.iRT{iApp}([1 end]));        
    else
        % case is row grouping
        dX = diff(iMov.iCT{iApp}([1 end]));
        dY = diff(iMov.iRT{iApp}{iTube}([1 end]));
    end

    % sets the overall distance tolerance
    dTol = (2/3)*sqrt(dX^2 + dY^2)/FPS;
end

% ensures the time vector is the same length as the position vector
if (length(T) > length(X)); T = T(1:length(X)); end

% retrieves the exclusion binary
% [isOK,iFrm0] = deal(true(length(T),1),-1);
[isOK,iFrm0,nFrm] = deal(~isnan(X),-1,length(T));
sz = [length(iRL),length(iMov.iC{iApp})];
hG = fspecial('gaussian',5,2);
Bw = usimage(double(getExclusionBin(iMov,sz,iApp,iTube)),sz);

% calculates the position offset
i0 = find(~isnan(X),1,'first');
pOfs = repmat(pData.fPos{iApp}{iTube}(i0,:)-[X(i0),Y(i0)],length(T),1);

% calculates the next-frame position estimates
[Xest,Yest] = deal(setupExtrapSig(X),setupExtrapSig(Y));

% keep looping while there are anomalous frames
while cont
    % calculates the estimated x-positions of the object
    dD = sqrt((X-Xest).^2 + (Y-Yest).^2);        
    
    % determines the first point where the discrepancy is outside tolerance
    iFrm = find((dD.*isOK) > dTol,1,'first');    
    if isempty(iFrm)
        % if there are no such points, then exit the loop
        cont = false;
        
    elseif (iFrm <= iFrm0) || (iFrm == 1)
        % if this is a repeat, then flag this frame
        isOK(iFrm) = false;
        
    else
        % updates the waitbar figure
        if ~isempty(h)
            wStrNw = sprintf('%s (Frame %i of %i)',wStr,iFrm,nFrm);
            if h.Update(wOfs+3,wStrNw,iFrm/nFrm)
                % if the user cancelled, then exit the function
                ok = false; 
                return
            end
        end              
        
        % 
        iPhase = find(iMov.iPhase(:,1)<=iFrm,1,'last');  
        if any(iMov.vPhase(iPhase) == [1,2])        
            % retrieves the global images for the surrounding frames   
            jFrm = iFrm + [-1,0];
            Img = arrayfun(@(x)(getDispImage...
                                (iData,iMov,x,0,handles)),jFrm,'un',0);            
            ImgL = cellfun(@(x)(double(x(iRL,iC))),Img,'un',0);

            % sets the    
            switch iMov.vPhase(iPhase)
                case 1
                    % calculates the residual image
                    IbgL = iMov.Ibg{iPhase}{iApp}(iRT,:);   
                    ImgR0 = cellfun(@(x)(imfilter(IbgL-x,hG)),ImgL,'un',0);
                    pR = iMov.pBG{iApp}(iTube);

                case 2
                    % uses the normalised images
                    pR = NaN;
                    ImgR0 = cellfun(@(x)(imfilter...
                                (1-normImg(x),hG)),ImgL,'un',0);
            end

            % determines if the next frame needs to be fixed         
            fixNext = compFrameRes(ImgR0,[X(jFrm),Y(jFrm)],pR);
            [ImgR,iFrmU] = deal(ImgR0{1+fixNext},jFrm(1+fixNext));
            isOK(iFrm) = false;
            
            % calculates the 
            if fixNext
                pEst = [Xest(iFrmU),Yest(iFrmU)];
            else
                pEst = [extrapSignalRev(X,iFrmU),extrapSignalRev(Y,iFrmU)];
            end
            
            % calculates the distance between the maxima & estimated points 
            iPmx = find(imregionalmax(ImgR).*Bw);
            [yPmx,xPmx] = ind2sub(sz,iPmx);
            Dest = pdist2(pEst,[xPmx,yPmx])';

            % determines the maxima which is most likely to be the closest 
            % to the estimated coordinates
            iMx = argMax(dTol*(ImgR(iPmx).^2)./(1+Dest));
            [X(iFrmU),Y(iFrmU)] = deal(xPmx(iMx),yPmx(iMx));

            % recalculates the estimated values
            [Xest,Yest] = deal(setupExtrapSig(X),setupExtrapSig(Y));
        end
    end
end

% updates the waitbar figure
h.Update(wOfs+3,sprintf('%s (100%% Complete)',wStr),1);

% updates the positions into the overall positonal data struct
pData.fPosL{iApp}{iTube} = [X,Y];
pData.fPos{iApp}{iTube} = pData.fPosL{iApp}{iTube} + pOfs;

% --- extrapolates the signal
function xExt = extrapSignalRev(x,iFrm)

% sets the interpolation array
nP = min(5,length(x)-(iFrm+1));
xP = flip(x((iFrm+1):(iFrm+nP)));

% calculates the extrapolated coordinates
if range(xP) == 0
    % if the range of the array is zero
    xExt = xP(1);
else
    % sets up the filter
    a = arburg(xP,length(xP)-1);    
    if any(isnan(a))
        % if there are any NaN coefficients, then return the mean locations
        xExt = nanmean(xP);
    else
        % otherwise, calculate the extrapolated signal value
        [~, zf] = filter(-[0 a(2:end)], 1, xP);
        xExt = filter([0 0], -a, 0, zf);
    end
end

% --- 
function fixNext = compFrameRes(ImgR,pFrm,pR)

%
prTol = 0.5;

%
iP = sub2ind(size(ImgR{1}),pFrm(:,2),pFrm(:,1));
ImgRP = max(0,cellfun(@(I,x)(I(x)-median(I(:))),ImgR(:),num2cell(iP(:))));

%
if isnan(pR)
    %
    fixNext = ImgRP(1)/ImgRP(2) > prTol;
else
    %
    isOK = ImgRP > pR;
    switch sum(isOK)
        case 0
            fixNext = ImgRP(1)/ImgRP(2) > prTol;
            
        case 1
            fixNext = isOK(1);
            
        case 2
            fixNext = true;
    end
end

% 
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
