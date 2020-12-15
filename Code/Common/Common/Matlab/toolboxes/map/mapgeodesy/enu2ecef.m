function [x, y, z] = enu2ecef( ...
    xEast, yNorth, zUp, lat0, lon0, h0, spheroid, angleUnit)
%ENU2ECEF Local Cartesian ENU to geocentric ECEF
%
%   [X, Y, Z] = ENU2ECEF(xEast, yNorth, zUp, LAT0, LON0, H0, SPHEROID)
%   transforms point locations in 3-D from local Cartesian coordinates
%   (xEast, yNorth, zUp) to geocentric Earth-Centered Earth-Fixed (ECEF)
%   coordinates (X, Y, Z), given a local coordinate system defined by the
%   geodetic coordinates of its origin (LAT0, LON0, H0).  The geodetic
%   coordinates refer to the reference body specified by the spheroid
%   object, SPHEROID.  Inputs xEast, yNorth, zUp, and ellipsoidal height H0
%   must be expressed in the same length unit as the spheroid.  Outputs X,
%   Y, and Z will be expressed in this unit, also.  The input latitude and
%   longitude angles are in degrees by default.
%
%   [...] = ENU2ECEF(..., angleUnit) uses the string angleUnit, which
%   matches either 'degrees' or 'radians', to specify the units of the
%   latitude and longitude angles.
%
%   The coordinate inputs must be the same size (but any of them can be
%   scalar).
%
%   Class support for inputs xEast, yNorth, zUp, LAT0, LON0, H0:
%      float: double, single
%
%   See also AER2ECEF, ECEF2ENU, ENU2GEODETIC, NED2ECEF

% Copyright 2012 The MathWorks, Inc.

inDegrees = (nargin < 8 || map.geodesy.isDegree(angleUnit));

[x, y, z] = enu2ecefFormula( ...
    xEast, yNorth, zUp, lat0, lon0, h0, spheroid, inDegrees);
