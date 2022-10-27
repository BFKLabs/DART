% --- testing the seizure analysis function 
function [indF,Pmet] = detLikelySeizureEvents(snTot,h)

% initialisations
nApp = length(snTot.Px);
nLen = cumsum(cellfun(@length,snTot.T));
ind = [[1;nLen(1:end-1)+1],nLen];
indS = cellfun(@(x)(x(1):x(2)),num2cell(ind,2),'un',0);
[sFac,iMov] = deal(snTot.sgP.sFac,snTot.iMov);

% memory allocation
[nFile,nFly] = deal(size(ind,1),getSRCount(iMov));
[dPx,dPy,Phi] = deal(cell(nFile,1));
[indF,Pmet] = deal(cell(nFile,max(nFly),nApp));

% creates a waitbar figure (if not provided)
if nargin == 1
    wStr = {'Sub-Region Analysis','Fly Analysis',...
            'Seizure Metric Calculations'};
    h = ProgBar(wStr,'Detecting Seizure Events'); 
end

% calculates the seizure event metrics for each fly over the experiment
for iApp = 1:nApp  
    % updates the waitbar figure
    wStrNw = sprintf('%s (%i of %i)',h.wStr{1},iApp,nApp);
    if h.Update(1,wStrNw,iApp/nApp)
        % if the user cancelled, then exit the function
        [indF,Pmet] = deal([]);
        return
    end
    
    % only analyse if the sub-region has not been rejected
    if iMov.ok(iApp)
        % retrieves the 2D coordinates
        [DPX,DPY,~,IND,dp0] = get2DCoords(snTot,iApp); 
        [X0,Y0] = getCircCentreCoords(iMov);
    
        % sets the values into the final array
        for iFly = 1:nFly(iApp)
            % updates the waitbar figure
            wStrNw = sprintf('%s (%i of %i)',h.wStr{2},iFly,nFly(iApp));
            if h.Update(2,wStrNw,iFly/nFly(iApp))
                % if the user cancelled, then exit the function
                [indF,Pmet] = deal([]);
                return
            end
            
            % only analyse if the fly has not been rejected
            if iMov.flyok(iFly,iApp)                                
                % calculates the x/y coordinates in the global coordinates
                k = IND{1}(iFly);
                x0 = X0(k) + dp0{1}(1,iFly);
                y0 = Y0(k) + dp0{1}(2,iFly);

                % sets the files x/y coordinates and orientation angles 
                for iFile = 1:nFile                        
                    dPx{iFile} = DPX{1}(indS{iFile},iFly);
                    dPy{iFile} = DPY{1}(indS{iFile},iFly);
                    Phi{iFile} = snTot.Phi{iApp}(indS{iFile},iFly);
                end

                % determines the rejected binary regions
                [Brej,X,Y] = detRejectedRegions(...
                                    iMov,iFly,iApp,k,dPx,dPy,Phi,x0,y0);          

                % calculates the event metrics for each video
                for iFile = 1:nFile
                    % updates the waitbar figure
                    wStrNw = sprintf('%s (Video %i of %i)',...
                                                h.wStr{3},iFile,nFile);
                    if h.Update(3,wStrNw,iFile/nFile)
                        % if the user cancelled, then exit the function
                        [indF,Pmet] = deal([]);
                        return
                    end
                                
                    % calculates the event metrics for the current video
                    [indF{iFile,iFly,iApp},Pmet{iFile,iFly,iApp}] = ...
                                calcEventMetrics(X{iFile},Y{iFile},...
                                                 Phi{iFile},Brej,sFac); 
                end
            end            
        end
    end
end

% updates and closes the waitbar figure (if still open)
if ~h.Update(3,'Analysis Complete!',1)
    if nargin == 1; h.closeProgBar(); end
end

