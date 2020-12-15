function profiles = privateGetVideoWriterProfiles(numBands)

% PRIVATEGETVIDEOWRITERPROFILES - Return the list of available VideoWriter
% profiles in a form that is easily usable by IMAQTool.

% Copyright 2011-2012 The MathWorks, Inc.

profList = VideoWriter.getProfiles();
profiles = {profList.Name};

if numBands == 3
    profiles = setxor(profiles, {'Grayscale AVI', 'Indexed AVI'});
end