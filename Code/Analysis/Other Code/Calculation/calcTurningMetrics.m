% --- calculates the turning metrics for a given experiment
function tData = calcTurningMetrics(snTot,cP,h,nExp)

% global variables
global wOfs

% data struct memory allocation
tData = struct('R',[],'exPr',[],'enPr',[],'cTurnM',[],'cTurnN',[],...
               'exStats',[],'enStats',[],'dcStats',[],'rStats',[],...
               'actDur',[],'actMet',[]);

% function parameters (REMOVE ME LATER)
if (nargin < 2)
    cP = struct('dPhiTol',30,'dPhiTolMT',135,'vTol',2,'rTol',3);
end
    
% waitbar figure setup (REMOVE ME LATER)
if nargin < 3
    wStr = {'Analysing Regions','Calculating Turn Statistics',...
            'Turn Angle Calculations'};
    [h,wOfs] = deal(ProgBar(wStr,'Turn Analysis'),0);
else
    wOfs = nExp>0;
end
    
% parameters and initialisations
[dpMin,d2r,pW] = deal(10,pi/180,0.9);
[nApp,T] = deal(length(snTot.Px),cell2mat(snTot.T));
[fok,sFac] = deal(snTot.appPara.flyok,snTot.sgP.sFac);
    
% sets the relevant time points and apparatus indices for this expt
if (cP.useAll)
    % uses all the time points
    ii = 1:length(T);
else
    % use only the points from the start to the duration end
    ii = (T >= 60*cP.T0) & (T <= 60*(cP.T0 + cP.Tdur));
    T = T(ii)-60*cP.T0;   
end  

% calculates the inter-frame time differences
[nFrm,dT] = deal(length(T),diff(T));

% memory allocation
a = cell(nApp,1);
[exPr,enPr,cTurnM,cTurnN,R] = deal(a);
[actDur,actMet,exStats,enStats,dcStats] = deal(a);

% calculates the time vector piecewise polynomial
pT = pchip(1:length(T),T);

% determines the non-rejected fly tubes
fokNw = cellfun(@(x,y)(any(~isnan(x),1) & ...
                       any(~isnan(y),1)),snTot.Px,snTot.Py,'un',0);

