%% Compositing and Animating Web Map Service (WMS) Meteorological Layers
%
% This example shows how to composite and animate data from multiple Web
% Map Service (WMS) layers.
%
% The base layer is from the NASA Goddard Space Flight Center's Scientific
% Visualization Studio (SVS) Image Server. The data in this layer shows
% satellite cloud data during Hurricane Katrina from August 23 through
% August 30, 2005. The layer consists of cloud data extracted from GOES-12
% imagery and overlaid on a color image of the southeast United States.
%
% Next-Generation Radar (NEXRAD) images, collected by the Iowa State
% University's Iowa Environmental Mesonet (IEM) Web map server, are
% composited with the cloud data at regular intervals of time.
%
% In particular, this example will show you how to:
%
% * Use the WMS database to find the Katrina and NEXRAD layers
% * Retrieve the Katrina base map from a WMS server at a particular time-step
% * Retrieve the NEXRAD map from a WMS server at the same time-step
% * Composite the base map with the map containing the NEXRAD imagery
% * View the composited map in a projected coordinate system
% * Retrieve, composite, and animate multiple time sequences
% * Create a video file and animated GIF file of the animation

% Copyright 2010-2012 The MathWorks, Inc.

%% Understanding Basic WMS Terminology
% If you are new to WMS, several key concepts are important to understand
% and are listed here.
%%
% 
% * _Web Map Service_  --- The Open Geospatial Consortium (OGC) defines a 
%   Web Map Service (WMS) to be an entity that "produces maps of spatially
%   referenced data dynamically from geographic information."
% * _WMS server_ --- A server that follows the guidelines of the OGC to 
%   render maps and return them to clients
% * _map_ --- The OGC definition for map is "a portrayal of geographic 
%   information as a digital image file suitable for display on a computer 
%   screen."
% * _layer_ --- A dataset of a specific type of geographic information, such 
%   as temperature, elevation, weather, orthophotos, boundaries, 
%   demographics, topography, transportation, environmental measurements, 
%   and various data from satellites
% * _capabilities document_ --- An XML document containing metadata 
%   describing the geographic content offered by a server

%% Source Function
% The code shown in this example can be found in this function:
function mapexwmsanimate(useInternet, datadir)

%% Internet Access
% Since WMS servers are located on the Internet, this example can be set to
% access the Internet to dynamically render and retrieve maps from WMS
% servers or it can be set to use data previously retrieved from the
% Internet using the WMS capabilities but now stored in local files. You
% can use a variable, |useInternet|, to determine whether to read data from
% locally stored files, or retrieve the data from the Internet.
%
% If the |useInternet| flag is set to true, then an Internet connection
% must be established to run the example. Note that the WMS servers may be
% unavailable, and several minutes may elapse before the maps are returned.
% One of the challenges of working with WMS servers is that sometimes you
% will encounter server errors. A function, such as |wmsread|, may time out
% if a server is unavailable. Often, this is a temporary problem and you
% will be able to connect to the server if you try again later. For a list
% of common problems and strategies for working around them, please see the
% Common Problems with WMS Servers section in the Mapping Toolbox(TM)
% User's Guide.
%
% You can store the data locally the first time you run the example and
% then set the |useInternet| flag to false. If the |useInternet| flag is
% not defined, it is set to false.
if ~exist('useInternet', 'var') 
    useInternet = false;
end

%% Setup: Define a Data Directory and Filename Utility Function
% This example writes data to files if |useInternet| is |true| or reads data
% from files if |useInternet| is |false|. It uses the variable |datadir| to
% denote the location of the folder containing the data files.
if ~exist('datadir', 'var')
    datadir = fullfile(fileparts(which('mapexwmsanimate')), 'html');
end
if ~exist(datadir, 'dir')
    mkdir(datadir)
end

%%
% Define an anonymous function to prepend |datadir| to the input filename:
datafile = @(filename) fullfile(datadir, filename);

%% Step 1: Find Katrina Layers From Local Database
% One of the more challenging aspects of using WMS is finding a WMS server
% and then finding the layer that is of interest to you. The process of
% finding a server that contains the data you need and constructing a
% specific and often complicated URL with all the relevant details can be 
% very daunting. 
%
% The Mapping Toolbox(TM) simplifies the process of locating WMS servers
% and layers by providing a local, installed, and pre-qualified WMS
% database, that is searchable, using the function |wmsfind|. You can
% search the database for layers and servers that are of interest to you.
% Here is how you find layers containing the term |katrina| in either the
% |LayerName| or |LayerTitle| field of the database:
katrina = wmsfind('katrina');
whos katrina

