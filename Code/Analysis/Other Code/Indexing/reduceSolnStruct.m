% --- reduces the solution struct (only applies to single expt analysis)
function snTot = reduceSolnStruct(snTot)

% only reduce single experiment data structs
if (length(snTot) == 1)
    % sets the acceptance/rejection flags
    ok = snTot.appPara.ok;
    
    % reduces down the x/y location data arrays
    if (~isempty(snTot.Px)); snTot.Px = snTot.Px(ok); end
    if (~isempty(snTot.Py)); snTot.Py = snTot.Py(ok); end
    
    % reduces the solution apparatus struct
    snTot = reduceSolnAppPara(snTot);
end