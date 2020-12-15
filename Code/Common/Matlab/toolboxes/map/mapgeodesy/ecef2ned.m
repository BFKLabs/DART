function [xNorth, yEast, zDown] = ecef2ned( ...
    x, y, z, lat0, lon0, h0, spheroid, angleUnit)
%ECEF2NED Geocentric ECEF to local Cartesian NED
%
%   [xNorth, yEast, zDown] = ECEF2NED(X, Y, Z, LAT0, LON0, H0, SPHEROID)
%   transforms point locations from geocentric Earth-Centered Earth-Fixed
%   (ECEF) coordinates (X, Y, Z) to local Cartesian coordinates (xNorth,
%   yEast, zDown), given a local coordinate system defined by the geodetic
%   coordinates of its origin (LAT0, LON0, H0).  The geodetic coordinates
%   refer to the reference body specified by the spheroid object, SPHEROID.
%   Inputs X, Y, Z, and ellipsoidal height H0 must be expressed in the same
%   length unit as the spheroid.  Outputs xNorth, yEast, and zDown will be
%   expressed in this unit, also.  The input latitude and longitude angles
%   are in degrees by default.
%
%   [...] = ECEF2NED(..., angleUnit) uses the string angleUnit, which
%   matches either 'degrees' or 'radians', to specify the units of the
%   latitude and longitude angles.
%
%   The coordinate inputs must be the same size (but any of them can be
%   scalar).
%
%   Class support for inputs X, Y, Z, LAT0, LON0, H0:
%      float: double, single
%
%   See also ECEF2ENU, ECEF2AER, GEODETIC2NED, NED2ECEF

% Copyright 2012 The MathWorks, Inc.

inDegrees = (nargin < 8 || map.geodesy.isDegree(angleUnit));

[yEast, xNorth, zUp] = ecef2enuFormula( ...
    x, y, z, lat0, lon0, h0, spheroid, inDegrees);

zDown = -zUp;
