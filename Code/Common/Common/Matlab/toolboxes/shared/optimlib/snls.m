function [xcurr,fvec,LAMBDA,JACOB,EXITFLAG,OUTPUT,msgData] = snls(funfcn,xstart,l,u,verb,options, ...
    defaultopt,fval,JACval,caller,Jstr,computeLambda,mtxmpy,detailedExitMsg,optionFeedback,finDiffFlags,varargin)
%

%SNLS  Sparse nonlinear least squares solver.
%   
% Locate a local solution to the box-constrained nonlinear 
% least-squares problem:
%
%              min { ||F(x)||^2 :  l <= x <= u }
%
% where F:R^n -> R^m, m > n, and || || is the 2-norm.
%
% x=SNLS(fname,xstart) solves the unconstrained nonlinear least
% squares problem. The vector function is 'fname' and the
% starting point is xstart. 
%
% x=SNLS(fname,xstart,options) solves the unconstrained or
% box constrained nonlinear least squares problem. Bounds and
% parameter settings are handled through the named parameter list
% options.
%
% x=SNLS(fname,xstart,options,Jstr) indicates the structure
% of the sparse Jacobian matrix -- sparse finite differencing
% is used to compute the Jacobian when Jstr is not empty.
%
% [x,fvec] =SNLS(fname,xstart, ...)  returns the final value of the
% vector function F.
%
% [x,fvec,gopt] = SNLS(fname,xstart, ...) returns the first-order
% optimality vector.
%
% [x,fvec,gopt,iter] = SNLS(fname,xstart, ...) returns the number of
% major iterations used.
%
% [x,fvec,gopt,iter,npcg] =  SNLS(fname,xstart, ...) returns the
% total number of CG iterations used.
%
% [x,fvec,gopt,iter,npcg,ex] = SNLS(fname,xstart, ...) returns the 
% termination code.

%   Copyright 1990-2012 The MathWorks, Inc.

% Check to see if the function vector or the user-supplied Jacobian at the initial point are well-defined.
% If not, then terminate immediately.
if any(~isfinite(fval)) 
    error(message('optimlib:snls:UsrObjUndefAtX0', caller));    
end
if any(~isfinite(nonzeros(JACval)))
    error('optimlib:snls:UserJacUndefAtX0', ...
        getString(message('optimlib:commonMsgs:JacUndefAtX0',caller)));
end
%   Extract input parameters etc.
l = l(:); u = u(:);
% save shape of xstart for user function
[sizes.xRows,sizes.xCols] = size(xstart);
xcurr = xstart;  
xstart = xstart(:);  % make it a vector

%   Initialize
msgData = {};
dnewt = [];
n = length(xstart); 
iter = 0;  
numFunEvals = 1;  % done in calling function lsqnonlin
numGradEvals = 1; % done in calling function
header = sprintf(['\n                                         Norm of      First-order \n',...
        ' Iteration  Func-count     f(x)          step          optimality']);
formatstrFirstIter = ' %5.0f      %5.0f   %13.6g                  %12.3g';
formatstr = ' %5.0f      %5.0f   %13.6g  %13.6g   %12.3g      %7.0f';

if n == 0, 
   error(message('optimlib:snls:InvalidN'))
end

if isempty(l)
   l = -inf*ones(n,1);
else
    % Some variables are possibly bounded (i.e. lb ~= [])
    arg2 = (l <= -1e10);
    l(arg2) = -inf;
end
if isempty(u)
   u = inf*ones(n,1); 
else
    % Some variables are possibly bounded (i.e. ub ~= [])
   arg = (u >= 1e10); 
   u(arg) = inf;
end

if any(u == l)
   error(message('optimlib:snls:EqualBounds'))
elseif min(u-l) <= 0
   error(message('optimlib:snls:InconsistentBounds'))
end

%
numberOfVariables = n;
% Read in user options
% Add ActiveConstrTol and Preconditioner to defaultopt. These are not
% documented options, and are not added to defaultopt at the user-facing
% function level.
defaultopt.ActiveConstrTol = sqrt(eps);
defaultopt.Preconditioner = @aprecon;

active_tol = optimget(options,'ActiveConstrTol',defaultopt,'fast');
pcmtx = optimget(options,'Preconditioner',defaultopt,'fast');

