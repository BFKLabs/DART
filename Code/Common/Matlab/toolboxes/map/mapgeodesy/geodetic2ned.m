function [xNorth, yEast, zDown] = geodetic2ned( ...
    lat, lon, h, lat0, lon0, h0, spheroid, angleUnit)
%GEODETIC2NED Geodetic to local Cartesian NED
%
%   [xNorth, yEast, zDown] = GEODETIC2NED(LAT, LON, H, LAT0, LON0, H0, ...
%       SPHEROID) transforms point locations from geodetic coordinates
%   (LAT, LON, H) to local Cartesian coordinates (xNorth, yEast, zDown),
%   given a local coordinate system defined by the geodetic coordinates of
%   its origin (LAT0, LON0, H0).  The geodetic coordinates refer to the
%   reference body specified by the spheroid object, SPHEROID.  Ellipsoidal
%   heights H and H0 must be expressed in the same length unit as the
%   spheroid.  Outputs xNorth, yEast, and zDown will be expressed in this
%   unit, also.  The input latitude and longitude angles are in degrees by
%   default.
%
%   [...] = GEODETIC2NED(..., angleUnit) uses the string angleUnit, which
%   matches either 'degrees' or 'radians', to specify the units of the
%   latitude and longitude angles.
%
%   The coordinate inputs must be the same size (but any of them can be
%   scalar).
%
%   Class support for inputs LAT, LON, H, LAT0, LON0, H0:
%      float: double, single
%
%   See also ECEF2NED, GEODETIC2ENU, GEODETIC2AER, NED2GEODETIC 

% Copyright 2012 The MathWorks, Inc.

inDegrees = (nargin < 8 || map.geodesy.isDegree(angleUnit));
[yEast, xNorth, zUp] = geodetic2enuFormula( ...
    lat, lon, h, lat0, lon0, h0, spheroid, inDegrees);
zDown = -zUp;
