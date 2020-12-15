%% Exporting Vector Data to KML
%
% This example shows how to structure geographic point and line vector data
% and export it to a Keyhole Markup Language (KML) file. KML is an
% XML-based markup language designed for visualizing geographic data on
% Web-based maps or "Earth browsers", such as Google Earth(TM), Google
% Maps(TM), NASA WorldWind, and the ESRI(R) ArcGIS(TM) Explorer.
% 
% The following functions write geographic data to a KML file:
%
% * <http://www.mathworks.com/help/map/ref/kmlwritepoint.html kmlwritepoint> Write geographic points to KML file
% * <http://www.mathworks.com/help/map/ref/kmlwriteline.html kmlwriteline>   Write geographic line to KML file
% * <http://www.mathworks.com/help/map/ref/kmlwrite.html kmlwrite>           Write geographic data to KML file

% Copyright 2007-2013 The MathWorks, Inc.

%% Define an Output Folder for the KML Files
% This example creates several KML files and uses the variable |kmlFolder|
% to denote their location. The value used here is determined by the output
% of the |tempdir| command, but you could easily customize this.
kmlFolder = tempdir;

%% Create a Function Handle to Open an Earth Browser
% A KML file can be opened in a variety of "Earth browsers", Web maps, or
% an editor. You can customize the following anonymous function handle to
% open a KML file. Executing this function handle launches the Google Earth
% browser, which must be installed on your computer. You can use the
% application by assigning the variable |useApplication| to |true| in your
% workspace or assign it to |true| here.
useApplication = exist('useApplication', 'var') && useApplication;

%%
if useApplication
    if ispc
        % On Windows(R) platforms display the KML file with:
        openKML = @(filename) winopen(filename);
    elseif ismac
        % On Mac platforms display the KML file with:
        cmd = 'open -a Google\ Earth ';
        openKML = @(filename) system([cmd filename]);
    else
        % On Linux platforms display the KML file with:
        cmd = 'googleearth ';
        openKML = @(filename) system([cmd filename]);
    end
else
    % No "Earth browser" is installed on the system.
    openKML = @(filename) disp('');
end

%% Example 1: Write a Single Point to a KML File
% This example writes a single point to a KML file.

%%
% Assign latitude and longitude values for Paderborn, Germany.
lat = 51.715254;
lon =  8.75213;

%%
% Use |kmlwritepoint| to write the point to a KML file.
filename = fullfile(kmlFolder, 'Paderborn.kml');
kmlwritepoint(filename, lat, lon);

%%
% Open the KML file.
openKML(filename)

%%
% Create a cell array of the KML file names used in this example in order
% to optionally remove them from your KML output folder when the example
% ends. (This example needs to delete the generated files; in a real
% application you would probably want to omit this step.)
kmlFilenames = {};
kmlFilenames{1} = filename;

%% Example 2: Write a Single Point to a KML File with Icon and Description
% This example writes a single point to a KML file. The placemark includes
% an icon and a description with HTML markup.

%%
% Assign latitude and longitude coordinates for a point that locates the
% headquarters of MathWorks(R) in Natick, Massachusetts.
lat =  42.299827;
lon = -71.350273;

%%
% Create a description for the placemark. Include HTML tags in the
% description to add new lines for the address.
description = sprintf('%s<br>%s</br><br>%s</br>', ...
   '3 Apple Hill Drive', 'Natick, MA. 01760', ...
   'http://www.mathworks.com');

%%
% Assign |iconFilename| to a GIF file on the local system's network.
iconDir = fullfile(matlabroot,'toolbox','matlab','icons');
iconFilename = fullfile(iconDir, 'matlabicon.gif');

%%
% Assign the name for the placemark.
name = 'The MathWorks, Inc.';

%%
% Use |kmlwritepoint| to write the point and associated data to the KML
% file.
filename = fullfile(kmlFolder, 'MathWorks.kml');
kmlwritepoint(filename, lat, lon, ...
   'Description', description, ...
   'Name', name, ...
   'Icon', iconFilename);

%%
% Open the KML file.
openKML(filename)

%%
% Add |filename| to |kmlFilenames|.
kmlFilenames{end+1} = filename;

%% Example 3: Write Multiple Points to a KML File
% This example writes the locations of major European cities to a KML file,
% including the names of the cities, and removes the default description
% table.

%%
% Assign the latitude, longitude bounding box.
latlim = [ 30; 75];
lonlim = [-25; 45];

%%
% Read the data from the worldcities shapefile into a geostruct array.
cities = shaperead('worldcities.shp','UseGeoCoords', true, ...
    'BoundingBox', [lonlim, latlim]);

%%
% Convert to a |geopoint vector|.
cities = geopoint(cities);

%%
% Use |kmlwrite| to write the |geopoint vector| to a KML file. Assign the
% name of the placemark to the name of the city.  Remove the default
% description since the data has only one attribute.
filename = fullfile(kmlFolder, 'European_Cities.kml');
kmlwrite(filename, cities, 'Name', cities.Name, 'Description',{});