% %
% [xSVM,Axls] = deal(cell(nFly,nApp,iFile),cell(nFile,1)); 
% for iFile = 1:nFile
%     for iApp = 1:size(xSVM,2)
%         for iFly = 1:size(xSVM,1); 
%             if (~isempty(Pmet{iFile,iFly,iApp}))
%                 xSVM{iFly,iApp,iFile} = num2cell([indF{iFile,iFly,iApp},...
%                                                   Pmet{iFile,iFly,iApp}]); 
%             end
% 
%             Axls{iFile} = combineCellArrays(...
%                     combineCellArrays(Axls{iFile},xSVM{iFly,iApp,iFile}),{NaN});
%         end
%     end
%     
%     ii = find(cellfun(@isnumeric,Axls{iFile})); 
%     Axls{iFile}(ii(cellfun(@(x)(isnan(x(1))),Axls{iFile}(ii)))) = {[]};    
% end   

% ------------------------------------------- %
% --- REJECTED REGION BINARY CALCULATIONS --- %
% ------------------------------------------- %
       
% --- determines the overall rejected binary regions
function [Brej,XX0,YY0] = detRejectedRegions(...
                                iMov,iFly,iApp,indG,X,Y,Phi,xOfs,yOfs)

% parameters
[d2r,Npre,Npost] = deal(pi/180,5,10);
[pTol,Rtol,GrpSzTol] = deal(0.2,0.5,5);

% memory allocation and other initialisations
[iRT,nFile] = deal(iMov.iRT{iApp}{iFly},length(X));
[xPaccP,yPaccP,Rmx,Pmx] = deal(cell(nFile,1));

% sets the x/y offsets
[y0,x0] = deal(iMov.iR{iApp}(iRT(1))-1,iMov.iC{iApp}(1)-1);
XX0 = cellfun(@(x)(roundP(x+xOfs-x0)),X,'un',0);
YY0 = cellfun(@(x)(roundP(x+yOfs-y0)),Y,'un',0);

% retrieves the exclusion binary mask
Bw = logical(getExclusionBin(iMov,[],iApp,iFly)); 
sz = size(Bw);

% calculates the distance/orientation masks
[X0G,Y0G] = getCircCentreCoords(iMov);
[xM,yM] = deal(X0G(indG)-x0,Y0G(indG)-y0);
[XX,YY] = meshgrid((1:size(Bw,2))-xM,(1:size(Bw,1))-yM);

% sets the region 
PhiR = mod(atan2(YY,XX)/d2r,90);
PhiR(PhiR > 45) = 90 - PhiR(PhiR > 45);

% sets the rejection binary mask
D = sqrt(XX.^2+YY.^2); D = D/max(D(Bw));
Brej = detCenterRejectedRegions(iMov.Ibg{1}{iApp}(iRT,:),D);

% calculates the metrics for the acceleration peaks (for each file)
Pdd = cell(nFile,1);
for i = 1:nFile
    %
    [xS,yS] = deal(smooth(X{i}),smooth(Y{i})); 
    dD = sqrt((X{i}-xS).^2 + (Y{i}-yS).^2);         
    Pdd{i} = calcAccPowerSpec(dD);    
    
    % determines the peaks from the 
    isRej = ~Brej(sub2ind(size(Brej),YY0{i},XX0{i})).^2;
    PddR = Pdd{i}(:).*isRej(1:end-1);    
    [yDD,iDD] = findpeaks(PddR);     
    
    % calculates the outlier
    [jj,nFrm] = deal(yDD > pTol,length(X{i}));   
    
    % calculate
    if (any(jj))
        % reduces the arrays
        [iDD,yDD] = deal(iDD(jj),yDD(jj));
        
        % removes any points adjacent to a rejected region
        kk = isRej(iDD-1) & isRej(iDD+1);        
        if (any(kk))
            % if there are still points, reduce the arrays
            [iDD,yDD] = deal(iDD(kk),yDD(kk));            
            Pmx{i} = [iDD,yDD,dD(iDD)];
            
            % retrieves the x/y and angles for the points surrounding the
            % power signal peaks
            indP = cellfun(@(j)(max(1,j-Npre):min(nFrm,j+Npost)),num2cell(iDD),'un',0);
            xPaccP{i} = cellfun(@(j)(X{i}(j)+xOfs-x0),indP,'un',0);
            yPaccP{i} = cellfun(@(j)(Y{i}(j)+yOfs-y0),indP,'un',0);
            pPhiP = cellfun(@(j)(Phi{i}(j)),indP,'un',0);            
            
            %
            Rtmp = cell2mat(cellfun(@(x,y,p)(calcSidewaysMovement(x,y,p)),...
                                xPaccP{i},yPaccP{i},pPhiP,'un',0));
            Rmx{i} = Rtmp(:,1);
        end
    end         
