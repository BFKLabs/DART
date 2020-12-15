% --- wrapper function for setting object callback functions
function setObjCallbackFcn(hTabGrp,type,selFcn)

% determines the matlab release being used
if (verLessThan('matlab','8.4'))
    % case is Release R2014a or earlier
    switch (type)
        case ('TabGroup')
            set(hTabGrp,'SelectionChangeCallback',selFcn); 
    end
else
    % case is Release R2014b or later
    switch (type)
        case ('TabGroup')    
            set(hTabGrp,'SelectionChangedFcn',selFcn); 
    end
end