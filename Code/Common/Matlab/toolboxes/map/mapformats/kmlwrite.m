function kmlwrite(varargin)
%KMLWRITE Write geographic data to KML file
%
%   KMLWRITE(FILENAME, S) writes the geographic point or line features
%   stored in S to disk in KML format.
%
%   KMLWRITE(FILENAME, ADDRESS) specifies the location of a KML Placemark
%   via an unstructured address with city, state, and/or postal code.
%
%   KMLWRITE(FILENAME, LATITUDE, LONGITUDE) writes the latitude and
%   longitude points to disk in KML format. The altitude values in the KML
%   file are set to 0 and the interpretation is 'clampToGround'.
%
%   KMLWRITE(FILENAME, LATITUDE, LONGITUDE, ALTITUDE) writes the latitude,
%   longitude, and altitude points to disk in KML format. The altitude
%   values are interpreted as 'relativeToSeaLevel'.
%
%   KMLWRITE(..., Name, Value) specifies name-value pairs that set
%   additional KML feature properties. Parameter names can be abbreviated
%   and are case-insensitive.
%
%   Input Arguments
%   ---------------
%   FILENAME  - Character string specifying the output file name and
%               location. If an extension is included, it must be '.kml'.
%
%   S         - A geopoint vector, a geoshape vector with the Geometry
%               field set to 'point' or 'line', or a geostruct (with 'Lat'
%               and 'Lon' fields) and with the Geometry field set to either
%               'Point','Multipoint', or 'Line'.
%
%               If S is a geostruct and includes 'X' and 'Y' fields an
%               error is issued. The attribute fields of S are displayed as
%               a table in the description tag of the placemark for each
%               element of S, in the same order as they appear in S.
%
%               If S contains a field named either Elevation, Altitude, or
%               Height then the field values are written to the file as the
%               KML altitudes. If more than one name is included in S, then
%               a warning is issued and the altitude fields are ignored. If
%               a valid altitude field is contained in S, then the field
%               values are interpreted as 'relativeToSeaLevel', otherwise
%               altitude is set to 0 and is interpreted as 'clampToGround'.
%
%   ADDRESS   - String or cell array of strings which specifies the
%               location of a KML Placemark. Each string represents an
%               unstructured address with city, state, and/or postal code.
%               If ADDRESS is a cell array, each cell represents a unique
%               point.
%
%   LATITUDE  - Numeric vector specifying latitudes in the range [-90 90].
%
%   LONGITUDE - Numeric vector specifying longitudes. All longitudes are
%               automatically wrapped to the range [-180, 180], to adhere
%               to the KML specification.
%
%   ALTITUDE  - Numeric vector or scalar. If ALTITUDE is a scalar, the
%               value is applied to each point, otherwise it has the same
%               length as LATITUDE and LONGITUDE. The altitude values are
%               in units of meter. The altitude interpretation is
%               'relativeToSeaLevel'.
%
%   The name-value pairs are listed below:
%
%     Name
%          A string or cell array of strings which specifies a name
%          displayed in the viewer as the label for the object. If the
%          value is a string, the name is applied to all objects. If the
%          value is a cell array, it has the same length as LAT and LON, S,
%          or ADDRESS.
%
%          If unspecified, Name is set to 'Address N' for address data,
%          'Point N' for point data, or 'Line N' for line data where N is
%          the specific address, point, or line number. If multipoint data
%          is being written, the points are placed in a folder labeled
%          either with 'Multipoint N' or the corresponding Name value and
%          the points are labeled 'Point N'. If line data is written and
%          the line contains NaN values, the line segments are placed in a
%          folder labeled with the corresponding Name value and the line
%          segments are labeled 'Segment N'.
%
%     Description
%          A string, cell array of strings, or attribute spec, which
%          specifies the contents to be displayed in the feature's
%          description tag(s). The description appears in the description
%          balloon when the user clicks on either the feature name in the
%          Google Earth Places panel or clicks the placemark icon in the
%          viewer window. If the value is a string, the description is
%          applied to all objects. If the value is a cell array, it has the
%          same length as LAT and LON, S, or ADDRESS.  Use a cell array to
%          customize descriptive tags for different placemarks.
%
%          Description elements can be either plain text or marked up with
%          HTML. When it is plain text, Google Earth applies basic
%          formatting, replacing newlines with <br> and giving anchor tags
%          to all valid URLs for the World Wide Web. The URL strings are
%          converted to hyperlinks. This means that you do not need to
%          surround a URL with <a href> tags in order to create a simple
%          link. Examples of HTML tags recognized by Google Earth are
%          provided at http://earth.google.com.
%
%          When an attribute spec is provided, the attribute fields of S
%          are displayed as a table in the description tag of the placemark
%          for each element of S. The attribute spec is ignored with LAT
%          and LON input. The attribute spec controls:
%
%             * Which attributes are included in the table
%             * The name for the attribute
%             * The order in which attributes appear
%             * The formatting of numeric-valued attributes
%
%          The easiest way to construct an attribute spec is to call
%          makeattribspec, then modify the output to remove attributes or
%          change the Format field for one or more attributes.
%
%          Note that the latitude and longitude coordinates of S are not
%          considered to be attributes. If included in an attribute spec,
%          they are ignored.
%
%     Icon
%          A string or cell array of strings which specifies a custom icon
%          filename. If the value is a string, the value is applied to all
%          objects. If the value is a cell array, it has the same length as
%          LAT and LON, S, or ADDRESS.  If the icon filename is not in the
%          current folder, or in a folder on the MATLAB path, specify a
%          full or relative pathname. The string may be an Internet URL.
%          The URL must include the protocol type.
%
%     IconScale
%          A positive numeric scalar or vector which specifies a scaling
%          factor for the icon. If the value is a scalar, the value is
%          applied to all objects. If the value is a vector, it has the
%          same length as LAT and LON, S, or ADDRESS. 
%
%     Color
%          A MATLAB Color Specification (ColorSpec) for the icons or lines
%          (a string, cell array of strings, or numeric array with values
%          between 0 and 1). If the value is a cell array, it is the same
%          length as LAT and LON, S, or ADDRESS. If the value is a numeric
%          array, it is size M-by-3 where M is the length of LAT, LON, S,
%          or ADDRESS.
%
%    Width
%          A positive numeric scalar or vector which specifies the width of
%          the line in pixels. If the value is not scalar, it is the same
%          length as LAT, LON, S, or ADDRESS. If unspecified, the width of
%          the line is 1.
%
%     AltitudeMode
%          A string which specifies how altitude values are interpreted.
%          Permissible values are outlined in the table below. If altitude
%          values are not specified, the default value is 'clampToGround',
%          otherwise the default value is 'relativeToSeaLevel'.
%
%          Value                Description                    
%          ---------            -----------    
%          'clampToGround'      Indicates to ignore the altitude values and
%                               set the feature on the ground
%
%          'relativeToGround'   Sets altitude values relative to the actual
%                               ground elevation of a particular feature
%
%          'relativeToSeaLevel' Sets altitude values relative to sea level,
%                               regardless of the actual elevation values
%                               of the terrain beneath the feature
%                                                    
%     LookAt
%          A geopoint vector that defines the virtual camera that views the
%          points or lines. If the value is a scalar, the value is applied
%          to all the objects; otherwise, the length of the value is the
%          same length as LAT and LON, S, or ADDRESS. The value specifies
%          the view in terms of the point of interest that is being viewed.
%          The view is defined by the fields of the geopoint vector,
%          outlined in the table below. LookAt is limited to looking down
%          at a feature, you cannot tilt the virtual camera to look above
%          the horizon into the sky.
%           
%          Property     
%          Name       Description                     Data Type
%          ---------  ---------------------------     ---------
%          Latitude   Latitude of the point the       Scalar double
%                     camera is looking at in degrees
%            
%          Longitude  Longitude of the point the      Scalar double
%                     camera is looking at in degrees 
%
%          Altitude   Altitude of the point the       Scalar numeric
%                     camera is looking at in meters  default: 0
%                     (optional)   
%
%          Heading    Camera direction (azimuth)      Scalar numeric
%                     in degrees (optional)           [0 360], default: 0
%
%          Tilt       Angle between the direction of  Scalar numeric
%                     the LookAt position and the     [0 90], default: 0
%                     normal to the surface of the
%                     Earth (optional)               
% 
%          Range      Distance in meters from the     Scalar numeric
%                     point to the LookAt position    
%
%          AltitudeMode 
%                     Specifies how the altitude is   String with value:
%                     interpreted for the LookAt      'relativeToSeaLevel',
%                     point (optional)                'clampToGround', 
%                                           (default) 'relativeToGround'
%
%     Camera
%          A geopoint vector that defines the virtual camera that views the
%          scene. If the value is a scalar, the value is applied to all the
%          objects; otherwise, the length of the value is the same length
%          as LAT and LON, S, or ADDRESS. The value defines the position of
%          the camera relative to the Earth's surface as well as the
%          viewing direction of the camera. The camera position is defined
%          by the fields of the geopoint vector, outlined in the table
%          below. The camera value provides full six-degrees-of-freedom
%          control over the view, so you can position the camera in space
%          and then rotate it around the X, Y, and Z axes. Most
%          importantly, you can tilt the camera view so that you're looking
%          above the horizon into the sky.
%           
%          Property     
%          Name       Description                     Data Type
%          ---------  ---------------------------     ---------
%          Latitude   Latitude of the eye point       Scalar double
%                     (virtual camera) in degrees
%            
%          Longitude  Longitude of the eye point      Scalar double
%                     (virtual camera) in degrees 
%
%          Altitude   Distance of the camera from     Scalar numeric
%                     the Earth's surface, in meters 
%
%          Heading    Camera direction (azimuth)      Scalar numeric
%                     in degrees (optional)           [0 360], default 0
%
%          Tilt       Camera rotation in degrees      Scalar numeric
%                     around the X axis (optional)    [0 180] default: 0
% 
%          Roll       Camera rotation in degrees      Scalar numeric
%                     around the Z axis (optional)    default: 0
%
%          AltitudeMode 
%                     Specifies how camera altitude   String with value:
%                     is interpreted. (optional)      'relativeToSeaLevel',
%                                                     'clampToGround',
%                                           (default) 'relativeToGround'
%
%   Example 1
%   ---------
%   % Write the locations of the Boston placenames to a KML file.
%   placenames = gpxread('boston_placenames');
%   filename = 'Boston_Placenames.kml';
%   kmlwrite(filename, placenames, 'Name', placenames.Name, ...
%      'Color', jet(length(placenames)));
%
%   Example 2
%   ---------
%   % Write tracks from a GPX file to a KML file as a set of lines. 
%   % Set the color of the first line to red and the second to green.
%   % Set the width of both lines to 2.
%   % Set the description of each to the value in Metadata.Name.
%   % Set the names to 'track1' and 'track2'.
%   tracks = gpxread('sample_tracks', 'Index', 1:2);
%   filename = 'tracks.kml';
%   color = {'red', 'green'};
%   description = tracks.Metadata.Name;
%   name = {'track1', 'track2'};
%   kmlwrite(filename, tracks, 'Color', color, 'Width', 2, ...
%      'Description', description, 'Name', name);
% 
%   Example 3
%   ---------
%   % Write the locations of major European cities to a KML file, including 
%   % the names of the cities, and remove the default description table.
%   latlim = [ 30; 75];
%   lonlim = [-25; 45];
%   cities = shaperead('worldcities.shp','UseGeoCoords', true, ...
%      'BoundingBox', [lonlim, latlim]);
%   filename = 'European_Cities.kml';
%   kmlwrite(filename, cities, 'Name', {cities.Name}, 'Description',{});
%
%   Example 4
%   ---------
%   % Write the locations of several Australian cities to a KML file, 
%   % using addresses.
%   address = {'Perth, Australia', ...
%              'Melbourne, Australia', ...
%              'Sydney, Australia'};
%   filename = 'Australian_Cities.kml';
%   kmlwrite(filename, address, 'Name', address);
%
%   Example 5
%   ---------
%   % Write a single point to a KML file.
%   % Add a description containing HTML, a name and an icon.
%   lat =  42.299827;
%   lon = -71.350273;
%   description = sprintf('%s<br>%s</br><br>%s</br>', ...
%      '3 Apple Hill Drive', 'Natick, MA. 01760', ...
%      'http://www.mathworks.com');
%   name = 'The MathWorks, Inc.';
%   iconDir = fullfile(matlabroot,'toolbox','matlab','icons');
%   iconFilename = fullfile(iconDir, 'matlabicon.gif');
%   filename = 'MathWorks.kml';
%   kmlwrite(filename, lat, lon, ...
%      'Description', description, 'Name', name, 'Icon', iconFilename);
%
%   See also KMLWRITELINE, KMLWRITEPOINT, MAKEATTRIBSPEC, SHAPEWRITE

% Copyright 2007-2013 The MathWorks, Inc.

% Verify the number of varargin inputs.
narginchk(2,inf);

% Parse the input.
[filename, S, options] = map.internal.kmlparse(mfilename, 'any', varargin{:});

% Create a KML document object.
kml = map.internal.KMLDocument;

% Set the properties from the options structure.
map.internal.setProperties(kml, options);

% Add S to the document.
if isobject(S)
    addFeature(kml, S);
else
    addAddress(kml, S);
end

% Write the KML document to the file.
write(kml, filename);
