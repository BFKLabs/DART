function R = constructMapRasterReference(rasterSize, rasterInterpretation, ...
    firstCornerX, firstCornerY, jacobianNumerator, jacobianDenominator)
% Construct a scalar instance of one of the following, depending on the
% value of rasterInterpretation:
%
%     map.rasterref.MapCellsReference
%     map.rasterref.MapPostingsReference

% Copyright 2013 The MathWorks, Inc.

if strncmpi(rasterInterpretation,'cells',numel(rasterInterpretation))
    R = map.rasterref.MapCellsReference(rasterSize, ...
        firstCornerX, firstCornerY, jacobianNumerator, jacobianDenominator);
elseif strncmpi(rasterInterpretation,'postings',numel(rasterInterpretation))
    R = map.rasterref.MapPostingsReference(rasterSize, ...
        firstCornerX, firstCornerY, jacobianNumerator, jacobianDenominator);
else
    % Invalid rasterInterpretation: validatestring will throw an error.
    validatestring(rasterIntepretation,{'cells','postings'})
end
