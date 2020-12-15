function out = isNumericNum(a)
    %isNumericNum Check that the input value is  isnumeric, non-nan, non-inf value
    %
    %    This undocumented class may be removed in a future release.
    
    %    Copyright 2010 The MathWorks, Inc.
    % $Revision: 1.1.6.1 $  $Date: 2010/11/08 02:16:57 $
    out = isnumeric(a) && ~any(any(isnan(a))) && ~any(any(isinf(a)));
end