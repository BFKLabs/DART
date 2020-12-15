function wpt = gpxread(filename, varargin)
%GPXREAD Read GPX file
%
%   P = GPXREAD(FILENAME) reads point data from a GPX file and returns an
%   N-by-1 geopoint vector P. FILENAME is a string that specifies the name
%   of the GPX file. FILENAME can include the folder name. Otherwise, the
%   file must be in the current folder or in a folder on the MATLAB path.
%   If the named file includes the extension '.GPX' (either upper or lower
%   case), you can omit the extension from FILENAME.
%
%   P = GPXREAD(URL) reads the GPX data from a URL. The URL must include
%   the protocol type (e.g. 'http://').
%
%   The function searches first for waypoint, then route, then track
%   features. It returns the data of the first type found. The additional
%   track or route metadata is contained in the Metadata property of P. For
%   all feature types, the Metadata property contains a 'FeatureType'
%   field, with a string value corresponding to the feature type
%   ('waypoint', 'track', or 'route') read from the file. If no feature
%   type data is found in the file, the function returns an empty geopoint
%   vector.
%
%   If multiple feature types are found, only data from the first type
%   listed in the above order is returned. If the file contains any
%   waypoints, then P contains the waypoints. If the file contains routes
%   and may contain track logs, then P contains the points of the first
%   route. If the file contains only track logs, then P contains the points
%   of the first track. If the file contains track logs with multiple track
%   segments, then the coordinates of the segments are concatenated
%   together and contain NaN separators. NaN is used to denote numeric
%   elements not found in the file. The empty string ('') is used to denote
%   string elements not found in the file.
%
%   P = GPXREAD( ..., NAME, VALUE) reads point data from a GPX file with
%   additional options, specified by one or more NAME, VALUE pair
%   arguments, that control various characteristics of the import. NAME is
%   the argument name and VALUE is the corresponding value. NAME must
%   appear inside single quotes ('') and is case insensitive. You can
%   specify several name-value pair arguments in any order.
%
%   Name-Value Pair Arguments
%   -------------------------
%
%   'FeatureType'   String that specifies the type of feature to read from
%                   the file. The value may be one of the following
%                   case-insensitive strings: 'track', 'route', 'waypoint',
%                   or 'auto'. If the specified feature type is not found,
%                   then P is returned as an empty geopoint vector. The
%                   default value is 'auto'.
%
%   'Index'         Positive, integer-valued scalar or vector that
%                   specifies waypoints, routes, or track logs to read from
%                   the file. If the value is a scalar number greater than
%                   the total number of the specific element found in the
%                   file or an empty vector, then P is returned as an empty
%                   geopoint vector. If the value is a vector of positive,
%                   integer-valued numbers then those specific waypoints,
%                   routes, or track logs are returned in the order
%                   specified. Index values that exceed the number of
%                   elements of the specific feature type are ignored.
%
%                   When the Index value is specified as a vector of
%                   integer-valued numbers, P is returned as a geoshape
%                   vector, with Geometry set to 'line' if P contains track
%                   logs and 'point' if P contains routes. Any additional
%                   route or track metadata are stored as vectors within
%                   the Metadata property. If the Index value is
%                   unspecified, or specified as a scalar number, P is
%                   returned as a geopoint vector for all feature types. If
%                   P contains waypoints, the default value is 1:N, where N
%                   is the number of waypoints in the file; otherwise the
%                   default value is 1.
% 
%   GPX Version Support
%   -------------------
%   Excluding extensions, GPX version 1.1 is fully supported. If any other
%   version is detected, a warning is issued. However, in most cases,
%   version 1.0 GPX files can be read successfully unless they contain
%   certain metadata tags.
%
%   The GPX 1.1 schema documentation may be found at: <a
%   href="matlab:web('http://www.topografix.com/GPX/1/1/')
%   ">http://www.topografix.com/GPX/1/1/</a>
%
%   Example 1
%   ---------
%   % Read and display waypoints from the boston_placenames.gpx file.
%   p = gpxread('boston_placenames');
%   
%   % Overlay the points onto the boston.tif image.
%   % Includes material (c) GeoEye, all rights reserved.
%   % Read the image and convert the length unit of the X and Y 
%   % limits to meter for use with the projection structure which 
%   % has a length unit of meter.
%   [A,R] = geotiffread('boston');
%   proj = geotiffinfo('boston');
%   mstruct = geotiff2mstruct(proj);
%   R.XWorldLimits = R.XWorldLimits * proj.UOMLengthInMeters;
%   R.YWorldLimits = R.YWorldLimits * proj.UOMLengthInMeters;
%   figure('Renderer', 'zbuffer'); 
%   axesm(mstruct)
%   mapshow(A,R);
% 
%   % Display the names and positions of each point.
%   for k=1:length(p)
%      textm(p(k).Latitude, p(k).Longitude, p(k).Name, ...
%         'Color',[0 0 0],'BackgroundColor',[0.9 0.9 0],...
%         'Interpreter','none');
%   end
%   geoshow(p);
%   xlim(R.XWorldLimits)
%   ylim(R.YWorldLimits)
%
%   Example 2
%   ---------
%   % Read and display a route from Boston Logan International Airport
%   % to The MathWorks, Inc. in Natick, MA.
%   route = gpxread('sample_route');
%
%   % Compute latlim and lonlim with a .05 buffer.
%   [latlim, lonlim] = geoquadline(route.Latitude, route.Longitude);
%   [latlim, lonlim] = bufgeoquad(latlim, lonlim, .05, .05);
%   
%   % Display the route.
%   figure
%   pos = get(gcf, 'Position');
%   pos(1:2) = [300 300];
%   set(gcf, 'Position', pos .* [1 1 1.25 1.25]);
%   ax = usamap(latlim, lonlim);
%   setm(ax, 'MLabelParallel', 43.5)
%   geoshow(route.Latitude, route.Longitude)
% 
%   % Extract the elements of route that include descriptions of turns,
%   % mark and color code each turn on the map, and construct a legend
%   % that displays the descriptions. Reverse the order, so that the legend
%   % displays the first turn at the top and the last at the bottom.
%   turns = route(~cellfun(@isempty, route.Description));
%   turns = turns(end:-1:1);
%   n = length(turns);
%   colors = cool(n);
%   for k=1:n
%      geoshow(turns(k).Latitude, turns(k).Longitude, ...
%          'DisplayType','point','MarkerEdgeColor',colors(k,:),...
%          'Tag','turn','DisplayName',turns(k).Description)
%   end
%   legend(findobj(ax,'Tag','turn'),'Location','SouthOutside')
%
%   Example 3
%   ---------
%   % Read and display multiple track logs.
%   % Read the track logs from sample_tracks.gpx.
%   tracks = gpxread('sample_tracks', 'Index', 1:2);
%  
%   % Display the track logs. Use a SymbolSpec to set a different color
%   % for each track log. The sample GPX file contains a "number" element
%   % that is unique for each track.
%   [latlim, lonlim] = geoquadline(tracks.Latitude, tracks.Longitude);
%   tracks.Number = 1:length(tracks);
%   trackColor = makesymbolspec('Line', ...
%      {'Number', 1, 'Color', 'blue'}, ...
%      {'Number', 2, 'Color', 'red'});
%   figure; usamap(latlim, lonlim)
%   geoshow(tracks,'SymbolSpec', trackColor)
%
%   % Obtain latitude and longitude limits and a high-resolution
%   % ortho-image of the region.
%   [latlim, lonlim] = geoquadline(tracks(1).Latitude, tracks(1).Longitude);
%   orthoLayer = wmsfind('1_foot_imagery', 'MatchType', 'exact');
%   orthoLayer = orthoLayer(1);
%   height = 518; width = 1024;
%   try
%      [A, R] = wmsread(orthoLayer, 'Latlim', latlim, 'Lonlim', lonlim, ...
%         'ImageHeight', height, 'ImageWidth', width);
%   catch e
%       fprintf('%s\n%s\n', ...
%         'An error occurred with the WMS server.', e.message);
%       A = ones(height, width);
%       R = georasterref('LatitudeLimits',latlim,'LongitudeLimits',lonlim, ...
%          'RasterSize', size(A));
%   end
%
%   % Display the track logs near the MathWorks campus in Natick.
%   figure('Position', [300 300 840 630])
%   usamap(A, R)
%   setm(gca, 'MapLatLimit', latlim, 'MapLonLimit', lonlim)
%   geoshow(A, R)
%   h1 = geoshow(tracks(1), 'Color', 'cyan');
%   h2 = geoshow(tracks(2), 'Color', 'red');
%   names = tracks.Metadata.Name;
%   legend([h1 h2], names{:}, 'Location', 'SouthOutside')
%
%   Example 4
%   ---------
%   % Read and display waypoints and a track log  
%   % from the sample_mixed.gpx file.
%   wpt = gpxread('sample_mixed');
%   trk = gpxread('sample_mixed', 'FeatureType', 'track');
%  
%   % Compute latlim and lonlim with a .05 buffer.
%   lat = [trk.Latitude  wpt.Latitude];
%   lon = [trk.Longitude wpt.Longitude];
%   [latlim, lonlim] = geoquadline(lat, lon);
%   [latlim, lonlim] = bufgeoquad(latlim, lonlim, .05, .05);
%
%   % Display the waypoints and track log.
%   figure
%   pos = get(gcf, 'Position');
%   pos(1:2) = [300 300];
%   set(gcf, 'Position', pos .* [1 1 1.25 1.25]);
%   usamap(latlim, lonlim)
%   geoshow(trk.Latitude, trk.Longitude);
%
%   % Display the names and positions of each point.
%   h1 = geoshow(wpt(1));
%   h2 = geoshow(wpt(2), 'Marker', 'd');
%   names = wpt.Name;
%   legend([h1 h2], names{:});
%
%   Example 5
%   ---------
%   % Display elevation and time area maps and
%   % calculate distance using track logs.
%   % Read the track log from the sample_mixed.gpx file.
%   trk = gpxread('sample_mixed', 'FeatureType', 'track');
%
%   % Time values are stored as strings in the GPX file.
%   % Use datenum to convert the strings to serial date numbers.
%   % Compute the time-of-day in hours-minutes-seconds.
%   timeStr = strrep(trk.Time, 'T', ' ');
%   timeStr = strrep(timeStr, '.000Z', '');
%   trk.DateNumber = datenum(timeStr, 31);
%   day = fix(trk.DateNumber(1));
%   trk.TimeOfDay = trk.DateNumber - day;
%
%   % Display an area plot of the elevation and time values.
%   figure
%   area(trk.TimeOfDay, trk.Elevation)
%   datetick('x', 13, 'keepticks', 'keeplimits')
%   ylabel('elevation (meters)')
%   xlabel('time(Z) hours:minutes:seconds')
%   title({'Elevation Area Plot', datestr(day)});
%
%   % Calculate and display ground track distance.
%   % Convert distance in meter to distance in U.S. survey mile.
%   e = wgs84Ellipsoid;
%   lat = trk.Latitude;
%   lon = trk.Longitude;
%   d = distance(lat(1:end-1), lon(1:end-1), lat(2:end), lon(2:end), e);
%   d = d * unitsratio('sm', 'meter');
%
%   % Display the cumulative ground track distance and elapsed time.
%   trk.ElapsedTime = trk.TimeOfDay - trk.TimeOfDay(1);
%   figure
%   line(trk.ElapsedTime(2:end), cumsum(d))
%   datetick('x', 13)
%   ylabel('cumulative ground track distance (statute mile)')
%   xlabel('elapsed time  (hours:minutes:seconds)')
%   title({'Cumulative Ground Track Distance in Miles', datestr(day),  ...
%      ['Total Distance in Miles: ' num2str(sum(d))]});  
%
%   See also GEOPOINT, GEOSHAPE, SHAPEREAD