%%
% The search for the term |'katrina'| returned a |WMSLayer| array
% containing multiple layers. To inspect information about an individual
% layer, simply display it like this:
katrina(1)

%%
% If you type, |katrina|, in the command window, the entire contents of the
% array are displayed, with each element's index number included in the
% output. This display makes it easy for you to examine the entire array
% quickly, searching for a layer of interest. You can display only the
% |LayerTitle| property for each element by executing the command:
% 
% |katrina.disp('Properties', 'layertitle', 'Index', 'off', 'Label', 'off');|

%%
% As you've discovered, a search for the generic word |'katrina'| returned
% results of many layers and you need to select only one layer. In general,
% a search may even return thousands of layers, which may be too large to
% review individually. Rather than searching the database again, you may
% refine your search by using the |refine| method of the |WMSLayer| class.
% Using the |refine| method is more efficient and returns results faster
% than |wmsfind| since the search has already been narrowed to a smaller
% set. Supplying the query string,
% |'goes-12*katrina*visible*close*up*animation'|, to the |refine| method
% returns a |WMSLayer| array whose elements contain a match of the query
% string in either the |LayerTitle| or |LayerName| properties. The |*|
% character indicates a wild-card search. If multiple entries are returned,
% select only the first one from the svs.gsfc.nasa.gov server.
katrina = katrina.refine('goes-12*katrina*visible*close*up*animation');
katrina = katrina.refine('svs.gsfc.nasa.gov', 'Searchfield', 'serverurl');
katrina = katrina(1);
whos katrina

%% Step 2: Synchronize WMSLayer Object with Server
% The database only stores a subset of the layer information. For example,
% information from the layer's abstract, details about the layer's
% attributes and style information, and the coordinate reference system of
% the layer are not returned by |wmsfind|. To return all the information,
% you need to use the |wmsupdate| function. |wmsupdate| synchronizes the
% layer from the database with the server, filling in the missing
% properties of the layer.
%
% Synchronize the first |katrina| layer with the server in order to obtain
% the abstract information. Since this action requires access to the
% Internet, call |wmsupdate| only if the |useInternet| flag is true.
cachefile = datafile('katrina.mat');
if useInternet
    katrina = wmsupdate(katrina);
    if ~exist(cachefile, 'file')
        save(cachefile, 'katrina')
    end
else
    cache = load(cachefile);
    katrina = cache.katrina;
end

%%
% Display the abstract information of the layer. Use |isspace| to help
% determine where to line wrap the text.
abstract = katrina.Abstract;
numSpaces = 60;
while(~isempty(abstract))
    k = find(isspace(abstract));
    n = find(k > numSpaces,1);
    if ~isempty(n)
        fprintf('%s\n', abstract(1:k(n)))
        abstract(1:k(n)) = [];
    else
        fprintf('%s\n', abstract)
        abstract = '';
    end
end

%%
% Note that this abstract information, including any typographical issues
% and incomplete fragments, was obtained directly from the server.

%% Step 3: Explore Katrina Layer Details
% You can find out more information about the |katrina| layer by exploring
% the |Details| property of the |katrina| layer. The |Details.Attributes|
% field informs you that the layer has fixed width and fixed height
% attributes, thus the size of the requested map cannot be modified.
disp(katrina.Details.Attributes)

%%
% The |Details.Dimension| field informs you that the layer has a |time|
% dimension 
disp(katrina.Details.Dimension)

%%
% with an extent from |2005-08-23T17:45Z| to |2005-08-30T17:45Z|
% with a period of |P1D| (one day), as shown in the
% |Details.Dimension.Extent| field. 
disp(katrina.Details.Dimension.Extent)

%% Step 4: Retrieve Katrina Map from Server
% Now that you have found a layer of interest, you can retrieve the raster
% map using the function |wmsread| and display the map using the function
% |geoshow|. Since |Time| is not specified when reading the layer, the
% default time, |2005-08-30T17:45Z|, is retrieved as specified by the
% |Details.Dimension.Default| field. If the |useInternet| flag is set to
% true, then cache the image and referencing matrix in a GeoTIFF file.
cachefile = datafile('katrina.tif');
if useInternet
    [katrinaMap, R] = wmsread(katrina);
    if ~exist(cachefile, 'file')
        geotiffwrite(cachefile, katrinaMap, R);
    end
