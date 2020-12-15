function entriesCell = privateimaqslgetentries(entriesStr)
%PRIVATEXCPSLGETENTRIES Return entries cell array for the string.
%
%    ENTRIESCELL = PRIVATEIMAQSLGETENTRIES (ENTRIESSTR) returns entries to
%    list box as cell, ENTRIESCELL, for the specified string input, 
%    ENTRIESSTR.

%    SS 06-15-12
%    Copyright 2012 The MathWorks, Inc.

entriesCell = {};

if isempty(strfind(entriesStr, ';'))
    entriesCell = {entriesStr};
else % We have more entries.
    ind = strfind(entriesStr, ';');
    start = 1;
    for idx=1:length(ind)
        entriesCell = [entriesCell {entriesStr(start:ind(idx)-1)}]; %#ok<AGROW>
        start = ind(idx)+1;
    end
    entriesCell = [entriesCell {entriesStr(start:end)}];
end