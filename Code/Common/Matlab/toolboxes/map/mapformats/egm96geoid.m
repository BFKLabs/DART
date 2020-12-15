function [Z, refvec] = egm96geoid(scalefactor, varargin)
% EGM96GEOID Read 15-minute gridded geoid heights from EGM96
% 
%  [Z, R] = EGM96GEOID(SAMPLEFACTOR) imports global geoid height in meters
%  from the EGM96 geoid model. The data set is gridded at 15-minute
%  intervals, but may be down sampled as specified by the positive integer
%  SAMPLEFACTOR. The result is returned in the regular data grid Z along
%  with referencing vector R. At full resolution (a SAMPLEFACTOR of 1), Z
%  will be 721-by-1441. The data grid has a raster interpretation of
%  'postings'.
%
%  The gridded EGM96 data set must be on your path in a file named
%  'WW15MGH.GRD'. 
% 
%  [Z, R] = EGM96GEOID(SAMPLEFACTOR, LATLIM, LONLIM) imports data for
%  the part of the world within the specified latitude and longitude
%  limits. The limits must be two-element vectors in units of degrees.
%  Longitude limits can be defined in the range [-180 180] or [0 360]. For
%  example, lonlim = [170 190] returns data centered on the dateline, while
%  lonlim = [-10 10] returns data centered on the prime meridian.
%
%  For details on locating map data for download over the Internet, see
%  the following documentation at the MathWorks web site:
%
%  <a href="matlab:
%  web('http://www.mathworks.com/help/map/finding-geospatial-data.html')
%  ">http://www.mathworks.com/help/map/finding-geospatial-data.html</a>

% Copyright 1996-2013 The MathWorks, Inc.

narginchk(1,3)

% Parse the inputs and obtain latitude and longitude limits.
[latlim, lonlim] = parseInputs(scalefactor, varargin);

% Determine if the file exists and read the header information.
[filename, header] = readHeader();

if filename ~= 0
    % Read the file and return Z and R.
    [Z, R] = readFile(filename, header, scalefactor, latlim, lonlim);
    refvec = georasterref2refvec(R);
else
    % User has canceled file dialog.
    Z = [];
    refvec = [];
end

%--------------------------------------------------------------------------

function [latlim, lonlim] = parseInputs(scalefactor, inputs)
% Parse inputs and return valid limits.

n = length(inputs);
if n == 0
    latlim = [-90 90];
    lonlim = [0 360];
elseif n == 2
    latlim = inputs{1};
    lonlim = inputs{2};
    [latlim, lonlim] = checklatlonlim(latlim, lonlim);
else
    narginchk(3,3);
end

if lonlim(2) < lonlim(1)
    lonlim(2) = lonlim(2) + 360;
end

% Ensure row vectors.
latlim = latlim(:)';
lonlim = lonlim(:)';

% Check input arguments.
validateattributes(scalefactor, {'numeric'}, {'scalar','positive'}, ...
    mfilename, 'SAMPLEFACTOR', 1)

%--------------------------------------------------------------------------

function [Z, R] = readFile(filename, header, scalefactor, latlim, lonlim)

% Data runs from [0 360] in file and has a 'postings' raster interpretation.
% The western and eastern edges (columns) match. Construct a corresponding
% raster referencing object.
nrows = header.NumberOfRows;
ncols = header.NumberOfColumns;

R = georasterref('RasterSize',[nrows ncols],'RasterInterpretation',...
    'postings','LatitudeLimits',[-90 90],'LongitudeLimits',[0 360], ...
    'ColumnsStartFrom','north');