% Copyright 2011-2013 The MathWorks, Inc.

% Validate filename.
[filename, url] = internal.map.checkfilename( ...
    filename, {'gpx'}, mfilename, 1, true);

if (url)
    % Delete temporary file from Internet download regardless if any
    % errors are issued.
    clean = onCleanup(@() deleteDownload(filename));
end

% Parse the optional inputs.
[featureType, indexValue] = parseInputs(varargin);

% Parse the file.
document = parseFile(filename);

% Validate the version number.
 validateVersion(document);

% Obtain the output from the document.
wpt = convertDocument(document, featureType, indexValue);

%--------------------------------------------------------------------------

function [featureType, indexValue] = parseInputs(inputs)
% Parse the name/value inputs from the cell array, INPUTS.

% Assign values for parsepv.
names = {'FeatureType', 'Index'};
featureTypes = {'track', 'route', 'waypoint', 'auto'};
validateFcns = { ...
    @(x) (validatestring(x, featureTypes, mfilename, 'FeatureType')), ...
    @validateIndex};

% Parse and validate the values. Throw the error as caller to prevent a
% large stack trace.
try
    [S, ~, unmatched] = internal.map.parsepv(names, validateFcns, inputs{:});
catch e
    throwAsCaller(e)
end

% Verify that the first parameter is a string.
if ~isempty(inputs) && ~ischar(inputs{1})
    unmatched{1} = 'NAME1';
