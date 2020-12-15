function newException = privateFixUDDError(lastException)
%PRIVATEFIXUDDERROR Correct UDD error message.
%
%    NEWEXCEPTION =PRIVATEFIXUDDERROR(EXCEPTION) parses EXCEPTION in search
%    of UDD specific tokens. If any are found, they are replaced with the
%    appropriate strings. 
%
%    PRIVATEFIXUDDERROR is useful for correcting UDD property error
%    messages.
%

%    CP 9-01-01
%    Copyright 2001-2008 The MathWorks, Inc.

% Initialize variables.
out = lastException.message;
outID = lastException.identifier;

invalidErrID = 'testmeas:getset:invalidProperty';
readonlyErrID = 'testmeas:set:setDenied';
ambiguousErrID = 'testmeas:getset:ambiguousProperty';
enumErrID = 'testmeas:set:invalidEnum';

% Extract the name of the property.  This always appears first in the error
% message.
match = regexp(out, '''(.*?)''', 'match');

if strcmp(readonlyErrID, outID)
    % Need to correct read-only error message:
    % Ex. Changing the 'Logging' property of [PackageName].[ClassName] is not allowed.
    
    out = sprintf('Attempt to modify read-only property: %s.\nUse IMAQHELP(OBJ, %s) for information.', match{1}, match{1});
elseif strcmp(invalidErrID, outID)
    % Need to correct invalid property error message:
    % Ex. There is no 'blahblah' property in the 'UDDNIClass' class.
    
    out = sprintf('Invalid property: %s.\nType ''imaqhelp'' for information.', match{1});
elseif strcmp(ambiguousErrID, outID)
    % Need to correct the ambiguous error message:
    % Ex. The 'log' property name is ambiguous in the 'UDDNIClass' class.
    
    out = sprintf('Ambiguous property: %s.\nType ''imaqhelp'' for information.', match{1});
elseif strcmp(enumErrID, outID)
    % Append additional information to the enumerated error message:
    % Ex. The 'log' enumerated value is invalid.
    out = sprintf('%s\nType ''imaqhelp'' for information.', out);
    
end

% Remove the trailing carriage returns from errmsg.
while out(end) == sprintf('\n')
    out = out(1:end-1);
end

newException = MException(outID, out);