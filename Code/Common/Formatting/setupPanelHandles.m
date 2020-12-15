% --- 
function handlesS = setupPanelHandles(hPanel)

% finds all the objects in the panel
hObj = findobj(hPanel);
handlesS = [];

% sets the handles for all the objects in the panel
for i = 1:length(hObj)
    eval(sprintf('handlesS.%s = hObj(i);',get(hObj(i),'tag')));
end