gradflag =  strcmp(optimget(options,'Jacobian',defaultopt,'fast'),'on');
pcflags = optimget(options,'PrecondBandWidth',defaultopt,'fast') ;
tol2 = optimget(options,'TolX',defaultopt,'fast') ;
tol1 = optimget(options,'TolFun',defaultopt,'fast') ;
itb = optimget(options,'MaxIter',defaultopt,'fast') ;
maxfunevals = optimget(options,'MaxFunEvals',defaultopt,'fast') ;
pcgtol = optimget(options,'TolPCG',defaultopt,'fast') ;  % pcgtol = .1;
kmax = optimget(options,'MaxPCGIter',defaultopt,'fast') ;

if ischar(kmax)
   if isequal(lower(kmax),'max(1,floor(numberofvariables/2))')
      kmax = max(1,floor(numberOfVariables/2));
   else
      error(message('optimlib:snls:InvalidMaxPCGIter'))
   end
end
if ischar(maxfunevals)
   if isequal(lower(maxfunevals),'100*numberofvariables')
      maxfunevals = 100*numberOfVariables;
   else
      error(message('optimlib:snls:MaxFunEvals'))
   end
end

% Handle the output
outputfcn = optimget(options,'OutputFcn',defaultopt,'fast');
if isempty(outputfcn)
    haveoutputfcn = false;
else
    haveoutputfcn = true;
    xOutputfcn = xcurr; % Last x passed to outputfcn; has the input x's shape
    % Parse OutputFcn which is needed to support cell array syntax for OutputFcn.
    outputfcn = createCellArrayOfFunctions(outputfcn,'OutputFcn');
end

% Handle the plot functions
plotfcns = optimget(options,'PlotFcns',defaultopt,'fast');
if isempty(plotfcns)
    haveplotfcn = false;
else
    haveplotfcn = true;
    xOutputfcn = xcurr; % Last x passed to outputfcn; has the input x's shape
    % Parse PlotFcns which is needed to support cell array syntax for PlotFcns.
    plotfcns = createCellArrayOfFunctions(plotfcns,'PlotFcns');
end

ex = 0; posdef = 1; npcg = 0; pcgit = 0;

delta = 10;nrmsx = 1; ratio = 0; 
degen = inf; 
x = xstart; oval = inf;
nbnds = 1; Z = [];
if all(isinf(u) & isinf(l))
   nbnds = 0; degen = -1;
end

xcurr(:) = xstart;
% Convert values to full to avoid unnecessary sparse operation overhead
fvec = full(fval);
%   Evaluate F and J
if ~gradflag % use sparse finite differencing
   % Determine coloring/grouping for sparse finite-differencing
   p = colamd(Jstr)'; 
   p = (n+1)*ones(n,1)-p; 
   group = color(Jstr,p);
   xcurr(:) = x;  % reshape x for user function
   % pass in funfcn{3} since we know no gradient: not funfcn{4}
   [A,findiffevals] = sfdnls(xcurr,fvec,Jstr,group,[],funfcn{3},l,u,...
                             options,sizes,finDiffFlags,varargin{:});
   
   if any(~isfinite(nonzeros(A)))
        error('optimlib:snls:DerivUndefAtX0', ...
            getString(message('optimlib:commonMsgs:FinDiffJacUndefAtX0', ...
                              caller)));       
   end
else % user-supplied computation of J or dnewt 
   A = JACval;
   findiffevals = 0;
end % of 'if ~gradflag'
numFunEvals = numFunEvals + findiffevals;

[mm,pp] = size(fvec);
if mm < n, 
   error(message('optimlib:snls:MLessThanN'))
end

%   Extract the Newton direction?
if pp == 2, 
   dnewt = fvec(1:n,2); 
end

%   Determine gradient of the nonlinear least squares function
g = feval(mtxmpy,A,fvec(:,1),-1,varargin{:});

%   Evaluate F (initial point)
val = fvec(:,1)'*fvec(:,1);

%   Display
if verb > 1
    disp(header)
end

