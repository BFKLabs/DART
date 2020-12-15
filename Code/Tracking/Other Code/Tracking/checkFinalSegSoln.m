% --- performs a diagnostic check on the final solution 
function [pData,iMov,ok] = checkFinalSegSoln(handles,iData,pData,iMov,h)

% global variables
global wOfs
if isempty(wOfs); wOfs = 1; end

% array dimensionsing and parameters
wStr = 'Final Segmentation Check';
[nApp,ok] = deal(length(pData.fPos),true);

% loops through all the frames/sub-regions determining if there is an issue
for i = 1:nApp
    % updates the waitbar figure
    if ~isempty(h)
        wStrNw = sprintf('%s (Apparatus %i of %i)',wStr,i,nApp);
        if h.Update(wOfs+1,wStrNw,i/nApp)
            ok = false; return;
        end
    end
    
    % only check if the apparatus is not rejected
    if iMov.ok(i)
        nTube = max(getFlyCount(iMov,1));
        for j = 1:nTube
            % updates the waitbar figure
            if ~isempty(h)
                wStrNw = sprintf('%s (Sub-Region %i of %i)',wStr,j,nTube);
                h.Update(wOfs+2,wStrNw,j/nTube);
                h.Update(wOfs+3,'Inter-Frame Distance Check',0);
            end
            
            % only check if the sub-region is not rejected
            if (iMov.flyok(j,i) && (iMov.Status{i}(j) == 1))
                % checks the location data for NaN frames 
                [iMov,pData] = frameNaNCheck(handles,iData,pData,iMov,i,j);
                                               
                % calculates inter-frame distance travelled by the object
                [pData,ok] = frameDistCheck(handles,iData,pData,iMov,i,j,h);
                if (~ok); return; end
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

% --- checks the position data for any large jumps in location
function [pData,ok] = frameDistCheck(handles,iData,pData,iMov,iApp,iTube,h)

% global variables
global wOfs

% parameters and memory allocation
[wStr,ok] = deal('Inter-Frame Distance Check',true);
[is2D,cont,FPS] = deal(is2DCheck(iMov),true,iData.exP.FPS/iMov.sRate);
[X,Y] = deal(pData.fPosL{iApp}{iTube}(:,1),pData.fPosL{iApp}{iTube}(:,2));

% calculates the distance tolerance dependent on the tracking algorithm
if (isfield(iMov,'xcP'))
    % case is the svm tracking algorithm 
    dTol = 4*sqrt(1+is2D)*detApproxSize(iMov.xcP)/FPS;
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
    
    %
    dTol = (2/3)*sqrt(dX^2 + dY^2)/FPS;
end

% sets the tube row indices and the position offset
T = iData.Tv(roundP(1:iMov.sRate:length(iData.Tv)));
[iR,iRT,iC] = deal(iMov.iR{iApp},iMov.iRT{iApp}{iTube},iMov.iC{iApp});

% ensures the time vector is the same length as the position vector
if (length(T) > length(X)); T = T(1:length(X)); end

% retrieves the exclusion binary
% [isOK,iFrm0] = deal(true(length(T),1),-1);
[isOK,iFrm0] = deal(~isnan(X),-1);
sz = [length(iRT),length(iMov.iC{iApp})];
Bw = usimage(double(getExclusionBin(iMov,sz,iApp,iTube)),sz);

% calculates the position offset
i0 = find(~isnan(X),1,'first');
pOfs = repmat(pData.fPos{iApp}{iTube}(i0,:)-[X(i0),Y(i0)],length(T),1);

% keep looping while there are anomalous frames
while (cont)
    % calculates the estimated x-positions of the object
    dD = abs(X-calcPosEstimate(T,X));    
    
    % calculates the estimated y-positions of the object (2D only)
    if (is2D)        
        dD = max([dD,abs(Y-calcPosEstimate(T,Y))],[],2); 
    end
    
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
            pW = iFrm/length(T);           
            wStrNw = sprintf('%s (%i%% Complete)',wStr,floor(100*pW));
            if h.Update(wOfs+3,wStrNw,pW)
                ok = false; return
            end
        end              
        
        % retrieves the global images for the surrounding frames        
        [jFrm,iFrm0] = deal(iFrm+(0:2)',iFrm); 
        jFrm = jFrm((jFrm>1)&(jFrm<=length(X)));        
        Img = cellfun(@(x)(double(getDispImage(iData,iMov,x,false,...
                            handles))),num2cell(jFrm),'un',0);  
        ImgL = cellfun(@(x)(x(iR(iRT),iC)),Img,'un',0);
                        
        % sets the background image
        updatePos = true;
        iPhase = find(iMov.iPhase(:,1)<=iFrm,1,'last');
        switch (iMov.vPhase(iPhase))
            case (1)
                % sets the background image
                IbgL = iMov.Ibg{iPhase}{iApp}(iRT,:);   

                % sets the local image for the tube region             
                szL = size(IbgL);
                Dp = sqrt(createPointDistMask([X(iFrm-1),Y(iFrm-1)],szL));
                IRL = cellfun(@(x)(Bw.*(IbgL-x)./(Dp+1)),ImgL,'un',0);

            case (6)
                % image size
                sz = size(ImgL{1});

                % sets up the new local search images
                ImgBL = createFilterImagesDD(ImgL,Bw,iMov.bgP);
                Dp = sqrt(createPointDistMask([X(iFrm-1),Y(iFrm-1)],sz));
                IRL = cellfun(@(x)(Bw.*x./(Dp+1)),ImgBL,'un',0);
                
            otherwise 
                updatePos = false;
        end
        
        % recalculates the object locations
        if updatePos
            for i = 1:length(jFrm)
                % sets the search x/y position offset
                Pmx = calcMaxValueLocation(IRL{i});        
                [X(jFrm(i)),Y(jFrm(i))] = deal(Pmx(1),Pmx(2));
            end         
        end
    end
end

% updates the waitbar figure
h.Update(wOfs+3,sprintf('%s (100%% Complete)',wStr),1);

% updates the positions into the overall positonal data struct
pData.fPosL{iApp}{iTube} = [X,Y];
pData.fPos{iApp}{iTube} = pData.fPosL{iApp}{iTube} + pOfs;

% --- calculates the estimate of the positions
function XC = calcPosEstimate(T,X)

% turns off the warnings
wState = warning('off','all');

% calculates the gradients
T = reshape(T,size(X));
[Th,dT] = deal(0.5*(T(1:end-1)+T(2:end)),T(2:end)-T(1:end-1));
dpp = pchip(T,gradient(X,T));

% calculates the derivatives
[f1,f2,f3] = deal(ppval(dpp,T(1:end-1)),ppval(dpp,Th),ppval(dpp,T(2:end)));

% calculates the estimated positions
XC = [X(1);(X(1:end-1) + (dT/6).*(f1 + 4*f2 + f3))];

% turns on the warnings again
warning(wState);