end

% calculates the interpolated coordinates for the peak indices
jj = ~cellfun(@isempty,xPaccP);
aa = cellfun(@(xx,yy,rr)(cellfun(@(x,y,r)(...
        interpCoordPath(x,y,sz,r)),xx,yy,num2cell(rr),'un',0)),...
        xPaccP(jj),yPaccP(jj),Rmx(jj),'un',0);
     
% sets up the positional heatmap   
yy = cell2mat(cellfun(@(x,z)(x(1:length(z))),YY0,Pdd,'un',0)); 
xx = cell2mat(cellfun(@(x,z)(x(1:length(z))),XX0,Pdd,'un',0)); 
indF = sub2ind(sz,yy,xx);
Ihm = reshape(hist(indF(:),1:prod(sz)),sz);

% sets the binary mask of the regions likely to contain the holes
DR = sqrt(XX.^2+YY.^2); 
DR = DR/max(DR(Bw));
BR = ((abs(PhiR) < 20) & (DR > 0.50) & (DR < 0.90));

%
bb = cell2mat(cellfun(@(x)(cell2mat(x)),aa,'un',0));
if (~isempty(bb))
    [IhmA,IhmR] = deal(reshape(hist(bb(:,1),1:prod(sz)),sz),NaN(sz));
    for i = 1:size(bb,1)
        if (isnan(IhmR(bb(i,1))))
            IhmR(bb(i,1)) = bb(i,2); 
        else
            IhmR(bb(i,1)) = max(IhmR(bb(i,1)),bb(i,2)); 
        end        
    end
else
    [IhmA,IhmR] = deal(zeros(sz));
end

%
[Ihm0,Bhole] = deal(bwmorph(Ihm==0,'open'),false(sz));
Bgrp0 = BR.*bwmorph(IhmA.*Ihm0>0,'close');

%
BRR = cellfun(@(x)(setGroup(x,sz)),getGroupIndex(BR),'un',0);
for i = 1:length(BRR)
    % determines the 
    iGrpR = getGroupIndex(BRR{i}.*Bgrp0);
    iGrpR = iGrpR(cellfun(@length,iGrpR) >= GrpSzTol);
    
    if (~isempty(iGrpR))
        % determines the group counts/R values from each group
        Ngrp = cellfun(@(x)(max(IhmA(x))),iGrpR);
        Rgrp = cellfun(@(x)(max(IhmR(x))),iGrpR);
                
        %
        [iN,iR] = deal(Ngrp > 1,Rgrp < Rtol);
        switch (sum(iN | iR))
            case (0)
            case (1)
                Bhole(iGrpR{1}) = true;
            otherwise
                if (any(iN & iR))
                    Bhole(cell2mat(iGrpR(iN & iR))) = true;
                elseif (any(Rgrp < Rtol/2))
                    Bhole(cell2mat(iGrpR(Rgrp < Rtol/2))) = true;
                end
        end
    end
end

%
if (any(Bhole(:)) && any(jj))
    Bhole = imfilter(double(Bhole),fspecial('disk',5)) > 0;    
    Brej = Brej | Bhole;
else
    % if there are no holes, then return
    for i = 1:length(Pmx)
        if (~isempty(Pmx{i}))
            Pmx{i} = [Pmx{i},true(size(Pmx{i},1),1)];      
        end
    end
end

% --- determines the centre region occupied by the food (rejected region)
function Brej = detCenterRejectedRegions(Ibg,D)

% parameters
[Dmin,nDil,wState] = deal(0.3,5,warning('off','all'));

% calculates the gaussian mixture model
BD = D < Dmin;
gm = fitgmdist(Ibg(BD),2);

% sets the final rejection binary mask
Brej = bwmorph(BD & (Ibg < mean(gm.mu)),'dilate',nDil);

% reverts the warning back to their original state
warning(wState)

% --- calculates the sideways movement ratio for a sub-sequence
function Rmx = calcSidewaysMovement(x,y,p)

% initialisations
[ii,d2r] = deal(1:(length(p)-1),pi/180);

