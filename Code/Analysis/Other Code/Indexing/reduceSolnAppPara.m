% --- reduces down the apparatus parameter solution struct (for single
%     experiment analysis)
function snTotL = reduceSolnAppPara(snTot)

% sets the initial solution struct
snTotL = snTot(1);

% if only one experiment, then reduce down the solution struct
if (length(snTot) == 1)
    % sets the acceptance/rejection flags
    ok = snTotL.appPara.ok;
    
    % reduces down the arrays
    snTotL.appPara.ok = snTotL.appPara.ok(ok);
    snTotL.appPara.flyok = snTotL.appPara.flyok(ok);
    snTotL.appPara.Name = snTotL.appPara.Name(ok);
end