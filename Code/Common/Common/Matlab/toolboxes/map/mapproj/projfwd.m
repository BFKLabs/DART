function [x, y] = projfwd(proj, lat, lon)
%PROJFWD Forward map projection using PROJ.4 library
%
%   [X, Y] = PROJFWD(PROJ, LAT, LON) applies the forward transformation
%   defined by the map projection in the PROJ structure, converting
%   locations given in latitude and longitude to a planar, projected map
%   coordinate system. PROJ may be either a map projection MSTRUCT or a
%   GeoTIFF INFO structure. LAT and LON are arrays of latitude and
%   longitude coordinates in degrees. For a complete list of map
%   projections that may be used with PROJFWD, see PROJLIST.
%
%   Class support for inputs LAT and LON:
%       float: double, single
%
%   Example 1
%   ---------
%   % Overlay landarea boundary on 'boston.tif'.
%   % Includes material (c) GeoEye, all rights reserved.
%
%   % Obtain stateline boundary of Massachusetts.
%   S = shaperead('usastatehi', 'UseGeoCoords', true, ...
%       'Selector',{@(name) strcmpi(name,'Massachusetts'), 'Name'});
%
%   % Obtain the projection structure.
%   proj = geotiffinfo('boston.tif');
%
%   % Project the stateline boundary.
%   lat = [S.Lat];
%   lon = [S.Lon];
%   [x, y] = projfwd(proj, lat, lon);
%
%   % Read the 'boston.tif' image.
%   [RGB, R] = geotiffread('boston.tif');
%
%   % Display the image.
%   figure
%   mapshow(RGB, R)
%   xlabel('MA Mainland State Plane easting, survey feet')
%   ylabel('MA Mainland State Plane northing, survey feet')
%
%   % Overlay the stateline boundary.
%   hold on
%   mapshow(gca, x, y,'Color','black','LineWidth',2.0)
%
%   % Set the map boundary to show a little more detail.
%   set(gca,'XLim', [ 645000,  895000], ...
%           'YLIm', [2865000, 3040000]);
%
%   See also GEOTIFFINFO, MFWDTRAN, MINVTRAN, PROJINV, PROJLIST

% Copyright 1996-2012 The MathWorks, Inc.

% Check the input arguments
validateattributes(lat, {'single', 'double'}, {'real'}, mfilename, 'LAT', 2);
validateattributes(lon, {'single', 'double'}, {'real'}, mfilename, 'LON', 3);
map.internal.assert(isequal(size(lat),size(lon)), ...
    'map:validate:inconsistentSizes2', mfilename, 'LAT', 'LON')

% Project the latitude and longitude points.
[x,y] = projaccess('fwd', proj, lat, lon);