% Initialize the output function.
if haveoutputfcn || haveplotfcn
    [xOutputfcn, optimValues, stop] = callOutputAndPlotFcns(outputfcn,plotfcns,caller,x,xOutputfcn,'init',iter, ...
    numFunEvals,fvec,val,[],[],[],pcgit,[],[],[],delta,varargin{:});
    if stop
        [xcurr,fvec,LAMBDA,JACOB,EXITFLAG,OUTPUT] = cleanUpInterrupt(xOutputfcn,optimValues,caller,npcg);
        msgData = {'snls',EXITFLAG,verb > 0,detailedExitMsg,caller};
        return;
    end
end

% Create the fault tolerance structure
faultTolStruct = createFaultTolStruct(false);
newFaultTolStruct = faultTolStruct;

%   Main loop: Generate feas. seq. x(iter) s.t. ||F(x(iter)|| is decreasing.
while ~ex 
         
   % Update 
   [v,dv] = definev(g,x,l,u); 
   gopt = v.*g;
   optnrm = norm(gopt,inf);
   r = abs(min(u-x,x-l));
   degen = min(r + abs(g));
   if ~nbnds 
      degen = -1; 
   end
   % Display
    if verb > 1
        if iter > 0
            if faultTolStruct.undefObj 
                fprintf(getString(message('optimlib:commonMsgs:ObjInfNaNComplex', ...
                    faultTolStruct.undefValue)));
            end                        
            currOutput = sprintf(formatstr,iter,numFunEvals,val,nrmsx,optnrm);
        else
            currOutput = sprintf(formatstrFirstIter,iter,numFunEvals,val,optnrm);
        end
        disp(currOutput);
    end
    
    % OutputFcn call
    if haveoutputfcn || haveplotfcn
        [xOutputfcn,optimValues, stop] = callOutputAndPlotFcns(outputfcn,plotfcns,caller,x,xOutputfcn,'iter',iter, ...
            numFunEvals,fvec,val,nrmsx,g,optnrm,pcgit,posdef,ratio,degen,delta,varargin{:});
        if stop  % Stop per user request.
            [xcurr,fvec,LAMBDA,JACOB,EXITFLAG,OUTPUT] = cleanUpInterrupt(xOutputfcn,optimValues,caller,npcg);
            msgData = {'snls',EXITFLAG,verb > 0,detailedExitMsg,caller};
            return;
        end
    end
    
   %     Test for convergence
   diff = abs(oval-val); 
   oval = val; 
   if ((optnrm < tol1) && (posdef == 1) )
       ex = 1; EXITFLAG = 1;
       if iter == 0
           msgFlag = 100;
       else
           msgFlag = EXITFLAG;
       end
       % Call createExitMsg with createExitMsgExitflag = 100 if x0 is
       % optimal, otherwise createExitMsgExitflag = 1
       msgData = {'snls',msgFlag,verb > 0,detailedExitMsg,caller, ...
           optnrm,optionFeedback.TolFun,tol1};
   elseif (nrmsx < .9*delta) && (ratio > .25) && (diff < tol1*(1+abs(oval)))
       ex = 2; EXITFLAG = 3;
       msgData = {'snls',EXITFLAG,verb > 0,detailedExitMsg,caller, ...
           diff/(1+abs(oval)),optionFeedback.TolFun,tol1};
   elseif (iter > 1) && (nrmsx < tol2),
       ex = 3; EXITFLAG = 2;
       msgData = {'snls',EXITFLAG,verb > 0,detailedExitMsg,caller, ...
           nrmsx,optionFeedback.TolX,tol2};
   elseif iter > itb,
       ex = 4; EXITFLAG = 0;
       msgData = {'snls',10,verb > 0,detailedExitMsg,caller, ...
           [],optionFeedback.MaxIter,itb};
   elseif numFunEvals > maxfunevals
       ex=4; EXITFLAG = 0;
       msgData = {'snls',EXITFLAG,verb > 0,detailedExitMsg,caller, ...
           [],optionFeedback.MaxFunEvals,maxfunevals};
   end

   % Reset fault tolerance structure
   faultTolStruct = newFaultTolStruct;

   %     Continue if ex = 0 (i.e., not done yet)
   if ~ex 
       % Call output functions (we don't call plot functions with
       % 'interrupt' flag)
       if haveoutputfcn  
           [~,~,stop] = callOutputAndPlotFcns(outputfcn,{},caller,x,xOutputfcn,'interrupt',iter, ...
               numFunEvals,fvec,val,nrmsx,g,optnrm,pcgit,posdef,ratio,degen,delta,varargin{:});
           if stop  % Stop per user request.
               [xcurr,fvec,LAMBDA,JACOB,EXITFLAG,OUTPUT] = cleanUpInterrupt(xOutputfcn,optimValues,caller,npcg);
               msgData = {'snls',EXITFLAG,verb > 0,detailedExitMsg,caller};
               return;
           end
       end

      %       Determine the trust region correction
      dd = abs(v); D = sparse(1:n,1:n,full(sqrt(dd)));
      theta = max(.95,1-optnrm);  
      oposdef = posdef;
      [sx,snod,qp,posdef,pcgit,Z] = trdog(x,g,A,D,delta,dv,...
         mtxmpy,pcmtx,pcflags,pcgtol,kmax,theta,l,u,Z,dnewt,'jacobprecon',varargin{:});
      
      if isempty(posdef), 
         posdef = oposdef; 
      end
      nrmsx=norm(snod); 
      npcg=npcg+pcgit; 
      newx=x+sx;
      
      %       Perturb?
      [~,newx] = perturbTrustRegionReflective(newx,l,u);

      xcurr(:) = newx;  % reshape newx for user function
      %       Evaluate F and J
      if ~gradflag %use sparse finite-differencing
         switch funfcn{1}
         case 'fun'
            newfvec = feval(funfcn{3},xcurr,varargin{:});
            newfvec = full(newfvec(:));
         otherwise
            error(message('optimlib:snls:UndefinedCalltype', caller))
         end
         % pass in funfcn{3} since we know no gradient
         [newA, findiffevals] = sfdnls(xcurr,newfvec,Jstr,group,[], ...
                       funfcn{3},l,u,options,sizes,finDiffFlags,varargin{:});
      else % use user-supplied determination of J or dnewt
         findiffevals = 0; % no finite differencing
         switch funfcn{1}
         case 'fungrad'
            [newfvec,newA] = feval(funfcn{3},xcurr,varargin{:});
            numGradEvals=numGradEvals+1;
            newfvec = full(newfvec(:));
         case 'fun_then_grad'
            newfvec = feval(funfcn{3},xcurr,varargin{:});
            newfvec = full(newfvec(:));
            newA = feval(funfcn{4},xcurr,varargin{:});
            numGradEvals=numGradEvals+1;
          otherwise
            error(message('optimlib:snls:UndefinedCalltype', caller))
         end
      end
      numFunEvals = numFunEvals + 1 + findiffevals;
      
      [mm,pp] = size(newfvec);
      if mm < n, 
         error(message('optimlib:snls:MLessThanN'))
      end

      % Calculate objective function value
      newval = newfvec(:,1)'*newfvec(:,1);

      % Update fault tolerance structure
      faultTolStruct = updateFaultTolStruct(faultTolStruct,newval,verb > 1);
      
      % Update trust region radius
      if ~faultTolStruct.currTrialWellDefined
          % Shrink the trust region if any element of the function vector
          % at the new step is not defined (i.e. it's inf/NaN/complex)
          delta = min(nrmsx/20,delta/20);
      else
          newgrad = feval(mtxmpy,newA,newfvec(:,1),-1,varargin{:});
          aug = .5*snod'*((dv.*abs(g)).*snod);
          ratio = (0.5*(newval-val)+aug)/qp;     % we compute val = f'*f, not val = 0.5*(f'*f)
          if (ratio >= .75) && (nrmsx >= .9*delta),
              delta = 2*delta;
          elseif ratio <= .25,
              delta = min(nrmsx/4,delta/4);
          end
      end           
      
      % Accept or reject trial point
      if faultTolStruct.currTrialWellDefined && newval < val
         x = newx; 
         val = newval; 
         g = newgrad; 
         A = newA; 
         Z = [];
         fvec = newfvec;
         
         %          Extract the Newton direction?
         if pp == 2, 
            dnewt = newfvec(1:n,2); 
         end
      end
      iter=iter+1; 
   end % if ~ex
end % while
%

if haveoutputfcn || haveplotfcn
    callOutputAndPlotFcns(outputfcn,plotfcns,caller,x,xOutputfcn,'done',iter, ...
        numFunEvals,fvec,val,nrmsx,g,optnrm,pcgit,posdef,ratio,degen,delta,varargin{:});
    % Optimization done, so ignore "stop"
end

JACOB = sparse(A);     % A is the Jacobian, not the gradient.
OUTPUT.firstorderopt = optnrm;
OUTPUT.iterations = iter;
OUTPUT.funcCount = numFunEvals;
OUTPUT.cgiterations = npcg;
OUTPUT.algorithm = 'trust-region-reflective'; 
xcurr(:)=x;

if computeLambda
   LAMBDA.lower = zeros(length(l),1);
   LAMBDA.upper = zeros(length(u),1);
   argl = logical(abs(x-l) < active_tol);
   argu = logical(abs(x-u) < active_tol);
   
   g = full(g);
   
   LAMBDA.lower(argl) = (g(argl));
   LAMBDA.upper(argu) = -(g(argu));
else
   LAMBDA = [];
end
%--------------------------------------------------------------------------
function [xOutputfcn, optimValues, stop] = callOutputAndPlotFcns(outputfcn,plotfcns,caller,x,xOutputfcn,state,iter, ...
    numFunEvals,fvec,val,nrmsx,g,optnrm,pcgit,posdef,ratio,degen,delta,varargin)
% CALLOUTPUTANDPLOTFCNS assigns values to the struct OptimValues and then calls the
% outputfcn/plotfcns.  
%
% state - can have the values 'init','iter','interrupt', or 'done'. 

% For the 'done' state we do not check the value of 'stop' because the
% optimization is already done.

optimValues.iteration = iter;
optimValues.funccount = numFunEvals;
optimValues.stepsize = nrmsx;
optimValues.gradient = g;
optimValues.firstorderopt = optnrm;
optimValues.cgiterations = pcgit; 
optimValues.positivedefinite = posdef;
optimValues.ratio = ratio;
optimValues.degenerate = min(degen,1);
optimValues.trustregionradius = delta;
if isequal(caller,'fsolve') 
   optimValues.fval = fvec; 
else % lsqnonlin, lsqcurvefit 
   optimValues.residual = fvec; 
   optimValues.resnorm = val; 
end 
xOutputfcn(:) = x;  % Set x to have user expected size
stop = false;
% Call output function
if ~isempty(outputfcn)
    switch state
        case {'iter','init','interrupt'}
            stop = callAllOptimOutputFcns(outputfcn,xOutputfcn,optimValues,state,varargin{:}) || stop;
        case 'done'
            callAllOptimOutputFcns(outputfcn,xOutputfcn,optimValues,state,varargin{:});
        otherwise
            error(message('optimlib:snls:UnknownStateInCALLOUTPUTANDPLOTFCNS'))
    end
end
% Call plot functions
if ~isempty(plotfcns)
    switch state
        case {'iter','init'}
            stop = callAllOptimPlotFcns(plotfcns,xOutputfcn,optimValues,state,varargin{:}) || stop;
        case 'done'
            callAllOptimPlotFcns(plotfcns,xOutputfcn,optimValues,state,varargin{:});
        otherwise
            error(message('optimlib:snls:UnknownStateInCALLOUTPUTANDPLOTFCNS'))
    end
end

%--------------------------------------------------------------------------
function [xcurr,fvec,LAMBDA,JACOB,EXITFLAG,OUTPUT] = cleanUpInterrupt(xOutputfcn,optimValues,caller,npcg)
% CLEANUPINTERRUPT sets the outputs arguments to be the values at the last call
% of the outputfcn during an 'iter' call (when these values were last known to
% be consistent). 

% Call plot function driver to finalize the plot function figure window. If
% no plot functions have been specified or the plot function figure no
% longer exists, this call just returns.
callAllOptimPlotFcns('cleanuponstopsignal');

xcurr = xOutputfcn;
% fvec can be either 'fval' (fsolve) or 'residual'
if isequal(caller,'fsolve') 
    fvec = optimValues.fval;
else
    fvec = optimValues.residual;
end
EXITFLAG = -1; 
OUTPUT.iterations = optimValues.iteration;
OUTPUT.funcCount = optimValues.funccount;
OUTPUT.algorithm = 'trust-region-reflective'; 
OUTPUT.firstorderopt = optimValues.firstorderopt; 
OUTPUT.cgiterations = npcg; % total number of CG iterations
JACOB = []; % May be in an inconsistent state
LAMBDA = []; % May be in an inconsistent state





