function [allfcns,idandmsg] = optimfcnchk(funstr,caller,lenVarIn,funValCheck, ...
    gradflag,hessflag,constrflag,Algorithm,ntheta)
%

%OPTIMFCNCHK Pre- and post-process function expression for FCNCHK.
%
% This is a helper function.

%   [ALLFCNS,idandmsg] = OPTIMFCNCHK(FUNSTR,CALLER,lenVarIn,GRADFLAG) takes
%   the (nonempty) function handle or expression FUNSTR from CALLER with
%   lenVarIn extra arguments, parses it according to what CALLER is, then
%   returns a string or inline object in ALLFCNS.  If an error occurs,
%   this message is put in idandmsg.
%
%   ALLFCNS is a cell array:
%    ALLFCNS{1} contains a flag
%    that says if the objective and gradients are together in one function
%    (calltype=='fungrad') or in two functions (calltype='fun_then_grad')
%    or there is no gradient (calltype=='fun'), etc.
%    ALLFCNS{2} contains the string CALLER.
%    ALLFCNS{3}  contains the objective (or constraint) function
%    ALLFCNS{4}  contains the gradient function
%    ALLFCNS{5}  contains the hessian function (not used for constraint function).
%
%    If funValCheck is 'on', then we update the funfcn's (fun/grad/hess) so
%    they are called through CHECKFUN to check for NaN's, Inf's, or complex
%    values. Add a wrapper function, CHECKFUN, to check for NaN/complex
%    values without having to change the calls that look like this:
%    f = funfcn(x,varargin{:});
%    CHECKFUN is a nested function so we can get the 'caller', 'userfcn', and
%    'ntheta' (for fseminf constraint functions) information from this function
%    and the user's function and CHECKFUN can both be called with the same
%    arguments.

%    NOTE: we assume FUNSTR is nonempty.

%   Copyright 1990-2011 The MathWorks, Inc.

% Initialize
if nargin < 9
    ntheta = 0;
    if nargin < 8
        Algorithm = [];
        if nargin < 7
            constrflag = false;
            if nargin < 6
                hessflag = false;
                if nargin < 5
                    gradflag = false;
                end
            end  
        end
    end
end
if constrflag
    % Create error message for constraint gradient option
    graderrMsgObj = message('optimlib:optimfcnchk:NoConstraintGradientFunction', ...
        '(OPTIONS.GradConstr = ''on'')');
    % Create warning message for constraint gradient option 
    warnMsgObj = message('optimlib:optimfcnchk:ConstraintGradientOptionOff', ... 
        'OPTIONS.GradConstr = ''off''','OPTIONS.GradConstr = ''on''');
else
    % Create error message for objective gradient option
    graderrMsgObj = message('optimlib:optimfcnchk:NoGradientFunction', ... 
        '(OPTIONS.GradObj=''on'')');
    % Create warning message for objective gradient option 
    warnMsgObj = message('optimlib:optimfcnchk:GradientOptionOff', ... 
        'OPTIONS.GradObj = ''off''','OPTIONS.GradObj=''on''');
end
idandmsg='';
if isequal(caller,'fseminf')
    nonlconMsgObj = message('optimlib:optimfcnchk:SeminfconNotAFunction', 'SEMINFCON');
else
    nonlconMsgObj = message('optimlib:optimfcnchk:NonlconNotAFunction', 'NONLCON');
end
allfcns = {};
funfcn = [];
gradfcn = [];
hessfcn = [];
if gradflag && hessflag 
    if strcmpi(caller,'fmincon') && strcmpi(Algorithm,'interior-point')
        % fmincon interior-point doesn't take Hessian as 3rd argument 
        % of objective function - it's passed as a separate function
        calltype = 'fungrad';
    else
        calltype = 'fungradhess';
    end
elseif gradflag
    calltype = 'fungrad';
else % ~gradflag & ~hessflag,   OR  ~gradflag & hessflag: this problem handled later
    calltype = 'fun';
end

