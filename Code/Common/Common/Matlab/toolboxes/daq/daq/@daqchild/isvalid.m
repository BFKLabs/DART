function isok = isvalid(obj)
%ISVALID True for data acquisition objects associated with hardware.
%
%    OUT = ISVALID(OBJ) returns a logical array, OUT, that contains a 1 
%    where the elements of OBJ are data acquisition objects associated 
%    with hardware and a 0 where the elements of OBJ are data acquisition 
%    objects not associated with hardware.
%
%    OBJ is an invalid data acquisition object when it is no longer 
%    associated with any hardware.  If this is the case, OBJ should be 
%    cleared from the workspace.
%
%    See also DAQHELP, DAQDEVICE/DELETE, DAQRESET.
%

%   DTL 9-1-2004
%   Copyright 1998-2013 The MathWorks, Inc.
%   $Revision: 1.10.2.7 $  $Date: 2013/05/13 22:13:11 $

% Verify UDD object is valid.
x = struct(obj);
uddobjs = x.uddobject;

% check for an empty list of objects
if ~isempty(uddobjs)
    isok = ishandle(uddobjs) & (uddobjs ~= zeros);

    % Return the correct shape based on the input size.
    isok = reshape(isok, size(uddobjs));
else
    % empty list -- return [] -- similar to isnan([])
    isok = [];
end


