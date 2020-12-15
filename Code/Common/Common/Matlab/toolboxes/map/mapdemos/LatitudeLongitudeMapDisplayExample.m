%% Creating Map Displays with Latitude and Longitude Data
%
% There are many geospatial data sets that contain data with coordinates in
% latitude and longitude in units of degrees. This example illustrates how
% to import geographic data with coordinates in latitude and longitude,
% display geographic data in a map display, and customize the display.
%
% In particular, this example illustrates how to
%
% * Import specific geographic vector and raster data sets
% * Create map displays and visualize the data
% * Display multiple data sets in a single map display
% * Customize a map display with a scale ruler and north arrow
% * Customize a map display with an inset map

% Copyright 2013 The MathWorks, Inc.

%% Example 1: Import Polygon Geographic Vector Data
% Geographic vector data can be stored in a variety of different formats
% including standard file formats such as shapefiles, GPS Exchange (GPX),
% NetCDF, HDF4, or HDF5 and specific vector data products such as Vector
% Smart Map Level 0 (VMAP0), and the Global Self-Consistent Hierarchical
% High-Resolution Shoreline (GSHHS). This example imports polygon
% geographic vector data from a shapefile. Vertices in a shapefile can be
% either in geographic coordinates (latitude and longitude) or in a
% projected coordinate reference system.

%%
% Read USA state boundaries from the |usasatehi.shp| file  included with
% the Mapping Toolbox(TM) software. The state boundaries are in latitude
% and longitude. Convert the geostruct array to a |geoshape vector| and
% store the results in |states|.
states = geoshape(shaperead('usastatehi', 'UseGeoCoords', true));

%% Example 2: Display Polygon Geographic Vector Data
% Display the polygon geographic vector data onto a map axes.  Since the
% geographic extent is in the United States, you can use |usamap| to setup
% a map axes. Use |geoshow| to project and display the geographic data onto
% the map axes. Display an ocean color in the background by setting the
% frame's face color.
figure
ax = usamap('conus');
oceanColor = [.5 .7 .9];
setm(ax, 'FFaceColor', oceanColor)
geoshow(states)
title({ ...
    'Conterminous USA State Boundaries', ...
    'Polygon Geographic Vector Data'})

%% Example 3: Import Point and Line Geographic Vector Data

%%
% Import point geographic vector data from the |boston_placenames.gpx| file
% included with the Mapping Toolbox(TM) software. The file contains
% latitude and longitude coordinates of geographic point features in part
% of Boston, Massachusetts, USA. Use |gpxread| to read the GPX file and
% return a |geopoint vector|.
placenames = gpxread('boston_placenames');

%%
% Import line vector data from the |sample_route.gpx| file included with
% the Mapping Toolbox(TM) software. The file contains latitude and
% longitude coordinates for a GPS route from Boston Logan International
% Airport to The MathWorks, Inc in Natick Massachusetts, USA. Use |gpxread|
% to read the GPX file and return a |geopoint vector|.
route = gpxread('sample_route.gpx');

%% Example 4: Display Point and Line Geographic Vector Data
% Display the geographic vector data in a map axes centered around the
% state of Massachusetts, using the data from the state boundaries and the
% GPX files. The coordinates for all of these data sets are in latitude and
% longitude.

%%
% Find the state boundary for Massachusetts.
stateName = 'Massachusetts';
ma = states(strcmp(states.Name, stateName));

%%
% Use |usamap| to setup a map axes for the region surrounding
% Massachusetts. Color the ocean by setting the frame's face color. Display
% the state boundaries and highlight Massachusetts by using |geoshow| to
% display the geographic data onto the map axes. Since the GPX route is a
% set of points stored in a |geopoint vector|, supply the latitude and
% longitude coordinates to |geoshow| to display the route as a line.
figure
ax = usamap('ma');
setm(ax, 'FFaceColor', oceanColor)
geoshow(states)
geoshow(ma, 'LineWidth', 1.5, 'FaceColor', [.5 .8 .6])
geoshow(placenames);
geoshow(route.Latitude, route.Longitude);
title({'Massachusetts and Surrounding Region', 'Placenames and Route'})

%% Example 5: Set Latitude and Longitude Limits Based on Data Extent
% Zoom into the map by computing new latitude and longitude limits for
% the map using the extent of the placenames and route data. Extend the
% limits by .05 degrees.
lat = [route.Latitude placenames.Latitude];
lon = [route.Longitude placenames.Longitude];
latlim = [min(lat) max(lat)];
lonlim = [min(lon) max(lon)];
[latlim, lonlim] = bufgeoquad(latlim, lonlim, .05, .05);

%%
% Construct a map axes with the new limits and display the geographic data.
figure
ax = usamap(latlim, lonlim);
setm(ax, 'FFaceColor', oceanColor)
geoshow(states)
geoshow(placenames)
geoshow(route.Latitude, route.Longitude)
title('Closeup of Placenames and Route')

%% Example 6: Import Geographic Raster Data 
% Geographic raster data can be stored in a variety of different formats
% including standard file formats such as GeoTIFF, Spatial Data Transfer
% Standard (SDTS), NetCDF, HDF4, or HDF5 and specific raster data products
% such as DTED, GTOPO30, ETOPO, and the USGS 1-degree (3-arc-second) DEM
% formats. This example imports a raster data file and a worldfile of the
% region surrounding Boston, Massachusetts. The coordinates of the image
% are in latitude and longitude. Use |imread| to read the image and
% |worldfileread| to read the worldfile and construct a spatial
% referencing object.
filename = 'boston_ovr.jpg';
RGB = imread(filename);
R = worldfileread(getworldfilename(filename), 'geographic', size(RGB));