if isa(funstr, 'cell') && length(funstr)==1 % {fun}
    % take the cellarray apart: we know it is nonempty
    if gradflag
        error(graderrMsgObj)
    end
    [funfcn, idandmsg] = fcnchk(funstr{1},lenVarIn);
    % Insert call to nested function checkfun which calls user funfcn
    if funValCheck
        userfcn = funfcn;
        funfcn = @checkfun; %caller and userfcn are in scope in nested checkfun
    end
    if ~isempty(idandmsg)
        if constrflag % Constraint, not objective, function, so adjust error message
            error(nonlconMsgObj);
        else
            error(message(idandmsg.identifier));
        end
    end
elseif isa(funstr, 'cell') && length(funstr)==2 && isempty(funstr{2}) % {fun,[]}
    if gradflag
        error(graderrMsgObj)
    end
    [funfcn, idandmsg] = fcnchk(funstr{1},lenVarIn);
    if funValCheck
        userfcn = funfcn;
        funfcn = @checkfun; %caller and userfcn are in scope in nested checkfun
    end
    if ~isempty(idandmsg)
        if constrflag
            error(nonlconMsgObj);
        else
            error(message(idandmsg.identifier));
        end
    end

elseif isa(funstr, 'cell') && length(funstr)==2 %  {fun, grad} and ~isempty(funstr{2})

    [funfcn, idandmsg] = fcnchk(funstr{1},lenVarIn);
    if funValCheck
        userfcn = funfcn;
        funfcn = @checkfun; %caller and userfcn are in scope in nested checkfun
    end

    if ~isempty(idandmsg)
        if constrflag
            error(nonlconMsgObj);
        else
            error(message(idandmsg.identifier));
        end
    end
    [gradfcn, idandmsg] = fcnchk(funstr{2},lenVarIn);
    if funValCheck
        userfcn = gradfcn;
        gradfcn = @checkfun; %caller and userfcn are in scope in nested checkfun
    end
    if ~isempty(idandmsg)
        if constrflag
            error(nonlconMsgObj);
        else
            error(message(idandmsg.identifier));
        end
    end
    calltype = 'fun_then_grad';
    if ~gradflag
        warning(warnMsgObj);
        calltype = 'fun';
    end
elseif isa(funstr, 'cell') && length(funstr)==3 ...
        && ~isempty(funstr{1}) && isempty(funstr{2}) && isempty(funstr{3})    % {fun, [], []}
    if gradflag
        error(graderrMsgObj)
    end
    if hessflag
        error(message('optimlib:optimfcnchk:NoHessianFunction'))
    end
    [funfcn, idandmsg] = fcnchk(funstr{1},lenVarIn);
    if funValCheck
        userfcn = funfcn;
        funfcn = @checkfun; %caller and userfcn are in scope in nested checkfun
    end
    if ~isempty(idandmsg)
        if constrflag
            error(nonlconMsgObj);
        else
            error(message(idandmsg.identifier));
        end
    end

elseif isa(funstr, 'cell') && length(funstr)==3 ...
        && ~isempty(funstr{2}) && ~isempty(funstr{3})     % {fun, grad, hess}
    [funfcn, idandmsg] = fcnchk(funstr{1},lenVarIn);
    if funValCheck
        userfcn = funfcn;
        funfcn = @checkfun; %caller and userfcn are in scope in nested checkfun
    end

    if ~isempty(idandmsg)
        if constrflag
            error(nonlconMsgObj);
        else
            error(message(idandmsg.identifier));
        end
    end
    [gradfcn, idandmsg] = fcnchk(funstr{2},lenVarIn);
    if funValCheck
        userfcn = gradfcn;
        gradfcn = @checkfun; %caller and userfcn are in scope in nested checkfun
    end

    if ~isempty(idandmsg)
        if constrflag
            error(nonlconMsgObj);
        else
            error(message(idandmsg.identifier));
        end
    end
    [hessfcn, idandmsg] = fcnchk(funstr{3},lenVarIn);
    if funValCheck
        userfcn = hessfcn;
        hessfcn = @checkfun; %caller and userfcn are in scope in nested checkfun
    end

    if ~isempty(idandmsg)
        if constrflag
            error(nonlconMsgObj);
        else
            error(message(idandmsg.identifier));
        end
    end
    calltype = 'fun_then_grad_then_hess';
    if ~hessflag && ~gradflag
        warning(message('optimlib:optimfcnchk:HessianAndGradientOptionsOff'))
        calltype = 'fun';
    elseif hessflag && ~gradflag
        warning(message('optimlib:optimfcnchk:GradientOptionOffFunstrACell'))
        calltype = 'fun';
    elseif ~hessflag && gradflag
        warning(message('optimlib:optimfcnchk:HessianOptionOff'));
        calltype = 'fun_then_grad';
    end


