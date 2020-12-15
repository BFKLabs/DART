% --- determines if directory string, nwStr, is a feasible directory string
function [ok,A] = chkDirString(nwStr,varargin)

% initialisations
[eStr,ok,vStr,A] = deal('/\:?"<>|@$!^&''',true,'String Input Error',[]);

% if the string is empty, then exit with a false flag
if (isempty(nwStr))
    [ok,A] = deal(false,'Error! String can''t be empty.');
    
    % outputs the error dialog (if not outputing error string)
    if (nargout == 1); waitfor(errordlg(A,vStr,'modal')); end        
    return
end

% sets the possible error strings and initialises the ok flag. if the 2nd
% input argument is set, then check for white-space
if (nargin == 2); eStr = [eStr,' ']; end

% determines if any of the offending strings are in the new string
for i = 1:length(eStr)
    % if so, then exit the function with a false flag
    if (strContains(nwStr,eStr(i)))
        % resets the flag and set the output error
        ok = false;
        if (strcmp(eStr(i),' '))
            A = 'Error! String can''t contain white-space.';
        else
            A = sprintf('Error! String can''t contain the string "%s".',eStr(i));
        end
        
        % outputs the error dialog (if not outputing error string)
        if (nargout == 1); waitfor(errordlg(A,vStr,'modal')); end
        return
    end
end