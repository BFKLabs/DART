function W = refmatToWorldFileMatrix(refmat)
%refmatToWorldFileMatrix Convert referencing matrix to world file matrix
%
%   W = refmatToWorldFileMatrix(REFMAT) converts the 3-by-2 referencing
%   matrix REFMAT to a 2-by-3 world file matrix W.
%
%   For the definition of a referencing matrix, see the help for
%   MAKEREFMAT.
%
%   For the world file matrix definitions, see the help for the
%   worldFileMatrix methods of the map raster reference and geographic
%   raster reference classes.
%
%   See also MAKEREFMAT, worldFileMatrixToRefmat, georasterref/worldFileMatrix, map.rasterref.MapRasterReference/worldFileMatrix

% Copyright 2010-2013 The MathWorks, Inc.

% The following expressions are derived in worldFileMatrixToRefmat.m

map.rasterref.internal.validateRasterReference(refmat, ...
    {}, 'refmatToWorldFileMatrix', 'REFMAT', 1)

Cinv = [0  1  1;...
        1  0  1;...
        0  0  1];

W = refmat' * Cinv;
