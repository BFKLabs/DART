function [lat, lon, h] = ned2geodetic( ...
    xNorth, yEast, zDown, lat0, lon0, h0, spheroid, angleUnit)
%NED2GEODETIC Local Cartesian NED to geodetic
%
%   [LAT, LON, H] = NED2GEODETIC(xNorth, yEast, zDown, LAT0, LON0, H0, ...
%       SPHEROID) transforms point locations in 3-D from local Cartesian
%   coordinates (xNorth, yEast, zDown) to geodetic coordinates (LAT, LON,
%   H), given a local coordinate system defined by the geodetic coordinates
%   of its origin (LAT0, LON0, H0).  The geodetic coordinates refer to the
%   reference body specified by the spheroid object, SPHEROID.  Inputs
%   xNorth, yEast, zDown, and ellipsoidal height H0 must be expressed in
%   the same length unit as the spheroid.  Ellipsoid height H will be
%   expressed in this unit, also. The input and output latitude and
%   longitude angles are in degrees by default.
%
%   [...] = NED2GEODETIC(..., angleUnit) uses the string angleUnit, which
%   matches either 'degrees' or 'radians', to specify the units of the
%   latitude and longitude angles.
%
%   The coordinate inputs must be the same size (but any of them can be
%   scalar).
%
%   Class support for inputs xNorth, yEast, zDown, LAT0, LON0, H0:
%      float: double, single
%
%   See also AER2GEODETIC, ENU2GEODETIC, NED2ECEF, GEODETIC2NED

% Copyright 2012 The MathWorks, Inc.

inDegrees = (nargin < 8 || map.geodesy.isDegree(angleUnit));

[x, y, z] = enu2ecefFormula( ...
    yEast, xNorth, -zDown, lat0, lon0, h0, spheroid, inDegrees);

if inDegrees
    [lat, lon, h] = spheroid.ecef2geodetic(x, y, z);
else
    [lat, lon, h] = spheroid.ecef2geodetic(x, y, z, 'radian');
end
