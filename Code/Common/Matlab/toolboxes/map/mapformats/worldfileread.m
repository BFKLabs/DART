function R = worldfileread(worldFileName, coordinateSystemType, rasterSize)
%WORLDFILEREAD Read world file and return referencing object or matrix
%
%   R = WORLDFILEREAD(worldFileName, coordinateSystemType, rasterSize)
%   reads the world file, worldFileName, and constructs a spatial
%   referencing object, R. The type of referencing object is determined by
%   the coordinateSystemType string, which can be either 'planar'
%   (including projected map coordinate systems) or 'geographic' (for
%   latitude-longitude systems). The rasterSize input should match to the
%   size of the image corresponding to the world file.
%
%   REFMAT = WORLDFILEREAD(worldFileName) reads the world file, 
%   worldFileName, and constructs a 3-by-2 referencing matrix, REFMAT.
%
%   Example 1
%   ---------
%   % Read ortho image referenced to a projected coordinate system
%   % (Massachusetts State Plane Mainland)
%   filename = 'concord_ortho_w.tif';
%   [X, cmap] = imread(filename);
%   worldFileName = getworldfilename(filename);
%   R = worldfileread(worldFileName, 'planar', size(X))
%
%   Example 2
%   ---------
%   % Read image referenced to a geographic coordinate system
%   filename = 'boston_ovr.jpg';
%   RGB = imread(filename);
%   worldFileName = getworldfilename(filename);
%   R = worldfileread(worldFileName, 'geographic', size(RGB))
%
%   See also GETWORLDFILENAME, PIX2MAP, MAP2PIX, WORLDFILEWRITE

% Copyright 1996-2012 The MathWorks, Inc.

narginchk(1, 3)
if nargin == 2
    error(message('map:validate:expected1Or3Inputs', 'WORLDFILEREAD'))
end

if nargin == 3
    % Validate coordinateSystemType, but let georasterref or maprasterref
    % validate rasterSize.
    coordinateSystemType = validatestring( ...
        coordinateSystemType, {'geographic', 'planar'}, ...
        'WORLDFILEREAD', 'coordinateSystemType', 2);
end

% Check that worldFileName is a file and that it can be opened.
worldFileName = internal.map.checkfilename(worldFileName, {}, mfilename, 1, false);

% Open the input worldFileName.
fid = fopen(worldFileName);
clean = onCleanup(@() fclose(fid));

% Read W into a 6-element vector.
[W, count] = fscanf(fid,'%f',6);
map.internal.assert(count == 6, 'map:fileio:expectedSixNumbers');

if nargin == 3
    if strcmp(coordinateSystemType,'geographic')
        R = georasterref(W, rasterSize, 'cells');
    else
        R = maprasterref(W, rasterSize, 'cells');
    end
else
    % Convert W to a referencing matrix
    R = worldFileMatrixToRefmat(W);
end

