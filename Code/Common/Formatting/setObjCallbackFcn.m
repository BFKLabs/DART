% --- wrapper function for setting object callback functions
function setObjCallbackFcn(hTabGrp,type,selFcn)

% sets the callback function based on the type
switch type
    case ('TabGroup')    
        set(hTabGrp,'SelectionChangedFcn',selFcn); 
end