else
    [katrinaMap, R] = geotiffread(cachefile);
end

%%
% Display the |katrinaMap| and overlay the data 
% from the |usastatehi.shp| file.
states = shaperead('usastatehi.shp', 'UseGeoCoords', true);
figure
usamap(katrina.Latlim, katrina.Lonlim)
geoshow(katrinaMap, R)
geoshow(states, 'FaceColor', 'none')
title({katrina.LayerTitle, katrina.Details.Dimension.Default}, ...
    'Interpreter', 'none');

%% Step 5: Find NEXRAD Radar Layer
% NEXRAD radar images for the United States are stored on the Iowa State
% University's IEM Web map server. The server conveniently stores NEXRAD
% images in five minute increments from |1995-01-01| to the present time.
% You can find the layer by first searching for the term |IEM WMS Service|
% in the |ServerTitle| field of the WMS database, then refining the search
% by requesting the layer of interest, |nexrad-n0r-wmst|.
iemLayers  = wmsfind('IEM WMS Service', 'SearchField', 'servertitle');
nexrad = iemLayers.refine('nexrad-n0r-wmst');

%%
% Synchronize the layer with the server.
cachefile = datafile('nexrad.mat');
if useInternet
    nexrad = wmsupdate(nexrad);
    if ~exist(cachefile, 'file')
        save(cachefile, 'nexrad')
    end
else
    cache = load(cachefile);
    nexrad = cache.nexrad;
end

%% Step 6: Obtain Extent Parameters
% To composite the |nexrad| layer with the |katrina| layer, you need to
% obtain the |nexrad| layer at coincidental time periods, and concurrent
% geographic and image extents. The |Details.Dimension| field informs you
% that the layer has a time dimension,
disp(nexrad.Details.Dimension)

%%
% and the |Details.Dimension.Default| field informs you that the layer's
% time extent includes seconds.
disp(nexrad.Details.Dimension.Default)

%%
% Obtain a time value coincidental with the |katrina| layer, and add
% seconds to the time specification.
nexradTime = [katrina.Details.Dimension.Default(1:end-1) ':00Z'];

%%
% Assign |latlim| and |lonlim| variables. Note that the |nexrad| layer 
% limits
disp(nexrad.Latlim)
disp(nexrad.Lonlim)

%%
% do not extend as far south as the |katrina| layer limits. 
disp(katrina.Latlim)
disp(katrina.Lonlim)

%%
% When reading the |nexrad| layer, values that lie outside the geographic
% bounding quadrangle of the layer are set to the background color.
latlim = katrina.Latlim;
lonlim = katrina.Lonlim;

%%
% Assign |imageHeight| and |imageWidth| variables.
imageHeight = katrina.Details.Attributes.FixedHeight;
imageWidth  = katrina.Details.Attributes.FixedWidth;

%% Step 7: Retrieve NEXRAD Radar Map from Server
% You can retrieve the |nexradMap| from the server, specified at the same
% time as the |katrinaMap| and for the same geographic and image extents,
% by supplying parameter/value pairs to the |wmsread| function. To
% accurately retrieve the radar signal from the map, set the |ImageFormat|
% parameter to the |image/png| format. In order to easily retrieve the
% signal from the background, set the background color to black (|[0 0 0]|).
%
% Retrieve the |nexradMap|.
black = [0 0 0];
cachefile = datafile('nexrad.tif');
if useInternet
    [nexradMap, R] = wmsread(nexrad, ...
        'Latlim', latlim, 'Lonlim', lonlim, ...
        'Time', nexradTime, 'BackgroundColor', black, ...
        'ImageFormat', 'image/png', ...
        'ImageHeight', imageHeight, 'ImageWidth', imageWidth);
    if ~exist(cachefile, 'file')
        geotiffwrite(cachefile, nexradMap, R);
    end
else
    [nexradMap, R] = geotiffread(cachefile);
end

%%
% Display the |nexradMap|.
figure
usamap(latlim, lonlim)
geoshow(nexradMap, R)
geoshow(states, 'FaceColor', 'none', 'EdgeColor', 'white')
title({nexrad.LayerTitle, nexradTime}, 'Interpreter', 'none');

