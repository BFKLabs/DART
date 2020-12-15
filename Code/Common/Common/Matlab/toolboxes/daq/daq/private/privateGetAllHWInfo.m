function [general,adaptors] = privateGetAllHWInfo()
%PRIVATEGETALLHWINFO Returns detailed hardware information on all adaptors.
%
%    [GENERAL,ADAPTORS] = PRIVATEGETALLHWINFO returns the results of
%    DAQHWINFO with no parameters and DAQHWINFO(<adaptor>) for each of the
%    adaptors installed in the system.
%
%    PRIVATEGETALLHWINFO is a helper function for the java model layer.
%

%    Copyright 2004-2005 The MathWorks, Inc.
%    $Revision: 1.1.8.2 $  $Date: 2005/06/27 22:32:37 $
general = daqhwinfo;

% For each of the adaptors, get the DAQHWINFO and put it in an array
adaptors = {};
for i = 1:length(general.InstalledAdaptors)
    % We put this in a try/catch since there are cases where some adaptors
    % cannot be enumerated, and will throw errors.  In those cases, ignore
    % them and keep enumerating the remaining adaptors.
    try
        adaptors{end + 1} = daqhwinfo(general.InstalledAdaptors{i});
    catch
    end
end