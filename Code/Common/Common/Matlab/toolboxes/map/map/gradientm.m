function [aspect,slope,gradN,gradE] = gradientm(varargin)
%GRADIENTM Calculate gradient, slope and aspect of data grid
%
%   [ASPECT, SLOPE, gradN, gradE] = GRADIENTM(Z, R) computes the slope,
%   aspect and north and east components of the gradient for a regular
%   data grid Z.  R can be a geographic raster reference object, a
%   referencing vector, or a referencing matrix. If the grid contains
%   elevations in meters, the resulting aspect and slope are in units of
%   degrees clockwise from north and up from the horizontal.  The north and
%   east gradient components are the change in the map variable per meter
%   of distance in the north and east directions.  The computation uses
%   finite differences for the map variable on the default earth ellipsoid.
%
%   If R is a geographic raster reference object, its RasterSize property
%   must be consistent with size(Z).
%
%   If R is a referencing vector, it must be a 1-by-3 with elements:
%
%     [cells/degree northern_latitude_limit western_longitude_limit]
%
%   If R is a referencing matrix, it must be 3-by-2 and transform raster
%   row and column indices to/from geographic coordinates according to:
% 
%                     [lon lat] = [row col 1] * R.
%
%   If R is a referencing matrix, it must define a (non-rotational,
%   non-skewed) relationship in which each column of the data grid falls
%   along a meridian and each row falls along a parallel.
%
%   [...] = GRADIENTM(LAT, LON, Z) does the computation for a geolocated
%   data grid.  LAT and LON, the latitudes and longitudes of the
%   geolocation points, are in degrees.
%
%   [...] = GRADIENTM(..., ELLIPSOID) uses the ellipsoid specified by the
%   input ELLIPSOID.  ELLIPSOID is a reference ellipsoid (oblate spheroid)
%   object, a reference sphere object, or a vector of the form
%   [semimajor_axis, eccentricity]. If the map contains elevations in the
%   same units as the semimajor axis, the slope and aspect are in units of
%   degrees. This calling form is most useful for computations on bodies
%   other than the earth.
% 
%   [...] = GRADIENTM(LAT, LON, Z, ELLIPSOID, UNITS) specifies the angle
%   units of the latitude and longitude inputs. If omitted, 'degrees' are
%   assumed.  For elevation maps in the same units as the semimajor axis,
%   the resulting slope and aspect are in the specified units. The
%   components of the gradient are the change in the map variable per unit
%   of semimajor axis.
%
%   Example
%   -------
%   Compute and display the slope for the 30 arc-second (10 km) Korea 
%   elevation data.  Slopes in the Sea of Japan are up to 8 degrees at this
%   grid resolution. 
%
%   load korea
%   [aspect, slope, gradN, gradE] = gradientm(map, refvec);
%   worldmap(slope, refvec)
%   geoshow(slope, refvec, 'DisplayType', 'texturemap')
%   cmap = cool(10);
%   demcmap('inc', slope, 1, [], cmap)
%   colorbar
%   latlim = getm(gca,'maplatlimit');
%   lonlim = getm(gca,'maplonlimit');
%   land = shaperead('landareas',...
%              'UseGeoCoords', true, 'BoundingBox', [lonlim' latlim']);
%   geoshow(land, 'FaceColor', 'none')
%
%   See also VIEWSHED

% Copyright 1996-2013 The MathWorks, Inc.
% Written by Walter Stumpf.

narginchk(2,5)

size1 = size(varargin{1});
size2 = size(varargin{2});

if nargin >= 3 && isequal(size1, size2, size(varargin{3})) ...
    % GRADIENTM(LAT, LON, Z, ...)
    
    [latgrat,longrat,map] = deal(varargin{1:3});
    varargin(1:3) = [];
    
    checklatlon(latgrat, longrat, mfilename, 'LAT', 'LON', 1, 2)
    validateattributes(map, {'numeric'}, {'2d'}, mfilename, 'Z')
    
    % Ensure that LAT and LON are truly two-dimensional:
    % they are M-by-N where both M and N are greater than 1.
    validateattributes(latgrat, {'numeric'}, {'2d'}, mfilename, 'LAT')
    assert(min(size(latgrat)) > 1, ...
        'map:gradientm:vectorInput', ...
        'Latitude and longitude inputs must be two-dimensional matrices.')    
else
    % GRADIENTM(Z, R, ...)

    narginchk(2,3)
    [map,R] = deal(varargin{1:2});
    varargin(1:2) = [];
    
    % If R is already spatial referencing object, validate it. Otherwise
    % convert the input referencing vector or matrix.
    R = internal.map.convertToGeoRasterRef( ...
        R, size(map), 'degrees', 'GRADIENTM', 'R', 2);
    
    % Construct a graticule with a point for
    % point correspondence to the grid.
    [longrat, latgrat] = meshgrid(...
        R.intrinsicXToLongitude(1:R.RasterSize(2)), ...
        R.intrinsicYToLatitude( 1:R.RasterSize(1)));
end

% Validate the ellipsoid
if isempty(varargin)
    ellipsoid = referenceEllipsoid('grs80');
else
    ellipsoid = checkellipsoid(varargin{1},'GRADIENTM','ELLIPSOID');
    varargin(1) = [];
end

% Validate the angle units
if isempty(varargin)
    units = 'degrees';
