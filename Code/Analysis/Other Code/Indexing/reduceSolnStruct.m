% --- reduces the solution struct (only applies to single expt analysis)
function snTot = reduceSolnStruct(snTot)

% only reduce single experiment data structs
if length(snTot) == 1
    % sets the acceptance/rejection flags
    ok = snTot.iMov.ok;
    
    % reduces down the x location data arrays (if it exists)
    if isfield(snTot,'Px') && ~isempty(snTot.Px)
        snTot.Px = snTot.Px(ok); 
    end
    
    % reduces down the y location data arrays (if it exists)
    if isfield(snTot,'Py') && ~isempty(snTot.Py)
        snTot.Py = snTot.Py(ok); 
    end
    
    % reduces the solution apparatus struct
    snTot = reduceSolnAppPara(snTot);
end