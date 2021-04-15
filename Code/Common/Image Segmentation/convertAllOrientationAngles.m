% --- wrapper function for calculating all fly orientation angles
function [pData,ok] = convertAllOrientationAngles(pData,iData,iMov,h)

% global variables
global wOfs

% array dimensionsing and parameters
wStr = 'Orientation Angle Conversion';
[nApp,ok] = deal(length(pData.fPos),true);

% initialisations
fOK = num2cell(iMov.flyok,1)';
axR = cellfun(@(x,y)(x(y)),pData.axR,fOK(:)','un',0);
[~,paxR] = setupSignalCDF(cell2mat(cell2cell(axR,0)'));

% loops through all the frames/sub-regions determining if there is an issue
for i = 1:nApp
    % updates the waitbar figure
    if ~isempty(h)
        wStrNw = sprintf('%s (Region %i of %i)',wStr,i,nApp);
        if h.Update(wOfs+1,wStrNw,i/nApp)
            ok = false; return;
        end
    end

    % only check if the apparatus is not rejected
    if iMov.ok(i)
        nTube = getSRCountMax(iMov);
        for j = 1:nTube    
            % updates the waitbar figure
            if ~isempty(h)
                wStrNw = sprintf('%s (Sub-Region %i of %i)',wStr,j,nTube);
                if h.Update(wOfs+2,wStrNw,j/nTube)
                    ok = false; return
                end
            end            
            
            % only check if the sub-region is not rejected
            if iMov.flyok(j,i)           
                PhiF = convertOrientationAngle(iData,pData,paxR,i,j,h);
                if (isempty(PhiF))
                    ok = false; return;
                else
                    pData.PhiF{i}{j} = PhiF;                
                end
            end
        end
    end
end

% --- converts the orientation angles to bearings
function PhiB = convertOrientationAngle(iData,pData,paxR,iApp,iFly,h)

% parameters and initialisation
[axR,Phi] = deal(pData.axR{iApp}{iFly},pData.Phi{iApp}{iFly});
[d2r,axRTol,NszBTol,del,nFrm] = deal(pi/180,0.025,0.025,3,length(Phi));

% ---------------------------------------- %
% --- SMALL ASPECT RATIO INTERPOLATION --- %
% ---------------------------------------- %

%
Zax = ppval(paxR,axR);
Zn = setupSignalCDF(pData.NszB{iApp}{iFly});

% determines the time bands where the a/r is small
iGrp = getGroupIndex((Zax < axRTol) & (Zn < NszBTol));
if ~isempty(iGrp)
    % combines any time bands which are close to each other
    iGrp = combineCloseGroups(iGrp,del);
    
    % for the small a/r time bands interpolate the orientation angles
    for i = 1:length(iGrp)  
        % only interpolate orientation angles if not at the start/end
        if (iGrp{i}(1) > 1) && (iGrp{i}(end) < nFrm)
            % sets the pre/post gap indices
            xiI1 = max(1,iGrp{i}(1)-del):(iGrp{i}(1)-1);
            xiI2 = (iGrp{i}(end)+1):min(nFrm,iGrp{i}(end)+del);
            
            % calculates the angle difference between start/end of the
            % interpolation phase
            [PhiI1,PhiI2] = deal(Phi(xiI1),Phi(xiI2));
            dPhi = calcOrientAngleDiff(PhiI1(end)*d2r,PhiI2(1)*d2r,1);

            % check to see the angle difference and 
            if ((sign(dPhi) < 0) && (PhiI2(1) > PhiI1(end)))
                PhiI2 = -180 + PhiI2;
            elseif ((sign(dPhi) > 0) && (PhiI2(1) < PhiI1(end)))
                PhiI2 = 180 + PhiI2;
            end
            
            % interpolates the values
            PhiI = [PhiI1(:)',PhiI2(:)'];
            Pnw = interp1([xiI1,xiI2],PhiI,iGrp{i},'pchip');                        
            Phi(iGrp{i}) = mod(Pnw+90,180)-90;
        end
    end
end

% ------------------------------------------------ %
% --- CORRECTED ORIENTATION ANGLE CALCULATIONS --- %
% ------------------------------------------------ %

% calculates the correction orientation angles
PhiB = detCorrectAngleOrientation(iData,pData,Phi,iApp,iFly,h);

% ----------------------------------------------------------------------- %
% ---                         OTHER FUNCTIONS                         --- %
% ----------------------------------------------------------------------- %

% ----------------------------------------- %
% --- ORIENTATION CALCULATION FUNCTIONS --- %
% ----------------------------------------- %

% --- calculates the correction orientation angles
function PhiBF = detCorrectAngleOrientation(iData,pData,Phi,iApp,iFly,h)

% global variables
global wOfs
h.Update(wOfs+3,'Determining Correct Orientation Angles',0);

%
fPos = pData.fPosL{iApp}{iFly};
[axR,Phi] = deal(pData.axR{iApp}{iFly},Phi*pi/180);

% parameters and initialisations
[nGrpMin,delG,sFac,DrngTol,pdTol,nSm] = deal(5,5,iData.exP.sFac,3,2,3); 
[X,Y] = deal(smooth(fPos(:,1),nSm),smooth(fPos(:,2),nSm));
[del,nFrm,fDir] = deal(10,length(X),1);
xi = 1:(nFrm-1);

%
PhiS = (mod(smooth(unwrap(2*Phi),nSm)+pi,2*pi)-pi)/2;
[dXs,dYs] = deal(del*cos(PhiS),del*sin(PhiS));

% calculates the inter-frame displacement ratio
DD = max(0.1,[0;sqrt(sum(diff(fPos,[],1).^2,2))]*sFac);
pD = [0;(DD(2:end)./DD(1:end-1))].*(DD > pdTol);

% sets the forward/reverse points
[pF,pR,pFin] = deal(zeros(nFrm,2));
[pF0,pR0] = deal([(X+dXs),(Y+dYs)],[(X-dXs),(Y-dYs)]);

% determines when there is a discontinuity in orientation angle
dPhi = [0;calcOrientAngleDiff(Phi(xi),Phi(xi+1))];
dPhiG = (calcOrientAngleDiff(PhiS(xi),PhiS(xi+1))-diff(PhiS))/pi;
iGrp = getGroupIndex([0;abs(dPhiG)] > 0.99);

%
if (isempty(iGrp))
    % no discontinuity so set the arrays as per normal
    [pF,pR] = deal(pF0,pR0);
else
    % sets the for forward/reverse position arrays values
    [pF,pR] = setFRPos(pF,pR,pF0,pR0,1:(iGrp{1}(1)-1),fDir);
    
    % 
    for i = 1:length(iGrp)
        %
        for j = 1:length(iGrp{i})
            fDir = -fDir;
            [pF,pR] = setFRPos(pF,pR,pF0,pR0,iGrp{i}(j),fDir);
        end
        
        %
        if (i == length(iGrp))
            k = (iGrp{i}(end)+1):nFrm;
        else
            k = (iGrp{i}(end)+1):(iGrp{i+1}(1)-1);            
        end
        
        %
        [pF,pR] = setFRPos(pF,pR,pF0,pR0,k,fDir);
    end
end

%
[B,dpRF] = detGenMovement([X,Y],pF,pR,Phi);

% fills any any remaining gaps
if (all(B == 0))
    % fly has not moved at all
    B(:) = 1;
else
    % otherwise, fill in any gaps (if they exist)
        
    % determines the small groups
    iGrp = getGroupIndex(B ~= 0);
    smlGrp = find(cellfun(@length,iGrp) < nGrpMin);
    
    %
    isOK = true(length(iGrp),1);
    for i = 1:length(smlGrp)
        % sets the global index
        j = smlGrp(i);
        
        % determines the indices that need to be reset
        if (iGrp{j}(1) == 1)
            % the group is located at the start of the video
            indNw = 1:(iGrp{j+1}(1)-1);
        elseif (iGrp{j}(end) == length(axR))
            % the group is located at the end of the video
            indNw = (iGrp{j-1}(end)+1):length(axR);
        else
            % the case is neither at the start or end
            indNw = (iGrp{j-1}(end)+1):(iGrp{j+1}(1)-1);
        end
        
        % resets the indices for the small group
        [B(indNw),isOK(j)] = deal(-B(iGrp{j}(1)),false);
    end
    
    % determines the small groups
    jGrp = getGroupIndex(B == 0);
    jGrp = cellfun(@(x)((max(1,(x(1)-delG)):min(length(axR),x(end)+delG))'),jGrp,'un',0);
        
    % loops through all the sub-sequence gaps filling in the missing values
    for i = 1:length(jGrp)     
        % updates the waitbar figure
        wStrNw = sprintf('Calculating Optimal Direction (Band %i of %i)',i,length(jGrp));
        if h.Update(wOfs+3,wStrNw,i/length(jGrp))
            PhiBF = [];
            return
        end
        
        % sets the end directional values for the sub-sequence
        Bend = B(jGrp{i}([1 end]));         
        
        % 
        iFrmT = detLikelyTurnPoint([X,Y],pF,pR,pD,dPhi,jGrp{i},sFac);
        if (length(iFrmT) == 1)
            % only one likely turning point
            [i0,i1] = deal(jGrp{i}(1):(iFrmT-1),iFrmT:jGrp{i}(end));
            [B(i0),B(i1)] = deal(Bend(1),Bend(2));
        else
            % more than one likely turning point
            [i0,i1] = deal(jGrp{i}(1):(iFrmT(1)-1),iFrmT(end):jGrp{i}(end));
            [B(i0),B(i1)] = deal(Bend(1),Bend(2));
            
            % determines the most likely direction within the mid-points
            for k = 1:(length(iFrmT)-1)
                iFrmS = iFrmT(k):iFrmT(k+1);
                B(iFrmS) = sign(mean(dpRF(iFrmS)));
            end
        end
    end
    
    % determines all the orphan directional frames
    kGrpF = [getGroupIndex(B == 1);getGroupIndex(B == -1)];
    kGrpF = kGrpF(cellfun(@length,kGrpF) == 1);    
    
    % if any orphan frames, then determine if they need to be flipped
    for i = 1:length(kGrpF)
        if (kGrpF{i} == 1)
            % case is the first frame
            ii = 2;
        elseif (kGrpF{i} == length(B))
            % case is the last frame
            ii = length(B) - 1;
        else
            % case is another frame
            ii = kGrpF{i} + [-1 1];
        end
        
        % if the single frame is surrounded by other feasible direction
        % frames, then flip the directional flag
        if (all(~isnan(B(ii)))); B(kGrpF{i}) = -B(kGrpF{i}); end
    end
        
    % determines any orphan non-feasible frames
    kGrpN = getGroupIndex(isnan(B));
    kGrpN = kGrpN(cellfun(@length,kGrpN) == 1);      
    
    % if any orphan frames, then determine if they need to be reset
    for i = 1:length(kGrpN)
        if (kGrpN{i} == 1)
            % case is the first frame
            ii = 2;
        elseif (kGrpN{i} == length(B))
            % case is the last frame
            ii = length(B) + 1;
        else
            % case is another frame
            ii = kGrpN{i} + [-1 1];
        end
        
        % if the single frame is surrounded by other feasible direction
        % frames, then flip the directional flag
        if (prod(B(ii)) == 1); B(kGrpN{i}) = B(ii(1)); end
    end    
end

% calculates the final bearing angle
[i0,i1,i2] = deal(B == 1,B == -1,isnan(B));
[pFin(i0,:),pFin(i1,:),pFin(i2,:)] = deal(pF(i0,:),pR(i1,:),NaN);
PhiB = atan2(pFin(:,2)-Y,pFin(:,1)-X)*180/pi;

% calculates the inter-frame orientation angle differences
dPhi = [0;calcAngleDifference(unwrap(PhiB*pi/180))*(180/pi)];

% searches the about-face turns to see if there is significant displacement
% between frames. if not, then flip the orientation angles again
[iTurn,i] = deal(find(abs(dPhi) > 160),1);
while (i < length(iTurn))
    % sets the frame indices between the about-face turns
    kk = iTurn(i):iTurn(i+1);
    
    % calculates the distance range over the sub-sequence
    Drng = sFac*sum(range(fPos(kk,:),1).^2).^0.5;    
    if (Drng < DrngTol)
        % if the range is less than tolerance, then flip the angles
        i = i + 2;
        PhiB(kk(1:end-1)) = mod(PhiB(kk(1:end-1))+360,360)-180;
    else
        % otherwise, increment the counter
        i = i + 1;
    end
end

% ensures the raw orientation angles are in the correct direction
dP = abs(PhiB-Phi*180/pi)/180;
PhiBF = mod(Phi*180/pi+(1+roundP(dP))*180,360)-180;

% --- 
function [B,dpRF] = detGenMovement(fP,pF,pR,Phi)

% memory allocation
[nFrm,nSm,del] = deal(size(fP,1),5,25);
dPhi = [0;diff((180/pi)*unwrap(2*Phi)/2)];

%
iFrm = num2cell((1:nFrm)');
xi = cellfun(@(x)(max(1,x-del):x),iFrm,'un',0);

%
dPhiG = cellfun(@(x)(cumsum(dPhi(x))-sum(dPhi(x))),xi,'un',0);
xiG = cellfun(@(x,y)(x(find(abs(y)<60,1,'first'):end)),xi,dPhiG,'un',0);

%
dpR = cellfun(@(x,y)(pdist2(fP(x,:),pR(y,:))),iFrm,xiG,'un',0);
dpF = cellfun(@(x,y)(pdist2(fP(x,:),pF(y,:))),iFrm,xiG,'un',0);

%
[pRmin,pFmin] = deal(cellfun(@(x)(min(x)),dpR),cellfun(@(x)(min(x)),dpF));
dpRF = smooth(pRmin - pFmin,nSm);

%
B = sign(dpRF).*(abs(dpRF) > 5);

% fills in the gaps within a directional block
iGrp = getGroupIndex(B ~= 0);
for i = 1:(length(iGrp)-1)
    if (B(iGrp{i}(1)) == B(iGrp{i+1}(1)))
        B((iGrp{i}(end)+1):(iGrp{i+1}(1)-1)) = B(iGrp{i}(1));
    end
end

% ensures the directional values have been set from the start
if (B(1) == 0)
    i0 = find(B~=0,1,'first');
    B(1:i0) = B(i0);
end

% ensures the directional values have been set to the end
if (B(end) == 0)
    i1 = find(B~=0,1,'last');
    B(i1:end) = B(i1);
end

% --- 
function iFrmT = detLikelyTurnPoint(fP,pF,pR,pD,dPhi,iFrm,sFac)

% parameters
[DrngTol,pdTol,dPhiTol] = deal(2,7.5,pi/3);
[pDL,dPhiL] = deal(pD(iFrm),dPhi(iFrm));

%
if (any(pDL > pdTol))
    % if there are any major jumps, then this is probably the location of
    % the turning point
    iFrmT = iFrm(pDL > pdTol);
elseif (any(dPhiL > dPhiTol))
    % if there are any major changes in orientation angle, then this is
    % probably the location of the turning point
    iGrp = getGroupIndex(dPhiL > dPhiTol);
    iFrmT = iFrm(cellfun(@(x)(x(end)),iGrp));
else
    % otherwise, determine the likely turning point from the curvature
    K = [calcSegCurvature(fP(iFrm,:)),...
         calcSegCurvature(pF(iFrm,:)),...
         calcSegCurvature(pR(iFrm,:))];
    Kp = prod(abs(K),2);

    %
    kpInf = isinf(Kp);
    if (~any(kpInf))
        % determines the maximum product value
        [~,iFrm0] = max(max(abs(K),[],2));   
        iFrmT = iFrm(iFrm0);    
    elseif (sum(kpInf) == 1)
        % only one frame has a discontinuity in curvature
        iFrmT = iFrm(kpInf);
    else
        % multiple frames have a dis
        [jFrm,kk] = deal(iFrm(kpInf),1);        
        while (1)            
            [idx,~,cmn] = kmeans(fP(jFrm,:)*sFac,kk);        
            if (max(cmn) < DrngTol)
                % if the groups are less than tolerance in distance, then
                % set the maximum frame from each group
                iFrmT = cellfun(@(x)(max(jFrm(idx==x))),num2cell(1:kk)');
                break;
            else
                % increments the kmeans counter
                kk = kk + 1;
                if (kk == length(jFrm))
                    iFrmT = jFrm(:);
                end
            end
        end

        % sorts the frames in chronological order
        iFrmT = sort(iFrmT);
    end
end
    
% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- updates the forward/reverse position arrays (based on direction)
function [pF,pR] = setFRPos(pF,pR,Y1,Y2,ind,fDir)

% sets the forward/reverse coordinates based on direction
if (fDir == 1)
    [pF(ind,:),pR(ind,:)] = deal(Y1(ind,:),Y2(ind,:));
else
    [pF(ind,:),pR(ind,:)] = deal(Y2(ind,:),Y1(ind,:));
end

% --- 
function [Z,p] = setupSignalCDF(Y)

%
[Y,sY] = deal(abs(Y),sign(Y));

%
if (range(Y) == 0)
    p = pchip([0 100],Y(1)*[1 1]);
else
    [f,x] = ecdf(Y); 
    p = pchip(x(2:end),f(2:end));     
end

Z = sY.*ppval(p,Y);
    
% --- 
function iGrp = combineCloseGroups(iGrp,del)

% determines the low a/r groups that close to each other
indB = cell2mat(cellfun(@(x)([x(1) x(end)]),iGrp,'un',0));
ii = find((indB(2:end,1)-indB(1:end-1,2)) <= del);

% combines the groups indices of the closely associated groups
isOK = true(length(iGrp),1);
for i = length(ii):-1:1
    iGrp{ii(i)} = (iGrp{ii(i)}(1):iGrp{ii(i)+1}(end))';
    isOK(ii(i)+1) = false;
end

% removes the non-feasible groups
iGrp = iGrp(isOK);