elseif isa(funstr, 'cell') && length(funstr)==3 ...
        && ~isempty(funstr{2}) && isempty(funstr{3})    % {fun, grad, []}
    if hessflag
        error(message('optimlib:optimfcnchk:NoHessianFunction'))
    end
    [funfcn, idandmsg] = fcnchk(funstr{1},lenVarIn);
    if funValCheck
        userfcn = funfcn;
        funfcn = @checkfun; %caller and userfcn are in scope in nested checkfun
    end
    if ~isempty(idandmsg)
        if constrflag
            error(nonlconMsgObj);
        else
            error(message(idandmsg.identifier));
        end
    end
    [gradfcn, idandmsg] = fcnchk(funstr{2},lenVarIn);
    if funValCheck
        userfcn = gradfcn;
        gradfcn = @checkfun; %caller and userfcn are in scope in nested checkfun
    end
    if ~isempty(idandmsg)
        if constrflag
            error(nonlconMsgObj);
        else
            error(message(idandmsg.identifier));
        end
    end
    calltype = 'fun_then_grad';
    if ~gradflag
        warning(warnMsgObj);
        calltype = 'fun';
    end


elseif isa(funstr, 'cell') && length(funstr)==3 ...
        && isempty(funstr{2}) && ~isempty(funstr{3})     % {fun, [], hess}
    error(message('optimlib:optimfcnchk:NoGradientWithHessian'))

elseif ~isa(funstr, 'cell')  %Not a cell; is a string expression, function name string or inline object
    [funfcn, idandmsg] = fcnchk(funstr,lenVarIn);
    if funValCheck
        userfcn = funfcn;
        funfcn = @checkfun; %caller and userfcn are in scope in nested checkfun
    end

    if ~isempty(idandmsg)
        if constrflag
            error(nonlconMsgObj);
        else
            error(message(idandmsg.identifier));
        end
    end
    if gradflag % gradient and function in one function/MATLAB file
        gradfcn = funfcn; % Do this so graderr will print the correct name
    end
    if hessflag && ~gradflag
        warning(message('optimlib:optimfcnchk:GradientOptionOffFunstrNotACell'));
    end

else
    error(message('optimlib:optimfcnchk:MustBeAFunction'));
end

