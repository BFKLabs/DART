% --- updates the loadbar and determines if it has closed
function ok = updateLoadbar(h,wStrNw)

% initialisations
ok = true;

% updates the loadbar. if there is an error (i.e., the figure is closed)
% then output a false flag
try    
    h.StatusMessage = wStrNw;
catch
    ok = false;
end   