% calculates the metrics/stats for each sub-group
for i = 1:nApp
    % updates the waitbar figure
    wStrNw = sprintf('%s (Group %i of %i)',h.wStr{1},i,nApp);
    if h.Update(1+wOfs,wStrNw,i/nApp,h)
        % if the user cancelled, then exit the function
        tData = [];
        return
    end       
    
    if snTot.appPara.ok(i)
        % updates the waitbar figure
        wStrNw = 'Calculating Relative 2D Coordinates';
        h.Update(2+wOfs,wStrNw,1/(length(fok{i})+1));
        h.Update(3+wOfs,h.wStr{3},0);
        pause(0.05);
                
        % retrieves the relative 2D coordinates
        PhiFT = snTot.Phi{i}(ii,fokNw{i});
        [dPx,dPy,R{i}] = get2DCoordsBG(snTot,i);
        [dPx,dPy] = deal(dPx(ii,:),dPy(ii,:));
        
        % determines the edge position flags for each fly (over all frames)
        onEdge = detFlyEdgePos(dPx,dPy,R{i},cP,sFac);                    
        
        % memory allocation
        [nFly,a] = deal(size(dPx,2),cell(1,size(dPx,2)));
        [cTurnM{i},cTurnN{i},exPr{i},enPr{i}] = deal(a);
        [dcStats{i},actDur{i},actMet{i},exStats{i},enStats{i}] = deal(a);
                
        % calculates the stats/metrics for each of the valid flies
        for j = 1:nFly  
            % updates the waitbar figure
            wStrNw = sprintf('%s (Fly %i of %i)',h.wStr{2},j,nFly);
            if h.Update(2+wOfs,wStrNw,(j+1)/(nFly+1))
                % if the user cancelled, then exit the function
                tData = [];
                return
            else
                % otherwise, reset the waitbar figure
                h.Update(3+wOfs,'Initial Turn Detection',0);
            end            
            
            % ------------------------------------------ %
            % --- INITIALISATIONS & PRE-CALCULATIONS --- %
            % ------------------------------------------ %            
            
            % initialisations            
            [X,Y,PhiF] = deal(dPx(:,j),dPy(:,j),PhiFT(:,j));  
            [dX,dY] = deal(diff(X),diff(Y));
            [PhiC,PhiFU] = deal(unwrap(atan2(Y,X)),unwrap(d2r*PhiF));
            
            % calculates interframe displacement/orientation angle differences 
            [dPhi,dPhiM] = deal([0;-calcAngleDifference(PhiF*d2r)/d2r]);
            [Dr,xi] = deal([0;sFac*(dX.^2 + dY.^2).^0.5],1:length(dPhi));            
            [pP0,Ds] = deal(pchip(xi,dPhi),smooth(Dr));                  
            [pD,pPhiC,pPhi] = deal(pchip(xi,Ds),pchip(xi,PhiC),pchip(xi,PhiFU));
            [rTol,Drad] = deal(R{i}(j) - cP.rTol/sFac,sqrt(X.^2+Y.^2)*sFac);
                        
            % ------------------------------------------------------ %
            % --- JUMP EVENT DETECTION & ENTRY TYPE CALCULATIONS --- %
            % ------------------------------------------------------ %
            
            % determines if there are any jump events
            jStats = detJumpStats(PhiF,dPhi,Dr,[dX,dY]);
            Br = setGroup(jStats',[nFrm,1]);
            
            % calculates the outer region movement types
            [exStats{i}{j},exPr{i}{j}] = detCrossStats(...
                            pPhi,pPhiC,X,Y,onEdge(:,j),Br,rTol,sFac,1);             
            [enStats{i}{j},enPr{i}{j}] = detCrossStats(...                                                  
                            pPhi,pPhiC,X,Y,onEdge(:,j),Br,rTol,sFac,0);                               
                        
            % --------------------------------------- %
            % --- MAJOR TURN/JUMP EVENT DETECTION --- %
            % --------------------------------------- %        
            
            % determines the frames with major turns and jumps
            iFrmM = getMajorTurns(dPhi,cP,dpMin);                                                                 
            
            % calculates the major turn properties
            [dtTurnM,iTurnM,pTurnM,dTurnM,ok] = calcTurnProps(...
                            pP0,pT,pD,iFrmM,cP,nFrm,dpMin,0,h);                                                      
            if (~ok)
                tData = [];
                return; 
            end
            
            % removes the major turns/jumps from orientation angle array so
            % as to determine the normal turn events
            Br(cell2mat(iTurnM(:)')) = true;
            dPhiM(Br) = 0;                              
                        
            % ----------------------------------- %
            % --- NORMAL TURN EVENT DETECTION --- %
            % ----------------------------------- %
                                    
            % determines the positive/negative turn angles            
            pP = pchip(1:length(dPhi),dPhiM);
            iGrpP = getGroupIndex(dPhiM > dpMin);
            iGrpN = getGroupIndex(dPhiM < -dpMin);          

            % combines the groups and sorts in chronological order
            iGrp = [iGrpP(~cellfun(@isempty,iGrpP));...
                    iGrpN(~cellfun(@isempty,iGrpN))];
            [~,iSort] = sort(cellfun(@(x)(x(1)),iGrp));
            iGrp = iGrp(iSort);

            % removes any turn events that have small angle sums
            iFrm = iGrp(abs(cellfun(@(x)(sum(dPhi(x))),iGrp)) > pW*cP.dPhiTol);
            
            % calculates the major turn properties
            [dtTurnN,iTurnN,pTurnN,dTurnN,ok] = calcTurnProps(...
                                pP,pT,pD,iFrm,cP,nFrm,dpMin,1,h);             
            if (~ok); 
                tData = [];
                return; 
            end
              
            % sets the major turn classification array
            cTurnM{i}{j} = [cellfun(@(x)(x(1)),iTurnM),pTurnM,dTurnM,dtTurnM];
            
            % ----------------------------------- %
            % --- NORMAL TURN EVENT DETECTION --- %
            % ----------------------------------- %
                        
            % updates the waitbar figure
            h.Update(3+wOfs,'Classifying Turn Events',0.9);
            
            % classifies the normal turn events
            cTurnN{i}{j} = classifyTurnEvents(iTurnN,pTurnN,dTurnN,dtTurnN,Br,onEdge(:,j));                                 
            
%             if (~isempty(indT))                
%                 [pEnter{i}{j},pExit{i}{j}] = detCrossAngles(X,Y,PhiFU,onEdge(:,j),indT,rTol);                
%                 Drel{i}{j}{1} = detTurnRelDisp(X,Y,PhiC,indT{3},~onEdge(:,j),-1);
%             end     
                        
            % -------------------------------------- %
            % --- ACTIVITY DURATION CALCULATIONS --- %
            % -------------------------------------- %

            % combines the normal/major turns into a single array
            iTurnT = [iTurnN;iTurnM];
            cTurnT = [cell2mat(cTurnN{i}{j}(:));cTurnM{i}{j}];
            
            % sets the combined region, movement, turn boolean array
            A = [onEdge(:,j),(Ds > cP.vTol),false(nFrm,1)];
            B = cellfun(@(x)(x(:)),iTurnT,'un',0);
            iT0 = cellfun(@(x)(x(1)),iTurnT);            
             
            % determines which turn events have an average speed 
            if (~isempty(cTurnT))
                isM = cTurnT(:,3)./cTurnT(:,4) > cP.vTol;
                [A(cell2mat(B(isM)),2),A(cell2mat(B(~isM)),2)] = deal(true,false);
            end
                        
            % calculates the activity type flags
            A(cell2mat(B),3) = true;
            A = A(2:end,:);
            Q = 4*A(:,1)+2*A(:,2)+A(:,3);
            
            % removes any events on the last frame
            iT0 = iT0(iT0 < nFrm);
            
            % calculates the activity duration for each type
            [actDur{i}{j},actMet{i}{j}] = deal(zeros(8,1),cell(1,8));
            for k = 1:8
                actDur{i}{j}(k) = sum(dT(Q == (k-1)));                                
                kM = Q(iT0) == (k-1);
                actMet{i}{j}{k} = [cTurnT(kM,2:end),Drad(iT0(kM))];
            end
            
            % --------------------------------- %
            % --- OTHER METRIC CALCULATIONS --- %
            % --------------------------------- %
            
            % detects the outer region directional change events
            dcStats{i}{j} = detDirChange([0;dT],PhiC,PhiFU,onEdge(:,j));                                    
        end
    end
end

% sets the data arrays into the final struct
tData.R = cellfun(@(x)(x*sFac),R,'un',0);
[tData.exPr,tData.enPr] = deal(exPr,enPr);
[tData.cTurnM,tData.cTurnN] = deal(cTurnM,cTurnN);
[tData.exStats,tData.enStats] = deal(exStats,enStats);
[tData.dcStats,tData.actDur,tData.actMet] = deal(dcStats,actDur,actMet);

% closes the waitbar figure (if testing...)
if nargin == 1
    h.closeProgBar(); 
end

% ------------------------------------- %
% --- TEST FUNCTIONS (REMOVE LATER) --- %
% ------------------------------------- %

% --- determines the exit turn type 
function Drel = detTurnRelDisp(X,Y,PhiC,indT,onEdge,mlt)

% initialisations
[N,nFrm] = deal(10,length(X));

% sets the turn bands
ix = cellfun(@(x)(x(find(~onEdge(x),1,'first'))),indT,'un',0);
ind = cellfun(@(x,y)(max(y(1),x-N):min(nFrm,x+N)),ix,indT,'un',0);

% ensures that the turn bands don't overlap
for i = 1:(length(ind)-1)
    if (ind{i}(end) >= ind{i+1}(1))
        ind{i} = ind{i}(ind{i} < ind{i+1}(1));
    end
end

% calculates the rotated edge coordinates
Pr = cell2cell(cellfun(@(x,y)(rotateEdgeCoord(...
                    [X(x),Y(x)],[X(y),Y(y)],PhiC(y),mlt)),ind,ix,'un',0));

%
Drel = zeros(length(ind),1);
for i = 1:length(ind)
    [ii,jj] = deal(Pr{i}(:,2) < 0,Pr{i}(:,2) > 0);
    Drel(i) = mean(Pr{i}(jj,1))/sign(mean(Pr{i}(ii,1)));
end

% REMOVE ME LATER
a = 1;

% --------------------------------- %
% --- EVENT DETECTION FUNCTIONS --- %
% --------------------------------- %

% --- determines the time bands of the major turn events
function iTmaj = getMajorTurns(dPhi,cP,dpMin)

% parameters
[N,nFrm] = deal(20,length(dPhi));

% determines the locations of the major turn events
ii = find(abs(dPhi) > cP.dPhiTolMT);

% determines the time bands surrounding the turn events
iTmaj = cell(length(ii),1);
for i = 1:length(iTmaj)
    % sets the pre/post turn event index arrays
    i0 = max(1,ii(i)-N):ii(i);
    i1 = ii(i):min(nFrm,ii(i)+N);
    
    % determines where the orientation change falls below threshold
    if (sign(dPhi(ii(i))) == 1)
        % orientation angle change is positive
        j0 = find(dPhi(i0) < dpMin,1,'last')+1;
        j1 = find(dPhi(i1) < dpMin,1,'first')-1;
    else
        % orientation angle change is negative
        j0 = find(dPhi(i0) > -dpMin,1,'last')+1;
        j1 = find(dPhi(i1) > -dpMin,1,'first')-1;        
    end
    
    % calculates the limits of the turn events
    iTmaj{i} = i0(j0):i1(j1);
end

% removes any turn events that are empty
iTmaj = iTmaj(~cellfun(@isempty,iTmaj));

% --- determines the location of any potential "jump" events"
function iTj = detJumpStats(PhiF,dPhi,D,pAcc)

% parameters
[DTol0,pDmin0,pDTol0] = deal(0.01,2,5);

% metric jump event tolerances
pDTol = 250;    % proportional difference tolerance
dTol = 0.6;     % orientation dot-product tolerance
Dtol = 3.5;     % inter-frame displacement tolerance
dPhiTol = 50;   % inter-frame orientation angle difference tolerance

% calculates the dot product of the expected/actual fly positions
pExp = [cos(PhiF(1:end-1)*pi/180),sin(PhiF(1:end-1)*pi/180)]; 
d = [1;dot(pExp,pAcc,2)./D(2:end)]; 

% calculates the proportional change in displacement
Dmn = max(D,DTol0); 
pD = [0;(Dmn(2:end)./Dmn(1:end-1))];

% preliminary determination of like jump events
jFrm = find(pD.*(D > pDmin0) > pDTol0); 

% thresholds the individual metrics to determine the actual jump events
B = (pD(jFrm) > pDTol) | (abs(d(jFrm)) < dTol) | ...
    (D(jFrm) > Dtol) | (abs(dPhi(jFrm)) > dPhiTol);
iTj = jFrm(B);

% --- determines the time bounds on a turn event
function indB = detTurnEventLimits(pP,nFrm,iNw,dpMin)

% initialisation
sP = sign(ppval(pP,iNw(1)));
[opt,indB] = deal(optimset('display','none','TolFun',0.01),iNw([1 end]));

% determines the lower bound time of the turn
if (iNw(1) > 1)
    indB(1) = fminbnd(@optFunc,iNw(1)-1,iNw(1),opt,pP,sP,dpMin);
end

% determines the upper bound time of the turn
if (iNw(end) < (nFrm-1))
    indB(2) = fminbnd(@optFunc,iNw(end),iNw(end)+1,opt,pP,sP,dpMin);
end

% --- calculates the bound detection objective function
function F = optFunc(x,pP,sP,dpMin)

F = abs(ppval(pP,x) - sP*dpMin);

% ------------------------------------------------- %
% --- EVENT CLASSIFICATION/STATISTICS FUNCTIONS --- %
% ------------------------------------------------- %
      
% --- function that classifies the turn events
function [cTurn,indTF] = classifyTurnEvents(iTurn,pTurn,dTurn,dtTurn,BR,onEdge)

% parameters and initialisations
iBR = find(BR);
[del,nFrm,nJump] = deal(2,length(onEdge),length(iBR)); 

% sets the frame range extent based on the normal turn/jump events
if (isempty(iTurn))
    % if there are no turn events, then exit the function
    [cTurn,indTF] = deal([]);
    return
elseif (nJump == 0)
    % if there are no jump events, then use the max frame range extent
    [delP0,delPF] = deal(del*ones(length(iTurn),1));
else
    % otherwise, determines the frame range such that the frame range
    % around the turn events do not include a jump event
    iJumpT = repmat(iBR(:)',length(iTurn),1);
    iTurn0 = repmat(cellfun(@(x)(x(1)),iTurn),1,nJump);
    iTurnF = repmat(cellfun(@(x)(x(end)),iTurn),1,nJump);

    % determines the relative distance from the start/end of the frame
    % range to the jump event
    [dT0,dTF] = deal(iTurn0-iJumpT,iJumpT-iTurnF); 
    [dT0(dT0<0),dTF(dTF<0)] = deal(del+1);
    
    % calculates the extent range such that the jump events are neglected
    delP0 = min(del+1,min(dT0,[],2))-1;
    delPF = min(del+1,min(dTF,[],2))-1;
end

% determines the overlap between the start/end of adjacent time bands
[i0,i1] = deal(cellfun(@(x)(x(1)),iTurn),cellfun(@(x)(x(end)),iTurn));
di = (i0(2:end)-i1(1:end-1))/2;

% ensures that there isn't any overlap between adjacent time bands
delP0 = min(delP0,min(del,[del;ceil(di)]));
delPF = min(delPF,min(del,[floor(di);del]));

% sets the indices of the frames surrounding the turn events
indT = cellfun(@(x,d1,d2)(max(1,(x(1)-d1)):min(nFrm,(x(end)+d2))),...
                        iTurn,num2cell(delP0),num2cell(delPF),'un',0);

% determines the location of the fly at the start of the time band, and the
% number of time the fly crosses the inner/outer boundary
p0 = cellfun(@(x)(onEdge(x(1))),indT);
iTurn0 = cellfun(@(x)(x(1)),iTurn);
nCross = cellfun(@(x)(sum(abs(diff(onEdge(x))))),indT); 

% turn classification - convention
% =1 - in-in
% =2 - out-out
% =3 - in-out
% =4 - out-in
% =5 - multi (in start)
% =6 - multi (out start)
tTurn = 2*min(nCross,2) + (p0 + 1);

% sets the classification data into a single array
% col 1 - start frame of turn event
% col 2 - turn angle
% col 3 - displacement during turn event
% col 4 - duration of turn event
[cTurn,indTF] = deal(cell(1,6));
for i = 1:length(cTurn)
    ii = (tTurn == i);
    cTurn{i} = [iTurn0(ii),pTurn(ii),dTurn(ii),dtTurn(ii)];
    indTF{i} = indT(ii);
end

% --- calculates the turn event properties (turn time, indices and angle)
function [dtTurn,iTurn,pTurn,dTurn,ok] = ...
                calcTurnProps(pP,pT,pD,iFrm,cP,nFrm,dpMin,isNorm,h)
            
% global variables
global wOfs            
            
% initialisations          
try
    [nTurn,ok] = deal(length(iFrm),true);     
    [iW,isW] = setupWaitbarArrays(nTurn);
catch
    ok = false;
    [dtTurn,iTurn,pTurn,dTurn] = deal([]);
    return
end
            
% calculates the limits of the normal turn events 
tTurn = zeros(nTurn,2);
for k = 1:nTurn
    % updates the waitbar figure
    iFound = find(k >= iW,1,'last');
    if (~isW(iFound))
        % updates the index array
        isW(iFound) = true;        
        
        % updates the waitbar figure
        wStrNw = sprintf('%s (%i%s Complete)',...
                                h.wStr{3},roundP(100*k/nTurn),char(37));
        if h.Update(3+wOfs,wStrNw,0.4*(isNorm+k/nTurn))
            % if the user cancelled, then exit the function
            ok = false;
            [dtTurn,iTurn,pTurn,dTurn] = deal([]);
            return
        end    
    end
        
    % determines the turn event time limits
    tTurn(k,:) = detTurnEventLimits(pP,nFrm,iFrm{k},dpMin);                
end

% updates waitbar figure
if isNorm
    h.Update(3+wOfs,'Calculating Turn Angles',0.85); 
end

% calculates the angle of the turn
tTurnT = num2cell(tTurn,2);
pTurn = cellfun(@(x)(integral(@(y)(ppval(pP,y)),x(1),x(2))),tTurnT);     

% for normal turn events determine if turns can be combined, and removes
% any turn events where the turn angle is too small
if isNorm
    % parameters
    tTol = 0.5;   
        
    % calculates the time between turn events and the direction of the turn
    if size(tTurn,1) > 1
        dtTurn = tTurn(2:end,1) - tTurn(1:end-1,2);
        spTurn = sign(pTurn(2:end)).*sign(pTurn(1:end-1));

        % determines which turn events are close enough to be combined and
        % have the same turn direction (i.e. slight pause within a turn
        % that can be removed)
        iComb = find((dtTurn < tTol) & (spTurn == 1));
        nTurn = length(iComb);    
        for i = nTurn:-1:1               
            % sets the global and reset indices
            j = iComb(i);
            k = [(1:j),(j+2:size(tTurn,1))];

            % combines the frame indices, turn time/angle for the turn events
            iFrm{j} = iFrm{j}(1):iFrm{j+1}(end);
            tTurn(j,2) = tTurn(j+1,2);
            pTurn(j) = integral(@(y)(ppval(pP,y)),tTurn(j,1),tTurn(j,2));

            % resets the overall arrays
            [iFrm,tTurn,pTurn] = deal(iFrm(k),tTurn(k,:),pTurn(k));
        end
    end

    % removes all of the turn events which does not exceed threshold
    isOK = abs(pTurn) > cP.dPhiTol;
    [iTurn,pTurn,tTurn] = deal(iFrm(isOK),pTurn(isOK),tTurn(isOK,:));   
else
    % otherwise, just set the index array
    iTurn = iFrm;
end
    
% calculates the average speed of the turn
dTurn = cellfun(@(x)(integral(@(y)(ppval(pD,y)),x(1),x(2))),num2cell(tTurn,2));
dtTurn = cellfun(@(x)(diff(ppval(pT,x))),num2cell(tTurn,2));

% --- determines the outer region entry statistics
function [eStats,ePr] = detCrossStats(pPhi,pPhiC,X,Y,onEdge,Br,rTol,sFac,isExit)

% parameters and initialisations
[eStats,ePr] = deal([]);
[N1,N2,dRTol,nFrm,xi] = deal(5,10,2,length(X),1:length(X));
[dPhiTol,D] = deal((dRTol/(rTol*sFac))*(180/pi),sqrt(X.^2 + Y.^2)*sFac);
[pD,pX,pY] = deal(pchip(xi,D),pchip(xi,X),pchip(xi,Y));

% determines points where the fly enters the inner/outer region. 
if (isExit)
    % case is the exit events
    iGrp = getGroupIndex(onEdge);
else
    % case is the entry events
    iGrp = getGroupIndex(~onEdge);
end
   
% determines if any valid groups were determined
if (isempty(iGrp))
    % if there are no groups, then exit the function
    return
else
    % removes the first group if it incorporates the first video frame 
    if (iGrp{1}(1) == 1); iGrp = iGrp(2:end); end
end

% sets the indices of the points surrounding the 
ind = cellfun(@(x)(max(1,x(1)-N1):min(nFrm,x(1)+N2)),iGrp,'un',0);
ii = ~cellfun(@(x)(any(Br(x))),ind);
[ind,iGrp] = deal(ind(ii),iGrp(ii));

% if there are no valid entry events, then exit the function
if (isempty(ind)); return; end

% determines the point where the fly enters the outer region. from this,
% calculate the orientation angle and circumferential angle 
pCross = zeros(length(ind),1);
[X0,Y0,xPhiC,iFrm0] = deal(cell(length(ind),1));
for k = 1:length(ind)
    % determines the cross-over points
    [iFrmB,iFrm0{k}] = deal(iGrp{k}(1)+[-1 0],find(ind{k}==iGrp{k}(1)));
    tCross = fminbnd(@(x) abs(ppval(pD,x)-rTol),iFrmB(1),iFrmB(2));

    % calculates the orientation angle and circumferential angle at
    % the point of cross over
    [X0{k},Y0{k}] = deal(ppval(pX,tCross),ppval(pY,tCross));
    [xPhi,xPhiC{k}] = deal(ppval(pPhi,tCross),ppval(pPhiC,tCross));
    pCross(k) = calcAngleDifference(xPhi,xPhiC{k})*180/pi;
end

% calculates the rotated edge coordinates
ePr = cellfun(@(x,x0,y0,phiC)(rotateEdgeCoord(...
            [X(x),Y(x)],[x0,y0],phiC,-1,1)),ind,X0,Y0,xPhiC,'un',0);
   
% ensures the final coordidnate array has the correct number of points
kk = find(cellfun(@(x)(x(1)==1),ind));
for i = reshape(kk,1,length(kk))
    ePr{i} = [NaN((N1+N2+1)-length(ind{i}),2);ePr{i}];
end

% ensures the final coordidnate arrays have the correct number of points
kk = find(cellfun(@(x)(x(end)==nFrm),ind));
for i = reshape(kk,1,length(kk))
    ePr{i} = [ePr{i};NaN((N1+N2+1)-length(ind{i}),2)];
end
    
% applies the orientation multipliers
mlt = num2cell(sign(pCross));
ePr = cellfun(@(x,y)([y*x(:,1),x(:,2)+rTol]*sFac),ePr,mlt,'un',0);

% calculates the relative circumferential angle of the rotated coordinates
PhiC = cellfun(@(x)(atan2(x(:,1),x(:,2))*180/pi),ePr,'un',0);

% eStats Array Convention
%  - col 1 = outer region entry movement type
%     = 1 - stopped
%     = 2 - turn & leave
%     = 3 - continued
%     = 4 - altered
%  - col 2 = orientation angle at point of exit
%  - col 3 = number of frames where fly is within inner region

if (isExit)
    % memory allocation
    eStats = NaN(length(ind),3);
    for i = 1:length(ind)
        % sets the local/global indices for the current group
        if (abs(pCross(i)) <= 90)
            ii = iFrm0{i}:length(ind{i});
            jj = ind{i}(ii);

            % sets the relative position flag and edge orientation angle 
            eStats(i,2:3) = [pCross(i),sum(~onEdge(jj))];

            % calculates the maximum displacement over the frames where the
            % fly has entered the outer region
            if (max(abs(PhiC{i})) < dPhiTol)
                % the fly has reached the outer region and stopped
                eStats(i,1) = 1 + (eStats(i,3) > 0);
            else
                % calculates the circumferential angle difference over all
                % of the frames within the post-edge sequence
                Qd = sign(PhiC{i}(ii)).*(abs(PhiC{i}(ii))>dPhiTol).*D(jj);
                eStats(i,1) = 3 + (sign(nanmean(Qd(abs(Qd)>0))) > 0);                 
            end
        end
    end

    % removes any non-feasible events
    ii = ~isnan(eStats(:,1));
    [eStats,ePr] = deal(eStats(ii,:),ePr(ii));
else
    % sets the exit angle
    eStats = pCross;
end

% -------------------------------------------- %
% --- DIRECTION CHANGE DETECTION FUNCTIONS --- %
% -------------------------------------------- %

% --- determines the directional changes of a fly in the outer region
function dcStats = detDirChange(dT,PhiC,Phi,onEdge)

% parameters and initialisations
[d2r,iGrp,dcStats] = deal(180/pi,getGroupIndex(onEdge),[]);

% calculates the difference 
dPhi = calcAngleDifference(PhiC,Phi)*d2r;
dPhiN = mod(dPhi+180,180);
Q = (1 - abs(dPhiN-90)/90).*sign(dPhi); 

% determines the frames/duration of the directional changes
indDC = cellfun(@(x)(detGroupDirChange(Q(x),dT,x)),iGrp,'un',0);
[ii,nDC] = deal(find(~cellfun(@isempty,indDC)),cellfun(@(x)(size(x,1)),indDC));

% if there are no events detected, then exit the function
if (isempty(ii)); return; end

% sets the directional change stats for each event
[dcStats,i0] = deal(zeros(sum(nDC),4),0);
for i = 1:length(ii)
    for j = 1:nDC(ii(i))
        % sets the global array index
        k = i0 + j;
        
        % sets the directional change stats
        dcStats(k,1:2) = indDC{ii(i)}(j,:);        
        if (j == 1)
            % direction change follows moving into the outer region
            dcStats(k,3:4) = [sum(dT(iGrp{ii(i)}(1):dcStats(k,1))),0];
        else
            % direction change follows another directional change
            dTnw = sum(dT(dcStats(k-1,1):dcStats(k,1))) - dcStats(k-1,2);
            dcStats(k,3:4) = [dTnw,1];            
        end
    end
    
    % increments the counter
    i0 = i0 + nDC(ii(i));
end

% --- determines the location(s) of any potential directional changes
function indDC = detGroupDirChange(Q,dT,iFrm)

% parameters
[Qtol,indDC,nSm,nChngMx] = deal(2/3,[],5,3);

% thresholds the Q-values 
iGrp = [getGroupIndex(Q > Qtol);getGroupIndex(-Q > Qtol)];
if (length(iGrp) > 1)
    % if there is more than one threshold grouping, then sort the groupings
    % by chronological order
    [~,iSort] = sort(cellfun(@(x)(x(1)),iGrp));
    iGrp = iGrp(iSort);
    
    % determines the sign of the Q-values within each group
    [sQ,nGrp] = deal(cellfun(@(x)(sign(Q(x(1)))),iGrp),length(iGrp));
    [ii,sQL] = deal([(1:nGrp-1)',(2:nGrp)'],[sQ(1:end-1),sQ(2:end)]);
    
    % determines if there are any groupings with a change in sign
    jj = find(prod(sQL,2) == -1);
    if (~isempty(jj))
        % if so, determine the frames where sign change occurs
        indDC = NaN(length(jj),2);
        for i = 1:size(indDC,1)
            % sets the frames for the directional change phase
            jFrm = iGrp{ii(jj(i),1)}(end):iGrp{ii(jj(i),2)}(1);
            if (length(jFrm) == 2)
                % directional change is immediate (i.e., about face)
                indDC(i,:) = [iFrm(jFrm(1)),1];
            else
                % otherwise, smooth the intermeditary signal and determines
                % if the directional change is approx continuous
                Qsm = smooth(Q(jFrm),min(nSm,length(jFrm)));
                if (sum(diff(sign(diff(Qsm))) ~= 0)/2 <= nChngMx)
                    % if so, then set the turn statistics
                    indDC(i,:) = [iFrm(jFrm(1)),sum(dT(jFrm))];
                end
            end
        end
        
        % removes any non-feasible direction change events
        indDC = indDC(~isnan(indDC(:,1)),:);
    end
end

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- rotates the edge coordinates around the point where the fly first
%     leaves the edge region, P0
function Pr = rotateEdgeCoord(P,P0,Phi,mlt,varargin)

%
[Xr,Yr] = rotateCoords(P(:,1)-P0(1),P(:,2)-P0(2),Phi+mlt*pi/2);
if (nargin == 4)
    Pr = {Xr,Yr,find((P(:,1)==P0(1)) & (P(:,2)==P0(2)))};
else
    Pr = [Xr,Yr];
end

% --- calculates the orientation angles for entry/exit of the outer region
function [pEntry,pExit] = detCrossAngles(X,Y,Phi,onEdge,indT,rTol)

%
pCross = cell(4,1);
[xi,D,PhiC] = deal(1:length(X),sqrt(X.^2+Y.^2),unwrap(atan2(Y,X)));
[pPhi,pPhiC,pD] = deal(pchip(xi,Phi),pchip(xi,PhiC),pchip(xi,D));

%
for i = 3:length(indT)
    % memory allocation
    pCross{i-2} = cell(length(indT{i}),1);
    
    %
    for j = 1:length(indT{i})
        % sets the frame indices of the turn event
        iFrm = indT{i}{j};
                
        %
        iCross = find(diff(onEdge(iFrm)) ~= 0);  
        pNew = zeros(length(iCross),5);
        
        % determines the time points where the fly crosses the outer
        % boundary. from this calculate the entry/exit 
        for k = 1:length(iCross)
            % determines the cross-over points
            iFrmB = iFrm(iCross(k) + [0 1]);
            tCross = fminbnd(@(x) abs(ppval(pD,x)-rTol),iFrmB(1),iFrmB(2));
            
            % calculates the orientation angle and circumferential angle at
            % the point of cross over
            [xPhi,xPhiC] = deal(ppval(pPhi,tCross),ppval(pPhiC,tCross));
            pNew(k,1) = calcAngleDifference(xPhi,xPhiC)*180/pi;
            pNew(k,2:end) = [onEdge(iFrmB(1)),i,j,k];
        end
        
        % sets the new values for the current turn event
        pCross{i-2}{j} = pNew;
    end
    
    % combines the individual exit/entry turns into a single array
    if (~isempty(pCross{i-2}))
        pCross{i-2} = cell2mat(pCross{i-2});
    end
end

%
ii = ~cellfun(@isempty,pCross);
if (any(ii))
    pCross = cell2mat(pCross(ii));
    iEntry = pCross(:,2) == 0;
    [pEntry,pExit] = deal(pCross(iEntry,:),pCross(~iEntry,:));
else
    [pEntry,pExit] = deal([]);
end