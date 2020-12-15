% --- 
function hExt = getTextSize(hAx,tStr,pFont)

%
if (nargin < 3); pFont = retFontProp(hAx); end

% creates the text object
hText = text(0,0,tStr,'Parent',hAx,'Units','Normalized','Visible','on','color','w');

% sets the text object properties
for i = 1:size(pFont,1)
    set(hText,pFont{i,1},pFont{i,2});
end

% retrieves the text object extent and then deletes the object
hExt = get(hText,'Extent');
delete(hText);