allfcns{1} = calltype;
allfcns{2} = caller;
allfcns{3} = funfcn;
allfcns{4} = gradfcn;
allfcns{5} = hessfcn;

    %------------------------------------------------------------
    function [varargout] = checkfun(x,varargin)
    % CHECKFUN checks for complex, Inf, or NaN results from userfcn.
    % Inputs CALLER, USERFCN, and NTHETA come from the scope of OPTIMFCNCHK.
    % We do not make assumptions about f, g, or H. For generality, assume
    % they can all be matrices.
   
        if nargout == 1
            f = userfcn(x,varargin{:});
            if any(any(isnan(f)))
                error(message('optimlib:optimfcnchk:checkfun:NaNFval', functiontostring( userfcn ), upper( caller )));
            elseif ~isreal(f)
                error(message('optimlib:optimfcnchk:checkfun:ComplexFval', functiontostring( userfcn ), upper( caller )));
            elseif any(any(isinf(f)))
                error(message('optimlib:optimfcnchk:checkfun:InfFval', functiontostring( userfcn ), upper( caller )));
            else
                varargout{1} = f;
            end

        elseif nargout == 2 % Two output could be f,g (from objective fcn) or c,ceq (from NONLCON)
            [f,g] = userfcn(x,varargin{:});
            if any(any(isnan(f))) || any(any(isnan(g)))
                error(message('optimlib:optimfcnchk:checkfun:NaNFval', functiontostring( userfcn ), upper( caller )));
            elseif ~isreal(f) || ~isreal(g)
                error(message('optimlib:optimfcnchk:checkfun:ComplexFval', functiontostring( userfcn ), upper( caller )));
            elseif any(any(isinf(f))) || any(any(isinf(g)))
                error(message('optimlib:optimfcnchk:checkfun:InfFval', functiontostring( userfcn ), upper( caller )));
            else
                varargout{1} = f;
                varargout{2} = g;
            end

        elseif nargout == 3 % This case only happens for objective functions
            [f,g,H] = userfcn(x,varargin{:});
            if any(any(isnan(f))) || any(any(isnan(g))) || any(any(isnan(H)))
                error(message('optimlib:optimfcnchk:checkfun:NaNFval', functiontostring( userfcn ), upper( caller )));
            elseif ~isreal(f) || ~isreal(g) || ~isreal(H)
                error(message('optimlib:optimfcnchk:checkfun:ComplexFval', functiontostring( userfcn ), upper( caller )));
            elseif any(any(isinf(f))) || any(any(isinf(g))) || any(any(isinf(H)))
                error(message('optimlib:optimfcnchk:checkfun:InfFval', functiontostring( userfcn ), upper( caller )));
            else
                varargout{1} = f;
                varargout{2} = g;
                varargout{3} = H;
            end
        elseif nargout == 4 && ~isequal(caller,'fseminf')
            % In this case we are calling NONLCON, e.g. for FMINCON, and
            % the outputs are [c,ceq,gc,gceq]
            [c,ceq,gc,gceq] = userfcn(x,varargin{:}); 
            if any(any(isnan(c))) || any(any(isnan(ceq))) || any(any(isnan(gc))) || any(any(isnan(gceq)))
                error(message('optimlib:optimfcnchk:checkfun:NaNFval', functiontostring( userfcn ), upper( caller )));
            elseif ~isreal(c) || ~isreal(ceq) || ~isreal(gc) || ~isreal(gceq)
                error(message('optimlib:optimfcnchk:checkfun:ComplexFval', functiontostring( userfcn ), upper( caller )));
            elseif any(any(isinf(c))) || any(any(isinf(ceq))) || any(any(isinf(gc))) || any(any(isinf(gceq))) 
                error(message('optimlib:optimfcnchk:checkfun:InfFval', functiontostring( userfcn ), upper( caller )));
            else
                varargout{1} = c;
                varargout{2} = ceq;
                varargout{3} = gc;
                varargout{4} = gceq;
            end
        else % fseminf constraints have a variable number of outputs, but at 
             % least 4: see semicon.m
            % Also, don't check 's' for NaN as NaN is a valid value
            T = cell(1,ntheta);
            [c,ceq,T{:},s] = userfcn(x,varargin{:});
            nanfound = any(any(isnan(c))) || any(any(isnan(ceq)));
            complexfound = ~isreal(c) || ~isreal(ceq) || ~isreal(s);
            inffound = any(any(isinf(c))) || any(any(isinf(ceq))) || any(any(isinf(s)));
            for ii=1:length(T) % Elements of T are matrices
                if nanfound || complexfound || inffound
                    break
                end
                nanfound = any(any(isnan(T{ii})));
                complexfound = ~isreal(T{ii});
                inffound = any(any(isinf(T{ii})));
            end
            if nanfound
                error(message('optimlib:optimfcnchk:checkfun:NaNFval', functiontostring( userfcn ), upper( caller )));
            elseif complexfound
                error(message('optimlib:optimfcnchk:checkfun:ComplexFval', functiontostring( userfcn ), upper( caller )));
            elseif inffound
                error(message('optimlib:optimfcnchk:checkfun:InfFval', functiontostring( userfcn ), upper( caller )));
            else
                varargout{1} = c;
                varargout{2} = ceq;
                varargout(3:ntheta+2) = T;
                varargout{ntheta+3} = s;
            end
        end

    end %checkfun
    %----------------------------------------------------------
end % optimfcnchk
