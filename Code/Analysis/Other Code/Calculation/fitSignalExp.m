% --- calculates the double-exponential fits to the signals, Y --- %
function [p,Yfit,gof] = fitSignalExp(T,Y,cP)

% sets the exponential calculation type to single (if not provided)
if (nargin < 3); cP = struct('useDouble',false); end

% runs the function recursively if the Y data array is a cell array
if iscell(Y)
    % memory allocation
    [p,Yfit,gof] = deal(cell(length(Y),1));
    
    % runs the exponential fitting calculations over each group
    for i = 1:length(Y)
        [p{i},Yfit{i},gof{i}] = fitSignalExp(T,Y{i},cP);
    end
    
    % exits the function
    return
end

% memory allocation
[nT,nSig] = size(Y);
[yTol,pTol] = deal(cP.ignoreWeak*cP.pWeak,0.2);
[b,c] = deal(NaN,NaN(1,2));

% struct memory allocation
a = struct('yMax',b,'yMaxR',b,'HW',b,'Tmax',b,...
           'Tofs',b,'kA',c,'kI1',c,'kI2',c,'yInf',c);
b = struct('sse',NaN,'rsquare',NaN,'dfe',NaN,'adjrsquare',NaN,'rmse',NaN);
[p,Yfit,gof] = deal(repmat(a,[nSig,1]),cell(nSig,1),cell(nSig,1));

% fits all signals with exponentials (depending on type)
for i = 1:nSig    
    % if the signal is too weak, then remove the signal
    if (sum(abs(Y(:,i)))/length(T) < yTol) || (mean(Y(:,i) == 0) > pTol)
        Y(:,i) = NaN;
    end

    % check to see if the signal is feasible
    if ~all(isnan(Y(:,i)))
        % removes any NaN values from the signal
        ii = ~isnan(Y(:,i));                
        
        % if so, then fit the exponential function to the data
        if cP.useDouble
            % case is using a double exponential
            [pExp,g,gof{i},Ysgn,ok] = fitDoubleExp(T(ii),Y(ii,i),cP.useToff);                                        
        else
            % case is fitting a single exponential
            [pExp,g,gof{i},Ysgn,ok] = fitSingleExp(T(ii),Y(ii,i),cP.useToff);
        end                     
        
        % calculates the exponential fit and sets the fitted parameters
        if ok
            Yfit{i} = calcFittedValues(g,pExp,T,Ysgn);
            p(i) = setExpParameters(p(i),pExp,T,Yfit{i},Y(:,i),Ysgn);    
        else
            [Yfit{i},gof{i}] = deal(NaN(length(T),1),b);
        end        

        % ensures the r2 values are non-negative
        gof{i}.rsquare = max(0,gof{i}.rsquare);
        gof{i}.adjrsquare = max(0,gof{i}.adjrsquare);
    else
        % otherwise, set a NaN array
        [Yfit{i},gof{i}] = deal(NaN(nT,1),b);
    end
end

