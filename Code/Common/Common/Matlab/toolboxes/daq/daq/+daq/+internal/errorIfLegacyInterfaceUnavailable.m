function errorIfLegacyInterfaceUnavailable()
%errorIfLegacyInterfaceUnavailable throws an error if the current
%environment cannot be used with the legacy interface (i.e. anything other
%than Win32)

    % Copyright 2010 The MathWorks, Inc.
    % $Revision: 1.1.6.1 $  $Date: 2010/11/08 02:16:54 $

    if strcmp(computer('arch'), 'win32')
        return
    end

    throwAsCaller(MException('daq:general:legacyInterfaceOnlyOnWin32',...
        getString(message('daq:general:legacyInterfaceOnlyOnWin32',...
        computer('arch')))));
end