if lonlim(1) < 0 || lonlim(2) > 360
    % Requesting data in longitude range: [-180 180] or with non-ascending
    % longitude limits.
    if any(lonlim < 0) 
        if lonlim(1) <= lonlim(2) && all(lonlim <= 180)
            % User requesting range from [-180 180] and ascending.
            westernEdge = wrapTo360(-180);
        else
            % Range is [-180, 180] but contains longitude wrapping.
            lonlim = wrapTo360(lonlim); 
            if lonlim(1) > lonlim(2)
                lonlim(2) = lonlim(2) + 360;
            end
            westernEdge = lonlim(1);
        end        
    else
        % All values are positive, [0, 360], but contains longitude
        % wrapping. user requested lonlim(1) > lonlim(2); therefore
        % lonlim(2) was set with lonlim(2) + 360; Set westernEdge to
        % lonlim(1).
        westernEdge = lonlim(1);
    end
    
    % Shift the referencing object to line up with western edge.
    col = R.longitudeToIntrinsicX(westernEdge);
    col = fix(col);
    lon = R.intrinsicXToLongitude(col);
    
    % Match longitude limits back to data grid.
    R.LongitudeLimits = [lon, lon + 360];
    if any(R.LongitudeLimits > 360)
        lonlim = R.LongitudeLimits;
        lonlim = lonlim - 360;
        lonlim = wrapTo180(lonlim);
        if lonlim(1) >= lonlim(2)
            lonlim(2) = lonlim(2) + 360;
        end
        R.LongitudeLimits = lonlim;
    end
    
    % Extract the complete map matrix. The data ranges from [0 360] in the
    % file.
    readrows = 1:nrows;
    readcols = 1:ncols;
    Z = readEGM96Geoid(filename, header, readrows, readcols);
    
    % The data grid has a raster interpretation of postings. The first and
    % last column are identical. Shift the data so that the western most
    % edge lines up with limits. But since the data grid is postings, first
    % remove the replicated column, then add a new one.
    Z(:, end) = [];
    col = -col + 1;
    Z = circshift(Z, [0, col]);
    Z(:, end+1) = Z(:, 1);
    
    % Find the row and column indices in the map.
    [row, col] = limitsToRowCol(R, latlim, lonlim, scalefactor);
    Z = Z(row, col);
else
    % User is requesting date in range: [0 360] and limits are ascending.
    % Compute row and column indices and read those values from the file.
    [row, col] = limitsToRowCol(R, latlim, lonlim, scalefactor);  
    readrows = row;
    readcols = col;
    Z = readEGM96Geoid(filename, header, readrows, readcols);
end

% Compute the new limits and adjust the referencing object.
lat = R.intrinsicYToLatitude(row);
lon = R.intrinsicXToLongitude(col);
latlim = [min(lat) max(lat)];
lonlim = [min(lon) max(lon)];
R.LatitudeLimits = latlim;
R.LongitudeLimits = lonlim;
R.RasterSize = size(Z);
R.ColumnsStartFrom = 'south';

%--------------------------------------------------------------------------

function  Z = readEGM96Geoid(filename, header, readrows, readcols)
% Read the EGM96 geoid from the file.

nFileTrailBytes = header.NumberOfTrailingBytes;
bytesperlat = header.BytesPerLatitude;
nrows = header.NumberOfRows;
ncols = header.NumberOfColumns;

Z = readmtx(filename, nrows, ncols, '%9g', readrows, readcols, ...
    'native', 74, 0, 0, nFileTrailBytes, bytesperlat);

%--------------------------------------------------------------------------

function [filename, header] = readHeader()
% Read the header from the EGM96 geoid file.

% Open the file, read the file header, and close it again.
filename = 'WW15MGH.GRD';
fid = fopen(filename,'r');

if fid == -1
	filename = lower(filename);
	fid = fopen(filename,'r');
	if fid == -1
		[filename,filepath] = uigetfile(filename,['Where is ',filename,'?']);
        if filename == 0
            header = 0;
            return
        end
		fid = fopen([filepath,filename],'r');
		filename = [filepath,filename];
	end
end

% Find end of file.
fseek(fid,0,1);
fsize = ftell(fid);

% Close file. 
fclose(fid);

