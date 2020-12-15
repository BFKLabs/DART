function [xEast, yNorth, zUp] = geodetic2enu( ...
    lat, lon, h, lat0, lon0, h0, spheroid, angleUnit)
%GEODETIC2ENU Geodetic to local Cartesian ENU
%
%   [xEast, yNorth, zUp] = GEODETIC2ENU(LAT, LON, H, LAT0, LON0, H0, ...
%       SPHEROID) transforms point locations from geodetic coordinates
%   (LAT, LON, H) to local Cartesian coordinates (xEast, yNorth, zUp),
%   given a local coordinate system defined by the geodetic coordinates of
%   its origin (LAT0, LON0, H0).  The geodetic coordinates refer to the
%   reference body specified by the spheroid object, SPHEROID.  Ellipsoidal
%   heights H and H0 must be expressed in the same length unit as the
%   spheroid.  Outputs xEast, yNorth, and zUp will be expressed in this
%   unit, also. The input latitude and longitude angles are in degrees by
%   default.
%
%   [...] = GEODETIC2ENU(..., angleUnit) uses the string angleUnit, which
%   matches either 'degrees' or 'radians', to specify the units of the
%   latitude and longitude angles.
%
%   The coordinate inputs must be the same size (but any of them can be
%   scalar).
%
%   Class support for inputs LAT, LON, H, LAT0, LON0, H0:
%      float: double, single
%
%   See also ECEF2ENU, ENU2GEODETIC, GEODETIC2NED, GEODETIC2AER 

% Copyright 2012 The MathWorks, Inc.

inDegrees = (nargin < 8 || map.geodesy.isDegree(angleUnit));

[xEast, yNorth, zUp] = geodetic2enuFormula( ...
    lat, lon, h, lat0, lon0, h0, spheroid, inDegrees);
