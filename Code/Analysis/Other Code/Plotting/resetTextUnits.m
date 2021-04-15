% --- resets the units of text objects (from pixels to units)
function resetTextUnits(hPanel,sInd)

% retrieves the axes objects from the currently selected panel
hPanelP = findall(hPanel,'tag','subPanel','UserData',sInd);
hObjAx = findall(hPanelP,'type','axes');

% splits the axes handles into plot and legend axes
ii = strcmp(get(hObjAx,'tag'),'legend');
[hAx,hLg] = deal(hObjAx(~ii),hObjAx(ii));

% resets the units of the 
set(hAx,'Units','Normalized');
for i = 1:length(hAx)
    hText = findall(hAx(i),'FontUnits','Pixels');
    set(hText,'FontUnits','Normalized')
end

a = 1;