% calculates the angle difference between time points
dp = unwrap(atan2(sin((p(ii+1)-p(ii))*d2r),cos((p(ii+1)-p(ii))*d2r)));

% calculates the inter-frame displacement
[dx,dy] = deal(diff(x),diff(y));
D = sqrt(dx.^2 + dy.^2);

% determines the expected displacement for each point in the path
[dxE,dyE] = deal(D.*cos(p(ii)*d2r+dp),D.*sin(p(ii)*d2r+dp));

% calculates the dot product between the expected and actual locations
[xx,yy] = deal([dxE,dyE],[dx,dy]);
ac = dot(xx,yy,2)./sum(xx.^2,2);

% sets the sideways movement ratio and overall displacement
Rmx = [(1-sum((ac.^2.*D)/sum(D),'omitnan')),sum(D)];

% --------------------------------- %
% --- EVENT METRIC CALCULATIONS --- %
% --------------------------------- %

% --- detects possible seizure events and calculates their metrics
function [indFF,Pmx] = calcEventMetrics(x,y,p,Brej,sFac)

% initialisations
[sz,nFrm] = deal(size(Brej),length(x));
[dT,nMet,pTol] = deal(0.1,2,[0.35,0.20]);
[xi,xiI,d2r,pTolR] = deal(1:nFrm,1:dT:nFrm,pi/180,0.25); 

% memory allocation
[dZS,dZ,ind] = deal(cell(1,nMet));

% interpolates the x, y and orientation angles
Q = 1-exp(-bwdist(Brej));
D = [0;sqrt(diff(x).^2+diff(y).^2)];

% maps the orientation angles from [-pi pi] to [-pi/2 pi/2]
[i1,i2,pp] = deal(p>90,p<-90,p); 
[pp(i1),pp(i2)] = deal(pp(i1)-180,180+pp(i2));

% unwraps the orientation angles 
xiP = xi(1:end-1); 
dp = atan2(sin(2*(pp(xiP+1)-pp(xiP))*d2r),cos(2*(pp(xiP+1)-pp(xiP))*d2r))/2; 
pUW = pp(1)*d2r + [0;cumsum(dp)];

% calculates the interpolated orientation angle and derivative
pS = interp1(xi,unwrap(p*d2r),xiI,'spline')';

% calculates the linear/spline interpolation x/y coordinates and angles
[xIL,xIS] = deal(interp1(xi,x,xiI,'linear')',interp1(xi,x,xiI,'spline')');
[yIL,yIS] = deal(interp1(xi,y,xiI,'linear')',interp1(xi,y,xiI,'spline')');
[pUL,pUS] = deal(interp1(xi,pUW,xiI,'linear')',interp1(xi,pUW,xiI,'spline')');

