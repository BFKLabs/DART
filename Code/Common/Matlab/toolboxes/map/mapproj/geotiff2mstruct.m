function mstruct = geotiff2mstruct(gtif)
%GEOTIFF2MSTRUCT Convert GeoTIFF information to map projection structure
%
%   MSTRUCT = GEOTIFF2MSTRUCT(PROJ) converts the GeoTIFF projection
%   structure, PROJ, to the map projection structure, MSTRUCT. The length
%   units of the MSTRUCT projection are meters.
%
%   PROJ must reference a projected coordinate system, as indicated by a
%   value of 'ModelTypeProjected' in the ModelType field. If ModelType has
%   the value 'ModelTypeGeographic' then it doesn't make sense to convert
%   to a map projection structure and an error is issued.
%
%   Example 
%   -------
%   % Compare inverse transform of points using projinv and minvtran.
%   % Obtain the projection structure of 'boston.tif'.
%   proj = geotiffinfo('boston.tif');
%
%   % Convert the corner map coordinates to latitude and longitude.
%   x = proj.CornerCoords.X;
%   y = proj.CornerCoords.Y;
%   [latProj, lonProj] = projinv(proj, x, y);
%
%   % Obtain the mstruct from the GeoTIFF projection.
%   mstruct = geotiff2mstruct(proj);
%
%   % Convert the units of x and y to meter to match projection units.
%   x = unitsratio('meter','sf') * x;
%   y = unitsratio('meter','sf') * y;
%
%   % Convert the corner map coordinates to latitude and longitude.
%   [latMstruct, lonMstruct] = minvtran(mstruct, x, y);
%
%   % Verify the values are within a tolerance of each other.
%   abs(latProj - latMstruct) <= 1e-7
%   abs(lonProj - lonMstruct) <= 1e-7
%
%   See also GEOTIFFINFO, MFWDTRAN, MINVTRAN, PROJFWD, PROJINV, PROJLIST.

% Copyright 1996-2012 The MathWorks, Inc.

% Verify the input structure
if ~isGeoTiff(gtif)
    error(message('map:validate:invalidGeoTIFF'))
end

% Assert that the GeoTIFF structure references a projected coordinate
% system.
map.internal.assert(isequal(gtif.ModelType, 'ModelTypeProjected'), ...
    'map:validate:expectedModelTypeProjected', gtif.ModelType);

% Get the projection code structure
code = projcode(gtif.CTProjection);
if (isequal(code.mapprojection,'Unknown'))
    error(message('map:validate:unknownPROJ', ...
        gtif.CTProjection, 'PROJFWD', 'PROJINV'))
end

% Create a default mstruct using the mapprojection name
mstruct = defaultm(code.mapprojection);

% Get the mstruct projection parameters from GeoTIFF
[origin, parallels, scale, easting, northing] = getProjParm( code.index, ...
 gtif.ProjParm(1:2), gtif.ProjParm(3:4), gtif.ProjParm(5), ...
 gtif.ProjParm(6), gtif.ProjParm(7));

% Reshape the origin and mapparallels
mstruct.origin = [reshape(origin,1,2) 0];
mstruct.mapparallels = reshape(parallels,1,2);

% scalefactor must be 1 if not set
if (isequal(scale,0))
  mstruct.scalefactor = 1;
else
  mstruct.scalefactor = scale;
end

% Assign the falseeasting and northing parameters
mstruct.falseeasting  = easting; 
mstruct.falsenorthing = northing; 

% Set the 'geoid' field 
mstruct.geoid = [gtif.SemiMajor  axes2ecc(gtif.SemiMajor, gtif.SemiMinor)];

% Set the rest of the mstruct properties
if strcmp(mstruct.mapprojection,'ups')
    % UPS sets the origin itself and will warn
    % because we've set it already.
    warnstate = warning('off','map:origin:ignoringOriginForUPS');
    c = onCleanup(@() warning(warnstate));
    if mstruct.origin(1) >= 0
        mstruct.zone = 'north';
    else
        mstruct.zone = 'south';
    end
    mstruct = defaultm(mstruct);
else
    mstruct = defaultm(mstruct);
end