% file has line breaks within logical records. Compute the number
% of bytes per record including line breaks. We bother with this because
% we can read just the data we want using READMTX.

% for PC line endings, change lineend to 2, and assume 
% last carriage return is followed by a linefeed

bigblocks = 9;
lineperbigblock = 20;
blockchars = 73; % bytes
lastpoint  = 10; % bytes

if fsize == 9618935 
    % one line ending character (mac and unix)
    lineend = 1;         % bytes
    nFileTrailBytes = 0;
    
elseif fsize == 9756647 
    % two line ending characters (PC)
    lineend = 2;         % bytes
    nFileTrailBytes = 1; % no linefeed
    
else
    error(message('map:egm96geoid:invalidFileSize'))
end
	
bytesperlat = bigblocks*( lineperbigblock*(blockchars+lineend)  + lineend ) ...
				+ lastpoint + 2*lineend;
            
header.NumberOfTrailingBytes = nFileTrailBytes;
header.BytesPerLatitude = bytesperlat;

% Number of rows and columns in the file..
header.NumberOfRows = 721;
header.NumberOfColumns = 1441;
            
%--------------------------------------------------------------------------

function [row, col] = limitsToRowCol(R, latlim, lonlim, scalefactor)
% Compute row and column indices given limits and a scale factor. 

[rowDensity, columnDensity] = sampleDensity(R);

row = fix(R.latitudeToIntrinsicY( ...
    latlim(1):(scalefactor/rowDensity):latlim(2)));

col = fix(R.longitudeToIntrinsicX( ...
    lonlim(1):(scalefactor/columnDensity):lonlim(2)));

%--------------------------------------------------------------------------

function [latlim, lonlim] = checklatlonlim(latlim, lonlim) 
% Validate latlim and lonlim inputs.

if isempty(latlim)
    latlim = [-90 90];
end
if isempty(lonlim)
    lonlim = [0 360];
end

latlim = sort(latlim);

validateattributes(latlim, {'double'}, {'real','vector','finite'}, ...
    mfilename, 'LATLIM', 2);

validateattributes(lonlim, {'double'}, {'real','vector','finite'}, ...
    mfilename, 'LONLIM', 3);

map.internal.assert(numel(latlim) == 2, ...
    'map:validate:expectedTwoElementVector', 'LATLIM');

map.internal.assert(numel(lonlim) == 2, ...
    'map:validate:expectedTwoElementVector', 'LONLIM');

map.internal.assert(latlim(1) <= latlim(2), ...
    'map:maplimits:expectedAscendingLatlim');

map.internal.assert( -90 <= latlim(1) && latlim(2) <= 90, ...
    'map:validate:expectedRange', 'LATLIM', '-90', 'latlim', '90')

map.internal.assert(all(lonlim <= 360), ...
    'map:validate:expectedRange', 'LONLIM',  '0', 'lonlim', '360')

if any(lonlim<0) && (any(lonlim<-180) || any(lonlim>180))
    error(message('map:validate:expectedRange', ...
        'LONLIM', '-180', 'lonlim', '180'))
end

%--------------------------------------------------------------------------

function refvec = georasterref2refvec(R)
%   This function assumes:
%
%       'postings'
%       columns start from west
%       rows start from south
%       sample density is the same in both dimensions
%
%   This is not a general purpose conversion. Instead, the limits are
%   extrapolated 1/2 sample north and west of their true locations, for
%   consistency with the previous behavior of egm96geoid.

cellsPerDegree = sampleDensity(R);

% Step north 1/2 cell/sample-spacing relative to northern limit.
northernLimit = R.LatitudeLimits(2) + 0.5 / cellsPerDegree;

% Step west 1/2 cell/sample-spacing relative to the western limit.
westernLimit  = R.LongitudeLimits(1) - 0.5 / cellsPerDegree;

refvec = [cellsPerDegree northernLimit westernLimit];
