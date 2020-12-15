function [lat, lon, h] = enu2geodetic( ...
    xEast, yNorth, zUp, lat0, lon0, h0, spheroid, angleUnit)
%ENU2GEODETIC Local Cartesian ENU to geodetic
%
%   [LAT, LON, H] = ENU2GEODETIC(xEast, yNorth, zUp, LAT0, LON0, H0, ...
%       SPHEROID) transforms point locations in 3-D from local Cartesian
%   coordinates (xEast, yNorth, zUp) to geodetic coordinates (LAT, LON, H),
%   given a local coordinate system defined by the geodetic coordinates of
%   its origin (LAT0, LON0, H0).  The geodetic coordinates refer to the
%   reference body specified by the spheroid object, SPHEROID.  Inputs
%   xEast, yNorth, zUp, and ellipsoidal height H0 must be expressed in the
%   same length unit as the spheroid.  Ellipsoidal height H will be
%   expressed in this unit, also. The input and output latitude and
%   longitude angles are in degrees by default.
%
%   [...] = ENU2GEODETIC(..., angleUnit) uses the string angleUnit, which
%   matches either 'degrees' or 'radians', to specify the units of the
%   latitude and longitude angles.
%
%   The coordinate inputs must be the same size (but any of them can be
%   scalar).
%
%   Class support for inputs xEast, yNorth, zUp, LAT0, LON0, H0:
%      float: double, single
%
%   See also AER2GEODETIC, ENU2ECEF, GEODETIC2ENU, NED2GEODETIC

% Copyright 2012 The MathWorks, Inc.

inDegrees = (nargin < 8 || map.geodesy.isDegree(angleUnit));

[x, y, z] = enu2ecefFormula( ...
    xEast, yNorth, zUp, lat0, lon0, h0, spheroid, inDegrees);

if inDegrees
    [lat, lon, h] = spheroid.ecef2geodetic(x, y, z);
else
    [lat, lon, h] = spheroid.ecef2geodetic(x, y, z, 'radian');
end
