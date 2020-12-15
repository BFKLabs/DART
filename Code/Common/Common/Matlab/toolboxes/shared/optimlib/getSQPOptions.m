function options = getSQPOptions(options,defaultopt,nVar)
%

%GETSQPOPTIONS read user options needed by the SQP algorithm of fmincon.
%
% getSQPOptions reads the options from the user-provided structure using
% optimget and overwrites the same fields in the same structure with the
% verified values.

%   Copyright 2009-2012 The MathWorks, Inc.

% Get options relevant for the SQP algorithm of fmincon that require no
% validation outside of that done in optimget
options.DerivativeCheck = optimget(options,'DerivativeCheck',defaultopt,'fast');
options.MaxIter         = optimget(options,'MaxIter',defaultopt,'fast');
options.TolCon          = optimget(options,'TolCon',defaultopt,'fast');
options.TolFun          = optimget(options,'TolFun',defaultopt,'fast');
options.TolX            = optimget(options,'TolX',defaultopt,'fast');
options.ObjectiveLimit  = optimget(options,'ObjectiveLimit',defaultopt,'fast');
options.OutputFcn       = optimget(options,'OutputFcn',defaultopt,'fast');
options.PlotFcns        = optimget(options,'PlotFcns',defaultopt,'fast');
options.ScaleProblem    = optimget(options,'ScaleProblem',defaultopt,'fast');
options.UseParallel     = optimget(options,'UseParallel',defaultopt,'fast');

options.MaxFunEvals = optimget(options,'MaxFunEvals',defaultopt,'fast');
% In case the defaults were gathered from calling: optimset('fmincon'):
if ischar(options.MaxFunEvals)
    if isequal(lower(options.MaxFunEvals),'100*numberofvariables')
        options.MaxFunEvals = 100*nVar;
    else
        error(message('optimlib:getOptionsSQP:InvalidMaxFunEvals'))
    end
end

% Don't bother checking Hessian. Just set to 'bfgs' and continue
options.Hessian  = defaultopt.Hessian;
options.HessType = defaultopt.Hessian; % Set for the computeHessian utility
