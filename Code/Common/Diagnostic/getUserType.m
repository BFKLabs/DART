% retrieves the token key (depending on the user)
function uType = getUserType()

% retrieves the hostname of the computer
[~,hName] = system('hostname');

% sets the user type/token key string based on the computer
switch hName(1:end-1)
    case {'DESKTOP-94RD45L','DESKTOP-NLLEH0V'} 
        % case is a developer
        uType = 0;

    otherwise
        % case is a basic program user
        uType = 1;

end