%% Step 8: Composite NEXRAD Radar Map with Katrina Map
% To composite the |nexradMap| with a copy of the |katrinaMap|, you need to
% identify the non-background pixels in the |nexradMap|. The |nexradMap|
% data is returned as an image with class double, because of how this web
% map server handles |PNG| format, so you need convert it to |uint8| before
% merging.
%
% Identify the pixels of the |nexradMap| image
% that do not contain the background color.
threshold = 0;
index = any(nexradMap > threshold, 3);
index = cat(3, index, index, index);

%%
% Composite the |nexradMap| with the |katrinaMap|.
combination = katrinaMap;
combination(index) = uint8(nexradMap(index)*255);

%%
% Display the composited map.
figure
usamap(latlim, lonlim)
geoshow(combination, R);
geoshow(states, 'FaceColor', 'none')
title({'GOES 12 Imagery of Hurricane Katrina', ...
    'Composited with NEXRAD Radar', nexradTime})

%% Step 9: Initialize Variables to Animate the Katrina and NEXRAD Maps
% The next step is to initialize variables in order to  animate the 
% composited |katrina| and |nexrad| maps.
%
% Create variables that contain the time extent 
% of the |katrina| layer. 
extent = katrina.Details.Dimension.Extent;
slash = '/';
slashIndex = strfind(extent, slash);
startTime = extent(1:slashIndex(1)-1);
endTime = extent(slashIndex(1)+1:slashIndex(2)-1);

%%
% Calculate numeric values for the start and end days. 
% Note that the time extent is in |yyyy-mm-dd| format.
hyphen = '-';
hyphenIndex = strfind(startTime, hyphen);
dayIndex = [hyphenIndex(2) + 1, hyphenIndex(2) + 2];
startDay = str2double(startTime(dayIndex));
endDay = str2double(endTime(dayIndex));

%%
% Assign the initial katrinaTime.
katrinaTime = startTime;

%%
% Since multiple requests to a server are required for animation, it is
% more efficient to use the |WebMapServer| and |WMSMapRequest| classes.
%
% Construct a |WebMapServer| object for each layer's server.
nasaServer = WebMapServer(katrina.ServerURL);
iemServer  = WebMapServer(nexrad.ServerURL);

%%
% Create |WMSMapRequest| objects.
katrinaRequest = WMSMapRequest(katrina, nasaServer);
nexradRequest  = WMSMapRequest(nexrad, iemServer);

%%
% Assign properties.
nexradRequest.Latlim = latlim;
nexradRequest.Lonlim = lonlim;
nexradRequest.BackgroundColor = black;
nexradRequest.ImageFormat = 'image/png';
nexradRequest.ImageHeight = imageHeight;
nexradRequest.ImageWidth  = imageWidth;

%% Step 10: Create Animation Files
% An animation can be viewed in the browser when the browser opens an
% animated GIF file or an AVI video file. To create the animation frames of
% the WMS basemap and vector overlays, create a loop through each day, from
% |startDay| to |endDay|, and obtain the |katrinaMap| and the |nexradMap|
% for that day. Composite the maps into a single image, display the image,
% retrieve the frame, and store the results into a frame of an AVI file and
% a frame of an animated GIF file.
%
% To share with others or to post to web video services, create an AVI
% video file containing all the frames using the VideoWriter class.
videoFilename = fullfile(pwd,'wmsanimated.avi');
if exist(videoFilename, 'file')
    delete(videoFilename)
end
writer = VideoWriter(videoFilename);
writer.FrameRate = 1;
writer.Quality = 100;
writer.open;

%%
% Create a temporary filename to contain a single frame. Use the
% |onCleanup| class to automatically delete the file when finished.
framefile = [tempname '.png'];
clean = onCleanup(@()delete(framefile));

%%
% The animation is viewed in a single map display. Outside the animation
% loop, create a map display. Initialize |hmap|, used in the loop as the
% return handle from the function |geoshow|, so it can be deleted on the
% first pass through the loop. Loop through each day, retrieve and display
% the WMS map, and save the frame.
hfig = figure;
usamap(latlim, lonlim);
geoshow(states, 'FaceColor', 'none')
hmap = [];

