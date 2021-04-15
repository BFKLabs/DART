% --- 
function pFont = retFontProp(hObj)

% memory allocation
pFont = {'FontAngle',[];'FontName',[];'FontUnits',[];...
         'FontSize',[];'FontWeight',[]};

%
for i = 1:size(pFont,1)
    eval(sprintf('pFont{i,2} = get(hObj,''%s'');',pFont{i,1}));
end