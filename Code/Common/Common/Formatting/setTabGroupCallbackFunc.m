% --- sets the callback function for a tab group
function setTabGroupCallbackFunc(hTabGrpU,cbFcn)

if (isHG1)
    set(hTabGrpU,'SelectionChangeCallback',cbFcn);
else
    set(hTabGrpU,'SelectionChangedFcn',cbFcn);
end