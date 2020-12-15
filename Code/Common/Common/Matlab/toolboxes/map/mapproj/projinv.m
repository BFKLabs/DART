function [lat, lon] = projinv(proj, x, y)
%PROJINV Inverse map projection using PROJ.4 library
%
%   [LAT, LON] = PROJINV(PROJ, X, Y) applies the inverse transformation
%   defined by the map projection in the PROJ structure, converting
%   locations in a planar, projected map coordinate system to latitudes,
%   LAT, and longitudes, LON, in degrees. PROJ may be either a map
%   projection MSTRUCT or a GeoTIFF INFO structure. X and Y are arrays of
%   map coordinates. For a complete list of map projections that may be
%   used with PROJINV, see PROJLIST.
%
%   Class support for inputs X and Y:
%       float: double, single
%
%   Example - Overlay Boston roads on top of 'boston_ovr.jpg' 
%             in a Mercator projection.
%   -------
%   % Import the Boston roads from the shapefile.
%   roads = shaperead('boston_roads.shp');
%
%   % Obtain the projection structure from 'boston.tif'.
%   proj = geotiffinfo('boston.tif');
%
%   % As shown by the UOMLength field of the projection structure, the
%   % units of length in the projected coordinate system is 
%   % 'US Survey Feet'. Coordinates in the roads shapefile are in meters.
%   % The road coordinates must be converted to the projection's length 
%   % unit.
%   x = [roads.X] * unitsratio('sf','meter');
%   y = [roads.Y] * unitsratio('sf','meter');
%  
%   % Convert the coordinates of the roads to latitude and longitude.
%   [roadsLat, roadsLon] = projinv(proj, x, y);
%
%   % Read the boston_ovr.jpg image and worldfile.
%   % Includes material (c) GeoEye, all rights reserved.
%   RGB = imread('boston_ovr.jpg');
%   R = worldfileread(getworldfilename('boston_ovr.jpg'));
%
%   % Obtain stateline boundary of Massachusetts.
%   S = shaperead('usastatehi', 'UseGeoCoords', true, ...
%       'Selector',{@(name) strcmpi(name,'Massachusetts'), 'Name'});
%
%   % Open a figure with a Mercator projection.
%   figure
%   axesm('mercator')
%
%   % Display the image, stateline boundary, and roads.
%   geoshow(RGB, R)
%   geoshow(S.Lat, S.Lon, 'Color','red')
%   geoshow(roadsLat, roadsLon, 'Color', 'green')
%
%   % Set the map boundary to the image's northern, western, and southern
%   % limits, and the eastern limit of the stateline within the image
%   % latitude boundaries.
%   [lon, lat] = mapoutline(R, size(RGB(:,:,1)));
%   ltvals = find((S.Lat>=min(lat(:))) & (S.Lat<=max(lat(:))));
%   setm(gca,'maplonlimit',[min(lon(:)) max(S.Lon(ltvals))], ...
%            'maplatlimit',[min(lat(:)) max(lat(:))])
%   tightmap
%   
%   See also GEOTIFFINFO, MFWDTRAN, MINVTRAN, PROJFWD, PROJLIST

% Copyright 1996-2013 The MathWorks, Inc.

% Check the input arguments.
validateattributes(x, {'single', 'double'}, {'real'}, mfilename, 'X', 2);
validateattributes(y, {'single', 'double'}, {'real'}, mfilename, 'Y', 3);
map.internal.assert(isequal(size(x),size(y)), ...
    'map:validate:inconsistentSizes2', mfilename, 'X', 'Y')

% Inverse transform the X and Y points.
[lat, lon] = projaccess('inv', proj, x, y);
