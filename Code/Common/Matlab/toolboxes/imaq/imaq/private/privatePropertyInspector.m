function inspector = privatePropertyInspector(obj)
%PRIVATEPROPERTYINSPECTOR Bring up a property inspector for a videoinput's videosource.
%
%   Example:
%      % inspect the currently selected source
%      inspectsource(vid);
%
%      inspectsource(getselectedsource(vid));
%
%    See also IMAQHELP, GETSELECTEDSOURCE

%    Copyright 2012-2013 The MathWorks, Inc.

if isa(obj, 'videosource')
    src = obj;
else
    if isa(obj, 'videoinput')
        src = getselectedsource(obj);
    else
        error(message('imaq:inspectsource:incorrectObjectType'));
    end
end

if ~isvalid(src)
    error(message('imaq:inspectsource:invalidSource'));
end

props = imaqgate('privateConvertVideoSourcePropinfoToList', src);

inspector = com.mathworks.toolbox.imaq.SourceInspector.getInstance();
inspector.initialize(src, props);

end


