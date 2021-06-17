% --- toggles the check mark for a menu item
function toggleMenuCheck(hMenu)

% performs the action based on the menu item checked status 
if strcmp(get(hMenu,'checked'),'off')
    % toggles the menu item to being checked and adds circle regions
    set(hMenu,'checked','on')    
else
    % toggles the menu item to being unchecked and removes circle regions
    set(hMenu,'checked','off')    
end