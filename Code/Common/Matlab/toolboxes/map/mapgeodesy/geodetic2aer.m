function [az, elev, slantRange] = geodetic2aer( ...
    lat, lon, h, lat0, lon0, h0, spheroid, angleUnit)
%GEODETIC2AER Geodetic to local spherical AER
%
%   [AZ, ELEV, slantRange] = GEODETIC2AER(LAT, LON, H, LAT0, LON0, H0, ...
%       SPHEROID) transforms point locations from geodetic coordinates
%   (LAT, LON, H) to local spherical coordinates (azimuth angle, elevation
%   angle, slant range), given a local coordinate system defined by the
%   geodetic coordinates of its origin (LAT0, LON0, H0).  The geodetic
%   coordinates refer to the reference body specified by the spheroid
%   object, SPHEROID.  Ellipsoidal heights H and H0 must be expressed in
%   the same length unit as the spheroid.  The slant range will be
%   expressed in this unit, also.  The input latitude and longitude angles,
%   and output azimuth and elevation angles, are in degrees by default.
%
%   [...] = GEODETIC2AER(..., angleUnit) uses the string angleUnit, which
%   matches either 'degrees' or 'radians', to specify the units of the
%   latitude, longitude, azimuth, and elevation angles.
%
%   The coordinate inputs must be the same size (but any of them can be
%   scalar).
%
%   Class support for inputs LAT, LON, H, LAT0, LON0, H0:
%      float: double, single
%
%   See also AER2GEODETIC, ECEF2AER, GEODETIC2ENU, GEODETIC2NED 

% Copyright 2012 The MathWorks, Inc.

inDegrees = (nargin < 8 || map.geodesy.isDegree(angleUnit));

[xEast, yNorth, zUp] = geodetic2enuFormula( ...
    lat, lon, h, lat0, lon0, h0, spheroid, inDegrees);

if inDegrees
    [az, elev, slantRange] = enu2aerFormula(xEast, yNorth, zUp, @atan2d);
else
    [az, elev, slantRange] = enu2aerFormula(xEast, yNorth, zUp, @atan2);
end
