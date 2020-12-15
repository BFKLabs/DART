function makePatchPickable(hPatch)
%makePatchPickable  Make all parts of a patch pickable.

% Copyright 2013 The MathWorks, Inc.

if (~matlab.graphics.internal.isGraphicsVersion1)
  hPatch.PickableParts = 'all';
end
