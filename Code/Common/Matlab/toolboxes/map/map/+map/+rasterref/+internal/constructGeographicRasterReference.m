function R = constructGeographicRasterReference( ...
    rasterSize, rasterInterpretation, firstCornerX, firstCornerY, ...
    deltaLatNumerator, deltaLatDenominator, ...
    deltaLonNumerator, deltaLonDenominator)
% Construct a scalar instance of one of the following, depending on the
% value of rasterInterpretation:
%
%     map.rasterref.GeographicCellsReference
%     map.rasterref.GeographicPostingsReference

% Copyright 2013 The MathWorks, Inc.

if strncmpi(rasterInterpretation,'cells',numel(rasterInterpretation))
    R = map.rasterref.GeographicCellsReference(rasterSize, ...
        firstCornerX, firstCornerY, deltaLatNumerator, ...
        deltaLatDenominator, deltaLonNumerator, deltaLonDenominator);
elseif strncmpi(rasterInterpretation,'postings',numel(rasterInterpretation))
    R = map.rasterref.GeographicPostingsReference(rasterSize, ...
        firstCornerX, firstCornerY, deltaLatNumerator, ...
        deltaLatDenominator, deltaLonNumerator, deltaLonDenominator);
else
    % Invalid rasterInterpretation: validatestring will throw an error.
    validatestring(rasterIntepretation,{'cells','postings'})
end