% sets the linear indices of the normal/interpolated coordinates. from this
% set the rejected object function/binary values
indQ = sub2ind(size(Brej),roundP(y),roundP(x)); 
indQI = sub2ind(size(Brej),roundP(yIS),roundP(xIS)); 
[QQ,BrejI] = deal(double(Q(indQ)'),Brej(indQI));
indB = cellfun(@(x)(((x-1)*10+1):(x*10+1)),num2cell(1:(nFrm-1)),'un',0);

% calculates the absolute distance between the linear/spline interpolations
[dZ{1},dZ{2}] = deal(sqrt((yIS-yIL).^2+(xIS-xIL).^2)*sFac,abs(pUL - pUS));

% ------------------------------ %
% --- INITIAL PEAK DETECTION --- %
% ------------------------------ %

% determines the initial event band lower/upper indices
for i = 1:nMet
    % sums the interpolation difference between time points
    dZS{i} = smoothdata(cellfun(@(x)(sum(dZ{i}(x))),indB));
    dZS{i} = dZS{i}.*QQ(1:end-1);
   
    % determines the peaks from the power signal 
    ind{i} = findAllSignalPeaks(dZS{i},pTol(i));                        
    
    % removes any rejected regions from the summed metric arrays
    dZS{i}(dZS{i} == 0) = NaN;    
end

% determines if there are any peaks
if (all(cellfun(@isempty,ind)))
    % if not, then exit with empty arrays
    [indFF,Pmx] = deal([]);
    return;
else
    % otherwise, sort the peak indices in chronological order
    [~,iSort] = sort(cellfun(@(x)(size(x,1)),ind),'descend');
end

% ---------------------------------- %
% --- EVENT INDEX BAND EXPANSION --- %
% ---------------------------------- %

% expands the event index bands so that they overlap for each metric
for i = iSort(:)'
    % determines the indices of the other metrics
    ii = find((1:nMet) ~= i);
    
    % matches the index bands between the metric types
    for j = 1:size(ind{i},1)
        %
        [indNw,indM] = deal(ind{i}(j,:),cell(nMet-1,1));
        jj = ~cellfun(@isempty,ind(ii));
        
        indM(jj) = cellfun(@(x)(find((x(:,1)<=indNw(2)) & ...
                             (x(:,2)>=indNw(1)))),ind(ii(jj)),'un',0);
        
        %
        for k = 1:(nMet-1)
            switch (length(indM{k}))
                case (0)
                    ind{ii(k)} = [ind{ii(k)};indNw];    
                case (1)
                    if (~isequal(ind{ii(k)}(indM{k},:),indNw))
                        indNw = [min(ind{ii(k)}(indM{k},1),indNw(1)),...
                                 max(ind{ii(k)}(indM{k},2),indNw(2))];
                        [ind{i}(j,:),ind{ii(k)}(indM{k},:)] = deal(indNw);
                    end
                otherwise
                    % sets the combined indices for the groups
                    indNwT = [ind{ii(k)}(indM{k}(1),1),ind{ii(k)}(indM{k}(end),2)];
                    
                    % removes the other index groups
                    jj = ~setGroup(indM{k}(2:end),[length(ind{ii(k)}),1]);
                    [ind{ii(k)},indM{k}] = deal(ind{ii(k)}(jj,:),indM{k}(1));
                    
                    % 
                    if (isequal(indNwT,indNw))
                        ind{ii(k)}(indM{k},:) = indNwT;
                    else
                        indNw = [min(indNw(1),indNwT(1)),...
                                 max(indNw(2),indNwT(2))];
                        [ind{i}(j,:),ind{ii(k)}(indM{k},:)] = deal(indNw);
                    end
            end                   
        end
    end
end

% sorts the indices by chronological order
[~,jSort] = sort(ind{1}(:,1));
indFF = ind{1}(jSort,:);

% sets the x/y coordinates of the likely events
[x,y] = deal(x*sFac,y*sFac);
indP = cellfun(@(x)(x(1):x(2)),num2cell(indFF,2),'un',0);
xP = cellfun(@(xx)(x(xx)),indP,'un',0);
yP = cellfun(@(xx)(y(xx)),indP,'un',0);

% removes any paths that are significantly within the rejected regions
indPI = cellfun(@(x,y)(interpCoordPath(x,y,sz)),xP,yP,'un',0);  
indFF = indFF(cellfun(@(x)(sum(Brej(x(:,1)))/size(x,1) < pTolR),indPI),:);

% determines if there are any overlapping groups
dindFF = [2;(indFF(2:end,1) - indFF(1:end-1,2))];
iGrp = getGroupIndex(dindFF(:)' <= 1);

% if there are any overlapping groups, then join them
if (~isempty(iGrp))
    % sets the new region lower/upper indices
    ii = true(size(indFF,1),1);
    for i = length(iGrp):-1:1
        indFF(iGrp{i}(1)-1,:) = [indFF(iGrp{i}(1)-1,1),indFF(iGrp{i}(end),2)];    
        ii(iGrp{i}) = false;
    end

    % removes the extraneous groups
    indFF = indFF(ii,:);
end
    
% sets the event indices for the normal/interpolated paths
indB = cellfun(@(x)(x(1):x(2)),num2cell(indFF,2),'un',0);
indBI = cellfun(@(x)(((x(1)-1)/dT+1):((x(2)-1)/dT+1)),num2cell(indFF,2),'un',0);

% --------------------------------- %
% --- FINAL METRIC CALCULATIONS --- %
% --------------------------------- %

% calculates the maximum sub-sequence displacement. if there are any
% non-feasible events then remove them
Dmx = cellfun(@(x,y)(detMaxDisp(D(x),BrejI(y))),indB,indBI);
isN = isnan(Dmx);
[indB,indBI,indFF,Dmx] = deal(indB(~isN),indBI(~isN),indFF(~isN,:),Dmx(~isN));

% calculates the max/upper quartile metric values
PzMx = cell2mat(cellfun(@(x)(cellfun(@(y)(max(x(y))),indB)),dZS(:)','un',0));
PzMn = cell2mat(cellfun(@(x)(cellfun(@(y)(prctile(x(y),75)),indB)),dZS(:)','un',0));

% calculates the proportional sideways movement
Dr = cellfun(@(x)(calcPropSidewaysMovement(xIS(x),yIS(x),pS(x),1)),indBI);

% calculates the sum/max path angular displacement difference
dpUSsum = cellfun(@(x)(sum(abs(diff(pUS(x))))),indBI);
dpUSmx = cellfun(@(x)(max(abs(diff(pUW(x))))),indB);

% sets the metrics into a final array (removes any NaN values)
Pmx = [PzMx,PzMn,Dmx,Dr,dpUSsum,dpUSmx];         
Pmx(isnan(Pmx)) = 0;   

% --- calculates the signal acceleration power spectrum
function P = calcAccPowerSpec(varargin)

if (nargin == 1)
    dV = diff(varargin{1});
else
    [X,Y] = deal(varargin{1},varargin{2});
    D = sqrt(diff(X).^2+diff(Y).^2); 
    ii = 2:length(D)-1; 

    dV = zeros(length(D),1); 
    dV(ii) = (D(ii-1)-2*D(ii)+D(ii+1)); 
end

P = mean(calcSigPowerSpectrum(dV),1);

% --- 
function ind = interpCoordPath(x,y,sz,r)

% calculates the distance between the points
D = sqrt(diff(x).^2 + diff(y).^2);
[Dmx,imx] = max(D);        

if (nargin == 3)
    if (Dmx > 0)
        imx = find(D/Dmx > 0.66,1,'first');
        Dmx = D(imx);
    end
end
    
%
nD = ceil(Dmx+1);
xI = roundP(linspace(x(imx),x(imx+1),nD));
yI = roundP(linspace(y(imx),y(imx+1),nD));

%
if (nargin == 3)
    ind = sub2ind(sz,yI,xI)';
else
    ind = [sub2ind(sz,yI,xI)',r*ones(length(xI),1)];
end

% --- determines the maximum inter-frame displacement. if the inter-frame
%     displacement is due to a rejected region (or at the end of the
%     sub-sequence) then a NaN values is returned 
function Dmx = detMaxDisp(D,BrejI)

% parameters
[pBrejTol,pDistR1,pDistR2] = deal(0.40,0.90,0.50);

% determines the maximum displacement from the sub-sequence
[DSort,iSort] = sort(D,'descend');
imx = iSort(1);
if ((imx == 1) || (imx == length(D)))
    % if the max values is at the start/end of the sequence, then return a
    % NaN value
    if ((DSort(2)/DSort(1)) < pDistR1)
        Dmx = NaN;
    else
        Dmx = DSort(1);
    end
else
    % if the point of the maximum displacement is due to passing through a
    % rejected region, then set the displacement to a NaN value
    BrejP = BrejI(((imx-1)*10+1):(imx*10+1));
    if ((mean(BrejP) > pBrejTol) && ((DSort(2)/DSort(1)) < pDistR2))
        Dmx = NaN;
    else
        Dmx = DSort(1);
    end    
end

% --- determines all of the signal peaks
function [xLim,k] = findAllSignalPeaks(P,pTol)

% parameters and memory allocation
[dxMin,dpTol,pWR,nFrm,kTol] = deal(5,0.2,1.25,length(P),0.005);

% filters the power signal
Pm = medfilt1(P,3);
if (max(Pm) < pTol)
    % if the maximum value is less than tolerance, then exit the function
    [xLim,k] = deal([]);
    return
else
    % otherwise, determine the initial peaks from the signal
    [~,imx] = findpeaks(Pm,'MinPeakHeight',pTol);
end

% determines the location of the local minima
imn = find(imregionalmin(Pm))';

% removes any maxima that are too close to each other
isOK = true(length(imx),1);
for i = 1:(length(isOK)-1)
    j = i + (0:1);
    if (diff(imx(j)) < dxMin) 
        if (~all(P(imx(j)) > pWR*pTol))
            [~,jmx] = max(P(imx(j)));
            isOK(j((1:2) ~= jmx)) = false;
        end
    end
end

% 
[ii,imx] = deal(zeros(length(P),2),imx(isOK));
[ii(imx,1),ii(imx,2),ii(imn,1),ii(imn,2)] = deal(1,imx,-1,imn); 

% determines the 
jj = find(ii(:,1)); 
dii = abs(diff(ii(jj,1)));
[iGrp,isOK] = deal(getGroupIndex(dii == 2),true(length(imx),1));

% removes any maxima that either a) are not surrounded by minima points, or
% b) have a difference between the surrounding minima that is too low
jGrp = cell(length(iGrp),1);
for i = 1:length(iGrp)  
    % determines the number of points in the grouping
    nGrp = length(iGrp{i});    
    if (mod(nGrp,2) == 0)
        % if there are an even number of points, then set the global
        % indices of the surrounding minima
        kMn = jj((iGrp{i}(1)):2:(iGrp{i}(end)+1));        
        indMn = [kMn(1:end-1),kMn(2:end)];            
        jGrp{i} = indMn;        
    else
        % odd number of points, so reject all maxima within the grouping
        for j = 1:nGrp
            isOK(jj(iGrp{i}(j)) == imx) = false;
        end
    end    
end

% removes the non-feasible peak points
[jGrp,imx] = deal(cell2mat(jGrp(~cellfun(@isempty,jGrp))),imx(isOK));

% memory allocation
yC = cell(1,length(Pm));
[A,mu,k] = deal(zeros(length(imx),1));
xLim = NaN(length(imx),2);

%
for i = 1:length(imx)
    %
    xx = (jGrp(i,1):jGrp(i,2))';
    xxI = xx(1):0.1:xx(end);
    yy = Pm(xx)';
    
    [A(i),iiMx] = max(interp1(xx,yy,xxI,'spline')); 
    mu(i) = xxI(iiMx);
    k(i) = calcWeightedMean((log(A(i)./yy)./(xx-mu(i)).^2));    

    if (k(i) >= kTol)
        yC{i} = A(i)*exp(-k(i)*((1:length(Pm))-mu(i)).^2);
        D = sqrt(log(A(i)/(A(i)*dpTol))/k(i));
        xLim(i,:) = [max(1,floor(mu(i)-D)),min(nFrm,ceil(mu(i)+D))];        
    end
end

% removes all overlapping bands
while (1)
    % determines the events which have overlapping bands
    ii = find((xLim(2:end,1) - xLim(1:end-1,2)) <= 0);
    if (isempty(ii))
        % if there are none, then exit the loop
        break
    else
        % otherwise, reset the index bands
        isOK = ~isnan(xLim(:,1));
        for i = length(ii):-1:1
            [xLim(ii(i),2),isOK(ii(i)+1)] = deal(xLim(ii(i)+1,2),false);
        end
    end

    % removes the non-feasible events
    xLim = xLim(isOK,:);    
end

% --- calculates the proportional sideways/backwards movement distance
function DDs = calcPropSidewaysMovement(x,y,p,varargin)

% parameters and initialisations
[pC,pS] = deal(cos(p),sin(p));
[xi,xiN] = deal(1:(length(x)-1),2:length(x));

% calculates the inter-frame displacement
D = sqrt(diff(x).^2+diff(y).^2); D = [D(1);D];

% calculates the dot-product between the fly's orientation and actual
% displacement
[xx,yy] = deal([pC(xi),pS(xi)],[diff(x),diff(y)]);
Dc = dot(xx,yy,2)./sqrt(sum(yy.^2,2));
[Ds,isN] = deal(sqrt(1-Dc.^2),Dc < 0);

% calculates the proportional sideways/backwards movement distance 
DDs = sum(([sum(Ds.*D(xiN)),sum(Dc(isN).*D(xiN(isN)))]/sum(D(xiN))).^2)^0.5;