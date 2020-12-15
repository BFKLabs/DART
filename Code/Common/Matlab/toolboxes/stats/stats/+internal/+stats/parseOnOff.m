function ison = parseOnOff(onoff,paramname)
% Process argument that can be true, false, on, or off, and return true if
% it is either on or true

%   Copyright 2011 The MathWorks, Inc.

if isscalar(onoff) && islogical(onoff)
    ison = onoff;
elseif internal.stats.isString(onoff)
    onoff = internal.stats.getParamVal(onoff,{'on' 'off'},paramname);
    ison = strcmp(onoff,'on');
else
    m = message('stats:internal:parseOnOff:InvalidInput', paramname);
    throwAsCaller(MException(m.Identifier, '%s', getString(m)));
end