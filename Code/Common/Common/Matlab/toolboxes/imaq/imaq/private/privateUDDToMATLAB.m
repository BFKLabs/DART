function mobjects = privateUDDToMATLAB(uddobjects)
%PRIVATEUDDTOMATLAB Convert objects to their appropriate MATLAB object type.
%
%    MOBJECTS = PRIVATEUDDTOMATLAB(UDDOBJECTS) converts the vector of UDD
%    objects, UDDOBJECTS, to a vector of video input MATLAB objects.
%

%    CP 9-01-01
%    Copyright 2001-2009 The MathWorks, Inc.

% Initialize return arguments.
mobjects = [];

% Convert each udd object to a MATLAB object.
for i=1:length(uddobjects),
    mConstructor = get(uddobjects(i), 'Type');
    mobjects = [ mobjects feval(mConstructor, uddobjects(i)) ]; %#ok<AGROW>
end