% --- 
function hMenu = resetMenuItems(pLabel,bStr)

% retrieves the parent/child menu items
hMenuP = findall(0,'Label',pLabel);
hMenu = findall(hMenuP,'Label',bStr);

% updates the checked group to the merging branch and runs the
% callback function
set(findall(hMenuP,'checked','on'),'checked','off')
set(hMenu,'checked','on');                        