%%
% Open the KML file.
openKML(filename)

%%
% Add |filename| to |kmlFilenames|.
kmlFilenames{end+1} = filename;

%% Example 4: Write Multiple Points to a KML File with Modified Attribute Table
% This example writes placemarks at the locations of tsunami (tidal wave)
% events, reported over several decades and tagged geographically by
% source location, to a KML file.

%%
% Read the data from the tsunamis shapefile.
S = shaperead('tsunamis', 'UseGeoCoords', true);

%%
% Convert to a |geopoint vector|.
tsunamis = geopoint(S);

%%
% Sort the attributes.
tsunamis = tsunamis(:, sort(fieldnames(tsunamis)));
   
%%
% Construct an attribute specification.
attribspec = makeattribspec(tsunamis);

%%
% Modify the attribute specification to:
%%
% * Display Max_Height, Cause, Year, Location, and Country attributes 
% * Rename the 'Max_Height' field to 'Maximum Height' 
% * Highlight each attribute label with a bold font 
% * Set to zero the number of decimal places used to display Year
% * We have independent knowledge that the height units are meters, 
%   so we will add that to the Height format specifier
desiredAttributes = ...
   {'Max_Height', 'Cause', 'Year', 'Location', 'Country'};
allAttributes = fieldnames(attribspec);
attributes = setdiff(allAttributes, desiredAttributes);
attribspec = rmfield(attribspec, attributes);
attribspec.Max_Height.AttributeLabel = '<b>Maximum Height</b>';
attribspec.Max_Height.Format = '%.1f Meters';
attribspec.Cause.AttributeLabel = '<b>Cause</b>';
attribspec.Year.AttributeLabel = '<b>Year</b>';
attribspec.Year.Format = '%.0f';
attribspec.Location.AttributeLabel = '<b>Location</b>';
attribspec.Country.AttributeLabel = '<b>Country</b>';

%%
% Use |kmlwrite| to write the |geopoint vector| containing the selected
% attributes and source locations to a KML file.
filename = fullfile(kmlFolder, 'Tsunami_Events.kml');
kmlwrite(filename, tsunamis, 'Description', attribspec, ...
    'Name', tsunamis.Location)

%%
% Open the KML file.
openKML(filename)

%%
% Add |filename| to |kmlFilenames|.
kmlFilenames{end+1} = filename;

%% Example 5: Write a Single Point with a LookAt Attribute
% Create a placemark for Machu Picchu, Peru with a LookAt virtual
% camera.
 
%%
% Assign the coordinate values.
lat = -13.162806;
lon = -72.516244;

%%
% Create the LookAt |geopoint vector|.
lookAtLat = -13.209676;
lookAtLon = -72.503364;
range = 14794.88;
heading = 71.13;
tilt =  66.77;
lookAt = geopoint(lookAtLat, lookAtLon, ...
    'Range', range, ...
    'Heading', heading, ...
    'Tilt', tilt);

%%
% Use |kmlwritepoint| to write the point location and LookAt information.
filename = fullfile(kmlFolder, 'Machu_Picchu.kml');
kmlwritepoint(filename, lat, lon, 'LookAt', lookAt, ...
    'Name', 'Machu Picchu');

%%
% Open the KML file.
openKML(filename)

%%
% Add |filename| to |kmlFilenames|.
kmlFilenames{end+1} = filename;

%% Example 6: Write Address Data to a KML File
% This example writes unstructured address data to a KML file. 

%%
% Create a cell array containing names of several places of interest in the
% Boston area.
names = {'Boston', ...
    'Massachusetts Institute of Technology', ...
    'Harvard University', ...
    'Fenway Park', ...
    'North End'};

%%
% Create a cell array containing addresses for the places of interest in
% the Boston area.
addresses = { ...
    'Boston, MA', ...
    '77 Massachusetts Ave, Cambridge, MA', ...
    'Harvard University, Cambridge MA', ...
    '4 Yawkey Way, Boston, MA', ...
    '134 Salem St, Boston, MA'};

%%
% Use a Google Maps icon for each of the placemarks.
icon = 'http://maps.google.com/mapfiles/kml/paddle/red-circle.png';

%%
% Use |kmlwrite| to write the cell array of addresses to the KML file.
filename = fullfile(kmlFolder, 'Places_of_Interest.kml');
kmlwrite(filename, addresses, ...
    'Name', names, ...
    'Icon', icon, ...
    'IconScale', 1.5);
    
%%
% Open the KML file.
openKML(filename)

%%
% Add |filename| to |kmlFilenames|.
kmlFilenames{end+1} = filename;

%% Example 7: Write a Single Line to a KML File
% This examples writes a single line connecting the top of Mount Washington
% to the Mount Washington Hotel in Carroll, New Hampshire, to a KML file.

%% 
% Assign coordinate values for the region of interest.
lat_Mount_Washington = 44.270489039;
lon_Mount_Washington = -71.303246453;

