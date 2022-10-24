% --- retrieves the external data struct from the solution data structs
function exD = getExtnData(snTot)

% initialisations
exD = [];

% if the external data field exists, then retrieve it
if isfield(snTot,'exD')
    exD = snTot.exD;
end