end

% Check if inputs contained unmatched parameters.
if ~isempty(unmatched)
    parameterNames = sprintf('''%s'', ', names{:});
    error(message('map:validate:invalidParameterName', ...
        unmatched{1}, parameterNames(1:end-2)));
end

% Assign default values if not provided.
default = {' '};
if isequal(S.FeatureType, default)
    featureType = 'auto';
else
    featureType = S.FeatureType;
end

if isequal(S.Index, default)
    indexValue = 'unspecified';
else
    indexValue = S.Index;
end

%--------------------------------------------------------------------------

function number = validateIndex(number)
% Validate Index value. The value may be a scalar positive integer-valued
% number or vector of positive integer-valued numbers. Use a function
% wrapper around validateattributes since it does not return any outputs
% and parsepv expects an output value.

validateattributes(number, {'numeric'}, ...
    {'integer', 'positive', 'vector'},  mfilename, 'Index');

%--------------------------------------------------------------------------

function document = parseFile(filename)
% Parse the file and return a com.mathworks.toolbox.geoweb.gpx.GPXDocument
% object.

% Obtain a GPX parser object.
parser = com.mathworks.toolbox.geoweb.gpx.GPXParser;
try
    % Read and obtain the document.
    parser.read(filename);
    document = parser.getDocument();
catch e
    % Parse the Java error message to remove all the stack trace
    % information.
    msg = parseMessage(e.message);

    % Issue an error message including the additional information.
    error(message('map:gpx:readError', filename, msg));
end

if isempty(document) ...
        || ~isa(document, 'com.mathworks.toolbox.geoweb.gpx.GPXDocument')
    error(message('map:gpx:expectedGPXFile', filename));
end

%--------------------------------------------------------------------------

function msg = parseMessage(msg)
% Parse the message string, msg, by obtaining only the actual message
% content rather than the message and stack trace.

% Java error messages consist of the following:
%  Java exception occurred: control character
%  package.ClassName:  error message content
%    control character
%    at (long stack trace)

% Find colon characters in the input message string.
colonIndex = strfind(msg, ':');

% Ensure at least two colon strings; otherwise the assumptions about the
% message string are invalid and just return the input message.
if numel(colonIndex) > 1  
    % Remove the sub-string from the  beginning "Java exception occurred:"
    % through the package.ClassName:
    msg(1:colonIndex(2)) = [];
    
    % Find control characters and remove the rest of the message.
    k = find(isstrprop(msg, 'cntrl'));
    
    % Ensure a control character is in the string.
    if ~isempty(msg) && numel(k) > 1
        % Remove all the characters past the first control character.
        msg = msg(1:k(1)-1);
        if isspace(msg(1))
            msg(1) = [];
        end
    end
end

%--------------------------------------------------------------------------

function validateVersion(document)
% Validate the GPX version number and issue an error if it doesn't conform
% to the standard.

standardVersion = '1.1';
version = char(document.getVersion);
if ~isequal(version, standardVersion)
    warning(message('map:gpx:versionMismatch', standardVersion, version));
end

%--------------------------------------------------------------------------

function wpt = convertDocument(document, featureType, indexValue)
% Convert the document object to a dynamic vector, wpt. 
%
% featureType is a string and is either:
%   'auto', 'track', 'route', or 'waypoint'
%
% indexValue is either a numeric, positive, integer-valued vector or a
% scalar or a string. It indicates specific waypoints, track logs or routes
% to read from the file. If indexValue is a vector within range and either
% routes or track logs are obtained from the file, then wpt is a geoshape
% vector; otherwise it is a geopoint vector.

switch featureType
    case 'auto'
        featureType = getFeatureType(document);
        wpt = convertDocument(document, featureType, indexValue);
        
    case 'track'
        wpt = getTracks(document, featureType, indexValue);
        
    case 'route'
        wpt = getRoutes(document, featureType, indexValue);
        
    case 'waypoint'
        wpt = getWaypoints(document, featureType, indexValue);
        
    otherwise
        % The case where the file does not contain any GPX elements and the
        % initial setting of featureType is 'auto'.
        wpt = geopoint;
end

%--------------------------------------------------------------------------

function wpt = getWaypoints(document, featureType, waypointIndex)
% Obtain waypoints from the document.

% Obtain the waypoints from the document object.
waypoints = document.getWayPoints.toArray;
numberOfWaypoints = numel(waypoints);

% Trim waypointIndex to fall with range of 1:numberOfWaypoints.
% waypointIndex may become empty, in which case wpt is returned as an empty
% geopoint vector. Specify 'waypoint' rather than featureType since this
% function is called by functions that also get waypoints for tracks and
% routes.
waypointIndex = trimRange(waypointIndex, numberOfWaypoints, 'waypoint');

% Check to see if the document contains any points within the specified
% range.
if ~isempty(waypoints) && ~isempty(waypointIndex)
    
    % For performance reasons, initialize lat, lon, elev, and time arrays.
    numpts = numel(waypointIndex);
    defaultValue = nan(1, numpts);
    lat  = defaultValue;
    lon  = defaultValue;
    elev = defaultValue;
    time = cell(1, numpts);
    [time{1:numpts}] = deal('');
    
    % Assign flags to determine if elev or time is supplied in the file.
    elevIsSupplied = false;
    timeIsSupplied = false;
    
    % Assign flags to determine whether to issue warnings if lat or lon
    % contains invalid values in the file.
    issueWarning = false;
    invalidCount = 0;
    
    % Assign the Elevation and Time values in order to set the order
    % correctly. Time is a cell array, so assign it dynamically to S in order
    % to not create a structure array.
    S = struct('Elevation', elev);
    S.Time = time;
    emptyCell = {''};
    
    % Loop through all the points and assign values to the geopoint vector.
    for k = 1:numpts
        waypoint = waypoints(waypointIndex(k));
        
        % The latitude and longitude values are stored in the XML file as
        % strings and read into a Java String variable. Convert the String
        % data to a MATLAB char. Some files encode the decimal point of the
        % latitude and longitude coordinates using a "," rather than a ".".
        % If found, replace the "," in order to convert the string to a
        % double. For any value that contains characters which cannot be
        % converted to a double, str2double returns a NaN.
        dlat = str2double(strrep(char(waypoint.getLatitude() ), ',', '.'));
        dlon = str2double(strrep(char(waypoint.getLongitude()), ',', '.'));
        if isempty(dlat) || isempty(dlon) || isnan(dlat) || isnan(dlon)
            % Empty coordinates cannot be stored into the geopoint vector.
            % When empty, convert the value to NaN. Keep track of the
            % number of invalid points and issue a warning after reading
            % all the waypoints.
            issueWarning = true;
            invalidCount = invalidCount + 1;
            lat(k) = NaN;
            lon(k) = NaN;
        else
            lat(k) = dlat;
            lon(k) = dlon;         
        end
        
        % Translate the name of each wpt XML element to a standard property
        % name. This must be done within the loop since each wpt may
        % contain different elements.
        wptNames = cell(waypoint.getElementNames.toArray);
        translatedNames = translateElementNames(wptNames);
        for l=1:numel(wptNames)
            elementName = translatedNames{l};
            elementValue = waypoint.getValue(wptNames{l});
            
            % Assign values to each property. Do not assign if the element
            % is empty since it could cause the property to be removed from
            % the geopoint vector.
            if ~isempty(elementValue)
                switch elementName
                    case 'Time'
                        time{k} = elementValue;
                        timeIsSupplied = true;
                        
                    case 'Elevation'
                        elev(k) = elementValue;
                        elevIsSupplied = true;
                        
                    otherwise
                        % Assign the value to S.
                        if iscell(elementValue) || ischar(elementValue)
                            if ~isfield(S, elementName)                                
                                S.(elementName) = emptyCell(1, ones(1, numpts));
                            end
                            S.(elementName){k} = elementValue;
                        else
                            if ~isfield(S, elementName)
                                S.(elementName) = zeros(1, numpts);
                            end
                            S.(elementName)(k) = elementValue;
                        end
                end
            end
        end
        
        % Assign the link value if available.
        link = getLink(waypoint);
        if ~isempty(link)
            if ~isfield(S, 'Link')
                S.Link = emptyCell(1, ones(1, numpts));
            end
            S.Link{k} = link;
        end
    end
    
    % Assign the values to the geopoint vector.
    if elevIsSupplied
        S.Elevation = elev;
    else
        S = rmfield(S, 'Elevation');
    end
    
    if timeIsSupplied
        S.Time = time;
    else
        S = rmfield(S, 'Time');
    end
    wpt = geopoint(lat, lon, S);
    wpt.Metadata.FeatureType = featureType;
    
    % Issue a warning if for any waypoint that was read, the lat or lon
    % value is missing or is non-standard.
    if issueWarning
        warning(message('map:gpx:nonstandardPoints', invalidCount));
    end 
else
    % The file does not contain any waypoints. Assign an empty geopoint
    % vector.
    wpt = geopoint;
    wpt.Metadata.FeatureType = featureType;
end

%--------------------------------------------------------------------------

function routes = getRoutes(document, featureType, routeNumbers)
% Obtain multiple routes from the document. 
%
% routeNumbers determines the type of output for routes according to
% the following table:
%
%    Type               Class of output
%    ------------       ---------------
%    scalar value       geopoint vector
%    string             geopoint vector
%    vector             geoshape vector (Geometry is 'point')
%    vector > range     empty geopoint vector

% Obtain the number of routes in the document.
numberOfRoutes = document.getRoutes.size();

if isnumeric(routeNumbers) && ~isscalar(routeNumbers)
    % Obtain the selected routes and return a geoshape vector (or a
    % geopoint vector if routeNumbers falls outside the range).
    fcn = @getRoute;
    routes = getMultipleElements(document, featureType, routeNumbers, ...
        numberOfRoutes, fcn);
    
    % Set Geometry property to 'point'.
    routes.Geometry = 'point';
else
    % Trim routeNumbers to fall with range of 1:numberOfRoutes.
    % routeNumbers may become empty, in which case routes is returned
    % as an empty geopoint vector.
    routeNumbers = trimRange(routeNumbers, numberOfRoutes, featureType);
    
    % Obtain the single track as a geopoint vector.
    routes = getRoute(document, featureType, routeNumbers);
end

%--------------------------------------------------------------------------

function tracks = getTracks(document, featureType, trackNumbers)
% Obtain one or more track logs from the document.
%
% trackNumbers determines the type of output for tracks according to
% the following table:
%
%    Type               Class of output
%    ------------       ---------------
%    scalar value       geopoint vector
%    string             geopoint vector
%    vector             geoshape vector (Geometry is 'line')
%    vector > range     empty geopoint vector

% Obtain the number of tracks in the document.
numberOfTracks = document.getTracks.size();

if isnumeric(trackNumbers) && ~isscalar(trackNumbers)
    % Obtain the selected tracks and return a geoshape vector (or a
    % geopoint vector if trackNumbers falls outside the range).
    fcn = @getTrack;
    tracks = getMultipleElements(document, featureType, trackNumbers, ...
        numberOfTracks, fcn);
else
    % Trim trackNumbers to fall with range of 1:numberOfTracks.
    % trackNumbers may become empty, in which case tracks is returned
    % as an empty geopoint vector.
    trackNumbers = trimRange(trackNumbers, numberOfTracks, featureType);
    
    % Obtain the single track as a geopoint vector.
    tracks = getTrack(document, featureType, trackNumbers);
end

%--------------------------------------------------------------------------

function wpt = getRoute(document, featureType, routeNumber)
% Obtain a GPX route for the specified scalar route number from the
% document. wpt contains a GPX route and is a geopoint vector.

% Obtain the routes.
routes = document.getRoutes.toArray;

% Check to see if the document contains any routes within the specified
% range.
if ~isempty(routeNumber) && ~isempty(routes)
    % Get the waypoints from the specified route.
    rte = routes(routeNumber);   
    wpt = getWaypoints(rte, featureType, 'all'); 
    
    % Assign the Metadata property values.
    wpt = getMetadata(rte, wpt);
else
    % There are no routes in the document or route number is greater than
    % number of routes. Return an empty geopoint vector.
    wpt = geopoint;
    wpt.Metadata.FeatureType = featureType;
end

%--------------------------------------------------------------------------

function wpt = getTrack(document, featureType, trackNumber)
% Obtain a GPX track for the specific scalar track number from the
% document. wpt contains a GPX track and is a geopoint vector.

% Obtain the tracks.
tracks = document.getTracks.toArray;

% Check to see if the document contains any tracks within the specified
% range.
if ~isempty(trackNumber) && ~isempty(tracks)
    trk = tracks(trackNumber);
    trkseg = getTrackSegments(trk, featureType);
    if iscell(trkseg)
        if numel(trkseg) > 1
            % More than one track segment exists in the file.
            % Concatenate the track segments using a geoshape vector.
            shape = geoshape;
            for k = 1:numel(trkseg)
                wpt = trkseg{k};
                props = properties(wpt);
                props(ismember({'Geometry','Metadata'},props)) = [];
                for n = 1:numel(props)
                    name = props{n};
                    shape(k).(name) = wpt.(name);
                end
            end
            
            % Convert geoshape vector to a geopoint vector.
            % By setting each geopoint property to the corresponding
            % geoshape value, we can efficiently manage the delimiters for
            % each track segment.
            props = properties(shape);
            props(ismember({'Geometry','Metadata'},props)) = []; 
            wpt = geopoint;
            wpt.Metadata.FeatureType = featureType;
            for n = 1:numel(props)
                name = props{n};
                wpt.(name) = shape.(name);
            end
        else
            % There is only one track segment in the document.
            wpt = trkseg{1};
        end
        
        % Assign Metadata property values.
        wpt = getMetadata(trk, wpt);

    else
        % There are no track segments in the document. wpt is an empty
        % geopoint vector.
        wpt = trkseg;
    end
else
    % There are no tracks in the document or track number is greater than
    % number of tracks.
    wpt = geopoint;
    wpt.Metadata.FeatureType = featureType;
end

%--------------------------------------------------------------------------

function wpt = getTrackSegments(document, featureType)
% Obtain waypoints from the track segments in the document. 
%
% wpt contains GPX waypoints. It is an empty geopoint vector if there are
% no track segments in the document; otherwise, it is a cell array of
% geopoint vectors.

trackseg = document.getTrackSegments.toArray;
if numel(trackseg) > 0 && ~isempty(trackseg)
    wpt = cell(1, numel(trackseg));
    for k=1:numel(trackseg)
        wpt{k} = getWaypoints(trackseg(k), featureType, 'all');
    end
else
    wpt = geopoint;
    wpt.Metadata.FeatureType = featureType;
end

%--------------------------------------------------------------------------

function elements = getMultipleElements( ...
    document, featureType, elementNumbers, numberOfElements, getElement)
% Obtain multiple track or route elements from document. 
% 
% elementNumbers is a vector of positive integer-valued numbers.
%
% numberOfElements is a scalar value indicating the maximum number of
% elements in the document.
%
% getElement is a handle to a function that retrieves a specific element.
%
% elements contains GPX routes or tracks and is a geoshape vector if XML
% elements are found in the file; otherwise it is an empty geopoint vector.

% Trim elementNumbers to fall with range of 1:numberOfElements.
% elementNumbers may become empty, in which case elements is returned as an
% empty geopoint vector.
elementNumbers = trimRange(elementNumbers, numberOfElements, featureType);


% Initialize meta as a geopoint vector which is used as a temporary
% container for the Metadata fields of each element.
meta = geopoint;

% Assign cell arrays for coordinates and dynamic properties for performance
% improvements.
numElements = numel(elementNumbers);
latitude = cell(1, numElements);
longitude = cell(1, numElements);
emptyPoints = false(1, numElements);
S = struct;

% Obtain each individual element and add the properties to elements.
for k = 1:numElements    
    % Obtain the geopoint vector, wpt, using the function handle,
    % getElement.
    elementNumber = elementNumbers(k);
    wpt = getElement(document, featureType, elementNumber);
    
    if ~isempty(wpt)
        % Copy Latitude and Longitude values.
        latitude{k}  = wpt.Latitude;
        longitude{k} = wpt.Longitude;
        
       % Copy other dynamic fields.
        names = fieldnames(wpt);
        for n = 1:length(names)
            value = wpt.(names{n});
            if iscell(value) && ~isfield(S, names{n})
                % Pre-initialize the cell array of strings.
                c = {{''}};               
                S.(names{n}) = c(1,ones(1, numElements));
                S.(names{n}){k} = value;
            else
                % value is either double or a cell array of strings. Do not
                % pre-initialize the field since if it is a cell array it
                % has already been pre-initialized and geoshape can handle
                % the size growth for doubles quickly and isfield is slow.
                % We are concerned in performance with not using subsasgn
                % in geoshape for each vertex element.
                S.(names{n}){k} = value;
            end
        end
        
        % Copy Metadata fields into the temporary meta geopoint vector
        % since they may be different for each element. The geopoint vector
        % handles missing field names correctly and keeps the arrays
        % synchronized in length. All GPX metadata elements are either
        % strings or numeric scalar values.
        names = setdiff(fieldnames(wpt.Metadata), 'FeatureType');
        for n = 1:length(names)
            meta(k).(names{n}) = wpt.Metadata.(names{n});
        end
    else
        emptyPoints(k) = true;
    end
end

% Initialize elements as a geoshape vector.
elements = geoshape(latitude, longitude, S);

% Remove those elements that did not have a waypoint.
elements(emptyPoints) = [];

if isempty(elements)
    % Return an empty geopoint vector if no data was found.
    elements = geopoint;
    elements.Metadata.FeatureType = featureType;
else
    % Assign Metadata fields
    elements.Metadata.FeatureType = featureType;
    if ~isempty(meta)        
        % Copy all the fields of meta to the Metadata structure.
        names = fieldnames(meta);
        for k = 1:length(names)
            elements.Metadata.(names{k}) = meta.(names{k});
        end
    end
end

%--------------------------------------------------------------------------

function wpt = getMetadata(document, wpt)
% Obtain metadata from the document.
 
if ~isa(document, 'com.mathworks.toolbox.geoweb.gpx.WayPoint') ...
        && ~isempty(document)
    % Obtain the element names from the document.
    elementNames = cell(document.getElementNames.toArray);
    if ~isempty(elementNames)
        % Translate the GPX element names to standard field names and
        % assign the translated names and values to the metadata structure.
        translatedNames = translateElementNames(elementNames);
        for l=1:numel(elementNames)
            elementName = translatedNames{l};
            elementValue = document.getValue(elementNames{l});
            wpt.Metadata.(elementName) = elementValue;
        end
    end
    % Assign the link value if present in the file.
    link = getLink(document);
    if ~isempty(link)
        wpt.Metadata.Link = link;
    end
else
    % A GPX waypoint does not include any additional metadata.
end

%--------------------------------------------------------------------------

function link = getLink(document)
% Obtain the link value from the document. link is empty if it is not 
% present in the document. If it is present in the document, and both href
% and text elements are set, then only the href value is returned.
% Otherwise, the text value is returned if set.

% Obtain the link value if available.
link = document.getLink();
if ~isempty(link)
    % Use the href value first, otherwise, use the text value.
    href = char(link.getHref());
    text = char(link.getText());
    if ~isempty(href)
        link = href;
    else
        link = text;
    end
end
        
%--------------------------------------------------------------------------

function featureType = getFeatureType(document)
% Get the feature type of the document by searching first for waypoint, 
% then route, then track features. If no features are found, return ''.

% The document getWayPoints, getRoute, and getTracks methods return a
% java.util.ArrayList. The size method returns the size of the array list
% and is 0 if there are no elements in the list.
if document.getWayPoints.size() > 0
    featureType = 'waypoint';
elseif document.getRoutes.size() > 0
    featureType = 'route';
elseif document.getTracks.size() > 0
    featureType = 'track';
else
    featureType = '';
end

%--------------------------------------------------------------------------

function x = trimRange(x, maxRange, featureType)
% Trim the vector X to fit within maxRange. If X is a char, then return X
% as a vector from 1:maxRange for waypoint feature types or return 1 for
% track and route feature types. Otherwise, X is a vector, trim X such that
% values outside of maxRange are removed.

if ischar(x)
    % x is a char value.
    if strcmp(featureType, 'waypoint')
        % featureType is a waypoint. The default is to read all waypoints.
        x = 1:maxRange;
    else
        % featureType is either track or route. The default is to read the
        % first element.
        x = 1;
    end
else
    % x is a vector of numbers. Remove values that are outside maxRange.
    x(x > maxRange) = [];
end

%--------------------------------------------------------------------------

function elementNames = translateElementNames(elementNames)
% Translate GPX element names to standard element names.

elementNames = cellfun(@translateName, elementNames, 'UniformOutput', false);
    
%--------------------------------------------------------------------------

function name = translateName(name)
% Translate a GPX element name to a standard element name. The parser
% ensures that NAME is a valid name. It ignores all others.

% For performance reasons, keep the translateMap as a persistent variable.
persistent translateMap
if isempty(translateMap)
    elementNames = {...
        'lat', 'lon', 'ele', 'time', ...
        'magvar', 'geoidheight', 'name', 'cmt', ...
        'desc', 'src', 'link', 'sym', 'type', ...
        'number', 'fix', 'sat', ...
        'hdop', 'vdop', 'pdop', ...
        'ageofdgpsdata', 'dgpsid'};
    
    translatedNames = { ...
        'Latitude', 'Longitude', 'Elevation', 'Time', ...
        'MagneticVariance', 'GeoidHeight', 'Name', 'Comment', ...
        'Description', 'Source', 'Link', 'Symbol', 'Type'...
        'Number', 'Fix', 'Satellite', ...
        'HDOP', 'VDOP', 'PDOP', ...
        'AgeOfDGPSData', 'DGPSID'};
    
    translateMap = containers.Map(elementNames, translatedNames);
end

% Translate the name using the map.
name = translateMap(name);
