% --- rescales the font size in the parameter struct, pData, by the
%     multiplier, fScl
function pF = rescaleFontSize(pF,fScl)

% retrieves the formatting data struct field names
pStr = fieldnames(pF);

% resets the font sizes for all the fields
for i = 1:length(pStr)
    % retrieves the parameter struct
    pFnw = eval(sprintf('pF.%s',pStr{i}));
    
    % rescales the font sizes for all the font types
    for j = 1:length(pFnw)
        pFnw(j).Font.FontSize = roundP(fScl*pFnw(j).Font.FontSize,1);
    end
    
    % updates the formatting parameter struct
    eval(sprintf('pF.%s = pFnw;',pStr{i}))
end