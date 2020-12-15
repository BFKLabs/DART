function kmlwriteline(varargin)
%KMLWRITELINE Write geographic line to KML file
%
%   KMLWRITELINE(FILENAME, LATITUDE, LONGITUDE) writes the latitude and
%   longitude values to disk in KML format as a line. The altitude values
%   in the KML file are set to 0 and the interpretation is 'clampToGround'.
%
%   KMLWRITELINE(FILENAME, LATITUDE, LONGITUDE, ALTITUDE) writes the
%   latitude, longitude, and altitude values to disk in KML format as a
%   line. The altitude values are interpreted as 'relativeToSeaLevel'.
%
%   KMLWRITELINE(..., Name, Value) specifies name-value pairs that set
%   additional KML feature properties. Parameter names can be abbreviated
%   and are case-insensitive.
%
%   Input Arguments
%   ---------------
%   FILENAME  - Character string specifying the output file name and
%               location. If an extension is included, it must be '.kml'.
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
%          A string which specifies a name displayed in the viewer as the
%          label for the line. If unspecified, Name is set to 'Line 1'. If
%          the line contains NaN values, the line segments are placed in a
%          folder labeled with 'Line 1' and the line segments are labeled
%          'Segment N', where N varies from 1 to the number of segments.
%
%     Description
%          A string which specifies the contents to be displayed in the
%          line's description tag. The description appears in the
%          description balloon when the user clicks on either the feature
%          name in the Google Earth Places panel or clicks the line in the
%          viewer window.
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
%     Color
%          A MATLAB Color Specification (ColorSpec) which specifies a color
%          for the line (a string, scalar cell array containing a string,
%          or a 1-by-3 numeric vector with values between 0 and 1).
%
%    Width
%          A positive numeric scalar which specifies the width of the line
%          in pixels. If unspecified, the width of the line is 1.
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
%          A scalar geopoint vector that defines the virtual camera that
%          views the line. The value specifies the view in terms of the
%          line of interest that is being viewed. The view is defined by
%          the fields of the geopoint vector, outlined in the table below.
%          LookAt is limited to looking down at a feature, you cannot tilt
%          the virtual camera to look above the horizon into the sky.
%           
%          Property     
%          Name       Description                     Data Type
%          ---------  ---------------------------     ---------
%          Latitude   Latitude of the line the       Scalar double
%                     camera is looking at in degrees
%            
%          Longitude  Longitude of the line the      Scalar double
%                     camera is looking at in degrees 
%
%          Altitude   Altitude of the line the       Scalar numeric
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
%                     line to the LookAt position    
%
%          AltitudeMode 
%                     Specifies how the altitude is   String with value:
%                     interpreted for the LookAt      'relativeToSeaLevel',
%                     line (optional)                'clampToGround', 
%                                           (default) 'relativeToGround'
%                                                    
%     Camera
%          A scalar geopoint vector that defines the virtual camera that
%          views the scene. The value defines the position of the camera
%          relative to the Earth's surface as well as the viewing direction
%          of the camera. The camera position is defined by the fields of
%          the geopoint vector, outlined in the table below. The camera
%          value provides full six-degrees-of-freedom control over the
%          view, so you can position the camera in space and then rotate it
%          around the X, Y, and Z axes. Most importantly, you can tilt the
%          camera view so that you're looking above the horizon into the
%          sky.
%           
%          Property     
%          Name       Description                     Data Type
%          ---------  ---------------------------     ---------
%          Latitude   Latitude of the eye line       Scalar double
%                     (virtual camera) in degrees
%            
%          Longitude  Longitude of the eye line      Scalar double
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
%   % Write the coast line to a KML file as a black line.
%   coast = load('coast');
%   filename = 'coast.kml';
%   kmlwriteline(filename, coast.lat, coast.long, 'Color','black', ...
%      'Width', 3);
%
%   Example 2
%   ---------
%   % Write a single GPS track log to a KML file.
%   S = gpxread('sample_tracks');
%   filename = 'track.kml';
%   kmlwriteline(filename, S.Latitude, S.Longitude, S.Elevation, ...
%      'Description', S.Metadata.Name, 'Name', 'Track Log');
%
%   See also KMLWRITE, KMLWRITEPOINT, SHAPEWRITE

% Copyright 2012-2013 The MathWorks, Inc.

% Verify the number of varargin inputs.
narginchk(3, inf);

% Parse the input.
[filename, S, options] = map.internal.kmlparse(mfilename, 'line', varargin{:});

% Create a KML document object.
kml = map.internal.KMLDocument;

% Set the properties from the options structure.
map.internal.setProperties(kml, options);

% Add S to the document.
addFeature(kml, S);
 
% Write the KML document to the file.
write(kml, filename);
