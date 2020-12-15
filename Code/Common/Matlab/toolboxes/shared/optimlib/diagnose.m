function msg = diagnose(caller,OUTPUT,gradflag,hessflag,constflag,gradconstflag, ...
    XOUT,non_eq,non_ineq,lin_eq,lin_ineq,LB,UB,funfcn,confcn)
%

%DIAGNOSE prints diagnostic information about the function to be minimized
%    or solved.
%
% This is a helper function.

%   Copyright 1990-2011 The MathWorks, Inc. 

msg = [];

beginStr = getString(message('optimlib:diagnose:DiagnosticHeader'));
separatorTxt = repmat('_',60,1);
fprintf('\n%s\n   %s\n\n',separatorTxt,beginStr);

if ~isempty(funfcn{1})
    funformula =  getformula(funfcn{3});
    gradformula = getformula(funfcn{4});
    hessformula = getformula(funfcn{5});
else
    funformula =  '';
    gradformula = '';
    hessformula = '';
end

if ~isempty(confcn{1})
    conformula = getformula(confcn{3});
    gradcformula = getformula(confcn{4});
else
    conformula = '';
    gradcformula = '';
end    

fprintf(getString(message('optimlib:diagnose:NumVars',length(XOUT))))
if ~isempty(funfcn{1})
    fprintf(getString(message('optimlib:diagnose:FuncHeader')))
    switch funfcn{1}
    case 'fun'
        % display 
        fprintf(getString(message('optimlib:diagnose:ObjFun',funformula)));
        
    case 'fungrad'
        if gradflag
            fprintf(getString(message('optimlib:diagnose:ObjGradFun',funformula)));
        else
            fprintf(getString(message('optimlib:diagnose:ObjFun',funformula)));
            fprintf(getString(message('optimlib:diagnose:SetGradObj'))) 
        end
        
    case 'fungradhess'
        if gradflag && hessflag
            fprintf(getString(message('optimlib:diagnose:ObjGradHessFun',funformula)));
        elseif gradflag
            fprintf(getString(message('optimlib:diagnose:ObjGradFun',funformula)));
            fprintf(getString(message('optimlib:diagnose:SetHess'))) 
        else
            fprintf(getString(message('optimlib:diagnose:ObjFun',funformula)));
            fprintf(getString(message('optimlib:diagnose:SetGradObj')))
            fprintf(getString(message('optimlib:diagnose:SetHess'))) 
        end
        
        
    case 'fun_then_grad'
        fprintf(getString(message('optimlib:diagnose:ObjFun',funformula)));
        if gradflag
            fprintf(getString(message('optimlib:diagnose:GradFun',gradformula)));
        end
        if hessflag
            fprintf(getString(message('optimlib:diagnose:IgnoreHessOpt')))
        end
        
    case 'fun_then_grad_then_hess'
        fprintf(getString(message('optimlib:diagnose:ObjFun',funformula)));
        if gradflag && hessflag
            fprintf(getString(message('optimlib:diagnose:GradFun',gradformula)));
            fprintf(getString(message('optimlib:diagnose:HessFun',hessformula,'')));
        elseif gradflag
            fprintf(getString(message('optimlib:diagnose:GradFun',gradformula)));
        end   
    otherwise
        
    end
    
    if ~gradflag
        fprintf(getString(message('optimlib:diagnose:GradFun',getString(message('optimlib:diagnose:FinDiff')))))
    end
    % shape of grad
    
    if ~hessflag && (isequal('fmincon',caller) || isequal('constrsh',caller) || isequal('fminunc',caller))
        fprintf(getString(message('optimlib:diagnose:HessFun', ...
            getString(message('optimlib:diagnose:FinDiff')), ...
            getString(message('optimlib:diagnose:QuasiNewton')) )));
    end
    % shape of hess
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(confcn{1})
    switch confcn{1}
        
    case 'fun'
        fprintf(getString(message('optimlib:diagnose:NonlinConstr',conformula)));
    case 'fungrad'
        if gradconstflag
            fprintf(getString(message('optimlib:diagnose:NonlinConstrAndGrad',conformula)));
        else
            fprintf(getString(message('optimlib:diagnose:NonlinConstr',conformula)));
            fprintf(getString(message('optimlib:diagnose:SetGradConstr'))) 
        end
        
    case 'fun_then_grad'
        fprintf(getString(message('optimlib:diagnose:NonlinConstr',conformula)));
        if gradconstflag
            fprintf(getString(message('optimlib:diagnose:NonlinConstGrad',gradcformula)));
        end
        
    otherwise
        
    end
    
    if ~constflag
        fprintf(getString(message('optimlib:diagnose:NonlinConstr', ...
            getString(message('optimlib:diagnose:DoNotExist')) )));
    end
    if ~gradconstflag
        fprintf(getString(message('optimlib:diagnose:NonlinConstGrad',...
            getString(message('optimlib:diagnose:FinDiff')) )));
    end
    fprintf(getString(message('optimlib:diagnose:ConstrHeader')))  
    fprintf(getString(message('optimlib:diagnose:NumNonlinIneq',non_ineq)))
    fprintf(getString(message('optimlib:diagnose:NumNonlinEq',non_eq)))
    
elseif isequal(caller,'fmincon') || isequal(caller,'constrsh') || isequal(caller,'fminimax') || ...
        isequal(caller,'fgoalattain') || isequal(caller,'fseminf')
    fprintf(getString(message('optimlib:diagnose:ConstrHeader')));
    fprintf(getString(message('optimlib:diagnose:NonlinConstr', ...
        getString(message('optimlib:diagnose:DoNotExist')))));
    
end

fprintf(' \n')

switch caller
case {'fmincon','constrsh','linprog','quadprog','lsqlin','fminimax','fseminf','fgoalattain'}
    fprintf(getString(message('optimlib:diagnose:NumLinIneq',lin_ineq)))
    fprintf(getString(message('optimlib:diagnose:NumLinEq',lin_eq)))
    fprintf(getString(message('optimlib:diagnose:NumLB',nnz(~isinf(LB)))))
    fprintf(getString(message('optimlib:diagnose:NumUB',nnz(~isinf(UB)))))
case {'lsqcurvefit','lsqnonlin'}
    fprintf(getString(message('optimlib:diagnose:NumLB',nnz(~isinf(LB)))))
    fprintf(getString(message('optimlib:diagnose:NumUB',nnz(~isinf(UB)))))
case {'bintprog'}
    fprintf(getString(message('optimlib:diagnose:NumBinVars',length(XOUT))))
    fprintf(getString(message('optimlib:diagnose:NumLinIneq',lin_ineq)))
    fprintf(getString(message('optimlib:diagnose:NumLinEq',lin_eq)))
case {'fsolve','fminunc','fsolves'}
otherwise
end

if ~isempty(OUTPUT)
    fprintf(getString(message('optimlib:diagnose:AlgorithmHeader',OUTPUT.algorithm)));
end

endStr = getString(message('optimlib:diagnose:EndDiagnose'));
fprintf('\n%s\n   %s\n',separatorTxt,endStr);


%--------------------------------------------------------------------------------
function funformula = getformula(fun)
% GETFORMULA Convert FUN to a string.

if isempty(fun)
    funformula = '';
    return;
end

if ischar(fun) % already a string
    funformula = fun;
elseif isa(fun,'function_handle')  % function handle
    funformula = func2str(fun);
elseif isa(fun,'inline')   % inline object
    funformula = formula(fun);
else % something else with a char method
    try
        funformula = char(fun);
    catch
        funformula = '';
    end
end