% converts the cell array to a numerical array
[Yfit,gof] = deal(cell2mat(Yfit'),cell2mat(gof));

% ----------------------------------------------------------------------- %
% ---                   EXPONENTIAL FITTING FUNCTIONS                 --- %
% ----------------------------------------------------------------------- %

% --- fits a single activation/inactivation exponential to Y --- %
function [pExp,g,gof,Ysgn,ok] = fitSingleExp(T,Y,useTofs)

% memory allocations
[ok,N,k,ix,pTol,cont] = deal(true,50,-log(2)/500,1:2,1e-3,true);
[iter,itermx,jj] = deal(1,5,1:(4+useTofs));

% if there is no signal, then exit the function with empty arrays
if all(Y == 0)
    [pExp,g,gof,ok] = deal([],[],[],false); return; 
end

% sets the initial parameter estimate and lower/upper bounds
[Yamp,YampL,YampU,~,imx,Ysgn] = detAmplitudeLimits(Y);
Y = Y*Ysgn;

%
Ymin = min(Y(imx:end));
NN = find(Y(imx:end) < (Ymin+(Yamp-Ymin)*exp(-1)),1,'first');

% estimation of the inactivation time constant
Ys = smooth(Y,2*N);
kI10 = calcInitTauEst(Ys((imx+1):min(length(Ys),imx+NN)));

% sets the amplitude limits (based on sign)
[A10,A1L,A1U] = deal(0.5,0.0,1.0);

% sets the initial parameter estimate and lower/upper bounds
x0 = [     1    kI10  A10  Yamp 1e-4];
xL = [ 0.005 kI10/20  A1L YampL 0];
xU = [  1000 kI10*20  A1U YampU T(imx)];
[x0,xL,xU] = deal(x0(jj),xL(jj),xU(jj));

% swaps any limits where the lower limit exceeds the upper limit
ii = xL > xU;
if any(ii)
    [xU(ii),xL(ii)] = deal(xL(ii),xU(ii));
end
    
% ensures the time-shift is within a reasonable range
if T(imx) > xU(1)
    [x0(end),xU(end)] = deal(75,100);
end

% sets the function fit-type  
if useTofs
    g = fittype('A0*(1-exp(-(x-dT)/kA))*(1-A1*(1-exp(-(x-dT)/kI1)))*Hside(x-dT)',...
                'coeff',{'kA','kI1','A1','A0','dT'});     
else
    g = fittype('A0*(1-exp(-x/kA))*(1-A1*(1-exp(-x/kI1)))',...
                'coeff',{'kA','kI1','A1','A0'}); 
end

% sets the exponential weights
W = exp(k*T); W = W/sum(W);

% sets the fit options struct
while cont
    % sets the fit options
    fOpt = fitoptions('method','NonlinearLeastSquares','Lower',xL,...
                      'Upper',xU,'StartPoint',x0,'MaxFunEvals',1e10,...
                      'MaxIter',1e10,'Weights',W);          
                   
    try
        % runs the solver
        [pExp,gof] = fit(T,Y,g,fOpt);
        x0 = coeffvalues(pExp);

    catch ME
        % if there was an error (and the offset was used), then revert the
        % model back to a non-offset model
        if strcmp(ME.identifier,'curvefit:fit:nanComputed') && useTofs
            g = fittype('A0*(1-exp(-x/kA))*(1-A1*(1-exp(-x/kI1)))',...
                        'coeff',{'kA','kI1','A1','A0'});  
            [x0,xL,xU] = deal(x0(1:end-1),xL(1:end-1),xU(1:end-1));
        else
            rethrow(ME)
        end
    end
    
    % calculates the coefficent values relative to the bounds   
    dx = (xU(ix)-xL(ix));
    [dpp,cont] = deal((x0(ix)-xL(ix))./dx,false);
    
    % determines if the parameters are within range of the bounds. if so,
    % then reset the initial value and restart the 
    for i = ix
        if dpp(i) < pTol
            % parameter is too close to the lower bound
            [xL(i),cont] = deal(max(0,x0(i)-dx(i)/2),1);
            xU(i) = 2*x0(i)-xL(i);
            
        elseif dpp(i) > (1-pTol)
            % parameter is too close to the upper bound 
            [xU(i),cont] = deal(x0(i)+dx(i)/2,1);
            xL(i) = 2*x0(i)-xU(i);
        end
    end
    
    % increments the iteration counter. if greater than max, then exit loop
    iter = iter + 1;
    if (iter > itermx); cont = false; end    
end

if ~isempty(lastwarn)
    a = 1;
end
    
% --- fits a single activation/inactivation exponential to Y --- %
function [pExp,g,gof,Ysgn,ok] = fitDoubleExp(T,Y,useTofs)

% memory allocations
[ok,N,k,ix,pTol,cont] = deal(true,50,-log(2)/500,1:3,1e-3,true);
[iter,itermx,jj] = deal(1,5,1:(6+useTofs));

% if there is no signal, then exit the function with empty arrays
if all(Y == 0)
    [pExp,g,ok] = deal([],[],false); return; 
end

% estimate pre-calculations
[Yamp,YampL,YampU,~,imx,Ysgn] = detAmplitudeLimits(Y);
Y = Y*Ysgn;
NN = find(Y(imx:end) < (Yamp-min(Y))*exp(-1),1,'first');    

% estimation of the inactivation time constant
Ys = smooth(Y,2*N);
kI10 = calcInitTauEst(Ys((imx+1):min(length(Ys),imx+NN)));

% sets the lower/upper bounds and initial estimate
x0 = [    1      kI10  kI10*2.5 0.5*[1 1] Yamp/1.5 1e-4];
xL = [ 0.01 kI10/50.0  kI10*5.0   0*[1 1]    YampL 0];
xU = [ 1000  kI10*2.5 kI10*20.0   1*[1 1]    YampU T(imx)];
[x0,xL,xU] = deal(x0(jj),xL(jj),xU(jj));

% swaps any limits where the lower limit exceeds the upper limit
ii = xL > xU;
if any(ii)
    [xU(ii),xL(ii)] = deal(xL(ii),xU(ii));
end

% ensures the time-shift is within a reasonable range
if T(imx) > xU(1)
    [x0(end),xU(end)] = deal(75,100);
end

% sets the fit options struct
W = exp(k*T); W = W/sum(W);
if useTofs
    g = fittype('A0*(1-exp(-(x-dT)/kA))*(1-A1*(1-exp(-(x-dT)/kI1)))*(1-A2*(1-exp(-(x-dT)/kI2)))*Hside(x-dT)',...
                'coeff',{'kA','kI1','kI2','A1','A2','A0','dT'}); 
else
    g = fittype('A0*(1-exp(-x/kA))*(1-A1*(1-exp(-x/kI1)))*(1-A2*(1-exp(-x/kI2)))',...
                'coeff',{'kA','kI1','kI2','A1','A2','A0'});     
end
        
% sets the fit options struct
while cont
    % sets the fit options
    fOpt = fitoptions('method','NonlinearLeastSquares','Lower',xL,...
                      'Upper',xU,'StartPoint',x0,'MaxFunEvals',1e10,...
                      'MaxIter',1e10,'Weights',W);          
                   
    try
        % runs the solver
        [pExp,gof] = fit(T,Y,g,fOpt);
        x0 = coeffvalues(pExp);
        
    catch ME
        % if there was an error (and the offset was used), then revert the
        % model back to a non-offset model
        if strcmp(ME.identifier,'curvefit:fit:nanComputed') && useTofs
            g = fittype('A0*(1-exp(-x/kA))*(1-A1*(1-exp(-x/kI1)))*(1-A2*(1-exp(-x/kI2)))',...
                'coeff',{'kA','kI1','kI2','A1','A2','A0'});
            [x0,xL,xU] = deal(x0(1:end-1),xL(1:end-1),xU(1:end-1));
        else
            rethrow(ME)
        end
    end    
    
    % calculates the coefficent values relative to the bounds   
    dx = (xU(ix)-xL(ix));
    [dpp,cont] = deal((x0(ix)-xL(ix))./dx,false);
    
    % determines if the parameters are within range of the bounds. if so,
    % then reset the initial value and restart the 
    for i = ix
        if dpp(i) < pTol
            % parameter is too close to the lower bound
            [xL(i),cont] = deal(max(0,x0(i)-dx(i)/2),1);
            xU(i) = 2*x0(i)-xL(i);
            
        elseif dpp(i) > (1-pTol)
            % parameter is too close to the upper bound 
            [xU(i),cont] = deal(x0(i)+dx(i)/2,1);
            xL(i) = 2*x0(i)-xU(i);
        end
    end
    
    % resets the lower/upper limits (so they don't overlap)
    if xU(2) > xL(3)
        [xU(2),xL(3)] = deal(0.5*(xU(2)+xL(3)));        
        if (xU(2) < xL(2)); [xL(2),xU(2)] = deal(xU(2),xL(2)); end
        if (xU(3) < xL(3)); [xL(3),xU(3)] = deal(xU(3),xL(3)); end
    end
    
    % increments the iteration counter. if greater than max, then exit loop
    iter = iter + 1;
    if (iter > itermx); cont = false; end
end

% ----------------------------------------------------------------------- %
% ---                          OTHER FUNCTIONS                        --- %
% ----------------------------------------------------------------------- %

% --- determines the amplitude limits for the optimisation solver --- %
function [Yamp,YampL,YampU,Yinf,imx,Ysgn] = detAmplitudeLimits(Y)

% initialisations
[ii,W] = deal(1:floor(length(Y)/2),exp(-log(2)*(1:length(Y))'/50));
[YpkMx,kmx] = findpeaks(Y(ii));
[YpkMn,kmn] = findpeaks(-Y(ii));

% calculates the weighted min/max values
[YpkMxT,kmxT] = max(W(kmx).*YpkMx);
[YpkMnT,kmnT] = min(-W(kmn).*YpkMn);

% determines the overall min/max values
if isempty(YpkMnT) || (YpkMxT > -YpkMnT)
    % peak signal value is positive
    [Ymax,imx,Ysgn] = deal(YpkMxT,kmx(kmxT),1);
else
    % peak signal value is negative
    [Ymax,imx,Ysgn] = deal(YpkMnT,kmn(kmnT),-1);
end
    
% sets the steady-state and maximum value
Yinf = mean(Y(floor(length(Y)/2):end),'omitnan');

% signal is negative, so set the lower limit to zero
[Yamp,YampL,YampU] = deal(Ymax,0,10*Ymax);

% --- sets the final exponential values into the 
function p = setExpParameters(p,pExp,T,Yexp,Y,Ysgn)

% parameters
[Ymin,del] = deal(0.01,10);  

% other initialisations
[pStr,cStr] = deal(fieldnames(p),coeffnames(pExp));
ii = cellfun(@(x)(find(strcmp(cStr,x))),pStr,'un',0);
useDouble = any(strcmp(cStr,'A2'));

% sets the indices of the parameters and scale factors
indP = cell2mat(ii(~cellfun('isempty',ii)));

% retrieves the coefficient values and confidence intervals
[pp,ppSEM] = deal(coeffvalues(pExp),diff(confint(pExp),[],1)/(2*1.96));
% ppSEM(ppSEM > pp) = NaN;

% determines if the signal is feasible (activation time constants > 0)
if isnan(pp(1))
    % if not, then set all parameter values to NaNs
    fStr = fieldnames(p);
    for i = 1:length(fStr)
        eval(sprintf('p.%s = NaN;',fStr{i}));
    end
    
    % exits the function
    return
end

% sets the new search values (for the amplitude calculations)
tLim = [0 max(30,ceil(10*pp(1)))] + [0 pp(end)];
if Ysgn > 0
    Yraw = max(Y((T >= tLim(1)) & (T <= tLim(2))));
else
    Yraw = min(Y((T >= tLim(1)) & (T <= tLim(2))));
end

%
[A0,A1,A2] = deal(pp(strcmp(cStr,'A0')),pp(strcmp(cStr,'A1')),0);
if (useDouble)
    A2 = pp(strcmp(cStr,'A2'));
    if (A2 < 1e-6)
        pp(strcmp(cStr,'kI2')) = 0;
    end
end

% removes the steady state component from the signal
[yInf,isMax] = deal(A0*(1-A1)*(1-A2),true);
if (Ysgn > 0)
    % signal is positive
    [Ymx,imx] = max(Yexp); YmxR = max(Yraw); 
    Yexp = Yexp - yInf; Yexp(Yexp<0) = 0;
else
    % signal is negative
    [Ymx,imx] = max(abs(Yexp)); YmxR = max(abs(Yraw));
    [Yexp,isMax] = deal(Yexp - yInf,false); Yexp(Yexp>0) = 0;
end

% calculates the index band within the signal is less than half the signal
% amplitude (with the s/s removed) which corresponds
if (imx == length(Yexp)) || (Ymx < Ymin) || (all(Yexp == 0))
    HW = NaN;
else    
    % removes the offset from the signal               
    [~,indTmp] = calcSignalExtremum(Yexp,(Ymx - yInf)/2);
    HW = diff(T(indTmp));        
end

% sets the exponential parameters
[p.yMax,p.yMaxR,p.HW] = deal(Ysgn*Ymx,Ysgn*YmxR,HW/60);

% sets the parameter/SEM values
for i = 1:length(indP)
    if strcmp(cStr{indP(i)}(1),'k')
        % case is a time constant parameter    
        p.(cStr{indP(i)})(1) = pp(indP(i))/60;
        p.(cStr{indP(i)})(2) = ppSEM(indP(i))/60;
    else
        % case is a scale factor
        p.(cStr{indP(i)})(1) = pp(indP(i));
        p.(cStr{indP(i)})(2) = ppSEM(indP(i));        
    end
end
    
% calculates the time to max response
if isMax
    % case is determining the maximum point from the signal
    Tex = T(argMax(Yexp));
    ii = Tex + (-del:del); ii = ii((ii > 0) & (ii <= length(Y)));
    imxR = argMax(Y(ii)) - 1;
else
    % case is determining the minimum point from the signal
    Tex = T(argMin(Yexp));
    ii = Tex + (-del:del); ii = ii((ii > 0) & (ii <= length(Y)));
    imxR = argMin(Y(ii)) - 1;    
end

% sets the final values
[p.Tmax,p.yInf] = deal(T(imxR + ii(1))/60,yInf);
if any(strcmp(fieldnames(pExp),'dT')); p.Tofs = pExp.dT; end

% --- calculates the initial time constant estimate
function k0 = calcInitTauEst(Y)

% creates a linear fit of the sub-sequence
wState = warning('off','all');
P = polyfit((1:length(Y))',log(Y-(min(Y)-1)),1);
warning(wState);

% calculates an estimate of the time constant
if P(1) < 0
    % linear component is valid, so calculate from the gradient
    k0 = -1/P(1);
else
    % linear component is invalid, so set a fixed value
    k0 = 1000;
end