%% Example 7: Display Geographic Raster Data
% Display the RGB image onto a map axes. The limits of the map are set to
% the limits defined by the spatial referencing object, |R|. The
% coordinates of the data are in latitude and longitude.
figure
ax = usamap(RGB, R);
setm(ax, ...
    'MLabelLocation',.05, 'PLabelLocation',.05, ...
    'MLabelRound',-2, 'PLabelRound',-2)
geoshow(RGB, R)
title('Boston Overview')

%% Example 8: Display Geographic Vector and Raster Data
% You can display raster and vector data in a single map display. Since the
% coordinates for all of these data sets are in latitude and longitude, use
% |geoshow| to display them in a single map display. Setup new limits based
% on the limits of the route, placenames, and the overview image.
lat = [route.Latitude  placenames.Latitude  R.LatitudeLimits];
lon = [route.Longitude placenames.Longitude R.LongitudeLimits];
latlim = [min(lat) max(lat)];
lonlim = [min(lon) max(lon)];

%%
figure
ax = usamap(latlim, lonlim);
setm(ax, 'GColor','k', ...
    'PLabelLocation',.05, 'PLineLocation',.05)
geoshow(RGB, R)
geoshow(states.Latitude, states.Longitude, 'LineWidth', 2, 'Color', 'y')
geoshow(placenames)
geoshow(route.Latitude, route.Longitude)
title('Boston Overview and Geographic Vector Data')

%% Example 9: Customize a Map Display with a Scale Ruler
% Customize a map display by including a scale ruler. A scale ruler is a
% graphic object that shows distances on the ground at the correct size for
% the projection. This example illustrates how to construct a scale ruler
% that displays horizontal distances in international miles.

%%
% Compute latitude and longitude limits of Massachusetts and extend the
% limits by .05 degrees by using the |bufgeoquad| function.
latlim = [min(ma.Latitude),  max(ma.Latitude)];
lonlim = [min(ma.Longitude), max(ma.Longitude)];
[latlim, lonlim] = bufgeoquad(latlim, lonlim, .05, .05);

%%
% Display the state boundary, placenames, route, and overview image onto
% the map.
figure
ax = usamap(latlim, lonlim);
setm(ax, 'FFaceColor', oceanColor)
geoshow(states)
geoshow(ma, 'LineWidth', 1.5, 'FaceColor', [.5 .8 .6])
geoshow(RGB, R)
geoshow(placenames)
geoshow(route.Latitude, route.Longitude)
titleText = 'Massachusetts and Surrounding Region';
title(titleText)

%%
% Insert a scale ruler. You can determine a location for the scale ruler by
% using the |ginput| function as shown below:

%%
% [xLoc, yLoc] = ginput(1);

%%
% A location previously chosen is set below.
xLoc = -127800;
yLoc = 5014700;
scaleruler('Units', 'mi', 'RulerStyle', 'patches',  ...
    'XLoc', xLoc, 'YLoc', yLoc);
title({titleText, 'with Scale Ruler'})

%% Example 10: Customize a Map Display with a North Arrow
% Customize the map by adding a north arrow. A north arrow is a graphic
% element pointing to the geographic North Pole.
 
%%
% Use latitude and longitude values to position the north arrow.
northArrowLat =  42.5;
northArrowLon = -70.25;
northarrow('Latitude', northArrowLat, 'Longitude', northArrowLon);
title({titleText, 'with Scale Ruler and North Arrow'})

%% Example 11: Customize a Map Display with an Inset Map
% Customize the map by adding an inset map. An inset map is a small map
% within a larger map that enables you to visualize the larger geographic
% region of your main map. Create a map for the surrounding region as an
% inset map. Use the |axes| function to contain and position the inset map.
% In the inset map:
% 
% * Display the state boundaries for the surrounding region
% * Plot a red box to show the extent of the main map
% 
h2 = axes('Position', [.15 .6 .2 .2], 'Visible', 'off');
usamap({'PA','ME'})
plabel off; mlabel off
setm(h2, 'FFaceColor', 'w'); 
geoshow(states, 'FaceColor', [.9 .6 .7], 'Parent', h2)
plotm(latlim([1 2 2 1 1]), lonlim([2 2 1 1 2]), ...
    'Color', 'red', 'LineWidth', 2)
title(ax, {titleText, 'with Scale Ruler, North Arrow, and Inset Map'})

%% Credits
% boston_placenames.gpx:
%
%    Office of Geographic and Environmental Information (MassGIS),
%    Commonwealth of Massachusetts  Executive Office of Environmental Affairs
%    http://www.state.ma.us/mgis
%
%    For more information, run: 
%    
%    >> type boston_placenames_gpx.txt
%
% boston_ovr.jpg:
%
%    Copyright GeoEye 
%    Includes material copyrighted by GeoEye, all rights reserved. For more
%    information, please call 1.703.480.7539 or visit http://www.geoeye.com 
%
%    For more information, run: 
%    
%    >> type boston_ovr.txt

displayEndOfDemoMessage(mfilename)