else
    units = varargin{1};
    % Ensure that graticule is in degrees.
    [latgrat, longrat] = toDegrees(units, latgrat, longrat);
end

% Compute the projected positions of the points. This gets the positions
% into the same units as the semimajor axis, which allows the computation
% of slopes of elevation maps. Use the Plate Carree projection. Compute the
% gradient on the pcarree projection, and then correct for the convergence
% of the meridians below.
[x,y,a] = pcarreefwd(ellipsoid,latgrat,longrat);

% Compute the gradient for the cell spacing in the projected cylindrical 
% coordinate system.
[gradE,gradN] = mtxgradient(map,x,y,a);

% Adjust the longitude gradient for the convergence of the meridians
convfactor = departure(...
   zeros(size(latgrat)),...
   ones(size(latgrat)),...
   latgrat,ellipsoid)...
   / departure(0,1,0,ellipsoid);

convfactor(convfactor==0) = NaN; % avoid divide by zeros 
gradE = gradE ./ convfactor;

% Compute slope and aspect
[aspect,mag]    = cart2pol(gradE,gradN);
aspect(gradN==0 & gradE==0) = NaN;
slope           = atan(mag);

% convert to desired units
aspect  = zero22pi(-aspect-pi/2,'radians');
[aspect, slope] = fromRadians(units, aspect, slope);

%--------------------------------------------------------------------------

function [x,y,a] = pcarreefwd(spheroid,lat,lon)
% Replicate what the following would do in R2013a and earlier:

% mstruct = defaultm('pcarree');
% mstruct.geoid = ellipsoid;
% mstruct = defaultm(mstruct);
% [x,y] = mfwdtran(mstruct,lat,lon);

if isobject(spheroid)
    a   = spheroid.SemimajorAxis;
    ecc = spheroid.Eccentricity;
else
    a = spheroid(1);
    if isscalar(spheroid)
        ecc = 0;
    else
        ecc = spheroid(2);
    end
end

lat = degtorad(lat);
lat = convertlat([a ecc], lat, 'geodetic', 'rectifying', 'nocheck');

lon = degtorad(lon);
lon = wrapToPi(lon);

% The rectifying latitude should actually be multiplied by the rectifying
% radius, but for now remain consistent with earlier releases.
x = a * lon;
y = a * lat;

%--------------------------------------------------------------------------

function [dfdx,dfdy] = mtxgradient(f,x,y,a)
%MTXGRADIENT gradient for matrix with variable cell spacing

% a is the semimajor axis of the ellipsoid used to construct the projected
% coordinates x and y.

[n,m] = size(x);
if n < 3 || m < 3
    error('map:gradientm:smallerThan4by4', ...
        'Matrix must be 4 by 4 or larger to compute gradient.')
end

% Derivatives of function with respect to rows and columns
dfdc = zeros(size(x));
dfdr = zeros(size(y));

% Take forward differences on left and right edges
dfdr(1,:)   = (f(2,:)   - f(1,:)    ) ;
dfdr(end,:) = (f(end,:) - f(end-1,:)) ;

dfdc(:,1) = f(:,2) - f(:,1);
dfdc(:,end) = f(:,end) - f(:,end-1);

% Take centered differences on interior points
dfdr(2:end-1,:) = (f(3:end,:)-f(1:end-2,:)) / 2;
dfdc(:,2:end-1) = (f(:,3:end)-f(:,1:end-2)) / 2;

% Differences of x and y with respect to row and column numbers
dxdc = zeros(size(x));
dxdr = zeros(size(x));
dydc = zeros(size(y));
dydr = zeros(size(y));

[n,m] = size(f);
if n < 3 || m < 3
    error('map:gradientm:smallerThan4by4', ...
        'Matrix must be 4 by 4 or larger to compute gradient.')
end

% Take forward differences on left and right edges
dxdr(1,:)   = a * wrapToPi((x(  2,:) - x(    1,:))/a);
dxdr(end,:) = a * wrapToPi((x(end,:) - x(end-1,:))/a);
dydr(1,:)   = y(2,:) - y(1,:);
dydr(end,:) = y(end,:) - y(end-1,:);

dxdc(:,1)   = x(:,2) - x(:,1);
dxdc(:,end) = x(:,end) - x(:,end-1);
dydc(:,1)   = y(:,2) - y(:,1);
dydc(:,end) = y(:,end)- y(:,end-1);

% Take centered differences on interior points
dydr(2:end-1,:) = (y(3:end,:) - y(1:end-2,:))/2;
dxdc(:,2:end-1) = a * wrapToPi((x(:,3:end) - x(:,1:end-2))/a) / 2;

dxdr(2:end-1,:) = a * wrapToPi((x(3:end,:) - x(1:end-2,:))/a) / 2;
dydc(:,2:end-1) = (y(:,3:end) - y(:,1:end-2))/2;

% Angles of graticule rows and columns
colang = atan2(dydc,dxdc);
rowang = atan2(dydr,dxdr);

% distances between elements along graticule rows and columns
rowdist = hypot(dxdr, dydr);
coldist = hypot(dxdc, dydc);

% conserve memory

clear dx* dy*

% derivatives in the x and y directions

dfdx =  dfdc ./ coldist .* cos(colang) + ...
        dfdr ./ rowdist .* cos(rowang);
dfdy =  dfdr ./ rowdist .* sin(rowang) + ...
        dfdc ./ coldist .* sin(colang);
