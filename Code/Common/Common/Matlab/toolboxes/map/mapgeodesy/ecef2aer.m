function [az, elev, slantRange] = ecef2aer( ...
    x, y, z, lat0, lon0, h0, spheroid, angleUnit)
%ECEF2AER Geocentric ECEF to local spherical AER
%
%   [AZ, ELEV, slantRange] = ECEF2AER(X, Y, Z, LAT0, LON0, H0, SPHEROID)
%   transforms point locations from geocentric Earth-Centered Earth-Fixed
%   (ECEF) coordinates (X, Y, Z) to local spherical coordinates (azimuth
%   angle, elevation angle, slant range), given a local coordinate system
%   defined by the geodetic coordinates of its origin (LAT0, LON0, H0). The
%   geodetic coordinates refer to the reference body specified by the
%   spheroid object, SPHEROID.  Inputs X, Y, Z, and ellipsoidal height H0
%   must be expressed in the same length unit as the spheroid.  The slant
%   range will be expressed in this unit, also.  The input latitude and
%   longitude angles, and output azimuth and elevation angles, are in
%   degrees by default.
%
%   [...] = ECEF2AER(..., angleUnit) uses the string angleUnit, which
%   matches either 'degrees' or 'radians', to specify the units of the
%   latitude, longitude, azimuth, and elevation angles.
%
%   The coordinate inputs must be the same size (but any of them can be
%   scalar).
%
%   Class support for inputs X, Y, Z, LAT0, LON0, H0:
%      float: double, single
%
%   See also AER2ECEF, ECEF2ENU, ECEF2NED, GEODETIC2AER 

% Copyright 2012 The MathWorks, Inc.

inDegrees = (nargin < 8 || map.geodesy.isDegree(angleUnit));

[xEast, yNorth, zUp] = ecef2enuFormula( ...
    x, y, z, lat0, lon0, h0, spheroid, inDegrees);

if inDegrees
    [az, elev, slantRange] = enu2aerFormula(xEast, yNorth, zUp, @atan2d);
else
    [az, elev, slantRange] = enu2aerFormula(xEast, yNorth, zUp, @atan2);
end
