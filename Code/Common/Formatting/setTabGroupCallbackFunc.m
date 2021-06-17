% --- sets the callback function for a tab group
function setTabGroupCallbackFunc(hTabGrpU,cbFcn)

set(hTabGrpU,'SelectionChangedFcn',cbFcn);