for k = startDay:endDay
    
    % Update the time values and assign the
    % Time property for each server.
    currentDay = num2str(k);
    katrinaTime(dayIndex) = currentDay;
    nexradTime = [katrinaTime(1:end-1) ':00Z'];
    katrinaRequest.Time = katrinaTime;
    nexradRequest.Time  = nexradTime;
    
    % Retrieve the WMS map of Katrina from the server (or file)
    % for this time period.
    cachefile = datafile(['katrina_' num2str(currentDay) '.tif']);
    if useInternet
        katrinaMap = nasaServer.getMap(katrinaRequest.RequestURL);
        if ~exist(cachefile, 'file')
            geotiffwrite(cachefile, katrinaMap, katrinaRequest.RasterRef);
        end
    else
        katrinaMap = geotiffread(cachefile);
    end
    
    % Retrieve the WMS map of the NEXRAD imagery from the server (or file)
    % for this time period.
    cachefile = datafile(['nexrad_' num2str(currentDay) '.tif']);
    if useInternet
        nexradMap = iemServer.getMap(nexradRequest.RequestURL);
        if ~exist(cachefile, 'file')
            geotiffwrite(cachefile, nexradMap, nexradRequest.RasterRef);
        end
    else
        nexradMap = geotiffread(cachefile);
    end
    
    % Identify the pixels of the nexradMap image
    % that do not contain the background color.
    index = any(nexradMap > threshold, 3);
    index = index(:,:,[1 1 1]);
    
    % Composite the nexradMap with the katrinaMap.
    combination = katrinaMap;
    combination(index) = uint8(nexradMap(index)*255);
    
    % Delete the old map and display the new composited map.
    delete(hmap)
    hmap = geoshow(combination, katrinaRequest.RasterRef);
    title({'GOES 12 Imagery of Hurricane Katrina', ...
        'Composited with NEXRAD Radar', nexradTime})
    drawnow
    
    % Save the current frame.
    print('-dpng', '-r100', framefile);
    
    % Convert the RGB frame to an indexed image to save into the
    % animated array.
    rgbFrame = imread(framefile);
    if k == startDay
        % The first time through the loop, save the colormap into the
        % variable, |cmap|. Use |cmap| to convert later frames.
        [frame, cmap] = rgb2ind(rgbFrame, 256, 'nodither');
        
        % Use the size of the first frame and the total
        % number of frames to initialize |animated| with
        % a size large enough to contain all the frames.
        frameSize = size(frame);
        numFrames = endDay - startDay + 1;
        animated = zeros(frameSize(1), frameSize(2), 1, numFrames, ...
            'like', frame);
    else
        % Use the colormap from the first frame conversion and
        % convert this frame to an indexed image.
        frame = rgb2ind(rgbFrame, cmap, 'nodither');
    end
   
    % Store the frame into the animated array for the GIF file.
    frameCount = k - startDay + 1;
    animated(:,:,1,frameCount) = frame;
    
    % Write the RGB frame to the AVI file.
    writer.writeVideo(rgbFrame);
end

% Close the Figure window and the AVI file.
close(hfig);
writer.close;

%%
% Write the animated GIF file.
filename = fullfile(pwd,'wmsanimated.gif');
if exist(filename, 'file')
    delete(filename)
end
delayTime = 2.0;
loopCount = inf;
imwrite(animated, cmap, filename, ...
    'DelayTime', delayTime, 'LoopCount', loopCount);

%% Step 11: View Animated GIF File
% An animation can be viewed in the browser when the browser opens an
% animated GIF file. 

%%
% <<wmsanimated.gif>>

%% Credits
%
% _Katrina Layer_ 
% 
% The Katrina layer used in the example is from the NASA Goddard Space Flight
% Center's SVS Image Server and is maintained by the Scientific
% Visualization Studio.
%
% For more information about this server, run: 
%    
%    >> wmsinfo('http://svs.gsfc.nasa.gov/cgi-bin/wms?')
%
% _NEXRAD Layer_
%
% The NEXRAD layer used in the example is from the Iowa State University's IEM
% WMS server and is a generated CONUS composite of National Weather Service
% (NWS) WSR-88D level III base reflectivity.
%
% For more information about this server, run: 
%    
%   >> wmsinfo('http://mesonet.agron.iastate.edu/cgi-bin/wms/nexrad/n0r-t.cgi?')

displayEndOfDemoMessage(mfilename)