lat_Mount_Washington_Hotel = 44.258056;
lon_Mount_Washington_Hotel = -71.440278;

lat = [lat_Mount_Washington lat_Mount_Washington_Hotel];
lon = [lon_Mount_Washington lon_Mount_Washington_Hotel];

%%
% Set the elevation value to a value of 6 feet, for the approximate height
% of a person.
elevation = 6 * unitsratio('meters', 'feet');

%%
% Add a camera viewpoint from the Mount Washington Hotel.
camera = geopoint(lat(2), lon(2), 'Altitude', 2, ...
    'Tilt', 90, 'Roll', 0, 'Heading', 90);

%%
% Use |kmlwriteline| to write the arrays to a KML file.
filename = fullfile(kmlFolder, 'Mount_Washington.kml');
kmlwriteline(filename, lat, lon, elevation, ...
    'Name', 'Mount Washington', 'Color', 'k', 'Width', 3, ...
    'Camera', camera, 'AltitudeMode', 'RelativeToGround');

%%
% Open the KML file.
openKML(filename)

%%
% Add |filename| to |kmlFilenames|.
kmlFilenames{end+1} = filename;

%% Example 8: Write a GPS Track Log to a KML File.
% This example writes a GPS track log to a KML file.

%%
% Read the track log from the GPX file. The data in the track log was
% obtained from a GPS wristwatch held while gliding over Mount Mansfield in
% Vermont, USA, on August 28, 2010.
track = gpxread('sample_mixed', 'FeatureType', 'track');

%%
% Use |kmlwriteline| to write the track log to a KML file. The elevation
% values obtained by the GPS are relative to sea level.
filename = fullfile(kmlFolder, 'GPS_Track_Log.kml');
kmlwriteline(filename, track.Latitude, track.Longitude, track.Elevation, ...
    'Name', 'GPS Track Log', ...
    'Color', 'k', ...
    'Width', 2, ...
    'AltitudeMode', 'RelativeToSeaLevel');

%%
% Open the KML file.
openKML(filename)

%%
% Add |filename| to |kmlFilenames|.
kmlFilenames{end+1} = filename;

%% Example 9: Write Multiple Lines to a KML File
% This example writes multiples lines as small circles around London City
% Airport. It includes a |LookAt| attribute.

%%
% Assign latitude and longitude values for the center of the feature.
lat0 = 51.50487;
lon0 = .05235;

%%
% Assign |azimuth| to [] to compute a complete small circle.
% Use the WGS84 ellipsoid.
azimuth = [];
e = wgs84Ellipsoid;

%%
% Compute small circles of 1000, 2000, and 3000 meter radius.
% Assign a color value of |'red'|, |'green'|, and |'blue'| for each circle.
% Use a |geoshape vector| to contain the line data.
radius = [1000 2000 3000];
colors = {'red', 'green', 'blue'};
circles = geoshape();
for k = 1:length(radius)
    [lat, lon] = scircle1(lat0, lon0, radius(k), azimuth, e);
    circles(k).Latitude = lat;
    circles(k).Longitude = lon;
    circles(k).Name = [num2str(radius(k)) ' Meters'];
    circles(k).Color = colors{k};
end

%%
% Assign elevation values of 100 meters (above ground).
circles.Elevation = [100 100 100];

%%
% Create a LookAt |geopoint vector| to create a viewpoint from the east of
% the airport and aligned with the runway.
lookAtLat = 51.503169;
lookAtLon =  0.105478;
range = 3500;
heading = 270;
tilt =  60;
lookAt = geopoint(lookAtLat, lookAtLon, 'Range', range, ...
    'Heading', heading, 'Tilt', tilt);

%%
% Use |kmlwrite| to write the |geoshape vector| containing the small circles
% and associated data to a KML file.
filename = fullfile(kmlFolder, 'Small_Circles.kml');
kmlwrite(filename, circles, ...
    'AltitudeMode','relativeToGround', ...
    'Name', circles.Name, ...
    'Color', circles.Color, ...
    'Width', 2, ...
    'LookAt', lookAt);

%%
% Open the KML file. Using Google Earth, the |LookAt| view point is set
% when clicking on either one of the |1000 Meters|, |2000 Meters|, or |3000
% Meters| strings in the Places list.
openKML(filename)

%%
% Add |filename| to |kmlFilenames|.
kmlFilenames{end+1} = filename;

%% Delete Generated KML Files
% Optionally, delete the new KML files from your KML output folder.
if ~useApplication
    for k = 1:length(kmlFilenames)
        delete(kmlFilenames{k})
    end
end

%% Credits
% worldcities.shp
%
%    Data from the Digital Chart of the World (DCW) browser layer,
%    published by U.S. National Geospatial-Intelligence Agency (NGA),
%    formerly National Imagery and Mapping Agency (NIMA).
%
% tsunamis.shp
%
%    Data from Global Tsunami Database, U.S. National Geospatial Data
%    Center (NGDC), National Oceanic and Atmospheric Administration (NOAA)
displayEndOfDemoMessage(mfilename)
