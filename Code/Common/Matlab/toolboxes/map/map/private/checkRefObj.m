function R = checkRefObj(mapfilename, R, rasterSize, posR)
%CHECKREFOBJ Validate referencing vector, matrix, or object
%
%   R = checkRefObj(MAPFILENAME, R, rasterSize, POSR) returns a validated
%   referencing matrix in R. The input R may be a referencing vector,
%   matrix, or object. If R is a referencing vector or object, it is
%   converted to a referencing matrix. rasterSize is the size of the
%   corresponding raster for R. POSR is the argument position for R.

% Copyright 2010-2013 The MathWorks, Inc.

var_name = 'R';
if numel(R) == 3
    checkrefvec(R, mapfilename, var_name, posR);
    R = refvec2mat(R, rasterSize);
else
    % Validate R. It must be a 3-by-2 matrix of real-valued finite doubles,
    % a map raster reference object for use with mapshow, or a geographic
    % raster reference object for use with geoshow.
    if strcmp(mapfilename, 'mapshow')
        type = {'planar'};
    else
        type = {'geographic'};
    end
    map.rasterref.internal.validateRasterReference(R, type, ...
        mapfilename, var_name, posR)
    if isobject(R)
        R = worldFileMatrixToRefmat(R.worldFileMatrix());
    end
end
