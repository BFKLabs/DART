% --- runs the Git environment variable add/remove function
function gitEnvVarFunc(action,vName,vPath)

% sets up the command line string based on action type
switch action
    case 'add'
        % case is adding an environment variable
        cmdStr = sprintf('setx %s "%s"',vName,vPath);
        setenv(vName,vPath)
        
    case 'remove'
        % case is removing an environment variable
        cmdStr = sprintf('reg delete "HKCU\\Environment" /v %s /f',vName);
        setenv(vName,'');
end

% runs the string from the command line
[~,~] = system(cmdStr);