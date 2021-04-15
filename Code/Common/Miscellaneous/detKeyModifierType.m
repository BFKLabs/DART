% --- returns the modifier key types that were pressed
function modType = detKeyModifierType(modifier)

% initialisations
modType = NaN;

% determines the modifier key types that were pressed
if (isempty(modifier))
    % no modifier as pressed
    modType = 0;
elseif (length(modifier) == 1)
    % only one modifier key was pressed
    if (strcmp(modifier,'shift'))
        % case is the shift key
        modType = 1;    
    elseif (strcmp(modifier,'control'))
        % case is the control key
        modType = 2;
    elseif (strcmp(modifier,'alt'))
        % case is the alt key
        modType = 3;        
    end
elseif (length(modifier) == 2)
    % two modifier keys were pressed
    if (any(strcmp(modifier,'shift')) && any(strcmp(modifier,'control')))
        % case is the shift + control key
        modType = 12;    
    elseif any(strcmp(modifier,'control')) && any(strcmp(modifier,'alt'))
        % case is the control + alt key
        modType = 23;
    elseif any(strcmp(modifier,'shift')) && any(strcmp(modifier,'alt'))
        % case is the shift + alt key
        modType = 13;        
    end        
end