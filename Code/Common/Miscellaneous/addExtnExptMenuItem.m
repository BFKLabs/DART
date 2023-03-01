function hMenuNew = addExtnExptMenuItem(hMenu,lblStr,cbFcn)

% retrieves the extension menu item
hMenuExtn = findall(hMenu,'tag','hMenuExtn');
if isempty(hMenuExtn)
    % if it doesn't exist, then create it
    nMenuC = length(hMenu.Children);
    hMenuExit = findall(hMenu,'Position',nMenuC);
    
    % creates the new menu item
    lblStrEx = 'Load External Experiment';
    hMenuExtn = uimenu(hMenu,'label',lblStrEx,'tag','hMenuExtn');
    
    % reorders the menu items
    set(hMenuExit,'Position',nMenuC+1);
    set(hMenuExtn,'Position',nMenuC);
end

% creates the new menu item
menuTag = sprintf('menu%s',lblStr);
hMenuNew = uimenu(hMenuExtn,...
    'label',lblStr,'tag',menuTag,'MenuSelectedFcn',cbFcn);